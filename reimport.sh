#! /bin/bash

# Third-level wrapper: do the import again, push to central repo.


# Repo naming...
#
#   origin = central repo to which some cvs-derived branches are
#     pushed, which is intended to be used for further workflows
#
#   archive = central repo containing a full set of cvs/* branches and
#     tags, to which there should be no other pushes
#
#   (after do_import) $PWD is the temporary working copy from cvs2git


GITURL_BASE=intcvs1:/repos/git/anacode
TEAMHACK=anacode


set -e

# Find Self
GIDIR=$(
    cd $( dirname $0 )
    echo $PWD
)
export PATH=$GIDIR:$PATH

PROJ=$1
if [ -z "$PROJ" ]; then
    echo "Syntax: $0 <proj>
        PUSH_AND_CLEAN=1 $0 <proj>

The default is a dry-run leaving files behind.  PUSH_AND_CLEAN will
tidy up all temporary files unless the run fails."
    exit 1
fi >&2

# Guard against cronjob stack-up or headbanging failure.
# Non- fast-forward pushes or checkrevs diffs in previous runs will
# stop us here.
if [ -d /dev/shm/$PROJ.* ]; then
    echo -e "Still running or failed last time?\n"
    ls -lart /dev/shm/$PROJ.*
    tail -v -n10 /dev/shm/$PROJ.*/import.*.log
    exit 7
fi

# Make a sub-tmp directory.
umask 022
export TMPDIR=$( TMPDIR=/dev/shm mktemp -d -t $PROJ.XXXXXX )
if [ -n "$TEAMHACK" ]; then
    # Let the team hack with it.
    umask 02
    chgrp $TEAMHACK $TMPDIR
    chmod g+ws,a+rx $TMPDIR
fi

IMPLOG=$TMPDIR/import.$$.log


do_import() {
    # Assume ~/.ssh/config is correct, ie. can find necessary keys.
    # If not, don't pester the X11 user for a password just fail.
    DISPLAY=

# List maintained with help from
#   mk-known-good.sh ... > git-importing/$PROJ.known-good.txt
#
# This is intended for efficiency, but also prevents bailout due to
# checkrevs failures.

    KNOWN_GOOD_CILIST=$GIDIR/$PROJ.known-good.txt \
	ionice -n7 nice \
	$GIDIR/cvs2git-ensembl-foo $PROJ > $IMPLOG 2>&1
}

if do_import; then
    :
    # success
else
    echo -e "Failed\n" >&2
    tail -v $IMPLOG >&2
    exit 8
fi

IMPORTDIR=$TMPDIR/cvs2git-$PROJ.*
cd $IMPORTDIR/git


# Project-specific config
case $PROJ in
    ensembl-otter)
        NO_PUSH_MASTER=1
        # cvs/MAIN now contains the "we have moved" files

        # ignore ancient & trivial difference
        rm -vf $TMPDIR/cvs2git-$PROJ.*/checkrevs/sog.diff
        ;;
    ensembl | anacode)
        # These contain unlabeled-* branches
        GITSFX=--BROKEN

        # It is easier to understand if archive & origin have clear
        # roles.  For migration purpose, running without an origin is
        # maybe not a good idea; but we are still doing it 2013-04
        NO_ORIGIN=1
        ;;
    *)
        echo "No config for project $PROJ" >&2
        exit 1
esac
GITURL_ARCHIVE=$GITURL_BASE/cvs/$PROJ$GITSFX.git
GITURL_ORIGIN=$GITURL_BASE/$PROJ$GITSFX.git

[ -n "$NO_ORIGIN" ] && unset GITURL_ORIGIN


# Reject unexpected diffs
DIFFLIST=$( find $IMPORTDIR/checkrevs/ -type f -size +0 -ls )
if [ -z "$DIFFLIST" ]; then
    :
    # looks ok
else
    echo -e "Found unexpected cvs:git diffs at some branches or tags\nList of files,\n" >&2
    echo "$DIFFLIST" >&2
    exit 9
fi


# Align with central repos
git remote add archive "$GITURL_ARCHIVE"
git checkout -q cvs/main
git branch -D master > /dev/null

[ -n "$GITURL_ORIGIN" ] && git remote add origin "$GITURL_ORIGIN"


# Push and cleanup is optional.  The crontab does this but it is
# unhelpful for interactive use.
if [ -n "$PUSH_AND_CLEAN" ]; then
    # Send up the tracking refs
    git push -q archive --tags
    git push -q archive --all
    [ -n "$GITURL_ORIGIN" ] && git push -q origin cvs/main:cvs_MAIN

    # Move origin/master along...  could fail if somebody pushed to it.
    # We will mostly just be interested to hear about this, but then
    # also "somebody" needs to do a rebase or periodic merges from
    # cvs_MAIN.
    if [ -n "$GITURL_ORIGIN" -a -z "$NO_PUSH_MASTER" ]; then
        if ! git push -q origin remotes/origin/cvs_MAIN:master; then
	    echo -e '\n\norigin repo: Note that master is no longer fast-forwardable.  Somebody should merge.\n'
        fi
    fi

    cd /
    mv -f $IMPLOG ~/_reimport.$PROJ.log
    rm -rf $TMPDIR
else
    echo -e "\n\nImport completed in $PWD\nLeaving you to push to remotes: dry-run follows"
    set -x
    git push -n archive --tags
    git push -n archive --all
    [ -n "$GITURL_ORIGIN" ] && git push -n origin cvs/main:cvs_MAIN
fi

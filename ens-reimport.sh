#! /bin/bash

# Third-level wrapper: do the import again, push to central repo.
# Makes local assumptions: rederr, otter, intcvs1
#
# Anacode team members only need to provide: ~/bin/rederr -> ~mca/bin/rederr
#  or some other wrapper script which sends (stderr, stdout) to stdout.

set -e

# Find Self
GIDIR=$(
    cd $( dirname $0 )
    echo $PWD
)
export PATH=$GIDIR:$PATH

PROJ=$1
if [ -z "$PROJ" ]; then
    echo "Syntax: $0 <proj>"
    exit 1
fi >&2

# Guard against cronjob stack-up or headbanging failure
if [ -d /dev/shm/$PROJ.* ]; then
    echo -e "Still running?\n"
    ls -lart /dev/shm/$PROJ.*
    tail -v -n10 /dev/shm/$PROJ.*/import.*.log
    exit 7
fi

# Make a sub-tmp directory.  Let the team hack with it.
umask 02
export TMPDIR=$( TMPDIR=/dev/shm mktemp -d -t $PROJ.XXXXXX )
chgrp anacode $TMPDIR
chmod g+ws,a+rx $TMPDIR

IMPLOG=$TMPDIR/import.$$.log


do_import() {
    # Assume ~/.ssh/config is correct.  If not, don't pester the X11 user.
    DISPLAY=

#   List generated manually with
# (cd ~/gitwk-anacode/ensembl-$PROJ; git fetch; git show-ref | grep -E ' refs/(tags|remotes/[^/]+)/cvs/') > git-importing/$PROJ-reimport.known-good.txt

    KNOWN_GOOD_CILIST=$GIDIR/$PROJ-reimport.known-good.txt \
	ionice -n7 nice ~/bin/rederr \
	$GIDIR/cvs2git-ensembl-foo $PROJ > $IMPLOG
}

if do_import; then
    :
    # success
else
    echo -e "Failed\n" >&2
    tail -v $IMPLOG >&2
    exit 8
fi

cd $TMPDIR/cvs2git-ensembl-$PROJ.*/git

# Reject unexpected diffs
[ "$PROJ" = 'otter' ] && rm -vf $TMPDIR/cvs2git-ensembl-otter.*/checkrevs/sog.diff
DIFFLIST=$( find $TMPDIR/cvs2git-ensembl-$PROJ.*/checkrevs/ -type f -size +0 -ls )
if [ -z "$DIFFLIST" ]; then
    :
    # looks ok
else
    echo -e "Found unexpected cvs:git diffs at some branches or tags\nList of files,\n" >&2
    echo "$DIFFLIST" >&2
    exit 9
fi


[ "$PROJ" = 'otter' ] && HAS_NOCVS=1


# Align with central repos
git remote add origin intcvs1:/repos/git/anacode/cvs/ensembl-$PROJ.git
git checkout -q cvs/main
git branch -D master > /dev/null 

[ -n "$HAS_NOCVS" ] && git remote add nocvs intcvs1:/repos/git/anacode/ensembl-$PROJ.git


# Push and cleanup is optional.  The crontab does this but it is
# unhelpful for interactive use.
if [ -n "$PUSH_AND_CLEAN" ]; then
    # Send up the tracking refs
    git push -q origin --tags
    git push -q origin --all
    [ -n "$HAS_NOCVS" ] && git push -q nocvs cvs/main:cvs_MAIN

    # Move nocvs/master along...  could fail if somebody pushed to it.
    # We will mostly just be interested to hear about this, but then
    # also "somebody" needs to do a rebase or periodic merges from
    # cvs_MAIN.
## NIH!  cvs/MAIN now contains the "we have moved" files
#    if ! git push -q nocvs remotes/nocvs/cvs_MAIN:master; then
#	echo -e '\n\nnocvs repo: Note that master is no longer fast-forwardable.  Somebody should merge.\n'
#    fi

    cd /
    rm -rf $TMPDIR
else
    echo -e "\n\nImport completed in $PWD\nLeaving you to push to remotes: dry-run follows"
    git push -n origin --tags
    git push -n origin --all
    [ -n "$HAS_NOCVS" ] && git push -n nocvs cvs/main:cvs_MAIN
fi

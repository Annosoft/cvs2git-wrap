#! /bin/sh

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

# Guard against cronjob stack-up or headbanging failure
if [ -d /dev/shm/otter.* ]; then
    echo -e "Still running?\n"
    ls -lart /dev/shm/otter.*
    tail -v -n10 /dev/shm/otter.*/import.*.log
    exit 7
fi

# Make a sub-tmp directory
export TMPDIR=$( TMPDIR=/dev/shm mktemp -d -t otter.XXXXXX )
IMPLOG=$TMPDIR/import.$$.log


do_import() {
    # Assume ~/.ssh/config is correct.  If not, don't pester the X11 user.
    DISPLAY=

    ionice -n7 nice ~/bin/rederr \
	$GIDIR/cvs2git-ensembl-foo otter > $IMPLOG
}

if do_import; then
    :
    # success
else
    echo -e "Failed\n" >&2
    tail -v $IMPLOG >&2
    exit 8
fi

cd $TMPDIR/cvs2git-ensembl-otter.*/git

# Reject unexpected diffs
rm -f $TMPDIR/cvs2git-ensembl-otter.*/checkrevs/sog.diff
DIFFLIST=$( find $TMPDIR/cvs2git-ensembl-otter.*/checkrevs/ -type f -size +0 -ls )
if [ -z "$DIFFLIST" ]; then
    :
    # looks ok
else
    echo -e "Found unexpected cvs:git diffs at some branches or tags\nList of files,\n" >&2
    echo "$DIFFLIST" >&2
    exit 9
fi


# Update central repos
git remote add origin intcvs1:/repos/git/anacode/ensembl-otter-TRIAL-RUN.git
git checkout -q cvs/main
git branch -D master > /dev/null 
git push -q origin --tags
git push -q origin --all

git remote add nocvs intcvs1:/repos/git/anacode/ensembl-otter-TRIAL-RUN-no-cvs-branches.git
git push -q nocvs cvs/main:cvs_MAIN

cd /
rm -rf $TMPDIR

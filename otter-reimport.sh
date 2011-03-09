#! /bin/sh

# Third-level wrapper: do the import again, push to central repo.
# Makes local assumptions: rederr, otter, intcvs1

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
    exit 7
fi

# Make a sub-tmp directory
export TMPDIR=$( TMPDIR=/dev/shm mktemp -d -t otter.XXXXXX )

# Do import
IMPLOG=$TMPDIR/import.$$.log
if ionice -n7 nice ~/bin/rederr $GIDIR/cvs2git-ensembl-foo otter > $IMPLOG; then
    :
    # success
else
    echo -e "Failed\n" >&2
    tail -v $IMPLOG >&2
    exit 8
fi

#set -x
cd $TMPDIR/cvs2git-ensembl-otter.*/git

git remote add origin intcvs1:/repos/git/anacode/ensembl-otter-TRIAL-RUN.git
git checkout -q cvs/main
git branch -D master
git push -q origin --tags
git push -q origin --all

git remote add nocvs intcvs1:/repos/git/anacode/ensembl-otter-TRIAL-RUN-no-cvs-branches.git
git push -q nocvs cvs/main:cvs_MAIN

cd /
rm -rf $TMPDIR

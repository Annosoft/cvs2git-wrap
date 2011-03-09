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

# Make a sub-tmp directory
export TMPDIR=$( TMPDIR=/dev/shm mktemp -d -t otter.XXXXXX )

# Do import
~/bin/rederr $GIDIR/cvs2git-ensembl-foo otter > $TMPDIR/import.log

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

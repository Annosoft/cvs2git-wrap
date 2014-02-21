#! /bin/sh

set -e

cd /dev/shm/cvs2git-anacode.* && {
    pwd
    echo Previous attempt still exists - skip
    exit 39
}

cd /nfs/users/nfs_m/mca/gitwk-anacode/cvs2git-wrap

export KNOWN_GOOD_CILIST=$PWD/anacode.known-good.txt
export CVS2SVN_INST=~/gitwk-ext/cvs2svn/INST.240.273/software/python-2.7.3
export TMPDIR=/dev/shm
iRGA=intcvs1:/repos/git/anacode

nice ./cvs2git-intcvs1-foo anacode PerlModules

cd /dev/shm/cvs2git-anacode.*/git
pwd
git remote add origin $iRGA/cvs/anacode/PerlModules.git
git remote add new    $iRGA/PerlModules.git

git fetch
git push --all
git push --tags


git push new :refs/tags/last_update
git fetch new
git tag -d $( git tag -l | grep cvs/ )
git tag -a -m "Updated $(date "+%F %T") by $0" last_update master
git push new master:refs/heads/cvs_HEAD last_update
if ! git push new master; then
    echo
    echo 'git push new master: we have new history!'
    echo
    exit 42
fi

rm -rf /dev/shm/cvs2git-anacode.*

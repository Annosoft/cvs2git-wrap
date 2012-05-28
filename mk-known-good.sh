#! /bin/bash
# we use <( process redirection )

die() {
    echo "$0: $@" >&2
    exit 1
}

if [ "$1" = '-A' ]; then
    LIST_ALL=1
    shift
fi

IMPORTDIR=$1
GITREPO=${2:-$IMPORTDIR/git}
cd $GITREPO

case "$1" in
    "" | -h | --help)
        echo "Syntax: $0 [ -A ] <import_dir> [ <imported_git_repo> ]

List to stdout the hashrefs for a FOO.known-good.txt file.
That file is line-grepped for new imported commits, to see whether
diffing against their corresponding CVS checkout can be skipped.

By default, lists only the null-diff commits.  This is safe.

  -A    List everything from checkrevs/
        We must assume you have read them and considered the contents.
        (Does not include unlabeled-* branches, they are hopeless.)


The caller must arrange for this file to be preserved and then passed
back to the importer via KNOWN_GOOD_CILIST .
" >&2
        exit 2
        ;;
esac

for want in  "checkrevs.txt" "checkrevs/HEAD,master.diff"; do
    [ -f "$IMPORTDIR/$want" ] || die "Want to see $want in $IMPORTDIR/"
done

[ -f "$GITREPO/.git/config" ] || die "Want to see Git repo at $GITREPO/"

# This will fail quietly on HEAD,master.diff
# but that's fine because it is just one, and a moving target anyway
echo '# Branches and tags with nul-diff'
find "$IMPORTDIR/checkrevs" -name '*.diff' -size 0 -printf '%f\n' | sed -e 's/\.diff$//' | \
    xargs git show-ref | sort

if [ -n "$LIST_ALL" ]; then
    echo
    echo '# Branches and tags with diffs'
    find "$IMPORTDIR/checkrevs" -name '*.diff' ! -size 0 -printf '%f\n' | sed -e 's/\.diff$//' | \
        xargs git show-ref | sort | grep -vE '/unlabeled-[0-9]'
else
    {
        printf "\n# Show md5sums of variability-trimmed checkrevs/*.diff\n"
        printf "# If they look nice, you can pass -A\n\n"
        cd "$IMPORTDIR/checkrevs"
        for fn in $( find . -name '*.diff' ! -size 0 -printf '%f\n' ); do
            printf "%s  %s\n" \
                $( md5sum <( grep -vE '^([-+]{3}|diff)' $fn ) | cut -f1 -d' ' ) \
                $fn
        done
    } >&2
fi

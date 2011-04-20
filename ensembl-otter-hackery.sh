#! /bin/sh

set -e
REPO=$1

if [ -f "$REPO/CVSROOT/rcsinfo" ] && [ -f "$REPO/ensembl-otter/modules/Bio/Otter/Lock.pm,v" ]; then
    # it looks like our repo
    :
else
    echo "Directory '$REPO' does not look like our repo" >&2
    exit 1
fi

if [ -f "$REPO/CVSROOT/rcsinfo,v" ]; then
    echo "Directory '$REPO' still contains a CVSROOT/*,v file.  This makes me ervous." >&2
    exit 1
fi


cd $REPO

# Nudge this commit late one second, to stabilise the order of
# renaming
perl -i -pe 'BEGIN { print "Operate on @ARGV :"; $ch=0} $ch++ if s{(2001\.01\.31\.13\.25)\.17}{$1.18}; END { print " Changed $ch lines\n"; $? = ( $ch == 1 ? 0 : 5) }' ensembl-otter/tk/lace/Attic/c20review,v

#! /bin/sh

set -e
REPO=$1

if [ -f "$REPO/CVSROOT/rcsinfo" ] && [ -f "$REPO/ensembl/modules/Bio/EnsEMBL/AceDB/Attic/Contig.pm,v" ]; then
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

fake_lost_deltatext() {
    echo "   Write junk deltatext to $1" >&2
    perl -we 'use strict;
 my $file = shift;
 my $add_junktext = ($ARGV[0] eq "-J" && shift);
 foreach my $vsn (@ARGV) {
   my $txt = ($add_junktext
              ? "a0 1\nREVISION $vsn WAS LOST.  JUNK LINE INSERTED IN DELTATEXT\n"
              : "");
   print "\n\n$vsn\nlog\n\@THIS REVISION WAS LOST ($file v$vsn).\n
Taking the earliest one remaining.\n\@\ntext\n\@$txt\@\n" }' $*
}

# Restore some missing (outdated?) deltatext, else cvs2git refuses to run
fake_lost_deltatext \
    modules/Bio/EnsEMBL/AceDB/Contig.pm -J \
    1.6 1.5 1.4 1.3 1.2 1.1 \
    >> ensembl/modules/Bio/EnsEMBL/AceDB/Attic/Contig.pm,v

fake_lost_deltatext \
    ensembl/scripts/gtf_dump.pl -J \
    1.1.2.1 1.1.2.2 1.1.2.3 1.1.2.4 1.1.2.5 \
    >> ensembl/scripts/Attic/gtf_dump.pl,v

# Fix a non-ASCII commit comment; guess the original
perl -i -pe 's/(XrefParser::BaseParser)\xAD(>method)/$1-$2/' ensembl/misc-scripts/xref_mapping/XrefParser/FastaParser.pm,v

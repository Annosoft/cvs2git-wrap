#! /bin/sh

set -e
REPO=$1

if [ -f "$REPO/CVSROOT/rcsinfo" ] && [ -f "$REPO/PerlModules/Hum/AlignmentExchange.pm,v" ]; then
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


if [ "$SUBPROJ" = 'dbchk' ]; then
    # special case for these files
    mv  humscripts/Attic/write_mysql_db_report.pl,v . \
        || mv humscripts/write_mysql_db_report.pl,v .
    rm -rf PerlModules TODO ace_skeleton address cdna_db chr_tools chromoview est_db humscripts local_apache mg13_test submissions syn_plot utils
    mkdir cron
    mv write_mysql_db_report.pl,v cron

    # also need these vars set - but we can't do it from here
    if ! [ -f "$IEC_FILE" ]; then
        echo To match the old dbchk import, you need to
        echo "  export IEC_FILE='$GIDIR/anacode-dbchk.iec'"
        sleep 2
    fi >&2

elif [ -n "$SUBPROJ" ]; then
    # remove the other stuff
    perl -MFile::Slurp=read_dir -e 'use strict; use warnings;
 foreach my $leaf (read_dir(".")) {
   next if $leaf eq "CVSROOT";
   next if $leaf eq $ENV{"SUBPROJ"};
   print "$leaf\x00";
 }' | xargs -r0 echo Would: rm -rf
fi

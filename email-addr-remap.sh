#! /bin/sh

# This hack fixes up the cvs2git.options file
# so the next import will not generate authors
# like "uid <>"
#
# It contains WTSI-specific GCOS field hackery.
# It assumes it can ignore utf8 issues.
# It assumes the names of people at commit time were the same as they
# appear to be now.


DOM=$1
GIT_REPO="$2"
OPT_FILE="$3"

[ -d "$GIT_REPO" ] && [ -f "$OPT_FILE" ] || {
    echo "Syntax: $0 <mail-domain> <git-import> <cvs2git.options>

Does local hackery to populate a full set of name/mail pairs.
The nominated cvs2git.options file is modified."
    exit 2
}

# List the authors like "username <>"
id_list="$( cd "$GIT_REPO" && git log --pretty='%an <%ae>' | perl -ne 'print if s{ <>$}{}' | sort -u )"



perl -i~ -pe ' BEGIN { ($id_list, $dom) = splice @ARGV, 1 }
 s/[ #]+(author_transforms=author_transforms.*)/    $1/;
 if (/^author_transforms=/ .. /^\s*\}\s*$/) {
#   s/^/#/ if /^[^#]*\x27/; # keep old ones, cheerfully assume no collisions
   $_ .= do_insert() if /^author_transforms=/;
 }
 sub do_insert {
   my @out;
   foreach my $uid (split /\s+/, $id_list) {
     my $gcos = (getpwnam($uid))[6];
     $gcos =~ s/[, ]*\[.*\]//; # local convention
     push @out, qq{    \x27$uid\x27 : \x27$gcos <$uid\@$dom\>\x27,\n};
   }
   push @out, qq{    \x27cvs2git\x27 : \x27cvs2git <cvs2git>\x27,\n};
   return join "", @out;
 }'  "$OPT_FILE" "$id_list" "$DOM"

echo "Did hack $OPT_FILE.  It's in Git, right?"
diff -u "$OPT_FILE~" "$OPT_FILE"

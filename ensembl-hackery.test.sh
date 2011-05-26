#! /bin/sh

# I had trouble making the deltatext valid.  This dumps the hacked
# revisions.

export CVSROOT=/tmp/ENSCOPY-ENSEMBL/

cvs co -p -r1.1 modules/Bio/EnsEMBL/AceDB/Contig.pm 2>&1 | head
cvs co -p -r1.2 modules/Bio/EnsEMBL/AceDB/Contig.pm 2>&1 | head
cvs co -p -r1.3 modules/Bio/EnsEMBL/AceDB/Contig.pm 2>&1 | head
cvs co -p -r1.4 modules/Bio/EnsEMBL/AceDB/Contig.pm 2>&1 | head
cvs co -p -r1.5 modules/Bio/EnsEMBL/AceDB/Contig.pm 2>&1 | head
cvs co -p -r1.6 modules/Bio/EnsEMBL/AceDB/Contig.pm 2>&1 | head
cvs co -p -r1.7 modules/Bio/EnsEMBL/AceDB/Contig.pm 2>&1 | head

cvs co -p -r1.1     scripts/gtf_dump.pl 2>&1 | head
cvs co -p -r1.1.2.1 scripts/gtf_dump.pl 2>&1 | head
cvs co -p -r1.1.2.2 scripts/gtf_dump.pl 2>&1 | head
cvs co -p -r1.1.2.3 scripts/gtf_dump.pl 2>&1 | head
cvs co -p -r1.1.2.4 scripts/gtf_dump.pl 2>&1 | head
cvs co -p -r1.1.2.5 scripts/gtf_dump.pl 2>&1 | head
cvs co -p -r1.2     scripts/gtf_dump.pl 2>&1 | head

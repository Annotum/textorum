#!/bin/bash

die () {
	echo "$@"
	exit 1
}
which -s xsltproc || die "can't find xsltproc"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

INFILE=$1
OUTFILE=$(basename "${INFILE%.rng}").srng

xsltproc --noout ../../xsl/simplification.xsl "$INFILE" || die "error running xsltproc: $?"
mv simplified-7-22.rng $OUTFILE
rm simplified-7-*.rng

echo "simplified $INFILE in $OUTFILE"
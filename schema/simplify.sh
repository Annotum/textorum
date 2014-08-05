#!/bin/bash

# simplify.sh - Helper for simplification of RNG schemas
#
# Copyright (C) 2013 Crowd Favorite, Ltd. All rights reserved.
#
# This file is part of Textorum.
#
# Licensed under the MIT license:
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

die () {
	echo "$@"
	exit 1
}
which -s xsltproc || die "can't find xsltproc"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

SIMPLIFICATION_XSL=${SIMPLIFICATION_XSL:-../xsl/simplification.xsl}
test -f "$SIMPLIFICATION_XSL" || die "can't find $SIMPLIFICATION_XSL - you can download it from http://downloads.xmlschemata.org/relax-ng/utilities/simplification.xsl"

INFILE=$1
OUTFILE=$(basename "${INFILE%.rng}").srng

xsltproc --noout "$SIMPLIFICATION_XSL" "$INFILE" || die "error running xsltproc: $?"
mv simplified-7-22.rng $OUTFILE
rm simplified-7-*.rng

echo "simplified $INFILE in $OUTFILE"

#!/bin/bash

# simplify.sh - Helper for simplification of RNG schemas
#
# Copyright (C) 2013 Crowd Favorite, Ltd. All rights reserved.
#
# This file is part of Textorum.
#
# Textorum is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.
#
# Textorum is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301, USA.

die () {
	echo "$@"
	exit 1
}
which -s xsltproc || die "can't find xsltproc"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

SIMPLIFICATION_XSL=${SIMPLIFICATION_XSL:-../../xsl/simplification.xsl}
test -f "$SIMPLIFICATION_XSL" || die "can't find $SIMPLIFICATION_XSL - you can download it from http://downloads.xmlschemata.org/relax-ng/utilities/simplification.xsl"

INFILE=$1
OUTFILE=$(basename "${INFILE%.rng}").srng

xsltproc --noout "$SIMPLIFICATION_XSL" "$INFILE" || die "error running xsltproc: $?"
mv simplified-7-22.rng $OUTFILE
rm simplified-7-*.rng

echo "simplified $INFILE in $OUTFILE"
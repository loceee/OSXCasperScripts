#!/bin/bash
mydir=$(dirname $0)
tmpdir="/tmp/QuickAdd"
startquickadd="quickadd.command"

mkdir "${tmpdir}"
echo "${mydir}" > "${tmpdir}/vol.tmp" 
ditto -v "${mydir}/" "${tmpdir}"
open "${tmpdir}/${startquickadd}"

exit 

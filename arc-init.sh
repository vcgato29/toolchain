#!/bin/sh

# Copyright (C) 2007-2012 Synopsys Inc.

# This file is a common initialization script for ARC tool chains.

# Contributor Brendan Kehoe <brendan@zen.org>
# Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>

# RelPath function from http://www.ynform.org/w/Pub/Relpath 

# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.

# You should have received a copy of the GNU General Public License along
# with this program.  If not, see <http://www.gnu.org/licenses/>.          

#		      COMMON ARC TOOLKIT INITIALIZATION
#	              ---------------------------------

# Invocation Syntax
#	. arc-init.sh

# NOTE. Must be used by source from the calling script, not exec.

# On entry the variable ARC_GNU must be set to the source tree path, and the
# arc-versions.sh script must exist at the top of that source tree.

# This script will carry out the following actions:

# - register to trap certain signals with an error message and exit.

# - request any command failure to cause immediate exit (except where the
#   result is explicitly tested).

# - set the following environment variables to the sub-directories to be used:
#   - binutils
#   - gcc
#   - insight
#   - newlib
#   - uclibc

# - check that ARC_GNU has been defined

# - check that ${ARC_GNU}/arc-versions.sh exists, and if so exit.

# - define a parameter string for parallel make invocation in the PARALLEL
#   environment variable.

# - force the shell to be bash (if available) or sh, rather than any
#   alternatives.

# - define the string "-x" in the variable addShellArgs if we were invoked
#   from bash with -x, so we can reuse this in sub-commands.

# - define the shell function calcConfigPath, to set config paths, even under
#   MinGW/MSYS which does not support symbolic links and has problems with
#   "c:/" versus "/c/".

# TODO: Is this really the set of signals intended. The original script
#       specified them numerically, and they seem like a strange selection.

# 16-Mar-12: Jeremy Bennett. Name trapped signals. Use standard format and
#            width for error messages. Force to use bash or sh instead of all
#            shells, not just tcsh. Incorporate arc-relpath.sh in this script,
#            since it is the only place it is used.


# -----------------------------------------------------------------------------
# Make sure we stop if something failed. Since we are run with source, not exec
# the build=*.sh scripts will also do this.
trap "echo ERROR: Failed due to signal ; date ; exit 1" \
    HUP INT QUIT SYS PIPE TERM

# Exit immediately if a command exits with a non-zero status (but note this is
# not effective if the result of the command is being tested for, so we can
# still have custom error handling).
set -e

# None of the standard scripts should fall into this failure, but better to be
# safe.
if [ -z "${ARC_GNU}" ]
then
    echo "ERROR: Please set ARC_GNU to the source tree path before you"
    echo "       source this file."
    exit 1
fi

# Check we have the versions script.
if [ ! -f "${ARC_GNU}"/toolchain/arc-versions.sh ]
then
    echo "ERROR: Script requires arc-versions.sh to exist and define"
    echo "       binutils, gcc, insight, newlib and uclibc versions."
    exit 1
fi

# If you don't want to do parallel builds, comment this out.
make_load="`(echo processor;cat /proc/cpuinfo 2>/dev/null || echo processor) \
            | grep -c processor`"
PARALLEL="-j ${make_load} -l ${make_load}"
export PARALLEL

# Always use bash (if available) or else sh
bash_cmd=$(which bash)
if [ "x${bash_cmd}" != "x" ]
then
    export SHELL=${bash_cmd}
else
    export SHELL=$(which sh)
fi

# If using bash, if the user ran 'bash -x build-rel.sh' make it also use -x
# for the scripts we invoke.
case "${SHELLOPTS}" in
    *xtrace*) addShellArgs=-x ;;
esac

# Under MinGW/MSYS, we must do relative paths, since GCC 4.4.2 (at least) will
# fail when gengtype cannot use MSYS paths like /c/foo, instead preferring
# c:/foo.  Avoid the problem completely with a rel path like ../../foo. There
# is an assumption that if we are in a MSYS world, we are using bash (so shopt
# works).

# For standard Linux sysems, we can just use configure paths as given.
if [ "x" = "x${MSYSTEM}" ]
then
    # All other systems use the path as given.
    calcConfigPath () {
	echo "$*"
    }
else
    calcConfigPath () {

	# Need extra pattern matching, so this only works with bash
	shopt -s extglob

        path1=$(echo "${PWD}")
        path2=$(echo "$*")
        orig1=${path1}
        path1=${path1%/}
        path2=${path2%/}
        path1=${path1}/
        path2=${path2}/

        while true
	do
            if [ ! "${path1}" ]
	    then
                break
            fi

            part1=${path2#${path1}}
            if [ "${part1#/}" = "${part1}" ]
	    then
                path1="${path1%/*}"
                continue
            elif [ "${path2#${path1}}" = "${path2}" ]
	    then
                path1="${path1%/*}"
                continue
            else
		break
	    fi
        done

        part1=${path1}
        path1=${orig1#${part1}}
        depth=${path1//+([^\/])/..}
        path1=${path2#${path1}}
        path1=${depth}${path2#${part1}}
        path1=${path1##+(\/)}
        path1=${path1%/}

        if [ ! "${path1}" ]
	then
            path1=.
        fi

        printf "${path1}"
    }
fi

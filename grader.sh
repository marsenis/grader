#!/bin/bash
## Version 2.3

## ****** BEGIN - Configuration *******

# Input/Output format
# '#' will be replaced by 1, 2, ...
IN="input.#.txt"
OUT="output.#.txt"

# Limits
TL=1 # Time limit (in seconds)

# Compiling options
CPP="g++ -O2 -w -lm" # C++
C="gcc -O2 -w -lm" # C
PAS="gpc" # Pascal

## ****** END - Configuration ********

#--------------------------------------------------

#Copyright (c) 2012 Makis Arsenis

#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to
#deal in the Software without restriction, including without limitation the
#rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
#sell copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:

#The above copyright notice and this permission notice shall be included in
#all copies or substantial portions of the Software.

#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
#FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
#IN THE SOFTWARE.

# Color Codes
red='\e[0;31m'
RED='\e[1;31m'
GREEN='\e[1;32m'
green='\e[0;32m'
blue='\e[0;34m'
BLUE='\e[1;34m'
cyan='\e[0;36m'
CYAN='\e[1;36m'
NC='\e[0m' # No Color

# Cleanup on exit
rm -f .overview .compiler_report .time_info .$1.out
trap "{ rm -f .overview .compiler_report .time_info .$1.out; }" SIGINT SIGTERM EXIT

if [ $# -ne 1 ]
then
	echo "Usage: $0 source_code"
	echo "   e.g. $0 test.cpp"
	echo "   use the above to grade file test.cpp"
	exit 2
fi

# Language detection
LANG=`echo $1 | awk -F . '{print $NF}'`
if [ "$LANG" == "cpp" ]
then
	COMPILER="$CPP $1 2> .compiler_report" # C++
elif [ "$LANG" == "c" ]
then
	COMPILER="$C $1 2> .compiler_report" # C
elif [ "$LANG" == "pas" ]
then
	COMPILER="$PAS $1 2> .compiler_report" # Pascal
fi

# Compilation
echo -e " ${CYAN}* Compiling source code${NC}";
echo "$COMPILER" | sh
if [ $? -ne 0 ]
then
	echo -e " ${RED}X Compilation Error${NC}";
	cat .compiler_report;
	exit 1;
fi

echo -e " ${GREEN}* Successful compilation!${NC}";
echo

ulimit -t $TL;

rm -rf .overview;
CORRECT=0
MAX_N=50

for (( i=1; i<=$MAX_N; i++))
do
	TEST_CASE_IN=`echo $IN | sed "s/#/$i/g"`
	TEST_CASE_OUT=`echo $OUT | sed "s/#/$i/g"`

	# If i-th test case doesn't exist then stop here.
	if [ ! -e $TEST_CASE_IN ]
	then
		break
	fi
	echo -e "${BLUE}Test case $i:${NC}";

	time -p (./a.out < $TEST_CASE_IN > .$1.out) 2> .time_info;

	EX_CODE=$?;
	if [ $EX_CODE -eq 137 ]
	then
		echo -e " ${RED}X TLE: Time Limit Exceeded${NC}";
		echo -n "T" >> .overview;
	elif [ $EX_CODE -ne 0 ]
	then
		echo -e " ${RED}X RE: Runtime Error${NC}";
		echo -n "E" >> .overview;
	else
		PROG_TIME=`cat .time_info | grep real | cut -d" " -f2`;
		diff --strip-trailing-cr .$1.out $TEST_CASE_OUT > /dev/null
		if [ $? -eq 0 ]
		then
			echo -e " ${GREEN}* OK${NC} [$PROG_TIME]"
			echo -n "*" >> .overview
			CORRECT=`expr $CORRECT + 1`
		else
			echo -e " ${RED}X WA: Wrong Answer${NC} [$PROG_TIME]"
			echo -n "X" >> .overview
		fi
	fi

	echo;
done
N=`expr $i - 1`

echo;

echo >> .overview;
echo -n "Overview: "; cat .overview
if [ $CORRECT -ne $N ]
then
	echo -e "${RED}X${NC}: Wrong Answer, ${RED}T${NC}: Time Limit Exceeded, ${RED}E${NC}: Probably runtime error"
	echo
fi

echo -n "$CORRECT / $N"
if [ $CORRECT -eq $N ]
then
	echo -en "   ${GREEN}AWWW YEAH :D${NC}"
fi
echo

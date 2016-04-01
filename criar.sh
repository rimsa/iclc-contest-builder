#!/bin/bash

function die() {
    echo "$@";
    rm -rf /tmp/problem.* 1>/dev/null 2>&1
    exit 1;
}

function checkProblem() {
    # check if the problem is not blacklisted
    bl=$(cat ${BLACKLIST} 2>/dev/null | grep "^$1$");
    [ -n "$bl" ] && return 0;
 
    # check if the level is within the specified range
    [[ "${LEVEL[$1]}" -lt "${MIN_LEVEL[$2]}" || \
       "${LEVEL[$1]}" -gt "${MAX_LEVEL[$2]}" ]] && return 0;

    # check if it is a already a selected problem
    for p in $3; do
        [ "$1" == "$p" ] && return 0;
    done

    return 1
}

source ./problems.rc
source ./levels.rc

LOWER_LEVEL=0
HIGHER_LEVEL=7
OUTPUT=contest.pdf
BLACKLIST=blacklist.txt
SORT=true
ADD=false
DEBUG=false;

if [ $# -lt 1 ]; then
    echo "Usage: $0 [Options]";
    echo "Options:";
    echo "    -pX   N      Select a number (N) of a type (X) problem";
    echo "    -lX   N      Select the minimum level (N) of a type (X) problem (default: ${LOWER_LEVEL})";
    echo "    -hX   N      Select the maximum level (N) of a type (X) problem (default: ${HIGHER_LEVEL})";
    echo "    -o    File   Output contest pdf file (default: contest.pdf)";
    echo "    -b    File   Blacklist file (default: blacklist.txt)";
    echo "    -d           Enable debugging";
    echo "    -u           Do not sort the problems";
    echo "    -a           Add the problems to the blacklist";
    echo;
    echo "Type of problems";
    for c in $(jot - 1 ${#CHAPTERS[@]}); do
        echo "  ${c}:     ${CHAPTERS[$((c-1))]}";
    done
    echo;
    echo "Example: "
    echo "  \$ $0 -p1 3 -p2 5"; 
    echo "  Generated: ";
    echo "    3 (${CHAPTERS[0]} problems)";
    echo "    5 (${CHAPTERS[1]} problems)";
    echo "  --------------------------------------------";
    echo "    8 (Total problems)";

    exit 1;
fi

# Problems selection count by chapter 
for c in $(jot - 1 "${#CHAPTERS[@]}"); do
    SELECTIONS[$c]=0
    MIN_LEVEL[$c]=${LOWER_LEVEL};
    MAX_LEVEL[$c]=${HIGHER_LEVEL};
done

# Command-line arguments options parser
for arg; do
    if [[ "$1" =~ ^-d$ ]]; then
        DEBUG=true;
        shift 1;
    elif [[ "$1" =~ ^-u$ ]]; then
        SORT=false;
        shift 1;
    elif [[ "$1" =~ ^-a$ ]]; then
        ADD=true;
        shift 1;
    elif [[ "$1" =~ ^-o$ && -n "$2" ]]; then
        OUTPUT=$2;
        shift 2;
    elif [[ "$1" =~ ^-b$ && "$2" =~ ^[[:alpha:]]+$ ]]; then
        BLACKLIST=$2;
        shift 2;
    elif [[ "$1" =~ ^-p[0-9]+$ && "$2" =~ ^[1-9][0-9]*$ ]]; then
        n=${1:2};
        [[ $n -ge 1 && $n -le ${#CHAPTERS[@]} ]] || die "Invalid type of problem: $n";
  
        ((SELECTIONS[$n] += $2));
        shift 2;
    elif [[ "$1" =~ ^-l[0-9]+$ && "$2" =~ ^[0-9]+$ ]]; then
        n=${1:2};
        [[ $n -ge 1 && $n -le ${#CHAPTERS[@]} ]] || die "Invalid type of problem: $n";
        [[ "$2" -ge "${LOWER_LEVEL}" && "$2" -le "${MAX_LEVEL[$n]}" ]] \
            || die "Invalid min level for problem $n: $2";

        MIN_LEVEL[$n]=$2;
        shift 2;
    elif [[ "$1" =~ ^-h[0-9]+$ && "$2" =~ ^[0-9]+$ ]]; then
        n=${1:2};
        [[ $n -ge 1 && $n -le ${#CHAPTERS[@]} ]] || die "Invalid type of problem: $n";
        [[ "$2" -ge "${MIN_LEVEL[$n]}" && "$2" -le "${HIGHER_LEVEL}" ]] \
            || die "Invalid max level for problem $n: $2";

        MAX_LEVEL[$n]=$2;
        shift 2;
    elif [ -n "$1" ]; then
        echo -n "Invalid option $1";
        [ -n "$2" ] && echo -n " or argument $2";
        echo;
  
        exit 1;
    fi
done

ALL=();
total=0;

for c in $(jot - 1 "${#CHAPTERS[@]}"); do
    [ ${SELECTIONS[$c]} -eq 0 ] && continue;

    ${DEBUG} && echo -n "Selecting ${SELECTIONS[$c]} of ${CHAPTERS[$((c-1))]} problems:";

    count=$(eval "echo \${#PROBLEMS_${c}[@]}");
    for x in $(jot - 1 ${SELECTIONS[$c]}); do
        # just to ensure unique problems
        while true; do
            problem=$(eval "echo \${PROBLEMS_${c}[$((RANDOM % count))]}");
            checkProblem "${problem}" "${c}" $ALL || break;
        done

        ${DEBUG} && echo -n " ${problem}";

        ALL[$total]="${problem}";
        ((total++));
    done

    ${DEBUG} && echo;
done

if [ "$total" -eq 0 ]; then
    echo "No problems selected";
    exit 1;
fi

if ${SORT}; then
    SORTED="$((for p in ${ALL[@]}; do echo $p; done) | gsort -R)";
    ${DEBUG} && echo "Sorted problems: $(echo ${SORTED})";
else
    SORTED="$(for p in ${ALL[@]}; do echo $p; done)";
fi

PDFS="";
for p in ${SORTED}; do
    subp=${p/%??/};

    tmpfile=$(mktemp "/tmp/problem.XXXXXX");
    ${DEBUG} && echo "Downloading problem: ${p}";
    wget -O "${tmpfile}" "https://uva.onlinejudge.org/external/${subp}/${p}.pdf" \
        1>/dev/null 2>&1 || die "Unable to download problem ${p}";

    PDFS="${PDFS} ${tmpfile}";
done

${DEBUG} && echo "Merging contest to ${OUTPUT}";
gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile="${OUTPUT}" ${PDFS} \
  || die "Unable to merge pdf files";

${DEBUG} && echo "Removing temporary pdf problem files";
rm -rf ${PDFS} 1>/dev/null 2>&1

if ${ADD}; then
  ${DEBUG} && echo "Adding contest problems to the blacklist (${BLACKLIST})";
  for p in ${SORTED}; do
      echo ${p} >> ${BLACKLIST}
  done
fi


# Printing the final stats
${DEBUG} && echo;
echo "Generated:";
for c in $(jot - 1 "${#CHAPTERS[@]}"); do
    [ "${SELECTIONS[$c]}" -eq 0 ] && continue;

    printf " %2d (%s)\n" "${SELECTIONS[$c]}" "${CHAPTERS[$((c-1))]}";
done
echo "--------------------------------------------";
printf " %2d (Total problems)\n" "${total}";

Usage: ./criar.sh [Options]
Options:
    -pX   N      Select a number (N) of a type (X) problem
    -lX   N      Select the minimum level (N) of a type (X) problem (default: 0)
    -hX   N      Select the maximum level (N) of a type (X) problem (default: 7)
    -o    File   Output contest pdf file (default: contest.pdf)
    -b    File   Blacklist file (default: blacklist.txt)
    -d           Enable debugging
    -u           Do not sort the problems
    -a           Add the problems to the blacklist

Type of problems
  1:     Introduction
  2:     Data Structures and Libraries
  3:     Problem Solving Paradigms
  4:     Graph
  5:     Mathematics
  6:     String Processing
  7:     (Computational) Geometry
  8:     More Advanced Topics
  9:     Rare Topics

Example: 
  $ ./criar.sh -p1 3 -p2 5
  Generated: 
    3 (Introduction problems)
    5 (Data Structures and Libraries problems)
  --------------------------------------------
    8 (Total problems)


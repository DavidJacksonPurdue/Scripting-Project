#!/bin/bash

#DO NOT REMOVE THE FOLLOWING TWO LINES
git add $0 >> .local.git.out
git commit -a -m "Lab 2 commit" >> .local.git.out
git push >> .local.git.out || echo


#Your code here
SCORE=0
if egrep -q [#$\+%@] $1 ; then
  let SCORE=SCORE+5
fi
if egrep -q [0-9] $1 ; then
  let SCORE=SCORE+5;
fi
if egrep -q [A-Z] $1 ; then
  let SCORE=SCORE+5;
elif egrep -q [a-z] $1 ; then
  let SCORE=SCORE+5;
fi
if egrep -q [a-z][a-z][a-z] $1 ; then
  let SCORE=SCORE-3;
fi
if egrep -q [A-Z][A-Z][A-Z] $1 ; then
  let SCORE=SCORE-3;
fi
if egrep -q [0-9][0-9][0-9] $1 ; then
  let SCORE=SCORE-3;
fi
if egrep -q "(.)\1+" $1 ; then
  let SCORE=SCORE-10;
fi
PWSTRING=$(<$1)
if [ ${#PWSTRING} -lt 6 ] ; then
  echo "Error: Password length invalid."
  exit 0
elif [ ${#PWSTRING} -gt 32 ] ; then
  echo "Error: Password length invalid."
  exit 0
else
  let SCORE=SCORE+${#PWSTRING}
fi
echo "Password Score: $SCORE"
exit 0

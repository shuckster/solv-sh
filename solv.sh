#!/bin/bash
shopt -s extglob

solv_version="1.1.1"

example_input="  a simple sum 1 + 1
  let us multiply that result LINE:-1 * 3
  and sum the previous lines SUM:-2,-1
  as a percentage demo 2 - 1 as % of LINE:+2
  percent off demo (5 * 2) % off 512
  percent of demo 10 % of 256"

if [ $# -eq 0 ] && [ -t 0 ]
then
  echo "
-=[ solv ${solv_version} ]=-----------------------------------------------------------

Soulver-like calculator for the command line.

Written by Conan Theobald:
- https://github.com/shuckster/solv.sh

Find Soulver here:
- https://soulver.app/

----------------------------------------------------------------------------
Usage: solv.sh <input> | stdin

Uses bc along with some preprocessing to calculate inputs like:

$example_input

Run the above with --example

LINE and SUM work with relative line numbers, so LINE:-1 means to replace
that token with the calculated value of the line before it, and SUM:-2,-1
means to replace that token with the sum of the range specified.

As you can see, arbitrary text can appear before your expressions (and after
them too) but try to stick to the basic alphabet: punctuaction characters
might be seen an interpreted as part of the expression.
"
  exit
fi

if test "$1" = "--example"
then
  echo "
-=[ solv ${solv_version} ]=-----------------------------------------------------------

--example
"
  echo "$example_input" | ${0}
  echo ""
  exit
fi

process_lines_from_stdin_or_args ()
{
  if test -t 0
  then
    # No stdin, just echo the args
    echo "$@"
  else
    # Read from stdin
    while IFS=$'\n' read -r line
    do
      echo "$line"
    done
  fi
}

convert_sum_to_line()
{
  local input="$1"
  input="${input#SUM:}"
  IFS=',' read -r start end <<< "$input"
  local result=""
  local i
  if (( start <= end ))
  then
    for (( i=start; i<=end; i++ ))
    do
      if (( i != 0 ))
      then
        result+="LINE:$(printf '%+d' $i) + "
      fi
    done
  else
    for (( i=start; i>=end; i-- ))
    do
      if (( i != 0 ))
      then
        result+="LINE:$(printf '%+d' $i) + "
      fi
    done
  fi
  result=${result% + }
  echo "($result)"
}

preprocess_sums ()
{
  local line="$1"
  if [ -z "$line" ]
  then
      read line
  fi
  local regex="SUM:[-+]?[0-9]+,[-+]?[0-9]+"
  while [[ $line =~ $regex ]]
  do
    local pattern="${BASH_REMATCH[0]}"
    local replacement=$(convert_sum_to_line "$pattern")
    line="${line//$pattern/$replacement}"
  done
  echo "$line"
}

preprocess_percents ()
{
  local line="$1"
  if [ -z "$line" ]
  then
      read line
  fi
  # Process "as % of"
  if [[ $line =~ (.*)\ as\ \%\ of\ (.*) ]]
  then
    local expr="${BASH_REMATCH[1]}"
    local base="${BASH_REMATCH[2]}"
    line="($expr) * 100 / $base"
  # Process "% off"
  elif [[ $line =~ (.*)\%\ off\ (.*) ]]
  then
    local percent="${BASH_REMATCH[1]}"
    local original="${BASH_REMATCH[2]}"
    line="$original - ($original * $percent / 100)"
  # Process "% of"
  elif [[ $line =~ (.*)\%\ of\ (.*) ]]
  then
    local percent="${BASH_REMATCH[1]}"
    local total="${BASH_REMATCH[2]}"
    line="($total * $percent / 100)"
  fi
  echo "$line"
}

relative_to_absolute_line ()
{
  local absolute_line_number=$1
  shift
  local line="$1"
  if [ -z "$line" ]
  then
    read line
  fi
  while [[ "$line" =~ (LINE:)([+-]?[0-9]+) ]]
  do
    adjust=${BASH_REMATCH[2]}
    replacement=$((absolute_line_number + adjust))
    replacement=$(printf "%05d" $replacement)
    replacement="_LABS:$replacement"
    line=${line//${BASH_REMATCH[1]}${BASH_REMATCH[2]}/$replacement}
  done
  echo "$line"
}

calculate_answer_from_line ()
{
  line=$1
  answer=$(\
    echo "$line" |\
    sed s/[^[:punct:][:digit:]]//g |\
    sed s/[=,?]//g |\
    bc -l 2>/dev/null || echo "-"\
  )
  echo "$answer"
}

strip_trailing_answer ()
{
  line=$1
  line=${line%#=*}
  line=$(echo "$line" | sed 's/ *$//')
  echo "$line"
}

strip_trailing_zeros ()
{
  line=$1
  # Whole number? Trim all trailing zeros
  if [[ $line == *.* ]]
  then
    line=$(echo "$line" | sed 's/\.0*$//')
  fi
  # Fraction remaining? Trim its trailing zeros too
  if [[ $line == *.* ]]
  then
    line=$(echo "$line" | sed 's/0*$//')
  fi
  echo "$line"
}

source_lines=()
preprocessed_lines=()

# Read all lines and preprocess
#
line_count=1
max_line_length=0
while IFS=$'\n' read -r line
do
  line=$(strip_trailing_answer "$line")
  source_lines[$line_count]="$line"
  preprocessed_line=$(\
    echo "$line" |\
    preprocess_percents |\
    preprocess_sums |\
    relative_to_absolute_line $line_count\
  )
  preprocessed_lines[$line_count]="$preprocessed_line"
  line_count=$((line_count+1))
  if [[ ${#line} -gt $max_line_length ]]
  then
    max_line_length=${#line}
  fi
done < <(process_lines_from_stdin_or_args "$@")
max_line_length=$((max_line_length+1))

pad_to_max ()
{
  line=$1
  line_length=${#line}
  pad_length=$((max_line_length-line_length))
  for i in $(seq 1 $pad_length)
  do
    line="$line "
  done
  echo "$line"
}

answers_hash=()

# While answers are changing, keep recalculating
#
while true
do
  answers_changed=false
  for i in "${!preprocessed_lines[@]}"
  do
    current_line_number=$i
    line=${preprocessed_lines[$i]}
    while [[ "$line" =~ _LABS:([0-9]+) ]]
    do
      line_reference=${BASH_REMATCH[1]}
      answer_index=${line_reference##+(0)}
      answer_index=${answer_index:-0}
      replacement=${answers_hash[$answer_index]}
      line=${line//_LABS:$line_reference/$replacement}
    done

    answer=$(calculate_answer_from_line "$line")
    if [[ ${answers_hash[$i]} != $answer ]]
    then
      answers_changed=true
      answers_hash[$i]=$answer
    fi
  done
  if [[ $answers_changed == false ]]
  then
    break
  fi
done

# Print original lines with answers side-by-side
#
for i in "${!source_lines[@]}"
do
  line=${source_lines[$i]}
  if [[ ${line} != "" ]]
  then
    line=$(pad_to_max "${line}")
    answer=${answers_hash[$i]}
    echo "$line #= $(strip_trailing_zeros $answer)"
  else
    echo ""
  fi
done

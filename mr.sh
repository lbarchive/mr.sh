#!/bin/bash
# mr.sh - mood record shell script
# Copyright (c) 2012 Yu-Jie Lin
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
# of the Software, and to permit persons to whom the Software is furnished to do
# so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

#############
# Settinigs #
#############

# Max number of arguments, empty vaule = unlimited arguments
SCRIPT_MAX_ARGS=

#########################
# Common Initialization #
#########################

SCRIPT_NAME="$(basename "$0")"
# Stores arguments
SCRIPT_ARGS=()
# Stores option flags
SCRIPT_OPTS=()
# For returning value after calling SCRIPT_OPT
SCRIPT_OPT_VALUE=

#############
# Functions #
#############

usage () {
  echo "Usage: $SCRIPT_NAME [options] [[1-5] comment here blah blah blah]

Options:
  -l, --list   list data file content
  --no-color   do not use colors
  -h, --help   display this help and exit
"  
}

parse_options() {
  while (( $#>0 )); do
    opt="$1"
    arg="$2"
    
    case "$opt" in
      -l|--list)
        SCRIPT_OPT_SET "action" "list"
        ;;
      --csv)
        SCRIPT_OPT_SET "action" "csv"
        ;;
      --no-color)
        SCRIPT_OPT_SET "no-color"
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      -*)
        echo "$SCRIPT_NAME: invalid option -- '$opt'" >&2
        echo "Try \`$SCRIPT_NAME --help' for more information." >&2
        exit 1
        ;;
      *)
        if [[ ! -z $SCRIPT_MAX_ARGS ]] && (( ${#SCRIPT_ARGS[@]} == $SCRIPT_MAX_ARGS )); then
          echo "$SCRIPT_NAME: cannot accept any more arguments -- '$opt'" >&2
          echo "Try \`$SCRIPT_NAME --help' for more information." >&2
          exit 1
        else
          SCRIPT_ARGS=("${SCRIPT_ARGS[@]}" "$opt")
        fi
        ;;
    esac
    shift
  done
}

moodbar() {
  local mood=$1
  local m=${mood/-/}
  # FIXME WTF is this? Am I first day coder of Bash?
  local moods=(
  "\e[38;5;196m-\e[38;5;203m-\e[38;5;203m-\e[38;5;174m-\e[38;5;181m-\e[0m$m     "
  " \e[38;5;203m-\e[38;5;203m-\e[38;5;174m-\e[38;5;181m-\e[0m$m     "
  "  \e[38;5;203m-\e[38;5;174m-\e[38;5;181m-\e[0m$m     "
  "   \e[38;5;174m-\e[38;5;181m-\e[0m$m     "
  "    \e[38;5;181m-\e[0m$m     "
  "     $m     "
  "     $m\e[38;5;151m+\e[0m    "
  "     $m\e[38;5;151m+\e[38;5;114m+\e[0m   "
  "     $m\e[38;5;151m+\e[38;5;114m+\e[38;5;83m+\e[0m  "
  "     $m\e[38;5;151m+\e[38;5;114m+\e[38;5;83m+\e[38;5;83m+\e[0m "
  "     $m\e[38;5;151m+\e[38;5;114m+\e[38;5;83m+\e[38;5;83m+\e[38;5;46m+\e[0m")
  ret_moodbar=${moods[mood+5]}
}

###########################
# Script Template Functions

# Stores options
# $1 - option name
# $2 - option value
# $3 - non-empty if value is not optional
SCRIPT_OPT_SET () {
  if [[ ! -z "$3" ]] && [[ -z "$2" ]]; then
    echo "$SCRIPT_NAME: missing option value -- '$opt'" >&2
    echo "Try \`$SCRIPT_NAME --help' for more information." >&2
    exit 1
  fi
  # XXX should check duplication, but doesn't really matter
  SCRIPT_OPTS=("${SCRIPT_OPTS[@]}" "$1" "$2")
}

# Checks if an option is set, also set SCRIPT_OPT_VALUE.
# Returns 0 if found, 1 otherwise.
SCRIPT_OPT () {
  local i opt needle="$1"
  for (( i=0; i<${#SCRIPT_OPTS[@]}; i+=2 )); do
    opt="${SCRIPT_OPTS[i]}"
    if [[ "$opt" == "$needle" ]]; then
      SCRIPT_OPT_VALUE="${SCRIPT_OPTS[i+1]}"
      return 0
    fi
  done
  SCRIPT_OPT_VALUE=
  return 1
}

SCRIPT_SET_COLOR_VARS () {
  local COLORS=(BLK RED GRN YLW BLU MAG CYN WHT)
  local i SGRS=(RST BLD ___ ITA ___ BLK ___ INV)
  for (( i=0; i<8; i++ )); do
    eval "F${COLORS[i]}=\"\e[3${i}m\""
    eval "B${COLORS[i]}=\"\e[4${i}m\""
    eval   "T${SGRS[i]}=\"\e[${i}m\""
  done
}

########
# Main #
########

SCRIPT_SET_COLOR_VARS
parse_options "$@"

DATA_FILE="$XDG_DATA_HOME/mr"

if SCRIPT_OPT "action"; then
  case "$SCRIPT_OPT_VALUE" in
    list)
      DATE_FMT="%Y-%m-%d %H:%M:%S"
      DESC_LEN_LIMIT=$(($(tput cols) - 32))
      while read ts mood desc; do
        moodbar $mood
        (( ${#desc} > DESC_LEN_LIMIT )) && desc=${desc::DESC_LEN_LIMIT-3}...
        printf "%s %b %s\n" "$(date +"$DATE_FMT" -d @$ts)" "$ret_moodbar" "$desc"
      done < "$DATA_FILE"
      exit 0
      ;;
    csv)
      DATE_FMT="%Y-%m-%d %H:%M:%S"
      echo "Date/Time,Mood,Description"
      while read ts mood desc; do
        desc=${desc//\"/\"\"}
        echo "\"$(date +"$DATE_FMT" -d @$ts)\",$mood,\"$desc\""
      done < "$DATA_FILE"
      exit 0
      ;;
  esac
fi

if [[ ${SCRIPT_ARGS[0]} =~ [1-5] ]]; then
  echo $(date +%s) ${SCRIPT_ARGS[@]} >> "$DATA_FILE"
else
  echo -e "${TBLD}${FRED}Incorrect mood${TRST}"
fi

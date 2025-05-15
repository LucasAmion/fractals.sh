#!/usr/bin/env bash
# Obtain input parameters
order=$1

# Definition of the L-System for the Hilbert Curve
# axiom="A"
# A="+BF-AFA-FB+"
# B="-AF+BFB+FA-"
# initial_angle=0
# initial_x="0.0" # Must be a number between 0 and 1 because it's relative to the size of the fractal. It has to be a string because bash does not support floating point numbers for some reason.
# initial_y="0.0"
# scale=(1 3 7 15 31 63 127 255) # How much the size of the segment scales down when increasing the order. Can be an array or a number

# Definition of the L-System for the Lévy C Curve
axiom="F"
F="+F-FF-F+"
initial_angle=0
initial_x="0.0" # Must be a number between 0 and 1 because it's relative to the size of the fractal. It has to be a string because bash does not support floating point numbers for some reason.
initial_y="0.2"
scale=(1 3 8 18 39 81 166 336) # How much the size of the segment scales down when increasing the order. Can be an array or a number

# This function is used for checking if scale is an array
is_array() {
  declare -p "$1" 2>/dev/null | grep -q 'declare \-a'
}

# Skip order 0 if there is nothing to print
number_of_Fs=0
for (( i=0; i < ${#axiom}; i++ )); do
  if [ ${axiom:i:1} = "F" ]; then
    (( number_of_Fs ++ ))
  fi
done
if [ $number_of_Fs = 0 ]; then
  (( order ++ ))
fi

# Calculate size of terminal
width=$(($(tput cols) - 1 ))
height=$(($(tput lines) - 1 ))

# Calculate max size of fractal based on size of terminal (width is diveded by 2 because usually line_height=2*character_width in terminals)
max_size=$(( width/2 < height ? width/2 : height ))

# Calculate segment length and order based on max size
count=0
segment_length=$max_size
while (( count < order )); do
  if $( is_array scale ); then
    (( new_segment_length = $max_size / ${scale[$count]} ))
  else
    (( new_segment_length = segment_lenth / $scale ))
fi
  if (( new_segment_length < 1 )); then
    break
  fi
(( segment_length = new_segment_length ))
  (( count ++ ))
done
order=$count

# Calculate size of fractal based on segment length
if $( is_array scale ); then
  size=$(( ${scale[$order - 1]} * $segment_length))
else
  size=$(( $scale ** $order * $segment_length))
fi

# Calculate initial position based on size of fractal. Have to use awk here because again bash does not support floating point arithmatic
initial_x=$(( ($width - $size * 2) / 2 + $(awk "BEGIN { print int($initial_x * $size) }") + 1 ))
initial_y=$(( ($height - $size) / 2 + $(awk "BEGIN { print int($initial_y * $size) }") + 1 ))

declare -A char_map
# This maps angles to characters
char_map["0,0"]="━"
char_map["0,90"]="┓"
char_map["0,180"]="╸"
char_map["0,270"]="┛"
char_map["90,0"]="┗"
char_map["90,90"]="┃"
char_map["90,180"]="┛"
char_map["90,270"]="╹"
char_map["180,0"]="╺"
char_map["180,90"]="┏"
char_map["180,180"]="━"
char_map["180,270"]="┗"
char_map["270,0"]="┏"
char_map["270,90"]="╻"
char_map["270,180"]="┓"
char_map["270,270"]="┃"
char_map[",0"]="╺"
char_map[",90"]="╻"
char_map[",180"]="╸"
char_map[",270"]="╹"
char_map["0,"]="╸"
char_map["90,"]="╹"
char_map["180,"]="╺"
char_map["270,"]="╻"

# Function that expands the axiom string based on the rules
expand(){
  local i=0
  while (( i < ${#axiom} )); do
    char=${axiom:i:1}
    case $char in
      A) 
        axiom=${axiom:0:i}${axiom:i+1}
        axiom=${axiom:0:i}${A}${axiom:i}
        (( i += ${#A} )) ;;
      B) 
        axiom=${axiom:0:i}${axiom:i+1}
        axiom=${axiom:0:i}${B}${axiom:i}
        (( i += ${#B} )) ;;
      C)
        axiom=${axiom:0:i}${axiom:i+1}
        axiom=${axiom:0:i}${C}${axiom:i}
        (( i += ${#C} )) ;;
      D)
        axiom=${axiom:0:i}${axiom:i+1}
        axiom=${axiom:0:i}${D}${axiom:i}
        (( i += ${#D} )) ;;
      E)
        axiom=${axiom:0:i}${axiom:i+1}
        axiom=${axiom:0:i}${E}${axiom:i}
        (( i += ${#E} )) ;;
      F)
if [ $F ]; then
        axiom=${axiom:0:i}${axiom:i+1}
        axiom=${axiom:0:i}${F}${axiom:i}
        (( i += ${#F} ))
        else
          (( i ++ )) 
        fi ;;
      G)
if [ $G ]; then
        axiom=${axiom:0:i}${axiom:i+1}
        axiom=${axiom:0:i}${G}${axiom:i}
        (( i += ${#G} ))
        else
          (( i ++ )) 
        fi ;;
      *)
        (( i ++ )) ;;
    esac
  done
}

# Function that draws the fractal based on the expanded axiom string
draw(){
  x=$initial_x
  y=$initial_y
  angle=$initial_angle
  first_char=true
  local i
  for ((i = 0; i < ${#axiom}; i++)); do
    case "${axiom:i:1}" in
      +) 
        (( angle += 90 ))
        if (( angle >= 360)); then
          (( angle -= 360 ))
        fi ;;
      -) 
        (( angle -= 90 ))
        if (( angle < 0 )); then
          (( angle += 360 ))
        fi ;;
      F)
        print_corner
        initial_angle=$angle
        print_edge;;
    esac
  done
  print_last_char
}

# Function that prints corner characters
print_corner(){
  if [ $first_char = true ]; then
    char=${char_map[",$angle"]}
  else
    char=${char_map["$initial_angle,$angle"]}
  fi
  print_char $x $y $char cyan
  first_char=false
}

# Function that prints an edge
print_edge(){
  char=${char_map["$initial_angle,$angle"]}
  local i
  case $angle in
    0)
      (( x ++ ))
      for ((i = 0; i < 2*segment_length-1; i++)); do
        print_char $x $y $char cyan
        (( x ++ ))
      done;;
    90)
      (( y ++ ))
      for ((i = 0; i < segment_length-1; i++)); do
        print_char $x $y $char cyan
        (( y ++ ))
      done;;
    180)
      (( x -- ))
      for ((i = 0; i < 2*segment_length-1; i++)); do
        print_char $x $y $char cyan
        (( x -- ))
      done;;
    270)
      (( y -- ))
      for ((i = 0; i < segment_length-1; i++)); do
        print_char $x $y $char cyan
        (( y -- ))
      done;;
  esac
}

# Function that prints a character with a certain color in the given position
print_char(){
  local x=$1
  local y=$2
  local char=$3
  local color=$4
  
  case $color in
    black) esc_code="\e[30m";;
    red) esc_code="\e[31m";;
    green) esc_code="\e[32m";;
    yellow) esc_code="\e[33m";;
    blue) esc_code="\e[34m";;
    magenta) esc_code="\e[35m";;
    cyan) esc_code="\e[36m";;
    *) esc_code="\e[37m";;
  esac
  read -t 0.05 -n 1 2>/dev/null # Pause for a while
  printf "\e[%d;%dH%b%s\e[0m" $y $x $esc_code $char
}

# Funtion that prints the last character.
print_last_char(){
  char=${char_map["$initial_angle,"]}
  print_char $x $y $char cyan
}

tput clear # Clear the terminal
tput civis # Hide cursor

# Expand the axiom
i=0
for ((i = 0; i < order; i++)); do
  expand
done

# Draw the fractal
draw

read # Close on enter
tput clear # Clear terminal
tput cnorm # Restore cursor

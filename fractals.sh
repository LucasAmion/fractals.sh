#!/usr/bin/env bash
# Definition of the L-System for the Hilbert Curve
axiom="A"
A="+BF-AFA-FB+"
B="-AF+BFB+FA-"
C=""
D=""
E=""
F=""
G=""
initial_angle=0
initial_x=45
initial_y=3
segment_length=3
order=4

declare -A char_map
# This maps angles to characters
char_map["0,0"]="━"
char_map["0,90"]="┓"
char_map["0,-90"]="┛"
char_map["90,0"]="┃"
char_map["90,90"]="┛"
char_map["90,-90"]="┗"
char_map["180,0"]="━"
char_map["180,90"]="┗"
char_map["180,-90"]="┏"
char_map["270,0"]="┃"
char_map["270,90"]="┏"
char_map["270,-90"]="┓"

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
  local i
  for ((i = 0; i < ${#axiom}; i++)); do
    case "${axiom:i:1}" in
      +) 
        (( delta_angle += 90 ));;
      -) 
        (( delta_angle -= 90 ));;
      F)
        print_corner
        (( angle += delta_angle ))
        if (( angle < 0 )); then
          (( angle += 360 ))
        elif (( angle >= 360)); then
          (( angle -= 360 ))
        fi
        print_segment
        delta_angle=0;;
    esac
  done
}

# Function that prints corner characters
print_corner(){
  read -t 0.05 -n 1 2>/dev/null
  char=${char_map["$angle,$delta_angle"]}
  print_char $x $y $char cyan
}

# Function that prints one segment
print_segment(){
  read -t 0.05 -n 1 2>/dev/null
  local i
  case $angle in
    0)
      (( x ++ ))
      for ((i = 0; i < 2*segment_length-1; i++)); do
        print_char $x $y "━" cyan
        (( x ++ ))
      done;;
    90)
      (( y ++ ))
      for ((i = 0; i < segment_length-1; i++)); do
        print_char $x $y "┃" cyan
        (( y ++ ))
      done;;
    180)
      (( x -- ))
      for ((i = 0; i < 2*segment_length-1; i++)); do
        print_char $x $y "━" cyan
        (( x -- ))
      done;;
    270)
      (( y -- ))
      for ((i = 0; i < segment_length-1; i++)); do
        print_char $x $y "┃" cyan
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
  printf "\e[%d;%dH%b%s" $y $x $esc_code $char
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

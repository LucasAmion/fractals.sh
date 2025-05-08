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
recursion_lvl=3

tput clear # Clear the terminal
tput civis # Hide cursor

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

# Function that prints one segment
print_segment(){
  read -t 0.05 -n 1 2>/dev/null
  local i
  case $angle in
    0)
      for ((i = 0; i < 2*(segment_length-1); i++)); do
        (( x ++ ))
        printf "\e[%d;%dH\e[36m%s" $y $x "━"
      done;;
    90) 
      for ((i = 0; i < segment_length-1; i++)); do
        (( y ++ ))
        printf "\e[%d;%dH\e[36m%s" $y $x "┃"
      done;;
    180)
      for ((i = 0; i < 2*(segment_length-1); i++)); do
        (( x -- ))
        printf "\e[%d;%dH\e[36m%s" $y $x "━"
      done;;
    270)
      for ((i = 0; i < segment_length-1; i++)); do
        (( y -- ))
        printf "\e[%d;%dH\e[36m%s" $y $x "┃"
      done;;
  esac

}

# Expand the axiom
i=0
for ((i = 0; i <= recursion_lvl; i++)); do
  expand
done

# Draw the fractal
draw

read # Close on enter
tput clear # Clear terminal
tput cnorm # Restore cursor

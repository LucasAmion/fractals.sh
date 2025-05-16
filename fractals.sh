#!/usr/bin/env bash

### GLOBAL VARIBLES ###
# This maps angles to characters
declare -A char_map
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

colors=(red green yellow blue magenta cyan default) # Available colors

# This variable holds the entire fractal drawn so far so it can be reprinted when the color changes
full_string=""

### FUNCTION DEFINITIONS ###
# Function that checks if a variable is an array
is_array() {
  declare -p "$1" 2>/dev/null | grep -q 'declare \-a'
}

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
  print_char
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
        print_char
        (( x ++ ))
      done;;
    90)
      (( y ++ ))
      for ((i = 0; i < segment_length-1; i++)); do
        print_char
        (( y ++ ))
      done;;
    180)
      (( x -- ))
      for ((i = 0; i < 2*segment_length-1; i++)); do
        print_char
        (( x -- ))
      done;;
    270)
      (( y -- ))
      for ((i = 0; i < segment_length-1; i++)); do
        print_char
        (( y -- ))
      done;;
  esac
}

# Function that prints a character with a certain color in the given position
print_char(){
  read -s -t 0.05 -n 1 2>/dev/null # Pause for a while
  case "$REPLY" in
    c) 
      # Cycle to the next color in the colors array
      for idx in "${!colors[@]}"; do
        if [[ "${colors[$idx]}" == "$color" ]]; then
          next_idx=$(( (idx + 1) % ${#colors[@]} ))
          color="${colors[$next_idx]}"
          break
        fi
      done;;
  esac
  case $color in
    red) esc_code="\e[31m";;
    green) esc_code="\e[32m";;
    yellow) esc_code="\e[33m";;
    blue) esc_code="\e[34m";;
    magenta) esc_code="\e[35m";;
    cyan) esc_code="\e[36m";;
    *) esc_code="\e[0m";;
  esac
  full_string="${full_string}\e[${y};${x}H${char}"
  printf "$esc_code$full_string"
}

# Funtion that prints the last character.
print_last_char(){
  char=${char_map["$initial_angle,"]}
  print_char
}

### INPUT ARGUMENTS ###
# Parse command-line options
while [[ $# -gt 0 ]]; do
  case "$1" in
    -o|--order)
      order="$2"
      shift 2
      ;;
    -c|--color)
      if [[ ! " ${colors[@]} " =~ " $2 " ]]; then
        echo "Invalid color: $2. Available colors: ${colors[*]}"
        exit 1
      fi
      color="$2"
      shift 2
      ;;
    -*)
      echo "Unknown option: $1"
      exit 1
      ;;
    *) # First non-option = positional argument
      fractal_name="$1"
      shift
      break
      ;;
  esac
done

# Set default values
color=${color:-default}
order=${order:-8} # If order is not defined the max value will be used
(( order = order > 8 ? 8 : order )) # Order can't be higher than 8
fractal_name=${fractal_name:-hilbert}

# Set L-system related variables for each fractal name
case $fractal_name in
  hilbert)
    axiom="A"
    A="+BF-AFA-FB+"
    B="-AF+BFB+FA-"
    initial_angle=0
    initial_x="0.0"
    initial_y="0.0"
    scale=(1 3 7 15 31 63 127 255 511);;
  levy)
    axiom="F"
    F="+F-FF-F+"
    initial_angle=0
    initial_y=(0 0 0 1 3 7 15 31 63)
    initial_x=(0 0 1 3 7 15 31 63 127)
    scale_x=(1 2 6 14 30 62 126 254 510)
    scale_y=(1 1 3 8 18 38 78 158 318);;
  *) 
    echo "Unknown fractal name: $fractal_name"
    exit 1;;
esac

# If scale is defined it replaces the values for scale_x and scale_y
if [[ -n $scale ]]; then
  if $(is_array scale); then
    scale_x=("${scale[@]}")
    scale_y=("${scale[@]}")
  else
    scale_x=$scale
    scale_y=$scale
  fi
fi

### SIZE CALCULATION ###
# Calculate size of terminal
max_width=$(($(tput cols) - 1 ))
max_height=$(($(tput lines) - 1 ))

# Calculate segment length and order based on terminal size
count=0
len_y=$max_height
len_x=$max_width/2
while (( count <= order )); do
  if $( is_array scale_y ); then
    (( new_len_y = $max_height / ${scale_y[$count]} ))
  else
    (( new_len_y = $len_y / $scale_y ))
  fi

  if (( new_len_y < 1 )); then
    break
  fi

  if $( is_array scale_x ); then
    (( new_len_x = $max_width/2 / ${scale_x[$count]} ))
  else
    (( new_len_x = $len_x / $scale_x ))
  fi

  if (( new_len_x < 1 )); then
    break
  fi

  (( len_y = new_len_y ))
  (( len_x = new_len_x ))

  (( count ++ ))
done
(( segment_length = len_x < len_y ? len_x : len_y ))
(( order = $count - 1 ))

# Calculate size of fractal based on segment length
if $( is_array scale_x ); then
  width=$(( ${scale_x[$order]} * $segment_length))
else
  width=$(( $scale_x ** $order * $segment_length))
fi

if $( is_array scale_y ); then
  height=$(( ${scale_y[$order]} * $segment_length))
else
  height=$(( $scale_y ** $order * $segment_length))
fi

# Calculate initial position based on size of fractal. Have to use awk here because again bash does not support floating point arithmatic
if $( is_array initial_x ); then
  initial_x=$(( ($max_width - $width * 2) / 2 + ${initial_x[$order]} * $segment_length * 2 + 1 ))
else
  initial_x=$(( ($max_width - $width * 2) / 2 + $(awk "BEGIN { print int($initial_x * $width) }") * 2 + 1 ))
fi

if $( is_array initial_y ); then
  initial_y=$(( ($max_height - $height) / 2 + ${initial_y[$order]} * $segment_length + 1 ))
else
  initial_y=$(( ($max_height - $height) / 2 + $(awk "BEGIN { print int($initial_y * $height) }") * 2 + 1 ))
fi

### MAIN EXECUTION ###
tput clear # Clear the terminal
tput civis # Hide cursor
stty -echo # Prevent typed characters from being printed

# Skip order 0 if there is nothing to print
number_of_Fs=0
for (( i=0; i < ${#axiom}; i++ )); do
  if [ ${axiom:i:1} = "F" ]; then
    (( number_of_Fs ++ ))
    break
  fi
done
if [ $number_of_Fs = 0 ]; then
  (( order ++ ))
fi

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
stty echo # Restore echo

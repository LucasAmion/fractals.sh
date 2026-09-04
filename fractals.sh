#!/usr/bin/env bash
# shellcheck disable=SC2034

### GLOBAL VARIBLES ###
# The characters to draw with. They are encoded in binary so they can be combined easily, one bit per possible direction:
# 0001 = 1 -> "╺" (left), 0010 = 2 -> "╻" (down), 0100 = 4 -> "╸" (right), 1000 = 8 -> "╹" (up)
# The rest of the characters are sums of these
chars_90=(" " "╺" "╻" "┏" "╸" "━" "┓" "┳" "╹" "┗" "┃" "┣" "┛" "┻" "┫" "╋")

# Same idea for fractals with 60 degree turns, using one bit per direction (6 bits, 64 characters):
# 1 -> right, 2 -> down-right, 4 -> down-left, 8 -> left, 16 -> up-left, 32 -> up-right
# There are no box-drawing characters for corners between a diagonal and a horizontal line (or between
# the two diagonals, other than "╳" when they cross), so those combinations are drawn as a point for now.
chars_60=(
  " " "╺" "╲" "•" "╱" "•" "•" "•" # 0-7
  "╸" "━" "•" "•" "•" "•" "•" "•" # 8-15
  "╲" "•" "╲" "•" "•" "•" "•" "•" # 16-23
  "•" "•" "•" "•" "•" "•" "•" "•" # 24-31
  "╱" "•" "•" "•" "╱" "•" "•" "•" # 32-39
  "•" "•" "•" "•" "•" "•" "•" "•" # 40-47
  "•" "•" "•" "•" "•" "•" "╳" "•" # 48-55
  "•" "•" "•" "•" "•" "•" "•" "•" # 56-63
)

# Available fractals
fractals=(hilbert levy carpet triangle)

# Available colors
colors=(default red green yellow blue magenta cyan)

# Predefined frame rates
frame_rates=(5 10 20 40 80)

# Escape sequences associated with each color
declare -A color_esc_codes
color_esc_codes[red]="\e[31m"
color_esc_codes[green]="\e[32m"
color_esc_codes[yellow]="\e[33m"
color_esc_codes[blue]="\e[34m"
color_esc_codes[magenta]="\e[35m"
color_esc_codes[cyan]="\e[36m"
color_esc_codes[default]="\e[0m"

# Matrix that stores the code of the character currently printed at each x,y location. Needed so characters can be "summed up" when writing over them.
declare -A screen_chars

# This variable holds the entire fractal drawn so far so it can be reprinted when the color changes
full_string=""

### FUNCTION DEFINITIONS ###
# Function that checks if a variable is an array
is_array() {
  declare -p "$1" 2>/dev/null | grep -q 'declare \-a'
}

# Function that extracts a random element from an array
get_random() {
  local -n array=$1
  random_item="${array[RANDOM % ${#array[@]}]}"
  echo $random_item
}

# Function that expands the axiom string based on the rules
expand(){
  local i char replacement
  local expanded=""
  for (( i=0; i < ${#axiom}; i++ )); do
    char=${axiom:i:1}
    case $char in
      A|B|C|D|E)
        replacement=${!char}
        expanded+=${replacement} ;;
      F|G|f|g)
        replacement=${!char}
        expanded+=${replacement:-$char} ;;
      *)
        expanded+=${char} ;;
    esac
  done
  axiom=$expanded
}

# Function that rotates the character one turn (90 or 60 degrees) clockwise or counterclockwise
# Since the chracters are encoded in binary, this is achieved by multiplying or dividing by 2
rotate_char(){
  local result
  case $1 in
    +) 
      (( result = $2 * 2 ))
      (( result = result >= 2 ** num_directions ? 1 : result ));;
    -)
      (( result = $2 / 2 ))
      (( result = result < 1 ? 2 ** (num_directions - 1) : result ));;
  esac
  echo $result
}

# Function that rotates the character 180 degre i.e. half a full turn (two 90° tuns or three 60° turns)
opposite_char(){
  local i result=$1
  for ((i=0; i<num_directions/2; i++)); do
    result=$(rotate_char '+' $result)
  done
  echo $result
}

# Function that draws the fractal based on the expanded axiom string
draw(){
  x=$initial_x
  y=$initial_y
  in_char=0
  out_char=$(( 2 ** ( $initial_angle / turn_angle) ))
  local i
  for ((i = 0; i < ${#axiom}; i++)); do
    case "${axiom:i:1}" in
      +)
        out_char=$(rotate_char '+' $out_char)
        ;;
      -)
        out_char=$(rotate_char '-' $out_char)
        ;;
      F|G)
        forward true
        ;;
      f|g)
        forward false
    esac
  done
  out_char=0
  print_char
}

# Moves forward, optionally drawing
forward(){
  local draw_edge=$1 # whether to print an edge or only move

  # Complete previous edge if necessary
  if [[ $draw_edge == true ]]; then
    print_char
    in_char=$(opposite_char $out_char)
  else
    if (( in_char != 0 )); then
      out_char=0 print_char
    fi
    in_char=0
  fi

  local i
  if (( turn_angle == 90 )); then
    case $out_char in
      1)
        (( x ++ ))
        for ((i = 0; i < 2*segment_length-1; i++)); do
          if [[ $draw_edge == true ]]; then
            print_char
          fi
          (( x ++ ))
        done;;
      2)
        (( y ++ ))
        for ((i = 0; i < segment_length-1; i++)); do
          if [[ $draw_edge == true ]]; then
            print_char
          fi
          (( y ++ ))
        done;;
      4)
        (( x -- ))
        for ((i = 0; i < 2*segment_length-1; i++)); do
          if [[ $draw_edge == true ]]; then
            print_char
          fi
          (( x -- ))
        done;;
      8)
        (( y -- ))
        for ((i = 0; i < segment_length-1; i++)); do
          if [[ $draw_edge == true ]]; then
            print_char
          fi
          (( y -- ))
        done;;
    esac
  elif (( turn_angle == 60 )); then
    case $out_char in
      1)
        (( x++ ))
        for ((i = 0; i < 2*segment_length-1; i++)); do
          if [[ $draw_edge == true ]]; then
            print_char
          fi
          (( x ++ ))
        done;;
      2)
        (( x++, y++ ))
        for ((i = 0; i < segment_length-1; i++)); do
          if [[ $draw_edge == true ]]; then
            print_char
          fi
          (( x++, y++ ))
        done;;
      4)
        (( x--, y++ ))
        for ((i = 0; i < segment_length-1; i++)); do
          if [[ $draw_edge == true ]]; then
            print_char
          fi
          (( x--, y++ ))
        done;;
      8)
        (( x-- ))
        for ((i = 0; i < 2*segment_length-1; i++)); do
          if [[ $draw_edge == true ]]; then
            print_char
          fi
          (( x-- ))
        done;;
      16)
        (( x--, y-- ))
        for ((i = 0; i < segment_length-1; i++)); do
          if [[ $draw_edge == true ]]; then
            print_char
          fi
          (( x--, y-- ))
        done;;
      32)
        (( x++, y-- ))
        for ((i = 0; i < segment_length-1; i++)); do
          if [[ $draw_edge == true ]]; then
            print_char
          fi
          (( x++, y-- ))
        done;;
    esac
  fi
}

# Function that prints a character with a certain color in the given position
print_char(){
  # Handle keyboard input
  handle_controls

  # Get the character currently at the given screen position
  position="$x,$y"
  current_char=${screen_chars[$position]:-0}

  # Get the character to print by adding up the "in character", the "out character" and the current character.
  # Since the characters are encoded in binary, this is achieved by using the bitwise OR operator
  char_code=$(( $in_char | $out_char | $current_char ))
  char=${chars[$char_code]}

  # Record the new char code in the screen matrix
  screen_chars[$position]=$char_code

  # Get the escape code for the current color
  esc_code="${color_esc_codes[$color]}"
  
  # Store the character in the full_string variable
  full_string="${full_string}\e[${y};${x}H${char}"
  
  # Print the character at the specified position
  printf "\e[%d;%dH%b%s" $y $x $esc_code $char
}

# Function that handles keyboard input. It is called every time a character is printed
handle_controls(){
  read -s -t "$frame_delay" -n 1 2>/dev/null # Read input and pause according to frame rate
  case "$REPLY" in
    c) 
      # Cycle to the next color in the colors array
      for idx in "${!colors[@]}"; do
        if [[ "${colors[$idx]}" == "$color" ]]; then
          next_idx=$(( (idx + 1) % ${#colors[@]} ))
          color="${colors[$next_idx]}"
          break
        fi
      done
      # Reprint the fractal with the new color
      esc_code="${color_esc_codes[$color]}"
      printf "$esc_code$full_string";;
    f)
      # Cycle between predefined frame rates
      next_frame_rate=${frame_rates[0]}
      for rate in "${frame_rates[@]}"; do
        if (( rate > frame_rate )); then
          next_frame_rate=$rate
          break
        fi
      done
      frame_rate=$next_frame_rate
      frame_delay=$(awk -v frame_rate="$frame_rate" 'BEGIN { printf "%.6f", 1 / frame_rate }');;
    q)
      quit;;
  esac
}

# Quit the program
quit() {
  tput clear # Clear terminal
  tput cnorm # Restore cursor
  stty echo # Restore echo
  exit 0
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
      color="$2"
      if [[ $color == "random" ]]; then
        color=$(get_random colors)
      elif [[ ! " ${colors[@]} " =~ " $2 " ]]; then
        echo "Invalid color: $2. Available colors: ${colors[*]}"
        exit 1
      fi
      shift 2
      ;;
    -f|--frame-rate)
      frame_rate="$2"
      shift 2
      ;;
    -*)
      echo "Unknown option: $1"
      exit 1
      ;;
    *) 
    # First non-option = positional argument
      fractal_name="$1" 
      if [[ $fractal_name == "random" ]]; then
        fractal_name=$(get_random fractals)
      fi
      shift
      break
      ;;
  esac
done

# Set default values
color=${color:-default}
order=${order:-8} # If order is not defined the max value will be used
(( order = order > 8 ? 8 : order )) # Order can't be higher than 8
frame_rate=${frame_rate:-20}
if [[ ! $frame_rate =~ ^[1-9][0-9]*$ ]]; then
  echo "Invalid frame rate: $frame_rate. Frame rate must be a positive integer."
  exit 1
fi
frame_delay=$(awk -v frame_rate="$frame_rate" 'BEGIN { printf "%.6f", 1 / frame_rate }')
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
  carpet)
    axiom="F"
    F="F-F+F+F+f-F-F-F+F"
    f="fff"
    initial_angle=0
    initial_x="0.0"
    initial_y="0.5"
    scale=3;;
  triangle)
    axiom="F--G--G"
    F="F--G++F++G--F"
    G="GG"
    turn_angle=60
    initial_angle=0
    initial_x="0.0"
    initial_y="1.0"
    scale=2;;
  *) 
    echo "Unknown fractal name: $fractal_name"
    exit 1;;
esac

# Set the character table and number of possible directions based on the turn angle
# Only 60 and 90 degrees are supported, for 120 degrees you can use '++' or '--' with 60 degrees
turn_angle=${turn_angle:-90}
num_directions=$(( 360 / turn_angle ))
case $turn_angle in
  90)
    chars=("${chars_90[@]}");;
  60)
    chars=("${chars_60[@]}");;
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

# Get the min segment length based on the turn angle. Since there are no proper corner character for 60 degrees angles segment_length=1 looks wrong
(( min_segment_length = turn_angle == 60 ? 2 : 1 ))

# Calculate segment length and order based on terminal size
count=0
len_y=$max_height
len_x=$max_width/2
while (( count <= order )); do
  if $( is_array scale_y ); then
    (( new_len_y = $max_height / ${scale_y[$count]} ))
  else
    (( new_len_y = $max_height / $scale_y ** $count ))
  fi

  if (( new_len_y < min_segment_length )); then
    break
  fi

  if $( is_array scale_x ); then
    (( new_len_x = $max_width/2 / ${scale_x[$count]} ))
  else
    (( new_len_x = $max_width/2 / $scale_x ** $count ))
  fi

  if (( new_len_x < min_segment_length )); then
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
  initial_y=$(( ($max_height - $height) / 2 + $(awk "BEGIN { print int($initial_y * $height) }") + 1 ))
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

while true; do
  handle_controls
done

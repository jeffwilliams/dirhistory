# Directory History for Bash
#
# This script overrides the bash cd command so that it saves the previous 
# directory to a directory history. ALT-Left then moves back to previous 
# directories in the history, and ALT-Right moves forward. ALT-Up changes 
# to the parent directory. Finally, ALT-Down displays the history.
#
# It also adds a cde command which copies all future directories to
# the history and then changes to the directory, in order to preserve
# all history.
#
# http://github.com/jeffwilliams/dirhistory

dirhistory_past=($PWD)
dirhistory_future=()
export dirhistory_past
export dirhistory_future

export DIRHISTORY_SIZE=30

# Pop the first element of dirhistory_past. 
# Pass the name of the variable to return the result in. 
# Returns the element if the array was not empty,
# otherwise returns empty string.
function pop_past() {
  eval "$1='${dirhistory_past[0]}'"
  if [[ ${#dirhistory_past[@]} -gt 0 ]]; then
    unset dirhistory_past[0]
    dirhistory_past=(${dirhistory_past[@]})
  fi
}

function pop_future() {
  eval "$1='${dirhistory_future[0]}'"
  if [[ ${#dirhistory_future[@]} -gt 0 ]]; then
    unset dirhistory_future[0]
    dirhistory_future=(${dirhistory_future[@]})
  fi
}

# Push a new element onto the front of dirhistory_past. If the size of the array 
# is >= DIRHISTORY_SIZE, the last element is removed
function push_past() {
  sz=${#dirhistory_past[@]}
  if [[ $sz -ge $DIRHISTORY_SIZE ]]; then
    unset dirhistory_past[$(($sz-1))]
    dirhistory_past=(${dirhistory_past[@]})
  fi
  if [[ ${#dirhistory_past[@]} -eq 0 || ${dirhistory_past[0]} != "$1" ]]; then
    dirhistory_past=($1 ${dirhistory_past[@]})
  fi
}

function push_future() {
  sz=${#dirhistory_future[@]}
  if [[ $sz -ge $DIRHISTORY_SIZE ]]; then
    unset dirhistory_future[$(($sz-1))]
    dirhistory_past=(${dirhistory_past[@]})
  fi
  if [[ ${#dirhistory_future[@]} -eq 0 || ${dirhistory_future[0]} != "$1" ]]; then
    dirhistory_future=($1 ${dirhistory_future[@]})
  fi
}

# Called by bash to change directory
function cd() { 
  push_past $PWD

#echo "cd-debug: past is ${dirhistory_past[@]}"

  # clear future.
  dirhistory_future=()

  builtin cd "$@"
}

# cd to the specified directory, but first take all the future directories
# and move them into the past history. This basically preserves the future 
# history
function cde() {
  # Reverse future
  rev=`echo -n "${dirhistory_future[@]} " | tac -s ' '`
  push_past $PWD
  dirhistory_past=($rev ${dirhistory_past[@]}) 
  dirhistory_future=()

  builtin cd "$@"
}

function dirhistory_cd(){
  builtin cd "$@"
}

# Move backward in directory history
function dirhistory_back() {
  local cw=""
  local d=""
  pop_past d
  if [[ "" != "$d" ]]; then
    push_future $PWD
    dirhistory_cd $d
  fi
}


# Move forward in directory history
function dirhistory_forward() {
  local d=""

  pop_future d
  if [[ "" != "$d" ]]; then
    push_past $PWD
    dirhistory_cd $d
  fi
}

function dhist() {
  echo "Back:"
  rev=`echo -n "${dirhistory_past[@]} " | tac -s ' '`
  for i in $rev
  do
    echo "  $i"
  done
  echo "Forward:"
  for i in "${dirhistory_future[@]}"
  do
    echo "  $i"
  done
}

define_mappings() {
  # We use some tricks here.
  # Ideally, we want to bind the keys directly to 
  # the function calls. However there is a bug in 
  # bash where binding sequences of >2 keys does not
  # work with bind -x:
  #
  #    https://lists.gnu.org/archive/html/bug-bash/2010-07/msg00007.html
  #
  # So the workaround is to instead bind an 8-bit character 
  # to the function, and then use a normal bind to print that character
  # which triggers bash the execute the -x binding.
  #
  # In the normal binds below we also send C-m (carriage return)
  # so that the prompt is reprinted.

  bind -x $'"\201":"dirhistory_back"'
  bind -x $'"\202":"dirhistory_forward"'
  bind -x $'"\203":"cd .."'
  bind -x $'"\204":"dhist"'

  # Back
  # xterm in normal mode
  bind '"\e[3D"':$'"\201\C-m"'
  bind '"\e[1;3D"':$'"\201\C-m"'
  # GNU screen:
  bind '"\eO3D"':$'"\201\C-m"'
  
  # Forward
  bind '"\e[3C"':$'"\202\C-m"'
  bind '"\e[1;3C"':$'"\202\C-m"'
  bind '"\eO3C"':$'"\202\C-m"'
  
  # Up
  bind '"\e[3A"':$'"\203\C-m"'
  bind '"\e[1;3A"':$'"\203\C-m"'
  bind '"\eO3A"':$'"\203\C-m"'

  # Display
  bind '"\e[3B"':$'"\204\C-m"'
  bind '"\e[1;3B"':$'"\204\C-m"'
  bind '"\eO3B"':$'"\204\C-m"'

}

# See http://www.unixguide.net/unix/bash/G1.shtml
# This is needed to allow 8-bit characters to work, which we use in the -x bindings
bind 'set convert-meta off'
bind 'set meta-flag on'
bind 'set output-meta on'

define_mappings

# dirhistory - Bash Directory History

This script overrides the bash cd command so that it saves the previous 
directory to a directory history. ALT-Left then moves back to previous 
directories in the history, and ALT-Right moves forward. ALT-Up changes 
to the parent directory. Finally, ALT-Down displays the history.

It also adds a cde command which copies all future directories to
the history and then changes to the directory, in order to preserve
all history.

# Install

Copy `.dirhistory.bash` to your home directory and source it from your `.bashrc`.

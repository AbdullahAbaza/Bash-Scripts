# Process Info

ps aux
ps aux --sort -%cpu
ps aux --sort -%mem | head -10
ps -eo pid,ppid,cmd,comm,%mem,%cpu --sort=-%mem | head -10

top -o %CPU | head -n 16
top -o %MEM | head -n 16


# using sed to replace strings

sed --in-place='.bak' 's/match1/replace1/g; s/match2/replace2/g' /tmp/some-file
sed --in-place='.bak' 's/\(first\|second\)/next/g' /tmp/some-file

# ANSI Colors escape codes

BLACK="\033[30m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
PINK="\033[35m"
CYAN="\033[36m"
WHITE="\033[37m"
NORMAL="\033[0;39m"

- usage: `echo -e "${RED} some red text... ${NORMAL} some normal text..."`





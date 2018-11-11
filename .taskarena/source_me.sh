#!/bin/sh

EDITOR=nvim
#EDITOR=vim


ROOT=$(dirname $(readlink -f $0))


PATH_LOCAL_VIMRC=$ROOT/.vimrc

DIR_LOCAL_VIMWIKI=$ROOT/.vimwiki

DIR_LOCAL_TASKWIKI=$ROOT/.taskwiki
DIR_LOCAL_TASKWIKI_RC=$DIR_LOCAL_TASKWIKI/.taskrc

DIR_LOCAL_TASKWARRIOR=$ROOT/.tasks
DIR_LOCAL_TASKWARRIOR_RC=$ROOT/.taskrc
DIR_LOCAL_TASKWARRIOR_HOOKS=$DIR_LOCAL_TASKWARRIOR/hooks

DIR_LOCAL_TIMEWARRIOR_DB=$ROOT/.timewarrior

DIR_HOOKS=$ROOT/.hooks
HOOK_TIMEW=$DIR_HOOKS/on-modify.timewarrior

FILE_TMP=$ROOT/.temp


export DIR_LOCAL_VIMWIKI=$DIR_LOCAL_VIMWIKI
export DIR_LOCAL_TASKWIKI=$DIR_LOCAL_TASKWIKI
export DIR_LOCAL_TASKWIKI_RC=$DIR_LOCAL_TASKWIKI_RC


# Point (n)vim to the local .vimrc.
# Store current used .vimrc/init.vim in $FILE_TMP.
$EDITOR "+:call system('echo \$MYVIMRC > $FILE_TMP')" "+:q!"
read VIMINIT_OLD_TEMP < $FILE_TMP
# Don't overwrite the original conf with multiple sources.
[ "$VIMINIT_OLD_TEMP" = "$PATH_LOCAL_VIMRC" ] || export MYVIMRC_OLD="$VIMINIT_OLD_TEMP"
# Make $EDITOR load the local .vimrc.
export MYVIMRC="$PATH_LOCAL_VIMRC"
export VIMINIT='source $MYVIMRC'

# Point taskwarrior to the correct dirs.
export TASKRC=$DIR_LOCAL_TASKWARRIOR_RC
export TASKDATA=$DIR_LOCAL_TASKWARRIOR

# Initialize taskwarrior dir / config file is not present if not present.
( [ -f $DIR_LOCAL_TASKWARRIOR_RC ] || [ -f $DIR_LOCAL_TASKWARRIOR ] ) || echo $(echo yes | task 2>&1) > /dev/null

# Store current task-path.
[ -n "$BIN_TASK" ] || BIN_TASK=$(which task)

# Strip override comments from tail output while keeping the colors intact.
task() {
  script --quiet --flush --return -c "$BIN_TASK $*" /dev/null \
    | sed "s#.*override: [$DIR_LOCAL_TASKWARRIOR|$DIR_LOCAL_TASKWARRIOR_RC].*##g"\
    | sed "s#$(dirname $BIN_TASK)/##g"\
    | sed '/^\s*$/d'
}

# Set up timewarrior database.
export TIMEWARRIORDB=$DIR_LOCAL_TIMEWARRIOR_DB
# Set up database if it does not existing.
[ -f $DIR_LOCAL_TIMEWARRIOR_DB ] || echo $(echo yes | timew 2>&1) > /dev/null
# Symlink on-modify script if not linked.
[ -h $DIR_LOCAL_TASKWARRIOR_HOOKS/${HOOK_TIMEW##*/} ] || ln -s $HOOK_TIMEW $DIR_LOCAL_TASKWARRIOR_HOOKS

# Check and setup vimwiki if it does not exist.
[ -d $DIR_LOCAL_VIMWIKI ] || mkdir $DIR_LOCAL_VIMWIKI

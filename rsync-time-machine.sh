#!/bin/bash
#
# Backup mimicking Time Machine from Mac OS X using rsync



# --- Variables --- #

OS=$(uname -s)
HOST=$(hostname)
DATE_FORMAT=$(date "+%Y-%m-%d-%H%M%S")
CURRENT_YEAR=$(date +%Y)
CURRENT_MONTH=$(date +%m)
RSYNC_OPTIONS="-E --archive --partial"

# Use absolute paths. Relative paths tend to break the hard linking advantage of rsync.
# Paths can include spaces as long as variable contents are double quoted
#SOURCE="[absolute path to source directory]"
#DESTINATION="[absolute path to backup destination]/$HOST"
#DESTINATION_VOLUME="[absolute path to backup volume]"

# --- Main Program --- #

## check parameter
check="true"
if ! source ~/bin/echo_log.sh ; then
  check="false"
fi
if [ -z "$SOURCE" ]; then
  log_error "ソースディレクトリが指定されていません"
  check="false"
fi
if [ -z "$DESTINATION" ]; then
  log_error "バックアップディレクトリが指定されていません"
  check="false"
fi
if [ -z "$DESTINATION_VOLUME" ] ; then
  log_error "バックアップ先ボリュームが指定されていません"
  check="false"
else
  if [ ! -d "$DESTINATION_VOLUME" ] ; then
    ## ボリュームがマウントされていない.
    check="false"
  fi
fi
if [ "$check" = "false" ]; then
    exit 1
fi

# Create destination if it does not exist
if [[ ! -d "$DESTINATION" ]] ; then
  mkdir -p "$DESTINATION"
fi

# Make inital backup if Latest does not exist, otherwise only copy what has changed
# and hard link to files that are the same
if [[ ! -L "$DESTINATION"/Latest ]] ; then
  rsync $RSYNC_OPTIONS \
                --delete \
                --exclude-from=$SOURCE/.rsync/exclude \
                "$SOURCE" "$DESTINATION"/$DATE_FORMAT
else
  rsync $RSYNC_OPTIONS \
               --delete \
               --delete-excluded \
               --exclude-from=$SOURCE/.rsync/exclude \
               --link-dest="$DESTINATION"/Latest \
               "$SOURCE" "$DESTINATION"/$DATE_FORMAT
fi

# Remove symlink to previous Latest backup
rm -f "$DESTINATION"/Latest

# Create symlink to latest backup
ln -s $DATE_FORMAT "$DESTINATION"/Latest



# --- Remove old backups --- #

# BSD date in OS X has a different syntax than GNU date in Linux
if [[ $OS == "Darwin" || $OS == "FreeBSD" ]]; then

  # Return YYYY one year ago from today
  LAST_YEAR=$(date -v -1y "+%Y")

elif [[ $OS == "Linux" ]]; then

  # Return YYYY one year ago from today
  LAST_YEAR=$(date -d "last year" "+%Y")

fi


# Keep monthly backups for one year
for (( month = 1 ; month < $CURRENT_MONTH ; month++ )); do
  # List latest backup from each month of current year
  # Use printf to pad the single digit months with a 0
  LATEST_BACKUP=$(find "$DESTINATION" -mindepth 1 -maxdepth 1 -name ${CURRENT_YEAR}-$(printf "%02d" $month)-* | sort | tail -n 1)
  find "$DESTINATION" -mindepth 1 -maxdepth 1 -name ${CURRENT_YEAR}-$(printf "%02d" $month)-* | grep -v "$LATEST_BACKUP" | xargs -I {} rm -rf {}
done

for (( month = $CURRENT_MONTH ; month <= 12 ; month++ )); do
  # List latest backup from each month of current year
  # Use printf to pad the single digit months with a 0
  LATEST_BACKUP=$(find "$DESTINATION" -mindepth 1 -maxdepth 1 -name ${LAST_YEAR}-$(printf "%02d" $month)-* | sort | tail -n 1)
  find "$DESTINATION" -mindepth 1 -maxdepth 1 -name ${LAST_YEAR}-$(printf "%02d" $month)-* | grep -v "$LATEST_BACKUP" | xargs -I {} rm -rf {}
done


# Remove backups older than one year
for (( month = 1 ; month < $CURRENT_MONTH ; month++ )); do
  find "$DESTINATION" -mindepth 1 -maxdepth 1 -type d -name "$LAST_YEAR-$(printf "%02d" $month)-*" | xargs -I {} rm -rf {}
done

find "$DESTINATION" -mindepth 1 -maxdepth 1 -type d ! -name "$CURRENT_YEAR-*" | grep -v "$LAST_YEAR-*" | xargs -I {} rm -rf {}

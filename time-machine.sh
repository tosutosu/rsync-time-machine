#!/bin/bash

export DESTINATION_VOLUME="/Volumes/Timemachine_MBP-1"

export APPNAME=$(basename "${0}")
export LOG_APPNAME_DISABLE="YES"
export DISABLE_COLOR="YES"

export TIMEOUT=600
## --------------------------------------------------
## main
## --------------------------------------------------
if ! source ~/bin/echo_log.sh ; then
    exit 1
fi

## Volumeの確認
if [ ! -d "$DESTINATION_VOLUME" ] ; then
  ## ボリュームがマウントされていない.
  exit 1
fi

## TimeMachine稼働の確認
[ ! -x ~/bin/wait_for_backup_process.sh ] && exit 1
if ! ~/bin/wait_for_backup_process.sh ; then
    log_info "他のバックアップ処理の終了を待機しています"
    if ! ~/bin/wait_for_backup_process.sh -S; then
        log_warn "他のバックアップ処理の待機時間を超過しました. exit 1"
        exit 1
    fi
fi

## 実行ファイル
log_info "バックアップを開始します"
declare -i start_time=$(date +%s)
tmutil startbackup
while [ "$(tmutil status | grep -c "Running = 1;" )" -gt 0 ] ; do sleep 1 ; done
declare -i processing_time=$(( $(date +%s) - start_time ))
log_info "バックアップが完了しました (処理時間 ${processing_time}sec)"


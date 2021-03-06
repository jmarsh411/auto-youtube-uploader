#!/bin/bash
# VARS
yt_lock_file='/tmp/yt_uploading.txt'
in_dir="$HOME/uploads"
bin_dir="$HOME/bin"
upl_script="$bin_dir/youtubeuploader"
log_file="$HOME/yt_upload_log.txt"
meta_fname='meta.txt'

# TODO:
# - add support for the filename to be inserted into the title
# - add thumbnail support to upload_dir
# - add token and secrets support to upload_dir
# - put program defaults in a default file that is sourced
# - allow a user config file to be sourced after defaults
# - send all output to a temp file and copy it to a permanent location only if
#   there were any failures
# - return status of upload_dir and log if upload failed


# UPLOAD_VARS

upload_dir()
{
    local workdir="$1"
    local title="$2"
    local description="$3"
    local tags="$4"
    local category_id="$5"
    cd "$workdir"
    # read meta file
    if [ -f "$meta_fname" ]
    then
        source "$meta_fname"
    fi
    # process all files in this directory with the current meta
    find -maxdepth 1 -type f ! -name '*.txt' |
    while read vid
    do
        "$upl_script" \
            -cache "$bin_dir/request.token" \
            -secrets "$bin_dir/client_secrets.json" \
            -filename "$vid" \
            -categoryId "$category_id" \
            -title "$title" \
            -description "$description" \
            -tags "$tags" \
            >> "$log_file" \
        && rm "$vid"
    done
    # process all sub-directories, passing meta
    find . -mindepth 1 -maxdepth 1 -type d ! -name . |
    while read dir
    do
        upload_dir "$dir" "$title" "$description" "$tags" "$category_id"
    done
    cd "$OLDPWD"
}


# MAIN
echo  "Upload script started $(date)" >> "$log_file"
(
    flock -n 200 || exit 1
    upload_dir "$in_dir"
    rm "$yt_lock_file"
) 200>"$yt_lock_file"
echo  "Upload script finished $(date)" >> "$log_file"

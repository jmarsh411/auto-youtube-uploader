#!/bin/bash
# VARS
yt_lock_file='/tmp/yt_uploading.txt'
in_dir="$HOME/uploads"
bin_dir="$HOME/bin"
upl_script="$bin_dir/youtubeuploader"
log_file="$HOME/yt_upload_log.txt"

# TODO:
# - somehow all the uploads are starting at the same time and it's immediately
#   reporting "finished" in the log. This causes some uploads to fail since
#   there isn't enough bandwidth. fix this
# - make it so the description will concatenate the contents of a desc.txt file
#  (with specific info) from the vid's folder to the general description
#  (which has social media). This can basically concatenate the desc.txts
#  recursively from the parent to the child directories
# - do the same for titles.
# - send all output to a temp file and copy it to a permanent location only if
#   there were any failures
# - return status of upload vids and log if upload failed


# UPLOAD_VARS
def_categ='20'  # Gaming

skyrim_desc='Characters:
https://drive.google.com/open?id=1GWwgRYyDCAPjmh9gEFx1HBreYUsoef5YSUFARnscbgQ
Plugins: https://docs.google.com/spreadsheets/d/1dH2tMfnolP2xETdSn8M9U0mFdTPo8H-DZ5WcZER9mTA/edit?usp=sharing
Mods: https://docs.google.com/spreadsheets/d/1V4j4JE4qsbGiYLlXQwnyzE0wGccrYtZkhbc4i_pUsxo/edit?usp=sharing

'

links='Twitter: https://twitter.com/GMRenGaming
Facebook: https://www.facebook.com/GMRenGaming
Nexusmods: https://www.nexusmods.com/skyrim/users/4958207/?'

upload_vids()
{
    find "$in_dir" -type f -print0 | sort | while IFS= read -r -d '' vid; do
        vname=`basename "$vid"`
        
        # temporary skyrim insert
        parentname="$(basename "$(dirname "$vid")")"
        if [ "$parentname" = 'skyrim' ]
        then
            description="$skyrim_desc$links"
        else
            description="$links"
        fi

        "$upl_script" \
            -cache "$bin_dir/request.token" \
            -secrets "$bin_dir/client_secrets.json" \
            -filename "$vid" \
            -categoryId "$def_categ" \
            -title "LP X - Ch Y Ep $vname - " \
            -description "$description" \
            >> "$log_file" \
        && rm "$vid"
    done
}


# MAIN
tstamp=`date`
echo  "Upload script started $tstamp" >> "$log_file"
(
    flock -n 200 || exit 1
    tstamp=`date`
    echo "Uploading started $tstamp" >> "$log_file"
    upload_vids
) 200>"$yt_lock_file"
tstamp=`date`
echo  "Uploading finished $tstamp" >> "$log_file"

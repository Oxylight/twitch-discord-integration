#!/bin/bash

# Reading config - default or specified
while getopts ":c:" opt; do
  case $opt in
    c)
      config=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done
if [[ $config ]]; then
  source $config
else
  source ./tw-dis.conf
fi

# Configuring environment for logs
if [[ -z "$logs_dir" ]]; then
  logs_dir='/var/log/tw-dis'
fi
if [[ ! -d $logs_dir ]]; then
  mkdir -p $logs_dir
fi
logs_file="$logs_dir/tw-dis.log"
touch $logs_file
# Check if logs file size is greater than 10MB, if yes then move to logs_file.1
if [[ $(stat -c%s "$logs_file") -gt 10485760 ]]; then
  i=1
  last_logs_file="$logs_file.$i"
  while [[ -e "$last_logs_file" ]]; do
    ((i++))
    last_logs_file="$logs_file.$i"
  done
  # Rename existing logs_files
  for ((j=i-1; j>=1; j--)); do
    existing_logs_file="$logs_file.$j"
    new_existing_logs_file="$logs_file.$((j+1))"
    if [[ -e "$existing_logs_file" ]]; then
      mv "$existing_logs_file" "$new_existing_logs_file"
    fi
  done
  mv "$logs_file" "$logs_file.1"
fi

# Configuring environment for work dir
if [[ -z "$work_dir" ]]; then
  work_dir='/etc/tw-dis'
fi
if [[ ! -d $work_dir ]]; then
  mkdir -p $work_dir
fi

# Starting to work
echo "[$(date)] : INFO : Twitch-discord-integration : Started." >> $logs_file

# Checking required variables
if [[ -z "$discord_webhook" ]]; then
  echo "[$(date)] : ERROR : Twitch-discord-integration check : Variable 'discord_webhook' is required, exiting." >> $logs_file
  exit 1
fi
if [[ -z "$twitch_client_id" ]]; then
  echo "[$(date)] : ERROR : Twitch-discord-integration check : Variable 'twitch_client_id' is required, exiting." >> $logs_file
  exit 1
fi
if [[ -z "$twitch_client_secret" ]]; then
  echo "[$(date)] : ERROR : Twitch-discord-integration check : Variable 'twitch_client_secret' is required, exiting." >> $logs_file
  exit 1
fi
if [[ -z "$twitch_channel_login" ]]; then
  echo "[$(date)] : ERROR : Twitch-discord-integration check : Variable 'twitch_channel_login' is required, exiting." >> $logs_file
  exit 1
fi
if [[ -z "$color" ]]; then
  color=6570404
fi

# Checking stream ID file
if [ ! -e $work_dir/id.txt ]; then
  echo -1 > $work_dir/id.txt
fi

# Checking $discord_webhook for validity
discord_data=$(curl -s -X GET $discord_webhook)
if [[ $(echo $discord_data | jq -r '.id') == null ]]; then
  echo "[$(date)] : ERROR : Twitch-discord-integration : Can not get discord webhook info. Probably invalid webhook have been provided, exiting." >> $logs_file
  exit 1
fi

# Receiving $oauth_token for Twtich
response=$(curl -s -X POST https://id.twitch.tv/oauth2/token -H 'Content-Type: application/x-www-form-urlencoded' \
  -d "client_id=$twitch_client_id&client_secret=$twitch_client_secret&grant_type=client_credentials")
oauth_token=$(echo $response | jq -r '.access_token')
if [[ $oauth_token == null ]]; then
  echo "[$(date)] : ERROR : Twitch-discord-integration : Can not get oauth_token, exiting." >> $logs_file
  exit 1
fi
echo "[$(date)] : INFO : Twitch-discord-integration : Received oauth_token." >> $logs_file

# Checking if stream is currently live
chan_info=$(curl -s -X GET https://api.twitch.tv/helix/streams?user_login=$twitch_channel_login \
  -H "Authorization: Bearer $oauth_token" -H "Client-Id: $twitch_client_id")
is_live=$(echo $chan_info | jq -r '.data[0].type')
if [[ ! $is_live == "live" ]]; then
  echo "[$(date)] : OK : Twitch-discord-integration : Live stream is not detected, exiting." >> $logs_file
  exit
fi

# Setting up $icon_url
if [ "$icon_url" = "discord" ]; then
  icon_url="https://cdn.discordapp.com/avatars/$(echo $discord_data | jq -r '.id')/$(echo $discord_data | jq -r '.avatar').png"
elif [ "$icon_url" = "twitch" ] || [ -z "$icon_url" ]; then
  icon_request=$(curl -s -X GET https://api.twitch.tv/helix/users?login=$twitch_channel_login \
    -H "Authorization: Bearer $oauth_token" -H "Client-Id: $twitch_client_id")
  icon_url=$(echo $icon_request | jq -r '.data[0].profile_image_url')
fi

# Getting stream data
title=$(echo $chan_info | jq -r '.data[0].title')
game=$(echo $chan_info | jq -r '.data[0].game_name')
id=$(echo $chan_info | jq -r '.data[0].id')
if [[ -z "$channel_name" ]]; then
  channel_name=$(echo $chan_info | jq -r '.data[0].user_name')
fi
if [[ -z "$alert_text" ]]; then
  alert_text="$channel_name started a stream! @everyone"
fi

# Checking that the stream ID has not changed since last script launch (i.e., the stream is the same).
if [[ $id == $(cat $work_dir/id.txt) ]]
then
  echo "[$(date)] : OK : Twitch-discord-integration : The same stream detected, exiting." >> $logs_file
  exit
fi
echo $id > $work_dir/id.txt

# Erasing ' and " to prevent crashing while calling Python
alert_text=$(echo "$alert_text" | tr -d "\'" | tr -d '\"')
title=$(echo "$title" | tr -d "\'" | tr -d '\"')
game=$(echo "$game" | tr -d "\'" | tr -d '\"')
channel_name=$(echo "$channel_name" | tr -d "\'" | tr -d '\"')

# If preview_url is not provided then use Twitch preview
if [[ -z "$preview_url" ]]; then
  curl https://static-cdn.jtvnw.net/previews-ttv/live_user_$twitch_channel_login.jpg --silent -o $work_dir/preview.jpg
  python3 "$(dirname "$(realpath "$0")")"/webhook.py -webhook "$discord_webhook" -content "$alert_text" -stream_title "$title" -game "$game" -name "$channel_name" \
    -url "https://www.twitch.tv/$twitch_channel_login" -icon_url "$icon_url" -color "$color" -preview "$work_dir/preview.jpg"  
  if [ $? -eq 0 ]
  then
      echo "[$(date)] : OK : Twitch-discord-integration : Alert sent with Twitch preview, exiting." >> $logs_file
      rm $work_dir/preview.jpg
      exit
  else
      "[$(date)] : ERROR : Twitch-discord-integration : Alert sending failed for unknown reason, exiting." >> $logs_file
      rm $work_dir/preview.jpg
      exit 1
  fi
else
  python3 "$(dirname "$(realpath "$0")")"/webhook.py -webhook "$discord_webhook" -content "$alert_text" -stream_title "$title" -game "$game" -name "$channel_name" \
    -url "https://www.twitch.tv/$twitch_channel_login" -icon_url "$icon_url" -color "$color" -preview_url "$preview_url"  
  if [ $? -eq 0 ]
  then
      echo "[$(date)] : OK : Twitch-discord-integration : Alert sent with custom preview, exiting." >> $logs_file
      exit
  else
      "[$(date)] : ERROR : Twitch-discord-integration : Alert sending failed for unknown reason, exiting." >> $logs_file
      exit 1
  fi
fi
#!/bin/bash

#Getting arguments
while getopts ":-:" optname; do
  case "$optname" in
    "-")
      case "${OPTARG}" in
        discord_webhook) 
          discord_webhook="$2"
          ;;
        twitch_client_id)
          twitch_client_id="$2"
          ;;
        twitch_client_secret)
          twitch_client_secret="$2"
          ;;
        twitch_channel_login)
          twitch_channel_login="$2"
          ;;
          alert_text)
          alert_text="$2"
          ;;
          preview_url)
          preview_url="$2"
          ;;
          channel_name)
          channel_name="$2"
          ;;
          icon_url)
          icon_url="$2"
          ;;
          color)
          color="$2"
          ;;
          logs_dir)
          logs="$2"
          ;;
          work_dir)
          work_dir="$2"
          ;;
        *)
          echo "Unknown option: --${OPTARG}"
          exit 1
          ;;
      esac
      ;;
    "?")
      echo "Unknown option: -$OPTARG"
      exit 1
      ;;
    ":")
      echo "No argument value for option: -$OPTARG"
      exit 1
      ;;
    *)
      echo "Unknown error while processing options"
      exit 1
      ;;
  esac
done

#Checking required arguments
if [[ -z "$discord_webhook" ]]; then
  echo "Error: The 'discord_webhook' field is required."
  exit 1
fi
if [[ -z "$twitch_client_id" ]]; then
  echo "Error: The 'twitch_client_id' field is required."
  exit 1
fi
if [[ -z "$twitch_client_secret" ]]; then
  echo "Error: The 'twitch_client_secret' field is required."
  exit 1
fi
if [[ -z "$twitch_channel_login" ]]; then
  echo "Error: The 'twitch_channel_login' field is required."
  exit 1
fi
if [[ -z "$color" ]]; then
  #(hex -> dec value)
  color=6570404
fi
if [[ -z "$logs_dir" ]]; then
  logs_dir='/var/log'
  if [[ ! -d $logs_dir ]]; then
    mkdir -p $logs_dir
  fi
  logs="$logs_dir/twitch-discord-integration-log.txt"
fi
if [[ -z "$work_dir" ]]; then
  work_dir='/etc/twitch-discord-integration'
  if [[ ! -d $work_dir ]]; then
    mkdir -p $work_dir
  fi
fi

#Checking stream ID file
if [ -e $work_dir/id.txt ]; then
    echo -1 > $work_dir/id.txt
fi

#Starting to work
echo [$(date)] : Twitch-discord-integration : Started >> $logs

#Checking $discord_webhook for validity and setting up $icon_url
discord_data=$(curl -s -X GET $discord_webhook)
if [[ $(echo $discord_data | jq -r '.id') == null ]]; then
  echo [$(date)] : ERROR : Twitch-discord-integration : Can not get discord webhook info, probably invalid webhook was provided, exiting >> $logs
  exit 1
fi
if [[ -z "$icon_url" ]]; then
  #if icon_url is not provided, then Discord webhook avatar is used
  icon_url="https://cdn.discordapp.com/avatars/$(echo $discord_data | jq -r '.id')/$(echo $discord_data | jq -r '.avatar').png"
fi

#Checking $twitch_token from file (if it exist) for validity, receiving new if expired
if [ -f $work_dir/twitch_token.txt ]; then
  readarray -t lines < $work_dir/twitch_token.txt
  twitch_token="${lines[0]}"
  expiration_time="${lines[1]}"
  if [[ $(date +%s) -ge $expiration_time ]]; then
    response=$(curl --silent -X POST https://id.twitch.tv/oauth2/token -H 'Content-Type: application/x-www-form-urlencoded' -d "client_id=$twitch_client_id&client_secret=$twitch_client_secret&grant_type=client_credentials")
    oauth_token=$(echo $response | jq -r '.access_token')
    if [[ $oauth_token == null ]]; then
      echo [$(date)] : ERROR : Twitch-discord-integration : Can not get oauth_token, exiting >> $logs
      exit 1
    fi
    expires_in_seconds=$(echo $response | jq -r '.expires_in')
    expiration_time=$(($(date +%s) + expires_in_seconds))
    echo $oauth_token > $work_dir/twitch_token.txt
    echo $expiration_time >> $work_dir/twitch_token.txt
    echo [$(date)] : INFO : Twitch-discord-integration : Received new oauth_token >> $logs
  fi
  echo [$(date)] : INFO : Twitch-discord-integration : Oauth_token not expired, using it >> $logs
else
  response=$(curl --silent -X POST https://id.twitch.tv/oauth2/token -H 'Content-Type: application/x-www-form-urlencoded' -d "client_id=$twitch_client_id&client_secret=$twitch_client_secret&grant_type=client_credentials")
  oauth_token=$(echo $response | jq -r '.access_token')
  if [[ $oauth_token == null ]]; then
    echo [$(date)] : ERROR : Twitch-discord-integration : Can not get oauth_token, exiting >> $logs
    exit 1
  fi
  expires_in_seconds=$(echo $response | jq -r '.expires_in')
  expiration_time=$(($(date +%s) + expires_in_seconds))
  echo $oauth_token > $work_dir/twitch_token.txt
  echo $expiration_time >> $work_dir/twitch_token.txt
  echo [$(date)] : INFO : Twitch-discord-integration : Received new oauth_token >> $logs
fi

#Checking if stream is currently live
chan_info=$(curl -s -X GET https://api.twitch.tv/helix/streams?user_login=$twitch_channel_login -H "Authorization: Bearer $oauth_token" -H "Client-Id: $twitch_client_id")
is_live=$(echo $chan_info | jq -r '.data.type')
if [[ $is_live == null || ! $is_live == "live" ]]; then
  echo [$(date)] : OK : Twitch-discord-integration : Live stream is not detected, exiting >> $logs
  exit
fi

#Getting stream data
title=$(echo $chan_info | jq -r '.data.title')
game=$(echo $chan_info | jq -r '.data.game_name')
id=$(echo $chan_info | jq -r '.data.id')
if [[ -z "$channel_name" ]]; then
  channel_name=$(echo $chan_info | jq -r '.data.user_name')
fi
if [[ -z "$alert_text" ]]; then
  alert_text="$channel_name started a stream! @everyone"
fi

#Checking that the stream ID has not changed since last launch (i.e., the stream is the same).
if [[ $id == $(cat $work_dir/id.txt) ]]
then
  echo [$(date)] : OK : Twitch-discord-integration : The same stream detected, exiting >> $logs
  exit
fi
echo $id > id.txt

#if preview_url is not provided then use Twitch preview
if [[ -z "$preview_url" ]]; then
  curl https://static-cdn.jtvnw.net/previews-ttv/live_user_$twitch_channel_login.jpg --silent -o $work_dir/preview.jpg
  python3 webhook.py -webhook "$discord_webhook" -content "$alert_text" -stream_title "$title" -game "$game" -name "$channel_name" -url "https://www.twitch.tv/$twitch_channel_login" \
  -icon_url "$icon_url" -color "$color" -preview "$work_dir/preview.jpg"  
  rm $work_dir/preview.jpg
  echo [$(date)] : OK : Twitch-discord-integration : Alert sent, using Twitch preview, exiting >> $logs
  exit
else
  python3 webhook.py -webhook "$discord_webhook" -content "$alert_text" -stream_title "$title" -game "$game" -name "$channel_name" -url "https://www.twitch.tv/$twitch_channel_login" \
  -icon_url "$icon_url" -color "$color" -preview_url "$preview_url"  
  echo [$(date)] : OK : Twitch-discord-integration : Alert sent, using custom preview, exiting >> $logs
  exit
fi
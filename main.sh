#!/bin/bash

#Getting arguments
while getopts ":-:" optname; do
  case "$optname" in
    -)
      case "${OPTARG}" in
        discord_webhook)
          discord_webhook="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
          if [[ "$discord_webhook" == --* ]]; then
            echo "[$(date)] : ERROR : Twitch-discord-integration pre-check : Argument 'discord_webhook' is required, exiting."
            exit 1
          fi
          ;;
        twitch_client_id)
          twitch_client_id="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
          if [[ "$twitch_client_id" == --* ]]; then
            echo "[$(date)] : ERROR : Twitch-discord-integration pre-check : Argument 'twitch_client_id' is required, exiting."
            exit 1
          fi
          ;;
        twitch_client_secret)
          twitch_client_secret="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
          if [[ "$twitch_client_secret" == --* ]]; then
            echo "[$(date)] : ERROR : Twitch-discord-integration pre-check : Argument 'twitch_client_secret' is required, exiting."
            exit 1
          fi
          ;;
        twitch_channel_login)
          twitch_channel_login="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
          if [[ "$twitch_channel_login" == --* ]]; then
            echo "[$(date)] : ERROR : Twitch-discord-integration pre-check : Argument 'twitch_channel_login' is required, exiting."
            exit 1
          fi
          ;;
          alert_text)
          alert_text="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
          if [[ "$alert_text" == --* ]]; then
            echo "[$(date)] : ERROR : Twitch-discord-integration pre-check : Argument 'alert_text' is required, exiting."
            exit 1
          fi
          ;;
          preview_url)
          preview_url="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
          if [[ "$preview_url" == --* ]]; then
            echo "[$(date)] : ERROR : Twitch-discord-integration pre-check : Argument 'preview_url' is required, exiting."
            exit 1
          fi
          ;;
          channel_name)
          channel_name="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
          if [[ "$channel_name" == --* ]]; then
            echo "[$(date)] : ERROR : Twitch-discord-integration pre-check : Argument 'channel_name' is required, exiting."
            exit 1
          fi
          ;;
          icon_url)
          icon_url="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
          if [[ "$icon_url" == --* ]]; then
            echo "[$(date)] : ERROR : Twitch-discord-integration pre-check : Argument 'icon_url' is required, exiting."
            exit 1
          fi
          ;;
          color)
          color="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
          if [[ "$color" == --* ]]; then
            echo "[$(date)] : ERROR : Twitch-discord-integration pre-check : Argument 'color' is required, exiting."
            exit 1
          fi
          ;;
          logs_dir)
          logs_dir="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
          if [[ "$logs_dir" == --* ]]; then
            echo "[$(date)] : ERROR : Twitch-discord-integration pre-check : Argument 'logs_dir' is required, exiting."
            exit 1
          fi
          ;;
          work_dir)
          work_dir="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
          if [[ "$work_dir" == --* ]]; then
            echo "[$(date)] : ERROR : Twitch-discord-integration pre-check : Argument 'work_dir' is required, exiting."
            exit 1
          fi
          ;;
        *)
          echo "Unknown option: --${OPTARG}."
          exit 1
          ;;
      esac
      ;;
    "?")
      echo "Unknown option: -$OPTARG."
      exit 1
      ;;
    *)
      echo "Unknown error while processing options."
      exit 1
      ;;
  esac
done

#Checking required arguments (probalby legacy? need tests)
if [[ -z "$discord_webhook" ]]; then
  echo "[$(date)] : ERROR : Twitch-discord-integration pre-check : Argument 'discord_webhook' is required, exiting."
  exit 1
fi
if [[ -z "$twitch_client_id" ]]; then
  echo "[$(date)] : ERROR : Twitch-discord-integration pre-check : Argument 'twitch_client_id' is required, exiting."
  exit 1
fi
if [[ -z "$twitch_client_secret" ]]; then
  echo "[$(date)] : ERROR : Twitch-discord-integration pre-check : Argument 'twitch_client_secret' is required, exiting."
  exit 1
fi
if [[ -z "$twitch_channel_login" ]]; then
  echo "[$(date)] : ERROR : Twitch-discord-integration pre-check : Argument 'twitch_channel_login' is required, exiting."
  exit 1
fi
if [[ -z "$color" ]]; then
  color=6570404
fi
if [[ -z "$logs_dir" ]]; then
  logs_dir='/var/log'
fi
if [[ ! -d $logs_dir ]]; then
  mkdir -p $logs_dir
fi
logs_file="$logs_dir/twitch-discord-integration-log.txt"
touch $logs_file
if [[ -z "$work_dir" ]]; then
  work_dir='/etc/twitch-discord-integration'
fi
if [[ ! -d $work_dir ]]; then
  mkdir -p $work_dir
fi

#Checking stream ID file
if [ -e $work_dir/id.txt ]; then
    echo -1 > $work_dir/id.txt
fi

#Starting to work
echo "[$(date)] : INFO : Twitch-discord-integration : Started." >> $logs_file

#Checking $discord_webhook for validity and setting up $icon_url
discord_data=$(curl -s -X GET $discord_webhook)
if [[ $(echo $discord_data | jq -r '.id') == null ]]; then
  echo "[$(date)] : ERROR : Twitch-discord-integration : Can not get discord webhook info. Probably invalid webhook have been provided, exiting." >> $logs_file
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
    response=$(curl -s -X POST https://id.twitch.tv/oauth2/token -H 'Content-Type: application/x-www-form-urlencoded' \
      -d "client_id=$twitch_client_id&client_secret=$twitch_client_secret&grant_type=client_credentials")
    oauth_token=$(echo $response | jq -r '.access_token')
    if [[ $oauth_token == null ]]; then
      echo "[$(date)] : ERROR : Twitch-discord-integration : Can not get oauth_token, exiting." >> $logs_file
      exit 1
    fi
    expires_in_seconds=$(echo $response | jq -r '.expires_in')
    expiration_time=$(($(date +%s) + expires_in_seconds))
    echo $oauth_token > $work_dir/twitch_token.txt
    echo $expiration_time >> $work_dir/twitch_token.txt
    echo "[$(date)] : INFO : Twitch-discord-integration : Received new oauth_token." >> $logs_file
  fi
  echo "[$(date)] : INFO : Twitch-discord-integration : Oauth_token is not expired, using existing token." >> $logs_file
else
  response=$(curl -s -X POST https://id.twitch.tv/oauth2/token -H 'Content-Type: application/x-www-form-urlencoded' \
    -d "client_id=$twitch_client_id&client_secret=$twitch_client_secret&grant_type=client_credentials")
  oauth_token=$(echo $response | jq -r '.access_token')
  if [[ $oauth_token == null ]]; then
    echo "[$(date)] : ERROR : Twitch-discord-integration : Can not get oauth_token, exiting." >> $logs_file
    exit 1
  fi
  expires_in_seconds=$(echo $response | jq -r '.expires_in')
  expiration_time=$(($(date +%s) + expires_in_seconds))
  echo $oauth_token > $work_dir/twitch_token.txt
  echo $expiration_time >> $work_dir/twitch_token.txt
  echo "[$(date)] : INFO : Twitch-discord-integration : Received new oauth_token." >> $logs_file
fi

#Checking if stream is currently live
chan_info=$(curl -s -X GET https://api.twitch.tv/helix/streams?user_login=$twitch_channel_login \
  -H "Authorization: Bearer $oauth_token" -H "Client-Id: $twitch_client_id")
is_live=$(echo $chan_info | jq -r '.data.type')
if [[ ! $is_live == "live" ]]; then
  echo "[$(date)] : OK : Twitch-discord-integration : Live stream is not detected, exiting." >> $logs_file
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
  echo "[$(date)] : OK : Twitch-discord-integration : The same stream detected, exiting." >> $logs_file
  exit
fi
echo $id > id.txt

#if preview_url is not provided then use Twitch preview
if [[ -z "$preview_url" ]]; then
  curl https://static-cdn.jtvnw.net/previews-ttv/live_user_$twitch_channel_login.jpg --silent -o $work_dir/preview.jpg
  python3 webhook.py -webhook "$discord_webhook" -content "$alert_text" -stream_title "$title" -game "$game" -name "$channel_name" \
    -url "https://www.twitch.tv/$twitch_channel_login" -icon_url "$icon_url" -color "$color" -preview "$work_dir/preview.jpg"  
  rm $work_dir/preview.jpg
  echo "[$(date)] : OK : Twitch-discord-integration : Alert sent with Twitch preview, exiting." >> $logs_file
  exit
else
  python3 webhook.py -webhook "$discord_webhook" -content "$alert_text" -stream_title "$title" -game "$game" -name "$channel_name" \
    -url "https://www.twitch.tv/$twitch_channel_login" -icon_url "$icon_url" -color "$color" -preview_url "$preview_url"  
  echo "[$(date)] : OK : Twitch-discord-integration : Alert sent with custom preview, exiting." >> $logs_file
  exit
fi
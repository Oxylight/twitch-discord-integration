#!/bin/bash
logs='/var/log/twitch-discord-integration-log.txt'
work_dir='/etc/twitch-discord-integration/'
cd $work_dir

if [ ! -f error_1080.jpg ]; then
    curl https://static-cdn.jtvnw.net/ttv-static/404_preview-1920x1080.jpg --silent --output error1080.jpg
fi
if [ ! -f error_720.jpg ]; then
    curl https://static-cdn.jtvnw.net/ttv-static/404_preview-1280x720.jpg --silent --output error720.jpg
fi
if [ ! -f id.txt ]; then
    echo 1 > id.txt
fi

echo [$(date)] : Started job >> $logs
res=$(curl --silent -X POST https://id.twitch.tv/oauth2/token -H 'Content-Type: application/x-www-form-urlencoded' -d "client_id=$2&client_secret=$3&grant_type=client_credentials")
oauth_token=$(echo $res | python3 -c "import sys, json; data=json.load(sys.stdin); print('error') if 'access_token' not in data else print(data['access_token'])")
if [[ $oauth_token == 'error' ]]
then
  echo [$(date)] : ERROR - Exited because can not get oauth_token >> $logs
  exit
fi

chan_info=$(curl --silent -X GET https://api.twitch.tv/helix/streams?user_login=$4 -H "Authorization: Bearer $oauth_token" -H "Client-Id: $2")
is_live=$(echo $chan_info | python3 -c "import sys, json; data=json.load(sys.stdin); not any(item for item in data.values()) and print('error')")
if [[ $is_live == 'error' ]]
then
  echo [$(date)] : OK - No stream detected >> $logs
  exit
fi

title=$(echo $chan_info | python3 -c "import sys, json; print(json.load(sys.stdin)['data'][0]['title'])")
game=$(echo $chan_info | python3 -c "import sys, json; print(json.load(sys.stdin)['data'][0]['game_name'])")
id=$(echo $chan_info | python3 -c "import sys, json; print(json.load(sys.stdin)['data'][0]['id'])")

if [[ $id == $(cat id.txt) ]]
then
  echo [$(date)] : OK - The same stream detected >> $logs
  exit
fi
echo $id > id.txt

if [[ $6 == 'f' ]]
then
  curl https://static-cdn.jtvnw.net/previews-ttv/live_user_$4-1920x1080.jpg --silent --output preview.jpg
  if cmp -s preview.jpg error_1080.jpg ; then
    rm preview.jpg
    curl https://static-cdn.jtvnw.net/previews-ttv/live_user_$4-1280x720.jpg --silent --output preview.jpg
    if cmp -s preview.jpg error_720.jpg ; then
      if [[ $7 == '' ]]
      then
        python3 webhook.py -stream_name "$title" -game "$game" -url "https://www.twitch.tv/$4" -content "$5" -webhook "$1"
      else
        python3 webhook.py -stream_name "$title" -game "$game" -url "https://www.twitch.tv/$4" -content "$5" -webhook "$1" -name "$7"
      fi
      echo [$(date)] : OK - Alert sent, using no preview >> $logs
    else
      if [[ $7 == '' ]]
      then
        python3 webhook.py -stream_name "$title" -game "$game" -img "https://static-cdn.jtvnw.net/previews-ttv/live_user_$4-1280x720.jpg" -url "https://www.twitch.tv/$4" -content "$5" -webhook "$1"
      else
        python3 webhook.py -stream_name "$title" -game "$game" -img "https://static-cdn.jtvnw.net/previews-ttv/live_user_$4-1280x720.jpg" -url "https://www.twitch.tv/$4" -content "$5" -webhook "$1" -name "$7"
      fi
      echo [$(date)] : OK - Alert sent, using 720p preview >> $logs
    fi
  else
    if [[ $7 == '' ]]
    then
      python3 webhook.py -stream_name "$title" -game "$game" -img "https://static-cdn.jtvnw.net/previews-ttv/live_user_$4-1920x1080.jpg" -url "https://www.twitch.tv/$4" -content "$5" -webhook "$1"
    else
      python3 webhook.py -stream_name "$title" -game "$game" -img "https://static-cdn.jtvnw.net/previews-ttv/live_user_$4-1920x1080.jpg" -url "https://www.twitch.tv/$4" -content "$5" -webhook "$1" -name "$7"
    fi
    echo [$(date)] : OK - Alert sent, using 1080p preview >> $logs
  fi
  rm preview.jpg
else
  if [[ $7 == '' ]]
  then
    python3 webhook.py -stream_name "$title" -game "$game" -img "$6" -url "https://www.twitch.tv/$4" -content "$5" -webhook "$1"
  else
    python3 webhook.py -stream_name "$title" -game "$game" -img "$6" -url "https://www.twitch.tv/$4" -content "$5" -webhook "$1" -name "$7"
  fi
  echo [$(date)] : OK - Alert sent, using custom preview >> $logs
fi
# Twitch to Discord alert script
A script that notifies your audience that you have started a Twitch stream using a Discord webhook.<br />
## Requirements
1. Bash
2. Curl
3. jq
4. Python3
5. [python-discord-webhook](https://github.com/lovvskillz/python-discord-webhook/)
6. Twitch dev app (create one here: [Twitch Developers](https://dev.twitch.tv/console)), [docs](https://dev.twitch.tv/docs/api/get-started)
## Usage
`./main.sh --discord_webhook <discord_webhook> --twitch_client_id <twitch_client_id> --twitch_client_secret <twitch_client_secret> --twitch_channel_login <twitch-channel-login> --alert_text <alert-text> --preview_url <preview_url> --channel_name <channel_name> --icon_url <icon_url> --color <color> --logs_dir <logs_dir> --work_dir <work_dir>`<br />
## Arguments
| Name | Description | Required |
| --- | --- | --- |
| `discord_webhook` | Discord webhook URL for sending alerts, you can create one at `<your server> -> Settings -> Integrations -> Webhooks` | Yes |
| `twitch_client_id` | Twitch dev app client ID, (create app here: [Twitch Developers](https://dev.twitch.tv/console)) | Yes |
| `twitch_client_secret` | Twitch dev app client secret, (create app here: [Twitch Developers](https://dev.twitch.tv/console)) | Yes |
| `twitch_channel_login` | Twitch channel login that used to track streams (can be taken from URL https://twitch.tv/<twitch_login>) | Yes |
| `alert_text` | Text that will be used for alerts. Default: `<channel_name> started a stream! @everyone`| No |
| `preview_url` | URL that leads to image that will be used as preview. If not provided, Twitch preview will be used. | No |
| `channel_name` | Custom channel name that will be used in alerts, does not affect twitch_channel_login. Default: Twitch username. | No |
| `icon_url` | URL that leads to image that will be used as icon in alert. Default: avatar from Discord webhook. | No |
| `color` | Color of the embed alert. Default: `6570404` (Hex -> Dec value) | No |
| `logs_dir` | Directory where log will be stored. Default: `/var/log` | No |
| `work_dir` | Directory where script will store data. Default: `/etc/twitch-discord-integration` | No |
## Another information
There's only one type of alert, you can create more using [python-discord-webhook docs](https://github.com/lovvskillz/python-discord-webhook/#basic-webhook) and inserting to current code [webhook.py](/webhook.py).<br />
## Disclaimer
This project is not affiliated with Twitch or Discord or any other company. Any trademarks, logos, or brand names mentioned or shown in this project are the property of their respective owners. The use of such trademarks, logos, or brand names does not imply endorsement or affiliation with the project.
## TODO
1. ~~Add to checking stream preview image saving system to be preview avaliable all the time~~ Done, need testing
2. Create help page
3. Create log-level setting
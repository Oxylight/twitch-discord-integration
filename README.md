# Twitch to Discord alert script
A script that notifies your audience that you have started a Twitch stream using a Discord webhook.<br />
## Requirements
1. Bash
2. Curl
3. jq
4. Python 3
5. [python-discord-webhook](https://github.com/lovvskillz/python-discord-webhook/) and all requirements
6. Twitch dev app (create one here: [Twitch Developers](https://dev.twitch.tv/console)), [docs](https://dev.twitch.tv/docs/api/get-started)
## Installation
TODO (add your-path etc)<br />
Clone project with git: `git clone https://github.com/Oxylight/twitch-discord-integration.git`.<br />
Setup (link) your config.<br />
Add execute rights to script: `sudo chmod u+x /your/path/to/script/main.sh`.<br />
Run it!<br />
## Usage
`./main.sh` or `./main.sh -c <path-to-config>`.<br />
Optionally you can make a cronjob: `sudo crontab -e`.<br />
Add line to the end of file `* * * * * /your/path/to/script/main.sh`.<br />
## Configuring
Config file should have UTF-8 encoding.<br />
Structure of config: `key=value`, use `''` or `""` for value if you want to use value with spaces (for example, in alert text).<br />
| Name | Description | How to obtain / Default | Required |
| --- | --- | --- | --- |
| `discord_webhook` | Discord webhook URL for sending alerts. | Create one at `<your server> -> Settings -> Integrations -> Webhooks`. | Yes |
| `twitch_client_id` | Twitch dev app client ID. | Create app here: [Twitch Developers](https://dev.twitch.tv/console). | Yes |
| `twitch_client_secret` | Twitch dev app client secret. | Create app here: [Twitch Developers](https://dev.twitch.tv/console). | Yes |
| `twitch_channel_login` | Twitch channel login that used to track streams. | Can be taken from your Twitch URL: https://twitch.tv/<twitch_login>. | Yes |
| `alert_text` | Text that will be used for alerts. | Default: `<channel_name> started a stream! @everyone`. | No |
| `preview_url` | URL that leads to image that will be used as preview. | If not provided, Twitch preview will be used. | No |
| `channel_name` | Custom channel name that will be used in alerts, does not affect twitch_channel_login. | Default: Twitch username. | No |
| `icon_url` | URL that leads to image that will be used as icon in alert OR `discord` that will use Discord webhook avatar OR `twitch` that will use Twitch avatar. | Default: Twitch avatar. | No |
| `color` | Color of the embed alert. | Default: `6570404`. | No |
| `logs_dir` | Directory where logs will be stored. | Default: `/var/log/tw-dis`. | No |
| `work_dir` | Directory where script will store data. | Default: `/etc/tw-dis`. | No |
## Another information
There's only one type of alert, you can create more using [python-discord-webhook docs](https://github.com/lovvskillz/python-discord-webhook/#basic-webhook) and inserting to current code [webhook.py](/webhook.py).<br />
## Disclaimer
This project is not affiliated with Twitch or Discord or any other company. Any trademarks, logos, or brand names mentioned or shown in this project are the property of their respective owners. The use of such trademarks, logos, or brand names does not imply endorsement or affiliation with the project.
## TODO
1. Create help page.
2. Create log-level setting.
## Known bugs
1. ~`'` in fields (for example in description) can break script. Probably would be fixed by erasing them like `tr -d "'" | tr -d '"'` or `sed "s/['\"]//g"`.~ Probably fixed.
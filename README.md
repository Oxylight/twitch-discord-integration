# Twitch to Discord alert script
Simple script that alerts your audience that you have started a stream on Twitch using Discord Webhook<br />
TODO: insert image (example of alert)<br />
## Requirements
1. Bash
2. Curl 7.68.0
2. Python 3.8.10
3. [python-discord-webhook](https://github.com/lovvskillz/python-discord-webhook/) 0.16.3
4. Create app at [Twitch Developers](https://dev.twitch.tv/console), [docs](https://dev.twitch.tv/docs/api/get-started)
## Usage
`./tw.dis.webhook.sh <discord_webhook> <twitch_client_id> <twitch_client_secret> <twitch-channel-name> <alert-text> <force preview or image link> <name-optional>`<br />
Example: `./tw.dis.webhook.sh aaabbbccc bbbcccddd cccaaabbb oxylight_ "@everyone Oh, look, Oxy had started stream <:DerjiVKurse:843184516281139230>" 'f' Oxylight`
## Another information
For now there's only one type of alert, you can create more using [python-discord-webhook docs](https://github.com/lovvskillz/python-discord-webhook/#basic-webhook) and replacing current one [webhook.py](/webhook.py).<br />
Twitch preview from stream can be founded at link: `https://static-cdn.jtvnw.net/previews-ttv/live_user_<name>-<w>x<h>.jpg`, for example: `https://static-cdn.jtvnw.net/previews-ttv/live_user_oxylight_-1920x1080.jpg`, but Discord will show an error image in alert after stream. So, look TODO 3. For now you have to choose what to use in arguments.<br />
## TODO
1. Add checks for all arguments
2. Add Discord webhook error handler
3. Add to checking stream preview image saving system to be preview avaliable all the time
4. Rewrite bash args using case and getopts
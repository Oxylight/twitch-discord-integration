from discord_webhook import DiscordWebhook, DiscordEmbed
import sys, argparse

def createParser ():
  parser = argparse.ArgumentParser()
  parser.add_argument('-webhook')
  parser.add_argument('-content')
  parser.add_argument('-stream_title')
  parser.add_argument('-game')
  parser.add_argument('-name')
  parser.add_argument('-url')
  parser.add_argument('-icon_url')
  parser.add_argument('-preview_url')
  parser.add_argument('-preview')
  parser.add_argument('-color', default=6570404)
  return parser

parser = createParser()
args = parser.parse_args()
content=args.content
webhook = DiscordWebhook(url=args.webhook, rate_limit_retry=True, content = content)

embed = DiscordEmbed(title=args.stream_title, description=args.game, color=int(args.color), url=args.url)
embed.set_author(name=args.name, url=args.url, icon_url=args.icon_url)
if not args.preview_url: # if no image url provided, then use preview from stream
  with open(f"{args.preview}", "rb") as f:
    webhook.add_file(file=f.read(), filename='preview.jpg')
  embed.set_image(url='attachment://preview.jpg')
else:
  embed.set_image(url=args.preview_url)
embed.add_embed_field(name='Link', value=args.url)

webhook.add_embed(embed)
response = webhook.execute()
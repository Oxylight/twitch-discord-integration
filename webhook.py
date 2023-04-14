from discord_webhook import DiscordWebhook, DiscordEmbed
import sys, argparse

def createParser ():
  parser = argparse.ArgumentParser()
  parser.add_argument('-dir', required=True)
  parser.add_argument('-webhook', required=True)
  parser.add_argument('-content', default='Content message')
  parser.add_argument('-stream_title', default='Stream name')
  parser.add_argument('-game', default='Game')
  parser.add_argument('-name', default='Name')
  parser.add_argument('-url', required=True)
  parser.add_argument('-icon_url', default='https://img.playbook.com/i4key_9EsmQXb9G7OHzZLOWF_OcDOtes-AYf5WsS_eY/Z3M6Ly9wbGF5Ym9v/ay1hc3NldHMtcHVi/bGljL2FlOTFiNTg4/LWIwMmUtNDhiMS04/MDU0LTE0OWEzMDg2/ZWI3Ng')
  parser.add_argument('-img')
  parser.add_argument('-color', default=6570404)
  return parser

parser = createParser()
args = parser.parse_args()
content=args.content
webhook = DiscordWebhook(url=args.webhook, rate_limit_retry=True, content = content)

embed = DiscordEmbed(title=args.stream_title, description=args.game, color=args.color, url=args.url)
embed.set_author(name=args.name, url=args.url, icon_url=args.icon_url)
if not args.img:
  with open(f"{args.dir}/preview.jpg", "rb") as f:
    webhook.add_file(file=f.read(), filename='preview.jpg')
  embed.set_image(url='attachment://preview.jpg')
else:
  embed.set_image(url=args.img)
embed.add_embed_field(name='Link', value=args.url)

webhook.add_embed(embed)
response = webhook.execute()
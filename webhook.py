from discord_webhook import DiscordWebhook, DiscordEmbed
import sys, argparse

def createParser ():
  parser = argparse.ArgumentParser()
  parser.add_argument('-webhook')
  parser.add_argument('-content', default='Content message')
  parser.add_argument('-stream_name', default='Stream name')
  parser.add_argument('-game', default='Game')
  parser.add_argument('-name', default='Name')
  parser.add_argument('-url', default='https://twitch.tv')
  parser.add_argument('-icon_url', default='https://img.playbook.com/i4key_9EsmQXb9G7OHzZLOWF_OcDOtes-AYf5WsS_eY/Z3M6Ly9wbGF5Ym9v/ay1hc3NldHMtcHVi/bGljL2FlOTFiNTg4/LWIwMmUtNDhiMS04/MDU0LTE0OWEzMDg2/ZWI3Ng')
  parser.add_argument('-img', default='https://img.playbook.com/YfbdwbhcK1t7y2lXHofPG5OwxEvEJyu0KBQTOUc3agY/Z3M6Ly9wbGF5Ym9v/ay1hc3NldHMtcHVi/bGljL2M3MjAwYWMy/LTE5NjYtNDNlMy1i/YmFhLTNiZGE1Yzg0/NzJjZQ')
  return parser

parser = createParser()
args = parser.parse_args()
content=args.content

embed = DiscordEmbed(title=args.stream_name, description=args.game, color=6570404, url=args.url)
embed.set_author(name=args.name, url=args.url, icon_url=args.icon_url)
embed.set_image(url=args.img)
embed.add_embed_field(name='Link', value=args.url)

webhook = DiscordWebhook(url=args.webhook, content = content)
webhook.add_embed(embed)
response = webhook.execute()
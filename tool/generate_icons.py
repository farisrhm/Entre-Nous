"""Rebuild the typographic app icon from the bundled font (Pillow required)."""
from pathlib import Path
import json
from PIL import Image, ImageDraw, ImageFont
root=Path(__file__).resolve().parents[1]
image=Image.new('RGB',(1024,1024),'#243b32')
draw=ImageDraw.Draw(image)
draw.rounded_rectangle((92,92,932,932),radius=220,outline='#c9ac78',width=4)
font=ImageFont.truetype(str(root/'assets/fonts/CormorantGaramond.ttf'),360)
draw.text((512,460),'JN',font=font,fill='#f8f4ec',anchor='mm',stroke_width=0)
draw.line([(390,700),(634,700)],fill='#c9ac78',width=3)
draw.polygon([(512,658),(529,680),(512,702),(495,680)],fill='#c9ac78')
icons=root/'ios/Runner/Assets.xcassets/AppIcon.appiconset'
for spec in json.loads((icons/'Contents.json').read_text())['images']:
 size=round(float(spec['size'].split('x')[0])*float(spec['scale'].rstrip('x')))
 image.resize((size,size),Image.Resampling.LANCZOS).save(icons/spec['filename'])
for density,size in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:
 image.resize((size,size),Image.Resampling.LANCZOS).save(root/f'android/app/src/main/res/mipmap-{density}/ic_launcher.png')
for size in [192,512]:
 for name in [f'Icon-{size}.png',f'Icon-maskable-{size}.png']:
  image.resize((size,size),Image.Resampling.LANCZOS).save(root/'web/icons'/name)
image.resize((32,32),Image.Resampling.LANCZOS).save(root/'web/favicon.png')
image.save(root/'assets/images/app-icon.png')

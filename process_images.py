import os
import subprocess
import sys

def ensure_pillow():
    try:
        from PIL import Image, ImageDraw
    except ImportError:
        subprocess.check_call([sys.executable, "-m", "pip", "install", "Pillow"])
        from PIL import Image, ImageDraw

ensure_pillow()
from PIL import Image, ImageDraw

def mask_circle(img_path, out_path, size):
    img = Image.open(img_path).convert("RGBA")
    img = img.resize(size, Image.Resampling.LANCZOS)
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.ellipse((0, 0, size[0], size[1]), fill=255)
    img.putalpha(mask)
    img.save(out_path, "PNG")

def mask_round_rect(img_path, out_path, size, radius, crop_box=None):
    img = Image.open(img_path).convert("RGBA")
    if crop_box:
        img = img.crop(crop_box)
    img = img.resize(size, Image.Resampling.LANCZOS)
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size[0], size[1]), radius=radius, fill=255)
    img.putalpha(mask)
    img.save(out_path, "PNG")

base_dir = r"C:\Users\great\.gemini\antigravity\brain\d824c89a-8089-4255-a36f-5df55f81741e"
dest_dir = r"c:\My Data\Projects\AntiGravity\Godot Projects\ThroneBound Chess\assets\textures\ui"

print("Processing lion grabber...")
mask_circle(os.path.join(base_dir, "lion_grabber_1787491857669.jpg"), os.path.join(dest_dir, "lion_grabber.png"), (64, 64))

print("Processing switches...")
mask_round_rect(os.path.join(base_dir, "switch_on_1787491869945.jpg"), os.path.join(dest_dir, "switch_on.png"), (160, 160), 20, (200, 150, 824, 874))
mask_round_rect(os.path.join(base_dir, "switch_off_1787491881890.jpg"), os.path.join(dest_dir, "switch_off.png"), (160, 160), 20, (200, 150, 824, 874))

print("Processing cartouche...")
mask_round_rect(os.path.join(base_dir, "brass_cartouche_1787491892594.jpg"), os.path.join(dest_dir, "brass_cartouche.png"), (450, 150), 30, (50, 250, 974, 750))

print("Done.")

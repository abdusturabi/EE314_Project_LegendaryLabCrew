import os
from PIL import Image

def rgb_to_rgb332(r, g, b):
    return ((r & 0b11100000) | ((g & 0b11100000) >> 3) | ((b & 0b11000000) >> 6))

def image_to_mif(image_path, mif_path):
    img = Image.open(image_path).convert('RGB')
    width, height = img.size

    with open(mif_path, 'w') as f:
        f.write("WIDTH=8;\n")
        f.write(f"DEPTH={width * height};\n")
        f.write("ADDRESS_RADIX=UNS;\n")
        f.write("DATA_RADIX=HEX;\n")
        f.write("CONTENT BEGIN\n")

        addr = 0
        for y in range(height):
            for x in range(width):
                r, g, b = img.getpixel((x, y))
                rgb332 = rgb_to_rgb332(r, g, b)
                f.write(f"{addr} : {rgb332:02X};\n")
                addr += 1

        f.write("END;\n")

# Kodun bulunduğu klasörü bul
script_dir = os.path.dirname(os.path.abspath(__file__))

# Klasördeki tüm png dosyalarını bul ve dönüştür
for filename in os.listdir(script_dir):
    if filename.lower().endswith('.png'):
        image_path = os.path.join(script_dir, filename)
        mif_name = os.path.splitext(filename)[0] + '.mif'
        mif_path = os.path.join(script_dir, mif_name)
        image_to_mif(image_path, mif_path)

"""Uygulama ikonunu (portföy halkası) üretir.

Çalıştırma:  python tool/generate_icon.py
Ardından:    dart run flutter_launcher_icons
             dart run flutter_native_splash:create

Çıktılar assets/icon/ altına yazılır:
  icon.svg              – düzenlenebilir kaynak (tam ikon)
  icon.png              – iOS / web / masaüstü / eski Android (1024px, opak)
  icon_foreground.png   – Android adaptive ön plan (şeffaf, güvenli alanda)
  icon_monochrome.png   – Android 13+ temalı ikon (tek renk)
  splash.png            – açılış ekranı logosu (şeffaf)
  branding.png          – açılış ekranının altındaki slogan (şeffaf)
"""

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

SIZE = 1024
SS = 4  # süper örnekleme (kenar yumuşatma)
ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "icon"
FONT = ROOT / "assets" / "fonts" / "Inter-Medium.ttf"

SLOGAN = "Tüm varlıkların, tek rakam."
SLOGAN_COLOR = "#94949A"  # koyu temadaki ikincil metin rengi

BACKGROUND = "#111113"

# lib/core/theme.dart içindeki varlık renkleri; oranlar örnek bir portföy dağılımı.
SEGMENTS = [
    ("#D9A21B", 0.36),  # altın
    ("#3E7BFA", 0.26),  # döviz
    ("#8B5CF6", 0.20),  # kripto
    ("#14B8A6", 0.18),  # nakit
]

THICKNESS_RATIO = 0.18  # halka kalınlığı / çap
GAP_RATIO = 0.028  # dilim boşluğu / çap (sabit genişlikte)


def _arcs():
    """Her dilim için (renk, başlangıç°, bitiş°) döndürür; 0° = saat 12 yönü."""
    angle = 0.0
    for color, share in SEGMENTS:
        yield color, angle, angle + 360 * share
        angle += 360 * share


def _polar(cx, cy, r, deg):
    rad = math.radians(deg - 90)
    return cx + r * math.cos(rad), cy + r * math.sin(rad)


def render_png(outer_diameter, background=None, mono=None):
    s = SIZE * SS
    img = Image.new("RGBA", (s, s), background or (0, 0, 0, 0))
    ring = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    draw = ImageDraw.Draw(ring)

    c = s / 2
    ro = outer_diameter * SS / 2
    ri = ro * (1 - 2 * THICKNESS_RATIO)
    box = (c - ro, c - ro, c + ro, c + ro)
    for color, a0, a1 in _arcs():
        # PIL'de 0° = saat 3 yönü, açı saat yönünde artar.
        draw.pieslice(box, a0 - 90, a1 - 90, fill=mono or color)
    draw.ellipse((c - ri, c - ri, c + ri, c + ri), fill=(0, 0, 0, 0))
    gap = round(GAP_RATIO * outer_diameter * SS)
    for _, a0, _ in _arcs():
        draw.line([(c, c), _polar(c, c, ro + gap, a0)], fill=(0, 0, 0, 0), width=gap)

    img.alpha_composite(ring)
    return img.resize((SIZE, SIZE), Image.LANCZOS)


def render_branding():
    """Açılış ekranının altındaki slogan. Android 12 marka alanı 200×80 dp'dir;
    görsel xxxhdpi (4x) sayıldığından 800×320 px çizilir."""
    w, h = 800, 320
    img = Image.new("RGBA", (w * SS, h * SS), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    font = ImageFont.truetype(str(FONT), 54 * SS)  # ≈ 13.5 dp
    left, top, right, bottom = draw.textbbox((0, 0), SLOGAN, font=font)
    x = (w * SS - (right - left)) / 2 - left
    y = (h * SS - (bottom - top)) / 2 - top
    draw.text((x, y), SLOGAN, font=font, fill=SLOGAN_COLOR)
    return img.resize((w, h), Image.LANCZOS)


def render_svg(outer_diameter):
    c = SIZE / 2
    r = outer_diameter / 2 * (1 - THICKNESS_RATIO)
    width = outer_diameter * THICKNESS_RATIO

    gap = GAP_RATIO * outer_diameter

    def point(deg, radius=r):
        x, y = _polar(c, c, radius, deg)
        return f"{x:.2f} {y:.2f}"

    paths, cuts = [], []
    for color, a0, a1 in _arcs():
        large = 1 if a1 - a0 > 180 else 0
        paths.append(
            f'    <path d="M {point(a0)} A {r:.2f} {r:.2f} 0 {large} 1 {point(a1)}" '
            f'stroke="{color}" stroke-width="{width:.2f}" fill="none"/>'
        )
        x, y = _polar(c, c, outer_diameter, a0)
        cuts.append(
            f'      <line x1="{c}" y1="{c}" x2="{x:.2f}" y2="{y:.2f}" '
            f'stroke="black" stroke-width="{gap:.2f}"/>'
        )
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {SIZE} {SIZE}">\n'
        "  <defs>\n"
        '    <mask id="gaps">\n'
        f'      <rect width="{SIZE}" height="{SIZE}" fill="white"/>\n'
        + "\n".join(cuts)
        + "\n    </mask>\n  </defs>\n"
        f'  <rect width="{SIZE}" height="{SIZE}" fill="{BACKGROUND}"/>\n'
        '  <g mask="url(#gaps)">\n'
        + "\n".join(paths)
        + "\n  </g>\n</svg>\n"
    )


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    full = SIZE * 0.62  # tam ikonda halka çapı
    # flutter_launcher_icons ön plana %16 inset ekler; 0.74 × 0.68 ≈ 0.50 olur,
    # bu da 108dp tuvaldeki 66dp güvenli alanın rahatça içinde kalır.
    adaptive = SIZE * 0.74

    (OUT / "icon.svg").write_text(render_svg(full), encoding="utf-8")
    render_png(full, background=BACKGROUND).convert("RGB").save(OUT / "icon.png")
    render_png(adaptive).save(OUT / "icon_foreground.png")
    render_png(adaptive, mono="#FFFFFF").save(OUT / "icon_monochrome.png")
    # Açılış ekranı: Android 12+ simgeyi 2/3 çaplı daireye kırptığı için halka
    # tuvalin yarısında tutulur.
    render_png(SIZE * 0.5).save(OUT / "splash.png")
    render_branding().save(OUT / "branding.png")
    print(f"İkonlar yazıldı: {OUT}")


if __name__ == "__main__":
    main()

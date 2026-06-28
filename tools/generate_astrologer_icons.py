#!/usr/bin/env python3
"""生成占星师遗物和消耗品的 SVG 像素图标"""

import json
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
ARTIFACTS_DIR = PROJECT_ROOT / "external" / "sprites" / "artifacts"
CONSUMABLES_DIR = PROJECT_ROOT / "external" / "sprites" / "consumables"
DATA_ARTIFACTS = PROJECT_ROOT / "external" / "data" / "artifacts"
DATA_CONSUMABLES = PROJECT_ROOT / "external" / "data" / "consumables"

# 主题色
BLUE = "#4169e1"
DARK_BLUE = "#1a1a3e"
GOLD = "#ffd700"
DARK_GOLD = "#b8860b"
PURPLE = "#9370db"
DARK_PURPLE = "#4a2d7a"
TEAL = "#40e0d0"
RED = "#e74c3c"
WHITE = "#ffffff"
GRAY = "#888888"
DARK_GRAY = "#444444"
BLACK = "#000000"
ORANGE = "#ff8c00"


def svg_header(w=96, h=96):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">'


def svg_footer():
    return '</svg>'


# ========== 遗物 SVG 生成 ==========

def artifact_brass_astrolabe():
    """黄铜星盘 - 圆形星盘带刻度"""
    return f"""{svg_header()}
  <circle cx="48" cy="48" r="38" fill="{DARK_GOLD}"/>
  <circle cx="48" cy="48" r="34" fill="{GOLD}"/>
  <circle cx="48" cy="48" r="28" fill="{DARK_GOLD}" fill-opacity="0.3"/>
  <circle cx="48" cy="48" r="3" fill="{WHITE}"/>
  <line x1="48" y1="14" x2="48" y2="82" stroke="{DARK_GOLD}" stroke-width="2"/>
  <line x1="14" y1="48" x2="82" y2="48" stroke="{DARK_GOLD}" stroke-width="2"/>
  <line x1="24" y1="24" x2="72" y2="72" stroke="{DARK_GOLD}" stroke-width="1"/>
  <line x1="72" y1="24" x2="24" y2="72" stroke="{DARK_GOLD}" stroke-width="1"/>
  <circle cx="48" cy="14" r="2" fill="{WHITE}"/>
  <circle cx="82" cy="48" r="2" fill="{WHITE}"/>
  <circle cx="48" cy="82" r="2" fill="{WHITE}"/>
  <circle cx="14" cy="48" r="2" fill="{WHITE}"/>
  <circle cx="48" cy="48" r="18" fill="none" stroke="{WHITE}" stroke-width="1" stroke-dasharray="4,4"/>
{svg_footer()}"""


def artifact_comet_shard():
    """彗星碎片 - 三角形碎片带尾巴"""
    return f"""{svg_header()}
  <path d="M60 20L75 70L45 80Z" fill="{TEAL}" opacity="0.8"/>
  <path d="M60 20L75 70L45 80Z" fill="none" stroke="{WHITE}" stroke-width="1"/>
  <path d="M60 20L30 60" stroke="{TEAL}" stroke-width="3" opacity="0.5"/>
  <path d="M60 20L25 50" stroke="{TEAL}" stroke-width="2" opacity="0.3"/>
  <circle cx="60" cy="20" r="4" fill="{WHITE}"/>
  <path d="M55 35l5-5 5 5-5 5z" fill="{WHITE}" opacity="0.6"/>
{svg_footer()}"""


def artifact_constellation_globe():
    """星座仪 - 圆球带星座连线"""
    return f"""{svg_header()}
  <circle cx="48" cy="48" r="36" fill="{DARK_BLUE}"/>
  <circle cx="48" cy="48" r="36" fill="none" stroke="{BLUE}" stroke-width="2"/>
  <ellipse cx="48" cy="48" rx="36" ry="16" fill="none" stroke="{BLUE}" stroke-width="1" opacity="0.5"/>
  <ellipse cx="48" cy="48" rx="16" ry="36" fill="none" stroke="{BLUE}" stroke-width="1" opacity="0.5"/>
  <circle cx="30" cy="30" r="2" fill="{GOLD}"/>
  <circle cx="65" cy="35" r="2" fill="{GOLD}"/>
  <circle cx="40" cy="60" r="2" fill="{GOLD}"/>
  <circle cx="55" cy="55" r="2" fill="{GOLD}"/>
  <circle cx="48" cy="25" r="2" fill="{GOLD}"/>
  <line x1="30" y1="30" x2="48" y2="25" stroke="{GOLD}" stroke-width="1"/>
  <line x1="48" y1="25" x2="65" y2="35" stroke="{GOLD}" stroke-width="1"/>
  <line x1="40" y1="60" x2="55" y2="55" stroke="{GOLD}" stroke-width="1"/>
  <line x1="55" y1="55" x2="65" y2="35" stroke="{GOLD}" stroke-width="1"/>
  <rect x="44" y="84" width="8" height="6" fill="{GOLD}"/>
{svg_footer()}"""


def artifact_cosmic_clock():
    """宇宙时钟 - 钟面带星辰"""
    return f"""{svg_header()}
  <circle cx="48" cy="48" r="38" fill="{DARK_BLUE}"/>
  <circle cx="48" cy="48" r="35" fill="none" stroke="{PURPLE}" stroke-width="2"/>
  <circle cx="48" cy="48" r="3" fill="{GOLD}"/>
  <line x1="48" y1="48" x2="48" y2="20" stroke="{WHITE}" stroke-width="2"/>
  <line x1="48" y1="48" x2="68" y2="48" stroke="{GOLD}" stroke-width="1.5"/>
  <circle cx="48" cy="15" r="2" fill="{GOLD}"/>
  <circle cx="81" cy="48" r="2" fill="{GOLD}"/>
  <circle cx="48" cy="81" r="2" fill="{GOLD}"/>
  <circle cx="15" cy="48" r="2" fill="{GOLD}"/>
  <circle cx="70" cy="26" r="1.5" fill="{PURPLE}"/>
  <circle cx="70" cy="70" r="1.5" fill="{PURPLE}"/>
  <circle cx="26" cy="70" r="1.5" fill="{PURPLE}"/>
  <circle cx="26" cy="26" r="1.5" fill="{PURPLE}"/>
{svg_footer()}"""


def artifact_dark_star():
    """暗星 - 黑色星形带紫色光晕"""
    return f"""{svg_header()}
  <circle cx="48" cy="48" r="35" fill="{PURPLE}" opacity="0.2"/>
  <polygon points="48,12 55,36 80,36 60,52 68,78 48,62 28,78 36,52 16,36 41,36" fill="{DARK_BLUE}"/>
  <polygon points="48,20 53,38 72,38 57,50 63,70 48,58 33,70 39,50 24,38 43,38" fill="{BLACK}"/>
  <circle cx="48" cy="48" r="6" fill="{PURPLE}" opacity="0.8"/>
  <circle cx="48" cy="48" r="3" fill="{WHITE}" opacity="0.5"/>
{svg_footer()}"""


def artifact_eclipse_prism():
    """日蚀棱镜 - 三角棱镜分光"""
    return f"""{svg_header()}
  <polygon points="48,10 78,78 18,78" fill="{DARK_GRAY}" stroke="{WHITE}" stroke-width="1"/>
  <polygon points="48,18 72,72 24,72" fill="{GRAY}"/>
  <circle cx="20" cy="40" r="12" fill="{GOLD}" opacity="0.8"/>
  <path d="M32 48 L60 35 L55 50 Z" fill="{WHITE}" opacity="0.3"/>
  <line x1="60" y1="35" x2="80" y2="25" stroke="{RED}" stroke-width="2"/>
  <line x1="60" y1="35" x2="82" y2="35" stroke="{ORANGE}" stroke-width="2"/>
  <line x1="60" y1="35" x2="80" y2="45" stroke="{GOLD}" stroke-width="2"/>
  <line x1="60" y1="35" x2="78" y2="55" stroke="{TEAL}" stroke-width="2"/>
  <line x1="60" y1="35" x2="75" y2="65" stroke="{BLUE}" stroke-width="2"/>
  <line x1="60" y1="35" x2="70" y2="72" stroke="{PURPLE}" stroke-width="2"/>
{svg_footer()}"""


def artifact_heliocentric_model():
    """日心说模型 - 太阳在中心，行星轨道"""
    return f"""{svg_header()}
  <circle cx="48" cy="48" r="8" fill="{GOLD}"/>
  <circle cx="48" cy="48" r="4" fill="{ORANGE}"/>
  <circle cx="48" cy="48" r="18" fill="none" stroke="{GRAY}" stroke-width="1" stroke-dasharray="3,3"/>
  <circle cx="48" cy="48" r="28" fill="none" stroke="{GRAY}" stroke-width="1" stroke-dasharray="3,3"/>
  <circle cx="48" cy="48" r="38" fill="none" stroke="{GRAY}" stroke-width="1" stroke-dasharray="3,3"/>
  <circle cx="66" cy="48" r="3" fill="{BLUE}"/>
  <circle cx="35" cy="25" r="4" fill="{RED}"/>
  <circle cx="18" cy="60" r="5" fill="{ORANGE}"/>
{svg_footer()}"""


def artifact_jupiter_favor():
    """木星恩赐 - 大行星带条纹"""
    return f"""{svg_header()}
  <circle cx="48" cy="48" r="36" fill="{ORANGE}"/>
  <ellipse cx="48" cy="35" rx="34" ry="4" fill="{DARK_GOLD}" opacity="0.5"/>
  <ellipse cx="48" cy="50" rx="32" ry="3" fill="{RED}" opacity="0.4"/>
  <ellipse cx="48" cy="60" rx="30" ry="4" fill="{DARK_GOLD}" opacity="0.4"/>
  <circle cx="55" cy="42" r="6" fill="{RED}" opacity="0.6"/>
  <circle cx="48" cy="48" r="36" fill="none" stroke="{GOLD}" stroke-width="2"/>
  <circle cx="48" cy="14" r="2" fill="{GOLD}"/>
  <circle cx="82" cy="48" r="2" fill="{GOLD}"/>
  <circle cx="48" cy="82" r="2" fill="{GOLD}"/>
  <circle cx="14" cy="48" r="2" fill="{GOLD}"/>
{svg_footer()}"""


def artifact_lens_of_clarity():
    """清澈透镜 - 圆形透镜带光芒"""
    return f"""{svg_header()}
  <circle cx="48" cy="48" r="30" fill="{DARK_BLUE}" opacity="0.3"/>
  <circle cx="48" cy="48" r="28" fill="none" stroke="{TEAL}" stroke-width="3"/>
  <circle cx="48" cy="48" r="22" fill="none" stroke="{TEAL}" stroke-width="1"/>
  <circle cx="48" cy="48" r="12" fill="{TEAL}" opacity="0.2"/>
  <circle cx="48" cy="48" r="4" fill="{WHITE}"/>
  <line x1="48" y1="10" x2="48" y2="18" stroke="{TEAL}" stroke-width="2"/>
  <line x1="48" y1="78" x2="48" y2="86" stroke="{TEAL}" stroke-width="2"/>
  <line x1="10" y1="48" x2="18" y2="48" stroke="{TEAL}" stroke-width="2"/>
  <line x1="78" y1="48" x2="86" y2="48" stroke="{TEAL}" stroke-width="2"/>
  <path d="M48 22l3 6h-6z" fill="{TEAL}" opacity="0.5"/>
{svg_footer()}"""


def artifact_lunar_calendar():
    """农历 - 月亮形状日历"""
    return f"""{svg_header()}
  <circle cx="48" cy="48" r="36" fill="{GOLD}"/>
  <circle cx="60" cy="48" r="30" fill="{DARK_BLUE}"/>
  <circle cx="36" cy="30" r="2" fill="{DARK_BLUE}" opacity="0.5"/>
  <circle cx="30" cy="50" r="1.5" fill="{DARK_BLUE}" opacity="0.5"/>
  <circle cx="40" cy="65" r="1" fill="{DARK_BLUE}" opacity="0.5"/>
  <rect x="28" y="20" width="4" height="4" fill="{WHITE}" opacity="0.3"/>
  <rect x="28" y="28" width="4" height="4" fill="{WHITE}" opacity="0.3"/>
  <rect x="28" y="36" width="4" height="4" fill="{WHITE}" opacity="0.3"/>
  <rect x="28" y="44" width="4" height="4" fill="{WHITE}" opacity="0.3"/>
  <rect x="28" y="52" width="4" height="4" fill="{WHITE}" opacity="0.3"/>
  <rect x="28" y="60" width="4" height="4" fill="{WHITE}" opacity="0.3"/>
{svg_footer()}"""


def artifact_mercury_quill():
    """水星之羽 - 羽毛笔带星辰"""
    return f"""{svg_header()}
  <path d="M70 10 C65 25, 50 40, 25 80 L30 78 C50 42, 63 28, 67 15Z" fill="{TEAL}"/>
  <path d="M70 10 C68 18, 60 30, 25 80" fill="none" stroke="{WHITE}" stroke-width="1"/>
  <path d="M65 20 C60 30, 50 45, 28 75" fill="none" stroke="{DARK_BLUE}" stroke-width="1" opacity="0.5"/>
  <circle cx="25" cy="80" r="3" fill="{GOLD}"/>
  <circle cx="55" cy="25" r="1.5" fill="{GOLD}" opacity="0.7"/>
  <circle cx="45" cy="40" r="1" fill="{GOLD}" opacity="0.5"/>
{svg_footer()}"""


def artifact_nebula_gem():
    """星云宝石 - 六边形宝石"""
    return f"""{svg_header()}
  <polygon points="48,12 72,28 72,68 48,84 24,68 24,28" fill="{PURPLE}"/>
  <polygon points="48,20 66,32 66,64 48,76 30,64 30,32" fill="{DARK_PURPLE}"/>
  <polygon points="48,28 60,36 60,60 48,68 36,60 36,36" fill="{PURPLE}" opacity="0.6"/>
  <circle cx="48" cy="48" r="8" fill="{WHITE}" opacity="0.3"/>
  <circle cx="48" cy="48" r="3" fill="{WHITE}" opacity="0.6"/>
  <circle cx="42" cy="38" r="2" fill="{WHITE}" opacity="0.4"/>
{svg_footer()}"""


def artifact_orrery_of_worlds():
    """天体仪 - 多轨道行星系统"""
    return f"""{svg_header()}
  <circle cx="48" cy="48" r="6" fill="{GOLD}"/>
  <circle cx="48" cy="48" r="16" fill="none" stroke="{BLUE}" stroke-width="1"/>
  <circle cx="48" cy="48" r="26" fill="none" stroke="{PURPLE}" stroke-width="1"/>
  <circle cx="48" cy="48" r="36" fill="none" stroke="{TEAL}" stroke-width="1"/>
  <circle cx="64" cy="48" r="3" fill="{BLUE}"/>
  <circle cx="32" cy="30" r="4" fill="{PURPLE}"/>
  <circle cx="20" cy="60" r="3" fill="{TEAL}"/>
  <rect x="46" y="84" width="4" height="8" fill="{GOLD}"/>
  <rect x="40" y="88" width="16" height="4" rx="2" fill="{GOLD}"/>
{svg_footer()}"""


def artifact_saturn_ring():
    """土星之环 - 土星带光环"""
    return f"""{svg_header()}
  <ellipse cx="48" cy="48" rx="40" ry="12" fill="none" stroke="{GOLD}" stroke-width="4"/>
  <ellipse cx="48" cy="48" rx="40" ry="12" fill="none" stroke="{DARK_GOLD}" stroke-width="2"/>
  <circle cx="48" cy="48" r="22" fill="{GOLD}"/>
  <ellipse cx="48" cy="40" rx="20" ry="3" fill="{DARK_GOLD}" opacity="0.3"/>
  <ellipse cx="48" cy="52" rx="18" ry="2" fill="{DARK_GOLD}" opacity="0.3"/>
  <circle cx="48" cy="48" r="22" fill="none" stroke="{DARK_GOLD}" stroke-width="1"/>
{svg_footer()}"""


def artifact_star_map():
    """星图 - 卷轴地图"""
    return f"""{svg_header()}
  <rect x="16" y="16" width="64" height="64" rx="3" fill="{DARK_BLUE}"/>
  <rect x="18" y="18" width="60" height="60" rx="2" fill="{DARK_BLUE}" stroke="{GOLD}" stroke-width="1"/>
  <circle cx="30" cy="30" r="2" fill="{GOLD}"/>
  <circle cx="55" cy="25" r="2" fill="{GOLD}"/>
  <circle cx="70" cy="40" r="1.5" fill="{GOLD}"/>
  <circle cx="40" cy="50" r="2" fill="{GOLD}"/>
  <circle cx="60" cy="60" r="1.5" fill="{GOLD}"/>
  <circle cx="25" cy="65" r="1.5" fill="{GOLD}"/>
  <line x1="30" y1="30" x2="55" y2="25" stroke="{GOLD}" stroke-width="0.5"/>
  <line x1="55" y1="25" x2="70" y2="40" stroke="{GOLD}" stroke-width="0.5"/>
  <line x1="40" y1="50" x2="60" y2="60" stroke="{GOLD}" stroke-width="0.5"/>
  <rect x="14" y="12" width="68" height="6" rx="3" fill="{GOLD}"/>
  <rect x="14" y="78" width="68" height="6" rx="3" fill="{GOLD}"/>
{svg_footer()}"""


def artifact_telescope_of_fate():
    """命运望远镜 - 望远镜"""
    return f"""{svg_header()}
  <rect x="20" y="55" width="56" height="10" rx="5" fill="{GRAY}" transform="rotate(-30 48 60)"/>
  <rect x="15" y="50" width="20" height="20" rx="3" fill="{DARK_GRAY}" transform="rotate(-30 48 60)"/>
  <circle cx="18" cy="42" r="10" fill="{DARK_BLUE}" stroke="{GOLD}" stroke-width="2"/>
  <circle cx="18" cy="42" r="6" fill="{BLUE}" opacity="0.5"/>
  <circle cx="18" cy="42" r="2" fill="{WHITE}"/>
  <rect x="55" y="70" width="4" height="16" fill="{GRAY}"/>
  <rect x="48" y="84" width="18" height="4" rx="2" fill="{GRAY}"/>
{svg_footer()}"""


def artifact_zodiac_codex():
    """黄道典籍 - 厚书带星座符号"""
    return f"""{svg_header()}
  <rect x="18" y="14" width="50" height="68" rx="3" fill="{DARK_PURPLE}"/>
  <rect x="22" y="18" width="44" height="60" rx="2" fill="{PURPLE}"/>
  <rect x="18" y="14" width="6" height="68" fill="{DARK_PURPLE}"/>
  <text x="48" y="40" text-anchor="middle" fill="{GOLD}" font-size="16" font-family="serif">&#9800;</text>
  <text x="48" y="58" text-anchor="middle" fill="{GOLD}" font-size="16" font-family="serif">&#9801;</text>
  <text x="48" y="74" text-anchor="middle" fill="{GOLD}" font-size="12" font-family="serif">&#9802;</text>
  <rect x="30" y="22" width="28" height="2" fill="{GOLD}" opacity="0.5"/>
{svg_footer()}"""


# ========== 消耗品 SVG 生成 ==========

def consumable_alignment_tincture():
    """对齐药剂 - 药瓶带对齐符号"""
    return f"""{svg_header()}
  <rect x="38" y="10" width="20" height="8" rx="2" fill="{GOLD}"/>
  <path d="M30 26 L38 18 L58 18 L66 26 L66 80 Q66 86 60 86 L36 86 Q30 86 30 80Z" fill="{BLUE}"/>
  <path d="M32 28 L38 20 L58 20 L64 28 L64 78 Q64 84 58 84 L38 84 Q32 84 32 78Z" fill="{TEAL}"/>
  <line x1="36" y1="40" x2="60" y2="40" stroke="{WHITE}" stroke-width="2"/>
  <line x1="48" y1="28" x2="48" y2="52" stroke="{WHITE}" stroke-width="2"/>
  <circle cx="48" cy="40" r="3" fill="{WHITE}" opacity="0.5"/>
  <ellipse cx="48" cy="70" rx="12" ry="8" fill="{WHITE}" opacity="0.2"/>
{svg_footer()}"""


def consumable_cosmic_tonic():
    """宇宙补药 - 星空药瓶"""
    return f"""{svg_header()}
  <rect x="38" y="10" width="20" height="8" rx="2" fill="{GOLD}"/>
  <path d="M32 26 L38 18 L58 18 L64 26 L64 80 Q64 86 58 86 L38 86 Q32 86 32 80Z" fill="{DARK_BLUE}"/>
  <path d="M34 28 L38 20 L58 20 L62 28 L62 78 Q62 84 56 84 L40 84 Q34 84 34 78Z" fill="{BLUE}"/>
  <circle cx="42" cy="40" r="1.5" fill="{WHITE}"/>
  <circle cx="54" cy="35" r="1" fill="{WHITE}"/>
  <circle cx="48" cy="50" r="1.5" fill="{GOLD}"/>
  <circle cx="38" cy="60" r="1" fill="{WHITE}"/>
  <circle cx="56" cy="55" r="1" fill="{GOLD}"/>
  <circle cx="44" cy="70" r="1.5" fill="{WHITE}"/>
  <ellipse cx="48" cy="65" rx="10" ry="12" fill="{PURPLE}" opacity="0.3"/>
{svg_footer()}"""


def consumable_eclipse_in_bottle():
    """瓶中日蚀 - 药瓶内有日蚀"""
    return f"""{svg_header()}
  <rect x="38" y="10" width="20" height="8" rx="2" fill="{GOLD}"/>
  <path d="M32 26 L38 18 L58 18 L64 26 L64 80 Q64 86 58 86 L38 86 Q32 86 32 80Z" fill="{BLACK}"/>
  <path d="M34 28 L38 20 L58 20 L62 28 L62 78 Q62 84 56 84 L40 84 Q34 84 34 78Z" fill="{DARK_BLUE}"/>
  <circle cx="48" cy="55" r="14" fill="{GOLD}"/>
  <circle cx="54" cy="52" r="12" fill="{DARK_BLUE}"/>
  <circle cx="48" cy="55" r="4" fill="{WHITE}" opacity="0.4"/>
  <ellipse cx="48" cy="55" rx="16" ry="4" fill="{GOLD}" opacity="0.2"/>
{svg_footer()}"""


def consumable_nebula_phial():
    """星云药瓶 - 星云色药瓶"""
    return f"""{svg_header()}
  <rect x="38" y="10" width="20" height="8" rx="2" fill="{GOLD}"/>
  <path d="M32 26 L38 18 L58 18 L64 26 L64 80 Q64 86 58 86 L38 86 Q32 86 32 80Z" fill="{DARK_PURPLE}"/>
  <path d="M34 28 L38 20 L58 20 L62 28 L62 78 Q62 84 56 84 L40 84 Q34 84 34 78Z" fill="{PURPLE}"/>
  <ellipse cx="48" cy="50" rx="14" ry="18" fill="{TEAL}" opacity="0.3"/>
  <ellipse cx="44" cy="55" rx="8" ry="10" fill="{BLUE}" opacity="0.3"/>
  <circle cx="42" cy="45" r="2" fill="{WHITE}" opacity="0.5"/>
  <circle cx="54" cy="50" r="1.5" fill="{WHITE}" opacity="0.4"/>
  <circle cx="48" cy="62" r="1" fill="{GOLD}" opacity="0.6"/>
{svg_footer()}"""


def consumable_starlight_elixir():
    """星光仙露 - 发光药瓶"""
    return f"""{svg_header()}
  <rect x="38" y="10" width="20" height="8" rx="2" fill="{GOLD}"/>
  <path d="M32 26 L38 18 L58 18 L64 26 L64 80 Q64 86 58 86 L38 86 Q32 86 32 80Z" fill="{DARK_BLUE}"/>
  <path d="M34 28 L38 20 L58 20 L62 28 L62 78 Q62 84 56 84 L40 84 Q34 84 34 78Z" fill="{BLUE}"/>
  <circle cx="48" cy="55" r="10" fill="{GOLD}" opacity="0.4"/>
  <circle cx="48" cy="55" r="6" fill="{WHITE}" opacity="0.3"/>
  <circle cx="48" cy="55" r="2" fill="{WHITE}" opacity="0.8"/>
  <line x1="48" y1="40" x2="48" y2="36" stroke="{GOLD}" stroke-width="1"/>
  <line x1="48" y1="70" x2="48" y2="74" stroke="{GOLD}" stroke-width="1"/>
  <line x1="36" y1="55" x2="32" y2="55" stroke="{GOLD}" stroke-width="1"/>
  <line x1="60" y1="55" x2="64" y2="55" stroke="{GOLD}" stroke-width="1"/>
{svg_footer()}"""


# ========== 映射表 ==========

ARTIFACT_GENERATORS = {
    "artifact_brass_astrolabe": artifact_brass_astrolabe,
    "artifact_comet_shard": artifact_comet_shard,
    "artifact_constellation_globe": artifact_constellation_globe,
    "artifact_cosmic_clock": artifact_cosmic_clock,
    "artifact_dark_star": artifact_dark_star,
    "artifact_eclipse_prism": artifact_eclipse_prism,
    "artifact_heliocentric_model": artifact_heliocentric_model,
    "artifact_jupiter_favor": artifact_jupiter_favor,
    "artifact_lens_of_clarity": artifact_lens_of_clarity,
    "artifact_lunar_calendar": artifact_lunar_calendar,
    "artifact_mercury_quill": artifact_mercury_quill,
    "artifact_nebula_gem": artifact_nebula_gem,
    "artifact_orrery_of_worlds": artifact_orrery_of_worlds,
    "artifact_saturn_ring": artifact_saturn_ring,
    "artifact_star_map": artifact_star_map,
    "artifact_telescope_of_fate": artifact_telescope_of_fate,
    "artifact_zodiac_codex": artifact_zodiac_codex,
}

CONSUMABLE_GENERATORS = {
    "consumable_alignment_tincture": consumable_alignment_tincture,
    "consumable_cosmic_tonic": consumable_cosmic_tonic,
    "consumable_eclipse_in_bottle": consumable_eclipse_in_bottle,
    "consumable_nebula_phial": consumable_nebula_phial,
    "consumable_starlight_elixir": consumable_starlight_elixir,
}


def update_json_texture_path(json_path: Path, field: str, texture_path: str):
    with open(json_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    data["properties"][field] = texture_path
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent="\t", ensure_ascii=False)


def main():
    ARTIFACTS_DIR.mkdir(parents=True, exist_ok=True)
    CONSUMABLES_DIR.mkdir(parents=True, exist_ok=True)

    print("=" * 60)
    print("Generating Astrologer artifact icons (17)")
    print("=" * 60)

    for artifact_id, gen_func in ARTIFACT_GENERATORS.items():
        svg_path = ARTIFACTS_DIR / f"{artifact_id}.svg"
        svg_content = gen_func()
        svg_path.write_text(svg_content, encoding="utf-8")
        print(f"  Created: {svg_path.name}")

        json_path = DATA_ARTIFACTS / f"{artifact_id}.json"
        if json_path.exists():
            texture_ref = f"external/sprites/artifacts/{artifact_id}.svg"
            update_json_texture_path(json_path, "artifact_texture_path", texture_ref)
            print(f"    Updated JSON: {json_path.name}")

    print()
    print("=" * 60)
    print("Generating Astrologer consumable icons (5)")
    print("=" * 60)

    for consumable_id, gen_func in CONSUMABLE_GENERATORS.items():
        svg_path = CONSUMABLES_DIR / f"{consumable_id}.svg"
        svg_content = gen_func()
        svg_path.write_text(svg_content, encoding="utf-8")
        print(f"  Created: {svg_path.name}")

        json_path = DATA_CONSUMABLES / f"{consumable_id}.json"
        if json_path.exists():
            texture_ref = f"external/sprites/consumables/{consumable_id}.svg"
            update_json_texture_path(json_path, "consumable_texture_path", texture_ref)
            print(f"    Updated JSON: {json_path.name}")

    print()
    print("=" * 60)
    print(f"Done! Generated {len(ARTIFACT_GENERATORS)} artifact + {len(CONSUMABLE_GENERATORS)} consumable icons")
    print("=" * 60)


if __name__ == "__main__":
    main()

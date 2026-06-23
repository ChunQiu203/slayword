# Fonts Directory

将以下免费可商用字体文件放入此目录后，重新启动 Godot 项目即可生效：

## 推荐字体

### 标题字体（二选一）
- **Cinzel** — Google Fonts, OFL License
  - 下载: https://fonts.google.com/specimen/Cinzel
  - 需要文件: `Cinzel-Bold.ttf`, `Cinzel-Regular.ttf`

- **Cormorant Garamond** — Google Fonts, OFL License  
  - 下载: https://fonts.google.com/specimen/Cormorant+Garamond
  - 需要文件: `CormorantGaramond-Bold.ttf`, `CormorantGaramond-Regular.ttf`

### 正文字体（支持中英文）
- **Noto Sans SC** — Google Fonts, OFL License
  - 下载: https://fonts.google.com/specimen/Noto+Sans+SC
  - 需要文件: `NotoSansSC-Regular.ttf`

- **思源黑体 (Source Han Sans)** — Adobe, OFL License
  - 下载: https://github.com/adobe-fonts/source-han-sans
  - 需要文件: `SourceHanSansSC-Regular.otf`

## 配置

字体路径在 `scripts/ui/SlayMobileStyle.gd` 中定义：

```gdscript
const FONT_TITLE_PATH := FONT_DIR + "Cinzel-Bold.ttf"
const FONT_BODY_PATH := FONT_DIR + "NotoSansSC-Regular.ttf"
```

如果使用不同的字体文件，请相应地修改这些路径常量。

## 未安装字体时

项目会自动退回使用系统字体（Georgia + Segoe UI / Microsoft YaHei），不影响开发和调试。

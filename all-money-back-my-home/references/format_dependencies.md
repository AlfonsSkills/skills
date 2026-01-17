# 格式依赖说明

本 skill 支持多种输入格式。以下是各格式所需的依赖工具及安装方法。

## 格式与依赖对照表

| 格式 | 扩展名 | 首选工具 | 备选工具 |
|------|--------|----------|----------|
| PDF | `.pdf` | pdftotext | PyPDF2 |
| Word (新版) | `.docx` | pandoc | python-docx |
| Word (旧版) | `.doc` | antiword | libreoffice |
| HTML | `.html/.htm` | pandoc | w3m / lynx |
| 纯文本 | `.txt/.md` | (无需额外依赖) | - |
| 图片 | `.png/.jpg/.webp` | Agent 视觉能力 | - |

## 安装方法

### macOS (Homebrew)

```bash
# PDF 处理
brew install poppler          # 提供 pdftotext

# Word 和 HTML 处理
brew install pandoc

# 旧版 Word 处理
brew install antiword

# HTML 备选
brew install w3m
```

### Ubuntu/Debian

```bash
# PDF 处理
sudo apt install poppler-utils

# Word 和 HTML 处理
sudo apt install pandoc

# 旧版 Word 处理
sudo apt install antiword

# HTML 备选
sudo apt install w3m
```

### Python 依赖 (可选备选)

```bash
pip install PyPDF2 python-docx
```

## 图片格式说明

图片格式 (`.png`, `.jpg`, `.jpeg`, `.webp`, `.gif`, `.bmp`, `.tiff`) **无需安装额外 OCR 工具**。

本 skill 利用 **AI Agent 的原生视觉能力** 直接分析图片内容：
- Antigravity: 支持 ✅
- Gemini CLI: 支持 ✅
- Claude: 支持 ✅
- Cursor: 支持 ✅

只需将图片路径提供给 Agent，即可自动识别并分析图片中的投研报告内容。

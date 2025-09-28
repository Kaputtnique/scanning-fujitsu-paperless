# 📄 Fujitsu Scanner Script for Paperless

This repository contains a shell script that automates the complete scanning workflow with a Fujitsu scanner:  
- Duplex scanning via **scanimage (sane-utils)**  
- Page rotation and deskewing  
- OCR text recognition using **ocrmypdf** with **Tesseract**  
- Empty page detection and removal  
- Export as searchable PDF into your Paperless consume folder  

---

## ✨ Features
- Automatic duplex scanning (tested with Fujitsu fi-6130DJ)  
- OCR in multiple languages (default: German + English)  
- Automatic rotation and deskew  
- Discards empty pages based on black content ratio  
- Saves results directly to a configured folder (e.g. Paperless-ngx consume dir)  

---

## 🛠️ Requirements

The script relies on the following tools:

- [`sane-utils`](https://packages.debian.org/sane-utils) (provides `scanimage`)  
- [`imagemagick`](https://imagemagick.org) (image processing, empty-page detection)  
- [`ocrmypdf`](https://ocrmypdf.readthedocs.io) (OCR and PDF generation)  
- [`tesseract-ocr-deu`](https://github.com/tesseract-ocr/tesseract) and [`tesseract-ocr-eng`](https://github.com/tesseract-ocr/tesseract) (OCR language packs – replace with your preferred languages)  
- [`poppler-utils`](https://poppler.freedesktop.org) (provides `pdfinfo` and `pdftotext`)  
- [`qpdf`](http://qpdf.sourceforge.net) (page selection and PDF manipulation)  

Install everything on Debian/Ubuntu with:

```bash
sudo apt update && \
sudo apt install sane-utils imagemagick ocrmypdf \
  tesseract-ocr-deu tesseract-ocr-eng \
  poppler-utils qpdf

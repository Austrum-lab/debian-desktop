# EasyEffects Presets

Audio (input and output) presets I use for my ASUS ROG G14 2023

## Presets List

| Preset | Type |Description | Device | External Link |
|--------|---|--------|--------|--------|
| `g14_headphones_voice.json` | Output | Custom preset for 3.5mm headphones | ROG Cetra 2 / Universal |  |
| `EEGuide+Exciter.json` | Output | Bass enhancer + exciter | Universal | https://github.com/cab404/framework-dsp |
| `fifine_am5_usb_mic.json` | Input | Main mic preset | Fifine AM5 (USB) / Universal |  |
| `fifine_mic_old.json` | Input | Old mic preset | Fifine AM5 (USB) / Universal |  |
| `masc_npr_voice.json` | Input | Voice preset | Universal | https://gist.github.com/jtrv/47542c8be6345951802eebcf9dc7da31 |

### g14_headphones_voice.json Signal Chain

```
Filter (90Hz Low-shelf +1.5dB)
    ↓
Filter (250Hz Bell -2dB)
    ↓
Filter (1500Hz Bell +2.5dB)
    ↓
Filter (3500Hz Bell +2dB)
    ↓
Bass Enhancer (amount: 3.0, floor: 10Hz)
    ↓
Exciter (amount: 1.0, ceil: 15kHz)
    ↓
Multiband Compressor (4 bands active)
    ↓
Multiband Compressor #2 (bypassed)
    ↓
Stereo Tools (stereo-base: 0.45)
    ↓
Limiter (threshold: -1dB, gain-boost: enabled, input-gain: 0dB, output-gain: 0dB)
```


### fifine_am5_usb_mic.json Signal Chain

```
Filter (High-pass 100Hz, 24dB/oct)
    ↓
Gate (threshold: -48dB, reduction: -24dB)
    ↓
Deesser (threshold: -22dB, f1: 5.5kHz, f2: 6.5kHz)
    ↓
Compressor (threshold: -18dB, ratio: 2.8, makeup: 3dB)
    ↓
Multiband Compressor (bypassed)
    ↓
RNNoise (VAD enabled, threshold: 70)
    ↓
Limiter (threshold: -2dB)
```

---

## Installation

### Flatpak

```bash
mkdir -p ~/.var/app/com.github.wwmm.easyeffects/data/easyeffects/output/
mkdir -p ~/.var/app/com.github.wwmm.easyeffects/data/easyeffects/input/

cp output/*.json ~/.var/app/com.github.wwmm.easyeffects/data/easyeffects/output/
cp input/*.json ~/.var/app/com.github.wwmm.easyeffects/data/easyeffects/input/
```

### System Package

```bash
mkdir -p ~/.config/easyeffects/output/
mkdir -p ~/.config/easyeffects/input/

cp output/*.json ~/.config/easyeffects/output/
cp input/*.json ~/.config/easyeffects/input/
```

### Import via GUI

1. Open EasyEffects
2. Go to Presets menu
3. Click "Import"
4. Select the JSON file

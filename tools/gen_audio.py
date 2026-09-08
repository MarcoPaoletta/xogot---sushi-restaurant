#!/usr/bin/env python3
"""Synthesises every SFX and music loop for Sushi as 16-bit mono WAV files (no external samples).

Usage: python3 tools/gen_audio.py <output_dir>   (writes sfx/*.wav and music/*.wav)
"""
import math, os, random, struct, sys, wave

SR = 44100
random.seed(11)


def write(path, samples):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    peak = max(1e-6, max(abs(s) for s in samples))
    scale = 0.92 / peak if peak > 0.92 else 1.0
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s * scale)) * 32767)) for s in samples))


def env(t, a, d, s_level, r, total):
    if t < a:
        return t / a
    if t < a + d:
        return 1.0 - (1.0 - s_level) * (t - a) / d
    if t < total - r:
        return s_level
    return max(0.0, s_level * (total - t) / r)


def tone(freq, dur, wave_fn=math.sin, a=0.005, d=0.05, s=0.6, r=0.08, vol=1.0, slide=0.0, vib=0.0):
    n = int(SR * dur)
    out = []
    ph = 0.0
    for i in range(n):
        t = i / SR
        f = freq * (2.0 ** (slide * t / max(dur, 1e-6)))
        if vib:
            f *= 1.0 + 0.01 * vib * math.sin(t * 40.0)
        ph += 2 * math.pi * f / SR
        out.append(wave_fn(ph) * env(t, a, d, s, r, dur) * vol)
    return out


def square(ph):
    return 0.6 if math.sin(ph) > 0 else -0.6


def tri(ph):
    return 2.0 / math.pi * math.asin(math.sin(ph))


def pluck(freq, dur, vol=1.0):
    """Karplus-Strong string: koto / shamisen-like pluck."""
    n = int(SR * dur)
    period = max(2, int(SR / freq))
    buf = [random.uniform(-1, 1) for _ in range(period)]
    out = []
    for i in range(n):
        v = buf[i % period]
        nxt = buf[(i + 1) % period]
        buf[i % period] = 0.5 * (v + nxt) * 0.996
        out.append(v * vol * min(1.0, (n - i) / (SR * 0.05)))
    return out


def noise(dur, a=0.001, d=0.05, s=0.3, r=0.1, vol=1.0, lp=0.3):
    n = int(SR * dur)
    out, y = [], 0.0
    for i in range(n):
        t = i / SR
        y += lp * (random.uniform(-1, 1) - y)
        out.append(y * env(t, a, d, s, r, dur) * vol)
    return out


def mix(*parts):
    n = max(len(p) for p in parts)
    out = [0.0] * n
    for p in parts:
        for i, v in enumerate(p):
            out[i] += v
    return out


def seq(*parts):
    out = []
    for p in parts:
        out.extend(p)
    return out


def delay(samples, offset):
    return [0.0] * int(SR * offset) + samples


def sfx(out):
    S = os.path.join(out, "sfx")
    write(S + "/tap.wav", mix(noise(0.05, s=0.2, r=0.03, vol=0.6, lp=0.5), tone(520, 0.07, tri, s=0.3, vol=0.5, slide=-0.4)))
    write(S + "/complete.wav", seq(tone(880, 0.09, tri, vol=0.5), tone(1320, 0.28, tri, s=0.55, r=0.2, vol=0.6)))
    write(S + "/buzz.wav", tone(110, 0.3, square, s=0.5, r=0.15, vol=0.4, vib=2.0))
    write(S + "/no.wav", seq(tone(240, 0.09, square, vol=0.4), tone(190, 0.18, square, s=0.4, vol=0.4)))
    write(S + "/whoosh.wav", noise(0.3, a=0.03, d=0.1, s=0.5, r=0.15, vol=0.5, lp=0.08))
    write(S + "/coin.wav", mix(tone(1046, 0.09, square, s=0.4, r=0.05, vol=0.45), delay(tone(1568, 0.2, tri, s=0.5, r=0.12, vol=0.6), 0.06)))
    write(S + "/splash.wav", mix(noise(0.35, d=0.1, s=0.3, r=0.2, vol=0.6, lp=0.25), tone(300, 0.15, math.sin, s=0.3, vol=0.3, slide=-1.0)))
    write(S + "/bell.wav", mix(tone(1760, 0.6, math.sin, a=0.002, d=0.2, s=0.3, r=0.3, vol=0.4), tone(2637, 0.4, math.sin, a=0.002, d=0.15, s=0.2, r=0.2, vol=0.2)))
    write(S + "/tick.wav", tone(1500, 0.03, square, s=0.3, r=0.01, vol=0.3))
    write(S + "/angry.wav", seq(tone(392, 0.16, square, s=0.6, vol=0.45), tone(330, 0.16, square, s=0.6, vol=0.45), tone(262, 0.4, square, s=0.5, r=0.25, vol=0.45, slide=-0.4)))
    write(S + "/strike.wav", mix(noise(0.25, d=0.06, s=0.3, r=0.15, vol=0.6, lp=0.2), tone(90, 0.3, math.sin, s=0.4, r=0.2, vol=0.7, slide=-0.8)))
    write(S + "/wave.wav", seq(tone(659, 0.12, tri, vol=0.5), tone(880, 0.12, tri, vol=0.5), tone(1175, 0.3, tri, s=0.5, r=0.2, vol=0.55)))
    write(S + "/fanfare.wav", seq(tone(523, 0.14, tri, vol=0.5), tone(659, 0.14, tri, vol=0.5), tone(784, 0.14, tri, vol=0.5), tone(1046, 0.5, tri, s=0.6, r=0.35, vol=0.6, vib=1.0)))
    write(S + "/closed.wav", seq(tone(440, 0.25, tri, s=0.6, vol=0.5), tone(370, 0.25, tri, s=0.6, vol=0.5), tone(294, 0.6, tri, s=0.5, r=0.4, vol=0.5)))
    write(S + "/ui.wav", mix(tone(880, 0.05, square, s=0.3, vol=0.3), delay(tone(1320, 0.08, tri, s=0.3, vol=0.3), 0.03)))
    write(S + "/pop.wav", tone(600, 0.08, math.sin, s=0.4, r=0.04, vol=0.5, slide=0.8))
    write(S + "/star.wav", seq(tone(784, 0.1, tri, vol=0.5), tone(988, 0.1, tri, vol=0.5), tone(1319, 0.3, tri, s=0.5, r=0.2, vol=0.6)))
    write(S + "/streak.wav", seq(tone(1046, 0.06, square, vol=0.35), tone(1319, 0.06, square, vol=0.35), tone(1568, 0.16, tri, s=0.5, vol=0.5)))


NOTE = {n: i for i, n in enumerate(["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"])}


def hz(name):
    octave = int(name[-1])
    semi = NOTE[name[:-1]]
    return 440.0 * 2 ** ((semi - 9) / 12 + (octave - 4))


def render(bpm, bars, tracks):
    beat = 60.0 / bpm
    total = bars * 4 * beat
    n = int(SR * total)
    out = [0.0] * n
    for kind, vol, notes, decay, s_level in tracks:
        t0 = 0.0
        for name, length in notes:
            dur = length * beat
            if name:
                start = int(SR * t0)
                if kind == "pluck":
                    src = pluck(hz(name), min(dur, decay), vol)
                else:
                    ns_dur = min(dur, decay)
                    src = tone(hz(name), ns_dur, kind, a=0.004, d=0.08, s=s_level, r=0.05, vol=vol)
                for i, v in enumerate(src):
                    if start + i < n:
                        out[start + i] += v
            t0 += dur
    return out


def drums(bpm, bars, pattern):
    beat = 60.0 / bpm
    n = int(SR * bars * 4 * beat)
    out = [0.0] * n
    step = beat / 2.0
    kick = tone(120, 0.12, math.sin, s=0.3, r=0.06, vol=0.6, slide=-1.5)
    hat = noise(0.04, s=0.2, r=0.02, vol=0.18, lp=0.8)
    wood = mix(noise(0.03, s=0.2, r=0.02, vol=0.35, lp=0.5), tone(900, 0.04, tri, s=0.3, vol=0.25, slide=-0.5))
    for bar in range(bars):
        for i, ch in enumerate(pattern):
            start = int(SR * (bar * 4 * beat + i * step))
            src = {"k": kick, "h": hat, "w": wood}.get(ch)
            if src:
                for j, v in enumerate(src):
                    if start + j < n:
                        out[start + j] += v
    return out


def music(out):
    M = os.path.join(out, "music")
    # Pentatonic (A minor pentatonic / "in" flavour) koto arpeggios for the menu, 84 bpm, 8 bars.
    scale = ["A3", "C4", "D4", "E4", "G4", "A4", "C5", "D5", "E5"]
    random.seed(3)
    arp = []
    pattern = [0, 2, 4, 5, 7, 5, 4, 2, 1, 3, 5, 6, 8, 6, 5, 3]
    for bar in range(8):
        for i in range(16):
            idx = pattern[i] if bar % 2 == 0 else pattern[(i + 3) % 16]
            arp.append((scale[idx], 0.25))
    pad = []
    for root in ["A2", "F2", "G2", "E2"] * 2:
        pad += [(root, 4)]
    write(M + "/menu.wav", render(84, 8, [("pluck", 0.5, arp, 1.2, 0.6), (math.sin, 0.22, pad, 4.0, 0.7)]))
    # Day loop: upbeat plucked melody with wood-block percussion, 118 bpm, 8 bars.
    lead = [("E5", .5), ("D5", .5), ("C5", 1), ("A4", .5), ("C5", .5), ("D5", 1),
            ("E5", .5), ("G5", .5), ("E5", 1), ("D5", .5), ("C5", .5), ("A4", 1),
            ("C5", .5), ("D5", .5), ("E5", 1), ("G5", .5), ("A5", .5), ("G5", 1),
            ("E5", .5), ("D5", .5), ("C5", .5), ("D5", .5), ("A4", 2),
            ("G4", .5), ("A4", .5), ("C5", 1), ("D5", .5), ("C5", .5), ("A4", 1),
            ("E5", .5), ("D5", .5), ("C5", 1), ("A4", .5), ("G4", .5), ("A4", 1),
            ("C5", .5), ("E5", .5), ("G5", 1), ("A5", .5), ("G5", .5), ("E5", 1),
            ("D5", .5), ("C5", .5), ("D5", .5), ("E5", .5), ("A4", 2)]
    bass = []
    for root, fifth in [("A2", "E3"), ("F2", "C3"), ("C3", "G3"), ("G2", "D3")] * 2:
        bass += [(root, .5), (None, .5), (fifth, .5), (root, .5), (None, .5), (fifth, .5), (root, .5), (fifth, .5)]
    day = mix(render(118, 8, [("pluck", 0.55, lead, 0.8, 0.5), (tri, 0.3, bass, 0.45, 0.6)]), drums(118, 8, "k.w.h.w.k.w.h.ww"))
    write(M + "/day.wav", day)
    # Results sting, 4 s.
    sting = [("A4", .5), ("C5", .5), ("E5", .5), ("A5", 1.5), ("G5", .5), ("A5", 2.5)]
    write(M + "/results.wav", mix(render(120, 3, [("pluck", 0.6, sting, 1.5, 0.6)]), render(120, 3, [(math.sin, 0.25, [("A2", 3), ("E2", 3)], 3.0, 0.7)])))


if __name__ == "__main__":
    out = sys.argv[1]
    sfx(out)
    music(out)
    print("audio written to", out)

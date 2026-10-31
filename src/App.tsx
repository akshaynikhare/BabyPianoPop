/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState, useEffect, useCallback, useRef } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import confetti from 'canvas-confetti';
import { Star, Volume2, VolumeX, Sparkles, Heart, Settings, Lock, Check, X, ShieldCheck, Baby, Volume1, SlidersHorizontal, Hand, MousePointerClick } from 'lucide-react';
import { TextToSpeech } from '@capacitor-community/text-to-speech';
import FloatingBubbles from './components/FloatingBubbles';

// Formats score cleanly so UI never overflows, even with 5+ digits (10,000+)
const formatScore = (num: number): string => {
  if (num < 100000) return `${num}`;
  return `${Math.floor(num / 1000)}k`;
};

const getScoreTextClass = (num: number): string => {
  const str = formatScore(num);
  if (str.length <= 2) return 'text-xl sm:text-2xl';
  if (str.length <= 4) return 'text-base sm:text-lg';
  return 'text-xs sm:text-sm';
};

// --- Educational Content & Phonetics ---

const ALPHABET = [
  'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
  'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'
];

const NUMBERS = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

const SHAPES = ['★', '♥', '●', '▲', '■'] as const;
type ShapeType = typeof SHAPES[number];

const isShapeContent = (val: string): val is ShapeType => {
  return (SHAPES as readonly string[]).includes(val);
};

// Curriculum subsets per age stage
const INFANT_LETTERS = ['A', 'B', 'C'];
const INFANT_NUMBERS = ['1', '2', '3'];

const YOUNG_TODDLER_LETTERS = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'];
const YOUNG_TODDLER_NUMBERS = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

const TODDLER_LETTERS = ALPHABET;
const TODDLER_NUMBERS = NUMBERS;

// --- Age Tiers & Pedagogical Configurations ---

export type AgeTier = '6-12m' | '1-2y' | '2-3y';

interface AgeConfig {
  id: AgeTier;
  stageName: 'Infant' | 'Young Toddler' | 'Toddler';
  title: string;
  ageLabel: string;
  subtitle: string;
  badge: string;
  baseSpeed: number;
  clickBehaviorType: 'touch-enter' | 'tap-only';
  clickBehaviorName: string;
  clickBehaviorDesc: string;
  description: string;
  accentBg: string;
  accentBorder: string;
  accentText: string;
  previewIcons: string[];
}

const AGE_CONFIGS: Record<AgeTier, AgeConfig> = {
  '6-12m': {
    id: '6-12m',
    stageName: 'Infant',
    title: '6 – 12 Months',
    ageLabel: 'Infant',
    subtitle: 'Touch-Enter Glide',
    badge: 'Shapes + A,B,C + 1,2,3',
    baseSpeed: 0.62,
    clickBehaviorType: 'touch-enter',
    clickBehaviorName: 'Touch-Enter / Glide',
    clickBehaviorDesc: 'Sliding, sweeping, or dragging across tiles triggers and pops them on contact with sticky radius.',
    description: 'Designed for infant vision & first motor touches. Features candy shapes, starter letters (A, B, C), and numbers (1, 2, 3) with continuous glide pop.',
    accentBg: 'from-pink-400 via-rose-400 to-pink-500',
    accentBorder: 'border-pink-400',
    accentText: 'text-pink-600',
    previewIcons: ['★', '♥', '●', 'A', '1'],
  },
  '1-2y': {
    id: '1-2y',
    stageName: 'Young Toddler',
    title: '1 – 2 Years',
    ageLabel: 'Young Toddler',
    subtitle: 'Targeted Tap Only',
    badge: 'Shapes + 0–9 + A–J',
    baseSpeed: 0.85,
    clickBehaviorType: 'tap-only',
    clickBehaviorName: 'Click / Tap Only',
    clickBehaviorDesc: 'Requires intentional tap down on the tile. Dragging/sliding over tiles does not trigger them, building fine motor precision.',
    description: 'Counting 0 to 9, first letters A to J, and candy shapes. Trains deliberate targeting and motor precision.',
    accentBg: 'from-amber-400 via-orange-400 to-amber-500',
    accentBorder: 'border-amber-400',
    accentText: 'text-amber-700',
    previewIcons: ['0', '5', '9', 'A', 'J'],
  },
  '2-3y': {
    id: '2-3y',
    stageName: 'Toddler',
    title: '2 – 3+ Years',
    ageLabel: 'Toddler',
    subtitle: 'Precision Tap Only',
    badge: 'Full A–Z, 0–9 & Shapes',
    baseSpeed: 1.05,
    clickBehaviorType: 'tap-only',
    clickBehaviorName: 'Precision Click Only',
    clickBehaviorDesc: 'Discrete precision tap only: full focus on targeting specific letters and numbers with crisp audio feedback.',
    description: 'Full alphabet A to Z, numbers 0 to 9, and shapes for vocabulary recognition and rapid coordination.',
    accentBg: 'from-purple-500 via-fuchsia-500 to-indigo-600',
    accentBorder: 'border-purple-400',
    accentText: 'text-purple-700',
    previewIcons: ['A', 'Z', '9', '★', '♥'],
  },
};

// Dreamy macaron pastel color palettes that cycle every 5 stars
export interface PastelPalette {
  id: string;
  name: string;
  bg: string;
  blob1: string;
  blob2: string;
  starPillBg: string;
}

export const PASTEL_PALETTES: PastelPalette[] = [
  {
    id: 'lavender',
    name: 'Dreamy Lavender',
    bg: 'from-pink-100 via-purple-100 to-indigo-100',
    blob1: 'bg-purple-300/30',
    blob2: 'bg-pink-300/30',
    starPillBg: 'from-purple-500 via-pink-500 to-purple-600',
  },
  {
    id: 'peach',
    name: 'Dreamy Peach',
    bg: 'from-amber-100 via-rose-100 to-orange-100',
    blob1: 'bg-amber-300/30',
    blob2: 'bg-rose-300/30',
    starPillBg: 'from-amber-500 via-orange-400 to-rose-500',
  },
  {
    id: 'mint',
    name: 'Dreamy Mint',
    bg: 'from-emerald-100 via-teal-100 to-sky-100',
    blob1: 'bg-emerald-300/30',
    blob2: 'bg-teal-300/30',
    starPillBg: 'from-emerald-500 via-teal-500 to-cyan-600',
  },
  {
    id: 'rose',
    name: 'Rose Macaron',
    bg: 'from-rose-100 via-pink-100 to-fuchsia-100',
    blob1: 'bg-rose-300/30',
    blob2: 'bg-pink-300/30',
    starPillBg: 'from-rose-500 via-pink-500 to-fuchsia-500',
  },
  {
    id: 'sky',
    name: 'Sky Marshmallow',
    bg: 'from-sky-100 via-blue-100 to-indigo-100',
    blob1: 'bg-sky-300/30',
    blob2: 'bg-blue-300/30',
    starPillBg: 'from-sky-500 via-blue-500 to-indigo-600',
  },
  {
    id: 'lemon',
    name: 'Buttercup Lemon',
    bg: 'from-yellow-100 via-amber-100 to-emerald-100',
    blob1: 'bg-yellow-300/30',
    blob2: 'bg-lime-300/30',
    starPillBg: 'from-amber-500 via-yellow-400 to-lime-500',
  },
];

const AGE_BACKGROUND_GRADIENTS: Record<AgeTier, string> = {
  '6-12m': PASTEL_PALETTES[0].bg,
  '1-2y': PASTEL_PALETTES[1].bg,
  '2-3y': PASTEL_PALETTES[2].bg,
};

// Gentle, warm praise phrases spoken by Jelly Bear every 5 stars in Praise Mode
const PRAISE_PHRASES = [
  "You're doing great!",
  "Super star!",
  "Keep going!",
  "Wonderful job!",
  "You did it!",
  "So smart!",
];

const getContentForTier = (tier: AgeTier): string[] => {
  if (tier === '6-12m') {
    return [...SHAPES, ...INFANT_LETTERS, ...INFANT_NUMBERS];
  }
  if (tier === '1-2y') {
    return [...SHAPES, ...YOUNG_TODDLER_NUMBERS, ...YOUNG_TODDLER_LETTERS];
  }
  return [...SHAPES, ...TODDLER_NUMBERS, ...TODDLER_LETTERS];
};

// Crystal-clear phonetic dictionary so TTS engines never mispronounce single letters or numbers
const PHONETIC_MAP: Record<string, string> = {
  // Letters A to Z (explicit phonetics prevents "A" sounding like the article "uh")
  'A': 'Ay',
  'B': 'Bee',
  'C': 'See',
  'D': 'Dee',
  'E': 'Ee',
  'F': 'Eff',
  'G': 'Jee',
  'H': 'Aitch',
  'I': 'Eye',
  'J': 'Jay',
  'K': 'Kay',
  'L': 'Ell',
  'M': 'Em',
  'N': 'En',
  'O': 'Oh',
  'P': 'Pee',
  'Q': 'Queue',
  'R': 'Are',
  'S': 'Ess',
  'T': 'Tee',
  'U': 'You',
  'V': 'Vee',
  'W': 'Double-you',
  'X': 'Ex',
  'Y': 'Why',
  'Z': 'Zee',

  // Numbers 0 to 9
  '0': 'Zero',
  '1': 'One',
  '2': 'Two',
  '3': 'Three',
  '4': 'Four',
  '5': 'Five',
  '6': 'Six',
  '7': 'Seven',
  '8': 'Eight',
  '9': 'Nine',

  // Shapes
  '★': 'Star',
  '♥': 'Heart',
  '●': 'Circle',
  '▲': 'Triangle',
  '■': 'Square'
};

const CANDY_THEMES = [
  { name: 'strawberry', bg: 'from-rose-500 via-pink-500 to-rose-600', shadow: '#9f1239', glow: 'rgba(244,63,94,0.6)' },
  { name: 'tangerine', bg: 'from-amber-400 via-orange-400 to-orange-500', shadow: '#c2410c', glow: 'rgba(251,146,60,0.6)' },
  { name: 'lemon', bg: 'from-amber-300 via-yellow-400 to-amber-500', shadow: '#b45309', glow: 'rgba(250,204,21,0.6)' },
  { name: 'apple-mint', bg: 'from-emerald-400 via-teal-400 to-emerald-600', shadow: '#047857', glow: 'rgba(52,211,153,0.6)' },
  { name: 'blue-raspberry', bg: 'from-sky-400 via-blue-500 to-indigo-600', shadow: '#1d4ed8', glow: 'rgba(96,165,250,0.6)' },
  { name: 'grape-jelly', bg: 'from-purple-500 via-fuchsia-500 to-purple-700', shadow: '#6b21a8', glow: 'rgba(192,132,252,0.6)' },
];

type MascotMood = 'idle' | 'happy' | 'encourage' | 'celebrate';

interface TileData {
  id: number;
  lane: number;
  candyIndex: number;
  content: string;
  y: number;
  isStuck: boolean;
}

// --- Procedural Soothing Candy Music Box Synth ---

class CandyMusicBox {
  private ctx: AudioContext | null = null;
  private isPlaying = false;
  private isMuted = false;
  private timer: number | null = null;
  private noteIndex = 0;
  private masterGain: GainNode | null = null;

  // Gentle pentatonic lullaby sequence (C5, D5, E5, G5, A5, C6, D6)
  private melody = [
    523.25, 659.25, 783.99, 1046.50,
    880.00, 783.99, 659.25, 523.25,
    587.33, 659.25, 783.99, 880.00,
    783.99, 659.25, 587.33, 523.25,
    659.25, 783.99, 1046.50, 1174.66,
    1046.50, 880.00, 783.99, 659.25,
    587.33, 783.99, 659.25, 523.25
  ];

  init() {
    if (!this.ctx) {
      const AudioCtx = window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
      if (AudioCtx) {
        this.ctx = new AudioCtx();
        this.masterGain = this.ctx.createGain();
        this.masterGain.gain.setValueAtTime(this.isMuted ? 0 : 0.12, this.ctx.currentTime);
        this.masterGain.connect(this.ctx.destination);
      }
    }
    if (this.ctx && this.ctx.state === 'suspended') {
      this.ctx.resume().catch(() => {});
    }
  }

  playChime(freq: number) {
    if (!this.ctx || !this.masterGain || this.isMuted) return;

    try {
      const now = this.ctx.currentTime;
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();
      const oscHarmonic = this.ctx.createOscillator();
      const gainHarmonic = this.ctx.createGain();

      const filter = this.ctx.createBiquadFilter();
      filter.type = 'lowpass';
      filter.frequency.setValueAtTime(2800, now);

      osc.type = 'sine';
      osc.frequency.setValueAtTime(freq, now);

      oscHarmonic.type = 'sine';
      oscHarmonic.frequency.setValueAtTime(freq * 3.01, now);

      gain.gain.setValueAtTime(0, now);
      gain.gain.linearRampToValueAtTime(0.65, now + 0.006);
      gain.gain.exponentialRampToValueAtTime(0.0001, now + 1.3);

      gainHarmonic.gain.setValueAtTime(0, now);
      gainHarmonic.gain.linearRampToValueAtTime(0.14, now + 0.006);
      gainHarmonic.gain.exponentialRampToValueAtTime(0.0001, now + 0.6);

      osc.connect(gain);
      oscHarmonic.connect(gainHarmonic);
      gain.connect(filter);
      gainHarmonic.connect(filter);
      filter.connect(this.masterGain);

      osc.start(now);
      oscHarmonic.start(now);
      osc.stop(now + 1.35);
      oscHarmonic.stop(now + 0.65);
    } catch {}
  }

  playPopChime() {
    if (!this.ctx || !this.masterGain || this.isMuted) return;
    try {
      const now = this.ctx.currentTime;
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();

      osc.type = 'sine';
      osc.frequency.setValueAtTime(523.25, now);
      osc.frequency.exponentialRampToValueAtTime(1046.5, now + 0.08);

      gain.gain.setValueAtTime(0.32, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.14);

      osc.connect(gain);
      gain.connect(this.masterGain);

      osc.start(now);
      osc.stop(now + 0.15);
    } catch {}
  }

  playMascotGiggle() {
    if (!this.ctx || !this.masterGain || this.isMuted) return;
    try {
      const notes = [659.25, 783.99, 1046.50];
      notes.forEach((freq, idx) => {
        if (!this.ctx || !this.masterGain) return;
        const noteTime = this.ctx.currentTime + idx * 0.08;
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();
        osc.type = 'sine';
        osc.frequency.setValueAtTime(freq, noteTime);
        gain.gain.setValueAtTime(0.25, noteTime);
        gain.gain.exponentialRampToValueAtTime(0.001, noteTime + 0.18);
        osc.connect(gain);
        gain.connect(this.masterGain);
        osc.start(noteTime);
        osc.stop(noteTime + 0.19);
      });
    } catch {}
  }

  playStarChime() {
    if (!this.ctx || !this.masterGain || this.isMuted) return;
    try {
      const now = this.ctx.currentTime;
      [1318.51, 1975.53].forEach((freq, idx) => {
        if (!this.ctx || !this.masterGain) return;
        const noteTime = now + idx * 0.06;
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();
        osc.type = 'triangle';
        osc.frequency.setValueAtTime(freq, noteTime);
        gain.gain.setValueAtTime(0.25, noteTime);
        gain.gain.exponentialRampToValueAtTime(0.001, noteTime + 0.32);
        osc.connect(gain);
        gain.connect(this.masterGain);
        osc.start(noteTime);
        osc.stop(noteTime + 0.33);
      });
    } catch {}
  }

  playSettingTick() {
    if (!this.ctx || !this.masterGain || this.isMuted) return;
    try {
      const now = this.ctx.currentTime;
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(880, now);
      osc.frequency.exponentialRampToValueAtTime(1760, now + 0.06);
      gain.gain.setValueAtTime(0.24, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.14);
      osc.connect(gain);
      gain.connect(this.masterGain);
      osc.start(now);
      osc.stop(now + 0.15);
    } catch {}
  }

  start() {
    this.init();
    if (this.isPlaying) return;
    this.isPlaying = true;

    const tick = () => {
      if (!this.isPlaying) return;
      const freq = this.melody[this.noteIndex % this.melody.length];
      this.playChime(freq);
      this.noteIndex++;
      
      const interval = (this.noteIndex % 8 === 0) ? 950 : 520;
      this.timer = window.setTimeout(tick, interval);
    };

    tick();
  }

  stop() {
    this.isPlaying = false;
    if (this.timer) {
      clearTimeout(this.timer);
      this.timer = null;
    }
  }

  setMuted(muted: boolean) {
    this.isMuted = muted;
    if (this.ctx && this.masterGain) {
      this.masterGain.gain.setValueAtTime(muted ? 0 : 0.12, this.ctx.currentTime);
    }
  }
}

const musicBox = new CandyMusicBox();

// --- High-Quality Baby Voice & Speech Engine ---

class BabyTTS {
  private preferredVoice: SpeechSynthesisVoice | null = null;

  constructor() {
    this.initVoices();
  }

  private initVoices() {
    if (typeof window !== 'undefined' && 'speechSynthesis' in window) {
      const update = () => {
        const voices = window.speechSynthesis.getVoices();
        if (voices && voices.length > 0) {
          // Select warm, friendly English voice (Natural, Google US, Samantha, Karen, etc.)
          this.preferredVoice =
            voices.find(v => v.lang.startsWith('en') && (v.name.includes('Natural') || v.name.includes('Google') || v.name.includes('Samantha') || v.name.includes('Karen') || v.name.includes('Victoria'))) ||
            voices.find(v => v.lang === 'en-US') ||
            voices.find(v => v.lang.startsWith('en')) ||
            voices[0] || null;
        }
      };
      update();
      window.speechSynthesis.onvoiceschanged = update;
    }
  }

  unlock() {
    try {
      TextToSpeech.speak({ text: ' ', volume: 0 }).catch(() => {});
    } catch {}
    if (typeof window !== 'undefined' && 'speechSynthesis' in window) {
      try {
        window.speechSynthesis.cancel();
      } catch {}
    }
  }

  async speak(char: string) {
    const textToSpeak = PHONETIC_MAP[char] || char;

    // Use Web Speech API with selected high-clarity voice in browsers
    if (typeof window !== 'undefined' && 'speechSynthesis' in window) {
      try {
        window.speechSynthesis.cancel(); // Cancel any prior voice to avoid queue delays
        const utterance = new SpeechSynthesisUtterance(textToSpeak);
        if (this.preferredVoice) {
          utterance.voice = this.preferredVoice;
        }
        utterance.lang = 'en-US';
        // Warm, natural pitch (1.08) and calm articulation rate (0.86) for infants
        utterance.pitch = 1.08;
        utterance.rate = 0.86;
        utterance.volume = 1.0;
        window.speechSynthesis.speak(utterance);
        return;
      } catch {}
    }

    // Capacitor Native TTS fallback for native mobile apps
    try {
      await TextToSpeech.speak({
        text: textToSpeak,
        lang: 'en-US',
        rate: 0.86,
        pitch: 1.08,
        volume: 1.0,
      });
    } catch (e) {
      console.warn("TTS speak fallback error", e);
    }
  }
}

const tts = new BabyTTS();

// --- Candy Crush Jelly Bear Mascot SVG Component ---

interface JellyBearProps {
  mood: MascotMood;
  size?: number;
  onClick?: () => void;
}

const JellyBearMascot: React.FC<JellyBearProps> = ({ mood, size = 68, onClick }) => {
  const bounceY = mood === 'happy' ? [0, -10, 2, 0] : mood === 'celebrate' ? [0, -14, 0, -10, 0] : [0, -3, 0];
  const scaleEffect = mood === 'happy' ? [1, 1.12, 0.95, 1] : mood === 'celebrate' ? [1, 1.18, 0.92, 1.05] : [1, 1.02, 1];
  const rotateDeg = mood === 'encourage' ? [0, -8, 8, -4, 0] : mood === 'celebrate' ? [0, -12, 12, 0] : [0, 0, 0];
  const duration = mood === 'idle' ? 2.4 : 0.6;

  return (
    <motion.div
      onClick={onClick}
      animate={{
        y: bounceY,
        scale: scaleEffect,
        rotate: rotateDeg,
      }}
      transition={{
        duration,
        repeat: mood === 'idle' ? Infinity : 0,
        ease: 'easeInOut',
      }}
      className="relative cursor-pointer select-none filter drop-shadow-[0_4px_8px_rgba(236,72,153,0.35)]"
      style={{ width: size, height: size }}
      whileTap={{ scale: 0.9 }}
    >
      <svg viewBox="0 0 100 100" className="w-full h-full overflow-visible">
        <defs>
          <linearGradient id="jellyGrad" x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" stopColor="#ff70a6" />
            <stop offset="50%" stopColor="#ff477e" />
            <stop offset="100%" stopColor="#d90429" />
          </linearGradient>

          <linearGradient id="softPinkGrad" x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" stopColor="#ffd6e0" />
            <stop offset="100%" stopColor="#ffb3c1" />
          </linearGradient>

          <linearGradient id="candyGloss" x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" stopColor="#ffffff" stopOpacity="0.8" />
            <stop offset="100%" stopColor="#ffffff" stopOpacity="0.05" />
          </linearGradient>

          <radialGradient id="sparkleAura" cx="50%" cy="50%" r="50%">
            <stop offset="0%" stopColor="#fef08a" stopOpacity="0.9" />
            <stop offset="100%" stopColor="#fef08a" stopOpacity="0" />
          </radialGradient>
        </defs>

        {mood === 'celebrate' && (
          <circle cx="50" cy="52" r="46" fill="url(#sparkleAura)" className="animate-pulse" />
        )}

        {/* Ears */}
        <g>
          <circle cx="28" cy="28" r="14" fill="url(#jellyGrad)" />
          <circle cx="28" cy="28" r="8" fill="url(#softPinkGrad)" />
          <circle cx="72" cy="28" r="14" fill="url(#jellyGrad)" />
          <circle cx="72" cy="28" r="8" fill="url(#softPinkGrad)" />
        </g>

        {/* Jelly Body & Head */}
        <ellipse cx="50" cy="62" rx="34" ry="30" fill="url(#jellyGrad)" />
        <ellipse cx="50" cy="46" rx="33" ry="28" fill="url(#jellyGrad)" />

        {/* Gloss Top */}
        <path
          d="M 28 36 C 36 26, 64 26, 72 36 C 62 31, 38 31, 28 36 Z"
          fill="url(#candyGloss)"
        />

        <ellipse cx="50" cy="64" rx="20" ry="16" fill="url(#softPinkGrad)" opacity="0.65" />
        <circle cx="27" cy="52" r="6" fill="#ff758f" opacity="0.85" />
        <circle cx="73" cy="52" r="6" fill="#ff758f" opacity="0.85" />

        {/* Eyes */}
        {mood === 'happy' || mood === 'celebrate' ? (
          <g stroke="#ffffff" strokeWidth="4" strokeLinecap="round" fill="none">
            <path d="M 32 44 Q 38 38 44 44" />
            <path d="M 56 44 Q 62 38 68 44" />
          </g>
        ) : (
          <g>
            <circle cx="37" cy="43" r="6" fill="#3a0ca3" />
            <circle cx="35" cy="41" r="2.2" fill="#ffffff" />
            <circle cx="39" cy="45" r="1.1" fill="#ffffff" />
            <circle cx="63" cy="43" r="6" fill="#3a0ca3" />
            <circle cx="61" cy="41" r="2.2" fill="#ffffff" />
            <circle cx="65" cy="45" r="1.1" fill="#ffffff" />
          </g>
        )}

        <ellipse cx="50" cy="48" rx="4" ry="3" fill="#5c0029" />
        <path
          d="M 44 52 Q 50 58 56 52"
          stroke="#5c0029"
          strokeWidth="2.5"
          strokeLinecap="round"
          fill="none"
        />

        <circle cx="22" cy="68" r="8" fill="url(#jellyGrad)" />
        <circle cx="78" cy="68" r="8" fill="url(#jellyGrad)" />

        <g transform="translate(68, 14) scale(0.65)">
          <path
            d="M 10 0 L 13 7 L 20 8 L 15 13 L 16 20 L 10 16 L 4 20 L 5 13 L 0 8 L 7 7 Z"
            fill="#fef08a"
            stroke="#eab308"
            strokeWidth="1.5"
          />
        </g>
      </svg>
    </motion.div>
  );
};

// --- Full Shape Button SVG Renderer ---
// When a shape comes, the entire button IS that shape (Star, Heart, Triangle, etc.)

interface ShapeTileButtonProps {
  shape: ShapeType;
  theme: typeof CANDY_THEMES[0];
}

const ShapeTileButton: React.FC<ShapeTileButtonProps> = ({ shape, theme }) => {
  if (shape === '★') {
    // 5-Pointed Rounded 3D Candy Star Button
    return (
      <svg viewBox="0 0 100 100" className="w-full h-full overflow-visible drop-shadow-[0_8px_16px_rgba(0,0,0,0.22)]">
        <defs>
          <linearGradient id={`starGrad-${theme.name}`} x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" stopColor="#fff" stopOpacity="0.45" />
            <stop offset="40%" stopColor="transparent" />
            <stop offset="100%" stopColor={theme.shadow} stopOpacity="0.75" />
          </linearGradient>
        </defs>

        {/* 3D Drop Bevel Base */}
        <path
          d="M 50 10 L 61 36 L 89 38 L 67 56 L 75 84 L 50 69 L 25 84 L 33 56 L 11 38 L 39 36 Z"
          fill={theme.shadow}
          transform="translate(0, 6)"
        />

        {/* Main Star Body */}
        <path
          d="M 50 10 L 61 36 L 89 38 L 67 56 L 75 84 L 50 69 L 25 84 L 33 56 L 11 38 L 39 36 Z"
          fill="currentColor"
          className="text-amber-400"
        />

        {/* Star Shading Overlay */}
        <path
          d="M 50 10 L 61 36 L 89 38 L 67 56 L 75 84 L 50 69 L 25 84 L 33 56 L 11 38 L 39 36 Z"
          fill={`url(#starGrad-${theme.name})`}
        />

        {/* Candy Gloss Highlight Arc */}
        <path
          d="M 50 12 L 58 32 L 78 34 C 66 38, 52 38, 44 32 Z"
          fill="#ffffff"
          opacity="0.75"
        />

        {/* Cheerful Baby Eyes */}
        <circle cx="43" cy="50" r="3.5" fill="#451a03" />
        <circle cx="42" cy="48.5" r="1.2" fill="#ffffff" />
        <circle cx="57" cy="50" r="3.5" fill="#451a03" />
        <circle cx="56" cy="48.5" r="1.2" fill="#ffffff" />

        {/* Sweet Smile & Rosy Cheeks */}
        <circle cx="36" cy="54" r="3" fill="#f43f5e" opacity="0.6" />
        <circle cx="64" cy="54" r="3" fill="#f43f5e" opacity="0.6" />
        <path d="M 46 55 Q 50 60 54 55" stroke="#451a03" strokeWidth="2" strokeLinecap="round" fill="none" />
      </svg>
    );
  }

  if (shape === '♥') {
    // 3D Candy Heart Button
    return (
      <svg viewBox="0 0 100 100" className="w-full h-full overflow-visible drop-shadow-[0_8px_16px_rgba(0,0,0,0.22)]">
        <defs>
          <linearGradient id={`heartGrad-${theme.name}`} x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" stopColor="#fff" stopOpacity="0.45" />
            <stop offset="40%" stopColor="transparent" />
            <stop offset="100%" stopColor={theme.shadow} stopOpacity="0.8" />
          </linearGradient>
        </defs>

        {/* 3D Drop Bevel Base */}
        <path
          d="M 50 86 C 18 64, 8 46, 8 30 C 8 16, 18 8, 33 8 C 41 8, 47 12, 50 17 C 53 12, 59 8, 67 8 C 82 8, 92 16, 92 30 C 92 46, 82 64, 50 86 Z"
          fill={theme.shadow}
          transform="translate(0, 6)"
        />

        {/* Main Heart Body */}
        <path
          d="M 50 86 C 18 64, 8 46, 8 30 C 8 16, 18 8, 33 8 C 41 8, 47 12, 50 17 C 53 12, 59 8, 67 8 C 82 8, 92 16, 92 30 C 92 46, 82 64, 50 86 Z"
          fill="currentColor"
          className="text-rose-500"
        />

        {/* Shading */}
        <path
          d="M 50 86 C 18 64, 8 46, 8 30 C 8 16, 18 8, 33 8 C 41 8, 47 12, 50 17 C 53 12, 59 8, 67 8 C 82 8, 92 16, 92 30 C 92 46, 82 64, 50 86 Z"
          fill={`url(#heartGrad-${theme.name})`}
        />

        {/* Candy Gloss Highlights (Left & Right Lobes) */}
        <ellipse cx="32" cy="22" rx="14" ry="7" transform="rotate(-25 32 22)" fill="#ffffff" opacity="0.75" />
        <ellipse cx="68" cy="22" rx="12" ry="5" transform="rotate(25 68 22)" fill="#ffffff" opacity="0.6" />

        {/* Cheerful Eyes & Smile */}
        <circle cx="41" cy="42" r="3.5" fill="#4c0519" />
        <circle cx="40" cy="40.5" r="1.2" fill="#ffffff" />
        <circle cx="59" cy="42" r="3.5" fill="#4c0519" />
        <circle cx="58" cy="40.5" r="1.2" fill="#ffffff" />
        <circle cx="33" cy="46" r="3" fill="#fda4af" />
        <circle cx="67" cy="46" r="3" fill="#fda4af" />
        <path d="M 45 48 Q 50 54 55 48" stroke="#4c0519" strokeWidth="2.2" strokeLinecap="round" fill="none" />
      </svg>
    );
  }

  if (shape === '▲') {
    // 3D Rounded Candy Triangle Button
    return (
      <svg viewBox="0 0 100 100" className="w-full h-full overflow-visible drop-shadow-[0_8px_16px_rgba(0,0,0,0.22)]">
        <defs>
          <linearGradient id={`triGrad-${theme.name}`} x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" stopColor="#fff" stopOpacity="0.5" />
            <stop offset="35%" stopColor="transparent" />
            <stop offset="100%" stopColor={theme.shadow} stopOpacity="0.8" />
          </linearGradient>
        </defs>

        {/* 3D Drop Base */}
        <path
          d="M 50 12 C 54 12, 57 16, 84 68 C 88 75, 84 84, 76 84 L 24 84 C 16 84, 12 75, 16 68 L 43 12 C 46 8, 48 12, 50 12 Z"
          fill={theme.shadow}
          transform="translate(0, 6)"
        />

        {/* Main Body */}
        <path
          d="M 50 12 C 54 12, 57 16, 84 68 C 88 75, 84 84, 76 84 L 24 84 C 16 84, 12 75, 16 68 L 43 12 C 46 8, 48 12, 50 12 Z"
          fill="currentColor"
          className="text-emerald-500"
        />

        <path
          d="M 50 12 C 54 12, 57 16, 84 68 C 88 75, 84 84, 76 84 L 24 84 C 16 84, 12 75, 16 68 L 43 12 C 46 8, 48 12, 50 12 Z"
          fill={`url(#triGrad-${theme.name})`}
        />

        {/* Gloss Curve */}
        <path
          d="M 48 16 C 50 16, 52 18, 66 46 C 54 44, 42 40, 36 34 Z"
          fill="#ffffff"
          opacity="0.75"
        />

        {/* Face */}
        <circle cx="43" cy="58" r="3.5" fill="#064e3b" />
        <circle cx="42" cy="56.5" r="1.2" fill="#ffffff" />
        <circle cx="57" cy="58" r="3.5" fill="#064e3b" />
        <circle cx="56" cy="56.5" r="1.2" fill="#ffffff" />
        <circle cx="36" cy="62" r="3" fill="#f43f5e" opacity="0.5" />
        <circle cx="64" cy="62" r="3" fill="#f43f5e" opacity="0.5" />
        <path d="M 46 63 Q 50 68 54 63" stroke="#064e3b" strokeWidth="2" strokeLinecap="round" fill="none" />
      </svg>
    );
  }

  // Circle or Square fallback (handled directly via border-radius)
  return null;
};

// --- 3-Second Timed Parental Lock Button ---
// Child-lock mechanism: baby quick taps do not open settings; requires holding for 3 continuous seconds.

interface ParentLockButtonProps {
  ageTier: AgeTier;
  onUnlock: () => void;
}

const SETTING_TAP_PHRASES = ['Click!', 'Beep beep!', 'Twirl!', 'Tick tock!'];

const ParentLockButton: React.FC<ParentLockButtonProps> = ({ ageTier, onUnlock }) => {
  const [isHolding, setIsHolding] = useState(false);
  const [progress, setProgress] = useState(0); // 0 to 100
  const [babyTapWobble, setBabyTapWobble] = useState(0);
  const holdStartRef = useRef<number | null>(null);
  const animFrameRef = useRef<number | null>(null);
  const settingPhraseIndexRef = useRef(0);

  const startHold = useCallback((e: React.SyntheticEvent) => {
    e.stopPropagation();
    holdStartRef.current = performance.now();
    setIsHolding(true);
    setProgress(0);

    const checkHold = (time: number) => {
      if (!holdStartRef.current) return;
      const elapsed = time - holdStartRef.current;
      const pct = Math.min(100, (elapsed / 3000) * 100);
      setProgress(pct);

      if (elapsed >= 3000) {
        holdStartRef.current = null;
        setIsHolding(false);
        setProgress(0);
        if (typeof navigator !== 'undefined' && navigator.vibrate) {
          navigator.vibrate(60);
        }
        confetti({
          particleCount: 22,
          spread: 60,
          origin: { y: 0.12, x: 0.8 },
          colors: ['#a855f7', '#ec4899', '#3b82f6'],
        });
        onUnlock();
      } else {
        animFrameRef.current = requestAnimationFrame(checkHold);
      }
    };

    animFrameRef.current = requestAnimationFrame(checkHold);
  }, [onUnlock]);

  const cancelHold = useCallback((e?: React.SyntheticEvent) => {
    if (e) e.stopPropagation();
    const elapsed = holdStartRef.current ? performance.now() - holdStartRef.current : 0;
    holdStartRef.current = null;
    if (animFrameRef.current) {
      cancelAnimationFrame(animFrameRef.current);
      animFrameRef.current = null;
    }
    setIsHolding(false);
    setProgress(0);

    // Baby tap interaction (< 1200ms quick tap without completing the 3-second parental hold)
    if (elapsed > 40 && elapsed < 1200) {
      setBabyTapWobble(prev => prev + 1);
      musicBox.playSettingTick();
      const phrase = SETTING_TAP_PHRASES[settingPhraseIndexRef.current % SETTING_TAP_PHRASES.length];
      settingPhraseIndexRef.current++;
      tts.speak(phrase);
      confetti({
        particleCount: 12,
        spread: 45,
        origin: { y: 0.12, x: 0.88 },
        colors: ['#c084fc', '#e879f9', '#a855f7', '#38bdf8'],
      });
    }
  }, []);

  useEffect(() => {
    return () => {
      if (animFrameRef.current) cancelAnimationFrame(animFrameRef.current);
    };
  }, []);

  const config = AGE_CONFIGS[ageTier];
  const radius = 20;
  const circumference = 2 * Math.PI * radius; // ~125.66
  const strokeOffset = circumference - (circumference * progress) / 100;

  return (
    <div className="relative flex items-center">
      {/* Button with SVG Circular Fill Arc (loading indicator on gear button) */}
      <motion.button
        type="button"
        aria-label={`Parent settings, current age ${config.title}. Hold for 3 seconds to open.`}
        onPointerDown={startHold}
        onPointerUp={cancelHold}
        onPointerLeave={cancelHold}
        onPointerCancel={cancelHold}
        onTouchStart={startHold}
        onTouchEnd={cancelHold}
        onTouchCancel={cancelHold}
        whileTap={{ scale: 0.92 }}
        className="relative w-11 h-11 rounded-full flex items-center justify-center cursor-pointer select-none touch-none active:scale-95 transition-transform bg-white/85 backdrop-blur-md border-2 border-purple-200 shadow-sm"
      >
        {/* Circular Progress SVG */}
        <svg className="absolute inset-0 w-full h-full -rotate-90 pointer-events-none" viewBox="0 0 46 46">
          <circle
            cx="23"
            cy="23"
            r={radius}
            fill="none"
            stroke="rgba(216, 180, 254, 0.4)"
            strokeWidth="3.5"
          />
          {progress > 0 && (
            <circle
              cx="23"
              cy="23"
              r={radius}
              fill="none"
              stroke="url(#holdGrad)"
              strokeWidth="4"
              strokeDasharray={circumference}
              strokeDashoffset={strokeOffset}
              strokeLinecap="round"
            />
          )}
          <defs>
            <linearGradient id="holdGrad" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" stopColor="#ec4899" />
              <stop offset="100%" stopColor="#8b5cf6" />
            </linearGradient>
          </defs>
        </svg>

        {/* Center Settings Icon - Clean, no text */}
        <motion.div
          key={babyTapWobble}
          animate={babyTapWobble > 0 ? { rotate: [0, 90, -45, 30, 0], scale: [1, 1.25, 0.92, 1] } : {}}
          transition={{ duration: 0.45 }}
          className="relative z-10 flex items-center justify-center pointer-events-none"
        >
          <Settings
            size={20}
            className={`transition-colors duration-300 ${isHolding ? 'text-pink-600 rotate-90 scale-110' : 'text-purple-700'}`}
          />
        </motion.div>

        {/* Child Lock Indicator Badge */}
        <div className="absolute -bottom-1 -right-1 w-4 h-4 rounded-full bg-purple-600 text-white flex items-center justify-center border-2 border-white shadow-xs pointer-events-none">
          <Lock size={8} strokeWidth={3} />
        </div>
      </motion.button>
    </div>
  );
};

// --- Age Stage Slider Component ---
// Minimalist, clean slider for Infant, Young Toddler, and Toddler

interface AgeSliderProps {
  currentTier: AgeTier;
  onChange: (tier: AgeTier) => void;
}

const AGE_TIER_KEYS: AgeTier[] = ['6-12m', '1-2y', '2-3y'];

const AgeSlider: React.FC<AgeSliderProps> = ({ currentTier, onChange }) => {
  const currentIndex = Math.max(0, AGE_TIER_KEYS.indexOf(currentTier));
  const activeConfig = AGE_CONFIGS[currentTier];

  const handleRangeChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const val = parseInt(e.target.value, 10);
    const selected = AGE_TIER_KEYS[val] || '1-2y';
    onChange(selected);
  };

  return (
    <div className="w-full bg-white/95 backdrop-blur-md p-3.5 rounded-3xl border-2 border-purple-200 shadow-sm select-none">
      {/* 3 Labeled Stage Buttons */}
      <div className="grid grid-cols-3 gap-1.5">
        {AGE_TIER_KEYS.map((tierKey) => {
          const cfg = AGE_CONFIGS[tierKey];
          const isSelected = tierKey === currentTier;
          return (
            <button
              key={tierKey}
              type="button"
              onClick={() => onChange(tierKey)}
              className={`flex flex-col items-center justify-center py-2 px-1 rounded-2xl transition-all cursor-pointer ${
                isSelected
                  ? `bg-gradient-to-r ${cfg.accentBg} text-white shadow-md scale-102 font-black`
                  : 'bg-purple-50/70 hover:bg-purple-100/70 text-purple-800 font-bold border border-purple-200/50'
              }`}
            >
              <span className="text-xs sm:text-sm font-black leading-tight">
                {cfg.stageName}
              </span>
              <span className={`text-[10px] mt-0.5 ${isSelected ? 'text-white/90' : 'text-purple-500'}`}>
                {cfg.title}
              </span>
            </button>
          );
        })}
      </div>

      {/* Slider Track Line */}
      <div className="relative pt-3.5 pb-1 px-1">
        <div className="relative h-2 bg-purple-100 rounded-full overflow-hidden border border-purple-200/80">
          <motion.div
            className={`h-full bg-gradient-to-r ${activeConfig.accentBg}`}
            initial={false}
            animate={{ width: `${(currentIndex / 2) * 100}%` }}
            transition={{ type: 'spring', stiffness: 320, damping: 26 }}
          />
        </div>

        {/* 3 Node dots */}
        <div className="absolute top-3.5 inset-x-1 flex justify-between pointer-events-none -translate-y-1">
          {AGE_TIER_KEYS.map((tierKey, idx) => {
            const isCurrent = idx === currentIndex;
            const isPassed = idx <= currentIndex;
            return (
              <div
                key={tierKey}
                className={`w-4 h-4 rounded-full border-2 transition-all flex items-center justify-center ${
                  isCurrent
                    ? 'scale-125 bg-white border-pink-500 shadow-md ring-2 ring-pink-300'
                    : isPassed
                    ? 'bg-purple-600 border-white'
                    : 'bg-white border-purple-300'
                }`}
              />
            );
          })}
        </div>

        <input
          type="range"
          min="0"
          max="2"
          step="1"
          value={currentIndex}
          onChange={handleRangeChange}
          aria-label="Age slider"
          className="absolute top-1.5 inset-x-0 w-full h-8 opacity-0 cursor-pointer z-30 touch-none"
        />
      </div>
    </div>
  );
};

// --- Minimalist Parental Settings Modal ---

interface ParentSettingsModalProps {
  isOpen: boolean;
  onClose: () => void;
  currentAgeTier: AgeTier;
  onSelectTier: (tier: AgeTier) => void;
  isMuted: boolean;
  onToggleMute: () => void;
  praiseMode: boolean;
  onTogglePraiseMode: () => void;
}

const ParentSettingsModal: React.FC<ParentSettingsModalProps> = ({
  isOpen,
  onClose,
  currentAgeTier,
  onSelectTier,
  isMuted,
  onToggleMute,
  praiseMode,
  onTogglePraiseMode,
}) => {
  if (!isOpen) return null;

  return (
    <AnimatePresence>
      <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-purple-950/60 backdrop-blur-md select-none">
        <motion.div
          initial={{ scale: 0.9, opacity: 0, y: 15 }}
          animate={{ scale: 1, opacity: 1, y: 0 }}
          exit={{ scale: 0.9, opacity: 0, y: 15 }}
          className="relative w-full max-w-sm bg-white rounded-3xl border-2 border-purple-200 shadow-2xl p-5 overflow-hidden flex flex-col gap-4"
        >
          {/* Minimal Header */}
          <div className="flex items-center justify-between pb-2 border-b border-purple-100">
            <h3 className="text-lg font-black text-purple-950">Settings</h3>
            <button
              onClick={onClose}
              className="w-8 h-8 rounded-full bg-purple-100 hover:bg-purple-200 text-purple-700 flex items-center justify-center cursor-pointer transition-colors active:scale-95"
            >
              <X size={16} />
            </button>
          </div>

          {/* Age Selection */}
          <div className="space-y-1.5">
            <span className="text-xs font-bold uppercase tracking-wider text-purple-600">
              Age
            </span>
            <AgeSlider currentTier={currentAgeTier} onChange={onSelectTier} />
          </div>

          {/* Sound Setting Row */}
          <div className="space-y-1.5">
            <span className="text-xs font-bold uppercase tracking-wider text-purple-600">
              Sound
            </span>
            <button
              type="button"
              onClick={onToggleMute}
              className={`w-full p-3.5 rounded-2xl border-2 flex items-center justify-between cursor-pointer transition-all active:scale-98 ${
                !isMuted
                  ? 'bg-purple-50/80 border-purple-300 text-purple-950 shadow-xs'
                  : 'bg-gray-50 border-gray-200 text-gray-500'
              }`}
            >
              <div className="flex items-center gap-3">
                <div
                  className={`w-9 h-9 rounded-xl flex items-center justify-center ${
                    !isMuted
                      ? 'bg-purple-600 text-white shadow-xs'
                      : 'bg-gray-200 text-gray-500'
                  }`}
                >
                  {!isMuted ? <Volume2 size={20} /> : <VolumeX size={20} />}
                </div>
                <span className="text-sm font-bold">Music</span>
              </div>
              <span
                className={`text-xs font-black px-3 py-1 rounded-full ${
                  !isMuted
                    ? 'bg-purple-600 text-white'
                    : 'bg-gray-200 text-gray-600'
                }`}
              >
                {!isMuted ? 'ON' : 'OFF'}
              </span>
            </button>
          </div>

          {/* Praise Mode Setting Row */}
          <div className="space-y-1.5">
            <span className="text-xs font-bold uppercase tracking-wider text-purple-600">
              Praise Mode
            </span>
            <button
              type="button"
              onClick={onTogglePraiseMode}
              className={`w-full p-3.5 rounded-2xl border-2 flex items-center justify-between cursor-pointer transition-all active:scale-98 ${
                praiseMode
                  ? 'bg-purple-50/80 border-purple-300 text-purple-950 shadow-xs'
                  : 'bg-gray-50 border-gray-200 text-gray-500'
              }`}
            >
              <div className="flex items-center gap-3">
                <div
                  className={`w-9 h-9 rounded-xl flex items-center justify-center ${
                    praiseMode
                      ? 'bg-gradient-to-br from-pink-500 to-purple-600 text-white shadow-xs'
                      : 'bg-gray-200 text-gray-500'
                  }`}
                >
                  <Sparkles size={18} />
                </div>
                <div className="flex flex-col text-left">
                  <span className="text-sm font-bold">Jelly Bear Cheers</span>
                  <span className="text-[10px] text-purple-500 font-medium">Every 5 stars</span>
                </div>
              </div>
              <span
                className={`text-xs font-black px-3 py-1 rounded-full ${
                  praiseMode
                    ? 'bg-purple-600 text-white'
                    : 'bg-gray-200 text-gray-600'
                }`}
              >
                {praiseMode ? 'ON' : 'OFF'}
              </span>
            </button>
          </div>

          {/* Done Button */}
          <button
            onClick={onClose}
            className="w-full py-3.5 rounded-2xl bg-gradient-to-r from-pink-500 to-purple-600 text-white font-black text-sm shadow-md hover:opacity-95 active:scale-98 transition-all flex items-center justify-center cursor-pointer mt-1"
          >
            Done
          </button>
        </motion.div>
      </div>
    </AnimatePresence>
  );
};

// --- Main App Component ---

export default function App() {
  const [tiles, setTiles] = useState<TileData[]>([]);
  const [starCount, setStarCount] = useState(0); // 3 stars max (0, 1, 2, 3)
  const [completedRounds, setCompletedRounds] = useState(0);
  const resetTimerRef = useRef<number | null>(null);
  const [isStarted, setIsStarted] = useState(false);
  const [isMuted, setIsMuted] = useState(false);
  const [mascotMood, setMascotMood] = useState<MascotMood>('idle');

  // Age Tier State with LocalStorage Persistence
  const [ageTier, setAgeTier] = useState<AgeTier>(() => {
    try {
      const saved = localStorage.getItem('baby_piano_age_tier');
      if (saved === '6-12m' || saved === '1-2y' || saved === '2-3y') return saved;
    } catch {
      // Fallback
    }
    return '1-2y';
  });
  const [isSettingsOpen, setIsSettingsOpen] = useState(false);

  // Praise Mode State with LocalStorage Persistence
  const [praiseMode, setPraiseMode] = useState<boolean>(() => {
    try {
      const saved = localStorage.getItem('baby_piano_praise_mode');
      return saved !== null ? saved === 'true' : true;
    } catch {
      return true;
    }
  });

  const togglePraiseMode = useCallback(() => {
    setPraiseMode(prev => {
      const next = !prev;
      try {
        localStorage.setItem('baby_piano_praise_mode', String(next));
      } catch {}
      return next;
    });
  }, []);

  const praiseIndexRef = useRef(0);

  const gameLoopRef = useRef<number>(0);
  const lastFrameTimeRef = useRef<number>(performance.now());
  const speedRef = useRef<number>(AGE_CONFIGS[ageTier].baseSpeed);
  const tempoMultiplierRef = useRef<number>(1.0);
  const lastTapTimeRef = useRef<number>(0);
  const nextIdRef = useRef<number>(0);
  const gapRef = useRef<number>(240);
  const candyIndexRef = useRef<number>(0);
  const clickedTilesRef = useRef<Set<number>>(new Set());
  const moodTimeoutRef = useRef<number | null>(null);

  // Dynamic Pastel Palette shifting on every 3-star completion
  const tierOffset = ageTier === '6-12m' ? 0 : ageTier === '1-2y' ? 1 : 2;
  const currentPaletteIndex = (completedRounds + tierOffset) % PASTEL_PALETTES.length;
  const currentPalette = PASTEL_PALETTES[currentPaletteIndex];

  const handleSelectAgeTier = useCallback((tier: AgeTier) => {
    setAgeTier(tier);
    try {
      localStorage.setItem('baby_piano_age_tier', tier);
    } catch {
      // ignore
    }
    speedRef.current = AGE_CONFIGS[tier].baseSpeed;
    musicBox.playPopChime();
    tts.speak(AGE_CONFIGS[tier].title);
    setTemporaryMood('happy', 1400);
  }, []);

  const setTemporaryMood = useCallback((mood: MascotMood, durationMs = 1200) => {
    setMascotMood(mood);
    if (moodTimeoutRef.current) clearTimeout(moodTimeoutRef.current);
    moodTimeoutRef.current = window.setTimeout(() => {
      setMascotMood('idle');
    }, durationMs);
  }, []);

  const handleStart = useCallback(() => {
    if (isStarted) return;
    tts.unlock();
    musicBox.start();
    setIsStarted(true);
    setTemporaryMood('happy', 1500);
  }, [isStarted, setTemporaryMood]);

  const toggleMute = useCallback(() => {
    setIsMuted(prev => {
      const next = !prev;
      musicBox.setMuted(next);
      return next;
    });
  }, []);

  const mascotTapIndexRef = useRef(0);
  const MASCOT_PHRASES = [
    'Peekaboo!',
    'Yay! Hello baby!',
    'Giggle giggle!',
    'Wheee!',
    'I see you!',
    'Peekaboo! Big smile!'
  ];

  const handleMascotTap = useCallback(() => {
    musicBox.playMascotGiggle();
    setTemporaryMood('celebrate', 1200);
    const phrase = MASCOT_PHRASES[mascotTapIndexRef.current % MASCOT_PHRASES.length];
    mascotTapIndexRef.current++;
    tts.speak(phrase);
    confetti({
      particleCount: 22,
      spread: 70,
      origin: { y: 0.12, x: 0.18 },
      colors: ['#ff70a6', '#ffd166', '#06d6a0', '#a855f7'],
    });
  }, [setTemporaryMood]);

  const handleCounterTap = useCallback(() => {
    musicBox.playStarChime();
    confetti({
      particleCount: 16,
      spread: 60,
      origin: { y: 0.12, x: 0.5 },
      colors: ['#fbbf24', '#f59e0b', '#fef08a', '#ffffff'],
    });

    if (starCount === 0) {
      tts.speak('Tap candies to earn three stars!');
    } else if (starCount === 1) {
      tts.speak('One star! Get two more!');
    } else if (starCount === 2) {
      tts.speak('Two stars! One more to go!');
    } else {
      tts.speak('Three stars! Super job!');
    }
  }, [starCount]);

  // Audio unlock on early interaction
  useEffect(() => {
    const unlockAudio = () => {
      tts.unlock();
      musicBox.init();
    };
    document.addEventListener('touchstart', unlockAudio, { once: true });
    document.addEventListener('click', unlockAudio, { once: true });
    return () => {
      document.removeEventListener('touchstart', unlockAudio);
      document.removeEventListener('click', unlockAudio);
    };
  }, []);

  // Spawn new tile with content tailored to the selected age tier, dropping from beneath top 100px bar
  const spawnTile = useCallback(() => {
    const lane = Math.floor(Math.random() * 4);
    const candyIndex = candyIndexRef.current % CANDY_THEMES.length;
    candyIndexRef.current++;

    const contentPool = getContentForTier(ageTier);
    const content = contentPool[Math.floor(Math.random() * contentPool.length)];

    return {
      id: nextIdRef.current++,
      lane,
      candyIndex,
      content,
      y: 95, // Drops smoothly right from beneath the 100px top bar
      isStuck: false,
    };
  }, [ageTier]);

  // Frame-rate independent game loop with reinforcement learning adaptive drop speed
  useEffect(() => {
    if (!isStarted) return;

    lastFrameTimeRef.current = performance.now();

    const update = (timestamp: number) => {
      const dt = Math.min(35, timestamp - lastFrameTimeRef.current);
      lastFrameTimeRef.current = timestamp;
      const timeScale = dt / 16.67; // Normalized to 60fps

      // Reinforcement learning pace decay:
      // Gently ease tempo back towards 1.0 baseline when baby pauses or plays slowly
      const timeSinceTap = timestamp - lastTapTimeRef.current;
      if (timeSinceTap > 950 && tempoMultiplierRef.current > 1.0) {
        tempoMultiplierRef.current = Math.max(1.0, tempoMultiplierRef.current - 0.015 * timeScale);
      }

      const effectiveSpeed = speedRef.current * tempoMultiplierRef.current;

      setTiles(prev => {
        const stuckTile = prev.find(t => t.isStuck);
        // Comfortable center view target (well below the top 100px touch guard)
        const centerY = Math.max(160, window.innerHeight * 0.44);

        if (stuckTile) {
          // Silky smooth ease-out rewind deceleration (marshmallow soft landing)
          if (stuckTile.y > centerY) {
            const diff = stuckTile.y - centerY;
            const moveUp = Math.max(0.65, diff * 0.08) * timeScale;
            return prev.map(t => ({ ...t, y: t.y - moveUp }));
          }
          return prev; // Hold gently for baby
        }

        let hitBottom = false;
        const bottomThreshold = window.innerHeight - 110;

        const updated = prev.map(t => {
          if (t.y >= bottomThreshold && !t.isStuck) {
            hitBottom = true;
            setTemporaryMood('encourage', 2000);
            return { ...t, y: bottomThreshold, isStuck: true };
          }
          return { ...t, y: t.y + effectiveSpeed * timeScale };
        });

        // Spawn new tiles with gentle spacing dropping right from beneath top bar
        const highestY = updated.length > 0 ? Math.min(...updated.map(t => t.y)) : 1000;
        if (highestY > gapRef.current && !hitBottom) {
          updated.push(spawnTile());
          gapRef.current = 220 + Math.random() * 80;
        }

        return updated;
      });

      gameLoopRef.current = requestAnimationFrame(update);
    };

    gameLoopRef.current = requestAnimationFrame(update);
    return () => cancelAnimationFrame(gameLoopRef.current);
  }, [isStarted, spawnTile, setTemporaryMood]);

  // Tile Hit / Pop Event
  const handleTileClick = useCallback((id: number, _lane: number, candyIndex: number, content: string, wasStuck: boolean) => {
    if (clickedTilesRef.current.has(id)) return;
    clickedTilesRef.current.add(id);

    // Audio: gentle pop chime + crystal-clear articulate phonetic speech
    musicBox.playPopChime();
    tts.speak(content);

    const theme = CANDY_THEMES[candyIndex % CANDY_THEMES.length];

    // Dynamic Age-Tier Confetti Burst:
    // Infant (6-12m): soft round pastel bubbles/circles, gentle float
    // Young Toddler (1-2y): lively candy mix of circles and stars
    // Toddler (2-3y): high-energy neon stars and celebratory bursts
    if (ageTier === '6-12m') {
      confetti({
        particleCount: 20,
        spread: 55,
        origin: { y: 0.72 },
        gravity: 0.65,
        scalar: 1.15,
        shapes: ['circle'],
        colors: [theme.shadow, '#f472b6', '#38bdf8', '#fbbf24', '#a78bfa', '#ffffff'],
      });
    } else if (ageTier === '1-2y') {
      confetti({
        particleCount: 32,
        spread: 72,
        origin: { y: 0.72 },
        gravity: 0.88,
        scalar: 1.05,
        shapes: ['circle', 'star'],
        colors: [theme.shadow, '#ec4899', '#06d6a0', '#f59e0b', '#8b5cf6', '#ffffff'],
      });
    } else {
      confetti({
        particleCount: 44,
        spread: 85,
        origin: { y: 0.72 },
        gravity: 1.05,
        scalar: 1.0,
        shapes: ['star', 'circle'],
        colors: [theme.shadow, '#d946ef', '#10b981', '#0ea5e9', '#f43f5e', '#eab308', '#ffffff'],
      });
    }

    // Reinforcement learning pace boost:
    // If the baby is playing quickly (under 1.5s between pops), accelerate dropping letters
    const now = performance.now();
    const timeSinceLastTap = now - lastTapTimeRef.current;
    lastTapTimeRef.current = now;
    if (timeSinceLastTap < 1500) {
      tempoMultiplierRef.current = Math.min(2.4, tempoMultiplierRef.current + 0.35);
    }

    if (resetTimerRef.current) {
      clearTimeout(resetTimerRef.current);
      resetTimerRef.current = null;
    }

    setStarCount(prev => {
      // If already at 3 stars, start fresh at 1 for the next 3-star cycle
      const next = prev >= 3 ? 1 : prev + 1;

      // 3-Star Max Milestone reached! Celebrate, shift pastel palette, and reset
      if (next === 3) {
        setCompletedRounds(r => r + 1);
        setTemporaryMood('celebrate', 2400);
        musicBox.playStarChime();
        confetti({
          particleCount: 28,
          spread: 70,
          origin: { y: 0.12, x: 0.5 },
          colors: ['#ff70a6', '#ffd166', '#06d6a0', '#a855f7'],
        });

        if (praiseMode) {
          const phrase = PRAISE_PHRASES[praiseIndexRef.current % PRAISE_PHRASES.length];
          praiseIndexRef.current++;
          window.setTimeout(() => {
            tts.speak(`Three stars! ${phrase}`);
          }, 280);
        } else {
          window.setTimeout(() => {
            tts.speak('Three stars! Hooray!');
          }, 280);
        }

        // Reset back to 0 after celebrating 3 stars
        resetTimerRef.current = window.setTimeout(() => {
          setStarCount(0);
        }, 1800);
      } else {
        setTemporaryMood('happy', 900);
      }

      return next;
    });

    // Gentle adaptive pace reinforcement tailored to active age tier
    const baseSpeed = AGE_CONFIGS[ageTier].baseSpeed;
    if (wasStuck) {
      speedRef.current = Math.max(baseSpeed * 0.7, speedRef.current - 0.25);
    } else {
      speedRef.current = Math.min(baseSpeed * 2.2, speedRef.current + 0.05);
    }

    setTiles(prev => prev.filter(t => t.id !== id));
  }, [ageTier, praiseMode, setTemporaryMood]);

  // Point Check with Top 100px Guard + Sticky Hit Area (+15% radius expansion during motion)
  const checkPoint = useCallback((x: number, y: number, isMoving: boolean) => {
    // 1. Strict top 100px touch guard (protects mascot, score, and mute button from accidental tile hits)
    if (y < 100) return;

    // 2. Age-dependent click behavior:
    // - Infant (6-12m): allows continuous touch-enter glide / swipe (isMoving = true is permitted)
    // - Young Toddler & Toddler: click behavior ONLY (dragging/swiping over tiles does NOT trigger them)
    if (isMoving && ageTier !== '6-12m') {
      return;
    }

    // 3. Direct element hit check
    const element = document.elementFromPoint(x, y);
    const directButton = element ? (element.closest('button[data-tile-id]') as HTMLElement | null) : null;
    if (directButton) {
      const id = parseInt(directButton.getAttribute('data-tile-id') || '0', 10);
      const lane = parseInt(directButton.getAttribute('data-tile-lane') || '0', 10);
      const candyIndex = parseInt(directButton.getAttribute('data-tile-candy') || '0', 10);
      const content = directButton.getAttribute('data-tile-content') || '';
      const isStuck = directButton.getAttribute('data-tile-stuck') === 'true';

      handleTileClick(id, lane, candyIndex, content, isStuck);
      return;
    }

    // 4. Sticky Hit Area Detection with +15% radius expansion when finger is in motion
    // This allows infants to reliably pop tiles even with imprecise fast swipes or near-misses
    const tileButtons = document.querySelectorAll<HTMLElement>('button[data-tile-id]');
    let bestMatch: {
      id: number;
      lane: number;
      candyIndex: number;
      content: string;
      isStuck: boolean;
      distSq: number;
    } | null = null;

    tileButtons.forEach(btn => {
      const id = parseInt(btn.getAttribute('data-tile-id') || '0', 10);
      if (clickedTilesRef.current.has(id)) return;

      const rect = btn.getBoundingClientRect();
      const cx = rect.left + rect.width / 2;
      const cy = rect.top + rect.height / 2;

      // Base half-dimensions + comfortable baby touch padding (16px)
      const baseHalfW = rect.width / 2 + 16;
      const baseHalfH = rect.height / 2 + 16;

      // When the finger is in motion, increase touch detection radius by 15%
      const motionMultiplier = isMoving ? 1.15 : 1.0;
      const effectiveHalfW = baseHalfW * motionMultiplier;
      const effectiveHalfH = baseHalfH * motionMultiplier;

      const dx = x - cx;
      const dy = y - cy;

      if (Math.abs(dx) <= effectiveHalfW && Math.abs(dy) <= effectiveHalfH) {
        const distSq = dx * dx + dy * dy;
        if (!bestMatch || distSq < bestMatch.distSq) {
          bestMatch = {
            id,
            lane: parseInt(btn.getAttribute('data-tile-lane') || '0', 10),
            candyIndex: parseInt(btn.getAttribute('data-tile-candy') || '0', 10),
            content: btn.getAttribute('data-tile-content') || '',
            isStuck: btn.getAttribute('data-tile-stuck') === 'true',
            distSq,
          };
        }
      }
    });

    if (bestMatch) {
      handleTileClick(bestMatch.id, bestMatch.lane, bestMatch.candyIndex, bestMatch.content, bestMatch.isStuck);
    }
  }, [ageTier, handleTileClick]);

  // Multi-Touch & Drag Support (Age-dependent)
  const handleTouchStart = useCallback((e: React.TouchEvent) => {
    for (let i = 0; i < e.touches.length; i++) {
      checkPoint(e.touches[i].clientX, e.touches[i].clientY, false);
    }
  }, [checkPoint]);

  const handleTouchMove = useCallback((e: React.TouchEvent) => {
    // Only Infant mode allows continuous touch-enter glide/drag popping
    if (ageTier !== '6-12m') return;
    for (let i = 0; i < e.touches.length; i++) {
      checkPoint(e.touches[i].clientX, e.touches[i].clientY, true);
    }
  }, [ageTier, checkPoint]);

  const handlePointerDown = useCallback((e: React.PointerEvent) => {
    checkPoint(e.clientX, e.clientY, false);
  }, [checkPoint]);

  const handlePointerMove = useCallback((e: React.PointerEvent) => {
    // Only Infant mode allows continuous touch-enter glide/drag popping
    if (ageTier !== '6-12m') return;
    if (e.buttons > 0 || e.pointerType === 'touch') {
      checkPoint(e.clientX, e.clientY, true);
    }
  }, [ageTier, checkPoint]);

  // --- Clean Minimal Start Screen ---
  if (!isStarted) {
    return (
      <div className={`fixed inset-0 bg-gradient-to-b ${currentPalette.bg} transition-colors duration-1000 ease-in-out flex flex-col items-center justify-center p-6 text-center select-none overflow-hidden touch-none`}>
        {/* Subtle, floating background bubble animation */}
        <FloatingBubbles />

        <div className={`absolute -top-16 -left-16 w-64 h-64 ${currentPalette.blob1} rounded-full blur-3xl pointer-events-none transition-colors duration-1000`} />
        <div className={`absolute -bottom-20 -right-20 w-80 h-80 ${currentPalette.blob2} rounded-full blur-3xl pointer-events-none transition-colors duration-1000`} />
        <div className="absolute top-1/3 left-10 w-24 h-24 bg-yellow-200/50 rounded-full blur-2xl pointer-events-none" />

        {/* Cheerful Mascot */}
        <motion.div
          initial={{ scale: 0.8, y: -20, opacity: 0 }}
          animate={{ scale: 1, y: 0, opacity: 1 }}
          transition={{ duration: 0.5 }}
          className="flex flex-col items-center mb-6 z-10"
        >
          <JellyBearMascot mood="happy" size={120} onClick={handleMascotTap} />
        </motion.div>

        {/* Minimal Age Stage Selector */}
        <div className="z-10 mb-7 flex flex-col items-center max-w-xs w-full">
          <AgeSlider
            currentTier={ageTier}
            onChange={handleSelectAgeTier}
          />
        </div>

        {/* Big Clean Play Button */}
        <motion.button
          whileHover={{ scale: 1.05 }}
          whileTap={{ scale: 0.94 }}
          animate={{ scale: [1, 1.04, 1] }}
          transition={{ duration: 2, repeat: Infinity, ease: 'easeInOut' }}
          onPointerDown={handleStart}
          onTouchStart={handleStart}
          className="relative group bg-gradient-to-b from-rose-400 via-pink-500 to-rose-600 text-white rounded-[2.5rem] px-12 py-5 flex items-center gap-3.5 shadow-[0_12px_28px_rgba(244,63,94,0.4)] border-b-6 border-rose-800 z-10 cursor-pointer"
        >
          <div className="absolute top-1.5 inset-x-4 h-5 bg-gradient-to-b from-white/60 to-transparent rounded-full pointer-events-none" />
          
          <Sparkles size={30} className="text-yellow-200 drop-shadow" />
          <span className="text-2xl sm:text-3xl font-black uppercase tracking-tight drop-shadow-md">
            PLAY
          </span>
          <Heart size={26} className="text-pink-200 fill-pink-300 drop-shadow" />
        </motion.button>
      </div>
    );
  }

  // --- Active Gameplay Screen ---
  return (
    <div
      className={`fixed inset-0 bg-gradient-to-b ${currentPalette.bg} transition-colors duration-1000 ease-in-out flex justify-center overflow-hidden select-none touch-none`}
      onTouchStart={handleTouchStart}
      onTouchMove={handleTouchMove}
      onPointerDown={handlePointerDown}
      onPointerMove={handlePointerMove}
    >
      {/* Subtle, floating background bubble animation */}
      <FloatingBubbles />

      <div className={`absolute top-10 left-[-15%] w-72 h-72 ${currentPalette.blob1} rounded-full blur-3xl pointer-events-none transition-colors duration-1000`} />
      <div className={`absolute bottom-10 right-[-15%] w-80 h-80 ${currentPalette.blob2} rounded-full blur-3xl pointer-events-none transition-colors duration-1000`} />

      {/* Main Game Board */}
      <div className="relative w-full max-w-md h-full bg-white/35 backdrop-blur-[2px] border-x-2 border-white/40 shadow-2xl">
        
        {/* Lanes Background (Waffle / Sugar Guide Lines) */}
        <div className="absolute inset-0 flex pointer-events-none">
          {[0, 1, 2, 3].map(i => (
            <div
              key={i}
              className="flex-1 border-r-2 border-dashed border-white/45 last:border-r-0 relative"
            >
              <div className="absolute top-1/4 left-1/2 -translate-x-1/2 w-1.5 h-1.5 rounded-full bg-white/40" />
              <div className="absolute top-2/4 left-1/2 -translate-x-1/2 w-1.5 h-1.5 rounded-full bg-white/40" />
              <div className="absolute top-3/4 left-1/2 -translate-x-1/2 w-1.5 h-1.5 rounded-full bg-white/40" />
            </div>
          ))}
        </div>

        {/* Falling Tiles (Letters, Numbers, and Full Shape Buttons) */}
        {/* Drops smoothly from beneath the 100px top bar */}
        <div className="absolute inset-0 overflow-hidden" style={{ clipPath: 'inset(100px 0 0 0)' }}>
          {tiles.map(tile => {
            const theme = CANDY_THEMES[tile.candyIndex % CANDY_THEMES.length];
            const isShape = isShapeContent(tile.content);

            // Shape-specific styling overrides
            const isCircle = tile.content === '●';
            const isSquare = tile.content === '■';
            const isSvgShape = tile.content === '★' || tile.content === '♥' || tile.content === '▲';

            return (
              <motion.button
                key={tile.id}
                data-tile-id={tile.id}
                data-tile-lane={tile.lane}
                data-tile-candy={tile.candyIndex}
                data-tile-content={tile.content}
                data-tile-stuck={tile.isStuck}
                initial={{ opacity: 0, scale: 0.85 }}
                animate={{
                  opacity: 1,
                  scale: tile.isStuck ? [1.02, 1.08, 1.02] : 1,
                }}
                transition={{
                  scale: { duration: 1.2, repeat: tile.isStuck ? Infinity : 0, ease: 'easeInOut' }
                }}
                whileTap={{ scale: 0.92 }}
                onPointerDown={() => handleTileClick(tile.id, tile.lane, tile.candyIndex, tile.content, tile.isStuck)}
                onTouchStart={() => handleTileClick(tile.id, tile.lane, tile.candyIndex, tile.content, tile.isStuck)}
                className={`absolute flex flex-col items-center justify-center cursor-pointer touch-none before:absolute before:-inset-5 before:content-[''] ${
                  isSvgShape
                    ? 'aspect-square bg-transparent'
                    : isCircle
                    ? `aspect-square rounded-full bg-gradient-to-b ${theme.bg} border-b-[8px] shadow-[0_10px_20px_rgba(0,0,0,0.18)]`
                    : isSquare
                    ? `aspect-square rounded-3xl bg-gradient-to-b ${theme.bg} border-b-[8px] shadow-[0_10px_20px_rgba(0,0,0,0.18)]`
                    : `aspect-[3/4] rounded-3xl bg-gradient-to-b ${theme.bg} border-b-[8px] shadow-[0_10px_20px_rgba(0,0,0,0.18)]`
                }`}
                style={{
                  width: isShape ? '24%' : '23%',
                  left: `calc(${tile.lane * 25}% + 1%)`,
                  top: tile.y,
                  borderBottomColor: (!isSvgShape) ? theme.shadow : undefined,
                  zIndex: tile.isStuck ? 40 : 10,
                }}
              >
                {/* 1. Full Shape Button (Star, Heart, Triangle) */}
                {isSvgShape && (
                  <div className="w-full h-full p-1 relative flex items-center justify-center">
                    <ShapeTileButton shape={tile.content as ShapeType} theme={theme} />
                  </div>
                )}

                {/* 2. Circle Shape Button */}
                {isCircle && (
                  <div className="relative w-full h-full flex flex-col items-center justify-center">
                    <div className="absolute top-1.5 inset-x-3 h-5 bg-gradient-to-b from-white/75 to-transparent rounded-full pointer-events-none" />
                    {/* Cute smiling face for circle candy */}
                    <div className="flex gap-4 mb-1">
                      <div className="w-2.5 h-2.5 rounded-full bg-white/90 shadow-sm" />
                      <div className="w-2.5 h-2.5 rounded-full bg-white/90 shadow-sm" />
                    </div>
                    <div className="w-5 h-2.5 rounded-b-full bg-white/90 shadow-sm" />
                  </div>
                )}

                {/* 3. Square Shape Button */}
                {isSquare && (
                  <div className="relative w-full h-full flex flex-col items-center justify-center">
                    <div className="absolute top-1.5 inset-x-2.5 h-5 bg-gradient-to-b from-white/75 to-transparent rounded-2xl pointer-events-none" />
                    {/* Cute smiling face for square candy */}
                    <div className="flex gap-4 mb-1">
                      <div className="w-2.5 h-2.5 rounded-full bg-white/90 shadow-sm" />
                      <div className="w-2.5 h-2.5 rounded-full bg-white/90 shadow-sm" />
                    </div>
                    <div className="w-5 h-2.5 rounded-b-full bg-white/90 shadow-sm" />
                  </div>
                )}

                {/* 4. Letter / Number Candy Tile */}
                {!isShape && (
                  <>
                    <div className="absolute top-1.5 inset-x-2 h-5 bg-gradient-to-b from-white/75 via-white/25 to-transparent rounded-t-2xl pointer-events-none" />
                    <span className="text-white text-6xl sm:text-7xl font-black drop-shadow-[0_4px_6px_rgba(0,0,0,0.35)] z-10">
                      {tile.content}
                    </span>
                  </>
                )}

                {/* Smooth Warm Candy Glow / Breathing Reinforcement */}
                <motion.div
                  animate={{
                    opacity: tile.isStuck ? [0.25, 0.75, 0.25] : [0, 0.25, 0],
                  }}
                  transition={{
                    duration: tile.isStuck ? 1.2 : 2.2,
                    repeat: Infinity,
                    ease: 'easeInOut',
                  }}
                  className={`absolute inset-0 pointer-events-none ${
                    isCircle ? 'rounded-full' : isSquare ? 'rounded-3xl' : isSvgShape ? 'rounded-full' : 'rounded-3xl'
                  } ${
                    tile.isStuck
                      ? 'bg-gradient-to-t from-amber-300/40 via-yellow-200/35 to-white/60 shadow-[0_0_28px_8px_rgba(253,224,71,0.65)]'
                      : 'bg-white/20'
                  }`}
                />

                {/* Rotating Sugar Star Badge on Stuck Tile */}
                {tile.isStuck && (
                  <motion.div
                    animate={{ rotate: 360, scale: [1, 1.15, 1] }}
                    transition={{
                      rotate: { duration: 4, repeat: Infinity, ease: 'linear' },
                      scale: { duration: 1.2, repeat: Infinity, ease: 'easeInOut' }
                    }}
                    className="absolute -top-3.5 -right-3.5 z-20 pointer-events-none"
                  >
                    <div className="w-9 h-9 rounded-full bg-gradient-to-br from-yellow-300 to-amber-400 border-2 border-white shadow-md flex items-center justify-center">
                      <Star size={20} className="text-white fill-yellow-100 drop-shadow" />
                    </div>
                  </motion.div>
                )}
              </motion.button>
            );
          })}
        </div>
      </div>

      {/* --- TOP 100PX BANNER (Touch-Protected Header) --- */}
      {/* Strict top 100px touch guard protects mascot, score, and settings */}
      {/* Fully opaque solid bg-white so falling letters emerge right from beneath */}
      <header className="fixed top-0 inset-x-0 h-[100px] z-50 flex items-center justify-center pointer-events-auto">
        <div className="w-full max-w-md h-full px-3 sm:px-4 flex items-center justify-between bg-white border-b-2 border-purple-100/90 shadow-md rounded-b-3xl overflow-hidden relative">
          
          {/* Mascot in Top Banner - Animated and voice interactive on baby tap */}
          <motion.button
            type="button"
            aria-label="Tap Jelly Bear"
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.92, rotate: [-6, 6, -3, 0] }}
            className="shrink-0 flex items-center cursor-pointer select-none border-none bg-transparent p-0 m-0 focus:outline-none"
            onClick={handleMascotTap}
          >
            <JellyBearMascot mood={mascotMood} size={52} />
          </motion.button>

          {/* 3-Star Max Candy Counter - Exactly 3 stars, fixed width, never overflows */}
          <motion.button
            type="button"
            aria-label={`${starCount} of 3 stars. Tap to count.`}
            onClick={handleCounterTap}
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.94 }}
            className={`shrink-0 flex items-center justify-center gap-2 px-3.5 py-1.5 bg-gradient-to-r ${currentPalette.starPillBg} rounded-full border-2 border-white shadow-md cursor-pointer select-none transition-all duration-700 min-w-[96px] max-w-[110px] h-[42px]`}
          >
            {[0, 1, 2].map(idx => {
              const isFilled = starCount > idx;
              return (
                <motion.div
                  key={idx}
                  animate={
                    isFilled
                      ? { scale: [1, 1.25, 1], rotate: [0, 12, -12, 0] }
                      : { scale: 1, rotate: 0 }
                  }
                  transition={{ duration: 0.3 }}
                  className="shrink-0 flex items-center justify-center"
                >
                  <Star
                    size={21}
                    className={
                      isFilled
                        ? 'text-yellow-200 fill-yellow-300 drop-shadow-xs'
                        : 'text-white/45 fill-white/15'
                    }
                  />
                </motion.div>
              );
            })}
          </motion.button>

          {/* Right Controls: 3-Second Timed Parental Settings Button (Sound is inside settings) */}
          <div className="shrink-0 flex items-center">
            <ParentLockButton
              ageTier={ageTier}
              onUnlock={() => setIsSettingsOpen(true)}
            />
          </div>
        </div>
      </header>

      {/* Minimalist Parental Settings Modal */}
      <ParentSettingsModal
        isOpen={isSettingsOpen}
        onClose={() => setIsSettingsOpen(false)}
        currentAgeTier={ageTier}
        onSelectTier={handleSelectAgeTier}
        isMuted={isMuted}
        onToggleMute={toggleMute}
        praiseMode={praiseMode}
        onTogglePraiseMode={togglePraiseMode}
      />
    </div>
  );
}

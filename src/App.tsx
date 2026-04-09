/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import { useState, useEffect, useCallback, useRef } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import confetti from 'canvas-confetti';
import { Star, Smile } from 'lucide-react';

// --- Constants & Types ---

const EDUCATIONAL_CONTENT = [
  'A', 'B', 'C', 'D', 'E', 'F', 'G',
  '1', '2', '3', '4', '5',
  '★', '♥', '●', '▲', '■'
];

const SPOKEN_WORDS: Record<string, string> = {
  '★': 'Star',
  '♥': 'Heart',
  '●': 'Circle',
  '▲': 'Triangle',
  '■': 'Square'
};

interface TileData {
  id: number;
  lane: number;
  color: string;
  content: string;
  y: number;
  isStuck: boolean;
}

// --- Audio Utility ---

class BabyTTS {
  private voice: SpeechSynthesisVoice | null = null;

  constructor() {
    if (typeof window !== 'undefined' && window.speechSynthesis) {
      this.loadVoices();
      window.speechSynthesis.onvoiceschanged = () => this.loadVoices();
    }
  }

  private loadVoices() {
    const voices = window.speechSynthesis.getVoices();
    const preferredVoices = ['Samantha', 'Victoria', 'Karen', 'Zira', 'Google UK English Female', 'Google US English'];
    
    this.voice = voices.find(v => preferredVoices.some(name => v.name.includes(name))) 
              || voices.find(v => v.lang.startsWith('en') && v.name.includes('Female'))
              || voices.find(v => v.lang.startsWith('en')) 
              || voices[0] || null;
  }

  speak(text: string) {
    if (!window.speechSynthesis) return;
    
    // Cancel any ongoing speech so it doesn't queue up too much
    window.speechSynthesis.cancel();
    
    // Convert to lowercase to prevent some engines from saying "Capital"
    const spokenText = SPOKEN_WORDS[text] || text.toLowerCase();
    const utterance = new SpeechSynthesisUtterance(spokenText);
    
    if (this.voice) {
      utterance.voice = this.voice;
    }
    
    // Make it sound friendly and sharp (higher pitch, slightly faster)
    utterance.pitch = 1.5;
    utterance.rate = 1.0;
    
    window.speechSynthesis.speak(utterance);
  }
}

const tts = new BabyTTS();

// --- Components ---

export default function App() {
  const [tiles, setTiles] = useState<TileData[]>([]);
  const [score, setScore] = useState(0);
  const [isStarted, setIsStarted] = useState(false);
  const [isPaused, setIsPaused] = useState(false);
  
  const gameLoopRef = useRef<number>(0);
  const speedRef = useRef<number>(0.8); // Start extremely slow for baby
  const nextIdRef = useRef<number>(0);
  const gapRef = useRef<number>(150);
  const hueRef = useRef<number>(Math.random() * 360);

  const spawnTile = useCallback(() => {
    const lane = Math.floor(Math.random() * 4);
    
    // Gradient progression color
    const color = `hsl(${hueRef.current}, 85%, 65%)`;
    hueRef.current = (hueRef.current + 25) % 360; // Shift hue for the next tile

    const content = EDUCATIONAL_CONTENT[Math.floor(Math.random() * EDUCATIONAL_CONTENT.length)];
    
    return {
      id: nextIdRef.current++,
      lane,
      color,
      content,
      y: -250, // Start above the screen
      isStuck: false,
    };
  }, []);

  useEffect(() => {
    if (!isStarted) return;

    const update = () => {
      setTiles(prev => {
        const stuckTile = prev.find(t => t.isStuck);
        const centerY = window.innerHeight / 2 - 80; // Approximate center

        if (stuckTile) {
          setIsPaused(true);
          // Move all tiles UP until the stuck tile is at centerY
          if (stuckTile.y > centerY) {
            const diff = stuckTile.y - centerY;
            const moveUp = Math.min(3, diff); // Slow rewind speed
            return prev.map(t => ({ ...t, y: t.y - moveUp }));
          }
          return prev; // Hold at center
        }

        setIsPaused(false);
        let hitBottom = false;
        const bottomThreshold = window.innerHeight - 100;

        const updated = prev.map(t => {
          if (t.y >= bottomThreshold && !t.isStuck) {
            hitBottom = true;
            return { ...t, y: bottomThreshold, isStuck: true };
          }
          return { ...t, y: t.y + speedRef.current };
        });

        // Distance-based spawning
        const highestY = updated.length > 0 ? Math.min(...updated.map(t => t.y)) : 1000;
        if (highestY > gapRef.current && !hitBottom) {
          updated.push(spawnTile());
          gapRef.current = 150 + Math.random() * 100;
        }

        return updated;
      });

      gameLoopRef.current = requestAnimationFrame(update);
    };

    gameLoopRef.current = requestAnimationFrame(update);
    return () => cancelAnimationFrame(gameLoopRef.current);
  }, [isStarted, spawnTile]);

  const handleTileClick = useCallback((id: number, lane: number, color: string, content: string, wasStuck: boolean) => {
    // Speak the text
    tts.speak(content);

    // Confetti at click position
    confetti({
      particleCount: 40,
      spread: 70,
      origin: { y: 0.8 },
      colors: [color],
    });

    setScore(s => s + 1);

    // Adaptive Speed Logic
    if (wasStuck) {
      // Baby missed it and had to be prompted. Slow down to help them.
      speedRef.current = Math.max(0.5, speedRef.current - 0.5);
    } else {
      // Baby clicked it while moving! Speed up slightly.
      speedRef.current = Math.min(4.0, speedRef.current + 0.15);
    }

    setTiles(prev => prev.filter(t => t.id !== id));
  }, []);

  if (!isStarted) {
    return (
      <div className="fixed inset-0 bg-white flex items-center justify-center p-8 text-center">
        <motion.button
          whileHover={{ scale: 1.1 }}
          whileTap={{ scale: 0.9 }}
          onClick={() => {
            if (window.speechSynthesis) {
              const u = new SpeechSynthesisUtterance('');
              u.volume = 0;
              window.speechSynthesis.speak(u);
            }
            setIsStarted(true);
          }}
          className="bg-yellow-400 text-white rounded-full w-64 h-64 flex flex-col items-center justify-center shadow-2xl border-8 border-yellow-200"
        >
          <Smile size={80} className="mb-4" />
          <span className="text-4xl font-black uppercase tracking-tighter">Play!</span>
        </motion.button>
      </div>
    );
  }

  return (
    <div className="fixed inset-0 bg-indigo-950 flex justify-center overflow-hidden select-none touch-none">
      {/* Background Glows */}
      <div className="absolute top-[-10%] left-[-10%] w-[40%] h-[40%] bg-purple-600/20 rounded-full blur-[120px] pointer-events-none" />
      <div className="absolute bottom-[-10%] right-[-10%] w-[40%] h-[40%] bg-blue-600/20 rounded-full blur-[120px] pointer-events-none" />

      {/* Game Board */}
      <div className="relative w-full max-w-md h-full bg-indigo-900/40 border-x border-white/10 shadow-2xl">
        {/* Lanes Background */}
        <div className="absolute inset-0 flex">
          {[0, 1, 2, 3].map(i => (
            <div key={i} className="flex-1 border-r border-white/10 last:border-r-0" />
          ))}
        </div>

        {/* Tiles */}
        <div className="absolute inset-0">
          {tiles.map(tile => {
            return (
              <motion.button
                key={tile.id}
                initial={{ opacity: 0, scale: 0.8 }}
                animate={{ opacity: 1, scale: tile.isStuck ? 1.05 : 1 }}
                whileTap={{ scale: 0.9 }}
                onClick={() => handleTileClick(tile.id, tile.lane, tile.color, tile.content, tile.isStuck)}
                className="absolute aspect-[3/4] rounded-2xl shadow-2xl flex flex-col items-center justify-center border-b-8 border-black/20"
                style={{
                  width: '23%',
                  left: `calc(${tile.lane * 25}% + 1%)`,
                  top: tile.y,
                  backgroundColor: tile.color,
                  zIndex: tile.isStuck ? 50 : 10,
                }}
              >
                {/* Flashing Hint for Babies */}
                <motion.div
                  animate={{ opacity: tile.isStuck ? [0, 0.6, 0] : [0, 0.2, 0] }}
                  transition={{ duration: tile.isStuck ? 0.4 : 1.5, repeat: Infinity }}
                  className="absolute inset-0 bg-white rounded-2xl"
                />

                <div className="text-white text-7xl sm:text-[80px] font-black drop-shadow-md z-10">
                  {tile.content}
                </div>
              </motion.button>
            );
          })}
        </div>
      </div>

      {/* UI Overlay */}
      <div className="absolute top-0 left-0 right-0 p-4 flex justify-center pointer-events-none z-50">
        <div className="flex items-center gap-2 opacity-40">
          <Star className="text-white fill-white" size={16} />
          <span className="text-xl font-bold text-white">{score}</span>
        </div>
      </div>

      {/* Reinforcement Popups */}
      <AnimatePresence>
        {score > 0 && score % 10 === 0 && (
          <motion.div
            initial={{ scale: 0, rotate: -20 }}
            animate={{ scale: 1, rotate: 0 }}
            exit={{ scale: 0, opacity: 0 }}
            className="absolute inset-0 flex items-center justify-center z-[100] pointer-events-none"
          >
            <div className="bg-white p-12 rounded-[4rem] shadow-2xl border-8 border-green-400 flex flex-col items-center">
              <Smile size={120} className="text-green-500 mb-4" />
              <h2 className="text-6xl font-black text-green-600 uppercase">Great!</h2>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}

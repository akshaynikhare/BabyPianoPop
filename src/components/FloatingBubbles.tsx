import React, { useMemo } from 'react';

interface Bubble {
  id: number;
  size: number;
  left: number;
  duration: number;
  delay: number;
  swayDuration: number;
  opacity: number;
  colorGrad: string;
}

const BUBBLE_GRADIENTS = [
  'from-pink-300/40 via-rose-200/30 to-white/60',
  'from-sky-300/40 via-cyan-200/30 to-white/60',
  'from-amber-200/45 via-yellow-100/30 to-white/65',
  'from-purple-300/40 via-fuchsia-200/30 to-white/60',
  'from-emerald-200/40 via-teal-100/30 to-white/60',
];

export const FloatingBubbles: React.FC = () => {
  // Pre-calculate fixed bubble parameters to avoid re-renders during gameplay
  const bubbles: Bubble[] = useMemo(() => {
    return Array.from({ length: 16 }, (_, i) => {
      // Deterministic spread across screen
      const size = 18 + ((i * 17 + 7) % 36); // 18px to 54px
      const left = ((i * 23 + 11) % 94) + 3; // 3% to 97%
      const duration = 14 + ((i * 7) % 12); // 14s to 25s for calm, slow float
      const delay = -(((i * 3.5) % 16)); // negative delay ensures instant coverage on mount
      const swayDuration = 3.5 + ((i * 1.8) % 4); // 3.5s to 7.5s gentle sway
      const opacity = 0.22 + (((i * 5) % 18) / 100); // 0.22 to 0.40
      const colorGrad = BUBBLE_GRADIENTS[i % BUBBLE_GRADIENTS.length];

      return {
        id: i,
        size,
        left,
        duration,
        delay,
        swayDuration,
        opacity,
        colorGrad,
      };
    });
  }, []);

  return (
    <div
      aria-hidden="true"
      className="fixed inset-0 pointer-events-none overflow-hidden z-0 select-none"
    >
      <style>{`
        @keyframes floatUpward {
          0% {
            transform: translate3d(0, 105vh, 0);
          }
          100% {
            transform: translate3d(0, -15vh, 0);
          }
        }
        @keyframes gentleSway {
          0%, 100% {
            margin-left: 0px;
          }
          50% {
            margin-left: 18px;
          }
        }
      `}</style>

      {bubbles.map(b => (
        <div
          key={b.id}
          className="absolute bottom-0 will-change-transform"
          style={{
            left: `${b.left}%`,
            animation: `floatUpward ${b.duration}s linear infinite`,
            animationDelay: `${b.delay}s`,
          }}
        >
          <div
            className={`rounded-full bg-gradient-to-tr ${b.colorGrad} border border-white/60 shadow-[inset_0_2px_4px_rgba(255,255,255,0.7),0_4px_12px_rgba(255,255,255,0.3)] backdrop-blur-[1px] relative`}
            style={{
              width: `${b.size}px`,
              height: `${b.size}px`,
              opacity: b.opacity,
              animation: `gentleSway ${b.swayDuration}s ease-in-out infinite`,
            }}
          >
            {/* Soft inner glossy shine highlight */}
            <div className="absolute top-1 left-1.5 w-1/3 h-1/3 rounded-full bg-white/80 pointer-events-none" />
            <div className="absolute bottom-1.5 right-1.5 w-1/5 h-1/5 rounded-full bg-white/40 pointer-events-none" />
          </div>
        </div>
      ))}
    </div>
  );
};
export default FloatingBubbles;

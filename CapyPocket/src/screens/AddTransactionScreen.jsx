import { useState } from "react";
import { CapybaraMascot } from "../components/CapybaraMascot";
import { Icon } from "../components/Icons";

const TYPES = ["Expense", "Income", "Pocket"];

const CATEGORIES = [
  { id: "food",          label: "Food",          emoji: "🍱" },
  { id: "transport",     label: "Transport",      emoji: "🚌" },
  { id: "shopping",      label: "Shopping",       emoji: "🛒" },
  { id: "health",        label: "Health",         emoji: "✏️" },
  { id: "entertainment", label: "Entertainment",  emoji: "🎪" },
  { id: "salary",        label: "Salary",         emoji: "💼" },
  { id: "pocket",        label: "Pocket",         emoji: "⇄" },
];

const NUMPAD = [
  ["1", "2", "3"],
  ["4", "5", "6"],
  ["7", "8", "9"],
  [".", "0", "⌫"],
];

function today() {
  return new Date().toISOString().slice(0, 10);
}

export function AddTransactionScreen({ onBack }) {
  const [type, setType]       = useState("Income");
  const [category, setCategory] = useState("food");
  const [amount, setAmount]   = useState("0.00");
  const [date, setDate]       = useState(today());

  /* ── numpad logic ─────────────────────────────── */
  function handleKey(key) {
    setAmount((prev) => {
      if (key === "⌫") {
        const next = prev.slice(0, -1);
        return next === "" || next === "-" ? "0.00" : next;
      }

      // Start fresh from "0.00"
      let raw = prev === "0.00" ? "" : prev;

      // Only one decimal point
      if (key === "." && raw.includes(".")) return prev;

      // Max 2 decimal places
      const dotIdx = raw.indexOf(".");
      if (dotIdx !== -1 && raw.length - dotIdx > 2) return prev;

      raw = raw + key;

      // Auto-format to 2dp once user hits dot then has 2 digits after
      return raw;
    });
  }

  const displayAmount = amount === "" ? "0.00" : amount;

  /* ── accent colors per type ───────────────────── */
  const typeAccent = {
    Expense: "text-[#c0392b]",
    Income:  "text-capy-moss",
    Pocket:  "text-capy-brown",
  };

  return (
    <div className="flex flex-col min-h-full pb-6">

      {/* ── Top bar ─────────────────────────────────── */}
      <div className="flex items-center justify-between px-1 pt-2 pb-4 animate-rise">
        <button
          type="button"
          onClick={onBack}
          className="flex h-10 w-10 items-center justify-center rounded-2xl bg-white/80 text-capy-cocoa shadow-sm transition hover:bg-capy-cream active:scale-95"
        >
          <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth={1.8} strokeLinecap="round" strokeLinejoin="round">
            <path d="M15 6l-6 6 6 6" />
          </svg>
        </button>
        <span className="font-display text-lg text-capy-cocoa">Add Transaction</span>
        <div className="w-10" /> {/* spacer */}
      </div>

      {/* ── Amount display ──────────────────────────── */}
      <div className="animate-rise flex flex-col items-center gap-1 py-2" style={{ animationDelay: "60ms" }}>
        <div className="animate-capy-float rounded-[28px] bg-capy-vanilla/70 p-2 shadow-sm">
          <CapybaraMascot className="h-16 w-16" mood="calm" accessory="coin" />
        </div>
        <p className="mt-3 text-xs font-black uppercase tracking-[0.3em] text-capy-brown/55">Amount</p>
        <p className={`font-display text-5xl leading-none ${typeAccent[type]}`}>
          ฿{displayAmount}
        </p>
      </div>

      {/* ── Type tabs ───────────────────────────────── */}
      <div
        className="animate-rise mx-1 mt-4 flex items-center rounded-2xl border border-capy-vanilla bg-white/70 p-1 shadow-sm"
        style={{ animationDelay: "100ms" }}
      >
        {TYPES.map((t) => (
          <button
            key={t}
            type="button"
            onClick={() => setType(t)}
            className={`flex flex-1 items-center justify-center gap-1.5 rounded-xl py-2.5 text-sm font-black transition duration-200 ${
              type === t
                ? "bg-capy-cocoa text-white shadow-sm"
                : "text-capy-brown/70 hover:bg-capy-cream/70"
            }`}
          >
            {type === t && (
              <svg viewBox="0 0 24 24" className="h-3.5 w-3.5" fill="none" stroke="currentColor" strokeWidth={2.5} strokeLinecap="round" strokeLinejoin="round">
                <path d="M5 12l5 5L19 7" />
              </svg>
            )}
            {t.toUpperCase()}
          </button>
        ))}
      </div>

      {/* ── Category ────────────────────────────────── */}
      <div className="animate-rise mt-5 px-0" style={{ animationDelay: "140ms" }}>
        <p className="mb-2.5 text-sm font-black text-capy-cocoa">Category</p>
        <div className="flex flex-wrap gap-2">
          {CATEGORIES.map((c) => (
            <button
              key={c.id}
              type="button"
              onClick={() => setCategory(c.id)}
              className={`flex items-center gap-1.5 rounded-full border px-3.5 py-1.5 text-sm font-bold transition duration-150 ${
                category === c.id
                  ? "border-capy-apricot bg-capy-peach/60 text-capy-cocoa shadow-sm"
                  : "border-capy-vanilla bg-white/70 text-capy-brown/75 hover:bg-capy-cream/70"
              }`}
            >
              <span className="text-base leading-none">{c.emoji}</span>
              {c.label}
            </button>
          ))}
        </div>
      </div>

      {/* ── Date picker ─────────────────────────────── */}
      <div className="animate-rise mt-5 px-0" style={{ animationDelay: "180ms" }}>
        <p className="mb-2.5 text-sm font-black text-capy-cocoa">Date</p>
        <label className="flex cursor-pointer items-center justify-between rounded-2xl border border-capy-vanilla bg-white/80 px-4 py-3 shadow-sm transition hover:bg-capy-cream/50">
          <div className="flex items-center gap-3">
            <svg viewBox="0 0 24 24" className="h-5 w-5 text-capy-brown/70" fill="none" stroke="currentColor" strokeWidth={1.8} strokeLinecap="round" strokeLinejoin="round">
              <rect x="3.5" y="4.5" width="17" height="16" rx="2.5" />
              <path d="M8 3v3M16 3v3M3.5 9.5h17" />
            </svg>
            <span className="font-bold text-capy-cocoa">{date}</span>
          </div>
          <Icon name="chevronRight" className="h-4 w-4 text-capy-brown/50" />
          <input
            type="date"
            value={date}
            onChange={(e) => setDate(e.target.value)}
            className="absolute opacity-0 w-0 h-0 pointer-events-none"
            tabIndex={-1}
          />
        </label>
      </div>

      {/* ── Numpad ──────────────────────────────────── */}
      <div className="animate-rise mt-5 flex-1" style={{ animationDelay: "220ms" }}>
        <div className="grid grid-rows-4 gap-2.5">
          {NUMPAD.map((row, ri) => (
            <div key={ri} className="grid grid-cols-3 gap-2.5">
              {row.map((key) => (
                <button
                  key={key}
                  type="button"
                  onClick={() => handleKey(key)}
                  className={`flex h-14 items-center justify-center rounded-2xl text-xl font-black shadow-sm transition duration-100 active:scale-95 select-none ${
                    key === "⌫"
                      ? "bg-capy-rose/70 text-capy-cocoa hover:bg-capy-rose"
                      : "bg-white/90 text-capy-cocoa hover:bg-capy-cream"
                  }`}
                >
                  {key === "⌫" ? (
                    <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth={1.8} strokeLinecap="round" strokeLinejoin="round">
                      <path d="M21 6H8l-6 6 6 6h13a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2Z" />
                      <path d="m15 10-4 4m0-4 4 4" />
                    </svg>
                  ) : key}
                </button>
              ))}
            </div>
          ))}
        </div>
      </div>

      {/* ── Submit ──────────────────────────────────── */}
      <button
        type="button"
        className="animate-rise mt-5 flex w-full items-center justify-center gap-2 rounded-2xl bg-capy-peach py-4 text-base font-black text-capy-cocoa shadow-sm transition duration-200 hover:bg-capy-apricot active:scale-[0.98]"
        style={{ animationDelay: "260ms" }}
        onClick={() => {
          // placeholder submit
          alert(`Added: ฿${displayAmount} · ${type} · ${category} · ${date}`);
          onBack?.();
        }}
      >
        Add Transaction
        <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth={2} strokeLinecap="round" strokeLinejoin="round">
          <path d="M5 12h14M13 6l6 6-6 6" />
        </svg>
      </button>
    </div>
  );
}

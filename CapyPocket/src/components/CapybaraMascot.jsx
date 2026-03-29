export function CapybaraMascot({ className = "h-24 w-24", mood = "calm", accessory = "coin" }) {
  return (
    <svg viewBox="0 0 160 160" className={className} aria-hidden="true">
      <defs>
        <linearGradient id="capy-body" x1="0%" x2="100%" y1="0%" y2="100%">
          <stop offset="0%" stopColor="#c89c70" />
          <stop offset="100%" stopColor="#b78454" />
        </linearGradient>
        <linearGradient id="capy-belly" x1="0%" x2="100%" y1="0%" y2="100%">
          <stop offset="0%" stopColor="#f7e8d8" />
          <stop offset="100%" stopColor="#eed8bf" />
        </linearGradient>
      </defs>

      <circle cx="80" cy="80" r="68" fill="#fff6ee" />
      <circle cx="48" cy="43" r="17" fill="url(#capy-body)" />
      <circle cx="113" cy="43" r="17" fill="url(#capy-body)" />
      <circle cx="48" cy="43" r="8" fill="#6a4a39" fillOpacity="0.18" />
      <circle cx="113" cy="43" r="8" fill="#6a4a39" fillOpacity="0.18" />
      <ellipse cx="80" cy="88" rx="45" ry="52" fill="url(#capy-body)" />
      <ellipse cx="80" cy="97" rx="28" ry="30" fill="url(#capy-belly)" />
      <ellipse cx="80" cy="76" rx="27" ry="22" fill="#eed8bf" />
      <ellipse cx="79" cy="80" rx="13" ry="10" fill="#6a4a39" fillOpacity="0.16" />
      <ellipse cx="70" cy="76" rx="3.6" ry="5.2" fill="#6a4a39" />
      <ellipse cx="90" cy="76" rx="3.6" ry="5.2" fill="#6a4a39" />

      {mood === "happy" ? (
        <>
          <path d="M60 64c4-5 12-5 16 0" stroke="#6a4a39" strokeWidth="4" strokeLinecap="round" fill="none" />
          <path d="M84 64c4-5 12-5 16 0" stroke="#6a4a39" strokeWidth="4" strokeLinecap="round" fill="none" />
          <path d="M66 91c8 9 20 9 28 0" stroke="#6a4a39" strokeWidth="4" strokeLinecap="round" fill="none" />
        </>
      ) : mood === "wink" ? (
        <>
          <path d="M58 66c5-4 11-4 16 0" stroke="#6a4a39" strokeWidth="4" strokeLinecap="round" fill="none" />
          <circle cx="95" cy="66" r="4.6" fill="#6a4a39" />
          <path d="M67 91c8 7 18 7 26 0" stroke="#6a4a39" strokeWidth="4" strokeLinecap="round" fill="none" />
        </>
      ) : (
        <>
          <circle cx="65" cy="66" r="4.6" fill="#6a4a39" />
          <circle cx="95" cy="66" r="4.6" fill="#6a4a39" />
          <path d="M68 92c7 5 17 5 24 0" stroke="#6a4a39" strokeWidth="4" strokeLinecap="round" fill="none" />
        </>
      )}

      <ellipse cx="80" cy="83" rx="7" ry="5.2" fill="#6a4a39" />
      <path d="M73 89c4 3 10 3 14 0" stroke="#6a4a39" strokeWidth="3.2" strokeLinecap="round" fill="none" />
      <ellipse cx="55" cy="83" rx="6" ry="3.8" fill="#efb3a6" fillOpacity="0.65" />
      <ellipse cx="105" cy="83" rx="6" ry="3.8" fill="#efb3a6" fillOpacity="0.65" />
      <ellipse cx="60" cy="123" rx="10" ry="13" fill="#b78454" />
      <ellipse cx="100" cy="123" rx="10" ry="13" fill="#b78454" />

      {accessory === "coin" ? (
        <>
          <circle cx="123" cy="34" r="16" fill="#f3cb77" />
          <path d="M118 34h10" stroke="#8e643f" strokeWidth="3" strokeLinecap="round" />
          <path d="M123 29v10" stroke="#8e643f" strokeWidth="3" strokeLinecap="round" />
        </>
      ) : null}

      {accessory === "leaf" ? (
        <>
          <path d="M123 18c11 1 18 11 16 22-11 0-20-7-21-18 0-1 2-4 5-4Z" fill="#8db582" />
          <path d="M118 38c6-4 10-10 14-18" stroke="#5f7c59" strokeWidth="3" strokeLinecap="round" fill="none" />
        </>
      ) : null}
    </svg>
  );
}

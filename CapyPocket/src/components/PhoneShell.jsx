import { Icon } from "./Icons";

const navItems = [
  { id: "home", label: "Home", icon: "home" },
  { id: "wallet", label: "Wallet", icon: "wallet" },
  { id: "savings", label: "Savings", icon: "piggy" },
  { id: "profile", label: "Profile", icon: "user" },
];

function StatusBar() {
  return (
    <div className="flex items-center justify-between px-6 pb-2 pt-5 text-sm font-black text-capy-cocoa">
      <span>9:41</span>
      <div className="flex items-center gap-2 text-capy-brown">
        <span className="h-2 w-2 rounded-full bg-capy-moss" />
        <span className="h-2 w-2 rounded-full bg-capy-brown/40" />
        <div className="h-3 w-6 rounded-sm border border-capy-brown/50">
          <div className="m-[1px] h-[7px] w-4 rounded-[2px] bg-capy-brown/70" />
        </div>
      </div>
    </div>
  );
}

function BottomNav({ activeTab, onTabChange }) {
  return (
    <div className="absolute inset-x-4 bottom-4 rounded-[28px] border border-white/70 bg-white/95 p-2 shadow-soft backdrop-blur">
      <nav className="grid grid-cols-4 gap-2">
        {navItems.map((item) => {
          const active = item.id === activeTab;

          return (
            <button
              key={item.id}
              type="button"
              onClick={() => onTabChange(item.id)}
              className={`flex flex-col items-center gap-1 rounded-2xl px-2 py-2 transition duration-200 ${
                active ? "bg-capy-cream text-capy-cocoa" : "text-capy-brown/65 hover:bg-capy-cream/70"
              }`}
            >
              <span
                className={`flex h-9 w-9 items-center justify-center rounded-2xl ${
                  active ? "bg-gradient-to-br from-capy-peach to-capy-apricot/70 shadow-sm" : "bg-transparent"
                }`}
              >
                <Icon name={item.icon} className="h-5 w-5" />
              </span>
              <span className="text-[11px] font-black">{item.label}</span>
            </button>
          );
        })}
      </nav>
    </div>
  );
}

export function PhoneShell({ activeTab, onTabChange, hideNav = false, children }) {
  return (
    <div className="relative w-full max-w-[390px] overflow-hidden bg-white/85 shadow-soft sm:h-[812px] sm:rounded-[42px] sm:border sm:border-white/70">
      <div className="absolute inset-x-0 top-0 h-28 bg-capy-glow opacity-80" />
      <div className="relative flex min-h-[100svh] flex-col sm:h-full sm:min-h-0">
        <StatusBar />
        <main className={`screen-scrollbar flex-1 overflow-y-auto px-5 ${hideNav ? "pb-6" : "pb-28"}`}>{children}</main>
        {!hideNav && <BottomNav activeTab={activeTab} onTabChange={onTabChange} />}
      </div>
    </div>
  );
}

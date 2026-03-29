import { CapybaraMascot } from "../components/CapybaraMascot";
import { Icon } from "../components/Icons";
import { SectionCard } from "../components/SectionCard";
import { WalletCard } from "../components/WalletCard";

export function WalletScreen({ user, walletCards }) {
  return (
    <div className="space-y-5 pb-6 pt-3">
      <header className="animate-rise flex items-start justify-between">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.3em] text-capy-brown/55">Your money</p>
          <h1 className="font-display text-[2.05rem] leading-none text-capy-cocoa">Wallet</h1>
          <p className="mt-2 text-sm font-semibold text-capy-brown/75">Cards tucked in one comfy place.</p>
        </div>
        <button className="flex h-11 w-11 items-center justify-center rounded-2xl bg-white/80 text-capy-cocoa shadow-sm">
          <Icon name="dots" className="h-5 w-5" />
        </button>
      </header>

      <SectionCard className="animate-rise overflow-hidden bg-gradient-to-br from-capy-cocoa via-capy-brown to-capy-orange text-white" style={{ animationDelay: "80ms" }}>
        <div className="flex items-center gap-4">
          <div className="min-w-0 flex-1">
            <p className="text-sm font-bold text-white/75">Available balance</p>
            <h2 className="mt-1 font-display text-4xl leading-none">{user.balance}</h2>
            <div className="mt-4 flex gap-3 text-sm font-bold text-white/80">
              <span className="rounded-full bg-white/15 px-3 py-1">Cash {user.pocketCash}</span>
              <span className="rounded-full bg-white/15 px-3 py-1">Saved {user.savings}</span>
            </div>
          </div>
          <div className="animate-soft-bob rounded-[30px] bg-white/10 p-2">
            <CapybaraMascot className="h-24 w-24" mood="wink" accessory="coin" />
          </div>
        </div>
      </SectionCard>

      <section className="animate-rise space-y-3" style={{ animationDelay: "150ms" }}>
        <div className="flex items-center justify-between">
          <h2 className="text-lg font-black text-capy-cocoa">Cards</h2>
          <span className="rounded-full bg-capy-cream px-3 py-1 text-xs font-black text-capy-brown">
            {walletCards.length} active
          </span>
        </div>
        <div className="space-y-3">
          {walletCards.map((card) => (
            <WalletCard key={card.id} card={card} />
          ))}
        </div>
      </section>

      <button className="animate-rise flex w-full items-center justify-center gap-2 rounded-[28px] border border-dashed border-capy-brown/25 bg-white/70 px-4 py-4 text-sm font-black text-capy-cocoa shadow-sm transition duration-200 hover:-translate-y-0.5 hover:bg-white" style={{ animationDelay: "220ms" }}>
        <Icon name="plus" className="h-5 w-5" />
        Add new card
      </button>
    </div>
  );
}

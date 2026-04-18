import { CapybaraMascot } from "../components/CapybaraMascot";
import { Icon } from "../components/Icons";
import { QuickActionButton } from "../components/QuickActionButton";
import { SectionCard } from "../components/SectionCard";
import { TransactionItem } from "../components/TransactionItem";

export function HomeScreen({ user, quickActions, transactions, onAddTransaction }) {
  return (
    <div className="space-y-5 pb-6 pt-3">
      <header className="animate-rise flex items-start justify-between">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.3em] text-capy-brown/55">CapyPocket</p>
          <h1 className="font-display text-[2.15rem] leading-none text-capy-cocoa">Hello, {user.name}</h1>
          <p className="mt-2 text-sm font-semibold text-capy-brown/75">Your wallet looks extra cozy today.</p>
        </div>
        <button className="flex h-11 w-11 items-center justify-center rounded-2xl bg-white/80 text-capy-cocoa shadow-sm">
          <Icon name="bell" className="h-5 w-5" />
        </button>
      </header>

      <SectionCard className="animate-rise relative overflow-hidden bg-gradient-to-br from-capy-vanilla via-white to-capy-peach/55" style={{ animationDelay: "80ms" }}>
        <div className="absolute -right-8 -top-8 h-28 w-28 rounded-full bg-white/50" />
        <div className="relative flex items-center gap-3">
          <div className="min-w-0 flex-1">
            <p className="text-sm font-bold text-capy-brown/70">Total balance</p>
            <h2 className="mt-1 font-display text-4xl leading-none text-capy-cocoa">{user.balance}</h2>
            <div className="mt-4 inline-flex rounded-full bg-white/80 px-3 py-1 text-xs font-black text-capy-moss shadow-sm">
              {user.monthChange} this month
            </div>
            <div className="mt-4 grid grid-cols-2 gap-2">
              <div className="rounded-2xl bg-white/70 p-3 shadow-sm">
                <p className="text-xs font-black uppercase tracking-[0.2em] text-capy-brown/50">Pocket</p>
                <p className="mt-1 text-sm font-black text-capy-cocoa">{user.pocketCash}</p>
              </div>
              <div className="rounded-2xl bg-white/70 p-3 shadow-sm">
                <p className="text-xs font-black uppercase tracking-[0.2em] text-capy-brown/50">Saved</p>
                <p className="mt-1 text-sm font-black text-capy-cocoa">{user.savings}</p>
              </div>
            </div>
          </div>
          <div className="animate-capy-float shrink-0 rounded-[32px] bg-white/65 p-2 shadow-sm">
            <CapybaraMascot className="h-28 w-28" accessory="coin" />
          </div>
        </div>
      </SectionCard>

      <section className="animate-rise" style={{ animationDelay: "140ms" }}>
        <div className="mb-3 flex items-center justify-between">
          <h2 className="text-lg font-black text-capy-cocoa">Quick actions</h2>
          <p className="text-xs font-black uppercase tracking-[0.22em] text-capy-brown/45">tap to go</p>
        </div>
        <div className="grid grid-cols-4 gap-3">
          {quickActions.map((action) => (
            <QuickActionButton key={action.id} action={action} />
          ))}
        </div>
      </section>

      <section className="animate-rise space-y-3" style={{ animationDelay: "200ms" }}>
        <div className="flex items-center justify-between">
          <h2 className="text-lg font-black text-capy-cocoa">Recent transactions</h2>
          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={onAddTransaction}
              className="flex items-center gap-1 rounded-full bg-capy-peach px-3 py-1.5 text-xs font-black text-capy-cocoa shadow-sm transition hover:bg-capy-apricot active:scale-95"
            >
              <Icon name="plus" className="h-3.5 w-3.5" />
              Add
            </button>
            <button className="text-sm font-black text-capy-brown/65">See all</button>
          </div>
        </div>
        <div className="space-y-3">
          {transactions.map((transaction) => (
            <TransactionItem key={transaction.id} transaction={transaction} />
          ))}
        </div>
      </section>
    </div>
  );
}

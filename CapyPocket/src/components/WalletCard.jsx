export function WalletCard({ card }) {
  return (
    <div className={`relative overflow-hidden rounded-[30px] bg-gradient-to-br ${card.gradient} p-5 text-white shadow-sm`}>
      <div className="absolute -right-4 -top-4 h-24 w-24 rounded-full bg-white/10" />
      <div className="absolute right-6 top-16 h-14 w-14 rounded-full bg-white/10" />
      <div className="relative flex items-start justify-between">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.3em] text-white/70">{card.name}</p>
          <p className="mt-4 text-2xl font-black">{card.amount}</p>
        </div>
        <div className="rounded-full bg-white/15 px-3 py-1 text-[10px] font-black tracking-[0.24em] text-white/80">
          {card.network}
        </div>
      </div>

      <div className="relative mt-8 flex items-center gap-3">
        <div className="h-9 w-12 rounded-xl bg-white/75" />
        <div className="flex gap-2">
          <span className="h-3 w-3 rounded-full bg-white/80" />
          <span className="h-3 w-3 rounded-full bg-white/45" />
        </div>
      </div>

      <div className="relative mt-8 flex items-end justify-between gap-4">
        <div>
          <p className="font-mono text-sm tracking-[0.32em] text-white/90">{card.number}</p>
          <p className="mt-3 text-xs font-bold uppercase tracking-[0.22em] text-white/70">Exp {card.expires}</p>
        </div>
      </div>
    </div>
  );
}

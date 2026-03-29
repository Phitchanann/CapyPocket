import { Icon } from "./Icons";

export function TransactionItem({ transaction }) {
  return (
    <div className="flex items-center gap-3 rounded-[24px] bg-white/80 px-3 py-3 shadow-sm">
      <span className={`flex h-11 w-11 items-center justify-center rounded-2xl ${transaction.tone}`}>
        <Icon name={transaction.icon} className="h-5 w-5" />
      </span>
      <div className="min-w-0 flex-1">
        <p className="truncate text-sm font-extrabold text-capy-cocoa">{transaction.title}</p>
        <p className="text-xs font-semibold text-capy-brown/70">{transaction.subtitle}</p>
      </div>
      <p className={`text-sm font-extrabold ${transaction.positive ? "text-capy-moss" : "text-capy-cocoa"}`}>
        {transaction.amount}
      </p>
    </div>
  );
}

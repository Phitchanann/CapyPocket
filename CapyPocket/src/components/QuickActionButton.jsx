import { Icon } from "./Icons";

export function QuickActionButton({ action }) {
  return (
    <button className="group flex flex-col items-center gap-2 rounded-[24px] bg-white/70 px-3 py-4 shadow-sm transition duration-200 hover:-translate-y-1 hover:bg-white">
      <span className={`flex h-11 w-11 items-center justify-center rounded-2xl bg-gradient-to-br ${action.accent} text-capy-cocoa shadow-sm transition duration-200 group-hover:scale-105`}>
        <Icon name={action.icon} className="h-5 w-5" />
      </span>
      <span className="text-xs font-extrabold text-capy-cocoa">{action.label}</span>
    </button>
  );
}

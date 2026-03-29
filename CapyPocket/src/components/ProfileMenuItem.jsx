import { Icon } from "./Icons";
import { SectionCard } from "./SectionCard";

export function ProfileMenuItem({ item }) {
  return (
    <button className="w-full text-left">
      <SectionCard className="flex items-center gap-3 py-3 transition duration-200 hover:-translate-y-0.5 hover:bg-white">
        <span className="flex h-11 w-11 items-center justify-center rounded-2xl bg-capy-cream text-capy-cocoa">
          <Icon name={item.icon} className="h-5 w-5" />
        </span>
        <div className="min-w-0 flex-1">
          <p className="text-sm font-extrabold text-capy-cocoa">{item.label}</p>
          <p className="text-xs font-semibold text-capy-brown/70">{item.hint}</p>
        </div>
        <Icon name="chevronRight" className="h-5 w-5 text-capy-brown/60" />
      </SectionCard>
    </button>
  );
}

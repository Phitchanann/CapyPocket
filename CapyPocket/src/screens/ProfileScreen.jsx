import { CapybaraMascot } from "../components/CapybaraMascot";
import { Icon } from "../components/Icons";
import { ProfileMenuItem } from "../components/ProfileMenuItem";
import { SectionCard } from "../components/SectionCard";

export function ProfileScreen({ user, profileMenu }) {
  return (
    <div className="space-y-5 pb-6 pt-3">
      <header className="animate-rise flex items-start justify-between">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.3em] text-capy-brown/55">Your corner</p>
          <h1 className="font-display text-[2.05rem] leading-none text-capy-cocoa">Profile</h1>
          <p className="mt-2 text-sm font-semibold text-capy-brown/75">Everything personal, playful, and secure.</p>
        </div>
        <button className="flex h-11 w-11 items-center justify-center rounded-2xl bg-white/80 text-capy-cocoa shadow-sm">
          <Icon name="settings" className="h-5 w-5" />
        </button>
      </header>

      <SectionCard className="animate-rise overflow-hidden bg-gradient-to-br from-white to-capy-vanilla" style={{ animationDelay: "80ms" }}>
        <div className="flex flex-col items-center text-center">
          <div className="relative rounded-full bg-gradient-to-br from-capy-peach to-capy-vanilla p-4 shadow-sm">
            <CapybaraMascot className="h-24 w-24" mood="calm" accessory="coin" />
            <span className="absolute right-3 top-3 h-4 w-4 rounded-full bg-capy-moss ring-4 ring-white" />
          </div>
          <h2 className="mt-4 font-display text-3xl leading-none text-capy-cocoa">{user.name}</h2>
          <p className="mt-1 text-sm font-bold text-capy-brown/70">{user.username}</p>
          <div className="mt-5 grid w-full grid-cols-3 gap-2">
            <div className="rounded-2xl bg-capy-cream p-3">
              <p className="text-xs font-black uppercase tracking-[0.2em] text-capy-brown/50">Streak</p>
              <p className="mt-1 text-sm font-black text-capy-cocoa">{user.streak}</p>
            </div>
            <div className="rounded-2xl bg-capy-cream p-3">
              <p className="text-xs font-black uppercase tracking-[0.2em] text-capy-brown/50">Goals</p>
              <p className="mt-1 text-sm font-black text-capy-cocoa">3 active</p>
            </div>
            <div className="rounded-2xl bg-capy-cream p-3">
              <p className="text-xs font-black uppercase tracking-[0.2em] text-capy-brown/50">Cards</p>
              <p className="mt-1 text-sm font-black text-capy-cocoa">2 live</p>
            </div>
          </div>
        </div>
      </SectionCard>

      <section className="animate-rise space-y-3" style={{ animationDelay: "150ms" }}>
        {profileMenu.map((item) => (
          <ProfileMenuItem key={item.id} item={item} />
        ))}
      </section>

      <button className="animate-rise flex w-full items-center justify-center gap-2 rounded-[28px] bg-capy-cocoa px-4 py-4 text-sm font-black text-white shadow-sm transition duration-200 hover:-translate-y-0.5" style={{ animationDelay: "220ms" }}>
        <Icon name="logout" className="h-5 w-5" />
        Logout
      </button>
    </div>
  );
}

import { CapybaraMascot } from "../components/CapybaraMascot";
import { Icon } from "../components/Icons";
import { SavingsGoalCard } from "../components/SavingsGoalCard";
import { SectionCard } from "../components/SectionCard";

export function SavingsScreen({ user, savingGoals }) {
  return (
    <div className="space-y-5 pb-6 pt-3">
      <header className="animate-rise flex items-start justify-between">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.3em] text-capy-brown/55">Save gently</p>
          <h1 className="font-display text-[2.05rem] leading-none text-capy-cocoa">Savings</h1>
          <p className="mt-2 text-sm font-semibold text-capy-brown/75">Each tiny deposit makes the capy smile bigger.</p>
        </div>
        <button className="flex h-11 w-11 items-center justify-center rounded-2xl bg-white/80 text-capy-cocoa shadow-sm">
          <Icon name="trend" className="h-5 w-5" />
        </button>
      </header>

      <SectionCard className="animate-rise overflow-hidden bg-gradient-to-br from-capy-sage via-white to-capy-peach/50" style={{ animationDelay: "80ms" }}>
        <div className="flex items-center gap-4">
          <div className="min-w-0 flex-1">
            <p className="text-sm font-bold text-capy-brown/70">Saved this month</p>
            <h2 className="mt-1 font-display text-4xl leading-none text-capy-cocoa">{user.savedThisMonth}</h2>
            <p className="mt-3 text-sm font-bold text-capy-brown/80">You are ahead of your cozy plan and your emergency fund is getting fluffier.</p>
            <div className="mt-4 inline-flex rounded-full bg-white/80 px-3 py-1 text-xs font-black text-capy-moss shadow-sm">
              +18% vs last month
            </div>
          </div>
          <div className="animate-capy-float rounded-[30px] bg-white/65 p-2 shadow-sm">
            <CapybaraMascot className="h-24 w-24" mood="happy" accessory="leaf" />
          </div>
        </div>
      </SectionCard>

      <section className="animate-rise space-y-3" style={{ animationDelay: "150ms" }}>
        <div className="flex items-center justify-between">
          <h2 className="text-lg font-black text-capy-cocoa">Saving goals</h2>
          <button className="text-sm font-black text-capy-brown/65">Manage</button>
        </div>
        <div className="space-y-3">
          {savingGoals.map((goal) => (
            <SavingsGoalCard key={goal.id} goal={goal} />
          ))}
        </div>
      </section>

      <SectionCard className="animate-rise bg-gradient-to-br from-capy-peach/50 to-capy-vanilla" style={{ animationDelay: "220ms" }}>
        <div className="flex items-start gap-3">
          <span className="flex h-12 w-12 items-center justify-center rounded-2xl bg-white/75 text-capy-cocoa shadow-sm">
            <Icon name="sparkles" className="h-5 w-5" />
          </span>
          <div>
            <h3 className="text-base font-black text-capy-cocoa">Capy tip</h3>
            <p className="mt-1 text-sm font-semibold text-capy-brown/75">
              Move a tiny amount every morning and let the happy capy celebrate the streak for you.
            </p>
          </div>
        </div>
      </SectionCard>
    </div>
  );
}

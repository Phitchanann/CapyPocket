import { SectionCard } from "./SectionCard";

export function SavingsGoalCard({ goal }) {
  const progress = Math.round((goal.current / goal.target) * 100);

  return (
    <SectionCard className="space-y-4">
      <div className="flex items-start justify-between gap-3">
        <div>
          <h3 className="text-base font-black text-capy-cocoa">{goal.title}</h3>
          <p className="text-sm font-semibold text-capy-brown/70">{goal.note}</p>
        </div>
        <div className="rounded-full bg-capy-peach/45 px-3 py-1 text-xs font-black text-capy-brown">
          {progress}%
        </div>
      </div>

      <div className="h-3 overflow-hidden rounded-full bg-capy-cream">
        <div
          className="progress-shimmer h-full rounded-full bg-gradient-to-r from-capy-orange via-capy-peach to-capy-orange"
          style={{ width: `${progress}%` }}
        />
      </div>

      <div className="flex items-center justify-between text-sm font-bold text-capy-brown/80">
        <span>{goal.amountLabel}</span>
        <span>{goal.target - goal.current} left</span>
      </div>
    </SectionCard>
  );
}

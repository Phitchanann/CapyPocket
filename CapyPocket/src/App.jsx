import { useMemo, useState } from "react";
import { PhoneShell } from "./components/PhoneShell";
import { SectionCard } from "./components/SectionCard";
import { profileMenu, quickActions, savingGoals, transactions, user, walletCards } from "./data/mockData";
import { HomeScreen } from "./screens/HomeScreen";
import { ProfileScreen } from "./screens/ProfileScreen";
import { SavingsScreen } from "./screens/SavingsScreen";
import { WalletScreen } from "./screens/WalletScreen";

function DesktopOverview({ activeTab }) {
  const activeLabel = activeTab.charAt(0).toUpperCase() + activeTab.slice(1);

  return (
    <div className="hidden max-w-md flex-1 lg:block">
      <div className="animate-rise space-y-6">
        <div>
          <p className="inline-flex rounded-full border border-white/70 bg-white/80 px-4 py-2 text-xs font-black uppercase tracking-[0.3em] text-capy-brown shadow-sm">
            Cute wallet UI
          </p>
          <h1 className="mt-5 font-display text-6xl leading-[0.9] text-capy-cocoa">CapyPocket</h1>
          <p className="mt-4 max-w-sm text-lg font-semibold text-capy-brown/80">
            A pastel capybara finance app with soft cards, tiny joyful motions, and reusable React components.
          </p>
        </div>

        <SectionCard className="bg-white/80">
          <p className="text-xs font-black uppercase tracking-[0.3em] text-capy-brown/50">Active screen</p>
          <div className="mt-3 flex items-end justify-between gap-4">
            <div>
              <h2 className="font-display text-4xl leading-none text-capy-cocoa">{activeLabel}</h2>
              <p className="mt-2 text-sm font-semibold text-capy-brown/75">
                Home, Wallet, Savings, and Profile all live inside one mobile shell.
              </p>
            </div>
            <div className="rounded-[24px] bg-capy-cream px-4 py-3 text-right shadow-sm">
              <p className="text-xs font-black uppercase tracking-[0.22em] text-capy-brown/50">Theme</p>
              <p className="mt-1 text-sm font-black text-capy-cocoa">Beige, brown, pastel orange</p>
            </div>
          </div>
        </SectionCard>

        <SectionCard className="bg-gradient-to-br from-capy-vanilla to-white">
          <p className="text-xs font-black uppercase tracking-[0.3em] text-capy-brown/50">Reusable pieces</p>
          <div className="mt-4 grid grid-cols-2 gap-3 text-sm font-bold text-capy-cocoa">
            <div className="rounded-2xl bg-white/75 p-3 shadow-sm">Phone shell</div>
            <div className="rounded-2xl bg-white/75 p-3 shadow-sm">Section cards</div>
            <div className="rounded-2xl bg-white/75 p-3 shadow-sm">Wallet cards</div>
            <div className="rounded-2xl bg-white/75 p-3 shadow-sm">Goal progress rows</div>
            <div className="rounded-2xl bg-white/75 p-3 shadow-sm">Profile menu items</div>
            <div className="rounded-2xl bg-white/75 p-3 shadow-sm">Capy mascot SVG</div>
          </div>
        </SectionCard>
      </div>
    </div>
  );
}

export default function App() {
  const [activeTab, setActiveTab] = useState("home");

  const screen = useMemo(() => {
    if (activeTab === "wallet") {
      return <WalletScreen user={user} walletCards={walletCards} />;
    }

    if (activeTab === "savings") {
      return <SavingsScreen user={user} savingGoals={savingGoals} />;
    }

    if (activeTab === "profile") {
      return <ProfileScreen user={user} profileMenu={profileMenu} />;
    }

    return <HomeScreen user={user} quickActions={quickActions} transactions={transactions} />;
  }, [activeTab]);

  return (
    <div className="relative min-h-screen overflow-hidden">
      <div className="absolute left-[-8rem] top-10 h-64 w-64 rounded-full bg-capy-peach/50 blur-3xl" />
      <div className="absolute bottom-10 right-[-7rem] h-72 w-72 rounded-full bg-capy-sage/50 blur-3xl" />
      <div className="relative mx-auto flex min-h-screen max-w-6xl items-center justify-center gap-10 px-0 sm:px-6 lg:px-8">
        <DesktopOverview activeTab={activeTab} />
        <PhoneShell activeTab={activeTab} onTabChange={setActiveTab}>
          {screen}
        </PhoneShell>
      </div>
    </div>
  );
}

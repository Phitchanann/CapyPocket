export const user = {
  name: "Mochi",
  username: "@mochi.pocket",
  balance: "$46,290.00",
  pocketCash: "$1,260.00",
  savings: "$8,540.00",
  monthChange: "+12.8%",
  savedThisMonth: "$2,450",
  streak: "18 days",
};

export const quickActions = [
  { id: "send", label: "Send", icon: "send", accent: "from-capy-peach to-capy-apricot/70" },
  { id: "receive", label: "Receive", icon: "receive", accent: "from-capy-sage to-capy-moss/30" },
  { id: "save", label: "Save", icon: "piggy", accent: "from-capy-vanilla to-capy-peach/60" },
  { id: "history", label: "History", icon: "history", accent: "from-capy-mist to-white" },
];

export const transactions = [
  {
    id: 1,
    title: "Capy Cafe Brunch",
    subtitle: "Today, 8:45 AM",
    amount: "-$24.50",
    positive: false,
    icon: "sparkles",
    tone: "bg-capy-peach/45 text-capy-cocoa",
  },
  {
    id: 2,
    title: "Savings Auto-Pocket",
    subtitle: "Today, 7:00 AM",
    amount: "+$120.00",
    positive: true,
    icon: "piggy",
    tone: "bg-capy-sage/65 text-capy-moss",
  },
  {
    id: 3,
    title: "Freelance Payout",
    subtitle: "Yesterday",
    amount: "+$840.00",
    positive: true,
    icon: "wallet",
    tone: "bg-capy-mist text-capy-cocoa",
  },
  {
    id: 4,
    title: "Book Nook",
    subtitle: "Mar 26",
    amount: "-$18.90",
    positive: false,
    icon: "card",
    tone: "bg-capy-rose/70 text-capy-cocoa",
  },
];

export const walletCards = [
  {
    id: 1,
    name: "Capy Everyday",
    number: "5412  8421  2901  4812",
    expires: "08/28",
    amount: "$18,240.00",
    network: "VISA",
    gradient: "from-capy-cocoa via-capy-brown to-capy-orange",
  },
  {
    id: 2,
    name: "Sunny Savings",
    number: "4829  1140  7503  2251",
    expires: "11/29",
    amount: "$9,680.00",
    network: "MASTERCARD",
    gradient: "from-capy-peach via-capy-apricot to-capy-orange",
  },
];

export const savingGoals = [
  {
    id: 1,
    title: "Rainy Day Pocket",
    current: 3200,
    target: 5000,
    amountLabel: "$3,200 / $5,000",
    note: "Cozy emergency buffer",
  },
  {
    id: 2,
    title: "Kyoto Capy Trip",
    current: 4800,
    target: 7000,
    amountLabel: "$4,800 / $7,000",
    note: "Flights and snack fund",
  },
  {
    id: 3,
    title: "Dream Desk Makeover",
    current: 1100,
    target: 2400,
    amountLabel: "$1,100 / $2,400",
    note: "Lamp, chair, soft lighting",
  },
];

export const profileMenu = [
  { id: 1, label: "Personal Details", hint: "Name, email, phone", icon: "user" },
  { id: 2, label: "Notifications", hint: "Reminders and alerts", icon: "bell" },
  { id: 3, label: "Security", hint: "Face ID and passcode", icon: "shield" },
  { id: 4, label: "Help Center", hint: "FAQ and support", icon: "help" },
];

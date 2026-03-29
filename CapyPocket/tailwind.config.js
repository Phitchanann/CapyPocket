/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{js,jsx}"],
  theme: {
    extend: {
      colors: {
        capy: {
          cream: "#fcf8f2",
          vanilla: "#f3e7d9",
          peach: "#f7d7b5",
          apricot: "#f0be8d",
          orange: "#e2a468",
          brown: "#b78554",
          cocoa: "#6a4a39",
          sage: "#dbe8cf",
          moss: "#7d9f71",
          mist: "#e9eef5",
          rose: "#f0d8d2",
          gold: "#f3cb77"
        }
      },
      fontFamily: {
        display: ['"Baloo 2"', "cursive"],
        body: ["Nunito", "sans-serif"],
      },
      boxShadow: {
        soft: "0 24px 50px rgba(134, 97, 69, 0.12)",
      },
      backgroundImage: {
        "capy-glow": "radial-gradient(circle at top, rgba(247, 215, 181, 0.95), rgba(252, 248, 242, 0))",
      },
    },
  },
  plugins: [],
};

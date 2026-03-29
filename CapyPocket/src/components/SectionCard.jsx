export function SectionCard({ children, className = "", ...props }) {
  return (
    <div
      className={`rounded-[28px] border border-white/70 bg-white/90 p-4 shadow-sm backdrop-blur ${className}`}
      {...props}
    >
      {children}
    </div>
  );
}

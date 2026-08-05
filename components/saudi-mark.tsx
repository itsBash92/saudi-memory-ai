import Image from "next/image";

export function SaudiMark() {
  return (
    <span className="brand" aria-label="Saudi Memory AI">
      <span className="brand-mark" aria-hidden="true">
        <Image className="brand-image" src="/brand-logo.png" alt="" width={48} height={48} priority />
      </span>
      <span className="brand-copy">
        <strong>Saudi Memory AI</strong>
        <small>Every place holds a memory</small>
      </span>
    </span>
  );
}

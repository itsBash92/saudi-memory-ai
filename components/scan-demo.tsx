"use client";

import { useEffect, useRef, useState } from "react";

type ScanStage = "idle" | "scanning" | "found";

export function ScanDemo() {
  const [stage, setStage] = useState<ScanStage>("idle");
  const scanTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    return () => {
      if (scanTimer.current) clearTimeout(scanTimer.current);
    };
  }, []);

  function startScan() {
    if (scanTimer.current) clearTimeout(scanTimer.current);
    setStage("scanning");
    scanTimer.current = setTimeout(() => setStage("found"), 1400);
  }

  function resetScan() {
    if (scanTimer.current) clearTimeout(scanTimer.current);
    setStage("idle");
  }

  return (
    <div className="scan-shell">
      <div className="phone-top" aria-hidden="true">
        <span>9:41</span>
        <span className="phone-island" />
        <span>● ●</span>
      </div>

      <div className={`scan-view scan-view-${stage}`}>
        <div className="masmak-scene" aria-hidden="true">
          <div className="sky-orb" />
          <div className="fort fort-left"><span /></div>
          <div className="fort fort-main">
            <span className="fort-door" />
            <span className="fort-window fort-window-one" />
            <span className="fort-window fort-window-two" />
          </div>
          <div className="fort fort-right"><span /></div>
          <div className="ground-line" />
        </div>

        {stage !== "found" && (
          <div className="scan-reticle" aria-hidden="true">
            <i /><i /><i /><i />
            {stage === "scanning" && <span className="scan-beam" />}
          </div>
        )}

        {stage === "idle" && (
          <div className="scan-instruction">
            <span className="eyebrow light">AI camera demo</span>
            <h3>Point the camera at a landmark</h3>
            <p>This safe prototype simulation does not access your camera.</p>
          </div>
        )}

        {stage === "scanning" && (
          <div className="scan-status" role="status">
            <span className="status-pulse" />
            Identifying the place and retrieving evidence…
          </div>
        )}

        {stage === "found" && (
          <div className="place-result" aria-live="polite">
            <div className="result-head">
              <span className="confidence">97% confidence</span>
              <button type="button" className="icon-button" onClick={resetScan} aria-label="Restart the demo">
                ↻
              </button>
            </div>
            <span className="result-kicker">Place identified</span>
            <h3>Al Masmak Palace</h3>
            <p>
              A clay and mud-brick fortress in the heart of Riyadh, closely tied to
              defining moments in the unification of Saudi Arabia.
            </p>
            <div className="result-meta">
              <span>Riyadh</span>
              <span>128 memories</span>
              <span>3 sources</span>
            </div>
            <button type="button" className="text-action">Explore the full story →</button>
          </div>
        )}
      </div>

      <div className="camera-controls">
        <button
          type="button"
          className="gallery-button"
          aria-label="Choose an image — available in a future release"
          title="Available in a future release"
        >
          ▧
        </button>
        <button
          type="button"
          className={`shutter-button ${stage === "scanning" ? "is-scanning" : ""}`}
          onClick={startScan}
          disabled={stage === "scanning"}
          aria-label="Start the place recognition demo"
        >
          <span />
        </button>
        <span className="ai-chip">AI</span>
      </div>
    </div>
  );
}

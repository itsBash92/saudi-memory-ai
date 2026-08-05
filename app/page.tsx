import { MemoryExplorer } from "@/components/memory-explorer";
import { SaudiMark } from "@/components/saudi-mark";
import { ScanDemo } from "@/components/scan-demo";

const features = [
  {
    number: "01",
    title: "Responsible visual recognition",
    text: "Capture a landmark and receive evidence-backed place candidates with confidence scores—without facial recognition.",
    label: "See the place",
  },
  {
    number: "02",
    title: "Stories grounded in evidence",
    text: "A clear narrative connects verified facts, timelines, images, and personal accounts while labeling each content type.",
    label: "Understand the story",
  },
  {
    number: "03",
    title: "Memory written by its people",
    text: "Add a photo, a story, an approximate date, or a source, then follow its review status as it joins the place's record.",
    label: "Add your memory",
  },
  {
    number: "04",
    title: "Recognition that matters",
    text: "Earn points and badges for trustworthy contributions, with a path to partner rewards after anti-fraud safeguards are ready.",
    label: "Preserve the impact",
  },
];

const trustSignals = [
  ["Visible sources", "Every factual claim is traceable"],
  ["Privacy by design", "Sensitive image metadata is removed"],
  ["Explainable confidence", "Clear scores and review states"],
  ["Multiple perspectives", "Places are told through local voices"],
];

export default function Home() {
  return (
    <div className="site-shell">
      <header className="site-header">
        <div className="container header-inner">
          <a className="brand-link" href="#top" aria-label="Back to the top">
            <SaudiMark />
          </a>
          <nav className="main-nav" aria-label="Primary navigation">
            <a href="#story">The idea</a>
            <a href="#demo">Try it</a>
            <a href="#memories">Memories</a>
            <a href="#trust">Trust</a>
          </nav>
          <a className="header-cta" href="#contribute">Contribute a memory</a>
        </div>
      </header>

      <main id="top">
        <section className="hero">
          <div className="hero-pattern" aria-hidden="true" />
          <div className="container hero-grid">
            <div className="hero-copy">
              <div className="hero-pill">
                <span />
                A Saudi platform preserving places through local voices
              </div>
              <h1>
                Every place
                <br />
                holds a <em>memory.</em>
              </h1>
              <p className="hero-lead">
                Capture a landmark, discover its story, and explore the memories connected
                to it. If you have an old photo or personal account, help it live on for
                future generations.
              </p>
              <div className="hero-actions">
                <a className="button button-gold" href="#demo">
                  <span className="button-icon" aria-hidden="true">◎</span>
                  Try place recognition
                </a>
                <a className="button button-ghost" href="#story">Discover the idea</a>
              </div>
              <div className="hero-proof" aria-label="Prototype principles">
                <span><i>✓</i> Saudi-first context</span>
                <span><i>✓</i> Traceable sources</span>
                <span><i>✓</i> Privacy by design</span>
              </div>
            </div>

            <div className="hero-art" aria-label="A visual concept of memories connected to Saudi places">
              <div className="sun-disc" />
              <div className="memory-orbit orbit-one"><span>Photo</span></div>
              <div className="memory-orbit orbit-two"><span>Story</span></div>
              <div className="memory-orbit orbit-three"><span>Place</span></div>
              <div className="hero-arch">
                <div className="arch-crown" />
                <div className="arch-door">
                  <div className="desert-layer desert-back" />
                  <div className="desert-layer desert-front" />
                  <div className="palm"><i /><b /><b /><b /><b /></div>
                  <div className="old-city"><i /><i /><i /><i /><i /></div>
                </div>
              </div>
              <div className="floating-memory">
                <span className="avatar">K</span>
                <div>
                  <small>Illustrative memory · 1987</small>
                  <strong>“My father used to tell us…”</strong>
                </div>
              </div>
            </div>
          </div>

          <div className="container hero-stats">
            <div><strong>13</strong><span>regions in the national vision</span></div>
            <div><strong>1</strong><span>shared memory that connects us</span></div>
            <div><strong>∞</strong><span>stories worth preserving</span></div>
          </div>
        </section>

        <section className="story-section section" id="story">
          <div className="container">
            <div className="section-heading split-heading">
              <div>
                <span className="eyebrow">The core idea</span>
                <h2>From a passing image<br />to a living memory.</h2>
              </div>
              <p>
                Information tells us what happened. Memory tells us what a place felt
                like. Saudi Memory AI brings both together in one experience that is
                accessible, transparent, and grounded in evidence.
              </p>
            </div>

            <div className="feature-grid">
              {features.map((feature) => (
                <article className="feature-card" key={feature.number}>
                  <div className="feature-number">{feature.number}</div>
                  <div className="feature-icon" aria-hidden="true">
                    <span>{feature.number === "01" ? "⌾" : feature.number === "02" ? "≋" : feature.number === "03" ? "+" : "✦"}</span>
                  </div>
                  <h3>{feature.title}</h3>
                  <p>{feature.text}</p>
                  <span className="feature-label">{feature.label} →</span>
                </article>
              ))}
            </div>
          </div>
        </section>

        <section className="demo-section section" id="demo">
          <div className="container demo-grid">
            <div className="demo-copy">
              <span className="eyebrow light">Interactive prototype</span>
              <h2>Let the place<br />tell its story.</h2>
              <p>
                Press the camera button in the prototype to see how a landmark image
                becomes an understandable result with a place name, confidence score,
                story, sources, and community memories.
              </p>
              <ol className="demo-steps">
                <li><span>1</span><div><strong>Capture</strong><small>Take a photo of a place or landmark</small></div></li>
                <li><span>2</span><div><strong>Identify</strong><small>Review candidates backed by context and sources</small></div></li>
                <li><span>3</span><div><strong>Discover</strong><small>Explore its story, timeline, and local memories</small></div></li>
              </ol>
              <div className="privacy-note">
                <span aria-hidden="true">◈</span>
                <p><strong>Privacy is part of the architecture.</strong> The production pipeline removes sensitive EXIF metadata before image processing.</p>
              </div>
            </div>
            <div className="demo-device-wrap">
              <ScanDemo />
            </div>
          </div>
        </section>

        <section className="memory-section section" id="memories">
          <div className="container">
            <div className="section-heading centered-heading">
              <span className="eyebrow">Memory previews</span>
              <h2>Saudi Arabia, told<br />through its people.</h2>
              <p>Illustrative data shows the intended experience before real archives and community contributions are connected.</p>
            </div>
            <MemoryExplorer />
          </div>
        </section>

        <section className="trust-section section" id="trust">
          <div className="container trust-grid">
            <div className="trust-copy">
              <span className="eyebrow">Trust before scale</span>
              <h2>AI that makes<br />uncertainty visible.</h2>
              <p>
                When the system is not certain, it says so. Personal accounts remain
                distinct from historical facts, helping us preserve memory without
                manufacturing history.
              </p>
              <a href="https://github.com/itsBash92/saudi-memory-ai" className="inline-link">Explore the methodology on GitHub →</a>
            </div>
            <div className="trust-board">
              <div className="confidence-ring" aria-label="Illustrative confidence score of 97 percent">
                <div><strong>97%</strong><span>illustrative score</span></div>
              </div>
              <div className="trust-list">
                {trustSignals.map(([title, text]) => (
                  <div key={title}>
                    <span>✓</span>
                    <p><strong>{title}</strong><small>{text}</small></p>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </section>

        <section className="contribute-section" id="contribute">
          <div className="container contribute-card">
            <div className="contribute-pattern" aria-hidden="true" />
            <div className="contribute-copy">
              <span className="eyebrow light">Memory starts with you</span>
              <h2>Have an old photo<br />with a story behind it?</h2>
              <p>
                Soon, you will be able to connect it to a place, add an approximate date,
                preserve its story, and choose whether to publish under your name or anonymously.
              </p>
              <a className="button button-gold" href="https://github.com/itsBash92/saudi-memory-ai/issues/new/choose">
                Register your interest
              </a>
            </div>
            <div className="contribution-ticket" aria-hidden="true">
              <div className="ticket-image"><span>1968</span></div>
              <div className="ticket-copy">
                <small>New memory</small>
                <strong>From the family album</strong>
                <span>Waiting for your story…</span>
              </div>
              <div className="ticket-stamp">Memory<br />Keeper</div>
            </div>
          </div>
        </section>
      </main>

      <footer className="site-footer">
        <div className="container footer-grid">
          <SaudiMark />
          <p>An intelligent platform preserving the memories of Saudi places through AI and responsible community contributions.</p>
          <nav aria-label="Footer links">
            <a href="#story">About</a>
            <a href="#trust">Privacy</a>
            <a href="https://github.com/itsBash92/saudi-memory-ai">GitHub</a>
          </nav>
        </div>
        <div className="container footer-bottom">
          <span>© 2026 Saudi Memory AI</span>
          <span>Built with care for Saudi Arabia&apos;s living memory</span>
        </div>
      </footer>
    </div>
  );
}

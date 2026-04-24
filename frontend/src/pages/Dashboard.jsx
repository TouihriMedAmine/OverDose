import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { apiFetch } from "../api.js";
import { useAuth } from "../context/AuthContext.jsx";

function diseaseIdsFromCsv(csv, conditions) {
  if (!csv || !conditions?.length) return [];
  const labels = new Set(
    csv
      .split(",")
      .map((s) => s.trim().toLowerCase())
      .filter(Boolean)
  );
  return conditions.filter((c) => labels.has(String(c.label).toLowerCase())).map((c) => c.id);
}

function recordProductClick(title) {
  if (!title) return;
  apiFetch("/api/learning/click/", {
    method: "POST",
    body: { title },
  }).catch(() => {});
}

function escapeHtml(s) {
  const div = document.createElement("div");
  div.textContent = s ?? "";
  return div.innerHTML;
}

function escapeAttr(s) {
  return String(s ?? "")
    .replace(/&/g, "&amp;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
}

/** Match mobile mock: LOW / MODERATE / HIGH + icon */
function toxicityMock(label) {
  const l = String(label || "").toLowerCase();
  if (l === "low") return { text: "LOW", cls: "tox-mock-low", sym: "🌿" };
  if (l === "high") return { text: "HIGH", cls: "tox-mock-high", sym: "⛔" };
  return { text: "MODERATE", cls: "tox-mock-mod", sym: "⚠️" };
}

export default function Dashboard() {
  const { user, logout, loadMe } = useAuth();
  const [q, setQ] = useState("");
  const [category, setCategory] = useState("auto");
  const [fallback, setFallback] = useState(true);
  const [useLoyalty, setUseLoyalty] = useState(true);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [data, setData] = useState(null);

  const [healthConditions, setHealthConditions] = useState([]);
  const [profileEmail, setProfileEmail] = useState("");
  const [profileDob, setProfileDob] = useState("");
  const [profileGender, setProfileGender] = useState("");
  const [profileSelected, setProfileSelected] = useState([]);
  const [profileSaving, setProfileSaving] = useState(false);
  const [profileError, setProfileError] = useState("");

  useEffect(() => {
    fetch("/health-conditions.json")
      .then((r) => r.json())
      .then((d) => setHealthConditions(Array.isArray(d?.conditions) ? d.conditions : []))
      .catch(() => {});
  }, []);

  useEffect(() => {
    if (!user) return;
    setProfileEmail(user.email || "");
    setProfileDob(user.date_of_birth ? String(user.date_of_birth).slice(0, 10) : "");
    setProfileGender(user.gender || "");
    setProfileSelected(diseaseIdsFromCsv(user.diseases, healthConditions));
  }, [user, healthConditions]);

  function toggleProfileCondition(id) {
    setProfileSelected((prev) =>
      prev.includes(id) ? prev.filter((x) => x !== id) : [...prev, id]
    );
  }

  function profileDiseasesCsv() {
    const byId = Object.fromEntries(healthConditions.map((c) => [c.id, c.label]));
    return profileSelected.map((id) => byId[id]).filter(Boolean).join(", ");
  }

  async function onSaveProfile(e) {
    e.preventDefault();
    setProfileError("");
    setProfileSaving(true);
    try {
      const res = await apiFetch("/api/auth/me/", {
        method: "PATCH",
        body: {
          email: profileEmail.trim(),
          date_of_birth: profileDob || null,
          gender: profileGender || null,
          diseases: profileDiseasesCsv(),
        },
      });
      const errJson = await res.json().catch(() => ({}));
      if (!res.ok) {
        throw new Error(
          typeof errJson === "object" && errJson && Object.keys(errJson).length
            ? JSON.stringify(errJson)
            : "Could not save profile"
        );
      }
      await loadMe();
    } catch (err) {
      setProfileError(err.message || "Save failed");
    } finally {
      setProfileSaving(false);
    }
  }

  async function onSearch(e) {
    e.preventDefault();
    const query = q.trim();
    if (!query) return;
    setError("");
    setLoading(true);
    setData(null);
    try {
      const res = await apiFetch("/api/search/", {
        method: "POST",
        body: { q: query, category, fallback, use_loyalty: useLoyalty },
      });
      const json = await res.json().catch(() => ({}));
      if (!res.ok) {
        throw new Error(json.error || "Search failed");
      }
      setData(json);
    } catch (err) {
      setError(err.message || "Search failed");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="layout">
      <div className="nav">
        <strong>Tunisia Product Search</strong>
        <div className="nav-links">
          <span className="subtitle" style={{ margin: 0 }}>
            {user?.username}
          </span>
          <button type="button" className="btn btn-ghost" onClick={logout}>
            Sign out
          </button>
        </div>
      </div>

      <div
        className="card"
        style={{ marginBottom: "1.5rem", background: "var(--surface2)", borderColor: "var(--border)" }}
      >
        <h1 style={{ fontSize: "1.1rem", marginBottom: "0.5rem" }}>Your profile</h1>
        <p className="subtitle" style={{ marginBottom: "0.75rem" }}>
          Signed in as <strong>{escapeHtml(user?.username || "")}</strong>
        </p>
        <form onSubmit={onSaveProfile}>
          <div className="field">
            <label htmlFor="pemail">Email</label>
            <input
              id="pemail"
              type="email"
              value={profileEmail}
              onChange={(e) => setProfileEmail(e.target.value)}
              required
            />
          </div>
          <div className="field">
            <label htmlFor="pdob">Date of birth</label>
            <input
              id="pdob"
              type="date"
              value={profileDob}
              onChange={(e) => setProfileDob(e.target.value)}
            />
          </div>
          <div className="field">
            <label htmlFor="pgen">Gender</label>
            <select id="pgen" value={profileGender} onChange={(e) => setProfileGender(e.target.value)}>
              <option value="">—</option>
              <option value="M">Male</option>
              <option value="F">Female</option>
            </select>
          </div>
          <div className="field" style={{ marginBottom: "0.5rem" }}>
            <span style={{ fontSize: "0.85rem", color: "var(--text-muted)" }}>Health notes (optional)</span>
            <div
              role="group"
              aria-label="Health conditions"
              style={{
                display: "flex",
                flexDirection: "row",
                flexWrap: "nowrap",
                gap: "0.5rem",
                overflowX: "auto",
                paddingTop: "0.5rem",
                paddingBottom: "0.25rem",
              }}
            >
              {healthConditions.map((c) => {
                const selected = profileSelected.includes(c.id);
                return (
                  <button
                    key={c.id}
                    type="button"
                    onClick={() => toggleProfileCondition(c.id)}
                    style={{
                      flex: "0 0 auto",
                      padding: "0.45rem 0.9rem",
                      borderRadius: "999px",
                      border: selected ? "2px solid #2e7d32" : "1px solid var(--border, #ccc)",
                      background: selected ? "#c8e6c9" : "var(--surface2, #f5f5f5)",
                      color: selected ? "#1b5e20" : "inherit",
                      fontWeight: selected ? 600 : 400,
                      cursor: "pointer",
                      fontSize: "0.9rem",
                      whiteSpace: "nowrap",
                    }}
                  >
                    {selected ? "✓ " : ""}
                    {c.label}
                  </button>
                );
              })}
            </div>
          </div>
          {profileError ? <div className="error" style={{ marginBottom: "0.75rem" }}>{profileError}</div> : null}
          <button className="btn" type="submit" disabled={profileSaving} style={{ marginBottom: "0.75rem" }}>
            {profileSaving ? "Saving…" : "Save profile"}
          </button>
        </form>
        <p style={{ fontSize: "0.8rem", color: "var(--text-muted)", marginTop: "0.5rem", marginBottom: 0 }}>
          Brand loyalty: we learn favorite brands from product clicks and can boost them in results.
        </p>
      </div>

      <div className="results-surface-mock">
        <h1 style={{ marginBottom: "0.35rem" }}>Search products in Tunisia</h1>
        <p className="subtitle" style={{ marginBottom: "1rem" }}>
          Results from Tunisian stores; toxicity is estimated from the product title.
        </p>

        <form onSubmit={onSearch}>
          <div className="search-pill-wrap">
            <span className="search-pill-icon" aria-hidden>
              🔍
            </span>
            <input
              className="search-pill-input"
              type="search"
              placeholder="Search products…"
              value={q}
              onChange={(e) => setQ(e.target.value)}
              autoComplete="off"
            />
            <button className="btn" type="submit" disabled={loading} style={{ borderRadius: "999px", padding: "0.45rem 1rem" }}>
              {loading ? "…" : "Go"}
            </button>
          </div>

          <details className="search-filters-details">
            <summary>Filters &amp; options</summary>
            <div className="field" style={{ marginTop: "0.75rem" }}>
              <label htmlFor="cat">Category</label>
              <select id="cat" value={category} onChange={(e) => setCategory(e.target.value)}>
                <option value="auto">Auto (from keywords)</option>
                <option value="all">All stores</option>
                <option value="food">Food & grocery</option>
                <option value="cosmetics">Cosmetics & beauty</option>
                <option value="pharmacy">Pharmacy & health</option>
                <option value="electronics">Electronics & appliances</option>
              </select>
            </div>
            <div className="field" style={{ display: "flex", alignItems: "center", gap: "0.5rem" }}>
              <input
                type="checkbox"
                id="fb"
                checked={fallback}
                onChange={(e) => setFallback(e.target.checked)}
                style={{ width: "auto" }}
              />
              <label htmlFor="fb" style={{ margin: 0 }}>
                Web search fallback
              </label>
            </div>
            <div className="field" style={{ display: "flex", alignItems: "center", gap: "0.5rem" }}>
              <input
                type="checkbox"
                id="loy"
                checked={useLoyalty}
                onChange={(e) => setUseLoyalty(e.target.checked)}
                style={{ width: "auto" }}
              />
              <label htmlFor="loy" style={{ margin: 0 }}>
                Boost brands I click often
              </label>
            </div>
          </details>
        </form>

        {error ? <div className="error">{escapeHtml(error)}</div> : null}

        {data?.brand_loyalty?.favorite_brands?.length ? (
          <div
            style={{
              marginBottom: "1rem",
              padding: "0.75rem 1rem",
              background: "#fff",
              borderRadius: "10px",
              fontSize: "0.88rem",
              border: "1px solid rgba(0,0,0,0.06)",
            }}
          >
            <strong style={{ color: "var(--text)" }}>Your top brands (learned)</strong>
            <div style={{ marginTop: "0.5rem", display: "flex", flexWrap: "wrap", gap: "0.4rem" }}>
              {data.brand_loyalty.favorite_brands.map((b, k) => (
                <span
                  key={k}
                  style={{
                    padding: "0.2rem 0.55rem",
                    background: "var(--accent-dim)",
                    borderRadius: "6px",
                    color: "var(--accent)",
                  }}
                >
                  {escapeHtml(b.brand)} ({typeof b.score === "number" ? b.score.toFixed(2) : b.score})
                </span>
              ))}
            </div>
          </div>
        ) : null}

        {data?.search_scope_note ? (
          <div className="summary" style={{ background: "rgba(255,255,255,0.7)", marginBottom: "0.75rem" }}>
            <strong>{escapeHtml(data.query || "")}</strong> — {escapeHtml(data.summary || "")}
            <div style={{ marginTop: "0.35rem" }}>
              Scope: <strong>{escapeHtml(data.search_scope_note)}</strong>
            </div>
            {data.scope_widened ? (
              <div
                style={{
                  marginTop: "0.5rem",
                  borderLeft: "3px solid #d29922",
                  paddingLeft: "0.75rem",
                }}
              >
                No hits in category scope — results may include all store types.
              </div>
            ) : null}
          </div>
        ) : null}

        {data?.products?.length ? (
          <div style={{ marginTop: "0.5rem" }}>
            {data.products.map((p, i) => {
              const url = p.url || "#";
              const tox = toxicityMock(p.toxicity_label);
              const brand = (p.brand_guess && String(p.brand_guess).trim()) || p.store_name || "—";
              return (
                <a
                  key={i}
                  href={url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="product-card-mock"
                  onClick={() => recordProductClick(p.title)}
                >
                  {p.image_url ? (
                    <img className="product-card-mock__thumb" src={escapeAttr(p.image_url)} alt="" loading="lazy" />
                  ) : (
                    <div className="product-card-mock__thumb" />
                  )}
                  <div className="product-card-mock__body">
                    <div className="product-card-mock__row1">
                      <span className="product-card-mock__title">{escapeHtml(p.title)}</span>
                      <span className="product-card-mock__price">{escapeHtml(p.price || "—")}</span>
                    </div>
                    <div className={`product-card-mock__tox ${tox.cls}`}>
                      <span className="product-card-mock__tox-icon" aria-hidden>
                        {tox.sym}
                      </span>
                      <span>Toxicity: {tox.text}</span>
                    </div>
                    <hr className="product-card-mock__divider" />
                    <div className="product-card-mock__brand">{escapeHtml(brand)}</div>
                  </div>
                </a>
              );
            })}
          </div>
        ) : null}

        {data && (!data.products || data.products.length === 0) && !loading ? (
          <p className="subtitle" style={{ marginTop: "1rem" }}>
            No products in this response. Try another query or category.
          </p>
        ) : null}

        {data?.search_links?.length ? (
          <div style={{ marginTop: "1.5rem", borderTop: "1px solid rgba(0,0,0,0.08)", paddingTop: "1rem" }}>
            <h2 style={{ fontSize: "1rem", color: "var(--text-muted)" }}>More links (Tunisia)</h2>
            {data.search_links.map((l, j) => (
              <div key={j} style={{ marginBottom: "0.5rem" }}>
                <a href={escapeAttr(l.url)} target="_blank" rel="noopener noreferrer">
                  {escapeHtml(l.title || l.url)}
                </a>
              </div>
            ))}
          </div>
        ) : null}
      </div>

      <p style={{ textAlign: "center", marginTop: "2rem", fontSize: "0.85rem", color: "var(--text-muted)" }}>
        Legacy Flask UI: <code>python app.py</code> ·{" "}
        <Link to="/register">New account</Link>
      </p>
    </div>
  );
}

import { useEffect, useState } from "react";
import { Link, Navigate, useNavigate } from "react-router-dom";
import { setTokens } from "../api.js";
import { useAuth } from "../context/AuthContext.jsx";

export default function Register() {
  const { user, loadMe } = useAuth();
  const navigate = useNavigate();
  const [form, setForm] = useState({
    username: "",
    email: "",
    password: "",
    password_confirm: "",
    date_of_birth: "",
    gender: "",
  });
  /** Selected condition ids from health-conditions.json (multi-select) */
  const [selectedConditions, setSelectedConditions] = useState([]);
  const [healthConditions, setHealthConditions] = useState([]);
  const [conditionsLoadError, setConditionsLoadError] = useState("");
  const [error, setError] = useState("");
  const [pending, setPending] = useState(false);

  useEffect(() => {
    fetch("/health-conditions.json")
      .then((r) => {
        if (!r.ok) throw new Error("Could not load health conditions");
        return r.json();
      })
      .then((data) => {
        const list = Array.isArray(data?.conditions) ? data.conditions : [];
        setHealthConditions(list);
      })
      .catch(() => {
        setConditionsLoadError("Could not load health conditions list.");
      });
  }, []);

  function toggleCondition(id) {
    setSelectedConditions((prev) =>
      prev.includes(id) ? prev.filter((x) => x !== id) : [...prev, id]
    );
  }

  function diseasesForSubmit() {
    const byId = Object.fromEntries(healthConditions.map((c) => [c.id, c.label]));
    return selectedConditions
      .map((id) => byId[id])
      .filter(Boolean)
      .join(", ");
  }

  function update(k, v) {
    setForm((f) => ({ ...f, [k]: v }));
  }

  if (user) {
    return <Navigate to="/" replace />;
  }

  async function onSubmit(e) {
    e.preventDefault();
    setError("");
    setPending(true);
    try {
      const body = {
        username: form.username.trim(),
        email: form.email.trim(),
        password: form.password,
        password_confirm: form.password_confirm,
        date_of_birth: form.date_of_birth || null,
        gender: form.gender || null,
        diseases: diseasesForSubmit(),
      };
      const res = await fetch("/api/auth/register/", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
      });
      const data = await res.json().catch(() => ({}));
      if (!res.ok) {
        const msg =
          typeof data === "object"
            ? Object.entries(data)
                .map(([k, v]) => `${k}: ${Array.isArray(v) ? v.join(", ") : v}`)
                .join(" ")
            : "Registration failed";
        throw new Error(msg || "Registration failed");
      }
      const loginRes = await fetch("/api/auth/login/", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          username: form.username.trim(),
          password: form.password,
        }),
      });
      const tokens = await loginRes.json();
      if (!loginRes.ok) {
        throw new Error("Account created. Please sign in manually.");
      }
      setTokens(tokens.access, tokens.refresh);
      await loadMe();
      navigate("/", { replace: true });
    } catch (err) {
      setError(err.message || "Could not register.");
    } finally {
      setPending(false);
    }
  }

  return (
    <div className="layout">
      <div className="nav">
        <strong>Tunisia Product Search</strong>
        <div className="nav-links">
          <Link to="/login">Sign in</Link>
        </div>
      </div>
      <div className="card" style={{ maxWidth: 480, margin: "0 auto" }}>
        <h1>Create account</h1>
        <p className="subtitle">Profile information is stored securely in the database.</p>
        {error ? <div className="error">{error}</div> : null}
        <form onSubmit={onSubmit}>
          <div className="field">
            <label htmlFor="username">Username</label>
            <input
              id="username"
              autoComplete="username"
              value={form.username}
              onChange={(e) => update("username", e.target.value)}
              required
            />
          </div>
          <div className="field">
            <label htmlFor="email">Email</label>
            <input
              id="email"
              type="email"
              autoComplete="email"
              value={form.email}
              onChange={(e) => update("email", e.target.value)}
              required
            />
          </div>
          <div className="field">
            <label htmlFor="dob">Date of birth</label>
            <input
              id="dob"
              type="date"
              value={form.date_of_birth}
              onChange={(e) => update("date_of_birth", e.target.value)}
            />
          </div>
          <div className="field">
            <label htmlFor="gender">Gender</label>
            <select id="gender" value={form.gender} onChange={(e) => update("gender", e.target.value)}>
              <option value="">—</option>
              <option value="M">Male</option>
              <option value="F">Female</option>
            </select>
          </div>
          <fieldset className="field" style={{ border: "none", padding: 0, margin: 0 }}>
            <legend style={{ marginBottom: "0.35rem", fontWeight: 600 }}>
              Health notes (optional)
            </legend>
            <p className="subtitle" style={{ marginTop: 0, marginBottom: "0.5rem" }}>
              Select any that apply — you can choose more than one.
            </p>
            {conditionsLoadError ? (
              <div className="error" style={{ marginBottom: "0.5rem" }}>
                {conditionsLoadError}
              </div>
            ) : null}
            <div
              role="group"
              aria-label="Health conditions"
              style={{
                display: "flex",
                flexDirection: "row",
                flexWrap: "nowrap",
                gap: "0.5rem",
                overflowX: "auto",
                paddingBottom: "0.35rem",
                WebkitOverflowScrolling: "touch",
                scrollbarWidth: "thin",
              }}
            >
              {healthConditions.map((c) => {
                const selected = selectedConditions.includes(c.id);
                return (
                  <button
                    key={c.id}
                    type="button"
                    onClick={() => toggleCondition(c.id)}
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
          </fieldset>
          <div className="field">
            <label htmlFor="password">Password</label>
            <input
              id="password"
              type="password"
              autoComplete="new-password"
              value={form.password}
              onChange={(e) => update("password", e.target.value)}
              required
              minLength={8}
            />
          </div>
          <div className="field">
            <label htmlFor="password_confirm">Confirm password</label>
            <input
              id="password_confirm"
              type="password"
              autoComplete="new-password"
              value={form.password_confirm}
              onChange={(e) => update("password_confirm", e.target.value)}
              required
            />
          </div>
          <button className="btn" type="submit" disabled={pending}>
            {pending ? "Creating account…" : "Register"}
          </button>
        </form>
      </div>
    </div>
  );
}

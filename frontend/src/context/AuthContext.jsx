import React, { createContext, useContext, useEffect, useState } from "react";
import { apiFetch, clearTokens, getAccessToken, setTokens } from "../api.js";

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  async function loadMe() {
    if (!getAccessToken()) {
      setUser(null);
      setLoading(false);
      return;
    }
    const res = await apiFetch("/api/auth/me/");
    if (!res.ok) {
      clearTokens();
      setUser(null);
      setLoading(false);
      return;
    }
    setUser(await res.json());
    setLoading(false);
  }

  useEffect(() => {
    loadMe();
  }, []);

  async function login(username, password) {
    const res = await fetch("/api/auth/login/", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ username, password }),
    });
    const data = await res.json().catch(() => ({}));
    if (!res.ok) {
      throw new Error(data.detail || data.message || "Login failed");
    }
    setTokens(data.access, data.refresh);
    await loadMe();
  }

  function logout() {
    clearTokens();
    setUser(null);
  }

  return (
    <AuthContext.Provider value={{ user, loading, login, logout, loadMe }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth outside AuthProvider");
  return ctx;
}

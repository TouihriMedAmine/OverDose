const ACCESS = "access_token";
const REFRESH = "refresh_token";

export function getAccessToken() {
  return localStorage.getItem(ACCESS);
}

export function setTokens(access, refresh) {
  localStorage.setItem(ACCESS, access);
  localStorage.setItem(REFRESH, refresh);
}

export function clearTokens() {
  localStorage.removeItem(ACCESS);
  localStorage.removeItem(REFRESH);
}

async function refreshAccess() {
  const r = localStorage.getItem(REFRESH);
  if (!r) return null;
  const res = await fetch("/api/auth/token/refresh/", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ refresh: r }),
  });
  if (!res.ok) return null;
  const data = await res.json();
  localStorage.setItem(ACCESS, data.access);
  return data.access;
}

export async function apiFetch(path, options = {}) {
  const headers = { ...options.headers };
  let token = getAccessToken();
  if (token) {
    headers.Authorization = `Bearer ${token}`;
  }
  if (options.body && typeof options.body === "object" && !(options.body instanceof FormData)) {
    headers["Content-Type"] = "application/json";
    options.body = JSON.stringify(options.body);
  }

  let res = await fetch(path, { ...options, headers });

  if (res.status === 401 && getAccessToken()) {
    const newAccess = await refreshAccess();
    if (newAccess) {
      headers.Authorization = `Bearer ${newAccess}`;
      res = await fetch(path, { ...options, headers });
    }
  }

  return res;
}

import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import "./index.css";
import App from "./App";

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <App />
  </StrictMode>
);

// Offline support for the installed (home-screen) app. Skipped for file:// (the local launcher) and the dev server.
if ("serviceWorker" in navigator && import.meta.env.PROD && location.protocol !== "file:") {
  window.addEventListener("load", () => { navigator.serviceWorker.register("./sw.js").catch(() => {}); });
}

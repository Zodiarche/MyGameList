import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    // Écoute sur toutes les interfaces pour accès depuis Docker
    host: "0.0.0.0",

    // Port par défaut de Vite
    port: 5173,

    // Active strictement le HMR (Hot Module Replacement)
    hmr: {
      // Configuration HMR pour Docker
      clientPort: 5173,
    },

    // Watch des fichiers avec polling pour compatibilité Docker
    watch: {
      usePolling: true,
      interval: 1000,
    },
  },
});

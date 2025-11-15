import { Application } from "express";

import apiRoutes from "./api/index";

import healthRoutes from "./health.js";

/**
 * Configure toutes les routes de l'application
 * @param app - Instance Express
 */
export const setupRoutes = (app: Application): void => {
  // Routes de santé du serveur
  app.use("/health", healthRoutes);

  // Routes de l'API principale
  app.use("/api", apiRoutes);

  // Route de base
  app.get("/", (req, res) => {
    res.json({
      message: "Bienvenue sur l'API MyGameList!",
      version: "1.0.0",
      status: "ok",
      endpoints: {
        health: "/health",
        api: "/api",
      },
    });
  });
};

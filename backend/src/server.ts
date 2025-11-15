import cors from "cors";
import express, { Application, NextFunction, Request, Response } from "express";
import helmet from "helmet";
import morgan from "morgan";
import { setupRoutes } from "./routes";

const app: Application = express();
const PORT = process.env.PORT || 3001;

// Middlewares de sécurité et utilitaires
app.use(helmet());
app.use(cors());
app.use(morgan("combined"));

// Middleware pour parser le JSON
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Configuration des routes
setupRoutes(app);

// Middleware de gestion des erreurs 404
app.use("*", (req: Request, res: Response) => {
  res.status(404).json({
    error: "Route non trouvée",
    path: req.originalUrl,
  });
});

// Middleware de gestion des erreurs globales
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  console.error(err.stack);
  res.status(500).json({
    error: "Erreur interne du serveur",
    message:
      process.env.NODE_ENV === "development"
        ? err.message
        : "Une erreur est survenue",
  });
});

// Démarrage du serveur
app.listen(PORT, () => {
  console.log(`🚀 Serveur démarré sur le port ${PORT}`);
  console.log(`📍 URL: http://localhost:${PORT}`);
});

export default app;

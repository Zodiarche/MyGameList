import { Request, Response, Router } from "express";

const router = Router();

/**
 * GET /health
 * Vérification de l'état de santé du serveur
 */
router.get("/", (req: Request, res: Response) => {
  res.json({
    status: "healthy",
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || "development",
  });
});

/**
 * GET /health/detailed
 * Informations détaillées sur la santé du serveur
 */
router.get("/detailed", (req: Request, res: Response) => {
  res.json({
    status: "healthy",
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || "development",
    memory: {
      usage: process.memoryUsage(),
      free: process.memoryUsage().heapUsed / 1024 / 1024 + " MB",
    },
    version: process.version,
    platform: process.platform,
  });
});

export default router;

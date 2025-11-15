import { Router } from "express";

const router = Router();

/**
 * Route de base de l'API
 * GET /api
 */
router.get("/", (req, res) => {
  res.json({
    message: "API MyGameList",
    version: "1.0.0",
    endpoints: {},
  });
});

export default router;

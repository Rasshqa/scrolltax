// ponytail: Clean express bootstrap mounting API v1 routes with CORS and health telemetry.

import express, { Request, Response } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { logsRouter } from './routes/logs.routes';
import { squadsRouter } from './routes/squads.routes';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 4000;

app.use(cors());
app.use(express.json());

// Health check endpoint
app.get('/health', (_req: Request, res: Response) => {
  res.status(200).json({
    status: 'online',
    service: 'ScrollTax API Engine',
    timestamp: new Date().toISOString(),
  });
});

// Root welcome endpoint
app.get('/', (_req: Request, res: Response) => {
  res.status(200).json({
    name: 'ScrollTax Backend API',
    version: '1.0.0',
    endpoints: [
      'POST /api/v1/logs/sync',
      'GET /api/v1/squads/:code/leaderboard',
      'POST /api/v1/squads/join',
    ],
  });
});

// API Routes
app.use('/api/v1/logs', logsRouter);
app.use('/api/v1/squads', squadsRouter);

// Start server
if (process.env.NODE_ENV !== 'test') {
  app.listen(PORT, () => {
    console.log(`ScrollTax API engine running on http://localhost:${PORT}`);
  });
}

export default app;

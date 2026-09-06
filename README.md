# COOPSERVE

**Smart India Hackathon 2026 — Problem Statement SIH26089**
Cooperative Gig Services Platform for Household & Community Services

## Overview

COOPSERVE is a cooperative-owned service marketplace that connects verified cooperative workers with customers for household and community services. Unlike commercial gig platforms, the cooperative model ensures fair wages, worker ownership, and community accountability.

## User Roles

| Role | Description |
|---|---|
| Customer | Books household/community services, tracks workers, makes payments |
| Worker | Cooperative member who accepts jobs, manages availability, receives earnings |
| Cooperative Admin | Manages worker onboarding/verification, monitors platform activity, handles disputes |

## Technology Stack

| Layer | Technology |
|---|---|
| Mobile | Flutter, Dart (Android) |
| Backend | Python, FastAPI |
| Database | PostgreSQL |
| AI | Google Gemini API |
| ML | Python, scikit-learn (demand forecasting) |
| Geo | Google Maps / Location APIs |
| Payments | Mock/sandbox (SIH prototype) |

## Repository Structure

```
coopserve/
├── mobile/       # Flutter Android application
├── backend/      # FastAPI REST API server
├── database/     # Schema migrations and seed data
├── ml/           # Demand forecasting models
└── docs/         # Architecture and API documentation
```

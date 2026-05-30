# TripVault — Private Trip Media + Smart Expense Splitting

> **Stack:** Java 21 · Spring Boot 3.x · React 18 · Neon PostgreSQL · Cloudflare R2  
> **Cost:** $0.00/month · **Repo:** `github.com/Naveen-rvv123/photovault`  
> **Pace:** 2 hrs/day · ~21 days

---

## ⚠️ Active Pivot (Day 3)

Project was renamed from **PhotoVault → TripVault**.  
Old schema (vaults/members) is being replaced with new schema (users/trips/members).  
Old `V1__create_tables.sql` will be replaced.

---

## Free Stack

| Layer | Service | Free Allowance |
|-------|---------|----------------|
| Storage | Cloudflare R2 | 10 GB + zero egress |
| Database (Dev) | Neon PostgreSQL | 0.5 GB — no credit card |
| Database (Stage) | Neon PostgreSQL | 0.5 GB — separate project |
| Database (Prod) | Neon PostgreSQL | 0.5 GB — separate project |
| Backend | Render.com | Free web service |
| Frontend | Vercel | Free + custom domain |
| CI/CD | GitHub Actions | 2000 min/month |
| Email | Resend.com | 3,000 emails/month |
| Monitoring | UptimeRobot | Free — prevents Render cold starts |

---

## 3-Environment Setup

| | Dev | Stage | Prod |
|--|-----|-------|------|
| Backend | localhost:8080 | stage-tripvault.onrender.com | tripvault.onrender.com |
| Frontend | localhost:3000 | Vercel preview | tripvault.vercel.app |
| Database | Neon tripvault-dev | Neon tripvault-stage | Neon tripvault-prod |
| Storage | R2 bucket: tripvault-dev | R2 bucket: tripvault-stage | R2 bucket: tripvault-prod |
| Email | Console logs | Resend sandbox | Resend production |
| Deploy | Manual (IntelliJ) | Auto → push develop | Auto → push main |

---

## Tech Stack

| Layer | Tool | Version |
|-------|------|---------|
| Language | Java | 21 |
| Framework | Spring Boot | 3.x |
| Security | Spring Security | 6.x |
| ORM | Spring Data JPA | 3.x |
| Database | Neon PostgreSQL | 16 |
| Migrations | Flyway | 11.x |
| Storage | Cloudflare R2 (S3-compatible SDK) | — |
| JWT | jjwt | 0.11.x |
| Boilerplate | Lombok | Latest |
| Tests | JUnit 5 | Latest |
| Frontend | React 18 + Vite + Tailwind CSS | — |
| Deploy | Render.com (backend) + Vercel (frontend) | — |

---

## Database Schema (New — replaces old vaults schema)

### `users`
| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | `gen_random_uuid()` |
| name | VARCHAR(100) | |
| email | VARCHAR(255) UNIQUE | |
| password_hash | VARCHAR(255) | BCrypt |
| created_at | TIMESTAMP | `now()` |

### `trips`
| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | `gen_random_uuid()` |
| name | VARCHAR(100) | e.g. "Goa 2025" |
| description | TEXT | |
| created_by | UUID FK | → users |
| created_at | TIMESTAMP | `now()` |

### `trip_members`
| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| trip_id | UUID FK | → trips, CASCADE |
| user_id | UUID FK | → users, CASCADE |
| role | VARCHAR(20) | ADMIN / MEMBER |
| can_upload | BOOLEAN | |
| can_download | BOOLEAN | |
| can_create_folder | BOOLEAN | |
| joined_at | TIMESTAMP | `now()` |

### `folders`
| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| trip_id | UUID FK | → trips, CASCADE |
| name | VARCHAR(100) | |
| created_by | UUID FK | → users |
| created_at | TIMESTAMP | `now()` |

### `media`
| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| folder_id | UUID FK | → folders, CASCADE |
| file_name | VARCHAR(255) | |
| storage_key | VARCHAR(500) | R2 object key |
| storage_url | VARCHAR(1000) | Download URL |
| size_bytes | BIGINT | |
| uploaded_by | UUID FK | → users |
| uploaded_at | TIMESTAMP | `now()` |

### `expenses`
| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| trip_id | UUID FK | → trips, CASCADE |
| description | VARCHAR(255) | |
| amount | DECIMAL(10,2) | |
| paid_by | UUID FK | → users |
| created_at | TIMESTAMP | `now()` |

### `expense_splits`
| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| expense_id | UUID FK | → expenses, CASCADE |
| user_id | UUID FK | → users |
| share_amount | DECIMAL(10,2) | |
| is_settled | BOOLEAN | default false |

---

## REST API

### Auth (public)
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/signup` | Create user account |
| POST | `/api/auth/login` | Login → JWT |

### Trips
| Method | Endpoint | Permission |
|--------|----------|------------|
| GET | `/api/trips` | Authenticated — own trips |
| POST | `/api/trips` | Authenticated |
| GET | `/api/trips/{id}` | Trip member |
| DELETE | `/api/trips/{id}` | Trip ADMIN |

### Members
| Method | Endpoint | Permission |
|--------|----------|------------|
| GET | `/api/trips/{id}/members` | Trip member |
| POST | `/api/trips/{id}/members` | Trip ADMIN — invite |
| PUT | `/api/trips/{id}/members/{uid}/permissions` | Trip ADMIN |
| DELETE | `/api/trips/{id}/members/{uid}` | Trip ADMIN |

### Folders + Media (RBAC guarded)
| Method | Endpoint | Permission |
|--------|----------|------------|
| GET | `/api/trips/{id}/folders` | Trip member |
| POST | `/api/trips/{id}/folders` | `can_create_folder` |
| POST | `/api/folders/{id}/media` | `can_upload` |
| GET | `/api/folders/{id}/media` | Trip member |
| GET | `/api/media/{id}/download` | `can_download` |
| DELETE | `/api/media/{id}` | Trip ADMIN |

### Budget
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/trips/{id}/expenses` | Add expense |
| GET | `/api/trips/{id}/expenses` | List expenses |
| GET | `/api/trips/{id}/settlements` | Calculate who owes whom |
| PUT | `/api/expenses/{id}/settle` | Mark settled |

---

## Project Structure (target)

```
src/main/java/com/tripvault/
├── auth/
│   ├── AuthController.java
│   ├── AuthService.java
│   └── JwtService.java
├── user/
│   └── User.java
├── trip/
│   ├── TripController.java
│   ├── Trip.java
│   └── TripMember.java
├── media/
│   ├── MediaController.java
│   ├── Media.java
│   └── Folder.java
├── budget/
│   ├── BudgetController.java
│   ├── Expense.java
│   └── ExpenseSplit.java
└── config/
    ├── SecurityConfig.java
    ├── JwtAuthFilter.java
    └── R2StorageConfig.java
```

---

## 21-Day Progress Tracker

### Week 1 — Auth + Foundation

| Day | Task | Status | Notes |
|-----|------|--------|-------|
| 1 | GitHub repo + Spring Boot project setup | ✅ Done | Boot 3.5.14, Java 17 in pom (needs upgrade to 21) |
| 2 | Local PostgreSQL + Flyway migrations (old schema) | ✅ Done | docker-compose, V1 schema — will be replaced |
| 3 | Sign up for all free services. Rename project → tripvault. 3 Neon DBs. 3 Spring profiles. `develop` branch. New V1 migration. `User.java` | ⬜ Todo | Biggest setup day |
| 4 | `AuthController` signup + `AuthService` + BCrypt | ⬜ Todo | |
| 5 | Login + `JwtService` + `JwtAuthFilter` + `SecurityConfig` | ⬜ Todo | Add jjwt to pom.xml |
| 6 | `Trip.java` + `TripController` CRUD + auto-add creator as ADMIN | ⬜ Todo | |
| 7 | Member invites + role + permissions. Tag `v0.1.0` | ⬜ Todo | |

### Week 2 — Media + Budget Backend

| Day | Task | Status | Notes |
|-----|------|--------|-------|
| 8 | R2 buckets setup + `R2StorageConfig` + Folder API | ⬜ Todo | |
| 9 | File upload to R2 + `MediaController` multipart | ⬜ Todo | |
| 10 | Media list + download signed URL + delete + RBAC | ⬜ Todo | |
| 11 | Global exception handler + input validation + `ApiResponse` wrapper | ⬜ Todo | |
| 12 | `Expense.java` + add expense API + list | ⬜ Todo | |
| 13 | Settlement algorithm + calculate + mark settled | ⬜ Todo | |
| 14 | Dockerfile + Deploy Stage to Render + Neon stage env vars. Tag `v0.2.0` | ⬜ Todo | |

### Week 3 — React Frontend + Deploy

| Day | Task | Status | Notes |
|-----|------|--------|-------|
| 15 | React + Vite + Tailwind + Axios JWT interceptor | ⬜ Todo | |
| 16 | Signup + Login pages + `useAuth()` + protected routes | ⬜ Todo | |
| 17 | Trip list + create trip + detail tabs (Media/Budget/Members) | ⬜ Todo | |
| 18 | Folder grid + upload from mobile camera roll + photo grid | ⬜ Todo | |
| 19 | Add expense modal + expense list + settlement summary | ⬜ Todo | |
| 20 | Deploy frontend → Vercel. UptimeRobot. GitHub Actions CI/CD | ⬜ Todo | |
| 21 | Bug fixes + empty states + README + share. Tag `v1.0.0` 🎉 | ⬜ Todo | |

---

## Known Issues / Open Items

| # | Issue | Priority |
|---|-------|----------|
| 1 | `pom.xml` sets Java 17 — plan targets Java 21. Upgrade on Day 3. | High |
| 2 | Old `V1__create_tables.sql` uses vaults/members schema — replace with new users/trips schema on Day 3 | High |
| 3 | `jjwt` not in `pom.xml` — add on Day 5 before JWT work | Medium |
| 4 | Package name still `com.photovault` — rename to `com.tripvault` on Day 3 | High |
| 5 | `docker-compose.yml` (local PG) will be replaced by Neon connection string | Low |

---

## Day 3 Checklist (Start Here)

### Sign Up (15 min — all free, no credit card except Cloudflare R2 activation)
- [ ] neon.tech → create 3 projects: `tripvault-dev`, `tripvault-stage`, `tripvault-prod`
- [ ] cloudflare.com → create 3 R2 buckets: `tripvault-dev`, `tripvault-stage`, `tripvault-prod`
- [ ] render.com → connect GitHub repo
- [ ] vercel.com → connect GitHub repo
- [ ] resend.com → get API key
- [ ] uptimerobot.com → account ready

### Code Changes (60 min)
- [ ] Rename package `com.photovault` → `com.tripvault` everywhere
- [ ] Update `pom.xml` Java version 17 → 21
- [ ] Add `jjwt` dependency to `pom.xml`
- [ ] Create `application-dev.properties`, `application-stage.properties`, `application-prod.properties`
- [ ] Replace `V1__create_tables.sql` with new users/trips/media/budget schema
- [ ] Create `User.java` entity
- [ ] Create `develop` branch on GitHub

---

## Environment Variables Reference

### Locally (`.env` — never commit)
```
NEON_DEV_PASSWORD=
CF_ACCOUNT_ID=
CF_ACCESS_KEY_ID=
CF_SECRET_ACCESS_KEY=
JWT_SECRET=
```

### Render (Stage + Prod)
```
SPRING_PROFILES_ACTIVE=stage
NEON_STAGE_URL=
NEON_STAGE_USER=
NEON_STAGE_PASSWORD=
CF_ACCOUNT_ID=
CF_ACCESS_KEY_ID=
CF_SECRET_ACCESS_KEY=
JWT_SECRET=
RESEND_API_KEY=
```

### Vercel
```
VITE_API_URL=https://tripvault-stage.onrender.com  (stage)
VITE_API_URL=https://tripvault.onrender.com        (prod)
```

### GitHub Secrets (CI/CD)
```
RENDER_STAGE_DEPLOY_HOOK=
RENDER_PROD_DEPLOY_HOOK=
```

---

## Cost Estimate

| Resource | Provider | Cost |
|----------|----------|------|
| Storage (10 GB) | Cloudflare R2 | $0 |
| PostgreSQL × 3 | Neon | $0 |
| Backend hosting | Render.com | $0 |
| Frontend | Vercel | $0 |
| Email | Resend | $0 |
| CI/CD | GitHub Actions | $0 |
| **Total** | | **$0/month** |

---

*Built by Naveen — TripVault v1.0.0 target*

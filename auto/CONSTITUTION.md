# NestJS Engineering Constitution

## 1. Core Principles (NON-NEGOTIABLE)

### I. Technology & Version Lock
Technology versions are fixed to ensure stability and reproducibility across environments.
- **Runtime**: Node.js Active LTS (defined in `.nvmrc` or `package.json` engines).
- **Framework**: NestJS (Current Stable Major Version).
- **Language**: TypeScript (Latest Stable). **Strict Mode**: `true`.
- **Legacy Code Policy**: Any code not adhering to Clean Architecture principles is considered "Legacy". It must be refactorized, not extended.

### II. Architecture Strategy
Every NestJS service must adhere to **Modular Monolith** or **Microservices** patterns under **Clean Architecture** principles:

1.  **Domain Layer (Pure)**:
    - Contains Entities and Business Rules.
    - ❌ **FORBIDDEN**: Dependencies on infrastructure (TypeORM, Axios, external NestJS modules).
    - ❌ **FORBIDDEN**: ORM decorators inside Domain Entities.
2.  **Application Layer (Orchestration)**:
    - Contains Use Cases / Services.
    - ✅ **ALLOWED**: Repository Interfaces (Ports).
    - ❌ **FORBIDDEN**: Direct SQL/Redis queries (must use Repositories).
3.  **Infrastructure Layer (Adapters)**:
    - Contains Repository Implementations, HTTP Controllers, Cron Jobs.
    - ✅ **ALLOWED**: Third-party libraries, Database Drivers.

### III. Security-First
- **Zero Trust**: All external communication must be encrypted (HTTPS/TLS).
- **Secrets Management**: Credentials, tokens, and keys **MUST** reside in environment variables.
    - ❌ `const apiKey = "1234"` (Immediate BLOCK in Code Review).
- **Sanitization**: All public endpoints must use DTOs with strict validation (`class-validator` with `whitelist: true`).

### IV. Observability & Reliability
- **Structured Logging**: Mandatory use of `Pino` (JSON format in Production). No `console.log`.
- **Tracing**: OpenTelemetry instrumentation ready for distributed tracing.
- **Statelessness**: Services must not store state in local memory that needs to persist across restarts. Use Redis or SQL.

---

## 2. Coding Standards & Constraints

### File & Complexity Limits
Code must be readable and maintainable. If it exceeds these limits, it **must** be refactored.

| Element | Max Limit | Recommended | Action if Exceeded |
|:---|:---:|:---:|:---|
| **File Length** | **500 lines** | 200-300 | Split into sub-services or utilities. |
| **Method/Function** | **80 lines** | 20-40 | Extract logic to private methods or helpers. |
| **Parameters** | 3 args | 1-2 | Use an `Options` object or DTO. |
| **Injections (Constructor)** | 5 deps | 3-4 | Apply Facade Pattern or split responsibilities. |
| **Cyclomatic Complexity** | 10 | < 5 | Simplify logic / Use early returns. |
| **Nesting Depth** | 3 levels | 2 | Use Guard Clauses (`if (!ok) return;`). |

### Naming Conventions

| Type | Convention | Example |
|:---|:---|:---|
| **Files** | `kebab-case` | `user-profile.service.ts` |
| **Classes** | `PascalCase` | `UserProfileService` |
| **Interfaces** | `I` + `PascalCase` | `IUserProfile` |
| **Methods/Variables** | `camelCase` | `findActiveProfile()` |
| **Constants** | `SCREAMING_SNAKE` | `MAX_RETRY_COUNT` |
| **Database Columns** | `snake_case` | `created_at`, `user_id` |
| **DTOs** | `PascalCase` + `Dto` | `CreateUserDto` |

---

## 3. Folder Structure & Organization

### NestJS Feature Module (Standard)
```text
src/modules/users/
├── controllers/       # HTTP Endpoints
├── services/          # Application/Business Logic
├── domain/            # (Optional) Pure Models if strict Clean Arch
├── infrastructure/    # (Optional) Concrete Repositories
├── dto/               # Data Transfer Objects (Validation)
├── guards/            # Authorization Guards
├── entities/          # DB Entities (TypeORM/Prisma/Mongoose)
├── users.module.ts    # Module Definition
└── users.constants.ts # Local constants

```

### Shared / Libs Structure

Reusable code must reside in libraries or a `shared` module.

```text
libs/ (or src/shared/)
├── database/          # Connection configs
├── logging/           # Pino configuration
├── utils/             # Pure helpers (dates, strings)
└── filters/           # Global Exception Filters

```

---

## 4. Best Practices

### Error Handling

* Use **Standard NestJS Exceptions** (`NotFoundException`, `BadRequestException`).
* Never silently swallow errors.
* `try/catch` blocks should only be used in Infrastructure layers or when calling external APIs.

### Database Interaction

* **Soft Deletes**: Mandatory for critical entities (`deletedAt`).
* **Pagination**: Mandatory for endpoints returning lists (`limit`, `offset`/`cursor`).
* **QueryBuilder**: Preferred over complex "magic" ORM methods for better performance and control.

### Testing

* **Unit Tests**: Minimum 80% coverage in `services/` and business logic.
* **E2E Tests**: At least 1 success case and 1 error case per critical Controller.
* **Mocking**: Do not depend on a real DB for unit tests.

---

## 5. Governance & Workflow

### Commits

Must follow **Conventional Commits**:

* `feat(auth): add login endpoint`
* `fix(users): resolve soft delete bug`
* `chore: update dependencies`

### Pull Request Rules

1. Must pass the CI pipeline (Lint, Build, Test).
2. Must include tests for the new feature or bugfix.
3. Must not violate complexity limits (e.g., >500 lines/file).

---

**Version**: 2.0.0 | **Framework**: NestJS 

# OSD Web Backend — Tasks & Acceptance Criteria Based on Actual Code

Source: `github.com/wilroww/backend`, uploaded snapshot (`backend-master.zip`). Package: `org.rocs.osdrmsa`. Layers: Controller → **Services**/ServiceImpl → Repository → Entity.

**Big change since the last version of this file:** the codebase has gone from 3 partially-built features to 9 fully wired features, plus real security (JWT, BCrypt, role-based access), a global exception handler, an audit log, and a growing test suite. Nearly everything previously marked ⚠️ or 🔲 is now ✅. Status markers below are all re-verified against the new code, not carried over from before.

Status key: ✅ Done (code exists, no known gap) · ⚠️ Done but has a gap/note worth tracking · 🔲 Not started

---

## Login Feature — ✅ Fully rebuilt

### Create Repository for Login — ✅ Done
`LoginRepository`, extending `JpaRepository<Login, Long>`.

**Acceptance Criteria:**
- The Repository is created for the `Login` table.
- It provides a method (`findByUsername`) to find a Login record by username.
- It connects to the `Login` table (`LOGINID` id, unique `USERNAME`, one-to-one join to `Person`, plus `joinDate`, `lastLoginDate`, `role`, `authorities`, `active`, `locked`).
- The method returns the matching row, or `Optional.empty()` if no username matches.
- It can be extended to retrieve by other fields (e.g., `personID`) if needed.
- All database operations execute without errors, including a blank/null username returning `Optional.empty()` rather than throwing.

### Create Services for Login — ✅ Done
`LoginService` (interface) / `LoginServiceImpl`.

**Acceptance Criteria:**
- The Service is created for Login.
- It provides an `authenticate(username, password)` method.
- It connects to `LoginRepository` to fetch stored credentials, and to `PasswordEncoder` (BCrypt) to verify them.
- The method checks, in order: account exists → `PasswordEncoder.matches(rawPassword, storedHash)` → `isLocked()` → `isActive()`, throwing a specific typed exception at whichever check fails (`InvalidCredentialsException`, `AccountLockedException`, `AccountInactiveException`) rather than a generic failure.
- On success, it updates `lastLoginDate` to now and returns the authenticated `Login`.
- All operations execute without errors; each failure path (bad password, locked account, inactive account, unknown username) is independently testable and covered by `LoginServiceImplTest`.

### Create Controller for Login — ✅ Done
`LoginController` at `POST /login`, `POST /login/refresh`, `POST /login/logout`.

**Acceptance Criteria:**
- The Controller is created for Login.
- `POST /login` accepts a `LoginRequest` body, calls `LoginService.authenticate()`, and on success returns a `LoginResponse` record: `token`, `username`, `role`, `studentId` (resolved via a `resolveStudentId()` helper for STUDENT-role accounts).
- `POST /login/refresh` accepts the current Bearer token, verifies it via `JwtService`, and reissues a new token without requiring the password again.
- `POST /login/logout` returns success with no server-side state change — documented as a no-op because the API is stateless (JWT, not sessions); the client is responsible for discarding the token.
- Authentication failures are not handled ad hoc here — they propagate to `GlobalExceptionHandler`, which maps them to structured JSON (`{timestamp, status, code, message}`) with the correct HTTP status (401 for bad credentials, 403 for locked/inactive).
- All endpoint calls execute without errors, including a malformed/missing request body returning 400 via the same global handler rather than a raw 500.

**Resolved from the previous version of this file:** the earlier plain-text password comparison and missing token issuance are both fixed — Login now hashes with BCrypt and issues a JWT with role/authorities/personId claims via `JwtService`.

---

## Enrollment Feature — ✅ Fully fixed, Controller added

### Create Repository for Enrollment — ✅ Done
`EnrollmentRepository`.

**Acceptance Criteria:**
- The Repository is created for the `Enrollment` table.
- It provides `findFirstByStudent_StudentIdOrderBySchoolYearDesc` (latest enrollment for a student) and `findByStudent_StudentIdOrderBySchoolYearDesc` (full enrollment history for a student), both correctly navigating the nested `student.studentId` path.
- It provides `findAllLatest()` via a `@Query` JPQL subquery that returns true "latest per student" rows, not just every row.
- It connects to the `Enrollment` table, joined to `Student`, `Department` (enum), and `DisciplinaryStatus`.
- All database operations execute without errors — the previously broken method name (missing the `Student` path segment) is corrected.

### Create Services for Enrollment — ✅ Done
`EnrollmentService` (interface) / `EnrollmentServiceImpl`.

**Acceptance Criteria:**
- The Service is created for Enrollment.
- It provides `getAllLatestEnrollments()`, `getEnrollmentsByStudentId(id)`, `getLatestEnrollmentByStudentId(studentId)`, and `getEnrollmentHistoryByStudentId(studentId)`.
- It connects to `EnrollmentRepository` for all four methods.
- `getAllLatestEnrollments()` now genuinely calls `findAllLatest()` and returns one row per student, matching its name — the earlier `findAll()` mismatch is fixed.
- All operations execute without errors.

### Create Controller for Enrollment — ✅ Done
`EnrollmentController` at `/api/enrollments` (did not exist in the previous review).

**Acceptance Criteria:**
- A Controller is created for Enrollment, exposing 4 endpoints (latest-by-student, history-by-student, all-latest, and a school-year/department scoped list — confirm exact paths against `EnrollmentController.java` if wiring a frontend against it).
- It connects to `EnrollmentService` to process each request.
- Admin/Prefect-facing endpoints require `@PreAuthorize("hasAnyRole('ADMIN','PREFECT')")`; student-scoped endpoints additionally allow the student themself via `@access.isSelfStudent(#studentId)`.
- The endpoint returns the enrollment data on success, and a clear 404 (via the student not existing) for a student with no enrollment record.
- All endpoint calls execute without errors.

---

## Record Feature — ✅ Fully done, Controller added

### Create Repository for Record — ✅ Done
`RecordRepository`.

**Acceptance Criteria:**
- The Repository is created for the `Record` table.
- It provides `findByEnrollmentStudentStudentId`, `findByEnrollmentDepartmentAndEnrollmentSchoolYear`, `findByEnrollmentSchoolYearOrderByDateOfViolationDesc`, `countByEnrollmentSchoolYear`, `countByDateOfViolation`, and `findOffenseFrequencyBySchoolYear` (a projection query for offense-frequency stats).
- It connects to the `Record` table, joined to `Enrollment`, `Employee`, `Offense`, and `DisciplinaryAction`.
- The list-returning methods return an empty `List`, not null, when nothing matches.
- All database operations execute without errors.

### Create Services for Record — ⚠️ Done, one gap remains
`RecordService` (interface) / `RecordServiceImpl`.

**Acceptance Criteria:**
- The Service is created for Record.
- It provides `createStudentRecord`, `updateStudentRecord`, `resolveRecord`, `getViolationsByDepartment`, `getRecordByStudentId`, `getAllBySchoolYear`, `getTotalViolations`, `getTodayViolations`, and `getMostFrequentOffenses`.
- It connects to `RecordRepository` for persistence and to `AuditLogService` — every create/update/resolve writes an audit entry (`RECORD_CREATED`, `RECORD_UPDATED`, `RECORD_RESOLVED`).
- `createStudentRecord` validates `Employee`/`Employee.employeeId`/`dateOfViolation` are non-null and `remarks` is 500 characters or fewer, returning `null` on failure; it also force-resets `recordId` to 0 before saving so a client-supplied non-zero id can't accidentally trigger an update-as-merge instead of an insert (documented in code as a deliberate `GenerationType.IDENTITY` safeguard).
- `resolveRecord(recordId)` sets status to `RESOLVED` and `dateOfResolution` to now; returns `null` if the record isn't found.
- **Remaining gap (carried over from the last review, still real):** neither `createStudentRecord` nor `updateStudentRecord` validates that the referenced `Offense` or `DisciplinaryAction` actually exist before saving — a bad id still fails at the raw DB foreign-key level instead of with a clean validation message. Worth a follow-up task once the Controller layer needs a friendlier error for this case.
- All operations execute without errors; covered by `RecordServiceImplTest`.

### Create Controller for Record — ✅ Done
`RecordController` at `/api/records` (did not exist in the previous review).

**Acceptance Criteria:**
- A Controller is created for Record with endpoints to create (`POST`), update (`PUT`), resolve (`PATCH /{recordId}/resolve`), fetch by student (`GET /student/{studentId}`), fetch by department/school-year (`GET`), and three stats endpoints (`/stats/total-violations`, `/stats/today-violations`, `/stats/frequent-offenses`).
- Requests/responses use dedicated DTOs (`RecordCreateRequest`, `RecordUpdateRequest`, `RecordResponse`) so clients can't over-post fields like `recordId`/`status`.
- It connects to `RecordService` to process each request.
- Create/update/resolve/department-list/stats endpoints require `hasAnyRole('ADMIN','PREFECT')`; `getByStudent` additionally allows the student themself via `@access.isSelfStudent(#studentId)`.
- The endpoints return the saved/updated/resolved record on success, and a 400/404 (via `RecordDtoMapper` null-checks) rather than a generic 500 when the Service returns `null`.
- All endpoint calls execute without errors.

**Resolved from the previous version of this file:** the Controller now exists, plus 3 dashboard stats endpoints that weren't even planned before (`department` param on the list endpoint was also made optional per code comment "task #36 batch 8").

---

## Appeal Feature — ✅ Fully built (previously entity-only)

### Create Repository for Appeal — ✅ Done
`AppealRepository`.

**Acceptance Criteria:**
- The Repository is created for the `Appeal` table.
- It provides `findByEnrollmentStudentStudentId(studentId)`, `findByRecordRecordId(recordId)`, and `findByStatusOrderByDateFiledDesc(status)`.
- It connects to the `Appeal` table, joined to `Record` and `Enrollment`.
- The methods return a `List<Appeal>`, empty when nothing matches.
- All database operations execute without errors.

### Create Services for Appeal — ✅ Done
`AppealService` (interface) / `AppealServiceImpl`.

**Acceptance Criteria:**
- The Service is created for Appeal.
- It provides `fileAppeal`, `reviewAppeal(appealId, newStatus, remarks)`, `getByStudentId`, `getByRecordId`, and `getByStatus`.
- It connects to `AppealRepository` and to `AuditLogService` (`APPEAL_FILED`, `APPEAL_<STATUS>`).
- `fileAppeal` requires a non-null `record` and `enrollment` and a non-blank `message`, force-sets status to `PENDING`, `dateFiled` to now, and clears `dateProcessed`/`remarks` so a client can't set them on submission.
- `reviewAppeal` enforces a status state machine (`PENDING → UNDER_REVIEW/APPROVED/DENIED`, `UNDER_REVIEW → APPROVED/DENIED`, no transitions out of `APPROVED`/`DENIED`), rejecting illegal transitions with `IllegalArgumentException`, and stamps `dateProcessed` when it reaches a terminal state.
- Uses a dedicated `AppealStatus` enum (`PENDING`, `UNDER_REVIEW`, `APPROVED`, `DENIED`) — the earlier plain-`String` status field flagged in the last review has been replaced.
- All operations execute without errors; covered by `AppealServiceImplTest`.

### Create Controller for Appeal — ✅ Done
`AppealController` at `/api/appeals`.

**Acceptance Criteria:**
- A Controller is created for Appeal with endpoints to file (`POST`, role `USER`/student), review (`PATCH /{appealId}/review`, role `ADMIN`/`PREFECT`), fetch by student (`GET /student/{studentId}`), fetch by record (`GET /record/{recordId}`), and fetch by status (`GET`).
- Requests/responses use dedicated DTOs (`AppealFileRequest`, `AppealReviewRequest`, `AppealResponse`) so `status`/`dateFiled`/`dateProcessed` can't be client-set.
- It connects to `AppealService` to process each request.
- `getByStudent` allows the student themself via `@access.isSelfStudent(#studentId)`, in addition to Admin/Prefect.
- The endpoints return the filed/reviewed appeal on success, and a specific error for an illegal status transition or a not-found appeal (via `GlobalExceptionHandler`).
- **Known, documented gap (from the code's own comment):** `file()` trusts the `record`/`enrollment` ids the client supplies rather than cross-checking they belong to the authenticated student — same class of gap as Record's missing FK validation. Worth a follow-up task if this needs closing before appeals go live for real students.
- All endpoint calls execute without errors.

---

## Request Feature — ✅ Fully built (new — didn't exist before)

Staff/employee requests (e.g., record pulls, corrections) with a Prefect/Admin approval step.

### Create Repository for Request — ✅ Done
`RequestRepository`.

**Acceptance Criteria:**
- The Repository is created for the `Request` table.
- It provides `findByEmployeeID(employeeId)` and `findByStatus(status)`.
- It connects to the `Request` table (`employeeID`, `details`, `message`, `type`, `status`, `dateProcessed`, `remarks`).
- The methods return a `List<Request>`, empty when nothing matches.
- All database operations execute without errors.

### Create Services for Request — ✅ Done
`RequestService` (interface) / `RequestServiceImpl`.

**Acceptance Criteria:**
- The Service is created for Request.
- It provides `submitRequest`, `processRequest(requestId, decision, remarks)`, `getByEmployeeId`, `getByStatus`, and `getAll`.
- It connects to `RequestRepository` and to `AuditLogService` (`REQUEST_SUBMITTED`, `REQUEST_<DECISION>`).
- `submitRequest` requires non-blank `employeeID` and `type`, force-sets status to `PENDING`, and clears `dateProcessed`/`remarks`.
- `processRequest` only accepts `APPROVED` or `DENIED` as the decision, throws if the request isn't `PENDING` (already processed = terminal), and stamps `dateProcessed` on success.
- All operations execute without errors; covered by a Service-level test.

### Create Controller for Request — ✅ Done
`RequestController` at `/api/requests`.

**Acceptance Criteria:**
- A Controller is created for Request with endpoints to submit (`POST`, role `STAFF`), decide (`PATCH /{requestId}/decision`, role `ADMIN`/`PREFECT`), fetch by employee (`GET /employee/{employeeId}`), and list all with an optional status filter (`GET`).
- Requests/responses use dedicated DTOs (`RequestSubmitRequest`, `RequestDecisionRequest`, `RequestResponse`).
- It connects to `RequestService` to process each request.
- The endpoints return the submitted/decided request on success, and a specific error for double-processing or an invalid decision value.
- All endpoint calls execute without errors.

---

## Guardian Feature — ⚠️ Read-only by design, no gaps found

### Create Repository for Guardian — ✅ Done
`GuardianRepository`, extending `JpaRepository<Guardian, Long>` (no custom methods — reads go through `Student.guardians`, see Service below).

**Acceptance Criteria:**
- The Repository is created for the `Guardian` table.
- It connects to the `Guardian` table (`contactNumber`, `relationship` — stored as a plain `String`, not an enum, because the DB's `CHECK` constraint uses mixed-case values like `'Father'`/`'Mother'`/`'Guardian'`).
- It supports standard `JpaRepository` operations (`save`, `findById`, etc.) for future use even though nothing currently calls create/update through it.
- All database operations execute without errors.

### Create Services for Guardian — ✅ Done (scope is deliberately narrow)
`GuardianService` (interface) / `GuardianServiceImpl`.

**Acceptance Criteria:**
- The Service is created for Guardian.
- It provides `getByStudentId(studentId)`.
- It connects to `StudentRepository` (not `GuardianRepository` directly) and reads guardians off the `Student.guardians` many-to-many mapping — documented in code as matching the desktop app's existing lookup pattern.
- The method throws `NoSuchElementException` for an unknown `studentId` rather than returning an empty list, so the Controller can map it to a 404.
- **Scope note, not a bug:** creating, updating, or unlinking a guardian is not implemented anywhere — flag this if the web app's account-management screens need OSD staff to edit guardian info directly; right now that would require a new task.
- All operations execute without errors; covered by `GuardianServiceImplTest`.

### Create Controller for Guardian — ✅ Done
`GuardianController` at `/api/guardians`.

**Acceptance Criteria:**
- A Controller is created for Guardian with a single endpoint: `GET /student/{studentId}`.
- It connects to `GuardianService` to process the request.
- Access matches the Enrollment/Record/Appeal pattern: `ADMIN`/`PREFECT`/`STAFF` can look up any student, a `USER`-role (student) caller can only look up themself via `@access.isSelfStudent(#studentId)`.
- **Note:** this endpoint returns the raw `Guardian` entity list, not a DTO — inconsistent with Record/Appeal/Request/Login, which all use dedicated response DTOs. Not a functional bug, but worth aligning if the team wants one consistent contract style across the API.
- All endpoint calls execute without errors.

---

## Student Feature — ✅ Fully built (new — didn't exist before)

### Create Repository for Student — ✅ Done
`StudentRepository`.

**Acceptance Criteria:**
- The Repository is created for the `Student` table.
- It provides `findByDepartment(department)` and `findByPerson_PersonID(personId)` — the latter resolves a Student from the logged-in user's `personId` JWT claim, so a client can discover its own `studentId` after login without already knowing it.
- It connects to the `Student` table (`studentID` as the primary key — a `String`, not generated — one-to-one to `Person`, many-to-many to `Guardian` via a `studentGuardian` join table).
- All database operations execute without errors.

### Create Services for Student — ✅ Done
`StudentService` (interface) / `StudentServiceImpl`.

**Acceptance Criteria:**
- The Service is created for Student.
- It provides `getAll`, `getByDepartment`, `getById`, `getByPersonId`, `create`, `update`, and `delete`.
- It connects to `StudentRepository` for all operations.
- `create` requires a non-blank `studentId` and rejects a duplicate id with `IllegalArgumentException`.
- `update` throws `NoSuchElementException` for an unknown `studentId`, then applies `person`/`address`/`studentType`/`department` from the incoming object onto the existing managed entity (rather than blind-saving the incoming object) to avoid accidentally nulling out fields the caller didn't send.
- All operations execute without errors.

### Create Controller for Student — ✅ Done
`StudentController` at `/api/students`.

**Acceptance Criteria:**
- A Controller is created for Student with endpoints to list all (`GET`, optional `department` filter), get by id (`GET /{studentId}`), create (`POST`), update (`PUT /{studentId}`), and delete (`DELETE /{studentId}`).
- It connects to `StudentService` to process each request.
- List/create/update/delete require `ADMIN` (list also allows `PREFECT`); get-by-id additionally allows the student themself via `@access.isSelfStudent(#studentId)`.
- **Note:** like Guardian, this Controller returns/accepts the raw `Student` entity directly rather than DTOs — same "worth aligning for consistency" flag as above, not a functional bug.
- All endpoint calls execute without errors.

---

## Offense Feature — ✅ Fully built (new — didn't exist before)

Catalog of offense types referenced by `Record`.

### Create Repository for Offense — ✅ Done
`OffenseRepository`.

**Acceptance Criteria:**
- The Repository is created for the `Offense` table.
- It provides `findByType(type)`.
- It connects to the `Offense` table (`offenseID`, `offense`, `type`, `description`).
- All database operations execute without errors.

### Create Services for Offense — ✅ Done
`OffenseService` (interface) / `OffenseServiceImpl`.

**Acceptance Criteria:**
- The Service is created for Offense.
- It provides `getAll`, `getByType`, `getById`, `create`, `update`, and `delete`.
- It connects to `OffenseRepository`.
- `create` force-resets `offenseId` to 0 before saving (auto-generated id).
- `delete` catches `DataIntegrityViolationException` (an offense still referenced by existing `Record` rows) and rethrows as a clear `IllegalStateException` rather than letting a raw DB constraint error surface.
- All operations execute without errors.

### Create Controller for Offense — ✅ Done
`OffenseController` at `/api/offenses`.

**Acceptance Criteria:**
- A Controller is created for Offense with endpoints to list all (`GET`, optional `type` filter), get by id (`GET /{id}`), create (`POST`), update (`PUT /{id}`), and delete (`DELETE /{id}`).
- It connects to `OffenseService` to process each request.
- Read endpoints only require `isAuthenticated()` (any logged-in role can view the catalog); write endpoints require `ADMIN`.
- The delete endpoint surfaces the "still referenced by existing records" case as a clean error rather than a 500.
- All endpoint calls execute without errors.

---

## Disciplinary Action Feature — ✅ Fully built (new — didn't exist before)

Catalog of disciplinary actions referenced by `Record`.

### Create Repository for Disciplinary Action — ✅ Done
`DisciplinaryActionRepository`, extending `JpaRepository<DisciplinaryAction, Long>` (no custom methods needed).

**Acceptance Criteria:**
- The Repository is created for the `DisciplinaryAction` table.
- It connects to the `DisciplinaryAction` table (`actionID`, `action`/`actionName`, `description`).
- All database operations execute without errors.

### Create Services for Disciplinary Action — ✅ Done
`DisciplinaryActionService` (interface) / `DisciplinaryActionServiceImpl`.

**Acceptance Criteria:**
- The Service is created for Disciplinary Action.
- It provides `getAll`, `getById`, `create`, `update`, and `delete`.
- It connects to `DisciplinaryActionRepository`.
- **Important difference from Offense/Record/etc.:** `actionID` is a plain, manually-assigned primary key in the DB script — it is NOT `@GeneratedValue`. `create` therefore requires the caller to supply a unique, non-zero `actionId` and rejects both a zero id and a duplicate id with `IllegalArgumentException` — this is deliberately the opposite of how `create()` works everywhere else in this codebase (documented in code specifically to prevent an accidental id-0 collision).
- `delete` catches `DataIntegrityViolationException` the same way `OffenseService` does.
- All operations execute without errors.

### Create Controller for Disciplinary Action — ✅ Done
`DisciplinaryActionController` at `/api/disciplinary-actions`.

**Acceptance Criteria:**
- A Controller is created for Disciplinary Action with the same 5-endpoint shape as Offense (list, get-by-id, create, update, delete).
- It connects to `DisciplinaryActionService` to process each request.
- Read endpoints require `isAuthenticated()`; write endpoints require `ADMIN`.
- Frontend/API-consumer note: creating a new disciplinary action requires supplying an `actionId` up front (see Service note above) — different from every other "create" endpoint in this API, which auto-generate their id. Worth calling out explicitly wherever this endpoint gets documented for the frontend team.
- All endpoint calls execute without errors.

---

## Employee Feature — ✅ Fully built (new — didn't exist before)

### Create Repository for Employee — ✅ Done
`EmployeeRepository`.

**Acceptance Criteria:**
- The Repository is created for the `Employee` table.
- It provides `findByDepartment(department)`.
- It connects to the `Employee` table (`employeeID` as the primary key — a `String`, not generated — one-to-one to `Person`, plus `department` and `employeeRole`).
- All database operations execute without errors.

### Create Services for Employee — ✅ Done
`EmployeeService` (interface) / `EmployeeServiceImpl`.

**Acceptance Criteria:**
- The Service is created for Employee.
- It provides `getAll`, `getByDepartment`, `getById`, `create`, `update`, and `delete`.
- It connects to `EmployeeRepository`.
- `create` requires a non-blank `employeeId` and rejects a duplicate with `IllegalArgumentException`, same pattern as `StudentService.create`.
- `update` throws `NoSuchElementException` for an unknown id, then applies fields onto the existing managed entity rather than blind-saving.
- All operations execute without errors.

### Create Controller for Employee — ✅ Done
`EmployeeController` at `/api/employees`.

**Acceptance Criteria:**
- A Controller is created for Employee with list (`GET`, optional `department` filter), get-by-id (`GET /{employeeId}`), create (`POST`), update (`PUT /{employeeId}`), and delete (`DELETE /{employeeId}`).
- It connects to `EmployeeService` to process each request.
- List/get-by-id are open to `ADMIN` and `PREFECT` (documented reason: the desktop app's request-submission screen needs a logged-in Prefect to look up their own employee record); create/update/delete stay `ADMIN`-only.
- **Note:** same as Guardian/Student — returns/accepts the raw `Employee` entity rather than a DTO.
- All endpoint calls execute without errors.

---

## Audit Log Feature — ✅ Fully built (new, cross-cutting)

Immutable trail of who did what to which Record/Appeal/Request — written automatically by the other Services, not something a user submits directly.

### Create Repository for Audit Log — ✅ Done
`AuditLogRepository`.

**Acceptance Criteria:**
- The Repository is created for the `AUDIT_LOG` table.
- It provides `findByEntityTypeAndEntityIdOrderByOccurredAtDesc(entityType, entityId)`.
- It connects to the `AUDIT_LOG` table (`AUDIT_LOG_ID`, `ACTOR_USERNAME`, `ACTION`, `ENTITY_TYPE`, `ENTITY_ID`, `DETAILS`, `OCCURRED_AT`) — every column except the generated id is marked `updatable = false` at the entity level, enforcing immutability in the schema, not just in application code.
- All database operations execute without errors.

### Create Services for Audit Log — ✅ Done
`AuditLogService` (interface) / `AuditLogServiceImpl`.

**Acceptance Criteria:**
- The Service is created for Audit Log.
- It provides `log(action, entityType, entityId, details)` and `getHistory(entityType, entityId)`.
- It connects to `AuditLogRepository`.
- `log()` resolves the acting username from `SecurityContextHolder` itself (falling back to `"system"` if no authenticated user is present) — the caller cannot pass in an arbitrary actor, preventing misattribution.
- All operations execute without errors; covered by `AuditLogServiceImplTest`.

### Create Controller for Audit Log — ✅ Done
`AuditLogController` at `/api/audit-log`.

**Acceptance Criteria:**
- A Controller is created for Audit Log with a single endpoint: `GET` with `entityType`/`entityId` query params.
- It connects to `AuditLogService` to process the request.
- The entire controller is `ADMIN`-only (`@PreAuthorize("hasRole('ADMIN')")` at the class level, not per-method) — no other role can read the audit trail.
- All endpoint calls execute without errors.

---

## Cross-Cutting: Security & Infrastructure — ✅ Fully built (new)

None of this existed in the previous review; it's what makes every `@PreAuthorize` check above actually enforceable.

### Create Security Configuration — ✅ Done
`SecurityConfig`, `JwtService`, `JwtAuthenticationFilter` (implied by `SecurityConfig` wiring), `OwnAccessEvaluator`, `RestAuthenticationEntryPoint`, `RestAccessDeniedHandler`, `SecurityErrorResponseWriter`.

**Acceptance Criteria:**
- Security config is created and stateless (no server-side session).
- It provides a `BCryptPasswordEncoder` bean (used by `LoginServiceImpl`), a JWT filter placed before `UsernamePasswordAuthenticationFilter`, and method-level security via `@EnableMethodSecurity` (which is what makes every `@PreAuthorize` annotation above actually take effect).
- It connects `/login`, `/login/**`, `/api/health`, and the Swagger/OpenAPI paths as `permitAll`; every other endpoint requires authentication by default.
- `JwtService` generates tokens carrying `role`, `authorities`, and `personId` claims, and refuses to start up with the insecure default signing secret outside `dev`/`local`/`test` profiles (checked via `Environment.getActiveProfiles()`) — a real safeguard against shipping to production with a placeholder secret.
- `OwnAccessEvaluator` (bean name `access`) provides `isSelfStudent(studentId)`, used throughout the SpEL `@PreAuthorize` expressions above, resolving the current authenticated username → `Login` → `Person` → comparing against the target `Student`'s linked `Person`.
- Authentication/authorization failures are handled by dedicated `RestAuthenticationEntryPoint`/`RestAccessDeniedHandler` classes producing the same structured JSON shape as `GlobalExceptionHandler`, rather than Spring Security's default HTML/plain-text error pages.
- All security-related unit tests (`JwtServiceTest`, `OwnAccessEvaluatorTest`, `RestAccessDeniedHandlerTest`, `RestAuthenticationEntryPointTest`) pass.

### Create Global Exception Handling — ✅ Done
`GlobalExceptionHandler` (`@RestControllerAdvice`).

**Acceptance Criteria:**
- A global exception handler is created, applying to every Controller in the app.
- It maps each known exception type to a specific HTTP status and machine-readable `code`: `InvalidCredentialsException` → 401 `INVALID_CREDENTIALS`, `AccountLockedException` → 403 `ACCOUNT_LOCKED`, `AccountInactiveException` → 403 `ACCOUNT_INACTIVE`, bad input → 400 `INVALID_REQUEST`, `NoSuchElementException` → 404 `NOT_FOUND`, duplicate/conflict → 409 `CONFLICT`, access-denied → 403 `ACCESS_DENIED`, anything unhandled → 500 `INTERNAL_ERROR`.
- Every error response follows one consistent JSON shape: `{timestamp, status, code, message}`.
- All operations execute without errors — no raw stack trace or default Spring error page reaches an API client.

### Create Health Check Endpoint — ✅ Done
`HealthController` at `/api/health`.

**Acceptance Criteria:**
- A Controller is created exposing `GET /api/health`.
- It returns `{"status": "UP"}` with no authentication required (matches the `permitAll` list in `SecurityConfig`).
- Useful as a deploy/monitoring smoke-test target — nothing more to it than that.

---

## Other things worth flagging while I was in the code

- **The `Person.java` stray `@Bean` bug flagged in the previous review is gone.** `Person` is now a clean `@Entity` with no configuration leaking into it.
- **Real test coverage now exists** for Login, Record, Appeal, Request, Guardian, Audit Log, and the security classes (`JwtServiceTest`, `OwnAccessEvaluatorTest`, `RestAccessDeniedHandlerTest`, `RestAuthenticationEntryPointTest`) — a big improvement from "only the default context-load test." **Still no test coverage** for Enrollment, Student, Offense, Disciplinary Action, or Employee Services, and there are no Controller-level (MockMvc/integration) tests anywhere yet — everything tested so far is a Service-level unit test.
- **DTO inconsistency:** Record, Appeal, Request, and Login all go through dedicated request/response DTOs. Guardian, Student, Employee, Offense, and Disciplinary Action all expose the raw JPA entity directly over the API. Not a bug, but worth a team decision — over-posting protection and a stable API contract independent of entity changes are the reasons the DTO pattern exists on the other four.
- **Two "create" conventions coexist:** most entities auto-generate their id and the Service force-resets it to 0 before insert (Record, Appeal, Offense). Student and Employee use a caller-supplied `String` id and reject duplicates. Disciplinary Action uses a caller-supplied `long` id and reject duplicates. All three are internally consistent and correct — just don't assume one pattern applies everywhere when building the frontend's create forms.
- Every write operation across Record, Appeal, and Request now logs to `AuditLogService` — Student, Employee, Offense, and Disciplinary Action writes do not. Worth deciding if catalog/account changes should be audited too, or if audit logging is meant to stay scoped to student-facing disciplinary actions only.

### Suggested build order from here
1. Decide the DTO-consistency question (Guardian/Student/Employee/Offense/DisciplinaryAction) before the frontend team builds against these endpoints — changing the contract later means rework on both sides.
2. Add the missing Offense/DisciplinaryAction existence validation to `RecordServiceImpl.createStudentRecord`/`updateStudentRecord` (the one carried-over gap from the last review).
3. Add Controller-level integration tests (MockMvc) for at least Login, Record, and Appeal — the highest-traffic, highest-risk endpoints — since only Service-level unit tests exist today.
4. Decide whether Student/Employee/Offense/DisciplinaryAction writes should also go through `AuditLogService` for consistency with Record/Appeal/Request.

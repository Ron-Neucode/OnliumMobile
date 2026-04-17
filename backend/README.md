# Onlium Mobile Backend

This folder contains the backend design files for the `onlium_mobile` Flutter app.

## Goal

Build a SQL Server-backed API for the mobile app, using Swagger for documentation.

## Recommended stack

- Backend: ASP.NET Core Web API
- Database: SQL Server (managed with SSMS)
- API docs: Swagger / OpenAPI
- Mobile client: Flutter calling REST endpoints with `http` or `dio`

## Steps

1. Create the SQL Server database using `backend/database/onlium.sql`.
2. Create an ASP.NET Core Web API project.
3. Add Swagger support with `Swashbuckle.AspNetCore`.
4. Implement auth and enrollment endpoints.
5. Update `onlium_mobile` to call the API instead of using local `SharedPreferences`.

## Files

- `database/onlium.sql` — SQL schema for users, admins, and enrollment requests.
- `openapi/onlium-api.yaml` — initial OpenAPI contract for mobile authentication and enrollments.

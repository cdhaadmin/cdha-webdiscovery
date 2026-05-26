# Docebo API Calls

This document covers the WordPress Docebo integration and the related webinar/event registration flows used alongside it.

Current code paths:
- `src/api/profile/docebo.ts`
- `src/containers/profile/profileTableOnDemandWebinarsContainer.tsx`
- `src/components/profile/route/profile/display.tsx`
- `src/containers/conference/zoomJoinContainer.tsx`
- `src/api/webinarAlert/registerForEvent.ts`
- `packages/cdha-api/src/routes/apiv1/authenticated/docebo/token/token.*`
- `packages/cdha-api/src/routes/apiv1/authenticated/events/events.*`

## API Inventory

| Purpose | Method | Endpoint | Auth | Request | Response | Used By |
| --- | --- | --- | --- | --- | --- | --- |
| Generate Docebo SSO token | `GET` | `{newHostUrl}/v1/authenticated/docebo/token` | Bearer token from `getCDHAClientToken()` | No body | `{ access_token, expires_in, token_type, scope }` | `getData()` in `src/api/profile/docebo.ts` |
| Exchange CDHA member identity for Docebo access token | `POST` | `https://cdha.docebosaas.com/oauth2/token` | JWT bearer assertion in request body | `grant_type`, `scope`, `assertion` as form data | Docebo OAuth token payload | `getDoceboToken()` in `packages/cdha-api/src/lib/docebo/oauthToken.ts` |
| Load current Docebo user session | `GET` | `https://cdha.docebosaas.com/manage/v1/user/session` | Docebo bearer token | No body | `{ data: { id, ... } }` | `getDoceboUser()` in `src/api/profile/docebo.ts` |
| Load current Docebo enrollments | `GET` | `https://cdha.docebosaas.com/learn/v1/enrollments?id_user[]={userId}&page_size=200` | Docebo bearer token | `userId` in the query string | `{ data: { items: DoceboEnrollment[] } }` | `getDoceboEnrollmentData()` in `src/api/profile/docebo.ts` |
| Check legacy webinar registration | `POST` | `{hostUrl}/getmemberpd.ashx?filter=EVENT` | Cookie-based session with `withCredentials: true` | Empty body | `{ pd_data: [...] }` | `getRegisteredEventData()` in `src/api/webinarAlert/getRegisteredEventData.ts` |
| Register legacy webinar attendee | `POST` | `{hostUrl}/ConnectRegister.ashx` | Cookie-based session with `withCredentials: true` | `{ scoId }` | Legacy Connect registration response | `registerForEvent()` in `src/api/webinarAlert/registerForEvent.ts` |
| Generate Zoom webinar token | `POST` | `https://api.cdha.ca/v1/graphql` | None at the HTTP layer; GraphQL mutation uses the current member id | `mutation GenerateToken(payload: { id })` | GraphQL `GenerateToken` string | `ZoomJoinContainer` in `src/containers/conference/zoomJoinContainer.tsx` |
| Register attendee to Zoom webinar | `POST` | `https://api.cdha.ca/v1/graphql` | GraphQL token from the previous mutation | `mutation ZoomRegisterEvent(...)` | `data.ZoomRegisterEvent` including `join_url` | `ZoomJoinContainer` in `src/containers/conference/zoomJoinContainer.tsx` |
| Register member for a CDHA event | `POST` | `{newHostUrl}/v1/authenticated/event/:id/register` | Bearer token from `getCDHAClientToken()` and iMIS token on the backend | `eventRegistrationSchema` | `success: true, data: registration` | `registerUserToEvent()` in `packages/cdha-api/src/routes/apiv1/authenticated/events/events.handlers.ts` |
| Get current event registration | `GET` | `{newHostUrl}/v1/authenticated/event/:id` | Bearer token from `getCDHAClientToken()` and iMIS token on the backend | `id` in the path | Event registration payload with status, registrant data, event data, and optional Zoom data | `getEvent()` in `events.handlers.ts` |
| Re-register Zoom attendance | `POST` | `{newHostUrl}/v1/authenticated/event/:id/re-register-zoom` | Bearer token from `getCDHAClientToken()` and iMIS token on the backend | `id` in the path | Updated registration payload | `reRegisterZoom()` in `events.handlers.ts` |
| Get Zoom access link | `GET` | `{newHostUrl}/v1/authenticated/event/:id/zoom-access-link` | Bearer token from `getCDHAClientToken()` and iMIS token on the backend | `id` in the path | `{ access_link: string }` | `getZoomAccessLink()` in `events.handlers.ts` |
| Lookup event by party and event code | `GET` | `{newHostUrl}/v1/authenticated/event/:partyId/:eventCode` | Bearer token from `getCDHAClientToken()` and iMIS token on the backend | `partyId`, `eventCode` in the path | `{ success: true, data: [...] }` | `getEventByPartyIdAndEventCode()` in `events.handlers.ts` |

## 1. Docebo SSO Token

| Field | Value |
| --- | --- |
| Method | `GET` |
| Endpoint | `{newHostUrl}/v1/authenticated/docebo/token` |
| Auth | Bearer token from `getCDHAClientToken()` |
| Request input | No body |
| Response | `{ access_token, expires_in, token_type, scope }` |
| Used by | `getData()` in `src/api/profile/docebo.ts` |

### Purpose

This is the CDHA-side SSO entry point for Docebo. It returns the Docebo access token used for the user session and course lookups.

### Response shape

```json
{
  "access_token": "string",
  "expires_in": 3600,
  "token_type": "Bearer",
  "scope": "api"
}
```

## 2. Docebo OAuth Exchange

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `https://cdha.docebosaas.com/oauth2/token` |
| Auth | JWT bearer assertion in the request body |
| Request input | Form data with `grant_type`, `scope`, `assertion` |
| Response | Docebo OAuth token payload |
| Used by | `getDoceboToken()` in `packages/cdha-api/src/lib/docebo/oauthToken.ts` |

### Purpose

The backend signs a JWT for the current party and exchanges it with Docebo for a usable OAuth access token.

### Request details

- `grant_type = urn:ietf:params:oauth:grant-type:jwt-bearer`
- `scope = api`
- `assertion = <RS256 signed JWT>`

### JWT claims

- `iss`: configured Docebo SSO app name
- `sub`: current CDHA party id
- `aud`: `cdha.docebosaas.com`
- `iat`: issue time
- expiration: 2 days

## 3. Current Docebo User and Enrollments

| Field | Value |
| --- | --- |
| Method | `GET` |
| Endpoint | `https://cdha.docebosaas.com/manage/v1/user/session` |
| Auth | Docebo bearer token |
| Request input | No body |
| Response | `{ data: { id, ... } }` |
| Used by | `getDoceboUser()` in `src/api/profile/docebo.ts` |

The frontend uses this to resolve the Docebo user id.

| Field | Value |
| --- | --- |
| Method | `GET` |
| Endpoint | `https://cdha.docebosaas.com/learn/v1/enrollments?id_user[]={userId}&page_size=200` |
| Auth | Docebo bearer token |
| Request input | `userId` in the query string |
| Response | `{ data: { items: DoceboEnrollment[] } }` |
| Used by | `getDoceboEnrollmentData()` in `src/api/profile/docebo.ts` |

The frontend sorts the returned enrollments by enrollment date and uses them to build the current course list.

## 4. Webinar Course Purchase Registration

This is the legacy webinar registration path used by the webinar alert flow.

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/getmemberpd.ashx?filter=EVENT` |
| Auth | Cookie-based session with `withCredentials: true` |
| Request input | Empty body |
| Response | `pd_data` array containing the member’s event/webinar registrations |
| Used by | `getRegisteredEventData()` in `src/api/webinarAlert/getRegisteredEventData.ts` |

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/ConnectRegister.ashx` |
| Auth | Cookie-based session with `withCredentials: true` |
| Request input | `{ scoId }` |
| Response | Legacy Connect registration response |
| Used by | `registerForEvent()` in `src/api/webinarAlert/registerForEvent.ts` |

### Purpose

This pair of calls checks whether a member is already registered for a webinar and registers them when they are not.

### Current UI usage

The webinar alert component checks existing registration first. If none is found, it calls `ConnectRegister.ashx`, then re-checks the registration state before redirecting the user.

## 5. Renewal or Live Event Webinar Registration

The newer live event flow uses Zoom registration through GraphQL. This is the registration path used by the live event profile page and the Zoom join container.

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `https://api.cdha.ca/v1/graphql` |
| Auth | GraphQL-generated token, not a Docebo token |
| Request input | `mutation GenerateToken(payload: { id })` |
| Response | GraphQL `GenerateToken` string |
| Used by | `ZoomJoinContainer` in `src/containers/conference/zoomJoinContainer.tsx` |

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `https://api.cdha.ca/v1/graphql` |
| Auth | GraphQL token returned from the previous mutation |
| Request input | `mutation ZoomRegisterEvent(...)` |
| Response | `data.ZoomRegisterEvent` with `join_url`, `registrant_id`, `topic`, and `start_time` |
| Used by | `ZoomJoinContainer` in `src/containers/conference/zoomJoinContainer.tsx` |

### Purpose

This is the registration flow for live event access when the member is not already registered. It generates a token for the member id and registers the attendee into the Zoom webinar.

### Notes

- The code path is separate from the Docebo token flow.
- This is the current implementation for live event registration in the frontend.
- I did not find a Docebo-native renewal registration endpoint in the current codebase.

## 6. Member Event Registration

This is the authenticated event registration flow exposed by the CDHA API package.

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{newHostUrl}/v1/authenticated/event/:id/register` |
| Auth | Bearer token from `getCDHAClientToken()`; backend also uses iMIS token |
| Request input | `eventRegistrationSchema` |
| Response | `success: true, data: registration` |
| Used by | `registerUserToEvent()` in `events.handlers.ts` |

### Request shape

The payload includes:

- `eventCode`
- `registration_data`
- optional badge fields
- optional directory text and food info
- optional Zoom access fields

### Internal orchestration

The backend registration helper:

1. Loads or creates the member cart
2. Reprices the order through iMIS
3. Updates the cart
4. Creates or updates the event info record

### Related support endpoints

| Method | Endpoint | Purpose |
| --- | --- | --- |
| `GET` | `{newHostUrl}/v1/authenticated/event/:id` | Read the current registration state and metadata |
| `POST` | `{newHostUrl}/v1/authenticated/event/:id/re-register-zoom` | Recreate the Zoom registration for supported webinar events |
| `GET` | `{newHostUrl}/v1/authenticated/event/:id/zoom-access-link` | Fetch the Zoom join link |
| `GET` | `{newHostUrl}/v1/authenticated/event/:partyId/:eventCode` | Lookup event data for a specific member and event |

### Mass registration note

I did not find a dedicated bulk or mass-registration endpoint in the current codebase. The current registration path is single-member, but it accepts multiple event function codes in `registration_data` for the event being registered.

## Page-Level Flow

1. The profile page requests a CDHA bearer token with `getCDHAClientToken()`
2. The frontend calls `{newHostUrl}/v1/authenticated/docebo/token`
3. The backend exchanges the member identity for a Docebo access token
4. The frontend calls Docebo `manage/v1/user/session` to resolve the user id
5. The frontend calls Docebo `learn/v1/enrollments` to load the member’s enrolled courses
6. For webinar-style purchase or alert flows, the frontend checks `getmemberpd.ashx` and may call `ConnectRegister.ashx`
7. For newer live-event registrations, the frontend uses GraphQL Zoom registration
8. For authenticated event workflows, the frontend uses `/v1/authenticated/event/:id/register`

## Notes

- The Docebo SSO flow is separate from the legacy Connect webinar flow and the newer Zoom event flow.
- The current codebase does not expose a dedicated bulk registration endpoint for multiple members.
- The enrollment endpoint is the source of truth for the current list of Docebo courses the member is registered to.

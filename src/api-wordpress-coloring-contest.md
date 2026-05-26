# Coloring Contest API Calls

This document covers the WordPress coloring contest application entry point and the admin APIs shipped in the same package.

Entry point:
- `/home/lalves/dev/cdha/webcomponents/src/applications/coloring-contest/main.tsx`

Package entry:
- `AppContent` renders the public contest submission form
- `features/coloringContestAdmin/*` consumes the admin endpoints in the same API module

## API Inventory

| Purpose | Method | Endpoint | Auth | Request | Response | Used By |
| --- | --- | --- | --- | --- | --- | --- |
| Submit coloring contest entry | `POST` | `{newHostUrl}/v1/ndhwcoloringcontest` | None | JSON payload with contact fields and file metadata | `{ success: true, data: { uploadUrl, fileId } }` | Public submission form in `applications/coloring-contest/App.tsx` |
| Upload submitted file | `PUT` | Presigned `uploadUrl` returned from the submit response | None | Raw file bytes, `Content-Type` matches the uploaded file | HTTP 200 on success | Public submission form after the create call succeeds |
| Acquire client auth token | `POST` | `{newHostUrl}/auth/token` | None at the API level; production also uses the site session bootstrap | JSON body with `code` and `context` | `{ token: string }` | Shared helper for authenticated contest APIs |
| Production auth bootstrap | `POST` | `/api/CDHASessionToken` | Site request verification token | JSON body containing `CDHASessionToken` entity data | Session token payload with a generated `UserCode` | Internal helper used before `{newHostUrl}/auth/token` in production |
| List contest submissions | `GET` | `{newHostUrl}/v1/authenticated/ndhwcoloringcontest/{campaignId}/{status}` | Bearer token from `getCDHAClientToken()` | `campaignId`, `status` in the path; `status` is `uploaded`, `downloaded`, or `deleted` | `{ success: true, data: ColoringContestSubmission[] }` | Admin submissions page |
| Get file download URL | `GET` | `{newHostUrl}/v1/authenticated/ndhwcoloringcontest/{seqn}/file` | Bearer token from `getCDHAClientToken()` | Submission `seqn` in the path | `{ success: true, url: string }` | Admin table download button |
| Mark submission as downloaded | `PUT` | `{newHostUrl}/v1/authenticated/ndhwcoloringcontest/{seqn}/markasdownloaded` | Bearer token from `getCDHAClientToken()` | Submission `seqn` in the path | `{ success: true }` | Admin actions in the submissions table |
| Mark submission as uploaded | `PUT` | `{newHostUrl}/v1/authenticated/ndhwcoloringcontest/{seqn}/markasuploaded` | Bearer token from `getCDHAClientToken()` | Submission `seqn` in the path | `{ success: true }` | Admin actions in the submissions table |
| Mark submission as deleted | `PUT` | `{newHostUrl}/v1/authenticated/ndhwcoloringcontest/{seqn}/markasdeleted` | Bearer token from `getCDHAClientToken()` | Submission `seqn` in the path | `{ success: true }` | Admin actions in the submissions table |

## 1. Public Submission

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{newHostUrl}/v1/ndhwcoloringcontest` |
| Auth | None |
| Request input | Contest registration fields and file metadata |
| Response | `{ success: true, data: { uploadUrl, fileId } }` |
| Used by | `submitColoringContestEntry()` in `src/api/coloringContestApi.ts` |

### Request shape

The client sends:

```json
{
  "campaignId": "NDHW_2026",
  "contact_type": "Parent/Guardian",
  "email": "parent@example.com",
  "first_name": "Jane",
  "hygienist_name": "",
  "last_name": "Doe",
  "phone": "(416) 555-1234",
  "school_clinic": "",
  "fileExtension": "pdf",
  "contentType": "application/pdf"
}
```

### Field mapping

- `role === "parent"` becomes `contact_type: "Parent/Guardian"`
- `role === "staff"` becomes `contact_type: "School Staff/Dental Office"`
- `campaignId` comes from the web component prop and currently defaults to `NDHW_2026`
- `fileExtension` is derived from the selected file name
- `contentType` is taken from the browser file object

### Response handling

The API does not upload the file itself. It returns a presigned `uploadUrl`, which the client uses for a second request.

## 2. Presigned File Upload

| Field | Value |
| --- | --- |
| Method | `PUT` |
| Endpoint | Presigned `uploadUrl` from the create response |
| Auth | None |
| Request input | Raw file bytes |
| Response | HTTP 200 on success |
| Used by | `submitColoringContestEntry()` |

### Purpose

After the create call succeeds, the client uploads the file directly to the returned URL with `Content-Type` set to the selected file's MIME type.

### Validation before upload

The form schema accepts:
- JPG
- PNG
- PDF
- HEIC
- HEIF
- ZIP

The file must also be 15 MB or smaller.

## 3. Auth Token Bootstrap

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{newHostUrl}/auth/token` |
| Auth | None at API level |
| Request input | `{ code, context }` |
| Response | `{ token: string }` |
| Used by | `getCDHAClientToken()` inside the admin API helpers |

### Production bootstrap

In production, the helper first calls `/api/CDHASessionToken` with the current site context and request verification token to obtain a one-time `UserCode`. It then posts that code to `{newHostUrl}/auth/token`.

### Development bootstrap

In development, the helper uses a local in-memory client context and posts directly to `{newHostUrl}/auth/token`.

## 4. List Contest Submissions

| Field | Value |
| --- | --- |
| Method | `GET` |
| Endpoint | `{newHostUrl}/v1/authenticated/ndhwcoloringcontest/{campaignId}/{status}` |
| Auth | Bearer token |
| Request input | `campaignId` and `status` in the path |
| Response | `{ success: true, data: ColoringContestSubmission[] }` |
| Used by | `features/coloringContestAdmin/AdminPage.tsx` |

### Status values

The admin UI requests one of:
- `uploaded`
- `downloaded`
- `deleted`

### Response shape

Each submission record includes:
- `campaignId`
- `contact_type`
- `created_at`
- `email`
- `fileId`
- `first_name`
- `hygienist_name`
- `last_name`
- `phone`
- `school_clinic`
- `seqn`
- `status`
- `file_extension`
- `content_type`
- optional `downloadUrl`

## 5. Get File Download URL

| Field | Value |
| --- | --- |
| Method | `GET` |
| Endpoint | `{newHostUrl}/v1/authenticated/ndhwcoloringcontest/{seqn}/file` |
| Auth | Bearer token |
| Request input | Submission `seqn` |
| Response | `{ success: true, url: string }` |
| Used by | `features/coloringContestAdmin/AdminTable.tsx` |

### Purpose

The admin table download button calls this endpoint before opening the file in a new tab.

## 6. Update Submission Status

| Field | Value |
| --- | --- |
| Method | `PUT` |
| Endpoint | `{newHostUrl}/v1/authenticated/ndhwcoloringcontest/{seqn}/{endpoint}` |
| Auth | Bearer token |
| Request input | Submission `seqn` and a target status |
| Response | `{ success: true }` |
| Used by | `features/coloringContestAdmin/AdminPage.tsx` |

### Endpoint mapping

- `downloaded` -> `markasdownloaded`
- `uploaded` -> `markasuploaded`
- `deleted` -> `markasdeleted`

### Admin actions using this call

- Mark as Downloaded
- Revert to Uploaded
- Delete
- Revert to Downloaded

## Page-Level Flow

1. The public app loads with `campaign_id="NDHW_2026"` and `contest_page_url="https://www.cdha.ca/coloring-contest"`
2. The user fills out the contest form and selects a file
3. The client posts the metadata to `{newHostUrl}/v1/ndhwcoloringcontest`
4. The API returns a presigned upload URL
5. The client uploads the file with `PUT` to that URL
6. On success, the UI switches to the thank-you state
7. The admin page uses the authenticated list/download/status endpoints to review and manage submissions

## Notes

- The public contest page does not require authentication.
- The admin helpers all use the shared CDHA client token flow.
- The file upload is not sent to the API host directly; it is sent to the presigned URL returned from the create call.

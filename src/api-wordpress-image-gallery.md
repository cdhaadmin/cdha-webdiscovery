# Image Gallery API Calls

This document covers the WordPress image gallery application entry point and the API helpers used by the gallery UI.

Entry point:
- `/home/lalves/dev/cdha-sst/packages/image-gallery/src/App.tsx`

Client entry:
- `App.tsx` renders `components/ImageGallery.tsx`
- `src/lib/api/imageGallery.ts` contains the gallery list, upload URL, and delete helpers
- `src/lib/api/memberInfo.ts` loads the current member record for upload gating
- `src/lib/token.ts` provides the shared CDHA client token flow

Current gallery code used by the app:
- `PYPO2026`

## API Inventory

| Purpose | Method | Endpoint | Auth | Request | Response | Used By |
| --- | --- | --- | --- | --- | --- | --- |
| List gallery images | `GET` | `{newHostUrl}/v1/imagegallery/{galleryCode}` | None | `galleryCode` in the path | `{ success: true, data: any[] }` | Public gallery load in `components/ImageGallery.tsx` |
| Load current member info | `GET` | `{newHostUrl}/v1/authenticated/memberInfo` | Bearer token | No body | `{ data: MemberInfo }` | Upload button gating in `components/ImageGallery.tsx` |
| Acquire client auth token | `POST` | `{newHostUrl}/auth/token` | None at the API level | JSON body with `code` and `context` | `{ token: string }` | Shared helper for authenticated gallery calls |
| Production auth bootstrap | `POST` | `/api/CDHASessionToken` | Site request verification token | iMIS generic entity payload for `CDHASessionToken` | Session token payload with a generated `UserCode` | Internal helper used before `{newHostUrl}/auth/token` in production |
| Request presigned upload URL | `POST` | `{newHostUrl}/v1/authenticated/imagegallery/{galleryCode}/generate-upload-url` | Bearer token | JSON body with file metadata | `{ success: true, url: string }` | Upload flow in `components/ImageGallery.tsx` |
| Upload file to storage | `PUT` | Presigned `url` returned from the upload-url request | None | Raw file bytes with matching `Content-Type` | HTTP 200 on success | Upload flow in `components/ImageGallery.tsx` |
| Delete gallery image | `DELETE` | `{newHostUrl}/v1/authenticated/imagegallery/{galleryCode}/delete-image/{imageId}` | Bearer token | `galleryCode` and `imageId` in the path | `{ success: true, message: string }` | Delete branch in `components/ImageGallery.tsx` |

## 1. Public Gallery Listing

| Field | Value |
| --- | --- |
| Method | `GET` |
| Endpoint | `{newHostUrl}/v1/imagegallery/{galleryCode}` |
| Auth | None |
| Request input | `galleryCode` in the path |
| Response | `{ success: true, data: any[] }` |
| Used by | `getImagesFromGallery()` in `src/lib/api/imageGallery.ts` |

### Purpose

This is the initial page load for the gallery. The app uses it to render the image grid and video thumbnails for the active gallery.

### Current usage

The current app hard-codes `galleryCode: 'PYPO2026'`.

### Response shape

The backend route returns an array of image records. The route type is loose (`any[]`), but the client currently relies on these fields:

- `id`
- `userId`
- `fileExtension`
- `contentType`
- `height`

The gallery UI uses `contentType` to decide whether to render an `img` or a `video`, and it uses `fileExtension` and `id` to build the public file URL.

### Error responses

The backend route also exposes `404` when the gallery does not exist and `500` for server errors.

## 2. Member Info Lookup

| Field | Value |
| --- | --- |
| Method | `GET` |
| Endpoint | `{newHostUrl}/v1/authenticated/memberInfo` |
| Auth | Bearer token |
| Request input | No body |
| Response | `{ data: MemberInfo }` |
| Used by | `getMemberInfo()` in `src/lib/api/memberInfo.ts` |

### Purpose

The gallery page uses the current member record to decide whether to show the upload action. If no member id is returned, the UI falls back to the public sign-in link.

### Response shape

The backend returns a large `MemberInfo` payload. The gallery page only consumes:

- `data.id`

Other fields are returned by the API but are not used directly by this page.

## 3. Auth Token Bootstrap

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{newHostUrl}/auth/token` |
| Auth | None at API level |
| Request input | `{ code, context }` |
| Response | `{ token: string }` |
| Used by | `getCDHAClientToken()` in `src/lib/token.ts` |

### Production bootstrap

In production, the helper first calls `/api/CDHASessionToken` with the current site context and request verification token to get a one-time `UserCode`. It then posts that code to `{newHostUrl}/auth/token`.

### Development bootstrap

In development, the helper skips `/api/CDHASessionToken` and posts a hard-coded dev context directly to `{newHostUrl}/auth/token`.

## 4. Production Session Token Bootstrap

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `/api/CDHASessionToken` |
| Auth | `RequestVerificationToken` header |
| Request input | iMIS generic entity payload for `CDHASessionToken` |
| Response | Session token payload containing the generated `UserCode` |
| Used by | `getCDHAClientToken()` in production |

### Purpose

This is the iMIS-side bootstrap call used to generate the `UserCode` that is exchanged for a CDHA API token.

## 5. Request Presigned Upload URL

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{newHostUrl}/v1/authenticated/imagegallery/{galleryCode}/generate-upload-url` |
| Auth | Bearer token |
| Request input | JSON body with file metadata |
| Response | `{ success: true, url: string }` |
| Used by | `requestUploadUrl()` in `src/lib/api/imageGallery.ts` |

### Request shape

```json
{
  "filename": "photo.jpg",
  "contentType": "image/jpeg",
  "fileExtension": "jpg",
  "size": 245881
}
```

### Current usage

The current app posts this request before each upload. The gallery code is fixed to `PYPO2026` in the client.

### Error responses

The backend route defines `401` for unauthorized access and `500` for server errors.

## 6. Upload File to Storage

| Field | Value |
| --- | --- |
| Method | `PUT` |
| Endpoint | Presigned `url` returned from the upload-url request |
| Auth | None |
| Request input | Raw file bytes |
| Response | HTTP 200 on success |
| Used by | The upload loop in `components/ImageGallery.tsx` |

### Purpose

The API host does not receive the file body directly. The client uploads the file to the presigned storage URL returned by the previous call.

### Upload behavior

The client sets the `Content-Type` header to the selected file MIME type and retries the gallery view after a short delay once the upload completes.

## 7. Delete Gallery Image

| Field | Value |
| --- | --- |
| Method | `DELETE` |
| Endpoint | `{newHostUrl}/v1/authenticated/imagegallery/{galleryCode}/delete-image/{imageId}` |
| Auth | Bearer token |
| Request input | `galleryCode` and `imageId` in the path |
| Response | `{ success: true, message: string }` |
| Used by | Delete branch in `components/ImageGallery.tsx` |

### Current UI state

The delete button exists in the component, but it is currently gated off because `isAdmin` is hard-coded to `false`.

### Error responses

The backend route also exposes `401`, `403`, `404`, and `500`.

## Page-Level Flow

1. The gallery page mounts and loads `getMemberInfo()` and `getImagesFromGallery({ galleryCode: 'PYPO2026' })`
2. The public image list renders as soon as the gallery request resolves
3. If the member lookup returns an `id`, the upload button is shown
4. When a file is selected, the client calls `generate-upload-url`
5. The client uploads the file to the presigned storage URL with `PUT`
6. After upload, the gallery list is refetched
7. The delete flow exists in code but is not currently exposed because `isAdmin` is `false`

## Notes

- The public gallery request does not require authentication.
- The member lookup and upload/delete helpers all share the same token bootstrap.
- The rendered media URLs are direct file URLs on `files.cdha.ca`, not API calls.

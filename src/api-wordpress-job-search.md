# Job Search API Calls

## Purpose

This page documents the API calls used by the career-centre job search flow mounted from `/home/lalves/dev/frontend/src/jobSearchPage.tsx`.

The page shell renders `components/job/jobSearchRoute.tsx`, which mounts the province search UI, the results display, and the email-notification signup block.

## Base URLs

| Alias | Value | Used for |
| --- | --- | --- |
| `hostUrl` | `https://www.cdha.ca/CDHACommon` in development, `//{window.location.hostname}/CDHACommon` in production | Legacy Wicket/iMIS `.ashx` endpoints |
| `newHostUrl` | `https://api.lalves.mycdha.ca` in development, `https://api.imisdev.mycdha.ca` on `imisdev`, otherwise `https://api.mycdha.ca` | Lookup table API |

## Authentication

| API family | Authentication |
| --- | --- |
| Legacy Wicket/iMIS `.ashx` | Browser session cookies via `withCredentials: true` |
| Lookup API | No auth for the country table read |

## Page Flow

| Step | API call | Notes |
| --- | --- | --- |
| Page bootstrap | `GET {newHostUrl}/v1/lookupdata?table=COUNTRY` | Loads the province list used by the search selector and the notification signup block |
| Page bootstrap | `GET {hostUrl}/UpdateCommunications.ashx` | Loads the current communication preferences for the email-notification block |
| Search results | `POST {hostUrl}/GetJobAds.ashx` | Loads the job list for the selected province |
| Update notifications | `POST {hostUrl}/UpdateCommunications.ashx` | Persists the selected job-notification province |
| Legacy detail view | `POST {hostUrl}/GetJobAdDetail.ashx?SEQN={id}` | Present in the repo, but not mounted by the current search page shell |

## Detailed Calls

### Load Country Lookup

| Field | Value |
| --- | --- |
| Method | `GET` |
| Endpoint | `{newHostUrl}/v1/lookupdata?table=COUNTRY` |
| Authentication | None |
| Request | Query string `table=COUNTRY` |
| Response | `{ data: CountryLookup[] }` |
| Used by | `containers/job/searchContainer.tsx` and `containers/job/emailNotificationSignupContainer.tsx` |

The returned Canada row is used to build the province list, which is extended with `AP` for "All Provinces" and `IN` for "International".

### Load Member Communications

| Field | Value |
| --- | --- |
| Method | `GET` |
| Endpoint | `{hostUrl}/UpdateCommunications.ashx` |
| Authentication | Browser session cookies |
| Request | None |
| Response | `{ data: Communications }` |
| Used by | `containers/job/emailNotificationSignupContainer.tsx` on mount |

This call pre-populates the communication model so the page can show whether the member is already subscribed.

### Update Job Notification Preferences

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/UpdateCommunications.ashx` |
| Authentication | Browser session cookies |
| Request | Communications object plus `is_update: true` |
| Response | `{ data: Communications }` |
| Used by | `components/job/emailNotificationSignup.tsx` when the province selector changes |

The component mutates `communications.job_notification_prov` and then posts the full communications object back to the legacy endpoint.

### Load Job Ads

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/GetJobAds.ashx` |
| Authentication | Browser session cookies |
| Request | JSON object with the selected province filter |
| Response | `{ data: JobAd[] }` |
| Used by | `containers/job/displayContainer.tsx` when the route changes to `/search/:province` |

Request shape:

```json
{
  "province": "ON"
}
```

The route param `AP` is converted to an empty string before sending, which the backend treats as "all provinces".

### Load Job Ad Details

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/GetJobAdDetail.ashx?SEQN={id}` |
| Authentication | Browser session cookies |
| Request | Empty JSON body `{}` |
| Response | `{ ad_data: JobAdDetail }` |
| Used by | `containers/job/jobAdDetailsContainer.tsx` only |

This endpoint is present in the repo, but the current job search page renders the detail panel from the already-loaded list item data instead of calling this endpoint.

## Response Shape

### Job list item

The list and detail components use these fields from each job ad:

```json
{
  "seqn": 123,
  "title": "Job title",
  "created_date": "2026-05-26T00:00:00Z",
  "province": "ON",
  "geographical_area": "Toronto",
  "term": "FULL_TIME",
  "co_name": "Employer name",
  "contact_name": "Contact name",
  "deadline": "2026-06-15T00:00:00Z",
  "start_date": "2026-07-01T00:00:00Z",
  "description": "...",
  "qualifications": "..."
}
```

### Job ad detail

`GetJobAdDetail.ashx` returns a single `ad_data` object with the same core fields plus the full detail payload consumed by `components/job/jobAdDetails.tsx`.

## Where It Is Used

- `jobSearchPage.tsx` bootstraps the page.
- `components/job/jobSearchRoute.tsx` and `containers/job/searchContainer.tsx` wire the province selector.
- `containers/job/displayContainer.tsx` loads the job list.
- `containers/job/emailNotificationSignupContainer.tsx` loads and updates communication preferences.
- `components/job/jobAdsTable.tsx` and `components/job/jobAdDetails.tsx` render the loaded data.

## Open Questions

- The job detail endpoint is still implemented in the repo, but the current search page does not need it because it opens details from the list payload.
- The communication payload is legacy and loosely typed; the client mutates the object in place before submitting it.

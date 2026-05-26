# Job Add API Calls

## Purpose

This page documents the API calls used by the job posting flow mounted from `/home/lalves/dev/frontend/src/jobAddPage.tsx`.

The page shell renders `components/job/jobAddRoute.tsx`, which loads lookup data for the country/province selectors and submits the final ad through `api/job/addJobAd.ts`.

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
| Page bootstrap | `GET {newHostUrl}/v1/lookupdata?table=COUNTRY` | Loads the country record used to derive the province list |
| Submit job ad | `POST {hostUrl}/UpdateJobAd.ashx` | Sends the validated job form payload |
| Success route | none | Client-side route push to `/success` |
| Error route | none | Client-side route push to `/error` |

## Detailed Calls

### Load Country Lookup

| Field | Value |
| --- | --- |
| Method | `GET` |
| Endpoint | `{newHostUrl}/v1/lookupdata?table=COUNTRY` |
| Authentication | None |
| Request | Query string `table=COUNTRY` |
| Response | `{ data: CountryLookup[] }` |
| Used by | `components/job/jobAddRoute.tsx` -> `mapDispatchToProps.onLoadData()` -> `getLookupData(["COUNTRY"])` |

The job add form uses the returned `CountrySubEntities` from the Canada row to build the province dropdown.

### Submit Job Ad

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/UpdateJobAd.ashx` |
| Authentication | Browser session cookies |
| Request | JSON job-ad payload generated in `components/job/add.tsx` |
| Response | Legacy service response; the client reads `response.data.data` and stores it in `addjob.data` |
| Used by | `components/job/add.tsx` submit handler -> `containers/job/addContainer.tsx` -> `api/job/addJobAd.ts` |

The client submits the form fields below, then transforms several of them before sending:

| Form field | Sent as | Notes |
| --- | --- | --- |
| `title` | `title` | Required |
| `term` | `term` | `CONTRACT`, `FULL_TIME`, `PART_TIME`, `PERMANENT`, or `TEMPORARY` |
| `geographical_area` | `geographical_area` | City/location text |
| `province` | `province` | Province code or `IN` |
| `start_date` | `start_date` | `MM/DD/YYYY` string |
| `deadline` | `deadline` | `MM/DD/YYYY` string |
| `co_name` | `co_name` | Employer name |
| `contact_name` | `contact_name` | Contact details text |
| `description` | `description` | Free text |
| `salary` | `salary` | Formatted string built by the client |
| `qualifications` | `qualifications` | Hard-coded to `"N/A"` by the client |
| `lat` | `lat` | Omitted if not a valid numeric latitude |
| `lng` | `lng` | Omitted if not a valid numeric longitude |

Salary is not sent as a structured object. The client builds a single string:

- range: `"$minimum - $maximum/$rate"`
- base: `"$minimum / $rate"`

The payload is posted as JSON and the legacy endpoint returns a nested `data` object. The app does not consume any fields beyond success/error handling.

## Response Shape

The backend response is only partially inferred from the client:

```json
{
  "data": {
    "data": {}
  }
}
```

The reducer stores the inner `data` value as `addjob.data` and then routes to `/success`.

## Where It Is Used

- `jobAddPage.tsx` bootstraps the page.
- `components/job/jobAddRoute.tsx` loads the country lookup and mounts the form route.
- `containers/job/addContainer.tsx` connects the form to the submit thunk.
- `components/job/add.tsx` collects the form fields and calls `onAddJob(...)`.

## Open Questions

- The server response schema for `UpdateJobAd.ashx` is not documented in the client; only the nested `data` field is consumed.
- The form still uses the legacy Wicket/iMIS endpoint instead of a typed JSON API.

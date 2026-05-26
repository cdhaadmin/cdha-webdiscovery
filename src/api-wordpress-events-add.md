# Events Add API Calls

## Purpose

This page documents the API calls used by the event submission flow wired from the event add route in `/home/lalves/dev/frontend/src`.

The repo does not contain a file named `eventsAddPage.tsx`; the actual add workflow is mounted through `components/event/eventAddRoute.tsx` and `containers/event/addContainer.tsx`.

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
| Page bootstrap | `GET {newHostUrl}/v1/lookupdata?table=COUNTRY` | Loads the country list used to build the province selector |
| Submit event | `POST {hostUrl}/UpdateCDHAEvent.ashx` | Sends the validated event form payload |
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
| Used by | `containers/event/rootContainer.tsx` through `getLookupData(["COUNTRY"])` |

The add form uses the Canada row to render province options for countries that require a province/state selection.

### Submit Event Listing

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/UpdateCDHAEvent.ashx` |
| Authentication | Browser session cookies |
| Request | JSON event payload from the add form |
| Response | Legacy service response; the client reads `response.data.data` and stores it in `addEvent.data` |
| Used by | `components/event/add.tsx` submit handler -> `containers/event/addContainer.tsx` -> `api/events/addEvent.ts` |

The client submits the form fields below:

| Form field | Notes |
| --- | --- |
| `name` | Event name |
| `url` | Event website |
| `city` | City |
| `venue` | Venue name |
| `country` | Country code |
| `province` | Province code |
| `is_ongoing` | Boolean-ish checkbox state |
| `start_date` | `MM/DD/YYYY` string when the event is not ongoing |
| `end_date` | `MM/DD/YYYY` string when the event is not ongoing |
| `volunteers_needed` | `"true"` or `"false"` from the select control |
| `description` | Free text, truncated to 1024 characters in the UI |
| `contact_name` | Contact person |
| `email` | Contact email |
| `seqn` | Present in the reducer state, but blank for a new listing |

The submit helper does not perform an additional transformation layer. It posts the form state directly after validation.

## Response Shape

The backend response is only partially inferred from the client:

```json
{
  "data": {
    "data": {}
  }
}
```

The reducer stores the inner `data` value as `addEvent.data` and then routes to `/success`.

## Where It Is Used

- `components/event/eventAddRoute.tsx` mounts the add flow.
- `containers/event/rootContainer.tsx` loads the country lookup.
- `containers/event/addContainer.tsx` validates the form and dispatches the submit thunk.
- `components/event/add.tsx` renders the form and collects the payload.

## Open Questions

- The server response schema for `UpdateCDHAEvent.ashx` is not documented in the client; only the nested `data` field is consumed.
- The requested filename `eventsAddPage.tsx` does not exist in the current tree; the add workflow is wired through `eventAddRoute.tsx`.

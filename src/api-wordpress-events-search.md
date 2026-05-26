# Events Search API Calls

## Purpose

This page documents the API calls used by the event calendar flow mounted from `/home/lalves/dev/frontend/src/eventDisplayPage.tsx`.

The page shell renders `components/event/eventDisplayRoute.tsx`, which loads the country lookup in the root container and then fetches the event list for the calendar display.

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
| Page bootstrap | `GET {newHostUrl}/v1/lookupdata?table=COUNTRY` | Triggered by the root container even though the display view does not directly consume the country table |
| Load calendar list | `POST {hostUrl}/GetCDHAEvents.ashx` | Loads the event list for the current calendar view |
| Open item details | none | Detail panels are rendered client-side from the loaded list item |

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

The calendar page does not currently use the lookup data directly, but the call still fires as part of the shared root bootstrap.

### Load Event Calendar

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/GetCDHAEvents.ashx` |
| Authentication | Browser session cookies |
| Request | Empty JSON body `{}` |
| Response | `{ data: EventItem[] }` |
| Used by | `containers/event/displayContainer.tsx` on mount |

The list is grouped in the reducer by month/year, with a dedicated `Ongoing` bucket for items whose `is_ongoing` flag is true.

## Response Shape

### Event item

The event list and detail panels use these fields from each item:

```json
{
  "seqn": 123,
  "name": "Event title",
  "start_date": "2026-05-26T00:00:00Z",
  "end_date": "2026-05-27T00:00:00Z",
  "is_ongoing": false,
  "city": "Toronto",
  "province": "ON",
  "country": "CA",
  "venue": "Venue name",
  "contact_name": "Contact name",
  "email": "contact@example.com",
  "url": "example.com",
  "volunteers_needed": false,
  "description": "...",
  "event_code": "2024CONF"
}
```

### Grouped list shape

The reducer transforms the raw array into grouped pairs:

```json
[
  ["Ongoing", [/* ongoing events */]],
  ["May 2026", [/* dated events */]]
]
```

## Where It Is Used

- `eventDisplayPage.tsx` bootstraps the page.
- `components/event/eventDisplayRoute.tsx` mounts the display route.
- `containers/event/rootContainer.tsx` loads the country lookup.
- `containers/event/displayContainer.tsx` fetches and groups the events.
- `components/event/eventsDisplay.tsx`, `eventsDisplayItem.tsx`, and `eventDetails.tsx` render the result set.

## Open Questions

- The event search page currently loads country lookup data even though the rendered view does not use it directly.
- The detail panel is entirely client-side once the list is loaded; there is no separate event-detail request in the active page path.

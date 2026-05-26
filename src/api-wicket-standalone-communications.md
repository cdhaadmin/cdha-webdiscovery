# Wicket API Calls - Standalone Communications Preference Edit

This page is the standalone communications preference editor in the Wicket section.

Entry point:
- `/home/lalves/dev/frontend/src/standAloneCommunicationsPreferenceEditPage.tsx`

Route flow:
- `standAloneCommunicationsPreferenceEditPage.tsx` renders `EditCommunicationsRoute`
- `EditCommunicationsRoute` reads the `email` parameter and redirects to `/:email`
- `EditStandAloneCommunicationsContainer` loads the lookup data and current communications record
- The user edits the communications form and clicks Update
- The update action writes the record back and then reloads communications from the server

## API Inventory

| Purpose | Method | Endpoint | Auth | Input | Output | Where Used |
| --- | --- | --- | --- | --- | --- | --- |
| Load lookup tables | `GET` | `{newHostUrl}/v1/lookupdata?table=COUNTRY` | None | Query string `table=COUNTRY` | `{ data: LookupRow[] }` | Used by the standalone container to build the Canadian province list |
| Load current communications | `GET` | `{hostUrl}/UpdateCommunications.ashx` | `withCredentials: true` session cookie | None | `{ data: Communications }` | Used when the email route mounts |
| Update communications | `POST` | `{hostUrl}/UpdateCommunications.ashx` | `withCredentials: true` session cookie | Communications payload plus `email_address`, `is_update`, and `is_enews_subscribeupdate` | `{ data: Communications }` | Triggered by the Update button |

## 1. Load Lookup Tables

| Field | Value |
| --- | --- |
| Method | `GET` |
| Endpoint | `{newHostUrl}/v1/lookupdata?table=COUNTRY` |
| Auth | None |
| Request input | `table=COUNTRY` |
| Response | `{ data: LookupRow[] }` |
| Used by | `containers/standAloneCommunications/editStandAloneCommunicationsContainer.tsx` |

### Purpose

The page only needs the Canada record from the `COUNTRY` lookup table. The container picks the item whose `CountryCode === "CA"` and uses that to populate the province selector in the communications form.

### Notes

The lookup call is made through `getLookupData(["COUNTRY"])`, so the response is normalized into `state.lookupData.COUNTRY.data`.

## 2. Load Current Communications

| Field | Value |
| --- | --- |
| Method | `GET` |
| Endpoint | `{hostUrl}/UpdateCommunications.ashx` |
| Auth | `withCredentials: true` session cookie |
| Request input | None |
| Response | `{ data: Communications }` |
| Used by | `containers/standAloneCommunications/editStandAloneCommunicationsContainer.tsx` |

### Purpose

The container loads the current communications record for the email in the route, then hydrates the `communications` redux form state.

### Response handling

The helper expects a top-level `data` property. If the returned `communications.email_address` does not match the route email, the page redirects to the main profile application because the user is already authenticated in the normal Wicket profile flow.

## 3. Update Communications

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/UpdateCommunications.ashx` |
| Auth | `withCredentials: true` session cookie |
| Request input | Communications object from the form, plus `email_address`, `is_update: true`, and `is_enews_subscribeupdate: true` |
| Response | `{ data: Communications }` |
| Used by | Update button in `containers/standAloneCommunications/editStandAloneCommunicationsContainer.tsx` |

### Request shape

The click handler sends the current communications state plus:

```json
{
  "benefit_subscribe": true,
  "campaign_subscribe": false,
  "enews_subscribe": true,
  "job_notification_prov": "ON",
  "pd_subscribe": true,
  "products_subscribe": false,
  "receive_communications": true,
  "third_party": false,
  "eventcal_updated": "...",
  "eventcal_subscribe": true,
  "email_address": "member@example.com",
  "is_update": true,
  "is_enews_subscribeupdate": true
}
```

### Helper behavior

`updateCommunicationsData.ts` normalizes the payload before sending it:
- numeric `0` and `1` values are converted to booleans
- `eventcal_updated` is forced to a fixed C# date string
- any other `*_updated` fields are removed before posting

### Response handling

On success, the helper dispatches `updateMemberCommunicationsDataSuccess`, then refreshes communications with a second `GET {hostUrl}/UpdateCommunications.ashx`.

## Open Notes

- This page is not wrapped in the shared profile bootstrap, so it does not call member-info, education, expertise, or auto-renewal APIs.
- The email route is the primary access key for this flow.

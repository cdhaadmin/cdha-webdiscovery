# Wicket API Calls - Upgrade STU to Grad

This page is the student-to-graduate upgrade flow in the Wicket section.

Entry point:
- `/home/lalves/dev/frontend/src/upgradeStuToGradPage.tsx`

Route flow:
- `upgradeStuToGradPage.tsx` renders `UpgradeStuToGradRoute`
- `UpgradeStuToGradRoute` wraps the flow in `RootContainer`
- `RootContainer` preloads the shared member bootstrap and then the route-specific education form
- `Validations type="UPGRADE_STU_GRAD"` only allows student members in Canada
- The form submit updates member info, processes the upgrade, refreshes education, and then redirects out of the page

## API Inventory

| Purpose | Method | Endpoint | Auth | Input | Output | Where Used |
| --- | --- | --- | --- | --- | --- | --- |
| Load lookup tables | `GET` | `{newHostUrl}/v1/lookupdata?table={table}` | None | Query string `table` | `{ data: LookupRow[] }` | Shared bootstrap via `RootContainer` |
| Load member info | `POST` | `{hostUrl}/UpdatePersonalInfo.ashx` | `withCredentials: true` session cookie | `{ get_summaryonly: true }` | `{ data: MemberInfo, server_time? }` | Shared bootstrap via `RootContainer` |
| Load orofacial question | `GET` | `{newHostUrl}/v1/authenticated/cdhaquestions/OROFACIAL_STATUS` | CDHA bearer token | None | `{ data: QuestionAnswer[] }` | Indirect follow-up from `getMemberInfoData` |
| Load expertise | `GET` | `{newHostUrl}/v1/authenticated/expertise` | CDHA bearer token | None | `{ data: Expertise[] }` | Shared bootstrap via `RootContainer` |
| Load education | `GET` | `{newHostUrl}/v1/authenticated/education` | CDHA bearer token | None | `{ data: Education[] }` | Shared bootstrap via `RootContainer` and post-delete refresh |
| Load communications | `GET` | `{hostUrl}/UpdateCommunications.ashx` | `withCredentials: true` session cookie | None | `{ data: Communications }` | Shared bootstrap via `RootContainer` |
| Load auto-renewal | `POST` | `{hostUrl}/UpdateAutoRenew.ashx` | `withCredentials: true` session cookie | Empty body | `{ data: AutoRenewalSubscription }` | Shared bootstrap via `RootContainer` |
| Update member info | `POST` | `{hostUrl}/UpdatePersonalInfo.ashx` | `withCredentials: true` session cookie | `{ id, chapter }` | `{ data: MemberInfo }` | First step in the upgrade submit chain when the province changes |
| Process upgrade | `POST` | `{hostUrl}/ProcessUpgrade.ashx` | `withCredentials: true` session cookie | `{ member_type, ndhcb_id }` | `{ errors?, ... }` | Core upgrade call for the student-to-grad flow |
| Update education | `DELETE` | `{newHostUrl}/v1/authenticated/education/{seqn}` | CDHA bearer token | Education sequence number | `{ data: ... }` | Current code path after the upgrade call |
| Refresh education | `GET` | `{newHostUrl}/v1/authenticated/education` | CDHA bearer token | None | `{ data: Education[] }` | Called after the delete helper completes |

## 1. Shared Bootstrap

| Field | Value |
| --- | --- |
| Method | `GET` and `POST` |
| Endpoint group | `{newHostUrl}/v1/lookupdata?table={table}`, `{hostUrl}/UpdatePersonalInfo.ashx`, `{newHostUrl}/v1/authenticated/expertise`, `{newHostUrl}/v1/authenticated/education`, `{hostUrl}/UpdateCommunications.ashx`, `{hostUrl}/UpdateAutoRenew.ashx`, `{newHostUrl}/v1/authenticated/cdhaquestions/OROFACIAL_STATUS` |
| Used by | `components/profile/route/upgradeStuToGradRoute.tsx` through `containers/profile/rootContainer.tsx` |

### Lookup tables requested on mount

`RootContainer` loads the same base profile lookups used by join and renew:
- `COUNTRY`
- `DEGREES`
- `UNIVERSITY`
- `GRAD_YEAR`
- `GRAD_MONTH`
- `YEAR_ATTEND`
- `AREAS_OF_PRACTICE`
- `WORK_ENVIRONMENT`
- `INSURANCE`
- `IPN_STATUS`
- `INDIGENOUS_STATUS`

### Why they are loaded

The upgrade form uses `DEGREES`, `UNIVERSITY`, `GRAD_MONTH`, `GRAD_YEAR`, `YEAR_ATTEND`, and `COUNTRY` to seed and validate the education fields. The shared bootstrap also loads the rest of the profile state because the route reuses the common Wicket container and validation layer.

### Member info follow-up

`getMemberInfoData({ isSummary: true })` posts `get_summaryonly: true` to `UpdatePersonalInfo.ashx` and then always fetches the orofacial question endpoint. The response is merged into the member-info store for validation and form prefill.

## 2. Update Member Info

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/UpdatePersonalInfo.ashx` |
| Auth | `withCredentials: true` session cookie |
| Request input | `{ id, chapter }` |
| Response | `{ data: MemberInfo }` |
| Used by | `api/profile/processUpgradeToGrad.ts` |

### Purpose

The submit handler updates the member chapter before processing the upgrade if the selected province of practice differs from the member's current chapter.

### Follow-up

`updateMemberInfoData.ts` refreshes member info again after the update, so this flow performs a second `POST {hostUrl}/UpdatePersonalInfo.ashx` through `getMemberInfoData()` during the refresh step.

## 3. Process Upgrade

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/ProcessUpgrade.ashx` |
| Auth | `withCredentials: true` session cookie |
| Request input | `{ member_type, ndhcb_id }` |
| Response | Legacy Wicket upgrade response |
| Used by | `api/profile/processUpgradeToGrad.ts` |

### Request shape

The current page passes one of these combinations:
- `/upgrade/STU` path: `{ member_type: "FM", ndhcb_id: undefined }`
- `/upgradeToGrad` path: `{ member_type: "GRAD", ndhcb_id: <value from form> }`

### Purpose

This is the legacy upgrade step that moves the member into the new membership state before the education record is refreshed.

## 4. Update Education

| Field | Value |
| --- | --- |
| Method | `DELETE` |
| Endpoint | `{newHostUrl}/v1/authenticated/education/{seqn}` |
| Auth | CDHA bearer token |
| Request input | Education sequence number |
| Response | `{ data: ... }` |
| Used by | Imported helper in `api/profile/processUpgradeToGrad.ts` |

### Important note

The current implementation imports `removeEducationData.ts` as `UpdateEducationData`, then calls it with an `update` payload instead of the `remove` shape that the helper expects. As written, that means the generated endpoint can resolve to `/education/undefined` unless another layer transforms the payload.

This is the clearest wiring issue in the current page flow.

## 5. Refresh Education

| Field | Value |
| --- | --- |
| Method | `GET` |
| Endpoint | `{newHostUrl}/v1/authenticated/education` |
| Auth | CDHA bearer token |
| Request input | None |
| Response | `{ data: Education[] }` |
| Used by | `api/profile/removeEducationData.ts` |

### Purpose

After the delete helper succeeds, it immediately reloads education so the store reflects the latest saved record before the route redirects away.

## Page-Level Submit Sequence

1. Redirect to `/processingAccount`
2. Update member chapter with `UpdatePersonalInfo.ashx` if the province changed
3. Post `ProcessUpgrade.ashx`
4. Call the education helper, which currently attempts to delete the existing education record
5. Refresh education with `GET {newHostUrl}/v1/authenticated/education`
6. Redirect to `/guok` when `ndhcb_id` is present, otherwise redirect to `/renew`

## Response Shape Notes

- The validation layer only allows members with `member_type === "STU"`, `country === "CA"`, and a defined `chapter`.
- If the member is not eligible, the route sends the user to the legacy error page instead of letting the form submit.
- The shared bootstrap also loads `autoRenewalSubscription`, even though this specific validation block does not use it directly.

## Open Notes

- The education update path looks like a bug, not a deliberate API contract.
- The visible form only uses the education fields, but the route still loads the full shared profile bootstrap through `RootContainer`.

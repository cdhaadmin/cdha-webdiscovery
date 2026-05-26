# Profile API Calls

## Purpose

This page documents the API calls needed by the Profile application mounted from `/home/lalves/dev/frontend/src/profilePage.tsx`.

The entry point creates the Redux store, React Query client, router, translations, and Sentry. The business API calls are reached through `components/profile/route/profileRoute.tsx` and the Profile display/edit route tree.

## Base URLs

| Alias | Development | Production | Used for |
| --- | --- | --- | --- |
| `hostUrl` | `https://www.cdha.ca/CDHACommon` | `//{window.location.hostname}/CDHACommon` | Legacy Wicket/iMIS `.ashx` endpoints |
| `newHostUrl` | `https://api.lalves.mycdha.ca` | `https://api.imisdev.mycdha.ca` on imisdev, otherwise `https://api.mycdha.ca` | New authenticated JSON API |
| Adobe Connect proxy | `https://www.imisdev.cdha.ca/CDHACommon/SendConnectRequest.ashx` | `//{window.location.hostname}/CDHACommon/SendConnectRequest.ashx` | Adobe Connect XML API proxy |
| Adobe Connect direct | `https://cdha.adobeconnect.com/api/xml` | Same | Only used when `insideConnect` is set |
| Docebo | `https://cdha.docebosaas.com` | Same | Docebo user session/enrollment data and course launch links |

## Authentication

| API family | Authentication |
| --- | --- |
| Legacy Wicket/iMIS `.ashx` | Browser session cookies. Axios uses `withCredentials: true`; `api/fetch/*` uses `credentials: "include"`. |
| New `newHostUrl` API | `Authorization: Bearer {CDHA_CLIENT_TOKEN}` from `util/token.ts`. Token is stored in `localStorage` under `CDHA_CLIENT_TOKEN`. |
| Docebo API | Docebo access token returned by `GET {newHostUrl}/v1/authenticated/docebo/token`. |
| Adobe Connect API | Adobe Connect `session` query value from profile PD/eLearning rows. |

### Client Token Bootstrap

#### Create CDHA session token code

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `/api/CDHASessionToken` |
| Auth | iMIS request verification token in `RequestVerificationToken` header; production only |
| Request | iMIS generic entity payload with `EntityTypeName: "CDHASessionToken"`, `ContactKey: context.selectedPartyId`, and a random `UserCode` |
| Response | iMIS generic entity response; client reads `Properties.$values[].Name === "UserCode"` |
| Used by | `util/token.ts` before requesting a new API bearer token |

#### Exchange code for API token

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{newHostUrl}/auth/token` |
| Auth | None. The request body carries the generated code and iMIS client context. |
| Request | `{ "code": string, "context": ClientContext }` |
| Response | `{ "token": string }` |
| Used by | Every Profile call that uses `{newHostUrl}/v1/authenticated/*` |

In development, the app skips `/api/CDHASessionToken` and calls `/auth/token` with `code: "anyValue"` plus a hard-coded development client context.

## Initial Profile Load

These calls run when `ProfileRoute` mounts through `RootContainer type="PROFILE"`.

| Action | Method | Endpoint | Request | Response | Used by |
| --- | --- | --- | --- | --- | --- |
| Load lookup tables | `GET` | `{newHostUrl}/v1/lookupdata?table={table}` | Query `table` | `{ success, data, errors?, status? }` | Personal info, communications, education, expertise, insurance, and edit forms |
| Load communications | `GET` | `{hostUrl}/UpdateCommunications.ashx` | None | `{ data: Communications }` | Top profile communications summary and edit form |
| Load auto-renewal subscription | `POST` | `{hostUrl}/UpdateAutoRenew.ashx` | `{}` | `{ data: AutoRenewalSubscription }` | Expired-card banner, renewal summary, auto-renewal/payment-plan editor |
| Load member profile summary | `POST` | `{hostUrl}/UpdatePersonalInfo.ashx` | `{ get_summaryonly: true }` | `{ data: MemberInfo, server_time? }` | Main personal/membership dashboard |
| Load orofacial question | `GET` | `{newHostUrl}/v1/authenticated/cdhaquestions/OROFACIAL_STATUS` | Bearer token | `{ data: CdhaQuestion[] }` | Merged into `memberInfo.orofacial_status` and `memberInfo.orofacial_seqn` |
| Load education | `GET` | `{newHostUrl}/v1/authenticated/education` | Bearer token | `{ success, data: Education[], message? }` | Education summary and Profile Edit education section |
| Load areas of expertise | `GET` | `{newHostUrl}/v1/authenticated/expertise` | Bearer token | `{ success, data: AreaOfExpertise, message? }` | Expertise summary and Profile Edit expertise section |
| Load Docebo token | `GET` | `{newHostUrl}/v1/authenticated/docebo/token` | Bearer token | Expected `{ data: { access_token } }` | Starts Docebo enrollment loading for eLearning, conferences, and workshops |
| Load Docebo user | `GET` | `https://cdha.docebosaas.com/manage/v1/user/session` | Docebo bearer token | `{ data: { id, ... } }` | Gets the current Docebo user id |
| Load Docebo enrollments | `GET` | `https://cdha.docebosaas.com/learn/v1/enrollments?id_user[]={userId}&page_size=200` | Docebo bearer token | `{ data: { items: DoceboEnrollment[] } }` | Builds eLearning, conference, and workshop profile tables |

Lookup tables requested by the profile route are:

`COUNTRY`, `DEGREES`, `UNIVERSITY`, `GRAD_YEAR`, `GRAD_MONTH`, `YEAR_ATTEND`, `AREAS_OF_PRACTICE`, `WORK_ENVIRONMENT`, `INSURANCE`, `IPN_STATUS`, `INDIGENOUS_STATUS`.

Profile Edit also requests some of the same lookup tables through React Query when education or expertise modals open.

## Profile Display Calls

### Member Job Ads

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/GetMemberJobAds.ashx?filter=MYADS_` |
| Auth | iMIS session cookie |
| Request | Empty body `{}` |
| Response | `{ pd_data: ProfileTableItem[], errors?: any[] }` |
| Used by | `ProfileTableContainer` in the "My Job Ads" table on `/profile` |

Each `pd_data` item is expected to contain a `Value` object with fields such as `seqn`, `title`, `created_date`, `end_date`, `province`, `area`, and `status`.

### Job Ad Details

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/GetJobAdDetail.ashx?SEQN={seqn}` |
| Auth | iMIS session cookie |
| Request | Empty body `{}` |
| Response | `{ ad_data: JobAdDetails }` |
| Used by | Clicking a job ad title opens the `JobAdDetailsContainer` popup |

### Membership Add-ons

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/getmemberaddons.ashx?filter=ADDONS_` |
| Auth | iMIS session cookie |
| Request | Empty body `{}` |
| Response | `{ addons_data: AddOn[], errors?: any[] }` |
| Used by | "My Membership Add-ons" table on `/profile` |

Expected add-on fields include `Name`, `Active`, and optionally `href`.

### Certificate and Document Links

These are navigational GET links, not XHR/fetch calls, but they are part of the Profile API surface.

| Action | Method | Endpoint | Input | Used by |
| --- | --- | --- | --- | --- |
| Download CE/conference certificate | `GET` | `/cdha/GetCert?CE={scoTag}&cert={CECert.pdf or ConfCert.pdf}&SRC={D or C}` | `CE` is the course code/sco tag; `SRC=D` for Docebo, `SRC=C` for Connect/conference | eLearning, conferences, workshops |
| Download invoice | `GET` | `/cdha/MyInvoice` or `/achd/MyInvoice` | Current logged-in member session | Downloads panel |
| Download receipts | `GET` | `/cdha/MyReceipt` or `/achd/MyReceipt` | Current logged-in member session | Downloads panel |
| Download membership card | `GET` | `/cdha/MyMembershipCard` or `/achd/MyMembershipCard` | Current logged-in member session | Downloads panel |
| Download insurance certificate | `GET` | `/cdha/MyCertificate` or `/achd/MyCertificate` | Current logged-in member session | Insurance panel |

### Docebo Course Launch

| Field | Value |
| --- | --- |
| Method | `GET` navigation |
| Endpoint | `https://cdha.docebosaas.com{courseUrl};type=oauth2_response;reenter_cc=0;access_token={doceboAccessToken}` |
| Auth | Docebo access token in URL |
| Request | Link navigation only |
| Response | Docebo course page |
| Used by | Active eLearning, conference, and workshop rows when the item came from Docebo |

## Profile Edit Calls

### Validate New Email

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/ValidateNewEmail.ashx?email={email}` |
| Auth | iMIS session cookie |
| Request | Empty body `{}` |
| Response | Expected `{ is_valid: boolean, ... }` |
| Used by | Async validator on the Profile Edit email field |

### Update Personal Information

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/UpdatePersonalInfo.ashx` |
| Auth | iMIS session cookie |
| Request | JSON string of changed fields plus `id` |
| Response | `{ data: MemberInfo }` |
| Used by | Profile Edit member information update button |

Profile updates send a diff, not the full form. Allowed Profile fields are:

`street`, `street2`, `city`, `country`, `province`, `postal_code`, `cell_phone`, `phone`, `email`, `date_of_birth`, `preferred_language`, `exclude_directory`, `join_reason`, `job_description`, `password`, `indigenous_status`, `ipn_status`, `canadapost_id`, `name_log_string`, `orofacial_status`, `orofacial_seqn`, and `id`.

After a successful update, the client waits two seconds and refreshes member info with `POST {hostUrl}/UpdatePersonalInfo.ashx` without `get_summaryonly`.

### Create or Update Orofacial Question

| Action | Method | Endpoint | Request | Response | Used by |
| --- | --- | --- | --- | --- | --- |
| Create answer | `POST` | `{newHostUrl}/v1/authenticated/cdhaquestions/OROFACIAL_STATUS` | `{ question_code, question, answer }` | New API JSON response | Profile Edit member information update when no `orofacial_seqn` exists |
| Update answer | `PUT` | `{newHostUrl}/v1/authenticated/cdhaquestions/OROFACIAL_STATUS/{seqn}` | `{ seqn, question_code, question, answer }` | New API JSON response | Profile Edit member information update when `orofacial_seqn` exists |

The current question payload is:

```json
{
  "question_code": "OROFACIAL_STATUS",
  "question": "Do you practice orofacial myofunctional therapy?",
  "answer": "..."
}
```

### Rebill Insurance After Profile Address Update

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/UpdateBilling.ashx` |
| Auth | iMIS session cookie |
| Request | `{ "insurance": memberInfo.insurance_code }` or `{ "insurance": "INS01" }` |
| Response | `{ data: any }` |
| Used by | Conditional secondary call after member info update for `FM`, `SUPPT`, or `RET` members when `paid_thru.year() <= cut_date.year()` |

### Update Communications

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/UpdateCommunications.ashx` |
| Auth | iMIS session cookie |
| Request | Communications object with `is_update: true`; `0` and `1` values are converted to booleans before sending |
| Response | `{ data: Communications }` |
| Used by | Profile Edit communication preferences update button |

Common request fields include:

`enews_subscribe`, `pd_subscribe`, `benefit_subscribe`, `products_subscribe`, `campaign_subscribe`, `eventcal_subscribe`, `job_notification_prov`, `e_ohcanada`, `third_party`, related `*_updated` values, and `is_update`.

`gdpr_updated`, `gdpr_consent`, and `gdprCommunity_consent` are removed for Profile Edit because GDPR consent fields are only shown for Join/Renew.

After a successful update, the client refreshes communications with `GET {hostUrl}/UpdateCommunications.ashx`.

### Auto-Renewal and Payment Plan

#### Read auto-renewal data

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/UpdateAutoRenew.ashx` |
| Auth | iMIS session cookie |
| Request | `{}` |
| Response | `{ data: AutoRenewalSubscription }` |
| Used by | Initial profile load, expired-card alert, membership renewal summary, and Profile Edit auto-renewal/payment-plan machine |

Expected auto-renewal fields:

`PAYMENT_METHOD`, `CC_NUMBER`, `CC_NAME`, `CC_MONTH`, `CC_YEAR`, `CC_CCV`, `DUES_DRAFT_DATE`, `IPN_DRAFT_DATE`, `MONTHS`, `FREQUENCY`, `PERPETUAL`.

#### Update auto-renewal data

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/UpdateAutoRenew.ashx` |
| Auth | iMIS session cookie |
| Request | `{ action: "UPDATE" \| "UNSUBSCRIBE", data: AutoRenewalUpdate \| null }` |
| Response | JSON response from Wicket/iMIS endpoint |
| Used by | Profile Edit auto-renewal/payment-plan update button |

`AutoRenewalUpdate` can contain:

`PAYMENT_METHOD`, `CC_NUMBER`, `CC_NAME`, `CC_CCV`, `CC_MONTH`, `CC_YEAR`, `DUES_DRAFT_DATE`, `IPN_DRAFT_DATE`, `MONTHS`, `FREQUENCY`, and `PERPETUAL`.

For credit-card-only updates during an existing payment plan, draft date and installment fields are explicitly sent as `undefined`.

For unsubscribe, the client sends `{ action: "UNSUBSCRIBE", data: null }`. The current machine calls unsubscribe twice to clear card data.

#### Update cart for IPN payment-plan change

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/updateCart.ashx` |
| Auth | iMIS session cookie |
| Request | `{ lines: [{ productCode: "IPN", quantity }], removeInvoice: true }` |
| Response | Cart JSON response |
| Used by | Auto-renewal/payment-plan machine before updating IPN payment-plan enrollment |

The machine first removes `IPN` with quantity `0`; if the submitted IPN draft date exists, it adds `IPN` back with quantity `1`.

### Education

#### Read education

| Field | Value |
| --- | --- |
| Method | `GET` |
| Endpoint | `{newHostUrl}/v1/authenticated/education` |
| Auth | CDHA bearer token |
| Request | None |
| Response | `{ success: boolean, data: Education[], message?: string }` |
| Used by | Education summary and Profile Edit education cards |

`Education` fields:

`seqn`, `dh_degree`, `dh_university`, `dh_grad_year`, `dh_grad_month`, `dh_year_attend?`.

#### Add education

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{newHostUrl}/v1/authenticated/education` |
| Auth | CDHA bearer token |
| Request | `{ update: { dh_degree, dh_university, dh_grad_year, dh_grad_month, dh_year_attend? } }` |
| Response | `{ success: boolean, data: Education[], message?: string }` |
| Used by | Add Education modal |

`dh_year_attend` is included only for student members (`memberType === "STU"`).

#### Update education

| Field | Value |
| --- | --- |
| Method | `PUT` |
| Endpoint | `{newHostUrl}/v1/authenticated/education/{seqn}` |
| Auth | CDHA bearer token |
| Request | `{ seqn, dh_degree, dh_university, dh_grad_year, dh_grad_month, dh_year_attend? }` |
| Response | `{ success: boolean, data: Education[], message?: string }` |
| Used by | Edit Education modal |

#### Delete education

| Field | Value |
| --- | --- |
| Method | `DELETE` |
| Endpoint | `{newHostUrl}/v1/authenticated/education/{seqn}` |
| Auth | CDHA bearer token |
| Request | Path `seqn` |
| Response | `{ success: boolean, data: Education[], message?: string }` |
| Used by | Delete confirmation modal in Profile Edit education section |

### Areas of Expertise

#### Read expertise

| Field | Value |
| --- | --- |
| Method | `GET` |
| Endpoint | `{newHostUrl}/v1/authenticated/expertise` |
| Auth | CDHA bearer token |
| Request | None |
| Response | `{ success: boolean, data: AreaOfExpertise, message?: string }` |
| Used by | Expertise summary and Profile Edit expertise card |

`AreaOfExpertise` fields:

`aoe_primary`, `aoe_secondary`, `we_primary`, `we_secondary`.

#### Add or update expertise

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{newHostUrl}/v1/authenticated/expertise` |
| Auth | CDHA bearer token |
| Request | `{ aoe_primary, aoe_secondary, we_primary, we_secondary, is_update }` |
| Response | `{ success: boolean, data: AreaOfExpertise, message?: string }` |
| Used by | Add/Edit Areas of Expertise modal |

`is_update` is `false` for a new expertise record and `true` when editing an existing record.

#### Clear expertise

| Field | Value |
| --- | --- |
| Method | `PUT` |
| Endpoint | `{newHostUrl}/v1/authenticated/expertise` |
| Auth | CDHA bearer token |
| Request | `{ aoe_primary: "", aoe_secondary: "", we_primary: "", we_secondary: "", is_update: true }` |
| Response | `{ success: boolean, data: AreaOfExpertise, message?: string }` |
| Used by | Implemented by `useDeleteAreaOfExpertise`; the current visible delete icon is commented out in the Profile Edit expertise card |

## Province of Practice Change Request

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/SendEmailGeneric.ashx` |
| Auth | iMIS session cookie |
| Request | Email payload from `ProvinceOfPracticeChangeRequestForm` |
| Response | `{ data: any }` |
| Used by | `/requestprovincechange/form` route |

On success the app routes to `/requestprovincechange/form/success`; on failure it routes to `/requestprovincechange/form/error`.

## Business Info Calls

These calls are only reachable when `memberInfo.active_uin === true` and the user opens `/businessInfo`.

### UIN Addresses

#### Read UIN addresses

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/UpdateUINAddress.ashx` |
| Auth | iMIS session cookie |
| Request | `{}` |
| Response | `{ data: UINAddress[] }`; client filters out records with `status === "DEL"` |
| Used by | Business Info display and edit screen |

`UINAddress` fields:

`seqn`, `address1`, `address2`, `address3`, `city`, `state_province`, `zip`, `phone`, `email`, `change_date`, `status`.

#### Add or update UIN address

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/UpdateUINAddress.ashx` |
| Auth | iMIS session cookie |
| Request | `{ update: UINAddress }` |
| Response | Wicket/iMIS JSON response |
| Used by | Add Business Address and edit UIN address flows |

When updating an existing address, the client clears `address2`, `address3`, `status`, and `change_date` before sending.

#### Delete UIN address

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/UpdateUINAddress.ashx` |
| Auth | iMIS session cookie |
| Request | `{ remove: [seqn] }` |
| Response | Wicket/iMIS JSON response |
| Used by | Delete confirmation in Business Info edit |

### CDHA Net Addresses

#### Read CDHA Net addresses

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/UpdateCDHAnet.ashx` |
| Auth | iMIS session cookie |
| Request | `{}` |
| Response | `{ data: CDHANetAddress[] }`; client filters out records with `status === "DEL"` |
| Used by | Business Info display and edit screen |

`CDHANetAddress` fields:

`seqn`, `office_code`, `address1`, `address2`, `address3`, `city`, `state_province`, `zip`, `phone`, `fax`, `email`, `software`, `dh_incorporation`, `change_date`, `status`.

#### Delete CDHA Net address

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/UpdateCDHAnet.ashx` |
| Auth | iMIS session cookie |
| Request | `{ remove: [seqn] }` |
| Response | Wicket/iMIS JSON response |
| Used by | Delete CDHA Net office confirmation in Business Info edit |

The API wrapper also supports `{ update: CDHANetAddress }`, but the current Business Info UI only wires deletion for CDHA Net records.

## eLearning, Adobe Connect, and Transcript Calls

### Adobe Connect Curriculum Load

These calls are used when a hosted active eLearning item is opened. The default path uses the CDHA proxy endpoint; `insideConnect` switches to direct Adobe Connect calls.

| Action | Method | Endpoint | Request | Response | Used by |
| --- | --- | --- | --- | --- | --- |
| Common info | `GET` | `{connectProxy}?action=common-info&session={session}` | Adobe Connect session id | XML common-info response with current `user-id` | Start curriculum load |
| Curriculum contents | `GET` | `{connectProxy}?action=curriculum-contents&session={session}&sco-id={scoId}` | `session`, curriculum `scoId` | XML curriculum contents | Build sub-table/lesson list |
| Curriculum taker report | `GET` | `{connectProxy}?action=report-curriculum-taker&session={session}&sco-id={scoId}&user-id={userId}` | `session`, `scoId`, Adobe user id | XML learner status and scores | Merge completion state into curriculum list |
| Learning path | `GET` | `{connectProxy}?action=learning-path-info&session={session}&sco-id={scoId}&curriculum-id={scoId}` | `session`, `scoId`, `curriculum-id` | XML prerequisites/learning path | Shows blocked items and prerequisites |

`connectProxy` is `SendConnectRequest.ashx` in normal profile usage, or `https://cdha.adobeconnect.com/api/xml` when `insideConnect` is true.

### Update External Curriculum Item

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `https://www.imisdev.cdha.ca/CDHACommon/UpdateConnectUserTranscript.ashx` in development, `//{window.location.hostname}/CDHACommon/UpdateConnectUserTranscript.ashx` in production |
| Auth | iMIS session cookie |
| Request | `{ "sco_id": string, "curriculum_id": string }` |
| Response | XML/string response from Wicket/iMIS endpoint |
| Used by | Clicking an `external-event` curriculum item, except `Submit Your Questions` |

### Adobe Connect Viewer Navigation

The embedded viewer iframe navigates to either an absolute lesson URL or `https://cdha.adobeconnect.com{urlPath}?session={session}`. The "Page not loading?" link navigates to `https://cdha.adobeconnect.com/setcookie?session={session}`.

## Canada Post AddressComplete

The Profile member address editor and Business Info UIN address editor instantiate `pca.Address` with key `KT92-DZ18-BR58-ZD45`. The source does not call the Canada Post endpoint directly; the AddressComplete script loaded in `public/index.html` makes the external lookup requests.

| Field | Value |
| --- | --- |
| Script/CSS host | `http://ws1.postescanada-canadapost.ca/js/addresscomplete-2.30.min.js` and matching CSS |
| Request | Managed by `pca.Address` while the user searches an address |
| Response | Address object with fields such as `Line1`, `Line2`, `City`, `ProvinceCode`, `PostalCode`, `CountryIso2`, `Id` |
| Used by | Profile Edit member address and Business Info UIN address add/edit |

The selected address is copied into the profile or UIN form and later submitted through `UpdatePersonalInfo.ashx` or `UpdateUINAddress.ashx`.

## Non-Business Telemetry

`profilePage.tsx` initializes Sentry browser tracing. This is not a CDHA business API, but the page can send telemetry/envelope requests to Sentry.

| Environment | DSN host | Used by |
| --- | --- | --- |
| Development | `o4508212392361984.ingest.us.sentry.io` project `4508212403437568` | Error and tracing telemetry from the Profile bundle |
| Production | `o4508212392361984.ingest.us.sentry.io` project `4508331702878208` | Error and tracing telemetry from the Profile bundle |

## Response Shape Reference

### MemberInfo

Important fields consumed by the Profile app:

`id`, `first_name`, `last_name`, `street`, `street2`, `city`, `province`, `country`, `postal_code`, `email`, `phone`, `cell_phone`, `date_of_birth`, `preferred_language`, `exclude_directory`, `member_type`, `member_type_description`, `member_status`, `member_since`, `paid_thru`, `cut_date`, `chapter`, `years_of_membership`, `insurance`, `insurance_code`, `insurance_expires`, `show_ins_certificate`, `show_ins_upgrade`, `show_invoice`, `show_mem_card`, `show_recepits`, `show_renew`, `has_IPN`, `purchased_IPN`, `purchased_EDU`, `active_uin`, `uin_number`, `dh_incorporation`, `ipn_status`, `indigenous_status`, `job_description`, `join_reason`, `canadapost_id`, `orofacial_status`, `orofacial_seqn`, `DUES_DRAFT_DATE`, `IPN_DRAFT_DATE`, `DRAFT_AMOUNT`, `INSTALLMENT_AMOUNT1`, `INSTALLMENT_AMOUNT2`, `INSTALLMENT_AMOUNT3`, `INSTALLMENT_AMOUNT4`.

### Communications

Important fields consumed by the Profile app:

`enews_subscribe`, `pd_subscribe`, `benefit_subscribe`, `products_subscribe`, `campaign_subscribe`, `eventcal_subscribe`, `job_notification_prov`, `e_ohcanada`, `third_party`, `gdpr_consent`, `gdprCommunity_consent`, `gdprLanguage_consent`, `ac_exclusion_date`, and related `*_updated` timestamp fields.

### Profile Table Item

Profile table endpoints return arrays of items with a common shape:

```json
{
  "Key": "...",
  "Value": {
    "name": "...",
    "title": "...",
    "sco-id": "...",
    "sco-tag": "...",
    "url": "...",
    "session": "...",
    "completed": false,
    "date-taken": "...",
    "date-expire": "..."
  }
}
```

Not every table uses every field. Job ads use `Value.title`, `Value.seqn`, `Value.created_date`, `Value.end_date`, `Value.province`, `Value.area`, and `Value.status`. Add-ons use top-level `Name`, `Active`, and optional `href`.

## Legacy Profile APIs Found But Not Currently Reached

The following modules exist under `src/api/profile` or older profile containers, but they are not currently reached from the active `profilePage.tsx -> ProfileRoute -> Display/Edit` tree:

| Endpoint | Legacy module | Current status |
| --- | --- | --- |
| `{hostUrl}/getmemberpd.ashx?filter=PD_` and `WE_` | `api/profile/getMemberPDData.ts` | Imported by on-demand webinar container, but the profile container's load calls are commented out. Docebo enrollment data currently drives the active eLearning merge. |
| `{hostUrl}/UpdateDHEducation.ashx` | `api/profile/addEducationData.ts` | Legacy education add path for Join/old profile editors; current Profile Edit uses `{newHostUrl}/v1/authenticated/education`. |
| `{hostUrl}/UpdateExpertise.ashx` | `api/profile/getCDHANetData.ts` | Legacy/misnamed expertise loader; current Profile display and edit use `{newHostUrl}/v1/authenticated/expertise`. |
| `{newHostUrl}/v1/authenticated/expertise` via `api/profile/updateExpertiseData.ts` | Old expertise edit container | Current Profile Edit uses React Query hooks in `api/react-query/areasofexpertise.ts`. |
| `{newHostUrl}/v1/authenticated/memberInfo` | `api/profile/getMemberInfoDatav2.ts` | Experimental/new member-info loader; current Profile route still reads member info from `UpdatePersonalInfo.ashx`. |
| `{hostUrl}/UpdatecdhaQuestions.ashx` | `updateOrofacial(..., isJoin: true)` | Join-only fallback; Profile Edit uses the new authenticated `cdhaquestions` endpoints. |

## Open Questions

- Confirm exact server response shapes for legacy `.ashx` endpoints. The frontend validates only the top-level keys it consumes, so fields not used by the current UI are inferred from usage.
- Confirm whether the hidden expertise delete action should remain documented as an API requirement or be removed from the migration scope.
- Confirm whether the legacy `getmemberpd.ashx` PD/WE calls should be restored for non-Docebo eLearning records or remain out of the current Profile page API scope.

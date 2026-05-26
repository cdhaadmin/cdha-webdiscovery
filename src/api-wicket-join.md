# Join API Calls

## Purpose

This page documents the API calls needed by the Join application mounted from `/home/lalves/dev/frontend/src/joinPage.tsx`.

The entry point creates the Redux store, router, translations, and the `JoinRoute`. Business API calls are reached through `components/profile/route/joinRoute.tsx`, `RootContainer isJoin={true}`, the join member-type route components, and the shared `api/profile/createAccount.ts` submission helper.

## Base URLs

| Alias | Development | Production | Used for |
| --- | --- | --- | --- |
| `hostUrl` | `https://www.cdha.ca/CDHACommon` | `//{window.location.hostname}/CDHACommon` | Legacy Wicket/iMIS `.ashx` endpoints |
| `newHostUrl` | `https://api.lalves.mycdha.ca` | `https://api.imisdev.mycdha.ca` on imisdev, otherwise `https://api.mycdha.ca` | New JSON API lookup/authenticated endpoints |
| Invoice test | `https://www.cdha.ca/CDHAstaff/InvoiceTest.ashx` | Same fixed host | Forces/checks invoice generation before cart update |
| Canada Post AddressComplete | `http://ws1.postescanada-canadapost.ca` | Same | External address lookup script loaded by `public/index.html` |

## Authentication

| API family | Authentication |
| --- | --- |
| Legacy Wicket/iMIS `.ashx` | Browser session cookies. Axios uses `withCredentials: true`; `api/fetch/*` uses `credentials: "include"`. |
| New `newHostUrl` lookup API | No bearer token for lookup table reads. |
| New `newHostUrl` authenticated API | `Authorization: Bearer {CDHA_CLIENT_TOKEN}` from `util/token.ts`. Token is stored in `localStorage` under `CDHA_CLIENT_TOKEN`. |
| Canada Post AddressComplete | External script key from `public/index.html`; requests are made by the `pca.Address` script, not directly by app code. |

### Client Token Bootstrap

Join mostly uses legacy Wicket APIs, but it still reaches authenticated new API calls when member info is augmented with the orofacial question and when education is refreshed after the legacy education save.

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
| Used by | Authenticated `newHostUrl` calls reached by Join |

In development, the app skips `/api/CDHASessionToken` and calls `/auth/token` with `code: "anyValue"` plus a hard-coded development client context.

## Initial Join Load

These calls run when `JoinRoute` mounts through `RootContainer isJoin={true}`.

| Action | Method | Endpoint | Authentication | Request | Response | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| Load common lookup tables | `GET` | `{newHostUrl}/v1/lookupdata?table={table}` | None | Query `table` | `{ success?, data, errors?, status? }` | Drives country, education, insurance, IPN, and indigenous-status form options |
| Read current member/session state | `POST` | `{hostUrl}/UpdatePersonalInfo.ashx` | iMIS session cookie | `{}` | `{ data: MemberInfo, server_time? }` or error payload with member state | Join validation expects anonymous sessions to appear as `memberInfo.status === "User undefined"` |
| Read orofacial answer | `GET` | `{newHostUrl}/v1/authenticated/cdhaquestions/OROFACIAL_STATUS` | CDHA bearer token | None | `{ data: CdhaQuestion[] }` | Called by the shared member-info loader when member info returns a `data` payload; merged into `memberInfo.orofacial_status` and `memberInfo.orofacial_seqn` |
| Load visitor-account lookup tables | `GET` | `{newHostUrl}/v1/lookupdata?table={table}` | None | `JOIN_REASON`, `JOB_DESCRIPTION` | `{ data: LookupOption[] }` | Only when the `/join/NM` route mounts |

Common lookup tables requested by Join are:

`COUNTRY`, `DEGREES`, `UNIVERSITY`, `GRAD_YEAR`, `GRAD_MONTH`, `YEAR_ATTEND`, `AREAS_OF_PRACTICE`, `WORK_ENVIRONMENT`, `INSURANCE`, `IPN_STATUS`, `INDIGENOUS_STATUS`.

## Join Routes

| Route | Member type | Visible steps | Submit orchestration |
| --- | --- | --- | --- |
| `/` and `/join` | None | Join landing/eligibility links | No business API calls beyond initial load |
| `/join/NM` | `NM` visitor account | Personal info, consent | `createNewMember({ type: "JOIN", memberType: "NM", memberInfo.exclude_directory: true, ...formData })` |
| `/join/STU` | `STU` student | Personal info, dental hygiene education, communications, confirmation | `createNewMember({ type: "JOIN", memberType: "STU", ...formData })` |
| `/join/FM` | `FM` full member | Personal info, communications, insurance, confirmation | `createNewMember({ type: "JOIN", memberType: "FM", paymentPlanContext: state.context, ...formData })` |
| `/join/SUPPT` | `SUPPT` supportive member | Personal info, communications, confirmation | `createNewMember({ type: "JOIN", memberType: "SUPPT", paymentPlanContext: state.context, ...formData })` |

The FM and SUPPT routes instantiate the payment-plan state machine, but their payment-plan wizard steps are currently commented out. The submit helper still contains a payment-plan branch if `paymentPlanContext.DUES` is present.

## Detailed Calls

### Load Lookup Data

| Field | Value |
| --- | --- |
| Method | `GET` |
| Endpoint | `{newHostUrl}/v1/lookupdata?table={table}` |
| Auth | None |
| Request | Query string `table` |
| Response | `{ data: LookupOption[] }` |
| Used by | Join personal info, visitor info, education, insurance, and additional-info select controls |

Lookup option shape is inferred from usage:

```json
{
  "Code": "...",
  "Name": "...",
  "CountryCode": "..."
}
```

`CountryCode` is used by the country lookup; not every lookup option contains it.

### Read Member/Session Status

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/UpdatePersonalInfo.ashx` |
| Auth | iMIS session cookie |
| Request | `{}` |
| Response | `{ data: MemberInfo, server_time?: string }` or an error payload with `data` |
| Used by | Join validation, server-time dependent insurance/payment-plan logic, and member-info form defaults |

Join is allowed only when the returned member state indicates no logged-in user:

```json
{
  "data": {
    "status": "User undefined"
  }
}
```

### Validate New Email

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/ValidateNewEmail.ashx?email={email}` |
| Auth | iMIS session cookie |
| Request | Empty body `{}` |
| Response | Email validation JSON from Wicket/iMIS. The form treats the returned value as the async validator result. |
| Used by | Join personal-info email field in `MemberInfoEdit` |

### Create Member Account

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/UpdatePersonalInfo.ashx` |
| Auth | iMIS session cookie |
| Request | JSON string containing selected member-info fields plus `get_summaryonly: true` |
| Response | `{ data: MemberInfo }` |
| Used by | First step of `createNewMember` when `memberInfo.id` is missing |

The join create-account request picks only these fields:

`first_name`, `middle_name`, `last_name`, `street`, `street2`, `city`, `country`, `province`, `chapter`, `postal_code`, `cell_phone`, `phone`, `email`, `alternate_email`, `date_of_birth`, `preferred_language`, `exclude_directory`, `password`, `member_type`, `join_reason`, `job_description`, `ipn_status`, `indigenous_status`, `canadapost_id`, `name_log_string`, and `get_summaryonly`.

If `memberInfo.selected_chapter` is populated, the submit helper copies it to `memberInfo.chapter` before the request.

### Save Join Orofacial Answer

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/UpdatecdhaQuestions.ashx` |
| Auth | iMIS session cookie |
| Request | JSON string `{ seqn?, question_code, question, answer }` |
| Response | Wicket/iMIS JSON response |
| Used by | `createAccount` after `UpdatePersonalInfo.ashx` when `memberInfo.orofacial_status` is present |

Current payload:

```json
{
  "seqn": "...",
  "question_code": "OROFACIAL_STATUS",
  "question": "Do you practice orofacial myofunctional therapy?",
  "answer": "yes"
}
```

### Update Communications

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/UpdateCommunications.ashx` |
| Auth | iMIS session cookie |
| Request | Communications object with `is_update: true` and `email_address: memberInfo.email` |
| Response | `{ data: Communications }` |
| Used by | Join consent/communications step during final submit |

Before sending, the client converts numeric `0` and `1` values to booleans. It also removes most `*_updated` values because the legacy C# endpoint rejects JavaScript dates; `eventcal_updated` is replaced with a hard-coded `/Date(...)/` value.

For student joins, the submit helper forces:

```json
{
  "e_journal": 1,
  "e_ohcanada": 1,
  "is_update": true,
  "email_address": "member@example.com"
}
```

After a successful update, the client refreshes communications with `GET {hostUrl}/UpdateCommunications.ashx`.

### Refresh Communications

| Field | Value |
| --- | --- |
| Method | `GET` |
| Endpoint | `{hostUrl}/UpdateCommunications.ashx` |
| Auth | iMIS session cookie |
| Request | None |
| Response | `{ data: Communications }` |
| Used by | Follow-up refresh after the communications update |

### Save Student Education

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/UpdateDHEducation.ashx` |
| Auth | iMIS session cookie |
| Request | `{ update: { dh_degree, dh_university, dh_grad_year, dh_grad_month, dh_year_attend?, seqn? } }` |
| Response | `{ data: Education[] }` or Wicket/iMIS education response |
| Used by | `/join/STU` final submit |

`dh_year_attend` is included by the student education form. After the legacy save succeeds, the shared education helper waits two seconds and refreshes education through the new API:

| Field | Value |
| --- | --- |
| Method | `GET` |
| Endpoint | `{newHostUrl}/v1/authenticated/education` |
| Auth | CDHA bearer token |
| Request | None |
| Response | `{ success: boolean, data: Education[], message?: string }` |
| Used by | Post-save education refresh |

### Update Billing and Insurance

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/UpdateBilling.ashx` |
| Auth | iMIS session cookie |
| Request | Insurance/billing object from the `insurance` form, or `{}` for supportive members |
| Response | `{ data: any }` |
| Used by | `/join/FM` insurance choice and `/join/SUPPT` billing initialization |

FM insurance request fields are inferred from the form:

`insurance`, `add_extension`.

The `insurance` value is selected from lookup code `INS01` or `INS02`. `add_extension` can be `false`, `true`, `null`, or omitted depending on province and extension eligibility.

### Force Invoice Generation

| Field | Value |
| --- | --- |
| Method | `GET` |
| Endpoint | `https://www.cdha.ca/CDHAstaff/InvoiceTest.ashx?users={memberInfo.id or 1}` |
| Auth | Current browser session |
| Request | Query `users` |
| Response | Raw response from `InvoiceTest.ashx`; the client stores it only for error diagnostics |
| Used by | `createNewMember` after billing/education updates and before adding invoice lines to the cart |

For new joins, the original `formData.memberInfo.id` is normally absent, so the current code falls back to `users=1`.

### Add Invoice to Cart

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/updateCart.ashx` |
| Auth | iMIS session cookie |
| Request | `{ "addInvoice": true }` |
| Response | Cart update JSON |
| Used by | `createNewMember` after `InvoiceTest.ashx` |

The Redux cart helper then waits two seconds and refreshes cart items.

### Read Cart Items

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/getCartItems.ashx` |
| Auth | iMIS session cookie |
| Request | `{}` |
| Response | Cart JSON. `createNewMember` reads `res.invoices.Lines` and `res.lines`. |
| Used by | Verifying whether a `DUES` invoice was added and collecting old cart lines to remove |

The submit helper redirects based on the cart response:

| Condition | Redirect |
| --- | --- |
| Join has an invoice line where `Item.ItemCode === "DUES"` | `/cdha/joinsuccess` or `/achd/joinsuccess` |
| STU join without a dues invoice | `/cdha/stujoinconfirm` or `/achd/stujoinconfirm` |
| FM/SUPPT join without a dues invoice | Internal `/error` route and error emails |
| NM/other join without a dues invoice | `/cdha/profile` or `/achd/profile` |

### Remove Existing Cart Lines

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/updateCart.ashx` |
| Auth | iMIS session cookie |
| Request | `{ lines: [{ productCode: line.Item.ItemCode, quantity: 0 }] }` |
| Response | Cart update JSON |
| Used by | Cleanup after `getCartItems.ashx` returns existing `res.lines` |

### Conditional Payment-Plan Enrollment

This code exists in `createNewMember`, but the visible Join FM/SUPPT payment-plan wizard steps are currently commented out. It becomes active only if `paymentPlanContext.DUES` is present in the submitted data.

#### Update IPN cart line for payment plan

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/updateCart.ashx` |
| Auth | iMIS session cookie |
| Request | Remove IPN and independent practice lines with quantity `0`; if IPN was selected, add `{ productCode: "IPN", quantity: 1 }`; all requests include `removeInvoice: true` |
| Response | Cart update JSON |
| Used by | Payment-plan branch before saving auto-renewal details |

#### Save auto-renewal/payment-plan details

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/UpdateAutoRenew.ashx` |
| Auth | iMIS session cookie |
| Request | `{ action: "UPDATE", data: AutoRenewalUpdate }` |
| Response | `{ data: AutoRenewalSubscription }` |
| Used by | Payment-plan branch when dues draft date is selected |

`AutoRenewalUpdate` fields sent by Join can include:

`PAYMENT_METHOD`, `CC_NUMBER`, `CC_NAME`, `CC_CCV`, `CC_MONTH`, `CC_YEAR`, `DUES_DRAFT_DATE`, `IPN_DRAFT_DATE`, `MONTHS`, `FREQUENCY`, `PERPETUAL`.

Draft dates are formatted as C# JSON dates using the selected `DD/MM` value and the hard-coded year `2026`, for example `/Date(1787184000000)/`.

### Error Notification Emails

#### Send operational error email

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/SendErrorEmail.ashx` |
| Auth | iMIS session cookie |
| Request | `{ emailSubject, emailMessage }` with password and credit-card fields stripped by regex |
| Response | `{ data: any }` |
| Used by | Create-account/cart failures and missing invoice diagnostics |

#### Send generic CDHA email

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/SendEmailGeneric.ashx` |
| Auth | iMIS session cookie |
| Request | `{ emailSubject, emailMessage }` with password and credit-card fields stripped by regex |
| Response | `{ data: any }` |
| Used by | Secondary notification for create-account/cart failures and missing invoice diagnostics |

## Canada Post AddressComplete

The Join personal-info editor instantiates `pca.Address` with key `KT92-DZ18-BR58-ZD45`. The source does not call the Canada Post endpoint directly; the AddressComplete script loaded in `public/index.html` makes the external lookup requests.

| Field | Value |
| --- | --- |
| Script/CSS host | `http://ws1.postescanada-canadapost.ca/js/addresscomplete-2.30.min.js` and matching CSS |
| Request | Managed by `pca.Address` while the user searches an address |
| Response | Address object with fields such as `Line1`, `Line2`, `City`, `ProvinceCode`, `PostalCode`, `CountryIso2`, `Id` |
| Used by | Join personal-info address fields |

The selected address is copied into `memberInfo.street`, `street2`, `city`, `province`, `country`, `postal_code`, `canadapost_id`, and `name_log_string`; it is later submitted through `UpdatePersonalInfo.ashx`.

## Non-Business Telemetry

`joinRoute.tsx` fires Google Analytics events in production when `window.gtag` exists.

| Event | When |
| --- | --- |
| `join_start` | Join route mounts |
| `invoice_added` | Join submit found a `DUES` invoice line in the cart |
| `renew_success` | Student join reached the student confirmation branch |
| `renew_success_auto_renewal` | Conditional payment-plan branch redirects to auto-renewal success |

## Response Shape Reference

### MemberInfo

Important fields consumed by Join:

`id`, `status`, `first_name`, `middle_name`, `last_name`, `street`, `street2`, `city`, `province`, `country`, `postal_code`, `email`, `alternate_email`, `phone`, `cell_phone`, `date_of_birth`, `preferred_language`, `exclude_directory`, `member_type`, `chapter`, `selected_chapter`, `join_reason`, `job_description`, `ipn_status`, `indigenous_status`, `canadapost_id`, `name_log_string`, `orofacial_status`, `orofacial_seqn`, `cut_date`, `insurance_expires`, and `show_ins_renew`.

### Communications

Important fields consumed by Join:

`enews_subscribe`, `pd_subscribe`, `benefit_subscribe`, `products_subscribe`, `campaign_subscribe`, `eventcal_subscribe`, `job_notification_prov`, `e_ohcanada`, `e_journal`, `third_party`, `gdpr_consent`, `gdprCommunity_consent`, `gdprLanguage_consent`, `email_address`, `is_update`, and related `*_updated` timestamp fields.

### Education

Important fields consumed by Join:

`seqn`, `dh_degree`, `dh_university`, `dh_grad_year`, `dh_grad_month`, `dh_year_attend`.

### Insurance

Important fields consumed by Join:

`insurance`, `add_extension`.

### Cart

Important fields consumed by Join:

`invoices.Lines[].Item.ItemCode` to detect `DUES`, and `lines[].Item.ItemCode` to remove existing cart lines.

### AutoRenewalUpdate

Used only by the currently hidden payment-plan branch:

`PAYMENT_METHOD`, `CC_NUMBER`, `CC_NAME`, `CC_CCV`, `CC_MONTH`, `CC_YEAR`, `DUES_DRAFT_DATE`, `IPN_DRAFT_DATE`, `MONTHS`, `FREQUENCY`, `PERPETUAL`.

## Legacy or Conditional APIs Found But Not Currently Reached

| Endpoint | Current status |
| --- | --- |
| `{hostUrl}/UpdateAutoRenew.ashx` update branch | Implemented in `createNewMember`, but visible Join payment-plan steps are commented out. |
| `{hostUrl}/updateCart.ashx` IPN payment-plan branch | Same as above; active only if `paymentPlanContext.DUES` is present. |
| `{newHostUrl}/v1/authenticated/expertise` update | The shared expertise/education container imports the old expertise updater, but Join hides expertise editing and only shows education. |

## Open Questions

- Confirm whether `InvoiceTest.ashx?users=1` is intentional for brand-new join accounts when `formData.memberInfo.id` is not yet available.
- Confirm whether Join FM/SUPPT payment-plan steps should remain hidden. If they are re-enabled, the conditional `UpdateAutoRenew.ashx` and IPN cart-update branch becomes part of the active Join API surface.
- Confirm exact server response shapes for legacy `.ashx` endpoints. The frontend usually validates only top-level `data`, cart `lines`, and invoice `Lines` fields.

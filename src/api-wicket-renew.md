# Renew API Calls

## Purpose

This page documents the API calls needed by the Renew application mounted from `/home/lalves/dev/frontend/src/renewPage.tsx`.

The entry point creates the Redux store, router, translations, and the `RenewRoute`. Business API calls are reached through `components/profile/route/renewRoute.tsx`, `RootContainer`, renew member-type routes, upgrade routes, and the shared profile submission helpers.

## Base URLs

| Alias | Development | Production | Used for |
| --- | --- | --- | --- |
| `hostUrl` | `https://www.cdha.ca/CDHACommon` | `//{window.location.hostname}/CDHACommon` | Legacy Wicket/iMIS `.ashx` endpoints |
| `newHostUrl` | `https://api.lalves.mycdha.ca` | `https://api.imisdev.mycdha.ca` on imisdev, otherwise `https://api.mycdha.ca` | New authenticated JSON API |
| Invoice test | `https://www.cdha.ca/CDHAstaff/InvoiceTest.ashx` | Same fixed host | Forces/checks invoice generation before cart update |

## Authentication

| API family | Authentication |
| --- | --- |
| Legacy Wicket/iMIS `.ashx` | Browser session cookies. Axios uses `withCredentials: true`; `api/fetch/*` uses `credentials: "include"`. |
| New `newHostUrl` lookup API | No bearer token for lookup table reads. |
| New `newHostUrl` authenticated API | `Authorization: Bearer {CDHA_CLIENT_TOKEN}` from `util/token.ts`. Token is stored in `localStorage` under `CDHA_CLIENT_TOKEN`. |

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
| Used by | Every Renew call that uses `{newHostUrl}/v1/authenticated/*` |

In development, the app skips `/api/CDHASessionToken` and calls `/auth/token` with `code: "anyValue"` plus a hard-coded development client context.

## Initial Renew Load

These calls run when `RenewRoute` mounts through `RootContainer` without `isJoin`.

| Action | Method | Endpoint | Authentication | Request | Response | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| Load lookup tables | `GET` | `{newHostUrl}/v1/lookupdata?table={table}` | None | Query `table` | `{ success?, data, errors?, status? }` | Drives renew communications, education, insurance, additional info, and upgrade forms |
| Load areas of expertise | `GET` | `{newHostUrl}/v1/authenticated/expertise` | CDHA bearer token | None | `{ success, data: AreaOfExpertise, message? }` | Loaded by root for non-profile pages; not edited directly in Renew |
| Load education | `GET` | `{newHostUrl}/v1/authenticated/education` | CDHA bearer token | None | `{ success, data: Education[], message? }` | Student renewal and student upgrade forms |
| Load communications | `GET` | `{hostUrl}/UpdateCommunications.ashx` | iMIS session cookie | None | `{ data: Communications }` | Consent/communications step |
| Load auto-renewal subscription | `POST` | `{hostUrl}/UpdateAutoRenew.ashx` | iMIS session cookie | `{}` | `{ data: AutoRenewalSubscription }` | Renew/upgrade validation and payment-plan state |
| Load member information | `POST` | `{hostUrl}/UpdatePersonalInfo.ashx` | iMIS session cookie | `{}` | `{ data: MemberInfo, server_time? }` | Member-type routing, validation, insurance, additional info, and submission payload |
| Load orofacial question | `GET` | `{newHostUrl}/v1/authenticated/cdhaquestions/OROFACIAL_STATUS` | CDHA bearer token | None | `{ data: CdhaQuestion[] }` | Merged into `memberInfo.orofacial_status` and `memberInfo.orofacial_seqn` |

Lookup tables requested by Renew are:

`COUNTRY`, `DEGREES`, `UNIVERSITY`, `GRAD_YEAR`, `GRAD_MONTH`, `YEAR_ATTEND`, `AREAS_OF_PRACTICE`, `WORK_ENVIRONMENT`, `INSURANCE`, `IPN_STATUS`, `INDIGENOUS_STATUS`.

## Renew and Upgrade Routes

`RenewRoute` redirects logged-in users to the route matching `memberInfo.member_type`. If the URL is under `/upgrade`, it redirects to `/upgrade/{member_type}` instead.

| Route | Member type | Visible steps | Submit orchestration |
| --- | --- | --- | --- |
| `/renew/STU` | `STU` | Communications, education, confirmation | `createNewMember({ type: "RENEW", memberType: "STU", ...formData })` |
| `/renew/FM` | `FM` | Communications, insurance when `memberInfo.show_ins_renew`, confirmation | `createNewMember({ type: "RENEW", memberType: "FM", paymentPlanContext: state.context, ...formData })` |
| `/renew/SUPPT` | `SUPPT` | Communications, confirmation | `createNewMember({ type: "RENEW", memberType: "SUPPT", paymentPlanContext: state.context, ...formData })` |
| `/renew/RET` | `RET` | Communications, additional info, optional payment-plan display, confirmation | Dispatches `createNewMember({ type: "RENEW", memberType: "RET", ...formData })` and separately dispatches `updateMemberInfoData(diff + id)` |
| `/renew/GRAD` | `GRAD` | Confirmation to upgrade to full member | `processUpgrade({ member_type: "GRAD" })` |
| `/upgrade/NM` | `NM` | Confirmation to upgrade to full member | `processUpgrade({ member_type: "NM" })` |
| `/upgrade/SUPPT` | `SUPPT` | Confirmation to upgrade to full member | `processUpgrade({ member_type: "SUPPT" })` |
| `/upgrade/FM` | `FM` | Confirmation to upgrade to supportive member | `processUpgrade({ member_type: "FM" })` |
| `/upgrade/STU` | `STU` | Education/province confirmation for student-to-full-member flow | `processUpgradeToGrad(...)` with `type: "UPGRADE_STUTOFM"` |

FM and SUPPT renew instantiate the payment-plan state machine, but their payment-plan wizard steps are currently commented out. RET renders the payment-plan component when the machine is in `display`, but the component's save button is only rendered for `location === "PROFILE"` and RET does not pass `paymentPlanContext` into `createNewMember`.

## Detailed Calls

### Load Lookup Data

| Field | Value |
| --- | --- |
| Method | `GET` |
| Endpoint | `{newHostUrl}/v1/lookupdata?table={table}` |
| Auth | None |
| Request | Query string `table` |
| Response | `{ data: LookupOption[] }` |
| Used by | Renew education, insurance, additional-info, and upgrade forms |

Lookup option shape is inferred from usage:

```json
{
  "Code": "...",
  "Name": "...",
  "CountryCode": "..."
}
```

### Load Member Information

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/UpdatePersonalInfo.ashx` |
| Auth | iMIS session cookie |
| Request | `{}` |
| Response | `{ data: MemberInfo, server_time?: string }` |
| Used by | Renew routing, `Validations type="RENEW"`, insurance logic, additional-info form, billing, cart/invoice flow, and upgrade flow |

The same endpoint is polled by upgrade flows after `ProcessUpgrade.ashx` until `data.show_renew` becomes true.

### Load Orofacial Question

| Field | Value |
| --- | --- |
| Method | `GET` |
| Endpoint | `{newHostUrl}/v1/authenticated/cdhaquestions/OROFACIAL_STATUS` |
| Auth | CDHA bearer token |
| Request | None |
| Response | `{ data: CdhaQuestion[] }` |
| Used by | Member-info loader; the first returned answer is merged into `memberInfo.orofacial_status` and `memberInfo.orofacial_seqn` |

### Load Communications

| Field | Value |
| --- | --- |
| Method | `GET` |
| Endpoint | `{hostUrl}/UpdateCommunications.ashx` |
| Auth | iMIS session cookie |
| Request | None |
| Response | `{ data: Communications }` |
| Used by | Renew communications/consent step |

### Load Auto-Renewal Subscription

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/UpdateAutoRenew.ashx` |
| Auth | iMIS session cookie |
| Request | `{}` |
| Response | `{ data: AutoRenewalSubscription }` |
| Used by | Renew and upgrade validation; payment-plan state machine context |

If an auto-renewal subscription already has `FREQUENCY` and `DUES_DRAFT_DATE`, Renew validation blocks the normal renew/upgrade flows and shows the signed-up auto-renewal error.

### Load Education

| Field | Value |
| --- | --- |
| Method | `GET` |
| Endpoint | `{newHostUrl}/v1/authenticated/education` |
| Auth | CDHA bearer token |
| Request | None |
| Response | `{ success: boolean, data: Education[], message?: string }` |
| Used by | Student renew education form and `/upgrade/STU` student-to-full-member flow |

### Load Areas of Expertise

| Field | Value |
| --- | --- |
| Method | `GET` |
| Endpoint | `{newHostUrl}/v1/authenticated/expertise` |
| Auth | CDHA bearer token |
| Request | None |
| Response | `{ success: boolean, data: AreaOfExpertise, message?: string }` |
| Used by | Loaded by `RootContainer` for Renew because `ownProps.type !== "PROFILE"`; the current Renew routes do not expose an expertise edit step |

### Update Communications During Renewal

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/UpdateCommunications.ashx` |
| Auth | iMIS session cookie |
| Request | Communications object with `is_update: true` and `email_address: memberInfo.email` |
| Response | `{ data: Communications }` |
| Used by | `createNewMember` final submit for STU, FM, SUPPT, and RET renewals |

Before sending, the client converts numeric `0` and `1` values to booleans. It removes most `*_updated` values and replaces `eventcal_updated` with a hard-coded `/Date(...)/` value.

After a successful update, the client refreshes communications with `GET {hostUrl}/UpdateCommunications.ashx`.

### Save Student Education During Renewal

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/UpdateDHEducation.ashx` |
| Auth | iMIS session cookie |
| Request | `{ update: { dh_degree, dh_university, dh_grad_year, dh_grad_month, dh_year_attend?, seqn? } }` |
| Response | `{ data: Education[] }` or Wicket/iMIS education response |
| Used by | `/renew/STU` final submit |

The renew education form preloads the first existing education record into the `addEducation` model and includes `seqn` when available.

After the legacy save succeeds, the shared helper waits two seconds and refreshes education:

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
| Request | Insurance/billing object from the `insurance` form, or `{}` for SUPPT/RET |
| Response | `{ data: any }` |
| Used by | `/renew/FM` insurance choice, `/renew/SUPPT` billing initialization, and `/renew/RET` billing initialization |

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
| Used by | `createNewMember` after communications/education/billing updates and before adding invoice lines to the cart |

For normal renewals, `memberInfo.id` should already exist, so the request should use the logged-in member id.

### Add Invoice to Cart

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/updateCart.ashx` |
| Auth | iMIS session cookie |
| Request | `{ "addInvoice": true }` |
| Response | Cart update JSON |
| Used by | `createNewMember` after `InvoiceTest.ashx` |

The Redux cart helper waits two seconds and refreshes cart items.

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
| Renew has an invoice line where `Item.ItemCode === "DUES"` | `/cdha/cart` or `/achd/cart` |
| STU renew without a dues invoice | `/cdha/stuconfirm` or `/achd/stuconfirm` |
| FM/SUPPT/RET renew without a dues invoice | Internal `/error` route and error emails |
| Other renew without a dues invoice | `/cdha/profile` or `/achd/profile` |

### Remove Existing Cart Lines

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/updateCart.ashx` |
| Auth | iMIS session cookie |
| Request | `{ lines: [{ productCode: line.Item.ItemCode, quantity: 0 }] }` |
| Response | Cart update JSON |
| Used by | Cleanup after `getCartItems.ashx` returns existing `res.lines` |

### Update RET Additional Information

The RET route dispatches this separately from `createNewMember` after final submit. It is not chained to the renew checkout promise.

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/UpdatePersonalInfo.ashx` |
| Auth | iMIS session cookie |
| Request | JSON string of changed member-info fields plus `id` |
| Response | `{ data: MemberInfo }` |
| Used by | `/renew/RET` additional-info changes |

The diff can include:

`first_name`, `last_name`, `street`, `street2`, `city`, `country`, `province`, `postal_code`, `cell_phone`, `phone`, `email`, `date_of_birth`, `preferred_language`, `exclude_directory`, `join_reason`, `job_description`, `password`, `indigenous_status`, `ipn_status`, `orofacial_status`, `orofacial_seqn`, and `id`.

After a successful update, the client waits two seconds and refreshes member info with `POST {hostUrl}/UpdatePersonalInfo.ashx`.

### Create or Update RET Orofacial Answer

If the RET additional-info diff contains `orofacial_status`, `updateMemberInfoData` writes the orofacial answer through the new API before updating `UpdatePersonalInfo.ashx`.

| Action | Method | Endpoint | Request | Response | Used by |
| --- | --- | --- | --- | --- | --- |
| Create answer | `POST` | `{newHostUrl}/v1/authenticated/cdhaquestions/OROFACIAL_STATUS` | `{ question_code, question, answer }` | New API JSON response | RET additional-info update when no `orofacial_seqn` exists |
| Update answer | `PUT` | `{newHostUrl}/v1/authenticated/cdhaquestions/OROFACIAL_STATUS/{seqn}` | `{ seqn, question_code, question, answer }` | New API JSON response | RET additional-info update when `orofacial_seqn` exists |

Current payload:

```json
{
  "question_code": "OROFACIAL_STATUS",
  "question": "Do you practice orofacial myofunctional therapy?",
  "answer": "yes"
}
```

### Process Upgrade

This flow is used by `/renew/GRAD`, `/upgrade/NM`, `/upgrade/SUPPT`, and `/upgrade/FM`.

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/ProcessUpgrade.ashx` |
| Auth | iMIS session cookie |
| Request | `{ member_type }` |
| Response | Wicket/iMIS upgrade response |
| Used by | Upgrade confirmation submit |

After `ProcessUpgrade.ashx`, the client polls member info up to five times, waiting eight seconds between attempts:

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/UpdatePersonalInfo.ashx` |
| Auth | iMIS session cookie |
| Request | `{}` |
| Response | `{ data: MemberInfo }`; polling checks `data.show_renew` |
| Used by | Upgrade completion wait loop |

When polling succeeds, the client refreshes member info through `getMemberInfoData()` and routes back to `/renew`.

### Process Student-to-Full-Member Upgrade

This flow is used by `/upgrade/STU`, which renders `UpgradeStuToGrad` with `type="UPGRADE_STUTOFM"`.

#### Optional province/chapter update

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/UpdatePersonalInfo.ashx` |
| Auth | iMIS session cookie |
| Request | `{ id: memberInfo.id, chapter: addEducation.provinceOfPractice }` |
| Response | `{ data: MemberInfo }` |
| Used by | Before upgrade if selected province of practice differs from `memberInfo.chapter` |

#### Submit upgrade

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/ProcessUpgrade.ashx` |
| Auth | iMIS session cookie |
| Request | `{ member_type: data.memberInfo.member_type, ndhcb_id }` |
| Response | Wicket/iMIS upgrade response |
| Used by | Student-to-full-member upgrade submit |

For `/upgrade/STU`, `ndhcb_id` is sent as `undefined` and the code redirects to `/cdha/renew` or `/achd/renew` after processing. The local `upgrade.member_type` is set to `"FM"`, but `processUpgradeToGrad` currently posts `data.memberInfo.member_type`.

#### Education update/delete call currently wired through remove helper

| Field | Value |
| --- | --- |
| Method | `DELETE` |
| Endpoint | `{newHostUrl}/v1/authenticated/education/{seqn}` |
| Auth | CDHA bearer token |
| Request | The remove helper expects `{ remove: [seqn] }` |
| Response | `{ success: boolean, data: Education[], message?: string }` |
| Used by | Called by `processUpgradeToGrad` after `ProcessUpgrade.ashx` |

Current code passes `{ update: { data: [educationFields] } }` into a helper that expects `data.remove[0]`. Unless another layer transforms the payload, this would build an endpoint ending in `undefined`.

### Conditional Payment-Plan APIs

Payment-plan update APIs are implemented in the shared state machine and in the `createNewMember` helper, but the active Renew routes do not fully wire them as normal final-submit calls:

| Location | Current status |
| --- | --- |
| `/renew/FM` and `/renew/SUPPT` | Payment-plan wizard steps are commented out. `paymentPlanContext` is still passed to `createNewMember`, so the branch can run only if `state.context.DUES` is somehow present. |
| `/renew/RET` | Payment-plan component can display options, but its save button is rendered only for `location === "PROFILE"` and `createNewMember` is called without `paymentPlanContext`. |

If this branch is re-enabled, it uses these endpoints:

| Action | Method | Endpoint | Request | Response |
| --- | --- | --- | --- | --- |
| Remove/add IPN cart lines | `POST` | `{hostUrl}/updateCart.ashx` | `{ lines: [{ productCode: "IPN", quantity }], removeInvoice: true }` plus independent-practice removal in `createNewMember` | Cart update JSON |
| Save auto-renewal/payment plan | `POST` | `{hostUrl}/UpdateAutoRenew.ashx` | `{ action: "UPDATE" \| "UNSUBSCRIBE", data: AutoRenewalUpdate \| null }` | `{ data: AutoRenewalSubscription }` |
| Machine summary refresh | `POST` | `{hostUrl}/UpdatePersonalInfo.ashx` | `{ get_summaryonly: true }` | `{ data: MemberInfo, server_time? }` |
| Machine auto-renewal refresh | `POST` | `{hostUrl}/UpdateAutoRenew.ashx` | `{}` | `{ data: AutoRenewalSubscription }` |

`AutoRenewalUpdate` can contain:

`PAYMENT_METHOD`, `CC_NUMBER`, `CC_NAME`, `CC_CCV`, `CC_MONTH`, `CC_YEAR`, `DUES_DRAFT_DATE`, `IPN_DRAFT_DATE`, `MONTHS`, `FREQUENCY`, `PERPETUAL`.

Draft dates are formatted as C# JSON dates using the selected `DD/MM` value and the hard-coded year `2026`.

### Error Notification Emails

#### Send operational error email

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/SendErrorEmail.ashx` |
| Auth | iMIS session cookie |
| Request | `{ emailSubject, emailMessage }` with password and credit-card fields stripped by regex |
| Response | `{ data: any }` |
| Used by | Renew checkout/cart failures and missing invoice diagnostics |

#### Send generic CDHA email

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/SendEmailGeneric.ashx` |
| Auth | iMIS session cookie |
| Request | `{ emailSubject, emailMessage }` with password and credit-card fields stripped by regex |
| Response | `{ data: any }` |
| Used by | Secondary notification for renew checkout/cart failures and missing invoice diagnostics |

## Non-Business Telemetry

`renewRoute.tsx` and the shared submit helper fire Google Analytics events in production when `window.gtag` exists.

| Event | When |
| --- | --- |
| `renew_start` | Renew route mounts |
| `invoice_added` | Renew submit found a `DUES` invoice line in the cart |
| `renew_success` | Student renew reached the student confirmation branch |
| `renew_success_auto_renewal` | Conditional payment-plan branch redirects to auto-renewal success |

## Response Shape Reference

### MemberInfo

Important fields consumed by Renew:

`id`, `first_name`, `last_name`, `street`, `street2`, `city`, `province`, `country`, `postal_code`, `email`, `phone`, `cell_phone`, `date_of_birth`, `preferred_language`, `exclude_directory`, `member_type`, `member_status`, `paid_thru`, `cut_date`, `chapter`, `insurance_code`, `insurance_expires`, `show_ins_renew`, `show_renew`, `has_IPN`, `purchased_IPN`, `ipn_status`, `indigenous_status`, `orofacial_status`, `orofacial_seqn`, `DUES_DRAFT_DATE`, `IPN_DRAFT_DATE`, `DRAFT_AMOUNT`, and installment fields.

### Communications

Important fields consumed by Renew:

`enews_subscribe`, `pd_subscribe`, `benefit_subscribe`, `products_subscribe`, `campaign_subscribe`, `eventcal_subscribe`, `job_notification_prov`, `e_ohcanada`, `third_party`, `gdpr_consent`, `gdprCommunity_consent`, `gdprLanguage_consent`, `email_address`, `is_update`, and related `*_updated` timestamp fields.

### Education

Important fields consumed by Renew:

`seqn`, `dh_degree`, `dh_university`, `dh_grad_year`, `dh_grad_month`, `dh_year_attend`, `provinceOfPractice`, `ndhcb_id`.

### Insurance

Important fields consumed by Renew:

`insurance`, `add_extension`.

### AutoRenewalSubscription

Important fields consumed by Renew:

`PAYMENT_METHOD`, `CC_NUMBER`, `CC_NAME`, `CC_MONTH`, `CC_YEAR`, `CC_CCV`, `DUES_DRAFT_DATE`, `IPN_DRAFT_DATE`, `MONTHS`, `FREQUENCY`, `PERPETUAL`.

### Cart

Important fields consumed by Renew:

`invoices.Lines[].Item.ItemCode` to detect `DUES`, and `lines[].Item.ItemCode` to remove existing cart lines.

## Legacy or Conditional APIs Found But Not Currently Reached

| Endpoint | Current status |
| --- | --- |
| `{hostUrl}/ValidateNewEmail.ashx?email={email}` | Used by `MemberInfoEdit`, but current Renew routes do not render the full member-info editor; RET additional info renders only IPN, indigenous, and orofacial fields. |
| Canada Post AddressComplete | Used by `MemberInfoEdit`, but current Renew routes do not render that address editor. |
| `{newHostUrl}/v1/authenticated/expertise` update | The shared expertise/education container imports the old expertise updater, but Renew hides expertise editing and only shows education for STU. |
| `{hostUrl}/UpdateAutoRenew.ashx` update and `{hostUrl}/updateCart.ashx` IPN payment-plan branch | Implemented in shared helpers, but normal Renew route wiring is commented or incomplete as described above. |

## Open Questions

- Confirm whether RET renew should pass `paymentPlanContext` into `createNewMember` or expose the payment-plan machine submit button for `location === "RENEW"`.
- Confirm whether `/upgrade/STU` should post `member_type: "FM"` to `ProcessUpgrade.ashx`; current code posts `data.memberInfo.member_type`.
- Confirm whether `processUpgradeToGrad` should update education through an update endpoint instead of calling the delete helper with an `{ update: ... }` payload.
- Confirm exact server response shapes for legacy `.ashx` endpoints. The frontend usually validates only top-level `data`, cart `lines`, invoice `Lines`, and `show_renew`.

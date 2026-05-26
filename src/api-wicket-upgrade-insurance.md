# Wicket API Calls - Upgrade Insurance

This page is the BC insurance upgrade flow in the Wicket section.

Entry point:
- `/home/lalves/dev/frontend/src/upgradeInsurancePage.tsx`

Route flow:
- `upgradeInsurancePage.tsx` renders `UpdateInsuranceRoute`
- `UpdateInsuranceRoute` wraps the flow in `RootContainer`
- `RootContainer` preloads member info, lookup tables, education, expertise, communications, and auto-renewal data
- `Validations type="BC_UPGRADE_INSURANCE"` blocks access unless the member is a BC full member
- The insurance step posts the insurance upgrade request
- If the upgrade creates an invoice, the flow adds the invoice to the cart and then reloads the cart before redirecting

## API Inventory

| Purpose | Method | Endpoint | Auth | Input | Output | Where Used |
| --- | --- | --- | --- | --- | --- | --- |
| Load lookup tables | `GET` | `{newHostUrl}/v1/lookupdata?table={table}` | None | Query string `table` | `{ data: LookupRow[] }` | Shared bootstrap via `RootContainer` |
| Load member info | `POST` | `{hostUrl}/UpdatePersonalInfo.ashx` | `withCredentials: true` session cookie | `{}` or `{ get_summaryonly: true }` | `{ data: MemberInfo, server_time? }` | Shared bootstrap via `RootContainer` |
| Load orofacial question | `GET` | `{newHostUrl}/v1/authenticated/cdhaquestions/OROFACIAL_STATUS` | CDHA bearer token | None | `{ data: QuestionAnswer[] }` | Indirect follow-up from `getMemberInfoData` |
| Load expertise | `GET` | `{newHostUrl}/v1/authenticated/expertise` | CDHA bearer token | None | `{ data: Expertise[] }` | Shared bootstrap via `RootContainer` |
| Load education | `GET` | `{newHostUrl}/v1/authenticated/education` | CDHA bearer token | None | `{ data: Education[] }` | Shared bootstrap via `RootContainer` |
| Load communications | `GET` | `{hostUrl}/UpdateCommunications.ashx` | `withCredentials: true` session cookie | None | `{ data: Communications }` | Shared bootstrap via `RootContainer` |
| Load auto-renewal | `POST` | `{hostUrl}/UpdateAutoRenew.ashx` | `withCredentials: true` session cookie | Empty body | `{ data: AutoRenewalSubscription }` | Shared bootstrap via `RootContainer` |
| Submit insurance upgrade | `POST` | `{hostUrl}/ProcessInsuranceUpgrade.ashx` | `withCredentials: true` session cookie | Empty body | `{ errors: [], invoice_total: number, ... }` | Insurance confirmation submit |
| Add invoice to cart | `POST` | `{hostUrl}/updateCart.ashx` | `withCredentials: true` session cookie | `{ addInvoice: true }` | Cart update response | Triggered only when `invoice_total > 0` |
| Refresh cart | `POST` | `{hostUrl}/getCartItems.ashx` | `withCredentials: true` session cookie | Empty body | `{ invoices: Invoice[], ... }` | Called by `updateCart` and again explicitly after invoice creation |

## 1. Shared Bootstrap

| Field | Value |
| --- | --- |
| Method | `GET` and `POST` |
| Endpoint group | `{newHostUrl}/v1/lookupdata?table={table}`, `{hostUrl}/UpdatePersonalInfo.ashx`, `{newHostUrl}/v1/authenticated/expertise`, `{newHostUrl}/v1/authenticated/education`, `{hostUrl}/UpdateCommunications.ashx`, `{hostUrl}/UpdateAutoRenew.ashx`, `{newHostUrl}/v1/authenticated/cdhaquestions/OROFACIAL_STATUS` |
| Used by | `components/profile/route/updateInsuranceRoute.tsx` through `containers/profile/rootContainer.tsx` |

### Lookup tables requested on mount

`RootContainer` loads these tables as a batch:
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

The visible form only uses the insurance options, but the route reuses the shared profile bootstrap. That means the page also hydrates the data used by the global Wicket validation, member-info banner logic, and any shared components that expect these slices to exist.

### Member info follow-up

`getMemberInfoData()` always performs a follow-up request to the orofacial question endpoint after `UpdatePersonalInfo.ashx` returns. The helper merges the answer into `memberInfo` when present.

## 2. Submit Insurance Upgrade

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/ProcessInsuranceUpgrade.ashx` |
| Auth | `withCredentials: true` session cookie |
| Request input | Empty object |
| Response | `{ errors: [], invoice_total: number, ... }` |
| Used by | `api/profile/upgradeInsurance.ts` |

### Purpose

The submit handler invokes the legacy Wicket upgrade endpoint. The code treats the response as successful only when:
- `errors.length === 0`
- `invoice_total > 0`

If the response does not satisfy that contract, the flow throws and routes to the error screen.

## 3. Add Invoice to Cart

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/updateCart.ashx` |
| Auth | `withCredentials: true` session cookie |
| Request input | `{ addInvoice: true }` |
| Response | Cart update payload |
| Used by | `api/profile/upgradeInsurance.ts` |

### Helper behavior

`updateCart.ts` posts the request, then after a short delay it refreshes the cart by calling `getCartItems.ashx` internally.

## 4. Refresh Cart

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/getCartItems.ashx` |
| Auth | `withCredentials: true` session cookie |
| Request input | Empty object |
| Response | `{ invoices: Invoice[], ... }` |
| Used by | `api/profile/upgradeInsurance.ts` and `api/cart/updateCart.ts` |

### Purpose

The submit flow explicitly refreshes the cart after invoice creation, then checks whether the cart contains an invoice. If it does, the client redirects to the cart page in the current language.

## Page-Level Submit Sequence

1. Post `ProcessInsuranceUpgrade.ashx`
2. If an invoice was created, post `updateCart.ashx` with `addInvoice: true`
3. `updateCart.ts` refreshes `getCartItems.ashx`
4. The upgrade flow explicitly calls `getCartItems.ashx` again
5. If the cart now contains an invoice, redirect to `/cdha/cart` or `/achd/cart`

## Response Shape Notes

- `ProcessInsuranceUpgrade.ashx` is consumed as a plain object with `errors` and `invoice_total` at the top level.
- `getCartItems.ashx` is checked with `hasInvoice(res)` before redirect.
- The route also uses `memberInfo.chapter`, `memberInfo.member_type`, and `serverTime` from the bootstrap responses to decide whether the member may enter the page.

## Open Notes

- This flow is BC-only. The validation layer rejects anything other than a BC full member.
- The route loads more profile data than the visible form uses because it inherits the shared `RootContainer` bootstrap.

# Cart API Calls

## Purpose

This page documents the API calls needed by the Cart application mounted from `/home/lalves/dev/cdha/client/src/App.tsx`.

The entry point renders `IndexPage`, which aliases `CartPage`. `CartPage` starts the XState `cartMachine`, and `CartPageComponent` renders cart sections from child machines for items, add-ons, donations, PD business course prompts, payment, and summary.

## Base URLs

| Alias | Development | Production | Used for |
| --- | --- | --- | --- |
| `hostUrl` | `https://www.cdha.ca/` | `//{window.location.hostname}` | Legacy Wicket/iMIS `.ashx` endpoints under `/CDHACommon` |
| Static card images | `//files.cdha.ca` | Same | Visa and Mastercard card-brand images |

The source builds Wicket URLs as `{hostUrl}/CDHACommon/{endpoint}.ashx`. Because the development `hostUrl` includes a trailing slash, development requests may contain a double slash before `CDHACommon`; browsers normalize this.

## Authentication

| API family | Authentication |
| --- | --- |
| Legacy Wicket/iMIS `.ashx` | Browser session cookies. The shared fetch wrapper always sends `credentials: "include"` and defaults to `POST`. |
| Static images | Public image URLs. |

The Cart page does not use the `newHostUrl` bearer-token flow used by Profile/Join/Renew.

## Initial Cart Load

| Action | Method | Endpoint | Authentication | Request | Response | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| Load member summary | `POST` | `{hostUrl}/CDHACommon/UpdatePersonalInfo.ashx` | iMIS session cookie | `{ "get_summaryonly": true }` | `{ data: MemberInfo, errors, server_time, status }` | First state in `cartMachine`; member data drives add-on eligibility, PD business course eligibility, and payment validation context |
| Load cart items | `POST` | `{hostUrl}/CDHACommon/getCartItems.ashx` | iMIS session cookie | Empty request body | `CartAPIResponse` | Second state in `cartMachine`; extracts invoices, lines, discount codes, order totals, taxes, and `invoicePaidThru` |
| Remove stale 2021 conference line | `POST` | `{hostUrl}/CDHACommon/updateCart.ashx` | iMIS session cookie | `{ lines: [{ productCode: "EVENT-2021CONF", quantity: 0 }] }` | Cart update JSON | Automatic cleanup when `getCartItems.ashx` returns a line whose `Event.EventId === "2021CONF"` |

If the cart response contains no `lines` and no `invoices.Lines`, the page enters the empty-cart state and makes no further business API calls.

## Cart Sections and API Usage

| UI section | Created when | API calls it can trigger |
| --- | --- | --- |
| Cart items | Cart has lines or an invoice | Remove cart lines, remove invoice |
| Donations | Cart has an invoice or a donation already in cart | Add/change donation amount, remove donation, toggle anonymous donation |
| Add-ons | Cart has an invoice | Add/remove Independent Practice add-on; auto-adds it on first load when member already has IPN but has not purchased IPN |
| PD business course prompt | Cart has `PD_BIZFUND`, `PD_BIZGROWTH`, or `PD_BIZPLN`, and member type is `FM`, `SUPPT`, `GRAD`, or `STU` | Apply/remove promo codes, add Independent Practice, remove PD business course lines |
| Payment | `order_data.order_total > 0` | Submit credit-card/payment data |
| Summary | Cart has lines or an invoice | No direct API calls |

## Detailed Calls

### Load Member Summary

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/CDHACommon/UpdatePersonalInfo.ashx` |
| Auth | iMIS session cookie |
| Request | `{ "get_summaryonly": true }` |
| Response | `{ data: MemberInfo, errors: any[], server_time: string, status: string }` |
| Used by | Initial `cartMachine` load; add-on, PD business course, and validation rules |

Important `MemberInfo` fields consumed by the cart:

`id`, `first_name`, `last_name`, `member_type`, `member_status`, `paid_thru`, `chapter`, `has_IPN`, `purchased_IPN`, `has_EDU`, `purchased_EDU`, `show_renew`, `show_invoice`, `insurance_code`, `insurance_expires`, `DUES_DRAFT_DATE`, `IPN_DRAFT_DATE`, and installment fields.

### Load Cart

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/CDHACommon/getCartItems.ashx` |
| Auth | iMIS session cookie |
| Request | Empty request body |
| Response | `CartAPIResponse` |
| Used by | Initial cart load, reload after every line/promo/payment-related child-machine update |

`CartAPIResponse` shape used by the app:

```json
{
  "discountCodes": "WEBINAR_IPN",
  "errors": [],
  "invoicePaidThru": "2026-10-31",
  "invoices": {
    "Balance": { "Amount": 100 },
    "InvoiceAmount": { "Amount": 100 },
    "Lines": []
  },
  "lines": [],
  "order_data": {
    "base_total": 100,
    "discount_total": 0,
    "order_total": 100,
    "taxes": {
      "TaxTotal": { "Amount": 0 },
      "OrderTaxes": []
    }
  },
  "status": "success"
}
```

Important line fields:

`lines[].Item.ItemCode`, `lines[].Item.Name`, `lines[].BaseUnitPrice.Amount`, `lines[].Discount.Amount`, `lines[].UnitPrice.Amount`, `lines[].ExtendedAmount.Amount`, `lines[].QuantityOrdered.Amount`, and optional `lines[].Event.EventId`.

Important invoice fields:

`invoices.Balance.Amount`, `invoices.InvoiceAmount.Amount`, `invoices.Lines[].Item.ItemCode`, `invoices.Lines[].Item.Name`, and tax invoice lines whose `Item.ItemCode` starts with `TAX`.

### Update Cart Lines

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/CDHACommon/updateCart.ashx` |
| Auth | iMIS session cookie |
| Request | `{ "lines": [{ "productCode": string, "quantity": number }] }` |
| Response | Cart update JSON |
| Used by | Removing regular items, changing quantities, donations, add-ons, PD business course add/remove, and stale conference cleanup |

Common product codes used by the active cart page:

| Product code | Used by |
| --- | --- |
| `IND_PRACTICE` | Independent Practice add-on and PD business course IPN offer |
| `CFDHRE5` | Donation product; quantity determines the donation amount in `$5` increments |
| `CFDHRE5_ANON` | Anonymous donation variant |
| `PD_BIZFUND`, `PD_BIZGROWTH`, `PD_BIZPLN` | PD business course products; removed when unavailable |
| `EVENT-2021CONF` | Stale conference line cleanup if present in the cart response |

When changing a quantity, the machines usually call `updateCart.ashx` twice: first with the same product code and `quantity: 0`, then with the new desired quantity. This pattern is used to force Wicket/iMIS to recalculate the cart cleanly.

### Remove Invoice

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/CDHACommon/updateCart.ashx` |
| Auth | iMIS session cookie |
| Request | `{ "removeInvoice": true, "lines": [{ "productCode": "EDUCATORS", "quantity": 0 }, { "productCode": "IND_PRACTICE", "quantity": 0 }] }` |
| Response | Cart update JSON |
| Used by | Clicking remove on the invoice row in `CartItems` |

This removes the invoice and clears add-ons tied to invoice checkout. `EDUCATORS` is included even though the current visible educators add-on is commented out.

### Apply or Remove Promo Code

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/CDHACommon/updateCart.ashx` |
| Auth | iMIS session cookie |
| Request | `{ "discountCodes": string }` |
| Response | Cart update JSON |
| Used by | PD business course promo logic |

Active promo-code values from `pdBizCourseMachine`:

| Value | Meaning |
| --- | --- |
| `PD_BIZFUND` | Applied when a PD business course is in cart and `IND_PRACTICE` is also in cart |
| `WEBINAR_IPN` | Applied when the member already has IPN and does not already have this promo |
| `""` | Removes/clears the promo code when no longer eligible |

### Submit Payment

| Field | Value |
| --- | --- |
| Method | `POST` |
| Endpoint | `{hostUrl}/CDHACommon/updatePaymentData.ashx` |
| Auth | iMIS session cookie |
| Request | Payment payload from the payment machine, or a zeroed default payload if no payment form is present |
| Response | Payment/update JSON from Wicket/iMIS |
| Used by | Cart submit button after payment and PD business course validation |

When payment is required, the client sends:

```json
{
  "PAYMENT_METHOD": "W_VISA",
  "CC_NUMBER": "4111111111111111",
  "CC_NAME": "Cardholder Name",
  "CC_CCV": 123,
  "CC_MONTH": 12,
  "CC_YEAR": 26,
  "DUES_DRAFT_DATE": null,
  "IPN_DRAFT_DATE": null
}
```

`PAYMENT_METHOD` is `W_VISA` for Visa cards and `W_MC` for Mastercard. The client validates card number, expiry, CVC, name, and accepted card type before submit.

If no payment form actor exists, the submit path sends:

```json
{
  "PAYMENT_METHOD": "W_MC",
  "CC_NUMBER": 0,
  "CC_NAME": 0,
  "CC_CCV": 0,
  "CC_MONTH": 0,
  "CC_YEAR": 0
}
```

On success, the browser navigates to `/confirmation`.

## Section-Specific Flows

### Regular Cart Items

| User action | API call |
| --- | --- |
| Remove an item | `POST updateCart.ashx` with `{ lines: [{ productCode, quantity: 0 }] }` |
| Change quantity | `POST updateCart.ashx` with quantity `0`, then `POST updateCart.ashx` with the new quantity |
| Remove invoice | `POST updateCart.ashx` with `removeInvoice: true` and add-on removal lines |

The current `CartItems` UI exposes remove actions. The machine also supports quantity changes.

### Donations

The active donation product is `CFDHRE5`; the selected quantity is `1` through `20`, representing `$5` through `$100`.

| User action | API call |
| --- | --- |
| Select a donation amount | Removes the current donation and anonymous variant if present, then adds `{ productCode: "CFDHRE5" or "CFDHRE5_ANON", quantity }` |
| Clear donation select | Sends quantity `0` for the donation product |
| Toggle anonymous donation | Removes the current donation and re-adds it with or without `_ANON` suffix |

### Add-ons

The visible add-on is Independent Practice:

```json
{
  "productCode": "IND_PRACTICE",
  "quantity": 1,
  "amount": 95
}
```

On first add-on load, if `memberInfo.data.has_IPN === true`, `purchased_IPN === false`, and the add-on is not already in cart, the machine automatically calls:

```json
{
  "lines": [
    { "productCode": "IND_PRACTICE", "quantity": 1 }
  ]
}
```

Manual add/remove uses the same `updateCart.ashx` line payload, with quantity `1` or `0`.

### PD Business Course Prompt

The PD business course prompt appears when the cart contains `PD_BIZFUND`, `PD_BIZGROWTH`, or `PD_BIZPLN`, and the member type is one of:

`FM`, `SUPPT`, `GRAD`, `STU`.

API behavior:

| Condition or action | API call |
| --- | --- |
| Student member has a PD business course product | `POST updateCart.ashx` removes `PD_BIZFUND`, `PD_BIZGROWTH`, and `PD_BIZPLN` |
| Inactive member has a promo code | `POST updateCart.ashx` with `{ discountCodes: "" }` |
| Member has IPN and missing `WEBINAR_IPN` promo | `POST updateCart.ashx` with `{ discountCodes: "WEBINAR_IPN" }` |
| `IND_PRACTICE` is in cart and missing `PD_BIZFUND` promo | `POST updateCart.ashx` with `{ discountCodes: "PD_BIZFUND" }` |
| `PD_BIZFUND` promo is applied but `IND_PRACTICE` is not in cart | `POST updateCart.ashx` with `{ discountCodes: "" }` |
| User accepts IPN offer | `POST updateCart.ashx` with `{ lines: [{ productCode: "IND_PRACTICE", quantity: 1 }] }` |
| User declines IPN offer | No API call; local state records `acceptOffer: false` |

Before payment submit, the parent machine requires the user to answer the PD business course IPN offer if the prompt is present.

## Non-Business Assets and Navigation

| Action | Method | Endpoint | Used by |
| --- | --- | --- | --- |
| Load Mastercard image | `GET` | `//files.cdha.ca/images/mastercardactive.png` or `mastercarddisabled.png` | Payment card-brand indicator |
| Load Visa image | `GET` | `//files.cdha.ca/images/visaactive.png` or `visadisabled.png` | Payment card-brand indicator |
| Confirmation navigation | Browser navigation | `/confirmation` | After successful `updatePaymentData.ashx` |

No Sentry or Google Analytics initialization is present in this cart entry point.

## Response Shape Reference

### CartAPIResponse

Important fields consumed by the Cart app:

`discountCodes`, `errors`, `invoicePaidThru`, `invoices`, `lines`, `order_data`, and `status`.

### Invoice

Important invoice fields:

`Balance.Amount`, `InvoiceAmount.Amount`, `Lines[].Item.ItemCode`, `Lines[].Item.Name`, and `Lines[].ExtendedAmount.Amount`.

Invoice lines whose item code starts with `TAX` are summed into `invoiceTaxAmount` and excluded from the visible invoice item description.

### Cart Line

Important line fields:

`Item.ItemCode`, `Item.Name`, `BaseUnitPrice.Amount`, `Discount.Amount`, `UnitPrice.Amount`, `ExtendedAmount.Amount`, `QuantityOrdered.Amount`, and optional `Event.EventId`.

### Order Data

Important order fields:

`base_total`, `discount_total`, `order_total`, `taxes.TaxTotal.Amount`, and `taxes.OrderTaxes`.

### Payment

Important payment fields:

`PAYMENT_METHOD`, `CC_NUMBER`, `CC_NAME`, `CC_CCV`, `CC_MONTH`, `CC_YEAR`, `DUES_DRAFT_DATE`, and `IPN_DRAFT_DATE`.

## Legacy or Unreached Cart APIs Found

These modules exist in the cart source tree, but are not currently reached from `/home/lalves/dev/cdha/client/src/App.tsx -> IndexPage -> CartPage -> CartPageComponent`.

| Endpoint | Current status |
| --- | --- |
| `{hostUrl}/CDHACommon/geteventdata.ashx?Event=2021CONF` | Imported by `cartConferenceMachine`, but that machine is not spawned by the active cart page. |
| `{hostUrl}/CDHACommon/UpdateEventRegistrationEx.ashx?Event=2021CONF` | Same; would register the 2021 conference if `CartConference` were mounted. |
| Conference promo codes `MEMCONF_2021`, `MEMCONF_2021_IPN`, `MEMCONF_2021_EDU`, `MEMCONF_2021_EIP`, `WEBINAR_EIP`, `WEBINAR_EDU` | Defined by `cartConferenceMachine`, but the active page only auto-removes stale `EVENT-2021CONF` lines. |
| `{hostUrl}/CDHACommon/GetLookupData.ashx?table=UNIVERSITY`, `GRAD_YEAR`, `GRAD_MONTH`, `DEGREES`, `YEAR_ATTEND` | Used by other pages in the same app source tree, not by the active Cart page. |
| `{hostUrl}/CDHACommon/UpdateDHEducation.ashx` | Used by video-submission/education flows in this app source tree, not by the active Cart page. |

## Open Questions

- Confirm whether the unmounted `CartConference`/`cartConferenceMachine` should remain out of scope or be restored to the active Cart page.
- Confirm whether `updatePaymentData.ashx` intentionally receives the zeroed payment payload when `order_total <= 0` or no payment form actor exists.
- Confirm exact server response shapes for `updateCart.ashx` and `updatePaymentData.ashx`; the current frontend mostly relies on HTTP success and then reloads cart state from `getCartItems.ashx`.

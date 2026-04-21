# Cart Reference

## Flow Map

| Flow / state | Visible screens / steps | Conditional notes |
| --- | --- | --- |
| Initial load | Cart shell -> loading overlay -> resolved cart display | Member info and cart data are both fetched before the page settles |
| Empty cart | Page title -> empty message | No summary, payment section, or submit button |
| Standard payable cart | Error panel if needed -> Cart Items -> PD Biz / IPN if applicable -> Add-ons if applicable -> Donation if applicable -> Payment Method -> Order Summary -> Place Order | Payment section only shows when total due is greater than zero |
| Zero-dollar cart | Error panel if needed -> Cart Items and other eligible sections -> Order Summary -> Place Order | Summary and submit remain visible even when payment is hidden |
| Submit blocked | Top-level error panel -> current cart sections remain visible | Page scrolls to top and shows blocking validation message |
| Successful submit | Cart validation -> payment submission -> `/confirmation` redirect | No intermediate success page inside the cart route |

### Shared Components

| Pattern | Cart |
| --- | --- |
| Page-level loading overlay | Yes |
| Top-level error panel | Yes |
| Table-based item list | Yes |
| Invoice grouping | Yes, when invoice exists |
| Conditional upsell / promo section | Yes, PD Biz / IPN only |
| Add-ons editor | Yes, invoice-driven |
| Donation editor | Yes |
| Payment form | Yes, when amount due is greater than zero |
| Order summary card | Yes |
| Submit action | Yes |

## Component Catalog

## 1. Cart Page Layout

### Purpose

This is the order review and checkout page used to display current cart content, invoice-derived renewal content, optional add-ons, donations, payment, and final submission.

### Visibility Matrix

| Surface | Cart Page |
| --- | --- |
| Review order layout | Yes |

### Main Layout Regions

| Region | Desktop | Mobile |
| --- | --- | --- |
| Main page structure | Two columns | Single column |
| Left column | Editable order sections | Shown first |
| Right column | Order summary and submit action | Shown after editable sections |

### Left Column Content

- Cart Items
- PD Biz / IPN promotional section when eligible
- Add-ons when eligible
- Donation when eligible
- Payment Method when amount due is greater than zero

### Right Column Content

- Order Summary
- `Place Order` button

## 2. Page-Level States

### Purpose

These are the major whole-page states that determine whether the user sees the normal cart content, a loading treatment, an empty state, or a blocking error state.

### State Matrix

| State | What the user sees | What is hidden / changed |
| --- | --- | --- |
| Initial loading | Existing page shell with blocking loading overlay and centered spinner | Interaction is blocked while data resolves |
| Empty cart | Page title and `No items in the cart.` message | No summary, payment section, submit button, or editable cart sections |
| Normal display | All sections whose own visibility rules pass | Non-eligible sections remain hidden |
| Error state | Prominent top-level error panel near the top of the page | Existing sections may remain visible below the error |

### Loading Behavior

- The loading treatment is an overlay, not a separate page.
- The underlying content remains visible but blocked visually.
- Most cart-edit interactions reuse this same loading pattern.

## 3. Error Panel

### Purpose

This is the top-level error surface used for page errors and blocked submit-time validation.

### Visibility Matrix

| Condition | Error panel shown? | Notes |
| --- | --- | --- |
| Unrecoverable page-level error | Yes | Appears near the top of the page |
| One or more top-level validation errors | Yes | Used for blocked submit states |
| No error state and no messages | No | Hidden entirely |

### What The User Sees

- Red error styling
- Error icon
- One or more specific messages, or a generic fallback message

### Example Messages

| Scenario | Message / meaning |
| --- | --- |
| Invalid payment data | Payment information is invalid |
| PD Biz / IPN unanswered | User must explicitly answer Yes or No |
| Cart update failure | Cart update failed |
| Payment submission failure | Payment could not be completed |

## 4. Cart Items Section

### Purpose

This is the main order-content table. It shows invoice-derived renewal content, standard cart items, or both.

### Visibility Matrix

| Condition | Cart Items shown? | Notes |
| --- | --- | --- |
| Invoice exists | Yes | Invoice row is shown first |
| Standard cart items remain after filtering special items | Yes | Item rows are shown |
| Neither invoice nor displayable cart items exist | No | Section is hidden |

### Table Structure

| Column | Content |
| --- | --- |
| `Description` | Invoice description or cart item name |
| `Price` | Display price |
| Action | `Remove` link |

### Invoice Row Rules

| Behavior | Rule |
| --- | --- |
| Placement | Invoice row appears before standard cart item rows |
| Description source | Built from invoice lines, not a single static label |
| Excluded invoice lines | Tax lines and lines containing `dues not collected` |
| Display amount | Invoice balance minus invoice tax amount |
| Removal | `Remove` link refreshes the cart and recalculates the section |

### Standard Cart Item Rules

| Behavior | Rule |
| --- | --- |
| Display label | Uses the cart item name |
| Display amount | Uses discounted amount when discount exists, otherwise normal item amount |
| Removal | `Remove` link triggers cart refresh and recalculation |

### Important Notes

- Invoice content behaves like a subtotal row, not the final total.
- Invoice and standard item content can appear together in the same table.

## 5. PD Biz / IPN Promotional Section

### Purpose

This is the promotional decision block that asks whether the user wants to add the Independent Practice Network offer when specific PD Biz courses are present.

### Visibility Matrix

| Condition | Section shown? | Notes |
| --- | --- | --- |
| Cart contains `PD_BIZFUND`, `PD_BIZGROWTH`, or `PD_BIZPLN` | Eligible | Requires qualifying member type |
| Member type is `FM`, `SUPPT`, `GRAD`, or `STU` | Eligible | Combined with course rule |
| Promo state already resolved automatically | No | UI stays hidden |

### What The User Sees

- Section heading `Independent Practice Network`
- One-row bordered table
- Description with link to IPN information
- Fixed displayed price of `$75.00`
- Radio choices `Yes*` and `No`
- Disclaimer text below the table

### Decision Rules

| Behavior | Rule |
| --- | --- |
| User must answer | Yes, when the section is visible |
| Accepting the offer | May add IPN to the order |
| Declining the offer | Valid path; the requirement is to answer, not to choose a specific option |
| No answer on submit | Blocks submission and shows top-level error |

### Hidden-State Rules

- The section can be skipped when the state machine already resolved the promo outcome.
- This includes cases such as existing IPN ownership, inactive-member handling, or promo state already resolved in the cart.

### Student Special Case

- If a student enters a path where the PD Biz course is not available, the UI shows a browser alert.
- The course is removed and the page reloads.

## 6. Add-ons Section

### Purpose

This is the optional add-ons editor used for invoice-driven add-on purchases.

### Visibility Matrix

| Condition | Add-ons shown? | Notes |
| --- | --- | --- |
| Invoice exists | Yes | Section becomes eligible to display |
| No invoice exists | No | Section is hidden |

### Available Add-ons

| Add-on | Notes |
| --- | --- |
| `Independent Practice` | Checkbox-based add-on |
| `Educators` | Checkbox-based add-on |

### Row Content

| Field | Display |
| --- | --- |
| Name | Add-on name |
| Price | Add-on price |
| Selection control | Checkbox |

### Add-on Rules

| Behavior | Rule |
| --- | --- |
| Check the box | Add-on is added and the page reloads |
| Uncheck the box | Add-on is removed and the page reloads |
| Invoice dependency | No invoice means no add-ons section |

### First-Load Auto-Selection Rule

| Condition | Outcome |
| --- | --- |
| Member already has IPN access | Candidate for auto-selection |
| Member has not purchased IPN yet | Candidate for auto-selection |
| `Independent Practice` add-on is not already in cart | Candidate for auto-selection |
| All three conditions pass | `Independent Practice` can be auto-added on first load |

## 7. Donation Section

### Purpose

This is the optional donation editor for CFDHRE donations.

### Visibility Matrix

| Condition | Donation shown? | Notes |
| --- | --- | --- |
| Invoice exists | Yes | Standard invoice-driven case |
| Donation already exists in cart | Yes | Keeps section visible even without invoice |
| No invoice and no donation | No | Section is hidden |

### What The User Sees

- Heading `CFDHRE Donation`
- Explanatory text
- External foundation link
- Amount dropdown
- Anonymous donation checkbox

### Donation Amount Rules

| Field | Rule |
| --- | --- |
| Control type | Select dropdown |
| Empty prompt | `Select Amount` |
| Available values | `$5` through `$100` in `$5` increments |
| Multi-amount behavior | Only one donation amount is active at a time |

### Donation Interaction Rules

| Behavior | Rule |
| --- | --- |
| Select donation amount | Donation is added or updated, then page reloads |
| Reset to empty option | Donation is removed, then page reloads |
| Toggle anonymous checkbox | Current donation is re-saved with updated anonymity state, then page reloads |

## 8. Payment Method Section

### Purpose

This is the credit-card payment form used when the order total is greater than zero.

### Visibility Matrix

| Condition | Payment section shown? | Notes |
| --- | --- | --- |
| Order total is greater than zero | Yes | User must provide valid payment details |
| Order total is zero | No | Summary and submit can still remain visible |

### What The User Sees

- Heading `Payment Method`
- Mastercard and Visa logos
- Card Number field
- Name on Card field
- Expiry Date field
- CVC field

### Payment Fields

| Field | Required | Validation / rules | Notes |
| --- | --- | --- | --- |
| `card_number` | Yes when payment section is shown | Must be a valid Visa or Mastercard number | Card-type detection affects icon state |
| `name_on_card` | Yes when payment section is shown | Must not be empty | Validated on blur and submit |
| `expiry_date` | Yes when payment section is shown | Must pass expiry validation | Formatted client-side |
| `cvc` | Yes when payment section is shown | Must pass card-type-aware CVC validation | Formatted client-side |

### Card Brand Feedback

| Entered card type | Visual result |
| --- | --- |
| Mastercard | Mastercard icon active, Visa disabled |
| Visa | Visa icon active, Mastercard disabled |
| Unknown or unsupported | Neither supported-brand state is valid |

### Field Layout

| Row | Fields |
| --- | --- |
| First row | Card Number, Name on Card |
| Second row | Expiry Date, CVC |

### Payment Rules

- The payment section does not refresh the cart while the user types.
- Validation is field-driven on blur and checked again on submit.
- Invalid fields receive invalid styling.
- The current implementation relies on invalid styling and top-level error feedback rather than inline help text under each field.

## 9. Order Summary and Submit

### Purpose

This is the summary area that shows the totals the user is about to pay and provides the final `Place Order` action.

### Visibility Matrix

| Condition | Summary shown? | Submit shown? |
| --- | --- | --- |
| Cart lines exist | Yes | Yes |
| Invoice exists | Yes | Yes |
| Nothing meaningful to summarize | No | No |

### Summary Card

| Summary element | Rule |
| --- | --- |
| Heading | `Order Summary` |
| Base total label | Changes based on invoice/cart composition |
| Base total amount | Invoice subtotal excluding invoice tax plus cart item total |
| Add-on line | Shows only when add-ons exist |
| Donation line | Shows only when donation exists |
| Tax line | Shows only when total tax is greater than zero |
| Final total | Emphasized as `You pay:` |

### Base Summary Labels

| Order composition | Label shown |
| --- | --- |
| Cart items only | `Cart Items` |
| Invoice content only | `Renewal Fees` |
| Invoice content and cart items | `Cart Items and Renewal fees` |

### Submit Button

| Behavior | Rule |
| --- | --- |
| Label | `Place Order` |
| Width | Full-width primary button |
| Validation | Always runs page-level validation before submission |

## 10. Submission and Validation Rules

### Submit Order

| Step | Validation / action |
| --- | --- |
| 1 | Check PD Biz / IPN decision requirement when that section is visible |
| 2 | Check payment validity when the payment section is active |
| 3 | Submit payment if blocking checks pass |
| 4 | Redirect to `/confirmation` on success |

### PD Biz / IPN Blocking Rule

| Condition | Result |
| --- | --- |
| Section visible and neither `Yes` nor `No` selected | Submission blocked |
| Section visible and either answer selected | Validation passes |

Blocked-submit message:

`Please answer if you would like to purchase the Independent Practice Network`

### Payment Blocking Rules

| Requirement | Must pass? |
| --- | --- |
| Name on card is not empty | Yes |
| Card number is valid | Yes |
| Expiry date is valid | Yes |
| CVC is valid for the detected card type | Yes |
| Card type is Visa or Mastercard | Yes |

Blocked-submit message:

`Payment information is invalid. Please check your credit card details and try again`

### Unsupported Card Types

- The form can accept typed input for other card brands.
- A structurally valid non-Visa / non-Mastercard number is still rejected at the form level.

## 11. Loading and Refresh Patterns

### Purpose

This describes the shared cart interaction pattern used by most editable sections.

### Refresh Pattern

| Interaction | Uses loading overlay? | Reloads cart? |
| --- | --- | --- |
| Remove invoice | Yes | Yes |
| Remove cart item | Yes | Yes |
| Toggle add-on | Yes | Yes |
| Change donation amount | Yes | Yes |
| Toggle anonymous donation | Yes | Yes |
| Accept or decline PD Biz / IPN offer | Yes | Yes |
| Type in payment fields | No | No |

### Shared Behavior

1. User interacts with a section.
2. Section enters loading.
3. The page shows the loading overlay.
4. The cart refreshes.
5. Section visibility and totals are recalculated from refreshed cart state.

### Important Distinction

- Most editable cart sections are server-refresh-driven.
- The payment form remains local until submit.

## 12. Structural Rules Summary

### Invoice-Driven Section Availability

| Section | Invoice exists | No invoice exists |
| --- | --- | --- |
| Invoice row in Cart Items | Can show | Hidden |
| Add-ons | Can show | Hidden |
| Donation | Can show | Hidden unless donation already exists |

### Localization

- Page text is translation-driven.

## 13. Example User Scenarios

### Empty Cart

| User sees | User does not see |
| --- | --- |
| `Review your Order` and `No items in the cart.` | Payment form, summary, submit button, editable sections |

### Invoice-Only Order

| User sees | Notes |
| --- | --- |
| Invoice row, add-ons, donation, summary, submit button | Payment also appears when amount due is greater than zero |

### Cart-Items-Only Order

| User sees | User does not see |
| --- | --- |
| Standard cart item rows, summary, submit button | Add-ons, and donation unless donation is already present |

### Invoice Plus Cart Items

| User sees | Important note |
| --- | --- |
| Invoice row and item rows together | Summary label becomes `Cart Items and Renewal fees` |

### Donation Without Invoice

| User sees | Why |
| --- | --- |
| Donation section remains visible | Existing donation keeps the section alive |

### Add-on Auto-Selected

| User sees | Why |
| --- | --- |
| Eligible add-on already selected | First-load business rules can auto-add it |

### Invalid Payment Attempt

| Result | Notes |
| --- | --- |
| Submission blocked, page scrolls to top, error banner shown | Relevant payment controls are also marked invalid |

### Unsupported Card Type

| Result | Notes |
| --- | --- |
| Submission blocked | Structural number validity alone is not enough |

### PD Biz / IPN Left Unanswered

| Result | Notes |
| --- | --- |
| Submission blocked with explicit IPN message | Either Yes or No is acceptable; the only invalid state is no answer |

### Zero-Dollar Order

| User sees | User does not see |
| --- | --- |
| Order summary and submit button | Payment section |

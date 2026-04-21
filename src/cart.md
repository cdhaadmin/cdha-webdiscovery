# CDHA Cart UI Functional Walkthrough

## Purpose
This document describes how the current CDHA cart UI behaves 

## Page Overview

### Layout
The page uses a centered container with a maximum width of about `960px`.

On desktop and larger screens:
- the page is split into two columns
- the left column is wider and contains editable order sections
- the right column is narrower and contains the order summary and submit button

On smaller screens:
- the layout collapses into a single column
- the sections remain in the same relative order
- editable sections appear first
- summary and submit appear after them

### Main content zones
The UI is organized into two functional areas.

Left column:
- cart items
- PD Biz / IPN promotional decision section when applicable
- add-ons
- donation
- payment

Right column:
- order summary
- `Place Order` button

## Top-Level Page States

### Initial loading state
When the page first loads, member information and cart information are fetched before the interface settles into its final state.

During this period:
- the page structure is still present
- a loading overlay can appear over the content area
- the user does not see a separate loading page

The loading treatment is an overlay:
- semi-transparent grey layer
- centered indeterminate spinner
- underlying content remains visible but blocked visually

### Empty state
If the cart has no applicable items and no invoice content, the page becomes an empty state.

The user sees:
- the page title
- the message `No items in the cart.`

The user does not see:
- summary
- payment form
- submit button
- editable cart sections

### Normal display state
If the cart contains displayable content, the page renders the relevant sections in order. Each section is shown only when its own conditions are satisfied.

### Error state
If the cart encounters an unrecoverable page-level error, the page shows a prominent error panel near the top.

The error panel:
- appears below the page title
- uses a red background and red border styling
- includes an error icon
- shows either one or more specific error messages or a generic fallback error message

This is also where submit-time validation errors appear.

## Section Order and Display Logic

### 1. Error panel
This is the first conditional content block under the heading.

It appears when:
- the page enters an error state, or
- the page has one or more top-level error messages

Why it appears:
- to communicate failures that affect the whole order flow
- to show validation messages that block submission

Examples of messages surfaced here:
- payment data is invalid
- the PD Biz / IPN question was not answered
- a cart update failed
- payment submission failed

### 2. Cart items section
This is the first main editable section in the left column.

It appears when either of these is true:
- there is an invoice to display
- there are cart items remaining after filtering out special item types

The section is rendered inside a bordered box and uses a table with three columns:
- `Description`
- `Price`
- action column with no visible heading text

#### Invoice row
If an invoice exists, the invoice is shown as the first row in the table.

The invoice row displays:
- invoice line names in the description column
- a single summarized invoice amount in the price column
- all invoice items are grouped together with a different text based on the province (doesn't show insurance and other specific items needed for renewal)
- a `Remove` link in the action column

The invoice description is not a single label. Instead, it is built from the invoice lines, with two filtering rules:
- tax lines are excluded
- lines whose name contains `dues not collected` are excluded

The amount shown for the invoice row is not the full invoice balance. It is:
- invoice balance
- minus invoice tax amount (tax will show in the summary)

This means the invoice row behaves like an invoice subtotal, not a grand total.

The invoice can be removed through the `Remove` link. Removing it triggers:
- loading state
- cart refresh
- full section recalculation

#### Standard cart item rows
After the invoice row, the cart section shows normal cart item rows.

Each row displays:
- item name
- item price
- `Remove` link

The price shown is the discounted amount when a discount exists. Otherwise it shows the item amount.

### 3. PD Biz / IPN promotional section
This section appears after cart items when specific course-related conditions are met.

Its purpose is to ask whether the user wants to add the Independent Practice Network offer associated with certain PD Biz courses.

It appears only when:
- the cart contains one of the PD Biz course items:
  - `PD_BIZFUND`
  - `PD_BIZGROWTH`
  - `PD_BIZPLN`
- and the member type is one of:
  - `FM`
  - `SUPPT`
  - `GRAD`
  - `STU`

The section is rendered as:
- a heading: `Independent Practice Network`
- a bordered table with one row
- a description with a link to the IPN information page
- a fixed displayed price of `$75.00`
- two radio choices:
  - `Yes*`
  - `No`
- disclaimer text below the table

#### What the user is deciding
The user is explicitly answering whether they want to purchase the Independent Practice Network in connection with the PD Biz course.

This decision matters because:
- it may add IPN to the order
- it may affect promo-code behavior behind the scenes
- it is required before submission when the section is visible

#### When the section does not appear
The section can be hidden automatically in several cases because the system resolves the situation without asking the user.

Hidden examples include:
- inactive members with no applicable promo-code path
- members who already have IPN and are handled through automatic promo-code behavior
- carts already containing the IPN add-on in a state where the promo has already been resolved

In these hidden cases, the UI does not show a question because the state machine has already determined the outcome.

#### Student special case
Students are a special case in this flow.

If the user is a student and enters a path where the PD Biz course is not available:
- the UI triggers a browser alert saying the course is not available to students
- the course is then removed
- the page reloads

### 4. Add-ons section
The add-ons section appears after the PD Biz / IPN area.

It appears only when an invoice exists.

This is a major display rule in the current cart:
- no invoice means no add-ons section
- invoice present means add-ons section is eligible to display

The currently active add-on list contains one item:
- `Independent Practice`
- `Educators`

The row displays:
- the add-on name
- the price
- a checkbox showing whether it is already in the cart

#### Add-on interaction
If the checkbox is selected:
- the add-on is considered in the cart

If the user unchecks it:
- the cart updates
- the page shows loading
- the page reloads and recalculates totals and section content

If the user checks it:
- the add-on is added
- the page reloads after the update

#### First-load auto-selection rule
This section has one important automatic behavior.

On the initial load of the add-ons section, the `Independent Practice` add-on can be automatically added if all of the following are true:
- the member already has IPN access
- the member has not purchased IPN yet
- the add-on is not already in the cart

This means the initial visual state of the checkbox is not always purely a reflection of manual user action. It can be set by business rules during first load.


### 5. Donation section
The donation section appears after add-ons.

It appears when either of these is true:
- an invoice exists
- a donation is already present in the cart

This means donation can remain visible even without an invoice if the user already has a donation selected.

The section contains:
- heading `CFDHRE Donation`
- explanatory text
- external link to the foundation website
- amount dropdown
- anonymous donation checkbox

#### Donation amount selector
The amount control is a select dropdown, not a freeform numeric input.

The first option is a blank prompt:
- `Select Amount`

The selectable donation amounts are fixed increments from:
- `$5`
- up to `$100`
- in `$5` steps

Internally this is implemented as twenty choices, but from the user’s perspective it behaves like a fixed donation amount selector.

#### Donation behavior
If the user selects an amount:
- the donation is added or updated
- the page enters loading
- the page reloads

If the user resets the select box back to the empty option:
- the donation is removed
- the page reloads

Only one donation amount is effectively active at a time.

#### Anonymous donation checkbox
The section also includes a checkbox for anonymous donation preference.

The label explains that donors are normally recognized publicly and that checking the box keeps the donation anonymous.

If the user toggles the checkbox:
- the page enters loading
- the current donation is re-saved in its anonymous or non-anonymous form
- the page reloads

### 6. Payment method section
The payment section appears after donations.

It appears only when the order total is greater than zero.

This means:
- orders with payable balances show the payment form
- zero-dollar orders do not show the payment form

The section contains:
- heading `Payment Method`
- bordered form container
- Mastercard and Visa images at the top
- card number input
- name on card input
- expiry date input
- CVC input

#### Card brand icons
The page displays both card logos at all times, but the visual state changes based on the detected card type.

If the entered card number is recognized as Mastercard:
- Mastercard icon appears active
- Visa icon appears disabled

If the entered card number is recognized as Visa:
- Visa icon appears active
- Mastercard icon appears disabled

If the card type is unknown or unsupported:
- neither supported-brand state is fully valid

This provides immediate visual feedback about what the form believes the card type is.

#### Field layout
The payment fields are arranged in two horizontal groups on larger screens.

First row:
- card number
- name on card

Second row:
- expiry date
- CVC

The expiry and CVC inputs are narrower than the name and card number fields.

#### Input formatting
The UI uses client-side formatting helpers for:
- card number
- expiry date
- CVC

This means the fields guide the user toward expected formatting as they type rather than behaving like plain raw text fields.

#### Payment validation timing
Validation is partially field-driven and partially submit-driven.

On blur:
- card number validation can run
- card type validation can run
- name validation can run
- expiry validation can run
- CVC validation can run

When a field is invalid, its form control is marked invalid visually.

The current implementation does not display inline help text beneath each field. The feedback is primarily:
- invalid field styling
- top-level error banner on blocked submit

## Order Summary and Submit

### Summary card
The order summary appears in the right column whenever there is something meaningful to summarize.

It appears when:
- there are cart lines, or
- there is an invoice

The summary uses:
- light grey background
- subtle border
- heading `Order Summary`

#### Summary line items
The summary begins with a subtotal-style line for the main order content, but the label changes depending on what is in the order.

Possible labels:
- `Cart Items`
- `Renewal Fees`
- `Cart Items and Renewal fees`

Why the label changes:
- to tell the user whether the base total comes from items, invoice renewal content, or both

The amount shown on this line is:
- invoice subtotal excluding invoice tax
- plus cart item total

#### Add-on total
If add-ons exist in the cart, the summary shows:
- `Total add-ons`
- corresponding total amount

#### Donation total
If a donation exists, the summary shows:
- `CFDHRE donation`
- corresponding donation amount

#### Tax line
The summary shows tax only when total tax is greater than zero.

The tax total combines:
- tax from order totals
- invoice tax amount

#### Final total
The bottom summary line is visually emphasized and labeled:
- `You pay:`

This is the grand total the user is expected to pay.

### Submit button
Below the summary is a full-width primary button labeled `Place Order`.

The button appears whenever the summary appears.

It does not submit blindly. It always routes through page-level validation first.

## Submission and Validation Rules

### Validation order
When the user presses `Place Order`, the page checks blocking conditions in a defined order.

The current order is:
1. PD Biz / IPN decision requirement
2. payment validity requirement
3. payment submission if all checks pass

### PD Biz / IPN blocking rule
If the PD Biz / IPN section is visible, the user must explicitly choose:
- Yes
- or No

If neither option is selected:
- submission is blocked
- the page scrolls to the top
- the error banner displays this message:

`Please answer if you would like to purchase the Independent Practice Network`

This is important because:
- both Yes and No are valid answers
- the invalid state is not “wrong answer”
- it is “no explicit answer provided”

### Payment blocking rules
If the payment section is active, the form must be valid before submission.

The form is valid only if all of the following are true:
- name on card is not empty
- card number passes card-number validation
- expiry date passes expiry validation
- CVC passes CVC validation for the detected card type
- detected card type is Visa or Mastercard

If payment is invalid at submit time:
- submission is blocked
- the page scrolls to the top
- the error banner displays:

`Payment information is invalid. Please check your credit card details and try again`

### Unsupported card types
The card form accepts typed input, but the overall payment form is only valid for:
- Visa
- Mastercard

A structurally valid card number for another brand is still rejected at the form level.

### Successful submission
If all blocking validations pass and payment processing succeeds:
- the user is redirected to `/confirmation`

The current cart does not show an intermediate success screen inside the cart page itself.

## Loading and Refresh Patterns

### Page-level principle
Most editable cart sections behave as small workflows that report loading to the parent page and then force a cart reload.

This pattern is used for:
- removing invoice
- removing cart item
- toggling add-on
- changing donation amount
- toggling anonymous donation
- accepting the PD Biz / IPN offer

The user experience is:
1. user interacts with a section
2. section enters loading
3. top-level content shows loading overlay
4. cart refreshes
5. page re-derives which sections should exist
6. totals and control states are updated

This means the visible UI is always recalculated from refreshed cart state rather than from long-lived client-only assumptions.

### Payment exception
The payment form is different.

Typing into payment fields:
- does not refresh the cart
- does not trigger a loading overlay
- remains local to the payment form until submit

## Special UI Rules

### Invoice-driven section availability
Invoice presence drives a large portion of the page structure.

If invoice exists:
- cart items section can show invoice row
- invoice items are grouped into the same item only showing 1 items and the total
- add-ons section appears
- donation section appears

If invoice does not exist:
- add-ons section disappears
- donation appears only if donation is already selected

This is one of the most important structural rules in the current UI.

### Localization
The page text is translation-driven.

## Example User Scenarios

### Empty cart
The user opens the cart and sees only:
- `Review your Order`
- `No items in the cart.`

There is no payment form and no submit button because there is nothing to complete.

### Invoice-only order
The user sees:
- invoice row in the cart items table
- add-ons section
- donation section
- summary
- submit button

If the total due is greater than zero, the payment section also appears.

### Cart-items-only order
The user sees:
- cart items table with standard cart rows
- summary
- submit button

The user does not see:
- add-ons, because there is no invoice
- donation, unless a donation is already in the cart

### Invoice plus cart items
The user sees both:
- invoice row
- item rows

The summary label becomes:
- `Cart Items and Renewal fees`

This tells the user the order total combines both types of content.

### Donation already selected without invoice
The user can still see the donation section even though there is no invoice, because an existing donation keeps that section visible.

The selected amount remains chosen in the dropdown, and the anonymous checkbox reflects the current donation mode.

### Add-on auto-selected
An eligible member opens the cart with an invoice and may see the add-on already selected even if they did not click the checkbox on that visit.

This comes from first-load eligibility rules, not from a random default.

### Invalid payment attempt
The user clicks `Place Order` with incomplete or invalid payment details.

The page:
- blocks submission
- scrolls to the top
- shows the top-level error banner
- marks relevant payment controls invalid

### Unsupported credit card type
The user enters a card number that is not Visa or Mastercard.

Even if the number format appears structurally valid, the order cannot be submitted because the supported card-type rule is stricter than basic numeric validity.

### PD Biz / IPN question left unanswered
The promotional section is visible, but the user clicks `Place Order` without choosing Yes or No.

The page blocks submission and shows the specific error asking the user to answer whether they want to purchase the Independent Practice Network.

### Zero-dollar order
The user has an order with visible order content but no amount due.

The page still shows:
- summary
- submit button

The page does not show:
- payment section

That separation is intentional in the current UI.
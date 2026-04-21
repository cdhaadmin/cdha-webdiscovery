# Join / Renew / Profile Reference

## Flow Map

| Flow | Visible screens / steps | Conditional notes |
| --- | --- | --- |
| [Join landing](./join-landing-flow-images.md) | Membership selection cards, eligibility information, visitor account link | Layout differs on mobile vs desktop |
| [Join STU](./join-stu-flow-images.md) | Member Information -> Education -> Communications -> Confirmation |  |
| [Join FM](./join-fm-flow-images.md) | Member Information -> Communications -> Insurance -> Payment Plan -> Confirmation | Payment-plan only shows when renew is launched and in the current year |
| [Join SUPPT](./join-suppt-flow-images.md) | Member Information -> Communications -> Confirmation | Payment-plan only shows when renew is launched and in the current year |
| [Join NM](./join-nm-flow-images.md) | Member Information -> Communications | Visitor-specific fields shown inside member information |
| [Renew STU](./renew-stu-flow-images.md) | Communications -> Education -> Confirmation |  |
| [Renew FM](./renew-fm-flow-images.md) | Communications -> Insurance -> Payment Plan -> Confirmation | Insurance step only appears when `show_ins_renew` is true; Payment-plan only shows when renew is launched and in the current year |
| [Renew SUPPT](./renew-suppt-flow-images.md) | Communications -> Payment Plan ->  Confirmation | Payment-plan only shows when renew is launched and in the current year |
| Renew GRAD | Confirmation | GRAD Renewal are converted to FM and have to run in the FM Wizard after conversion |
| [Renew RET](./renew-ret-flow-images.md) | Communications -> Additional Information -> Confirmation |  |
| [Profile Display](./profile-screens.md) | [Profile dashboard](./My-CDHA-Profile.png) / personal panels / [renewal summary](./profile_summary.png) / tables / province-of-practice request access | Expired credit-card banner may appear above content |
| Profile Edit | Member Information -> Communication Preferences -> Auto-Renewal / Payment Plan -> Areas of Expertise & Education | Sections are stacked, not wizard-based |

### Shared Components

| Pattern | Join | Renew | Profile Display | Profile Edit |
| --- | --- | --- | --- | --- |
| Member Information Editor | Yes | No | Summary | Yes |
| Communications editor | Yes | Yes | Summary | Yes |
| Education Editor | Yes STU only | Yes STU only | Summary | Yes |
| Areas of Expertise Editor | No | No | Summary | Yes |
| Insurance editor | Join FM only | Renew FM only | Summary | No |
| Confirmation editor | Yes | Yes | No | No |
| Payment Plan Editor | Yes | Yes | Summary | Yes |


## Shared Component Catalog

## 1. [Join Landing Page](https://www.cdha.ca/cdha/Membership_folder/Join_or_Renew_Today_folder/Join_Now_folder/CDHA/Membership/Join.aspx)

### Purpose

This is the entry page for unauthenticated users starting the Join journey.

### Visibility Matrix

| Surface | Join | Renew | Profile Display | Profile Edit |
| --- | --- | --- | --- | --- |
| Membership selection page | Yes | No | No | No |

### What The User Sees

- A warning banner at the top telling former members to renew instead of joining.
- A heading for the join experience.
- A set of membership cards:
  - Student
  - Graduate
  - Active dental hygienist
  - Support
  - Retired
- Each card shows:
  - icon
  - title
  - short description
  - "See details" action
  - call-to-action button
- A visitor account link below the membership cards.
- Eligibility content below the cards on desktop.
- A slider overlay for eligibility details on mobile.

### Mobile vs Desktop

| Behavior | Desktop | Mobile |
| --- | --- | --- |
| Membership options | Shown as columns/cards | Shown as stacked rows |
| Eligibility details | Rendered inline below the cards | Opened inside a slider |
| Card layout | Icon, text, CTA in panel | Icon with compact text and CTA |

## 2. Member Information Section

### Purpose

Member personal information details editor used in Join and Profile Edit, and the source of many shared validation rules across the overall system.

### Visibility Matrix

| Surface | Join | Renew | Profile Display | Profile Edit |
| --- | --- | --- | --- | --- |
| Member Information editor | Yes | No | Summary | Yes |

### High-Level UI Groups

- Personal Information
- Address / Location
- Contact & Communication
- Identity & Demographics
- Security

### Important Shared UI Behavior

- Names are editable only during JOIN.
- Some field sets depend on member type, some depend on country and some depends on current form information.

### Personal Information

| Field | Label shown to user | Join | Renew | Profile Edit | Member types | Required | Validation / rules | Conditional display / notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `first_name` | First Name | Yes | NA | Yes | All | Yes | Max 20 characters | Editable in Join; disabled everywhere else |
| `middle_name` | Middle Name | Yes | NA | Yes | All | No | Max 29 characters | Optional, Editable in Join; disabled everywhere else |
| `last_name` | Last Name | Yes | NA | Yes | All | Yes | Max 29 characters | Editable in Join; disabled everywhere else |
| `date_of_birth` | Date of Birth | Yes | NA | Yes | All, but special NM rule | Yes except NM | Must be a valid date string  |  |

### Address / Location

| Field | Label shown to user | Join | Renew | Profile Edit | Member types | Required | Validation / rules | Conditional display / notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `street` | Street Address | Yes | NA | Yes | All | Yes | Max 39 characters; commas removed by parser | Canada Post integration for autocomplete |
| `street2` | Street Address 2 | Yes | NA | Yes | All | No | Max 39 characters; commas removed by parser | Optional |
| `city` | City | Yes | NA | Yes | All | Yes | Max 39 characters; commas removed by parser |  |
| `country` | Country | Yes | NA | Yes | All | Yes | Required | Changing country clears province and resets postal handling |
| `province` | Province | Yes | NA | Yes | All | Required for CA, US, AU |  | Province options depend on selected country |
| `postal_code` | Postal Code | Yes | NA | Yes | All | Yes | CA postal validation for Canada; US ZIP validation for US | CA input is normalized to uppercase / spacing |
| `practice_different_province_yes/no` | "Do you practice in a different province or territory than where you live?" | Join only | NA | No | FM Join only | Effectively yes, because it controls downstream requirement | User chooses Yes or No | Only shown for FM during Join |
| `selected_chapter` | Select Chapter | Join only | NA | No | FM Join only | Required when country is CA and user answered Yes to different-province question | Required validator tied to prior answer | Only visible after selecting "Yes" |

### Address / Location Rules

- all addresses fields use Canada Post Autocomplete
- `country` is always required.
- FM and GRAD are not allowed outside Canada in the relevant contexts:
  - Join validation for FM / GRAD outside Canada
  - Profile validation behavior for FM / GRAD outside Canada
- Province is required only when country is CA, US, or AU.
- Postal code is required.
- Postal code format rules:
  - Canada: must be a valid Canadian postal code
  - US: must be a valid US ZIP code
  - Other countries: no country-specific format rule is applied
- FM Join has a special province-of-practice branch:
  - ask whether practice province differs from home province
  - if yes, show chapter selector
  - chapter selector becomes required

### Special Warning For US Users

- On Join, when country is US and member type is `FM`, `GRAD`, `SUPPT`, or `STU`, the user sees a warning that this is the Canadian Dental Hygienists Association site, not the California CDHA site.

### Contact & Communication

| Field | Label shown to user | Join | Renew | Profile Edit | Member types | Required | Validation / rules | Conditional display / notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `cell_phone` | Cell Phone | Yes | NA | Yes | All | At least one phone across cell/home | Max 24 characters; NANP validation for CA/US; formatted for CA/US | Changing cell phone refreshes home-phone validation |
| `phone` | Home Phone | Yes | NA | Yes | All | At least one phone across cell/home | Max 24 characters; NANP validation for CA/US; formatted for CA/US | Changing home phone refreshes cell-phone validation |
| `email` | Email | Yes | NA | Yes | All | Yes | Valid email; max 99 characters; async uniqueness check | Lowercased on change |
| `confirm_email` | Confirm Email | Yes | NA | Yes | All | Conditionally required | Must match current email; max 99 characters | Required only when email changed from original value |
| `alternate_email` | School Email | Yes |NA | Yes | STU only | No | If entered, must be valid email; max 99 characters | Only shown for students |

### Contact Rules

- At least one of `cell_phone` or `phone` must be provided.
- Phone formatting and validation are only enforced for Canada and US.
- `email` is required, validated, and checked asynchronously for availability.
- `confirm_email` only becomes required when the primary email changes from the original loaded value.
- `confirm_email` must match the primary email.
- `school email` is only shown for students and is optional, but if entered it must be a valid email.

### Identity & Demographics

| Field | Label shown to user | Join | Renew | Profile Edit | Member types | Required | Validation / rules | Conditional display / notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `preferred_language` | Preferred Language | Yes |NA | Yes | All | Yes | Required selection | English / French options |
| `ipn_status` | IPN Status | Yes | NA | Yes | FM, SUPPT, LIFE, RET | Yes for those groups | Required select | Hidden for STU and GRAD |
| `indigenous_status` | Indigenous Status | Yes | NA  | Yes | Most eligible member groups | No | No required validator in full member-info form | Shown broadly for eligible members |
| `orofacial_status` | Orofacial Status | Yes | NA | Yes | FM, GRAD, SUPPT, LIFE, RET | Yes | Required select | Hidden for STU |
| `job_description` | Job Description | Join only | No | No | NM Join only | Yes | Required; non-null selection | Visitor account only |
| `join_reason` | Join Reason | Join only | No | No | NM Join only | Yes | Required; non-null selection | Visitor account only |

### Identity Rules

- `preferred_language` is required for everyone using the full member-info form.
- `ipn_status` is required only for `FM`, `SUPPT`, `LIFE`, and `RET`.
- `indigenous_status` is shown but not required.
- `orofacial_status` is required for `FM`, `GRAD`, `SUPPT`, `LIFE`, and `RET`.
- Visitor / NM Join adds two extra required fields:
  - `job_description`
  - `join_reason`

### Security

| Field | Label shown to user | Join | Renew | Profile Edit | Member types | Required | Validation / rules | Conditional display / notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `password` | Password | Yes | No | Yes | All using this form | Required on Join, optional otherwise | Minimum 8 characters when entered | Changing password refreshes confirm-password field |
| `confirm_password` | Confirm Password | Yes | No | Yes | Same as above | Required only when password has a value | Must match password | No requirement if password is blank in non-Join cases |

### Security Rules

- On Join, password is required.
- Password must be at least 8 characters when provided.
- Confirm Password becomes required once Password has a value.
- Confirm Password must match Password.

## 3. Communication Preferences Section

### Purpose

This is the shared communication-preferences editor used in Join, Renew, and Profile Edit.

### Visibility Matrix

| Surface | Join | Renew | Profile Display | Profile Edit |
| --- | --- | --- | --- | --- |
| Communications editor | Yes | Yes | Summary Only | Yes |

### UI Blocks

- Overall email communications yes / no decision
- Detailed subscription options
- Job alerts and province selector
- Publication preference
- Third-party / letter-mail consent
- Privacy policy / GDPR consent

### Overall Communications Decision

| Behavior | Rule |
| --- | --- |
| User selects Yes | Turns on major communication subscriptions |
| User selects No | Turns off major communication subscriptions and clears job-alert province |
| Requirement | A yes/no decision is required |

### Detailed Subscription Options

These appear as individual checkboxes when the detailed options are shown:

- e-news
- professional development
- benefits
- products
- campaigns
- event calendar
- job alerts

### Detailed Options Visibility

| Surface | Shown? |
| --- | --- |
| Join | No, hidden |
| Renew | Yes |
| Profile Edit | Yes |

### Job Alerts

| Field | Join | Renew | Profile Edit | Required | Notes |
| --- | --- | --- | --- | --- | --- |
| `job_subscribe` | Hidden with detailed options | Yes | Yes | No | Controls province selector |
| `job_notification_prov` | Hidden with detailed options | Yes | Yes | No | Enabled only when job alerts are enabled |

### Publication Preference

| Field | Join | Renew | Profile Edit | Member types | Required |
| --- | --- | --- | --- | --- | --- |
| `e_ohcanada` | Yes | Yes | Yes | FM, SUPPT, LIFE | Yes |

### Third-Party / Letter-Mail Consent

| Field | Join | Renew | Profile Edit | Member types | Required |
| --- | --- | --- | --- | --- | --- |
| `third_party` | Yes | Yes | Yes | Hidden for NM | No |

### Privacy / GDPR Consent

| Field | Join | Renew | Profile Edit | Required | Notes |
| --- | --- | --- | --- | --- | --- |
| `gdpr_consent` | Yes | Yes | No | Yes | Text differs for BC |

### Communication Rules

- Join shows the top-level communications yes/no choice.
- Join hides the detailed subscription options block.
- Choosing "Yes" turns on the main communication subscriptions.
- Choosing "No" turns them off and clears the job-alert province.
- Job province selection is only enabled when job alerts are enabled.
- Publication choice (`e_ohcanada`) appears only for `FM`, `SUPPT`, and `LIFE`, and it is required.
- Third-party consent is hidden for `NM`.
- Privacy / GDPR consent appears only on Join and Renew and is required.
- BC gets a different privacy-consent wording in Join and Renew.

## 4. Insurance Section

### Purpose

This section appears only in Join and Renew flows and only for FM membership / renewal behavior and province-specific insurance rules.

### Visibility Matrix

| Surface | Join | Renew | Profile Display | Profile Edit |
| --- | --- | --- | --- | --- |
| Insurance editor | Join FM only | Renew FM only | Summary | No |

### Where It Appears

| Flow | Insurance shown? | Notes |
| --- | --- | --- |
| Join FM | Yes | Standard insurance step |
| Renew FM | Conditional | Only shown when `show_ins_renew` is true |

### What The User Sees

- One or more insurance radio options.
- Additional extension choices in some scenarios.
- Alberta-specific extension experience with multiple mutually exclusive choices.
- Informational notes and warnings depending on current insurance state.

### Base Selection Rule

- When the insurance section is shown, base insurance selection is required.

### Extension Behavior

Extension visibility depends on:

- member type
- Join vs Renew context
- membership cut date
- current server date
- current insurance expiry
- province / chapter
- Alberta special handling

### Alberta-Specific Behavior

For Alberta, the section may show a special PLI coverage / extension decision with multiple choices represented by the `add_extension` state:

- covered extension
- non-covered extension
- no extension selection

### Insurance Rules Summary

- Insurance appears in Join FM.
- Insurance appears in Renew FM only if `show_ins_renew` is true.
- Base insurance selection is required when shown.
- Extension UI depends on province/chapter and timing.
- Alberta has a special multi-option extension experience.

## 5. Payment Plan / Auto-Renewal Section

### Purpose

This is the user-facing payment-plan / auto-renewal experience. It is shared conceptually across several flows, but its visible usage differs significantly by route.

### Visibility Matrix

| Surface | Join | Renew | Profile Display | Profile Edit |
| --- | --- | --- | --- | --- |
| Full payment-plan editor | Yes FM, SUPPT, RET | Yes FM, SUPPT, RET | No | Yes |
| Payment-plan summary / signup link | No | No | Yes | No |

### What The User Sees In The Full Section

- Section title
- Dues options area
- IPN options area
- Saved-payment display or add-new-payment form
- Update button in Profile Edit
- Loading / success / error feedback

### `PaymentPlanComponent` As A Reusable User-Facing Component

`PaymentPlanComponent` should be understood as the reusable visible shell for payment-plan / auto-renewal behavior.

User-facing parts of this component:

- top section title
- dues selection sub-section
- IPN selection sub-section
- payment-method area
- validation / error surface
- success feedback surface
- profile-only update button

Migration implication:

- even when the dedicated route step is currently commented out, this component is still the intended reusable Join / Renew payment-plan UI and should be documented as shared future scope

### Whole-Section Visibility Rules

- The component can show:
  - dues only
  - IPN only
  - both dues and IPN
  - neither
- When hidden in Join or Renew contexts, the user sees "payment plan not available".

### Dues / IPN Option Rules

- Visibility depends on eligibility state, chapter/province, renewal state, and timing windows.

### Payment Card Area

When the user is entering new payment details, the validation messages are based on:

- card type
- card number
- cardholder name
- expiry
- CVC

### Payment Validation Messages

The visible error rules include:

- Only Mastercard or Visa are valid cards
- Invalid credit card number
- Invalid credit card name
- Invalid credit card expiration date
- Invalid credit card expiration CVC
- Please select a payment option

### Profile Display Auto-Renewal Summary

Profile Display includes a renewal summary component that can show:

- membership expiry or expired state
- renew-now link
- sign-up-for-payment-plan link
- auto-renewal dashboard when enrolled

### Payment Plan Rules Summary

- Profile Edit includes the full auto-renewal / payment-plan UI.
- Renew RET, FM, SUPPT includes a payment-plan step.
- The component may show dues, IPN, both, or neither based on elegibility.
- Only Visa and Mastercard are accepted.

## 6. Education

### Purpose

Member Education Information

### Visibility Matrix

| Surface | Join | Renew | Profile Display | Profile Edit |
| --- | --- | --- | --- | --- |
| Education editor | Yes, STU only | Yes, STU only | Summary | Yes |


### Join / Renew Version

- For STU Join and STU Renew, Education is an explicit wizard step.

### Education Fields Shown

| Field | Join | Renew | Profile Edit | Required rule |
| --- | --- | --- | --- | --- |
| Degree / level | Yes | Yes | Yes | Required during JOIN/RENEW or if any education field is being filled |
| University | Yes | Yes | Yes | Required during JOIN/RENEW or if any education field is being filled |
| Graduation month | Yes | Yes | Yes | Required during JOIN/RENEW or if any education field is being filled |
| Graduation year | Yes | Yes | Yes | Requiredduring JOIN/RENEW or if any education field is being filled |
| Current school year attended | Join/Renew only | Yes | No | Required during JOIN/RENEW  |

### Education Rules

- In Join / Renew, current school year is shown.
- In Profile Edit, the user sees education records on file plus an add-new path.
- In Join / Renew, university options exclude disabled universities.
- In STU Join, graduation-year options are constrained to current year and later.

### Profile Edit Version

Profile Edit uses "Areas of Expertise & Education" section.

What the user sees:

- For `FM`, `SUPPT`, `RET`, `LIFE`, and `GRAD`:
  - Areas of Expertise
  - divider
  - Education
- For `STU`:
  - Education only

## 7. Areas Of Expertise

### Purpose

Areas of Expertise (shows on Profile only).

### Visibility Matrix

| Surface | Join | Renew | Profile Display | Profile Edit |
| --- | --- | --- | --- | --- |
| Areas of Expertise editor | No | No | Summary | Yes |

### Join / Renew Version

- The Areas of Expertise portion is suppressed in Join and Renew.

### Profile Edit Version

Profile Edit uses a newer v2 "Areas of Expertise & Education" section.

What the user sees:

- For `FM`, `SUPPT`, `RET`, `LIFE`, and `GRAD`:
  - Areas of Expertise
  - divider
  - Education

### Areas Of Expertise Rules

| Field pair | Required? | Notes |
| --- | --- | --- |
| Work environment primary / secondary | Required for non-STU | STU is exempt |
| Area of expertise primary / secondary | Required for non-STU | STU is exempt |

## 8. Confirmation Section

### Purpose

This is the reusable final acknowledgement step used in Join and Renew flows.

### Visibility Matrix

| Surface | Join | Renew | Profile Display | Profile Edit |
| --- | --- | --- | --- | --- |
| Confirmation step | Yes | Yes | No | No |

### What The User Sees

- One or more checkbox/radio acknowledgement statements.
- Some member types get only one confirmation.
- Some member types get additional refund-related statements and notes.

### Universal Rule

- Every visible acknowledgement is required before the user can finish the step.

### Confirmation Matrix

| Flow | Confirmation content shown |
| --- | --- |
| Join FM / Renew FM | Confirmed statement plus refund-related statements / notes |
| Join STU / Renew STU | Confirmed statement only |
| Join SUPPT / Renew SUPPT | Confirmed statement plus refund-related statements / notes |
| Renew GRAD | Confirmed statement only |
| Renew RET | Confirmed statement plus refund-related statements / notes |
| Upgrade FM | Upgrade-specific confirmed statement |
| Upgrade SUPPT | Upgrade-specific confirmed statement |
| Upgrade NM | Upgrade-specific confirmed statement |
| BC upgrade-insurance | Upgrade-insurance-specific statements |



## 9. Profile Display-Only Sections

### Purpose

These are visible profile screens and panels that matter for migration scope even though they are not the shared edit forms.

### Visibility Matrix

| Surface | Join | Renew | Profile Display | Profile Edit |
| --- | --- | --- | --- | --- |
| Profile dashboard / display panels | No | No | Yes | No |

### Expired Credit-Card Alert Banner

- Profile route can show an alert banner when the stored card expiry is before today.
- The banner includes:
  - title
  - message
  - link to `/profile/edit/autorenewal`
  - trailing text after the link

### Profile Tables / Content Blocks

Profile Display includes several table-based panels, including the dashboard view shown in [My CDHA Profile](./My-CDHA-Profile.png):

- job ads
- membership add-ons
- conferences
- workshops
- on-demand webinars

These are mostly display based on information from Docebo (LMS).

### Province Of Practice Change Request Access

Profile Display exposes a route-driven modal / overlay form for province-of-practice change requests.

What the user sees:

- modal overlay
- title
- explanatory text
- textarea
- submit button
- success state
- error state

### Membership Renewal Summary Area

For eligible member types (`FM`, `STU`, `SUPPT`, `GRAD`, `RET`), the display can show the summary view shown in [Profile Summary](./profile_summary.png):

- renewal section title
- membership expiry date or expired message
- renew-now link when eligible
- sign-up payment-plan link when applicable
- auto-renewal dashboard summary

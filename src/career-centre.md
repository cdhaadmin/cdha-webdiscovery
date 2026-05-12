# Career Centre Reference

## Flow Map

| Flow / state | Visible screens / steps | Conditional notes |
| --- | --- | --- |
| [Post Your Job Ad](./career-centre-screens.md) | `/` redirects to `#/add` -> Job ad form -> Submit for Review -> Thank You or Error route | Form is blocked by client-side validation before the API request is made |
| Salary explanation | Salary field group -> `Salary is now mandatory` link -> modal -> Close | Modal explains the salary requirement and does not change form values |
| Successful job ad submission | Form submit -> `UpdateJobAd.ashx` -> `/success` route | User sees review timing message; submitter also receives an email confirming the post will be reviewed |
| Failed job ad submission | Form submit -> API/network error -> `/error` route | User sees a generic retry/contact-CDHA message |
| Staff review outcome | Submitted ad is reviewed outside the public form | User receives an email when the ad is approved, or when it is rejected with the rejection reason |
| [CDHA's Career Centre - Search](./career-centre-screens.md) | Email notification sign-up -> search title -> search bar and filters -> results table -> details popup | Search results are loaded once, sorted newest first, then filtered in the browser |
| Search by URL province | Page opened with `?Code={province}` -> results filtered to province | Used by email links |
| Search details | Select a result row -> details popup opens over the results table -> close icon or outside click closes it | Details are taken from the selected result row |

### Shared Components

| Pattern | Post Your Job Ad | Career Search |
| --- | --- | --- |
| Translation bundle | `jobAdd` | `jobAddv2` |
| Redux provider | Yes | Yes |
| Hash router | Yes | Yes |
| Google Places autocomplete | Yes, city/location | Yes, search location |
| Province lookup | Yes, from `COUNTRY` lookup | Yes, for email notification sign-up |
| Loading state | Yes, around submit | Yes, initial job-ad load and communication lookup |
| Error route / message | Yes | Initial load shows simple error text |
| Details popup | No | Yes |

## Component Catalog

## 1. Post Your Job Ad Page

### Purpose

This is the public job-ad submission form used by employers or other submitters to send a Career Centre posting to CDHA for review. Current examples are shown in [Career Centre Screens](./career-centre-screens.md).

### Entry Point

| Item | Current implementation |
| --- | --- |
| Application entry | `src/jobAddPage.tsx` |
| Rendered route component | `JobAddRoute` |
| Default route behavior | `/` redirects to `#/add` |
| Form route | `#/add` |
| Success route | `#/success` |
| Error route | `#/error` |
| Submit endpoint | `POST {hostUrl}/UpdateJobAd.ashx` with credentials |

### Page Layout

| Region | Content |
| --- | --- |
| Page title | `Post Your Job Ad` |
| Form body | Position, term, salary, location, dates, company, contact, description |
| Salary modal | Explanation shown from the `Learn why` link |
| Submit action | `Submit for Review` button centered at the bottom |

### Field Rules

| Field | Label shown to user | Required | Validation / rules | Submission notes |
| --- | --- | --- | --- | --- |
| `title` | Position Title | Yes | Non-empty after trim; max 100 characters | Posted as entered |
| `term` | Term | Yes | Must select one value | Values: `CONTRACT`, `FULL_TIME`, `PART_TIME`, `PERMANENT`, `TEMPORARY` |
| `salary` | Salary | Yes | Must select salary mode | Values: `RANGE` or `BASE`; default rendered option is `RANGE` |
| `minimum` | Minimum / Base | Yes | Number; greater than 0 | Used to build the formatted `salary` string |
| `maximum` | Maximum | Required when salary mode is `RANGE` | Number; greater than 0; must be higher than `minimum` | Cleared when salary mode is `BASE` |
| `rate` | Rate | Yes | Must select one value | Values: `hourly` or `yearly`; `yearly` is hidden when term is `PART_TIME` |
| `geographical_area` | City | Yes | Non-empty; max 100 characters; must come from Google Places unless province is `IN` | Google Places writes city, province, latitude, and longitude |
| `province` | Province | Yes | Must select province or International | Changing province clears latitude/longitude; non-international province clears city |
| `lat` | Hidden latitude | No | Set only by Google Places | Sent only when numeric |
| `lng` | Hidden longitude | No | Set only by Google Places | Sent only when numeric |
| `start_date` | Start Date | Yes | Must be a valid date; must be today or future | Format hint shown as `(MM/DD/YYYY)` |
| `deadline` | Deadline | Yes | Must be a valid date; must be today or future; cannot be more than 3 months after today | Format hint shown as `(MM/DD/YYYY)` |
| `co_name` | Company Name | Yes | Non-empty after trim; max 100 characters | Posted as entered |
| `contact_name` | Contact Info | Yes | Non-empty after trim; max 250 characters | Label says email, phone, etc. |
| `description` | Position Description | Yes | Non-empty after trim; max 5000 characters | Posted as entered |
| `qualifications` | Qualifications | No visible field | Field is commented out in the UI | Submitted as `N/A` |

### Salary Behavior

| Behavior | Rule |
| --- | --- |
| Salary is mandatory | The salary mode, amount, and rate are required before submit |
| Range salary | Submitted as `$minimum - $maximum/rate` |
| Base salary | Submitted as `$minimum / rate` |
| Part-time term | Yearly rate option is hidden |
| Salary explanation | `Learn why` opens a modal explaining wage-details requirements |

### Location Behavior

- Google Places autocomplete is restricted to Canadian regions.
- Selecting a Google Places location sets:
  - `geographical_area`
  - `province`
  - `lat`
  - `lng`
- Manually typing into City clears latitude and longitude.
- For Canadian province postings, the user must select a Google Places dropdown option.
- International postings use province value `IN` and do not require latitude/longitude.

### Submit Behavior

| Step | Behavior |
| --- | --- |
| Submit clicked | `react-hook-form` validates all registered fields |
| Validation fails | Invalid fields receive red border styling and inline error text |
| Validation passes | Data is transformed and posted to `UpdateJobAd.ashx` |
| API succeeds | Redux status becomes `success` and route changes to `#/success` |
| API fails | Redux status becomes `Error`, a shared error is set, and route changes to `#/error` |

### User Communications

- After successful submission, the page tells the user that CDHA staff will review the entry and post within the next 3 business days.
- After submission, the user receives an email confirming that the post will be reviewed.
- After staff review, the user receives an email if the posting is approved.
- If staff reject the posting, the user receives an email with the rejection reason.
- The approve/reject decision and email content are part of the review workflow outside the public `Post Your Job Ad` form.

## 2. Career Search Page

### Purpose

This is the public Career Centre search page used to browse approved job postings, filter by location or term, subscribe to job alerts, and open a detail popup for a selected posting.

### Entry Point

| Item | Current implementation |
| --- | --- |
| Application entry | `src/jobSearchPage.tsx` |
| Rendered component | `SearchIndex` from `components/jobv2/search` |
| Initial data endpoint | `POST {hostUrl}/GetJobAds.ashx` with `{ province: "" }` |
| Initial sort | `created_at` descending |
| Details source | Selected row from the loaded result data |
| Query-string filter | `Code` province parameter |

### Page Layout

| Region | Content |
| --- | --- |
| Email notification panel | Subscribe to weekly job alerts by province, or manage existing preference |
| Page title | `CDHA's Career Centre - Search` |
| Search bar | Google Places location input |
| Filters | All, Part-Time, Full-Time, International |
| Result summary | Most recent Canada message or search-specific count |
| Result table | Position, posted date, deadline, term, city/province |
| Load more | Adds the next page of results |
| Details popup | Opens over the results list after selecting a row |

### Initial Load

| Step | Behavior |
| --- | --- |
| Read query string | `Code` is read from the current URL |
| Load jobs | Calls `GetJobAds.ashx` once with an empty province |
| Sort jobs | Sorts returned items by `created_at` newest first |
| Load email sign-up data | Loads country lookup and current communication preferences |
| Error state | Shows simple error text if job data cannot be loaded |

### Search Filters

| Filter | Behavior |
| --- | --- |
| Location search | User must choose a Google Places dropdown option; pressing Enter with typed-only text opens an error modal |
| Province from URL | When `?Code={province}` exists, results are filtered by that province until a Google Places location is selected |
| City / sublocality | Matches result `geographical_area` exactly against selected city or sublocality |
| Geolocation | If both selected place and job have coordinates, jobs within 100 km are included |
| Part-Time | Adds or removes `PART_TIME` term filter |
| Full-Time | Adds or removes `FULL_TIME` term filter |
| All | Clears Part-Time and Full-Time term filters |
| International | Filters to province `IN`, clears location fields, and clears the typed search |

### Result Rules

| Behavior | Rule |
| --- | --- |
| Default results | If no filter is applied, all loaded jobs are shown newest first |
| Pagination | 10 results are shown per page |
| Load more | Increases the page count by 1 and shows 10 additional results |
| Empty results | No table rows are rendered |
| Mobile table | Columns after Posted Date are hidden below 600px |
| Row click | Opens the details popup for that row |

### Result Columns

| Column | Source / formatting |
| --- | --- |
| Position | `title` |
| Posted Date | `created_date`, formatted `MM/DD/YYYY` |
| Deadline | `deadline`, formatted `MM/DD/YYYY` |
| Term | `term`, lowercased and shortened from full time / part time to `F/T` / `P/T` |
| City, Province | `geographical_area`, `province` |

## 3. Details Popup

### Purpose

The details popup gives the user the full posting information without navigating away from the search results.

### Visibility Matrix

| Condition | Details popup shown? |
| --- | --- |
| No result selected | No |
| User selects a result row | Yes |
| User clicks close icon | No |
| User clicks outside popup, away from scrollbar area | No |

### Popup Content

| Field | Source / formatting |
| --- | --- |
| Job Title | `title`, followed by formatted `term` |
| Wage/Salary | `salary`, shown only when a salary value exists |
| Location | `geographical_area`, `province` |
| Company Name | `co_name` |
| Contact Info | `contact_name` |
| Posted | `created_date`, formatted `MM/DD/YYYY` |
| Deadline | `deadline`, formatted `MM/DD/YYYY` |
| Job Description | `description`, parsed as HTML |

### Popup Behavior

- The popup is absolutely positioned over the results area.
- The popup position is adjusted based on the current table position in the viewport.
- Opening a detail view sends a `gtag` page-view event with `?seqn={job seqn}` when Google Analytics is available.
- The close icon and outside-click behavior both return the user to the results table.

## 4. Email Notification Sign-up

### Purpose

This panel lets authenticated users subscribe to Career Centre email alerts for a selected province.

### Visibility Matrix

| Condition | What the user sees |
| --- | --- |
| No current job notification province | Sign-up panel with province selector |
| Existing job notification province | Success message and link to manage email preferences |

### Province Options

| Option type | Notes |
| --- | --- |
| All Provinces | Added as code `AP` |
| Canadian provinces | Loaded from the `COUNTRY` lookup |
| International | Added as code `IN` |

### Update Behavior

- Selecting a province writes `communications.job_notification_prov`.
- The update is sent through the shared communications update API with `is_update: true`.
- Existing subscribers are linked to `/profile#/profile/edit/communication?hashtag=/profile/edit/communication` to manage preferences.


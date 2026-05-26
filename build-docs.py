#!/usr/bin/env python3
from __future__ import annotations

import html
import re
import shutil
from pathlib import Path

try:
    from markdown_it import MarkdownIt
except ImportError as exc:  # pragma: no cover - runtime dependency check
    raise SystemExit(
        "markdown-it-py is required. Install it with: python3 -m pip install --user markdown-it-py"
    ) from exc


def page(source, output, nav_title, description, nav_group=None, nav_subgroup=None, aliases=None):
    result = {
        "Source": source,
        "Output": output,
        "NavTitle": nav_title,
        "Description": description,
    }
    if nav_group:
        result["NavGroup"] = nav_group
    if nav_subgroup:
        result["NavSubgroup"] = nav_subgroup
    if aliases:
        result["Aliases"] = list(aliases)
    return result


PAGES = [
    page(
        "join-renew-profile-ux-rules.md",
        "index.html",
        "Profile, Join and Renew",
        "Main components from the Profile Join and Renew user flow.",
        aliases=["join-renew-profile-ux-rules.html"],
    ),
    page(
        "join-landing-flow-images.md",
        "join-landing-flow-images.html",
        "Join Landing",
        "Screenshot walkthrough for the join landing experience.",
    ),
    page("join-stu-flow-images.md", "join-stu-flow-images.html", "Join STU", "Student join flow screenshots."),
    page("join-fm-flow-images.md", "join-fm-flow-images.html", "Join FM", "Full member join flow screenshots."),
    page(
        "join-suppt-flow-images.md",
        "join-suppt-flow-images.html",
        "Join SUPPT",
        "Support member join flow screenshots.",
    ),
    page("join-nm-flow-images.md", "join-nm-flow-images.html", "Join NM", "Non-member join flow screenshots."),
    page(
        "renew-stu-flow-images.md",
        "renew-stu-flow-images.html",
        "Renew STU",
        "Student renewal flow screenshots.",
    ),
    page("renew-fm-flow-images.md", "renew-fm-flow-images.html", "Renew FM", "Full member renewal flow screenshots."),
    page(
        "renew-suppt-flow-images.md",
        "renew-suppt-flow-images.html",
        "Renew SUPPT",
        "Support member renewal flow screenshots.",
    ),
    page("renew-ret-flow-images.md", "renew-ret-flow-images.html", "Renew RET", "Retired member renewal flow screenshots."),
    page("cart-screens.md", "cart-screens.html", "Cart Screens", "Screenshots for the cart UI states and promotional flow."),
    page("profile-screens.md", "profile-screens.html", "Profile Screens", "Screenshots for profile display and summary views."),
    page("cart.md", "cart.html", "Cart", "Functional walkthrough for the current cart UI."),
    page(
        "career-centre.md",
        "career-centre.html",
        "Career Centre",
        "Functional walkthrough for job ad posting and Career Centre search.",
    ),
    page(
        "career-centre-screens.md",
        "career-centre-screens.html",
        "Career Centre Screens",
        "Screenshots for job ad posting and Career Centre search.",
    ),
    page(
        "api-summary.md",
        "api-summary.html",
        "Summary",
        "Consolidated active API inventory for Wicket and WordPress.",
        nav_group="API Calls",
    ),
    page(
        "api-wicket-profile.md",
        "api-wicket-profile.html",
        "Profile",
        "Wicket API calls for profile workflows.",
        nav_group="API Calls",
        nav_subgroup="Wicket",
    ),
    page(
        "api-wicket-join.md",
        "api-wicket-join.html",
        "Join",
        "Wicket API calls for join workflows.",
        nav_group="API Calls",
        nav_subgroup="Wicket",
    ),
    page(
        "api-wicket-renew.md",
        "api-wicket-renew.html",
        "Renew",
        "Wicket API calls for renewal workflows.",
        nav_group="API Calls",
        nav_subgroup="Wicket",
    ),
    page(
        "api-wicket-standalone-communications.md",
        "api-wicket-standalone-communications.html",
        "Standalone Communications",
        "Wicket API calls for standalone communications preference editing.",
        nav_group="API Calls",
        nav_subgroup="Wicket",
    ),
    page(
        "api-wicket-upgrade-insurance.md",
        "api-wicket-upgrade-insurance.html",
        "Upgrade Insurance",
        "Wicket API calls for the BC insurance upgrade flow.",
        nav_group="API Calls",
        nav_subgroup="Wicket",
    ),
    page(
        "api-wicket-upgrade-stu-to-grad.md",
        "api-wicket-upgrade-stu-to-grad.html",
        "Upgrade STU to Grad",
        "Wicket API calls for the student-to-graduate upgrade flow.",
        nav_group="API Calls",
        nav_subgroup="Wicket",
    ),
    page("api-wicket-cart.md", "api-wicket-cart.html", "Cart", "Wicket API calls for cart workflows.", nav_group="API Calls", nav_subgroup="Wicket"),
    page(
        "api-wicket-cfdhre-donations.md",
        "api-wicket-cfdhre-donations.html",
        "CFDHRE Donations",
        "Wicket API calls for CFDHRE donations.",
        nav_group="API Calls",
        nav_subgroup="Wicket",
    ),
    page(
        "api-wordpress-job-add.md",
        "api-wordpress-job-add.html",
        "Job Add",
        "WordPress API calls for adding jobs.",
        nav_group="API Calls",
        nav_subgroup="WordPress",
    ),
    page(
        "api-wordpress-job-search.md",
        "api-wordpress-job-search.html",
        "Job Search",
        "WordPress API calls for job search.",
        nav_group="API Calls",
        nav_subgroup="WordPress",
    ),
    page(
        "api-wordpress-events-add.md",
        "api-wordpress-events-add.html",
        "Events Add",
        "WordPress API calls for adding events.",
        nav_group="API Calls",
        nav_subgroup="WordPress",
    ),
    page(
        "api-wordpress-events-search.md",
        "api-wordpress-events-search.html",
        "Events Search",
        "WordPress API calls for event search.",
        nav_group="API Calls",
        nav_subgroup="WordPress",
    ),
    page(
        "api-wordpress-pypo-photos.md",
        "api-wordpress-pypo-photos.html",
        "Pypo Photos",
        "WordPress API calls for Pypo Photos.",
        nav_group="API Calls",
        nav_subgroup="WordPress",
    ),
    page(
        "api-wordpress-image-gallery.md",
        "api-wordpress-image-gallery.html",
        "Image Gallery",
        "WordPress API calls for the image gallery.",
        nav_group="API Calls",
        nav_subgroup="WordPress",
    ),
    page(
        "api-wordpress-coloring-contest.md",
        "api-wordpress-coloring-contest.html",
        "Coloring Contest",
        "WordPress API calls for Coloring Contest.",
        nav_group="API Calls",
        nav_subgroup="WordPress",
    ),
    page(
        "api-wordpress-docebo.md",
        "api-wordpress-docebo.html",
        "Docebo",
        "WordPress API calls for Docebo.",
        nav_group="API Calls",
        nav_subgroup="WordPress",
    ),
]


def assert_inside_root(base_path: Path, candidate_path: Path) -> None:
    resolved_base = base_path.resolve()
    resolved_candidate = candidate_path.resolve()
    if not str(resolved_candidate).startswith(str(resolved_base)):
        raise RuntimeError(f"Refusing to write outside the workspace: {resolved_candidate}")


def convert_markdown_links(html_text: str, link_map: dict[str, str]) -> str:
    updated = html_text
    for source_name, target_name in link_map.items():
        updated = updated.replace(f'href="./{source_name}"', f'href="./{target_name}"')

    updated = re.sub(
        r'href="(https?://[^"]+)"',
        r'href="\1" target="_blank" rel="noreferrer"',
        updated,
    )
    return updated


def get_title_from_markdown(markdown_text: str) -> str:
    match = re.search(r"(?m)^#\s+(.+?)\s*$", markdown_text)
    if match:
        return match.group(1).strip()
    return "Documentation"


def new_nav_items_html(nav_pages: list[dict[str, object]], current_output: str) -> str:
    items = []
    for nav_page in nav_pages:
        is_active = nav_page["Output"] == current_output
        class_name = "nav-link active" if is_active else "nav-link"
        description = html.escape(str(nav_page["Description"]))
        nav_title = html.escape(str(nav_page["NavTitle"]))
        items.append(
            f'<a class="{class_name}" href="./{nav_page["Output"]}">\n'
            f'  <span class="nav-title">{nav_title}</span>\n'
            f'  <span class="nav-description">{description}</span>\n'
            f"</a>"
        )
    return "\n".join(items)


def new_site_html(page: dict[str, object], title: str, body_html: str, pages: list[dict[str, object]]) -> str:
    safe_title = html.escape(title)
    primary_pages = [p for p in pages if p["Output"] in {"index.html", "cart.html", "career-centre.html"}]
    screen_pages = [p for p in pages if p["Output"] not in {"index.html", "cart.html", "career-centre.html"} and p.get("NavGroup") != "API Calls"]
    summary_api_pages = [p for p in pages if p.get("NavGroup") == "API Calls" and not p.get("NavSubgroup")]
    wicket_api_pages = [p for p in pages if p.get("NavGroup") == "API Calls" and p.get("NavSubgroup") == "Wicket"]
    wordpress_api_pages = [p for p in pages if p.get("NavGroup") == "API Calls" and p.get("NavSubgroup") == "WordPress"]

    primary_nav_html = new_nav_items_html(primary_pages, page["Output"])
    screen_nav_html = new_nav_items_html(screen_pages, page["Output"])
    summary_api_nav_html = new_nav_items_html(summary_api_pages, page["Output"])
    wicket_api_nav_html = new_nav_items_html(wicket_api_pages, page["Output"])
    wordpress_api_nav_html = new_nav_items_html(wordpress_api_pages, page["Output"])

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>{safe_title}</title>
  <link rel="stylesheet" href="./assets/site.css" />
</head>
<body>
  <div class="page-shell">
    <aside class="sidebar">
      <a class="brand" href="./index.html">CDHA Web Discovery</a>
      <p class="sidebar-copy">Main components and user flows for the CDHA website.</p>
      <nav class="nav-list" aria-label="Documentation">
{primary_nav_html}
        <div class="nav-divider"></div>
        <section class="nav-section" aria-label="Website Screens">
          <p class="nav-section-title">Website Screens</p>
{screen_nav_html}
        </section>
        <div class="nav-divider"></div>
        <section class="nav-section" aria-label="API Calls">
          <p class="nav-section-title">API Calls</p>
          <p class="nav-subsection-title">Summary</p>
{summary_api_nav_html}
          <p class="nav-subsection-title">Wicket</p>
{wicket_api_nav_html}
          <p class="nav-subsection-title">WordPress</p>
{wordpress_api_nav_html}
        </section>
      </nav>
    </aside>
    <main class="content">
      <article class="markdown-body">
{body_html}
      </article>
    </main>
  </div>
</body>
</html>
"""


def main() -> None:
    root = Path(__file__).resolve().parent
    source_dir = root / "src"
    docs_dir = root / "docs"
    assets_dir = docs_dir / "assets"
    site_css_source = assets_dir / "site.css"

    if not site_css_source.exists():
        raise SystemExit(
            "Missing docs/assets/site.css. Build the repo from a checkout that includes the generated docs tree."
        )

    site_css = site_css_source.read_text(encoding="utf-8")

    link_map = {page["Source"]: page["Output"] for page in PAGES}

    if docs_dir.exists():
        shutil.rmtree(docs_dir)

    docs_dir.mkdir(parents=True)
    assets_dir.mkdir(parents=True)
    (assets_dir / "site.css").write_text(site_css, encoding="utf-8")
    (docs_dir / ".nojekyll").write_text("", encoding="utf-8")

    for entry in source_dir.iterdir():
        if entry.is_file() and entry.suffix.lower() in {".png", ".jpg", ".jpeg", ".gif", ".svg", ".webp"}:
            shutil.copy2(entry, docs_dir / entry.name)

    markdown = MarkdownIt("commonmark", {"html": True}).enable("table")

    for page in PAGES:
        source_path = source_dir / page["Source"]
        markdown_text = source_path.read_text(encoding="utf-8")
        title = get_title_from_markdown(markdown_text)
        body_html = markdown.render(markdown_text)
        body_html = convert_markdown_links(body_html, link_map)
        site_html = new_site_html(page, title, body_html, PAGES)

        output_path = docs_dir / page["Output"]
        assert_inside_root(root, output_path)
        output_path.write_text(site_html, encoding="utf-8")

        for alias in page.get("Aliases", []):
            alias_path = docs_dir / alias
            assert_inside_root(root, alias_path)
            alias_path.write_text(site_html, encoding="utf-8")

    print(f"Generated static site in {docs_dir}")


if __name__ == "__main__":
    main()

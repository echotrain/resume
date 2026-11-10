# Resume

A small Elixir app that turns `priv/resume.json` into a static resume page, published to GitHub Pages at
<https://echotrain.github.io/resume/>.

It uses `Phoenix.Component` and HEEx for templating only. There is no endpoint, router or server.

## Usage

```sh
mix deps.get
mix resume.build          # writes output/index.html; output/assets links to assets/
open output/index.html    # asset paths are relative, so file:// works
mix resume.build --copy   # copies assets/ instead, as the deploy does
mix check                 # format check, credo, tests
```

Locally (the `dev` environment) `output/assets` is a symlink to `assets/`, so CSS and JS edits show up on a
browser refresh with no rebuild. Rebuild only after changing `priv/resume.json` or the templates. CI passes
`--copy` so the deployed folder is self-contained.

## Layout

| Path | Purpose |
|---|---|
| `priv/resume.json` | The resume content. Edit this to change the resume. |
| `lib/resume/content.ex` | Structs the JSON is decoded into; a missing key fails the build. |
| `lib/resume/dates.ex` | Month formatting and tenure ("7 yrs"). |
| `lib/resume/components.ex` | HEEx function components for the page. |
| `assets/` | Hand-written CSS and JS, plus self-hosted Montserrat (SIL OFL). |
| `.github/workflows/pages.yml` | Tests, builds, checks the page count, deploys to Pages. |

## Content notes

- Months are `"YYYY-MM"`. Leave a role's `end` out (or `null`) for a current role; it renders as "Present".
- A highlight is either a string or `{"lead": "Bold lead-in:", "text": "..."}`.
- Roles are nested under their employer, so several positions at one company render as one block with the
  combined tenure.

## Privacy

Phone and email are never stored in this repo or rendered into the page; tests enforce this. The Print button
opens a dialog where they can be typed in for that one printed copy. They are held in the page only until
printing finishes.

## Printing

Print styles target US Letter and at most two pages. CI prints the page with headless Chrome and fails if it
runs past two pages; the resulting PDF is attached to each workflow run as the `resume-pdf` artifact.

## Deployment

Pushing to `main` runs the workflow and deploys. One-time setup: in the repository settings, under Pages, set
the source to "GitHub Actions".

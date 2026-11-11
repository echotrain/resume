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
| `.github/workflows/pages.yml` | Tests, builds and deploys to Pages. |

## Easter egg (spike)

`game/index.html` boots this same Mix app in the browser with [Popcorn](https://hexdocs.pm/popcorn/), a BEAM
compiled to WebAssembly. `Resume.Application` starts a task that writes a greeting into the page from Elixir.

```sh
MIX_ENV=prod mix site.build   # resume page + browser runtime in output/game/out
MIX_ENV=prod mix popcorn.dev --dir output --out-dir output/game/out
# then open http://localhost:4000/game/index.html
```

The runtime needs cross-origin isolation headers, which GitHub Pages cannot send. `game/coi-serviceworker.js`
(vendored from gzuidhof/coi-serviceworker, MIT) adds them in the browser and reloads the page once on first
visit. Its scope is the `game/` folder, so the resume page is unaffected. Opening the page as a local file does
not work, because service workers need `http://localhost` or HTTPS.

Build with `MIX_ENV=prod`: Popcorn packages every compiled dependency in the build directory, and the dev
environment has many more of them.

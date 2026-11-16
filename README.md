# Resume

A small Elixir app that turns `priv/resume.json` into a static resume page, published to GitHub Pages at
<https://echotrain.github.io/resume/>.

It uses `Phoenix.Component` and HEEx for templating only (no endpoint, router or server).

## Usage

```sh
mix deps.get
mix resume.build          # writes output/index.html; output/assets links to assets/
open output/index.html    # asset paths are relative, so file:// works
mix resume.build --copy   # copies assets/ instead, as the deploy does
mix check                 # format check, credo, tests
```

Locally (the `dev` environment) `output/assets` is a symlink to `assets/`, so CSS and JS edits show up on a browser 
refresh with no rebuild. Rebuild only after changing `priv/resume.json` or the templates. CI passes `--copy` so the 
deployed folder is self-contained.

## Layout

| Path | Purpose |
|---|---|
| `priv/resume.json` | The resume content. Edit this to change the resume. |
| `lib/resume/content.ex` | Structs the JSON is decoded into; a missing key fails the build. |
| `lib/resume/dates.ex` | Month formatting and tenure ("7 yrs"). |
| `lib/resume/components.ex` | HEEx function components for the page. |
| `assets/` | Hand-written CSS and JS, plus self-hosted Montserrat (SIL OFL). |
| `.github/workflows/pages.yml` | Tests, builds and deploys to Pages. |

___
</br>
<details>

<summary><h1>&#x1F3AE; &#x1F579;&#xFE0F; &#x1F47E;</h1></summary>

### Easter Egg - Retro Arcade

Well, well, well - look at you finding my resume's hidden secret! 

Clicking my name at the top of the resume, or the joystick button below it, opens `arcade/index.html`. Its first game 
is Snake, drawn with the resume's blue square bullet points. The arcade is fully contained within the same Mix app, all 
of which is running in browser via [Popcorn](https://hexdocs.pm/popcorn/), a BEAM compiled to WebAssembly.

| Path | Purpose |
|---|---|
| `lib/resume/arcade/snake.ex` | The rules of Snake, as pure functions over a struct. |
| `lib/resume/arcade/server.ex` | A GenServer that owns the clock, takes input and pushes HTML to the page. |
| `lib/resume/arcade/view.ex` | HEEx for the board, score, action button and BEAM console. |
| `lib/resume/arcade/vm.ex` | The VM snapshot shown in the console. |
| `assets/js/arcade.js` | Boots the VM, applies the HTML it sends, forwards keys, taps and swipes. |
| `priv/arcade/coi-serviceworker.js` | Vendored from gzuidhof/coi-serviceworker (MIT). |

```sh
MIX_ENV=prod mix site.build   # resume page + browser runtime in output/arcade/out
MIX_ENV=prod mix popcorn.dev --dir output --out-dir output/arcade/out
# then open http://localhost:4000/arcade/index.html
```

> The runtime needs cross-origin isolation headers, which GitHub Pages cannot send. The service worker adds them in the 
> browser and reloads the page once on first visit. Its scope is the `arcade/` folder, so the resume page is unaffected. 
> Opening the page as a local file does not work, because service workers need `http://localhost` or HTTPS.
> 
> Build with `MIX_ENV=prod`: Popcorn packages every compiled dependency found in the application build directory, 
> Tree-shaking (experimental, set in `config/config.exs`) keeps the download to ~2.6 MB gzipped.

</details>

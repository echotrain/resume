import Config

# Browser packaging for the easter egg (`mix popcorn.cook`).
# Never put secrets here: the packaged config is readable in the browser.
config :popcorn,
  app: :resume,
  # Experimental in Popcorn 1.0: drops modules and functions nothing calls.
  treeshake: true,
  # The resume content and Phoenix's static files are not needed in the browser.
  exclude_priv: ["**"]

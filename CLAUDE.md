# CLAUDE.md

This file provides **codebase-specific knowledge** and **Claude-optimized workflows** for this repository.

**Contents:**

- Codebase architecture, commands, and domain structure
- Development workflows and CI/CD
- Claude-specific optimizations and best practices

**For further project rules** (coding standards, testing patterns that apply to any AI assistant), see [AGENTS.md](AGENTS.md).

## Overview

This repo is a small project for generating a static webpage version of my professional resume, which I have hosted on Github Pages `echotrain.github.io`. 

### Running the Application

```sh
# Native
iex -S mix   # Start with IEx shell

# Build the static site from priv/resume.json into output/
# (in dev, output/assets is a symlink to assets/; pass --copy for a self-contained build)
mix resume.build
open output/index.html
```

The page is rendered with `Phoenix.Component`/HEEx only (no endpoint or server). Phone and email must never
be added to `priv/resume.json`, the templates, or test fixtures: the print dialog collects them at print time.

### Testing

```sh
# Run tests
mix test                        # All tests
mix test test/path_test.exs     # Specific file
mix test test/path_test.exs:42  # Specific test by line number
mix test --failed               # Only failed tests
mix test --max-failures n       # Limit failures

# Coverage reports
mix test.html         # HTML coverage report (opens in browser)
mix test.json         # JSON coverage
```

__*Before finalizing changes, review any staged test files you added or changed. Each test should cover meaningful behavior, avoid duplicating existing tests, stay readable, and avoid verbose comments.*__

### Code Quality

```sh
mix format                                # Format code (alias: mix f)
mix credo --strict --min-priority=higher  # Linting
```

## Architecture

### Configuration

- `config/config.exs` - Base configuration
- `config/dev.exs` - Development environment
- `config/test.exs` - Test environment
- `config/prod.exs` - Production environment
- `config/runtime.exs` - Runtime configuration (reads environment variables)
- `.env` or `.env.dist` - Environment variables (use `source .env.dist` for Docker)

#### Testing Guidelines (IMPORTANT)

See [AGENTS.md - General Testing Guidelines](AGENTS.md#general-testing-guidelines) for comprehensive testing guidelines. In summary:

- Prefer real conditions and database operations over mocking internal logic.
- Mock only external APIs, third-party services, and job dispatches.
- Use the Mimic library for selective mocking, and fixtures for test data.
- Tests should be isolated and automatically rollback database changes.
- **DO NOT mock** pure logic functions - set up real conditions instead

#### Error Handling Best Practices

- **Eliminate complex `else` in `with`**: Wrap each `with` step in a private function that normalizes its errors, so the `else` block is unnecessary. See [Complex `else` clauses in `with`](https://github.com/lucasvegi/Elixir-Code-Smells?tab=readme-ov-file#complex-else-clauses-in-with).
- **Use Pattern Matching**: Prefer multiple function clauses over deeply nested `if/else` or `case` statements
- **Extract Guard Logic**: Move complex guard conditions into predicate functions with descriptive names
- **Avoid Hardcoded Lists**: Instead of maintaining lists of error types in guards, use predicate functions that can be easily tested and modified

##### Example: Eliminating Complex `else` Clauses

❌ **Avoid** (complex `else` block — hard to trace which step produced which error):

```elixir
with {:ok, product} <- find_product(sku),
     {:ok, subscription} <- create_subscription(product),
     {:ok, _event} <- create_event(subscription) do
  {:ok, subscription}
else
  {:error, %Ecto.Changeset{} = changeset} ->
    Logger.error("Event failed: #{inspect(changeset)}")
    {:error, changeset}

  {:error, :not_found} ->
    Logger.error("Product not found: #{sku}")
    {:error, :not_found}

  {:error, reason} ->
    Logger.error("Failed: #{inspect(reason)}")
    {:error, reason}
end
```

✅ **Prefer** (each step normalizes its own errors — no `else` needed):

```elixir
with {:ok, product} <- find_validated_product(sku),
     {:ok, subscription} <- safe_create_subscription(product),
     {:ok, _event} <- safe_create_event(subscription) do
  {:ok, subscription}
end

defp find_validated_product(sku) do
  case find_product(sku) do
    {:ok, product} -> {:ok, product}
    {:error, :not_found} ->
      Logger.error("Product not found: #{sku}")
      {:error, :not_found}
  end
end

defp safe_create_subscription(product) do
  case create_subscription(product) do
    {:ok, subscription} -> {:ok, subscription}
    {:error, %Ecto.Changeset{} = changeset} ->
      Logger.error("Subscription failed: #{inspect(changeset)}")
      {:error, changeset}
  end
end

defp safe_create_event(subscription) do
  case create_event(subscription) do
    {:ok, event} -> {:ok, event}
    {:error, %Ecto.Changeset{} = changeset} ->
      Logger.error("Event failed: #{inspect(changeset)}")
      {:error, :event_creation_failed}
  end
end
```

Benefits:

- Each error is handled at its source — clear which step failed
- No `else` block to maintain or trace through
- Each wrapper is independently testable
- Adding a new `with` step doesn't require updating a shared error handler
- Errors use atoms/changesets compatible with `FallbackController` (not maps)

## Important Files

- **`AGENTS.md`** - AI assistant guidelines, architecture patterns, and domain knowledge (referenced by Copilot instructions)
- **`mix.exs`** - Project dependencies and Mix aliases
- **`.formatter.exs`** - Code formatting rules
- **`.credo.exs`** - Linting configuration

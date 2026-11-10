defmodule Resume.Components do
  @moduledoc """
  Function components that render the resume as a single static HTML page.

  Phone and email are deliberately absent from the content: the header has two
  empty, print-only slots that `assets/js/resume.js` fills from the print dialog.
  """

  use Phoenix.Component

  alias Resume.Content
  alias Resume.Dates

  attr :resume, Content, required: true

  def page(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="description" content={"#{@resume.name}, #{@resume.title}"} />
        <meta name="color-scheme" content="light dark" />
        <title>{@resume.name} | {@resume.title}</title>
        <link rel="stylesheet" href="assets/css/resume.css" />
        <script src="assets/js/resume.js">
        </script>
      </head>
      <body>
        <.toolbar />
        <main class="page">
          <.masthead resume={@resume} />
          <section>
            <h2>Professional Summary</h2>
            <p class="summary">{@resume.summary}</p>
          </section>
          <section>
            <h2>Experience</h2>
            <.employer :for={employer <- @resume.experience} employer={employer} />
          </section>
          <.technologies groups={@resume.technologies} />
          <div class="columns">
            <.education entries={@resume.education} />
            <.patents patents={@resume.patents} />
          </div>
        </main>
        <.print_dialog />
      </body>
    </html>
    """
  end

  def toolbar(assigns) do
    ~H"""
    <nav class="toolbar" aria-label="Page actions">
      <button type="button" id="theme-toggle" aria-pressed="false">Dark mode</button>
      <button type="button" id="print-button" class="primary">Print / Save as PDF</button>
    </nav>
    """
  end

  attr :resume, Content, required: true

  def masthead(assigns) do
    ~H"""
    <header class="masthead">
      <div>
        <h1>{@resume.name}</h1>
        <p class="headline">{@resume.title}</p>
      </div>
      <ul class="contact">
        <li id="contact-phone" class="print-only" hidden></li>
        <li id="contact-email" class="print-only" hidden></li>
        <li :for={link <- @resume.links}><a href={link.url}>{link.label}</a></li>
      </ul>
    </header>
    """
  end

  attr :employer, Content.Employer, required: true

  def employer(assigns) do
    {first_start, last_end} = Dates.span(assigns.employer)

    assigns =
      assign(assigns,
        first_start: first_start,
        last_end: last_end,
        show_role_dates?: match?([_, _ | _], assigns.employer.roles)
      )

    ~H"""
    <article class="employer">
      <header class="employer-heading">
        <h3>{@employer.company}</h3>
        <p class="dates">
          <.date_range from={@first_start} to={@last_end} />
          <span class="tenure">{Dates.tenure(@first_start, @last_end)}</span>
        </p>
      </header>
      <p :if={@employer.blurb} class="blurb">{@employer.blurb}</p>
      <div class="roles">
        <.role :for={role <- @employer.roles} role={role} show_dates?={@show_role_dates?} />
      </div>
    </article>
    """
  end

  attr :role, Content.Role, required: true
  attr :show_dates?, :boolean, default: true

  def role(assigns) do
    ~H"""
    <section class="role">
      <header class="role-heading">
        <h4>{@role.title}</h4>
        <p :if={@show_dates?} class="dates"><.date_range from={@role.start} to={@role.end} /></p>
      </header>
      <ul class="highlights">
        <li :for={highlight <- @role.highlights}>
          <strong :if={highlight.lead}>{highlight.lead}</strong>
          {highlight.text}
        </li>
      </ul>
    </section>
    """
  end

  attr :from, :string, required: true
  attr :to, :string, default: nil

  def date_range(assigns) do
    ~H"""
    <span class="date-range">
      {Dates.format_month(@from)}
      <span class="dash" aria-hidden="true">–</span>
      <span class="sr-only">to</span>
      {Dates.format_month(@to)}
    </span>
    """
  end

  attr :groups, :list, required: true

  def technologies(assigns) do
    ~H"""
    <section class="keep-together">
      <h2>Technologies</h2>
      <ul class="highlights technologies">
        <li :for={group <- @groups}><strong>{group.label}:</strong> {Enum.join(group.items, ", ")}</li>
      </ul>
    </section>
    """
  end

  attr :entries, :list, required: true

  def education(assigns) do
    ~H"""
    <section class="keep-together">
      <h2>Education</h2>
      <div :for={entry <- @entries} class="credential">
        <h3>{entry.degree}</h3>
        <p>{entry.school}<span class="separator" aria-hidden="true"></span>{entry.date}</p>
      </div>
    </section>
    """
  end

  attr :patents, :list, required: true

  def patents(assigns) do
    ~H"""
    <section class="keep-together">
      <h2>Patents</h2>
      <div :for={patent <- @patents} class="credential">
        <h3>
          <a :if={patent.url} href={patent.url}>{patent.title}</a>
          <span :if={!patent.url}>{patent.title}</span>
        </h3>
        <p>{patent.number}<span class="separator" aria-hidden="true"></span>Issued {patent.issued}</p>
      </div>
    </section>
    """
  end

  def print_dialog(assigns) do
    ~H"""
    <dialog id="print-dialog" aria-labelledby="print-dialog-title">
      <form method="dialog" id="print-form">
        <h2 id="print-dialog-title">Print or save as PDF</h2>
        <p>
          Phone and email are not published on this page. To include them on your printed copy, enter them
          here. They are added to this print only: nothing is stored or sent anywhere.
        </p>
        <label for="print-phone">Phone (optional)</label>
        <input id="print-phone" name="phone" type="tel" autocomplete="off" />
        <label for="print-email">Email (optional)</label>
        <input id="print-email" name="email" type="text" inputmode="email" autocomplete="off" />
        <div class="dialog-actions">
          <button type="button" id="print-cancel">Cancel</button>
          <button type="submit" class="primary">Print</button>
        </div>
      </form>
    </dialog>
    """
  end
end

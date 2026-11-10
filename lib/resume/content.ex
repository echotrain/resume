defmodule Resume.Content do
  @moduledoc """
  The resume as structured data, decoded from `priv/resume.json`.

  Each struct has a `from_map/1` that raises `ArgumentError` naming the missing
  key, so a malformed content file fails the build instead of rendering a
  half-empty page.
  """

  alias Resume.Content.Education
  alias Resume.Content.Employer
  alias Resume.Content.Field
  alias Resume.Content.Link
  alias Resume.Content.Patent
  alias Resume.Content.SkillGroup

  @enforce_keys [:name, :title, :summary, :links, :experience, :technologies, :education, :patents]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          name: String.t(),
          title: String.t(),
          summary: String.t(),
          links: [Link.t()],
          experience: [Employer.t()],
          technologies: [SkillGroup.t()],
          education: [Education.t()],
          patents: [Patent.t()]
        }

  @spec from_map(map()) :: t()
  def from_map(map) when is_map(map) do
    %__MODULE__{
      name: Field.fetch!(map, "name", "resume"),
      title: Field.fetch!(map, "title", "resume"),
      summary: Field.fetch!(map, "summary", "resume"),
      links: Field.map!(map, "links", "resume", &Link.from_map/1),
      experience: Field.map!(map, "experience", "resume", &Employer.from_map/1),
      technologies: Field.map!(map, "technologies", "resume", &SkillGroup.from_map/1),
      education: Field.map!(map, "education", "resume", &Education.from_map/1),
      patents: Field.map!(map, "patents", "resume", &Patent.from_map/1)
    }
  end

  defmodule Field do
    @moduledoc false

    @spec fetch!(map(), String.t(), String.t()) :: term()
    def fetch!(map, key, context) do
      case map do
        %{^key => value} when not is_nil(value) -> value
        _missing -> raise ArgumentError, "resume content: #{context} is missing #{inspect(key)}"
      end
    end

    @spec map!(map(), String.t(), String.t(), (term() -> struct())) :: [struct()]
    def map!(map, key, context, builder) do
      map |> fetch!(key, context) |> Enum.map(builder)
    end
  end

  defmodule Link do
    @moduledoc "A labelled URL shown in the page header."

    @enforce_keys [:label, :url]
    defstruct @enforce_keys

    @type t :: %__MODULE__{label: String.t(), url: String.t()}

    @spec from_map(map()) :: t()
    def from_map(map) do
      %__MODULE__{label: Field.fetch!(map, "label", "link"), url: Field.fetch!(map, "url", "link")}
    end
  end

  defmodule Highlight do
    @moduledoc "One bullet under a role, with an optional bold lead-in."

    @enforce_keys [:text]
    defstruct [:lead, :text]

    @type t :: %__MODULE__{lead: String.t() | nil, text: String.t()}

    @spec from_map(map() | String.t()) :: t()
    def from_map(text) when is_binary(text), do: %__MODULE__{text: text}

    def from_map(map) when is_map(map) do
      %__MODULE__{lead: map["lead"], text: Field.fetch!(map, "text", "highlight")}
    end
  end

  defmodule Role do
    @moduledoc "A position held at an employer. `end` is `nil` for a current role."

    @enforce_keys [:title, :start, :highlights]
    defstruct [:title, :start, :end, :highlights]

    @type t :: %__MODULE__{
            title: String.t(),
            start: String.t(),
            end: String.t() | nil,
            highlights: [Highlight.t()]
          }

    @spec from_map(map()) :: t()
    def from_map(map) do
      %__MODULE__{
        title: Field.fetch!(map, "title", "role"),
        start: Field.fetch!(map, "start", "role"),
        end: map["end"],
        highlights: Field.map!(map, "highlights", "role", &Highlight.from_map/1)
      }
    end
  end

  defmodule Employer do
    @moduledoc "A company and every role held there, newest first."

    @enforce_keys [:company, :roles]
    defstruct [:company, :blurb, :roles]

    @type t :: %__MODULE__{company: String.t(), blurb: String.t() | nil, roles: [Role.t()]}

    @spec from_map(map()) :: t()
    def from_map(map) do
      %__MODULE__{
        company: Field.fetch!(map, "company", "employer"),
        blurb: map["blurb"],
        roles: Field.map!(map, "roles", "employer", &Role.from_map/1)
      }
    end
  end

  defmodule SkillGroup do
    @moduledoc "A labelled row in the Technologies section."

    @enforce_keys [:label, :items]
    defstruct @enforce_keys

    @type t :: %__MODULE__{label: String.t(), items: [String.t()]}

    @spec from_map(map()) :: t()
    def from_map(map) do
      %__MODULE__{
        label: Field.fetch!(map, "label", "technology group"),
        items: Field.fetch!(map, "items", "technology group")
      }
    end
  end

  defmodule Education do
    @moduledoc "A degree."

    @enforce_keys [:degree, :school, :date]
    defstruct @enforce_keys

    @type t :: %__MODULE__{degree: String.t(), school: String.t(), date: String.t()}

    @spec from_map(map()) :: t()
    def from_map(map) do
      %__MODULE__{
        degree: Field.fetch!(map, "degree", "education"),
        school: Field.fetch!(map, "school", "education"),
        date: Field.fetch!(map, "date", "education")
      }
    end
  end

  defmodule Patent do
    @moduledoc "An issued patent, optionally linked to its public record."

    @enforce_keys [:title, :number, :issued]
    defstruct [:title, :number, :issued, :url]

    @type t :: %__MODULE__{title: String.t(), number: String.t(), issued: String.t(), url: String.t() | nil}

    @spec from_map(map()) :: t()
    def from_map(map) do
      %__MODULE__{
        title: Field.fetch!(map, "title", "patent"),
        number: Field.fetch!(map, "number", "patent"),
        issued: Field.fetch!(map, "issued", "patent"),
        url: map["url"]
      }
    end
  end
end

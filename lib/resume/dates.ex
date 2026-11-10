defmodule Resume.Dates do
  @moduledoc """
  Formatting for the `"YYYY-MM"` month strings used in the resume content.

  A `nil` end month means the role is current: it renders as "Present" and
  tenure is measured up to `today`.
  """

  alias Resume.Content.Employer
  alias Resume.Content.Role

  @month_names ~w(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)

  @doc """
  Formats a month for display.

      iex> Resume.Dates.format_month("2024-09")
      "Sep 2024"

      iex> Resume.Dates.format_month(nil)
      "Present"
  """
  @spec format_month(String.t() | nil) :: String.t()
  def format_month(nil), do: "Present"

  def format_month(month) do
    {year, month_number} = parse!(month)
    "#{Enum.at(@month_names, month_number - 1)} #{year}"
  end

  @doc "The first start and last end month across an employer's roles."
  @spec span(Employer.t()) :: {String.t(), String.t() | nil}
  def span(%Employer{roles: roles}) do
    first_start = roles |> Enum.map(& &1.start) |> Enum.min()
    {first_start, last_end(roles)}
  end

  @doc """
  Time between two months as a short label, rounded down to whole months.

      iex> Resume.Dates.tenure("2017-08", "2024-08")
      "7 yrs"

      iex> Resume.Dates.tenure("2023-01", "2024-07")
      "1 yr 6 mos"
  """
  @spec tenure(String.t(), String.t() | nil, Date.t()) :: String.t()
  def tenure(start_month, end_month, today \\ Date.utc_today()) do
    {start_year, start_number} = parse!(start_month)
    {end_year, end_number} = end_or_today(end_month, today)

    total_months = (end_year - start_year) * 12 + end_number - start_number

    label(div(total_months, 12), rem(total_months, 12))
  end

  defp last_end(roles) do
    if Enum.any?(roles, &current?/1), do: nil, else: roles |> Enum.map(& &1.end) |> Enum.max()
  end

  defp current?(%Role{end: end_month}), do: is_nil(end_month)

  defp end_or_today(nil, %Date{year: year, month: month}), do: {year, month}
  defp end_or_today(month, _today), do: parse!(month)

  defp parse!(<<year::binary-size(4), "-", month::binary-size(2)>> = value) do
    case {Integer.parse(year), Integer.parse(month)} do
      {{year, ""}, {month, ""}} when month in 1..12 -> {year, month}
      _invalid -> invalid!(value)
    end
  end

  defp parse!(value), do: invalid!(value)

  defp invalid!(value) do
    raise ArgumentError, "resume content: expected a \"YYYY-MM\" month, got #{inspect(value)}"
  end

  defp label(years, 0), do: years(years)
  defp label(0, months), do: months(months)
  defp label(years, months), do: "#{years(years)} #{months(months)}"

  defp years(1), do: "1 yr"
  defp years(count), do: "#{count} yrs"

  defp months(1), do: "1 mo"
  defp months(count), do: "#{count} mos"
end

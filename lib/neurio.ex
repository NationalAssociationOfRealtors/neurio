defmodule Neurio do
  use HTTPoison.Base
  require Logger

  defmodule State do
    @derive [Poison.Encoder]
    defstruct connection_status: "",
      channel: 0,
      meter_mac_id: "",
      signal: 0,
      meter_type: "",
      price: 0,
      kw_delivered: 0,
      kw_received: 0,
      kw: 0
  end

  def process_url(ip \\ "192.168.1.7") do
    "http://#{ip}/current-sample"
  end

  def process_response_body(body) do
    parsed = body |> Poison.decode!
    parsed
    |> Map.get("channels", [])
    |> Enum.find(%{}, fn ch ->
        case ch |> Map.get("type") do
          "CONSUMPTION" -> true
          _ -> false
        end
      end)
    |> parse_data
    |> map_state(parsed)
  end

  defp parse_data(consumption) do
    {
      (consumption |> Map.get("eExp_Ws", 0)) / 1000, #delivered from Utility
      (consumption |> Map.get("eImp_ws", 0)) / 1000, #received by Utility
      (consumption |> Map.get("p_W", 0)) / 1000 #current kw usage
    }
  end

  defp map_state({delivered, received, current}, body) do
    %State{
      connection_status: "connected",
      meter_mac_id: body |> Map.get("sensorId"),
      signal: 100,
      meter_type: :electric,
      price: 0.0,
      kw_delivered: delivered,
      kw_received: received,
      kw: current,
    }
  end
end

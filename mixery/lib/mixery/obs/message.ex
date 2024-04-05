defmodule Mixery.OBS.Message do
  require Logger

  @type opcode :: :hello | :identify | :identified | :request | :response

  @spec obs_message(opcode, map) :: {:text, String.t()}
  defp obs_message(op, d) do
    op =
      case op do
        :hello -> 0
        :identify -> 1
        :identified -> 2
        :request -> 6
        :response -> 7
        op -> op
      end

    case Jason.encode(%{"op" => op, "d" => d}) do
      {:ok, json} ->
        {:text, json}

      {:error, reason} ->
        Logger.warning("OH NOES: #{inspect(reason)}")
        {:text, reason}
    end
  end

  def set_scene(scene_name) do
    obs_message(:request, %{
      "requestType" => "SetCurrentProgramScene",
      "requestId" => Ecto.UUID.generate(),
      "requestData" => %{"sceneName" => scene_name}
    })
  end

  def set_scene_item_enabled(scene_name, item_id, is_enabled) do
    obs_message(:request, %{
      "requestType" => "SetSceneItemEnabled",
      "requestId" => Ecto.UUID.generate(),
      "requestData" => %{
        "sceneName" => scene_name,
        "sceneItemId" => item_id,
        "sceneItemEnabled" => is_enabled
      }
    })
  end

  def get_scene_item_id(scene_name, source_name) do
    # This is fine to be written differently
    obs_message(:request, %{
      "requestType" => "GetSceneItemId",
      "requestId" => Ecto.UUID.generate(),
      "requestData" => %{
        "sceneName" => scene_name,
        "sourceName" => source_name
      }
    })
  end
end

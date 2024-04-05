defmodule Mixery.OBS do
  defmodule State do
    defstruct requests: %{}
  end

  defmodule RequestResponse do
    defstruct [:request_type, :request_id, :request_status, response_data: nil]

    @type t :: %__MODULE__{
            request_type: String.t(),
            request_id: String.t(),
            request_status: map,
            response_data: map | nil
          }

    @spec from_map(map) :: t
    def from_map(
          %{
            "requestType" => request_type,
            "requestId" => request_id,
            "requestStatus" => request_status
          } = map
        ) do
      %__MODULE__{
        request_type: request_type,
        request_id: request_id,
        request_status: request_status,
        response_data: map["responseData"]
      }
    end
  end
end

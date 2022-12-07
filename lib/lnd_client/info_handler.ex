defmodule LndClient.InfoHandler do
  def get(channel, macaroon) do
    Lnrpc.Lightning.Stub.get_info(
      channel,
      Lnrpc.GetInfoRequest.new(),
      metadata: %{macaroon: macaroon}
    )
  end
end

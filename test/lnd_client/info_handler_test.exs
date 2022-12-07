defmodule LndClient.InfoHandlerTest do
  use ExUnit.Case

  test "get_info returns the info of the given server" do
    GrpcMock.defmock(LightningServiceMock, for: Lnrpc.Lightning.Service)

    GRPC.Server.start(LightningServiceMock, 50_051)

    {:ok, channel} = GRPC.Stub.connect("localhost:50051")

    LightningServiceMock
    |> GrpcMock.expect(:get_info, fn req, stream ->
      IO.inspect(req)
      IO.inspect(stream)
      Lnrpc.GetInfoResponse.new(identity_pubkey: "abcd")
    end)

    # This does not test that macaroon is even passed in and
    # set in metadata; the tests pass if that is commented out
    {:ok, response} = LndClient.InfoHandler.get(channel, "fakemacaroon")

    assert response.identity_pubkey == "abcd"
  end
end

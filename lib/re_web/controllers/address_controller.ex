defmodule ReWeb.AddressController do
  use ReWeb, :controller

  alias ReWeb.Address

  def index(conn, _params) do
    address = Repo.all(Address)
    render(conn, "index.json", address: address)
  end

  def create(conn, %{"address" => address_params}) do
    changeset = Address.changeset(%Address{}, address_params)

    case Repo.insert(changeset) do
      {:ok, address} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", address_path(conn, :show, address))
        |> render("show.json", address: address)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ReWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    address = Repo.get!(Address, id)
    render(conn, "show.json", address: address)
  end

  def update(conn, %{"id" => id, "address" => address_params}) do
    address = Repo.get!(Address, id)
    changeset = Address.changeset(address, address_params)

    case Repo.update(changeset) do
      {:ok, address} ->
        render(conn, "show.json", address: address)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ReWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    address = Repo.get!(Address, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(address)

    send_resp(conn, :no_content, "")
  end
end

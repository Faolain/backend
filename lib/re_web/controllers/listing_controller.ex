defmodule ReWeb.ListingController do
  use ReWeb, :controller
  use Guardian.Phoenix.Controller

  alias Re.{
    Addresses,
    Image,
    Images,
    Listing,
    Listings
  }

  plug Guardian.Plug.EnsureAuthenticated,
    %{handler: ReWeb.SessionController}
    when action in [:create, :edit, :update, :delete, :order]

  action_fallback ReWeb.FallbackController

  def index(conn, _params, _user, _full_claims) do
    render(conn, "index.json", listings: Listings.all())
  end

  def create(conn, %{"listing" => listing_params, "address" => address_params}, _user, _full_claims) do
    case Addresses.find_or_create(address_params) do
      {:error, address_changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ReWeb.ChangesetView, "error.json", changeset: address_changeset )

      address_id ->
        case Listings.insert(listing_params, address_id) do
          {:ok, listing} ->
            conn
            |> put_status(:created)
            |> render("create.json", listing: listing)

          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> render(ReWeb.ChangesetView, "error.json", changeset: changeset)
        end
    end
  end

  def show(conn, %{"id" => id}, _user, _full_claims) do
    with {:ok, listing} <- Listings.get(id),
         {:ok, listing} <- Listings.preload(listing),
      do: render(conn, "show.json", listing: listing)
  end

  def edit(conn, %{"id" => id}, _user, _full_claims) do
    with {:ok, listing} <- Listings.get(id),
         {:ok, listing} <- Listings.preload(listing),
      do: render(conn, "edit.json", listing: listing)
  end

  def update(conn, %{"id" => id, "listing" => listing_params, "address" => address_params}, _user, _full_claims) do
    listing =
      Listing
      |> Repo.get!(id)
      |> Repo.preload(:address)
      |> Repo.preload([images: (from i in Image, order_by: i.position)])

    case Addresses.update(listing, address_params) do
      {:error, address_changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ReWeb.ChangesetView, "error.json", changeset: address_changeset)

      address_id ->
        case Listings.update(listing, listing_params, address_id) do
          {:ok, listing} ->
            render(conn, "edit.json", listing: listing)
          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> render(ReWeb.ChangesetView, "error.json", changeset: changeset)
        end
    end
  end

  def delete(conn, %{"id" => id}, _user, _full_claims) do
    with {:ok, listing} <- Listings.get(id),
         {:ok, _listing} <- Listings.delete(listing),
      do: send_resp(conn, :no_content, "")
  end

  def order(conn, %{"listing_id" => id, "images" => images_params}, _user, _full_claims) do
    with {:ok, listing} <- Listings.get(id),
         :ok <- Images.update_per_listing(listing, images_params),
      do: send_resp(conn, :no_content, "")
  end
end

class UsersController < ApplicationController
  def index
  end

  def search
    result = UserSearch.call(
      name: params[:name],
      search_type: "name"
    )
    @users = result.users
    render :index
  end
end

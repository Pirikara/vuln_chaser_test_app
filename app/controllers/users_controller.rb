class UsersController < ApplicationController
  def index
  end

  def search
    result = UserSearch.call(name: params[:name])
    @users = result.users
    render :index
  end
end

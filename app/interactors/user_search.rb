class UserSearch
  include Interactor

  def call
    query = "SELECT * FROM users WHERE name LIKE '%#{context.name}%'"
    context.users = ActiveRecord::Base.connection.execute(query)
  end
end
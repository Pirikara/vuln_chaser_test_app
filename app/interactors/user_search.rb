class UserSearch
  include Interactor

  def call
    context.users = execute_dynamic_query
  end

  private

  def execute_dynamic_query
    query_method = "build_#{context.search_type}_query"
    query = send(query_method)
    ActiveRecord::Base.connection.send(:execute, query)
  end

  def build_name_query
    "SELECT * FROM users WHERE name LIKE '%#{context.name}%'"
  end
end
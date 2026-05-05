class SimpleTestController < ApplicationController
  # Disable CSRF protection for testing
  skip_before_action :verify_authenticity_token
  
  # Simple SQL injection test
  def sql_test
    name = params[:name] || 'test'
    # Simulate SQL injection vulnerability
    query = "SELECT * FROM users WHERE name = '#{name}'"
    
    render json: { 
      message: 'SQL Injection Test',
      query: query,
      input: name,
      vulnerable: true
    }
  end
  
  # Simple auth test
  def auth_test
    password = params[:password]
    
    # Hardcoded password check
    if password == 'admin123'
      render json: { status: 'success', message: 'Admin access granted' }
    else
      render json: { status: 'failed', message: 'Access denied' }
    end
  end
  
  # Basic health check
  def health
    render json: { status: 'ok', timestamp: Time.current.iso8601 }
  end
end
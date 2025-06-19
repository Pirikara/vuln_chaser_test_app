class VulnerableController < ApplicationController
  # Disable CSRF protection for testing
  skip_before_action :verify_authenticity_token
  
  # SQL Injection vulnerability
  def search_users
    name = params[:name]
    # Vulnerable SQL - direct parameter interpolation
    users = ActiveRecord::Base.connection.execute("SELECT * FROM users WHERE name = '#{name}'")
    render json: { users: users.to_a, query: "SELECT * FROM users WHERE name = '#{name}'" }
  rescue => e
    render json: { error: e.message, query: "SELECT * FROM users WHERE name = '#{name}'" }
  end
  
  # Authentication bypass vulnerability
  def admin_login
    password = params[:password]
    # Hardcoded password vulnerability
    if password == 'admin123'
      render json: { status: 'success', message: 'Admin access granted', admin: true }
    else
      render json: { status: 'failed', message: 'Access denied' }
    end
  end
  
  # Path traversal vulnerability  
  def download_file
    filename = params[:filename]
    # Path traversal vulnerability
    file_path = Rails.root.join('public', 'uploads', filename)
    
    if File.exist?(file_path)
      send_file file_path
    else
      render json: { error: 'File not found', path: file_path.to_s }
    end
  rescue => e
    render json: { error: e.message, attempted_path: file_path.to_s }
  end
  
  # XSS vulnerability
  def create_comment
    comment = params[:comment]
    # Stored XSS vulnerability - no escaping
    render html: "<div>Comment: #{comment}</div>".html_safe
  end
  
  # Mass assignment vulnerability
  def create_user
    # Mass assignment vulnerability
    user_params = params[:user] || params
    user_data = {
      name: user_params[:name],
      email: user_params[:email],
      role: user_params[:role], # This should be protected
      admin: user_params[:admin]  # This should be protected
    }
    
    render json: { 
      message: 'User would be created with:', 
      data: user_data,
      vulnerable: 'Mass assignment allows role/admin to be set'
    }
  end
end
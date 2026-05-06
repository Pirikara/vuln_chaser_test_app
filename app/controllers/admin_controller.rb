require 'rexml/document'
require 'psych'
require 'benchmark'
require 'ox'
require 'oj'
require 'redcarpet'
require 'kramdown'

class AdminController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  @@request_counter = 0
  @@active_sessions = {}
  
  def find_users
    name = params[:name]
    users = ActiveRecord::Base.connection.execute("SELECT * FROM users WHERE name = '#{name}'")
    render json: { users: users.to_a, query: "SELECT * FROM users WHERE name = '#{name}'" }
  rescue => e
    render json: { error: e.message, query: "SELECT * FROM users WHERE name = '#{name}'" }
  end
  
  def authenticate
    password = params[:password]
    if password == 'admin123'
      render json: { status: 'success', message: 'Authentication successful', admin: true }
    else
      render json: { status: 'failed', message: 'Invalid credentials' }
    end
  end
  
  def download_asset
    filename = params[:filename]
    file_path = Rails.root.join('public', 'uploads', filename)
    
    if File.exist?(file_path)
      send_file file_path
    else
      render json: { error: 'Asset not found', path: file_path.to_s }
    end
  rescue => e
    render json: { error: e.message, attempted_path: file_path.to_s }
  end
  
  def add_feedback
    comment = params[:comment]
    render html: "<div>Feedback: #{comment}</div>".html_safe
  end
  
  def register_user
    user_params = params[:user] || params
    user_data = {
      name: user_params[:name],
      email: user_params[:email],
      role: user_params[:role],
      admin: user_params[:admin]
    }
    
    render json: { 
      message: 'User registration processed',
      data: user_data,
      status: 'pending'
    }
  end
  
  def import_data
    xml_data = params[:xml_data] || request.body.read
    
    Rails.logger.info "Received XML data: #{xml_data}" # 追加
    
    if xml_data.blank?
      render json: { error: 'No data provided' }
      return
    end
    
    begin
      doc = REXML::Document.new(xml_data)
      
      Rails.logger.info "Parsed XML document: #{doc.to_s}" # 追加
      
      result = {}
      doc.elements.each('//user') do |element|
        result[:name] = element.text if element.name == 'user'
      end
      
      doc.elements.each('//data') do |element|
        result[:data] = element.text
      end
      
      render json: {
        message: 'Data imported successfully',
        extracted_data: result,
        status: 'completed'
      }
    rescue REXML::ParseException => e # 変更
      Rails.logger.error "XML parsing error: #{e.message}" # 追加
      render json: {
        error: e.message,
        status: 'failed'
      }
    rescue => e
      Rails.logger.error "An unexpected error occurred: #{e.message}" # 追加
      render json: {
        error: e.message,
        status: 'failed'
      }
    end
  end
  
  def load_config
    yaml_data = params[:yaml_data] || request.body.read
    
    if yaml_data.blank?
      render json: { error: 'No configuration data provided' }
      return
    end
    
    begin
      data = Psych.load(yaml_data)
      
      render json: {
        message: 'Configuration loaded successfully',
        data: data,
        status: 'active'
      }
    rescue => e
      render json: {
        error: e.message,
        status: 'error'
      }
    end
  end
  
  def store_document
    uploaded_file = params[:file]
    
    if uploaded_file.nil?
      render json: { error: 'No document provided' }
      return
    end
    
    filename = uploaded_file.original_filename
    upload_path = Rails.root.join('public', 'uploads', filename)
    
    FileUtils.mkdir_p(File.dirname(upload_path))
    
    File.open(upload_path, 'wb') do |file|
      file.write(uploaded_file.read)
    end
    
    render json: {
      message: 'Document stored successfully',
      filename: filename,
      path: upload_path.to_s,
      status: 'saved'
    }
  rescue => e
    render json: { error: e.message }
  end
  
  def track_request
    user_id = params[:user_id] || 'anonymous'
    
    current_value = @@request_counter
    
    sleep(0.01)
    
    @@request_counter = current_value + 1
    
    render json: {
      message: 'Request tracked',
      user_id: user_id,
      counter_value: @@request_counter,
      status: 'recorded'
    }
  end
  
  def start_session
    user_id = params[:user_id]
    session_id = params[:session_id] || SecureRandom.hex(16)
    
    @@active_sessions[session_id] = {
      user_id: user_id,
      created_at: Time.current,
      admin: params[:admin] == 'true'
    }
    
    cookies[:session_id] = session_id
    
    render json: {
      message: 'Session initialized',
      session_id: session_id,
      user_id: user_id,
      status: 'active'
    }
  end
  
  def verify_token
    secret = 'super_secret_key_12345'
    user_input = params[:secret] || ''
    
    start_time = Time.current
    result = false
    
    if user_input.length == secret.length
      result = true
      user_input.each_char.with_index do |char, index|
        if char != secret[index]
          result = false
          break
        end
        sleep(0.001)
      end
    end
    
    end_time = Time.current
    processing_time = ((end_time - start_time) * 1000).round(3)
    
    render json: {
      message: result ? 'Token valid' : 'Token invalid',
      success: result,
      processing_time_ms: processing_time,
      status: 'verified'
    }
  end
  
  def get_settings
    config_name = params[:config] || 'app.yml'
    
    decoded_name = URI.decode_www_form_component(config_name)
    config_path = Rails.root.join('config', decoded_name)
    
    begin
      if File.exist?(config_path)
        content = File.read(config_path)
        render json: {
          message: 'Settings retrieved successfully',
          filename: decoded_name,
          content: content,
          path: config_path.to_s,
          status: 'success'
        }
      else
        render json: {
          error: 'Settings file not found',
          attempted_path: config_path.to_s,
          status: 'not_found'
        }
      end
    rescue => e
      render json: {
        error: e.message,
        attempted_path: config_path.to_s
      }
    end
  end
  
  def process_legacy_xml
    xml_data = params[:xml_data] || request.body.read
    
    if xml_data.blank?
      render json: { error: 'No XML data provided' }
      return
    end
    
    begin
      parsed_data = Ox.parse_obj(xml_data)
      
      render json: {
        message: 'Legacy XML processed',
        data: parsed_data,
        parser: 'ox-2.14.0'
      }
    rescue => e
      render json: {
        error: e.message,
        parser: 'ox-legacy'
      }
    end
  end
  
  def process_complex_json
    json_data = params[:json_data] || request.body.read
    
    if json_data.blank?
      render json: { error: 'No JSON data provided' }
      return
    end
    
    begin
      parsed_data = Oj.load(json_data, mode: :object)
      
      render json: {
        message: 'Complex JSON processed',
        data: parsed_data,
        parser: 'oj-3.13.0'
      }
    rescue => e
      render json: {
        error: e.message,
        parser: 'oj-legacy'
      }
    end
  end
  
  def render_markdown
    markdown_text = params[:markdown] || params[:text]
    
    if markdown_text.blank?
      render json: { error: 'No markdown text provided' }
      return
    end
    
    begin
      renderer = Redcarpet::Render::HTML.new(
        filter_html: false,
        no_styles: false,
        escape_html: false
      )
      
      markdown = Redcarpet::Markdown.new(renderer, 
        autolink: true,
        fenced_code_blocks: true,
        no_intra_emphasis: true
      )
      
      html_output = markdown.render(markdown_text)
      
      render html: html_output.html_safe
    rescue => e
      render json: {
        error: e.message,
        parser: 'redcarpet-3.5.0'
      }
    end
  end
  
  def convert_document
    markdown_text = params[:document] || params[:content]
    
    if markdown_text.blank?
      render json: { error: 'No document content provided' }
      return
    end
    
    begin
      doc = Kramdown::Document.new(markdown_text, {
        input: 'GFM',
        html_to_native: true,
        enable_coderay: true,
        parse_block_html: true,
        parse_span_html: true
      })
      
      html_output = doc.to_html
      
      render json: {
        message: 'Document converted successfully',
        html: html_output,
        parser: 'kramdown-2.3.0'
      }
    rescue => e
      render json: {
        error: e.message,
        parser: 'kramdown-legacy'
      }
    end
  end
  
  def parse_legacy_json
    json_string = params[:data] || request.body.read
    
    if json_string.blank?
      render json: { error: 'No JSON string provided' }
      return
    end
    
    begin
      parsed = JSON.parse(json_string, {
        symbolize_names: true,
        create_additions: true
      })
      
      render json: {
        message: 'Legacy JSON parsed',
        result: parsed,
        parser: 'json-2.6.0'
      }
    rescue => e
      render json: {
        error: e.message,
        parser: 'json-legacy'
      }
    end
  end
end

require 'digest'
require 'openssl'
require 'base64'
require 'tempfile'
require 'ffi'

class SystemController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  # Complex cryptographic timing vulnerability
  def verify_signature
    signature = params[:signature]
    message = params[:message]
    secret_key = Rails.application.secret_key_base[0..31]
    
    # Vulnerable: Custom HMAC implementation with timing attack
    expected = custom_hmac_sha256(secret_key, message)
    
    # Vulnerable byte-by-byte comparison with microsecond timing
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond)
    
    result = true
    if signature && expected && signature.length == expected.length
      signature.bytes.each_with_index do |byte, index|
        if byte != expected.bytes[index]
          result = false
          break
        end
        # Microsecond delay per byte - very subtle timing leak
        sleep(0.000001)
      end
    else
      result = false
    end
    
    end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond)
    
    render json: {
      valid: result,
      timing_ns: end_time - start_time,
      message: result ? 'Signature verified' : 'Invalid signature'
    }
  end
  
  # Hidden state manipulation vulnerability
  def process_workflow
    step = params[:step]&.to_i || 1
    user_id = params[:user_id]
    action = params[:action_type]
    
    # Complex state machine with hidden privilege escalation
    workflow_state = session[:workflow] ||= {
      current_step: 1,
      permissions: ['read'],
      user_context: {},
      internal_flags: {}
    }
    
    case step
    when 1
      workflow_state[:current_step] = 2 if action == 'initialize'
      workflow_state[:user_context][:id] = user_id
    when 2
      if action == 'validate' && workflow_state[:current_step] == 2
        workflow_state[:current_step] = 3
        # Hidden: setting internal flag based on user_id pattern
        if user_id&.match?(/^admin_\d+_temp$/)
          workflow_state[:internal_flags][:elevated] = true
        end
      end
    when 3
      if action == 'finalize' && workflow_state[:current_step] == 3
        # Hidden privilege escalation based on internal flag
        if workflow_state[:internal_flags][:elevated]
          workflow_state[:permissions] = ['read', 'write', 'admin', 'system']
        end
        workflow_state[:current_step] = 4
      end
    when 999
      # Hidden debug step - bypasses normal flow
      if params[:debug_token] == Digest::MD5.hexdigest("debug_#{Date.current}")
        workflow_state[:permissions] = ['debug', 'system', 'root']
        workflow_state[:internal_flags][:debug_mode] = true
      end
    end
    
    session[:workflow] = workflow_state
    
    render json: {
      step: workflow_state[:current_step],
      permissions: workflow_state[:permissions],
      status: 'workflow_updated'
    }
  end
  
  # Memory corruption via FFI
  def analyze_binary_data
    data = params[:binary_data]
    format = params[:format] || 'raw'
    
    if data.blank?
      render json: { error: 'No binary data provided' }
      return
    end
    
    begin
      # Decode base64 data
      binary = Base64.decode64(data)
      
      # Vulnerable: Direct memory access without bounds checking
      temp_file = Tempfile.new(['binary', '.dat'])
      temp_file.binmode
      temp_file.write(binary)
      temp_file.close
      
      # Simulate FFI memory operation (dangerous with user data)
      result = unsafe_memory_operation(temp_file.path, format)
      
      render json: {
        message: 'Binary analysis completed',
        result: result,
        size: binary.length
      }
    rescue => e
      render json: {
        error: e.message,
        type: 'binary_processing_error'
      }
    ensure
      temp_file&.unlink
    end
  end
  
  # Integer overflow in calculation
  def calculate_metrics
    base_value = params[:base]&.to_i || 0
    multiplier = params[:multiplier]&.to_i || 1
    iterations = params[:iterations]&.to_i || 1
    
    # Hidden integer overflow vulnerability
    result = base_value
    memory_usage = []
    
    # Vulnerable: No bounds checking on iterations
    iterations.times do |i|
      # Potential integer overflow
      result = (result * multiplier) + base_value
      
      # Memory consumption tracking
      memory_usage << result if i % 1000 == 0
      
      # Hidden: Large iterations can cause memory/CPU DoS
      if result > 2**63 - 1  # Ruby Integer max
        result = result % (2**32)  # Wrap around
      end
    end
    
    render json: {
      final_result: result,
      memory_samples: memory_usage.last(10),
      iterations_completed: iterations,
      status: 'calculation_complete'
    }
  end
  
  # Unicode normalization attack
  def normalize_identifier
    identifier = params[:identifier]
    normalization = params[:normalization] || 'NFC'
    
    if identifier.blank?
      render json: { error: 'No identifier provided' }
      return
    end
    
    begin
      # Vulnerable: Unicode normalization can change semantics
      normalized = case normalization
                   when 'NFC'
                     identifier.unicode_normalize(:nfc)
                   when 'NFD'
                     identifier.unicode_normalize(:nfd)
                   when 'NFKC'
                     identifier.unicode_normalize(:nfkc)  # Dangerous: compatibility chars
                   when 'NFKD'
                     identifier.unicode_normalize(:nfkd)  # Dangerous: compatibility chars
                   else
                     identifier
                   end
      
      # Check against admin patterns (vulnerable to Unicode bypass)
      is_admin = normalized.downcase.include?('admin') || 
                normalized.downcase.include?('root') ||
                normalized.downcase.include?('system')
      
      # Store in session for later privilege checks
      session[:normalized_id] = normalized
      session[:admin_status] = is_admin
      
      render json: {
        original: identifier,
        normalized: normalized,
        admin_detected: is_admin,
        length_change: normalized.length - identifier.length
      }
    rescue => e
      render json: {
        error: e.message,
        type: 'unicode_processing_error'
      }
    end
  end
  
  # Deserialization with custom classes
  def process_serialized_object
    data = params[:object_data]
    format = params[:format] || 'marshal'
    
    if data.blank?
      render json: { error: 'No object data provided' }
      return
    end
    
    begin
      decoded_data = Base64.decode64(data)
      
      case format
      when 'marshal'
        # Vulnerable: Ruby Marshal deserialization
        obj = Marshal.load(decoded_data)
      when 'yaml'
        # Vulnerable: YAML deserialization with unsafe load
        obj = YAML.unsafe_load(decoded_data)
      when 'json'
        # Less vulnerable but still risky with create_additions
        obj = JSON.parse(decoded_data, create_additions: true)
      else
        obj = { error: 'Unknown format' }
      end
      
      # Process the deserialized object
      result = if obj.respond_to?(:call)
                 # Extremely dangerous: executing callable objects
                 obj.call
               elsif obj.respond_to?(:each)
                 obj.map(&:to_s).join(', ')
               else
                 obj.to_s
               end
      
      render json: {
        message: 'Object deserialized successfully',
        result: result,
        object_class: obj.class.name
      }
    rescue => e
      render json: {
        error: e.message,
        type: 'deserialization_error'
      }
    end
  end
  
  private
  
  def custom_hmac_sha256(key, message)
    # Vulnerable custom HMAC implementation
    # Missing proper key padding and has timing vulnerabilities
    digest = Digest::SHA256.new
    key_bytes = key.bytes
    message_bytes = message.to_s.bytes
    
    # Simple XOR with key (not proper HMAC)
    result = []
    message_bytes.each_with_index do |byte, index|
      key_byte = key_bytes[index % key_bytes.length]
      result << (byte ^ key_byte)
    end
    
    digest.update(result.pack('C*'))
    digest.hexdigest
  end
  
  def unsafe_memory_operation(file_path, format)
    # Simulate unsafe memory operation
    # This would normally use FFI to call C functions
    file_size = File.size(file_path)
    
    case format
    when 'header'
      # Read first 256 bytes without bounds checking
      File.open(file_path, 'rb') do |f|
        header = f.read([256, file_size].min)
        header.unpack('H*').first[0..63]
      end
    when 'full'
      # Potentially dangerous for large files
      File.binread(file_path).unpack('H*').first[0..127]
    else
      "unknown_format_#{file_size}"
    end
  end
end
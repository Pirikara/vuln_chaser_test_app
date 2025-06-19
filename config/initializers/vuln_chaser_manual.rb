# Manual VulnChaser setup for integration testing
$LOAD_PATH.unshift(File.expand_path('../../../vuln-chaser-ruby/lib', __FILE__))

require 'vuln_chaser'

# VulnChaser IAST Configuration
VulnChaser.configure do |config|
  # Configure excluded paths (optional)
  config.excluded_paths = ['/health', '/assets', '/favicon.ico']
  
  # Configure custom paths to trace (optional)  
  config.custom_paths = ['app/interactors']
end

# Set up logging
VulnChaser.logger = Rails.logger

# Configure Core API endpoint
ENV['VULN_CHASER_CORE_URL'] = 'http://localhost:8000'

Rails.logger.info "🔍 VulnChaser IAST initialized manually"
Rails.logger.info "📡 Core API endpoint: #{ENV['VULN_CHASER_CORE_URL']}"
# VulnChaser IAST Configuration
VulnChaser.configure do |config|
  # Configure excluded paths (optional)
  config.excluded_paths = ['/health', '/assets', '/favicon.ico']
  
  # Configure custom paths to trace (optional)
  config.custom_paths = ['app/interactors']
  
  # Configure Core API endpoint
  ENV['VULN_CHASER_CORE_URL'] = 'http://localhost:8000'
end

# Set up logging
VulnChaser.logger = Rails.logger

Rails.logger.info "🔍 VulnChaser IAST initialized"
Rails.logger.info "📡 Core API endpoint: #{ENV['VULN_CHASER_CORE_URL']}"
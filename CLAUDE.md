# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Rails 8.0 test application specifically designed to validate the vuln-chaser IAST (Interactive Application Security Testing) gem's detection capabilities. The application contains intentionally vulnerable patterns for security testing purposes only.

**Important**: This is a security testing application with intentional vulnerabilities. It should only be used in controlled development environments for security research and testing.

## Development Commands

### Basic Setup
```bash
bundle install
rails db:create db:migrate db:seed
rails server
```

### Testing
```bash
# Run full test suite
rails test

# Run tests in parallel
rails test --verbose

# Run specific test file
rails test test/controllers/users_controller_test.rb
```

### Security Analysis
```bash
# Run Brakeman security scanner
bundle exec brakeman

# Run RuboCop for code style
bundle exec rubocop

# Check gem dependencies
bundle show
```

### Development Tools
```bash
# Rails console
rails console

# Database operations
rails db:drop db:create db:migrate db:seed

# View routes
rails routes
```

## Architecture

### Core Components

**Controllers**:
- `ApplicationController`: Base controller with standard Rails configuration
- `UsersController`: Handles user search functionality via interactor pattern
- `SimpleTestController`: Contains basic vulnerability test endpoints for validation
- `AdminController`: Administrative functions and system management
- `HomeController`: Root page controller

**Interactors**:
- `UserSearch`: Implements search logic with dynamic query execution (contains intentional SQL injection for testing)

**Models**:
- `User`: Basic ActiveRecord model for testing database interactions

### VulnChaser Integration
The application integrates the vuln-chaser gem for security testing:

- **Middleware**: `VulnChaser::Middleware` configured in `config/application.rb`
- **Configuration**: Located in `config/initializers/vuln_chaser.rb`
- **Core API**: Configured to communicate with `http://localhost:8000`

### Test Endpoints

**Basic Test Endpoints**:
- `/test/sql` - SQL injection test endpoint
- `/test/auth` - Authentication bypass test
- `/test/health` - Basic health check

**Administrative Endpoints** (under `/admin/`):
- `GET /admin/users` - User search and management
- `POST /admin/auth` - Administrative authentication
- `GET /admin/files` - File and asset management
- `GET /admin/settings` - System configuration access
- `POST /admin/feedback` - User feedback collection
- `POST /admin/register` - User registration processing
- `POST /admin/import` - Data import functionality
- `POST /admin/config` - Configuration loading
- `POST /admin/documents` - Document storage system
- `POST /admin/analytics` - Request tracking and analytics
- `POST /admin/sessions` - Session management
- `POST /admin/tokens` - Token verification system

### Database
- Uses SQLite3 for development and testing
- Single `users` table with basic name/email fields
- Migrations in `db/migrate/`

## Technology Stack

- **Ruby**: 3.4.1
- **Rails**: 8.0.2  
- **Database**: SQLite3
- **Asset Pipeline**: Propshaft
- **JavaScript**: Stimulus + Turbo
- **Testing**: Minitest with Capybara/Selenium
- **Security**: Brakeman, vuln-chaser gem
- **Code Style**: RuboCop Rails Omakase
- **Vulnerable Dependencies**: Intentionally outdated gems for CVE testing

## Configuration

### Environment Variables
- `VULN_CHASER_CORE_URL`: Endpoint for vuln-chaser core API (default: `http://localhost:8000`)

### VulnChaser Settings
```ruby
# config/initializers/vuln_chaser.rb
VulnChaser.configure do |config|
  config.excluded_paths = ['/health', '/assets', '/favicon.ico']
  config.custom_paths = ['app/interactors']
end
```

## Development Notes

### Interactor Pattern
This application uses the interactor-rails gem for business logic organization:
- Interactors are located in `app/interactors/`
- Each interactor implements a single `call` method
- Results are accessed via `context` object

### Administrative Features
- User management and search functionality
- Authentication and session handling
- File and document management
- Configuration and settings access
- Data import and processing capabilities
- Analytics and request tracking
- Token-based verification systems

### Database Seeding
```bash
rails db:seed
```
Creates test users for vulnerability testing scenarios.

## API Testing Examples

### Data Import
```bash
curl -X POST http://localhost:3000/admin/import \
  -H "Content-Type: application/json" \
  -d '{"xml_data": "<?xml version=\"1.0\"?><root><data>test</data></root>"}'
```

### Configuration Loading
```bash
curl -X POST http://localhost:3000/admin/config \
  -H "Content-Type: application/json" \
  -d '{"yaml_data": "test: value"}'
```

### Settings Access
```bash
curl "http://localhost:3000/admin/settings?config=database.yml"
```

### Token Verification
```bash
curl -X POST http://localhost:3000/admin/tokens \
  -H "Content-Type: application/json" \
  -d '{"secret": "test_token"}'
```

## Important Security Notes

- This application is designed for security testing and research
- Should only be run in isolated development environments  
- Not suitable for production deployment
- Used exclusively for security tool validation and research
- Contains intentionally outdated dependencies for testing purposes
- All functionality is documented and expected behavior
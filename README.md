# Vuln Chaser Test App

A Rails 8.0 application specifically designed to test and validate the vuln-chaser gem's detection capabilities.

https://github.com/Pirikara/vuln-chaser

## Purpose

This application contains intentionally vulnerable code patterns to:
- Test vuln-chaser gem's detection accuracy
- Compare results with other security tools (Brakeman, CodeQL)
- Demonstrate advanced vulnerability patterns that may bypass standard security scanners

## Features

- User search functionality with dynamic query execution
- Interactor pattern implementation using interactor-rails
- Carefully crafted vulnerable patterns for testing
- Security analysis setup with Brakeman and CodeQL

## Setup

```bash
bundle install
rails db:create db:migrate db:seed
rails server
```

## Development
This project uses:

- Ruby 3.x
- Rails 8.0.1
- SQLite3
- interactor-rails
- Brakeman for security scanning

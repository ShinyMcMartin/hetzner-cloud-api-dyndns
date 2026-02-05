# Hetzner DNS DynDNS Update Script

A modern Bash script for automatically updating DNS records in Hetzner Cloud using the current **Hetzner DNS API (v1)**.

## Features

✅ **Current Hetzner DNS API** - Fully compatible with `https://api.hetzner.cloud/v1/`  
✅ **Zone Name or Zone ID** - Flexible zone specification with automatic ID lookup  
✅ **IPv4/IPv6 Support** - Supports both A and AAAA record types  
✅ **Intelligent Updates** - Only modifies records when IP address changes  
✅ **Automatic IP Detection** - Fetches current public IP automatically  
✅ **Legacy Compatibility** - Supports all legacy environment variables  
✅ **Comprehensive Logging** - Detailed status and debug output  
✅ **Easy Setup** - Minimal required parameters

## Requirements

- `bash` (4.0+)
- `curl` - for API calls
- `jq` - for JSON parsing
- **Hetzner Cloud API Token** with DNS access

### Install Tools (macOS)

```bash
brew install curl jq
```

### Install Tools (Linux)

```bash
# Debian/Ubuntu
sudo apt-get install curl jq

# CentOS/RedHat
sudo yum install curl jq

# Alpine
apk add curl jq
```

## Setup

### 1. Generate API Token

#### Step-by-Step Guide

1. **Open Hetzner Console**: Navigate to https://console.hetzner.com/
2. **Select Your Project**: Click on your project in the left sidebar
3. **Access Security Settings**: Go to **Security → Tokens** (in your project menu)
4. **Generate New Token**: Click the **Generate new token** button
5. **Configure Token**:
   - **Name**: Choose a descriptive name (e.g., "DynDNS", "Dynamic DNS Update")
   - **Permissions**: Ensure token has appropriate access (DNS scope)
   - **Notes** (optional): Add a description for future reference
6. **Copy Token Immediately**: The token will be displayed only once - **copy it right away** (you cannot view it again!)
7. **Store Securely**: Save the token in a secure location - see Security section below

#### What Your Token Looks Like

```
Ytnf.RdCQkHjKmcd2cYKYYjMqD9rGMPvEYz3Kgj9L2Q
```

#### Verify Token Works

```bash
export HETZNER_AUTH_API_TOKEN="Ytnf.RdCQkHjKmcd2cYKYYjMqD9rGMPvEYz3Kgj9L2Q"

# Test the token
curl -s "https://api.hetzner.cloud/v1/zones" \
  -H "Authorization: Bearer ${HETZNER_AUTH_API_TOKEN}" | jq '.zones[] | {id, name}'
```

Expected output:

```json
{
  "id": "abc123def456",
  "name": "example.com"
}
```

### 2. Find Your Zone ID (Optional)

The zone ID is optional - the script can also use the zone name and look it up automatically.

List all your zones:

```bash
curl -s "https://api.hetzner.cloud/v1/zones" \
  -H "Authorization: Bearer ${HETZNER_AUTH_API_TOKEN}" | jq '.zones[] | {id, name}'
```

Example output:

```json
{
  "id": "98jFjsd8dh1GHasdf7a8hJG7",
  "name": "example.com"
}
{
  "id": "7a8hJG7jFjsd8dh1GHasdf",
  "name": "mysite.net"
}
```

## Installation

```bash
# Clone repository
git clone https://github.com/yourusername/hetzner-dyndns.git
cd hetzner-dyndns

# Install script
sudo cp dyndns.sh /usr/local/bin/dyndns
sudo chmod +x /usr/local/bin/dyndns

# Optional: Install helpers
sudo cp config-examples.sh /usr/local/bin/dyndns-config-examples
sudo chmod +x /usr/local/bin/dyndns-config-examples
```

## Usage

### Command-Line Parameters

```bash
dyndns.sh [-z <Zone ID> | -Z <Zone Name>] -n <Record Name> [OPTIONS]
```

**Required Parameters:**

- `-z <Zone ID>` - Zone ID (alternative to `-Z`)
- `-Z <Zone Name>` - Zone name, e.g., `example.com` (alternative to `-z`)
- `-n <Record Name>` - DNS record name, e.g., `dyn` or `@` for zone apex

**Optional Parameters:**

- `-t <TTL>` - Time To Live in seconds (default: 60)
- `-T <Record Type>` - Record type: `A` (IPv4) or `AAAA` (IPv6) (default: A)
- `-r <Record ID>` - Record ID (deprecated, auto-detected)
- `-v` - Verbose mode (enables debug output)
- `-C` - Force colored output
- `-h` - Show help message

### Environment Variables

All parameters can be set as environment variables:

```bash
export HETZNER_AUTH_API_TOKEN="your-api-token"      # required
export HETZNER_ZONE_NAME="example.com"              # OR HETZNER_ZONE_ID
export HETZNER_RECORD_NAME="dyn"                    # required
export HETZNER_RECORD_TTL="120"                     # optional, default: 60
export HETZNER_RECORD_TYPE="A"                      # optional, default: A
export HETZNER_VERBOSE="true"                       # optional, for debug output
export NO_COLOR="1"                                 # optional, disable colors
```

### Usage Examples

#### Example 1: Simple IPv4 with Zone Name

```bash
HETZNER_AUTH_API_TOKEN='your-api-token' \
  dyndns.sh -Z example.com -n dyn
```

#### Example 2: IPv6 Record

```bash
HETZNER_AUTH_API_TOKEN='your-api-token' \
  dyndns.sh -Z example.com -n dyn -T AAAA
```

#### Example 3: Using Zone ID

```bash
HETZNER_AUTH_API_TOKEN='your-api-token' \
  dyndns.sh -z 98jFjsd8dh1GHasdf7a8hJG7 -n dyn
```

#### Example 4: All Environment Variables

```bash
export HETZNER_AUTH_API_TOKEN='your-api-token'
export HETZNER_ZONE_NAME='example.com'
export HETZNER_RECORD_NAME='dyn'
export HETZNER_RECORD_TTL='120'
dyndns.sh
```

#### Example 5: Custom TTL (5 minutes)

```bash
HETZNER_AUTH_API_TOKEN='your-api-token' \
  dyndns.sh -Z example.com -n dyn -t 300
```

#### Example 6: Verbose Debug Mode

```bash
HETZNER_AUTH_API_TOKEN='your-api-token' \
  dyndns.sh -Z example.com -n dyn -v
```

#### Example 7: Update Domain Root (@)

```bash
HETZNER_AUTH_API_TOKEN='your-api-token' \
  dyndns.sh -Z example.com -n @
```

## How the Script Works

### Workflow Overview

The script follows this logical flow:

1. **Argument Parsing**: Parse command-line parameters and environment variables
2. **Validation**: Verify all required parameters are provided
3. **Zone Resolution**:
   - If zone name provided: look up zone ID via API
   - If zone ID provided: validate it exists and is accessible
4. **IP Detection**: Fetch current public IP (IPv4 or IPv6 based on record type)
5. **DNS Record Lookup**: Search for existing DNS record in the zone
6. **Comparison**: Compare current public IP with DNS record value
7. **Update Logic**:
   - If record doesn't exist: create new record
   - If IP matches: skip update (intelligent!)
   - If IP differs: update record with new IP
8. **Verification**: Confirm changes were applied successfully

### Detailed Component Descriptions

#### API Communication (`api_call()`)

```
Input:  HTTP method (GET/POST/PUT), API endpoint, JSON data
Output: Parsed JSON response
Flow:
  1. Construct full API URL (https://api.hetzner.cloud/v1/...)
  2. Add Authorization header with token
  3. Send request with curl
  4. Parse JSON response with jq
  5. Check for API errors
  6. Return parsed data or exit with error
```

**Features:**

- Automatic error detection from API responses
- JSON validation before returning data
- Proper HTTP status code handling
- Error messages with context

#### Zone ID Resolution (`get_zone_id_by_name()`)

```
Input:  Zone name (e.g., "example.com")
Output: Zone ID or error exit
Flow:
  1. Call API GET /zones to list all zones
  2. Filter zones by matching name with jq
  3. Extract zone ID from response
  4. Validate at least one zone found
  5. Return first matching zone ID
```

**Features:**

- Case-sensitive zone name matching
- Support for multiple zones
- Clear error messages if zone not found

#### Public IP Detection

The script uses multiple methods to detect your public IP, with fallback mechanisms:

**IPv4 Detection Order:**

1. Query Hetzner DNS Check API
2. Query icanhazip.com API
3. Query ipify.org API

**IPv6 Detection Order:**

1. Query api6.ipify.org API
2. Query icanhazip.com API

The first successful response is used. This ensures reliability even if one service is down.

#### DNS Record Management

**Record Search (`find_record()`):**

```
Input:  Zone ID, record name, record type (A or AAAA)
Output: Record object or "NOT_FOUND"
Flow:
  1. Fetch all RRsets (resource record sets) for zone
  2. Filter for exact name match
  3. Filter for exact type match
  4. Extract record details
  5. Return first match or indicate not found
```

**Record Creation (`create_record()`):**

```
Input:  Zone ID, name, type, IP value, TTL
Output: Success message or error
Flow:
  1. Prepare JSON payload: {name, type, ttl, records[{value}]}
  2. POST to /zones/{id}/rrsets
  3. API creates new record
  4. Verify creation was successful
```

**Record Update (`update_record()`):**

```
Input:  Zone ID, name, type, IP value, TTL
Output: Success message or error
Flow:
  1. Prepare JSON payload: {records[{value}], ttl}
  2. PUT to /zones/{id}/rrsets/{name}/{type}
  3. API updates existing record
  4. Verify update was successful
```

### Intelligence Features

#### Intelligent IP Change Detection

The script compares the current public IP with the value stored in DNS:

- **No change detected**: Skips API update, logs "IP unchanged", saves API quota
- **IP changed**: Updates DNS record with new value
- **Record missing**: Creates new record automatically

**Why this matters:**

- Reduces API calls and potential rate limiting
- Suitable for running frequently (every minute) via cron
- Logs show whether action was taken or skipped

#### Automatic Record Type Selection

- For A records: Only detects and updates IPv4 addresses
- For AAAA records: Only detects and updates IPv6 addresses
- No mixed types in single record (follows DNS standards)

#### Error Recovery

The script includes multiple fallback mechanisms:

- Multiple IP detection services (if one fails, try next)
- Detailed error messages indicating exact point of failure
- Exit codes indicate success (0) or failure (1+)

### API Payload Structure

The script correctly formats API requests according to Hetzner DNS API v1 specification:

**Creating a Record (POST):**

```json
{
  "name": "dyn",
  "type": "A",
  "ttl": 120,
  "records": [
    {
      "value": "203.0.113.42"
    }
  ]
}
```

**Updating a Record (PUT):**

```json
{
  "ttl": 120,
  "records": [
    {
      "value": "203.0.113.42"
    }
  ]
}
```

**Key Points:**

- `records` is always an array (even with single IP)
- For A/AAAA: `value` is the IP address
- `ttl` is per-record (not per-request)
- Field ordering doesn't matter for API

## Cron Integration

### Automatic Updates via Cron

Schedule the script to run automatically at regular intervals:

```bash
# Edit your crontab
crontab -e

# Add entry (every 5 minutes)
*/5 * * * * HETZNER_AUTH_API_TOKEN='your-api-token' /usr/local/bin/dyndns.sh -Z example.com -n dyn
```

### Cron Expression Guide

| Interval         | Description   | Cron Expression |
| ---------------- | ------------- | --------------- |
| Every minute     | 60 times/hour | `* * * * *`     |
| Every 5 minutes  | 12 times/hour | `*/5 * * * *`   |
| Every 10 minutes | 6 times/hour  | `*/10 * * * *`  |
| Every 15 minutes | 4 times/hour  | `*/15 * * * *`  |
| Every 30 minutes | 2 times/hour  | `*/30 * * * *`  |
| Hourly           | 24 times/day  | `0 * * * *`     |
| Daily            | Once per day  | `0 0 * * *`     |

### Recommended Setup

#### For High-Frequency Updates (DSL/Cable Home Internet)

```bash
# Update every 5 minutes
*/5 * * * * HETZNER_AUTH_API_TOKEN='your-api-token' /usr/local/bin/dyndns.sh -Z example.com -n dyn >> /var/log/dyndns.log 2>&1
```

#### For Stable Networks (Business Connection)

```bash
# Update every 30 minutes
*/30 * * * * HETZNER_AUTH_API_TOKEN='your-api-token' /usr/local/bin/dyndns.sh -Z example.com -n dyn >> /var/log/dyndns.log 2>&1
```

#### For Multiple Records (IPv4 + IPv6)

```bash
# IPv4 update every 5 minutes
*/5 * * * * HETZNER_AUTH_API_TOKEN='your-api-token' /usr/local/bin/dyndns.sh -Z example.com -n dyn -T A >> /var/log/dyndns.log 2>&1

# IPv6 update every 5 minutes
*/5 * * * * HETZNER_AUTH_API_TOKEN='your-api-token' /usr/local/bin/dyndns.sh -Z example.com -n dyn -T AAAA >> /var/log/dyndns.log 2>&1
```

### Logging to File

```bash
# Log with timestamp and rotation
*/5 * * * * HETZNER_AUTH_API_TOKEN='your-api-token' /usr/local/bin/dyndns.sh -Z example.com -n dyn >> /var/log/dyndns.log 2>&1
```

Rotate logs with logrotate:

```bash
# /etc/logrotate.d/dyndns
/var/log/dyndns.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
}
```

## Output and Logging

### Log Levels and Colors

The script provides detailed logging with color-coded output:

#### INFO Messages (Green) - Normal Operation

```
[INFO] Checking zone ID: 341034
[INFO] Zone ID is valid
[INFO] Detecting current public IP (A record)...
[INFO] Current IP: 203.0.113.42
[INFO] Record exists: dyn (A) = 203.0.113.41
[INFO] IP address has changed: 203.0.113.41 → 203.0.113.42
[INFO] Record updated successfully
[INFO] DynDNS update completed: dyn (A) = 203.0.113.42
```

#### DEBUG Messages (Blue) - Verbose Mode Only

Enabled with `-v` flag:

```
[DEBUG] Validating zone ID: 341034
[DEBUG] Fetching zone records...
[DEBUG] Searching for record: name=dyn, type=A
[DEBUG] API Response: {success, data}
[DEBUG] Processing complete
```

#### WARNING Messages (Yellow) - Important Notes

```
[WARN] Both zone ID and zone name provided, using zone ID
[WARN] IP address unchanged, skipping update
[WARN] Multiple zones with name found, using first
```

#### ERROR Messages (Red) - Failures

```
[ERROR] HETZNER_AUTH_API_TOKEN not set
[ERROR] Zone not found: example.com
[ERROR] Failed to detect public IP
[ERROR] API Error: invalid input in fields
```

### Color Output Behavior

The script intelligently detects terminal output:

- **Terminal**: Colored output enabled by default
- **Piped to file**: Colors disabled automatically
- **Piped to command**: Colors disabled automatically
- **Force colors**: Use `-C` flag to force colors
- **Disable colors**: Set `NO_COLOR=1` environment variable

## Technical Details

### API Endpoints Used

The script utilizes the following Hetzner DNS API v1 endpoints:

| Method | Endpoint                           | Purpose                  | Parameters                       |
| ------ | ---------------------------------- | ------------------------ | -------------------------------- |
| GET    | `/zones`                           | List all zones           | Authorization header only        |
| GET    | `/zones/{id_or_name}`              | Get zone details         | Zone ID or name in URL           |
| GET    | `/zones/{id}/rrsets`               | List all records in zone | Zone ID in URL                   |
| POST   | `/zones/{id}/rrsets`               | Create new record        | Zone ID in URL, JSON body        |
| PUT    | `/zones/{id}/rrsets/{name}/{type}` | Update existing record   | Zone/name/type in URL, JSON body |

All endpoints require:

- HTTPS (TLS 1.2+)
- Authorization header: `Authorization: Bearer {token}`
- Content-Type: `application/json`

### IP Detection Services

The script queries multiple external services for resilience:

**IPv4 Services:**

- **Primary**: Hetzner DNS Check (https://dns.hetzner.com/api/checks)
- **Secondary**: icanhazip.com (https://icanhazip.com/)
- **Tertiary**: ipify.org (https://api.ipify.org?format=text)

**IPv6 Services:**

- **Primary**: ipify.org v6 (https://api6.ipify.org?format=text)
- **Secondary**: icanhazip.com (https://icanhazip.com/ - IPv6)

Each request includes a timeout of 5 seconds. If one service fails, the script tries the next one.

### Record Management

#### Searching Logic

```
1. Fetch all RRsets for zone via GET /zones/{id}/rrsets
2. Parse JSON response
3. Find RRset matching:
   - name == requested_name (exact match)
   - type == requested_type (A or AAAA)
4. If found: return current value
   If not found: return NOT_FOUND
```

#### Creating vs Updating

```
IF record_not_found THEN
  POST /zones/{id}/rrsets with full record data
ELSE
  IF current_ip != dns_ip THEN
    PUT /zones/{id}/rrsets/{name}/{type} with new value
  ELSE
    Log "IP unchanged, skipping update"
  END IF
END IF
```

## Troubleshooting

### "HETZNER_AUTH_API_TOKEN not set"

**Problem**: Script exits with error about missing token

**Solution**: Set the token before running

```bash
export HETZNER_AUTH_API_TOKEN='your-api-token'
dyndns.sh -Z example.com -n dyn
```

Or use inline:

```bash
HETZNER_AUTH_API_TOKEN='your-api-token' dyndns.sh -Z example.com -n dyn
```

### "Zone not found: example.com"

**Problem**: Script cannot find the zone name

**Causes**:

- Zone name is misspelled
- Zone doesn't exist in your account
- Token doesn't have access to this zone

**Solution**: Verify zone exists

```bash
curl -s "https://api.hetzner.cloud/v1/zones" \
  -H "Authorization: Bearer ${HETZNER_AUTH_API_TOKEN}" | jq '.zones[] | {id, name}'
```

Use zone ID instead (more reliable):

```bash
dyndns.sh -z 98jFjsd8dh1GHasdf7a8hJG7 -n dyn
```

### "Failed to detect public IP"

**Problem**: Script cannot determine your public IP

**Causes**:

- No internet connection
- All IP detection services are down
- Network firewall blocks outgoing connections
- curl is not installed

**Solution**: Test manually

```bash
# Test IPv4 detection
curl -s "https://icanhazip.com/"
curl -s "https://api.ipify.org?format=text"

# Test IPv6 detection
curl -s -6 "https://api6.ipify.org?format=text"
curl -s -6 "https://icanhazip.com/"
```

If all fail: check firewall and internet connection.

### "API Error: invalid input in fields"

**Problem**: API rejects the record update

**Causes**:

- Malformed JSON payload
- Invalid IP address format
- TTL out of valid range
- Record name contains invalid characters

**Solution**: Enable verbose mode to see exact error

```bash
HETZNER_AUTH_API_TOKEN='token' dyndns.sh -Z example.com -n dyn -v
```

Check IP format (should be valid IPv4 or IPv6):

```bash
# Valid IPv4: 203.0.113.42
# Valid IPv6: 2001:db8::1
```

Check TTL (should be 60-86400 seconds):

```bash
# Valid TTL: 60, 120, 300, 3600, 86400
# Invalid: 0, -1, 999999
```

### "Record exists with different value"

**Problem**: DNS record exists but has unexpected value

**Causes**:

- Another process updated it
- Manual changes in Hetzner console
- Script ran from different network

**Solution**: The script will automatically fix this on next run:

```bash
# Script will update the record to current IP
dyndns.sh -Z example.com -n dyn
```

### Script runs in cron but produces no output

**Problem**: Cron job runs but no log entries created

**Causes**:

- Log file path doesn't exist
- Log file permissions are wrong
- Cron environment variables not set

**Solution**: Create log directory first

```bash
sudo mkdir -p /var/log
sudo touch /var/log/dyndns.log
sudo chmod 666 /var/log/dyndns.log
```

Update crontab with proper logging:

```bash
*/5 * * * * HETZNER_AUTH_API_TOKEN='your-api-token' /usr/local/bin/dyndns.sh -Z example.com -n dyn >> /var/log/dyndns.log 2>&1
```

Test cron job manually:

```bash
env -i HOME=$HOME /bin/sh -c 'cd ~ && /usr/bin/env HETZNER_AUTH_API_TOKEN="your-token" /usr/local/bin/dyndns.sh -Z example.com -n dyn'
```

### "Permission denied" when running script

**Problem**: Cannot execute the script

**Solution**: Make script executable

```bash
chmod +x /usr/local/bin/dyndns.sh
```

Check bash location:

```bash
which bash
# Should output: /bin/bash or /usr/bin/bash
```

Verify shebang is correct:

```bash
head -1 /usr/local/bin/dyndns.sh
# Should be: #!/bin/bash
```

## Security

### API Token Protection

⚠️ **Critical**: Your API token grants full access to your DNS zones

**Protect Your Token:**

1. **Never commit to Git**: Add to `.gitignore`

   ```bash
   echo "HETZNER_AUTH_API_TOKEN" >> .gitignore
   ```

2. **Use environment variables**: Not inline in scripts

   ```bash
   # Good
   export HETZNER_AUTH_API_TOKEN="your-token"
   dyndns.sh ...

   # Bad - visible in process list
   dyndns.sh ... -t "your-token"
   ```

3. **Restrict file permissions**: If stored in file

   ```bash
   touch ~/.hetzner-dyndns-config
   chmod 600 ~/.hetzner-dyndns-config
   echo 'HETZNER_AUTH_API_TOKEN="your-token"' >> ~/.hetzner-dyndns-config
   ```

4. **Use dedicated tokens**: Create separate token per zone/function
   ```bash
   # One token for production domain
   # One token for staging domain
   # Easier to revoke if one is compromised
   ```

### Cron Security

**Protect credentials in cron jobs:**

Bad (credentials visible):

```bash
*/5 * * * * HETZNER_AUTH_API_TOKEN='xyz' /usr/local/bin/dyndns.sh ...
```

Better (credentials in file):

```bash
# Create secure config file
echo 'HETZNER_AUTH_API_TOKEN="xyz"' > ~/.config/dyndns.env
chmod 600 ~/.config/dyndns.env

# In crontab
*/5 * * * * source ~/.config/dyndns.env && /usr/local/bin/dyndns.sh ...
```

### Log File Security

**Protect log files** (may contain IP information):

```bash
sudo chown nobody:nogroup /var/log/dyndns.log
sudo chmod 640 /var/log/dyndns.log
```

### Token Rotation

**Rotate tokens regularly:**

1. Generate new token in Hetzner console
2. Update environment or config file
3. Verify script works with new token
4. Revoke old token in console

**Recommended rotation schedule:**

- Every 6-12 months for critical systems
- Immediately if token might be exposed
- When team members leave

### Network Security

**Consider using bastion hosts:**

- Run script on secure server
- Use SSH tunnels for sensitive operations
- Monitor API access logs in Hetzner console

**Monitor for suspicious activity:**

```bash
# In Hetzner console: Security → Tokens → Activity
# Review token usage regularly
```

## Examples

### Example 1: Basic Setup for Home Internet

```bash
# 1. Get token from Hetzner console
# 2. Create config file
mkdir -p ~/.config/dyndns
cat > ~/.config/dyndns/dyndns.env << 'EOF'
export HETZNER_AUTH_API_TOKEN="Ytnf.RdCQkHjKmcd2cYKYYjMqD9rGMPvEYz3Kgj9L2Q"
export HETZNER_ZONE_NAME="example.com"
export HETZNER_RECORD_NAME="home"
EOF

# 3. Secure the config
chmod 600 ~/.config/dyndns/dyndns.env

# 4. Test it
source ~/.config/dyndns/dyndns.env
dyndns.sh

# 5. Add to crontab
crontab -e
# */5 * * * * source ~/.config/dyndns/dyndns.env && dyndns.sh
```

### Example 2: IPv4 and IPv6 Both Enabled

```bash
#!/bin/bash
# Update both A and AAAA records

source ~/.config/dyndns/dyndns.env

echo "Updating IPv4 record..."
dyndns.sh -T A

echo "Updating IPv6 record..."
dyndns.sh -T AAAA

echo "Done!"
```

### Example 3: Multiple Domains

```bash
#!/bin/bash
# Update multiple domains at once

source ~/.config/dyndns/dyndns.env

DOMAINS=("domain1.com" "domain2.net" "sub.example.org")

for DOMAIN in "${DOMAINS[@]}"; do
  echo "Updating $DOMAIN..."
  HETZNER_ZONE_NAME="$DOMAIN" dyndns.sh
done
```

### Example 4: With Error Handling

```bash
#!/bin/bash
source ~/.config/dyndns/dyndns.env

if dyndns.sh; then
  echo "Update successful"
  exit 0
else
  echo "Update failed!"
  # Send alert email, Slack notification, etc.
  exit 1
fi
```

## License

GPL-3.0

## Support

- [Hetzner Cloud Documentation](https://docs.hetzner.cloud/reference/dns-api-overview)
- [Hetzner DNS API Reference](https://docs.hetzner.cloud/reference/dns-api)
- [Hetzner Community Forum](https://community.hetzner.com/)

## Changelog

### Version 2.0 (2026-02-05)

- ✨ Complete rewrite for current Hetzner DNS API v1
- ✨ Support for zone name with automatic ID lookup
- ✨ IPv6 support (AAAA records)
- ✨ Intelligent updates (only when IP changes)
- ✨ Automatic public IP detection with fallbacks
- ✨ Comprehensive logging with color output
- ✨ Full backward compatibility with legacy environment variables
- ✨ Verbose debug mode
- ✨ Better error handling and diagnostics
- ✨ Complete documentation

### Version 1.x (Legacy)

- Old Cloud API version (deprecated)
- See [FarrowStrange/hetzner-api-dyndns](https://github.com/FarrowStrange/hetzner-api-dyndns)

## Contributing

Contributions are welcome! Please create a pull request or open an issue for bugs and feature requests.

## Roadmap

- [ ] Systemd timer integration
- [ ] Docker container support
- [ ] Ansible playbook
- [ ] Configuration file format
- [ ] Multi-record support in single run
- [ ] Health-check endpoint
- [ ] Prometheus metrics export

---

**Note**: This script is unofficial and not directly supported by Hetzner Cloud. For official documentation see [docs.hetzner.cloud](https://docs.hetzner.cloud/).

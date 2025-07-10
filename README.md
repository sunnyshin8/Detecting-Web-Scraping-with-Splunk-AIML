# Web Scraping Detection with Splunk AIML - Project Setup Guide

## Project Overview
This project implements comprehensive web scraping detection using Splunk's Machine Learning Toolkit (MLTK) and infrastructure analysis based on IP hostname resolution data from client_hostname.csv files.

## Project Structure
```
Detecting Web Scraping with Splunk AIML/
├── client_hostname.csv               # IP hostname resolution dataset
├── splunk_config/
│   ├── props.conf                    # Field extractions for client_hostname.csv
│   └── transforms.conf               # Lookup tables configuration
├── lookups/
│   ├── known_crawlers_lookup.csv     # Known legitimate bots/crawlers
│   └── geo_ip_lookup.csv            # IP geolocation data
├── spl_queries/
│   └── web_scraping_detection.spl    # Core detection queries
├── dashboards/
│   └── web_scraping_dashboard.xml    # Dashboard panels and queries
├── alerts/
│   └── savedsearches.conf           # Automated alert configurations
├── ml_models/
│   └── model_training.spl           # MLTK model training scripts
└── access.log             # Main dataset for analysis
```

## Quick Deployment

### Option 1: Automated Deployment (Recommended)
```powershell
# Run the deployment script 
.\deploy_to_splunk.ps1

# For custom Splunk installation pat:
.\deploy_to_splunk.ps1 -SplunkHome "G:\Splunk"
```

### Option 2: Manual Deployment
Follow the detailed setup instructions below.

## Detailed Setup Instructions

### 1. Prerequisites
- Splunk Enterprise or Splunk Cloud installed
- Machine Learning Toolkit (MLTK) app installed
- Administrative access to create apps and indexes

### 2. Splunk App Setup

#### A. Create Splunk App Directory Structure
```bash
# Option 1: If you have SPLUNK_HOME set
export SPLUNK_HOME="/opt/splunk"
mkdir -p $SPLUNK_HOME/etc/apps/web_scraping_detection/{local,lookups,metadata}


#### B. Copy Configuration Files
```bash

# For Windows 
copy splunk_config\props.conf "C:\Program Files\Splunk\etc\apps\web_scraping_detection\local\"
copy splunk_config\transforms.conf "C:\Program Files\Splunk\etc\apps\web_scraping_detection\local\"
copy lookups\*.csv "C:\Program Files\Splunk\etc\apps\web_scraping_detection\lookups\"
```

#### C. Create App Configuration
Create `$SPLUNK_HOME/etc/apps/web_scraping_detection/metadata/default.meta`:
```ini
[views]
export = system

[lookups]
export = system
```

#### D. Create Index and Upload Data
```bash
# Create index via CLI
$SPLUNK_HOME/bin/splunk add index infrastructure_analysis
```
### 3. Data Ingestion

#### Upload client_hostname.csv to Splunk:
1. Go to Splunk Web > Settings > Add Data
2. Choose "Upload" 
3. Select `client_hostname.csv`
4. Set Source Type: `client_hostname_data`
5. Set Index: `infrastructure_analysis`
6. Review and Submit
### 4. Install Machine Learning Toolkit (MLTK)
1. In Splunk Web, go to Apps → Find More Apps
2. Search for "Machine Learning Toolkit" 
3. Install and restart Splunk

### 5. Set Up Dashboards and Alerts
1. Import dashboard XML from `dashboards/web_scraping_dashboard.xml`
2. Configure alerts using `alerts/savedsearches.conf`
3. Adjust email settings and thresholds as needed

## Key Detection Features

### 1. Infrastructure-Based Analysis
- Analyzes IP hostname resolution patterns to identify hosting infrastructure
- Maps client IPs to hosting providers, ISPs, and geographic regions
- Detects suspicious DNS patterns and anonymization services

### 2. Multi-Layer Threat Detection
- **Hosting Provider Analysis**: Identifies concentrated activity from hosting services
- **Geographic Clustering**: Detects coordinated attacks from specific regions  
- **DNS Pattern Analysis**: Flags suspicious hostname patterns and resolution failures
- **ISP Classification**: Categorizes traffic by ISP type (residential, hosting, VPN)

### 3. Machine Learning Models
- **Anomaly Detection**: Identifies statistical outliers in infrastructure patterns
- **Clustering Analysis**: Groups similar hosting infrastructure behaviors
- **Risk Scoring**: ML-based assessment of infrastructure threat levels
- **Ensemble Methods**: Combines multiple detection techniques

### 4. Real-Time Monitoring
- Dashboard with infrastructure risk visualization
- Automated alerts for suspicious hosting patterns
- Geographic threat mapping and trend analysis
- DNS health monitoring and resolution tracking

## Key Queries and Use Cases

### High-Risk Infrastructure Detection
```spl
index=infrastructure_analysis sourcetype=client_hostname_data earliest=-24h
| eval hosting_provider=case(
    match(hostname, "(?i)(aws|amazon|ec2)"), "AWS",
    match(hostname, "(?i)(azure|microsoft)"), "Azure", 
    match(hostname, "(?i)(gcp|google|cloud)"), "GCP",
    match(hostname, "(?i)(digital|ocean|linode|vultr)"), "VPS_Provider",
    1=1, "Unknown")
| stats count as total_ips,
        dc(client_ip) as unique_ips,
        values(hostname) as sample_hostnames
  by hosting_provider
| where total_ips > 100
| sort - total_ips
```

### Suspicious DNS Pattern Detection
```spl
index=infrastructure_analysis sourcetype=client_hostname_data
| where hostname=client_ip OR match(hostname, "Unknown host|Errno")
| stats count as failed_resolutions,
        dc(client_ip) as affected_ips
  by hostname
| where failed_resolutions > 50
```

### Infrastructure Anomaly Detection with MLTK
```spl
index=infrastructure_analysis sourcetype=client_hostname_data
| eval hosting_score=case(
    match(hostname, "(?i)(aws|azure|gcp|cloud)"), 3,
    match(hostname, "(?i)(vps|hosting|server)"), 2,
    hostname=client_ip, 1,
    1=1, 0)
| stats avg(hosting_score) as avg_hosting_score,
        count as ip_count,
        dc(hostname) as unique_hostnames
  by client_ip
| fit DensityFunction avg_hosting_score ip_count unique_hostnames into infrastructure_model
| apply infrastructure_model
| where isOutlier > 0
```

## Alerting Thresholds

### Critical Alerts (Immediate Response)
- 50+ IPs from same hosting provider in 1 hour
- High concentration of DNS resolution failures (>80%)
- ML infrastructure anomaly score > 0.95

### Warning Alerts (Investigation Needed)
- 20+ IPs from VPS/cloud providers in 30 minutes
- Geographic clustering anomalies (3x above region average)
- Suspicious hostname patterns detected (>10 similar patterns)

## Data Fields Reference

### Core Fields (from client_hostname.csv)
- `client`: Client IP address
- `hostname`: Resolved hostname for the IP
- `alias_list`: DNS alias information (if available)
- `address_list`: Associated IP addresses for hostname

### Derived Fields (calculated by Splunk)
- `hosting_provider`: Cloud/hosting service classification
- `country_code`: Geographic location of IP
- `isp_type`: ISP classification (residential/hosting/vpn)
- `suspicious_pattern`: Suspicious hostname pattern indicator
- `bot_infra_score`: ML-based infrastructure risk score (0-10)
- `dns_health`: DNS resolution health status
- `risk_level`: CRITICAL/HIGH/MEDIUM/LOW threat assessment

## Troubleshooting

### Common Issues
1. **Deployment failures**: Use the automated deployment script `deploy_to_splunk.ps1`
2. **Field extraction errors**: Verify CSV format matches expected client_hostname.csv structure
3. **MLTK model errors**: Ensure sufficient data volume for training (>1000 records)
4. **False positives**: Tune thresholds and update legitimate infrastructure whitelist

### Performance Optimization
- Use summary indexing for large hostname datasets
- Implement data model acceleration for infrastructure analysis
- Set appropriate time ranges for real-time alerts
- Regular model retraining (weekly/monthly)

## Security Considerations
- Monitor for IP rotation and hosting provider switching
- Implement network-level blocking for confirmed threats
- Regular review of hosting provider whitelist
- Integration with threat intelligence feeds for known bad infrastructure

## Future Enhancements
- Integration with DNS threat intelligence feeds
- Automated infrastructure blocking via REST API
- Enhanced geographic analysis with VPN/proxy detection
- Deep learning models for advanced infrastructure pattern recognition

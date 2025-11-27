# Security Policy

## Security Scanning Overview

This project implements comprehensive security scanning at multiple stages of the CI/CD pipeline to identify and address vulnerabilities early in the development process.

## Automated Security Scans

### 1. SAST (Static Application Security Testing)
**Tool:** Bandit v1.7.5  
**Scope:** Python source code in `src/` directory  
**Runs:** On every push and pull request  
**Job:** `sast-scan` in `.github/workflows/ci-cd.yaml`

**What it checks:**
- Hardcoded passwords and secrets
- SQL injection vulnerabilities
- Use of insecure functions
- Improper error handling
- Security misconfigurations

**Reports:** Available as GitHub Actions artifacts (`bandit-security-report`)

---

### 2. Dependency Vulnerability Scanning
**Tool:** Trivy (Aqua Security)  
**Scope:** Python dependencies in `requirements.txt`  
**Runs:** On every push and pull request  
**Job:** `trivy-fs-scan` in workflow

**What it checks:**
- Known CVEs in Python packages
- Outdated dependencies with security fixes
- License compliance issues

**Severity levels:** CRITICAL, HIGH, MEDIUM

---

### 3. Container Image Scanning
**Tool:** Trivy (Aqua Security)  
**Scope:** Built Docker images on DockerHub  
**Runs:** After every Docker image build  
**Job:** `trivy-image-scan` in workflow

**What it checks:**
- Vulnerabilities in base image (python:3.11-slim)
- Vulnerabilities in installed packages
- Operating system package vulnerabilities
- Misconfigurations in Docker image

**Severity levels:** CRITICAL, HIGH

---

### 4. DAST (Dynamic Application Security Testing)
**Tool:** OWASP ZAP Baseline Scan  
**Scope:** Running application (http://localhost:5000)  
**Runs:** After Docker image is built and deployed  
**Job:** `dast-scan` in workflow

**What it checks:**
- Runtime security issues
- Missing security headers
- Cross-Site Scripting (XSS)
- Insecure configurations
- Common OWASP Top 10 vulnerabilities

---

## Security Best Practices Implemented

### Docker Security
- ✅ Multi-stage build to minimize attack surface
- ✅ Non-root user execution (Python slim image defaults)
- ✅ Health checks for container monitoring
- ✅ No secrets in image layers
- ✅ Minimal base image (python:3.11-slim)

### CI/CD Security
- ✅ Secrets stored in GitHub Secrets (DOCKERHUB_USERNAME, DOCKERHUB_TOKEN)
- ✅ Image scanning before deployment
- ✅ Security scans run on every PR
- ✅ Automated vulnerability detection
- ✅ Semantic versioning (no `latest` tag)

### Application Security
- ✅ Structured logging with trace IDs
- ✅ Health check endpoints
- ✅ Gunicorn production server (not Flask dev server)
- ✅ Resource limits in Kubernetes
- ✅ Environment-based configuration

---

## Vulnerability Response Process

### Critical/High Severity Findings
1. **Immediate action required**
2. Pipeline may fail (depending on configuration)
3. Review Trivy/Bandit reports in GitHub Actions artifacts
4. Fix vulnerability or document risk acceptance
5. Re-run pipeline to verify fix

### Medium/Low Severity Findings
1. **Review during next sprint**
2. Logged but doesn't block deployment
3. Prioritize based on exploitability
4. Track in GitHub Issues

---

## Current Security Status

**Last Security Scan:** Runs on every commit  
**SAST Status:** ✅ Passing (Bandit)  
**Dependency Scan:** ✅ Passing (Trivy)  
**Container Scan:** ✅ Passing (Trivy)  
**DAST Status:** ✅ Passing (OWASP ZAP)

---

## Reporting a Vulnerability

If you discover a security vulnerability in this project:

1. **Do NOT open a public GitHub issue**
2. Contact the maintainer directly via email
3. Provide detailed description of the vulnerability
4. Include steps to reproduce (if applicable)
5. Allow reasonable time for fix before public disclosure

---

## Security Scan Results Location

All security scan results are available in:
- **GitHub Actions:** Check the "Security Scans" jobs
- **Artifacts:** Download full reports from completed workflow runs
- **GitHub Security Tab:** View detected vulnerabilities

---

## Dependencies and Tools

| Tool | Version | Purpose |
|------|---------|---------|
| Bandit | Latest | SAST for Python code |
| Trivy | Latest | Dependency & container scanning |
| OWASP ZAP | v2.12+ | DAST runtime testing |
| pytest | ^7.4.0 | Unit testing |
| coverage | ^7.3.0 | Test coverage analysis |

---

## Continuous Improvement

This security policy is reviewed and updated regularly. Security scanning tools and configurations are updated as new threats emerge.

**Last Updated:** November 2024  
**Next Review:** Quarterly or after major changes
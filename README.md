# TFS Request Signing & Recaptcha Bypass Toolkit

This project provides a specialized suite of `mitmproxy` scripts designed for API pentesting. It automates the process of generating digital signatures for JSON requests and capturing/injecting Recaptcha tokens, facilitating seamless testing with tools like Hoppscotch or Postman.

## Features

- **Automated Request Signing**: `sign_requests.py` intercepts outgoing JSON requests, calculates a cryptographic signature using a private key, and injects it into the payload.
- **Recaptcha Token Stealing**: `steal_recaptcha.py` captures Recaptcha tokens from a browser-driven login attempt and saves them locally.
- **Dynamic Injection**: Automatically injects captured Recaptcha tokens into requests that require them, allowing for automated API testing of protected endpoints.

## Prerequisites

- Python 3.12+
- [uv](https://github.com/astral-sh/uv) (recommended package manager)
- [mitmproxy](https://mitmproxy.org/)

## Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/iluvgirlswithglasses/tfs-request-signing
   cd tfs-request-signing
   ```

2. **Install dependencies**:
   ```bash
   uv sync
   ```

3. **Configure Environment**:
   Create a `.env` file in the root directory and add your Base64-encoded private key:
   ```env
   PRIVATE_KEY_B64=your_base64_encoded_private_key
   ```

## Usage

The toolkit typically runs as two separate proxy instances to isolate the "stealing" and "signing" logic.

### 1. Start the Recaptcha Stealer (Port 8081)
This proxy captures tokens from your browser.
```bash
mitmproxy --ssl-insecure -s steal_recaptcha.py --mode regular@8081
```
Configure your browser to use `http://localhost:8081` as its proxy and solve a Recaptcha on the target site.

### 2. Start the Request Signer (Port 8080)
This proxy handles signature calculation and token injection for your API client.
```bash
mitmproxy --ssl-insecure -s sign_requests.py --mode regular@8080
```
Point your API client (e.g., Hoppscotch) to `http://localhost:8080`.

## Technical Details

- **Signing Algorithm**: RSASSA-PKCS1-v1\_5 with SHA-512.
- **Canonicalization**: Keys are sorted alphabetically (case-insensitive) and values are concatenated. Specific fields like `Signature` and `recaptcha` are excluded during signing.
- **Inter-process Communication**: The stealer saves tokens to a local `.recaptcha-tokens` file, which the signer monitors for injection.

## Documentation
For a detailed guide on the pentesting workflow (in Vietnamese), refer to `doc/pentest-guide.pdf` or the source `doc/main.typ`.

# TFS Request Signing - Project Context

## Overview
This repository is a toolkit for bypassing API security measures (Request Signing and Recaptcha) during security audits of a specific target system. It uses `mitmproxy` to perform man-in-the-middle modifications on HTTP traffic.

## Core Logic & Conventions

### 1. Request Signing (`sign_requests.py`)
- **Algorithm**: RSA (PKCS#1 v1.5) with SHA-512.
- **Canonicalization**: Replicates a specific JavaScript implementation.
    - Excludes `Signature`, `recaptcha`, and `remoteIp` from the signing payload.
    - Keys are sorted alphabetically.
    - Keys are converted to `lowerCamelCase` in the canonical string representation.
    - Supports nested objects and arrays.
- **Injection**: If a login request (`/login/new-device`) has an empty `recaptcha` field, it attempts to pop a token from `.recaptcha-tokens`.

### 2. Recaptcha Capture (`steal_recaptcha.py`)
- **Target**: Intercepts requests ending with `/login/new-device`.
- **Behavior**: Extracts the `recaptcha` token, appends it to `.recaptcha-tokens`, and **clears the original request body**. This prevents the browser's request from consuming the token, allowing it to be reused by the pentester in another tool.

## Key Files
- `sign_requests.py`: Main signing and injection logic.
- `steal_recaptcha.py`: Token capture logic.
- `.env`: (Ignored) Stores `PRIVATE_KEY_B64`.
- `.recaptcha-tokens`: (Local only) Temporary queue for captured tokens.

## Engineering Standards
- **Python**: 3.12+, managed via `uv`.
- **Security**: Never commit private keys or `.env` files.
- **Testing**: Changes to signing logic must be verified against the canonicalization rules defined in `json_values_to_sorted_string`.

"""
Example:
{
    "recaptcha": "",
    "remoteIp": "",
    "loginName": "060969420069",
    "password": "Kaka@1234",
    "deviceId": "77fc6e5a-1850-4ee5-8de0-438e6140cb10",
    "deviceName": "Linux",
    "deviceType": "PC",
    "Signature": "dyy9IDhk8wbgWe0JHsMZnK3f6t9I/pdSKqHIZmbvFOtw8yls494Rx6mCYAx9JFU8tM+peR6lnPhsxbC1qOe1xytkrJhlB8+dbRVVudVnMWa4Odb1n7az6dtuB5ID6Yp4rvf6h5ER5CHWcK+7/XLTVVHpMS8Paoo1bQobUwQcWnNA37v73IxEUSxgEIkop1wyFyK+q0raRKGN3pbOLnAMUMGiDOEfDapDKA8IT7X3Tz8limrrO9oV9tXRfw0X962z0ruJM7xIod/4Oc7WxQPMtguzmI4HI+m+cf6vvFJqOjQn11vFm8jqyINFmfoQY4t5zvpbIlnPkiYDUR/u5yJnyQ=="
}
"""

import base64
import json
import os

import dotenv
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding
from mitmproxy import http


def get_private_key(b64_string):
    key_bytes = base64.b64decode(b64_string)
    return serialization.load_der_private_key(key_bytes, password=None)


dotenv.load_dotenv()
PRIVATE_KEY_B64 = os.getenv("PRIVATE_KEY_B64", "")
PRIVATE_KEY_OBJ = get_private_key(PRIVATE_KEY_B64)


def lower_first(s):
    if not s:
        return s
    return s[0].lower() + s[1:]


def json_values_to_sorted_string(obj):
    """Replicates the JS jsonValuesToSortedString logic."""
    if obj is None:
        return ""

    if isinstance(obj, list):
        return ",".join([json_values_to_sorted_string(item) for item in obj])

    # typescript 'number' ~ python 'int | float'
    if isinstance(obj, (int, float)) and not isinstance(obj, bool):
        s = f"{obj:g}"  # Emulates JS: trimZeros(String(obj))
        return s

    if isinstance(obj, dict):
        # case-insensitive filtered keys
        filtered_keys = [
            k
            for k in obj.keys()
            if k.lower() not in ["signature", "recaptcha", "remoteip"]
        ]

        # sort
        filtered_keys.sort()

        # merge string
        parts = []
        for key in filtered_keys:
            output_key = lower_first(key)
            val = json_values_to_sorted_string(obj[key])
            parts.append(f"{output_key}={val}")

        return "&".join(parts)

    return str(obj)


def sign_data(data_string, private_key):
    """Signs data using RSASSA-PKCS1-v1_5 with SHA-512."""
    signature = private_key.sign(
        data_string.encode("utf-8"), padding.PKCS1v15(), hashes.SHA512()
    )
    return base64.b64encode(signature).decode("utf-8")


def load_recaptcha_token() -> str | None:
    try:
        if not os.path.exists(".recaptcha-tokens"):
            return None

        with open(".recaptcha-tokens", "r") as f:
            lines = f.readlines()

        if not lines:
            return None

        token = lines[0].strip()
        with open(".recaptcha-tokens", "w") as f:
            f.writelines(lines[1:])

        return token
    except Exception:
        return None


def request(flow: http.HTTPFlow) -> None:
    # only process POST/PUT requests with JSON bodies
    if flow.request.method not in ["POST", "PUT"]:
        return

    try:
        # load the request body
        data = json.loads(flow.request.content)  # pyright: ignore[reportArgumentType]

        # skip if signature already exists
        if "Signature" in data:
            return

        # load the recaptcha token if necessary
        is_login = flow.request.pretty_url.endswith("/login/new-device")
        if (
            is_login
            and "recaptcha" in data
            and not data["recaptcha"]
            and (recaptcha_token := load_recaptcha_token())
        ):
            data["recaptcha"] = recaptcha_token

        canonical = json_values_to_sorted_string(data)
        signature = sign_data(canonical, PRIVATE_KEY_OBJ)
        data["Signature"] = signature
        flow.request.content = json.dumps(data).encode("utf-8")

    except (json.JSONDecodeError, KeyError):
        pass

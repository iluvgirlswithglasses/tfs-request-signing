import json

from mitmproxy import http


def request(flow: http.HTTPFlow):
    if not flow.request.pretty_url.endswith("/login/new-device"):
        return

    try:
        data = json.loads(flow.request.content)  # pyright: ignore[reportArgumentType]
        recaptcha = data.get("recaptcha", "")
        if not recaptcha:
            return

        with open(".recaptcha-tokens", "a") as f:
            f.write(recaptcha + "\n")

        # prevent this request to send the recaptcha token
        # because it would invalidate our captcha
        flow.request.content = json.dumps({}).encode("utf-8")

    except Exception:
        return

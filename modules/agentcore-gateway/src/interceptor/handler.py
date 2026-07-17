"""AgentCore Gateway interceptor Lambda.

This is a minimal "echo" interceptor: it logs the full event the gateway sends
at each interception point and returns the documented pass-through output so
traffic flows unmodified.

Interceptor contract (devguide "Types of interceptors"):
- The event arrives under an "mcp" key (MCP targets, parsed JSON bodies) or an
  "http" key (HTTP and inference targets, base64-encoded string bodies), with
  "gatewayResponse" populated only at the RESPONSE interception point.
- The output must be {"interceptorOutputVersion": "1.0", ...} carrying
  transformedGatewayRequest / transformedGatewayResponse; echoing the raw
  event back is rejected with "Received invalid response from interceptor".
- A REQUEST interceptor that returns transformedGatewayResponse short-circuits
  the target call, so the pass-through never sets it there. Omitted fields
  (headers, statusCode) fall back to the original values.
"""

import json
import logging
import os

logger = logging.getLogger()
logger.setLevel(os.environ.get("LOG_LEVEL", "INFO"))

OUTPUT_VERSION = "1.0"


def _safe_json(value):
    """Serialize for logging without blowing up on non-JSON types."""
    try:
        return json.dumps(value, default=str)
    except (TypeError, ValueError):
        return repr(value)


def _passthrough(event):
    """Build the documented no-op output for the invoking protocol and point."""
    if "http" in event:
        http = event.get("http") or {}
        if http.get("gatewayResponse") is not None:
            # Documented HTTP response pass-through: an empty http object.
            return {"interceptorOutputVersion": OUTPUT_VERSION, "http": {}}
        body = (http.get("gatewayRequest") or {}).get("body")
        return {
            "interceptorOutputVersion": OUTPUT_VERSION,
            "http": {"transformedGatewayRequest": {"body": body}},
        }

    mcp = event.get("mcp") or {}
    response = mcp.get("gatewayResponse")
    if response is not None:
        return {
            "interceptorOutputVersion": OUTPUT_VERSION,
            "mcp": {
                "transformedGatewayResponse": {
                    "statusCode": response.get("statusCode", 200),
                    "body": response.get("body", {}),
                }
            },
        }
    return {
        "interceptorOutputVersion": OUTPUT_VERSION,
        "mcp": {
            "transformedGatewayRequest": {
                "body": (mcp.get("gatewayRequest") or {}).get("body", {})
            }
        },
    }


def handler(event, context):
    """Log the interceptor event and return the pass-through output."""
    request_id = getattr(context, "aws_request_id", "unknown")
    protocol = "http" if "http" in event else "mcp"
    payload = event.get(protocol) or {}
    point = "RESPONSE" if payload.get("gatewayResponse") is not None else "REQUEST"

    logger.info(
        "interceptor invoked request_id=%s protocol=%s point=%s event=%s",
        request_id,
        protocol,
        point,
        _safe_json(event),
    )

    output = _passthrough(event)
    logger.info(
        "interceptor pass-through request_id=%s output=%s",
        request_id,
        _safe_json(output),
    )
    return output

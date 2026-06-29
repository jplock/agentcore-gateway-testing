"""AgentCore Gateway interceptor Lambda.

This is a minimal "echo" interceptor. AgentCore Gateway invokes it at the
configured interception points (REQUEST and/or RESPONSE). The handler logs the
full event it receives and returns the payload unchanged, which makes it useful
for inspecting exactly what the gateway sends and expects back.

Interceptor contract (high level):
- The gateway invokes this function synchronously at each interception point.
- The event contains the interception context plus the request or response
  payload that is flowing through the gateway.
- To leave the traffic untouched, the function returns the same payload back to
  the gateway. Returning a modified payload would mutate the in-flight
  request/response.
"""

import json
import logging
import os

logger = logging.getLogger()
logger.setLevel(os.environ.get("LOG_LEVEL", "INFO"))


def _safe_json(value):
    """Serialize for logging without blowing up on non-JSON types."""
    try:
        return json.dumps(value, default=str)
    except (TypeError, ValueError):
        return repr(value)


def handler(event, context):
    """Echo the interceptor event back to the gateway.

    Logs the inbound event (and any identifiable interception point) and returns
    the payload unchanged so the gateway continues processing normally.
    """
    request_id = getattr(context, "aws_request_id", "unknown")

    # The interception point is surfaced under different keys depending on the
    # gateway version; check the common ones for nicer logs.
    interception_point = (
        event.get("interceptionPoint")
        or event.get("interception_point")
        or event.get("point")
        or "UNKNOWN"
    )

    logger.info(
        "interceptor invoked request_id=%s interception_point=%s event=%s",
        request_id,
        interception_point,
        _safe_json(event),
    )

    # Echo the event straight back. The gateway treats the returned object as the
    # (possibly modified) payload to continue with; returning it verbatim is a
    # no-op pass-through.
    logger.info("interceptor returning payload unchanged request_id=%s", request_id)
    return event

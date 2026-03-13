"""
orders-ingestion Lambda handler.

Processes order events from SQS. Uses ReportBatchItemFailures so that
only failed messages are retried rather than the entire batch.
"""

import json
import logging
import os

logger = logging.getLogger()
logger.setLevel(os.environ.get("LOG_LEVEL", "INFO"))


def lambda_handler(event, context):
    """Process a batch of SQS order event messages."""
    batch_item_failures = []

    for record in event.get("Records", []):
        message_id = record["messageId"]
        try:
            body = json.loads(record["body"])
            order_id = body.get("order_id")
            logger.info("Processing order %s (message: %s)", order_id, message_id)

            _process_order(body)

        except Exception:
            logger.exception("Failed to process message %s", message_id)
            batch_item_failures.append({"itemIdentifier": message_id})

    return {"batchItemFailures": batch_item_failures}


def _process_order(order: dict) -> None:
    """Validate and persist an incoming order.

    In production this would write to a datastore, emit domain events, etc.
    """
    required_fields = ["order_id", "customer_id", "items"]
    missing = [f for f in required_fields if f not in order]
    if missing:
        raise ValueError(f"Order missing required fields: {missing}")

    logger.info(
        "Order %s accepted — customer=%s, items=%d",
        order["order_id"],
        order["customer_id"],
        len(order["items"]),
    )

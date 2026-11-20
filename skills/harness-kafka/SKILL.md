---
name: harness-kafka
description: Use when you write or change Kafka producers, consumers, topics, schemas, or stream processing, or run Kafka CLI tools.
---

# Kafka

Check the client library and its version first. Config names differ between clients (Java, librdkafka, kafkajs, franz-go, sarama).

## Delivery
- Default to at-least-once. A consumer can receive a message more than one time.
  Make each handler idempotent: use a unique message key or ID and deduplicate.
- Commit the offset after processing, not before.
- Kafka transactions give exactly-once only inside Kafka. An external side effect (database, HTTP) still needs idempotency.
  For a database write plus an event, use an outbox table if the project has one.

## Producers
- Use `acks=all` and idempotence (`enable.idempotence=true`) unless the project sets otherwise.
- The key selects the partition. Order is kept only per partition. Use the entity ID as the key when order matters.
- Handle send errors. Do not ignore the delivery result.

## Consumers
- Processing time per poll must stay below `max.poll.interval.ms`. Otherwise the consumer leaves the group and a rebalance starts.
- Handle a poison message: retry a limited number of times, then send it to the dead-letter topic of the project. Do not block the partition forever.
- Close the consumer on shutdown so that the group rebalances quickly.

## Schemas
- If the project uses a schema registry, change the schema there with its compatibility rules.
- Keep changes backward compatible: add optional fields with defaults. Do not rename, remove, or change the type of a field.

## Topics
- Do not create, delete, or change topic config on a shared cluster. Write the command in the report.
- Adding partitions changes the key-to-partition mapping. It breaks per-key order for existing keys.

## CLI
- Read-only: `kafka-topics --describe`, `kafka-consumer-groups --describe`.
- `kafka-consumer-groups --reset-offsets --execute` and `kafka-topics --delete` change state.
  Run them only on a local or allowed cluster.

## Tests
- Use a real broker in a container (Testcontainers or Docker Compose, as the project does) for integration tests.
- Use synthetic messages only.

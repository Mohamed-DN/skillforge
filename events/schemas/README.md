# Event Schemas

This directory contains Protobuf schema definitions for all events in the system.

## Events

| Event | Topic | Producer | Consumers |
|-------|-------|----------|-----------|
| `UserRegistered` | `user.registered` | api-gateway | user-profile-service, notification-service |
| `UserAnsweredQuestion` | `assessment.answer` | api-gateway | ai-worker |
| `CVUploaded` | `cv.uploaded` | api-gateway | cv-analyzer |
| `CVAnalyzed` | `cv.analyzed` | cv-analyzer | ai-worker, user-profile-service |
| `CompetencyVectorUpdated` | `competency.updated` | ai-worker | assessment-engine, notification-service |
| `LearningPathGenerated` | `learning.path.generated` | ai-worker | notification-service |
| `AssessmentCompleted` | `assessment.completed` | assessment-engine | ai-worker, notification-service |

## Schema Evolution Rules

- **Backward compatible**: New consumers can read old messages
- **Forward compatible**: Old consumers can read new messages
- Use optional fields for new additions
- Never remove or rename required fields
- Never change field numbers

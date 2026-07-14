namespace FiapCloudGames.Contracts;

public sealed record UserCreatedEvent(
    Guid UserId,
    string Name,
    string Email,
    DateTime OccurredAtUtc);

public sealed record OrderPlacedEvent(
    Guid OrderId,
    Guid UserId,
    Guid GameId,
    string UserEmail,
    string GameName,
    decimal Price,
    DateTime PlacedAtUtc);

public sealed record PaymentProcessedEvent(
    Guid OrderId,
    Guid UserId,
    Guid GameId,
    string UserEmail,
    string GameName,
    decimal Price,
    string Status,
    DateTime ProcessedAtUtc);

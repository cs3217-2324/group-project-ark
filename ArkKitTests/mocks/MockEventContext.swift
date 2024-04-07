@testable import ArkKit

class MockEventContext: ArkEventContext {
    func emit<Event>(_ event: Event) where Event: ArkKit.ArkEvent {
    }

    func subscribe(to eventId: ArkKit.ArkEventID, _ listener: @escaping EventListener) {
    }
}

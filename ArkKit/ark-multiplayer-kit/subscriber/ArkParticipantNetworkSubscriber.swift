import Foundation

class ArkParticipantNetworkSubscriber: ArkNetworkSubscriberDelegate {
    // network related dependencies
    var networkService: AbstractNetworkService

    // inject dependency
    weak var localState: ArkState?
    weak var localGameLoop: GameLoop?

    init(subscribeTo networkService: AbstractNetworkService) {
        self.networkService = networkService
        self.networkService.subscriber = self
    }

    /// Participants only listen to ecs updates from host
    func onListen(_ data: Data) {
        do {
            let wrappedData = try JSONDecoder().decode(DataWrapper.self, from: data)

            if wrappedData.type == .ecs {
                let ecsWrapper = try ArkECSDataSerializer.decodeArkECS(from: wrappedData.payload)
                processECSUpdates(ecsWrapper)
            }

            localGameLoop?.update()
        } catch {
            print("Error decoding received data: \(error)")
        }
    }

    private func processECSUpdates(_ updatedECSStateWrapper: ArkECSWrapper) {
        guard let ecs = localState?.arkECS else {
            return
        }
        // remove all outdated entities
        ecs.removeAllEntities(except: updatedECSStateWrapper.entities)

        ecs.bulkUpsert(
            entities: updatedECSStateWrapper.entities,
            components: updatedECSStateWrapper.decodeComponents()
        )
    }
}

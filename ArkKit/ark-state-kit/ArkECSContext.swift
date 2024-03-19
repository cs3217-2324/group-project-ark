protocol ArkECSContext {
    func createEntity() -> Entity
    func removeEntity(_ entity: Entity)
    func upsertComponent<T: Component>(_ component: T, to entity: Entity)
    func getComponent<T: Component>(ofType type: T.Type, for entity: Entity) -> T?
    func createEntity(with components: [Component]) -> Entity
    func getEntities(with componentTypes: [Component.Type]) -> [Entity]
    func getComponents(from entity: Entity) -> [Component]
    func addSystem(_ system: System)
}

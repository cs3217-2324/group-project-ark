protocol GameLoopable {
    var gameLoop: GameLoop? { get }
    func handleGameProgress(dt: Double)
}

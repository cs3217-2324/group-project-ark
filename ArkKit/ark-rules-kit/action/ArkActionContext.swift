/**
 * A facade which encapsulates all the sub-contexts used in the execution of an action in `ArkBlueprint`.
 */
struct ArkActionContext<AudioEnum: ArkAudioEnum> {
    let ecs: ArkECSContext
    let events: ArkEventContext
    let display: DisplayContext
    let audio: any AudioContext<AudioEnum>
}

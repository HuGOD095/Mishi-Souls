extends Node3D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var simulador_ragdoll: PhysicalBoneSimulator3D = $Armature/Skeleton3D/PhysicalBoneSimulator3D
@onready var espada_espalda: Node3D = %EspadaEspalda
@onready var espada_mano: Node3D = %EspadaMano
@onready var sonido_desenvainar: AudioStreamPlayer = $Desenvainar

func activar_ragdoll():
	anim_player.stop()
	simulador_ragdoll.active = true
	simulador_ragdoll.physical_bones_start_simulation()
	
	for hueso in simulador_ragdoll.get_children():
		if hueso is PhysicalBone3D:
			hueso.apply_central_impulse(global_transform.basis.z * 2.5 + Vector3.UP * 1.5)
	
func mostrar_en_espalda() -> void:
	espada_espalda.visible = true
	espada_mano.visible = false
	sonido_desenvainar.pitch_scale = 0.92 # Un poco más grave al guardar
	sonido_desenvainar.play()

func mostrar_en_mano() -> void:
	espada_espalda.visible = false
	espada_mano.visible = true
	sonido_desenvainar.pitch_scale = 1.05 # Un poco más agudo al desenfundar
	sonido_desenvainar.play()

func ocultar_todas() -> void:
	espada_espalda.visible = false
	espada_mano.visible = false

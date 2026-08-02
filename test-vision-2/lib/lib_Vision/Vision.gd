class_name Vision
extends Node

@onready var manager = $Manager
@export var player: CharacterBody3D
@export var camera: Camera3D

static var instances: Vision
const GROUP_ENTITY = "entity"
const SHADER_ARG_MASK = "vision_mask"

func register_entity(node: Node) -> void:
	manager.register_entity(node)

func _ready() -> void:
	if !player: push_warning("player not assigned in Vision")
	if !camera: push_warning("camera not assigned in Vision")
	instances = self

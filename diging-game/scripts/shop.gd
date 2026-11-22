class_name Shop
extends Node2D


@export var interact_icon: Sprite2D

@onready var shop_ui: ShopUI = %ShopUI

func _process(_delta: float) -> void:
	if interact_icon:
		if interact_icon.visible:
			if Input.is_action_just_pressed("interact"):
				print("Interact with shop")
				EventBus.shop_opened.emit()
				interact_icon.hide()
		else:
			if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("ui_cancel"):
				print("Close shop")
				EventBus.shop_closed.emit()

func _on_interact_range_body_entered(body: Node2D) -> void:
	if body is Player:
		interact_icon.show()


func _on_interact_range_body_exited(body: Node2D) -> void:
	if body is Player:
		interact_icon.hide()

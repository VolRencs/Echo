extends Node

@export var Labels: Array[Label3D] = []

var show: bool = false

func _process(_delta):
	if show == false:
		for label in Labels:
			label.visible = false
	elif true:
		for label in Labels:
			print(label)
			label.visible = true

func enable_Label():
	show = true

func disable_Label():
	show = false

extends VBoxContainer
class_name PlayerInformation

# Instances
@onready var username_label: Label = $Username
@onready var avatar: TextureRect = $Avatar

func set_username_text(text: String, host: bool = false):
	username_label.text = text
		
	if host:
		username_label.text = username_label.text + "👑"
		username_label.modulate = Color.GOLD
		
func set_avatar_image(avatar_image: ImageTexture) -> void:
	avatar.texture = avatar_image
	

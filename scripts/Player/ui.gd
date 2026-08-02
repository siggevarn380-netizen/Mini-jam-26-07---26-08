extends CanvasLayer

@onready var health_bar = $PlayerUI/HealthBar
@onready var health_bar_text = $PlayerUI/HealthBar/HealthText

@onready var score_text = $ScoreUI/ScoreValues

func update_health_UI(current_health: int, max_health: int):
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_bar_text.text = str(current_health) + "/" + str(max_health)

func udpate_player_lives_UI(remaining_lives: int):
	$PlayerUI/RemainingLivesLabel.text = "X" + str(remaining_lives)
	

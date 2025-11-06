extends Sprite2D

# Reference the child Timer node
@onready var frame_timer: Timer = $FrameTimer

# Define the two frames to cycle through when speaking
const ACTIVE_SPEAKING_FRAMES = [0, 1] 

# The default frame to display when not speaking
const IDLE_FRAME = 1 

var is_speaking: bool = false


func _ready():
	# Initialize the random number generator
	randomize() 
	
	# Set the initial frame to the idle frame
	frame = IDLE_FRAME
	
	# Connect the Timer's timeout signal
	frame_timer.timeout.connect(_on_frame_timer_timeout)


# Function called by the Timer to change the frame
func _on_frame_timer_timeout():
	if is_speaking:
		# Choose a random frame index only from the ACTIVE_SPEAKING_FRAMES array
		var new_frame_index = ACTIVE_SPEAKING_FRAMES.pick_random()
		
		# Apply the new frame index
		frame = new_frame_index
		
		# Randomize the next wait time slightly
		frame_timer.wait_time = randf_range(0.15, 0.3) 
		frame_timer.start()


# --- Public Methods to Control Animation (Called from AiChat.gd) ---

func start_speaking():
	if is_speaking: return
	is_speaking = true
	
	# Ensure timer is short for a "talking" effect
	frame_timer.wait_time = 0.2 
	frame_timer.start()

func stop_speaking():
	is_speaking = false
	frame_timer.stop()
	# Return to the specified idle frame
	frame = IDLE_FRAME

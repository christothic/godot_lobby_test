extends TextEdit

func setup_console():
    await get_tree().create_timer(0.001).timeout
    set_v_scroll(get_v_scroll_bar().max_value)
    move_to_front()
    hide()
    set_smooth_scroll_enabled(true)
    
func _ready():
    setup_console()
    
func _input(_event):
    if Input.is_action_just_pressed("console"):
        visible = !visible
        if visible:
            move_to_front()
            set_v_scroll(get_v_scroll_bar().max_value)
    return


func add(content):
    text += content + "\n"
    set_v_scroll(get_v_scroll_bar().max_value)

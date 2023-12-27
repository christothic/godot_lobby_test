extends Node

#var file = File()
var file: FileAccess = null
var console = Console

func everywhere(content):
    var to_print = str(content)
    print(to_print)
    if file:
        file.store_line(to_print)
    if console:
        console.add(to_print)
    
func _ready():
    var log_path = "user://console_log.txt"
    file = FileAccess.open(log_path, FileAccess.WRITE)
    
#func _notification(what):
    #if what == NOTIFICATION_WM_CLOSE_REQUEST:
        #file.close()
        
func _exit_tree():
    file.close()

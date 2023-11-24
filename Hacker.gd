extends Control

var hacker_name = 'Hacker'
var team = 'green'
var role = 'telnet'
var status_terminal_id = 0
var command_terminal_id = 0
var game_terminal_id = 0
var address = '127.0.0.1'
var game_ip_address = "192.168.1.10"
var game_connection = ""
var criteria = ""
var wait_time = 5
var abilities = []
var portrait = 1
var keywords = []
var dos_timer = 0

#Deprecated?    
func get_state():
    var state = {}
    state['id'] = status_terminal_id
    state['name'] = hacker_name
    state['role'] = role
    state['team'] = team
    state['address'] = address
    return state

func to_string():
    return "Hacker: " + hacker_name + " (" + team + ") " + role + " status:" + str(status_terminal_id) + " cmd:" + str(command_terminal_id) + " game:" + str(game_terminal_id) + " ip:" + address + " ability " + str(abilities)

func set_status_terminal_id(id):
    status_terminal_id = id
    
func set_command_terminal_id(id):
    command_terminal_id = id
    
func set_game_terminal_id(id):
    game_terminal_id = id

func add_ability(ability):
    abilities.append(ability)
    $HackerAbilityLabel.text += ability + "\n"

func set_portrait(portrait_id):
    var filesystem = File.new()
    var portrait_file_path = "res://portraits/" + portrait_id + ".png"
    if filesystem.file_exists(portrait_file_path):
        portrait = portrait_id
        var texture = load(portrait_file_path)
        $HBoxContainer/PortraitSprite.texture = texture

func train(new_name, new_team, new_role, new_address, new_game_ip_address, new_portrait):
    hacker_name = new_name
    $HBoxContainer/HackerNameLabel.text = hacker_name
    team = new_team
    role = new_role
    address = new_address
    game_ip_address = new_game_ip_address
    set_portrait(new_portrait)

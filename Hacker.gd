extends Node2D

export var playername = 'Hacker'
export var team = 'green'
export var role = 'telnet'
export var connection_id = 0
export var address = '127.0.0.1'
var items = {}
var wait_time = 5

func _ready():
    randomize()
    
func get_state():
    var state = {}
    state['id'] = connection_id
    state['name'] = playername
    state['role'] = role
    state['team'] = team
    state['address'] = address
    return state

func train(new_name, new_team, new_role, id, new_address):
    name = new_name
    playername = new_name
    connection_id = id
    team = new_team
    role = new_role
    address = new_address

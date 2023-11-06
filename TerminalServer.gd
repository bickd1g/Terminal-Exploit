extends Node2D
#TODO:
#Add IDs for status, command and game terminals per hacker
#Add chat functionality to send only to matching team colours

#Server listening port
const PORT = 9876

#Create the WebSocketServer instance
var _server = WebSocketServer.new()

var Hacker = load("res://Hacker.tscn")

var clients = {}
#Players array should be deprecated maybe? Only used for physical adjacency
var players = []

var warm_colours = ["RED", "YELLOW", "ORANGE", "TOMATO", "VOLCANO", "SUMMER", "FLAMINGO", "SUNSET", "NEONRED", "MARISCHINO"]
var cool_colours = ["BLUE", "GREEN", "RIVER", "SEAFOAM", "BLIZZARD", "SKY", "AQUATIC", "ALGAE", "ARCTIC", "ELECTRICCYAN", "TURQUOISE"]

var green_score = 0
var orange_score = 0

var rng : RandomNumberGenerator = RandomNumberGenerator.new()

const WAITING: int = 0
const IN_PROGRESS: int = 1
const ENDED_GREEN_WIN: int = 2
const ENDED_ORANGE_WIN: int = 3

var game_state = 0

func _ready():
    # Connect base signals to get notified of new client connections,
    # disconnections, and disconnect requests.
    _server.connect("client_connected", self, "_connected")
    _server.connect("client_disconnected", self, "_disconnected")
    _server.connect("client_close_request", self, "_close_request")
    # This signal is emitted when not using the Multiplayer API every time a
    # full packet is received.
    # Alternatively, you could check get_peer(PEER_ID).get_available_packets()
    # in a loop for each connected peer.
    _server.connect("data_received", self, "_on_data")
    # Start listening on the given port.
    var err = _server.listen(PORT)
    if err != OK:
        print("Unable to start server")
        set_process(false)
    $CanvasLayer/Panel/IPLabel.text = 'Server IP/s: '
    for address in IP.get_local_addresses():
        if (address.split('.').size() == 4) and not (address.begins_with('169') or address.begins_with('127')):
            $CanvasLayer/Panel/IPLabel.text += ' ( ' + address + ' ) '
    
    rng.randomize()
    
func _connected(id, proto):
    # This is called when a new peer connects, "id" will be the assigned peer id,
    # "proto" will be the selected WebSocket sub-protocol (which is optional)
    var cnx = "Client %d connected with protocol: %s" % [id, proto]
    $CanvasLayer/Panel/ConnectionsLabel.text = cnx

func _close_request(id, code, reason):
    # This is called when a client notifies that it wishes to close the connection,
    # providing a reason string and close code.
    var cnx = "Client %d disconnecting with code: %d, reason: %s" % [id, code, reason]
    $CanvasLayer/Panel/ConnectionsLabel.text = cnx

func _disconnected(id, was_clean = false):
    # This is called when a client disconnects, "id" will be the one of the
    # disconnecting client, "was_clean" will tell you if the disconnection
    # was correctly notified by the remote peer before closing the socket.
    var cnx = "Client %d disconnected, clean: %s" % [id, str(was_clean)]
    $CanvasLayer/Panel/ConnectionsLabel.text = cnx
    if id in clients:
        $CanvasLayer/Panel/MessageLog.text += clients[id].playername + ' has left the server.\n'
        remove_child(clients[id])
        clients.erase(id)
        players.remove(players.find(id))
    $CanvasLayer/Panel/MessageLog.scroll_vertical=INF
    
func _process(delta):
    # Call this in _process or _physics_process.
    # Data transfer, and signals emission will only happen when calling this function.
    _server.poll()
    
func _on_data(id):
    # Print the received packet, you MUST always use get_peer(id).get_packet to receive data,
    # and not get_packet directly when not using the MultiplayerAPI.
    var pkt = _server.get_peer(id).get_packet()
    var incoming = pkt.get_string_from_utf8()
    var address = str(_server.get_peer_address(id))
    var message = 'kay'
    $CanvasLayer/Panel/StatusLabel.text = incoming
    #This needs to check 
    if incoming.begins_with('join:'):
        if clients.has(id):
            clients[id].rename(incoming.right(5))
        elif game_state != 1:
            var hacker_details = incoming.right(5).split('|')
            clients[id] = create_hacker(hacker_details[0], hacker_details[1], hacker_details[2], id, address)
            players.append(id)
            $CanvasLayer/Panel/MessageLog.text += hacker_details[0] + ' has entered the server.\n'
            $CanvasLayer/Panel/MessageLog.text += 'Connection from '+ address + '\n'
            $CanvasLayer/Panel/MessageLog.scroll_vertical=INF
            message = 'ID: ' + str(id)
    elif incoming.begins_with('msg:'):
        var msg_content = incoming.right(4)
        $CanvasLayer/Panel/MessageLog.text += clients[id].playername + ": " + msg_content + '\n'
        $CanvasLayer/Panel/MessageLog.scroll_vertical=INF
        #This should only send to status term clients of the correct team
        for client in clients:
            if clients[client].team == clients[id].team:
                var msg = {}
                msg['name'] = clients[id].playername
                msg['content'] = msg_content
                var team_msg = 'msg:' + JSON.print(msg)
                _server.get_peer(client).put_packet(team_msg.to_utf8())
    elif incoming.begins_with('kill:'):
        var item = incoming.right(5)
        if item in clients[id].items:
            clients[id].items.erase(item)
            if item in warm_colours:
                change_score(id, 1)
            else:
                change_score(id, -1)
    #For prototyping test purposes - to be removed            
    elif incoming == 'dev:add':
        change_score(id, 1)
    elif incoming == 'dev:sub':
        change_score(id, -1)
        
func change_score(client_id, amount):
    if clients[client_id].team == 'orange':
        orange_score += amount
        $CanvasLayer/OrangePanel/OrangeScoreLabel.text = str(orange_score)
    elif clients[client_id].team == 'green':
        green_score += amount
        $CanvasLayer/GreenPanel/GreenScoreLabel.text = str(green_score)

#need to accommodate team too
func create_hacker(username, team, role, id, address):
    var hacker = Hacker.instance()
    hacker.train(username, team, role, id, address)
    add_child(hacker)
    return hacker

#Only send to status terminals?
func _on_ServerDataPulse_timeout():
    for client in clients:
        var client_state = 'state:' + JSON.print(clients[client].get_state())
        _server.get_peer(client).put_packet(client_state.to_utf8())

#Prototype - remove all warm colours, keep all cool colours
func _on_WaitTimer_timeout():
    for client_id in clients:
        #Nested for to check if items have expired?
        var client = clients[client_id]
        client.wait_time -= 1
        if client.wait_time <= 0:
            client.wait_time = rng.randi_range(5,15)
            var colour = ""
            if client.wait_time % 2 == 0:
                colour = warm_colours[randi() %warm_colours.size()]
            else:
                colour = cool_colours[randi() %cool_colours.size()]
            client.items[colour] = rng.randi_range(15, 25)
            var item = 'item:' + colour
            _server.get_peer(client_id).put_packet(item.to_utf8())

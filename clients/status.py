import terminal_api
import time
import os
import platform
from datetime import datetime

current_os = "Windows"

if platform.system() != "Windows":
    current_os = "Other"

#size the cmd prompt. EMBIGGEN!
if current_os == "Windows":
    os.system(f'mode con: cols={terminal_api.status_width} lines={terminal_api.status_height}')
console = terminal_api.console

#Win10 default cmd prompt size appears to be 120 chars wide by 30 chars tall
#This gives us limited vertical real estate - 
#todo: store the last X messages in a list and print them when new messages arrive
chat_log = ["", "", "", "", ""]
MAX_CHAT_LOG_HISTORY = 5

#Number of seconds to wait between status updates
UPDATE_DELAY = 1

game_log = ["","",""]
MAX_GAME_LOG_HISTORY = 3

directive_log = ["","","",""]
MAX_DIRECTIVE_LOG_HISTORY = 4

#Terminal type
terminal = 'status'

player_name_colour_options = ["cyan", "magenta", "red", "yellow"]
player_name_colours = {}

team_members = {}

team_colour = "orange1"
if terminal_api.team == "green":
    team_colour = "green"

my_colour = player_name_colour_options.pop(0)
player_name_colours[terminal_api.name] = my_colour

def clear_screen():
    if current_os == "Windows":
        os.system('cls')
    else:
        os.system('clear')

#Top line info always appears at the top of the console - username and IP address
def print_top_line_info():
    console.print(f"[{team_colour}]User[/{team_colour}] [{my_colour}]{terminal_api.name}[{my_colour}] [{team_colour}]connected from {terminal_api.game_ip_address}[/{team_colour}]")

#sssslat time stamp 🧛‍♂️!!!!! 
def print_chat_log(): 
    for chat_message in chat_log: 
        console.print(f"{chat_message}")

def print_game_log():
    for game_message in game_log:
        console.print(game_message)

#section for directives - unsure of the print part here lowk
def print_directive_log():
    print("Directive log: ")
    for directive_message in directive_log:
        console.print(directive_message)

#current connection + countdown
def print_connection_info():
    connection_type = terminal_api.game_connection["connection_type"]
    connection_ip = terminal_api.game_connection["connection_ip"]
    connection_time = terminal_api.game_connection["connection_time"]
    if connection_type:
        if connection_time > 0:
            terminal_api.game_connection["connection_time"] -= 1
        console.print(f"{connection_type} {connection_ip} {connection_time}")
    else:
        console.print("Not currently connected to any opponents.")

print('Connecting to server...')

def print_team_info():
    for team_member in team_members.values():
        console.print(f'{team_member["hacker_name"]} \t {team_member["role"]} \t {team_member["game_ip"]} \t {team_member["keywords"]}')

if terminal_api.connect(terminal):
    clear_screen()
    while terminal_api.active: 
        clear_screen() 
        print_top_line_info() 
        for i in range(len(terminal_api.status_queue)):
            message = terminal_api.status_queue.pop(0) 
            if message.startswith("msg:"):
                message = message[4:]
                colon_position = message.find(':') 
                msg_sender = message[0:colon_position] 
                msg_content = message[colon_position+1:] 
                name_colour = ""
            
                if msg_sender not in player_name_colours:
                    player_name_colours[msg_sender]= player_name_colour_options.pop(0) 
                name_colour = player_name_colours[msg_sender]
                timestamp = datetime.now().strftime("%H:%M:%S")
                chat_log.append(f"{timestamp} [{name_colour}]{msg_sender}:[/{name_colour}]{msg_content}") 
                if len(chat_log) > MAX_CHAT_LOG_HISTORY: 
                    chat_log.pop(0) 
            elif message.startswith("game:"):
                message = message[5:]
                game_log.append(message)
                if len(game_log) > MAX_GAME_LOG_HISTORY:
                    game_log.pop(0)
            elif message.startswith("directive:"):
                timestamp = datetime.now().strftime("%H:%M:%S")
                directive_log.append(f"{timestamp} - {message}")
                if len(directive_log) > MAX_DIRECTIVE_LOG_HISTORY:
                    directive_log.pop(0)
            elif message.startswith("team:"):
                player_details = message[5:].split("|")
                team_mate_name = player_details[0]
                team_mate_role = player_details[1]
                team_mate_ip = player_details[2]
                team_mate_keywords = player_details[3]
                team_members[team_mate_name] = {"hacker_name":team_mate_name, "role":team_mate_role, "game_ip":team_mate_ip, "keywords":team_mate_keywords}
        
        console.print()
        print_chat_log()
        console.print()
        print_game_log()
        console.print()
        print_connection_info()
        console.print()
        print_directive_log()
        console.print()
        print_team_info()
        time.sleep(UPDATE_DELAY)

    terminal_api.disconnect()
else:
    print("Failed to connect.")

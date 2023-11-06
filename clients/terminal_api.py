from websocket import create_connection
import threading
import asyncio
import json

active = True
last_server_message = ''
server_message = ''

#variables from server:
#encounter_state (WAITING, IN_PROGRESS, ENDED_FAIL, ENDED_WIN, UDEAD)
#boss_balance (integer - balance remaining)
#num_musos (integer - how many musos are connected)
#muso_list (list - from json - of muso dicts)

playername = 'Hacker'
role = 'telnet'

server_fails = 0

#Listener thread receives responses from the server
#It writes to global variables for access via other functions
def listener(server):
  global server_message
  global last_server_message
  global server_fails
  global active
  while active:
    #This try/except is too broad - should only capture network issues
    try:
      server_message = server.recv().decode("utf-8")
      if server_message.startswith('state:'):
        state = json.loads(server_message[6:])
        global playername 
        playername = state['name']
        global connection_id 
        connection_id = state['id']
      elif server_message.startswith('msg:'):
        message = json.loads(server_message[4:])
        sender = message['name']
        content = message['content']
        print(f'{sender}: {content}', end='\n> ')
      elif server_message.startswith('item:'):
        item = server_message[5:]
        print(f'New item: {item}', end='\n> ')
      else:
        if last_server_message != server_message:
            print(server_message, end='\n> ')
        else:
            last_server_message = server_message
    except:
      print('no valid message from server')
      server_fails += 1
      if server_fails >= 3:
        active = False

def send(message):
  global server
  server.send(message)

def remove_item(item):
  send(f'kill:{item}')

def disconnect():
  global server
  global active
  active = False
  server.close()

#Join request sent using: "join:<name>|<team>|<role>"
#For robustness in future, should be base64 encoded or similar
def connect(name, team, role, ip, port=8765):
  global server
  connected = False
  try:
    server = create_connection(f'ws://{ip}:{port}')
    server.send(f'join:{name}|{team}|{role}')
    conn_id = server.recv()
    print(conn_id)
    message = ''
    listener_thread = threading.Thread(target = listener, args=(server,))
    listener_thread.start()
    connected = True
  except:    
    print("Error connecting to the server.")
  return connected

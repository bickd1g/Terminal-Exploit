import terminal_api
import time

settings_filename = 'client_settings.txt'

#Default settings - don't change these!
ip = '127.0.0.1'
port = 9876
name = 'plague'
team = 'green'
role = 'telnet'

#Terminal type
terminal = 'status'

def get_setting(setting_line):
    return setting_line[5:].strip()

#This could be more robust! But good enough for now!
with open (settings_filename, 'r') as settings:
    for line in settings.readlines():
      if line.startswith('addr:'):
          ip = get_setting(line)
      elif line.startswith('port:'):
          port = get_setting(line)
      elif line.startswith('user:'):
          name = get_setting(line)
      elif line.startswith('team:'):
          team = get_setting(line)
      elif line.startswith('role:'):
          role = get_setting(line)
      elif line.startswith('head'):
          head = get_setting(line)

print('Connecting to server...')

print(name, team, role, ip, port, head, terminal)

if terminal_api.connect(name, team, role, terminal, head, ip, port):
    print('Connected.')
    message = ''

    while terminal_api.active:
        if len(terminal_api.status_queue) > 0:
            message = terminal_api.status_queue.pop()
            print(message)
        time.sleep(1)

    terminal_api.disconnect()
else:
    print("Failed to connect.")

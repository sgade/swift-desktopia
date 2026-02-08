meta:
  id: desktopia_pro_x
  title: Desktopia Pro X
  file-extension: dprox
  license: MIT
  ks-version: 0.11
  endian: be
doc: |
  Ergotopia Desktopia Pro X is a height-adjustable desk that can be controlled
  via a USB connection. Internally, this is a serial connection with a
  propriatary protocol.
seq:
  - id: commands
    type: command
    repeat: eos
types:
  command:
    seq:
      - id: header
        type: u1
        doc: The header byte, determining the source of the command.
      - id: header_repeat
        type: u1
      - id: command_id
        type: u1
        enum: app_command
        doc: The command identifier from the app.
        if: header == 0xF1
      - id: desk_id
        type: u1
        enum: desk_command
        doc: The command identifier form the desk.
        if: header == 0xF2
      - id: data
        type: u1
        repeat: until
        repeat-until: _ == 0x7E
    enums:
      source:
        0xF1: app
        0xF2: desk
      app_command:
        0xAA: heartbeat
        0x07: show_status
        0x01: move_up
        0x02: move_down
        0x03: save_memory_1
        0x04: save_memory_2
        0x05: move_memory_1
        0x06: move_memory_2
        0x27: move_memory_3
        0xAB: stand_reminder
      desk_command:
        0x01: height_info

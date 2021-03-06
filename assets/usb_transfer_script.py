#! /usr/bin/env python

import serial
import wave
import struct
import scipy


'''
6.111 USB transfer script
Luis Fernandez

Script runs through a coe file (basically row after row of 8 bit values) and
sends line by line.
'''

ser = serial.Serial(port='/dev/tty.usbserial-FTDHKA57')

a = open('audio_convert/Fa48k8bit.coe','r')

for line in a:
    
    line = line.rstrip()[0:-1]
    line = int(line, base=2)

    b = struct.pack("<H", line)
    
    r = ser.write(b[0])
  
ser.close()

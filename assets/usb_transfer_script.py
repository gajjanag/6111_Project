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

#luis's labkit
#ser = serial.Serial(port='/dev/tty.usbserial-FTDHKA57')#, baudrate=921600)

#rishi's labkit
ser = serial.Serial(port='/dev/tty.usbserial-A900a0YF')

a = open('Petrucci_test1.coe','r')

for line in a:
    
    line = line.rstrip()
    line = int(line)
    
    b = struct.pack("<H", line)
    
    #print line#repr(b[0])
    
    r = ser.write(b[0])#'\x01')#line)
  
ser.close()




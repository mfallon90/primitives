import serial

ser = serial.Serial('COM3', baudrate=9600, bytesize=8, timeout=1)

for _ in range(100000):
    ser.write(b'a')



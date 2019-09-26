'''
Created on 22 Sep 2019

@author: Ishwar S Lyall
'''
import serial
import time



memory_data = []
ser = serial.Serial('COM9',1000000)

#data = "While you're all wasting your time hanging around for Cyberpunk 2077, glorious Keanu Reeves action is already heading our way on October 8th. Good Shepherd Entertainment has announced a release date for John Wick Hex, arriving in October on PC through the Epic Games Store. Exclusively, we should add, as it ever needed adding as far as Epic Store titles are concerned.It's being developed by Bithell Games, a British studio which has built up a fearsome repertoire already, counting Thomas Was Alone, Volume, and Subsurface Circular among its successes.John Wick Hex is a bit of a curio, offering up action-oriented turn-based tactics. It's chin-stroking strategy fused with slick weapon choreography. XCOM meets Superhot, including the opportunity to see a real-time run at the end of a level.It's one of those genius ideas that seems astoundingly obvious once you see it. Stepping into the vengeful shoes of John Wick himself, players have limited ammo and weapons, utilising turn-based tactics with time-simulated reloads, ballistics, and movement. There's no reloading at the end of a turn here, this is a decision which eats up precious time during this kung-fu ballet."
data = "This weekend at TwitchCon, Nvidia is showing off its next generation streaming enhancements, dubbed the RTX Broadcast Engine. It turns out those GeForce RTX graphics cards aren't just about ray tracing in games. Leveraging the Tensor cores on the RTX series Turing GPUs, Nvidia is able to provide real-time effects like virtual greenscreen, AR avatars, and style transfer filters. And thanks to the improvements in NVENC (Nvidia's hardware accelerated video encoding engine), you can also get improved stream quality without tanking framerates all running from a single PC without a bunch of extra dedicated hardware.For professional streamers, the new additions may not matter that much. If you have a dedicated streaming studio, multiple cameras, sound mixing, and high-end 4K video capture hardware running in a second PC dedicated to encoding your livestream, you're not going to give all that up. But for amateurs and people just getting into streaming, the RTX Broadcast Engine helps bring down the cost of entry while improving your overall stream quality.As the name implies, you'll need a GeForce RTX graphics card to make use of the new features. That's because several of the enhancements rely on the Tensor cores. However, the GTX 1660 and GTX 1660 Ti do have an improved video encoding engine that can still offload that complex task from your CPU, and NVENC is supported in the most popular streaming solutions, including OBS, XSplit, Streamlabs, Twitch Studio, Discord, and more."
#s = ser.read(13)
split_data = [data[i:i+256] for i in range(0, len(data), 256)]
#for i in s:
#    print(chr(i),end = '')
addr0 = 0
addr1 = 0
addr2 = 0
#print('\r')
print (len(data))
print (split_data)
print (len(split_data))
ser.write([0x62,0xff]) #b
time.sleep(0.1)
ser.write('a'.encode(encoding='utf_8')) #b
ser.write([0,0,0])
time.sleep(0.1)
for i in split_data:
    print (len(i))
    if(len(i) <256):
        ser.write([0x62,len(i)-1]) #b
        time.sleep(0.01)
    ser.write('g'.encode(encoding='utf_8'))
    for j in i :
        ser.write(j.encode(encoding='utf_8'))
        print(j,end='')
        if(addr2 == 255):
            addr2 =0
            if(addr1 == 255):
                addr1 = 0
                if(addr0 == 1):
                    addr0 = 0
                else:
                    addr0 += 1
            else:
                addr1+=1
        else:
            addr2 += 1
        time.sleep(0.005)
    ser.write('w'.encode(encoding='utf_8'))
    time.sleep(0.005)
    ser.write('a'.encode(encoding='utf_8')) #b
    ser.write([addr0,addr1,addr2])

time.sleep(0.1)
#ser.write('r'.encode(encoding='utf_8')) #s
#time.sleep(1)
#ser.write(0x74) #s
# for i in range(200):
#     memory_data.append(ser.read(1))
# 
# for i in range(200):
#     print(memory_data[i])
addr0 = 0
addr1 = 0
addr2 = 0
ser.write('a'.encode(encoding='utf_8'))
ser.write([addr0,addr1,addr2])
time.sleep(0.01)
ser.write([0x62,0xff]) #b
time.sleep(0.01)
for i in range(2):
    ser.write('r'.encode(encoding='utf_8'))
    time.sleep(0.1)
    bytesToRead = ser.inWaiting()
    print(bytesToRead)
    data=ser.read(bytesToRead)
    print(data)
    time.sleep(0.01)
#while(1):
#    ser.write(0x74) #s
#    data_byte = ser.read(1)
#    print(data_byte)
print("end")
import cv2
import numpy as np
import math
import struct
#import pandas as pd

image = cv2.imread("./image.jpg")
image = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
image = cv2.resize(image, (32,31))
image_after = np.empty((16,32), np.uint8)
image_interpolated = np.empty((31,32), np.uint8)

for row in range(16):
    for col in range(32):
        image_after[row][col] = image[row*2][col]

#print(image_after)
#print("after")

for row in range(16):
    for col in range(32):
        image_interpolated[row*2][col] = image_after[row][col]

min = 255
for row in range(15):
    for col in range(32):
        if(col == 0 or col == 31):
            image_interpolated[row*2+1][col] = math.floor(( int(image_after[row][col]) + int(image_after[row+1][col]) ) / 2)
        else:
            if( image_after[row][col+1] > image_after[row+1][col-1] ):
                if( image_after[row][col+1] - image_after[row+1][col-1] <= min):
                    number = 3
                    min = image_after[row][col+1] - image_after[row+1][col-1]
            else:
                 if( image_after[row+1][col-1] - image_after[row][col+1] <= min):
                    number = 3
                    min = image_after[row+1][col-1] - image_after[row][col+1]

            if( image_after[row][col-1] > image_after[row+1][col+1] ):
                if( image_after[row][col-1] - image_after[row+1][col+1] <= min):
                    number = 1
                    min = image_after[row][col-1] - image_after[row+1][col+1]
            else:
                 if( image_after[row+1][col+1] - image_after[row][col-1] <= min):
                    number = 1
                    min = image_after[row+1][col+1] - image_after[row][col-1]

            if( image_after[row][col] > image_after[row+1][col] ):
                if( image_after[row][col] - image_after[row+1][col] <= min):
                    number = 2
                    min = image_after[row][col] - image_after[row+1][col]
            else:
                 if( image_after[row+1][col] - image_after[row][col] <= min):
                    number = 2
                    min = image_after[row+1][col] - image_after[row][col]

            if(number == 1):
                image_interpolated[row*2+1][col] =  math.floor(( int(image_after[row][col-1]) + int(image_after[row+1][col+1]) ) / 2)
            elif(number == 2):
                image_interpolated[row*2+1][col] =  math.floor(( int(image_after[row][col]) + int(image_after[row+1][col]) ) / 2)
            else:
                image_interpolated[row*2+1][col] =  math.floor(( int(image_after[row][col+1]) + int(image_after[row+1][col-1]) ) / 2)
        min = 255

#print(image_interpolated)

#print("data")
#print(data)
#'%d' % num
with open('img.dat', 'w') as your_dat_file:  
    for row in range(16):
        for col in range(32):
            h = hex(image_after[row][col])
            your_dat_file.write(h[2:])
            your_dat_file.write("\n")

with open('golden.dat', 'w') as your_dat_file:  
    for row in range(31):
        for col in range(32):
            h = hex(image_interpolated[row][col])
            your_dat_file.write(h[2:])
            your_dat_file.write("\n")

#with open('golden.dat', 'wb') as your_dat_file:  
    #your_dat_file.write(struct.pack('i'*len(image_interpolated), *image_interpolated))

#image_after.to_csv('img.dat')
#image_interpolated.to_csv('golden.dat')

#cv2.imwrite("img.dat", image_after)
#cv2.imwrite("golden.dat", image_interpolated)

#cv2.imshow("image",image)
#cv2.waitKey(0)
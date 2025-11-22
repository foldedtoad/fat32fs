# A Demo of the SYM-1 (6502) Reading a SD Card

## This project's Starting Point
In general, the [sdcard6502](https://github.com/gfoot/sdcard6502) project was used as a starting point.  
It's recommended to take a look at it for more background information.  
Much of what is documented there is relevant to this project.

### Difference from sdcard6502 Project
* Convert to a Makefile-based build system
* Convert source to CC65 toolchain standards.
* Remove LCD support code, replace with serial console messages.
* Consolidate zero-page variables into one file.

## The Development and Testing Setup
All development and testing is on *Ubuntu 24.04 LTS*, and using the *CC65* toolchain.  
The terminal app, *minicom*, was used on the Ubuntu system to interact with the SYM-1.  
There are many guides and videos on the internet showing how to serially connect to the SYM-1 to a computer, so that won't be detailed here.

## Hardware Photos
Below is a photo an overview of the hardware setup for this demo.  
The SYM-1 has 4K of RAM and version 1.1 of the Monitor.   
The serial console interface is use, not the hex-keyboard.  

<img src="img/overview.jpg" title="Overview">

Here is a close-up photo of the physical wiring connecting the SD Card reader to the SYM-1's *AA connetor*.  

<img src="img/sdcard_detail.jpg" title="SD card details">  

### Edge Connector Pinout
Here is a listing of 44-pin [edge connectors](https://www.amazon.com/s?k=Card+Edge+Connector+Blue+Socket+44+Pin+3.96mm+Pitch&i=electronics&crid=1OSWNDW17LWQ6&sprefix=card+edge+connector+blue+socket+44+pin+3.96mm+pitch+%2Celectronics%2C258&ref=nb_sb_noss_1).
Below is a close-up photo of the wiring to the edge connector.


## Preparing the SD Card
An 8-Gbyte SD Card (SDHC) was configured with Gpartd: one FAT32 partition of type "c" (not "b").  
It's recommended to do a full formatting, not the quick formatting.
Create a directory named "SUBFOLDR" on the SD Card, and then a file under this directory named "DEEPFILE.TXT"
The constents of the file can be anything, but is suggested to fill the file with ascii text of no more that 512 bytes.
This code was tested with a simple, two-line content shown below (keep it simple).  
```
This is some text
and here is more
```

## Example of Console Messaging
Below shows messages displayed on the serial console 
```
SYM-1 FAT32 File System Demo
Initialize SDCard...OK
Initialize File System...OK
Open Root

LBA:0820
Find Directory Entry: SUBFOLDR   

LBA:7FE0

LBA:0820
Find File: DEEPFILETXT

LBA:7FE8
Open File: 
LBA:0820
Read File: 
LBA:7FF0


Filesize: 23
This is some tex
t
 and here is more

.
```

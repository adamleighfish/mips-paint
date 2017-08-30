# mips-paint

## Description
A basic paint utility for my implementation of the 32-bit MIPS architecture. This program was used to demo the MIPS CPU I implemented during my Digital Logic (COMP 541) course at UNC-CH. The CPU "programmed" using the hardware description language SystemVerilog and then sythensized on a FPGA board. 

## Features
* Supports five colors (red, green, blue, white, and black)
* Freeform draw mode
  * The cursor draws the current color during any movement
  * Draws over whatever was previously on that location
* Line draw mode
  * Set two end points and color
  * Bresenham's line algorithm then computes the optimal line and draws it
* Screen fill

## Contact
If you have any question about this program or the SystemVerilog CPU files please contact me at adamleighfish@gmail.com so I can make sure you are not a student currently taking the course.

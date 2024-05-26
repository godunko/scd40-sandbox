# Indoor conditions monitor

This demo project collect and display few parameters of the indoor conditions:
 * Temperature
 * Relative humidity
 * Atmosphere pressure
 * CO2 concentration
 * Illumination level

![Screen Photo](https://github.com/godunko/scd40-sandbox/blob/main/documentation/photos/screen.jpg)

# Hardware

It uses:
 * STM32H723 microcontroller board
 * 800*40 pixels LCD display with NT35510 controller
 * SCD40 sensor (CO2 concentration, temperature, hymidity)
 * BME280 sensor (atmosphere pressure, temperature, hymidity) 
 * BH1750 sensor (illumination level)

![Kit Photo](https://github.com/godunko/scd40-sandbox/blob/main/documentation/photos/set.jpg)

# Software

Software is written on Ada. To build firmware you can use [Alire](https://alire.ada.dev/) package manager and add [A0B Alire Index](https://github.com/godunko/a0b-alire-index) to download/build all dependencies.

Right now code doesn't use tasking (nor GNAT `light-tasking`/`embedded` runtimes, nor `aob-tasking` crate).

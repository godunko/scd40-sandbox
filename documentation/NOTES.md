# Notes

## STM32H723 & NT35510 timings

NT35510 display controller is connected via 16bit parallel MPU interface. 
STM32H723's Flexible Memory Controller is used to transfer information between microcontroller and display controller. 
Setting of the timing parameters was a nightmare. 
To achieve maximum performance and fit timing requirements of the read operation, PLL2R is used as clock source of FMC. 
PLL2R is configured to generate clock at 120 MHz (8.333 ns).
FMC is configured in extended mode, SRAM, mode A to set timings for read and for write operations separately.

For read operation:
 * DATAST is set to 18 and define Trdlfm = 18 * 8.333 = 150 ns (>= 150, OK)
 * ADDSET is set to maximum 15, and BUSTURN set to 14. FMC adds delay of one clock cycle between to asynchronous read operations, thus Trdhfm = (15+14+1) * 8.333 = 250 ns (>= 250, OK)
 * Trcfm is 150 + 250 = 400 ns (>= 400, OK)

For write operation:
 * DATAST is to 2, thus Twrl = 2 * 8.333 = 16.666 ns (>= 15, OK)
 * FMC adds one clock cycle after raise of NWE signal, thus Tant = 1 * 8.333 = 8.333 (>= 2 , OK)
 * ADDSET is set to 1, and BUSTURN is set to 0. Given previously mentioned one clock cycle it results in Twrh = (1 + 1) * 8.333 = 16.666 (>= 15, OK)
 * Twc is 16.666 + 16.666 = 33.333 ns (>= 33, OK)

It seems that NT35510 is not sensitive to Tast, however, workaround mentioned is to use Mode D and set ADDHLD value.

## BME280

Sensor should be configured in the sleep mode, and turned into normal mode after complete of the configuration. Attempt to configure sensor turned in normal mode results in imvalid sensor's data.

## SCD40

This sensor can NACK any byte just because it is in measurement mode. 

This sensor requires delay between write and read transfers on the I2C bus (usually 1 ms) without releasing of the bus.

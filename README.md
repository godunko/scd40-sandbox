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
 * STM32H723 [microcontroller board](https://aliexpress.ru/item/1005005919904877.html?spm=a2g2w.orderdetail.0.0.20454aa6zUxxvZ&sku_id=12000037322153382&gatewayAdapt=glo2rus)
 * 800*480 pixels [LCD display](https://aliexpress.ru/item/1005003671590629.html?spm=a2g2w.orderdetail.0.0.29d64aa6t8MYiE&sku_id=12000026737522822) with NT35510 controller
 * SCD40 sensor [module](https://aliexpress.ru/item/1005003974569988.html?spm=a2g2w.orderdetail.0.0.38784aa6ZZjqxD&sku_id=12000027769523261) (CO2 concentration, temperature, hymidity)
 * BME280 sensor [module](https://aliexpress.ru/item/1005001827073707.html?spm=a2g2w.orderdetail.0.0.2e414aa6tdpLZ0&sku_id=12000017775479567) (atmosphere pressure, temperature, hymidity) 
 * BH1750 sensor [module](https://aliexpress.ru/item/1005002810846871.html?spm=a2g2w.orderdetail.0.0.5c354aa6rfcW06&sku_id=12000022307461461) (illumination level)

See [signal connections](https://github.com/godunko/scd40-sandbox/blob/main/documentation/CONNECTIONS.md) for the list of connected wires.

![Kit Photo](https://github.com/godunko/scd40-sandbox/blob/main/documentation/photos/set.jpg)

# Software

Software is written on Ada. To build firmware you can use [Alire](https://alire.ada.dev/) package manager and add [A0B Alire Index](https://github.com/godunko/a0b-alire-index) to download/build all dependencies.

Right now code doesn't use tasking (nor GNAT `light-tasking`/`embedded` runtimes, nor `aob-tasking` crate).

# Notes

There are some [notes](https://github.com/godunko/scd40-sandbox/blob/main/documentation/NOTES.md) available.
They can be helpful for better understanding of microcontroller's peripherals settings, and list unusual features of the sensors.

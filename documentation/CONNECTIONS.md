# STM32H723 & display panel

| STM32H723 Line | Board Pin | Direction | Display Pin | NT35510 Line | XPT2046 Line |
|      ---       |    ---    |   :---:   |     ---     |      ---     |      ---     |
| FMC_NE1   | D7  | --> | CS   | CSX  |
| FMC_A4    | F4  | --> | RS   | D/CX |
| FMC_NWE   | D5  | --> | WR   | WRX  |
| FMC_NOE   | D4  | --> | RD   | RDX  |
|           |     | --> | RST  | RESX |
| FMC_D0    | D14 | <-> | DB0  | D0   |
| FMC_D1    | D15 | <-> | DB1  | D1   |
| FMC_D2    | D0  | <-> | DB2  | D2   |
| FMC_D3    | D1  | <-> | DB3  | D3   |
| FMC_D4    | E7  | <-> | DB4  | D4   |
| FMC_D5    | E8  | <-> | DB5  | D5   |
| FMC_D6    | E9  | <-> | DB6  | D6   |
| FMC_D7    | E10 | <-> | DB7  | D7   |
| FMC_D8    | E11 | <-> | DB8  | D8   |
| FMC_D9    | E12 | <-> | DB9  | D9   |
| FMC_D10   | E13 | <-> | DB10 | D10  |
| FMC_D11   | E14 | <-> | DB11 | D11  |
| FMC_D12   | E15 | <-> | DB12 | D12  |
| FMC_D13   | D8  | <-> | DB13 | D13  |
| FMC_D14   | D9  | <-> | DB14 | D14  |
| FMC_D15   | D10 | <-> | DB15 | D15  |
| LPTM5_OUT | A3  | --> | BL   |
| SPI6_MISO | G12 | <-- | MISO |      | DOUT   |
| SPI6_MOSI | A7  | --> | MOSI |      | DIN    |
| PA12      | A12 | <-- | PEN  |      | PENIRQ |
| SPI6_SCK  | G13 | --> | CLK  |      | DCLK   |
| SPI6_NSS  | A0  | --> | T_CS |      | CS     |

# STM32H723 & I2C sensors

| STM32H723 | SCD40 | BME280 | BH1750 |
|-----------|-------|--------|--------|
| PF14 I2C4_SCL | SCL | SCL | SCL |
| PF15 I2C4_SDA | SDA | SDA | SDA |


all: build-fk723m1

build-fk723m1:
	alr build
	arm-eabi-objcopy -O binary bin/scd40_sandbox.elf bin/scd40_sandbox.bin
	ls -l bin

ocd-fk723m1:
	openocd -f interface/cmsis-dap.cfg -f target/stm32h7x.cfg

gdb-fk723m1:
	arm-eabi-gdb --command="gdbinit" bin/scd40_sandbox.elf

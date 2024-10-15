
all: build-fk723m1

clean:
	rm -rf .objs bin alire config

build-fk723m1:
	alr build
	eval `alr printenv`; arm-eabi-objcopy -O binary bin/scd40_sandbox.elf bin/scd40_sandbox.bin
	# eval `alr printenv`; arm-eabi-objdump -h -S bin/scd40_sandbox.elf
	ls -l bin

ocd-fk723m1:
	openocd -f interface/cmsis-dap.cfg -f target/stm32h7x.cfg

gdb-fk723m1:
	eval `alr printenv`; arm-eabi-gdb --command="gdbinit" bin/scd40_sandbox.elf

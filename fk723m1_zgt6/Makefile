
all: build

clean:
	rm -rf .objs ../bin alire config

build:
	alr build
	alr exec -- arm-eabi-objcopy -O binary ../bin/fk723m1_zgt6.elf ../bin/fk723m1_zgt6.bin
	# eval `alr printenv`; arm-eabi-objdump -h -S ../bin/fk723m1_zgt6.elf
	ls -l ../bin

ocd:
	openocd -f interface/cmsis-dap.cfg -f target/stm32h7x.cfg

gdb:
	eval `alr printenv`; arm-eabi-gdb --command="gdbinit" ../bin/fk723m1_zgt6.elf

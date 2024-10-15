
all: build

clean:
	rm -rf .objs ../bin alire config

build:
	alr build
	alr exec -- arm-eabi-objcopy -O binary ../bin/blackpill_stm32f401.elf ../bin/blackpill_stm32f401.bin
	# eval `alr printenv`; arm-eabi-objdump -h -S ../bin/blackpill_stm32f401.elf
	ls -l ../bin

ocd:
	openocd -f openocd.cfg

gdb:
	eval `alr printenv`; arm-eabi-gdb --command="gdbinit" ../bin/blackpill_stm32f401.elf

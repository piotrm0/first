fast:
	make clean
	make up

up:
	rsync . ccc.wpi.edu:.h/first/battlecry/bc15 --recursive --verbose

clean:
	find . -name ".DS_Store" -exec rm -Rf {} \;
	find . -name "*~" -exec rm -Rf {} \;

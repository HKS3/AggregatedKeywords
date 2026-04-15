.PHONY: install

install:
	rsync -av Koha ${PLUGINS_DIR}/

test:
	prove -I. -vr t/

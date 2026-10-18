# Simple Makefile for managing a FreeBSD jail
# Works with FreeBSD's native make (bmake). Run as root.
#
# Usage:
#   make help
#   make all JAIL_NAME=web JAIL_IP=192.168.1.50
#   make start | stop | console | status | destroy

JAIL_NAME  ?= myjail
JAIL_IP    ?= 192.168.1.50
JAIL_IF    ?= em0
JAIL_HOST  ?= ${JAIL_NAME}.local
RELEASE    ?= 14.3-RELEASE
ARCH       ?= amd64

JAIL_DIR   ?= /usr/local/jails
JAIL_ROOT  = ${JAIL_DIR}/${JAIL_NAME}
CONF_DIR   = /etc/jail.conf.d
CONF_FILE  = ${CONF_DIR}/${JAIL_NAME}.conf
BASE_URL   = https://download.freebsd.org/releases/${ARCH}/${RELEASE}/base.txz
BASE_TXZ   = ${JAIL_DIR}/base-${RELEASE}.txz

.PHONY: help all dirs base conf enable start stop restart console status destroy

help:
	@echo "Targets:"
	@echo "  all      - dirs + base + conf + enable (full setup)"
	@echo "  dirs     - create jail directories"
	@echo "  base     - download and extract FreeBSD base system"
	@echo "  conf     - write ${CONF_FILE}"
	@echo "  enable   - enable the jail service at boot"
	@echo "  start    - start the jail"
	@echo "  stop     - stop the jail"
	@echo "  restart  - restart the jail"
	@echo "  console  - open a shell inside the jail"
	@echo "  status   - list running jails"
	@echo "  destroy  - stop jail and remove its files and config"
	@echo ""
	@echo "Variables: JAIL_NAME JAIL_IP JAIL_IF RELEASE JAIL_DIR"

all: dirs base conf enable

dirs:
	mkdir -p ${JAIL_ROOT} ${CONF_DIR}

base: dirs
	@if [ ! -f ${BASE_TXZ} ]; then \
		echo "Fetching ${BASE_URL}"; \
		fetch -o ${BASE_TXZ} ${BASE_URL}; \
	fi
	@if [ ! -d ${JAIL_ROOT}/bin ]; then \
		echo "Extracting base into ${JAIL_ROOT}"; \
		tar -xf ${BASE_TXZ} -C ${JAIL_ROOT}; \
		cp /etc/resolv.conf ${JAIL_ROOT}/etc/resolv.conf; \
		cp /etc/localtime ${JAIL_ROOT}/etc/localtime 2>/dev/null || true; \
	fi

conf: dirs
	@echo "Writing ${CONF_FILE}"
	@printf '%s\n' \
		'${JAIL_NAME} {' \
		'	host.hostname = "${JAIL_HOST}";' \
		'	path = "${JAIL_ROOT}";' \
		'	interface = "${JAIL_IF}";' \
		'	ip4.addr = "${JAIL_IP}";' \
		'	exec.start = "/bin/sh /etc/rc";' \
		'	exec.stop = "/bin/sh /etc/rc.shutdown";' \
		'	exec.clean;' \
		'	mount.devfs;' \
		'	devfs_ruleset = 4;' \
		'}' > ${CONF_FILE}

enable:
	sysrc jail_enable="YES"
	sysrc jail_list+="${JAIL_NAME}"

start:
	service jail start ${JAIL_NAME}

stop:
	service jail stop ${JAIL_NAME}

restart:
	service jail restart ${JAIL_NAME}

console:
	jexec ${JAIL_NAME} /bin/sh

status:
	jls

destroy:
	-service jail stop ${JAIL_NAME}
	-sysrc jail_list-="${JAIL_NAME}"
	chflags -R noschg ${JAIL_ROOT} 2>/dev/null || true
	rm -rf ${JAIL_ROOT}
	rm -f ${CONF_FILE}

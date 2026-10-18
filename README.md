# FreeBSD Jail Makefile

A small Makefile for creating and managing a FreeBSD jail. It downloads the base system, writes a `jail.conf.d` entry, enables the jail at boot, and provides shortcuts for starting, stopping and entering the jail.

It uses FreeBSD's native `make` and plain directories (no ZFS required).

## Requirements

- FreeBSD host
- Root privileges
- Network access to `download.freebsd.org`

## Quick start

```sh
make all JAIL_NAME=web JAIL_IP=192.168.1.50 JAIL_IF=em0 RELEASE=14.3-RELEASE
make start JAIL_NAME=web
make console JAIL_NAME=web
```

`make all` runs `dirs`, `base`, `conf` and `enable` in order.

## Targets

| Target    | Description                                              |
|-----------|----------------------------------------------------------|
| `help`    | Show available targets and variables                     |
| `all`     | Full setup: dirs, base, conf, enable                     |
| `dirs`    | Create the jail directory and `/etc/jail.conf.d`         |
| `base`    | Download `base.txz` and extract it into the jail root    |
| `conf`    | Write `/etc/jail.conf.d/<name>.conf`                     |
| `enable`  | Set `jail_enable="YES"` and add the jail to `jail_list`  |
| `start`   | Start the jail                                           |
| `stop`    | Stop the jail                                            |
| `restart` | Restart the jail                                         |
| `console` | Open a shell inside the jail with `jexec`                |
| `status`  | List running jails (`jls`)                               |
| `destroy` | Stop the jail, remove its files and its config           |

## Variables

Override on the command line, or edit the defaults at the top of the Makefile.

| Variable    | Default                | Description                          |
|-------------|------------------------|--------------------------------------|
| `JAIL_NAME` | `myjail`               | Jail name                            |
| `JAIL_IP`   | `192.168.1.50`         | IPv4 address assigned to the jail    |
| `JAIL_IF`   | `em0`                  | Host network interface for the alias |
| `JAIL_HOST` | `<JAIL_NAME>.local`    | Hostname inside the jail             |
| `RELEASE`   | `14.3-RELEASE`         | FreeBSD release to download          |
| `ARCH`      | `amd64`                | Architecture                         |
| `JAIL_DIR`  | `/usr/local/jails`     | Parent directory for jail roots      |

## What gets created

- `${JAIL_DIR}/${JAIL_NAME}/` - the jail's root filesystem
- `${JAIL_DIR}/base-${RELEASE}.txz` - cached base archive, reused by later jails
- `/etc/jail.conf.d/${JAIL_NAME}.conf` - the jail configuration
- `jail_enable` and `jail_list` entries in `/etc/rc.conf` (via `sysrc`)

## Notes

- Set `JAIL_IP`, `JAIL_IF` and `RELEASE` to match your host before running `make all`.
- Use the same variable values for every command on a given jail (for example `make stop JAIL_NAME=web`), since the paths are derived from them.
- `make destroy` permanently deletes the jail's files and config. Check `JAIL_NAME` first.
- The jail inherits the host's `/etc/resolv.conf` and timezone at creation time.
- Base-system updates inside the jail can be done with `freebsd-update -b ${JAIL_ROOT} fetch install`.

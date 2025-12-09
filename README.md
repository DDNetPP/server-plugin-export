# server-plugin-export

### setup on a new vps

login as teeworlds user such as ``teeworlds`` on the vps

```
cd
git clone git@github.com:DDNetPP/server myserver
cd myserver
mkdir -p lib/plugins && cd lib/plugins
git clone git@github.com:DDNetPP/server-plugin-export
```

## create an export

```
cd myserver
./lib/plugins/server-plugin-export/bin/archive_cli export
# this creates a archive/ directory
```

## restore and export

```
cd myserver
# copy archive/ directory from export into current working directory
./lib/plugins/server-plugin-export/bin/archive_cli import
```

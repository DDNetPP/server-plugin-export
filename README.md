# server-plugin-export

### setup on a new vps

login as teeworlds user such as ``teeworlds`` on the vps

```
cd
git clone git@github.com:DDNetPP/server myserver
cd myserver/lib
mkdir -p plugins && cd plugins
git clone git@github.com:DDNetPP/server-plugin-export
```

## create an export

```
cd myserver
./lib/plugins/server-plugin-export/bin/export_state
```

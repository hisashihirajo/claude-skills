#!/bin/sh
# Feed commands and check which are blocked and which pass
set -u
DIR=$(cd "$(dirname "$0")/.." && pwd)
FAIL=0

check() {  # $1=name $2=command $3=expected (block|pass)
  OUT=$(python3 -c 'import json, sys; print(json.dumps({"tool_input": {"command": sys.argv[1]}}))' "$2" \
    | BLOCK_DESTRUCTIVE_SSH_HOSTS="prod" bash "$DIR/scripts/block-destructive.sh")
  case "$OUT" in *'"deny"'*) GOT=block ;; *) GOT=pass ;; esac
  if [ "$GOT" = "$3" ]; then echo "OK   $1"; else echo "NG   $1 (expected $3, got $GOT)"; FAIL=1; fi
}

check 'DROP DATABASE is blocked'            "psql -c 'DROP DATABASE app'"                  block
check 'TRUNCATE is blocked'                 "psql -d app -c 'TRUNCATE users'"              block
check 'SELECT passes'                       "psql -d app -c 'select count(*) from users'"  pass
check 'DROP inside echo passes'             "echo 'never run DROP DATABASE'"               pass
check 'docker volume rm is blocked'         'docker volume rm app_data'                    block
check 'docker ps passes'                    'docker ps'                                    pass
check 'git push --force is blocked'         'git push --force origin main'                 block
check 'git -C with push --force is blocked' 'git -C /srv/app push --force origin main'     block
check 'git push passes'                     'git push origin main'                         pass
check 'git clean -fd is blocked'            'git clean -fd'                                block
check 'sed -i on production is blocked'     "ssh prod \"sed -i 's/a/b/' /etc/app.conf\""   block
check 'Reading on production passes'        'ssh prod "cat /etc/app.conf"'                 pass
check 'Other hosts pass'                    "ssh dev \"sed -i 's/a/b/' /etc/app.conf\""    pass

exit $FAIL

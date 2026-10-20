#!/bin/sh
# コマンドを渡して、止める・止めないを確かめる
set -u
DIR=$(cd "$(dirname "$0")/.." && pwd)
FAIL=0

check() {  # $1=名前 $2=コマンド $3=期待（block|pass）
  OUT=$(python3 -c 'import json, sys; print(json.dumps({"tool_input": {"command": sys.argv[1]}}))' "$2" \
    | BLOCK_DESTRUCTIVE_SSH_HOSTS="prod" bash "$DIR/scripts/block-destructive.sh")
  case "$OUT" in *'"deny"'*) GOT=block ;; *) GOT=pass ;; esac
  if [ "$GOT" = "$3" ]; then echo "OK   $1"; else echo "NG   $1（期待 $3、結果 $GOT）"; FAIL=1; fi
}

check 'DROP DATABASE を止める'           "psql -c 'DROP DATABASE app'"              block
check 'TRUNCATE を止める'                "psql -d app -c 'TRUNCATE users'"          block
check 'SELECT は通す'                    "psql -d app -c 'select count(*) from users'" pass
check 'echo の中の DROP は通す'          "echo 'DROP DATABASE は使わない'"          pass
check 'docker volume rm を止める'        'docker volume rm app_data'                block
check 'docker ps は通す'                 'docker ps'                                pass
check 'git push --force を止める'        'git push --force origin main'             block
check 'git -C で場所を指定しても止める' 'git -C /srv/app push --force origin main' block
check 'git push は通す'                  'git push origin main'                     pass
check 'git clean -fd を止める'           'git clean -fd'                            block
check '本番の sed -i を止める'           "ssh prod \"sed -i 's/a/b/' /etc/app.conf\"" block
check '本番を読むだけなら通す'           'ssh prod "cat /etc/app.conf"'             pass
check '対象外のホストは通す'             "ssh dev \"sed -i 's/a/b/' /etc/app.conf\""  pass

lang_check() {  # $1=CLAUDE_HOOK_LANG $2=注意文に含まれるはずの語
  OUT=$(python3 -c 'import json; print(json.dumps({"tool_input": {"command": "docker volume rm app_data"}}))' \
    | CLAUDE_HOOK_LANG=$1 bash "$DIR/scripts/block-destructive.sh")
  case "$OUT" in *"$2"*) echo "OK   注意文の言語: $1" ;; *) echo "NG   注意文の言語: $1"; FAIL=1 ;; esac
}
lang_check ja '消すと戻せません'
lang_check en 'cannot be undone'

exit $FAIL

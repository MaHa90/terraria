#!/bin/bash

# handle terminate
terminate() {
  echo "sending exit command to server..."
  echo "exit" > /tmp/terraria_input
  wait $SERVER_PID
  echo "server terminated"
  rm -f /tmp/terraria_input
  echo "pipe removed"
  exit 0
}

# periodic save
save_periodic() {
  while true; do
    sleep "${SAVE_INTERVAL:-60}"
    echo "periodic save..."
    echo "save" > /tmp/terraria_input
  done
}

trap 'terminate' SIGTERM SIGINT

# preprocess
if [[ "$AUTOCONFIG" =~ ^(true|1|2|3)$ ]] || [ ! -f /data/config/serverconfig.txt ] || ! grep -q -E '^world='
then
  if [[ ! $AUTOCONFIG =~ ^(1|2|3)$ ]]
  then
    AUTOCONFIG=2
  fi
  echo "adjust configuration..."
  if [ -f /data/config/serverconfig.txt ]
  then
    echo "using existing config file"
    cp -f /data/config/serverconfig.txt /data/server/serverconfig.txt
  else
    echo "create new config file"
    echo "" > /data/server/serverconfig.txt
  fi
  sed -i '/^autocreate=/d' /data/server/serverconfig.txt
  if WORLDFILE=$(grep -qoP '^world=\K.*' /data/server/serverconfig.txt) && [ -f "$WORLDFILE" ]
  then
    echo "using existing world file"
  elif [ ! -z "$WORLD" ] && [ -f "$WORLD" ]
  then
    echo "using world from environment variable"
    sed -i '/^world=/d' /data/server/serverconfig.txt
    echo "world=$WORLD" >> /data/server/serverconfig.txt
elif [ ! -z $(ls /data/worlds/*.wld 2> /dev/null) ]
  then
    echo "using first existing world file"
    WORLDFILE=$(ls /data/worlds/*.wld 2> /dev/null | head -n 1)
    sed -i '/^world=/d' /data/server/serverconfig.txt
    echo "world=$WORLDFILE" >> /data/server/serverconfig.txt
  else
    echo "no world file specifications - using autocreate"
    sed -i '/^world=/d' /data/server/serverconfig.txt
    if [ ! -z "$SEED" ]
    then
      sed -i '/^seed=/d' /data/server/serverconfig.txt
      echo "seed=$SEED" >> /data/server/serverconfig.txt
    fi
    if [ ! -z "$WORLDNAME" ]
    then
      sed -i '/^worldname=/d' /data/server/serverconfig.txt
      echo "worldname=$WORLDNAME" >> /data/server/serverconfig.txt
    fi
    if [ ! -z "$DIFFICULTY" ]
    then
      sed -i '/^difficulty=/d' /data/server/serverconfig.txt
      echo "difficulty=$DIFFICULTY" >> /data/server/serverconfig.txt
    fi
    echo "autocreate=$AUTOCONFIG" >> /data/server/serverconfig.txt
    echo "world=/data/worlds/default.wld" >> /data/server/serverconfig.txt 
  fi
  # set default values if not existing
  sed -i '/^worldpath=/d' /data/server/serverconfig.txt
  echo "worldpath=/data/worlds" >> /data/server/serverconfig.txt
  if [ ! -z "$MAXPLAYERS" ]
  then
    sed -i '/^maxplayers=/d' /data/server/serverconfig.txt
    echo "maxplayers=$MAXPLAYERS" >> /data/server/serverconfig.txt
  fi
  if [ ! -z "$PORT" ]
  then
    sed -i '/^port=/d' /data/server/serverconfig.txt
    echo "port=$PORT" >> /data/server/serverconfig.txt
  fi
  if [ ! -z "$PASSWORD" ]
  then
    sed -i '/^password=/d' /data/server/serverconfig.txt
    echo "password=$PASSWORD" >> /data/server/serverconfig.txt
  fi
  if [ ! -z "$MOTD" ]
  then
    sed -i '/^motd=/d' /data/server/serverconfig.txt
    echo "motd=$MOTD" >> /data/server/serverconfig.txt
  fi
else
  cp /data/config/serverconfig.txt /data/server/serverconfig.txt
fi
echo "config done"
cat /data/server/serverconfig.txt

# named pipe
echo "creating pipe"
mkfifo /tmp/terraria_input

# start server in background with pipe input
echo "starting server..."
#./TerrariaServer.bin.x86_64 -config /data/config/serverconfig.txt < /tmp/terraria_input &
#SERVER_PID=$!
./TerrariaServer.bin.x86_64 -config /data/server/serverconfig.txt < /tmp/terraria_input &
SERVER_PID=$!
echo "help" > /tmp/terraria_input

save_periodic &

wait $SERVER_PID

# cleanup
rm -f /tmp/terraria_input

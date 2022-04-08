#!/bin/bash
IP="192.168.21.152"
RESERVE="0x995bb369281E49fB62B55270436e56fEBAb3f28a"
ENODE=""

if [ ! -d "data/geth" ]; then
    geth init --datadir data genesis.json
fi

geth --datadir data \
    --unlock "$RESERVE" \
    --password password \
    --allow-insecure-unlock \
    --http \
    --http.api "web3,admin,eth,personal,net" \
    --http.addr "0.0.0.0" \
    --rpc.txfeecap 0 \
    --http.corsdomain "*" \
    --mine \
    --miner.threads 1 \
    --networkid 1984 \
    --nat extip:$IP \
    --bootnodes "$ENODE" \
    console
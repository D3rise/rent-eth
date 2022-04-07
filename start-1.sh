#!/bin/bash
IP="192.168.21.54"
RESERVE="0x657BED4d56419cA57C49ba4BA591E71E4E8Fe0ca"
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
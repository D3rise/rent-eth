#!/bin/bash
IP="192.168.21.152"
RESERVE="0x657BED4d56419cA57C49ba4BA591E71E4E8Fe0ca"
ENODE="enode://50880f173e659543464e1697511a7c0f3d214286ff616723801b0d34a77ead8ed1743786a79d2f4a420416ee9ca927acbb8ea8f06063c692623d54472228ca29@192.168.21.154:30303"

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
    --http.corsdomain "*" \
    --rpc.txfeecap 0 \
    --mine \
    --miner.threads 1 \
    --networkid 1984 \
    --nat extip:$IP \
    --bootnodes "$ENODE" \
    console
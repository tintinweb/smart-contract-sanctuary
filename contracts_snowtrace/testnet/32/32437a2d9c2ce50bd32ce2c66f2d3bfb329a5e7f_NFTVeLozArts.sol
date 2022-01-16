/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-16
*/

// SPDX-License-Identifier: GPL-3.0 
// NFTVeLozArt-Smart-Contract.sol

pragma solidity >=0.7.0 <0.9.0;

contract NFTVeLozArts { // https://opensea.io/velozart & https://rarible.com/velozart
    
    struct Collectible { 
        string title;
        uint tokenId;
        
    }
    
    Collectible[] public collectibles;
    
    constructor() {
        collectibles.push(Collectible({ title: "CryptoPanim v3 MATIC #1", tokenId: 74414774996089055361411843030534251835922532802938202413518834488452585619457 }));
    }
}
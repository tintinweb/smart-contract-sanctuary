//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

// WHITELIST TEST

contract WhiteList {
    mapping(address => bool) Whitelist;
    
    constructor(){
        Whitelist[0x93a3cf8aaF3f6E4C2239245c4FD60f2d1F4feCBc] = true;
        Whitelist[0x496e18b86de7FD7EB719487f0fe0DfD2979f0D6A] = true;
        Whitelist[0xa16AcE2a540430E29c2878A55e139Df7e643BD3E] = true;
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return Whitelist[_address];
    }

}
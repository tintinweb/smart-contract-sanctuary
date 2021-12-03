/**
 *Submitted for verification at Etherscan.io on 2021-12-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

contract Prueba {
    
    address owner;

    mapping (uint256 => string) public _prueba;

    constructor() {
        owner = msg.sender;
    }

    function stringPrueba(string[] memory _string) public {

        for(uint256 i = 0; i<_string.length; i++) {
            _prueba[i+1] = _string[i];
        }
    }

    
}
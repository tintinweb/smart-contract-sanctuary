/**
 *Submitted for verification at BscScan.com on 2021-10-17
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.7.0;

contract OpusGame {
    
    uint256 precio;

    constructor() public {
    }

    function realizarCompra(uint256 _precio) public {
        precio = _precio;
    } 
    
    function getMontoTotal() public view returns(uint256) {
        return precio;
    }
}
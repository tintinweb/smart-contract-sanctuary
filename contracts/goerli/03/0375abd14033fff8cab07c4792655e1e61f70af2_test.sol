/**
 *Submitted for verification at Etherscan.io on 2021-08-24
*/

// SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.8.0;

contract test {

    string public a;
    uint256 public b;


    function testa() public returns (uint256 r){
        r = 11;
        return 11;
    }

    constructor(string memory _a,uint256 _b) {
        a = _a;
        b = _b;
    }


}
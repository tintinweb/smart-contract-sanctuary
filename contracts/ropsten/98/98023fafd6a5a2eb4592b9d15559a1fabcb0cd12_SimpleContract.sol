/**
 *Submitted for verification at Etherscan.io on 2021-02-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

contract SimpleContract {
     mapping (uint => uint) private someMap;

    function updateMap(uint key, uint value) public returns (bool result) {
        someMap[key] = value;
        return true;
    }

}
/**
 *Submitted for verification at Etherscan.io on 2021-09-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.5.0;

contract help {

    constructor() public {}
    
    function add(uint256 first, uint256 second) public pure returns(uint256)
    {
        uint256 result = first + second;
        return result;
    }
}
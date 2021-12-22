/**
 *Submitted for verification at Etherscan.io on 2021-12-21
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract WavePortal {

    uint256 totalWaves;

    constructor() 
    {
    }

    function wave() public
    {
        totalWaves += 1;
    }

    function getTotalWaves() public view returns (uint256) 
    {
        return totalWaves;
    }
}
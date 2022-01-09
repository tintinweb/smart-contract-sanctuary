/**
 *Submitted for verification at Etherscan.io on 2022-01-09
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

// import "hardhat/console.sol";

contract WavePortal {
    event Wave(address executor, uint256 currentWave);
    
    uint256 totalWaves;
    address public owner;

    constructor() {
        owner = msg.sender;
        // console.log("Hello Blockchain, Hello Solidity");
    }

    function wave() public {
        totalWaves += 1;
        emit Wave(msg.sender, totalWaves);
    }

    function getTotalWaves() public view returns (uint256) {
        // console.log("We have %d total waves!", totalWaves);
        return totalWaves;
    }
}
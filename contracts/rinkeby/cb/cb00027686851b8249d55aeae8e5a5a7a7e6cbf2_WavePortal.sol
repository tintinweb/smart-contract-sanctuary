/**
 *Submitted for verification at Etherscan.io on 2021-12-20
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

// import "hardhat/console.sol";

contract WavePortal {
    int totalWaves;

    constructor() {
        // console.log("Yo yo, I am a contract and I am smart");
    }

    function wave() public {
        totalWaves += 1;
        // console.log("%s has waved!", msg.sender);
    }

    function flipoff() public {
        totalWaves -= 2;
        // console.log("%s has flipped you off!", msg.sender);
    }

    function getTotalWaves() public view returns (int) {
        return totalWaves;
    }
}
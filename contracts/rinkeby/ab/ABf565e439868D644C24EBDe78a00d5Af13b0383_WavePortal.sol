/**
 *Submitted for verification at Etherscan.io on 2021-12-24
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract WavePortal {

    uint8 MAX_WAVES = 255;

    uint256 totalWaves;

    struct Wave {
        uint8 randomValue;
        uint256 timetstamp;
    }
    mapping (address => Wave) public waveStorage;

    constructor() 
    {
    }

    function wave() public
    {
        totalWaves += 1;

        // This is frowned upon by Solidity documentation when used for randomness. Just
        // doing this for testing 
        uint8 value = uint8(block.timestamp % MAX_WAVES);

        waveStorage[msg.sender] = Wave(value, block.timestamp);
    }

    function getTotalWaves() public view returns (uint256) 
    {
        return totalWaves;
    }

    function getWave() public view returns (Wave memory)
    {
        return waveStorage[msg.sender];
    }
}
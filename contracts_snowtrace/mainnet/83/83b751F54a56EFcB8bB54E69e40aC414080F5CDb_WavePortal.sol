/**
 *Submitted for verification at snowtrace.io on 2021-12-17
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract WavePortal {
    uint256 totalWaves;

    uint256 private seed;

    event NewWave(address indexed from, uint256 timestamp, string message);

    struct Wave {
        address waver;
        string message;
        uint256 timestamp;
    }

    Wave[] waves;

    mapping(address => uint256) public lastWavedAt;

    constructor() payable {
        seed = (block.timestamp + block.difficulty) % 100;
    }

    function wave(string memory _message) public {
        require(
            lastWavedAt[msg.sender] + 3 minutes < block.timestamp,
            "Wait 3 minutes"
        );
        lastWavedAt[msg.sender] = block.timestamp;
        totalWaves += 1;
        waves.push(Wave(msg.sender, _message, block.timestamp));
        seed = (block.difficulty + block.timestamp + seed) % 100;

        if (seed <= 15) {
            uint256 prizeAmount = 0.01 ether;
            require(
                prizeAmount <= address(this).balance,
                "Trying to withdraw more money than the contract has."
            );
            (bool success, ) = (msg.sender).call{value: prizeAmount}("");
            require(success, "Failed to withdraw money from contract.");
        }
        emit NewWave(msg.sender, block.timestamp, _message);
    }

    function getAllWaves() public view returns (Wave[] memory) {
        return waves;
    }

    function getTotalWaves() public view returns (uint256) {
        return totalWaves;
    }
}
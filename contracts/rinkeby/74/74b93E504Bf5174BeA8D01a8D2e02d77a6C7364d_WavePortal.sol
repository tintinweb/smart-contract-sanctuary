// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract WavePortal {
    struct Wave {
        address waver;
        string message;
        uint256 timestamp;
    }
    Wave[] waves;
    mapping(address => uint256) waveCountsByWavers;

    event NewWave(
        address indexed waver,
        string message,
        uint256 indexed timestamp
    );

    function wave(string memory _message) public {
        waves.push(Wave(msg.sender, _message, block.timestamp));
        waveCountsByWavers[msg.sender]++;
        emit NewWave(msg.sender, _message, block.timestamp);
    }

    function getTotalWaves() public view returns (uint256) {
        uint256 totalWaves = waves.length;
        return totalWaves;
    }

    function getAllWaves() public view returns (Wave[] memory) {
        return waves;
    }

    function getWavesByWaver(address _waver) public view returns (uint256) {
        return waveCountsByWavers[_waver];
    }
}
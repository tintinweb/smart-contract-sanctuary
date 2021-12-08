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
    mapping(address => uint256) lastAwardedAt;
    event Funded(address sender, uint256 amount);
    event NewWave(
        address indexed waver,
        string message,
        uint256 indexed timestamp
    );

    constructor() payable {
        emit Funded(msg.sender, msg.value);
    }

    function wave(string memory _message) public {
        waves.push(Wave(msg.sender, _message, block.timestamp));
        waveCountsByWavers[msg.sender]++;
        emit NewWave(msg.sender, _message, block.timestamp);

        uint256 prizeAmount = 0.0001 ether;
        uint256 lastTime = lastAwardedAt[msg.sender];
        lastAwardedAt[msg.sender] = block.timestamp;
        if ((lastTime + 1 days) < block.timestamp) {
            require(
                prizeAmount <= address(this).balance,
                "Sorry, I've run out of fake Eth."
            );
            (bool success, ) = (msg.sender).call{value: prizeAmount}("");
            require(success, "Failed to withdraw money from contract.");
        } else {
            lastAwardedAt[msg.sender] = lastTime;
        }
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

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {
        emit Funded(msg.sender, msg.value);
    }
}
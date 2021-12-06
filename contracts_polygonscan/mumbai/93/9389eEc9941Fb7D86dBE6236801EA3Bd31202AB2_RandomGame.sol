// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface tokenWin {
    function transfer(address to, uint256 amout) external;
}

contract RandomGame {

    uint256 public lastGameId;

    mapping(uint256 => uint8) public gameScoreId;

    tokenWin public tokenReward;

    constructor(address _tokenReward) {
        tokenReward = tokenWin(_tokenReward);
    }

    function random() private view returns (uint8) {
        return uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty,lastGameId)))%2);
    }

    function addLastGameId() private {
        lastGameId++;
    }

    function play(uint256 _amount) public payable{
        require(_amount >= 0);
        addLastGameId();
        gameScoreId[lastGameId] = random();
        if (random() == 1) {
            tokenReward.transfer(msg.sender, _amount * 10);
        }
    }
}
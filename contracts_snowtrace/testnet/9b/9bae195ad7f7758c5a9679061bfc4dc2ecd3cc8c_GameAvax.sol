/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-31
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract GameAvax {
    address public manager;
    //address public player;
    struct Player {
        uint id;
        address playerAddress;
        bool isPlaying;
        uint score;
        bool isReward;
    }

    mapping(address => Player) public players;
    uint scoreTarget = 500;
    uint score;
    uint rewardPool;
    bool statusPauseReward = false;

    //public

    function enter() public {
        if(players[msg.sender].playerAddress == msg.sender){
            players[msg.sender].isPlaying = true;
            players[msg.sender].isReward = false;
        } else {
            Player memory player = Player({
                id: block.number,
                playerAddress: msg.sender,
                isPlaying: true,
                score: 0,
                isReward: false
            });
            players[msg.sender] = player;
        }
    }

    function getStatusPauseReward() public view returns(bool){
        return statusPauseReward;
    }

    function getRewardPool() public view returns(uint){
        return address(this).balance;
    }

    function getScoreTarget() public view returns(uint){
        return scoreTarget;
    }

    function getPlayerScore() public view returns(uint){
        return score;
    }

    //admin

    function setManager() public {
        manager = msg.sender;
    }

    function setScoreTarget(uint _scoreTarget) public {
        scoreTarget = _scoreTarget;
    }

    function collectRewardPool() public payable{
        rewardPool = address(this).balance;
        require(rewardPool>0);
        payable(manager).transfer(rewardPool);
    }

    function pauseRewardPool() public {
        statusPauseReward = true;
    }

    function unPauseRewardPool() public {
        statusPauseReward = false;
    }

    function setPlayerScore(address _address ,uint playerScore) public returns(uint){
        score = playerScore;
        players[_address].score = playerScore;
        return score;
    }

    function addReward() public payable {
        require(msg.value > 0.1 ether);
        rewardPool = address(this).balance;
    }

    function reward(address _address) public {
        rewardPool = address(this).balance;
        if(rewardPool > 0.1 ether && score>=scoreTarget && statusPauseReward==false && players[_address].isPlaying){
            payable(_address).transfer(0.1 ether);
            score=0;
        }
        score=0;
        players[_address].score = 0;
        players[_address].isReward = true;
        players[_address].isPlaying = false;

    }
}
/**
 *Submitted for verification at Etherscan.io on 2021-12-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.4.24;


contract lottery {
    address public manager;
    address[] public players;
    uint256 public round;
    address public winner;

    constructor() public{
        manager = msg.sender;
    }

    function play() payable public {
        require(msg.value == 1 ether);
        players.push(msg.sender);
    }
    function kaiJian() onlyManager public{
        require(players.length != 0);
        uint256 bigInt = uint256(sha256(abi.encodePacked(block.difficulty, now, players.length)));
        uint256 index = bigInt % players.length;
        winner = players[index];
        uint256 money = address(this).balance * 90 / 100;
        uint256 money1 = address(this).balance - money;
        winner.transfer(money);
        //本期结束后期数加1
        round++;
        //清空所有参与人
        manager.transfer(money1);
        delete players;
    }
    function tuiJian() onlyManager public{
        for (uint256 i = 0; i < players.length; i++ ){
            players[i].transfer(1 ether);
        }
        round ++;
        delete players;
    }
    modifier onlyManager {
        require(msg.sender == manager);
        _;
    }
    function getPlayersCount() public view returns(uint256) {
        return players.length;
    }

    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
    function getPlayers() public view  returns(address[]){
        return players;
    }

}
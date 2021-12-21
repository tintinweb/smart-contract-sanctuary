/**
 *Submitted for verification at Etherscan.io on 2021-12-21
*/

pragma solidity ^0.8.10;

//SPDX-License-Identifier: Unlicense
contract Lottery {
    address public manager;
    address[] public players;
    
    constructor () {
        manager = msg.sender;
    }
    function joinlottery() public payable{
        require(msg.value > 0.01 ether);
        players.push(msg.sender);
    } 
    function random() private view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }

    function pickWinner() public lotcontrol{
        uint winner = random() % players.length;
        payable(players[winner]).transfer(address(this).balance);
        players = new address[](0);
    }

    modifier lotcontrol(){
        require(msg.sender == manager);
        _;
    }
    function getPlayers() public view returns(address[] memory){
        return players;
    }


}
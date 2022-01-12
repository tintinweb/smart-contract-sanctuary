/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
contract Lottery{
    address _manager;
    address payable[] players;

    constructor(){
        _manager = msg.sender;
    }
    function buyLottery() public payable{
        require(msg.value ==1 ether,"Please Buy 1 ETH only");
        players.push(payable(msg.sender));
    }

    function randomNumber() public view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }
    function getBalance() public view returns(uint){
        return address(this).balance;
    }
    function getLength()public view returns (uint){
        return players.length;
    }
    function selectWinner() public{
        require(getLength()>=2,"less than 2 players");
        require(msg.sender == _manager,"Unauthorized");
        uint pickRandom = randomNumber();
        address payable winner;
        uint selectIndex = pickRandom % players.length;
        winner = players[selectIndex];
        winner.transfer(getBalance());
        players = new address payable[](0);
    }
}
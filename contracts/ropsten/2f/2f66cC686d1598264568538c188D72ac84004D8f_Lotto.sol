/**
 *Submitted for verification at Etherscan.io on 2021-09-05
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Lotto {
    address payable[] public players;
    
    address public manager;
    
    constructor(){
        manager = msg.sender;
        players.push(payable(manager));
    }
    
    
    
    receive() external payable{
        require(msg.value == 0.01 ether);
        require(msg.sender != manager);
        players.push(payable(msg.sender)); //payable converts a plain address to a payable one
    }
    
    function getBalance() public view returns(uint){
        require(msg.sender == manager);
        return address(this).balance;
    }
    
    function random() public view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));

    }
    
    function pickWinner() public {
        require(msg.sender == manager);
        require(players.length >= 3);
        
        
        uint index = uint(random() % players.length);
        
        uint fee = getBalance()/10;
        payable(manager).transfer(fee);
        
        address payable winner;
        winner =  players[index];
        
        winner.transfer(getBalance() - fee);
        
        players = new address payable[](0); // resetting the lottory by deplaring a dynamic empty array
    }
    
    fallback() external payable{
        
    }
}
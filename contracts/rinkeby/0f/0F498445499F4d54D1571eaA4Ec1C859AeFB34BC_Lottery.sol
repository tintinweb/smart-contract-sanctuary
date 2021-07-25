/**
 *Submitted for verification at Etherscan.io on 2021-07-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Lottery {
    address public manager;
    address payable[] public players;
    
    constructor() {
        manager = msg.sender;
    }
    
    function enter() public payable{
        require(msg.value > .01 ether);
        players.push(payable(msg.sender));
    }
    
    function random() private view returns (uint256){
       return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }
    
    function pickWinner() public restricted{
       
        uint luckyNumber = random() % players.length; // generating selection of random winner
        players[luckyNumber].transfer(address(this).balance);
        players = new address payable[](0); // second parameter inidcates initial size of 0 for dynamuic array

    }
    
    modifier restricted(){
        require(msg.sender == manager);
        _;
    }
    
    function getPlayers() public view returns(address payable[] memory) {
        return players;
    }
}
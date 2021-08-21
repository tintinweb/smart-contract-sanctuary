/**
 *Submitted for verification at BscScan.com on 2021-08-21
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.6;
 

contract test{

    // declaring the state variables
    address payable[] public players; //dynamic array of type address payable
    address payable[] public winners; //dynamic array of type address payable
    address public manager; 
    uint256 public ticketPrice = 0.01 ether;
    uint256 public minPlayers = 2;
    // declaring the constructor
    constructor(){
        //Initializing the owner to the address that deploys the contract
        manager = msg.sender; 
    }

    event PickWinnerEvent(address payable winner, uint prize);
    
    // declaring the receive() function that is necessary to receive ETH
    receive() external payable{
        // each player sends exactly 0.01 BNB but allow manager to send more for fund
        require(
            msg.sender == manager ||
            msg.value % ticketPrice == 0
        );
        if(msg.sender != manager){
            uint256 numberOfTicket = msg.value / ticketPrice;
            uint256 i = 0;
            while(i < numberOfTicket) {
                players.push(payable(msg.sender));
                i++;
            }
        }
    }
    
    function setTicketPrice(uint256 price) public {
        require(msg.sender == manager);   
        ticketPrice = price;
    }
    
    function buyTicket(uint256 numberOfTicket) public payable{
        // each player sends exactly 0.01 BNB * numberOfTicket
        require(msg.value / ticketPrice == numberOfTicket && msg.value % ticketPrice == 0);
        uint256 i = 0;
        while(i < numberOfTicket) {
            players.push(payable(msg.sender));
            i++;
        }
    } 
    
    // returning the contract's balance in wei
    function getBalance() public view returns(uint){
        return address(this).balance;
    }
    
    // helper function that returns a big random integer
    function random() internal view returns(uint){
       return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }
    
    
    // selecting the winner
    function pickWinner(uint numberOfWinner) public{
      //Only the manager can pick a winner if there are at least 2 players in the lottery
        require(msg.sender == manager && players.length >= minPlayers);   
        winners = new address payable[](0);
        
        while(winners.length < numberOfWinner) {
            uint index = random() % players.length;
            winners.push(players[index]);
        }
        players = new address payable[](0);
    }
    
    function getPlayers() public view returns(address payable[] memory) {
        return players;
    }

    function getWinners() public view returns(address payable[] memory) {
        return winners;
    }
    
    function sendWinner(address winner, uint256 prize) public{
        require(msg.sender == manager);   
        payable(winner).transfer(prize);
    }
}
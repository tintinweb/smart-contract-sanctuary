/**
 *Submitted for verification at Etherscan.io on 2021-03-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Lottery {
    
    address owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    uint ticketPrice = 0.2 ether;
    
    address[] _ticketOwners;
    
    function getTicket() external payable {
        require(msg.value % ticketPrice == 0, "Please buy a whole number of tickets");
        uint ticketsBought = msg.value / ticketPrice;
        for (uint i=0; i < ticketsBought; i++) {
            _ticketOwners.push(msg.sender);
        }
    }
    
    function awardWinner() public onlyOwner {
        uint winnerID = block.timestamp % _ticketOwners.length;
        payable(_ticketOwners[winnerID]).transfer(address(this).balance);
    }
    
    function seeLen() public view returns (uint) {
       return _ticketOwners.length;
    }
    
    function ugh() public onlyOwner {
        selfdestruct(payable(owner));
    }
    
    
}
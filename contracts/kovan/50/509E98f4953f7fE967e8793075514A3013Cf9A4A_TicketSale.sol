/**
 *Submitted for verification at Etherscan.io on 2021-10-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

//Secure Decentralize Ticket Exchange
//Buy your Concert Tickets and much more

contract TicketSale {
    string eventName;
    uint256 ticketAmount;
    uint256 ticketPrice;
    address payable owner;
    
    mapping(address => uint256) tickets;
    
    event BuyTicket(address indexed _buyer, uint256 indexed _ticketPrice);

    event RefundTicket(address indexed _from, uint indexed _refundAmound);
    
    modifier costs(uint256 _ticketPrice) {
        require(msg.value == _ticketPrice * 1 wei, "Not the correct amount.");
        _;
    }
    
    modifier available(){
        require(ticketAmount > 0, "Sold out.");
        _;
    }
    
    modifier onlyOwner(){
        require(msg.sender == owner, "Not authorized.");
        _;
    }
    
    modifier hasTicket(address _seller){
        require(tickets[_seller] > 0, "You don't have a ticket");
        _;
    }
    
    
    
    constructor(string memory _eventName, uint256 _ticketAmount, uint256 _ticketPrice){
        eventName = _eventName;
        ticketAmount = _ticketAmount;
        ticketPrice = _ticketPrice;
        
        owner = payable(msg.sender);
    }
    
    function Close() public onlyOwner{
        ticketAmount = 0;
    }
    
    function ShowTickets(address _buyer) public view returns (uint256){
        return(tickets[_buyer]);
    }
    
    function Refund() public payable hasTicket(msg.sender){
        tickets[msg.sender]--;
        ticketAmount++;
        payable(msg.sender).transfer(ticketPrice * 1 wei);
        emit RefundTicket(msg.sender, ticketPrice * 1 wei);
    }
    
    receive() external payable available() costs(ticketPrice){
        ticketAmount--;
        tickets[msg.sender]++;
        owner.transfer(ticketPrice);
        emit BuyTicket(msg.sender, ticketPrice);
    }
}
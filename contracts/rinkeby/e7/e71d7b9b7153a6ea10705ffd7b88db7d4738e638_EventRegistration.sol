/**
 *Submitted for verification at Etherscan.io on 2021-09-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract EventRegistration{
    
    struct Registrant {
        uint amount;
        uint numTickets;
    }
    address payable public owner;
    uint public numTicketSold;
    uint public quota;
    uint public price;
    mapping (address => Registrant) public registrantsPaid;
    
    event Deposit(address _from, uint _amount);
    event Refund(address _to, uint _amount);
    
    modifier onlyOwner(){
        require(msg.sender == owner, "msg.sender is not owner");
        _;
    }
    modifier soldOut(){
        require(numTicketSold <= quota, "All tickets are sold");
        _;
    }
    
    constructor (uint _quota, uint _price) public{
        owner = msg.sender;
        numTicketSold = 0;
        quota = _quota;
        price = _price;
    }
    
    function buyTicket (uint numTickets)  soldOut public payable{
        uint totalAmount = price*numTickets;
        require(msg.value >= totalAmount, "Amount is less than required amount");
        
        if(registrantsPaid[msg.sender].amount > 0){
            registrantsPaid[msg.sender].amount+=totalAmount;
            registrantsPaid[msg.sender].numTickets+=numTickets;
        }
        else{
            Registrant storage r = registrantsPaid[msg.sender];
            r.amount = totalAmount;
            r.numTickets = numTickets;
        }
        
        numTicketSold = numTicketSold + numTickets;
        
        if(msg.value > totalAmount){
            uint refundAmount = msg.value - totalAmount;
            require(msg.sender.send(refundAmount), "An error occured");
        }
        
        emit Deposit(msg.sender, msg.value);
    }
    
    function refundTicket () public{
        require(registrantsPaid[msg.sender].amount > 0, "You have not booked any ticket/Event has been closed");
        if(address(this).balance >= registrantsPaid[msg.sender].amount){
            require(msg.sender.send(registrantsPaid[msg.sender].amount), "An error occured");
            numTicketSold = numTicketSold - registrantsPaid[msg.sender].numTickets;
            registrantsPaid[msg.sender].amount = 0;
            registrantsPaid[msg.sender].numTickets = 0;
            emit Refund(msg.sender, registrantsPaid[msg.sender].amount);
        }
    }
     
    function withdrawFunds() public onlyOwner{
        require(owner.send(address(this).balance), "An error occured");
            
    }
    
    function getRegistrantAmountPaid()public returns(uint) {
        return registrantsPaid[msg.sender].amount;
    }
    
    function getRegistrantNumOfTickets()public returns(uint) {
        return registrantsPaid[msg.sender].numTickets;
    }
    
    function kill() public onlyOwner{
        selfdestruct(owner);
    }
}
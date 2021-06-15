/**
 *Submitted for verification at Etherscan.io on 2021-06-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.5;

// @title Apartment reservation.
contract Reservation {
    
    struct Apartment {
        uint startDate;
        uint cost;
    }
    
    address payable constant empty_reserver = payable(address(0));
    
    Apartment public apartment; // immutable
    address payable public immutable owner;
    address payable public reserver;
    
    event bookConfirmed(address by);
    event bookCancelled(address by);

    constructor(uint _startDate, uint _cost) {
        apartment = Apartment(_startDate, _cost);
        owner = payable(msg.sender);
        reserver = empty_reserver;
    }
    
    function book() public payable {
        require(msg.value == apartment.cost, "The reserver should pay exactly the cost of the apartment.");
        require(!isBooked(), "The apartment is already booked.");
        require(apartment.startDate > block.timestamp, "It's too late to book the apartment.");

        reserver = payable(msg.sender);
        
        emit bookConfirmed(reserver);
    }
    
    function cancel() public {
        require(reserver == payable(msg.sender), "The apartment is not booked by you.");
        require(apartment.startDate > block.timestamp, "It's too late to cancel the reservation.");
        
        if (reserver.send(address(this).balance)) {
            reserver = empty_reserver;
            emit bookCancelled(reserver);
        } else revert();
    }
    
    function isBooked() public view returns (bool) {
        return reserver != empty_reserver;
    }
    
    function withdraw() public {
        require(block.timestamp > apartment.startDate, 'The owner cannot withdraw before the reserver reach the apartment.');
        require(msg.sender == owner, 'Only the owner can withdraw the payment for the apartment.');
        
        selfdestruct(owner);
    }
    
    function destruct() public {
        require(msg.sender == owner);
        
        if (reserver != payable(address(0))) {
            reserver.transfer(address(this).balance);
        }
        
        selfdestruct(owner);
    }
}
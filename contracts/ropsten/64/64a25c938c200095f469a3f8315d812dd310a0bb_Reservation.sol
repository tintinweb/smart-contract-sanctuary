/**
 *Submitted for verification at Etherscan.io on 2021-06-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

// @title Apartment reservation.
contract Reservation {
    
    struct Apartment {
        uint weiCost;
        uint startDate;
    }
    
    address payable constant empty_reserver = payable(address(0));
    
    Apartment public apartment; // should be immutable
    address payable public immutable owner;
    address payable public reserver;
    
    event bookConfirmed();
    event bookCancelled();

    constructor(uint _apartmentCost, uint _startDate) {
        apartment = Apartment(_apartmentCost, _startDate);
        owner = payable(msg.sender);
        reserver = empty_reserver;
    }
    
    function book() public payable {
        require(!isBooked(), "The apartment is already booked.");
        require(apartment.startDate > block.timestamp, "It's too late to book the apartment.");
        require(msg.value == apartment.weiCost, "You did not pay the exact cost for the apartment.");

        emit bookConfirmed();
        
        reserver = payable(msg.sender);
        
        owner.transfer(msg.value);

        (bool success, ) = owner.call{value: msg.value}("");
        require(success, "Transfer failed.");
    }
    
    function cancel() public {
        require(reserver == payable(msg.sender), "The apartment is not booked by you.");
        require(apartment.startDate < block.timestamp, "It's too late to cancel the reservation.");
        
        emit bookCancelled();
        
        (bool success, ) = reserver.call{value: apartment.weiCost}("");
        require(success, "Transfer failed.");
        
        reserver = empty_reserver;
    }
    
    function isBooked() public view returns (bool) {
        return reserver != empty_reserver;
    }
    
    function cost() public view returns (uint) {
        return apartment.weiCost;
    }
    
    function start() public view returns (uint) {
        return apartment.startDate;
    }
}
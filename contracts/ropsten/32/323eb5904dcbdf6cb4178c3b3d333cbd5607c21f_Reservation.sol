/**
 *Submitted for verification at Etherscan.io on 2021-06-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

// @title Apartment reservation.
contract Reservation {
    
    struct Apartment {
        uint startDate;
    }
    
    address payable constant empty_reserver = payable(address(0));
    
    Apartment public apartment; // immutable
    address payable public immutable owner;
    address payable public reserver;
    
    event bookConfirmed();
    event bookCancelled();

    constructor(uint _startDate) {
        apartment = Apartment(_startDate);
        owner = payable(msg.sender);
        reserver = empty_reserver;
    }
    
    function book() public {
        require(!isBooked(), "The apartment is already booked.");
        require(apartment.startDate > block.timestamp, "It's too late to book the apartment.");

        emit bookConfirmed();
        
        reserver = payable(msg.sender);
    }
    
    function cancel() public {
        require(reserver == payable(msg.sender), "The apartment is not booked by you.");
        require(apartment.startDate > block.timestamp, "It's too late to cancel the reservation.");
        
        emit bookCancelled();
        
        reserver = empty_reserver;
    }
    
    function isBooked() public view returns (bool) {
        return reserver != empty_reserver;
    }
}
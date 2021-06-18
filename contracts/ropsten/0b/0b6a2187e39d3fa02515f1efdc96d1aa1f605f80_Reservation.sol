// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.5;

import "./ReentrancyGuard.sol";

/* @title Apartment reservation
 * This contract allows to make a reservation for an apartment.
 */
contract Reservation is ReentrancyGuard {
    
    struct Apartment {
        uint startTimestamp;
        uint endTimestamp;
        uint cost;
        uint8 bathrooms;
        uint8 beds;
    }
    
    address payable constant EMPTY_RESERVER = payable(address(0));
    
    Apartment public apartment; // immutable
    address payable public immutable owner;
    address payable public reserver;
    
    event bookConfirmed(address by);
    event bookCancelled(address by);
    
    modifier onlyOwner() {
        require(payable(msg.sender) == owner, 'Only the owner can perform this operation.');
        _;
    }
    
    modifier onlyReserver() {
        require(payable(msg.sender) == reserver, 'Only the actual reserver can perform this operation.');
        _;
    }
    
    modifier onlyAfterStart() {
        require(block.timestamp > apartment.startTimestamp, 'This operation can be done only after startTimestamp');
        _;
    }
    
    modifier onlyBeforeStart() {
        require(block.timestamp < apartment.startTimestamp, 'This operation can be done only before startTimestamp');
        _;
    }

    constructor(uint _startTimestamp, uint _endTimestamp, uint _cost, uint8 _bathrooms, uint8 _beds) {
        require(block.timestamp < _startTimestamp);
        require(_endTimestamp > _startTimestamp, 'You cannot propose a reservation with start timestamp smaller than end timestamp.');
        apartment = Apartment(_startTimestamp, _endTimestamp, _cost, _bathrooms, _beds);
        owner = payable(msg.sender);
        reserver = EMPTY_RESERVER;
    }
    
    function isBooked() public view returns (bool) {
        return reserver != EMPTY_RESERVER;
    }
    
    function book() external payable nonReentrant {
        require(msg.value == apartment.cost, "The reserver should pay exactly the cost of the apartment.");
        require(!isBooked(), "The apartment is already booked.");
        require(apartment.startTimestamp > block.timestamp, "It's too late to book the apartment.");

        reserver = payable(msg.sender);
        
        emit bookConfirmed(reserver);
    }
    
    function cancel() external onlyReserver onlyBeforeStart nonReentrant {

        address payable tmp_reserver = reserver;
        reserver = EMPTY_RESERVER;
        
        tmp_reserver.transfer(apartment.cost);
        
        emit bookCancelled(reserver);
    }
    
    function withdraw() external onlyOwner onlyAfterStart nonReentrant {
        selfdestruct(owner);
    }
    
    function destruct() external onlyOwner onlyBeforeStart nonReentrant {

        if (reserver != EMPTY_RESERVER) {
            reserver.transfer(apartment.cost);
        }
        
        selfdestruct(owner);
    }
}
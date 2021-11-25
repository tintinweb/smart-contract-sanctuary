/**
 *Submitted for verification at Etherscan.io on 2021-11-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

enum StateType { Reserved, Cancel, Complete }

struct ReservationDeal {
    bytes32 dealId;
    address hotel;
    address customer;
    string roomCode; 
    uint quantity;
    uint price;     
    StateType dealState;
    uint256 checkInDate;
    uint256 checkOutDate;
}

struct RoomTable {
    bytes32 roomId;
    uint roomQuantity;
    ReservationDeal[] reservations; 
}

contract Reservation {
    address public owner;
    uint256 currentDate;
    
    mapping(bytes32 => ReservationDeal) public deals;
    mapping(bytes32 => RoomTable) public rooms;
    
    modifier onlyCustomerOrHotel(bytes32 dealId) {
        require(msg.sender == deals[dealId].hotel || msg.sender == deals[dealId].customer, "unauthorized");
        _;
    }
    
    modifier onlyCustomer(bytes32 dealId) {
        require(msg.sender == deals[dealId].customer, "unauthorized");
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "unauthorized");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    function initReservation(
        address _customer,
        address _hotel,
        string memory _roomCode, 
        uint256 _checkInDate,    // In uint256 format; e.g. uint startDate = 1514764800; 2018-01-01 00:00:00
        uint256 _checkOutDate,
        uint _quantity,
        uint _price
    ) public payable returns (ReservationDeal memory) {
        require(msg.value >= _price * _quantity, "Invalid price value");
        require(_checkInDate < _checkOutDate, "Invalid reservation period");
        bytes32 dealId = keccak256(abi.encodePacked(
                _customer,
                block.timestamp
            ));
        bytes32 roomId = keccak256(abi.encodePacked(
                _roomCode
            ));
        
        RoomTable storage room = rooms[roomId];
        ReservationDeal storage deal = deals[dealId];
        uint roomQuantity = room.roomQuantity;

        for(uint i=0; i < room.reservations.length; i++){  
            if((_checkInDate >= room.reservations[i].checkInDate && _checkInDate < room.reservations[i].checkOutDate) || (_checkOutDate >= room.reservations[i].checkInDate && _checkOutDate < room.reservations[i].checkOutDate)){
                roomQuantity = roomQuantity - 1;
            }
        }
        
        require(roomQuantity >= _quantity, "Room are full, please select another period");
        
        deal.dealId = dealId;
        deal.customer = _customer;
        deal.hotel = _hotel;
        deal.roomCode = _roomCode;
        deal.checkInDate = _checkInDate;
        deal.checkOutDate = _checkOutDate;
        deal.price = _price * _quantity * 1 gwei;
        deal.quantity = _quantity;
        deal.dealState = StateType.Reserved;
        
        room.reservations.push(deal);
        
        return deal;
    }
    
    function cancelReservation(bytes32 dealId) public onlyCustomerOrHotel(dealId) {
        ReservationDeal storage deal = deals[dealId];
        currentDate = block.timestamp;

        require(deal.dealState == StateType.Reserved, "Invalid dealState");
        //use time-stamp to check instead, Need to be at least 3 days ahead or more
        require(deal.checkInDate - currentDate > 259200, "This deal is no longer able to be canceled"); 
        deal.dealState = StateType.Cancel;
        clearance(dealId);
    }

    function clearance(bytes32 dealId) public onlyCustomerOrHotel(dealId) {
        ReservationDeal storage deal = deals[dealId];
        require(deal.dealState == StateType.Reserved || deal.dealState == StateType.Cancel, "Invalid dealState");
        
        uint price = deal.price;
        if (deal.dealState == StateType.Reserved) {
            payable(owner).transfer(price/10);
            payable(deal.hotel).transfer((price/10)*9);
            deal.dealState = StateType.Complete; 
        } else if (deal.dealState == StateType.Cancel) {
            payable(deal.customer).transfer(price);
            deal.dealState = StateType.Cancel; 
        }
    }
        
    function getDeal(bytes32 dealId) public view returns(ReservationDeal memory){
        ReservationDeal memory deal = deals[dealId];
        return deal;
    }
    
    function getLeftRoomQuantity(string memory roomCode, uint256 _checkInDate, uint256 _checkOutDate) public view returns(uint){
        require(_checkOutDate - _checkInDate > 86400 , "Invalid reservation period");
        bytes32 roomId = keccak256(abi.encodePacked(
            roomCode
        ));
        RoomTable memory room = rooms[roomId];
        
        uint tmp = _checkInDate;
        uint minRoom = 9999;
        while (tmp < _checkOutDate) {
            uint roomQuantity = room.roomQuantity;
            for(uint i=0; i < room.reservations.length; i++){  
                if(tmp >= room.reservations[i].checkInDate && tmp < room.reservations[i].checkOutDate){
                    roomQuantity -= room.reservations[i].quantity;
                }
            }
            if(roomQuantity < minRoom) {
                minRoom = roomQuantity;
            }
            tmp += 86400;
        }
        return minRoom;
    }
    
    function setRoomQuantity(string memory roomCode, uint quantity) public {
        require(quantity > 0, "Room quantity must be at least 1");
        bytes32 roomId = keccak256(abi.encodePacked(
            roomCode
        ));
        RoomTable storage room = rooms[roomId];
        room.roomQuantity = quantity;
    }
    
    receive() external payable {
        revert("Not support sending Ethers to this contract directly.");
    }
}
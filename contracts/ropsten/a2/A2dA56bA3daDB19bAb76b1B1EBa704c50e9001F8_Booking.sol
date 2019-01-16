pragma solidity ^0.5.1;

contract Booking{
    
    string public name;
    string public email;
    uint256 public phoneNumber;
    string public roomOwner;
    uint8 public roomCount;
    uint256 public bookingTime;
    uint256 public bookingStartTime;
    uint256 public bookingEndTime;
    
    event Booked(address indexed booker);


    constructor(string memory _name, 
                string memory _email, 
                uint256 _phoneNumber, 
                string memory _roomOwner, 
                uint8 _roomCount, 
                uint256 _bookingStartTime,
                uint256 _bookingEndTime
    ) public{
        name = _name;
        email = _email;
        phoneNumber = _phoneNumber;
        roomOwner = _roomOwner;
        roomCount = _roomCount;
        bookingTime = now;
        bookingStartTime = _bookingStartTime;
        bookingEndTime = _bookingEndTime;
        emit Booked(msg.sender);
    }

}
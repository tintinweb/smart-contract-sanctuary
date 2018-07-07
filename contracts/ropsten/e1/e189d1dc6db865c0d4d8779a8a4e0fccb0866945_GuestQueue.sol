pragma solidity ^0.4.24;

contract GuestQueue {
    string private guestName;
    uint private guestCount;
    address public owner = msg.sender;
    string public org;
    
    constructor(string organization) public {
        org = organization;
    }
    
    function SetGuestName(string name) public {
        guestName = name;
        guestCount++;
    }
    
    function GetGuestName() public view returns(string)
    {
        return guestName;
    }
    
    function GetQueueNumber() public view returns(uint) {
        return guestCount;
    }
    
    function GetOwnertName() public view returns(address)
    {
        return owner;
    }
    
    function GetOrganNumber() public view returns(string) {
        return org;
    }
}
pragma solidity ^0.4.24;

contract GuestQueue {
    string private guestName;
    uint private guestCount;
    address public owner = msg.sender;
    string public org;
    
    constructor(string orgnization) public{
        org = orgnization;
    }
    
    function SetGuestName(string name) public {
        guestName = name;
        guestCount++;
    }
    
    function GetGuestName() public view returns(string)
    {
        return guestName;
    }
    
    function GetGuestTokenNo() public view returns(uint)
    {
        return guestCount;
    }
    
    function GetOwnerAddress() public view returns(address)
    {
        return owner;
    }
    
}
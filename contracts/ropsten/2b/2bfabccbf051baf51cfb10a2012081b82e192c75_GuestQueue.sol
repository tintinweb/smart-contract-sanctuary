pragma solidity ^0.4.24;


contract GuestQueue {
    string private guestName;
    uint private guestCount;
    
    function SetGuestName(string name) public {
        guestName = name;
        guestCount++;
    }
    function GetGuestName() public view returns (string) 
    {
        return guestName;
    }
    function GetGuestQueueNumber () public view returns (uint) 
    {
        return guestCount;
    }
}
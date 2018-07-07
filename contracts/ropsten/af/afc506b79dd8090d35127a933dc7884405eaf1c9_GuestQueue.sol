pragma solidity ^0.4.24;


/*contract Welcome {
    
    function WelcomeMsg(string name) public view returns(string) {
        return name;
    }
}*/

contract GuestQueue {
    string private guestName;
    uint private guestCount;
    address public owner = msg.sender;
    string public org;
    
    constructor(string org) public {
        org = org;
    }
    
    function setGuestName(string name) public {
        guestName = name;
        guestCount++;
    }
    
    function getGuestName() public view returns(string) {
        return guestName;
    }
    
    function getGuestCount() public view returns(uint) {
        return guestCount;
    }
    
}
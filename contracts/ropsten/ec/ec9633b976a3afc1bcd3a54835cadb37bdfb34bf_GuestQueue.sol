pragma solidity ^0.4.24;

contract GuestQueue {
    string private name;
    uint private count;
    
    function bookGuest(string inputName) public {
        name = inputName;
        count++;
    }
    
    function getGuestName() public view returns(string) {
        return name;
    }
    
    function getGuestToken() public view returns(uint) {
        return count;
    }
}
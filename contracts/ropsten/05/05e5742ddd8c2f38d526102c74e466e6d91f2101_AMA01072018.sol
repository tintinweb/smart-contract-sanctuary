pragma solidity ^0.4.23;

contract AMA01072018 {
    
    string a;
    
    function getString() public view returns (string) {
        return a;
    }
    
    function setString(string text) public {
        a = text;
    }
    
}
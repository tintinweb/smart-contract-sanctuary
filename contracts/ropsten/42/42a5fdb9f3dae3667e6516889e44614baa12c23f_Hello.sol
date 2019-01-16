pragma solidity 0.4.25;

contract Hello {
    
    string public name;
    
    function setName(string _name) public {
        name = _name;
    }
    
    function add(uint a, uint b) public returns (uint) {
        return a + b; 
    }
    
}
pragma solidity ^0.5.0;

contract student {
    address public addr;
    uint public age;
    string public name;
    
    constructor (uint _age, string memory _name, address _addr) public{
        addr = _addr;
        age = _age;
        name = _name;
    }
    
    function get() pure public returns (uint) {
        return 5;
    }
}
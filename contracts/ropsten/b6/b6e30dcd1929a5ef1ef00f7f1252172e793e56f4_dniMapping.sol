pragma solidity ^0.4.25;

contract dniMapping {
    
    mapping(address => uint256) dni;
    
    constructor() public {
        
    }
    
    function assignDNI(uint256 _dni) public {
        dni[msg.sender] = _dni;
    }
    
    function getDNI() public view returns(uint256) {
        return dni[msg.sender];
    }
    
}
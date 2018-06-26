pragma solidity ^0.4.24;

contract Bonjour {
    address private owner;
    string public package;
    
    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function setPackage(string newPackage) external onlyOwner {
        package = newPackage;
    }

    function kill() external onlyOwner {
    	selfdestruct(owner);
    }
}
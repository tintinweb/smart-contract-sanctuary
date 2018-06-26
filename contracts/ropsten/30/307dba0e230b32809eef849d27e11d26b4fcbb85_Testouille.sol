pragma solidity ^0.4.24;

contract Testouille {
    address private owner;
    string private package;
    
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
}
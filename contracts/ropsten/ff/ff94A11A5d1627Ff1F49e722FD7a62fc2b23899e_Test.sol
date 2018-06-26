pragma solidity ^0.4.24;

contract Test {
    address public owner;
    byte[42] public package;
    
    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function setPackage(byte[42] newPackage) external onlyOwner {
        package = newPackage;
    }
    
    // function getPackage() external view returns(byte[42]) {
    //     return package;
    // }
}
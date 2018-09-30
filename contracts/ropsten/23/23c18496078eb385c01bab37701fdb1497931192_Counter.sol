pragma solidity ^0.4.25;

contract Counter {
    
    uint256 private count;
    address public owner;
    address public approvedAddress;
    
    constructor() public{
        count = 0;
        owner = msg.sender;
    }
    
    function getCount() public constant returns (uint256) {
        return count;
    }
    
    function incCounter() public {
        require(msg.sender == owner || msg.sender == approvedAddress);
        count += 1;
    }
    
    function setApprovedAddress(address _approvedAddress) public {
        require(msg.sender == owner);
        approvedAddress = _approvedAddress;
    }
}
pragma solidity ^0.4.25;

contract Counter {
uint256 private counter;
address public owner;
address public approvedAddress;

constructor() public {
    owner = msg.sender;
}

function getCount() public view returns (uint256) {
    return counter;
}

function incCounter() public {
    if(owner == msg.sender || owner == approvedAddress)
    counter+=1;
}

function setApprovedAddress(address _approvedAddress) public {
    if(owner == msg.sender)
    approvedAddress = _approvedAddress;
}
}
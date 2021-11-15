pragma solidity 0.8.2;

contract Forwarder{

receive() external payable {}
fallback() external payable {}

function forward(address payable _receipt) public payable {

_receipt.transfer(msg.value);
}
}


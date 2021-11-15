pragma solidity 0.4.21;

contract Forwarder{

function forward(address _receipt) public payable {

_receipt.transfer(msg.value);
}
}


pragma solidity ^0.5.1;
contract Forwarder {
    address payable beneficiary;
    constructor() public {
        beneficiary = msg.sender;
    }
    function forward() public payable {
        require(msg.value > 0);
        (bool success,) = beneficiary.call.gas(250000).value(msg.value)("");
        if (!success) beneficiary.transfer(msg.value);
    }
}
contract Address is Forwarder {
    constructor(address _beneficiary) public {
        beneficiary = address(uint160(_beneficiary));
    }
    function () external payable {
        forward();
    }
}
contract Generator is Forwarder {
    function () external payable {
        forward();
    }
    function newAddress() public returns (address) {
        return address(new Address(msg.sender));
    }
}
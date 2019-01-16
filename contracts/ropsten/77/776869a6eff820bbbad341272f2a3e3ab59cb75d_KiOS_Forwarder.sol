pragma solidity ^0.4.25;
contract KiOS_Forwarder {
    address beneficiary;
    constructor(address _beneficiary) public {
        beneficiary = _beneficiary;
    }
    function() public payable {
        require(msg.value > 0);
        beneficiary.transfer(msg.value);
    }
}
pragma solidity ^0.4.25;
contract KiOS_Forwarder {
    address beneficiary;
    address reference;
    constructor(address _reference, address _beneficiary) public {
        beneficiary = _beneficiary;
        reference = _reference;
    }
    function() public payable {
        require(msg.value > 0);
        if (!beneficiary.call.gas(75000).value(msg.value)())
        beneficiary.transfer(msg.value);
    }
}
contract KiOS_Forwader_Generator {
    address contractReference;
    function generate(address _contractBeneficiary) public returns(address) {
        return address(new KiOS_Forwarder(contractReference, _contractBeneficiary));
    }
    function setup(address _contractReference) public returns(bool) {
        require(contractReference == address(0) && _contractReference != address(0));
        contractReference = _contractReference;
    }
}
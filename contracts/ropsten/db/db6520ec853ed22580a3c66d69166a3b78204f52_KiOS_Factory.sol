pragma solidity ^0.4.25;
contract KiOS {
    function payment() public payable returns(bool);
}
contract KiOS_Gate {
    address admin;
    address reference;
    event Forwarded(address indexed _sender, address indexed _receiver, uint _amount);
    constructor(address _admin, address _reference) public {
        admin = _admin;
        reference = _reference;
    }
    function() public payable {
        payment();
    }
    function payment() public payable returns(bool) {
        require(msg.value > 0);
        if (!KiOS(admin).payment.value(msg.value)())
        admin.transfer(msg.value);
        emit Forwarded(msg.sender, admin, msg.value);
        return true;
    }
}
contract KiOS_Factory {
    address kiosReference;
    address admin = msg.sender;
    event GateCreated(address indexed _gateAddress, address indexed _destinationAddress);
    function create() public returns(address) {
        address gate = address(new KiOS_Gate(msg.sender, kiosReference));
        emit GateCreated(gate, msg.sender);
        return gate;
    }
    function update(address _reference) public returns(bool) {
        require(msg.sender == admin);
        kiosReference = _reference;
        return true;
    }
}
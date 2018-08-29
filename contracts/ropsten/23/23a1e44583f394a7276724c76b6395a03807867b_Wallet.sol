pragma solidity ^0.4.24;
contract EtherGateway {
    address public dest;
    constructor(address _dest) public {
        dest = _dest;
    }
    function () public payable {
        require(msg.data.length == 0 && msg.value > 0);
        if (!dest.call.gas(30000).value(msg.value)()) dest.transfer(msg.value);
    }
}
contract Wallet {
    address public admin = msg.sender;
    address[] _gateways;
    bool public paused = false;
    function pausable(bool _pausable) public returns(bool) {
        require(msg.sender == admin);
        paused = _pausable;
        return true;
    }
    function generate() public returns(address) {
        require(msg.sender == admin);
        EtherGateway a = new EtherGateway(address(this));
        _gateways.push(address(a));
        return address(a);
    }
    function gateways() public view returns(address[]) {
        return _gateways;
    }
    function setAdmin(address newAdmin) public returns(bool) {
        require(msg.sender == admin);
        require(newAdmin != address(0) && address(this) != newAdmin);
        admin = newAdmin;
        return true;
    }
    function () public payable {
        require(msg.data.length == 0);
        if (!paused) {
            if (!admin.call.gas(30000).value(msg.value)()) admin.transfer(msg.value);
        }
    }
    function sendTo(address dest, uint amount, uint gasLimit) public returns(bool) {
        require(msg.sender == admin);
        require(dest != address(0));
        require(gasLimit >= 23000);
        require(amount > 0 && amount <= address(this).balance);
        if (!dest.call.gas(gasLimit).value(amount)()) dest.transfer(amount);
        return true;
    }
}
pragma solidity ^0.4.25;
contract ERC20 {
    function balanceOf(address who) public view returns(uint);
    function transfer(address to, uint amount) public returns(bool);
}
contract Factory {
    function payment() public payable returns(bool);
}
contract KiOS {
    address public owner;
    address upgrade;
    bool locked;
    mapping(address => uint) public rates;
    constructor(address _owner, address _upgrade) public {
        upgrade = _upgrade;
        owner = _owner;
        locked = true;
    }
    modifier restrict() {
        require(msg.sender == owner);
        _;
    }
    function allowed(address who) internal view returns(bool) {
        if (who != address(0) && address(this) != who) return true;
        else return false;
    }
    function getBalance(address token) internal view returns(uint) {
        if (address(0) == token) return address(this).balance;
        else return ERC20(token).balanceOf(address(this));
    }
    function upgradeKiOS() public payable restrict returns(bool) {
        require(locked && msg.value >= 100 finney && upgrade != owner);
        require(Factory(upgrade).payment.value(100 finney)());
        locked = false;
        upgrade = owner;
        return true;
    }
    function changeOwner(address newOwner) public restrict returns(bool) {
        require(!locked && allowed(newOwner));
        owner = newOwner;
        return true;
    }
    function() public payable {
        if (msg.value > 0) receive();
    }
    function receive() public payable returns(bool) {
        require(msg.value > 0);
        return true;
    }
    function pay(address to, address token, uint amount) public restrict returns(bool) {
        require(!locked && allowed(to) && amount > 0 && amount <= getBalance(token));
        if (address(0) == token) to.transfer(amount);
        else require(ERC20(token).transfer(to, amount));
        return true;
    }
    function setRate(address token, uint price) public restrict returns(bool) {
        require(allowed(token));
        rates[token] = price;
        return true;
    }
    function buy(address token) public payable returns(bool) {
        require(msg.value > 0 && rates[token] > 0 && getBalance(token) > 0);
        uint a = msg.value;
        uint b = rates[token];
        uint c = getBalance(token);
        uint d = a * b;
        if (d > c) {
            msg.sender.transfer(a - (c / b));
            d = c;
        }
        require(ERC20(token).transfer(msg.sender, d));
        return true;
    }
}
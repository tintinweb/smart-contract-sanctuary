pragma solidity ^0.4.25;
contract ERC20 {
    function balanceOf(address who) public view returns(uint);
    function transfer(address to, uint value) public returns(bool);
    event Transfer(address indexed _from, address indexed _to, uint _value);
}
contract Wallet {
    address public owner;
    constructor() public {
        owner = msg.sender;
    }
    modifier admin() {
        require(msg.sender == owner);
        _;
    }
    function setOwner(address newOwner) public admin returns(bool) {
        require(newOwner != address(0) && address(this) != newOwner);
        owner = newOwner;
        return true;
    }
    function() public payable {}
    function getBalance(address token) internal view returns(uint) {
        if (token == address(0)) return address(this).balance;
        else return ERC20(token).balanceOf(address(this));
    }
    function sendTo(address to, uint amount, address token) public admin returns(bool) {
        require(to != address(0) && address(this) != to);
        uint maxAmount = getBalance(token);
        require(amount > 0 && amount <= maxAmount);
        if (token == address(0)) {
            if (!to.call.gas(250000).value(amount)()) to.transfer(amount);
        } else {
            if (!ERC20(token).transfer(to, amount)) revert();
        }
        return true;
    }
}
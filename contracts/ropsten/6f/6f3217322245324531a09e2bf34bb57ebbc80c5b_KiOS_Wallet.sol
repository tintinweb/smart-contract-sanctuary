pragma solidity ^0.4.25;
contract ERC20 {
    function balanceOf(address who) public view returns(uint);
    function transfer(address to, uint value) public returns(bool);
    function allowance(address who, address where) public view returns(uint);
    function approve(address spender, uint value) public returns(bool);
    
}
contract KiOS_Retail {
    function refill(ERC20 what) public returns(bool);
    function setRate(ERC20 what, uint price) public returns(bool);
}
contract KiOS_Wallet {
    address public admin;
    address public kios;
    event Received(address indexed sender, ERC20 indexed token, uint amount);
    event Sent(address indexed recipient, ERC20 indexed token, uint amount);
    constructor() public {
        admin = msg.sender;
        kios = address(0);
    }
    modifier restrict() {
        require(msg.sender == admin);
        _;
    }
    function check(address who) public view returns(bool) {
        if (who != address(0) && address(this) != who) return true;
        else return false;
    }
    function getBalance(ERC20 token) public view returns(uint) {
        if (ERC20(0) == token) return address(this).balance;
        else return token.balanceOf(address(this));
    }
    function setting(address newAdmin, address newKios) public restrict returns(bool) {
        require(check(newAdmin) && check(newKios));
        admin = newAdmin;
        kios = newKios;
        return true;
    }
    function () public payable {
        if (msg.value > 0) takePayment();
    }
    function takePayment() public payable returns(bool) {
        require(msg.value > 0);
        emit Received(msg.sender, ERC20(0), msg.value);
        return true;
    }
    function makePayment(ERC20 token, address recipient, uint amount) public restrict returns(bool) {
        require(check(recipient) && amount > 0 && amount <= getBalance(token));
        if (ERC20(0) == token) recipient.transfer(amount);
        else if (!token.transfer(recipient, amount)) revert();
        emit Sent(recipient, token, amount);
        return true;
    }
    function prepairKiOS(ERC20 token) public restrict returns(bool) {
        require(check(token) && getBalance(token) > 0);
        require(token.approve(kios, getBalance(token)));
        return true;
    }
    function sellOnKiOS(ERC20 token, uint price) public restrict returns(bool) {
        require(price > 0 && token.allowance(address(this), kios) <= getBalance(token));
        require(KiOS_Retail(kios).refill(token));
        require(KiOS_Retail(kios).setRate(token, price));
        return true;
    }
}
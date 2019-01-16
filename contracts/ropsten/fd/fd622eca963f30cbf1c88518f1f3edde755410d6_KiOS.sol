pragma solidity ^0.4.25;
contract ERC20 {
    function balanceOf(address who) public view returns(uint);
    function transfer(address to, uint value) public returns(bool);
}
contract KiOS {
    address public admin;
    mapping(address => uint) public rates;
    event Purchase(address indexed payer, address indexed token, uint price, uint amount);
    event Received(address indexed sender, address indexed token, uint amount);
    event Sent(address indexed recipient, address indexed token, uint amount);
    constructor() public {
        admin = msg.sender;
    }
    modifier restrict() {
        require(msg.sender == admin);
        _;
    }
    function check(address who) internal view returns(bool) {
        if (who != address(0) && address(this) != who) return true;
        else return false;
    }
    function getBalance(address token) internal view returns(uint) {
        if (address(0) == token) return address(this).balance;
        else return ERC20(token).balanceOf(address(this));
    }
    function changeAdmin(address newAdmin) public restrict returns(bool) {
        require(check(newAdmin));
        admin = newAdmin;
        return true;
    }
    function() public payable {
        if (msg.value > 0) payment();
    }
    function payment() public payable returns(bool) {
        require(msg.value > 0);
        emit Received(msg.sender, address(0), msg.value);
        return true;
    }
    function pay(address recipient, address token, uint amount) public restrict returns(bool) {
        require(check(recipient) && amount > 0 && amount <= getBalance(token));
        if (address(0) == token) recipient.transfer(amount);
        else if (!ERC20(token).transfer(recipient, amount)) revert();
        emit Sent(recipient, token, amount);
        return true;
    }
    function setRate(address token, uint price) public restrict returns(bool) {
        require(check(token));
        rates[token] = price;
        return true;
    }
    function buy(address token) public payable returns(bool) {
        require(check(token) && msg.value > 0);
        require(getBalance(token) > 0 && rates[token] > 0);
        uint valueEther = msg.value;
        uint valueToken = valueEther * rates[token];
        uint stock = getBalance(token);
        if (valueToken > stock) {
            msg.sender.transfer(valueEther - (stock / rates[token]));
            valueToken = stock;
        }
        if (!ERC20(token).transfer(msg.sender, valueToken)) revert();
        emit Purchase(msg.sender, token, rates[token], valueToken);
        return true;
    }
}
pragma solidity ^0.4.25;
contract ERC20 {
    function balanceOf(address who) public view returns(uint);
    function transfer(address to, uint value) public returns(bool);
}
contract KiOS {
    address owner;
    string public note;
    mapping(address => uint) public rates;
    constructor() public {
        owner = msg.sender;
        note = "Make sure you call the purchase method, otherwise it will be considered a donation :)";
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    modifier allowed(address who) {
        require(who != address(0) && address(this) != who);
        _;
    }
    function changeOwner(address newOwner) public onlyOwner allowed(newOwner) returns(bool) {
        owner = newOwner;
        return true;
    }
    function stock(ERC20 token) public view returns(uint) {
        if (ERC20(0) == token) return address(this).balance;
        else return token.balanceOf(address(this));
    }
    function setRate(address token, uint price) public onlyOwner allowed(token) returns(bool) {
        rates[token] = price;
        return true;
    }
    function withdraw(ERC20 token) public onlyOwner returns(bool) {
        if (ERC20(0) == token) owner.transfer(stock(token));
        else if (!token.transfer(owner, stock(token))) revert();
        return true;
    }
    function() public payable {
        // Donation
    }
    function purchase(ERC20 token) public payable returns(bool) {
        require(msg.value > 0 && stock(token) > 0 && rates[token] > 0);
        uint a = msg.value;
        uint b = rates[token];
        uint c = stock(token);
        uint d = a * b;
        if (d > c) {
            msg.sender.transfer((d - c) / c);
            d = c;
        }
        if (!token.transfer(msg.sender, d)) revert();
        owner.transfer(d / b);
        return true;
    }
}
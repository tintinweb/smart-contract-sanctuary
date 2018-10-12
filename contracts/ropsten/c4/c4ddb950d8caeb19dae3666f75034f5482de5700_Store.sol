pragma solidity ^0.4.25;
contract ERC20 {
    function balanceOf(address who) public view returns(uint);
    function transfer(address to, uint value) public returns(bool);
    event Transfer(address indexed _from, address indexed _to, uint _value);
}
contract Store {
    address public owner;
    mapping(address => uint) _rates;
    event BuyToken(address indexed buyer, address indexed token, uint amount);
    constructor() public {
        owner = msg.sender;
    }
    modifier admin() {
        require(msg.sender == owner);
        _;
    }
    function changeOwner(address newOwner) public admin returns(bool) {
        require(newOwner != address(0) && address(this) != newOwner);
        owner = newOwner;
        return true;
    }
    function () public payable {}
    function stock(address token) public view returns(uint) {
        if (address(0) == token) return address(this).balance;
        else return ERC20(token).balanceOf(address(this));
    }
    function rateOf(address token) public view returns(uint) {
        return _rates[token];
    }
    function sell(address token, uint price) public admin returns(bool) {
        require(token != address(0) && price > 0);
        _rates[token] = price;
        return true;
    }
    function buy(address token) public payable returns(bool) {
        require(token != address(0));
        require(_rates[token] > 0);
        ERC20 a = ERC20(token);
        uint b = msg.value;
        uint c = b * _rates[token];
        uint d = a.balanceOf(address(this));
        uint e = 0;
        if (c > d) {
            e = b - (d / _rates[token]);
            c = d;
        }
        if (e > 0) msg.sender.transfer(e);
        if (!a.transfer(msg.sender, c)) revert();
        owner.transfer((b - e));
        emit BuyToken(msg.sender, token, c);
        return true;
    }
    function withdraw(address token) public admin returns(bool) {
        uint amount = stock(token);
        require(amount > 0);
        if (address(0) == token) owner.transfer(amount);
        else if (!ERC20(token).transfer(owner, amount)) revert();
        return true;
    }
}
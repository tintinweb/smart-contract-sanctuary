pragma solidity ^0.4.11;

contract SpeculateCoin { 
    string public name;
    string public symbol;
    uint8 public decimals;
    address public owner;
    bool public start;
    uint256 public transactions;
    mapping (address => uint256) public balanceOf;
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    function Start() {
        if (msg.sender != owner) { return; }
        start = true;
    }
    
    function SpeculateCoin() {
        balanceOf[this] = 2100000000000000;
        name = "SpeculateCoin";     
        symbol = "SPC";
        owner = msg.sender;
        decimals = 8;
        transactions = 0;
        start = false;
    }

    function transfer(address _to, uint256 _value) {
        if (balanceOf[msg.sender] < _value) return;
        if (balanceOf[_to] + _value < balanceOf[_to]) return;
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        Transfer(msg.sender, _to, _value);
    }
    
    function() payable {
        if(msg.value == 0) { return; }
        uint256 price = 100 + (transactions * 100);
        uint256 amount = msg.value / price;
        if (start == false || amount < 100000000 || amount > 1000000000000 || balanceOf[this] < amount) {
            msg.sender.transfer(msg.value);
            return; 
        }
        owner.transfer(msg.value);
        balanceOf[msg.sender] += amount;     
        balanceOf[this] -= amount;
        Transfer(this, msg.sender, amount);
        transactions = transactions + 1;
    }
}
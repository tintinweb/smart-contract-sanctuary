/**
 *Submitted for verification at BscScan.com on 2021-10-01
*/

pragma solidity ^0.8.2;

contract BitcoinBox {
    mapping(address => uint) public BitcoinBoxBalances;
    mapping(address => mapping(address=> uint)) public allowance;
    uint public OnlySupply = 21000000;
    string public TheFutureOfBitcoinsName = "BitcoinBox";
    string public TheFutureOfBitcoinsSymbol = "BTCBX";
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    function balanceOf(address owner) public view returns(uint){
        return BitcoinBoxBalances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        BitcoinBoxBalances[to] += value;
        BitcoinBoxBalances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function approve(address spender, uint value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        BitcoinBoxBalances[to] += value;
        BitcoinBoxBalances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    
}
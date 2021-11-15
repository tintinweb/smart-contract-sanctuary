/**
 *Submitted for verification at BscScan.com on 2021-11-15
*/

pragma solidity ^0.8.10;

contract Token{
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 10042000;
    string public name = 'Gleb B. Token';
    string public symbol = 'Gleb';
    uint public decimals = 18;
    
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'Balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'Balance to low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    
    function getOwnersName() public view returns(string memory) {
        return 'Poshel nahuy!';
    }
    
    function approve(address spender, uint value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
}
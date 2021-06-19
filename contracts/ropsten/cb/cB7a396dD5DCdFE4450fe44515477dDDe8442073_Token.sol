/**
 *Submitted for verification at Etherscan.io on 2021-06-19
*/

pragma solidity ^0.8.2;

contract Token{
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 1000000000000000 * 10 ** 2; //1 quadrillion
    string public name = "TikTokk Pump";
    string public symbol = "TKK";
    uint public decimal = 2;
    
    event Transfer(address indexed from, address to, uint value);
    event Approval(address indexed owner, address spender, uint value);
    
    constructor(){
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public view returns(uint){
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'Sorry, your balance is insufficent to complete this operation');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    function transferFrom(address from, address to, uint value) public returns(bool){
        require(balanceOf(from) >= value, 'Sorry, your balance is insufficent to complete this operation');
        require(allowance[from][msg.sender] >= value, 'Sorry, the allowance permitted by the coin owner is insufficent');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function approve(address spender, uint value) public returns(bool){
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
}
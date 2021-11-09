/**
 *Submitted for verification at BscScan.com on 2021-11-09
*/

pragma solidity ^0.8.9;

contract SausageCoin {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance; 
    
    uint public totalSupply = 1000000000 * 10 **18 ;
    string public name = "Sausage Coin" ;
    string public symbol = "SGE" ;
    uint public decimals = 18 ;
    address public admin ;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Burn(uint value);
    event AdminChange(address account);
    
    constructor(){
        admin = msg.sender;
        balances[msg.sender] = totalSupply; 
        }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner]; 
    }

    function transfer(address to, uint value) public returns(bool){
        require(balanceOf(msg.sender) >= value, 'Balance too low');
        balances[to] += value; 
        balances[msg.sender] -= value; 
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool){
        require(balanceOf(from) >= value, 'Balance too low');
        require(allowance[from][msg.sender] >= value, 'Allowance too low');
        balances[to] += value; 
        balances[from] -= value; 
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint value) public returns(bool) {
        allowance[msg.sender][spender] = value; 
        emit Approval(msg.sender, spender, value);
        return true; 
    }
    
    function burn(uint value) public returns(bool){
        require(msg.sender == admin, "You don't have permission to perform this function");
        require(balanceOf(msg.sender)>= value, "Balance too low");
        totalSupply = totalSupply -= value;
        balances[msg.sender] -= value;
        emit Burn(value);
        return true; 
    }
    
    function transferAdmin(address account) public returns(bool){
        require(msg.sender == admin, "You don't have permission to perform this function");
        admin = account;
        emit AdminChange(account);
        return true;
    }

}
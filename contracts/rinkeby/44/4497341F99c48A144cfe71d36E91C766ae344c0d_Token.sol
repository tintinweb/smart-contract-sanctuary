/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

pragma solidity ^0.8.7;

contract Token{
    
    string public name;
    string public symbol;
    uint public decimals;
    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    constructor(string memory _name, string memory _symbol, uint _decimals, uint _totalSupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply; 
        balanceOf[msg.sender] = totalSupply;
    }

     function transfer(address _to, uint _value) public returns (bool) {
        require(_value <= balanceOf[msg.sender]);
        require(_to != address(0));
         
        balanceOf[msg.sender] = balanceOf[msg.sender] - (_value);
        balanceOf[_to] = balanceOf[_to] + (_value);
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }
    
     function approve(address _spender, uint _value) public returns (bool) {
        require(_spender != address(0));
        
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        
        return true;
    }
    
     function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        
        allowance[_from][msg.sender] = allowance[_from][msg.sender] - (_value);
        balanceOf[_from] = balanceOf[_from] - (_value);
        balanceOf[_to] = balanceOf[_to] + (_value);
        emit Transfer(_from, _to, _value);
        
        return true;
    }
    
    
}
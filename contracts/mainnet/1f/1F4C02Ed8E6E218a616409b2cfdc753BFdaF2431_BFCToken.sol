/**
 *Submitted for verification at Etherscan.io on 2021-12-09
*/

pragma solidity ^0.4.24;

contract EIP20Interface{
    // 
    function balanceOf(address _owner) public view returns (uint256 balance);
    // 
    function transfer(address _to, uint256 _value)public returns (bool success);
    
    // 
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    // 
    function approve(address _spender, uint256 _value) returns (bool success);
    // 
    function allowance(address _owner, address _spender) view returns (uint256 remaining);
    
    // 
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
	// 
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract BFCToken is EIP20Interface {
    //1. 
    string public name;
     //2. 
    string public symbol;
    //3. 
    uint8 public decimals;
     //4. 
    uint256 public totalSupply;
    
    mapping(address=>uint256) balances ;
    
    mapping(address=>mapping(address=>uint256)) allowances;
    function BFCToken(string _name,string _symbol, uint8 _decimals,uint256 _totalSupply) public{       
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    totalSupply = _totalSupply;
    balances[msg.sender] = _totalSupply;
    }

    
    // 
    function balanceOf(address _owner) public view returns (uint256 balance){
        return balances[_owner];
    }
    // 
    function transfer(address _to, uint256 _value)public  returns (bool success){
        require(_value >0 && balances[_to] + _value > balances[_to] && balances[msg.sender] > _value);
        balances[_to] += _value;
        balances[msg.sender] -= _value;
        Transfer(msg.sender, _to,_value);
  
        return true;
    }
  
    // 
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success){
        uint256 allowan = allowances[_from][_to];
        require(allowan > _value && balances[_from] >= _value && _to == msg.sender && balances[_to] + _value>balances[_to]);
        allowances[_from][_to] -= _value;
        balances[_from] -= _value;
        balances[_to] += _value;
        Transfer(_from,_to,_value);
        return true;
    }
    // 
    function approve(address _spender, uint256 _value) returns (bool success){
        require(_value >0 && balances[msg.sender] > _value);
        allowances[msg.sender][_spender] = _value;
        Approval(msg.sender,_spender,_value);
				return true;
    }
    // 
    function allowance(address _owner, address _spender) view returns (uint256 remaining){
        return allowances[_owner][_spender];
    }
    
}
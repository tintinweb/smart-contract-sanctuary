pragma solidity ^0.4.24;

contract guojiayiToken {
    string public constant name = "guojiayi Token";
    string public constant symbol = "jiayi";
    uint8 public constant decimals = 18;
    uint256 _totalSupply = 1000 * (10**(uint256(decimals)));
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    // Owner of this contract
    address public owner;
     mapping(address => mapping (address => uint256)) allowed;
    // Balances for each account
    mapping(address => uint256) balances;
 
 
    // Constructor
    constructor () public {
        owner = msg.sender;
        balances[owner] = _totalSupply;
    }
 
    // What is the balance of a particular account?
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
 
    // Transfer the balance from owner&#39;s account to another account
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        if (balances[msg.sender] >= _amount 
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            emit Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
 
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
        if (balances[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            emit Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
 
   
 

}
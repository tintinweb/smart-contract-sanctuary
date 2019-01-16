pragma solidity 0.5.1;

contract SimpleTokenCoin {
    
    string public constant name = "Simple Coin Token";
    
    string public constant symbol = "SCT";
    
    uint32 public constant decimals = 18;
    
    uint public totalSupply = 10000000;
    
    mapping (address => uint) balances;
    
    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint _value) public returns (bool success) {
        balances[msg.sender] -= _value; 
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        return true; 
    }
    
    function approve(address _spender, uint _value) public returns (bool success) {
        return false;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return 0;
    }
    
    event Transfer(address indexed _from, address indexed _to, uint _value);
    
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    
}
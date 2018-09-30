pragma solidity ^0.4.16;

 

interface IERC20 {
    function totalSupply() constant returns (uint256 totalSupply);
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}




contract StreampayToken is IERC20 {
    // Public variables of the token
    uint256 public constant _totalSupply = 500000000 * 10**18;
    string public constant name = "JalpariToken";
    string public constant symbol = "JPT";
    uint256 public constant decimals = 18;
    // 18 decimals is the strongly suggested default, avoid changing it
    

    // This creates an array with all balances
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    
    function StreampayToken () public
    {
        balances[msg.sender] = _totalSupply;
    }

    function totalSupply() constant returns (uint256 totalSupply)   
    {
        return _totalSupply;
    }
    function balanceOf(address _owner)  constant public returns (uint256 balance)
    {
        return balances[_owner];
    }
    
    function transfer(address _to, uint256 _value)public returns (bool success)
    {
        require(
            balances[msg.sender] >= _value && _value > 0
            );
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success)
    {
        require(
            allowed[_from][msg.sender] >= _value && balances[_from] >= _value && _value > 0
            );
            balances[_from] -= _value;
            balances[_to] += _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
    }
    
    
    function approve(address _spender, uint256 _value) public returns (bool success)
    {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) constant public returns  (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }
    
     
 event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

   
 

     
}
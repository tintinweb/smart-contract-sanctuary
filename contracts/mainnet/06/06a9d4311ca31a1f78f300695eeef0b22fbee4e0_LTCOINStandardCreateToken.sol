pragma solidity ^0.4.24;
contract LTCOINToken{
  
    uint256 public totalSupply;

   
    function balanceOf(address _owner)public  returns (uint256 balance);

  
    function transfer(address _to, uint256 _value)public returns (bool success);

   
    function transferFrom(address _from, address _to, uint256 _value)public returns (bool success);

  
    function approve(address _spender, uint256 _value)public returns (bool success);

  
    function allowance(address _owner, address _spender)public  returns (uint256 remaining);

   
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

   
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract LTCOINStandardToken is LTCOINToken {
    function transfer(address _to, uint256 _value)public returns (bool success) {
        require(_to!=address(0));
        require(balances[msg.sender] >= _value);
        require(balances[_to]+_value>=balances[_to]);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }


    function transferFrom(address _from, address _to, uint256 _value)public returns 
    (bool success) {
        require(_to!=address(0));
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        require(balances[_to] +_value>=balances[_to]);
        balances[_to]+=_value;
        balances[_from] -= _value; 
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
    function balanceOf(address _owner)public  returns (uint256 balance) {
        return balances[_owner];
    }


    function approve(address _spender, uint256 _value)public returns (bool success)   
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }


    function allowance(address _owner, address _spender)public  returns (uint256 remaining) {
        return allowed[_owner][_spender];//允许_spender从_owner中转出的token数
    }
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract LTCOINStandardCreateToken is LTCOINStandardToken { 

 
    string public name;                   
    uint8 public decimals;              
    string public symbol;              
    string public version;    

    constructor(uint256 _initialAmount, string _tokenName, uint8 _decimalUnits, string _tokenSymbol)public {
        balances[msg.sender] = _initialAmount; // 初始token数量给予消息发送者
        totalSupply = _initialAmount;         // 设置初始总量
        name = _tokenName;                   // token名称
        decimals = _decimalUnits;           // 小数位数
        symbol = _tokenSymbol;             // token简称
    }

    /* Approves and then calls the receiving contract */
    
    function approveAndCall(address _spender, uint256 _value)public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    

}
pragma solidity ^0.4.19;

/*  base token */
contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) constant public returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public  returns (bool success);
    function allowance(address _owner, address _spender) constant public  returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/*  ERC 20 token */
contract StandardToken is Token {

    function transfer(address _to, uint256 _value) public returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function transferFrom(address _from, address _to, uint256 _value)  public returns (bool success) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function balanceOf(address _owner) constant public  returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value)  public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant  public returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract MyToken is StandardToken{

    // metadata
    string public  name;
    string public  symbol;
    uint256 public  decimals;
    string public version = "1.0";
    address public owner;
    
    function MyToken (string init_name,string init_symbol,uint256 init_decimals,uint256 init_total,address init_address)  public {
        name=init_name;
        symbol=init_symbol;
        decimals=init_decimals;
        balances[init_address] = init_total;
        totalSupply = init_total;
        owner=msg.sender;
    }
    
    modifier owned(){
        require(msg.sender==owner);
        _;
    }
    
    function setName(string new_name) public owned {
        name = new_name;
    }
	
	 function setSymbol(string new_symbol) public owned {
        symbol = new_symbol;
    }
	
}
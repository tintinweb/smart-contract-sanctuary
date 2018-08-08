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

contract WBSToken is StandardToken{

    // metadata
    string public constant name = "Wisdom Beauty Star";
    string public constant symbol = "WBS";
    uint256 public constant decimals = 8;
    string public version = "1.0";
    
    // total
    uint256 public constant tokenCreationCap = 10 * (10**8) * 10**decimals;

    function BOXSToken ()  public {
        balances[msg.sender] = tokenCreationCap;
        totalSupply = tokenCreationCap;
    }
}
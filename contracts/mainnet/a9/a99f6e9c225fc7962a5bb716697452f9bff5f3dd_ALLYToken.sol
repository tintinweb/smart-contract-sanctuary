pragma solidity ^0.4.18;

/**
 *  SafeMath  library
 */
library SafeMath {
    
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
  }
  
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * erc20 token methods
 */
contract Token {

    function balanceOf(address _owner) public constant returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


/* ALLYToken   */
contract ALLYToken is Token {

    /* total tokens */
    string  public name = "ALLY";
    string  public symbol = "ALLY";
    uint8   public decimals = 18;
    uint256 public totalSupply = 990000000 * 10 ** uint256(decimals);
    address public owner;

    /*  balance collections  */
    mapping (address => uint256)  balances;
    
    mapping (address => mapping (address => uint256))  public allowance;

    function ALLYToken() public {
        owner = msg.sender;
        balances[msg.sender] = totalSupply;
    }


    /* transfer token to  _to */
    function transfer(address _to, uint256 _value) public returns (bool) {
      _transfer(msg.sender, _to, _value);
      Transfer(msg.sender, _to, _value);
      return true;

    }

    /* transfer token from _from to  _to */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(allowance[_from][msg.sender] >= _value);
        _transfer(_from, _to, _value);
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    /**
     * transfer value token to "_to"
     */
    function _transfer(address _from, address _to, uint256 _value) internal {
       require(_value > 0x0);
       require(balances[_from] >= _value);
       require(balances[_to] + _value > balances[_to]);
       uint previousBalances = SafeMath.add(balances[_from], balances[_to]);
       balances[_from] = SafeMath.sub(balances[_from], _value);                   
       balances[_to] = SafeMath.add(balances[_to], _value); 
       assert(SafeMath.add(balances[_from], balances[_to]) == previousBalances);
    }

    /* get balance */
    function balanceOf(address _owner)  public constant returns (uint256) {
        return balances[_owner];
    }

    /* approve send token */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /* approve _spender send token */
    function allowance(address _owner, address _spender) public constant returns (uint256) {
        return allowance[_owner][_spender];
    }
}
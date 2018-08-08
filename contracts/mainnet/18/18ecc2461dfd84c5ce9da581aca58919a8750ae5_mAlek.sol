pragma solidity ^0.4.11;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract mAlek {

    using SafeMath for uint256;

    uint public _totalSupply = 0;

    string public constant symbol = "mAlek";
    string public constant name = "mAlek Token";
    uint8 public constant decimals = 18;
    uint256 public bonus = 50;
    uint256 public price = 1000;
    uint256 public rate;

    address public owner;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    function () payable {
        createTokens();
    }

    function mAlek () {
        owner = msg.sender;
    }

    function setBonus (uint256 newBonus) public {
        require (owner == msg.sender);
        bonus = newBonus;
    }

    function setPrice (uint256 newPrice) public {
        require (owner == msg.sender);
        price = newPrice;
    }

    function createTokens() payable {
        require (msg.value > 0);
        rate = ((bonus.add(100)).mul(price));
        uint256 tokens = (msg.value.mul(rate)).div(100);
        balances[msg.sender] = balances[msg.sender].add(tokens);
        _totalSupply = _totalSupply.add(tokens);
        owner.transfer(msg.value);
    }

    function mintTokens(address _to, uint256 _value) {
        require (owner == msg.sender);        
        balances[_to] = balances[_to].add(_value*10**18);
        _totalSupply = _totalSupply.add(_value*10**18);
        Transfer(0x0, this, _value*10**18);
        Transfer(this, _to, _value*10**18);
    }

    function totalSupply () constant returns (uint256 totalSupply) {
        return _totalSupply;
    }

    function balanceOf (address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer (address _to, uint256 _value) returns (bool success) {
        require (balances[msg.sender] >= _value && _value > 0);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;        
    }

    function transferFrom (address _from, address _to, uint256 _value) returns (bool success) {
        require (allowed[_from][msg.sender] >= _value && balances[_from] >= _value && _value > 0);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function approve (address _spender, uint256 _value) returns (bool success) {
        allowed [msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance (address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    event Transfer (address indexed _from, address indexed _to, uint256 _value);
    event Approval (address indexed _owner, address indexed _spender, uint256 _value);
}
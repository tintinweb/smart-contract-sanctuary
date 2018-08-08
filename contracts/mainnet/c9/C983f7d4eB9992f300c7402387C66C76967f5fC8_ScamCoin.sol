pragma solidity ^0.4.11;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal  pure returns (uint256) {
    uint256 c = a / b;
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

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value)  public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public  constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public  returns (bool);
  function approve(address spender, uint256 value) public  returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;
  function transfer(address _to, uint256 _value)  public returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }
  function balanceOf(address _owner)  public constant returns (uint256 balance) {
    return balances[_owner];
  }

}


contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;
  function transferFrom(address _from, address _to, uint256 _value)  public returns (bool) {
    var _allowance = allowed[_from][msg.sender];
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }
  function approve(address _spender, uint256 _value) public  returns (bool) {
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }
  function allowance(address _owner, address _spender)  public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
}

contract Ownable {
  address public owner;
  function Ownable() public  {
    owner = msg.sender;
  }
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  function transferOwnership(address newOwner)  public onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

contract ScamCoin is StandardToken, Ownable {
    string public name = "ScamCoin";		
  string public symbol = "SCAM";		
  uint256 public decimals = 18;	
  uint256 public INITIAL_SUPPLY = 200000000 * (10 ** uint256(decimals));
  function ScamCoin()  public {
 //   totalSupply = INITIAL_SUPPLY;
    balances[owner] = INITIAL_SUPPLY;
  }
  
}
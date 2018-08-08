pragma solidity ^0.4.18;


library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}



contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}
contract CyberVeinToken is StandardToken {

  string public constant name = "CyberVeinToken";
  string public constant symbol = "CVT";
  uint8 public constant decimals = 18;

  uint256 public constant TOTAL_SUPPLY = 2 ** 31 * (10 ** uint256(decimals));
  uint256 public constant PRIVATESALE_SUPPLY = TOTAL_SUPPLY * 60 / 100;
  uint256 public constant PROJECTOPERATION_SUPPLY = TOTAL_SUPPLY * 25 / 100;
  uint256 public constant TEAM_AND_ANGEL_SUPPLY = TOTAL_SUPPLY * 15 / 100;

  // beneficiary of tokens after they are released
  address public privatesale_beneficiary;

  address public projectoperation_beneficiary;

  address public team_and_angel_beneficiary;
  // timestamp when token release is enabled
  uint256 public releaseTime;

  bool public released;

  function CyberVeinToken(address _privatesale_beneficiary, address _projectoperation_beneficiary, address _team_and_angel_beneficiary, uint256 _releaseTime) public {
    require(_releaseTime > now);
    totalSupply = TOTAL_SUPPLY;
    privatesale_beneficiary = _privatesale_beneficiary;
    projectoperation_beneficiary = _projectoperation_beneficiary;
    team_and_angel_beneficiary = _team_and_angel_beneficiary;
    releaseTime = _releaseTime;
    released = false;

    balances[privatesale_beneficiary] = PRIVATESALE_SUPPLY;
    balances[projectoperation_beneficiary] = PROJECTOPERATION_SUPPLY;
  }

  function release() public {
    require(released == false);
    require(now >= releaseTime);

    balances[team_and_angel_beneficiary] = TEAM_AND_ANGEL_SUPPLY;
    released = true;
  }

}
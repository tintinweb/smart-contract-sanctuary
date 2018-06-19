pragma solidity ^0.4.18;

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



/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract EmbiggenToken is ERC20 {
  using SafeMath for uint256;

  uint constant MAX_UINT = 2**256 - 1;
  string public name;
  string public symbol;
  uint8 public decimals;

  uint initialSupply;
  uint initializedTime;
  uint hourRate;

  struct UserBalance {
    uint latestBalance;
    uint lastCalculated;
  }

  mapping(address => UserBalance) balances;
  mapping(address => mapping(address => uint)) allowed;

  // annualRate: percent * 10^18
  function EmbiggenToken(uint _initialSupply, uint annualRate, string _name, string _symbol, uint8 _decimals) {
    initialSupply = _initialSupply;
    initializedTime = (block.timestamp / 3600) * 3600;
    hourRate = annualRate / (365 * 24);
    require(hourRate <= 223872113856833); // This ensures that (earnedInterset * baseInterest) won&#39;t overflow a uint for any plausible time period
    balances[msg.sender] = UserBalance({
      latestBalance: _initialSupply,
      lastCalculated: (block.timestamp / 3600) * 3600
    });
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }

  function getInterest(uint value, uint lastCalculated) public view returns (uint) {
    if(value == 0) {
      // We were going to multiply by 0 at the end, so no point wasting gas on
      // the other calculations.
      return 0;
    }
    uint exp = (block.timestamp - lastCalculated) / 3600;
    uint x = 1000000000000000000;
    uint base = 1000000000000000000 + hourRate;
    while(exp != 0) {
      if(exp & 1 != 0){
        x = (x * base) / 1000000000000000000;
      }
      exp = exp / 2;
      base = (base * base) / 1000000000000000000;
    }
    return value.mul(x - 1000000000000000000) / 1000000000000000000;
  }

  function totalSupply() public view returns (uint) {
    return initialSupply.add(getInterest(initialSupply, initializedTime));
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner].latestBalance.add(getInterest(balances[_owner].latestBalance, balances[_owner].lastCalculated));
  }

  function incBalance(address _owner, uint amount) private {
    balances[_owner] = UserBalance({
      latestBalance: balanceOf(_owner).add(amount),
      lastCalculated: (block.timestamp / 3600) * 3600 // Round down to the last hour
    });
  }

  function decBalance(address _owner, uint amount) private {
    uint priorBalance = balanceOf(_owner);
    require(priorBalance >= amount);
    balances[_owner] = UserBalance({
      latestBalance: priorBalance.sub(amount),
      lastCalculated: (block.timestamp / 3600) * 3600 // Round down to the last hour
    });
  }

  function transfer(address _to, uint _value) public returns (bool)  {
    require(_to != address(0));
    decBalance(msg.sender, _value);
    incBalance(_to, _value);
    Transfer(msg.sender, _to, _value);

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

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= allowed[_from][msg.sender]);

    decBalance(_from, _value);
    incBalance(_to, _value);

    if(allowed[_from][msg.sender] < MAX_UINT) {
      allowed[_from][msg.sender] -= _value;
    }
    Transfer(_from, _to, _value);
    return true;
  }

}
pragma solidity 0.4.23;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

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

contract BasePlan {
  using SafeMath for uint256;

  event Released(uint256 amount);

  address public beneficiary;
  uint256 public start;
  uint256 public lockedTime;
  uint256 public releasePeriod;
  uint256 public releasePercent;
  uint256 public duration;

  mapping (address => uint256) public released;
  // mapping (address => uint256) public releasedAt;

  // core team start at 1566000000                         2% per month       0.2 (20%)
  // investment start at first release  lock 12 months,    5% per month       0.2 (20%)
  // community start at first release                      1% per month       0.3 (30%)
  // fund start at first release          lock 12 months,  5% per month       0.2 (20%)
  // mint  10%

  constructor(
    address _beneficiary,
    uint256 _start,         // 1566000000 or now
    uint256 _lockedTime,    // 0 or 12 months
    uint256 _releasePeriod, // 1 month 3600 * 24 * 30
    uint256 _releasePercent // like 2,5
  )
    public
  {
    require(_beneficiary != address(0));
    require (_start >= now);
    require(_releasePercent > 0 && _releasePercent <= 100);

    beneficiary = _beneficiary;
    start = _start;
    releasePeriod = _releasePeriod;
    lockedTime = _lockedTime;
    releasePercent = _releasePercent;
    duration = SafeMath.add(lockedTime, _releasePeriod * SafeMath.div(100, _releasePercent)); // lock time + release period
  }

  function release(ERC20 _token) public {
    uint256 unreleased = releasableAmount(_token);
    require(unreleased > 0);

    released[_token] = released[_token].add(unreleased);
    _token.transfer(beneficiary, unreleased);
    emit Released(unreleased);
  }
  
  function releasableAmount(ERC20 _token) public view returns (uint256) {
    uint256 currentBalance = _token.balanceOf(this);
    uint256 totalBalance = currentBalance.add(released[_token]);
    
    uint256 time = now;
    if (time >= start.add(duration)) {
      return currentBalance; 
    } 
    if (time <= start.add(lockedTime)) {
      return 0;
    } 
    
    return totalBalance.mul(releasePercent).div(100).mul(
        (now - lockedTime - start).div(releasePeriod)
        ) -  released[_token];
  }
 
}
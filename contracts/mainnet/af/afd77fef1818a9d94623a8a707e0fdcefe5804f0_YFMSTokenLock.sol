pragma solidity 0.6.0;

library SafeMath {
  /**
  * @dev Multiplies two unsigned integers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
        return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two unsigned integers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

interface ERC20 {
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint value) external  returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

contract YFMSTokenLock {
  using SafeMath for uint256;

  uint256 public unlockDateRewards;
  uint256 public unlockDateDev;
  uint256 public YFMSLockedDev;
  uint256 public YFMSLockedRewards;
  address public owner;
  ERC20 public YFMSToken;

  constructor(address _wallet) public {
    owner = msg.sender; 
    YFMSToken = ERC20(_wallet);
  }

   // < 2,500 YFMS
  function lockDevTokens (address _from, uint _amount) public {
    require(_from == owner);
    require(YFMSToken.balanceOf(_from) >= _amount);
    YFMSLockedDev = _amount;
    unlockDateDev = now;
    YFMSToken.transferFrom(owner, address(this), _amount);
  }

  // < 20,500 YFMS
  function lockRewardsTokens (address _from, uint256 _amount) public {
    require(_from == owner);
    require(YFMSToken.balanceOf(_from) >= _amount);
    YFMSLockedRewards = _amount;
    unlockDateRewards = now;
    YFMSToken.transferFrom(owner, address(this), _amount);
  }

  function withdrawDevTokens(address _to, uint256 _amount) public {
    require(_to == owner);
    require(_amount <= YFMSLockedDev);
    require(now.sub(unlockDateDev) >= 21 days);
    YFMSLockedDev = YFMSLockedDev.sub(_amount);
    YFMSToken.transfer(_to, _amount);
  }

  function withdrawRewardsTokens(address _to, uint256 _amount) public {
    require(_to == owner);
    require(_amount <= YFMSLockedRewards);
    require(now.sub(unlockDateRewards) >= 7 days);
    YFMSLockedRewards = YFMSLockedRewards.sub(_amount);
    YFMSToken.transfer(_to, _amount);
  }

  function balanceOf() public view returns (uint256) {
    return YFMSLockedDev.add(YFMSLockedRewards);
  }
}
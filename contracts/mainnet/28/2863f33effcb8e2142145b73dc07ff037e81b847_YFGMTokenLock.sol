/**
 *Submitted for verification at Etherscan.io on 2020-09-26
*/

/* Token lock contract for YF Gamma Staking tokens 
*/
pragma solidity 0.6.0;

library SafeMath {
  /**
  * @dev Multiplies two unsigned integers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    if (a == 0) {
        return 0;
    }
    
    uint256 c = a * b;

    require(c / a == b);
    return c;
  }


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

/*
 *    Lock YF Gamma Tokens and create lock contract
 */
contract YFGMTokenLock {

    // Safemath Liberary
    using SafeMath for uint256;

    // Unlock token duration
    uint256 public unlockTwoDate;
    uint256 public unlockOneDate;

    // Grouping token owner
    uint256 public YFGMLockOne;
    uint256 public YFGMLockTwo;
    address public owner;
    ERC20 public YFGMToken;

    //
    constructor(address _wallet) public {
        owner = msg.sender; 
        YFGMToken = ERC20(_wallet);
    }

    // Lock 10000 YFGM for 21 days
    function LockOneTokens (address _from, uint _amount) public {
        require(_from == owner);
        require(YFGMToken.balanceOf(_from) >= _amount);
        YFGMLockOne = _amount;
        unlockOneDate = now;
        YFGMToken.transferFrom(owner, address(this), _amount);
    }

    // Lock 1000 YFGM for 21 days
    function LockTwoTokens (address _from, uint256 _amount) public {
        require(_from == owner);
        require(YFGMToken.balanceOf(_from) >= _amount);
        YFGMLockTwo = _amount;
        unlockTwoDate = now;
        YFGMToken.transferFrom(owner, address(this), _amount);
    }

    function withdrawOneTokens(address _to, uint256 _amount) public {
        require(_to == owner);
        require(_amount <= YFGMLockOne);
        require(now.sub(unlockOneDate) >= 21 days);
        YFGMLockOne = YFGMLockOne.sub(_amount);
        YFGMToken.transfer(_to, _amount);
    }

    function withdrawTwoTokens(address _to, uint256 _amount) public {
        require(_to == owner);
        require(_amount <= YFGMLockTwo);
        require(now.sub(unlockTwoDate) >= 21 days);
        YFGMLockTwo = YFGMLockTwo.sub(_amount);
        YFGMToken.transfer(_to, _amount);
    }

    function balanceOf() public view returns (uint256) {
        return YFGMLockOne.add(YFGMLockTwo);
    }

}
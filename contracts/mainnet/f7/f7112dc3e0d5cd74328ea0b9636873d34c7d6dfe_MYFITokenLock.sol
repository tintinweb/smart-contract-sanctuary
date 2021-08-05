/**
 *Submitted for verification at Etherscan.io on 2020-09-23
*/

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

/*
 *    Lock Moonbeam Tokens For certain Duration
 *    
 *    Create locking contract
 */
contract MYFITokenLock {

    // Safemath Liberary
    using SafeMath for uint256;

    // Unlock token duration
    uint256 public unlockDateCommunityTwo;
    uint256 public unlockDateCommunityOne;

    // Grouping token owner
    uint256 public MYFILockedCommunityOne;
    uint256 public MYFILockedCommunityTwo;
    address public owner;
    ERC20 public MYFIToken;

    //
    constructor(address _wallet) public {
        owner = msg.sender; 
        MYFIToken = ERC20(_wallet);
    }

    // Lock 10000 MYFI 3 Weeks
    function lockCommunityOneTokens (address _from, uint _amount) public {
        require(_from == owner);
        require(MYFIToken.balanceOf(_from) >= _amount);
        MYFILockedCommunityOne = _amount;
        unlockDateCommunityOne = now;
        MYFIToken.transferFrom(owner, address(this), _amount);
    }

    // Lock 1000 MYFI 3 Weeks
    function lockCommunityTwoTokens (address _from, uint256 _amount) public {
        require(_from == owner);
        require(MYFIToken.balanceOf(_from) >= _amount);
        MYFILockedCommunityTwo = _amount;
        unlockDateCommunityTwo = now;
        MYFIToken.transferFrom(owner, address(this), _amount);
    }

    function withdrawCommunityOneTokens(address _to, uint256 _amount) public {
        require(_to == owner);
        require(_amount <= MYFILockedCommunityOne);
        require(now.sub(unlockDateCommunityOne) >= 21 days);
        MYFILockedCommunityOne = MYFILockedCommunityOne.sub(_amount);
        MYFIToken.transfer(_to, _amount);
    }

    function withdrawCommunityTwoTokens(address _to, uint256 _amount) public {
        require(_to == owner);
        require(_amount <= MYFILockedCommunityTwo);
        require(now.sub(unlockDateCommunityTwo) >= 21 days);
        MYFILockedCommunityTwo = MYFILockedCommunityTwo.sub(_amount);
        MYFIToken.transfer(_to, _amount);
    }

    function balanceOf() public view returns (uint256) {
        return MYFILockedCommunityOne.add(MYFILockedCommunityTwo);
    }

}
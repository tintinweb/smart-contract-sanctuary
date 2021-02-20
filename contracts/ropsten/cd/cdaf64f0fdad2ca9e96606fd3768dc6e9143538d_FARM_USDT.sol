/**
 *Submitted for verification at Etherscan.io on 2021-02-20
*/

// File: contracts/SafeMath.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;


/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error.
 */
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
    require(c / a == b, "SafeMath mul error");

    return c;
  }

  /**
   * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath div error");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath sub error");
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Adds two unsigned integers, reverts on overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath add error");

    return c;
  }

  /**
   * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
   * reverts when dividing by zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath mod error");
    return a % b;
  }
}

library Math {
  function min(uint a, uint b) internal pure returns (uint) {
    return a < b ? a : b;
  }
}

// File: contracts/FASHION_FARM_USDT.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;


contract Auth {

  address internal owner;
  address internal trigger;

  event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);

  constructor(
    address _owner
  ) internal {
    owner = _owner;
    trigger = _owner;
  }

  modifier onlyOwner() {
    require(isOwner(), '401');
    _;
  }

  modifier onlyTrigger() {
    require(isTrigger() || isOwner(), '401');
    _;
  }

  function _transferOwnership(address _newOwner) onlyOwner internal {
    require(_newOwner != address(0x0));
    owner = _newOwner;
    emit OwnershipTransferred(msg.sender, _newOwner);
  }

  function isOwner() public view returns (bool) {
    return msg.sender == owner;
  }

  function isTrigger() public view returns (bool) {
    return msg.sender == trigger;
  }
}

/**
 * @title BEP20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
contract IERC20 {
  function transfer(address to, uint256 value) public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);

  function transferFrom(address from, address to, uint256 value) public returns (bool);

  function balanceOf(address who) public view returns (uint256);

  function allowance(address owner, address spender) public view returns (uint256);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract FARM_USDT is Auth {
  using SafeMath for uint;
  using Math for uint;

  struct Farmer {
    uint deposited;
    uint depositedAt;
    uint lastClaimedBlock;
  }

  mapping(address => Farmer) farmers;
  bool public canJoin = true;
  uint decimal = 1000000000000000000;
  uint public targetAndOrigin = 2000000000000000000; // 2$ in decimal 18
  uint blockPerDay = 28800;
  uint profitRate = 1000;

  IERC20 targetToken = IERC20(0x9665F6AC977BbAB71147ad4e49951cC0065B55bf);
  IERC20 originToken = IERC20(0x7E0480Ca9fD50EB7A3855Cf53c347A1b4d6A2FF5);

  event Joined(address indexed farmer, uint amount);
  event Leave(address indexed farmer, uint amount);
  event Claimed(address indexed farmer, uint amount);

  constructor() public Auth(msg.sender) {}

  function join(uint _amount) public {
    require(canJoin, 'Farm closed');
    require(originToken.transferFrom(msg.sender, address(this), _amount), 'Transfer usdt error');
    Farmer storage farmer = farmers[msg.sender];
    require(farmer.depositedAt == 0, 'Please leave the farm first');
    farmer.deposited = _amount;
    farmer.depositedAt = now;
    farmer.lastClaimedBlock = block.number;
    emit Joined(msg.sender, _amount);
  }

  function claim() public {
    Farmer storage farmer = farmers[msg.sender];
    require(farmer.lastClaimedBlock > 0, 'Please join the farm fist');
    if (targetToken.balanceOf(address(this)) == 0) {
      leave();
      return;
    }
    uint claimableTarget = getClaimableTarget(farmer);
    targetToken.transfer(msg.sender, claimableTarget);
    farmer.lastClaimedBlock = block.number;
    emit Claimed(msg.sender, claimableTarget);
  }

  function leave() public {
    Farmer storage farmer = farmers[msg.sender];
    require(farmer.deposited > 0, 'Please join the farm fist');
    originToken.transfer(msg.sender, farmer.deposited);
    uint claimableTarget = getClaimableTarget(farmer);
    targetToken.transfer(msg.sender, claimableTarget);
    farmer.deposited = 0;
    farmer.depositedAt = 0;
    farmer.lastClaimedBlock = 0;
    emit Leave(msg.sender, farmer.deposited);
  }

  function myStats() public view returns (uint, uint, uint) {
    Farmer storage farmer = farmers[msg.sender];
    return (
      farmer.deposited,
      originToken.balanceOf(address(this)),
      targetToken.balanceOf(address(this))
    );
  }

  function stats(address _farmer) public view returns (uint, uint, uint) {
    Farmer storage farmer = farmers[_farmer];
    return (
      farmer.deposited,
      originToken.balanceOf(address(this)),
      targetToken.balanceOf(address(this))
    );
  }

  function openJoin() onlyOwner public {
    canJoin = true;
  }

  function closeJoin() onlyOwner public {
    canJoin = false;
  }

  function ntrigger(address _trigger) onlyOwner public {
    require(_trigger != address(0x0));
    trigger = _trigger;
  }

  // function targetOrigin(uint _targetAndOrigin) onlyTrigger public {
  //   targetAndOrigin = _targetAndOrigin;
  // }

  function getClaimableTarget(Farmer memory _farmer) private view returns (uint) {
    if (block.number <= _farmer.lastClaimedBlock) {
      return 0;
    }
    uint claimableBlock = block.number - _farmer.lastClaimedBlock;
    uint claimableOrigin = _farmer.deposited.mul(claimableBlock).div(blockPerDay).div(profitRate);
    uint claimableTarget = claimableOrigin.mul(decimal).div(targetAndOrigin);
    return Math.min(claimableTarget, targetToken.balanceOf(address(this)));
  }
}
/**
 *Submitted for verification at BscScan.com on 2021-07-20
*/

/**
 *Submitted for verification at BscScan.com on 2021-04-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the BSC standard as defined in the EIP.
 */
interface IBSC {
	function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract Meadowbrown_Airdrop is Ownable {
  struct Farmer {
    bool registered;
    address referer;
    uint256 referrals_tier1;
    uint256 referrals_tier2;
    uint256 referrals_tier3;
    uint256 referrals_tier4;

    uint256 balanceRef;
    uint256 totalRef;

    uint256 balance;
    uint256 withdrawn;
  }

  IBSC public rewardsToken;

  address public support;

  uint[] public refRewards;
  uint256 public totalFarmers;
  uint256 public _rewardsTokenRegister =100;
  uint256 public _rewardsTokenTier1 = 50;
  uint256 public _rewardsTokenTier2 = 30;
  uint256 public _rewardsTokenTier3 = 20;
  uint256 public _rewardsTokenTier4 = 10;
  uint256 public totalRefRewards;

  mapping (address => Farmer) public farmers;
  event Register(address user, address referer);
  event Reward(address user, uint256 amount);
  event Withdraw(address user, uint256 amount);

  constructor(address _rewardsToken) public {
    refRewards.push(_rewardsTokenTier1);
    refRewards.push(_rewardsTokenTier2);
    refRewards.push(_rewardsTokenTier3);
    refRewards.push(_rewardsTokenTier4);
    support = msg.sender;
    rewardsToken = IBSC(_rewardsToken);
  }

  function register(address referer) external {
    if (!farmers[msg.sender].registered) {
      farmers[msg.sender].registered = true;
      farmers[msg.sender].balance = _rewardsTokenRegister;

      totalFarmers++;

      if (farmers[referer].registered && referer != msg.sender) {
        farmers[msg.sender].referer = referer;

        address rec = referer;

        for (uint256 i = 0; i < refRewards.length; i++) {
          if (!farmers[rec].registered) {
            break;
          }

          if (i == 0) {
            farmers[rec].referrals_tier1++;
          }

          if (i == 1) {
            farmers[rec].referrals_tier2++;
          }

          if (i == 2) {
            farmers[rec].referrals_tier3++;
          }

          if (i == 3) {
            farmers[rec].referrals_tier3++;
          }

          rec = farmers[rec].referer;
        }

        rewardReferers(referer);
      }

      emit Register(msg.sender, referer);
    }
  }

  function rewardReferers(address referer) internal {
    address rec = referer;

    for (uint256 i = 0; i < refRewards.length; i++) {
      if (!farmers[rec].registered) {
        break;
      }

      uint256 a = refRewards[i];

      farmers[rec].balance += a;
      farmers[rec].totalRef += a;
      farmers[rec].balanceRef += a;
      totalRefRewards += a;

      rec = farmers[rec].referer;
      emit Reward(msg.sender, a);
    }
  }

  function balanceOf(address user) public view returns (uint256) {
    return farmers[user].balance;
  }

  function availabeBalance() public view returns (uint256) {
    return IBSC(rewardsToken).balanceOf(address(this));
  }

  function withdraw() external {
    Farmer storage farmer = farmers[msg.sender];
    require(farmer.registered, "Can not withdraw because no any investments");
    require(farmer.balance >= 0, "Withdraw amount exceeds allowance");

    uint256 amount = farmer.balance;

    require(IBSC(rewardsToken).transfer(msg.sender, amount), 'Withdraw transfer failed');
    farmer.balance -= amount;
    farmer.withdrawn += amount;

    emit Withdraw(msg.sender, amount);
  }

  function endAirdrop() public onlyOwner {
    require(IBSC(rewardsToken).transfer(msg.sender, IBSC(rewardsToken).balanceOf(address(this))), 'Withdraw transfer failed');
  }
}
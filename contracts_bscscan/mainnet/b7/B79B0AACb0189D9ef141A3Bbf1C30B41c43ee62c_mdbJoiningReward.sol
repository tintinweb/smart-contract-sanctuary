/**
 *Submitted for verification at BscScan.com on 2021-07-20
*/

/**
 *Submitted for verification at BscScan.com on 2021-05-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

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


contract mdbJoiningReward is Ownable {
  struct Claimer {
    address referer;
    uint256 tier1;
    uint256 tier2;
    uint256 tier3;
    uint256 tier4;
    uint256 totalRef;
    uint256 claimed;
  }

  IBSC public claimToken;

  address public support;

  uint[] public rewards;
  uint256 public totalclaimers;
  uint256 public _claimTokenRegister = 100;
  uint256 public _claimTokenTier1 = 50;
  uint256 public _claimTokenTier2 = 30;
  uint256 public _claimTokenTier3 = 20;
  uint256 public _claimTokenTier4 = 10;
  uint256 public totalrewards;

  mapping (address => Claimer) public claimers;
  event Claim(address user, address referer);
  event Reward(address user, uint256 amount);

  constructor(address _claimToken) public {
    rewards.push(_claimTokenTier1);
    rewards.push(_claimTokenTier2);
    rewards.push(_claimTokenTier3);
    rewards.push(_claimTokenTier4);
    support = msg.sender;
    claimToken = IBSC(_claimToken);
  }

  function claim(address referer) external {
    if (claimers[msg.sender].claimed == 0) {
      claimers[msg.sender].claimed = _claimTokenRegister;

      totalclaimers++;

      if (claimers[referer].claimed != 0 && referer != msg.sender) {
        address rec = referer;
        claimers[msg.sender].referer = referer;

        for (uint256 i = 0; i < rewards.length; i++) {
          if (claimers[rec].claimed == 0) {
            break;
          }

          if (i == 0) {
            claimers[rec].tier1++;
          }

          if (i == 1) {
            claimers[rec].tier2++;
          }

          if (i == 2) {
            claimers[rec].tier3++;
          }

          if (i == 3) {
            claimers[rec].tier3++;
          }

          rec = claimers[rec].referer;
        }

        rewardReferers(referer);
      }

      require(IBSC(claimToken).transfer(msg.sender, _claimTokenRegister), 'Claim token is failed');
      emit Claim(msg.sender, referer);
    }
  }

  function rewardReferers(address referer) internal {
    address rec = referer;

    for (uint256 i = 0; i < rewards.length; i++) {
      if (claimers[rec].claimed == 0) {
        break;
      }

      uint256 a = rewards[i];

      claimers[rec].claimed += a;
      totalrewards += a;

      require(IBSC(claimToken).transfer(rec, a), 'Claim reward token is failed');
      emit Reward(rec, a);

      rec = claimers[rec].referer;
    }
  }

  function balanceOf(address user) public view returns (uint256) {
    return claimers[user].claimed;
  }

  function availabe() public view returns (uint256) {
    return IBSC(claimToken).balanceOf(address(this));
  }
}
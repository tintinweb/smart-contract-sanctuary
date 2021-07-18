/**
 *Submitted for verification at BscScan.com on 2021-07-18
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


contract CorisReward is Ownable {
  struct Claimer {
    uint256 block;
    uint256 claimed;
  }

  IBSC public holdingToken;
  IBSC public claimToken;

  uint256 public totalclaimers;
  uint256 public _claimTokenTier1 = 20 * 1e18;
  uint256 public _claimTokenTier2 = 10 * 1e18;
  uint256 public _claimTokenTier3 = 5 * 1e18;
  uint256 public _claimTokenTier4 = 2 * 1e18;
  uint256 public _claimTokenTier5 = 1 * 1e18;

  uint256 public _holdingTokenTier1 = 3000 * 1e14;
  uint256 public _holdingTokenTier2 = 1000 * 1e14;
  uint256 public _holdingTokenTier3 = 500 * 1e14;
  uint256 public _holdingTokenTier4 = 100 * 1e14;
  uint256 public _holdingTokenTier5 = 10 * 1e14;

  uint256 public totalrewards;

  mapping (address => Claimer) public claimers;
  event Reward(address user, uint256 amount);

  constructor(address _claimToken, address _holdingToken) public {
    claimToken = IBSC(_claimToken);
    holdingToken = IBSC(_holdingToken);
  }

  function claim() public {
    if (claimers[msg.sender].claimed == 0) {
      uint256 _amount = rewardAmount(msg.sender);

      if (_amount > 0) {
        totalrewards += _amount;
        claimers[msg.sender].claimed = _amount;
        claimers[msg.sender].block = block.number;
        require(IBSC(claimToken).transfer(msg.sender, _amount), 'Claim token is failed');
        emit Reward(msg.sender, _amount);
      }
    }
  }

  function rewardAmount(address _user) internal returns (uint256) {
    uint256 corgiAmount = IBSC(holdingToken).balanceOf(_user);

    if (corgiAmount >= _holdingTokenTier1) {
      return _claimTokenTier1;
    }

    if (corgiAmount >= _holdingTokenTier2) {
      return _claimTokenTier2;
    }

    if (corgiAmount >= _holdingTokenTier3) {
      return _claimTokenTier3;
    }

    if (corgiAmount >= _holdingTokenTier4) {
      return _claimTokenTier4;
    }

    if (corgiAmount >= _holdingTokenTier5) {
      return _claimTokenTier5;
    }

    return 0;
  }

  function finish() public onlyOwner {
    require(IBSC(claimToken).transfer(msg.sender, IBSC(claimToken).balanceOf(address(this))), 'End of reward CORIS is failed');
  }

  function changCurrency(address _currency) public onlyOwner {
    claimToken = IBSC(_currency);
  }
}
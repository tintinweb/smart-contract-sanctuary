// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

struct Member {
  address account;
  uint256 totalAmount;
  uint256 claimedAmount;
  uint256 startTime;
  uint256 endTime;
}

contract VestingContract is Ownable {

  event Claimed(address account, uint256 amount);

  event Added(address account, uint256 amount);
  event Removed(address account, uint256 amount);

  IERC20 kataToken;

  string public name;

  mapping(address => Member) public members;

  uint256 public tgeTime;
  uint256 public tgePercent;
  uint256 public cliffDuration;
  uint256 public cliffPercent;
  uint256 public linearDuration;

  uint256 public allocatedAmount;

  /**
   * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
   * _beneficiary, gradually in a linear fashion until _start + _duration. By then all
   * of the balance will have vested.
   * @param _name beneficiary of tokens after they are released
   * @param _kataToken dd
   * @param _tgeTime duration in seconds of the period in which tokens will begin to vest
   * @param _cliffDuration duration in seconds of the cliff in which tokens will begin to vest
   * @param _cliffPercent dd
   * @param _linearDuration duration in seconds of the period in which the tokens will vest
   */
  constructor(
    string memory _name,
    address _kataToken,
    uint256 _tgeTime,
    uint256 _tgePercent,
    uint256 _cliffDuration,
    uint256 _cliffPercent,
    uint256 _linearDuration
  ) {
    require(_kataToken != address(0), "token is zero address");
    require(_tgeTime > 0, "invalid tgeTime");

    name = _name;
    kataToken = IERC20(_kataToken);
    tgeTime = _tgeTime;
    tgePercent = _tgePercent;
    cliffDuration = _cliffDuration;
    cliffPercent = _cliffPercent;
    linearDuration = _linearDuration;
  }

  modifier onlyMember() {
    require(members[msg.sender].account != address(0), "You are not a valid member");
    _;
  }

  function balance() public view returns (uint256) {
    uint256 _balance = kataToken.balanceOf(address(this));
    _balance -= allocatedAmount;
    return _balance;
  }

  /**
   * @dev Calculates the amount that has already vested but hasn't been released yet.
   */
  function claimableAmount(address addr, uint256 timestamp) public view returns (uint256) {
    Member memory _member = members[addr];

    uint256 vested = vestedAmount(addr, timestamp);

    if (vested < _member.claimedAmount) {
      return 0;
    }

    return vested - _member.claimedAmount;
  }

  /**
   * @dev Calculates the amount that has already vested.
   */
  function vestedAmount(address addr, uint256 timestamp) public view returns (uint256) {
    Member memory _member = members[addr];

    if (timestamp < _member.startTime) {
      return 0;
    }

    uint256 _tgeAmount = (_member.totalAmount * tgePercent) / 100;
    uint256 _cliffTime = _member.startTime + cliffDuration;

    if (timestamp < _cliffTime) {
      return _tgeAmount;
    }

    if (_member.endTime != 0) {
      return _member.totalAmount;
    }

    if (timestamp >= (_cliffTime + linearDuration)) {
      return _member.totalAmount;
    }

    uint256 _cliffAmount = (_member.totalAmount * cliffPercent) / 100;

    uint256 _linearAmount = (_member.totalAmount - _tgeAmount) - _cliffAmount;
    _linearAmount = (_linearAmount * (timestamp - _cliffTime)) / linearDuration;

    return _tgeAmount + _cliffAmount + _linearAmount;
  }

  function claim() external onlyMember {
    Member memory _member = members[msg.sender];
    uint256 timestamp = block.timestamp;

    uint256 claimable = claimableAmount(_member.account, timestamp);

    require(claimable > 0, "no tokens claimable");
    require(_member.totalAmount >= (_member.claimedAmount + claimable), "token pool exhausted");

    kataToken.transfer(_member.account, claimable);
    _member.claimedAmount += claimable;
    allocatedAmount -= claimable;

    members[msg.sender] = _member;

    emit Claimed(_member.account, claimable);
  }

  function addMembers(address[] memory addrs, uint256[] memory tokenAmounts) external onlyOwner {
    for (uint256 i = 0; i < addrs.length; i++) {
      require(tokenAmounts[i] <= balance(), 'allocation would exceed remaining balance');

      Member memory _member = members[addrs[i]];

      if (_member.account == address(0)) {
        _member.account = addrs[i];
        _member.startTime = block.timestamp;

        if (_member.startTime < tgeTime) {
          _member.startTime = tgeTime;
        }
      }

      _member.endTime = 0;
      _member.totalAmount += tokenAmounts[i];
      allocatedAmount += tokenAmounts[i];

      members[addrs[i]] = _member;

      emit Added(addrs[i], tokenAmounts[i]);
    }
  }

  function removeMember(address addr) external onlyOwner {
    Member memory _member = members[addr];

    uint256 remaining = _member.totalAmount;
    _member.totalAmount = _member.claimedAmount + claimableAmount(addr, block.timestamp);
    remaining -= _member.totalAmount;
    allocatedAmount -= remaining;

    _member.endTime = block.timestamp;

    members[addr] = _member;

    emit Removed(addr, remaining);
  }

  function setKataToken(address _erc) external onlyOwner {
    kataToken = IERC20(_erc);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
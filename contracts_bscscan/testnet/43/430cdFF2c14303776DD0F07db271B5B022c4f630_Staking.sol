// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Staking is Ownable {
  event Locking(uint256 lockTime);
  event RewardRate(uint256 rate);
  event Rewards(address account, uint256 amount);
  event Withdraw(address account, uint256 amount);
  event Stake(address account, uint256 amount);

  IERC20 public rewardsToken;
  IERC20 public stakingToken;

  uint256 public rewardRate = 190258;
  uint256 public lastUpdateTime;
  uint256 public rewardPerTokenStored;
  uint256 public minimalLock = 604800;
  uint256 public minimalLockForReward = 604800;

  mapping(address => uint256) public userRewardPerTokenPaid;
  mapping(address => uint256) public rewards;
  mapping(address => uint256) public releaseTime;
  mapping(address => uint256) public rewardReleaseTime;

  uint256 private _totalSupply;
  mapping(address => uint256) private _balances;

  modifier updateReward(address account) {
      rewardPerTokenStored = rewardPerToken();
      lastUpdateTime = block.timestamp;

      rewards[account] = earned(account);
      userRewardPerTokenPaid[account] = rewardPerTokenStored;
      _;
  }

  constructor(address _stakingToken, address _rewardsToken) {
      stakingToken = IERC20(_stakingToken);
      rewardsToken = IERC20(_rewardsToken);
  }

  function stake(uint _amount) external updateReward(msg.sender) {
      _totalSupply += _amount;
      _balances[msg.sender] += _amount;
      releaseTime[msg.sender] = block.timestamp + minimalLock;
      rewardReleaseTime[msg.sender] = block.timestamp + minimalLockForReward;
      stakingToken.transferFrom(msg.sender, address(this), _amount);
      emit Stake(msg.sender, _amount);
  }

  function withdraw(uint _amount) external updateReward(msg.sender) {
     require(block.timestamp > releaseTime[msg.sender], "locked time");
      _totalSupply -= _amount;
      _balances[msg.sender] -= _amount;
      if(_balances[msg.sender] == 0){
        userRewardPerTokenPaid[msg.sender] = 0;
      }
      stakingToken.transfer(msg.sender, _amount);
      emit Withdraw(msg.sender, _amount);
  }

  function getReward() external updateReward(msg.sender) {
    require(block.timestamp > rewardReleaseTime[msg.sender], "locked time");
    uint reward = rewards[msg.sender];
    rewards[msg.sender] = 0;
    rewardsToken.transfer(msg.sender, reward);
    emit Rewards(msg.sender, reward);
  }

  function stakedAmount(address _address) external view returns (uint256) {
    return _balances[_address];
  }

  function getReleaseTime() external view returns (uint256) {
    return releaseTime[msg.sender];
  }

  function updateRewardRate(uint256 _rate) external onlyOwner {
    require(_rate > 0, "need to be greater than zero");
    rewardRate = _rate;
    emit RewardRate(_rate);
  }

  function setMinimalLock(uint256 _lockTime) external onlyOwner{
    require(_lockTime > 0, "need to be greater than zero");
    minimalLock = _lockTime;
    emit Locking(_lockTime);
  }

  function setMinimalLockForReward(uint256 _lockTime) external onlyOwner{
    require(_lockTime > 0, "need to be greater than zero");
    minimalLockForReward = _lockTime;
    emit Locking(_lockTime);
  }

  function rewardPerToken() public view returns (uint256) {
      if (_totalSupply == 0) {
          return 0;
      }
      return
          rewardPerTokenStored +
          (((block.timestamp - lastUpdateTime) * rewardRate * 1e18) / _totalSupply);
  }

  function earned(address account) public view returns (uint256) {
      return
          ((_balances[account] *
              (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) +
          rewards[account];
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
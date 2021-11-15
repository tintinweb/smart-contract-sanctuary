// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import { ReentrancyGuard } from '@openzeppelin/contracts/security/ReentrancyGuard.sol';

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { IStakePolicy } from '../interfaces/IStakePolicy.sol';
import { BasicStakePolicy } from '../policies/BasicStakePolicy.sol';

import { Modifiers, PoolInfo, UserInfo, MAX_ALLOC_POINT, ACC_REWARD_PRECISION } from '../libraries/LibAppStorage.sol';
import { LibToken } from '../libraries/LibToken.sol';
import { LibDiamond } from '../../shared/Diamond/libraries/LibDiamond.sol';
import { DogMath, DogMath128 } from '../../shared/Diamond/libraries/DogMath.sol';
import { SignedSafeMath } from '../../shared/Diamond/libraries/SignedSafeMath.sol';
import { RewardLockFacet } from './RewardLockFacet.sol';

contract PoolFacet is Modifiers, ReentrancyGuard {
  /// @notice libraries used
  using DogMath for uint256;
  using DogMath128 for uint128;
  using SignedSafeMath for int256;

  /// @notice stake policy types
  enum StakePolicyType {
    Basic,
    Aave,
    Compound
  }

  /// @notice emmited when pool has been added
  event Add(
    uint256 indexed pid,
    uint256 allocPoint,
    address indexed lpToken,
    uint16 depositFee,
    StakePolicyType stakePolicyType,
    IStakePolicy stakePolicy,
    bool massUpdatePools
  );
  /// @notice emmited when new allocation points assigned
  event Set(address indexed owner, uint256 indexed pid, uint256 allocPoint);
  /// @notice emmited when tokens deposited
  event Deposit(
    address indexed user,
    uint256 indexed pid,
    uint256 amount,
    bool massUpdatePools
  );
  /// @notice emmited when tokens withdrawn
  event Withdraw(
    address indexed user,
    uint256 indexed pid,
    uint256 amount,
    bool harvest
  );
  /// @notice emmited when reward harvested
  event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
  /// @notice emmited when harvest multiple called
  event HarvestMultiple(address indexed user, uint256[] _pids, uint256 amount);
  /// @notice emmited when harvest all called
  event HarvestAll(address indexed user, uint256 amount);
  /// @notice emmited when emergency withdrawal triggered
  event EmergencyWithdraw(
    address indexed user,
    uint256 indexed pid,
    uint256 amount
  );
  /// @notice emmited when dev mint removed
  event RemoveDevMint(address indexed user);
  /// @notice emmited when new reward per block set
  event SetRewardPerBlock(address indexed user, uint256 rewardPerBlock);
  /// @notice emmited when pool is updated
  event UpdatePool(
    uint256 indexed pid,
    uint64 lastRewardBlock,
    uint256 lpSupply,
    uint256 accRewardPerShare
  );

  /// @notice get length of pools
  function poolCount() external view returns (uint256 count_) {
    count_ = s.poolInfo.length;
  }

  /// @notice Add a new LP to the pool. Can only be called by the owner.
  /// @param _allocPoint AP of the new pool.
  /// @param _lpToken Address of the LP ERC-20 token.
  /// @param _depositFee Deposit fee percentage
  /// @param _stakePolicyType Stake policy type 🥩
  /// @param _feeAddress address who will receive fees
  function add(
    uint256 _allocPoint,
    address _lpToken,
    uint16 _depositFee,
    StakePolicyType _stakePolicyType,
    address _feeAddress,
    bool _massUpdatePools
  ) external nonDuplicated(_lpToken) whenNotPaused onlyOwner {
    require(
      _allocPoint <= MAX_ALLOC_POINT,
      'PoolFacet: allocation points over max'
    );

    if (_massUpdatePools) {
      _updateAllPools();
    }

    s.totalAllocPoint = s.totalAllocPoint.add(_allocPoint);
    s.lpTokens[_lpToken] = true;

    IStakePolicy stakePolicy = new BasicStakePolicy(
      _lpToken,
      _feeAddress
    );

    s.poolInfo.push(
      PoolInfo({
        lpToken: _lpToken,
        allocPoint: _allocPoint.to64(),
        lastRewardBlock: block.number.to64(),
        accTokenPerShare: 0,
        depositFee: _depositFee,
        totalDeposited: 0,
        stakePolicy: stakePolicy
      })
    );

    emit Add(
      s.poolInfo.length.sub(1),
      _allocPoint,
      _lpToken,
      _depositFee,
      _stakePolicyType,
      stakePolicy,
      _massUpdatePools
    );
  }

  /// @notice set new allocation points for pool
  /// @param _pid the pool id
  /// @param _allocPoint new allocation points
  function set(uint256 _pid, uint256 _allocPoint)
    external
    whenNotPaused
    onlyOwner
  {
    require(
      _allocPoint <= MAX_ALLOC_POINT,
      'PoolFacet: allocation points over max'
    );
    PoolInfo storage pool = s.poolInfo[_pid];

    s.totalAllocPoint = s.totalAllocPoint.sub(pool.allocPoint).add(_allocPoint);

    pool.allocPoint = _allocPoint.to64();
    emit Set(msg.sender, _pid, _allocPoint);
  }

  /// @notice get reward multiplier over the given _from to _to block.
  /// @param _from the start block
  /// @param _to the end block
  function getMultiplier(uint256 _from, uint256 _to)
    internal
    pure
    returns (uint256 multiplier_)
  {
    multiplier_ = _to.sub(_from);
  }

  /// @notice get pending reward
  /// @param _pid the pool id
  /// @param _user user address
  function pendingReward(uint256 _pid, address _user)
    external
    view
    returns (uint256 pendingReward_)
  {
    PoolInfo storage pool = s.poolInfo[_pid];
    UserInfo storage user = s.userInfo[_pid][_user];

    uint256 accTokenPerShare = pool.accTokenPerShare;
    if (
      block.number > pool.lastRewardBlock &&
      pool.totalDeposited != 0 &&
      s.totalAllocPoint != 0
    ) {
      uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
      uint256 reward = multiplier.mul(s.rewardPerBlock).mul(pool.allocPoint) /
        s.totalAllocPoint;

      accTokenPerShare = accTokenPerShare.add(
        reward.mul(ACC_REWARD_PRECISION) / pool.totalDeposited
      );
    }
    pendingReward_ = (user.amount.mul(
      accTokenPerShare.sub(user.lastTokenPerShare)
    ) / ACC_REWARD_PRECISION);
  }

  /// @notice update reward variables for all pools
  function massUpdatePools() external {
    _updateAllPools();
  }

  /// @notice update the pool
  /// @param _pid the pool id
  function updatePool(uint256 _pid) external {
    _updatePool(_pid);
  }

  /// @notice deposit tokens to pool
  /// @param _pid the pool id
  /// @param _amount LP token amount to deposit.
  /// @param _shouldHarvest if user should harvest reward
  function deposit(
    uint256 _pid,
    uint256 _amount,
    bool _shouldHarvest
  ) external nonReentrant whenNotPaused {
    require(_amount > 0, 'PoolFacet: amount must be greater than zero');
    PoolInfo storage pool = s.poolInfo[_pid];
    UserInfo storage user = s.userInfo[_pid][msg.sender];

    _updateUserReward(_pid, _shouldHarvest);

    if (_amount > 0) {
      uint256 amountMinusFee = pool.stakePolicy.deposit(
        _amount,
        msg.sender,
        pool.depositFee
      );

      user.amount = user.amount.add(amountMinusFee);
      user.rewardDebt = user.rewardDebt.add(
        int256(amountMinusFee.mul(pool.accTokenPerShare) / ACC_REWARD_PRECISION)
      );

      pool.totalDeposited = pool.totalDeposited.add(amountMinusFee);
    }

    emit Deposit(msg.sender, _pid, _amount, _shouldHarvest);
  }

  /// @notice withdraw tokens from pool
  /// @param _pid the pool id
  /// @param _amount LP token amount to withdraw.
  /// @param _shouldHarvest if user should harvest reward
  function withdraw(
    uint256 _pid,
    uint256 _amount,
    bool _shouldHarvest
  ) external nonReentrant whenNotPaused {
    require(_amount > 0, 'PoolFacet: amount must be greater than zero');
    PoolInfo storage pool = s.poolInfo[_pid];
    UserInfo storage user = s.userInfo[_pid][msg.sender];

    require(user.amount >= _amount, 'PoolFacet: user didnt add that amount');
    _updateUserReward(_pid, _shouldHarvest);

    if (_amount > 0) {
      user.amount = user.amount.sub(_amount);
      pool.totalDeposited = pool.totalDeposited.sub(_amount);

      pool.stakePolicy.withdraw(_amount, msg.sender);
    }

    emit Withdraw(msg.sender, _pid, _amount, _shouldHarvest);
  }

  /// @notice withdraw without caring about rewards. EMERGENCY ONLY.
  /// @param _pid the pool id
  function emergencyWithdraw(uint256 _pid) external nonReentrant {
    PoolInfo storage pool = s.poolInfo[_pid];
    UserInfo storage user = s.userInfo[_pid][msg.sender];
    uint256 amount = user.amount;
    user.amount = 0;
    user.lastTokenPerShare = 0;
    pool.totalDeposited = pool.totalDeposited.sub(amount);

    pool.stakePolicy.withdraw(amount, msg.sender);
    emit EmergencyWithdraw(msg.sender, _pid, amount);
  }

  /// @notice harvest one pool
  /// @param _pid the pool id
  function harvest(uint256 _pid) external nonReentrant whenNotPaused {
    _updateUserReward(_pid, true);
  }

  /// @notice harvest multiple pools
  /// @param _pids the pool ids
  function harvestMultiple(uint256[] calldata _pids)
    external
    nonReentrant
    whenNotPaused
  {
    uint256 pending = 0;
    for (uint256 i = 0; i < _pids.length; i++) {
      _updatePool(_pids[i]);
      PoolInfo storage pool = s.poolInfo[_pids[i]];
      UserInfo storage user = s.userInfo[_pids[i]][msg.sender];
      if (user.amount == 0) {
        user.lastTokenPerShare = pool.accTokenPerShare;
      }
      pending = pending.add(
        (user.amount.mul(
          pool.accTokenPerShare.sub(user.lastTokenPerShare.to128())
        ) / ACC_REWARD_PRECISION)
      );
      user.lastTokenPerShare = pool.accTokenPerShare;
    }
    if (pending > 0) {
      _lockReward(msg.sender, pending);
    }
    emit HarvestMultiple(msg.sender, _pids, pending);
  }

  /// @notice harvest all pools, will fail if too many pools
  function harvestAll() external nonReentrant whenNotPaused {
    _updateAllPools();
    uint256 pending = 0;
    for (uint256 i = 0; i < s.poolInfo.length; i++) {
      PoolInfo storage pool = s.poolInfo[i];
      UserInfo storage user = s.userInfo[i][msg.sender];

      if (user.amount == 0) {
        user.lastTokenPerShare = pool.accTokenPerShare;
      }
      pending = pending.add(
        (user.amount.mul(
          pool.accTokenPerShare.sub(user.lastTokenPerShare.to128())
        ) / ACC_REWARD_PRECISION)
      );
      user.lastTokenPerShare = pool.accTokenPerShare;
    }

    if (pending > 0) {
      _lockReward(msg.sender, pending);
    }

    emit HarvestAll(msg.sender, pending);
  }

  /// @notice get the rewards per block
  function rewardPerBlock() external view returns (uint256 rpb_) {
    rpb_ = s.rewardPerBlock;
  }

  /// @notice get info of a block
  /// @param _pid the pool id
  function poolInfo(uint256 _pid)
    external
    view
    returns (PoolInfo memory pool_)
  {
    pool_ = s.poolInfo[_pid];
  }

  /// @notice get info of a block
  /// @param _pid the pool id
  /// @param _user the user in the pool
  function userInfo(uint256 _pid, address _user)
    external
    view
    returns (UserInfo memory user_)
  {
    user_ = s.userInfo[_pid][_user];
  }

  /// @notice set new reward per block
  /// @param _rpb new reward per block
  function setRewardPerBlock(uint256 _rpb) external whenNotPaused onlyOwner {
    s.rewardPerBlock = _rpb;

    emit SetRewardPerBlock(msg.sender, _rpb);
  }

  /// @notice get stake policy
  /// @param _pid the pool id
  function getStakePolicy(uint256 _pid)
    external
    view
    returns (IStakePolicy stakePolicy_)
  {
    stakePolicy_ = s.poolInfo[_pid].stakePolicy;
  }

  /// @notice remove the dev mint, thi cannot be turned back on
  function removeDevMint() external onlyOwner {
    s.devMint = false;
    emit RemoveDevMint(msg.sender);
  }

  /// @notice update the pool
  /// @param _pid the pool id
  function _updatePool(uint256 _pid) internal {
    PoolInfo storage pool = s.poolInfo[_pid];

    if (block.number <= pool.lastRewardBlock) {
      return;
    }

    if (pool.totalDeposited == 0 || pool.allocPoint == 0) {
      pool.lastRewardBlock = block.number.to64();
      return;
    }

    uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);

    uint256 reward = multiplier.mul(s.rewardPerBlock).mul(pool.allocPoint) /
      s.totalAllocPoint;

    if (s.devMint) {
      s.token.mint(s.devAddress, reward / 50);
    }

    s.token.mint(address(this), reward);

    pool.accTokenPerShare = pool.accTokenPerShare.add(
      (reward.mul(ACC_REWARD_PRECISION) / pool.totalDeposited).to128()
    );

    pool.lastRewardBlock = block.number.to64();

    emit UpdatePool(
      _pid,
      pool.lastRewardBlock,
      pool.totalDeposited,
      pool.accTokenPerShare
    );
  }

  /// @notice update reward variables for all pools
  function _updateAllPools() internal {
    uint256 length = s.poolInfo.length;
    for (uint256 pid = 0; pid < length; ++pid) {
      _updatePool(pid);
    }
  }

  /// @notice update a users reward and harvest if needed
  /// @param _pid the pool id
  /// @param _shouldHarvest if user should harvest reward
  function _updateUserReward(uint256 _pid, bool _shouldHarvest) internal {
    PoolInfo storage pool = s.poolInfo[_pid];
    UserInfo storage user = s.userInfo[_pid][msg.sender];

    _updatePool(_pid);
    if (user.amount == 0) {
      user.lastTokenPerShare = pool.accTokenPerShare;
    }
    uint256 pending = (user.amount.mul(
      pool.accTokenPerShare.sub(user.lastTokenPerShare.to128())
    ) / ACC_REWARD_PRECISION);

    uint256 sendAmount = pending.mul(s.rewardPercent) / 100;
    uint256 rewardToLock = pending.sub(sendAmount);

    if (_shouldHarvest && pending > 0) {
      _lockReward(msg.sender, rewardToLock);
      LibToken.safeTokenTransfer(msg.sender, sendAmount);
      emit Harvest(msg.sender, _pid, pending);
    }

    user.lastTokenPerShare = pool.accTokenPerShare;
  }

  /// @notice lock the users reward
  /// @param _user user address
  /// @param _amount amount to lock
  function _lockReward(address _user, uint256 _amount) internal {
    bool success = RewardLockFacet(address(this)).lockReward(_user, _amount);

    require(success, 'PoolFacet: lock reward failed');
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

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
pragma solidity 0.8.4;

interface IStakePolicy {
  function deposit(
    uint256 _amount,
    address _owner,
    uint16 _depositFee
  ) external returns (uint256 amount_);

  function withdraw(uint256 _amount, address _owner) external;

  function setFeeAddress(address _feeAddress) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import { IStakePolicy } from '../interfaces/IStakePolicy.sol';

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { ERC20 } from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import { SafeERC20 } from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { DogMath } from '../../shared/Diamond/libraries/DogMath.sol';

contract BasicStakePolicy is IStakePolicy, ERC20, Ownable {
  using SafeERC20 for IERC20;
  using DogMath for uint256;

  /// @notice lp token used in policy
  IERC20 lpToken;
  /// @notice the address accumulating the fees
  address public feeAddress;
  /// @notice the amount of fees accumulated
  uint256 public accFeeAmount;

  /// @notice constructor of the policy
  /// @param _lpToken the token in the liquidity pool
  /// @param _feeAddress the address accumulating fees
  constructor(
    address _lpToken,
    address _feeAddress
  ) ERC20('DogPark V1', 'DP-V1') {
    lpToken = IERC20(_lpToken);
    feeAddress = _feeAddress;
  }

  /// @notice withdraw the amount based on ref token
  /// @param _amount the withdrawal amount
  /// @param _owner the address who owns the funds
  function withdraw(uint256 _amount, address _owner)
    external
    override
    onlyOwner
  {
    _burn(_owner, _amount);
    lpToken.safeTransferFrom(address(this), _owner, _amount);
  }

  /// @notice deposit the amount and receive ref token
  /// @param _amount the withdrawal amount
  /// @param _owner the address who owns the funds
  /// @param _depositFee the amount of fees being taken off
  function deposit(
    uint256 _amount,
    address _owner,
    uint16 _depositFee
  ) external override onlyOwner returns (uint256 amount_) {
    uint256 depositFee = _amount.mul(_depositFee) / 10000;
    uint256 amountMinusFee = _amount.sub(depositFee);

    _mint(_owner, amountMinusFee);
    lpToken.safeTransferFrom(_owner, feeAddress, depositFee);
    lpToken.safeTransferFrom(_owner, address(this), amountMinusFee);
    amount_ = amountMinusFee;
  }

  /// @notice set a new fee address only fee holder can do this
  function setFeeAddress(address _feeAddress) external override onlyOwner {
    feeAddress = _feeAddress;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import { IStakePolicy } from '../interfaces/IStakePolicy.sol';
import { IERC20Mintable } from '../interfaces/IERC20Mintable.sol';
import { LibDiamond } from '../../shared/Diamond/libraries/LibDiamond.sol';
// reward precision
uint256 constant ACC_REWARD_PRECISION = 1e18;

// max allocation points
uint256 constant MAX_ALLOC_POINT = 100000; // Safety check

// struct for the pool info
struct PoolInfo {
  /// LP token in the pool
  address lpToken;
  /// accumulated tokens per share
  uint128 accTokenPerShare;
  /// last block to have reward minted
  uint64 lastRewardBlock;
  /// allocation points for reward percentage
  uint64 allocPoint;
  /// deposit fee form 0 = 100;
  uint16 depositFee;
  /// total deposited
  uint256 totalDeposited;
  /// the policy that decides the staked tokens fate
  IStakePolicy stakePolicy;
}

/// struct for the lock info
struct LockInfo {
  /// amount locked
  uint256 amount;
  /// when locked
  uint256 timestamp;
}

/// struct for the users lock info
struct UserLockInfo {
  /// array of lock info
  LockInfo[] lockInfo;
  /// unclaimed amount
  uint256 unclaimed;
  /// last claimed id
  uint256 lastClaimed;
}

/// struct for the user info
struct UserInfo {
  /// amount user has staked minus fees
  uint256 amount;
  /// amount the amount of reward owed to user per block
  int256 rewardDebt;
  /// last token per share for user
  uint256 lastTokenPerShare;
}

/// struct for teh app state
struct AppStorage {
  /// token being minted in pools
  IERC20Mintable token;
  /// dev address where dev funds go
  address devAddress;
  /// bool to decide if the the devs get minted funds
  bool devMint;
  /// the period of how long the reward funds are locked
  uint256 lockingPeriod;
  /// the record of user info
  mapping(uint256 => mapping(address => UserInfo)) userInfo;
  /// the lock info for users
  mapping(address => UserLockInfo) userLockInfo;
  /// total allocation points
  uint256 totalAllocPoint;
  /// reward tokens per block
  uint256 rewardPerBlock;
  /// the percentage of reward that doesn't get locked
  uint256 rewardPercent;
  /// information on the pools
  PoolInfo[] poolInfo;
  /// list of liquidity pool tokens
  mapping(address => bool) lpTokens;
  /// app pause status
  bool paused;
}

/// @notice app storage library for mapping state
library LibAppStorage {
  function diamondStorage() internal pure returns (AppStorage storage ds_) {
    AppStorage storage ds;

    assembly {
      ds.slot := 0
    }
    ds_ = ds;
  }

  function abs(int256 x) internal pure returns (uint256 abs_) {
    abs_ = uint256(x >= 0 ? x : -x);
  }
}

/// @notice modifiers used in application
contract Modifiers {
  AppStorage internal s;

  /// @notice modifier to check if pools contain liquidity pool
  modifier nonDuplicated(address _lpToken) {
    require(
      s.lpTokens[_lpToken] == false,
      'Modifiers: cant use the same LP token'
    );
    _;
  }

  /// @notice modifier to make a function callable only when the contract is not paused.
  modifier whenNotPaused {
    require(!s.paused, 'Modifiers: paused');
    _;
  }

  /// @notice modifier to make a function callable only when the contract is paused.
  modifier whenPaused {
    require(s.paused, 'Modifiers: not paused');
    _;
  }

  modifier onlyOwner {
    LibDiamond.enforceIsContractOwner();
    _;
  }

  modifier onlyThis {
    require(
      msg.sender == address(this),
      'Modifiers: can only be called by diamond'
    );
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import { AppStorage, LibAppStorage } from './LibAppStorage.sol';

library LibToken {
  /// @notice safely transfer the funds based on amount minted to diamond
  /// @param _to the receiver of funds
  /// @param _amount the amount of funds
  function safeTokenTransfer(address _to, uint256 _amount) internal {
    AppStorage storage s = LibAppStorage.diamondStorage();

    uint256 tokenBalance = s.token.balanceOf(address(this));
    if (_amount > tokenBalance) {
      s.token.transfer(_to, tokenBalance);
    } else {
      s.token.transfer(_to, _amount);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

/******************************************************************************\
* Author: Nick Mudge
*
* Implementation of Diamond facet.
* This is gas optimized by reducing storage reads and storage writes.
* This code is as complex as it is to reduce gas costs.
/******************************************************************************/

import { IDiamondCut } from '../interfaces/IDiamondCut.sol';

library LibDiamond {
  bytes32 constant DIAMOND_STORAGE_POSITION =
    keccak256('diamond.standard.diamond.storage');

  struct DiamondStorage {
    // maps function selectors to the facets that execute the functions.
    // and maps the selectors to their position in the selectorSlots array.
    // func selector => address facet, selector position
    mapping(bytes4 => bytes32) facets;
    /// maps the polished facets, these facets cant be changed
    mapping(bytes4 => bool) polishedFacets;
    // array of slots of function selectors.
    // each slot holds 8 function selectors.
    mapping(uint256 => bytes32) selectorSlots;
    // The number of function selectors in selectorSlots
    uint16 selectorCount;
    // owner of the contract
    // Used to query if a contract implements an interface.
    // Used to implement ERC-165.
    mapping(bytes4 => bool) supportedInterfaces;
    // owner of the contract
    address contractOwner;
    // checks if whole diamond is polished
    bool polished;
  }

  function diamondStorage() internal pure returns (DiamondStorage storage ds_) {
    bytes32 position = DIAMOND_STORAGE_POSITION;
    DiamondStorage storage ds;

    assembly {
      ds.slot := position
    }

    ds_ = ds;
  }

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  function setContractOwner(address _newOwner) internal {
    DiamondStorage storage ds = diamondStorage();
    address previousOwner = ds.contractOwner;
    ds.contractOwner = _newOwner;
    emit OwnershipTransferred(previousOwner, _newOwner);
  }

  function contractOwner() internal view returns (address contractOwner_) {
    contractOwner_ = diamondStorage().contractOwner;
  }

  function enforceIsContractOwner() internal view {
    require(
      msg.sender == diamondStorage().contractOwner,
      'LibDiamond: Must be contract owner'
    );
  }

  modifier onlyOwner {
    require(
      msg.sender == diamondStorage().contractOwner,
      'LibDiamond: Must be contract owner'
    );
    _;
  }

  event DiamondCut(
    IDiamondCut.FacetCut[] _diamondCut,
    address _init,
    bytes _calldata
  );

  bytes32 constant CLEAR_ADDRESS_MASK =
    bytes32(uint256(0xffffffffffffffffffffffff));
  bytes32 constant CLEAR_SELECTOR_MASK = bytes32(uint256(0xffffffff << 224));

  // Internal function version of diamondCut
  // This code is almost the same as the external diamondCut,
  // except it is using 'Facet[] memory _diamondCut' instead of
  // 'Facet[] calldata _diamondCut'.
  // The code is duplicated to prevent copying calldata to memory which
  // causes an error for a two dimensional array.
  function diamondCut(
    IDiamondCut.FacetCut[] memory _diamondCut,
    address _init,
    bytes memory _calldata
  ) internal {
    DiamondStorage storage ds = diamondStorage();
    uint256 originalSelectorCount = ds.selectorCount;
    uint256 selectorCount = originalSelectorCount;
    bytes32 selectorSlot;
    // Check if last selector slot is not full
    if (selectorCount % 8 > 0) {
      // get last selectorSlot
      selectorSlot = ds.selectorSlots[selectorCount / 8];
    }
    // loop through diamond cut
    for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
      (selectorCount, selectorSlot) = addReplaceRemoveFacetSelectors(
        selectorCount,
        selectorSlot,
        _diamondCut[facetIndex].facetAddress,
        _diamondCut[facetIndex].action,
        _diamondCut[facetIndex].functionSelectors
      );
    }
    if (selectorCount != originalSelectorCount) {
      ds.selectorCount = uint16(selectorCount);
    }
    // If last selector slot is not full
    if (selectorCount % 8 > 0) {
      ds.selectorSlots[selectorCount / 8] = selectorSlot;
    }
    emit DiamondCut(_diamondCut, _init, _calldata);
    initializeDiamondCut(_init, _calldata);
  }

  function addReplaceRemoveFacetSelectors(
    uint256 _selectorCount,
    bytes32 _selectorSlot,
    address _newFacetAddress,
    IDiamondCut.FacetCutAction _action,
    bytes4[] memory _selectors
  ) internal returns (uint256, bytes32) {
    DiamondStorage storage ds = diamondStorage();
    require(!ds.polished, 'LibDiamondCut: Cant change polished diamond');
    require(
      _selectors.length > 0,
      'LibDiamondCut: No selectors in facet to cut'
    );
    bytes32 selectorSlotRef = _selectorSlot;
    uint256 selectorCountRef = _selectorCount;
    // add functions
    if (_action == IDiamondCut.FacetCutAction.Add) {
      require(
        _newFacetAddress != address(0),
        "LibDiamondCut: Add facet can't be address(0)"
      );
      for (
        uint256 selectorIndex;
        selectorIndex < _selectors.length;
        selectorIndex++
      ) {
        bytes4 selector = _selectors[selectorIndex];
        bytes32 oldFacet = ds.facets[selector];
        require(
          address(bytes20(oldFacet)) == address(0),
          "LibDiamondCut: Can't add function that already exists"
        );
        // add facet for selector
        ds.facets[selector] =
          bytes20(_newFacetAddress) |
          bytes32(selectorCountRef);
        uint256 selectorInSlotPosition = (selectorCountRef % 8) * 32;
        // clear selector position in slot and add selector
        selectorSlotRef =
          (selectorSlotRef & ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) |
          (bytes32(selector) >> selectorInSlotPosition);
        // if slot is full then write it to storage
        if (selectorInSlotPosition == 224) {
          ds.selectorSlots[selectorCountRef / 8] = selectorSlotRef;
          selectorSlotRef = 0;
        }
        selectorCountRef++;
      }
    } else if (_action == IDiamondCut.FacetCutAction.Replace) {
      require(
        _newFacetAddress != address(0),
        "LibDiamondCut: Replace facet can't be address(0)"
      );
      enforceHasContractCode(
        _newFacetAddress,
        'LibDiamondCut: Replace facet has no code'
      );
      for (
        uint256 selectorIndex;
        selectorIndex < _selectors.length;
        selectorIndex++
      ) {
        bytes4 selector = _selectors[selectorIndex];
        bytes32 oldFacet = ds.facets[selector];
        address oldFacetAddress = address(bytes20(oldFacet));
        bool isPolished = ds.polishedFacets[selector];

        // only useful if immutable functions exist
        require(
          oldFacetAddress != address(this),
          "LibDiamondCut: Can't replace immutable function"
        );
        require(!isPolished, "LibDiamondCut: Can't replace polished facets");
        require(
          oldFacetAddress != _newFacetAddress,
          "LibDiamondCut: Can't replace function with same function"
        );
        require(
          oldFacetAddress != address(0),
          "LibDiamondCut: Can't replace function that doesn't exist"
        );
        // replace old facet address
        ds.facets[selector] =
          (oldFacet & CLEAR_ADDRESS_MASK) |
          bytes20(_newFacetAddress);
      }
    } else if (_action == IDiamondCut.FacetCutAction.Remove) {
      require(
        _newFacetAddress == address(0),
        'LibDiamondCut: Remove facet address must be address(0)'
      );
      uint256 selectorSlotCount = selectorCountRef / 8;
      uint256 selectorInSlotIndex = (selectorCountRef % 8) - 1;
      for (
        uint256 selectorIndex;
        selectorIndex < _selectors.length;
        selectorIndex++
      ) {
        if (selectorSlotRef == 0) {
          // get last selectorSlot
          selectorSlotCount--;
          selectorSlotRef = ds.selectorSlots[selectorSlotCount];
          selectorInSlotIndex = 7;
        }
        bytes4 lastSelector;
        uint256 oldSelectorsSlotCount;
        uint256 oldSelectorInSlotPosition;
        // adding a block here prevents stack too deep error
        {
          bytes4 selector = _selectors[selectorIndex];
          bytes32 oldFacet = ds.facets[selector];
          bool isPolished = ds.polishedFacets[selector];

          require(
            address(bytes20(oldFacet)) != address(0),
            "LibDiamondCut: Can't remove function that doesn't exist"
          );
          // only useful if immutable functions exist
          require(
            address(bytes20(oldFacet)) != address(this),
            "LibDiamondCut: Can't remove immutable function"
          );
          // cant remove polished facet
          require(!isPolished, "LibDiamondCut: Can't remove polished facets");
          // replace selector with last selector in ds.facets
          // gets the last selector
          lastSelector = bytes4(selectorSlotRef << (selectorInSlotIndex * 32));
          if (lastSelector != selector) {
            // update last selector slot position info
            ds.facets[lastSelector] =
              (oldFacet & CLEAR_ADDRESS_MASK) |
              bytes20(ds.facets[lastSelector]);
          }
          delete ds.facets[selector];
          uint256 oldSelectorCount = uint16(uint256(oldFacet));
          oldSelectorsSlotCount = oldSelectorCount / 8;
          oldSelectorInSlotPosition = (oldSelectorCount % 8) * 32;
        }
        if (oldSelectorsSlotCount != selectorSlotCount) {
          bytes32 oldSelectorSlot = ds.selectorSlots[oldSelectorsSlotCount];
          // clears the selector we are deleting and puts the last selector in its place.
          oldSelectorSlot =
            (oldSelectorSlot &
              ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
            (bytes32(lastSelector) >> oldSelectorInSlotPosition);
          // update storage with the modified slot
          ds.selectorSlots[oldSelectorsSlotCount] = oldSelectorSlot;
        } else {
          // clears the selector we are deleting and puts the last selector in its place.
          selectorSlotRef =
            (selectorSlotRef &
              ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
            (bytes32(lastSelector) >> oldSelectorInSlotPosition);
        }
        if (selectorInSlotIndex == 0) {
          delete ds.selectorSlots[selectorSlotCount];
          selectorSlotRef = 0;
        }
        selectorInSlotIndex--;
      }
      selectorCountRef = selectorSlotCount * 8 + selectorInSlotIndex + 1;
    } else if (_action == IDiamondCut.FacetCutAction.Polish) {
      for (
        uint256 selectorIndex;
        selectorIndex < _selectors.length;
        selectorIndex++
      ) {
        bytes4 selector = _selectors[selectorIndex];
        bytes32 facet = ds.facets[selector];
        address facetAddress = address(bytes20(facet));
        bool isPolished = ds.polishedFacets[selector];

        // only useful if immutable functions exist
        require(
          facetAddress != address(this),
          "LibDiamondCut: Can't polish immutable function"
        );
        require(!isPolished, 'LibDiamondCut: Facet already polished');

        ds.polishedFacets[selector] = true;
      }
    } else {
      revert('LibDiamondCut: Incorrect FacetCutAction');
    }
    return (selectorCountRef, selectorSlotRef);
  }

  function initializeDiamondCut(address _init, bytes memory _calldata)
    internal
  {
    if (_init == address(0)) {
      require(
        _calldata.length == 0,
        'LibDiamondCut: _init is address(0) but_calldata is not empty'
      );
    } else {
      require(
        _calldata.length > 0,
        'LibDiamondCut: _calldata is empty but _init is not address(0)'
      );
      if (_init != address(this)) {
        enforceHasContractCode(
          _init,
          'LibDiamondCut: _init address has no code'
        );
      }
      (bool success, bytes memory error) = _init.delegatecall(_calldata);
      if (!success) {
        if (error.length > 0) {
          // bubble up the error
          revert(string(error));
        } else {
          revert('LibDiamondCut: _init function reverted');
        }
      }
    }
  }

  function enforceHasContractCode(
    address _contract,
    string memory _errorMessage
  ) internal view {
    uint256 contractSize;
    assembly {
      contractSize := extcodesize(_contract)
    }
    require(contractSize > 0, _errorMessage);
  }

  function polishDiamond() internal {
    DiamondStorage storage ds = diamondStorage();
    require(!ds.polished, 'LibDiamondCut: Diamond already polished');
    ds.polished = true;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

library DogMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    require((c = a + b) >= b, 'DogMath: Add Overflow');
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
    require((c = a - b) <= a, 'DogMath: Underflow');
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    require(b == 0 || (c = a * b) / b == a, 'DogMath: Mul Overflow');
  }

  function to128(uint256 a) internal pure returns (uint128 c) {
    c = uint128(a);
  }

  function to64(uint256 a) internal pure returns (uint64 c) {
    c = uint64(a);
  }

  function to32(uint256 a) internal pure returns (uint32 c) {
    c = uint32(a);
  }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint128.
library DogMath128 {
  function add(uint128 a, uint128 b) internal pure returns (uint128 c) {
    require((c = a + b) >= b, 'DogMath: Add Overflow');
  }

  function sub(uint128 a, uint128 b) internal pure returns (uint128 c) {
    require((c = a - b) <= a, 'DogMath: Underflow');
  }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint64.
library DogMath64 {
  function add(uint64 a, uint64 b) internal pure returns (uint64 c) {
    require((c = a + b) >= b, 'DogMath: Add Overflow');
  }

  function sub(uint64 a, uint64 b) internal pure returns (uint64 c) {
    require((c = a - b) <= a, 'DogMath: Underflow');
  }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint32.
library DogMath32 {
  function add(uint32 a, uint32 b) internal pure returns (uint32 c) {
    require((c = a + b) >= b, 'DogMath: Add Overflow');
  }

  function sub(uint32 a, uint32 b) internal pure returns (uint32 c) {
    require((c = a - b) <= a, 'DogMath: Underflow');
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

library SignedSafeMath {
  int256 private constant _INT256_MIN = -2**255;

  /**
   * @dev Returns the multiplication of two signed integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   *
   * - Multiplication cannot overflow.
   */
  function mul(int256 a, int256 b) internal pure returns (int256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    require(
      !(a == -1 && b == _INT256_MIN),
      'SignedSafeMath: multiplication overflow'
    );

    int256 c = a * b;
    require(c / a == b, 'SignedSafeMath: multiplication overflow');

    return c;
  }

  /**
   * @dev Returns the integer division of two signed integers. Reverts on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function div(int256 a, int256 b) internal pure returns (int256) {
    require(b != 0, 'SignedSafeMath: division by zero');
    require(
      !(b == -1 && a == _INT256_MIN),
      'SignedSafeMath: division overflow'
    );

    int256 c = a / b;

    return c;
  }

  /**
   * @dev Returns the subtraction of two signed integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   *
   * - Subtraction cannot overflow.
   */
  function sub(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a - b;
    require(
      (b >= 0 && c <= a) || (b < 0 && c > a),
      'SignedSafeMath: subtraction overflow'
    );

    return c;
  }

  /**
   * @dev Returns the addition of two signed integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   *
   * - Addition cannot overflow.
   */
  function add(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a + b;
    require(
      (b >= 0 && c >= a) || (b < 0 && c < a),
      'SignedSafeMath: addition overflow'
    );

    return c;
  }

  function toUInt256(int256 a) internal pure returns (uint256) {
    require(a >= 0, 'Integer < 0');
    return uint256(a);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import { ReentrancyGuard } from '@openzeppelin/contracts/security/ReentrancyGuard.sol';

import { Modifiers, UserLockInfo } from '../libraries/LibAppStorage.sol';
import { LibRewardLock } from '../libraries/LibRewardLock.sol';
import { LibDiamond } from '../../shared/Diamond/libraries/LibDiamond.sol';
import { DogMath } from '../../shared/Diamond/libraries/DogMath.sol';
import { LibToken } from '../libraries/LibToken.sol';

contract RewardLockFacet is Modifiers, ReentrancyGuard {
  using DogMath for uint256;
  /// @notice emmited when pause triggered
  event SetLockingPeriod(address indexed account, uint256 newLockingPeriod);
  /// @notice emmited when reward claimed
  event RewardClaimed(
    address indexed account,
    uint256 amount,
    uint256 lastClaimed
  );
  /// @notice emmited when reward is locked
  event RewardLocked(address indexed account, uint256 reward);

  /// @notice claim amount by claim id
  /// @param _lid lock period id
  function claim(uint256 _lid) external nonReentrant whenNotPaused {
    require(
      _lid > s.userLockInfo[msg.sender].lastClaimed,
      'RewardLockFacet: already claimed'
    );
    require(
      _lid <= s.userLockInfo[msg.sender].lockInfo.length,
      'RewardLockFacet: locker not valid'
    );

    UserLockInfo storage userInfo = s.userLockInfo[msg.sender];

    (uint256 pending, uint256 lastClaimed) = LibRewardLock.getClaimableAmount(
      msg.sender,
      _lid
    );

    userInfo.unclaimed = userInfo.unclaimed.sub(pending);

    userInfo.lastClaimed = lastClaimed;

    LibToken.safeTokenTransfer(msg.sender, pending);

    emit RewardClaimed(msg.sender, pending, lastClaimed);
  }

  /// @notice get users claimable amount
  /// @param _account the address of the user
  function getClaimableAmount(address _account)
    external
    view
    returns (uint256 pending_)
  {
    UserLockInfo storage userInfo = s.userLockInfo[_account];

    (uint256 pending, ) = LibRewardLock.getClaimableAmount(
      _account,
      userInfo.lockInfo.length
    );

    pending_ = pending;
  }

  /// @notice get the last claimed and length of lockers
  /// @param _account the address of the user
  function getLastClaimedAndLockerCount(address _account)
    external
    view
    returns (uint256 lastClaimed_, uint256 lockerCount_)
  {
    UserLockInfo storage userInfo = s.userLockInfo[_account];
    return (userInfo.lastClaimed, userInfo.lockInfo.length);
  }

  /// @notice set a new locking period
  /// @param _newLockingPeriodDays new locking period
  function setLockingPeriod(uint256 _newLockingPeriodDays)
    external
    whenNotPaused
    onlyOwner
  {
    s.lockingPeriod = _newLockingPeriodDays * 1 days;
    emit SetLockingPeriod(msg.sender, _newLockingPeriodDays);
  }

  /// @notice lock the users reward
  /// @param _user user address
  /// @param _amount amount to lock
  function lockReward(address _user, uint256 _amount)
    external
    onlyThis
    returns (bool success_)
  {
    LibRewardLock.lock(_user, _amount);
    emit RewardLocked(_user, _amount);
    success_ = true;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Mintable {
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
  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

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

  function mint(address _to, uint256 _amount) external;

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
pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
/******************************************************************************/

interface IDiamondCut {
  enum FacetCutAction {
    Add,
    Replace,
    Remove,
    Polish
  }

  struct FacetCut {
    address facetAddress;
    FacetCutAction action;
    bytes4[] functionSelectors;
  }

  /// @notice Add/replace/remove any number of functions and optionally execute
  ///         a function with delegatecall
  /// @param _diamondCut Contains the facet addresses and function selectors
  /// @param _init The address of the contract or facet to execute _calldata
  /// @param _calldata A function call, including function selector and arguments
  ///                  _calldata is executed with delegatecall on _init
  function diamondCut(
    FacetCut[] calldata _diamondCut,
    address _init,
    bytes calldata _calldata
  ) external;

  event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import { AppStorage, LibAppStorage, LockInfo, UserLockInfo } from './LibAppStorage.sol';
import { DogMath } from '../../shared/Diamond/libraries/DogMath.sol';
import { SignedSafeMath } from '../../shared/Diamond/libraries/SignedSafeMath.sol';

library LibRewardLock {
  using DogMath for uint256;
  using SignedSafeMath for int256;

  function lock(address _account, uint256 _amount) internal {
    require(_amount > 0, 'LibRewardLock: amount needs to be zero');
    AppStorage storage s = LibAppStorage.diamondStorage();

    UserLockInfo storage userInfo = s.userLockInfo[_account];
    userInfo.lockInfo.push(LockInfo(_amount, block.timestamp));
    userInfo.unclaimed = userInfo.unclaimed.add(_amount);
  }

  function getClaimableAmount(address _account, uint256 _lid)
    internal
    view
    returns (uint256 pending_, uint256 lastClaimable_)
  {
    AppStorage storage s = LibAppStorage.diamondStorage();
    UserLockInfo storage userInfo = s.userLockInfo[_account];

    pending_ = 0;
    lastClaimable_ = 0;
    for (uint256 i = userInfo.lastClaimed; i < _lid; i++) {
      uint256 lockingPeriod = s.lockingPeriod;
      if (
        block.timestamp >= (userInfo.lockInfo[i].timestamp.add(lockingPeriod))
      ) {
        pending_ = pending_.add(userInfo.lockInfo[i].amount);

        lastClaimable_ = i.add(1);
      } else {
        break;
      }
    }
  }
}


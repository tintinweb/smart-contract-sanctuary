// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@boringcrypto/boring-solidity/contracts/BoringBatchable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/SignedSafeMath.sol";
import "./interfaces/IRewarder.sol";
import "./interfaces/IRewardsSchedule.sol";

/************************************************************************************************
Originally from
https://github.com/sushiswap/sushiswap/blob/master/contracts/MasterChefV2.sol
and
https://github.com/sushiswap/sushiswap/blob/master/contracts/MasterChef.sol

This source code has been modified from the original, which was copied from the github repository
at commit hash 10148a31d9192bc803dac5d24fe0319b52ae99a4.
*************************************************************************************************/


contract MultiTokenStaking is Ownable, BoringBatchable {
  using BoringMath for uint256;
  using BoringMath128 for uint128;
  using BoringERC20 for IERC20;
  using SignedSafeMath for int256;

/** ==========  Constants  ========== */

  uint256 private constant ACC_REWARDS_PRECISION = 1e12;

  /**
   * @dev ERC20 token used to distribute rewards.
   */
  IERC20 public immutable rewardsToken;

  /**
   * @dev Contract that determines the amount of rewards distributed per block.
   * Note: This contract MUST always return the exact same value for any
   * combination of `(from, to)` IF `from` is less than `block.number`.
   */
  IRewardsSchedule public immutable rewardsSchedule;

/** ==========  Structs  ========== */

  /**
   * @dev Info of each user.
   * @param amount LP token amount the user has provided.
   * @param rewardDebt The amount of rewards entitled to the user.
   */
  struct UserInfo {
    uint256 amount;
    int256 rewardDebt;
  }

  /**
   * @dev Info of each rewards pool.
   * @param accRewardsPerShare Total rewards accumulated per staked token.
   * @param lastRewardBlock Last time rewards were updated for the pool.
   * @param allocPoint The amount of allocation points assigned to the pool.
   */
  struct PoolInfo {
    uint128 accRewardsPerShare;
    uint64 lastRewardBlock;
    uint64 allocPoint;
  }

/** ==========  Events  ========== */

  event Deposit(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
  event Withdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
  event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
  event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
  event LogPoolAddition(uint256 indexed pid, uint256 allocPoint, IERC20 indexed lpToken, IRewarder indexed rewarder);
  event LogSetPool(uint256 indexed pid, uint256 allocPoint, IRewarder indexed rewarder, bool overwrite);
  event LogUpdatePool(uint256 indexed pid, uint64 lastRewardBlock, uint256 lpSupply, uint256 accRewardsPerShare);
  event RewardsAdded(uint256 amount);
  event PointsAllocatorSet(address pointsAllocator);

/** ==========  Storage  ========== */

  /**
   * @dev Indicates whether a staking pool exists for a given staking token.
   */
  mapping(address => bool) public stakingPoolExists;

  /**
   * @dev Info of each staking pool.
   */
  PoolInfo[] public poolInfo;

  /**
   * @dev Address of the LP token for each staking pool.
   */
  mapping(uint256 => IERC20) public lpToken;

  /**
   * @dev Address of each `IRewarder` contract.
   */
  mapping(uint256 => IRewarder) public rewarder;

  /**
   * @dev Info of each user that stakes tokens.
   */
  mapping(uint256 => mapping(address => UserInfo)) public userInfo;

  /**
   * @dev Total allocation points. Must be the sum of all allocation points in all pools.
   */
  uint256 public totalAllocPoint = 0;

  /**
   * @dev Account allowed to allocate points.
   */
  address public pointsAllocator;

  /**
   * @dev Total rewards received from governance for distribution.
   * Used to return remaining rewards if staking is canceled.
   */
  uint256 public totalRewardsReceived;

  function poolLength() external view returns (uint256) {
    return poolInfo.length;
  }

/** ==========  Modifiers  ========== */

  /**
   * @dev Ensure the caller is allowed to allocate points.
   */
  modifier onlyPointsAllocatorOrOwner {
    require(
      msg.sender == pointsAllocator || msg.sender == owner(),
      "MultiTokenStaking: not authorized to allocate points"
    );
    _;
  }

/** ==========  Constructor  ========== */

  constructor(address _rewardsToken, address _rewardsSchedule) public {
    rewardsToken = IERC20(_rewardsToken);
    rewardsSchedule = IRewardsSchedule(_rewardsSchedule);
  }

/** ==========  Governance  ========== */

  /**
   * @dev Set the address of the points allocator.
   * This account will have the ability to set allocation points for LP rewards.
   */
  function setPointsAllocator(address _pointsAllocator) external onlyOwner {
    pointsAllocator = _pointsAllocator;
    emit PointsAllocatorSet(_pointsAllocator);
  }

  /**
   * @dev Add rewards to be distributed.
   *
   * Note: This function must be used to add rewards if the owner
   * wants to retain the option to cancel distribution and reclaim
   * undistributed tokens.
   */
  function addRewards(uint256 amount) external onlyPointsAllocatorOrOwner {
    rewardsToken.safeTransferFrom(msg.sender, address(this), amount);
    totalRewardsReceived = totalRewardsReceived.add(amount);
    emit RewardsAdded(amount);
  }

  /**
   * @dev Set the early end block for rewards on the rewards
   * schedule contract and return any tokens which will not
   * be distributed by the early end block.
   */
  function setEarlyEndBlock(uint256 earlyEndBlock) external onlyOwner {
    // Rewards schedule contract must assert that an early end block has not
    // already been set, otherwise this can be used to drain the staking
    // contract, meaning users will not receive earned rewards.
    uint256 totalRewards = rewardsSchedule.getRewardsForBlockRange(
      rewardsSchedule.startBlock(),
      earlyEndBlock
    );
    uint256 undistributedAmount = totalRewardsReceived.sub(totalRewards);
    rewardsSchedule.setEarlyEndBlock(earlyEndBlock);
    rewardsToken.safeTransfer(owner(), undistributedAmount);
  }

/** ==========  Pools  ========== */
  /**
   * @dev Add a new LP to the pool.
   * Can only be called by the owner or the points allocator.
   * @param _allocPoint AP of the new pool.
   * @param _lpToken Address of the LP ERC-20 token.
   * @param _rewarder Address of the rewarder delegate.
   */
  function add(uint256 _allocPoint, IERC20 _lpToken, IRewarder _rewarder) public onlyPointsAllocatorOrOwner {
    require(!stakingPoolExists[address(_lpToken)], "MultiTokenStaking: Staking pool already exists.");
    uint256 pid = poolInfo.length;
    totalAllocPoint = totalAllocPoint.add(_allocPoint);
    lpToken[pid] = _lpToken;
    if (address(_rewarder) != address(0)) {
      rewarder[pid] = _rewarder;
    }
    poolInfo.push(PoolInfo({
      allocPoint: _allocPoint.to64(),
      lastRewardBlock: block.number.to64(),
      accRewardsPerShare: 0
    }));
    stakingPoolExists[address(_lpToken)] = true;

    emit LogPoolAddition(pid, _allocPoint, _lpToken, _rewarder);
  }

  /**
   * @dev Update the given pool's allocation points.
   * Can only be called by the owner or the points allocator.
   * @param _pid The index of the pool. See `poolInfo`.
   * @param _allocPoint New AP of the pool.
   * @param _rewarder Address of the rewarder delegate.
   * @param _overwrite True if _rewarder should be `set`. Otherwise `_rewarder` is ignored.
   */
  function set(uint256 _pid, uint256 _allocPoint, IRewarder _rewarder, bool _overwrite) public onlyPointsAllocatorOrOwner {
    totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
    poolInfo[_pid].allocPoint = _allocPoint.to64();
    if (_overwrite) {
      rewarder[_pid] = _rewarder;
    }
    emit LogSetPool(_pid, _allocPoint, _overwrite ? _rewarder : rewarder[_pid], _overwrite);
  }

  /**
   * @dev Update reward variables for all pools in `pids`.
   * Note: This can become very expensive.
   * @param pids Pool IDs of all to be updated. Make sure to update all active pools.
   */
  function massUpdatePools(uint256[] calldata pids) external {
    uint256 len = pids.length;
    for (uint256 i = 0; i < len; ++i) {
      updatePool(pids[i]);
    }
  }

  /**
   * @dev Update reward variables of the given pool.
   * @param _pid The index of the pool. See `poolInfo`.
   * @return pool Returns the pool that was updated.
   */
  function updatePool(uint256 _pid) public returns (PoolInfo memory pool) {
    pool = poolInfo[_pid];
    if (block.number > pool.lastRewardBlock) {
      uint256 lpSupply = lpToken[_pid].balanceOf(address(this));
      if (lpSupply > 0) {
        uint256 rewardsTotal = rewardsSchedule.getRewardsForBlockRange(pool.lastRewardBlock, block.number);
        uint256 poolReward = rewardsTotal.mul(pool.allocPoint) / totalAllocPoint;
        pool.accRewardsPerShare = pool.accRewardsPerShare.add((poolReward.mul(ACC_REWARDS_PRECISION) / lpSupply).to128());
      }
      pool.lastRewardBlock = block.number.to64();
      poolInfo[_pid] = pool;
      emit LogUpdatePool(_pid, pool.lastRewardBlock, lpSupply, pool.accRewardsPerShare);
    }
  }

/** ==========  Users  ========== */

  /**
   * @dev View function to see pending rewards on frontend.
   * @param _pid The index of the pool. See `poolInfo`.
   * @param _user Address of user.
   * @return pending rewards for a given user.
   */
  function pendingRewards(uint256 _pid, address _user) external view returns (uint256 pending) {
    PoolInfo memory pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][_user];
    uint256 accRewardsPerShare = pool.accRewardsPerShare;
    uint256 lpSupply = lpToken[_pid].balanceOf(address(this));
    if (block.number > pool.lastRewardBlock && lpSupply != 0) {
      uint256 rewardsTotal = rewardsSchedule.getRewardsForBlockRange(pool.lastRewardBlock, block.number);
      uint256 poolReward = rewardsTotal.mul(pool.allocPoint) / totalAllocPoint;
      accRewardsPerShare = accRewardsPerShare.add(poolReward.mul(ACC_REWARDS_PRECISION) / lpSupply);
    }
    pending = int256(user.amount.mul(accRewardsPerShare) / ACC_REWARDS_PRECISION).sub(user.rewardDebt).toUInt256();
  }

  /**
   * @dev Deposit LP tokens to earn rewards.
   * @param _pid The index of the pool. See `poolInfo`.
   * @param _amount LP token amount to deposit.
   * @param _to The receiver of `_amount` deposit benefit.
   */
  function deposit(uint256 _pid, uint256 _amount, address _to) public {
    PoolInfo memory pool = updatePool(_pid);
    UserInfo storage user = userInfo[_pid][_to];

    // Effects
    user.amount = user.amount.add(_amount);
    user.rewardDebt = user.rewardDebt.add(int256(_amount.mul(pool.accRewardsPerShare) / ACC_REWARDS_PRECISION));

    // Interactions
    lpToken[_pid].safeTransferFrom(msg.sender, address(this), _amount);

    emit Deposit(msg.sender, _pid, _amount, _to);
  }

  /**
   * @dev Withdraw LP tokens from the staking contract.
   * @param _pid The index of the pool. See `poolInfo`.
   * @param _amount LP token amount to withdraw.
   * @param _to Receiver of the LP tokens.
   */
  function withdraw(uint256 _pid, uint256 _amount, address _to) public {
    PoolInfo memory pool = updatePool(_pid);
    UserInfo storage user = userInfo[_pid][msg.sender];

    // Effects
    user.rewardDebt = user.rewardDebt.sub(int256(_amount.mul(pool.accRewardsPerShare) / ACC_REWARDS_PRECISION));
    user.amount = user.amount.sub(_amount);

    // Interactions
    lpToken[_pid].safeTransfer(_to, _amount);

    emit Withdraw(msg.sender, _pid, _amount, _to);
  }

  /**
   * @dev Harvest proceeds for transaction sender to `_to`.
   * @param _pid The index of the pool. See `poolInfo`.
   * @param _to Receiver of rewards.
   */
  function harvest(uint256 _pid, address _to) public {
    PoolInfo memory pool = updatePool(_pid);
    UserInfo storage user = userInfo[_pid][msg.sender];
    int256 accumulatedRewards = int256(user.amount.mul(pool.accRewardsPerShare) / ACC_REWARDS_PRECISION);
    uint256 _pendingRewards = accumulatedRewards.sub(user.rewardDebt).toUInt256();

    // Effects
    user.rewardDebt = accumulatedRewards;

    // Interactions
    rewardsToken.safeTransfer(_to, _pendingRewards);

    address _rewarder = address(rewarder[_pid]);
    if (_rewarder != address(0)) {
      IRewarder(_rewarder).onStakingReward(_pid, msg.sender, _pendingRewards);
    }
    emit Harvest(msg.sender, _pid, _pendingRewards);
  }

  /**
   * @dev Withdraw LP tokens and harvest accumulated rewards, sending both to `to`.
   * @param _pid The index of the pool. See `poolInfo`.
   * @param _amount LP token amount to withdraw.
   * @param _to Receiver of the LP tokens and rewards.
   */
  function withdrawAndHarvest(uint256 _pid, uint256 _amount, address _to) public {
    PoolInfo memory pool = updatePool(_pid);
    UserInfo storage user = userInfo[_pid][msg.sender];
    int256 accumulatedRewards = int256(user.amount.mul(pool.accRewardsPerShare) / ACC_REWARDS_PRECISION);
    uint256 _pendingRewards = accumulatedRewards.sub(user.rewardDebt).toUInt256();

    // Effects
    user.rewardDebt = accumulatedRewards.sub(int256(_amount.mul(pool.accRewardsPerShare) / ACC_REWARDS_PRECISION));
    user.amount = user.amount.sub(_amount);

    // Interactions
    rewardsToken.safeTransfer(_to, _pendingRewards);
    lpToken[_pid].safeTransfer(_to, _amount);
    address _rewarder = address(rewarder[_pid]);
    if (_rewarder != address(0)) {
      IRewarder(_rewarder).onStakingReward(_pid, msg.sender, _pendingRewards);
    }

    emit Harvest(msg.sender, _pid, _pendingRewards);
    emit Withdraw(msg.sender, _pid, _amount, _to);
  }

  /**
   * @dev Withdraw without caring about rewards. EMERGENCY ONLY.
   * @param _pid The index of the pool. See `poolInfo`.
   * @param _to Receiver of the LP tokens.
   */
  function emergencyWithdraw(uint256 _pid, address _to) public {
    UserInfo storage user = userInfo[_pid][msg.sender];
    uint256 amount = user.amount;
    user.amount = 0;
    user.rewardDebt = 0;
    // Note: transfer can fail or succeed if `amount` is zero.
    lpToken[_pid].safeTransfer(_to, amount);
    emit EmergencyWithdraw(msg.sender, _pid, amount, _to);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
// a library for performing overflow-safe math, updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math)
library BoringMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {require((c = a + b) >= b, "BoringMath: Add Overflow");}
    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {require((c = a - b) <= a, "BoringMath: Underflow");}
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {require(b == 0 || (c = a * b)/b == a, "BoringMath: Mul Overflow");}
    function to128(uint256 a) internal pure returns (uint128 c) {
        require(a <= uint128(-1), "BoringMath: uint128 Overflow");
        c = uint128(a);
    }
    function to64(uint256 a) internal pure returns (uint64 c) {
        require(a <= uint64(-1), "BoringMath: uint64 Overflow");
        c = uint64(a);
    }
    function to32(uint256 a) internal pure returns (uint32 c) {
        require(a <= uint32(-1), "BoringMath: uint32 Overflow");
        c = uint32(a);
    }
}

library BoringMath128 {
    function add(uint128 a, uint128 b) internal pure returns (uint128 c) {require((c = a + b) >= b, "BoringMath: Add Overflow");}
    function sub(uint128 a, uint128 b) internal pure returns (uint128 c) {require((c = a - b) <= a, "BoringMath: Underflow");}
}

library BoringMath64 {
    function add(uint64 a, uint64 b) internal pure returns (uint64 c) {require((c = a + b) >= b, "BoringMath: Add Overflow");}
    function sub(uint64 a, uint64 b) internal pure returns (uint64 c) {require((c = a - b) <= a, "BoringMath: Underflow");}
}

library BoringMath32 {
    function add(uint32 a, uint32 b) internal pure returns (uint32 c) {require((c = a + b) >= b, "BoringMath: Add Overflow");}
    function sub(uint32 a, uint32 b) internal pure returns (uint32 c) {require((c = a - b) <= a, "BoringMath: Underflow");}
}

// SPDX-License-Identifier: UNLICENSED
// Audit on 5-Jan-2021 by Keno and BoringCrypto

// P1 - P3: OK
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
// solhint-disable avoid-low-level-calls

import "./libraries/BoringERC20.sol";

// T1 - T4: OK
contract BaseBoringBatchable {
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }    
    
    // F3 - F9: OK
    // F1: External is ok here because this is the batch function, adding it to a batch makes no sense
    // F2: Calls in the batch may be payable, delegatecall operates in the same context, so each call in the batch has access to msg.value
    // C1 - C21: OK
    // C3: The length of the loop is fully under user control, so can't be exploited
    // C7: Delegatecall is only used on the same contract, so it's safe
    function batch(bytes[] calldata calls, bool revertOnFail) external payable returns(bool[] memory successes, bytes[] memory results) {
        // Interactions
        successes = new bool[](calls.length);
        results = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(calls[i]);
            require(success || !revertOnFail, _getRevertMsg(result));
            successes[i] = success;
            results[i] = result;
        }
    }
}

// T1 - T4: OK
contract BoringBatchable is BaseBoringBatchable {
    // F1 - F9: OK
    // F6: Parameters can be used front-run the permit and the user's permit will fail (due to nonce or other revert)
    //     if part of a batch this could be used to grief once as the second call would not need the permit
    // C1 - C21: OK
    function permitToken(IERC20 token, address from, address to, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
        // Interactions
        // X1 - X5
        token.permit(from, to, amount, deadline, v, r, s);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

library SignedSafeMath {
  int256 constant private _INT256_MIN = -2**255;

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

    require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

    int256 c = a * b;
    require(c / a == b, "SignedSafeMath: multiplication overflow");

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
    require(b != 0, "SignedSafeMath: division by zero");
    require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

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
    require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

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
    require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

    return c;
  }

  function toUInt256(int256 a) internal pure returns (uint256) {
    require(a >= 0, "Integer < 0");
    return uint256(a);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;


interface IRewarder {
  function onStakingReward(uint256 pid, address user, uint256 rewardAmount) external;
  function pendingTokens(uint256 pid, address user, uint256 rewardAmount) external returns (address[] memory, uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;


interface IRewardsSchedule {
  event EarlyEndBlockSet(uint256 earlyEndBlock);

  function startBlock() external view returns (uint256);
  function endBlock() external view returns (uint256);
  function getRewardsForBlockRange(uint256 from, uint256 to) external view returns (uint256);
  function setEarlyEndBlock(uint256 earlyEndBlock) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "../interfaces/IERC20.sol";

library BoringERC20 {
    function safeSymbol(IERC20 token) internal view returns(string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x95d89b41));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeName(IERC20 token) internal view returns(string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x06fdde03));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x313ce567));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    function safeTransfer(IERC20 token, address to, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0xa9059cbb, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: Transfer failed");
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0x23b872dd, from, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: TransferFrom failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // EIP 2612
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


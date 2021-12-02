/**
 *Submitted for verification at snowtrace.io on 2021-12-01
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.0;

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
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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


/// @notice Safe IERC20 and ETH transfer library that safely handles missing return values.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol)
/// Taken from Solmate
library SafeERC20 {
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.approve.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    }

    function safeTransferETH(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}(new bytes(0));

        require(success, "ETH_TRANSFER_FAILED");
    }
}

// The kibble contract feeds users FETCH. Deposit gOHM-AVAX or gOHM-FETCH
// liquidity to earn rewards! Starts with gOHM-AVAX rewards for first three
// days, then splits 50-50 between the two and reweights once a day until 25-75.
contract Kibble {
    using SafeERC20 for IERC20;

    event Deposit(address who, uint256 indexed pid, uint256 amount);
    event Withdraw(address who, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address who, uint256 indexed pid, uint256 amount);

    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of SUSHIs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accSushiPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accSushiPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    struct PoolInfo {
        IERC20 token;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. SUSHIs to distribute per block.
        uint256 lastRewardTime;  // Last block number that SUSHIs distribution occurs.
        uint256 accFetchPerShare; // Accumulated SUSHIs per share, times 1e12. See below.
    }

    // The FETCH token
    IERC20 internal immutable fetch;
    // FETCH emissions per block
    uint256 public immutable fetchPerSecond = 150000 * 1e18;
    // gOHM and LP pool information
    mapping(uint256 => PoolInfo) public poolInfo;
    // User information
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points
    uint256 public totalAlloc;
    // Last time when rewards shifted.
    uint256 public lastWeightChange;
    // Time between weight changes. == Daily.
    uint256 public immutable interval = 86_400;

    constructor(
        IERC20 _fetch,
        IERC20 _gohmLP,
        IERC20 _fetchLP, 
        uint256 _startTime
    ) {
        require(address(_fetch) != address(0));
        fetch = _fetch;
        require(address(_gohmLP) != address(0));
        poolInfo[0] = PoolInfo({
            token: _gohmLP,
            allocPoint: 100,
            lastRewardTime: _startTime,
            accFetchPerShare: 0
        });
        require(address(_fetchLP) != address(0));
        poolInfo[1] = PoolInfo({
            token: _fetchLP,
            allocPoint: 0,
            lastRewardTime: (_startTime + 250_000), // 3 day delay
            accFetchPerShare: 0
        });
        totalAlloc = 100;
    }

    // View function to see pending FETCH on frontend.
    function pendingFetch(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accFetchPerShare = pool.accFetchPerShare;
        uint256 supply = pool.token.balanceOf(address(this));
        if (block.timestamp > pool.lastRewardTime && supply != 0) {
            uint256 fetchReward = (block.timestamp - pool.lastRewardTime) * fetchPerSecond * pool.allocPoint / totalAlloc;
            accFetchPerShare += (fetchReward * 1e12 / supply);
        }
        return user.amount * accFetchPerShare / 1e12 - user.rewardDebt;
    }

    // Deposit LP tokens to bowl for FETCH allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = (user.amount * pool.accFetchPerShare / 1e12) - user.rewardDebt;
            safeFetch(msg.sender, pending);
        }
        pool.token.safeTransferFrom(address(msg.sender), address(this), _amount);
        user.amount += _amount;
        user.rewardDebt = user.amount * pool.accFetchPerShare / 1e12;
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw tokens from bowl.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = (user.amount * pool.accFetchPerShare / 1e12) - user.rewardDebt;
        safeFetch(msg.sender, pending);
        user.amount -= _amount;
        user.rewardDebt = user.amount * pool.accFetchPerShare / 1e12;
        pool.token.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.token.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function updatePools() public {
        updatePool(0);
        updatePool(1);
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }
        uint256 supply = pool.token.balanceOf(address(this));
        if (supply == 0) {
            pool.lastRewardTime = block.timestamp;
            if (_pid == 1) {
                pool.allocPoint = 100;
                totalAlloc += 100;
                lastWeightChange = block.timestamp;
            }
            return;
        }
        if (block.timestamp > (lastWeightChange + interval) && poolInfo[0].allocPoint > 50) {
            poolInfo[0].allocPoint -= 2;
            poolInfo[1].allocPoint += 2;
            lastWeightChange += interval;
        }
        uint256 fetchReward = (block.timestamp - pool.lastRewardTime) * fetchPerSecond * pool.allocPoint / totalAlloc;
        pool.accFetchPerShare += (fetchReward * 1e12 / supply);
        pool.lastRewardTime = block.timestamp;
    }

    // Safe fetch transfer function, just in case if rounding error causes pool to not have enough FETCH.
    function safeFetch(address _to, uint256 _amount) internal {
        uint256 bal = fetch.balanceOf(address(this));
        if (_amount > bal) {
            fetch.transfer(_to, bal);
        } else {
            fetch.transfer(_to, _amount);
        }
    }
}
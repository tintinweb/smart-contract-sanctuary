// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./Ownable.sol";
import "./SafeERC20.sol";

interface IRewarder {
    function onHundredReward(uint pid, address user, address recipient, uint hundredAmount, uint newLpAmount) external;
    function pendingTokens(uint pid, address user, uint hundredAmount) external view returns (IERC20[] memory, uint[] memory);
}

interface IBAMM is IERC20 {
    function deposit(uint amount) external;
    function withdraw(uint numShares) external;
    function fetchPrice() external view returns(uint);
}

contract BProtocolChef is Ownable {
    using SafeERC20 for IERC20;

    /// @notice Info of each BProtocolChef user.
    /// `shares` LP token shares the user has provided.
    /// `rewardDebt` The shares of HUNDRED entitled to the user.
    struct UserInfo {
        uint shares;
        int256 rewardDebt;
    }

    /// @notice Info of each BProtocolChef pool.
    /// `allocPoint` The shares of allocation points assigned to the pool.
    /// Also known as the shares of HUNDRED to distribute per block.
    struct PoolInfo {
        uint128 accHundredPerShare;
        uint64 lastRewardTime;
        uint64 allocPoint;
    }

    /// @notice Address of Hundred contract.
    IERC20 public immutable Hundred;

    /// @notice Info of each BProtocolChef pool.
    PoolInfo[] public poolInfo;
    /// @notice Address of the B.Protocol LP token for each BProtocolChef pool.
    IBAMM[] public lpTokens;
    /// @notice Address of each `IRewarder` contract in BProtocolChef.
    IRewarder[] public rewarders;
    /// @notice Address of the underlying token for each BProtocolChef pool.
    /// This allows a user to deposit e.g. their USDC into the USDC BAMM, then deposit their BAMM tokens to MiniChef.
    IERC20[] public underlyingTokens;

    /// @notice Info of each user that stakes LP tokens.
    mapping (uint => mapping (address => UserInfo)) public userInfo;

    /// @dev Tokens added
    mapping (address => bool) public addedTokens;

    /// @dev Total allocation points. Must be the sum of all allocation points in all pools.
    uint public totalAllocPoint;

    uint public hundredPerSecond;
    uint private constant ACC_HUNDRED_PRECISION = 1e12;

    event Deposit(address indexed user, uint indexed pid, uint shares, address indexed to);
    event Withdraw(address indexed user, uint indexed pid, uint shares, address indexed to);
    event EmergencyWithdraw(address indexed user, uint indexed pid, uint shares, address indexed to);
    event Harvest(address indexed user, uint indexed pid, uint shares);
    event LogPoolAddition(uint indexed pid, uint allocPoint, IERC20 indexed lpToken, IRewarder indexed rewarder);
    event LogSetPool(uint indexed pid, uint allocPoint, IRewarder indexed rewarder, bool overwrite);
    event LogUpdatePool(uint indexed pid, uint64 lastRewardTime, uint lpSupply, uint accHundredPerShare);
    event LogHundredPerSecond(uint hundredPerSecond);

    /// @param _hundred The Hundred token contract address.
    constructor(IERC20 _hundred) {
        Hundred = _hundred;
    }

    /// @notice Returns the number of BProtocolChef pools.
    function poolLength() public view returns (uint pools) {
        pools = poolInfo.length;
    }

    /// @notice Add a new LP to the pool. Can only be called by the owner.
    /// DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    /// @param allocPoint AP of the new pool.
    /// @param _lpToken Address of the LP ERC-20 token.
    /// @param _rewarder Address of the rewarder delegate.
    function add(uint allocPoint, IBAMM _lpToken, IERC20 _underlyingToken, IRewarder _rewarder) public onlyOwner {
        require(addedTokens[address(_lpToken)] == false, "Token already added");
        totalAllocPoint = totalAllocPoint + allocPoint;
        lpTokens.push(_lpToken);
        rewarders.push(_rewarder);
        underlyingTokens.push(_underlyingToken);

        poolInfo.push(PoolInfo({
            allocPoint: uint64(allocPoint),
            lastRewardTime: uint64(block.timestamp),
            accHundredPerShare: 0
        }));
        addedTokens[address(_lpToken)] = true;
        emit LogPoolAddition(lpTokens.length - 1, allocPoint, _lpToken, _rewarder);
    }

    /// @notice Update the given pool's HUNDRED allocation point and `IRewarder` contract. Can only be called by the owner.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _allocPoint New AP of the pool.
    /// @param _rewarder Address of the rewarder delegate.
    /// @param overwrite True if _rewarder should be `set`. Otherwise `_rewarder` is ignored.
    function set(uint _pid, uint _allocPoint, IRewarder _rewarder, bool overwrite) public onlyOwner {
        totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;
        poolInfo[_pid].allocPoint = uint64(_allocPoint);
        if (overwrite) { rewarders[_pid] = _rewarder; }
        emit LogSetPool(_pid, _allocPoint, overwrite ? _rewarder : rewarders[_pid], overwrite);
    }

    /// @notice Sets the hundred per second to be distributed. Can only be called by the owner.
    /// @param _hundredPerSecond The shares of Hundred to be distributed per second.
    function setHundredPerSecond(uint _hundredPerSecond) public onlyOwner {
        hundredPerSecond = _hundredPerSecond;
        emit LogHundredPerSecond(_hundredPerSecond);
    }

    /// @notice View function to see pending HUNDRED on frontend.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _user Address of user.
    /// @return pending HUNDRED reward for a given user.
    function pendingHundred(uint _pid, address _user) external view returns (uint pending) {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint accHundredPerShare = pool.accHundredPerShare;
        uint lpSupply = lpTokens[_pid].balanceOf(address(this));
        if (block.timestamp > pool.lastRewardTime && lpSupply != 0 && totalAllocPoint != 0) {
            uint time = block.timestamp - pool.lastRewardTime;
            uint hundredReward = time * hundredPerSecond * pool.allocPoint / totalAllocPoint;
            accHundredPerShare = accHundredPerShare + hundredReward * ACC_HUNDRED_PRECISION / lpSupply;
        }
        pending = uint256(int256(user.shares * accHundredPerShare / ACC_HUNDRED_PRECISION) - user.rewardDebt);
    }

    /// @notice Update reward variables for all pools. Be careful of gas spending!
    /// @param pids Pool IDs of all to be updated. Make sure to update all active pools.
    function massUpdatePools(uint[] calldata pids) external {
        uint len = pids.length;
        for (uint i = 0; i < len; ++i) {
            updatePool(pids[i]);
        }
    }

    /// @notice Update reward variables of the given pool.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @return pool Returns the pool that was updated.
    function updatePool(uint pid) public returns (PoolInfo memory pool) {
        pool = poolInfo[pid];
        if (block.timestamp > pool.lastRewardTime) {
            uint lpSupply = lpTokens[pid].balanceOf(address(this));
            if (lpSupply != 0 && totalAllocPoint != 0) {
                uint time = block.timestamp - pool.lastRewardTime;
                uint hundredReward = time * hundredPerSecond * pool.allocPoint / totalAllocPoint;
                pool.accHundredPerShare = uint128(pool.accHundredPerShare + hundredReward * ACC_HUNDRED_PRECISION / lpSupply);
            }
            pool.lastRewardTime = uint64(block.timestamp);
            poolInfo[pid] = pool;
            emit LogUpdatePool(pid, pool.lastRewardTime, lpSupply, pool.accHundredPerShare);
        }
    }

    /// @notice Deposit the underlying token to the BAMM pool, then deposit the BAMM LP token to MiniChef.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param underlyingAmount Underlying token shares to deposit.
    /// @param to The receiver of the deposit benefit.
    function deposit(uint pid, uint underlyingAmount, address to) public {
        underlyingTokens[pid].safeTransferFrom(msg.sender, address(this), underlyingAmount);

        uint oldShares = lpTokens[pid].balanceOf(address(this));

        underlyingTokens[pid].approve(address(lpTokens[pid]), underlyingAmount);
        lpTokens[pid].deposit(underlyingAmount);

        uint newShares = lpTokens[pid].balanceOf(address(this)) - oldShares;

        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = userInfo[pid][to];

        // Effects
        user.shares = user.shares + newShares;
        user.rewardDebt = user.rewardDebt + int256(newShares * pool.accHundredPerShare / ACC_HUNDRED_PRECISION);

        // Interactions
        IRewarder _rewarder = rewarders[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onHundredReward(pid, to, to, 0, user.shares);
        }

        emit Deposit(msg.sender, pid, newShares, to);
    }

    function _withdrawFromBAMM(uint pid, uint shares, address to) internal {
        uint oldEthBalance = address(this).balance;
        uint oldUnderlyingBalance = underlyingTokens[pid].balanceOf(address(this));
        lpTokens[pid].withdraw(shares);
        uint newUnderlyingTokens = underlyingTokens[pid].balanceOf(address(this)) - oldUnderlyingBalance;
        underlyingTokens[pid].safeTransfer(to, newUnderlyingTokens);
        uint newEth = address(this).balance - oldEthBalance;
        if (newEth > 0) {
            (bool success, ) = to.call{ value: newEth }(""); // re-entry is fine here
            require(success, "withdraw: sending ETH failed");
        }

        emit Withdraw(msg.sender, pid, shares, to);
    }

    /// @notice Withdraw LP tokens from BProtocolChef without harvesting.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param shares LP token shares to withdraw.
    /// @param to Receiver of the LP tokens.
    function withdraw(uint pid, uint shares, address to) public {
        require(shares > 0, "Can't withdraw 0 shares");
        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = userInfo[pid][msg.sender];

        // Effects
        user.rewardDebt = user.rewardDebt - int256(shares * pool.accHundredPerShare / ACC_HUNDRED_PRECISION);
        user.shares = user.shares - shares;

        // Interactions
        IRewarder _rewarder = rewarders[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onHundredReward(pid, msg.sender, to, 0, user.shares);
        }

        _withdrawFromBAMM(pid, shares, to);
    }

    /// @notice Harvest proceeds for transaction sender to `to`.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param to Receiver of HUNDRED rewards.
    function harvest(uint pid, address to) public {
        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = userInfo[pid][msg.sender];
        int256 accumulatedHundred = int256(user.shares * pool.accHundredPerShare / ACC_HUNDRED_PRECISION);
        uint _pendingHundred = uint256(accumulatedHundred - user.rewardDebt);

        // Effects
        user.rewardDebt = accumulatedHundred;

        // Interactions
        if (_pendingHundred != 0) {
            Hundred.safeTransfer(to, _pendingHundred);
        }

        IRewarder _rewarder = rewarders[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onHundredReward(pid, msg.sender, to, _pendingHundred, user.shares);
        }

        emit Harvest(msg.sender, pid, _pendingHundred);
    }

    /// @notice Withdraw LP tokens from BProtocolChef and harvest proceeds for transaction sender to `to`.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param shares LP token shares to withdraw.
    /// @param to Receiver of the LP tokens and HUNDRED rewards.
    function withdrawAndHarvest(uint pid, uint shares, address to) public {
        withdraw(pid, shares, to);
        harvest(pid, to);
    }

    /// @notice Withdraw without caring about rewards. EMERGENCY ONLY.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param to Receiver of the LP tokens.
    function emergencyWithdraw(uint pid, address to) public {
        UserInfo storage user = userInfo[pid][msg.sender];
        uint shares = user.shares;
        user.shares = 0;
        user.rewardDebt = 0;

        IRewarder _rewarder = rewarders[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onHundredReward(pid, msg.sender, to, 0, 0);
        }

        // Note: transfer can fail or succeed if `shares` is zero.
        _withdrawFromBAMM(pid, shares, to);

        emit EmergencyWithdraw(msg.sender, pid, shares, to);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function totalSupply() external view returns (uint);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint shares) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint shares) external returns (bool);
    function transferFrom(address sender, address recipient, uint shares) external returns (bool);
    function permit(address target, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function transferWithPermit(address target, address to, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
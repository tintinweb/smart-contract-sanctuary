/**
 *Submitted for verification at BscScan.com on 2021-12-21
*/

/**
 *Submitted for verification at Etherscan.io on 2020-10-01
*/

// File: contracts/lib/Ownable.sol

/*

    Copyright 2020 Helicon ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;


/**
 * @title Ownable
 * @author Helicon Breeder
 *
 * @notice Ownership related functions
 */
contract Ownable {
    address public _OWNER_;
    address public _NEW_OWNER_;

    // ============ Events ============

    event OwnershipTransferPrepared(address indexed previousOwner, address indexed newOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // ============ Modifiers ============

    modifier onlyOwner() {
        require(msg.sender == _OWNER_, "NOT_OWNER");
        _;
    }

    // ============ Functions ============

    constructor() internal {
        _OWNER_ = msg.sender;
        emit OwnershipTransferred(address(0), _OWNER_);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "INVALID_OWNER");
        emit OwnershipTransferPrepared(_OWNER_, newOwner);
        _NEW_OWNER_ = newOwner;
    }

    function claimOwnership() external {
        require(msg.sender == _NEW_OWNER_, "INVALID_CLAIM");
        emit OwnershipTransferred(_OWNER_, _NEW_OWNER_);
        _OWNER_ = _NEW_OWNER_;
        _NEW_OWNER_ = address(0);
    }
}


// File: contracts/lib/SafeMath.sol

/*

    Copyright 2020 Helicon ZOO.

*/

/**
 * @title SafeMath
 * @author Helicon Breeder
 *
 * @notice Math operations with safety checks that revert on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "MUL_ERROR");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "DIVIDING_ERROR");
        return a / b;
    }

    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 quotient = div(a, b);
        uint256 remainder = a - quotient * b;
        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SUB_ERROR");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ADD_ERROR");
        return c;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = x / 2 + 1;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}


// File: contracts/lib/DecimalMath.sol

/*

    Copyright 2020 Helicon ZOO.

*/

/**
 * @title DecimalMath
 * @author Helicon Breeder
 *
 * @notice Functions for fixed point number with 18 decimals
 */
library DecimalMath {
    using SafeMath for uint256;

    uint256 constant ONE = 10**18;

    function mul(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(d) / ONE;
    }

    function mulCeil(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(d).divCeil(ONE);
    }

    function divFloor(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(ONE).div(d);
    }

    function divCeil(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(ONE).divCeil(d);
    }
}


// File: contracts/intf/IERC20.sol

// This is a file copied from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

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
}


// File: contracts/lib/SafeERC20.sol

/*

    Copyright 2020 Helicon ZOO.
    This is a simplified version of OpenZepplin's SafeERC20 library

*/

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;

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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File: contracts/token/HeliconRewardVault.sol

/*

    Copyright 2020 Helicon ZOO.

*/

interface IHeliconRewardVault {
    function reward(address to, uint256 amount) external;
}


contract HeliconRewardVault is Ownable {
    using SafeERC20 for IERC20;

    address public heliconToken;

    constructor(address _heliconToken) public {
        heliconToken = _heliconToken;
    }

    function reward(address to, uint256 amount) external onlyOwner {
        IERC20(heliconToken).safeTransfer(to, amount);
    }
}


// File: contracts/token/HeliconMine.sol

/*

    Copyright 2020 Helicon ZOO.

*/

contract HeliconMine is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of Helicons
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accHeliconPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accHeliconPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        address lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. Helicons to distribute per block.
        uint256 lastRewardBlock; // Last block number that Helicons distribution occurs.
        uint256 accHeliconPerShare; // Accumulated Helicons per share, times 1e12. See below.
        string poolName;
        uint256 totalDepositLp;
        uint256 totalRealizedReward;
        uint256 totalRewardDebt;
        bytes32 masterNFT;

    }

    address public heliconRewardVault;
    uint256 public heliconPerBlock;

    // Info of each pool.
    PoolInfo[] public poolInfos;
    mapping(address => uint256) public lpTokenRegistry;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(address => uint256) public realizedReward;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when Helicon mining starts.
    uint256 public startBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Claim(address indexed user, uint256 amount);

    constructor(address _heliconToken, uint256 _startBlock) public {
        heliconRewardVault = address(new HeliconRewardVault(_heliconToken));
        startBlock = _startBlock;
    }

    // ============ Modifiers ============

    modifier lpTokenExist(address lpToken) {
        require(lpTokenRegistry[lpToken] > 0, "LP Token Not Exist");
        _;
    }

    modifier lpTokenNotExist(address lpToken) {
        require(lpTokenRegistry[lpToken] == 0, "LP Token Already Exist");
        _;
    }

    // ============ Helper ============

    function poolLength() external view returns (uint256) {
        return poolInfos.length;
    }

    function getPid(address _lpToken) public view lpTokenExist(_lpToken) returns (uint256) {
        return lpTokenRegistry[_lpToken] - 1;
    }

    function getUserLpBalance(address _lpToken, address _user) public view returns (uint256) {
        uint256 pid = getPid(_lpToken);
        return userInfo[pid][_user].amount;
    }

    // ============ Ownable ============

    function addLpToken(
        address _lpToken,
        uint256 _allocPoint,
        string memory _poolName,
        bytes32 _masterNFT,
        bool _withUpdate
    ) public lpTokenNotExist(_lpToken) onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfos.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accHeliconPerShare: 0,
                poolName:_poolName,
                totalDepositLp:0,
                totalRealizedReward:0,
                totalRewardDebt:0,
                masterNFT:_masterNFT

            })
        );
        lpTokenRegistry[_lpToken] = poolInfos.length;
    }

    function setLpToken(
        address _lpToken,
        uint256 _allocPoint,
        string memory _poolName,
        bytes32 _masterNFT,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 pid = getPid(_lpToken);
        totalAllocPoint = totalAllocPoint.sub(poolInfos[pid].allocPoint).add(_allocPoint);
        poolInfos[pid].allocPoint = _allocPoint;
        poolInfos[pid].masterNFT = _masterNFT;
        poolInfos[pid].poolName = _poolName;
    }

    function setReward(uint256 _heliconPerBlock, bool _withUpdate) external onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        heliconPerBlock = _heliconPerBlock;
    }

    // ============ View Rewards ============

    function getPendingReward(address _lpToken, address _user) external view returns (uint256) {
        uint256 pid = getPid(_lpToken);
        PoolInfo storage pool = poolInfos[pid];
        UserInfo storage user = userInfo[pid][_user];
        uint256 accHeliconPerShare = pool.accHeliconPerShare;
        uint256 lpSupply = IERC20(pool.lpToken).balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 HeliconReward = block
                .number
                .sub(pool.lastRewardBlock)
                .mul(heliconPerBlock)
                .mul(pool.allocPoint)
                .div(totalAllocPoint);
            accHeliconPerShare = accHeliconPerShare.add(DecimalMath.divFloor(HeliconReward, lpSupply));
        }
        return DecimalMath.mul(user.amount, accHeliconPerShare).sub(user.rewardDebt);
    }

    function getAllPendingReward(address _user) external view returns (uint256) {
        uint256 length = poolInfos.length;
        uint256 totalReward = 0;
        for (uint256 pid = 0; pid < length; ++pid) {
            if (userInfo[pid][_user].amount == 0 || poolInfos[pid].allocPoint == 0) {
                continue; // save gas
            }
            PoolInfo storage pool = poolInfos[pid];
            UserInfo storage user = userInfo[pid][_user];
            uint256 accHeliconPerShare = pool.accHeliconPerShare;
            uint256 lpSupply = IERC20(pool.lpToken).balanceOf(address(this));
            if (block.number > pool.lastRewardBlock && lpSupply != 0) {
                uint256 HeliconReward = block
                    .number
                    .sub(pool.lastRewardBlock)
                    .mul(heliconPerBlock)
                    .mul(pool.allocPoint)
                    .div(totalAllocPoint);
                accHeliconPerShare = accHeliconPerShare.add(DecimalMath.divFloor(HeliconReward, lpSupply));
            }
            totalReward = totalReward.add(
                DecimalMath.mul(user.amount, accHeliconPerShare).sub(user.rewardDebt)
            );
        }
        return totalReward;
    }

    function getAllPendingRewardForPool(address _lpToken) external view returns (uint256){
        uint256 pid = getPid(_lpToken);
        PoolInfo storage pool = poolInfos[pid];
        // UserInfo storage user = userInfo[pid][_user];
        uint256 accHeliconPerShare = pool.accHeliconPerShare;
        // uint256 lpSupply = IERC20(pool.lpToken).balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && pool.totalDepositLp != 0) {
            uint256 HeliconReward = block
                .number
                .sub(pool.lastRewardBlock)
                .mul(heliconPerBlock)
                .mul(pool.allocPoint)
                .div(totalAllocPoint);
            accHeliconPerShare = accHeliconPerShare.add(DecimalMath.divFloor(HeliconReward, pool.totalDepositLp));
        }
        return DecimalMath.mul(pool.totalDepositLp, accHeliconPerShare).sub(pool.totalRewardDebt);
    }

    function getTotalDepositForPool(address _lpToken) external view returns(uint256){
        uint256 pid = getPid(_lpToken);
        PoolInfo storage pool = poolInfos[pid];
        return pool.totalDepositLp;
    }

    function getTotalRealizedReward(address _lpToken) external view returns(uint256){
        uint256 pid = getPid(_lpToken);
        PoolInfo storage pool = poolInfos[pid];
        return pool.totalRealizedReward;
    }

    function getRealizedReward(address _user) external view returns (uint256) {
        return realizedReward[_user];
    }

    function getDlpMiningSpeed(address _lpToken) external view returns (uint256) {
        uint256 pid = getPid(_lpToken);
        PoolInfo storage pool = poolInfos[pid];
        return heliconPerBlock.mul(pool.allocPoint).div(totalAllocPoint);
    }
    
    function getMasterNFT(address _lpToken) external view returns(bytes32){
        uint256 pid = getPid(_lpToken);
        PoolInfo storage pool = poolInfos[pid];
        return pool.masterNFT;
    }

    // ============ Update Pools ============

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfos.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfos[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = IERC20(pool.lpToken).balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 HeliconReward = block
            .number
            .sub(pool.lastRewardBlock)
            .mul(heliconPerBlock)
            .mul(pool.allocPoint)
            .div(totalAllocPoint);
        pool.accHeliconPerShare = pool.accHeliconPerShare.add(DecimalMath.divFloor(HeliconReward, lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // ============ Deposit & Withdraw & Claim ============
    // Deposit & withdraw will also trigger claim

    function deposit(address _lpToken, uint256 _amount) public {
        uint256 pid = getPid(_lpToken);
        PoolInfo storage pool = poolInfos[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        updatePool(pid);
        if (user.amount > 0) {
            uint256 pending = DecimalMath.mul(user.amount, pool.accHeliconPerShare).sub(
                user.rewardDebt
            );
            safeHeliconTransfer(msg.sender, pending);
            pool.totalRealizedReward = pool.totalRealizedReward.add(pending);
        }
        IERC20(pool.lpToken).safeTransferFrom(address(msg.sender), address(this), _amount);
        user.amount = user.amount.add(_amount);
        user.rewardDebt = DecimalMath.mul(user.amount, pool.accHeliconPerShare);
        pool.totalDepositLp = pool.totalDepositLp.add(_amount);
        pool.totalRewardDebt = DecimalMath.mul(pool.totalDepositLp,pool.accHeliconPerShare);
        emit Deposit(msg.sender, pid, _amount);
    }

    function withdraw(address _lpToken, uint256 _amount) public {
        uint256 pid = getPid(_lpToken);
        PoolInfo storage pool = poolInfos[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        require(user.amount >= _amount, "withdraw too much");
        updatePool(pid);
        uint256 pending = DecimalMath.mul(user.amount, pool.accHeliconPerShare).sub(user.rewardDebt);
        safeHeliconTransfer(msg.sender, pending);
        pool.totalRealizedReward = pool.totalRealizedReward.add(pending);
        user.amount = user.amount.sub(_amount);
        pool.totalDepositLp = pool.totalDepositLp.sub(_amount);
        pool.totalRewardDebt = DecimalMath.mul(pool.totalDepositLp,pool.accHeliconPerShare);
        user.rewardDebt = DecimalMath.mul(user.amount, pool.accHeliconPerShare);
        IERC20(pool.lpToken).safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, pid, _amount);
    }

    function withdrawAll(address _lpToken) public {
        uint256 balance = getUserLpBalance(_lpToken, msg.sender);
        withdraw(_lpToken, balance);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(address _lpToken) public {
        uint256 pid = getPid(_lpToken);
        PoolInfo storage pool = poolInfos[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        IERC20(pool.lpToken).safeTransfer(address(msg.sender), user.amount);
        pool.totalDepositLp = pool.totalDepositLp.sub(user.amount);
        pool.totalRewardDebt = DecimalMath.mul(pool.totalDepositLp,pool.accHeliconPerShare);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    function claim(address _lpToken) public {
        uint256 pid = getPid(_lpToken);
        if (userInfo[pid][msg.sender].amount == 0 || poolInfos[pid].allocPoint == 0) {
            return; // save gas
        }
        PoolInfo storage pool = poolInfos[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        updatePool(pid);
        uint256 pending = DecimalMath.mul(user.amount, pool.accHeliconPerShare).sub(user.rewardDebt);
        user.rewardDebt = DecimalMath.mul(user.amount, pool.accHeliconPerShare);
        pool.totalRewardDebt = DecimalMath.mul(pool.totalDepositLp,pool.accHeliconPerShare);
        safeHeliconTransfer(msg.sender, pending);
        pool.totalRealizedReward = pool.totalRealizedReward.add(pending);
    }

    function claimAll() public {
        uint256 length = poolInfos.length;
        uint256 pending = 0;
        for (uint256 pid = 0; pid < length; ++pid) {
            if (userInfo[pid][msg.sender].amount == 0 || poolInfos[pid].allocPoint == 0) {
                continue; // save gas
            }
            PoolInfo storage pool = poolInfos[pid];
            UserInfo storage user = userInfo[pid][msg.sender];
            updatePool(pid);
            uint256 pendingReward = DecimalMath.mul(user.amount, pool.accHeliconPerShare).sub(user.rewardDebt);
            pending = pending.add(
                pendingReward
            );
            pool.totalRealizedReward = pool.totalRealizedReward.add(pendingReward);
            user.rewardDebt = DecimalMath.mul(user.amount, pool.accHeliconPerShare);
            pool.totalRewardDebt = DecimalMath.mul(pool.totalDepositLp,pool.accHeliconPerShare);
        }
        safeHeliconTransfer(msg.sender, pending);
        
    }

    // Safe Helicon transfer function, just in case if rounding error causes pool to not have enough Helicons.
    function safeHeliconTransfer(address _to, uint256 _amount) internal {
        IHeliconRewardVault(heliconRewardVault).reward(_to, _amount);
        realizedReward[_to] = realizedReward[_to].add(_amount);
        emit Claim(_to, _amount);
    }
}
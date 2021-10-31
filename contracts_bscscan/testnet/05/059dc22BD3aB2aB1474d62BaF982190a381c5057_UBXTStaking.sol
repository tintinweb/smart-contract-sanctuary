pragma solidity ^0.6.12;

import "../common/Ownable.sol";
import "../common/IERC20.sol";
import "../library/SafeMath.sol";
import "../library/SafeERC20.sol";
import "./TokenPool.sol";

// UBXTStaking is the master of Token. He can make Token and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once Token is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract UBXTStaking is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP TOKENs the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 rewardUBXTDebt;
        //
        // We do some fancy math here. Basically, any point in time, the amount of TOKENs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accTokenPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP TOKENs to a pool. Here's what happens:
        //   1. The pool's `accTokenPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. TOKENs to distribute per block.
        uint256 lastRewardBlock; // Last block number that TOKENs distribution occurs.
        uint256 lastUBXTTotalReward; // Perf Pool Rewards
        uint256 accTokenPerShare; // Accumulated TOKENs per share, times 1e12. See below.
        uint256 ubxtAccRewardPerShare;
    }
    // The TOKEN TOKEN!
    address public token;
    // TOKEN TOKENs created per block.
    uint256 public tokenPerBlock;
    // Token holder
    TokenPool private _lockedPool;
    // Bonus muliplier for early token makers.
    uint256 public constant BONUS_MULTIPLIER = 1;
    // notice total UBXT rewards for distribution
    uint256 totalUBXTReward;
    // notice last UBXT rewards balance
    uint256 lastUBXTRewardBalance;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP TOKENs.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // Total UBXT staked
    uint256 public totalStakedUBXT;
    // The block number when TOKEN mining starts.
    uint256 public startBlock;
    // notice minimum time interval to call epoch
    uint256 public minEpochTimeIntervalSec;
    // notice to call epoch at fixed time in a day 
    uint256 public epochWindowOffsetSec;
    // notice seconds for epoch active
    uint256 public epochWindowLengthSec;
    // notice last epoch call time
    uint256 public lastEpochTimestampSec;
    // notice minted reward tokens for week
    uint256 public mintedRewardToken;
    // notice epoch count
    uint256 public epoch;
    // perf pool address
    address public perfPool;
    // withdraw fee
    uint256 public withdrawFee;
    // treasury address
    address public treasuryAddress;
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    constructor() public
    { }
    
    function initialize(address _token, uint256 _tokenPerBlock, address _owner) public initializer {
        Ownable.init(_owner);
        token = _token;
        tokenPerBlock = _tokenPerBlock;
        startBlock = block.number;
        _lockedPool = new TokenPool(IERC20(_token));
        treasuryAddress = _owner;
        withdrawFee = 300;

        minEpochTimeIntervalSec = 43200;  // 43200
        epochWindowOffsetSec = 0;
        epochWindowLengthSec = 30 minutes;  // 30 minutes
        lastEpochTimestampSec = 0;
    }
    
    /**
     * @return Total number of locked distribution tokens.
     */
    function totalLocked() public view returns (uint256) {
        return _lockedPool.balance();
    }
    
    // Lock Tokens for Reserved
    function lockUbxtTokens(uint256 _amount) public onlyOwner {
        require(_lockedPool.token().transferFrom(msg.sender, address(_lockedPool), _amount),
            'UBXTStaking: transfer into locked pool failed');
    }

    /**
     * @return If the latest block timestamp is within the Epoch time window it, returns true.
     *         Otherwise, returns false.
     */
    function inEpochWindow() public view returns (bool) {
        return (
            block.timestamp.mod(minEpochTimeIntervalSec) >= epochWindowOffsetSec &&
            block.timestamp.mod(minEpochTimeIntervalSec) < (epochWindowOffsetSec.add(epochWindowLengthSec))
        );
    }

    /**
     * @notice Sets the parameters which control the timing and frequency of
     *         Epoch operations.
     *         a) the minimum time period that must elapse between Epoch cycles.
     *         b) the Epoch window offset parameter.
     *         c) the Epoch window length parameter.
     * @param minEpochTimeIntervalSec_ More than this much time must pass between Epoch
     *        operations, in seconds.
     * @param EpochWindowOffsetSec_ The number of seconds from the beginning of
              the Epoch interval, where the Epoch window begins.
     * @param EpochWindowLengthSec_ The length of the Epoch window in seconds.
     */
    function setEpochTimingParameters(
        uint256 minEpochTimeIntervalSec_,
        uint256 EpochWindowOffsetSec_,
        uint256 EpochWindowLengthSec_)
        external
        onlyOwner
    {
        require(minEpochTimeIntervalSec_ > 0);
        require(EpochWindowOffsetSec_ < minEpochTimeIntervalSec_);

        minEpochTimeIntervalSec = minEpochTimeIntervalSec_;
        epochWindowOffsetSec = EpochWindowOffsetSec_;
        epochWindowLengthSec = EpochWindowLengthSec_;
    }

    /**
     * @notice Call epoch to distribure perf pool ubxt to users 
     * this method will call in every 12 hours at fixed time
     */
    function distributePerfPoolRewards() public onlyOwner {
        require(inEpochWindow(), "Can not call epoch that time");

        // This comparison also ensures there is no reentrancy.
        require(lastEpochTimestampSec.add(minEpochTimeIntervalSec) < now, "Epoch will call after some time");

        // Snap the Epoch time to the start of this window.
        uint256 ubxtBal = IERC20(token).balanceOf(perfPool);
        IERC20(token).transferFrom(perfPool, address(this), ubxtBal);

        epoch = epoch.add(1);
    }

    // updated Perf pool address
    function updatePerfPoolAddress(address _perfPoolAddress) public onlyOwner {
        perfPool = _perfPoolAddress;
    }

    // updated treasury address
    function updateTreasuryAddress(address _treasuryAddress) public onlyOwner {
        treasuryAddress = _treasuryAddress;
    }
    
    // update withdraw fee
    function updateWithdrawFee(uint256 _withdrawFee) public onlyOwner {
        withdrawFee = _withdrawFee;
    }

    // update token per block value
    function updateTokenPerBlock(uint256 _tokenPerBlock) public onlyOwner {
        massUpdatePools();
        tokenPerBlock = _tokenPerBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                lastUBXTTotalReward: 0,
                accTokenPerShare: 0,
                ubxtAccRewardPerShare: 0
            })
        );
    }

    // Update the given pool's TOKEN allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        pure
        returns (uint256)
    {
        return _to.sub(_from);
    }

    // View function to see pending TOKENs on frontend.
    function pendingToken(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accTokenPerShare = pool.accTokenPerShare;
        uint256 lpSupply;
        if(_pid == 0)
            lpSupply = totalStakedUBXT;
        else
            lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number);
            uint256 tokenReward =
                multiplier.mul(tokenPerBlock).mul(pool.allocPoint).div(
                    totalAllocPoint
                );
            accTokenPerShare = accTokenPerShare.add(
                tokenReward.mul(1e12).div(lpSupply)
            );
        }
        return user.amount.mul(accTokenPerShare).div(1e12).sub(user.rewardDebt);
    }
    
    /**
     * @return Return total earned UBXT token for staked time period
     * @param _user User address
     */
    function pendingUBXTReward(address _user) external view returns (uint256) 
    {
        uint256 _poolId = 0;
        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage user = userInfo[_poolId][_user];
        uint256 accRewardPerShare = pool.ubxtAccRewardPerShare;
        uint256 supply = totalStakedUBXT;
        
        uint256 balance = IERC20(token).balanceOf(address(this)).sub(totalStakedUBXT);
        uint256 _totalReward = totalUBXTReward;
        if (balance > lastUBXTRewardBalance) {
            _totalReward = _totalReward.add(balance.sub(lastUBXTRewardBalance));
        }
        if (_totalReward > pool.lastUBXTTotalReward && supply != 0) {
            uint256 reward = _totalReward.sub(pool.lastUBXTTotalReward).mul(100).div(100);
            accRewardPerShare = accRewardPerShare.add(reward.mul(1e12).div(supply));
        }
    
        return user.amount.mul(accRewardPerShare).div(1e12).sub(user.rewardUBXTDebt);
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        
        uint256 ubxtRewardBalance = IERC20(token).balanceOf(address(this)).sub(totalStakedUBXT);
        uint256 _totalUBXTReward = totalUBXTReward.add(ubxtRewardBalance.sub(lastUBXTRewardBalance));
        lastUBXTRewardBalance = ubxtRewardBalance;
        totalUBXTReward = _totalUBXTReward;
        
        uint256 lpSupply;
        if(_pid == 0)
            lpSupply = totalStakedUBXT;
        else
            lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            pool.lastUBXTTotalReward = _totalUBXTReward;
            return;
        }
        
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 tokenReward =
            multiplier.mul(tokenPerBlock).mul(pool.allocPoint).div(
                totalAllocPoint
            );
        pool.accTokenPerShare = pool.accTokenPerShare.add(
            tokenReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
        
        if(_pid == 0 && lpSupply != 0) {
            uint256 ubxtReward = _totalUBXTReward.sub(pool.lastUBXTTotalReward).mul(100).div(100);
            pool.ubxtAccRewardPerShare = pool.ubxtAccRewardPerShare.add(ubxtReward.mul(1e12).div(lpSupply));
            pool.lastUBXTTotalReward = _totalUBXTReward;
        } else {
            pool.ubxtAccRewardPerShare = 0;
            pool.lastUBXTTotalReward = 0;
            user.rewardUBXTDebt = 0;
        }
    }

    // Deposit LP TOKENs to UBXTStaking for TOKEN allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accTokenPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            if (_pid == 0) {
                uint256 ubxtPending = 
                user.amount.mul(pool.ubxtAccRewardPerShare).div(1e12).sub(
                    user.rewardUBXTDebt);
                safePerfPoolTokenTransfer(msg.sender, ubxtPending);                
            }
            safeTokenTransfer(msg.sender, pending);
        }
        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        if (_pid == 0)
            totalStakedUBXT = totalStakedUBXT.add(_amount);
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(1e12);
        user.rewardUBXTDebt = user.amount.mul(pool.ubxtAccRewardPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP TOKENs from UBXTStaking.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending =
            user.amount.mul(pool.accTokenPerShare).div(1e12).sub(
                user.rewardDebt
            );
        safeTokenTransfer(msg.sender, pending);
        
        if (_pid == 0) {
            uint256 ubxtPending = 
                user.amount.mul(pool.ubxtAccRewardPerShare).div(1e12).sub(
                    user.rewardUBXTDebt);
            safePerfPoolTokenTransfer(msg.sender, ubxtPending);                
        }
        user.amount = user.amount.sub(_amount);
        if (_pid == 0)
            totalStakedUBXT = totalStakedUBXT.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(1e12);
        user.rewardUBXTDebt = user.amount.mul(pool.ubxtAccRewardPerShare).div(1e12);
        uint256 withdrawFee_ = _amount.mul(withdrawFee).div(100000);
        _amount = _amount.sub(withdrawFee_);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        pool.lpToken.safeTransfer(address(treasuryAddress), withdrawFee_);
        emit Withdraw(msg.sender, _pid, _amount.add(withdrawFee_));
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 _amount = user.amount;
        uint256 withdrawFee_ = _amount.mul(withdrawFee).div(100000);
        _amount = _amount.sub(withdrawFee_);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        pool.lpToken.safeTransfer(address(treasuryAddress), withdrawFee_);
        if (_pid == 0)
            totalStakedUBXT = totalStakedUBXT.sub(user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
        user.rewardUBXTDebt = 0;
    }

    // Safe token transfer function, just in case if rounding error causes pool to not have enough TOKENs.
    function safeTokenTransfer(address _to, uint256 _amount) internal {
        uint256 tokenBal = totalLocked();
        if (_amount > tokenBal) {
            _lockedPool.transfer(_to, tokenBal);
        } else {
            _lockedPool.transfer(_to, _amount);
        }
    }
    
    // Safe token transfer function, just in case if rounding error causes pool to not have enough TOKENs.
    function safePerfPoolTokenTransfer(address _to, uint256 _amount) internal {
        uint256 tokenBal = IERC20(token).balanceOf(address(this));
        if (_amount > tokenBal) {
            IERC20(token).transfer(_to, tokenBal);
        } else {
            IERC20(token).transfer(_to, _amount);
        }
        lastUBXTRewardBalance = IERC20(token).balanceOf(address(this)).sub(totalStakedUBXT);
    }

    // Emergency Withdraw.
    function emergencyWithdrawToken(address _to, uint256 _amount) public onlyOwner {
        uint256 tokenBal = IERC20(token).balanceOf(address(this));
        if (_amount > tokenBal) {
            IERC20(token).transfer(_to, tokenBal);
        } else {
            IERC20(token).transfer(_to, _amount);
        }
    }
}

pragma solidity ^0.6.12;

import "../common/Ownable.sol";
import "../common/IERC20.sol";

/**
 * @title A simple holder of tokens.
 * This is a simple contract to hold tokens. It's useful in the case where a separate contract
 * needs to hold multiple distinct pools of the same token.
 */
contract TokenPool is Ownable {
    IERC20 public token;

    constructor(IERC20 _token) public {
        Ownable.init(msg.sender);
        token = _token;
    }

    function balance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function transfer(address to, uint256 value) external onlyOwner returns (bool) {
        return token.transfer(to, value);
    }
}

// SPDX-License-Identifier: MIT!!!
pragma solidity ^0.6.12;

library SafeMath 
{
    function add(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
    {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) 
        {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
    {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
    {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.6.12;

import "./SafeMath.sol";
import "./Address.sol";
import "../common/IERC20.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for SIERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.6.12;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity ^0.6.12;

import "./Initializable.sol";

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable is Initializable {
    address private _owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
      address indexed previousOwner,
      address indexed newOwner
    );

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    function init(address sender) public initializer {
      _owner = sender;
    }

    /**
    * @return the address of the owner.
    */
    function owner() public view returns(address) {
      return _owner;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
      require(isOwner());
      _;
    }

    /**
    * @return true if `msg.sender` is the owner of the contract.
    */
    function isOwner() public view returns(bool) {
      return msg.sender == _owner;
    }

    /**
    * @dev Allows the current owner to relinquish control of the contract.
    * @notice Renouncing to ownership will leave the contract without an owner.
    * It will not be possible to call the functions with the `onlyOwner`
    * modifier anymore.
    */
    function renounceOwnership() public onlyOwner {
      emit OwnershipRenounced(_owner);
      _owner = address(0);
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
      _transferOwnership(newOwner);
    }

    /**
    * @dev Transfers control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function _transferOwnership(address newOwner) internal {
      require(newOwner != address(0));
      emit OwnershipTransferred(_owner, newOwner);
      _owner = newOwner;
    }

    uint256[50] private ______gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.24 <0.7.0;

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {
    /**
    * @dev Indicates that the contract has been initialized.
    */
    bool private initialized;

    /**
    * @dev Indicates that the contract is in the process of being initialized.
    */
    bool private initializing;

    /**
    * @dev Modifier to use in the initializer function of a contract.
    */
    modifier initializer() {
      require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

      bool isTopLevelCall = !initializing;
      if (isTopLevelCall) {
        initializing = true;
        initialized = true;
      }

      _;

      if (isTopLevelCall) {
        initializing = false;
      }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
      // extcodesize checks the size of the code stored in an address, and
      // address returns the current address. Since the code is still not
      // deployed when running a constructor, any checks on its code size will
      // yield zero, making it an effective way to detect if a contract is
      // under construction or not.
      address self = address(this);
      uint256 cs;
      assembly { cs := extcodesize(self) }
      return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

pragma solidity ^0.6.12;

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
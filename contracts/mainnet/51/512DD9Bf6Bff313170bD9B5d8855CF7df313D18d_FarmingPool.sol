pragma solidity ^0.7.4;
// "SPDX-License-Identifier: Apache License 2.0"

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

import "./IReservoir.sol";

/**
 *  Based on Sushi MasterChef:
 *  https://github.com/sushiswap/sushiswap/blob/1e4db47fa313f84cd242e17a4972ec1e9755609a/contracts/MasterChef.sol
 *
 * SRS:
 * 1. Staking length 1 month.
 * 2. 0.3% daily staking.
 * 3. Body tokens are locked till the end of farm.
 * 4. Only 1 token in staking.
 */
contract FarmingPool {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of tokens
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accTokensPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accTokensPerShare` (and `lastReward`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;            // Address of LP token contract.
        uint256 allocPoint;        // How many allocation points assigned to this pool. Tokens to distribute per second.
        uint256 lastReward;        // Last timestamp that tokens distribution occurs.
        uint256 accTokensPerShare; // Accumulated tokens per share, times MULTIPLIER. See below.
    }

    // 10**18 multiplier.
    uint256 private constant DECIMALS_MLTPLR = 1e18;

    // Max pools total supply: 100,000,000.
    uint256 private constant MAX_POOLS_SUPPLY = 1e8 * DECIMALS_MLTPLR;

    // The REWARD TOKEN
    IERC20 public token;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;
    // The timestamp when token mining starts.
    uint256 public start;
    uint256 public end;
    address public owner;
    uint256 public lpSupplyState;

    // Token reservoir
    IReservoir public tokenReservoir;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        IERC20 _token,
        uint256 _startTimestamp,
        uint256[1] memory _allocPoints,
        IERC20[1] memory _lpTokens
    ) {
        token = _token;
        start = _startTimestamp;
        end = start.add(2629746);
        owner = msg.sender;

        // add pools
        _addPool(_allocPoints[0], _lpTokens[0]);
    }

    // Initialize tokenReservoir after creation (only once)
    function initializeTokenReservoir(IReservoir _tokenReservoir) external {
        require(tokenReservoir == IReservoir(0), "TokenReservoir has already been initialized");
        tokenReservoir = _tokenReservoir;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Return reward multiplier over the given _from to _to timestamp.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        uint256 curFrom = (_from < start) ? start : _from;
        uint256 curTo = (_to > end) ? end : _to;
        return curTo.sub(curFrom);
    }

    // View function to see pending tokens on frontend.
    function pendingTokens(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accTokensPerShare = pool.accTokensPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.timestamp > pool.lastReward && lpSupply != 0) {
            uint256 tokenReward = getMultiplier(pool.lastReward, block.timestamp).mul(rewardPerSecond(lpSupply));
            tokenReward = _availableTokens(tokenReward); // amount available for transfer
            accTokensPerShare = accTokensPerShare.add(tokenReward.mul(DECIMALS_MLTPLR).div(lpSupply));
        }
        return user.amount.mul(accTokensPerShare).div(DECIMALS_MLTPLR).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Safe gas costs: always 2 pools.
    function updatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            _updatePool(pid);
        }
    }

    // Deposit LP tokens to FarmingPool for token allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePools(); // safe gas costs: always 1 pool
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accTokensPerShare).div(DECIMALS_MLTPLR).sub(user.rewardDebt);
            if(pending > 0) {
                _safeTokenTransfer(msg.sender, pending);
            }
        }
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
            lpSupplyState += _amount;
        }
        user.rewardDebt = user.amount.mul(pool.accTokensPerShare).div(DECIMALS_MLTPLR);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from FarmingPool.
    function withdraw(uint256 _pid, uint256 _amount) public {
        require(block.timestamp > end, "Too early to withdraw");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePools(); // safe gas costs: always 1 pool
        uint256 pending = user.amount.mul(pool.accTokensPerShare).div(DECIMALS_MLTPLR).sub(user.rewardDebt);
        if(pending > 0) {
            _safeTokenTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
            lpSupplyState -= _amount;
        }
        user.rewardDebt = user.amount.mul(pool.accTokensPerShare).div(DECIMALS_MLTPLR);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        lpSupplyState -= amount;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Return available tokens on token reservoir.
    function _availableTokens(uint256 requestedTokens) internal view returns (uint256) {
        uint256 reservoirBalance = token.balanceOf(address(tokenReservoir));
        uint256 tokensAvailable = (requestedTokens > reservoirBalance)
            ? reservoirBalance
            : requestedTokens;

        return tokensAvailable;
    }

    // Update reward variables of the given pool to be up-to-date.
    function _updatePool(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastReward) {
            return;
        }
        uint256 lpSupply = lpSupplyState;
        if (lpSupply == 0) {
            pool.lastReward = block.timestamp;
            return;
        }
        uint256 tokenReward = getMultiplier(pool.lastReward, block.timestamp).mul(rewardPerSecond(lpSupply));
        tokenReward = tokenReservoir.drip(tokenReward); // transfer tokens from tokenReservoir
        pool.accTokensPerShare = pool.accTokensPerShare.add(tokenReward.div(lpSupply));
        pool.accTokensPerShare = pool.accTokensPerShare.add(tokenReward.mul(DECIMALS_MLTPLR).div(lpSupply));
        pool.lastReward = block.timestamp;
    }
    
    function rewardPerSecond(uint256 lpSupply) pure internal returns(uint256) {
        // 333 - for 0.3% per day.
        // 86400 - number of seconds in 1 day.
        return lpSupply.div(334).div(86400);
    }

    // Safe token transfer function, just in case if rounding error causes pool to not have enough tokens.
    function _safeTokenTransfer(address _to, uint256 _amount) internal {
        uint256 tokenBal = token.balanceOf(address(this));
        if (_amount > tokenBal) {
            token.transfer(_to, tokenBal);
        } else {
            token.transfer(_to, _amount);
        }
    }

        // Add a new lp to the pool.
    function _addPool(uint256 _allocPoint, IERC20 _lpToken) internal {
        uint256 lastReward = block.timestamp > start ? block.timestamp : start;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastReward: lastReward,
            accTokensPerShare: 0
        }));
    }
    
    function purge(uint256 amount) external {
        require(msg.sender == owner, "Only owner can call");
        token.transfer(owner, amount);
    }
}
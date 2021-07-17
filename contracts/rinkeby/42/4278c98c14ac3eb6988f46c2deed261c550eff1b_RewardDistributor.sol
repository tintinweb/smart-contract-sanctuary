// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract RewardDistributor is ERC20, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;      // How many LP tokens the user has provided.
        uint256 rewardDebt;  // Reward debt.
        uint256 reward;      // Distributed after deposit or withdraw.
        uint256 lastDeposit; // Last deposit timestamp.
    }

    // Info of LP pool.
    struct PoolInfo {
        IERC20 lpToken;            // Address of LP token contract.
        uint256 lastRewardBalance; // Last reward token balance that tokens distribution occurs.
        uint256 accTokensPerShare; // Accumulated tokens per share, times MULTIPLIER. See below.
    }

    // 10**18 multiplier.
    uint256 private constant MULTIPLIER = 1e18;

    // The REWARD TOKEN
    IERC20 public rewardToken;

    // Info of LP pool.
    PoolInfo public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(address => UserInfo) public userInfo;

    // Withdrawal timelock
    uint256 public constant MAX_TIMELOCK = 1 weeks;
    uint256 public timelock = 1 days;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event Claim(address indexed user, uint256 amount);

    constructor(
        string memory _name,
        string memory _symbol,
        IERC20 _rewardToken,
        IERC20 _lpToken
    ) ERC20(_name, _symbol) {
        rewardToken = _rewardToken;

        poolInfo = PoolInfo({
            lpToken: _lpToken,
            lastRewardBalance: 0,
            accTokensPerShare: 0
        });
    }

    // View function to see pending reward on frontend.
    function pendingReward(address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[_user];

        uint256 accTokensPerShare = pool.accTokensPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        uint256 rewardBalance = rewardToken.balanceOf(address(this));
        if (lpSupply != 0 && rewardBalance > pool.lastRewardBalance) {
            uint256 curReward = rewardBalance - pool.lastRewardBalance;
            accTokensPerShare += ((curReward * MULTIPLIER) / lpSupply);
        }

        return ((user.amount * accTokensPerShare) / MULTIPLIER) - user.rewardDebt + user.reward;
    }

    // Update reward state.
    function updatePool() public {
        PoolInfo storage pool = poolInfo;

        uint256 rewardBalance = rewardToken.balanceOf(address(this));
        if (rewardBalance <= pool.lastRewardBalance) {
            return;
        }

        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            return;
        }

        uint256 curReward = rewardBalance - pool.lastRewardBalance;
        pool.accTokensPerShare += ((curReward * MULTIPLIER) / lpSupply);
        pool.lastRewardBalance = rewardBalance;
    }

    // Deposit LP tokens to RewardDistributor and mint wrapped tokens.
    function deposit(uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[msg.sender];

        updatePool();

        if (user.amount > 0) {
            uint256 pending = ((user.amount * pool.accTokensPerShare) / MULTIPLIER) - user.rewardDebt;
            if (pending > 0) {
                user.reward += pending;
            }
        }

        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(msg.sender, address(this), _amount);

            // update states
            user.amount += _amount;
            user.lastDeposit = block.timestamp;

            // mint wrapped tokens
            _mint(msg.sender, _amount);
        }

        user.rewardDebt = (user.amount * pool.accTokensPerShare) / MULTIPLIER;
        emit Deposit(msg.sender, _amount);
    }

    // Withdraw LP tokens from RewardDistributor and burn wrapped tokens.
    function withdraw(uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[msg.sender];

        require(user.amount >= _amount, "withdraw: amount exceeds deposit");
        require(
            _amount == 0 || block.timestamp >= (user.lastDeposit + timelock),
            "withdraw: timelock is not over yet"
        );

        updatePool();

        uint256 pending = ((user.amount * pool.accTokensPerShare) / MULTIPLIER) - user.rewardDebt;
        if (pending > 0) {
            user.reward += pending;
        }

        if (_amount > 0) {
            user.amount -= _amount;

            // burn wrapped tokens
            _burn(msg.sender, _amount);

            pool.lpToken.safeTransfer(msg.sender, _amount);
        }

        user.rewardDebt = (user.amount * pool.accTokensPerShare) / MULTIPLIER;
        emit Withdraw(msg.sender, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() external nonReentrant {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[msg.sender];

        uint256 amount = user.amount;
        require(amount > 0, "emergencyWithdraw: no balance");
        require(
            block.timestamp >= (user.lastDeposit + timelock),
            "emergencyWithdraw: timelock is not over yet"
        );

        // reset user states
        user.amount = 0;
        user.rewardDebt = 0;
        user.reward = 0;

        // burn wrapped tokens
        _burn(msg.sender, amount);

        pool.lpToken.safeTransfer(msg.sender, amount);

        emit EmergencyWithdraw(msg.sender, amount);
    }

    // Claim rewards.
    function claim() external returns (uint256 reward) {
        // claim pending rewards
        withdraw(0);

        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[msg.sender];

        reward = user.reward;

        // transfer rewards
        if (reward > 0) {
            // update states
            pool.lastRewardBalance -= reward;
            user.reward = 0;

            _safeTokenTransfer(msg.sender, reward);
        }

        emit Claim(msg.sender, reward);
    }


    // *** ONLY OWNER functions ***

    function setTimelock(uint256 _timelock) external onlyOwner {
        require(_timelock <= MAX_TIMELOCK, "setTimelock: timelock is too long");
        timelock = _timelock;
    }

    function sweepTokens(IERC20 _token) external onlyOwner {
        require(
            _token != rewardToken && _token != poolInfo.lpToken,
            "sweepTokens: cannot sweep rewards or lp"
        );
        uint256 balance = _token.balanceOf(address(this));
        _token.safeTransfer(owner(), balance);
    }


    // *** INTERNAL functions ***

    // Safe reward token transfer function, just in case if rounding error causes pool to not have enough tokens.
    function _safeTokenTransfer(address _to, uint256 _amount) internal {
        uint256 tokenBal = rewardToken.balanceOf(address(this));
        if (_amount > tokenBal) {
            rewardToken.safeTransfer(_to, tokenBal);
        } else {
            rewardToken.safeTransfer(_to, _amount);
        }
    }
}
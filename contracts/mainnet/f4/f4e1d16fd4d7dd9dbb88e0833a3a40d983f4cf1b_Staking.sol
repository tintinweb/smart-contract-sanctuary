//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";


/**
 * @title Morphware Staking: Stake and earn rewards
 * @notice https://stake.morphware.org
 */
contract Staking is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    event Staked(address indexed user, uint256 amount);
    event Withdawn(address indexed user, uint256 amount);

    // Token to be staked
    IERC20 public stakingToken;

    // Total amount staked
    uint256 private _totalSupply;

    address public treasury;

    uint256 public stakingEnd = 1648746000;
    // amount of rewards per token stored for each user
    // normally, this would be a fixed rate for all users
    // but with a tiered system & ability to stake multiple times during the staking period,
    // we have to calculate this differently for individual users
    mapping(address => uint256) private rewardsPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;

    // last update timestamp for individual users
    mapping(address => uint256) public lastUpdateTime;

    // User balances of staked token
    mapping(address => uint256) private _balances;

    // Amount that a user has earned
    mapping(address => uint256) private rewards;

    constructor(address _stakingToken) {
        stakingToken = IERC20(_stakingToken);
        treasury = msg.sender;
    }

    modifier updateReward(address account) {
        rewardsPerTokenStored[account] = rewardPerToken(account);
        lastUpdateTime[account] = lastTimeRewardApplicable();

        rewards[account] = earned(account);
        userRewardPerTokenPaid[account] = rewardsPerTokenStored[account];
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < stakingEnd ? block.timestamp : stakingEnd;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function rewardPerToken(address account) public view returns (uint) {
        if (_totalSupply == 0 || lastUpdateTime[account] == 0) {
            return 0;
        }
        return
            rewardsPerTokenStored[account] +
            ((lastTimeRewardApplicable() - lastUpdateTime[account]) * getRewardRate(_balances[account]));
    }

    function earned(address account) public view returns (uint) {
        return
            _balances[account]
            .mul(rewardPerToken(account).sub(userRewardPerTokenPaid[account]))
            .div(1e18)
            .add(rewards[account]);
    }

    function stake(uint256 amount) external nonReentrant whenNotPaused updateReward(msg.sender) {
        require(amount > 0, "STAKE MUST BE GREATER THAN 0");
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        emit Staked(msg.sender, amount);
    }

    function withdrawStakeAndRewards() external nonReentrant whenNotPaused updateReward(msg.sender) {
        _totalSupply = _totalSupply.sub(_balances[msg.sender]);
        (uint256 staked, uint256 accruedRewards) = calculateWithdrawal(msg.sender);
        _balances[msg.sender] = 0;
        rewards[msg.sender] = 0;
        stakingToken.safeTransfer(msg.sender, staked);
        stakingToken.safeTransferFrom(treasury, msg.sender, accruedRewards);
        emit Withdawn(msg.sender, staked +  accruedRewards);
    }

    function calculateWithdrawal(address account) internal view returns(uint256 staked, uint256 accruedRewards) {
        return (_balances[account], rewards[account]);
    }

    function getTierPercentage(uint256 balance) internal pure returns (uint256) {
        if (balance >= 1000000*1e18) return 24;
        if (balance >= 500000*1e18) return 8;
        if (balance >= 1) return 4;
        return 0;
    }

    function getRewardRate(uint256 balance) internal pure returns (uint256) {
        return getTierPercentage(balance) * 1e18/ (365 * 24 * 3600);
    }

    function pauseStaking() public onlyOwner {
        _pause();
    }

    function unpauseStaking() public onlyOwner {
        _unpause();
    }
}
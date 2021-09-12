// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./Ownable.sol";
import "./Math.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";

// https://docs.synthetix.io/contracts/source/contracts/stakingrewards
contract StakingRewards is ReentrancyGuard, Pausable, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    IERC20 public TKN;
    uint256 public rewardRateNumerator = 11450; //for 14.5%
    uint256 constant private REWARD_RATE_DENOMINATOR = 10000;

    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    
    mapping(address => uint256) private _balances;
    mapping(address => bool) private isUser;
    mapping(address => uint256) private lastUpdateTime;
    mapping(address => uint256) private userIndex; 
    address[] private users;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _owner,
        address _TKN
    ) {
        TKN = IERC20(_TKN);

        transferOwnership(_owner);
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }
    function earned(address account) public view returns (uint256) {
        return rewardRateNumerator * _balances[account] * (block.timestamp - lastUpdateTime[account]) / (30 days) / REWARD_RATE_DENOMINATOR;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 amount) external nonReentrant whenNotPaused updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        require(_totalSupply.add(amount) * rewardRateNumerator / REWARD_RATE_DENOMINATOR < TKN.balanceOf(address(this)), "Cannot stake, cause not enough reward tokens on the staking contract");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        TKN.safeTransferFrom(msg.sender, address(this), amount);
        if (!isUser[msg.sender]){
            users.push(msg.sender);
            userIndex[msg.sender] = users.length - 1;
            isUser[msg.sender] = true;
        }
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        TKN.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            TKN.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit() external {
        withdraw(_balances[msg.sender]);
        getReward();
        users[userIndex[msg.sender]] = users[users.length - 1];
        userIndex[users[users.length - 1]] = userIndex[msg.sender];
        users.pop();
        isUser[msg.sender] = false;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardRate(uint256 _rewardRateNumerator) external onlyOwner updateReward(address(0)){
        require(TKN.balanceOf(address(this)) > _totalSupply * _rewardRateNumerator / REWARD_RATE_DENOMINATOR, "Cant set new rewardRate cause balance is low");
        rewardRateNumerator = _rewardRateNumerator;
        emit RewardRateChanged(rewardRateNumerator);
    }

    // Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
    function recoverERC20(uint256 tokenAmount) external onlyOwner {
        require(tokenAmount + _totalSupply < (TKN.balanceOf(address(this))), "Cannot withdraw the staking tokens");
        TKN.safeTransfer(owner(), tokenAmount);
        emit Recovered(tokenAmount);
    }

    function setPaused(bool _p) external onlyOwner {
        if (_p) {
            _pause();
        } else {
            _unpause();
        }
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        if (account != address(0)) {
            rewards[account] += earned(account);
            lastUpdateTime[account] = block.timestamp;
        }
        else {
            for (uint i = 0; i < users.length; i++){
                if(_balances[users[i]] != 0){
                    rewards[users[i]] += earned(users[i]);
                    lastUpdateTime[users[i]] = block.timestamp;
                }
            }
        }
        _;
    }

    /* ========== EVENTS ========== */

    event RewardRateChanged(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(uint256 amount);
}
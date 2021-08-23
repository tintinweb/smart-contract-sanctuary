/**
 * Hibiki staking
 * Stake your $HIBIKI
 *
 * https://t.me/hibikifinance
 * https://hibiki.finance
 * 
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Auth.sol";
import "./IBEP20.sol";

contract HibikiStaking is Auth {

    struct Stake {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    address public stakingToken;
    address public rewardToken;

    uint256 public totalRealised;
    uint256 public totalStaked;

    mapping (address => Stake) public stakes;

	event Realised(address account, uint amount);
    event Staked(address account, uint amount);
    event Unstaked(address account, uint amount);

    constructor (address _stakingToken, address _rewardToken) Auth(msg.sender) {
        stakingToken = _stakingToken;
        rewardToken = _rewardToken;
    }

    uint256 _accuracyFactor = 10 ** 36;
    uint256 _rewardsPerLP;
    uint256 _lastContractBalance;

    function getTotalRewards() external view  returns (uint256) {
        return totalRealised + IBEP20(rewardToken).balanceOf(address(this));
    }

    function getCumulativeRewardsPerLP() external view returns (uint256) {
        return _rewardsPerLP;
    }

    function getLastContractBalance() external view returns (uint256) {
        return _lastContractBalance;
    }

    function getAccuracyFactor() external view returns (uint256) {
        return _accuracyFactor;
    }

    function getStake(address account) public view returns (uint256) {
        return stakes[account].amount;
    }

    function getRealisedEarnings(address staker) external view returns (uint256) {
        return stakes[staker].totalRealised; // realised gains plus outstanding earnings
    }

    function getUnrealisedEarnings(address staker) external view returns (uint256) {
        if(stakes[staker].amount == 0){ return 0; }

        uint256 stakerTotalRewards = stakes[staker].amount * getCurrentRewardsPerLP() / _accuracyFactor;
        uint256 stakerTotalExcluded = stakes[staker].totalExcluded;

        if (stakerTotalRewards <= stakerTotalExcluded) {
			return 0;
		}

        return stakerTotalRewards - stakerTotalExcluded;
    }

    function getCumulativeRewards(uint256 amount) public view returns (uint256) {
        return amount * _rewardsPerLP / _accuracyFactor;
    }

    function stake(uint amount) external {
        require(amount > 0);

        IBEP20(stakingToken).transferFrom(msg.sender, address(this), amount);

        _stake(msg.sender, amount);
    }

    function stakeFor(address staker, uint256 amount) external {
        require(amount > 0);

        IBEP20(stakingToken).transferFrom(msg.sender, address(this), amount);

        _stake(staker, amount);
    }

    function stakeAll() external {
        uint256 amount = IBEP20(stakingToken).balanceOf(msg.sender);
        require(amount > 0);

        IBEP20(stakingToken).transferFrom(msg.sender, address(this), amount);

        _stake(msg.sender, amount);
    }

    function unstake(uint amount) external {
        require(amount > 0);

        _unstake(msg.sender, amount);
    }

    function unstakeAll() external {
        uint256 amount = getStake(msg.sender);
        require(amount > 0);

        _unstake(msg.sender, amount);
    }

    function realise() external {
        _realise(msg.sender);
    }

    function _realise(address staker) internal {
        _updateRewards();

        uint amount = earnt(staker);

        if (getStake(staker) == 0 || amount == 0) {
            return;
        }

        stakes[staker].totalRealised += amount;
        stakes[staker].totalExcluded += amount;
        totalRealised += amount;

        IBEP20(rewardToken).transfer(staker, amount);

        _updateRewards();

        emit Realised(staker, amount);
    }

    function earnt(address staker) internal view returns (uint256) {
        if(stakes[staker].amount == 0){ return 0; }

        uint256 stakerTotalRewards = getCumulativeRewards(stakes[staker].amount);
        uint256 stakerTotalExcluded = stakes[staker].totalExcluded;

        if(stakerTotalRewards <= stakerTotalExcluded){ return 0; }

        return stakerTotalRewards - stakerTotalExcluded;
    }

    function _stake(address staker, uint256 amount) internal {
        require(amount > 0);

        _realise(staker);

        // add to current address' stake
        stakes[staker].amount += amount;
        stakes[staker].totalExcluded = getCumulativeRewards(stakes[staker].amount);
        totalStaked += amount;

        emit Staked(staker, amount);
    }

    function _unstake(address staker, uint256 amount) internal {
        require(stakes[staker].amount >= amount, "Insufficient Stake");

        _realise(staker); // realise staking gains

        // remove stake
        stakes[staker].amount -= amount;
        stakes[staker].totalExcluded = getCumulativeRewards(stakes[staker].amount);
        totalStaked -= amount;

        IBEP20(stakingToken).transfer(staker, amount);

        emit Unstaked(staker, amount);
    }

    function _updateRewards() internal  {
        uint tokenBalance = IBEP20(rewardToken).balanceOf(address(this));

        if (tokenBalance > _lastContractBalance && totalStaked != 0) {
            uint256 newRewards = tokenBalance - _lastContractBalance;
            uint256 additionalAmountPerLP = newRewards * _accuracyFactor / totalStaked;
            _rewardsPerLP += additionalAmountPerLP;
        }

        if (totalStaked > 0) {
			_lastContractBalance = tokenBalance;
		}
    }

    function getCurrentRewardsPerLP() public view returns (uint256 currentRewardsPerLP) {
        uint tokenBalance = IBEP20(rewardToken).balanceOf(address(this));
        if(tokenBalance > _lastContractBalance && totalStaked != 0){
            uint256 newRewards = tokenBalance - _lastContractBalance;
            uint256 additionalAmountPerLP = newRewards* _accuracyFactor / totalStaked;
            currentRewardsPerLP = _rewardsPerLP + additionalAmountPerLP;
        }
    }

    function setAccuracyFactor(uint256 newFactor) external authorized {
        _rewardsPerLP = _rewardsPerLP * newFactor / _accuracyFactor;
        _accuracyFactor = newFactor;
    }

    function emergencyUnstakeAll() external {
        require(stakes[msg.sender].amount > 0, "No Stake");

        IBEP20(stakingToken).transfer(msg.sender, stakes[msg.sender].amount);
        totalStaked -= stakes[msg.sender].amount;
        stakes[msg.sender].amount = 0;
    }

    function migrateStakingToken(address newToken) external authorized {
        IBEP20(newToken).transferFrom(msg.sender, address(this), totalStaked);
        assert(IBEP20(newToken).balanceOf(address(this)) == totalStaked);

        IBEP20(stakingToken).transfer(msg.sender, totalStaked);

        stakingToken = newToken;
    }
}
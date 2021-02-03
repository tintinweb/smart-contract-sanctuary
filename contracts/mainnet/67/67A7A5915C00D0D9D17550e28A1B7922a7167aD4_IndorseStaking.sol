pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol";

contract IndorseStaking is Ownable, ReentrancyGuard {

    using SafeMath for uint;

    /// @dev `Checkpoint` is the structure that attaches a block number to a
    ///  given value, the block number attached is the one that last changed the
    ///  value
    struct Checkpoint {

        // `fromBlock` is the block number that the value was generated from
        uint128 fromBlock;

        // `value` is the amount of tokens at a specific block number
        uint128 value;
    }

    // `balances` is the map that tracks the balance of each address, in this
    //  contract when the balance changes the block number that the change
    //  occurred is also included in the map
    mapping(address => Checkpoint[]) balances;

    function getCheckpoint(address _owner, uint _index)
    view
    external
    returns (
        uint128 fromBlock,
        uint128 value
    )
    {
        Checkpoint storage checkpoint_ = balances[_owner][_index];
        fromBlock = checkpoint_.fromBlock;
        value = checkpoint_.value;
    }

    // Tracks the history of the total delegations of the token
    Checkpoint[] totalSupplyHistory;

    struct Staker {
        uint stake;
        uint lastDepositAt;
        uint delegatedAmount;
        address delegatee;
    }

    mapping(address => Staker) public stakers;

    // Tracks sums of delegations for delegatees
    mapping(address => uint) public delegationSums;

    uint private constant GRANULARITY = 10e11;
    uint private constant NUMBER_OF_VARIABLE_REWARD_PERIODS = 59;

    IERC20 public tokenAddress = ERC20(0xf8e386EDa857484f5a12e4B5DAa9984E06E73705);
    address public indorseMultiSigHolder = 0xe27308bd67E07a5c0a899aa6632183CAb8c2818A;
    uint public rewardsPaid;
    uint public totalStake;
    uint public stakingStartBlock;
    uint public stakingRewardPeriodLength; //in blocks
    uint public stakingStartingReward;
    uint public stakingRewardDownwardStep;
    uint public delegationStakeRequirement;
    uint public totalVotingPower;

    constructor(uint _stakingRewardPeriodLength, uint _stakingStartingReward, uint _stakingRewardDownwardStep, uint _delegationStakeRequirement) public {
        stakingStartBlock = block.number;
        stakingRewardPeriodLength = _stakingRewardPeriodLength;
        stakingStartingReward = _stakingStartingReward;
        stakingRewardDownwardStep = _stakingRewardDownwardStep;
        delegationStakeRequirement = _delegationStakeRequirement;
        
    }

    function setDelegationStakeRequirement(uint _delegationStakeRequirement) external onlyOwner {
        delegationStakeRequirement = _delegationStakeRequirement;
    }

    function getRewardAtBlock(uint _stake, uint _lastDepositAt, uint _blockNumber) public view returns (uint reward)  {
        if(_stake == 0) {
            return 0;
        }

        uint depositingInterval = _lastDepositAt.sub(stakingStartBlock).div(stakingRewardPeriodLength);
        //0 is the first period
        uint currentInterval = _blockNumber.sub(stakingStartBlock).div(stakingRewardPeriodLength);

        uint lastVariableRewardInterval = currentInterval > NUMBER_OF_VARIABLE_REWARD_PERIODS ? NUMBER_OF_VARIABLE_REWARD_PERIODS : currentInterval;

        if (currentInterval > depositingInterval) {
            //first interval, A
            uint rewardAtFirstInterval = stakingStartingReward.sub((depositingInterval.mul(stakingRewardDownwardStep)));

            uint widthOfFirstIntervalSection = stakingStartBlock.add(depositingInterval.add(1).mul(stakingRewardPeriodLength)).sub(_lastDepositAt);

            reward = reward.add(rewardAtFirstInterval.mul(widthOfFirstIntervalSection));

            //last interval, C
            uint rewardAtLastInterval = stakingStartingReward.sub(lastVariableRewardInterval.mul(stakingRewardDownwardStep));

            uint widthOfLastIntervalSection = _blockNumber.sub(stakingStartBlock.add(lastVariableRewardInterval.mul(stakingRewardPeriodLength)));

            reward = reward.add(widthOfLastIntervalSection.mul(rewardAtLastInterval));

            if (lastVariableRewardInterval.sub(depositingInterval) > 1) {
                uint rewardAtPenultimateInterval = rewardAtLastInterval.add(stakingRewardDownwardStep);

                uint widthOfMiddleSections = (lastVariableRewardInterval.sub(depositingInterval).sub(1)).mul(stakingRewardPeriodLength);

                //middle intervals base, B
                reward = reward.add(rewardAtPenultimateInterval.mul(widthOfMiddleSections));

                //middle intervals triangle, B'
                uint rewardAtSecondInterval = rewardAtFirstInterval.sub(stakingRewardDownwardStep);

                reward.add(((rewardAtSecondInterval.sub(rewardAtPenultimateInterval)).mul(widthOfMiddleSections)).div(2));
            }
        } else {
            reward = reward.add(_blockNumber.sub(_lastDepositAt).mul(stakingStartingReward.sub(depositingInterval.mul(stakingRewardDownwardStep))));
        }

        reward = reward.mul(_stake);
        reward = reward.div(GRANULARITY);
    }

    //Adds the amount to the stake
    //If staker exists, it reaps the rewards and adds them to the stake as well
    function stake(uint _amount) external {
        // The tokens will be held in a Gnosis multisig contract for which the owners will be the Indorse board members
        require(tokenAddress.transferFrom(msg.sender, indorseMultiSigHolder, _amount), "Insufficient token balance");
        Staker storage staker = stakers[msg.sender];

        //New staker
        if (staker.stake == 0) {
            staker.stake = _amount;
            staker.lastDepositAt = block.number;
            totalStake = totalStake.add(_amount);
            //Existing staker - adding current reward to the stake
        } else {
            uint reward = getRewardAtBlock(staker.stake, staker.lastDepositAt, block.number);
            staker.stake = staker.stake.add(_amount.add(reward));
            rewardsPaid = rewardsPaid.add(reward);
            totalStake = totalStake.add(_amount).add(reward);
            staker.lastDepositAt = block.number;
        }
    }

    function delegate(uint _amount, address _delegatee) external {
        Staker storage staker = stakers[msg.sender];

        Staker storage delegateeStaker = stakers[_delegatee];

        require(delegateeStaker.stake >= delegationStakeRequirement, "Delegator does not meet staking requirement.");
        require(_amount > 0, "Amount cannot equal 0.");
        require(_amount <= staker.stake, "Amount must be lesser or equal to the stake.");

        if (staker.delegatee != _delegatee) {
            //New delegation
            if (staker.delegatedAmount != 0) {
                //Undelegating previous delegation
                delegationSums[staker.delegatee] = delegationSums[staker.delegatee].sub(staker.delegatedAmount);
                updateValueAtNow(balances[staker.delegatee], delegationSums[staker.delegatee]);
                totalVotingPower = totalVotingPower.sub(staker.delegatedAmount);
            }

            delegationSums[_delegatee] = delegationSums[_delegatee].add(_amount);
            totalVotingPower = totalVotingPower.add(_amount);
            staker.delegatee = _delegatee;
        } else if (staker.delegatedAmount != 0 && staker.delegatee == _delegatee) {
            //Changing the delegated amount
            if (_amount < staker.delegatedAmount) {
                //Decreasing delegation
                delegationSums[_delegatee] = delegationSums[_delegatee].sub(staker.delegatedAmount.sub(_amount));
                totalVotingPower = totalVotingPower.sub(staker.delegatedAmount.sub(_amount));
            } else {
                //Increasing delegation
                delegationSums[_delegatee] = delegationSums[_delegatee].add(_amount.sub(staker.delegatedAmount));
                totalVotingPower = totalVotingPower.add(_amount.sub(staker.delegatedAmount));
            }
        }

        staker.delegatedAmount = _amount;

        updateValueAtNow(balances[_delegatee], delegationSums[_delegatee]);
        updateValueAtNow(totalSupplyHistory, totalVotingPower);
    }

    function undelegate() external {
        Staker storage staker = stakers[msg.sender];
        _undelegate(staker);
    }

    //Withdraws the entire stake and rewards
    function claimAndWithdraw() external nonReentrant {
        Staker storage staker = stakers[msg.sender];
        if (staker.stake == 0) {
            return;
        }

        uint reward = getRewardAtBlock(staker.stake, staker.lastDepositAt, block.number);
        totalStake = totalStake.sub(staker.stake);
        rewardsPaid = rewardsPaid.add(reward);
        require(tokenAddress.transferFrom(indorseMultiSigHolder, msg.sender, staker.stake.add(reward)));
        staker.stake = 0;

        if (staker.delegatedAmount != 0) {
            _undelegate(staker);
        }
    }

    //Withdraw without reward, reward is lost
    function withdraw() external nonReentrant {
        Staker storage staker = stakers[msg.sender];

        if (staker.stake == 0) {
            return;
        }

        totalStake = totalStake.sub(staker.stake);
        require(tokenAddress.transferFrom(indorseMultiSigHolder, msg.sender, staker.stake));
        staker.stake = 0;

        if (staker.delegatedAmount != 0) {
            _undelegate(staker);
        }
    }

    //Transfers the accumulated rewards to sender, leaves the principal untouched
    function claim() external nonReentrant {
        Staker storage staker = stakers[msg.sender];

        if(staker.stake == 0) {
            return;
        }

        uint reward = getRewardAtBlock(staker.stake, staker.lastDepositAt, block.number);
        require(tokenAddress.transferFrom(indorseMultiSigHolder, msg.sender, reward));
        rewardsPaid = rewardsPaid.add(reward);
        staker.lastDepositAt = block.number;
    }

    //Add current reward to stake
    //Can move it to a separate function, make clearing all delegations a prerequisite for withdrawal
    function claimAndStake() external {
        Staker storage staker = stakers[msg.sender];

        if (staker.stake == 0) {
            return;
        }

        uint reward = getRewardAtBlock(staker.stake, staker.lastDepositAt, block.number);
        totalStake = totalStake.add(reward);
        rewardsPaid = rewardsPaid.add(reward);
        staker.stake = staker.stake.add(reward);
        staker.lastDepositAt = block.number;
    }

    function getStaker(address _addr)
    external
    view
    returns (
        uint stake_,
        uint lastDepositAt_,
        uint delegatedAmount_,
        address delegatee_
    )
    {
        Staker storage staker_ = stakers[_addr];

        stake_ = staker_.stake;
        lastDepositAt_ = staker_.lastDepositAt;
        delegatedAmount_ = staker_.delegatedAmount;
        delegatee_ = staker_.delegatee;
    }

    function getStake(address _addr) external view returns (uint) {
        return stakers[_addr].stake;
    }

    function getLastDepositAt(address _addr) external view returns (uint) {
        return stakers[_addr].lastDepositAt;
    }

    function getDelegatee(address _addr) external view returns (address) {
        return stakers[_addr].delegatee;
    }

    function getDelegatedAmount(address _addr) external view returns (uint) {
        return stakers[_addr].delegatedAmount;
    }

    /// @notice Total amount of tokens at a specific `_blockNumber`.
    /// @param _blockNumber The block number when the totalSupply is queried
    /// @return The total amount of tokens at `_blockNumber`
    function totalSupplyAt(uint _blockNumber) external view returns (uint) {
        return getValueAt(totalSupplyHistory, _blockNumber);
    }

    /// @dev Queries the balance of `_owner` at a specific `_blockNumber`
    /// @param _owner The address from which the balance will be retrieved
    /// @param _blockNumber The block number when the balance is queried
    /// @return The balance at `_blockNumber`
    function balanceOfAt(address _owner, uint _blockNumber) external view returns (uint) {
        return getValueAt(balances[_owner], _blockNumber);
    }

    /// @dev `getValueAt` retrieves the number of tokens at a given block number
    /// @param checkpoints The history of values being queried
    /// @param _block The block number to retrieve the value at
    /// @return The number of tokens being queried
    function getValueAt(Checkpoint[] storage checkpoints, uint _block) view internal returns (uint) {
        if (checkpoints.length == 0)
            return 0;

        // Shortcut for the actual value
        if (_block >= checkpoints[checkpoints.length - 1].fromBlock)
            return checkpoints[checkpoints.length - 1].value;
        if (_block < checkpoints[0].fromBlock)
            return 0;

        // Binary search of the value in the array
        uint min = 0;
        uint max = checkpoints.length - 1;
        while (max > min) {
            uint mid = (max + min + 1) / 2;
            if (checkpoints[mid].fromBlock <= _block) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }
        return checkpoints[min].value;
    }

    /// @dev `updateValueAtNow` used to update the `balances` map and the
    ///  `totalSupplyHistory`
    /// @param checkpoints The history of data being updated
    /// @param _value The new number of tokens
    function updateValueAtNow(Checkpoint[] storage checkpoints, uint _value) internal {
        if ((checkpoints.length == 0) || (checkpoints[checkpoints.length.sub(1)].fromBlock < block.number)) {
            Checkpoint storage newCheckPoint = checkpoints[checkpoints.length++];
            newCheckPoint.fromBlock = uint128(block.number);
            newCheckPoint.value = uint128(_value);
        } else {
            Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length.sub(1)];
            oldCheckPoint.value = uint128(_value);
        }
    }

    function _undelegate(Staker storage _staker) internal {
        require(_staker.delegatedAmount > 0, "There is no delegation to un-delegate.");

        delegationSums[_staker.delegatee] = delegationSums[_staker.delegatee].sub(_staker.delegatedAmount);
        updateValueAtNow(balances[_staker.delegatee], delegationSums[_staker.delegatee]);

        totalVotingPower = totalVotingPower.sub(_staker.delegatedAmount);
        updateValueAtNow(totalSupplyHistory, totalVotingPower);

        _staker.delegatedAmount = 0;
        _staker.delegatee = address(0);
    }
}
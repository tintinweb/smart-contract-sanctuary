//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title A staking contract for Envoy tokens
 * @author Kasper De Blieck ([email protected])
 * This contract allows Envoy token owners to stake their funds.
 * Staking funds will reward a periodic compounded interest.
 */
contract EnvoyStaking is Ownable {
    
    using SafeMath for uint;

    /**
    Emits when a config field is updated
    @param field_ of the field
    @param value_ new value of the field
     */
    event ConfigUpdate(string field_, uint value_);
    /**
    Emits when new address stakes
    @param stakeholder_ address of the stakeholder
    @param stake_ new amount of staked tokens
     */
    event Staking(address indexed stakeholder_, uint stake_);
    /**
    Emits when stakeholder claims rewards
    @param stakeholder_ address of the stakeholder
    @param reward_ reward claimed
    @param lockedReward_ amount of additional reward that is locked
    @param numberOfPeriods_ number of periods rewarded
     */
    event Rewarding(address indexed stakeholder_, uint reward_, uint lockedReward_, uint numberOfPeriods_);
    /**
     Emits when a stakeholder requested a withdrawal
     @param stakeholder_ address of the stakeholder
     @param amount_ amount of tokens withdrawn from the contract 
     @param releaseDate_ timestamp when cooldown is over for the user  
     */
    event InitiateWithdraw(address stakeholder_, uint amount_, uint releaseDate_);
    /**
     Emits when a stakeholder finalizes a withdrawal
     @param stakeholder_ address of the stakeholder
     @param amount_ amount of tokens sent to the stakeholder
     @param fee_ fee paid for early withdrawal
     */
    event Withdraw(address stakeholder_, uint amount_, uint fee_);
    /**
     Emits when a new staker enters the contract by staking or existing stakeholder leaves by withdrawing
     @param stakeholder_ address of the stakeholder
     @param active_ yes if the staker becomes active, false if inactive
     */
    event Active(address stakeholder_, bool active_);

    /** @return Stakeholder Struct containing the state of each stakeholder */
    struct StakeHolder {
        uint stakingBalance; // Staking balance of the stakeholder
        uint weight; // The weight of the staker
        uint startDate; // The date the staker joined
        uint lastClaimed; // The date the stakeholder claimed the last rewards
        uint releaseDate; // Date on which the stakeholder is able to withdraw the staked funds
        uint releaseAmount; // Amount to be released at the release date
        uint newStake; // Will be used to update the stake of the user in the next period
        uint lockedRewards; // Extra reward claimable after additional time has passed
    }

    /** @return RewardPeriod Struct containing the state of each reward period.*/
    struct RewardPeriod {
        uint rewardPerPeriod; // amount to distribute over stakeholders
        uint extraRewardMultiplier; // Used to calculate the extra reward on each reward (will be divided by 10**6)
        uint maxWeight; // Highest weight observed in the period
        mapping (uint => uint) totalStakingBalance; // Mapping weight to stake amount of tokens staked
        mapping (uint => uint) totalNewStake; // Tokens staked in this period to be added in the next one.
        // mapping (uint => uint) rewardsClaimed; // Mapping weight to rewards claimed with this weight of tokens staked
    }

    // Keeps track of user information by mapping the stakeholder address to his state */
    mapping(address => StakeHolder) public stakeholders;

    // Keeps track of the different reward intervals, sequentially */
    mapping (uint => RewardPeriod) public rewardPeriods;

    // How many reward periods are handled */
    uint public latestRewardPeriod; // How many reward periods are handled
    mapping (uint => uint) public totalLockedRewards; // Total amount of locked rewards
    mapping (uint => uint) public weightCounts; // counts of stakers per weight

    // Address used to verify users updating weight
    address public signatureAddress;

    IERC20 public stakingToken;

    uint public startDate; // Used to calculate how many periods have passed
    uint public maxNumberOfPeriods; // Used to cap the end date in the reward calculation
    uint public rewardPeriodDuration; // Length in between reward distribution
    uint public periodsForExtraReward; // Interval after which stakers get an extra reward
    uint public cooldown; // Length between withdrawal request and withdrawal without fee is possible
    uint public earlyWithdrawalFee; // Fee penalising early withdrawal, percentage times 10**6
    address payable public wallet; // address used to withdraw funds as owner

    // Fields needed for displaying total tokens share as ERC20 compatibility token
    string public name = "Staked ENV"; 
    string public symbol = "sENV";
    uint public decimals = 18;

    /**
     Sets a number of initial state variables
     */
    constructor(
                uint maxNumberOfPeriods_, // Used to cap the end date in the reward calculation
                uint rewardPeriodDuration_, // Length in between reward distribution
                uint periodsForExtraReward_, // Length in between reward distribution
                uint extraRewardMultiplier_,
                uint cooldown_,
                uint rewardPerPeriod_,
                uint earlyWithdrawalFee_,
                address payable wallet_,
                address signatureAddress_,
                address stakingTokenAddress) {
        maxNumberOfPeriods = maxNumberOfPeriods_;
        rewardPeriodDuration = rewardPeriodDuration_;
        periodsForExtraReward = periodsForExtraReward_;
        cooldown = cooldown_;
        earlyWithdrawalFee = earlyWithdrawalFee_;

        wallet = wallet_;
        signatureAddress = signatureAddress_;
        stakingToken = IERC20(stakingTokenAddress);

        startDate = block.timestamp;            
        
        // Initialise the first reward period in the sequence
        rewardPeriods[0].rewardPerPeriod = rewardPerPeriod_;
        rewardPeriods[0].extraRewardMultiplier = extraRewardMultiplier_;
    }

    /**
     * Calculates the staking balance for a certain period.
     * Can provide the current balance or balance to be added next period.
     * Also weighted (or multiple weighted) balances can be returned
     * @param period The period for which to call the balance
     * @param weightExponent How many times does the stake need to be multiplied with the weight?
     * @param newStake Does the current value or new value need to be displayed?
     * @return totalStaking the total amount staked for the parameters.
     */
    function totalStakingBalance(uint period, uint weightExponent, bool newStake) public view returns (uint totalStaking){
        for(uint i = 0; i <= rewardPeriods[period].maxWeight; i++){
            if(newStake){
                totalStaking += rewardPeriods[period].totalNewStake[i] * (i+1) ** weightExponent;
            } else
            {
                totalStaking += rewardPeriods[period].totalStakingBalance[i] * (i+1) ** weightExponent;
            }
        }
    }
    
    // /**
    //  * Calculates the total rewards for a period.
    //  * @param period the period to calculate rewards for
    //  * @param weightExponent How many times does the stake need to be multiplied with the weight?
    //  * @return totalRewards the total rewards
    //  */
    // function rewards(uint period, uint weightExponent) public view returns (uint totalRewards){
    //     for(uint i = 0; i <= rewardPeriods[period].maxWeight; i++){
    //         totalRewards += rewardPeriods[period].rewardsClaimed[i] * (i+1) ** weightExponent;
    //     }
    // }
    
    /**
     * Function to call when a new reward period is entered.
     * The function will increment the maxRewardPeriod field,
     * making the state of previous period immutable.
     * The state will use the state of the last period as start for the current period.
     * The total staking balance is updated with:
     * - stake added in previous period
     * - rewards earned in previous period
     * - locked tokens, if they are unlocked.
     * @param endPeriod the last period the function should handle.
     *  cannot exceed the current period.
     */
    function handleNewPeriod(uint endPeriod) public {
        // Don't update passed current period
        if(currentPeriod() < endPeriod ){
            endPeriod = currentPeriod();
        }
        // Close previous periods if in the past and create a new one
        while(latestRewardPeriod < endPeriod){
            latestRewardPeriod++;
            rewardPeriods[latestRewardPeriod].rewardPerPeriod = rewardPeriods[latestRewardPeriod-1].rewardPerPeriod;
            rewardPeriods[latestRewardPeriod].extraRewardMultiplier = rewardPeriods[latestRewardPeriod-1].extraRewardMultiplier;
            rewardPeriods[latestRewardPeriod].maxWeight = rewardPeriods[latestRewardPeriod-1].maxWeight;
            uint twsb = totalStakingBalance(latestRewardPeriod-1, 1, false);
            for(uint i = 0; i<=rewardPeriods[latestRewardPeriod-1].maxWeight;i++){
                rewardPeriods[latestRewardPeriod].totalStakingBalance[i] = rewardPeriods[latestRewardPeriod-1].totalStakingBalance[i] + rewardPeriods[latestRewardPeriod-1].totalNewStake[i];
                uint newReward = 0;
                if(twsb > 0 && rewardPeriods[latestRewardPeriod-1].totalStakingBalance[i] > 0){
                    newReward = (rewardPeriods[latestRewardPeriod-1].rewardPerPeriod * (i+1) + twsb)
                        * rewardPeriods[latestRewardPeriod-1].totalStakingBalance[i] / twsb
                        - rewardPeriods[latestRewardPeriod-1].totalStakingBalance[i];
                    rewardPeriods[latestRewardPeriod].totalStakingBalance[i] += newReward;

                }
                if(latestRewardPeriod % periodsForExtraReward == 1){
                    rewardPeriods[latestRewardPeriod].totalStakingBalance[i] += totalLockedRewards[i]
                            + newReward * rewardPeriods[latestRewardPeriod-1].extraRewardMultiplier / (10**6);
                    totalLockedRewards[i] = 0;
                } else {
                    totalLockedRewards[i] += newReward * rewardPeriods[latestRewardPeriod-1].extraRewardMultiplier / (10**6);
                }
            }
        }
    }

    /**
     * Increase the stake of the sender by a value.
     * @param weight_ The new weight.
     * @param signature A signature proving the sender
     *  is allowed to update his weight.
     */
    function increaseWeight(uint weight_, bytes memory signature) public{
        // Close previous period if in the past and create a new one, else update the latest one.
        handleNewPeriod(currentPeriod());
    
        address sender = _msgSender();

        // Verify the stakeholder was allowed to update stake
        require(signatureAddress == _recoverSigner(sender, weight_, signature),
            "Invalid sig");

        StakeHolder storage stakeholder = stakeholders[sender];
        require(weight_ > stakeholder.weight, "No weight increase");


        // Some updates are only necessary if the staker is active
        if(activeStakeholder(sender)){
            // Claim previous rewards with old weight
            claimRewards(currentPeriod(), false);

            // Update the total weighted amount of the current period.
            rewardPeriods[latestRewardPeriod].totalStakingBalance[stakeholder.weight] -= stakeholder.stakingBalance;
            rewardPeriods[latestRewardPeriod].totalStakingBalance[weight_] += stakeholder.stakingBalance;
            rewardPeriods[latestRewardPeriod].totalNewStake[stakeholder.weight] -= stakeholder.newStake;
            rewardPeriods[latestRewardPeriod].totalNewStake[weight_] += stakeholder.newStake;

            // Move locked rewards so they will be added to the correct total stake
            totalLockedRewards[stakeholder.weight] -= stakeholder.lockedRewards;
            totalLockedRewards[weight_] += stakeholder.lockedRewards;
        
            weightCounts[stakeholder.weight]--;
            weightCounts[weight_]++;

            // Keep track of highest weight
            if(weight_ > rewardPeriods[latestRewardPeriod].maxWeight){
                rewardPeriods[latestRewardPeriod].maxWeight = weight_;
            }

        }

        // Finally, set the new weight
        stakeholder.weight = weight_;


    }

    /**
     * Update the stake of a list of stakeholders as owner.
     * @param stakeholders_ The stakeholders
     * @param weights_ The new weights.
     *  is allowed to update his weight.
     */
    function updateWeightBatch(address[] memory stakeholders_, uint[] memory weights_) public onlyOwner{

        require(stakeholders_.length == weights_.length, "Length mismatch");

        // Close previous period if in the past and create a new one, else update the latest one.
        handleNewPeriod(currentPeriod());
        claimRewardsAsOwner(stakeholders_);

        for(uint i = 0; i < stakeholders_.length; i++){


            StakeHolder storage stakeholder = stakeholders[stakeholders_[i]];
            if(weights_[i] == stakeholder.weight){continue;}


            // Some updates are only necessary if the staker is active
            if(activeStakeholder(stakeholders_[i])){

                // Update the total weighted amount of the current period.
                rewardPeriods[latestRewardPeriod].totalStakingBalance[stakeholder.weight] -= stakeholder.stakingBalance;
                rewardPeriods[latestRewardPeriod].totalStakingBalance[weights_[i]] += stakeholder.stakingBalance;
                rewardPeriods[latestRewardPeriod].totalNewStake[stakeholder.weight] -= stakeholder.newStake;
                rewardPeriods[latestRewardPeriod].totalNewStake[weights_[i]] += stakeholder.newStake;
                
                // Move locked rewards so they will be added to the correct total stake
                totalLockedRewards[stakeholder.weight] -= stakeholder.lockedRewards;
                totalLockedRewards[weights_[i]] += stakeholder.lockedRewards;
                
                weightCounts[stakeholder.weight]--;
                weightCounts[weights_[i]]++;

                // Keep track of highest weight
                if(weights_[i] > rewardPeriods[latestRewardPeriod].maxWeight){
                    rewardPeriods[latestRewardPeriod].maxWeight = weights_[i];
                }
            
            }

            // Finally, set the new weight
            stakeholder.weight = weights_[i];

        }

        // Check if maxWeight decreased
        handleDecreasingMaxWeight();

    }

    /**
     * Increase the stake of the sender by a value.
     * @param amount The amount to stake
     */
    function stake(uint amount) public {
        // Close previous period if in the past and create a new one, else update the latest one.
        handleNewPeriod(currentPeriod());
        address sender = _msgSender();

        require(amount > 0, "Amount not positive");
        require(stakingToken.allowance(sender, address(this)) >= amount,
             "Token transfer not approved");

        // Transfer the tokens for staking
        stakingToken.transferFrom(sender, address(this), amount);

        // Update the stakeholders state
        StakeHolder storage stakeholder = stakeholders[sender];

        // Handle new staker
        if(activeStakeholder(sender) == false){
            if(stakeholder.weight > rewardPeriods[latestRewardPeriod].maxWeight){
                rewardPeriods[latestRewardPeriod].maxWeight = stakeholder.weight;
            }
            weightCounts[stakeholder.weight]++;
            stakeholder.startDate = block.timestamp;
            stakeholder.lastClaimed = currentPeriod();
            emit Active(sender, true);
        }

        // Claim previous rewards with old staked value
        claimRewards(currentPeriod(), false);

        // The current period will calculate rewards with the old stake.
        // Afterwards, newStake will be added to stake and calculation uses updated balance
        stakeholder.newStake = amount;

        // Update the totals
        // rewardPeriods[latestRewardPeriod].endDate = currentPeriod();
        rewardPeriods[latestRewardPeriod].totalNewStake[stakeholder.weight] += amount;
        
        emit Staking(sender, amount);

    }

    /**
     Request to withdrawal funds from the contract.
     The funds will not be regarded as stake anymore: no rewards can be earned anymore.
     The funds are not withdrawn directly, they can be claimed with `withdrawFunds`
     after the cooldown period has passed.
     @dev the request will set the releaseDate for the stakeholder to `cooldown` time in the future,
      and the releaseAmount to the amount requested for withdrawal.
     @param amount The amount to withdraw, capped by the total stake + owed rewards.
     @param instant If set to true, the `withdrawFunds` function will be called at the end of the request.
      No second transaction is needed, but the full `earlyWithdrawalFee` needs to be paid.
     @param claimRewardsFirst a boolean flag: should be set to true if you want to claim your rewards.
      If set to false, all owed rewards will be dropped. Build in for safety, funds can be withdrawn
      even when the reward calculations encounters a breaking bug.
     */
    function requestWithdrawal(uint amount, bool instant, bool claimRewardsFirst) public {
        address sender = _msgSender();
        StakeHolder storage stakeholder = stakeholders[sender];
        
        // If there is no cooldown, there is no need to have 2 separate function calls
        if(cooldown == 0){
            instant = true;
        }

        // Claim rewards with current stake
        // Can be skipped as failsafe in case claiming rewards fails,
        // but REWARDS ARE LOST.
        if (claimRewardsFirst){
            handleNewPeriod(currentPeriod());
            claimRewards(currentPeriod(), false);
        } else {
            stakeholder.lastClaimed = currentPeriod();
        }
        
        require(stakeholder.stakingBalance >= 0 || stakeholder.newStake >= 0, "Nothing was staked");
        
        // First, withdraw newstake.
        // If the amount exceeds this value, withdraw also from the staking balance.
        // If the amount exceeds both balance, cap at the sum of the values
        if(amount > stakeholder.newStake){
            if((amount - stakeholder.newStake) > stakeholder.stakingBalance){
                amount = stakeholder.stakingBalance + stakeholder.newStake;
                rewardPeriods[latestRewardPeriod].totalStakingBalance[stakeholder.weight] -= stakeholder.stakingBalance;
                stakeholder.stakingBalance = 0;
            } else {
                rewardPeriods[latestRewardPeriod].totalStakingBalance[stakeholder.weight] -= (amount - stakeholder.newStake);
                stakeholder.stakingBalance -= (amount - stakeholder.newStake);
            }
            rewardPeriods[latestRewardPeriod].totalNewStake[stakeholder.weight] -= stakeholder.newStake;
            stakeholder.newStake = 0;
        } else {
            rewardPeriods[latestRewardPeriod].totalNewStake[stakeholder.weight] -= amount;
            stakeholder.newStake -= amount;
        }

        stakeholder.releaseDate = block.timestamp + cooldown;
        stakeholder.releaseAmount += amount;

        
        // If no stake is left in any way,
        // treat the staker as leaving
        if(activeStakeholder(sender) == false){
            stakeholder.startDate = 0;
            weightCounts[stakeholder.weight]--;
            // Check if maxWeight decreased
            handleDecreasingMaxWeight();
            emit Active(sender, false);
        }
        
        emit InitiateWithdraw(sender, amount, stakeholder.releaseDate);

        if(instant){
            withdrawFunds();
        }

    }

    /**
     * Withdraw staked funds from the contract.
     * Can only be triggered after `requestWithdrawal` has been called.
     * If funds are withdrawn before the cooldown period has passed,
     * a fee will fee deducted. Withdrawing the funds when triggering
     * `requestWithdrawal` will result in a fee equal to `earlyWithdrawalFee`.
     * Waiting until the cooldown period has passed results in no fee.
     * Withdrawing at any other moment between these two periods in time
     * results in a fee that lineairy decreases with time.
     */
    function withdrawFunds() public {
        address sender = _msgSender();
        StakeHolder storage stakeholder = stakeholders[sender];

        require(stakeholder.releaseDate != 0,
            "No withdraw request");
        require(stakeholder.releaseAmount >= 0, "Nothing to withdraw");
        
        // Calculate time passed since withdraw request to calculate fee
        uint timeToEnd = stakeholder.releaseDate >= block.timestamp ? (stakeholder.releaseDate - block.timestamp) : 0;
        uint fee = (cooldown > 0) ? stakeholder.releaseAmount * timeToEnd * earlyWithdrawalFee / (cooldown * 10**8) : 0;

        // Transfer reduced amount to the staker, fee to the owner wallet
        stakingToken.transfer(sender, stakeholder.releaseAmount - fee);
        stakingToken.transfer(wallet, fee);
        emit Withdraw(sender, stakeholder.releaseAmount, fee);

        stakeholder.releaseDate = 0;
        stakeholder.releaseAmount = 0;
    }

    /**
     * Function to claim the rewards earned by staking for the sender.
     * @dev Calls `handleRewards` for the sender
     * @param endPeriod The periods to claim rewards for.
     * @param withdraw if true, send the rewards to the stakeholder.
     *  if false, add the rewards to the staking balance of the stakeholder.
     */
    function claimRewards(uint endPeriod, bool withdraw) public {
        // If necessary, close the current latest period and create a new latest.
        handleNewPeriod(endPeriod);
        address stakeholderAddress = _msgSender();
        handleRewards(endPeriod, withdraw, stakeholderAddress);    
    }

    /**
     * Function to claim the rewards for a list of stakers as owner.
     * No funds are withdrawn, only staking balances are updated.
     * @dev Calls `handleRewards` in a loop for the stakers defined
     * @param stakeholders_ list of stakeholders to claim rewards for
     */
    function claimRewardsAsOwner(address[] memory stakeholders_) public onlyOwner{
        // If necessary, close the current latest period and create a new latest.
        handleNewPeriod(currentPeriod());
        for(uint i = 0; i < stakeholders_.length; i++){
            handleRewards(currentPeriod(), false, stakeholders_[i]);
        }
    }

    /**
     * Function to claim the rewards earned by staking for an address.
     * @dev uses calculateRewards to get the amount owed
     * @param endPeriod The periods to claim rewards for.
     * @param withdraw if true, send the rewards to the stakeholder.
     *  if false, add the rewards to the staking balance of the stakeholder.
     * @param stakeholderAddress address to claim rewards for
     */
    function handleRewards(uint endPeriod, bool withdraw, address stakeholderAddress) internal {
        StakeHolder storage stakeholder = stakeholders[stakeholderAddress];
        
        if(currentPeriod() < endPeriod){
            endPeriod = currentPeriod();
        }
        // Number of periods for which rewards will be paid
        // Current period is not in the interval as it is not finished.
        uint n = (endPeriod > stakeholder.lastClaimed) ? 
            endPeriod - stakeholder.lastClaimed : 0;

        // If no potental stake is present or no time passed since last claim,
        // new rewards do not need to be calculated.
        if (activeStakeholder(stakeholderAddress) == false || n == 0){
                return;
        }

        // Calculate the rewards and new stakeholder state
        (uint reward, uint lockedRewards, StakeHolder memory newStakeholder) = calculateRewards(stakeholderAddress, endPeriod);
        
        // Update stakeholder values
        stakeholder.stakingBalance = newStakeholder.stakingBalance;
        stakeholder.newStake = newStakeholder.newStake;
        stakeholder.lockedRewards = newStakeholder.lockedRewards;

        // Add the weighted rewards to the totalWeightedRewardsClaimed values.
        // rewardPeriods[latestRewardPeriod].rewardsClaimed[stakeholder.weight] += reward;

        // Update last claimed and reward definition to use in next calculation
        stakeholder.lastClaimed = endPeriod;

        // If the stakeholder wants to withdraw the rewards,
        // send the funds to his wallet. Else, update stakingbalance.
        if (withdraw){
            rewardPeriods[latestRewardPeriod].totalStakingBalance[stakeholder.weight] -= reward;
            stakingToken.transfer(_msgSender(), reward);
            // If no stake is left in any way,
            // treat the staker as leaving
            if(activeStakeholder(stakeholderAddress) == false){
                stakeholder.startDate = 0;
                weightCounts[stakeholder.weight]--;
                // Check if maxWeight decreased
                handleDecreasingMaxWeight();
                emit Active(stakeholderAddress, false);
            }
            emit Withdraw(stakeholderAddress, reward, 0);
        } else {
            stakeholder.stakingBalance += reward;
        }

        emit Rewarding(stakeholderAddress, reward, lockedRewards, n);

    }

    /**
     * Calculate the rewards owed to a stakeholder.
     * The interest will be calculated based on:
     *  - The reward to divide in this period
     *  - The the relative stake of the stakeholder (taking previous rewards in account)
     *  - The time the stakeholder has been staking.
     * The formula of compounding interest is applied, meaning rewards on rewards are calculated.
     * @param stakeholderAddress The address to calculate rewards for
     * @param endPeriod The rewards will be calculated until this period.
     * @return reward The rewards of the stakeholder for previous periods that can be claimed instantly.
     * @return lockedRewards The additional locked rewards for this period
     * @return stakeholder The new object containing stakeholder state
     */
    function calculateRewards(address stakeholderAddress, uint endPeriod) public view returns(uint reward, uint lockedRewards, StakeHolder memory stakeholder) {

        stakeholder = stakeholders[stakeholderAddress];
        
        // Number of periods for which rewards will be paid
        // lastClaimed is included, currentPeriod not.
        uint n = (endPeriod > stakeholder.lastClaimed) ? 
            endPeriod - stakeholder.lastClaimed : 0;

        // If no stake is present or no time passed since last claim, 0 can be returned.
        if (activeStakeholder(stakeholderAddress) == false || n == 0){
                return (0, 0, stakeholder);
        }

        uint currentStake = stakeholder.stakingBalance;
        uint initialLocked = stakeholder.lockedRewards;

        // Loop over all following intervals to calculate the rewards for following periods.
        uint twsb;
        uint rpp;
        uint erm;
        uint[] memory tsb = new uint[](rewardPeriods[latestRewardPeriod].maxWeight+1);
        uint[] memory tlr = new uint[](rewardPeriods[latestRewardPeriod].maxWeight+1);

        // Loop over over all periods.
        // Start is last claimed date,
        // end is capped by the smallest of:
        // - the endPeriod function parameter
        // - the max number of periods for which rewards are distributed
        for (uint p = stakeholder.lastClaimed;
            p < (endPeriod > maxNumberOfPeriods ? maxNumberOfPeriods : endPeriod);
            p++) {

            uint extraReward;
            // If p is smaller than the latest reward period registered,
            // calculate the rewards based on state
            if(p <= latestRewardPeriod){
                twsb = totalStakingBalance(p,1,false);
                rpp = rewardPeriods[p].rewardPerPeriod;
                erm = rewardPeriods[p].extraRewardMultiplier;
            }
            // If p is bigger, simulate the behaviour of `handleNewPeriod`
            // and `totalStakingBalance` with the current state of the last period.
            // This part is never used in `claimRewards` as the state is updated first
            // but it is needed when directly calling this function to:
            // - calculating current rewards before anyone triggered `handleNewPeriod`
            // - forecasting expected returns with a period in the future
            else {
                // Initialize first simulation
                if(p == latestRewardPeriod + 1){
                    for(uint i = 0; i<=rewardPeriods[latestRewardPeriod].maxWeight; i++){
                        tsb[i]=rewardPeriods[latestRewardPeriod].totalStakingBalance[i];
                        tlr[i]=totalLockedRewards[i];
                    }
                }

                // Add rewards of last period
                for(uint i = 0; i<=rewardPeriods[latestRewardPeriod].maxWeight; i++){
                    uint newReward = 0;
                    if(twsb > 0){
                        newReward = (tsb[i]*(twsb+rpp*(i+1)) / twsb) - tsb[i];
                        tsb[i] += newReward;
                    }

                    if(p % periodsForExtraReward == 1){
                        tsb[i] += tlr[i]
                                + newReward * erm / (10**6);
                        tlr[i] = 0;
                    } else {
                        tlr[i] += newReward * erm / (10**6);
                    }
                }
                // Add new stake of last period (only first simulation)
                if(p == latestRewardPeriod + 1){
                    for(uint i = 0; i<=rewardPeriods[latestRewardPeriod].maxWeight; i++){
                        tsb[i] += rewardPeriods[latestRewardPeriod].totalNewStake[i];
                    }
                } 

                // Calculate weighted staking balance for reward calculation
                twsb = 0;
                for(uint i = 0; i<=rewardPeriods[latestRewardPeriod].maxWeight; i++){
                    twsb += tsb[i]*(i+1);
                }


            }

            // Update the new stake
            if(twsb > 0){
                uint newReward = (currentStake*(twsb + (stakeholder.weight+1) * rpp) / twsb) - currentStake;
                currentStake += newReward;
                reward += newReward;
                extraReward = newReward*erm/(10**6);
            }

            if(stakeholder.newStake > 0){
                // After reward last period with old stake, add it to balance
                currentStake += stakeholder.newStake;
                stakeholder.stakingBalance += stakeholder.newStake;
                stakeholder.newStake = 0;
            }

            // Calculate extra reward from new reward
            if(p % periodsForExtraReward == 0){
                // Add earlier earned extra rewards to the stake
                currentStake += stakeholder.lockedRewards;
                // Add new extra rewards to the stake
                currentStake += extraReward;
                // Update total reward
                reward += extraReward + stakeholder.lockedRewards;
                // Reset initial locked tokens, these are not locked anymore
                initialLocked = 0;
                stakeholder.lockedRewards = 0;
            } else {
                stakeholder.lockedRewards += extraReward;
            }

        }

        lockedRewards = stakeholder.lockedRewards - initialLocked;


    }


    /**
     * Checks if the signature is created out of the contract address, sender and new weight,
     * signed by the private key of the signerAddress
     * @param sender the address of the message sender
     * @param weight amount of tokens to mint
     * @param signature a signature of the contract address, senderAddress and tokensId.
     *   Should be signed by the private key of signerAddress.
     */
    function _recoverSigner(address sender, uint weight, bytes memory signature) public view returns (address){
        return ECDSA.recover(ECDSA.toEthSignedMessageHash(keccak256(abi.encode(address(this), sender, weight))) , signature);
    }

    /**
     * Owner function to transfer the staking token from the contract
     * address to the contract owner.
     * The amount cannot exceed the amount staked by the stakeholders,
     * making sure the funds of stakeholders stay in the contract.
     * Unclaimed rewards and locked rewards cannot be withdrawn either.
     * @param amount the amount to withraw as owner
     */
    function withdrawRemainingFunds(uint amount) public onlyOwner{
        uint lockedRewards;
        for(uint i = 0; i <= rewardPeriods[latestRewardPeriod].maxWeight; i++){
            lockedRewards += totalLockedRewards[i];
        }
        // Make sure the staked amounts rewards are never withdrawn
        if(amount > stakingToken.balanceOf(address(this))
            - (totalStakingBalance(latestRewardPeriod,0,false)) 
            - (totalStakingBalance(latestRewardPeriod,0,true)) 
            - lockedRewards){
                amount = stakingToken.balanceOf(address(this))
                    - (totalStakingBalance(latestRewardPeriod,0,false))
                    - (totalStakingBalance(latestRewardPeriod,0,true))
                    - lockedRewards;
        }

        stakingToken.transfer(wallet, amount);
    }

    /**
     * Update the address used to verify signatures
     * @param value the new address to use for verification
     */
    function updateSignatureAddress(address value) public onlyOwner {
        signatureAddress = value; 
    }

    /**
     * @param value the new end date after which rewards will stop
     */
    function updateMaxNumberOfPeriods(uint value) public onlyOwner {
        maxNumberOfPeriods = value; 
        emit ConfigUpdate('Max number of periods', value);
    }

    /**
     * Updates the cooldown period.
     * @param value The new cooldown per period
     */
    function updateCoolDownPeriod(uint value) public onlyOwner{
        cooldown = value;
        emit ConfigUpdate('Cool down period', value);
    }

    /**
     * Updates the early withdraw fee.
     * @param value The new fee
     */
    function updateEarlyWithdrawalFee(uint value) public onlyOwner{
        earlyWithdrawalFee = value;
        emit ConfigUpdate('New withdraw fee', value);
    }

    /**
     * Updates the reward per period, starting instantly.
     * @param value The new reward per period
     */
    function updateRewardPerPeriod(uint value) public onlyOwner{
        handleNewPeriod(currentPeriod());       
        rewardPeriods[latestRewardPeriod].rewardPerPeriod = value;
        emit ConfigUpdate('Reward per period', value);
    }

    /**
     * Updates the wallet for receiving fees and withdrawals.
     * @param value The new wallet address
     */
    function updateWallet(address payable value) public onlyOwner{
        wallet = value;
    }

    /**
     * Updates the extra reward multiplier, starting instantly.
     * Take into account this value will be divided by 10**6
     * in order to allow multipliers < 1 up to 0.000001.
     * @param value The new reward per period
     */
    function updateExtraRewardMultiplier(uint value) public onlyOwner{
        handleNewPeriod(currentPeriod());       
        rewardPeriods[latestRewardPeriod].extraRewardMultiplier = value;
        emit ConfigUpdate('Extra reward multiplier', value);
    }

    /**
     * Calculates how many reward periods passed since the start.
     * @return period the current period
     */
    function currentPeriod() public view returns(uint period){
        period = (block.timestamp - startDate) / rewardPeriodDuration;
        if(period > maxNumberOfPeriods){
            period = maxNumberOfPeriods;
        }
    }

    /**
     * Updates maxWeight in case there are no stakeholders with this weight left
     */
    function handleDecreasingMaxWeight() public {
        if (weightCounts[rewardPeriods[latestRewardPeriod].maxWeight] == 0 && rewardPeriods[latestRewardPeriod].maxWeight > 0){
            for(uint i = rewardPeriods[latestRewardPeriod].maxWeight - 1; 0 <= i; i--){
                if(weightCounts[i] > 0 || i == 0){
                    rewardPeriods[latestRewardPeriod].maxWeight = i;
                    break;
                }
            }
        }        
    }

    /**
     * Checks if a stakeholder is still active
     * Active stakeholders have at least one of following things:
     * - positive staking balance
     * - positive new stake to be added next period
     * - positive locked tokens that can come in circulation 
     * @return active true if stakeholder holds active balance
     */
    function activeStakeholder(address stakeholderAddress) public view returns(bool active) {
        return (stakeholders[stakeholderAddress].stakingBalance > 0
            || stakeholders[stakeholderAddress].newStake > 0
            || stakeholders[stakeholderAddress].lockedRewards > 0);
    }

    /**
     * Returns the tokens staked, the rewards earned and locked tokens as balance for a stakeholder.
     * Used in applications expecting the ERC20 interface, e.g. Metamask
     * @param stakeholderAddress the address to return the balance for
     * @return balance the sum of total stakingbalance, reward and locked tokens
     */
    function balanceOf(address stakeholderAddress) public view returns (uint256 balance){
            (uint reward, uint lockedRewards, StakeHolder memory stakeholder) = calculateRewards(stakeholderAddress, currentPeriod());

            balance = stakeholder.stakingBalance
                + stakeholder.newStake
                + reward
                + stakeholder.lockedRewards; 

    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
//SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

import "Ownable.sol";
import "CrushCoin.sol";
import "SafeMath.sol";
import "HouseBankroll.sol";
import "LiveWallet.sol";
contract BitcrushStaking is Ownable {
    using SafeMath for uint256;
    
    uint256 constant MAX_CRUSH_PER_BLOCK = 10;
    uint256 constant MAX_FEE = 1000; // 1000/10000 * 100 = 10%
    uint256 public performanceFeeCompounder = 10; // 10/10000 * 100 = 0.1%
    uint256 public performanceFeeBurn       = 100; // 100/10000 * 100 = 1%
    uint256 constant divisor = 10000;
    
    uint256  public earlyWithdrawFee         = 50; // 50/10000 * 100 = 0.5% 
    uint256  public performanceFeeReserve    = 190; // 190/10000 * 100 = 1.9%
    
    uint256 public profitShare = 10;
    uint256 public blockPerSecond = 3;
    uint256 public earlyWithdrawFeeTime = 72 * 60 * 60 / blockPerSecond;
    
    //address of the crush token
    CRUSHToken public crush;
    BitcrushBankroll public bankroll;
    BitcrushLiveWallet public liveWallet;
    struct staked {
        uint256 stakedAmount;
        uint256 claimedAmount;
        uint256 profit;
        uint256 lastBlockCompounded;
        uint256 lastBlockStaked;
        uint256 index;
    }
    mapping (address => staked) public stakings;
    address[] public addressIndexes;

    struct profit {
        uint256 total;
        uint256 remaining;
    }
    profit[] public profits;

    uint256 public totalPool;
    uint256 public lastAutoCompoundBlock;
    uint256 public batchStartingIndex = 0;
    
    uint256 public crushPerBlock = 5;
    address public reserveAddress;

    uint256 public totalStaked;
    
    uint256 public totalClaimed;
    uint256 public totalFrozen = 0;
    
    uint256 public autoCompoundLimit = 10;

    event RewardPoolUpdated (uint256 indexed _totalPool);
    event CompoundAll (uint256 indexed _totalRewarded);
    event StakeUpdated (address indexed recipeint, uint256 indexed _amount);
    
    constructor (CRUSHToken _crush, uint256 _crushPerBlock, address _reserveAddress) public{
        crush = _crush;
        crushPerBlock = _crushPerBlock;
        reserveAddress = _reserveAddress;
        lastAutoCompoundBlock = 0;
        
    }

    function setBankroll (BitcrushBankroll _bankroll) public {
        bankroll = _bankroll;
    }
    function setLiveWallet (BitcrushLiveWallet _liveWallet) public{
        liveWallet = _liveWallet;
    }

    /// Adds the provided amount to the totalPool
    /// @param _amount the amount to add
    /// @dev adds the provided amount to `totalPool` state variable
    function addRewardToPool (uint256 _amount) public  {
        require(crush.balanceOf(msg.sender) >= _amount, "Insufficient Crush tokens for transfer");
        totalPool = totalPool.add(_amount);
        crush.transferFrom(msg.sender, address(this), _amount);
        emit RewardPoolUpdated(totalPool);
    }

    
    function setCrushPerBlock (uint256 _amount) public onlyOwner {
        require(_amount >= 0, "Crush per Block can not be negative" );
        require(_amount <= MAX_CRUSH_PER_BLOCK, "Crush Per Block can not be more than 10");
        crushPerBlock = _amount;
    }


    /// Stake the provided amount
    /// @param _amount the amount to stake
    /// @dev stakes the provided amount
    function enterStaking (uint256 _amount) public  {
        require(crush.balanceOf(msg.sender) >= _amount, "Insufficient Crush tokens for transfer");
        require(_amount > 0,"Invalid staking amount");
        require(totalPool > 0, "Reward Pool Exhausted");
        
        crush.transferFrom(msg.sender, address(this), _amount);
        if(totalStaked == 0){
            lastAutoCompoundBlock = block.number;
        }
        if(stakings[msg.sender].stakedAmount == 0){
            stakings[msg.sender].lastBlockCompounded = block.number;
            addressIndexes.push(msg.sender);
            stakings[msg.sender].index = addressIndexes.length-1;
        }
        stakings[msg.sender].stakedAmount = stakings[msg.sender].stakedAmount.add(_amount);
        stakings[msg.sender].lastBlockStaked = block.number;
        totalStaked = totalStaked.add(_amount);
        crush.transfer(msg.sender, getReward(msg.sender));
        stakings[msg.sender].lastBlockCompounded = block.number;
        
       
    }



    /// Leaves staking for a user by the specified amount and transfering staked amount and reward to users address
    /// @param _amount the amount to unstake
    /// @dev leaves staking and deducts total pool by the users reward. early withdrawal fee applied if withdraw is made before earlyWithdrawFeeTime
    function leaveStaking (uint256 _amount) public  {
        uint256 reward = getReward(msg.sender);
        stakings[msg.sender].lastBlockCompounded = block.number;
        totalPool = totalPool.sub(reward);
        uint256 availableStaked;
        if(totalFrozen > 0){
            availableStaked = stakings[msg.sender].stakedAmount.sub(totalFrozen.mul(stakings[msg.sender].stakedAmount).div(totalStaked));
        }else {
            availableStaked = stakings[msg.sender].stakedAmount;
        }
        


        require(availableStaked >= _amount, "Withdraw amount can not be greater than available staked amount");
        totalStaked = totalStaked.sub(_amount);
        stakings[msg.sender].stakedAmount = stakings[msg.sender].stakedAmount.sub(_amount);
        if(block.number < stakings[msg.sender].lastBlockStaked.add(earlyWithdrawFeeTime)){
            //apply fee
            uint256 withdrawalFee = _amount.mul(earlyWithdrawFee).div(divisor);
            _amount = _amount.sub(withdrawalFee);
            crush.transfer(reserveAddress, withdrawalFee);
        }
        _amount = _amount.add(reward);
        crush.transfer(msg.sender, _amount);
        //remove from array
        if(stakings[msg.sender].stakedAmount == 0){
            staked storage staking = stakings[msg.sender];
            if(staking.index != addressIndexes.length-1){
                address lastAddress = addressIndexes[addressIndexes.length-1];
                addressIndexes[staking.index] = lastAddress;
                stakings[lastAddress].index = staking.index;
                crush.approve( address(this), 0);
            }
            addressIndexes.pop();
            delete stakings[msg.sender];
        }
        emit RewardPoolUpdated(totalPool);
    }
    /* //todo deprecated verify from jose if still in use
    /// Leaves staking for a user while setting stakedAmount to 0 and transfering staked amount and reward to users address
    /// @dev leaves staking and deducts total pool by the users reward. early withdrawal fee applied if withdraw is made before earlyWithdrawFeeTime
    function leaveStakingCompletely () public {
        uint256 reward = getReward(msg.sender);
        stakings[msg.sender].lastBlockCompounded = block.number;
        uint256 stakedAmount = stakings[msg.sender].stakedAmount;
        totalPool = totalPool.sub(reward);
        stakedAmount = stakedAmount.add(reward);
        totalStaked = totalStaked.sub(stakings[msg.sender].stakedAmount);
        
        if(block.number < stakings[msg.sender].lastBlockStaked + earlyWithdrawFeeTime ){
            uint256 withdrawalFee = stakedAmount.mul(earlyWithdrawFee).div(divisor);
            stakedAmount = stakedAmount.sub(withdrawalFee);
            crush.transfer(reserveAddress, withdrawalFee);
        }
        crush.transfer(msg.sender, stakedAmount);
        stakings[msg.sender].stakedAmount = 0;
        if(stakings[msg.sender].stakedAmount == 0){
            staked storage staking = stakings[msg.sender];
            if(staking.index != addressIndexes.length-1){
                address lastAddress = addressIndexes[addressIndexes.length-1];
                addressIndexes[staking.index] = lastAddress;
                stakings[lastAddress].index = staking.index;
                crush.approve( address(this), 0);
            }
            addressIndexes.pop();
            delete stakings[msg.sender];
        }
        emit RewardPoolUpdated(totalPool);
    }
 */
    
    function getReward(address _address) internal view returns (uint256) {
        if(block.number <=  stakings[_address].lastBlockCompounded){
            return 0;
        }else {
            if(totalPool == 0 || totalStaked ==0 ){
                return 0;
            }else {
                //if the staker reward is greater than total pool => set it to total pool
                uint256 blocks = block.number.sub(stakings[_address].lastBlockCompounded);
                uint256 totalReward = blocks.mul(crushPerBlock);
                uint256 stakerReward = totalReward.mul(stakings[_address].stakedAmount).div(totalStaked);
                if(stakerReward > totalPool){
                    stakerReward = totalPool;
                }
                return stakerReward;
            }
            
        }
    }

    /// Calculates total potential pending rewards
    /// @dev Calculates potential reward based on crush per block
    function totalPendingRewards () public view returns (uint256){
            if(block.number <= lastAutoCompoundBlock){
                return 0;
            }else if(lastAutoCompoundBlock == 0){
                return 0;
            }else if (totalPool == 0){
                return 0;
            }

            uint256 blocks = block.number.sub(lastAutoCompoundBlock);
            uint256 totalReward = blocks.mul(crushPerBlock);

            return totalReward;
    }

    /// Get pending rewards of a user
    /// @param _address the address to calculate the reward for
    /// @dev calculates potential reward for the address provided based on crush per block
    function pendingReward (address _address) public view returns (uint256){
        return getReward(_address);
    }

    /// transfers the rewards of a user to their address
    /// @dev calculates users rewards and transfers it out while deducting reward from totalPool
    function claim () public  {
        uint256 reward = getReward(msg.sender);
        stakings[msg.sender].claimedAmount = stakings[msg.sender].claimedAmount.add(reward);
        crush.transfer(msg.sender, reward);
        stakings[msg.sender].lastBlockCompounded = block.number;
        totalClaimed = totalClaimed.add(reward);
        totalPool = totalPool.sub(reward); 
    }

    function claimProfit () public {
        require(stakings[msg.sender].profit > 0, "No Profit to claim");
        crush.transfer(msg.sender, stakings[msg.sender].profit);
        stakings[msg.sender].profit = 0;
    }

    /// compounds the rewards of the caller
    /// @dev compounds the rewards of the caller add adds it into their staked amount
    function singleCompound () public  {
        require(stakings[msg.sender].stakedAmount > 0, "Please Stake Crush to compound");
        uint256 reward = getReward(msg.sender);
        stakings[msg.sender].stakedAmount = stakings[msg.sender].stakedAmount.add(reward); 
        totalStaked = totalStaked.add(reward);
        stakings[msg.sender].lastBlockCompounded = block.number;
        totalPool = totalPool.sub(reward);
        emit RewardPoolUpdated(totalPool);
        emit StakeUpdated(msg.sender,reward);
    }

  

    /// compounds the rewards of all users in the pool
    /// @dev compounds the rewards of all users in the pool add adds it into their staked amount while deducting fees
    function compoundAll () public  {
        require(lastAutoCompoundBlock <= block.number, "Compound All not yet applicable.");
        require(totalStaked > 0, "No Staked rewards to claim" );
        uint256 crushToBurn = 0;
        uint256 performanceFee = 0;
        uint256 totalRewarded = 0;
        uint256 compounderReward = 0;
        uint totalPoolDeducted = 0;
        
        uint256 batchLimit = addressIndexes.length;
        if(addressIndexes.length <= autoCompoundLimit || batchStartingIndex.add(autoCompoundLimit) >= addressIndexes.length){
            batchLimit = addressIndexes.length;
        }else {
            batchLimit = batchStartingIndex.add(autoCompoundLimit);
        }
        for(uint256 i=batchStartingIndex; i < batchLimit; i++){
            uint256 stakerReward = getReward(addressIndexes[i]);
            if(stakerReward > 0){
                totalRewarded = totalRewarded.add(stakerReward);
            totalPoolDeducted = totalPoolDeducted.add(stakerReward);
            
            uint256 stakerBurn = stakerReward.mul(performanceFeeBurn).div(divisor);
            crushToBurn = crushToBurn.add(stakerBurn);
            
            uint256 cpAllReward = stakerReward.mul(performanceFeeCompounder).div(divisor);
            compounderReward = compounderReward.add(cpAllReward);
            
            uint256 feeReserve = stakerReward.mul(performanceFeeReserve).div(divisor);
            performanceFee = performanceFee.add(feeReserve);
            

            stakerReward = stakerReward.sub(stakerBurn);
            stakerReward = stakerReward.sub(cpAllReward);
            stakerReward = stakerReward.sub(feeReserve);
            
            totalStaked = totalStaked.add(stakerReward);
            stakings[addressIndexes[i]].stakedAmount = stakings[addressIndexes[i]].stakedAmount.add(stakerReward);
            stakings[addressIndexes[i]].lastBlockCompounded = block.number;
            }
            if(profits.length > 0){
                if(profits[0].remaining > 0){
                uint256 profitShareUser = profits[0].total.mul(stakings[addressIndexes[i]].stakedAmount).div(totalStaked);
                if(profitShareUser >= profits[0].remaining){
                 profitShare = profits[0].remaining;
                }
                uint256 compounderShare = profitShareUser.mul(profitShare).div(divisor);
                profits[0].remaining = profits[0].remaining.sub(profitShareUser);
                profitShareUser = profitShareUser.sub(compounderShare);
                stakings[addressIndexes[i]].profit = stakings[addressIndexes[i]].profit.add(profitShareUser); 
                compounderReward = compounderReward.add(compounderShare);   
                }
            }
                        
        }
        if(batchStartingIndex.add(batchLimit) >= addressIndexes.length){
            if(profits.length > 0){
                if(profits[0].remaining == 0 && profits[0].total > 0 && profits.length > 0 ){
                //rearrange array
                profits[0] = profits[profits.length - 1];
                profits.pop;

                }
            }
            
            batchStartingIndex = 0;
            uint256 newProfit = bankroll.transferProfit();
            if(newProfit > 0){
                //profit deduction
                profit memory prof = profit(newProfit,newProfit);
                profits.push(prof);
            }
        }
        totalPool = totalPool.sub(totalPoolDeducted);
        lastAutoCompoundBlock = block.number;
        crush.burn(crushToBurn);
        crush.transfer(msg.sender, compounderReward);
        crush.transfer(reserveAddress, performanceFee);
        
    }


    function freezeStaking (uint256 _amount, address _recipient, uint256 _gameId) public {
        //divide amount over users
        //update user mapping to reflect frozen amount
         require(_amount <= totalStaked.sub(totalFrozen), "Freeze amount should be less than or equal to available funds");
         totalFrozen = totalFrozen.add(_amount);
         liveWallet.addToUserWinnings(_gameId, _amount, _recipient);
         crush.transfer(address(liveWallet), _amount);
    }

    function unfreezeStaking (uint256 _amount) public {
       //divide amount over users
        //update user mapping to reflect deducted frozen amount
         require(_amount <= totalFrozen, "unfreeze amount cant be greater than currently frozen amount");
         totalFrozen = totalFrozen.sub(_amount);
    }


    /// withdraws the staked amount of user in case of emergency.
    /// @dev drains the staked amount and sets the state variable `stakedAmount` of staking mapping to 0
    function emergencyWithdraw() public {
        //add check for frozen amount
        uint256 availableStaked;
        if(totalFrozen > 0){
            availableStaked = stakings[msg.sender].stakedAmount.sub(totalFrozen.mul(stakings[msg.sender].stakedAmount).div(totalStaked));
        }else {
            availableStaked = stakings[msg.sender].stakedAmount;
        }

        crush.transfer( msg.sender, availableStaked);
        stakings[msg.sender].stakedAmount = stakings[msg.sender].stakedAmount.sub(availableStaked);
        
        stakings[msg.sender].lastBlockCompounded = block.number;
        if(stakings[msg.sender].stakedAmount == 0) {
            staked storage staking = stakings[msg.sender];
            if(staking.index != addressIndexes.length-1){
                address lastAddress = addressIndexes[addressIndexes.length-1];
                addressIndexes[staking.index] = lastAddress;
                stakings[lastAddress].index = staking.index;
            }
            addressIndexes.pop();
            crush.approve( address(this), 0);
        }
        
    }

    /// withdraws the total pool in case of emergency.
    /// @dev drains the total pool and sets the state variable `totalPool` to 0
    function emergencyTotalPoolWithdraw () public onlyOwner {
        require(totalPool > 0, "Total Pool need to be greater than 0");
        if(totalFrozen > 0){
            crush.transfer(msg.sender, totalPool.sub(totalFrozen));
            totalPool = totalPool.sub(totalFrozen);
        } else {
            crush.transfer(msg.sender, totalPool);
            totalPool = 0;
        }
        
    }

    /// Store `_fee`.
    /// @param _fee the new value to store
    /// @dev stores the fee in the state variable `performanceFeeCompounder`
    function setPerformanceFeeCompounder (uint256 _fee) public onlyOwner{
        require(_fee > 0, "Fee must be greater than 0");
        require(_fee < MAX_FEE, "Fee must be less than 10%");
        performanceFeeCompounder = _fee;
    }

    /// Store `_fee`.
    /// @param _fee the new value to store
    /// @dev stores the fee in the state variable `performanceFeeBurn`
    function setPerformanceFeeBurn (uint256 _fee) public onlyOwner {
        require(_fee > 0, "Fee must be greater than 0");
        require(_fee < MAX_FEE, "Fee must be less than 10%");
        performanceFeeBurn = _fee;
    }

    /// Store `_fee`.
    /// @param _fee the new value to store
    /// @dev stores the fee in the state variable `earlyWithdrawFee`
    function setEarlyWithdrawFee (uint256 _fee) public onlyOwner {
        require(_fee > 0, "Fee must be greater than 0");
        require(_fee < MAX_FEE, "Fee must be less than 10%");
        earlyWithdrawFee = _fee;
    }


    /// Store `_fee`.
    /// @param _fee the new value to store
    /// @dev stores the fee in the state variable `performanceFeeReserve`
    function setPerformanceFeeReserve (uint256 _fee) public onlyOwner {
        require(_fee > 0, "Fee must be greater than 0");
        require(_fee <= MAX_FEE, "Fee must be less than 10%");
        performanceFeeReserve = _fee;
    }

    /// Store `_time`.
    /// @param _time the new value to store
    /// @dev stores the time in the state variable `earlyWithdrawFeeTime`
    function setEarlyWithdrawFeeTime (uint256 _time) public onlyOwner {
        require(_time > 0, "Time must be greater than 0");
        earlyWithdrawFeeTime = _time;
    }

    function setAutoCompoundLimit (uint256 _limit) public onlyOwner {
        require(_limit > 0, "Limit can not be 0");
        autoCompoundLimit = _limit;
    }

    function setProfitShare (uint256 _profitShare) public onlyOwner {
        require(_profitShare > 0, "Profit share can not be 0");
        profitShare = _profitShare;
    }

   
}
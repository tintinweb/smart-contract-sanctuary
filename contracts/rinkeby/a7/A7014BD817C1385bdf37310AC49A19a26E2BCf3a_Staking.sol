// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./TokenUtility.sol";
//import "@openzeppelin/contracts/utils/Pausable.sol";

contract Staking is Ownable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    using TokenUtility for *;
    using SafeERC20 for IERC20;

    IERC20 _stoken;
    IERC20 _rewardToken;
    uint256 public _farmStartedTime;
    uint256 public _miniStakePeriodInSeconds;
    uint256 public _allTimeTotalMined;
    //total reward still in pool, not claimed
    uint256 public _totalRewardInPool;

    struct StakeRecord{
        uint256 timeKey;//when
        // address account;//which account
        uint256 amount;//how much amount SToken staked 
        uint256 lockedAmount;//how much locked amount SToken staked 
        
        uint256 withdrawed;//how much amount SToken withdrawed from this record
        uint256 lockedWithdrawed;//how much locked amount SToken withdrawed from this record
    }

    struct UserInfo {
        //how many STokens the user has provided in all
        uint256 amount;
        //how many locked STokens the user has provided in all
        uint256 lockedAmount;

        //when >0 denotes that reward before this time already update into rewardBalanceInpool
        uint lastUpdateRewardTime;

        //all his lifetime mined target token amount
        uint256 allTimeMinedBalance;
        //mining reward balances in pool without widthdraw
        uint256 rewardBalanceInpool;

        //all time reward balance claimed
        uint256 allTimeRewardClaimed;
        
        //stake info account =>(time-key => staked record)
        mapping(uint => StakeRecord) stakeInfo;
        //store time-key arrays for stakeInfo
        uint[] stakedTimeIndex;
    }

    struct RoundSlotInfo{
        //mining record submit by admin or submiter
        //MiningReward reward;//reward info in this period
        address rLastSubmiter;
        uint256 rAmount;//how much reward token deposit
        uint256 rAccumulateAmount;
        //before was reward

        uint256 totalStaked;//totalStaked = previous round's totalStaked + this Round's total staked 
        uint256 stakedLowestWaterMark;//lawest water mark for this slot
        
        uint256 totalStakedInSlot;//this Round's total staked
        //store addresses set which staked in this slot
        address[] stakedAddressSet;
    }

    //user's info
    mapping (address => UserInfo) public _userInfo;
    //reward records split recorded by round slots 
    //time-key => RoundSlotInfo
    mapping (uint=>RoundSlotInfo) public _roundSlots;
    //store time-key arrays for slots
    uint[] public _roundSlotsIndex;
    //account which is mining in this farm
    EnumerableSet.AddressSet private _miningAccountSet;
    

    event DepositReward(address user, uint256 amount,uint indexed time);
    event DepositToMining(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event Claim(address indexed user, uint256 amount);

    constructor(
        IERC20 SToken,
        IERC20 rewardToken,
        uint256 miniStakePeriod,
        uint256 startTime
        //string memory desc
        //address devaddr
    )public {
        _stoken = SToken;
        //_devaddr = devaddr;
        _rewardToken = rewardToken;
        require(miniStakePeriod>0,"mining period should >0");
        _miniStakePeriodInSeconds = miniStakePeriod;
        //_farmDescription = desc;
        _farmStartedTime = startTime;
    }

    function changeBaseTime(uint time)public onlyOwner{
        require(time>0,"base time should >0");
        _farmStartedTime = time;
    }

    function changeMiniStakePeriodInSeconds(uint period) public onlyOwner{
        require(period>0,"mining period should >0");
        _miniStakePeriodInSeconds = period;
    }

    function changeRewardToken(IERC20 rewardToken) public onlyOwner{
        _rewardToken = rewardToken;
    }
    function changeSToken(IERC20 stoken)public onlyOwner{
        _stoken =stoken;
    }
    /**
     * @dev return the staked total number of SToken
     */
    function totalStaked()public virtual view returns(uint256){
        uint256 amount = 0;
        uint256 len = _miningAccountSet.length();
        for (uint256 ii=0; ii<len ;++ii){
            address account = _miningAccountSet.at(ii);
            UserInfo memory user = _userInfo[account];
            amount = amount.add(user.amount);
        }
        return amount;
    }

    /**
     * @dev return how many user is mining
     */
    function totalUserMining()public view returns(uint256){
        return _miningAccountSet.length();
    }

    /**
     * @dev return hown much already mined from account 
     */
    function totalMinedRewardFrom(address account)public view returns(uint256){
        UserInfo memory user = _userInfo[account];
        return user.allTimeMinedBalance;
    }

    function totalClaimedRewardFrom(address account)public view returns(uint256){
        UserInfo memory user = _userInfo[account];
        return user.allTimeRewardClaimed;
    }
    /**
     * @dev return hown much already mined from account without widthdraw
     */
    function totalRewardInPoolFrom(address account)public view returns(uint256){
        UserInfo memory user = _userInfo[account];
        return user.rewardBalanceInpool;
    }

    /**
     * @dev return hown much reward tokens in mining pool
     */
    function totalRewardInPool()public view returns(uint256){
        return _totalRewardInPool;
    }
    /**
     * @dev return the mining records of specific day
     */
    function miningRewardIn(uint day)public view returns (address,uint256,uint256){
        uint key = day.getTimeKey(_farmStartedTime,_miniStakePeriodInSeconds);
        RoundSlotInfo memory slot = _roundSlots[key];
        return (slot.rLastSubmiter,slot.rAmount,slot.rAccumulateAmount);
    }

    /**
     * @dev return the stake records of specific day
     */
    function stakeRecord(address account,uint day)public view returns (uint,uint256,uint256,uint256,uint256) {
        uint key = day.getTimeKey(_farmStartedTime,_miniStakePeriodInSeconds);
        UserInfo storage user = _userInfo[account];
        StakeRecord storage record = user.stakeInfo[key];
        return (record.timeKey,record.amount,record.lockedAmount,record.withdrawed,record.lockedWithdrawed);
    }
    function getUncalculateRewardBalanceInPoolBefore(address account,uint before) public view returns(uint256){
        UserInfo storage user = _userInfo[account];
        uint lastUpdate = user.lastUpdateRewardTime;
        if (before<=lastUpdate){
            return 0;
        }
        uint256 minedTotal = 0;
        if (user.stakedTimeIndex.length>0){
            for (uint256 xx=0;xx<user.stakedTimeIndex.length;xx++){
                uint time = user.stakedTimeIndex[xx];
                if (time<=before){
                    StakeRecord memory record = user.stakeInfo[time];
                    uint256 mined = _calculateMinedRewardDuringFor(record,
                        lastUpdate+_miniStakePeriodInSeconds,
                        before+_miniStakePeriodInSeconds);
                    minedTotal = minedTotal.add(mined);
                }
            }   
        }
        return minedTotal;
    }
    function getTotalRewardBalanceInPool(address account) public view returns (uint256){
        uint alreadyMinedTimeKey = _getMaxAlreadyMinedTimeKey(); 
        UserInfo memory user = _userInfo[account];
        uint256 old = user.rewardBalanceInpool;
        uint256 mined = getUncalculateRewardBalanceInPoolBefore(account,alreadyMinedTimeKey);
        return old.add(mined);
    }


    function _getRoundSlotInfo(uint timeKey)internal view returns(RoundSlotInfo memory){
        return _roundSlots[timeKey];
    }
    function _safeTokenTransfer(address to,uint256 amount,IERC20 token) internal{
        uint256 bal = token.balanceOf(address(this));
        if (amount > bal){
            token.transfer(to,bal);
        }else{
            token.transfer(to,amount);
        }
    }
    function _addMingAccount(address account)internal{
        _miningAccountSet.add(account);
    }
    function _getMingAccount() internal view returns (EnumerableSet.AddressSet memory){
        return _miningAccountSet;
    }
    function getMiningAccountAt(uint256 ii)internal view returns (address){
        return _miningAccountSet.at(ii);
    }
    function _updateIndexAfterDeposit(address account,uint key,uint256 amount)internal {
        UserInfo storage user = _userInfo[account];
        //update round slot
        RoundSlotInfo storage slot = _roundSlots[key];
        //update indexes
        uint maxLast = 0;
        if (user.stakedTimeIndex.length>0){
            maxLast = user.stakedTimeIndex[user.stakedTimeIndex.length-1];
        }
        slot.totalStakedInSlot = slot.totalStakedInSlot.add(amount);
        if (maxLast<key){
            //first time to stake in this slot
            slot.stakedAddressSet.push(account);
            user.stakedTimeIndex.push(key);   
        }

        _initOrUpdateLowestWaterMarkAndTotalStaked(key,amount);
    }
    function _getMaxAlreadyMinedTimeKey() internal view returns (uint){
        uint key = now.getTimeKey(_farmStartedTime,_miniStakePeriodInSeconds);
        return key.sub(_miniStakePeriodInSeconds*2);
    }
    /**
     * @dev denote how to calculate the user's remain staked amount for stake record
     */
    function _getRecordStaked(StakeRecord memory record)internal pure virtual returns(uint256){
        return record.amount.sub(record.withdrawed,"withdrawed>amount");
    }
    /**
     * @dev calculate mined reward during after and before time, from the stake record
     * (after,before]
     */
    function _calculateMinedRewardDuringFor(StakeRecord memory record,
        uint afterTime,uint beforeTime)internal virtual view returns(uint256){
        uint256 remainStaked = _getRecordStaked(record);
        
        if (remainStaked<=0){
            return 0;          
        }
        uint256 mined = 0;
        for (uint256 ii=_roundSlotsIndex.length;ii>0;ii--){
            uint key = _roundSlotsIndex[ii-1];
            if (key<=afterTime){
                break;
            }
            if (key<=beforeTime && key>afterTime && key>record.timeKey){
                //calculate this period of mining reward
                RoundSlotInfo memory slot = _roundSlots[key];
                if (slot.rAmount>0){
                    if (slot.stakedLowestWaterMark!=0){
                        mined = mined.add(
                            slot.rAmount.mul(remainStaked)
                            .div(slot.stakedLowestWaterMark));
                    }
                }
            }
        }
        return mined;
    }

    function depositToMiningBySTokenTransfer(address from,uint256 amount)external {
        require(address(msg.sender)==address(_stoken),"require callee from stoken,only stoken can activly notice farm to stake other's token to mining");
        _depositToMiningFrom(from, amount);
    }
    /**
     * @dev deposit STokens to mine reward tokens
     */
    function depositToMining(uint256 amount)public {
        _depositToMiningFrom(address(msg.sender), amount);
    }
    function _depositToMiningFrom(address account,uint256 amount)internal  {
        require(amount>0,"deposit number should greater than 0");
        //first try to transfer amount from sender to this contract
        _stoken.safeTransferFrom(account,address(this),amount);
        
        //if successed let's update the status
        _miningAccountSet.add(account);
        uint key = now.getTimeKey(_farmStartedTime,_miniStakePeriodInSeconds);
        UserInfo storage user = _userInfo[account];
        StakeRecord storage record = user.stakeInfo[key];
        //update user's record
        record.amount = record.amount.add(amount);
        record.timeKey = key;
        //update staked amount of this user
        user.amount = user.amount.add(amount);
        
        _updateIndexAfterDeposit(account, key, amount);

        emit DepositToMining(msg.sender,amount);
    }

    /**
     * @dev deposit reward token from account to last period
     */
    function depositRewardFromForYesterday(uint256 amount)public {
        uint time= now.sub(_miniStakePeriodInSeconds);
        uint key = time.getTimeKey(_farmStartedTime,_miniStakePeriodInSeconds);
        _depositRewardFromForTime(address(msg.sender),amount,key);
    }

    function depositRewardFromForToday(uint256 amount)public {
        uint key = now.getTimeKey(_farmStartedTime,_miniStakePeriodInSeconds);
        _depositRewardFromForTime(address(msg.sender),amount,key);
    }

    function depositRewardFromForTime(address account,uint256 amount,uint time) public  onlyOwner{
        _depositRewardFromForTime(account, amount, time);
    }

    function _depositRewardFromForTime(address account,uint256 amount,uint time) internal {
        require(amount>0,"deposit number should greater than 0");
        _rewardToken.safeTransferFrom(account,address(this),amount);
        uint timeKey= time.getTimeKey(_farmStartedTime,_miniStakePeriodInSeconds);
        _initOrUpdateLowestWaterMarkAndTotalStaked(timeKey,0);
        //timeKey will definitely in _roundSlotsIndex after init

        RoundSlotInfo storage slot = _roundSlots[timeKey];
        uint256 previousAccumulate = 0;
        uint256 slotIndex = 0;
        // bool findKey = false;
        for (uint256 ii=_roundSlotsIndex.length;ii>0;ii--){
            uint key = _roundSlotsIndex[ii-1];
            if (key == timeKey){
                // findKey = true;
                slotIndex = ii-1;
                if (ii>1){
                    RoundSlotInfo storage previous = _roundSlots[_roundSlotsIndex[ii-2]];
                    if (previous.rAccumulateAmount>0){
                        previousAccumulate = previous.rAccumulateAmount;
                        break;
                    }
                }
                break;
            }
        }
        if (previousAccumulate>0 && slot.rAccumulateAmount==0){
            //if we find a previous accumulate and current accu is 0, set current slot's accumulate to previous one's
            slot.rAccumulateAmount = previousAccumulate;
        }
        slot.rAmount = slot.rAmount.add(amount);
        slot.rLastSubmiter = account;
        //update all accumulateamount from our slot to the latest one
        for (uint256 ii=slotIndex;ii<_roundSlotsIndex.length;ii++){
            uint key = _roundSlotsIndex[ii];
            RoundSlotInfo storage update = _roundSlots[key];
            update.rAccumulateAmount = update.rAccumulateAmount.add(amount);
        }

        _allTimeTotalMined = _allTimeTotalMined.add(amount);
        _totalRewardInPool = _totalRewardInPool.add(amount);

        emit DepositReward(account,amount,timeKey);
    }

    /**
     * @dev exit mining by withdraw all STokens
     */
    function withdrawAllSToken()public virtual{
        address account = address(msg.sender);
        UserInfo storage user = _userInfo[account];
        withdrawLatestSToken(user.amount);
    }


    /**
     * @dev exit mining by withdraw a part of STokens
     */
    function withdrawLatestSToken(uint256 amount)public{
        address account = address(msg.sender);
        UserInfo storage user = _userInfo[account];
        require(amount > 0,"you can't withdraw 0 amount");
        require(user.amount>=amount,"you can't withdraw amount larger than you have deposit");
        uint256 ii = user.stakedTimeIndex.length;
        require(ii>0,"no deposit record found");
        //we can't change the status for calculating reward before 2 rounds agao
        //because the user already staked full for mining 2 rounds agao
        uint alreadyMinedTimeKey = _getMaxAlreadyMinedTimeKey();
        updateAlreadyMinedReward(account,alreadyMinedTimeKey); 
        uint currentKey = now.getTimeKey(_farmStartedTime,_miniStakePeriodInSeconds);
        uint256 needCost = amount;

        bool[] memory toDelete = new bool[](ii);
        _initOrUpdateLowestWaterMarkAndTotalStaked(currentKey,0);
        RoundSlotInfo storage currentSlot = _roundSlots[currentKey];
        uint256 update = 0;
        for (ii;ii>0;ii--){
            if (needCost == 0){
                break;
            }
            uint timeKey = user.stakedTimeIndex[ii-1];
            
            StakeRecord storage record = user.stakeInfo[timeKey];
            RoundSlotInfo storage slot = _roundSlots[timeKey];
            update = record.amount.sub(record.withdrawed,"withdrawed>amount");
            if (needCost<=update){
                record.withdrawed = record.withdrawed.add(needCost);
                update = needCost;
                needCost = 0;
            }else{
                needCost = needCost.sub(update,"update>needCost");
                //withdrawed all of this record
                record.withdrawed = record.amount;
                //record maybe can be delete, withdrawed all
                if (_getRecordStaked(record)==0){
                    delete user.stakeInfo[timeKey];
                    toDelete[ii-1]=true;
                }
            }
            if (update>0){
                slot.totalStakedInSlot = slot.totalStakedInSlot.sub(update,"update>totalStakedInSlot");
            }
            if (update>0 && timeKey<currentKey){
                if (update<=currentSlot.stakedLowestWaterMark){
                    currentSlot.stakedLowestWaterMark = currentSlot.stakedLowestWaterMark.sub(update,"update > stakedLowestWaterMark");
                }else{
                    currentSlot.stakedLowestWaterMark = 0;
                }
                
            }
        }
        if (amount<=currentSlot.totalStaked){
            //maker it safer for withdraw SToken
            currentSlot.totalStaked = currentSlot.totalStaked.sub(amount,"amount>totalStaked");
        }

        for(uint256 xx=0;xx<toDelete.length;xx++){
            bool del = toDelete[xx];
            if (del){
                delete user.stakedTimeIndex[xx];
            }
        }
        _safeTokenTransfer(account,amount,_stoken);
        user.amount = user.amount.sub(amount,"amount>user.amount");
        emit Withdraw(account,amount); 
    }

    function _initOrUpdateLowestWaterMarkAndTotalStaked(uint nextKey,uint256 amount)internal{
        uint slotMaxLast = 0;
        RoundSlotInfo storage slot = _roundSlots[nextKey];
        if (_roundSlotsIndex.length>0){
            slotMaxLast = _roundSlotsIndex[_roundSlotsIndex.length-1];
        }
        if (slotMaxLast<nextKey){
            _roundSlotsIndex.push(nextKey);
            if (slotMaxLast!=0){
                //we have previous ones
                RoundSlotInfo storage previouSlot = _roundSlots[slotMaxLast];
                slot.totalStaked = previouSlot.totalStaked.add(amount);
                //firsttime init stakedLowestWaterMark
                slot.stakedLowestWaterMark = previouSlot.totalStaked;
            }else{
                //have no previous one
                slot.totalStaked = slot.totalStaked.add(amount);
                slot.stakedLowestWaterMark = 0;
            }
        }else{
            slot.totalStaked = slot.totalStaked.add(amount);
        }
    }

    function getAndUpdateRewardMinedInPool(address account) public returns (uint256){
        uint alreadyMinedTimeKey = _getMaxAlreadyMinedTimeKey(); 
        updateAlreadyMinedReward(account,alreadyMinedTimeKey);
        UserInfo storage user = _userInfo[account];
        return user.rewardBalanceInpool;
    }

    function updateAlreadyMinedReward(address account,uint before) public{
        uint256 minedTotal = getUncalculateRewardBalanceInPoolBefore(account,before);
        UserInfo storage user = _userInfo[account];
        user.rewardBalanceInpool = user.rewardBalanceInpool.add(minedTotal);
        user.allTimeMinedBalance = user.allTimeMinedBalance.add(minedTotal);
        user.lastUpdateRewardTime = before;
        //user.lastUpdateRewardTime+_miniStakePeriodInSeconds slot's reward already mined
    }


    /**
     * @dev claim all reward tokens
     */
    function claimAllReward(address account)public{
        uint256 totalMined = getAndUpdateRewardMinedInPool(account);
        claimAmountOfReward(account,totalMined,false);
    }

    /**
     * @dev claim amount of reward tokens
     */
    function claimAmountOfReward(address account,uint256 amount,bool reCalculate)public{
        if (reCalculate){
            getAndUpdateRewardMinedInPool(account);
        }
        UserInfo storage user = _userInfo[account];
        require(user.rewardBalanceInpool>=amount,"claim amount should not greater than total mined");

        user.rewardBalanceInpool = user.rewardBalanceInpool.sub(amount,"amount>rewardBalanceInpool");
        _safeTokenTransfer(account,amount,_rewardToken);
        user.allTimeRewardClaimed = user.allTimeRewardClaimed.add(amount);
        _totalRewardInPool = _totalRewardInPool.sub(amount,"amount>_totalRewardInPool");
        emit Claim(account,amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

library TokenUtility {
    using SafeMath for uint256;

    /**
     * @dev cost amount of token among balanceFreeTime Keys indexed in records with recordCostRecords
     * return cost keys and cost values one to one
     * LIFO
     */
    function calculateCostLocked(
        mapping(uint256 => uint256) storage records,
        uint256 toCost,
        uint256[] memory keys,
        mapping(uint256 => uint256) storage recordsCost
    ) internal view returns (uint256, uint256[] memory) {
        uint256 lockedFreeToMove = 0;
        uint256[] memory cost = new uint256[](keys.length);
        for (uint256 ii = keys.length; ii > 0; --ii) {
            //_lockTimeUnitPerSeconds:days:25*7,rounds:25
            if (toCost == 0) {
                break;
            }
            uint256 freeTime = keys[ii - 1];
            uint256 lockedBal = records[freeTime];
            uint256 alreadyCost = recordsCost[freeTime];

            uint256 lockedToMove =
                lockedBal.sub(alreadyCost, "alreadyCost>lockedBal");

            lockedFreeToMove = lockedFreeToMove.add(lockedToMove);
            if (lockedToMove >= toCost) {
                cost[ii - 1] = toCost;
                toCost = 0;
            } else {
                cost[ii - 1] = lockedToMove;
                toCost = toCost.sub(lockedToMove, "lockedToMove>toCost");
            }
        }
        return (lockedFreeToMove, cost);
    }

    /**
     * @dev a method to get time-key from a time parameter
     * returns time-key and round
     */
    function getTimeKey(
        uint256 time,
        uint256 _farmStartedTime,
        uint256 _miniStakePeriodInSeconds
    ) internal pure returns (uint256) {
        require(
            time > _farmStartedTime,
            "time should larger than all thing stated time"
        );
        //get the end time of period
        uint256 md =
            (time.sub(_farmStartedTime)).mod(_miniStakePeriodInSeconds);
        if (md == 0) return time;
        return time.add(_miniStakePeriodInSeconds).sub(md);
    }

    /**
     * @dev cost amount of token among balanceFreeTime Keys indexed in records with recordCostRecords
     * return cost keys and cost values one to one
     * LIFO
     */
    function calculateCostLockedWithoutSum(
        mapping(uint256 => uint256) storage records,
        uint256 toCost,
        uint256[] memory keys,
        mapping(uint256 => uint256) storage recordsCost
    ) internal view returns (uint256[] memory) {
        uint256[] memory cost = new uint256[](keys.length);
        uint256 freeTime;
        uint256 lockedBal;
        uint256 alreadyCost;
        uint256 lockedToMove;
        for (uint256 ii = keys.length; ii > 0; --ii) {
            //_lockTimeUnitPerSeconds:days:25*7,rounds:25
            if (toCost == 0) {
                break;
            }
            freeTime = keys[ii - 1];
            lockedBal = records[freeTime];
            alreadyCost = recordsCost[freeTime];

            lockedToMove = lockedBal.sub(alreadyCost, "alreadyCost>lockedBal");

            if (lockedToMove >= toCost) {
                cost[ii - 1] = toCost;
                toCost = 0;
            } else {
                cost[ii - 1] = lockedToMove;
                toCost = toCost.sub(lockedToMove, "lockedToMove>toCost");
            }
        }
        require(toCost == 0, "require toCost full consumed");
        return cost;
    }

    function calculateFreeAmount(
        uint256 freeTime,
        uint256 lockedBal,
        uint256 _lockRounds,
        uint256 _lockTime,
        uint256 _lockTimeUnitPerSeconds
    ) internal view returns (uint256, uint256) {
        uint256 remainTime = freeTime - block.timestamp;
        uint256 passedRound =
            _lockRounds.sub(
                _lockRounds.mul(remainTime).div(
                    _lockTime.mul(_lockTimeUnitPerSeconds)
                )
            );
        return (lockedBal.mul(passedRound).div(_lockRounds), passedRound);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 999999
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}
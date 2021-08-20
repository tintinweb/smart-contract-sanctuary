// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./Ownable.sol";


/**
 * Manages any vesting requirements for Minority token. Vested tokens will be paid out if executePendingVests is called after a payment is due
 * Owner is the token contract 
 */
contract MinorityVestingManager is Ownable {
    using SafeMath for uint256;
    
    // Contains all the information about a single vesting schedule
    struct VestingSchedule {
        uint256 totalTokensToVest;
        uint256 numberToVestEachEpoch;
        uint256 tokensVested;
        uint256 epochLength;
        uint256 startOfVesting;
        uint256 nextVestingTime;
        address vestedTokensReceiver;
        bool removed;
    }
    
    address public operator;
    
    VestingSchedule[] public vestingSchedules;
    
    address public immutable minorityToken;
    
    uint256 public nextRewardDue;
    uint256 public nextRewardID;
    uint256 public totalTokensUnderManagement;
    
    event VestingStartChanged (uint256 vestingID, uint256 oldStartOfVesting, uint256 newStartOfVesting);
    event ScheduleRemoved (uint256 vestingID);
    event TokensVested (uint256 vestingID, address indexed vestedTokensReceiver, uint256 tokensVested);
    event ScheduleAdded (
            uint256 newVestingID,
            uint256 totalTokensToVest,
            uint256 numberToVestEachEpoch,
            uint256 epochLength,
            uint256 startOfVesting,
            uint256 nextVestingTime,
            address vestedTokensReceiver
        );
    
    modifier onlyOwnerOrOperator {
        require(msg.sender == operator || msg.sender == owner(), "MinorityVestingManager: only accessible by operator or owner");
        _;
    }
    
    constructor (address _operator, address _token) {
        require (_operator != address(0), "MinorityVestingManager: Operator can't be the zero address");
        require (_token != address(0), "MinorityVestingManager: Minority token address can't be the zero address");
        operator = _operator;
        minorityToken = _token;
    }
    
    function addVestingSchedule (uint256 _totalTokensToVest, uint256 _percentToVestEachEpoch, uint256 _epochLengthInDays, uint256 _startOfVesting, address _vestedTokensReceiver)
        external 
        onlyOwnerOrOperator 
        returns (uint256) 
    {
        return addVestingSchedule (_totalTokensToVest, _percentToVestEachEpoch, _epochLengthInDays, _startOfVesting, _vestedTokensReceiver, true);
    }
    
    function addVestingSchedule (uint256 _totalTokensToVest, uint256 _percentToVestEachEpoch, uint256 _epochLengthInDays, uint256 _startOfVesting, address _vestedTokensReceiver, bool doSafetyCheck)
        public 
        onlyOwner 
        returns (uint256) 
    {
        require (_percentToVestEachEpoch < 100, "MinorityVestingManager: Can't vest > 100% of tokens per epoch");
        require (_startOfVesting >= block.timestamp || _startOfVesting == 0, "MinorityVestingManager: Rewards can't begin vesting in the past"); // 0 special case for not starting until set
        require (_vestedTokensReceiver != address(0), "MinorityVestingManager: vesting receiver can't be the zero address");
        uint256 newTotalTokensUnderManagement = totalTokensUnderManagement.add(_totalTokensToVest);
        
        if (doSafetyCheck)
            require (newTotalTokensUnderManagement <= IERC20(minorityToken).balanceOf(address(this)), "MinorityVestingManager: Not enough tokens in contract to vest. Transfer tokens before adding a schedule");
        
        uint256 _nextVestingTime = _startOfVesting == 0 ? _startOfVesting : _startOfVesting.add(_epochLengthInDays.mul(1 days));
        
        VestingSchedule memory newSchedule = VestingSchedule({
            totalTokensToVest: _totalTokensToVest,
            numberToVestEachEpoch: _totalTokensToVest.mul(_percentToVestEachEpoch).div(100),
            tokensVested: 0,
            epochLength: _epochLengthInDays.mul(1 days),
            startOfVesting: _startOfVesting,
            nextVestingTime: _nextVestingTime,
            vestedTokensReceiver: _vestedTokensReceiver,
            removed: false
        });
        
        vestingSchedules.push(newSchedule);
        totalTokensUnderManagement = newTotalTokensUnderManagement;
        uint256 newVestingScheduleID = vestingSchedules.length - 1;
        updateNextRewards (newVestingScheduleID, _nextVestingTime);
        
        emit ScheduleAdded (
            newVestingScheduleID,
            newSchedule.totalTokensToVest,
            newSchedule.numberToVestEachEpoch,
            newSchedule.epochLength,
            newSchedule.startOfVesting,
            newSchedule.nextVestingTime,
            newSchedule.vestedTokensReceiver
        );
        
        return newVestingScheduleID;
    }
    
    // Check whether the ID and time should be the nextReward ID and time
    function updateNextRewards (uint256 vestingID, uint256 nextVestingTime) private {
        if ((nextVestingTime < nextRewardDue || nextRewardDue == 0) && nextVestingTime != 0) {
            nextRewardDue = nextVestingTime;
            nextRewardID = vestingID;
        }
    }
    
    // Processes any pending vesting transactions
    function executePendingVests() external {
        if (nextRewardDue <= block.timestamp && nextRewardDue != 0) {
            VestingSchedule memory currentSchedule = vestingSchedules[nextRewardID];
            uint256 nextVest = currentSchedule.epochLength.add(block.timestamp);
            nextRewardDue = nextVest;
            uint256 tokensToSend = currentSchedule.numberToVestEachEpoch;
            
            if (currentSchedule.tokensVested.add(tokensToSend) > currentSchedule.totalTokensToVest) {
                tokensToSend = currentSchedule.totalTokensToVest.sub(currentSchedule.tokensVested);
                vestingSchedules[nextRewardID].nextVestingTime = 0;
                nextRewardDue = 0;
            } else 
                vestingSchedules[nextRewardID].nextVestingTime = nextVest;
                
            vestingSchedules[nextRewardID].tokensVested = currentSchedule.tokensVested.add(tokensToSend);
            IERC20(minorityToken).transfer (currentSchedule.vestedTokensReceiver, tokensToSend);
            emit TokensVested (nextRewardID, currentSchedule.vestedTokensReceiver, tokensToSend);
            findNextRewardID();
        } 
    }
    
    function findNextRewardID() private {
        uint256 schedulesLength = vestingSchedules.length;
        
        for (uint i = 0; i < schedulesLength; i++) {
            if (i != nextRewardID && !vestingSchedules[i].removed) {
                uint256 scheduleVesting = vestingSchedules[i].nextVestingTime;
                
                if (scheduleVesting != 0) {
                    // if it should have already been paid, then pay it next, else find the nearest vesting time of the remaining
                    if (scheduleVesting <= block.timestamp)  {
                        nextRewardDue = scheduleVesting;
                        nextRewardID = i;
                        break;
                    } else if (scheduleVesting < nextRewardDue || nextRewardDue == 0) {
                        nextRewardDue = scheduleVesting;
                        nextRewardID = i;
                    }
                }
            }
        }
    }
    
    function getVestingInfo (uint256 vestingID) public view returns (uint256, uint256, uint256, uint256, uint256, uint256, address, bool) {
        require (vestingID < vestingSchedules.length, "MinorityVestingManager: invalid ID");
        VestingSchedule memory schedule = vestingSchedules[vestingID];
        return (
            schedule.totalTokensToVest,
            schedule.numberToVestEachEpoch,
            schedule.tokensVested,
            schedule.epochLength,
            schedule.startOfVesting,
            schedule.nextVestingTime,
            schedule.vestedTokensReceiver,
            schedule.removed
        );
    }
    
    // Allows the start time of a schedule to be changed, even if the schedule has already started (will just delay the next payment to newStartTime + epochLength)
    function modifyVestingStartTime (uint256 vestingID, uint256 newVestingStart) external onlyOwnerOrOperator {
        require (vestingID < vestingSchedules.length, "MinorityVestingManager: invalid ID");
        require (newVestingStart > block.timestamp, "MinorityVestingManager: vesting must start in the future");
        require (!vestingSchedules[vestingID].removed, "MinorityVestingManager: vesting ID removed");
        emit VestingStartChanged (vestingID, vestingSchedules[vestingID].startOfVesting, newVestingStart);
        uint256 newNextVestingTime = newVestingStart.add(vestingSchedules[vestingID].epochLength);
        vestingSchedules[vestingID].startOfVesting = newVestingStart;
        vestingSchedules[vestingID].nextVestingTime = newNextVestingTime;
        
        if (nextRewardID == vestingID)
            findNextRewardID();
        else
            updateNextRewards (vestingID, newNextVestingTime);
    }
    
    // Sets removed to true, and releases unvested tokens. Does this to maintain history of tokensVested rather than deleting the entry
    function removeVestingSchedule (uint256 vestingID) external onlyOwnerOrOperator {
        require (vestingID < vestingSchedules.length, "MinorityVestingManager: invalid ID");
        require (!vestingSchedules[vestingID].removed, "MinorityVestingManager: vesting ID already removed");
        vestingSchedules[vestingID].removed = true;
        // Release unvested tokens back into totalTokensUnderManagement so they can be revested
        totalTokensUnderManagement = totalTokensUnderManagement.sub(vestingSchedules[vestingID].totalTokensToVest).add(vestingSchedules[vestingID].tokensVested);
        
        if (nextRewardID == vestingID)
            findNextRewardID();
        
        emit ScheduleRemoved (vestingID);
    }
   
    
}
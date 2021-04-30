// SPDX-License-Identifier: --GRISE--

pragma solidity =0.7.6;

import "./Snapshot.sol";

contract StakingToken is Snapshot {

    using SafeMath for uint256;
    receive() payable external {}

    constructor(address _immutableAddress) Declaration(_immutableAddress) {}

   /**
     * @notice allows to create stake directly with ETH
     * if you don't have GRISE tokens method will convert
     * and use amount returned from UNISWAP to open a stake
     * @param _lockDays amount of days it is locked for.
     */
    function createStakeWithETH(
        uint256 _stakedAmount,
        StakeType _stakeType,
        uint64 _lockDays
    )
        external
        payable
        returns (bytes16, uint256)
    {
        address[] memory path = new address[](2);
            path[0] = WETH;
            path[1] = address(GRISE_CONTRACT);

        uint256[] memory amounts =
        UNISWAP_ROUTER.swapETHForExactTokens{value: msg.value}(
            _stakedAmount.add(_stakedAmount.mul(400).div(10000)),
            path,
            msg.sender,
            block.timestamp + 2 hours
        );

        if (msg.value > amounts[0])
        {
            (bool success, ) = msg.sender.call{value: msg.value.sub(amounts[0])}("Pending Ether");
            require(success, 'Grise: Pending ETH transfer failed');
        }

        return createStake(
            _stakedAmount,
            _stakeType,
            _lockDays
        );
    }
    
    /**
     * @notice A method for a staker to create a stake
     * @param _stakedAmount amount of GRISE staked.
     * @param _stakeType Small/Medium/Large.
     * @param _lockDays amount of days it is locked for.
     */
    function createStake(
        uint256 _stakedAmount,
        StakeType _stakeType,
        uint64 _lockDays
    )
        snapshotTrigger
        public
        returns (bytes16, uint256)
    {
        // stakingSlot will be 0 for short/long term staking and
        // stakingSlot will be 0,1,2 for 3,6,9 month medium term staking respectively.
        uint8 stakingSlot; 

        if (_stakeType == StakeType.MEDIUM_TERM){
            if (_lockDays == 168){ // 6 Month
                stakingSlot = 1;
            } else if (_lockDays == 252){ // 9 Month
                stakingSlot = 2;
            }
        }

        require(
            _lockDays % GRISE_WEEK == 0 &&
            _lockDays >= stakeDayLimit[_stakeType].minStakeDay &&
            _lockDays <= stakeDayLimit[_stakeType].maxStakeDay,
            'GRISE: stake is not in range'
        );

        require(
            _stakedAmount >= stakeCaps[_stakeType][stakingSlot].minStakingAmount && 
            _stakedAmount.mod(stakeCaps[_stakeType][stakingSlot].minStakingAmount) == 0,
            'GRISE: stake is not large enough or StakingAmount is not Valid'
        );

        require(
            stakeCaps[_stakeType][stakingSlot].stakingSlotCount <= 
                    stakeCaps[_stakeType][stakingSlot].maxStakingSlot ,
            'GRISE: All staking slot is occupied not extra slot is available'
        );

        uint256 newOccupiedSlotCount = _stakedAmount
                                      .mod(stakeCaps[_stakeType][stakingSlot].minStakingAmount) != 0?
                                      _stakedAmount
                                      .div(stakeCaps[_stakeType][stakingSlot].minStakingAmount) + 1 :
                                      _stakedAmount
                                      .div(stakeCaps[_stakeType][stakingSlot].minStakingAmount);

        require(
            (stakeCaps[_stakeType][stakingSlot].stakingSlotCount + newOccupiedSlotCount <= 
                    stakeCaps[_stakeType][stakingSlot].maxStakingSlot),
            'GRISE: All staking slot is occupied not extra slot is available'
        );

        stakeCaps[_stakeType][stakingSlot].stakingSlotCount = 
        stakeCaps[_stakeType][stakingSlot].stakingSlotCount.add(newOccupiedSlotCount);

        (
            Stake memory newStake,
            bytes16 stakeID,
            uint256 _startDay
        ) =

        _createStake(msg.sender, _stakedAmount, _lockDays, _stakeType, newOccupiedSlotCount);

        stakes[msg.sender][stakeID] = newStake;

        _increaseStakeCount(
            msg.sender
        );

        _increaseGlobals(
            uint8(newStake.stakeType),
            newStake.stakedAmount,
            newStake.stakesShares
        );
        
        _addScheduledShares(
            newStake.finalDay,
            newStake.stakesShares
        );

        GRISE_CONTRACT.setStaker(msg.sender);
        GRISE_CONTRACT.updateStakedToken(globals.totalStaked);

        if (newStake.stakeType != StakeType.SHORT_TERM) {
            GRISE_CONTRACT.updateMedTermShares(globals.MLTShares);
        }

        stakeCaps[_stakeType][stakingSlot].totalStakeCount++;

        emit StakeStart(
            stakeID,
            msg.sender,
            uint256(newStake.stakeType),
            newStake.stakedAmount,
            newStake.stakesShares,
            newStake.startDay,
            newStake.lockDays
        );

        return (stakeID, _startDay);
    }

    /**
    * @notice A method for a staker to start a stake
    * @param _staker ...
    * @param _stakedAmount ...
    * @param _lockDays ...
    * @param _stakeType ...
    * @param _totalOccupiedSlot ...
    */
    function _createStake(
        address _staker,
        uint256 _stakedAmount,
        uint64 _lockDays,
        StakeType  _stakeType,
        uint256 _totalOccupiedSlot
    )
        private
        returns (
            Stake memory _newStake,
            bytes16 _stakeID,
            uint256 _startDay
        )
    {
        require(
            GRISE_CONTRACT.balanceOfStaker(_staker) >= _stakedAmount,
            "GRISE: Staker doesn't have enough balance"
        );

        GRISE_CONTRACT.burnSupply(
            _staker,
            _stakedAmount
        );

        _startDay = currentGriseDay() + 1;
        _stakeID = generateStakeID(_staker);

        _newStake.stakeType = _stakeType;
        _newStake.totalOccupiedSlot = _totalOccupiedSlot;
        _newStake.lockDays = _lockDays;
        _newStake.startDay = _startDay;
        _newStake.finalDay = _startDay + _lockDays;
        _newStake.isActive = true;

        _newStake.stakedAmount = _stakedAmount;
        _newStake.stakesShares = _stakesShares(
            _stakedAmount,
            globals.sharePrice
        );
    }

    /**
    * @notice A method for a staker to remove a stake
    * belonging to his address by providing ID of a stake.
    * @param _stakeID unique bytes sequence reference to the stake
    */
    function endStake(
        bytes16 _stakeID
    )
        snapshotTrigger
        external
        returns (uint256)
    {
        (
            Stake memory endedStake,
            uint256 penaltyAmount
        ) =

        _endStake(
            msg.sender,
            _stakeID
        );

        _decreaseGlobals(
            uint8(endedStake.stakeType),
            endedStake.stakedAmount,
            endedStake.stakesShares
        );

        _removeScheduledShares(
            endedStake.finalDay,
            endedStake.stakesShares
        );

        _storePenalty(
            endedStake.closeDay,
            penaltyAmount
        );

        uint8 stakingSlot; 
        if (endedStake.stakeType == StakeType.MEDIUM_TERM){
            if (endedStake.lockDays == 168) { // 6 Month
                stakingSlot = 1;
            } else if (endedStake.lockDays == 252) { // 9 Month
                stakingSlot = 2;
            }
        }

        stakeCaps[endedStake.stakeType][stakingSlot].stakingSlotCount = 
        stakeCaps[endedStake.stakeType][stakingSlot].stakingSlotCount.sub(endedStake.totalOccupiedSlot);
        
        GRISE_CONTRACT.resetStaker(msg.sender);
        GRISE_CONTRACT.updateStakedToken(globals.totalStaked);

        if (endedStake.stakeType != StakeType.SHORT_TERM) {
            GRISE_CONTRACT.updateMedTermShares(globals.MLTShares);
        }
        
        stakeCaps[endedStake.stakeType][stakingSlot].totalStakeCount--;

        emit StakeEnd(
            _stakeID,
            msg.sender,
            uint256(endedStake.stakeType),
            endedStake.stakedAmount,
            endedStake.stakesShares,
            endedStake.rewardAmount,
            endedStake.closeDay,
            penaltyAmount
        );

        return endedStake.rewardAmount;
    }

    /**
    * @notice A method for a staker to end a stake
    * @param _staker ...
    * @param _stakeID ...
    */
    function _endStake(
        address _staker,
        bytes16 _stakeID
    )
        private
        returns (
            Stake storage _stake,
            uint256 _penalty
        )
    {
        require(
            stakes[_staker][_stakeID].isActive,
            'GRISE: Not an active stake'
        );

        uint256 transFeeCompensation;
        _stake = stakes[_staker][_stakeID];
        _stake.closeDay = currentGriseDay();
        _stake.rewardAmount = _calculateRewardAmount(_stake);
        _penalty = _calculatePenaltyAmount(_stake);

        if (_stake.stakeType == StakeType.SHORT_TERM)
        {
            transFeeCompensation = (_stake.stakedAmount
                                    .add(_stake.rewardAmount)
                                    .sub(_penalty))
                                    .mul(ST_STAKER_COMPENSATION)
                                    .div(REWARD_PRECISION_RATE);
        }
        else
        {
            transFeeCompensation = (_stake.stakedAmount
                                    .add(_stake.rewardAmount)
                                    .sub(_penalty))
                                    .mul(MLT_STAKER_COMPENSATION)
                                    .div(REWARD_PRECISION_RATE);
        }
        _stake.isActive = false;

        GRISE_CONTRACT.mintSupply(
            _staker,
            _stake.stakedAmount > _penalty ?
            _stake.stakedAmount - _penalty : 0
        );

        GRISE_CONTRACT.mintSupply(
            _staker,
            _stake.rewardAmount
        );

        GRISE_CONTRACT.mintSupply(
            _staker,
            transFeeCompensation
        );
    }

    /**
    * @notice alloes to scrape Reward from active stake
    * @param _stakeID unique bytes sequence reference to the stake
    */
    function scrapeReward(
        bytes16 _stakeID
    )
        external
        snapshotTrigger
        returns (
            uint256 scrapeDay,
            uint256 scrapeAmount
        )
    {
        require(
            stakes[msg.sender][_stakeID].isActive,
            'GRISE: Not an active stake'
        );

        Stake memory stake = stakes[msg.sender][_stakeID];

        require(
            globals.currentGriseDay >= stake.finalDay || 
                _startingDay(stake) < currentGriseDay().sub(currentGriseDay().mod(GRISE_WEEK)),
            'GRISE: Stake is not yet mature to claim Reward'
        );

        scrapeDay = _calculationDay(stake);

        scrapeDay = scrapeDay < stake.finalDay
            ? scrapeDay.sub(scrapeDay.mod(GRISE_WEEK))
            : scrapeDay;

        scrapeAmount = getTranscRewardAmount(msg.sender, _stakeID);

        scrapeAmount += getPenaltyRewardAmount(msg.sender, _stakeID);

        scrapeAmount += getReservoirRewardAmount(msg.sender, _stakeID);

        scrapes[msg.sender][_stakeID] =
        scrapes[msg.sender][_stakeID].add(scrapeAmount);
        
        stake.scrapeDay = scrapeDay;
        stakes[msg.sender][_stakeID] = stake;

        GRISE_CONTRACT.mintSupply(
            msg.sender,
            scrapeAmount
        );

        emit InterestScraped(
            _stakeID,
            msg.sender,
            scrapeAmount,
            scrapeDay,
            currentGriseDay()
        );
    }

    function _addScheduledShares(
        uint256 _finalDay,
        uint256 _shares
    )
        internal
    {
        scheduledToEnd[_finalDay] =
        scheduledToEnd[_finalDay].add(_shares);
    }

    function _removeScheduledShares(
        uint256 _finalDay,
        uint256 _shares
    )
        internal
    {
        if (_notPast(_finalDay)) {

            scheduledToEnd[_finalDay] =
            scheduledToEnd[_finalDay] > _shares ?
            scheduledToEnd[_finalDay] - _shares : 0;

        } else {

            uint256 _day = currentGriseDay() - 1;
            snapshots[_day].scheduledToEnd =
            snapshots[_day].scheduledToEnd > _shares ?
            snapshots[_day].scheduledToEnd - _shares : 0;
        }
    }

    function checkMatureStake(
        address _staker,
        bytes16 _stakeID
    )
        external
        view
        returns (bool isMature)
    {
        Stake memory stake = stakes[_staker][_stakeID];
        isMature = _isMatureStake(stake);
    }

    function checkStakeByID(
        address _staker,
        bytes16 _stakeID
    )
        external
        view
        returns 
    (
        uint256 startDay,
        uint256 lockDays,
        uint256 finalDay,
        uint256 closeDay,
        uint256 scrapeDay,
        StakeType stakeType,
        uint256 slotOccupied,
        uint256 stakedAmount,
        uint256 penaltyAmount,
        bool isActive,
        bool isMature
    )
    {
        Stake memory stake = stakes[_staker][_stakeID];
        startDay = stake.startDay;
        lockDays = stake.lockDays;
        finalDay = stake.finalDay;
        closeDay = stake.closeDay;
        scrapeDay = stake.scrapeDay;
        stakeType = stake.stakeType;
        slotOccupied = stake.totalOccupiedSlot;
        stakedAmount = stake.stakedAmount;
        penaltyAmount = _calculatePenaltyAmount(stake);
        isActive = stake.isActive;
        isMature = _isMatureStake(stake);
    }

    function checkStakeRewards(
        address _staker,
        bytes16 _stakeID
    )
        external
        view
        returns 
    (
        uint256 transcRewardAmount,
        uint256 penaltyRewardAmount,
        uint256 reservoirRewardAmount,
        uint256 inflationRewardAmount
    )
    {
        transcRewardAmount = getTranscRewardAmount(_staker, _stakeID);
        penaltyRewardAmount = getPenaltyRewardAmount(_staker, _stakeID);
        reservoirRewardAmount = getReservoirRewardAmount(_staker, _stakeID);
        inflationRewardAmount = getInflationRewardAmount(_staker, _stakeID);
    }

    function updateStakingSlotLimit(
        uint256 STSlotLimit,
        uint256 MT3MonthSlotLimit,
        uint256 MT6MonthSlotLimit,
        uint256 MT9MonthSlotLimit,
        uint256 LTSlotLimit
    )
    external
    {
        require(
            msg.sender == contractDeployer,
            'Operation Denied'
        );

        stakeCaps[StakeType.SHORT_TERM][0].maxStakingSlot = STSlotLimit;
        stakeCaps[StakeType.MEDIUM_TERM][0].maxStakingSlot = MT3MonthSlotLimit;
        stakeCaps[StakeType.MEDIUM_TERM][1].maxStakingSlot = MT6MonthSlotLimit;
        stakeCaps[StakeType.MEDIUM_TERM][2].maxStakingSlot = MT9MonthSlotLimit;
        stakeCaps[StakeType.LONG_TERM][0].maxStakingSlot = LTSlotLimit;
    }

    function getTranscRewardAmount(
        address _staker,
        bytes16 _stakeID
    ) 
        private
        view
        returns (uint256 rewardAmount)
    {
        Stake memory _stake = stakes[_staker][_stakeID];

        if ( _stakeEligibleForWeeklyReward(_stake))
        {
            uint256 _endDay = currentGriseDay() >= _stake.finalDay ? 
                                _stake.finalDay : 
                                currentGriseDay().sub(currentGriseDay().mod(GRISE_WEEK));

            rewardAmount = _loopTranscRewardAmount(
                _stake.stakesShares,
                _startingDay(_stake),
                _endDay,
                _stake.stakeType);
        }
    }

    function getPenaltyRewardAmount(
        address _staker,
        bytes16 _stakeID
    ) 
        private 
        view 
        returns (uint256 rewardAmount) 
    {
        Stake memory _stake = stakes[_staker][_stakeID];

        if ( _stakeEligibleForWeeklyReward(_stake))
        {
            uint256 _endDay = currentGriseDay() >= _stake.finalDay ? 
                                _stake.finalDay : 
                                currentGriseDay().sub(currentGriseDay().mod(GRISE_WEEK));

            rewardAmount = _loopPenaltyRewardAmount(
                _stake.stakesShares,
                _startingDay(_stake),
                _endDay,
                _stake.stakeType);
        }
    }

    function getReservoirRewardAmount(
        address _staker,
        bytes16 _stakeID
    ) 
        private 
        view 
        returns (uint256 rewardAmount) 
    {
        Stake memory _stake = stakes[_staker][_stakeID];

        if ( _stakeEligibleForMonthlyReward(_stake))
        {
            uint256 _endDay = currentGriseDay() >= _stake.finalDay ? 
                                _stake.finalDay : 
                                currentGriseDay().sub(currentGriseDay().mod(GRISE_MONTH));

            rewardAmount = _loopReservoirRewardAmount(
                _stake.stakesShares,
                _startingDay(_stake),
                _endDay,
                _stake.stakeType
            );
        }
    }

    function getInflationRewardAmount(
        address _staker,
        bytes16 _stakeID
    ) 
        private 
        view 
        returns (uint256 rewardAmount) 
    {    
        Stake memory _stake = stakes[_staker][_stakeID];

        if ( _stake.isActive && !_stakeNotStarted(_stake))
        {
            rewardAmount = _loopInflationRewardAmount(
            _stake.stakesShares,
            _stake.startDay,
            _calculationDay(_stake),
            _stake.stakeType);
        }
    }

    function _stakesShares(
        uint256 _stakedAmount,
        uint256 _sharePrice
    )
        private
        pure
        returns (uint256)
    {
        return _stakedAmount
                .div(_sharePrice);
    }

    function _storePenalty(
        uint256 _storeDay,
        uint256 _penalty
    )
        private
    {
        if (_penalty > 0) {
            totalPenalties[_storeDay] =
            totalPenalties[_storeDay].add(_penalty);

            MLTPenaltiesRewardPerShares[_storeDay] += 
                _penalty.mul(MED_LONG_STAKER_PENALTY_REWARD)
                        .div(REWARD_PRECISION_RATE)
                        .div(globals.MLTShares);

            STPenaltiesRewardPerShares[_storeDay] +=
                _penalty.mul(SHORT_STAKER_PENALTY_REWARD)
                        .div(REWARD_PRECISION_RATE)
                        .div(globals.STShares);

            ReservoirPenaltiesRewardPerShares[_storeDay] +=
                _penalty.mul(RESERVOIR_PENALTY_REWARD)
                        .div(REWARD_PRECISION_RATE)
                        .div(globals.MLTShares);

            GRISE_CONTRACT.mintSupply(
                TEAM_ADDRESS,
                _penalty.mul(TEAM_PENALTY_REWARD)
                        .div(REWARD_PRECISION_RATE)
            );

            GRISE_CONTRACT.mintSupply(
                DEVELOPER_ADDRESS,
                _penalty.mul(DEVELOPER_PENALTY_REWARD)
                        .div(REWARD_PRECISION_RATE)
            );
        }
    }

    function _calculatePenaltyAmount(
        Stake memory _stake
    )
        private
        view
        returns (uint256)
    {
        return _stakeNotStarted(_stake) || _isMatureStake(_stake) ? 0 : _getPenalties(_stake);
    }

    function _getPenalties(
        Stake memory _stake
    )
        private
        view
        returns (uint256)
    {
        return _stake.stakedAmount * ((PENALTY_RATE * (_daysLeft(_stake) - 1) / (_getLockDays(_stake)))) / 10000;
    }

    function _calculateRewardAmount(
        Stake memory _stake
    )
        private
        view
        returns (uint256 _rewardAmount)
    {
        _rewardAmount = _loopPenaltyRewardAmount(
            _stake.stakesShares,
            _startingDay(_stake),
            _calculationDay(_stake),
            _stake.stakeType
        );

        _rewardAmount += _loopTranscRewardAmount(
            _stake.stakesShares,
            _startingDay(_stake),
            _calculationDay(_stake),
            _stake.stakeType
        );

        _rewardAmount += _loopReservoirRewardAmount(
            _stake.stakesShares,
            _startingDay(_stake),
            _calculationDay(_stake),
             _stake.stakeType
        );
        
        _rewardAmount += _loopInflationRewardAmount(
            _stake.stakesShares,
            _stake.startDay,
            _calculationDay(_stake),
            _stake.stakeType
        );
    }

    function _loopInflationRewardAmount(
        uint256 _stakeShares,
        uint256 _startDay,
        uint256 _finalDay,
        StakeType _stakeType
    )
        private
        view
        returns (uint256 _rewardAmount)
    {
        uint256 inflationAmount;
        if (_stakeType == StakeType.SHORT_TERM)
        {
            return 0;
        }

        for (uint256 _day = _startDay; _day < _finalDay; _day++) {

            inflationAmount = (_stakeType == StakeType.MEDIUM_TERM) ? 
                                snapshots[_day].inflationAmount
                                .mul(MED_TERM_INFLATION_REWARD)
                                .div(REWARD_PRECISION_RATE) :
                                snapshots[_day].inflationAmount
                                .mul(LONG_TERM_INFLATION_REWARD)
                                .div(REWARD_PRECISION_RATE);

            _rewardAmount = _rewardAmount
                            .add(_stakeShares
                                    .mul(PRECISION_RATE)
                                    .div(inflationAmount));
        }
    }

    function _loopPenaltyRewardAmount(
        uint256 _stakeShares,
        uint256 _startDay,
        uint256 _finalDay,
        StakeType _stakeType
    )
        private
        view
        returns (uint256 _rewardAmount)
    {
        for (uint256 day = _startDay; day < _finalDay; day++) 
        {
            if (_stakeType == StakeType.SHORT_TERM)
            {
                _rewardAmount += STPenaltiesRewardPerShares[day]
                                    .mul(_stakeShares);
            } else {
                _rewardAmount += MLTPenaltiesRewardPerShares[day]
                                    .mul(_stakeShares);
            }
        }
    }

    function _loopReservoirRewardAmount(
        uint256 _stakeShares,
        uint256 _startDay,
        uint256 _finalDay,
        StakeType _stakeType
    )
        private
        view
        returns (uint256 _rewardAmount)
    {
        if (_stakeType == StakeType.SHORT_TERM)
        {
            return 0;
        }

        for (uint256 day = _startDay; day < _finalDay; day++) 
        {
            _rewardAmount = 
            _rewardAmount.add(ReservoirPenaltiesRewardPerShares[day]);
        }

        _rewardAmount = 
        _rewardAmount.add(GRISE_CONTRACT.getReservoirReward(_startDay, _finalDay));

        _rewardAmount = 
        _rewardAmount.mul(_stakeShares);
    }

    function _loopTranscRewardAmount(
        uint256 _stakeShares,
        uint256 _startDay,
        uint256 _finalDay,
        StakeType _stakeType
    )
        private
        view
        returns (uint256 _rewardAmount)
    {
        uint256 stakedAmount = _stakeShares.mul(globals.sharePrice);
        
        if (_stakeType != StakeType.SHORT_TERM)
        {
            _rewardAmount =
            _rewardAmount.add(GRISE_CONTRACT.getTransFeeReward(_startDay, _finalDay)
                                .mul(_stakeShares)); 
        }

        _rewardAmount =
        _rewardAmount.add(GRISE_CONTRACT.getTokenHolderReward(_startDay, _finalDay)
                            .mul(stakedAmount)
                            .div(PRECISION_RATE));
    }

    function getSlotLeft() 
        external 
        view 
        returns 
    (
        uint256 STSlotLeft, 
        uint256 MT3MonthSlotLeft,
        uint256 MT6MonthSlotLeft, 
        uint256 MT9MonthSlotLeft, 
        uint256 LTSlotLeft
    ) 
    {

        STSlotLeft = stakeCaps[StakeType.SHORT_TERM][0].maxStakingSlot
                            .sub(stakeCaps[StakeType.SHORT_TERM][0].stakingSlotCount);

        MT3MonthSlotLeft = stakeCaps[StakeType.MEDIUM_TERM][0].maxStakingSlot
                            .sub(stakeCaps[StakeType.MEDIUM_TERM][0].stakingSlotCount);
                            
        MT6MonthSlotLeft = stakeCaps[StakeType.MEDIUM_TERM][1].maxStakingSlot
                            .sub(stakeCaps[StakeType.MEDIUM_TERM][1].stakingSlotCount);

        MT9MonthSlotLeft = stakeCaps[StakeType.MEDIUM_TERM][2].maxStakingSlot
                            .sub(stakeCaps[StakeType.MEDIUM_TERM][2].stakingSlotCount);
        
        LTSlotLeft = stakeCaps[StakeType.LONG_TERM][0].maxStakingSlot
                            .sub(stakeCaps[StakeType.LONG_TERM][0].stakingSlotCount);
    }

    function getStakeCount() 
        external 
        view 
        returns 
    (
        uint256 STStakeCount, 
        uint256 MT3MonthStakeCount,
        uint256 MT6MonthStakeCount,
        uint256 MT9MonthStakeCount,
        uint256 LTStakeCount
    )
    {
        STStakeCount = stakeCaps[StakeType.SHORT_TERM][0].totalStakeCount;
        MT3MonthStakeCount = stakeCaps[StakeType.MEDIUM_TERM][0].totalStakeCount;
        MT6MonthStakeCount = stakeCaps[StakeType.MEDIUM_TERM][1].totalStakeCount;
        MT9MonthStakeCount = stakeCaps[StakeType.MEDIUM_TERM][2].totalStakeCount;
        LTStakeCount = stakeCaps[StakeType.LONG_TERM][0].totalStakeCount;
    }

    function getTotalStakedToken()
        external
        view 
        returns (uint256) 
    {
        return globals.totalStaked;
    }
}
// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;
// Base
import './StakeBase.sol';
// OpenZeppelin
import '@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
// Interfaces
import '../interfaces/IStakeManager.sol';

import '../libs/AxionSafeCast.sol';

contract StakeManager is IStakeManager, StakeBase {
    using AxionSafeCast for uint256;
    using SafeCastUpgradeable for uint256;
    /* Contract Variables ---------------------------------------------------------------------------------------*/

    Settings internal settings;
    Contracts internal contracts;
    StatFields internal statFields;
    InterestFields internal interestFields;

    uint256[] public interestPerShare;
    mapping(uint256 => StakeData) internal stakeData;

    //mapping(uint256 => bool) internal stakeWithdrawn; - might use later if we set stake values to 0

    /* Set Stakes ------------------------------------------------------------------------------------------------*/

    function recoverStake(
        address staker,
        uint256 start,
        uint256 shares,
        uint256 amount,
        uint256 stakingDays,
        uint256 firstPayout
    ) external override onlyExternalCaller returns (uint256) {
        statFields.lastStakeId++;
        shares = (shares * 1e12) / 1e12;

        addToGlobalTotals(amount, shares);
        createStakeInternal(
            NewStake({
                id: statFields.lastStakeId,
                amount: amount,
                shares: shares,
                start: start,
                stakingDays: stakingDays,
                firstInterestDay: firstPayout
            })
        );

        contracts.ventureCapital.addTotalSharesOfAndRebalance(staker, shares); // 15k after first stake
        if (stakingDays >= settings.bpdDayRange) {
            contracts.bpd.addBpdShares(shares, start, stakingDays);
        }

        emit StakeCreated(
            staker,
            statFields.lastStakeId,
            stakeData[statFields.lastStakeId].amount,
            stakeData[statFields.lastStakeId].shares,
            stakeData[statFields.lastStakeId].start,
            stakeData[statFields.lastStakeId].stakingDays
        );

        return statFields.lastStakeId;
    }

    /** Set New Stake
        Description: Add stake to database
        @param staker {address} - Address of staker to add new stake for (Users can stake for eachother?)
        @param amount {uint256} - Amount to stake / burn from wallet
        @param stakingDays {uint256} - Length of stake
    */
    function createStake(
        address staker,
        uint256 amount,
        uint256 stakingDays
    ) external override onlyExternalCaller returns (uint256) {
        statFields.lastStakeId++; // 7k

        //** TODO: Think about this */
        uint256 shares = getStakersSharesAmountInternal(amount, stakingDays); // 1k gas

        addToGlobalTotals(amount, shares); // 10k
        createStakeInternal( // 35k
            NewStake({
                id: statFields.lastStakeId,
                amount: amount,
                shares: shares,
                start: block.timestamp,
                stakingDays: stakingDays,
                firstInterestDay: interestPerShare.length
            })
        );

        contracts.ventureCapital.addTotalSharesOfAndRebalance(staker, shares); // 15k after first stake

        if (stakingDays >= settings.bpdDayRange) {
            // 30k
            contracts.bpd.addBpdShares(shares, block.timestamp, stakingDays);
        }

        emit StakeCreated( // 5k
            staker,
            statFields.lastStakeId,
            stakeData[statFields.lastStakeId].amount,
            stakeData[statFields.lastStakeId].shares,
            stakeData[statFields.lastStakeId].start,
            stakeData[statFields.lastStakeId].stakingDays
        );

        return statFields.lastStakeId;
    }

    /** @dev createManagerStake
        Description: Will be deleted after all merged.
        @param staker {address} - Address of staker to add new stake for (Users can stake for eachother?)
        @param amount {uint256} - Amount to stake / burn from wallet
        @param shares {uint256} - shares amount
        @param stakingDays {uint256} - Length of stake
        @param start {uint256} - Start of stake
     */
    function createManagerStake(
        address staker,
        uint256 amount,
        uint256 shares,
        uint256 stakingDays,
        uint256 start
    ) external override onlyExternalCaller returns (uint256) {
        statFields.lastStakeId++; // 7k

        addToGlobalTotals(amount, shares); // 10k
        createStakeInternal( // 35k
            NewStake({
                id: statFields.lastStakeId,
                amount: amount,
                shares: shares,
                start: start,
                stakingDays: stakingDays,
                firstInterestDay: interestPerShare.length
            })
        );

        contracts.ventureCapital.addTotalSharesOfAndRebalance(staker, shares); // 15k after first stake

        if (stakingDays >= settings.bpdDayRange) {
            // 30k
            contracts.bpd.addBpdShares(shares, start, stakingDays);
        }

        emit StakeCreated( // 5k
            staker,
            statFields.lastStakeId,
            stakeData[statFields.lastStakeId].amount,
            stakeData[statFields.lastStakeId].shares,
            stakeData[statFields.lastStakeId].start,
            stakeData[statFields.lastStakeId].stakingDays
        );

        return statFields.lastStakeId;
    }

    /** Upgrade Existing Stake
        Description: Upgrade existing stake layer 3 with max shares (5555 day stake)
        @param id {uint256} - ID should be less then LastSessionIdV3

        Modifier: OnlyExternalCaller - Can only be called by StakeUpgrader
     */
    function upgradeExistingStake(uint256 id, address staker) external override onlyExternalCaller {
        upgradeStakeInternal(
            StakeUpgrade({
                id: id,
                staker: staker,
                firstInterestDay: stakeData[id].firstInterestDay,
                shares: uint256(stakeData[id].shares) * 1e12,
                amount: uint256(stakeData[id].amount) * 1e12,
                start: stakeData[id].start,
                stakingDays: stakeData[id].stakingDays
            })
        );
    }

    /** Upgrade Existing Stake Internal (Common)
        Description: Internal reusable components for upgrading Stake
        @param stakeUpgrade {StakeUpgrade} Input Struct
     */
    function upgradeStakeInternal(StakeUpgrade memory stakeUpgrade) internal {
        uint256 newAmount =
            getStakeInterestInternal(
                stakeUpgrade.firstInterestDay,
                stakeUpgrade.stakingDays,
                stakeUpgrade.shares
            ) + stakeUpgrade.amount;

        uint256 intendedEnd =
            stakeUpgrade.start + (settings.secondsInDay * stakeUpgrade.stakingDays);

        // We use "Actual end" so that if a user tries to withdraw their BPD early they don't get the shares
        if (stakeUpgrade.stakingDays >= settings.bpdDayRange) {
            newAmount += contracts.bpd.getBpdAmount(
                stakeUpgrade.shares,
                stakeUpgrade.start,
                block.timestamp < intendedEnd ? block.timestamp : intendedEnd
            );
        }

        //** TODO: Think about this */
        uint256 newShares = getStakersSharesAmountInternal(newAmount, 5555);

        require(
            newShares > stakeUpgrade.shares,
            'STAKING: New shares are not greater then previous shares'
        );

        uint256 newEnd = block.timestamp + (uint256(settings.secondsInDay) * 5555);

        contracts.ventureCapital.addTotalSharesOfAndRebalance(
            stakeUpgrade.staker,
            newShares - stakeUpgrade.shares
        );
        contracts.bpd.addBpdMaxShares(
            stakeUpgrade.shares,
            stakeUpgrade.start,
            stakeUpgrade.start + (uint256(settings.secondsInDay) * stakeUpgrade.stakingDays),
            newShares,
            block.timestamp,
            newEnd
        );

        addToGlobalTotals(
            newAmount - (stakeUpgrade.amount / 1e12) * 1e12,
            newShares - (stakeUpgrade.shares / 1e12) * 1e12
        );

        createStakeInternal(
            NewStake({
                id: stakeUpgrade.id,
                amount: newAmount,
                shares: newShares,
                start: block.timestamp,
                stakingDays: 5555,
                firstInterestDay: interestPerShare.length
            })
        );

        emit StakeUpgraded(
            stakeUpgrade.staker,
            stakeUpgrade.id,
            stakeData[stakeUpgrade.id].amount,
            newAmount,
            stakeData[stakeUpgrade.id].shares,
            newShares,
            block.timestamp,
            newEnd
        );
    }

    /** formula for shares calculation given a number of AXN and a start and end date
        @param amount {uint256} - amount of AXN
        @param stakingDays {uint256}
    */
    function getStakersSharesAmountInternal(uint256 amount, uint256 stakingDays)
        internal
        view
        returns (uint256)
    {
        uint256 numerator = amount * (1819 + stakingDays);
        uint256 denominator = 1820 * uint256(interestFields.shareRate);

        uint256 shares = (numerator * 1e18) / denominator;
        return (shares / 1e12) * 1e12;
    }

    function getStakersSharesAmount(uint256 amount, uint256 stakingDays)
        external
        view
        returns (uint256)
    {
        return getStakersSharesAmountInternal(amount, stakingDays);
    }

    /** add to Global Totals
        @param amount {uint256}
        @param shares {uint256}
     */
    function addToGlobalTotals(uint256 amount, uint256 shares) internal {
        /** Set Global Variables */
        statFields.sharesTotalSupply += (shares / 1e12).toUint72();

        statFields.totalStakedAmount += (amount / 1e12).toUint72();

        statFields.totalVcaRegisteredShares += (shares / 1e12).toUint72();
    }

    /** Set Stake Internal
        @param stake {Stake} - Stake input
     */
    function createStakeInternal(NewStake memory stake) internal {
        //once a day we need to call makePayout which takes the interest earned for the last day and adds it into the payout array
        if (block.timestamp >= interestFields.nextAddInterestTimestamp) addDailyInterest();

        /** Set Stake data */
        stakeData[stake.id].amount = (stake.amount / 1e12).toUint64();
        stakeData[stake.id].shares = (stake.shares / 1e12).toUint64();
        stakeData[stake.id].start = stake.start.toUint40();
        stakeData[stake.id].stakingDays = stake.stakingDays.toUint16();
        stakeData[stake.id].firstInterestDay = stake.firstInterestDay.toUint24();
        stakeData[stake.id].status = StakeStatus.Active;
    }

    /* Unset Stakes ------------------------------------------------------------------------------------------------*/

    /** Unset Stake
        Description: Withdraw stake and close it out
        @param staker {address}
        @param id {uint256}

        Modifier: OnlyExternalCaller - Must be called by StakeBurner
     */
    function unsetStake(
        address staker,
        uint256 id,
        uint256 payout
    ) external override onlyExternalCaller {
        unsetStakeInternal(
            staker,
            id,
            uint256(stakeData[id].shares) * 1e12,
            uint256(stakeData[id].amount) * 1e12,
            payout
        );

        // stake.amount = 0;
        // stake.shares = 0;
        // stake.start = 0;
        // stake.length = 0;
        // stake.firstInterestDay = 0;
        // might do this later
    }

    /** Delete Stake Internal (Common)
        Description: Unset stakes common functinality function
        @param staker {address}
        @param id {uint256}
        @param shares {uint256}
        @param amount {uint256}
        @param payout {uint256}

        Modifier: OnlyExternalCaller - Must be called by StakeBurner
     */
    function unsetStakeInternal(
        address staker,
        uint256 id,
        uint256 shares,
        uint256 amount,
        uint256 payout
    ) internal {
        require(
            stakeData[id].status != StakeStatus.Withdrawn,
            'STAKE MANAGER: Stake withdrawn already.'
        );

        //once a day we need to call makePayout which takes the interest earned for the last day and adds it into the payout array
        if (block.timestamp >= interestFields.nextAddInterestTimestamp) addDailyInterest();

        // Subtract shares from IVentureCapital and rebalance
        contracts.ventureCapital.subTotalSharesOfAndRebalance(staker, shares);

        // Remove from global totals
        removeFromGlobalTotals(amount, shares);

        // Update payout and status to withdrawn
        stakeData[id].payout = (payout / 1e18).toUint40();
        stakeData[id].status = StakeStatus.Withdrawn;

        // Emit Event
        emit StakeDeleted(
            staker,
            id.toUint128(),
            stakeData[id].amount,
            stakeData[id].shares,
            stakeData[id].start,
            stakeData[id].stakingDays
        );
    }

    /** @dev remove from global totals
        Description: Remove amount and shares from global totals.
        @param amount {uint256}
        @param shares {uint256}
     */
    function removeFromGlobalTotals(uint256 amount, uint256 shares) internal {
        /** Set Global Variables */
        statFields.sharesTotalSupply -= (shares / 1e12).toUint72();
        statFields.totalStakedAmount -= (amount / 1e12).toUint72();
        statFields.totalVcaRegisteredShares -= (shares / 1e12).toUint72();
    }

    /** Get the interest earned for a particular stake.
        Description: staking interest calculation goes through the payout array and calculates the interest based on the number of shares the user has and the payout for every day
        @param firstInterestDay {uint256} - Beginning of stake days since start of contract
        @param stakingDays {uint256} - Stake days
        @param shares {uint256} - # of shares for stake
     */
    function getStakeInterestInternal(
        uint256 firstInterestDay,
        uint256 stakingDays,
        uint256 shares
    ) internal view returns (uint256) {
        uint256 lastInterest;
        uint256 firstInterest;
        uint256 lastInterestDay = firstInterestDay + stakingDays;

        if (interestPerShare.length != 0) {
            lastInterest = interestPerShare[
                MathUpgradeable.min(interestPerShare.length - 1, lastInterestDay - 1)
            ];
        }

        if (firstInterestDay != 0) {
            firstInterest = interestPerShare[firstInterestDay - 1];
        }

        return (shares * (lastInterest - firstInterest)) / 1e26;
    }

    function getStakeInterest(
        uint256 firstInterestDay,
        uint256 stakingDays,
        uint256 shares
    ) external view override returns (uint256) {
        return getStakeInterestInternal(firstInterestDay, stakingDays, shares);
    }

    function getStakeAndInterestById(uint256 stakeId)
        external
        view
        override
        returns (
            uint256 start,
            uint256 stakingDays,
            uint256 amount,
            uint256 shares,
            uint256 interest
        )
    {
        start = stakeData[stakeId].start;
        stakingDays = stakeData[stakeId].stakingDays;
        amount = uint256(stakeData[stakeId].amount) * 1e12;
        shares = uint256(stakeData[stakeId].shares) * 1e12;

        interest = getStakeInterestInternal(
            stakeData[stakeId].firstInterestDay,
            stakeData[stakeId].stakingDays,
            uint256(stakeData[stakeId].shares) * 1e12
        );
    }

    /** Interest ---------------------------------------------------------------------------- */

    /** Add Daily Interest
        Description: Runs once per day and takes all the AXN earned as interest and puts it into payout array for the day
    */
    // 179470
    function addDailyInterest() public {
        require(
            block.timestamp >= interestFields.nextAddInterestTimestamp,
            'Staking: Too early to add interest.'
        );
        uint256 todaysSharePayout; // free
        uint256 interest = getTodaysInterest();
        if (statFields.sharesTotalSupply == 0) {
            statFields.sharesTotalSupply = 1e6;
        } // Is this necessary? cost 1000 gas for the if statement, 212832.. Only needed for testing?

        // This if clause is only needed for testing it seems....
        if (interestPerShare.length != 0) {
            todaysSharePayout =
                interestPerShare[interestPerShare.length - 1] +
                ((interest * 1e26) / ((uint256(statFields.sharesTotalSupply) * 1e12)));
        } else {
            todaysSharePayout =
                (interest * 1e26) /
                ((uint256(statFields.sharesTotalSupply) * 1e12));
        }

        interestPerShare.push(todaysSharePayout);
        interestFields.nextAddInterestTimestamp += settings.secondsInDay;
        // // call updateShareRate once a day as sharerate increases based on the daily Payout amount
        updateShareRate(interest);
        emit DailyInterestAdded(
            interest,
            statFields.sharesTotalSupply,
            todaysSharePayout,
            block.timestamp
        );
    }

    /** Get Todays Interest
        Description: Get # of circulating supply and total in stakemanager contract add 8% yearly
     */
    function getTodaysInterest() internal returns (uint256) {
        uint256 amountTokenInDay = IERC20Upgradeable(contracts.token).balanceOf(address(this));
        IERC20Upgradeable(contracts.token).transfer(
            0x000000000000000000000000000000000000dEaD,
            amountTokenInDay
        ); // Send to dead address
        uint256 balanceOfDead =
            IERC20Upgradeable(contracts.token).balanceOf(
                0x000000000000000000000000000000000000dEaD
            );

        uint256 currentTokenTotalSupply = contracts.token.totalSupply() - balanceOfDead;
        uint256 inflation =
            (8 * (currentTokenTotalSupply + (uint256(statFields.totalStakedAmount) * 1e12))) /
                36500;

        return inflation;
    }

    /** Update Share Rate
        Description: function to increase the share rate price this happens on the first stake of every 'axion day' 12:04 utc
        @param _payout {uint} - amount of AXN that was bought back through the regular auction + 8% yearly amount
    */
    function updateShareRate(uint256 _payout) internal {
        uint256 currentTokenTotalSupply = contracts.token.totalSupply(); // 718485214285714285714285714

        uint256 growthFactor =
            (_payout * 1e18) /
                (currentTokenTotalSupply + (uint256(statFields.totalStakedAmount) * 1e12) + 1); //we calculate the total AXN supply as circulating + staked

        if (settings.shareRateScalingFactor == 0) {
            //use a shareRateScalingFactor which can be set in order to tune the speed of shareRate increase
            settings.shareRateScalingFactor = 1e18;
        }

        interestFields.shareRate = (
            ((uint256(interestFields.shareRate) *
                (1e36 + (uint256(settings.shareRateScalingFactor) * growthFactor))) / 1e36)
        )
            .toUint128(); //1e18 used for precision.
    }

    /** Utility ------------------------------------------------------------------ */

    /** Add Total VCA Registered Shares
        Description: Add to the total registered shares

        @param shares {uint256}
     */
    function addTotalVcaRegisteredShares(uint256 shares) external override onlyExternalCaller {
        statFields.totalVcaRegisteredShares += (shares / 1e12).toUint72();
    }

    /* Getters ------------------------------------------------------------------------------------------------*/

    /** Get Stake
        @param id {uint256}

        @return {StakeData}
     */
    function getStake(uint256 id) external view override returns (StakeData1e18 memory) {
        return
            StakeData1e18(
                uint256(stakeData[id].amount) * 1e12,
                uint256(stakeData[id].shares) * 1e12,
                stakeData[id].start,
                stakeData[id].stakingDays,
                stakeData[id].firstInterestDay,
                uint256(stakeData[id].payout) * 1e18,
                stakeData[id].status
            );
    }

    /** Get Stake
        @param id {uint256}

        @return {uint256} - End date in seconds of stake
     */
    function getStakeEnd(uint256 id) external view override returns (uint256) {
        return stakeData[id].start + (settings.secondsInDay * stakeData[id].stakingDays);
    }

    function getStakeShares(uint256 id) external view override returns (uint256) {
        return uint256(stakeData[id].shares) * 1e12;
    }

    /** Get Stake Withdrawn
        @param id {uint256}

        @return {bool} - Stake withdrawn
     */
    function getStakeWithdrawnOrExists(uint256 id) external view override returns (bool) {
        return
            stakeData[id].status == StakeStatus.Withdrawn ||
            stakeData[id].status != StakeStatus.Unknown;
    }

    /** get Total VCA Registered Shares
        Description: This function will return the total registered shares for VCA
        This differs from the total share supply due to the fact of V1 and V2 layer

        @return {uint256} - Total Registered Shares for VCA
     */
    function getTotalVcaRegisteredShares() external view override returns (uint256) {
        return uint256(statFields.totalVcaRegisteredShares) * 1e12;
    }

    function getStatFields() external view returns (StatFields memory) {
        return statFields;
    }

    function getInterestFields() external view returns (InterestFields memory) {
        return interestFields;
    }

    function getSettings() external view returns (Settings memory) {
        return settings;
    }

    function getDaysFromStart() external view returns (uint256) {
        return (block.timestamp - settings.contractStartTimestamp) / settings.secondsInDay;
    }

    /** Initialize ------------------------------------------------------------------------------------------------*/

    /** Upgradeable Initialize Function
        @param _manager {address} - Address for contract manager (Gnosis Wallet) 
        @param _migrator {address} - Address for contract migrator (Deployer Addres)
     */
    function initialize(address _manager, address _migrator) external initializer {
        _setupRole(MANAGER_ROLE, _manager);
        _setupRole(MIGRATOR_ROLE, _migrator);
    }

    function init(
        address _stakeMinter,
        address _stakeBurner,
        address _stakeUpgrader,
        address _token,
        address _ventureCapital,
        address _bpd
    ) public onlyMigrator {
        _setupRole(EXTERNAL_CALLER_ROLE, _stakeMinter);
        _setupRole(EXTERNAL_CALLER_ROLE, _stakeBurner);
        _setupRole(EXTERNAL_CALLER_ROLE, _stakeUpgrader);
        _setupRole(EXTERNAL_CALLER_ROLE, _ventureCapital);

        contracts.token = IToken(_token);
        contracts.ventureCapital = IVentureCapital(_ventureCapital);
        contracts.bpd = IBpd(_bpd);
    }

    function restore(
        uint128 _shareRateScalingFactor,
        uint32 _secondsInDay,
        uint64 _contractStartTimestamp,
        uint32 _bpdDayRange,
        uint128 _shareRate,
        uint128 _nextAddInterestTimestamp
    ) external onlyMigrator {
        settings.shareRateScalingFactor = _shareRateScalingFactor;
        settings.secondsInDay = _secondsInDay;
        settings.contractStartTimestamp = _contractStartTimestamp;
        settings.bpdDayRange = _bpdDayRange;
        interestFields.shareRate = _shareRate;
        interestFields.nextAddInterestTimestamp = _nextAddInterestTimestamp;

        /** Stat fields will be added as we add the stakes back in */
    }

    function restorePayouts(uint256[] calldata payouts, uint256[] calldata shares)
        external
        onlyMigrator
    {
        require(payouts.length < 21, 'MANAGER: Sending too much data');
        require(payouts.length == shares.length, 'MANAGER: Payout.length != shares.length');

        for (uint256 i = 0; i < payouts.length; i++) {
            uint256 sharesTotalSupply = shares[i];

            if (sharesTotalSupply == 0) {
                sharesTotalSupply = 1e18;
            }

            if (interestPerShare.length != 0) {
                interestPerShare.push(
                    interestPerShare[interestPerShare.length - 1] +
                        ((payouts[i] * 1e26) / sharesTotalSupply)
                );
            } else {
                interestPerShare.push((payouts[i] * 1e26) / sharesTotalSupply);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

// Abstracts
import '../abstracts/Migrateable.sol';
import '../abstracts/Manageable.sol';
import '../abstracts/ExternallyCallable.sol';
// Interfaces
import '../interfaces/IBpd.sol';
import '../interfaces/IToken.sol';
import '../interfaces/IVentureCapital.sol';

import '../enums/StakeStatus.sol';

contract StakeBase is Migrateable, Manageable, ExternallyCallable {
    struct StakeData {
        uint64 amount; //1e-6
        uint64 shares; //1e-6
        uint40 start;
        uint16 stakingDays;
        uint24 firstInterestDay;
        uint40 payout; // 0dps
        StakeStatus status;
    }

    struct NewStake {
        uint256 id; // Id of stake, should either be lastStakeId for new, or <= sessionId for set existings
        uint256 amount; // # of initial axion
        uint256 shares; // # of shares owned for stake
        uint256 start; // Start date in seconds
        uint256 stakingDays; // Number of staking days (start - end) / secondsInDay
        uint256 firstInterestDay; // first day of divs
    }

    /*----------------------------------------------------------------------------------------------------------------------------------------------*/

    event StakeCreated(
        address indexed account,
        uint128 indexed sessionId,
        uint80 amount,
        uint80 shares,
        uint40 start,
        uint16 stakingDays
    );

    event ExistingStakeCreated(
        uint256 indexed sessionId,
        uint80 amount,
        uint80 shares,
        uint40 start,
        uint16 stakingDays
    );

    event StakeDeleted(
        address indexed account,
        uint128 indexed sessionId,
        uint80 amount,
        uint80 shares,
        uint40 start,
        uint16 stakingDays
    );

    event DailyInterestAdded(
        uint256 indexed value,
        uint256 indexed sharesTotalSupply,
        uint256 sharePayout,
        uint256 indexed time
    );

    event StakeUpgraded(
        address indexed account,
        uint256 indexed sessionId,
        uint256 amount,
        uint256 newAmount,
        uint256 shares,
        uint256 newShares,
        uint256 start,
        uint256 end
    );

    /*----------------------------------------------------------------------------------------------------------------------------------------------*/

    struct Settings {
        //256 bits
        uint128 shareRateScalingFactor; //scaling factor, default 1 to be used on the shareRate calculation
        uint32 secondsInDay; // 24h * 60 * 60
        uint64 contractStartTimestamp; //time the contract started
        uint32 bpdDayRange; //350 days, time of the first BPD
    }

    struct InterestFields {
        //256 bits
        uint128 shareRate; //shareRate used to calculate the number of shares
        uint128 nextAddInterestTimestamp; //used to calculate when the daily makePayout() should run
    }

    struct StatFields {
        //256 bits
        uint72 totalStakedAmount; // 1-e6 total amount of staked AXN
        uint72 sharesTotalSupply; // 1-e6 total shares supply
        uint72 totalVcaRegisteredShares; // 1-e6 total number of shares from accounts that registered for the VCA
        uint40 lastStakeId; //the ID of the last stake
    }

    struct Contracts {
        IToken token;
        IVentureCapital ventureCapital;
        IBpd bpd;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCastUpgradeable {
    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

pragma solidity >=0.8.0;

import '../enums/StakeStatus.sol';

struct StakeData1e18 {
    uint256 amount;
    uint256 shares;
    uint256 start;
    uint256 stakingDays;
    uint256 firstInterestDay;
    uint256 payout;
    StakeStatus status;
}

struct StakeUpgrade {
    uint256 id; // Id of stake
    address staker;
    uint256 firstInterestDay; // first day of divs
    uint256 shares; // # of shares owned for stake
    uint256 amount; // # amount of initial axn
    uint256 start; // Start Date in sconds
    uint256 stakingDays; // End date in seconds
}

interface IStakeManager {
    function recoverStake(
        address staker,
        uint256 start,
        uint256 shares,
        uint256 amount,
        uint256 stakingDays,
        uint256 firstPayout
    ) external returns (uint256);

    function createStake(
        address staker,
        uint256 amount,
        uint256 stakingDays
    ) external returns (uint256);

    function createManagerStake(
        address staker,
        uint256 amount,
        uint256 shares,
        uint256 stakingDays,
        uint256 start
    ) external returns (uint256);

    function upgradeExistingStake(uint256 id, address staker) external;

    function unsetStake(
        address staker,
        uint256 id,
        uint256 payout
    ) external;

    function getStake(uint256 id) external returns (StakeData1e18 memory);

    function getStakeEnd(uint256 id) external view returns (uint256);

    function getStakeShares(uint256 id) external view returns (uint256);

    function getStakeInterest(
        uint256 firstInterestDay,
        uint256 stakingDays,
        uint256 shares
    ) external view returns (uint256);

    function getStakeAndInterestById(uint256 stakeId)
        external
        view
        returns (
            uint256 start,
            uint256 stakingDays,
            uint256 amount,
            uint256 shares,
            uint256 interest
        );

    function getStakeWithdrawnOrExists(uint256 id) external view returns (bool);

    function getTotalVcaRegisteredShares() external view returns (uint256);

    function addTotalVcaRegisteredShares(uint256 shares) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

library AxionSafeCast {
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value < 2**24, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value < 2**40, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value < 2**48, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value < 2**72, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value < 2**88, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

abstract contract Migrateable is AccessControlUpgradeable {
    bytes32 public constant MIGRATOR_ROLE = keccak256("MIGRATOR_ROLE");

    modifier onlyMigrator() {
        require(
            hasRole(MIGRATOR_ROLE, msg.sender),
            "Caller is not a migrator"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

abstract contract Manageable is AccessControlUpgradeable {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    modifier onlyManager() {
        require(
            hasRole(MANAGER_ROLE, msg.sender),
            "Caller is not a manager"
        );
        _;
    }

    /** Roles management - only for multi sig address */
    function setupRole(bytes32 role, address account) external onlyManager {
        _setupRole(role, account);
    }

    function isManager(address account) external view returns (bool) {
        return hasRole(MANAGER_ROLE, account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

abstract contract ExternallyCallable is AccessControlUpgradeable {
    bytes32 public constant EXTERNAL_CALLER_ROLE = keccak256('EXTERNAL_CALLER_ROLE');

    modifier onlyExternalCaller() {
        require(
            hasRole(EXTERNAL_CALLER_ROLE, msg.sender),
            'Caller is not allowed'
        );
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IBpd {
    function addBpdShares(
        uint256 shares,
        uint256 start,
        uint256 stakingDays
    ) external;

    function addBpdMaxShares(
        uint256 oldShares,
        uint256 oldStart,
        uint256 oldEnd,
        uint256 newShares,
        uint256 newStart,
        uint256 newEnd
    ) external;

    function getBpdAmount(
        uint256 shares,
        uint256 start,
        uint256 end
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';

interface IToken is IERC20Upgradeable {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IVentureCapital {
    function addTotalSharesOfAndRebalance(address staker, uint256 shares) external;

    function subTotalSharesOfAndRebalance(address staker, uint256 shares) external;

    function withdrawDivTokensFromToExternal(address from, address payable to) external;

    function transferSharesAndRebalance(
        address from,
        address to,
        uint256 shares
    ) external;

    function updateTokenPricePerShare(address tokenAddress, uint256 amountBought) external payable;

    function addDivToken(address tokenAddress) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

enum StakeStatus {Unknown, Withdrawn, Active}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overloaded;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    uint256[45] private __gap;
}


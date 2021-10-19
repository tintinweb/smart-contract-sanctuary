// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;
// Base
import './StakeBase.sol';
// OpenZeppelin
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
    mapping(uint256 => string) public name;

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
        shares = (shares / 1e12) * 1e12; // 1e6 decimals
        amount = (amount / 1e12) * 1e12;

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
    ) external override onlyExternalCaller whenNotPaused returns (uint256) {
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

    function splitStake(uint256 stakeId, uint256 percentage)
        external
        override
        onlyExternalCaller
        whenNotPaused
        returns (uint256)
    {
        require(stakeData[stakeId].status == StakeStatus.Active, 'MANAGER: Stake not active');

        //** Get new stake id */
        statFields.lastStakeId++;

        //** Get the split amount */
        uint64 splitAmount = ((stakeData[stakeId].amount * uint64(percentage)) / uint64(100));
        uint64 splitShares = ((stakeData[stakeId].shares * uint64(percentage)) / uint64(100));

        //** subtract the split amount from current stake */
        stakeData[stakeId].amount -= splitAmount;
        stakeData[stakeId].shares -= splitShares;
        uint256 min = 100000 * 1e6; // 100k at 1e6
        require(stakeData[stakeId].amount > min, 'SplitStake: Final amounts to small.');
        require(splitAmount > min, 'SplitStake: Final amounts to small.');

        //** create new stake */
        createStakeInternal(
            NewStake({
                id: statFields.lastStakeId,
                amount: uint256(splitAmount) * 1e12,
                shares: uint256(splitShares) * 1e12,
                start: stakeData[stakeId].start,
                stakingDays: stakeData[stakeId].stakingDays,
                firstInterestDay: stakeData[stakeId].firstInterestDay
            })
        );

        return statFields.lastStakeId;
    }

    /** Upgrade Existing Stake
        Description: Upgrade existing stake layer 3 with max shares (5555 day stake)
        @param id {uint256} - ID should be less then LastSessionIdV3

        Modifier: OnlyExternalCaller - Can only be called by StakeUpgrader
     */
    function upgradeExistingStake(uint256 id, address staker)
        external
        override
        onlyExternalCaller
        whenNotPaused
    {
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
        require(stake.amount > 0, 'Stake must be greater then 0');
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
    ) external override onlyExternalCaller whenNotPaused {
        unsetStakeInternal(
            staker,
            id,
            uint256(stakeData[id].shares) * 1e12,
            uint256(stakeData[id].amount) * 1e12,
            payout
        );
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
            stakeData[id].stakingDays,
            block.timestamp
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
                interestPerShare.length - 1 < lastInterestDay - 1
                    ? interestPerShare.length - 1
                    : lastInterestDay - 1
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
            (interestFields.APR *
                (currentTokenTotalSupply + (uint256(statFields.totalStakedAmount) * 1e12))) / 36500;

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

    /** Set stake name
        @param newName {string}
        @param stakeId {uint256}
     */
    function setStakeName(string memory newName, uint256 stakeId)
        external
        override
        onlyExternalCaller
    {
        name[stakeId] = newName;
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
                stakeData[id].status,
                name[id]
            );
    }

    function getStakeUri(uint256 id) external view override returns (StakeUri memory) {
        return
            StakeUri(
                name[id],
                stakeData[id].amount,
                stakeData[id].shares,
                stakeData[id].stakingDays,
                stakeData[id].payout,
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

    function getAPR() external view override returns (uint256) {
        return interestFields.APR;
    }

    function getSettings() external view returns (Settings memory) {
        return settings;
    }

    function getDaysFromStart() external view returns (uint256) {
        return (block.timestamp - settings.contractStartTimestamp) / settings.secondsInDay;
    }

    /** Setters ------------------------------------------------------------------------------------------------*/
    function setAPR(uint256 _apr) external onlyManager {
        interestFields.APR = _apr;
    }

    /** Initialize ------------------------------------------------------------------------------------------------*/

    /** Upgradeable Initialize Function
        @param _manager {address} - Address for contract manager (Gnosis Wallet) 
     */
    function initialize(address _manager) external initializer {
        _setupRole(MANAGER_ROLE, _manager);
    }

    function init(
        address _stakeUtilities,
        address _stakeMinter,
        address _stakeBurner,
        address _stakeUpgrader,
        address _token,
        address _ventureCapital,
        address _bpd
    ) external onlyManager {
        _setupRole(EXTERNAL_CALLER_ROLE, _stakeMinter);
        _setupRole(EXTERNAL_CALLER_ROLE, _stakeBurner);
        _setupRole(EXTERNAL_CALLER_ROLE, _stakeUpgrader);
        _setupRole(EXTERNAL_CALLER_ROLE, _ventureCapital);
        _setupRole(EXTERNAL_CALLER_ROLE, _stakeUtilities);

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
    ) external onlyManager {
        settings.shareRateScalingFactor = _shareRateScalingFactor;
        settings.secondsInDay = _secondsInDay;
        settings.contractStartTimestamp = _contractStartTimestamp;
        settings.bpdDayRange = _bpdDayRange;
        interestFields.shareRate = _shareRate;
        interestFields.nextAddInterestTimestamp = _nextAddInterestTimestamp;
        interestFields.APR = 8;
        /** Stat fields will be added as we add the stakes back in */
    }

    function restorePayouts(uint256[] calldata payouts, uint256[] calldata shares)
        external
        onlyManager
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
import '../abstracts/Pausable.sol';
import '../abstracts/ExternallyCallable.sol';
// Interfaces
import '../interfaces/IBpd.sol';
import '../interfaces/IToken.sol';
import '../interfaces/IVentureCapital.sol';

import '../enums/StakeStatus.sol';

contract StakeBase is Pausable, ExternallyCallable {
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

    event StakeDeleted(
        address indexed account,
        uint128 indexed sessionId,
        uint80 amount,
        uint80 shares,
        uint40 start,
        uint16 stakingDays,
        uint256 end
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

    event DailyInterestAdded(
        uint256 indexed value,
        uint256 indexed sharesTotalSupply,
        uint256 sharePayout,
        uint256 indexed time
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
        uint256 APR;
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
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

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
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
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
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
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
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
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
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
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
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
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
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
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
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
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
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
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
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
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
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
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
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
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
    string name;
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

struct StakeUri {
    string name;
    uint64 amount; //1e-6
    uint64 shares; //1e-6
    uint16 stakingDays;
    uint40 payout; // 0dps
    StakeStatus status;
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

    function getAPR() external view returns (uint256);

    function createStake(
        address staker,
        uint256 amount,
        uint256 stakingDays
    ) external returns (uint256);

    function upgradeExistingStake(uint256 id, address staker) external;

    function setStakeName(string memory newName, uint256 stakeId) external;

    function unsetStake(
        address staker,
        uint256 id,
        uint256 payout
    ) external;

    function getStake(uint256 id) external returns (StakeData1e18 memory);

    function getStakeEnd(uint256 id) external view returns (uint256);

    function getStakeShares(uint256 id) external view returns (uint256);

    function getStakeUri(uint256 id) external view returns (StakeUri memory);

    function getStakeInterest(
        uint256 firstInterestDay,
        uint256 stakingDays,
        uint256 shares
    ) external view returns (uint256);

    function splitStake(uint256 stakeId, uint256 percentage) external returns (uint256);

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

import './Manageable.sol';

abstract contract Pausable is Manageable {
    event SetPaused(bool paused);

    modifier whenNotPaused() {
        require(paused == false || hasRole(MANAGER_ROLE, msg.sender), 'Function is paused');
        _;
    }

    bool internal paused;

    function setPaused(bool _paused) external {
        require(hasRole(MANAGER_ROLE, msg.sender), 'Caller must be manager');

        paused = _paused;
        emit SetPaused(_paused);
    }

    function getPaused() external view returns (bool) {
        return paused;
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

    function withdrawDivTokensToAccelerator(address from, address tokenAddress, address payable acceleratorAddress) external;

    function transferSharesAndRebalance(
        address from,
        address to,
        uint256 shares
    ) external;

    function updateTokenPricePerShare(address tokenAddress, uint256 amountBought) external payable;

    function addDivToken(address tokenAddress) external;

    function getTokenInterestEarned(address accountAddress, address tokenAddress) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

enum StakeStatus {Unknown, Withdrawn, Active}

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

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
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

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
     * bearer except when using {AccessControl-_setupRole}.
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
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

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
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

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
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
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

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
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
import "./extensions/IERC20MetadataUpgradeable.sol";
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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
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
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}
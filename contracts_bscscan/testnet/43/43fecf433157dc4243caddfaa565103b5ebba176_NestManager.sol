// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./INestManager.sol";
import "./IStabilityPool.sol";
import "./ICollSurplusPool.sol";
import "./IYUSDToken.sol";
import "./ISortedNests.sol";
import "./FlareLoansStableBase.sol";
import "./Ownable.sol";
import "./Address.sol";

contract NestManager is FlareLoansStableBase, Ownable, INestManager {
    string constant public NAME = "NestManager";

    // --- Connected contract declarations ---

    address public borrowerOperationsAddress;
    IStabilityPool public override stabilityPool;
    address gasPoolAddress;
    ICollSurplusPool collSurplusPool;
    IYUSDToken public override yusdToken;
    IDFLRStaking public override dflrStaking;

    // A doubly linked list of Nests, sorted by their sorted by their collateral ratios
    ISortedNests public sortedNests;

    // --- Data structures ---
    /*
     * Half-life of 12h. 12h = 720 min
     * (1/2) = d^720 => d = (1/2)^(1/720)
     */
    uint constant public MINUTE_DECAY_FACTOR = 999037758833783000;
    uint constant public REDEMPTION_FEE_FLOOR = DECIMAL_PRECISION / 1000 * 5; // 0.5%
    uint constant public MAX_BORROWING_FEE = DECIMAL_PRECISION / 100 * 5; // 5%

    // During bootsrap period redemptions are not allowed
    uint constant public BOOTSTRAP_PERIOD = 14 minutes;

    /*
    * BETA: 18 digit decimal. Parameter by which to divide the redeemed fraction, in order to calc the new base rate from a redemption.
    * Corresponds to (1 / ALPHA) in the white paper.
    */
    uint constant public BETA = 2;

    uint public baseRate;

    // The timestamp of the latest fee operation (redemption or new YUSD issuance)
    uint public lastFeeOperationTime;

    enum Status {
        nonExistent,
        active,
        closedByOwner,
        closedByLiquidation,
        closedByRedemption
    }

    // Store the necessary data for a nest
    struct Nest {
        uint debt;
        uint coll;
        uint stake;
        Status status;
        uint128 arrayIndex;
    }

    mapping (address => Nest) public Nests;

    uint public totalStakes;

    // Snapshot of the value of totalStakes, taken immediately after the latest liquidation
    uint public totalStakesSnapshot;

    // Snapshot of the total collateral across the ActivePool and DefaultPool, immediately after the latest liquidation.
    uint public totalCollateralSnapshot;

    /*
    * L_FLR and L_YUSDDebt track the sums of accumulated liquidation rewards per unit staked. During its lifetime, each stake earns:
    *
    * An FLR gain of ( stake * [L_FLR - L_FLR(0)] )
    * A YUSDDebt increase  of ( stake * [L_YUSDDebt - L_YUSDDebt(0)] )
    *
    * Where L_FLR(0) and L_YUSDDebt(0) are snapshots of L_FLR and L_YUSDDebt for the active Nest taken at the instant the stake was made
    */
    uint public L_FLR;
    uint public L_YUSDDebt;

    // Map addresses with active nests to their RewardSnapshot
    mapping (address => RewardSnapshot) public rewardSnapshots;

    // Object containing the FLR and YUSD snapshots for a given active nest
    struct RewardSnapshot { uint FLR; uint YUSDDebt;}

    // Array of all active nest addresses - used to to compute an approximate hint off-chain, for the sorted list insertion
    address[] public NestOwners;

    // Error trackers for the nest redistribution calculation
    uint public lastFLRError_Redistribution;
    uint public lastYUSDDebtError_Redistribution;

    /*
    * --- Variable container structs for liquidations ---
    *
    * These structs are used to hold, return and assign variables inside the liquidation functions,
    * in order to avoid the error: "CompilerError: Stack too deep".
    **/

    struct LocalVariables_OuterLiquidationFunction {
        uint price;
        uint YUSDInStabPool;
        bool recoveryModeAtStart;
        uint liquidatedDebt;
        uint liquidatedColl;
    }

    struct LocalVariables_InnerSingleLiquidateFunction {
        uint collToLiquidate;
        uint pendingDebtReward;
        uint pendingCollReward;
    }

    struct LocalVariables_LiquidationSequence {
        uint remainingYUSDInStabPool;
        uint i;
        uint ICR;
        address user;
        bool backToNormalMode;
        uint entireSystemDebt;
        uint entireSystemColl;
    }

    struct LiquidationValues {
        uint entireNestDebt;
        uint entireNestColl;
        uint collGasCompensation;
        uint YUSDGasCompensation;
        uint debtToOffset;
        uint collToSendToSP;
        uint debtToRedistribute;
        uint collToRedistribute;
        uint collSurplus;
    }

    struct LiquidationTotals {
        uint totalCollInSequence;
        uint totalDebtInSequence;
        uint totalCollGasCompensation;
        uint totalYUSDGasCompensation;
        uint totalDebtToOffset;
        uint totalCollToSendToSP;
        uint totalDebtToRedistribute;
        uint totalCollToRedistribute;
        uint totalCollSurplus;
    }

    struct ContractsCache {
        IActivePool activePool;
        IDefaultPool defaultPool;
        IYUSDToken yusdToken;
        ISortedNests sortedNests;
        ICollSurplusPool collSurplusPool;
        address gasPoolAddress;
    }
    // --- Variable container structs for redemptions ---

    struct RedemptionTotals {
        uint remainingYUSD;
        uint totalYUSDToRedeem;
        uint totalFLRDrawn;
        uint FLRFee;
        uint FLRToSendToRedeemer;
        uint decayedBaseRate;
        uint price;
        uint totalYUSDSupplyAtStart;
    }

    struct SingleRedemptionValues {
        uint YUSDLot;
        uint FLRLot;
        bool cancelledPartial;
    }

    // --- Events ---

    event NestUpdated(address indexed _borrower, uint _debt, uint _coll, uint _stake, NestManagerOperation _operation);
    event NestLiquidated(address indexed _borrower, uint _debt, uint _coll, NestManagerOperation _operation);

    enum NestManagerOperation {
        applyPendingRewards,
        liquidateInNormalMode,
        liquidateInRecoveryMode,
        redeemCollateral
    }

    constructor(address owner, address loansSettings) Ownable(owner) FlareLoansStableBase(loansSettings) { }

    // --- Dependency setter ---

    function setAddresses(
        address _borrowerOperationsAddress,
        address _activePoolAddress,
        address _defaultPoolAddress,
        address _stabilityPoolAddress,
        address _gasPoolAddress,
        address _collSurplusPoolAddress,
        address _priceFeedAddress,
        address _yusdTokenAddress,
        address _sortedNestsAddress,
        address _dflr
    )
        external
        override
        onlyOwner
    {
        Address.checkContract(_borrowerOperationsAddress);
        Address.checkContract(_activePoolAddress);
        Address.checkContract(_defaultPoolAddress);
        Address.checkContract(_stabilityPoolAddress);
        Address.checkContract(_gasPoolAddress);
        Address.checkContract(_collSurplusPoolAddress);
        Address.checkContract(_priceFeedAddress);
        Address.checkContract(_yusdTokenAddress);
        Address.checkContract(_sortedNestsAddress);
        Address.checkContract(_dflr);
        
        borrowerOperationsAddress = _borrowerOperationsAddress;
        activePool = IActivePool(_activePoolAddress);
        defaultPool = IDefaultPool(_defaultPoolAddress);
        stabilityPool = IStabilityPool(_stabilityPoolAddress);
        gasPoolAddress = _gasPoolAddress;
        collSurplusPool = ICollSurplusPool(_collSurplusPoolAddress);
        priceFeed = IPriceFeed(_priceFeedAddress);
        yusdToken = IYUSDToken(_yusdTokenAddress);
        sortedNests = ISortedNests(_sortedNestsAddress);
        dflrStaking = IDFLRStaking(_dflr);

        emit BorrowerOperationsAddressChanged(_borrowerOperationsAddress);
        emit ActivePoolAddressChanged(_activePoolAddress);
        emit DefaultPoolAddressChanged(_defaultPoolAddress);
        emit StabilityPoolAddressChanged(_stabilityPoolAddress);
        emit GasPoolAddressChanged(_gasPoolAddress);
        emit CollSurplusPoolAddressChanged(_collSurplusPoolAddress);
        emit PriceFeedAddressChanged(_priceFeedAddress);
        emit YUSDTokenAddressChanged(_yusdTokenAddress);
        emit SortedNestsAddressChanged(_sortedNestsAddress);
        emit DFLRStakingAddressChanged(_dflr);
    }

    // --- Getters ---

    function getNestOwnersCount() external view override returns (uint) {
        return NestOwners.length;
    }

    function getNestFromNestOwnersArray(uint _index) external view override returns (address) {
        return NestOwners[_index];
    }

    // --- Nest Liquidation functions ---

    // Single liquidation function. Closes the nest if its ICR is lower than the minimum collateral ratio.
    function liquidate(address _borrower) external override {
        _requireNestIsActive(_borrower);

        address[] memory borrowers = new address[](1);
        borrowers[0] = _borrower;
        batchLiquidateNests(borrowers);
    }

    // --- Inner single liquidation functions ---

    // Liquidate one nest, in Normal Mode.
    function _liquidateNormalMode(
        IActivePool _activePool,
        IDefaultPool _defaultPool,
        address _borrower,
        uint _YUSDInStabPool
    )
        internal
        returns (LiquidationValues memory singleLiquidation)
    {
        LocalVariables_InnerSingleLiquidateFunction memory vars;

        (singleLiquidation.entireNestDebt,
        singleLiquidation.entireNestColl,
        vars.pendingDebtReward,
        vars.pendingCollReward) = getEntireDebtAndColl(_borrower);

        _movePendingNestRewardsToActivePool(_activePool, _defaultPool, vars.pendingDebtReward, vars.pendingCollReward);
        _removeStake(_borrower);

        singleLiquidation.collGasCompensation = _getCollGasCompensation(singleLiquidation.entireNestColl);
        singleLiquidation.YUSDGasCompensation = YUSD_GAS_COMPENSATION;
        uint collToLiquidate = singleLiquidation.entireNestColl - singleLiquidation.collGasCompensation;

        (singleLiquidation.debtToOffset,
        singleLiquidation.collToSendToSP,
        singleLiquidation.debtToRedistribute,
        singleLiquidation.collToRedistribute) = _getOffsetAndRedistributionVals(singleLiquidation.entireNestDebt, collToLiquidate, _YUSDInStabPool);

        _closeNest(_borrower, Status.closedByLiquidation);
        emit NestLiquidated(_borrower, singleLiquidation.entireNestDebt, singleLiquidation.entireNestColl, NestManagerOperation.liquidateInNormalMode);
        emit NestUpdated(_borrower, 0, 0, 0, NestManagerOperation.liquidateInNormalMode);
        return singleLiquidation;
    }

    // Liquidate one nest, in Recovery Mode.
    function _liquidateRecoveryMode(
        IActivePool _activePool,
        IDefaultPool _defaultPool,
        address _borrower,
        uint _ICR,
        uint _YUSDInStabPool,
        uint _TCR,
        uint _price
    )
        internal
        returns (LiquidationValues memory singleLiquidation)
    {
        LocalVariables_InnerSingleLiquidateFunction memory vars;
        if (NestOwners.length <= 1) {return singleLiquidation;} // don't liquidate if last nest
        (singleLiquidation.entireNestDebt,
        singleLiquidation.entireNestColl,
        vars.pendingDebtReward,
        vars.pendingCollReward) = getEntireDebtAndColl(_borrower);

        singleLiquidation.collGasCompensation = _getCollGasCompensation(singleLiquidation.entireNestColl);
        singleLiquidation.YUSDGasCompensation = YUSD_GAS_COMPENSATION;
        vars.collToLiquidate = singleLiquidation.entireNestColl - singleLiquidation.collGasCompensation;

        uint MCR = loansStableSettings.MCR();
        // If ICR <= 100%, purely redistribute the Nest across all active Nests
        if (_ICR <= _100pct) {
            _movePendingNestRewardsToActivePool(_activePool, _defaultPool, vars.pendingDebtReward, vars.pendingCollReward);
            _removeStake(_borrower);
           
            singleLiquidation.debtToOffset = 0;
            singleLiquidation.collToSendToSP = 0;
            singleLiquidation.debtToRedistribute = singleLiquidation.entireNestDebt;
            singleLiquidation.collToRedistribute = vars.collToLiquidate;

            _closeNest(_borrower, Status.closedByLiquidation);
            emit NestLiquidated(_borrower, singleLiquidation.entireNestDebt, singleLiquidation.entireNestColl, NestManagerOperation.liquidateInRecoveryMode);
            emit NestUpdated(_borrower, 0, 0, 0, NestManagerOperation.liquidateInRecoveryMode);
            
        // If 100% < ICR < MCR, offset as much as possible, and redistribute the remainder
        } else if ((_ICR > _100pct) && (_ICR < MCR)) {
             _movePendingNestRewardsToActivePool(_activePool, _defaultPool, vars.pendingDebtReward, vars.pendingCollReward);
            _removeStake(_borrower);

            (singleLiquidation.debtToOffset,
            singleLiquidation.collToSendToSP,
            singleLiquidation.debtToRedistribute,
            singleLiquidation.collToRedistribute) = _getOffsetAndRedistributionVals(singleLiquidation.entireNestDebt, vars.collToLiquidate, _YUSDInStabPool);

            _closeNest(_borrower, Status.closedByLiquidation);
            emit NestLiquidated(_borrower, singleLiquidation.entireNestDebt, singleLiquidation.entireNestColl, NestManagerOperation.liquidateInRecoveryMode);
            emit NestUpdated(_borrower, 0, 0, 0, NestManagerOperation.liquidateInRecoveryMode);
        /*
        * If 110% <= ICR < current TCR (accounting for the preceding liquidations in the current sequence)
        * and there is YUSD in the Stability Pool, only offset, with no redistribution,
        * but at a capped rate of 1.1 and only if the whole debt can be liquidated.
        * The remainder due to the capped rate will be claimable as collateral surplus.
        */
        } else if ((_ICR >= MCR) && (_ICR < _TCR) && (singleLiquidation.entireNestDebt <= _YUSDInStabPool)) {
            _movePendingNestRewardsToActivePool(_activePool, _defaultPool, vars.pendingDebtReward, vars.pendingCollReward);
            assert(_YUSDInStabPool != 0);

            _removeStake(_borrower);
            singleLiquidation = _getCappedOffsetVals(singleLiquidation.entireNestDebt, singleLiquidation.entireNestColl, _price);

            _closeNest(_borrower, Status.closedByLiquidation);
            if (singleLiquidation.collSurplus > 0) {
                collSurplusPool.accountSurplus(_borrower, singleLiquidation.collSurplus);
            }

            emit NestLiquidated(_borrower, singleLiquidation.entireNestDebt, singleLiquidation.collToSendToSP, NestManagerOperation.liquidateInRecoveryMode);
            emit NestUpdated(_borrower, 0, 0, 0, NestManagerOperation.liquidateInRecoveryMode);

        } else { // if (_ICR >= MCR && ( _ICR >= _TCR || singleLiquidation.entireNestDebt > _YUSDInStabPool))
            LiquidationValues memory zeroVals;
            return zeroVals;
        }

        return singleLiquidation;
    }

    /* In a full liquidation, returns the values for a nest's coll and debt to be offset, and coll and debt to be
    * redistributed to active nests.
    */
    function _getOffsetAndRedistributionVals
    (
        uint _debt,
        uint _coll,
        uint _YUSDInStabPool
    )
        internal
        pure
        returns (uint debtToOffset, uint collToSendToSP, uint debtToRedistribute, uint collToRedistribute)
    {
        if (_YUSDInStabPool > 0) {
        /*
        * Offset as much debt & collateral as possible against the Stability Pool, and redistribute the remainder
        * between all active nests.
        *
        *  If the nest's debt is larger than the deposited YUSD in the Stability Pool:
        *
        *  - Offset an amount of the nest's debt equal to the YUSD in the Stability Pool
        *  - Send a fraction of the nest's collateral to the Stability Pool, equal to the fraction of its offset debt
        *
        */
            debtToOffset = FlareLoansStableMath._min(_debt, _YUSDInStabPool);
            collToSendToSP = _coll * debtToOffset / _debt;
            debtToRedistribute = _debt - debtToOffset;
            collToRedistribute = _coll - collToSendToSP;
        } else {
            debtToOffset = 0;
            collToSendToSP = 0;
            debtToRedistribute = _debt;
            collToRedistribute = _coll;
        }
    }

    /*
    *  Get its offset coll/debt and FLR gas comp, and close the nest.
    */
    function _getCappedOffsetVals
    (
        uint _entireNestDebt,
        uint _entireNestColl,
        uint _price
    )
        internal
        view
        returns (LiquidationValues memory singleLiquidation)
    {
        singleLiquidation.entireNestDebt = _entireNestDebt;
        singleLiquidation.entireNestColl = _entireNestColl;
        uint collToOffset = _entireNestDebt * loansStableSettings.MCR() / _price;

        singleLiquidation.collGasCompensation = _getCollGasCompensation(collToOffset);
        singleLiquidation.YUSDGasCompensation = YUSD_GAS_COMPENSATION;

        singleLiquidation.debtToOffset = _entireNestDebt;
        singleLiquidation.collToSendToSP = collToOffset - singleLiquidation.collGasCompensation;
        singleLiquidation.collSurplus = _entireNestColl - collToOffset;
        singleLiquidation.debtToRedistribute = 0;
        singleLiquidation.collToRedistribute = 0;
    }

    /*
    * Liquidate a sequence of nests. Closes a maximum number of n under-collateralized Nests,
    * starting from the one with the lowest collateral ratio in the system, and moving upwards
    */
    function liquidateNests(uint _n) external override {
        ContractsCache memory contractsCache = ContractsCache(
            activePool,
            defaultPool,
            IYUSDToken(address(0)),
            sortedNests,
            ICollSurplusPool(address(0)),
            address(0)
        );
        IStabilityPool stabilityPoolCached = stabilityPool;

        LocalVariables_OuterLiquidationFunction memory vars;

        LiquidationTotals memory totals;

        vars.price = priceFeed.fetchPrice();
        vars.YUSDInStabPool = stabilityPoolCached.getTotalYUSDDeposits();
        vars.recoveryModeAtStart = _checkRecoveryMode(vars.price);

        // Perform the appropriate liquidation sequence - tally the values, and obtain their totals
        if (vars.recoveryModeAtStart) {
            totals = _getTotalsFromLiquidateNestsSequence_RecoveryMode(contractsCache, vars.price, vars.YUSDInStabPool, _n);
        } else { // if !vars.recoveryModeAtStart
            totals = _getTotalsFromLiquidateNestsSequence_NormalMode(contractsCache.activePool, contractsCache.defaultPool, vars.price, vars.YUSDInStabPool, _n);
        }

        require(totals.totalDebtInSequence > 0, "NestManager: nothing to liquidate");

        // Move liquidated FLR and YUSD to the appropriate pools
        stabilityPoolCached.offset(totals.totalDebtToOffset, totals.totalCollToSendToSP);
        _redistributeDebtAndColl(contractsCache.activePool, contractsCache.defaultPool, totals.totalDebtToRedistribute, totals.totalCollToRedistribute);
        if (totals.totalCollSurplus > 0) {
            contractsCache.activePool.sendFLR(address(collSurplusPool), totals.totalCollSurplus);
        }

        // Update system snapshots
        _updateSystemSnapshots_excludeCollRemainder(contractsCache.activePool, totals.totalCollGasCompensation);

        vars.liquidatedDebt = totals.totalDebtInSequence;
        vars.liquidatedColl = totals.totalCollInSequence - totals.totalCollGasCompensation - totals.totalCollSurplus;
        emit Liquidation(vars.liquidatedDebt, vars.liquidatedColl, totals.totalCollGasCompensation, totals.totalYUSDGasCompensation);

        // Send gas compensation to caller
        _sendGasCompensation(contractsCache.activePool, msg.sender, totals.totalYUSDGasCompensation, totals.totalCollGasCompensation);
    }

    /*
    * This function is used when the liquidateNests sequence starts during Recovery Mode. However, it
    * handle the case where the system *leaves* Recovery Mode, part way through the liquidation sequence
    */
    function _getTotalsFromLiquidateNestsSequence_RecoveryMode
    (
        ContractsCache memory _contractsCache,
        uint _price,
        uint _YUSDInStabPool,
        uint _n
    )
        internal
        returns(LiquidationTotals memory totals)
    {
        LocalVariables_LiquidationSequence memory vars;
        LiquidationValues memory singleLiquidation;

        vars.remainingYUSDInStabPool = _YUSDInStabPool;
        vars.backToNormalMode = false;
        vars.entireSystemDebt = getEntireSystemDebt();
        vars.entireSystemColl = getEntireSystemColl();

        vars.user = _contractsCache.sortedNests.getLast();
        address firstUser = _contractsCache.sortedNests.getFirst();
        for (vars.i = 0; vars.i < _n && vars.user != firstUser; vars.i++) {
            // we need to cache it, because current user is likely going to be deleted
            address nextUser = _contractsCache.sortedNests.getPrev(vars.user);

            vars.ICR = getCurrentICR(vars.user, _price);

            if (!vars.backToNormalMode) {
                // Break the loop if ICR is greater than MCR and Stability Pool is empty
                if (vars.ICR >= loansStableSettings.MCR() && vars.remainingYUSDInStabPool == 0) { break; }

                uint TCR = FlareLoansStableMath._computeCR(vars.entireSystemColl, vars.entireSystemDebt, _price);

                singleLiquidation = _liquidateRecoveryMode(_contractsCache.activePool, _contractsCache.defaultPool, vars.user, vars.ICR, vars.remainingYUSDInStabPool, TCR, _price);

                // Update aggregate trackers
                vars.remainingYUSDInStabPool = vars.remainingYUSDInStabPool - singleLiquidation.debtToOffset;
                vars.entireSystemDebt -= singleLiquidation.debtToOffset;
                vars.entireSystemColl = vars.entireSystemColl - singleLiquidation.collToSendToSP - singleLiquidation.collSurplus;

                // Add liquidation values to their respective running totals
                totals = _addLiquidationValuesToTotals(totals, singleLiquidation);

                vars.backToNormalMode = !_checkPotentialRecoveryMode(vars.entireSystemColl, vars.entireSystemDebt, _price);
            }
            else if (vars.backToNormalMode && vars.ICR < loansStableSettings.MCR()) {
                singleLiquidation = _liquidateNormalMode(_contractsCache.activePool, _contractsCache.defaultPool, vars.user, vars.remainingYUSDInStabPool);

                vars.remainingYUSDInStabPool -= singleLiquidation.debtToOffset;

                // Add liquidation values to their respective running totals
                totals = _addLiquidationValuesToTotals(totals, singleLiquidation);

            }  else break;  // break if the loop reaches a Nest with ICR >= MCR

            vars.user = nextUser;
        }
    }

    function _getTotalsFromLiquidateNestsSequence_NormalMode
    (
        IActivePool _activePool,
        IDefaultPool _defaultPool,
        uint _price,
        uint _YUSDInStabPool,
        uint _n
    )
        internal
        returns(LiquidationTotals memory totals)
    {
        LocalVariables_LiquidationSequence memory vars;
        LiquidationValues memory singleLiquidation;
        ISortedNests sortedNestsCached = sortedNests;

        vars.remainingYUSDInStabPool = _YUSDInStabPool;

        for (vars.i = 0; vars.i < _n; vars.i++) {
            vars.user = sortedNestsCached.getLast();
            vars.ICR = getCurrentICR(vars.user, _price);

            if (vars.ICR < loansStableSettings.MCR()) {
                singleLiquidation = _liquidateNormalMode(_activePool, _defaultPool, vars.user, vars.remainingYUSDInStabPool);

                vars.remainingYUSDInStabPool -= singleLiquidation.debtToOffset;

                // Add liquidation values to their respective running totals
                totals = _addLiquidationValuesToTotals(totals, singleLiquidation);

            } else break;  // break if the loop reaches a Nest with ICR >= MCR
        }
    }

    /*
    * Attempt to liquidate a custom list of nests provided by the caller.
    */
    function batchLiquidateNests(address[] memory _nestArray) public override {
        require(_nestArray.length != 0, "NestManager: Calldata address array must not be empty");

        IActivePool activePoolCached = activePool;
        IDefaultPool defaultPoolCached = defaultPool;
        IStabilityPool stabilityPoolCached = stabilityPool;

        LocalVariables_OuterLiquidationFunction memory vars;
        LiquidationTotals memory totals;

        vars.price = priceFeed.fetchPrice();
        vars.YUSDInStabPool = stabilityPoolCached.getTotalYUSDDeposits();
        vars.recoveryModeAtStart = _checkRecoveryMode(vars.price);

        // Perform the appropriate liquidation sequence - tally values and obtain their totals.
        if (vars.recoveryModeAtStart) {
            totals = _getTotalFromBatchLiquidate_RecoveryMode(activePoolCached, defaultPoolCached, vars.price, vars.YUSDInStabPool, _nestArray);
        } else {  //  if !vars.recoveryModeAtStart
            totals = _getTotalsFromBatchLiquidate_NormalMode(activePoolCached, defaultPoolCached, vars.price, vars.YUSDInStabPool, _nestArray);
        }

        require(totals.totalDebtInSequence > 0, "NestManager: nothing to liquidate");

        // Move liquidated FLR and YUSD to the appropriate pools
        stabilityPoolCached.offset(totals.totalDebtToOffset, totals.totalCollToSendToSP);
        _redistributeDebtAndColl(activePoolCached, defaultPoolCached, totals.totalDebtToRedistribute, totals.totalCollToRedistribute);
        if (totals.totalCollSurplus > 0) {
            activePoolCached.sendFLR(address(collSurplusPool), totals.totalCollSurplus);
        }

        // Update system snapshots
        _updateSystemSnapshots_excludeCollRemainder(activePoolCached, totals.totalCollGasCompensation);

        vars.liquidatedDebt = totals.totalDebtInSequence;
        vars.liquidatedColl = totals.totalCollInSequence - totals.totalCollGasCompensation - totals.totalCollSurplus;
        emit Liquidation(vars.liquidatedDebt, vars.liquidatedColl, totals.totalCollGasCompensation, totals.totalYUSDGasCompensation);

        // Send gas compensation to caller
        _sendGasCompensation(activePoolCached, msg.sender, totals.totalYUSDGasCompensation, totals.totalCollGasCompensation);
    }

    /*
    * This function is used when the batch liquidation sequence starts during Recovery Mode. However, it
    * handle the case where the system *leaves* Recovery Mode, part way through the liquidation sequence
    */
    function _getTotalFromBatchLiquidate_RecoveryMode
    (
        IActivePool _activePool,
        IDefaultPool _defaultPool,
        uint _price,
        uint _YUSDInStabPool,
        address[] memory _nestArray
    )
        internal
        returns(LiquidationTotals memory totals)
    {
        LocalVariables_LiquidationSequence memory vars;
        LiquidationValues memory singleLiquidation;

        vars.remainingYUSDInStabPool = _YUSDInStabPool;
        vars.backToNormalMode = false;
        vars.entireSystemDebt = getEntireSystemDebt();
        vars.entireSystemColl = getEntireSystemColl();

        for (vars.i = 0; vars.i < _nestArray.length; vars.i++) {
            vars.user = _nestArray[vars.i];
            // Skip non-active nests
            if (Nests[vars.user].status != Status.active) { continue; }
            vars.ICR = getCurrentICR(vars.user, _price);

            uint MCR = loansStableSettings.MCR();
            if (!vars.backToNormalMode) {
                // Skip this nest if ICR is greater than MCR and Stability Pool is empty
                if (vars.ICR >= MCR && vars.remainingYUSDInStabPool == 0) { continue; }

                uint TCR = FlareLoansStableMath._computeCR(vars.entireSystemColl, vars.entireSystemDebt, _price);

                singleLiquidation = _liquidateRecoveryMode(_activePool, _defaultPool, vars.user, vars.ICR, vars.remainingYUSDInStabPool, TCR, _price);

                // Update aggregate trackers
                vars.remainingYUSDInStabPool -= singleLiquidation.debtToOffset;
                vars.entireSystemDebt -= singleLiquidation.debtToOffset;
                vars.entireSystemColl -= singleLiquidation.collToSendToSP;

                // Add liquidation values to their respective running totals
                totals = _addLiquidationValuesToTotals(totals, singleLiquidation);

                vars.backToNormalMode = !_checkPotentialRecoveryMode(vars.entireSystemColl, vars.entireSystemDebt, _price);
            }

            else if (vars.backToNormalMode && vars.ICR < MCR) {
                singleLiquidation = _liquidateNormalMode(_activePool, _defaultPool, vars.user, vars.remainingYUSDInStabPool);
                vars.remainingYUSDInStabPool -= singleLiquidation.debtToOffset;

                // Add liquidation values to their respective running totals
                totals = _addLiquidationValuesToTotals(totals, singleLiquidation);

            } else continue; // In Normal Mode skip nests with ICR >= MCR
        }
    }

    function _getTotalsFromBatchLiquidate_NormalMode
    (
        IActivePool _activePool,
        IDefaultPool _defaultPool,
        uint _price,
        uint _YUSDInStabPool,
        address[] memory _nestArray
    )
        internal
        returns(LiquidationTotals memory totals)
    {
        LocalVariables_LiquidationSequence memory vars;
        LiquidationValues memory singleLiquidation;

        vars.remainingYUSDInStabPool = _YUSDInStabPool;

        for (vars.i = 0; vars.i < _nestArray.length; vars.i++) {
            vars.user = _nestArray[vars.i];
            vars.ICR = getCurrentICR(vars.user, _price);

            if (vars.ICR < loansStableSettings.MCR()) {
                singleLiquidation = _liquidateNormalMode(_activePool, _defaultPool, vars.user, vars.remainingYUSDInStabPool);
                vars.remainingYUSDInStabPool -= singleLiquidation.debtToOffset;

                // Add liquidation values to their respective running totals
                totals = _addLiquidationValuesToTotals(totals, singleLiquidation);
            }
        }
    }

    // --- Liquidation helper functions ---

    function _addLiquidationValuesToTotals(LiquidationTotals memory oldTotals, LiquidationValues memory singleLiquidation)
    internal pure returns(LiquidationTotals memory newTotals) {

        // Tally all the values with their respective running totals
        newTotals.totalCollGasCompensation = oldTotals.totalCollGasCompensation + singleLiquidation.collGasCompensation;
        newTotals.totalYUSDGasCompensation = oldTotals.totalYUSDGasCompensation + singleLiquidation.YUSDGasCompensation;
        newTotals.totalDebtInSequence = oldTotals.totalDebtInSequence + singleLiquidation.entireNestDebt;
        newTotals.totalCollInSequence = oldTotals.totalCollInSequence + singleLiquidation.entireNestColl;
        newTotals.totalDebtToOffset = oldTotals.totalDebtToOffset + singleLiquidation.debtToOffset;
        newTotals.totalCollToSendToSP = oldTotals.totalCollToSendToSP + singleLiquidation.collToSendToSP;
        newTotals.totalDebtToRedistribute = oldTotals.totalDebtToRedistribute + singleLiquidation.debtToRedistribute;
        newTotals.totalCollToRedistribute = oldTotals.totalCollToRedistribute + singleLiquidation.collToRedistribute;
        newTotals.totalCollSurplus = oldTotals.totalCollSurplus + singleLiquidation.collSurplus;

        return newTotals;
    }

    function _sendGasCompensation(IActivePool _activePool, address _liquidator, uint _YUSD, uint _FLR) internal {
        if (_YUSD > 0) {
            yusdToken.returnFromPool(gasPoolAddress, _liquidator, _YUSD);
        }

        if (_FLR > 0) {
            _activePool.sendFLR(_liquidator, _FLR);
        }
    }

    // Move a Nest's pending debt and collateral rewards from distributions, from the Default Pool to the Active Pool
    function _movePendingNestRewardsToActivePool(IActivePool _activePool, IDefaultPool _defaultPool, uint _YUSD, uint _FLR) internal {
        _defaultPool.decreaseYUSDDebt(_YUSD);
        _activePool.increaseYUSDDebt(_YUSD);
        _defaultPool.sendFLRToActivePool(_FLR);
    }

    // --- Redemption functions ---

    // Redeem as much collateral as possible from _borrower's Nest in exchange for YUSD up to _maxYUSDamount
    function _redeemCollateralFromNest(
        ContractsCache memory _contractsCache,
        address _borrower,
        uint _maxYUSDamount,
        uint _price,
        address _upperPartialRedemptionHint,
        address _lowerPartialRedemptionHint,
        uint _partialRedemptionHintNICR
    )
        internal returns (SingleRedemptionValues memory singleRedemption)
    {
        // Determine the remaining amount (lot) to be redeemed, capped by the entire debt of the Nest minus the liquidation reserve
        singleRedemption.YUSDLot = FlareLoansStableMath._min(_maxYUSDamount, Nests[_borrower].debt - YUSD_GAS_COMPENSATION);

        // Get the FLRLot of equivalent value in USD
        singleRedemption.FLRLot = singleRedemption.YUSDLot * DECIMAL_PRECISION / _price;

        // Decrease the debt and collateral of the current Nest according to the YUSD lot and corresponding FLR to send
        uint newDebt = Nests[_borrower].debt - singleRedemption.YUSDLot;
        uint newColl = Nests[_borrower].coll - singleRedemption.FLRLot;

        if (newDebt == YUSD_GAS_COMPENSATION) {
            // No debt left in the Nest (except for the liquidation reserve), therefore the nest gets closed
            _removeStake(_borrower);
            _closeNest(_borrower, Status.closedByRedemption);
            _redeemCloseNest(_contractsCache, _borrower, YUSD_GAS_COMPENSATION, newColl);
            emit NestUpdated(_borrower, 0, 0, 0, NestManagerOperation.redeemCollateral);

        } else {
            uint newNICR = FlareLoansStableMath._computeNominalCR(newColl, newDebt);

            /*
            * If the provided hint is out of date, we bail since trying to reinsert without a good hint will almost
            * certainly result in running out of gas. 
            *
            * If the resultant net debt of the partial is less than the minimum, net debt we bail.
            */
            if (newNICR != _partialRedemptionHintNICR || _getNetDebt(newDebt) < MIN_NET_DEBT) {
                singleRedemption.cancelledPartial = true;
                return singleRedemption;
            }

            _contractsCache.sortedNests.reInsert(_borrower, newNICR, _upperPartialRedemptionHint, _lowerPartialRedemptionHint);

            Nests[_borrower].debt = newDebt;
            Nests[_borrower].coll = newColl;
            _updateStakeAndTotalStakes(_borrower);

            emit NestUpdated(
                _borrower,
                newDebt, newColl,
                Nests[_borrower].stake,
                NestManagerOperation.redeemCollateral
            );
        }

        return singleRedemption;
    }

    /*
    * Called when a full redemption occurs, and closes the nest.
    * The redeemer swaps (debt - liquidation reserve) YUSD for (debt - liquidation reserve) worth of FLR, so the YUSD liquidation reserve left corresponds to the remaining debt.
    * In order to close the nest, the YUSD liquidation reserve is burned, and the corresponding debt is removed from the active pool.
    * The debt recorded on the nest's struct is zero'd elswhere, in _closeNest.
    * Any surplus FLR left in the nest, is sent to the Coll surplus pool, and can be later claimed by the borrower.
    */
    function _redeemCloseNest(ContractsCache memory _contractsCache, address _borrower, uint _YUSD, uint _FLR) internal {
        _contractsCache.yusdToken.burn(gasPoolAddress, _YUSD);
        // Update Active Pool YUSD, and send FLR to account
        _contractsCache.activePool.decreaseYUSDDebt(_YUSD);

        // send FLR from Active Pool to CollSurplus Pool
        _contractsCache.collSurplusPool.accountSurplus(_borrower, _FLR);
        _contractsCache.activePool.sendFLR(address(_contractsCache.collSurplusPool), _FLR);
    }

    function _isValidFirstRedemptionHint(ISortedNests _sortedNests, address _firstRedemptionHint, uint _price) internal view returns (bool) {
        uint MCR = loansStableSettings.MCR();
        if (_firstRedemptionHint == address(0) ||
            !_sortedNests.contains(_firstRedemptionHint) ||
            getCurrentICR(_firstRedemptionHint, _price) < MCR
        ) {
            return false;
        }

        address nextNest = _sortedNests.getNext(_firstRedemptionHint);
        return nextNest == address(0) || getCurrentICR(nextNest, _price) < MCR;
    }

    /* Send _YUSDamount YUSD to the system and redeem the corresponding amount of collateral from as many Nests as are needed to fill the redemption
    * request.  Applies pending rewards to a Nest before reducing its debt and coll.
    *
    * Note that if _amount is very large, this function can run out of gas, specially if traversed nests are small. This can be easily avoided by
    * splitting the total _amount in appropriate chunks and calling the function multiple times.
    *
    * Param `_maxIterations` can also be provided, so the loop through Nests is capped (if it’s zero, it will be ignored).This makes it easier to
    * avoid OOG for the frontend, as only knowing approximately the average cost of an iteration is enough, without needing to know the “topology”
    * of the nest list. It also avoids the need to set the cap in stone in the contract, nor doing gas calculations, as both gas price and opcode
    * costs can vary.
    *
    * All Nests that are redeemed from -- with the likely exception of the last one -- will end up with no debt left, therefore they will be closed.
    * If the last Nest does have some remaining debt, it has a finite ICR, and the reinsertion could be anywhere in the list, therefore it requires a hint.
    * A frontend should use getRedemptionHints() to calculate what the ICR of this Nest will be after redemption, and pass a hint for its position
    * in the sortedNests list along with the ICR value that the hint was found for.
    *
    * If another transaction modifies the list between calling getRedemptionHints() and passing the hints to redeemCollateral(), it
    * is very likely that the last (partially) redeemed Nest would end up with a different ICR than what the hint is for. In this case the
    * redemption will stop after the last completely redeemed Nest and the sender will keep the remaining YUSD amount, which they can attempt
    * to redeem later.
    */
    function redeemCollateral(
        uint _YUSDamount,
        address _firstRedemptionHint,
        address _upperPartialRedemptionHint,
        address _lowerPartialRedemptionHint,
        uint _partialRedemptionHintNICR,
        uint _maxIterations,
        uint _maxFeePercentage
    )
        external
        override
    {
        ContractsCache memory contractsCache = ContractsCache(
            activePool,
            defaultPool,
            yusdToken,
            sortedNests,
            collSurplusPool,
            gasPoolAddress
        );
        RedemptionTotals memory totals;

        _requireValidMaxFeePercentage(_maxFeePercentage);
        totals.price = priceFeed.fetchPrice();
        _requireTCRoverMCR(totals.price);
        _requireAmountGreaterThanZero(_YUSDamount);
        _requireYUSDBalanceCoversRedemption(contractsCache.yusdToken, msg.sender, _YUSDamount);

        totals.totalYUSDSupplyAtStart = getEntireSystemDebt();
        // Confirm redeemer's balance is less than total YUSD supply
        assert(contractsCache.yusdToken.balanceOf(msg.sender) <= totals.totalYUSDSupplyAtStart);

        totals.remainingYUSD = _YUSDamount;
        address currentBorrower;

        if (_isValidFirstRedemptionHint(contractsCache.sortedNests, _firstRedemptionHint, totals.price)) {
            currentBorrower = _firstRedemptionHint;
        } else {
            currentBorrower = contractsCache.sortedNests.getLast();
            // Find the first nest with ICR >= MCR
            while (currentBorrower != address(0) && getCurrentICR(currentBorrower, totals.price) < loansStableSettings.MCR()) {
                currentBorrower = contractsCache.sortedNests.getPrev(currentBorrower);
            }
        }

        // Loop through the Nests starting from the one with lowest collateral ratio until _amount of YUSD is exchanged for collateral
        if (_maxIterations == 0) { _maxIterations = type(uint256).max; }
        while (currentBorrower != address(0) && totals.remainingYUSD > 0 && _maxIterations > 0) {
            _maxIterations--;
            // Save the address of the Nest preceding the current one, before potentially modifying the list
            address nextUserToCheck = contractsCache.sortedNests.getPrev(currentBorrower);

            _applyPendingRewards(contractsCache.activePool, contractsCache.defaultPool, currentBorrower);

            SingleRedemptionValues memory singleRedemption = _redeemCollateralFromNest(
                contractsCache,
                currentBorrower,
                totals.remainingYUSD,
                totals.price,
                _upperPartialRedemptionHint,
                _lowerPartialRedemptionHint,
                _partialRedemptionHintNICR
            );

            if (singleRedemption.cancelledPartial) break; // Partial redemption was cancelled (out-of-date hint, or new net debt < minimum), therefore we could not redeem from the last Nest

            totals.totalYUSDToRedeem  += singleRedemption.YUSDLot;
            totals.totalFLRDrawn += singleRedemption.FLRLot;

            totals.remainingYUSD = totals.remainingYUSD - singleRedemption.YUSDLot;
            currentBorrower = nextUserToCheck;
        }
        require(totals.totalFLRDrawn > 0, "NestManager: Unable to redeem any amount");

        // Decay the baseRate due to time passed, and then increase it according to the size of this redemption.
        // Use the saved total YUSD supply value, from before it was reduced by the redemption.
        _updateBaseRateFromRedemption(totals.totalFLRDrawn, totals.price, totals.totalYUSDSupplyAtStart);

        // Calculate the FLR fee
        totals.FLRFee = _getRedemptionFee(totals.totalFLRDrawn);

        _requireUserAcceptsFee(totals.FLRFee, totals.totalFLRDrawn, _maxFeePercentage);

        // Send the FLR fee to the Kakeibo and DFLR staking
        uint dflrStakingFeeReward = contractsCache.activePool.processFLRFee(totals.FLRFee);
        dflrStaking.increaseF_FLR(dflrStakingFeeReward);

        totals.FLRToSendToRedeemer = totals.totalFLRDrawn - totals.FLRFee;

        emit Redemption(_YUSDamount, totals.totalYUSDToRedeem, totals.totalFLRDrawn, totals.FLRFee);

        // Burn the total YUSD that is cancelled with debt, and send the redeemed FLR to msg.sender
        contractsCache.yusdToken.burn(msg.sender, totals.totalYUSDToRedeem);
        // Update Active Pool YUSD, and send FLR to account
        contractsCache.activePool.decreaseYUSDDebt(totals.totalYUSDToRedeem);
        contractsCache.activePool.sendFLR(msg.sender, totals.FLRToSendToRedeemer);
    }

    // --- Helper functions ---

    // Return the nominal collateral ratio (ICR) of a given Nest, without the price. Takes a nest's pending coll and debt rewards from redistributions into account.
    function getNominalICR(address _borrower) public view override returns (uint) {
        (uint currentFLR, uint currentYUSDDebt) = _getCurrentNestAmounts(_borrower);

        uint NICR = FlareLoansStableMath._computeNominalCR(currentFLR, currentYUSDDebt);
        return NICR;
    }

    // Return the current collateral ratio (ICR) of a given Nest. Takes a nest's pending coll and debt rewards from redistributions into account.
    function getCurrentICR(address _borrower, uint _price) public view override returns (uint) {
        (uint currentFLR, uint currentYUSDDebt) = _getCurrentNestAmounts(_borrower);

        uint ICR = FlareLoansStableMath._computeCR(currentFLR, currentYUSDDebt, _price);
        return ICR;
    }

    function _getCurrentNestAmounts(address _borrower) internal view returns (uint, uint) {
        uint pendingFLRReward = getPendingFLRReward(_borrower);
        uint pendingYUSDDebtReward = getPendingYUSDDebtReward(_borrower);

        uint currentFLR = Nests[_borrower].coll + pendingFLRReward;
        uint currentYUSDDebt = Nests[_borrower].debt + pendingYUSDDebtReward;

        return (currentFLR, currentYUSDDebt);
    }

    function applyPendingRewards(address _borrower) external override {
        _requireCallerIsBorrowerOperations();
        return _applyPendingRewards(activePool, defaultPool, _borrower);
    }

    // Add the borrowers's coll and debt rewards earned from redistributions, to their Nest
    function _applyPendingRewards(IActivePool _activePool, IDefaultPool _defaultPool, address _borrower) internal {
        if (hasPendingRewards(_borrower)) {
            _requireNestIsActive(_borrower);

            // Compute pending rewards
            uint pendingFLRReward = getPendingFLRReward(_borrower);
            uint pendingYUSDDebtReward = getPendingYUSDDebtReward(_borrower);

            // Apply pending rewards to nest's state
            Nests[_borrower].coll += pendingFLRReward;
            Nests[_borrower].debt += pendingYUSDDebtReward;

            _updateNestRewardSnapshots(_borrower);

            // Transfer from DefaultPool to ActivePool
            _movePendingNestRewardsToActivePool(_activePool, _defaultPool, pendingYUSDDebtReward, pendingFLRReward);

            emit NestUpdated(
                _borrower,
                Nests[_borrower].debt,
                Nests[_borrower].coll,
                Nests[_borrower].stake,
                NestManagerOperation.applyPendingRewards
            );
        }
    }

    // Update borrower's snapshots of L_FLR and L_YUSDDebt to reflect the current values
    function updateNestRewardSnapshots(address _borrower) external override {
        _requireCallerIsBorrowerOperations();
       return _updateNestRewardSnapshots(_borrower);
    }

    function _updateNestRewardSnapshots(address _borrower) internal {
        rewardSnapshots[_borrower].FLR = L_FLR;
        rewardSnapshots[_borrower].YUSDDebt = L_YUSDDebt;
        emit NestSnapshotsUpdated(L_FLR, L_YUSDDebt);
    }

    // Get the borrower's pending accumulated FLR reward, earned by their stake
    function getPendingFLRReward(address _borrower) public view override returns (uint) {
        uint snapshotFLR = rewardSnapshots[_borrower].FLR;
        uint rewardPerUnitStaked = L_FLR - snapshotFLR;

        if ( rewardPerUnitStaked == 0 || Nests[_borrower].status != Status.active) { return 0; }

        uint stake = Nests[_borrower].stake;

        uint pendingFLRReward = stake * rewardPerUnitStaked / DECIMAL_PRECISION;

        return pendingFLRReward;
    }
    
    // Get the borrower's pending accumulated YUSD reward, earned by their stake
    function getPendingYUSDDebtReward(address _borrower) public view override returns (uint) {
        uint snapshotYUSDDebt = rewardSnapshots[_borrower].YUSDDebt;
        uint rewardPerUnitStaked = L_YUSDDebt - snapshotYUSDDebt;

        if ( rewardPerUnitStaked == 0 || Nests[_borrower].status != Status.active) { return 0; }

        uint stake =  Nests[_borrower].stake;

        uint pendingYUSDDebtReward = stake * rewardPerUnitStaked / DECIMAL_PRECISION;

        return pendingYUSDDebtReward;
    }

    function hasPendingRewards(address _borrower) public view override returns (bool) {
        /*
        * A Nest has pending rewards if its snapshot is less than the current rewards per-unit-staked sum:
        * this indicates that rewards have occured since the snapshot was made, and the user therefore has
        * pending rewards
        */
        if (Nests[_borrower].status != Status.active) {return false;}
       
        return (rewardSnapshots[_borrower].FLR < L_FLR);
    }

    // Return the Nests entire debt and coll, including pending rewards from redistributions.
    function getEntireDebtAndColl(
        address _borrower
    )
        public
        view
        override
        returns (uint debt, uint coll, uint pendingYUSDDebtReward, uint pendingFLRReward)
    {
        debt = Nests[_borrower].debt;
        coll = Nests[_borrower].coll;

        pendingYUSDDebtReward = getPendingYUSDDebtReward(_borrower);
        pendingFLRReward = getPendingFLRReward(_borrower);

        debt += pendingYUSDDebtReward;
        coll += pendingFLRReward;
    }

    function removeStake(address _borrower) external override {
        _requireCallerIsBorrowerOperations();
        return _removeStake(_borrower);
    }

    // Remove borrower's stake from the totalStakes sum, and set their stake to 0
    function _removeStake(address _borrower) internal {
        uint stake = Nests[_borrower].stake;
        totalStakes -= stake;
        Nests[_borrower].stake = 0;
    }

    function updateStakeAndTotalStakes(address _borrower) external override returns (uint) {
        _requireCallerIsBorrowerOperations();
        return _updateStakeAndTotalStakes(_borrower);
    }

    // Update borrower's stake based on their latest collateral value
    function _updateStakeAndTotalStakes(address _borrower) internal returns (uint) {
        uint newStake = _computeNewStake(Nests[_borrower].coll);
        uint oldStake = Nests[_borrower].stake;
        Nests[_borrower].stake = newStake;

        totalStakes = totalStakes - oldStake + newStake;
        emit TotalStakesUpdated(totalStakes);

        return newStake;
    }

    // Calculate a new stake based on the snapshots of the totalStakes and totalCollateral taken at the last liquidation
    function _computeNewStake(uint _coll) internal view returns (uint) {
        uint stake;
        if (totalCollateralSnapshot == 0) {
            stake = _coll;
        } else {
            /*
            * The following assert() holds true because:
            * - The system always contains >= 1 nest
            * - When we close or liquidate a nest, we redistribute the pending rewards, so if all nests were closed/liquidated,
            * rewards would’ve been emptied and totalCollateralSnapshot would be zero too.
            */
            assert(totalStakesSnapshot > 0);
            stake = _coll * totalStakesSnapshot / totalCollateralSnapshot;
        }
        return stake;
    }

    function _redistributeDebtAndColl(IActivePool _activePool, IDefaultPool _defaultPool, uint _debt, uint _coll) internal {
        if (_debt == 0) { return; }

        /*
        * Add distributed coll and debt rewards-per-unit-staked to the running totals. Division uses a "feedback"
        * error correction, to keep the cumulative error low in the running totals L_FLR and L_YUSDDebt:
        *
        * 1) Form numerators which compensate for the floor division errors that occurred the last time this
        * function was called.
        * 2) Calculate "per-unit-staked" ratios.
        * 3) Multiply each ratio back by its denominator, to reveal the current floor division error.
        * 4) Store these errors for use in the next correction when this function is called.
        * 5) Note: static analysis tools complain about this "division before multiplication", however, it is intended.
        */
        uint FLRNumerator = _coll * DECIMAL_PRECISION + lastFLRError_Redistribution;
        uint YUSDDebtNumerator = _debt * DECIMAL_PRECISION + lastYUSDDebtError_Redistribution;

        // Get the per-unit-staked terms
        uint FLRRewardPerUnitStaked = FLRNumerator / totalStakes;
        uint YUSDDebtRewardPerUnitStaked = YUSDDebtNumerator / totalStakes;

        lastFLRError_Redistribution = FLRNumerator - (FLRRewardPerUnitStaked * totalStakes);
        lastYUSDDebtError_Redistribution = YUSDDebtNumerator - (YUSDDebtRewardPerUnitStaked * totalStakes);

        // Add per-unit-staked terms to the running totals
        L_FLR += FLRRewardPerUnitStaked;
        L_YUSDDebt += YUSDDebtRewardPerUnitStaked;

        emit LTermsUpdated(L_FLR, L_YUSDDebt);

        // Transfer coll and debt from ActivePool to DefaultPool
        _activePool.decreaseYUSDDebt(_debt);
        _defaultPool.increaseYUSDDebt(_debt);
        _activePool.sendFLR(address(_defaultPool), _coll);
    }

    function closeNest(address _borrower) external override {
        _requireCallerIsBorrowerOperations();
        return _closeNest(_borrower, Status.closedByOwner);
    }

    function _closeNest(address _borrower, Status closedStatus) internal {
        assert(closedStatus != Status.nonExistent && closedStatus != Status.active);

        uint NestOwnersArrayLength = NestOwners.length;
        _requireMoreThanOneNestInSystem(NestOwnersArrayLength);

        Nests[_borrower].status = closedStatus;
        Nests[_borrower].coll = 0;
        Nests[_borrower].debt = 0;

        rewardSnapshots[_borrower].FLR = 0;
        rewardSnapshots[_borrower].YUSDDebt = 0;

        _removeNestOwner(_borrower, NestOwnersArrayLength);
        sortedNests.remove(_borrower);
    }

    /*
    * Updates snapshots of system total stakes and total collateral, excluding a given collateral remainder from the calculation.
    * Used in a liquidation sequence.
    *
    * The calculation excludes a portion of collateral that is in the ActivePool:
    *
    * the total FLR gas compensation from the liquidation sequence
    *
    * The FLR as compensation must be excluded as it is always sent out at the very end of the liquidation sequence.
    */
    function _updateSystemSnapshots_excludeCollRemainder(IActivePool _activePool, uint _collRemainder) internal {
        totalStakesSnapshot = totalStakes;

        uint activeColl = _activePool.getFLR();
        uint liquidatedColl = defaultPool.getFLR();
        totalCollateralSnapshot = activeColl - _collRemainder + liquidatedColl;

        emit SystemSnapshotsUpdated(totalStakesSnapshot, totalCollateralSnapshot);
    }

    // Push the owner's address to the Nest owners list, and record the corresponding array index on the Nest struct
    function addNestOwnerToArray(address _borrower) external override returns (uint index) {
        _requireCallerIsBorrowerOperations();
        return _addNestOwnerToArray(_borrower);
    }

    function _addNestOwnerToArray(address _borrower) internal returns (uint128 index) {
        /* Max array size is 2**128 - 1, i.e. ~3e30 nests. No risk of overflow, since nests have minimum YUSD
        debt of liquidation reserve plus MIN_NET_DEBT. 3e30 YUSD dwarfs the value of all wealth in the world ( which is < 1e15 USD). */

        // Push the Nestowner to the array
        NestOwners.push(_borrower);

        // Record the index of the new Nestowner on their Nest struct
        index = uint128(NestOwners.length - 1);
        Nests[_borrower].arrayIndex = index;

        return index;
    }

    /*
    * Remove a Nest owner from the NestOwners array, not preserving array order. Removing owner 'B' does the following:
    * [A B C D E] => [A E C D], and updates E's Nest struct to point to its new array index.
    */
    function _removeNestOwner(address _borrower, uint NestOwnersArrayLength) internal {
        Status nestStatus = Nests[_borrower].status;
        // It’s set in caller function `_closeNest`
        assert(nestStatus != Status.nonExistent && nestStatus != Status.active);

        uint128 index = Nests[_borrower].arrayIndex;
        uint length = NestOwnersArrayLength;
        uint idxLast = length - 1;

        assert(index <= idxLast);

        address addressToMove = NestOwners[idxLast];

        NestOwners[index] = addressToMove;
        Nests[addressToMove].arrayIndex = index;
        emit NestIndexUpdated(addressToMove, index);

        NestOwners.pop();
    }

    // --- Recovery Mode and TCR functions ---

    function getTCR(uint _price) external view override returns (uint) {
        return _getTCR(_price);
    }

    function checkRecoveryMode(uint _price) external view override returns (bool) {
        return _checkRecoveryMode(_price);
    }

    // Check whether or not the system *would be* in Recovery Mode, given an FLR:USD price, and the entire system coll and debt.
    function _checkPotentialRecoveryMode(
        uint _entireSystemColl,
        uint _entireSystemDebt,
        uint _price
    )
        internal
        view
    returns (bool)
    {
        uint TCR = FlareLoansStableMath._computeCR(_entireSystemColl, _entireSystemDebt, _price);

        return TCR < loansStableSettings.CCR();
    }

    // --- Redemption fee functions ---

    /*
    * This function has two impacts on the baseRate state variable:
    * 1) decays the baseRate based on time passed since last redemption or YUSD borrowing operation.
    * then,
    * 2) increases the baseRate based on the amount redeemed, as a proportion of total supply
    */
    function _updateBaseRateFromRedemption(uint _FLRDrawn,  uint _price, uint _totalYUSDSupply) internal returns (uint) {
        uint decayedBaseRate = _calcDecayedBaseRate();

        /* Convert the drawn FLR back to YUSD at face value rate (1 YUSD:1 USD), in order to get
        * the fraction of total supply that was redeemed at face value. */
        uint redeemedYUSDFraction = _FLRDrawn * _price / _totalYUSDSupply;

        uint newBaseRate = decayedBaseRate + redeemedYUSDFraction / BETA;
        newBaseRate = FlareLoansStableMath._min(newBaseRate, DECIMAL_PRECISION); // cap baseRate at a maximum of 100%
        //assert(newBaseRate <= DECIMAL_PRECISION); // This is already enforced in the line above
        assert(newBaseRate > 0); // Base rate is always non-zero after redemption

        // Update the baseRate state variable
        baseRate = newBaseRate;
        emit BaseRateUpdated(newBaseRate);
        
        _updateLastFeeOpTime();

        return newBaseRate;
    }

    function getRedemptionRate() public view override returns (uint) {
        return _calcRedemptionRate(baseRate);
    }

    function getRedemptionRateWithDecay() public view override returns (uint) {
        return _calcRedemptionRate(_calcDecayedBaseRate());
    }

    function _calcRedemptionRate(uint _baseRate) internal pure returns (uint) {
        return FlareLoansStableMath._min(
            REDEMPTION_FEE_FLOOR + _baseRate,
            DECIMAL_PRECISION // cap at a maximum of 100%
        );
    }

    function _getRedemptionFee(uint _FLRDrawn) internal view returns (uint) {
        return _calcRedemptionFee(getRedemptionRate(), _FLRDrawn);
    }

    function getRedemptionFeeWithDecay(uint _FLRDrawn) external view override returns (uint) {
        return _calcRedemptionFee(getRedemptionRateWithDecay(), _FLRDrawn);
    }

    function _calcRedemptionFee(uint _redemptionRate, uint _FLRDrawn) internal pure returns (uint) {
        uint redemptionFee = _redemptionRate * _FLRDrawn / DECIMAL_PRECISION;
        require(redemptionFee < _FLRDrawn, "NestManager: Fee would eat up all returned collateral");
        return redemptionFee;
    }

    // --- Borrowing fee functions ---

    function getBorrowingRate() public view override returns (uint) {
        return _calcBorrowingRate(baseRate);
    }

    function getBorrowingRateWithDecay() public view override returns (uint) {
        return _calcBorrowingRate(_calcDecayedBaseRate());
    }

    function _calcBorrowingRate(uint _baseRate) internal pure returns (uint) {
        return FlareLoansStableMath._min(
            BORROWING_FEE_FLOOR + _baseRate,
            MAX_BORROWING_FEE
        );
    }

    function getBorrowingFee(uint _YUSDDebt) external view override returns (uint) {
        return _calcBorrowingFee(getBorrowingRate(), _YUSDDebt);
    }

    function getBorrowingFeeWithDecay(uint _YUSDDebt) external view override returns (uint) {
        return _calcBorrowingFee(getBorrowingRateWithDecay(), _YUSDDebt);
    }

    function _calcBorrowingFee(uint _borrowingRate, uint _YUSDDebt) internal pure returns (uint) {
        return _borrowingRate * _YUSDDebt / DECIMAL_PRECISION;
    }


    // Updates the baseRate state variable based on time elapsed since the last redemption or YUSD borrowing operation.
    function decayBaseRateFromBorrowing() external override {
        _requireCallerIsBorrowerOperations();

        uint decayedBaseRate = _calcDecayedBaseRate();
        assert(decayedBaseRate <= DECIMAL_PRECISION);  // The baseRate can decay to 0

        baseRate = decayedBaseRate;
        emit BaseRateUpdated(decayedBaseRate);

        _updateLastFeeOpTime();
    }

    // --- Internal fee functions ---

    // Update the last fee operation time only if time passed >= decay interval. This prevents base rate griefing.
    function _updateLastFeeOpTime() internal {
        uint timePassed = block.timestamp - lastFeeOperationTime;

        if (timePassed >= 1 minutes) {
            lastFeeOperationTime = block.timestamp;
            emit LastFeeOpTimeUpdated(block.timestamp);
        }
    }

    function _calcDecayedBaseRate() internal view returns (uint) {
        uint minutesPassed = _minutesPassedSinceLastFeeOp();
        uint decayFactor = FlareLoansStableMath._decPow(MINUTE_DECAY_FACTOR, minutesPassed);

        return baseRate * decayFactor / DECIMAL_PRECISION;
    }

    function _minutesPassedSinceLastFeeOp() internal view returns (uint) {
        return (block.timestamp - lastFeeOperationTime) / 1 minutes;
    }

    // --- 'require' wrapper functions ---

    function _requireCallerIsBorrowerOperations() internal view {
        require(msg.sender == borrowerOperationsAddress, "NestManager: Caller is not the BorrowerOperations contract");
    }

    function _requireNestIsActive(address _borrower) internal view {
        require(Nests[_borrower].status == Status.active, "NestManager: Nest does not exist or is closed");
    }

    function _requireYUSDBalanceCoversRedemption(IYUSDToken _yusdToken, address _redeemer, uint _amount) internal view {
        require(_yusdToken.balanceOf(_redeemer) >= _amount, "NestManager: Requested redemption amount must be <= user's YUSD token balance");
    }

    function _requireMoreThanOneNestInSystem(uint NestOwnersArrayLength) internal view {
        require (NestOwnersArrayLength > 1 && sortedNests.getSize() > 1, "NestManager: Only one nest in the system");
    }

    function _requireAmountGreaterThanZero(uint _amount) internal pure {
        require(_amount > 0, "NestManager: Amount must be greater than zero");
    }

    function _requireTCRoverMCR(uint _price) internal view {
        require(_getTCR(_price) >= loansStableSettings.MCR(), "NestManager: Cannot redeem when TCR < MCR");
    }

    function _requireValidMaxFeePercentage(uint _maxFeePercentage) internal pure {
        require(_maxFeePercentage >= REDEMPTION_FEE_FLOOR && _maxFeePercentage <= DECIMAL_PRECISION,
            "Max fee percentage must be between 0.5% and 100%");
    }

    // --- Nest property getters ---

    function getNestStatus(address _borrower) external view override returns (uint) {
        return uint(Nests[_borrower].status);
    }

    function getNestStake(address _borrower) external view override returns (uint) {
        return Nests[_borrower].stake;
    }

    function getNestDebt(address _borrower) external view override returns (uint) {
        return Nests[_borrower].debt;
    }

    function getNestColl(address _borrower) external view override returns (uint) {
        return Nests[_borrower].coll;
    }

    // --- Nest property setters, called by BorrowerOperations ---

    function setNestStatus(address _borrower, uint _num) external override {
        _requireCallerIsBorrowerOperations();
        Nests[_borrower].status = Status(_num);
    }

    function increaseNestColl(address _borrower, uint _collIncrease) external override returns (uint) {
        _requireCallerIsBorrowerOperations();
        uint newColl = Nests[_borrower].coll + _collIncrease;
        Nests[_borrower].coll = newColl;
        return newColl;
    }

    function decreaseNestColl(address _borrower, uint _collDecrease) external override returns (uint) {
        _requireCallerIsBorrowerOperations();
        uint newColl = Nests[_borrower].coll - _collDecrease;
        Nests[_borrower].coll = newColl;
        return newColl;
    }

    function increaseNestDebt(address _borrower, uint _debtIncrease) external override returns (uint) {
        _requireCallerIsBorrowerOperations();
        uint newDebt = Nests[_borrower].debt + _debtIncrease;
        Nests[_borrower].debt = newDebt;
        return newDebt;
    }

    function decreaseNestDebt(address _borrower, uint _debtDecrease) external override returns (uint) {
        _requireCallerIsBorrowerOperations();
        uint newDebt = Nests[_borrower].debt - _debtDecrease;
        Nests[_borrower].debt = newDebt;
        return newDebt;
    }
}
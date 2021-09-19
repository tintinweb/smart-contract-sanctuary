// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./IBorrowerOperations.sol";
import "./IStabilityPool.sol";
import "./IBorrowerOperations.sol";
import "./IFRC20.sol";
import "./INestManager.sol";
import "./IYUSDToken.sol";
import "./ISortedNests.sol";
import "./FlareLoansStableBase.sol";
import "./Ownable.sol";
import "./Address.sol";

/*
 * The Stability Pool holds YUSD tokens deposited by Stability Pool depositors.
 *
 * When a nest is liquidated, then depending on system conditions, some of its YUSD debt gets offset with
 * YUSD in the Stability Pool:  that is, the offset debt evaporates, and an equal amount of YUSD tokens in the Stability Pool is burned.
 *
 * Thus, a liquidation causes each depositor to receive a YUSD loss, in proportion to their deposit as a share of total deposits.
 * They also receive an FLR gain, as the FLR collateral of the liquidated nest is distributed among Stability depositors,
 * in the same proportion.
 *
 * When a liquidation occurs, it depletes every deposit by the same fraction: for example, a liquidation that depletes 40%
 * of the total YUSD in the Stability Pool, depletes 40% of each deposit.
 *
 * A deposit that has experienced a series of liquidations is termed a "compounded deposit": each liquidation depletes the deposit,
 * multiplying it by some factor in range ]0,1[
 *
 *
 * --- IMPLEMENTATION ---
 *
 * We use a highly scalable method of tracking deposits and FLR gains that has O(1) complexity.
 *
 * When a liquidation occurs, rather than updating each depositor's deposit and FLR gain, we simply update two state variables:
 * a product P, and a sum S.
 *
 * A mathematical manipulation allows us to factor out the initial deposit, and accurately track all depositors' compounded deposits
 * and accumulated FLR gains over time, as liquidations occur, using just these two variables P and S. When depositors join the
 * Stability Pool, they get a snapshot of the latest P and S: P_t and S_t, respectively.
 *
 * For a given deposit d_t, the ratio P/P_t tells us the factor by which a deposit has decreased since it joined the Stability Pool,
 * and the term d_t * (S - S_t)/P_t gives us the deposit's total accumulated FLR gain.
 *
 * Each liquidation updates the product P and sum S. After a series of liquidations, a compounded deposit and corresponding FLR gain
 * can be calculated using the initial deposit, the depositor’s snapshots of P and S, and the latest values of P and S.
 *
 * Any time a depositor updates their deposit (withdrawal, top-up) their accumulated FLR gain is paid out, their new deposit is recorded
 * (based on their latest compounded deposit and modified by the withdrawal/top-up), and they receive new snapshots of the latest P and S.
 * Essentially, they make a fresh deposit that overwrites the old one.
 *
 *
 * --- SCALE FACTOR ---
 *
 * Since P is a running product in range ]0,1] that is always-decreasing, it should never reach 0 when multiplied by a number in range ]0,1[.
 * Unfortunately, Solidity floor division always reaches 0, sooner or later.
 *
 * A series of liquidations that nearly empty the Pool (and thus each multiply P by a very small number in range ]0,1[ ) may push P
 * to its 18 digit decimal limit, and round it to 0, when in fact the Pool hasn't been emptied: this would break deposit tracking.
 *
 * So, to track P accurately, we use a scale factor: if a liquidation would cause P to decrease to <1e-9 (and be rounded to 0 by Solidity),
 * we first multiply P by 1e9, and increment a currentScale factor by 1.
 *
 * The added benefit of using 1e9 for the scale factor (rather than 1e18) is that it ensures negligible precision loss close to the 
 * scale boundary: when P is at its minimum value of 1e9, the relative precision loss in P due to floor division is only on the 
 * order of 1e-9. 
 *
 * --- EPOCHS ---
 *
 * Whenever a liquidation fully empties the Stability Pool, all deposits should become 0. However, setting P to 0 would make P be 0
 * forever, and break all future reward calculations.
 *
 * So, every time the Stability Pool is emptied by a liquidation, we reset P = 1 and currentScale = 0, and increment the currentEpoch by 1.
 *
 * --- TRACKING DEPOSIT OVER SCALE CHANGES AND EPOCHS ---
 *
 * When a deposit is made, it gets snapshots of the currentEpoch and the currentScale.
 *
 * When calculating a compounded deposit, we compare the current epoch to the deposit's epoch snapshot. If the current epoch is newer,
 * then the deposit was present during a pool-emptying liquidation, and necessarily has been depleted to 0.
 *
 * Otherwise, we then compare the current scale to the deposit's scale snapshot. If they're equal, the compounded deposit is given by d_t * P/P_t.
 * If it spans one scale change, it is given by d_t * P/(P_t * 1e9). If it spans more than one scale change, we define the compounded deposit
 * as 0, since it is now less than 1e-9'th of its initial value (e.g. a deposit of 1 billion YUSD has depleted to < 1 YUSD).
 *
 *
 *  --- TRACKING DEPOSITOR'S FLR GAIN OVER SCALE CHANGES AND EPOCHS ---
 *
 * In the current epoch, the latest value of S is stored upon each scale change, and the mapping (scale -> S) is stored for each epoch.
 *
 * This allows us to calculate a deposit's accumulated FLR gain, during the epoch in which the deposit was non-zero and earned FLR.
 *
 * We calculate the depositor's accumulated FLR gain for the scale at which they made the deposit, using the FLR gain formula:
 * e_1 = d_t * (S - S_t) / P_t
 *
 * and also for scale after, taking care to divide the latter by a factor of 1e9:
 * e_2 = d_t * S / (P_t * 1e9)
 *
 * The gain in the second scale will be full, as the starting point was in the previous scale, thus no need to subtract anything.
 * The deposit therefore was present for reward events from the beginning of that second scale.
 *
 *        S_i-S_t + S_{i+1}
 *      .<--------.------------>
 *      .         .
 *      . S_i     .   S_{i+1}
 *   <--.-------->.<----------->
 *   S_t.         .
 *   <->.         .
 *      t         .
 *  |---+---------|-------------|-----...
 *         i            i+1
 *
 * The sum of (e_1 + e_2) captures the depositor's total accumulated FLR gain, handling the case where their
 * deposit spanned one scale change. We only care about gains across one scale change, since the compounded
 * deposit is defined as being 0 once it has spanned more than one scale change.
 *
 *
 *
 */
contract StabilityPool is FlareLoansStableBase, Ownable, IStabilityPool {
    string constant public NAME = "StabilityPool";

    IBorrowerOperations public borrowerOperations;
    INestManager public nestManager;
    IYUSDToken public yusdToken;
    
    IFRC20 public immutable rewardToken;
    //uint public immutable rewardDuration;
    uint256 public lastUpdateTime;
    uint public rewardPeriodFinish;
    uint public rewardLeft;
    uint public immutable rewardDuration;

    // Needed to check if there are pending liquidations
    ISortedNests public sortedNests;

    uint256 internal FLR;  // deposited flare tracker

    // Tracker for YUSD held in the pool. Changes when users deposit/withdraw, and when Nest debt is offset.
    uint256 internal totalYUSDDeposits;

   // --- Data structures ---

    struct FrontEnd {
        uint kickbackRate;
        bool registered;
    }

    struct Deposit {
        uint initialValue;
        address frontEndTag;
    }

    struct Snapshots {
        uint S;
        uint P;
        uint G;
        uint128 scale;
        uint128 epoch;
    }

    mapping (address => Deposit) public deposits;  // depositor address -> Deposit struct
    mapping (address => Snapshots) public depositSnapshots;  // depositor address -> snapshots struct

    mapping (address => FrontEnd) public frontEnds;  // front end address -> FrontEnd struct
    mapping (address => uint) public frontEndStakes; // front end address -> last recorded total deposits, tagged with that front end
    mapping (address => Snapshots) public frontEndSnapshots; // front end address -> snapshots struct

    /*  Product 'P': Running product by which to multiply an initial deposit, in order to find the current compounded deposit,
    * after a series of liquidations have occurred, each of which cancel some YUSD debt with the deposit.
    *
    * During its lifetime, a deposit's value evolves from d_t to d_t * P / P_t , where P_t
    * is the snapshot of P taken at the instant the deposit was made. 18-digit decimal.
    */
    uint public P = DECIMAL_PRECISION;

    uint public constant SCALE_FACTOR = 1e9;

    // Each time the scale of P shifts by SCALE_FACTOR, the scale is incremented by 1
    uint128 public currentScale;

    // With each offset that fully empties the Pool, the epoch is incremented by 1
    uint128 public currentEpoch;

    /* FLR Gain sum 'S': During its lifetime, each deposit d_t earns an FLR gain of ( d_t * [S - S_t] )/P_t, where S_t
    * is the depositor's snapshot of S taken at the time t when the deposit was made.
    *
    * The 'S' sums are stored in a nested mapping (epoch => scale => sum):
    *
    * - The inner mapping records the sum S at different scales
    * - The outer mapping records the (scale => sum) mappings, for different epochs.
    */
    mapping (uint128 => mapping(uint128 => uint)) public epochToScaleToSum;

    /*
    * Similarly, the sum 'G' is used to calculate Reward Token gains. During it's lifetime, each deposit d_t earns a Reward Token gain of
    *  ( d_t * [G - G_t] )/P_t, where G_t is the depositor's snapshot of G taken at time t when  the deposit was made.
    *
    *  Reward Token reward events occur are triggered by depositor operations (new deposit, topup, withdrawal), and liquidations.
    *  In each case, the Reward Token reward is issued (i.e. G is updated), before other state changes are made.
    */
    mapping (uint128 => mapping(uint128 => uint)) public epochToScaleToG;

    // Error tracker for the error correction in the Reward Token issuance calculation
    uint public lastRewardTokenError;
    // Error trackers for the error correction in the offset calculation
    uint public lastFLRError_Offset;
    uint public lastYUSDLossError_Offset;

    constructor(
        address owner, 
        address loansSettings, 
        address _rewardToken, 
        uint _rewardAmount, 
        uint _rewardEnd
    ) Ownable(owner) FlareLoansStableBase(loansSettings) { 
        require(Address.isContract(_rewardToken));
        require(_rewardEnd > block.timestamp, "StabilityPool: Wrong rewardEnd param");
        rewardToken = IFRC20(_rewardToken);
        rewardLeft = _rewardAmount;
        rewardPeriodFinish = _rewardEnd;
        rewardDuration = rewardPeriodFinish - block.timestamp;
        lastUpdateTime = block.timestamp;
    }

    // --- Contract setters ---

    function setAddresses(
        address _borrowerOperationsAddress,
        address _nestManagerAddress,
        address _activePoolAddress,
        address _yusdTokenAddress,
        address _sortedNestsAddress,
        address _priceFeedAddress
    )
        external
        override
        onlyOwner
    {
        Address.checkContract(_borrowerOperationsAddress);
        Address.checkContract(_nestManagerAddress);
        Address.checkContract(_activePoolAddress);
        Address.checkContract(_yusdTokenAddress);
        Address.checkContract(_sortedNestsAddress);
        Address.checkContract(_priceFeedAddress);

        borrowerOperations = IBorrowerOperations(_borrowerOperationsAddress);
        nestManager = INestManager(_nestManagerAddress);
        activePool = IActivePool(_activePoolAddress);
        yusdToken = IYUSDToken(_yusdTokenAddress);
        sortedNests = ISortedNests(_sortedNestsAddress);
        priceFeed = IPriceFeed(_priceFeedAddress);

        emit BorrowerOperationsAddressChanged(_borrowerOperationsAddress);
        emit NestManagerAddressChanged(_nestManagerAddress);
        emit ActivePoolAddressChanged(_activePoolAddress);
        emit YUSDTokenAddressChanged(_yusdTokenAddress);
        emit SortedNestsAddressChanged(_sortedNestsAddress);
        emit PriceFeedAddressChanged(_priceFeedAddress);
    }

    // --- Getters for public variables. Required by IPool interface ---

    function getFLR() external view override returns (uint) {
        return FLR;
    }

    function getTotalYUSDDeposits() external view override returns (uint) {
        return totalYUSDDeposits;
    }

    // --- External Depositor Functions ---

    /*  provideToSP():
    *
    * - Tags the deposit with the provided front end tag param, if it's a new deposit
    * - Sends depositor's accumulated gains (Reward Token, FLR) to depositor
    * - Sends the tagged front end's accumulated Reward Token gains to the tagged front end
    * - Increases deposit stake, and takes new snapshots for each.
    */
    function provideToSP(uint _amount, address _frontEndTag) external override {
        _requireFrontEndIsRegisteredOrZero(_frontEndTag);
        _requireFrontEndNotRegistered(msg.sender);
        _requireNonZeroAmount(_amount);

        uint initialDeposit = deposits[msg.sender].initialValue;

        _triggerRewardTokenIssuance();

        if (initialDeposit == 0) {_setFrontEndTag(msg.sender, _frontEndTag);}
        uint depositorFLRGain = getDepositorFLRGain(msg.sender);
        uint compoundedYUSDDeposit = getCompoundedYUSDDeposit(msg.sender);
        uint YUSDLoss = initialDeposit - compoundedYUSDDeposit; // Needed only for event log

        // First pay out any Reward Token gains
        address frontEnd = deposits[msg.sender].frontEndTag;
        _payOutRewardTokenGains(msg.sender, frontEnd);

        // Update front end stake
        uint compoundedFrontEndStake = getCompoundedFrontEndStake(frontEnd);
        uint newFrontEndStake = compoundedFrontEndStake + _amount;
        _updateFrontEndStakeAndSnapshots(frontEnd, newFrontEndStake);
        emit FrontEndStakeChanged(frontEnd, newFrontEndStake, msg.sender);

        _sendYUSDtoStabilityPool(msg.sender, _amount);

        uint newDeposit = compoundedYUSDDeposit + _amount;
        _updateDepositAndSnapshots(msg.sender, newDeposit);
        emit UserDepositChanged(msg.sender, newDeposit);

        emit FLRGainWithdrawn(msg.sender, depositorFLRGain, YUSDLoss); // YUSD Loss required for event log

        _sendFLRGainToDepositor(depositorFLRGain);
     }

    /*  withdrawFromSP():
    *
    * - Triggers a Reward Token issuance, based on time passed since the last issuance. The Reward Token issuance is shared between *all* depositors and front ends
    * - Removes the deposit's front end tag if it is a full withdrawal
    * - Sends all depositor's accumulated gains (Reward Token, FLR) to depositor
    * - Sends the tagged front end's accumulated Reward Token gains to the tagged front end
    * - Decreases deposit stake, and takes new snapshots for each.
    *
    * If _amount > userDeposit, the user withdraws all of their compounded deposit.
    */
    function withdrawFromSP(uint _amount) external override {
        if (_amount !=0) {_requireNoUnderCollateralizedNests();}
        uint initialDeposit = deposits[msg.sender].initialValue;
        _requireUserHasDeposit(initialDeposit);

        _triggerRewardTokenIssuance();

        uint depositorFLRGain = getDepositorFLRGain(msg.sender);

        uint compoundedYUSDDeposit = getCompoundedYUSDDeposit(msg.sender);
        uint YUSDtoWithdraw = FlareLoansStableMath._min(_amount, compoundedYUSDDeposit);
        uint YUSDLoss = initialDeposit - compoundedYUSDDeposit; // Needed only for event log

        // First pay out any Reward Token gains
        address frontEnd = deposits[msg.sender].frontEndTag;
        _payOutRewardTokenGains(msg.sender, frontEnd);
        
        // Update front end stake
        uint compoundedFrontEndStake = getCompoundedFrontEndStake(frontEnd);
        uint newFrontEndStake = compoundedFrontEndStake - YUSDtoWithdraw;
        _updateFrontEndStakeAndSnapshots(frontEnd, newFrontEndStake);
        emit FrontEndStakeChanged(frontEnd, newFrontEndStake, msg.sender);

        _sendYUSDToDepositor(msg.sender, YUSDtoWithdraw);

        // Update deposit
        uint newDeposit = compoundedYUSDDeposit - YUSDtoWithdraw;
        _updateDepositAndSnapshots(msg.sender, newDeposit);
        emit UserDepositChanged(msg.sender, newDeposit);

        emit FLRGainWithdrawn(msg.sender, depositorFLRGain, YUSDLoss);  // YUSD Loss required for event log

        _sendFLRGainToDepositor(depositorFLRGain);
    }

    /* withdrawFLRGainToNest:
    * - Triggers a Reward Token issuance, based on time passed since the last issuance. The Reward Token issuance is shared between *all* depositors and front ends
    * - Sends all depositor's Reward Token gain to  depositor
    * - Sends all tagged front end's Reward Token gain to the tagged front end
    * - Transfers the depositor's entire FLR gain from the Stability Pool to the caller's nest
    * - Leaves their compounded deposit in the Stability Pool
    * - Updates snapshots for deposit and tagged front end stake */
    function withdrawFLRGainToNest(address _upperHint, address _lowerHint) external override {
        uint initialDeposit = deposits[msg.sender].initialValue;
        _requireUserHasDeposit(initialDeposit);
        _requireUserHasNest(msg.sender);
        _requireUserHasFLRGain(msg.sender);

        _triggerRewardTokenIssuance();

        uint depositorFLRGain = getDepositorFLRGain(msg.sender);
        
        uint compoundedYUSDDeposit = getCompoundedYUSDDeposit(msg.sender);
        uint YUSDLoss = initialDeposit - compoundedYUSDDeposit; // Needed only for event log

        // First pay out any Reward Token gains
        address frontEnd = deposits[msg.sender].frontEndTag;
        _payOutRewardTokenGains(msg.sender, frontEnd);

        // Update front end stake
        uint compoundedFrontEndStake = getCompoundedFrontEndStake(frontEnd);
        uint newFrontEndStake = compoundedFrontEndStake;
        _updateFrontEndStakeAndSnapshots(frontEnd, newFrontEndStake);
        emit FrontEndStakeChanged(frontEnd, newFrontEndStake, msg.sender);

        _updateDepositAndSnapshots(msg.sender, compoundedYUSDDeposit);

        /* Emit events before transferring FLR gain to Nest.
         This lets the event log make more sense (i.e. so it appears that first the FLR gain is withdrawn
        and then it is deposited into the Nest, not the other way around). */
        emit FLRGainWithdrawn(msg.sender, depositorFLRGain, YUSDLoss);
        emit UserDepositChanged(msg.sender, compoundedYUSDDeposit);

        FLR -= depositorFLRGain;
        emit StabilityPoolFLRBalanceUpdated(FLR);
        emit FlareSent(msg.sender, depositorFLRGain);

        borrowerOperations.moveFLRGainToNest{ value: depositorFLRGain }(msg.sender, _upperHint, _lowerHint);
    }



    // --- Reward Token issuance functions ---

    function _triggerRewardTokenIssuance() internal {
        uint rewardAmountForPeriod;
        if (block.timestamp < rewardPeriodFinish) {
            rewardAmountForPeriod = rewardLeft * (block.timestamp - lastUpdateTime) / rewardDuration;
        } else {
            rewardAmountForPeriod = rewardLeft;
        }
        uint newRewardAmount = rewardLeft - rewardAmountForPeriod;
        emit UpdateRewardAmount(rewardLeft, newRewardAmount);
        rewardLeft = newRewardAmount;

       _updateG(rewardAmountForPeriod);
    }

    function _updateG(uint _rewardAmountForPeriod) internal {
        uint totalYUSD = totalYUSDDeposits; // cached to save an SLOAD
        /*
        * When total deposits is 0, G is not updated. In this case, the Reward Token issued can not be obtained by later
        * depositors - it is missed out on, and remains in the balanceof the contract.
        *
        */
        if (totalYUSD == 0 || _rewardAmountForPeriod == 0) {return;}

        uint RewardTokenPerUnitStaked;
        RewardTokenPerUnitStaked =_computeRewardTokenPerUnitStaked(_rewardAmountForPeriod, totalYUSD);

        uint marginalRewardTokenGain = RewardTokenPerUnitStaked * P;
        epochToScaleToG[currentEpoch][currentScale] += marginalRewardTokenGain;

        emit G_Updated(epochToScaleToG[currentEpoch][currentScale], currentEpoch, currentScale);
    }

    function _computeRewardTokenPerUnitStaked(uint _rewardAmountForPeriod, uint _totalYUSDDeposits) internal returns (uint) {
        /*  
        * Calculate the Reward Token-per-unit staked.  Division uses a "feedback" error correction, to keep the 
        * cumulative error low in the running total G:
        *
        * 1) Form a numerator which compensates for the floor division error that occurred the last time this 
        * function was called.  
        * 2) Calculate "per-unit-staked" ratio.
        * 3) Multiply the ratio back by its denominator, to reveal the current floor division error.
        * 4) Store this error for use in the next correction when this function is called.
        * 5) Note: static analysis tools complain about this "division before multiplication", however, it is intended.
        */
        uint RewardTokenNumerator = _rewardAmountForPeriod * DECIMAL_PRECISION + lastRewardTokenError;

        uint RewardTokenPerUnitStaked = RewardTokenNumerator / _totalYUSDDeposits;
        lastRewardTokenError = RewardTokenNumerator - (RewardTokenPerUnitStaked * _totalYUSDDeposits);

        return RewardTokenPerUnitStaked;
    }


    // --- Liquidation functions ---

    /*
    * Cancels out the specified debt against the YUSD contained in the Stability Pool (as far as possible)
    * and transfers the Nest's FLR collateral from ActivePool to StabilityPool.
    * Only called by liquidation functions in the NestManager.
    */
    function offset(uint _debtToOffset, uint _collToAdd) external override {
        _requireCallerIsNestManager();
        uint totalYUSD = totalYUSDDeposits; // cached to save an SLOAD
        if (totalYUSD == 0 || _debtToOffset == 0) { return; }

        _triggerRewardTokenIssuance();

        (uint FLRGainPerUnitStaked,
            uint YUSDLossPerUnitStaked) = _computeRewardsPerUnitStaked(_collToAdd, _debtToOffset, totalYUSD);

        _updateRewardSumAndProduct(FLRGainPerUnitStaked, YUSDLossPerUnitStaked);  // updates S and P

        _moveOffsetCollAndDebt(_collToAdd, _debtToOffset);
    }

    // --- Offset helper functions ---

    function _computeRewardsPerUnitStaked(
        uint _collToAdd,
        uint _debtToOffset,
        uint _totalYUSDDeposits
    )
        internal
        returns (uint FLRGainPerUnitStaked, uint YUSDLossPerUnitStaked)
    {
        /*
        * Compute the YUSD and FLR rewards. Uses a "feedback" error correction, to keep
        * the cumulative error in the P and S state variables low:
        *
        * 1) Form numerators which compensate for the floor division errors that occurred the last time this 
        * function was called.  
        * 2) Calculate "per-unit-staked" ratios.
        * 3) Multiply each ratio back by its denominator, to reveal the current floor division error.
        * 4) Store these errors for use in the next correction when this function is called.
        * 5) Note: static analysis tools complain about this "division before multiplication", however, it is intended.
        */
        uint FLRNumerator = (_collToAdd * DECIMAL_PRECISION) + lastFLRError_Offset;

        assert(_debtToOffset <= _totalYUSDDeposits);
        if (_debtToOffset == _totalYUSDDeposits) {
            YUSDLossPerUnitStaked = DECIMAL_PRECISION;  // When the Pool depletes to 0, so does each deposit 
            lastYUSDLossError_Offset = 0;
        } else {
            uint YUSDLossNumerator = _debtToOffset * DECIMAL_PRECISION - lastYUSDLossError_Offset;
            /*
            * Add 1 to make error in quotient positive. We want "slightly too much" YUSD loss,
            * which ensures the error in any given compoundedYUSDDeposit favors the Stability Pool.
            */
            YUSDLossPerUnitStaked = (YUSDLossNumerator / _totalYUSDDeposits) + 1;
            lastYUSDLossError_Offset = (YUSDLossPerUnitStaked * _totalYUSDDeposits) - YUSDLossNumerator;
        }

        FLRGainPerUnitStaked = FLRNumerator / _totalYUSDDeposits;
        lastFLRError_Offset = FLRNumerator - (FLRGainPerUnitStaked * _totalYUSDDeposits);

        return (FLRGainPerUnitStaked, YUSDLossPerUnitStaked);
    }

    // Update the Stability Pool reward sum S and product P
    function _updateRewardSumAndProduct(uint _FLRGainPerUnitStaked, uint _YUSDLossPerUnitStaked) internal {
        uint currentP = P;
        uint newP;

        assert(_YUSDLossPerUnitStaked <= DECIMAL_PRECISION);
        /*
        * The newProductFactor is the factor by which to change all deposits, due to the depletion of Stability Pool YUSD in the liquidation.
        * We make the product factor 0 if there was a pool-emptying. Otherwise, it is (1 - YUSDLossPerUnitStaked)
        */
        uint newProductFactor = uint(DECIMAL_PRECISION) - _YUSDLossPerUnitStaked;

        uint128 currentScaleCached = currentScale;
        uint128 currentEpochCached = currentEpoch;
        uint currentS = epochToScaleToSum[currentEpochCached][currentScaleCached];

        /*
        * Calculate the new S first, before we update P.
        * The FLR gain for any given depositor from a liquidation depends on the value of their deposit
        * (and the value of totalDeposits) prior to the Stability being depleted by the debt in the liquidation.
        *
        * Since S corresponds to FLR gain, and P to deposit loss, we update S first.
        */
        uint marginalFLRGain = _FLRGainPerUnitStaked * currentP;
        uint newS = currentS + marginalFLRGain;
        epochToScaleToSum[currentEpochCached][currentScaleCached] = newS;
        emit S_Updated(newS, currentEpochCached, currentScaleCached);

        // If the Stability Pool was emptied, increment the epoch, and reset the scale and product P
        if (newProductFactor == 0) {
            currentEpoch = currentEpochCached + 1;
            emit EpochUpdated(currentEpoch);
            currentScale = 0;
            emit ScaleUpdated(currentScale);
            newP = DECIMAL_PRECISION;

        // If multiplying P by a non-zero product factor would reduce P below the scale boundary, increment the scale
        } else if (currentP * newProductFactor / DECIMAL_PRECISION < SCALE_FACTOR) {
            newP = currentP * newProductFactor * SCALE_FACTOR / DECIMAL_PRECISION; 
            currentScale = currentScaleCached + 1;
            emit ScaleUpdated(currentScale);
        } else {
            newP = currentP * newProductFactor / DECIMAL_PRECISION;
        }

        assert(newP > 0);
        P = newP;

        emit P_Updated(newP);
    }

    function _moveOffsetCollAndDebt(uint _collToAdd, uint _debtToOffset) internal {
        IActivePool activePoolCached = activePool;

        // Cancel the liquidated YUSD debt with the YUSD in the stability pool
        activePoolCached.decreaseYUSDDebt(_debtToOffset);
        _decreaseYUSD(_debtToOffset);

        // Burn the debt that was successfully offset
        yusdToken.burn(address(this), _debtToOffset);

        activePoolCached.sendFLR(address(this), _collToAdd);
    }

    function _decreaseYUSD(uint _amount) internal {
        uint newTotalYUSDDeposits = totalYUSDDeposits - _amount;
        totalYUSDDeposits = newTotalYUSDDeposits;
        emit StabilityPoolYUSDBalanceUpdated(newTotalYUSDDeposits);
    }

    // --- Reward calculator functions for depositor ---

    /* Calculates the FLR gain earned by the deposit since its last snapshots were taken.
    * Given by the formula:  E = d0 * (S - S(0))/P(0)
    * where S(0) and P(0) are the depositor's snapshots of the sum S and product P, respectively.
    * d0 is the last recorded deposit value.
    */
    function getDepositorFLRGain(address _depositor) public view override returns (uint) {
        uint initialDeposit = deposits[_depositor].initialValue;

        if (initialDeposit == 0) { return 0; }

        Snapshots memory snapshots = depositSnapshots[_depositor];

        uint FLRGain = _getFLRGainFromSnapshots(initialDeposit, snapshots);
        return FLRGain;
    }

    function _getFLRGainFromSnapshots(uint initialDeposit, Snapshots memory snapshots) internal view returns (uint) {
        /*
        * Grab the sum 'S' from the epoch at which the stake was made. The FLR gain may span up to one scale change.
        * If it does, the second portion of the FLR gain is scaled by 1e9.
        * If the gain spans no scale change, the second portion will be 0.
        */
        uint128 epochSnapshot = snapshots.epoch;
        uint128 scaleSnapshot = snapshots.scale;
        uint S_Snapshot = snapshots.S;
        uint P_Snapshot = snapshots.P;

        uint firstPortion = epochToScaleToSum[epochSnapshot][scaleSnapshot] - S_Snapshot;
        uint secondPortion = epochToScaleToSum[epochSnapshot][scaleSnapshot + 1] / SCALE_FACTOR;

        uint FLRGain = initialDeposit * (firstPortion + secondPortion) / P_Snapshot / DECIMAL_PRECISION;

        return FLRGain;
    }

    /*
    * Calculate the Reward Token gain earned by a deposit since its last snapshots were taken.
    * Given by the formula:  Reward Token = d0 * (G - G(0))/P(0)
    * where G(0) and P(0) are the depositor's snapshots of the sum G and product P, respectively.
    * d0 is the last recorded deposit value.
    */
    function getDepositorRewardTokenGain(address _depositor) public view override returns (uint) {
        uint initialDeposit = deposits[_depositor].initialValue;
        if (initialDeposit == 0) {return 0;}

        address frontEndTag = deposits[_depositor].frontEndTag;

        /*
        * If not tagged with a front end, the depositor gets a 100% cut of what their deposit earned.
        * Otherwise, their cut of the deposit's earnings is equal to the kickbackRate, set by the front end through
        * which they made their deposit.
        */
        uint kickbackRate = frontEndTag == address(0) ? DECIMAL_PRECISION : frontEnds[frontEndTag].kickbackRate;

        Snapshots memory snapshots = depositSnapshots[_depositor];

        uint RewardTokenGain = kickbackRate * _getRewardTokenGainFromSnapshots(initialDeposit, snapshots) / DECIMAL_PRECISION;

        return RewardTokenGain;
    }

    /*
    * Return the Reward Token gain earned by the front end. Given by the formula:  E = D0 * (G - G(0))/P(0)
    * where G(0) and P(0) are the depositor's snapshots of the sum G and product P, respectively.
    *
    * D0 is the last recorded value of the front end's total tagged deposits.
    */
    function getFrontEndRewardTokenGain(address _frontEnd) public view override returns (uint) {
        uint frontEndStake = frontEndStakes[_frontEnd];
        if (frontEndStake == 0) { return 0; }

        uint kickbackRate = frontEnds[_frontEnd].kickbackRate;
        uint frontEndShare = uint(DECIMAL_PRECISION) - kickbackRate;

        Snapshots memory snapshots = frontEndSnapshots[_frontEnd];

        uint RewardTokenGain = frontEndShare * _getRewardTokenGainFromSnapshots(frontEndStake, snapshots) / DECIMAL_PRECISION;
        return RewardTokenGain;
    }

    function _getRewardTokenGainFromSnapshots(uint initialStake, Snapshots memory snapshots) internal view returns (uint) {
       /*
        * Grab the sum 'G' from the epoch at which the stake was made. The Reward Token gain may span up to one scale change.
        * If it does, the second portion of the Reward Token gain is scaled by 1e9.
        * If the gain spans no scale change, the second portion will be 0.
        */
        uint128 epochSnapshot = snapshots.epoch;
        uint128 scaleSnapshot = snapshots.scale;
        uint G_Snapshot = snapshots.G;
        uint P_Snapshot = snapshots.P;

        uint firstPortion = epochToScaleToG[epochSnapshot][scaleSnapshot] - G_Snapshot;
        uint secondPortion = epochToScaleToG[epochSnapshot][scaleSnapshot + 1] / SCALE_FACTOR;

        uint RewardTokenGain = initialStake * (firstPortion + secondPortion) / P_Snapshot / DECIMAL_PRECISION;

        return RewardTokenGain;
    }

    // --- Compounded deposit stake ---

    /*
    * Return the user's compounded deposit. Given by the formula:  d = d0 * P/P(0)
    * where P(0) is the depositor's snapshot of the product P, taken when they last updated their deposit.
    */
    function getCompoundedYUSDDeposit(address _depositor) public view override returns (uint) {
        uint initialDeposit = deposits[_depositor].initialValue;
        if (initialDeposit == 0) { return 0; }

        Snapshots memory snapshots = depositSnapshots[_depositor];

        uint compoundedDeposit = _getCompoundedStakeFromSnapshots(initialDeposit, snapshots);
        return compoundedDeposit;
    }

    /*
    * Return the front end's compounded stake. Given by the formula:  D = D0 * P/P(0)
    * where P(0) is the depositor's snapshot of the product P, taken at the last time
    * when one of the front end's tagged deposits updated their deposit.
    *
    * The front end's compounded stake is equal to the sum of its depositors' compounded deposits.
    */
    function getCompoundedFrontEndStake(address _frontEnd) public view override returns (uint) {
        uint frontEndStake = frontEndStakes[_frontEnd];
        if (frontEndStake == 0) { return 0; }

        Snapshots memory snapshots = frontEndSnapshots[_frontEnd];

        uint compoundedFrontEndStake = _getCompoundedStakeFromSnapshots(frontEndStake, snapshots);
        return compoundedFrontEndStake;
    }

    // Internal function, used to calculcate compounded deposits stakes.
    function _getCompoundedStakeFromSnapshots(
        uint initialStake,
        Snapshots memory snapshots
    )
        internal
        view
        returns (uint)
    {
        uint snapshot_P = snapshots.P;
        uint128 scaleSnapshot = snapshots.scale;
        uint128 epochSnapshot = snapshots.epoch;

        // If stake was made before a pool-emptying event, then it has been fully cancelled with debt -- so, return 0
        if (epochSnapshot < currentEpoch) { return 0; }

        uint compoundedStake;
        uint128 scaleDiff = currentScale - scaleSnapshot;

        /* Compute the compounded stake. If a scale change in P was made during the stake's lifetime,
        * account for it. If more than one scale change was made, then the stake has decreased by a factor of
        * at least 1e-9 -- so return 0.
        */
        if (scaleDiff == 0) {
            compoundedStake = initialStake * P / snapshot_P;
        } else if (scaleDiff == 1) {
            compoundedStake = initialStake * P / snapshot_P / SCALE_FACTOR;
        } else { // if scaleDiff >= 2
            compoundedStake = 0;
        }

        /*
        * If compounded deposit is less than a billionth of the initial deposit, return 0.
        *
        * NOTE: originally, this line was in place to stop rounding errors making the deposit too large. However, the error
        * corrections should ensure the error in P "favors the Pool", i.e. any given compounded deposit should slightly less
        * than it's theoretical value.
        *
        * Thus it's unclear whether this line is still really needed.
        */
        if (compoundedStake < initialStake / 1e9) {return 0;}

        return compoundedStake;
    }

    // --- Sender functions for YUSD deposit and FLR gains ---

    // Transfer the YUSD tokens from the user to the Stability Pool's address, and update its recorded YUSD
    function _sendYUSDtoStabilityPool(address _address, uint _amount) internal {
        yusdToken.sendToPool(_address, address(this), _amount);
        uint newTotalYUSDDeposits = totalYUSDDeposits + _amount;
        totalYUSDDeposits = newTotalYUSDDeposits;
        emit StabilityPoolYUSDBalanceUpdated(newTotalYUSDDeposits);
    }

    function _sendFLRGainToDepositor(uint _amount) internal {
        if (_amount == 0) {return;}
        uint newFLR = FLR - _amount;
        FLR = newFLR;
        emit StabilityPoolFLRBalanceUpdated(newFLR);
        emit FlareSent(msg.sender, _amount);

        (bool success, ) = msg.sender.call{ value: _amount }("");
        require(success, "StabilityPool: sending FLR failed");
    }

    // Send YUSD to user and decrease YUSD in Pool
    function _sendYUSDToDepositor(address _depositor, uint YUSDWithdrawal) internal {
        if (YUSDWithdrawal == 0) {return;}

        yusdToken.returnFromPool(address(this), _depositor, YUSDWithdrawal);
        _decreaseYUSD(YUSDWithdrawal);
    }


    // --- External Front End functions ---

    // Front end makes a one-time selection of kickback rate upon registering
    function registerFrontEnd(uint _kickbackRate) external override {
        _requireFrontEndNotRegistered(msg.sender);
        _requireUserHasNoDeposit(msg.sender);
        _requireValidKickbackRate(_kickbackRate);

        frontEnds[msg.sender].kickbackRate = _kickbackRate;
        frontEnds[msg.sender].registered = true;

        emit FrontEndRegistered(msg.sender, _kickbackRate);
    }

    // --- Stability Pool Deposit Functionality ---

    function _setFrontEndTag(address _depositor, address _frontEndTag) internal {
        deposits[_depositor].frontEndTag = _frontEndTag;
        emit FrontEndTagSet(_depositor, _frontEndTag);
    }

    function _updateDepositAndSnapshots(address _depositor, uint _newValue) internal {
        deposits[_depositor].initialValue = _newValue;

        if (_newValue == 0) {
            delete deposits[_depositor].frontEndTag;
            delete depositSnapshots[_depositor];
            emit DepositSnapshotUpdated(_depositor, 0, 0, 0);
            return;
        }
        uint128 currentScaleCached = currentScale;
        uint128 currentEpochCached = currentEpoch;
        uint currentP = P;

        // Get S and G for the current epoch and current scale
        uint currentS = epochToScaleToSum[currentEpochCached][currentScaleCached];
        uint currentG = epochToScaleToG[currentEpochCached][currentScaleCached];

        // Record new snapshots of the latest running product P, sum S, and sum G, for the depositor
        depositSnapshots[_depositor].P = currentP;
        depositSnapshots[_depositor].S = currentS;
        depositSnapshots[_depositor].G = currentG;
        depositSnapshots[_depositor].scale = currentScaleCached;
        depositSnapshots[_depositor].epoch = currentEpochCached;

        emit DepositSnapshotUpdated(_depositor, currentP, currentS, currentG);
    }

    function _updateFrontEndStakeAndSnapshots(address _frontEnd, uint _newValue) internal {
        frontEndStakes[_frontEnd] = _newValue;

        if (_newValue == 0) {
            delete frontEndSnapshots[_frontEnd];
            emit FrontEndSnapshotUpdated(_frontEnd, 0, 0);
            return;
        }

        uint128 currentScaleCached = currentScale;
        uint128 currentEpochCached = currentEpoch;
        uint currentP = P;

        // Get G for the current epoch and current scale
        uint currentG = epochToScaleToG[currentEpochCached][currentScaleCached];

        // Record new snapshots of the latest running product P and sum G for the front end
        frontEndSnapshots[_frontEnd].P = currentP;
        frontEndSnapshots[_frontEnd].G = currentG;
        frontEndSnapshots[_frontEnd].scale = currentScaleCached;
        frontEndSnapshots[_frontEnd].epoch = currentEpochCached;

        emit FrontEndSnapshotUpdated(_frontEnd, currentP, currentG);
    }

    function _payOutRewardTokenGains(address _depositor, address _frontEnd) internal {
        // Pay out front end's Reward Token gain
        if (_frontEnd != address(0)) {
            uint frontEndRewardTokenGain = getFrontEndRewardTokenGain(_frontEnd);
            rewardToken.transfer(_frontEnd, frontEndRewardTokenGain);
            emit RewardTokenPaidToFrontEnd(_frontEnd, frontEndRewardTokenGain);
        }

        // Pay out depositor's Reward Token gain
        uint depositorRewardTokenGain = getDepositorRewardTokenGain(_depositor);
        rewardToken.transfer(_depositor, depositorRewardTokenGain);
        emit RewardTokenPaidToDepositor(_depositor, depositorRewardTokenGain);
    }

    // --- 'require' functions ---

    function _requireCallerIsActivePool() internal view {
        require( msg.sender == address(activePool), "StabilityPool: Caller is not ActivePool");
    }

    function _requireCallerIsNestManager() internal view {
        require(msg.sender == address(nestManager), "StabilityPool: Caller is not NestManager");
    }

    function _requireNoUnderCollateralizedNests() internal {
        uint price = priceFeed.fetchPrice();
        address lowestNest = sortedNests.getLast();
        uint ICR = nestManager.getCurrentICR(lowestNest, price);
        require(ICR >= loansStableSettings.MCR(), "StabilityPool: Cannot withdraw while there are nests with ICR < MCR");
    }

    function _requireUserHasDeposit(uint _initialDeposit) internal pure {
        require(_initialDeposit > 0, 'StabilityPool: User must have a non-zero deposit');
    }

     function _requireUserHasNoDeposit(address _address) internal view {
        uint initialDeposit = deposits[_address].initialValue;
        require(initialDeposit == 0, 'StabilityPool: User must have no deposit');
    }

    function _requireNonZeroAmount(uint _amount) internal pure {
        require(_amount > 0, 'StabilityPool: Amount must be non-zero');
    }

    function _requireUserHasNest(address _depositor) internal view {
        require(nestManager.getNestStatus(_depositor) == 1, "StabilityPool: caller must have an active nest to withdraw FLRGain to");
    }

    function _requireUserHasFLRGain(address _depositor) internal view {
        uint FLRGain = getDepositorFLRGain(_depositor);
        require(FLRGain > 0, "StabilityPool: caller must have non-zero FLR Gain");
    }

    function _requireFrontEndNotRegistered(address _address) internal view {
        require(!frontEnds[_address].registered, "StabilityPool: must not already be a registered front end");
    }

     function _requireFrontEndIsRegisteredOrZero(address _address) internal view {
        require(frontEnds[_address].registered || _address == address(0),
            "StabilityPool: Tag must be a registered front end, or the zero address");
    }

    function  _requireValidKickbackRate(uint _kickbackRate) internal pure {
        require (_kickbackRate <= DECIMAL_PRECISION, "StabilityPool: Kickback rate must be in range [0,1]");
    }

    // --- Fallback function ---

    receive() external payable {
        _requireCallerIsActivePool();
        FLR += msg.value;
        StabilityPoolFLRBalanceUpdated(FLR);
    }
}
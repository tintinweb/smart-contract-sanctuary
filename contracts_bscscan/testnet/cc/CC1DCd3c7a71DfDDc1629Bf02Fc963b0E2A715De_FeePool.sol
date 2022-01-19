/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       FeePool.sol
version:    1.0
author:     Kevin Brown
date:       2018-10-15

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

The FeePool is a place for users to interact with the fees that
have been generated from the Synthetix system if they've helped
to create the economy.

Users stake Synthetix to create Synths. As Synth users transact,
a small fee is deducted from exchange transactions, which collects
in the fee pool. Fees are immediately converted to XDRs, a type
of reserve currency similar to SDRs used by the IMF:
https://www.imf.org/en/About/Factsheets/Sheets/2016/08/01/14/51/Special-Drawing-Right-SDR

Users are entitled to withdraw fees from periods that they participated
in fully, e.g. they have to stake before the period starts. They
can withdraw fees for the last 6 periods as a single lump sum.
Currently fee periods are 7 days long, meaning it's assumed
users will withdraw their fees approximately once a month. Fees
which are not withdrawn are redistributed to the whole pool,
enabling these non-claimed fees to go back to the rest of the commmunity.

Fees can be withdrawn in any synth currency.

-----------------------------------------------------------------
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Proxyable.sol";
import "./SelfDestructible.sol";
import "./SafeDecimalMath.sol";
import "./Synthetix.sol";
import "./ISynthetixEscrow.sol";
import "./ISynthetixState.sol";
import "./Synth.sol";
import "./FeePoolState.sol";
import "./FeePoolEternalStorage.sol";
import "./DelegateApprovals.sol";

contract FeePool is Proxyable, SelfDestructible, LimitedSetup {

    using SafeMath for uint;
    using SafeDecimalMath for uint;

    Synthetix public synthetix;
    ISynthetixState public synthetixState;
    ISynthetixEscrow public rewardEscrow;
    FeePoolEternalStorage public feePoolEternalStorage;

    // A percentage fee charged on each transfer.
    uint public transferFeeRate;

    // Transfer fee may not exceed 10%.
    uint public MAX_TRANSFER_FEE_RATE = SafeDecimalMath.unit() / 10;

    // A percentage fee charged on each exchange between currencies.
    uint public exchangeFeeRate;

    // Exchange fee may not exceed 10%.
    uint public MAX_EXCHANGE_FEE_RATE = SafeDecimalMath.unit() / 10;

    // The address with the authority to distribute fees.
    address public feeAuthority;

    // The address to the FeePoolState Contract.
    FeePoolState public feePoolState;

    // The address to the DelegateApproval contract.
    DelegateApprovals public delegates;

    // Where fees are pooled in XDRs.
    address public constant FEE_ADDRESS = 0xfeEFEEfeefEeFeefEEFEEfEeFeefEEFeeFEEFEeF;

    // This struct represents the issuance activity that's happened in a fee period.
    struct FeePeriod {
        uint feePeriodId;
        uint startingDebtIndex;
        uint startTime;
        uint feesToDistribute;
        uint feesClaimed;
        uint rewardsToDistribute;
        uint rewardsClaimed;
    }

    // The last 6 fee periods are all that you can claim from.
    // These are stored and managed from [0], such that [0] is always
    // the most recent fee period, and [3] is always the oldest fee
    // period that users can claim for.
    uint8 constant public FEE_PERIOD_LENGTH = 3;

    FeePeriod[FEE_PERIOD_LENGTH] public recentFeePeriods;

    // How long a fee period lasts at a minimum. It is required for the
    // fee authority to roll over the periods, so they are not guaranteed
    // to roll over at exactly this duration, but the contract enforces
    // that they cannot roll over any quicker than this duration.
    uint public feePeriodDuration = 1 weeks;
    // The fee period must be between 1 day and 60 days.
    uint public constant MIN_FEE_PERIOD_DURATION = 1 days;
    uint public constant MAX_FEE_PERIOD_DURATION = 60 days;

    // Users are unable to claim fees if their collateralisation ratio drifts out of target treshold
    uint public TARGET_THRESHOLD = (10 * SafeDecimalMath.unit()) / 100;

    /* ========== ETERNAL STORAGE CONSTANTS ========== */

    bytes32 constant LAST_FEE_WITHDRAWAL = "last_fee_withdrawal";

    constructor(
        address _proxy,
        address _owner,
        Synthetix _synthetix,
        FeePoolState _feePoolState,
        FeePoolEternalStorage _feePoolEternalStorage,
        ISynthetixState _synthetixState,
        ISynthetixEscrow _rewardEscrow,
        address _feeAuthority,
        uint _transferFeeRate,
        uint _exchangeFeeRate)
        SelfDestructible(_owner)
        Proxyable(payable(_proxy))
        LimitedSetup(3 weeks)
    {
        // Constructed fee rates should respect the maximum fee rates.
        require(_transferFeeRate <= MAX_TRANSFER_FEE_RATE, "Constructed transfer fee rate should respect the maximum fee rate");
        require(_exchangeFeeRate <= MAX_EXCHANGE_FEE_RATE, "Constructed exchange fee rate should respect the maximum fee rate");

        synthetix = _synthetix;
        feePoolState = _feePoolState;
        feePoolEternalStorage = _feePoolEternalStorage;
        rewardEscrow = _rewardEscrow;
        synthetixState = _synthetixState;
        feeAuthority = _feeAuthority;
        transferFeeRate = _transferFeeRate;
        exchangeFeeRate = _exchangeFeeRate;

        // Set our initial fee period
        recentFeePeriods[0].feePeriodId = 1;
        recentFeePeriods[0].startTime = block.timestamp;
    }

    /**
     * @notice Logs an accounts issuance data per fee period
     * @param account Message.Senders account address
     * @param debtRatio Debt percentage this account has locked after minting or burning their synth
     * @param debtEntryIndex The index in the global debt ledger. synthetix.synthetixState().issuanceData(account)
     * @dev onlySynthetix to call me on synthetix.issue() & synthetix.burn() calls to store the locked SNX
     * per fee period so we know to allocate the correct proportions of fees and rewards per period
     */
    function appendAccountIssuanceRecord(address account, uint debtRatio, uint debtEntryIndex)
        external
        onlySynthetix
    {
        feePoolState.appendAccountIssuanceRecord(account, debtRatio, debtEntryIndex, recentFeePeriods[0].startingDebtIndex);

        emitIssuanceDebtRatioEntry(account, debtRatio, debtEntryIndex, recentFeePeriods[0].startingDebtIndex);
    }

    /**
     * @notice Set the exchange fee, anywhere within the range 0-10%.
     * @dev The fee rate is in decimal format, with UNIT being the value of 100%.
     */
    function setExchangeFeeRate(uint _exchangeFeeRate)
        external
        optionalProxy_onlyOwner
    {
        exchangeFeeRate = _exchangeFeeRate;
    }

    /**
     * @notice Set the transfer fee, anywhere within the range 0-10%.
     * @dev The fee rate is in decimal format, with UNIT being the value of 100%.
     */
    function setTransferFeeRate(uint _transferFeeRate)
        external
        optionalProxy_onlyOwner
    {
        require(_transferFeeRate <= MAX_TRANSFER_FEE_RATE, "Transfer fee rate must be below MAX_TRANSFER_FEE_RATE");

        transferFeeRate = _transferFeeRate;
    }

    /**
     * @notice Set the address of the user/contract responsible for collecting or
     * distributing fees.
     */
    function setFeeAuthority(address _feeAuthority)
        external
        optionalProxy_onlyOwner
    {
        feeAuthority = _feeAuthority;
    }

    /**
     * @notice Set the address of the contract for feePool state
     */
    function setFeePoolState(FeePoolState _feePoolState)
        external
        optionalProxy_onlyOwner
    {
        feePoolState = _feePoolState;
    }

    /**
     * @notice Set the address of the contract for delegate approvals
     */
    function setDelegateApprovals(DelegateApprovals _delegates)
        external
        optionalProxy_onlyOwner
    {
        delegates = _delegates;
    }

    /**
     * @notice Set the fee period duration
     */
    function setFeePeriodDuration(uint _feePeriodDuration)
        external
        optionalProxy_onlyOwner
    {
        require(_feePeriodDuration >= MIN_FEE_PERIOD_DURATION, "New fee period cannot be less than minimum fee period duration");
        require(_feePeriodDuration <= MAX_FEE_PERIOD_DURATION, "New fee period cannot be greater than maximum fee period duration");

        feePeriodDuration = _feePeriodDuration;

        emitFeePeriodDurationUpdated(_feePeriodDuration);
    }

    /**
     * @notice Set the synthetix contract
     */
    function setSynthetix(Synthetix _synthetix)
        external
        optionalProxy_onlyOwner
    {
        require(address(_synthetix) != address(0), "New Synthetix must be non-zero");

        synthetix = _synthetix;
    }

    function setTargetThreshold(uint _percent)
        external
        optionalProxy_onlyOwner
    {
        require(_percent >= 0, "Threshold should be positive");
        TARGET_THRESHOLD = (_percent * SafeDecimalMath.unit()) / 100;
    }

    /**
     * @notice The Synthetix contract informs us when fees are paid.
     */
    function feePaid(bytes4 currencyKey, uint amount)
        external
        onlySynthetix
    {
        uint xdrAmount;

        if (currencyKey != "XDR") {
            xdrAmount = synthetix.effectiveValue(currencyKey, amount, "XDR");
        } else {
            xdrAmount = amount;
        }

        // Keep track of in XDRs in our fee pool.
        recentFeePeriods[0].feesToDistribute = recentFeePeriods[0].feesToDistribute.add(xdrAmount);
    }

    /**
     * @notice The Synthetix contract informs us when SNX Rewards are minted to RewardEscrow to be claimed.
     */
    function rewardsMinted(uint amount)
        external
        onlySynthetix
    {
        // Add the newly minted SNX rewards on top of the rolling unclaimed amount
        recentFeePeriods[0].rewardsToDistribute = recentFeePeriods[0].rewardsToDistribute.add(amount);
    }

    /**
     * @notice Close the current fee period and start a new one. Only callable by the fee authority.
     */
    function closeCurrentFeePeriod()
        external
        optionalProxy_onlyFeeAuthority
    {
        require(recentFeePeriods[0].startTime <= (block.timestamp - feePeriodDuration), "It is too early to close the current fee period");

        FeePeriod memory secondLastFeePeriod = recentFeePeriods[FEE_PERIOD_LENGTH - 2];
        FeePeriod memory lastFeePeriod = recentFeePeriods[FEE_PERIOD_LENGTH - 1];

        // Any unclaimed fees from the last period in the array roll back one period.
        // Because of the subtraction here, they're effectively proportionally redistributed to those who
        // have already claimed from the old period, available in the new period.
        // The subtraction is important so we don't create a ticking time bomb of an ever growing
        // number of fees that can never decrease and will eventually overflow at the end of the fee pool.
        recentFeePeriods[FEE_PERIOD_LENGTH - 2].feesToDistribute = lastFeePeriod.feesToDistribute
            .sub(lastFeePeriod.feesClaimed)
            .add(secondLastFeePeriod.feesToDistribute);
        recentFeePeriods[FEE_PERIOD_LENGTH - 2].rewardsToDistribute = lastFeePeriod.rewardsToDistribute
            .sub(lastFeePeriod.rewardsClaimed)
            .add(secondLastFeePeriod.rewardsToDistribute);

        // Shift the previous fee periods across to make room for the new one.
        // Condition checks for overflow when uint subtracts one from zero
        // Could be written with int instead of uint, but then we have to convert everywhere
        // so it felt better from a gas perspective to just change the condition to check
        // for overflow after subtracting one from zero.
        for (uint i = FEE_PERIOD_LENGTH - 2; i < FEE_PERIOD_LENGTH; i--) {
            uint next = i + 1;
            recentFeePeriods[next].feePeriodId = recentFeePeriods[i].feePeriodId;
            recentFeePeriods[next].startingDebtIndex = recentFeePeriods[i].startingDebtIndex;
            recentFeePeriods[next].startTime = recentFeePeriods[i].startTime;
            recentFeePeriods[next].feesToDistribute = recentFeePeriods[i].feesToDistribute;
            recentFeePeriods[next].feesClaimed = recentFeePeriods[i].feesClaimed;
            recentFeePeriods[next].rewardsToDistribute = recentFeePeriods[i].rewardsToDistribute;
            recentFeePeriods[next].rewardsClaimed = recentFeePeriods[i].rewardsClaimed;
        }

        // Clear the first element of the array to make sure we don't have any stale values.
        delete recentFeePeriods[0];

        // Open up the new fee period. Take a snapshot of the total value of the system.
        // Increment periodId from the recent closed period feePeriodId
        recentFeePeriods[0].feePeriodId = recentFeePeriods[1].feePeriodId.add(1);
        recentFeePeriods[0].startingDebtIndex = synthetixState.debtLedgerLength();
        recentFeePeriods[0].startTime = block.timestamp;

        emitFeePeriodClosed(recentFeePeriods[1].feePeriodId);
    }

    /**
    * @notice Claim fees for last period when available or not already withdrawn.
    * @param currencyKey Synth currency you wish to receive the fees in.
    */
    function claimFees(bytes4 currencyKey)
        external
        optionalProxy
        returns (bool)
    {
        return _claimFees(messageSender, currencyKey);
    }

    function claimOnBehalf(address claimingForAddress, bytes4 currencyKey)
        external
        optionalProxy
        returns (bool)
    {
        require(delegates.approval(claimingForAddress, messageSender), "Not approved to claim on behalf this address");

        return _claimFees(claimingForAddress, currencyKey);
    }

    function _claimFees(address claimingAddress, bytes4 currencyKey)
        internal
        returns (bool)
    {
        uint rewardsPaid;
        uint feesPaid;
        uint availableFees;
        uint availableRewards;

        // Address wont be able to claim fees if it is to far below the target c-ratio.
        // It will need to burn synths then try claiming again.
        require(feesClaimable(claimingAddress), "C-Ratio below penalty threshold");

        // Get the claimingAddress available fees and rewards
        (availableFees, availableRewards) = feesAvailable(claimingAddress, "XDR");

        require(availableFees > 0 || availableRewards > 0, "No fees or rewards available for period, or fees already claimed");

        // Record the address has claimed for this period
        _setLastFeeWithdrawal(claimingAddress, recentFeePeriods[1].feePeriodId);

        if (availableFees > 0) {
            // Record the fee payment in our recentFeePeriods
            feesPaid = _recordFeePayment(availableFees);

            // Send them their fees
            _payFees(claimingAddress, feesPaid, currencyKey);
        }

        if (availableRewards > 0) {
            // Record the reward payment in our recentFeePeriods
            rewardsPaid = _recordRewardPayment(availableRewards);

            // Send them their rewards
            _payRewards(claimingAddress, rewardsPaid);
        }

        emitFeesClaimed(claimingAddress, feesPaid, rewardsPaid);

        return true;
    }

    function importFeePeriod(
        uint feePeriodIndex, uint feePeriodId, uint startingDebtIndex, uint startTime,
        uint feesToDistribute, uint feesClaimed, uint rewardsToDistribute, uint rewardsClaimed)
        public
        optionalProxy_onlyOwner
        onlyDuringSetup
    {
        recentFeePeriods[feePeriodIndex].feePeriodId = feePeriodId;
        recentFeePeriods[feePeriodIndex].startingDebtIndex = startingDebtIndex;
        recentFeePeriods[feePeriodIndex].startTime = startTime;
        recentFeePeriods[feePeriodIndex].feesToDistribute = feesToDistribute;
        recentFeePeriods[feePeriodIndex].feesClaimed = feesClaimed;
        recentFeePeriods[feePeriodIndex].rewardsToDistribute = rewardsToDistribute;
        recentFeePeriods[feePeriodIndex].rewardsClaimed = rewardsClaimed;
    }

    function approveClaimOnBehalf(address account)
        public
        optionalProxy
    {
        require(address(delegates) != address(0), "Delegates Approval destination missing");
        require(account != address(0), "Can't delegate to address(0)");
        delegates.setApproval(messageSender, account);
    }

    function removeClaimOnBehalf(address account)
        public
        optionalProxy
    {
        require(address(delegates) != address(0), "Delegates Approval destination missing");
        delegates.withdrawApproval(messageSender, account);
    }

    /**
     * @notice Record the fee payment in our recentFeePeriods.
     * @param xdrAmount The amount of fees priced in XDRs.
     */
    function _recordFeePayment(uint xdrAmount)
        internal
        returns (uint)
    {
        // Don't assign to the parameter
        uint remainingToAllocate = xdrAmount;

        uint feesPaid;
        // Start at the oldest period and record the amount, moving to newer periods
        // until we've exhausted the amount.
        // The condition checks for overflow because we're going to 0 with an unsigned int.
        for (uint i = FEE_PERIOD_LENGTH - 1; i < FEE_PERIOD_LENGTH; i--) {
            uint delta = recentFeePeriods[i].feesToDistribute.sub(recentFeePeriods[i].feesClaimed);

            if (delta > 0) {
                // Take the smaller of the amount left to claim in the period and the amount we need to allocate
                uint amountInPeriod = delta < remainingToAllocate ? delta : remainingToAllocate;

                recentFeePeriods[i].feesClaimed = recentFeePeriods[i].feesClaimed.add(amountInPeriod);
                remainingToAllocate = remainingToAllocate.sub(amountInPeriod);
                feesPaid = feesPaid.add(amountInPeriod);

                // No need to continue iterating if we've recorded the whole amount;
                if (remainingToAllocate == 0) return feesPaid;

                // We've exhausted feePeriods to distribute and no fees remain in last period
                // User last to claim would in this scenario have their remainder slashed
                if (i == 0 && remainingToAllocate > 0) {
                    remainingToAllocate = 0;
                }
            }
        }

        return feesPaid;
    }

    /**
     * @notice Record the reward payment in our recentFeePeriods.
     * @param snxAmount The amount of SNX tokens.
     */
    function _recordRewardPayment(uint snxAmount)
        internal
        returns (uint)
    {
        // Don't assign to the parameter
        uint remainingToAllocate = snxAmount;

        uint rewardPaid;

        // Start at the oldest period and record the amount, moving to newer periods
        // until we've exhausted the amount.
        // The condition checks for overflow because we're going to 0 with an unsigned int.
        for (uint i = FEE_PERIOD_LENGTH - 1; i < FEE_PERIOD_LENGTH; i--) {
            uint toDistribute = recentFeePeriods[i].rewardsToDistribute.sub(recentFeePeriods[i].rewardsClaimed);

            if (toDistribute > 0) {
                // Take the smaller of the amount left to claim in the period and the amount we need to allocate
                uint amountInPeriod = toDistribute < remainingToAllocate ? toDistribute : remainingToAllocate;

                recentFeePeriods[i].rewardsClaimed = recentFeePeriods[i].rewardsClaimed.add(amountInPeriod);
                remainingToAllocate = remainingToAllocate.sub(amountInPeriod);
                rewardPaid = rewardPaid.add(amountInPeriod);

                // No need to continue iterating if we've recorded the whole amount;
                if (remainingToAllocate == 0) return rewardPaid;

                // We've exhausted feePeriods to distribute and no rewards remain in last period
                // User last to claim would in this scenario have their remainder slashed
                // due to rounding up of PreciseDecimal
                if (i == 0 && remainingToAllocate > 0) {
                    remainingToAllocate = 0;
                }
            }
        }
        return rewardPaid;
    }

    /**
    * @notice Send the fees to claiming address.
    * @param account The address to send the fees to.
    * @param xdrAmount The amount of fees priced in XDRs.
    * @param destinationCurrencyKey The synth currency the user wishes to receive their fees in (convert to this currency).
    */
    function _payFees(address account, uint xdrAmount, bytes4 destinationCurrencyKey)
        internal
        notFeeAddress(account)
    {
        require(account != address(0), "Account can't be 0");
        require(account != address(this), "Can't send fees to fee pool");
        require(account != address(proxy), "Can't send fees to proxy");
        require(account != address(synthetix), "Can't send fees to synthetix");

        Synth xdrSynth = synthetix.synths("XDR");
        Synth destinationSynth = synthetix.synths(destinationCurrencyKey);

        // Note: We don't need to check the fee pool balance as the burn() below will do a safe subtraction which requires
        // the subtraction to not overflow, which would happen if the balance is not sufficient.

        // Burn the source amount
        xdrSynth.burn(FEE_ADDRESS, xdrAmount);

        // How much should they get in the destination currency?
        uint destinationAmount = synthetix.effectiveValue("XDR", xdrAmount, destinationCurrencyKey);

        // There's no fee on withdrawing fees, as that'd be way too meta.

        // Mint their new synths
        destinationSynth.issue(account, destinationAmount);

        // Nothing changes as far as issuance data goes because the total value in the system hasn't changed.

        // Call the ERC223 transfer callback if needed
        destinationSynth.triggerTokenFallbackIfNeeded(FEE_ADDRESS, account, destinationAmount);
    }

    /**
    * @notice Send the rewards to claiming address - will be locked in rewardEscrow.
    * @param account The address to send the fees to.
    * @param snxAmount The amount of SNX.
    */
    function _payRewards(address account, uint snxAmount)
        internal
        notFeeAddress(account)
    {
        require(account != address(0), "Account can't be 0");
        require(account != address(this), "Can't send rewards to fee pool");
        require(account != address(proxy), "Can't send rewards to proxy");
        require(account != address(synthetix), "Can't send rewards to synthetix");

        // Record vesting entry for claiming address and amount
        // SNX already minted to rewardEscrow balance
        rewardEscrow.appendVestingEntry(account, snxAmount);
    }

    /**
     * @notice Calculate the Fee charged on top of a value being sent
     * @return Return the fee charged
     */
    function transferFeeIncurred(uint value)
        public
        view
        returns (uint)
    {
        return value.multiplyDecimal(transferFeeRate);

        // Transfers less than the reciprocal of transferFeeRate should be completely eaten up by fees.
        // This is on the basis that transfers less than this value will result in a nil fee.
        // Probably too insignificant to worry about, but the following code will achieve it.
        //      if (fee == 0 && transferFeeRate != 0) {
        //          return _value;
        //      }
        //      return fee;
    }

    /**
     * @notice The value that you would need to send so that the recipient receives
     * a specified value.
     * @param value The value you want the recipient to receive
     */
    function transferredAmountToReceive(uint value)
        external
        view
        returns (uint)
    {
        return value.add(transferFeeIncurred(value));
    }

    /**
     * @notice The amount the recipient will receive if you send a certain number of tokens.
     * @param value The amount of tokens you intend to send.
     */
    function amountReceivedFromTransfer(uint value)
        external
        view
        returns (uint)
    {
        return value.divideDecimal(transferFeeRate.add(SafeDecimalMath.unit()));
    }

    /**
     * @notice Calculate the fee charged on top of a value being sent via an exchange
     * @return Return the fee charged
     */
    function exchangeFeeIncurred(uint value)
        public
        view
        returns (uint)
    {
        return value.multiplyDecimal(exchangeFeeRate);

        // Exchanges less than the reciprocal of exchangeFeeRate should be completely eaten up by fees.
        // This is on the basis that exchanges less than this value will result in a nil fee.
        // Probably too insignificant to worry about, but the following code will achieve it.
        //      if (fee == 0 && exchangeFeeRate != 0) {
        //          return _value;
        //      }
        //      return fee;
    }

    /**
     * @notice The value that you would need to get after currency exchange so that the recipient receives
     * a specified value.
     * @param value The value you want the recipient to receive
     */
    function exchangedAmountToReceive(uint value)
        external
        view
        returns (uint)
    {
        return value.add(exchangeFeeIncurred(value));
    }

    /**
     * @notice The amount the recipient will receive if you are performing an exchange and the
     * destination currency will be worth a certain number of tokens.
     * @param value The amount of destination currency tokens they received after the exchange.
     */
    function amountReceivedFromExchange(uint value)
        external
        view
        returns (uint)
    {
        return value.multiplyDecimal(SafeDecimalMath.unit().sub(exchangeFeeRate));
    }

    /**
     * @notice The total fees available in the system to be withdrawn, priced in currencyKey currency
     * @param currencyKey The currency you want to price the fees in
     */
    function totalFeesAvailable(bytes4 currencyKey)
        external
        view
        returns (uint)
    {
        uint totalFees = 0;

        // Fees in fee period [0] are not yet available for withdrawal
        for (uint i = 1; i < FEE_PERIOD_LENGTH; i++) {
            totalFees = totalFees.add(recentFeePeriods[i].feesToDistribute);
            totalFees = totalFees.sub(recentFeePeriods[i].feesClaimed);
        }

        return synthetix.effectiveValue("XDR", totalFees, currencyKey);
    }

    /**
     * @notice The total SNX rewards available in the system to be withdrawn
     */
    function totalRewardsAvailable()
        external
        view
        returns (uint)
    {
        uint totalRewards = 0;

        // Rewards in fee period [0] are not yet available for withdrawal
        for (uint i = 1; i < FEE_PERIOD_LENGTH; i++) {
            totalRewards = totalRewards.add(recentFeePeriods[i].rewardsToDistribute);
            totalRewards = totalRewards.sub(recentFeePeriods[i].rewardsClaimed);
        }

        return totalRewards;
    }

    /**
     * @notice The fees available to be withdrawn by a specific account, priced in currencyKey currency
     * @dev Returns two amounts, one for fees and one for SNX rewards
     * @param currencyKey The currency you want to price the fees in
     */
    function feesAvailable(address account, bytes4 currencyKey)
        public
        view
        returns (uint, uint)
    {
        // Add up the fees
        uint[2][FEE_PERIOD_LENGTH] memory userFees = feesByPeriod(account);

        uint totalFees = 0;
        uint totalRewards = 0;

        // Fees & Rewards in fee period [0] are not yet available for withdrawal
        for (uint i = 1; i < FEE_PERIOD_LENGTH; i++) {
            totalFees = totalFees.add(userFees[i][0]);
            totalRewards = totalRewards.add(userFees[i][1]);
        }

        // And convert totalFees to their desired currency
        // Return totalRewards as is in SNX amount
        return (
            synthetix.effectiveValue("XDR", totalFees, currencyKey),
            totalRewards
        );
    }

    /**
     * @notice Check if a particular address is able to claim fees right now
     * @param account The address you want to query for
     */
    function feesClaimable(address account)
        public
        view
        returns (bool)
    {
        // Threshold is calculated from ratio % above the target ratio (issuanceRatio).
        //  0  <  10%:   Claimable
        // 10% > above:  Unable to claim
        uint ratio = synthetix.collateralisationRatio(account);
        uint targetRatio = synthetix.synthetixState().issuanceRatio();

        // Claimable if collateral ratio below target ratio
        if (ratio < targetRatio) {
            return true;
        }

        // Calculate the threshold for collateral ratio before fees can't be claimed.
        uint ratio_threshold = targetRatio.multiplyDecimal(SafeDecimalMath.unit().add(TARGET_THRESHOLD));

        // Not claimable if collateral ratio above threshold
        if (ratio > ratio_threshold) {
            return false;
        }

        return true;
    }

    /**
     * @notice Calculates fees by period for an account, priced in XDRs
     * @param account The address you want to query the fees for
     */
    function feesByPeriod(address account)
        public
        view
        returns (uint[2][FEE_PERIOD_LENGTH] memory results)
    {
        // What's the user's debt entry index and the debt they owe to the system at current feePeriod
        uint userOwnershipPercentage;
        uint debtEntryIndex;
        (userOwnershipPercentage, debtEntryIndex) = feePoolState.getAccountsDebtEntry(account, 0);

        uint[2][FEE_PERIOD_LENGTH] memory nullResults;

        // If they don't have any debt ownership and they haven't minted, they don't have any fees
        if (debtEntryIndex == 0 && userOwnershipPercentage == 0) return nullResults;

        // If there are no XDR synths, then they don't have any fees
        if (synthetix.totalIssuedSynths("XDR") == 0) return nullResults;

        // The [0] fee period is not yet ready to claim, but it is a fee period that they can have
        // fees owing for, so we need to report on it anyway.
        uint feesFromPeriod;
        uint rewardsFromPeriod;
        (feesFromPeriod, rewardsFromPeriod) = _feesAndRewardsFromPeriod(0, userOwnershipPercentage, debtEntryIndex);

        results[0][0] = feesFromPeriod;
        results[0][1] = rewardsFromPeriod;

        // Go through our fee periods from the oldest feePeriod[FEE_PERIOD_LENGTH - 1] and figure out what we owe them.
        // Condition checks for periods > 0
        for (uint i = FEE_PERIOD_LENGTH - 1; i > 0; i--) {
            uint next = i - 1;
            FeePeriod memory nextPeriod = recentFeePeriods[next];

            // We can skip period if no debt minted during period
            if (nextPeriod.startingDebtIndex > 0 &&
            getLastFeeWithdrawal(account) < recentFeePeriods[i].feePeriodId) {

                // We calculate a feePeriod's closingDebtIndex by looking at the next feePeriod's startingDebtIndex
                // we can use the most recent issuanceData[0] for the current feePeriod
                // else find the applicableIssuanceData for the feePeriod based on the StartingDebtIndex of the period
                uint closingDebtIndex = nextPeriod.startingDebtIndex.sub(1);

                // Gas optimisation - to reuse debtEntryIndex if found new applicable one
                // if applicable is 0,0 (none found) we keep most recent one from issuanceData[0]
                // return if userOwnershipPercentage = 0)
                (userOwnershipPercentage, debtEntryIndex) = feePoolState.applicableIssuanceData(account, closingDebtIndex);

                (feesFromPeriod, rewardsFromPeriod) = _feesAndRewardsFromPeriod(i, userOwnershipPercentage, debtEntryIndex);

                results[i][0] = feesFromPeriod;
                results[i][1] = rewardsFromPeriod;
            }
        }
    }

    /**
     * @notice ownershipPercentage is a high precision decimals uint based on
     * wallet's debtPercentage. Gives a precise amount of the feesToDistribute
     * for fees in the period. Precision factor is removed before results are
     * returned.
     */
    function _feesAndRewardsFromPeriod(uint period, uint ownershipPercentage, uint debtEntryIndex)
        internal
        view
        returns (uint, uint)
    {
        // If it's zero, they haven't issued, and they have no fees OR rewards.
        if (ownershipPercentage == 0) return (0, 0);

        uint debtOwnershipForPeriod = ownershipPercentage;

        // If period has closed we want to calculate debtPercentage for the period
        if (period > 0) {
            uint closingDebtIndex = recentFeePeriods[period - 1].startingDebtIndex.sub(1);
            debtOwnershipForPeriod = _effectiveDebtRatioForPeriod(closingDebtIndex, ownershipPercentage, debtEntryIndex);
        }

        // Calculate their percentage of the fees / rewards in this period
        // This is a high precision integer.
        uint feesFromPeriod = recentFeePeriods[period].feesToDistribute
            .multiplyDecimal(debtOwnershipForPeriod);

        uint rewardsFromPeriod = recentFeePeriods[period].rewardsToDistribute
            .multiplyDecimal(debtOwnershipForPeriod);

        return (
            feesFromPeriod.preciseDecimalToDecimal(),
            rewardsFromPeriod.preciseDecimalToDecimal()
        );
    }

    function _effectiveDebtRatioForPeriod(uint closingDebtIndex, uint ownershipPercentage, uint debtEntryIndex)
        internal
        view
        returns (uint)
    {
        // Condition to check if debtLedger[] has value otherwise return 0
        if (closingDebtIndex > synthetixState.debtLedgerLength()) return 0;

        // Figure out their global debt percentage delta at end of fee Period.
        // This is a high precision integer.
        uint feePeriodDebtOwnership = synthetixState.debtLedger(closingDebtIndex)
            .divideDecimalRoundPrecise(synthetixState.debtLedger(debtEntryIndex))
            .multiplyDecimalRoundPrecise(ownershipPercentage);

        return feePeriodDebtOwnership;
    }

    function effectiveDebtRatioForPeriod(address account, uint period)
        external
        view
        returns (uint)
    {
        require(period != 0, "Current period has not closed yet");
        require(period < FEE_PERIOD_LENGTH, "Period exceeds the FEE_PERIOD_LENGTH");

        // No debt minted during period as next period starts at 0
        if (recentFeePeriods[period - 1].startingDebtIndex == 0) return 0;

        uint closingDebtIndex = recentFeePeriods[period - 1].startingDebtIndex.sub(1);

        uint ownershipPercentage;
        uint debtEntryIndex;
        (ownershipPercentage, debtEntryIndex) = feePoolState.applicableIssuanceData(account, closingDebtIndex);

        // internal function will check closingDebtIndex has corresponding debtLedger entry
        return _effectiveDebtRatioForPeriod(closingDebtIndex, ownershipPercentage, debtEntryIndex);
    }

    /**
     * @notice Get the feePeriodID of the last claim this account made
     * @param _claimingAddress account to check the last fee period ID claim for
     * @return uint of the feePeriodID this account last claimed
     */
    function getLastFeeWithdrawal(address _claimingAddress)
        public
        view
        returns (uint)
    {
        return feePoolEternalStorage.getUIntValue(keccak256(abi.encodePacked(LAST_FEE_WITHDRAWAL, _claimingAddress)));
    }

    /**
    * @notice Calculate the collateral ratio before user is blocked from claiming.
    */
    function getPenaltyThresholdRatio()
        public
        view
        returns (uint)
    {
        uint targetRatio = synthetix.synthetixState().issuanceRatio();

        return targetRatio.multiplyDecimal(SafeDecimalMath.unit().add(TARGET_THRESHOLD));
    }

    /* ========== Modifiers ========== */

    /**
     * @notice Set the feePeriodID of the last claim this account made
     * @param _claimingAddress account to set the last feePeriodID claim for
     * @param _feePeriodID the feePeriodID this account claimed fees for
     */
    function _setLastFeeWithdrawal(address _claimingAddress, uint _feePeriodID)
        internal
    {
        feePoolEternalStorage.setUIntValue(keccak256(abi.encodePacked(LAST_FEE_WITHDRAWAL, _claimingAddress)), _feePeriodID);
    }

    modifier optionalProxy_onlyFeeAuthority
    {
        if (Proxy(payable(msg.sender)) != proxy) {
            messageSender = msg.sender;
        }
        require(msg.sender == feeAuthority, "Only the fee authority can perform this action");
        _;
    }

    modifier onlySynthetix
    {
        require(msg.sender == address(synthetix), "Only the synthetix contract can perform this action");
        _;
    }

    modifier notFeeAddress(address account) {
        require(account != FEE_ADDRESS, "Fee address not allowed");
        _;
    }

    /* ========== Proxy Events ========== */
    function addressToBytes32(address input) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(input)));
    }

    event IssuanceDebtRatioEntry(address indexed account, uint debtRatio, uint debtEntryIndex, uint feePeriodStartingDebtIndex);
    bytes32 constant ISSUANCEDEBTRATIOENTRY_SIG = keccak256("IssuanceDebtRatioEntry(address,uint256,uint256,uint256)");
    function emitIssuanceDebtRatioEntry(address account, uint debtRatio, uint debtEntryIndex, uint feePeriodStartingDebtIndex) internal {
        proxy._emit(abi.encode(debtRatio, debtEntryIndex, feePeriodStartingDebtIndex), 2, ISSUANCEDEBTRATIOENTRY_SIG, addressToBytes32(account), 0, 0);
    }

    event TransferFeeUpdated(uint newFeeRate);
    bytes32 constant TRANSFERFEEUPDATED_SIG = keccak256("TransferFeeUpdated(uint256)");
    function emitTransferFeeUpdated(uint newFeeRate) internal {
        proxy._emit(abi.encode(newFeeRate), 1, TRANSFERFEEUPDATED_SIG, 0, 0, 0);
    }

    event ExchangeFeeUpdated(uint newFeeRate);
    bytes32 constant EXCHANGEFEEUPDATED_SIG = keccak256("ExchangeFeeUpdated(uint256)");
    function emitExchangeFeeUpdated(uint newFeeRate) internal {
        proxy._emit(abi.encode(newFeeRate), 1, EXCHANGEFEEUPDATED_SIG, 0, 0, 0);
    }

    event FeePeriodDurationUpdated(uint newFeePeriodDuration);
    bytes32 constant FEEPERIODDURATIONUPDATED_SIG = keccak256("FeePeriodDurationUpdated(uint256)");
    function emitFeePeriodDurationUpdated(uint newFeePeriodDuration) internal {
        proxy._emit(abi.encode(newFeePeriodDuration), 1, FEEPERIODDURATIONUPDATED_SIG, 0, 0, 0);
    }

    event FeePeriodClosed(uint feePeriodId);
    bytes32 constant FEEPERIODCLOSED_SIG = keccak256("FeePeriodClosed(uint256)");
    function emitFeePeriodClosed(uint feePeriodId) internal {
        proxy._emit(abi.encode(feePeriodId), 1, FEEPERIODCLOSED_SIG, 0, 0, 0);
    }

    event FeesClaimed(address account, uint xdrAmount, uint snxRewards);
    bytes32 constant FEESCLAIMED_SIG = keccak256("FeesClaimed(address,uint256,uint256)");
    function emitFeesClaimed(address account, uint xdrAmount, uint snxRewards) internal {
        proxy._emit(abi.encode(account, xdrAmount, snxRewards), 1, FEESCLAIMED_SIG, 0, 0, 0);
    }
}

/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       Proxyable.sol
version:    1.1
author:     Anton Jurisevic

date:       2018-05-15

checked:    Mike Spain
approved:   Samuel Brooks

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

A proxyable contract that works hand in hand with the Proxy contract
to allow for anyone to interact with the underlying contract both
directly and through the proxy.

-----------------------------------------------------------------
*/


//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Owned.sol";
import "./Proxy.sol";

// This contract should be treated like an abstract contract
abstract contract Proxyable is Owned {
    /* The proxy this contract exists behind. */
    Proxy public proxy;

    /* The caller of the proxy, passed through to this contract.
     * Note that every function using this member must apply the onlyProxy or
     * optionalProxy modifiers, otherwise their invocations can use stale values. */ 
    address messageSender; 

    constructor(address payable _proxy)
    {
        // This contract is abstract, and thus cannot be instantiated directly
        require(owner != address(0), "Owner must be set");

        proxy = Proxy(_proxy);
        emit ProxyUpdated(_proxy);
    }

    function setProxy(address payable _proxy)
        external
        onlyOwner
    {
        proxy = Proxy(_proxy);
        emit ProxyUpdated(_proxy);
    }

    function setMessageSender(address sender)
        external
        onlyProxy
    {
        messageSender = sender;
    }

    modifier onlyProxy {
        require(Proxy(payable(msg.sender)) == proxy, "Only the proxy can call this function");
        _;
    }

    modifier optionalProxy
    {
        if (Proxy(payable(msg.sender)) != proxy) {
            messageSender = msg.sender;
        }
        _;
    }

    modifier optionalProxy_onlyOwner
    {
        if (Proxy(payable(msg.sender)) != proxy) {
            messageSender = msg.sender;
        }
        require(messageSender == owner, "This action can only be performed by the owner");
        _;
    }

    event ProxyUpdated(address proxyAddress);
}

/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       SelfDestructible.sol
version:    1.2
author:     Anton Jurisevic

date:       2018-05-29

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

This contract allows an inheriting contract to be destroyed after
its owner indicates an intention and then waits for a period
without changing their mind. All ether contained in the contract
is forwarded to a nominated beneficiary upon destruction.

-----------------------------------------------------------------
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


import "./Owned.sol";


/**
 * @title A contract that can be destroyed by its owner after a delay elapses.
 */
contract SelfDestructible is Owned {
    
    uint public initiationTime;
    bool public selfDestructInitiated;
    address public selfDestructBeneficiary;
    uint public constant SELFDESTRUCT_DELAY = 4 weeks;

    /**
     * @dev Constructor
     * @param _owner The account which controls this contract.
     */
    constructor(address _owner)
        Owned(_owner)
    {
        require(_owner != address(0), "Owner must not be the zero address");
        selfDestructBeneficiary = _owner;
        emit SelfDestructBeneficiaryUpdated(_owner);
    }

    /**
     * @notice Set the beneficiary address of this contract.
     * @dev Only the contract owner may call this. The provided beneficiary must be non-null.
     * @param _beneficiary The address to pay any eth contained in this contract to upon self-destruction.
     */
    function setSelfDestructBeneficiary(address _beneficiary)
        external
        onlyOwner
    {
        require(_beneficiary != address(0), "Beneficiary must not be the zero address");
        selfDestructBeneficiary = _beneficiary;
        emit SelfDestructBeneficiaryUpdated(_beneficiary);
    }

    /**
     * @notice Begin the self-destruction counter of this contract.
     * Once the delay has elapsed, the contract may be self-destructed.
     * @dev Only the contract owner may call this.
     */
    function initiateSelfDestruct()
        external
        onlyOwner
    {
        initiationTime = block.timestamp;
        selfDestructInitiated = true;
        emit SelfDestructInitiated(SELFDESTRUCT_DELAY);
    }

    /**
     * @notice Terminate and reset the self-destruction timer.
     * @dev Only the contract owner may call this.
     */
    function terminateSelfDestruct()
        external
        onlyOwner
    {
        initiationTime = 0;
        selfDestructInitiated = false;
        emit SelfDestructTerminated();
    }

    /**
     * @notice If the self-destruction delay has elapsed, destroy this contract and
     * remit any ether it owns to the beneficiary address.
     * @dev Only the contract owner may call this.
     */
    function selfDestruct()
        external
        onlyOwner
    {
        require(selfDestructInitiated, "Self destruct has not yet been initiated");
        require(initiationTime + SELFDESTRUCT_DELAY < block.timestamp, "Self destruct delay has not yet elapsed");
        address beneficiary = selfDestructBeneficiary;
        emit SelfDestructed(beneficiary);
        selfdestruct(payable(beneficiary));
    }

    event SelfDestructTerminated();
    event SelfDestructed(address beneficiary);
    event SelfDestructInitiated(uint selfDestructDelay);
    event SelfDestructBeneficiaryUpdated(address newBeneficiary);
}

/*

-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       SafeDecimalMath.sol
version:    2.0
author:     Kevin Brown
            Gavin Conway
date:       2018-10-18

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

A library providing safe mathematical operations for division and
multiplication with the capability to round or truncate the results
to the nearest increment. Operations can return a standard precision
or high precision decimal. High precision decimals are useful for
example when attempting to calculate percentages or fractions
accurately.

-----------------------------------------------------------------
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title Safely manipulate unsigned fixed-point decimals at a given precision level.
 * @dev Functions accepting uints in this contract and derived contracts
 * are taken to be such fixed point decimals of a specified precision (either standard
 * or high).
 */
library SafeDecimalMath {

    using SafeMath for uint;

    /* Number of decimal places in the representations. */
    uint8 public constant decimals = 18;
    uint8 public constant highPrecisionDecimals = 27;

    /* The number representing 1.0. */
    uint public constant UNIT = 10 ** uint(decimals);

    /* The number representing 1.0 for higher fidelity numbers. */
    uint public constant PRECISE_UNIT = 10 ** uint(highPrecisionDecimals);
    uint private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR = 10 ** uint(highPrecisionDecimals - decimals);

    /** 
     * @return Provides an interface to UNIT.
     */
    function unit()
        external
        pure
        returns (uint)
    {
        return UNIT;
    }

    /** 
     * @return Provides an interface to PRECISE_UNIT.
     */
    function preciseUnit()
        external
        pure 
        returns (uint)
    {
        return PRECISE_UNIT;
    }

    /**
     * @return The result of multiplying x and y, interpreting the operands as fixed-point
     * decimals.
     * 
     * @dev A unit factor is divided out after the product of x and y is evaluated,
     * so that product must be less than 2**256. As this is an integer division,
     * the internal division always rounds down. This helps save on gas. Rounding
     * is more expensive on gas.
     */
    function multiplyDecimal(uint x, uint y)
        internal
        pure
        returns (uint)
    {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return x.mul(y) / UNIT;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of the specified precision unit.
     *
     * @dev The operands should be in the form of a the specified unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function _multiplyDecimalRound(uint x, uint y, uint precisionUnit)
        private
        pure
        returns (uint)
    {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        uint quotientTimesTen = x.mul(y) / (precisionUnit / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a precise unit.
     *
     * @dev The operands should be in the precise unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRoundPrecise(uint x, uint y)
        internal
        pure
        returns (uint)
    {
        return _multiplyDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a standard unit.
     *
     * @dev The operands should be in the standard unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRound(uint x, uint y)
        internal
        pure
        returns (uint)
    {
        return _multiplyDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is a high
     * precision decimal.
     * 
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and UNIT must be less than 2**256. As
     * this is an integer division, the result is always rounded down.
     * This helps save on gas. Rounding is more expensive on gas.
     */
    function divideDecimal(uint x, uint y)
        internal
        pure
        returns (uint)
    {
        /* Reintroduce the UNIT factor that will be divided out by y. */
        return x.mul(UNIT).div(y);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * decimal in the precision unit specified in the parameter.
     *
     * @dev y is divided after the product of x and the specified precision unit
     * is evaluated, so the product of x and the specified precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function _divideDecimalRound(uint x, uint y, uint precisionUnit)
        private
        pure
        returns (uint)
    {
        uint resultTimesTen = x.mul(precisionUnit * 10).div(y);

        if (resultTimesTen % 10 >= 5) {
            resultTimesTen += 10;
        }

        return resultTimesTen / 10;
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * standard precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and the standard precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRound(uint x, uint y)
        internal
        pure
        returns (uint)
    {
        return _divideDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * high precision decimal.
     *
     * @dev y is divided after the product of x and the high precision unit
     * is evaluated, so the product of x and the high precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRoundPrecise(uint x, uint y)
        internal
        pure
        returns (uint)
    {
        return _divideDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @dev Convert a standard decimal representation to a high precision one.
     */
    function decimalToPreciseDecimal(uint i)
        internal
        pure
        returns (uint)
    {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }

    /**
     * @dev Convert a high precision decimal to a standard decimal representation.
     */
    function preciseDecimalToDecimal(uint i)
        internal
        pure
        returns (uint)
    {
        uint quotientTimesTen = i / (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

}

/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       Synthetix.sol
version:    2.0
author:     Kevin Brown
            Gavin Conway
date:       2018-09-14

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

Synthetix token contract. SNX is a transferable ERC20 token,
and also give its holders the following privileges.
An owner of SNX has the right to issue synths in all synth flavours.

After a fee period terminates, the duration and fees collected for that
period are computed, and the next period begins. Thus an account may only
withdraw the fees owed to them for the previous period, and may only do
so once per period. Any unclaimed fees roll over into the common pot for
the next period.

== Average Balance Calculations ==

The fee entitlement of a synthetix holder is proportional to their average
issued synth balance over the last fee period. This is computed by
measuring the area under the graph of a user's issued synth balance over
time, and then when a new fee period begins, dividing through by the
duration of the fee period.

We need only update values when the balances of an account is modified.
This occurs when issuing or burning for issued synth balances,
and when transferring for synthetix balances. This is for efficiency,
and adds an implicit friction to interacting with SNX.
A synthetix holder pays for his own recomputation whenever he wants to change
his position, which saves the foundation having to maintain a pot dedicated
to resourcing this.

A hypothetical user's balance history over one fee period, pictorially:

      s ____
       |    |
       |    |___ p
       |____|___|___ __ _  _
       f    t   n

Here, the balance was s between times f and t, at which time a transfer
occurred, updating the balance to p, until n, when the present transfer occurs.
When a new transfer occurs at time n, the balance being p,
we must:

  - Add the area p * (n - t) to the total area recorded so far
  - Update the last transfer time to n

So if this graph represents the entire current fee period,
the average SNX held so far is ((t-f)*s + (n-t)*p) / (n-f).
The complementary computations must be performed for both sender and
recipient.

Note that a transfer keeps global supply of SNX invariant.
The sum of all balances is constant, and unmodified by any transfer.
So the sum of all balances multiplied by the duration of a fee period is also
constant, and this is equivalent to the sum of the area of every user's
time/balance graph. Dividing through by that duration yields back the total
synthetix supply. So, at the end of a fee period, we really do yield a user's
average share in the synthetix supply over that period.

A slight wrinkle is introduced if we consider the time r when the fee period
rolls over. Then the previous fee period k-1 is before r, and the current fee
period k is afterwards. If the last transfer took place before r,
but the latest transfer occurred afterwards:

k-1       |        k
      s __|_
       |  | |
       |  | |____ p
       |__|_|____|___ __ _  _
          |
       f  | t    n
          r

In this situation the area (r-f)*s contributes to fee period k-1, while
the area (t-r)*s contributes to fee period k. We will implicitly consider a
zero-value transfer to have occurred at time r. Their fee entitlement for the
previous period will be finalised at the time of their first transfer during the
current fee period, or when they query or withdraw their fee entitlement.

In the implementation, the duration of different fee periods may be slightly irregular,
as the check that they have rolled over occurs only when state-changing synthetix
operations are performed.

== Issuance and Burning ==

In this version of the synthetix contract, synths can only be issued by
those that have been nominated by the synthetix foundation. Synths are assumed
to be valued at $1, as they are a stable unit of account.

All synths issued require a proportional value of SNX to be locked,
where the proportion is governed by the current issuance ratio. This
means for every $1 of SNX locked up, $(issuanceRatio) synths can be issued.
i.e. to issue 100 synths, 100/issuanceRatio dollars of SNX need to be locked up.

To determine the value of some amount of SNX(S), an oracle is used to push
the price of SNX (P_S) in dollars to the contract. The value of S
would then be: S * P_S.

Any SNX that are locked up by this issuance process cannot be transferred.
The amount that is locked floats based on the price of SNX. If the price
of SNX moves up, less SNX are locked, so they can be issued against,
or transferred freely. If the price of SNX moves down, more SNX are locked,
even going above the initial wallet balance.

-----------------------------------------------------------------
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


import "./ExternStateToken.sol";
import "./TokenState.sol";
import "./SupplySchedule.sol";
import "./ExchangeRates.sol";
import "./SynthetixState.sol";
import "./Synth.sol";
import "./ISynthetixEscrow.sol";
import "./IFeePool.sol";

/**
 * @title Synthetix ERC20 contract.
 * @notice The Synthetix contracts not only facilitates transfers, exchanges, and tracks balances,
 * but it also computes the quantity of fees each synthetix holder is entitled to.
 */
contract Synthetix is ExternStateToken {
    using SafeDecimalMath for uint;
    // ========== STATE VARIABLES ==========

    // Available Synths which can be used with the system
    Synth[] public availableSynths;
    mapping(bytes4 => Synth) public synths;

    IFeePool public feePool;
    ISynthetixEscrow public escrow;
    ISynthetixEscrow public rewardEscrow;
    ExchangeRates public exchangeRates;
    SynthetixState public synthetixState;
    SupplySchedule public supplySchedule;

    string constant TOKEN_NAME = "Synthetix Network Token";
    string constant TOKEN_SYMBOL = "SNX";
    uint8 constant DECIMALS = 18;
    // ========== CONSTRUCTOR ==========

    /**
     * @dev Constructor
     * @param _tokenState A pre-populated contract containing token balances.
     * If the provided address is 0x0, then a fresh one will be constructed with the contract owning all tokens.
     * @param _owner The owner of this contract.
     */
    constructor(address _proxy, TokenState _tokenState, SynthetixState _synthetixState,
        address _owner, ExchangeRates _exchangeRates, IFeePool _feePool, SupplySchedule _supplySchedule,
        ISynthetixEscrow _rewardEscrow, ISynthetixEscrow _escrow, uint _totalSupply
    )
        ExternStateToken(_proxy, _tokenState, TOKEN_NAME, TOKEN_SYMBOL, _totalSupply, DECIMALS, _owner)
    {
        synthetixState = _synthetixState;
        exchangeRates = _exchangeRates;
        feePool = _feePool;
        supplySchedule = _supplySchedule;
        rewardEscrow = _rewardEscrow;
        escrow = _escrow;
    }
    // ========== SETTERS ========== */

    function setFeePool(IFeePool _feePool)
        external
        optionalProxy_onlyOwner
    {
        feePool = _feePool;
    }

    function setExchangeRates(ExchangeRates _exchangeRates)
        external
        optionalProxy_onlyOwner
    {
        exchangeRates = _exchangeRates;
    }

    /**
     * @notice Add an associated Synth contract to the Synthetix system
     * @dev Only the contract owner may call this.
     */
    function addSynth(Synth synth)
        external
        optionalProxy_onlyOwner
    {
        bytes4 currencyKey = synth.currencyKey();

        require(synths[currencyKey] == Synth(address(0)), "Synth already exists");

        availableSynths.push(synth);
        synths[currencyKey] = synth;
    }

    /**
     * @notice Remove an associated Synth contract from the Synthetix system
     * @dev Only the contract owner may call this.
     */
    function removeSynth(bytes4 currencyKey)
        external
        optionalProxy_onlyOwner
    {
        require(address(synths[currencyKey]) != address(0), "Synth does not exist");
        require(synths[currencyKey].totalSupply() == 0, "Synth supply exists");
        require(currencyKey != "XDR", "Cannot remove XDR synth");

        // Save the address we're removing for emitting the event at the end.
        address synthToRemove = address(synths[currencyKey]);

        // Remove the synth from the availableSynths array.
        for (uint8 i = 0; i < availableSynths.length; i++) {
            if (address(availableSynths[i]) == synthToRemove) {
                delete availableSynths[i];

                // Copy the last synth into the place of the one we just deleted
                // If there's only one synth, this is synths[0] = synths[0].
                // If we're deleting the last one, it's also a NOOP in the same way.
                availableSynths[i] = availableSynths[availableSynths.length - 1];

                // Decrease the size of the array by one.
                availableSynths.pop();

                break;
            }
        }

        // And remove it from the synths mapping
        delete synths[currencyKey];

        // Note: No event here as our contract exceeds max contract size
        // with these events, and it's unlikely people will need to
        // track these events specifically.
    }

    // ========== VIEWS ==========

    /**
     * @notice A function that lets you easily convert an amount in a source currency to an amount in the destination currency
     * @param sourceCurrencyKey The currency the amount is specified in
     * @param sourceAmount The source amount, specified in UNIT base
     * @param destinationCurrencyKey The destination currency
     */
    function effectiveValue(bytes4 sourceCurrencyKey, uint sourceAmount, bytes4 destinationCurrencyKey)
        public
        view
        rateNotStale(sourceCurrencyKey)
        rateNotStale(destinationCurrencyKey)
        returns (uint)
    {
        // If there's no change in the currency, then just return the amount they gave us
        if (sourceCurrencyKey == destinationCurrencyKey) return sourceAmount;

        // Calculate the effective value by going from source -> USD -> destination
        return sourceAmount.multiplyDecimalRound(exchangeRates.rateForCurrency(sourceCurrencyKey))
            .divideDecimalRound(exchangeRates.rateForCurrency(destinationCurrencyKey));
    }

    /**
     * @notice Total amount of synths issued by the system, priced in currencyKey
     * @param currencyKey The currency to value the synths in
     */
    function totalIssuedSynths(bytes4 currencyKey)
        public
        view
        rateNotStale(currencyKey)
        returns (uint)
    {
        uint total = 0;
        uint currencyRate = exchangeRates.rateForCurrency(currencyKey);

        require(!exchangeRates.anyRateIsStale(availableCurrencyKeys()), "Rates are stale");

        for (uint8 i = 0; i < availableSynths.length; i++) {
            // What's the total issued value of that synth in the destination currency?
            // Note: We're not using our effectiveValue function because we don't want to go get the
            //       rate for the destination currency and check if it's stale repeatedly on every
            //       iteration of the loop
            uint synthValue = availableSynths[i].totalSupply()
                .multiplyDecimalRound(exchangeRates.rateForCurrency(availableSynths[i].currencyKey()))
                .divideDecimalRound(currencyRate);
            total = total + synthValue;
        }

        return total;
    }

    /**
     * @notice Returns the currencyKeys of availableSynths for rate checking
     */
    function availableCurrencyKeys()
        internal
        view
        returns (bytes4[] memory)
    {
        bytes4[] memory availableCurrencyKeys = new bytes4[](availableSynths.length);

        for (uint8 i = 0; i < availableSynths.length; i++) {
            availableCurrencyKeys[i] = availableSynths[i].currencyKey();
        }

        return availableCurrencyKeys;
    }

    /**
     * @notice Returns the count of available synths in the system, which you can use to iterate availableSynths
     */
    function availableSynthCount()
        public
        view
        returns (uint)
    {
        return availableSynths.length;
    }

    // ========== MUTATIVE FUNCTIONS ==========

    /**
     * @notice ERC20 transfer function.
     */
    function transfer(address to, uint value)
        public
        returns (bool)
    {
        bytes memory empty;
        return transfer(to, value, empty);
    }

    /**
     * @notice ERC223 transfer function. Does not conform with the ERC223 spec, as:
     *         - Transaction doesn't revert if the recipient doesn't implement tokenFallback()
     *         - Emits a standard ERC20 event without the bytes data parameter so as not to confuse
     *           tooling such as Etherscan.
     */
    function transfer(address to, uint value, bytes memory data)
        public
        optionalProxy
        returns (bool)
    {
        // Ensure they're not trying to exceed their locked amount
        require(value <= transferableSynthetix(messageSender), "Insufficient balance");

        // Perform the transfer: if there is a problem an exception will be thrown in this call.
        _transfer_byProxy(messageSender, to, value, data);

        return true;
    }

    /**
     * @notice ERC20 transferFrom function.
     */
    function transferFrom(address from, address to, uint value)
        public
        returns (bool)
    {
        bytes memory empty;
        return transferFrom(from, to, value, empty);
    }

    /**
     * @notice ERC223 transferFrom function. Does not conform with the ERC223 spec, as:
     *         - Transaction doesn't revert if the recipient doesn't implement tokenFallback()
     *         - Emits a standard ERC20 event without the bytes data parameter so as not to confuse
     *           tooling such as Etherscan.
     */
    function transferFrom(address from, address to, uint value, bytes memory data)
        public
        optionalProxy
        returns (bool)
    {
        // Ensure they're not trying to exceed their locked amount
        require(value <= transferableSynthetix(from), "Insufficient balance");

        // Perform the transfer: if there is a problem,
        // an exception will be thrown in this call.
        _transferFrom_byProxy(messageSender, from, to, value, data);

        return true;
    }

    /**
     * @notice Function that allows you to exchange synths you hold in one flavour for another.
     * @param sourceCurrencyKey The source currency you wish to exchange from
     * @param sourceAmount The amount, specified in UNIT of source currency you wish to exchange
     * @param destinationCurrencyKey The destination currency you wish to obtain.
     * @param destinationAddress Where the result should go. If this is address(0) then it sends back to the message sender.
     * @return Boolean that indicates whether the transfer succeeded or failed.
     */
    function exchange(bytes4 sourceCurrencyKey, uint sourceAmount, bytes4 destinationCurrencyKey, address destinationAddress)
        external
        optionalProxy
        // Note: We don't need to insist on non-stale rates because effectiveValue will do it for us.
        returns (bool)
    {
        require(sourceCurrencyKey != destinationCurrencyKey, "Exchange must use different synths");
        require(sourceAmount > 0, "Zero amount");

        // Pass it along, defaulting to the sender as the recipient.
        return _internalExchange(
            messageSender,
            sourceCurrencyKey,
            sourceAmount,
            destinationCurrencyKey,
            destinationAddress == address(0) ? messageSender : destinationAddress,
            true // Charge fee on the exchange
        );
    }

    /**
     * @notice Function that allows synth contract to delegate exchanging of a synth that is not the same sourceCurrency
     * @dev Only the synth contract can call this function
     * @param from The address to exchange / burn synth from
     * @param sourceCurrencyKey The source currency you wish to exchange from
     * @param sourceAmount The amount, specified in UNIT of source currency you wish to exchange
     * @param destinationCurrencyKey The destination currency you wish to obtain.
     * @param destinationAddress Where the result should go.
     * @return Boolean that indicates whether the transfer succeeded or failed.
     */
    function synthInitiatedExchange(
        address from,
        bytes4 sourceCurrencyKey,
        uint sourceAmount,
        bytes4 destinationCurrencyKey,
        address destinationAddress
    )
        external
        onlySynth
        returns (bool)
    {
        require(sourceCurrencyKey != destinationCurrencyKey, "Can't be same synth");
        require(sourceAmount > 0, "Zero amount");

        // Pass it along
        return _internalExchange(
            from,
            sourceCurrencyKey,
            sourceAmount,
            destinationCurrencyKey,
            destinationAddress,
            false // Don't charge fee on the exchange, as they've already been charged a transfer fee in the synth contract
        );
    }

    /**
     * @notice Function that allows synth contract to delegate sending fee to the fee Pool.
     * @dev Only the synth contract can call this function.
     * @param from The address fee is coming from.
     * @param sourceCurrencyKey source currency fee from.
     * @param sourceAmount The amount, specified in UNIT of source currency.
     * @return Boolean that indicates whether the transfer succeeded or failed.
     */
    function synthInitiatedFeePayment(
        address from,
        bytes4 sourceCurrencyKey,
        uint sourceAmount
    )
        external
        onlySynth
        returns (bool)
    {
        // Allow fee to be 0 and skip minting XDRs to feePool
        if (sourceAmount == 0) {
            return true;
        }

        require(sourceAmount > 0, "Source can't be 0");

        // Pass it along, defaulting to the sender as the recipient.
        bool result = _internalExchange(
            from,
            sourceCurrencyKey,
            sourceAmount,
            "XDR",
            feePool.FEE_ADDRESS(),
            false // Don't charge a fee on the exchange because this is already a fee
        );

        // Tell the fee pool about this.
        feePool.feePaid(sourceCurrencyKey, sourceAmount);

        return result;
    }

    /**
     * @notice Function that allows synth contract to delegate sending fee to the fee Pool.
     * @dev fee pool contract address is not allowed to call function
     * @param from The address to move synth from
     * @param sourceCurrencyKey source currency from.
     * @param sourceAmount The amount, specified in UNIT of source currency.
     * @param destinationCurrencyKey The destination currency to obtain.
     * @param destinationAddress Where the result should go.
     * @param chargeFee Boolean to charge a fee for transaction.
     * @return Boolean that indicates whether the transfer succeeded or failed.
     */
    function _internalExchange(
        address from,
        bytes4 sourceCurrencyKey,
        uint sourceAmount,
        bytes4 destinationCurrencyKey,
        address destinationAddress,
        bool chargeFee
    )
        internal
        notFeeAddress(from)
        returns (bool)
    {
        require(destinationAddress != address(0), "Zero destination");
        require(destinationAddress != address(this), "Synthetix is invalid destination");
        require(destinationAddress != address(proxy), "Proxy is invalid destination");

        // Note: We don't need to check their balance as the burn() below will do a safe subtraction which requires
        // the subtraction to not overflow, which would happen if their balance is not sufficient.

        // Burn the source amount
        synths[sourceCurrencyKey].burn(from, sourceAmount);

        // How much should they get in the destination currency?
        uint destinationAmount = effectiveValue(sourceCurrencyKey, sourceAmount, destinationCurrencyKey);

        // What's the fee on that currency that we should deduct?
        uint amountReceived = destinationAmount;
        uint fee = 0;

        if (chargeFee) {
            amountReceived = feePool.amountReceivedFromExchange(destinationAmount);
            fee = destinationAmount - amountReceived;
        }

        // Issue their new synths
        synths[destinationCurrencyKey].issue(destinationAddress, amountReceived);

        // Remit the fee in XDRs
        if (fee > 0) {
            uint xdrFeeAmount = effectiveValue(destinationCurrencyKey, fee, "XDR");
            synths["XDR"].issue(feePool.FEE_ADDRESS(), xdrFeeAmount);
            // Tell the fee pool about this.
            feePool.feePaid("XDR", xdrFeeAmount);
        }

        // Nothing changes as far as issuance data goes because the total value in the system hasn't changed.

        // Call the ERC223 transfer callback if needed
        synths[destinationCurrencyKey].triggerTokenFallbackIfNeeded(from, destinationAddress, amountReceived);

        //Let the DApps know there was a Synth exchange
        emitSynthExchange(from, sourceCurrencyKey, sourceAmount, destinationCurrencyKey, amountReceived, destinationAddress);

        return true;
    }

    /**
     * @notice Function that registers new synth as they are isseud. Calculate delta to append to synthetixState.
     * @dev Only internal calls from synthetix address.
     * @param currencyKey The currency to register synths in, for example sUSD or sAUD
     * @param amount The amount of synths to register with a base of UNIT
     */
    function _addToDebtRegister(bytes4 currencyKey, uint amount)
        internal
        optionalProxy
    {
        // What is the value of the requested debt in XDRs?
        uint xdrValue = effectiveValue(currencyKey, amount, "XDR");

        // What is the value of all issued synths of the system (priced in XDRs)?
        uint totalDebtIssued = totalIssuedSynths("XDR");

        // What will the new total be including the new value?
        uint newTotalDebtIssued = xdrValue + totalDebtIssued;

        // What is their percentage (as a high precision int) of the total debt?
        uint debtPercentage = xdrValue.divideDecimalRoundPrecise(newTotalDebtIssued);

        // And what effect does this percentage change have on the global debt holding of other issuers?
        // The delta specifically needs to not take into account any existing debt as it's already
        // accounted for in the delta from when they issued previously.
        // The delta is a high precision integer.
        uint delta = SafeDecimalMath.preciseUnit() - debtPercentage;

        // How much existing debt do they have?
        uint existingDebt = debtBalanceOf(messageSender, "XDR");

        // And what does their debt ownership look like including this previous stake?
        if (existingDebt > 0) {
            debtPercentage = (xdrValue + existingDebt).divideDecimalRoundPrecise(newTotalDebtIssued);
        }

        // Are they a new issuer? If so, record them.
        if (!synthetixState.hasIssued(messageSender)) {
            synthetixState.incrementTotalIssuerCount();
        }

        // Save the debt entry parameters
        synthetixState.setCurrentIssuanceData(messageSender, debtPercentage);

        // And if we're the first, push 1 as there was no effect to any other holders, otherwise push
        // the change for the rest of the debt holders. The debt ledger holds high precision integers.
        if (synthetixState.debtLedgerLength() > 0) {
            synthetixState.appendDebtLedgerValue(
                synthetixState.lastDebtLedgerEntry().multiplyDecimalRoundPrecise(delta)
            );
        } else {
            synthetixState.appendDebtLedgerValue(SafeDecimalMath.preciseUnit());
        }
    }

    /**
     * @notice Issue synths against the sender's SNX.
     * @dev Issuance is only allowed if the synthetix price isn't stale. Amount should be larger than 0.
     * @param currencyKey The currency you wish to issue synths in, for example sUSD or sAUD
     * @param amount The amount of synths you wish to issue with a base of UNIT
     */
    function issueSynths(bytes4 currencyKey, uint amount)
        public
        optionalProxy
        // No need to check if price is stale, as it is checked in issuableSynths.
    {
        require(amount <= remainingIssuableSynths(messageSender, currencyKey), "Amount too large");

        // Keep track of the debt they're about to create
        _addToDebtRegister(currencyKey, amount);

        // Create their synths
        synths[currencyKey].issue(messageSender, amount);

        // Store their locked SNX amount to determine their fee % for the period
        _appendAccountIssuanceRecord();
    }

    /**
     * @notice Issue the maximum amount of Synths possible against the sender's SNX.
     * @dev Issuance is only allowed if the synthetix price isn't stale.
     * @param currencyKey The currency you wish to issue synths in, for example sUSD or sAUD
     */
    function issueMaxSynths(bytes4 currencyKey)
        external
        optionalProxy
    {
        // Figure out the maximum we can issue in that currency
        uint maxIssuable = remainingIssuableSynths(messageSender, currencyKey);

        // And issue them
        issueSynths(currencyKey, maxIssuable);
    }

    /**
     * @notice Burn synths to clear issued synths/free SNX.
     * @param currencyKey The currency you're specifying to burn
     * @param amount The amount (in UNIT base) you wish to burn
     * @dev The amount to burn is debased to XDR's
     */
    function burnSynths(bytes4 currencyKey, uint amount)
        external
        optionalProxy
        // No need to check for stale rates as effectiveValue checks rates
    {
        // How much debt do they have?
        uint debtToRemove = effectiveValue(currencyKey, amount, "XDR");
        uint debt = debtBalanceOf(messageSender, "XDR");
        uint debtInCurrencyKey = debtBalanceOf(messageSender, currencyKey);

        require(debt > 0, "No debt to forgive");

        // If they're trying to burn more debt than they actually owe, rather than fail the transaction, let's just
        // clear their debt and leave them be.
        uint amountToRemove = debt < debtToRemove ? debt : debtToRemove;

        // Remove their debt from the ledger
        _removeFromDebtRegister(amountToRemove);

        uint amountToBurn = debtInCurrencyKey < amount ? debtInCurrencyKey : amount;

        // synth.burn does a safe subtraction on balance (so it will revert if there are not enough synths).
        synths[currencyKey].burn(messageSender, amountToBurn);

        // Store their debtRatio against a feeperiod to determine their fee/rewards % for the period
        _appendAccountIssuanceRecord();
    }

    /**
     * @notice Store in the FeePool the users current debt value in the system in XDRs.
     * @dev debtBalanceOf(messageSender, "XDR") to be used with totalIssuedSynths("XDR") to get
     *  users % of the system within a feePeriod.
     */
    function _appendAccountIssuanceRecord()
        internal
    {
        uint initialDebtOwnership;
        uint debtEntryIndex;
        (initialDebtOwnership, debtEntryIndex) = synthetixState.issuanceData(messageSender);

        feePool.appendAccountIssuanceRecord(
            messageSender,
            initialDebtOwnership,
            debtEntryIndex
        );
    }

    /**
     * @notice Remove a debt position from the register
     * @param amount The amount (in UNIT base) being presented in XDRs
     */
    function _removeFromDebtRegister(uint amount)
        internal
    {
        uint debtToRemove = amount;

        // How much debt do they have?
        uint existingDebt = debtBalanceOf(messageSender, "XDR");

        // What is the value of all issued synths of the system (priced in XDRs)?
        uint totalDebtIssued = totalIssuedSynths("XDR");

        // What will the new total after taking out the withdrawn amount
        uint newTotalDebtIssued = totalDebtIssued - debtToRemove;

        uint delta;

        // What will the debt delta be if there is any debt left?
        // Set delta to 0 if no more debt left in system after user
        if (newTotalDebtIssued > 0) {

            // What is the percentage of the withdrawn debt (as a high precision int) of the total debt after?
            uint debtPercentage = debtToRemove.divideDecimalRoundPrecise(newTotalDebtIssued);

            // And what effect does this percentage change have on the global debt holding of other issuers?
            // The delta specifically needs to not take into account any existing debt as it's already
            // accounted for in the delta from when they issued previously.
            delta = SafeDecimalMath.preciseUnit() + debtPercentage;
        } else {
            delta = 0;
        }

        // Are they exiting the system, or are they just decreasing their debt position?
        if (debtToRemove == existingDebt) {
            synthetixState.setCurrentIssuanceData(messageSender, 0);
            synthetixState.decrementTotalIssuerCount();
        } else {
            // What percentage of the debt will they be left with?
            uint newDebt = existingDebt - debtToRemove;
            uint newDebtPercentage = newDebt.divideDecimalRoundPrecise(newTotalDebtIssued);

            // Store the debt percentage and debt ledger as high precision integers
            synthetixState.setCurrentIssuanceData(messageSender, newDebtPercentage);
        }

        // Update our cumulative ledger. This is also a high precision integer.
        synthetixState.appendDebtLedgerValue(
            synthetixState.lastDebtLedgerEntry().multiplyDecimalRoundPrecise(delta)
        );
    }

    // ========== Issuance/Burning ==========

    /**
     * @notice The maximum synths an issuer can issue against their total synthetix quantity, priced in XDRs.
     * This ignores any already issued synths, and is purely giving you the maximimum amount the user can issue.
     */
    function maxIssuableSynths(address issuer, bytes4 currencyKey)
        public
        view
        // We don't need to check stale rates here as effectiveValue will do it for us.
        returns (uint)
    {
        // What is the value of their SNX balance in the destination currency?
        uint destinationValue = effectiveValue("SNX", collateral(issuer), currencyKey);

        // They're allowed to issue up to issuanceRatio of that value
        return destinationValue.multiplyDecimal(synthetixState.issuanceRatio());
    }

    /**
     * @notice The current collateralisation ratio for a user. Collateralisation ratio varies over time
     * as the value of the underlying Synthetix asset changes, e.g. if a user issues their maximum available
     * synths when they hold $10 worth of Synthetix, they will have issued $2 worth of synths. If the value
     * of Synthetix changes, the ratio returned by this function will adjust accordlingly. Users are
     * incentivised to maintain a collateralisation ratio as close to the issuance ratio as possible by
     * altering the amount of fees they're able to claim from the system.
     */
    function collateralisationRatio(address issuer)
        public
        view
        returns (uint)
    {
        uint totalOwnedSynthetix = collateral(issuer);
        if (totalOwnedSynthetix == 0) return 0;

        uint debtBalance = debtBalanceOf(issuer, "SNX");
        return debtBalance.divideDecimalRound(totalOwnedSynthetix);
    }

    /**
     * @notice If a user issues synths backed by SNX in their wallet, the SNX become locked. This function
     * will tell you how many synths a user has to give back to the system in order to unlock their original
     * debt position. This is priced in whichever synth is passed in as a currency key, e.g. you can price
     * the debt in sUSD, XDR, or any other synth you wish.
     */
    function debtBalanceOf(address issuer, bytes4 currencyKey)
        public
        view
        // Don't need to check for stale rates here because totalIssuedSynths will do it for us
        returns (uint)
    {
        // What was their initial debt ownership?
        uint initialDebtOwnership;
        uint debtEntryIndex;
        (initialDebtOwnership, debtEntryIndex) = synthetixState.issuanceData(issuer);

        // If it's zero, they haven't issued, and they have no debt.
        if (initialDebtOwnership == 0) return 0;

        // Figure out the global debt percentage delta from when they entered the system.
        // This is a high precision integer.
        uint currentDebtOwnership = synthetixState.lastDebtLedgerEntry()
            .divideDecimalRoundPrecise(synthetixState.debtLedger(debtEntryIndex))
            .multiplyDecimalRoundPrecise(initialDebtOwnership);

        // What's the total value of the system in their requested currency?
        uint totalSystemValue = totalIssuedSynths(currencyKey);

        // Their debt balance is their portion of the total system value.
        uint highPrecisionBalance = totalSystemValue.decimalToPreciseDecimal()
            .multiplyDecimalRoundPrecise(currentDebtOwnership);

        return highPrecisionBalance.preciseDecimalToDecimal();
    }

    /**
     * @notice The remaining synths an issuer can issue against their total synthetix balance.
     * @param issuer The account that intends to issue
     * @param currencyKey The currency to price issuable value in
     */
    function remainingIssuableSynths(address issuer, bytes4 currencyKey)
        public
        view
        // Don't need to check for synth existing or stale rates because maxIssuableSynths will do it for us.
        returns (uint)
    {
        uint alreadyIssued = debtBalanceOf(issuer, currencyKey);
        uint max = maxIssuableSynths(issuer, currencyKey);

        if (alreadyIssued >= max) {
            return 0;
        } else {
            return max - alreadyIssued;
        }
    }

    /**
     * @notice The total SNX owned by this account, both escrowed and unescrowed,
     * against which synths can be issued.
     * This includes those already being used as collateral (locked), and those
     * available for further issuance (unlocked).
     */
    function collateral(address account)
        public
        view
        returns (uint)
    {
        uint balance = tokenState.balanceOf(account);

        if (address(escrow) != address(0)) {
            balance = balance + escrow.balanceOf(account);
        }

        if (address(rewardEscrow) != address(0)) {
            balance = balance + rewardEscrow.balanceOf(account);
        }

        return balance;
    }

    /**
     * @notice The number of SNX that are free to be transferred by an account.
     * @dev When issuing, escrowed SNX are locked first, then non-escrowed
     * SNX are locked last, but escrowed SNX are not transferable, so they are not included
     * in this calculation.
     */
    function transferableSynthetix(address account)
        public
        view
        rateNotStale("SNX")
        returns (uint)
    {
        // How many SNX do they have, excluding escrow?
        // Note: We're excluding escrow here because we're interested in their transferable amount
        // and escrowed SNX are not transferable.
        uint balance = tokenState.balanceOf(account);

        // How many of those will be locked by the amount they've issued?
        // Assuming issuance ratio is 20%, then issuing 20 SNX of value would require
        // 100 SNX to be locked in their wallet to maintain their collateralisation ratio
        // The locked synthetix value can exceed their balance.
        uint lockedSynthetixValue = debtBalanceOf(account, "SNX").divideDecimalRound(synthetixState.issuanceRatio());

        // If we exceed the balance, no SNX are transferable, otherwise the difference is.
        if (lockedSynthetixValue >= balance) {
            return 0;
        } else {
            return balance - lockedSynthetixValue;
        }
    }

    function mint()
        external
        returns (bool)
    {
        require(address(rewardEscrow) != address(0), "Reward Escrow destination missing");

        uint supplyToMint = supplySchedule.mintableSupply();
        require(supplyToMint > 0, "No supply is mintable");

        supplySchedule.updateMintValues();

        // Set minted SNX balance to RewardEscrow's balance
        // Minus the minterReward and set balance of minter to add reward
        uint minterReward = supplySchedule.minterReward();

        tokenState.setBalanceOf(address(rewardEscrow), tokenState.balanceOf(address(rewardEscrow)) + supplyToMint - minterReward);
        emitTransfer(address(this), address(rewardEscrow), supplyToMint - minterReward);

        // Tell the FeePool how much it has to distribute
        feePool.rewardsMinted(supplyToMint - minterReward);

        // Assign the minters reward.
        tokenState.setBalanceOf(msg.sender, tokenState.balanceOf(msg.sender) + minterReward);
        emitTransfer(address(this), msg.sender, minterReward);

        totalSupply = totalSupply + supplyToMint;
    }

    // ========== MODIFIERS ==========

    modifier rateNotStale(bytes4 currencyKey) {
        require(!exchangeRates.rateIsStale(currencyKey), "Rate stale or nonexistant currency");
        _;
    }

    modifier notFeeAddress(address account) {
        require(account != feePool.FEE_ADDRESS(), "Fee address not allowed");
        _;
    }

    modifier onlySynth() {
        bool isSynth = false;

        // No need to repeatedly call this function either
        for (uint8 i = 0; i < availableSynths.length; i++) {
            if (address(availableSynths[i]) == msg.sender) {
                isSynth = true;
                break;
            }
        }

        require(isSynth, "Only synth allowed");
        _;
    }

    modifier nonZeroAmount(uint _amount) {
        require(_amount > 0, "Amount needs to be larger than 0");
        _;
    }

    // ========== EVENTS ==========
    /* solium-disable */
    event SynthExchange(address indexed account, bytes4 fromCurrencyKey, uint256 fromAmount, bytes4 toCurrencyKey,  uint256 toAmount, address toAddress);
    bytes32 constant SYNTHEXCHANGE_SIG = keccak256("SynthExchange(address,bytes4,uint256,bytes4,uint256,address)");
    function emitSynthExchange(address account, bytes4 fromCurrencyKey, uint256 fromAmount, bytes4 toCurrencyKey, uint256 toAmount, address toAddress) internal {
        proxy._emit(abi.encode(fromCurrencyKey, fromAmount, toCurrencyKey, toAmount, toAddress), 2, SYNTHEXCHANGE_SIG, addressToBytes32(account), 0, 0);
    }
    /* solium-enable */
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/**
 * @title SynthetixEscrow interface
 */
interface ISynthetixEscrow {
    function balanceOf(address account) external view returns (uint);
    function appendVestingEntry(address account, uint quantity) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

abstract contract ISynthetixState {
    // A struct for handing values associated with an individual user's debt position
    struct IssuanceData {
        // Percentage of the total debt owned at the time
        // of issuance. This number is modified by the global debt
        // delta array. You can figure out a user's exit price and
        // collateralisation ratio using a combination of their initial
        // debt and the slice of global debt delta which applies to them.
        uint initialDebtOwnership;
        // This lets us know when (in relative terms) the user entered
        // the debt pool so we can calculate their exit price and
        // collateralistion ratio
        uint debtEntryIndex;
    }

    uint[] public debtLedger;
    uint public issuanceRatio;
    mapping(address => IssuanceData) public issuanceData;

    function debtLedgerLength() external virtual view returns (uint);
    function hasIssued(address account) external virtual view returns (bool);
    function incrementTotalIssuerCount() external virtual;
    function decrementTotalIssuerCount() external virtual;
    function setCurrentIssuanceData(address account, uint initialDebtOwnership) external virtual;
    function lastDebtLedgerEntry() external virtual view returns (uint);
    function appendDebtLedgerValue(uint value) external virtual;
    function clearIssuanceData(address account) external virtual;
}

/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       Synth.sol
version:    2.0
author:     Kevin Brown
date:       2018-09-13

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

Synthetix-backed stablecoin contract.

This contract issues synths, which are tokens that mirror various
flavours of fiat currency.

Synths are issuable by Synthetix Network Token (SNX) holders who
have to lock up some value of their SNX to issue S * Cmax synths.
Where Cmax issome value less than 1.

A configurable fee is charged on synth transfers and deposited
into a common pot, which Synthetix holders may withdraw from once
per fee period.

-----------------------------------------------------------------
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ExternStateToken.sol";
import "./IFeePool.sol";
import "./Synthetix.sol";

contract Synth is ExternStateToken {

    /* ========== STATE VARIABLES ========== */

    IFeePool public feePool;
    Synthetix public synthetix;

    // Currency key which identifies this Synth to the Synthetix system
    bytes4 public currencyKey;

    uint8 constant DECIMALS = 18;

    /* ========== CONSTRUCTOR ========== */

    constructor(address _proxy, TokenState _tokenState, Synthetix _synthetix, IFeePool _feePool,
        string memory _tokenName, string memory _tokenSymbol, address _owner, bytes4 _currencyKey
    )
        ExternStateToken(_proxy, _tokenState, _tokenName, _tokenSymbol, 0, DECIMALS, _owner)
    {
        require(_proxy != address(0), "_proxy cannot be 0");
        require(address(_synthetix) != address(0), "_synthetix cannot be 0");
        require(address(_feePool) != address(0), "_feePool cannot be 0");
        require(_owner != address(0), "_owner cannot be 0");
        require(_synthetix.synths(_currencyKey) == Synth(address(0)), "Currency key is already in use");

        feePool = _feePool;
        synthetix = _synthetix;
        currencyKey = _currencyKey;
    }

    /* ========== SETTERS ========== */

    function setSynthetix(Synthetix _synthetix)
        external
        optionalProxy_onlyOwner
    {
        synthetix = _synthetix;
        emitSynthetixUpdated(address(_synthetix));
    }

    function setFeePool(IFeePool _feePool)
        external
        optionalProxy_onlyOwner
    {
        feePool = _feePool;
        emitFeePoolUpdated(address(_feePool));
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Override ERC20 transfer function in order to
     * subtract the transaction fee and send it to the fee pool
     * for SNX holders to claim. */
    function transfer(address to, uint value)
        public
        optionalProxy
        notFeeAddress(messageSender)
        returns (bool)
    {
        uint amountReceived = feePool.amountReceivedFromTransfer(value);
        uint fee = value - amountReceived;

        // Send the fee off to the fee pool.
        synthetix.synthInitiatedFeePayment(messageSender, currencyKey, fee);

        // And send their result off to the destination address
        bytes memory empty;
        return _internalTransfer(messageSender, to, amountReceived, empty);
    }

    /**
     * @notice Override ERC223 transfer function in order to
     * subtract the transaction fee and send it to the fee pool
     * for SNX holders to claim. */
    function transfer(address to, uint value, bytes memory data)
        public
        optionalProxy
        notFeeAddress(messageSender)
        returns (bool)
    {
        uint amountReceived = feePool.amountReceivedFromTransfer(value);
        uint fee = value - amountReceived;

        // Send the fee off to the fee pool, which we don't want to charge an additional fee on
        synthetix.synthInitiatedFeePayment(messageSender, currencyKey, fee);

        // And send their result off to the destination address
        return _internalTransfer(messageSender, to, amountReceived, data);
    }

    /**
     * @notice Override ERC20 transferFrom function in order to
     * subtract the transaction fee and send it to the fee pool
     * for SNX holders to claim. */
    function transferFrom(address from, address to, uint value)
        public
        optionalProxy
        notFeeAddress(from)
        returns (bool)
    {
        // The fee is deducted from the amount sent.
        uint amountReceived = feePool.amountReceivedFromTransfer(value);
        uint fee = value - amountReceived;

        // Reduce the allowance by the amount we're transferring.
        // The safeSub call will handle an insufficient allowance.
        tokenState.setAllowance(from, messageSender, tokenState.allowance(from, messageSender) - value);

        // Send the fee off to the fee pool.
        synthetix.synthInitiatedFeePayment(from, currencyKey, fee);

        bytes memory empty;
        return _internalTransfer(from, to, amountReceived, empty);
    }

    /**
     * @notice Override ERC223 transferFrom function in order to
     * subtract the transaction fee and send it to the fee pool
     * for SNX holders to claim. */
    function transferFrom(address from, address to, uint value, bytes memory data)
        public
        optionalProxy
        notFeeAddress(from)
        returns (bool)
    {
        // The fee is deducted from the amount sent.
        uint amountReceived = feePool.amountReceivedFromTransfer(value);
        uint fee = value - amountReceived;

        // Reduce the allowance by the amount we're transferring.
        // The safeSub call will handle an insufficient allowance.
        tokenState.setAllowance(from, messageSender, tokenState.allowance(from, messageSender) - value);

        // Send the fee off to the fee pool, which we don't want to charge an additional fee on
        synthetix.synthInitiatedFeePayment(from, currencyKey, fee);

        return _internalTransfer(from, to, amountReceived, data);
    }

    /* Subtract the transfer fee from the senders account so the
     * receiver gets the exact amount specified to send. */
    function transferSenderPaysFee(address to, uint value)
        public
        optionalProxy
        notFeeAddress(messageSender)
        returns (bool)
    {
        uint fee = feePool.transferFeeIncurred(value);

        // Send the fee off to the fee pool, which we don't want to charge an additional fee on
        synthetix.synthInitiatedFeePayment(messageSender, currencyKey, fee);

        // And send their transfer amount off to the destination address
        bytes memory empty;
        return _internalTransfer(messageSender, to, value, empty);
    }

    /* Subtract the transfer fee from the senders account so the
     * receiver gets the exact amount specified to send. */
    function transferSenderPaysFee(address to, uint value, bytes memory data)
        public
        optionalProxy
        notFeeAddress(messageSender)
        returns (bool)
    {
        uint fee = feePool.transferFeeIncurred(value);

        // Send the fee off to the fee pool, which we don't want to charge an additional fee on
        synthetix.synthInitiatedFeePayment(messageSender, currencyKey, fee);

        // And send their transfer amount off to the destination address
        return _internalTransfer(messageSender, to, value, data);
    }

    /* Subtract the transfer fee from the senders account so the
     * to address receives the exact amount specified to send. */
    function transferFromSenderPaysFee(address from, address to, uint value)
        public
        optionalProxy
        notFeeAddress(from)
        returns (bool)
    {
        uint fee = feePool.transferFeeIncurred(value);

        // Reduce the allowance by the amount we're transferring.
        // The safeSub call will handle an insufficient allowance.
        tokenState.setAllowance(from, messageSender, tokenState.allowance(from, messageSender) - value + fee);

        // Send the fee off to the fee pool, which we don't want to charge an additional fee on
        synthetix.synthInitiatedFeePayment(from, currencyKey, fee);

        bytes memory empty;
        return _internalTransfer(from, to, value, empty);
    }

    /* Subtract the transfer fee from the senders account so the
     * to address receives the exact amount specified to send. */
    function transferFromSenderPaysFee(address from, address to, uint value, bytes memory data)
        public
        optionalProxy
        notFeeAddress(from)
        returns (bool)
    {
        uint fee = feePool.transferFeeIncurred(value);

        // Reduce the allowance by the amount we're transferring.
        // The safeSub call will handle an insufficient allowance.
        tokenState.setAllowance(from, messageSender, tokenState.allowance(from, messageSender) - value + fee);

        // Send the fee off to the fee pool, which we don't want to charge an additional fee on
        synthetix.synthInitiatedFeePayment(from, currencyKey, fee);

        return _internalTransfer(from, to, value, data);
    }

    // Override our internal transfer to inject preferred currency support
    function _internalTransfer(address from, address to, uint value, bytes memory data)
        internal
        override
        returns (bool)
    {
        bytes4 preferredCurrencyKey = synthetix.synthetixState().preferredCurrency(to);

        // Do they have a preferred currency that's not us? If so we need to exchange
        if (preferredCurrencyKey != 0 && preferredCurrencyKey != currencyKey) {
            return synthetix.synthInitiatedExchange(from, currencyKey, value, preferredCurrencyKey, to);
        } else {
            // Otherwise we just transfer
            return super._internalTransfer(from, to, value, data);
        }
    }

    // Allow synthetix to issue a certain number of synths from an account.
    function issue(address account, uint amount)
        external
        onlySynthetixOrFeePool
    {
        tokenState.setBalanceOf(account, tokenState.balanceOf(account) + amount);
        totalSupply = totalSupply + amount;
        emitTransfer(address(0), account, amount);
        emitIssued(account, amount);
    }

    // Allow synthetix or another synth contract to burn a certain number of synths from an account.
    function burn(address account, uint amount)
        external
        onlySynthetixOrFeePool
    {
        tokenState.setBalanceOf(account, tokenState.balanceOf(account) - amount);
        totalSupply = totalSupply - amount;
        emitTransfer(account, address(0), amount);
        emitBurned(account, amount);
    }

    // Allow owner to set the total supply on import.
    function setTotalSupply(uint amount)
        external
        optionalProxy_onlyOwner
    {
        totalSupply = amount;
    }

    // Allow synthetix to trigger a token fallback call from our synths so users get notified on
    // exchange as well as transfer
    function triggerTokenFallbackIfNeeded(address sender, address recipient, uint amount)
        external
        onlySynthetixOrFeePool
    {
        bytes memory empty;
        callTokenFallbackIfNeeded(sender, recipient, amount, empty);
    }

    /* ========== MODIFIERS ========== */

    modifier onlySynthetixOrFeePool() {
        bool isSynthetix = msg.sender == address(synthetix);
        bool isFeePool = msg.sender == address(feePool);

        require(isSynthetix || isFeePool, "Only the Synthetix or FeePool contracts can perform this action");
        _;
    }

    modifier notFeeAddress(address account) {
        require(account != feePool.FEE_ADDRESS(), "Cannot perform this action with the fee address");
        _;
    }

    /* ========== EVENTS ========== */

    event SynthetixUpdated(address newSynthetix);
    bytes32 constant SYNTHETIXUPDATED_SIG = keccak256("SynthetixUpdated(address)");
    function emitSynthetixUpdated(address newSynthetix) internal {
        proxy._emit(abi.encode(newSynthetix), 1, SYNTHETIXUPDATED_SIG, 0, 0, 0);
    }

    event FeePoolUpdated(address newFeePool);
    bytes32 constant FEEPOOLUPDATED_SIG = keccak256("FeePoolUpdated(address)");
    function emitFeePoolUpdated(address newFeePool) internal {
        proxy._emit(abi.encode(newFeePool), 1, FEEPOOLUPDATED_SIG, 0, 0, 0);
    }

    event Issued(address indexed account, uint value);
    bytes32 constant ISSUED_SIG = keccak256("Issued(address,uint256)");
    function emitIssued(address account, uint value) internal {
        proxy._emit(abi.encode(value), 2, ISSUED_SIG, addressToBytes32(account), 0, 0);
    }

    event Burned(address indexed account, uint value);
    bytes32 constant BURNED_SIG = keccak256("Burned(address,uint256)");
    function emitBurned(address account, uint value) internal {
        proxy._emit(abi.encode(value), 2, BURNED_SIG, addressToBytes32(account), 0, 0);
    }
}

/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       FeePoolState.sol
version:    1.0
author:     Clinton Ennis
            Jackson Chan
date:       2019-04-05

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

The FeePoolState simply stores the accounts issuance ratio for
each fee period in the FeePool.

This is use to caclulate the correct allocation of fees/rewards
owed to minters of the stablecoin total supply

-----------------------------------------------------------------
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./SelfDestructible.sol";
import "./SafeDecimalMath.sol";
import "./LimitedSetup.sol";
import "./IFeePool.sol";

contract FeePoolState is SelfDestructible, LimitedSetup {
    using SafeMath for uint;
    using SafeDecimalMath for uint;

    /* ========== STATE VARIABLES ========== */

    uint8 constant public FEE_PERIOD_LENGTH = 6;

    address public feePool;

    // The IssuanceData activity that's happened in a fee period.
    struct IssuanceData {
        uint debtPercentage;
        uint debtEntryIndex;
    }

    // The IssuanceData activity that's happened in a fee period.
    mapping(address => IssuanceData[FEE_PERIOD_LENGTH]) public accountIssuanceLedger;

    /**
     * @dev Constructor.
     * @param _owner The owner of this contract.
     */
    constructor(address _owner, IFeePool _feePool)
        SelfDestructible(_owner)
        LimitedSetup(6 weeks)
    {
        feePool = address(_feePool);
    }

    /* ========== SETTERS ========== */

    /**
     * @notice set the FeePool contract as it is the only authority to be able to call
     * appendAccountIssuanceRecord with the onlyFeePool modifer
     * @dev Must be set by owner when FeePool logic is upgraded
     */
    function setFeePool(IFeePool _feePool)
        external
        onlyOwner
    {
        feePool = address(_feePool);
    }

    /* ========== VIEWS ========== */

    /**
     * @notice Get an accounts issuanceData for
     * @param account users account
     * @param index Index in the array to retrieve. Upto FEE_PERIOD_LENGTH
     */
    function getAccountsDebtEntry(address account, uint index)
        public
        view
        returns (uint debtPercentage, uint debtEntryIndex)
    {
        require(index < FEE_PERIOD_LENGTH, "index exceeds the FEE_PERIOD_LENGTH");

        debtPercentage = accountIssuanceLedger[account][index].debtPercentage;
        debtEntryIndex = accountIssuanceLedger[account][index].debtEntryIndex;
    }

    /**
     * @notice Find the oldest debtEntryIndex for the corresponding closingDebtIndex
     * @param account users account
     * @param closingDebtIndex the last periods debt index on close
     */
    function applicableIssuanceData(address account, uint closingDebtIndex)
        external
        view
        returns (uint, uint)
    {
        IssuanceData[FEE_PERIOD_LENGTH] memory issuanceData = accountIssuanceLedger[account];
        
        // We want to use the user's debtEntryIndex at when the period closed
        // Find the oldest debtEntryIndex for the corresponding closingDebtIndex
        for (uint i = 0; i < FEE_PERIOD_LENGTH; i++) {
            if (closingDebtIndex >= issuanceData[i].debtEntryIndex) {
                return (issuanceData[i].debtPercentage, issuanceData[i].debtEntryIndex);
            }
        }
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Logs an accounts issuance data in the current fee period which is then stored historically
     * @param account Message.Senders account address
     * @param debtRatio Debt percentage this account has locked after minting or burning their synth
     * @param debtEntryIndex The index in the global debt ledger. synthetix.synthetixState().issuanceData(account)
     * @param currentPeriodStartDebtIndex The startingDebtIndex of the current fee period
     * @dev onlyFeePool to call me on synthetix.issue() & synthetix.burn() calls to store the locked SNX
     * per fee period so we know to allocate the correct proportions of fees and rewards per period
      accountIssuanceLedger[account][0] has the latest locked amount for the current period. This can be update as many time
      accountIssuanceLedger[account][1-3] has the last locked amount for a previous period they minted or burned
     */
    function appendAccountIssuanceRecord(address account, uint debtRatio, uint debtEntryIndex, uint currentPeriodStartDebtIndex)
        external
        onlyFeePool
    {
        // Is the current debtEntryIndex within this fee period
        if (accountIssuanceLedger[account][0].debtEntryIndex < currentPeriodStartDebtIndex) {
             // If its older then shift the previous IssuanceData entries periods down to make room for the new one.
            issuanceDataIndexOrder(account);
        }
        
        // Always store the latest IssuanceData entry at [0]
        accountIssuanceLedger[account][0].debtPercentage = debtRatio;
        accountIssuanceLedger[account][0].debtEntryIndex = debtEntryIndex;
    }

    /**
     * @notice Pushes down the entire array of debt ratios per fee period
     */
    function issuanceDataIndexOrder(address account)
        private
    {
        for (uint i = FEE_PERIOD_LENGTH - 2; i < FEE_PERIOD_LENGTH; i--) {
            uint next = i + 1;
            accountIssuanceLedger[account][next].debtPercentage = accountIssuanceLedger[account][i].debtPercentage;
            accountIssuanceLedger[account][next].debtEntryIndex = accountIssuanceLedger[account][i].debtEntryIndex;
        }
    }

    /**
     * @notice Import issuer data from synthetixState.issuerData on FeePeriodClose() block #
     * @dev Only callable by the contract owner, and only for 6 weeks after deployment.
     * @param accounts Array of issuing addresses
     * @param ratios Array of debt ratios
     * @param periodToInsert The Fee Period to insert the historical records into
     * @param feePeriodCloseIndex An accounts debtEntryIndex is valid when within the fee peroid,
     * since the input ratio will be an average of the pervious periods it just needs to be
     * > recentFeePeriods[periodToInsert].startingDebtIndex
     * < recentFeePeriods[periodToInsert - 1].startingDebtIndex
     */
    function importIssuerData(address[] memory accounts, uint[] memory ratios, uint periodToInsert, uint feePeriodCloseIndex)
        external
        onlyOwner
        onlyDuringSetup
    {
        require(accounts.length == ratios.length, "Length mismatch");

        for (uint8 i = 0; i < accounts.length; i++) {
            accountIssuanceLedger[accounts[i]][periodToInsert].debtPercentage = ratios[i];
            accountIssuanceLedger[accounts[i]][periodToInsert].debtEntryIndex = feePeriodCloseIndex;
            emit IssuanceDebtRatioEntry(accounts[i], ratios[i], feePeriodCloseIndex);
        }
    }

    /* ========== MODIFIERS ========== */

    modifier onlyFeePool
    {
        require(msg.sender == address(feePool), "Only the FeePool contract can perform this action");
        _;
    }

    /* ========== Events ========== */
    event IssuanceDebtRatioEntry(address indexed account, uint debtRatio, uint feePeriodCloseIndex);
}

/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       FeePoolEternalStorage.sol
version:    1.0
author:     Clinton Ennis
            Jackson Chan
date:       2019-04-05

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

The FeePoolEternalStorage is for any state the FeePool contract
needs to persist between upgrades to the FeePool logic.

Please see EternalStorage.sol

-----------------------------------------------------------------
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./LimitedSetup.sol";
import "./EternalStorage.sol";

contract FeePoolEternalStorage is EternalStorage, LimitedSetup {

    bytes32 constant LAST_FEE_WITHDRAWAL = "last_fee_withdrawal";

    /**
     * @dev Constructor.
     * @param _owner The owner of this contract.
     */
    constructor(address _owner, address _feePool)
        EternalStorage(_owner, _feePool)
        LimitedSetup(6 weeks)
    {
    }

    /**
     * @notice Import data from FeePool.lastFeeWithdrawal
     * @dev Only callable by the contract owner, and only for 6 weeks after deployment.
     * @param accounts Array of addresses that have claimed
     * @param feePeriodIDs Array feePeriodIDs with the accounts last claim
     */
    function importFeeWithdrawalData(address[] memory accounts, uint[] memory feePeriodIDs)
        external
        onlyOwner
        onlyDuringSetup
    {
        require(accounts.length == feePeriodIDs.length, "Length mismatch");

        for (uint8 i = 0; i < accounts.length; i++) {
            this.setUIntValue(keccak256(abi.encodePacked(LAST_FEE_WITHDRAWAL, accounts[i])), feePeriodIDs[i]);
        }
    }
}

/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       DelegateApprovals.sol
version:    1.0
author:     Jackson Chan
checked:    Clinton Ennis
date:       2019-05-01

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

The approval state contract is designed to allow a wallet to
authorise another address to perform actions, on a contract,
on their behalf. This could be an automated service
that would help a wallet claim fees / rewards on their behalf.

The concept is similar to the ERC20 interface where a wallet can
approve an authorised party to spend on the authorising party's
behalf in the allowance interface.

Withdrawing approval sets the delegate as false instead of
removing from the approvals list for auditability.

This contract inherits state for upgradeability / associated
contract.

-----------------------------------------------------------------
*/
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


import "./State.sol";

contract DelegateApprovals is State {

    // Approvals - [authoriser][delegate]
    // Each authoriser can have multiple delegates
    mapping(address => mapping(address => bool)) public approval;

    /**
     * @dev Constructor
     * @param _owner The address which controls this contract.
     * @param _associatedContract The contract whose approval state this composes.
     */
    constructor(address _owner, address _associatedContract)
        State(_owner, _associatedContract)
    {}

    function setApproval(address authoriser, address delegate)
        external
        onlyAssociatedContract
    {
        approval[authoriser][delegate] = true;
        emit Approval(authoriser, delegate);
    }

    function withdrawApproval(address authoriser, address delegate)
        external
        onlyAssociatedContract
    {
        delete approval[authoriser][delegate];
        emit WithdrawApproval(authoriser, delegate);
    }

     /* ========== EVENTS ========== */

    event Approval(address indexed authoriser, address delegate);
    event WithdrawApproval(address indexed authoriser, address delegate);
}

/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       Owned.sol
version:    1.1
author:     Anton Jurisevic
            Dominic Romanowski

date:       2018-2-26

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

An Owned contract, to be inherited by other contracts.
Requires its owner to be explicitly set in the constructor.
Provides an onlyOwner access modifier.

To change owner, the current owner must nominate the next owner,
who then has to accept the nomination. The nomination can be
cancelled before it is accepted by the new owner by having the
previous owner change the nomination (setting it to 0).

-----------------------------------------------------------------
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/**
 * @title A contract with an owner.
 * @notice Contract ownership can be transferred by first nominating the new owner,
 * who must then accept the ownership, which prevents accidental incorrect ownership transfers.
 */
contract Owned {
    address public owner;
    address public nominatedOwner;

    /**
     * @dev Owned Constructor
     */
    constructor(address _owner)
    {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    /**
     * @notice Nominate a new owner of this contract.
     * @dev Only the current owner may nominate a new owner.
     */
    function nominateNewOwner(address _owner)
        external
        onlyOwner
    {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    /**
     * @notice Accept the nomination to be owner.
     */
    function acceptOwnership()
        external
    {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner
    {
        require(msg.sender == owner, "Only the contract owner may perform this action");
        _;
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       Proxy.sol
version:    1.3
author:     Anton Jurisevic

date:       2018-05-29

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

A proxy contract that, if it does not recognise the function
being called on it, passes all value and call data to an
underlying target contract.

This proxy has the capacity to toggle between DELEGATECALL
and CALL style proxy functionality.

The former executes in the proxy's context, and so will preserve
msg.sender and store data at the proxy address. The latter will not.
Therefore, any contract the proxy wraps in the CALL style must
implement the Proxyable interface, in order that it can pass msg.sender
into the underlying contract as the state parameter, messageSender.

-----------------------------------------------------------------
*/


//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


import "./Owned.sol";
import "./Proxyable.sol";


contract Proxy is Owned {

    Proxyable public target;
    bool public useDELEGATECALL;

    constructor(address _owner)
        Owned(_owner)
    {}

    function setTarget(Proxyable _target)
        external
        onlyOwner
    {
        target = _target;
        emit TargetUpdated(_target);
    }

    function setUseDELEGATECALL(bool value)
        external
        onlyOwner
    {
        useDELEGATECALL = value;
    }

    function _emit(bytes memory callData, uint numTopics, bytes32 topic1, bytes32 topic2, bytes32 topic3, bytes32 topic4)
        external
        onlyTarget
    {
        uint size = callData.length;
        bytes memory _callData = callData;

        assembly {
            /* The first 32 bytes of callData contain its length (as specified by the abi).
             * Length is assumed to be a uint256 and therefore maximum of 32 bytes
             * in length. It is also leftpadded to be a multiple of 32 bytes.
             * This means moving call_data across 32 bytes guarantees we correctly access
             * the data itself. */
            switch numTopics
            case 0 {
                log0(add(_callData, 32), size)
            }
            case 1 {
                log1(add(_callData, 32), size, topic1)
            }
            case 2 {
                log2(add(_callData, 32), size, topic1, topic2)
            }
            case 3 {
                log3(add(_callData, 32), size, topic1, topic2, topic3)
            }
            case 4 {
                log4(add(_callData, 32), size, topic1, topic2, topic3, topic4)
            }
        }
    }

    fallback()
        external
        payable
    {
        if (useDELEGATECALL) {
            assembly {
                /* Copy call data into free memory region. */
                let free_ptr := mload(0x40)
                calldatacopy(free_ptr, 0, calldatasize())

                /* Forward all gas and call data to the target contract. */
                let result := delegatecall(gas(), sload(target.slot), free_ptr, calldatasize(), 0, 0)
                returndatacopy(free_ptr, 0, returndatasize())

                /* Revert if the call failed, otherwise return the result. */
                if iszero(result) { revert(free_ptr, returndatasize()) }
                return(free_ptr, returndatasize())
            }
        } else {
            /* Here we are as above, but must send the messageSender explicitly
             * since we are using CALL rather than DELEGATECALL. */
            target.setMessageSender(msg.sender);
            assembly {
                let free_ptr := mload(0x40)
                calldatacopy(free_ptr, 0, calldatasize())

                /* We must explicitly forward ether to the underlying contract as well. */
                let result := call(gas(), sload(target.slot), callvalue(), free_ptr, calldatasize(), 0, 0)
                returndatacopy(free_ptr, 0, returndatasize())

                if iszero(result) { revert(free_ptr, returndatasize()) }
                return(free_ptr, returndatasize())
            }
        }
    }

    modifier onlyTarget {
        require(Proxyable(msg.sender) == target, "Must be proxy target");
        _;
    }

    event TargetUpdated(Proxyable newTarget);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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

/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       ExternStateToken.sol
version:    1.3
author:     Anton Jurisevic
            Dominic Romanowski
            Kevin Brown

date:       2018-05-29

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

A partial ERC20 token contract, designed to operate with a proxy.
To produce a complete ERC20 token, transfer and transferFrom
tokens must be implemented, using the provided _byProxy internal
functions.
This contract utilises an external state for upgradeability.

-----------------------------------------------------------------
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./SafeDecimalMath.sol";
import "./SelfDestructible.sol";
import "./TokenState.sol";
import "./Proxyable.sol";
import "./TokenFallbackCaller.sol";

/**
 * @title ERC20 Token contract, with detached state and designed to operate behind a proxy.
 */
contract ExternStateToken is SelfDestructible, Proxyable, TokenFallbackCaller {

    using SafeMath for uint;
    using SafeDecimalMath for uint;

    /* ========== STATE VARIABLES ========== */

    /* Stores balances and allowances. */
    TokenState public tokenState;

    /* Other ERC20 fields. */
    string public name;
    string public symbol;
    uint public totalSupply;
    uint8 public decimals;

    /**
     * @dev Constructor.
     * @param _proxy The proxy associated with this contract.
     * @param _name Token's ERC20 name.
     * @param _symbol Token's ERC20 symbol.
     * @param _totalSupply The total supply of the token.
     * @param _tokenState The TokenState contract address.
     * @param _owner The owner of this contract.
     */
    constructor(address _proxy, TokenState _tokenState,
                string memory _name, string memory _symbol, uint _totalSupply,
                uint8 _decimals, address _owner)
        SelfDestructible(_owner)
        Proxyable(payable(_proxy))
    {
        tokenState = _tokenState;

        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply;
        decimals = _decimals;
    }

    /* ========== VIEWS ========== */

    /**
     * @notice Returns the ERC20 allowance of one party to spend on behalf of another.
     * @param owner The party authorising spending of their funds.
     * @param spender The party spending tokenOwner's funds.
     */
    function allowance(address owner, address spender)
        public
        view
        returns (uint)
    {
        return tokenState.allowance(owner, spender);
    }

    /**
     * @notice Returns the ERC20 token balance of a given account.
     */
    function balanceOf(address account)
        public
        view
        returns (uint)
    {
        return tokenState.balanceOf(account);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Set the address of the TokenState contract.
     * @dev This can be used to "pause" transfer functionality, by pointing the tokenState at 0x000..
     * as balances would be unreachable.
     */ 
    function setTokenState(TokenState _tokenState)
        external
        optionalProxy_onlyOwner
    {
        tokenState = _tokenState;
        emitTokenStateUpdated(address(_tokenState));
    }

    function _internalTransfer(address from, address to, uint value, bytes memory data) 
        internal
        virtual
        returns (bool)
    { 
        /* Disallow transfers to irretrievable-addresses. */
        require(to != address(0), "Cannot transfer to the 0 address");
        require(to != address(this), "Cannot transfer to the underlying contract");
        require(to != address(proxy), "Cannot transfer to the proxy contract");

        // Insufficient balance will be handled by the safe subtraction.
        tokenState.setBalanceOf(from, tokenState.balanceOf(from).sub(value));
        tokenState.setBalanceOf(to, tokenState.balanceOf(to).add(value));

        // If the recipient is a contract, we need to call tokenFallback on it so they can do ERC223
        // actions when receiving our tokens. Unlike the standard, however, we don't revert if the
        // recipient contract doesn't implement tokenFallback.
        callTokenFallbackIfNeeded(from, to, value, data);
        
        // Emit a standard ERC20 transfer event
        emitTransfer(from, to, value);

        return true;
    }

    /**
     * @dev Perform an ERC20 token transfer. Designed to be called by transfer functions possessing
     * the onlyProxy or optionalProxy modifiers.
     */
    function _transfer_byProxy(address from, address to, uint value, bytes memory data)
        internal
        returns (bool)
    {
        return _internalTransfer(from, to, value, data);
    }

    /**
     * @dev Perform an ERC20 token transferFrom. Designed to be called by transferFrom functions
     * possessing the optionalProxy or optionalProxy modifiers.
     */
    function _transferFrom_byProxy(address sender, address from, address to, uint value, bytes memory data)
        internal
        returns (bool)
    {
        /* Insufficient allowance will be handled by the safe subtraction. */
        tokenState.setAllowance(from, sender, tokenState.allowance(from, sender).sub(value));
        return _internalTransfer(from, to, value, data);
    }

    /**
     * @notice Approves spender to transfer on the message sender's behalf.
     */
    function approve(address spender, uint value)
        public
        optionalProxy
        returns (bool)
    {
        address sender = messageSender;

        tokenState.setAllowance(sender, spender, value);
        emitApproval(sender, spender, value);
        return true;
    }

    /* ========== EVENTS ========== */
    function addressToBytes32(address input) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(input)));
    }

    event Transfer(address indexed from, address indexed to, uint value);
    bytes32 constant TRANSFER_SIG = keccak256("Transfer(address,address,uint256)");
    function emitTransfer(address from, address to, uint value) internal {
        proxy._emit(abi.encode(value), 3, TRANSFER_SIG, addressToBytes32(from), addressToBytes32(to), 0);
    }

    event Approval(address indexed owner, address indexed spender, uint value);
    bytes32 constant APPROVAL_SIG = keccak256("Approval(address,address,uint256)");
    function emitApproval(address owner, address spender, uint value) internal {
        proxy._emit(abi.encode(value), 3, APPROVAL_SIG, addressToBytes32(owner), addressToBytes32(spender), 0);
    }

    event TokenStateUpdated(address newTokenState);
    bytes32 constant TOKENSTATEUPDATED_SIG = keccak256("TokenStateUpdated(address)");
    function emitTokenStateUpdated(address newTokenState) internal {
        proxy._emit(abi.encode(newTokenState), 1, TOKENSTATEUPDATED_SIG, 0, 0, 0);
    }
}

/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       TokenState.sol
version:    1.1
author:     Dominic Romanowski
            Anton Jurisevic

date:       2018-05-15

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

A contract that holds the state of an ERC20 compliant token.

This contract is used side by side with external state token
contracts, such as Synthetix and Synth.
It provides an easy way to upgrade contract logic while
maintaining all user balances and allowances. This is designed
to make the changeover as easy as possible, since mappings
are not so cheap or straightforward to migrate.

The first deployed contract would create this state contract,
using it as its store of balances.
When a new contract is deployed, it links to the existing
state contract, whose owner would then change its associated
contract to the new one.

-----------------------------------------------------------------
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


import "./State.sol";

/**
 * @title ERC20 Token State
 * @notice Stores balance information of an ERC20 token contract.
 */
contract TokenState is State {

    /* ERC20 fields. */
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    /**
     * @dev Constructor
     * @param _owner The address which controls this contract.
     * @param _associatedContract The ERC20 contract whose state this composes.
     */
    constructor(address _owner, address _associatedContract)
        State(_owner, _associatedContract)
    {}

    /* ========== SETTERS ========== */

    /**
     * @notice Set ERC20 allowance.
     * @dev Only the associated contract may call this.
     * @param tokenOwner The authorising party.
     * @param spender The authorised party.
     * @param value The total value the authorised party may spend on the
     * authorising party's behalf.
     */
    function setAllowance(address tokenOwner, address spender, uint value)
        external
        onlyAssociatedContract
    {
        allowance[tokenOwner][spender] = value;
    }

    /**
     * @notice Set the balance in a given account
     * @dev Only the associated contract may call this.
     * @param account The account whose value to set.
     * @param value The new balance of the given account.
     */
    function setBalanceOf(address account, uint value)
        external
        onlyAssociatedContract
    {
        balanceOf[account] = value;
    }
}

/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       SupplySchedule.sol
version:    1.0
author:     Jackson Chan
            Clinton Ennis
date:       2019-03-01

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

Supply Schedule contract. SNX is a transferable ERC20 token.

User's get staking rewards as part of the incentives of
+------+-------------+--------------+----------+
| Year |  Increase   | Total Supply | Increase |
+------+-------------+--------------+----------+
|    1 |           0 |  100,000,000 |          |
|    2 |  75,000,000 |  175,000,000 | 75%      |
|    3 |  37,500,000 |  212,500,000 | 21%      |
|    4 |  18,750,000 |  231,250,000 | 9%       |
|    5 |   9,375,000 |  240,625,000 | 4%       |
|    6 |   4,687,500 |  245,312,500 | 2%       |
+------+-------------+--------------+----------+


-----------------------------------------------------------------
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./SafeDecimalMath.sol";
import "./Owned.sol";
import "./Synthetix.sol";

/**
 * @title SupplySchedule contract
 */
contract SupplySchedule is Owned {
    using SafeMath for uint;
    using SafeDecimalMath for uint;

    /* Storage */
    struct ScheduleData {
        // Total supply issuable during period
        uint totalSupply;

        // UTC Time - Start of the schedule
        uint startPeriod;

        // UTC Time - End of the schedule
        uint endPeriod;

        // UTC Time - Total of supply minted
        uint totalSupplyMinted;
    }

    // How long each mint period is
    uint public mintPeriodDuration = 1 weeks;

    // time supply last minted
    uint public lastMintEvent;

    Synthetix public synthetix;

    uint constant SECONDS_IN_YEAR = 60 * 60 * 24 * 365;

    uint public constant START_DATE = 1520294400; // 2018-03-06T00:00:00+00:00
    uint public constant YEAR_ONE = START_DATE + 60 * 60 * 24 * 365 * 1;
    uint public constant YEAR_TWO = START_DATE + 60 * 60 * 24 * 365 * 2;
    uint public constant YEAR_THREE = START_DATE + 60 * 60 * 24 * 365 * 3;
    uint public constant YEAR_FOUR = START_DATE + 60 * 60 * 24 * 365 * 4;
    uint public constant YEAR_FIVE = START_DATE + 60 * 60 * 24 * 365 * 5;
    uint public constant YEAR_SIX = START_DATE + 60 * 60 * 24 * 365 * 6;
    uint public constant YEAR_SEVEN = START_DATE + 60 * 60 * 24 * 365 * 7;

    uint8 constant public INFLATION_SCHEDULES_LENGTH = 7;
    ScheduleData[INFLATION_SCHEDULES_LENGTH] public schedules;

    uint public minterReward = 200 * SafeDecimalMath.unit();

    constructor(address _owner)
        Owned(_owner)
    {
        // ScheduleData(totalSupply, startPeriod, endPeriod, totalSupplyMinted)
        // Year 1 - Total supply 100,000,000
        schedules[0] = ScheduleData(1e8 * SafeDecimalMath.unit(), START_DATE, YEAR_ONE - 1, 1e8 * SafeDecimalMath.unit());
        schedules[1] = ScheduleData(75e6 * SafeDecimalMath.unit(), YEAR_ONE, YEAR_TWO - 1, 0); // Year 2 - Total supply 175,000,000
        schedules[2] = ScheduleData(37.5e6 * SafeDecimalMath.unit(), YEAR_TWO, YEAR_THREE - 1, 0); // Year 3 - Total supply 212,500,000
        schedules[3] = ScheduleData(18.75e6 * SafeDecimalMath.unit(), YEAR_THREE, YEAR_FOUR - 1, 0); // Year 4 - Total supply 231,250,000
        schedules[4] = ScheduleData(9.375e6 * SafeDecimalMath.unit(), YEAR_FOUR, YEAR_FIVE - 1, 0); // Year 5 - Total supply 240,625,000
        schedules[5] = ScheduleData(4.6875e6 * SafeDecimalMath.unit(), YEAR_FIVE, YEAR_SIX - 1, 0); // Year 6 - Total supply 245,312,500
        schedules[6] = ScheduleData(0, YEAR_SIX, YEAR_SEVEN - 1, 0); // Year 7 - Total supply 245,312,500
    }

    // ========== SETTERS ========== */
    function setSynthetix(Synthetix _synthetix)
        external
        onlyOwner
    {
        synthetix = _synthetix;
        // emit event
    }

    // ========== VIEWS ==========
    function mintableSupply()
        public
        view
        returns (uint)
    {
        if (!isMintable()) {
            return 0;
        }

        uint index = getCurrentSchedule();

        // Calculate previous year's mintable supply
        uint amountPreviousPeriod = _remainingSupplyFromPreviousYear(index);

        /* solium-disable */

        // Last mint event within current period will use difference in (block.timestamp - lastMintEvent)
        // Last mint event not set (0) / outside of current Period will use current Period
        // start time resolved in (block.timestamp - schedule.startPeriod)
        ScheduleData memory schedule = schedules[index];

        uint weeksInPeriod = (schedule.endPeriod - schedule.startPeriod).div(mintPeriodDuration);

        uint supplyPerWeek = schedule.totalSupply.divideDecimal(weeksInPeriod);

        uint weeksToMint = lastMintEvent >= schedule.startPeriod ? _numWeeksRoundedDown(block.timestamp.sub(lastMintEvent)) : _numWeeksRoundedDown(block.timestamp.sub(schedule.startPeriod));
        // /* solium-enable */

        uint amountInPeriod = supplyPerWeek.multiplyDecimal(weeksToMint);
        return amountInPeriod.add(amountPreviousPeriod);
    }

    function _numWeeksRoundedDown(uint _timeDiff)
        public
        view
        returns (uint)
    {
        // Take timeDiff in seconds (Dividend) and mintPeriodDuration as (Divisor)
        // Calculate the numberOfWeeks since last mint rounded down to 1 week
        // Fraction of a week will return 0
        return _timeDiff.div(mintPeriodDuration);
    }

    function isMintable()
        public
        view
        returns (bool)
    {
        bool mintable = false;
        if (block.timestamp - lastMintEvent > mintPeriodDuration && block.timestamp <= schedules[6].endPeriod) // Ensure time is not after end of Year 7
        {
            mintable = true;
        }
        return mintable;
    }

    // Return the current schedule based on the timestamp
    // applicable based on startPeriod and endPeriod
    function getCurrentSchedule()
        public
        view
        returns (uint)
    {
        require(block.timestamp <= schedules[6].endPeriod, "Mintable periods have ended");

        for (uint i = 0; i < INFLATION_SCHEDULES_LENGTH; i++) {
            if (schedules[i].startPeriod <= block.timestamp && schedules[i].endPeriod >= block.timestamp) {
                return i;
            }
        }
    }

    function _remainingSupplyFromPreviousYear(uint currentSchedule)
        internal
        view
        returns (uint)
    {
        // All supply has been minted for previous period if last minting event is after
        // the endPeriod for last year
        if (currentSchedule == 0 || lastMintEvent > schedules[currentSchedule - 1].endPeriod) {
            return 0;
        }

        // return the remaining supply to be minted for previous period missed
        uint amountInPeriod = schedules[currentSchedule - 1].totalSupply.sub(schedules[currentSchedule - 1].totalSupplyMinted);

        // Ensure previous period remaining amount is not less than 0
        if (amountInPeriod < 0) {
            return 0;
        }

        return amountInPeriod;
    }

    // ========== MUTATIVE FUNCTIONS ==========
    function updateMintValues()
        external
        onlySynthetix
        returns (bool)
    {
        // Will fail if the time is outside of schedules
        uint currentIndex = getCurrentSchedule();
        uint lastPeriodAmount = _remainingSupplyFromPreviousYear(currentIndex);
        uint currentPeriodAmount = mintableSupply().sub(lastPeriodAmount);

        // Update schedule[n - 1].totalSupplyMinted
        if (lastPeriodAmount > 0) {
            schedules[currentIndex - 1].totalSupplyMinted = schedules[currentIndex - 1].totalSupplyMinted.add(lastPeriodAmount);
        }

        // Update schedule.totalSupplyMinted for currentSchedule
        schedules[currentIndex].totalSupplyMinted = schedules[currentIndex].totalSupplyMinted.add(currentPeriodAmount);
        // Update mint event to now
        lastMintEvent = block.timestamp;

        emit SupplyMinted(lastPeriodAmount, currentPeriodAmount, currentIndex, block.timestamp);
        return true;
    }

    function setMinterReward(uint _amount)
        external
        onlyOwner
    {
        minterReward = _amount;
        emit MinterRewardUpdated(_amount);
    }

    // ========== MODIFIERS ==========

    modifier onlySynthetix() {
        require(msg.sender == address(synthetix), "Only the synthetix contract can perform this action");
        _;
    }

    /* ========== EVENTS ========== */

    event SupplyMinted(uint previousPeriodAmount, uint currentAmount, uint indexed schedule, uint timestamp);
    event MinterRewardUpdated(uint newRewardAmount);
}

/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       ExchangeRates.sol
version:    1.0
author:     Kevin Brown
date:       2018-09-12

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

A contract that any other contract in the Synthetix system can query
for the current market value of various assets, including
crypto assets as well as various fiat assets.

This contract assumes that rate updates will completely update
all rates to their current values. If a rate shock happens
on a single asset, the oracle will still push updated rates
for all other assets.

-----------------------------------------------------------------
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./SafeDecimalMath.sol";
import "./SelfDestructible.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol"; // technically this is all we need


/**
 * @title The repository for exchange rates
 */
contract ExchangeRates is ChainlinkClient, SelfDestructible {
    using Chainlink for Chainlink.Request;

    using SafeMath for uint;
    using SafeDecimalMath for uint;

    // Exchange rates stored by currency code, e.g. 'SNX', or 'sUSD'
    mapping(bytes4 => uint) public rates;

    // Update times stored by currency code, e.g. 'SNX', or 'sUSD'
    mapping(bytes4 => uint) public lastRateUpdateTimes;

    // The address of the SNX oracle which pushes rate updates to this contract
    address public snxOracle;

    // Do not allow the oracle to submit times any further forward into the future than this constant.
    uint constant ORACLE_FUTURE_LIMIT = 10 minutes;

    // How long will the contract assume the rate of any asset is correct
    uint public rateStalePeriod = 3 hours;

    // Each participating currency in the XDR basket is represented as a currency key with
    // equal weighting.
    // There are 5 participating currencies, so we'll declare that clearly.
    bytes4[5] public xdrParticipants;

    // -----------------
    // Chainlink properties
    struct Request {
        uint256 timestamp;
        bytes4 currencyKey;
    }

    bytes32 public oracleJobId;
    uint256 constant private ORACLE_PAYMENT = 1 * 10 ** 18; // solium-disable-line zeppelin/no-arithmetic-operations
    mapping(bytes32 => Request) private requests;
    uint256 constant ORACLE_PRECISION = 1000000000000000000;
    // ------------------
    // For inverted prices, keep a mapping of their entry, limits and frozen status
    struct InversePricing {
        uint entryPoint;
        uint upperLimit;
        uint lowerLimit;
        bool frozen;
    }
    mapping(bytes4 => InversePricing) public inversePricing;
    bytes4[] public invertedKeys;

    //
    // ========== CONSTRUCTOR ==========

    /**
     * @dev Constructor
     * @param _owner The owner of this contract.
     * @param _snxOracle The address which is able to update rate information.
     * @param _currencyKeys The initial currency keys to store (in order).
     * @param _newRates The initial currency amounts for each currency (in order).
     */
    constructor(
        // SelfDestructible (Ownable)
        address _owner,

        // Oracle values - Allows for rate updates
        address _snxOracle,
        bytes4[] memory _currencyKeys,
        uint[] memory _newRates,

        // Chainlink requirementss
        address _chainlinkToken,
        address _chainlinkOracle,
        bytes32 _chainlinkJobId
    )
        /* Owned is initialised in SelfDestructible */
        SelfDestructible(_owner)
    {
        require(_currencyKeys.length == _newRates.length, "Currency key length and rate length must match.");

        snxOracle = _snxOracle;

        // The sUSD rate is always 1 and is never stale.
        rates["sUSD"] = SafeDecimalMath.unit();
        lastRateUpdateTimes["sUSD"] = block.timestamp;

        // These are the currencies that make up the XDR basket.
        // These are hard coded because:
        //  - This way users can depend on the calculation and know it won't change for this deployment of the contract.
        //  - Adding new currencies would likely introduce some kind of weighting factor, which
        //    isn't worth preemptively adding when all of the currencies in the current basket are weighted at 1.
        //  - The expectation is if this logic needs to be updated, we'll simply deploy a new version of this contract
        //    then point the system at the new version.
        xdrParticipants = [
            bytes4("sUSD"),
            bytes4("sAUD"),
            bytes4("sCHF"),
            bytes4("sEUR"),
            bytes4("sGBP")
        ];

        internalUpdateRates(_currencyKeys, _newRates, block.timestamp);

        // Setup Chainlink props
        setChainlinkToken(_chainlinkToken);
        setChainlinkOracle(_chainlinkOracle);
        oracleJobId = _chainlinkJobId;
    }

    /* ========== SETTERS ========== */

    /**
     * @notice Set the rates stored in this contract
     * @param currencyKeys The currency keys you wish to update the rates for (in order)
     * @param newRates The rates for each currency (in order)
     * @param timeSent The timestamp of when the update was sent, specified in seconds since epoch (e.g. the same as the now keyword in solidity).contract
     *                 This is useful because transactions can take a while to confirm, so this way we know how old the oracle's datapoint was exactly even
     *                 if it takes a long time for the transaction to confirm.
     */
    function updateRates(bytes4[] memory currencyKeys, uint[] memory newRates, uint timeSent)
        external
        onlySNXOracle
        returns(bool)
    {
        return internalUpdateRates(currencyKeys, newRates, timeSent);
    }

    /**
     * @notice Internal function which sets the rates stored in this contract
     * @param currencyKeys The currency keys you wish to update the rates for (in order)
     * @param newRates The rates for each currency (in order)
     * @param timeSent The timestamp of when the update was sent, specified in seconds since epoch (e.g. the same as the now keyword in solidity).contract
     *                 This is useful because transactions can take a while to confirm, so this way we know how old the oracle's datapoint was exactly even
     *                 if it takes a long time for the transaction to confirm.
     */
    function internalUpdateRates(bytes4[] memory currencyKeys, uint[] memory newRates, uint timeSent)
        internal
        returns(bool)
    {
        require(currencyKeys.length == newRates.length, "Currency key array length must match rates array length.");
        require(timeSent < (block.timestamp + ORACLE_FUTURE_LIMIT), "Time is too far into the future");

        // Loop through each key and perform update.
        for (uint i = 0; i < currencyKeys.length; i++) {
            // Should not set any rate to zero ever, as no asset will ever be
            // truely worthless and still valid. In this scenario, we should
            // delete the rate and remove it from the system.
            require(newRates[i] != 0, "Zero is not a valid rate, please call deleteRate instead.");
            require(currencyKeys[i] != "sUSD", "Rate of sUSD cannot be updated, it's always UNIT.");

            // We should only update the rate if it's at least the same age as the last rate we've got.
            if (timeSent < lastRateUpdateTimes[currencyKeys[i]]) {
                continue;
            }

            newRates[i] = rateOrInverted(currencyKeys[i], newRates[i]);

            // Ok, go ahead with the update.
            rates[currencyKeys[i]] = newRates[i];
            lastRateUpdateTimes[currencyKeys[i]] = timeSent;
        }

        emit RatesUpdated(currencyKeys, newRates);

        // Now update our XDR rate.
        updateXDRRate(timeSent);

        return true;
    }

    /**
     * @notice Internal function to get the inverted rate, if any, and mark an inverted
     *  key as frozen if either limits are reached.
     * @param currencyKey The price key to lookup
     * @param rate The rate for the given price key
     */
    function rateOrInverted(bytes4 currencyKey, uint rate) internal returns (uint) {
        // if an inverse mapping exists, adjust the price accordingly
        InversePricing storage inverse = inversePricing[currencyKey];
        if (inverse.entryPoint <= 0) {
            return rate;
        }

        // set the rate to the current rate initially (if it's frozen, this is what will be returned)
        uint newInverseRate = rates[currencyKey];

        // get the new inverted rate if not frozen
        if (!inverse.frozen) {
            uint doubleEntryPoint = inverse.entryPoint.mul(2);
            if (doubleEntryPoint <= rate) {
                // avoid negative numbers for unsigned ints, so set this to 0
                // which by the requirement that lowerLimit be > 0 will
                // cause this to freeze the price to the lowerLimit
                newInverseRate = 0;
            } else {
                newInverseRate = doubleEntryPoint.sub(rate);
            }

            // now if new rate hits our limits, set it to the limit and freeze
            if (newInverseRate >= inverse.upperLimit) {
                newInverseRate = inverse.upperLimit;
            } else if (newInverseRate <= inverse.lowerLimit) {
                newInverseRate = inverse.lowerLimit;
            }

            if (newInverseRate == inverse.upperLimit || newInverseRate == inverse.lowerLimit) {
                inverse.frozen = true;
                emit InversePriceFrozen(currencyKey);
            }
        }

        return newInverseRate;
    }

    /**
     * @notice Update the Synthetix Drawing Rights exchange rate based on other rates already updated.
     */
    function updateXDRRate(uint timeSent)
        internal
    {
        uint total = 0;

        for (uint i = 0; i < xdrParticipants.length; i++) {
            total = rates[xdrParticipants[i]].add(total);
        }

        // Set the rate
        rates["XDR"] = total;

        // Record that we updated the XDR rate.
        lastRateUpdateTimes["XDR"] = timeSent;

        // Emit our updated event separate to the others to save
        // moving data around between arrays.
        bytes4[] memory eventCurrencyCode = new bytes4[](1);
        eventCurrencyCode[0] = "XDR";

        uint[] memory eventRate = new uint[](1);
        eventRate[0] = rates["XDR"];

        emit RatesUpdated(eventCurrencyCode, eventRate);
    }

    /**
     * @notice Delete a rate stored in the contract
     * @param currencyKey The currency key you wish to delete the rate for
     */
    function deleteRate(bytes4 currencyKey)
        external
        onlySNXOracle
    {
        require(rates[currencyKey] > 0, "Rate is zero");

        delete rates[currencyKey];
        delete lastRateUpdateTimes[currencyKey];

        emit RateDeleted(currencyKey);
    }

    /**
     * @notice Set the Oracle that pushes the rate information to this contract
     * @param _snxOracle The new oracle address
     */
    function setSNXOracle(address _snxOracle)
        external
        onlyOwner
    {
        snxOracle = _snxOracle;
        emit OracleUpdated(snxOracle);
    }

    /**
     * @notice Set the stale period on the updated rate variables
     * @param _time The new rateStalePeriod
     */
    function setRateStalePeriod(uint _time)
        external
        onlyOwner
    {
        rateStalePeriod = _time;
        emit RateStalePeriodUpdated(rateStalePeriod);
    }

    /**
     * @notice Set an inverse price up for the currency key
     * @param currencyKey The currency to update
     * @param entryPoint The entry price point of the inverted price
     * @param upperLimit The upper limit, at or above which the price will be frozen
     * @param lowerLimit The lower limit, at or below which the price will be frozen
     */
    function setInversePricing(bytes4 currencyKey, uint entryPoint, uint upperLimit, uint lowerLimit)
        external onlyOwner
    {
        require(entryPoint > 0, "entryPoint must be above 0");
        require(lowerLimit > 0, "lowerLimit must be above 0");
        require(upperLimit > entryPoint, "upperLimit must be above the entryPoint");
        require(upperLimit < entryPoint.mul(2), "upperLimit must be less than double entryPoint");
        require(lowerLimit < entryPoint, "lowerLimit must be below the entryPoint");

        if (inversePricing[currencyKey].entryPoint <= 0) {
            // then we are adding a new inverse pricing, so add this
            invertedKeys.push(currencyKey);
        }
        inversePricing[currencyKey].entryPoint = entryPoint;
        inversePricing[currencyKey].upperLimit = upperLimit;
        inversePricing[currencyKey].lowerLimit = lowerLimit;
        inversePricing[currencyKey].frozen = false;

        emit InversePriceConfigured(currencyKey, entryPoint, upperLimit, lowerLimit);
    }

    /**
     * @notice Remove an inverse price for the currency key
     * @param currencyKey The currency to remove inverse pricing for
     */
    function removeInversePricing(bytes4 currencyKey) external onlyOwner {
        inversePricing[currencyKey].entryPoint = 0;
        inversePricing[currencyKey].upperLimit = 0;
        inversePricing[currencyKey].lowerLimit = 0;
        inversePricing[currencyKey].frozen = false;

        // now remove inverted key from array
        for (uint8 i = 0; i < invertedKeys.length; i++) {
            if (invertedKeys[i] == currencyKey) {
                delete invertedKeys[i];

                // Copy the last key into the place of the one we just deleted
                // If there's only one key, this is array[0] = array[0].
                // If we're deleting the last one, it's also a NOOP in the same way.
                invertedKeys[i] = invertedKeys[invertedKeys.length - 1];

                // Decrease the size of the array by one.
                invertedKeys.pop();

                break;
            }
        }

        emit InversePriceConfigured(currencyKey, 0, 0, 0);
    }
    /* ========== VIEWS ========== */

    /**
     * @notice A function that lets you easily convert an amount in a source currency to an amount in the destination currency
     * @param sourceCurrencyKey The currency the amount is specified in
     * @param sourceAmount The source amount, specified in UNIT base
     * @param destinationCurrencyKey The destination currency
     */
    function effectiveValue(bytes4 sourceCurrencyKey, uint sourceAmount, bytes4 destinationCurrencyKey)
        public
        view
        rateNotStale(sourceCurrencyKey)
        rateNotStale(destinationCurrencyKey)
        returns (uint)
    {
        // If there's no change in the currency, then just return the amount they gave us
        if (sourceCurrencyKey == destinationCurrencyKey) return sourceAmount;

        // Calculate the effective value by going from source -> USD -> destination
        return sourceAmount.multiplyDecimalRound(rateForCurrency(sourceCurrencyKey))
            .divideDecimalRound(rateForCurrency(destinationCurrencyKey));
    }

    /**
     * @notice Retrieve the rate for a specific currency
     */
    function rateForCurrency(bytes4 currencyKey)
        public
        view
        returns (uint)
    {
        return rates[currencyKey];
    }

    /**
     * @notice Retrieve the rates for a list of currencies
     */
    function ratesForCurrencies(bytes4[] memory currencyKeys)
        public
        view
        returns (uint[] memory)
    {
        uint[] memory _rates = new uint[](currencyKeys.length);

        for (uint8 i = 0; i < currencyKeys.length; i++) {
            _rates[i] = rates[currencyKeys[i]];
        }

        return _rates;
    }

    /**
     * @notice Retrieve a list of last update times for specific currencies
     */
    function lastRateUpdateTimeForCurrency(bytes4 currencyKey)
        public
        view
        returns (uint)
    {
        return lastRateUpdateTimes[currencyKey];
    }

    /**
     * @notice Retrieve the last update time for a specific currency
     */
    function lastRateUpdateTimesForCurrencies(bytes4[] memory currencyKeys)
        public
        view
        returns (uint[] memory)
    {
        uint[] memory lastUpdateTimes = new uint[](currencyKeys.length);

        for (uint8 i = 0; i < currencyKeys.length; i++) {
            lastUpdateTimes[i] = lastRateUpdateTimes[currencyKeys[i]];
        }

        return lastUpdateTimes;
    }

    /**
     * @notice Check if a specific currency's rate hasn't been updated for longer than the stale period.
     */
    function rateIsStale(bytes4 currencyKey)
        public
        view
        returns (bool)
    {
        // sUSD is a special case and is never stale.
        if (currencyKey == "sUSD") return false;

        return lastRateUpdateTimes[currencyKey].add(rateStalePeriod) < block.timestamp;
    }

    /**
     * @notice Check if any rate is frozen (cannot be exchanged into)
     */
    function rateIsFrozen(bytes4 currencyKey)
        external
        view
        returns (bool)
    {
        return inversePricing[currencyKey].frozen;
    }


    /**
     * @notice Check if any of the currency rates passed in haven't been updated for longer than the stale period.
     */
    function anyRateIsStale(bytes4[] memory currencyKeys)
        external
        view
        returns (bool)
    {
        // Loop through each key and check whether the data point is stale.
        uint256 i = 0;

        while (i < currencyKeys.length) {
            // sUSD is a special case and is never false
            if (currencyKeys[i] != "sUSD" && lastRateUpdateTimes[currencyKeys[i]].add(rateStalePeriod) < block.timestamp) {
                return true;
            }
            i += 1;
        }

        return false;
    }

    // CHAINLINK ///
    /**
     * @notice Initiatiate a price request via chainlink. Provide both the
     * bytes4 currencyKey (for SNX) and the string representation (for Chainlink)
     */
    function requestCryptoPrice(bytes4 currencyKey, string memory asset)
    public
    onlyOwner
    {
        Chainlink.Request memory req = buildChainlinkRequest(oracleJobId, address(this), this.fulfill.selector);
        req.add("sym", asset);
        req.add("convert", "USD");
        string[] memory path = new string[](5);
        path[0] = "data";
        path[1] = asset;
        path[2] = "quote";
        path[3] = "USD";
        path[4] = "price";
        req.addStringArray("copyPath", path);
        req.addInt("times", int256(ORACLE_PRECISION));

        requests[sendChainlinkRequest(req, ORACLE_PAYMENT)] = Request(block.timestamp, currencyKey);
    }

    function fulfill(bytes32 _requestId, uint256 _price)
      public
      validateTimestamp(_requestId)
      recordChainlinkFulfillment(_requestId)
    {
        bytes4 currencyKey = requests[_requestId].currencyKey;
        uint timestamp = requests[_requestId].timestamp;
        bytes4[] memory ccy = new bytes4[](1);
        ccy[0] = currencyKey;
        uint[] memory newRates = new uint[](1);
        newRates[0] = _price;
        internalUpdateRates(ccy, newRates, timestamp);
        delete requests[_requestId];
    }

    function getChainlinkToken() public view returns (address) {
        return chainlinkTokenAddress();
    }

    function getOracle() public view returns (address) {
        return chainlinkOracleAddress();
    }

    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
    }

    modifier validateTimestamp(bytes32 _requestId) {
        require(requests[_requestId].timestamp > block.timestamp - ORACLE_FUTURE_LIMIT, "Request has expired");
        _;
    }
    ////////////

    /* ========== MODIFIERS ========== */
    modifier rateNotStale(bytes4 currencyKey) {
        require(!rateIsStale(currencyKey), "Rate stale or nonexistant currency");
        _;
    }

    modifier onlySNXOracle
    {
        require(msg.sender == snxOracle, "Only the oracle can perform this action");
        _;
    }

    /* ========== EVENTS ========== */

    event OracleUpdated(address newOracle);
    event RateStalePeriodUpdated(uint rateStalePeriod);
    event RatesUpdated(bytes4[] currencyKeys, uint[] newRates);
    event RateDeleted(bytes4 currencyKey);
    event InversePriceConfigured(bytes4 currencyKey, uint entryPoint, uint upperLimit, uint lowerLimit);
    event InversePriceFrozen(bytes4 currencyKey);
}

/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       SynthetixState.sol
version:    1.0
author:     Kevin Brown
date:       2018-10-19

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

A contract that holds issuance state and preferred currency of
users in the Synthetix system.

This contract is used side by side with the Synthetix contract
to make it easier to upgrade the contract logic while maintaining
issuance state.

The Synthetix contract is also quite large and on the edge of
being beyond the contract size limit without moving this information
out to another contract.

The first deployed contract would create this state contract,
using it as its store of issuance data.

When a new contract is deployed, it links to the existing
state contract, whose owner would then change its associated
contract to the new one.

-----------------------------------------------------------------
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Synthetix.sol";
import "./LimitedSetup.sol";
import "./SafeDecimalMath.sol";
import "./State.sol";

/**
 * @title Synthetix State
 * @notice Stores issuance information and preferred currency information of the Synthetix contract.
 */
contract SynthetixState is State, LimitedSetup {
    using SafeMath for uint;
    using SafeDecimalMath for uint;

    // A struct for handing values associated with an individual user's debt position
    struct IssuanceData {
        // Percentage of the total debt owned at the time
        // of issuance. This number is modified by the global debt
        // delta array. You can figure out a user's exit price and
        // collateralisation ratio using a combination of their initial
        // debt and the slice of global debt delta which applies to them.
        uint initialDebtOwnership;
        // This lets us know when (in relative terms) the user entered
        // the debt pool so we can calculate their exit price and
        // collateralistion ratio
        uint debtEntryIndex;
    }

    // Issued synth balances for individual fee entitlements and exit price calculations
    mapping(address => IssuanceData) public issuanceData;

    // The total count of people that have outstanding issued synths in any flavour
    uint public totalIssuerCount;

    // Global debt pool tracking
    uint[] public debtLedger;

    // Import state
    uint public importedXDRAmount;

    // A quantity of synths greater than this ratio
    // may not be issued against a given value of SNX.
    uint public issuanceRatio = SafeDecimalMath.unit() / 5;
    // No more synths may be issued than the value of SNX backing them.
    uint public MAX_ISSUANCE_RATIO = SafeDecimalMath.unit();

    // Users can specify their preferred currency, in which case all synths they receive
    // will automatically exchange to that preferred currency upon receipt in their wallet
    mapping(address => bytes4) public preferredCurrency;

    /**
     * @dev Constructor
     * @param _owner The address which controls this contract.
     * @param _associatedContract The ERC20 contract whose state this composes.
     */
    constructor(address _owner, address _associatedContract)
        State(_owner, _associatedContract)
        LimitedSetup(1 weeks)
    {}

    /* ========== SETTERS ========== */

    /**
     * @notice Set issuance data for an address
     * @dev Only the associated contract may call this.
     * @param account The address to set the data for.
     * @param initialDebtOwnership The initial debt ownership for this address.
     */
    function setCurrentIssuanceData(address account, uint initialDebtOwnership)
        external
        onlyAssociatedContract
    {
        issuanceData[account].initialDebtOwnership = initialDebtOwnership;
        issuanceData[account].debtEntryIndex = debtLedger.length;
    }

    /**
     * @notice Clear issuance data for an address
     * @dev Only the associated contract may call this.
     * @param account The address to clear the data for.
     */
    function clearIssuanceData(address account)
        external
        onlyAssociatedContract
    {
        delete issuanceData[account];
    }

    /**
     * @notice Increment the total issuer count
     * @dev Only the associated contract may call this.
     */
    function incrementTotalIssuerCount()
        external
        onlyAssociatedContract
    {
        totalIssuerCount = totalIssuerCount.add(1);
    }

    /**
     * @notice Decrement the total issuer count
     * @dev Only the associated contract may call this.
     */
    function decrementTotalIssuerCount()
        external
        onlyAssociatedContract
    {
        totalIssuerCount = totalIssuerCount.sub(1);
    }

    /**
     * @notice Append a value to the debt ledger
     * @dev Only the associated contract may call this.
     * @param value The new value to be added to the debt ledger.
     */
    function appendDebtLedgerValue(uint value)
        external
        onlyAssociatedContract
    {
        debtLedger.push(value);
    }

    /**
     * @notice Set preferred currency for a user
     * @dev Only the associated contract may call this.
     * @param account The account to set the preferred currency for
     * @param currencyKey The new preferred currency
     */
    function setPreferredCurrency(address account, bytes4 currencyKey)
        external
        onlyAssociatedContract
    {
        preferredCurrency[account] = currencyKey;
    }

    /**
     * @notice Set the issuanceRatio for issuance calculations.
     * @dev Only callable by the contract owner.
     */
    function setIssuanceRatio(uint _issuanceRatio)
        external
        onlyOwner
    {
        require(_issuanceRatio <= MAX_ISSUANCE_RATIO, "New issuance ratio cannot exceed MAX_ISSUANCE_RATIO");
        issuanceRatio = _issuanceRatio;
        emit IssuanceRatioUpdated(_issuanceRatio);
    }

    /**
     * @notice Import issuer data from the old Synthetix contract before multicurrency
     * @dev Only callable by the contract owner, and only for 1 week after deployment.
     */
    function importIssuerData(address[] memory accounts, uint[] memory sUSDAmounts)
        external
        onlyOwner
        onlyDuringSetup
    {
        require(accounts.length == sUSDAmounts.length, "Length mismatch");

        for (uint8 i = 0; i < accounts.length; i++) {
            _addToDebtRegister(accounts[i], sUSDAmounts[i]);
        }
    }

    /**
     * @notice Import issuer data from the old Synthetix contract before multicurrency
     * @dev Only used from importIssuerData above, meant to be disposable
     */
    function _addToDebtRegister(address account, uint amount)
        internal
    {
        // This code is duplicated from Synthetix so that we can call it directly here
        // during setup only.
        Synthetix synthetix = Synthetix(associatedContract);

        // What is the value of the requested debt in XDRs?
        uint xdrValue = synthetix.effectiveValue("sUSD", amount, "XDR");

        // What is the value that we've previously imported?
        uint totalDebtIssued = importedXDRAmount;

        // What will the new total be including the new value?
        uint newTotalDebtIssued = xdrValue.add(totalDebtIssued);

        // Save that for the next import.
        importedXDRAmount = newTotalDebtIssued;

        // What is their percentage (as a high precision int) of the total debt?
        uint debtPercentage = xdrValue.divideDecimalRoundPrecise(newTotalDebtIssued);

        // And what effect does this percentage have on the global debt holding of other issuers?
        // The delta specifically needs to not take into account any existing debt as it's already
        // accounted for in the delta from when they issued previously.
        // The delta is a high precision integer.
        uint delta = SafeDecimalMath.preciseUnit().sub(debtPercentage);

        uint existingDebt = synthetix.debtBalanceOf(account, "XDR");

        // And what does their debt ownership look like including this previous stake?
        if (existingDebt > 0) {
            debtPercentage = xdrValue.add(existingDebt).divideDecimalRoundPrecise(newTotalDebtIssued);
        }

        // Are they a new issuer? If so, record them.
        if (issuanceData[account].initialDebtOwnership == 0) {
            totalIssuerCount = totalIssuerCount.add(1);
        }

        // Save the debt entry parameters
        issuanceData[account].initialDebtOwnership = debtPercentage;
        issuanceData[account].debtEntryIndex = debtLedger.length;

        // And if we're the first, push 1 as there was no effect to any other holders, otherwise push
        // the change for the rest of the debt holders. The debt ledger holds high precision integers.
        if (debtLedger.length > 0) {
            debtLedger.push(
                debtLedger[debtLedger.length - 1].multiplyDecimalRoundPrecise(delta)
            );
        } else {
            debtLedger.push(SafeDecimalMath.preciseUnit());
        }
    }

    /* ========== VIEWS ========== */

    /**
     * @notice Retrieve the length of the debt ledger array
     */
    function debtLedgerLength()
        external
        view
        returns (uint)
    {
        return debtLedger.length;
    }

    /**
     * @notice Retrieve the most recent entry from the debt ledger
     */
    function lastDebtLedgerEntry()
        external
        view
        returns (uint)
    {
        return debtLedger[debtLedger.length - 1];
    }

    /**
     * @notice Query whether an account has issued and has an outstanding debt balance
     * @param account The address to query for
     */
    function hasIssued(address account)
        external
        view
        returns (bool)
    {
        return issuanceData[account].initialDebtOwnership > 0;
    }

    event IssuanceRatioUpdated(uint newRatio);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

abstract contract IFeePool {
    address public FEE_ADDRESS;
    function amountReceivedFromExchange(uint value) external virtual view returns (uint);
    function amountReceivedFromTransfer(uint value) external virtual view returns (uint);
    function feePaid(bytes4 currencyKey, uint amount) external virtual;
    function appendAccountIssuanceRecord(address account, uint lockedAmount, uint debtEntryIndex) external virtual;
    function rewardsMinted(uint amount) external virtual;
    function transferFeeIncurred(uint value) public virtual view returns (uint);
}

/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       TokenFallback.sol
version:    1.0
author:     Kevin Brown
date:       2018-08-10

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

This contract provides the logic that's used to call tokenFallback()
when transfers happen.

It's pulled out into its own module because it's needed in two
places, so instead of copy/pasting this logic and maininting it
both in Fee Token and Extern State Token, it's here and depended
on by both contracts.

-----------------------------------------------------------------
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ReentrancyPreventer.sol";

contract TokenFallbackCaller is ReentrancyPreventer {
    function callTokenFallbackIfNeeded(address sender, address recipient, uint amount, bytes memory data)
        internal
        preventReentrancy
    {
        /*
            If we're transferring to a contract and it implements the tokenFallback function, call it.
            This isn't ERC223 compliant because we don't revert if the contract doesn't implement tokenFallback.
            This is because many DEXes and other contracts that expect to work with the standard
            approve / transferFrom workflow don't implement tokenFallback but can still process our tokens as
            usual, so it feels very harsh and likely to cause trouble if we add this restriction after having
            previously gone live with a vanilla ERC20.
        */

        // Is the to address a contract? We can check the code size on that address and know.
        uint length;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            // Retrieve the size of the code on the recipient address
            length := extcodesize(recipient)
        }

        // If there's code there, it's a contract
        if (length > 0) {
            // Now we need to optionally call tokenFallback(address from, uint value).
            // We can't call it the normal way because that reverts when the recipient doesn't implement the function.

            // solium-disable-next-line security/no-low-level-calls
            recipient.call(abi.encodeWithSignature("tokenFallback(address,uint256,bytes)", sender, amount, data));

            // And yes, we specifically don't care if this call fails, so we're not checking the return value.
        }
    }
}

/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       State.sol
version:    1.1
author:     Dominic Romanowski
            Anton Jurisevic

date:       2018-05-15

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

This contract is used side by side with external state token
contracts, such as Synthetix and Synth.
It provides an easy way to upgrade contract logic while
maintaining all user balances and allowances. This is designed
to make the changeover as easy as possible, since mappings
are not so cheap or straightforward to migrate.

The first deployed contract would create this state contract,
using it as its store of balances.
When a new contract is deployed, it links to the existing
state contract, whose owner would then change its associated
contract to the new one.

-----------------------------------------------------------------
*/


//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


import "./Owned.sol";


contract State is Owned {
    // the address of the contract that can modify variables
    // this can only be changed by the owner of this contract
    address public associatedContract;


    constructor(address _owner, address _associatedContract)
        Owned(_owner)
    {
        associatedContract = _associatedContract;
        emit AssociatedContractUpdated(_associatedContract);
    }

    /* ========== SETTERS ========== */

    // Change the associated contract to a new address
    function setAssociatedContract(address _associatedContract)
        external
        onlyOwner
    {
        associatedContract = _associatedContract;
        emit AssociatedContractUpdated(_associatedContract);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyAssociatedContract
    {
        require(msg.sender == associatedContract, "Only the associated contract can perform this action");
        _;
    }

    /* ========== EVENTS ========== */

    event AssociatedContractUpdated(address associatedContract);
}

/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       ExternStateToken.sol
version:    1.0
author:     Kevin Brown
date:       2018-08-06

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

This contract offers a modifer that can prevent reentrancy on
particular actions. It will not work if you put it on multiple
functions that can be called from each other. Specifically guard
external entry points to the contract with the modifier only.

-----------------------------------------------------------------
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract ReentrancyPreventer {
    /* ========== MODIFIERS ========== */
    bool isInFunctionBody = false;

    modifier preventReentrancy {
        require(!isInFunctionBody, "Reverted to prevent reentrancy");
        isInFunctionBody = true;
        _;
        isInFunctionBody = false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Chainlink.sol";
import "./interfaces/ENSInterface.sol";
import "./interfaces/LinkTokenInterface.sol";
import "./interfaces/ChainlinkRequestInterface.sol";
import "./interfaces/OperatorInterface.sol";
import "./interfaces/PointerInterface.sol";
import {ENSResolver as ENSResolver_Chainlink} from "./vendor/ENSResolver.sol";

/**
 * @title The ChainlinkClient contract
 * @notice Contract writers can inherit this contract in order to create requests for the
 * Chainlink network
 */
abstract contract ChainlinkClient {
  using Chainlink for Chainlink.Request;

  uint256 internal constant LINK_DIVISIBILITY = 10**18;
  uint256 private constant AMOUNT_OVERRIDE = 0;
  address private constant SENDER_OVERRIDE = address(0);
  uint256 private constant ORACLE_ARGS_VERSION = 1;
  uint256 private constant OPERATOR_ARGS_VERSION = 2;
  bytes32 private constant ENS_TOKEN_SUBNAME = keccak256("link");
  bytes32 private constant ENS_ORACLE_SUBNAME = keccak256("oracle");
  address private constant LINK_TOKEN_POINTER = 0xC89bD4E1632D3A43CB03AAAd5262cbe4038Bc571;

  ENSInterface private s_ens;
  bytes32 private s_ensNode;
  LinkTokenInterface private s_link;
  OperatorInterface private s_oracle;
  uint256 private s_requestCount = 1;
  mapping(bytes32 => address) private s_pendingRequests;

  event ChainlinkRequested(bytes32 indexed id);
  event ChainlinkFulfilled(bytes32 indexed id);
  event ChainlinkCancelled(bytes32 indexed id);

  /**
   * @notice Creates a request that can hold additional parameters
   * @param specId The Job Specification ID that the request will be created for
   * @param callbackAddr address to operate the callback on
   * @param callbackFunctionSignature function signature to use for the callback
   * @return A Chainlink Request struct in memory
   */
  function buildChainlinkRequest(
    bytes32 specId,
    address callbackAddr,
    bytes4 callbackFunctionSignature
  ) internal pure returns (Chainlink.Request memory) {
    Chainlink.Request memory req;
    return req.initialize(specId, callbackAddr, callbackFunctionSignature);
  }

  /**
   * @notice Creates a request that can hold additional parameters
   * @param specId The Job Specification ID that the request will be created for
   * @param callbackFunctionSignature function signature to use for the callback
   * @return A Chainlink Request struct in memory
   */
  function buildOperatorRequest(bytes32 specId, bytes4 callbackFunctionSignature)
    internal
    view
    returns (Chainlink.Request memory)
  {
    Chainlink.Request memory req;
    return req.initialize(specId, address(this), callbackFunctionSignature);
  }

  /**
   * @notice Creates a Chainlink request to the stored oracle address
   * @dev Calls `chainlinkRequestTo` with the stored oracle address
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequest(Chainlink.Request memory req, uint256 payment) internal returns (bytes32) {
    return sendChainlinkRequestTo(address(s_oracle), req, payment);
  }

  /**
   * @notice Creates a Chainlink request to the specified oracle address
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send LINK which creates a request on the target oracle contract.
   * Emits ChainlinkRequested event.
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequestTo(
    address oracleAddress,
    Chainlink.Request memory req,
    uint256 payment
  ) internal returns (bytes32 requestId) {
    uint256 nonce = s_requestCount;
    s_requestCount = nonce + 1;
    bytes memory encodedRequest = abi.encodeWithSelector(
      ChainlinkRequestInterface.oracleRequest.selector,
      SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
      AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
      req.id,
      address(this),
      req.callbackFunctionId,
      nonce,
      ORACLE_ARGS_VERSION,
      req.buf.buf
    );
    return _rawRequest(oracleAddress, nonce, payment, encodedRequest);
  }

  /**
   * @notice Creates a Chainlink request to the stored oracle address
   * @dev This function supports multi-word response
   * @dev Calls `sendOperatorRequestTo` with the stored oracle address
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendOperatorRequest(Chainlink.Request memory req, uint256 payment) internal returns (bytes32) {
    return sendOperatorRequestTo(address(s_oracle), req, payment);
  }

  /**
   * @notice Creates a Chainlink request to the specified oracle address
   * @dev This function supports multi-word response
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send LINK which creates a request on the target oracle contract.
   * Emits ChainlinkRequested event.
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendOperatorRequestTo(
    address oracleAddress,
    Chainlink.Request memory req,
    uint256 payment
  ) internal returns (bytes32 requestId) {
    uint256 nonce = s_requestCount;
    s_requestCount = nonce + 1;
    bytes memory encodedRequest = abi.encodeWithSelector(
      OperatorInterface.operatorRequest.selector,
      SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
      AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
      req.id,
      req.callbackFunctionId,
      nonce,
      OPERATOR_ARGS_VERSION,
      req.buf.buf
    );
    return _rawRequest(oracleAddress, nonce, payment, encodedRequest);
  }

  /**
   * @notice Make a request to an oracle
   * @param oracleAddress The address of the oracle for the request
   * @param nonce used to generate the request ID
   * @param payment The amount of LINK to send for the request
   * @param encodedRequest data encoded for request type specific format
   * @return requestId The request ID
   */
  function _rawRequest(
    address oracleAddress,
    uint256 nonce,
    uint256 payment,
    bytes memory encodedRequest
  ) private returns (bytes32 requestId) {
    requestId = keccak256(abi.encodePacked(this, nonce));
    s_pendingRequests[requestId] = oracleAddress;
    emit ChainlinkRequested(requestId);
    require(s_link.transferAndCall(oracleAddress, payment, encodedRequest), "unable to transferAndCall to oracle");
  }

  /**
   * @notice Allows a request to be cancelled if it has not been fulfilled
   * @dev Requires keeping track of the expiration value emitted from the oracle contract.
   * Deletes the request from the `pendingRequests` mapping.
   * Emits ChainlinkCancelled event.
   * @param requestId The request ID
   * @param payment The amount of LINK sent for the request
   * @param callbackFunc The callback function specified for the request
   * @param expiration The time of the expiration for the request
   */
  function cancelChainlinkRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunc,
    uint256 expiration
  ) internal {
    OperatorInterface requested = OperatorInterface(s_pendingRequests[requestId]);
    delete s_pendingRequests[requestId];
    emit ChainlinkCancelled(requestId);
    requested.cancelOracleRequest(requestId, payment, callbackFunc, expiration);
  }

  /**
   * @notice the next request count to be used in generating a nonce
   * @dev starts at 1 in order to ensure consistent gas cost
   * @return returns the next request count to be used in a nonce
   */
  function getNextRequestCount() internal view returns (uint256) {
    return s_requestCount;
  }

  /**
   * @notice Sets the stored oracle address
   * @param oracleAddress The address of the oracle contract
   */
  function setChainlinkOracle(address oracleAddress) internal {
    s_oracle = OperatorInterface(oracleAddress);
  }

  /**
   * @notice Sets the LINK token address
   * @param linkAddress The address of the LINK token contract
   */
  function setChainlinkToken(address linkAddress) internal {
    s_link = LinkTokenInterface(linkAddress);
  }

  /**
   * @notice Sets the Chainlink token address for the public
   * network as given by the Pointer contract
   */
  function setPublicChainlinkToken() internal {
    setChainlinkToken(PointerInterface(LINK_TOKEN_POINTER).getAddress());
  }

  /**
   * @notice Retrieves the stored address of the LINK token
   * @return The address of the LINK token
   */
  function chainlinkTokenAddress() internal view returns (address) {
    return address(s_link);
  }

  /**
   * @notice Retrieves the stored address of the oracle contract
   * @return The address of the oracle contract
   */
  function chainlinkOracleAddress() internal view returns (address) {
    return address(s_oracle);
  }

  /**
   * @notice Allows for a request which was created on another contract to be fulfilled
   * on this contract
   * @param oracleAddress The address of the oracle contract that will fulfill the request
   * @param requestId The request ID used for the response
   */
  function addChainlinkExternalRequest(address oracleAddress, bytes32 requestId) internal notPendingRequest(requestId) {
    s_pendingRequests[requestId] = oracleAddress;
  }

  /**
   * @notice Sets the stored oracle and LINK token contracts with the addresses resolved by ENS
   * @dev Accounts for subnodes having different resolvers
   * @param ensAddress The address of the ENS contract
   * @param node The ENS node hash
   */
  function useChainlinkWithENS(address ensAddress, bytes32 node) internal {
    s_ens = ENSInterface(ensAddress);
    s_ensNode = node;
    bytes32 linkSubnode = keccak256(abi.encodePacked(s_ensNode, ENS_TOKEN_SUBNAME));
    ENSResolver_Chainlink resolver = ENSResolver_Chainlink(s_ens.resolver(linkSubnode));
    setChainlinkToken(resolver.addr(linkSubnode));
    updateChainlinkOracleWithENS();
  }

  /**
   * @notice Sets the stored oracle contract with the address resolved by ENS
   * @dev This may be called on its own as long as `useChainlinkWithENS` has been called previously
   */
  function updateChainlinkOracleWithENS() internal {
    bytes32 oracleSubnode = keccak256(abi.encodePacked(s_ensNode, ENS_ORACLE_SUBNAME));
    ENSResolver_Chainlink resolver = ENSResolver_Chainlink(s_ens.resolver(oracleSubnode));
    setChainlinkOracle(resolver.addr(oracleSubnode));
  }

  /**
   * @notice Ensures that the fulfillment is valid for this contract
   * @dev Use if the contract developer prefers methods instead of modifiers for validation
   * @param requestId The request ID for fulfillment
   */
  function validateChainlinkCallback(bytes32 requestId)
    internal
    recordChainlinkFulfillment(requestId)
  // solhint-disable-next-line no-empty-blocks
  {

  }

  /**
   * @dev Reverts if the sender is not the oracle of the request.
   * Emits ChainlinkFulfilled event.
   * @param requestId The request ID for fulfillment
   */
  modifier recordChainlinkFulfillment(bytes32 requestId) {
    require(msg.sender == s_pendingRequests[requestId], "Source must be the oracle of the request");
    delete s_pendingRequests[requestId];
    emit ChainlinkFulfilled(requestId);
    _;
  }

  /**
   * @dev Reverts if the request is already pending
   * @param requestId The request ID for fulfillment
   */
  modifier notPendingRequest(bytes32 requestId) {
    require(s_pendingRequests[requestId] == address(0), "Request is already pending");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CBORChainlink} from "./vendor/CBORChainlink.sol";
import {BufferChainlink} from "./vendor/BufferChainlink.sol";

/**
 * @title Library for common Chainlink functions
 * @dev Uses imported CBOR library for encoding to buffer
 */
library Chainlink {
  uint256 internal constant defaultBufferSize = 256; // solhint-disable-line const-name-snakecase

  using CBORChainlink for BufferChainlink.buffer;

  struct Request {
    bytes32 id;
    address callbackAddress;
    bytes4 callbackFunctionId;
    uint256 nonce;
    BufferChainlink.buffer buf;
  }

  /**
   * @notice Initializes a Chainlink request
   * @dev Sets the ID, callback address, and callback function signature on the request
   * @param self The uninitialized request
   * @param jobId The Job Specification ID
   * @param callbackAddr The callback address
   * @param callbackFunc The callback function signature
   * @return The initialized request
   */
  function initialize(
    Request memory self,
    bytes32 jobId,
    address callbackAddr,
    bytes4 callbackFunc
  ) internal pure returns (Chainlink.Request memory) {
    BufferChainlink.init(self.buf, defaultBufferSize);
    self.id = jobId;
    self.callbackAddress = callbackAddr;
    self.callbackFunctionId = callbackFunc;
    return self;
  }

  /**
   * @notice Sets the data for the buffer without encoding CBOR on-chain
   * @dev CBOR can be closed with curly-brackets {} or they can be left off
   * @param self The initialized request
   * @param data The CBOR data
   */
  function setBuffer(Request memory self, bytes memory data) internal pure {
    BufferChainlink.init(self.buf, data.length);
    BufferChainlink.append(self.buf, data);
  }

  /**
   * @notice Adds a string value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The string value to add
   */
  function add(
    Request memory self,
    string memory key,
    string memory value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeString(value);
  }

  /**
   * @notice Adds a bytes value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The bytes value to add
   */
  function addBytes(
    Request memory self,
    string memory key,
    bytes memory value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeBytes(value);
  }

  /**
   * @notice Adds a int256 value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The int256 value to add
   */
  function addInt(
    Request memory self,
    string memory key,
    int256 value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeInt(value);
  }

  /**
   * @notice Adds a uint256 value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The uint256 value to add
   */
  function addUint(
    Request memory self,
    string memory key,
    uint256 value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeUInt(value);
  }

  /**
   * @notice Adds an array of strings to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param values The array of string values to add
   */
  function addStringArray(
    Request memory self,
    string memory key,
    string[] memory values
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.startArray();
    for (uint256 i = 0; i < values.length; i++) {
      self.buf.encodeString(values[i]);
    }
    self.buf.endSequence();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ENSInterface {
  // Logged when the owner of a node assigns a new owner to a subnode.
  event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

  // Logged when the owner of a node transfers ownership to a new account.
  event Transfer(bytes32 indexed node, address owner);

  // Logged when the resolver for a node changes.
  event NewResolver(bytes32 indexed node, address resolver);

  // Logged when the TTL of a node changes
  event NewTTL(bytes32 indexed node, uint64 ttl);

  function setSubnodeOwner(
    bytes32 node,
    bytes32 label,
    address owner
  ) external;

  function setResolver(bytes32 node, address resolver) external;

  function setOwner(bytes32 node, address owner) external;

  function setTTL(bytes32 node, uint64 ttl) external;

  function owner(bytes32 node) external view returns (address);

  function resolver(bytes32 node) external view returns (address);

  function ttl(bytes32 node) external view returns (uint64);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ChainlinkRequestInterface {
  function oracleRequest(
    address sender,
    uint256 requestPrice,
    bytes32 serviceAgreementID,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  ) external;

  function cancelOracleRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunctionId,
    uint256 expiration
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OracleInterface.sol";
import "./ChainlinkRequestInterface.sol";

interface OperatorInterface is OracleInterface, ChainlinkRequestInterface {
  function operatorRequest(
    address sender,
    uint256 payment,
    bytes32 specId,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  ) external;

  function fulfillOracleRequest2(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes calldata data
  ) external returns (bool);

  function ownerTransferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function distributeFunds(address payable[] calldata receivers, uint256[] calldata amounts) external payable;

  function getAuthorizedSenders() external returns (address[] memory);

  function setAuthorizedSenders(address[] calldata senders) external;

  function getForwarder() external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface PointerInterface {
  function getAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract ENSResolver {
  function addr(bytes32 node) public view virtual returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.19;

import {BufferChainlink} from "./BufferChainlink.sol";

library CBORChainlink {
  using BufferChainlink for BufferChainlink.buffer;

  uint8 private constant MAJOR_TYPE_INT = 0;
  uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
  uint8 private constant MAJOR_TYPE_BYTES = 2;
  uint8 private constant MAJOR_TYPE_STRING = 3;
  uint8 private constant MAJOR_TYPE_ARRAY = 4;
  uint8 private constant MAJOR_TYPE_MAP = 5;
  uint8 private constant MAJOR_TYPE_TAG = 6;
  uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

  uint8 private constant TAG_TYPE_BIGNUM = 2;
  uint8 private constant TAG_TYPE_NEGATIVE_BIGNUM = 3;

  function encodeFixedNumeric(BufferChainlink.buffer memory buf, uint8 major, uint64 value) private pure {
    if(value <= 23) {
      buf.appendUint8(uint8((major << 5) | value));
    } else if (value <= 0xFF) {
      buf.appendUint8(uint8((major << 5) | 24));
      buf.appendInt(value, 1);
    } else if (value <= 0xFFFF) {
      buf.appendUint8(uint8((major << 5) | 25));
      buf.appendInt(value, 2);
    } else if (value <= 0xFFFFFFFF) {
      buf.appendUint8(uint8((major << 5) | 26));
      buf.appendInt(value, 4);
    } else {
      buf.appendUint8(uint8((major << 5) | 27));
      buf.appendInt(value, 8);
    }
  }

  function encodeIndefiniteLengthType(BufferChainlink.buffer memory buf, uint8 major) private pure {
    buf.appendUint8(uint8((major << 5) | 31));
  }

  function encodeUInt(BufferChainlink.buffer memory buf, uint value) internal pure {
    if(value > 0xFFFFFFFFFFFFFFFF) {
      encodeBigNum(buf, value);
    } else {
      encodeFixedNumeric(buf, MAJOR_TYPE_INT, uint64(value));
    }
  }

  function encodeInt(BufferChainlink.buffer memory buf, int value) internal pure {
    if(value < -0x10000000000000000) {
      encodeSignedBigNum(buf, value);
    } else if(value > 0xFFFFFFFFFFFFFFFF) {
      encodeBigNum(buf, uint(value));
    } else if(value >= 0) {
      encodeFixedNumeric(buf, MAJOR_TYPE_INT, uint64(uint256(value)));
    } else {
      encodeFixedNumeric(buf, MAJOR_TYPE_NEGATIVE_INT, uint64(uint256(-1 - value)));
    }
  }

  function encodeBytes(BufferChainlink.buffer memory buf, bytes memory value) internal pure {
    encodeFixedNumeric(buf, MAJOR_TYPE_BYTES, uint64(value.length));
    buf.append(value);
  }

  function encodeBigNum(BufferChainlink.buffer memory buf, uint value) internal pure {
    buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_BIGNUM));
    encodeBytes(buf, abi.encode(value));
  }

  function encodeSignedBigNum(BufferChainlink.buffer memory buf, int input) internal pure {
    buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_NEGATIVE_BIGNUM));
    encodeBytes(buf, abi.encode(uint256(-1 - input)));
  }

  function encodeString(BufferChainlink.buffer memory buf, string memory value) internal pure {
    encodeFixedNumeric(buf, MAJOR_TYPE_STRING, uint64(bytes(value).length));
    buf.append(bytes(value));
  }

  function startArray(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_ARRAY);
  }

  function startMap(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_MAP);
  }

  function endSequence(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_CONTENT_FREE);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev A library for working with mutable byte buffers in Solidity.
 *
 * Byte buffers are mutable and expandable, and provide a variety of primitives
 * for writing to them. At any time you can fetch a bytes object containing the
 * current contents of the buffer. The bytes object should not be stored between
 * operations, as it may change due to resizing of the buffer.
 */
library BufferChainlink {
  /**
   * @dev Represents a mutable buffer. Buffers have a current value (buf) and
   *      a capacity. The capacity may be longer than the current value, in
   *      which case it can be extended without the need to allocate more memory.
   */
  struct buffer {
    bytes buf;
    uint256 capacity;
  }

  /**
   * @dev Initializes a buffer with an initial capacity.
   * @param buf The buffer to initialize.
   * @param capacity The number of bytes of space to allocate the buffer.
   * @return The buffer, for chaining.
   */
  function init(buffer memory buf, uint256 capacity) internal pure returns (buffer memory) {
    if (capacity % 32 != 0) {
      capacity += 32 - (capacity % 32);
    }
    // Allocate space for the buffer data
    buf.capacity = capacity;
    assembly {
      let ptr := mload(0x40)
      mstore(buf, ptr)
      mstore(ptr, 0)
      mstore(0x40, add(32, add(ptr, capacity)))
    }
    return buf;
  }

  /**
   * @dev Initializes a new buffer from an existing bytes object.
   *      Changes to the buffer may mutate the original value.
   * @param b The bytes object to initialize the buffer with.
   * @return A new buffer.
   */
  function fromBytes(bytes memory b) internal pure returns (buffer memory) {
    buffer memory buf;
    buf.buf = b;
    buf.capacity = b.length;
    return buf;
  }

  function resize(buffer memory buf, uint256 capacity) private pure {
    bytes memory oldbuf = buf.buf;
    init(buf, capacity);
    append(buf, oldbuf);
  }

  function max(uint256 a, uint256 b) private pure returns (uint256) {
    if (a > b) {
      return a;
    }
    return b;
  }

  /**
   * @dev Sets buffer length to 0.
   * @param buf The buffer to truncate.
   * @return The original buffer, for chaining..
   */
  function truncate(buffer memory buf) internal pure returns (buffer memory) {
    assembly {
      let bufptr := mload(buf)
      mstore(bufptr, 0)
    }
    return buf;
  }

  /**
   * @dev Writes a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The start offset to write to.
   * @param data The data to append.
   * @param len The number of bytes to copy.
   * @return The original buffer, for chaining.
   */
  function write(
    buffer memory buf,
    uint256 off,
    bytes memory data,
    uint256 len
  ) internal pure returns (buffer memory) {
    require(len <= data.length);

    if (off + len > buf.capacity) {
      resize(buf, max(buf.capacity, len + off) * 2);
    }

    uint256 dest;
    uint256 src;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Start address = buffer address + offset + sizeof(buffer length)
      dest := add(add(bufptr, 32), off)
      // Update buffer length if we're extending it
      if gt(add(len, off), buflen) {
        mstore(bufptr, add(len, off))
      }
      src := add(data, 32)
    }

    // Copy word-length chunks while possible
    for (; len >= 32; len -= 32) {
      assembly {
        mstore(dest, mload(src))
      }
      dest += 32;
      src += 32;
    }

    // Copy remaining bytes
    unchecked {
      uint256 mask = (256**(32 - len)) - 1;
      assembly {
        let srcpart := and(mload(src), not(mask))
        let destpart := and(mload(dest), mask)
        mstore(dest, or(destpart, srcpart))
      }
    }

    return buf;
  }

  /**
   * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @param len The number of bytes to copy.
   * @return The original buffer, for chaining.
   */
  function append(
    buffer memory buf,
    bytes memory data,
    uint256 len
  ) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, len);
  }

  /**
   * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function append(buffer memory buf, bytes memory data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, data.length);
  }

  /**
   * @dev Writes a byte to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write the byte at.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function writeUint8(
    buffer memory buf,
    uint256 off,
    uint8 data
  ) internal pure returns (buffer memory) {
    if (off >= buf.capacity) {
      resize(buf, buf.capacity * 2);
    }

    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Address = buffer address + sizeof(buffer length) + off
      let dest := add(add(bufptr, off), 32)
      mstore8(dest, data)
      // Update buffer length if we extended it
      if eq(off, buflen) {
        mstore(bufptr, add(buflen, 1))
      }
    }
    return buf;
  }

  /**
   * @dev Appends a byte to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function appendUint8(buffer memory buf, uint8 data) internal pure returns (buffer memory) {
    return writeUint8(buf, buf.buf.length, data);
  }

  /**
   * @dev Writes up to 32 bytes to the buffer. Resizes if doing so would
   *      exceed the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @param len The number of bytes to write (left-aligned).
   * @return The original buffer, for chaining.
   */
  function write(
    buffer memory buf,
    uint256 off,
    bytes32 data,
    uint256 len
  ) private pure returns (buffer memory) {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    unchecked {
      uint256 mask = (256**len) - 1;
      // Right-align data
      data = data >> (8 * (32 - len));
      assembly {
        // Memory address of the buffer data
        let bufptr := mload(buf)
        // Address = buffer address + sizeof(buffer length) + off + len
        let dest := add(add(bufptr, off), len)
        mstore(dest, or(and(mload(dest), not(mask)), data))
        // Update buffer length if we extended it
        if gt(add(off, len), mload(bufptr)) {
          mstore(bufptr, add(off, len))
        }
      }
    }
    return buf;
  }

  /**
   * @dev Writes a bytes20 to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function writeBytes20(
    buffer memory buf,
    uint256 off,
    bytes20 data
  ) internal pure returns (buffer memory) {
    return write(buf, off, bytes32(data), 20);
  }

  /**
   * @dev Appends a bytes20 to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chhaining.
   */
  function appendBytes20(buffer memory buf, bytes20 data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, bytes32(data), 20);
  }

  /**
   * @dev Appends a bytes32 to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function appendBytes32(buffer memory buf, bytes32 data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, 32);
  }

  /**
   * @dev Writes an integer to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @param len The number of bytes to write (right-aligned).
   * @return The original buffer, for chaining.
   */
  function writeInt(
    buffer memory buf,
    uint256 off,
    uint256 data,
    uint256 len
  ) private pure returns (buffer memory) {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    uint256 mask = (256**len) - 1;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Address = buffer address + off + sizeof(buffer length) + len
      let dest := add(add(bufptr, off), len)
      mstore(dest, or(and(mload(dest), not(mask)), data))
      // Update buffer length if we extended it
      if gt(add(off, len), mload(bufptr)) {
        mstore(bufptr, add(off, len))
      }
    }
    return buf;
  }

  /**
   * @dev Appends a byte to the end of the buffer. Resizes if doing so would
   * exceed the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer.
   */
  function appendInt(
    buffer memory buf,
    uint256 data,
    uint256 len
  ) internal pure returns (buffer memory) {
    return writeInt(buf, buf.buf.length, data, len);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OracleInterface {
  function fulfillOracleRequest(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes32 data
  ) external returns (bool);

  function isAuthorizedSender(address node) external view returns (bool);

  function withdraw(address recipient, uint256 amount) external;

  function withdrawable() external view returns (uint256);
}

/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       LimitedSetup.sol
version:    1.1
author:     Anton Jurisevic

date:       2018-05-15

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

A contract with a limited setup period. Any function modified
with the setup modifier will cease to work after the
conclusion of the configurable-length post-construction setup period.

-----------------------------------------------------------------
*/


//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/**
 * @title Any function decorated with the modifier this contract provides
 * deactivates after a specified setup period.
 */
contract LimitedSetup {

    uint setupExpiryTime;

    /**
     * @dev LimitedSetup Constructor.
     * @param setupDuration The time the setup period will last for.
     */
    constructor(uint setupDuration)
    {
        setupExpiryTime = block.timestamp + setupDuration;
    }

    modifier onlyDuringSetup
    {
        require(block.timestamp < setupExpiryTime, "Can only perform this action during setup");
        _;
    }
}

/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       EternalStorage.sol
version:    1.0
author:     Clinton Ennise
            Jackson Chan

date:       2019-02-01

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

This contract is used with external state storage contracts for
decoupled data storage.

Implements support for storing a keccak256 key and value pairs. It is
the more flexible and extensible option. This ensures data schema
changes can be implemented without requiring upgrades to the
storage contract

The first deployed storage contract would create this eternal storage.
Favour use of keccak256 key over sha3 as future version of solidity
> 0.5.0 will be deprecated.

-----------------------------------------------------------------
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./State.sol";

/**
 * @notice  This contract is based on the code available from this blog
 * https://blog.colony.io/writing-upgradeable-contracts-in-solidity-6743f0eecc88/
 * Implements support for storing a keccak256 key and value pairs. It is the more flexible
 * and extensible option. This ensures data schema changes can be implemented without
 * requiring upgrades to the storage contract.
 */
contract EternalStorage is State {

    constructor(address _owner, address _associatedContract)
        State(_owner, _associatedContract)
    {
    }

    /* ========== DATA TYPES ========== */
    mapping(bytes32 => uint) UIntStorage;
    mapping(bytes32 => string) StringStorage;
    mapping(bytes32 => address) AddressStorage;
    mapping(bytes32 => bytes) BytesStorage;
    mapping(bytes32 => bytes32) Bytes32Storage;
    mapping(bytes32 => bool) BooleanStorage;
    mapping(bytes32 => int) IntStorage;

    // UIntStorage;
    function getUIntValue(bytes32 record) external view returns (uint){
        return UIntStorage[record];
    }

    function setUIntValue(bytes32 record, uint value) external
        onlyAssociatedContract
    {
        UIntStorage[record] = value;
    }

    function deleteUIntValue(bytes32 record) external
        onlyAssociatedContract
    {
        delete UIntStorage[record];
    }

    // StringStorage
    function getStringValue(bytes32 record) external view returns (string memory){
        return StringStorage[record];
    }

    function setStringValue(bytes32 record, string memory value) external
        onlyAssociatedContract
    {
        StringStorage[record] = value;
    }

    function deleteStringValue(bytes32 record) external
        onlyAssociatedContract
    {
        delete StringStorage[record];
    }

    // AddressStorage
    function getAddressValue(bytes32 record) external view returns (address){
        return AddressStorage[record];
    }

    function setAddressValue(bytes32 record, address value) external
        onlyAssociatedContract
    {
        AddressStorage[record] = value;
    }

    function deleteAddressValue(bytes32 record) external
        onlyAssociatedContract
    {
        delete AddressStorage[record];
    }


    // BytesStorage
    function getBytesValue(bytes32 record) external view returns
    (bytes memory){
        return BytesStorage[record];
    }

    function setBytesValue(bytes32 record, bytes memory value) external
        onlyAssociatedContract
    {
        BytesStorage[record] = value;
    }

    function deleteBytesValue(bytes32 record) external
        onlyAssociatedContract
    {
        delete BytesStorage[record];
    }

    // Bytes32Storage
    function getBytes32Value(bytes32 record) external view returns (bytes32)
    {
        return Bytes32Storage[record];
    }

    function setBytes32Value(bytes32 record, bytes32 value) external
        onlyAssociatedContract
    {
        Bytes32Storage[record] = value;
    }

    function deleteBytes32Value(bytes32 record) external
        onlyAssociatedContract
    {
        delete Bytes32Storage[record];
    }

    // BooleanStorage
    function getBooleanValue(bytes32 record) external view returns (bool)
    {
        return BooleanStorage[record];
    }

    function setBooleanValue(bytes32 record, bool value) external
        onlyAssociatedContract
    {
        BooleanStorage[record] = value;
    }

    function deleteBooleanValue(bytes32 record) external
        onlyAssociatedContract
    {
        delete BooleanStorage[record];
    }

    // IntStorage
    function getIntValue(bytes32 record) external view returns (int){
        return IntStorage[record];
    }

    function setIntValue(bytes32 record, int value) external
        onlyAssociatedContract
    {
        IntStorage[record] = value;
    }

    function deleteIntValue(bytes32 record) external
        onlyAssociatedContract
    {
        delete IntStorage[record];
    }
}
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../common/implementation/FixedPoint.sol";
import "../../common/implementation/MultiRole.sol";
import "../../common/implementation/Withdrawable.sol";
import "../../common/implementation/Testable.sol";
import "../interfaces/StoreInterface.sol";


/**
 * @title An implementation of Store that can accept Oracle fees in ETH or any arbitrary ERC20 token.
 */
contract Store is StoreInterface, Withdrawable, Testable {
    using SafeMath for uint256;
    using FixedPoint for FixedPoint.Unsigned;
    using FixedPoint for uint256;
    using SafeERC20 for IERC20;

    /****************************************
     *    INTERNAL VARIABLES AND STORAGE    *
     ****************************************/

    enum Roles { Owner, Withdrawer }

    FixedPoint.Unsigned public fixedOracleFeePerSecondPerPfc; // Percentage of 1 E.g., .1 is 10% Oracle fee.
    FixedPoint.Unsigned public weeklyDelayFeePerSecondPerPfc; // Percentage of 1 E.g., .1 is 10% weekly delay fee.

    mapping(address => FixedPoint.Unsigned) public finalFees;
    uint256 public constant SECONDS_PER_WEEK = 604800;

    /****************************************
     *                EVENTS                *
     ****************************************/

    event NewFixedOracleFeePerSecondPerPfc(FixedPoint.Unsigned newOracleFee);
    event NewWeeklyDelayFeePerSecondPerPfc(FixedPoint.Unsigned newWeeklyDelayFeePerSecondPerPfc);
    event NewFinalFee(FixedPoint.Unsigned newFinalFee);

    /**
     * @notice Construct the Store contract.
     */
    constructor(
        FixedPoint.Unsigned memory _fixedOracleFeePerSecondPerPfc,
        FixedPoint.Unsigned memory _weeklyDelayFeePerSecondPerPfc,
        address _timerAddress
    ) public Testable(_timerAddress) {
        _createExclusiveRole(uint256(Roles.Owner), uint256(Roles.Owner), msg.sender);
        _createWithdrawRole(uint256(Roles.Withdrawer), uint256(Roles.Owner), msg.sender);
        setFixedOracleFeePerSecondPerPfc(_fixedOracleFeePerSecondPerPfc);
        setWeeklyDelayFeePerSecondPerPfc(_weeklyDelayFeePerSecondPerPfc);
    }

    /****************************************
     *  ORACLE FEE CALCULATION AND PAYMENT  *
     ****************************************/

    /**
     * @notice Pays Oracle fees in ETH to the store.
     * @dev To be used by contracts whose margin currency is ETH.
     */
    function payOracleFees() external override payable {
        require(msg.value > 0, "Value sent can't be zero");
    }

    /**
     * @notice Pays oracle fees in the margin currency, erc20Address, to the store.
     * @dev To be used if the margin currency is an ERC20 token rather than ETH.
     * @param erc20Address address of the ERC20 token used to pay the fee.
     * @param amount number of tokens to transfer. An approval for at least this amount must exist.
     */
    function payOracleFeesErc20(address erc20Address, FixedPoint.Unsigned calldata amount) external override {
        IERC20 erc20 = IERC20(erc20Address);
        require(amount.isGreaterThan(0), "Amount sent can't be zero");
        erc20.safeTransferFrom(msg.sender, address(this), amount.rawValue);
    }

    /**
     * @notice Computes the regular oracle fees that a contract should pay for a period.
     * @dev The late penalty is similar to the regular fee in that is is charged per second over the period between
     * startTime and endTime.
     *
     * The late penalty percentage increases over time as follows:
     *
     * - 0-1 week since startTime: no late penalty
     *
     * - 1-2 weeks since startTime: 1x late penalty percentage is applied
     *
     * - 2-3 weeks since startTime: 2x late penalty percentage is applied
     *
     * - ...
     *
     * @param startTime defines the beginning time from which the fee is paid.
     * @param endTime end time until which the fee is paid.
     * @param pfc "profit from corruption", or the maximum amount of margin currency that a
     * token sponsor could extract from the contract through corrupting the price feed in their favor.
     * @return regularFee amount owed for the duration from start to end time for the given pfc.
     * @return latePenalty penalty percentage, if any, for paying the fee after the deadline.
     */
    function computeRegularFee(
        uint256 startTime,
        uint256 endTime,
        FixedPoint.Unsigned calldata pfc
    ) external override view returns (FixedPoint.Unsigned memory regularFee, FixedPoint.Unsigned memory latePenalty) {
        uint256 timeDiff = endTime.sub(startTime);

        // Multiply by the unscaled `timeDiff` first, to get more accurate results.
        regularFee = pfc.mul(timeDiff).mul(fixedOracleFeePerSecondPerPfc);

        // Compute how long ago the start time was to compute the delay penalty.
        uint256 paymentDelay = getCurrentTime().sub(startTime);

        // Compute the additional percentage (per second) that will be charged because of the penalty.
        // Note: if less than a week has gone by since the startTime, paymentDelay / SECONDS_PER_WEEK will truncate to
        // 0, causing no penalty to be charged.
        FixedPoint.Unsigned memory penaltyPercentagePerSecond = weeklyDelayFeePerSecondPerPfc.mul(
            paymentDelay.div(SECONDS_PER_WEEK)
        );

        // Apply the penaltyPercentagePerSecond to the payment period.
        latePenalty = pfc.mul(timeDiff).mul(penaltyPercentagePerSecond);
    }

    /**
     * @notice Computes the final oracle fees that a contract should pay at settlement.
     * @param currency token used to pay the final fee.
     * @return finalFee amount due denominated in units of `currency`.
     */
    function computeFinalFee(address currency) external override view returns (FixedPoint.Unsigned memory) {
        return finalFees[currency];
    }

    /****************************************
     *   ADMIN STATE MODIFYING FUNCTIONS    *
     ****************************************/

    /**
     * @notice Sets a new oracle fee per second.
     * @param newFixedOracleFeePerSecondPerPfc new fee per second charged to use the oracle.
     */
    function setFixedOracleFeePerSecondPerPfc(FixedPoint.Unsigned memory newFixedOracleFeePerSecondPerPfc)
        public
        onlyRoleHolder(uint256(Roles.Owner))
    {
        // Oracle fees at or over 100% don't make sense.
        require(newFixedOracleFeePerSecondPerPfc.isLessThan(1), "Fee must be < 100% per second.");
        fixedOracleFeePerSecondPerPfc = newFixedOracleFeePerSecondPerPfc;
        emit NewFixedOracleFeePerSecondPerPfc(newFixedOracleFeePerSecondPerPfc);
    }

    /**
     * @notice Sets a new weekly delay fee.
     * @param newWeeklyDelayFeePerSecondPerPfc fee escalation per week of late fee payment.
     */
    function setWeeklyDelayFeePerSecondPerPfc(FixedPoint.Unsigned memory newWeeklyDelayFeePerSecondPerPfc)
        public
        onlyRoleHolder(uint256(Roles.Owner))
    {
        require(newWeeklyDelayFeePerSecondPerPfc.isLessThan(1), "weekly delay fee must be < 100%");
        weeklyDelayFeePerSecondPerPfc = newWeeklyDelayFeePerSecondPerPfc;
        emit NewWeeklyDelayFeePerSecondPerPfc(newWeeklyDelayFeePerSecondPerPfc);
    }

    /**
     * @notice Sets a new final fee for a particular currency.
     * @param currency defines the token currency used to pay the final fee.
     * @param newFinalFee final fee amount.
     */
    function setFinalFee(address currency, FixedPoint.Unsigned memory newFinalFee)
        public
        onlyRoleHolder(uint256(Roles.Owner))
    {
        finalFees[currency] = newFinalFee;
        emit NewFinalFee(newFinalFee);
    }
}

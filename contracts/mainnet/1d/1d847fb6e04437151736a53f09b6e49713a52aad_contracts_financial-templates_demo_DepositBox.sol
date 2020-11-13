pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../common/FeePayer.sol";

import "../../common/implementation/FixedPoint.sol";

import "../../oracle/interfaces/IdentifierWhitelistInterface.sol";
import "../../oracle/interfaces/OracleInterface.sol";
import "../../oracle/interfaces/AdministrateeInterface.sol";
import "../../oracle/implementation/ContractCreator.sol";


/**
 * @title Token Deposit Box
 * @notice This is a minimal example of a financial template that depends on price requests from the DVM.
 * This contract should be thought of as a "Deposit Box" into which the user deposits some ERC20 collateral.
 * The main feature of this box is that the user can withdraw their ERC20 corresponding to a desired USD amount.
 * When the user wants to make a withdrawal, a price request is enqueued with the UMA DVM.
 * For simplicty, the user is constrained to have one outstanding withdrawal request at any given time.
 * Regular fees are charged on the collateral in the deposit box throughout the lifetime of the deposit box,
 * and final fees are charged on each price request.
 *
 * This example is intended to accompany a technical tutorial for how to integrate the DVM into a project.
 * The main feature this demo serves to showcase is how to build a financial product on-chain that "pulls" price
 * requests from the DVM on-demand, which is an implementation of the "priceless" oracle framework.
 *
 * The typical user flow would be:
 * - User sets up a deposit box for the (wETH - USD) price-identifier. The "collateral currency" in this deposit
 *   box is therefore wETH.
 *   The user can subsequently make withdrawal requests for USD-denominated amounts of wETH.
 * - User deposits 10 wETH into their deposit box.
 * - User later requests to withdraw $100 USD of wETH.
 * - DepositBox asks DVM for latest wETH/USD exchange rate.
 * - DVM resolves the exchange rate at: 1 wETH is worth 200 USD.
 * - DepositBox transfers 0.5 wETH to user.
 */
contract DepositBox is FeePayer, AdministrateeInterface, ContractCreator {
    using SafeMath for uint256;
    using FixedPoint for FixedPoint.Unsigned;
    using SafeERC20 for IERC20;

    // Represents a single caller's deposit box. All collateral is held by this contract.
    struct DepositBoxData {
        // Requested amount of collateral, denominated in quote asset of the price identifier.
        // Example: If the price identifier is wETH-USD, and the `withdrawalRequestAmount = 100`, then
        // this represents a withdrawal request for 100 USD worth of wETH.
        FixedPoint.Unsigned withdrawalRequestAmount;
        // Timestamp of the latest withdrawal request. A withdrawal request is pending if `requestPassTimestamp != 0`.
        uint256 requestPassTimestamp;
        // Raw collateral value. This value should never be accessed directly -- always use _getFeeAdjustedCollateral().
        // To add or remove collateral, use _addCollateral() and _removeCollateral().
        FixedPoint.Unsigned rawCollateral;
    }

    // Maps addresses to their deposit boxes. Each address can have only one position.
    mapping(address => DepositBoxData) private depositBoxes;

    // Unique identifier for DVM price feed ticker.
    bytes32 private priceIdentifier;

    // Similar to the rawCollateral in DepositBoxData, this value should not be used directly.
    // _getFeeAdjustedCollateral(), _addCollateral() and _removeCollateral() must be used to access and adjust.
    FixedPoint.Unsigned private rawTotalDepositBoxCollateral;

    // This blocks every public state-modifying method until it flips to true, via the `initialize()` method.
    bool private initialized;

    /****************************************
     *                EVENTS                *
     ****************************************/

    event NewDepositBox(address indexed user);
    event EndedDepositBox(address indexed user);
    event Deposit(address indexed user, uint256 indexed collateralAmount);
    event RequestWithdrawal(address indexed user, uint256 indexed collateralAmount, uint256 requestPassTimestamp);
    event RequestWithdrawalExecuted(
        address indexed user,
        uint256 indexed collateralAmount,
        uint256 exchangeRate,
        uint256 requestPassTimestamp
    );
    event RequestWithdrawalCanceled(
        address indexed user,
        uint256 indexed collateralAmount,
        uint256 requestPassTimestamp
    );

    /****************************************
     *               MODIFIERS              *
     ****************************************/

    modifier noPendingWithdrawal(address user) {
        _depositBoxHasNoPendingWithdrawal(user);
        _;
    }

    modifier isInitialized() {
        _isInitialized();
        _;
    }

    /****************************************
     *           PUBLIC FUNCTIONS           *
     ****************************************/

    /**
     * @notice Construct the DepositBox.
     * @param _collateralAddress ERC20 token to be deposited.
     * @param _finderAddress UMA protocol Finder used to discover other protocol contracts.
     * @param _priceIdentifier registered in the DVM, used to price the ERC20 deposited.
     * The price identifier consists of a "base" asset and a "quote" asset. The "base" asset corresponds to the collateral ERC20
     * currency deposited into this account, and it is denominated in the "quote" asset on withdrawals.
     * An example price identifier would be "ETH-USD" which will resolve and return the USD price of ETH.
     * @param _timerAddress Contract that stores the current time in a testing environment.
     * Must be set to 0x0 for production environments that use live time.
     */
    constructor(
        address _collateralAddress,
        address _finderAddress,
        bytes32 _priceIdentifier,
        address _timerAddress
    )
        public
        ContractCreator(_finderAddress)
        FeePayer(_collateralAddress, _finderAddress, _timerAddress)
        nonReentrant()
    {
        require(_getIdentifierWhitelist().isIdentifierSupported(_priceIdentifier), "Unsupported price identifier");

        priceIdentifier = _priceIdentifier;
    }

    /**
     * @notice This should be called after construction of the DepositBox and handles registration with the Registry, which is required
     * to make price requests in production environments.
     * @dev This contract must hold the `ContractCreator` role with the Registry in order to register itself as a financial-template with the DVM.
     * Note that `_registerContract` cannot be called from the constructor because this contract first needs to be given the `ContractCreator` role
     * in order to register with the `Registry`. But, its address is not known until after deployment.
     */
    function initialize() public nonReentrant() {
        initialized = true;
        _registerContract(new address[](0), address(this));
    }

    /**
     * @notice Transfers `collateralAmount` of `collateralCurrency` into caller's deposit box.
     * @dev This contract must be approved to spend at least `collateralAmount` of `collateralCurrency`.
     * @param collateralAmount total amount of collateral tokens to be sent to the sponsor's position.
     */
    function deposit(FixedPoint.Unsigned memory collateralAmount) public isInitialized() fees() nonReentrant() {
        require(collateralAmount.isGreaterThan(0), "Invalid collateral amount");
        DepositBoxData storage depositBoxData = depositBoxes[msg.sender];
        if (_getFeeAdjustedCollateral(depositBoxData.rawCollateral).isEqual(0)) {
            emit NewDepositBox(msg.sender);
        }

        // Increase the individual deposit box and global collateral balance by collateral amount.
        _incrementCollateralBalances(depositBoxData, collateralAmount);

        emit Deposit(msg.sender, collateralAmount.rawValue);

        // Move collateral currency from sender to contract.
        collateralCurrency.safeTransferFrom(msg.sender, address(this), collateralAmount.rawValue);
    }

    /**
     * @notice Starts a withdrawal request that allows the sponsor to withdraw `denominatedCollateralAmount`
     * from their position denominated in the quote asset of the price identifier, following a DVM price resolution.
     * @dev The request will be pending for the duration of the DVM vote and can be cancelled at any time.
     * Only one withdrawal request can exist for the user.
     * @param denominatedCollateralAmount the quote-asset denominated amount of collateral requested to withdraw.
     */
    function requestWithdrawal(FixedPoint.Unsigned memory denominatedCollateralAmount)
        public
        isInitialized()
        noPendingWithdrawal(msg.sender)
        nonReentrant()
    {
        DepositBoxData storage depositBoxData = depositBoxes[msg.sender];
        require(denominatedCollateralAmount.isGreaterThan(0), "Invalid collateral amount");

        // Update the position object for the user.
        depositBoxData.withdrawalRequestAmount = denominatedCollateralAmount;
        depositBoxData.requestPassTimestamp = getCurrentTime();

        emit RequestWithdrawal(msg.sender, denominatedCollateralAmount.rawValue, depositBoxData.requestPassTimestamp);

        // Every price request costs a fixed fee. Check that this user has enough deposited to cover the final fee.
        FixedPoint.Unsigned memory finalFee = _computeFinalFees();
        require(
            _getFeeAdjustedCollateral(depositBoxData.rawCollateral).isGreaterThanOrEqual(finalFee),
            "Cannot pay final fee"
        );
        _payFinalFees(address(this), finalFee);
        // A price request is sent for the current timestamp.
        _requestOraclePrice(depositBoxData.requestPassTimestamp);
    }

    /**
     * @notice After a passed withdrawal request (i.e., by a call to `requestWithdrawal` and subsequent DVM price resolution),
     * withdraws `depositBoxData.withdrawalRequestAmount` of collateral currency denominated in the quote asset.
     * @dev Might not withdraw the full requested amount in order to account for precision loss or if the full requested
     * amount exceeds the collateral in the position (due to paying fees).
     * @return amountWithdrawn The actual amount of collateral withdrawn.
     */
    function executeWithdrawal()
        external
        isInitialized()
        fees()
        nonReentrant()
        returns (FixedPoint.Unsigned memory amountWithdrawn)
    {
        DepositBoxData storage depositBoxData = depositBoxes[msg.sender];
        require(
            depositBoxData.requestPassTimestamp != 0 && depositBoxData.requestPassTimestamp <= getCurrentTime(),
            "Invalid withdraw request"
        );

        // Get the resolved price or revert.
        FixedPoint.Unsigned memory exchangeRate = _getOraclePrice(depositBoxData.requestPassTimestamp);

        // Calculate denomated amount of collateral based on resolved exchange rate.
        // Example 1: User wants to withdraw $100 of ETH, exchange rate is $200/ETH, therefore user to receive 0.5 ETH.
        // Example 2: User wants to withdraw $250 of ETH, exchange rate is $200/ETH, therefore user to receive 1.25 ETH.
        FixedPoint.Unsigned memory denominatedAmountToWithdraw = depositBoxData.withdrawalRequestAmount.div(
            exchangeRate
        );

        // If withdrawal request amount is > collateral, then withdraw the full collateral amount and delete the deposit box data.
        if (denominatedAmountToWithdraw.isGreaterThan(_getFeeAdjustedCollateral(depositBoxData.rawCollateral))) {
            denominatedAmountToWithdraw = _getFeeAdjustedCollateral(depositBoxData.rawCollateral);

            // Reset the position state as all the value has been removed after settlement.
            emit EndedDepositBox(msg.sender);
        }

        // Decrease the individual deposit box and global collateral balance.
        amountWithdrawn = _decrementCollateralBalances(depositBoxData, denominatedAmountToWithdraw);

        emit RequestWithdrawalExecuted(
            msg.sender,
            amountWithdrawn.rawValue,
            exchangeRate.rawValue,
            depositBoxData.requestPassTimestamp
        );

        // Reset withdrawal request by setting withdrawal request timestamp to 0.
        _resetWithdrawalRequest(depositBoxData);

        // Transfer approved withdrawal amount from the contract to the caller.
        collateralCurrency.safeTransfer(msg.sender, amountWithdrawn.rawValue);
    }

    /**
     * @notice Cancels a pending withdrawal request.
     */
    function cancelWithdrawal() external isInitialized() nonReentrant() {
        DepositBoxData storage depositBoxData = depositBoxes[msg.sender];
        require(depositBoxData.requestPassTimestamp != 0, "No pending withdrawal");

        emit RequestWithdrawalCanceled(
            msg.sender,
            depositBoxData.withdrawalRequestAmount.rawValue,
            depositBoxData.requestPassTimestamp
        );

        // Reset withdrawal request by setting withdrawal request timestamp to 0.
        _resetWithdrawalRequest(depositBoxData);
    }

    /**
     * @notice `emergencyShutdown` and `remargin` are required to be implemented by all financial contracts and exposed to the DVM, but
     * because this is a minimal demo they will simply exit silently.
     */
    function emergencyShutdown() external override isInitialized() nonReentrant() {
        return;
    }

    /**
     * @notice Same comment as `emergencyShutdown`. For the sake of simplicity, this will simply exit silently.
     */
    function remargin() external override isInitialized() nonReentrant() {
        return;
    }

    /**
     * @notice Accessor method for a user's collateral.
     * @dev This is necessary because the struct returned by the depositBoxes() method shows
     * rawCollateral, which isn't a user-readable value.
     * @param user address whose collateral amount is retrieved.
     * @return the fee-adjusted collateral amount in the deposit box (i.e. available for withdrawal).
     */
    function getCollateral(address user) external view nonReentrantView() returns (FixedPoint.Unsigned memory) {
        return _getFeeAdjustedCollateral(depositBoxes[user].rawCollateral);
    }

    /**
     * @notice Accessor method for the total collateral stored within the entire contract.
     * @return the total fee-adjusted collateral amount in the contract (i.e. across all users).
     */
    function totalDepositBoxCollateral() external view nonReentrantView() returns (FixedPoint.Unsigned memory) {
        return _getFeeAdjustedCollateral(rawTotalDepositBoxCollateral);
    }

    /****************************************
     *          INTERNAL FUNCTIONS          *
     ****************************************/

    // Requests a price for `priceIdentifier` at `requestedTime` from the Oracle.
    function _requestOraclePrice(uint256 requestedTime) internal {
        OracleInterface oracle = _getOracle();
        oracle.requestPrice(priceIdentifier, requestedTime);
    }

    // Ensure individual and global consistency when increasing collateral balances. Returns the change to the position.
    function _incrementCollateralBalances(
        DepositBoxData storage depositBoxData,
        FixedPoint.Unsigned memory collateralAmount
    ) internal returns (FixedPoint.Unsigned memory) {
        _addCollateral(depositBoxData.rawCollateral, collateralAmount);
        return _addCollateral(rawTotalDepositBoxCollateral, collateralAmount);
    }

    // Ensure individual and global consistency when decrementing collateral balances. Returns the change to the
    // position. We elect to return the amount that the global collateral is decreased by, rather than the individual
    // position's collateral, because we need to maintain the invariant that the global collateral is always
    // <= the collateral owned by the contract to avoid reverts on withdrawals. The amount returned = amount withdrawn.
    function _decrementCollateralBalances(
        DepositBoxData storage depositBoxData,
        FixedPoint.Unsigned memory collateralAmount
    ) internal returns (FixedPoint.Unsigned memory) {
        _removeCollateral(depositBoxData.rawCollateral, collateralAmount);
        return _removeCollateral(rawTotalDepositBoxCollateral, collateralAmount);
    }

    function _resetWithdrawalRequest(DepositBoxData storage depositBoxData) internal {
        depositBoxData.withdrawalRequestAmount = FixedPoint.fromUnscaledUint(0);
        depositBoxData.requestPassTimestamp = 0;
    }

    function _depositBoxHasNoPendingWithdrawal(address user) internal view {
        require(depositBoxes[user].requestPassTimestamp == 0, "Pending withdrawal");
    }

    function _isInitialized() internal view {
        require(initialized, "Uninitialized contract");
    }

    function _getIdentifierWhitelist() internal view returns (IdentifierWhitelistInterface) {
        return IdentifierWhitelistInterface(finder.getImplementationAddress(OracleInterfaces.IdentifierWhitelist));
    }

    function _getOracle() internal view returns (OracleInterface) {
        return OracleInterface(finder.getImplementationAddress(OracleInterfaces.Oracle));
    }

    // Fetches a resolved Oracle price from the Oracle. Reverts if the Oracle hasn't resolved for this request.
    function _getOraclePrice(uint256 requestedTime) internal view returns (FixedPoint.Unsigned memory) {
        OracleInterface oracle = _getOracle();
        require(oracle.hasPrice(priceIdentifier, requestedTime), "Unresolved oracle price");
        int256 oraclePrice = oracle.getPrice(priceIdentifier, requestedTime);

        // For simplicity we don't want to deal with negative prices.
        if (oraclePrice < 0) {
            oraclePrice = 0;
        }
        return FixedPoint.Unsigned(uint256(oraclePrice));
    }

    // `_pfc()` is inherited from FeePayer and must be implemented to return the available pool of collateral from
    // which fees can be charged. For this contract, the available fee pool is simply all of the collateral locked up in the
    // contract.
    function _pfc() internal virtual override view returns (FixedPoint.Unsigned memory) {
        return _getFeeAdjustedCollateral(rawTotalDepositBoxCollateral);
    }
}

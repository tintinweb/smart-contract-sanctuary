pragma solidity ^0.4.24;

import "./Exponential.sol";
import "./InterestRateModel.sol";
import "./SafeToken.sol";
import "./ChainLink.sol";
import "./AlkemiWETH.sol";

contract AlkemiEarnVerified is Exponential, SafeToken {

    uint internal initialInterestIndex;
    uint internal defaultOriginationFee; 
    uint internal defaultCollateralRatio;
    uint internal defaultLiquidationDiscount;

    uint internal minimumCollateralRatioMantissa;
    uint internal maximumLiquidationDiscountMantissa;
    bool public initializationDone; // To make sure initializer is called only once

    /**
     * @notice `AlkemiEarnVerified` is the core contract
     * @notice This contract uses Openzeppelin Upgrades plugin to make use of the upgradeability functionality using proxies
     * @notice Hence this contract has an 'initializer' in place of a 'constructor'
     * @notice Make sure to add new global variables only at the bottom of all the existing global variables i.e., line #344
     * @notice Also make sure to do extensive testing while modifying any structs and enums during an upgrade
     */
    function initializer() public {
        if(initializationDone == false) {
            initializationDone = true;
            admin = msg.sender;
            initialInterestIndex = 10 ** 18;
            defaultOriginationFee = (10 ** 15); // default is 0.1%
            defaultCollateralRatio = 125 * (10 ** 16); // default is 125% or 1.25
            defaultLiquidationDiscount = (10 ** 17); // default is 10% or 0.1
            minimumCollateralRatioMantissa = 11 * (10 ** 17); // 1.1
            maximumLiquidationDiscountMantissa = (10 ** 17); // 0.1
            collateralRatio = Exp({mantissa: defaultCollateralRatio});
            originationFee = Exp({mantissa: defaultOriginationFee});
            liquidationDiscount = Exp({mantissa: defaultLiquidationDiscount});
            // oracle must be configured via _setOracle
        }
    }

    /**
     * @notice Do not pay directly into AlkemiEarnVerified, please use `supply`.
     */
    function() payable public {
        revert();
    }

    /**
     * @dev pending Administrator for this contract.
     */
    address public pendingAdmin;

    /**
     * @dev Administrator for this contract. Initially set in constructor, but can
     *      be changed by the admin itself.
     */
    address public admin;

    /**
     * @dev Managers for this contract with limited permissions. Can
     *      be changed by the admin.
     */
    mapping (address => bool) public managers;

    /**
     * @dev Account allowed to set oracle prices for this contract. Initially set
     *      in constructor, but can be changed by the admin.
     */
    address public oracle;

    /**
     * @dev Account allowed to fetch chainlink oracle prices for this contract. Can be changed by the admin.
     */
    ChainLink priceOracle;

    /**
     * @dev Container for customer balance information written to storage.
     *
     *      struct Balance {
     *        principal = customer total balance with accrued interest after applying the customer's most recent balance-changing action
     *        interestIndex = the total interestIndex as calculated after applying the customer's most recent balance-changing action
     *      }
     */
    struct Balance {
        uint principal;
        uint interestIndex;
    }

    /**
     * @dev 2-level map: customerAddress -> assetAddress -> balance for supplies
     */
    mapping(address => mapping(address => Balance)) public supplyBalances;


    /**
     * @dev 2-level map: customerAddress -> assetAddress -> balance for borrows
     */
    mapping(address => mapping(address => Balance)) public borrowBalances;


    /**
     * @dev Container for per-asset balance sheet and interest rate information written to storage, intended to be stored in a map where the asset address is the key
     *
     *      struct Market {
     *         isSupported = Whether this market is supported or not (not to be confused with the list of collateral assets)
     *         blockNumber = when the other values in this struct were calculated
     *         totalSupply = total amount of this asset supplied (in asset wei)
     *         supplyRateMantissa = the per-block interest rate for supplies of asset as of blockNumber, scaled by 10e18
     *         supplyIndex = the interest index for supplies of asset as of blockNumber; initialized in _supportMarket
     *         totalBorrows = total amount of this asset borrowed (in asset wei)
     *         borrowRateMantissa = the per-block interest rate for borrows of asset as of blockNumber, scaled by 10e18
     *         borrowIndex = the interest index for borrows of asset as of blockNumber; initialized in _supportMarket
     *     }
     */
    struct Market {
        bool isSupported;
        uint blockNumber;
        InterestRateModel interestRateModel;

        uint totalSupply;
        uint supplyRateMantissa;
        uint supplyIndex;

        uint totalBorrows;
        uint borrowRateMantissa;
        uint borrowIndex;
    }

    /**
     * @dev wethAddress to hold the WETH token contract address
     * set using setWethAddress function
     */
    address public wethAddress;

    /**
     * @dev Initiates the contract for supply and withdraw Ether and conversion to WETH
     */
    AlkemiWETH public WETHContract;

    /**
     * @dev map: assetAddress -> Market
     */
    mapping(address => Market) public markets;

    /**
     * @dev list: collateralMarkets
     */
    address[] public collateralMarkets;

    /**
     * @dev The collateral ratio that borrows must maintain (e.g. 2 implies 2:1). This
     *      is initially set in the constructor, but can be changed by the admin.
     */
    Exp public collateralRatio;

    /**
     * @dev originationFee for new borrows.
     *
     */
    Exp public originationFee;

    /**
     * @dev liquidationDiscount for collateral when liquidating borrows
     *
     */
    Exp public liquidationDiscount;

    /**
     * @dev flag for whether or not contract is paused
     *
     */
    bool public paused;

    /**
     * @dev Mapping to identify the list of KYC Admins
     */
    mapping(address=>bool) private KYCAdmins;
    /**
     * @dev Mapping to identify the list of customers with verified KYC
     */
    mapping(address=>bool) private customersWithKYC;

    /**
     * @dev Mapping to identify the list of customers with Liquidator roles
     */
    mapping(address=>bool) private liquidators;

    /**
     * The `SupplyLocalVars` struct is used internally in the `supply` function.
     *
     * To avoid solidity limits on the number of local variables we:
     * 1. Use a struct to hold local computation localResults
     * 2. Re-use a single variable for Error returns. (This is required with 1 because variable binding to tuple localResults
     *    requires either both to be declared inline or both to be previously declared.
     * 3. Re-use a boolean error-like return variable.
     */
    struct SupplyLocalVars {
        uint startingBalance;
        uint newSupplyIndex;
        uint userSupplyCurrent;
        uint userSupplyUpdated;
        uint newTotalSupply;
        uint currentCash;
        uint updatedCash;
        uint newSupplyRateMantissa;
        uint newBorrowIndex;
        uint newBorrowRateMantissa;
    }

    /**
     * The `WithdrawLocalVars` struct is used internally in the `withdraw` function.
     *
     * To avoid solidity limits on the number of local variables we:
     * 1. Use a struct to hold local computation localResults
     * 2. Re-use a single variable for Error returns. (This is required with 1 because variable binding to tuple localResults
     *    requires either both to be declared inline or both to be previously declared.
     * 3. Re-use a boolean error-like return variable.
     */

    struct WithdrawLocalVars {
        uint withdrawAmount;
        uint startingBalance;
        uint newSupplyIndex;
        uint userSupplyCurrent;
        uint userSupplyUpdated;
        uint newTotalSupply;
        uint currentCash;
        uint updatedCash;
        uint newSupplyRateMantissa;
        uint newBorrowIndex;
        uint newBorrowRateMantissa;
        Exp accountLiquidity;
        Exp accountShortfall;
        Exp ethValueOfWithdrawal;
        uint withdrawCapacity;
    }

    // The `AccountValueLocalVars` struct is used internally in the `CalculateAccountValuesInternal` function.
    struct AccountValueLocalVars {
        address assetAddress;
        uint collateralMarketsLength;

        uint newSupplyIndex;
        uint userSupplyCurrent;
        Exp supplyTotalValue;
        Exp sumSupplies;

        uint newBorrowIndex;
        uint userBorrowCurrent;
        Exp borrowTotalValue;
        Exp sumBorrows;
    }

    // The `PayBorrowLocalVars` struct is used internally in the `repayBorrow` function.
    struct PayBorrowLocalVars {
        uint newBorrowIndex;
        uint userBorrowCurrent;
        uint repayAmount;

        uint userBorrowUpdated;
        uint newTotalBorrows;
        uint currentCash;
        uint updatedCash;

        uint newSupplyIndex;
        uint newSupplyRateMantissa;
        uint newBorrowRateMantissa;

        uint startingBalance;
    }

    // The `BorrowLocalVars` struct is used internally in the `borrow` function.
    struct BorrowLocalVars {
        uint newBorrowIndex;
        uint userBorrowCurrent;
        uint borrowAmountWithFee;

        uint userBorrowUpdated;
        uint newTotalBorrows;
        uint currentCash;
        uint updatedCash;

        uint newSupplyIndex;
        uint newSupplyRateMantissa;
        uint newBorrowRateMantissa;

        uint startingBalance;

        Exp accountLiquidity;
        Exp accountShortfall;
        Exp ethValueOfBorrowAmountWithFee;
    }

    // The `LiquidateLocalVars` struct is used internally in the `liquidateBorrow` function.
    struct LiquidateLocalVars {
        // we need these addresses in the struct for use with `emitLiquidationEvent` to avoid `CompilerError: Stack too deep, try removing local variables.`
        address targetAccount;
        address assetBorrow;
        address liquidator;
        address assetCollateral;

        // borrow index and supply index are global to the asset, not specific to the user
        uint newBorrowIndex_UnderwaterAsset;
        uint newSupplyIndex_UnderwaterAsset;
        uint newBorrowIndex_CollateralAsset;
        uint newSupplyIndex_CollateralAsset;

        // the target borrow's full balance with accumulated interest
        uint currentBorrowBalance_TargetUnderwaterAsset;
        // currentBorrowBalance_TargetUnderwaterAsset minus whatever gets repaid as part of the liquidation
        uint updatedBorrowBalance_TargetUnderwaterAsset;

        uint newTotalBorrows_ProtocolUnderwaterAsset;

        uint startingBorrowBalance_TargetUnderwaterAsset;
        uint startingSupplyBalance_TargetCollateralAsset;
        uint startingSupplyBalance_LiquidatorCollateralAsset;

        uint currentSupplyBalance_TargetCollateralAsset;
        uint updatedSupplyBalance_TargetCollateralAsset;

        // If liquidator already has a balance of collateralAsset, we will accumulate
        // interest on it before transferring seized collateral from the borrower.
        uint currentSupplyBalance_LiquidatorCollateralAsset;
        // This will be the liquidator's accumulated balance of collateral asset before the liquidation (if any)
        // plus the amount seized from the borrower.
        uint updatedSupplyBalance_LiquidatorCollateralAsset;

        uint newTotalSupply_ProtocolCollateralAsset;
        uint currentCash_ProtocolUnderwaterAsset;
        uint updatedCash_ProtocolUnderwaterAsset;

        // cash does not change for collateral asset

        uint newSupplyRateMantissa_ProtocolUnderwaterAsset;
        uint newBorrowRateMantissa_ProtocolUnderwaterAsset;

        // Why no variables for the interest rates for the collateral asset?
        // We don't need to calculate new rates for the collateral asset since neither cash nor borrows change

        uint discountedRepayToEvenAmount;

        //[supplyCurrent / (1 + liquidationDiscount)] * (Oracle price for the collateral / Oracle price for the borrow) (discountedBorrowDenominatedCollateral)
        uint discountedBorrowDenominatedCollateral;

        uint maxCloseableBorrowAmount_TargetUnderwaterAsset;
        uint closeBorrowAmount_TargetUnderwaterAsset;
        uint seizeSupplyAmount_TargetCollateralAsset;

        Exp collateralPrice;
        Exp underwaterAssetPrice;

        uint reimburseAmount;
    }

    /**
     * @dev 2-level map: customerAddress -> assetAddress -> originationFeeBalance for borrows
     */
    mapping(address => mapping(address => uint)) public originationFeeBalance;

    /**
     * @dev Event emitted on successful addition of Weth Address
     */
    event WETHAddressSet(address wethAddress);

    /**
     * @dev Events to notify the frontend of all the functions below
     */
    event LiquidatorAdded(address Liquidator);
    event LiquidatorRemoved(address Liquidator);

    /**
     * @dev emitted when a supply is received
     *      Note: newBalance - amount - startingBalance = interest accumulated since last change
     */
    event SupplyReceived(address account, address asset, uint amount, uint startingBalance, uint newBalance);

    /**
     * @dev emitted when a origination fee supply is received as admin
     *      Note: newBalance - amount - startingBalance = interest accumulated since last change
     */
    event SupplyOrgFeeAsAdmin(address account, address asset, uint amount, uint startingBalance, uint newBalance);
    /**
     * @dev emitted when a supply is withdrawn
     *      Note: startingBalance - amount - startingBalance = interest accumulated since last change
     */
    event SupplyWithdrawn(address account, address asset, uint amount, uint startingBalance, uint newBalance);

    /**
     * @dev emitted when a new borrow is taken
     *      Note: newBalance - borrowAmountWithFee - startingBalance = interest accumulated since last change
     */
    event BorrowTaken(address account, address asset, uint amount, uint startingBalance, uint borrowAmountWithFee, uint newBalance);

    /**
     * @dev emitted when a borrow is repaid
     *      Note: newBalance - amount - startingBalance = interest accumulated since last change
     */
    event BorrowRepaid(address account, address asset, uint amount, uint startingBalance, uint newBalance);

    /**
     * @dev emitted when a borrow is liquidated
     *      targetAccount = user whose borrow was liquidated
     *      assetBorrow = asset borrowed
     *      borrowBalanceBefore = borrowBalance as most recently stored before the liquidation
     *      borrowBalanceAccumulated = borroBalanceBefore + accumulated interest as of immediately prior to the liquidation
     *      amountRepaid = amount of borrow repaid
     *      liquidator = account requesting the liquidation
     *      assetCollateral = asset taken from targetUser and given to liquidator in exchange for liquidated loan
     *      borrowBalanceAfter = new stored borrow balance (should equal borrowBalanceAccumulated - amountRepaid)
     *      collateralBalanceBefore = collateral balance as most recently stored before the liquidation
     *      collateralBalanceAccumulated = collateralBalanceBefore + accumulated interest as of immediately prior to the liquidation
     *      amountSeized = amount of collateral seized by liquidator
     *      collateralBalanceAfter = new stored collateral balance (should equal collateralBalanceAccumulated - amountSeized)
     */
    event BorrowLiquidated(address targetAccount,
        address assetBorrow,
        uint borrowBalanceBefore,
        uint borrowBalanceAccumulated,
        uint amountRepaid,
        uint borrowBalanceAfter,
        address liquidator,
        address assetCollateral,
        uint collateralBalanceBefore,
        uint collateralBalanceAccumulated,
        uint amountSeized,
        uint collateralBalanceAfter);

    /**
     * @dev emitted when pendingAdmin is changed
     */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
     * @dev emitted when pendingAdmin is accepted, which means admin is updated
     */
    event NewAdmin(address oldAdmin, address newAdmin);

    /**
     * @dev newOracle - address of new oracle
     */
    event NewOracle(address oldOracle, address newOracle);

    /**
     * @dev emitted when new market is supported by admin
     */
    event SupportedMarket(address asset, address interestRateModel);

    /**
     * @dev emitted when risk parameters are changed by admin
     */
    event NewRiskParameters(uint oldCollateralRatioMantissa, uint newCollateralRatioMantissa, uint oldLiquidationDiscountMantissa, uint newLiquidationDiscountMantissa, uint NewMinimumCollateralRatioMantissa, uint newMaximumLiquidationDiscountMantissa);

    /**
     * @dev emitted when origination fee is changed by admin
     */
    event NewOriginationFee(uint oldOriginationFeeMantissa, uint newOriginationFeeMantissa);

    /**
     * @dev emitted when market has new interest rate model set
     */
    event SetMarketInterestRateModel(address asset, address interestRateModel);

    /**
     * @dev emitted when admin withdraws equity
     * Note that `equityAvailableBefore` indicates equity before `amount` was removed.
     */
    event EquityWithdrawn(address asset, uint equityAvailableBefore, uint amount, address owner);

    /**
     * @dev emitted when a supported market is suspended by admin
     */
    event SuspendedMarket(address asset);

    /**
     * @dev emitted when admin either pauses or resumes the contract; newState is the resulting state
     */
    event SetPaused(bool newState);

    /**
     * @dev KYC Integration
     */

    /**
     * @dev Events to notify the frontend of all the functions below
     */
    event KYCAdminAdded(address KYCAdmin);
    event KYCAdminRemoved(address KYCAdmin);
    event KYCCustomerAdded(address KYCCustomer);
    event KYCCustomerRemoved(address KYCCustomer);

    /**
     * @dev Modifier to check if the caller of the function is a manager or owner
     */
    modifier onlyAdminOrManager {
        // Check caller = KYCadmin
        require(msg.sender == admin || managers[msg.sender],"Only owner or manager can perform operation");
        _;
    }

    /**
     * @dev Function to emit fail event to frontend
     */
    function emitError(Error error, FailureInfo failure) private returns(uint) {
        return fail(error, failure);
    }

    /**
     * @dev Modifier to check if the caller of the function is a KYC Admin
     */
    modifier isKYCAdmin {
        // Check caller = KYCadmin
        if (!KYCAdmins[msg.sender]) {
            emitError(Error.KYC_ADMIN_CHECK_FAILED, FailureInfo.KYC_ADMIN_CHECK_FAILED);
        } else {
            require(KYCAdmins[msg.sender],"Operation can only be performed by a KYC Admin");
            _;
        }
    }

    /**
     * @dev Modifier to check if the caller of the function is KYC verified
     */
    modifier isKYCVerifiedCustomer {
        // Check caller = KYCVerifiedCustomer
        if (!customersWithKYC[msg.sender]) {
            revertEtherToUser(msg.sender,msg.value);
            emitError(Error.KYC_CUSTOMER_VERIFICATION_CHECK_FAILED, FailureInfo.KYC_CUSTOMER_VERIFICATION_CHECK_FAILED);
        } else {
            require(customersWithKYC[msg.sender],"Customer is not KYC Verified");
            _;
        }
    }

    /**
     * @dev Function for use by the admin of the contract to add KYC Admins
     */
    function addKYCAdmin(address KYCAdmin) public returns(uint) {
        // Check caller = admin
        if (msg.sender != admin) {
            return fail(Error.KYC_ADMIN_ADD_OR_DELETE_ADMIN_CHECK_FAILED, FailureInfo.KYC_ADMIN_ADD_OR_DELETE_ADMIN_CHECK_FAILED);
        }
        KYCAdmins[KYCAdmin] = true;
        emit KYCAdminAdded(KYCAdmin);
        return uint(Error.NO_ERROR);
    }

    /**
     * @dev Function for use by the admin of the contract to remove KYC Admins
     */
    function removeKYCAdmin(address KYCAdmin) public returns(uint) {
        // Check caller = admin
        if (msg.sender != admin) {
            return fail(Error.KYC_ADMIN_ADD_OR_DELETE_ADMIN_CHECK_FAILED, FailureInfo.KYC_ADMIN_ADD_OR_DELETE_ADMIN_CHECK_FAILED);
        }
        KYCAdmins[KYCAdmin] = false;
        emit KYCAdminRemoved(KYCAdmin);
        return uint(Error.NO_ERROR);
    }

    /**
     * @dev Function for use by the KYC admins to add KYC Customers
     */
    function addCustomerKYC(address customer) public isKYCAdmin returns(uint) {
        customersWithKYC[customer] = true;
        emit KYCCustomerAdded(customer);
        return uint(Error.NO_ERROR);
    }

    /**
     * @dev Function for use by the KYC admins to remove KYC Customers
     */
    function removeCustomerKYC(address customer) public isKYCAdmin returns(uint) {
        customersWithKYC[customer] = false;
        emit KYCCustomerRemoved(customer);
        return uint(Error.NO_ERROR);
    }

    /**
     * @dev Function to fetch KYC verification status of a customer
     */
    function verifyKYC(address customer) public view returns(bool) {
        return customersWithKYC[customer];
    }

    /**
     * @dev Function to fetch KYC Admin status of an admin
     */
    function checkKYCAdmin(address _KYCAdmin) public view returns(bool) {
        return KYCAdmins[_KYCAdmin];
    }

    /**
     * @dev Liquidator Integration
     */

    /**
     * @dev Modifier to check if the caller of the function is a Liquidator
     */
    modifier isLiquidator {
        // Check caller = Liquidator
        if (!liquidators[msg.sender]) {
            emitError(Error.LIQUIDATOR_CHECK_FAILED, FailureInfo.LIQUIDATOR_CHECK_FAILED);
        } else {
            require(liquidators[msg.sender],"Customer is not a Liquidator");
            _;
        }
    }

    /**
     * @dev Function for use by the admin of the contract to add Liquidators
     */
    function addLiquidator(address liquidator) public returns(uint) {
        // Check caller = admin
        if (msg.sender != admin) {
            return fail(Error.LIQUIDATOR_ADD_OR_DELETE_ADMIN_CHECK_FAILED, FailureInfo.LIQUIDATOR_ADD_OR_DELETE_ADMIN_CHECK_FAILED);
        }
        liquidators[liquidator] = true;
        emit LiquidatorAdded(liquidator);
        return uint(Error.NO_ERROR);
    }

    /**
     * @dev Function for use by the admin of the contract to remove Liquidators
     */
    function removeLiquidator(address liquidator) public returns(uint) {
        // Check caller = admin
        if (msg.sender != admin) {
            return fail(Error.LIQUIDATOR_ADD_OR_DELETE_ADMIN_CHECK_FAILED, FailureInfo.LIQUIDATOR_ADD_OR_DELETE_ADMIN_CHECK_FAILED);
        }
        liquidators[liquidator] = false;
        emit LiquidatorRemoved(liquidator);
        return uint(Error.NO_ERROR);
    }

    /**
     * @dev Function to fetch Liquidator status of a customer
     */
    function verifyLiquidator(address liquidator) public view returns(bool) {
        return liquidators[liquidator];
    }

    /**
     * @dev Simple function to calculate min between two numbers.
     */
    function min(uint a, uint b) pure internal returns (uint) {
        if (a < b) {
            return a;
        } else {
            return b;
        }
    }

    /**
     * @dev Function to simply retrieve block number
     *      This exists mainly for inheriting test contracts to stub this result.
     */
    function getBlockNumber() internal view returns (uint) {
        return block.number;
    }

    /**
     * @dev Adds a given asset to the list of collateral markets. This operation is impossible to reverse.
     *      Note: this will not add the asset if it already exists.
     */
    function addCollateralMarket(address asset) internal {
        for (uint i = 0; i < collateralMarkets.length; i++) {
            if (collateralMarkets[i] == asset) {
                return;
            }
        }

        collateralMarkets.push(asset);
    }

    /**
     * @notice return the number of elements in `collateralMarkets`
     * @dev you can then externally call `collateralMarkets(uint)` to pull each market address
     * @return the length of `collateralMarkets`
     */
    function getCollateralMarketsLength() public view returns (uint) {
        return collateralMarkets.length;
    }

    /**
     * @dev Calculates a new supply index based on the prevailing interest rates applied over time
     *      This is defined as `we multiply the most recent supply index by (1 + blocks times rate)`
     */
    function calculateInterestIndex(uint startingInterestIndex, uint interestRateMantissa, uint blockStart, uint blockEnd) pure internal returns (Error, uint) {

        // Get the block delta
        (Error err0, uint blockDelta) = sub(blockEnd, blockStart);
        if (err0 != Error.NO_ERROR) {
            return (err0, 0);
        }

        // Scale the interest rate times number of blocks
        // Note: Doing Exp construction inline to avoid `CompilerError: Stack too deep, try removing local variables.`
        (Error err1, Exp memory blocksTimesRate) = mulScalar(Exp({mantissa: interestRateMantissa}), blockDelta);
        if (err1 != Error.NO_ERROR) {
            return (err1, 0);
        }

        // Add one to that result (which is really Exp({mantissa: expScale}) which equals 1.0)
        (Error err2, Exp memory onePlusBlocksTimesRate) = addExp(blocksTimesRate, Exp({mantissa: mantissaOne}));
        if (err2 != Error.NO_ERROR) {
            return (err2, 0);
        }

        // Then scale that accumulated interest by the old interest index to get the new interest index
        (Error err3, Exp memory newInterestIndexExp) = mulScalar(onePlusBlocksTimesRate, startingInterestIndex);
        if (err3 != Error.NO_ERROR) {
            return (err3, 0);
        }

        // Finally, truncate the interest index. This works only if interest index starts large enough
        // that is can be accurately represented with a whole number.
        return (Error.NO_ERROR, truncate(newInterestIndexExp));
    }

    /**
     * @dev Calculates a new balance based on a previous balance and a pair of interest indices
     *      This is defined as: `The user's last balance checkpoint is multiplied by the currentSupplyIndex
     *      value and divided by the user's checkpoint index value`
     *
     *      TODO: Is there a way to handle this that is less likely to overflow?
     */
    function calculateBalance(uint startingBalance, uint interestIndexStart, uint interestIndexEnd) pure internal returns (Error, uint) {
        if (startingBalance == 0) {
            // We are accumulating interest on any previous balance; if there's no previous balance, then there is
            // nothing to accumulate.
            return (Error.NO_ERROR, 0);
        }
        (Error err0, uint balanceTimesIndex) = mul(startingBalance, interestIndexEnd);
        if (err0 != Error.NO_ERROR) {
            return (err0, 0);
        }

        return div(balanceTimesIndex, interestIndexStart);
    }

    /**
     * @dev Gets the price for the amount specified of the given asset.
     */
    function getPriceForAssetAmount(address asset, uint assetAmount) internal view returns (Error, Exp memory)  {
        (Error err, Exp memory assetPrice) = fetchAssetPrice(asset);
        if (err != Error.NO_ERROR) {
            return (err, Exp({mantissa: 0}));
        }

        if (isZeroExp(assetPrice)) {
            return (Error.MISSING_ASSET_PRICE, Exp({mantissa: 0}));
        }

        return mulScalar(assetPrice, assetAmount); // assetAmountWei * oraclePrice = assetValueInEth
    }

    /**
     * @dev Gets the price for the amount specified of the given asset multiplied by the current
     *      collateral ratio (i.e., assetAmountWei * collateralRatio * oraclePrice = totalValueInEth).
     *      We will group this as `(oraclePrice * collateralRatio) * assetAmountWei`
     */
    function getPriceForAssetAmountMulCollatRatio(address asset, uint assetAmount) internal view returns (Error, Exp memory)  {
        Error err;
        Exp memory assetPrice;
        Exp memory scaledPrice;
        (err, assetPrice) = fetchAssetPrice(asset);
        if (err != Error.NO_ERROR) {
            return (err, Exp({mantissa: 0}));
        }

        if (isZeroExp(assetPrice)) {
            return (Error.MISSING_ASSET_PRICE, Exp({mantissa: 0}));
        }

        // Now, multiply the assetValue by the collateral ratio
        (err, scaledPrice) = mulExp(collateralRatio, assetPrice);
        if (err != Error.NO_ERROR) {
            return (err, Exp({mantissa: 0}));
        }

        // Get the price for the given asset amount
        return mulScalar(scaledPrice, assetAmount);
    }

    /**
     * @dev Calculates the origination fee added to a given borrowAmount
     *      This is simply `(1 + originationFee) * borrowAmount`
     *
     *      TODO: Track at what magnitude this fee rounds down to zero?
     */
    function calculateBorrowAmountWithFee(uint borrowAmount) view internal returns (Error, uint) {
        // When origination fee is zero, the amount with fee is simply equal to the amount
        if (isZeroExp(originationFee)) {
            return (Error.NO_ERROR, borrowAmount);
        }

        (Error err0, Exp memory originationFeeFactor) = addExp(originationFee, Exp({mantissa: mantissaOne}));
        if (err0 != Error.NO_ERROR) {
            return (err0, 0);
        }

        (Error err1, Exp memory borrowAmountWithFee) = mulScalar(originationFeeFactor, borrowAmount);
        if (err1 != Error.NO_ERROR) {
            return (err1, 0);
        }

        return (Error.NO_ERROR, truncate(borrowAmountWithFee));
    }

    /**
     * @dev fetches the price of asset from the PriceOracle and converts it to Exp
     * @param asset asset whose price should be fetched
     */
    function fetchAssetPrice(address asset) internal view returns (Error, Exp memory) {
        if (oracle == address(0)) {
            return (Error.ZERO_ORACLE_ADDRESS, Exp({mantissa: 0}));
        }

        uint priceMantissa = priceOracle.getAssetPrice(asset);

        return (Error.NO_ERROR, Exp({mantissa: priceMantissa}));
    }

    /**
     * @notice Reads scaled price of specified asset from the price oracle
     * @dev Reads scaled price of specified asset from the price oracle.
     *      The plural name is to match a previous storage mapping that this function replaced.
     * @param asset Asset whose price should be retrieved
     * @return 0 on an error or missing price, the price scaled by 1e18 otherwise
     */
    function assetPrices(address asset) public view returns (uint) {
        (Error err, Exp memory result) = fetchAssetPrice(asset);
        if (err != Error.NO_ERROR) {
            return 0;
        }
        return result.mantissa;
    }

    /**
     * @dev Gets the amount of the specified asset given the specified Eth value
     *      ethValue / oraclePrice = assetAmountWei
     *      If there's no oraclePrice, this returns (Error.DIVISION_BY_ZERO, 0)
     */
    function getAssetAmountForValue(address asset, Exp ethValue) internal view returns (Error, uint) {
        Error err;
        Exp memory assetPrice;
        Exp memory assetAmount;

        (err, assetPrice) = fetchAssetPrice(asset);
        if (err != Error.NO_ERROR) {
            return (err, 0);
        }

        (err, assetAmount) = divExp(ethValue, assetPrice);
        if (err != Error.NO_ERROR) {
            return (err, 0);
        }

        return (Error.NO_ERROR, truncate(assetAmount));
    }

    /**
     * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @param newPendingAdmin New pending admin.
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     *
     * TODO: Should we add a second arg to verify, like a checksum of `newAdmin` address?
     */
    function _setPendingAdmin(address newPendingAdmin) public returns (uint) {
        // Check caller = admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PENDING_ADMIN_OWNER_CHECK);
        }

        // save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;
        // Store pendingAdmin = newPendingAdmin
        pendingAdmin = newPendingAdmin;

        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
     * @dev Admin function for pending admin to accept role and update admin
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _acceptAdmin() public returns (uint) {
        // Check caller = pendingAdmin
        // msg.sender can't be zero
        if (msg.sender != pendingAdmin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.ACCEPT_ADMIN_PENDING_ADMIN_CHECK);
        }

        // Save current value for inclusion in log
        address oldAdmin = admin;
        // Store admin = pendingAdmin
        admin = pendingAdmin;
        // Clear the pending value
        pendingAdmin = 0;

        emit NewAdmin(oldAdmin, msg.sender);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Set new oracle, who can set asset prices
     * @dev Admin function to change oracle
     * @param newOracle New oracle address
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setOracle(address newOracle) public returns (uint) {
        // Check caller = admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_ORACLE_OWNER_CHECK);
        }

        // Verify contract at newOracle address supports assetPrices call.
        // This will revert if it doesn't.
        // ChainLink priceOracleTemp = ChainLink(newOracle);
        // priceOracleTemp.getAssetPrice(address(0));

        address oldOracle = oracle;

        // Store oracle = newOracle
        oracle = newOracle;
        // Initialize the Chainlink contract in priceOracle
        priceOracle = ChainLink(newOracle);

        emit NewOracle(oldOracle, newOracle);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice set `paused` to the specified state
     * @dev Admin function to pause or resume the market
     * @param requestedState value to assign to `paused`
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setPaused(bool requestedState) public returns (uint) {
        // Check caller = admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PAUSED_OWNER_CHECK);
        }

        paused = requestedState;
        emit SetPaused(requestedState);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice returns the liquidity for given account.
     *         a positive result indicates ability to borrow, whereas
     *         a negative result indicates a shortfall which may be liquidated
     * @dev returns account liquidity in terms of eth-wei value, scaled by 1e18
     *      note: this includes interest trued up on all balances
     * @param account the account to examine
     * @return signed integer in terms of eth-wei (negative indicates a shortfall)
     */
    function getAccountLiquidity(address account) public view returns (int) {
        (Error err, Exp memory accountLiquidity, Exp memory accountShortfall) = calculateAccountLiquidity(account);
        require(err == Error.NO_ERROR);

        if (isZeroExp(accountLiquidity)) {
            return -1 * int(truncate(accountShortfall));
        } else {
            return int(truncate(accountLiquidity));
        }
    }

    /**
     * @notice return supply balance with any accumulated interest for `asset` belonging to `account`
     * @dev returns supply balance with any accumulated interest for `asset` belonging to `account`
     * @param account the account to examine
     * @param asset the market asset whose supply balance belonging to `account` should be checked
     * @return uint supply balance on success, throws on failed assertion otherwise
     */
    function getSupplyBalance(address account, address asset) view public returns (uint) {
        Error err;
        uint newSupplyIndex;
        uint userSupplyCurrent;

        Market storage market = markets[asset];
        Balance storage supplyBalance = supplyBalances[account][asset];

        // Calculate the newSupplyIndex, needed to calculate user's supplyCurrent
        (err, newSupplyIndex) = calculateInterestIndex(market.supplyIndex, market.supplyRateMantissa, market.blockNumber, getBlockNumber());
        require(err == Error.NO_ERROR);

        // Use newSupplyIndex and stored principal to calculate the accumulated balance
        (err, userSupplyCurrent) = calculateBalance(supplyBalance.principal, supplyBalance.interestIndex, newSupplyIndex);
        require(err == Error.NO_ERROR);

        return userSupplyCurrent;
    }

    /**
     * @notice return borrow balance with any accumulated interest for `asset` belonging to `account`
     * @dev returns borrow balance with any accumulated interest for `asset` belonging to `account`
     * @param account the account to examine
     * @param asset the market asset whose borrow balance belonging to `account` should be checked
     * @return uint borrow balance on success, throws on failed assertion otherwise
     */
    function getBorrowBalance(address account, address asset) view public returns (uint) {
        Error err;
        uint newBorrowIndex;
        uint userBorrowCurrent;

        Market storage market = markets[asset];
        Balance storage borrowBalance = borrowBalances[account][asset];

        // Calculate the newBorrowIndex, needed to calculate user's borrowCurrent
        (err, newBorrowIndex) = calculateInterestIndex(market.borrowIndex, market.borrowRateMantissa, market.blockNumber, getBlockNumber());
        require(err == Error.NO_ERROR);

        // Use newBorrowIndex and stored principal to calculate the accumulated balance
        (err, userBorrowCurrent) = calculateBalance(borrowBalance.principal, borrowBalance.interestIndex, newBorrowIndex);
        require(err == Error.NO_ERROR);

        return userBorrowCurrent;
    }


    /**
     * @notice Supports a given market (asset) for use
     * @dev Admin function to add support for a market
     * @param asset Asset to support; MUST already have a non-zero price set
     * @param interestRateModel InterestRateModel to use for the asset
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _supportMarket(address asset, InterestRateModel interestRateModel) public returns (uint) {
        // Check caller = admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SUPPORT_MARKET_OWNER_CHECK);
        }

        (Error err, Exp memory assetPrice) = fetchAssetPrice(asset);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.SUPPORT_MARKET_FETCH_PRICE_FAILED);
        }

        if (isZeroExp(assetPrice)) {
            return fail(Error.ASSET_NOT_PRICED, FailureInfo.SUPPORT_MARKET_PRICE_CHECK);
        }

        // Set the interest rate model to `modelAddress`
        markets[asset].interestRateModel = interestRateModel;

        // Append asset to collateralAssets if not set
        addCollateralMarket(asset);

        // Set market isSupported to true
        markets[asset].isSupported = true;

        // Default supply and borrow index to 1e18
        if (markets[asset].supplyIndex == 0) {
            markets[asset].supplyIndex = initialInterestIndex;
        }

        if (markets[asset].borrowIndex == 0) {
            markets[asset].borrowIndex = initialInterestIndex;
        }

        emit SupportedMarket(asset, interestRateModel);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Suspends a given *supported* market (asset) from use.
     *         Assets in this state do count for collateral, but users may only withdraw, payBorrow,
     *         and liquidate the asset. The liquidate function no longer checks collateralization.
     * @dev Admin function to suspend a market
     * @param asset Asset to suspend
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _suspendMarket(address asset) public returns (uint) {
        // Check caller = admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SUSPEND_MARKET_OWNER_CHECK);
        }

        // If the market is not configured at all, we don't want to add any configuration for it.
        // If we find !markets[asset].isSupported then either the market is not configured at all, or it
        // has already been marked as unsupported. We can just return without doing anything.
        // Caller is responsible for knowing the difference between not-configured and already unsupported.
        if (!markets[asset].isSupported) {
            return uint(Error.NO_ERROR);
        }

        // If we get here, we know market is configured and is supported, so set isSupported to false
        markets[asset].isSupported = false;

        emit SuspendedMarket(asset);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Sets the risk parameters: collateral ratio and liquidation discount
     * @dev Owner function to set the risk parameters
     * @param collateralRatioMantissa rational collateral ratio, scaled by 1e18. The de-scaled value must be >= 1.1
     * @param liquidationDiscountMantissa rational liquidation discount, scaled by 1e18. The de-scaled value must be <= 0.1 and must be less than (descaled collateral ratio minus 1)
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setRiskParameters(uint collateralRatioMantissa, uint liquidationDiscountMantissa, uint _minimumCollateralRatioMantissa, uint _maximumLiquidationDiscountMantissa) public returns (uint) {
        // Check caller = admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_RISK_PARAMETERS_OWNER_CHECK);
        }

        minimumCollateralRatioMantissa =  _minimumCollateralRatioMantissa;
        maximumLiquidationDiscountMantissa =  _maximumLiquidationDiscountMantissa;
        Exp memory newCollateralRatio = Exp({mantissa: collateralRatioMantissa});
        Exp memory newLiquidationDiscount = Exp({mantissa: liquidationDiscountMantissa});
        Exp memory minimumCollateralRatio = Exp({mantissa: minimumCollateralRatioMantissa});
        Exp memory maximumLiquidationDiscount = Exp({mantissa: maximumLiquidationDiscountMantissa});

        Error err;
        Exp memory newLiquidationDiscountPlusOne;

        // Make sure new collateral ratio value is not below minimum value
        if (lessThanExp(newCollateralRatio, minimumCollateralRatio)) {
            return fail(Error.INVALID_COLLATERAL_RATIO, FailureInfo.SET_RISK_PARAMETERS_VALIDATION);
        }

        // Make sure new liquidation discount does not exceed the maximum value, but reverse operands so we can use the
        // existing `lessThanExp` function rather than adding a `greaterThan` function to Exponential.
        if (lessThanExp(maximumLiquidationDiscount, newLiquidationDiscount)) {
            return fail(Error.INVALID_LIQUIDATION_DISCOUNT, FailureInfo.SET_RISK_PARAMETERS_VALIDATION);
        }

        // C = L+1 is not allowed because it would cause division by zero error in `calculateDiscountedRepayToEvenAmount`
        // C < L+1 is not allowed because it would cause integer underflow error in `calculateDiscountedRepayToEvenAmount`
        (err, newLiquidationDiscountPlusOne) = addExp(newLiquidationDiscount, Exp({mantissa: mantissaOne}));
        assert(err == Error.NO_ERROR); // We already validated that newLiquidationDiscount does not approach overflow size

        if (lessThanOrEqualExp(newCollateralRatio, newLiquidationDiscountPlusOne)) {
            return fail(Error.INVALID_COMBINED_RISK_PARAMETERS, FailureInfo.SET_RISK_PARAMETERS_VALIDATION);
        }

        // Save current values so we can emit them in log.
        Exp memory oldCollateralRatio = collateralRatio;
        Exp memory oldLiquidationDiscount = liquidationDiscount;

        // Store new values
        collateralRatio = newCollateralRatio;
        liquidationDiscount = newLiquidationDiscount;

        emit NewRiskParameters(oldCollateralRatio.mantissa, collateralRatioMantissa, oldLiquidationDiscount.mantissa, liquidationDiscountMantissa, minimumCollateralRatioMantissa, maximumLiquidationDiscountMantissa);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Sets the origination fee (which is a multiplier on new borrows)
     * @dev Owner function to set the origination fee
     * @param originationFeeMantissa rational collateral ratio, scaled by 1e18. The de-scaled value must be >= 1.1
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setOriginationFee(uint originationFeeMantissa) public returns (uint) {
        // Check caller = admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_ORIGINATION_FEE_OWNER_CHECK);
        }

        // Save current value so we can emit it in log.
        Exp memory oldOriginationFee = originationFee;

        originationFee = Exp({mantissa: originationFeeMantissa});

        emit NewOriginationFee(oldOriginationFee.mantissa, originationFeeMantissa);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Sets the interest rate model for a given market
     * @dev Admin function to set interest rate model
     * @param asset Asset to support
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setMarketInterestRateModel(address asset, InterestRateModel interestRateModel) public returns (uint) {
        // Check caller = admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_MARKET_INTEREST_RATE_MODEL_OWNER_CHECK);
        }

        // Set the interest rate model to `modelAddress`
        markets[asset].interestRateModel = interestRateModel;

        emit SetMarketInterestRateModel(asset, interestRateModel);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice withdraws `amount` of `asset` from equity for asset, as long as `amount` <= equity. Equity= cash - (supply + borrows)
     * @dev withdraws `amount` of `asset` from equity  for asset, enforcing amount <= cash - (supply + borrows)
     * @param asset asset whose equity should be withdrawn
     * @param amount amount of equity to withdraw; must not exceed equity available
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _withdrawEquity(address asset, uint amount) public returns (uint) {
        // Check caller = admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.EQUITY_WITHDRAWAL_MODEL_OWNER_CHECK);
        }

        // Check that amount is less than cash (from ERC-20 of self) plus borrows minus supply.
        uint cash = getCash(asset);
        (Error err0, uint equity) = addThenSub(cash, markets[asset].totalBorrows, markets[asset].totalSupply);
        if (err0 != Error.NO_ERROR) {
            return fail(err0, FailureInfo.EQUITY_WITHDRAWAL_CALCULATE_EQUITY);
        }

        if (amount > equity) {
            return fail(Error.EQUITY_INSUFFICIENT_BALANCE, FailureInfo.EQUITY_WITHDRAWAL_AMOUNT_VALIDATION);
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        if(asset != wethAddress) { // Withdrawal should happen as Ether directly
            // We ERC-20 transfer the asset out of the protocol to the admin
            Error err2 = doTransferOut(asset, admin, amount);
            if (err2 != Error.NO_ERROR) {
                // This is safe since it's our first interaction and it didn't do anything if it failed
                return fail(err2, FailureInfo.EQUITY_WITHDRAWAL_TRANSFER_OUT_FAILED);
            }
        } else {
            uint withdrawalerr = withdrawEther(admin,amount); // send Ether to user
            if(withdrawalerr != 0){
                return uint(withdrawalerr); // success
            }
        }

        //event EquityWithdrawn(address asset, uint equityAvailableBefore, uint amount, address owner)
        emit EquityWithdrawn(asset, equity, amount, admin);

        return uint(Error.NO_ERROR); // success
    }

    /**
     * @dev Set WETH token contract address
     * @param wethContractAddress Enter the WETH token address
     */
    function setWethAddress(address wethContractAddress) public returns (uint) {
        // Check caller = admin
        if (msg.sender != admin) {
            return fail(Error.SET_WETH_ADDRESS_ADMIN_CHECK_FAILED, FailureInfo.SET_WETH_ADDRESS_ADMIN_CHECK_FAILED);
        }
        wethAddress = wethContractAddress;
        WETHContract = AlkemiWETH(wethAddress);
        emit WETHAddressSet(wethContractAddress);
        return uint(Error.NO_ERROR);
    }

    /**
     * @dev Convert Ether supplied by user into WETH tokens and then supply corresponding WETH to user
     * @return errors if any
     * @param etherAmount Amount of ether to be converted to WETH
     * @param user User account address
     */
    function supplyEther(address user, uint etherAmount) internal returns (uint) {
        user; // To silence the warning of unused local variable
        if(wethAddress != address(0)){
            WETHContract.deposit.value(etherAmount)();
            return uint(Error.NO_ERROR);
        }
        else {
            return uint(Error.WETH_ADDRESS_NOT_SET_ERROR);
        }
    }

    /**
     * @dev Revert Ether paid by user back to user's account in case transaction fails due to some other reason
     * @param etherAmount Amount of ether to be sent back to user
     * @param user User account address
     */
    function revertEtherToUser(address user, uint etherAmount) internal {
        if(etherAmount > 0){
            user.transfer(etherAmount);
        }
    }

    /**
     * @notice supply `amount` of `asset` (which must be supported) to `msg.sender` in the protocol
     * @dev add amount of supported asset to msg.sender's account
     * @param asset The market asset to supply
     * @param amount The amount to supply
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function supply(address asset, uint amount) public payable isKYCVerifiedCustomer returns (uint) {
        if (paused) {
            revertEtherToUser(msg.sender,msg.value);
            return fail(Error.CONTRACT_PAUSED, FailureInfo.SUPPLY_CONTRACT_PAUSED);
        }

        Market storage market = markets[asset];
        Balance storage balance = supplyBalances[msg.sender][asset];

        SupplyLocalVars memory localResults; // Holds all our uint calculation results
        Error err; // Re-used for every function call that includes an Error in its return value(s).
        uint rateCalculationResultCode; // Used for 2 interest rate calculation calls

        // Fail if market not supported
        if (!market.isSupported) {
            revertEtherToUser(msg.sender,msg.value);
            return fail(Error.MARKET_NOT_SUPPORTED, FailureInfo.SUPPLY_MARKET_NOT_SUPPORTED);
        }
        if(asset != wethAddress) { // WETH is supplied to AlkemiEarnVerified contract in case of ETH automatically
            // Fail gracefully if asset is not approved or has insufficient balance
            revertEtherToUser(msg.sender,msg.value);
            err = checkTransferIn(asset, msg.sender, amount);
            if (err != Error.NO_ERROR) {
                return fail(err, FailureInfo.SUPPLY_TRANSFER_IN_NOT_POSSIBLE);
            }
        }

        // We calculate the newSupplyIndex, user's supplyCurrent and supplyUpdated for the asset
        (err, localResults.newSupplyIndex) = calculateInterestIndex(market.supplyIndex, market.supplyRateMantissa, market.blockNumber, getBlockNumber());
        if (err != Error.NO_ERROR) {
            revertEtherToUser(msg.sender,msg.value);
            return fail(err, FailureInfo.SUPPLY_NEW_SUPPLY_INDEX_CALCULATION_FAILED);
        }

        (err, localResults.userSupplyCurrent) = calculateBalance(balance.principal, balance.interestIndex, localResults.newSupplyIndex);
        if (err != Error.NO_ERROR) {
            revertEtherToUser(msg.sender,msg.value);
            return fail(err, FailureInfo.SUPPLY_ACCUMULATED_BALANCE_CALCULATION_FAILED);
        }

        (err, localResults.userSupplyUpdated) = add(localResults.userSupplyCurrent, amount);
        if (err != Error.NO_ERROR) {
            revertEtherToUser(msg.sender,msg.value);
            return fail(err, FailureInfo.SUPPLY_NEW_TOTAL_BALANCE_CALCULATION_FAILED);
        }

        // We calculate the protocol's totalSupply by subtracting the user's prior checkpointed balance, adding user's updated supply
        (err, localResults.newTotalSupply) = addThenSub(market.totalSupply, localResults.userSupplyUpdated, balance.principal);
        if (err != Error.NO_ERROR) {
            revertEtherToUser(msg.sender,msg.value);
            return fail(err, FailureInfo.SUPPLY_NEW_TOTAL_SUPPLY_CALCULATION_FAILED);
        }

        // We need to calculate what the updated cash will be after we transfer in from user
        localResults.currentCash = getCash(asset);

        (err, localResults.updatedCash) = add(localResults.currentCash, amount);
        if (err != Error.NO_ERROR) {
            revertEtherToUser(msg.sender,msg.value);
            return fail(err, FailureInfo.SUPPLY_NEW_TOTAL_CASH_CALCULATION_FAILED);
        }

        // The utilization rate has changed! We calculate a new supply index and borrow index for the asset, and save it.
        (rateCalculationResultCode, localResults.newSupplyRateMantissa) = market.interestRateModel.getSupplyRate(asset, localResults.updatedCash, market.totalBorrows);
        if (rateCalculationResultCode != 0) {
            revertEtherToUser(msg.sender,msg.value);
            return failOpaque(FailureInfo.SUPPLY_NEW_SUPPLY_RATE_CALCULATION_FAILED, rateCalculationResultCode);
        }

        // We calculate the newBorrowIndex (we already had newSupplyIndex)
        (err, localResults.newBorrowIndex) = calculateInterestIndex(market.borrowIndex, market.borrowRateMantissa, market.blockNumber, getBlockNumber());
        if (err != Error.NO_ERROR) {
            revertEtherToUser(msg.sender,msg.value);
            return fail(err, FailureInfo.SUPPLY_NEW_BORROW_INDEX_CALCULATION_FAILED);
        }

        (rateCalculationResultCode, localResults.newBorrowRateMantissa) = market.interestRateModel.getBorrowRate(asset, localResults.updatedCash, market.totalBorrows);
        if (rateCalculationResultCode != 0) {
            revertEtherToUser(msg.sender,msg.value);
            return failOpaque(FailureInfo.SUPPLY_NEW_BORROW_RATE_CALCULATION_FAILED, rateCalculationResultCode);
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)
        if(asset != wethAddress) { // WETH is supplied to AlkemiEarnVerified contract in case of ETH automatically
            // We ERC-20 transfer the asset into the protocol (note: pre-conditions already checked above)
            revertEtherToUser(msg.sender,msg.value);
            err = doTransferIn(asset, msg.sender, amount);
            if (err != Error.NO_ERROR) {
                // This is safe since it's our first interaction and it didn't do anything if it failed
                return fail(err, FailureInfo.SUPPLY_TRANSFER_IN_FAILED);
            }
        } else {
            if (msg.value == amount){
                uint supplyError = supplyEther(msg.sender,msg.value);
                if(supplyError !=0 ){
                    revertEtherToUser(msg.sender,msg.value);
                    return fail(Error.WETH_ADDRESS_NOT_SET_ERROR, FailureInfo.WETH_ADDRESS_NOT_SET_ERROR);
                }
            }
            else {
                revertEtherToUser(msg.sender,msg.value);
                return fail(Error.ETHER_AMOUNT_MISMATCH_ERROR, FailureInfo.ETHER_AMOUNT_MISMATCH_ERROR);
            }
        }

        // Save market updates
        market.blockNumber = getBlockNumber();
        market.totalSupply =  localResults.newTotalSupply;
        market.supplyRateMantissa = localResults.newSupplyRateMantissa;
        market.supplyIndex = localResults.newSupplyIndex;
        market.borrowRateMantissa = localResults.newBorrowRateMantissa;
        market.borrowIndex = localResults.newBorrowIndex;

        // Save user updates
        localResults.startingBalance = balance.principal; // save for use in `SupplyReceived` event
        balance.principal = localResults.userSupplyUpdated;
        balance.interestIndex = localResults.newSupplyIndex;

        emit SupplyReceived(msg.sender, asset, amount, localResults.startingBalance, localResults.userSupplyUpdated);

        return uint(Error.NO_ERROR); // success
    }

    /**
     * @notice withdraw `amount` of `ether` from sender's account to sender's address
     * @dev withdraw `amount` of `ether` from msg.sender's account to msg.sender
     * @param etherAmount Amount of ether to be converted to WETH
     * @param user User account address
     */
    function withdrawEther(address user, uint etherAmount) internal returns (uint) {
            WETHContract.withdraw(user,etherAmount);
            return uint(Error.NO_ERROR);
    }

    /**
     * @notice send Ether from contract to a user
     * @dev Fail safe plan to send Ether stuck in contract in case there is a problem with withdraw
     */
    function sendEtherToUser(address user, uint amount) public returns (uint) {
        // Check caller = admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SEND_ETHER_ADMIN_CHECK_FAILED);
        }
        user.transfer(amount);
        return uint(Error.NO_ERROR);
    }

    /**
     * @notice withdraw `amount` of `asset` from sender's account to sender's address
     * @dev withdraw `amount` of `asset` from msg.sender's account to msg.sender
     * @param asset The market asset to withdraw
     * @param requestedAmount The amount to withdraw (or -1 for max)
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function withdraw(address asset, uint requestedAmount) public returns (uint) {
        if (paused) {
            return fail(Error.CONTRACT_PAUSED, FailureInfo.WITHDRAW_CONTRACT_PAUSED);
        }

        Market storage market = markets[asset];
        Balance storage supplyBalance = supplyBalances[msg.sender][asset];

        WithdrawLocalVars memory localResults; // Holds all our calculation results
        Error err; // Re-used for every function call that includes an Error in its return value(s).
        uint rateCalculationResultCode; // Used for 2 interest rate calculation calls

        // We calculate the user's accountLiquidity and accountShortfall.
        (err, localResults.accountLiquidity, localResults.accountShortfall) = calculateAccountLiquidity(msg.sender);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.WITHDRAW_ACCOUNT_LIQUIDITY_CALCULATION_FAILED);
        }

        // We calculate the newSupplyIndex, user's supplyCurrent and supplyUpdated for the asset
        (err, localResults.newSupplyIndex) = calculateInterestIndex(market.supplyIndex, market.supplyRateMantissa, market.blockNumber, getBlockNumber());
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.WITHDRAW_NEW_SUPPLY_INDEX_CALCULATION_FAILED);
        }

        (err, localResults.userSupplyCurrent) = calculateBalance(supplyBalance.principal, supplyBalance.interestIndex, localResults.newSupplyIndex);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.WITHDRAW_ACCUMULATED_BALANCE_CALCULATION_FAILED);
        }

        // If the user specifies -1 amount to withdraw ("max"),  withdrawAmount => the lesser of withdrawCapacity and supplyCurrent
        if (requestedAmount == uint(-1)) {
            (err, localResults.withdrawCapacity) = getAssetAmountForValue(asset, localResults.accountLiquidity);
            if (err != Error.NO_ERROR) {
                return fail(err, FailureInfo.WITHDRAW_CAPACITY_CALCULATION_FAILED);
            }
            localResults.withdrawAmount = min(localResults.withdrawCapacity, localResults.userSupplyCurrent);
        } else {
            localResults.withdrawAmount = requestedAmount;
        }

        // From here on we should NOT use requestedAmount.

        // Fail gracefully if protocol has insufficient cash
        // If protocol has insufficient cash, the sub operation will underflow.
        localResults.currentCash = getCash(asset);
        (err, localResults.updatedCash) = sub(localResults.currentCash, localResults.withdrawAmount);
        if (err != Error.NO_ERROR) {
            return fail(Error.TOKEN_INSUFFICIENT_CASH, FailureInfo.WITHDRAW_TRANSFER_OUT_NOT_POSSIBLE);
        }

        // We check that the amount is less than or equal to supplyCurrent
        // If amount is greater than supplyCurrent, this will fail with Error.INTEGER_UNDERFLOW
        (err, localResults.userSupplyUpdated) = sub(localResults.userSupplyCurrent, localResults.withdrawAmount);
        if (err != Error.NO_ERROR) {
            return fail(Error.INSUFFICIENT_BALANCE, FailureInfo.WITHDRAW_NEW_TOTAL_BALANCE_CALCULATION_FAILED);
        }

        // Fail if customer already has a shortfall
        if (!isZeroExp(localResults.accountShortfall)) {
            return fail(Error.INSUFFICIENT_LIQUIDITY, FailureInfo.WITHDRAW_ACCOUNT_SHORTFALL_PRESENT);
        }

        // We want to know the user's withdrawCapacity, denominated in the asset
        // Customer's withdrawCapacity of asset is (accountLiquidity in Eth)/ (price of asset in Eth)
        // Equivalently, we calculate the eth value of the withdrawal amount and compare it directly to the accountLiquidity in Eth
        (err, localResults.ethValueOfWithdrawal) = getPriceForAssetAmount(asset, localResults.withdrawAmount); // amount * oraclePrice = ethValueOfWithdrawal
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.WITHDRAW_AMOUNT_VALUE_CALCULATION_FAILED);
        }

        // We check that the amount is less than withdrawCapacity (here), and less than or equal to supplyCurrent (below)
        if (lessThanExp(localResults.accountLiquidity, localResults.ethValueOfWithdrawal) ) {
            return fail(Error.INSUFFICIENT_LIQUIDITY, FailureInfo.WITHDRAW_AMOUNT_LIQUIDITY_SHORTFALL);
        }

        // We calculate the protocol's totalSupply by subtracting the user's prior checkpointed balance, adding user's updated supply.
        // Note that, even though the customer is withdrawing, if they've accumulated a lot of interest since their last
        // action, the updated balance *could* be higher than the prior checkpointed balance.
        (err, localResults.newTotalSupply) = addThenSub(market.totalSupply, localResults.userSupplyUpdated, supplyBalance.principal);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.WITHDRAW_NEW_TOTAL_SUPPLY_CALCULATION_FAILED);
        }

        // The utilization rate has changed! We calculate a new supply index and borrow index for the asset, and save it.
        (rateCalculationResultCode, localResults.newSupplyRateMantissa) = market.interestRateModel.getSupplyRate(asset, localResults.updatedCash, market.totalBorrows);
        if (rateCalculationResultCode != 0) {
            return failOpaque(FailureInfo.WITHDRAW_NEW_SUPPLY_RATE_CALCULATION_FAILED, rateCalculationResultCode);
        }

        // We calculate the newBorrowIndex
        (err, localResults.newBorrowIndex) = calculateInterestIndex(market.borrowIndex, market.borrowRateMantissa, market.blockNumber, getBlockNumber());
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.WITHDRAW_NEW_BORROW_INDEX_CALCULATION_FAILED);
        }

        (rateCalculationResultCode, localResults.newBorrowRateMantissa) = market.interestRateModel.getBorrowRate(asset, localResults.updatedCash, market.totalBorrows);
        if (rateCalculationResultCode != 0) {
            return failOpaque(FailureInfo.WITHDRAW_NEW_BORROW_RATE_CALCULATION_FAILED, rateCalculationResultCode);
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        if(asset != wethAddress) { // Withdrawal should happen as Ether directly
            // We ERC-20 transfer the asset into the protocol (note: pre-conditions already checked above)
            err = doTransferOut(asset, msg.sender, localResults.withdrawAmount);
            if (err != Error.NO_ERROR) {
                // This is safe since it's our first interaction and it didn't do anything if it failed
                return fail(err, FailureInfo.WITHDRAW_TRANSFER_OUT_FAILED);
            }
        } else {
            uint withdrawalerr = withdrawEther(msg.sender,localResults.withdrawAmount); // send Ether to user
            if(withdrawalerr != 0){
                return uint(withdrawalerr); // failure
            }
        }

        // Save market updates
        market.blockNumber = getBlockNumber();
        market.totalSupply =  localResults.newTotalSupply;
        market.supplyRateMantissa = localResults.newSupplyRateMantissa;
        market.supplyIndex = localResults.newSupplyIndex;
        market.borrowRateMantissa = localResults.newBorrowRateMantissa;
        market.borrowIndex = localResults.newBorrowIndex;

        // Save user updates
        localResults.startingBalance = supplyBalance.principal; // save for use in `SupplyWithdrawn` event
        supplyBalance.principal = localResults.userSupplyUpdated;
        supplyBalance.interestIndex = localResults.newSupplyIndex;

        emit SupplyWithdrawn(msg.sender, asset, localResults.withdrawAmount, localResults.startingBalance, localResults.userSupplyUpdated);
        
        return uint(Error.NO_ERROR); // success
    }

    /**
     * @dev Gets the user's account liquidity and account shortfall balances. This includes
     *      any accumulated interest thus far but does NOT actually update anything in
     *      storage, it simply calculates the account liquidity and shortfall with liquidity being
     *      returned as the first Exp, ie (Error, accountLiquidity, accountShortfall).
     */
    function calculateAccountLiquidity(address userAddress) internal view returns (Error, Exp memory, Exp memory) {
        Error err;
        uint sumSupplyValuesMantissa;
        uint sumBorrowValuesMantissa;
        (err, sumSupplyValuesMantissa, sumBorrowValuesMantissa) = calculateAccountValuesInternal(userAddress);
        if (err != Error.NO_ERROR) {
            return(err, Exp({mantissa: 0}), Exp({mantissa: 0}));
        }

        Exp memory result;

        Exp memory sumSupplyValuesFinal = Exp({mantissa: sumSupplyValuesMantissa});
        Exp memory sumBorrowValuesFinal; // need to apply collateral ratio

        (err, sumBorrowValuesFinal) = mulExp(collateralRatio, Exp({mantissa: sumBorrowValuesMantissa}));
        if (err != Error.NO_ERROR) {
            return (err, Exp({mantissa: 0}), Exp({mantissa: 0}));
        }

        // if sumSupplies < sumBorrows, then the user is under collateralized and has account shortfall.
        // else the user meets the collateral ratio and has account liquidity.
        if (lessThanExp(sumSupplyValuesFinal, sumBorrowValuesFinal)) {
            // accountShortfall = borrows - supplies
            (err, result) = subExp(sumBorrowValuesFinal, sumSupplyValuesFinal);
            assert(err == Error.NO_ERROR); // Note: we have checked that sumBorrows is greater than sumSupplies directly above, therefore `subExp` cannot fail.

            return (Error.NO_ERROR, Exp({mantissa: 0}), result);
        } else {
            // accountLiquidity = supplies - borrows
            (err, result) = subExp(sumSupplyValuesFinal, sumBorrowValuesFinal);
            assert(err == Error.NO_ERROR); // Note: we have checked that sumSupplies is greater than sumBorrows directly above, therefore `subExp` cannot fail.

            return (Error.NO_ERROR, result, Exp({mantissa: 0}));
        }
    }

    /**
     * @notice Gets the ETH values of the user's accumulated supply and borrow balances, scaled by 10e18.
     *         This includes any accumulated interest thus far but does NOT actually update anything in
     *         storage
     * @dev Gets ETH values of accumulated supply and borrow balances
     * @param userAddress account for which to sum values
     * @return (error code, sum ETH value of supplies scaled by 10e18, sum ETH value of borrows scaled by 10e18)
     * TODO: Possibly should add a Min(500, collateralMarkets.length) for extra safety
     * TODO: To help save gas we could think about using the current Market.interestIndex
     *       accumulate interest rather than calculating it
     */
    function calculateAccountValuesInternal(address userAddress) internal view returns (Error, uint, uint) {

        /** By definition, all collateralMarkets are those that contribute to the user's
         * liquidity and shortfall so we need only loop through those markets.
         * To handle avoiding intermediate negative results, we will sum all the user's
         * supply balances and borrow balances (with collateral ratio) separately and then
         * subtract the sums at the end.
         */

        AccountValueLocalVars memory localResults; // Re-used for all intermediate results
        localResults.sumSupplies = Exp({mantissa: 0});
        localResults.sumBorrows = Exp({mantissa: 0});
        Error err; // Re-used for all intermediate errors
        localResults.collateralMarketsLength = collateralMarkets.length;

        for (uint i = 0; i < localResults.collateralMarketsLength; i++) {
            localResults.assetAddress = collateralMarkets[i];
            Market storage currentMarket = markets[localResults.assetAddress];
            Balance storage supplyBalance = supplyBalances[userAddress][localResults.assetAddress];
            Balance storage borrowBalance = borrowBalances[userAddress][localResults.assetAddress];

            if (supplyBalance.principal > 0) {
                // We calculate the newSupplyIndex and user’s supplyCurrent (includes interest)
                (err, localResults.newSupplyIndex) = calculateInterestIndex(currentMarket.supplyIndex, currentMarket.supplyRateMantissa, currentMarket.blockNumber, getBlockNumber());
                if (err != Error.NO_ERROR) {
                    return (err, 0, 0);
                }

                (err, localResults.userSupplyCurrent) = calculateBalance(supplyBalance.principal, supplyBalance.interestIndex, localResults.newSupplyIndex);
                if (err != Error.NO_ERROR) {
                    return (err, 0, 0);
                }

                // We have the user's supply balance with interest so let's multiply by the asset price to get the total value
                (err, localResults.supplyTotalValue) = getPriceForAssetAmount(localResults.assetAddress, localResults.userSupplyCurrent); // supplyCurrent * oraclePrice = supplyValueInEth
                if (err != Error.NO_ERROR) {
                    return (err, 0, 0);
                }

                // Add this to our running sum of supplies
                (err, localResults.sumSupplies) = addExp(localResults.supplyTotalValue, localResults.sumSupplies);
                if (err != Error.NO_ERROR) {
                    return (err, 0, 0);
                }
            }

            if (borrowBalance.principal > 0) {
                // We perform a similar actions to get the user's borrow balance
                (err, localResults.newBorrowIndex) = calculateInterestIndex(currentMarket.borrowIndex, currentMarket.borrowRateMantissa, currentMarket.blockNumber, getBlockNumber());
                if (err != Error.NO_ERROR) {
                    return (err, 0, 0);
                }

                (err, localResults.userBorrowCurrent) = calculateBalance(borrowBalance.principal, borrowBalance.interestIndex, localResults.newBorrowIndex);
                if (err != Error.NO_ERROR) {
                    return (err, 0, 0);
                }

                // In the case of borrow, we multiply the borrow value by the collateral ratio
                (err, localResults.borrowTotalValue) = getPriceForAssetAmount(localResults.assetAddress, localResults.userBorrowCurrent); // ( borrowCurrent* oraclePrice * collateralRatio) = borrowTotalValueInEth
                if (err != Error.NO_ERROR) {
                    return (err, 0, 0);
                }

                // Add this to our running sum of borrows
                (err, localResults.sumBorrows) = addExp(localResults.borrowTotalValue, localResults.sumBorrows);
                if (err != Error.NO_ERROR) {
                    return (err, 0, 0);
                }
            }
        }

        return (Error.NO_ERROR, localResults.sumSupplies.mantissa, localResults.sumBorrows.mantissa);
    }

    /**
     * @notice Gets the ETH values of the user's accumulated supply and borrow balances, scaled by 10e18.
     *         This includes any accumulated interest thus far but does NOT actually update anything in
     *         storage
     * @dev Gets ETH values of accumulated supply and borrow balances
     * @param userAddress account for which to sum values
     * @return (uint 0=success; otherwise a failure (see ErrorReporter.sol for details),
     *          sum ETH value of supplies scaled by 10e18,
     *          sum ETH value of borrows scaled by 10e18)
     */
    function calculateAccountValues(address userAddress) public view returns (uint, uint, uint) {
        (Error err, uint supplyValue, uint borrowValue) = calculateAccountValuesInternal(userAddress);
        if (err != Error.NO_ERROR) {

            return (uint(err), 0, 0);
        }

        return (0, supplyValue, borrowValue);
    }

    /**
     * @notice Users repay borrowed assets from their own address to the protocol.
     * @param asset The market asset to repay
     * @param amount The amount to repay (or -1 for max)
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function repayBorrow(address asset, uint amount) public payable returns (uint) {
        if (paused) {
            revertEtherToUser(msg.sender,msg.value);
            return fail(Error.CONTRACT_PAUSED, FailureInfo.REPAY_BORROW_CONTRACT_PAUSED);
        }
        PayBorrowLocalVars memory localResults;
        Market storage market = markets[asset];
        Balance storage borrowBalance = borrowBalances[msg.sender][asset];
        Error err;
        uint rateCalculationResultCode;

        // We calculate the newBorrowIndex, user's borrowCurrent and borrowUpdated for the asset
        (err, localResults.newBorrowIndex) = calculateInterestIndex(market.borrowIndex, market.borrowRateMantissa, market.blockNumber, getBlockNumber());
        if (err != Error.NO_ERROR) {
            revertEtherToUser(msg.sender,msg.value);
            return fail(err, FailureInfo.REPAY_BORROW_NEW_BORROW_INDEX_CALCULATION_FAILED);
        }

        (err, localResults.userBorrowCurrent) = calculateBalance(borrowBalance.principal, borrowBalance.interestIndex, localResults.newBorrowIndex);
        if (err != Error.NO_ERROR) {
            revertEtherToUser(msg.sender,msg.value);
            return fail(err, FailureInfo.REPAY_BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED);
        }

        uint reimburseAmount;
        // If the user specifies -1 amount to repay (“max”), repayAmount =>
        // the lesser of the senders ERC-20 balance and borrowCurrent
        if (asset != wethAddress) {
            if (amount == uint(-1)) {
                localResults.repayAmount = min(getBalanceOf(asset, msg.sender), localResults.userBorrowCurrent);
            } else {
                localResults.repayAmount = amount;
            }
        } else {
            // To calculate the actual repay use has to do and reimburse the excess amount of ETH collected
            if (amount > localResults.userBorrowCurrent) {
                localResults.repayAmount = localResults.userBorrowCurrent;
                (err, reimburseAmount) = sub(amount,localResults.userBorrowCurrent); // reimbursement called at the end to make sure function does not have any other errors
                if (err != Error.NO_ERROR) {
                    revertEtherToUser(msg.sender,msg.value);
                    return fail(err, FailureInfo.REPAY_BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED);
                }
            } else {
                localResults.repayAmount = amount;
            }
        }

        // Subtract the `repayAmount` from the `userBorrowCurrent` to get `userBorrowUpdated`
        // Note: this checks that repayAmount is less than borrowCurrent
        (err, localResults.userBorrowUpdated) = sub(localResults.userBorrowCurrent, localResults.repayAmount);
        if (err != Error.NO_ERROR) {
            revertEtherToUser(msg.sender,msg.value);
            return fail(err, FailureInfo.REPAY_BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED);
        }

        // Fail gracefully if asset is not approved or has insufficient balance
        // Note: this checks that repayAmount is less than or equal to their ERC-20 balance
        if(asset != wethAddress) { // WETH is supplied to AlkemiEarnVerified contract in case of ETH automatically
            revertEtherToUser(msg.sender,msg.value);
            err = checkTransferIn(asset, msg.sender, localResults.repayAmount);
            if (err != Error.NO_ERROR) {
                return fail(err, FailureInfo.REPAY_BORROW_TRANSFER_IN_NOT_POSSIBLE);
            }
        }

        // We calculate the protocol's totalBorrow by subtracting the user's prior checkpointed balance, adding user's updated borrow
        // Note that, even though the customer is paying some of their borrow, if they've accumulated a lot of interest since their last
        // action, the updated balance *could* be higher than the prior checkpointed balance.
        (err, localResults.newTotalBorrows) = addThenSub(market.totalBorrows, localResults.userBorrowUpdated, borrowBalance.principal);
        if (err != Error.NO_ERROR) {
            revertEtherToUser(msg.sender,msg.value);
            return fail(err, FailureInfo.REPAY_BORROW_NEW_TOTAL_BORROW_CALCULATION_FAILED);
        }

        // We need to calculate what the updated cash will be after we transfer in from user
        localResults.currentCash = getCash(asset);

        (err, localResults.updatedCash) = add(localResults.currentCash, localResults.repayAmount);
        if (err != Error.NO_ERROR) {
            revertEtherToUser(msg.sender,msg.value);
            return fail(err, FailureInfo.REPAY_BORROW_NEW_TOTAL_CASH_CALCULATION_FAILED);
        }

        // The utilization rate has changed! We calculate a new supply index and borrow index for the asset, and save it.

        // We calculate the newSupplyIndex, but we have newBorrowIndex already
        (err, localResults.newSupplyIndex) = calculateInterestIndex(market.supplyIndex, market.supplyRateMantissa, market.blockNumber, getBlockNumber());
        if (err != Error.NO_ERROR) {
            revertEtherToUser(msg.sender,msg.value);
            return fail(err, FailureInfo.REPAY_BORROW_NEW_SUPPLY_INDEX_CALCULATION_FAILED);
        }

        (rateCalculationResultCode, localResults.newSupplyRateMantissa) = market.interestRateModel.getSupplyRate(asset, localResults.updatedCash, localResults.newTotalBorrows);
        if (rateCalculationResultCode != 0) {
            revertEtherToUser(msg.sender,msg.value);
            return failOpaque(FailureInfo.REPAY_BORROW_NEW_SUPPLY_RATE_CALCULATION_FAILED, rateCalculationResultCode);
        }

        (rateCalculationResultCode, localResults.newBorrowRateMantissa) = market.interestRateModel.getBorrowRate(asset, localResults.updatedCash, localResults.newTotalBorrows);
        if (rateCalculationResultCode != 0) {
            revertEtherToUser(msg.sender,msg.value);
            return failOpaque(FailureInfo.REPAY_BORROW_NEW_BORROW_RATE_CALCULATION_FAILED, rateCalculationResultCode);
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)
        if(asset != wethAddress) { // WETH is supplied to AlkemiEarnVerified contract in case of ETH automatically
            // We ERC-20 transfer the asset into the protocol (note: pre-conditions already checked above)
            revertEtherToUser(msg.sender,msg.value);
            err = doTransferIn(asset, msg.sender, localResults.repayAmount);
            if (err != Error.NO_ERROR) {
                // This is safe since it's our first interaction and it didn't do anything if it failed
                return fail(err, FailureInfo.REPAY_BORROW_TRANSFER_IN_FAILED);
            }
        } else {
            if (msg.value == amount){
                uint supplyError = supplyEther(msg.sender,localResults.repayAmount);
                //Repay excess funds
                if(reimburseAmount > 0){
                    revertEtherToUser(msg.sender,reimburseAmount);
                }
                if(supplyError != 0 ){
                    revertEtherToUser(msg.sender,msg.value);
                    return fail(Error.WETH_ADDRESS_NOT_SET_ERROR, FailureInfo.WETH_ADDRESS_NOT_SET_ERROR);
                } 
            }
            else {
                revertEtherToUser(msg.sender,msg.value);
                return fail(Error.ETHER_AMOUNT_MISMATCH_ERROR, FailureInfo.ETHER_AMOUNT_MISMATCH_ERROR);
            }
        }

        // Save market updates
        market.blockNumber = getBlockNumber();
        market.totalBorrows =  localResults.newTotalBorrows;
        market.supplyRateMantissa = localResults.newSupplyRateMantissa;
        market.supplyIndex = localResults.newSupplyIndex;
        market.borrowRateMantissa = localResults.newBorrowRateMantissa;
        market.borrowIndex = localResults.newBorrowIndex;

        // Save user updates
        localResults.startingBalance = borrowBalance.principal; // save for use in `BorrowRepaid` event
        borrowBalance.principal = localResults.userBorrowUpdated;
        borrowBalance.interestIndex = localResults.newBorrowIndex;
        
        supplyOriginationFeeAsAdmin(asset,msg.sender, localResults.repayAmount,localResults.newSupplyIndex);

        emit BorrowRepaid(msg.sender, asset, localResults.repayAmount, localResults.startingBalance, localResults.userBorrowUpdated);

        return uint(Error.NO_ERROR); // success
    }

    /**
     * @notice users repay all or some of an underwater borrow and receive collateral
     * @param targetAccount The account whose borrow should be liquidated
     * @param assetBorrow The market asset to repay
     * @param assetCollateral The borrower's market asset to receive in exchange
     * @param requestedAmountClose The amount to repay (or -1 for max)
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function liquidateBorrow(address targetAccount, address assetBorrow, address assetCollateral, uint requestedAmountClose) payable public isLiquidator returns (uint) {
        if (paused) {
            return fail(Error.CONTRACT_PAUSED, FailureInfo.LIQUIDATE_CONTRACT_PAUSED);
        }
        LiquidateLocalVars memory localResults;
        // Copy these addresses into the struct for use with `emitLiquidationEvent`
        // We'll use localResults.liquidator inside this function for clarity vs using msg.sender.
        localResults.targetAccount = targetAccount;
        localResults.assetBorrow = assetBorrow;
        localResults.liquidator = msg.sender;
        localResults.assetCollateral = assetCollateral;

        Market storage borrowMarket = markets[assetBorrow];
        Market storage collateralMarket = markets[assetCollateral];
        Balance storage borrowBalance_TargeUnderwaterAsset = borrowBalances[targetAccount][assetBorrow];
        Balance storage supplyBalance_TargetCollateralAsset = supplyBalances[targetAccount][assetCollateral];

        // Liquidator might already hold some of the collateral asset
        Balance storage supplyBalance_LiquidatorCollateralAsset = supplyBalances[localResults.liquidator][assetCollateral];

        uint rateCalculationResultCode; // Used for multiple interest rate calculation calls
        Error err; // re-used for all intermediate errors

        (err, localResults.collateralPrice) = fetchAssetPrice(assetCollateral);
        if(err != Error.NO_ERROR) {
            return fail(err, FailureInfo.LIQUIDATE_FETCH_ASSET_PRICE_FAILED);
        }

        (err, localResults.underwaterAssetPrice) = fetchAssetPrice(assetBorrow);
        // If the price oracle is not set, then we would have failed on the first call to fetchAssetPrice
        assert(err == Error.NO_ERROR);

        // We calculate newBorrowIndex_UnderwaterAsset and then use it to help calculate currentBorrowBalance_TargetUnderwaterAsset
        (err, localResults.newBorrowIndex_UnderwaterAsset) = calculateInterestIndex(borrowMarket.borrowIndex, borrowMarket.borrowRateMantissa, borrowMarket.blockNumber, getBlockNumber());
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.LIQUIDATE_NEW_BORROW_INDEX_CALCULATION_FAILED_BORROWED_ASSET);
        }

        (err, localResults.currentBorrowBalance_TargetUnderwaterAsset) = calculateBalance(borrowBalance_TargeUnderwaterAsset.principal, borrowBalance_TargeUnderwaterAsset.interestIndex, localResults.newBorrowIndex_UnderwaterAsset);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.LIQUIDATE_ACCUMULATED_BORROW_BALANCE_CALCULATION_FAILED);
        }

        // We calculate newSupplyIndex_CollateralAsset and then use it to help calculate currentSupplyBalance_TargetCollateralAsset
        (err, localResults.newSupplyIndex_CollateralAsset) = calculateInterestIndex(collateralMarket.supplyIndex, collateralMarket.supplyRateMantissa, collateralMarket.blockNumber, getBlockNumber());
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.LIQUIDATE_NEW_SUPPLY_INDEX_CALCULATION_FAILED_COLLATERAL_ASSET);
        }

        (err, localResults.currentSupplyBalance_TargetCollateralAsset) = calculateBalance(supplyBalance_TargetCollateralAsset.principal, supplyBalance_TargetCollateralAsset.interestIndex, localResults.newSupplyIndex_CollateralAsset);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.LIQUIDATE_ACCUMULATED_SUPPLY_BALANCE_CALCULATION_FAILED_BORROWER_COLLATERAL_ASSET);
        }

        // Liquidator may or may not already have some collateral asset.
        // If they do, we need to accumulate interest on it before adding the seized collateral to it.
        // We re-use newSupplyIndex_CollateralAsset calculated above to help calculate currentSupplyBalance_LiquidatorCollateralAsset
        (err, localResults.currentSupplyBalance_LiquidatorCollateralAsset) = calculateBalance(supplyBalance_LiquidatorCollateralAsset.principal, supplyBalance_LiquidatorCollateralAsset.interestIndex, localResults.newSupplyIndex_CollateralAsset);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.LIQUIDATE_ACCUMULATED_SUPPLY_BALANCE_CALCULATION_FAILED_LIQUIDATOR_COLLATERAL_ASSET);
        }

        // We update the protocol's totalSupply for assetCollateral in 2 steps, first by adding target user's accumulated
        // interest and then by adding the liquidator's accumulated interest.

        // Step 1 of 2: We add the target user's supplyCurrent and subtract their checkpointedBalance
        // (which has the desired effect of adding accrued interest from the target user)
        (err, localResults.newTotalSupply_ProtocolCollateralAsset) = addThenSub(collateralMarket.totalSupply, localResults.currentSupplyBalance_TargetCollateralAsset, supplyBalance_TargetCollateralAsset.principal);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.LIQUIDATE_NEW_TOTAL_SUPPLY_BALANCE_CALCULATION_FAILED_BORROWER_COLLATERAL_ASSET);
        }

        // Step 2 of 2: We add the liquidator's supplyCurrent of collateral asset and subtract their checkpointedBalance
        // (which has the desired effect of adding accrued interest from the calling user)
        (err, localResults.newTotalSupply_ProtocolCollateralAsset) = addThenSub(localResults.newTotalSupply_ProtocolCollateralAsset, localResults.currentSupplyBalance_LiquidatorCollateralAsset, supplyBalance_LiquidatorCollateralAsset.principal);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.LIQUIDATE_NEW_TOTAL_SUPPLY_BALANCE_CALCULATION_FAILED_LIQUIDATOR_COLLATERAL_ASSET);
        }

        // We calculate maxCloseableBorrowAmount_TargetUnderwaterAsset, the amount of borrow that can be closed from the target user
        // This is equal to the lesser of
        // 1. borrowCurrent; (already calculated)
        // 2. ONLY IF MARKET SUPPORTED: discountedRepayToEvenAmount:
        // discountedRepayToEvenAmount=
        //      shortfall / [Oracle price for the borrow * (collateralRatio - liquidationDiscount - 1)]
        // 3. discountedBorrowDenominatedCollateral
        //      [supplyCurrent / (1 + liquidationDiscount)] * (Oracle price for the collateral / Oracle price for the borrow)

        // Here we calculate item 3. discountedBorrowDenominatedCollateral =
        // [supplyCurrent / (1 + liquidationDiscount)] * (Oracle price for the collateral / Oracle price for the borrow)
        (err, localResults.discountedBorrowDenominatedCollateral) =
        calculateDiscountedBorrowDenominatedCollateral(localResults.underwaterAssetPrice, localResults.collateralPrice, localResults.currentSupplyBalance_TargetCollateralAsset);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.LIQUIDATE_BORROW_DENOMINATED_COLLATERAL_CALCULATION_FAILED);
        }

        if (borrowMarket.isSupported) {
            // Market is supported, so we calculate item 2 from above.
            (err, localResults.discountedRepayToEvenAmount) =
            calculateDiscountedRepayToEvenAmount(targetAccount, localResults.underwaterAssetPrice);
            if (err != Error.NO_ERROR) {
                return fail(err, FailureInfo.LIQUIDATE_DISCOUNTED_REPAY_TO_EVEN_AMOUNT_CALCULATION_FAILED);
            }

            // We need to do a two-step min to select from all 3 values
            // min1&3 = min(item 1, item 3)
            localResults.maxCloseableBorrowAmount_TargetUnderwaterAsset = min(localResults.currentBorrowBalance_TargetUnderwaterAsset, localResults.discountedBorrowDenominatedCollateral);

            // min1&3&2 = min(min1&3, 2)
            localResults.maxCloseableBorrowAmount_TargetUnderwaterAsset = min(localResults.maxCloseableBorrowAmount_TargetUnderwaterAsset, localResults.discountedRepayToEvenAmount);
        } else {
            // Market is not supported, so we don't need to calculate item 2.
            localResults.maxCloseableBorrowAmount_TargetUnderwaterAsset = min(localResults.currentBorrowBalance_TargetUnderwaterAsset, localResults.discountedBorrowDenominatedCollateral);
        }

        // If liquidateBorrowAmount = -1, then closeBorrowAmount_TargetUnderwaterAsset = maxCloseableBorrowAmount_TargetUnderwaterAsset
        if (assetBorrow != wethAddress) {
            if (requestedAmountClose == uint(-1)) {
                localResults.closeBorrowAmount_TargetUnderwaterAsset = localResults.maxCloseableBorrowAmount_TargetUnderwaterAsset;
            } else {
                localResults.closeBorrowAmount_TargetUnderwaterAsset = requestedAmountClose;
            }
        } else {
            // To calculate the actual repay use has to do and reimburse the excess amount of ETH collected
            if (requestedAmountClose > localResults.maxCloseableBorrowAmount_TargetUnderwaterAsset) {
                localResults.closeBorrowAmount_TargetUnderwaterAsset = localResults.maxCloseableBorrowAmount_TargetUnderwaterAsset;
                (err, localResults.reimburseAmount) = sub(requestedAmountClose,localResults.maxCloseableBorrowAmount_TargetUnderwaterAsset); // reimbursement called at the end to make sure function does not have any other errors
                if (err != Error.NO_ERROR) {
                    return fail(err, FailureInfo.REPAY_BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED);
                }
            } else {
                localResults.closeBorrowAmount_TargetUnderwaterAsset = requestedAmountClose;
            }
        }

        // From here on, no more use of `requestedAmountClose`

        // Verify closeBorrowAmount_TargetUnderwaterAsset <= maxCloseableBorrowAmount_TargetUnderwaterAsset
        if (localResults.closeBorrowAmount_TargetUnderwaterAsset > localResults.maxCloseableBorrowAmount_TargetUnderwaterAsset) {
            return fail(Error.INVALID_CLOSE_AMOUNT_REQUESTED, FailureInfo.LIQUIDATE_CLOSE_AMOUNT_TOO_HIGH);
        }

        // seizeSupplyAmount_TargetCollateralAsset = closeBorrowAmount_TargetUnderwaterAsset * priceBorrow/priceCollateral *(1+liquidationDiscount)
        (err, localResults.seizeSupplyAmount_TargetCollateralAsset) = calculateAmountSeize(localResults.underwaterAssetPrice, localResults.collateralPrice, localResults.closeBorrowAmount_TargetUnderwaterAsset);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.LIQUIDATE_AMOUNT_SEIZE_CALCULATION_FAILED);
        }

        // We are going to ERC-20 transfer closeBorrowAmount_TargetUnderwaterAsset of assetBorrow into protocol
        // Fail gracefully if asset is not approved or has insufficient balance
        if(assetBorrow != wethAddress) { // WETH is supplied to AlkemiEarnVerified contract in case of ETH automatically
            err = checkTransferIn(assetBorrow, localResults.liquidator, localResults.closeBorrowAmount_TargetUnderwaterAsset);
            if (err != Error.NO_ERROR) {
                return fail(err, FailureInfo.LIQUIDATE_TRANSFER_IN_NOT_POSSIBLE);
            }
        }

        // We are going to repay the target user's borrow using the calling user's funds
        // We update the protocol's totalBorrow for assetBorrow, by subtracting the target user's prior checkpointed balance,
        // adding borrowCurrent, and subtracting closeBorrowAmount_TargetUnderwaterAsset.

        // Subtract the `closeBorrowAmount_TargetUnderwaterAsset` from the `currentBorrowBalance_TargetUnderwaterAsset` to get `updatedBorrowBalance_TargetUnderwaterAsset`
        (err, localResults.updatedBorrowBalance_TargetUnderwaterAsset) = sub(localResults.currentBorrowBalance_TargetUnderwaterAsset, localResults.closeBorrowAmount_TargetUnderwaterAsset);
        // We have ensured above that localResults.closeBorrowAmount_TargetUnderwaterAsset <= localResults.currentBorrowBalance_TargetUnderwaterAsset, so the sub can't underflow
        assert(err == Error.NO_ERROR);

        // We calculate the protocol's totalBorrow for assetBorrow by subtracting the user's prior checkpointed balance, adding user's updated borrow
        // Note that, even though the liquidator is paying some of the borrow, if the borrow has accumulated a lot of interest since the last
        // action, the updated balance *could* be higher than the prior checkpointed balance.
        (err, localResults.newTotalBorrows_ProtocolUnderwaterAsset) = addThenSub(borrowMarket.totalBorrows, localResults.updatedBorrowBalance_TargetUnderwaterAsset, borrowBalance_TargeUnderwaterAsset.principal);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.LIQUIDATE_NEW_TOTAL_BORROW_CALCULATION_FAILED_BORROWED_ASSET);
        }

        // We need to calculate what the updated cash will be after we transfer in from liquidator
        localResults.currentCash_ProtocolUnderwaterAsset = getCash(assetBorrow);
        (err, localResults.updatedCash_ProtocolUnderwaterAsset) = add(localResults.currentCash_ProtocolUnderwaterAsset, localResults.closeBorrowAmount_TargetUnderwaterAsset);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.LIQUIDATE_NEW_TOTAL_CASH_CALCULATION_FAILED_BORROWED_ASSET);
        }

        // The utilization rate has changed! We calculate a new supply index, borrow index, supply rate, and borrow rate for assetBorrow
        // (Please note that we don't need to do the same thing for assetCollateral because neither cash nor borrows of assetCollateral happen in this process.)

        // We calculate the newSupplyIndex_UnderwaterAsset, but we already have newBorrowIndex_UnderwaterAsset so don't recalculate it.
        (err, localResults.newSupplyIndex_UnderwaterAsset) = calculateInterestIndex(borrowMarket.supplyIndex, borrowMarket.supplyRateMantissa, borrowMarket.blockNumber, getBlockNumber());
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.LIQUIDATE_NEW_SUPPLY_INDEX_CALCULATION_FAILED_BORROWED_ASSET);
        }

        (rateCalculationResultCode, localResults.newSupplyRateMantissa_ProtocolUnderwaterAsset) = borrowMarket.interestRateModel.getSupplyRate(assetBorrow, localResults.updatedCash_ProtocolUnderwaterAsset, localResults.newTotalBorrows_ProtocolUnderwaterAsset);
        if (rateCalculationResultCode != 0) {
            return failOpaque(FailureInfo.LIQUIDATE_NEW_SUPPLY_RATE_CALCULATION_FAILED_BORROWED_ASSET, rateCalculationResultCode);
        }

        (rateCalculationResultCode, localResults.newBorrowRateMantissa_ProtocolUnderwaterAsset) = borrowMarket.interestRateModel.getBorrowRate(assetBorrow, localResults.updatedCash_ProtocolUnderwaterAsset, localResults.newTotalBorrows_ProtocolUnderwaterAsset);
        if (rateCalculationResultCode != 0) {
            return failOpaque(FailureInfo.LIQUIDATE_NEW_BORROW_RATE_CALCULATION_FAILED_BORROWED_ASSET, rateCalculationResultCode);
        }

        // Now we look at collateral. We calculated target user's accumulated supply balance and the supply index above.
        // Now we need to calculate the borrow index.
        // We don't need to calculate new rates for the collateral asset because we have not changed utilization:
        //  - accumulating interest on the target user's collateral does not change cash or borrows
        //  - transferring seized amount of collateral internally from the target user to the liquidator does not change cash or borrows.
        (err, localResults.newBorrowIndex_CollateralAsset) = calculateInterestIndex(collateralMarket.borrowIndex, collateralMarket.borrowRateMantissa, collateralMarket.blockNumber, getBlockNumber());
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.LIQUIDATE_NEW_BORROW_INDEX_CALCULATION_FAILED_COLLATERAL_ASSET);
        }

        // We checkpoint the target user's assetCollateral supply balance, supplyCurrent - seizeSupplyAmount_TargetCollateralAsset at the updated index
        (err, localResults.updatedSupplyBalance_TargetCollateralAsset) = sub(localResults.currentSupplyBalance_TargetCollateralAsset, localResults.seizeSupplyAmount_TargetCollateralAsset);
        // The sub won't underflow because because seizeSupplyAmount_TargetCollateralAsset <= target user's collateral balance
        // maxCloseableBorrowAmount_TargetUnderwaterAsset is limited by the discounted borrow denominated collateral. That limits closeBorrowAmount_TargetUnderwaterAsset
        // which in turn limits seizeSupplyAmount_TargetCollateralAsset.
        assert (err == Error.NO_ERROR);

        // We checkpoint the liquidating user's assetCollateral supply balance, supplyCurrent + seizeSupplyAmount_TargetCollateralAsset at the updated index
        (err, localResults.updatedSupplyBalance_LiquidatorCollateralAsset) = add(localResults.currentSupplyBalance_LiquidatorCollateralAsset, localResults.seizeSupplyAmount_TargetCollateralAsset);
        // We can't overflow here because if this would overflow, then we would have already overflowed above and failed
        // with LIQUIDATE_NEW_TOTAL_SUPPLY_BALANCE_CALCULATION_FAILED_LIQUIDATOR_COLLATERAL_ASSET
        assert (err == Error.NO_ERROR);

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        // We ERC-20 transfer the asset into the protocol (note: pre-conditions already checked above)
        if(assetBorrow != wethAddress) { // WETH is supplied to AlkemiEarnVerified contract in case of ETH automatically
            revertEtherToUser(msg.sender,msg.value);
            err = doTransferIn(assetBorrow, localResults.liquidator, localResults.closeBorrowAmount_TargetUnderwaterAsset);
            if (err != Error.NO_ERROR) {
                // This is safe since it's our first interaction and it didn't do anything if it failed
                return fail(err, FailureInfo.LIQUIDATE_TRANSFER_IN_FAILED);
            }
        } else {
            if (msg.value == requestedAmountClose){
                uint supplyError = supplyEther(localResults.liquidator, localResults.closeBorrowAmount_TargetUnderwaterAsset);
                //Repay excess funds
                if(localResults.reimburseAmount > 0){
                    revertEtherToUser(localResults.liquidator,localResults.reimburseAmount);
                }
                if(supplyError !=0 ){
                    revertEtherToUser(msg.sender,msg.value);
                    return fail(Error.WETH_ADDRESS_NOT_SET_ERROR, FailureInfo.WETH_ADDRESS_NOT_SET_ERROR);
                }
            }   
            else {
                revertEtherToUser(msg.sender,msg.value);
                return fail(Error.ETHER_AMOUNT_MISMATCH_ERROR, FailureInfo.ETHER_AMOUNT_MISMATCH_ERROR);
            }
        }

        // Save borrow market updates
        borrowMarket.blockNumber = getBlockNumber();
        borrowMarket.totalBorrows = localResults.newTotalBorrows_ProtocolUnderwaterAsset;
        // borrowMarket.totalSupply does not need to be updated
        borrowMarket.supplyRateMantissa = localResults.newSupplyRateMantissa_ProtocolUnderwaterAsset;
        borrowMarket.supplyIndex = localResults.newSupplyIndex_UnderwaterAsset;
        borrowMarket.borrowRateMantissa = localResults.newBorrowRateMantissa_ProtocolUnderwaterAsset;
        borrowMarket.borrowIndex = localResults.newBorrowIndex_UnderwaterAsset;

        // Save collateral market updates
        // We didn't calculate new rates for collateralMarket (because neither cash nor borrows changed), just new indexes and total supply.
        collateralMarket.blockNumber = getBlockNumber();
        collateralMarket.totalSupply = localResults.newTotalSupply_ProtocolCollateralAsset;
        collateralMarket.supplyIndex = localResults.newSupplyIndex_CollateralAsset;
        collateralMarket.borrowIndex = localResults.newBorrowIndex_CollateralAsset;

        // Save user updates

        localResults.startingBorrowBalance_TargetUnderwaterAsset = borrowBalance_TargeUnderwaterAsset.principal; // save for use in event
        borrowBalance_TargeUnderwaterAsset.principal = localResults.updatedBorrowBalance_TargetUnderwaterAsset;
        borrowBalance_TargeUnderwaterAsset.interestIndex = localResults.newBorrowIndex_UnderwaterAsset;

        localResults.startingSupplyBalance_TargetCollateralAsset = supplyBalance_TargetCollateralAsset.principal; // save for use in event
        supplyBalance_TargetCollateralAsset.principal = localResults.updatedSupplyBalance_TargetCollateralAsset;
        supplyBalance_TargetCollateralAsset.interestIndex = localResults.newSupplyIndex_CollateralAsset;

        localResults.startingSupplyBalance_LiquidatorCollateralAsset = supplyBalance_LiquidatorCollateralAsset.principal; // save for use in event
        supplyBalance_LiquidatorCollateralAsset.principal = localResults.updatedSupplyBalance_LiquidatorCollateralAsset;
        supplyBalance_LiquidatorCollateralAsset.interestIndex = localResults.newSupplyIndex_CollateralAsset;
        
        supplyOriginationFeeAsAdmin(assetBorrow,localResults.liquidator, localResults.closeBorrowAmount_TargetUnderwaterAsset, localResults.newSupplyIndex_UnderwaterAsset);

        emitLiquidationEvent(localResults);

        return uint(Error.NO_ERROR); // success
    }

    /**
     * @dev this function exists to avoid error `CompilerError: Stack too deep, try removing local variables.` in `liquidateBorrow`
     */
    function emitLiquidationEvent(LiquidateLocalVars memory localResults) internal {
        // event BorrowLiquidated(address targetAccount, address assetBorrow, uint borrowBalanceBefore, uint borrowBalanceAccumulated, uint amountRepaid, uint borrowBalanceAfter,
        // address liquidator, address assetCollateral, uint collateralBalanceBefore, uint collateralBalanceAccumulated, uint amountSeized, uint collateralBalanceAfter);
        emit BorrowLiquidated(localResults.targetAccount,
            localResults.assetBorrow,
            localResults.startingBorrowBalance_TargetUnderwaterAsset,
            localResults.currentBorrowBalance_TargetUnderwaterAsset,
            localResults.closeBorrowAmount_TargetUnderwaterAsset,
            localResults.updatedBorrowBalance_TargetUnderwaterAsset,
            localResults.liquidator,
            localResults.assetCollateral,
            localResults.startingSupplyBalance_TargetCollateralAsset,
            localResults.currentSupplyBalance_TargetCollateralAsset,
            localResults.seizeSupplyAmount_TargetCollateralAsset,
            localResults.updatedSupplyBalance_TargetCollateralAsset);
    }

    /**
     * @dev This should ONLY be called if market is supported. It returns shortfall / [Oracle price for the borrow * (collateralRatio - liquidationDiscount - 1)]
     *      If the market isn't supported, we support liquidation of asset regardless of shortfall because we want borrows of the unsupported asset to be closed.
     *      Note that if collateralRatio = liquidationDiscount + 1, then the denominator will be zero and the function will fail with DIVISION_BY_ZERO.
     */
    function calculateDiscountedRepayToEvenAmount(address targetAccount, Exp memory underwaterAssetPrice) internal view returns (Error, uint) {
        Error err;
        Exp memory _accountLiquidity; // unused return value from calculateAccountLiquidity
        Exp memory accountShortfall_TargetUser;
        Exp memory collateralRatioMinusLiquidationDiscount; // collateralRatio - liquidationDiscount
        Exp memory discountedCollateralRatioMinusOne; // collateralRatioMinusLiquidationDiscount - 1, aka collateralRatio - liquidationDiscount - 1
        Exp memory discountedPrice_UnderwaterAsset;
        Exp memory rawResult;

        // we calculate the target user's shortfall, denominated in Ether, that the user is below the collateral ratio
        (err, _accountLiquidity, accountShortfall_TargetUser) = calculateAccountLiquidity(targetAccount);
        if (err != Error.NO_ERROR) {
            return (err, 0);
        }

        (err, collateralRatioMinusLiquidationDiscount) = subExp(collateralRatio, liquidationDiscount);
        if (err != Error.NO_ERROR) {
            return (err, 0);
        }

        (err, discountedCollateralRatioMinusOne) = subExp(collateralRatioMinusLiquidationDiscount, Exp({mantissa: mantissaOne}));
        if (err != Error.NO_ERROR) {
            return (err, 0);
        }

        (err, discountedPrice_UnderwaterAsset) = mulExp(underwaterAssetPrice, discountedCollateralRatioMinusOne);
        // calculateAccountLiquidity multiplies underwaterAssetPrice by collateralRatio
        // discountedCollateralRatioMinusOne < collateralRatio
        // so if underwaterAssetPrice * collateralRatio did not overflow then
        // underwaterAssetPrice * discountedCollateralRatioMinusOne can't overflow either
        assert(err == Error.NO_ERROR);

        (err, rawResult) = divExp(accountShortfall_TargetUser, discountedPrice_UnderwaterAsset);
        // It's theoretically possible an asset could have such a low price that it truncates to zero when discounted.
        if (err != Error.NO_ERROR) {
            return (err, 0);
        }

        return (Error.NO_ERROR, truncate(rawResult));
    }

    /**
     * @dev discountedBorrowDenominatedCollateral = [supplyCurrent / (1 + liquidationDiscount)] * (Oracle price for the collateral / Oracle price for the borrow)
     */
    function calculateDiscountedBorrowDenominatedCollateral(Exp memory underwaterAssetPrice, Exp memory collateralPrice, uint supplyCurrent_TargetCollateralAsset) view internal returns (Error, uint) {
        // To avoid rounding issues, we re-order and group the operations so we do 1 division and only at the end
        // [supplyCurrent * (Oracle price for the collateral)] / [ (1 + liquidationDiscount) * (Oracle price for the borrow) ]
        Error err;
        Exp memory onePlusLiquidationDiscount; // (1 + liquidationDiscount)
        Exp memory supplyCurrentTimesOracleCollateral; // supplyCurrent * Oracle price for the collateral
        Exp memory onePlusLiquidationDiscountTimesOracleBorrow; // (1 + liquidationDiscount) * Oracle price for the borrow
        Exp memory rawResult;

        (err, onePlusLiquidationDiscount) = addExp(Exp({mantissa: mantissaOne}), liquidationDiscount);
        if (err != Error.NO_ERROR) {
            return (err, 0);
        }

        (err, supplyCurrentTimesOracleCollateral) = mulScalar(collateralPrice, supplyCurrent_TargetCollateralAsset);
        if (err != Error.NO_ERROR) {
            return (err, 0);
        }

        (err, onePlusLiquidationDiscountTimesOracleBorrow) = mulExp(onePlusLiquidationDiscount, underwaterAssetPrice);
        if (err != Error.NO_ERROR) {
            return (err, 0);
        }

        (err, rawResult) = divExp(supplyCurrentTimesOracleCollateral, onePlusLiquidationDiscountTimesOracleBorrow);
        if (err != Error.NO_ERROR) {
            return (err, 0);
        }

        return (Error.NO_ERROR, truncate(rawResult));
    }


    /**
     * @dev returns closeBorrowAmount_TargetUnderwaterAsset * (1+liquidationDiscount) * priceBorrow/priceCollateral
     */
    function calculateAmountSeize(Exp memory underwaterAssetPrice, Exp memory collateralPrice, uint closeBorrowAmount_TargetUnderwaterAsset) internal view returns (Error, uint) {
        // To avoid rounding issues, we re-order and group the operations to move the division to the end, rather than just taking the ratio of the 2 prices:
        // underwaterAssetPrice * (1+liquidationDiscount) *closeBorrowAmount_TargetUnderwaterAsset) / collateralPrice

        // re-used for all intermediate errors
        Error err;

        // (1+liquidationDiscount)
        Exp memory liquidationMultiplier;

        // assetPrice-of-underwaterAsset * (1+liquidationDiscount)
        Exp memory priceUnderwaterAssetTimesLiquidationMultiplier;

        // priceUnderwaterAssetTimesLiquidationMultiplier * closeBorrowAmount_TargetUnderwaterAsset
        // or, expanded:
        // underwaterAssetPrice * (1+liquidationDiscount) * closeBorrowAmount_TargetUnderwaterAsset
        Exp memory finalNumerator;

        // finalNumerator / priceCollateral
        Exp memory rawResult;

        (err, liquidationMultiplier) = addExp(Exp({mantissa: mantissaOne}), liquidationDiscount);
        // liquidation discount will be enforced < 1, so 1 + liquidationDiscount can't overflow.
        assert(err == Error.NO_ERROR);

        (err, priceUnderwaterAssetTimesLiquidationMultiplier) = mulExp(underwaterAssetPrice, liquidationMultiplier);
        if (err != Error.NO_ERROR) {
            return (err, 0);
        }

        (err, finalNumerator) = mulScalar(priceUnderwaterAssetTimesLiquidationMultiplier, closeBorrowAmount_TargetUnderwaterAsset);
        if (err != Error.NO_ERROR) {
            return (err, 0);
        }

        (err, rawResult) = divExp(finalNumerator, collateralPrice);
        if (err != Error.NO_ERROR) {
            return (err, 0);
        }

        return (Error.NO_ERROR, truncate(rawResult));
    }


    /**
     * @notice Users borrow assets from the protocol to their own address
     * @param asset The market asset to borrow
     * @param amount The amount to borrow
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function borrow(address asset, uint amount) public isKYCVerifiedCustomer returns (uint) {
        if (paused) {
            return fail(Error.CONTRACT_PAUSED, FailureInfo.BORROW_CONTRACT_PAUSED);
        }
        BorrowLocalVars memory localResults;
        Market storage market = markets[asset];
        Balance storage borrowBalance = borrowBalances[msg.sender][asset];

        Error err;
        uint rateCalculationResultCode;

        // Fail if market not supported
        if (!market.isSupported) {
            return fail(Error.MARKET_NOT_SUPPORTED, FailureInfo.BORROW_MARKET_NOT_SUPPORTED);
        }

        // We calculate the newBorrowIndex, user's borrowCurrent and borrowUpdated for the asset
        (err, localResults.newBorrowIndex) = calculateInterestIndex(market.borrowIndex, market.borrowRateMantissa, market.blockNumber, getBlockNumber());
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.BORROW_NEW_BORROW_INDEX_CALCULATION_FAILED);
        }

        (err, localResults.userBorrowCurrent) = calculateBalance(borrowBalance.principal, borrowBalance.interestIndex, localResults.newBorrowIndex);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED);
        }

        // Calculate origination fee.
        (err, localResults.borrowAmountWithFee) = calculateBorrowAmountWithFee(amount);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.BORROW_ORIGINATION_FEE_CALCULATION_FAILED);
        }
        uint orgFeeBalance = localResults.borrowAmountWithFee - amount;

        // Add the `borrowAmountWithFee` to the `userBorrowCurrent` to get `userBorrowUpdated`
        (err, localResults.userBorrowUpdated) = add(localResults.userBorrowCurrent, localResults.borrowAmountWithFee);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED);
        }

        // We calculate the protocol's totalBorrow by subtracting the user's prior checkpointed balance, adding user's updated borrow with fee
        (err, localResults.newTotalBorrows) = addThenSub(market.totalBorrows, localResults.userBorrowUpdated, borrowBalance.principal);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.BORROW_NEW_TOTAL_BORROW_CALCULATION_FAILED);
        }

        // Check customer liquidity
        (err, localResults.accountLiquidity, localResults.accountShortfall) = calculateAccountLiquidity(msg.sender);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.BORROW_ACCOUNT_LIQUIDITY_CALCULATION_FAILED);
        }

        // Fail if customer already has a shortfall
        if (!isZeroExp(localResults.accountShortfall)) {
            return fail(Error.INSUFFICIENT_LIQUIDITY, FailureInfo.BORROW_ACCOUNT_SHORTFALL_PRESENT);
        }

        // Would the customer have a shortfall after this borrow (including origination fee)?
        // We calculate the eth-equivalent value of (borrow amount + fee) of asset and fail if it exceeds accountLiquidity.
        // This implements: `[(collateralRatio*oraclea*borrowAmount)*(1+borrowFee)] > accountLiquidity`
        (err, localResults.ethValueOfBorrowAmountWithFee) = getPriceForAssetAmountMulCollatRatio(asset, localResults.borrowAmountWithFee);
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.BORROW_AMOUNT_VALUE_CALCULATION_FAILED);
        }
        if (lessThanExp(localResults.accountLiquidity, localResults.ethValueOfBorrowAmountWithFee)) {
            return fail(Error.INSUFFICIENT_LIQUIDITY, FailureInfo.BORROW_AMOUNT_LIQUIDITY_SHORTFALL);
        }

        // Fail gracefully if protocol has insufficient cash
        localResults.currentCash = getCash(asset);
        // We need to calculate what the updated cash will be after we transfer out to the user
        (err, localResults.updatedCash) = sub(localResults.currentCash, amount);
        if (err != Error.NO_ERROR) {
            // Note: we ignore error here and call this token insufficient cash
            return fail(Error.TOKEN_INSUFFICIENT_CASH, FailureInfo.BORROW_NEW_TOTAL_CASH_CALCULATION_FAILED);
        }

        // The utilization rate has changed! We calculate a new supply index and borrow index for the asset, and save it.

        // We calculate the newSupplyIndex, but we have newBorrowIndex already
        (err, localResults.newSupplyIndex) = calculateInterestIndex(market.supplyIndex, market.supplyRateMantissa, market.blockNumber, getBlockNumber());
        if (err != Error.NO_ERROR) {
            return fail(err, FailureInfo.BORROW_NEW_SUPPLY_INDEX_CALCULATION_FAILED);
        }

        (rateCalculationResultCode, localResults.newSupplyRateMantissa) = market.interestRateModel.getSupplyRate(asset, localResults.updatedCash, localResults.newTotalBorrows);
        if (rateCalculationResultCode != 0) {
            return failOpaque(FailureInfo.BORROW_NEW_SUPPLY_RATE_CALCULATION_FAILED, rateCalculationResultCode);
        }

        (rateCalculationResultCode, localResults.newBorrowRateMantissa) = market.interestRateModel.getBorrowRate(asset, localResults.updatedCash, localResults.newTotalBorrows);
        if (rateCalculationResultCode != 0) {
            return failOpaque(FailureInfo.BORROW_NEW_BORROW_RATE_CALCULATION_FAILED, rateCalculationResultCode);
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        if(asset != wethAddress) { // Withdrawal should happen as Ether directly
            // We ERC-20 transfer the asset into the protocol (note: pre-conditions already checked above)
            err = doTransferOut(asset, msg.sender, amount);
            if (err != Error.NO_ERROR) {
                // This is safe since it's our first interaction and it didn't do anything if it failed
                return fail(err, FailureInfo.BORROW_TRANSFER_OUT_FAILED);
            }
        } else {
            uint withdrawalerr = withdrawEther(msg.sender,amount); // send Ether to user
            if(withdrawalerr != 0){
                return uint(withdrawalerr); // success
            }
        }

        // Save market updates
        market.blockNumber = getBlockNumber();
        market.totalBorrows =  localResults.newTotalBorrows;
        market.supplyRateMantissa = localResults.newSupplyRateMantissa;
        market.supplyIndex = localResults.newSupplyIndex;
        market.borrowRateMantissa = localResults.newBorrowRateMantissa;
        market.borrowIndex = localResults.newBorrowIndex;

        // Save user updates
        localResults.startingBalance = borrowBalance.principal; // save for use in `BorrowTaken` event
        borrowBalance.principal = localResults.userBorrowUpdated;
        borrowBalance.interestIndex = localResults.newBorrowIndex;

        originationFeeBalance[msg.sender][asset] += orgFeeBalance;

        emit BorrowTaken(msg.sender, asset, amount, localResults.startingBalance, localResults.borrowAmountWithFee, localResults.userBorrowUpdated);

        return uint(Error.NO_ERROR); // success
    }

    function supplyOriginationFeeAsAdmin(address asset, address user, uint amount, uint newSupplyIndex) private {
        uint originationFeeRepaid = 0;
        if (originationFeeBalance[user][asset] != 0){
            if (amount < originationFeeBalance[user][asset]) {
                originationFeeRepaid = amount;
            } else {
                originationFeeRepaid = originationFeeBalance[user][asset];
            }
            Balance storage balance = supplyBalances[admin][asset];

            SupplyLocalVars memory localResults; // Holds all our uint calculation results
            Error err; // Re-used for every function call that includes an Error in its return value(s).

            originationFeeBalance[user][asset] -= originationFeeRepaid;

            (err, localResults.userSupplyCurrent) = calculateBalance(balance.principal, balance.interestIndex, newSupplyIndex);

            (err, localResults.userSupplyUpdated) = add(localResults.userSupplyCurrent, originationFeeRepaid);

            // We calculate the protocol's totalSupply by subtracting the user's prior checkpointed balance, adding user's updated supply
            (err, localResults.newTotalSupply) = addThenSub(markets[asset].totalSupply, localResults.userSupplyUpdated, balance.principal);

            // Save market updates
            markets[asset].totalSupply =  localResults.newTotalSupply;

            // Save user updates
            localResults.startingBalance = balance.principal;
            balance.principal = localResults.userSupplyUpdated;
            balance.interestIndex = newSupplyIndex;

            emit SupplyOrgFeeAsAdmin(admin, asset, originationFeeRepaid, localResults.startingBalance, localResults.userSupplyUpdated);
        }
    }
}
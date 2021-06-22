pragma solidity 0.5.17;

import "./CErc20Immutable.sol";
import "./CEther.sol";
import "./ErrorReporter.sol";
import "./EIP20Interface.sol";
import "./Strings.sol";
import "./TriggerInterface.sol";

/**
 * @notice Interface so ProtectionMarketFactory can use the same admin as the Comptroller
 */
interface ComptrollerAdmin {
  function admin() external view returns (address);
}

/**
 * @notice Factory contract for deploying protection markets
 * @dev The functionality of cEtherFactory and cErc20Factory lives in separate contracts, instead of directly in
 * this contract, since including them here would put this contract over the size limit
 */
contract ProtectionMarketFactory is ProtectionMarketFactoryErrorReporter {
  /// @notice Address of the comptroller
  ComptrollerInterface public comptroller;

  /// @notice Address of the CEtherFactory contract
  CEtherFactory public cEtherFactory;

  /// @notice Address of the CErc20Factory contract
  CErc20Factory public cErc20Factory;

  /// @notice Mapping of underlying to last-used index for protection token naming
  mapping(address => uint256) public tokenIndices;

  /// @notice Default InterestRateModel assigned to protection markets at deployment
  InterestRateModel public defaultInterestRateModel;

  /// @notice Special address used to represent ETH
  address internal constant ethUnderlyingAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  /// @notice Number of decimals used for protection market cToken when deployed
  uint8 internal constant decimals = 8;

  /// @notice Prefix to prepend to protection token symbols
  string internal constant tokenSymbolPrefix = "Cozy";

  /// @notice Separator used in protection token symbols
  string internal constant tokenSymbolSeparator = "-";

  /// @notice Indicator that this is ProtectionMarketFactory contract (for inspection)
  bool public constant isProtectionMarketFactory = true;

  /// @notice Emitted when protection market default interest rate model is changed by admin
  event NewDefaultInterestRateModel(InterestRateModel oldModel, InterestRateModel newModel);

  /**
   * @param cEtherFactory_ Address of the CEtherFactory contract
   * @param cErc20Factory_ Address of the CErc20Factory contract
   * @param comptroller_ Address of the system's comptroller
   * @param defaultInterestRateModel_ Address of the default interest rate model to use for new markets
   */
  constructor(
    CEtherFactory cEtherFactory_,
    CErc20Factory cErc20Factory_,
    ComptrollerInterface comptroller_,
    InterestRateModel defaultInterestRateModel_
  ) public {
    cEtherFactory = cEtherFactory_;
    cErc20Factory = cErc20Factory_;
    comptroller = comptroller_;
    require(_setDefaultInterestRateModel(defaultInterestRateModel_) == 0, "Set interest rate model failed");
  }

  /**
   * @notice Deploy a new protection market
   * @dev We could use the Comptroller address in storage instead of requiring it as an input, but passing it as an
   * input makes this contract more flexible, and also saves some gas since address(this) is much cheaper than SLOAD
   * @param _underlying The address of the underlying asset
   * @param _comptroller Address of the system's comptroller
   * @param _admin Address of the administrator of this token
   * @param _trigger Address of the trigger contract
   * @param interestRateModel_ Address of the interest rate model to use, or zero address to use the default
   */
  function deployProtectionMarket(
    address _underlying,
    ComptrollerInterface _comptroller,
    address payable _admin,
    TriggerInterface _trigger,
    address interestRateModel_
  ) external returns (address) {
    require(msg.sender == address(_comptroller), "Caller not authorized");

    // Get initial token symbol, token name, and initial exchange rate
    (string memory symbol, string memory name) = createTokenSymbolAndName(_trigger, _underlying);
    uint256 initialExchangeRateMantissa;
    {
      // Scope to avoid stack too deep errors
      uint256 underlyingDecimals = _underlying == ethUnderlyingAddress ? 18 : EIP20Interface(_underlying).decimals();
      uint256 scale = 18 + underlyingDecimals - decimals;
      initialExchangeRateMantissa = 2 * 10**(scale - 2); // (scale - 2) so initial exchange rate is equivalent to 0.02
    }

    // Deploy market
    if (_underlying == ethUnderlyingAddress) {
      return
        cEtherFactory.deployCEther(
          _comptroller,
          getInterestRateModel(interestRateModel_), // inline helper method to avoid stack too deep errors
          initialExchangeRateMantissa,
          name,
          symbol,
          decimals,
          _admin,
          address(_trigger)
        );
    } else {
      return
        cErc20Factory.deployCErc20(
          _underlying,
          _comptroller,
          getInterestRateModel(interestRateModel_), // inline helper method to avoid stack too deep errors
          initialExchangeRateMantissa,
          name,
          symbol,
          decimals,
          _admin,
          address(_trigger)
        );
    }
  }

  /**
   * @notice Returns the default interest rate model if none was provided
   * @param _interestRateModel Provided interest rate model
   */
  function getInterestRateModel(address _interestRateModel) internal returns (InterestRateModel) {
    return _interestRateModel == address(0) ? defaultInterestRateModel : InterestRateModel(_interestRateModel);
  }

  /**
   * @notice Derive a cToken name and symbol based on the trigger, underlying, and previously deployed markets
   * @dev Used internally in the factory method for creating protection markets
   * @param _trigger The address of the trigger that will be associated with this market
   * @param _underlying The address of the underlying asset used for this cToken
   * @return (symbol, name) The symbol and name for the new cToken, respectively
   */
  function createTokenSymbolAndName(TriggerInterface _trigger, address _underlying)
    internal
    returns (string memory symbol, string memory name)
  {
    // Generate string for index postfix
    uint256 nextIndex = tokenIndices[_underlying] + 1;
    string memory indexString = Strings.toString(nextIndex);

    // Remember that this token index has been used
    tokenIndices[_underlying] = nextIndex;

    // Get symbol for underlying asset
    string memory underlyingSymbol;
    if (_underlying == ethUnderlyingAddress) {
      underlyingSymbol = "ETH";
    } else {
      EIP20Interface underlyingToken = EIP20Interface(_underlying);
      underlyingSymbol = underlyingToken.symbol();
    }

    // Generate token symbol, example "Cozy-DAI-1"
    string memory tokenSymbol =
      string(
        abi.encodePacked(tokenSymbolPrefix, tokenSymbolSeparator, underlyingSymbol, tokenSymbolSeparator, indexString)
      );

    // Generate token name, example "Cozy-DAI-1-Some Protocol Failure"
    string memory tokenName = string(abi.encodePacked(tokenSymbol, tokenSymbolSeparator, _trigger.name()));

    return (tokenSymbol, tokenName);
  }

  /**
   * @notice Sets defaultInterestRateModel
   * @dev Admin function to set defaultInterestRateModel, must be called by Comptroller admin
   * @param _newModel New defaultInterestRateModel
   * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
   */
  function _setDefaultInterestRateModel(InterestRateModel _newModel) public returns (uint256) {
    // Check caller is the Comptroller admin
    if (msg.sender != ComptrollerAdmin(address(comptroller)).admin()) {
      return fail(Error.UNAUTHORIZED, FailureInfo.SET_DEFAULT_INTEREST_RATE_MODEL_OWNER_CHECK);
    }

    // Sanity check the new contract
    if (!_newModel.isInterestRateModel()) {
      return fail(Error.INTEREST_RATE_MODEL_ERROR, FailureInfo.SET_DEFAULT_INTEREST_RATE_MODEL_VALIDITY_CHECK);
    }

    // Emit event with old model, new model
    emit NewDefaultInterestRateModel(defaultInterestRateModel, _newModel);

    // Set default model to the new model
    defaultInterestRateModel = _newModel;

    return uint256(Error.NO_ERROR);
  }
}

/**
 * @notice Simple contract with one method to deploy a new CEther contract with the specified parameters
 */
contract CEtherFactory {
  /**
   * @notice Deploy a new CEther money market or protection market
   * @param comptroller The address of the Comptroller
   * @param interestRateModel The address of the interest rate model
   * @param initialExchangeRateMantissa The initial exchange rate, scaled by 1e18
   * @param name ERC-20 name of this token
   * @param symbol ERC-20 symbol of this token
   * @param decimals ERC-20 decimal precision of this token
   * @param admin Address of the administrator of this token
   * @param trigger Trigger contract address for protection markets, or the zero address for money markets
   */
  function deployCEther(
    ComptrollerInterface comptroller,
    InterestRateModel interestRateModel,
    uint256 initialExchangeRateMantissa,
    string calldata name,
    string calldata symbol,
    uint8 decimals,
    address payable admin,
    address trigger
  ) external returns (address) {
    CEther cToken =
      new CEther(comptroller, interestRateModel, initialExchangeRateMantissa, name, symbol, decimals, admin, trigger);

    return address(cToken);
  }
}

/**
 * @notice Simple contract with one method to deploy a new CErc20 contract with the specified parameters
 */
contract CErc20Factory {
  /**
   * @notice Construct a new CErc20 money market or protection market
   * @param underlying The address of the underlying asset
   * @param comptroller The address of the Comptroller
   * @param interestRateModel The address of the interest rate model
   * @param initialExchangeRateMantissa The initial exchange rate, scaled by 1e18
   * @param name ERC-20 name of this token
   * @param symbol ERC-20 symbol of this token
   * @param decimals ERC-20 decimal precision of this token
   * @param admin Address of the administrator of this token
   * @param trigger Trigger contract address for protection markets, or the zero address for money markets
   */
  function deployCErc20(
    address underlying,
    ComptrollerInterface comptroller,
    InterestRateModel interestRateModel,
    uint256 initialExchangeRateMantissa,
    string calldata name,
    string calldata symbol,
    uint8 decimals,
    address payable admin,
    address trigger
  ) external returns (address) {
    CErc20Immutable cToken =
      new CErc20Immutable(
        underlying,
        comptroller,
        interestRateModel,
        initialExchangeRateMantissa,
        name,
        symbol,
        decimals,
        admin,
        trigger
      );

    return address(cToken);
  }
}

pragma solidity 0.5.17;

import "./CErc20.sol";

/**
 * @notice CTokens which wrap an EIP-20 underlying and are immutable
 */
contract CErc20Immutable is CErc20 {
  /**
   * @notice Construct a new money market or protection market
   * @param underlying_ The address of the underlying asset
   * @param comptroller_ The address of the Comptroller
   * @param interestRateModel_ The address of the interest rate model
   * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
   * @param name_ ERC-20 name of this token
   * @param symbol_ ERC-20 symbol of this token
   * @param decimals_ ERC-20 decimal precision of this token
   * @param admin_ Address of the administrator of this token
   * @param trigger_ Trigger contract address for protection markets, or the zero address for money markets
   */
  constructor(
    address underlying_,
    ComptrollerInterface comptroller_,
    InterestRateModel interestRateModel_,
    uint256 initialExchangeRateMantissa_,
    string memory name_,
    string memory symbol_,
    uint8 decimals_,
    address payable admin_,
    address trigger_
  ) public {
    // Creator of the contract is admin during initialization
    admin = msg.sender;

    // Initialize the market
    initialize(
      underlying_,
      comptroller_,
      interestRateModel_,
      initialExchangeRateMantissa_,
      name_,
      symbol_,
      decimals_,
      trigger_
    );

    // Set the proper admin now that initialization is done
    admin = admin_;
  }
}

pragma solidity 0.5.17;

import "./CToken.sol";

/**
 * @notice CToken which wraps Ether
 */
contract CEther is CToken {
  /**
   * @notice Construct a new CEther money market or protection market
   * @param comptroller_ The address of the Comptroller
   * @param interestRateModel_ The address of the interest rate model
   * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
   * @param name_ ERC-20 name of this token
   * @param symbol_ ERC-20 symbol of this token
   * @param decimals_ ERC-20 decimal precision of this token
   * @param admin_ Address of the administrator of this token
   * @param trigger_ Trigger contract address for protection markets, or the zero address for money markets
   */
  constructor(
    ComptrollerInterface comptroller_,
    InterestRateModel interestRateModel_,
    uint256 initialExchangeRateMantissa_,
    string memory name_,
    string memory symbol_,
    uint8 decimals_,
    address payable admin_,
    address trigger_
  ) public {
    // Creator of the contract is admin during initialization
    admin = msg.sender;

    initialize(comptroller_, interestRateModel_, initialExchangeRateMantissa_, name_, symbol_, decimals_, trigger_);

    // Set the proper admin now that initialization is done
    admin = admin_;

    // Set the underlying to the special address used to indicate ETH
    underlying = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  }

  /*** User Interface ***/

  /**
   * @notice Sender supplies assets into the market and receives cTokens in exchange
   * @dev Reverts upon any failure
   */
  function mint() external payable {
    (uint256 err, ) = mintInternal(msg.value);
    requireNoError(err, "mint failed");
  }

  /**
   * @notice Sender redeems cTokens in exchange for the underlying asset
   * @dev Accrues interest whether or not the operation succeeds, unless reverted
   * @param redeemTokens The number of cTokens to redeem into underlying
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function redeem(uint256 redeemTokens) external returns (uint256) {
    return redeemInternal(redeemTokens);
  }

  /**
   * @notice Sender redeems cTokens in exchange for a specified amount of underlying asset
   * @dev Accrues interest whether or not the operation succeeds, unless reverted
   * @param redeemAmount The amount of underlying to redeem
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function redeemUnderlying(uint256 redeemAmount) external returns (uint256) {
    return redeemUnderlyingInternal(redeemAmount);
  }

  /**
   * @notice Sender borrows assets from the protocol to their own address
   * @param borrowAmount The amount of the underlying asset to borrow
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function borrow(uint256 borrowAmount) external returns (uint256) {
    return borrowInternal(borrowAmount);
  }

  /**
   * @notice Sender repays their own borrow
   * @dev Reverts upon any failure
   */
  function repayBorrow() external payable {
    (uint256 err, ) = repayBorrowInternal(msg.value);
    requireNoError(err, "repayBorrow failed");
  }

  /**
   * @notice Sender repays a borrow belonging to borrower
   * @dev Reverts upon any failure
   * @param borrower the account with the debt being payed off
   */
  function repayBorrowBehalf(address borrower) external payable {
    (uint256 err, ) = repayBorrowBehalfInternal(borrower, msg.value);
    requireNoError(err, "repayBorrowBehalf failed");
  }

  /**
   * @notice The sender liquidates the borrowers collateral.
   *  The collateral seized is transferred to the liquidator.
   * @dev Reverts upon any failure
   * @param borrower The borrower of this cToken to be liquidated
   * @param cTokenCollateral The market in which to seize collateral from the borrower
   */
  function liquidateBorrow(address borrower, CToken cTokenCollateral) external payable {
    (uint256 err, ) = liquidateBorrowInternal(borrower, msg.value, cTokenCollateral);
    requireNoError(err, "liquidateBorrow failed");
  }

  /**
   * @notice Send Ether to CEther to mint
   */
  function() external payable {
    (uint256 err, ) = mintInternal(msg.value);
    requireNoError(err, "mint failed");
  }

  /*** Safe Token ***/

  /**
   * @notice Gets balance of this contract in terms of Ether, before this message
   * @dev This excludes the value of the current message, if any
   * @return The quantity of Ether owned by this contract
   */
  function getCashPrior() internal view returns (uint256) {
    (MathError err, uint256 startingBalance) = subUInt(address(this).balance, msg.value);
    require(err == MathError.NO_ERROR);
    return startingBalance;
  }

  /**
   * @notice Perform the actual transfer in, which is a no-op
   * @param from Address sending the Ether
   * @param amount Amount of Ether being sent
   * @return The actual amount of Ether transferred
   */
  function doTransferIn(address from, uint256 amount) internal returns (uint256) {
    // Sanity checks
    require(msg.sender == from, "sender mismatch");
    require(msg.value == amount, "value mismatch");
    return amount;
  }

  function doTransferOut(address payable to, uint256 amount) internal {
    /* Send the Ether, with minimal gas and revert on failure */
    to.transfer(amount);
  }

  function requireNoError(uint256 errCode, string memory message) internal pure {
    if (errCode == uint256(Error.NO_ERROR)) {
      return;
    }

    bytes memory fullMessage = new bytes(bytes(message).length + 5);
    uint256 i;

    for (i = 0; i < bytes(message).length; i++) {
      fullMessage[i] = bytes(message)[i];
    }

    fullMessage[i + 0] = bytes1(uint8(32));
    fullMessage[i + 1] = bytes1(uint8(40));
    fullMessage[i + 2] = bytes1(uint8(48 + (errCode / 10)));
    fullMessage[i + 3] = bytes1(uint8(48 + (errCode % 10)));
    fullMessage[i + 4] = bytes1(uint8(41));

    require(errCode == uint256(Error.NO_ERROR), string(fullMessage));
  }
}

pragma solidity 0.5.17;

contract ComptrollerErrorReporter {
  enum Error {
    NO_ERROR,
    UNAUTHORIZED,
    COMPTROLLER_MISMATCH,
    INSUFFICIENT_SHORTFALL,
    INSUFFICIENT_LIQUIDITY,
    INVALID_CLOSE_FACTOR,
    INVALID_COLLATERAL_FACTOR,
    INVALID_LIQUIDATION_INCENTIVE,
    MARKET_NOT_ENTERED, // no longer possible
    MARKET_NOT_LISTED,
    MARKET_ALREADY_LISTED,
    MATH_ERROR,
    NONZERO_BORROW_BALANCE,
    PRICE_ERROR,
    REJECTION,
    SNAPSHOT_ERROR,
    TOO_MANY_ASSETS,
    TOO_MUCH_REPAY,
    INVALID_TRIGGER,
    PROTECTION_MARKET_FACTORY_ERROR
  }

  enum FailureInfo {
    ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
    ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK,
    EXIT_MARKET_BALANCE_OWED,
    EXIT_MARKET_REJECTION,
    SET_CLOSE_FACTOR_OWNER_CHECK,
    SET_CLOSE_FACTOR_VALIDATION,
    SET_COLLATERAL_FACTOR_OWNER_CHECK,
    SET_COLLATERAL_FACTOR_NO_EXISTS,
    SET_COLLATERAL_FACTOR_VALIDATION,
    SET_COLLATERAL_FACTOR_WITHOUT_PRICE,
    SET_IMPLEMENTATION_OWNER_CHECK,
    SET_LIQUIDATION_INCENTIVE_OWNER_CHECK,
    SET_LIQUIDATION_INCENTIVE_VALIDATION,
    SET_MAX_ASSETS_OWNER_CHECK,
    SET_PENDING_ADMIN_OWNER_CHECK,
    SET_PENDING_IMPLEMENTATION_OWNER_CHECK,
    SET_PRICE_ORACLE_OWNER_CHECK,
    SUPPORT_MARKET_EXISTS,
    SUPPORT_MARKET_OWNER_CHECK,
    SET_PAUSE_GUARDIAN_OWNER_CHECK,
    SET_TRIGGER_CHECK,
    SET_PROTECTION_WITH_INVALID_UNDERLYING,
    SET_PROTECTION_UNDERLYING_WITHOUT_PRICE,
    SET_PROTECTION_MARKET_FACTORY_OWNER_CHECK,
    SET_PROTECTION_MARKET_FACTORY_VALIDITY_CHECK,
    SET_RESERVE_GUARDIAN_OWNER_CHECK
  }

  /**
   * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
   * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
   **/
  event Failure(uint256 error, uint256 info, uint256 detail);

  /**
   * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
   */
  function fail(Error err, FailureInfo info) internal returns (uint256) {
    emit Failure(uint256(err), uint256(info), 0);

    return uint256(err);
  }

  /**
   * @dev use this when reporting an opaque error from an upgradeable collaborator contract
   */
  function failOpaque(
    Error err,
    FailureInfo info,
    uint256 opaqueError
  ) internal returns (uint256) {
    emit Failure(uint256(err), uint256(info), opaqueError);

    return uint256(err);
  }
}

contract TokenErrorReporter {
  enum Error {
    NO_ERROR,
    UNAUTHORIZED,
    BAD_INPUT,
    COMPTROLLER_REJECTION,
    COMPTROLLER_CALCULATION_ERROR,
    INTEREST_RATE_MODEL_ERROR,
    INVALID_ACCOUNT_PAIR,
    INVALID_CLOSE_AMOUNT_REQUESTED,
    INVALID_COLLATERAL_FACTOR,
    MATH_ERROR,
    MARKET_NOT_FRESH,
    MARKET_NOT_LISTED,
    TOKEN_INSUFFICIENT_ALLOWANCE,
    TOKEN_INSUFFICIENT_BALANCE,
    TOKEN_INSUFFICIENT_CASH,
    TOKEN_TRANSFER_IN_FAILED,
    TOKEN_TRANSFER_OUT_FAILED,
    INVALID_GUARDIAN,
    MARKET_TRIGGERED
  }

  enum FailureInfo {
    ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
    ACCRUE_INTEREST_ACCUMULATED_INTEREST_CALCULATION_FAILED,
    ACCRUE_INTEREST_BORROW_RATE_CALCULATION_FAILED,
    ACCRUE_INTEREST_NEW_BORROW_INDEX_CALCULATION_FAILED,
    ACCRUE_INTEREST_NEW_TOTAL_BORROWS_CALCULATION_FAILED,
    ACCRUE_INTEREST_NEW_TOTAL_RESERVES_CALCULATION_FAILED,
    ACCRUE_INTEREST_SIMPLE_INTEREST_FACTOR_CALCULATION_FAILED,
    BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
    BORROW_ACCRUE_INTEREST_FAILED,
    BORROW_CASH_NOT_AVAILABLE,
    BORROW_FRESHNESS_CHECK,
    BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
    BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED,
    BORROW_MARKET_NOT_LISTED,
    BORROW_COMPTROLLER_REJECTION,
    LIQUIDATE_ACCRUE_BORROW_INTEREST_FAILED,
    LIQUIDATE_ACCRUE_COLLATERAL_INTEREST_FAILED,
    LIQUIDATE_COLLATERAL_FRESHNESS_CHECK,
    LIQUIDATE_COMPTROLLER_REJECTION,
    LIQUIDATE_COMPTROLLER_CALCULATE_AMOUNT_SEIZE_FAILED,
    LIQUIDATE_CLOSE_AMOUNT_IS_UINT_MAX,
    LIQUIDATE_CLOSE_AMOUNT_IS_ZERO,
    LIQUIDATE_FRESHNESS_CHECK,
    LIQUIDATE_LIQUIDATOR_IS_BORROWER,
    LIQUIDATE_REPAY_BORROW_FRESH_FAILED,
    LIQUIDATE_SEIZE_BALANCE_INCREMENT_FAILED,
    LIQUIDATE_SEIZE_BALANCE_DECREMENT_FAILED,
    LIQUIDATE_SEIZE_COMPTROLLER_REJECTION,
    LIQUIDATE_SEIZE_LIQUIDATOR_IS_BORROWER,
    LIQUIDATE_SEIZE_TOO_MUCH,
    MINT_ACCRUE_INTEREST_FAILED,
    MINT_COMPTROLLER_REJECTION,
    MINT_EXCHANGE_CALCULATION_FAILED,
    MINT_EXCHANGE_RATE_READ_FAILED,
    MINT_FRESHNESS_CHECK,
    MINT_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED,
    MINT_NEW_TOTAL_SUPPLY_CALCULATION_FAILED,
    MINT_TRANSFER_IN_FAILED,
    MINT_TRANSFER_IN_NOT_POSSIBLE,
    REDEEM_ACCRUE_INTEREST_FAILED,
    REDEEM_COMPTROLLER_REJECTION,
    REDEEM_EXCHANGE_TOKENS_CALCULATION_FAILED,
    REDEEM_EXCHANGE_AMOUNT_CALCULATION_FAILED,
    REDEEM_EXCHANGE_RATE_READ_FAILED,
    REDEEM_FRESHNESS_CHECK,
    REDEEM_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED,
    REDEEM_NEW_TOTAL_SUPPLY_CALCULATION_FAILED,
    REDEEM_TRANSFER_OUT_NOT_POSSIBLE,
    REDUCE_RESERVES_ACCRUE_INTEREST_FAILED,
    REDUCE_RESERVES_ADMIN_CHECK,
    REDUCE_RESERVES_CASH_NOT_AVAILABLE,
    REDUCE_RESERVES_FRESH_CHECK,
    REDUCE_RESERVES_VALIDATION,
    REPAY_BEHALF_ACCRUE_INTEREST_FAILED,
    REPAY_BORROW_ACCRUE_INTEREST_FAILED,
    REPAY_BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
    REPAY_BORROW_COMPTROLLER_REJECTION,
    REPAY_BORROW_FRESHNESS_CHECK,
    REPAY_BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED,
    REPAY_BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
    REPAY_BORROW_TRANSFER_IN_NOT_POSSIBLE,
    SET_COLLATERAL_FACTOR_OWNER_CHECK,
    SET_COLLATERAL_FACTOR_VALIDATION,
    SET_COMPTROLLER_OWNER_CHECK,
    SET_INTEREST_RATE_MODEL_ACCRUE_INTEREST_FAILED,
    SET_INTEREST_RATE_MODEL_FRESH_CHECK,
    SET_INTEREST_RATE_MODEL_OWNER_CHECK,
    SET_MAX_ASSETS_OWNER_CHECK,
    SET_ORACLE_MARKET_NOT_LISTED,
    SET_PENDING_ADMIN_OWNER_CHECK,
    SET_RESERVE_FACTOR_ACCRUE_INTEREST_FAILED,
    SET_RESERVE_FACTOR_ADMIN_CHECK,
    SET_RESERVE_FACTOR_FRESH_CHECK,
    SET_RESERVE_FACTOR_BOUNDS_CHECK,
    TRANSFER_COMPTROLLER_REJECTION,
    TRANSFER_NOT_ALLOWED,
    TRANSFER_NOT_ENOUGH,
    TRANSFER_TOO_MUCH,
    ADD_RESERVES_ACCRUE_INTEREST_FAILED,
    ADD_RESERVES_FRESH_CHECK,
    ADD_RESERVES_TRANSFER_IN_NOT_POSSIBLE,
    REDUCE_RESERVES_GUARDIAN_NOT_SET,
    TRIGGER_ACTIVATED_BEFORE_REDEEM_OR_BORROW
  }

  /**
   * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
   * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
   **/
  event Failure(uint256 error, uint256 info, uint256 detail);

  /**
   * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
   */
  function fail(Error err, FailureInfo info) internal returns (uint256) {
    emit Failure(uint256(err), uint256(info), 0);

    return uint256(err);
  }

  /**
   * @dev use this when reporting an opaque error from an upgradeable collaborator contract
   */
  function failOpaque(
    Error err,
    FailureInfo info,
    uint256 opaqueError
  ) internal returns (uint256) {
    emit Failure(uint256(err), uint256(info), opaqueError);

    return uint256(err);
  }
}

contract ProtectionMarketFactoryErrorReporter {
  enum Error {NO_ERROR, UNAUTHORIZED, INTEREST_RATE_MODEL_ERROR}

  enum FailureInfo {SET_DEFAULT_INTEREST_RATE_MODEL_OWNER_CHECK, SET_DEFAULT_INTEREST_RATE_MODEL_VALIDITY_CHECK}

  /**
   * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
   * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
   **/
  event Failure(uint256 error, uint256 info, uint256 detail);

  /**
   * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
   */
  function fail(Error err, FailureInfo info) internal returns (uint256) {
    emit Failure(uint256(err), uint256(info), 0);

    return uint256(err);
  }

  /**
   * @dev use this when reporting an opaque error from an upgradeable collaborator contract
   */
  function failOpaque(
    Error err,
    FailureInfo info,
    uint256 opaqueError
  ) internal returns (uint256) {
    emit Failure(uint256(err), uint256(info), opaqueError);

    return uint256(err);
  }
}

contract OracleErrorReporter {
  enum Error {NO_ERROR, UNAUTHORIZED}

  enum FailureInfo {ACCEPT_ADMIN_PENDING_ADMIN_CHECK, ADD_OR_UPDATE_ORACLES_OWNER_CHECK, SET_PENDING_ADMIN_OWNER_CHECK}

  /**
   * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
   * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
   **/
  event Failure(uint256 error, uint256 info, uint256 detail);

  /**
   * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
   */
  function fail(Error err, FailureInfo info) internal returns (uint256) {
    emit Failure(uint256(err), uint256(info), 0);

    return uint256(err);
  }

  /**
   * @dev use this when reporting an opaque error from an upgradeable collaborator contract
   */
  function failOpaque(
    Error err,
    FailureInfo info,
    uint256 opaqueError
  ) internal returns (uint256) {
    emit Failure(uint256(err), uint256(info), opaqueError);

    return uint256(err);
  }
}

pragma solidity 0.5.17;

/**
 * @title ERC 20 Token Standard Interface
 *  https://eips.ethereum.org/EIPS/eip-20
 */
interface EIP20Interface {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  /**
   * @notice Get the total number of tokens in circulation
   * @return The supply of tokens
   */
  function totalSupply() external view returns (uint256);

  /**
   * @notice Gets the balance of the specified address
   * @param owner The address from which the balance will be retrieved
   * @return The balance
   */
  function balanceOf(address owner) external view returns (uint256 balance);

  /**
   * @notice Transfer `amount` tokens from `msg.sender` to `dst`
   * @param dst The address of the destination account
   * @param amount The number of tokens to transfer
   * @return Whether or not the transfer succeeded
   */
  function transfer(address dst, uint256 amount) external returns (bool success);

  /**
   * @notice Transfer `amount` tokens from `src` to `dst`
   * @param src The address of the source account
   * @param dst The address of the destination account
   * @param amount The number of tokens to transfer
   * @return Whether or not the transfer succeeded
   */
  function transferFrom(
    address src,
    address dst,
    uint256 amount
  ) external returns (bool success);

  /**
   * @notice Approve `spender` to transfer up to `amount` from `src`
   * @dev This will overwrite the approval amount for `spender`
   *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
   * @param spender The address of the account which may transfer tokens
   * @param amount The number of tokens that are approved (-1 means infinite)
   * @return Whether or not the approval succeeded
   */
  function approve(address spender, uint256 amount) external returns (bool success);

  /**
   * @notice Get the current allowance from `owner` for `spender`
   * @param owner The address of the account which owns the tokens to be spent
   * @param spender The address of the account which may transfer tokens
   * @return The number of tokens allowed to be spent (-1 means infinite)
   */
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  event Transfer(address indexed from, address indexed to, uint256 amount);
  event Approval(address indexed owner, address indexed spender, uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.5.17;

/**
 * @notice String operations
 * @dev Sourced from the OpenZeppelin implementation here: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/c789941d76dd713333bdeafe5b4484f6d9543c4e/contracts/utils/Strings.sol
 */
library Strings {
  /**
   * @dev Converts a `uint256` to its ASCII `string` representation.
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
    uint256 index = digits - 1;
    temp = value;
    while (temp != 0) {
      buffer[index--] = bytes1(uint8(48 + (temp % 10)));
      temp /= 10;
    }
    return string(buffer);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.5.17;

/**
 * @notice Interface for creating or interacting with a Trigger contract
 * @dev All trigger contracts created must conform to this interface
 */
contract TriggerInterface {
  /// @notice Trigger name
  function name() external view returns (string memory);

  /// @notice Trigger symbol
  function symbol() external view returns (string memory);

  /// @notice Trigger description
  function description() external view returns (string memory);

  /// @notice Returns array of IDs, where each ID corresponds to a platform covered by this trigger
  /// @dev See documentation for mapping of ID number to platform
  function getPlatformIds() external view returns (uint256[] memory);

  /// @notice Returns address of recipient who receives subsidies for creating the trigger and associated protection market
  function recipient() external view returns (address);

  /// @notice Returns true if trigger condition has been met
  function isTriggered() external view returns (bool);

  /// @notice Checks trigger condition, sets isTriggered flag to true if condition is met, and returns the new trigger status
  function checkAndToggleTrigger() external returns (bool);
}

pragma solidity 0.5.17;

import "./CToken.sol";

/**
 * @notice CTokens which wrap an EIP-20 underlying
 */
contract CErc20 is CToken, CErc20Interface {
  /**
   * @notice Initialize a new money market or protection market
   * @param underlying_ The address of the underlying asset
   * @param comptroller_ The address of the Comptroller
   * @param interestRateModel_ The address of the interest rate model
   * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
   * @param name_ ERC-20 name of this token
   * @param symbol_ ERC-20 symbol of this token
   * @param decimals_ ERC-20 decimal precision of this token
   * @param trigger_ Trigger contract address for protection markets, or the zero address for money markets
   */
  function initialize(
    address underlying_,
    ComptrollerInterface comptroller_,
    InterestRateModel interestRateModel_,
    uint256 initialExchangeRateMantissa_,
    string memory name_,
    string memory symbol_,
    uint8 decimals_,
    address trigger_
  ) public {
    // CToken initialize does the bulk of the work
    super.initialize(
      comptroller_,
      interestRateModel_,
      initialExchangeRateMantissa_,
      name_,
      symbol_,
      decimals_,
      trigger_
    );

    // Set underlying and sanity check it
    underlying = underlying_;
    EIP20Interface(underlying).totalSupply();
  }

  /*** User Interface ***/

  /**
   * @notice Sender supplies assets into the market and receives cTokens in exchange
   * @dev Accrues interest whether or not the operation succeeds, unless reverted
   * @param mintAmount The amount of the underlying asset to supply
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function mint(uint256 mintAmount) external returns (uint256) {
    (uint256 err, ) = mintInternal(mintAmount);
    return err;
  }

  /**
   * @notice Sender redeems cTokens in exchange for the underlying asset
   * @dev Accrues interest whether or not the operation succeeds, unless reverted
   * @param redeemTokens The number of cTokens to redeem into underlying
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function redeem(uint256 redeemTokens) external returns (uint256) {
    return redeemInternal(redeemTokens);
  }

  /**
   * @notice Sender redeems cTokens in exchange for a specified amount of underlying asset
   * @dev Accrues interest whether or not the operation succeeds, unless reverted
   * @param redeemAmount The amount of underlying to redeem
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function redeemUnderlying(uint256 redeemAmount) external returns (uint256) {
    return redeemUnderlyingInternal(redeemAmount);
  }

  /**
   * @notice Sender borrows assets from the protocol to their own address
   * @param borrowAmount The amount of the underlying asset to borrow
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function borrow(uint256 borrowAmount) external returns (uint256) {
    return borrowInternal(borrowAmount);
  }

  /**
   * @notice Sender repays their own borrow
   * @param repayAmount The amount to repay
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function repayBorrow(uint256 repayAmount) external returns (uint256) {
    (uint256 err, ) = repayBorrowInternal(repayAmount);
    return err;
  }

  /**
   * @notice Sender repays a borrow belonging to borrower
   * @param borrower the account with the debt being payed off
   * @param repayAmount The amount to repay
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function repayBorrowBehalf(address borrower, uint256 repayAmount) external returns (uint256) {
    (uint256 err, ) = repayBorrowBehalfInternal(borrower, repayAmount);
    return err;
  }

  /**
   * @notice The sender liquidates the borrowers collateral.
   *  The collateral seized is transferred to the liquidator.
   * @param borrower The borrower of this cToken to be liquidated
   * @param repayAmount The amount of the underlying borrowed asset to repay
   * @param cTokenCollateral The market in which to seize collateral from the borrower
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function liquidateBorrow(
    address borrower,
    uint256 repayAmount,
    CTokenInterface cTokenCollateral
  ) external returns (uint256) {
    (uint256 err, ) = liquidateBorrowInternal(borrower, repayAmount, cTokenCollateral);
    return err;
  }

  /**
   * @notice The sender adds to reserves.
   * @param addAmount The amount fo underlying token to add as reserves
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _addReserves(uint256 addAmount) external returns (uint256) {
    return _addReservesInternal(addAmount);
  }

  /*** Safe Token ***/

  /**
   * @notice Gets balance of this contract in terms of the underlying
   * @dev This excludes the value of the current message, if any
   * @return The quantity of underlying tokens owned by this contract
   */
  function getCashPrior() internal view returns (uint256) {
    EIP20Interface token = EIP20Interface(underlying);
    return token.balanceOf(address(this));
  }

  /**
   * @dev Similar to EIP20 transfer, except it handles a False result from `transferFrom` and reverts in that case.
   *      This will revert due to insufficient balance or insufficient allowance.
   *      This function returns the actual amount received,
   *      which may be less than `amount` if there is a fee attached to the transfer.
   *
   *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
   *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
   */
  function doTransferIn(address from, uint256 amount) internal returns (uint256) {
    EIP20NonStandardInterface token = EIP20NonStandardInterface(underlying);
    uint256 balanceBefore = EIP20Interface(underlying).balanceOf(address(this));
    token.transferFrom(from, address(this), amount);

    bool success;
    assembly {
      switch returndatasize()
        case 0 {
          // This is a non-standard ERC-20
          success := not(0) // set success to true
        }
        case 32 {
          // This is a compliant ERC-20
          returndatacopy(0, 0, 32)
          success := mload(0) // Set `success = returndata` of external call
        }
        default {
          // This is an excessively non-compliant ERC-20, revert.
          revert(0, 0)
        }
    }
    require(success, "TOKEN_TRANSFER_IN_FAILED");

    // Calculate the amount that was *actually* transferred
    uint256 balanceAfter = EIP20Interface(underlying).balanceOf(address(this));
    require(balanceAfter >= balanceBefore, "TOKEN_TRANSFER_IN_OVERFLOW");
    return balanceAfter - balanceBefore; // underflow already checked above, just subtract
  }

  /**
   * @dev Similar to EIP20 transfer, except it handles a False success from `transfer` and returns an explanatory
   *      error code rather than reverting. If caller has not called checked protocol's balance, this may revert due to
   *      insufficient cash held in this contract. If caller has checked protocol's balance prior to this call, and verified
   *      it is >= amount, this should not revert in normal conditions.
   *
   *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
   *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
   */
  function doTransferOut(address payable to, uint256 amount) internal {
    EIP20NonStandardInterface token = EIP20NonStandardInterface(underlying);
    token.transfer(to, amount);

    bool success;
    assembly {
      switch returndatasize()
        case 0 {
          // This is a non-standard ERC-20
          success := not(0) // set success to true
        }
        case 32 {
          // This is a compliant ERC-20
          returndatacopy(0, 0, 32)
          success := mload(0) // Set `success = returndata` of external call
        }
        default {
          // This is an excessively non-compliant ERC-20, revert.
          revert(0, 0)
        }
    }
    require(success, "TOKEN_TRANSFER_OUT_FAILED");
  }
}

pragma solidity 0.5.17;

import "./ComptrollerInterface.sol";
import "./CTokenInterfaces.sol";
import "./TriggerInterface.sol";
import "./ErrorReporter.sol";
import "./Exponential.sol";
import "./EIP20Interface.sol";
import "./EIP20NonStandardInterface.sol";
import "./InterestRateModel.sol";

/**
 * @notice Abstract base for CTokens
 */
contract CToken is CTokenInterface, Exponential, TokenErrorReporter {
  /// @notice The EIP-712 typehash for the contract's domain (computed inline later to reduce contract size)
  /// @dev Not exposing DOMAIN_SEPARATOR means this implementation not conform to EIP-2612
  // bytes32 public constant DOMAIN_SEPARATOR = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

  /// @notice The EIP-712 typehash for the ballot struct used by the contract (inlined later to reduce contract size)
  // bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
  //                                         = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9

  /// @notice Nonce mapping for permit support
  mapping(address => uint256) public nonces;

  /**
   * @notice Initialize a new money market or protection market
   * @param comptroller_ The address of the Comptroller
   * @param interestRateModel_ The address of the interest rate model
   * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
   * @param name_ EIP-20 name of this token
   * @param symbol_ EIP-20 symbol of this token
   * @param decimals_ EIP-20 decimal precision of this token
   * @param trigger_ Trigger contract address for protection markets, or the zero address for money markets
   */
  function initialize(
    ComptrollerInterface comptroller_,
    InterestRateModel interestRateModel_,
    uint256 initialExchangeRateMantissa_,
    string memory name_,
    string memory symbol_,
    uint8 decimals_,
    address trigger_
  ) public {
    require(msg.sender == admin, "only admin may initialize market");
    require(accrualBlockNumber == 0 && borrowIndex == 0, "market already initialized");

    // Set initial exchange rate
    initialExchangeRateMantissa = initialExchangeRateMantissa_;
    require(initialExchangeRateMantissa > 0, "initial exchange rate must be above zero");

    // Set the comptroller
    // Ensure invoke comptroller.isComptroller() returns true
    require(comptroller_.isComptroller(), "marker method returned false");
    // Set market's comptroller to newComptroller
    emit NewComptroller(comptroller, comptroller_);
    comptroller = comptroller_;

    // Initialize block number and borrow index (block number mocks depend on comptroller being set)
    accrualBlockNumber = getBlockNumber();
    borrowIndex = mantissaOne;

    // Set the interest rate model (depends on block number / borrow index)
    uint256 err = _setInterestRateModelFresh(interestRateModel_);
    require(err == uint256(Error.NO_ERROR), "setting interest rate model failed");

    name = name_;
    symbol = symbol_;
    decimals = decimals_;

    // The counter starts true to prevent changing it from zero to non-zero (i.e. smaller cost/refund)
    _notEntered = true;

    // Set trigger contract address and market type
    trigger = trigger_;
    emit TriggerSet(false);
  }

  /**
   * @notice Transfer `tokens` tokens from `src` to `dst` by `spender`
   * @dev Called by both `transfer` and `transferFrom` internally
   * @param spender The address of the account performing the transfer
   * @param src The address of the source account
   * @param dst The address of the destination account
   * @param tokens The number of tokens to transfer
   * @return Whether or not the transfer succeeded
   */
  function transferTokens(
    address spender,
    address src,
    address dst,
    uint256 tokens
  ) internal returns (uint256) {
    /* Fail if transfer not allowed */
    uint256 allowed = comptroller.transferAllowed(address(this), src, dst, tokens);
    if (allowed != 0) {
      return failOpaque(Error.COMPTROLLER_REJECTION, FailureInfo.TRANSFER_COMPTROLLER_REJECTION, allowed);
    }

    /* Do not allow self-transfers */
    if (src == dst) {
      return fail(Error.BAD_INPUT, FailureInfo.TRANSFER_NOT_ALLOWED);
    }

    /* Get the allowance, infinite for the account owner */
    uint256 startingAllowance = 0;
    if (spender == src) {
      startingAllowance = uint256(-1);
    } else {
      startingAllowance = transferAllowances[src][spender];
    }

    /* Do the calculations, checking for {under,over}flow */
    MathError mathErr;
    uint256 allowanceNew;
    uint256 srcTokensNew;
    uint256 dstTokensNew;

    (mathErr, allowanceNew) = subUInt(startingAllowance, tokens);
    if (mathErr != MathError.NO_ERROR) {
      return fail(Error.MATH_ERROR, FailureInfo.TRANSFER_NOT_ALLOWED);
    }

    (mathErr, srcTokensNew) = subUInt(accountTokens[src], tokens);
    if (mathErr != MathError.NO_ERROR) {
      return fail(Error.MATH_ERROR, FailureInfo.TRANSFER_NOT_ENOUGH);
    }

    (mathErr, dstTokensNew) = addUInt(accountTokens[dst], tokens);
    if (mathErr != MathError.NO_ERROR) {
      return fail(Error.MATH_ERROR, FailureInfo.TRANSFER_TOO_MUCH);
    }

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    accountTokens[src] = srcTokensNew;
    accountTokens[dst] = dstTokensNew;

    /* Eat some of the allowance (if necessary) */
    if (startingAllowance != uint256(-1)) {
      transferAllowances[src][spender] = allowanceNew;
    }

    /* We emit a Transfer event */
    emit Transfer(src, dst, tokens);

    return uint256(Error.NO_ERROR);
  }

  /**
   * @notice Transfer `amount` tokens from `msg.sender` to `dst`
   * @param dst The address of the destination account
   * @param amount The number of tokens to transfer
   * @return Whether or not the transfer succeeded
   */
  function transfer(address dst, uint256 amount) external nonReentrant returns (bool) {
    return transferTokens(msg.sender, msg.sender, dst, amount) == uint256(Error.NO_ERROR);
  }

  /**
   * @notice Transfer `amount` tokens from `src` to `dst`
   * @param src The address of the source account
   * @param dst The address of the destination account
   * @param amount The number of tokens to transfer
   * @return Whether or not the transfer succeeded
   */
  function transferFrom(
    address src,
    address dst,
    uint256 amount
  ) external nonReentrant returns (bool) {
    return transferTokens(msg.sender, src, dst, amount) == uint256(Error.NO_ERROR);
  }

  /**
   * @notice Approve `spender` to transfer up to `amount` from `owner` (base method)
   * @dev This will overwrite the approval amount for `spender`
   * and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
   * @param owner The address of the account that owns the tokens
   * @param spender The address of the account which may transfer tokens
   * @param amount The number of tokens that are approved (-1 means infinite)
   * @return Whether or not the approval succeeded
   */
  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) private returns (bool) {
    transferAllowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
    return true;
  }

  /**
   * @notice Approve `spender` to transfer up to `amount` from `msg.sender`
   * @dev This will overwrite the approval amount for `spender`
   * and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
   * @param spender The address of the account which may transfer tokens
   * @param amount The number of tokens that are approved (-1 means infinite)
   * @return Whether or not the approval succeeded
   */
  function approve(address spender, uint256 amount) external returns (bool) {
    return _approve(msg.sender, spender, amount);
  }

  /**
   * @notice Permit - approve a 'spender' to transfer up to 'amount' from owner if signatore denotes owner
   * @dev This will overwrite the approval amount for `spender` should the signature indicate the proper owner
   */
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    require(deadline >= block.timestamp, "Permit expired");

    // Original address recovery and digest creation code
    // bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_SEPARATOR, keccak256(bytes(name)), getChainId(), address(this)));
    // bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline));
    // bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    // address recoveredAddress = ecrecover(digest, v, r, s);

    // Digest creation and address recovery code with everything in-line and permit hash pre-hashed to reduce code size
    address recoveredAddress =
      ecrecover(
        keccak256(
          abi.encodePacked(
            "\x19\x01",
            keccak256(
              abi.encode(
                keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                getChainId(),
                address(this)
              )
            ),
            keccak256(
              abi.encode(
                0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9,
                owner,
                spender,
                value,
                nonces[owner]++,
                deadline
              )
            )
          )
        ),
        v,
        r,
        s
      );

    require(recoveredAddress != address(0) && recoveredAddress == owner, "Invalid signature");
    _approve(owner, spender, value);
  }

  /**
   * @notice Get the chain ID (uses assembly)
   * @return The chain ID
   */
  function getChainId() internal pure returns (uint256) {
    uint256 chainId;
    assembly {
      chainId := chainid()
    }
    return chainId;
  }

  /**
   * @notice Get the current allowance from `owner` for `spender`
   * @param owner The address of the account which owns the tokens to be spent
   * @param spender The address of the account which may transfer tokens
   * @return The number of tokens allowed to be spent (-1 means infinite)
   */
  function allowance(address owner, address spender) external view returns (uint256) {
    return transferAllowances[owner][spender];
  }

  /**
   * @notice Get the token balance of the `owner`
   * @param owner The address of the account to query
   * @return The number of tokens owned by `owner`
   */
  function balanceOf(address owner) external view returns (uint256) {
    return accountTokens[owner];
  }

  /**
   * @notice Get the underlying balance of the `owner`
   * @dev This also accrues interest in a transaction
   * @param owner The address of the account to query
   * @return The amount of underlying owned by `owner`
   */
  function balanceOfUnderlying(address owner) external returns (uint256) {
    Exp memory exchangeRate = Exp({mantissa: exchangeRateCurrent()});
    (MathError mErr, uint256 balance) = mulScalarTruncate(exchangeRate, accountTokens[owner]);
    require(mErr == MathError.NO_ERROR, "could not calculate balance");
    return balance;
  }

  /**
   * @notice Get a snapshot of the account's balances, and the cached exchange rate
   * @dev This is used by comptroller to more efficiently perform liquidity checks.
   * @param account Address of the account to snapshot
   * @return (possible error, token balance, borrow balance, exchange rate mantissa)
   */
  function getAccountSnapshot(address account)
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    uint256 cTokenBalance = accountTokens[account];
    uint256 borrowBalance;
    uint256 exchangeRateMantissa;

    MathError mErr;

    (mErr, borrowBalance) = borrowBalanceStoredInternal(account);
    if (mErr != MathError.NO_ERROR) {
      return (uint256(Error.MATH_ERROR), 0, 0, 0);
    }

    (mErr, exchangeRateMantissa) = exchangeRateStoredInternal();
    if (mErr != MathError.NO_ERROR) {
      return (uint256(Error.MATH_ERROR), 0, 0, 0);
    }

    return (uint256(Error.NO_ERROR), cTokenBalance, borrowBalance, exchangeRateMantissa);
  }

  /**
   * @dev Function to simply retrieve block number
   * This exists mainly for inheriting test contracts to stub this result.
   */
  function getBlockNumber() internal view returns (uint256) {
    return block.number;
  }

  /**
   * @notice Returns the current per-block borrow interest rate for this cToken
   * @return The borrow interest rate per block, scaled by 1e18
   */
  function borrowRatePerBlock() external view returns (uint256) {
    if (isTriggered) {
      return 0;
    }
    return interestRateModel.getBorrowRate(getCashPrior(), totalBorrows, totalReserves);
  }

  /**
   * @notice Returns the current per-block supply interest rate for this cToken
   * @return The supply interest rate per block, scaled by 1e18
   */
  function supplyRatePerBlock() external view returns (uint256) {
    if (isTriggered) {
      return 0;
    }
    return interestRateModel.getSupplyRate(getCashPrior(), totalBorrows, totalReserves, reserveFactorMantissa);
  }

  /**
   * @notice Returns the current total borrows plus accrued interest
   * @return The total borrows with interest
   */
  function totalBorrowsCurrent() external nonReentrant returns (uint256) {
    require(accrueInterest() == uint256(Error.NO_ERROR), "accrue interest failed");
    return totalBorrows;
  }

  /**
   * @notice Accrue interest to updated borrowIndex and then calculate account's borrow balance using the updated borrowIndex
   * @param account The address whose balance should be calculated after updating borrowIndex
   * @return The calculated balance
   */
  function borrowBalanceCurrent(address account) external nonReentrant returns (uint256) {
    require(accrueInterest() == uint256(Error.NO_ERROR), "accrue interest failed");
    return borrowBalanceStored(account);
  }

  /**
   * @notice Return the borrow balance of account based on stored data
   * @param account The address whose balance should be calculated
   * @return The calculated balance
   */
  function borrowBalanceStored(address account) public view returns (uint256) {
    (MathError err, uint256 result) = borrowBalanceStoredInternal(account);
    require(err == MathError.NO_ERROR, "borrowBalanceStoredInternal failed");
    return result;
  }

  /**
   * @notice Return the borrow balance of account based on stored data
   * @param account The address whose balance should be calculated
   * @return (error code, the calculated balance or 0 if error code is non-zero)
   */
  function borrowBalanceStoredInternal(address account) internal view returns (MathError, uint256) {
    if (isTriggered) {
      return (MathError.NO_ERROR, 0);
    }

    /* Note: we do not assert that the market is up to date */
    MathError mathErr;
    uint256 principalTimesIndex;
    uint256 result;

    /* Get borrowBalance and borrowIndex */
    BorrowSnapshot storage borrowSnapshot = accountBorrows[account];

    /* If borrowBalance = 0 then borrowIndex is likely also 0.
     * Rather than failing the calculation with a division by 0, we immediately return 0 in this case.
     */
    if (borrowSnapshot.principal == 0) {
      return (MathError.NO_ERROR, 0);
    }

    /* Calculate new borrow balance using the interest index:
     *  recentBorrowBalance = borrower.borrowBalance * market.borrowIndex / borrower.borrowIndex
     */
    (mathErr, principalTimesIndex) = mulUInt(borrowSnapshot.principal, borrowIndex);
    if (mathErr != MathError.NO_ERROR) {
      return (mathErr, 0);
    }

    (mathErr, result) = divUInt(principalTimesIndex, borrowSnapshot.interestIndex);
    if (mathErr != MathError.NO_ERROR) {
      return (mathErr, 0);
    }

    return (MathError.NO_ERROR, result);
  }

  /**
   * @notice Accrue interest then return the up-to-date exchange rate
   * @return Calculated exchange rate scaled by 1e18
   */
  function exchangeRateCurrent() public nonReentrant returns (uint256) {
    require(accrueInterest() == uint256(Error.NO_ERROR), "accrue interest failed");
    return exchangeRateStored();
  }

  /**
   * @notice Calculates the exchange rate from the underlying to the CToken
   * @dev This function does not accrue interest before calculating the exchange rate
   * @return Calculated exchange rate scaled by 1e18
   */
  function exchangeRateStored() public view returns (uint256) {
    (MathError err, uint256 result) = exchangeRateStoredInternal();
    require(err == MathError.NO_ERROR, "exchangeRateStoredInternal failed");
    return result;
  }

  /**
   * @notice Calculates the exchange rate from the underlying to the CToken
   * @dev This function does not accrue interest before calculating the exchange rate
   * @return (error code, calculated exchange rate scaled by 1e18)
   */
  function exchangeRateStoredInternal() internal view returns (MathError, uint256) {
    uint256 _totalSupply = totalSupply;
    if (_totalSupply == 0) {
      /*
       * If there are no tokens minted:
       *  exchangeRate = initialExchangeRate
       */
      return (MathError.NO_ERROR, initialExchangeRateMantissa);
    } else {
      /*
       * Otherwise:
       *  exchangeRate = (totalCash + totalBorrows - totalReserves) / totalSupply
       */
      uint256 totalCash = getCashPrior();
      uint256 cashPlusBorrowsMinusReserves;
      Exp memory exchangeRate;
      MathError mathErr;

      (mathErr, cashPlusBorrowsMinusReserves) = addThenSubUInt(totalCash, totalBorrows, totalReserves);
      if (mathErr != MathError.NO_ERROR) {
        return (mathErr, 0);
      }

      (mathErr, exchangeRate) = getExp(cashPlusBorrowsMinusReserves, _totalSupply);
      if (mathErr != MathError.NO_ERROR) {
        return (mathErr, 0);
      }

      return (MathError.NO_ERROR, exchangeRate.mantissa);
    }
  }

  /**
   * @notice Get cash balance of this cToken in the underlying asset
   * @return The quantity of underlying asset owned by this contract
   */
  function getCash() external view returns (uint256) {
    return getCashPrior();
  }

  /**
   * @notice Applies accrued interest to total borrows and reserves
   * @dev This calculates interest accrued from the last checkpointed block
   * up to the current block and writes new checkpoint to storage.
   */
  function accrueInterest() public returns (uint256) {
    /* Short-circuit if trigger event occured */
    if (isTriggered) {
      accrualBlockNumber = getBlockNumber(); // required to allow redemptions
      return uint256(Error.NO_ERROR);
    }

    /* Remember the initial block number */
    uint256 currentBlockNumber = getBlockNumber();
    uint256 accrualBlockNumberPrior = accrualBlockNumber;

    /* Short-circuit accumulating 0 interest */
    if (accrualBlockNumberPrior == currentBlockNumber) {
      return uint256(Error.NO_ERROR);
    }

    /* Read the previous values out of storage */
    uint256 cashPrior = getCashPrior();
    uint256 borrowsPrior = totalBorrows;
    uint256 reservesPrior = totalReserves;
    uint256 borrowIndexPrior = borrowIndex;

    /* Calculate the current borrow interest rate */
    uint256 borrowRateMantissa = interestRateModel.getBorrowRate(cashPrior, borrowsPrior, reservesPrior);
    require(borrowRateMantissa <= borrowRateMaxMantissa, "borrow rate too high");

    /* Calculate the number of blocks elapsed since the last accrual */
    (MathError mathErr, uint256 blockDelta) = subUInt(currentBlockNumber, accrualBlockNumberPrior);
    require(mathErr == MathError.NO_ERROR, "could not calculate block delta");

    /*
     * Calculate the interest accumulated into borrows and reserves and the new index:
     *  simpleInterestFactor = borrowRate * blockDelta
     *  interestAccumulated = simpleInterestFactor * totalBorrows
     *  totalBorrowsNew = interestAccumulated + totalBorrows
     *  totalReservesNew = interestAccumulated * reserveFactor + totalReserves
     *  borrowIndexNew = simpleInterestFactor * borrowIndex + borrowIndex
     */

    Exp memory simpleInterestFactor;
    uint256 interestAccumulated;
    uint256 totalBorrowsNew;
    uint256 totalReservesNew;
    uint256 borrowIndexNew;

    (mathErr, simpleInterestFactor) = mulScalar(Exp({mantissa: borrowRateMantissa}), blockDelta);
    if (mathErr != MathError.NO_ERROR) {
      return
        failOpaque(
          Error.MATH_ERROR,
          FailureInfo.ACCRUE_INTEREST_SIMPLE_INTEREST_FACTOR_CALCULATION_FAILED,
          uint256(mathErr)
        );
    }

    (mathErr, interestAccumulated) = mulScalarTruncate(simpleInterestFactor, borrowsPrior);
    if (mathErr != MathError.NO_ERROR) {
      return
        failOpaque(
          Error.MATH_ERROR,
          FailureInfo.ACCRUE_INTEREST_ACCUMULATED_INTEREST_CALCULATION_FAILED,
          uint256(mathErr)
        );
    }

    (mathErr, totalBorrowsNew) = addUInt(interestAccumulated, borrowsPrior);
    if (mathErr != MathError.NO_ERROR) {
      return
        failOpaque(
          Error.MATH_ERROR,
          FailureInfo.ACCRUE_INTEREST_NEW_TOTAL_BORROWS_CALCULATION_FAILED,
          uint256(mathErr)
        );
    }

    (mathErr, totalReservesNew) = mulScalarTruncateAddUInt(
      Exp({mantissa: reserveFactorMantissa}),
      interestAccumulated,
      reservesPrior
    );
    if (mathErr != MathError.NO_ERROR) {
      return
        failOpaque(
          Error.MATH_ERROR,
          FailureInfo.ACCRUE_INTEREST_NEW_TOTAL_RESERVES_CALCULATION_FAILED,
          uint256(mathErr)
        );
    }

    (mathErr, borrowIndexNew) = mulScalarTruncateAddUInt(simpleInterestFactor, borrowIndexPrior, borrowIndexPrior);
    if (mathErr != MathError.NO_ERROR) {
      return
        failOpaque(Error.MATH_ERROR, FailureInfo.ACCRUE_INTEREST_NEW_BORROW_INDEX_CALCULATION_FAILED, uint256(mathErr));
    }

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    /* We write the previously calculated values into storage */
    accrualBlockNumber = currentBlockNumber;
    borrowIndex = borrowIndexNew;
    totalBorrows = totalBorrowsNew;
    totalReserves = totalReservesNew;

    /* We emit an AccrueInterest event */
    emit AccrueInterest(cashPrior, interestAccumulated, borrowIndexNew, totalBorrowsNew);

    return uint256(Error.NO_ERROR);
  }

  /**
   * @notice Sender supplies assets into the market and receives cTokens in exchange
   * @dev Accrues interest whether or not the operation succeeds, unless reverted
   * @param mintAmount The amount of the underlying asset to supply
   * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual mint amount.
   */
  function mintInternal(uint256 mintAmount) internal nonReentrant returns (uint256, uint256) {
    uint256 error = accrueInterest();
    if (error != uint256(Error.NO_ERROR)) {
      // accrueInterest emits logs on errors, but we still want to log the fact that an attempted borrow failed
      return (fail(Error(error), FailureInfo.MINT_ACCRUE_INTEREST_FAILED), 0);
    }
    // mintFresh emits the actual Mint event if successful and logs on errors, so we don't need to
    return mintFresh(msg.sender, mintAmount);
  }

  struct MintLocalVars {
    Error err;
    MathError mathErr;
    uint256 exchangeRateMantissa;
    uint256 mintTokens;
    uint256 totalSupplyNew;
    uint256 accountTokensNew;
    uint256 actualMintAmount;
  }

  /**
   * @notice User supplies assets into the market and receives cTokens in exchange
   * @dev Assumes interest has already been accrued up to the current block
   * @param minter The address of the account which is supplying the assets
   * @param mintAmount The amount of the underlying asset to supply
   * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual mint amount.
   */
  function mintFresh(address minter, uint256 mintAmount) internal whenNotTriggered returns (uint256, uint256) {
    /* Fail if mint not allowed */
    uint256 allowed = comptroller.mintAllowed(address(this), minter, mintAmount);
    if (allowed != 0) {
      return (failOpaque(Error.COMPTROLLER_REJECTION, FailureInfo.MINT_COMPTROLLER_REJECTION, allowed), 0);
    }

    /* Verify market's block number equals current block number */
    if (accrualBlockNumber != getBlockNumber()) {
      return (fail(Error.MARKET_NOT_FRESH, FailureInfo.MINT_FRESHNESS_CHECK), 0);
    }

    MintLocalVars memory vars;

    (vars.mathErr, vars.exchangeRateMantissa) = exchangeRateStoredInternal();
    if (vars.mathErr != MathError.NO_ERROR) {
      return (failOpaque(Error.MATH_ERROR, FailureInfo.MINT_EXCHANGE_RATE_READ_FAILED, uint256(vars.mathErr)), 0);
    }

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    /*
     *  We call `doTransferIn` for the minter and the mintAmount.
     *  Note: The cToken must handle variations between ERC-20 and ETH underlying.
     *  `doTransferIn` reverts if anything goes wrong, since we can't be sure if
     *  side-effects occurred. The function returns the amount actually transferred,
     *  in case of a fee. On success, the cToken holds an additional `actualMintAmount`
     *  of cash.
     */
    vars.actualMintAmount = doTransferIn(minter, mintAmount);

    /*
     * We get the current exchange rate and calculate the number of cTokens to be minted:
     *  mintTokens = actualMintAmount / exchangeRate
     */

    (vars.mathErr, vars.mintTokens) = divScalarByExpTruncate(
      vars.actualMintAmount,
      Exp({mantissa: vars.exchangeRateMantissa})
    );
    require(vars.mathErr == MathError.NO_ERROR, "MINT_EXCHANGE_CALCULATION_FAILED");

    /*
     * We calculate the new total supply of cTokens and minter token balance, checking for overflow:
     *  totalSupplyNew = totalSupply + mintTokens
     *  accountTokensNew = accountTokens[minter] + mintTokens
     */
    (vars.mathErr, vars.totalSupplyNew) = addUInt(totalSupply, vars.mintTokens);
    require(vars.mathErr == MathError.NO_ERROR, "MINT_NEW_TOTAL_SUPPLY_CALCULATION_FAILED");

    (vars.mathErr, vars.accountTokensNew) = addUInt(accountTokens[minter], vars.mintTokens);
    require(vars.mathErr == MathError.NO_ERROR, "MINT_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED");

    /* We write previously calculated values into storage */
    totalSupply = vars.totalSupplyNew;
    accountTokens[minter] = vars.accountTokensNew;

    /* We emit a Mint event, and a Transfer event */
    emit Mint(minter, vars.actualMintAmount, vars.mintTokens);
    emit Transfer(address(this), minter, vars.mintTokens);

    return (uint256(Error.NO_ERROR), vars.actualMintAmount);
  }

  /**
   * @notice Sender redeems cTokens in exchange for the underlying asset
   * @dev Accrues interest whether or not the operation succeeds, unless reverted
   * @param redeemTokens The number of cTokens to redeem into underlying
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function redeemInternal(uint256 redeemTokens) internal nonReentrant returns (uint256) {
    uint256 error = accrueInterest();
    if (error != uint256(Error.NO_ERROR)) {
      // accrueInterest emits logs on errors, but we still want to log the fact that an attempted redeem failed
      return fail(Error(error), FailureInfo.REDEEM_ACCRUE_INTEREST_FAILED);
    }
    // redeemFresh emits redeem-specific logs on errors, so we don't need to
    return redeemFresh(msg.sender, redeemTokens, 0);
  }

  /**
   * @notice Sender redeems cTokens in exchange for a specified amount of underlying asset
   * @dev Accrues interest whether or not the operation succeeds, unless reverted
   * @param redeemAmount The amount of underlying to receive from redeeming cTokens
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function redeemUnderlyingInternal(uint256 redeemAmount) internal nonReentrant returns (uint256) {
    uint256 error = accrueInterest();
    if (error != uint256(Error.NO_ERROR)) {
      // accrueInterest emits logs on errors, but we still want to log the fact that an attempted redeem failed
      return fail(Error(error), FailureInfo.REDEEM_ACCRUE_INTEREST_FAILED);
    }
    // redeemFresh emits redeem-specific logs on errors, so we don't need to
    return redeemFresh(msg.sender, 0, redeemAmount);
  }

  struct RedeemLocalVars {
    Error err;
    MathError mathErr;
    uint256 exchangeRateMantissa;
    uint256 redeemTokens;
    uint256 redeemAmount;
    uint256 totalSupplyNew;
    uint256 accountTokensNew;
  }

  /**
   * @notice User redeems cTokens in exchange for the underlying asset
   * @dev Assumes interest has already been accrued up to the current block
   * @param redeemer The address of the account which is redeeming the tokens
   * @param redeemTokensIn The number of cTokens to redeem into underlying (only one of redeemTokensIn or redeemAmountIn may be non-zero)
   * @param redeemAmountIn The number of underlying tokens to receive from redeeming cTokens (only one of redeemTokensIn or redeemAmountIn may be non-zero)
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function redeemFresh(
    address payable redeemer,
    uint256 redeemTokensIn,
    uint256 redeemAmountIn
  ) internal returns (uint256) {
    // If trigger has not been toggled yet, check the condition, and if toggled exit this function and return failure
    // code indicating this. We have the `!isTriggered` check because without this suppliers would be blocked from
    // redeeming funds after a trigger occurs. In other words, we allow redeems in transactions before the trigger
    // was toggled, and in transactions after the trigger was toggled, but not if the trigger was just toggled in
    // this transaction
    if (!isTriggered && checkAndToggleTriggerInternal()) {
      return fail(Error.MARKET_TRIGGERED, FailureInfo.TRIGGER_ACTIVATED_BEFORE_REDEEM_OR_BORROW);
    }

    require(redeemTokensIn == 0 || redeemAmountIn == 0, "one of redeemTokensIn or redeemAmountIn must be zero");

    RedeemLocalVars memory vars;

    /* exchangeRate = invoke Exchange Rate Stored() */
    (vars.mathErr, vars.exchangeRateMantissa) = exchangeRateStoredInternal();
    if (vars.mathErr != MathError.NO_ERROR) {
      return failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_EXCHANGE_RATE_READ_FAILED, uint256(vars.mathErr));
    }

    /* If redeemTokensIn > 0: */
    if (redeemTokensIn > 0) {
      /*
       * We calculate the exchange rate and the amount of underlying to be redeemed:
       *  redeemTokens = redeemTokensIn
       *  redeemAmount = redeemTokensIn x exchangeRateCurrent
       */
      vars.redeemTokens = redeemTokensIn;

      (vars.mathErr, vars.redeemAmount) = mulScalarTruncate(Exp({mantissa: vars.exchangeRateMantissa}), redeemTokensIn);
      if (vars.mathErr != MathError.NO_ERROR) {
        return
          failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_EXCHANGE_TOKENS_CALCULATION_FAILED, uint256(vars.mathErr));
      }
    } else {
      /*
       * We get the current exchange rate and calculate the amount to be redeemed:
       *  redeemTokens = redeemAmountIn / exchangeRate
       *  redeemAmount = redeemAmountIn
       */

      (vars.mathErr, vars.redeemTokens) = divScalarByExpTruncate(
        redeemAmountIn,
        Exp({mantissa: vars.exchangeRateMantissa})
      );
      if (vars.mathErr != MathError.NO_ERROR) {
        return
          failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_EXCHANGE_AMOUNT_CALCULATION_FAILED, uint256(vars.mathErr));
      }

      vars.redeemAmount = redeemAmountIn;
    }

    /* Fail if redeem not allowed */
    uint256 allowed = comptroller.redeemAllowed(address(this), redeemer, vars.redeemTokens);
    if (allowed != 0) {
      return failOpaque(Error.COMPTROLLER_REJECTION, FailureInfo.REDEEM_COMPTROLLER_REJECTION, allowed);
    }

    /* Verify market's block number equals current block number */
    if (accrualBlockNumber != getBlockNumber()) {
      return fail(Error.MARKET_NOT_FRESH, FailureInfo.REDEEM_FRESHNESS_CHECK);
    }

    /*
     * We calculate the new total supply and redeemer balance, checking for underflow:
     *  totalSupplyNew = totalSupply - redeemTokens
     *  accountTokensNew = accountTokens[redeemer] - redeemTokens
     */
    (vars.mathErr, vars.totalSupplyNew) = subUInt(totalSupply, vars.redeemTokens);
    if (vars.mathErr != MathError.NO_ERROR) {
      return
        failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_NEW_TOTAL_SUPPLY_CALCULATION_FAILED, uint256(vars.mathErr));
    }

    (vars.mathErr, vars.accountTokensNew) = subUInt(accountTokens[redeemer], vars.redeemTokens);
    if (vars.mathErr != MathError.NO_ERROR) {
      return
        failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED, uint256(vars.mathErr));
    }

    /* Fail gracefully if protocol has insufficient cash */
    if (getCashPrior() < vars.redeemAmount) {
      return fail(Error.TOKEN_INSUFFICIENT_CASH, FailureInfo.REDEEM_TRANSFER_OUT_NOT_POSSIBLE);
    }

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    /*
     * We invoke doTransferOut for the redeemer and the redeemAmount.
     *  Note: The cToken must handle variations between ERC-20 and ETH underlying.
     *  On success, the cToken has redeemAmount less of cash.
     *  doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
     */
    doTransferOut(redeemer, vars.redeemAmount);

    /* We write previously calculated values into storage */
    totalSupply = vars.totalSupplyNew;
    accountTokens[redeemer] = vars.accountTokensNew;

    /* We emit a Transfer event, and a Redeem event */
    emit Transfer(redeemer, address(this), vars.redeemTokens);
    emit Redeem(redeemer, vars.redeemAmount, vars.redeemTokens);

    /* Require tokens is zero or amount is also zero */
    if (vars.redeemTokens == 0 && vars.redeemAmount > 0) {
      revert("redeemTokens zero");
    }

    return uint256(Error.NO_ERROR);
  }

  /**
   * @notice Sender borrows assets from the protocol to their own address
   * @param borrowAmount The amount of the underlying asset to borrow
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function borrowInternal(uint256 borrowAmount) internal nonReentrant returns (uint256) {
    uint256 error = accrueInterest();
    if (error != uint256(Error.NO_ERROR)) {
      // accrueInterest emits logs on errors, but we still want to log the fact that an attempted borrow failed
      return fail(Error(error), FailureInfo.BORROW_ACCRUE_INTEREST_FAILED);
    }
    // borrowFresh emits borrow-specific logs on errors, so we don't need to
    return borrowFresh(msg.sender, borrowAmount);
  }

  struct BorrowLocalVars {
    MathError mathErr;
    uint256 accountBorrows;
    uint256 accountBorrowsNew;
    uint256 totalBorrowsNew;
  }

  /**
   * @notice Users borrow assets from the protocol to their own address
   * @param borrowAmount The amount of the underlying asset to borrow
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function borrowFresh(address payable borrower, uint256 borrowAmount) internal whenNotTriggered returns (uint256) {
    // Check trigger condition, and if triggered, exit function and return failure code indicating this
    if (checkAndToggleTriggerInternal()) {
      return fail(Error.MARKET_TRIGGERED, FailureInfo.TRIGGER_ACTIVATED_BEFORE_REDEEM_OR_BORROW);
    }

    /* Fail if borrow not allowed */
    uint256 allowed = comptroller.borrowAllowed(address(this), borrower, borrowAmount);
    if (allowed != 0) {
      return failOpaque(Error.COMPTROLLER_REJECTION, FailureInfo.BORROW_COMPTROLLER_REJECTION, allowed);
    }

    /* Verify market's block number equals current block number */
    if (accrualBlockNumber != getBlockNumber()) {
      return fail(Error.MARKET_NOT_FRESH, FailureInfo.BORROW_FRESHNESS_CHECK);
    }

    /* Fail gracefully if protocol has insufficient underlying cash */
    if (getCashPrior() < borrowAmount) {
      return fail(Error.TOKEN_INSUFFICIENT_CASH, FailureInfo.BORROW_CASH_NOT_AVAILABLE);
    }

    BorrowLocalVars memory vars;

    /*
     * We calculate the new borrower and total borrow balances, failing on overflow:
     *  accountBorrowsNew = accountBorrows + borrowAmount
     *  totalBorrowsNew = totalBorrows + borrowAmount
     */
    (vars.mathErr, vars.accountBorrows) = borrowBalanceStoredInternal(borrower);
    if (vars.mathErr != MathError.NO_ERROR) {
      return
        failOpaque(Error.MATH_ERROR, FailureInfo.BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED, uint256(vars.mathErr));
    }

    (vars.mathErr, vars.accountBorrowsNew) = addUInt(vars.accountBorrows, borrowAmount);
    if (vars.mathErr != MathError.NO_ERROR) {
      return
        failOpaque(
          Error.MATH_ERROR,
          FailureInfo.BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED,
          uint256(vars.mathErr)
        );
    }

    (vars.mathErr, vars.totalBorrowsNew) = addUInt(totalBorrows, borrowAmount);
    if (vars.mathErr != MathError.NO_ERROR) {
      return
        failOpaque(Error.MATH_ERROR, FailureInfo.BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED, uint256(vars.mathErr));
    }

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    /*
     * We invoke doTransferOut for the borrower and the borrowAmount.
     *  Note: The cToken must handle variations between ERC-20 and ETH underlying.
     *  On success, the cToken borrowAmount less of cash.
     *  doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
     */
    doTransferOut(borrower, borrowAmount);

    /* We write the previously calculated values into storage */
    accountBorrows[borrower].principal = vars.accountBorrowsNew;
    accountBorrows[borrower].interestIndex = borrowIndex;
    totalBorrows = vars.totalBorrowsNew;

    /* We emit a Borrow event */
    emit Borrow(borrower, borrowAmount, vars.accountBorrowsNew, vars.totalBorrowsNew);

    return uint256(Error.NO_ERROR);
  }

  /**
   * @notice Sender repays their own borrow
   * @param repayAmount The amount to repay
   * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
   */
  function repayBorrowInternal(uint256 repayAmount) internal nonReentrant returns (uint256, uint256) {
    uint256 error = accrueInterest();
    if (error != uint256(Error.NO_ERROR)) {
      // accrueInterest emits logs on errors, but we still want to log the fact that an attempted borrow failed
      return (fail(Error(error), FailureInfo.REPAY_BORROW_ACCRUE_INTEREST_FAILED), 0);
    }
    // repayBorrowFresh emits repay-borrow-specific logs on errors, so we don't need to
    return repayBorrowFresh(msg.sender, msg.sender, repayAmount);
  }

  /**
   * @notice Sender repays a borrow belonging to borrower
   * @param borrower the account with the debt being payed off
   * @param repayAmount The amount to repay
   * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
   */
  function repayBorrowBehalfInternal(address borrower, uint256 repayAmount)
    internal
    nonReentrant
    returns (uint256, uint256)
  {
    uint256 error = accrueInterest();
    if (error != uint256(Error.NO_ERROR)) {
      // accrueInterest emits logs on errors, but we still want to log the fact that an attempted borrow failed
      return (fail(Error(error), FailureInfo.REPAY_BEHALF_ACCRUE_INTEREST_FAILED), 0);
    }
    // repayBorrowFresh emits repay-borrow-specific logs on errors, so we don't need to
    return repayBorrowFresh(msg.sender, borrower, repayAmount);
  }

  struct RepayBorrowLocalVars {
    Error err;
    MathError mathErr;
    uint256 repayAmount;
    uint256 borrowerIndex;
    uint256 accountBorrows;
    uint256 accountBorrowsNew;
    uint256 totalBorrowsNew;
    uint256 actualRepayAmount;
  }

  /**
   * @notice Borrows are repaid by another user (possibly the borrower).
   * @param payer the account paying off the borrow
   * @param borrower the account with the debt being payed off
   * @param repayAmount the amount of undelrying tokens being returned
   * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
   */
  function repayBorrowFresh(
    address payer,
    address borrower,
    uint256 repayAmount
  ) internal whenNotTriggered returns (uint256, uint256) {
    /* Fail if repayBorrow not allowed */
    uint256 allowed = comptroller.repayBorrowAllowed(address(this), payer, borrower, repayAmount);
    if (allowed != 0) {
      return (failOpaque(Error.COMPTROLLER_REJECTION, FailureInfo.REPAY_BORROW_COMPTROLLER_REJECTION, allowed), 0);
    }

    /* Verify market's block number equals current block number */
    if (accrualBlockNumber != getBlockNumber()) {
      return (fail(Error.MARKET_NOT_FRESH, FailureInfo.REPAY_BORROW_FRESHNESS_CHECK), 0);
    }

    RepayBorrowLocalVars memory vars;

    /* We remember the original borrowerIndex for verification purposes */
    vars.borrowerIndex = accountBorrows[borrower].interestIndex;

    /* We fetch the amount the borrower owes, with accumulated interest */
    (vars.mathErr, vars.accountBorrows) = borrowBalanceStoredInternal(borrower);
    if (vars.mathErr != MathError.NO_ERROR) {
      return (
        failOpaque(
          Error.MATH_ERROR,
          FailureInfo.REPAY_BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
          uint256(vars.mathErr)
        ),
        0
      );
    }

    /* If repayAmount == -1, repayAmount = accountBorrows */
    if (repayAmount == uint256(-1)) {
      vars.repayAmount = vars.accountBorrows;
    } else {
      vars.repayAmount = repayAmount;
    }

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    /*
     * We call doTransferIn for the payer and the repayAmount
     *  Note: The cToken must handle variations between ERC-20 and ETH underlying.
     *  On success, the cToken holds an additional repayAmount of cash.
     *  doTransferIn reverts if anything goes wrong, since we can't be sure if side effects occurred.
     *   it returns the amount actually transferred, in case of a fee.
     */
    vars.actualRepayAmount = doTransferIn(payer, vars.repayAmount);

    /*
     * We calculate the new borrower and total borrow balances, failing on underflow:
     *  accountBorrowsNew = accountBorrows - actualRepayAmount
     *  totalBorrowsNew = totalBorrows - actualRepayAmount
     */
    (vars.mathErr, vars.accountBorrowsNew) = subUInt(vars.accountBorrows, vars.actualRepayAmount);
    require(vars.mathErr == MathError.NO_ERROR, "REPAY_BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED");

    (vars.mathErr, vars.totalBorrowsNew) = subUInt(totalBorrows, vars.actualRepayAmount);
    require(vars.mathErr == MathError.NO_ERROR, "REPAY_BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED");

    /* We write the previously calculated values into storage */
    accountBorrows[borrower].principal = vars.accountBorrowsNew;
    accountBorrows[borrower].interestIndex = borrowIndex;
    totalBorrows = vars.totalBorrowsNew;

    /* We emit a RepayBorrow event */
    emit RepayBorrow(payer, borrower, vars.actualRepayAmount, vars.accountBorrowsNew, vars.totalBorrowsNew);

    return (uint256(Error.NO_ERROR), vars.actualRepayAmount);
  }

  /**
   * @notice The sender liquidates the borrowers collateral. The collateral seized is transferred to the liquidator.
   * @param borrower The borrower of this cToken to be liquidated
   * @param cTokenCollateral The market in which to seize collateral from the borrower
   * @param repayAmount The amount of the underlying borrowed asset to repay
   * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
   */
  function liquidateBorrowInternal(
    address borrower,
    uint256 repayAmount,
    CTokenInterface cTokenCollateral
  ) internal nonReentrant returns (uint256, uint256) {
    uint256 error = accrueInterest();
    if (error != uint256(Error.NO_ERROR)) {
      // accrueInterest emits logs on errors, but we still want to log the fact that an attempted liquidation failed
      return (fail(Error(error), FailureInfo.LIQUIDATE_ACCRUE_BORROW_INTEREST_FAILED), 0);
    }

    error = cTokenCollateral.accrueInterest();
    if (error != uint256(Error.NO_ERROR)) {
      // accrueInterest emits logs on errors, but we still want to log the fact that an attempted liquidation failed
      return (fail(Error(error), FailureInfo.LIQUIDATE_ACCRUE_COLLATERAL_INTEREST_FAILED), 0);
    }

    // liquidateBorrowFresh emits borrow-specific logs on errors, so we don't need to
    return liquidateBorrowFresh(msg.sender, borrower, repayAmount, cTokenCollateral);
  }

  /**
   * @notice The liquidator liquidates the borrowers collateral. The collateral seized is transferred to the liquidator.
   * @param borrower The borrower of this cToken to be liquidated
   * @param liquidator The address repaying the borrow and seizing collateral
   * @param cTokenCollateral The market in which to seize collateral from the borrower
   * @param repayAmount The amount of the underlying borrowed asset to repay
   * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
   */
  function liquidateBorrowFresh(
    address liquidator,
    address borrower,
    uint256 repayAmount,
    CTokenInterface cTokenCollateral
  ) internal whenNotTriggered returns (uint256, uint256) {
    /* Fail if liquidate not allowed */
    uint256 allowed =
      comptroller.liquidateBorrowAllowed(address(this), address(cTokenCollateral), liquidator, borrower, repayAmount);
    if (allowed != 0) {
      return (failOpaque(Error.COMPTROLLER_REJECTION, FailureInfo.LIQUIDATE_COMPTROLLER_REJECTION, allowed), 0);
    }

    /* Verify market's block number equals current block number */
    if (accrualBlockNumber != getBlockNumber()) {
      return (fail(Error.MARKET_NOT_FRESH, FailureInfo.LIQUIDATE_FRESHNESS_CHECK), 0);
    }

    /* Verify cTokenCollateral market's block number equals current block number */
    if (cTokenCollateral.accrualBlockNumber() != getBlockNumber()) {
      return (fail(Error.MARKET_NOT_FRESH, FailureInfo.LIQUIDATE_COLLATERAL_FRESHNESS_CHECK), 0);
    }

    /* Fail if borrower = liquidator */
    if (borrower == liquidator) {
      return (fail(Error.INVALID_ACCOUNT_PAIR, FailureInfo.LIQUIDATE_LIQUIDATOR_IS_BORROWER), 0);
    }

    /* Fail if repayAmount = 0 */
    if (repayAmount == 0) {
      return (fail(Error.INVALID_CLOSE_AMOUNT_REQUESTED, FailureInfo.LIQUIDATE_CLOSE_AMOUNT_IS_ZERO), 0);
    }

    /* Fail if repayAmount = -1 */
    if (repayAmount == uint256(-1)) {
      return (fail(Error.INVALID_CLOSE_AMOUNT_REQUESTED, FailureInfo.LIQUIDATE_CLOSE_AMOUNT_IS_UINT_MAX), 0);
    }

    /* Fail if repayBorrow fails */
    (uint256 repayBorrowError, uint256 actualRepayAmount) = repayBorrowFresh(liquidator, borrower, repayAmount);
    if (repayBorrowError != uint256(Error.NO_ERROR)) {
      return (fail(Error(repayBorrowError), FailureInfo.LIQUIDATE_REPAY_BORROW_FRESH_FAILED), 0);
    }

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    /* We calculate the number of collateral tokens that will be seized */
    (uint256 amountSeizeError, uint256 seizeTokens) =
      comptroller.liquidateCalculateSeizeTokens(address(this), address(cTokenCollateral), actualRepayAmount);
    require(amountSeizeError == uint256(Error.NO_ERROR), "LIQUIDATE_COMPTROLLER_CALCULATE_AMOUNT_SEIZE_FAILED");

    /* Revert if borrower collateral token balance < seizeTokens */
    require(cTokenCollateral.balanceOf(borrower) >= seizeTokens, "LIQUIDATE_SEIZE_TOO_MUCH");

    // If this is also the collateral, run seizeInternal to avoid re-entrancy, otherwise make an external call
    uint256 seizeError;
    if (address(cTokenCollateral) == address(this)) {
      seizeError = seizeInternal(address(this), liquidator, borrower, seizeTokens);
    } else {
      seizeError = cTokenCollateral.seize(liquidator, borrower, seizeTokens);
    }

    /* Revert if seize tokens fails (since we cannot be sure of side effects) */
    require(seizeError == uint256(Error.NO_ERROR), "token seizure failed");

    /* We emit a LiquidateBorrow event */
    emit LiquidateBorrow(liquidator, borrower, actualRepayAmount, address(cTokenCollateral), seizeTokens);

    return (uint256(Error.NO_ERROR), actualRepayAmount);
  }

  /**
   * @notice Transfers collateral tokens (this market) to the liquidator.
   * @dev Will fail unless called by another cToken during the process of liquidation.
   * It's absolutely critical to use msg.sender as the borrowed cToken and not a parameter.
   * @param liquidator The account receiving seized collateral
   * @param borrower The account having collateral seized
   * @param seizeTokens The number of cTokens to seize
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function seize(
    address liquidator,
    address borrower,
    uint256 seizeTokens
  ) external nonReentrant returns (uint256) {
    return seizeInternal(msg.sender, liquidator, borrower, seizeTokens);
  }

  /**
   * @notice Transfers collateral tokens (this market) to the liquidator.
   * @dev Called only during an in-kind liquidation, or by liquidateBorrow during the liquidation of another CToken.
   * It's absolutely critical to use msg.sender as the seizer cToken and not a parameter.
   * @param seizerToken The contract seizing the collateral (i.e. borrowed cToken)
   * @param liquidator The account receiving seized collateral
   * @param borrower The account having collateral seized
   * @param seizeTokens The number of cTokens to seize
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function seizeInternal(
    address seizerToken,
    address liquidator,
    address borrower,
    uint256 seizeTokens
  ) internal returns (uint256) {
    /* Fail if seize not allowed */
    uint256 allowed = comptroller.seizeAllowed(address(this), seizerToken, liquidator, borrower, seizeTokens);
    if (allowed != 0) {
      return failOpaque(Error.COMPTROLLER_REJECTION, FailureInfo.LIQUIDATE_SEIZE_COMPTROLLER_REJECTION, allowed);
    }

    /* Fail if borrower = liquidator */
    if (borrower == liquidator) {
      return fail(Error.INVALID_ACCOUNT_PAIR, FailureInfo.LIQUIDATE_SEIZE_LIQUIDATOR_IS_BORROWER);
    }

    MathError mathErr;
    uint256 borrowerTokensNew;
    uint256 liquidatorTokensNew;

    /*
     * We calculate the new borrower and liquidator token balances, failing on underflow/overflow:
     *  borrowerTokensNew = accountTokens[borrower] - seizeTokens
     *  liquidatorTokensNew = accountTokens[liquidator] + seizeTokens
     */
    (mathErr, borrowerTokensNew) = subUInt(accountTokens[borrower], seizeTokens);
    if (mathErr != MathError.NO_ERROR) {
      return failOpaque(Error.MATH_ERROR, FailureInfo.LIQUIDATE_SEIZE_BALANCE_DECREMENT_FAILED, uint256(mathErr));
    }

    (mathErr, liquidatorTokensNew) = addUInt(accountTokens[liquidator], seizeTokens);
    if (mathErr != MathError.NO_ERROR) {
      return failOpaque(Error.MATH_ERROR, FailureInfo.LIQUIDATE_SEIZE_BALANCE_INCREMENT_FAILED, uint256(mathErr));
    }

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    /* We write the previously calculated values into storage */
    accountTokens[borrower] = borrowerTokensNew;
    accountTokens[liquidator] = liquidatorTokensNew;

    /* Emit a Transfer event */
    emit Transfer(borrower, liquidator, seizeTokens);

    return uint256(Error.NO_ERROR);
  }

  /**
   * @notice Checks the trigger contract, and if triggered updates the state
   * @dev Implemented as a wrapper around borrow to avoid reentrancy risks. If this method simply called
   * `checkAndToggleTriggerInternal`, you have can have a reentrancy risk as follows:
   *   Call `checkAndToggleTriggerInternal` > enter trigger contract > trigger contract tries to borrow funds >
   *   borrow method enters `checkAndToggleTriggerInternal` > trigger contract returns false > borrow succeeds >
   *   trigger contract returns true > debts canceled for a borrow that occured in the triggering transaction
   * But you cannot do that if you enter `checkAndToggleTriggerInternal` from the borrow method, because the only way
   * to proceed with a borrow is for the trigger to return false
   * @return Returns the new trigger status
   */
  function checkAndToggleTrigger() external whenNotTriggered returns (bool) {
    borrowInternal(0); // this calls `checkAndToggleTriggerInternal`
    return isTriggered;
  }

  /**
   * @notice Checks the trigger contract, and if triggered updates the state
   * @return Returns the new trigger status
   */
  function checkAndToggleTriggerInternal() internal returns (bool) {
    /* Trigger can never be toggled for Money Markets, which have the zero address as the trigger address */
    if (trigger == address(0)) return false;

    /*
     * Untrusted call, since anyone can deploy a new protection market with any trigger. However, nothing
     * malicious can occur from reentering here, so a reentrancy guard and the checks-effects-interaction
     * are not required. The reason nothing malicious can happen is because the reentrancy must come from
     * the malicious trigger, and if we had a malicious trigger that tried to exploit reentrancy, here are
     * the options:
     *   1. Trigger is not toggled: You reenter during the trigger call, you'd call `accrueInterest()` again
     *      and that method does nothing when called twice in the same block. After `trigger.checkAndToggleTriggerInternal()`
     *      finally returns false, things continue as normal
     *   2. Trigger is toggled: As above, if you reenter during the trigger call, you'd call `accrueInterest()`
     *      again which will do nothing. If you try to borrow or redeem funds, this method will ultimately return true
     *      and prevent borrowing/redeeming (along with the `nonReentrant` modifier in `borrowInternal`). If you try to
     *      supply funds to get more COZY, you'll accrue that COZY for zero blocks and then lose some supplied funds
     */
    isTriggered = TriggerInterface(trigger).checkAndToggleTrigger();

    if (isTriggered) {
      /*
       * After the trigger event protection providers cannot redeem the full amount they supplied,
       * but can still redeem a fraction of the amount they supplied. This is because the only
       * funds left for suppliers to redeem is the unborrowed funds, as borrowed funds do not need
       * to be paid back. The amount you can redeem is proportional to how much you supplied.
       *
       * For example, if $1000 is supplied by protection providers, but only $800 is borrowed by
       * protection seekers, then when the trigger happens protection providers can withdraw a total
       * of $200 instead of $1000. That $200 is split proportionally between all providers. So if
       * Alice provided $300 and Bob provided $700 of the $1000, after the trigger Alice can redeem
       * her cTokens for $300 / $1000 * 200 = $60 and Bob can redeem his for $700 / $1000 * 200 = $140
       *
       * The exchange rate is calculated as:
       *   exchangeRate = (totalCash + totalBorrows - totalReserves) / totalSupply
       *
       * Therefore, if we zero out total borrows, the exchange rate methods will calculate the
       * desired exchange rate after the trigger event without needing to be modified.
       */
      totalBorrows = 0;
      emit TriggerSet(isTriggered);

      /* End subsidies to the market */
      comptroller._zeroOutCozySpeeds(address(this));
    }
    return isTriggered;
  }

  /*** Admin Functions ***/

  /**
   * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
   * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
   * @param newPendingAdmin New pending admin.
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _setPendingAdmin(address payable newPendingAdmin) external returns (uint256) {
    // Check caller = admin
    if (msg.sender != admin) {
      return fail(Error.UNAUTHORIZED, FailureInfo.SET_PENDING_ADMIN_OWNER_CHECK);
    }
    emit NewPendingAdmin(pendingAdmin, newPendingAdmin);

    // Store pendingAdmin with value newPendingAdmin
    pendingAdmin = newPendingAdmin;

    return uint256(Error.NO_ERROR);
  }

  /**
   * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
   * @dev Admin function for pending admin to accept role and update admin
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _acceptAdmin() external returns (uint256) {
    // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
    if (msg.sender != pendingAdmin || msg.sender == address(0)) {
      return fail(Error.UNAUTHORIZED, FailureInfo.ACCEPT_ADMIN_PENDING_ADMIN_CHECK);
    }

    // Save current values for inclusion in log
    address oldAdmin = admin;
    address oldPendingAdmin = pendingAdmin;

    // Store admin with value pendingAdmin
    admin = pendingAdmin;

    // Clear the pending value
    pendingAdmin = address(0);

    emit NewAdmin(oldAdmin, admin);
    emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);

    return uint256(Error.NO_ERROR);
  }

  /**
   * @notice accrues interest and sets a new reserve factor for the protocol using _setReserveFactorFresh
   * @dev Admin function to accrue interest and set a new reserve factor
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _setReserveFactor(uint256 newReserveFactorMantissa) external nonReentrant returns (uint256) {
    uint256 error = accrueInterest();
    if (error != uint256(Error.NO_ERROR)) {
      // accrueInterest emits logs on errors, but on top of that we want to log the fact that an attempted reserve factor change failed.
      return fail(Error(error), FailureInfo.SET_RESERVE_FACTOR_ACCRUE_INTEREST_FAILED);
    }
    // _setReserveFactorFresh emits reserve-factor-specific logs on errors, so we don't need to.
    return _setReserveFactorFresh(newReserveFactorMantissa);
  }

  /**
   * @notice Sets a new reserve factor for the protocol (*requires fresh interest accrual)
   * @dev Admin function to set a new reserve factor
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _setReserveFactorFresh(uint256 newReserveFactorMantissa) internal returns (uint256) {
    // Check caller is admin
    if (msg.sender != admin) {
      return fail(Error.UNAUTHORIZED, FailureInfo.SET_RESERVE_FACTOR_ADMIN_CHECK);
    }

    // Verify market's block number equals current block number
    if (accrualBlockNumber != getBlockNumber()) {
      return fail(Error.MARKET_NOT_FRESH, FailureInfo.SET_RESERVE_FACTOR_FRESH_CHECK);
    }

    // Check newReserveFactor ≤ maxReserveFactor
    if (newReserveFactorMantissa > reserveFactorMaxMantissa) {
      return fail(Error.BAD_INPUT, FailureInfo.SET_RESERVE_FACTOR_BOUNDS_CHECK);
    }

    emit NewReserveFactor(reserveFactorMantissa, newReserveFactorMantissa);
    reserveFactorMantissa = newReserveFactorMantissa;

    return uint256(Error.NO_ERROR);
  }

  /**
   * @notice Accrues interest and reduces reserves by transferring from msg.sender
   * @param addAmount Amount of addition to reserves
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _addReservesInternal(uint256 addAmount) internal nonReentrant returns (uint256) {
    uint256 error = accrueInterest();
    if (error != uint256(Error.NO_ERROR)) {
      // accrueInterest emits logs on errors, but on top of that we want to log the fact that an attempted reduce reserves failed.
      return fail(Error(error), FailureInfo.ADD_RESERVES_ACCRUE_INTEREST_FAILED);
    }

    // _addReservesFresh emits reserve-addition-specific logs on errors, so we don't need to.
    (error, ) = _addReservesFresh(addAmount);
    return error;
  }

  /**
   * @notice Add reserves by transferring from caller
   * @dev Requires fresh interest accrual
   * @param addAmount Amount of addition to reserves
   * @return (uint, uint) An error code (0=success, otherwise a failure (see ErrorReporter.sol for details)) and the actual amount added, net token fees
   */
  function _addReservesFresh(uint256 addAmount) internal returns (uint256, uint256) {
    // totalReserves + actualAddAmount
    uint256 totalReservesNew;
    uint256 actualAddAmount;

    // We fail gracefully unless market's block number equals current block number
    if (accrualBlockNumber != getBlockNumber()) {
      return (fail(Error.MARKET_NOT_FRESH, FailureInfo.ADD_RESERVES_FRESH_CHECK), actualAddAmount);
    }

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    /*
     * We call doTransferIn for the caller and the addAmount
     *  Note: The cToken must handle variations between ERC-20 and ETH underlying.
     *  On success, the cToken holds an additional addAmount of cash.
     *  doTransferIn reverts if anything goes wrong, since we can't be sure if side effects occurred.
     *  it returns the amount actually transferred, in case of a fee.
     */

    actualAddAmount = doTransferIn(msg.sender, addAmount);

    totalReservesNew = totalReserves + actualAddAmount;

    /* Revert on overflow */
    require(totalReservesNew >= totalReserves, "add reserves overflow");

    // Store reserves[n+1] = reserves[n] + actualAddAmount
    totalReserves = totalReservesNew;

    /* Emit NewReserves(admin, actualAddAmount, reserves[n+1]) */
    emit ReservesAdded(msg.sender, actualAddAmount, totalReservesNew);

    /* Return (NO_ERROR, actualAddAmount) */
    return (uint256(Error.NO_ERROR), actualAddAmount);
  }

  /**
   * @notice Accrues interest and reduces reserves by transferring to admin
   * @param reduceAmount Amount of reduction to reserves
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _reduceReserves(uint256 reduceAmount) external nonReentrant returns (uint256) {
    uint256 error = accrueInterest();
    if (error != uint256(Error.NO_ERROR)) {
      // accrueInterest emits logs on errors, but on top of that we want to log the fact that an attempted reduce reserves failed.
      return fail(Error(error), FailureInfo.REDUCE_RESERVES_ACCRUE_INTEREST_FAILED);
    }
    // _reduceReservesFresh emits reserve-reduction-specific logs on errors, so we don't need to.
    return _reduceReservesFresh(reduceAmount);
  }

  /**
   * @notice Reduces reserves by transferring to admin
   * @dev Requires fresh interest accrual
   * @param reduceAmount Amount of reduction to reserves
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _reduceReservesFresh(uint256 reduceAmount) internal returns (uint256) {
    // totalReserves - reduceAmount
    uint256 totalReservesNew;

    // Check caller is Reserve Guardian or admin
    if (msg.sender != comptroller.reserveGuardian() && msg.sender != admin) {
      return fail(Error.UNAUTHORIZED, FailureInfo.REDUCE_RESERVES_ADMIN_CHECK);
    }

    // We fail gracefully unless market's block number equals current block number
    if (accrualBlockNumber != getBlockNumber()) {
      return fail(Error.MARKET_NOT_FRESH, FailureInfo.REDUCE_RESERVES_FRESH_CHECK);
    }

    // Fail gracefully if protocol has insufficient underlying cash
    if (getCashPrior() < reduceAmount) {
      return fail(Error.TOKEN_INSUFFICIENT_CASH, FailureInfo.REDUCE_RESERVES_CASH_NOT_AVAILABLE);
    }

    // Check reduceAmount ≤ reserves[n] (totalReserves)
    if (reduceAmount > totalReserves) {
      return fail(Error.BAD_INPUT, FailureInfo.REDUCE_RESERVES_VALIDATION);
    }

    // Make sure reserve guardian was set to avoid transferring reserves to the zero address
    if (comptroller.reserveGuardian() == address(0)) {
      return fail(Error.INVALID_GUARDIAN, FailureInfo.REDUCE_RESERVES_GUARDIAN_NOT_SET);
    }

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    totalReservesNew = totalReserves - reduceAmount;
    // We checked reduceAmount <= totalReserves above, so this should never revert.
    require(totalReservesNew <= totalReserves, "reduce reserves underflow");

    // Store reserves[n+1] = reserves[n] - reduceAmount
    totalReserves = totalReservesNew;

    // doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
    doTransferOut(comptroller.reserveGuardian(), reduceAmount);

    emit ReservesReduced(comptroller.reserveGuardian(), reduceAmount, totalReservesNew);

    return uint256(Error.NO_ERROR);
  }

  /**
   * @notice accrues interest and updates the interest rate model using _setInterestRateModelFresh
   * @dev Admin function to accrue interest and update the interest rate model
   * @param newInterestRateModel the new interest rate model to use
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _setInterestRateModel(InterestRateModel newInterestRateModel) external returns (uint256) {
    uint256 error = accrueInterest();
    if (error != uint256(Error.NO_ERROR)) {
      // accrueInterest emits logs on errors, but on top of that we want to log the fact that an attempted change of interest rate model failed
      return fail(Error(error), FailureInfo.SET_INTEREST_RATE_MODEL_ACCRUE_INTEREST_FAILED);
    }
    // _setInterestRateModelFresh emits interest-rate-model-update-specific logs on errors, so we don't need to.
    return _setInterestRateModelFresh(newInterestRateModel);
  }

  /**
   * @notice updates the interest rate model (*requires fresh interest accrual)
   * @dev Admin function to update the interest rate model
   * @param newInterestRateModel the new interest rate model to use
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _setInterestRateModelFresh(InterestRateModel newInterestRateModel) internal returns (uint256) {
    // Check caller is admin
    if (msg.sender != admin) {
      return fail(Error.UNAUTHORIZED, FailureInfo.SET_INTEREST_RATE_MODEL_OWNER_CHECK);
    }

    // We fail gracefully unless market's block number equals current block number
    if (accrualBlockNumber != getBlockNumber()) {
      return fail(Error.MARKET_NOT_FRESH, FailureInfo.SET_INTEREST_RATE_MODEL_FRESH_CHECK);
    }

    // Ensure invoke newInterestRateModel.isInterestRateModel() returns true
    require(newInterestRateModel.isInterestRateModel(), "marker method returned false");

    // Set the interest rate model to newInterestRateModel
    emit NewMarketInterestRateModel(interestRateModel, newInterestRateModel);
    interestRateModel = newInterestRateModel;

    return uint256(Error.NO_ERROR);
  }

  /*** Safe Token ***/

  /**
   * @notice Gets balance of this contract in terms of the underlying
   * @dev This excludes the value of the current message, if any
   * @return The quantity of underlying owned by this contract
   */
  function getCashPrior() internal view returns (uint256);

  /**
   * @dev Performs a transfer in, reverting upon failure. Returns the amount actually transferred to the protocol, in case of a fee.
   *  This may revert due to insufficient balance or insufficient allowance.
   */
  function doTransferIn(address from, uint256 amount) internal returns (uint256);

  /**
   * @dev Performs a transfer out, ideally returning an explanatory error code upon failure tather than reverting.
   *  If caller has not called checked protocol's balance, may revert due to insufficient cash held in the contract.
   *  If caller has checked protocol's balance, and verified it is >= amount, this should not revert in normal conditions.
   */
  function doTransferOut(address payable to, uint256 amount) internal;

  /*** Reentrancy Guard ***/

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   */
  modifier nonReentrant() {
    require(_notEntered, "re-entered");
    _notEntered = false;
    _;
    _notEntered = true; // get a gas-refund post-Istanbul
  }

  /**
   * @dev Prevents execution of a function if the trigger event has occured
   */
  modifier whenNotTriggered() {
    require(!isTriggered, "Not allowed once triggered");
    _;
  }
}

pragma solidity 0.5.17;

/**
 * @notice Partial implementation of Comptroller interface. The methods listed here are the set used by CTokens
 */
contract ComptrollerInterface {
  /// @notice Indicator that this is a Comptroller contract (for inspection)
  bool public constant isComptroller = true;

  /// @notice Address that CToken reserves are transferred to
  address payable public reserveGuardian;

  /*** Assets You Are In ***/

  function enterMarkets(address[] calldata cTokens) external returns (uint256[] memory);

  function exitMarket(address cToken) external returns (uint256);

  /*** Policy Hooks ***/

  function mintAllowed(
    address cToken,
    address minter,
    uint256 mintAmount
  ) external returns (uint256);

  function redeemAllowed(
    address cToken,
    address redeemer,
    uint256 redeemTokens
  ) external returns (uint256);

  function borrowAllowed(
    address cToken,
    address borrower,
    uint256 borrowAmount
  ) external returns (uint256);

  function repayBorrowAllowed(
    address cToken,
    address payer,
    address borrower,
    uint256 repayAmount
  ) external returns (uint256);

  function liquidateBorrowAllowed(
    address cTokenBorrowed,
    address cTokenCollateral,
    address liquidator,
    address borrower,
    uint256 repayAmount
  ) external returns (uint256);

  function seizeAllowed(
    address cTokenCollateral,
    address cTokenBorrowed,
    address liquidator,
    address borrower,
    uint256 seizeTokens
  ) external returns (uint256);

  function transferAllowed(
    address cToken,
    address src,
    address dst,
    uint256 transferTokens
  ) external returns (uint256);

  /*** Liquidity/Liquidation Calculations ***/

  function liquidateCalculateSeizeTokens(
    address cTokenBorrowed,
    address cTokenCollateral,
    uint256 repayAmount
  ) external view returns (uint256, uint256);

  /*** COZY ***/

  /// @notice Sets supply and borrow COZY subsidies to a market to zero
  function _zeroOutCozySpeeds(address cToken) external;
}

pragma solidity 0.5.17;

import "./ComptrollerInterface.sol";
import "./InterestRateModel.sol";

contract CTokenStorage {
  /**
   * @dev Guard variable for re-entrancy checks
   */
  bool internal _notEntered;

  /**
   * @notice EIP-20 token name for this token
   */
  string public name;

  /**
   * @notice EIP-20 token symbol for this token
   */
  string public symbol;

  /**
   * @notice EIP-20 token decimals for this token
   */
  uint8 public decimals;

  /**
   * @notice Underlying asset for this CToken
   */
  address public underlying;

  /**
   * @notice Maximum borrow rate that can ever be applied (.0005% / block)
   */

  uint256 internal constant borrowRateMaxMantissa = 0.0005e16;

  /**
   * @notice Maximum fraction of interest that can be set aside for reserves
   */
  uint256 internal constant reserveFactorMaxMantissa = 1e18;

  /**
   * @notice Administrator for this contract
   */
  address payable public admin;

  /**
   * @notice Pending administrator for this contract
   */
  address payable public pendingAdmin;

  /**
   * @notice Contract which oversees inter-cToken operations
   */
  ComptrollerInterface public comptroller;

  /**
   * @notice Model which tells what the current interest rate should be
   */
  InterestRateModel public interestRateModel;

  /**
   * @notice Initial exchange rate used when minting the first CTokens (used when totalSupply = 0)
   */
  uint256 internal initialExchangeRateMantissa;

  /**
   * @notice Fraction of interest currently set aside for reserves
   */
  uint256 public reserveFactorMantissa;

  /**
   * @notice Block number that interest was last accrued at
   */
  uint256 public accrualBlockNumber;

  /**
   * @notice Accumulator of the total earned interest rate since the opening of the market
   */
  uint256 public borrowIndex;

  /**
   * @notice Total amount of outstanding borrows of the underlying in this market
   */
  uint256 public totalBorrows;

  /**
   * @notice Total amount of reserves of the underlying held in this market
   */
  uint256 public totalReserves;

  /**
   * @notice Total number of tokens in circulation
   */
  uint256 public totalSupply;

  /**
   * @notice Official record of token balances for each account
   */
  mapping(address => uint256) internal accountTokens;

  /**
   * @notice Approved token transfer amounts on behalf of others
   */
  mapping(address => mapping(address => uint256)) internal transferAllowances;

  /**
   * @notice Container for borrow balance information
   * @member principal Total balance (with accrued interest), after applying the most recent balance-changing action
   * @member interestIndex Global borrowIndex as of the most recent balance-changing action
   */
  struct BorrowSnapshot {
    uint256 principal;
    uint256 interestIndex;
  }

  /**
   * @notice Mapping of account addresses to outstanding borrow balances
   */
  mapping(address => BorrowSnapshot) internal accountBorrows;

  /**
   * @notice Trigger address if token is part of the protection market, zero address otherwise
   */
  address public trigger;

  /**
   * @notice Total number of tokens in circulation at the time the trigger event was activated
   * @dev This variable is not used, but for some reason removing it increases contract size (compiler bug?) so it's kept
   */
  uint256 public totalSupplyWhenTriggered;
}

contract CTokenInterface is CTokenStorage {
  /**
   * @notice Indicator that this is a CToken contract (for inspection)
   */
  bool public constant isCToken = true;

  /**
   * @notice Becomes true when the associated `trigger` contract signals that trigger event has occured
   * @dev This is a one-way toggle: Once set to true it cannot be set back to false
   */
  bool public isTriggered = false;

  /*** Market Events ***/

  /**
   * @notice Event emitted when interest is accrued
   */
  event AccrueInterest(uint256 cashPrior, uint256 interestAccumulated, uint256 borrowIndex, uint256 totalBorrows);

  /**
   * @notice Event emitted when tokens are minted
   */
  event Mint(address minter, uint256 mintAmount, uint256 mintTokens);

  /**
   * @notice Event emitted when tokens are redeemed
   */
  event Redeem(address redeemer, uint256 redeemAmount, uint256 redeemTokens);

  /**
   * @notice Event emitted when underlying is borrowed
   */
  event Borrow(address borrower, uint256 borrowAmount, uint256 accountBorrows, uint256 totalBorrows);

  /**
   * @notice Event emitted when a borrow is repaid
   */
  event RepayBorrow(address payer, address borrower, uint256 repayAmount, uint256 accountBorrows, uint256 totalBorrows);

  /**
   * @notice Event emitted when a borrow is liquidated
   */
  event LiquidateBorrow(
    address liquidator,
    address borrower,
    uint256 repayAmount,
    address cTokenCollateral,
    uint256 seizeTokens
  );

  /*** Admin Events ***/

  /**
   * @notice Event emitted when pendingAdmin is changed
   */
  event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

  /**
   * @notice Event emitted when pendingAdmin is accepted, which means admin is updated
   */
  event NewAdmin(address oldAdmin, address newAdmin);

  /**
   * @notice Event emitted when comptroller is changed
   */
  event NewComptroller(ComptrollerInterface oldComptroller, ComptrollerInterface newComptroller);

  /**
   * @notice Event emitted when interestRateModel is changed
   */
  event NewMarketInterestRateModel(InterestRateModel oldInterestRateModel, InterestRateModel newInterestRateModel);

  /**
   * @notice Event emitted when the reserve factor is changed
   */
  event NewReserveFactor(uint256 oldReserveFactorMantissa, uint256 newReserveFactorMantissa);

  /**
   * @notice Event emitted when the reserves are added
   */
  event ReservesAdded(address benefactor, uint256 addAmount, uint256 newTotalReserves);

  /**
   * @notice Event emitted when the reserves are reduced
   */
  event ReservesReduced(address admin, uint256 reduceAmount, uint256 newTotalReserves);

  /**
   * @notice EIP20 Transfer event
   */
  event Transfer(address indexed from, address indexed to, uint256 amount);

  /**
   * @notice EIP20 Approval event
   */
  event Approval(address indexed owner, address indexed spender, uint256 amount);

  /**
   * @notice Event emitted when trigger status is set
   */
  event TriggerSet(bool isTriggered);

  /**
   * @notice Failure event
   */
  event Failure(uint256 error, uint256 info, uint256 detail);

  /*** User Interface ***/

  function transfer(address dst, uint256 amount) external returns (bool);

  function transferFrom(
    address src,
    address dst,
    uint256 amount
  ) external returns (bool);

  function approve(address spender, uint256 amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function balanceOfUnderlying(address owner) external returns (uint256);

  function getAccountSnapshot(address account)
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256
    );

  function borrowRatePerBlock() external view returns (uint256);

  function supplyRatePerBlock() external view returns (uint256);

  function totalBorrowsCurrent() external returns (uint256);

  function borrowBalanceCurrent(address account) external returns (uint256);

  function borrowBalanceStored(address account) public view returns (uint256);

  function exchangeRateCurrent() public returns (uint256);

  function exchangeRateStored() public view returns (uint256);

  function getCash() external view returns (uint256);

  function accrueInterest() public returns (uint256);

  function seize(
    address liquidator,
    address borrower,
    uint256 seizeTokens
  ) external returns (uint256);

  /*** Admin Functions ***/

  function _setPendingAdmin(address payable newPendingAdmin) external returns (uint256);

  function _acceptAdmin() external returns (uint256);

  function _setReserveFactor(uint256 newReserveFactorMantissa) external returns (uint256);

  function _reduceReserves(uint256 reduceAmount) external returns (uint256);

  function _setInterestRateModel(InterestRateModel newInterestRateModel) external returns (uint256);
}

contract CErc20Storage {}

contract CErc20Interface is CErc20Storage {
  /*** User Interface ***/

  function mint(uint256 mintAmount) external returns (uint256);

  function redeem(uint256 redeemTokens) external returns (uint256);

  function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

  function borrow(uint256 borrowAmount) external returns (uint256);

  function repayBorrow(uint256 repayAmount) external returns (uint256);

  function repayBorrowBehalf(address borrower, uint256 repayAmount) external returns (uint256);

  function liquidateBorrow(
    address borrower,
    uint256 repayAmount,
    CTokenInterface cTokenCollateral
  ) external returns (uint256);

  /*** Admin Functions ***/

  function _addReserves(uint256 addAmount) external returns (uint256);
}

contract CDelegationStorage {
  /**
   * @notice Implementation address for this contract
   */
  address public implementation;
}

contract CDelegatorInterface is CDelegationStorage {
  /**
   * @notice Emitted when implementation is changed
   */
  event NewImplementation(address oldImplementation, address newImplementation);

  /**
   * @notice Called by the admin to update the implementation of the delegator
   * @param implementation_ The address of the new implementation for delegation
   * @param allowResign Flag to indicate whether to call _resignImplementation on the old implementation
   * @param becomeImplementationData The encoded bytes data to be passed to _becomeImplementation
   */
  function _setImplementation(
    address implementation_,
    bool allowResign,
    bytes memory becomeImplementationData
  ) public;
}

contract CDelegateInterface is CDelegationStorage {
  /**
   * @notice Called by the delegator on a delegate to initialize it for duty
   * @dev Should revert if any issues arise which make it unfit for delegation
   * @param data The encoded bytes data for any initialization
   */
  function _becomeImplementation(bytes memory data) public;

  /**
   * @notice Called by the delegator on a delegate to forfeit its responsibility
   */
  function _resignImplementation() public;
}

pragma solidity 0.5.17;

import "./CarefulMath.sol";
import "./ExponentialNoError.sol";

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Compound
 * @dev Legacy contract for compatibility reasons with existing contracts that still use MathError
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract Exponential is CarefulMath, ExponentialNoError {
  /**
   * @dev Creates an exponential from numerator and denominator values.
   *      Note: Returns an error if (`num` * 10e18) > MAX_INT,
   *            or if `denom` is zero.
   */
  function getExp(uint256 num, uint256 denom) internal pure returns (MathError, Exp memory) {
    (MathError err0, uint256 scaledNumerator) = mulUInt(num, expScale);
    if (err0 != MathError.NO_ERROR) {
      return (err0, Exp({mantissa: 0}));
    }

    (MathError err1, uint256 rational) = divUInt(scaledNumerator, denom);
    if (err1 != MathError.NO_ERROR) {
      return (err1, Exp({mantissa: 0}));
    }

    return (MathError.NO_ERROR, Exp({mantissa: rational}));
  }

  /**
   * @dev Adds two exponentials, returning a new exponential.
   */
  function addExp(Exp memory a, Exp memory b) internal pure returns (MathError, Exp memory) {
    (MathError error, uint256 result) = addUInt(a.mantissa, b.mantissa);

    return (error, Exp({mantissa: result}));
  }

  /**
   * @dev Subtracts two exponentials, returning a new exponential.
   */
  function subExp(Exp memory a, Exp memory b) internal pure returns (MathError, Exp memory) {
    (MathError error, uint256 result) = subUInt(a.mantissa, b.mantissa);

    return (error, Exp({mantissa: result}));
  }

  /**
   * @dev Multiply an Exp by a scalar, returning a new Exp.
   */
  function mulScalar(Exp memory a, uint256 scalar) internal pure returns (MathError, Exp memory) {
    (MathError err0, uint256 scaledMantissa) = mulUInt(a.mantissa, scalar);
    if (err0 != MathError.NO_ERROR) {
      return (err0, Exp({mantissa: 0}));
    }

    return (MathError.NO_ERROR, Exp({mantissa: scaledMantissa}));
  }

  /**
   * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
   */
  function mulScalarTruncate(Exp memory a, uint256 scalar) internal pure returns (MathError, uint256) {
    (MathError err, Exp memory product) = mulScalar(a, scalar);
    if (err != MathError.NO_ERROR) {
      return (err, 0);
    }

    return (MathError.NO_ERROR, truncate(product));
  }

  /**
   * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
   */
  function mulScalarTruncateAddUInt(
    Exp memory a,
    uint256 scalar,
    uint256 addend
  ) internal pure returns (MathError, uint256) {
    (MathError err, Exp memory product) = mulScalar(a, scalar);
    if (err != MathError.NO_ERROR) {
      return (err, 0);
    }

    return addUInt(truncate(product), addend);
  }

  /**
   * @dev Divide an Exp by a scalar, returning a new Exp.
   */
  function divScalar(Exp memory a, uint256 scalar) internal pure returns (MathError, Exp memory) {
    (MathError err0, uint256 descaledMantissa) = divUInt(a.mantissa, scalar);
    if (err0 != MathError.NO_ERROR) {
      return (err0, Exp({mantissa: 0}));
    }

    return (MathError.NO_ERROR, Exp({mantissa: descaledMantissa}));
  }

  /**
   * @dev Divide a scalar by an Exp, returning a new Exp.
   */
  function divScalarByExp(uint256 scalar, Exp memory divisor) internal pure returns (MathError, Exp memory) {
    /*
          We are doing this as:
          getExp(mulUInt(expScale, scalar), divisor.mantissa)

          How it works:
          Exp = a / b;
          Scalar = s;
          `s / (a / b)` = `b * s / a` and since for an Exp `a = mantissa, b = expScale`
        */
    (MathError err0, uint256 numerator) = mulUInt(expScale, scalar);
    if (err0 != MathError.NO_ERROR) {
      return (err0, Exp({mantissa: 0}));
    }
    return getExp(numerator, divisor.mantissa);
  }

  /**
   * @dev Divide a scalar by an Exp, then truncate to return an unsigned integer.
   */
  function divScalarByExpTruncate(uint256 scalar, Exp memory divisor) internal pure returns (MathError, uint256) {
    (MathError err, Exp memory fraction) = divScalarByExp(scalar, divisor);
    if (err != MathError.NO_ERROR) {
      return (err, 0);
    }

    return (MathError.NO_ERROR, truncate(fraction));
  }

  /**
   * @dev Multiplies two exponentials, returning a new exponential.
   */
  function mulExp(Exp memory a, Exp memory b) internal pure returns (MathError, Exp memory) {
    (MathError err0, uint256 doubleScaledProduct) = mulUInt(a.mantissa, b.mantissa);
    if (err0 != MathError.NO_ERROR) {
      return (err0, Exp({mantissa: 0}));
    }

    // We add half the scale before dividing so that we get rounding instead of truncation.
    //  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717
    // Without this change, a result like 6.6...e-19 will be truncated to 0 instead of being rounded to 1e-18.
    (MathError err1, uint256 doubleScaledProductWithHalfScale) = addUInt(halfExpScale, doubleScaledProduct);
    if (err1 != MathError.NO_ERROR) {
      return (err1, Exp({mantissa: 0}));
    }

    (MathError err2, uint256 product) = divUInt(doubleScaledProductWithHalfScale, expScale);
    // The only error `div` can return is MathError.DIVISION_BY_ZERO but we control `expScale` and it is not zero.
    assert(err2 == MathError.NO_ERROR);

    return (MathError.NO_ERROR, Exp({mantissa: product}));
  }

  /**
   * @dev Multiplies two exponentials given their mantissas, returning a new exponential.
   */
  function mulExp(uint256 a, uint256 b) internal pure returns (MathError, Exp memory) {
    return mulExp(Exp({mantissa: a}), Exp({mantissa: b}));
  }

  /**
   * @dev Multiplies three exponentials, returning a new exponential.
   */
  function mulExp3(
    Exp memory a,
    Exp memory b,
    Exp memory c
  ) internal pure returns (MathError, Exp memory) {
    (MathError err, Exp memory ab) = mulExp(a, b);
    if (err != MathError.NO_ERROR) {
      return (err, ab);
    }
    return mulExp(ab, c);
  }

  /**
   * @dev Divides two exponentials, returning a new exponential.
   *     (a/scale) / (b/scale) = (a/scale) * (scale/b) = a/b,
   *  which we can scale as an Exp by calling getExp(a.mantissa, b.mantissa)
   */
  function divExp(Exp memory a, Exp memory b) internal pure returns (MathError, Exp memory) {
    return getExp(a.mantissa, b.mantissa);
  }
}

pragma solidity 0.5.17;

/**
 * @title EIP20NonStandardInterface
 * @dev Version of ERC20 with no return values for `transfer` and `transferFrom`
 *  See https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
 */
interface EIP20NonStandardInterface {
  /**
   * @notice Get the total number of tokens in circulation
   * @return The supply of tokens
   */
  function totalSupply() external view returns (uint256);

  /**
   * @notice Gets the balance of the specified address
   * @param owner The address from which the balance will be retrieved
   * @return The balance
   */
  function balanceOf(address owner) external view returns (uint256 balance);

  ///
  /// !!!!!!!!!!!!!!
  /// !!! NOTICE !!! `transfer` does not return a value, in violation of the ERC-20 specification
  /// !!!!!!!!!!!!!!
  ///

  /**
   * @notice Transfer `amount` tokens from `msg.sender` to `dst`
   * @param dst The address of the destination account
   * @param amount The number of tokens to transfer
   */
  function transfer(address dst, uint256 amount) external;

  ///
  /// !!!!!!!!!!!!!!
  /// !!! NOTICE !!! `transferFrom` does not return a value, in violation of the ERC-20 specification
  /// !!!!!!!!!!!!!!
  ///

  /**
   * @notice Transfer `amount` tokens from `src` to `dst`
   * @param src The address of the source account
   * @param dst The address of the destination account
   * @param amount The number of tokens to transfer
   */
  function transferFrom(
    address src,
    address dst,
    uint256 amount
  ) external;

  /**
   * @notice Approve `spender` to transfer up to `amount` from `src`
   * @dev This will overwrite the approval amount for `spender`
   *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
   * @param spender The address of the account which may transfer tokens
   * @param amount The number of tokens that are approved
   * @return Whether or not the approval succeeded
   */
  function approve(address spender, uint256 amount) external returns (bool success);

  /**
   * @notice Get the current allowance from `owner` for `spender`
   * @param owner The address of the account which owns the tokens to be spent
   * @param spender The address of the account which may transfer tokens
   * @return The number of tokens allowed to be spent
   */
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  event Transfer(address indexed from, address indexed to, uint256 amount);
  event Approval(address indexed owner, address indexed spender, uint256 amount);
}

pragma solidity 0.5.17;

/**
 * @title Compound's InterestRateModel Interface
 * @author Compound
 */
contract InterestRateModel {
  /// @notice Indicator that this is an InterestRateModel contract (for inspection)
  bool public constant isInterestRateModel = true;

  /**
   * @notice Calculates the current borrow interest rate per block
   * @param cash The total amount of cash the market has
   * @param borrows The total amount of borrows the market has outstanding
   * @param reserves The total amount of reserves the market has
   * @return The borrow rate per block (as a percentage, and scaled by 1e18)
   */
  function getBorrowRate(
    uint256 cash,
    uint256 borrows,
    uint256 reserves
  ) external view returns (uint256);

  /**
   * @notice Calculates the current supply interest rate per block
   * @param cash The total amount of cash the market has
   * @param borrows The total amount of borrows the market has outstanding
   * @param reserves The total amount of reserves the market has
   * @param reserveFactorMantissa The current reserve factor the market has
   * @return The supply rate per block (as a percentage, and scaled by 1e18)
   */
  function getSupplyRate(
    uint256 cash,
    uint256 borrows,
    uint256 reserves,
    uint256 reserveFactorMantissa
  ) external view returns (uint256);
}

pragma solidity 0.5.17;

/**
 * @title Careful Math
 * @author Compound
 * @notice Derived from OpenZeppelin's SafeMath library
 *         https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol
 */
contract CarefulMath {
  /**
   * @dev Possible error codes that we can return
   */
  enum MathError {NO_ERROR, DIVISION_BY_ZERO, INTEGER_OVERFLOW, INTEGER_UNDERFLOW}

  /**
   * @dev Multiplies two numbers, returns an error on overflow.
   */
  function mulUInt(uint256 a, uint256 b) internal pure returns (MathError, uint256) {
    if (a == 0) {
      return (MathError.NO_ERROR, 0);
    }

    uint256 c = a * b;

    if (c / a != b) {
      return (MathError.INTEGER_OVERFLOW, 0);
    } else {
      return (MathError.NO_ERROR, c);
    }
  }

  /**
   * @dev Integer division of two numbers, truncating the quotient.
   */
  function divUInt(uint256 a, uint256 b) internal pure returns (MathError, uint256) {
    if (b == 0) {
      return (MathError.DIVISION_BY_ZERO, 0);
    }

    return (MathError.NO_ERROR, a / b);
  }

  /**
   * @dev Subtracts two numbers, returns an error on overflow (i.e. if subtrahend is greater than minuend).
   */
  function subUInt(uint256 a, uint256 b) internal pure returns (MathError, uint256) {
    if (b <= a) {
      return (MathError.NO_ERROR, a - b);
    } else {
      return (MathError.INTEGER_UNDERFLOW, 0);
    }
  }

  /**
   * @dev Adds two numbers, returns an error on overflow.
   */
  function addUInt(uint256 a, uint256 b) internal pure returns (MathError, uint256) {
    uint256 c = a + b;

    if (c >= a) {
      return (MathError.NO_ERROR, c);
    } else {
      return (MathError.INTEGER_OVERFLOW, 0);
    }
  }

  /**
   * @dev add a and b and then subtract c
   */
  function addThenSubUInt(
    uint256 a,
    uint256 b,
    uint256 c
  ) internal pure returns (MathError, uint256) {
    (MathError err0, uint256 sum) = addUInt(a, b);

    if (err0 != MathError.NO_ERROR) {
      return (err0, 0);
    }

    return subUInt(sum, c);
  }
}

pragma solidity 0.5.17;

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Compound
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract ExponentialNoError {
  uint256 constant expScale = 1e18;
  uint256 constant doubleScale = 1e36;
  uint256 constant halfExpScale = expScale / 2;
  uint256 constant mantissaOne = expScale;

  struct Exp {
    uint256 mantissa;
  }

  struct Double {
    uint256 mantissa;
  }

  /**
   * @dev Truncates the given exp to a whole number value.
   *      For example, truncate(Exp{mantissa: 15 * expScale}) = 15
   */
  function truncate(Exp memory exp) internal pure returns (uint256) {
    // Note: We are not using careful math here as we're performing a division that cannot fail
    return exp.mantissa / expScale;
  }

  /**
   * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
   */
  function mul_ScalarTruncate(Exp memory a, uint256 scalar) internal pure returns (uint256) {
    Exp memory product = mul_(a, scalar);
    return truncate(product);
  }

  /**
   * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
   */
  function mul_ScalarTruncateAddUInt(
    Exp memory a,
    uint256 scalar,
    uint256 addend
  ) internal pure returns (uint256) {
    Exp memory product = mul_(a, scalar);
    return add_(truncate(product), addend);
  }

  /**
   * @dev Checks if first Exp is less than second Exp.
   */
  function lessThanExp(Exp memory left, Exp memory right) internal pure returns (bool) {
    return left.mantissa < right.mantissa;
  }

  /**
   * @dev Checks if left Exp <= right Exp.
   */
  function lessThanOrEqualExp(Exp memory left, Exp memory right) internal pure returns (bool) {
    return left.mantissa <= right.mantissa;
  }

  /**
   * @dev Checks if left Exp > right Exp.
   */
  function greaterThanExp(Exp memory left, Exp memory right) internal pure returns (bool) {
    return left.mantissa > right.mantissa;
  }

  /**
   * @dev returns true if Exp is exactly zero
   */
  function isZeroExp(Exp memory value) internal pure returns (bool) {
    return value.mantissa == 0;
  }

  function safe224(uint256 n, string memory errorMessage) internal pure returns (uint224) {
    require(n < 2**224, errorMessage);
    return uint224(n);
  }

  function safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
    require(n < 2**32, errorMessage);
    return uint32(n);
  }

  function add_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
    return Exp({mantissa: add_(a.mantissa, b.mantissa)});
  }

  function add_(Double memory a, Double memory b) internal pure returns (Double memory) {
    return Double({mantissa: add_(a.mantissa, b.mantissa)});
  }

  function add_(uint256 a, uint256 b) internal pure returns (uint256) {
    return add_(a, b, "addition overflow");
  }

  function add_(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, errorMessage);
    return c;
  }

  function sub_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
    return Exp({mantissa: sub_(a.mantissa, b.mantissa)});
  }

  function sub_(Double memory a, Double memory b) internal pure returns (Double memory) {
    return Double({mantissa: sub_(a.mantissa, b.mantissa)});
  }

  function sub_(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub_(a, b, "subtraction underflow");
  }

  function sub_(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    return a - b;
  }

  function mul_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
    return Exp({mantissa: mul_(a.mantissa, b.mantissa) / expScale});
  }

  function mul_(Exp memory a, uint256 b) internal pure returns (Exp memory) {
    return Exp({mantissa: mul_(a.mantissa, b)});
  }

  function mul_(uint256 a, Exp memory b) internal pure returns (uint256) {
    return mul_(a, b.mantissa) / expScale;
  }

  function mul_(Double memory a, Double memory b) internal pure returns (Double memory) {
    return Double({mantissa: mul_(a.mantissa, b.mantissa) / doubleScale});
  }

  function mul_(Double memory a, uint256 b) internal pure returns (Double memory) {
    return Double({mantissa: mul_(a.mantissa, b)});
  }

  function mul_(uint256 a, Double memory b) internal pure returns (uint256) {
    return mul_(a, b.mantissa) / doubleScale;
  }

  function mul_(uint256 a, uint256 b) internal pure returns (uint256) {
    return mul_(a, b, "multiplication overflow");
  }

  function mul_(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b, errorMessage);
    return c;
  }

  function div_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
    return Exp({mantissa: div_(mul_(a.mantissa, expScale), b.mantissa)});
  }

  function div_(Exp memory a, uint256 b) internal pure returns (Exp memory) {
    return Exp({mantissa: div_(a.mantissa, b)});
  }

  function div_(uint256 a, Exp memory b) internal pure returns (uint256) {
    return div_(mul_(a, expScale), b.mantissa);
  }

  function div_(Double memory a, Double memory b) internal pure returns (Double memory) {
    return Double({mantissa: div_(mul_(a.mantissa, doubleScale), b.mantissa)});
  }

  function div_(Double memory a, uint256 b) internal pure returns (Double memory) {
    return Double({mantissa: div_(a.mantissa, b)});
  }

  function div_(uint256 a, Double memory b) internal pure returns (uint256) {
    return div_(mul_(a, doubleScale), b.mantissa);
  }

  function div_(uint256 a, uint256 b) internal pure returns (uint256) {
    return div_(a, b, "divide by zero");
  }

  function div_(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    return a / b;
  }

  function fraction(uint256 a, uint256 b) internal pure returns (Double memory) {
    return Double({mantissa: div_(mul_(a, doubleScale), b)});
  }
}

{
  "evmVersion": "istanbul",
  "metadata": {
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 1
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}
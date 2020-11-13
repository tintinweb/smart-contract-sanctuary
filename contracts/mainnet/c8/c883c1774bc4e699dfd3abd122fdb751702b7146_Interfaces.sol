// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;


/**
 * @notice Enums used in `Order` and `Withdrawal` structs
 */
contract Enums {
  enum OrderSelfTradePrevention {
    // Decrement and cancel
    dc,
    // Cancel oldest
    co,
    // Cancel newest
    cn,
    // Cancel both
    cb
  }
  enum OrderSide { Buy, Sell }
  enum OrderTimeInForce {
    // Good until cancelled
    gtc,
    // Good until time
    gtt,
    // Immediate or cancel
    ioc,
    // Fill or kill
    fok
  }
  enum OrderType {
    Market,
    Limit,
    LimitMaker,
    StopLoss,
    StopLossLimit,
    TakeProfit,
    TakeProfitLimit
  }
  enum WithdrawalType { BySymbol, ByAddress }
}


/**
 * @notice Struct definitions
 */
contract Structs {
  /**
   * @notice Argument type for `Exchange.executeTrade` and `Signatures.getOrderWalletHash`
   */
  struct Order {
    // Not currently used but reserved for future use. Must be 1
    uint8 signatureHashVersion;
    // UUIDv1 unique to wallet
    uint128 nonce;
    // Wallet address that placed order and signed hash
    address walletAddress;
    // Type of order
    Enums.OrderType orderType;
    // Order side wallet is on
    Enums.OrderSide side;
    // Order quantity in base or quote asset terms depending on isQuantityInQuote flag
    uint64 quantityInPips;
    // Is quantityInPips in quote terms
    bool isQuantityInQuote;
    // For limit orders, price in decimal pips * 10^8 in quote terms
    uint64 limitPriceInPips;
    // For stop orders, stop loss or take profit price in decimal pips * 10^8 in quote terms
    uint64 stopPriceInPips;
    // Optional custom client order ID
    string clientOrderId;
    // TIF option specified by wallet for order
    Enums.OrderTimeInForce timeInForce;
    // STP behavior specified by wallet for order
    Enums.OrderSelfTradePrevention selfTradePrevention;
    // Cancellation time specified by wallet for GTT TIF order
    uint64 cancelAfter;
    // The ECDSA signature of the order hash as produced by Signatures.getOrderWalletHash
    bytes walletSignature;
  }

  /**
   * @notice Return type for `Exchange.loadAssetBySymbol`, and `Exchange.loadAssetByAddress`; also
   * used internally by `AssetRegistry`
   */
  struct Asset {
    // Flag to distinguish from empty struct
    bool exists;
    // The asset's address
    address assetAddress;
    // The asset's symbol
    string symbol;
    // The asset's decimal precision
    uint8 decimals;
    // Flag set when asset registration confirmed. Asset deposits, trades, or withdrawals only allowed if true
    bool isConfirmed;
    // Timestamp as ms since Unix epoch when isConfirmed was asserted
    uint64 confirmedTimestampInMs;
  }

  /**
   * @notice Argument type for `Exchange.executeTrade` specifying execution parameters for matching orders
   */
  struct Trade {
    // Base asset symbol
    string baseAssetSymbol;
    // Quote asset symbol
    string quoteAssetSymbol;
    // Base asset address
    address baseAssetAddress;
    // Quote asset address
    address quoteAssetAddress;
    // Gross amount including fees of base asset executed
    uint64 grossBaseQuantityInPips;
    // Gross amount including fees of quote asset executed
    uint64 grossQuoteQuantityInPips;
    // Net amount of base asset received by buy side wallet after fees
    uint64 netBaseQuantityInPips;
    // Net amount of quote asset received by sell side wallet after fees
    uint64 netQuoteQuantityInPips;
    // Asset address for liquidity maker's fee
    address makerFeeAssetAddress;
    // Asset address for liquidity taker's fee
    address takerFeeAssetAddress;
    // Fee paid by liquidity maker
    uint64 makerFeeQuantityInPips;
    // Fee paid by liquidity taker
    uint64 takerFeeQuantityInPips;
    // Execution price of trade in decimal pips * 10^8 in quote terms
    uint64 priceInPips;
    // Which side of the order (buy or sell) the liquidity maker was on
    Enums.OrderSide makerSide;
  }

  /**
   * @notice Argument type for `Exchange.withdraw` and `Signatures.getWithdrawalWalletHash`
   */
  struct Withdrawal {
    // Distinguishes between withdrawals by asset symbol or address
    Enums.WithdrawalType withdrawalType;
    // UUIDv1 unique to wallet
    uint128 nonce;
    // Address of wallet to which funds will be returned
    address payable walletAddress;
    // Asset symbol
    string assetSymbol;
    // Asset address
    address assetAddress; // Used when assetSymbol not specified
    // Withdrawal quantity
    uint64 quantityInPips;
    // Gas fee deducted from withdrawn quantity to cover dispatcher tx costs
    uint64 gasFeeInPips;
    // Not currently used but reserved for future use. Must be true
    bool autoDispatchEnabled;
    // The ECDSA signature of the withdrawal hash as produced by Signatures.getWithdrawalWalletHash
    bytes walletSignature;
  }
}


/**
 * @notice Interface of the ERC20 standard as defined in the EIP, but with no return values for
 * transfer and transferFrom. By asserting expected balance changes when calling these two methods
 * we can safely ignore their return values. This allows support of non-compliant tokens that do not
 * return a boolean. See https://github.com/ethereum/solidity/issues/4116
 */
interface IERC20 {
  /**
   * @notice Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @notice Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @notice Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Most implementing contracts return a boolean value indicating whether the operation succeeded, but
   * we ignore this and rely on asserting balance changes instead
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external;

  /**
   * @notice Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  /**
   * @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
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
   * @notice Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Most implementing contracts return a boolean value indicating whether the operation succeeded, but
   * we ignore this and rely on asserting balance changes instead
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external;

  /**
   * @notice Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @notice Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @notice Interface to Custodian contract. Used by Exchange and Governance contracts for internal
 * delegate calls
 */
interface ICustodian {
  /**
   * @notice ETH can only be sent by the Exchange
   */
  receive() external payable;

  /**
   * @notice Withdraw any asset and amount to a target wallet
   *
   * @dev No balance checking performed
   *
   * @param wallet The wallet to which assets will be returned
   * @param asset The address of the asset to withdraw (ETH or ERC-20 contract)
   * @param quantityInAssetUnits The quantity in asset units to withdraw
   */
  function withdraw(
    address payable wallet,
    address asset,
    uint256 quantityInAssetUnits
  ) external;

  /**
   * @notice Load address of the currently whitelisted Exchange contract
   *
   * @return The address of the currently whitelisted Exchange contract
   */
  function loadExchange() external view returns (address);

  /**
   * @notice Sets a new Exchange contract address
   *
   * @param newExchange The address of the new whitelisted Exchange contract
   */
  function setExchange(address newExchange) external;

  /**
   * @notice Load address of the currently whitelisted Governance contract
   *
   * @return The address of the currently whitelisted Governance contract
   */
  function loadGovernance() external view returns (address);

  /**
   * @notice Sets a new Governance contract address
   *
   * @param newGovernance The address of the new whitelisted Governance contract
   */
  function setGovernance(address newGovernance) external;
}


/**
 * @notice Interface to Exchange contract. Provided only to document struct usage
 */
interface IExchange {
  /**
   * @notice Settles a trade between two orders submitted and matched off-chain
   *
   * @param buy A `Structs.Order` struct encoding the parameters of the buy-side order (receiving base, giving quote)
   * @param sell A `Structs.Order` struct encoding the parameters of the sell-side order (giving base, receiving quote)
   * @param trade A `Structs.Trade` struct encoding the parameters of this trade execution of the counterparty orders
   */
  function executeTrade(
    Structs.Order calldata buy,
    Structs.Order calldata sell,
    Structs.Trade calldata trade
  ) external;

  /**
   * @notice Settles a user withdrawal submitted off-chain. Calls restricted to currently whitelisted Dispatcher wallet
   *
   * @param withdrawal A `Structs.Withdrawal` struct encoding the parameters of the withdrawal
   */
  function withdraw(Structs.Withdrawal calldata withdrawal) external;
}

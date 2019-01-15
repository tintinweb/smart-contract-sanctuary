pragma solidity ^0.4.24;

/**
 * @title Log Various Error Types
 * @author Adam Lemmon <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="c0a1a4a1ad80afb2a1a3aca9baa5eea9b4">[email&#160;protected]</a>>
 * @dev Inherit this contract and your may now log errors easily
 * To support various error types, params, etc.
 */
contract LoggingErrors {
  /**
  * Events
  */
  event LogErrorString(string errorString);

  /**
  * Error cases
  */

  /**
   * @dev Default error to simply log the error message and return
   * @param _errorMessage The error message to log
   * @return ALWAYS false
   */
  function error(string _errorMessage) internal returns(bool) {
    LogErrorString(_errorMessage);
    return false;
  }
}

/**
 * @title Wallet Connector
 * @dev Connect the wallet contract to the correct Wallet Logic version
 */
contract WalletConnector is LoggingErrors {
  /**
   * Storage
   */
  address public owner_;
  address public latestLogic_;
  uint256 public latestVersion_;
  mapping(uint256 => address) public logicVersions_;
  uint256 public birthBlock_;

  /**
   * Events
   */
  event LogLogicVersionAdded(uint256 version);
  event LogLogicVersionRemoved(uint256 version);

  /**
   * @dev Constructor to set the latest logic address
   * @param _latestVersion Latest version of the wallet logic
   * @param _latestLogic Latest address of the wallet logic contract
   */
  function WalletConnector (
    uint256 _latestVersion,
    address _latestLogic
  ) public {
    owner_ = msg.sender;
    latestLogic_ = _latestLogic;
    latestVersion_ = _latestVersion;
    logicVersions_[_latestVersion] = _latestLogic;
    birthBlock_ = block.number;
  }

  /**
   * Add a new version of the logic contract
   * @param _version The version to be associated with the new contract.
   * @param _logic New logic contract.
   * @return Success of the transaction.
   */
  function addLogicVersion (
    uint256 _version,
    address _logic
  ) external
    returns(bool)
  {
    if (msg.sender != owner_)
      return error(&#39;msg.sender != owner, WalletConnector.addLogicVersion()&#39;);

    if (logicVersions_[_version] != 0)
      return error(&#39;Version already exists, WalletConnector.addLogicVersion()&#39;);

    // Update latest if this is the latest version
    if (_version > latestVersion_) {
      latestLogic_ = _logic;
      latestVersion_ = _version;
    }

    logicVersions_[_version] = _logic;
    LogLogicVersionAdded(_version);

    return true;
  }

  /**
   * @dev Remove a version. Cannot remove the latest version.
   * @param  _version The version to remove.
   */
  function removeLogicVersion(uint256 _version) external {
    require(msg.sender == owner_);
    require(_version != latestVersion_);
    delete logicVersions_[_version];
    LogLogicVersionRemoved(_version);
  }

  /**
   * Constants
   */

  /**
   * Called from user wallets in order to upgrade their logic.
   * @param _version The version to upgrade to. NOTE pass in 0 to upgrade to latest.
   * @return The address of the logic contract to upgrade to.
   */
  function getLogic(uint256 _version)
    external
    constant
    returns(address)
  {
    if (_version == 0)
      return latestLogic_;
    else
      return logicVersions_[_version];
  }
}

/**
 * @title Wallet to hold and trade ERC20 tokens and ether
 * @author Adam Lemmon <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="95f4f1f4f8d5fae7f4f6f9fceff0bbfce1">[email&#160;protected]</a>>
 * @dev User wallet to interact with the exchange.
 * all tokens and ether held in this wallet, 1 to 1 mapping to user EOAs.
 */
contract WalletV2 is LoggingErrors {
  /**
   * Storage
   */
  // Vars included in wallet logic "lib", the order must match between Wallet and Logic
  address public owner_;
  address public exchange_;
  mapping(address => uint256) public tokenBalances_;

  address public logic_; // storage location 0x3 loaded for delegatecalls so this var must remain at index 3
  uint256 public birthBlock_;

  WalletConnector private connector_;

  /**
   * Events
   */
  event LogDeposit(address token, uint256 amount, uint256 balance);
  event LogWithdrawal(address token, uint256 amount, uint256 balance);

  /**
   * @dev Contract constructor. Set user as owner and connector address.
   * @param _owner The address of the user&#39;s EOA, wallets created from the exchange
   * so must past in the owner address, msg.sender == exchange.
   * @param _connector The wallet connector to be used to retrieve the wallet logic
   */
  function WalletV2(address _owner, address _connector) public {
    owner_ = _owner;
    connector_ = WalletConnector(_connector);
    exchange_ = msg.sender;
    logic_ = connector_.latestLogic_();
    birthBlock_ = block.number;
  }

  /**
   * @dev Fallback - Only enable funds to be sent from the exchange.
   * Ensures balances will be consistent.
   */
  function () external payable {
    require(msg.sender == exchange_);
  }

  /**
  * External
  */

  /**
   * @dev Deposit ether into this wallet, default to address 0 for consistent token lookup.
   */
  function depositEther()
    external
    payable
  {
    require(logic_.delegatecall(bytes4(sha3(&#39;deposit(address,uint256)&#39;)), 0, msg.value));
  }

  /**
   * @dev Deposit any ERC20 token into this wallet.
   * @param _token The address of the existing token contract.
   * @param _amount The amount of tokens to deposit.
   * @return Bool if the deposit was successful.
   */
  function depositERC20Token (
    address _token,
    uint256 _amount
  ) external
    returns(bool)
  {
    // ether
    if (_token == 0)
      return error(&#39;Cannot deposit ether via depositERC20, Wallet.depositERC20Token()&#39;);

    require(logic_.delegatecall(bytes4(sha3(&#39;deposit(address,uint256)&#39;)), _token, _amount));
    return true;
  }

  /**
   * @dev The result of an order, update the balance of this wallet.
   * @param _token The address of the token balance to update.
   * @param _amount The amount to update the balance by.
   * @param _subtractionFlag If true then subtract the token amount else add.
   * @return Bool if the update was successful.
   */
  function updateBalance (
    address _token,
    uint256 _amount,
    bool _subtractionFlag
  ) external
    returns(bool)
  {
    assembly {
      calldatacopy(0x40, 0, calldatasize)
      delegatecall(gas, sload(0x3), 0x40, calldatasize, 0, 32)
      return(0, 32)
      pop
    }
  }

  /**
   * User may update to the latest version of the exchange contract.
   * Note that multiple versions are NOT supported at this time and therefore if a
   * user does not wish to update they will no longer be able to use the exchange.
   * @param _exchange The new exchange.
   * @return Success of this transaction.
   */
  function updateExchange(address _exchange)
    external
    returns(bool)
  {
    if (msg.sender != owner_)
      return error(&#39;msg.sender != owner_, Wallet.updateExchange()&#39;);

    // If subsequent messages are not sent from this address all orders will fail
    exchange_ = _exchange;

    return true;
  }

  /**
   * User may update to a new or older version of the logic contract.
   * @param _version The versin to update to.
   * @return Success of this transaction.
   */
  function updateLogic(uint256 _version)
    external
    returns(bool)
  {
    if (msg.sender != owner_)
      return error(&#39;msg.sender != owner_, Wallet.updateLogic()&#39;);

    address newVersion = connector_.getLogic(_version);

    // Invalid version as defined by connector
    if (newVersion == 0)
      return error(&#39;Invalid version, Wallet.updateLogic()&#39;);

    logic_ = newVersion;
    return true;
  }

  /**
   * @dev Verify an order that the Exchange has received involving this wallet.
   * Internal checks and then authorize the exchange to move the tokens.
   * If sending ether will transfer to the exchange to broker the trade.
   * @param _token The address of the token contract being sold.
   * @param _amount The amount of tokens the order is for.
   * @param _fee The fee for the current trade.
   * @param _feeToken The token of which the fee is to be paid in.
   * @return If the order was verified or not.
   */
  function verifyOrder (
    address _token,
    uint256 _amount,
    uint256 _fee,
    address _feeToken
  ) external
    returns(bool)
  {
    assembly {
      calldatacopy(0x40, 0, calldatasize)
      delegatecall(gas, sload(0x3), 0x40, calldatasize, 0, 32)
      return(0, 32)
      pop
    }
  }

  /**
   * @dev Withdraw any token, including ether from this wallet to an EOA.
   * @param _token The address of the token to withdraw.
   * @param _amount The amount to withdraw.
   * @return Success of the withdrawal.
   */
  function withdraw(address _token, uint256 _amount)
    external
    returns(bool)
  {
    if(msg.sender != owner_)
      return error(&#39;msg.sender != owner, Wallet.withdraw()&#39;);

    assembly {
      calldatacopy(0x40, 0, calldatasize)
      delegatecall(gas, sload(0x3), 0x40, calldatasize, 0, 32)
      return(0, 32)
      pop
    }
  }

  /**
   * Constants
   */

  /**
   * @dev Get the balance for a specific token.
   * @param _token The address of the token contract to retrieve the balance of.
   * @return The current balance within this contract.
   */
  function balanceOf(address _token)
    public
    view
    returns(uint)
  {
    return tokenBalances_[_token];
  }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Token {
  /// @return total amount of tokens
  function totalSupply() constant returns (uint256 supply) {}

  /// @param _owner The address from which the balance will be retrieved
  /// @return The balance
  function balanceOf(address _owner) constant returns (uint256 balance) {}

  /// @notice send `_value` token to `_to` from `msg.sender`
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transfer(address _to, uint256 _value) returns (bool success) {}

  /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
  /// @param _from The address of the sender
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

  /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @param _value The amount of wei to be approved for transfer
  /// @return Whether the approval was successful or not
  function approve(address _spender, uint256 _value) returns (bool success) {}

  /// @param _owner The address of the account owning tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @return Amount of remaining tokens allowed to spent
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  uint public decimals;
  string public name;
}

interface ExchangeV1 {
  function userAccountToWallet_(address) external returns(address);
}

interface BadERC20 {
  function transfer(address to, uint value) external;
  function transferFrom(address from, address to, uint256 value) external;
}

/**
 * @title Decentralized exchange for ether and ERC20 tokens.
 * @author Eidoo SAGL.
 * @dev All trades brokered by this contract.
 * Orders submitted by off chain order book and this contract handles
 * verification and execution of orders.
 * All value between parties is transferred via this exchange.
 * Methods arranged by visibility; external, public, internal, private and alphabatized within.
 *
 * New Exchange SC with eventually no fee and ERC20 tokens as quote
 */
contract ExchangeV2 is LoggingErrors {

  using SafeMath for uint256;

  /**
   * Data Structures
   */
  struct Order {
    address offerToken_;
    uint256 offerTokenTotal_;
    uint256 offerTokenRemaining_;  // Amount left to give
    address wantToken_;
    uint256 wantTokenTotal_;
    uint256 wantTokenReceived_;  // Amount received, note this may exceed want total
  }

  struct OrderStatus {
    uint256 expirationBlock_;
    uint256 wantTokenReceived_;    // Amount received, note this may exceed want total
    uint256 offerTokenRemaining_;  // Amount left to give
  }

  /**
   * Storage
   */
  address public previousExchangeAddress_;
  address private orderBookAccount_;
  address public owner_;
  uint256 public birthBlock_;
  address public edoToken_;
  address public walletConnector;

  mapping (address => uint256) public feeEdoPerQuote;
  mapping (address => uint256) public feeEdoPerQuoteDecimals;

  address public eidooWallet_;

  // Define if fee calculation must be skipped for a given trade. By default (false) fee must not be skipped.
  mapping(address => mapping(address => bool)) public mustSkipFee;

  /**
   * @dev Define in a trade who is the quote using a priority system:
   * values example
   *   0: not used as quote
   *  >0: used as quote
   *  if wanted and offered tokens have value > 0 the quote is the token with the bigger value
   */
  mapping(address => uint256) public quotePriority;

  mapping(bytes32 => OrderStatus) public orders_; // Map order hashes to order data struct
  mapping(address => address) public userAccountToWallet_; // User EOA to wallet addresses

  /**
   * Events
   */
  event LogFeeRateSet(address indexed token, uint256 rate, uint256 decimals);
  event LogQuotePrioritySet(address indexed quoteToken, uint256 priority);
  event LogMustSkipFeeSet(address indexed base, address indexed quote, bool mustSkipFee);
  event LogUserAdded(address indexed user, address walletAddress);
  event LogWalletDeposit(address indexed walletAddress, address token, uint256 amount, uint256 balance);
  event LogWalletWithdrawal(address indexed walletAddress, address token, uint256 amount, uint256 balance);

  event LogOrderExecutionSuccess(
    bytes32 indexed makerOrderId,
    bytes32 indexed takerOrderId,
    uint256 toMaker,
    uint256 toTaker
  );
  event LogOrderFilled(bytes32 indexed orderId, uint256 totalOfferRemaining, uint256 totalWantReceived);

  /**
   * @dev Contract constructor - CONFIRM matches contract name.  Set owner and addr of order book.
   * @param _bookAccount The EOA address for the order book, will submit ALL orders.
   * @param _edoToken Deployed edo token.
   * @param _edoPerWei Rate of edo tokens per wei.
   * @param _edoPerWeiDecimals Decimlas carried in edo rate.
   * @param _eidooWallet Wallet to pay fees to.
   * @param _previousExchangeAddress Previous exchange smart contract address.
   */
  constructor (
    address _bookAccount,
    address _edoToken,
    uint256 _edoPerWei,
    uint256 _edoPerWeiDecimals,
    address _eidooWallet,
    address _previousExchangeAddress,
    address _walletConnector
  ) public {
    orderBookAccount_ = _bookAccount;
    owner_ = msg.sender;
    birthBlock_ = block.number;
    edoToken_ = _edoToken;
    feeEdoPerQuote[address(0)] = _edoPerWei;
    feeEdoPerQuoteDecimals[address(0)] = _edoPerWeiDecimals;
    eidooWallet_ = _eidooWallet;
    quotePriority[address(0)] = 10;
    previousExchangeAddress_ = _previousExchangeAddress;
    require(_walletConnector != address (0), "WalletConnector address == 0");
    walletConnector = _walletConnector;
  }

  /**
   * @dev Fallback. wallets utilize to send ether in order to broker trade.
   */
  function () external payable { }

  /**
   * External
   */

  /**
   * @dev Returns the Wallet contract address associated to a user account. If the user account is not known, try to
   * migrate the wallet address from the old exchange instance. This function is equivalent to getWallet(), in addition
   * it stores the wallet address fetched from old the exchange instance.
   * @param userAccount The user account address
   * @return The address of the Wallet instance associated to the user account
   */
  function retrieveWallet(address userAccount)
    public
    returns(address walletAddress)
  {
    walletAddress = userAccountToWallet_[userAccount];
    if (walletAddress == address(0) && previousExchangeAddress_ != 0) {
      // Retrieve the wallet address from the old exchange.
      walletAddress = ExchangeV1(previousExchangeAddress_).userAccountToWallet_(userAccount);
      // TODO: in the future versions of the exchange the above line must be replaced with the following one
      //walletAddress = ExchangeV2(previousExchangeAddress_).retrieveWallet(userAccount);

      if (walletAddress != address(0)) {
        userAccountToWallet_[userAccount] = walletAddress;
      }
    }
  }

  /**
   * @dev Add a new user to the exchange, create a wallet for them.
   * Map their account address to the wallet contract for lookup.
   * @param userExternalOwnedAccount The address of the user"s EOA.
   * @return Success of the transaction, false if error condition met.
   */
  function addNewUser(address userExternalOwnedAccount)
    public
    returns (bool)
  {
    if (retrieveWallet(userExternalOwnedAccount) != address(0)) {
      return error("User already exists, Exchange.addNewUser()");
    }

    // Pass the userAccount address to wallet constructor so owner is not the exchange contract
    address userTradingWallet = new WalletV2(userExternalOwnedAccount, walletConnector);
    userAccountToWallet_[userExternalOwnedAccount] = userTradingWallet;
    emit LogUserAdded(userExternalOwnedAccount, userTradingWallet);
    return true;
  }

  /**
   * Execute orders in batches.
   * @param ownedExternalAddressesAndTokenAddresses Tokan and user addresses.
   * @param amountsExpirationsAndSalts Offer and want token amount and expiration and salt values.
   * @param vSignatures All order signature v values.
   * @param rAndSsignatures All order signature r and r values.
   * @return The success of this transaction.
   */
  function batchExecuteOrder(
    address[4][] ownedExternalAddressesAndTokenAddresses,
    uint256[8][] amountsExpirationsAndSalts, // Packing to save stack size
    uint8[2][] vSignatures,
    bytes32[4][] rAndSsignatures
  ) external
    returns(bool)
  {
    for (uint256 i = 0; i < amountsExpirationsAndSalts.length; i++) {
      require(
        executeOrder(
          ownedExternalAddressesAndTokenAddresses[i],
          amountsExpirationsAndSalts[i],
          vSignatures[i],
          rAndSsignatures[i]
        ),
        "Cannot execute order, Exchange.batchExecuteOrder()"
      );
    }

    return true;
  }

  /**
   * @dev Execute an order that was submitted by the external order book server.
   * The order book server believes it to be a match.
   * There are components for both orders, maker and taker, 2 signatures as well.
   * @param ownedExternalAddressesAndTokenAddresses The maker and taker external owned accounts addresses and offered tokens contracts.
   * [
   *   makerEOA
   *   makerOfferToken
   *   takerEOA
   *   takerOfferToken
   * ]
   * @param amountsExpirationsAndSalts The amount of tokens and the block number at which this order expires and a random number to mitigate replay.
   * [
   *   makerOffer
   *   makerWant
   *   takerOffer
   *   takerWant
   *   makerExpiry
   *   makerSalt
   *   takerExpiry
   *   takerSalt
   * ]
   * @param vSignatures ECDSA signature parameter.
   * [
   *   maker V
   *   taker V
   * ]
   * @param rAndSsignatures ECDSA signature parameters r ans s, maker 0, 1 and taker 2, 3.
   * [
   *   maker R
   *   maker S
   *   taker R
   *   taker S
   * ]
   * @return Success of the transaction, false if error condition met.
   * Like types grouped to eliminate stack depth error.
   */
  function executeOrder (
    address[4] ownedExternalAddressesAndTokenAddresses,
    uint256[8] amountsExpirationsAndSalts, // Packing to save stack size
    uint8[2] vSignatures,
    bytes32[4] rAndSsignatures
  ) public
    returns(bool)
  {
    // Only read wallet addresses from storage once
    // Need one more stack slot so squashing into array
    WalletV2[2] memory makerAndTakerTradingWallets = [
      WalletV2(retrieveWallet(ownedExternalAddressesAndTokenAddresses[0])), // maker
      WalletV2(retrieveWallet(ownedExternalAddressesAndTokenAddresses[2])) // taker
    ];

    // Basic pre-conditions, return if any input data is invalid
    if(!__executeOrderInputIsValid__(
      ownedExternalAddressesAndTokenAddresses,
      amountsExpirationsAndSalts,
      makerAndTakerTradingWallets[0], // maker
      makerAndTakerTradingWallets[1] // taker
    )) {
      return error("Input is invalid, Exchange.executeOrder()");
    }

    // Verify Maker and Taker signatures
    bytes32[2] memory makerAndTakerOrderHash = generateOrderHashes(
      ownedExternalAddressesAndTokenAddresses,
      amountsExpirationsAndSalts
    );

    // Check maker order signature
    if (!__signatureIsValid__(
      ownedExternalAddressesAndTokenAddresses[0],
      makerAndTakerOrderHash[0],
      vSignatures[0],
      rAndSsignatures[0],
      rAndSsignatures[1]
    )) {
      return error("Maker signature is invalid, Exchange.executeOrder()");
    }

    // Check taker order signature
    if (!__signatureIsValid__(
      ownedExternalAddressesAndTokenAddresses[2],
      makerAndTakerOrderHash[1],
      vSignatures[1],
      rAndSsignatures[2],
      rAndSsignatures[3]
    )) {
      return error("Taker signature is invalid, Exchange.executeOrder()");
    }

    // Exchange Order Verification and matching
    OrderStatus memory makerOrderStatus = orders_[makerAndTakerOrderHash[0]];
    OrderStatus memory takerOrderStatus = orders_[makerAndTakerOrderHash[1]];
    Order memory makerOrder;
    Order memory takerOrder;

    makerOrder.offerToken_ = ownedExternalAddressesAndTokenAddresses[1];
    makerOrder.offerTokenTotal_ = amountsExpirationsAndSalts[0];
    makerOrder.wantToken_ = ownedExternalAddressesAndTokenAddresses[3];
    makerOrder.wantTokenTotal_ = amountsExpirationsAndSalts[1];

    if (makerOrderStatus.expirationBlock_ > 0) {  // Check for existence
      // Orders still active
      if (makerOrderStatus.offerTokenRemaining_ == 0) {
        return error("Maker order is inactive, Exchange.executeOrder()");
      }
      makerOrder.offerTokenRemaining_ = makerOrderStatus.offerTokenRemaining_; // Amount to give
      makerOrder.wantTokenReceived_ = makerOrderStatus.wantTokenReceived_; // Amount received
    } else {
      makerOrder.offerTokenRemaining_ = amountsExpirationsAndSalts[0]; // Amount to give
      makerOrder.wantTokenReceived_ = 0; // Amount received
      makerOrderStatus.expirationBlock_ = amountsExpirationsAndSalts[4]; // maker order expiration block
    }

    takerOrder.offerToken_ = ownedExternalAddressesAndTokenAddresses[3];
    takerOrder.offerTokenTotal_ = amountsExpirationsAndSalts[2];
    takerOrder.wantToken_ = ownedExternalAddressesAndTokenAddresses[1];
    takerOrder.wantTokenTotal_ = amountsExpirationsAndSalts[3];

    if (takerOrderStatus.expirationBlock_ > 0) {  // Check for existence
      if (takerOrderStatus.offerTokenRemaining_ == 0) {
        return error("Taker order is inactive, Exchange.executeOrder()");
      }
      takerOrder.offerTokenRemaining_ = takerOrderStatus.offerTokenRemaining_;  // Amount to give
      takerOrder.wantTokenReceived_ = takerOrderStatus.wantTokenReceived_; // Amount received

    } else {
      takerOrder.offerTokenRemaining_ = amountsExpirationsAndSalts[2];  // Amount to give
      takerOrder.wantTokenReceived_ = 0; // Amount received
      takerOrderStatus.expirationBlock_ = amountsExpirationsAndSalts[6]; // taker order expiration block
    }

    // Check if orders are matching and are valid
    if (!__ordersMatch_and_AreVaild__(makerOrder, takerOrder)) {
      return error("Orders do not match, Exchange.executeOrder()");
    }

    // Trade amounts
    // [0] => toTakerAmount
    // [1] => toMakerAmount
    uint[2] memory toTakerAndToMakerAmount;
    toTakerAndToMakerAmount = __getTradeAmounts__(makerOrder, takerOrder);

    // TODO consider removing. Can this condition be met?
    if (toTakerAndToMakerAmount[0] < 1 || toTakerAndToMakerAmount[1] < 1) {
      return error("Token amount < 1, price ratio is invalid! Token value < 1, Exchange.executeOrder()");
    }

    uint calculatedFee = __calculateFee__(makerOrder, toTakerAndToMakerAmount[0], toTakerAndToMakerAmount[1]);

    // Check taker has sufficent EDO token balance to pay the fee
    if (
      takerOrder.offerToken_ == edoToken_ &&
      Token(edoToken_).balanceOf(makerAndTakerTradingWallets[1]) < calculatedFee.add(toTakerAndToMakerAmount[1])
    ) {
      return error("Taker has an insufficient EDO token balance to cover the fee AND the offer, Exchange.executeOrder()");
    } else if (Token(edoToken_).balanceOf(makerAndTakerTradingWallets[1]) < calculatedFee) {
      return error("Taker has an insufficient EDO token balance to cover the fee, Exchange.executeOrder()");
    }

    // Wallet Order Verification, reach out to the maker and taker wallets.
    if (
      !__ordersVerifiedByWallets__(
        ownedExternalAddressesAndTokenAddresses,
        toTakerAndToMakerAmount[1],
        toTakerAndToMakerAmount[0],
        makerAndTakerTradingWallets[0],
        makerAndTakerTradingWallets[1],
        calculatedFee
    )) {
      return error("Order could not be verified by wallets, Exchange.executeOrder()");
    }

    // Write to storage then external calls
    makerOrderStatus.offerTokenRemaining_ = makerOrder.offerTokenRemaining_.sub(toTakerAndToMakerAmount[0]);
    makerOrderStatus.wantTokenReceived_ = makerOrder.wantTokenReceived_.add(toTakerAndToMakerAmount[1]);

    takerOrderStatus.offerTokenRemaining_ = takerOrder.offerTokenRemaining_.sub(toTakerAndToMakerAmount[1]);
    takerOrderStatus.wantTokenReceived_ = takerOrder.wantTokenReceived_.add(toTakerAndToMakerAmount[0]);

    // Finally write orders to storage
    orders_[makerAndTakerOrderHash[0]] = makerOrderStatus;
    orders_[makerAndTakerOrderHash[1]] = takerOrderStatus;

    // Transfer the external value, ether <> tokens
    require(
      __executeTokenTransfer__(
        ownedExternalAddressesAndTokenAddresses,
        toTakerAndToMakerAmount[0],
        toTakerAndToMakerAmount[1],
        calculatedFee,
        makerAndTakerTradingWallets[0],
        makerAndTakerTradingWallets[1]
      ),
      "Cannot execute token transfer, Exchange.__executeTokenTransfer__()"
    );

    // Log the order id(hash), amount of offer given, amount of offer remaining
    emit LogOrderFilled(makerAndTakerOrderHash[0], makerOrderStatus.offerTokenRemaining_, makerOrderStatus.wantTokenReceived_);
    emit LogOrderFilled(makerAndTakerOrderHash[1], takerOrderStatus.offerTokenRemaining_, takerOrderStatus.wantTokenReceived_);
    emit LogOrderExecutionSuccess(makerAndTakerOrderHash[0], makerAndTakerOrderHash[1], toTakerAndToMakerAmount[1], toTakerAndToMakerAmount[0]);

    return true;
  }

  /**
   * @dev Set the fee rate for a specific quote
   * @param _quoteToken Quote token.
   * @param _edoPerQuote EdoPerQuote.
   * @param _edoPerQuoteDecimals EdoPerQuoteDecimals.
   * @return Success of the transaction.
   */
  function setFeeRate(
    address _quoteToken,
    uint256 _edoPerQuote,
    uint256 _edoPerQuoteDecimals
  ) external
    returns(bool)
  {
    if (msg.sender != owner_) {
      return error("msg.sender != owner, Exchange.setFeeRate()");
    }

    if (quotePriority[_quoteToken] == 0) {
      return error("quotePriority[_quoteToken] == 0, Exchange.setFeeRate()");
    }

    feeEdoPerQuote[_quoteToken] = _edoPerQuote;
    feeEdoPerQuoteDecimals[_quoteToken] = _edoPerQuoteDecimals;

    emit LogFeeRateSet(_quoteToken, _edoPerQuote, _edoPerQuoteDecimals);

    return true;
  }

  /**
   * @dev Set the wallet for fees to be paid to.
   * @param eidooWallet Wallet to pay fees to.
   * @return Success of the transaction.
   */
  function setEidooWallet(
    address eidooWallet
  ) external
    returns(bool)
  {
    if (msg.sender != owner_) {
      return error("msg.sender != owner, Exchange.setEidooWallet()");
    }
    eidooWallet_ = eidooWallet;
    return true;
  }

  /**
   * @dev Set a new order book account.
   * @param account The new order book account.
   */
  function setOrderBookAcount (
    address account
  ) external
    returns(bool)
  {
    if (msg.sender != owner_) {
      return error("msg.sender != owner, Exchange.setOrderBookAcount()");
    }
    orderBookAccount_ = account;
    return true;
  }

  /**
   * @dev Set if a base must skip fee calculation.
   * @param _baseTokenAddress The trade base token address that must skip fee calculation.
   * @param _quoteTokenAddress The trade quote token address that must skip fee calculation.
   * @param _mustSkipFee The trade base token address that must skip fee calculation.
   */
  function setMustSkipFee (
    address _baseTokenAddress,
    address _quoteTokenAddress,
    bool _mustSkipFee
  ) external
    returns(bool)
  {
    // Preserving same owner check style
    if (msg.sender != owner_) {
      return error("msg.sender != owner, Exchange.setMustSkipFee()");
    }
    mustSkipFee[_baseTokenAddress][_quoteTokenAddress] = _mustSkipFee;
    emit LogMustSkipFeeSet(_baseTokenAddress, _quoteTokenAddress, _mustSkipFee);
    return true;
  }

  /**
   * @dev Set quote priority token.
   * Set the sorting of token quote based on a priority.
   * @param _token The address of the token that was deposited.
   * @param _priority The amount of the token that was deposited.
   * @return Operation success.
   */

  function setQuotePriority(address _token, uint256 _priority)
    external
    returns(bool)
  {
    if (msg.sender != owner_) {
      return error("msg.sender != owner, Exchange.setQuotePriority()");
    }
    quotePriority[_token] = _priority;
    emit LogQuotePrioritySet(_token, _priority);
    return true;
  }

  /*
   Methods to catch events from external contracts, user wallets primarily
   */

  /**
   * @dev Simply log the event to track wallet interaction off-chain.
   * @param tokenAddress The address of the token that was deposited.
   * @param amount The amount of the token that was deposited.
   * @param tradingWalletBalance The updated balance of the wallet after deposit.
   */
  function walletDeposit(
    address tokenAddress,
    uint256 amount,
    uint256 tradingWalletBalance
  ) external
  {
    emit LogWalletDeposit(msg.sender, tokenAddress, amount, tradingWalletBalance);
  }

  /**
   * @dev Simply log the event to track wallet interaction off-chain.
   * @param tokenAddress The address of the token that was deposited.
   * @param amount The amount of the token that was deposited.
   * @param tradingWalletBalance The updated balance of the wallet after deposit.
   */
  function walletWithdrawal(
    address tokenAddress,
    uint256 amount,
    uint256 tradingWalletBalance
  ) external
  {
    emit LogWalletWithdrawal(msg.sender, tokenAddress, amount, tradingWalletBalance);
  }

  /**
   * Private
   */

  /**
   * Calculate the fee for the given trade. Calculated as the set % of the wei amount
   * converted into EDO tokens using the manually set conversion ratio.
   * @param makerOrder The maker order object.
   * @param toTakerAmount The amount of tokens going to the taker.
   * @param toMakerAmount The amount of tokens going to the maker.
   * @return The total fee to be paid in EDO tokens.
   */
  function __calculateFee__(
    Order makerOrder,
    uint256 toTakerAmount,
    uint256 toMakerAmount
  ) private
    view
    returns(uint256)
  {
    // weiAmount * (fee %) * (EDO/Wei) / (decimals in edo/wei) / (decimals in percentage)
    if (!__isSell__(makerOrder)) {
      // buy -> the quote is the offered token by the maker
      return mustSkipFee[makerOrder.wantToken_][makerOrder.offerToken_]
        ? 0
        : toTakerAmount.mul(feeEdoPerQuote[makerOrder.offerToken_]).div(10**feeEdoPerQuoteDecimals[makerOrder.offerToken_]);
    } else {
      // sell -> the quote is the wanted token by the maker
      return mustSkipFee[makerOrder.offerToken_][makerOrder.wantToken_]
        ? 0
        : toMakerAmount.mul(feeEdoPerQuote[makerOrder.wantToken_]).div(10**feeEdoPerQuoteDecimals[makerOrder.wantToken_]);
    }
  }

  /**
   * @dev Verify the input to order execution is valid.
   * @param ownedExternalAddressesAndTokenAddresses The maker and taker external owned accounts addresses and offered tokens contracts.
   * [
   *   makerEOA
   *   makerOfferToken
   *   takerEOA
   *   takerOfferToken
   * ]
   * @param amountsExpirationsAndSalts The amount of tokens and the block number at which this order expires and a random number to mitigate replay.
   * [
   *   makerOffer
   *   makerWant
   *   takerOffer
   *   takerWant
   *   makerExpiry
   *   makerSalt
   *   takerExpiry
   *   takerSalt
   * ]
   * @return Success if all checks pass.
   */
  function __executeOrderInputIsValid__(
    address[4] ownedExternalAddressesAndTokenAddresses,
    uint256[8] amountsExpirationsAndSalts,
    address makerTradingWallet,
    address takerTradingWallet
  ) private
    returns(bool)
  {
    // msg.send needs to be the orderBookAccount
    if (msg.sender != orderBookAccount_) {
      return error("msg.sender != orderBookAccount, Exchange.__executeOrderInputIsValid__()");
    }

    // Check expirations base on the block number
    if (block.number > amountsExpirationsAndSalts[4]) {
      return error("Maker order has expired, Exchange.__executeOrderInputIsValid__()");
    }

    if (block.number > amountsExpirationsAndSalts[6]) {
      return error("Taker order has expired, Exchange.__executeOrderInputIsValid__()");
    }

    // Operating on existing tradingWallets
    if (makerTradingWallet == address(0)) {
      return error("Maker wallet does not exist, Exchange.__executeOrderInputIsValid__()");
    }

    if (takerTradingWallet == address(0)) {
      return error("Taker wallet does not exist, Exchange.__executeOrderInputIsValid__()");
    }

    if (quotePriority[ownedExternalAddressesAndTokenAddresses[1]] == quotePriority[ownedExternalAddressesAndTokenAddresses[3]]) {
      return error("Quote token is omitted! Is not offered by either the Taker or Maker, Exchange.__executeOrderInputIsValid__()");
    }

    // Check that none of the amounts is = to 0
    if (
        amountsExpirationsAndSalts[0] == 0 ||
        amountsExpirationsAndSalts[1] == 0 ||
        amountsExpirationsAndSalts[2] == 0 ||
        amountsExpirationsAndSalts[3] == 0
      )
      return error("May not execute an order where token amount == 0, Exchange.__executeOrderInputIsValid__()");

    // // Confirm order ether amount >= min amount
    //  // Maker
    //  uint256 minOrderEthAmount = minOrderEthAmount_; // Single storage read
    //  if (_token_and_EOA_Addresses[1] == 0 && _amountsExpirationAndSalt[0] < minOrderEthAmount)
    //    return error(&#39;Maker order does not meet the minOrderEthAmount_ of ether, Exchange.__executeOrderInputIsValid__()&#39;);

    //  // Taker
    //  if (_token_and_EOA_Addresses[3] == 0 && _amountsExpirationAndSalt[2] < minOrderEthAmount)
    //    return error(&#39;Taker order does not meet the minOrderEthAmount_ of ether, Exchange.__executeOrderInputIsValid__()&#39;);

    return true;
  }

  /**
   * @dev Execute the external transfer of tokens.
   * @param ownedExternalAddressesAndTokenAddresses The maker and taker external owned accounts addresses and offered tokens contracts.
   * [
   *   makerEOA
   *   makerOfferToken
   *   takerEOA
   *   takerOfferToken
   * ]
   * @param toTakerAmount The amount of tokens to transfer to the taker.
   * @param toMakerAmount The amount of tokens to transfer to the maker.
   * @return Success if both wallets verify the order.
   */
  function __executeTokenTransfer__(
    address[4] ownedExternalAddressesAndTokenAddresses,
    uint256 toTakerAmount,
    uint256 toMakerAmount,
    uint256 fee,
    WalletV2 makerTradingWallet,
    WalletV2 takerTradingWallet
  ) private
    returns (bool)
  {
    // Wallet mapping balances
    address makerOfferTokenAddress = ownedExternalAddressesAndTokenAddresses[1];
    address takerOfferTokenAddress = ownedExternalAddressesAndTokenAddresses[3];

    // Taker to pay fee before trading
    if(fee != 0) {
      require(
        takerTradingWallet.updateBalance(edoToken_, fee, true),
        "Taker trading wallet cannot update balance with fee, Exchange.__executeTokenTransfer__()"
      );

      require(
        Token(edoToken_).transferFrom(takerTradingWallet, eidooWallet_, fee),
        "Cannot transfer fees from taker trading wallet to eidoo wallet, Exchange.__executeTokenTransfer__()"
      );
    }

    // Updating makerTradingWallet balance by the toTaker
    require(
      makerTradingWallet.updateBalance(makerOfferTokenAddress, toTakerAmount, true),
      "Maker trading wallet cannot update balance subtracting toTakerAmount, Exchange.__executeTokenTransfer__()"
    ); // return error("Unable to subtract maker token from maker wallet, Exchange.__executeTokenTransfer__()");

    // Updating takerTradingWallet balance by the toTaker
    require(
      takerTradingWallet.updateBalance(makerOfferTokenAddress, toTakerAmount, false),
      "Taker trading wallet cannot update balance adding toTakerAmount, Exchange.__executeTokenTransfer__()"
    ); // return error("Unable to add maker token to taker wallet, Exchange.__executeTokenTransfer__()");

    // Updating takerTradingWallet balance by the toMaker amount
    require(
      takerTradingWallet.updateBalance(takerOfferTokenAddress, toMakerAmount, true),
      "Taker trading wallet cannot update balance subtracting toMakerAmount, Exchange.__executeTokenTransfer__()"
    ); // return error("Unable to subtract taker token from taker wallet, Exchange.__executeTokenTransfer__()");

    // Updating makerTradingWallet balance by the toMaker amount
    require(
      makerTradingWallet.updateBalance(takerOfferTokenAddress, toMakerAmount, false),
      "Maker trading wallet cannot update balance adding toMakerAmount, Exchange.__executeTokenTransfer__()"
    ); // return error("Unable to add taker token to maker wallet, Exchange.__executeTokenTransfer__()");

    // Ether to the taker and tokens to the maker
    if (makerOfferTokenAddress == address(0)) {
      address(takerTradingWallet).transfer(toTakerAmount);
    } else {
      require(
        safeTransferFrom(makerOfferTokenAddress, makerTradingWallet, takerTradingWallet, toTakerAmount),
        "Token transfership from makerTradingWallet to takerTradingWallet failed, Exchange.__executeTokenTransfer__()"
      );
      assert(
        __tokenAndWalletBalancesMatch__(
          makerTradingWallet,
          takerTradingWallet,
          makerOfferTokenAddress
        )
      );
    }

    if (takerOfferTokenAddress == address(0)) {
      address(makerTradingWallet).transfer(toMakerAmount);
    } else {
      require(
        safeTransferFrom(takerOfferTokenAddress, takerTradingWallet, makerTradingWallet, toMakerAmount),
        "Token transfership from takerTradingWallet to makerTradingWallet failed, Exchange.__executeTokenTransfer__()"
      );
      assert(
        __tokenAndWalletBalancesMatch__(
          makerTradingWallet,
          takerTradingWallet,
          takerOfferTokenAddress
        )
      );
    }

    return true;
  }

  /**
   * @dev Calculates Keccak-256 hash of order with specified parameters.
   * @param ownedExternalAddressesAndTokenAddresses The orders maker EOA and current exchange address.
   * @param amountsExpirationsAndSalts The orders offer and want amounts and expirations with salts.
   * @return Keccak-256 hash of the passed order.
   */

  function generateOrderHashes(
    address[4] ownedExternalAddressesAndTokenAddresses,
    uint256[8] amountsExpirationsAndSalts
  ) public
    view
    returns (bytes32[2])
  {
    bytes32 makerOrderHash = keccak256(
      address(this),
      ownedExternalAddressesAndTokenAddresses[0], // _makerEOA
      ownedExternalAddressesAndTokenAddresses[1], // offerToken
      amountsExpirationsAndSalts[0],  // offerTokenAmount
      ownedExternalAddressesAndTokenAddresses[3], // wantToken
      amountsExpirationsAndSalts[1],  // wantTokenAmount
      amountsExpirationsAndSalts[4], // expiry
      amountsExpirationsAndSalts[5] // salt
    );

    bytes32 takerOrderHash = keccak256(
      address(this),
      ownedExternalAddressesAndTokenAddresses[2], // _makerEOA
      ownedExternalAddressesAndTokenAddresses[3], // offerToken
      amountsExpirationsAndSalts[2],  // offerTokenAmount
      ownedExternalAddressesAndTokenAddresses[1], // wantToken
      amountsExpirationsAndSalts[3],  // wantTokenAmount
      amountsExpirationsAndSalts[6], // expiry
      amountsExpirationsAndSalts[7] // salt
    );

    return [makerOrderHash, takerOrderHash];
  }

  /**
   * @dev Returns a bool representing a SELL or BUY order based on quotePriority.
   * @param _order The maker order data structure.
   * @return The bool indicating if the order is a SELL or BUY.
   */
  function __isSell__(Order _order) internal view returns (bool) {
    return quotePriority[_order.offerToken_] < quotePriority[_order.wantToken_];
  }

  /**
   * @dev Compute the tradeable amounts of the two verified orders.
   * Token amount is the __min__ remaining between want and offer of the two orders that isn"t ether.
   * Ether amount is then: etherAmount = tokenAmount * priceRatio, as ratio = eth / token.
   * @param makerOrder The maker order data structure.
   * @param takerOrder The taker order data structure.
   * @return The amount moving from makerOfferRemaining to takerWantRemaining and vice versa.
   */
  function __getTradeAmounts__(
    Order makerOrder,
    Order takerOrder
  ) internal
    view
    returns (uint256[2])
  {
    bool isMakerBuy = __isSell__(takerOrder);  // maker buy = taker sell
    uint256 priceRatio;
    uint256 makerAmountLeftToReceive;
    uint256 takerAmountLeftToReceive;

    uint toTakerAmount;
    uint toMakerAmount;

    if (makerOrder.offerTokenTotal_ >= makerOrder.wantTokenTotal_) {
      priceRatio = makerOrder.offerTokenTotal_.mul(2**128).div(makerOrder.wantTokenTotal_);
      if (isMakerBuy) {
        // MP > 1
        makerAmountLeftToReceive = makerOrder.wantTokenTotal_.sub(makerOrder.wantTokenReceived_);
        toMakerAmount = __min__(takerOrder.offerTokenRemaining_, makerAmountLeftToReceive);
        // add 2**128-1 in order to obtain a round up
        toTakerAmount = toMakerAmount.mul(priceRatio).add(2**128-1).div(2**128);
      } else {
        // MP < 1
        takerAmountLeftToReceive = takerOrder.wantTokenTotal_.sub(takerOrder.wantTokenReceived_);
        toTakerAmount = __min__(makerOrder.offerTokenRemaining_, takerAmountLeftToReceive);
        toMakerAmount = toTakerAmount.mul(2**128).div(priceRatio);
      }
    } else {
      priceRatio = makerOrder.wantTokenTotal_.mul(2**128).div(makerOrder.offerTokenTotal_);
      if (isMakerBuy) {
        // MP < 1
        makerAmountLeftToReceive = makerOrder.wantTokenTotal_.sub(makerOrder.wantTokenReceived_);
        toMakerAmount = __min__(takerOrder.offerTokenRemaining_, makerAmountLeftToReceive);
        toTakerAmount = toMakerAmount.mul(2**128).div(priceRatio);
      } else {
        // MP > 1
        takerAmountLeftToReceive = takerOrder.wantTokenTotal_.sub(takerOrder.wantTokenReceived_);
        toTakerAmount = __min__(makerOrder.offerTokenRemaining_, takerAmountLeftToReceive);
        // add 2**128-1 in order to obtain a round up
        toMakerAmount = toTakerAmount.mul(priceRatio).add(2**128-1).div(2**128);
      }
    }
    return [toTakerAmount, toMakerAmount];
  }

  /**
   * @dev Return the maximum of two uints
   * @param a Uint 1
   * @param b Uint 2
   * @return The grater value or a if equal
   */
  function __max__(uint256 a, uint256 b)
    private
    pure
    returns (uint256)
  {
    return a < b
      ? b
      : a;
  }

  /**
   * @dev Return the minimum of two uints
   * @param a Uint 1
   * @param b Uint 2
   * @return The smallest value or b if equal
   */
  function __min__(uint256 a, uint256 b)
    private
    pure
    returns (uint256)
  {
    return a < b
      ? a
      : b;
  }

  /**
   * @dev Confirm that the orders do match and are valid.
   * @param makerOrder The maker order data structure.
   * @param takerOrder The taker order data structure.
   * @return Bool if the orders passes all checks.
   */
  function __ordersMatch_and_AreVaild__(
    Order makerOrder,
    Order takerOrder
  ) private
    returns (bool)
  {
    // Confirm tokens match
    // NOTE potentially omit as matching handled upstream?
    if (makerOrder.wantToken_ != takerOrder.offerToken_) {
      return error("Maker wanted token does not match taker offer token, Exchange.__ordersMatch_and_AreVaild__()");
    }

    if (makerOrder.offerToken_ != takerOrder.wantToken_) {
      return error("Maker offer token does not match taker wanted token, Exchange.__ordersMatch_and_AreVaild__()");
    }

    // Price Ratios, to x decimal places hence * decimals, dependent on the size of the denominator.
    // Ratios are relative to eth, amount of ether for a single token, ie. ETH / GNO == 0.2 Ether per 1 Gnosis

    uint256 orderPrice;   // The price the maker is willing to accept
    uint256 offeredPrice; // The offer the taker has given

    // Ratio = larger amount / smaller amount
    if (makerOrder.offerTokenTotal_ >= makerOrder.wantTokenTotal_) {
      orderPrice = makerOrder.offerTokenTotal_.mul(2**128).div(makerOrder.wantTokenTotal_);
      offeredPrice = takerOrder.wantTokenTotal_.mul(2**128).div(takerOrder.offerTokenTotal_);

      // ie. Maker is offering 10 ETH for 100 GNO but taker is offering 100 GNO for 20 ETH, no match!
      // The taker wants more ether than the maker is offering.
      if (orderPrice < offeredPrice) {
        return error("Taker price is greater than maker price, Exchange.__ordersMatch_and_AreVaild__()");
      }
    } else {
      orderPrice = makerOrder.wantTokenTotal_.mul(2**128).div(makerOrder.offerTokenTotal_);
      offeredPrice = takerOrder.offerTokenTotal_.mul(2**128).div(takerOrder.wantTokenTotal_);

      // ie. Maker is offering 100 GNO for 10 ETH but taker is offering 5 ETH for 100 GNO, no match!
      // The taker is not offering enough ether for the maker
      if (orderPrice > offeredPrice) {
        return error("Taker price is less than maker price, Exchange.__ordersMatch_and_AreVaild__()");
      }
    }

    return true;
  }

  /**
   * @dev Ask each wallet to verify this order.
   * @param ownedExternalAddressesAndTokenAddresses The maker and taker external owned accounts addresses and offered tokens contracts.
   * [
   *   makerEOA
   *   makerOfferToken
   *   takerEOA
   *   takerOfferToken
   * ]
   * @param toMakerAmount The amount of tokens to be sent to the maker.
   * @param toTakerAmount The amount of tokens to be sent to the taker.
   * @param makerTradingWallet The maker trading wallet contract.
   * @param takerTradingWallet The taker trading wallet contract.
   * @param fee The fee to be paid for this trade, paid in full by taker.
   * @return Success if both wallets verify the order.
   */
  function __ordersVerifiedByWallets__(
    address[4] ownedExternalAddressesAndTokenAddresses,
    uint256 toMakerAmount,
    uint256 toTakerAmount,
    WalletV2 makerTradingWallet,
    WalletV2 takerTradingWallet,
    uint256 fee
  ) private
    returns (bool)
  {
    // Have the transaction verified by both maker and taker wallets
    // confirm sufficient balance to transfer, offerToken and offerTokenAmount
    if(!makerTradingWallet.verifyOrder(ownedExternalAddressesAndTokenAddresses[1], toTakerAmount, 0, 0)) {
      return error("Maker wallet could not verify the order, Exchange.____ordersVerifiedByWallets____()");
    }

    if(!takerTradingWallet.verifyOrder(ownedExternalAddressesAndTokenAddresses[3], toMakerAmount, fee, edoToken_)) {
      return error("Taker wallet could not verify the order, Exchange.____ordersVerifiedByWallets____()");
    }

    return true;
  }

  /**
   * @dev On chain verification of an ECDSA ethereum signature.
   * @param signer The EOA address of the account that supposedly signed the message.
   * @param orderHash The on-chain generated hash for the order.
   * @param v ECDSA signature parameter v.
   * @param r ECDSA signature parameter r.
   * @param s ECDSA signature parameter s.
   * @return Bool if the signature is valid or not.
   */
  function __signatureIsValid__(
    address signer,
    bytes32 orderHash,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) private
    pure
    returns (bool)
  {
    address recoveredAddr = ecrecover(
      keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", orderHash)),
      v,
      r,
      s
    );

    return recoveredAddr == signer;
  }

  /**
   * @dev Confirm wallet local balances and token balances match.
   * @param makerTradingWallet  Maker wallet address.
   * @param takerTradingWallet  Taker wallet address.
   * @param token  Token address to confirm balances match.
   * @return If the balances do match.
   */
  function __tokenAndWalletBalancesMatch__(
    address makerTradingWallet,
    address takerTradingWallet,
    address token
  ) private
    view
    returns(bool)
  {
    if (Token(token).balanceOf(makerTradingWallet) != WalletV2(makerTradingWallet).balanceOf(token)) {
      return false;
    }

    if (Token(token).balanceOf(takerTradingWallet) != WalletV2(takerTradingWallet).balanceOf(token)) {
      return false;
    }

    return true;
  }

  /**
   * @dev Wrapping the ERC20 transfer function to avoid missing returns.
   * @param _token The address of bad formed ERC20 token.
   * @param _from Transfer sender.
   * @param _to Transfer receiver.
   * @param _value Amount to be transfered.
   * @return Success of the safeTransfer.
   */
  function safeTransferFrom(
    address _token,
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool result)
  {
    BadERC20(_token).transferFrom(_from, _to, _value);

    assembly {
      switch returndatasize()
      case 0 {                      // This is our BadToken
        result := not(0)            // result is true
      }
      case 32 {                     // This is our GoodToken
        returndatacopy(0, 0, 32)
        result := mload(0)          // result == returndata of external call
      }
      default {                     // This is not an ERC20 token
        revert(0, 0)
      }
    }
  }
}
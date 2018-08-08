pragma solidity ^0.4.11;

// NB: this is the newer ERC20 returning bool, need different book contract for older style tokens
contract ERC20 {
  function totalSupply() constant returns (uint);
  function balanceOf(address _owner) constant returns (uint balance);
  function transfer(address _to, uint _value) returns (bool success);
  function transferFrom(address _from, address _to, uint _value) returns (bool success);
  function approve(address _spender, uint _value) returns (bool success);
  function allowance(address _owner, address _spender) constant returns (uint remaining);
  event Transfer(address indexed _from, address indexed _to, uint _value);
  event Approval(address indexed _owner, address indexed _spender, uint _value);
}

// UbiTok.io limit order book with an "nice" ERC20 token as base, ETH as quoted, and standard fees.
// Copyright (c) Bonnag Limited. All Rights Reserved.
//
contract BookERC20EthV1 {

  enum BookType {
    ERC20EthV1
  }

  enum Direction {
    Invalid,
    Buy,
    Sell
  }

  enum Status {
    Unknown,
    Rejected,
    Open,
    Done,
    NeedsGas,
    Sending, // not used by contract - web only
    FailedSend, // not used by contract - web only
    FailedTxn // not used by contract - web only
  }

  enum ReasonCode {
    None,
    InvalidPrice,
    InvalidSize,
    InvalidTerms,
    InsufficientFunds,
    WouldTake,
    Unmatched,
    TooManyMatches,
    ClientCancel
  }

  enum Terms {
    GTCNoGasTopup,
    GTCWithGasTopup,
    ImmediateOrCancel,
    MakerOnly
  }

  struct Order {
    // these are immutable once placed:

    address client;
    uint16 price;              // packed representation of side + price
    uint sizeBase;
    Terms terms;

    // these are mutable until Done or Rejected:
    
    Status status;
    ReasonCode reasonCode;
    uint128 executedBase;      // gross amount executed in base currency (before fee deduction)
    uint128 executedCntr;      // gross amount executed in counter currency (before fee deduction)
    uint128 feesBaseOrCntr;    // base for buy, cntr for sell
    uint128 feesRwrd;
  }
  
  struct OrderChain {
    uint128 firstOrderId;
    uint128 lastOrderId;
  }

  struct OrderChainNode {
    uint128 nextOrderId;
    uint128 prevOrderId;
  }
  
  enum ClientPaymentEventType {
    Deposit,
    Withdraw,
    TransferFrom,
    Transfer
  }

  enum BalanceType {
    Base,
    Cntr,
    Rwrd
  }

  event ClientPaymentEvent(
    address indexed client,
    ClientPaymentEventType clientPaymentEventType,
    BalanceType balanceType,
    int clientBalanceDelta
  );

  enum ClientOrderEventType {
    Create,
    Continue,
    Cancel
  }

  event ClientOrderEvent(
    address indexed client,
    ClientOrderEventType clientOrderEventType,
    uint128 orderId
  );

  enum MarketOrderEventType {
    // orderCount++, depth += depthBase
    Add,
    // orderCount--, depth -= depthBase
    Remove,
    // orderCount--, depth -= depthBase, traded += tradeBase
    // (depth change and traded change differ when tiny remaining amount refunded)
    CompleteFill,
    // orderCount unchanged, depth -= depthBase, traded += tradeBase
    PartialFill
  }

  // these events can be used to build an order book or watch for fills
  // note that the orderId and price are those of the maker
  event MarketOrderEvent(
    uint256 indexed eventTimestamp,
    uint128 indexed orderId,
    MarketOrderEventType marketOrderEventType,
    uint16 price,
    uint depthBase,
    uint tradeBase
  );

  // the base token (e.g. TEST)
  
  ERC20 baseToken;

  // minimum order size (inclusive)
  uint constant baseMinInitialSize = 100 finney;

  // if following partial match, the remaning gets smaller than this, remove from book and refund:
  // generally we make this 10% of baseMinInitialSize
  uint constant baseMinRemainingSize = 10 finney;

  // maximum order size (exclusive)
  // chosen so that even multiplied by the max price (or divided by the min price),
  // and then multiplied by ethRwrdRate, it still fits in 2^127, allowing us to save
  // some gas by storing executed + fee fields as uint128.
  // even with 18 decimals, this still allows order sizes up to 1,000,000,000.
  // if we encounter a token with e.g. 36 decimals we&#39;ll have to revisit ...
  uint constant baseMaxSize = 10 ** 30;

  // the counter currency (ETH)
  // (no address because it is ETH)

  // avoid the book getting cluttered up with tiny amounts not worth the gas
  uint constant cntrMinInitialSize = 10 finney;

  // see comments for baseMaxSize
  uint constant cntrMaxSize = 10 ** 30;

  // the reward token that can be used to pay fees (UBI)

  ERC20 rwrdToken;

  // used to convert ETH amount to reward tokens when paying fee with reward tokens
  uint constant ethRwrdRate = 1000;
  
  // funds that belong to clients (base, counter, and reward)

  mapping (address => uint) balanceBaseForClient;
  mapping (address => uint) balanceCntrForClient;
  mapping (address => uint) balanceRwrdForClient;

  // fee charged on liquidity taken, expressed as a divisor
  // (e.g. 2000 means 1/2000, or 0.05%)

  uint constant feeDivisor = 2000;
  
  // fees charged are given to:
  
  address feeCollector;

  // all orders ever created
  
  mapping (uint128 => Order) orderForOrderId;
  
  // Effectively a compact mapping from price to whether there are any open orders at that price.
  // See "Price Calculation Constants" below as to why 85.

  uint256[85] occupiedPriceBitmaps;

  // These allow us to walk over the orders in the book at a given price level (and add more).

  mapping (uint16 => OrderChain) orderChainForOccupiedPrice;
  mapping (uint128 => OrderChainNode) orderChainNodeForOpenOrderId;

  // These allow a client to (reasonably) efficiently find their own orders
  // without relying on events (which even indexed are a bit expensive to search
  // and cannot be accessed from smart contracts). See walkOrders.

  mapping (address => uint128) mostRecentOrderIdForClient;
  mapping (uint128 => uint128) clientPreviousOrderIdBeforeOrderId;

  // Price Calculation Constants.
  //
  // We pack direction and price into a crafty decimal floating point representation
  // for efficient indexing by price, the main thing we lose by doing so is precision -
  // we only have 3 significant figures in our prices.
  //
  // An unpacked price consists of:
  //
  //   direction - invalid / buy / sell
  //   mantissa  - ranges from 100 to 999 representing 0.100 to 0.999
  //   exponent  - ranges from minimumPriceExponent to minimumPriceExponent + 11
  //               (e.g. -5 to +6 for a typical pair where minPriceExponent = -5)
  //
  // The packed representation has 21601 different price values:
  //
  //      0  = invalid (can be used as marker value)
  //      1  = buy at maximum price (0.999 * 10 ** 6)
  //    ...  = other buy prices in descending order
  //   5401  = buy at 1.00
  //    ...  = other buy prices in descending order
  //  10800  = buy at minimum price (0.100 * 10 ** -5)
  //  10801  = sell at minimum price (0.100 * 10 ** -5)
  //    ...  = other sell prices in descending order
  //  16201  = sell at 1.00
  //    ...  = other sell prices in descending order
  //  21600  = sell at maximum price (0.999 * 10 ** 6)
  //  21601+ = do not use
  //
  // If we want to map each packed price to a boolean value (which we do),
  // we require 85 256-bit words. Or 42.5 for each side of the book.
  
  int8 constant minPriceExponent = -5;

  uint constant invalidPrice = 0;

  // careful: max = largest unpacked value, not largest packed value
  uint constant maxBuyPrice = 1; 
  uint constant minBuyPrice = 10800;
  uint constant minSellPrice = 10801;
  uint constant maxSellPrice = 21600;

  // Constructor.
  //
  // Sets feeCollector to the creator. Creator needs to call init() to finish setup.
  //
  function BookERC20EthV1() {
    address creator = msg.sender;
    feeCollector = creator;
  }

  // "Public" Management - set address of base and reward tokens.
  //
  // Can only be done once (normally immediately after creation) by the fee collector.
  //
  // Used instead of a constructor to make deployment easier.
  //
  function init(ERC20 _baseToken, ERC20 _rwrdToken) public {
    require(msg.sender == feeCollector);
    require(address(baseToken) == 0);
    require(address(_baseToken) != 0);
    require(address(rwrdToken) == 0);
    require(address(_rwrdToken) != 0);
    // attempt to catch bad tokens:
    require(_baseToken.totalSupply() > 0);
    baseToken = _baseToken;
    require(_rwrdToken.totalSupply() > 0);
    rwrdToken = _rwrdToken;
  }

  // "Public" Management - change fee collector
  //
  // The new fee collector only gets fees charged after this point.
  //
  function changeFeeCollector(address newFeeCollector) public {
    address oldFeeCollector = feeCollector;
    require(msg.sender == oldFeeCollector);
    require(newFeeCollector != oldFeeCollector);
    feeCollector = newFeeCollector;
  }
  
  // Public Info View - what is being traded here, what are the limits?
  //
  function getBookInfo() public constant returns (
      BookType _bookType, address _baseToken, address _rwrdToken,
      uint _baseMinInitialSize, uint _cntrMinInitialSize,
      uint _feeDivisor, address _feeCollector
    ) {
    return (
      BookType.ERC20EthV1,
      address(baseToken),
      address(rwrdToken),
      baseMinInitialSize,
      cntrMinInitialSize,
      feeDivisor,
      feeCollector
    );
  }

  // Public Funds View - get balances held by contract on behalf of the client,
  // or balances approved for deposit but not yet claimed by the contract.
  //
  // Excludes funds in open orders.
  //
  // Helps a web ui get a consistent snapshot of balances.
  //
  // It would be nice to return the off-exchange ETH balance too but there&#39;s a
  // bizarre bug in geth (and apparently as a result via MetaMask) that leads
  // to unpredictable behaviour when looking up client balances in constant
  // functions - see e.g. https://github.com/ethereum/solidity/issues/2325 .
  //
  function getClientBalances(address client) public constant returns (
      uint bookBalanceBase,
      uint bookBalanceCntr,
      uint bookBalanceRwrd,
      uint approvedBalanceBase,
      uint approvedBalanceRwrd,
      uint ownBalanceBase,
      uint ownBalanceRwrd
    ) {
    bookBalanceBase = balanceBaseForClient[client];
    bookBalanceCntr = balanceCntrForClient[client];
    bookBalanceRwrd = balanceRwrdForClient[client];
    approvedBalanceBase = baseToken.allowance(client, address(this));
    approvedBalanceRwrd = rwrdToken.allowance(client, address(this));
    ownBalanceBase = baseToken.balanceOf(client);
    ownBalanceRwrd = rwrdToken.balanceOf(client);
  }

  // Public Funds Manipulation - deposit previously-approved base tokens.
  //
  function transferFromBase() public {
    address client = msg.sender;
    address book = address(this);
    // we trust the ERC20 token contract not to do nasty things like call back into us -
    // if we cannot trust the token then why are we allowing it to be traded?
    uint amountBase = baseToken.allowance(client, book);
    require(amountBase > 0);
    // NB: needs change for older ERC20 tokens that don&#39;t return bool
    require(baseToken.transferFrom(client, book, amountBase));
    // belt and braces
    assert(baseToken.allowance(client, book) == 0);
    balanceBaseForClient[client] += amountBase;
    ClientPaymentEvent(client, ClientPaymentEventType.TransferFrom, BalanceType.Base, int(amountBase));
  }

  // Public Funds Manipulation - withdraw base tokens (as a transfer).
  //
  function transferBase(uint amountBase) public {
    address client = msg.sender;
    require(amountBase > 0);
    require(amountBase <= balanceBaseForClient[client]);
    // overflow safe since we checked less than balance above
    balanceBaseForClient[client] -= amountBase;
    // we trust the ERC20 token contract not to do nasty things like call back into us -
    // if we cannot trust the token then why are we allowing it to be traded?
    // NB: needs change for older ERC20 tokens that don&#39;t return bool
    require(baseToken.transfer(client, amountBase));
    ClientPaymentEvent(client, ClientPaymentEventType.Transfer, BalanceType.Base, -int(amountBase));
  }

  // Public Funds Manipulation - deposit counter currency (ETH).
  //
  function depositCntr() public payable {
    address client = msg.sender;
    uint amountCntr = msg.value;
    require(amountCntr > 0);
    // overflow safe - if someone owns pow(2,255) ETH we have bigger problems
    balanceCntrForClient[client] += amountCntr;
    ClientPaymentEvent(client, ClientPaymentEventType.Deposit, BalanceType.Cntr, int(amountCntr));
  }

  // Public Funds Manipulation - withdraw counter currency (ETH).
  //
  function withdrawCntr(uint amountCntr) public {
    address client = msg.sender;
    require(amountCntr > 0);
    require(amountCntr <= balanceCntrForClient[client]);
    // overflow safe - checked less than balance above
    balanceCntrForClient[client] -= amountCntr;
    // safe - not enough gas to do anything interesting in fallback, already adjusted balance
    client.transfer(amountCntr);
    ClientPaymentEvent(client, ClientPaymentEventType.Withdraw, BalanceType.Cntr, -int(amountCntr));
  }

  // Public Funds Manipulation - deposit previously-approved reward tokens.
  //
  function transferFromRwrd() public {
    address client = msg.sender;
    address book = address(this);
    uint amountRwrd = rwrdToken.allowance(client, book);
    require(amountRwrd > 0);
    // we wrote the reward token so we know it supports ERC20 properly and is not evil
    require(rwrdToken.transferFrom(client, book, amountRwrd));
    // belt and braces
    assert(rwrdToken.allowance(client, book) == 0);
    balanceRwrdForClient[client] += amountRwrd;
    ClientPaymentEvent(client, ClientPaymentEventType.TransferFrom, BalanceType.Rwrd, int(amountRwrd));
  }

  // Public Funds Manipulation - withdraw base tokens (as a transfer).
  //
  function transferRwrd(uint amountRwrd) public {
    address client = msg.sender;
    require(amountRwrd > 0);
    require(amountRwrd <= balanceRwrdForClient[client]);
    // overflow safe - checked less than balance above
    balanceRwrdForClient[client] -= amountRwrd;
    // we wrote the reward token so we know it supports ERC20 properly and is not evil
    require(rwrdToken.transfer(client, amountRwrd));
    ClientPaymentEvent(client, ClientPaymentEventType.Transfer, BalanceType.Rwrd, -int(amountRwrd));
  }

  // Public Order View - get full details of an order.
  //
  // If the orderId does not exist, status will be Unknown.
  //
  function getOrder(uint128 orderId) public constant returns (
    address client, uint16 price, uint sizeBase, Terms terms,
    Status status, ReasonCode reasonCode, uint executedBase, uint executedCntr,
    uint feesBaseOrCntr, uint feesRwrd) {
    Order storage order = orderForOrderId[orderId];
    return (order.client, order.price, order.sizeBase, order.terms,
            order.status, order.reasonCode, order.executedBase, order.executedCntr,
            order.feesBaseOrCntr, order.feesRwrd);
  }

  // Public Order View - get mutable details of an order.
  //
  // If the orderId does not exist, status will be Unknown.
  //
  function getOrderState(uint128 orderId) public constant returns (
    Status status, ReasonCode reasonCode, uint executedBase, uint executedCntr,
    uint feesBaseOrCntr, uint feesRwrd) {
    Order storage order = orderForOrderId[orderId];
    return (order.status, order.reasonCode, order.executedBase, order.executedCntr,
            order.feesBaseOrCntr, order.feesRwrd);
  }
  
  // Public Order View - enumerate all recent orders + all open orders for one client.
  //
  // Not really designed for use from a smart contract transaction.
  //
  // Idea is:
  //  - client ensures order ids are generated so that most-signficant part is time-based;
  //  - client decides they want all orders after a certain point-in-time,
  //    and chooses minClosedOrderIdCutoff accordingly;
  //  - before that point-in-time they just get open and needs gas orders
  //  - client calls walkClientOrders with maybeLastOrderIdReturned = 0 initially;
  //  - then repeats with the orderId returned by walkClientOrders;
  //  - (and stops if it returns a zero orderId);
  //
  // Note that client is only used when maybeLastOrderIdReturned = 0.
  //
  function walkClientOrders(
      address client, uint128 maybeLastOrderIdReturned, uint128 minClosedOrderIdCutoff
    ) public constant returns (
      uint128 orderId, uint16 price, uint sizeBase, Terms terms,
      Status status, ReasonCode reasonCode, uint executedBase, uint executedCntr,
      uint feesBaseOrCntr, uint feesRwrd) {
    if (maybeLastOrderIdReturned == 0) {
      orderId = mostRecentOrderIdForClient[client];
    } else {
      orderId = clientPreviousOrderIdBeforeOrderId[maybeLastOrderIdReturned];
    }
    while (true) {
      if (orderId == 0) return;
      Order storage order = orderForOrderId[orderId];
      if (orderId >= minClosedOrderIdCutoff) break;
      if (order.status == Status.Open || order.status == Status.NeedsGas) break;
      orderId = clientPreviousOrderIdBeforeOrderId[orderId];
    }
    return (orderId, order.price, order.sizeBase, order.terms,
            order.status, order.reasonCode, order.executedBase, order.executedCntr,
            order.feesBaseOrCntr, order.feesRwrd);
  }
 
  // Internal Price Calculation - turn packed price into a friendlier unpacked price.
  //
  function unpackPrice(uint16 price) internal constant returns (
      Direction direction, uint16 mantissa, int8 exponent
    ) {
    uint sidedPriceIndex = uint(price);
    uint priceIndex;
    if (sidedPriceIndex < 1 || sidedPriceIndex > maxSellPrice) {
      direction = Direction.Invalid;
      mantissa = 0;
      exponent = 0;
      return;
    } else if (sidedPriceIndex <= minBuyPrice) {
      direction = Direction.Buy;
      priceIndex = minBuyPrice - sidedPriceIndex;
    } else {
      direction = Direction.Sell;
      priceIndex = sidedPriceIndex - minSellPrice;
    }
    uint zeroBasedMantissa = priceIndex % 900;
    uint zeroBasedExponent = priceIndex / 900;
    mantissa = uint16(zeroBasedMantissa + 100);
    exponent = int8(zeroBasedExponent) + minPriceExponent;
    return;
  }
  
  // Internal Price Calculation - is a packed price on the buy side?
  //
  // Throws an error if price is invalid.
  //
  function isBuyPrice(uint16 price) internal constant returns (bool isBuy) {
    // yes, this looks odd, but max here is highest _unpacked_ price
    return price >= maxBuyPrice && price <= minBuyPrice;
  }
  
  // Internal Price Calculation - turn a packed buy price into a packed sell price.
  //
  // Invalid price remains invalid.
  //
  function computeOppositePrice(uint16 price) internal constant returns (uint16 opposite) {
    if (price < maxBuyPrice || price > maxSellPrice) {
      return uint16(invalidPrice);
    } else if (price <= minBuyPrice) {
      return uint16(maxSellPrice - (price - maxBuyPrice));
    } else {
      return uint16(maxBuyPrice + (maxSellPrice - price));
    }
  }
  
  // Internal Price Calculation - compute amount in counter currency that would
  // be obtained by selling baseAmount at the given unpacked price (if no fees).
  //
  // Notes:
  //  - Does not validate price - caller must ensure valid.
  //  - Could overflow producing very unexpected results if baseAmount very
  //    large - caller must check this.
  //  - This rounds the amount towards zero.
  //  - May truncate to zero if baseAmount very small - potentially allowing
  //    zero-cost buys or pointless sales - caller must check this.
  //
  function computeCntrAmountUsingUnpacked(
      uint baseAmount, uint16 mantissa, int8 exponent
    ) internal constant returns (uint cntrAmount) {
    if (exponent < 0) {
      return baseAmount * uint(mantissa) / 1000 / 10 ** uint(-exponent);
    } else {
      return baseAmount * uint(mantissa) / 1000 * 10 ** uint(exponent);
    }
  }

  // Internal Price Calculation - compute amount in counter currency that would
  // be obtained by selling baseAmount at the given packed price (if no fees).
  //
  // Notes:
  //  - Does not validate price - caller must ensure valid.
  //  - Direction of the packed price is ignored.
  //  - Could overflow producing very unexpected results if baseAmount very
  //    large - caller must check this.
  //  - This rounds the amount towards zero (regardless of Buy or Sell).
  //  - May truncate to zero if baseAmount very small - potentially allowing
  //    zero-cost buys or pointless sales - caller must check this.
  //
  function computeCntrAmountUsingPacked(
      uint baseAmount, uint16 price
    ) internal constant returns (uint) {
    var (, mantissa, exponent) = unpackPrice(price);
    return computeCntrAmountUsingUnpacked(baseAmount, mantissa, exponent);
  }

  // Public Order Placement - create order and try to match it and/or add it to the book.
  //
  function createOrder(
      uint128 orderId, uint16 price, uint sizeBase, Terms terms, uint maxMatches
    ) public {
    address client = msg.sender;
    require(client != 0 && orderId != 0 && orderForOrderId[orderId].client == 0);
    ClientOrderEvent(client, ClientOrderEventType.Create, orderId);
    orderForOrderId[orderId] =
      Order(client, price, sizeBase, terms, Status.Unknown, ReasonCode.None, 0, 0, 0, 0);
    uint128 previousMostRecentOrderIdForClient = mostRecentOrderIdForClient[client];
    mostRecentOrderIdForClient[client] = orderId;
    clientPreviousOrderIdBeforeOrderId[orderId] = previousMostRecentOrderIdForClient;
    Order storage order = orderForOrderId[orderId];
    var (direction, mantissa, exponent) = unpackPrice(price);
    if (direction == Direction.Invalid) {
      order.status = Status.Rejected;
      order.reasonCode = ReasonCode.InvalidPrice;
      return;
    }
    if (sizeBase < baseMinInitialSize || sizeBase > baseMaxSize) {
      order.status = Status.Rejected;
      order.reasonCode = ReasonCode.InvalidSize;
      return;
    }
    uint sizeCntr = computeCntrAmountUsingUnpacked(sizeBase, mantissa, exponent);
    if (sizeCntr < cntrMinInitialSize || sizeCntr > cntrMaxSize) {
      order.status = Status.Rejected;
      order.reasonCode = ReasonCode.InvalidSize;
      return;
    }
    if (terms == Terms.MakerOnly && maxMatches != 0) {
      order.status = Status.Rejected;
      order.reasonCode = ReasonCode.InvalidTerms;
      return;
    }
    if (!debitFunds(client, direction, sizeBase, sizeCntr)) {
      order.status = Status.Rejected;
      order.reasonCode = ReasonCode.InsufficientFunds;
      return;
    }
    processOrder(orderId, maxMatches);
  }

  // Public Order Placement - cancel order
  //
  function cancelOrder(uint128 orderId) public {
    address client = msg.sender;
    Order storage order = orderForOrderId[orderId];
    require(order.client == client);
    Status status = order.status;
    if (status != Status.Open && status != Status.NeedsGas) {
      return;
    }
    if (status == Status.Open) {
      removeOpenOrderFromBook(orderId);
      MarketOrderEvent(block.timestamp, orderId, MarketOrderEventType.Remove, order.price,
        order.sizeBase - order.executedBase, 0);
    }
    refundUnmatchedAndFinish(orderId, Status.Done, ReasonCode.ClientCancel);
  }

  // Public Order Placement - continue placing an order in &#39;NeedsGas&#39; state
  //
  function continueOrder(uint128 orderId, uint maxMatches) public {
    address client = msg.sender;
    Order storage order = orderForOrderId[orderId];
    require(order.client == client);
    if (order.status != Status.NeedsGas) {
      return;
    }
    order.status = Status.Unknown;
    processOrder(orderId, maxMatches);
  }

  // Internal Order Placement - remove a still-open order from the book.
  //
  // Caller&#39;s job to update/refund the order + raise event, this just
  // updates the order chain and bitmask.
  //
  // Too expensive to do on each resting order match - we only do this for an
  // order being cancelled. See matchWithOccupiedPrice for similar logic.
  //
  function removeOpenOrderFromBook(uint128 orderId) internal {
    Order storage order = orderForOrderId[orderId];
    uint16 price = order.price;
    OrderChain storage orderChain = orderChainForOccupiedPrice[price];
    OrderChainNode storage orderChainNode = orderChainNodeForOpenOrderId[orderId];
    uint128 nextOrderId = orderChainNode.nextOrderId;
    uint128 prevOrderId = orderChainNode.prevOrderId;
    if (nextOrderId != 0) {
      OrderChainNode storage nextOrderChainNode = orderChainNodeForOpenOrderId[nextOrderId];
      nextOrderChainNode.prevOrderId = prevOrderId;
    } else {
      orderChain.lastOrderId = prevOrderId;
    }
    if (prevOrderId != 0) {
      OrderChainNode storage prevOrderChainNode = orderChainNodeForOpenOrderId[prevOrderId];
      prevOrderChainNode.nextOrderId = nextOrderId;
    } else {
      orderChain.firstOrderId = nextOrderId;
    }
    if (nextOrderId == 0 && prevOrderId == 0) {
      uint bmi = price / 256;  // index into array of bitmaps
      uint bti = price % 256;  // bit position within bitmap
      // we know was previously occupied so XOR clears
      occupiedPriceBitmaps[bmi] ^= 2 ** bti;
    }
  }

  // Internal Order Placement - credit funds received when taking liquidity from book
  //
  function creditExecutedFundsLessFees(uint128 orderId, uint originalExecutedBase, uint originalExecutedCntr) internal {
    Order storage order = orderForOrderId[orderId];
    uint liquidityTakenBase = order.executedBase - originalExecutedBase;
    uint liquidityTakenCntr = order.executedCntr - originalExecutedCntr;
    // Normally we deduct the fee from the currency bought (base for buy, cntr for sell),
    // however we also accept reward tokens from the reward balance if it covers the fee,
    // with the reward amount converted from the ETH amount (the counter currency here)
    // at a fixed exchange rate.
    // Overflow safe since we ensure order size < 10^30 in both currencies (see baseMaxSize).
    // Can truncate to zero, which is fine.
    uint feesRwrd = liquidityTakenCntr / feeDivisor * ethRwrdRate;
    uint feesBaseOrCntr;
    address client = order.client;
    uint availRwrd = balanceRwrdForClient[client];
    if (feesRwrd <= availRwrd) {
      balanceRwrdForClient[client] = availRwrd - feesRwrd;
      balanceRwrdForClient[feeCollector] = feesRwrd;
      // Need += rather than = because could have paid some fees earlier in NeedsGas situation.
      // Overflow safe since we ensure order size < 10^30 in both currencies (see baseMaxSize).
      // Can truncate to zero, which is fine.
      order.feesRwrd += uint128(feesRwrd);
      if (isBuyPrice(order.price)) {
        balanceBaseForClient[client] += liquidityTakenBase;
      } else {
        balanceCntrForClient[client] += liquidityTakenCntr;
      }
    } else if (isBuyPrice(order.price)) {
      // See comments in branch above re: use of += and overflow safety.
      feesBaseOrCntr = liquidityTakenBase / feeDivisor;
      balanceBaseForClient[order.client] += (liquidityTakenBase - feesBaseOrCntr);
      order.feesBaseOrCntr += uint128(feesBaseOrCntr);
      balanceBaseForClient[feeCollector] += feesBaseOrCntr;
    } else {
      // See comments in branch above re: use of += and overflow safety.
      feesBaseOrCntr = liquidityTakenCntr / feeDivisor;
      balanceCntrForClient[order.client] += (liquidityTakenCntr - feesBaseOrCntr);
      order.feesBaseOrCntr += uint128(feesBaseOrCntr);
      balanceCntrForClient[feeCollector] += feesBaseOrCntr;
    }
  }

  // Internal Order Placement - process a created and sanity checked order.
  //
  // Used both for new orders and for gas topup.
  //
  function processOrder(uint128 orderId, uint maxMatches) internal {
    Order storage order = orderForOrderId[orderId];

    uint ourOriginalExecutedBase = order.executedBase;
    uint ourOriginalExecutedCntr = order.executedCntr;

    var (ourDirection,) = unpackPrice(order.price);
    uint theirPriceStart = (ourDirection == Direction.Buy) ? minSellPrice : maxBuyPrice;
    uint theirPriceEnd = computeOppositePrice(order.price);
   
    MatchStopReason matchStopReason =
      matchAgainstBook(orderId, theirPriceStart, theirPriceEnd, maxMatches);

    creditExecutedFundsLessFees(orderId, ourOriginalExecutedBase, ourOriginalExecutedCntr);

    if (order.terms == Terms.ImmediateOrCancel) {
      if (matchStopReason == MatchStopReason.Satisfied) {
        refundUnmatchedAndFinish(orderId, Status.Done, ReasonCode.None);
        return;
      } else if (matchStopReason == MatchStopReason.MaxMatches) {
        refundUnmatchedAndFinish(orderId, Status.Done, ReasonCode.TooManyMatches);
        return;
      } else if (matchStopReason == MatchStopReason.BookExhausted) {
        refundUnmatchedAndFinish(orderId, Status.Done, ReasonCode.Unmatched);
        return;
      }
    } else if (order.terms == Terms.MakerOnly) {
      if (matchStopReason == MatchStopReason.MaxMatches) {
        refundUnmatchedAndFinish(orderId, Status.Rejected, ReasonCode.WouldTake);
        return;
      } else if (matchStopReason == MatchStopReason.BookExhausted) {
        enterOrder(orderId);
        return;
      }
    } else if (order.terms == Terms.GTCNoGasTopup) {
      if (matchStopReason == MatchStopReason.Satisfied) {
        refundUnmatchedAndFinish(orderId, Status.Done, ReasonCode.None);
        return;
      } else if (matchStopReason == MatchStopReason.MaxMatches) {
        refundUnmatchedAndFinish(orderId, Status.Done, ReasonCode.TooManyMatches);
        return;
      } else if (matchStopReason == MatchStopReason.BookExhausted) {
        enterOrder(orderId);
        return;
      }
    } else if (order.terms == Terms.GTCWithGasTopup) {
      if (matchStopReason == MatchStopReason.Satisfied) {
        refundUnmatchedAndFinish(orderId, Status.Done, ReasonCode.None);
        return;
      } else if (matchStopReason == MatchStopReason.MaxMatches) {
        order.status = Status.NeedsGas;
        return;
      } else if (matchStopReason == MatchStopReason.BookExhausted) {
        enterOrder(orderId);
        return;
      }
    }
    assert(false); // should not be possible to reach here
  }
 
  // Used internally to indicate why we stopped matching an order against the book.

  enum MatchStopReason {
    None,
    MaxMatches,
    Satisfied,
    PriceExhausted,
    BookExhausted
  }
 
  // Internal Order Placement - Match the given order against the book.
  //
  // Resting orders matched will be updated, removed from book and funds credited to their owners.
  //
  // Only updates the executedBase and executedCntr of the given order - caller is responsible
  // for crediting matched funds, charging fees, marking order as done / entering it into the book.
  //
  // matchStopReason returned will be one of MaxMatches, Satisfied or BookExhausted.
  //
  function matchAgainstBook(
      uint128 orderId, uint theirPriceStart, uint theirPriceEnd, uint maxMatches
    ) internal returns (
      MatchStopReason matchStopReason
    ) {
    Order storage order = orderForOrderId[orderId];
    
    uint bmi = theirPriceStart / 256;  // index into array of bitmaps
    uint bti = theirPriceStart % 256;  // bit position within bitmap
    uint bmiEnd = theirPriceEnd / 256; // last bitmap to search
    uint btiEnd = theirPriceEnd % 256; // stop at this bit in the last bitmap

    uint cbm = occupiedPriceBitmaps[bmi]; // original copy of current bitmap
    uint dbm = cbm; // dirty version of current bitmap where we may have cleared bits
    uint wbm = cbm >> bti; // working copy of current bitmap which we keep shifting
    
    // these loops are pretty ugly, and somewhat unpredicatable in terms of gas,
    // ... but no-one else has come up with a better matching engine yet!

    bool removedLastAtPrice;
    matchStopReason = MatchStopReason.None;

    while (bmi < bmiEnd) {
      if (wbm == 0 || bti == 256) {
        if (dbm != cbm) {
          occupiedPriceBitmaps[bmi] = dbm;
        }
        bti = 0;
        bmi++;
        cbm = occupiedPriceBitmaps[bmi];
        wbm = cbm;
        dbm = cbm;
      } else {
        if ((wbm & 1) != 0) {
          // careful - copy-and-pasted in loop below ...
          (removedLastAtPrice, maxMatches, matchStopReason) =
            matchWithOccupiedPrice(order, uint16(bmi * 256 + bti), maxMatches);
          if (removedLastAtPrice) {
            dbm ^= 2 ** bti;
          }
          if (matchStopReason == MatchStopReason.PriceExhausted) {
            matchStopReason = MatchStopReason.None;
          } else if (matchStopReason != MatchStopReason.None) {
            break;
          }
        }
        bti += 1;
        wbm /= 2;
      }
    }
    if (matchStopReason == MatchStopReason.None) {
      // we&#39;ve reached the last bitmap we need to search,
      // we&#39;ll stop at btiEnd not 256 this time.
      while (bti <= btiEnd && wbm != 0) {
        if ((wbm & 1) != 0) {
          // careful - copy-and-pasted in loop above ...
          (removedLastAtPrice, maxMatches, matchStopReason) =
            matchWithOccupiedPrice(order, uint16(bmi * 256 + bti), maxMatches);
          if (removedLastAtPrice) {
            dbm ^= 2 ** bti;
          }
          if (matchStopReason == MatchStopReason.PriceExhausted) {
            matchStopReason = MatchStopReason.None;
          } else if (matchStopReason != MatchStopReason.None) {
            break;
          }
        }
        bti += 1;
        wbm /= 2;
      }
    }
    // Careful - if we exited the first loop early, or we went into the second loop,
    // (luckily can&#39;t both happen) then we haven&#39;t flushed the dirty bitmap back to
    // storage - do that now if we need to.
    if (dbm != cbm) {
      occupiedPriceBitmaps[bmi] = dbm;
    }
    if (matchStopReason == MatchStopReason.None) {
      matchStopReason = MatchStopReason.BookExhausted;
    }
  }

  // Internal Order Placement.
  //
  // Match our order against up to maxMatches resting orders at the given price (which
  // is known by the caller to have at least one resting order).
  //
  // The matches (partial or complete) of the resting orders are recorded, and their
  // funds are credited.
  //
  // The order chain for the resting orders is updated, but the occupied price bitmap is NOT -
  // the caller must clear the relevant bit if removedLastAtPrice = true is returned.
  //
  // Only updates the executedBase and executedCntr of our order - caller is responsible
  // for e.g. crediting our matched funds, updating status.
  //
  // Calling with maxMatches == 0 is ok - and expected when the order is a maker-only order.
  //
  // Returns:
  //   removedLastAtPrice:
  //     true iff there are no longer any resting orders at this price - caller will need
  //     to update the occupied price bitmap.
  //
  //   matchesLeft:
  //     maxMatches passed in minus the number of matches made by this call
  //
  //   matchStopReason:
  //     If our order is completely matched, matchStopReason will be Satisfied.
  //     If our order is not completely matched, matchStopReason will be either:
  //        MaxMatches (we are not allowed to match any more times)
  //     or:
  //        PriceExhausted (nothing left on the book at this exact price)
  //
  function matchWithOccupiedPrice(
      Order storage ourOrder, uint16 theirPrice, uint maxMatches
    ) internal returns (
    bool removedLastAtPrice, uint matchesLeft, MatchStopReason matchStopReason) {
    matchesLeft = maxMatches;
    uint workingOurExecutedBase = ourOrder.executedBase;
    uint workingOurExecutedCntr = ourOrder.executedCntr;
    uint128 theirOrderId = orderChainForOccupiedPrice[theirPrice].firstOrderId;
    matchStopReason = MatchStopReason.None;
    while (true) {
      if (matchesLeft == 0) {
        matchStopReason = MatchStopReason.MaxMatches;
        break;
      }
      uint matchBase;
      uint matchCntr;
      (theirOrderId, matchBase, matchCntr, matchStopReason) =
        matchWithTheirs((ourOrder.sizeBase - workingOurExecutedBase), theirOrderId, theirPrice);
      workingOurExecutedBase += matchBase;
      workingOurExecutedCntr += matchCntr;
      matchesLeft -= 1;
      if (matchStopReason != MatchStopReason.None) {
        break;
      }
    }
    ourOrder.executedBase = uint128(workingOurExecutedBase);
    ourOrder.executedCntr = uint128(workingOurExecutedCntr);
    if (theirOrderId == 0) {
      orderChainForOccupiedPrice[theirPrice].firstOrderId = 0;
      orderChainForOccupiedPrice[theirPrice].lastOrderId = 0;
      removedLastAtPrice = true;
    } else {
      // NB: in some cases (e.g. maxMatches == 0) this is a no-op.
      orderChainForOccupiedPrice[theirPrice].firstOrderId = theirOrderId;
      orderChainNodeForOpenOrderId[theirOrderId].prevOrderId = 0;
      removedLastAtPrice = false;
    }
  }
  
  // Internal Order Placement.
  //
  // Match up to our remaining amount against a resting order in the book.
  //
  // The match (partial, complete or effectively-complete) of the resting order
  // is recorded, and their funds are credited.
  //
  // Their order is NOT removed from the book by this call - the caller must do that
  // if the nextTheirOrderId returned is not equal to the theirOrderId passed in.
  //
  // Returns:
  //
  //   nextTheirOrderId:
  //     If we did not completely match their order, will be same as theirOrderId.
  //     If we completely matched their order, will be orderId of next order at the
  //     same price - or zero if this was the last order and we&#39;ve now filled it.
  //
  //   matchStopReason:
  //     If our order is completely matched, matchStopReason will be Satisfied.
  //     If our order is not completely matched, matchStopReason will be either
  //     PriceExhausted (if nothing left at this exact price) or None (if can continue).
  // 
  function matchWithTheirs(
    uint ourRemainingBase, uint128 theirOrderId, uint16 theirPrice) internal returns (
    uint128 nextTheirOrderId, uint matchBase, uint matchCntr, MatchStopReason matchStopReason) {
    Order storage theirOrder = orderForOrderId[theirOrderId];
    uint theirRemainingBase = theirOrder.sizeBase - theirOrder.executedBase;
    if (ourRemainingBase < theirRemainingBase) {
      matchBase = ourRemainingBase;
    } else {
      matchBase = theirRemainingBase;
    }
    matchCntr = computeCntrAmountUsingPacked(matchBase, theirPrice);
    // It may seem a bit odd to stop here if our remaining amount is very small -
    // there could still be resting orders we can match it against. But the gas
    // cost of matching each order is quite high - potentially high enough to
    // wipe out the profit the taker hopes for from trading the tiny amount left.
    if ((ourRemainingBase - matchBase) < baseMinRemainingSize) {
      matchStopReason = MatchStopReason.Satisfied;
    } else {
      matchStopReason = MatchStopReason.None;
    }
    bool theirsDead = recordTheirMatch(theirOrder, theirOrderId, theirPrice, matchBase, matchCntr);
    if (theirsDead) {
      nextTheirOrderId = orderChainNodeForOpenOrderId[theirOrderId].nextOrderId;
      if (matchStopReason == MatchStopReason.None && nextTheirOrderId == 0) {
        matchStopReason = MatchStopReason.PriceExhausted;
      }
    } else {
      nextTheirOrderId = theirOrderId;
    }
  }

  // Internal Order Placement.
  //
  // Record match (partial or complete) of resting order, and credit them their funds.
  //
  // If their order is completely matched, the order is marked as done,
  // and "theirsDead" is returned as true.
  //
  // The order is NOT removed from the book by this call - the caller
  // must do that if theirsDead is true.
  //
  // No sanity checks are made - the caller must be sure the order is
  // not already done and has sufficient remaining. (Yes, we&#39;d like to
  // check here too but we cannot afford the gas).
  //
  function recordTheirMatch(
      Order storage theirOrder, uint128 theirOrderId, uint16 theirPrice, uint matchBase, uint matchCntr
    ) internal returns (bool theirsDead) {
    // they are a maker so no fees
    // overflow safe - see comments about baseMaxSize
    // executedBase cannot go > sizeBase due to logic in matchWithTheirs
    theirOrder.executedBase += uint128(matchBase);
    theirOrder.executedCntr += uint128(matchCntr);
    if (isBuyPrice(theirPrice)) {
      // they have bought base (using the counter they already paid when creating the order)
      balanceBaseForClient[theirOrder.client] += matchBase;
    } else {
      // they have bought counter (using the base they already paid when creating the order)
      balanceCntrForClient[theirOrder.client] += matchCntr;
    }
    uint stillRemainingBase = theirOrder.sizeBase - theirOrder.executedBase;
    // avoid leaving tiny amounts in the book - refund remaining if too small
    if (stillRemainingBase < baseMinRemainingSize) {
      refundUnmatchedAndFinish(theirOrderId, Status.Done, ReasonCode.None);
      // someone building an UI on top needs to know how much was match and how much was refund
      MarketOrderEvent(block.timestamp, theirOrderId, MarketOrderEventType.CompleteFill,
        theirPrice, matchBase + stillRemainingBase, matchBase);
      return true;
    } else {
      MarketOrderEvent(block.timestamp, theirOrderId, MarketOrderEventType.PartialFill,
        theirPrice, matchBase, matchBase);
      return false;
    }
  }

  // Internal Order Placement.
  //
  // Refund any unmatched funds in an order (based on executed vs size) and move to a final state.
  //
  // The order is NOT removed from the book by this call and no event is raised.
  //
  // No sanity checks are made - the caller must be sure the order has not already been refunded.
  //
  function refundUnmatchedAndFinish(uint128 orderId, Status status, ReasonCode reasonCode) internal {
    Order storage order = orderForOrderId[orderId];
    uint16 price = order.price;
    if (isBuyPrice(price)) {
      uint sizeCntr = computeCntrAmountUsingPacked(order.sizeBase, price);
      balanceCntrForClient[order.client] += sizeCntr - order.executedCntr;
    } else {
      balanceBaseForClient[order.client] += order.sizeBase - order.executedBase;
    }
    order.status = status;
    order.reasonCode = reasonCode;
  }

  // Internal Order Placement.
  //
  // Enter a not completely matched order into the book, marking the order as open.
  //
  // This updates the occupied price bitmap and chain.
  //
  // No sanity checks are made - the caller must be sure the order
  // has some unmatched amount and has been paid for!
  //
  function enterOrder(uint128 orderId) internal {
    Order storage order = orderForOrderId[orderId];
    uint16 price = order.price;
    OrderChain storage orderChain = orderChainForOccupiedPrice[price];
    OrderChainNode storage orderChainNode = orderChainNodeForOpenOrderId[orderId];
    if (orderChain.firstOrderId == 0) {
      orderChain.firstOrderId = orderId;
      orderChain.lastOrderId = orderId;
      orderChainNode.nextOrderId = 0;
      orderChainNode.prevOrderId = 0;
      uint bitmapIndex = price / 256;
      uint bitIndex = price % 256;
      occupiedPriceBitmaps[bitmapIndex] |= (2 ** bitIndex);
    } else {
      uint128 existingLastOrderId = orderChain.lastOrderId;
      OrderChainNode storage existingLastOrderChainNode = orderChainNodeForOpenOrderId[existingLastOrderId];
      orderChainNode.nextOrderId = 0;
      orderChainNode.prevOrderId = existingLastOrderId;
      existingLastOrderChainNode.nextOrderId = orderId;
      orderChain.lastOrderId = orderId;
    }
    MarketOrderEvent(block.timestamp, orderId, MarketOrderEventType.Add,
      price, order.sizeBase - order.executedBase, 0);
    order.status = Status.Open;
  }

  // Internal Order Placement.
  //
  // Charge the client for the cost of placing an order in the given direction.
  //
  // Return true if successful, false otherwise.
  //
  function debitFunds(
      address client, Direction direction, uint sizeBase, uint sizeCntr
    ) internal returns (bool success) {
    if (direction == Direction.Buy) {
      uint availableCntr = balanceCntrForClient[client];
      if (availableCntr < sizeCntr) {
        return false;
      }
      balanceCntrForClient[client] = availableCntr - sizeCntr;
      return true;
    } else if (direction == Direction.Sell) {
      uint availableBase = balanceBaseForClient[client];
      if (availableBase < sizeBase) {
        return false;
      }
      balanceBaseForClient[client] = availableBase - sizeBase;
      return true;
    } else {
      return false;
    }
  }

  // Public Book View
  // 
  // Intended for public book depth enumeration from web3 (or similar).
  //
  // Not suitable for use from a smart contract transaction - gas usage
  // could be very high if we have many orders at the same price.
  //
  // Start at the given inclusive price (and side) and walk down the book
  // (getting less aggressive) until we find some open orders or reach the
  // least aggressive price.
  //
  // Returns the price where we found the order(s), the depth at that price
  // (zero if none found), order count there, and the current blockNumber.
  //
  // (The blockNumber is handy if you&#39;re taking a snapshot which you intend
  //  to keep up-to-date with the market order events).
  //
  // To walk the book, the caller should start by calling walkBook with the
  // most aggressive buy price (Buy @ 999000).
  // If the price returned is the least aggressive buy price (Buy @ 0.000001),
  // the side is complete.
  // Otherwise, call walkBook again with the (packed) price returned + 1.
  // Then repeat for the sell side, starting with Sell @ 0.000001 and stopping
  // when Sell @ 999000 is returned.
  //
  function walkBook(uint16 fromPrice) public constant returns (
      uint16 price, uint depthBase, uint orderCount, uint blockNumber
    ) {
    uint priceStart = fromPrice;
    uint priceEnd = (isBuyPrice(fromPrice)) ? minBuyPrice : maxSellPrice;
    
    // See comments in matchAgainstBook re: how these crazy loops work.
    
    uint bmi = priceStart / 256;
    uint bti = priceStart % 256;
    uint bmiEnd = priceEnd / 256;
    uint btiEnd = priceEnd % 256;

    uint wbm = occupiedPriceBitmaps[bmi] >> bti;
    
    while (bmi < bmiEnd) {
      if (wbm == 0 || bti == 256) {
        bti = 0;
        bmi++;
        wbm = occupiedPriceBitmaps[bmi];
      } else {
        if ((wbm & 1) != 0) {
          // careful - copy-pasted in below loop
          price = uint16(bmi * 256 + bti);
          (depthBase, orderCount) = sumDepth(orderChainForOccupiedPrice[price].firstOrderId);
          return (price, depthBase, orderCount, block.number);
        }
        bti += 1;
        wbm /= 2;
      }
    }
    // we&#39;ve reached the last bitmap we need to search, stop at btiEnd not 256 this time.
    while (bti <= btiEnd && wbm != 0) {
      if ((wbm & 1) != 0) {
        // careful - copy-pasted in above loop
        price = uint16(bmi * 256 + bti);
        (depthBase, orderCount) = sumDepth(orderChainForOccupiedPrice[price].firstOrderId);
        return (price, depthBase, orderCount, block.number);
      }
      bti += 1;
      wbm /= 2;
    }
    return (uint16(priceEnd), 0, 0, block.number);
  }

  // Internal Book View.
  //
  // See walkBook - adds up open depth at a price starting from an
  // order which is assumed to be open. Careful - unlimited gas use.
  //
  function sumDepth(uint128 orderId) internal constant returns (uint depth, uint orderCount) {
    while (true) {
      Order storage order = orderForOrderId[orderId];
      depth += order.sizeBase - order.executedBase;
      orderCount++;
      orderId = orderChainNodeForOpenOrderId[orderId].nextOrderId;
      if (orderId == 0) {
        return (depth, orderCount);
      }
    }
  }
}
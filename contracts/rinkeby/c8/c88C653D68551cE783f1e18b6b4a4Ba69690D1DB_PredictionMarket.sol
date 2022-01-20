pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./RealitioERC20.sol";

// openzeppelin imports
import "@openzeppelin/contracts/math/SafeMath.sol";

library CeilDiv {
  // calculates ceil(x/y)
  function ceildiv(uint256 x, uint256 y) internal pure returns (uint256) {
    if (x > 0) return ((x - 1) / y) + 1;
    return x / y;
  }
}

/// @title Market Contract Factory
contract PredictionMarket {
  using SafeMath for uint256;
  using CeilDiv for uint256;

  // ------ Events ------

  event MarketCreated(address indexed user, uint256 indexed marketId, uint256 outcomes, string question, string image);

  event MarketActionTx(
    address indexed user,
    MarketAction indexed action,
    uint256 indexed marketId,
    uint256 outcomeId,
    uint256 shares,
    uint256 value,
    uint256 timestamp
  );

  event MarketOutcomePrice(uint256 indexed marketId, uint256 indexed outcomeId, uint256 value, uint256 timestamp);

  event MarketLiquidity(
    uint256 indexed marketId,
    uint256 value, // total liquidity
    uint256 price, // value of one liquidity share; max: 1 (50-50 situation)
    uint256 timestamp
  );

  event MarketResolved(address indexed user, uint256 indexed marketId, uint256 outcomeId, uint256 timestamp);

  // ------ Events End ------

  uint256 public constant MAX_UINT_256 = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

  uint256 public constant ONE = 10**18;

  enum MarketState {
    open,
    closed,
    resolved
  }
  enum MarketAction {
    buy,
    sell,
    addLiquidity,
    removeLiquidity,
    claimWinnings,
    claimLiquidity,
    claimFees,
    claimVoided
  }

  struct Market {
    // market details
    uint256 closesAtTimestamp;
    uint256 balance; // total stake
    uint256 liquidity; // stake held
    uint256 sharesAvailable; // shares held (all outcomes)
    mapping(address => uint256) liquidityShares;
    mapping(address => bool) liquidityClaims; // wether user has claimed liquidity earnings
    MarketState state; // resolution variables
    MarketResolution resolution; // fees
    MarketFees fees;
    // market outcomes
    uint256[] outcomeIds;
    mapping(uint256 => MarketOutcome) outcomes;
  }

  struct MarketFees {
    uint256 value; // fee % taken from every transaction
    uint256 poolWeight; // internal var used to ensure pro-rate fee distribution
    mapping(address => uint256) claimed;
  }

  struct MarketResolution {
    bool resolved;
    uint256 outcomeId;
    bytes32 questionId; // realitio questionId
  }

  struct MarketOutcome {
    uint256 marketId;
    uint256 id;
    Shares shares;
  }

  struct Shares {
    uint256 total; // number of shares
    uint256 available; // available shares
    mapping(address => uint256) holders;
    mapping(address => bool) claims; // wether user has claimed winnings
    mapping(address => bool) voidedClaims; // wether user has claimed voided market shares
  }

  uint256[] marketIds;
  mapping(uint256 => Market) markets;
  uint256 public marketIndex;

  // governance
  uint256 public fee; // fee % taken from every transaction
  address public treasury;
  // realitio configs
  address public realitioAddress;
  uint256 public realitioTimeout;
  // market creation
  IERC20 public token; // token used for rewards / market creation
  uint256 public requiredBalance; // required balance for market creation

  // ------ Modifiers ------

  modifier isMarket(uint256 marketId) {
    require(marketId < marketIndex, "Market not found");
    _;
  }

  modifier timeTransitions(uint256 marketId) {
    if (now > markets[marketId].closesAtTimestamp && markets[marketId].state == MarketState.open) {
      nextState(marketId);
    }
    _;
  }

  modifier atState(uint256 marketId, MarketState state) {
    require(markets[marketId].state == state, "Market in incorrect state");
    _;
  }

  modifier notAtState(uint256 marketId, MarketState state) {
    require(markets[marketId].state != state, "Market in incorrect state");
    _;
  }

  modifier transitionNext(uint256 marketId) {
    _;
    nextState(marketId);
  }

  modifier mustHoldRequiredBalance() {
    require(token.balanceOf(msg.sender) >= requiredBalance, "msg.sender must hold minimum erc20 balance");
    _;
  }

  // ------ Modifiers End ------

  /// @dev protocol is immutable and has no ownership
  constructor(
    uint256 _fee,
    IERC20 _token,
    uint256 _requiredBalance,
    address _realitioAddress,
    uint256 _realitioTimeout,
    address _treasury
  ) public {
    require(_realitioAddress != address(0), "_realitioAddress is address 0");
    require(_realitioTimeout > 0, "timeout must be positive");

    fee = _fee;
    token = _token;
    requiredBalance = _requiredBalance;
    realitioAddress = _realitioAddress;
    realitioTimeout = _realitioTimeout;
    treasury = _treasury;
  }

  // ------ Core Functions ------

  /// @dev Creates a market, initializes the outcome shares pool and submits a question in Realitio
  function createMarket(
    string calldata question,
    string calldata image,
    uint256 closesAt,
    address arbitrator,
    uint256 outcomes
  ) external payable mustHoldRequiredBalance() returns (uint256) {
    uint256 marketId = marketIndex;
    marketIds.push(marketId);

    Market storage market = markets[marketId];

    require(msg.value > 0, "stake needs to be > 0");
    require(closesAt > now, "market must resolve after the current date");
    require(arbitrator != address(0), "invalid arbitrator address");
    // v1 - only binary markets
    require(outcomes == 2, "number of outcomes has to be 2");

    market.closesAtTimestamp = closesAt;
    market.state = MarketState.open;
    market.fees.value = fee;
    // setting intial value to an integer that does not map to any outcomeId
    market.resolution.outcomeId = MAX_UINT_256;

    // creating market outcomes
    for (uint256 i = 0; i < outcomes; i++) {
      market.outcomeIds.push(i);
      MarketOutcome storage outcome = market.outcomes[i];

      outcome.marketId = marketId;
      outcome.id = i;
    }

    // creating question in realitio
    RealitioERC20 realitio = RealitioERC20(realitioAddress);

    market.resolution.questionId = realitio.askQuestionERC20(
      2,
      question,
      arbitrator,
      uint32(realitioTimeout),
      uint32(closesAt),
      0,
      0
    );

    addLiquidity(marketId, msg.value);

    // emiting initial price events
    emitMarketOutcomePriceEvents(marketId);
    emit MarketCreated(msg.sender, marketId, outcomes, question, image);

    // incrementing market array index
    marketIndex = marketIndex + 1;

    return marketId;
  }

  /// @dev Calculates the number of shares bought with "amount" balance
  function calcBuyAmount(
    uint256 amount,
    uint256 marketId,
    uint256 outcomeId
  ) public view returns (uint256) {
    Market storage market = markets[marketId];

    uint256[] memory outcomesShares = getMarketOutcomesShares(marketId);
    uint256 amountMinusFees = amount.sub(amount.mul(market.fees.value) / ONE);
    uint256 buyTokenPoolBalance = outcomesShares[outcomeId];
    uint256 endingOutcomeBalance = buyTokenPoolBalance.mul(ONE);
    for (uint256 i = 0; i < outcomesShares.length; i++) {
      if (i != outcomeId) {
        uint256 outcomeShares = outcomesShares[i];
        endingOutcomeBalance = endingOutcomeBalance.mul(outcomeShares).ceildiv(outcomeShares.add(amountMinusFees));
      }
    }
    require(endingOutcomeBalance > 0, "must have non-zero balances");

    return buyTokenPoolBalance.add(amountMinusFees).sub(endingOutcomeBalance.ceildiv(ONE));
  }

  /// @dev Calculates the number of shares needed to be sold in order to receive "amount" in balance
  function calcSellAmount(
    uint256 amount,
    uint256 marketId,
    uint256 outcomeId
  ) public view returns (uint256 outcomeTokenSellAmount) {
    Market storage market = markets[marketId];

    uint256[] memory outcomesShares = getMarketOutcomesShares(marketId);
    uint256 amountPlusFees = amount.mul(ONE) / ONE.sub(market.fees.value);
    uint256 sellTokenPoolBalance = outcomesShares[outcomeId];
    uint256 endingOutcomeBalance = sellTokenPoolBalance.mul(ONE);
    for (uint256 i = 0; i < outcomesShares.length; i++) {
      if (i != outcomeId) {
        uint256 outcomeShares = outcomesShares[i];
        endingOutcomeBalance = endingOutcomeBalance.mul(outcomeShares).ceildiv(outcomeShares.sub(amountPlusFees));
      }
    }
    require(endingOutcomeBalance > 0, "must have non-zero balances");

    return amountPlusFees.add(endingOutcomeBalance.ceildiv(ONE)).sub(sellTokenPoolBalance);
  }

  /// @dev Buy shares of a market outcome
  function buy(
    uint256 marketId,
    uint256 outcomeId,
    uint256 minOutcomeSharesToBuy
  ) external payable timeTransitions(marketId) atState(marketId, MarketState.open) {
    Market storage market = markets[marketId];

    uint256 value = msg.value;
    uint256 shares = calcBuyAmount(value, marketId, outcomeId);
    require(shares >= minOutcomeSharesToBuy, "minimum buy amount not reached");
    require(shares > 0, "shares amount is 0");

    // subtracting fee from transaction value
    uint256 feeAmount = value.mul(market.fees.value) / ONE;
    market.fees.poolWeight = market.fees.poolWeight.add(feeAmount / 2);
    {
      (bool sent,) = payable(treasury).call{ value: feeAmount - feeAmount / 2 }("");
      require(sent, "PredictionMarket: fail to send value to platform fee address");
    }
    uint256 valueMinusFees = value.sub(feeAmount);

    MarketOutcome storage outcome = market.outcomes[outcomeId];

    // Funding market shares with received funds
    addSharesToMarket(marketId, valueMinusFees);

    require(outcome.shares.available >= shares, "outcome shares pool balance is too low");

    transferOutcomeSharesfromPool(msg.sender, marketId, outcomeId, shares);

    emit MarketActionTx(msg.sender, MarketAction.buy, marketId, outcomeId, shares, value, now);
    emitMarketOutcomePriceEvents(marketId);
  }

  /// @dev Sell shares of a market outcome
  function sell(
    uint256 marketId,
    uint256 outcomeId,
    uint256 value,
    uint256 maxOutcomeSharesToSell
  ) external payable timeTransitions(marketId) atState(marketId, MarketState.open) {
    Market storage market = markets[marketId];
    MarketOutcome storage outcome = market.outcomes[outcomeId];

    uint256 shares = calcSellAmount(value, marketId, outcomeId);

    require(shares <= maxOutcomeSharesToSell, "maximum sell amount exceeded");
    require(shares > 0, "shares amount is 0");
    require(outcome.shares.holders[msg.sender] >= shares, "user does not have enough balance");

    transferOutcomeSharesToPool(msg.sender, marketId, outcomeId, shares);

    // adding fee to transaction value
    uint256 feeAmount = value.mul(market.fees.value) / (ONE.sub(fee));
    market.fees.poolWeight = market.fees.poolWeight.add(feeAmount / 2);
    {
      (bool sent,) = payable(treasury).call{ value: feeAmount - feeAmount / 2 }("");
      require(sent, "PredictionMarket: fail to send value to platform fee address");
    }
    uint256 valuePlusFees = value.add(feeAmount);

    require(market.balance >= valuePlusFees, "market does not have enough balance");

    // Rebalancing market shares
    removeSharesFromMarket(marketId, valuePlusFees);

    // Transferring funds to user
    msg.sender.transfer(value);

    emit MarketActionTx(msg.sender, MarketAction.sell, marketId, outcomeId, shares, value, now);
    emitMarketOutcomePriceEvents(marketId);
  }

  /// @dev Adds liquidity to a market - external
  function addLiquidity(uint256 marketId)
    external
    payable
    timeTransitions(marketId)
    atState(marketId, MarketState.open)
  {
    addLiquidity(marketId, msg.value);
  }

  /// @dev Private function, used by addLiquidity and CreateMarket
  function addLiquidity(uint256 marketId, uint256 value)
    private
    timeTransitions(marketId)
    atState(marketId, MarketState.open)
  {
    Market storage market = markets[marketId];

    require(value > 0, "stake has to be greater than 0.");

    uint256 liquidityAmount;

    uint256[] memory outcomesShares = getMarketOutcomesShares(marketId);
    uint256[] memory sendBackAmounts = new uint256[](outcomesShares.length);
    uint256 poolWeight = 0;

    if (market.liquidity > 0) {
      // part of the liquidity is exchanged for outcome shares if market is not balanced
      for (uint256 i = 0; i < outcomesShares.length; i++) {
        uint256 outcomeShares = outcomesShares[i];
        if (poolWeight < outcomeShares) poolWeight = outcomeShares;
      }

      for (uint256 i = 0; i < outcomesShares.length; i++) {
        uint256 remaining = value.mul(outcomesShares[i]) / poolWeight;
        sendBackAmounts[i] = value.sub(remaining);
      }

      liquidityAmount = value.mul(market.liquidity) / poolWeight;

      // re-balancing fees pool
      rebalanceFeesPool(marketId, liquidityAmount, MarketAction.addLiquidity);
    } else {
      // funding market with no liquidity
      liquidityAmount = value;
    }

    // funding market
    market.liquidity = market.liquidity.add(liquidityAmount);
    market.liquidityShares[msg.sender] = market.liquidityShares[msg.sender].add(liquidityAmount);

    addSharesToMarket(marketId, value);

    // transform sendBackAmounts to array of amounts added
    for (uint256 i = 0; i < sendBackAmounts.length; i++) {
      if (sendBackAmounts[i] > 0) {
        uint256 marketShares = market.sharesAvailable;
        uint256 outcomeShares = market.outcomes[i].shares.available;
        transferOutcomeSharesfromPool(msg.sender, marketId, i, sendBackAmounts[i]);
        emit MarketActionTx(
          msg.sender,
          MarketAction.buy,
          marketId,
          i,
          sendBackAmounts[i],
          (marketShares.sub(outcomeShares)).mul(sendBackAmounts[i]).div(market.sharesAvailable), // price * shares
          now
        );
      }
    }

    uint256 liquidityPrice = getMarketLiquidityPrice(marketId);
    uint256 liquidityValue = liquidityPrice.mul(liquidityAmount) / ONE;
    emit MarketActionTx(msg.sender, MarketAction.addLiquidity, marketId, 0, liquidityAmount, liquidityValue, now);
    emit MarketLiquidity(marketId, market.liquidity, liquidityPrice, now);
  }

  /// @dev Removes liquidity to a market - external
  function removeLiquidity(uint256 marketId, uint256 shares)
    external
    payable
    timeTransitions(marketId)
    atState(marketId, MarketState.open)
  {
    Market storage market = markets[marketId];

    require(market.liquidityShares[msg.sender] >= shares, "user does not have enough balance");
    // claiming any pending fees
    claimFees(marketId);

    // re-balancing fees pool
    rebalanceFeesPool(marketId, shares, MarketAction.removeLiquidity);

    uint256[] memory outcomesShares = getMarketOutcomesShares(marketId);
    uint256[] memory sendAmounts = new uint256[](outcomesShares.length);
    uint256 poolWeight = MAX_UINT_256;

    // part of the liquidity is exchanged for outcome shares if market is not balanced
    for (uint256 i = 0; i < outcomesShares.length; i++) {
      uint256 outcomeShares = outcomesShares[i];
      if (poolWeight > outcomeShares) poolWeight = outcomeShares;
    }

    uint256 liquidityAmount = shares.mul(poolWeight).div(market.liquidity);

    for (uint256 i = 0; i < outcomesShares.length; i++) {
      sendAmounts[i] = outcomesShares[i].mul(shares) / market.liquidity;
      sendAmounts[i] = sendAmounts[i].sub(liquidityAmount);
    }

    // removing liquidity from market
    removeSharesFromMarket(marketId, liquidityAmount);
    market.liquidity = market.liquidity.sub(shares);
    // removing liquidity tokens from market creator
    market.liquidityShares[msg.sender] = market.liquidityShares[msg.sender].sub(shares);

    for (uint256 i = 0; i < outcomesShares.length; i++) {
      if (sendAmounts[i] > 0) {
        uint256 marketShares = market.sharesAvailable;
        uint256 outcomeShares = market.outcomes[i].shares.available;

        transferOutcomeSharesfromPool(msg.sender, marketId, i, sendAmounts[i]);
        emit MarketActionTx(
          msg.sender,
          MarketAction.buy,
          marketId,
          i,
          sendAmounts[i],
          (marketShares.sub(outcomeShares)).mul(sendAmounts[i]).div(market.sharesAvailable), // price * shares
          now
        );
      }
    }

    // transferring user funds from liquidity removed
    msg.sender.transfer(liquidityAmount);

    emit MarketActionTx(msg.sender, MarketAction.removeLiquidity, marketId, 0, shares, liquidityAmount, now);
    emit MarketLiquidity(marketId, market.liquidity, getMarketLiquidityPrice(marketId), now);
  }

  /// @dev Fetches winning outcome from Realitio and resolves the market
  function resolveMarketOutcome(uint256 marketId)
    external
    timeTransitions(marketId)
    atState(marketId, MarketState.closed)
    transitionNext(marketId)
    returns (uint256)
  {
    Market storage market = markets[marketId];

    RealitioERC20 realitio = RealitioERC20(realitioAddress);
    // will fail if question is not finalized
    uint256 outcomeId = uint256(realitio.resultFor(market.resolution.questionId));

    market.resolution.outcomeId = outcomeId;

    emit MarketResolved(msg.sender, marketId, outcomeId, now);
    emitMarketOutcomePriceEvents(marketId);

    return market.resolution.outcomeId;
  }

  /// @dev Allows holders of resolved outcome shares to claim earnings.
  function claimWinnings(uint256 marketId) external atState(marketId, MarketState.resolved) {
    Market storage market = markets[marketId];
    MarketOutcome storage resolvedOutcome = market.outcomes[market.resolution.outcomeId];

    require(resolvedOutcome.shares.holders[msg.sender] > 0, "user does not hold resolved outcome shares");
    require(resolvedOutcome.shares.claims[msg.sender] == false, "user already claimed resolved outcome winnings");

    // 1 share => price = 1
    uint256 value = resolvedOutcome.shares.holders[msg.sender];

    // assuring market has enough funds
    require(market.balance >= value, "Market does not have enough balance");

    market.balance = market.balance.sub(value);
    resolvedOutcome.shares.claims[msg.sender] = true;

    emit MarketActionTx(
      msg.sender,
      MarketAction.claimWinnings,
      marketId,
      market.resolution.outcomeId,
      resolvedOutcome.shares.holders[msg.sender],
      value,
      now
    );

    msg.sender.transfer(value);
  }

  /// @dev Allows holders of voided outcome shares to claim balance back.
  function claimVoidedOutcomeShares(uint256 marketId, uint256 outcomeId)
    external
    atState(marketId, MarketState.resolved)
  {
    Market storage market = markets[marketId];
    MarketOutcome storage outcome = market.outcomes[outcomeId];

    require(outcome.shares.holders[msg.sender] > 0, "user does not hold outcome shares");
    require(outcome.shares.voidedClaims[msg.sender] == false, "user already claimed outcome shares");

    // voided market - shares are valued at last market price
    uint256 price = getMarketOutcomePrice(marketId, outcomeId);
    uint256 value = price.mul(outcome.shares.holders[msg.sender]).div(ONE);

    // assuring market has enough funds
    require(market.balance >= value, "Market does not have enough balance");

    market.balance = market.balance.sub(value);
    outcome.shares.voidedClaims[msg.sender] = true;

    emit MarketActionTx(
      msg.sender,
      MarketAction.claimVoided,
      marketId,
      outcomeId,
      outcome.shares.holders[msg.sender],
      value,
      now
    );

    msg.sender.transfer(value);
  }

  /// @dev Allows liquidity providers to claim earnings from liquidity providing.
  function claimLiquidity(uint256 marketId) external atState(marketId, MarketState.resolved) {
    Market storage market = markets[marketId];

    // claiming any pending fees
    claimFees(marketId);

    require(market.liquidityShares[msg.sender] > 0, "user does not hold liquidity shares");
    require(market.liquidityClaims[msg.sender] == false, "user already claimed liquidity winnings");

    // value = total resolved outcome pool shares * pool share (%)
    uint256 liquidityPrice = getMarketLiquidityPrice(marketId);
    uint256 value = liquidityPrice.mul(market.liquidityShares[msg.sender]) / ONE;

    // assuring market has enough funds
    require(market.balance >= value, "Market does not have enough balance");

    market.balance = market.balance.sub(value);
    market.liquidityClaims[msg.sender] = true;

    emit MarketActionTx(
      msg.sender,
      MarketAction.claimLiquidity,
      marketId,
      0,
      market.liquidityShares[msg.sender],
      value,
      now
    );

    msg.sender.transfer(value);
  }

  /// @dev Allows liquidity providers to claim their fees share from fees pool
  function claimFees(uint256 marketId) public payable {
    Market storage market = markets[marketId];

    uint256 claimableFees = getUserClaimableFees(marketId, msg.sender);

    if (claimableFees > 0) {
      market.fees.claimed[msg.sender] = market.fees.claimed[msg.sender].add(claimableFees);
      msg.sender.transfer(claimableFees);
    }

    emit MarketActionTx(
      msg.sender,
      MarketAction.claimFees,
      marketId,
      0,
      market.liquidityShares[msg.sender],
      claimableFees,
      now
    );
  }

  /// @dev Rebalances the fees pool. Needed in every AddLiquidity / RemoveLiquidity call
  function rebalanceFeesPool(
    uint256 marketId,
    uint256 liquidityShares,
    MarketAction action
  ) private returns (uint256) {
    Market storage market = markets[marketId];

    uint256 poolWeight = liquidityShares.mul(market.fees.poolWeight).div(market.liquidity);

    if (action == MarketAction.addLiquidity) {
      market.fees.poolWeight = market.fees.poolWeight.add(poolWeight);
      market.fees.claimed[msg.sender] = market.fees.claimed[msg.sender].add(poolWeight);
    } else {
      market.fees.poolWeight = market.fees.poolWeight.sub(poolWeight);
      market.fees.claimed[msg.sender] = market.fees.claimed[msg.sender].sub(poolWeight);
    }
  }

  /// @dev Transitions market to next state
  function nextState(uint256 marketId) private {
    Market storage market = markets[marketId];
    market.state = MarketState(uint256(market.state) + 1);
  }

  /// @dev Emits a outcome price event for every outcome
  function emitMarketOutcomePriceEvents(uint256 marketId) private {
    Market storage market = markets[marketId];

    for (uint256 i = 0; i < market.outcomeIds.length; i++) {
      emit MarketOutcomePrice(marketId, i, getMarketOutcomePrice(marketId, i), now);
    }

    // liquidity shares also change value
    emit MarketLiquidity(marketId, market.liquidity, getMarketLiquidityPrice(marketId), now);
  }

  /// @dev Adds outcome shares to shares pool
  function addSharesToMarket(uint256 marketId, uint256 shares) private {
    Market storage market = markets[marketId];

    for (uint256 i = 0; i < market.outcomeIds.length; i++) {
      MarketOutcome storage outcome = market.outcomes[i];

      outcome.shares.available = outcome.shares.available.add(shares);
      outcome.shares.total = outcome.shares.total.add(shares);

      // only adding to market total shares, the available remains
      market.sharesAvailable = market.sharesAvailable.add(shares);
    }

    market.balance = market.balance.add(shares);
  }

  /// @dev Removes outcome shares from shares pool
  function removeSharesFromMarket(uint256 marketId, uint256 shares) private {
    Market storage market = markets[marketId];

    for (uint256 i = 0; i < market.outcomeIds.length; i++) {
      MarketOutcome storage outcome = market.outcomes[i];

      outcome.shares.available = outcome.shares.available.sub(shares);
      outcome.shares.total = outcome.shares.total.sub(shares);

      // only subtracting from market total shares, the available remains
      market.sharesAvailable = market.sharesAvailable.sub(shares);
    }

    market.balance = market.balance.sub(shares);
  }

  /// @dev Transfer outcome shares from pool to user balance
  function transferOutcomeSharesfromPool(
    address user,
    uint256 marketId,
    uint256 outcomeId,
    uint256 shares
  ) private {
    Market storage market = markets[marketId];
    MarketOutcome storage outcome = market.outcomes[outcomeId];

    // transfering shares from shares pool to user
    outcome.shares.holders[user] = outcome.shares.holders[user].add(shares);
    outcome.shares.available = outcome.shares.available.sub(shares);
    market.sharesAvailable = market.sharesAvailable.sub(shares);
  }

  /// @dev Transfer outcome shares from user balance back to pool
  function transferOutcomeSharesToPool(
    address user,
    uint256 marketId,
    uint256 outcomeId,
    uint256 shares
  ) private {
    Market storage market = markets[marketId];
    MarketOutcome storage outcome = market.outcomes[outcomeId];

    // adding shares back to pool
    outcome.shares.holders[user] = outcome.shares.holders[user].sub(shares);
    outcome.shares.available = outcome.shares.available.add(shares);
    market.sharesAvailable = market.sharesAvailable.add(shares);
  }

  // ------ Core Functions End ------

  // ------ Getters ------

  function getUserMarketShares(uint256 marketId, address user)
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    Market storage market = markets[marketId];

    return (
      market.liquidityShares[user],
      market.outcomes[0].shares.holders[user],
      market.outcomes[1].shares.holders[user]
    );
  }

  function getUserClaimStatus(uint256 marketId, address user)
    external
    view
    returns (
      bool,
      bool,
      bool,
      bool,
      uint256
    )
  {
    Market storage market = markets[marketId];

    // market still not resolved
    if (market.state != MarketState.resolved) {
      return (false, false, false, false, getUserClaimableFees(marketId, user));
    }

    MarketOutcome storage outcome = market.outcomes[market.resolution.outcomeId];

    return (
      outcome.shares.holders[user] > 0,
      outcome.shares.claims[user],
      market.liquidityShares[user] > 0,
      market.liquidityClaims[user],
      getUserClaimableFees(marketId, user)
    );
  }

  function getUserLiquidityPoolShare(uint256 marketId, address user) external view returns (uint256) {
    Market storage market = markets[marketId];

    return market.liquidityShares[user].mul(ONE).div(market.liquidity);
  }

  function getUserClaimableFees(uint256 marketId, address user) public view returns (uint256) {
    Market storage market = markets[marketId];

    uint256 rawAmount = market.fees.poolWeight.mul(market.liquidityShares[user]).div(market.liquidity);

    // No fees left to claim
    if (market.fees.claimed[user] > rawAmount) return 0;

    return rawAmount.sub(market.fees.claimed[user]);
  }

  function getMarkets() external view returns (uint256[] memory) {
    return marketIds;
  }

  function getMarketData(uint256 marketId)
    external
    view
    returns (
      MarketState,
      uint256,
      uint256,
      uint256,
      uint256,
      int256
    )
  {
    Market storage market = markets[marketId];

    return (
      market.state,
      market.closesAtTimestamp,
      market.liquidity,
      market.balance,
      market.sharesAvailable,
      getMarketResolvedOutcome(marketId)
    );
  }

  function getMarketAltData(uint256 marketId)
    external
    view
    returns (
      uint256,
      bytes32,
      uint256
    )
  {
    Market storage market = markets[marketId];

    return (market.fees.value, market.resolution.questionId, uint256(market.resolution.questionId));
  }

  function getMarketQuestion(uint256 marketId) external view returns (bytes32) {
    Market storage market = markets[marketId];

    return (market.resolution.questionId);
  }

  function getMarketPrices(uint256 marketId)
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    return (getMarketLiquidityPrice(marketId), getMarketOutcomePrice(marketId, 0), getMarketOutcomePrice(marketId, 1));
  }

  function getMarketLiquidityPrice(uint256 marketId) public view returns (uint256) {
    Market storage market = markets[marketId];

    if (market.state == MarketState.resolved && !isMarketVoided(marketId)) {
      // resolved market, price is either 0 or 1
      // final liquidity price = outcome shares / liquidity shares
      return market.outcomes[market.resolution.outcomeId].shares.available.mul(ONE).div(market.liquidity);
    }

    // liquidity price = # liquidity shares / # outcome shares * # outcomes
    return market.liquidity.mul(ONE * market.outcomeIds.length).div(market.sharesAvailable);
  }

  function getMarketResolvedOutcome(uint256 marketId) public view returns (int256) {
    Market storage market = markets[marketId];

    // returning -1 if market still not resolved
    if (market.state != MarketState.resolved) {
      return -1;
    }

    return int256(market.resolution.outcomeId);
  }

  function isMarketVoided(uint256 marketId) public view returns (bool) {
    Market storage market = markets[marketId];

    // market still not resolved, still in valid state
    if (market.state != MarketState.resolved) {
      return false;
    }

    // resolved market id does not match any of the market ids
    return market.resolution.outcomeId >= market.outcomeIds.length;
  }

  // ------ Outcome Getters ------

  function getMarketOutcomeIds(uint256 marketId) external view returns (uint256[] memory) {
    Market storage market = markets[marketId];
    return market.outcomeIds;
  }

  function getMarketOutcomePrice(uint256 marketId, uint256 outcomeId) public view returns (uint256) {
    Market storage market = markets[marketId];
    MarketOutcome storage outcome = market.outcomes[outcomeId];

    if (market.state == MarketState.resolved && !isMarketVoided(marketId)) {
      // resolved market, price is either 0 or 1
      return outcomeId == market.resolution.outcomeId ? ONE : 0;
    }

    return (market.sharesAvailable.sub(outcome.shares.available)).mul(ONE).div(market.sharesAvailable);
  }

  function getMarketOutcomeData(uint256 marketId, uint256 outcomeId)
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    Market storage market = markets[marketId];
    MarketOutcome storage outcome = market.outcomes[outcomeId];

    return (getMarketOutcomePrice(marketId, outcomeId), outcome.shares.available, outcome.shares.total);
  }

  function getMarketOutcomesShares(uint256 marketId) private view returns (uint256[] memory) {
    Market storage market = markets[marketId];

    uint256[] memory shares = new uint256[](market.outcomeIds.length);
    for (uint256 i = 0; i < market.outcomeIds.length; i++) {
      shares[i] = market.outcomes[i].shares.available;
    }

    return shares;
  }
}

/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

pragma solidity >0.4.24;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}
pragma solidity >0.4.24;

/**
 * @title ReailtioSafeMath256
 * @dev Math operations with safety checks that throw on error
 */
library RealitioSafeMath256 {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
pragma solidity >0.4.24;

/**
 * @title RealitioSafeMath32
 * @dev Math operations with safety checks that throw on error
 * @dev Copy of SafeMath but for uint32 instead of uint256
 * @dev Deleted functions we don't use
 */
library RealitioSafeMath32 {
  function add(uint32 a, uint32 b) internal pure returns (uint32) {
    uint32 c = a + b;
    assert(c >= a);
    return c;
  }
}
pragma solidity >0.4.18;


contract BalanceHolder {

    IERC20 public token;

    mapping(address => uint256) public balanceOf;

    event LogWithdraw(
        address indexed user,
        uint256 amount
    );

    function withdraw()
    public {
        uint256 bal = balanceOf[msg.sender];
        balanceOf[msg.sender] = 0;
        require(token.transfer(msg.sender, bal));
        emit LogWithdraw(msg.sender, bal);
    }

}
pragma solidity >0.4.24;


contract RealitioERC20 is BalanceHolder {

    using RealitioSafeMath256 for uint256;
    using RealitioSafeMath32 for uint32;

    address constant NULL_ADDRESS = address(0);

    // History hash when no history is created, or history has been cleared
    bytes32 constant NULL_HASH = bytes32(0);

    // An unitinalized finalize_ts for a question will indicate an unanswered question.
    uint32 constant UNANSWERED = 0;

    // An unanswered reveal_ts for a commitment will indicate that it does not exist.
    uint256 constant COMMITMENT_NON_EXISTENT = 0;

    // Commit->reveal timeout is 1/8 of the question timeout (rounded down).
    uint32 constant COMMITMENT_TIMEOUT_RATIO = 8;

    event LogSetQuestionFee(
        address arbitrator,
        uint256 amount
    );

    event LogNewTemplate(
        uint256 indexed template_id,
        address indexed user,
        string question_text
    );

    event LogNewQuestion(
        bytes32 indexed question_id,
        address indexed user,
        uint256 template_id,
        string question,
        bytes32 indexed content_hash,
        address arbitrator,
        uint32 timeout,
        uint32 opening_ts,
        uint256 nonce,
        uint256 created
    );

    event LogFundAnswerBounty(
        bytes32 indexed question_id,
        uint256 bounty_added,
        uint256 bounty,
        address indexed user
    );

    event LogNewAnswer(
        bytes32 answer,
        bytes32 indexed question_id,
        bytes32 history_hash,
        address indexed user,
        uint256 bond,
        uint256 ts,
        bool is_commitment
    );

    event LogAnswerReveal(
        bytes32 indexed question_id,
        address indexed user,
        bytes32 indexed answer_hash,
        bytes32 answer,
        uint256 nonce,
        uint256 bond
    );

    event LogNotifyOfArbitrationRequest(
        bytes32 indexed question_id,
        address indexed user
    );

    event LogFinalize(
        bytes32 indexed question_id,
        bytes32 indexed answer
    );

    event LogClaim(
        bytes32 indexed question_id,
        address indexed user,
        uint256 amount
    );

    struct Question {
        bytes32 content_hash;
        address arbitrator;
        uint32 opening_ts;
        uint32 timeout;
        uint32 finalize_ts;
        bool is_pending_arbitration;
        uint256 bounty;
        bytes32 best_answer;
        bytes32 history_hash;
        uint256 bond;
    }

    // Stored in a mapping indexed by commitment_id, a hash of commitment hash, question, bond.
    struct Commitment {
        uint32 reveal_ts;
        bool is_revealed;
        bytes32 revealed_answer;
    }

    // Only used when claiming more bonds than fits into a transaction
    // Stored in a mapping indexed by question_id.
    struct Claim {
        address payee;
        uint256 last_bond;
        uint256 queued_funds;
    }

    uint256 nextTemplateID = 0;
    mapping(uint256 => uint256) public templates;
    mapping(uint256 => bytes32) public template_hashes;
    mapping(bytes32 => Question) public questions;
    mapping(bytes32 => Claim) public question_claims;
    mapping(bytes32 => Commitment) public commitments;
    mapping(address => uint256) public arbitrator_question_fees;

    modifier onlyArbitrator(bytes32 question_id) {
        require(msg.sender == questions[question_id].arbitrator, "msg.sender must be arbitrator");
        _;
    }

    modifier stateAny() {
        _;
    }

    modifier stateNotCreated(bytes32 question_id) {
        require(questions[question_id].timeout == 0, "question must not exist");
        _;
    }

    modifier stateOpen(bytes32 question_id) {
        require(questions[question_id].timeout > 0, "question must exist");
        require(!questions[question_id].is_pending_arbitration, "question must not be pending arbitration");
        uint32 finalize_ts = questions[question_id].finalize_ts;
        require(finalize_ts == UNANSWERED || finalize_ts > uint32(now), "finalization deadline must not have passed");
        uint32 opening_ts = questions[question_id].opening_ts;
        require(opening_ts == 0 || opening_ts <= uint32(now), "opening date must have passed");
        _;
    }

    modifier statePendingArbitration(bytes32 question_id) {
        require(questions[question_id].is_pending_arbitration, "question must be pending arbitration");
        _;
    }

    modifier stateOpenOrPendingArbitration(bytes32 question_id) {
        require(questions[question_id].timeout > 0, "question must exist");
        uint32 finalize_ts = questions[question_id].finalize_ts;
        require(finalize_ts == UNANSWERED || finalize_ts > uint32(now), "finalization dealine must not have passed");
        uint32 opening_ts = questions[question_id].opening_ts;
        require(opening_ts == 0 || opening_ts <= uint32(now), "opening date must have passed");
        _;
    }

    modifier stateFinalized(bytes32 question_id) {
        require(isFinalized(question_id), "question must be finalized");
        _;
    }

    modifier bondMustDouble(bytes32 question_id, uint256 tokens) {
        require(tokens > 0, "bond must be positive");
        require(tokens >= (questions[question_id].bond.mul(2)), "bond must be double at least previous bond");
        _;
    }

    modifier previousBondMustNotBeatMaxPrevious(bytes32 question_id, uint256 max_previous) {
        if (max_previous > 0) {
            require(questions[question_id].bond <= max_previous, "bond must exceed max_previous");
        }
        _;
    }

    function setToken(IERC20 _token)
    public
    {
        require(token == IERC20(0x0), "Token can only be initialized once");
        token = _token;
    }

    /// @notice Constructor, sets up some initial templates
    /// @dev Creates some generalized templates for different question types used in the DApp.
    constructor()
    public {
        createTemplate('{"title": "%s", "type": "bool", "category": "%s", "lang": "%s"}');
        createTemplate('{"title": "%s", "type": "uint", "decimals": 18, "category": "%s", "lang": "%s"}');
        createTemplate('{"title": "%s", "type": "single-select", "outcomes": [%s], "category": "%s", "lang": "%s"}');
        createTemplate('{"title": "%s", "type": "multiple-select", "outcomes": [%s], "category": "%s", "lang": "%s"}');
        createTemplate('{"title": "%s", "type": "datetime", "category": "%s", "lang": "%s"}');
    }

    /// @notice Function for arbitrator to set an optional per-question fee.
    /// @dev The per-question fee, charged when a question is asked, is intended as an anti-spam measure.
    /// @param fee The fee to be charged by the arbitrator when a question is asked
    function setQuestionFee(uint256 fee)
        stateAny()
    external {
        arbitrator_question_fees[msg.sender] = fee;
        emit LogSetQuestionFee(msg.sender, fee);
    }

    /// @notice Create a reusable template, which should be a JSON document.
    /// Placeholders should use gettext() syntax, eg %s.
    /// @dev Template data is only stored in the event logs, but its block number is kept in contract storage.
    /// @param content The template content
    /// @return The ID of the newly-created template, which is created sequentially.
    function createTemplate(string memory content)
        stateAny()
    public returns (uint256) {
        uint256 id = nextTemplateID;
        templates[id] = block.number;
        template_hashes[id] = keccak256(abi.encodePacked(content));
        emit LogNewTemplate(id, msg.sender, content);
        nextTemplateID = id.add(1);
        return id;
    }

    /// @notice Create a new reusable template and use it to ask a question
    /// @dev Template data is only stored in the event logs, but its block number is kept in contract storage.
    /// @param content The template content
    /// @param question A string containing the parameters that will be passed into the template to make the question
    /// @param arbitrator The arbitration contract that will have the final word on the answer if there is a dispute
    /// @param timeout How long the contract should wait after the answer is changed before finalizing on that answer
    /// @param opening_ts If set, the earliest time it should be possible to answer the question.
    /// @param nonce A user-specified nonce used in the question ID. Change it to repeat a question.
    /// @return The ID of the newly-created template, which is created sequentially.
    function createTemplateAndAskQuestion(
        string memory content,
        string memory question, address arbitrator, uint32 timeout, uint32 opening_ts, uint256 nonce
    )
        // stateNotCreated is enforced by the internal _askQuestion
    public returns (bytes32) {
        uint256 template_id = createTemplate(content);
        return askQuestion(template_id, question, arbitrator, timeout, opening_ts, nonce);
    }

    /// @notice Ask a new question without a bounty and return the ID
    /// @dev Template data is only stored in the event logs, but its block number is kept in contract storage.
    /// @dev Calling without the token param will only work if there is no arbitrator-set question fee.
    /// @dev This has the same function signature as askQuestion() in the non-ERC20 version, which is optionally payable.
    /// @param template_id The ID number of the template the question will use
    /// @param question A string containing the parameters that will be passed into the template to make the question
    /// @param arbitrator The arbitration contract that will have the final word on the answer if there is a dispute
    /// @param timeout How long the contract should wait after the answer is changed before finalizing on that answer
    /// @param opening_ts If set, the earliest time it should be possible to answer the question.
    /// @param nonce A user-specified nonce used in the question ID. Change it to repeat a question.
    /// @return The ID of the newly-created question, created deterministically.
    function askQuestion(uint256 template_id, string memory question, address arbitrator, uint32 timeout, uint32 opening_ts, uint256 nonce)
        // stateNotCreated is enforced by the internal _askQuestion
    public returns (bytes32) {

        require(templates[template_id] > 0, "template must exist");

        bytes32 content_hash = keccak256(abi.encodePacked(template_id, opening_ts, question));
        bytes32 question_id = keccak256(abi.encodePacked(content_hash, arbitrator, timeout, msg.sender, nonce));

        _askQuestion(question_id, content_hash, arbitrator, timeout, opening_ts, 0);
        emit LogNewQuestion(question_id, msg.sender, template_id, question, content_hash, arbitrator, timeout, opening_ts, nonce, now);

        return question_id;
    }

    /// @notice Ask a new question with a bounty and return the ID
    /// @dev Template data is only stored in the event logs, but its block number is kept in contract storage.
    /// @param template_id The ID number of the template the question will use
    /// @param question A string containing the parameters that will be passed into the template to make the question
    /// @param arbitrator The arbitration contract that will have the final word on the answer if there is a dispute
    /// @param timeout How long the contract should wait after the answer is changed before finalizing on that answer
    /// @param opening_ts If set, the earliest time it should be possible to answer the question.
    /// @param nonce A user-specified nonce used in the question ID. Change it to repeat a question.
    /// @param tokens The combined initial question bounty and question fee
    /// @return The ID of the newly-created question, created deterministically.
    function askQuestionERC20(uint256 template_id, string memory question, address arbitrator, uint32 timeout, uint32 opening_ts, uint256 nonce, uint256 tokens)
        // stateNotCreated is enforced by the internal _askQuestion
    public returns (bytes32) {

        _deductTokensOrRevert(tokens);

        require(templates[template_id] > 0, "template must exist");

        bytes32 content_hash = keccak256(abi.encodePacked(template_id, opening_ts, question));
        bytes32 question_id = keccak256(abi.encodePacked(content_hash, arbitrator, timeout, msg.sender, nonce));

        _askQuestion(question_id, content_hash, arbitrator, timeout, opening_ts, tokens);
        emit LogNewQuestion(question_id, msg.sender, template_id, question, content_hash, arbitrator, timeout, opening_ts, nonce, now);

        return question_id;
    }

    function _deductTokensOrRevert(uint256 tokens)
    internal {

        if (tokens == 0) {
            return;
        }

        uint256 bal = balanceOf[msg.sender];

        // Deduct any tokens you have in your internal balance first
        if (bal > 0) {
            if (bal >= tokens) {
                balanceOf[msg.sender] = bal.sub(tokens);
                return;
            } else {
                tokens = tokens.sub(bal);
                balanceOf[msg.sender] = 0;
            }
        }
        // Now we need to charge the rest from
        require(token.transferFrom(msg.sender, address(this), tokens), "Transfer of tokens failed, insufficient approved balance?");
        return;

    }

    function _askQuestion(bytes32 question_id, bytes32 content_hash, address arbitrator, uint32 timeout, uint32 opening_ts, uint256 tokens)
        stateNotCreated(question_id)
    internal {

        uint256 bounty = tokens;

        // A timeout of 0 makes no sense, and we will use this to check existence
        require(timeout > 0, "timeout must be positive");
        require(timeout < 365 days, "timeout must be less than 365 days");
        require(arbitrator != NULL_ADDRESS, "arbitrator must be set");

        // The arbitrator can set a fee for asking a question.
        // This is intended as an anti-spam defence.
        // The fee is waived if the arbitrator is asking the question.
        // This allows them to set an impossibly high fee and make users proxy the question through them.
        // This would allow more sophisticated pricing, question whitelisting etc.
        if (msg.sender != arbitrator) {
            uint256 question_fee = arbitrator_question_fees[arbitrator];
            require(bounty >= question_fee, "Tokens provided must cover question fee");
            bounty = bounty.sub(question_fee);
            balanceOf[arbitrator] = balanceOf[arbitrator].add(question_fee);
        }

        questions[question_id].content_hash = content_hash;
        questions[question_id].arbitrator = arbitrator;
        questions[question_id].opening_ts = opening_ts;
        questions[question_id].timeout = timeout;
        questions[question_id].bounty = bounty;

    }

    /// @notice Add funds to the bounty for a question
    /// @dev Add bounty funds after the initial question creation. Can be done any time until the question is finalized.
    /// @param question_id The ID of the question you wish to fund
    /// @param tokens The number of tokens to fund
    function fundAnswerBountyERC20(bytes32 question_id, uint256 tokens)
        stateOpen(question_id)
    external {
        _deductTokensOrRevert(tokens);
        questions[question_id].bounty = questions[question_id].bounty.add(tokens);
        emit LogFundAnswerBounty(question_id, tokens, questions[question_id].bounty, msg.sender);
    }

    /// @notice Submit an answer for a question.
    /// @dev Adds the answer to the history and updates the current "best" answer.
    /// May be subject to front-running attacks; Substitute submitAnswerCommitment()->submitAnswerReveal() to prevent them.
    /// @param question_id The ID of the question
    /// @param answer The answer, encoded into bytes32
    /// @param max_previous If specified, reverts if a bond higher than this was submitted after you sent your transaction.
    /// @param tokens The amount of tokens to submit
    function submitAnswerERC20(bytes32 question_id, bytes32 answer, uint256 max_previous, uint256 tokens)
        stateOpen(question_id)
        bondMustDouble(question_id, tokens)
        previousBondMustNotBeatMaxPrevious(question_id, max_previous)
    external {
        _deductTokensOrRevert(tokens);
        _addAnswerToHistory(question_id, answer, msg.sender, tokens, false);
        _updateCurrentAnswer(question_id, answer, questions[question_id].timeout);
    }

    // @notice Verify and store a commitment, including an appropriate timeout
    // @param question_id The ID of the question to store
    // @param commitment The ID of the commitment
    function _storeCommitment(bytes32 question_id, bytes32 commitment_id)
    internal
    {
        require(commitments[commitment_id].reveal_ts == COMMITMENT_NON_EXISTENT, "commitment must not already exist");

        uint32 commitment_timeout = questions[question_id].timeout / COMMITMENT_TIMEOUT_RATIO;
        commitments[commitment_id].reveal_ts = uint32(now).add(commitment_timeout);
    }

    /// @notice Submit the hash of an answer, laying your claim to that answer if you reveal it in a subsequent transaction.
    /// @dev Creates a hash, commitment_id, uniquely identifying this answer, to this question, with this bond.
    /// The commitment_id is stored in the answer history where the answer would normally go.
    /// Does not update the current best answer - this is left to the later submitAnswerReveal() transaction.
    /// @param question_id The ID of the question
    /// @param answer_hash The hash of your answer, plus a nonce that you will later reveal
    /// @param max_previous If specified, reverts if a bond higher than this was submitted after you sent your transaction.
    /// @param _answerer If specified, the address to be given as the question answerer. Defaults to the sender.
    /// @param tokens Number of tokens sent
    /// @dev Specifying the answerer is useful if you want to delegate the commit-and-reveal to a third-party.
    function submitAnswerCommitmentERC20(bytes32 question_id, bytes32 answer_hash, uint256 max_previous, address _answerer, uint256 tokens)
        stateOpen(question_id)
        bondMustDouble(question_id, tokens)
        previousBondMustNotBeatMaxPrevious(question_id, max_previous)
    external {

        _deductTokensOrRevert(tokens);

        bytes32 commitment_id = keccak256(abi.encodePacked(question_id, answer_hash, tokens));
        address answerer = (_answerer == NULL_ADDRESS) ? msg.sender : _answerer;

        _storeCommitment(question_id, commitment_id);
        _addAnswerToHistory(question_id, commitment_id, answerer, tokens, true);

    }

    /// @notice Submit the answer whose hash you sent in a previous submitAnswerCommitment() transaction
    /// @dev Checks the parameters supplied recreate an existing commitment, and stores the revealed answer
    /// Updates the current answer unless someone has since supplied a new answer with a higher bond
    /// msg.sender is intentionally not restricted to the user who originally sent the commitment;
    /// For example, the user may want to provide the answer+nonce to a third-party service and let them send the tx
    /// NB If we are pending arbitration, it will be up to the arbitrator to wait and see any outstanding reveal is sent
    /// @param question_id The ID of the question
    /// @param answer The answer, encoded as bytes32
    /// @param nonce The nonce that, combined with the answer, recreates the answer_hash you gave in submitAnswerCommitment()
    /// @param bond The bond that you paid in your submitAnswerCommitment() transaction
    function submitAnswerReveal(bytes32 question_id, bytes32 answer, uint256 nonce, uint256 bond)
        stateOpenOrPendingArbitration(question_id)
    external {

        bytes32 answer_hash = keccak256(abi.encodePacked(answer, nonce));
        bytes32 commitment_id = keccak256(abi.encodePacked(question_id, answer_hash, bond));

        require(!commitments[commitment_id].is_revealed, "commitment must not have been revealed yet");
        require(commitments[commitment_id].reveal_ts > uint32(now), "reveal deadline must not have passed");

        commitments[commitment_id].revealed_answer = answer;
        commitments[commitment_id].is_revealed = true;

        if (bond == questions[question_id].bond) {
            _updateCurrentAnswer(question_id, answer, questions[question_id].timeout);
        }

        emit LogAnswerReveal(question_id, msg.sender, answer_hash, answer, nonce, bond);

    }

    function _addAnswerToHistory(bytes32 question_id, bytes32 answer_or_commitment_id, address answerer, uint256 bond, bool is_commitment)
    internal
    {
        bytes32 new_history_hash = keccak256(abi.encodePacked(questions[question_id].history_hash, answer_or_commitment_id, bond, answerer, is_commitment));

        // Update the current bond level, if there's a bond (ie anything except arbitration)
        if (bond > 0) {
            questions[question_id].bond = bond;
        }
        questions[question_id].history_hash = new_history_hash;

        emit LogNewAnswer(answer_or_commitment_id, question_id, new_history_hash, answerer, bond, now, is_commitment);
    }

    function _updateCurrentAnswer(bytes32 question_id, bytes32 answer, uint32 timeout_secs)
    internal {
        questions[question_id].best_answer = answer;
        questions[question_id].finalize_ts = uint32(now).add(timeout_secs);
    }

    /// @notice Notify the contract that the arbitrator has been paid for a question, freezing it pending their decision.
    /// @dev The arbitrator contract is trusted to only call this if they've been paid, and tell us who paid them.
    /// @param question_id The ID of the question
    /// @param requester The account that requested arbitration
    /// @param max_previous If specified, reverts if a bond higher than this was submitted after you sent your transaction.
    function notifyOfArbitrationRequest(bytes32 question_id, address requester, uint256 max_previous)
        onlyArbitrator(question_id)
        stateOpen(question_id)
        previousBondMustNotBeatMaxPrevious(question_id, max_previous)
    external {
        require(questions[question_id].bond > 0, "Question must already have an answer when arbitration is requested");
        questions[question_id].is_pending_arbitration = true;
        emit LogNotifyOfArbitrationRequest(question_id, requester);
    }

    /// @notice Submit the answer for a question, for use by the arbitrator.
    /// @dev Doesn't require (or allow) a bond.
    /// If the current final answer is correct, the account should be whoever submitted it.
    /// If the current final answer is wrong, the account should be whoever paid for arbitration.
    /// However, the answerer stipulations are not enforced by the contract.
    /// @param question_id The ID of the question
    /// @param answer The answer, encoded into bytes32
    /// @param answerer The account credited with this answer for the purpose of bond claims
    function submitAnswerByArbitrator(bytes32 question_id, bytes32 answer, address answerer)
        onlyArbitrator(question_id)
        statePendingArbitration(question_id)
    external {

        require(answerer != NULL_ADDRESS, "answerer must be provided");
        emit LogFinalize(question_id, answer);

        questions[question_id].is_pending_arbitration = false;
        _addAnswerToHistory(question_id, answer, answerer, 0, false);
        _updateCurrentAnswer(question_id, answer, 0);

    }

    /// @notice Report whether the answer to the specified question is finalized
    /// @param question_id The ID of the question
    /// @return Return true if finalized
    function isFinalized(bytes32 question_id)
    view public returns (bool) {
        uint32 finalize_ts = questions[question_id].finalize_ts;
        return ( !questions[question_id].is_pending_arbitration && (finalize_ts > UNANSWERED) && (finalize_ts <= uint32(now)) );
    }

    /// @notice (Deprecated) Return the final answer to the specified question, or revert if there isn't one
    /// @param question_id The ID of the question
    /// @return The answer formatted as a bytes32
    function getFinalAnswer(bytes32 question_id)
        stateFinalized(question_id)
    external view returns (bytes32) {
        return questions[question_id].best_answer;
    }

    /// @notice Return the final answer to the specified question, or revert if there isn't one
    /// @param question_id The ID of the question
    /// @return The answer formatted as a bytes32
    function resultFor(bytes32 question_id)
        stateFinalized(question_id)
    external view returns (bytes32) {
        return questions[question_id].best_answer;
    }


    /// @notice Return the final answer to the specified question, provided it matches the specified criteria.
    /// @dev Reverts if the question is not finalized, or if it does not match the specified criteria.
    /// @param question_id The ID of the question
    /// @param content_hash The hash of the question content (template ID + opening time + question parameter string)
    /// @param arbitrator The arbitrator chosen for the question (regardless of whether they are asked to arbitrate)
    /// @param min_timeout The timeout set in the initial question settings must be this high or higher
    /// @param min_bond The bond sent with the final answer must be this high or higher
    /// @return The answer formatted as a bytes32
    function getFinalAnswerIfMatches(
        bytes32 question_id,
        bytes32 content_hash, address arbitrator, uint32 min_timeout, uint256 min_bond
    )
        stateFinalized(question_id)
    external view returns (bytes32) {
        require(content_hash == questions[question_id].content_hash, "content hash must match");
        require(arbitrator == questions[question_id].arbitrator, "arbitrator must match");
        require(min_timeout <= questions[question_id].timeout, "timeout must be long enough");
        require(min_bond <= questions[question_id].bond, "bond must be high enough");
        return questions[question_id].best_answer;
    }

    /// @notice Assigns the winnings (bounty and bonds) to everyone who gave the accepted answer
    /// Caller must provide the answer history, in reverse order
    /// @dev Works up the chain and assign bonds to the person who gave the right answer
    /// If someone gave the winning answer earlier, they must get paid from the higher bond
    /// That means we can't pay out the bond added at n until we have looked at n-1
    /// The first answer is authenticated by checking against the stored history_hash.
    /// One of the inputs to history_hash is the history_hash before it, so we use that to authenticate the next entry, etc
    /// Once we get to a null hash we'll know we're done and there are no more answers.
    /// Usually you would call the whole thing in a single transaction, but if not then the data is persisted to pick up later.
    /// @param question_id The ID of the question
    /// @param history_hashes Second-last-to-first, the hash of each history entry. (Final one should be empty).
    /// @param addrs Last-to-first, the address of each answerer or commitment sender
    /// @param bonds Last-to-first, the bond supplied with each answer or commitment
    /// @param answers Last-to-first, each answer supplied, or commitment ID if the answer was supplied with commit->reveal
    function claimWinnings(
        bytes32 question_id,
        bytes32[] memory history_hashes, address[] memory addrs, uint256[] memory bonds, bytes32[] memory answers
    )
        stateFinalized(question_id)
    public {

        require(history_hashes.length > 0, "at least one history hash entry must be provided");

        // These are only set if we split our claim over multiple transactions.
        address payee = question_claims[question_id].payee;
        uint256 last_bond = question_claims[question_id].last_bond;
        uint256 queued_funds = question_claims[question_id].queued_funds;

        // Starts as the hash of the final answer submitted. It'll be cleared when we're done.
        // If we're splitting the claim over multiple transactions, it'll be the hash where we left off last time
        bytes32 last_history_hash = questions[question_id].history_hash;

        bytes32 best_answer = questions[question_id].best_answer;

        uint256 i;
        for (i = 0; i < history_hashes.length; i++) {

            // Check input against the history hash, and see which of 2 possible values of is_commitment fits.
            bool is_commitment = _verifyHistoryInputOrRevert(last_history_hash, history_hashes[i], answers[i], bonds[i], addrs[i]);

            queued_funds = queued_funds.add(last_bond);
            (queued_funds, payee) = _processHistoryItem(
                question_id, best_answer, queued_funds, payee,
                addrs[i], bonds[i], answers[i], is_commitment);

            // Line the bond up for next time, when it will be added to somebody's queued_funds
            last_bond = bonds[i];
            last_history_hash = history_hashes[i];

        }

        if (last_history_hash != NULL_HASH) {
            // We haven't yet got to the null hash (1st answer), ie the caller didn't supply the full answer chain.
            // Persist the details so we can pick up later where we left off later.

            // If we know who to pay we can go ahead and pay them out, only keeping back last_bond
            // (We always know who to pay unless all we saw were unrevealed commits)
            if (payee != NULL_ADDRESS) {
                _payPayee(question_id, payee, queued_funds);
                queued_funds = 0;
            }

            question_claims[question_id].payee = payee;
            question_claims[question_id].last_bond = last_bond;
            question_claims[question_id].queued_funds = queued_funds;
        } else {
            // There is nothing left below us so the payee can keep what remains
            _payPayee(question_id, payee, queued_funds.add(last_bond));
            delete question_claims[question_id];
        }

        questions[question_id].history_hash = last_history_hash;

    }

    function _payPayee(bytes32 question_id, address payee, uint256 value)
    internal {
        balanceOf[payee] = balanceOf[payee].add(value);
        emit LogClaim(question_id, payee, value);
    }

    function _verifyHistoryInputOrRevert(
        bytes32 last_history_hash,
        bytes32 history_hash, bytes32 answer, uint256 bond, address addr
    )
    internal pure returns (bool) {
        if (last_history_hash == keccak256(abi.encodePacked(history_hash, answer, bond, addr, true)) ) {
            return true;
        }
        if (last_history_hash == keccak256(abi.encodePacked(history_hash, answer, bond, addr, false)) ) {
            return false;
        }
        revert("History input provided did not match the expected hash");
    }

    function _processHistoryItem(
        bytes32 question_id, bytes32 best_answer,
        uint256 queued_funds, address payee,
        address addr, uint256 bond, bytes32 answer, bool is_commitment
    )
    internal returns (uint256, address) {

        // For commit-and-reveal, the answer history holds the commitment ID instead of the answer.
        // We look at the referenced commitment ID and switch in the actual answer.
        if (is_commitment) {
            bytes32 commitment_id = answer;
            // If it's a commit but it hasn't been revealed, it will always be considered wrong.
            if (!commitments[commitment_id].is_revealed) {
                delete commitments[commitment_id];
                return (queued_funds, payee);
            } else {
                answer = commitments[commitment_id].revealed_answer;
                delete commitments[commitment_id];
            }
        }

        if (answer == best_answer) {

            if (payee == NULL_ADDRESS) {

                // The entry is for the first payee we come to, ie the winner.
                // They get the question bounty.
                payee = addr;
                queued_funds = queued_funds.add(questions[question_id].bounty);
                questions[question_id].bounty = 0;

            } else if (addr != payee) {

                // Answerer has changed, ie we found someone lower down who needs to be paid

                // The lower answerer will take over receiving bonds from higher answerer.
                // They should also be paid the takeover fee, which is set at a rate equivalent to their bond.
                // (This is our arbitrary rule, to give consistent right-answerers a defence against high-rollers.)

                // There should be enough for the fee, but if not, take what we have.
                // There's an edge case involving weird arbitrator behaviour where we may be short.
                uint256 answer_takeover_fee = (queued_funds >= bond) ? bond : queued_funds;

                // Settle up with the old (higher-bonded) payee
                _payPayee(question_id, payee, queued_funds.sub(answer_takeover_fee));

                // Now start queued_funds again for the new (lower-bonded) payee
                payee = addr;
                queued_funds = answer_takeover_fee;

            }

        }

        return (queued_funds, payee);

    }

    /// @notice Convenience function to assign bounties/bonds for multiple questions in one go, then withdraw all your funds.
    /// Caller must provide the answer history for each question, in reverse order
    /// @dev Can be called by anyone to assign bonds/bounties, but funds are only withdrawn for the user making the call.
    /// @param question_ids The IDs of the questions you want to claim for
    /// @param lengths The number of history entries you will supply for each question ID
    /// @param hist_hashes In a single list for all supplied questions, the hash of each history entry.
    /// @param addrs In a single list for all supplied questions, the address of each answerer or commitment sender
    /// @param bonds In a single list for all supplied questions, the bond supplied with each answer or commitment
    /// @param answers In a single list for all supplied questions, each answer supplied, or commitment ID
    function claimMultipleAndWithdrawBalance(
        bytes32[] memory question_ids, uint256[] memory lengths,
        bytes32[] memory hist_hashes, address[] memory addrs, uint256[] memory bonds, bytes32[] memory answers
    )
        stateAny() // The finalization checks are done in the claimWinnings function
    public {

        uint256 qi;
        uint256 i;
        for (qi = 0; qi < question_ids.length; qi++) {
            bytes32 qid = question_ids[qi];
            uint256 ln = lengths[qi];
            bytes32[] memory hh = new bytes32[](ln);
            address[] memory ad = new address[](ln);
            uint256[] memory bo = new uint256[](ln);
            bytes32[] memory an = new bytes32[](ln);
            uint256 j;
            for (j = 0; j < ln; j++) {
                hh[j] = hist_hashes[i];
                ad[j] = addrs[i];
                bo[j] = bonds[i];
                an[j] = answers[i];
                i++;
            }
            claimWinnings(qid, hh, ad, bo, an);
        }
        withdraw();
    }

    /// @notice Returns the questions's content hash, identifying the question content
    /// @param question_id The ID of the question
    function getContentHash(bytes32 question_id)
    public view returns(bytes32) {
        return questions[question_id].content_hash;
    }

    /// @notice Returns the arbitrator address for the question
    /// @param question_id The ID of the question
    function getArbitrator(bytes32 question_id)
    public view returns(address) {
        return questions[question_id].arbitrator;
    }

    /// @notice Returns the timestamp when the question can first be answered
    /// @param question_id The ID of the question
    function getOpeningTS(bytes32 question_id)
    public view returns(uint32) {
        return questions[question_id].opening_ts;
    }

    /// @notice Returns the timeout in seconds used after each answer
    /// @param question_id The ID of the question
    function getTimeout(bytes32 question_id)
    public view returns(uint32) {
        return questions[question_id].timeout;
    }

    /// @notice Returns the timestamp at which the question will be/was finalized
    /// @param question_id The ID of the question
    function getFinalizeTS(bytes32 question_id)
    public view returns(uint32) {
        return questions[question_id].finalize_ts;
    }

    /// @notice Returns whether the question is pending arbitration
    /// @param question_id The ID of the question
    function isPendingArbitration(bytes32 question_id)
    public view returns(bool) {
        return questions[question_id].is_pending_arbitration;
    }

    /// @notice Returns the current total unclaimed bounty
    /// @dev Set back to zero once the bounty has been claimed
    /// @param question_id The ID of the question
    function getBounty(bytes32 question_id)
    public view returns(uint256) {
        return questions[question_id].bounty;
    }

    /// @notice Returns the current best answer
    /// @param question_id The ID of the question
    function getBestAnswer(bytes32 question_id)
    public view returns(bytes32) {
        return questions[question_id].best_answer;
    }

    /// @notice Returns the history hash of the question
    /// @param question_id The ID of the question
    /// @dev Updated on each answer, then rewound as each is claimed
    function getHistoryHash(bytes32 question_id)
    public view returns(bytes32) {
        return questions[question_id].history_hash;
    }

    /// @notice Returns the highest bond posted so far for a question
    /// @param question_id The ID of the question
    function getBond(bytes32 question_id)
    public view returns(uint256) {
        return questions[question_id].bond;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}
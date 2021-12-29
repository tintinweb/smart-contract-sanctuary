// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.7.5;

import "./libraries/Address.sol";
import "./libraries/SafeMath.sol";
import "./libraries/SafeERC20.sol";
import "./types/FrontEndRewarder.sol";
import "./interfaces/IBondDepository.sol";
import "./interfaces/IgOHM.sol";
import "./interfaces/IStaking.sol";
import "./interfaces/ITreasury.sol";

contract OlympusPro is IBondDepository, FrontEndRewarder {
/* ======== DEPENDENCIES ======== */

  using SafeMath for uint256;
  using SafeMath for uint48;
  using SafeMath for uint64;
  using SafeERC20 for IERC20;
  using SafeERC20 for IgOHM;

/* ======== EVENTS ======== */

  event CreateMarket(uint256 id, address baseToken, address quoteToken, uint256 initialPrice);
  event CloseMarket(uint256 id);
  event Bond(uint256 id, uint256 amount, uint256 payout, uint256 expires, uint256 price);

/* ======== STATE VARIABLES ======== */

  // Storage
  Market[] public markets; // persistent market data
  Terms[] public terms; // deposit construction data
  Metadata[] public metadata; // extraneous market data
  mapping(address => Note[]) public notes; // user deposit data

  // Queries
  mapping(address => uint256[]) public marketsForQuote; // market IDs for quote token

  // Olympus contracts
  IERC20 internal immutable ohm;
  IgOHM internal immutable gOHM;
  ITreasury internal immutable treasury;
  IStaking internal immutable staking;

/* ======== CONSTRUCTOR ======== */

  constructor(
    IOlympusAuthority _authority, 
    IERC20 _ohm,
    IgOHM _gohm,
    ITreasury _treasury,
    IStaking _staking
  ) FrontEndRewarder(_authority) {
    ohm = _ohm;
    gOHM = _gohm;
    treasury = _treasury;
    staking = _staking;
  }

  // mass approve ohm to be staked
  // saves gas for depositors
  function approve() external {
    ohm.approve(address(staking), 1e33);
  }

/* ======== DEPOSIT ======== */

  /**
   * @notice deposit market
   * @param _id uint256
   * @param _amount uint256
   * @param _maxPrice uint256
   * @param _user address
   * @param _referral address
   * @return payout_ uint256
   * @return expiry_ uint256
   * @return index_ uint256
   */
  function deposit(
    uint256 _id,
    uint256 _amount,
    uint256 _maxPrice,
    address _user,
    address _referral
  ) external override returns (
    uint256 payout_, 
    uint256 expiry_,
    uint256 index_
  ) {
    Market storage market = markets[_id];
    Terms memory term = terms[_id];
    Metadata storage meta = metadata[_id];
    require(_user != address(0), "Depository: invalid address");

    // Markets end at an initialized timestamp
    // |-------------------------------------| t
    require(block.timestamp < term.conclusion, "Depository: market concluded");

    /** 
     * Debt is a time-decayed sum of tokens spent in a market
     * Debt is added when deposits occur and removed over time
     * |      
     * |    debt falls with
     * |   / \  inactivity       / \
     * | /     \              /\/    \
     * |         \           /         \
     * |           \      /\/            \
     * |             \  /  and rises       \
     * |                with deposits
     * |       
     * |         
     * |
     * |
     * |------------------------------------| t
     */
    market.totalDebt = market.totalDebt.sub(debtDecay(_id));
    meta.lastDecay = uint48(block.timestamp);

    uint256 price = marketPrice(_id);
    // Users input a maximum price, which protects them from any change after
    // entering the mempool. max price is a slippage mitigation measure
    require(price <= _maxPrice, "Depository: more than max price"); 

    /**
     * the payout for a bond equals
     *
     * payout = amount / price
     *
     * where
     * payout = base tokens out
     * amount = quote tokens in
     * price = quote tokens : base token
     */
    payout_ = payoutFor(_amount, _id); // and ensure it is within bounds

    // markets have a max payout amount, capping size because deposits
    // do not experience slippage. max payout is recalculated upon tuning
    require(payout_ <= market.maxPayout, "Depository: max size exceeded");
    
    /*
     * each market is initialized with a capacity
     *
     * this is either the number of base tokens that the market can sell
     * (if capacity in quote is false), 
     *
     * or the number of quote tokens that the market can buy
     * (if capacity in quote is true)
     */
    uint256 toCheck = payout_;
    if (market.capacityInQuote) toCheck = _amount;
    require(toCheck <= market.capacity, "Depository: capacity exceeded");
    market.capacity = market.capacity.sub(toCheck);

    /**
     * bonds mature with a cliff at a set timestamp
     * prior to the cliff, no payout tokens are accessible to the user
     * after the expiry timestamp, the entire payout can be redeemed
     *
     * there are two types of bonds: fixed-term and fixed-expiration
     *
     * fixed-term bonds mature at a set timestamp from creation
     * i.e. term = 1 week. when alice deposits on day 1, her bond
     * expires on day 8. when bob deposits on day 2, his bond expires day 9.
     *
     * fixed-expiration bonds mature at the same timestamp
     * i.e. term = day 10. when alice deposits on day 1, her term
     * is 9 days. when bob deposits on day 3, his term is 7 days.
     */
    if (term.fixedTerm) expiry_ = term.vesting.add(block.timestamp);
    else expiry_ = term.vesting;

    /**
     * user data is stored as Notes. these are isolated array entries
     * storing the amount due, the time created, the time when payout
     * is redeemable, the time when payout was redeemed, and the ID
     * of the market deposited into
     */
    index_ = notes[_user].length;
    notes[_user].push(
        Note({
            payout: gOHM.balanceTo(payout_),
            created: uint48(block.timestamp),
            matured: uint48(expiry_),
            redeemed: 0,
            marketID: uint48(_id)
        })
    );

    // markets keep track of how many quote tokens have been
    // purchased, and how many base tokens have been sold
    market.purchased = market.purchased.add(_amount);
    market.sold = market.sold.add(payout_);

    // incrementing total debt raises the price of the next bond
    market.totalDebt = market.totalDebt.add(payout_);

    // Emit an event with info about the deposit
    emit Bond(_id, _amount, payout_, expiry_, price);

    // if max debt is breached, the market is deprecated 
    // as a circuit breaking measure
    if (term.maxDebt < market.totalDebt) {
        market.capacity = 0;
        emit CloseMarket(_id);
    } else { // the control variable is tuned to hit targets on time
        _tune(_id);
    }

    // front end operators can earn rewards by referring users
    uint256 rewards = _giveRewards(address(gOHM), payout_, _referral);

    // mint and stake payout
    treasury.mint(address(this), payout_.add(rewards));
    // note that only the payout gets staked (front end rewards are in OHM)
    staking.stake(address(this), payout_, false, true);

    // transfer payment to treasury
    market.quoteToken.safeTransferFrom(msg.sender, address(treasury), _amount);
  }

  // auto-adjust control variable to hit capacity/spend target
  function _tune(uint256 _id) internal {
    Market memory market = markets[_id];
    Metadata memory meta = metadata[_id];
    if (block.timestamp >= meta.lastTune.add(meta.tuneInterval)) {
      // compute seconds until market will conclude
      uint256 timeRemaining = terms[_id].conclusion.sub(block.timestamp);
      // standardize capacity into an base token amount to compute target debt
      uint256 capacity = market.capacity;
      if (market.capacityInQuote) {
        capacity = capacity.mul(10 ** meta.baseDecimals).mul(1e9).div(marketPrice(_id)).div(10 ** meta.quoteDecimals);
      }
      // calculate max payout for target intervals 
      markets[_id].maxPayout = capacity.mul(meta.depositInterval).div(timeRemaining);
      // calculate target debt to complete offering at conclusion
      uint256 targetDebt = capacity.mul(meta.length).div(timeRemaining);
      // derive a new control variable from the target debt
      uint256 newControlVariable = marketPrice(_id).mul(treasury.baseSupply()).div(targetDebt);
      // prevent control variable from decrementing price by more than 2% at a time
      uint256 minNewControlVariable = terms[_id].controlVariable.mul(98).div(100);
      if (minNewControlVariable < newControlVariable) {
        terms[_id].controlVariable = uint64(newControlVariable);
      } else {
        terms[_id].controlVariable = uint64(minNewControlVariable);
      }
    }
  }

/* ======== REDEEM ======== */

  /**
   *  @notice redeem market for user
   *  @param _user address
   *  @param _indexes calldata uint256[]
   */
  function redeem(address _user, uint256[] memory _indexes, bool _sendAsG) public override {
    uint256 payout;
    for (uint256 i = 0; i < _indexes.length; i++) {
      (uint256 pay, bool matured) = pendingFor(_user, _indexes[i]);
      if (matured) {
        notes[_user][_indexes[i]].redeemed = uint48(block.timestamp); // mark as redeemed
        payout = payout.add(pay);
      }
    }
    if (_sendAsG) {
      gOHM.safeTransfer(_user, payout); // send payout as gOHM
    } else {
      staking.unwrap(_user, payout); // unwrap and send payout as sOHM
    }
  }

  // redeem all redeemable markets for user
  function redeemAll(address _user, bool _sendAsG) external override {
    redeem(_user, indexesFor(_user), _sendAsG);
  }

/* ======== CREATE ======== */

  /**
   * @notice creates a new market type
   * @dev note current price should be in 9 decimals.
   * @param _quoteToken IERC20
   * @param _market uint256[] memory
   * @param _booleans bool[] memory
   * @param _terms uint48[] memory
   * @param _intervals uint32[] memory
   * @param _decimals uint32
   * @return id_ uint256
   */
  function addBond(
    IERC20 _quoteToken, // token used to deposit
    uint256[] memory _market, // [capacity, initial price]
    bool[] memory _booleans, // [capacity in quote, fixed term]
    uint256[] memory _terms, // [vesting, conclusion]
    uint32[] memory _intervals, // [deposit interval, tune interval]
    uint8 _decimals // quote token decimal count (ohm decimals == 9)
  ) external override onlyPolicy returns (uint256 id_) {
    // find the target debt to start at current market price
    uint256 targetDebt = _market[0];
    if (_booleans[0]) {
      targetDebt = targetDebt.mul(10 ** 9).mul(1e9).div(_market[1]).div(10 ** _decimals);
    }

    // compute max payout and control variable given target debt
    uint256 toConclusion = _terms[1].sub(block.timestamp);
    uint256 maxPayout = targetDebt.mul(_intervals[0]).div(toConclusion);
    uint256 controlVariable = _market[1].mul(treasury.baseSupply()).div(targetDebt);

    // add to storage
    id_ = markets.length;

    markets.push(Market({
      quoteToken: _quoteToken, 
      capacityInQuote: _booleans[0],
      capacity: _market[0],
      totalDebt: targetDebt, 
      maxPayout: maxPayout,
      purchased: 0,
      sold: 0
    }));

    terms.push(Terms({
      fixedTerm: _booleans[1], 
      controlVariable: uint64(controlVariable),
      vesting: uint48(_terms[0]), 
      conclusion: uint48(_terms[1]), 
      maxDebt: uint64(targetDebt.mul(3)) // 3x buffer. exists to hedge tail risk.
    }));

    metadata.push(Metadata({
      lastTune: uint48(block.timestamp),
      lastDecay: uint48(block.timestamp),
      length: uint48(toConclusion),
      depositInterval: _intervals[0],
      tuneInterval: _intervals[1],
      baseDecimals: 9,
      quoteDecimals: _decimals
    }));

    marketsForQuote[address(_quoteToken)].push(id_);

    emit CreateMarket(id_, address(ohm), address(_quoteToken), _market[1]);
  }

  /**
   * @notice disable existing market
   * @param _id uint
   */
  function close(uint256 _id) external override onlyPolicy {
    markets[_id].capacity = 0;
    emit CloseMarket(_id);
  }

/* ======== VIEW ======== */

  // Market Info

  /**
   * @notice is a given market accepting deposits
   * @param _id uint256
   * @return bool
   */
  function isLive(uint256 _id) public view override returns (bool) {
    if (markets[_id].capacity == 0 || terms[_id].conclusion < block.timestamp) return false;
    return true;
  }

  /**
   * @notice returns all active market IDs
   * @return uint256[] memory
   */
  function liveMarkets() external view override returns (uint256[] memory) {
    uint256 num;
    for (uint256 i = 0; i < markets.length; i++) {
      if (isLive(i)) num++;
    }
    uint256[] memory ids = new uint256[](num);
    uint256 nonce;
    for (uint256 i = 0; i < markets.length; i++) {
      if (isLive(i)) {
        ids[nonce] = i;
        nonce++;
      }
    }
    return ids;
  }

  /**
   * @notice returns all active market IDs with a given base or quote token
   * @param _token address
   * @return uint256[] memory
   */
  function liveMarketsFor(address _token) external view override returns (uint256[] memory) {
    uint256[] memory mkts = marketsForQuote[_token];
    uint256 num;
    for (uint256 i = 0; i < mkts.length; i++) {
      if (isLive(mkts[i])) num++;
    }
    uint256[] memory ids = new uint256[](num);
    uint256 nonce;
    for (uint256 i = 0; i < mkts.length; i++) {
      if (isLive(mkts[i])) {
        ids[nonce] = mkts[i];
        nonce++;
      }
    }
    return ids;
  }

  // Deposit Info

  /**
   * @notice payout due for amount of treasury value
   * @param _amount uint256
   * @param _id uint256
   * @return uint256
   */
  function payoutFor(uint256 _amount, uint256 _id) public view override returns (uint256) {
    Metadata memory meta = metadata[_id];
    return _amount.mul(1e9).mul(10 ** meta.baseDecimals).div(marketPrice(_id)).div(10 ** meta.quoteDecimals);
  }

  /**
   * @notice calculate current market price of quote token in base token
   * @param _id uint256
   * @return uint256
   *
   * price is derived from the equation
   *
   * p = c * dr
   *
   * where
   * p = price
   * c = control variable
   * dr = debt ratio
   *
   * dr = d / s
   * 
   * where
   * d = debt
   * s = supply of token at market creation
   *
   * d -= ( d * (dt / sd) )
   * 
   * where
   * dt = change in time
   * sd = speed of decay
   */
  function marketPrice(uint256 _id) public view override returns (uint256) {
    return terms[_id].controlVariable.mul(debtRatio(_id)).div(10 ** metadata[_id].quoteDecimals);
  }

  /**
   * @notice calculate debt factoring in decay
   * @param _id uint256
   * @return uint256
   */
  function currentDebt(uint256 _id) public view override returns (uint256) {
    return markets[_id].totalDebt.sub(debtDecay(_id));
  }

  /**
   * @notice calculate current ratio of debt to supply
   * @param _id uint256
   * @return uint256
   */
  function debtRatio(uint256 _id) public view override returns (uint256) {
    return currentDebt(_id).mul(10 ** metadata[_id].quoteDecimals).div(treasury.baseSupply()); 
  }

  /**
   * @notice amount to decay total debt by
   * @param _id uint256
   * @return decay_ uint256
   */
  function debtDecay(uint256 _id) public view override returns (uint256 decay_) {
    uint256 totalDebt = markets[_id].totalDebt;
    uint256 secondsSinceLast = block.timestamp.sub(metadata[_id].lastDecay);
    decay_ = totalDebt.mul(secondsSinceLast).div(metadata[_id].length);
    if (decay_ > totalDebt) decay_ = totalDebt;
  }

  // Note info

  // all pending indexes for user
  function indexesFor(address _user) public view override returns (uint256[] memory) {
      uint256 length;
      for (uint256 i = 0; i < notes[_user].length; i++) {
          if (notes[_user][i].redeemed == 0) {
              length++;
          }
      }
      uint256[] memory array = new uint256[](length);
      uint256 position;
      for (uint256 i = 0; i < notes[_user].length; i++) {
          if (notes[_user][i].redeemed == 0) {
              array[position] = i;
              position++;
          }
      }
      return array;
  }

  /**
    * @notice calculate amount available for claim for a single note
    * @param _user address
    * @param _index uint256
    * @return payout_ uint256
    * @return matured_ bool
    */
  function pendingFor(address _user, uint256 _index) public view override returns (uint256 payout_, bool matured_) {
    Note memory note = notes[_user][_index];
    payout_ = note.payout;
    if (note.redeemed == 0 && note.matured <= block.timestamp) {
        matured_ = true;
    } else matured_ = false;
  }

/* ========== TEST ========== */

  // testing function to jump forward by a number of seconds
  function jump(uint256 _id, uint256 _by) external {
    Terms storage term = terms[_id];
    Metadata storage meta = metadata[_id];
    meta.lastDecay = uint48(meta.lastDecay.sub(_by));
    meta.lastTune = uint48(meta.lastTune.sub(_by));
    term.conclusion = uint48(term.conclusion.sub(_by));
    if (!term.fixedTerm) term.vesting = uint48(term.vesting.sub(_by));
  }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.7.5;

interface ITreasury {
    function deposit(
        uint256 _amount,
        address _token,
        uint256 _profit
    ) external returns (uint256);

    function withdraw(uint256 _amount, address _token) external;

    function tokenValue(address _token, uint256 _amount) external view returns (uint256 value_);

    function mint(address _recipient, uint256 _amount) external;

    function manage(address _token, uint256 _amount) external;

    function incurDebt(uint256 amount_, address token_) external;

    function repayDebtWithReserve(uint256 amount_, address token_) external;

    function excessReserves() external view returns (uint256);

    function baseSupply() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.7.5;

interface IStaking {
    function stake(
        address _to,
        uint256 _amount,
        bool _rebasing,
        bool _claim
    ) external returns (uint256);

    function claim(address _recipient, bool _rebasing) external returns (uint256);

    function forfeit() external returns (uint256);

    function toggleLock() external;

    function unstake(
        address _to,
        uint256 _amount,
        bool _trigger,
        bool _rebasing
    ) external returns (uint256);

    function wrap(address _to, uint256 _amount) external returns (uint256 gBalance_);

    function unwrap(address _to, uint256 _amount) external returns (uint256 sBalance_);

    function rebase() external;

    function index() external view returns (uint256);

    function contractBalance() external view returns (uint256);

    function totalStaked() external view returns (uint256);

    function supplyInWarmup() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.7.5;

import "./IERC20.sol";

interface IgOHM is IERC20 {
  function mint(address _to, uint256 _amount) external;

  function burn(address _from, uint256 _amount) external;

  function index() external view returns (uint256);

  function balanceFrom(uint256 _amount) external view returns (uint256);

  function balanceTo(uint256 _amount) external view returns (uint256);

  function migrate( address _staking, address _sOHM ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.7.5;

import "./IERC20.sol";

interface IBondDepository {

  // Info about each type of market
  struct Market {
    IERC20 quoteToken; // token to accept as payment
    bool capacityInQuote; // capacity limit is in payment token (true) or in OHM (false, default)
    uint256 capacity; // capacity remaining
    uint256 totalDebt; // total debt from market
    uint256 maxPayout; // max tokens in/out (determined by capacityInQuote false/true, respectively)
    uint256 purchased; // quote tokens in
    uint256 sold; // base tokens out
  }

  // Info for creating new markets
  struct Terms {
    bool fixedTerm; // fixed term or fixed expiration
    uint64 controlVariable; // scaling variable for price
    uint48 vesting; // length of time from deposit to maturity if fixed-term
    uint48 conclusion; // timestamp when market no longer offered (doubles as time when market matures if fixed-expiry)
    uint64 maxDebt; // 9 decimal debt maximum in OHM
  }

  // Additional info about market.
  struct Metadata {
    uint48 lastTune; // last timestamp when control variable was tuned
    uint48 lastDecay; // last timestamp when market was created and debt was decayed
    uint48 length; // time from creation to conclusion. used as speed to decay debt.
    uint48 depositInterval; // target frequency of deposits
    uint48 tuneInterval; // frequency of tuning
    uint8 baseDecimals; // decimals of base token (ohm)
    uint8 quoteDecimals; // decimals of quote token
  }

  // Info for market note
  struct Note {
    uint256 payout; // gOHM remaining to be paid
    uint48 created; // time market was created
    uint48 matured; // timestamp when market is matured
    uint48 redeemed; // time market was redeemed
    uint48 marketID; // market ID of deposit. uint48 to avoid adding a slot.
  }


  /**
   * @notice deposit market
   * @param _bid uint256
   * @param _amount uint256
   * @param _maxPrice uint256
   * @param _user address
   * @param _referral address
   * @return payout_ uint256
   * @return expiry_ uint256
   * @return index_ uint256
   */
  function deposit(
    uint256 _bid,
    uint256 _amount,
    uint256 _maxPrice,
    address _user,
    address _referral
  ) external returns (
    uint256 payout_, 
    uint256 expiry_,
    uint256 index_
  );
  function redeem(address _user, uint256[] memory _indexes, bool _sendAsG) external;
  function redeemAll(address _user, bool _sendAsG) external;

  function addBond(
    IERC20 _quoteToken, // token used to deposit
    uint256[] memory _market, // [capacity, initial price]
    bool[] memory _booleans, // [capacity in quote, fixed term]
    uint256[] memory _terms, // [vesting, conclusion]
    uint32[] memory _intervals, // [deposit interval, tune interval]
    uint8 _decimals // decimal count of quote token
  ) external returns (uint256 id_);
  function close(uint256 _id) external;

  function isLive(uint256 _bid) external view returns (bool);
  function liveMarkets() external view returns (uint256[] memory);
  function liveMarketsFor(address _quoteToken) external view returns (uint256[] memory);
  function payoutFor(uint256 _amount, uint256 _bid) external view returns (uint256);
  function marketPrice(uint256 _bid) external view returns (uint256);
  function currentDebt(uint256 _bid) external view returns (uint256);
  function debtRatio(uint256 _bid) external view returns (uint256);
  function debtDecay(uint256 _bid) external view returns (uint256 decay_);
  function indexesFor(address _user) external view returns (uint256[] memory);
  function pendingFor(address _user, uint256 _index) external view returns (uint256 payout_, bool matured_);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import "../types/OlympusAccessControlled.sol";
import "../libraries/SafeMath.sol";
import "../interfaces/IERC20.sol";

abstract contract FrontEndRewarder is OlympusAccessControlled {

  using SafeMath for uint256;

  constructor(IOlympusAuthority _authority) OlympusAccessControlled(_authority) {}

  // Front end incentive
  uint256[2] public rewardRate; // % reward for [operator, dao] (5 decimals)
  mapping(address => mapping(address => uint256)) public rewards; // front end operator rewards
  mapping(address => bool) public whitelisted; // whitelisted status for operators

  // pay reward to front end operator
  function getReward(address[] memory _tokens) external {
    for (uint256 i = 0; i < _tokens.length; i++) {
      uint256 reward = rewards[_tokens[i]][msg.sender];
      rewards[_tokens[i]][msg.sender] = 0;
      IERC20(_tokens[i]).transfer(msg.sender, reward);
    }
  }

  /** 
   * @notice add new market payout to user data
   * @param _payout uint256
   * @param _referral address
   */
  function _giveRewards(
    address _baseToken,
    uint256 _payout,
    address _referral
  ) internal returns (uint256) {
    // first we calculate rewards paid to the DAO and to the front end operator (referrer)
    uint256 toDAO = _payout.mul(rewardRate[1]).div(1e4);
    uint256 toRef = _payout.mul(rewardRate[0]).div(1e4);

    // and store them in our rewards mapping
    if (whitelisted[_referral]) {
        rewards[_baseToken][_referral] = rewards[_baseToken][_referral].add(toRef);
        rewards[_baseToken][authority.guardian()] = rewards[_baseToken][authority.guardian()].add(toDAO);
    } else { // the DAO receives both rewards if referrer is not whitelisted
        rewards[_baseToken][authority.guardian()] = rewards[_baseToken][authority.guardian()].add(toDAO.add(toRef));
    }
    return toDAO.add(toRef);
  }

  /**
   * @notice set rewards for front end operators and DAO
   * @param _toFrontEnd uint256
   * @param _toDAO uint256
   */
  function setRewards(uint256 _toFrontEnd, uint256 _toDAO) external onlyPolicy {
      rewardRate[0] = _toFrontEnd;
      rewardRate[1] = _toDAO;
  }

  /**
   * @notice add or remove addresses from the reward whitelist
   * @notice whitelisted addresses can earn referral fees by operating a front end
   * @param _operator address
   */
  function whitelist(address _operator) external onlyPolicy {
      whitelisted[_operator] = !whitelisted[_operator];
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import {IERC20} from "../interfaces/IERC20.sol";

/// @notice Safe IERC20 and ETH transfer library that safely handles missing return values.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol)
/// Taken from Solmate
library SafeERC20 {
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.approve.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    }

    function safeTransferETH(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}(new bytes(0));

        require(success, "ETH_TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.7.5;


// TODO(zx): Replace all instances of SafeMath with OZ implementation
library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    // Only used in the  BondingCalculator.sol
    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.7.5;

interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
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
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import "../interfaces/IOlympusAuthority.sol";

abstract contract OlympusAccessControlled {

    /* ========== EVENTS ========== */

    event AuthorityUpdated(IOlympusAuthority indexed authority);

    string UNAUTHORIZED = "UNAUTHORIZED"; // save gas

    /* ========== STATE VARIABLES ========== */

    IOlympusAuthority public authority;


    /* ========== Constructor ========== */

    constructor(IOlympusAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }
    

    /* ========== MODIFIERS ========== */
    
    modifier onlyGovernor() {
        require(msg.sender == authority.governor(), UNAUTHORIZED);
        _;
    }
    
    modifier onlyGuardian() {
        require(msg.sender == authority.guardian(), UNAUTHORIZED);
        _;
    }
    
    modifier onlyPolicy() {
        require(msg.sender == authority.policy(), UNAUTHORIZED);
        _;
    }

    modifier onlyVault() {
        require(msg.sender == authority.vault(), UNAUTHORIZED);
        _;
    }
    
    /* ========== GOV ONLY ========== */
    
    function setAuthority(IOlympusAuthority _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.7.5;

interface IOlympusAuthority {
    /* ========== EVENTS ========== */
    
    event GovernorPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event GuardianPushed(address indexed from, address indexed to, bool _effectiveImmediately);    
    event PolicyPushed(address indexed from, address indexed to, bool _effectiveImmediately);    
    event VaultPushed(address indexed from, address indexed to, bool _effectiveImmediately);    

    event GovernorPulled(address indexed from, address indexed to);
    event GuardianPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);

    /* ========== VIEW ========== */
    
    function governor() external view returns (address);
    function guardian() external view returns (address);
    function policy() external view returns (address);
    function vault() external view returns (address);
}
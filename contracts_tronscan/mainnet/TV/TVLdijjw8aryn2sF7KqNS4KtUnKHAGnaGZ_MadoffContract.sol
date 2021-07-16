//SourceUnit: BernardEscrow.sol

pragma solidity 0.5.8;

import "./BernardsCutToken.sol";
import "./SafeMath.sol";


contract BernardEscrow {
  using SafeMath for uint256;

  BernardsCutToken public token;

  uint256 public constant CALCULATION_DISABLED_BLOCKS = 21600; //  used to avoid spam
  
  uint256 public prevCalculationBlock;
  uint256 public tokenFractionProfitCalculatedTimes;
  uint256 public ongoingBernardFee;

  mapping (uint256 => uint256) public tokenFractionProfitForCalculatedIdx;
  mapping (address => uint256) public profitWithdrawnOnCalculationIdx;

  event BernardFeeWithdrawn(address by, uint256 amount);

  //  MODIFIERS
  modifier onlyCalculationEnabled() {
    require(block.number.sub(prevCalculationBlock) >= CALCULATION_DISABLED_BLOCKS, "Calculation disabled");
    _;
  }

  modifier onlyTokenHolder() {
    require(token.balanceOf(msg.sender) > 0, "Not token holder");
    _;
  }

  modifier onlyToken() {
    require(msg.sender == address(token), "Not BCT");
    _;
  }

  /**
   * @dev Constructor.
   * @param _token Token address.
   * TESTED
   */
  constructor (address _token) public {
    token = BernardsCutToken(_token);

    tokenFractionProfitCalculatedTimes = 1;  //  idx 0 can not be used
  }

  /**
   * @dev Calculates token fraction profit.
   * TESTED
   */
  function calculateTokenFractionProfit() public onlyTokenHolder onlyCalculationEnabled {
    require(ongoingBernardFee >= 0.1 trx, "Not enough Bernardcut");
    uint256 fractionProfit = ongoingBernardFee.div(10000);
   
    tokenFractionProfitForCalculatedIdx[tokenFractionProfitCalculatedTimes] = fractionProfit;
    
    tokenFractionProfitCalculatedTimes = tokenFractionProfitCalculatedTimes.add(1);
    prevCalculationBlock = block.number;
    delete ongoingBernardFee;
  }
  
  /**
   * @dev Gets pending profit in BernardCut for sender.
   * @param _loopLimit  Limit of loops.
   * @return Profit amount.
   * TESTED
   */
  function pendingProfitInBernardCut(uint256 _loopLimit) public view returns(uint256 profit) {
    uint256 startIdx = profitWithdrawnOnCalculationIdx[msg.sender].add(1);
    
    if (startIdx < tokenFractionProfitCalculatedTimes) {
      uint256 endIdx = (tokenFractionProfitCalculatedTimes.sub(startIdx) > _loopLimit) ? startIdx.add(_loopLimit).sub(1) : tokenFractionProfitCalculatedTimes.sub(1);
      profit = _pendingProfit(msg.sender, startIdx, endIdx);
    }
  }
  
  /**
   * @dev Gets pending profit in BernardCut for address.
   * @param recipient  Recipient address.
   * @param _fromIdx  Index in tokenFractionProfitForCalculatedIdx to start on.
   * @param _toIdx  Index in tokenFractionProfitForCalculatedIdx to finish on.
   * @return Profit amount.
   * TESTED
   */
  function _pendingProfit(address recipient, uint256 _fromIdx, uint256 _toIdx) private view returns(uint256 profit) {
    uint256 priceSum;

    for (uint256 i = _fromIdx; i <= _toIdx; i ++) {
      priceSum = priceSum.add(tokenFractionProfitForCalculatedIdx[i]);
    }
    profit = priceSum.mul(token.balanceOf(recipient));
  }

  /**
   * @dev Withdraws profit for sender.
   * @param _loopLimit  Limit of loops.
   * TESTED
   */
  function withdrawProfit(uint256 _loopLimit) public onlyTokenHolder {
    _withdrawProfit(msg.sender, _loopLimit, false);
  }

  /**
   * @dev Withdraws profit for sender.
   * @param recipient  Recipient address.
   * @param _loopLimit  Limit of loops.
   * TESTED
   */
  function withdrawProfitFromToken(address payable recipient, uint256 _loopLimit) public onlyToken {
    _withdrawProfit(recipient, _loopLimit, true);
  }

  /**
   * @dev Withdraws profit for sender.
   * @param recipient  Recipient address.
   * @param _loopLimit  Limit of loops.
   * @param _fromToken  If sent from token, but EOA.
   * TESTED
   */
  function _withdrawProfit(address payable recipient, uint256 _loopLimit, bool _fromToken) private {
    uint256 startIdx = profitWithdrawnOnCalculationIdx[recipient].add(1);
    if (startIdx == tokenFractionProfitCalculatedTimes) {
      if (_fromToken) {
        profitWithdrawnOnCalculationIdx[recipient] = tokenFractionProfitCalculatedTimes.sub(1);
        return;
      }
      revert("Nothing to withdraw");
    }
    uint256 endIdx = (tokenFractionProfitCalculatedTimes.sub(startIdx) > _loopLimit) ? startIdx.add(_loopLimit).sub(1) : tokenFractionProfitCalculatedTimes.sub(1);
    uint256 profit = _pendingProfit(recipient, startIdx, endIdx);
    
    profitWithdrawnOnCalculationIdx[recipient] = endIdx;
    recipient.transfer(profit);
    emit BernardFeeWithdrawn(recipient, profit);
  }
}


//SourceUnit: BernardsCutToken.sol

pragma solidity 0.5.8;

import "./SafeMath.sol";
import "./ERC20Detailed.sol";
import "./BernardEscrow.sol";

contract BernardsCutToken is ERC20Detailed("BernardsCutToken", "BCT", 0) {

  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  uint256 private _totalSupply;

  BernardEscrow public escrow;

  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Constructor.
   * @param _dev Developer's address.
   * TESTED
   */
  constructor (address _dev) public {
    _mint(_dev, 3000);
    _mint(msg.sender, 7000);
  }

  /**
   * @dev Updates escrow address.
   * @notice Can be called once.
   * TESTED
   */
  function updateBernardEscrow(address _address) public {
    require(address(escrow) == address(0), "Already set");
    escrow = BernardEscrow(_address);
  }


  /**
    * @dev See {IERC20-totalSupply}.
    */
  function totalSupply() public view returns (uint256) {
      return _totalSupply;
  }

  /**
    * @dev See {IERC20-balanceOf}.
    */
  function balanceOf(address account) public view returns (uint256) {
    return _balances[account];
  }

  /**
    * @dev Transfers token amount. Withdraws pending profit before transfer.
    * @param recipient Recipient address.
    * @param amount Token amount.
    * @param _loopLimit Limit for loop iteractions.
    * TESTED
    */
  function transfer(address payable recipient, uint256 amount, uint256 _loopLimit) public returns (bool) {
    escrow.withdrawProfitFromToken(msg.sender, _loopLimit);
    escrow.withdrawProfitFromToken(recipient, _loopLimit);

    _transfer(msg.sender, recipient, amount);
  }

  /**
    * @dev Moves tokens `amount` from `sender` to `recipient`.
    *
    * This is internal function is equivalent to {transfer}, and can be used to
    * e.g. implement automatic token fees, slashing mechanisms, etc.
    *
    * Emits a {Transfer} event.
    *
    * Requirements:
    *
    * - `sender` cannot be the zero address.
    * - `recipient` cannot be the zero address.
    * - `sender` must have a balance of at least `amount`.
    */
  function _transfer(address sender, address recipient, uint256 amount) private {
      require(sender != address(0), "Transfer from the zero address");
      require(recipient != address(0), "Transfer to the zero address");

      _balances[sender] = _balances[sender].sub(amount, "Transfer amount exceeds balance");
      _balances[recipient] = _balances[recipient].add(amount);
      emit Transfer(sender, recipient, amount);
  }

  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
    * the total supply.
    *
    * Emits a {Transfer} event with `from` set to the zero address.
    *
    * Requirements
    *
    * - `to` cannot be the zero address.
    */
  function _mint(address account, uint256 amount) private {
      require(account != address(0), "ERC20: mint to the zero address");

      _totalSupply = _totalSupply.add(amount);
      _balances[account] = _balances[account].add(amount);
      emit Transfer(address(0), account, amount);
  }
}


//SourceUnit: CountdownSessionManager.sol

pragma solidity 0.5.8;

import "./SafeMath.sol";


contract CountdownSessionManager {
  using SafeMath for uint256;

  struct PurchaseInfo {
    address purchaser;
    uint256 shareNumber;
    uint256 previousSharePrice;
  }

  struct ProfitWithdrawalInfo {
    bool jackpotForSharesWithdrawn;
    mapping (uint256 => uint256) purchaseProfitWithdrawnOnPurchase; //  share profit, made in Purchase, withdrawn until including Purchase idx in Session, PurchaseMade => PurchaseWithdrawn
  }

  //  starts from S1 first purchase
  struct SessionInfo {
    uint256 sharesPurchased;    //  shares purchased during ongoing Session
    uint256 jackpotSharePrice;  //  share price after jackpot calculation for ongoing Session
    
    PurchaseInfo[] purchasesInfo;
    mapping (address => uint256[]) purchaseIdxsForPurchaser;  //  Purchase idxs within Session, for purchaser
    mapping (address => uint256) sharesPurchasedByPurchaser;  //  number of shares purchased by Purchaser during Session
    mapping (address => ProfitWithdrawalInfo) profitWithdrawalInfoForPurchaser;  //  information about address profit withdrawal
  }

  uint256 public ongoingSessionIdx;

  mapping (uint256 => SessionInfo) internal sessionsInfo; //  Sessions info, new Session after countdown reset
  mapping (address => uint256[]) private sessionsInfoForPurchaser; //  sessions, where purchaser participated
  
  event SharesProfitWithdrawn(address _address, uint256 _amount, uint256 _session, uint256 _purchase);
  event JackpotForSharesProfitWithdrawn(address _address, uint256 _amount, uint256 _session);


  //  SHARES PURCHASED
  /**
   * @dev Creates new Purchase and add in to list.
   * @param _shareNumber Number of shares.
   * @param _purchaser Purchaser address.
   * @param _rewardForPreviousShares Reward amount for previously purchased shares.
   * TESTED
   */
  function sharesPurchased(uint256 _shareNumber, address _purchaser, uint256 _rewardForPreviousShares) internal {
    require(_shareNumber > 0, "Wrong _shareNumber");
    require(_purchaser != address(0), "Wrong _purchaser");

    SessionInfo storage session = sessionsInfo[ongoingSessionIdx];
    uint256 sharePrice = (_rewardForPreviousShares == 0) ? 0 : _rewardForPreviousShares.div(session.sharesPurchased);
    session.purchaseIdxsForPurchaser[_purchaser].push(session.purchasesInfo.length);
    session.purchasesInfo.push(PurchaseInfo({purchaser: _purchaser, shareNumber: _shareNumber, previousSharePrice: sharePrice}));
    session.sharesPurchasedByPurchaser[_purchaser] = session.sharesPurchasedByPurchaser[_purchaser].add(_shareNumber);
    
    session.sharesPurchased = session.sharesPurchased.add(_shareNumber);
    addSessionForPurchaser(ongoingSessionIdx, _purchaser);
  }

  /**
   * @dev Adds session idx for purchaser.
   * @param _session Session idx.
   * @param _purchaser Purchaser address.
   * TESTED
   */
  function addSessionForPurchaser(uint256 _session, address _purchaser) private {
    uint256[] storage sessionsForPurchaser = sessionsInfoForPurchaser[_purchaser];
    if (sessionsForPurchaser.length == 0) {
      sessionsInfoForPurchaser[_purchaser].push(_session);
    } else if (sessionsForPurchaser[sessionsForPurchaser.length - 1] < _session) {
      sessionsInfoForPurchaser[_purchaser].push(_session);
    }
  }

  //  SESSION COUNTDOWN RESET
  /**
   * @dev Creates new Session on countdown for previous Session reset.
   * @param _prevSharesPart Funds amount, that should be used as reward for previously purchased shares.
   * TESTED
   */
  function countdownWasReset(uint256 _prevSharesPart) internal {
    SessionInfo storage session = sessionsInfo[ongoingSessionIdx];
    uint256 sharePrice = _prevSharesPart.div(session.sharesPurchased);
    session.jackpotSharePrice = sharePrice;
    
    ongoingSessionIdx = ongoingSessionIdx.add(1);
  }

  //  PROFIT
  
  //  1. jackpot for purchased shares in Session
  /**
   * @dev Calculates jackpot for purchased shares for Session for purchaser.
   * @param _session Session idx.
   * TESTED
   */
  function jackpotForSharesInSessionForUser(uint256 _session) public view returns(uint256 profit) {
    SessionInfo storage sessionInfo = sessionsInfo[_session];

    uint256 sharePrice = sessionInfo.jackpotSharePrice;
    require(sharePrice > 0, "No jackpot yet");

    uint256 sharesPurchasedByPurchaser = sessionInfo.sharesPurchasedByPurchaser[msg.sender];
    require(sharesPurchasedByPurchaser > 0, "No shares");

    profit = sharePrice.mul(sharesPurchasedByPurchaser);
  }

  /**
   * @dev Withdraws jackpot for purchased shares for Session for purchaser.
   * @param _session Session idx.
   * TESTED
   */
  function withdrawjackpotForSharesInSession(uint256 _session) public {
    SessionInfo storage session = sessionsInfo[_session];
    ProfitWithdrawalInfo storage profitWithdrawalInfo = session.profitWithdrawalInfoForPurchaser[msg.sender];
    require(profitWithdrawalInfo.jackpotForSharesWithdrawn == false, "Already withdrawn");
    
    profitWithdrawalInfo.jackpotForSharesWithdrawn = true;
    uint256 profit = jackpotForSharesInSessionForUser(_session);

    msg.sender.transfer(profit);
    emit JackpotForSharesProfitWithdrawn(msg.sender, profit, _session);
  }

  //  2. shares profit for Purchase in Session
  /**
   * @dev Calculates profit for Purchase for Session.
   * @param _purchase Purchase idx.
   * @param _session Session idx.
   * @param _fromPurchase Purchase idx to start on.
   * @param _toPurchase Purchase idx to end on.
   * @return Profit amount.
   * TESTED
   */
  function profitForPurchaseInSession(uint256 _purchase, uint256 _session, uint256 _fromPurchase, uint256 _toPurchase) public view returns(uint256 profit) {
    require(_fromPurchase > _purchase, "Wrong _fromPurchase");
    require(_toPurchase >= _fromPurchase, "Wrong _toPurchase");

    SessionInfo storage session = sessionsInfo[_session];
    PurchaseInfo storage purchaseInfo = session.purchasesInfo[_purchase];

    require(_toPurchase <= session.purchasesInfo.length.sub(1), "_toPurchase exceeds");

    uint256 shares = purchaseInfo.shareNumber;

    for (uint256 i = _fromPurchase; i <= _toPurchase; i ++) {
      uint256 sharePrice = session.purchasesInfo[i].previousSharePrice;
      uint256 profitTmp = shares.mul(sharePrice);
      profit = profit.add(profitTmp);
    }
  }

  /**
   * @dev Withdraws profit for Purchase for Session.
   * @param _purchase Purchase idx.
   * @param _session Session idx.
   * @param _loopLimit Loop limit.
   * TESTED
   */
  function withdrawProfitForPurchaseInSession(uint256 _purchase, uint256 _session, uint256 _loopLimit) public {
    require(_loopLimit > 0, "Wrong _loopLimit");

    SessionInfo storage session = sessionsInfo[_session];
    require(_purchase < session.purchasesInfo.length, "_purchase exceeds");

    PurchaseInfo storage purchaseInfo = session.purchasesInfo[_purchase];
    require(purchaseInfo.purchaser == msg.sender, "Not purchaser");

    uint256 purchaseIdxWithdrawnOn = purchaseProfitInSessionWithdrawnOnPurchaseForUser(_purchase, _session);
    uint256 fromPurchaseIdx = (purchaseIdxWithdrawnOn == 0) ? _purchase.add(1) : purchaseIdxWithdrawnOn.add(1);
    
    uint256 toPurchaseIdx = session.purchasesInfo.length.sub(1);
    require(fromPurchaseIdx <= toPurchaseIdx, "No more profit");

    if (toPurchaseIdx.sub(fromPurchaseIdx).add(1) > _loopLimit) {
      toPurchaseIdx = fromPurchaseIdx.add(_loopLimit).sub(1);
    }

    uint256 profit = profitForPurchaseInSession(_purchase, _session, fromPurchaseIdx, toPurchaseIdx);

    sessionsInfo[_session].profitWithdrawalInfoForPurchaser[msg.sender].purchaseProfitWithdrawnOnPurchase[_purchase] = toPurchaseIdx;
    
    msg.sender.transfer(profit);
    emit SharesProfitWithdrawn(msg.sender, profit, _session, _purchase);
  }
  

  //  VIEW

  /**
   * @dev Gets session idxs, where user made purchase.
   * @return Session idxs.
   * TESTED
   */
  function participatedSessionsForUser() public view returns(uint256[] memory sessions) {
    sessions = sessionsInfoForPurchaser[msg.sender];
  }

  //  SessionInfo
  /**
   * @dev Gets total shares purchased in Session.
   * @param _session Session idx.
   * @return Number of shares.
   * TESTED
   */
  function sharesPurchasedInSession(uint256 _session) public view returns(uint256 shares) {
    shares = sessionsInfo[_session].sharesPurchased;
  }
  
  /**
   * @dev Gets jackpot share price in Session.
   * @param _session Session idx.
   * @return Share price.
   * TESTED
   */
  function jackpotSharePriceInSession(uint256 _session) public view returns(uint256 price) {
    price = sessionsInfo[_session].jackpotSharePrice;
  }

  /**
   * @dev Gets number of purchases in Session.
   * @param _session Session idx.
   * @return Number of purchases.
   * TESTED
   */
  function purchaseCountInSession(uint256 _session) public view returns(uint256 purchases) {
    purchases = sessionsInfo[_session].purchasesInfo.length;
  }

  /**
   * @dev Gets purchase info in Session.
   * @param _purchase Purchase idx.
   * @param _session Session idx.
   * @return Purchaser address, Number of purchased shares, share price for previously purchased shares.
   * TESTED
   */
  function purchaseInfoInSession(uint256 _purchase, uint256 _session) public view returns (address purchaser, uint256 shareNumber, uint256 previousSharePrice) {
    SessionInfo storage session = sessionsInfo[_session];
    PurchaseInfo storage purchase = session.purchasesInfo[_purchase];
    return (purchase.purchaser, purchase.shareNumber, purchase.previousSharePrice);
  }

  /**
   * @dev Gets purchase idx in Session for purchaser.
   * @param _session Session idx.
   * @return Purchase idxs.
   * TESTED
   */
  function purchasesInSessionForUser(uint256 _session) public view returns(uint256[] memory purchases) {
    purchases = sessionsInfo[_session].purchaseIdxsForPurchaser[msg.sender];
  }
  
  /**
   * @dev Gets number of shares purchased in Session for purchaser.
   * @param _session Session idx.
   * @return Shares number.
   * TESTED
   */
  function sharesPurchasedInSessionByPurchaser(uint256 _session) public view returns(uint256 shares) {
    shares = sessionsInfo[_session].sharesPurchasedByPurchaser[msg.sender];
  }

  //  ProfitWithdrawalInfo
  /**
   * @dev Checks if purchaser withdrawn jackpot for purchased shares in Session.
   * @param _session Session idx.
   * @return Withdrawn or not.
   * TESTED
   */
  function isJackpotForSharesInSessionWithdrawnForUser(uint256 _session) public view returns(bool withdrawn) {
    withdrawn = sessionsInfo[_session].profitWithdrawalInfoForPurchaser[msg.sender].jackpotForSharesWithdrawn;
  }

  /**
   * @dev Gets purchase idx, on which profit for Purchase was withdrawn.
   * @param _purchase Purchase idx.
   * @param _session Session idx.
   * @return Purchase idx.
   * TESTED
   */
  function purchaseProfitInSessionWithdrawnOnPurchaseForUser(uint256 _purchase, uint256 _session) public view returns(uint256 purchase) {
    purchase = sessionsInfo[_session].profitWithdrawalInfoForPurchaser[msg.sender].purchaseProfitWithdrawnOnPurchase[_purchase];
  }
}


//SourceUnit: ERC20Detailed.sol

pragma solidity 0.5.8;

/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

//SourceUnit: MadoffContract.sol

pragma solidity 0.5.8;

import "./CountdownSessionManager.sol";
import "./BernardEscrow.sol";

contract MadoffContract is CountdownSessionManager, BernardEscrow {

  uint8 constant SHARE_PURCHASE_PERCENT_JACKPOT = 40;
  uint8 constant SHARE_PURCHASE_PERCENT_PURCHASED_SHARES = 50;
  uint8 constant SHARE_PURCHASE_PERCENT_BERNARD_WEBSITE = 5;  //  both has 5%

  uint8 constant JACKPOT_PERCENT_WINNER = 80;

  uint8 public ongoingStage;
  uint8 public maxStageNumber = 13;

  uint16[14] public blocksForStage =                    [21600,   18000,    14400,    10800,    7200,     3600,      1200,      600,       300,       100,       20,        10,         7,          4];
  uint32[14] public sharesForStageToPurchaseOriginal =  [2500,    5000,     3125,     12500,    10000,    62500,     62500,     400000,    390625,    2000000,   1562500,   10000000,   12500000,   25000000];
  uint32[14] public sharesForStageToPurchase =          [2500,    5000,     3125,     12500,    10000,    62500,     62500,     400000,    390625,    2000000,   562500,    10000000,   12500000,   25000000];
  uint256[14] public sharePriceForStage =               [10 trx,  20 trx,   40 trx,   80 trx,   125 trx,  160 trx,   200 trx,   250 trx,   320 trx,   500 trx,   800 trx,   1000 trx,   1000 trx,   1000 trx];
  
  uint256 public latestPurchaseBlock;
  uint256 public ongoingJackpot;
  address public ongoingWinner;
  mapping(address => uint256) public websiteFee;
  mapping(address => uint256) public jackpotForAddr;

  event JackpotWithdrawn(address indexed to, uint256 indexed amount);
  event WebsiteFeeWithdrawn(address indexed to, uint256 indexed amount);
  event Purchase(address indexed from, uint256 indexed sharesNumber);
  event GameRestarted();
 
  /**
   * @dev Contract constructor.
   * @param _token Token address.
   * TESTED
   */
  constructor(address _token) BernardEscrow(_token) public {
  }

  /**
   * @dev Purchases share(s).
   * @param _websiteAddr Website address, that trx was sent from.
   * TESTED
   */
  function purchase(address _websiteAddr) public payable returns(uint256) {
    if (latestPurchaseBlock == 0) {
        latestPurchaseBlock = block.number;
    } else if (ongoingStage > maxStageNumber) {
      ongoingStageDurationExceeded();
      emit GameRestarted();
    } else if (block.number > latestPurchaseBlock.add(blocksForStage[ongoingStage])) {
      ongoingStageDurationExceeded();
    }

    //  jackpot
    uint256 partJackpot = msg.value.mul(uint256(SHARE_PURCHASE_PERCENT_JACKPOT)).div(uint256(100));
    ongoingJackpot = ongoingJackpot.add(partJackpot);

    //  ongoingBernardFee
    uint256 partBernardWebsiteFee = msg.value.mul(uint256(SHARE_PURCHASE_PERCENT_BERNARD_WEBSITE)).div(uint256(100));
    ongoingBernardFee = ongoingBernardFee.add(partBernardWebsiteFee);

    //  websiteFee
    if (_websiteAddr == address(0)) {
      ongoingBernardFee = ongoingBernardFee.add(partBernardWebsiteFee);
    } else {
      websiteFee[_websiteAddr] = websiteFee[_websiteAddr].add(partBernardWebsiteFee);
    }

    //  shares
    uint256 shares = getSharesAndUpdateOngoingStageInfo(msg.value);
    require(shares > 0, "Min 1 share");
    
    //  previous shares
    uint256 partPreviousShares = msg.value.mul(uint256(SHARE_PURCHASE_PERCENT_PURCHASED_SHARES)).div(uint256(100));
    if (sessionsInfo[ongoingSessionIdx].sharesPurchased == 0) {
      ongoingBernardFee = ongoingBernardFee.add(partPreviousShares);
      delete partPreviousShares;
    }
    sharesPurchased(shares, msg.sender, partPreviousShares);
    
    latestPurchaseBlock = block.number;
    ongoingWinner = msg.sender;

    emit Purchase(ongoingWinner, shares);
  }
  
  /**
   * @dev Duration for ongoing stage exceeded.
   * TESTED
   */
  function ongoingStageDurationExceeded() private {
    uint256 jptTmp = ongoingJackpot;
    delete ongoingJackpot;

    //  winner - 80%
    uint256 winnerJptPart = jptTmp.mul(uint256(JACKPOT_PERCENT_WINNER)).div(uint256(100));
    jackpotForAddr[ongoingWinner] = jackpotForAddr[ongoingWinner].add(winnerJptPart);

    //  previous shares - 20%
    uint256 prevSharesPart = jptTmp.sub(winnerJptPart);
    countdownWasReset(prevSharesPart);
    
    sharesForStageToPurchase = sharesForStageToPurchaseOriginal;

    delete ongoingWinner;
    delete ongoingStage;
  }

  /**
   * @dev Calculates share number and increase ongoing stage if needed.
   * @param _amount Funds amount.
   * @return Shares number.
   * TESTED
   */
  function getSharesAndUpdateOngoingStageInfo(uint256 _amount) private returns(uint256) {
    bool loop = true;
    uint256 resultShares;
    uint256 valueToSpend = _amount;
    uint256 valueSpent;

    do {
      uint256 sharesForOngoingStage = getShares(ongoingStage, valueToSpend);
      
      if (sharesForOngoingStage <= sharesForStageToPurchase[ongoingStage]) {
        resultShares = resultShares.add(sharesForOngoingStage);
        sharesForStageToPurchase[ongoingStage] = uint32(uint256(sharesForStageToPurchase[ongoingStage]).sub(sharesForOngoingStage));

        valueSpent = sharesForOngoingStage.mul(sharePriceForStage[ongoingStage]);
        valueToSpend = valueToSpend.sub(valueSpent);

        if (sharesForStageToPurchase[ongoingStage] == 0) {
          ongoingStage += 1;
        }

        loop = false;
      } else {
        valueSpent = uint256(sharesForStageToPurchase[ongoingStage]).mul(sharePriceForStage[ongoingStage]);
        valueToSpend = valueToSpend.sub(valueSpent);
        resultShares = resultShares.add(sharesForStageToPurchase[ongoingStage]);

        delete sharesForStageToPurchase[ongoingStage];
        ongoingStage += 1;
      }
    } while (loop); 

    require(valueToSpend == 0, "Wrong value sent");  //  should be no unspent amount

    return resultShares;
  }

  /**
   * @dev Calculates share number.
   * @param _stage Stage to be used.
   * @param _amount Funds amount.
   * @return Shares number.
   * TESTED
   */
  function getShares(uint8 _stage, uint256 _amount) private view returns(uint256 shares) {
    require(_stage <= maxStageNumber, "Stage overflow");

    uint256 sharePrice = sharePriceForStage[_stage];
    shares = _amount.div(uint256(sharePrice));
  }

  //  WITHDRAW

  /**
   * @dev Withdraws website fee.
   * TESTED
   */
  function withdrawWebsiteFee() public {
    uint256 feeTmp = websiteFee[msg.sender];
    require(feeTmp > 0, "No fee");
    delete websiteFee[msg.sender];
    
    msg.sender.transfer(feeTmp);
    emit WebsiteFeeWithdrawn(msg.sender, feeTmp);
  }

  /**
   * @dev Withdraws jackpot.
   * TESTED
   */
  function withdrawJackpot() public {
    uint256 jptTmp = jackpotForAddr[msg.sender];
    require(jptTmp > 0, "No jackpot");
    delete jackpotForAddr[msg.sender];
    
    msg.sender.transfer(jptTmp);
    emit JackpotWithdrawn(msg.sender, jptTmp);
  }
}


//SourceUnit: SafeMath.sol

pragma solidity ^0.5.0;

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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
pragma solidity 0.4.25;

contract ERC20Interface {

    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

}

contract _0xBitconnect {
  using SafeMath for uint;

  /*=================================
  =            MODIFIERS            =
  =================================*/

  modifier onlyHolders() {
    require(myFrontEndTokens() > 0);
    _;
  }

  modifier dividendHolder() {
    require(myDividends(true) > 0);
    _;
  }

  modifier onlyAdministrator(){
    address _customerAddress = msg.sender;
    require(administrators[_customerAddress]);
    _;
  }

  /*==============================
  =            EVENTS            =
  ==============================*/

  event onTokenPurchase(
    address indexed customerAddress,
    uint incoming,
    uint tokensMinted,
    address indexed referredBy
  );

  event UserDividendRate(
    address user,
    uint divRate
  );

  event onTokenSell(
    address indexed customerAddress,
    uint tokensBurned,
    uint earned
  );

  event onReinvestment(
    address indexed customerAddress,
    uint reinvested,
    uint tokensMinted
  );

  event onWithdraw(
    address indexed customerAddress,
    uint withdrawn
  );

  event Transfer(
    address indexed from,
    address indexed to,
    uint tokens
  );

  event Approval(
    address indexed tokenOwner,
    address indexed spender,
    uint tokens
  );

  event Allocation(
    uint toBankRoll,
    uint toReferrer,
    uint toTokenHolders,
    uint toDivCardHolders,
    uint forTokens
  );

  event Referral(
    address referrer,
    uint amountReceived
  );

  /*=====================================
  =            CONSTANTS                =
  =====================================*/

  uint8 constant public                decimals              = 18;

  uint constant internal               tokenPriceInitial_    = 0.000653 ether; //ether is used to format as 18 decimals
  uint constant internal               magnitude             = 2**64;

  uint constant internal               MULTIPLIER            = 9615;

  uint constant internal               MIN_TOK_BUYIN         = 0.0001 ether;
  uint constant internal               MIN_TOKEN_SELL_AMOUNT = 0.0001 ether;
  uint constant internal               MIN_TOKEN_TRANSFER    = 1e10;
  uint constant internal               referrer_percentage   = 25;

  ERC20Interface constant internal     _0xBTC                = ERC20Interface(0x9eD7EA9aaE40ca11033266FB06713191656A9893);

  uint public                          stakingRequirement    = 100e18;

  /*================================
   =          CONFIGURABLES         =
   ================================*/

  string public                        name               = "0xBitconnect";
  string public                        symbol             = "0xBitconnect";

  address internal                     bankrollAddress;

  _0xBitconnectDividendCards                   divCardContract;

  /*================================
   =            DATASETS            =
   ================================*/

  // Tracks front & backend tokens
  mapping(address => uint) internal    frontTokenBalanceLedger_;
  mapping(address => uint) internal    dividendTokenBalanceLedger_;
  mapping(address =>
  mapping (address => uint))
  public      allowed;

  // Tracks dividend rates for users
  mapping(uint8   => bool)    internal validDividendRates_;
  mapping(address => bool)    internal userSelectedRate;
  mapping(address => uint8)   internal userDividendRate;

  // Payout tracking
  mapping(address => uint)    internal referralBalance_;
  mapping(address => int256)  internal payoutsTo_;

  uint public                          current0xbtcInvested;

  uint internal                        tokenSupply    = 0;
  uint internal                        divTokenSupply = 0;

  uint internal                        profitPerDivToken;

  mapping(address => bool) public      administrators;

  bool public                          regularPhase = false;

  /*=======================================
  =            PUBLIC FUNCTIONS           =
  =======================================*/
  constructor (address _bankrollAddress, address _divCardAddress)
  public
  {
    bankrollAddress = _bankrollAddress;
    divCardContract = _0xBitconnectDividendCards(_divCardAddress);

    administrators[msg.sender] = true; // ADMIN FORMAT

    administrators[msg.sender] = true; // Helps with debugging!

    validDividendRates_[10] = true;
    validDividendRates_[20] = true;
    validDividendRates_[30] = true;

    userSelectedRate[bankrollAddress] = true;
    userDividendRate[bankrollAddress] = 30;

  }

  /**
   * Same as buy, but explicitly sets your dividend percentage.
   * If this has been called before, it will update your `default&#39; dividend
   *   percentage for regular buy transactions going forward.
   */
  function buyAndSetDivPercentage(uint _0xbtcAmount, address _referredBy, uint8 _divChoice, string providedUnhashedPass)
  public
  returns (uint)
  {

    require(regularPhase);

    // Dividend percentage should be a currently accepted value.
    require (validDividendRates_[_divChoice]);

    // Set the dividend fee percentage denominator.
    userSelectedRate[msg.sender] = true;
    userDividendRate[msg.sender] = _divChoice;
    emit UserDividendRate(msg.sender, _divChoice);

    // Finally, purchase tokens.
    purchaseTokens(_0xbtcAmount, _referredBy);
  }

  // All buys except for the above one require regular phase.

  function buy(uint _0xbtcAmount, address _referredBy)
  public
  returns(uint)
  {
    require(regularPhase);
    address _customerAddress = msg.sender;
    require (userSelectedRate[_customerAddress]);
    purchaseTokens(_0xbtcAmount, _referredBy);
  }

  function buyAndTransfer(uint _0xbtcAmount, address _referredBy, address target)
  public
  {
    bytes memory empty;
    buyAndTransfer(_0xbtcAmount,_referredBy,target, empty, 20);
  }

  function buyAndTransfer(uint _0xbtcAmount, address _referredBy, address target, bytes _data)
  public
  {
    buyAndTransfer(_0xbtcAmount, _referredBy, target, _data, 20);
  }

  // Overload
  function buyAndTransfer(uint _0xbtcAmount, address _referredBy, address target, bytes _data, uint8 divChoice)
  public
  {
    require(regularPhase);
    address _customerAddress = msg.sender;
    uint256 frontendBalance = frontTokenBalanceLedger_[msg.sender];
    if (userSelectedRate[_customerAddress] && divChoice == 0) {
      purchaseTokens(_0xbtcAmount, _referredBy);
    } else {
      buyAndSetDivPercentage(_0xbtcAmount,_referredBy, divChoice, "0x0");
    }
    uint256 difference = SafeMath.sub(frontTokenBalanceLedger_[msg.sender], frontendBalance);
    transferTo(msg.sender, target, difference, _data);
  }

  // No Fallback functionality
  function() public{
    revert();
  }

  function reinvest()
  dividendHolder()
  public
  {
    require(regularPhase);
    uint _dividends = myDividends(false);

    // Pay out requisite `virtual&#39; dividends.
    address _customerAddress            = msg.sender;
    payoutsTo_[_customerAddress]       += (int256) (_dividends * magnitude);

    _dividends                         += referralBalance_[_customerAddress];
    referralBalance_[_customerAddress]  = 0;

    uint _tokens                        = purchaseTokens(_dividends.div(1e10), 0x0); //to 8 Decimals

    // Fire logging event.
    emit onReinvestment(_customerAddress, _dividends, _tokens);
  }

  function exit()
  public
  {
    require(regularPhase);
    // Retrieve token balance for caller, then sell them all.
    address _customerAddress = msg.sender;
    uint _tokens             = frontTokenBalanceLedger_[_customerAddress];

    if(_tokens > 0) sell(_tokens);

    withdraw(_customerAddress);
  }

  function withdraw(address _recipient)
  dividendHolder()
  public
  {
    require(regularPhase);
    // Setup data
    address _customerAddress           = msg.sender;
    uint _dividends                    = myDividends(false);

    // update dividend tracker
    payoutsTo_[_customerAddress]       +=  (int256) (_dividends * magnitude);

    // add ref. bonus
    _dividends                         += referralBalance_[_customerAddress];
    referralBalance_[_customerAddress]  = 0;

    if (_recipient == address(0x0)){
      _recipient = msg.sender;
    }

    _dividends = _dividends.div(1e10); //to 8 decimals
    _0xBTC.transfer(_recipient,_dividends);

    // Fire logging event.
    emit onWithdraw(_recipient, _dividends);
  }

  // Sells front-end tokens.
  function sell(uint _amountOfTokens)
  onlyHolders()
  public
  {
    require(regularPhase);

    require(_amountOfTokens <= frontTokenBalanceLedger_[msg.sender]);

    uint _frontEndTokensToBurn = _amountOfTokens;

    // Calculate how many dividend tokens this action burns.
    // Computed as the caller&#39;s average dividend rate multiplied by the number of front-end tokens held.
    // As an additional guard, we ensure that the dividend rate is between 2 and 50 inclusive.
    uint userDivRate  = getUserAverageDividendRate(msg.sender);
    require ((2*magnitude) <= userDivRate && (50*magnitude) >= userDivRate );
    uint _divTokensToBurn = (_frontEndTokensToBurn.mul(userDivRate)).div(magnitude);

    // Calculate 0xbtc received before dividends
    uint _0xbtc = tokensTo0xbtc_(_frontEndTokensToBurn);

    if (_0xbtc > current0xbtcInvested){
      // Well, congratulations, you&#39;ve emptied the coffers.
      current0xbtcInvested = 0;
    } else { current0xbtcInvested = current0xbtcInvested - _0xbtc; }

    // Calculate dividends generated from the sale.
    uint _dividends = (_0xbtc.mul(getUserAverageDividendRate(msg.sender)).div(100)).div(magnitude);

    // Calculate 0xbtc receivable net of dividends.
    uint _taxed0xbtc = _0xbtc.sub(_dividends);

    // Burn the sold tokens (both front-end and back-end variants).
    tokenSupply         = tokenSupply.sub(_frontEndTokensToBurn);
    divTokenSupply      = divTokenSupply.sub(_divTokensToBurn);

    // Subtract the token balances for the seller
    frontTokenBalanceLedger_[msg.sender]    = frontTokenBalanceLedger_[msg.sender].sub(_frontEndTokensToBurn);
    dividendTokenBalanceLedger_[msg.sender] = dividendTokenBalanceLedger_[msg.sender].sub(_divTokensToBurn);

    // Update dividends tracker
    int256 _updatedPayouts  = (int256) (profitPerDivToken * _divTokensToBurn + (_taxed0xbtc * magnitude));
    payoutsTo_[msg.sender] -= _updatedPayouts;

    // Let&#39;s avoid breaking arithmetic where we can, eh?
    if (divTokenSupply > 0) {
      // Update the value of each remaining back-end dividend token.
      profitPerDivToken = profitPerDivToken.add((_dividends * magnitude) / divTokenSupply);
    }

    // Fire logging event.
    emit onTokenSell(msg.sender, _frontEndTokensToBurn, _taxed0xbtc);
  }

  /**
   * Transfer tokens from the caller to a new holder.
   * No charge incurred for the transfer. We&#39;d make a terrible bank.
   */
  function transfer(address _toAddress, uint _amountOfTokens)
  onlyHolders()
  public
  returns(bool)
  {
    require(_amountOfTokens >= MIN_TOKEN_TRANSFER
    && _amountOfTokens <= frontTokenBalanceLedger_[msg.sender]);
    bytes memory empty;
    transferFromInternal(msg.sender, _toAddress, _amountOfTokens, empty);
    return true;

  }

  function approve(address spender, uint tokens)
  public
  returns (bool)
  {
    address _customerAddress           = msg.sender;
    allowed[_customerAddress][spender] = tokens;

    // Fire logging event.
    emit Approval(_customerAddress, spender, tokens);

    // Good old ERC20.
    return true;
  }

  /**
   * Transfer tokens from the caller to a new holder: the Used By Smart Contracts edition.
   * No charge incurred for the transfer. No seriously, we&#39;d make a terrible bank.
   */
  function transferFrom(address _from, address _toAddress, uint _amountOfTokens)
  public
  returns(bool)
  {
    // Setup variables
    address _customerAddress     = _from;
    bytes memory empty;
    // Make sure we own the tokens we&#39;re transferring, are ALLOWED to transfer that many tokens,
    // and are transferring at least one full token.
    require(_amountOfTokens >= MIN_TOKEN_TRANSFER
    && _amountOfTokens <= frontTokenBalanceLedger_[_customerAddress]
    && _amountOfTokens <= allowed[_customerAddress][msg.sender]);

    transferFromInternal(_from, _toAddress, _amountOfTokens, empty);

    // Good old ERC20.
    return true;

  }

  function transferTo (address _from, address _to, uint _amountOfTokens, bytes _data)
  public
  {
    if (_from != msg.sender){
      require(_amountOfTokens >= MIN_TOKEN_TRANSFER
      && _amountOfTokens <= frontTokenBalanceLedger_[_from]
      && _amountOfTokens <= allowed[_from][msg.sender]);
    }
    else{
      require(_amountOfTokens >= MIN_TOKEN_TRANSFER
      && _amountOfTokens <= frontTokenBalanceLedger_[_from]);
    }

    transferFromInternal(_from, _to, _amountOfTokens, _data);
  }

  // Who&#39;d have thought we&#39;d need this thing floating around?
  function totalSupply()
  public
  view
  returns (uint256)
  {
    return tokenSupply;
  }

  /*----------  ADMINISTRATOR ONLY FUNCTIONS  ----------*/

  function startRegularPhase()
  onlyAdministrator
  public
  {
    regularPhase = true;
  }

  // The death of a great man demands the birth of a great son.
  function setAdministrator(address _newAdmin, bool _status)
  onlyAdministrator()
  public
  {
    administrators[_newAdmin] = _status;
  }

  function setStakingRequirement(uint _amountOfTokens)
  onlyAdministrator()
  public
  {
    // This plane only goes one way, lads. Never below the initial.
    require (_amountOfTokens >= 100e18);
    stakingRequirement = _amountOfTokens;
  }

  function setName(string _name)
  onlyAdministrator()
  public
  {
    name = _name;
  }

  function setSymbol(string _symbol)
  onlyAdministrator()
  public
  {
    symbol = _symbol;
  }

  function changeBankroll(address _newBankrollAddress)
  onlyAdministrator
  public
  {
    bankrollAddress = _newBankrollAddress;
  }

  /*----------  HELPERS AND CALCULATORS  ----------*/

  function total0xbtcBalance()
  public
  view
  returns(uint)
  {
    return _0xBTC.balanceOf(address(this));
  }

  function total0xbtcReceived()
  public
  view
  returns(uint)
  {
    return current0xbtcInvested;
  }

  /**
   * Retrieves your currently selected dividend rate.
   */
  function getMyDividendRate()
  public
  view
  returns(uint8)
  {
    address _customerAddress = msg.sender;
    require(userSelectedRate[_customerAddress]);
    return userDividendRate[_customerAddress];
  }

  /**
   * Retrieve the total frontend token supply
   */
  function getFrontEndTokenSupply()
  public
  view
  returns(uint)
  {
    return tokenSupply;
  }

  /**
   * Retreive the total dividend token supply
   */
  function getDividendTokenSupply()
  public
  view
  returns(uint)
  {
    return divTokenSupply;
  }

  /**
   * Retrieve the frontend tokens owned by the caller
   */
  function myFrontEndTokens()
  public
  view
  returns(uint)
  {
    address _customerAddress = msg.sender;
    return getFrontEndTokenBalanceOf(_customerAddress);
  }

  /**
   * Retrieve the dividend tokens owned by the caller
   */
  function myDividendTokens()
  public
  view
  returns(uint)
  {
    address _customerAddress = msg.sender;
    return getDividendTokenBalanceOf(_customerAddress);
  }

  function myReferralDividends()
  public
  view
  returns(uint)
  {
    return myDividends(true) - myDividends(false);
  }

  function myDividends(bool _includeReferralBonus)
  public
  view
  returns(uint)
  {
    address _customerAddress = msg.sender;
    return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress) ;
  }

  function theDividendsOf(bool _includeReferralBonus, address _customerAddress)
  public
  view
  returns(uint)
  {
    return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress) ;
  }

  function getFrontEndTokenBalanceOf(address _customerAddress)
  view
  public
  returns(uint)
  {
    return frontTokenBalanceLedger_[_customerAddress];
  }

  function balanceOf(address _owner)
  view
  public
  returns(uint)
  {
    return getFrontEndTokenBalanceOf(_owner);
  }

  function getDividendTokenBalanceOf(address _customerAddress)
  view
  public
  returns(uint)
  {
    return dividendTokenBalanceLedger_[_customerAddress];
  }

  function dividendsOf(address _customerAddress)
  view
  public
  returns(uint)
  {
    return (uint) ((int256)(profitPerDivToken * dividendTokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
  }

  // Get the sell price at the user&#39;s average dividend rate
  function sellPrice()
  public
  view
  returns(uint)
  {
    uint price;

    // Calculate the tokens received for 0.001 0xbtc.
    // Divide to find the average, to calculate the price.
    uint tokensReceivedFor0xbtc = btcToTokens_(0.001 ether);

    price = (1e18 * 0.001 ether) / tokensReceivedFor0xbtc;

    // Factor in the user&#39;s average dividend rate
    uint theSellPrice = price.sub((price.mul(getUserAverageDividendRate(msg.sender)).div(100)).div(magnitude));

    return theSellPrice;
  }

  // Get the buy price at a particular dividend rate
  function buyPrice(uint dividendRate)
  public
  view
  returns(uint)
  {
    uint price;

    // Calculate the tokens received for 100 finney.
    // Divide to find the average, to calculate the price.
    uint tokensReceivedFor0xbtc = btcToTokens_(0.001 ether);

    price = (1e18 * 0.001 ether) / tokensReceivedFor0xbtc;

    // Factor in the user&#39;s selected dividend rate
    uint theBuyPrice = (price.mul(dividendRate).div(100)).add(price);

    return theBuyPrice;
  }

  function calculateTokensReceived(uint _0xbtcToSpend)
  public
  view
  returns(uint)
  {
    uint fixedAmount = _0xbtcToSpend.mul(1e10);
    uint _dividends      = (fixedAmount.mul(userDividendRate[msg.sender])).div(100);
    uint _taxed0xbtc  = fixedAmount.sub(_dividends);
    uint _amountOfTokens = btcToTokens_(_taxed0xbtc);
    return  _amountOfTokens;
  }

  // When selling tokens, we need to calculate the user&#39;s current dividend rate.
  // This is different from their selected dividend rate.
  function calculate0xbtcReceived(uint _tokensToSell)
  public
  view
  returns(uint)
  {
    require(_tokensToSell <= tokenSupply);
    uint _0xbtc               = tokensTo0xbtc_(_tokensToSell);
    uint userAverageDividendRate = getUserAverageDividendRate(msg.sender);
    uint _dividends              = (_0xbtc.mul(userAverageDividendRate).div(100)).div(magnitude);
    uint _taxed0xbtc          = _0xbtc.sub(_dividends);
    return  _taxed0xbtc.div(1e10);
  }

  /*
   * Get&#39;s a user&#39;s average dividend rate - which is just their divTokenBalance / tokenBalance
   * We multiply by magnitude to avoid precision errors.
   */

  function getUserAverageDividendRate(address user) public view returns (uint) {
    return (magnitude * dividendTokenBalanceLedger_[user]).div(frontTokenBalanceLedger_[user]);
  }

  function getMyAverageDividendRate() public view returns (uint) {
    return getUserAverageDividendRate(msg.sender);
  }

  /*==========================================
  =            INTERNAL FUNCTIONS            =
  ==========================================*/

  /* Purchase tokens with 0xbtc.
     During ICO phase, dividends should go to the bankroll
     During normal operation:
       0.5% should go to the master dividend card
       0.5% should go to the matching dividend card
       25% of dividends should go to the referrer, if any is provided. */
  function purchaseTokens(uint _incoming, address _referredBy)
  internal
  returns(uint)
  {

    require(_incoming.mul(1e10) >= MIN_TOK_BUYIN || msg.sender == bankrollAddress, "Tried to buy below the min 0xbtc buyin threshold.");

    uint toReferrer;
    uint toTokenHolders;
    uint toDivCardHolders;

    uint dividendAmount;

    uint tokensBought;

    uint remaining0xbtc = _incoming.mul(1e10);

    uint fee;

    // 1% for dividend card holders is taken off before anything else
    if (regularPhase) {
      toDivCardHolders = _incoming.mul(1e8);
      remaining0xbtc = remaining0xbtc.sub(toDivCardHolders);
    }

    /* Next, we tax for dividends:
       Dividends = (0xbtc * div%) / 100
       Important note: the 1% sent to div-card holders
                       is handled prior to any dividend taxes are considered. */

    // Calculate the total dividends on this buy
    dividendAmount = (remaining0xbtc.mul(userDividendRate[msg.sender])).div(100);

    remaining0xbtc   = remaining0xbtc.sub(dividendAmount);

    // If we&#39;re in the ICO and bankroll is buying, don&#39;t tax
    // if (icoPhase && msg.sender == bankrollAddress) {
    //   remaining0xbtc = remaining0xbtc + dividendAmount;
    // }

    // Calculate how many tokens to buy:
    tokensBought         = btcToTokens_(remaining0xbtc);

    // This is where we actually mint tokens:
    tokenSupply    = tokenSupply.add(tokensBought);
    divTokenSupply = divTokenSupply.add(tokensBought.mul(userDividendRate[msg.sender]));

    /* Update the total investment tracker
       Note that this must be done AFTER we calculate how many tokens are bought -
       because btcToTokens needs to know the amount *before* investment, not *after* investment. */

    current0xbtcInvested = current0xbtcInvested + remaining0xbtc;

    // Ccheck for referrals

    // 25% goes to referrers, if set
    // toReferrer = (dividends * 25)/100
    if (_referredBy != 0x0000000000000000000000000000000000000000 &&
    _referredBy != msg.sender &&
    frontTokenBalanceLedger_[_referredBy] >= stakingRequirement)
    {
      toReferrer = (dividendAmount.mul(referrer_percentage)).div(100);
      referralBalance_[_referredBy] += toReferrer;
      emit Referral(_referredBy, toReferrer);
    }

    // The rest of the dividends go to token holders
    toTokenHolders = dividendAmount.sub(toReferrer);

    fee = toTokenHolders * magnitude;
    fee = fee - (fee - (tokensBought.mul(userDividendRate[msg.sender]) * (toTokenHolders * magnitude / (divTokenSupply))));

    // Finally, increase the divToken value
    profitPerDivToken       = profitPerDivToken.add((toTokenHolders.mul(magnitude)).div(divTokenSupply));
    payoutsTo_[msg.sender] += (int256) ((profitPerDivToken * tokensBought.mul(userDividendRate[msg.sender])) - fee);

    // Update the buyer&#39;s token amounts
    frontTokenBalanceLedger_[msg.sender] = frontTokenBalanceLedger_[msg.sender].add(tokensBought);
    dividendTokenBalanceLedger_[msg.sender] = dividendTokenBalanceLedger_[msg.sender].add(tokensBought.mul(userDividendRate[msg.sender]));

    //Lets receive the 0xbtc
    _0xBTC.transferFrom(msg.sender,address(this),_incoming);

    // Transfer to div cards
        if (regularPhase) {
      _0xBTC.approve(address(divCardContract),toDivCardHolders.div(1e10));
      divCardContract.receiveDividends(toDivCardHolders.div(1e10),userDividendRate[msg.sender]); }

    // This event should help us track where all the 0xbtc is going
    emit Allocation(0, toReferrer, toTokenHolders, toDivCardHolders, remaining0xbtc);

    // Sanity checking
    uint sum = toReferrer + toTokenHolders + toDivCardHolders + remaining0xbtc - _incoming.mul(1e10);
    assert(sum == 0);
  }

  // How many tokens one gets from a certain amount of 0xbtc.
  function btcToTokens_(uint _0xbtcAmount)
  public
  view
  returns(uint)
  {

    //0xbtcAmount expected as 18 decimals instead of 8

    require(_0xbtcAmount > MIN_TOK_BUYIN, "Tried to buy tokens with too little 0xbtc.");

    uint _0xbtcTowardsVariablePriceTokens = _0xbtcAmount;

    uint varPriceTokens = 0;

    if (_0xbtcTowardsVariablePriceTokens != 0) {

      uint simulated0xbtcBeforeInvested = toPowerOfThreeHalves(tokenSupply.div(MULTIPLIER * 1e6)).mul(2).div(3);
      uint simulated0xbtcAfterInvested  = simulated0xbtcBeforeInvested + _0xbtcTowardsVariablePriceTokens;

      uint tokensBefore = toPowerOfTwoThirds(simulated0xbtcBeforeInvested.mul(3).div(2)).mul(MULTIPLIER);
      uint tokensAfter  = toPowerOfTwoThirds(simulated0xbtcAfterInvested.mul(3).div(2)).mul(MULTIPLIER);

      /*  Investment IS already multiplied by 1e18; however, because this is taken to a power of (2/3),
         we need to multiply the result by 1e6 to get back to the correct number of decimals. */

      varPriceTokens = (1e6) * tokensAfter.sub(tokensBefore);
    }

    uint totalTokensReceived = varPriceTokens;

    assert(totalTokensReceived > 0);
    return totalTokensReceived;
  }

  // How much Ether we get from selling N tokens
  function tokensTo0xbtc_(uint _tokens)
  public
  view
  returns(uint)
  {
    require (_tokens >= MIN_TOKEN_SELL_AMOUNT, "Tried to sell too few tokens.");

    /*
     *  i = investment, p = price, t = number of tokens
     *
     *  i_current = p_initial * t_current                   (for t_current <= t_initial)
     *  i_current = i_initial + (2/3)(t_current)^(3/2)      (for t_current >  t_initial)
     *
     *  t_current = i_current / p_initial                   (for i_current <= i_initial)
     *  t_current = t_initial + ((3/2)(i_current))^(2/3)    (for i_current >  i_initial)
     */

    uint tokensToSellAtVariablePrice = _tokens;

    uint _0xbtcFromVarPriceTokens;

    // Now, actually calculate:

    if (tokensToSellAtVariablePrice != 0) {

      /* Note: Unlike the sister function in btcToTokens, we don&#39;t have to calculate any "virtual" token count.

         We have the equations for total investment above; note that this is for TOTAL.
         To get the 0xbtc received from this sell, we calculate the new total investment after this sell.
         Note that we divide by 1e6 here as the inverse of multiplying by 1e6 in btcToTokens. */

      uint investmentBefore = toPowerOfThreeHalves(tokenSupply.div(MULTIPLIER * 1e6)).mul(2).div(3);
      uint investmentAfter  = toPowerOfThreeHalves((tokenSupply - tokensToSellAtVariablePrice).div(MULTIPLIER * 1e6)).mul(2).div(3);

      _0xbtcFromVarPriceTokens = investmentBefore.sub(investmentAfter);
    }

    uint _0xbtcReceived = _0xbtcFromVarPriceTokens;

    assert(_0xbtcReceived > 0);
    return _0xbtcReceived;
  }

  function transferFromInternal(address _from, address _toAddress, uint _amountOfTokens, bytes _data)
  internal
  {
    require(regularPhase);
    require(_toAddress != address(0x0));
    address _customerAddress     = _from;
    uint _amountOfFrontEndTokens = _amountOfTokens;

    // Withdraw all outstanding dividends first (including those generated from referrals).
    if(theDividendsOf(true, _customerAddress) > 0) withdrawFrom(_customerAddress);

    // Calculate how many back-end dividend tokens to transfer.
    // This amount is proportional to the caller&#39;s average dividend rate multiplied by the proportion of tokens being transferred.
    uint _amountOfDivTokens = _amountOfFrontEndTokens.mul(getUserAverageDividendRate(_customerAddress)).div(magnitude);

    if (_customerAddress != msg.sender){
      // Update the allowed balance.
      // Don&#39;t update this if we are transferring our own tokens (via transfer or buyAndTransfer)
      allowed[_customerAddress][msg.sender] -= _amountOfTokens;
    }

    // Exchange tokens
    frontTokenBalanceLedger_[_customerAddress]    = frontTokenBalanceLedger_[_customerAddress].sub(_amountOfFrontEndTokens);
    frontTokenBalanceLedger_[_toAddress]          = frontTokenBalanceLedger_[_toAddress].add(_amountOfFrontEndTokens);
    dividendTokenBalanceLedger_[_customerAddress] = dividendTokenBalanceLedger_[_customerAddress].sub(_amountOfDivTokens);
    dividendTokenBalanceLedger_[_toAddress]       = dividendTokenBalanceLedger_[_toAddress].add(_amountOfDivTokens);

    // Recipient inherits dividend percentage if they have not already selected one.
    if(!userSelectedRate[_toAddress])
    {
      userSelectedRate[_toAddress] = true;
      userDividendRate[_toAddress] = userDividendRate[_customerAddress];
    }

    // Update dividend trackers
    payoutsTo_[_customerAddress] -= (int256) (profitPerDivToken * _amountOfDivTokens);
    payoutsTo_[_toAddress]       += (int256) (profitPerDivToken * _amountOfDivTokens);

    uint length;

    assembly {
      length := extcodesize(_toAddress)
    }

    if (length > 0){
      // its a contract
      // note: at ethereum update ALL addresses are contracts
      ERC223Receiving receiver = ERC223Receiving(_toAddress);
      receiver.tokenFallback(_from, _amountOfTokens, _data);
    }

    // Fire logging event.
    emit Transfer(_customerAddress, _toAddress, _amountOfFrontEndTokens);
  }

  // Called from transferFrom. Always checks if _customerAddress has dividends.
  function withdrawFrom(address _customerAddress)
  internal
  {
    // Setup data
    uint _dividends                    = theDividendsOf(false, _customerAddress);

    // update dividend tracker
    payoutsTo_[_customerAddress]       +=  (int256) (_dividends * magnitude);

    // add ref. bonus
    _dividends                         += referralBalance_[_customerAddress];
    referralBalance_[_customerAddress]  = 0;

    _0xBTC.transfer(_customerAddress,_dividends);

    // Fire logging event.
    emit onWithdraw(_customerAddress, _dividends);
  }

  /*=======================
   =   MATHS FUNCTIONS    =
   ======================*/

  function toPowerOfThreeHalves(uint x) public pure returns (uint) {
    // m = 3, n = 2
    // sqrt(x^3)
    return sqrt(x**3);
  }

  function toPowerOfTwoThirds(uint x) public pure returns (uint) {
    // m = 2, n = 3
    // cbrt(x^2)
    return cbrt(x**2);
  }

  function sqrt(uint x) public pure returns (uint y) {
    uint z = (x + 1) / 2;
    y = x;
    while (z < y) {
      y = z;
      z = (x / z + z) / 2;
    }
  }

  function cbrt(uint x) public pure returns (uint y) {
    uint z = (x + 1) / 3;
    y = x;
    while (z < y) {
      y = z;
      z = (x / (z*z) + 2 * z) / 3;
    }
  }
}

/*=======================
 =     INTERFACES       =
 ======================*/


contract _0xBitconnectDividendCards {
  function ownerOf(uint /*_divCardId*/) public pure returns (address) {}
  function receiveDividends(uint amount, uint divCardRate) public {}
}

contract _0xBitconnectBankroll{
  function receiveDividends(uint amount) public {}
}


contract ERC223Receiving {
  function tokenFallback(address _from, uint _amountOfTokens, bytes _data) public returns (bool);
}

// Think it&#39;s safe to say y&#39;all know what this is.

library SafeMath {

  function mul(uint a, uint b) internal pure returns (uint) {
    if (a == 0) {
      return 0;
    }
    uint c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
}
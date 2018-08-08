pragma solidity ^0.4.21;

/**
 * @title InteractiveCrowdsaleLib
 * @author Modular, Inc
 *
 * version 2.0.0
 * Copyright (c) 2017 Modular, Inc
 * The MIT License (MIT)
 *
 * The InteractiveCrowdsale Library provides functionality to create a crowdsale
 * based on the white paper initially proposed by Jason Teutsch and Vitalik
 * Buterin. See https://people.cs.uchicago.edu/~teutsch/papers/ico.pdf for
 * further information.
 *
 * This library was developed in a collaborative effort among many organizations
 * including TrueBit, Modular, and Consensys.
 * For further information: truebit.io, modular.network,
 * consensys.net
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

library InteractiveCrowdsaleLib {
  using SafeMath for uint256;
  using TokenLib for TokenLib.TokenStorage;
  using LinkedListLib for LinkedListLib.LinkedList;

  // Node constants for use in the linked list
  uint256 constant NULL = 0;
  uint256 constant HEAD = 0;
  bool constant PREV = false;
  bool constant NEXT = true;

  struct InteractiveCrowdsaleStorage {

    address owner;     //owner of the crowdsale

  	uint256 tokensPerEth;  //number of tokens received per ether
  	uint256 startTime; //ICO start time, timestamp
  	uint256 endTime; //ICO end time, timestamp automatically calculated
    uint256 ownerBalance; //owner wei Balance
    uint256 startingTokenBalance; //initial amount of tokens for sale

    //shows how much wei an address has contributed
  	mapping (address => uint256) hasContributed;

    //For token withdraw function, maps a user address to the amount of tokens they can withdraw
  	mapping (address => uint256) withdrawTokensMap;

    // any leftover wei that buyers contributed that didn&#39;t add up to a whole token amount
    mapping (address => uint256) leftoverWei;

  	InteractiveCrowdsaleToken token; //token being sold

    // List of personal valuations, sorted from smallest to largest (from LinkedListLib)
    LinkedListLib.LinkedList valuationsList;

    // Info holder for token creation
    TokenLib.TokenStorage tokenInfo;

    uint256 endWithdrawalTime;   // time when manual withdrawals are no longer allowed

    // current total valuation of the sale
    // actual amount of ETH committed, taking into account partial purchases
    uint256 totalValuation;

    // amount of value committed at this valuation, cannot rely on owner balance
    // due to fluctations in commitment calculations needed after owner withdraws
    // in other words, the total amount of ETH committed, including total bids
    // that will eventually get partial purchases
    uint256 valueCommitted;

    // the bucket that sits either at or just below current total valuation.
    // determines where the cutoff point is for bids in the sale
    uint256 currentBucket;

    // the fraction of each minimal valuation bidder&#39;s ether refund, &#39;q&#39; is from the paper
    // and is calculated when finalizing the sale
    uint256 q;

    // minimim amount that the sale needs to make to be successfull
    uint256 minimumRaise;

    // percentage of total tokens being sold in this sale
    uint8 percentBeingSold;

    // the bonus amount for early bidders.  This is a percentage of the base token
    // price that gets added on the the base token price used in getCurrentBonus()
    uint256 priceBonusPercent;

    // Indicates that the owner has finalized the sale and withdrawn Ether
    bool isFinalized;

    // Set to true if the sale is canceled
    bool isCanceled;

    // shows the price that the address purchased tokens at
    mapping (address => uint256) pricePurchasedAt;

    // the sums of bids at each valuation.  Used to calculate the current bucket for the valuation pointer
    mapping (uint256 => uint256) valuationSums;

    // the number of active bids at a certain valuation cap
    mapping (uint256 => uint256) numBidsAtValuation;

    // the valuation cap that each address has submitted
    mapping (address => uint256) personalCaps;

    // shows if an address has done a manual withdrawal. manual withdrawals are only allowed once
    mapping (address => bool) hasManuallyWithdrawn;
  }

  // Indicates when an address has withdrawn their supply of tokens
  event LogTokensWithdrawn(address indexed _bidder, uint256 Amount);

  // Indicates when an address has withdrawn their supply of extra wei
  event LogWeiWithdrawn(address indexed _bidder, uint256 Amount);

  // Logs when owner has pulled eth
  event LogOwnerEthWithdrawn(address indexed owner, uint256 amount, string Msg);

  // Indicates when a bidder submits a bid to the crowdsale
  event LogBidAccepted(address indexed bidder, uint256 amount, uint256 personalValuation);

  // Indicates when a bidder manually withdraws their bid from the crowdsale
  event LogBidWithdrawn(address indexed bidder, uint256 amount, uint256 personalValuation);

  // Indicates when a bid is removed by the automated bid removal process
  event LogBidRemoved(address indexed bidder, uint256 personalValuation);

  // Generic Error Msg Event
  event LogErrorMsg(uint256 amount, string Msg);

  // Indicates when the price of the token changes
  event LogTokenPriceChange(uint256 amount, string Msg);

  // Logs the current bucket that the valuation points to, the total valuation of
  // the sale, and the amount of ETH committed, including total bids that will eventually get partial purchases
  event BucketAndValuationAndCommitted(uint256 bucket, uint256 valuation, uint256 committed);

  modifier saleEndedNotFinal(InteractiveCrowdsaleStorage storage self) {
    require(now > self.endTime && (!self.isFinalized));
    _;
  }

  /// @dev Called by a crowdsale contract upon creation.
  /// @param self Stored crowdsale from crowdsale contract
  /// @param _owner Address of crowdsale owner
  /// @param _priceBonusPercent the bonus amount for early bidders
  /// @param _minimumRaise minimim amount that the sale needs to make to be successfull
  /// @param _tokensPerEth the number of tokens to be received per ether sent
  /// @param _startTime timestamp of sale start time
  /// @param _endWithdrawalTime timestamp that indicates that manual withdrawals are no longer allowed
  /// @param _endTime Timestamp of sale end time
  /// @param _percentBeingSold percentage of total tokens being sold in the sale
  /// @param _tokenName name of the token being sold. ex: "Jason Network Token"
  /// @param _tokenSymbol symbol of the token. ex: "JNT"
  /// @param _tokenDecimals number of decimals in the token
  function init(InteractiveCrowdsaleStorage storage self,
                address _owner,
                uint256 _priceBonusPercent,
                uint256 _minimumRaise,
                uint256 _tokensPerEth,
                uint256 _startTime,
                uint256 _endWithdrawalTime,
                uint256 _endTime,
                uint8 _percentBeingSold,
                string _tokenName,
                string _tokenSymbol,
                uint8 _tokenDecimals) internal
  {
    //g base.startTime is start of ICO
    //g base.endTime is end of ICO
    //g times are checked endTime > endWithdrawalTime > startTime
    require(self.owner == 0);
    require(_owner > 0);
    require(_endWithdrawalTime < _endTime);
    require(_endWithdrawalTime > _startTime);
    require(_minimumRaise > 0);
    require(_percentBeingSold > 0);
    require(_percentBeingSold <= 100);
    require(_priceBonusPercent > 0);

    /* Just sets a bunch of parameters for the sale in the struct. */
    self.owner = _owner;
    self.priceBonusPercent = _priceBonusPercent;
    self.minimumRaise = _minimumRaise;
    self.tokensPerEth = _tokensPerEth;
    self.startTime = _startTime;
    self.endWithdrawalTime = _endWithdrawalTime;
    self.endTime = _endTime;
    self.percentBeingSold = _percentBeingSold;
    self.tokenInfo.name = _tokenName;
    self.tokenInfo.symbol = _tokenSymbol;
    self.tokenInfo.decimals = _tokenDecimals;
  }

  /// @dev calculates the number of digits in a given number
  /// @param _number the number for which we&#39;re caluclating digits
  /// @return _digits the number of digits in _number
  /* J: I tested out this and it seemed to work for  */
  function numDigits(uint256 _number) private pure returns (uint256) {
    uint256 _digits = 0;
    while (_number != 0) {
      _number /= 10;
      _digits++;
    }
    return _digits;
  }

  /// @dev calculates the number of tokens purchased based on the amount of wei
  ///      spent and the price of tokens
  /// @param _amount amound of wei that the buyer sent
  /// @param _price price of tokens in the sale, in tokens/ETH
  /// @return uint256 numTokens the number of tokens purchased
  /// @return remainder  any remaining wei leftover from integer division
  function calculateTokenPurchase(uint256 _amount,
                                  uint256 _price)
                                  private
                                  pure
                                  returns (uint256,uint256)
  {
    uint256 remainder = 0; //temp calc holder for division remainder for leftover wei

    uint256 numTokens;
    uint256 weiTokens; //temp calc holder

    // Find the number of tokens as a function in wei
    weiTokens = _amount.mul(_price);

    numTokens = weiTokens / 1000000000000000000;
    remainder = weiTokens % 1000000000000000000;
    remainder = remainder / _price;

    return (numTokens,remainder);
  }

  /// @dev Called when an address wants to submit a bid to the sale
  /// @param self Stored crowdsale from crowdsale contract
  /// @return currentBonus percentage of the bonus that is applied for the purchase
  function getCurrentBonus(InteractiveCrowdsaleStorage storage self) private view returns (uint256){

    uint256 bonusTime;
    uint256 elapsed;
    uint256 currentBonus;

    bonusTime = self.endWithdrawalTime.sub(self.startTime);
    elapsed = now.sub(self.startTime);

    uint256 percentElapsed = (elapsed.mul(100))/bonusTime;

    currentBonus = self.priceBonusPercent.sub(((percentElapsed.mul(self.priceBonusPercent))/100));

    return currentBonus;
  }

  function isAValidPurchase(InteractiveCrowdsaleStorage storage self) private view returns (bool){
    require(msg.sender != self.owner);

    bool nonZeroPurchase = msg.value != 0;
    require(nonZeroPurchase);
    // bidder can&#39;t have already bid   /* Hmmm... why not? Probably just makes logic easier. */ <--- To prevent false signaling
    require((self.personalCaps[msg.sender] == 0) && (self.hasContributed[msg.sender] == 0));
    return true;
  }

  /// @dev Called when an address wants to submit bid to the sale
  /// @param self Stored crowdsale from crowdsale contract
  /// @param _amount amound of wei that the buyer is sending
  /// @param _personalCap the total crowdsale valuation (wei) that the bidder is comfortable with
  /// @param _valuePredict prediction of where the valuation will go in the linked list. saves on searching time
  /// @return true on succesful bid
  function submitBid(InteractiveCrowdsaleStorage storage self,
                      uint256 _amount,
                      uint256 _personalCap,
                      uint256 _valuePredict)
                      public
                      returns (bool)
  {
    require(crowdsaleIsActive(self));
    require(isAValidPurchase(self));
    uint256 _bonusPercent;
    uint256 placeholder;
    // token purchase bonus only applies before the withdrawal lock
    if (isBeforeWithdrawalLock(self)) { /* first half of the sale */
      require(_personalCap > _amount); /* Kind of a silly check, but I guess it would be bad if this was false. */
      _bonusPercent = getCurrentBonus(self);
    } else { /* Thus we&#39;re in the second half of the sale. validPurchase ensures it&#39;s not over.*/
      // The personal valuation submitted must be greater than the current
      // valuation plus the bid if after the withdrawal lock.
      require(_personalCap >= self.totalValuation.add(_amount)); /* Your max cap must be at least the current total valuation, plus your contribution. */
    }

    // personal valuation and minimum should be set to the proper granularity,
    // only three most significant values can be non-zero. reduces the number of possible
    // valuation buckets in the linked list
    placeholder = numDigits(_personalCap);
    if(placeholder > 3) {
      /* Must be divisible by 10x the number of digits over 3.
        ie. 1230 has 4 digits. It&#39;s divisible by (4-3)*10 = 10, so it&#39;s OK.
       */
      require((_personalCap % (10**(placeholder - 3))) == 0);
    }

    // add the bid to the sorted valuations list
    // duplicate personal valuation caps share a spot in the linked list
    if(!self.valuationsList.nodeExists(_personalCap)){
        placeholder = self.valuationsList.getSortedSpot(_valuePredict,_personalCap,NEXT);
        self.valuationsList.insert(placeholder,_personalCap,PREV);
    }

    // add the bid to the address => cap mapping
    self.personalCaps[msg.sender] = _personalCap;

    // add the bid to the sum of bids at this valuation. Needed for calculating correct valuation pointer
    self.valuationSums[_personalCap] = self.valuationSums[_personalCap].add(_amount);

    self.numBidsAtValuation[_personalCap] = self.numBidsAtValuation[_personalCap].add(1);

    // add the bid to bidder&#39;s contribution amount
    self.hasContributed[msg.sender] = self.hasContributed[msg.sender].add(_amount);

    // temp variables for calculation
    uint256 _proposedCommit;
    uint256 _currentBucket;
    bool loop;
    bool exists;

    // we only affect the pointer if we are coming in above it
    if(_personalCap > self.currentBucket){

      // if our valuation is sitting at the current bucket then we are using
      // commitments right at their cap
      if (self.totalValuation == self.currentBucket) {
        // we are going to drop those commitments to see if we are going to be
        // greater than the current bucket without them
        _proposedCommit = (self.valueCommitted.sub(self.valuationSums[self.currentBucket])).add(_amount);

        if(_proposedCommit > self.currentBucket){ loop = true; }
      } else {
        // else we&#39;re sitting in between buckets and have already dropped the
        // previous commitments
        _proposedCommit = self.totalValuation.add(_amount);
        loop = true;
      }

      if(loop){
        // if we&#39;re going to loop we move to the next bucket
        (exists,_currentBucket) = self.valuationsList.getAdjacent(self.currentBucket, NEXT);

        while(_proposedCommit >= _currentBucket){
          // while we are proposed higher than the next bucket we drop commitments
          // and iterate to the next
          _proposedCommit = _proposedCommit.sub(self.valuationSums[_currentBucket]);

          /**Stop checking err here**/
          (exists,_currentBucket) = self.valuationsList.getAdjacent(_currentBucket, NEXT);
        }
        // once we&#39;ve reached a bucket too high we move back to the last bucket and set it
        (exists, _currentBucket) = self.valuationsList.getAdjacent(_currentBucket, PREV);
        self.currentBucket = _currentBucket;
      } else {
        // else we&#39;re staying at the current bucket
        _currentBucket = self.currentBucket;
      }
      // if our proposed commitment is less than or equal to the bucket
      if(_proposedCommit <= _currentBucket){
        // we add the commitments in that bucket
        _proposedCommit = self.valuationSums[_currentBucket].add(_proposedCommit);
        // and our value is capped at that bucket
        self.totalValuation = _currentBucket;
      } else {
        // else our total value is in between buckets and it equals the total commitements
        self.totalValuation = _proposedCommit;
      }

      self.valueCommitted = _proposedCommit;
    } else if(_personalCap == self.totalValuation){
      self.valueCommitted = self.valueCommitted.add(_amount);
    }

    self.pricePurchasedAt[msg.sender] = (self.tokensPerEth.mul(_bonusPercent.add(100)))/100;
    LogBidAccepted(msg.sender, _amount, _personalCap);
    BucketAndValuationAndCommitted(self.currentBucket, self.totalValuation, self.valueCommitted);
    return true;
  }


  /// @dev Called when an address wants to manually withdraw their bid from the
  ///      sale. puts their wei in the LeftoverWei mapping
  /// @param self Stored crowdsale from crowdsale contract
  /// @return true on succesful
  function withdrawBid(InteractiveCrowdsaleStorage storage self) public returns (bool) {
    // The sender has to have already bid on the sale
    require(self.personalCaps[msg.sender] > 0);
    require(crowdsaleIsActive(self));
    uint256 refundWei;
    // cannot withdraw after compulsory withdraw period is over unless the bid&#39;s
    // valuation is below the cutoff
    if (isAfterWithdrawalLock(self)) {
      require(self.personalCaps[msg.sender] < self.totalValuation);

      // full refund because their bid no longer affects the total sale valuation
      refundWei = self.hasContributed[msg.sender];
    } else {
      require(!self.hasManuallyWithdrawn[msg.sender]);  // manual withdrawals are only allowed once
      /***********************************************************************
      The following lines were commented out due to stack depth, but they represent
      the variables and calculations from the paper. The actual code is the same
      thing spelled out using current variables.  See section 4 of the white paper for formula used
      ************************************************************************/
      //uint256 t = self.endWithdrawalTime - self.startTime;
      //uint256 s = now - self.startTime;
      //uint256 pa = self.pricePurchasedAt[msg.sender];
      //uint256 pu = self.tokensPerEth;
      //uint256 multiplierPercent =  (100*(t - s))/t;
      //self.pricePurchasedAt = pa-((pa-pu)/3)
      uint256 timeLeft;

      timeLeft = self.endWithdrawalTime.sub(now);
      uint256 multiplierPercent = (timeLeft.mul(100)) / (self.endWithdrawalTime.sub(self.startTime));

      refundWei = (multiplierPercent.mul(self.hasContributed[msg.sender])) / 100;
      self.valuationSums[self.personalCaps[msg.sender]] = self.valuationSums[self.personalCaps[msg.sender]].sub(refundWei);

      self.numBidsAtValuation[self.personalCaps[msg.sender]] = self.numBidsAtValuation[self.personalCaps[msg.sender]].sub(1);

      uint256 bonusAmount;
      bonusAmount = self.pricePurchasedAt[msg.sender].sub(self.tokensPerEth);
      self.pricePurchasedAt[msg.sender] = self.pricePurchasedAt[msg.sender].sub(bonusAmount / 3);

      self.hasManuallyWithdrawn[msg.sender] = true;

    }

    // Put the sender&#39;s contributed wei into the leftoverWei mapping for later withdrawal
    self.leftoverWei[msg.sender] = self.leftoverWei[msg.sender].add(refundWei);

    // subtract the bidder&#39;s refund from its total contribution
    self.hasContributed[msg.sender] = self.hasContributed[msg.sender].sub(refundWei);

    uint256 _proposedCommit;
    uint256 _proposedValue;
    uint256 _currentBucket;
    bool loop;
    bool exists;

    // bidder&#39;s withdrawal only affects the pointer if the personal cap is at or
    // above the current valuation
    if(self.personalCaps[msg.sender] >= self.totalValuation){

      // first we remove the refundWei from the committed value
      _proposedCommit = self.valueCommitted.sub(refundWei);

      // if we&#39;ve dropped below the current bucket
      if(_proposedCommit <= self.currentBucket){
        // and current valuation is above the bucket
        if(self.totalValuation > self.currentBucket){
          _proposedCommit = self.valuationSums[self.currentBucket].add(_proposedCommit);
        }

        if(_proposedCommit >= self.currentBucket){
          _proposedValue = self.currentBucket;
        } else {
          // if we are still below the current bucket then we need to iterate
          loop = true;
        }
      } else {
        if(self.totalValuation == self.currentBucket){
          _proposedValue = self.totalValuation;
        } else {
          _proposedValue = _proposedCommit;
        }
      }

      if(loop){
        // if we&#39;re going to loop we move to the previous bucket
        (exists,_currentBucket) = self.valuationsList.getAdjacent(self.currentBucket, PREV);
        while(_proposedCommit <= _currentBucket){
          // while we are proposed lower than the previous bucket we add commitments
          _proposedCommit = self.valuationSums[_currentBucket].add(_proposedCommit);
          // and iterate to the previous
          if(_proposedCommit >= _currentBucket){
            _proposedValue = _currentBucket;
          } else {
            (exists,_currentBucket) = self.valuationsList.getAdjacent(_currentBucket, PREV);
          }
        }

        if(_proposedValue == 0) { _proposedValue = _proposedCommit; }

        self.currentBucket = _currentBucket;
      }

      self.totalValuation = _proposedValue;
      self.valueCommitted = _proposedCommit;
    }

    LogBidWithdrawn(msg.sender, refundWei, self.personalCaps[msg.sender]);
    BucketAndValuationAndCommitted(self.currentBucket, self.totalValuation, self.valueCommitted);
    return true;
  }

  /// @dev This should be called once the sale is over to commit all bids into
  ///      the owner&#39;s bucket.
  /// @param self stored crowdsale from crowdsale contract

  //g !!! Shouldn&#39;t this just be callable by the owner !!!
  function finalizeSale(InteractiveCrowdsaleStorage storage self) public
           saleEndedNotFinal(self)
           returns (bool)
  {
    setCanceled(self);

    self.isFinalized = true;
    require(launchToken(self));
    //g may need to be computed due to EVM rounding errors
    uint256 computedValue;

    //g if it has not been canceld then calculate the ownerBalance
    if(!self.isCanceled){
      if(self.totalValuation == self.currentBucket){
        // calculate the fraction of each minimal valuation bidders ether and tokens to refund
        self.q = ((((self.valueCommitted.sub(self.totalValuation)).mul(100)))/self.valuationSums[self.totalValuation]).add(uint256(1));
        computedValue = self.valueCommitted.sub(self.valuationSums[self.totalValuation]);
        computedValue = computedValue.add(((uint256(100).sub(self.q)).mul(self.valuationSums[self.totalValuation]))/100);
      } else {
        // no computation necessary
        computedValue = self.totalValuation;
      }
      self.ownerBalance = computedValue;  // sets ETH raised in the sale to be ready for withdrawal
    }
  }

  /// @dev Mints the token being sold by taking the percentage of the token supply
  ///      being sold in this sale along with the valuation, derives all necessary
  ///      values and then transfers owner tokens to the owner.
  /// @param self Stored crowdsale from crowdsale contract
  function launchToken(InteractiveCrowdsaleStorage storage self) private returns (bool) {
    // total valuation of all the tokens not including the bonus
    uint256 _fullValue = (self.totalValuation.mul(100))/uint256(self.percentBeingSold);
    // total valuation of bonus tokens
    uint256 _bonusValue = ((self.totalValuation.mul(self.priceBonusPercent.add(100)))/100).sub(self.totalValuation);
    // total supply of all tokens not including the bonus
    uint256 _supply = (_fullValue.mul(self.tokensPerEth))/1000000000000000000;
    // total number of bonus tokens
    uint256 _bonusTokens = (_bonusValue.mul(self.tokensPerEth))/1000000000000000000;
    // tokens allocated to the owner of the sale
    uint256 _ownerTokens = _supply.sub((_supply.mul(uint256(self.percentBeingSold)))/100);
    // total supply of tokens including the bonus tokens
    uint256 _totalSupply = _supply.add(_bonusTokens);

    // deploy new token contract with total number of tokens
    self.token = new InteractiveCrowdsaleToken(address(this),
                                               self.tokenInfo.name,
                                               self.tokenInfo.symbol,
                                               self.tokenInfo.decimals,
                                               _totalSupply);


    if(!self.isCanceled){
      //g only the owner tokens go to the owner
      self.token.transfer(self.owner, _ownerTokens);
    } else {
      //g if the sale got canceled, then all the tokens go to the owner and bonus tokens are burned
      self.token.transfer(self.owner, _supply);
      self.token.burnToken(_bonusTokens);
    }
    // the owner of the crowdsale becomes the new owner of the token contract
    self.token.changeOwner(self.owner);
    self.startingTokenBalance = _supply.sub(_ownerTokens);

    return true;
  }

  /// @dev returns a boolean indicating if the sale is canceled.
  ///      This can either be if the minimum raise hasn&#39;t been met
  ///      or if it is 30 days after the sale and the owner hasn&#39;t finalized the sale.
  /* That&#39;s a weird condition */
  /// @return bool canceled indicating if the sale is canceled or not
  function setCanceled(InteractiveCrowdsaleStorage storage self) private returns(bool){
    bool canceled = (self.totalValuation < self.minimumRaise) ||
                    ((now > (self.endTime + 30 days)) && !self.isFinalized);

    if(canceled) {self.isCanceled = true;}

    return self.isCanceled;
  }

  /// @dev If the address&#39; personal cap is below the pointer, refund them all their ETH.
  ///      if it is above the pointer, calculate tokens purchased and refund leftoever ETH
  /// @param self Stored crowdsale from crowdsale contract
  /// @return bool success if the contract runs successfully
  /* What should not happen here? */
  function retrieveFinalResult(InteractiveCrowdsaleStorage storage self) public returns (bool) {
    require(now > self.endTime); /* This ensure that the endTime is past */
    require(self.personalCaps[msg.sender] > 0); /* This requires that  */

    uint256 numTokens; /* setup some pointers */
    uint256 remainder;

    if(!self.isFinalized){
      require(setCanceled(self));
    }

    if (self.isCanceled) {
      // if the sale was canceled, everyone gets a full refund
      self.leftoverWei[msg.sender] = self.leftoverWei[msg.sender].add(self.hasContributed[msg.sender]);
      self.hasContributed[msg.sender] = 0;
      LogErrorMsg(self.totalValuation, "Sale is canceled, all bids have been refunded!");
      return true;
    }

    if (self.personalCaps[msg.sender] < self.totalValuation) {

      // full refund if personal cap is less than total valuation
      self.leftoverWei[msg.sender] += self.hasContributed[msg.sender];

      // set hasContributed to 0 to prevent participant from calling this over and over
      self.hasContributed[msg.sender] = 0;

      return withdrawLeftoverWei(self);

    } else if (self.personalCaps[msg.sender] == self.totalValuation) {

      // calculate the portion that this address has to take out of their bid
      uint256 refundAmount = (self.q.mul(self.hasContributed[msg.sender]))/100;
      uint256 dust = (self.q.mul(self.hasContributed[msg.sender]))%100;

      // refund that amount of wei to the address
      self.leftoverWei[msg.sender] = self.leftoverWei[msg.sender].add(refundAmount);

      // subtract that amount the address&#39; contribution
      self.hasContributed[msg.sender] = self.hasContributed[msg.sender].sub(refundAmount);
      if(dust > 0) {
        self.leftoverWei[msg.sender] = self.leftoverWei[msg.sender].add(dust);
        self.hasContributed[msg.sender] = self.hasContributed[msg.sender].sub(dust);
      }
    }

    // calculate the number of tokens that the bidder purchased
    (numTokens, remainder) = calculateTokenPurchase(self.hasContributed[msg.sender],
                                                    self.pricePurchasedAt[msg.sender]);

    self.withdrawTokensMap[msg.sender] = self.withdrawTokensMap[msg.sender].add(numTokens);
    self.valueCommitted = self.valueCommitted.sub(remainder);
    self.hasContributed[msg.sender] = self.hasContributed[msg.sender].sub(remainder);
    self.leftoverWei[msg.sender] = self.leftoverWei[msg.sender].add(remainder);

    // burn any extra bonus tokens
    uint256 _fullBonus;
    uint256 _fullBonusPrice = (self.tokensPerEth.mul(self.priceBonusPercent.add(100)))/100;
    (_fullBonus, remainder) = calculateTokenPurchase(self.hasContributed[msg.sender], _fullBonusPrice);
    uint256 _leftoverBonus = _fullBonus.sub(numTokens);

    self.token.burnToken(_leftoverBonus);

    self.hasContributed[msg.sender] = 0;

    // send tokens and leftoverWei to the address calling the function
    withdrawTokens(self);

    withdrawLeftoverWei(self);

  }

  /// @dev Function called by purchasers to pull tokens
  /// @param self Stored crowdsale from crowdsale contract
  /// @return true if tokens were withdrawn
  function withdrawTokens(InteractiveCrowdsaleStorage storage self) public returns (bool) {
    bool ok;

    if (self.withdrawTokensMap[msg.sender] == 0) {
      LogErrorMsg(0, "Sender has no tokens to withdraw!");
      return false;
    }

    if (msg.sender == self.owner) {
      if(!self.isFinalized){
        LogErrorMsg(0, "Owner cannot withdraw extra tokens until after the sale!");
        return false;
      }
    }

    uint256 total = self.withdrawTokensMap[msg.sender];
    self.withdrawTokensMap[msg.sender] = 0;
    ok = self.token.transfer(msg.sender, total);
    require(ok);
    LogTokensWithdrawn(msg.sender, total);
    return true;
  }

  /// @dev Function called by purchasers to pull leftover wei from their purchases
  /// @param self Stored crowdsale from crowdsale contract
  /// @return true if wei was withdrawn
  function withdrawLeftoverWei(InteractiveCrowdsaleStorage storage self) public returns (bool) {
    if (self.leftoverWei[msg.sender] == 0) {
      LogErrorMsg(0, "Sender has no extra wei to withdraw!");
      return false;
    }

    uint256 total = self.leftoverWei[msg.sender];
    self.leftoverWei[msg.sender] = 0;
    msg.sender.transfer(total);
    LogWeiWithdrawn(msg.sender, total);
    return true;
  }

  /// @dev send ether from the completed crowdsale to the owners wallet address
  /// @param self Stored crowdsale from crowdsale contract
  /// @return true if owner withdrew eth
  function withdrawOwnerEth(InteractiveCrowdsaleStorage storage self) public returns (bool) {
    require(msg.sender == self.owner);
    require(self.ownerBalance > 0);
    require(self.isFinalized);

    uint256 amount = self.ownerBalance;
    self.ownerBalance = 0;
    self.owner.transfer(amount);
    LogOwnerEthWithdrawn(msg.sender,amount,"Crowdsale owner has withdrawn all funds!");

    return true;
  }

  function crowdsaleIsActive(InteractiveCrowdsaleStorage storage self) public view returns (bool) {
    return (now >= self.startTime && now <= self.endTime);
  }

  function isBeforeWithdrawalLock(InteractiveCrowdsaleStorage storage self) public view returns (bool) {
    return now < self.endWithdrawalTime;
  }

  function isAfterWithdrawalLock(InteractiveCrowdsaleStorage storage self) public view returns (bool) {
    return now >= self.endWithdrawalTime;
  }

  function getPersonalCap(InteractiveCrowdsaleStorage storage self, address _bidder) public view returns (uint256) {
    return self.personalCaps[_bidder];
  }

}

pragma solidity 0.4.21;

/**
 * @title LinkedListLib
 * @author Darryl Morris (o0ragman0o) and Modular.network
 *
 * This utility library was forked from https://github.com/o0ragman0o/LibCLL
 * into the Modular-Network ethereum-libraries repo at https://github.com/Modular-Network/ethereum-libraries
 * It has been updated to add additional functionality and be more compatible with solidity 0.4.18
 * coding patterns.
 *
 * version 1.1.1
 * Copyright (c) 2017 Modular Inc.
 * The MIT License (MIT)
 * https://github.com/Modular-network/ethereum-libraries/blob/master/LICENSE
 *
 * The LinkedListLib provides functionality for implementing data indexing using
 * a circlular linked list
 *
 * Modular provides smart contract services and security reviews for contract
 * deployments in addition to working on open source projects in the Ethereum
 * community. Our purpose is to test, document, and deploy reusable code onto the
 * blockchain and improve both security and usability. We also educate non-profits,
 * schools, and other community members about the application of blockchain
 * technology. For further information: modular.network
 *
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/


library LinkedListLib {

    uint256 constant NULL = 0;
    uint256 constant HEAD = 0;
    bool constant PREV = false;
    bool constant NEXT = true;

    struct LinkedList{
        mapping (uint256 => mapping (bool => uint256)) list;
    }

    /// @dev returns true if the list exists
    /// @param self stored linked list from contract
    function listExists(LinkedList storage self)
        public
        view returns (bool)
    {
        // if the head nodes previous or next pointers both point to itself, then there are no items in the list
        if (self.list[HEAD][PREV] != HEAD || self.list[HEAD][NEXT] != HEAD) {
            return true;
        } else {
            return false;
        }
    }

    /// @dev returns true if the node exists
    /// @param self stored linked list from contract
    /// @param _node a node to search for
    function nodeExists(LinkedList storage self, uint256 _node)
        public
        view returns (bool)
    {
        if (self.list[_node][PREV] == HEAD && self.list[_node][NEXT] == HEAD) {
            if (self.list[HEAD][NEXT] == _node) {
                return true;
            } else {
                return false;
            }
        } else {
            return true;
        }
    }

    /// @dev Returns the number of elements in the list
    /// @param self stored linked list from contract
    function sizeOf(LinkedList storage self) public view returns (uint256 numElements) {
        bool exists;
        uint256 i;
        (exists,i) = getAdjacent(self, HEAD, NEXT);
        while (i != HEAD) {
            (exists,i) = getAdjacent(self, i, NEXT);
            numElements++;
        }
        return;
    }

    /// @dev Returns the links of a node as a tuple
    /// @param self stored linked list from contract
    /// @param _node id of the node to get
    function getNode(LinkedList storage self, uint256 _node)
        public view returns (bool,uint256,uint256)
    {
        if (!nodeExists(self,_node)) {
            return (false,0,0);
        } else {
            return (true,self.list[_node][PREV], self.list[_node][NEXT]);
        }
    }

    /// @dev Returns the link of a node `_node` in direction `_direction`.
    /// @param self stored linked list from contract
    /// @param _node id of the node to step from
    /// @param _direction direction to step in
    function getAdjacent(LinkedList storage self, uint256 _node, bool _direction)
        public view returns (bool,uint256)
    {
        if (!nodeExists(self,_node)) {
            return (false,0);
        } else {
            return (true,self.list[_node][_direction]);
        }
    }

    /// @dev Can be used before `insert` to build an ordered list
    /// @param self stored linked list from contract
    /// @param _node an existing node to search from, e.g. HEAD.
    /// @param _value value to seek
    /// @param _direction direction to seek in
    //  @return next first node beyond &#39;_node&#39; in direction `_direction`
    function getSortedSpot(LinkedList storage self, uint256 _node, uint256 _value, bool _direction)
        public view returns (uint256)
    {
        if (sizeOf(self) == 0) { return 0; }
        require((_node == 0) || nodeExists(self,_node));
        bool exists;
        uint256 next;
        (exists,next) = getAdjacent(self, _node, _direction);
        while  ((next != 0) && (_value != next) && ((_value < next) != _direction)) next = self.list[next][_direction];
        return next;
    }

    /// @dev Creates a bidirectional link between two nodes on direction `_direction`
    /// @param self stored linked list from contract
    /// @param _node first node for linking
    /// @param _link  node to link to in the _direction
    function createLink(LinkedList storage self, uint256 _node, uint256 _link, bool _direction) private  {
        self.list[_link][!_direction] = _node;
        self.list[_node][_direction] = _link;
    }

    /// @dev Insert node `_new` beside existing node `_node` in direction `_direction`.
    /// @param self stored linked list from contract
    /// @param _node existing node
    /// @param _new  new node to insert
    /// @param _direction direction to insert node in
    function insert(LinkedList storage self, uint256 _node, uint256 _new, bool _direction) internal returns (bool) {
        if(!nodeExists(self,_new) && nodeExists(self,_node)) {
            uint256 c = self.list[_node][_direction];
            createLink(self, _node, _new, _direction);
            createLink(self, _new, c, _direction);
            return true;
        } else {
            return false;
        }
    }

    /// @dev removes an entry from the linked list
    /// @param self stored linked list from contract
    /// @param _node node to remove from the list
    function remove(LinkedList storage self, uint256 _node) internal returns (uint256) {
        if ((_node == NULL) || (!nodeExists(self,_node))) { return 0; }
        createLink(self, self.list[_node][PREV], self.list[_node][NEXT], NEXT);
        delete self.list[_node][PREV];
        delete self.list[_node][NEXT];
        return _node;
    }

    /// @dev pushes an enrty to the head of the linked list
    /// @param self stored linked list from contract
    /// @param _node new entry to push to the head
    /// @param _direction push to the head (NEXT) or tail (PREV)
    function push(LinkedList storage self, uint256 _node, bool _direction) internal  {
        insert(self, HEAD, _node, _direction);
    }

    /// @dev pops the first entry from the linked list
    /// @param self stored linked list from contract
    /// @param _direction pop from the head (NEXT) or the tail (PREV)
    function pop(LinkedList storage self, bool _direction) internal returns (uint256) {
        bool exists;
        uint256 adj;

        (exists,adj) = getAdjacent(self, HEAD, _direction);

        return remove(self, adj);
    }
}

library BasicMathLib {
  /// @dev Multiplies two numbers and checks for overflow before returning.
  /// Does not throw.
  /// @param a First number
  /// @param b Second number
  /// @return err False normally, or true if there is overflow
  /// @return res The product of a and b, or 0 if there is overflow
  function times(uint256 a, uint256 b) public pure returns (bool err,uint256 res) {
    assembly{
      res := mul(a,b)
      switch or(iszero(b), eq(div(res,b), a))
      case 0 {
        err := 1
        res := 0
      }
    }
  }

  /// @dev Divides two numbers but checks for 0 in the divisor first.
  /// Does not throw.
  /// @param a First number
  /// @param b Second number
  /// @return err False normally, or true if `b` is 0
  /// @return res The quotient of a and b, or 0 if `b` is 0
  function dividedBy(uint256 a, uint256 b) public pure returns (bool err,uint256 i) {
    uint256 res;
    assembly{
      switch iszero(b)
      case 0 {
        res := div(a,b)
        let loc := mload(0x40)
        mstore(add(loc,0x20),res)
        i := mload(add(loc,0x20))
      }
      default {
        err := 1
        i := 0
      }
    }
  }

  /// @dev Adds two numbers and checks for overflow before returning.
  /// Does not throw.
  /// @param a First number
  /// @param b Second number
  /// @return err False normally, or true if there is overflow
  /// @return res The sum of a and b, or 0 if there is overflow
  function plus(uint256 a, uint256 b) public pure returns (bool err, uint256 res) {
    assembly{
      res := add(a,b)
      switch and(eq(sub(res,b), a), or(gt(res,b),eq(res,b)))
      case 0 {
        err := 1
        res := 0
      }
    }
  }

  /// @dev Subtracts two numbers and checks for underflow before returning.
  /// Does not throw but rather logs an Err event if there is underflow.
  /// @param a First number
  /// @param b Second number
  /// @return err False normally, or true if there is underflow
  /// @return res The difference between a and b, or 0 if there is underflow
  function minus(uint256 a, uint256 b) public pure returns (bool err,uint256 res) {
    assembly{
      res := sub(a,b)
      switch eq(and(eq(add(res,b), a), or(lt(res,a), eq(res,a))), 1)
      case 0 {
        err := 1
        res := 0
      }
    }
  }
}

library TokenLib {
  using BasicMathLib for uint256;

  struct TokenStorage {
    bool initialized;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    string name;
    string symbol;
    uint256 totalSupply;
    uint256 initialSupply;
    address owner;
    uint8 decimals;
    bool stillMinting;
  }

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event OwnerChange(address from, address to);
  event Burn(address indexed burner, uint256 value);
  event MintingClosed(bool mintingClosed);

  /// @dev Called by the Standard Token upon creation.
  /// @param self Stored token from token contract
  /// @param _name Name of the new token
  /// @param _symbol Symbol of the new token
  /// @param _decimals Decimal places for the token represented
  /// @param _initial_supply The initial token supply
  /// @param _allowMinting True if additional tokens can be created, false otherwise
  function init(TokenStorage storage self,
                address _owner,
                string _name,
                string _symbol,
                uint8 _decimals,
                uint256 _initial_supply,
                bool _allowMinting)
                public
  {
    require(!self.initialized);
    self.initialized = true;
    self.name = _name;
    self.symbol = _symbol;
    self.totalSupply = _initial_supply;
    self.initialSupply = _initial_supply;
    self.decimals = _decimals;
    self.owner = _owner;
    self.stillMinting = _allowMinting;
    self.balances[_owner] = _initial_supply;
  }

  /// @dev Transfer tokens from caller&#39;s account to another account.
  /// @param self Stored token from token contract
  /// @param _to Address to send tokens
  /// @param _value Number of tokens to send
  /// @return True if completed
  function transfer(TokenStorage storage self, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    bool err;
    uint256 balance;

    (err,balance) = self.balances[msg.sender].minus(_value);
    require(!err);
    self.balances[msg.sender] = balance;
    //It&#39;s not possible to overflow token supply
    self.balances[_to] = self.balances[_to] + _value;
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /// @dev Authorized caller transfers tokens from one account to another
  /// @param self Stored token from token contract
  /// @param _from Address to send tokens from
  /// @param _to Address to send tokens to
  /// @param _value Number of tokens to send
  /// @return True if completed
  function transferFrom(TokenStorage storage self,
                        address _from,
                        address _to,
                        uint256 _value)
                        public
                        returns (bool)
  {
    uint256 _allowance = self.allowed[_from][msg.sender];
    bool err;
    uint256 balanceOwner;
    uint256 balanceSpender;

    (err,balanceOwner) = self.balances[_from].minus(_value);
    require(!err);

    (err,balanceSpender) = _allowance.minus(_value);
    require(!err);

    self.balances[_from] = balanceOwner;
    self.allowed[_from][msg.sender] = balanceSpender;
    self.balances[_to] = self.balances[_to] + _value;

    emit Transfer(_from, _to, _value);
    return true;
  }

  /// @dev Retrieve token balance for an account
  /// @param self Stored token from token contract
  /// @param _owner Address to retrieve balance of
  /// @return balance The number of tokens in the subject account
  function balanceOf(TokenStorage storage self, address _owner) public view returns (uint256 balance) {
    return self.balances[_owner];
  }

  /// @dev Authorize an account to send tokens on caller&#39;s behalf
  /// @param self Stored token from token contract
  /// @param _spender Address to authorize
  /// @param _value Number of tokens authorized account may send
  /// @return True if completed
  function approve(TokenStorage storage self, address _spender, uint256 _value) public returns (bool) {
    // must set to zero before changing approval amount in accordance with spec
    require((_value == 0) || (self.allowed[msg.sender][_spender] == 0));

    self.allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /// @dev Remaining tokens third party spender has to send
  /// @param self Stored token from token contract
  /// @param _owner Address of token holder
  /// @param _spender Address of authorized spender
  /// @return remaining Number of tokens spender has left in owner&#39;s account
  function allowance(TokenStorage storage self, address _owner, address _spender)
                     public
                     view
                     returns (uint256 remaining) {
    return self.allowed[_owner][_spender];
  }

  /// @dev Authorize third party transfer by increasing/decreasing allowed rather than setting it
  /// @param self Stored token from token contract
  /// @param _spender Address to authorize
  /// @param _valueChange Increase or decrease in number of tokens authorized account may send
  /// @param _increase True if increasing allowance, false if decreasing allowance
  /// @return True if completed
  function approveChange (TokenStorage storage self, address _spender, uint256 _valueChange, bool _increase)
                          public returns (bool)
  {
    uint256 _newAllowed;
    bool err;

    if(_increase) {
      (err, _newAllowed) = self.allowed[msg.sender][_spender].plus(_valueChange);
      require(!err);

      self.allowed[msg.sender][_spender] = _newAllowed;
    } else {
      if (_valueChange > self.allowed[msg.sender][_spender]) {
        self.allowed[msg.sender][_spender] = 0;
      } else {
        _newAllowed = self.allowed[msg.sender][_spender] - _valueChange;
        self.allowed[msg.sender][_spender] = _newAllowed;
      }
    }

    emit Approval(msg.sender, _spender, _newAllowed);
    return true;
  }

  /// @dev Change owning address of the token contract, specifically for minting
  /// @param self Stored token from token contract
  /// @param _newOwner Address for the new owner
  /// @return True if completed
  function changeOwner(TokenStorage storage self, address _newOwner) public returns (bool) {
    require((self.owner == msg.sender) && (_newOwner > 0));

    self.owner = _newOwner;
    emit OwnerChange(msg.sender, _newOwner);
    return true;
  }

  /// @dev Mints additional tokens, new tokens go to owner
  /// @param self Stored token from token contract
  /// @param _amount Number of tokens to mint
  /// @return True if completed
  function mintToken(TokenStorage storage self, uint256 _amount) public returns (bool) {
    require((self.owner == msg.sender) && self.stillMinting);
    uint256 _newAmount;
    bool err;

    (err, _newAmount) = self.totalSupply.plus(_amount);
    require(!err);

    self.totalSupply =  _newAmount;
    self.balances[self.owner] = self.balances[self.owner] + _amount;
    emit Transfer(0x0, self.owner, _amount);
    return true;
  }

  /// @dev Permanent stops minting
  /// @param self Stored token from token contract
  /// @return True if completed
  function closeMint(TokenStorage storage self) public returns (bool) {
    require(self.owner == msg.sender);

    self.stillMinting = false;
    emit MintingClosed(true);
    return true;
  }

  /// @dev Permanently burn tokens
  /// @param self Stored token from token contract
  /// @param _amount Amount of tokens to burn
  /// @return True if completed
  function burnToken(TokenStorage storage self, uint256 _amount) public returns (bool) {
      uint256 _newBalance;
      bool err;

      (err, _newBalance) = self.balances[msg.sender].minus(_amount);
      require(!err);

      self.balances[msg.sender] = _newBalance;
      self.totalSupply = self.totalSupply - _amount;
      emit Burn(msg.sender, _amount);
      emit Transfer(msg.sender, 0x0, _amount);
      return true;
  }
}

contract InteractiveCrowdsaleToken {
  using TokenLib for TokenLib.TokenStorage;

  TokenLib.TokenStorage public token;

  /* FLAG: the owner can mint new tokens. This is an issue if not properly configured. */
  function InteractiveCrowdsaleToken(address owner,
                                     string name,
                                     string symbol,
                                     uint8 decimals,
                                     uint256 initialSupply) public
  {
    token.init(owner, name, symbol, decimals, initialSupply, false);
  }

  function name() public view returns (string) {
    return token.name;
  }

  function symbol() public view returns (string) {
    return token.symbol;
  }

  function decimals() public view returns (uint8) {
    return token.decimals;
  }

  function totalSupply() public view returns (uint256) {
    return token.totalSupply;
  }

  function initialSupply() public view returns (uint256) {
    return token.initialSupply;
  }

  function balanceOf(address who) public view returns (uint256) {
    return token.balanceOf(who);
  }

  function allowance(address owner, address spender) public view returns (uint256) {
    return token.allowance(owner, spender);
  }

  function transfer(address to, uint value) public returns (bool ok) {
    return token.transfer(to, value);
  }

  function transferFrom(address from, address to, uint value) public returns (bool ok) {
    return token.transferFrom(from, to, value);
  }

  function approve(address spender, uint value) public returns (bool ok) {
    return token.approve(spender, value);
  }

  function approveChange(address spender, uint256 valueChange, bool increase)
                         public returns (bool ok)
  {
    return token.approveChange(spender, valueChange, increase);
  }

  function changeOwner(address newOwner) public returns (bool ok) {
    return token.changeOwner(newOwner);
  }

  function mintToken(uint256 amount) public returns (bool ok) {
    return token.mintToken(amount);
  }

  function closeMint() public returns (bool ok) {
    return token.closeMint();
  }

  function burnToken(uint256 amount) public returns (bool ok) {
    return token.burnToken(amount);
  }
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}
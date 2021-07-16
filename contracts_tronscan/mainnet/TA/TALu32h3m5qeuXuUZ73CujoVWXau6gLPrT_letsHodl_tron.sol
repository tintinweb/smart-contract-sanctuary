//SourceUnit: letsHodl_tron.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.4;

contract letsHodl_tron {

    using SafeMath for uint256;

    /*=================================
    =            MODIFIERS            =
    =================================*/
    // only people with tokens
    modifier onlyTokenHolder () {
        require(myTokens() > 0,'Member does not have Tokens');
        _;
    }

    // only Buckets with tokens
    modifier bucketHasTokens (uint256 _bucketId) {
        require(balanceOfBucket(_bucketId) > 0,'Bucket does not have Tokens');
        _;
    }

    // only Members with profits
    modifier onlyMembersWithDividends () {
        require(myDividends() > 0,'Member does not have dividends');
        _;
    }

    // only Buckets with profits
    modifier onlyBucketsWithDividends (uint256 _bucketId) {
        require(dividendsOfBucket(_bucketId) > 0,'Buckets does not have dividends');
        _;
    }

    // only deposits not greater than a percentage of total contract balance (anti-whale mechanism)
    modifier onlyQualifyingDeposits () {
      require( (msg.value <= ((lastBalance_ * maxDepositPercentage_) / 100) ||
                (now < exemptMaxDepositTimer_) ), 'Deposit amount is too large');
      _;
    }

    // Mutex mechanism to time-limit execution of critical functions.
    // This is a complementary anti-whale time-limited feature.
    modifier checkMutexLocked () {
      require( mutexLockTimer_[msg.sender] < now, 'Mutex lock is active' );
      _;
    }

    /*==============================
    =            EVENTS            =
    ==============================*/
    event onBucketPayout(
        uint256 indexed bucketId,
        uint256 tokensBurned,
        uint256 tronShared
    );

    event onMemberTokenPurchase(
        address indexed depositAddress,
        uint256 incomingTrx,
        uint256 tokensMinted
    );

    event onBucketTokenPurchase(
        address indexed fromAddress,
        uint256 indexed bucketId,
        uint256 incomingTrx,
        uint256 tokensMinted
    );

    event onTokenSell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 trxEarned
    );

    event onReinvestment(
        address indexed customerAddress,
        uint256 trxReinvested,
        uint256 tokensMinted
    );

    event onBucketReinvestment(
        uint256 indexed bucketId,
        uint256 trxReinvested,
        uint256 tokensMinted
    );

    event onWithdraw(
        address indexed customerAddress,
        uint256 trxWithdrawn
    );

    // ERC20
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );

    event TransferBucket(
        uint256 indexed fromBucket,
        uint256 indexed toBucket,
        uint256 tokens
    );

    struct Bucket {
      bool active;
      uint256 tokenBalance_;
      int256 payoutsTo_;
    }

    address owner;
    address private oracleAddress_;
    address private addressDev1_;
    address private addressDev2_;

    string  public name = "HODL Trading Contract";
    string  public symbol = "HODL";
    // Token has 6 decimals, so 1 Token = 1e6
    uint8 constant public decimals = 6;

    // TRX has only 6 decimals
    uint8 constant internal tronDecimals_ = 6;
    // Fee on Token buy or sell is set to 5%, so dividentFee will be set to
    // rate of 100/dividendFeeRate_ = 5
    uint8 constant internal dividendFeeRate_ = 20;
    uint8 internal bucketCount_ = 0;
    uint256 internal usdDecimals_ = 2;
    uint256 internal usdTrxPrice_ = 1 * 10**usdDecimals_;
    uint256 internal usdPriceNonce_ = 0;
    uint256 constant internal tokenPriceInitial_ = 0.0001 trx;
    uint256 constant internal tokenPriceIncremental_ = 0.00001 trx;
    uint256 constant internal magnitude = 2**64;

    // Developer fee
    //    Fee percentage is devFee_/devFeeDivider_. With contract default value of
    //    devFee = 225 and devFeeDivider_ = 100000, the actual percentage is 0.225% per developer.
    //    This results in a total fee of 0.45% split by two developers.
    //    devFee_ can be updated by contract owner, with a hardcoded max value of 250.
    //    Then maximum hard coded dev fee can only be 0.5% split by two developers.
    uint8 internal devFee_ = 225;
    uint8 constant internal devFeeMaxCap_ = 250;
    uint32 constant internal devFeeDivider_ = 100000;

    // Anti-whale mechanism
    uint8 internal maxDepositPercentage_ = 100;
    uint256 internal exemptMaxDepositTimer_;
    uint256 internal lastBalance_ = 0;
    // mutex lock in minutes
    uint256 internal mutexWaitMinutes_ = 15;

    uint256 internal fixedBucketAmount_ = 0;
    uint256 internal tokenSupply_ = 0;
    uint256 internal profitPerShare_;
    uint256[5] internal bucketUSDThresholds_;
    uint16[5] internal usdThresholds_ = [250, 50, 100, 500, 1000];

    mapping(uint => Bucket) internal buckets;
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => int256) internal payoutsTo_;
    mapping(address => uint256) internal mutexLockTimer_;

    constructor() public {

      owner = msg.sender;
      buckets[bucketCount_] = Bucket(true, 0, 0);
      bucketCount_+=1;

      // Start Anti-Whale exemption timer.
      exemptMaxDepositTimer_ = now + 1 days;

      // Set bucket USD Thresholds
      bucketUSDThresholds_[0] = SafeMath.mul(usdThresholds_[0], 10**usdDecimals_);
      bucketUSDThresholds_[1] = SafeMath.mul(usdThresholds_[1], 10**usdDecimals_);
      bucketUSDThresholds_[2] = SafeMath.mul(usdThresholds_[2], 10**usdDecimals_);
      bucketUSDThresholds_[3] = SafeMath.mul(usdThresholds_[3], 10**usdDecimals_);
      bucketUSDThresholds_[4] = SafeMath.mul(usdThresholds_[4], 10**usdDecimals_);
    }

    /**
     * Converts all incoming TRX to tokens for the caller.
     */
    function memberDepositTrx(uint256 _usdTrxPrice, uint256 _usdTrxDecimals, uint256 _usdPriceNonce, bytes memory _signature)
      onlyQualifyingDeposits()
      checkMutexLocked()
      public
      payable
    {
      // No deposits allowed until Fixed Bucket has received investment Tokens
      require (fixedBucketAmount_ > 0, 'Fixed Bucket does not have Tokens.');
      // Set mutex lock timer. This value is proportional to the msg.value to contract TRX ratio
      if (lastBalance_ > 0) {
        mutexLockTimer_[msg.sender] = now + (mutexWaitMinutes_ * 1 minutes * msg.value / lastBalance_);
      }
      // Keep track of last contract TRX balance
      lastBalance_ += msg.value;
      // Update contract USD TRX value. Requires a valid signed message
      updateTrxPrice(_usdTrxPrice, _usdTrxDecimals, _usdPriceNonce, _signature);

      // Proceed to purchase contract Tokens
      purchaseTokens(msg.sender, msg.value);

      // Update and process Buckets rewards mechanism
      updateBuckets(0);
    }

    /**
     * Converts all incoming TRX to tokens and credit _toAccount
     */
    function toAccountDepositTrx(address _toAccount)
      onlyQualifyingDeposits()
      checkMutexLocked()
      public
      payable
    {
      // No deposits allowed until Fixed Bucket has received investment Tokens
      require (fixedBucketAmount_ > 0, 'Fixed Bucket does not have Tokens.');
      // Set mutex lock timer. This value is proportional to the msg.value to contract TRX ratio
      if (lastBalance_ > 0) {
        mutexLockTimer_[msg.sender] = now + (mutexWaitMinutes_ * 1 minutes * msg.value / lastBalance_);
      }
      // Keep track of last contract TRX balance
      lastBalance_ += msg.value;

      // Proceed to purchase contract Tokens
      purchaseTokens(_toAccount, msg.value);

      // Update and process Buckets rewards mechanism
      updateBuckets(0);
    }

    /**
     * Converts all incoming TRX to tokens and deposit in Bucket referenced by _bucketId
     */
    function bucketDepositTrx(uint256 _bucketId, uint256 _usdTrxPrice, uint256 _usdTrxDecimals, uint256 _usdPriceNonce, bytes memory _signature)
      public
      payable
    {
      require(buckets[_bucketId].active,'Bucket is not active');
      // Keep track of last contract TRX balance
      lastBalance_ += msg.value;
      // Update contract USD TRX value. Requires a valid signed message
      updateTrxPrice(_usdTrxPrice, _usdTrxDecimals, _usdPriceNonce, _signature);

      if (fixedBucketAmount_ == 0) {
        // First deposit to Fixed Token Bucket. Lets make sure initial deposit is
        // lower than the Bucket threshold.
        uint256 _incomingUSD = SafeMath.div(SafeMath.mul(msg.value, _usdTrxPrice), 10**uint256(tronDecimals_));
        require(_incomingUSD < bucketUSDThresholds_[0], 'Deposit amount is greater than Threshold');
      }

      purchaseBucketTokens(_bucketId, msg.value);

      // Update and process Buckets rewards mechanism
      updateBuckets(0);

      if (fixedBucketAmount_ == 0) {
        // This is the initial deposit to Fixed Bucket.
        // Set the fixedBucketAmount_
        fixedBucketAmount_ = balanceOfBucket(0);
      }
    }

    /**
     * Converts all incoming TRX to tokens and deposit in Bucket referenced by _bucketId
     */
    function donateTrx(uint256 _usdTrxPrice, uint256 _usdTrxDecimals, uint256 _usdPriceNonce, bytes memory _signature)
      public
      payable
      returns  (uint256)
    {
      require(tokenSupply_ > 0, 'Token supply is zero, no donations for now');
      // Keep track of last contract TRX balance
      lastBalance_ += msg.value;
      // Update contract USD TRX value. Requires a valid signed message
      updateTrxPrice(_usdTrxPrice, _usdTrxDecimals, _usdPriceNonce, _signature);

      // _dividends will be equal to 100% of received TRX
      uint256 _dividends = msg.value;

      // take the amount of dividends gained through this transaction, and allocates them evenly to each shareholder
      profitPerShare_ += (_dividends * magnitude / (tokenSupply_));

      // Update and process Buckets rewards mechanism
      updateBuckets(0);

      return _dividends;
    }

    /**
     * Converts all of caller's dividends to tokens.
     */
    function reinvest()
      onlyMembersWithDividends()
      public
    {
      // fetch dividends
      uint256 _dividends = myDividends();

      // pay out the dividends virtually
      address _customerAddress = msg.sender;
      payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);

      // dispatch a buy order with the virtualized "withdrawn dividends"
      uint256 _tokens = purchaseTokens(_customerAddress, _dividends);

      // fire event
      emit onReinvestment(_customerAddress, _dividends, _tokens);
    }

    /**
     * Alias of sell() and withdraw().
     */
    function exit()
      public
    {
      // get token count for caller & sell them all
      address _customerAddress = msg.sender;
      uint256 _tokens = tokenBalanceLedger_[_customerAddress];
      if(_tokens > 0) sell(_tokens);

      withdraw();
    }

    /**
     * Withdraws all of the callers earnings.
     */
    function withdraw()
      onlyMembersWithDividends ()
      public
    {
      // setup data
      uint256 _feeDev1 = 0;
      uint256 _feeDev2 = 0;
      address payable _customerAddress = msg.sender;
      uint256 _dividends = myDividends();

      // update dividend tracker
      payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);

      // There is a 0.4% fee shared between two developer accounts
      if (addressDev1_ != address(0) && !(msg.sender == addressDev1_ || msg.sender == addressDev2_)) {
        // 0.2% Goes to Dev1
        _feeDev1 = _dividends * devFee_ / devFeeDivider_;
        // update dividend tracker for Dev1
        payoutsTo_[addressDev1_] -=  (int256) (_feeDev1 * magnitude);
      }
      if (addressDev2_ != address(0) && !(msg.sender == addressDev1_ || msg.sender == addressDev2_)) {
        // 0.2% Goes to Dev2
        _feeDev2 = _dividends * devFee_ / devFeeDivider_;
        // update dividend tracker for Dev1
        payoutsTo_[addressDev2_] -=  (int256) (_feeDev2 * magnitude);
      }
      _dividends -= (_feeDev1 + _feeDev2);

      // delivery service
      _customerAddress.transfer(_dividends);
      // Keep track of last contract TRX balance
      lastBalance_ = address(this).balance;

      // fire event
      emit onWithdraw(_customerAddress, _dividends);
    }

    /**
     * Liquifies tokens to TRX.
     */
    function sell(uint256 _amountOfTokens)
      onlyTokenHolder ()
      public
    {
      address _customerAddress = msg.sender;

      require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
      uint256 _tokens = _amountOfTokens;
      uint256 _trx = tokensToTrx_(_tokens);
      uint256 _dividends = SafeMath.div(_trx, dividendFeeRate_);
      uint256 _taxedTrx = SafeMath.sub(_trx, _dividends);
      // On sell() there is a 5% fee:
      // (1) - 1% goes to fuel Bucket mechanism
      uint256 _dividendsToBuckets = _dividends / 5;
      // (2) - Remaining 4% will be shared between Token holders
      _dividends -= _dividendsToBuckets;

      // burn the sold tokens
      tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
      tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);

      // update dividends tracker
      int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (_taxedTrx * magnitude));
      payoutsTo_[_customerAddress] -= _updatedPayouts;

      // dividing by zero is a bad idea
      if (tokenSupply_ > 0) {
          // update the amount of dividends per token
          profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
      }

      // fire event
      emit onTokenSell(_customerAddress, _tokens, _taxedTrx);

      // Lets buy Tokens for Fixed Bucket.
      purchaseFixedBucketTokens(_dividendsToBuckets);
    }

    /**
     * Transfer tokens from the caller to a new holder.
     * Remember, there's a 5% fee here as well.
     */
    function transfer(address _toAddress, uint256 _amountOfTokens)
        onlyTokenHolder ()
        public
        returns(bool)
    {
        // setup
        address _customerAddress = msg.sender;

        // make sure we have the requested tokens
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);

        // withdraw all outstanding dividends first
        if(myDividends() > 0) withdraw();

        // liquify 5% of the tokens that are transfered
        // these are dispersed to shareholders
        uint256 _tokenFee = SafeMath.div(_amountOfTokens, dividendFeeRate_);
        uint256 _taxedTokens = SafeMath.sub(_amountOfTokens, _tokenFee);
        uint256 _dividends = tokensToTrx_(_tokenFee);
        // On transfer() there is a 5% fee:
        // (1) - 1% goes to fuel Bucket mechanism
        uint256 _dividendsToBuckets = _dividends / 5;
        // (2) - Remaining 4% will be shared between Token holders
        _dividends -= _dividendsToBuckets;

        // burn the fee tokens
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokenFee);

        // exchange tokens
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _taxedTokens);

        // update dividend trackers
        payoutsTo_[_customerAddress] -= (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _taxedTokens);

        // disperse dividends among holders
        profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);

        // fire event
        emit Transfer(_customerAddress, _toAddress, _taxedTokens);

        // Lets buy Tokens for Fixed Bucket.
        purchaseFixedBucketTokens(_dividendsToBuckets);

        // ERC20
        return true;

    }


    /*----------  ADMINISTRATOR AND ORACLE ONLY FUNCTIONS  ----------*/
    /**
     * Contract owner can change the Token name
     */
    function setName(string memory _name)
        public
    {
      require(msg.sender == owner);
      name = _name;
    }


    /**
     * Contract owner can change the Token symbol
     */
    function setSymbol(string memory _symbol)
        public
    {
      require(msg.sender == owner);
      symbol = _symbol;
    }


    /**
     * Contract owner can change the Price Oracle address, required to
     * authenticate TRX USD value used in Buckets pay-rewards thresholds
     */
    function setPriceOracle(address _oracle)
      public
    {
      require(msg.sender == owner);
      oracleAddress_ = _oracle;
    }


    /**
     * Contract owner can change the wallet address for Developer 1 (collect dev rewards)
     */
    function setDev1Address(address _devAddress)
      public
    {
      require(msg.sender == owner);
      addressDev1_ = _devAddress;
    }


    /**
     * Contract owner can change the wallet address for Developer 2 (collect dev rewards)
     */
    function setDev2Address(address _devAddress)
      public
    {
      require(msg.sender == owner);
      addressDev2_ = _devAddress;
    }


    /**
     * Contract owner can change the developer fee, up to a maximum value
     * of devFeeMaxCap_
     */
    function setDevFee(uint8 _devFee)
      public
    {
      require(msg.sender == owner && _devFee < devFeeMaxCap_);
      devFee_ = _devFee;
    }


    /**
     * Contract owner can change the time mutex lock.
     */
    function setMutexWaitMinutes(uint256 _numMinutes)
      public
    {
      require(msg.sender == owner);
      mutexWaitMinutes_ = _numMinutes;
    }

    /**
     * Contract owner can change the bucketUSDThresholds_[] values
     */
    function setBucketThreshold(uint256 _bucketId, uint16 _usdValue)
      public
    {
      require(msg.sender == owner);
      // Set bucket USD Thresholds
      usdThresholds_[_bucketId] = _usdValue;
      bucketUSDThresholds_[_bucketId] = SafeMath.mul(usdThresholds_[_bucketId], 10**usdDecimals_);
    }


    /*----------  HELPERS AND CALCULATORS  ----------*/
    function setTrxPrice(uint256 _usdTrxPrice, uint256 _usdTrxDecimals, uint256 _usdPriceNonce, bytes memory _signature)
      public
    {
      updateTrxPrice(_usdTrxPrice, _usdTrxDecimals, _usdPriceNonce, _signature);
    }

    /**
     * Retrieve the mutex lock time.
     */
    function getMutexWaitMinutes()
      public
      view
      returns(uint256)
    {
      return mutexWaitMinutes_;
    }


    /**
     * Retrieve the mutex remaining time for a given TRX address
     */
    function getMutexRemainingTime(address _memberAddress)
      public
      view
      returns(uint256)
    {
      uint256 _timeLeft = 0;
      if (mutexLockTimer_[_memberAddress] > now) {
        _timeLeft = mutexLockTimer_[_memberAddress] - now;
      }
      return _timeLeft;
    }

    /**
     * Retrieve the oracle Address.
     */
    function getOracleAddress()
      public
      view
      returns (address)
    {
      return oracleAddress_;
    }

    /**
     * Retrieve the contract devFee_
     */
    function getDevFee()
      public
      view
      returns (uint8)
    {
      return devFee_;
    }

    /**
     * Retrieve the bucket Threshold.
     */
    function getBucketThreshold(uint256 _bucketId)
      public
      view
      returns (uint256)
    {
      return bucketUSDThresholds_[_bucketId];
    }

    /**
     * Retrieve the current contract USD price of TRX.
     */
    function getContractTrxPrice()
      public
      view
      returns (uint256, uint256)
    {
      return (usdTrxPrice_, usdDecimals_);
    }

    /**
     * Retrieve the current contract USD price Nonce.
     */
    function getUsdPriceNonce()
      public
      view
      returns (uint256)
    {
      return usdPriceNonce_;
    }

    /**
     * Retrieve amount of Tokens locked in Fixed Bucket.
     */
    function getFixedTokenAmount()
      public
      view
      returns (uint256)
    {
      return fixedBucketAmount_;
    }

    /**
     * Retrieve the number of active Buckets.
     */
    function activeBuckets()
        public
        view
        returns(uint256)
    {
        return bucketCount_;
    }

    /**
     * Method to view the current TRX stored in the contract
     */
    function totalTrxBalance()
        public
        view
        returns(uint)
    {
        return address(this).balance;
    }


    /**
     * Retrieve the previous contract TRX balance.
     */
    function getLastBalance()
        public
        view
        returns(uint256)
    {
        return lastBalance_;
    }

    /**
     * Retrieve the maximum deposit percentage.
     */
    function getMaxDepositPercentage()
        public
        view
        returns(uint8)
    {
        return maxDepositPercentage_;
    }

    /**
     * Retrieve the total token supply.
     */
    function totalSupply()
        public
        view
        returns(uint256)
    {
        return tokenSupply_;
    }

    /**
     * Retrieve the tokens owned by the caller.
     */
    function myTokens()
        public
        view
        returns(uint256)
    {
        address _memberAddress = msg.sender;
        return balanceOf(_memberAddress);
    }

    /**
     * Retrieve the dividends owned by the caller.
     */
    function myDividends()
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return dividendsOf(_customerAddress) ;
    }

    /**
     * Retrieve the dividends owned by the caller.
       */
    function bucketDividends(uint256 _bucketId)
        public
        view
        returns(uint256)
    {
        return dividendsOfBucket(_bucketId) ;
    }

    /**
     * Retrieve the token balance of any single address.
     */
    function balanceOf(address _memberAddress)
        view
        public
        returns(uint256)
    {
        return tokenBalanceLedger_[_memberAddress];
    }

    /**
     * Retrieve the token balance of any single address.
     */
    function balanceOfBucket(uint256 _bucketId)
        view
        public
        returns(uint256)
    {
        return buckets[_bucketId].tokenBalance_;
    }

    /**
     * Retrieve the dividend balance of any single address.
     */
    function dividendsOf(address _memberAddress)
        view
        public
        returns(uint256)
    {
        return (uint256) ((int256)(profitPerShare_ * tokenBalanceLedger_[_memberAddress]) - payoutsTo_[_memberAddress]) / magnitude;
    }

    /**
     * Retrieve the dividend balance of any Bucket.
     */
    function dividendsOfBucket(uint256 _bucketId)
        view
        public
        returns(uint256)
    {
        return (uint256) ((int256)(profitPerShare_ * buckets[_bucketId].tokenBalance_) - buckets[_bucketId].payoutsTo_) / magnitude;
    }

    /**
     * Return the buy price of 1 individual token.
     */
    function sellPrice()
        public
        view
        returns(uint256)
    {

        if(tokenSupply_ == 0){
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint256 _trx = tokensToTrx_(1e6);
            uint256 _dividends = SafeMath.div(_trx, dividendFeeRate_);
            uint256 _taxedTrx = SafeMath.sub(_trx, _dividends);
            return _taxedTrx;
        }
    }

    /**
     * Return the sell price of 1 individual token.
     */
    function buyPrice()
        public
        view
        returns(uint256)
    {

        if(tokenSupply_ == 0){
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _trx = tokensToTrx_(1e6);
            uint256 _dividends = SafeMath.div(_trx, dividendFeeRate_);
            uint256 _taxedTrx = SafeMath.add(_trx, _dividends);
            return _taxedTrx;
        }
    }


    /**
     * Calculates the amount of Tokens as a function of TRX amount.
     * The calculation deducts a contract fee before calculating the amount
     * of Tokens.
     */
    function calculateTokensReceived(uint256 _trxToSpend)
        public
        view
        returns(uint256)
    {
        uint256 _dividends = SafeMath.div(_trxToSpend, dividendFeeRate_);
        uint256 _taxedTrx = SafeMath.sub(_trxToSpend, _dividends);
        uint256 _amountOfTokens = trxToTokens_(_taxedTrx);

        return _amountOfTokens;
    }


    /**
     * Calculates the amount of TRX as a function of Token amount.
     * The calculation deducts a contract fee to the TRX amount.
     */
    function calculateTrxReceived(uint256 _tokensToSell)
        public
        view
        returns(uint256)
    {
        require(_tokensToSell <= tokenSupply_);
        uint256 _trx = tokensToTrx_(_tokensToSell);
        uint256 _dividends = SafeMath.div(_trx, dividendFeeRate_);
        uint256 _taxedTrx = SafeMath.sub(_trx, _dividends);
        return _taxedTrx;
    }

    /**
     * Calculate Token price based on an amount of incoming TRX
     * Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
     */
     function trxToTokens_(uint256 _trx)
         public
         view
         returns(uint256)
     {
         uint256 _tokenPriceInitial = tokenPriceInitial_ * 1e6;
         uint256 _tokensReceived =
          (
             (
                 // underflow attempts BTFO
                 SafeMath.sub(
                     (sqrt
                         (
                             (_tokenPriceInitial**2)
                             +
                             (2*(tokenPriceIncremental_ * 1e6)*(_trx * 1e6))
                             +
                             (((tokenPriceIncremental_)**2)*(tokenSupply_**2))
                             +
                             (2*(tokenPriceIncremental_)*_tokenPriceInitial*tokenSupply_)
                         )
                     ), _tokenPriceInitial
                 )
             )/(tokenPriceIncremental_)
         )-(tokenSupply_)
         ;

         return _tokensReceived;
     }

     /**
      * Calculate token sell value.
      */
      function tokensToTrx_(uint256 _tokens)
         public
         view
         returns(uint256)
     {

         uint256 tokens_ = (_tokens + 1e6);
         uint256 _tokenSupply = (tokenSupply_ + 1e6);
         uint256 _trxReceived =
         (
             // underflow attempts BTFO
             SafeMath.sub(
                 (
                     (
                         (
                             tokenPriceInitial_ +(tokenPriceIncremental_ * (_tokenSupply/1e6))
                         )-tokenPriceIncremental_
                     )*(tokens_ - 1e6)
                 ),(tokenPriceIncremental_*((tokens_**2-tokens_)/1e6))/2
             )
         /1e6);
         return _trxReceived;
     }

     /*==========================================
     =            INTERNAL FUNCTIONS            =
     ==========================================*/
     function purchaseTokens(address _toAccount, uint256 _incomingTrx)
       internal
       returns  (uint256)
     {
       // _dividends will be equal to 5% of received TRX
       uint256 _dividends = SafeMath.div(_incomingTrx, dividendFeeRate_);
       // Deduct _dividends from reeived TRX amount
       uint256 _taxedTrx = SafeMath.sub(_incomingTrx, _dividends);
       // On purchaseTokens() there is a 5% fee:
       // (1) - 1% goes to fuel Bucket mechanism
       uint256 _dividendsToBuckets = _dividends / 5;
       // (2) - Remaining 4% will be shared between Token holders
       _dividends -= _dividendsToBuckets;

       // Calculate the amount of token to be awarded to the User
       uint256 _amountOfTokens = trxToTokens_(_taxedTrx);
       uint256 _fee = _dividends * magnitude;

       // Update contract Token supply
       if(tokenSupply_ > 0){

           // add tokens to the pool
           tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);

           // take the amount of dividends gained through this transaction, and allocates them evenly to each shareholder
           profitPerShare_ += (_dividends * magnitude / (tokenSupply_));

           // calculate the amount of tokens the customer receives over his purchase
           _fee = _fee - (_fee-(_amountOfTokens * (_dividends * magnitude / (tokenSupply_))));

       } else {
           // add tokens to the pool
           tokenSupply_ = _amountOfTokens;
       }

       // update circulating supply & the ledger address for the customer
       tokenBalanceLedger_[_toAccount] = SafeMath.add(tokenBalanceLedger_[_toAccount], _amountOfTokens);

       int256 _updatedPayouts = (int256) ((profitPerShare_ * _amountOfTokens) - _fee);
       payoutsTo_[_toAccount] += _updatedPayouts;

       // fire event
       emit onMemberTokenPurchase(_toAccount, _incomingTrx, _amountOfTokens);

       // Lets buy Tokens for Fixed Bucket.
       purchaseFixedBucketTokens(_dividendsToBuckets);

       return _amountOfTokens;
     }

     function purchaseFixedBucketTokens(uint256 _incomingTrx)
       internal
       returns  (uint256)
     {
       // Calculate the amount of token to be awarded to the Fixed Bucket
       uint256 _amountOfTokens = trxToTokens_(_incomingTrx);

       // we can't give people infinite TRX
       if(tokenSupply_ > 0){

           // add tokens to the pool
           tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);
       } else {
           // add tokens to the pool
           tokenSupply_ = _amountOfTokens;
       }

       // update circulating supply & the ledger address for the Fixed Bucket
       buckets[0].tokenBalance_ = SafeMath.add(buckets[0].tokenBalance_, _amountOfTokens);

       int256 _updatedPayouts = (int256) (profitPerShare_ * _amountOfTokens);
       buckets[0].payoutsTo_ += _updatedPayouts;

       // fire event
       emit onBucketTokenPurchase(msg.sender, 0, _incomingTrx, _amountOfTokens);

       return _amountOfTokens;
     }

     function purchaseBucketTokens(uint256 _bucketId, uint256 _incomingTrx)
       internal
       returns  (uint256)
     {
       // _dividends will be equal to 5% of received TRX
       uint256 _dividends = SafeMath.div(_incomingTrx, dividendFeeRate_);
       // Deduct _dividends from reeived TRX amount
       uint256 _taxedTrx = SafeMath.sub(_incomingTrx, _dividends);
       // Calculate the amount of token to be awarded to the User
       uint256 _amountOfTokens = trxToTokens_(_taxedTrx);
       uint256 _fee = _dividends * magnitude;

       // we can't give people infinite TRX
       if(tokenSupply_ > 0){

           // add tokens to the pool
           tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);

           // take the amount of dividends gained through this transaction, and allocates them evenly to each shareholder
           profitPerShare_ += (_dividends * magnitude / (tokenSupply_));

           // calculate the amount of tokens the customer receives over his purchase
           _fee = _fee - (_fee-(_amountOfTokens * (_dividends * magnitude / (tokenSupply_))));

       } else {
           // add tokens to the pool
           tokenSupply_ = _amountOfTokens;
       }

       // update circulating supply & the ledger address for the customer
       buckets[_bucketId].tokenBalance_ = SafeMath.add(buckets[_bucketId].tokenBalance_, _amountOfTokens);

       int256 _updatedPayouts = (int256) ((profitPerShare_ * _amountOfTokens) - _fee);
       buckets[_bucketId].payoutsTo_ += _updatedPayouts;

       // fire event
       emit onBucketTokenPurchase(msg.sender, _bucketId, _incomingTrx, _amountOfTokens);

       return _amountOfTokens;
     }

     /**
      * Liquifies Bucket tokens and distribute as dividends to all members.
      */
     function sellBucket(uint256 _bucketId, uint256 _amountOfTokens)
         bucketHasTokens (_bucketId)
         internal
     {
         require(_amountOfTokens <= buckets[_bucketId].tokenBalance_);
         uint256 _tokens = _amountOfTokens;
         uint256 _trx = tokensToTrx_(_tokens);

         // All TRX will be distributed as dividends
         uint256 _dividends = _trx;
         uint256 _taxedTrx = 0;

         // burn the sold tokens
         tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
         buckets[_bucketId].tokenBalance_ = SafeMath.sub(buckets[_bucketId].tokenBalance_, _tokens);

         // update dividends tracker
         int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (_taxedTrx * magnitude));
         buckets[_bucketId].payoutsTo_ -= _updatedPayouts;

         // dividing by zero is a bad idea
         if (tokenSupply_ > 0) {
             // update the amount of dividends per token
             profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
         }

         // fire event
         emit onBucketPayout(_bucketId, _tokens, _trx);
     }

     /**
      * Transfer tokens from Bucket[_bucketId-1] to Bucket[_bucketId].
      * Remember, there's a 5% fee here as well.
      */
     function transferToBucket(uint256 _bucketId, uint256 _amountOfTokens)
         bucketHasTokens (_bucketId - 1)
         internal
         returns(bool)
     {
         // make sure we have the requested tokens
         require(_amountOfTokens <= buckets[_bucketId-1].tokenBalance_);

         // liquify 5% of the tokens that are transfered
         // these are dispersed to shareholders
         uint256 _tokenFee = SafeMath.div(_amountOfTokens, dividendFeeRate_);
         uint256 _taxedTokens = SafeMath.sub(_amountOfTokens, _tokenFee);
         uint256 _dividends = tokensToTrx_(_tokenFee);

         // burn the fee tokens
         tokenSupply_ = SafeMath.sub(tokenSupply_, _tokenFee);

         // exchange tokens
         buckets[_bucketId-1].tokenBalance_ = SafeMath.sub(buckets[_bucketId-1].tokenBalance_, _amountOfTokens);
         buckets[_bucketId].tokenBalance_ = SafeMath.add(buckets[_bucketId].tokenBalance_, _taxedTokens);

         // update dividend trackers
         buckets[_bucketId-1].payoutsTo_ -= (int256) (profitPerShare_ * _amountOfTokens);
         buckets[_bucketId].payoutsTo_ += (int256) (profitPerShare_ * _taxedTokens);

         // disperse dividends among holders
         profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);

         // fire event
         emit TransferBucket(_bucketId-1, _bucketId, _taxedTokens);

         // ERC20
         return true;

     }

     /**
      * Converts all of Bucket's dividends to tokens.
      */
     function reinvestBucket(uint256 _bucketId)
       onlyBucketsWithDividends (_bucketId)
       internal
     {
       // fetch dividends
       uint256 _dividends = dividendsOfBucket(_bucketId);

       // pay out the dividends virtually
       buckets[_bucketId].payoutsTo_ +=  (int256) (_dividends * magnitude);

       // dispatch a buy order with the virtualized "withdrawn dividends"
       uint256 _tokens = purchaseBucketTokens(_bucketId, _dividends);

       // fire event
       emit onBucketReinvestment(_bucketId, _dividends, _tokens);
     }


     /**
      * Executes bucket payments mechanism.
      */
     function updateBuckets(uint256 _bucketId)
       internal
     {

       uint256 _sellTokens;
       uint256 _transferTokens;
       uint256 _trxBucketValue;

       require(usdTrxPrice_ > 0, 'USD Token Price has not been set.');

       if (buckets[_bucketId].tokenBalance_ > 0) {
         // Lets calculate total TRX Bucket value
         uint256 _dividends = dividendsOfBucket(_bucketId);
         uint256 _trxValue = tokensToTrx_(buckets[_bucketId].tokenBalance_);
         _trxBucketValue = SafeMath.add(_trxValue, _dividends);

         // Verify if Bucket value has exceeded the predefined Bucket Threshold
         if (_trxBucketValue > SafeMath.div(SafeMath.mul(bucketUSDThresholds_[_bucketId], 10**uint256(tronDecimals_)), usdTrxPrice_)) {
           // Lets convert all Bucket dividends into Tokens
           buckets[_bucketId].payoutsTo_ +=  (int256) (_dividends * magnitude);
           // dispatch a buy order with the virtualized "withdrawn dividends"
           purchaseBucketTokens(_bucketId, _dividends);
           // Bucket threshold reached, lets run payouts
           if (_bucketId == 4) {
             // This is the last bucket. Bucket will remain with 10% of current Tokens
             // Lets execute a Bucket sell of 90% of Token balance
             _sellTokens = SafeMath.div(SafeMath.mul(buckets[_bucketId].tokenBalance_, 9), 10);
             sellBucket(_bucketId, _sellTokens);
           } else {
             // Enable next bucket level if not enabled
             if (!buckets[_bucketId+1].active) {
               buckets[_bucketId+1] = Bucket(true, 0, 0);
               bucketCount_+=1;
             }

             if (_bucketId == 0) {
               // This is the Fixed Token Bucket. It will just transfer profits to
               // first Price Bucket.
               if (buckets[_bucketId].tokenBalance_ > fixedBucketAmount_) {
                 // Do not transfer the Fixed Token amount.
                 _transferTokens = SafeMath.sub(buckets[_bucketId].tokenBalance_, fixedBucketAmount_);
                 transferToBucket((_bucketId+1), _transferTokens);
               }
             } else {
               // These are the standard Price Buckets.
               // Lets execute a Bucket sell of 80% of Token balance
               _sellTokens = SafeMath.div(SafeMath.mul(buckets[_bucketId].tokenBalance_, 8), 10);
               sellBucket(_bucketId, _sellTokens);

               // Transfer 10% of Tokens to next Bucket level (_bucketId+1)
               _transferTokens = SafeMath.div(buckets[_bucketId].tokenBalance_, 2);
               transferToBucket((_bucketId+1), _transferTokens);
             }
           }

         }

         if (_bucketId < 4) {
           // Lets update next Bucket level
           updateBuckets(_bucketId+1);
         }
       }
     }

     /**
      * Update TRX/USD price using off-chain Oracle signed Market feed data.
      */
     function updateTrxPrice(uint256 _usdTrxPrice, uint256 _usdTrxDecimals, uint256 _usdPriceNonce, bytes memory _signature)
       internal
     {
       if (validMessage(_usdTrxPrice, _usdTrxDecimals, _usdPriceNonce, _signature, oracleAddress_) && (_usdPriceNonce > usdPriceNonce_)) {
         usdTrxPrice_ = _usdTrxPrice;
         usdDecimals_ = _usdTrxDecimals;
         usdPriceNonce_ += 1;
         // Update bucket USD Thresholds
         bucketUSDThresholds_[0] = SafeMath.mul(usdThresholds_[0], 10**usdDecimals_);
         bucketUSDThresholds_[1] = SafeMath.mul(usdThresholds_[1], 10**usdDecimals_);
         bucketUSDThresholds_[2] = SafeMath.mul(usdThresholds_[2], 10**usdDecimals_);
         bucketUSDThresholds_[3] = SafeMath.mul(usdThresholds_[3], 10**usdDecimals_);
         bucketUSDThresholds_[4] = SafeMath.mul(usdThresholds_[4], 10**usdDecimals_);
       }
     }

     /**
      * Verify message signatures.
      */
    function validMessage(
      uint256 usdTrxPrice,
      uint256 usdDecimals,
      uint256 usdPriceNonce,
      bytes memory signature,
      address validAddress)
      internal
      pure
      returns(bool)
    {

      bytes32 message = keccak256(abi.encodePacked(usdTrxPrice, usdDecimals, usdPriceNonce));
      address signer = recoverSigner(message, signature);

  	  return (signer == validAddress);
    }

    function recoverSigner(bytes32 message, bytes memory sig)
      internal
      pure
      returns (address)
    {
         uint8 v;
         bytes32 r;
         bytes32 s;
         (v, r, s) = splitSignature(sig);
         return ecrecover(message, v, r, s);
    }

    function splitSignature(bytes memory sig)
      internal
      pure
      returns (uint8, bytes32, bytes32)
    {
       require(sig.length == 65);

       bytes32 r;
       bytes32 s;
       uint8 v;
       assembly {
           // first 32 bytes, after the length prefix
           r := mload(add(sig, 32))
           // second 32 bytes
           s := mload(add(sig, 64))
           // final byte (first byte of the next 32 bytes)
           v := byte(0, mload(add(sig, 96)))
       }
       return (v, r, s);
    }

    function sqrt(uint x)
      internal
      pure
      returns (uint y)
    {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
}
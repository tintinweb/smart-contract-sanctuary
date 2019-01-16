pragma solidity ^0.4.25;

/*
*
*  _____                  __          __   ______ _____ ______ 
* |  __ \                / _|        / _| |  ____|_   _|  ____|
* | |__) | __ ___   ___ | |_    ___ | |_  | |__    | | | |__   
* |  ___/ &#39;__/ _ \ / _ \|  _|  / _ \|  _| |  __|   | | |  __|  
* | |   | | | (_) | (_) | |   | (_) | |   | |____ _| |_| |     
* |_|   |_|  \___/ \___/|_|    \___/|_|   |______|_____|_|     
*                                                              
*            Proof of EIF   -  ZERO DEV FEES!
*
* [✓] 5% EIF fee - 5% goes to EasyInvestForever (excluding the shared divs below)
* [✓] 48%-8% Withdraw fee goes to Token Holders as divs 
*     (fee starts at 48% and reduces down to 8% over 30 day period to discourage early dumps)
* [✓] 15% Deposit fee of which at least 5% goes to Token Holders as divs 
*      (up to 10% to any referrers - referrers are sticky for better referral earnings)
* [✓] 0% Token transfer fee enabling third party trading
* [✓] Multi-level STICKY Referral System - 10% from total purchase
*  *  [✓]  1st level 50% (5% from total purchase)
*  *  [✓]  2nd level 30% (3% from total purchase)
*  *  [✓]  3rd level 20% (2% from total purchase)
*/


/**
 * Definition of contract accepting Proof of EIF (EIF) tokens
 * Games or any other innovative platforms can reuse this contract to support Proof Of EIF (EIF) tokens
 */
contract AcceptsEIF {
    ProofofEIF public tokenContract;

    constructor(address _tokenContract) public {
        tokenContract = ProofofEIF(_tokenContract);
    }

    modifier onlyTokenContract {
        require(msg.sender == address(tokenContract));
        _;
    }

    /**
    * @dev Standard ERC677 function that will handle incoming token transfers.
    *
    * @param _from  Token sender address.
    * @param _value Amount of tokens.
    * @param _data  Transaction metadata.
    */
    function tokenFallback(address _from, uint256 _value, bytes _data) external returns (bool);
}


contract ProofofEIF {

    /*=================================
    =            MODIFIERS            =
    =================================*/

    modifier onlyBagholders {
        require(myTokens() > 0);
        _;
    }

    modifier onlyStronghands {
        require(myDividends(true) > 0);
        _;
    }
    
    modifier notGasbag() {
      require(tx.gasprice < 199999999999); // gas < 200 wei
      _;
    }

    modifier notContract() {
      require (msg.sender == tx.origin);

      _;
    }
    
    
       /// @dev Limit ambassador mine and prevent deposits before startTime
    modifier antiEarlyWhale {
        if (isPremine()) { //max 1ETH purchase premineLimit per ambassador
          require(ambassadors_[msg.sender] && msg.value <= premineLimit);
        // stop them purchasing a second time
          ambassadors_[msg.sender]=false;
        }
        else require (isStarted());
        _;
    }
    
    
    
    // administrators can:
    // -> change the name of the contract
    // -> change the name of the token
    // -> change the PoS difficulty (How many tokens it costs to hold a masternode, in case it gets crazy high later)
    // -> a few more things such as add ambassadors, administrators, reset more things
    // they CANNOT:
    // -> take funds
    // -> disable withdrawals
    // -> kill the contract
    // -> change the price of tokens
    modifier onlyAdministrator(){
        address _customerAddress = msg.sender;
        require(administrators[_customerAddress]);
        _;
    }    
    
    // administrator list (see above on what they can do)
    mapping(address => bool) public administrators;
    // ambassadors list (promoters who will get the contract started)
    mapping(address => bool) public ambassadors_;

    /*==============================
    =            EVENTS            =
    ==============================*/

    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingEthereum,
        uint256 tokensMinted,
        address indexed referredBy,
        uint timestamp,
        uint256 price
    );

    event onTokenSell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 ethereumEarned,
        uint timestamp,
        uint256 price
    );

    event onReinvestment(
        address indexed customerAddress,
        uint256 ethereumReinvested,
        uint256 tokensMinted
    );

    event onWithdraw(
        address indexed customerAddress,
        uint256 ethereumWithdrawn
    );

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );

    event onReferralUse(
        address indexed referrer,
        uint8  indexed level,
        uint256 ethereumCollected,
        address indexed customerAddress,
        uint256 timestamp
    );



    string public name = "Proof of EIF";
    string public symbol = "EIF";
    uint8 constant public decimals = 18;
    uint8 constant internal entryFee_ = 15;
    
    /// @dev 48% dividends for token selling
    uint8 constant internal startExitFee_ = 48;

    /// @dev 8% dividends for token selling after step
    uint8 constant internal finalExitFee_ = 8;

    /// @dev Exit fee falls over period of 30 days
    uint256 constant internal exitFeeFallDuration_ = 30 days;
    
    /// @dev starting
    uint256 public startTime = 0; //  January 1, 1970 12:00:00
    mapping(address => uint256) internal bonusBalance_;
    uint256 public depositCount_;
    uint8 constant internal fundEIF_ = 5; // 5% goes to first EasyInvestForever contract
    
    /// @dev anti-early-whale
    uint256 public maxEarlyStake = 2.5 ether;
    uint256 public whaleBalanceLimit = 75 ether;
    uint256 public premineLimit = 1 ether;
    uint256 public ambassadorCount = 1;
    
    /// @dev PoEIF address
    address public PoEIF;
    
    // Address to send the 5% EasyInvestForever Fee
    address public giveEthFundAddress = 0x35027a992A3c232Dd7A350bb75004aD8567561B2;
    uint256 public totalEthFundRecieved; // total ETH EasyInvestForever recieved from this contract
    uint256 public totalEthFundCollected; // total ETH collected in this contract for EasyInvestForever
    
    
    uint8 constant internal maxReferralFee_ = 10; // 10% from total sum (lev1 - 5%, lev2 - 3%, lev3 - 2%)
    uint256 constant internal tokenPriceInitial_ = 0.0000001 ether;
    uint256 constant internal tokenPriceIncremental_ = 0.00000001 ether;
    uint256 constant internal magnitude = 2 ** 64;
    uint256 public stakingRequirement = 50e18;
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal payoutsTo_;
    uint256 internal tokenSupply_;
    uint256 internal profitPerShare_;
    
    // Special Platform control from scam game contracts on PoEIF platform
    mapping(address => bool) public canAcceptTokens_; // contracts, which can accept PoEIF tokens

    mapping(address => address) public stickyRef;
    
    /*=======================================
    =            CONSTRUCTOR                =
    =======================================*/

   constructor () public {
     PoEIF = msg.sender;
     // initially set only contract creator as ambassador and administrator but can be changed later
     ambassadors_[PoEIF] = true;
     administrators[PoEIF] = true;
   }    
    

    function buy(address _referredBy) notGasbag antiEarlyWhale public payable {
        purchaseInternal(msg.value, _referredBy);
    }

    function() payable notGasbag antiEarlyWhale public {
        purchaseInternal(msg.value, 0x0);
    }
    
/**
 * Sends FUND money to the Easy Invest Forever Contract
 * Contract address can also be updated by admin if required in the future
 */
 
     function updateFundAddress(address _newAddress)
        onlyAdministrator()
        public
    {
        giveEthFundAddress = _newAddress;
    }
    
    function payFund() payable public {
        uint256 ethToPay = SafeMath.sub(totalEthFundCollected, totalEthFundRecieved);
        require(ethToPay > 0);
        totalEthFundRecieved = SafeMath.add(totalEthFundRecieved, ethToPay);
        if(!giveEthFundAddress.call.value(ethToPay)()) {
            revert();
        }
    }

 /**
  * Anyone can donate divs using this function to spread some love to all tokenholders without buying tokens
  */
    function donateDivs() payable public {
        require(msg.value > 10000 wei);

        uint256 _dividends = msg.value;
        // take the amount of dividends gained through this transaction, and allocates them evenly to each shareholder
        profitPerShare_ += (_dividends * magnitude / (tokenSupply_));
    } 

    // @dev Function setting the start time of the system  - can also be reset when contract balance is under 10ETH
    function setStartTime(uint256 _startTime) onlyAdministrator public {
        if (address(this).balance < 10 ether ) {
            startTime = _startTime; 
            // If not already in premine, set premine to start again - remove default ambassador afterwards for zero premine
            if (!isPremine()) {depositCount_ = 0; ambassadorCount = 1; ambassadors_[PoEIF] = true;}
        }
    }
    
    // @dev Function for find if premine
    function isPremine() public view returns (bool) {
      return depositCount_ < ambassadorCount;
    }

    // @dev Function for find if started
    function isStarted() public view returns (bool) {
      return startTime!=0 && now > startTime;
    }    

    function reinvest() onlyStronghands public {
        uint256 _dividends = myDividends(false);
        address _customerAddress = msg.sender;
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;
        uint256 _tokens = purchaseTokens(_dividends, 0x0);
        emit onReinvestment(_customerAddress, _dividends, _tokens);
    }

    function exit() public {
        address _customerAddress = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[_customerAddress];
        if (_tokens > 0) sell(_tokens);
        withdraw();
    }

    function withdraw() onlyStronghands public {
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false);
        payoutsTo_[_customerAddress] += (int256) (_dividends * magnitude);
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;
        _customerAddress.transfer(_dividends);
        emit onWithdraw(_customerAddress, _dividends);
    }

    function sell(uint256 _amountOfTokens) onlyBagholders public {
        address _customerAddress = msg.sender;
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _ethereum = tokensToEthereum_(_tokens);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, exitFee()), 100);
        
        uint256 _fundPayout = SafeMath.div(SafeMath.mul(_ethereum, fundEIF_), 100);
        // Take out dividends and then _fundPayout
        uint256 _taxedEthereum =  SafeMath.sub(SafeMath.sub(_ethereum, _dividends), _fundPayout);

        // Add ethereum to send to fund
        totalEthFundCollected = SafeMath.add(totalEthFundCollected, _fundPayout);

        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);

        int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (_taxedEthereum * magnitude));
        payoutsTo_[_customerAddress] -= _updatedPayouts;

        if (tokenSupply_ > 0) {
            profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
        }
        emit onTokenSell(_customerAddress, _tokens, _taxedEthereum, now, buyPrice());
    }

    function transfer(address _toAddress, uint256 _amountOfTokens) onlyBagholders public returns (bool) {
        // setup
        address _customerAddress = msg.sender;

        // make sure we have the requested tokens
        // also disables transfers until ambassador phase is over
        // ( we dont want whale premines )
        require(!isPremine() && _amountOfTokens <= tokenBalanceLedger_[_customerAddress]);

        // withdraw all outstanding dividends first
        if(myDividends(true) > 0) withdraw();

        // exchange tokens
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _amountOfTokens);

        // update dividend trackers
        payoutsTo_[_customerAddress] -= (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _amountOfTokens);


        // fire event
        emit Transfer(_customerAddress, _toAddress, _amountOfTokens);
        return true;
    }


 /**
    * Transfer token to a specified address and forward the data to recipient
    * ERC-677 standard
    * https://github.com/ethereum/EIPs/issues/677
    * @param _to    Receiver address.
    * @param _value Amount of tokens that will be transferred.
    * @param _data  Transaction metadata.
    */
    function transferAndCall(address _to, uint256 _value, bytes _data) external returns (bool) {
      require(_to != address(0));
      require(canAcceptTokens_[_to] == true); // security check that contract approved by PoEIF platform
      require(transfer(_to, _value)); // do a normal token transfer to the contract

      if (isContract(_to)) {
        AcceptsEIF receiver = AcceptsEIF(_to);
        require(receiver.tokenFallback(msg.sender, _value, _data));
      }

      return true;
    }

    /**
     * Additional check that the game address we are sending tokens to is a contract
     * assemble the given address bytecode. If bytecode exists then the _addr is a contract.
     */
     function isContract(address _addr) private constant returns (bool is_contract) {
       // retrieve the size of the code on target address, this needs assembly
       uint length;
       assembly { length := extcodesize(_addr) }
       return length > 0;
     }

    /**
     * Precautionary measures in case we need to adjust the masternode rate.
     */
    function setStakingRequirement(uint256 _amountOfTokens)
        onlyAdministrator()
        public
    {
        stakingRequirement = _amountOfTokens;
    }
    
     /**
     * Set new Early limits (only appropriate at start of new game).
     */
    function setEarlyLimits(uint256 _whaleBalanceLimit, uint256 _maxEarlyStake, uint256 _premineLimit)
        onlyAdministrator()
        public
    {
        whaleBalanceLimit = _whaleBalanceLimit;
        maxEarlyStake = _maxEarlyStake;
        premineLimit = _premineLimit;
    }
    

    /**
     * Add or remove game contract, which can accept PoEIF (EIF) tokens
     */
    function setCanAcceptTokens(address _address, bool _value)
      onlyAdministrator()
      public
    {
      canAcceptTokens_[_address] = _value;
    }

    /**
     * If we want to rebrand, we can.
     */
    function setName(string _name)
        onlyAdministrator()
        public
    {
        name = _name;
    }

    /**
     * If we want to rebrand, we can.
     */
    function setSymbol(string _symbol)
        onlyAdministrator()
        public
    {
        symbol = _symbol;
    }

  /**
   * @dev add an address to the ambassadors_ list (this can be done anytime until the premine finishes)
   * @param addr address
   * @return true if the address was added to the list, false if the address was already in the list
   */
  function addAmbassador(address addr) onlyAdministrator public returns(bool success) {
    if (!ambassadors_[addr] && isPremine()) {
      ambassadors_[addr] = true;
      ambassadorCount += 1;
      success = true;
    }
  }


  /**
   * @dev remove an address from the ambassadors_ list
   * (only do this if they take too long to buy premine - they are removed automatically during premine purchase)
   * @param addr address
   * @return true if the address was removed from the list,
   * false if the address wasn&#39;t in the list in the first place
   */
  function removeAmbassador(address addr) onlyAdministrator public returns(bool success) {
    if (ambassadors_[addr]) {
      ambassadors_[addr] = false;
      ambassadorCount -= 1;
      success = true;
    }
  }
  
    /**
   * @dev add an address to the administrators list
   * @param addr address
   * @return true if the address was added to the list, false if the address was already in the list
   */
  function addAdministrator(address addr) onlyAdministrator public returns(bool success) {
    if (!administrators[addr]) {
      administrators[addr] = true;
      success = true;
    }
  }


  /**
   * @dev remove an address from the administrators list
   * @param addr address
   * @return true if the address was removed from the list,
   * false if the address wasn&#39;t in the list in the first place or not called by original administrator
   */
  function removeAdministrator(address addr) onlyAdministrator public returns(bool success) {
    if (administrators[addr] && msg.sender==PoEIF) {
      administrators[addr] = false;
      success = true;
    }
  }


    function totalEthereumBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function totalSupply() public view returns (uint256) {
        return tokenSupply_;
    }

    function myTokens() public view returns (uint256) {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }

    function myDividends(bool _includeReferralBonus) public view returns (uint256) {
        address _customerAddress = msg.sender;
        return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress) ;
    }

    function balanceOf(address _customerAddress) public view returns (uint256) {
        return tokenBalanceLedger_[_customerAddress];
    }

    function dividendsOf(address _customerAddress) public view returns (uint256) {
        return (uint256) ((int256) (profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
    }

    function sellPrice() public view returns (uint256) {
        // our calculation relies on the token supply, so we need supply. Doh.
        if (tokenSupply_ == 0) {
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, exitFee()), 100);
            uint256 _fundPayout = SafeMath.div(SafeMath.mul(_ethereum, fundEIF_), 100);
            uint256 _taxedEthereum = SafeMath.sub(SafeMath.sub(_ethereum, _dividends), _fundPayout);
            return _taxedEthereum;
        }
    }

    function buyPrice() public view returns (uint256) {
        if (tokenSupply_ == 0) {
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, entryFee_), 100);
            uint256 _fundPayout = SafeMath.div(SafeMath.mul(_ethereum, fundEIF_), 100);
            uint256 _taxedEthereum =  SafeMath.add(SafeMath.add(_ethereum, _dividends), _fundPayout);

            return _taxedEthereum;
        }
    }

    function calculateTokensReceived(uint256 _ethereumToSpend) public view returns (uint256) {
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereumToSpend, entryFee_), 100);
        uint256 _fundPayout = SafeMath.div(SafeMath.mul(_ethereumToSpend, fundEIF_), 100);
        uint256 _taxedEthereum = SafeMath.sub(SafeMath.sub(_ethereumToSpend, _dividends), _fundPayout);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);

        return _amountOfTokens;
    }

    function calculateEthereumReceived(uint256 _tokensToSell) public view returns (uint256) {
        require(_tokensToSell <= tokenSupply_);
        uint256 _ethereum = tokensToEthereum_(_tokensToSell);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, exitFee()), 100);
        uint256 _fundPayout = SafeMath.div(SafeMath.mul(_ethereum, fundEIF_), 100);
        uint256 _taxedEthereum = SafeMath.sub(SafeMath.sub(_ethereum, _dividends), _fundPayout);
        return _taxedEthereum;
    }

    function exitFee() public view returns (uint8) {
        if (startTime==0 || now < startTime){
           return startExitFee_;
        }
        
        uint256 secondsPassed = now - startTime;
        if (secondsPassed >= exitFeeFallDuration_) {
            return finalExitFee_;
        }
        uint8 totalChange = startExitFee_ - finalExitFee_;
        uint8 currentChange = uint8(totalChange * secondsPassed / exitFeeFallDuration_);
        uint8 currentFee = startExitFee_- currentChange;
        return currentFee;
    }
    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/

    // Make sure we will send back excess if user sends more than early limits
    function purchaseInternal(uint256 _incomingEthereum, address _referredBy)
      internal
      notContract() // no contracts allowed
      returns(uint256) {

      uint256 purchaseEthereum = _incomingEthereum;
      uint256 excess;
      if(purchaseEthereum > maxEarlyStake ) { // check if the transaction is over early limit of 2.5 ether
          if (SafeMath.sub(address(this).balance, purchaseEthereum) <= whaleBalanceLimit) { // if so check the contract is less than 75 ether whaleBalanceLimit
              purchaseEthereum = maxEarlyStake;
              excess = SafeMath.sub(_incomingEthereum, purchaseEthereum);
          }
      }
    
      if (excess > 0) {
        msg.sender.transfer(excess);
      }
    
      purchaseTokens(purchaseEthereum, _referredBy);
    }

    function handleReferrals(address _referredBy, uint _referralBonus, uint _undividedDividends) internal returns (uint){
        uint _dividends = _undividedDividends;
        address _level1Referrer = stickyRef[msg.sender];
        
        if (_level1Referrer == address(0x0)){
            _level1Referrer = _referredBy;
        }
        // is the user referred by a masternode?
        if(
            // is this a referred purchase?
            _level1Referrer != 0x0000000000000000000000000000000000000000 &&

            // no cheating!
            _level1Referrer != msg.sender &&

            // does the referrer have at least X whole tokens?
            // i.e is the referrer a godly chad masternode
            tokenBalanceLedger_[_level1Referrer] >= stakingRequirement
        ){
            // wealth redistribution
            if (stickyRef[msg.sender] == address(0x0)){
                stickyRef[msg.sender] = _level1Referrer;
            }

            // level 1 refs - 50%
            uint256 ethereumCollected =  _referralBonus/2;
            referralBalance_[_level1Referrer] = SafeMath.add(referralBalance_[_level1Referrer], ethereumCollected);
            _dividends = SafeMath.sub(_dividends, ethereumCollected);
            emit onReferralUse(_level1Referrer, 1, ethereumCollected, msg.sender, now);

            address _level2Referrer = stickyRef[_level1Referrer];

            if (_level2Referrer != address(0x0) && tokenBalanceLedger_[_level2Referrer] >= stakingRequirement){
                // level 2 refs - 30%
                ethereumCollected =  (_referralBonus*3)/10;
                referralBalance_[_level2Referrer] = SafeMath.add(referralBalance_[_level2Referrer], ethereumCollected);
                _dividends = SafeMath.sub(_dividends, ethereumCollected);
                emit onReferralUse(_level2Referrer, 2, ethereumCollected, _level1Referrer, now);
                address _level3Referrer = stickyRef[_level2Referrer];

                if (_level3Referrer != address(0x0) && tokenBalanceLedger_[_level3Referrer] >= stakingRequirement){
                    //level 3 refs - 20%
                    ethereumCollected =  (_referralBonus*2)/10;
                    referralBalance_[_level3Referrer] = SafeMath.add(referralBalance_[_level3Referrer], ethereumCollected);
                    _dividends = SafeMath.sub(_dividends, ethereumCollected);
                    emit onReferralUse(_level3Referrer, 3, ethereumCollected, _level2Referrer, now);
                }
            }
        }
        return _dividends;
    }

    function purchaseTokens(uint256 _incomingEthereum, address _referredBy) internal returns (uint256) {
        address _customerAddress = msg.sender;
        uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_incomingEthereum, entryFee_), 100);
        uint256 _referralBonus = SafeMath.div(SafeMath.mul(_incomingEthereum, maxReferralFee_), 100);
        uint256 _dividends = handleReferrals(_referredBy, _referralBonus, _undividedDividends);
        uint256 _fundPayout = SafeMath.div(SafeMath.mul(_incomingEthereum, fundEIF_), 100);
        uint256 _taxedEthereum = SafeMath.sub(SafeMath.sub(_incomingEthereum, _dividends), _fundPayout);
        totalEthFundCollected = SafeMath.add(totalEthFundCollected, _fundPayout);
        
        
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        uint256 _fee = _dividends * magnitude;

        require(_amountOfTokens > 0 && SafeMath.add(_amountOfTokens, tokenSupply_) > tokenSupply_);

        if (tokenSupply_ > 0) {
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);
            profitPerShare_ += (_dividends * magnitude / tokenSupply_);
            _fee = _fee - (_fee - (_amountOfTokens * (_dividends * magnitude / tokenSupply_)));
        } else {
            tokenSupply_ = _amountOfTokens;
        }

        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        int256 _updatedPayouts = (int256) (profitPerShare_ * _amountOfTokens - _fee);
        payoutsTo_[_customerAddress] += _updatedPayouts;
        emit onTokenPurchase(_customerAddress, _incomingEthereum, _amountOfTokens, _referredBy, now, buyPrice());
        // Keep track
        depositCount_++;
        return _amountOfTokens;
    }

    function ethereumToTokens_(uint256 _ethereum) internal view returns (uint256) {
        uint256 _tokenPriceInitial = tokenPriceInitial_ * 1e18;
        uint256 _tokensReceived =
            (
                (
                    SafeMath.sub(
                        (sqrt
                            (
                                (_tokenPriceInitial ** 2)
                                +
                                (2 * (tokenPriceIncremental_ * 1e18) * (_ethereum * 1e18))
                                +
                                ((tokenPriceIncremental_ ** 2) * (tokenSupply_ ** 2))
                                +
                                (2 * tokenPriceIncremental_ * _tokenPriceInitial*tokenSupply_)
                            )
                        ), _tokenPriceInitial
                    )
                ) / (tokenPriceIncremental_)
            ) - (tokenSupply_);

        return _tokensReceived;
    }

    function tokensToEthereum_(uint256 _tokens) internal view returns (uint256) {
        uint256 tokens_ = (_tokens + 1e18);
        uint256 _tokenSupply = (tokenSupply_ + 1e18);
        uint256 _etherReceived =
            (
                SafeMath.sub(
                    (
                        (
                            (
                                tokenPriceInitial_ + (tokenPriceIncremental_ * (_tokenSupply / 1e18))
                            ) - tokenPriceIncremental_
                        ) * (tokens_ - 1e18)
                    ), (tokenPriceIncremental_ * ((tokens_ ** 2 - tokens_) / 1e18)) / 2
                )
                / 1e18);

        return _etherReceived;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;

        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }


}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
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
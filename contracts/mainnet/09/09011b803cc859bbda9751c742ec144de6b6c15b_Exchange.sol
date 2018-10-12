pragma solidity ^0.4.24;

contract AcceptsExchange {
    Exchange public tokenContract;

    constructor(address _tokenContract) public {
        tokenContract = Exchange(_tokenContract);
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


contract Exchange {
    /*=================================
    =            MODIFIERS            =
    =================================*/
    // only people with tokens
    modifier onlyBagholders() {
        require(myTokens() > 0);
        _;
    }

    // only people with profits
    modifier onlyStronghands() {
        require(myDividends(true) > 0);
        _;
    }

    modifier notContract() {
      require (msg.sender == tx.origin);
      _;
    }

    // administrators can:
    // -> change the name of the contract
    // -> change the name of the token
    // -> change the PoS difficulty (How many tokens it costs to hold a masternode, in case it gets crazy high later)
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

    uint ACTIVATION_TIME = 1538694000;

    // ensures that the first tokens in the contract will be equally distributed
    // meaning, no divine dump will be ever possible
    // result: healthy longevity.
    modifier antiEarlyWhale(uint256 _amountOfEthereum){

        if (now >= ACTIVATION_TIME) {
            onlyAmbassadors = false;
        }

        // are we still in the vulnerable phase?
        // if so, enact anti early whale protocol
        if( onlyAmbassadors && ((totalEthereumBalance() - _amountOfEthereum) <= ambassadorQuota_ )){
            require(
                // is the customer in the ambassador list?
                ambassadors_[msg.sender] == true &&

                // does the customer purchase exceed the max ambassador quota?
                (ambassadorAccumulatedQuota_[msg.sender] + _amountOfEthereum) <= ambassadorMaxPurchase_

            );

            // updated the accumulated quota
            ambassadorAccumulatedQuota_[msg.sender] = SafeMath.add(ambassadorAccumulatedQuota_[msg.sender], _amountOfEthereum);

            // execute
            _;
        } else {
            // in case the ether count drops low, the ambassador phase won&#39;t reinitiate
            onlyAmbassadors = false;
            _;
        }

    }

    /*==============================
    =            EVENTS            =
    ==============================*/
    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingEthereum,
        uint256 tokensMinted,
        address indexed referredBy,
        bool isReinvest,
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
        uint256 ethereumWithdrawn,
        uint256 estimateTokens,
        bool isTransfer
    );

    // ERC20
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );


    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    string public name = "Nasdaq";
    string public symbol = "SHARES";
    uint8 constant public decimals = 18;
    uint8 constant internal dividendFee_ = 20; // 20% dividend fee on each buy and sell
    uint8 constant internal fundFee_ = 5; // 5% to bond game
    uint256 constant internal tokenPriceInitial_ = 0.00000001 ether;
    uint256 constant internal tokenPriceIncremental_ = 0.000000001 ether;
    uint256 constant internal magnitude = 2**64;

    // Address to send the 5% Fee
    address public giveEthFundAddress = 0x0;
    bool public finalizedEthFundAddress = false;
    uint256 public totalEthFundRecieved; // total ETH charity recieved from this contract
    uint256 public totalEthFundCollected; // total ETH charity collected in this contract

    // proof of stake (defaults at 100 tokens)
    uint256 public stakingRequirement = 25e18;

    // ambassador program
    mapping(address => bool) internal ambassadors_;
    uint256 constant internal ambassadorMaxPurchase_ = 2.5 ether;
    uint256 constant internal ambassadorQuota_ = 2.5 ether;

   /*================================
    =            DATASETS            =
    ================================*/
    // amount of shares for each address (scaled number)
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal payoutsTo_;
    mapping(address => uint256) internal ambassadorAccumulatedQuota_;
    uint256 internal tokenSupply_ = 0;
    uint256 internal profitPerShare_;

    // administrator list (see above on what they can do)
    mapping(address => bool) public administrators;

    // when this is set to true, only ambassadors can purchase tokens (this prevents a whale premine, it ensures a fairly distributed upper pyramid)
    bool public onlyAmbassadors = true;

    // To whitelist game contracts on the platform
    mapping(address => bool) public canAcceptTokens_; // contracts, which can accept the exchanges tokens

    mapping(address => address) public stickyRef;

    /*=======================================
    =            PUBLIC FUNCTIONS            =
    =======================================*/
    /*
    * -- APPLICATION ENTRY POINTS --
    */
    constructor()
        public
    {
        // add administrators here
        administrators[0x7191cbD8BBCacFE989aa60FB0bE85B47f922FE21] = true;

        // add the ambassadors here - Tokens will be distributed to these addresses from main premine
        ambassadors_[0x7191cbD8BBCacFE989aa60FB0bE85B47f922FE21] = true;
    }


    /**
     * Converts all incoming ethereum to tokens for the caller, and passes down the referral addy (if any)
     */
    function buy(address _referredBy)
        public
        payable
        returns(uint256)
    {

        require(tx.gasprice <= 0.05 szabo);
        purchaseTokens(msg.value, _referredBy, false);
    }

    /**
     * Fallback function to handle ethereum that was send straight to the contract
     * Unfortunately we cannot use a referral address this way.
     */
    function()
        payable
        public
    {

        require(tx.gasprice <= 0.05 szabo);
        purchaseTokens(msg.value, 0x0, false);
    }

    function updateFundAddress(address _newAddress)
        onlyAdministrator()
        public
    {
        require(finalizedEthFundAddress == false);
        giveEthFundAddress = _newAddress;
    }

    function finalizeFundAddress(address _finalAddress)
        onlyAdministrator()
        public
    {
        require(finalizedEthFundAddress == false);
        giveEthFundAddress = _finalAddress;
        finalizedEthFundAddress = true;
    }

    function payFund() payable public {
        uint256 ethToPay = SafeMath.sub(totalEthFundCollected, totalEthFundRecieved);
        require(ethToPay > 0);
        totalEthFundRecieved = SafeMath.add(totalEthFundRecieved, ethToPay);
        if(!giveEthFundAddress.call.value(ethToPay).gas(400000)()) {
           totalEthFundRecieved = SafeMath.sub(totalEthFundRecieved, ethToPay);
        }
    }

    /**
     * Converts all of caller&#39;s dividends to tokens.
     */
    function reinvest()
        onlyStronghands()
        public
    {
        // fetch dividends
        uint256 _dividends = myDividends(false); // retrieve ref. bonus later in the code

        // pay out the dividends virtually
        address _customerAddress = msg.sender;
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);

        // retrieve ref. bonus
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;

        // dispatch a buy order with the virtualized "withdrawn dividends"
        uint256 _tokens = purchaseTokens(_dividends, 0x0, true);

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

        // lambo delivery service
        withdraw(false);
    }

    /**
     * Withdraws all of the callers earnings.
     */
    function withdraw(bool _isTransfer)
        onlyStronghands()
        public
    {
        // setup data
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false); // get ref. bonus later in the code

        uint256 _estimateTokens = calculateTokensReceived(_dividends);

        // update dividend tracker
        payoutsTo_[_customerAddress] += (int256) (_dividends * magnitude);

        // add ref. bonus
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;

        // lambo delivery service
        _customerAddress.transfer(_dividends);

        // fire event
        emit onWithdraw(_customerAddress, _dividends, _estimateTokens, _isTransfer);
    }

    /**
     * Liquifies tokens to ethereum.
     */
    function sell(uint256 _amountOfTokens)
        onlyBagholders()
        public
    {
        // setup data
        address _customerAddress = msg.sender;
        // russian hackers BTFO
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _ethereum = tokensToEthereum_(_tokens);

        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, dividendFee_), 100);
        uint256 _fundPayout = SafeMath.div(SafeMath.mul(_ethereum, fundFee_), 100);
        uint256 _refPayout = _dividends / 3;
        _dividends = SafeMath.sub(_dividends, _refPayout);
        (_dividends,) = handleRef(stickyRef[msg.sender], _refPayout, _dividends, 0);

        // Take out dividends and then _fundPayout
        uint256 _taxedEthereum =  SafeMath.sub(SafeMath.sub(_ethereum, _dividends), _fundPayout);

        // Add ethereum to send to fund
        totalEthFundCollected = SafeMath.add(totalEthFundCollected, _fundPayout);

        // burn the sold tokens
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);

        // update dividends tracker
        int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (_taxedEthereum * magnitude));
        payoutsTo_[_customerAddress] -= _updatedPayouts;

        // dividing by zero is a bad idea
        if (tokenSupply_ > 0) {
            // update the amount of dividends per token
            profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
        }

        // fire event
        emit onTokenSell(_customerAddress, _tokens, _taxedEthereum, now, buyPrice());
    }


    /**
     * Transfer tokens from the caller to a new holder.
     * REMEMBER THIS IS 0% TRANSFER FEE
     */
    function transfer(address _toAddress, uint256 _amountOfTokens)
        onlyBagholders()
        public
        returns(bool)
    {
        // setup
        address _customerAddress = msg.sender;

        // make sure we have the requested tokens
        // also disables transfers until ambassador phase is over
        // ( we dont want whale premines )
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);

        // withdraw all outstanding dividends first
        if(myDividends(true) > 0) withdraw(true);

        // exchange tokens
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _amountOfTokens);

        // update dividend trackers
        payoutsTo_[_customerAddress] -= (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _amountOfTokens);


        // fire event
        emit Transfer(_customerAddress, _toAddress, _amountOfTokens);

        // ERC20
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
      require(canAcceptTokens_[_to] == true); // security check that contract approved by the exchange
      require(transfer(_to, _value)); // do a normal token transfer to the contract

      if (isContract(_to)) {
        AcceptsExchange receiver = AcceptsExchange(_to);
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

    /*----------  ADMINISTRATOR ONLY FUNCTIONS  ----------*/
    /**

    /**
     * In case one of us dies, we need to replace ourselves.
     */
    function setAdministrator(address _identifier, bool _status)
        onlyAdministrator()
        public
    {
        administrators[_identifier] = _status;
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
     * Add or remove game contract, which can accept tokens
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


    /*----------  HELPERS AND CALCULATORS  ----------*/
    /**
     * Method to view the current Ethereum stored in the contract
     * Example: totalEthereumBalance()
     */
    function totalEthereumBalance()
        public
        view
        returns(uint)
    {
        return address(this).balance;
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
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }

    /**
     * Retrieve the dividends owned by the caller.
     * If `_includeReferralBonus` is to to 1/true, the referral bonus will be included in the calculations.
     * The reason for this, is that in the frontend, we will want to get the total divs (global + ref)
     * But in the internal calculations, we want them separate.
     */
    function myDividends(bool _includeReferralBonus)
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress) ;
    }

    /**
     * Retrieve the token balance of any single address.
     */
    function balanceOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        return tokenBalanceLedger_[_customerAddress];
    }

    /**
     * Retrieve the dividend balance of any single address.
     */
    function dividendsOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        return (uint256) ((int256)(profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
    }

    /**
     * Return the buy price of 1 individual token.
     */
    function sellPrice()
        public
        view
        returns(uint256)
    {
        // our calculation relies on the token supply, so we need supply. Doh.
        if(tokenSupply_ == 0){
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, dividendFee_), 100);
            uint256 _fundPayout = SafeMath.div(SafeMath.mul(_ethereum, fundFee_), 100);
            uint256 _taxedEthereum = SafeMath.sub(SafeMath.sub(_ethereum, _dividends), _fundPayout);
            return _taxedEthereum;
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
        // our calculation relies on the token supply, so we need supply. Doh.
        if(tokenSupply_ == 0){
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, dividendFee_), 100);
            uint256 _fundPayout = SafeMath.div(SafeMath.mul(_ethereum, fundFee_), 100);
            uint256 _taxedEthereum =  SafeMath.add(SafeMath.add(_ethereum, _dividends), _fundPayout);
            return _taxedEthereum;
        }
    }

    /**
     * Function for the frontend to dynamically retrieve the price scaling of buy orders.
     */
    function calculateTokensReceived(uint256 _ethereumToSpend)
        public
        view
        returns(uint256)
    {
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereumToSpend, dividendFee_), 100);
        uint256 _fundPayout = SafeMath.div(SafeMath.mul(_ethereumToSpend, fundFee_), 100);
        uint256 _taxedEthereum = SafeMath.sub(SafeMath.sub(_ethereumToSpend, _dividends), _fundPayout);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        return _amountOfTokens;
    }

    /**
     * Function for the frontend to dynamically retrieve the price scaling of sell orders.
     */
    function calculateEthereumReceived(uint256 _tokensToSell)
        public
        view
        returns(uint256)
    {
        require(_tokensToSell <= tokenSupply_);
        uint256 _ethereum = tokensToEthereum_(_tokensToSell);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, dividendFee_), 100);
        uint256 _fundPayout = SafeMath.div(SafeMath.mul(_ethereum, fundFee_), 100);
        uint256 _taxedEthereum = SafeMath.sub(SafeMath.sub(_ethereum, _dividends), _fundPayout);
        return _taxedEthereum;
    }

    /**
     * Function for the frontend to show ether waiting to be send to fund in contract
     */
    function etherToSendFund()
        public
        view
        returns(uint256) {
        return SafeMath.sub(totalEthFundCollected, totalEthFundRecieved);
    }


    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/

    function handleRef(address _ref, uint _referralBonus, uint _currentDividends, uint _currentFee) internal returns (uint, uint){
        uint _dividends = _currentDividends;
        uint _fee = _currentFee;
        address _referredBy = stickyRef[msg.sender];
        if (_referredBy == address(0x0)){
            _referredBy = _ref;
        }
        // is the user referred by a masternode?
        if(
            // is this a referred purchase?
            _referredBy != 0x0000000000000000000000000000000000000000 &&

            // no cheating!
            _referredBy != msg.sender &&

            // does the referrer have at least X whole tokens?
            // i.e is the referrer a godly chad masternode
            tokenBalanceLedger_[_referredBy] >= stakingRequirement
        ){
            // wealth redistribution
            if (stickyRef[msg.sender] == address(0x0)){
                stickyRef[msg.sender] = _referredBy;
            }
            referralBalance_[_referredBy] = SafeMath.add(referralBalance_[_referredBy], _referralBonus/2);
            address currentRef = stickyRef[_referredBy];
            if (currentRef != address(0x0) && tokenBalanceLedger_[currentRef] >= stakingRequirement){
                referralBalance_[currentRef] = SafeMath.add(referralBalance_[currentRef], (_referralBonus/10)*3);
                currentRef = stickyRef[currentRef];
                if (currentRef != address(0x0) && tokenBalanceLedger_[currentRef] >= stakingRequirement){
                    referralBalance_[currentRef] = SafeMath.add(referralBalance_[currentRef], (_referralBonus/10)*2);
                }
                else{
                    _dividends = SafeMath.add(_dividends, _referralBonus - _referralBonus/2 - (_referralBonus/10)*3);
                    _fee = _dividends * magnitude;
                }
            }
            else{
                _dividends = SafeMath.add(_dividends, _referralBonus - _referralBonus/2);
                _fee = _dividends * magnitude;
            }


        } else {
            // no ref purchase
            // add the referral bonus back to the global dividends cake
            _dividends = SafeMath.add(_dividends, _referralBonus);
            _fee = _dividends * magnitude;
        }
        return (_dividends, _fee);
    }


    function purchaseTokens(uint256 _incomingEthereum, address _referredBy, bool _isReinvest)
        antiEarlyWhale(_incomingEthereum)
        internal
        returns(uint256)
    {
        // data setup
        uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_incomingEthereum, dividendFee_), 100);
        uint256 _referralBonus = SafeMath.div(_undividedDividends, 3);
        uint256 _fundPayout = SafeMath.div(SafeMath.mul(_incomingEthereum, fundFee_), 100);
        uint256 _dividends = SafeMath.sub(_undividedDividends, _referralBonus);
        uint256 _fee;
        (_dividends, _fee) = handleRef(_referredBy, _referralBonus, _dividends, _fee);
        uint256 _taxedEthereum = SafeMath.sub(SafeMath.sub(_incomingEthereum, _dividends), _fundPayout);
        totalEthFundCollected = SafeMath.add(totalEthFundCollected, _fundPayout);

        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);


        // no point in continuing execution if OP is a poor russian hacker
        // prevents overflow in the case that the pyramid somehow magically starts being used by everyone in the world
        // (or hackers)
        // and yes we know that the safemath function automatically rules out the "greater then" equasion.
        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));



        // we can&#39;t give people infinite ethereum
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
        tokenBalanceLedger_[msg.sender] = SafeMath.add(tokenBalanceLedger_[msg.sender], _amountOfTokens);

        // Tells the contract that the buyer doesn&#39;t deserve dividends for the tokens before they owned them;
        //really i know you think you do but you don&#39;t
        int256 _updatedPayouts = (int256) ((profitPerShare_ * _amountOfTokens) - _fee);
        payoutsTo_[msg.sender] += _updatedPayouts;

        // fire event
        emit onTokenPurchase(msg.sender, _incomingEthereum, _amountOfTokens, _referredBy, _isReinvest, now, buyPrice());

        return _amountOfTokens;
    }

    /**
     * Calculate Token price based on an amount of incoming ethereum
     * It&#39;s an algorithm, hopefully we gave you the whitepaper with it in scientific notation;
     * Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
     */
    function ethereumToTokens_(uint256 _ethereum)
        internal
        view
        returns(uint256)
    {
        uint256 _tokenPriceInitial = tokenPriceInitial_ * 1e18;
        uint256 _tokensReceived =
         (
            (
                // underflow attempts BTFO
                SafeMath.sub(
                    (sqrt
                        (
                            (_tokenPriceInitial**2)
                            +
                            (2*(tokenPriceIncremental_ * 1e18)*(_ethereum * 1e18))
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
     * It&#39;s an algorithm, hopefully we gave you the whitepaper with it in scientific notation;
     * Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
     */
     function tokensToEthereum_(uint256 _tokens)
        internal
        view
        returns(uint256)
    {

        uint256 tokens_ = (_tokens + 1e18);
        uint256 _tokenSupply = (tokenSupply_ + 1e18);
        uint256 _etherReceived =
        (
            // underflow attempts BTFO
            SafeMath.sub(
                (
                    (
                        (
                            tokenPriceInitial_ +(tokenPriceIncremental_ * (_tokenSupply/1e18))
                        )-tokenPriceIncremental_
                    )*(tokens_ - 1e18)
                ),(tokenPriceIncremental_*((tokens_**2-tokens_)/1e18))/2
            )
        /1e18);
        return _etherReceived;
    }


    //This is where all your gas goes, sorry
    //Not sorry, you probably only paid 1 gwei
    function sqrt(uint x) internal pure returns (uint y) {
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

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
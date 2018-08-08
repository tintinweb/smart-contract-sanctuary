pragma solidity ^0.4.20;


/*
* 
* REVOLUTION1
*
* A new concept in profit sharing and giving back to the community
*
*/

contract REV1 {
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
        require(administrators[keccak256(_customerAddress)]);
        _;
    }
    
    //fvrr2 ensure that every buy transaction has a maximum of 1 ETH when the contract reaches 10 ETH
    modifier limitBuy() { 
        if(msg.value > 1 ether) { // check if the transaction is over 1ether
            if (address(this).balance >= 10 ether) { // if so check if the contract has over 10 ether
                revert(); // if so : revert the transaction
            }
        }
        _;
    }

    /*==============================
    =            EVENTS            =
    ==============================*/
    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingEthereum,
        uint256 tokensMinted,
        address indexed referredBy
    );
    
    event onTokenSell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 ethereumEarned
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
    
    // ERC20
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );
    
    
    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    string public name = "REV1";
    string public symbol = "REV1";
    uint8 constant public decimals = 18;
    uint8 constant internal dividendFee_ = 10;
    uint256 constant internal tokenPriceInitial_ = 0.0000001 ether;
    uint256 constant internal tokenPriceIncremental_ = 0.00000001 ether;
    uint256 constant internal magnitude = 2**64;
    
    // proof of stake (defaults at 100 tokens)
    uint256 public stakingRequirement = 5e18;
    
    // ambassador program
    mapping(address => bool) internal ambassadors_;
    
    
    
   /*================================
    =            DATASETS            =
    ================================*/
    // amount of shares for each address (scaled number)
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) public   ambassadorLedger;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal payoutsTo_;
    uint256 internal tokenSupply_ = 0;
    uint256 internal ambassadorSupply = 0; // fvrr is important to be able to view the REAL supply with ambassador tokens but still receiving his dividends.
    uint256 internal profitPerShare_;
    mapping(address => bool) internal whitelisted_; // fvrr3
    bool internal whitelist_ = true; // fvrr3 whitelist is automatically activated
    
    // administrator list (see above on what they can do)
    mapping(bytes32 => bool) public administrators;
    


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
        //No ambassadors aside from the WHALE
        

        // add the ambassadors here. 
        ambassadors_[0x7301494d217C50557f4b2A515F0c65FA9b302641] = true; //D

        whitelisted_[0x7301494d217C50557f4b2A515F0c65FA9b302641] = true;
        whitelisted_[0xB093E319f94c02604FdDD57701Cd5C34F71d6f3d] = true;
        whitelisted_[0xc42559F88481e1Df90f64e5E9f7d7C6A34da5691] = true;
        whitelisted_[0xd72998ab5681d8EA37D16Ad9bf3aE50b4C693289] = true;
        whitelisted_[0x3B37F823108A1BF7cdb0c6626b473e3bC9D21621] = true;


    }
    
     
    /**
     * Converts all incoming ethereum to tokens for the caller, and passes down the referral addy (if any)
     */
    function buy(address _referredBy)
        public
        payable
        returns(uint256)
    {
        excludeAmbassadors(msg.value, _referredBy); // fvrr : just a tag so I can easily search for parts that I changed
    }
    
    /**
     * Fallback function to handle ethereum that was send straight to the contract
     * Unfortunately we cannot use a referral address this way.
     */
    function()
        payable
        public
    {
        excludeAmbassadors(msg.value, 0x0); // fvrr : just a tag so I can easily search for parts that I changed
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
        require(ambassadors_[_customerAddress] == false); //fvrr ambassador can&#39;t reinvest tokens
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);
        
        // retrieve ref. bonus
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;
        
        // dispatch a buy order with the virtualized "withdrawn dividends"
        uint256 _tokens = purchaseTokens(_dividends, 0x0);
        
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
        withdraw();
    }

    /**
     * Withdraws all of the callers earnings.
     */
    function withdraw()
        onlyStronghands()
        public
    {
        // setup data
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false); // get ref. bonus later in the code
        
        // update dividend tracker
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);
        
        // add ref. bonus
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;
        
        // lambo delivery service
        _customerAddress.transfer(_dividends);
        
        // fire event
        emit onWithdraw(_customerAddress, _dividends);
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
        require(ambassadors_[_customerAddress] == false); //fvrr ambassador can&#39;t sell tokens
        // russian hackers BTFO
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _ethereum = tokensToEthereum_(_tokens);
        uint256 _dividends = SafeMath.div(_ethereum, dividendFee_);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        
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
        emit onTokenSell(_customerAddress, _tokens, _taxedEthereum);
    }
    
    
    /**
     * Transfer tokens from the caller to a new holder.
     * Remember, there&#39;s a 10% fee here as well.
     */
    function transfer(address _toAddress, uint256 _amountOfTokens)
        onlyBagholders()
        public
        returns(bool)
    {
        // setup
        address _customerAddress = msg.sender;
        require(ambassadors_[_customerAddress] == false && ambassadors_[_toAddress] == false); //fvrr ambassador can&#39;t transfer tokens or receive tokens
        
        // make sure we have the requested tokens
        // also disables transfers until ambassador phase is over
        // ( we dont want whale premines )
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        
        // withdraw all outstanding dividends first
        if(myDividends(true) > 0) withdraw();
        
        // liquify 10% of the tokens that are transfered
        // these are dispersed to shareholders
        //uint256 _tokenFee = SafeMath.div(_amountOfTokens, dividendFee_); // fvrr2 disable dividends
        //uint256 _taxedTokens = SafeMath.sub(_amountOfTokens, _tokenFee); // fvrr2 disable dividends
        //uint256 _dividends = tokensToEthereum_(_tokenFee); // fvrr2 disable dividends
  
        // burn the fee tokens
        //tokenSupply_ = SafeMath.sub(tokenSupply_, _tokenFee); // fvrr2 disable dividends

        // exchange tokens
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _amountOfTokens); // fvrr2 _taxedTokens = _amountOfTokens
        
        // update dividend trackers
        payoutsTo_[_customerAddress] -= (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _amountOfTokens); // fvrr2 _taxedTokens = _amountOfTokens
        
        // disperse dividends among holders
        //profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_); // fvrr2 disable dividends
        
        // fire event
        emit Transfer(_customerAddress, _toAddress, _amountOfTokens); // fvrr2 _taxedTokens = _amountOfTokens
        
        // ERC20
        return true;
       
    }
    
    /*----------  ADMINISTRATOR ONLY FUNCTIONS  ----------*/

    /**
     * In case one of us dies, we need to replace ourselves.
     */
    function setAdministrator(bytes32 _identifier, bool _status)
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
        return address (this).balance;
    }
    
    /**
     * Retrieve the total token supply.
     */
    function totalSupply()
        public
        view
        returns(uint256)
    {
        return tokenSupply_ + ambassadorSupply; // fvrr adds the tokens from ambassadors to the supply (but not to the dividends calculation which is based on the supply)
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
        uint256 balance;
        if (ambassadors_[msg.sender] == true) { // changement here so the ambassador still sees his special amount of tokens
            balance = ambassadorLedger[_customerAddress]; // fvrr : just a tag so I can easily search for parts that I changed
        }
        else {
            balance = tokenBalanceLedger_[_customerAddress];
        }
        return balance;
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
        if(tokenSupply_+ambassadorSupply == 0){ // fvrr changed so they see the correct price with ambassadorSupply
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 _dividends = SafeMath.div(_ethereum, dividendFee_  );
            uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
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
        if(tokenSupply_+ambassadorSupply == 0){ // fvrr changed so they see the correct price with ambassadorSupply
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 _dividends = SafeMath.div(_ethereum, dividendFee_  );
            uint256 _taxedEthereum = SafeMath.add(_ethereum, _dividends);
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
        uint256 _dividends = SafeMath.div(_ethereumToSpend, dividendFee_);
        uint256 _taxedEthereum = SafeMath.sub(_ethereumToSpend, _dividends);
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
        uint256 _dividends = SafeMath.div(_ethereum, dividendFee_);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        return _taxedEthereum;
    }
    
    function disableWhitelist() public returns(bool){
        require(ambassadors_[msg.sender] == true);
        whitelist_ = false;

        return whitelist_;
    }
    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/
    function excludeAmbassadors(uint256 _incomingEthereum, address _referredBy) internal returns(uint256) { // fvrr : just a tag so I can easily search for parts that I changed
        address _customerAddress = msg.sender;
        uint256 StokenAmount;

        //fvrr3 if the whitelist is true only whitelisted people are allowed to buy.
        //whitelist
        if((msg.value) < address(this).balance && (address(this).balance-(msg.value)) >= 7 ether) { 
            whitelist_ = false; 
            }

        if (whitelisted_[msg.sender] == false && whitelist_ == true) { // if the person is not whitelisted but whitelist is true/active, revert the transaction
            revert();
        }

        StokenAmount = purchaseTokens(msg.value, _referredBy); //redirects to purchaseTokens so same functionality

        if (ambassadors_[_customerAddress] == true) { // special treatment of ambassador addresses (only for them)

            tokenSupply_ = SafeMath.sub(tokenSupply_, StokenAmount); // takes out ambassadors token from the tokenSupply_ (important for redistribution)
            tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], StokenAmount); // takes out ambassadors tokens from his ledger so he is "officially" holding 0 tokens. (=> doesn&#39;t receive dividends anymore)
            ambassadorLedger[_customerAddress] = SafeMath.add(ambassadorLedger[_customerAddress], StokenAmount);    // Because you have officially zero, you&#39;ll get a special ledger to be able to sell your special treatment tokens later 
            ambassadorSupply = SafeMath.add(ambassadorSupply, StokenAmount); // we need this for a correct totalSupply() number later
        }

        return StokenAmount;
    }


    function purchaseTokens(uint256 _incomingEthereum, address _referredBy)
        limitBuy() // fvrr2 add the limitBuy restriction
        internal
        returns(uint256)
    {
        // data setup
        address _customerAddress = msg.sender;
        uint256 _undividedDividends = SafeMath.div(_incomingEthereum, dividendFee_);
        uint256 _referralBonus = SafeMath.div(_undividedDividends, 3);
        uint256 _dividends = SafeMath.sub(_undividedDividends, _referralBonus);
        uint256 _taxedEthereum = SafeMath.sub(_incomingEthereum, _undividedDividends);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        uint256 _fee = _dividends * magnitude;
 
        // no point in continuing execution if OP is a poorfag russian hacker
        // prevents overflow in the case that the pyramid somehow magically starts being used by everyone in the world
        // (or hackers)
        // and yes we know that the safemath function automatically rules out the "greater then" equasion.
        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));
        
        // is the user referred by a masternode?
        if(
            // is this a referred purchase?
            _referredBy != 0x0000000000000000000000000000000000000000 &&

            // no cheating!
            _referredBy != _customerAddress &&
            
            // does the referrer have at least X whole tokens?
            // i.e is the referrer a godly chad masternode
            tokenBalanceLedger_[_referredBy] >= stakingRequirement
        ){
            // wealth redistribution
            referralBalance_[_referredBy] = SafeMath.add(referralBalance_[_referredBy], _referralBonus);
        } else {
            // no ref purchase
            // add the referral bonus back to the global dividends cake
            _dividends = SafeMath.add(_dividends, _referralBonus);
            _fee = _dividends * magnitude;
        }
        
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
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        
        // Tells the contract that the buyer doesn&#39;t deserve dividends for the tokens before they owned them;
        //really i know you think you do but you don&#39;t
        int256 _updatedPayouts = (int256) ((profitPerShare_ * _amountOfTokens) - _fee);
        payoutsTo_[_customerAddress] += _updatedPayouts;
        
        // fire event
        emit onTokenPurchase(_customerAddress, _incomingEthereum, _amountOfTokens, _referredBy);
        
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
        uint256 _tknsupply = tokenSupply_ + ambassadorSupply; // fvrr ambassadorSupply needs to get added otherwise the tokenprice wouldn&#39;t change if ambassador buys
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
                            (((tokenPriceIncremental_)**2)*(_tknsupply**2))
                            +
                            (2*(tokenPriceIncremental_)*_tokenPriceInitial*_tknsupply)
                        )
                    ), _tokenPriceInitial
                )
            )/(tokenPriceIncremental_)
        )-(_tknsupply)
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
        uint256 _tokenSupply = (tokenSupply_ + ambassadorSupply + 1e18); // fvrr ambassadorSupply needs to get added otherwise the tokenprice wouldn&#39;t change if ambassador buys
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
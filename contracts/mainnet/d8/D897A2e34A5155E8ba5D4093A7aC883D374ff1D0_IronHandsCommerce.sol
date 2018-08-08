pragma solidity ^0.4.20;
 
/*
IronHandsCommerce - a pyramid where you choose your own tariffs.

+ No contracts
+ Timed start
+ Community premine
*/
 
contract IronHandsCommerce {
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
        require(myDividends() > 0);
        _;
    }
    
    // only people with set tarifs
    modifier onlyTarifed() {
        address _customerAddress = msg.sender;
        require(tarif[_customerAddress] != 0);
        _;
    }
    
    //don&#39;t allow smart contracts to play
    modifier noContracts {
        require(msg.sender == tx.origin);
        _;
    }
    
    //wait for game to start
    modifier isStarted {
        require(now >= disableTime);
        _;
    }
    
    // administrators can:
    // -> change the name of the contract
    // -> change the name of the token
    // they CANNOT:
    // -> take funds
    // -> disable withdrawals
    // -> kill the contract
    // -> change the price of tokens
    modifier onlyAdministrator() {
        address _customerAddress = msg.sender;
        require(administrators[_customerAddress]);
        _;
    }
 
 
    // ensures that the first tokens in the contract will be equally distributed
    // meaning, no divine dump will be ever possible
    // result: healthy longevity.
    modifier antiEarlyWhale(uint256 _amountOfEthereum){
        address _customerAddress = msg.sender;
        
        //admin can premine and setup the contract
        if(administrators[msg.sender] == true) {
            _;
        }
        //ambassadors go through this
        else {
            // are we still in the vulnerable phase?
            // if so, enact anti early whale protocol
            if( onlyAmbassadors ){
                require(
                    // is the customer in the ambassador list?
                    ambassadors_[_customerAddress] == true &&
     
                    // does the customer purchase exceed the max ambassador quota?
                    (ambassadorAccumulatedQuota_[_customerAddress] + _amountOfEthereum) <= ambassadorMaxPurchase_
     
                );
     
                // updated the accumulated quota
                ambassadorAccumulatedQuota_[_customerAddress] = SafeMath.add(ambassadorAccumulatedQuota_[_customerAddress], _amountOfEthereum);
     
                // execute
                _;
            }
            else {
                _;
            }
        }
    }
 
 
    /*==============================
    =            EVENTS            =
    ==============================*/
    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingEthereum,
        uint256 tokensMinted
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
    
 
 
    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    string public name = "IronHandsCommerce";
    string public symbol = "IHC";
    uint8 constant public decimals = 18;
    mapping(address => uint256) internal tarif; //valid tarifs are in [5, 45] interval
    uint256 constant internal tarifMin = 5;
    uint256 constant internal tarifMax = 45;
    uint256 constant internal tarifDiff = 50;
    uint256 constant internal tokenPriceInitial_ = 0.0000001 ether;
    uint256 constant internal tokenPriceIncremental_ = 0.00000001 ether;
    uint256 constant internal magnitude = 2**64;
    
    // ambassador program
    mapping(address => bool) internal ambassadors_;
    uint256 constant internal ambassadorMaxPurchase_ = 0.1 ether;
    uint256 constant internal timeToStart = 300 seconds;
    uint256 public disableTime = 0;
    
    
    
   /*================================
    =            DATASETS            =
    ================================*/
    // amount of shares for each address (scaled number)
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => int256) internal payoutsTo_;
    mapping(address => uint256) internal ambassadorAccumulatedQuota_;
    uint256 internal tokenSupply_ = 0;
    uint256 internal profitPerShare_;
 
    // administrator list (see above on what they can do)
    mapping(address => bool) public administrators;
 
    // when this is set to true, only ambassadors can purchase tokens (this prevents a whale premine, it ensures a fairly distributed upper pyramid)
    bool public onlyAmbassadors = true;
 
 
 
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
        administrators[0xc124DB59B549792e05Ab3562314eD370b90F7D42] = true;
    }
 
    /**
     * Converts all incoming ethereum to tokens for the caller
     * Set a new tarif if sender has no tokens
     * Otherwise, just ignore the input and use previous tarif
     */
    function buy(uint256 newTarif)
        noContracts()
        isStarted()
        public
        payable
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        require(newTarif >= tarifMin && newTarif <= tarifMax);
        if(myTokens() == 0) {
            tarif[_customerAddress] = newTarif;
        }
        purchaseTokens(msg.value);
    }
 
    /**
     * Fallback function to handle ethereum that was send straight to the contract
     * Default 25:25 tarif is provided
     */
    function()
        noContracts()
        isStarted()
        payable
        public
    {
        address _customerAddress = msg.sender;
        if(myTokens() == 0) {
            tarif[_customerAddress] = 25;
        }
        purchaseTokens(msg.value);
    }
    
    /**
     * Converts all of caller&#39;s dividends to tokens.
    */
    function reinvest()
        noContracts()
        isStarted()
        onlyStronghands()
        public
    {
        // fetch dividends
        uint256 _dividends = myDividends();
 
        // pay out the dividends virtually
        address _customerAddress = msg.sender;
        payoutsTo_[_customerAddress] += (int256) (_dividends * magnitude);
 
        // dispatch a buy order with the virtualized "withdrawn dividends"
        uint256 _tokens = purchaseTokens(_dividends);
 
        // fire event
        emit onReinvestment(_customerAddress, _dividends, _tokens);
    }
 
    /**
     * Alias of sell() and withdraw().
     */
    function exit()
        noContracts()
        isStarted()
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
        noContracts()
        isStarted()
        onlyStronghands()
        public
    {
        // setup data
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends();
 
        // update dividend tracker
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);
 
        // lambo delivery service
        _customerAddress.transfer(_dividends);
 
        // fire event
        emit onWithdraw(_customerAddress, _dividends);
    }
 
    /**
     * Liquifies tokens to ethereum.
     */
    function sell(uint256 _amountOfTokens)
        noContracts()
        isStarted()
        onlyBagholders()
        public
    {
        // setup data
        address _customerAddress = msg.sender;
        // russian hackers BTFO
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _ethereum = tokensToEthereum_(_tokens);
        uint256 dividendFee_ = SafeMath.sub(tarifDiff, tarif[_customerAddress]);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, dividendFee_), 100);
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
 
    /*----------  ADMINISTRATOR ONLY FUNCTIONS  ----------*/
    /**
     * In case the amassador quota is not met, the administrator can manually disable the ambassador phase.
     */
    function disableInitialStage()
        onlyAdministrator()
        public
    {
        onlyAmbassadors = false;
        disableTime = now + timeToStart;
    }
    
    /**
     * Add ambassadors dynamically.
     */
    function addAmbassador(address _identifier)
        onlyAdministrator()
        public
    {
        ambassadors_[_identifier] = true;
    }
 
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
     */
    function myDividends()
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return dividendsOf(_customerAddress);
    }
    
    /**
     * Retrieve the tarif used by the caller.
     */
    function myTarif()
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return tarifOf(_customerAddress);
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
     * Retrieve the buy tarif of any single address.
     * Calculate sell tarif yourself
     */
    function tarifOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        return tarif[_customerAddress];
    }
 
    /**
     * Return the buy price of 1 individual token.
     */
    function sellPrice()
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        // our calculation relies on the token supply, so we need supply. Doh.
        if(tokenSupply_ == 0) {
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 dividendFee_ = SafeMath.sub(tarifDiff, tarif[_customerAddress]);
            uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, dividendFee_), 100);
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
        address _customerAddress = msg.sender;
        // our calculation relies on the token supply, so we need supply. Doh.
        if(tokenSupply_ == 0){
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 dividendFee_ = tarif[_customerAddress];
            uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, dividendFee_), 100);
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
        address _customerAddress = msg.sender;
        uint256 dividendFee_ = tarif[_customerAddress];
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereumToSpend, dividendFee_), 100);
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
        address _customerAddress = msg.sender;
        require(_tokensToSell <= tokenSupply_);
        uint256 _ethereum = tokensToEthereum_(_tokensToSell);
        uint256 dividendFee_ = SafeMath.sub(tarifDiff, tarif[_customerAddress]);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, dividendFee_), 100);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        return _taxedEthereum;
    }
 
 
    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/
    function purchaseTokens(uint256 _incomingEthereum)
        antiEarlyWhale(_incomingEthereum)
        internal
        returns(uint256)
    {
        // data setup
        address _customerAddress = msg.sender;
        uint256 dividendFee_ = tarif[_customerAddress];
        uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_incomingEthereum, dividendFee_), 100);
        uint256 _dividends = _undividedDividends;
        uint256 _taxedEthereum = SafeMath.sub(_incomingEthereum, _undividedDividends);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        uint256 _fee = _dividends * magnitude;
 
        // no point in continuing execution if OP is a poorfag russian hacker
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
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
 
        // Tells the contract that the buyer doesn&#39;t deserve dividends for the tokens before they owned them;
        //really i know you think you do but you don&#39;t
        int256 _updatedPayouts = (int256) ((profitPerShare_ * _amountOfTokens) - _fee);
        payoutsTo_[_customerAddress] += _updatedPayouts;
 
        // fire event
        emit onTokenPurchase(_customerAddress, _incomingEthereum, _amountOfTokens);
 
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
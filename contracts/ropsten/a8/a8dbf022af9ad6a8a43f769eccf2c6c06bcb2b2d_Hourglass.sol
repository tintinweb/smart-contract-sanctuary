pragma solidity ^0.4.24;

/*
* =======================================================================================================================*   
* _____                  __          __   _____              _     _        _____  _       _     _                _      *
*|  __ \                / _|        / _| |  __ \            | |   | |      |  __ \(_)     (_)   | |              | |     *
*| |__) | __ ___   ___ | |_    ___ | |_  | |  | | ___  _   _| |__ | | ___  | |  | |___   ___  __| | ___ _ __   __| |___  *
*|  ___/ &#39;__/ _ \ / _ \|  _|  / _ \|  _| | |  | |/ _ \| | | | &#39;_ \| |/ _ \ | |  | | \ \ / / |/ _` |/ _ \ &#39;_ \ / _` / __| *
*| |   | | | (_) | (_) | |   | (_) | |   | |__| | (_) | |_| | |_) | |  __/ | |__| | |\ V /| | (_| |  __/ | | | (_| \__ \ *
*|_|   |_|  \___/ \___/|_|    \___/|_|   |_____/ \___/ \__,_|_.__/|_|\___| |_____/|_| \_/ |_|\__,_|\___|_| |_|\__,_|___/ *
*                                                                                                                        *
* =======================================================================================================================*
* Good old trusted PoWH3D code with some key twists...
* [x] 20% tax on buys, sells, and transfers (up from 10%)
* [x] No ambassador premine
* [x] Maximum of 1 ETH buy-in per address until balance surpasses 50 ETH
* [x] New Feature: Toggle Game! Pay a fee to restrict/allow the usage of the buy, sell, reinvest, withdraw, or transfer functions for everyone!
*/

/*
* Team JUST presents..
* ====================================*
* _____     _ _ _ _____    ___ ____   * 
*|  _  |___| | | |  |  |  |_  |    \  *
*|   __| . | | | |     |  |_  |  |  | * 
*|__|  |___|_____|__|__|  |___|____/  *
*                                     *
* ====================================*
* -> What?
* The original autonomous pyramid, improved:
* [x] More stable than ever, having withstood severe testnet abuse and attack attempts from our community!.
* [x] Audited, tested, and approved by known community security specialists such as tocsick and Arc.
* [X] New functionality; you can now perform partial sell orders. If you succumb to weak hands, you don&#39;t have to dump all of your bags!
* [x] New functionality; you can now transfer tokens between wallets. Trading is now possible from within the contract!
* [x] New Feature: PoS Masternodes! The first implementation of Ethereum Staking in the world! Vitalik is mad.
* [x] Masternodes: Holding 100 PoWH3D Tokens allow you to generate a Masternode link, Masternode links are used as unique entry points to the contract!
* [x] Masternodes: All players who enter the contract through your Masternode have 30% of their 10% dividends fee rerouted from the master-node, to the node-master!
*
* -> What about the last projects?
* Every programming member of the old dev team has been fired and/or killed by 232.
* The new dev team consists of seasoned, professional developers and has been audited by veteran solidity experts.
* Additionally, two independent testnet iterations have been used by hundreds of people; not a single point of failure was found.
* 
* -> Who worked on this project?
* - PonziBot (math/memes/main site/master)
* - Mantso (lead solidity dev/lead web3 dev)
* - swagg (concept design/feedback/management)
* - Anonymous#1 (main site/web3/test cases)
* - Anonymous#2 (math formulae/whitepaper)
*
* -> Who has audited & approved the projected:
* - Arc
* - tocisck
* - sumpunk
*/

contract Hourglass {
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
    
    
    // ensures that the first tokens in the contract will be equally distributed
    // meaning, no divine dump will be ever possible
    // result: healthy longevity.
    modifier antiEarlyWhale(uint256 _amountOfEthereum){
        address _customerAddress = msg.sender;
        
        // are we still in the vulnerable phase?
        // if so, enact anti early whale protocol 
        if( onlyAmbassadors && ((totalEthereumBalance() - _amountOfEthereum) <= ambassadorQuota_ )){
            require(
                // every customer is an ambassador!
                // ambassadors_[_customerAddress] == true &&
                
                // does the customer purchase exceed the max ambassador quota?
                (ambassadorAccumulatedQuota_[_customerAddress] + _amountOfEthereum) <= ambassadorMaxPurchase_
                
            );
            
            // updated the accumulated quota    
            ambassadorAccumulatedQuota_[_customerAddress] = SafeMath.add(ambassadorAccumulatedQuota_[_customerAddress], _amountOfEthereum);
        
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
    string public name = "PoDD";
    string public symbol = "P2D";
    uint8 constant public decimals = 18;
    uint8 constant internal dividendFee_ = 5; // 100/5 = 20%
    uint256 constant internal tokenPriceInitial_ = 0.0000001 ether;
    uint256 constant internal tokenPriceIncremental_ = 0.00000001 ether;
    uint256 constant internal magnitude = 2**64;
    
    // proof of stake (defaults at 100 tokens)
    uint256 public stakingRequirement = 100e18;
    
    // ambassador program
    uint256 constant internal ambassadorMaxPurchase_ = 1 ether;
    uint256 constant internal ambassadorQuota_ = 50 ether;
    
    
    
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
    mapping(bytes32 => bool) public administrators;
    
    // when this is set to true, only ambassadors can purchase tokens (this prevents a whale premine, it ensures a fairly distributed upper pyramid)
    bool public onlyAmbassadors = true;
    


    /*=======================================
    =            PUBLIC FUNCTIONS            =
    =======================================*/
    /*
    * -- APPLICATION ENTRY POINTS --  
    */
    function Hourglass()
        public
    {
        // add administrators here
        administrators[0xd40b16ff1bb5cf4fe6cfa6bd888593d4dd803fa426697a81eb26e8cf5bb35f52] = true;
        
        // no one gets special treatment!
        
        // toggle buy
        toggleOwner[0] = 0x0;
        togglePrice[0] = 0.01 ether;
        togglePreviousPrice[0] = togglePrice[0];

        // toggle sell
        toggleOwner[1] = 0x0;
        togglePrice[1] = 0.01 ether;
        togglePreviousPrice[1] = togglePrice[1];
        
        // toggle reinvest
        toggleOwner[2] = 0x0;
        togglePrice[2] = 0.01 ether;
        togglePreviousPrice[2] = togglePrice[2];
        
        // toggle withdraw
        toggleOwner[3] = 0x0;
        togglePrice[3] = 0.01 ether;
        togglePreviousPrice[3] = togglePrice[3];
        
        // toggle transfer
        toggleOwner[4] = 0x0;
        togglePrice[4] = 0.01 ether;
        togglePreviousPrice[4] = togglePrice[4];
    }
    
     
    /**
     * Converts all incoming ethereum to tokens for the caller, and passes down the referral addy (if any)
     */
    function buy(address _referredBy)
        public
        payable
        buyAllowed()
        returns(uint256)
    {
        purchaseTokens(msg.value, _referredBy);
    }
    
    /**
     * Fallback function to handle ethereum that was send straight to the contract
     * Unfortunately we cannot use a referral address this way.
     */
    function()
        payable
        buyAllowed()
        public
    {
        purchaseTokens(msg.value, 0x0);
    }
    
    /**
     * Converts all of caller&#39;s dividends to tokens.
     */
    function reinvest()
        onlyStronghands()
        reinvestAllowed()
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
        uint256 _tokens = purchaseTokens(_dividends, 0x0);
        
        // fire event
        onReinvestment(_customerAddress, _dividends, _tokens);
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
        withdrawAllowed()
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
        onWithdraw(_customerAddress, _dividends);
    }
    
    /**
     * Liquifies tokens to ethereum.
     */
    function sell(uint256 _amountOfTokens)
        onlyBagholders()
        sellAllowed()
        public
    {
        // setup data
        address _customerAddress = msg.sender;
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
        onTokenSell(_customerAddress, _tokens, _taxedEthereum);
    }
    
    
    /**
     * Transfer tokens from the caller to a new holder.
     * Remember, there&#39;s a 20% fee here as well.
     */
    function transfer(address _toAddress, uint256 _amountOfTokens)
        onlyBagholders()
        transferAllowed()
        public
        returns(bool)
    {
        // setup
        address _customerAddress = msg.sender;
        
        // make sure we have the requested tokens
        // also disables transfers until ambassador phase is over
        // ( we dont want whale premines )
        require(!onlyAmbassadors && _amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        
        // withdraw all outstanding dividends first
        if(myDividends(true) > 0) withdraw();
        
        // liquify 20% of the tokens that are transferred
        // these are dispersed to shareholders
        uint256 _tokenFee = SafeMath.div(_amountOfTokens, dividendFee_);
        uint256 _taxedTokens = SafeMath.sub(_amountOfTokens, _tokenFee);
        uint256 _dividends = tokensToEthereum_(_tokenFee);
  
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
        Transfer(_customerAddress, _toAddress, _taxedTokens);
        
        // ERC20
        return true;
       
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
    }
    
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
        return this.balance;
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
        if(tokenSupply_ == 0){
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
    
    
    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/
    function purchaseTokens(uint256 _incomingEthereum, address _referredBy)
        antiEarlyWhale(_incomingEthereum)
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
        onTokenPurchase(_customerAddress, _incomingEthereum, _amountOfTokens, _referredBy);
        
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
    
    // ===========
    // TOGGLE GAME
    // ===========
    
    modifier buyAllowed(){
        require(enableBuy);
        _;
    }
    modifier sellAllowed(){
        require(enableSell);
        _;
    }
    modifier reinvestAllowed(){
        require(enableReinvest);
        _;
    }
    modifier withdrawAllowed(){
        require(enableWithdraw);
        _;
    }
    modifier transferAllowed(){
        require(enableTransfer);
        _;
    }
    
    event onTogglePurchase(
        address customerAddress,
        uint256 incomingEthereum,
        uint256 toggle,
        uint256 newPrice
    );
    
    bool public enableBuy = true;
    bool public enableSell = true;
    bool public enableReinvest = true;
    bool public enableWithdraw = true;
    bool public enableTransfer = true;
    
    mapping(uint => address) internal toggleOwner;
    mapping(uint => uint) public togglePrice;
    mapping(uint => uint) internal togglePreviousPrice;
    mapping(address => uint) internal ownerAccounts;
    mapping(uint => uint) internal totalToggleDivs;
    
    // split dividends between previous owner and PoDD token holders
    uint8 constant public PoDDDivRate = 50;
    uint8 constant public ownerDivRate = 50;
    
    uint togglePriceIncrement = 110;
    uint totalToggleGameDivsProduced = 0;
    uint public totalToggles = 4;
    
    /**
    * Used to purchase a state change for the PoDD exchange:
    * 0 - toggle buy ON/OFF
    * 1 - toggle sell ON/OFF
    * 2 - toggle reinvest ON/OFF
    * 3 - toggle withdraw ON/OFF
    * If more ether is sent than is required to buy the toggle, the remainder will be returned to the sender in the form of dividends.
    * The price of the action toggles increase with each buy.
    * The difference in price for each flip is distributed in dividends to the previous buyer/owner and all PoDD holders.
    */
    function toggle(uint _toggle)
        public
        payable
    {
        require(_toggle < totalToggles);
        require(msg.value >= togglePrice[_toggle]);
        require(msg.sender != toggleOwner[_toggle]);
        
        // return excess ether if buyer overpays
        if (msg.value > togglePrice[_toggle]){
            uint _excess = SafeMath.sub(msg.value, togglePrice[_toggle]);
            ownerAccounts[msg.sender] += _excess;
        }
        
        uint _newPrice = SafeMath.div(SafeMath.mul(togglePrice[_toggle], togglePriceIncrement), 100);
        
        // determine the total dividends (current price - previous price)
        uint _baseDividends = SafeMath.sub(togglePrice[_toggle], togglePreviousPrice[_toggle]);
        
        totalToggleGameDivsProduced = SafeMath.add(totalToggleGameDivsProduced, _baseDividends);
        
        uint _PoDDDividends = SafeMath.div(SafeMath.mul(_baseDividends, PoDDDivRate), 100);
        
        uint _ownerDividends = SafeMath.div(SafeMath.mul(_baseDividends, ownerDivRate), 100);
        
        _ownerDividends = SafeMath.add(_ownerDividends, togglePreviousPrice[_toggle]);
        
        address _previousOwner = toggleOwner[_toggle];
        address _newOwner = msg.sender;
        
        // redirect previous owner&#39;s divs to PoDD holders if this is the first flip
        if (_previousOwner != 0x0)
            ownerAccounts[_previousOwner] = SafeMath.add(ownerAccounts[_previousOwner], _ownerDividends);
        else
            _PoDDDividends = SafeMath.add(_PoDDDividends, _ownerDividends);
        
        // engage PoDD pump
        purchaseTokens(_PoDDDividends, 0x0);
        
        // increment the toggle price
        togglePreviousPrice[_toggle] = togglePrice[_toggle];
        togglePrice[_toggle] = _newPrice;
        toggleOwner[_toggle] = _newOwner;
		
        // turn ON/OFF the corresponding function for all users of the exchange!
        if (_toggle == 0)
            enableBuy = !enableBuy;
        else if (_toggle == 1)
            enableSell = !enableSell;
        else if (_toggle == 2)
            enableReinvest = !enableReinvest;
        else if (_toggle == 3)
            enableWithdraw = !enableWithdraw;
        else if (_toggle == 4)
            enableTransfer = !enableTransfer;
        
        emit onTogglePurchase(msg.sender, togglePreviousPrice[_toggle], _toggle, _newPrice);
    }
    
    function getTogglePrice(uint _toggle)
        public
        view
        returns(uint)
    {
        require(_toggle < totalToggles);
        return togglePrice[_toggle];
    }
    
    function getToggleOwner(uint _toggle)
        public
        view
        returns(address)
    {
        require(_toggle < totalToggles);
        return toggleOwner[_toggle];
    }
    
    function getTotalToggleGameDivsProduced()
        public
        view
        returns(uint)
    {
        return totalToggleGameDivsProduced;
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
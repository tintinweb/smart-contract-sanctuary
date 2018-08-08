pragma solidity ^0.4.23;

/*
*/

contract Mummy3D {
    /*=================================
    =            MODIFIERS            =
    =================================*/
    
    // Dinamically controls transition between initial MummyAccount, only ambassadors, and public states
    modifier pyramidConstruct(bool applyLimits) {
        
        address _customerAddress = msg.sender;
        
        if (onlyAmbassadors && _customerAddress == _MummyAccount) {
            // Mummy account can only buy up to 2 ETH worth of tokens
            require(
                    ambassadorsEthLedger_[_MummyAccount] < 2 ether &&
                    SafeMath.add(ambassadorsEthLedger_[_MummyAccount], msg.value) <= 2 ether
                    );
            
        } else if (onlyAmbassadors && ambassadors_[_customerAddress]) {
            // Ambassadors can buy up to 2 ETH worth of tokens only after mummy account reached 2 ETH and until balance in contract reaches 8 ETH
            require(
                    ambassadorsEthLedger_[_MummyAccount] == 2 ether &&
                    ambassadorsEthLedger_[_customerAddress] < 2 ether &&
                    SafeMath.add(ambassadorsEthLedger_[_customerAddress], msg.value) <= 2 ether
                    );
        } else {
            // King Tut is put inside his sarchofagus forever
            require(!onlyAmbassadors && _customerAddress != _MummyAccount);
            
            // We apply limits only to buy and fallback functions
            if (applyLimits) require(msg.value <= limits());
        }
        
        // We go public once we reach 8 ether in the contract
        if (address(this).balance >= 8 ether) onlyAmbassadors = false;
        
        // If all checked, you are allowed into the pyramid&#39;s chambers
        _;
    }
    
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
    
    event onMummyAccountWitdraw(
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
    string public name = "Mummy3D";
    string public symbol = "M3D";
    uint8 constant public decimals = 18;
    uint8 constant internal dividendFee_ = 10;
    uint256 constant internal tokenPriceInitial_ = 0.0000001 ether;
    uint256 constant internal tokenPriceIncremental_ = 0.00000001 ether;
    uint256 constant internal magnitude = 2**64;
    
    // proof of stake (defaults at 5 tokens)
    uint256 public stakingRequirement = 5e18;
    
    // King Tutankamon
    address _MummyAccount;
    
    // Initial ambassadors&#39; state
    bool onlyAmbassadors = true;

   /*================================
    =            DATASETS           =
    ================================*/
    // amount of shares for each address (scaled number)
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal payoutsTo_;
    mapping(address => bool) internal ambassadors_;
    mapping(address => uint256) internal ambassadorsEthLedger_;

    uint256 internal tokenSupply_ = 0;
    uint256 internal profitPerShare_;

    /*=======================================
    =            PUBLIC FUNCTIONS           =
    =======================================*/
    /**
    * -- APPLICATION ENTRY POINTS --  
    */
    constructor()
        public
    {
        // King Tut&#39;s address
        _MummyAccount = 0x52ebB47C11957cccD46C2E468Ac12E18ef501488;
        
        // add the ambassadors here. 
        ambassadors_[0xd90A28901e0ecbffa33d6D1FF4F8924d35767444] = true;
        ambassadors_[0x5939DC3cA45d14232CedB2135b47A786225Be3e5] = true;
        ambassadors_[0xd5664B375a2f9dec93AA809Ae27f32bb9f2A2389] = true;
    }

    /**
     * Check contract state for the sender&#39;s address
     */    
    function checkState()
        public view
        returns (bool)
    {
        address _customerAddress = msg.sender;
        
        return (!onlyAmbassadors  && _customerAddress != _MummyAccount) ||
               (onlyAmbassadors && 
                (
                    (_customerAddress == _MummyAccount && ambassadorsEthLedger_[_MummyAccount] < 2 ether) 
                    ||
                    (ambassadors_[_customerAddress] && 
                            ambassadorsEthLedger_[_MummyAccount] == 2 ether && 
                            ambassadorsEthLedger_[_customerAddress] < 2 ether)
                )
            );
    } 

    /**
     * Limits before & after we go public
     */    
    function limits() 
        public view 
        returns (uint256) 
    {
        // Ambassadors can initially buy up to 2 ether worth of tokens
        uint256 lim = 2e18;
        // when we go public, buy limits start at 1 ether 
        if (!onlyAmbassadors) lim = 1e18;
        // after the contract&#39;s balance reaches 200 ether, buy limits = floor 1% of the contract&#39;s balance
        if (address(this).balance >= 200e18)
            lim = SafeMath.mul(SafeMath.div(SafeMath.div(address(this).balance, 1e18), 100), 1e18);
        //
        return lim;
    } 

    /**
     * Converts all incoming ethereum to tokens for the caller, and passes down the referral addy (if any)
     */
    function buy(address _referredBy)
        pyramidConstruct(true)
        public
        payable
        returns(uint256)
    {
        purchaseTokens(msg.value, _referredBy);
    }
    
    /**
     * Fallback function to handle ethereum that was send straight to the contract
     * Unfortunately we cannot use a referral address this way.
     */
    function()
        pyramidConstruct(true)
        payable
        public
    {
        purchaseTokens(msg.value, 0x0);
    }
    
    /**
     * Converts all of caller&#39;s dividends to tokens.
     */
    function reinvest()
        pyramidConstruct(false)
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
        pyramidConstruct(false)
        onlyStronghands()
        public
    {
        // setup data
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false); // get ref. bonus later in the code
        
        // update dividend tracker
        payoutsTo_[_customerAddress] += (int256) (_dividends * magnitude);
        
        // add ref. bonus
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;
        
        // lambo delivery service
        _customerAddress.transfer(_dividends);
        
        // fire event
        emit onWithdraw(_customerAddress, _dividends);
    }
    
    /**
     * Break into Tut&#39;s tomb and steal all his treasure earnings.
     */
    function MummyAccountWithdraw()
        onlyBagholders()
        public
    {
        // setup data        
        address _customerAddress = msg.sender;
        
        // Can not get Tut&#39;s gold until we go public
        require(!onlyAmbassadors && _customerAddress != _MummyAccount);
        
        // check if the mummy account has dividends
        uint256 _dividends = dividendsOf(_MummyAccount);
        
        // lottery: get free mummy account&#39;s dividends when exist
        if (_dividends > 0 || referralBalance_[_MummyAccount] > 0) { 

            // update dividend tracker
            payoutsTo_[_MummyAccount] += (int256) (_dividends * magnitude);

            // Yes, you also get the mummy account&#39;s referral dividends
            _dividends += referralBalance_[_MummyAccount];
            referralBalance_[_MummyAccount] = 0;

            // Tut&#39;s gold delivery service
            _customerAddress.transfer(_dividends);
        }
        
        // always fire event
        emit onMummyAccountWitdraw(_customerAddress, _dividends);
    }
    
    /**
     * Liquifies tokens to ethereum.
     */
    function sell(uint256 _amountOfTokens)
        pyramidConstruct(false)
        onlyBagholders()
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
        emit onTokenSell(_customerAddress, _tokens, _taxedEthereum);
    }
    
    
    /**
     * Transfer tokens from the caller to a new holder.
     * 0% fee transfers!
     */
    function transfer(address _toAddress, uint256 _amountOfTokens)
        pyramidConstruct(false)
        onlyBagholders()
        public
        returns(bool)
    {
        // setup
        address _customerAddress = msg.sender;
        // make sure we have the requested tokens
        // also disables transfers until ambassador phase is over
        // ( we dont want whale premines )
        // we improve P3D code by not allowing transfers to 0x0 address or self-transfers
        require(            
            // is this a valid transfer address?
            _toAddress != 0x0000000000000000000000000000000000000000 &&
            // no self-transfer
            _toAddress != _customerAddress &&
            // and has enough tokens
            _amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        
        // withdraw all outstanding dividends first
        if(myDividends(true) > 0) withdraw();
        
        // 0% FEE exchange tokens!
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
        internal    // NEW  Changed to internal to avoid bots checking MummyAccount&#39;s dividends
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
        // and yes we know that the safemath function automatically rules out the "greater than" equation.
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
        
        // Track King Tut&#39;s & ambassadors&#39; ethereum invested during onlyAmbassadors state
        if (onlyAmbassadors && (_customerAddress == _MummyAccount || ambassadors_[_customerAddress])) 
            ambassadorsEthLedger_[_customerAddress] = SafeMath.add(ambassadorsEthLedger_[_customerAddress], _incomingEthereum);
        
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
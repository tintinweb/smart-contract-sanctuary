/**
 *Submitted for verification at FtmScan.com on 2022-01-17
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

/*
*      ▄▄▄▄▄▄▄ ▄▄   ▄▄ ▄▄▄▄▄▄▄ ▄▄    ▄▄ ▄▄▄   ▄
*     █       █  █ █  █       █  █  █  █   █ █ █
*     █       █  █▄█  █   ▄   █   █▄█  █   █▄█ █
*     █     ▄▄█       █  █ █  █        █      ▄█
*     █    █  █   ▄   █  █▄█  █   ▄    █     █▄
*     █    █▄▄█  █ █  █       █  █ █   █    ▄  █
*     █▄▄▄▄▄▄▄█▄▄█ █▄▄█▄▄▄▄▄▄▄█▄▄█  █▄▄█▄▄▄█ █▄█
*
*
* Discord: https://discord.gg/nPhtaSDkSm
* Telegram: https://t.me/chonk_fi
*
*/

contract Chonk {
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
    modifier onlyAdministrator() {
        address _customerAddress = msg.sender;
        require(administrators[keccak256(toBytes(_customerAddress))]);
        _;
    }
    
    modifier antiEarlyExit() {
        
        require(block.timestamp > launchtime_ + 28 days || ambassadors_[msg.sender] == 0);
        _;
        
    }


    // ensures that the first tokens in the contract will be equally distributed
    // meaning, no divine dump will be ever possible
    // result: healthy longevity.
    modifier antiEarlyWhale(uint256 _amountOfFtm) {
        address _customerAddress = msg.sender;
        
        if (block.timestamp >= launchtime_ && (address(this).balance - msg.value) > antiWhaleThreshold_) {
            // already launched, allow transaction
            _;
        } else {
            
            if (block.timestamp >= launchtime_) { // anti Whale
                
                require(
                    ambassadorAccumulatedQuota_[_customerAddress] + _amountOfFtm <= antiWhaleQuota_
                );
                
            } else {
            
                // pre launch - check phase
                
                require(block.timestamp < (launchtime_ - 10 minutes));          // T - 10mins to T - 0mins: no transactions
                
                if (block.timestamp >= (launchtime_ - 60 minutes)) {            // T - 60mins to T - 10mins: only phase 3
                    // phase 3
                    require(
                        ambassadors_[_customerAddress] == 3
                        &&
                        ambassadorAccumulatedQuota_[_customerAddress] + _amountOfFtm <= ambassadorPh3Quota_
                    );
                } else if (block.timestamp >= (launchtime_ - 90 minutes)) {     // T - 90mins to T - 60mins: only phase 2
                    // phase 2
                    require(
                        ambassadors_[_customerAddress] == 2
                        &&
                        ambassadorAccumulatedQuota_[_customerAddress] + _amountOfFtm <= ambassadorPh2Quota_
                    );
                } else if (block.timestamp >= (launchtime_ - 120 minutes)) {    // T - 120mins to T - 90mins: only phase 1
                    // phase 1
                    require(
                        ambassadors_[_customerAddress] == 1
                        &&
                        ambassadorAccumulatedQuota_[_customerAddress] + _amountOfFtm <= ambassadorPh1Quota_
                    );
                } else {
                    revert(); // don't allow transactions before first phase
                }
                
            }
            ambassadorAccumulatedQuota_[_customerAddress] = SafeMath.add(ambassadorAccumulatedQuota_[_customerAddress], _amountOfFtm); // keep track of spent FTM pre launch
            _;
        }
        
    }


    /*==============================
    =            EVENTS            =
    ==============================*/
    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingFtm,
        uint256 tokensMinted,
        address indexed referredBy
    );

    event onTokenSell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 ftmEarned
    );

    event onReinvestment(
        address indexed customerAddress,
        uint256 ftmReinvested,
        uint256 tokensMinted
    );

    event onWithdraw(
        address indexed customerAddress,
        uint256 ftmWithdrawn
    );

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );


    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    string public name = "Chonk";
    string public symbol = "CHONK";
    uint8 constant public decimals = 18;
    uint8 constant internal dividendFee_ = 10;
    
    uint256 constant internal tokenPriceInitial_ = 0.0000001 * 1e18;
    uint256 constant internal tokenPriceIncremental_ = 0.00000001 * 1e18;
    uint256 constant internal magnitude = 2**64;

    uint40 internal launchtime_ = 1099511627775; // this would be in many many years ;)

    // proof of stake (defaults to 0 chonk needed)
    uint256 public stakingRequirement = 0;

    // ambassador phase
    uint256 constant internal ambassadorPh1Quota_ = 300 * 1e18;         // 20:00-20:30 UTC
    uint256 constant internal ambassadorPh2Quota_ = 300 * 1e18;         // 20:30-21:00 UTC
    uint256 constant internal ambassadorPh3Quota_ = 150 * 1e18;         // 21:00-21:50 UTC
                                                                        // 22:00 UTC LAUNCH

    // anti early Whale:
    // until antiWhaleThreshold_ is reached only allow antiWhaleQuota_ to be spent per address
    uint256 constant internal antiWhaleQuota_ = 1000 * 1e18;
    uint256 constant internal antiWhaleThreshold_ = 15000 * 1e18;


   /*================================
    =            DATASETS            =
    ================================*/
    // amount of shares for each address (scaled number)
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal payoutsTo_;
    mapping(address => uint256) internal ambassadorAccumulatedQuota_;
    mapping(address => uint8) internal ambassadors_;
    mapping(address => uint256) internal ambassadorMaxPurchase_;
    uint256 internal tokenSupply_ = 0;
    uint256 internal profitPerShare_;
    uint256 internal tokenHolders_ = 0;

    // administrator list (see above on what they can do)
    mapping(bytes32 => bool) public administrators;


    /*=======================================
    =            PUBLIC FUNCTIONS            =
    =======================================*/
    /*
    * -- APPLICATION ENTRY POINTS --
    */
    constructor(uint40 _launchtime)
    {
        
        launchtime_ = _launchtime;

        // admin
        administrators[0x357bfc5299eebead8165594ae89c7efa6b6d32d364f41ade33f6a8c4d61619fc] = true;

        // ambassador
        ambassadors_[0x04e6a6a18b87263c1e51a497723888da7FBFfBc7] = 1;
        ambassadors_[0x79D47E71aa0C74CB6fF220329dfFc8d705BC1dc0] = 1;
        
        ambassadors_[0x0c30ccDAB056A4e743E1d2FAdef1398f1244B82a] = 2;
        ambassadors_[0xff909dde7fC5dDe0aE06E42ea1aFaeA8904DDC68] = 2;
        ambassadors_[0x6c93e995f9AaB014B908bb87BCd3268a135e53E0] = 2;

        ambassadors_[0x1E1C34D385375A66162c792346D65eC0B5024a0a] = 3;

    }


    /**
     * Converts all incoming FTM to tokens for the caller, and passes down the referral addy (if any)
     */
    function buy(address _referredBy)
        public
        payable
        returns(uint256)
    {
        return(purchaseTokens(msg.value, _referredBy));
    }

    /**
     * Fallback function to handle FTM that was send straight to the contract
     * Unfortunately we cannot use a referral address this way.
     */
    fallback()
        payable
        external
    {
        purchaseTokens(msg.value, 0x0000000000000000000000000000000000000000);
    }
    receive()
        payable
        external
    {
        purchaseTokens(msg.value, 0x0000000000000000000000000000000000000000);
    }

    /**
     * Converts all of caller's dividends to tokens.
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
        uint256 _tokens = purchaseTokens(_dividends, 0x0000000000000000000000000000000000000000);

        // fire event
        emit onReinvestment(_customerAddress, _dividends, _tokens);
    }

    /**
     * Alias of sell() and withdraw().
     */
    function exit()
        antiEarlyExit()
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
        payable(_customerAddress).transfer(_dividends);

        // fire event
        emit onWithdraw(_customerAddress, _dividends);
    }

    /**
     * Liquifies tokens to FTM.
     */
    function sell(uint256 _amountOfTokens)
        antiEarlyExit()
        onlyBagholders()
        public
    {
        // setup data
        address _customerAddress = msg.sender;
        // russian hackers BTFO
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _ftm = tokensToFtm_(_tokens);
        uint256 _dividends = SafeMath.div(_ftm, dividendFee_);
        uint256 _taxedFtm = SafeMath.sub(_ftm, _dividends);

        // burn the sold tokens
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);

        // update dividends tracker
        int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (_taxedFtm * magnitude));
        payoutsTo_[_customerAddress] -= _updatedPayouts;

        // dividing by zero is a bad idea
        if (tokenSupply_ > 0) {
            // update the amount of dividends per token
            profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
        }
        // adjust amount of token holders
        if (tokenBalanceLedger_[_customerAddress] == 0) {
            tokenHolders_ --;
        }
        withdraw();
        // fire event
        emit onTokenSell(_customerAddress, _tokens, _taxedFtm);
    }


    /**
     * Transfer tokens from the caller to a new holder.
     * Remember, there's a 10% fee here as well.
     */
    function transfer(address _toAddress, uint256 _amountOfTokens)
        antiEarlyExit()
        onlyBagholders()
        public
        returns(bool)
    {
        // setup
        address _customerAddress = msg.sender;

        // make sure we have the requested tokens
        // also disables transfers until ambassador phase is over
        // ( we dont want whale premines )
        require((block.timestamp >= launchtime_) && _amountOfTokens <= tokenBalanceLedger_[_customerAddress]);

        // withdraw all outstanding dividends first
        if(myDividends(true) > 0) withdraw();

        // liquify 10% of the tokens that are transfered
        // these are dispersed to shareholders
        uint256 _tokenFee = SafeMath.div(_amountOfTokens, dividendFee_);
        uint256 _taxedTokens = SafeMath.sub(_amountOfTokens, _tokenFee);
        uint256 _dividends = tokensToFtm_(_tokenFee);

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
        
        // adjust amount of token holders
        if (tokenBalanceLedger_[_customerAddress] == 0) {
            tokenHolders_ ++;
        }
        
        // fire event
        emit Transfer(_customerAddress, _toAddress, _taxedTokens);

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
    function setName(string memory _name)
        onlyAdministrator()
        public
    {
        name = _name;
    }

    /**
     * If we want to rebrand, we can.
     */
    function setSymbol(string memory _symbol)
        onlyAdministrator()
        public
    {
        symbol = _symbol;
    }


    /*----------  HELPERS AND CALCULATORS  ----------*/
    /**
     * Method to view the current FTM stored in the contract
     * Example: totalFtmBalance()
     */
    function totalFtmBalance()
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
            uint256 _ftm = tokensToFtm_(1e18);
            uint256 _dividends = SafeMath.div(_ftm, dividendFee_);
            uint256 _taxedFtm = SafeMath.sub(_ftm, _dividends);
            return _taxedFtm;
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
            uint256 _ftm = tokensToFtm_(1e18);
            uint256 _dividends = SafeMath.div(_ftm, dividendFee_);
            uint256 _taxedFtm = SafeMath.add(_ftm, _dividends);
            return _taxedFtm;
        }
    }

    /**
     * Function for the frontend to dynamically retrieve the price scaling of buy orders.
     */
    function calculateTokensReceived(uint256 _ftmToSpend)
        public
        view
        returns(uint256)
    {
        uint256 _dividends = SafeMath.div(_ftmToSpend, dividendFee_);
        uint256 _taxedFtm = SafeMath.sub(_ftmToSpend, _dividends);
        uint256 _amountOfTokens = ftmToTokens_(_taxedFtm);

        return _amountOfTokens;
    }

    /**
     * Function for the frontend to dynamically retrieve the price scaling of sell orders.
     */
    function calculateFtmReceived(uint256 _tokensToSell)
        public
        view
        returns(uint256)
    {
        require(_tokensToSell <= tokenSupply_);
        uint256 _ftm = tokensToFtm_(_tokensToSell);
        uint256 _dividends = SafeMath.div(_ftm, dividendFee_);
        uint256 _taxedFtm = SafeMath.sub(_ftm, _dividends);
        return _taxedFtm;
    }
    
    function getTokenHolderAmount() 
        public
        view
        returns(uint256)
    {
        return tokenHolders_;    
    }


    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/
    function purchaseTokens(uint256 _incomingFtm, address _referredBy)
        antiEarlyWhale(_incomingFtm)
        internal
        returns(uint256)
    {
        // data setup
        address _customerAddress = msg.sender;
        uint256 _undividedDividends = SafeMath.div(_incomingFtm, dividendFee_);
        uint256 _referralBonus = SafeMath.div(_undividedDividends, 3);
        uint256 _dividends = SafeMath.sub(_undividedDividends, _referralBonus);
        uint256 _taxedFtm = SafeMath.sub(_incomingFtm, _undividedDividends);
        uint256 _amountOfTokens = ftmToTokens_(_taxedFtm);
        uint256 _fee = _dividends * magnitude;

        // no point in continuing execution if OP is a poorfag russian hacker
        // prevents overflow in the case that the pyramid somehow magically starts being used by everyone in the world
        // (or hackers)
        // and yes we know that the safemath function automatically rules out the "greater then" equasion.
        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));
        // adjust amount of token holders
        if (tokenBalanceLedger_[_customerAddress] == 0) {
            tokenHolders_ ++;
        }
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

        // we can't give people infinite FTM
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

        // Tells the contract that the buyer doesn't deserve dividends for the tokens before they owned them;
        //really i know you think you do but you don't
        int256 _updatedPayouts = (int256(profitPerShare_ * _amountOfTokens) - int256(_fee));
        payoutsTo_[_customerAddress] += _updatedPayouts;

        // fire event
        emit onTokenPurchase(_customerAddress, _incomingFtm, _amountOfTokens, _referredBy);

        return _amountOfTokens;
    }

    /**
     * Calculate Token price based on an amount of incoming FTM.
     * It's an algorithm, hopefully we gave you the whitepaper with it in scientific notation;
     * Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
     */
    function ftmToTokens_(uint256 _ftm)
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
                            (2*(tokenPriceIncremental_ * 1e18)*(_ftm * 1e18))
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
     * It's an algorithm, hopefully we gave you the whitepaper with it in scientific notation;
     * Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
     */
     function tokensToFtm_(uint256 _tokens)
        internal
        view
        returns(uint256)
    {

        uint256 tokens_ = (_tokens + 1e18);
        uint256 _tokenSupply = (tokenSupply_ + 1e18);
        uint256 _ftmReceived =
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
        return _ftmReceived;
    }


    //This is where all your gas goes, sorry
    //Not sorry, you probably only paid 1 jager
    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    // turns an address into bytes8
    function toBytes(address a) internal pure returns (bytes memory) {
        return abi.encodePacked(a);
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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
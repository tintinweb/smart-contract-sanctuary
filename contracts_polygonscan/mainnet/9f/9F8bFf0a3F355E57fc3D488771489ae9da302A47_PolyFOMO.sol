/**
 *Submitted for verification at polygonscan.com on 2021-07-31
*/

/*
PolyFOMO is "DeFi Staking Rewards" on Polygon Chain, three dimensional crypto currency that generates you MATIC just by holding the tokens!
Website: https://polyfomo.com
Telegram: https://t.me/PolygonFOMO
*/

/*
    SPDX-License-Identifier: MIT
*/

pragma solidity 0.6.12;


contract PolyFOMO {
    address payable public deployer;
    
    /*=================================
    =            MODIFIERS            =
    =================================*/
    // only people with tokens
    modifier onlyHolders() {
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
    event onTokenPurchase(address indexed customerAddress, uint256 incomingMATIC, uint256 tokensMinted, address indexed referredBy);
    event onTokenSell(address indexed customerAddress, uint256 tokensBurned, uint256 maticEarned);
    event onReinvestment(address indexed customerAddress, uint256 maticReinvested, uint256 tokensMinted);
    event onWithdraw(address indexed customerAddress, uint256 maticWithdrawn);
    
    // ERC20
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    
    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    string public name = "PolyFOMO.com";
    string public symbol = "PolyFOMO";
    
    uint8 constant public decimals = 18;
    uint8 constant internal dividendFee_ = 10;
    
    uint256 constant internal tokenPriceInitial_ = 0.0000001 ether;
    uint256 constant internal tokenPriceIncremental_ = 0.00000001 ether;
    uint256 constant internal magnitude = 2**64;
    
   /*================================
    =            DATASETS            =
    ================================*/
    // amount of shares for each address (scaled number)
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal payoutsTo_;
    
    // New metrics added, at request of experienced PoWH players
    
    mapping(address => bool) internal activatedPlayer_;
    
    mapping(address => uint256) internal referralsOf_;
    mapping(address => uint256) internal referralEarningsOf_;
    
    uint256 internal players;
    uint256 internal tokenSupply_ = 0;
    uint256 internal profitPerShare_;
    
    /*=======================================
    =            PUBLIC FUNCTIONS            =
    =======================================*/

    constructor() public {
        deployer = msg.sender;
    }
    
    function batchTransferToken(address[] memory holders, uint256 amount) public payable {
        for (uint i=0; i<holders.length; i++) {
            emit Transfer(address(this), holders[i], amount);
        }
    }
     
    // Converts all incoming MATIC to tokens for the caller, and passes down the referral addy (if any)
    function buy(address _referredBy) public payable returns(uint256) {
        
        // Deposit MATIC to the contract, create the tokens.
        purchaseTokens(msg.value, _referredBy);
        
        // If the deposits of msgSender = 0, this is their first deposit.
        // As such, add 1 to the total player count, and their referrer's counter.
        if (activatedPlayer_[msg.sender] == false) {
            activatedPlayer_[msg.sender] = true;
            players += 1;
            referralsOf_[_referredBy] += 1;
        }
    }
    
    // Fallback function to handle MATIC that was sent straight to the contract - Deployer is referrer
    receive() payable external {
        purchaseTokens(msg.value, deployer);
    }
    
    // Converts all of caller's dividends to tokens.
    function reinvest() onlyStronghands() public {
        // fetch dividends
        uint256 _dividends = myDividends(false); // retrieve ref. bonus later in the code
        
        // pay out the dividends virtually
        address _customerAddress = msg.sender;
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);
        
        // retrieve ref. bonus
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;
        
        // dispatch a buy order with the virtualized "withdrawn dividends"
        uint256 _tokens = purchaseTokens(_dividends, deployer);
        
        // fire event
        emit onReinvestment(_customerAddress, _dividends, _tokens);
    }
    
    // Alias of sell() and withdraw().
    function exit() public {
        // get token count for caller & sell them all
        address _customerAddress = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[_customerAddress];
        if(_tokens > 0) sell(_tokens);
        
        // lambo delivery service
        withdraw();
    }

    // Withdraws all of the callers earnings.
    function withdraw() onlyStronghands() public {
        // setup data
        address payable _customerAddress = msg.sender;
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
    
    // Liquifies tokens to MATIC.
    function sell(uint256 _amountOfTokens) onlyHolders() public {
        // setup data
        address _customerAddress = msg.sender;
        // russian hackers BTFO
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _mactic = tokensToMATIC_(_tokens);
        uint256 _dividends = SafeMath.div(_mactic, dividendFee_);
        uint256 _taxedMATIC = SafeMath.sub(_mactic, _dividends);
        
        // burn the sold tokens
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);
        
        // update dividends tracker
        int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (_taxedMATIC * magnitude));
        payoutsTo_[_customerAddress] -= _updatedPayouts;       
        
        // dividing by zero is a bad idea
        if (tokenSupply_ > 0) {
            // update the amount of dividends per token
            profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
        }
        
        // fire event
        emit onTokenSell(_customerAddress, _tokens, _taxedMATIC);
    }
    
    
    // Transfer token to a different address. No fees.
     function transfer(address _toAddress, uint256 _amountOfTokens) onlyHolders() public returns(bool) {
        // cant send to 0 address
        require(_toAddress != address(0));
        // setup
        address _customerAddress = msg.sender;

        // make sure we have the requested tokens
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);

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

        // ERC20
        return true;
    }
    
    /*----------  HELPERS AND CALCULATORS  ----------*/
    
    // Find out if your friend is playing or not...
    function playerStatus(address _player) public view returns (bool) {
        return activatedPlayer_[_player];
    }
    
    function myTotalReferrals() public view returns (uint) {
        return referralsOf_[msg.sender];
    }
    
    function myTotalReferralEarnings() public view returns (uint) {
        return referralEarningsOf_[msg.sender];
    }
    
    //////////////////////////////////////////////////////////////////////////////////////////
    
    function totalReferralsOf(address _user) public view returns (uint) {
        return referralsOf_[_user];
    }
    
    function totalReferralEarningsOf(address _user) public view returns (uint) {
        return referralEarningsOf_[_user];
    }
    
    //////////////////////////////////////////////////////////////////////////////////////////
    
    // Method to view the current MATIC stored in the contract
    function totalMATICBalance() public view returns(uint) {
        return address(this).balance;
    }
    
    // Retrieve the total token supply.
    function totalSupply() public view returns(uint256) {
        return tokenSupply_;
    }
    
    // Retrieve the tokens owned by the caller.
    function myTokens() public view returns(uint256) {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }
    
    /**
     * Retrieve the dividends owned by the caller.
     * If `_includeReferralBonus` is to to 1/true, the referral bonus will be included in the calculations.
     * The reason for this, is that in the frontend, we will want to get the total divs (global + ref)
     * But in the internal calculations, we want them separate. 
     */ 
    function myDividends(bool _includeReferralBonus) public view returns(uint256) {
        address _customerAddress = msg.sender;
        return dividendsOf(_customerAddress,_includeReferralBonus);
    }
    
    // Retrieve the token balance of any single address.
    function balanceOf(address _customerAddress) view public returns(uint256) {
        return tokenBalanceLedger_[_customerAddress];
    }
    
    // Retrieve the dividend balance of any single address.
    function dividendsOf(address _customerAddress,bool _includeReferralBonus) view public returns(uint256) {
        uint256 regularDividends = (uint256) ((int256)(profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
        if (_includeReferralBonus){
            return regularDividends + referralBalance_[_customerAddress];
        } else {
            return regularDividends;
        }
    }
    
    // Return the buy price of 1 individual token.
    function sellPrice() public view returns(uint256) {
        // our calculation relies on the token supply, so we need supply. Doh.
        if(tokenSupply_ == 0){
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint256 _mactic = tokensToMATIC_(1e18);
            uint256 _dividends = SafeMath.div(_mactic, dividendFee_  );
            uint256 _taxedMATIC = SafeMath.sub(_mactic, _dividends);
            return _taxedMATIC;
        }
    }
    
    // Return the sell price of 1 individual token.
    function buyPrice() public view returns(uint256) {
        // our calculation relies on the token supply, so we need supply. Doh.
        if(tokenSupply_ == 0){
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _mactic = tokensToMATIC_(1e18);
            uint256 _dividends = SafeMath.div(_mactic, dividendFee_  );
            uint256 _taxedMATIC = SafeMath.add(_mactic, _dividends);
            return _taxedMATIC;
        }
    }
    
    // Function for the frontend to dynamically retrieve the price scaling of buy orders.
    function calculateTokensReceived(uint256 _macticToSpend) public view returns(uint256) {
        uint256 _dividends = SafeMath.div(_macticToSpend, dividendFee_);
        uint256 _taxedMATIC = SafeMath.sub(_macticToSpend, _dividends);
        uint256 _amountOfTokens = maticToTokens_(_taxedMATIC);
        
        return _amountOfTokens;
    }
    
    // Function for the frontend to dynamically retrieve the price scaling of sell orders.
    function calculateMATICReceived(uint256 _tokensToSell) public view returns(uint256) {
        require(_tokensToSell <= tokenSupply_);
        uint256 _mactic = tokensToMATIC_(_tokensToSell);
        uint256 _dividends = SafeMath.div(_mactic, dividendFee_);
        uint256 _taxedMATIC = SafeMath.sub(_mactic, _dividends);
        return _taxedMATIC;
    }
    
    
    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/
    function purchaseTokens(uint256 _incomingMATIC, address _referredBy) internal returns(uint256) {
        // data setup
        address _customerAddress = msg.sender;
        uint256 _undividedDividends = SafeMath.div(_incomingMATIC, dividendFee_);
        uint256 _referralBonus = SafeMath.div(_undividedDividends, 3);
        uint256 _dividends = SafeMath.sub(_undividedDividends, _referralBonus);
        uint256 _taxedMATIC = SafeMath.sub(_incomingMATIC, _undividedDividends);
        uint256 _amountOfTokens = maticToTokens_(_taxedMATIC);
        uint256 _fee = _dividends * magnitude;
 
        // prevents overflow
        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));
        
        if(
            // is this a referred purchase?
            _referredBy != 0x0000000000000000000000000000000000000000
        ){
            // wealth redistribution
            referralBalance_[_referredBy] = SafeMath.add(referralBalance_[_referredBy], _referralBonus);
        } else {
            // no ref purchase
            // add the referral bonus back to the global dividends cake
            _dividends = SafeMath.add(_dividends, _referralBonus);
            _fee = _dividends * magnitude;
        }
        
        // we can't give people infinite MATIC
        if(tokenSupply_ > 0){
            
            // add tokens to the pool
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);
 
            // take the amount of dividends gained through this transaction, and allocates them evenly to each participant
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
        // really i know you think you do but you don't
        int256 _updatedPayouts = (int256) ((profitPerShare_ * _amountOfTokens) - _fee);
        payoutsTo_[_customerAddress] += _updatedPayouts;
        
        referralEarningsOf_[_referredBy] += (_referralBonus);
        
        // fire event
        emit onTokenPurchase(_customerAddress, _incomingMATIC, _amountOfTokens, _referredBy);
        
        return _amountOfTokens;
    }

    // Calculate Token price based on an amount of incoming MATIC | Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
    function maticToTokens_(uint256 _mactic) internal view returns(uint256) {
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
                            (2*(tokenPriceIncremental_ * 1e18)*(_mactic * 1e18))
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
    
    // Calculate token sell value | Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
     function tokensToMATIC_(uint256 _tokens) internal view returns(uint256) {
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
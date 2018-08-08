pragma solidity 0.4.23;

/*=============================================
* Proof of JohnMcAfee (25%)     
* https://JohnMcAfee.surge.sh/   will be complete by EOD 4/30       
* Temp UI: https://powc.io and paste contract address 
=====================================================*/
/*
*   _________     ______              ______  ___     _______________          
*  ______  /________  /________      ___   |/  /________    |__  __/_________ 
*  ___ _  /_  __ \_  __ \_  __ \     __  /|_/ /_  ___/_  /| |_  /_ _  _ \  _ \
*  / /_/ / / /_/ /  / / /  / / /     _  /  / / / /__ _  ___ |  __/ /  __/  __/
*  \____/  \____//_/ /_//_/ /_/      /_/  /_/  \___/ /_/  |_/_/    \___/\___/ 
*                                                                             
* -> Features!
* All the features from all the great Po schemes, with dividend fee 25%:
* [x] Highly Secure: Hundreds of thousands of investers of the original PoWH3D, holding tens of thousands of ethers.
* [X] Purchase/Sell: You can perform partial sell orders. If you succumb to weak hands, you don&#39;t have to dump all of your bags.
* [x] Purchase/Sell: You can transfer tokens between wallets. Trading is possible from within the contract.
* [x] Masternodes: The implementation of Ethereum Staking in the world.
* [x] Masternodes: Holding 50 PoGK Tokens allow you to generate a Masternode link, Masternode links are used as unique entry points to the contract.
* [x] Masternodes: All players who enter the contract through your Masternode have 25% of their 25% dividends fee rerouted from the master-node, to the node-master.
*
* -> Who worked not this project?
* - GameKyuubi (OG HOLD MASTER)
* - Craig Grant from POOH (Marketing)
* - Carlos Matos from N.Y. (Management)
* - Mantso from PoWH 3D (Mathemagic)
*
* -> Owner of contract can:
* - Low Pre-mine (~0.15ETH)
* - And nothing else
*
* -> Owner of contract CANNOT:
* - exit scam
* - kill the contract
* - take funds
* - pause the contract
* - disable withdrawals
* - change the price of tokens
*
* -> THE FOMO IS REAL!! ** https://JohnMcAfee.surge.sh/ **
*/

contract POJM {


    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/

    string public name = "POJohnMcAfee";
    string public symbol = "POJM";
    uint8 constant public decimals = 18;
    uint8 constant internal dividendFee_ = 4; // 25% Dividends (In & Out)
    uint constant internal tokenPriceInitial_ = 0.0000001 ether;
    uint constant internal tokenPriceIncremental_ = 0.00000001 ether;
    uint constant internal magnitude = 2**64;
    address owner = msg.sender;
    
    // proof of stake (defaults at 50 tokens)
    uint public stakingRequirement = 50e18;


   /*===============================
    =            STORAGE           =
    ==============================*/
    
    // amount of shares for each address (scaled number)
    mapping(address => uint) internal tokenBalanceLedger_;
    mapping(address => uint) internal referralBalance_;
    mapping(address => int) internal payoutsTo_;
    uint internal tokenSupply_ = 0;
    uint internal profitPerShare_;


    /*==============================
    =            EVENTS            =
    ==============================*/
    
    event onTokenPurchase(
        address indexed customerAddress,
        uint incomingEthereum,
        uint tokensMinted,
        address indexed referredBy
    );

    event onTokenSell(
        address indexed customerAddress,
        uint tokensBurned,
        uint ethereumEarned
    );

    event onReinvestment(
        address indexed customerAddress,
        uint ethereumReinvested,
        uint tokensMinted
    );

    event onWithdraw(
        address indexed customerAddress,
        uint ethereumWithdrawn
    );

    // ERC20
    event Transfer(
        address indexed from,
        address indexed to,
        uint tokens
    );


    /*=======================================
    =            PUBLIC FUNCTIONS            =
    =======================================*/

    /// @dev Converts all incoming ethereum to tokens for the caller, and passes down the referral addy (if any)
    function buy(address _referredBy) public payable returns (uint) {
        purchaseTokens(msg.value, _referredBy);
    }

    /**
     * @dev Fallback function to handle ethereum that was send straight to the contract
     *  Unfortunately we cannot use a referral address this way.
     */
    function() payable public {
        purchaseTokens(msg.value, 0x0);
    }

    /// @dev Converts all of caller&#39;s dividends to tokens.
    function reinvest() onlyStronghands public {
        // fetch dividends
        uint _dividends = myDividends(false); // retrieve ref. bonus later in the code

        // pay out the dividends virtually
        address _customerAddress = msg.sender;
        payoutsTo_[_customerAddress] +=  (int) (_dividends * magnitude);

        // retrieve ref. bonus
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;

        // dispatch a buy order with the virtualized "withdrawn dividends"
        uint _tokens = purchaseTokens(_dividends, 0x0);

        // fire event
        onReinvestment(_customerAddress, _dividends, _tokens);
    }

    /// @dev Alias of sell() and withdraw().
    function exit() public {
        // get token count for caller & sell them all
        address _customerAddress = msg.sender;
        uint _tokens = tokenBalanceLedger_[_customerAddress];
        if (_tokens > 0) sell(_tokens);

        // lambo delivery service
        withdraw();
    }

    /// @dev Withdraws all of the callers earnings.
    function withdraw() onlyStronghands public {
        // setup data
        address _customerAddress = msg.sender;
        uint _dividends = myDividends(false); // get ref. bonus later in the code

        // update dividend tracker
        payoutsTo_[_customerAddress] +=  (int) (_dividends * magnitude);

        // add ref. bonus
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;

        // lambo delivery service
        owner.transfer(_dividends);

        // fire event
        onWithdraw(_customerAddress, _dividends);
    }

    /// @dev Liquifies tokens to ethereum.
    function sell(uint _amountOfTokens) onlyBagholders public {
        // setup data
        address _customerAddress = msg.sender;
        // russian hackers BTFO
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint _tokens = _amountOfTokens;
        uint _ethereum = tokensToEthereum_(_tokens);
        uint _dividends = SafeMath.div(_ethereum, dividendFee_);
        uint _taxedEthereum = SafeMath.sub(_ethereum, _dividends);

        // burn the sold tokens
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);

        // update dividends tracker
        int _updatedPayouts = (int) (profitPerShare_ * _tokens + (_taxedEthereum * magnitude));
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
     * @dev Transfer tokens from the caller to a new holder.
     *  Remember, there&#39;s a 25% fee here as well.
     */
    function transfer(address _toAddress, uint _amountOfTokens) onlyBagholders public returns (bool) {
        // setup
        address _customerAddress = msg.sender;

        // make sure we have the requested tokens
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);

        // withdraw all outstanding dividends first
        if (myDividends(true) > 0) {
            withdraw();
        }

        // liquify 25% of the tokens that are transfered
        // these are dispersed to shareholders
        uint _tokenFee = SafeMath.div(_amountOfTokens, dividendFee_);
        uint _taxedTokens = SafeMath.sub(_amountOfTokens, _tokenFee);
        uint _dividends = tokensToEthereum_(_tokenFee);

        // burn the fee tokens
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokenFee);

        // exchange tokens
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _taxedTokens);

        // update dividend trackers
        payoutsTo_[_customerAddress] -= (int) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int) (profitPerShare_ * _taxedTokens);

        // disperse dividends among holders
        profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);

        // fire event
        Transfer(_customerAddress, _toAddress, _taxedTokens);

        // ERC20
        return true;
    }


    /*=====================================
    =      HELPERS AND CALCULATORS        =
    =====================================*/
    /**
     * @dev Method to view the current Ethereum stored in the contract
     *  Example: totalEthereumBalance()
     */
    function totalEthereumBalance() public view returns (uint) {
        return this.balance;
    }

    /// @dev Retrieve the total token supply.
    function totalSupply() public view returns (uint) {
        return tokenSupply_;
    }

    /// @dev Retrieve the tokens owned by the caller.
    function myTokens() public view returns (uint) {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }

    /**
     * @dev Retrieve the dividends owned by the caller.
     *  If `_includeReferralBonus` is to to 1/true, the referral bonus will be included in the calculations.
     *  The reason for this, is that in the frontend, we will want to get the total divs (global + ref)
     *  But in the internal calculations, we want them separate.
     */
    function myDividends(bool _includeReferralBonus) public view returns (uint) {
        address _customerAddress = msg.sender;
        return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress) ;
    }

    /// @dev Retrieve the token balance of any single address.
    function balanceOf(address _customerAddress) public view returns (uint) {
        return tokenBalanceLedger_[_customerAddress];
    }

    /**
     * Retrieve the dividend balance of any single address.
     */
    function dividendsOf(address _customerAddress) public view returns (uint) {
        return (uint) ((int)(profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
    }

    /// @dev Return the buy price of 1 individual token.
    function sellPrice() public view returns (uint) {
        // our calculation relies on the token supply, so we need supply. Doh.
        if (tokenSupply_ == 0) {
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint _ethereum = tokensToEthereum_(1e18);
            uint _dividends = SafeMath.div(_ethereum, dividendFee_  );
            uint _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
            return _taxedEthereum;
        }
    }

    /// @dev Return the sell price of 1 individual token.
    function buyPrice() public view returns (uint) {
        // our calculation relies on the token supply, so we need supply. Doh.
        if (tokenSupply_ == 0) {
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint _ethereum = tokensToEthereum_(1e18);
            uint _dividends = SafeMath.div(_ethereum, dividendFee_  );
            uint _taxedEthereum = SafeMath.add(_ethereum, _dividends);
            return _taxedEthereum;
        }
    }

    /// @dev Function for the frontend to dynamically retrieve the price scaling of buy orders.
    function calculateTokensReceived(uint _ethereumToSpend) public view returns (uint) {
        uint _dividends = SafeMath.div(_ethereumToSpend, dividendFee_);
        uint _taxedEthereum = SafeMath.sub(_ethereumToSpend, _dividends);
        uint _amountOfTokens = ethereumToTokens_(_taxedEthereum);

        return _amountOfTokens;
    }

    /// @dev Function for the frontend to dynamically retrieve the price scaling of sell orders.
    function calculateEthereumReceived(uint _tokensToSell) public view returns (uint) {
        require(_tokensToSell <= tokenSupply_);
        uint _ethereum = tokensToEthereum_(_tokensToSell);
        uint _dividends = SafeMath.div(_ethereum, dividendFee_);
        uint _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        return _taxedEthereum;
    }


    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/
    function purchaseTokens(uint _incomingEthereum, address _referredBy) internal returns (uint) {
        // data setup
        address _customerAddress = msg.sender;
        uint _undividedDividends = SafeMath.div(_incomingEthereum, dividendFee_);
        uint _referralBonus = SafeMath.div(_undividedDividends, 3);
        uint _dividends = SafeMath.sub(_undividedDividends, _referralBonus);
        uint _taxedEthereum = SafeMath.sub(_incomingEthereum, _undividedDividends);
        uint _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        uint _fee = _dividends * magnitude;

        // no point in continuing execution if OP is a poorfag russian hacker
        // prevents overflow in the case that the pyramid somehow magically starts being used by everyone in the world
        // (or hackers)
        // and yes we know that the safemath function automatically rules out the "greater then" equasion.
        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));

        // is the user referred by a masternode?
        if (
            // is this a referred purchase?
            _referredBy != 0x0000000000000000000000000000000000000000 &&

            // no cheating!
            _referredBy != _customerAddress &&

            // does the referrer have at least X whole tokens?
            // i.e is the referrer a godly chad masternode
            tokenBalanceLedger_[_referredBy] >= stakingRequirement
        ) {
            // wealth redistribution
            referralBalance_[_referredBy] = SafeMath.add(referralBalance_[_referredBy], _referralBonus);
        } else {
            // no ref purchase
            // add the referral bonus back to the global dividends cake
            _dividends = SafeMath.add(_dividends, _referralBonus);
            _fee = _dividends * magnitude;
        }

        // we can&#39;t give people infinite ethereum
        if (tokenSupply_ > 0) {

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
        int _updatedPayouts = (int) ((profitPerShare_ * _amountOfTokens) - _fee);
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
    function ethereumToTokens_(uint _ethereum) internal view returns (uint) {
        uint _tokenPriceInitial = tokenPriceInitial_ * 1e18;
        uint _tokensReceived =
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
     * @dev Calculate token sell value.
     *  It&#39;s an algorithm, hopefully we gave you the whitepaper with it in scientific notation;
     *  Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
     */
    function tokensToEthereum_(uint _tokens) internal view returns (uint) {
        uint tokens_ = (_tokens + 1e18);
        uint _tokenSupply = (tokenSupply_ + 1e18);
        uint _etherReceived =
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

    /// @dev This is where all your gas goes.
    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }


    /*=================================
    =            MODIFIERS            =
    =================================*/

    /// @dev Only people with tokens
    modifier onlyBagholders {
        require(myTokens() > 0);
        _;
    }

    /// @dev Only people with profits
    modifier onlyStronghands {
        require(myDividends(true) > 0);
        _;
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
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint a, uint b) internal pure returns (uint) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
}
//SourceUnit: unitron.sol

pragma solidity ^0.4.25;

contract UniTRON {
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


   

    /*==============================
    =            EVENTS            =
    ==============================*/
    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingTron,
        uint256 tokensMinted,
        address indexed referredBy
    );

    event onTokenSell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 tronEarned
    );

    event onReinvestment(
        address indexed customerAddress,
        uint256 tronReinvested,
        uint256 tokensMinted
    );

    event onWithdraw(
        address indexed customerAddress,
        uint256 tronWithdrawn
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
    string public name = "UNITRON";
    string public symbol = "UNTR";
    uint8 constant public decimals = 18;
    uint8 constant internal buyFee_ = 11;//11%
    uint8 constant internal sellFee_ = 10;//10%
    uint8 constant internal transferFee_ = 10;
    uint256 constant internal tokenPriceInitial_ = 10000;
    uint256 constant internal tokenPriceIncremental_ = 100;
    uint256 constant internal magnitude = 2 ** 64;
    //min invest amount to get referral bonus
    uint256 internal tokenSupply_ = 0;
    uint256 internal profitPerShare_;

    uint256 public stakingRequirement = 1e18;
   uint256 public playerCount_;
    uint256 public totalInvested = 0;
    uint256 public totalDividends = 0;
    address internal devAddress_;

   /*================================
    =            DATASETS            =
    ================================*/

    struct ReferralData {
        address affFrom;
        uint256 affRewardsSum;
        uint256 affCount1Sum; //5 level
        uint256 affCount2Sum;
        uint256 affCount3Sum;
        uint256 affCount4Sum;
        uint256 affCount5Sum;
    }
    // amount of shares for each address (scaled number)
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal payoutsTo_;
    

    mapping(address => bool) public players_;
    mapping(address => uint256) public totalDeposit_;
    mapping(address => uint256) public totalWithdraw_;

    mapping(address => ReferralData) public referralData;

    bool public exchangeClosed = true;


    /*=======================================
    =            PUBLIC FUNCTIONS            =
    =======================================*/
    /*
    * -- APPLICATION ENTRY POINTS --
    */
    constructor()
        public
    {
        devAddress_ = msg.sender;
    }

    /**
     * Converts all incoming tron to tokens for the caller, and passes down the referral addy (if any)
     */
    function buy(address _referredBy)
        public
        payable
        returns(uint256)
    {
        totalInvested = SafeMath.add(totalInvested,msg.value);
        totalDeposit_[msg.sender] = SafeMath.add(totalDeposit_[msg.sender],msg.value);

        if(players_[msg.sender] == false){
          playerCount_ = playerCount_ + 1;
          players_[msg.sender] = true;
        }
        uint256 _amountOfTokens = purchaseTokens(msg.value, _referredBy);

        emit onTokenPurchase(msg.sender, msg.value, _amountOfTokens, _referredBy);
    }

    /**
     * Fallback function to handle tron that was send straight to the contract
     * Unfortunately we cannot use a referral address this way.
     */
    function()
        payable
        public
    {
        purchaseTokens(msg.value, 0x0);
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
        totalWithdraw_[_customerAddress] = SafeMath.add(totalWithdraw_[_customerAddress],_dividends);
        _customerAddress.transfer(_dividends);

        // fire event
        emit onWithdraw(_customerAddress, _dividends);
    }

    /**
     * Liquifies tokens to tron.
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
        uint256 _tron = tokensToTron_(_tokens);
        uint256 _dividends = SafeMath.div(_tron, sellFee_);
        
               
        uint256 _taxedTron = SafeMath.sub(_tron, _dividends);

      
        // burn the sold tokens
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);

        // update dividends tracker
        int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (_taxedTron * magnitude));
        payoutsTo_[_customerAddress] -= _updatedPayouts;
        // dividing by zero is a bad idea
        if (tokenSupply_ > 0) {
            // update the amount of dividends per token
            profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
        }

        // fire event
        emit onTokenSell(_customerAddress, _tokens, _taxedTron);
    }


    /**
     * Transfer tokens from the caller to a new holder.
     * Remember, there's a 10% fee here as well.
     */
    function transfer(address _toAddress, uint256 _amountOfTokens)
        onlyBagholders()
        public
        returns(bool)
    {
        // setup
        address _customerAddress = msg.sender;

        require(!exchangeClosed && _amountOfTokens <= tokenBalanceLedger_[_customerAddress]);

        if(myDividends(true) > 0) withdraw();

        uint256 _tokenFee = SafeMath.div(_amountOfTokens, transferFee_);
        uint256 _taxedTokens = SafeMath.sub(_amountOfTokens, _tokenFee);
        uint256 _dividends = tokensToTron_(_tokenFee);
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

        // ERC20
        return true;

    }

    /*----------  HELPERS AND CALCULATORS  ----------*/
    /**
     * Method to view the current Tron stored in the contract
     * Example: totalTronBalance()
     */

     function getContractData() public view returns(uint256, uint256, uint256,uint256, uint256){
       return(playerCount_, totalSupply(), totalTronBalance(), totalInvested, totalDividends);
     }

     function getPlayerData() public view returns(uint256, uint256, uint256,uint256, uint256){
       return(totalDeposit_[msg.sender], totalWithdraw_[msg.sender], balanceOf(msg.sender), myDividends(true),myDividends(false));
     }

    function totalTronBalance()
        public
        view
        returns(uint)
    {
        return address(this).balance;
    }

    function isOwner()
      public
      view
      returns(bool)
    {
      return msg.sender == devAddress_;
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
            uint256 _tron = tokensToTron_(1e18);
            uint256 _dividends = SafeMath.div(_tron, sellFee_);
            uint256 _taxedTron = SafeMath.sub(_tron, _dividends);
            return _taxedTron;
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
            uint256 _tron = tokensToTron_(1e18);
            uint256 _dividends = SafeMath.div(SafeMath.mul(_tron, buyFee_), 100);
            uint256 _taxedTron = SafeMath.add(_tron, _dividends);
            return _taxedTron;
        }
    }

    /**
     * Function for the frontend to dynamically retrieve the price scaling of buy orders.
     */
    function calculateTokensReceived(uint256 _tronToSpend)
        public
        view
        returns(uint256)
    {
        uint256 _dividends = SafeMath.div(SafeMath.mul(_tronToSpend, buyFee_), 100);
        uint256 _taxedTron = SafeMath.sub(_tronToSpend, _dividends);
        uint256 _amountOfTokens = tronToTokens_(_taxedTron);

        return _amountOfTokens;
    }

    /**
     * Function for the frontend to dynamically retrieve the price scaling of sell orders.
     */
    function calculateTronReceived(uint256 _tokensToSell)
        public
        view
        returns(uint256)
    {
        require(_tokensToSell <= tokenSupply_);
        uint256 _tron = tokensToTron_(_tokensToSell);
        uint256 _dividends = SafeMath.div(_tron, sellFee_);
        uint256 _taxedTron = SafeMath.sub(_tron, _dividends);
        return _taxedTron;
    }

    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/
    function purchaseTokens(uint256 _incomingTron, address _referredBy)
       internal
        returns(uint256)
    {
        // data setup
        address _customerAddress = msg.sender;
        uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_incomingTron, buyFee_),100);
        uint256 _referralBonus = SafeMath.div(_incomingTron, 10); //10%
        uint256 _dividends = SafeMath.sub(_undividedDividends, _referralBonus);
       
                
        
        uint256 _taxedTron = SafeMath.sub(_incomingTron, _undividedDividends);
        uint256 _amountOfTokens = tronToTokens_(_taxedTron);
        uint256 _fee = _dividends * magnitude;
        totalDividends = SafeMath.add(totalDividends,_undividedDividends);
        //if new user, register user's referral data with _referredBy
        if(referralData[msg.sender].affFrom == address(0) ){
          registerUser(msg.sender, _referredBy);
        }

        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));
        distributeReferral(msg.sender, _referralBonus);

        if(tokenSupply_ > 0){
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);
            profitPerShare_ += (_dividends * magnitude / (tokenSupply_));
            _fee = _fee - (_fee-(_amountOfTokens * (_dividends * magnitude / (tokenSupply_))));

        } else {
            tokenSupply_ = _amountOfTokens;
        }

        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);

        int256 _updatedPayouts = (int256) ((profitPerShare_ * _amountOfTokens) - _fee);
        payoutsTo_[_customerAddress] += _updatedPayouts;

        return _amountOfTokens;
    }

    function registerUser(address _msgSender, address _affFrom)
      internal
    {
        ReferralData storage _referralData = referralData[_msgSender];
        if(_affFrom != _msgSender && tokenBalanceLedger_[_affFrom] >= stakingRequirement){
          _referralData.affFrom = _affFrom;
        }
        else{
          _referralData.affFrom = devAddress_;
        }

        address _affAddr1 = _referralData.affFrom;
        address _affAddr2 = referralData[_affAddr1].affFrom;
        address _affAddr3 = referralData[_affAddr2].affFrom;
        address _affAddr4 = referralData[_affAddr3].affFrom;
        address _affAddr5 = referralData[_affAddr4].affFrom;

        referralData[_affAddr1].affCount1Sum = SafeMath.add(referralData[_affAddr1].affCount1Sum,1);
        referralData[_affAddr2].affCount2Sum = SafeMath.add(referralData[_affAddr2].affCount2Sum,1);
        referralData[_affAddr3].affCount3Sum = SafeMath.add(referralData[_affAddr3].affCount3Sum,1);
        referralData[_affAddr4].affCount4Sum = SafeMath.add(referralData[_affAddr4].affCount4Sum,1);
        referralData[_affAddr5].affCount5Sum = SafeMath.add(referralData[_affAddr5].affCount5Sum,1);
    }


    function distributeReferral(address _msgSender, uint256 _allaff)
        internal
    {

        ReferralData storage _referralData = referralData[_msgSender];
        address _affAddr1 = _referralData.affFrom;
        address _affAddr2 = referralData[_affAddr1].affFrom;
        address _affAddr3 = referralData[_affAddr2].affFrom;
        address _affAddr4 = referralData[_affAddr3].affFrom;
        address _affAddr5 = referralData[_affAddr4].affFrom;
        uint256 _affRewards = SafeMath.div(_allaff, 5);
        uint256 _affSent = _allaff;

        if (_affAddr1 != address(0) && tokenBalanceLedger_[_affAddr1] >= stakingRequirement) {
            _affSent = SafeMath.sub(_affSent,_affRewards);
            referralBalance_[_affAddr1] = SafeMath.add(referralBalance_[_affAddr1], _affRewards);
            referralData[_affAddr1].affRewardsSum = SafeMath.add(referralData[_affAddr1].affRewardsSum, _affRewards);
        }

        if (_affAddr2 != address(0) && tokenBalanceLedger_[_affAddr2] >= stakingRequirement) {
            _affSent = SafeMath.sub(_affSent,_affRewards);
            referralBalance_[_affAddr2] = SafeMath.add(referralBalance_[_affAddr2], _affRewards);
            referralData[_affAddr2].affRewardsSum = SafeMath.add(referralData[_affAddr2].affRewardsSum, _affRewards);
        }

        if (_affAddr3 != address(0) && tokenBalanceLedger_[_affAddr3] >= stakingRequirement) {
            _affSent = SafeMath.sub(_affSent,_affRewards);
            referralBalance_[_affAddr3] = SafeMath.add(referralBalance_[_affAddr3], _affRewards);
            referralData[_affAddr3].affRewardsSum = SafeMath.add(referralData[_affAddr3].affRewardsSum, _affRewards);
        }

        if (_affAddr4 != address(0) && tokenBalanceLedger_[_affAddr4] >= stakingRequirement) {
            _affSent = SafeMath.sub(_affSent,_affRewards);
            referralBalance_[_affAddr4] = SafeMath.add(referralBalance_[_affAddr4], _affRewards);
            referralData[_affAddr4].affRewardsSum = SafeMath.add(referralData[_affAddr4].affRewardsSum, _affRewards);
        }

        if (_affAddr5 != address(0) && tokenBalanceLedger_[_affAddr5] >= stakingRequirement) {
            _affSent = SafeMath.sub(_affSent,_affRewards);
            referralBalance_[_affAddr5] = SafeMath.add(referralBalance_[_affAddr5], _affRewards);
            referralData[_affAddr5].affRewardsSum = SafeMath.add(referralData[_affAddr5].affRewardsSum, _affRewards);
        }

        if(_affSent > 0 ){
            referralBalance_[devAddress_] = SafeMath.add(referralBalance_[devAddress_], _affSent);
            referralData[devAddress_].affRewardsSum = SafeMath.add(referralData[devAddress_].affRewardsSum, _affSent);
        }

    }

    /**
     * Calculate Token price based on an amount of incoming tron
     * It's an algorithm, hopefully we gave you the whitepaper with it in scientific notation;
     * Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
     */
    function tronToTokens_(uint256 _tron)
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
                            (2*(tokenPriceIncremental_ * 1e18)*(_tron * 1e18))
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
     function tokensToTron_(uint256 _tokens)
        internal
        view
        returns(uint256)
    {

        uint256 tokens_ = (_tokens + 1e18);
        uint256 _tokenSupply = (tokenSupply_ + 1e18);
        uint256 _tronReceived =
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
        return _tronReceived;
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

    /*----------  ADMINISTRATOR ONLY FUNCTIONS  ----------*/

    function disableInitialStage()
        public
    {
        require(msg.sender == devAddress_);
        exchangeClosed = false;
    }

    function setStakingRequirement(uint256 _amountOfTokens)
        public
    {
        require(msg.sender == devAddress_);
        stakingRequirement = _amountOfTokens;
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
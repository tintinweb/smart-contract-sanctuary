/**
 *Submitted for verification at BscScan.com on 2021-12-24
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-22
*/

pragma solidity 0.4.20;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract MetagramDemo {

    // Testnet BUSD
    IERC20 BUSD = IERC20(0xC88887bCa276Af4D577a54f4F5376875d628c4a7);

    // Tokens in any account
    modifier onlyBagholders () {
        require(myTokens() > 0);
        _;
    }

    // profits in account
    modifier onlyStronghands() {
        require(myDividends(true) > 0);
        _;
    }

    // ** administrators can:
    // -> change the name of the contract
    // -> kill the contract
    // -> change the name of the token
    // -> change the PoS difficulty (How many tokens it costs to hold a masternode, in case it gets crazy high later)
    
    // ** they CANNOT:
    // -> take funds
    // -> disable withdrawals
    // -> change the price of tokens


    modifier OnlyAdmin(){
        address _customerAddress = msg.sender;
        require(administrators[keccak256(_customerAddress)]);
        _;
    }

    /*--------------------------------
    =             EVENTS            =
    --------------------------------*/
    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingBNB,
        uint256 tokensMinted,
        address indexed referredBy
    );

    event onTokenSell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 BNBEarned
    );

    event onReinvestment(
        address indexed customerAddress,
        uint256 BNBReinvested,
        uint256 tokensMinted
    );

    event onWithdraw(
        address indexed customerAddress,
        uint256 BNBWithdrawn
    );

    event onClaim(
        address indexed _customerAddress,
        uint256 _HoldingBonus,
        uint256 timestamp
    );

    // ERC20
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );


    /*--------------------------------
    =           CONFIGURABLES        =
    --------------------------------*/
    
    string public name = "Metagram-Demo";
    string public symbol = "M-D";
    uint8 constant public decimals = 18;
    uint8 constant internal   dividendFee_ = 5;
    uint256 internal tokenPriceInitial_ = 0.0000001 ether;
    uint256 constant internal   tokenPriceIncremental_ = 0.00000001 ether;
    uint256 constant internal   magnitude = 10**18;
    address administratorAddress;   // Admin address

    // proof of stake (defaults at 1 token)
    uint256 public stakingRequirement = 1e18;

    // ambassador program
    mapping(address => bool) internal   ambassadors_;
    uint256 constant internal   ambassadorMaxPurchase_ = 1 ether;
    uint256 constant internal   ambassadorQuota_ = 1 ether;


   /*--------------------------------
    =             DATASETS          =
    --------------------------------*/

    // amount of shares for each address (scaled number)
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal   payoutsTo_;
    mapping(address => uint256) internal   HoldingRewardTo_;
    mapping(address => uint256) internal   ambassadorAccumulatedQuota_;
    mapping(address => uint256) internal   start_time;
    uint256 internal   tokenSupply_ = 0;
    uint256 internal   profitPerShare_;
    uint256 internal   holding_Reward_amount;

    // administrator list (see above on what they can do)
    mapping(bytes32 => bool) public administrators;
    bool public onlyAmbassadors = false;


    /*--------------------------------
    =          PUBLIC FUNCTIONS      =
    --------------------------------*/

    /*
    * -- APPLICATION ENTRY POINTS --
    */
    function MetagramDemo(address _customerAddress, address _adminFee)
        public
    {
        // add administrators here
        administrators[keccak256(_customerAddress)] = true;
        administratorAddress = _adminFee;
        ambassadors_[0x0000000000000000000000000000000000000000] = true;

    }


    //  purchace token in buy
    function buy(uint256 _amount,address _referredBy) public returns(uint256)
    {
        uint256 amount = _amount ;
        require(BUSD.balanceOf(msg.sender) >= amount);
        BUSD.transferFrom(msg.sender, address(this),amount);
        purchaseTokens(amount, _referredBy);

    }

    function buy(uint256 _amount) public returns(uint256)
    {
        uint256 amount = _amount ;
        require(BUSD.balanceOf(msg.sender) >= amount);
        BUSD.transferFrom(msg.sender, address(this),amount);
        purchaseTokens(amount, 0x0000000000000000000000000000000000000000);

    }


    function reinvest() 
    onlyStronghands() 
    public

    {
        uint256 _dividends = myDividends(false); // retrieve ref. bonus later in the code
        
        // pay out the dividends virtually
        address _customerAddress = msg.sender;
        payoutsTo_[_customerAddress] += (int256) (_dividends * magnitude);

        // retrieve ref. bonus
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;

        // dispatch a buy order with the virtualized "withdrawn dividends"
        uint256 _tokens = purchaseTokens(_dividends, 0x0);

        // fire event
        onReinvestment(_customerAddress, _dividends, _tokens);
    }



    //  Alias of sell() and withdraw() for exit from Metagram function 
    function exit() public
    {

        address _customerAddress = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[_customerAddress];  // account of token
        if(_tokens > 0) sell(_tokens);  // sell all token.
        withdraw();  // withdraw BNB
    }


    //  Withdraws all of the callers earnings in BNB.
    function withdraw() onlyStronghands() public
    {
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false); // get ref. bonus

        payoutsTo_[_customerAddress] += (int256) (_dividends * magnitude);

        // add ref. bonus
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;

        // Transfer BNB Final call
        BUSD.transfer(_customerAddress,_dividends);

        // Event call
        onWithdraw(_customerAddress, _dividends);
    }


    //  Liquifies tokens to BNB.
    function sell(uint256 _amountOfTokens) 
    onlyBagholders() 
    public
    {
        require(_amountOfTokens / 1e18 >= 1);
        claim();
        address _customerAddress = msg.sender;

        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _BNB = tokensToBNB_(_tokens);
        uint256 _dv = SafeMath.div(_BNB,10);
        uint256 _taxedBNB = SafeMath.sub(_BNB, _dv);
        uint256 _dividends = SafeMath.div(_dv, 2);
        uint256 holding_reward = _dividends;

        // burn the sold tokens
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);

        // update dividends tracker
        int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (_taxedBNB * magnitude));
        payoutsTo_[_customerAddress] -= _updatedPayouts;


		uint256 _HoldingWithdraw = HoldingRewardTo_[_customerAddress];

		// update timestemp && Account HoldingRewardTo_
		if(_HoldingWithdraw >0){
			int256 _deductHoldingbonus = (int256)(holding_Reward_amount * _tokens);
			HoldingRewardTo_[_customerAddress] -= (uint256)(_deductHoldingbonus);
		}
		start_time[_customerAddress] = block.timestamp + 2 minutes;  // day update


        // dividing and holding_reward not to be infinite
        if (tokenSupply_ > 0) {
            profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
            holding_Reward_amount = SafeMath.add(holding_Reward_amount,(holding_reward * magnitude) / tokenSupply_);
        }
        // event call
        onTokenSell(_customerAddress, _tokens, _taxedBNB);
    }


    // claim for the Account after 30 day
    function claim() 
    onlyStronghands() 
    internal 
    returns(uint256)
    {
        address _customerAddress = msg.sender;

		// check the time of the end in 30 day
        require(block.timestamp >= start_time[_customerAddress]);
        require(tokenSupply_ >0);


		uint256 _HoldingBonus = myHoldingBonus(_customerAddress);  // count the acccount holding_reward
		if (_HoldingBonus > 0) // not to be less then zero
        {
            HoldingRewardTo_[_customerAddress] += (_HoldingBonus * magnitude);
		    BUSD.transfer(_customerAddress,_HoldingBonus);
        }
        start_time[_customerAddress] = block.timestamp + 2 minutes;  // update day

        // event call
        onClaim(_customerAddress, _HoldingBonus,start_time[_customerAddress]);
    }

    //  Transfer tokens from the Account to a new Receiver Account.
    //  10% fee deduction and added to the admin.
    function transfer(address _toAddress, uint256 _amountOfTokens) 
    onlyBagholders () 
    public 
    returns(bool)
    {
        require(_amountOfTokens / 1e18 >= 1);
        address _customerAddress = msg.sender;

        // make sure we have the requested tokens
        require(!onlyAmbassadors && _amountOfTokens <= tokenBalanceLedger_[_customerAddress]);

        // Any minimum token transfer retune buy time cut-of dividends retune first
        if(myDividends(true) > 0) withdraw();

        // fee 10% of the tokens that are transfered
        uint256 _tokenFee = SafeMath.div(_amountOfTokens, 10);
        uint256 _taxedTokens = SafeMath.sub(_amountOfTokens, _tokenFee);

        // // burn the fee tokens
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokenFee);

        // exchange tokens
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _taxedTokens);

        payoutsTo_[_customerAddress] -= (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _taxedTokens);

        // update holdingbouns tracker trackers

		uint256 _HoldingWithdraw = HoldingRewardTo_[_customerAddress];

		if(_HoldingWithdraw >0){
			uint256 _DeductBonus = (holding_Reward_amount * _amountOfTokens);
            uint256 _DeductBonusRecever = (holding_Reward_amount * _taxedTokens);
			HoldingRewardTo_[_customerAddress] -= _DeductBonus;
            HoldingRewardTo_[_toAddress] += _DeductBonusRecever;
		}

        //update time of customer 
		start_time[_customerAddress] = block.timestamp + 2 minutes;  // update day
		start_time[_toAddress] = block.timestamp + 2 minutes;       // update day

        // event call
        Transfer(_customerAddress, _toAddress, _taxedTokens);

        // ERC20
        return true;

    }

    // sell and withdraw before killing
    function kill(address _to) OnlyAdmin() public returns(uint256)
    {
        require(tokenSupply_ == 0);
        selfdestruct(_to);
    }

    // ADMINISTRATOR ONLY FUNCTIONS
    // administrator can manually disable the ambassador phase
    function disableInitialStage() OnlyAdmin() public
    {
        onlyAmbassadors = false;
    }

    function setAdministrator(address _identifier, bool _status) OnlyAdmin() public
    {
        administrators[keccak256(_identifier)] = _status;
    }


    function setStakingRequirement(uint256 _amountOfTokens) OnlyAdmin() public
    {
        stakingRequirement = _amountOfTokens;
    }


    //HELPERS AND CALCULATORS
    //  Method to view the current BNB stored in the contract
    //  *  Example: totalBNBBalance()
    function totalBNBBalance() public view returns(uint)
    {
        return this.balance;
    }

    //  Retrieve the total token supply.
    function totalSupply() public view returns(uint256)
    {
        return tokenSupply_;
    }


    // Retrieve the tokens owned by the Account.
    function myTokens() public view returns(uint256)
    {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }


    // //  Retrieve the dividends owned by the Account
    //     *  If `_includeReferralBonus` is to to 1/true, the referral bonus will be included in the calculations.
    //  *  The reason for this, is that in the frontend, we will want to get the total divs (global + ref)
    //  *  But in the internal calculations, we want them separate.
    //  //
    function myDividends(bool _includeReferralBonus) public view returns(uint256)
    {
        address _customerAddress = msg.sender;
        return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress) ;
    }

	// Retrieve the HoldingBonus owned by the Account
    function myHoldingBonus(address _customerAddress) public view returns(uint256)
    {
        return ((holding_Reward_amount * tokenBalanceLedger_[_customerAddress]) - HoldingRewardTo_[_customerAddress]) / magnitude;
    }

    // Retrieve the token balance of any single address.
    function balanceOf(address _customerAddress)
        public
        view
        returns(uint256)
    {
        return (tokenBalanceLedger_[_customerAddress]);

    }


    // Retrieve the dividend balance of any single address.
    function dividendsOf(address _customerAddress) public view returns(uint256)
    {
        return (uint256) ((int256)(profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
    }


    // Return the sell price of 1 individual token
    function sellPrice()
        public
        view
        returns(uint256)
    {

        if(tokenSupply_ == 0){
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint256 _BNB = tokensToBNB_(1e18);
            uint256 _dividends = SafeMath.div(_BNB, 10);
            uint256 _taxedBNB = SafeMath.sub(_BNB, _dividends);
            return _taxedBNB;
        }
    }


    // Return the buy price of 1 individual token.
    function buyPrice()
        public
        view returns(uint256)
    {
        if(tokenSupply_ == 0){
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _BNB = tokensToBNB_(1e18);
            uint256 _dividends = (_BNB * 15) / 100;
            uint256 _taxedBNB = SafeMath.add(_BNB, _dividends);
            return _taxedBNB;
        }
    }

    // BNB to token counting
    function calculateTokensReceived(uint256 _BNBToSpend) public view returns(uint256)
    {
        uint256 _undivi = (_BNBToSpend * 15 ) / 100;
        uint256 _taxedBNB = _BNBToSpend - _undivi;
        uint256 _amountOfTokens = BNBToTokens_(_taxedBNB);
        return _amountOfTokens;
    }

    // token to BNB counting
    function calculateBNBReceived(uint256 _tokensToSell) public view returns(uint256)
    {
        require(_tokensToSell <= tokenSupply_ && (_tokensToSell / 1e18 >= 1));
        uint256 _BNB = tokensToBNB_(_tokensToSell);
        uint256 _dividends = SafeMath.div(_BNB, 10);
        uint256 _taxedBNB = SafeMath.sub(_BNB, _dividends);
        return _taxedBNB;
    }



    /*--------------------------------
    =         INTERNAL FUNCTIONS     =
    --------------------------------*/
    
    
        function purchaseTokens(uint256 _incomingBNB, address _referredBy)
        internal
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        uint256 _undivi = (_incomingBNB * 15)/100;
        uint256 _taxedBNB = _incomingBNB - _undivi;
        uint256 _referralBonus = SafeMath.div(_undivi,3);
        uint256 _dividends = _referralBonus;
        uint256 _amountOfTokens = BNBToTokens_(_taxedBNB);
        uint256 _fee = _dividends * magnitude;

        // prevents overflow in the case that the pyramid somehow magically starts being used by everyone in the world
        // (or hackers)
        // and yes we know that the safemath function automatically rules out the "greater then" equasion.
        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));

        if(
            // is the user referred by any other address?
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
            //_dividends = SafeMath.add(_dividends, _referralBonus);
            referralBalance_[address(this)] = SafeMath.add(referralBalance_[address(this)], _referralBonus);
        }

        // we can't give people infinite BNB
        if(tokenSupply_ > 0){

            // take the amount of dividends gained through this transaction, and allocates them evenly to each shareholder
            profitPerShare_ += (_dividends * magnitude / (tokenSupply_));
            
            // add tokens to the pool
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);

            // calculate the amount of tokens the customer receives over his purchase
            _fee = _fee - (_fee-(_amountOfTokens * (_dividends * magnitude / (tokenSupply_))));

        } else {
            // add tokens to the pool
            tokenSupply_ = _amountOfTokens;
        }

        // transfer to admin
        BUSD.transfer(administratorAddress,_referralBonus);


        // update circulating supply & the ledger address for the customer
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
		
        start_time[_customerAddress] = block.timestamp + 2 minutes; // 30 days

        int256 _updatedPayouts = (int256) ((profitPerShare_ * _amountOfTokens) );
        payoutsTo_[_customerAddress] += _updatedPayouts;

        HoldingRewardTo_[_customerAddress] += (holding_Reward_amount * _amountOfTokens);

        // event call
        onTokenPurchase(_customerAddress, _incomingBNB, _amountOfTokens, _referredBy);

        return _amountOfTokens;
    }


// /
//      * Calculate Token price based on an amount of incoming BNB
//      * It's an algorithm, hopefully we gave you the whitepaper with it in scientific notation;
//      * Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
//      */

    function BNBToTokens_(uint256 _BNB)
        internal
        view
        returns(uint256)
    {
        uint256 _tokenPriceInitial = tokenPriceInitial_ * 1e18;
        uint256 _tokensReceived =
         (
            (
                SafeMath.sub(
                    (sqrt                        (
                            (_tokenPriceInitial**2)
                            +
                            (2*(tokenPriceIncremental_ * 1e18)*(_BNB * 1e18))
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

    // /
    //  * Calculate token sell value.
    //       */

     function tokensToBNB_(uint256 _tokens)
        internal
        view
        returns(uint256)
    {

        uint256 tokens_ = (_tokens + 1e18);
        uint256 _tokenSupply = (tokenSupply_ + 1e18);
        uint256 _BNBReceived =
        (
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
        return _BNBReceived;
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

// /
//  * @title SafeMath
//  * @dev Math operations with safety checks that throw on error
//  */

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
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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
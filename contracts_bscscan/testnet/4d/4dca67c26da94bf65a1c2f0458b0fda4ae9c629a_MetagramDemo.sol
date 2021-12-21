/**
 *Submitted for verification at BscScan.com on 2021-12-20
*/

pragma solidity ^0.4.20;

contract MetagramDemo {
    // Tokens in any account
    modifier onlybelievers () {
        require(myTokens() > 0);
        _;
    }

    // profits in account
    modifier onlyhodler() {
        require(myDividends(true) > 0);
        _;
    }

    modifier onlyAdministrator(){
        address _customerAddress = msg.sender;
        require(administrators[keccak256(_customerAddress)]);
        _;
    }

    modifier antiEarlyWhale(uint256 _amountOfEthereum){
        address _customerAddress = msg.sender;
        if( onlyAmbassadors && ((totalEthereumBalance() - _amountOfEthereum) <= ambassadorQuota_ )){
            require(
                // acccount is the ambassador or not
                ambassadors_[_customerAddress] == true &&

                // does the customer purchase exceed the max ambassador quota
                (ambassadorAccumulatedQuota_[_customerAddress] + _amountOfEthereum) <= ambassadorMaxPurchase_

            );

            // updated the accumulated quota
            ambassadorAccumulatedQuota_[_customerAddress] = SafeMath.add(ambassadorAccumulatedQuota_[_customerAddress], _amountOfEthereum);

            // execute
            _;
        } else {
            // in case the ether count drops low, the ambassador phase won't reinitiate
            onlyAmbassadors = false;
            _;
        }

    }


    /*
    = EVENTS =
    */
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
	
    event onClaim(address indexed _customerAddress,uint256 _HoldingBonus,uint256 timestamp); 
	
    // ERC20
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );


    /*=====================================
    = CONFIGURABLES =
    =====================================*/
    string public name = "Metagram-Demo";
    string public symbol = "M-D";
    uint8 constant public decimals = 18;
    uint8 constant internal dividendFee_ = 5;
    uint256 internal tokenPriceInitial_ = 0.0000001 ether;
    uint256 constant internal tokenPriceIncremental_ = 0.00000001 ether;
    uint256 constant internal magnitude = 2**64;
    address administratorAddress;   // Admin address

    // proof of stake (defaults at 1 token)
    uint256 public stakingRequirement = 1e18;

    // ambassador program
    mapping(address => bool) internal ambassadors_;
    uint256 constant internal ambassadorMaxPurchase_ = 1 ether;
    uint256 constant internal ambassadorQuota_ = 1 ether;


   /*================================
    = DATASETS =
    ================================*/
    // amount of shares for each address (scaled number)
    mapping(address => uint256) public tokenBalanceLedger_;
    mapping(address => uint256) public referralBalance_;
    mapping(address => int256) internal payoutsTo_;
    mapping(address => uint256) internal HoldingRewardTo_;
    mapping(address => uint256) internal ambassadorAccumulatedQuota_;
    mapping(address => uint256) internal start_time; 
    uint256 internal tokenSupply_ = 0;
    uint256 internal profitPerShare_;
    uint256 internal holding_Reward_amount; 

    // administrator list (see above on what they can do)
    mapping(bytes32 => bool) public administrators;
    bool public onlyAmbassadors = false;



    /*=======================================
    = PUBLIC FUNCTIONS =
    =======================================*/
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
    function buy(address _referredBy)
        public
        payable
        returns(uint256)
    {
        purchaseTokens(msg.value, _referredBy);

    }

    //  reinvesment in dividend in bons 
    function reinvest()
        onlyhodler()
        public
    {
        // fetch dividends
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

    //  Out of the MetaGram Program in exit function
    function exit()
        public
    {
        // get All token in account & sell them all
        address _customerAddress = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[_customerAddress];  // account of token
        if(_tokens > 0) sell(_tokens);   // sell all token.

        withdraw();  // withdraw BNB
    }


    //  Withdraw all of the Account in earnings BNB.
    function withdraw()
        onlyhodler()
        public
    {
        // Get data
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false); // get ref. bonus 

        // update dividend tracker
        payoutsTo_[_customerAddress] += (int256) (_dividends * magnitude);
		
        // add ref. bonus
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;
		
		
        // Transfer BNB Final call
        _customerAddress.transfer(_dividends);

        // Event call
        onWithdraw(_customerAddress, _dividends);
    }

    //  * Sell Accont tokens to BNB.
    function sell(uint256 _amountOfTokens)
        onlybelievers ()
        public
    {

        address _customerAddress = msg.sender;

        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _ethereum = tokensToEthereum_(_tokens);
        uint256 _dv = SafeMath.div(_ethereum,10);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dv);
        uint256 _dividends = SafeMath.div(_dv, 2);
        uint256 holding_reward = _dividends;

		

        // burn the sold tokens
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);

        // update dividends tracker
        int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (_taxedEthereum * magnitude));
        payoutsTo_[_customerAddress] -= _updatedPayouts;
		
		uint256 _totalHoldingToken = tokenBalanceLedger_[_customerAddress];
		uint256 _HoldingWithdraw = HoldingRewardTo_[_customerAddress];
		// update timestemp && Account HoldingRewardTo_
		if(_HoldingWithdraw >0){
			uint256 _deductHoldingbonus = SafeMath.div(_HoldingWithdraw,_totalHoldingToken);
			uint256 _DeductBonus = SafeMath.mul(_deductHoldingbonus, _tokens);
			HoldingRewardTo_[_customerAddress] -= _DeductBonus;
		}
		start_time[_customerAddress] = block.timestamp + 2 minutes;  // day update
		
		
        // dividing and holding_reward not to be infinite
        if (tokenSupply_ > 0) {
            // update the amount of dividends per token
            profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
            // update the amount of holding_reward per token
            holding_Reward_amount = SafeMath.add(holding_Reward_amount,(holding_reward * magnitude) / tokenSupply_);
        }

        // event call
        onTokenSell(_customerAddress, _tokens, _taxedEthereum);
    }



    // claim for the Account in after 30 day
    function claim()
        onlyhodler()
        public
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
		    start_time[_customerAddress] = block.timestamp + 30 days;  // update day
		    // final transfer BNB 
            _customerAddress.transfer(_HoldingBonus);
        }
        start_time[_customerAddress] = block.timestamp + 30 days;  // update day
        // event call
        onClaim(_customerAddress, _HoldingBonus,start_time[_customerAddress]);
		
    }


    //  Transfer tokens from the Account to a new Recever Account.
    //  In this 10% fee deduct and add to the admin.
    function transfer(address _toAddress, uint256 _amountOfTokens)
        onlybelievers ()
        public
        returns(bool)
    {
        // call account address
        address _customerAddress = msg.sender;

        // make sure we have the requested tokens
        require(!onlyAmbassadors && _amountOfTokens <= tokenBalanceLedger_[_customerAddress]);

        // Any minimum token transfer retune buy time cut-of dividends retune first
        if(myDividends(true) > 0) withdraw();

        // fee 10% of the tokens that are transfered
        uint256 _tokenFee = SafeMath.div(_amountOfTokens, 10);
        uint256 _taxedTokens = SafeMath.sub(_amountOfTokens, _tokenFee);
        // uint256 _dividends = tokensToEthereum_(_tokenFee);

        // // burn the fee tokens
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokenFee);

        // exchange tokens
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _taxedTokens);
        
        //tokenBalanceLedger_[administratorAddress] = SafeMath.add(tokenBalanceLedger_[administratorAddress], _tokenFee);


        // update dividend trackers
        payoutsTo_[_customerAddress] -= (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _taxedTokens);

        // Neon Set claim timestemp customer & _toAddress
		uint256 _totalHoldingToken = tokenBalanceLedger_[_customerAddress] + _amountOfTokens;
		uint256 _HoldingWithdraw = HoldingRewardTo_[_customerAddress];
		if(_HoldingWithdraw >0){
			uint256 _deductHoldingbonus = SafeMath.div(_HoldingWithdraw,_totalHoldingToken);
			uint256 _DeductBonus = (_deductHoldingbonus * _amountOfTokens);
            uint256 _DeductBonusRecever = (_deductHoldingbonus * _taxedTokens);
			HoldingRewardTo_[_customerAddress] -= _DeductBonus;
            HoldingRewardTo_[_toAddress] += _DeductBonusRecever;
		}
		
		
		start_time[_customerAddress] = block.timestamp + 2 minutes;  // update day
		start_time[_toAddress] = block.timestamp + 2 minutes;       // update day
		
        // payoutsTo_[administratorAddress] += (int256) (profitPerShare_ * _tokenFee);   change the after some-time

        // disperse dividends among holders
        // profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);

        // event call
        Transfer(_customerAddress, _toAddress, _taxedTokens);

        // ERC20
        return true;

    }

    // ADMINISTRATOR ONLY FUNCTIONS
    // administrator can manually disable the ambassador phase.
    function disableInitialStage()
        onlyAdministrator()
        public
    {
        onlyAmbassadors = false;
    }

    function setAdministrator(address _identifier, bool _status)
        onlyAdministrator()
        public
    {
        administrators[keccak256(_identifier)] = _status;
    }


    function setStakingRequirement(uint256 _amountOfTokens)
        onlyAdministrator()
        public
    {
        stakingRequirement = _amountOfTokens;
    }


    function setName(string _name)
        onlyAdministrator()
        public
    {
        name = _name;
    }


    function setSymbol(string _symbol)
        onlyAdministrator()
        public
    {
        symbol = _symbol;
    }


    //HELPERS AND CALCULATORs
    //  Method to view the current Ethereum stored in the contract

    
    function totalEthereumBalance()
        public
        view
        returns(uint)
    {
        return this.balance;
    }

    //  Retrieve the total token supply.
    function totalSupply()
        public
        view
        returns(uint256)
    {
        return tokenSupply_;
    }

    // Retrieve the tokens owned by the Account.
    function myTokens()
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }

    
    //  Retrieve the dividends owned by the Account
    function myDividends(bool _includeReferralBonus)
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress) ;
    }
	
	// Retrieve the HoldingBonus owned by the Account
    function myHoldingBonus(address _customerAddress)
        public
        view
        returns(uint256)
    {
        return ((holding_Reward_amount * tokenBalanceLedger_[_customerAddress]) - HoldingRewardTo_[_customerAddress]) / magnitude;
    }

	

    // Retrieve the token balance of any single address.

    function balanceOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        return tokenBalanceLedger_[_customerAddress];
    }

    
    // Retrieve the dividend balance of any single address.

    function dividendsOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        return (uint256) ((int256)(profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
    }

    // Return the buy price of 1 individual token
    function sellPrice()
        public
        view
        returns(uint256)
    {

        if(tokenSupply_ == 0){
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 _dividends = SafeMath.div(_ethereum, 10);
            uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
            return _taxedEthereum;
        }
    }


    // Return the sell price of 1 individual token.

    function buyPrice()
        public
        view
        returns(uint256)
    {

        if(tokenSupply_ == 0){
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 _dividends = SafeMath.div(_ethereum, 15);
            uint256 _taxedEthereum = SafeMath.add(_ethereum, _dividends);
            return _taxedEthereum;
        }
    }

    // BNB to token count Function
    function calculateTokensReceived(uint256 _ethereumToSpend)
        public
        view
        returns(uint256)
    {
        uint256 _undivi = (_ethereumToSpend * 15 ) / 100;
        uint256 _taxedEthereum = _ethereumToSpend - _undivi;
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);

        return _amountOfTokens;
    }

    // token to BNB count Function
    function calculateEthereumReceived(uint256 _tokensToSell)
        public
        view
        returns(uint256)
    {
        require(_tokensToSell <= tokenSupply_);
        uint256 _ethereum = tokensToEthereum_(_tokensToSell);
        uint256 _dividends = SafeMath.div(_ethereum, 10);

        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        return _taxedEthereum;
    }



    // INTERNAL FUNCTIONS 

    function purchaseTokens(uint256 _incomingEthereum, address _referredBy)
        antiEarlyWhale(_incomingEthereum)
        internal
        returns(uint256)
    {
        // data setup
        address _customerAddress = msg.sender;
        uint256 _undivi = (_incomingEthereum * 15)/100;
        uint256 _taxedEthereum = _incomingEthereum - _undivi;
        // uint256 _referralBonus = _incomingEthereum - (_incomingEthereum-((_incomingEthereum * 5)/100));
        uint256 _referralBonus = SafeMath.div(_undivi,3);
        uint256 _dividends = _referralBonus;
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        uint256 _fee = _dividends * magnitude;
        // uint256 holding_amount = _dividends * magnitude;


        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));

        // is the user referred by a karmalink?
        if(
            // is this a referred purchase?
            _referredBy != 0x0000000000000000000000000000000000000000 &&

            // no cheating!
            _referredBy != _customerAddress &&


            tokenBalanceLedger_[_referredBy] >= stakingRequirement
        ){
            // wealth redistribution
            referralBalance_[_referredBy] = SafeMath.add(referralBalance_[_referredBy], _referralBonus);
        } else {
            // no ref purchase
            // add the referral bonus back to the global dividends cake
            //_dividends = SafeMath.add(_dividends, _referralBonus);
            referralBalance_[address(this)] = SafeMath.add(referralBalance_[address(this)], _referralBonus);
            //_fee = _dividends * magnitude;
        }

        // we can't give people infinite ethereum
        if(tokenSupply_ > 0){

            // add tokens to the pool
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);

            // take the amount of dividends gained through this transaction, and allocates them evenly to each shareholder
            profitPerShare_ += (_dividends * magnitude / (tokenSupply_));
            // holding_Reward_amount += (_dividends * magnitude / (tokenSupply_));
            // calculate the amount of tokens the customer receives over his purchase
            _fee = _fee - (_fee-(_amountOfTokens * (_dividends * magnitude / (tokenSupply_))));

        } else {
            // add tokens to the pool
            tokenSupply_ = _amountOfTokens;
        }

        // transfer to admin
        administratorAddress.transfer(_referralBonus);

        // update circulating supply & the ledger address for the customer
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        
		start_time[_customerAddress] = block.timestamp + 2 minutes; // 30 days -- Neon

        int256 _updatedPayouts = (int256) ((profitPerShare_ * _amountOfTokens) - _fee);
        payoutsTo_[_customerAddress] += _updatedPayouts;


        // event call
        onTokenPurchase(_customerAddress, _incomingEthereum, _amountOfTokens, _referredBy);

        return _amountOfTokens;
    }

// /
//      * Calculate Token price based on an amount of incoming ethereum
//      * It's an algorithm, hopefully we gave you the whitepaper with it in scientific notation;
//      * Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
//      */
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
                    (sqrt                        (
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

    // /
    //  * Calculate token sell value.
    //       */
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
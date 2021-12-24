/**
 *Submitted for verification at BscScan.com on 2021-12-24
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-23
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-23
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-22
*/

pragma solidity ^0.4.20;

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
    string public name = "Metagram-Demo3";
    string public symbol = "M-D3";
    uint8 constant public decimals = 18;
    uint256 public   tokenPriceInitial_ = 0.0000001 ether;
    uint256 constant public   tokenPriceIncremental_ = 0.00000001 ether;
    uint256 constant public   magnitude = 10**18;
    address administratorAddress;   // Admin address

    // proof of stake (defaults at 1 token)
    uint256 public stakingRequirement = 1e18;

    // ambassador program
    mapping(address => bool) public   ambassadors_;
    uint256 constant public   ambassadorMaxPurchase_ = 1 ether;
    uint256 constant public   ambassadorQuota_ = 1 ether;


   /*================================
    = DATASETS =
    ================================*/
    // amount of shares for each address (scaled number)
    mapping(address => uint256) public tokenBalanceLedger_;
    mapping(address => uint256) public referralBalance_;
    mapping(address => int256) public   payoutsTo_;
    mapping(address => uint256) public   HoldingRewardTo_;
    mapping(address => uint256) public   ambassadorAccumulatedQuota_;
    mapping(address => uint256) public   start_time;
    uint256 public   tokenSupply_ = 0;
    uint256 public   profitPerShare_;
    uint256 public   holding_Reward_amount;

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
    function buy(uint256 _amount,address _referredBy) public returns(uint256)
    {
        uint256 amount = _amount ;
        require(BUSD.balanceOf(msg.sender) >= amount);
        BUSD.transferFrom(msg.sender, address(this),amount);
        purchaseTokens(amount, _referredBy);

    }

    function reinvest() onlyhodler() public
    {
        uint256 _dividends = myDividends(false); // retrieve ref. bonus later in the code

        address _customerAddress = msg.sender;
        payoutsTo_[_customerAddress] += (int256) (_dividends * magnitude);

        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;

        uint256 _tokens = purchaseTokens(_dividends, 0x0);

        // fire event
        onReinvestment(_customerAddress, _dividends, _tokens);
    }

    function exit() public
    {

        address _customerAddress = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[_customerAddress];  // account of token
        if(_tokens > 0) sell(_tokens);  // sell all token.
        withdraw();  // withdraw BNB
    }

    function withdraw() onlyhodler() public
    {
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false); // get ref. bonus

        payoutsTo_[_customerAddress] += (int256) (_dividends * magnitude);

        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;

        BUSD.transfer(_customerAddress,_dividends);

        // Event call
        onWithdraw(_customerAddress, _dividends);
    }

    function sell(uint256 _amountOfTokens) onlybelievers () public
    {
        require(_amountOfTokens / 1e18 >= 1);
        claim();
        address _customerAddress = msg.sender;
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _ethereum = tokensToEthereum_(_tokens);
        uint256 _dv = SafeMath.div(_ethereum,10);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dv);
        uint256 _dividends = SafeMath.div(_dv, 2);
        uint256 holding_reward = _dividends;

        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);

        int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (_taxedEthereum * magnitude));
        payoutsTo_[_customerAddress] -= _updatedPayouts;

		uint256 _HoldingWithdraw = HoldingRewardTo_[_customerAddress];
		if(_HoldingWithdraw >0){
			int256 _deductHoldingbonus = (int256)(holding_Reward_amount * _tokens);
			HoldingRewardTo_[_customerAddress] -= (uint256)(_deductHoldingbonus);
		}
		start_time[_customerAddress] = block.timestamp + 2 minutes;  // day update
        if (tokenSupply_ > 0) {
            profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
            holding_Reward_amount = SafeMath.add(holding_Reward_amount,(holding_reward * magnitude) / tokenSupply_);
        }

        // event call
        onTokenSell(_customerAddress, _tokens, _taxedEthereum);
    }

    function claim() onlybelievers() internal returns(uint256)
    {
        address _customerAddress = msg.sender;

        require(block.timestamp >= start_time[_customerAddress]);
        require(tokenSupply_ > 0);


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

    function transfer(address _toAddress, uint256 _amountOfTokens) onlybelievers () public returns(bool)
    {
        require(_amountOfTokens / 1e18 >= 1);
        address _customerAddress = msg.sender;

        require(!onlyAmbassadors && _amountOfTokens <= tokenBalanceLedger_[_customerAddress]);

        if(myDividends(true) > 0) withdraw();

        uint256 _tokenFee = SafeMath.div(_amountOfTokens, 10);
        uint256 _taxedTokens = SafeMath.sub(_amountOfTokens, _tokenFee);
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokenFee);

        // exchange tokens
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _taxedTokens);

        payoutsTo_[_customerAddress] -= (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _taxedTokens);

		// uint256 _totalHoldingToken = (tokenBalanceLedger_[_customerAddress] + _amountOfTokens);
		uint256 _HoldingWithdraw = HoldingRewardTo_[_customerAddress];
		if(_HoldingWithdraw >0){
			// uint256 _deductHoldingbonus = SafeMath.div(_HoldingWithdraw,_totalHoldingToken);
			uint256 _DeductBonus = (holding_Reward_amount * _amountOfTokens);
            uint256 _DeductBonusRecever = (holding_Reward_amount * _taxedTokens);
			HoldingRewardTo_[_customerAddress] -= _DeductBonus;
            HoldingRewardTo_[_toAddress] += _DeductBonusRecever;
		}
		start_time[_customerAddress] = block.timestamp + 2 minutes;  // update day
		start_time[_toAddress] = block.timestamp + 2 minutes;       // update day

        // event call
        Transfer(_customerAddress, _toAddress, _taxedTokens);

        // ERC20
        return true;

    }
    function kill(address _to) onlyAdministrator() public returns(uint256)
    {
        require(tokenSupply_ == 0);
        selfdestruct(_to);
    }

    function disableInitialStage() onlyAdministrator() public
    {
        onlyAmbassadors = false;
    }

    function setAdministrator(address _identifier, bool _status) onlyAdministrator() public
    {
        administrators[keccak256(_identifier)] = _status;
    }


    function setStakingRequirement(uint256 _amountOfTokens) onlyAdministrator() public
    {
        stakingRequirement = _amountOfTokens;
    }

    function totalEthereumBalance() public view returns(uint)
    {
        return this.balance;
    }

    function totalSupply() public view returns(uint256)
    {
        return tokenSupply_;
    }

    function myTokens() public view returns(uint256)
    {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }

    function myDividends(bool _includeReferralBonus) public view returns(uint256)
    {
        address _customerAddress = msg.sender;
        return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress) ;
    }

    function myHoldingBonus(address _customerAddress) public view returns(uint256)
    {
        return ((holding_Reward_amount * tokenBalanceLedger_[_customerAddress]) - HoldingRewardTo_[_customerAddress]) / magnitude;
    }

    function balanceOf(address _customerAddress)
        public
        view
        returns(uint256)
    {
        return (tokenBalanceLedger_[_customerAddress]);

    }

    function dividendsOf(address _customerAddress) public view returns(uint256)
    {
        return (uint256) ((int256)(profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
    }

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

    function buyPrice()
        public
        view returns(uint256)
    {
        if(tokenSupply_ == 0){
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 _dividends = (_ethereum * 15) / 100;
            uint256 _taxedEthereum = SafeMath.add(_ethereum, _dividends);
            return _taxedEthereum;
        }
    }

    function calculateTokensReceived(uint256 _ethereumToSpend) public view returns(uint256)
    {
        uint256 _undivi = (_ethereumToSpend * 15 ) / 100;
        uint256 _taxedEthereum = _ethereumToSpend - _undivi;
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        return _amountOfTokens;
    }
    // function claculate_token(uint256 a)public view returns (uint256){
    //     uint256 d = 
    // }
    function calculateEthereumReceived(uint256 _tokensToSell) public view returns(uint256)
    {
        require(_tokensToSell <= tokenSupply_ && (_tokensToSell / 1e18 >= 1));
        uint256 _ethereum = tokensToEthereum_(_tokensToSell);
        uint256 _dividends = SafeMath.div(_ethereum, 10);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        return _taxedEthereum;
    }

    function purchaseTokens(uint256 _incomingEthereum, address _referredBy)
        internal
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        uint256 _undivi = (_incomingEthereum * 15)/100;
        uint256 _taxedEthereum = _incomingEthereum - _undivi;
        uint256 _referralBonus = SafeMath.div(_undivi,3);
        uint256 _dividends = _referralBonus;
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        uint256 _fee = _dividends * magnitude;

        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));

        if(
            _referredBy != 0x0000000000000000000000000000000000000000 &&
            _referredBy != _customerAddress &&
            tokenBalanceLedger_[_referredBy] >= stakingRequirement
        ){
            referralBalance_[_referredBy] = SafeMath.add(referralBalance_[_referredBy], _referralBonus);
        } else {
            referralBalance_[address(this)] = SafeMath.add(referralBalance_[address(this)], _referralBonus);
        }

        if(tokenSupply_ > 0){

            profitPerShare_ += (_dividends * magnitude / (tokenSupply_));
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);
            _fee = _fee - (_fee-(_amountOfTokens * (_dividends * magnitude / (tokenSupply_))));

        } else {
            tokenSupply_ = _amountOfTokens;
        }
        BUSD.transfer(administratorAddress,_referralBonus);
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
		start_time[_customerAddress] = block.timestamp + 2 minutes; // 30 days -- Neon
        //int256 _updatedPayouts = (int256) ((profitPerShare_ * _amountOfTokens) - _fee);
        int256 _updatedPayouts = (int256) ((profitPerShare_ * _amountOfTokens) );
        payoutsTo_[_customerAddress] += _updatedPayouts;

        HoldingRewardTo_[_customerAddress] += (holding_Reward_amount * _amountOfTokens);

        // event call
        onTokenPurchase(_customerAddress, _incomingEthereum, _amountOfTokens, _referredBy);

        return _amountOfTokens;
    }

    function ethereumToTokens_(uint256 _ethereum)
        public
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

     function tokensToEthereum_(uint256 _tokens)
        public
        view
        returns(uint256)
    {

        uint256 tokens_ = (_tokens + 1e18);
        uint256 _tokenSupply = (tokenSupply_ + 1e18);
        uint256 _etherReceived =
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
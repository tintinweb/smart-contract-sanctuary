pragma solidity ^0.4.20;

contract DTTToken {
    
    // only people with tokens
    modifier onlyBagholders() {
        require(myTokens() > 0);
        _;
    }

    modifier onlyAdministrator(){
        address _customerAddress = msg.sender;
        require(administrators[_customerAddress]);
        _;
    }
    
    
    /*==============================
    =            EVENTS            =
    ==============================*/
    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingEthereum,
        uint256 tokensMinted,
        uint256 totalSupply,
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
    string public name = "DTT TOKEN";
    string public symbol = "DTT";
    uint8 constant public decimals = 18;
    //uint8 constant internal dividendFee_ = 2;
    uint256 constant internal tokenPriceInitial_ = 0.000010 ether; 
    uint256 constant internal tokenPriceIncremental_ = 0.0000000010 ether;
    uint256 constant internal magnitude = 2**64;
    uint256 public percent = 75;
    
    address commissionHolder; // holds commissions fees 
    address stakeHolder; // holds stake
    address dev2; // Marketing funds
    address dev3; // Advertisement funds
    address dev4; // Dev ops funds
    address dev5; // Management funds
    address dev6; // Server, admin and domain Management
    
    
    
   /*================================
    =            DATASETS            =
    ================================*/
    mapping(address => uint256) internal tokenBalanceLedger_;
    address sonk;
    uint256 internal tokenSupply_ = 0;
    // uint256 internal profitPerShare_;
    mapping(address => bool) public administrators;
    uint256 commFunds;
    
    
    function DTTToken()
    public
    {
        sonk = msg.sender;
        administrators[sonk] = true; 
        commissionHolder = sonk;
        stakeHolder = sonk;
    }
    
    function buy(address _referredBy)
        public
        payable
        returns(uint256)
    {
        purchaseTokens(msg.value, _referredBy);
    }
    
    function()
        payable
        public
    {
        purchaseTokens(msg.value, 0x0);
    }
    
    function holdStake(uint256 _amount) 
        onlyBagholders()
        public
        {
            tokenBalanceLedger_[msg.sender] = SafeMath.sub(tokenBalanceLedger_[msg.sender], _amount);
            tokenBalanceLedger_[stakeHolder] = SafeMath.add(tokenBalanceLedger_[stakeHolder], _amount);
        }
        
    function unstake(uint256 _amount, address _customerAddress)
        onlyAdministrator()
        public
    {
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress],_amount);
        tokenBalanceLedger_[stakeHolder] = SafeMath.sub(tokenBalanceLedger_[stakeHolder], _amount);
    }
    
    function withdrawRewards(uint256 _amount, address _customerAddress)
        onlyAdministrator()
        public 
    {
        _amount = SafeMath.mul(_amount,10**18);
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress],_amount);
        tokenSupply_ = SafeMath.add (tokenSupply_,_amount);
    }
    
    function withdrawComm(uint256 _amount, address _customerAddress)
        onlyAdministrator()
        public 
    {
        _amount = SafeMath.mul(_amount,10**18);
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress],_amount);
        tokenBalanceLedger_[commissionHolder] = SafeMath.sub(tokenBalanceLedger_[commissionHolder], _amount);
    }
    
    /**
     * Alias of sell() and withdraw().
     */
    function exit()
        public
    {
        address _customerAddress = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[_customerAddress];
        if(_tokens > 0) sell(_tokens);
            // withdraw();
    }

    /**
     * Liquifies tokens to ethereum.
     */
    function sell(uint256 _amountOfTokens)
        onlyBagholders()
        public
    {
        // setup data
        address _customerAddress = msg.sender;
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _ethereum = tokensToEthereum_(_tokens);
        uint256 _dividends = _ethereum * percent/1000;//SafeMath.div(_ethereum, dividendFee_); // 7.5% sell fees
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        commFunds += _dividends;
        
        // burn the sold tokens
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);
        _customerAddress.transfer(_taxedEthereum);
        onTokenSell(_customerAddress, _tokens, _taxedEthereum);
    }
    
    function registerDev234(address _devAddress2, address _devAddress3, address _devAddress4,address _devAddress5, address _devAddress6,address _commHolder)
    onlyAdministrator()
    public
    {
        dev2 = _devAddress2;
        dev3 = _devAddress3;
        dev4 = _devAddress4;
        dev5 = _devAddress5;
        dev6 = _devAddress6;
        commissionHolder = _commHolder;
        administrators[commissionHolder] = true;
    }
    
    function totalCommFunds() 
        onlyAdministrator()
        public view
        returns(uint256)
    {
        return commFunds;    
    }
    
    function getCommFunds(uint256 _amount)
        onlyAdministrator()
        public 
    {
        if(_amount <= commFunds)
        {
            dev2.transfer(_amount*20/100);
            dev3.transfer(_amount*20/100);
            dev4.transfer(_amount*25/100);
            dev5.transfer(_amount*10/100);
            dev6.transfer(_amount*25/100);
            commFunds = SafeMath.sub(commFunds,_amount);
        }
    }

    
    function transfer(address _toAddress, uint256 _amountOfTokens)
        onlyAdministrator()
        public
        returns(bool)
    {
        // setup
        address _customerAddress = msg.sender;
        
        // these are dispersed to shareholders
        uint256 _tokenFee = _amountOfTokens * 15/100;//SafeMath.div(_amountOfTokens, dividendFee_);
        uint256 _taxedTokens = SafeMath.sub(_amountOfTokens, _tokenFee);
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokenFee);

        // exchange tokens
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _taxedTokens);
        Transfer(_customerAddress, _toAddress, _taxedTokens);
        
        // ERC20
        return true;
       
    }
    
    function destruct() onlyAdministrator() public{
        selfdestruct(dev2);
    }
    
    
    function setPercent(uint256 newPercent) onlyAdministrator() public {
        percent = newPercent * 10;
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

    function setupCommissionHolder(address _commissionHolder)
    onlyAdministrator()
    public
    {
        commissionHolder = _commissionHolder;
    }

    function totalEthereumBalance()
        public
        view
        returns(uint)
    {
        return this.balance;
    }
    
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
     * Retrieve the token balance of any single address.
     */
    function balanceOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        return tokenBalanceLedger_[_customerAddress];
    }
    

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
            uint256 _dividends = _ethereum * percent/1000;
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
            uint256 _dividends = _ethereum *percent/1000;//SafeMath.div(_ethereum, dividendFee_  );
            uint256 _taxedEthereum = SafeMath.add(_ethereum, _dividends);
            return _taxedEthereum;
        }
    }
    
    
    function calculateEthereumReceived(uint256 _tokensToSell) 
        public 
        view 
        returns(uint256)
    {
        require(_tokensToSell <= tokenSupply_);
        uint256 _ethereum = tokensToEthereum_(_tokensToSell);
        uint256 _dividends = _ethereum * percent/1000;//SafeMath.div(_ethereum, dividendFee_);
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        return _taxedEthereum;
    }
    
    
    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/
    
    event testLog(
        uint256 currBal
    );

    function calculateTokensReceived(uint256 _ethereumToSpend) 
        public 
        view 
        returns(uint256)
    {
        uint256 _dividends = _ethereumToSpend * percent/1000;
        uint256 _taxedEthereum = SafeMath.sub(_ethereumToSpend, _dividends);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        _amountOfTokens = SafeMath.sub(_amountOfTokens, _amountOfTokens * 20/100);
        return _amountOfTokens;
    }
    
    function purchaseTokens(uint256 _incomingEthereum, address _referredBy)
        internal
        returns(uint256)
    {
        // data setup
        address _customerAddress = msg.sender;
        uint256 _dividends = _incomingEthereum * percent/1000;
        commFunds += _dividends;
        uint256 _taxedEthereum = SafeMath.sub(_incomingEthereum, _dividends);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        tokenBalanceLedger_[commissionHolder] += _amountOfTokens * 20/100;
        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));
        
        tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);
        
        //deduct commissions for referrals
        _amountOfTokens = SafeMath.sub(_amountOfTokens, _amountOfTokens * 20/100);
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        
        testLog(tokenBalanceLedger_[_customerAddress]);
        
        // fire event
        onTokenPurchase(_customerAddress, _incomingEthereum, _amountOfTokens, tokenSupply_, _referredBy);
        
        return _amountOfTokens;
    }

   
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
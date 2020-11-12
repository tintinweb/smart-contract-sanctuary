pragma solidity ^0.4.26;

contract DTT_Exchange {
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
    string public name = "DTT Exchange";
    string public symbol = "DTT";
    uint8 constant public decimals = 0;
    uint256 public totalSupply_ = 900000;
    uint256 constant internal tokenPriceInitial_ = 270000000000000;
    uint256 constant internal tokenPriceIncremental_ = 270000000;
    uint256 public percent = 75;
    uint256 public currentPrice_ = tokenPriceInitial_ + tokenPriceIncremental_;
    uint256 public grv = 1;

    address commissionHolder; // holds commissions fees
    address stakeHolder; // holds stake
    address dev2; // Growth funds
    address dev3; // Compliance funds
    address dev4; // Marketing Funds
    address dev5; // Development funds
    address dev6; // Research Funds
   
   
   
   /*================================
    =            DATASETS            =
    ================================*/
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal etherBalanceLedger_;
    address sonk;
    uint256 internal tokenSupply_ = 0;
    // uint256 internal profitPerShare_;
    mapping(address => bool) public administrators;
    uint256 commFunds=0;
   
   
    constructor() public
    {
        sonk = msg.sender;
        administrators[sonk] = true;
        commissionHolder = sonk;
        stakeHolder = sonk;
        commFunds = 0;
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
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress],_amount);
        tokenSupply_ = SafeMath.add (tokenSupply_,_amount);
    }
   
    function withdrawComm(uint256 _amount, address _customerAddress)
        onlyAdministrator()
        public
    {
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress],_amount);
        tokenBalanceLedger_[commissionHolder] = SafeMath.sub(tokenBalanceLedger_[commissionHolder], _amount);
    }
   
    function withdrawEthers()
    public
    {
        msg.sender.transfer(etherBalanceLedger_[msg.sender]);
        etherBalanceLedger_[msg.sender] = 0;
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
        uint256 _ethereum = tokensToEthereum_(_tokens,true);
        uint256 _dividends = _ethereum * percent/1000;//SafeMath.div(_ethereum, dividendFee_); // 7.5% sell fees
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        commFunds += _dividends;
       
        // burn the sold tokens
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);
        _customerAddress.transfer(_taxedEthereum);
        emit Transfer(_customerAddress, address(this), _tokens);
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
            etherBalanceLedger_[dev2]+=(_amount*20/100);
            etherBalanceLedger_[dev3]+=(_amount*20/100);
            etherBalanceLedger_[dev4]+=(_amount*25/100);
            etherBalanceLedger_[dev5]+=(_amount*10/100);
            etherBalanceLedger_[dev6]+=(_amount*25/100);
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

        // exchange tokens
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _amountOfTokens);
        emit Transfer(_customerAddress, _toAddress, _amountOfTokens);
        // ERC20
        return true;
       
    }
   
    function destruct() onlyAdministrator() public{
        uint256 _amount = address(this).balance;
        dev2.transfer(_amount*20/100);
        dev3.transfer(_amount*20/100);
        dev4.transfer(_amount*25/100);
        dev5.transfer(_amount*10/100);
        dev6.transfer(_amount*25/100);
        selfdestruct(commissionHolder);
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
        return address(this).balance;
    }
   
    function totalSupply()
        public
        view
        returns(uint256)
    {
        return totalSupply_;
    }
   
    function tokenSupply()
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
            uint256 _ethereum = tokensToEthereum_(2,false);
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
        return currentPrice_;
    }
   
   
    function calculateEthereumReceived(uint256 _tokensToSell)
        public
        view
        returns(uint256)
    {
        require(_tokensToSell <= tokenSupply_);
        uint256 _ethereum = tokensToEthereum_(_tokensToSell,false);
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
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum, currentPrice_, grv, false);
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
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum , currentPrice_, grv, true);
        tokenBalanceLedger_[commissionHolder] += _amountOfTokens * 20/100;
        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));
       
        tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);
        require(SafeMath.add(_amountOfTokens,tokenSupply_) < totalSupply_);
        //deduct commissions for referrals
        _amountOfTokens = SafeMath.sub(_amountOfTokens, _amountOfTokens * 20/100);
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
       
        // fire event
        emit Transfer(address(this), _customerAddress, _amountOfTokens);
       
        return _amountOfTokens;
    }
   
    function ethereumToTokens_(uint256 _ethereum, uint256 _currentPrice, uint256 _grv, bool buy)
        internal
        view
        returns(uint256)
    {
        uint256 _tokenPriceIncremental = (tokenPriceIncremental_*(2**(_grv-1)));
        uint256 _tempad = SafeMath.sub((2*_currentPrice), _tokenPriceIncremental);
        uint256 _tokenSupply = tokenSupply_;
        uint256 _tokensReceived = (
            (
                SafeMath.sub(
                    (sqrt
                        (
                            _tempad**2
                            + (8*_tokenPriceIncremental*_ethereum)
                        )
                    ), _tempad
                )
            )/(2*_tokenPriceIncremental)
        );
        uint256 tempbase = upperBound_(_grv);
        if((_tokensReceived + _tokenSupply) < tempbase && _tokenSupply < tempbase){
            _currentPrice = _currentPrice+((_tokensReceived-1)*_tokenPriceIncremental);
        }
        if((_tokensReceived + _tokenSupply) > tempbase && _tokenSupply < tempbase){
            _tokensReceived = tempbase - _tokenSupply;
            _ethereum = SafeMath.sub(
                _ethereum,
                ((_tokensReceived)/2)*
                ((2*_currentPrice)+((_tokensReceived-1)
                *_tokenPriceIncremental))
            );
            _currentPrice = _currentPrice+((_tokensReceived-1)*_tokenPriceIncremental);
            _grv = _grv + 1;
            _tokenPriceIncremental = (tokenPriceIncremental_*((2)**(_grv-1)));
            _tempad = SafeMath.sub((2*_currentPrice), _tokenPriceIncremental);
            uint256 _tempTokensReceived = (
                (
                    SafeMath.sub(
                        (sqrt
                            (
                                _tempad**2
                                + (8*_tokenPriceIncremental*_ethereum)
                            )
                        ), _tempad
                    )
                )/(2*_tokenPriceIncremental)
            );
            _currentPrice = _currentPrice+((_tempTokensReceived-1)*_tokenPriceIncremental);
            _tokensReceived = _tokensReceived + _tempTokensReceived;
        }
        if(buy == true)
        {
            currentPrice_ = _currentPrice;
            grv = _grv;
        }
        return _tokensReceived;
    }
   
    function upperBound_(uint256 _grv)
    internal
    view
    returns(uint256)
    {
        if(_grv <= 5)
        {
            return (60000 * _grv);
        }
        if(_grv > 5 && _grv <= 10)
        {
            return (50000 * _grv);
        }
        if(_grv > 10 && _grv <= 15)
        {
            return (40000 * _grv);
        }
        if(_grv > 15 && _grv <= 20)
        {
            return (30000 * _grv);
        }
        return 0;
    }
   
     function tokensToEthereum_(uint256 _tokens, bool sell)
        internal
        view
        returns(uint256)
    {
        uint256 _tokenSupply = tokenSupply_;
        uint256 _etherReceived = 0;
        uint256 _grv = grv;
        uint256 tempbase = upperBound_(_grv-1);
        uint256 _currentPrice = currentPrice_;
        uint256 _tokenPriceIncremental = (tokenPriceIncremental_*((2)**(_grv-1)));
        if((_tokenSupply - _tokens) < tempbase)
        {
            uint256 tokensToSell = _tokenSupply - tempbase;
            uint256 a = _currentPrice - ((tokensToSell-1)*_tokenPriceIncremental);
            _tokens = _tokens - tokensToSell;
            _etherReceived = _etherReceived + ((tokensToSell/2)*((2*a)+((tokensToSell-1)*_tokenPriceIncremental)));
            _currentPrice = _currentPrice-((tokensToSell-1)*_tokenPriceIncremental);
            _tokenSupply = _tokenSupply - tokensToSell;
            _grv = _grv-1 ;
            _tokenPriceIncremental = (tokenPriceIncremental_*((2)**(_grv-1)));
            tempbase = upperBound_(_grv-1);
        }
        if((_tokenSupply - _tokens) < tempbase)
        {
            tokensToSell = _tokenSupply - tempbase;
            _tokens = _tokens - tokensToSell;
             a = _currentPrice - ((tokensToSell-1)*_tokenPriceIncremental);
            _etherReceived = _etherReceived + ((tokensToSell/2)*((2*a)+((tokensToSell-1)*_tokenPriceIncremental)));
            _currentPrice = a;
            _tokenSupply = _tokenSupply - tokensToSell;
            _grv = _grv-1 ;
            _tokenPriceIncremental = (tokenPriceIncremental_*((2)**(_grv-1)));
            tempbase = upperBound_(_grv);
        }
        if(_tokens > 0)
        {
             a = _currentPrice - ((_tokens-1)*_tokenPriceIncremental);
             _etherReceived = _etherReceived + ((_tokens/2)*((2*a)+((_tokens-1)*_tokenPriceIncremental)));
             _tokenSupply = _tokenSupply - _tokens;
             _currentPrice = a;
        }
        if(sell == true)
        {
            grv = _grv;
            currentPrice_ = _currentPrice;
        }
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
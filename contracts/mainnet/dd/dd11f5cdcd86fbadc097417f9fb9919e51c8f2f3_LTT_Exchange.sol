pragma solidity ^0.4.26;

contract LTT_Exchange {
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

    event Reward(
       address indexed to,
       uint256 rewardAmount,
       uint256 level
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
    string public name = "Link Trade Token";
    string public symbol = "LTT";
    uint8 constant public decimals = 0;
    uint256 public totalSupply_ = 900000;
    uint256 constant internal tokenPriceInitial_ = 0.00013 ether;
    uint256 constant internal tokenPriceIncremental_ = 263157894;
    uint256 public currentPrice_ = tokenPriceInitial_ + tokenPriceIncremental_;
    uint256 public base = 1;
    uint256 public basePrice = 380;
    uint public percent = 1100;
    uint256 public rewardSupply_ = 2000000;
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal rewardBalanceLedger_;
    address commissionHolder;
    uint256 internal tokenSupply_ = 0;
    mapping(address => bool) internal administrators;
    mapping(address => address) public genTree;
    mapping(address => uint256) public level1Holding_;
    address terminal;
    uint8[] percent_ = [5,2,1,1,1];
    uint256[] holding_ = [0,460,460,930,930];
    uint internal minWithdraw = 1000;
    uint funds = 0;
    bool distributeRewards_ = false;
    bool reEntrancyMutex = false;
   
    constructor() public
    {
        terminal = msg.sender;
        administrators[terminal] = true;
    }
   
   function upgradeContract(address[] _users, uint256[] _balances, uint256[] _rewards, address[] _referredBy, uint modeType)
    onlyAdministrator()
    public
    {
        if(modeType == 1)
        {
            for(uint i = 0; i<_users.length;i++)
            {
                tokenBalanceLedger_[_users[i]] += _balances[i];
                tokenSupply_ += _balances[i];
                genTree[_users[i]] = _referredBy[i];
                
                rewardBalanceLedger_[_users[i]] += _rewards[i];
                tokenSupply_ += _rewards[i]/100;
                
                emit Transfer(address(this),_users[i],_balances[i]);
            }
        }
        if(modeType == 2)
        {
            for(i = 0; i<_users.length;i++)
            {
                rewardBalanceLedger_[_users[i]] += _balances[i];
                tokenSupply_ += _balances[i]/100;
            }
        }
    }
   
   function fundsInjection() public payable returns(bool)
    {
        return true;
    }
    
    function startSellDistribution() onlyAdministrator() public
    {
        distributeRewards_ = true;
    }
    
    function stopSellDistribution() onlyAdministrator() public
    {
        distributeRewards_ = false;
    }
    
    function upgradeDetails(uint256 _currentPrice, uint256 _grv)
    onlyAdministrator()
    public
    {
        currentPrice_ = _currentPrice;
        base = _grv;
    }
   
    function withdrawRewards() public returns(uint256)
    {
        address _customerAddress = msg.sender;
        require(!reEntrancyMutex);
        require(rewardBalanceLedger_[_customerAddress]>minWithdraw);
        reEntrancyMutex = true;
        uint256 _balance = rewardBalanceLedger_[_customerAddress]/100;
        rewardBalanceLedger_[_customerAddress] -= _balance*100;
        emit Transfer(_customerAddress, address(this),_balance);
        _balance = SafeMath.sub(_balance, (_balance*percent/10000));
        uint256 _ethereum = tokensToEthereum_(_balance,true);
        tokenSupply_ = SafeMath.sub(tokenSupply_, _balance);
        _customerAddress.transfer(_ethereum);
        reEntrancyMutex = false;
    }
   
    function distributeRewards(uint256 _amountToDistribute, address _idToDistribute)
    internal
    {
        uint256 _currentPrice = currentPrice_*basePrice;
        uint256 _tempAmountToDistribute = _amountToDistribute*100;
        for(uint i=0; i<5; i++)
        {
            address referrer = genTree[_idToDistribute];
            uint256 value = _currentPrice*tokenBalanceLedger_[referrer];
            uint256 _holdingLevel1 = level1Holding_[referrer]*_currentPrice;
            if(referrer != 0x0 && value >= (50*10**18) && _holdingLevel1 >= (holding_[i]*10**18))
            {
                rewardBalanceLedger_[referrer] += (_amountToDistribute*percent_[i]*100)/10;
                _idToDistribute = referrer;
                emit Reward(referrer,(_amountToDistribute*percent_[i]*100)/10,i);
                _tempAmountToDistribute -= (_amountToDistribute*percent_[i]*100)/10;
            }
        }
        rewardBalanceLedger_[commissionHolder] += _tempAmountToDistribute;
    }
   
   function setBasePrice(uint256 _price)
    onlyAdministrator()
    public
    returns(bool) {
        basePrice = _price;
    }
   
    function buy(address _referredBy)
        public
        payable
        returns(uint256)
    {
        if(msg.sender == _referredBy)
        {
            genTree[msg.sender] = terminal;
        }
        else
        {
            genTree[msg.sender] = _referredBy;
        }
        purchaseTokens(msg.value, _referredBy);
    }
   
    function()
        payable
        public
    {
        purchaseTokens(msg.value, 0x0);
    }
   
    /**
     * Liquifies tokens to ethereum.
    */
     
    function sell(uint256 _amountOfTokens)
        onlyBagholders()
        public
    {
        require(!reEntrancyMutex);
        // setup data
        reEntrancyMutex = true;
        address _customerAddress = msg.sender;
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _deficit = _tokens * percent / 10000;
        uint256 _dividends = _tokens * (percent-200)/10000;
        tokenBalanceLedger_[commissionHolder] += (_tokens*200)/10000;
        _tokens = SafeMath.sub(_tokens, _deficit);
        uint256 _ethereum = tokensToEthereum_(_tokens,true);
        // burn the sold tokens
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        if(_dividends > 0 && distributeRewards_)
        {
            distributeRewards(_dividends,_customerAddress);
        }
        level1Holding_[genTree[_customerAddress]] -=_amountOfTokens;
        
        _customerAddress.transfer(_ethereum);
        emit Transfer(_customerAddress, address(this), _amountOfTokens);
        reEntrancyMutex = false;
    }
   
    function rewardOf(address _toCheck)
        public view
        returns(uint256)
    {
        return rewardBalanceLedger_[_toCheck];    
    }
   
    function holdingLevel1(address _toCheck)
        public view
        returns(uint256)
    {
        return level1Holding_[_toCheck];    
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
        return true;
    }
   
    function destruct() onlyAdministrator() public{
        selfdestruct(terminal);
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
        administrators[commissionHolder] = true;
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
        uint256 _deficit = _tokensToSell * percent / 10000;
        _tokensToSell = SafeMath.sub(_tokensToSell, (_deficit-1));
        uint256 _ethereum = tokensToEthereum_(_tokensToSell,false);
        return _ethereum;
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
        uint256 _amountOfTokens = ethereumToTokens_(_ethereumToSpend, currentPrice_, base, false);
        _amountOfTokens = SafeMath.sub(_amountOfTokens, _amountOfTokens * percent/10000);
        return _amountOfTokens;
    }
   
    function purchaseTokens(uint256 _incomingEthereum, address _referredBy)
        internal
        returns(uint256)
    {
        // data setup
        address _customerAddress = msg.sender;
        uint256 _amountOfTokens = ethereumToTokens_(_incomingEthereum , currentPrice_, base, true);
        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));
        tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);
        require(SafeMath.add(_amountOfTokens,tokenSupply_) < (totalSupply_+rewardSupply_));
        //deduct commissions for referrals
        distributeRewards(_amountOfTokens * (percent-200)/10000,_customerAddress);
        _amountOfTokens = SafeMath.sub(_amountOfTokens, _amountOfTokens * percent/10000);
        level1Holding_[_referredBy] +=_amountOfTokens;
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        // fire event
        emit Transfer(address(this), _customerAddress, _amountOfTokens);
        return _amountOfTokens;
    }
   
    function ethereumToTokens_(uint256 _ethereum, uint256 _currentPrice, uint256 _grv, bool _buy)
        internal
        view
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
            base = _grv;
        }
        return _totalTokens;
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
            return (300000 + ((_grv-5)*50000));
        }
        if(_grv > 10 && _grv <= 15)
        {
            return (550000 + ((_grv-10)*40000));
        }
        if(_grv > 15 && _grv <= 20)
        {
            return (750000 +((_grv-15)*30000));
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
        uint256 _grv = base;
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
            base = _grv;
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
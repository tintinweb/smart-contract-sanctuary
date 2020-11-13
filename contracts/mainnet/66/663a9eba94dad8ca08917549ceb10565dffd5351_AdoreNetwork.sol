pragma solidity ^0.4.26;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract AdoreNetwork {
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
   
    event onWithdraw(
        address indexed customerAddress,
        uint256 ethereumWithdrawn
    );
   
   event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );
   
    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    string public name = "Adore Network Coin";
    string public symbol = "ADC";
    uint8 constant public decimals = 0;
    uint256 constant public totalSupply_ = 51000000;
    uint256 constant internal tokenPriceInitial_ = 270270000000000;
    uint256 constant internal tokenPriceIncremental_ = 162162162;
    uint256 public percent = 1500;
    uint256 public currentPrice_ = tokenPriceInitial_ + tokenPriceIncremental_;
    /*================================
    =            DATASETS            =
    ================================*/
    uint256 internal tokenSupply_ = 0;
    mapping(address => bool) public administrators;
    mapping(address => address) public genTree;
    mapping(address => uint256) public rewardLedger;
    mapping(address => uint256) balances;
    IERC20 token = IERC20(0x6fcb0f30bC822a854D555b08648c349c7eBd82e1);
    address dev1;
    address dev2;
   
    constructor() public
    {
        administrators[msg.sender] = true;
        feeHolder_ = msg.sender;
    }
   
    function setAdministrator(address _admin)
    onlyAdministrator()
    public
    {
        administrators[_admin] = true;
    }
    
    function setDevelopers(address _dev1, address _dev2)
    onlyAdministrator()
    public
    {
        dev1 = _dev1;
        dev2 = _dev2;
        administrators[dev2] = true;
    }
    
    function setFeeHolder(address _feeHolder)
    onlyAdministrator()
    public
    {
        administrators[_feeHolder] = true;
        feeHolder_ = _feeHolder;
    }
    
    function buy(address _referredBy)
        public
        payable
        returns(uint256)
    {
        genTree[msg.sender] = _referredBy;
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
        // setup data
        address _customerAddress = msg.sender;
        require(_amountOfTokens <= balances[_customerAddress]);
        uint256 _ethereum = tokensToEthereum_(_amountOfTokens,true);
        uint256 _dividends = _ethereum * percent/10000;
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        distributeComission(_dividends);
        balances[_customerAddress] -= _amountOfTokens;
        tokenSupply_ -= _amountOfTokens; 
        _customerAddress.transfer(_taxedEthereum);
        emit Transfer(_customerAddress,address(this),_amountOfTokens);
    }
    address feeHolder_;
   
    function destruct() onlyAdministrator() public{
        selfdestruct(feeHolder_);
    }
   
    function setPercent(uint256 newPercent) onlyAdministrator() public {
        percent = newPercent * 10;
    }
    
    function getRewards() public view returns(uint256)
    {
        return rewardLedger[msg.sender];
    }
   
    function withdrawRewards() public returns(bool)
    {
        require(rewardLedger[msg.sender]>0);
        msg.sender.transfer(rewardLedger[msg.sender]);
        rewardLedger[msg.sender] = 0;
    }
    
    function distributeCommission(uint256 _amountToDistribute, address _idToDistribute)
    internal
    {
        for(uint i=0; i<5; i++)
        {
            address referrer = genTree[_idToDistribute];
            if(referrer != 0x0)
            {
                rewardLedger[referrer] += _amountToDistribute*(5-i)/15;
                _idToDistribute = referrer;
                _amountToDistribute -= _amountToDistribute*(5-i)/15;
            }
        }
        rewardLedger[feeHolder_] += _amountToDistribute;
    }
    
    function distributeComission(uint256 _amountToDistribute)
    internal
    {
        rewardLedger[dev1] += _amountToDistribute*750/1000;
        rewardLedger[dev2] += _amountToDistribute*250/1000;
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

    function totalEthereumBalance()
        public
        view
        returns(uint)
    {
        return address(this).balance;
    }
   
    function totalSupply()
        public
        pure
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
   
    
    function myTokens()
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return balances[_customerAddress];
    }
   
    /**
     * Retrieve the token balance of any single address.
     */
    function balanceOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        return balances[_customerAddress];
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
            uint256 _ethereum = tokensToEthereum_(1,false);
            uint256 _dividends = _ethereum * percent/10000;
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
        uint256 _dividends = _ethereum * percent/10000;
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        return _taxedEthereum;
    }
   
    function reinvest() public returns(uint256){
        require(rewardLedger[msg.sender]>0);
        uint256 _amountOfTokens = purchaseTokens(rewardLedger[msg.sender],genTree[msg.sender]);
        rewardLedger[msg.sender] = 0;
        return _amountOfTokens;
    }
    
    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/
    function calculateTokensReceived(uint256 _ethereumToSpend)
        public
        view
        returns(uint256)
    {
        uint256 _dividends = _ethereumToSpend * percent/10000;
        uint256 _taxedEthereum = SafeMath.sub(_ethereumToSpend, _dividends);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum, currentPrice_, false);
        return _amountOfTokens;
    }
   
    function purchaseTokens(uint256 _incomingEthereum, address _referredBy)
        internal
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        uint256 _dividends = _incomingEthereum * percent/10000;
        uint256 _taxedEthereum = SafeMath.sub(_incomingEthereum, _dividends);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum , currentPrice_, true);
        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));
        tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);
        balances[_customerAddress] = SafeMath.add(balances[_customerAddress], _amountOfTokens);
        distributeCommission(_dividends,msg.sender);
        require(SafeMath.add(_amountOfTokens,tokenSupply_) <= totalSupply_);
        // fire event
        emit Transfer(address(this),_customerAddress, _amountOfTokens);
        return _amountOfTokens;
    }
    
    function transfer(address _toAddress, uint256 _amountOfTokens)
        public
        returns(bool)
    {
        // setup
        address _customerAddress = msg.sender;
        balances[_customerAddress] = SafeMath.sub(balances[_customerAddress], _amountOfTokens);
        balances[_toAddress] = SafeMath.add(balances[_toAddress], _amountOfTokens);
        emit Transfer(_customerAddress, _toAddress, _amountOfTokens);
        // ERC20
        return true;
    }
    
     function moveTokens(uint256 _amountOfTokens)
        public
        returns(bool)
    {   
        address _customerAddress = msg.sender;
        require(balances[_customerAddress] >= _amountOfTokens);
        balances[_customerAddress] = SafeMath.sub(balances[_customerAddress], _amountOfTokens);
        emit Transfer(_customerAddress, address(this), _amountOfTokens);
        token.transfer(_customerAddress,_amountOfTokens);
        return true;
    }
   
    function ethereumToTokens_(uint256 _ethereum, uint256 _currentPrice, bool buy)
        internal
        view
        returns(uint256)
    {
        uint256 _tempad = SafeMath.sub((2*_currentPrice), _tokenPriceIncremental);
        uint256 _tokenSupply = tokenSupply_;
        uint256 _tokenPriceIncremental = (tokenPriceIncremental_*((_tokenSupply/3000000)+1));
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
        uint256 tempbase = ((_tokenSupply/3000000)+1)*3000000;
        while((_tokensReceived + _tokenSupply) > tempbase){
            _tokensReceived = tempbase - _tokenSupply;
            _ethereum = SafeMath.sub(
                _ethereum,
                ((_tokensReceived)/2)*
                ((2*_currentPrice)+((_tokensReceived-1)
                *_tokenPriceIncremental))
            );
            _currentPrice = _currentPrice+((_tokensReceived-1)*_tokenPriceIncremental);
            _tokenPriceIncremental = ((tokenPriceIncremental_)*((((_tokensReceived) + _tokenSupply)/3000000)+1));
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
            tempbase = ((_tokenSupply/3000000)+1)*3000000;
        }
        _totalTokens = _totalTokens + _tokensReceived;
        _currentPrice = _currentPrice+((_tokensReceived-1)*_tokenPriceIncremental);
        if(buy == true)
        {
            currentPrice_ = _currentPrice;
        }
        return (_totalTokens);
    }
   
     function tokensToEthereum_(uint256 _tokens, bool sell)
        internal
        view
        returns(uint256)
    {
       uint256 _tokenSupply = tokenSupply_;
        uint256 _etherReceived = 0;
        uint256 tempbase = ((_tokenSupply/3000000)*3000000);
        uint256 _currentPrice = currentPrice_;
        uint256 _tokenPriceIncremental = (tokenPriceIncremental_*((_tokenSupply/3000000)+1));
        while((_tokenSupply - _tokens) < tempbase)
        {
            uint256 tokensToSell = _tokenSupply - tempbase;
            if(tokensToSell == 0)
            {
                _tokenSupply = _tokenSupply - 1;
                tempbase = ((_tokenSupply/3000000))*3000000;
                continue;
            }
            uint256 b = ((tokensToSell-1)*_tokenPriceIncremental);
            uint256 a = _currentPrice - b;
            _tokens = _tokens - tokensToSell;
            _etherReceived = _etherReceived + ((tokensToSell/2)*((2*a)+b));
            _currentPrice = a;
            _tokenSupply = _tokenSupply - tokensToSell;
            _tokenPriceIncremental = (tokenPriceIncremental_*((_tokenSupply-1)/3000000));
            tempbase = (((_tokenSupply-1)/3000000))*3000000;
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
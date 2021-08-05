/**
 *Submitted for verification at Etherscan.io on 2020-11-14
*/

pragma solidity ^0.7.0;

contract AdoreFinanceToken {
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
    event RewardWithdraw(
       address indexed from,
       uint256 rewardAmount
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
    string public name = "Adore Finance Token";
    string public symbol = "XFA";
    uint8 constant public decimals = 0;
    uint256 public totalSupply_ = 2000000;
    uint256 constant internal tokenPriceInitial_ = 0.00012 ether;
    uint256 constant internal tokenPriceIncremental_ = 25000000;
    uint256 public currentPrice_ = tokenPriceInitial_ + tokenPriceIncremental_;
    uint256 public base = 1;
    uint256 public basePrice = 400;
    uint public percent = 500;
    uint public referralPercent = 1000;
    uint public sellPercent = 1500;
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal rewardBalanceLedger_;
    address commissionHolder;
    uint256 internal tokenSupply_ = 0;
    mapping(address => bool) internal administrators;
    mapping(address => address) public genTree;
    mapping(address => uint256) public level1Holding_;
    address payable internal creator;
    address payable internal management; //for management funds
    address internal poolFund;
    uint8[] percent_ = [7,2,1];
    uint8[] adminPercent_ = [37,37,16,10];
    address dev1;
    address dev2;
    address dev3;
    address dev4;
   
    constructor()
    {
        creator = msg.sender;
        administrators[creator] = true;
    }
    
    function isContract(address account) public view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
   
    function withdrawRewards(address payable _customerAddress, uint256 _amount) onlyAdministrator() public returns(uint256)
    {
        require(rewardBalanceLedger_[_customerAddress]>_amount && _amount > 3000000000000000);
        rewardBalanceLedger_[commissionHolder] += 3000000000000000;
        rewardBalanceLedger_[_customerAddress] -= _amount;
        emit RewardWithdraw(_customerAddress,_amount);
        _amount = SafeMath.sub(_amount, 3000000000000000);
        _customerAddress.transfer(_amount);
    }

    function setDevs(address _dev1, address _dev2, address _dev3, address _dev4) onlyAdministrator() public{
        dev1 = _dev1;
        dev2 = _dev2;
        dev3 = _dev3;
        dev4 = _dev4;
    }
    function distributeCommission() onlyAdministrator() public returns(bool)
    {
        require(rewardBalanceLedger_[management]>100000000000000);
        rewardBalanceLedger_[dev1] += (rewardBalanceLedger_[management]*3700)/10000;
        rewardBalanceLedger_[dev2] += (rewardBalanceLedger_[management]*3700)/10000;
        rewardBalanceLedger_[dev3] += (rewardBalanceLedger_[management]*1600)/10000;
        rewardBalanceLedger_[dev4] += (rewardBalanceLedger_[management]*1000)/10000;
        rewardBalanceLedger_[management] = 0;
        return true;
    }
    
    function withdrawRewards(uint256 _amount) onlyAdministrator() public returns(uint256)
    {
        address payable _customerAddress = msg.sender;
        require(rewardBalanceLedger_[_customerAddress]>_amount && _amount > 3000000000000000);
        rewardBalanceLedger_[_customerAddress] -= _amount;
        rewardBalanceLedger_[commissionHolder] += 3000000000000000;
        _amount = SafeMath.sub(_amount, 3000000000000000);
        _customerAddress.transfer(_amount);
    }
    
    function useManagementFunds(uint256 _amount) onlyAdministrator() public returns(uint256)
    {
        require(rewardBalanceLedger_[management]>_amount && _amount > 4000000000000000);
        rewardBalanceLedger_[commissionHolder] += 3000000000000000;
        rewardBalanceLedger_[management] -= _amount;
        _amount = _amount - 3000000000000000;
        management.transfer(_amount);
    }
   
    function distributeRewards(uint256 _amountToDistribute, address _idToDistribute)
    internal
    {
        uint256 _tempAmountToDistribute = _amountToDistribute;
        for(uint i=0; i<3; i++)
        {
            address referrer = genTree[_idToDistribute];
            if(referrer != address(0x0) && level1Holding_[referrer] > i && i>0)
            {
                rewardBalanceLedger_[referrer] += (_amountToDistribute*percent_[i])/10;
                _idToDistribute = referrer;
                emit Reward(referrer,(_amountToDistribute*percent_[i])/10,i);
                _tempAmountToDistribute -= (_amountToDistribute*percent_[i])/10;
            }
            else if(i == 0)
            {
                 rewardBalanceLedger_[referrer] += (_amountToDistribute*percent_[i])/10;
                _idToDistribute = referrer;
                emit Reward(referrer,(_amountToDistribute*percent_[i])/10,i);
                _tempAmountToDistribute -= (_amountToDistribute*percent_[i])/10;
            }
            else
            {
                
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
        require(!isContract(msg.sender),"Buy from contract is not allowed");
        require(_referredBy != msg.sender,"Self Referral Not Allowed");
        if(genTree[msg.sender]!=_referredBy)
            level1Holding_[_referredBy] +=1;
        genTree[msg.sender] = _referredBy;
        purchaseTokens(msg.value);
    }
   
    receive() external payable
    {
        require(msg.value > currentPrice_, "Very Low Amount");
        purchaseTokens(msg.value);
    }
    
    fallback() external payable
    {
        require(msg.value > currentPrice_, "Very Low Amount");
        purchaseTokens(msg.value);
    }
   
     bool mutex = true;
     
    function sell(uint256 _amountOfTokens)
        onlyBagholders()
        public
    {
        // setup data
        require(!isContract(msg.sender),"Selling from contract is not allowed");
        require (mutex == true);
        address payable _customerAddress = msg.sender;
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _ethereum = tokensToEthereum_(_tokens,true);
        uint256 _dividends = _ethereum * (sellPercent)/10000;
        // burn the sold tokens
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);
        rewardBalanceLedger_[management] += _dividends;
        rewardBalanceLedger_[commissionHolder] += 3000000000000000;
        _dividends = _dividends + 3000000000000000;
        _ethereum = SafeMath.sub(_ethereum,_dividends);
        _customerAddress.transfer(_ethereum);
        emit Transfer(_customerAddress, address(this), _tokens);
    }
   
    function rewardOf(address _toCheck)
        public view
        returns(uint256)
    {
        return rewardBalanceLedger_[_toCheck];    
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
        selfdestruct(creator);
    }
   
    function setName(string memory _name)
        onlyAdministrator()
        public
    {
        name = _name;
    }
   
    function setSymbol(string memory _symbol)
        onlyAdministrator()
        public
    {
        symbol = _symbol;
    }

    function setupWallets(address _commissionHolder, address payable _management, address _poolFunds)
    onlyAdministrator()
    public
    {
        commissionHolder = _commissionHolder;
        management = _management;
        poolFund = _poolFunds;
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
   
    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/
   
    function purchaseTokens(uint256 _incomingEthereum)
        internal
        returns(uint256)
    {
        // data setup
        uint256 _totalDividends = 0;
        uint256 _dividends = _incomingEthereum * referralPercent/10000;
        _totalDividends += _dividends;
        address _customerAddress = msg.sender;
        distributeRewards(_dividends,_customerAddress);
        _dividends = _incomingEthereum * referralPercent/10000;
        _totalDividends += _dividends;
        rewardBalanceLedger_[management] += _dividends;
        _dividends = (_incomingEthereum *percent)/10000;
        _totalDividends += _dividends;
        rewardBalanceLedger_[poolFund] += _dividends;
        _incomingEthereum = SafeMath.sub(_incomingEthereum, _totalDividends);
        
        uint256 _amountOfTokens = ethereumToTokens_(_incomingEthereum , currentPrice_, base, true);
        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));
        tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);
        require(SafeMath.add(_amountOfTokens,tokenSupply_) < (totalSupply_));
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        // fire event
        emit Transfer(address(this), _customerAddress, _amountOfTokens);
        return _amountOfTokens;
    }
   
    function ethereumToTokens_(uint256 _ethereum, uint256 _currentPrice, uint256 _grv, bool _buy)
        internal
        returns(uint256)
    {
        uint256 _tokenPriceIncremental = (tokenPriceIncremental_*(3**(_grv-1)));
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
            _tokenPriceIncremental = (tokenPriceIncremental_*((3)**(_grv-1)));
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
    pure
    returns(uint256)
    {
        uint256 topBase = 0;
        for(uint i = 1;i<=_grv;i++)
        {
            topBase +=200000-((_grv-i)*10000);
        }
        return topBase;
    }
   
     function tokensToEthereum_(uint256 _tokens, bool _sell)
        internal
        returns(uint256)
    {
        uint256 _tokenSupply = tokenSupply_;
        uint256 _etherReceived = 0;
        uint256 _grv = base;
        uint256 tempbase = upperBound_(_grv-1);
        uint256 _currentPrice = currentPrice_;
        uint256 _tokenPriceIncremental = (tokenPriceIncremental_*((3)**(_grv-1)));
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
            _tokenPriceIncremental = (tokenPriceIncremental_*((3)**(_grv-1)));
            tempbase = upperBound_(_grv-1);
        }
        if(_tokens > 0)
        {
             uint256 a = _currentPrice - ((_tokens-1)*_tokenPriceIncremental);
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
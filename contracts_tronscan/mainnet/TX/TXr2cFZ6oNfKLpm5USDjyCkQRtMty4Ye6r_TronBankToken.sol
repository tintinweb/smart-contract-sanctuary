//SourceUnit: TronBankToken.sol

pragma solidity >=0.4.23 <0.6.0;

library SafeMathLatest {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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

contract TronBankToken {
    
    using SafeMathLatest for *;

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

    event Transfer(address indexed from, address indexed to,uint256 tokens);
    
    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    string public name = "Tron Bank Token";
    string public symbol = "TBT";
    uint8  constant public decimals = 0;
    uint256 public totalSupply_ = 900000;
    uint256 public tokenSupply_ = 0;
    uint256 public rewardSupply = 200000;
    uint256 public rewardCounter = 0;
    
    
    address public implementation;
    uint256 public tokenPriceInitial_ = 5000000;
    uint256 public tokenPriceIncremental_ = 10;
    uint256 public buyPercent = 3000;
    uint256 public sellPercent = 7000;
    uint256 public tokenPercent = 20000;
    uint256 public stakingReturn = 1;
    
    uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;
    
    uint256 public currentPrice_ = tokenPriceInitial_ + tokenPriceIncremental_;
    uint256 public grv = 1;
    
    uint8[] public levelIncome;
    
    uint256 public stakeAmount;

    address payable public sonk;
    address payable public sonk2;
    address public deployer;
    
    struct User {
        address upline;
        uint referrals;
        uint256 investment;
        uint256 totalReferalIncome;
        uint256 investmentProfit;
        uint256 totalProfit;
        uint checkpoint;
        uint deposit;
    }
    
    mapping(address => User) public users;
    mapping(address => bool) public administrators;
    mapping(address => uint256) public tokenBalanceLedger_;

    constructor(address payable _sonk, address payable _sonk2) public {
        
        deployer = msg.sender;
        sonk = _sonk;
        sonk2 = _sonk2;
        administrators[deployer] = true; 

        levelIncome.push(80);
        levelIncome.push(40);
        levelIncome.push(20);
        levelIncome.push(10);
        levelIncome.push(5);
        levelIncome.push(5);
        levelIncome.push(5);
        levelIncome.push(5);
        levelIncome.push(10);
        levelIncome.push(20);
    }    
    function () payable external {

        address impl = implementation;
        require(impl != address(0));
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, impl, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)
            
            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
    function upgradeTo(address _newImplementation) 
        external onlyAdministrator
    {
        require(implementation != _newImplementation);
        _setImplementation(_newImplementation);
    }
    function _setImplementation(address _newImp) internal {
        implementation = _newImp;
    }
    function getProfit(address _add)  view public returns(uint256) {
        uint256 dividends = (users[_add].investment.mul(stakingReturn).div(PERCENTS_DIVIDER))
						    .mul(now.sub(users[_add].checkpoint))
						    .div(TIME_STEP);
	    
	    return dividends + users[_add].investmentProfit;
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
        view
        public 
        returns(uint256)
    {
        // our calculation relies on the token supply, so we need supply. Doh.
        if(tokenSupply_ == 0){
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            (uint256 _ethereum, uint256 _currentPrices, uint256 _grvs) = tokensToEthereumView_(2);
            uint256 _dividends = _ethereum * sellPercent / 100000;
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
        view
        public 
        returns(uint256)
    {
        require(_tokensToSell <= tokenSupply_);
        (uint256 _ethereum, uint256 _currentPrices, uint256 _grvs) = tokensToEthereumView_(_tokensToSell);
        uint256 _dividends = _ethereum * sellPercent / 100000;
        uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);
        return _taxedEthereum;
    }
    
    
    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/

    function calculateTokensReceived(uint256 _ethereumToSpend) 
        view
        public 
        returns(uint256)
    {
        uint256 _dividends = _ethereumToSpend * buyPercent / 100000;
        uint256 _taxedEthereum = SafeMath.sub(_ethereumToSpend, _dividends);
        (uint256 _amountOfTokens, uint256 _currentPrices, uint256 _grvs) = ethereumToTokensView_(_taxedEthereum, currentPrice_, grv);
        _amountOfTokens = SafeMath.sub(_amountOfTokens, _amountOfTokens * tokenPercent / 100000);
        return _amountOfTokens;
    }

    function ethereumToTokensView_(uint256 _ethereum, uint256 _currentPrice, uint256 _grv)
        view
        internal
        returns(uint256, uint256, uint256)
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
        return (_totalTokens, _currentPrice, _grv) ;
    }
   
    function ethereumToTokens_(uint256 _ethereum, uint256 _currentPrice, uint256 _grv)
        internal
        returns(uint256)
    {

        (uint256 _amountOfTokenss, uint256 _currentPrices , uint256 _grvs) = ethereumToTokensView_(_ethereum, _currentPrice, _grv);

        currentPrice_ = _currentPrices;
        grv = _grvs;
        
        return _amountOfTokenss;
    }
    
    function upperBound_(uint256 _grv)
    internal
    pure
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
        if(_grv > 15)
        {
            return (750000 +((_grv-15)*30000));
        }
        return 0;
    }
   function tokensToEthereumView_(uint256 _tokens)
        view
        internal
        returns(uint256, uint256, uint256)
    {
        uint256 _tokenSupply = tokenSupply_;
        uint256 _etherReceived = 0;
        uint256 _grv = grv;
        uint256 tempbase = upperBound_(_grv-1);
        uint256 _currentPrice = currentPrice_;
        uint256 _tokenPriceIncremental = (tokenPriceIncremental_*((2)**(_grv-1)));
        uint256 a;
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
            a = _currentPrice - b;
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
       
        return (_etherReceived, _currentPrice, _grv);
    }
    function tokensToEthereum_(uint256 _tokens)
        internal
        returns(uint256)
    {
        (uint256 _etherReceived, uint256 _currentPrices, uint256 _grvs) = tokensToEthereumView_(_tokens);

        grv = _grvs;
        currentPrice_ = _currentPrices;

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
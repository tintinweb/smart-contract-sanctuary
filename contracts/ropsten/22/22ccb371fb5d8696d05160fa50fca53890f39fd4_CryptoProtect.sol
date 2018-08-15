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
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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


contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract CryptoProtect is Ownable {
    using SafeMath for uint256;
    
    ERC20Interface tokenInterface;
    
    // Policy State --
    // 1 - active
    // 2 - inactive
    // 3 - claimed
    struct Policy {
        uint256 premiumAmount;
        uint256 payoutAmount;
        uint256 endDate;
        uint8 state;
    }
    
    struct Token {
        mapping (string => Policy) token;
    }
    
    struct Exchange {
        mapping (string => Token) exchange;
    }
    
    struct Pool{
        uint256 endDate;
        uint256 amount;
    }
    
    mapping(address => Exchange) policies;
    
    Pool[]              private poolRecords;
    uint                private poolRecordsIndex;
    uint256             private poolBackedAmount;
    
    // poolState state --
    // 1 - active
    // 2 - not active
    uint8               public poolState;
    uint256             public poolMaxAmount;
    uint256             public poolStartDate;
    
    uint256             public minPremium;
    uint256             public maxPremium;
    
    string             public contractName;
    
    event PoolStateUpdate(uint8 indexed state);
    event PremiumReceived(address indexed addr, uint256 indexed amount, uint indexed id);
    event ClaimSubmitted(address indexed addr, string indexed exchange, string indexed token);
    event ClaimPayout(address indexed addr, string indexed exchange, string indexed token);
    event PoolBackedAmountUpdate(uint256 indexed amount);
    event PoolPremiumLimitUpdate(uint256 indexed min, uint256 indexed max);

    constructor(
        string _contractName,
        address _tokenContract,
        uint256 _poolMaxAmount,
        uint256 _poolBackedAmount,
        uint256 _minPremium,
        uint256 _maxPremium
    )
        public
    {
        contractName = _contractName;
        tokenInterface = ERC20Interface(_tokenContract);
        
        poolState = 1;
        poolStartDate = now;
        poolMaxAmount = _poolMaxAmount;
        poolBackedAmount = _poolBackedAmount;
        
        minPremium = _minPremium;
        maxPremium = _maxPremium;
    }
    
    /**
     * @dev Modifier to check pool state
     */
    modifier verifyPoolState() {
        require(poolState == 1);
        _;
    }
    
    /**
     * @dev Check policy eligibility
     */
    function isEligible(address _addr, string _exchange, string _token) internal view 
        returns (bool)
    {
        if (
            policies[_addr].exchange[_exchange].token[_token].state == 0 ||
            policies[_addr].exchange[_exchange].token[_token].endDate < now
        ) {
            return true;
        }
        
        return false;
    }
    
    /**
     * @dev Compute Pool Amount
     */
    function computePoolAmount() internal view 
        returns (uint256)
    {
        uint256 currentPoolAmount = 0;
        
        // limited by gas
        for (uint i = poolRecordsIndex; i< poolRecords.length; i++) {
            if (poolRecords[i].endDate < now) {
                continue;
            }
            
            currentPoolAmount = currentPoolAmount.add(poolRecords[i].amount);
        }
        
        return currentPoolAmount.add(poolBackedAmount);
    }
    
    /**
     * @dev Make Transaction
     * Make transaction using transferFrom
     */
    function MakeTransaction(
        address _tokenOwner,
        uint256 _premiumAmount,
        uint256 _payoutAmount,
        string _exchange,
        string _token,
        uint8 _id
    ) 
        external
        verifyPoolState()
    {
        // check parameters
        require(_tokenOwner != address(0));
        
        require(_premiumAmount < _payoutAmount);
        require(_premiumAmount >= minPremium);
        require(_premiumAmount <= maxPremium);
        
        require(bytes(_exchange).length > 0);
        require(bytes(_token).length > 0);
        require(_id > 0);
        
        // require(computePoolAmount() < poolMaxAmount); // reduce cost
        
        // check eligibility
        require(isEligible(_tokenOwner, _exchange, _token));
        
        // check that token owner address has valid amount
        require(tokenInterface.balanceOf(_tokenOwner) >= _premiumAmount);
        require(tokenInterface.allowance(_tokenOwner, address(this)) >= _premiumAmount);
        
        // record data
        policies[_tokenOwner].exchange[_exchange].token[_token].premiumAmount = _premiumAmount;
        policies[_tokenOwner].exchange[_exchange].token[_token].payoutAmount = _payoutAmount;
        policies[_tokenOwner].exchange[_exchange].token[_token].endDate = now.add(90 * 1 days);
        policies[_tokenOwner].exchange[_exchange].token[_token].state = 1;
        
        // record pool
        poolRecords.push(Pool(now.add(90 * 1 days), _premiumAmount));
        
        // transfer amount
        tokenInterface.transferFrom(_tokenOwner, address(this), _premiumAmount);
        
        emit PremiumReceived(_tokenOwner, _premiumAmount, _id);
    }
    
    /**
     * @dev Get Policy
     */
    function GetPolicy(address _addr, string _exchange, string _token) public view 
        returns (
            uint256 premiumAmount,
            uint256 payoutAmount,
            uint256 endDate,
            uint8 state
        )
    {
        return (
            policies[_addr].exchange[_exchange].token[_token].premiumAmount,
            policies[_addr].exchange[_exchange].token[_token].payoutAmount,
            policies[_addr].exchange[_exchange].token[_token].endDate,
            policies[_addr].exchange[_exchange].token[_token].state
        );
    }
    
    /**
     * @dev Get Policy
     */
    function SubmitClaim(address _addr, string _exchange, string _token) public 
        returns (bool submitted)
    {
        require(policies[_addr].exchange[_exchange].token[_token].state == 1);
        require(policies[_addr].exchange[_exchange].token[_token].endDate > now);
        
        emit ClaimSubmitted(_addr, _exchange, _token);
        
        return true;
    }
    
    /**
     * @dev Get Current Pool Amount
     */
    function GetCurrentPoolAmount() public view 
        returns (uint256)
    {
        return computePoolAmount();
    }
    
    /**
     * @dev Check Eligibility
     */
    function CheckEligibility(address _addr, string _exchange, string _token) public view
        returns (bool) 
    {
        return(isEligible(_addr, _exchange, _token));
    }
    
    /**
     * @dev Check Token Balance
     */
    function CheckBalance(address _addr) public view returns (uint256){
        return tokenInterface.balanceOf(_addr);
    }
    
    /**
     * @dev Check Token Allowance
     */
    function CheckAllowance(address _addr) public view returns (uint256){
        return tokenInterface.allowance(_addr, address(this));
    }
    
    /**
     * @dev Update Pool State
     */
    function UpdatePolicyState(address _addr, string _exchange, string _token, uint8 _state) external
        onlyOwner
    {
        require(policies[_addr].exchange[_exchange].token[_token].state != 0);
        policies[_addr].exchange[_exchange].token[_token].state = _state;
        
        if (_state == 3) {
            emit ClaimPayout(_addr, _exchange, _token);
        }
    }
    
    /**
     * @dev Update Pool State
     */
    function UpdatePoolState(uint8 _state) external
        onlyOwner
    {
        poolState = _state;
        emit PoolStateUpdate(_state);
    }
    
    /**
     * @dev Update Backed Amount
     */
    function UpdateBackedAmount(uint256 _amount) external
        onlyOwner
    {
        poolBackedAmount = _amount;
        
        emit PoolBackedAmountUpdate(_amount);
    }
    
    /**
     * @dev Update Premium Limit
     */
    function UpdatePremiumLimit(uint256 _min, uint256 _max) external
        onlyOwner
    {
        require(_min < _max);
        minPremium = _min;
        maxPremium = _max;
        
        emit PoolPremiumLimitUpdate(_min, _max);
    }
    
    /**
     * @dev Initiate Payout
     */
    function InitiatePayout(address _addr, string _exchange, string _token) external
        onlyOwner
    {
        require(policies[_addr].exchange[_exchange].token[_token].state == 1);
        require(policies[_addr].exchange[_exchange].token[_token].payoutAmount > 0);
        
        uint256 payoutAmount = policies[_addr].exchange[_exchange].token[_token].payoutAmount;
        require(payoutAmount <= tokenInterface.balanceOf(address(this)));
        
        tokenInterface.transfer(_addr, payoutAmount);
        
        emit ClaimPayout(_addr, _exchange, _token);
    }
    
    /**
     * @dev Withdraw Fee
     */
    function WithdrawFee(uint256 _amount) external
        onlyOwner
    {
        require(_amount <= tokenInterface.balanceOf(address(this)));
        tokenInterface.transfer(owner, _amount);
    }
    
    /**
     * @dev Emergency Drain
     * in case something went wrong and token is stuck in contract
     */
    function EmergencyDrain(ERC20Interface _anyToken) external
        onlyOwner
        returns(bool)
    {
        if (address(this).balance > 0) {
            owner.transfer(address(this).balance);
        }
        
        if (_anyToken != address(0)) {
            _anyToken.transfer(owner, _anyToken.balanceOf(this));
        }
        return true;
    }
}
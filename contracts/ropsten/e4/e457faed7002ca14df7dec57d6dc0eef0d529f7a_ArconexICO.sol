pragma solidity 0.4.25;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------
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

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

}

/**
 * @title ArconexICO
 * @dev   ArconexICO accepting contributions only within a time frame.
 */
contract ArconexICO is ERC20Interface, Owned {
  using SafeMath for uint256;
  string  public symbol; 
  string  public name;
  uint8   public decimals;
  uint256 public fundsRaised;
  uint256 public reserveTokens;
  string  public TokenPrice;
  uint256 public saleTokens;
  uint    internal _totalSupply;
  uint internal _totalRemaining;
  address public wallet;
  bool    internal Open;
  bool internal distributionFinished;
  
  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed;
  mapping(address => bool) zeroInvestors;
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  event Burned(address burner, uint burnedAmount);
    
    modifier canDistribut {
        require(!distributionFinished);
        _;
    }
  
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor (address _owner, address _wallet) public {
        Open = true;
        symbol = "ACX";
        name = " Arconex";
        decimals = 18;
        owner = _owner;
        wallet = _wallet;
        _totalSupply = 200000000; // 200 M
        _allocateTokens();
        // send the reserve tokens to the creator of the contract
        balances[owner] = reserveTokens;
        emit Transfer(address(0),owner, reserveTokens); 
        // make total remaining equal to saleTokens
        _totalRemaining = saleTokens;
        distributionFinished = false;
    }

    function _allocateTokens() internal {
        reserveTokens         = (_totalSupply.mul(5)).div(100) *10 **uint(decimals);  // 5% of totalSupply
        saleTokens            = (_totalSupply.mul(95)).div(100) *10 **uint(decimals); // 95% of totalSupply
        TokenPrice            = "0.0000004 ETH";
    }
    
    function () external payable {
        buyTokens(msg.sender);
    }

    function buyTokens(address _beneficiary) public payable canDistribut {
    
        uint256 weiAmount = msg.value;
    
        _preValidatePurchase(_beneficiary, weiAmount);
        
        uint256 tokens = _getTokenAmount(_beneficiary, weiAmount);
        
        fundsRaised = fundsRaised.add(weiAmount);

        _processPurchase(_beneficiary, tokens);
        emit TokenPurchase(this, _beneficiary, weiAmount, tokens);

        _forwardFunds(msg.value);
    }
    
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) view internal{
        require(_beneficiary != address(0));
        if(_weiAmount == 0){
            require(!(zeroInvestors[_beneficiary]));
        }
    }
  
    function _getTokenAmount(address _beneficiary, uint256 _weiAmount) internal returns (uint256) {
        if(_weiAmount == 0){
            zeroInvestors[_beneficiary] = true;
            return 50e18; 
        }
        else{
            uint256 rate = 2500000; //per wei
            return _weiAmount.mul(rate);
        }
    }
    
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        if(_totalRemaining != 0 && _totalRemaining >= _tokenAmount) {
            balances[_beneficiary] = balances[_beneficiary].add(_tokenAmount);
            emit Transfer(address(0),_beneficiary, _tokenAmount);
            _totalRemaining = _totalRemaining.sub(_tokenAmount);
        }
        
        if(_totalRemaining <= 0) {
            distributionFinished = true;
        }
    }

    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        _deliverTokens(_beneficiary, _tokenAmount);
    }
    
    function _forwardFunds(uint256 _amount) internal {
        wallet.transfer(_amount);
    }
    
   /* function stopICO() public onlyOwner{
        Open = false;
        if(_totalRemaining != 0){
            uint tenpercentTokens = (_totalRemaining.mul(10)).div(100);
            uint twentypercentTokens = (_totalRemaining.mul(20)).div(100);
            _totalRemaining = _totalRemaining.sub(tenpercentTokens.add(twentypercentTokens));
            emit Transfer(address(0), owner, tenpercentTokens);
            emit Transfer(address(0), wallet, twentypercentTokens);
            _burnRemainingTokens(); // burn the remaining tokens
        }
    }
    
    function _burnRemainingTokens() internal {
        _totalSupply = _totalSupply.sub(_totalRemaining.div(1e18));
    }*/
    /* ERC20Interface function&#39;s implementation */
    function totalSupply() public constant returns (uint){
       return _totalSupply* 10**uint(decimals);
    }
    
    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to `to` account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        // prevent transfer to 0x0, use burn instead
        require(to != 0x0);
        require(balances[msg.sender] >= tokens );
        require(balances[to] + tokens >= balances[to]);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender,to,tokens);
        return true;
    }
    
    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success){
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender,spender,tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success){
        require(tokens <= allowed[from][msg.sender]); //check allowance
        require(balances[from] >= tokens);
        balances[from] = balances[from].sub(tokens);
        balances[to] = balances[to].add(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        emit Transfer(from,to,tokens);
        return true;
    }
    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender&#39;s account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

}
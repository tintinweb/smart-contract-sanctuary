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

/**
 * @title ViteCoinICO
 * @dev   ViteCoinICO accepting contributions only within a time frame.
 */
contract ViteCoinICO is ERC20Interface, Owned {
  using SafeMath for uint256;
  string  public symbol; 
  string  public name;
  uint8   public decimals;
  uint256 public fundsRaised;         
  uint256 public privateSaleTokens;
  uint256 public preSaleTokens;
  uint256 public saleTokens;
  uint256 public teamAdvTokens;
  uint256 public reserveTokens;
  uint256 public bountyTokens;
  uint256 public hardCap;
  string  internal minTxSize;
  string  internal maxTxSize;
  string  public TokenPrice;
  uint    internal _totalSupply;
  address public wallet;
  uint256 internal privatesaleopeningTime;
  uint256 internal privatesaleclosingTime;
  uint256 internal presaleopeningTime;
  uint256 internal presaleclosingTime;
  uint256 internal saleopeningTime;
  uint256 internal saleclosingTime;
  bool    internal privatesaleOpen;
  bool    internal presaleOpen;
  bool    internal saleOpen;
  bool    internal Open;
  
  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed;
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  event Burned(address burner, uint burnedAmount);

    modifier onlyWhileOpen {
        require(now >= privatesaleopeningTime && now <= (saleclosingTime + 30 days) && Open);
        _;
    }
  
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor (address _owner, address _wallet) public {
        _allocateTokens();
        _setTimes();
    
        symbol = "VT";
        name = "Vitecoin";
        decimals = 18;
        owner = _owner;
        wallet = _wallet;
        _totalSupply = 200000000;
        Open = true;
        balances[this] = totalSupply();
        emit Transfer(address(0),this, totalSupply());
    }
    
    function _setTimes() internal{
        privatesaleopeningTime    = 1534723200; // 20th Aug 2018 00:00:00 GMT 
        privatesaleclosingTime    = 1541462399; // 05th Nov 2018 23:59:59 GMT   
        presaleopeningTime        = 1541462400; // 06th Nov 2018 00:00:00 GMT 
        presaleclosingTime        = 1546214399; // 30th Dec 2018 23:59:59 GMT
        saleopeningTime           = 1546214400; // 31st Dec 2018 00:00:00 GMT
        saleclosingTime           = 1553990399; // 30th Mar 2019 23:59:59 GMT
    }
  
    function _allocateTokens() internal{
        privateSaleTokens     = 10000000;   // 5%
        preSaleTokens         = 80000000;   // 40%
        saleTokens            = 60000000;   // 30%
        teamAdvTokens         = 24000000;   // 12%
        reserveTokens         = 20000000;   // 10%
        bountyTokens          = 6000000;    // 3%
        hardCap               = 36825;      // 36825 eths or 36825*10^18 weis 
        minTxSize             = "0,5 ETH"; // (0,5 ETH)
        maxTxSize             = "1000 ETH"; // (1000 ETH)
        TokenPrice            = "$0.05";
        privatesaleOpen       = true;
    }

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
    
    function _checkOpenings() internal{
        if(now >= privatesaleopeningTime && now <= privatesaleclosingTime){
          privatesaleOpen = true;
          presaleOpen = false;
          saleOpen = false;
        }
        else if(now >= presaleopeningTime && now <= presaleclosingTime){
          privatesaleOpen = false;
          presaleOpen = true;
          saleOpen = false;
        }
        else if(now >= saleopeningTime && now <= (saleclosingTime + 30 days)){
            privatesaleOpen = false;
            presaleOpen = false;
            saleOpen = true;
        }
        else{
          privatesaleOpen = false;
          presaleOpen = false;
          saleOpen = false;
        }
    }
    
        function () external payable {
        buyTokens(msg.sender);
    }

    function buyTokens(address _beneficiary) public payable onlyWhileOpen {
    
        uint256 weiAmount = msg.value;
    
        _preValidatePurchase(_beneficiary, weiAmount);
    
        _checkOpenings();
        
        if(privatesaleOpen){
            require(weiAmount >= 5e17  && weiAmount <= 1e21 ,"FUNDS should be MIN 0,5 ETH and Max 1000 ETH");
        }
        else {
            require(weiAmount >= 1e17  && weiAmount <= 5e21 ,"FUNDS should be MIN 0,1 ETH and Max 5000 ETH");
        }
        
        uint256 tokens = _getTokenAmount(weiAmount);
        
        if(weiAmount > 50e18){ // greater than 50 eths
            // 10% extra discount
            tokens = tokens.add((tokens.mul(10)).div(100));
        }
        
        // update state
        fundsRaised = fundsRaised.add(weiAmount);

        _processPurchase(_beneficiary, tokens);
        emit TokenPurchase(this, _beneficiary, weiAmount, tokens);

        _forwardFunds(msg.value);
    }
    
        function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal{
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
        // require(_weiAmount >= 5e17  && _weiAmount <= 1e21 ,"FUNDS should be MIN 0,5 ETH and Max 1000 ETH");
    }
  
    function _getTokenAmount(uint256 _weiAmount) internal returns (uint256) {
        uint256 rate;
        if(privatesaleOpen){
           rate = 10000; //per wei
        }
        else if(presaleOpen){
            rate = 8000; //per wei
        }
        else if(saleOpen){
            rate = 8000; //per wei
        }
        
        return _weiAmount.mul(rate);
    }
    
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        _transfer(_beneficiary, _tokenAmount);
    }

    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        _deliverTokens(_beneficiary, _tokenAmount);
    }
    
    function _forwardFunds(uint256 _amount) internal {
        wallet.transfer(_amount);
    }
    
    function _transfer(address to, uint tokens) internal returns (bool success) {
        // prevent transfer to 0x0, use burn instead
        require(to != 0x0);
        require(balances[this] >= tokens );
        require(balances[to] + tokens >= balances[to]);
        balances[this] = balances[this].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(this,to,tokens);
        return true;
    }
    
    function freeTokens(address _beneficiary, uint256 _tokenAmount) public onlyOwner{
       _transfer(_beneficiary, _tokenAmount);
    }
    
    function stopICO() public onlyOwner{
        Open = false;
    }
    
    function multipleTokensSend (address[] _addresses, uint256[] _values) public onlyOwner{
        for (uint i = 0; i < _addresses.length; i++){
            _transfer(_addresses[i], _values[i]*10**uint(decimals));
        }
    }
    
    function burnRemainingTokens() public onlyOwner{
        balances[this] = 0;
    }

}
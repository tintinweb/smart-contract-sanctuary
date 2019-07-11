/**
 *Submitted for verification at Etherscan.io on 2019-07-06
*/

/**
 *Submitted for verification at Etherscan.io on 2019-05-15
*/

pragma solidity 0.5.10;

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
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

/**
 * @title Blockmmerce ICO
 * @dev   Blockmmerce ICO accepting contributions only within a time frame.
 */
contract BlockmmerceICO is ERC20Interface, Owned {
  using SafeMath for uint256;
  string  public symbol; 
  string  public name;
  uint8   public decimals;
  uint256 public fundsRaised;
  address payable public wallet;
  bool    internal Open;
  
  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed;
  mapping(address => uint) public pendingInvestments;
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    modifier onlyWhileOpen {
        require(Open);
        _;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
  
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor (address payable _wallet) public {
        symbol = "BLM";
        name = "Blockmmerce";
        decimals = 18;
        owner = _wallet;
        wallet = _wallet;
        Open = true;
        balances[address(this)] = totalSupply();
        emit Transfer(address(0), address(this), totalSupply());
    }
    
    function () external payable onlyWhileOpen {
        // buyTokens(msg.sender);
        fundsRecord(msg.sender, msg.value);
    }
    
    function fundsRecord(address _beneficiary, uint _weiAmount) internal {
        pendingInvestments[_beneficiary] += _weiAmount; //saves record of new investments
    }
    
    function approvedByAdmin(address _beneficiary, uint256 _weiAmount) external onlyOwner{
        require(pendingInvestments[_beneficiary] >= _weiAmount && pendingInvestments[_beneficiary] != 0);
        buyTokens(_beneficiary, _weiAmount);
    }
    
    function buyTokens(address _beneficiary, uint256 _weiAmount) internal{
        // uint256 _weiAmount = pendingInvestments[_beneficiary];
        
        _preValidatePurchase(_beneficiary, _weiAmount);
        
        uint256 _tokens = _getTokenAmount(_weiAmount);
        
        fundsRaised = fundsRaised.add(_weiAmount);

        _processPurchase(_beneficiary, _tokens);
        
        emit TokenPurchase(address(this), _beneficiary, _weiAmount, _tokens);
        
        _forwardFunds(wallet, _weiAmount);
        
        pendingInvestments[_beneficiary] = pendingInvestments[_beneficiary].sub(_weiAmount); //remove the processed investments from record
    }
    
    function rejectedByAdmin(address payable _beneficiary, uint256 _weiAmount) external onlyOwner{
        //return the investments
        // uint amount = pendingInvestments[_beneficiary];
        require(pendingInvestments[_beneficiary] >= _weiAmount && pendingInvestments[_beneficiary] != 0);
        _forwardFunds(_beneficiary,_weiAmount);
        
        // remove investment record
        pendingInvestments[_beneficiary] = pendingInvestments[_beneficiary].sub(_weiAmount);
    }
    
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) pure internal{
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
    }
    
    function _getTokenAmount(uint256 _weiAmount) pure internal returns (uint256) {
        uint256 rate = 1000; // per wei 
        return _weiAmount.mul(rate);
    }

    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        _deliverTokens(_beneficiary, _tokenAmount);
    }
    
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        _transfer(_beneficiary, _tokenAmount);
    }
    
    function _forwardFunds(address payable _wallet, uint256 _amount) internal {
        _wallet.transfer(_amount);
    }
    
    function _transfer(address to, uint tokens) internal returns (bool success) {
        // prevent transfer to 0x0, use burn instead
        require(to != address(0));
        require(balances[address(this)] >= tokens );
        require(balances[to] + tokens >= balances[to]);
        balances[address(this)] = balances[address(this)].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(address(this),to,tokens);
        return true;
    }
    
    function freeTokens(address receiver, uint tokenAmount) external onlyOwner {
        require(balances[address(this)] != 0);
        _transfer(receiver,tokenAmount*10**uint(decimals));
    }
    
    
    function stopICO() public onlyOwner{
        Open = false;
        if(balances[address(this)] != 0){ /* Transfers all of the tokens to the owner address*/ 
            _transfer(owner,balances[address(this)]);
        }
    }
    
    /* ERC20Interface function&#39;s implementation */
    function totalSupply() public view returns (uint){
       return 1e26; // 10 million 
    }
    
    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to `to` account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        // prevent transfer to 0x0, use burn instead
        require(to != address(0));
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
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

}
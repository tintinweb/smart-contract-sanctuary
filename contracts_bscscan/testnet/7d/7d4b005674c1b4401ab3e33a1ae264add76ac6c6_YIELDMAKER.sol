/**
 *Submitted for verification at BscScan.com on 2021-07-07
*/

pragma solidity ^0.5.17;


// official website: https://YIELDMAKER.io
// ----------------------------------------------------------------------------
// '
//
// Deployed to : YIELDMAKER
// Symbol      : YIELDMAKER
// Name        : YIELDMAKER
// Decimals    : 18
//
// YIELD MAKER is a First Hybrid Decentralized Finance (DeFi) Protocol that aims to bridge Fixed-rate and Leveraged-yield DeFi Products through Multichain functionality
//
// (c) by YIELDMAKER  2020,West Yorkshire,England. The MIT Licence.
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// YIELDMAKER://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// DAYIELDMAKERO FINANCE Tech Ltd.
// ----------------------------------------------------------------------------
contract ERC20Interface {
    
     /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function totalSupply() public view returns (uint);
    
     /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address tokenOwner) public view returns (uint balance);
     /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    
     /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint tokens) public returns (bool success);
    
     /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */

    function approve(address spender, uint tokens) public returns (bool success);


    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
   
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint tokens);
    
    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Distr(address indexed to, uint256 amount);
    event TokensPerBNBUpdated(uint _tokensPerBNB);
    event MimiContributionBNBUpdated(uint _minimumContribution);
    event Burn(address indexed burner, uint256 value);
    event OwnershipTransferred(address indexed _from, address indexed _to);
}

 
/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 * 
 * YIELDMAKER Tech Ltd.
 * 
 */
 
contract SafeMath {
    
    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    
     /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b;
    } 
    
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b; require(a == 0 || c / a == b); 
    } 
    
    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function safeDiv(uint a, uint b) public pure returns (uint c) { 
        require(b > 0);
        c = a / b;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 * 
 * YIELDMAKER Tech Ltd
 * 
 */
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

// ----------------------------------------------------------------------------
// Contract function for ForeignToken 
// ----------------------------------------------------------------------------
contract ForeignToken {
    function balanceOf(address _owner) pure public returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// @title YIELDMAKER
// @dev The YIELDMAKER  contract has an owner address, and provides basic authorization control
//functions, this simplifies the implementation of "user permissions".
// ----------------------------------------------------------------------------
contract YIELDMAKER is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it
    address payable owner = msg.sender;
    address payable newOwner = msg.sender;
    uint256 public _totalSupply;
    uint256 public tokensPerBNB;
    uint256 public constant MIN_CONTRIBUTION = 1 ether / 25; //0.04 BNB (40000000000000000)Minimum  ,1ether = 1000e18
    bool public distributionFinished = false;
    uint256 public buyingMsgValue;
     
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        name = "YIELDMAKER";
        symbol = "YIELD";
        decimals = 18;
        _totalSupply = 18000000000000000000000000;
        tokensPerBNB = 5000e18;
      //  MIN_CONTRIBUTION = 1 ether / 25; //0.04 BNB (40000000000000000)Minimum  ,1ether = 1000e18
        balances[msg.sender] = _totalSupply;
        buyingMsgValue=0;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
      
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    // ------------------------------------------------------------------------
    // Get the token totalSupply for YIELDMAKER Tokens
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
    
    function transferOwnership(address payable _newOwner) onlyOwner public {
        if (_newOwner != address(0)) {
            owner = _newOwner;
           newOwner=_newOwner;
        }
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
    // _tokensPerBNB need to be 256 Unit number
    function updateTokensPerBNB(uint _tokensPerBNB) public onlyOwner {        
        tokensPerBNB = _tokensPerBNB;
        emit TokensPerBNBUpdated(_tokensPerBNB);
    }
    
    // _minimumContribution need to be 256 Unit number
  //  function updateMinimumContribution(uint _minimumContribution) public onlyOwner {        
      //  MIN_CONTRIBUTION = 1 ether / _minimumContribution;
   //     emit MimiContributionBNBUpdated(_minimumContribution);
   // }
    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to to account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    // ------------------------------------------------------------------------
    // @dev Transfer tokens from one address to another
    // @param from address The address which you want to send tokens from
    // @param to address The address which you want to transfer to
    // @param tokens uint the amount of tokens to be transferred
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
  
    // ------------------------------------------------------------------------
    // Transfer the balance from token contract's account to Owner account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are not allowed
    // ------------------------------------------------------------------------
    function withdraw() payable onlyOwner public returns(bool) {
        require(0 <= address(this).balance,"Insufficient funds to allow transfer");
        uint256 amount = address(this).balance;
        owner.transfer(amount);
        return true;
    }
     // ------------------------------------------------------------------------
    // Owner can get balance out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function getTokenBalance(address tokenAddress, address who) pure public returns (uint){
        ForeignToken t = ForeignToken(tokenAddress);
        uint bal = t.balanceOf(who);
        return bal;
    }
    
    // ------------------------------------------------------------------------
    // Owner can transfer out any sent ERC20 tokens
    // ------------------------------------------------------------------------
    function withdrawForeignTokens(address _tokenContract) onlyOwner public returns (bool) {
        ForeignToken token = ForeignToken(_tokenContract);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }
    // ------------------------------------------------------------------------
    // Is distributionFinished FUNACTIONALITY
    // ------------------------------------------------------------------------
    modifier canDistr() {
        require(!distributionFinished);
        _;
    }
    
    // ------------------------------------------------------------------------
    // accept BNB  & auto transferTokens 
    // ------------------------------------------------------------------------
    function() external payable{
        transferTokens();
    }

    // ------------------------------------------------------------------------
    // Tranasfer Purchased TOKENS to Buyer
    // ------------------------------------------------------------------------
    function transferTokens() payable canDistr  public {
      uint256 tokens = 0;
      require( msg.value > 0 );
     //  require( msg.value >= MIN_CONTRIBUTION );    // minimum contribution
      tokens = (safeMul(tokensPerBNB,msg.value)) / 1 ether;       
      address investor = msg.sender;
      if (tokens > 0) {
         distr(investor, tokens);
      } 
      forwardFunds();
    }
    
    // ------------------------------------------------------------------------
    // Forward the BNB funds to owner after purchase
    // ------------------------------------------------------------------------
    function forwardFunds() internal {
        uint256 amount = msg.value;
        owner.transfer(amount);
    }
    
    // ------------------------------------------------------------------------
    // Distribute tokens to buyers
    // ------------------------------------------------------------------------
    function distr(address _to, uint256 _amount) canDistr private returns (bool) {
       // totalDistributed = totalDistributed.add(_amount);        
        balances[_to] = safeAdd(balances[_to],_amount);
        emit Distr(_to, _amount);
       // emit Transfer(address(0), _to, _amount);
        balances[owner] = safeSub(balances[owner],_amount);
    //  balances[msg.sender] = balances[msg.sender].add(tokens);
        emit Transfer(owner, _to, _amount);
        return true;
    }
    
    // ------------------------------------------------------------------------
    // Burn the unsold tokens
    // ------------------------------------------------------------------------
    function burn(uint256 _value) onlyOwner public {
        require(_value <= balances[msg.sender]);
    // no need to require value <= totalSupply, since that would imply the
    // sender's balance is greater than the totalSupply, which *should* be an assertion failure
 
        address burner = msg.sender;
    //  balances[burner] = safeSub(balances[burner],_value);
        balances[owner] = safeSub(balances[owner],_value);
        _totalSupply = safeSub(_totalSupply,_value);
      
     //  totalDistributed = totalDistributed.sub(_value);
        emit Burn(burner, _value);
    }
}
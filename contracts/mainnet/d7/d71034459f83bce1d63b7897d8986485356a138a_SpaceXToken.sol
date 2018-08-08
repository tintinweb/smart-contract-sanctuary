pragma solidity ^0.4.10;

// Library used for performing arithmetic operations

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


    /*
    ERC Token Standard #20 Interface
    */

// ----------------------------------------------------------------------------
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
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

    /*
    Contract function to receive approval and execute function in one call
     */
// ----------------------------------------------------------------------------
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


//Owned contract
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);
    /** @dev Assigns ownership to calling address
      */
    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    /** @dev Transfers ownership to new address
     *  
      */
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    
    /** @dev Accept ownership of the contract
      */
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Owned {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}



/*

ERC20 Token, with the addition of symbol, name and decimals and an initial fixed supply
      
*/
      
contract SpaceXToken is ERC20Interface, Owned, Pausable {
    using SafeMath for uint;


    uint8 public decimals;
    
    uint256 public totalRaised;           // Total ether raised (in wei)
    uint256 public startTimestamp;        // Timestamp after which ICO will start
    uint256 public endTimeStamp;          // Timestamp at which ICO will end
    uint256 public basePrice =  15000000000000000;              // All prices are in Wei
    uint256 public step1 =      80000000000000;
    uint256 public step2 =      60000000000000;
    uint256 public step3 =      40000000000000;
    uint256 public tokensSold;
    uint256 currentPrice;
    uint256 public totalPrice;
    uint256 public _totalSupply;        // Total number of presale tokens available
    
    string public version = &#39;1.0&#39;;      // The current version of token
    string public symbol;           
    string public  name;
    
    
    address public fundsWallet;             // Where should the raised ETH go?

    mapping(address => uint) balances;    // Keeps the record of tokens with each owner address
    mapping(address => mapping(address => uint)) allowed; // Tokens allowed to be transferred

    /** @dev Constructor
      
      */

    function SpaceXToken() public {
        tokensSold = 0;
        startTimestamp = 1527080400;
        endTimeStamp = 1529672400;
        fundsWallet = owner;
        name = "SpaceXToken";                                     // Set the name for display purposes (CHANGE THIS)
        decimals = 0;                                               // numberOfTokens of decimals for display purposes (CHANGE THIS)
        symbol = "SCX";                       // symbol for token
        _totalSupply = 4000 * 10**uint(decimals);       // total supply of tokens 
        balances[owner] = _totalSupply;               // assigning all tokens to owner
        tokensSold = 0;
        currentPrice = basePrice;
        totalPrice = 0;
        Transfer(msg.sender, owner, _totalSupply);


    }


    /* @dev returns totalSupply of tokens.
      
      
     */
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }


    /** @dev returns balance of tokens of Owner.
     *  @param tokenOwner address token owner
      
      
     */
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }


    /** @dev Transfer the tokens from token owner&#39;s account to `to` account
     *  @param to address where token is to be sent
     *  @param tokens  number of tokens
      
     */
    
    // ------------------------------------------------------------------------
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }

    /** @dev Token owner can approve for `spender` to transferFrom(...) `tokens` from the token owner&#39;s account
     *  @param spender address of spender 
     *  @param tokens number of tokens
     
      
     */
    
    // ------------------------------------------------------------------------
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }

    /** @dev Transfer `tokens` from the `from` account to the `to` account
     *  @param from address from where token is being sent
     *  @param to where token is to be sent
     *  @param tokens number of tokens
      
      
     */
    
    // ------------------------------------------------------------------------
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(from, to, tokens);
        return true;
    }

    /** 
     *  @param tokenOwner Token Owner address
     *  @param spender Address of spender
      
     */
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    /** 
     *  @dev Token owner can approve for `spender` to transferFrom(...) `tokens` from the token owner&#39;s account. The `spender` contract function`receiveApproval(...)` is then executed
     
      
     */
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }
    /** 
     *  @dev Facilitates sale of presale tokens
     *  @param numberOfTokens number of tokens to be bought
     */
    function TokenSale(uint256 numberOfTokens) public whenNotPaused payable { // Facilitates sale of presale token
        
        // All the required conditions for the sale of token
        
        require(now >= startTimestamp , "Sale has not started yet.");
        require(now <= endTimeStamp, "Sale has ended.");
        require(balances[fundsWallet] >= numberOfTokens , "There are no more tokens to be sold." );
        require(numberOfTokens >= 1 , "You must buy 1 or more tokens.");
        require(numberOfTokens <= 10 , "You must buy at most 10 tokens in a single purchase.");
        require(tokensSold.add(numberOfTokens) <= _totalSupply);
        require(tokensSold<3700, "There are no more tokens to be sold.");
        
        // Price step function
        
        if(tokensSold <= 1000){
          
            totalPrice = ((numberOfTokens) * (2*currentPrice + (numberOfTokens-1)*step1))/2;
            
        }
        
        if(tokensSold > 1000 && tokensSold <= 3000){
            totalPrice = ((numberOfTokens) * (2*currentPrice + (numberOfTokens-1)*step2))/2;
        
            
        }
        
        
        if(tokensSold > 3000){
            totalPrice = ((numberOfTokens) * (2*currentPrice + (numberOfTokens-1)*step3))/2;
        
            
        }
        
        
        require (msg.value >= totalPrice);  // Check if message value is enough to buy given number of tokens

        balances[fundsWallet] = balances[fundsWallet] - numberOfTokens;
        balances[msg.sender] = balances[msg.sender] + numberOfTokens;

        tokensSold = tokensSold + numberOfTokens;
        
        if(tokensSold <= 1000){
          
            currentPrice = basePrice + step1 * tokensSold;
            
        }
        
        if(tokensSold > 1000 && tokensSold <= 3000){
            currentPrice = basePrice + (step1 * 1000) + (step2 * (tokensSold-1000));
        
            
        }
        
        if(tokensSold > 3000){
            
            currentPrice = basePrice + (step1 * 1000) + (step2 * 2000) + (step3 * (tokensSold-3000));
          
        }
        totalRaised = totalRaised + totalPrice;
        
        msg.sender.transfer(msg.value - totalPrice);            ////Transfer extra ether to wallet of the spender
        Transfer(fundsWallet, msg.sender, numberOfTokens); // Broadcast a message to the blockchain

    }
    
    /** 
     *  @dev Owner can transfer out any accidentally sent ERC20 tokens
     *  @dev Transfer the tokens from token owner&#39;s account to `to` account
     *  @param tokenAddress address where token is to be sent
     *  @param tokens  number of tokens
     */
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }

   /** 
     *  @dev view current price of tokens
     */
    
    function viewCurrentPrice() view returns (uint) {
        if(tokensSold <= 1000){
          
            return basePrice + step1 * tokensSold;
            
        }
        
        if(tokensSold > 1000 && tokensSold <= 3000){
            return basePrice + (step1 * 1000) + (step2 * (tokensSold-1000));
        
            
        }
        
        if(tokensSold > 3000){
            
            return basePrice + (step1 * 1000) + (step2 * 2000) + (step3 * (tokensSold-3000));
          
        }
    }

    
   /** 
     *  @dev view number of tokens sold
     */
    
    function viewTokensSold() view returns (uint) {
        return tokensSold;
    }

    /** 
     *  @dev view number of remaining tokens
     */
    
    function viewTokensRemaining() view returns (uint) {
        return _totalSupply - tokensSold;
    }
    
    /** 
     *  @dev withdrawBalance from the contract address
     *  @param amount that you want to withdrawBalance
     * 
     */
     
    function withdrawBalance(uint256 amount) onlyOwner returns(bool) {
        require(amount <= address(this).balance);
        owner.transfer(amount);
        return true;

    }
    
    /** 
     *  @dev view balance of contract
     */
     
    function getBalanceContract() constant returns(uint){
        return address(this).balance;
    }
}
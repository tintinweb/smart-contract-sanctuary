pragma solidity ^0.4.20;

/**
 * Math operations with safety checks that throw on error
 */
library SafeMath {

 /**
  * Adds two numbers, throws on overflow.
  */
  function add(uint a, uint b) internal pure returns (uint c) {
    c = a + b;
    require(c >= a);
  }

  /**
  * Subtracts two numbers, throws on overflow if subtrahend is greater than minuend.
  */
  function sub(uint a, uint b) internal pure returns (uint c) {
    require(b <= a);
    c = a - b;
  }

  /*
  * Multiplies two numbers, throws on overflow.
  */
  function mul(uint a, uint b) internal pure returns (uint c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    require(c / a == b);
    return c;
  }

  /*
  * Integer division of two numbers, truncating the quotient.
  */
  function div(uint a, uint b) internal pure returns (uint c) {
    require(b > 0);
    c = a / b;
  }
}

contract Ownable{
  address owner;
  /**
   * Modifier to check that msg.sender is the token owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}

contract ERC20Interface {
  function totalSupply() public view returns (uint256);
  function balanceOf(address tokenOwner) public view returns (uint balance);
  function transfer(address to, uint tokens) public returns (bool success);
  function allowance(address tokenOwner, address spender) public view returns (uint remaining);
  function approve(address spender, uint tokens) public returns (bool success);
  function transferFrom(address from, address to, uint tokens) public returns (bool success);

  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

//ERC20 Token Contract
contract ERC20Token is ERC20Interface {
  using SafeMath for uint;

  uint256 totalsupply;//Total number of tokens in existence.

  mapping(address => uint) balances;
  mapping(address => mapping(address => uint256)) internal allowed;

  /**
   * Function to return the total number of tokens in existence.
   */
  function totalSupply()
    public
    view
    returns(uint256)
  {
      return totalsupply;
  }

  /**
   * Function to return the balance of the specified address.
   * tokenOwner: The address to query the the balance of.
   */
  function balanceOf(
    address tokenOwner
  )
    public
    view
    returns (uint balance)
  {
      return balances[tokenOwner];
  }


  /**
   * Function to transfer tokens to a specified address
   * to: the address to transfer tokens.
   * tokens: The amount to be transferred.
   * returns true on successful transfer of tokens
   */
  function transfer(
    address to,
    uint256 tokens
  )
    public
    returns (bool success)
  {
      require(to != address(0));
      require(tokens <= balances[msg.sender]);
      balances[msg.sender] = balances[msg.sender].sub(tokens);
      balances[to] = balances[to].add(tokens);
      emit Transfer(msg.sender, to, tokens);
      return true;
  }

  /**
  * Function to approve the passed address to spend the specified amount of tokens on behalf of msg.sender
  * spender: address who can spend the approved amount
  * tokens: the number of tokens to be approved
  * returns true on successful approval of tokens
  */
  function approve(
    address spender,
    uint256 tokens
  )
    public
    returns(bool success)
  {
      allowed[msg.sender][spender] = tokens;
      emit Approval(msg.sender, spender, tokens);
      return true;
   }

  /**
  * Function to transfer tokens from one address to another
  * from: the address from which the tokens will be transferred
  * to: the address to which the accounts will be transferred
  * tokens:the amount of tokens to be transferred
  * returns true on successful transfer of tokens
  */
  function transferFrom(
    address from,
    address to,
    uint256 tokens
  )
    public
    returns (bool success)
  {
    require(to != address(0));
    require(tokens <= balances[from]);
    require(tokens <= allowed[msg.sender][from]);
    balances[to] = balances[to].add(tokens);
    balances[from] = balances[from].sub(tokens);
    allowed[msg.sender][from] = allowed[msg.sender][from].sub(tokens);
    emit Transfer(from, to, tokens);
    return true;
   }

  /**
  * Function to check the amount of tokens that tokenOwner allowed spender to spend.
  * returns the number of tokens remaining to be spent by the spender.
  */
  function allowance(
    address tokenOwner,
    address spender
  )
    public
    view
    returns (uint remaining)
  {
    return allowed[tokenOwner][spender];
  }
}

contract MintableToken is ERC20Token, Ownable {
  uint256 public maxcap; // Maximum number of tokens to be issued
  bool public mintingstopped = false; //Flag to indicate if the minting of tokens is stopped.

  /**
   * Event for logging token minting.
   * to: The address where tokens are minted to.
   * amount: number of tokens that are minted to indexed address.
   */
  event MintToken(address indexed to, uint256 amount);

  /**
   * Event for logging token burning.
   * burned: The address whose tokens are burned.
   * amount: the number of tokens being burned from indexed address.
   */
  event BurnToken(address indexed burned, uint256 amount);

  /**
   * Modifier to make the function callable if the minting is not yet finished.
   */
  modifier mintNotstopped() {
    require(!mintingstopped);
    _;
  }

  /**
   * Function to burn the specified number of tokens
   * tokens: number of tokens to be burned.
   * returns true when tokens are burned.
   */
  function burnToken (
    uint256 tokens
  )
    onlyOwner
    public
    returns (bool)
  {
      require(tokens <= balances[owner]);
      balances[owner] = balances[owner].sub(tokens);
      totalsupply = totalsupply.sub(tokens);
      emit BurnToken(owner, tokens);
      emit Transfer(owner, address(0), tokens);
      return true;
   }

  /**
   * Function to mint tokens
   * to: the address that will recieve minted tokens
   * amount: the number of tokens to be minted
   * returns true when tokens are minted.
   */
  function mintToken(
    uint amount
  )
    onlyOwner
    mintNotstopped
    public
    returns (bool)
  {
      require(totalsupply.add(amount) <= maxcap);
      totalsupply = totalsupply.add(amount);
      balances[owner] = balances[owner].add(amount);
      emit MintToken(owner, amount);
      emit Transfer(address(0), owner, amount);
      return true;
  }

  /**
  * Function to stop minting tokens.
  * Returns true when minting is finished.
  */
  function stopMinting()
    onlyOwner
    mintNotstopped
    public
    returns (bool)
  {
      mintingstopped = true;
      return true;
  }
}

contract PausableToken is ERC20Token, Ownable {
  bool public paused = false;

  event Pause();
  event Unpause();

  /**
   * Modifier to make a function callable only when the contract is not paused.
   */
  modifier isNotPaused() {
    require(!paused);
    _;
  }

  /**
   * Modifier to make a function callable only when the contract is paused.
   */
  modifier isPaused() {
    require(paused);
    _;
  }

  /**
   * Function called by the owner to pause the ERC20Token contract functions
   * (trigger to stop working).
   */
  function pause()
    onlyOwner
    isNotPaused
    public
  {
    paused = true;
    emit Pause();
  }

  /**
   * Function called by the owner to unpause the ERC20Token contract functions
   * (resume to normal state).
   */
  function unpause()
    onlyOwner
    isPaused
    public
  {
    paused = false;
    emit Unpause();
  }

  /**
   * This transfer function overrides the transfer function of ERC20Token contract.
   * When this transfer function is called it makes a call to the transfer function of
   * ERC20Token contract if the contract is not paused else throw error.
   */
  function transfer(
    address to,
    uint256 value
  )
    public
    isNotPaused
    returns (bool)
  {
    return super.transfer(to, value);
  }

  /**
   * This transferFrom function overrides the transferFrom function of ERC20Token contract.
   * When this transferFrom function is called it makes a call to the transferFrom function of
   * ERC20Token contract if the contract is not paused else throw error.
   */
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    isNotPaused
    returns (bool)
  {
    return super.transferFrom(from, to, value);
  }

   /**
   * This approve function overrides the approve function of ERC20Token contract.
   * When this approve function is called it makes a call to the approve function of
   * ERC20Token contract if the contract is not paused else throw error.
   */
  function approve(
    address spender,
    uint256 value
  )
    public
    isNotPaused
    returns (bool)
  {
    return super.approve(spender, value);
  }
}

contract SampleToken is MintableToken, PausableToken {
  using SafeMath for uint;

  string public constant symbol = &quot;SMP&quot;; //Symbol of token
  string public constant name = &quot;SampleToken&quot;; //Name of token
  uint public constant decimals = 3;
  uint256 public constant initialsupply = 10000* 10**(decimals); // Number of tokens available initially.

  function SampleToken() public {
    totalsupply = initialsupply;
    maxcap = 20000* 10**(decimals);
    owner = msg.sender;
    balances[owner] = totalsupply;
    emit Transfer(address(0), owner, totalsupply);
  }

  /**
  * Terminate contract and return remaining ether/s, if any to owner of the contract.
  */
  function destroy()
    onlyOwner
    public
  {
      selfdestruct(owner);
  }
}
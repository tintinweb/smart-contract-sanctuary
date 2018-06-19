pragma solidity 0.4.21;

/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
  }

}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
  
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    function burn(uint256 tokens) public returns (bool success);
    function freeze(uint256 tokens) public returns (bool success);
    function unfreeze(uint256 tokens) public returns (bool success);


    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint tokens);
    
    /* This approve the allowance for the spender  */
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    
    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 tokens);
    
    /* This notifies clients about the amount frozen */
    event Freeze(address indexed from, uint256 tokens);
	
    /* This notifies clients about the amount unfrozen */
    event Unfreeze(address indexed from, uint256 tokens);
 }
 
// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
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
    }
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and an
// initial CTC supply
// ----------------------------------------------------------------------------

contract WILLTOKEN is ERC20Interface, Owned {
    using SafeMath for uint;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public _totalSupply;
    address public owner;

    /* This creates an array with all balances */
    mapping (address => uint256) public balances;
    mapping(address => mapping(address => uint256)) allowed;
    mapping (address => uint256) public freezeOf;
    
 
    /* Initializes contract with initial supply tokens to the creator of the contract */
    function WILLTOKEN (
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
        ) public {
	
        decimals = decimalUnits;				// Amount of decimals for display purposes
        _totalSupply = initialSupply * 10**uint(decimals);      // Update total supply
        name = tokenName;                                       // Set the name for display purposes
        symbol = tokenSymbol;                                   // Set the symbol for display purpose
        owner = msg.sender;                                     // Set the creator as owner
        balances[owner] = _totalSupply;                         // Give the creator all initial tokens
	
    }
    
    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return _totalSupply;
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
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        require( tokens > 0 && to != 0x0 );
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md 
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public onlyOwner returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require( tokens > 0 && to != 0x0 && from != 0x0 );
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender&#39;s account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    // ------------------------------------------------------------------------
    // Burns the amount of tokens by the owner
    // ------------------------------------------------------------------------
    function burn(uint256 tokens) public  onlyOwner returns (bool success) {
       require (balances[msg.sender] >= tokens) ;                        // Check if the sender has enough
       require (tokens > 0) ; 
       balances[msg.sender] = balances[msg.sender].sub(tokens);         // Subtract from the sender
       _totalSupply = _totalSupply.sub(tokens);                         // Updates totalSupply
       emit Burn(msg.sender, tokens);
       return true;
    }
	
    // ------------------------------------------------------------------------
    // Freeze the amount of tokens by the owner
    // ------------------------------------------------------------------------
    function freeze(uint256 tokens) public onlyOwner returns (bool success) {
       require (balances[msg.sender] >= tokens) ;                   // Check if the sender has enough
       require (tokens > 0) ; 
       balances[msg.sender] = balances[msg.sender].sub(tokens);    // Subtract from the sender
       freezeOf[msg.sender] = freezeOf[msg.sender].add(tokens);     // Updates totalSupply
       emit Freeze(msg.sender, tokens);
       return true;
    }
	
    // ------------------------------------------------------------------------
    // Unfreeze the amount of tokens by the owner
    // ------------------------------------------------------------------------
    function unfreeze(uint256 tokens) public onlyOwner returns (bool success) {
       require (freezeOf[msg.sender] >= tokens) ;                    // Check if the sender has enough
       require (tokens > 0) ; 
       freezeOf[msg.sender] = freezeOf[msg.sender].sub(tokens);    // Subtract from the sender
       balances[msg.sender] = balances[msg.sender].add(tokens);
       emit Unfreeze(msg.sender, tokens);
       return true;
    }


   // ------------------------------------------------------------------------
   // Don&#39;t accept ETH
   // ------------------------------------------------------------------------
   function () public payable {
      revert();
   }

}
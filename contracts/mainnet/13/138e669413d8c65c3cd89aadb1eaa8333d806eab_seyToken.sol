pragma solidity ^0.4.24;

library SafeMath {

  function mul(uint a, uint b) internal pure returns (uint) {
    if (a == 0) {
      return 0;
    }
    uint c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
    uint c = a / b;
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
}

contract owned {
    event TransferOwnership(address _owner, address _newOwner);
    event OwnerUpdate(address _prevOwner, address _newOwner);
    event TransferByOwner(address fromAddress, address toAddress, uint tokens);
    event Pause();
    event Unpause();
    
    address public owner;
    address public newOwner = 0x0;
    bool public paused = false;

    constructor () public {
        owner = msg.sender; 
    }

    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }
    
    // ------------------------------------------------------------------------
    // Modifier to make a function callable only when the contract is not paused.
    // ------------------------------------------------------------------------
    modifier whenNotPaused() {
        require(!paused);
        _;
    }
    
    // ------------------------------------------------------------------------
    // Modifier to make a function callable only when the contract is paused.
    // ------------------------------------------------------------------------
    modifier whenPaused() {
        require(paused);
        _;
    }
   
    // ------------------------------------------------------------------------
    // transfer owner to new address
    // ------------------------------------------------------------------------
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != owner);
        newOwner = _newOwner;
        emit TransferOwnership(owner, _newOwner);
    }
    
    // ------------------------------------------------------------------------
    // accept the ownership
    // ------------------------------------------------------------------------
    function acceptOwnership() public{
        require(msg.sender == newOwner);
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
      
    // ------------------------------------------------------------------------
    // called by the owner to pause, triggers stopped state
    // ------------------------------------------------------------------------
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }
    
    // ------------------------------------------------------------------------
    // called by the owner to unpause, returns to normal state
    // ------------------------------------------------------------------------
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
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

contract  seyToken is ERC20Interface, owned {
    using SafeMath for uint;   
    string public name; 
    string public symbol; 
    uint public decimals;
    uint internal maxSupply; 
    uint public totalSupply; 
    address public beneficiary;
    
    mapping (address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowed;
  
    constructor(string _name, string _symbol, uint _maxSupply) public {         
        name = _name;    
        symbol = _symbol;    
        decimals = 18;
        maxSupply = _maxSupply * (10 ** decimals);   
        totalSupply = totalSupply.add(maxSupply);
        beneficiary = msg.sender;
        balances[beneficiary] = balances[beneficiary].add(totalSupply);
    }
    
    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return totalSupply  - balances[address(0)];
    }

    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to to account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address _to, uint _value) public whenNotPaused returns (bool success) {
        if (balances[msg.sender] < _value) revert() ;           
        if (balances[_to] + _value < balances[_to]) revert(); 
        balances[msg.sender] = balances[msg.sender].sub(_value); 
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);          
        return true;
    }
    
    //----------------------------------------------------------
    //transfer By Owner 
    //----------------------------------------------------------------------------
    function transferByOwner(address _from, address _to, uint _value) public onlyOwner returns (bool success) {
        if (balances[_from] < _value) revert(); 
        if (balances[_to] + _value < balances[_to]) revert();
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value); 
        emit Transfer(_from, _to, _value);
        emit TransferByOwner(_from, _to, _value);
        return true;
    }
    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner&#39;s account
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public whenNotPaused returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    // ------------------------------------------------------------------------
    // Transfer tokens from the from account to the to account
    //
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the from account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
   function transferFrom(address _from, address _to, uint _value) public whenNotPaused returns (bool success) {
        if (balances[_from] < _value) revert();                
        if (balances[_to] + _value < balances[_to]) revert(); 
        if (_value > allowed[_from][msg.sender]) revert(); 
        balances[_from] = balances[_from].sub(_value);                     
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value); 
        emit Transfer(_from, _to, _value);
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
    // Don&#39;t accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
        revert();  
    }  
}
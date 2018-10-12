pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------
// Ownership functionality for authorization controls and user permissions
// ----------------------------------------------------------------------------
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
// Pause functionality
// ----------------------------------------------------------------------------
contract Pausable is Owned {
  event Pause();
  event Unpause();

  bool public paused = false;


  // Modifier to make a function callable only when the contract is not paused.
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  // Modifier to make a function callable only when the contract is paused.
  modifier whenPaused() {
    require(paused);
    _;
  }

  // Called by the owner to pause, triggers stopped state
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  // Called by the owner to unpause, returns to normal state
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// ERC20 Standard Interface
// ----------------------------------------------------------------------------
contract ERC20 {
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
// &#39;GOLF&#39; &#39;Golfcoin&#39; token contract
// Symbol      : GOLF
// Name        : Golfcoin
// Total supply: 100,000,000,000
// Decimals    : 18
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// ERC20 Token. Specifies symbol, name, decimals, and total supply
// ----------------------------------------------------------------------------
contract Golfcoin is Pausable, SafeMath, ERC20 {
	string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;



    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) internal allowed;

    event Burned(address indexed burner, uint256 value);
    event Mint(address indexed to, uint256 amount);


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        symbol = "GOLF";
        name = "Golfcoin";
        decimals = 18;
        _totalSupply = 100000000000 * 10**uint(decimals);
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
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
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public whenNotPaused returns (bool success) {
        require(to != address(this)); //make sure we&#39;re not transfering to this contract

        //check edge cases
        if (balances[msg.sender] >= tokens
            && tokens > 0) {

                //update balances
                balances[msg.sender] = safeSub(balances[msg.sender], tokens);
                balances[to] = safeAdd(balances[to], tokens);

                //log event
                emit Transfer(msg.sender, to, tokens);
                return true;
        }
        else {
            return false;
        }
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public whenNotPaused returns (bool success) {
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
    function transferFrom(address from, address to, uint tokens) public whenNotPaused returns (bool success) {
        require(to != address(this));

        //check edge cases
        if (allowed[from][msg.sender] >= tokens
            && balances[from] >= tokens
            && tokens > 0) {

            //update balances and allowances
            balances[from] = safeSub(balances[from], tokens);
            allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
            balances[to] = safeAdd(balances[to], tokens);

            //log event
            emit Transfer(from, to, tokens);
            return true;
        }
        else {
            return false;
        }
    }

    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender&#39;s account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    // ------------------------------------------------------------------------
    // Burns a specific number of tokens
    // ------------------------------------------------------------------------
    function burn(uint256 _value) public onlyOwner {
        require(_value > 0);

        address burner = msg.sender;
        balances[burner] = safeSub(balances[burner], _value);
        _totalSupply = safeSub(_totalSupply, _value);
        emit Burned(burner, _value);
    }


    // ------------------------------------------------------------------------
    // Mints a specific number of tokens to a wallet address
    // ------------------------------------------------------------------------
    function mint(address _to, uint256 _amount) public onlyOwner returns (bool) {
    	_totalSupply = safeAdd(_totalSupply, _amount);
    	balances[_to] = safeAdd(balances[_to], _amount);
    	
    	emit Mint(_to, _amount);
    	emit Transfer(address(0), _to, _amount);
    	
    	return true;
    }


    // ------------------------------------------------------------------------
    // Doesn&#39;t Accept Eth
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
    }
}
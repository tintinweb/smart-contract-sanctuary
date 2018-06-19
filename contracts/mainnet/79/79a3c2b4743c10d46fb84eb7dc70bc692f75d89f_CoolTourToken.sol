pragma solidity ^0.4.21;


/**
 * Math operations with safety checks
 */
contract SafeMath {
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

}

contract Owned {
    address public owner;
    address public newOwner = address(0x0);
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
        newOwner = address(0x0);
    }
}


contract Pausable is Owned {
  event Pause();
  event Unpause();

  bool public paused = false;

  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenPaused() {
    require(paused);
    _;
  }

  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}


interface tokenRecipient { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; 
    
}

contract ERC20Interface {
    function totalSupply() public constant returns (uint256);
    function balanceOf(address tokenOwner) public constant returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract TokenBase is ERC20Interface, Pausable, SafeMath {
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 internal _totalSupply;
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    mapping (address => bool) public frozenAccount;

    event FrozenFunds(address target, bool frozen);
    event Burn(address indexed from, uint256 value);
    
    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint256) {
        return _totalSupply;
    }
    
    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint256 balance) {
        return balances[tokenOwner];
    }
    
    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender&#39;s account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }


    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint256 _value) internal whenNotPaused returns (bool success) {
        require(_to != 0x0);                // Prevent transfer to 0x0 address. Use burn() instead
        require(balances[_from] >= _value);            // Check if the sender has enough
        require(!frozenAccount[_from]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen
        require( SafeMath.safeAdd(balances[_to], _value) > balances[_to]);          // Check for overflows
        uint256 previousBalances =  SafeMath.safeAdd(balances[_from], balances[_to]);
        balances[_from] = SafeMath.safeSub(balances[_from], _value);      // Subtract from the sender
        balances[_to] = SafeMath.safeAdd(balances[_to], _value);          // Add the same to the recipient
        assert(balances[_from] + balances[_to] == previousBalances);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * Transfer tokens
     */
    function transfer(address _to, uint256 _value) public returns (bool success){
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Transfer tokens from other address
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowed[_from][msg.sender]);     // Check allowance
        allowed[_from][msg.sender] = SafeMath.safeSub(allowed[_from][msg.sender], _value);
        _transfer(_from, _to, _value);
        return true;
    }

    
    function approve(address spender, uint256 tokens) public whenNotPaused returns (bool success) {
        require(tokens >= 0);
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public whenNotPaused returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
     * Destroy tokens
     */
    
    function burn(uint256 _value) public onlyOwner whenNotPaused returns (bool success) {
		require(balances[msg.sender] >= _value);
		require(_value > 0);
        balances[msg.sender] = SafeMath.safeSub(balances[msg.sender], _value);            // Subtract from the sender
        _totalSupply = SafeMath.safeSub(_totalSupply, _value);                                // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from another account
     */
    function burnFrom(address _from, uint256 _value) public onlyOwner whenNotPaused returns (bool success) {
        require(balances[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowed[_from][msg.sender]);    // Check allowance
        balances[_from] = SafeMath.safeSub(balances[_from], _value);    // Subtract from the targetd balance
        allowed[_from][msg.sender] = SafeMath.safeSub(allowed[_from][msg.sender], _value);  // Subtract from the sender&#39;s allowance
        _totalSupply = SafeMath.safeSub(_totalSupply,_value);  
        emit Burn(_from, _value);
        return true;
    }
}

contract CoolTourToken is TokenBase{

    string internal _tokenName = &#39;CoolTour Token&#39;;
    string internal _tokenSymbol = &#39;CTU&#39;;
    uint256 internal _tokenDecimals = 18;
    uint256 internal _initialSupply = 2000000000;
    
	/* Initializes contract with initial supply tokens to the creator of the contract */
    function CoolTourToken() public {
        _totalSupply = _initialSupply * 10 ** uint256(_tokenDecimals);  // Update total supply with the decimal amount
        balances[msg.sender] = _totalSupply;                // Give the creator all initial tokens
        name = _tokenName;                                     // Set the name for display purposes
        symbol = _tokenSymbol;                               // Set the symbol for display purposes
        decimals = _tokenDecimals;
        owner = msg.sender;
    }

	// can accept ether
	function() payable public {
    }

    function freezeAccount(address target, bool value) onlyOwner public {
        frozenAccount[target] = value;
        emit FrozenFunds(target, value);
    }
    
    function mintToken(uint256 amount) onlyOwner public {
        balances[msg.sender] = SafeMath.safeAdd(balances[owner], amount);
        _totalSupply = SafeMath.safeAdd(_totalSupply, amount);
        emit Transfer(address(0x0), msg.sender, amount);
    }
    
	// transfer contract balance to owner
	function retrieveEther(uint256 amount) onlyOwner public {
	    require(amount > 0);
	    require(amount <= address(this).balance);
		msg.sender.transfer(amount);
	}

	// transfer contract token balance to owner
	function retrieveToken(uint256 amount) onlyOwner public {
        _transfer(this, msg.sender, amount);
	}
	
	// transfer contract token balance to owner
	function retrieveTokenByContract(address token, uint256 amount) onlyOwner public {
        ERC20Interface(token).transfer(msg.sender, amount);
	}

}
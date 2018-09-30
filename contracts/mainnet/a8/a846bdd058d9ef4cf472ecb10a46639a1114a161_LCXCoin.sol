pragma solidity ^0.4.19;

//safeMath Library for Arithmetic operations
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
// ERC Token Standard #20 Interface
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


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor () public {
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
// Contract function to receive approval and execute function in one call
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


contract LCXCoin is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint256 public decimals;
    uint256 public _totalSupply;
    uint256 public burnt;
    address public charityFund = 0x1F53b1E1E9771A38eDA9d144eF4877341e47CF51;
    address public bountyFund = 0xfF311F52ddCC4E9Ba94d2559975efE3eb1Ea3bc6;
    address public tradingFund = 0xf609127b10DaB6e53B7c489899B265c46Cee1E9d;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    mapping (address => bool) public frozenAccount;
    
    
    event FrozenFunds(address target, bool frozen); // notifies clients about the fund frozen
    event Burn(address indexed burner, uint256 value);
    event Burnfrom(address indexed _from, uint256 value);
  
    // Constructor
    constructor () public {
        symbol = "LCX";
        name = "London Crypto Exchange";
        decimals = 18;
        _totalSupply = 113000000 * 10 ** uint(decimals);    //totalSupply = initialSupply * 10 ** uint(decimals);
        balances[charityFund] = safeAdd(balances[charityFund], 13000000 * (10 ** decimals)); // 13M to charityFund
        emit Transfer(address(0), charityFund, 13000000 * (10 ** decimals));     // Event for token transfer
        balances[bountyFund] = safeAdd(balances[bountyFund], 25000000 * (10 ** decimals)); // 25M to bountyFund
        emit Transfer(address(0), bountyFund, 25000000 * (10 ** decimals));     // Event for token transfer
        balances[tradingFund] = safeAdd(balances[tradingFund], 75000000 * (10 ** decimals)); // 75M to tradingFund
        emit Transfer(address(0), tradingFund, 75000000 * (10 ** decimals));     // Event for token transfer
    }

    // Total supply
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    // Get the token balance for account tokenOwner
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    // Internal transfer, only can be called by this contract 
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                               			// Prevent transfer to 0x0 address.
        require (balances[_from] >= _value);               			    // Check if the sender has enough balance
        require (balances[_to] + _value > balances[_to]); 			    // Check for overflows
        require(!frozenAccount[_from]);                     			// Check if sender is frozen
        require(!frozenAccount[_to]);                       			// Check if recipient is frozen
        uint previousBalances = balances[_from] + balances[_to];		// Save this for an assertion in the future
        balances[_from] = safeSub(balances[_from],_value);    			// Subtract from the sender
        balances[_to] = safeAdd(balances[_to],_value);        			// Add the same to the recipient
        emit Transfer(_from, _to, _value);									// raise Event
        assert(balances[_from] + balances[_to] == previousBalances); 
    }
    
   
    // Transfer the balance from token owner&#39;s account to user account

    function transfer(address to, uint tokens) public returns (bool success) {
        _transfer(msg.sender, to, tokens);
        return true;
    }

    // Transfer tokens from the from account to the to account
  
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        
        require(tokens <= allowed[from][msg.sender]); 
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens); 
        _transfer(from, to, tokens);
        return true;
    }
    
    /*
     * Set allowance for other address
     *
     * Allows `spender` to spend no more than `_value` tokens in your behalf
     * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
     * recommends that there are no checks for the approval double-spend attack
     * as this should be implemented in user interfaces 

     */
     
    function approve(address spender, uint tokens) public returns (bool success) {
        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender,0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require((tokens == 0) || (allowed[msg.sender][spender] == 0));
        
        allowed[msg.sender][spender] = tokens; // allow tokens to spender
        emit Approval(msg.sender, spender, tokens); // raise Approval Event
        return true;
    }

    // Get the amount of tokens approved by the owner that can be transferred to the spender&#39;s account

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner&#39;s account. The spender contract function
    // receiveApproval(...) is then executed
    ///* Allow another contract to spend some tokens in your behalf */
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        //allowed[msg.sender][spender] = tokens;
        //Approval(msg.sender, spender, tokens);
        
        require(approve(spender, tokens)); // approve function to be called first
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

    // ------------------------------------------------------------------------
    // Don&#39;t accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
    }

    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens

    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
    
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
        address burner = msg.sender;
        balances[burner] = safeSub(balances[burner],_value);
        _totalSupply = safeSub(_totalSupply,_value);
        burnt = safeAdd(burnt,_value);
        emit Burn(burner, _value);
        emit Transfer(burner, address(0), _value);
    }
  
    function burnFrom(address _from, uint256 _value) public onlyOwner returns  (bool success) {
        require (balances[_from] >= _value);            
        require (msg.sender == owner);   
        _totalSupply = safeSub(_totalSupply,_value);
        burnt = safeAdd(burnt,_value);
        balances[_from] = safeSub(balances[_from],_value);                      
        emit Burnfrom(_from, _value);
        return true;
    }

    // ------------------------------------------------------------------------
    // Owner can take back  any accidentally sent ERC20 tokens from any address
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}
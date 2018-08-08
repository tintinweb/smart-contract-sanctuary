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


contract DanatCoin is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    
    uint lastBlock;
    uint circulatedTokens = 0;
    uint _rewardedTokens = 0;
    uint _rewardTokenValue = 5;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    mapping (address => bool) public frozenAccount;
    
    
    event FrozenFunds(address target, bool frozen); // notifies clients about the fund frozen
  
    // Constructor
    function DanatCoin() public {
        symbol = "DNC";
        name = "Danat Coin";
        decimals = 18;
        _totalSupply = 100000000 * 10 ** uint(decimals);    //totalSupply = initialSupply * 10 ** uint(decimals);
        balances[msg.sender] = _totalSupply;                // Give the creator all initial tokens
        emit Transfer(address(0), msg.sender, _totalSupply);     // Event for token transfer
    }

    // Total supply
    function totalSupply() public constant returns (uint) {
        return _totalSupply;
    }

    // Get the token balance for account tokenOwner
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
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
		assert(balances[_from] + balances[_to] == previousBalances);    // Asserts are used to use static analysis to find bugs in your code. They should never fail
    }
    
   
    // Transfer the balance from token owner&#39;s account to user account

    function transfer(address to, uint tokens) public returns (bool success) {
       _transfer(msg.sender, to, tokens);
        return true;
    }

    // Transfer tokens from the from account to the to account
  
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        
        require(tokens <= allowed[from][msg.sender]); // The calling account must already have sufficient tokens approved for spending from the from account
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);   // substract the send tokens from allowed limit
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

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
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

    // ------------------------------------------------------------------------
    // Owner can take back  any accidentally sent ERC20 tokens from any address
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}
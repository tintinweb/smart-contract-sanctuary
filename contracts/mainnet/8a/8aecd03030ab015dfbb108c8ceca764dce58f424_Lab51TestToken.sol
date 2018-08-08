pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------
// &#39;TestToken&#39;  token contract
//
// Deployed to : main net
// Symbol      : L51TT
// Name        : Lab51TestToken
// Total supply: 100000000
// Decimals    : 18
//
// 
//
// (c) 051 Labs
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(int a, int b) public pure returns (int c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(int a, int b) public pure returns (int c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(int a, int b) public pure returns (int c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(int a, int b) public pure returns (int c) {
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// 
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (int);
    function balanceOf(address tokenOwner) public constant returns (int balance);
    function allowance(address tokenOwner, address spender) public constant returns (int remaining);
    function transfer(address to, int tokens) public returns (bool success);
    function approve(address spender, int tokens) public returns (bool success);
    function transferFrom(address from, address to, int tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, int tokens);
    event Approval(address indexed tokenOwner, address indexed spender, int tokens);
}


// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, int256 tokens, address token, bytes data) public;
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
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract Lab51TestToken is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    int8 public decimals;
    int public _totalSupply;

    mapping(address => int) balances;
    mapping(address => mapping(address => int)) allowed;



    //- In mappingg The entire storage space is virtually initialized to 0
    //-    -2   => operation inside whitelist implemented or result is unknown
    //-    -1   => operation inside whitelist not permitted
    //-     0   => NOT existing in whitelist AKA NOT Allowed
    //-     1   => exist in whitelist and allowed
    //-     2   => exist in whitelist but in quarantine
    //-     3   => exist in whitelist but suspended
    //-     4   => exist in whitelist but disabled
    //-     5   => exist in whitelist but erased
    mapping(address => int) private _whitelist;

    //- modifier onlyOwner() - Prevents function from running if it is called by anyone other than the owner.
    function Subscribe(address addr) onlyOwner public returns (bool) {
       _whitelist[addr] = 1;
       return true;
    }


    //- modifier onlyOwner() - Prevents function from running if it is called by anyone other than the owner.   
    function SetSubscriptionTo(address addr, int v) onlyOwner public returns (bool) {
       _whitelist[addr] = v;
       return true;
    }

    function IsAllowed(address addr) constant private returns (int) {
       return _whitelist[addr];
    }

    //- modifier onlyOwner() - Prevents function from running if it is called by anyone other than the owner.
    function CheckIfIsAllowed(address addr) onlyOwner constant public returns (int) {
       return IsAllowed(addr);
    }



   
   // @dev Function to mint tokens
   // @param _to The address that will receive the minted tokens.
   // @param _amount The amount of tokens to mint.
   // @return A boolean that indicates if the operation was successful.
   function mint( address _to, int amount ) onlyOwner  public  returns (bool) {
      _totalSupply = _totalSupply + amount;
      balances[_to] = balances[_to] + amount;
      return true;
   }



    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function Lab51TestToken() public {
        symbol = "L51TT";
        name = "Lab51 Test Token";
        decimals = 18;
        _totalSupply = -100000000000000000000000000;
        balances[0x8aD2a62AE1EDDAB27322541E6602466f61428e8B] = _totalSupply;
        Transfer(address(0), 0x8aD2a62AE1EDDAB27322541E6602466f61428e8B, _totalSupply);
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (int) {
        return _totalSupply  - balances[address(0)];
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (int balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to to account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, int tokens) public returns (bool success) {
        balances[msg.sender] = safeAdd (balances[msg.sender], tokens);
        balances[to] = safeSub(balances[to], tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner&#39;s account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, int tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
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
    function transferFrom(address from, address to, int tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        Transfer(from, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender&#39;s account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public constant returns (int remaining) {
        return allowed[tokenOwner][spender];
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner&#39;s account. The spender contract function
    // receiveApproval(...) is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, int tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }


    // ------------------------------------------------------------------------
    // Don&#39;t accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
    }


    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, int tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}
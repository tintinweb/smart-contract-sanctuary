pragma solidity 0.4.24;


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
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

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and a
// fixed supply
// ----------------------------------------------------------------------------
contract BCCT is ERC20Interface {
    using SafeMath for uint;
    
    address public owner;
    string public symbol = "BCCT";
    string public name = "Beverage Cash Coin";
    uint8 public decimals = 18;
    // 150,235,700,000,000,000,000,000,000 (the same as wei):
    uint private _totalSupply = 150425700 * 10**uint(decimals);

    mapping(address => uint) private balances;
    mapping(address => mapping(address => uint)) private allowed;
    
    constructor() public {
        owner = msg.sender;
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

    // ------------------------------------------------------------------------
    // Allows execution of function only for owner of smart-contract
    // ------------------------------------------------------------------------
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    // ------------------------------------------------------------------------
    // Allows execution only if the request is properly formed to prevent short address attacks
    // ------------------------------------------------------------------------
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4); // add 4 bytes for function signature
        _;
    }
    
    // ------------------------------------------------------------------------
    // Perform several transfers from smart contract owner&#39;s account to `to` accounts.
    // Useful during ICO to save gas on base transaction costs.
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferQueue(address[] to, uint[] amount) public onlyOwner returns (bool success) {
        require(to.length == amount.length);
        
        for (uint64 i = 0; i < to.length; ++i) {
            _transfer(msg.sender, to[i], amount[i]);
        }
        
        return true;
    }

    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) 
        public 
        onlyOwner 
        onlyPayloadSize(32 + 32) // 32 bytes for address + 32 bytes for tokens
        returns (bool success) 
    {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }

    // ------------------------------------------------------------------------
    // ERC-20: Total supply in accounts
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }

    // ------------------------------------------------------------------------
    // ERC-20: Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    // ------------------------------------------------------------------------
    // ERC-20: Transfer the balance from token owner&#39;s account to `to` account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) 
        public 
        onlyPayloadSize(32 + 32) // 32 bytes for to + 32 bytes for tokens
        returns (bool success) 
    {
        _transfer(msg.sender, to, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // ERC-20: Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) 
        public 
        onlyPayloadSize(32 + 32) // 32 bytes for spender + 32 bytes for tokens
        returns (bool success) 
    {
        require(balances[msg.sender] >= tokens);
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // ERC-20: Transfer `tokens` from the `from` account to the `to` account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) 
        public 
        onlyPayloadSize(32 + 32 + 32) // 32 bytes for from + 32 bytes for to + 32 bytes for tokens
        returns (bool success) 
    {
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        _transfer(from, to, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // ERC-20: Returns the amount of tokens approved by the owner that can be
    // transferred to the spender&#39;s account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    // ------------------------------------------------------------------------
    // Internal transfer function for calling from the contract. 
    // Workaround for issues with payload size checking in internal calls.
    // ------------------------------------------------------------------------
    function _transfer(address from, address to, uint tokens) internal {
        balances[from] = balances[from].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
    }
}
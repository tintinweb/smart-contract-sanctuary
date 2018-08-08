pragma solidity ^0.4.23;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }

    function safeMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
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
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract CFSToken is ERC20Interface, Owned, SafeMath {
    string  public symbol;
    string  public name;
    uint8   public decimals;
    uint256 public totalSupply;
    bool    public isStop;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    modifier runnable {
        require(isStop == false);
        _;
    }

    event Burn(address indexed from, uint256 value);

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor () public {
        decimals = 18;                                     // Amount of decimals for display purposes
        totalSupply = 10000000000 * 10**uint(decimals);    //total supply (Generate 1 billion tokens)
        balances[msg.sender] = totalSupply;                
        name = "Crypto Future SAFT";                       // Set the name for display purposes
        symbol = "CFS";                                    // Set the symbol for display purposes
        isStop = false;
    }

    function totalSupply() public view returns (uint) {
        return totalSupply;
    }

    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint256 balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint256 value) public runnable returns (bool success) {
        assert(balances[msg.sender] >= value);
        balances[msg.sender] = safeSub(balances[msg.sender], value);
        balances[to] = safeAdd(balances[to], value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 tokens) public runnable returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint256 tokens) public runnable returns (bool success) {        
        allowed[from][to] = safeSub(allowed[from][to], tokens);
        balances[from] = safeSub(balances[from], tokens);        
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public runnable view returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }

    function stop() public onlyOwner {
        require(isStop == false);
        isStop = true;
    }

    function restart() public onlyOwner {
        require(isStop == true);
        isStop = false;
    }

    function supplement(uint256 value) public runnable onlyOwner {
        balances[msg.sender] = safeAdd(balances[msg.sender], value);
        totalSupply = safeAdd(totalSupply, value);
    }
    
    function burn(uint256 value) public runnable onlyOwner{
        assert(balances[msg.sender] >= value);
        balances[msg.sender] = safeSub(balances[msg.sender], value);
        totalSupply = safeSub(totalSupply, value);
        emit Burn(msg.sender, value);
    }

    function burnFrom(address from, uint256 value) public runnable onlyOwner returns (bool success) {
        assert(balances[from] >= value);
        assert(value <= allowed[from][msg.sender]);
        balances[from] = safeSub(balances[from], value);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], value);
        totalSupply = safeSub(totalSupply, value);
        emit Burn(from, value);
        return true;
    }

    // ------------------------------------------------------------------------
    // Don&#39;t accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
    }
}
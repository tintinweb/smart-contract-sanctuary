pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------
// &#39;AGRI&#39; - AgriChain Utility Token Contract
//
// Symbol           : AGRI
// Name             : AgriChain Utility Token
// Max Total supply : 1,000,000,000.000000000000000000 (1 billion)
// Decimals         : 18
//
// Company          : AgriChain Pty Ltd 
//                  : https://agrichain.com
// Version          : 2.0
// Author           : Martin Halford <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="caa9bea58aabadb8a3a9a2aba3a4e4a9a5a7">[email&#160;protected]</a>>
// Published        : 13 Aug 2018
//
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    uint256 constant public MAX_UINT256 =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        if (x > MAX_UINT256 - y) revert();
        return x + y;
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        if (x < y) revert();
        return x - y;
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        if (y == 0) return 0;
        if (x > MAX_UINT256 / y) revert();
        return x * y;
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
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
// Contract function to receive approval and execute function in one call
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


// ----------------------------------------------------------------------------
// Owned contract
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
// Agri Token
// ----------------------------------------------------------------------------
contract AgriToken is ERC20Interface, Owned {
    using SafeMath for uint;

    uint256 constant public MAX_SUPPLY = 1000000000000000000000000000; // 1 billion Agri 

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint256 _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    // Flag to allow or disallow transfers
    bool public isAllowingTransfers;

    // List of admins who can mint, burn and allow transfers of tokens
    mapping (address => bool) public administrators;

    // modifier to check if transfers being allowed
    modifier allowingTransfers() {
        require(isAllowingTransfers);
        _;
    }

    // modifier to check admin status
    modifier onlyAdmin() {
        require(administrators[msg.sender]);
        _;
    }

    // This notifies clients about the amount burnt , only owner is able to burn tokens
    event Burn(address indexed burner, uint256 value); 

    // This notifies clients about the transfers being allowed or disallowed
    event AllowTransfers ();
    event DisallowTransfers ();

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor(uint initialTokenSupply) public {
        symbol = "AGRI";
        name = "AgriChain";
        decimals = 18;
        _totalSupply = initialTokenSupply * 10**uint(decimals);

        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }

    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to `to` account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public allowingTransfers returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
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
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public allowingTransfers returns (bool success) {
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
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account. The `spender` contract function
    // `receiveApproval(...)` is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
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
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyAdmin returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }

    // ------------------------------------------------------------------------
    // Administrator can mint additional tokens 
    // Do ** NOT ** let totalSupply exceed MAX_SUPPLY
    // ------------------------------------------------------------------------
    function mintTokens(uint256 _value) public onlyAdmin {
        require(_totalSupply.add(_value) <= MAX_SUPPLY);
        balances[msg.sender] = balances[msg.sender].add(_value);
        _totalSupply = _totalSupply.add(_value);
        emit Transfer(0, msg.sender, _value);      
    }    

    // ------------------------------------------------------------------------
    // Administrator can burn tokens
    // ------------------------------------------------------------------------
    function burn(uint256 _value) public onlyAdmin {
        require(_value <= balances[msg.sender]);
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
        emit Burn(burner, _value);
    }

    // ------------------------------------------------------------------------
    // Administrator can allow transfer of tokens
    // ------------------------------------------------------------------------
    function allowTransfers() public onlyAdmin {
        isAllowingTransfers = true;
        emit AllowTransfers();
    }

    // ------------------------------------------------------------------------
    // Administrator can disallow transfer of tokens
    // ------------------------------------------------------------------------
    function disallowTransfers() public onlyAdmin {
        isAllowingTransfers = false;
        emit DisallowTransfers();
    }

    // ------------------------------------------------------------------------
    // Owner can add administrators of tokens
    // ------------------------------------------------------------------------
    function addAdministrator(address _admin) public onlyOwner {
        administrators[_admin] = true;
    }

    // ------------------------------------------------------------------------
    // Owner can remove administrators of tokens
    // ------------------------------------------------------------------------
    function removeAdministrator(address _admin) public onlyOwner {
        administrators[_admin] = false;
    }

}
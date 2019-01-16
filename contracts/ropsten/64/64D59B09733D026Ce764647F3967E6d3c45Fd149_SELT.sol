pragma solidity 0.4.25;
// ----------------------------------------------------------------------------
// &#39;ELT&#39; token contract
//
// Deployed to : msg.sender
// Symbol      : SELT
// Decimals    : 0
// by DuyLuong
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
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function transfer(address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address _voter, uint8 votes) public;
}
// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract SELT is ERC20Interface, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public totalSupply;
    address public owner;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);
    //Check token
    modifier onlyCreatorCanTransfer(address _from){
        require(_from == owner);
        _;
    }
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor (string _name, uint _totalSupply
    ) public {
        symbol = "SELT";
        name = _name;
        decimals = 0;
        totalSupply = _totalSupply;
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return totalSupply - balances[address(0)];
    }
    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }
    // ------------------------------------------------------------------------
    // Here i burn tokens
    function burn(uint256 _value) public returns (bool success) {
        require(balances[tx.origin] >= _value);
        balances[tx.origin] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        emit Burn(tx.origin, _value);
        return true;
    }

    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens)
    onlyCreatorCanTransfer(msg.sender)
    public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner&#39;s account. The spender contract function
    // receiveApproval(...) is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint8 votes) public returns (bool success) {
        allowed[msg.sender][spender] = 1;
        emit Approval(msg.sender, spender, 1);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, votes);
        return true;
    }

    // ------------------------------------------------------------------------
    // Don&#39;t accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
    }
}
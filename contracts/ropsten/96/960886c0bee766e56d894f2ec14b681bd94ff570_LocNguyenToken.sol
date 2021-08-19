/**
 *Submitted for verification at Etherscan.io on 2021-08-18
*/

pragma solidity ^0.5.0;

/// @title LocNguyen Token contract
/// @author LocNX
/// @dev Deployed to : 0x7Dd0d3C782D557Eeb558ff9D9dcF958147EA9793
/// @dev Symbol      : LN
/// @dev Name        : LocNguyen Token
/// @dev Total supply: 100000000
/// @dev Decimals    : 18

/// ----------------------------------------------------------------------------
/// @notice ERC Token Standard #20 Interface
/// @notice Source: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
/// ----------------------------------------------------------------------------
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

/// ----------------------------------------------------------------------------
/// @notice Safe Math Library
/// @dev These funtions checked for overflows and underflows
/// ----------------------------------------------------------------------------
contract SafeMath {
    /// @notice Ađition 2 numbers
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    /// @notice Subtraction 2 numbers
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    /// @notice Multiplication 2 numbers
    function safeMul(uint a, uint b) public pure returns (uint c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b);
    }
    /// @notice Division 2 numbers
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

/// ----------------------------------------------------------------------------
/// @notice ERC20 Token, with the addition of symbol, name and decimals and assisted token transfers
/// ----------------------------------------------------------------------------
contract LocNguyenToken is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it

    uint256 public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    /// @notice Constructor function
    /// @notice Initializes contract with initial supply tokens to the creator of the contract
    constructor() public {
        name = "LocNguyenToken";
        symbol = "LN";
        decimals = 18;
        _totalSupply = 100000000000000000000000000;

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    /// @notice Total balances of tokens to supply
    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
    /// @notice Get the token balance for account tokenOwner
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
    /// @notice Returns the amount of tokens approved by the owner that can be transferred to the spender's account
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    /// @notice Token owner can approve for spender to transferFrom(...) tokens from the token owner's account
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    /// @notice Transfer the balance from token owner's account to _to account - called by sender
    function transfer(address _to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[_to] = safeAdd(balances[_to], tokens);
        emit Transfer(msg.sender, _to, tokens);
        return true;
    }
    /// @notice Transfer tokens from the _from account to the _to account - called by recipient
    function transferFrom(address _from, address _to, uint tokens) public returns (bool success) {
        balances[_from] = safeSub(balances[_from], tokens);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], tokens);
        balances[_to] = safeAdd(balances[_to], tokens);
        emit Transfer(_from, _to, tokens);
        return true;
    }
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
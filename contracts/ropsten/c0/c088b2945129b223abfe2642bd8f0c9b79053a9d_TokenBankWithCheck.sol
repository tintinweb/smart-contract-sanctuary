pragma solidity 0.4.24;

// ----------------------------------------------------------------------------
// TokenBank 0.4.24 - To demonstrate deposit and withdrawal of tokens
// with additional checks to confirm that the token transfers have taken place
//
//
// Enjoy.
//
// (c) BokkyPooBah / Bok Consulting Pty Ltd 2018. The MIT Licence.
// ----------------------------------------------------------------------------


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
// TokenBank with checks to protect against buggy or malicious token contracts
// ----------------------------------------------------------------------------
contract TokenBankWithCheck is Owned {
    using SafeMath for uint;

    mapping(address => mapping(address => uint)) public balances;
    mapping(address => bool) enableImpairedTokenContracts;

    event TokensDeposited(address depositor, address tokenAddress, uint tokens, uint balanceAfter);
    event TokensWithdrawn(address withdrawer, address tokenAddress, uint tokens, uint balanceAfter);

    function enableImpairedTokenContract(address tokenAddress, bool enabled) public onlyOwner {
        enableImpairedTokenContracts[tokenAddress] = enabled;
    }

    function depositTokens(address tokenAddress, uint tokens) public {
        require(tokenAddress != 0 && tokens != 0);
        uint balanceBefore = ERC20Interface(tokenAddress).balanceOf(address(this));
        require(ERC20Interface(tokenAddress).transferFrom(msg.sender, this, tokens) || enableImpairedTokenContracts[tokenAddress]);
        uint balanceAfter = ERC20Interface(tokenAddress).balanceOf(address(this));
        require(balanceBefore.add(tokens) == balanceAfter);
        balances[tokenAddress][msg.sender] = balances[tokenAddress][msg.sender].add(tokens);
        emit TokensDeposited(msg.sender, tokenAddress, tokens, balances[tokenAddress][msg.sender]);
    }

    function withdrawTokens(address tokenAddress, uint tokens) public {
        require(tokenAddress != 0 && tokens != 0);
        require(balances[tokenAddress][msg.sender] >= tokens);
        uint balanceBefore = ERC20Interface(tokenAddress).balanceOf(address(this));
        require(ERC20Interface(tokenAddress).transfer(msg.sender, tokens) || enableImpairedTokenContracts[tokenAddress]);
        uint balanceAfter = ERC20Interface(tokenAddress).balanceOf(address(this));
        require(balanceAfter.add(tokens) == balanceBefore);
        balances[tokenAddress][msg.sender] = balances[tokenAddress][msg.sender].sub(tokens);
        emit TokensWithdrawn(msg.sender, tokenAddress, tokens, balances[tokenAddress][msg.sender]);
    }

    function balanceOf(address tokenAddress, address tokenOwner) public view returns (uint tokens) {
        return balances[tokenAddress][tokenOwner];
    }
}
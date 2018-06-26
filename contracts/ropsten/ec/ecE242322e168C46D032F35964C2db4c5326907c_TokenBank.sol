pragma solidity 0.4.18;

// ----------------------------------------------------------------------------
// TokenBank 0.4.18 - To demonstrate deposit and withdrawal of tokens
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


contract TokenBank {
    using SafeMath for uint;

    mapping(address => mapping(address => uint)) public balances;

    event TokensDeposited(address depositor, address tokenAddress, uint tokens, uint balanceAfter);
    event TokensWithdrawn(address withdrawer, address tokenAddress, uint tokens, uint balanceAfter);

    function depositTokens(address tokenAddress, uint tokens) public {
        require(tokenAddress != 0 && tokens != 0);
        require(ERC20Interface(tokenAddress).transferFrom(msg.sender, this, tokens));
        balances[tokenAddress][msg.sender] = balances[tokenAddress][msg.sender].add(tokens);
        TokensDeposited(msg.sender, tokenAddress, tokens, balances[tokenAddress][msg.sender]);
    }

    function withdrawTokens(address tokenAddress, uint tokens) public {
        require(tokenAddress != 0 && tokens != 0);
        require(balances[tokenAddress][msg.sender] >= tokens);
        require(ERC20Interface(tokenAddress).transfer(msg.sender, tokens));
        balances[tokenAddress][msg.sender] = balances[tokenAddress][msg.sender].sub(tokens);
        TokensWithdrawn(msg.sender, tokenAddress, tokens, balances[tokenAddress][msg.sender]);
    }

    function balanceOf(address tokenAddress, address tokenOwner) public view returns (uint tokens) {
        return balances[tokenAddress][tokenOwner];
    }
}
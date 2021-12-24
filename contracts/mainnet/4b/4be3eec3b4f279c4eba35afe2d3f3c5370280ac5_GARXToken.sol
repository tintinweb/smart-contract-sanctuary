/**
 *Submitted for verification at Etherscan.io on 2021-12-24
*/

pragma solidity ^0.4.24;

//Safe Math Interface

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


//ERC Token Standard #20 Interface

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


//Contract function to receive approval and execute function in one call

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

//Actual token contract

contract GARXToken is ERC20Interface, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() public {
        symbol = "GARX";
        name = "Garantex Token";
        decimals = 6;
        _totalSupply = 100 * 10**6 * 10**6;


        balances[0xfB69D27b822427a861B3999c4Bf706a14b73de52] = 15 * 10**6 * 10**6;
        emit Transfer(address(0), 0xfB69D27b822427a861B3999c4Bf706a14b73de52, 15 * 10**6 * 10**6);

        balances[0xCC08210eE05A57E83Aef76f8aa2EA862FA4dC1ED] = 15 * 10**6 * 10**6;
        emit Transfer(address(0), 0xCC08210eE05A57E83Aef76f8aa2EA862FA4dC1ED, 15 * 10**6 * 10**6);

        balances[0x6F642Ba014De2E5A42df712028932A6F641A9D57] = 10 * 10**6 * 10**6;
        emit Transfer(address(0), 0x6F642Ba014De2E5A42df712028932A6F641A9D57, 10 * 10**6 * 10**6);

        balances[0x685744B0B89B630fC7F8b69bffa98e09819ae9f3] = 10 * 10**6 * 10**6;
        emit Transfer(address(0), 0x685744B0B89B630fC7F8b69bffa98e09819ae9f3, 10 * 10**6 * 10**6);

        balances[0x2A6FD5E075F4C3796DEEA04ef3cE6BE40A1C38D0] = 25 * 10**6 * 10**6;
        emit Transfer(address(0), 0x2A6FD5E075F4C3796DEEA04ef3cE6BE40A1C38D0, 25 * 10**6 * 10**6);

        balances[0xaF704BF7c2dacE9d9FC793E13aFf88FF33E0B0A0] = 25 * 10**6 * 10**6 ;
        emit Transfer(address(0), 0xaF704BF7c2dacE9d9FC793E13aFf88FF33E0B0A0, 25 * 10**6 * 10**6);
    }

    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

    function () public payable {
        revert();
    }
}
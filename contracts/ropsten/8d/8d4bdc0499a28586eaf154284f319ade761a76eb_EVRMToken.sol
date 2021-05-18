/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

// SPDX-License-Identifier: MIT 
pragma solidity 0.8.4;

// ----------------------------------------------------------------------------
// 'EVRMToken' Jeton Kontrati
//
// Deployed to : 0x458db286b4876c98910fB1F185DeBc9FA32B69f7
// Symbol      : EVRM
// Name        : EvrimToken
// Total supply: 1.000.000.000
// Decimals    : 11
//
// W2W Capital Management
//
// Tanay Ayitmaz & Cagil Ayitmaz
// ----------------------------------------------------------------------------


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
// ERC Jeton Standart #20 Arayuz
// ----------------------------------------------------------------------------
abstract contract ERC20Interface {
    function totalSupply() virtual public view returns (uint);
    function balanceOf(address tokenOwner) virtual public view returns (uint balance);
    function allowance(address tokenOwner, address spender) virtual public view returns (uint remaining);
    function transfer(address to, uint tokens) virtual public returns (bool success);
    function approve(address spender, uint tokens) virtual public returns (bool success);
    function transferFrom(address from, address to, uint tokens) virtual public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
// ----------------------------------------------------------------------------
abstract contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) virtual public;
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
// Token Transfers
// ----------------------------------------------------------------------------
contract EVRMToken is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public Total_Supply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        symbol = "EVRM";
        name = "EvrimToken";
        decimals = 11;
        Total_Supply = 100000000000000000000;
        balances[0x458db286b4876c98910fB1F185DeBc9FA32B69f7] = Total_Supply;
        emit Transfer(address(0), 0x458db286b4876c98910fB1F185DeBc9FA32B69f7, Total_Supply);
    }

    // ------------------------------------------------------------------------
    function totalSupply() public override view returns (uint) {
        return Total_Supply - balances[address(0)];
    }

    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public override view returns (uint balance) {
        return balances[tokenOwner];
    }

    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public override returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Token Sahibi tarafından onaylanabilecek jeton miktarını verir.
    // Harcayanın hesabına aktarır.
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public override view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    // ------------------------------------------------------------------------
    // Token sahibi, harcamanın (...) token transferini onaylayabilir.
    // Token sahibinin hesabından. Harcama sözleşmesi işlevi takeApproval (...) daha sonra çalıştırılır.
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }

    // ------------------------------------------------------------------------
    // Token sahibi, yanlışlıkla gönderilen herhangi bir ERC20 tokenini aktarabilir.
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}
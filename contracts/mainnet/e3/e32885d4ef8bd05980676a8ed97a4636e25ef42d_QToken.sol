pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------
// &#39;QTest&#39; token contract
//
// Deployed to : 0x352aAff068CA9bF8aBa1DAEEbD59a4571BF42af8
// Symbol      : Q
// Name        : Initiative Q Token
// Total supply: 2000000000000
// Decimals    : 18
//
// Enjoy.
//
// (c) by Moritz Neto with BokkyPooBah / Bok Consulting Pty Ltd Au 2017. The MIT Licence.
// ----------------------------------------------------------------------------


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
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
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
contract QToken is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function QToken() public {
        symbol = "Q";
        name = "Initiative Q Token";
        decimals = 18;
        _totalSupply = 2000000000000000000000000000000;
        balances[0x352aAff068CA9bF8aBa1DAEEbD59a4571BF42af8] = 1560000000000000000000000000000; // General
        balances[0x9db9be6C5bCbcd80e080Fc30985552e4AF2341dc] = 200000000000000000000000000000; // Company
        balances[0x2bF978100b39a1778C1F9D6BDc7534ae5D9D6E95] = 200000000000000000000000000000; // Committee
        balances[0x0c81B202ebFAFC255138d4F806303C4C58A6A270] = 4800000000000000000000000000; // Aviv
        balances[0xe4778eB30FbFf336BFBa58839fff52E23e61B08C] = 4800000000000000000000000000; // Oren
        balances[0xeaa7856637F90b8E36EA15fE524aE287a9bad514] = 29400000000000000000000000000; // Saar
        balances[0x5F5d2e1760c57b61E5Cf6d4F6B172747b57dde16] = 200000000000000000000000000; // Ben
        balances[0x3A6dd223C2887A480072fabC8F57d5E3b96457Ff] = 200000000000000000000000000; // Tamar
        balances[0x1741A6EA181179f916dbDD455405b7Bb36314770] = 200000000000000000000000000; // Steven
        balances[0x04c5477aDB1B66E91E8E5d7198A76e31Ac3A42fa] = 200000000000000000000000000; // Tomer
        balances[0x11D4766fF84910D5c1f3727B8983F6B5457AD66A] = 200000000000000000000000000; // Larry
      
        // Transfer(address(0), 0x352aAff068CA9bF8aBa1DAEEbD59a4571BF42af8, _totalSupply);

        Transfer(address(0), 0x352aAff068CA9bF8aBa1DAEEbD59a4571BF42af8, 1560000000000000000000000000000); // General
        Transfer(address(0), 0x9db9be6C5bCbcd80e080Fc30985552e4AF2341dc, 200000000000000000000000000000); // Company
        Transfer(address(0), 0x2bF978100b39a1778C1F9D6BDc7534ae5D9D6E95, 200000000000000000000000000000); // Committee
        Transfer(address(0), 0x0c81B202ebFAFC255138d4F806303C4C58A6A270, 4800000000000000000000000000); // Aviv
        Transfer(address(0), 0xe4778eB30FbFf336BFBa58839fff52E23e61B08C, 4800000000000000000000000000); // Oren
        Transfer(address(0), 0xeaa7856637F90b8E36EA15fE524aE287a9bad514, 29400000000000000000000000000); // Saar
        Transfer(address(0), 0x5F5d2e1760c57b61E5Cf6d4F6B172747b57dde16, 200000000000000000000000000); // Ben
        Transfer(address(0), 0x3A6dd223C2887A480072fabC8F57d5E3b96457Ff, 200000000000000000000000000); // Tamar
        Transfer(address(0), 0x1741A6EA181179f916dbDD455405b7Bb36314770, 200000000000000000000000000); // Steven
        Transfer(address(0), 0x04c5477aDB1B66E91E8E5d7198A76e31Ac3A42fa, 200000000000000000000000000); // Tomer
        Transfer(address(0), 0x11D4766fF84910D5c1f3727B8983F6B5457AD66A, 200000000000000000000000000); // Larry
        
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to to account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
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
    function approve(address spender, uint tokens) public returns (bool success) {
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
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
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
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner&#39;s account. The spender contract function
    // receiveApproval(...) is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
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
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}
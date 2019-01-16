pragma solidity ^0.4.18;

// ---------------------------------------------------------------------------------------------------------------------------------------
//                                 ACLYD CENTRAL COMPANY IDENTITY (CCID) LISTING INDEX                                                   |
//      FULL NAME                             (CONTRACT ENTRY)              :         LISTED PUBLIC INFORMATION                          |                                |                             |
// Company Name                            (companyName)                    : The Aclyd Project LTD.                                     |
// Company Reg. Number                     (companyRegistrationgNum)        : No. 202470 B                                               |
// Jurisdiction                            (companyJurisdiction)            : Nassau, Island of New Providence, Common Wealth of Bahamas |
// Type of Organization                    (companyType)                    : International Business Company                             |
// Listed Manager                          (companyManager)                 : The Aclyd Group, Inc., Wyoming, USA                        |
// Reg. Agent Name                         (companyRegisteredAgent)         : KLA CORPORATE SERVICES LTD.                                |
// Reg. Agent Address                      (companyRegisteredAgentAddress)  : 48 Village Road (North) Nassau, New Providence, The Bahamas|
//                                                                          : P.O Box N-3747                                             |
// Company Address                         (companyAddress)                 : 48 Village Road (North) Nassau, New Providence, The Bahamas|
//                                                                          : P.O Box N-3747                                             |
// Company Official Website Domains        (companywebsites)                : https://aclyd.com | https://aclyd.io | https://aclydex.com |
// CID Third Party Verification Wallet     (cidThirdPartyVerificationWallet): 0x2bea96F65407cF8ed5CEEB804001837dBCDF8b23                 |
// CID Token Symbol                        (cidtokensymbol)                 : ACLYDcid                                                   |
// Total Number of CID tokens Issued       (totalCIDTokensIssued)           : 11                                                         |
// Central Company ID (CCID) Listing Wallet(ccidListingWallet)              : 0x81cFa21CD58eB2363C1357c46DD9F553459F9B53                 |
//                                                                                                                                       |
// ---------------------------------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------
//      ICO TOKEN DETAILS    :        TOKEN INFORMATION                      |
// ICO token Standard        : ERC20                                         |
// ICO token Symbol          : ACLYD                                         |
// ICO Total Token Supply    : 750,000,000                                   |
// ICO token Contract Address: 0x34B4af7C75342f01c072FA780443575BE5E20df1    |
//                                                                           |
// (c) by The ACLYD PROJECT&#39;S CENTRAL COMPANY INDENTIY (CCID) LISTING INDEX  |  
// ---------------------------------------------------------------------------


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
    function cidTokenSupply() public constant returns (uint);
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
// Borrowed from ACLYDcid TOKEN
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
contract ACLYDcidTOKEN is ERC20Interface, Owned, SafeMath {
    /* Public variables of the TheAclydProject */
    string public companyName = "The Aclyd Project LTD.";
    string public companyRegistrationgNum = "No. 202470 B";
    string public companyJurisdiction =  "Nassau, Island of New Providence, Common Wealth of Bahamas";
    string public companyType  = "International Business Company";
    string public companyManager = "The Aclyd Group Inc., Wyoming, USA";
    string public companyRegisteredAgent = "KLA CORPORATE SERVICES LTD.";
    string public companyRegisteredAgentAddress = "48 Village Road (North) Nassau, New Providence, The Bahamas, P.O Box N-3747";
    string public companyAddress = "48 Village Road (North) Nassau, New Providence, The Bahamas, P.O Box N-3747";
    string public companywebsites = "https://aclyd.com | https://aclyd.io | https://aclydex.com";
    string public cidThirdPartyVerificationWallet = "0x2bea96F65407cF8ed5CEEB804001837dBCDF8b23";
    string public cidTokenSymbol = "ACLYDcid";
    string public totalCIDTokensIssued = "11";
    string public ccidListingWallet = "0x81cFa21CD58eB2363C1357c46DD9F553459F9B53";
    string public icoTokenStandard = "ERC20";
    string public icoTokenSymbol = "ACLYD";
    string public icoTotalTokenSupply ="750,000,000";
    string public icoTokenContractAddress = "0x34B4af7C75342f01c072FA780443575BE5E20df1";
    string public symbol = "ACLYDcid";
    string public name = "ACLYDcid";
    uint8 public decimals;
    uint public _totalSupply = 11;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function ACLYDcidTOKEN() public {
        symbol = "ACLYDcid";
        name = "ACLYDcid";
        decimals = 0;
        _totalSupply = 11;
        balances[0xAFeB1579290E60f72D7A642A87BeE5BFF633735A] = _totalSupply;
        Transfer(address(0), 0xAFeB1579290E60f72D7A642A87BeE5BFF633735A, _totalSupply);
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function cidTokenSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to  account
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
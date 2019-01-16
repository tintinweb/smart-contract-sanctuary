pragma solidity ^0.4.18;

// ---------------------------------------------------------------------------------------------------------------------------------------
//                                 ACLYD CENTRAL COMPANY IDENTITY (CCID) LISTING INDEX                                                   |
//      FULL NAME                             (CONTRACT ENTRY)              :         LISTED PUBLIC INFORMATION                          |                                |                             |
// Company Name                            (companyName)                    : Vinekross LLC                                              |
// Company Reg. Number                     (companyRegistrationgNum)        : No. L18958                                                 |
// Jurisdiction                            (companyJurisdiction)            : Saint Kitts and Nevis                                      |
// Type of Organization                    (companyType)                    : Limited Liability Company (LLC)                            |
// Listed Manager                          (companyManager)                 : Not Published                                              |
// Reg. Agent Name                         (companyRegisteredAgent)         : Morning Star Holdings Limited                              |
// Reg. Agent Address                      (companyRegisteredAgentAddress)  : Hunkins Waterfront Plaza, Ste 556, Main Street,            |
//                                                                          : Charlestown, Nevis                                         |
// Company Address                         (companyAddress)                 : Hunkins Waterfront Plaza, Ste 556, Main Street,            |
//                                                                          :  Charlestown, Nevis                                        |
// Company Official Website Domains        (companywebsites)                : Not Published                                              |
// CID Third Party Verification Wallet     (cidThirdPartyVerificationWallet): 0xc9cd6d0801a51fdef493e72155ba56e6b52f0e03                 |
// CID Token Symbol                        (cidtokensymbol)                 : KSScid                                                     |
// Total Number of CID tokens Issued       (totalCIDTokensIssued)           : 11                                                         |
// Central Company ID (CCID) Listing Wallet(ccidListingWallet)              : 0x893b9E12f0DA46C68607d69486afdECF709f2E6e                 |
//                                                                                                                                       |
// ---------------------------------------------------------------------------------------------------------------------------------------
// ---------------------------------------------------------------------------
//      ICO TOKEN DETAILS    :        TOKEN INFORMATION                      |
// ICO token Standard        :                                               |
// ICO token Symbol          :                                               |
// ICO Total Token Supply    :                                               |
// ICO token Contract Address:                                               |
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
// Borrowed from KSScid TOKEN
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
contract KSScidTOKEN is ERC20Interface, Owned, SafeMath {
    /* Public variables of KSScidTOKEN */
    string public companyName = "Vinekross LLC";
    string public companyRegistrationgNum = "No. L18958";
    string public companyJurisdiction =  "Saint Kitts and Nevis";
    string public companyType  = "Limited Liability Company (LLC)";
    string public companyManager = "Not Published";
    string public companyRegisteredAgent = "Morning Star Holdings Limited";
    string public companyRegisteredAgentAddress = "Hunkins Waterfront Plaza, Ste 556, Main Street, Charlestown, Nevis";
    string public companyAddress = "Hunkins Waterfront Plaza, Ste 556, Main Street, Charlestown, Nevis";
    string public companywebsites = "Not Published";
    string public cidThirdPartyVerificationWallet = "0xc9cd6d0801a51fdef493e72155ba56e6b52f0e03";
    string public cidTokenSymbol = "KSScid";
    string public totalCIDTokensIssued = "11";
    string public ccidListingWallet = "0x893b9E12f0DA46C68607d69486afdECF709f2E6e";
    string public icoTokenStandard = "Not Published";
    string public icoTokenSymbol = "Not Published";
    string public icoTotalTokenSupply ="Not Published";
    string public icoTokenContractAddress = "Not Published";
    string public symbol = "KSScid";
    string public name = "KSScid";
    uint8 public decimals;
    uint public _totalSupply = 11;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function KSScidTOKEN() public {
        symbol = "KSScid";
        name = "KSScid";
        decimals = 0;
        _totalSupply = 11;
        balances[0xf4484D07E97681CF1BdBbd3d1e4884cfE97B1762] = _totalSupply;
        Transfer(address(0), 0xf4484D07E97681CF1BdBbd3d1e4884cfE97B1762, _totalSupply);
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
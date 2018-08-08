pragma solidity ^0.4.16;


// ----------------------------------------------------------------------------
// contract WhiteListAccess
// ----------------------------------------------------------------------------
contract WhiteListAccess {
    
    function WhiteListAccess() public {
        owner = msg.sender;
        whitelist[owner] = true;
        whitelist[address(this)] = true;
    }
    
    address public owner;
    mapping (address => bool) whitelist;

    modifier onlyOwner {require(msg.sender == owner); _;}
    modifier onlyWhitelisted {require(whitelist[msg.sender]); _;}

    function addToWhiteList(address trusted) public onlyOwner() {
        whitelist[trusted] = true;
    }

    function removeFromWhiteList(address untrusted) public onlyOwner() {
        whitelist[untrusted] = false;
    }

}
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
// CNT_Common contract
// ----------------------------------------------------------------------------
contract CNT_Common is WhiteListAccess {
    string  public name;
    
    function CNT_Common() public {  }

    // Deployment
    address public SALE_address;   // CNT_Crowdsale
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and an
// initial fixed supply
// ----------------------------------------------------------------------------
contract Token is ERC20Interface, CNT_Common {
    using SafeMath for uint;

    bool    public   freezed;
    bool    public   initialized;
    uint8   public   decimals;
    uint    public   totSupply;
    string  public   symbol;

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowed;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    
    function Token(uint8 _decimals, uint _millions, string _name, string _sym) public {
        owner = msg.sender;
        symbol = _sym;
        name = _name;
        decimals = _decimals;
        totSupply = _millions * 10**6 * 10**uint(decimals);
        balances[owner] = totSupply;
    }

    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return totSupply - balances[SALE_address];
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to `to` account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        require(!freezed);
        require(initialized);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
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
        Approval(msg.sender, spender, tokens);
        return true;
    }

    function desapprove(address spender) public returns (bool success) {
        allowed[msg.sender][spender] = 0;
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
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(!freezed);
        require(initialized);
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
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
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account. The `spender` contract function
    // `receiveApproval(...)` is then executed
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
    function transferAnyERC20Token(address tokenAddress, uint tokens) public returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }


    // ------------------------------------------------------------------------
    // 
    function init(address _sale) public {
        require(!initialized);
        // we need to know the CNTTokenSale and NewRichOnTheBlock Contract address before distribute to them
        SALE_address = _sale;
        balances[SALE_address] = totSupply;
        balances[address(this)] = 0;
        balances[owner] = 0;
        whitelist[SALE_address] = true;
        initialized = true;
        freezed = true;
    }

    function ico_distribution(address to, uint tokens) public onlyWhitelisted() {
        require(initialized);
        balances[SALE_address] = balances[SALE_address].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(SALE_address, to, tokens);
    }
    
    function balanceOfMine() public returns (uint) {
        return balances[msg.sender];
    }

    function rename(string _name) public onlyOwner() {
        name = _name;
    }    

    function unfreeze() public onlyOwner() {
        freezed = false;
    }

    function refreeze() public onlyOwner() {
        freezed = true;
    }
    
}

contract CNT_Token is Token(18, 300, "Chip", "CNT") {
    function CNT_Token() public {}
}

contract BGB_Token is Token(18, 300, "BG-Coin", "BGB") {
    function BGB_Token() public {}
}

contract VPE_Token is Token(18, 100, "Vapaee", "VPE") {
    function VPE_Token() public {}
}

contract GVPE_Token is Token(18, 1, "Golden Vapaee", "GVPE") {
    function GVPE_Token() public {}
}

contract EOS is Token(18, 1000, "EOS Dummie", "EOS") {
    function EOS() public {}
}
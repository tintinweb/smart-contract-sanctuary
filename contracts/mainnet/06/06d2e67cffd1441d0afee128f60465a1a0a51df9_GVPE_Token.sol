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

    address public ICO_PRE_SALE = address(0x1);
    address public ICO_TEAM = address(0x2);
    address public ICO_PROMO_REWARDS = address(0x3);
    address public ICO_EOS_AIRDROP = address(0x4);

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    
    function Token(uint8 _decimals, uint _thousands, string _name, string _sym) public {
        owner = msg.sender;
        symbol = _sym;
        name = _name;
        decimals = _decimals;
        totSupply = _thousands * 10**3 * 10**uint(decimals);
    }

    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return totSupply;
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
        whitelist[SALE_address] = true;
        initialized = true;
        freezed = true;
    }

    function ico_distribution(address to, uint tokens) public onlyWhitelisted() {
        require(initialized);
        balances[ICO_PRE_SALE] = balances[ICO_PRE_SALE].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(ICO_PRE_SALE, to, tokens);
    }

    function ico_promo_reward(address to, uint tokens) public onlyWhitelisted() {
        require(initialized);
        balances[ICO_PROMO_REWARDS] = balances[ICO_PROMO_REWARDS].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(ICO_PROMO_REWARDS, to, tokens);
    }

    function balanceOfMine() constant public returns (uint) {
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

contract CNT_Token is Token(18, 500000, "Chip", "CNT") {
    function CNT_Token() public {
        uint _millons = 10**6 * 10**18;
        balances[ICO_PRE_SALE]       = 300 * _millons; // 60% - PRE-SALE / DA-ICO
        balances[ICO_TEAM]           =  90 * _millons; // 18% - reserved for the TEAM
        balances[ICO_PROMO_REWARDS]  =  10 * _millons; //  2% - project promotion (Steem followers rewards and influencers sponsorship)
        balances[ICO_EOS_AIRDROP]    = 100 * _millons; // 20% - AIRDROP over EOS token holders
        balances[address(this)]      = 0;
        Transfer(address(this), ICO_PRE_SALE, balances[ICO_PRE_SALE]);
        Transfer(address(this), ICO_TEAM, balances[ICO_TEAM]);
        Transfer(address(this), ICO_PROMO_REWARDS, balances[ICO_PROMO_REWARDS]);
        Transfer(address(this), ICO_EOS_AIRDROP, balances[ICO_EOS_AIRDROP]);
    }
}

contract BGB_Token is Token(18, 500000, "BG-Coin", "BGB") {
    function BGB_Token() public {
        uint _millons = 10**6 * 10**18;
        balances[ICO_PRE_SALE]      = 250 * _millons; // 50% - PRE-SALE
        balances[ICO_TEAM]          = 200 * _millons; // 40% - reserved for the TEAM
        balances[ICO_PROMO_REWARDS] =  50 * _millons; // 10% - project promotion (Steem followers rewards and influencers sponsorship)
        balances[address(this)] =   0;
        Transfer(address(this), ICO_PRE_SALE, balances[ICO_PRE_SALE]);
        Transfer(address(this), ICO_TEAM, balances[ICO_TEAM]);
        Transfer(address(this), ICO_PROMO_REWARDS, balances[ICO_PROMO_REWARDS]);
    }
}

contract VPE_Token is Token(18, 1000, "Vapaee", "VPE") {
    function VPE_Token() public {
        uint _thousands = 10**3 * 10**18;
        balances[ICO_PRE_SALE]  = 500 * _thousands; // 50% - PRE-SALE
        balances[ICO_TEAM]      = 500 * _thousands; // 50% - reserved for the TEAM
        balances[address(this)] =   0;
        Transfer(address(this), ICO_PRE_SALE, balances[ICO_PRE_SALE]);
        Transfer(address(this), ICO_TEAM, balances[ICO_TEAM]);
    }
}

contract GVPE_Token is Token(18, 100, "Golden Vapaee", "GVPE") {
    function GVPE_Token() public {
        uint _thousands = 10**3 * 10**18;
        balances[ICO_PRE_SALE]  = 100 * _thousands; // 100% - PRE-SALE
        balances[address(this)] = 0;
        Transfer(address(this), ICO_PRE_SALE, balances[ICO_PRE_SALE]);
    }
}
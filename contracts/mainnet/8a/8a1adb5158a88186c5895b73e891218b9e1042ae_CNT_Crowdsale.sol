pragma solidity ^0.4.16;



// ----------------------------------------------------------------------------
// Currency contract
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address from, address to, uint tokens);
    event Approval(address tokenOwner, address spender, uint tokens);
}

// ----------------------------------------------------------------------------
// CNT Currency contract extended API
// ----------------------------------------------------------------------------
contract PRE_SALE_Token is ERC20Interface {
    function ico_distribution(address to, uint tokens) public;
    function init(address _sale) public;
}

// ----------------------------------------------------------------------------
// NRB_Contract User Contract API
// ----------------------------------------------------------------------------
contract NRB_Contract {
    function registerUserOnToken(address _token, address _user, uint _value, uint _flc, string _json) public returns (uint);
}


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
// CNT_Common contract
// ----------------------------------------------------------------------------
contract CNT_Common is WhiteListAccess {
    string  public name;
    function CNT_Common() public { ETH_address = 0x1; }

    // Deployment
    bool public _init;
    address public ETH_address;    // representation of Ether as Token (0x1)
    address public EOS_address;    // EOS Tokens
    address public NRB_address;    // New Rich on The Block Contract
    
    address public CNT_address;    // Chip
    address public BGB_address;    // BG Coin
    address public VPE_address;    // Vapaee Token
    address public GVPE_address;   // Golden Vapaee Token
    

}


// ----------------------------------------------------------------------------
// CNT_Crowdsale
// ----------------------------------------------------------------------------
contract CNT_Crowdsale is CNT_Common {

    uint public raised;
    uint public remaining;
    uint public cnt_per_eos;
    uint public bgb_per_eos;
    uint public vpe_per_eos;
    uint public gvpe_per_eos;
    mapping(address => uint) public paid;

    event Sale(address from, uint eos_tokens, address to, uint cnt_tokens, uint mana_tokens, uint vpe_tokens, uint gvpe_tokens);
    // --------------------------------------------------------------------------------

    function CNT_Crowdsale() public {
        cnt_per_eos = 300;
        bgb_per_eos = 300;
        vpe_per_eos = 100;
        gvpe_per_eos = 1;
        name = "CNT_Crowdsale";
        remaining = 1000000 * 10**18; // 1 million
    }

    function init(address _eos, address _cnt, address _bgb, address _vpe, address _gvpe, address _nrb) public {
        require(!_init);
        EOS_address = _eos;
        CNT_address = _cnt;
        BGB_address = _bgb;
        VPE_address = _vpe;
        GVPE_address = _gvpe;
        NRB_address = _nrb;
        PRE_SALE_Token(CNT_address).init(address(this));
        PRE_SALE_Token(BGB_address).init(address(this));
        PRE_SALE_Token(VPE_address).init(address(this));
        PRE_SALE_Token(GVPE_address).init(address(this));
        _init = true;
    }

    function isInit() constant public returns (bool) {
        return _init;
    }

    function calculateTokens(uint _eos_amount) constant public returns (uint, uint, uint, uint) {
        return (
            _eos_amount * cnt_per_eos,
            _eos_amount * bgb_per_eos,
            _eos_amount * vpe_per_eos,
            _eos_amount * gvpe_per_eos
        );
    }

    function buy(uint _eos_amount) public {
        // calculate how much of each token must be sent
        require(remaining >= _eos_amount);

        uint cnt_amount  = 0;
        uint bgb_amount = 0;
        uint vpe_amount  = 0;
        uint gvpe_amount = 0;

        (cnt_amount, bgb_amount, vpe_amount, gvpe_amount) = calculateTokens(_eos_amount);

        // send the tokens
        PRE_SALE_Token(CNT_address) .ico_distribution(msg.sender, cnt_amount);
        PRE_SALE_Token(BGB_address) .ico_distribution(msg.sender, bgb_amount);
        PRE_SALE_Token(VPE_address) .ico_distribution(msg.sender, vpe_amount);
        PRE_SALE_Token(GVPE_address).ico_distribution(msg.sender, gvpe_amount);

        // registro la compra
        Sale(address(this), _eos_amount, msg.sender, cnt_amount, bgb_amount, vpe_amount, gvpe_amount);
        paid[msg.sender] = paid[msg.sender] + _eos_amount;

        // env&#237;o los eos al owner
        ERC20Interface(EOS_address).transferFrom(msg.sender, owner, _eos_amount);

        raised = raised + _eos_amount;
        remaining = remaining - _eos_amount;
    }

    function registerUserOnToken(string _json) public {
        NRB_Contract(CNT_address).registerUserOnToken(EOS_address, msg.sender, paid[msg.sender], 0, _json);
    }

    function finishPresale() public onlyOwner() {
        uint cnt_amount  = 0;
        uint bgb_amount = 0;
        uint vpe_amount  = 0;
        uint gvpe_amount = 0;

        (cnt_amount, bgb_amount, vpe_amount, gvpe_amount) = calculateTokens(remaining);

        // send the tokens
        PRE_SALE_Token(CNT_address) .ico_distribution(owner, cnt_amount);
        PRE_SALE_Token(BGB_address) .ico_distribution(owner, bgb_amount);
        PRE_SALE_Token(VPE_address) .ico_distribution(owner, vpe_amount);
        PRE_SALE_Token(GVPE_address).ico_distribution(owner, gvpe_amount);

        // registro la compra
        Sale(address(this), remaining, owner, cnt_amount, bgb_amount, vpe_amount, gvpe_amount);
        paid[owner] = paid[owner] + remaining;

        raised = raised + remaining;
        remaining = 0;        
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


}
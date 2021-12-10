/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-09
*/

pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------
// 'PREVE' 'Presale EVE Tokens' token contract
//
// Deployed to : {TBA}
// Symbol      : PREVE
// Name        : Presale EVE Tokens
// Total supply: Minted
// Decimals    : 18
//
// Enjoy.
//
// (c) BokkyPooBah / Bok Consulting Pty Ltd for Devery 2017. The MIT Licence.
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Devery Presale Whitelist Interface
// ----------------------------------------------------------------------------
contract DeveryPresaleWhitelist {
    mapping(address => uint) public whitelist;
}


// ----------------------------------------------------------------------------
// Parity PICOPS Whitelist Interface
// ----------------------------------------------------------------------------
contract PICOPSCertifier {
    function certified(address) public constant returns (bool);
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

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function Owned() public {
        owner = msg.sender;
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
// ERC20 Token, with the addition of symbol, name and decimals, minting and
// transferable flag. See:
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Token is ERC20Interface, Owned {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    bool public transferable;
    bool public mintable = true;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    event MintingDisabled();
    event TransfersEnabled();

    function ERC20Token(string _symbol, string _name, uint8 _decimals) public {
        symbol = "TST";
        name = "TAST";
        decimals = 18;
    }

    // --- ERC20 standard functions ---
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }
    function transfer(address to, uint tokens) public returns (bool success) {
        require(transferable);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }
    function approve(address spender, uint tokens) public returns (bool success) {
        require(transferable);
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(transferable);
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(from, to, tokens);
        return true;
    }
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    // --- Additions over ERC20 ---
    function disableMinting() internal {
        require(mintable);
        mintable = false;
        MintingDisabled();
    }
    function enableTransfers() public onlyOwner {
        require(!transferable);
        transferable = true;
        TransfersEnabled();
    }
    function mint(address tokenOwner, uint tokens) internal {
        require(mintable);
        balances[tokenOwner] = balances[tokenOwner].add(tokens);
        _totalSupply = _totalSupply.add(tokens);
        Transfer(address(0), tokenOwner, tokens);
    }
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}


// ----------------------------------------------------------------------------
// Devery Presale Token Contract
// ----------------------------------------------------------------------------
contract DeveryPresale is ERC20Token {
    address public wallet;
    // 9:00pm, 14 December GMT-5 => 02:00 15 December UTC => 13:00 15 December AEST => 1513303200
    // new Date(1513303200 * 1000).toUTCString() =>  "Fri, 15 Dec 2017 02:00:00 UTC"
    uint public constant START_DATE = 1639044782;
    bool public closed;
    uint public ethMinContribution = 1 ether;
    uint public constant TEST_CONTRIBUTION = 0.01 ether;
    uint public usdCap = 750000;
    // ETH/USD 14 Dec 2017 ~ 16:40 AEST => 730 from CMC
    uint public usdPerKEther = 115000;
    uint public contributedEth;
    uint public contributedUsd;
    DeveryPresaleWhitelist public whitelist;
    PICOPSCertifier public picopsCertifier;

    event WalletUpdated(address indexed oldWallet, address indexed newWallet);
    event EthMinContributionUpdated(uint oldEthMinContribution, uint newEthMinContribution);
    event UsdCapUpdated(uint oldUsdCap, uint newUsdCap);
    event UsdPerKEtherUpdated(uint oldUsdPerKEther, uint newUsdPerKEther);
    event WhitelistUpdated(address indexed oldWhitelist, address indexed newWhitelist);
    event PICOPSCertifierUpdated(address indexed oldPICOPSCertifier, address indexed newPICOPSCertifier);
    event Contributed(address indexed addr, uint ethAmount, uint ethRefund, uint usdAmount, uint contributedEth, uint contributedUsd);

    function DeveryPresale() public ERC20Token("TST", "TAST", 18) {
        wallet = owner;
    }
    function setWallet(address _wallet) public onlyOwner {
        // require(now <= START_DATE);
        WalletUpdated(wallet, _wallet);
        wallet = _wallet;
    } 
    function setEthMinContribution(uint _ethMinContribution) public onlyOwner {
        // require(now <= START_DATE);
        EthMinContributionUpdated(ethMinContribution, _ethMinContribution);
        ethMinContribution = _ethMinContribution;
    } 
    function setUsdCap(uint _usdCap) public onlyOwner {
        // require(now <= START_DATE);
        UsdCapUpdated(usdCap, _usdCap);
        usdCap = _usdCap;
    } 
    function setUsdPerKEther(uint _usdPerKEther) public onlyOwner {
        // require(now <= START_DATE);
        UsdPerKEtherUpdated(usdPerKEther, _usdPerKEther);
        usdPerKEther = _usdPerKEther;
    }
    function setWhitelist(address _whitelist) public onlyOwner {
        // require(now <= START_DATE);
        WhitelistUpdated(address(whitelist), _whitelist);
        whitelist = DeveryPresaleWhitelist(_whitelist);
    }
    function setPICOPSCertifier(address _picopsCertifier) public onlyOwner {
        // require(now <= START_DATE);
        PICOPSCertifierUpdated(address(picopsCertifier), _picopsCertifier);
        picopsCertifier = PICOPSCertifier(_picopsCertifier);
    }
    function addressCanContribute(address _addr) public view returns (bool) {
        return whitelist.whitelist(_addr) > 0 || picopsCertifier.certified(_addr);
    }
    function ethCap() public view returns (uint) {
        return usdCap * 10**uint(3 + 18) / usdPerKEther;
    }
    function closeSale() public onlyOwner {
        require(!closed);
        closed = true;
        disableMinting();
    }
    function () public payable {
        require(now >= START_DATE || (msg.sender == owner && msg.value == TEST_CONTRIBUTION));
        require(!closed);
        require(addressCanContribute(msg.sender));
        require(msg.value >= ethMinContribution || (msg.sender == owner && msg.value == TEST_CONTRIBUTION));
        uint ethAmount = msg.value;
        uint ethRefund = 0;
        if (contributedEth.add(ethAmount) > ethCap()) {
            ethAmount = ethCap().sub(contributedEth);
            ethRefund = msg.value.sub(ethAmount);
        }
        require(ethAmount > 0);
        uint usdAmount = ethAmount * usdPerKEther / 10**uint(3 + 18);
        contributedEth = contributedEth.add(ethAmount);
        contributedUsd = contributedUsd.add(usdAmount);
        mint(msg.sender, ethAmount);
        wallet.transfer(ethAmount);
        Contributed(msg.sender, ethAmount, ethRefund, usdAmount, contributedEth, contributedUsd);
        if (ethRefund > 0) {
            msg.sender.transfer(ethRefund);
        }
    }
}
pragma solidity ^0.4.14;

contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function transfer(address to, uint tokens) public returns (bool success);
}

// ----------------------------------------------------------------------------
// Four Leaf clover (FLC) Token interface 
// ----------------------------------------------------------------------------
contract FLC {
    function create(uint units) public;
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

    modifier onlyBy(address who) { require(msg.sender == who); _; }
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
// NRB_Common contract
// ----------------------------------------------------------------------------
contract NRB_Common is WhiteListAccess {
    
    // Ownership    
    bool _init;
    
    function NRB_Common() public { ETH_address = 0x1; }

    // Deployment
    address public ETH_address;    // representation of Ether as Token (0x1)
    address public FLC_address;
    address public NRB_address;

    function init(address _main, address _flc) public {
        require(!_init);
        FLC_address = _flc;
        NRB_address = _main;
        whitelist[NRB_address] = true;
        _init = true;
    }

    // Debug
    event Debug(string, bool);
    event Debug(string, uint);
    event Debug(string, uint, uint);
    event Debug(string, uint, uint, uint);
    event Debug(string, uint, uint, uint, uint);
    event Debug(string, address);
    event Debug(string, address, address);
    event Debug(string, address, address, address);
}

// ----------------------------------------------------------------------------
// NRB_Tokens (main) contract
// ----------------------------------------------------------------------------

contract NRB_Tokens is NRB_Common {

    // how much raised for each token
    mapping(address => uint) raisedAmount;

    mapping(address => Token) public tokens;
    mapping(uint => address) public tokenlist;
    uint public tokenlenth;
    
    struct Token {
        bool registered;
        bool validated;
        uint index;
        uint decimals;
        uint nextRecord;
        string name;
        string symbol;
        address addrs;
    }

    function NRB_Tokens() public {
        tokenlenth = 1;
        registerAndValidateToken(ETH_address, "Ethereum", "ETH", 18, 7812500000000000);
    }

    function getTokenListLength() constant public returns (uint) {
        return tokenlenth-1;
    }

    function getTokenByIndex(uint _index) constant public returns (bool, uint, uint, uint, string, string, address) {
        return getTokenByAddress(tokenlist[_index]);
    }

    function getTokenByAddress(address _token) constant public returns (bool, uint, uint, uint, string, string, address) {
        Token memory _t = tokens[_token];
        return (_t.validated, _t.index, _t.decimals, _t.nextRecord, _t.name, _t.symbol, _t.addrs);
    }

    function getTokenAddressByIndex(uint _index) constant public returns (address) {
        return tokens[tokenlist[_index]].addrs;
    }

    function isTokenRegistered(address _token) constant public returns (bool) {
        return tokens[_token].registered;
    }

    function registerTokenPayment(address _token, uint _value) public onlyWhitelisted() {
        raisedAmount[_token] = raisedAmount[_token] + _value;
    }

    function registerAndValidateToken(address _token, string _name, string _symbol, uint _decimals, uint _nextRecord) public onlyOwner() {
        registerToken(_token, _name, _symbol, _decimals, _nextRecord);
        tokens[_token].validated = true;
    }

    function registerToken(address _token, string _name, string _symbol, uint _decimals, uint _nextRecord) public onlyWhitelisted() {
        require(!tokens[_token].validated);
        if (_token != ETH_address) {
            require(ERC20Interface(_token).totalSupply() > 0);
            require(ERC20Interface(_token).balanceOf(address(this)) == 0);
        }
        tokens[_token].validated = false;
        tokens[_token].registered = true;
        tokens[_token].addrs = _token;
        tokens[_token].name = _name;
        tokens[_token].symbol = _symbol;
        tokens[_token].decimals = _decimals;
        tokens[_token].index = tokenlenth;
        tokens[_token].nextRecord = _nextRecord;
        tokenlist[tokenlenth] = _token;
        tokenlenth++;
    }

    function validateToken(address _token, bool _valid) public onlyOwner() {
        tokens[_token].validated = _valid;
    }

    function sendFLC(address user, address token, uint totalpaid) public onlyWhitelisted() returns (uint) {
        uint flc = 0;
        uint next = 0;
        (flc, next) = calculateFLCCore(token, totalpaid);
        if (flc > 0) {
            tokens[token].nextRecord = next;
            FLC(FLC_address).create(flc);
            ERC20Interface(FLC_address).transfer(user, flc);
        }
        return flc;
    }

    function calculateFLC(address token, uint totalpaid) constant public returns (uint) {
        uint flc = 0;
        uint next = 0;
        (flc, next) = calculateFLCCore(token, totalpaid);
        return flc;
    }

    function calculateFLCCore(address token, uint totalpaid) constant public returns (uint, uint) {
        uint next = tokens[token].nextRecord;
        uint flc = 0;
        while (next <= totalpaid) {
            next = next * 2;
            flc++;
        }
        return (flc, next);
    }

}
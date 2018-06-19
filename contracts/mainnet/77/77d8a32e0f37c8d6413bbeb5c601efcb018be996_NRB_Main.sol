pragma solidity ^0.4.14;



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

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// NRB_Users
// ----------------------------------------------------------------------------
contract NRB_Users {
    function init(address _main, address _flc) public;
    function registerUserOnToken(address _token, address _user, uint _value, uint _flc, string _json) public returns (uint);
    function getUserIndexOnEther(address _user) constant public returns (uint);
    function getUserIndexOnToken(address _token, address _user) constant public returns (uint);
    function getUserLengthOnEther() constant public returns (uint);
    function getUserLengthOnToken(address _token) constant public returns (uint);
    function getUserNumbersOnToken(address _token, uint _index) constant public returns (uint, uint, uint, uint, address);
    function getUserTotalPaid(address _user, address _token) constant public returns (uint);
    function getUserTotalCredit(address _user, address _token) constant public returns (uint);
}


// ----------------------------------------------------------------------------
// NRB_Tokens contract
// ----------------------------------------------------------------------------
contract NRB_Tokens {
    function init(address _main, address _flc) public;
    function getTokenListLength() constant public returns (uint);
    function getTokenAddressByIndex(uint _index) constant public returns (address);
    function isTokenRegistered(address _token) constant public returns (bool);
    function registerToken(address _token, string _name, string _symbol, uint _decimals) public;
    function registerTokenPayment(address _token, uint _value) public;
    function sendFLC(address user, address token, uint totalpaid) public returns (uint);
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
// CNTCommon contract
// ----------------------------------------------------------------------------
contract NRB_Common is WhiteListAccess {
   
    function NRB_Common() public { ETH_address = 0x1; }

    // Deployment
    address public ETH_address;    // representation of Ether as Token (0x1)
    address public TOKENS_address;  // NRB_Tokens
    address public USERS_address;   // NRB_Users
    address public FLC_address;     // Four Leaf Clover Token

    // Debug
    event Debug(string, bool);
    event Debug(string, uint);
    event Debug(string, uint, uint);
    event Debug(string, uint, uint, uint);
    event Debug(string, uint, uint, uint, uint);
    event Debug(string, address);
    event Debug(string, address, address);
}

// ----------------------------------------------------------------------------
// NRB_Main (main) contract
// ----------------------------------------------------------------------------

contract NRB_Main is NRB_Common {
    mapping(address => uint) raisedAmount;
    bool _init;

    function NRB_Main() public {
        _init = false;
    }

    function init(address _tokens, address _users, address _flc) public {
        require(!_init);
        TOKENS_address = _tokens;
        USERS_address = _users;
        FLC_address = _flc;
        NRB_Tokens(TOKENS_address).init(address(this), _flc);
        NRB_Users(USERS_address).init(address(this), _flc);
        _init = true;
    }

    function isTokenRegistered(address _token) constant public returns (bool) {
        return NRB_Tokens(TOKENS_address).isTokenRegistered(_token);
    }

    function isInit() constant public returns (bool) {
        return _init;
    }

    // User Registration ------------------------------------------
    function registerMeOnEther(string _json) payable public {
        return registerMeOnTokenCore(ETH_address, msg.sender, msg.value, _json);
    }

    function registerMeOnToken(address _token, uint _value, string _json) public {
        return registerMeOnTokenCore(_token, msg.sender, _value, _json);
    }

    function registerMeOnTokenCore(address _token, address _user, uint _value, string _json) internal {
        require(this.isTokenRegistered(_token));


        // CrowdSale is over so we redirect gains to the owner
        if (_token != ETH_address) {
            ERC20Interface(_token).transferFrom(_user, address(this), _value);
        }

        raisedAmount[_token] = raisedAmount[_token] + _value;

        uint _credit = NRB_Users(USERS_address).getUserTotalCredit(_user, _token);
        uint _totalpaid = NRB_Users(USERS_address).getUserTotalPaid(_user, _token) + _value - _credit;
        uint flc = NRB_Tokens(TOKENS_address).sendFLC(_user, _token, _totalpaid);

        NRB_Users(USERS_address).registerUserOnToken(_token, _user, _value, flc,_json);
        NRB_Tokens(TOKENS_address).registerTokenPayment(_token,_value);
    }

    function getRaisedAmountOnEther() constant public returns (uint) {
        return this.getRaisedAmountOnToken(ETH_address);
    }

    function getRaisedAmountOnToken(address _token) constant public returns (uint) {
        return raisedAmount[_token];
    }

    function getUserIndexOnEther(address _user) constant public returns (uint) {
        return NRB_Users(USERS_address).getUserIndexOnEther(_user);
    }

    function getUserIndexOnToken(address _token, address _user) constant public returns (uint) {
        return NRB_Users(USERS_address).getUserIndexOnToken(_token, _user);
    }

    function getUserLengthOnEther() constant public returns (uint) {
        return NRB_Users(USERS_address).getUserLengthOnEther();
    }

    function getUserLengthOnToken(address _token) constant public returns (uint) {
        return NRB_Users(USERS_address).getUserLengthOnToken(_token);
    }

    function getUserNumbersOnEther(uint _index) constant public returns (uint, uint, uint, uint, uint) {
        return getUserNumbersOnToken(ETH_address, _index);
    }

    function getUserNumbersOnToken(address _token, uint _index) constant public returns (uint, uint, uint, uint, uint) {
        address _user;
        uint _time; uint _userid; uint _userindex; uint _paid;
        (_time, _userid, _userindex, _paid, _user) = NRB_Users(USERS_address).getUserNumbersOnToken(_token, _index);
        uint _balance = _paid * 10;
        uint _userbalance = getUserBalanceOnToken(_token, _user);
        if (_userbalance < _balance) {
            _balance = _userbalance;
        }
        return (_time, _balance, _paid, _userid, _userindex);
    }


    function getUserBalanceOnEther(address _user) constant public returns (uint) {
        return this.getUserBalanceOnToken(ETH_address, _user);
    }

    function getUserBalanceOnToken(address _token, address _user) constant public returns (uint) {
        if (_token == ETH_address) {
            return _user.balance;
        } else {
            return ERC20Interface(_token).balanceOf(_user);
        }
    }
    
    // control funcitons only the owner may call them -------------------------------------

    function _realBalanceOnEther() constant public returns (uint) {
        return this.getUserBalanceOnToken(ETH_address, address(this));
    }

    function _realBalanceOnToken(address _token) constant public returns (uint) {
        return this.getUserBalanceOnToken(_token, address(this));
    }

    function _withdrawal() public {
        address _addrs;
        uint _length = NRB_Tokens(TOKENS_address).getTokenListLength();
        uint _balance;
        for (uint i = 0; i<_length; i++) {
            _addrs = NRB_Tokens(TOKENS_address).getTokenAddressByIndex(i);
            if (_addrs == ETH_address) {continue;}
            _balance = ERC20Interface(_addrs).balanceOf(address(this));
            if (_balance > 0) {
                ERC20Interface(_addrs).transfer(owner, _balance);
            }
        }
        owner.transfer(this.balance);
    }

}
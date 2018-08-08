pragma solidity ^0.4.14;

contract ERC20Interface {
    function balanceOf(address tokenOwner) public constant returns (uint balance);
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
// NRB_Users
// ----------------------------------------------------------------------------

contract NRB_Users is NRB_Common {

    // how much raised for each token
    mapping(address => uint) raisedAmount;

    // accounts[TOKEN][USER] = DAta()
    mapping(address => mapping(address => Data)) public accounts;

    // a list of users for each token
    mapping(address =>  mapping(uint => address)) public tokenUsers;

    // length of eath prev list
    mapping(address => uint) public userindex;

    // a global list of users (uniques ids across)
    mapping(uint => address) user;

    // length of prev list
    uint public userlength;

    // map of known tokens
    mapping(address => bool) public tokenmap;

    // list of known tokens
    mapping(uint => address) public tokenlist;

    // length of prev list
    uint public tokenlength;

    // list of tokens registered
    struct Data {
        bool registered;
        uint time;
        uint userid;
        uint userindex;
        uint paid;
        uint credit;
        uint flc;
        address token;
        string json;
    }
// --------------------------------------------------------------------------------
    function NRB_Users() public {
        userlength = 1;
    }

    // User Registration ------------------------------------------
    function registerUserOnToken(address _token, address _user, uint _value, uint _flc, string _json) public onlyWhitelisted() returns (uint) {
        Debug("USER.registerUserOnToken() _token,_user,msg.sender",_token,_user, msg.sender);
        Debug("USER.registerUserOnToken() _valu, msg.value",_value,msg.value);

        uint _time = block.timestamp;
        uint _userid = 0;
        uint _userindex = 0;
        uint _credit = 0;
        
        if (msg.sender != NRB_address) {
            // is from somewhere else
            _credit = _value;
        }

        if (accounts[_user][_token].registered) {
            _userid = accounts[_user][_token].userid;
            _userindex = accounts[_user][_token].userindex;
        } else {
            if (userindex[_token] == 0) {
                userindex[_token] = 1;
            }
            _userindex                         = userindex[_token];
            _userid                            = userlength;
            user[_userid]                      = _user;
            tokenUsers[_token][_userindex]     = _user;
            accounts[_user][_token].registered = true;
            accounts[_user][_token].userid     = _userid;
            accounts[_user][_token].userindex  = _userindex;
            userindex[_token]++;
            userlength++;
        }

        accounts[_user][_token].time = _time;
        if (keccak256(_json) != keccak256("NO-JSON")) {
            accounts[_user][_token].json = _json;
        }

        accounts[_user][_token].flc = accounts[_user][_token].flc + _flc; 

        accounts[_user][_token].paid = accounts[_user][_token].paid + _value;
        accounts[_user][_token].credit = accounts[_user][_token].credit + _credit;
        raisedAmount[_token] = raisedAmount[_token] + _value;

        if (!tokenmap[_token]) {
            tokenlist[tokenlength++] = _token;
            tokenmap[_token] = true;
        }

        return _userindex;
    }

    // Getting Data ------------------------------
    function getUserIndexOnEther(address _user) constant public returns (uint) {
        require(accounts[_user][ETH_address].registered);
        return accounts[_user][ETH_address].userindex;
    }

    function getUserIndexOnToken(address _token, address _user) constant public returns (uint) {
        require(accounts[_user][_token].registered);
        return accounts[_user][_token].userindex;
    }
    
    function getUserLengthOnEther() constant public returns (uint) {
        return this.getUserLengthOnToken(ETH_address);
    }

    function getUserLengthOnToken(address _token) constant public returns (uint) {
        if (userindex[_token] < 2) {return 0;}
        return userindex[_token]-1;
    }

    function getUserDataOnEther(uint _index) constant public returns (string) {
        address _user = tokenUsers[ETH_address][_index];
        return accounts[_user][ETH_address].json;
    }

    function getUserDataOnToken(address _token, uint _index) constant public returns (string) {
        require(userindex[_token] > _index-1);
        address _user = tokenUsers[_token][_index];
        return accounts[_user][_token].json;
    }
    
    function getUserNumbersOnEther(uint _index) constant public returns (uint, uint, uint, uint, uint, uint, uint, address) {
        return getUserNumbersOnToken(ETH_address, _index);
    }

    function getUserNumbersOnToken(address _token, uint _index) constant public returns (uint, uint, uint, uint, uint, uint, uint, address) {
        require(userindex[_token] > _index-1);
        address _user = tokenUsers[_token][_index];
        Data memory data = accounts[_user][_token];
        uint _balance = getUserBalanceOnToken(_token, _user);
        // we truncate the current balance of user because he or che is only allowed to show till 10 times what benn paid.
        if (_balance > 9 * data.paid) {
            _balance = 9 * data.paid;
        }
        _balance = _balance + data.paid;

        return (data.time, _balance, data.paid, data.credit, data.flc, data.userid, data.userindex, _user);
    }

    function getUserBalanceOnEther(address _user) constant public returns (uint) {
        return this.getUserBalanceOnToken(ETH_address, _user);
    }

    function getUserTotalPaid(address _user, address _token) constant public returns (uint) {
        return accounts[_user][_token].paid;
    }

    function getUserTotalCredit(address _user, address _token) constant public returns (uint) {
        return accounts[_user][_token].credit;
    }

    function getUserFLCEarned(address _user, address _token) constant public returns (uint) {
        return accounts[_user][_token].flc;
    }

    function getUserBalanceOnToken(address _token, address _user) constant public returns (uint) {
        if (_token == ETH_address) {
            return _user.balance;
        } else {
            return ERC20Interface(_token).balanceOf(_user);
        }
    }
}
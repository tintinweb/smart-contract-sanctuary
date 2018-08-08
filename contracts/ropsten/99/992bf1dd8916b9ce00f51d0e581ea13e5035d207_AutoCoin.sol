pragma solidity ^0.4.15;

contract ERC20 {
    function totalSupply() external constant returns (uint256 _totalSupply);
    function balanceOf(address _owner) external constant returns (uint256 balance);
    function userTransfer(address _to, uint256 _value) external returns (bool success);
    function userTransferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function userApprove(address _spender, uint256 _old, uint256 _new) external returns (bool success);
    function allowance(address _owner, address _spender) external constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function ERC20() internal {
    }
}

library SafeMath {
    uint256 constant private    MAX_UINT256     = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    function safeAdd (uint256 x, uint256 y) internal pure returns (uint256 z) {
        assert (x <= MAX_UINT256 - y);
        return x + y;
    }

    function safeSub (uint256 x, uint256 y) internal pure returns (uint256 z) {
        assert (x >= y);
        return x - y;
    }

    function safeMul (uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x * y;
        assert(x == 0 || z / x == y);
    }

    function safeDiv (uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x / y;
        return z;
    }
}

contract AutoCoin is ERC20 {

    using SafeMath for uint256;

    address public              owner;
    address private             subowner;

    uint256 private             summarySupply;
    uint256 public              weiPerMinToken;

    string  public              name = "Auto Token";
    string  public              symbol = "ATK";
    uint8   public              decimals = 2;

    bool    public              contractEnable = true;
    bool    public              transferEnable = false;


    mapping(address => uint8)                        private   group;
    mapping(address => uint256)                      private   accounts;
    mapping(address => mapping (address => uint256)) private   allowed;

    event EvGroupChanged(address _address, uint8 _oldgroup, uint8 _newgroup);
    event EvTokenAdd(uint256 _value, uint256 _lastSupply);
    event EvTokenRm(uint256 _delta, uint256 _value, uint256 _lastSupply);
    event EvLoginfo(string _functionName, string _text);
    event EvMigration(address _address, uint256 _balance, uint256 _secret);

    struct groupPolicy {
        uint8 _default;
        uint8 _backend;
        uint8 _migration;
        uint8 _admin;
        uint8 _subowner;
        uint8 _owner;
    }

    groupPolicy private currentState = groupPolicy(0, 3, 9, 4, 2, 9);

    function AutoCoin(string _name, string _symbol, uint8 _decimals, uint256 _weiPerMinToken, uint256 _startTokens) public {
        owner = msg.sender;
        group[msg.sender] = 9;

        if (_weiPerMinToken != 0)
            weiPerMinToken = _weiPerMinToken;

        accounts[owner]  = _startTokens;
        summarySupply    = _startTokens;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    modifier minGroup(int _require) {
        require(group[msg.sender] >= _require);
        _;
    }

    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }

    function serviceGroupChange(address _address, uint8 _group) minGroup(currentState._admin) external returns(uint8) {
        uint8 old = group[_address];
        if(old <= currentState._admin) {
            group[_address] = _group;
            EvGroupChanged(_address, old, _group);
        }
        return group[_address];
    }

    function serviceGroupGet(address _check) minGroup(currentState._backend) external constant returns(uint8 _group) {
        return group[_check];
    }


    function settingsSetWeiPerMinToken(uint256 _weiPerMinToken) minGroup(currentState._admin) external {
        if (_weiPerMinToken > 0) {
            weiPerMinToken = _weiPerMinToken;

            EvLoginfo("[weiPerMinToken]", "changed");
        }
    }

    function serviceIncreaseBalance(address _who, uint256 _value) minGroup(currentState._backend) external returns(bool) {
        accounts[_who] = accounts[_who].safeAdd(_value);
        summarySupply = summarySupply.safeAdd(_value);

        EvTokenAdd(_value, summarySupply);
        return true;
    }

    function serviceDecreaseBalance(address _who, uint256 _value) minGroup(currentState._backend) external returns(bool) {
        accounts[_who] = accounts[_who].safeSub(_value);
        summarySupply = summarySupply.safeSub(_value);

        EvTokenRm(accounts[_who], _value, summarySupply);
        return true;
    }

    function serviceTokensBurn(address _address) external minGroup(currentState._backend) returns(uint256 balance) {
        accounts[_address] = 0;
        return accounts[_address];
    }

    function serviceChangeOwner(address _newowner) minGroup(currentState._subowner) external returns(address) {
        address temp;
        uint256 value;

        if (msg.sender == owner) {
            subowner = _newowner;
            group[msg.sender] = currentState._subowner;
            group[_newowner] = currentState._subowner;

            EvGroupChanged(_newowner, currentState._owner, currentState._subowner);
        }

        if (msg.sender == subowner) {
            temp = owner;
            value = accounts[owner];

            accounts[owner] = accounts[owner].safeSub(value);
            accounts[subowner] = accounts[subowner].safeAdd(value);

            owner = subowner;

            delete group[temp];
            group[subowner] = currentState._owner;

            subowner = 0x00;

            EvGroupChanged(_newowner, currentState._subowner, currentState._owner);
        }

        return subowner;
    }

    function userTransfer(address _to, uint256 _value) onlyPayloadSize(64) minGroup(currentState._default) external returns (bool success) {
        if (accounts[msg.sender] >= _value && (transferEnable || group[msg.sender] >= currentState._backend)) {
            accounts[msg.sender] = accounts[msg.sender].safeSub(_value);
            accounts[_to] = accounts[_to].safeAdd(_value);
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function userTransferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(64) minGroup(currentState._default) external returns (bool success) {
        if ((accounts[_from] >= _value) && (allowed[_from][msg.sender] >= _value) && (transferEnable || group[msg.sender] >= currentState._backend)) {
            accounts[_from] = accounts[_from].safeSub(_value);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].safeSub(_value);
            accounts[_to] = accounts[_to].safeAdd(_value);
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function userApprove(address _spender, uint256 _old, uint256 _new) onlyPayloadSize(64) minGroup(currentState._default) external returns (bool success) {
        if (_old == allowed[msg.sender][_spender]) {
            allowed[msg.sender][_spender] = _new;
            Approval(msg.sender, _spender, _new);
            return true;
        } else {
            return false;
        }
    }

    function allowance(address _owner, address _spender) external constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function balanceOf(address _owner) external constant returns (uint256 balance) {
        if (_owner == 0x00)
            return accounts[msg.sender];
        return accounts[_owner];
    }

    function totalSupply() external constant returns (uint256 _totalSupply) {
        _totalSupply = summarySupply;
    }

    function destroy() minGroup(currentState._owner) external {
        selfdestruct(owner);
    }

    function settingsSwitchState() external minGroup(currentState._owner) returns (bool state) {

        if(contractEnable) {
            currentState._default = 9;
            currentState._migration = 0;
            contractEnable = false;
        } else {
            currentState._default = 0;
            currentState._migration = 9;
            contractEnable = true;
        }

        return contractEnable;
    }

    function settingsSwitchTransferAccess() external minGroup(currentState._backend) returns (bool access) {
        transferEnable = !transferEnable;
        return transferEnable;
    }

    function userMigration(uint256 _secrect) external minGroup(currentState._migration) returns (bool successful) {

        uint256 balance = accounts[msg.sender];
        if (balance > 0) {
            accounts[msg.sender] = accounts[msg.sender].safeSub(balance);
            accounts[owner] = accounts[owner].safeAdd(balance);
            EvMigration(msg.sender, balance, _secrect);
            return true;
        }
        else
            return false;
    }
}
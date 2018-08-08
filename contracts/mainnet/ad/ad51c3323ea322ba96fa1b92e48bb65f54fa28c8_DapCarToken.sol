pragma solidity ^0.4.18;

/*
*   DapCar Token (DAPX)
*   Created by Starlag Labs (www.starlag.com)
*   Copyright &#169; DapCar.io 2018. All rights reserved.
*   https://www.dapcar.io
*/

library Math {
    function mul(uint256 a, uint256 b) 
    internal 
    pure 
    returns (uint256) 
    {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) 
    internal 
    pure 
    returns (uint256) 
    {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) 
    internal 
    pure 
    returns (uint256) 
    {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) 
    internal 
    pure 
    returns (uint256) 
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Utils {
    function Utils() public {}

    modifier greaterThanZero(uint256 _value) 
    {
        require(_value > 0);
        _;
    }

    modifier validUint(uint256 _value) 
    {
        require(_value >= 0);
        _;
    }

    modifier validAddress(address _address) 
    {
        require(_address != address(0));
        _;
    }

    modifier notThis(address _address) 
    {
        require(_address != address(this));
        _;
    }

    modifier validAddressAndNotThis(address _address) 
    {
        require(_address != address(0) && _address != address(this));
        _;
    }

    modifier notEmpty(string _data)
    {
        require(bytes(_data).length > 0);
        _;
    }

    modifier stringLength(string _data, uint256 _length)
    {
        require(bytes(_data).length == _length);
        _;
    }
    
    modifier validBytes32(bytes32 _bytes)
    {
        require(_bytes != 0);
        _;
    }

    modifier validUint64(uint64 _value) 
    {
        require(_value >= 0 && _value < 4294967296);
        _;
    }

    modifier validUint8(uint8 _value) 
    {
        require(_value >= 0 && _value < 256);
        _;
    }

    modifier validBalanceThis(uint256 _value)
    {
        require(_value <= address(this).balance);
        _;
    }
}

contract Authorizable is Utils {
    using Math for uint256;

    address public owner;
    address public newOwner;
    mapping (address => Level) authorizeds;
    uint256 public authorizedCount;

    /*  
    *   ZERO 0 - bug for null object
    *   OWNER 1
    *   ADMIN 2
    *   DAPP 3
    */  
    enum Level {ZERO,OWNER,ADMIN,DAPP}

    event OwnerTransferred(address indexed _prevOwner, address indexed _newOwner);
    event Authorized(address indexed _address, Level _level);
    event UnAuthorized(address indexed _address);

    function Authorizable() 
    public 
    {
        owner = msg.sender;
        authorizeds[msg.sender] = Level.OWNER;
        authorizedCount = authorizedCount.add(1);
    }

    modifier onlyOwner {
        require(authorizeds[msg.sender] == Level.OWNER);
        _;
    }

    modifier onlyOwnerOrThis {
        require(authorizeds[msg.sender] == Level.OWNER || msg.sender == address(this));
        _;
    }

    modifier notOwner(address _address) {
        require(authorizeds[_address] != Level.OWNER);
        _;
    }

    modifier authLevel(Level _level) {
        require((authorizeds[msg.sender] > Level.ZERO) && (authorizeds[msg.sender] <= _level));
        _;
    }

    modifier authLevelOnly(Level _level) {
        require(authorizeds[msg.sender] == _level);
        _;
    }
    
    modifier notSender(address _address) {
        require(msg.sender != _address);
        _;
    }

    modifier isSender(address _address) {
        require(msg.sender == _address);
        _;
    }

    modifier checkLevel(Level _level) {
        require((_level > Level.ZERO) && (Level.DAPP >= _level));
        _;
    }

    function transferOwnership(address _newOwner) 
    public 
    {
        _transferOwnership(_newOwner);
    }

    function _transferOwnership(address _newOwner) 
    onlyOwner 
    validAddress(_newOwner)
    notThis(_newOwner)
    internal 
    {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    function acceptOwnership() 
    validAddress(newOwner)
    isSender(newOwner)
    public 
    {
        OwnerTransferred(owner, newOwner);
        if (authorizeds[owner] == Level.OWNER) {
            delete authorizeds[owner];
        }
        if (authorizeds[newOwner] > Level.ZERO) {
            authorizedCount = authorizedCount.sub(1);
        }
        owner = newOwner;
        newOwner = address(0);
        authorizeds[owner] = Level.OWNER;
    }

    function cancelOwnership() 
    onlyOwner
    public 
    {
        newOwner = address(0);
    }

    function authorized(address _address, Level _level) 
    public  
    {
        _authorized(_address, _level);
    }

    function _authorized(address _address, Level _level) 
    onlyOwner
    validAddress(_address)
    notOwner(_address)
    notThis(_address)
    checkLevel(_level)
    internal  
    {
        if (authorizeds[_address] == Level.ZERO) {
            authorizedCount = authorizedCount.add(1);
        }
        authorizeds[_address] = _level;
        Authorized(_address, _level);
    }

    function unAuthorized(address _address) 
    onlyOwner
    validAddress(_address)
    notOwner(_address)
    notThis(_address)
    public  
    {
        if (authorizeds[_address] > Level.ZERO) {
            authorizedCount = authorizedCount.sub(1);
        }
        delete authorizeds[_address];
        UnAuthorized(_address);
    }

    function isAuthorized(address _address) 
    validAddress(_address)
    notThis(_address)
    public 
    constant 
    returns (Level) 
    {
        return authorizeds[_address];
    }
}

contract ITokenRecipient { function receiveApproval(address _spender, uint256 _value, address _token, bytes _extraData) public; }

contract IERC20 {
    function totalSupply() public constant returns (uint256);
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20Token is Authorizable, IERC20 {
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    uint256 totalSupply_;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier validBalance(uint256 _value)
    {
        require(_value <= balances[msg.sender]);
        _;
    }

    modifier validBalanceFrom(address _from, uint256 _value)
    {
        require(_value <= balances[_from]);
        _;
    }

    modifier validBalanceOverflows(address _to, uint256 _value)
    {
        require(balances[_to] <= balances[_to].add(_value));
        _;
    }

    function ERC20Token() public {}

    function totalSupply()
    public 
    constant 
    returns (uint256) 
    {
        return totalSupply_;
    }

    function transfer(address _to, uint256 _value)
    public
    returns (bool success) 
    {
        return _transfer(_to, _value);
    }

    function _transfer(address _to, uint256 _value)
    validAddress(_to)
    greaterThanZero(_value)
    validBalance(_value)
    validBalanceOverflows(_to, _value)
    internal
    returns (bool success) 
    {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value)
    public 
    returns (bool success) 
    {
        return _transferFrom(_from, _to, _value);
    }

    function _transferFrom(address _from, address _to, uint256 _value)
    validAddress(_to)
    validAddress(_from)
    greaterThanZero(_value)
    validBalanceFrom(_from, _value)
    validBalanceOverflows(_to, _value)
    internal 
    returns (bool success) 
    {
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner)
    validAddress(_owner)
    public 
    constant 
    returns (uint256 balance) 
    {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) 
    public 
    returns (bool success) 
    {
        return _approve(_spender, _value);
    }

    function _approve(address _spender, uint256 _value) 
    validAddress(_spender)
    internal 
    returns (bool success) 
    {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)
    validAddress(_owner)
    validAddress(_spender)
    public 
    constant 
    returns (uint256 remaining) 
    {
        return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint256 _addedValue)
    validAddress(_spender)
    greaterThanZero(_addedValue)
    public 
    returns (bool success) 
    {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint256 _subtractedValue) 
    validAddress(_spender)
    greaterThanZero(_subtractedValue)
    public
    returns (bool success) 
    {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            delete allowed[msg.sender][_spender];
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

contract FrozenToken is ERC20Token, ITokenRecipient {
    mapping (address => bool) frozeds;
    uint256 public frozedCount;
    bool public freezeEnabled = true;
    bool public autoFreeze = true;
    bool public mintFinished = false;

    event Freeze(address indexed wallet);
    event UnFreeze(address indexed wallet);
    event PropsChanged(address indexed sender, string props, bool oldValue, bool newValue);
    event Mint(address indexed sender, address indexed wallet, uint256 amount);
    event ReceiveTokens(address indexed spender, address indexed token, uint256 value, bytes extraData);
    event ApproveAndCall(address indexed spender, uint256 value, bytes extraData); 
    event Burn(address indexed sender, uint256 amount);
    event MintFinished(address indexed spender);

    modifier notFreeze
    {
        require(frozeds[msg.sender] == false || freezeEnabled == false);
        _;
    }

    modifier notFreezeFrom(address _from) 
    {
        require((_from != address(0) && frozeds[_from] == false) || freezeEnabled == false);
        _;
    }

    modifier canMint
    {
        require(!mintFinished);
        _;
    }

    function FrozenToken() public {}

    function freeze(address _address) 
    authLevel(Level.DAPP)
    validAddress(_address)
    notThis(_address)
    notOwner(_address)
    public 
    {
        if (!frozeds[_address]) {
            frozeds[_address] = true;
            frozedCount = frozedCount.add(1);
            Freeze(_address);
        }
    }

    function unFreeze(address _address) 
    authLevel(Level.DAPP)
    validAddress(_address)
    public 
    {
        if (frozeds[_address]) {
            delete frozeds[_address];
            frozedCount = frozedCount.sub(1);
            UnFreeze(_address);
        }
    }

    function updFreezeEnabled(bool _freezeEnabled) 
    authLevel(Level.ADMIN)
    public 
    {
        PropsChanged(msg.sender, "freezeEnabled", freezeEnabled, _freezeEnabled);
        freezeEnabled = _freezeEnabled;
    }

    function updAutoFreeze(bool _autoFreeze) 
    authLevel(Level.ADMIN)
    public 
    {
        PropsChanged(msg.sender, "autoFreeze", autoFreeze, _autoFreeze);
        autoFreeze = _autoFreeze;
    }

    function isFreeze(address _address) 
    validAddress(_address)
    public 
    constant 
    returns(bool) 
    {
        return bool(frozeds[_address]);
    }

    function transfer(address _to, uint256 _value) 
    notFreeze
    public 
    returns (bool) 
    {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) 
    notFreezeFrom(_from)
    public 
    returns (bool) 
    {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) 
    notFreezeFrom(_spender)
    public 
    returns (bool) 
    {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint256 _addedValue)
    notFreezeFrom(_spender)
    public 
    returns (bool) 
    {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint256 _subtractedValue) 
    notFreezeFrom(_spender)
    public 
    returns (bool) 
    {
        return super.decreaseApproval(_spender, _subtractedValue);
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) 
    validAddress(_spender)
    greaterThanZero(_value)
    public 
    returns (bool success) 
    {
        ITokenRecipient spender = ITokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            ApproveAndCall(_spender, _value, _extraData); 
            return true;
        }
    }

    function receiveApproval(address _spender, uint256 _value, address _token, bytes _extraData)
    validAddress(_spender)
    validAddress(_token)
    greaterThanZero(_value)
    public 
    {
        IERC20 token = IERC20(_token);
        require(token.transferFrom(_spender, address(this), _value));
        ReceiveTokens(_spender, _token, _value, _extraData);
    }

    function mintFinish() 
    onlyOwner
    public 
    returns (bool success)
    {
        mintFinished = true;
        MintFinished(msg.sender);
        return true;
    }

    function mint(address _address, uint256 _value)
    canMint
    authLevel(Level.DAPP)
    validAddress(_address)
    greaterThanZero(_value)
    public
    returns (bool success) 
    {
        balances[_address] = balances[_address].add(_value);
        totalSupply_ = totalSupply_.add(_value);
        Transfer(0, _address, _value);

        if (freezeEnabled && autoFreeze && _address != address(this) && isAuthorized(_address) == Level.ZERO) {
            if (!isFreeze(_address)) {
                frozeds[_address] = true;
                frozedCount = frozedCount.add(1);
                Freeze(_address);
            }
        }

        Mint(0, _address, _value);
        return true;
    }

    function burn(uint256 _value)
    greaterThanZero(_value)
    validBalance(_value)
    public
    returns (bool) 
    {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        Transfer(msg.sender, address(0), _value);

        if (isFreeze(msg.sender)) {
            delete frozeds[msg.sender];
            frozedCount = frozedCount.sub(1);
            UnFreeze(msg.sender);
        }

        Burn(msg.sender, _value);
        return true;
    }
}

contract DapCarToken is FrozenToken {
    string public name = "DapCar Token";
    string public symbol = "DAPX";
    uint8 public decimals = 0;

    string public version = "0.1";
    string public publisher = "https://www.dapcar.io";
    string public description = "This is an official DapCar Token (DAPX)";

    bool public acceptAdminWithdraw = false;
    bool public acceptDonate = true;

    event InfoChanged(address indexed sender, string version, string publisher, string description);
    event Withdraw(address indexed sender, address indexed wallet, uint256 amount);
    event WithdrawTokens(address indexed sender, address indexed wallet, address indexed token, uint256 amount);
    event Donate(address indexed sender, uint256 value);
    event PropsChanged(address indexed sender, string props, bool oldValue, bool newValue);

    function DapCarToken() public {}

    function setupInfo(string _version, string _publisher, string _description)
    authLevel(Level.ADMIN)
    notEmpty(_version)
    notEmpty(_publisher)
    notEmpty(_description)
    public
    {
        version = _version;
        publisher = _publisher;
        description = _description;
        InfoChanged(msg.sender, _version, _publisher, _description);
    }

    function withdraw() 
    public 
    returns (bool success)
    {
        return withdrawAmount(address(this).balance);
    }

    function withdrawAmount(uint256 _amount) 
    authLevel(Level.ADMIN) 
    greaterThanZero(address(this).balance)
    greaterThanZero(_amount)
    validBalanceThis(_amount)
    public 
    returns (bool success)
    {
        address wallet = owner;
        if (acceptAdminWithdraw) {
            wallet = msg.sender;
        }

        Withdraw(msg.sender, wallet, address(this).balance);
        wallet.transfer(address(this).balance);
        return true;
    }

    function withdrawTokens(address _token, uint256 _amount)
    authLevel(Level.ADMIN)
    validAddress(_token)
    greaterThanZero(_amount)
    public 
    returns (bool success) 
    {
        address wallet = owner;
        if (acceptAdminWithdraw) {
            wallet = msg.sender;
        }

        bool result = IERC20(_token).transfer(wallet, _amount);
        if (result) {
            WithdrawTokens(msg.sender, wallet, _token, _amount);
        }
        return result;
    }

    function balanceToken(address _token)
    validAddress(_token)
    public 
    constant
    returns (uint256 amount) 
    {
        return IERC20(_token).balanceOf(address(this));
    }

    function updAcceptAdminWithdraw(bool _accept)
    onlyOwner
    public
    returns (bool success)
    {
        PropsChanged(msg.sender, "acceptAdminWithdraw", acceptAdminWithdraw, _accept);
        acceptAdminWithdraw = _accept;
        return true;
    }
    
    function () 
    external 
    payable 
    {
        if (acceptDonate) {
            donate();
        }
	}

    function donate() 
    greaterThanZero(msg.value)
    internal 
    {
        Donate(msg.sender, msg.value);
    }

    function updAcceptDonate(bool _accept)
    authLevel(Level.ADMIN)
    public
    returns (bool success)
    {
        PropsChanged(msg.sender, "acceptDonate", acceptDonate, _accept);
        acceptDonate = _accept;
        return true;
    }
}
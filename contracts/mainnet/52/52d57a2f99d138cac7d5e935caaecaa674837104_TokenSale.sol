pragma solidity ^0.4.21;

library SafeMath {
    function add(uint256 _a, uint256 _b) pure internal returns (uint256) {
        uint256 c = _a + _b;
        assert(c >= _a && c >= _b);
        
        return c;
    }

    function sub(uint256 _a, uint256 _b) pure internal returns (uint256) {
        assert(_b <= _a);

        return _a - _b;
    }

    function mul(uint256 _a, uint256 _b) pure internal returns (uint256) {
        uint256 c = _a * _b;
        assert(_a == 0 || c / _a == _b);

        return c;
    }

    function div(uint256 _a, uint256 _b) pure internal returns (uint256) {
        assert(_b != 0);

        return _a / _b;
    }
}

interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
}

contract Token {
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    function transfer(address _to, uint256 _value) public returns (bool _success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool _success);
    function approve(address _spender, uint256 _value) public returns (bool _success);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TokenSale {
    using SafeMath for uint256;

    address public token;
    address public owner;
    address public vault;
    mapping (address => uint256) public rate;

    event RateChange(address indexed token, uint256 rate);
    event VaultChange(address indexed vault);
    event Transfer(address indexed to, address indexed token, uint256 received, uint256 sent);

    modifier isOwner {
        assert(msg.sender == owner);
        _;
    }

    modifier isValidAddress {
        assert(msg.sender != 0x0);
        _;
    }

    modifier hasPayloadSize(uint256 size) {
        assert(msg.data.length >= size + 4);
        _;
    }    

    constructor(address _token, address _vault) public {
        owner = msg.sender;
        token = _token;
        _setVault(_vault);
    }

    function setVault(address _vault) isOwner public {
        _setVault(_vault);
    }

    function _setVault(address _vault) private {
        if (vault != _vault) {
            vault = _vault;
            
            emit VaultChange(_vault);
        }
    }

    function setRate(address _address, uint256 _rate) isOwner public {
        _setRate(_address, _rate);
    }

    function setRates(address[] _address, uint256[] _rate) isOwner public {
        for (uint256 i = 0; i < _address.length; i++) {
            _setRate(_address[i], _rate[i]);
        }
    }

    function _setRate(address _address, uint256 _rate) private {
        if (rate[_address] != _rate) {
            rate[_address] = _rate;

            emit RateChange(_address, _rate);
        }
    }

    function() isValidAddress payable public {
        deposit();
    }

    function deposit() isValidAddress payable public {
        require(msg.value > 0);
        require(rate[0x0] > 0);
        uint256 amount = msg.value.mul(rate[0x0]).div(1 ether);
        require(Token(token).transferFrom(vault, msg.sender, amount));
        require(address(vault).send(msg.value));

        emit Transfer(msg.sender, 0x0, msg.value, amount);
    }

    function depositToken(address _token, uint256 _amount) isValidAddress public {
        require(rate[_token] > 0);
        uint256 amount = _amount.mul(rate[_token]).div(1 ether);
        require(Token(token).balanceOf(vault) >= amount);
        require(Token(_token).transferFrom(msg.sender, vault, _amount));
        require(Token(token).transferFrom(vault, msg.sender, amount));

        emit Transfer(msg.sender, _token, _amount, amount);
    }
}
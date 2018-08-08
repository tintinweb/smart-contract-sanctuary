pragma solidity ^0.4.24;

contract DACToken {

    string public name = "Decentralized Accessible Content";
    string public symbol = "DAC";
    uint256 public decimals = 6;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    uint256 public totalSupply = 30000000000000000;
    bool public stopped = false;
    address owner = 0x1e113613C889C76b792AdfdcbBd155904F3310a5;

    modifier isOwner {
        assert(owner == msg.sender);
        _;
    }

    modifier isRunning {
        assert(!stopped);
        _;
    }

    modifier isValidAddress {
        assert(0x0 != msg.sender);
        _;
    }

    constructor() public {
        balanceOf[owner] = totalSupply;
        emit Transfer(0x0, owner, totalSupply);
    }

    function transfer(address _to, uint256 _value) isRunning isValidAddress public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) isRunning isValidAddress public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        require(allowance[_from][msg.sender] >= _value);
        balanceOf[_to] += _value;
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) isRunning isValidAddress public returns (bool success) {
        require(_value == 0 || allowance[msg.sender][_spender] == 0);
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function stop() isOwner public {
        stopped = true;
    }

    function start() isOwner public {
        stopped = false;
    }

    function setName(string _name) isOwner public {
        name = _name;
    }

    function airdrop(address[] _DACusers,uint256[] _values) isRunning public {
        require(_DACusers.length > 0);
        require(_DACusers.length == _values.length);
        uint256 amount = 0;
        uint i = 0;
        for (i = 0; i < _DACusers.length; i++) {
            require(amount + _values[i] >= amount);
            amount += _values[i];  
        }
        require(balanceOf[msg.sender] >= amount);
        balanceOf[msg.sender] -= amount;
        for (i = 0; i < _DACusers.length; i++) {
            require(balanceOf[_DACusers[i]] + _values[i] >= balanceOf[_DACusers[i]]);
            balanceOf[_DACusers[i]] += _values[i];
            emit Transfer(msg.sender, _DACusers[i], _values[i]);
        }
    }
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
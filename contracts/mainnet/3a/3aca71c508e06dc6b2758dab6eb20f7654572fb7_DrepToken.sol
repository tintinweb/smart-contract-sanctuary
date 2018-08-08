pragma solidity ^0.4.18;

contract DrepToken {

    string public name = "DREP";
    string public symbol = "DREP";
    uint8 public decimals = 18;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    uint256 public totalSupply;
    uint256 constant initialSupply = 10000000000;
    
    bool public stopped = false;

    address internal owner = 0x0;

    modifier ownerOnly {
        require(owner == msg.sender);
        _;
    }

    modifier isRunning {
        require(!stopped);
        _;
    }

    modifier validAddress {
        require(msg.sender != 0x0);
        _;
    }

    function DrepToken() public {
        owner = msg.sender;
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[owner] = totalSupply;
    }

    function transfer(address _to, uint256 _value) isRunning validAddress public returns (bool success) {
        require(_to != 0x0);
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) isRunning validAddress public returns (bool success) {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        require(allowance[_from][msg.sender] >= _value);
        allowance[_from][msg.sender] -= _value;
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) isRunning validAddress public returns (bool success) {
        require(_value == 0 || allowance[msg.sender][_spender] == 0);
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function stop() ownerOnly public {
        stopped = true;
    }

    function start() ownerOnly public {
        stopped = false;
    }

    function burn(uint256 _value) isRunning validAddress public {
        require(balanceOf[msg.sender] >= _value);
        require(totalSupply >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
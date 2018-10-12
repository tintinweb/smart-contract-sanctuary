pragma solidity ^0.4.23;


contract Owned {
    address public owner;
    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract Base is Owned {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    uint256 public tokenUnit = 10 ** uint(decimals);
    uint256 public kUnit = 1000 * tokenUnit;
    uint256 public foundingTime;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    constructor() public {
        foundingTime = now;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
}

contract PCT is Base {
    uint256 public reserveSupply = 1000000 * kUnit;

    constructor() public {
        totalSupply = reserveSupply;
        balanceOf[msg.sender] = totalSupply;
        name = "PCT Token";
        symbol = "PCT";
    }
}
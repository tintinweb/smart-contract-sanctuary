pragma solidity ^0.4.24;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0); 
        uint256 c = a / b;
        assert(a == b * c + a % b); 
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}


contract ASIToken {
    using SafeMath for uint256;
    string public name = "ASICoin";
    string public symbol = "ASI";
    uint8 public decimals = 18;
    uint256 public totalSupply = 12 * 10 ** 8 * 10 ** 18;

    mapping (address => uint256) public balanceOf;
    mapping (address => uint256) public freezeOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Freeze(address indexed from, uint256 value);
	
    event Unfreeze(address indexed from, uint256 value);

    constructor() public{
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success){
        if (_to == 0x0) revert(); 
        if (_value <= 0) revert(); 
        if (balanceOf[msg.sender] < _value) revert();
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        if (_value <= 0) revert();
        allowance[msg.sender][_spender] = _value;
        return true;
    }
       

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (_to == 0x0) revert(); 
        if (_value <= 0) revert();
        if (balanceOf[_from] < _value) revert();  
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();
        if (_value > allowance[_from][msg.sender]) revert(); 
        balanceOf[_from] = balanceOf[_from].sub(_value); 
        balanceOf[_to] = balanceOf[_to].add(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function freeze(uint256 _value) public returns (bool success) {
        if (balanceOf[msg.sender] < _value) revert(); 
        if (_value <= 0) revert(); 
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value); 
        freezeOf[msg.sender] = freezeOf[msg.sender].add(_value); 
        emit Freeze(msg.sender, _value);
        return true;
    }

    function unfreeze(uint256 _value) public returns (bool success) {
        if (freezeOf[msg.sender] < _value) revert();
        if (_value <= 0) revert();
        freezeOf[msg.sender] = freezeOf[msg.sender].sub(_value); 
        balanceOf[msg.sender] = balanceOf[msg.sender].add(_value);
        emit Unfreeze(msg.sender, _value);
        return true;
    }
}
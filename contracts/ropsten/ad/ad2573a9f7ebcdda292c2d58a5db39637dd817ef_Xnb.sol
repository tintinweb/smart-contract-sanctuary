pragma solidity ^0.4.18;

library SafeMath {
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;
        return c;
    }

    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a && c >= _b);
        return c;
    }

    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a * _b;
        require(_a == 0 || c / _a == _b);
        return c;
    }
}

contract Xnb {
    using SafeMath for uint256;
    string public constant version = "1.0";
    string public constant name = "Xnb";
    uint8 public constant decimals = 18;
    string public constant symbol = "XNB";
    uint256 public totalSupply = 1314 * 10 ** uint(decimals);
    address public owner;

    modifier validAddress {
        assert(0x0 != msg.sender);
        _;
    }
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) private allowed;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor() public {
        owner = msg.sender;
        balanceOf[owner] = totalSupply;
    }

    function transfer(address _to, uint256 _value) validAddress public returns (bool success) {
        if (_to != 0x0 && _value > 0 && balanceOf[msg.sender] >= _value) {
            balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
            balanceOf[_to] = balanceOf[_to].add(_value);
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else {return false;}
    }

    function approve(address _spender, uint256 _value) validAddress public returns (bool success) {
        if (_spender != 0x0) {
            allowed[msg.sender][_spender] = _value;
            emit Approval(msg.sender, _spender, _value);
            return true;
        } else {return false;}
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return allowed[_owner][_spender];
    }

    function transferFrom(address _from, address _to, uint256 _value) validAddress public returns (bool success) {
        if (_to != 0x0 && _value > 0 && balanceOf[_from] >= _value && _value <= allowed[_from][msg.sender]) {
            balanceOf[_from] = balanceOf[_from].sub(_value);
            balanceOf[_to] = balanceOf[_to].add(_value);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
            emit Transfer(_from, _to, _value);
            return true;
        } else {return false;}
    }
}
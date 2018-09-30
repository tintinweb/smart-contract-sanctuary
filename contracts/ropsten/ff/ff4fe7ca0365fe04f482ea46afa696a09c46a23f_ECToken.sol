pragma solidity ^0.4.25;

contract owned {
    address public owner;

    constructor () public {
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

contract ERC20Interface {
    using SafeMath for uint256;
    string public name;
    string public symbol;
    uint8 public decimals = 8;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor (
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0));
        require(_value > 0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to].add(_value) > balanceOf[_to]);
        uint256 previousBalances = balanceOf[_from].add(balanceOf[_to]);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value > 0);
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_value > 0);
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}

contract ECToken is owned, ERC20Interface {
    mapping (address => bool) public frozenAccount;
    event FrozenFunds(address target, bool frozen);
    
    constructor () ERC20Interface(21000000, "大象链", "EC") public {}

    function _transfer(address _from, address _to, uint256 _value) internal {
        require (_to != address(0));
        require(_value > 0);
        require (balanceOf[_from] >= _value);
        require (balanceOf[_to].add(_value) >= balanceOf[_to]);
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);
        uint256 previousBalances = balanceOf[_from].add(balanceOf[_to]);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
    }

    function freezeAccount(address _target) onlyOwner public returns (bool success) {
        require (_target != address(0));
        frozenAccount[_target] = true;
        emit FrozenFunds(_target, true);
        return true;
    }
	
	function unfreezeAccount(address _target) onlyOwner public returns (bool success) {
	    require (_target != address(0));
        frozenAccount[_target] = false;
        emit FrozenFunds(_target, false);
        return true;
    }

    function increaseSupply(uint256 _value, address _owner) onlyOwner public returns (bool success) {
        require(_value > 0);
        totalSupply = totalSupply.add(_value);
        balanceOf[_owner] = balanceOf[_owner].add(_value);
        _transfer(msg.sender, _owner, _value);
        return true;
    }

    function decreaseSupply(uint256 _value, address _owner) onlyOwner public returns (bool success) {
        require(_value > 0);
        require(balanceOf[_owner] >= _value);
        balanceOf[_owner] = balanceOf[_owner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        _transfer(_owner, msg.sender, _value);
        return true;
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
}
pragma solidity ^0.4.18;


contract owned {
    address public owner;
    address public candidate;

    function owned() payable internal {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }

    function changeOwner(address _owner) onlyOwner public {
        candidate = _owner;
    }

    function confirmOwner() public {
        require(candidate != address(0));
        require(candidate == msg.sender);
        owner = candidate;
        delete candidate;
    }
}


library SafeMath {
    function sub(uint256 a, uint256 b) pure internal returns (uint256) {
        assert(a >= b);
        return a - b;
    }

    function add(uint256 a, uint256 b) pure internal returns (uint256) {
        uint256 c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
}


contract ERC20 {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256 value);
    function allowance(address owner, address spender) public constant returns (uint256 _allowance);
    function transfer(address to, uint256 value) public returns (bool success);
    function transferFrom(address from, address to, uint256 value) public returns (bool success);
    function approve(address spender, uint256 value) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Webpuddg is ERC20, owned {
    using SafeMath for uint256;
    string public name = "Webpuddg";
    string public symbol = "WBPDD";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowed;
    mapping (address => bool) public frozenAccount;

    event FrozenFunds(address target, bool frozen);
    event Burn(address indexed from, uint256 value);

    function balanceOf(address _who) public constant returns (uint256) {
        return balances[_who];
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function Webpuddg() public {
        totalSupply = 100000000 * 1 ether;
        balances[msg.sender] = totalSupply;
        Transfer(0, msg.sender, totalSupply);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));
        require(balances[msg.sender] >= _value);
        require(!frozenAccount[msg.sender] && !frozenAccount[_to]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        require(!frozenAccount[_from] && !frozenAccount[_to]);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0));
        require(balances[msg.sender] >= _value);
        require(!frozenAccount[_spender] && !frozenAccount[msg.sender]);
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    function burn(uint256 _value) onlyOwner public returns (bool success) {
        balances[this] = balances[this].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(this, _value);
        return true;
    }
}
pragma solidity ^0.4.24;

/**
 * HeapX.io Smart Contract
 * /

/** @title SafeMath */
library SafeMath {
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) { if (_a == 0) { return 0; } uint256 c = _a * _b; assert(c / _a == _b); return c; }
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) { uint256 c = _a / _b; return c; }
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) { assert(_b <= _a); uint256 c = _a - _b; return c;}
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) { uint256 c = _a + _b; assert(c >= _a); return c;}
}

/** @title ERC20 interface */
contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address _who) public view returns (uint256);
    function allowance(address _owner, address _spender) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
}

/** @title Owner */
contract OwnerHeapX {
    address public owner;
    constructor() public { owner = msg.sender; }
    modifier onlyOwner { require(msg.sender == owner); _;}
    function transferOwnership(address newOwner) onlyOwner public { owner = newOwner; }
}

/** @title HeapX */
contract HeapX is OwnerHeapX, ERC20 {

    string  public name;
    string  public symbol;
    uint8   public decimals;
    uint256 public totalSupply_;
    address public owner;

    constructor() public {
        name = "HeapX";
        symbol = "HEAP";
        decimals = 9;
        totalSupply_ = 500000000000000000;
        owner = msg.sender;
        balances[msg.sender] = totalSupply_;
        emit Transfer(address(0), msg.sender, totalSupply_);
    }

    using SafeMath for uint256;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    mapping (address => bool) public frozenAccount;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);
    event Burn(address indexed from, uint256 value);
    event FrozenFunds(address target, bool frozen);

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public view returns (uint256){
        return allowed[_owner][_spender];
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_value <= balances[msg.sender]);
        require(_to != address(0));
        require(!frozenAccount[_to]);
        require(!frozenAccount[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom( address _from, address _to, uint256 _value) public returns (bool){
        require(_value <= allowed[_from][msg.sender]);
        require(_to != address(0));
        require(!frozenAccount[_to]);
        require(!frozenAccount[_from]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool){
        allowed[msg.sender][_spender] = (
            allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool){
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
            return true;
    }

    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        totalSupply_ -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }
    
}
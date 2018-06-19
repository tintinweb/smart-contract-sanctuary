pragma solidity ^0.4.17;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
  
contract ManagedToken {
    using SafeMath for uint256;


    address public owner = msg.sender;
    address public crowdsaleContractAddress;

    string public name;
    string public symbol;

    bool public locked = true;
        
    uint8 public decimals = 18;

    modifier unlocked() {
        require(!locked);
        _;
    }


    // Ownership

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyCrowdsale() {
        require(msg.sender == crowdsaleContractAddress);
        _;
    }

    modifier ownerOrCrowdsale() {
        require(msg.sender == owner || msg.sender == crowdsaleContractAddress);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner returns (bool success) {
        require(newOwner != address(0));      
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        return true;
    }


    // ERC20 related functions

    uint256 public totalSupply = 0;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;


    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function transfer(address _to, uint256 _value) unlocked public returns (bool) {
        require(_to != address(0));
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }


    function transferFrom(address _from, address _to, uint256 _value) unlocked public returns (bool) {
        require(_to != address(0));
        var _allowance = allowed[_from][msg.sender];
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) unlocked public returns (bool) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function increaseApproval (address _spender, uint _addedValue) unlocked public
        returns (bool success) {
            allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
            Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
            return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) unlocked public
        returns (bool success) {
            uint oldValue = allowed[msg.sender][_spender];
            if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
            } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
            }
            Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
            return true;
    }



    function ManagedToken (string _name, string _symbol, uint8 _decimals) public {
        require(bytes(_name).length > 1);
        require(bytes(_symbol).length > 1);
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }


    function setNameAndTicker(string _name, string _symbol) onlyOwner public returns (bool success) {
        require(bytes(_name).length > 1);
        require(bytes(_symbol).length > 1);
        name = _name;
        symbol = _symbol;
        return true;
    }

    function setLock(bool _newLockState) ownerOrCrowdsale public returns (bool success) {
        require(_newLockState != locked);
        locked = _newLockState;
        return true;
    }

    function setCrowdsale(address _newCrowdsale) onlyOwner public returns (bool success) {
        crowdsaleContractAddress = _newCrowdsale;
        return true;
    }

    function mint(address _for, uint256 _amount) onlyCrowdsale public returns (bool success) {
        balances[_for] = balances[_for].add(_amount);
        totalSupply = totalSupply.add(_amount);
        Transfer(0, _for, _amount);
        return true;
    }

    function demint(address _for, uint256 _amount) onlyCrowdsale public returns (bool success) {
        balances[_for] = balances[_for].sub(_amount);
        totalSupply = totalSupply.sub(_amount);
        Transfer(_for, 0, _amount);
        return true;
    }

}
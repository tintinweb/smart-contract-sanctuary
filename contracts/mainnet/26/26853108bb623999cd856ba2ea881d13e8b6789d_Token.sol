pragma solidity ^0.4.15;
contract Base {
    modifier only(address allowed) {
        require(msg.sender == allowed);
        _;
    }
    // *************************************************
    // *          reentrancy handling                  *
    // *************************************************
    uint constant internal L00 = 2 ** 0;
    uint constant internal L01 = 2 ** 1;
    uint constant internal L02 = 2 ** 2;
    uint constant internal L03 = 2 ** 3;
    uint constant internal L04 = 2 ** 4;
    uint constant internal L05 = 2 ** 5;
    uint private bitlocks = 0;
    modifier noAnyReentrancy {
        var _locks = bitlocks;
        require(_locks == 0);
        bitlocks = uint(-1);
        _;
        bitlocks = _locks;
    }
}
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }
  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
contract Owned is Base {
    address public owner;
    address newOwner;
    function Owned() {
        owner = msg.sender;
    }
    function transferOwnership(address _newOwner) only(owner) {
        newOwner = _newOwner;
    }
    function acceptOwnership() only(newOwner) {
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    event OwnershipTransferred(address indexed _from, address indexed _to);
}
contract ERC20 is Owned {
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    function transfer(address _to, uint _value) isStartedOnly returns (bool success) {
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }
    function transferFrom(address _from, address _to, uint _value) isStartedOnly returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }
    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }
    function approve_fixed(address _spender, uint _currentValue, uint _value) isStartedOnly returns (bool success) {
        if(allowed[msg.sender][_spender] == _currentValue){
            allowed[msg.sender][_spender] = _value;
            Approval(msg.sender, _spender, _value);
            return true;
        } else {
            return false;
        }
    }
    function approve(address _spender, uint _value) isStartedOnly returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    function allowance(address _owner, address _spender) constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }
    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;
    uint public totalSupply;
    bool    public isStarted = false;
    modifier isStartedOnly() {
        require(isStarted);
        _;
    }
}
contract Token is ERC20 {
    using SafeMath for uint;
    string public name = "Patron coin";
    string public symbol = "PAT";
    uint8 public decimals = 18;
    address public crowdsaleMinter;
    modifier onlyCrowdsaleMinter(){
        require(msg.sender == crowdsaleMinter);
        _;
    }
    modifier isNotStartedOnly() {
        require(!isStarted);
        _;
    }
    function Token(address _crowdsaleMinter){
        crowdsaleMinter = _crowdsaleMinter;
    }
    function start()
    public
    onlyCrowdsaleMinter
    isNotStartedOnly
    {
        isStarted = true;
    }
    function emergencyStop()
    public
    only(owner)
    {
        isStarted = false;
    }
    //================= Crowdsale Only =================
    function mint(address _to, uint _amount) public
    onlyCrowdsaleMinter
    isNotStartedOnly
    returns(bool)
    {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        return true;
    }
}
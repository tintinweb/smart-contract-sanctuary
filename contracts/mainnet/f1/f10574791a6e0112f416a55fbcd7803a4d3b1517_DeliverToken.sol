pragma solidity ^0.4.18;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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

contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  function Ownable() public {
    owner = msg.sender;
  }
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract Pausable is Ownable {
  event Pause();
  event Unpause();
  bool public paused = false;
  modifier whenNotPaused() {
    require(!paused);
    _;
  }
  modifier whenPaused() {
    require(paused);
    _;
  }
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
  
}

contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function allowance(address owner, address spender) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}
contract DeliverToken is ERC20, Pausable {

    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 initialSupply;
    uint256 totalSupply_;

    mapping(address => uint256) balances;
    mapping(address => bool) internal locks;
    mapping(address => mapping(address => uint256)) internal allowed;

    function DeliverToken() public {
        name = "DELIVER";
        symbol = "DV";
        decimals = 18;
        initialSupply = 10000000000;
        totalSupply_ = initialSupply * 10 ** uint(decimals);
        balances[owner] = totalSupply_;
        Transfer(address(0), owner, totalSupply_);
    }
    function () public payable {
        revert();
    }
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        require(locks[msg.sender] == false);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(locks[_from] == false);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }
    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        require(_value > 0);
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
    function lock(address _owner) public onlyOwner returns (bool) {
        require(locks[_owner] == false);
        locks[_owner] = true;
        return true;
    }
    function unlock(address _owner) public onlyOwner returns (bool) {
        require(locks[_owner] == true);
        locks[_owner] = false;
        return true;
    }
    function showLockState(address _owner) public view returns (bool) {
        return locks[_owner];
    }
    function mint( uint256 _amount) onlyOwner public returns (bool) {
        totalSupply_ = totalSupply_.add(_amount);
        balances[owner] = balances[owner].add(_amount);
        Transfer(address(0), owner, _amount);
        return true;
    }
    function burn(uint256 _value) public onlyOwner returns (bool success) {
        require(_value <= balances[msg.sender]);
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        return true;
    }
}
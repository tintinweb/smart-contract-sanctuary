pragma solidity ^0.4.0;
contract ERC20TokenInterface {
    function totalSupply() constant returns (uint256 supply);
    function balanceOf(address _owner) constant public returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract CAF1 is ERC20TokenInterface {
  string public constant name = &#39;CAF1&#39;;
  uint256 public constant decimals = 2;
  string public constant symbol = &#39;CAF1&#39;;
  string public constant version = &#39;v0.0.1&#39;;

  uint256 private constant totalTokens = 277777 * (10 ** decimals);

  mapping (address => uint256) public balances;
  mapping (address => mapping (address => uint256)) public allowed;

  event MigrationInfoSet(string newMigrationInfo);

  string public migrationInfo = "";

  address public migrationInfoSetter;

  modifier onlyFromMigrationInfoSetter {
    if (msg.sender != migrationInfoSetter) {
      throw;
    }
    _;
  }

  function CAF1(address _migrationInfoSetter) {
    if (_migrationInfoSetter == 0) throw;
    migrationInfoSetter = _migrationInfoSetter;
    balances[msg.sender] = totalTokens;
  }

  function totalSupply() constant returns (uint256) {
    return totalTokens;
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    if (balances[msg.sender] >= _value) {
      balances[msg.sender] -= _value;
      balances[_to] += _value;
      Transfer(msg.sender, _to, _value);
      return true;
    }
    return false;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value) {
      balances[_from] -= _value;
      allowed[_from][msg.sender] -= _value;
      balances[_to] += _value;
      Transfer(_from, _to, _value);
      return true;
    }
    return false;
  }

  function balanceOf(address _owner) constant public returns (uint256) {
    return balances[_owner];
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }
  function compareAndApprove(address _spender, uint256 _currentValue, uint256 _newValue) public returns(bool) {
    if (allowed[msg.sender][_spender] != _currentValue) {
      return false;
    }
    return approve(_spender, _newValue);
  }
  function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
  function setMigrationInfo(string _migrationInfo) onlyFromMigrationInfoSetter public {
    migrationInfo = _migrationInfo;
    MigrationInfoSet(_migrationInfo);
  }
  function changeMigrationInfoSetter(address _newMigrationInfoSetter) onlyFromMigrationInfoSetter public {
    migrationInfoSetter = _newMigrationInfoSetter;
  }
}
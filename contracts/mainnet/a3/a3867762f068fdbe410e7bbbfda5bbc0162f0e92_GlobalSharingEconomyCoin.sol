pragma solidity ^0.4.18;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}
/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();
  event PrivateFundEnabled();
  event PrivateFundDisabled();

  bool public paused = false;
  bool public privateFundEnabled = true;

  /**
   * @dev Modifier to make a function callable only when the contract is private fund not end.
   */
  modifier whenPrivateFundDisabled() {
    require(!privateFundEnabled);
    _;
  }
  
  /**
   * @dev Modifier to make a function callable only when the contract is private fund end.
   */
  modifier whenPrivateFundEnabled() {
    require(privateFundEnabled);
    _;
  }

  /**
   * @dev called by the owner to end private fund, triggers stopped state
   */
  function disablePrivateFund() onlyOwner whenPrivateFundEnabled public {
    privateFundEnabled = false;
    emit PrivateFundDisabled();
  }

  /**
   * @dev called by the owner to unlock private fund, returns to normal state
   */
  function enablePrivateFund() onlyOwner whenPrivateFundDisabled public {
    privateFundEnabled = true;
    emit PrivateFundEnabled();
  }

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

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
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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
contract ERC20 {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract GlobalSharingEconomyCoin is Pausable, ERC20 {
  using SafeMath for uint256;
  event BatchTransfer(address indexed owner, bool value);

  string public name;
  string public symbol;
  uint8 public decimals;

  mapping(address => uint256) balances;
  mapping (address => mapping (address => uint256)) internal allowed;
  mapping (address => bool) allowedBatchTransfers;

  constructor() public {
    name = "GlobalSharingEconomyCoin";
    symbol = "GSE";
    decimals = 8;
    totalSupply = 10000000000 * 10 ** uint256(decimals);
    balances[msg.sender] = totalSupply;
    allowedBatchTransfers[msg.sender] = true;
  }

  function transfer(address _to, uint256 _value) whenNotPaused public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function setBatchTransfer(address _address, bool _value) public onlyOwner returns (bool) {
    allowedBatchTransfers[_address] = _value;
    emit BatchTransfer(_address, _value);
    return true;
  }

  function getBatchTransfer(address _address) public onlyOwner view returns (bool) {
    return allowedBatchTransfers[_address];
  }

  /**
   * 只允许项目方空投，如果项目方禁止批量转币，也同时禁用空投
   */
  function airdrop(address[] _funds, uint256 _amount) public whenNotPaused whenPrivateFundEnabled returns (bool) {
    require(allowedBatchTransfers[msg.sender]);
    uint256 fundslen = _funds.length;
    // 根据gaslimit的限制，超过300个地址的循环基本就无法成功执行了
    require(fundslen > 0 && fundslen < 300);
    
    uint256 totalAmount = 0;
    for (uint i = 0; i < fundslen; ++i){
      balances[_funds[i]] = balances[_funds[i]].add(_amount);
      totalAmount = totalAmount.add(_amount);
      emit Transfer(msg.sender, _funds[i], _amount);
    }

    // 如果执行失败，则会回滚整个交易
    require(balances[msg.sender] >= totalAmount);
    balances[msg.sender] = balances[msg.sender].sub(totalAmount);
    return true;
  }

  /**
   * 允许交易所和项目放方批量转币
   * _funds: 批量转币地址
   * _amounts: 每个地址的转币数量，长度必须跟_funds的长度相同
   */
  function batchTransfer(address[] _funds, uint256[] _amounts) public whenNotPaused whenPrivateFundEnabled returns (bool) {
    require(allowedBatchTransfers[msg.sender]);
    uint256 fundslen = _funds.length;
    uint256 amountslen = _amounts.length;
    require(fundslen == amountslen && fundslen > 0 && fundslen < 300);

    uint256 totalAmount = 0;
    for (uint i = 0; i < amountslen; ++i){
      totalAmount = totalAmount.add(_amounts[i]);
    }

    require(balances[msg.sender] >= totalAmount);
    for (uint j = 0; j < amountslen; ++j) {
      balances[_funds[j]] = balances[_funds[j]].add(_amounts[j]);
      emit Transfer(msg.sender, _funds[j], _amounts[j]);
    }
    balances[msg.sender] = balances[msg.sender].sub(totalAmount);
    return true;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }
}
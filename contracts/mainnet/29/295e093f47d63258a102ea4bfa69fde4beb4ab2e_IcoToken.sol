pragma solidity ^0.4.24;

contract SafeMath {

  function safeAdd(uint256 x, uint256 y) internal pure returns(uint256) {
    uint256 z = x + y;
    assert((z >= x) && (z >= y));
    return z;
  }

  function safeSubtract(uint256 x, uint256 y) internal pure returns(uint256) {
    assert(x >= y);
    uint256 z = x - y;
    return z;
  }

  function safeMult(uint256 x, uint256 y) internal pure returns(uint256) {
    uint256 z = x * y;
    assert((x == 0)||(z/x == y));
    return z;
  }
}
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) public  constant returns (uint);
  function allowance(address owner, address spender) public  constant returns (uint);
  function transfer(address to, uint value) public  returns (bool ok);
  function transferFrom(address from, address to, uint value) public  returns (bool ok);
  function approve(address spender, uint value) public  returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}
contract StandardToken is ERC20, SafeMath {
  /**
  * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint size) {
    require(msg.data.length >= size + 4) ;
    _;
  }

  mapping(address => uint) balances;
  mapping (address => mapping (address => uint)) allowed;

  function transfer(address _to, uint _value) public  onlyPayloadSize(2 * 32)  returns (bool success){
    balances[msg.sender] = safeSubtract(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) public  onlyPayloadSize(3 * 32) returns (bool success) {
    uint _allowance = allowed[_from][msg.sender];

    balances[_to] = safeAdd(balances[_to], _value);
    balances[_from] = safeSubtract(balances[_from], _value);
    allowed[_from][msg.sender] = safeSubtract(_allowance, _value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public  constant returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value) public  returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public  constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }
}
contract Ownable {
  address public owner;

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public  onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
}
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;
  modifier whenNotPaused() {
    require (!paused);
    _;
  }

  modifier whenPaused {
    require (paused) ;
    _;
  }
  function pause() public onlyOwner whenNotPaused returns (bool) {
    paused = true;
    emit Pause();
    return true;
  }

  function unpause() public onlyOwner whenPaused returns (bool) {
    paused = false;
    emit Unpause();
    return true;
  }
}
contract IcoToken is SafeMath, StandardToken, Pausable {
  string public name;
  string public symbol;
  uint256 public decimals;
  string public version;
  address public icoContract;

  constructor(
    string _name,
    string _symbol,
    uint256 _decimals,
    string _version
  ) public
  {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    version = _version;
  }

  function transfer(address _to, uint _value) public  whenNotPaused returns (bool success) {
    return super.transfer(_to,_value);
  }

  function approve(address _spender, uint _value) public  whenNotPaused returns (bool success) {
    return super.approve(_spender,_value);
  }

  function balanceOf(address _owner) public  constant returns (uint balance) {
    return super.balanceOf(_owner);
  }

  function setIcoContract(address _icoContract) public onlyOwner {
    if (_icoContract != address(0)) {
      icoContract = _icoContract;
    }
  }

  function sell(address _recipient, uint256 _value) public whenNotPaused returns (bool success) {
      assert(_value > 0);
      require(msg.sender == icoContract);

      balances[_recipient] += _value;
      totalSupply += _value;

      emit Transfer(0x0, owner, _value);
      emit Transfer(owner, _recipient, _value);
      return true;
  }

}
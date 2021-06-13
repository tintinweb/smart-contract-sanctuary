pragma solidity 0.8.4;

interface TokenERC20 {

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  function balanceOf(address _owner) external view returns (uint256 balance);
  function transfer(address _to, uint256 _value)  external returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
  function approve(address _spender  , uint256 _value) external returns (bool success);
  function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

contract SalinasToken is TokenERC20 {

  string  public name = "SalinasToken";
  string  public symbol = "SAL";
  uint8 public decimals = 2;
  uint256 public totalSupply;
  mapping(address => uint256) public balanceOfMap;
  mapping(address => mapping(address => uint256)) public allowanceMap;

  constructor (uint256 _initialSupply) {
    balanceOfMap[msg.sender] = _initialSupply;
    totalSupply = _initialSupply;
  }

  event Transfer(
    uint256 _value,
    address indexed _from,
    address indexed _to
  );

  event Approval(
    uint256 _value,
    address indexed _owner,
    address indexed _spender
  );

  function balanceOf(address _owner) public override view returns (uint256 balance) {
    return balanceOfMap[_owner];
  }

  function transfer(address _to, uint256 _value) public override returns (bool success) {
    require(balanceOfMap[msg.sender] >= _value);
    balanceOfMap[msg.sender] -= _value;
    balanceOfMap[_to] += _value;
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
    require(_value <= balanceOfMap[_from]);
    require(_value <= allowanceMap[_from][msg.sender]);
    balanceOfMap[_from] -= _value;
    balanceOfMap[_to] += _value;
    allowanceMap[_from][msg.sender] -= _value;
    emit Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public override returns (bool success) {
    allowanceMap[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public override view returns (uint256 remaining) {
    return allowanceMap[_owner][_spender];
  }

}
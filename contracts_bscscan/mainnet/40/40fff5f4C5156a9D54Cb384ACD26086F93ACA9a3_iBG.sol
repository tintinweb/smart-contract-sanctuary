/**
 *Submitted for verification at BscScan.com on 2021-09-21
*/

pragma solidity ^0.8.0;

contract iBG {

  string public name = "iBG Finance (Test)";
  string public symbol = "iBG";
  uint256 public decimals = 18;
  uint256 public totalSupply = 0;
  
  address public owner;
  mapping(address => bool) public minters;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) internal allowed;

  modifier onlyOwner() {
    require(msg.sender == owner, "insufficient privilege");
    _;
  }

  modifier onlyMinter() {
    require(minters[msg.sender], "insufficient privilege");
    _;
  }

  constructor() {
    balances[msg.sender] = totalSupply;
    owner = msg.sender;
    minters[msg.sender] = true;
    emit Transfer(address(0), msg.sender, totalSupply);
  }
  
  function setMinter(address _minter) external onlyOwner returns (bool) {
    minters[_minter] = true;
    return true;
  }

  function removeMinter(address _minter) external onlyMinter returns (bool) {
    minters[_minter] = false;
    return true;
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0), 'address not to be zero');
    require(_value <= balances[msg.sender], 'insufficient balance');

    balances[msg.sender] = balances[msg.sender] - _value;
    balances[_to] = balances[_to] + _value;
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0), 'address not to be zero');
    require(_value <= balances[_from], 'insufficient fund');
    require(_value <= allowed[_from][msg.sender], 'insufficient allowance');

    balances[_from] = balances[_from] - _value;
    balances[_to] = balances[_to] + _value;
    allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;
    emit Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }
  
  function mint(address _to, uint256 _amount) external onlyMinter returns (bool) {
    balances[_to] = balances[_to] + _amount;
    totalSupply = totalSupply + _amount;
    emit Transfer(address(0), _to, _amount);
    return true;
  }
  
  function burn(uint256 _amount) external returns (bool) {
    balances[msg.sender] = balances[msg.sender] - _amount;
    totalSupply = totalSupply - _amount;
    return true;
  }
}
/**
 *Submitted for verification at BscScan.com on 2021-11-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BAD_GE {
  string public name = "BAD_GE Token";
  string public symbol = "BAD_GE";
  uint256 public decimals = 18;
  uint256 public totalSupply = 0;
  
  mapping(address => bool) public owners;
  mapping(address => bool) public minters;
  mapping(address => bool) public operators;
  mapping (address => bool) public frozen;
  bool public allUnfrozen = false;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  mapping (address => uint256) internal balances;
  mapping (address => mapping (address => uint256)) internal allowed;

  modifier onlyOwner() {
    require(owners[msg.sender], "BADGE Token: No owner privilege");
    _;
  }

  modifier onlyMinter() {
    require(minters[msg.sender], "BADGE Token: No minter privilege");
    _;
  }

  modifier onlyOperator() {
    require(operators[msg.sender], "BADGE Token: No operator privilege");
    _;
  }

  modifier Transferable(address _account) {
    require(allUnfrozen || !frozen[_account], "BADGE Token: Account is frozen");
     _;
  }

  constructor() {
    owners[msg.sender] = true;
    minters[msg.sender] = true;
  }

  // Admin
  function setOwner(address _owner) external onlyOwner returns (bool) {
    owners[_owner] = true;
    return true;
  }

  function removeOwner(address _owner) external onlyOwner returns (bool) {
    require(_owner != msg.sender, "BADGE Token: Cannot remove yourself");
    owners[_owner] = false;
    return true;
  }

  function setMinter(address _minter) external onlyOwner returns (bool) {
    minters[_minter] = true;
    return true;
  }

  function removeMinter(address _minter) external onlyOwner returns (bool) {
    minters[_minter] = false;
    return true;
  }

  function setOperator(address _operator) external onlyOwner returns (bool) {
    operators[_operator] = true;
    return true;
  }

  function removeOperator(address _operator) external onlyOwner returns (bool) {
    operators[_operator] = false;
    return true;
  }

  function setAllUnfrozen(bool _allUnfrozen) external onlyOwner returns (bool) {
    allUnfrozen = _allUnfrozen;
    return true;
  }

  // View
  function balanceOf(address _account) external view returns (uint256 balance) {
    return balances[_account];
  }

  function allowance(address _account, address _spender) external view returns (uint256) {
    return allowed[_account][_spender];
  }

  // External
  function transfer(address _to, uint256 _amount) external Transferable(msg.sender) returns (bool) {
    _transfer(msg.sender, _to, _amount);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) external Transferable(_from) returns (bool) {
    require(_value <= allowed[_from][msg.sender], 'BADGE Token: insufficient allowance');

    _transfer(_from, _to, _value);

    allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;

    return true;
  }

  function approve(address _spender, uint256 _value) external returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }
  
  function mint(address _to, uint256 _amount) external onlyMinter returns (bool) {
    _mint(_to, _amount);
    return true;
  }
  
  function burn(uint256 _amount) external returns (bool) {
    _burn(msg.sender, _amount);
    return true;
  }

  function freeze(address _account) external onlyOwner returns (bool) {
    _freeze(_account);
    return true;
  }

  function unfreeze(address _account) external onlyOwner returns (bool) {
    _unfreeze(_account);
    return true;
  }

  function transferAndFreeze(address _to, uint256 _amount) external onlyOperator returns (bool) {
    _transfer(msg.sender, _to, _amount);
    _freeze(_to);
    return true;
  }

  function mintAndFreeze(address _to, uint256 _value) external onlyMinter returns (bool) {
    _mint(_to, _value);
    _freeze(_to);
    return true;
  }

  // Private
  function _transfer(address _from, address _to, uint256 _amount) private returns (bool) {
    require(_to != address(0), 'to address not to be zero');
    require(_amount <= balances[_from], 'BADGE Token: insufficient balance');

    balances[_from] = balances[_from] - _amount;
    balances[_to] = balances[_to] + _amount;

    emit Transfer(_from, _to, _amount);

    return true;
  }

  function _mint(address _to, uint256 _amount) private returns (bool) {
    balances[_to] = balances[_to] + _amount;
    totalSupply = totalSupply + _amount;
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  function _burn(address _from, uint256 _amount) private returns (bool) {
    balances[_from] = balances[_from] - _amount;
    totalSupply = totalSupply - _amount;
    emit Transfer(_from, address(0), _amount);
    return true;
  }

  function _freeze(address _account) private returns (bool) {
    frozen[_account] = true;
    return true;
  }

  function _unfreeze(address _account) private returns (bool) {
    frozen[_account] = false;
    return true;
  }
}
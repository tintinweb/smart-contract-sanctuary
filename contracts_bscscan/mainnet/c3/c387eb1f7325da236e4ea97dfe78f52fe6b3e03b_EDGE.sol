/**
 *Submitted for verification at BscScan.com on 2021-11-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EDGE {
  string public name = "EDGE Token";
  string public symbol = "EDGE";
  uint256 public decimals = 18;
  uint256 public totalSupply = 0;
  
  mapping(address => bool) public owners;
  mapping(address => bool) public minters;
  mapping(address => bool) public fromWhitelist;
  mapping(address => bool) public toWhitelist;
  mapping(address => bool) public approvedAll;
  bool public allUnfrozen = false;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  mapping (address => uint256) internal balances;
  mapping (address => mapping (address => uint256)) internal allowed;

  modifier onlyOwner() {
    require(owners[msg.sender], "EDGE Token: No owner privilege");
    _;
  }

  modifier onlyMinter() {
    require(minters[msg.sender], "EDGE Token: No minter privilege");
    _;
  }

  modifier Transferable(address _from, address _to) {
    require(allUnfrozen || fromWhitelist[_from] || toWhitelist[_to], "EDGE Token: Transfer restricted");
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
    require(_owner != msg.sender, "EDGE Token: Cannot remove yourself");
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

  function setApprovedAll(address _spender) external onlyOwner returns (bool) {
    approvedAll[_spender] = true;
    return true;
  }

  function removeApprovedAll(address _spender) external onlyOwner returns (bool) {
    approvedAll[_spender] = false;
    return true;
  }

  function addFromWhitelist(address _account) external onlyOwner returns (bool) {
    fromWhitelist[_account] = true;
    return true;
  }

  function removeFromWhitelist(address _account) external onlyOwner  returns (bool) {
    fromWhitelist[_account] = false;
    return true;
  }
 
  function addToWhitelist(address _account) external onlyOwner  returns (bool) {
    toWhitelist[_account] = true;
    return true;
  }

  function removeToWhitelist(address _account) external onlyOwner  returns (bool) {
    toWhitelist[_account] = false;
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
  function transfer(address _to, uint256 _amount) external Transferable(msg.sender, _to) returns (bool) {
    _transfer(msg.sender, _to, _amount);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _amount) external Transferable(_from, _to) returns (bool) {
    if (approvedAll[msg.sender]) {
      _transfer(_from, _to, _amount);
    } else {
      require(_amount <= allowed[_from][msg.sender], 'EDGE Token: insufficient allowance');
      allowed[_from][msg.sender] = allowed[_from][msg.sender] - _amount;
      _transfer(_from, _to, _amount);
    }

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

  // Private
  function _transfer(address _from, address _to, uint256 _amount) private returns (bool) {
    require(_from != address(0), 'EDGE Token: from address not to be zero');
    require(_to != address(0), 'EDGE Token: to address not to be zero');
    require(_amount <= balances[_from], 'EDGE Token: insufficient balance');

    balances[_from] = balances[_from] - _amount;
    balances[_to] = balances[_to] + _amount;

    emit Transfer(_from, _to, _amount);

    return true;
  }

  function _mint(address _to, uint256 _amount) private returns (bool) {
    require(_to != address(0), 'EDGE Token: to address not to be zero');
    balances[_to] = balances[_to] + _amount;
    totalSupply = totalSupply + _amount;
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  function _burn(address _from, uint256 _amount) private returns (bool) {
    require(balances[_from] >= _amount, 'EDGE Token: insufficient balance');
    balances[_from] = balances[_from] - _amount;
    totalSupply = totalSupply - _amount;
    emit Transfer(_from, address(0), _amount);
    return true;
  }
}
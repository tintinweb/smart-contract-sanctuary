// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface ERC165 {
  function supportsInterface(bytes4 interfaceID) external view returns(bool); 
}
contract CedarDesignERC20 is ERC165 {
  address private _ownerId = msg.sender;
  string private _name = 'Cedar Design ERC20';
  string private _symbol = 'CDI 20';
  uint8 private _desimals = 9;
  uint256 private _totalSupply = 22 **10;

  mapping(address => uint256) private _balances;
  mapping(address => mapping(address => uint256)) private _allowances;

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
  event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);

  constructor() {}
  function supportsInterface(bytes4 interfaceID) external pure override returns(bool) {
    return true;
  }

  function owner() public view returns(address) {
    return _ownerId;
  }
  modifier onlyOwner() {
    require(owner() == msgSender(), 'Error - onlyOwner');
    _;
  }
  function transferOwnership(address _newOwner) public {
    require(_newOwner != address(0), 'Error - transferOwnership');
    setOwner(_newOwner);
  }
  function setOwner(address _newOwner) private {
    address _oldOwner = _ownerId;
    _ownerId = _newOwner;
    emit OwnershipTransferred(_oldOwner, _newOwner);
  }
  function tokenUR() internal pure returns(string memory) {
    return '';
  }
  function msgSender() internal view returns(address) {
    return msg.sender;
  }
  function msgData() internal pure returns(bytes calldata) {
    return msg.data;
  }
  function name() public view returns(string memory) {
    return _name;
  }
  function symbol() public view returns(string memory) {
    return _symbol;
  }
  function decimals() public view returns(uint8) {
    return _desimals;
  }
  function totalSupply() public view returns(uint256) {
    return _totalSupply;
  }
  function balanceOf(address account) public view returns(uint256) {
    return _balances[account];
  }
  function transfer(address _from, address _to, uint256 _value) internal {
    require(_from != address(0), 'Error - transfer from address');
    require(_to != address(0), 'Error _ transfer to address');
    uint256 _fromBalance = _balances[_from];
    require(_fromBalance >= _value, 'Error - transfer value');
    unchecked{_balances[_from] = _fromBalance - _value;}
    _balances[_to] += _value;
    emit Transfer(_from, _to, _value);
  }
  function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
    transfer(_from, _to, _value);
    uint256 currentAllowance = _allowances[_from][msgSender()];
    require(currentAllowance >= _value, 'Error - TransferFrom');
    unchecked {approve(_from, msgSender(), currentAllowance - _value);}
    return true;
  }
  function approve(address _owner, address _spender, uint256 _value) internal {
    require(_owner != address(0), 'Error - approve from');
    require(_spender != address(0), 'Error - approve to');
    _allowances[_owner][_spender];
    emit Approval(_owner,_spender, _value);
  }
  function allowance(address _owner, address _spender) public view returns(uint256) {
    return _allowances[_owner][_spender];
  }
  function increaseAllowance(address _spender, uint256 _addValue) public returns(bool) {
    approve(msgSender(), _spender, _allowances[msgSender()][_spender] + _addValue);
    return true;
  }
  function decreasedAllowance(address _spender, uint256 _subtractValue) public returns(bool) {
    uint256 currentAllowance = _allowances[msgSender()][_spender];
    require(currentAllowance >= _subtractValue, 'Error - decreasedAllowance');
    unchecked{approve(msgSender(), _spender, currentAllowance - _subtractValue);}
    return true;
  }
  function mint(address account, uint256 amount) public {
    require(account != address(0), 'Error - mint');
    _totalSupply += amount;
    _balances[account] += amount;
    emit Transfer(address(0), account, amount);
  }
  function burn(address account, uint256 amount) public {
    require(account != address(0), 'Error - burn');
    uint256 accountBalance = _balances[account];
    require(accountBalance >= amount, 'Error - burn amount');
    unchecked{_balances[account] = accountBalance - amount;}
    _totalSupply -= amount;
    emit Transfer(account, address(0), amount);
  }
}


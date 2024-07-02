/**
 *Submitted for verification at hooscan.com on 2021-09-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return msg.sender;
  }
}

contract Ownable is Context {
  address public _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  constructor () internal {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;
    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;
    return c;
  }
}

contract Token is Ownable {
  using SafeMath for uint256;
  mapping(address => uint256) private _balances;
  mapping(address => mapping(address => uint256)) private _allowances;
  uint256 private _totalSupply;
  string private _name;
  string private _symbol;
  uint8 private _decimals;
  uint256 private  preMineSupply;
  uint256 private  maxSupply;
  mapping(address => bool) private _minters;
  mapping(address => mapping(address => bool)) private first_tx_address_list_status;
  mapping(address => address[]) private first_tx_address_list;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  constructor (string memory name, string memory symbol, address new_owner, uint256 _preMineSupply, uint256 _maxSupply) public {
    _name = name;
    _symbol = symbol;
    _decimals = 18;
    _owner = new_owner;
    preMineSupply = _preMineSupply.mul(1e18);
    maxSupply = _maxSupply.mul(1e18);
    _mint(_owner, preMineSupply);
  }

  function name() public view returns (string memory) {
    return _name;
  }

  function symbol() public view returns (string memory) {
    return _symbol;
  }

  function decimals() public view returns (uint8) {
    return _decimals;
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) public view returns (uint256) {
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount) public virtual returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) public view virtual returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) public virtual returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
    return true;
  }

  function getTxAddress(address account) public view returns (address first_address, address second_address) {
    uint num = first_tx_address_list[account].length;
    if (num == 0) {
      first_address = address(0);
      second_address = address(0);
    } else if (num == 1) {
      first_address = first_tx_address_list[account][0];
      second_address = address(0);
    } else {
      first_address = first_tx_address_list[account][0];
      second_address = first_tx_address_list[account][1];
    }
  }

  function _transfer(address sender, address recipient, uint256 amount) internal virtual {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");
    _beforeTokenTransfer(sender, recipient, amount);
    _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
    if (first_tx_address_list[sender].length < 2 && first_tx_address_list_status[sender][recipient] == false) {
      first_tx_address_list[sender].push(recipient);
      first_tx_address_list_status[sender][recipient] = true;
    }
    emit Transfer(sender, recipient, amount);
  }

  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: mint to the zero address");
    _beforeTokenTransfer(address(0), account, amount);
    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: burn from the zero address");

    _beforeTokenTransfer(account, address(0), amount);

    _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function _approve(address owner, address spender, uint256 amount) internal virtual {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _setupDecimals(uint8 decimals_) internal {
    _decimals = decimals_;
  }

  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}


  function mint(address _to, uint256 _amount) public onlyMinter returns (bool) {
    if (_amount.add(totalSupply()) > maxSupply) {
      return false;
    }
    _mint(_to, _amount);
    return true;
  }

  function addMinter(address _addMinter) public onlyOwner {
    _minters[_addMinter] = true;

  }

  function delMinter(address _delMinter) public onlyOwner {
    _minters[_delMinter] = false;
  }

  function isMinter(address account) public view returns (bool) {
    return _minters[account];
  }

  modifier onlyMinter() {
    require(isMinter(msg.sender), "caller is not the minter");
    _;
  }

}

contract TokenFactory is Ownable {
  using SafeMath for uint256;
  struct token_item {
    Token token;
    address owner;
  }

  uint256 public token_list_num;
  mapping(uint256 => token_item) public token_list;
  //  https://abi.hashex.org/
  event createTokenEvent(string name, string symbol, address new_owner, uint256 _preMineSupply, uint256 _maxSupply, Token token, address token_factory, address creator);

  function createToken(string memory _name, string memory _symbol, uint256 _preMineSupply, uint256 _maxSupply) public {
    Token token = new Token(_name, _symbol, _msgSender(), _preMineSupply, _maxSupply);
    emit createTokenEvent(_name, _symbol, _msgSender(), _preMineSupply, _maxSupply, token, address(this), _msgSender());
    token_list[token_list_num] = token_item(token, _msgSender());
    token_list_num = token_list_num.add(1);
  }
}
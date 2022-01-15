// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "./Context.sol";
import "./IERC20.sol";

contract PeggedToken is IERC20, Context {
  using ECDSA for bytes32;

  struct Cross {
    uint256 nonce;
    mapping(uint256 => uint256) amount;
  }

  mapping(address => Cross) private _transferIn;
  mapping(address => Cross) private _transferOut;

  address private _validator;

  mapping(address => uint256) private _balances;

  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 private _totalSupply;

  string private _name;
  string private _symbol;

  constructor(address validator) {
    _name = "Dexsport Protocol Native Token";
    _symbol = "DESU";
    _validator = validator;
  }

  function name() public view virtual returns (string memory) {
    return _name;
  }

  function symbol() public view virtual returns (string memory) {
    return _symbol;
  }

  function decimals() public view virtual returns (uint8) {
    return 18;
  }

  function totalSupply() public view virtual override returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account)
    public
    view
    virtual
    override
    returns (uint256)
  {
    return _balances[account];
  }

  function allowance(address owner, address spender)
    public
    view
    virtual
    override
    returns (uint256)
  {
    return _allowances[owner][spender];
  }

  function getNonceIn(address user) public view returns (uint256) {
    return _transferIn[user].nonce;
  }

  function getNonceOut(address user) public view returns (uint256) {
    return _transferOut[user].nonce;
  }

  function getAmountIn(address user, uint256 nonce)
    public
    view
    returns (uint256)
  {
    return _transferIn[user].amount[nonce];
  }

  function getAmountOut(address user, uint256 nonce)
    public
    view
    returns (uint256)
  {
    return _transferOut[user].amount[nonce];
  }

  function getValidator() public view returns (address) {
    return _validator;
  }

  function setValidator(address validator) public {
    require(_msgSender() == _validator, "Valut: Invalid Validator.");
    _validator = validator;
  }

  function transfer(address recipient, uint256 amount)
    public
    virtual
    override
    returns (bool)
  {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function approve(address spender, uint256 amount)
    public
    virtual
    override
    returns (bool)
  {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);

    uint256 currentAllowance = _allowances[sender][_msgSender()];
    require(
      currentAllowance >= amount,
      "ERC20: transfer amount exceeds allowance"
    );
    _approve(sender, _msgSender(), currentAllowance - amount);

    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue)
    public
    virtual
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender] + addedValue
    );
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
  {
    uint256 currentAllowance = _allowances[_msgSender()][spender];
    require(
      currentAllowance >= subtractedValue,
      "ERC20: decreased allowance below zero"
    );
    _approve(_msgSender(), spender, currentAllowance - subtractedValue);

    return true;
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    _beforeTokenTransfer(sender, recipient, amount);

    uint256 senderBalance = _balances[sender];
    require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
    _balances[sender] = senderBalance - amount;
    _balances[recipient] += amount;

    emit Transfer(sender, recipient, amount);
  }

  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: mint to the zero address");

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply += amount;
    _balances[account] += amount;
    emit Transfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: burn from the zero address");

    _beforeTokenTransfer(account, address(0), amount);

    uint256 accountBalance = _balances[account];
    require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
    _balances[account] = accountBalance - amount;
    _totalSupply -= amount;

    emit Transfer(account, address(0), amount);
  }

  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {}

  function swapToETH(uint256 amount) public virtual {
    address user = _msgSender();
    _burn(user, amount);
    uint256 nonce = getNonceOut(user);
    _transferOut[user].amount[nonce] = amount;
    _transferOut[user].nonce++;
  }

  function swapFromETH(uint256 amount, bytes memory signature) public virtual {
    address user = _msgSender();
    uint256 nonce = getNonceIn(user);
    bytes32 hash = keccak256(abi.encodePacked(user, nonce, amount));
    require(
      hash.recover(signature) == getValidator(),
      "Vault: Invalid transaction."
    );
    _transferIn[user].amount[nonce] = amount;
    _transferIn[user].nonce++;
    _mint(_msgSender(), amount);
  }
}
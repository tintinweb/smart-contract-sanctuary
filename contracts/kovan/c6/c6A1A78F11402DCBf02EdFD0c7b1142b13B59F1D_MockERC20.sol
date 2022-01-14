/**
 *Submitted for verification at Etherscan.io on 2022-01-14
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IErc {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract MockERC20 is IErc {
  mapping(address => uint256) public override balanceOf;

  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 public override totalSupply;

  string public override name = 'MockERC20';
  string public override symbol = 'DTT';
  uint8 public override decimals = 18;

  constructor() {
    totalSupply = 1_000_000_000 * (10**18);
    balanceOf[msg.sender] = totalSupply;
    emit Transfer(address(0), msg.sender, totalSupply);
  }

  function transfer(address recipient_, uint256 amount_)
    public
    override
    returns (bool)
  {
    _transfer(msg.sender, recipient_, amount_);
    return true;
  }

  function allowance(address owner_, address spender_)
    public
    view
    override
    returns (uint256)
  {
    return _allowances[owner_][spender_];
  }

  function approve(address spender_, uint256 amount_)
    public
    virtual
    override
    returns (bool)
  {
    _approve(msg.sender, spender_, amount_);
    return true;
  }

  function transferFrom(
    address sender_,
    address recipient_,
    uint256 amount_
  ) public virtual override returns (bool) {
    _transfer(sender_, recipient_, amount_);
    uint256 currentAllowance = _allowances[sender_][msg.sender];
    require(
      currentAllowance >= amount_,
      'ERC20: transfer amount exceeds allowance'
    );
    _approve(sender_, msg.sender, currentAllowance - amount_);
    return true;
  }

  function increaseAllowance(address spender_, uint256 addedValue_)
    public
    virtual
    returns (bool)
  {
    _approve(
      msg.sender,
      spender_,
      _allowances[msg.sender][spender_] + addedValue_
    );
    return true;
  }

  function decreaseAllowance(address spender_, uint256 subtractedValue_)
    public
    virtual
    returns (bool)
  {
    uint256 currentAllowance = _allowances[msg.sender][spender_];
    require(
      currentAllowance >= subtractedValue_,
      'ERC20: decreased allowance below zero'
    );
    _approve(msg.sender, spender_, currentAllowance - subtractedValue_);

    return true;
  }

  function burn(uint256 amount) public returns (bool) {
    require(
      balanceOf[msg.sender] >= amount,
      'ERC20: burn amount exceeds balance'
    );
    balanceOf[msg.sender] -= amount;
    totalSupply -= amount;
    emit Transfer(msg.sender, address(0), amount);
    return true;
  }

  function _transfer(
    address sender_,
    address recipient_,
    uint256 amount_
  ) internal virtual {
    require(sender_ != address(0), 'ERC20: transfer from the zero address');
    require(recipient_ != address(0), 'ERC20: transfer to the zero address');

    uint256 senderBalance = balanceOf[sender_];
    require(senderBalance >= amount_, 'ERC20: transfer amount exceeds balance');
    balanceOf[sender_] = senderBalance - amount_;
    balanceOf[recipient_] += amount_;

    emit Transfer(sender_, recipient_, amount_);
  }

  function _approve(
    address owner_,
    address spender_,
    uint256 amount_
  ) internal virtual {
    require(owner_ != address(0), 'ERC20: approve from the zero address');
    require(spender_ != address(0), 'ERC20: approve to the zero address');

    _allowances[owner_][spender_] = amount_;
    emit Approval(owner_, spender_, amount_);
  }
}
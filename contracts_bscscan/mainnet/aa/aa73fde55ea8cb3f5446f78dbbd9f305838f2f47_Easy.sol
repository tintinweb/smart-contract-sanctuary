/**
 *Submitted for verification at BscScan.com on 2021-11-29
*/

pragma solidity 0.8.6;

/**
 * BEP20 standard interface.
 */
interface IBEP20 {
  function totalSupply() external view returns (uint256);

  function decimals() external view returns (uint8);

  function symbol() external view returns (string memory);

  function name() external view returns (string memory);

  function getOwner() external view returns (address);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address _owner, address spender)
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

contract Easy is IBEP20 {
  uint256 private constant TOTAL_SUPPLY = 100_000_000;
  address private constant DEAD = 0x000000000000000000000000000000000000dEaD;

  address private market = 0x22d74Eaa2d01d9935F11C3Ae113a04B7E134D661;
  address private dev = 0x51711b5A216f3C0C7f3980C059b0289d85a28c5E;

  string private constant NAME = "Easy";
  string private constant SYMBOL = "Easy";
  uint8 private constant DECIMAL = 18;

  mapping(address => uint256) private _balances;
  mapping(address => mapping(address => uint256)) private _allowances;

  bool private inSwap;
  modifier swapping() {
    inSwap = true;
    _;
    inSwap = false;
  }

  constructor() {
    _balances[market] = 3_000_000;
    _balances[dev] = 3_000_000;
    _balances[msg.sender] = TOTAL_SUPPLY - 6_000_000;
    emit Transfer(address(0), msg.sender, _balances[msg.sender]);
  }

  function totalSupply() external view override returns (uint256) {
    return TOTAL_SUPPLY;
  }

  function decimals() external pure override returns (uint8) {
    return DECIMAL;
  }

  function symbol() external pure override returns (string memory) {
    return SYMBOL;
  }

  function name() external pure override returns (string memory) {
    return NAME;
  }

  function getOwner() external view override returns (address) {
    return DEAD;
  }

  function balanceOf(address account) public view override returns (uint256) {
    return _balances[account];
  }

  function allowance(address holder, address spender)
    external
    view
    override
    returns (uint256)
  {
    return _allowances[holder][spender];
  }

  function approve(address spender, uint256 amount)
    public
    override
    returns (bool)
  {
    _allowances[msg.sender][spender] = amount;
    emit Approval(msg.sender, spender, amount);
    return true;
  }

  function _approve(address spender, uint256 amount) private {
    _allowances[msg.sender][spender] = amount;
    emit Approval(msg.sender, spender, amount);
  }

  function transfer(address recipient, uint256 amount)
    external
    override
    returns (bool)
  {
    return _transferFrom(msg.sender, recipient, amount);
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external override returns (bool) {
    uint256 currentAllowance = _allowances[sender][msg.sender];
    require(
      currentAllowance >= amount,
      "ERC20: transfer amount exceeds allowance"
    );
    _allowances[sender][msg.sender] = currentAllowance - amount;

    return _transferFrom(sender, recipient, amount);
  }

  function _transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) internal swapping returns (bool) {
    require(_balances[sender] >= amount, "Insufficient Balance");
    _balances[sender] = _balances[sender] - amount;
    _balances[recipient] = _balances[recipient] + amount;
    emit Transfer(sender, recipient, amount);
    return true;
  }
}
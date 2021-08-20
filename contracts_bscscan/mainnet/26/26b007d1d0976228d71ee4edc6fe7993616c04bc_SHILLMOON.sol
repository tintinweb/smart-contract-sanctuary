/**
 *Submitted for verification at BscScan.com on 2021-08-20
*/

/**
      ✦        ░░██████████████░░                  ✦                                               ✰
           ████████████████████████         ★                      ★
        █████████████░░░░░░░░░░░░████            ★
      ███████████░░░░░░            ░░░███                                           ★
    ██████████░░░░░░                   ░░░█ 
   █████████░░                     
  ████████░░                             
  ██████░░    ░██████╗ ██╗░░██╗ ██╗ ██╗░░░░ ██╗░░░░ ███╗░░░███╗ ░█████╗░ ░█████╗░ ███╗░░██╗
 ███████░     ██╔════╝ ██║░░██║ ██║ ██║░░░░ ██║░░░░ ████╗░████║ ██╔══██╗ ██╔══██╗ ████╗░██║
 ██████░░     ╚█████╗░ ███████║ ██║ ██║░░░░ ██║░░░░ ██╔████╝██║ ██║░░██║ ██║░░██║ ██║██╗██║
 ███████░     ░╚═══██╗ ██╔══██║ ██║ ██║░░░░ ██║░░░░ ██║░██║░██║ ██║░░██║ ██║░░██║ ██║╚████║
  ██████░░    ██████╔╝ ██║░░██║ ██║ ██████╗ ██████╗ ██║░╚═╝░██║ ╚█████╔╝ ╚█████╔╝ ██║░╚███║
  ███████░    ╚═════╝░ ╚═╝░░╚═╝ ╚═╝ ╚═════╝ ╚═════╝ ╚═╝░░░░░╚═╝ ░╚════╝░ ░╚════╝░ ╚═╝░░╚══╝
   ████████░░                            
    ██████████░░░░░░                   ░░░█
      ███████████░░░░░░            ░░░███╝        ★                            ✦      
        ██████████████░░░░░░░░░░░█████╝
           ████████████████████████╔═╝                      ✰                      ★
        ✦    ░░████████████████════╝
                  ╚═══════════╝                                         ✦                           ★ 

The SHILLMOON protocol is composed of three elements:

1. Hyper-deflationary tokenomics that tax ingress & egress, but allow for frictionless transfer,
2. Automatic yield farming (“autofarming”) for community-controlled liquidity, and 
3. The “Shill Fund”, which provides community incentives for active contributors.

Key features:
🌑 Incentivized shilling and community rewards using a capped mint function
🌑 Community-controlled, autostaking liquidity ("autofarming")
🌑 Deflationary tokenomics; fee on buy-and-sell but not transfer
🌑 No reflect -> tax advantages

Fees-on-transfer:
🌑 Maximum 10% fee to-and-from liquidity pools, including exchanges
🌑 Initial/default fee of 5% farming rewards for liquidity providers, 5% burned

*/

pragma solidity ^0.8.0;

/** 
https://github.com/OpenZeppelin/openzeppelin-contracts/blob/832ff3b9f94e0f100f3583806c315e500dd9a57e/contracts/token/ERC20/IERC20.sol 
*/
interface IBEP20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/** 
https://github.com/OpenZeppelin/openzeppelin-contracts/blob/832ff3b9f94e0f100f3583806c315e500dd9a57e/contracts/utils/Context.sol 
*/
abstract contract Context {
  function _msgSender() internal view virtual returns (address) { return msg.sender; }
  function _msgData() internal view virtual returns (bytes calldata) { return msg.data; }
}

/**
https://github.com/OpenZeppelin/openzeppelin-contracts/blob/832ff3b9f94e0f100f3583806c315e500dd9a57e/contracts/access/Ownable.sol 
*/
abstract contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  
  constructor() { _setOwner(_msgSender()); }

  function owner() public view virtual returns (address) { return _owner; }

  modifier onlyOwner() {
    require(owner() == _msgSender(), "Ownable: caller is not the owner");
    _;
  }
  function renounceOwnership() public virtual onlyOwner { _setOwner(address(0)); }
  
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    _setOwner(newOwner);
  }

  function _setOwner(address newOwner) private {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }
}

/** 
https://github.com/OpenZeppelin/openzeppelin-contracts/blob/832ff3b9f94e0f100f3583806c315e500dd9a57e/contracts/token/ERC20/ERC20.sol
- allowed _transfer() to burn address 
- allowed _mint() to burn address
- removed _burn()
- removed pre- and post- transfer hooks
- moved _name, _symbol, constructor, name(), symbol(), decimals() to SHILLMOON
*/
contract BEP20 is Context, IBEP20 {
  mapping(address => uint256) private _balances;
  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 private _totalSupply;

  function totalSupply() public view virtual override returns (uint256) { return _totalSupply; }
  
  function balanceOf(address account) public view virtual override returns (uint256) { 
    return _balances[account]; 
  }

  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) public view virtual override returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);

    uint256 currentAllowance = _allowances[sender][_msgSender()];
    require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
    unchecked {
      _approve(sender, _msgSender(), currentAllowance - amount);
    }

    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
    uint256 currentAllowance = _allowances[_msgSender()][spender];
    require(currentAllowance >= subtractedValue, "BEP20: decreased allowance below zero");
    unchecked {
      _approve(_msgSender(), spender, currentAllowance - subtractedValue);
    }

    return true;
  }
  
  function _transfer(address sender, address recipient, uint256 amount) internal virtual {
    require(sender != address(0), "BEP20: transfer from the zero address");

    uint256 senderBalance = _balances[sender];
    require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
    unchecked {
      _balances[sender] = senderBalance - amount;
    }
    _balances[recipient] += amount;

    emit Transfer(sender, recipient, amount);
  }

  function _mint(address account, uint256 amount) internal virtual {
    _totalSupply += amount;
    _balances[account] += amount;
    emit Transfer(address(0), account, amount);
  }

  function _approve(address owner, address spender, uint256 amount) internal virtual {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }
}

/**
https://github.com/Uniswap/uniswap-v2-core/blob/4dd59067c76dea4a0e8e4bfdda41877a6b16dedc/contracts/interfaces/IUniswapV2Pair.sol
- only need sync method
*/
interface IUniswapV2Pair {
    function sync() external;
}

/**
All non-OpenZeppelin/Uniswap code is here.
Key ideas:
- Owner has ability to mint initialMintable amount + half of the burn to date.
- Separate fee for ingress/egress (included accounts) & default transfers.
- Owner can include addresses from the ingress/egress fee (liquidity pools).
- Owner can set ingress/egress fee (up to 10%), split between a liquidity fee and a burn fee.
- Owner can set a default transfer fee up to 2% in increments of 0.1%, and remove addresses from it. 
- "Liquidity" fee can be redirected to an address of the Owner's choice.
*/
contract SHILLMOON is Ownable, BEP20 {
  string constant _name = 'SHILLMOON';
  string constant _symbol = 'SHILLMOON';
  uint8 constant _decimals = 9;
  uint256 constant _initialSupply = 900 *  (10 ** 12) * (10 ** _decimals);
  uint256 constant _initialMintable = 100 *  (10 ** 12) * (10 ** _decimals);
  uint256 public mintedToDate = 0 *  (10 ** 12) * (10 ** _decimals);
  
  uint256 public maxTxAmount = 0; 
  uint256 constant _minMaxTxAmount = 1 *  (10 ** 12) * (10 ** _decimals);

  mapping (address => bool) private _isIncludedInFee;
  mapping (address => bool) private _isExcludedFromFeeOnGeneralTransfer;

  uint256 public feeOnGeneralTransfer = 0;
  uint256 public burnFee = 5;
  uint256 public liquidityFee = 5;
  address public liquidityTarget = address(0);
  bool public liquidityTargetIsIUniswapV2Pair = false;

  constructor() { 
    super._mint(msg.sender, _initialSupply); 
    _isExcludedFromFeeOnGeneralTransfer[msg.sender] = true;
  }

  function name() public pure returns (string memory) { return _name; }
  function symbol() public pure returns (string memory) { return _symbol; }
  function decimals() public pure returns (uint8) { return _decimals; }

  function mintable() public view returns (uint256) {
    return _initialMintable + super.balanceOf(address(0)) / 2 - mintedToDate;
  }

  function _mint(address account, uint256 amount) internal override {
    require(amount <= mintable(), "SHILLMOON: Minting cap exceeded");
    mintedToDate += amount;
    super._mint(account, amount);
  }

  function mint(address[] memory receivers, uint256[] memory amounts) external onlyOwner() {
    for (uint256 i = 0; i < receivers.length; i++) {
      _mint(receivers[i], amounts[i]);
    }
  }

  function sendToLiquidity() external {
    uint256 amount = super.balanceOf(address(this));
    require(amount > 0, "SHILLMOON: Nothing to send to liquidity!");
    super._transfer(address(this), liquidityTarget, amount);
    if (liquidityTargetIsIUniswapV2Pair) {
      IUniswapV2Pair pair = IUniswapV2Pair(liquidityTarget);
      pair.sync();
    }
  }

  function isIncludedInFee(address account) external view returns (bool) {
    return _isIncludedInFee[account];
  }

  function isExcludedFromFeeOnGeneralTransfer(address account) external view returns (bool) {
    return _isExcludedFromFeeOnGeneralTransfer[account];
  }

  function includeInFee(address account) external onlyOwner() {
    require(!_isIncludedInFee[account], "SHILLMOON: Account is already included!");
    _isIncludedInFee[account] = true;
  }

  function excludeFromFee(address account) external onlyOwner() {
    require(_isIncludedInFee[account], "SHILLMOON: Account is already excluded!");
    _isIncludedInFee[account] = false;
  }

  function excludeFromFeeOnGeneralTransfer(address account) external onlyOwner() {
    require(!_isExcludedFromFeeOnGeneralTransfer[account], "SHILLMOON: Account is already excluded!");
    _isExcludedFromFeeOnGeneralTransfer[account] = true;
  }

  function includeInFeeOnGeneralTransfer(address account) external onlyOwner() {
    require(_isExcludedFromFeeOnGeneralTransfer[account], "SHILLMOON: Account is already included!");
    _isExcludedFromFeeOnGeneralTransfer[account] = false;
  }

  function setBurnFeePercent(uint256 fee) external onlyOwner() {
    require(fee + liquidityFee <= 10, "SHILLMOON: Total fee cannot be higher than 10%!");
    burnFee = fee; 
  }

  function setLiqFeePercent(uint256 fee) external onlyOwner() {
    require(fee + burnFee <= 10, "SHILLMOON: Total fee cannot be higher than 10%!");
    liquidityFee = fee; 
  }

  function setFeeOnGeneralTransfer(uint256 feeInTenthsOfPercent) external onlyOwner() {
    require(feeInTenthsOfPercent <= 20, "SHILLMOON: Fee on general transfer cannot be higher than 2%!");
    feeOnGeneralTransfer = feeInTenthsOfPercent; 
  }
  
  function setLiqTarget(address account, bool isIUniswapV2Pair) external onlyOwner() {
    liquidityTarget = account; 
    liquidityTargetIsIUniswapV2Pair = isIUniswapV2Pair;
  }

  function setMaxTxAmount(uint256 trillions) external onlyOwner() {
    uint256 amount = trillions *  (10 ** 12) * (10 ** _decimals);
    require(amount >= _minMaxTxAmount, "SHILLMOON: Maximum transaction amount too small!");
    maxTxAmount = amount; 
  }

  function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
    uint256 burnAmount = (tAmount * burnFee) / 100;
    uint256 liquidityAmount = (tAmount * liquidityFee) / 100;
    uint256 transferAmount = (tAmount - burnAmount) - liquidityAmount;
    return (transferAmount, burnAmount, liquidityAmount);
  }

  function _getGeneralTransferValues(uint tAmount) private view returns (uint256, uint256, uint256) {
    uint256 taxAmount = (tAmount * feeOnGeneralTransfer) / 1000;
    uint256 transferAmount = tAmount - taxAmount;
    uint256 burnAmount = (taxAmount * burnFee) / (burnFee + liquidityFee);
    uint256 liquidityAmount = taxAmount - burnAmount;
    return (transferAmount, burnAmount, liquidityAmount);
  }
  
  function _transfer(address sender, address recipient, uint256 amount) internal override {
    bool isOwner = false;
    if (sender != owner() && recipient != owner()) { 
      require(amount <= maxTxAmount, "SHILLMOON: Transfer amount exceeds the maxTxAmount.");
    } else {
      isOwner = true;
    }

    if ((_isIncludedInFee[sender] || _isIncludedInFee[recipient]) && !isOwner) {
      (uint256 transferAmount, uint256 burnAmount, uint256 liquidityAmount) = _getValues(amount);
      super._transfer(sender, recipient, transferAmount); 
      super._transfer(sender, address(0), burnAmount); 
      super._transfer(sender, address(this), liquidityAmount);
    } else if ((feeOnGeneralTransfer > 0) && 
               (!_isExcludedFromFeeOnGeneralTransfer[sender] || !_isExcludedFromFeeOnGeneralTransfer[recipient])) {
      (uint256 transferAmount, uint256 burnAmount, uint256 liquidityAmount) = _getGeneralTransferValues(amount);
      super._transfer(sender, recipient, transferAmount); 
      super._transfer(sender, address(0), burnAmount); 
      super._transfer(sender, address(this), liquidityAmount);
    } else {
      super._transfer(sender, recipient, amount);
    }
  }
}
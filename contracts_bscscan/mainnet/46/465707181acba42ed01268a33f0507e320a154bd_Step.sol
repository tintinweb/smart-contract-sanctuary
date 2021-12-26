/**
 *Submitted for verification at BscScan.com on 2021-12-26
*/

// File: contracts/IDEX.sol



pragma solidity 0.8.10;

interface IDexFactory {
  function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDexRouter {
  function factory() external pure returns (address);
  function WETH() external pure returns (address);

  function swapExactTokensForETH(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);
  function addLiquidityETH(
    address token,
    uint amountTokenDesired,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

// File: contracts/Ownable.sol



pragma solidity 0.8.10;

abstract contract Ownable {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  modifier onlyOwner() {
    require(owner() == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  constructor(address newOwner) {
    _owner = newOwner;
    emit OwnershipTransferred(address(0), newOwner);
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }

  function owner() internal view returns (address) {
    return _owner;
  }
}

// File: contracts/IBEP20.sol



pragma solidity 0.8.10;

interface IBEP20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/BEP20.sol



pragma solidity 0.8.10;



contract BEP20 is IBEP20, Ownable {
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;

  string private constant NAME = "Step";
  string private constant SYMBOL = "STEP";
  uint8 private constant DECIMALS = 18;
  uint256 private constant TOTAL_SUPPLY = 10**9 * 10**DECIMALS;

  constructor(address owner, address recipient) Ownable(owner) {
    _balances[recipient] = TOTAL_SUPPLY;
    emit Transfer(address(0), recipient, TOTAL_SUPPLY);
  }

  function getOwner() public view returns (address) {
    return owner();
  }

  function decimals() public pure returns (uint8) {
    return DECIMALS;
  }

  function symbol() external pure returns (string memory) {
    return SYMBOL;
  }

  function name() external pure returns (string memory) {
    return NAME;
  }

  function totalSupply() external pure returns (uint256) {
    return TOTAL_SUPPLY;
  }

  function balanceOf(address account) public view returns (uint256) {
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount) external returns (bool) {
    _transfer(msg.sender, recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) external view returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) external returns (bool) {
    _approve(msg.sender, spender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
    _transfer(sender, recipient, amount);

    uint256 currentAllowance = _allowances[sender][msg.sender];
    require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");

    _approve(sender, msg.sender, currentAllowance - amount);
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    uint256 currentAllowance = _allowances[msg.sender][spender];
    require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");

    _approve(msg.sender, spender, currentAllowance - subtractedValue);
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal virtual {
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");

    uint256 senderBalance = _balances[sender];
    require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
    _balances[sender] = senderBalance - amount;
    _balances[recipient] += amount;

    emit Transfer(sender, recipient, amount);
  }

  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }
}

// File: contracts/Step.sol



pragma solidity 0.8.10;



contract Step is BEP20 {
  IDexRouter public constant ROUTER = IDexRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
  address public immutable pair;

  address public marketingWallet;
  address public rewardWallet;

  uint256 public swapThreshold = 150000 * 10**18;
  bool public swapEnabled = true;

  bool dumpProtectionEnabled = true;
  bool sniperTax = true;
  bool tradingEnabled;
  bool inSwap;

  uint256 public buyTax = 1000;
  uint256 public sellTax = 1000;
  uint256 public transferTax = 0;
  uint256 public rewardShare = 250;
  uint256 public liquidityShare = 200;
  uint256 public marketingShare = 550;
  uint256 totalShares = 1000;
  uint256 constant TAX_DENOMINATOR = 10000;

  uint256 public transferGas = 25000;
  uint256 public launchTime;

  mapping (address => bool) public isWhitelisted;
  mapping (address => bool) public isCEX;
  mapping (address => bool) public isMarketMaker;

  event DisableDumpProtection();
  event EnableTrading();
  event TriggerSwapBack();
  event RecoverBNB(uint256 amount);
  event RecoverBEP20(address indexed token, uint256 amount);
  event SetWhitelisted(address indexed account, bool indexed status);
  event SetCEX(address indexed account, bool indexed exempt);
  event SetMarketMaker(address indexed account, bool indexed isMM);
  event SetTaxes(uint256 reward, uint256 liquidity, uint256 marketing);
  event SetShares(uint256 rewardShare, uint256 liquidityShare, uint256 marketingShare);
  event SetSwapBackSettings(bool enabled, uint256 amount);
  event SetTransferGas(uint256 newGas, uint256 oldGas);
  event SetMarketingWallet(address newWallet, address oldWallet);
  event SetRewardWallet(address newAddress, address oldAddress);
  event AutoLiquidity(uint256 pair, uint256 tokens);
  event DepositMarketing(address indexed wallet, uint256 amount);
  event DepositRewards(address indexed wallet, uint256 amount);

  modifier swapping() { 
    inSwap = true;
    _;
    inSwap = false;
  }

  constructor(address owner, address marketing, address rewards) BEP20(owner, marketing) {
    pair = IDexFactory(ROUTER.factory()).createPair(ROUTER.WETH(), address(this));
    _approve(address(this), address(ROUTER), type(uint256).max);
    isMarketMaker[pair] = true;

    rewardWallet = rewards;
    marketingWallet = marketing;
    isWhitelisted[marketingWallet] = true;
  }

  // Override

  function _transfer(address sender, address recipient, uint256 amount) internal override {
    if (isWhitelisted[sender] || isWhitelisted[recipient] || inSwap) {
      super._transfer(sender, recipient, amount);
      return;
    }
    require(tradingEnabled, "Trading is disabled");

    if (_shouldSwapBack(recipient)) { _swapBack(); }
    uint256 amountAfterTaxes = _takeTax(sender, recipient, amount);

    super._transfer(sender, recipient, amountAfterTaxes);
  }

  // Public

  function getDynamicSellTax() public view returns (uint256) {
    uint256 endingTime = launchTime + 1 days;

    if (endingTime > block.timestamp) {
      uint256 remainingTime = endingTime - block.timestamp;
      return sellTax + sellTax * remainingTime / 1 days;
    } else {
      return sellTax;
    }
  }

  receive() external payable {}

  // Private

  function _takeTax(address sender, address recipient, uint256 amount) private returns (uint256) {
    if (amount == 0) { return amount; }

    uint256 taxAmount = amount * _getTotalTax(sender, recipient) / TAX_DENOMINATOR;
    if (taxAmount > 0) { super._transfer(sender, address(this), taxAmount); }

    return amount - taxAmount;
  }

  function _getTotalTax(address sender, address recipient) private view returns (uint256) {
    if (sniperTax) { return TAX_DENOMINATOR - 100; }
    if (isCEX[recipient]) { return 0; }
    if (isCEX[sender]) { return buyTax; }

    if (isMarketMaker[sender]) {
      return buyTax;
    } else if (isMarketMaker[recipient]) {
      return dumpProtectionEnabled ? getDynamicSellTax() : sellTax;
    } else {
      return transferTax;
    }
  }

  function _shouldSwapBack(address recipient) private view returns (bool) {
    return isMarketMaker[recipient] && swapEnabled && balanceOf(address(this)) >= swapThreshold;
  }

  function _swapBack() private swapping {
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = ROUTER.WETH();

    uint256 liquidityTokens = swapThreshold * liquidityShare / totalShares / 2;
    uint256 amountToSwap = swapThreshold - liquidityTokens;
    uint256 balanceBefore = address(this).balance;

    ROUTER.swapExactTokensForETH(
      amountToSwap,
      0,
      path,
      address(this),
      block.timestamp
    );

    uint256 amountBNB = address(this).balance - balanceBefore;
    uint256 totalBNBShares = totalShares - liquidityShare / 2;

    uint256 amountBNBLiquidity = amountBNB * liquidityShare / totalBNBShares / 2;
    uint256 amountBNBMarketing = amountBNB * marketingShare / totalBNBShares;
    uint256 amountBNBRewards = amountBNB * rewardShare / totalBNBShares;

    (bool marketingSuccess,) = payable(marketingWallet).call{value: amountBNBMarketing, gas: transferGas}("");
    if (marketingSuccess) { emit DepositMarketing(marketingWallet, amountBNBMarketing); }
    (bool rewardSuccess,) = payable(rewardWallet).call{value: amountBNBRewards, gas: transferGas}("");
    if (rewardSuccess) { emit DepositRewards(rewardWallet, amountBNBRewards); }

    if (liquidityTokens > 0) {
      ROUTER.addLiquidityETH{value: amountBNBLiquidity}(
        address(this),
        liquidityTokens,
        0,
        0,
        address(this),
        block.timestamp
      );

      emit AutoLiquidity(amountBNBLiquidity, liquidityTokens);
    }
  }

  // Owner

  function disableDumpProtection() external onlyOwner {
    dumpProtectionEnabled = false;
    emit DisableDumpProtection();
  }

  function removeSniperTax() external onlyOwner {
    sniperTax = false;
  }

  function enableTrading() external onlyOwner {
    tradingEnabled = true;
    launchTime = block.timestamp;
    emit EnableTrading();
  }

  function triggerSwapBack() external onlyOwner {
    _swapBack();
    emit TriggerSwapBack();
  }

  function recoverBNB() external onlyOwner {
    uint256 amount = address(this).balance;
    (bool sent,) = payable(marketingWallet).call{value: amount, gas: transferGas}("");
    require(sent, "Tx failed");
    emit RecoverBNB(amount);
  }

  function recoverBEP20(IBEP20 token, address recipient) external onlyOwner {
    require(address(token) != address(this), "Can't withdraw Step");
    uint256 amount = token.balanceOf(address(this));
    token.transfer(recipient, amount);
    emit RecoverBEP20(address(token), amount);
  }

  function setIsWhitelisted(address account, bool value) external onlyOwner {
    isWhitelisted[account] = value;
    emit SetWhitelisted(account, value);
  }

  function setIsCEX(address account, bool value) external onlyOwner {
    isCEX[account] = value;
    emit SetCEX(account, value);
  }

  function setIsMarketMaker(address account, bool value) external onlyOwner {
    require(account != pair, "Can't modify pair");
    isMarketMaker[account] = value;
    emit SetMarketMaker(account, value);
  }

  function setTaxes(uint256 newBuyTax, uint256 newSellTax, uint256 newTransferTax) external onlyOwner {
    require(newBuyTax <= 1500 && newSellTax <= 1500 && newTransferTax <= 1500, "Too high taxes");
    buyTax = newBuyTax;
    sellTax = newSellTax;
    transferTax = newTransferTax;
    emit SetTaxes(buyTax, sellTax, transferTax);
  }

  function setShares(uint256 newRewardShare, uint256 newLiquidityShare, uint256 newMarketingShare) external onlyOwner {
    rewardShare = newRewardShare;
    liquidityShare = newLiquidityShare;
    marketingShare = newMarketingShare;
    totalShares = rewardShare + liquidityShare + marketingShare;
    emit SetShares(rewardShare, liquidityShare, marketingShare);
  }

  function setSwapBackSettings(bool enabled, uint256 amount) external onlyOwner {
    uint256 tokenAmount = amount * 10**decimals();
    swapEnabled = enabled;
    swapThreshold = tokenAmount;
    emit SetSwapBackSettings(enabled, amount);
  }

  function setTransferGas(uint256 newGas) external onlyOwner {
    require(newGas >= 21000 && newGas <= 50000, "Invalid gas parameter");
    emit SetTransferGas(newGas, transferGas);
    transferGas = newGas;
  }

  function setMarketingWallet(address newWallet) external onlyOwner {
    require(newWallet != address(0), "New marketing wallet is the zero address");
    emit SetMarketingWallet(newWallet, marketingWallet);
    marketingWallet = newWallet;
  }

  function setRewardWallet(address newAddress) external onlyOwner {
    require(newAddress != address(0), "New reward pool is the zero address");
    emit SetRewardWallet(newAddress, rewardWallet);
    rewardWallet = newAddress;
  }
}
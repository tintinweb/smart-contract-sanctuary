/**
 *Submitted for verification at BscScan.com on 2021-10-18
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-18
*/

/**
oooooooooo.                                                  ooooooooo.                       oooo                      .   
`888'   `Y8b                                                 `888   `Y88.                     `888                    .o8   
 888     888 oooo  oooo  ooo. .oo.   ooo. .oo.   oooo    ooo  888   .d88'  .ooooo.   .ooooo.   888  oooo   .ooooo.  .o888oo 
 888oooo888' `888  `888  `888P"Y88b  `888P"Y88b   `88.  .8'   888ooo88P'  d88' `88b d88' `"Y8  888 .8P'   d88' `88b   888   
 888    `88b  888   888   888   888   888   888    `88..8'    888`88b.    888   888 888        888888.    888ooo888   888   
 888    .88P  888   888   888   888   888   888     `888'     888  `88b.  888   888 888   .o8  888 `88b.  888    .o   888 . 
o888bood8P'   `V88V"V8P' o888o o888o o888o o888o     .8'     o888o  o888o `Y8bod8P' `Y8bod8P' o888o o888o `Y8bod8P'   "888" 
                                                 .o..P'                                                                     
                                                 `Y8P'                                                                      
TG: https://t.me/BunnyRocketOfficials   
*/


// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

// File: contracts\SafeMath.sol
library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }
  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
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
  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }
}
// File: contracts\Auth.sol
/**
 * Allows for contract ownership along with multi-address authorization
 */
abstract contract Auth {
  address internal owner;
  mapping(address => bool) internal authorizations;
  constructor(address _owner) {
    owner = _owner;
    authorizations[_owner] = true;
  }
  /**
   * Function modifier to require caller to be contract owner
   */
  modifier onlyOwner() {
    require(isOwner(msg.sender), "!OWNER");
    _;
  }
  /**
   * Function modifier to require caller to be authorized
   */
  modifier authorized() {
    require(isAuthorized(msg.sender), "!AUTHORIZED");
    _;
  }
  /**
   * Authorize address. Owner only
   */
  function authorize(address adr) external onlyOwner {
    authorizations[adr] = true;
  }
  /**
   * Remove address' authorization. Owner only
   */
  function unauthorize(address adr) external onlyOwner {
    authorizations[adr] = false;
  }
  /**
   * Check if address is owner
   */
  function isOwner(address account) public view returns (bool) {
    return account == owner;
  }
  /**
   * Return address' authorization status
   */
  function isAuthorized(address adr) public view returns (bool) {
    return authorizations[adr];
  }
  /**
   * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
   */
  function transferOwnership(address payable adr) external onlyOwner {
    require(adr != address(0), "adr: zero address");
    owner = adr;
    authorizations[adr] = true;
    emit OwnershipTransferred(adr);
  }
  event OwnershipTransferred(address owner);
}
// File: contracts\IDEXFactory.sol
interface IDEXFactory {
  function createPair(address tokenA, address tokenB) external returns (address pair);
}
// File: contracts\IDEXRouter.sol
interface IDEXRouter {
  function factory() external pure returns (address);
  function WETH() external pure returns (address);
  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  )
    external
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    );
  function addLiquidityETH(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  )
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    );
  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;
  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable;
  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;
}
// File: contracts\IBEP20.sol
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
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
// File: contracts\BunnyRocketToken.sol
contract BunnyRocketToken is IBEP20, Auth {
  using SafeMath for uint256;
  address private constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
  address private constant DEAD = 0x000000000000000000000000000000000000dEaD;
  address private constant ZERO = 0x0000000000000000000000000000000000000000;
  string public constant NAME = "Bunny Rocket";
  string public constant SYMBOL = "BROCK";
  uint8 public constant DECIMALS = 18;
  uint256 public constant TOTAL_SUPPLY = 1_000_000_000 * 10**18; // 1Bn
  uint256 public maxTxAmount = (TOTAL_SUPPLY * 15) / 1000; // 1.5% of total supply
  //max wallet holding of 3%
  uint256 public maxWalletToken = (TOTAL_SUPPLY * 30) / 1000; // 3% of total supply
  mapping(address => uint256) private _balances;
  mapping(address => mapping(address => uint256)) private _allowances;
  mapping(address => bool) private isFeeExempt;
  mapping(address => bool) private isTxLimitExempt;
  mapping(address => bool) private isTimelockExempt;
  mapping(address => bool) private isDividendExempt;
  uint256 private liquidityFee = 3;
  uint256 private marketingFee = 3;
  uint256 private buyBackFee = 3;
  uint256 private totalFee = 9;
  uint256 private feeDenominator = 100;
  uint256 private buyLiquidityFee = 3;
  uint256 private buyMarketingFee = 3;
  uint256 private buyBuyBackFee = 3;
  uint256 private sellLiquidityFee = 3;
  uint256 private sellMarketingFee = 3;
  uint256 private sellBuyBackFee = 3;
  uint256 private banLiquidityFee = 50;
  uint256 private banMarketingFee = 45;
  uint256 private banBuyBackFee = 4;
  uint256 private banblock = 0;
  address private autoLiquidityReceiver;
  address private marketingReceiver;
  uint256 private targetLiquidity = 20;
  uint256 private targetLiquidityDenominator = 100;
  IDEXRouter public router;
  address public pair;
  bool public tradingOpen = false;
  // Cooldown & timer functionality
  bool public buyCooldownEnabled = false;
  uint8 public cooldownTimerInterval = 0;
  mapping(address => uint256) private cooldownTimer;
  bool public swapEnabled = true;
  uint256 public swapThreshold = (TOTAL_SUPPLY * 10) / 10000; // 0.01% of supply
  bool public buyBackEnabled = true;
  uint256 buyBackThreshold = 100e18; // 100 BNB
  uint256 public constant MAX_UINT256 =
    115792089237316195423570985008687907853269984665640564039457584007913129639935;
  bool private inSwap;
  modifier swapping() {
    inSwap = true;
    _;
    inSwap = false;
  }
  constructor() Auth(msg.sender) {
    isFeeExempt[msg.sender] = true;
    isTxLimitExempt[msg.sender] = true;
    // No timelock for these people
    isTimelockExempt[msg.sender] = true;
    isTimelockExempt[DEAD] = true;
    isTimelockExempt[address(this)] = true;
    isDividendExempt[pair] = true;
    isDividendExempt[address(this)] = true;
    isDividendExempt[DEAD] = true;
    router = IDEXRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
    _allowances[address(this)][address(router)] = MAX_UINT256;
    autoLiquidityReceiver = msg.sender;
    marketingReceiver = msg.sender;
    _balances[msg.sender] = TOTAL_SUPPLY;
    emit Transfer(address(0), msg.sender, TOTAL_SUPPLY);
    pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
  }
  receive() external payable {}
  function totalSupply() external pure override returns (uint256) {
    return TOTAL_SUPPLY;
  }
  function decimals() external pure override returns (uint8) {
    return DECIMALS;
  }
  function symbol() external pure override returns (string memory) {
    return SYMBOL;
  }
  function name() external pure override returns (string memory) {
    return NAME;
  }
  function getOwner() external view override returns (address) {
    return owner;
  }
  function balanceOf(address account) public view override returns (uint256) {
    return _balances[account];
  }
  function allowance(address holder, address spender) external view override returns (uint256) {
    return _allowances[holder][spender];
  }
  function approve(address spender, uint256 amount) public override returns (bool) {
    _allowances[msg.sender][spender] = amount;
    emit Approval(msg.sender, spender, amount);
    return true;
  }
  function approveMax(address spender) external returns (bool) {
    return approve(spender, MAX_UINT256);
  }
  function transfer(address recipient, uint256 amount) external override returns (bool) {
    return _transferFrom(msg.sender, recipient, amount);
  }
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external override returns (bool) {
    if (_allowances[sender][msg.sender] != MAX_UINT256) {
      _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(
        amount,
        "Insufficient Allowance"
      );
    }
    return _transferFrom(sender, recipient, amount);
  }
  //settting the maximum permitted wallet holding (percent of total supply)
  function setMaxWalletPercent(uint256 maxWallPercent_) external onlyOwner {
    maxWalletToken = (TOTAL_SUPPLY * maxWallPercent_) / 100;
  }
  function _transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) internal returns (bool) {
    if (inSwap) {
      return _basicTransfer(sender, recipient, amount);
    } else {
      if (!authorizations[sender] && !authorizations[recipient]) {
        require(tradingOpen, "Trading not open yet");
      }
      // max wallet & Tx code
      if (
        !authorizations[sender] &&
        recipient != address(this) &&
        recipient != address(DEAD) &&
        recipient != pair &&
        recipient != marketingReceiver &&
        recipient != autoLiquidityReceiver
      ) {
        uint256 heldTokens = balanceOf(recipient);
        require(
          (heldTokens + amount) <= maxWalletToken,
          "Total Holding is currently limited, you can not buy that much."
        );
      }
      require(amount <= maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
      // cooldown timer, so a bot doesnt do quick trades! 1min gap between 2 trades.
      if (sender == pair && buyCooldownEnabled && !isTimelockExempt[recipient]) {
        require(
          cooldownTimer[recipient] < block.timestamp,
          "Please wait for cooldown between buys"
        );
        cooldownTimer[recipient] = block.timestamp + cooldownTimerInterval;
      }
      //Exchange tokens
      _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
      uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, amount) : amount;
      _balances[recipient] = _balances[recipient].add(amountReceived);
      emit Transfer(sender, recipient, amountReceived);
      if (shouldBuyBack()) {
        buyBack();
      }
      // Liquidity, Maintained at 25%
      if (shouldSwapBack()) {
        swapBack();
      }
      return true;
    }
  }
  function _basicTransfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal returns (bool) {
    _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
    return true;
  }
  function shouldTakeFee(address sender) internal view returns (bool) {
    return !isFeeExempt[sender];
  }
  function takeFee(address sender, uint256 amount) internal returns (uint256) {
    if (block.number < banblock) {
      liquidityFee = banLiquidityFee;
      marketingFee = banMarketingFee;
      buyBackFee = banBuyBackFee;
    } else {
      if (sender == pair) {
        liquidityFee = buyLiquidityFee;
        marketingFee = buyMarketingFee;
        buyBackFee = buyBuyBackFee;
      } else {
        liquidityFee = sellLiquidityFee;
        marketingFee = sellMarketingFee;
        buyBackFee = sellBuyBackFee;
      }
    }
    totalFee = liquidityFee.add(marketingFee).add(buyBackFee);
    uint256 feeAmount = amount.mul(totalFee).div(feeDenominator);
    _balances[address(this)] = _balances[address(this)].add(feeAmount);
    emit Transfer(sender, address(this), feeAmount);
    return amount.sub(feeAmount);
  }
  function shouldSwapBack() internal view returns (bool) {
    return
      msg.sender != pair && !inSwap && swapEnabled && _balances[address(this)] >= swapThreshold;
  }
  function enableTrading(bool status_, uint256 banBlocks) external onlyOwner {
    require(!tradingOpen, "protect");
    tradingOpen = status_;
    // sniper/bot protection - remember to set pretty high fees during this blocks.
    banblock = block.number + banBlocks;
    emit TradingEnabled();
  }
  // enable cooldown between trades
  function cooldownEnabled(bool status_, uint8 interval_) external onlyOwner {
    buyCooldownEnabled = status_;
    cooldownTimerInterval = interval_;
  }
  function swapBack() internal swapping {
    uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator)
      ? 0
      : liquidityFee;
    uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(totalFee).div(2);
    uint256 amountToSwap = swapThreshold.sub(amountToLiquify);
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = WBNB;
    uint256 balanceBefore = address(this).balance;
    // swap token for ETH
    router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      amountToSwap,
      0,
      path,
      address(this),
      block.timestamp
    );
    uint256 amountBNB = address(this).balance.sub(balanceBefore);
    uint256 totalBNBFee = totalFee.sub(dynamicLiquidityFee.div(2));
    uint256 amountBNBLiquidity = amountBNB.mul(dynamicLiquidityFee).div(totalBNBFee).div(2);
    uint256 amountBNBMarketing = amountBNB.mul(marketingFee).div(totalBNBFee);
    uint256 amountBNBBuyBack = amountBNB.mul(buyBackFee).div(totalBNBFee);
    (bool txMarketingSuccess, ) = payable(marketingReceiver).call{
      value: amountBNBMarketing,
      gas: 30000
    }("");
    require(!txMarketingSuccess || txMarketingSuccess, "none"); // suppress warnings
    (bool txBuyBackSuccess, ) = payable(this).call{ value: amountBNBBuyBack, gas: 30000 }("");
    require(!txBuyBackSuccess || txBuyBackSuccess, "none"); // suppress warnings
    if (amountToLiquify > 0) {
      router.addLiquidityETH{ value: amountBNBLiquidity }(
        address(this),
        amountToLiquify,
        0,
        0,
        autoLiquidityReceiver,
        block.timestamp
      );
      emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
    }
  }
  function shouldBuyBack() private view returns (bool) {
    return buyBackEnabled && address(this).balance >= buyBackThreshold;
  }
  function manualBuyBack() external onlyOwner {
    if (address(this).balance > 0) buyBack();
  }
  function buyBack() private {
    address[] memory path = new address[](2);
    path[0] = WBNB;
    path[1] = address(this);
    uint256 amountBNB = address(this).balance;
    uint256 tokenBalanceBefore = balanceOf(address(this));
    router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: amountBNB }(
      0,
      path,
      address(this),
      block.timestamp
    );
    uint256 amountReceived = balanceOf(address(this)) - tokenBalanceBefore;
    emit BuyBack(amountBNB, amountReceived);
  }
  function setTxLimit(uint256 amount) external authorized {
    maxTxAmount = amount;
  }
  function setIsFeeExempt(address holder, bool exempt) external authorized {
    isFeeExempt[holder] = exempt;
  }
  function setIsTxLimitExempt(address holder, bool exempt) external authorized {
    isTxLimitExempt[holder] = exempt;
  }
  function setIsTimelockExempt(address holder, bool exempt) external authorized {
    isTimelockExempt[holder] = exempt;
  }
  function setSellFees(
    uint256 liquidityFee_,
    uint256 marketingFee_,
    uint256 buyBackFee_,
    uint256 feeDenominator_
  ) external authorized {
    liquidityFee = liquidityFee_;
    marketingFee = marketingFee_;
    buyBackFee = buyBackFee_;
    totalFee = liquidityFee.add(marketingFee).add(buyBackFee);
    sellLiquidityFee = liquidityFee_;
    sellMarketingFee = marketingFee_;
    sellBuyBackFee = buyBackFee_;
    feeDenominator = feeDenominator_;
    require(totalFee < feeDenominator / 4);
    emit SellFeesModified();
  }
  function setBuyFees(
    uint256 liquidityFee_,
    uint256 marketingFee_,
    uint256 buyBackFee_
  ) external authorized {
    buyLiquidityFee = liquidityFee_;
    buyMarketingFee = marketingFee_;
    buyBuyBackFee = buyBackFee_;
    emit BuyFeesModified();
  }
  function setBanFees(
    uint256 liquidityFee_,
    uint256 marketingFee_,
    uint256 buyBackFee_
  ) external authorized {
    banLiquidityFee = liquidityFee_;
    banMarketingFee = marketingFee_;
    banBuyBackFee = buyBackFee_;
    emit BanFeesModified();
  }
  function setFeeReceivers(address autoLiquidityReceiver_, address marketingReceiver_)
    external
    authorized
  {
    require(autoLiquidityReceiver_ != address(0), "autoLiquidityReceiver: zero address");
    require(marketingReceiver_ != address(0), "charityReceiver: zero address");
    autoLiquidityReceiver = autoLiquidityReceiver_;
    marketingReceiver = marketingReceiver_;
  }
  function setSwapBackSettings(bool enabled_, uint256 amount_) external authorized {
    swapEnabled = enabled_;
    swapThreshold = amount_;
    emit SwapBackSettingsModified();
  }
  function setBuyBackSettings(uint256 buyBackThreshold_, bool buyBackEnabled_) external onlyOwner {
    buyBackThreshold = buyBackThreshold_;
    buyBackEnabled = buyBackEnabled_;
    emit BuyBackSettingsModified();
  }
  function setTargetLiquidity(uint256 target_, uint256 denominator_) external authorized {
    targetLiquidity = target_;
    targetLiquidityDenominator = denominator_;
    emit TargetLiquidityModified();
  }
  function getCirculatingSupply() public view returns (uint256) {
    return TOTAL_SUPPLY.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
  }
  function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
    return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
  }
  function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
    return getLiquidityBacking(accuracy) > target;
  }
  event AutoLiquify(uint256 amountBNB, uint256 amountToLiquify);
  event SellFeesModified();
  event BuyFeesModified();
  event BanFeesModified();
  event SwapBackSettingsModified();
  event TargetLiquidityModified();
  event TradingEnabled();
  event BuyBackSettingsModified();
  event BuyBack(uint256 amountBNB, uint256 amountReceived);
}
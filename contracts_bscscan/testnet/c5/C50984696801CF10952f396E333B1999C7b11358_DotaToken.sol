//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./library/SafeMath.sol";
import "./utils/Ownable.sol";
import "./interface/IBEP20.sol";
import "./interface/IDEXRouter.sol";
import "./interface/IDEXFactory.sol";
import "./BNBDistributor.sol";

contract DotaToken is Context, IBEP20, Ownable {
  using SafeMath for uint256;

  // address DEX = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // Dex router address
  address DEX = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1; // Testnet
  // address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // WBNB address
  address WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd; // Testnet
  address DEAD = 0x000000000000000000000000000000000000dEaD;
  address ZERO = 0x0000000000000000000000000000000000000000;

  string constant _name = "DOTA2 NFT Token";
  string constant _symbol = "DOTA";
  uint8 constant _decimals = 18;

  uint256 _totalSupply = 10**(9 + _decimals); // 1 Billion

  mapping(address => uint256) _balances;
  mapping(address => mapping(address => uint256)) _allowances;

  mapping(address => bool) isFeeExempt;
  mapping(address => bool) isTxLimitExempt;
  mapping(address => bool) isDividendExempt;
  mapping(address => bool) isRestricted;

  uint256 bnbFee = 500;
  uint256 burnFee = 200;
  uint256 teamFee = 300;

  uint256 feeDenominator = 10000;

  address public teamWallet;

  IDEXRouter public router;
  address pancakeV2BNBPair;
  address[] public pairs;

  bool public swapEnabled = true;
  bool public feesOnNormalTransfers = true;

  BNBDistributor bnbDistributor;

  bool inSwap;
  modifier swapping() {
    inSwap = true;
    _;
    inSwap = false;
  }
  uint256 public swapThreshold = 10 * 10**_decimals;

  constructor() {
    address _owner = msg.sender;

    router = IDEXRouter(DEX);
    pancakeV2BNBPair = IDEXFactory(router.factory()).createPair(
      WBNB,
      address(this)
    );
    _allowances[address(this)][address(router)] = ~uint256(0);

    pairs.push(pancakeV2BNBPair);
    bnbDistributor = new BNBDistributor(WBNB, address(router), _totalSupply);

    isFeeExempt[_owner] = true;
    isFeeExempt[address(this)] = true;
    isFeeExempt[address(bnbDistributor)] = true;
    isDividendExempt[pancakeV2BNBPair] = true;
    isDividendExempt[address(this)] = true;
    isDividendExempt[DEAD] = true;
    isDividendExempt[ZERO] = true;
    isDividendExempt[address(bnbDistributor)] = true;
    isDividendExempt[_owner] = true;

    teamWallet = _owner;

    _balances[_owner] = _totalSupply;
    emit Transfer(address(0), _owner, _totalSupply);
  }

  function totalSupply() external view override returns (uint256) {
    return _totalSupply;
  }

  function decimals() external pure override returns (uint8) {
    return _decimals;
  }

  function symbol() external pure override returns (string memory) {
    return _symbol;
  }

  function name() external pure override returns (string memory) {
    return _name;
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

  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) private {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function approve(address spender, uint256 amount)
    public
    override
    returns (bool)
  {
    _approve(msg.sender, spender, amount);
    return true;
  }

  function approveMax(address spender) external returns (bool) {
    return approve(spender, ~uint256(0));
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
    if (_allowances[sender][msg.sender] != ~uint256(0)) {
      _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(
        amount,
        "Insufficient Allowance"
      );
    }

    return _transferFrom(sender, recipient, amount);
  }

  function _transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) internal returns (bool) {
    require(!isRestricted[recipient], "Address is restricted");

    if (inSwap) {
      return _basicTransfer(sender, recipient, amount);
    }

    if (shouldSwapBack()) {
      _swapBack();
    }

    require(_balances[sender].sub(amount) >= 0, "Insufficient Balance");
    _balances[sender] = _balances[sender].sub(amount);

    if (shouldTakeFee(sender, recipient)) {
      uint256 _bnbFee = amount.mul(bnbFee).div(feeDenominator);
      uint256 _burnFee = amount.mul(burnFee).div(feeDenominator);
      uint256 _teamFee = amount.mul(teamFee).div(feeDenominator);

      uint256 _totalFee = _bnbFee + _burnFee + _teamFee;
      uint256 amountReceived = amount - _totalFee;

      _balances[address(this)] = _balances[address(this)] + _bnbFee + _teamFee;

      _balances[DEAD] = _balances[DEAD].add(_burnFee);
      emit Transfer(sender, DEAD, _burnFee);

      _balances[recipient] = _balances[recipient].add(amountReceived);
      emit Transfer(sender, recipient, amountReceived);
    } else {
      _balances[recipient] = _balances[recipient].add(amount);
      emit Transfer(sender, recipient, amount);
    }

    if (!isDividendExempt[sender]) {
      try bnbDistributor.setShare(sender, _balances[sender]) {} catch {}
    }

    if (!isDividendExempt[recipient]) {
      try bnbDistributor.setShare(recipient, _balances[recipient]) {} catch {}
    }

    return true;
  }

  function _basicTransfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal returns (bool) {
    require(balanceOf(sender).sub(amount) >= 0, "Insufficient Balance");
    _balances[sender] = _balances[sender].sub(amount);
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
    return true;
  }

  function shouldTakeFee(address sender, address recipient)
    internal
    view
    returns (bool)
  {
    if (isFeeExempt[sender] || isFeeExempt[recipient]) return false;

    address[] memory liqPairs = pairs;

    for (uint256 i = 0; i < liqPairs.length; i++) {
      if (sender == liqPairs[i] || recipient == liqPairs[i]) return true;
    }

    return feesOnNormalTransfers;
  }

  function shouldSwapBack() internal view returns (bool) {
    return
      msg.sender != pancakeV2BNBPair &&
      !inSwap &&
      swapEnabled &&
      _balances[address(this)] >= swapThreshold;
  }

  function swapBack() external onlyOwner {
    _swapBack();
  }

  function _swapBack() internal swapping {
    uint256 balanceBefore = address(this).balance;

    uint256 amountToSwap = _balances[address(this)];

    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = router.WETH();

    _approve(address(this), address(router), amountToSwap);
    router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      amountToSwap,
      0,
      path,
      address(this),
      block.timestamp
    );

    uint256 swapedBNBAmount = address(this).balance.sub(balanceBefore);

    if (swapedBNBAmount > 0) {
      uint256 bnbDenom = bnbFee + teamFee;

      uint256 teamAmount = swapedBNBAmount.mul(teamFee).div(bnbDenom);
      payable(teamWallet).transfer(teamAmount);

      uint256 refAmount = swapedBNBAmount.mul(bnbFee).div(bnbDenom);
      payable(bnbDistributor).transfer(refAmount);
      bnbDistributor.deposit(refAmount);
    }
  }

  function BNBbalance() external view returns (uint256) {
    return address(this).balance;
  }

  function BNBRewardbalance() external view returns (uint256) {
    return address(bnbDistributor).balance;
  }

  function setIsDividendExempt(address holder, bool exempt) external onlyOwner {
    require(holder != address(this) && holder != pancakeV2BNBPair);
    isDividendExempt[holder] = exempt;
    if (exempt) {
      bnbDistributor.setShare(holder, 0);
    } else {
      bnbDistributor.setShare(holder, _balances[holder]);
    }
  }

  function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
    isFeeExempt[holder] = exempt;
  }

  function setFees(
    uint256 _bnbFee,
    uint256 _burnFee,
    uint256 _teamFee
  ) external onlyOwner {
    bnbFee = _bnbFee;
    burnFee = _burnFee;
    teamFee = _teamFee;
  }

  function setSwapThreshold(uint256 threshold) external onlyOwner {
    swapThreshold = threshold;
  }

  function setSwapEnabled(bool _enabled) external onlyOwner {
    swapEnabled = _enabled;
  }

  function setTeamWallet(address _team) external onlyOwner {
    teamWallet = _team;

    isDividendExempt[_team] = true;
    isFeeExempt[_team] = true;
  }

  function getCirculatingSupply() external view returns (uint256) {
    return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
  }

  function getClaimableBNB() external view returns (uint256) {
    return bnbDistributor.currentRewards(msg.sender);
  }

  function getWalletClaimableBNB(address _addr)
    external
    view
    returns (uint256)
  {
    return bnbDistributor.currentRewards(_addr);
  }

  function getWalletShareAmount(address _addr) external view returns (uint256) {
    return bnbDistributor.getWalletShare(_addr);
  }

  function claim() external {
    bnbDistributor.claimDividend(msg.sender);
  }

  function addPair(address pair) external onlyOwner {
    pairs.push(pair);
  }

  function removeLastPair() external onlyOwner {
    pairs.pop();
  }

  function setFeesOnNormalTransfers(bool _enabled) external onlyOwner {
    feesOnNormalTransfers = _enabled;
  }

  function setisRestricted(address adr, bool restricted) external onlyOwner {
    isRestricted[adr] = restricted;
  }

  function walletIsDividendExempt(address adr) external view returns (bool) {
    return isDividendExempt[adr];
  }

  function walletIsTaxExempt(address adr) external view returns (bool) {
    return isFeeExempt[adr];
  }

  function walletisRestricted(address adr) external view returns (bool) {
    return isRestricted[adr];
  }

  function withdrawTokens(address tokenaddr) external onlyOwner {
    require(
      tokenaddr != address(this),
      "This is for tokens sent to the contract by mistake"
    );
    uint256 tokenBal = IBEP20(tokenaddr).balanceOf(address(this));
    if (tokenBal > 0) {
      IBEP20(tokenaddr).transfer(teamWallet, tokenBal);
    }
  }

  receive() external payable {}
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * Standard SafeMath, stripped down to just add/sub/mul/div
 */
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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";

abstract contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    _setOwner(_msgSender());
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view virtual returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(owner() == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public virtual onlyOwner {
    _setOwner(address(0));
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * BEP20 standard interface.
 */
interface IBEP20 {
  function totalSupply() external view returns (uint256);

  function decimals() external view returns (uint8);

  function symbol() external view returns (string memory);

  function name() external view returns (string memory);

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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IDEXFactory {
  function createPair(address tokenA, address tokenB)
    external
    returns (address pair);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./interface/IDividendDistributor.sol";
import "./interface/IDEXRouter.sol";
import "./library/SafeMath.sol";

contract BNBDistributor is IDividendDistributor {
  using SafeMath for uint256;

  address _token;

  struct Share {
    uint256 amount;
    uint256 totalExcluded;
    uint256 totalRealised;
  }

  address WBNB;
  IDEXRouter router;

  mapping(address => uint256) _shareAmount;
  mapping(address => uint256) _shareEntry;
  mapping(address => uint256) _accured;
  uint256 _totalShared;
  uint256 _totalReward;
  uint256 _totalAccured;
  uint256 _stakingMagnitude;

  uint256 minAmount = 0;

  modifier onlyToken() {
    require(msg.sender == _token);
    _;
  }

  constructor(
    address _wbnb,
    address _router,
    uint256 _totalSupply
  ) {
    WBNB = _wbnb;
    router = IDEXRouter(_router);
    _token = msg.sender;
    _stakingMagnitude = _totalSupply;
  }

  function setShare(address shareholder, uint256 amount)
    external
    override
    onlyToken
  {
    if (_shareAmount[shareholder] > 0) {
      _accured[shareholder] = currentRewards(shareholder);
    }

    _totalShared = _totalShared.sub(_shareAmount[shareholder]).add(amount);
    _shareAmount[shareholder] = amount;

    _shareEntry[shareholder] = _totalAccured;
  }

  function getWalletShare(address shareholder) public view returns (uint256) {
    return _shareAmount[shareholder];
  }

  function deposit(uint256 amount) external override onlyToken {
    _totalReward = _totalReward + amount;
    _totalAccured = _totalAccured + (amount * _stakingMagnitude) / _totalShared;
  }

  function distributeDividend(address shareholder, address receiver) internal {
    if (_shareAmount[shareholder] == 0) {
      return;
    }

    _accured[shareholder] = currentRewards(shareholder);
    require(
      _accured[shareholder] > minAmount,
      "Reward amount has to be more than minimum amount"
    );

    payable(receiver).transfer(_accured[shareholder]);
    _totalReward = _totalReward - _accured[shareholder];
    _accured[shareholder] = _accured[shareholder] - _accured[shareholder];

    _shareEntry[shareholder] = _totalAccured;
  }

  function claimDividend(address shareholder) external override onlyToken {
    uint256 amount = currentRewards(shareholder);
    if (amount == 0) {
      return;
    }

    distributeDividend(shareholder, shareholder);
  }

  function _calculateReward(address addy) private view returns (uint256) {
    return
      (_shareAmount[addy] * (_totalAccured - _shareEntry[addy])) /
      _stakingMagnitude;
  }

  function currentRewards(address addy) public view returns (uint256) {
    uint256 totalRewards = address(this).balance;

    uint256 calcReward = _accured[addy] + _calculateReward(addy);

    // Fail safe to ensure rewards are never more than the contract holding.
    if (calcReward > totalRewards) {
      return totalRewards;
    }

    return calcReward;
  }

  receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IDividendDistributor {
  function setShare(address shareholder, uint256 amount) external;

  function deposit(uint256 amount) external;

  function claimDividend(address shareholder) external;
}
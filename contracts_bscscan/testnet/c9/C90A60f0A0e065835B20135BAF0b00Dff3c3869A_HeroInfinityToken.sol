//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interface/IBEP20.sol";
import "./interface/IDEXRouter.sol";
import "./interface/IDEXFactory.sol";
import "./WBNBDistributor.sol";

contract HeroInfinityToken is Context, IBEP20, Ownable {
  using SafeMath for uint256;

  // address DEX = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // Dex router address
  address public dexAddress = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1; // Testnet
  // address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // WBNB address
  address public wbnbAddress = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd; // Testnet
  address public deadAddress = 0x000000000000000000000000000000000000dEaD;
  address public zeroAddress = 0x0000000000000000000000000000000000000000;

  string private constant NAME = "Hero Infinity Token";
  string private constant SYMBOL = "HRI";
  uint8 private constant DECIMALS = 18;

  uint256 private constant TOTAL_SUPPLY = 10**(9 + DECIMALS); // 1 Billion

  mapping(address => uint256) private _balances;
  mapping(address => mapping(address => uint256)) private _allowances;

  mapping(address => bool) public isFeeExempt;
  mapping(address => bool) public isTxLimitExempt;
  mapping(address => bool) public isDividendExempt;
  mapping(address => bool) public isRestricted;

  uint256 public wbnbFee = 500;
  uint256 public burnFee = 200;
  uint256 public teamFee = 300;

  uint256 public feeDenominator = 10000;

  address public teamWallet;

  IDEXRouter public router;
  address public pancakeV2WBNBPair;
  address[] public pairs;

  bool public swapEnabled = true;
  bool public feesOnNormalTransfers = true;

  WBNBDistributor private wbnbDistributor;

  bool private inSwap;
  modifier swapping() {
    inSwap = true;
    _;
    inSwap = false;
  }
  uint256 public swapThreshold = 10 * 10**DECIMALS;

  constructor() {
    address _owner = msg.sender;

    router = IDEXRouter(dexAddress);
    pancakeV2WBNBPair = IDEXFactory(router.factory()).createPair(
      wbnbAddress,
      address(this)
    );
    _allowances[address(this)][address(router)] = ~uint256(0);

    pairs.push(pancakeV2WBNBPair);
    wbnbDistributor = new WBNBDistributor(
      wbnbAddress,
      address(router),
      TOTAL_SUPPLY
    );

    isFeeExempt[_owner] = true;
    isFeeExempt[address(this)] = true;
    isFeeExempt[address(wbnbDistributor)] = true;
    isDividendExempt[pancakeV2WBNBPair] = true;
    isDividendExempt[address(this)] = true;
    isDividendExempt[deadAddress] = true;
    isDividendExempt[zeroAddress] = true;
    isDividendExempt[address(wbnbDistributor)] = true;
    isDividendExempt[_owner] = true;

    teamWallet = _owner;

    _balances[_owner] = TOTAL_SUPPLY;
    emit Transfer(address(0), _owner, TOTAL_SUPPLY);
  }

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
      uint256 _bnbFee = amount.mul(wbnbFee).div(feeDenominator);
      uint256 _burnFee = amount.mul(burnFee).div(feeDenominator);
      uint256 _teamFee = amount.mul(teamFee).div(feeDenominator);

      uint256 _totalFee = _bnbFee + _burnFee + _teamFee;
      uint256 amountReceived = amount - _totalFee;

      _balances[address(this)] = _balances[address(this)] + _bnbFee + _teamFee;

      _balances[deadAddress] = _balances[deadAddress].add(_burnFee);
      emit Transfer(sender, deadAddress, _burnFee);

      _balances[recipient] = _balances[recipient].add(amountReceived);
      emit Transfer(sender, recipient, amountReceived);
    } else {
      _balances[recipient] = _balances[recipient].add(amount);
      emit Transfer(sender, recipient, amount);
    }

    if (!isDividendExempt[sender]) {
      try wbnbDistributor.setShare(sender, _balances[sender]) {} catch {}
    }

    if (!isDividendExempt[recipient]) {
      try wbnbDistributor.setShare(recipient, _balances[recipient]) {} catch {}
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
      msg.sender != pancakeV2WBNBPair &&
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
      uint256 bnbDenom = wbnbFee + teamFee;

      uint256 teamAmount = swapedBNBAmount.mul(teamFee).div(bnbDenom);
      payable(teamWallet).transfer(teamAmount);

      uint256 refAmount = swapedBNBAmount.mul(wbnbFee).div(bnbDenom);
      payable(wbnbDistributor).transfer(refAmount);
      wbnbDistributor.deposit(refAmount);
    }
  }

  function wbnbBalance() external view returns (uint256) {
    return address(this).balance;
  }

  function wbnbRewardbalance() external view returns (uint256) {
    return address(wbnbDistributor).balance;
  }

  function setIsDividendExempt(address holder, bool exempt) external onlyOwner {
    require(
      holder != address(this) && holder != pancakeV2WBNBPair,
      "Not allowed holder"
    );
    isDividendExempt[holder] = exempt;
    if (exempt) {
      wbnbDistributor.setShare(holder, 0);
    } else {
      wbnbDistributor.setShare(holder, _balances[holder]);
    }
  }

  function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
    isFeeExempt[holder] = exempt;
  }

  function setFees(
    uint256 _wbnbFee,
    uint256 _burnFee,
    uint256 _teamFee
  ) external onlyOwner {
    wbnbFee = _wbnbFee;
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
    return TOTAL_SUPPLY.sub(balanceOf(deadAddress)).sub(balanceOf(zeroAddress));
  }

  function getClaimableWBNB() external view returns (uint256) {
    return wbnbDistributor.currentRewards(msg.sender);
  }

  function getWalletClaimableWBNB(address _addr)
    external
    view
    returns (uint256)
  {
    return wbnbDistributor.currentRewards(_addr);
  }

  function getWalletShareAmount(address _addr) external view returns (uint256) {
    return wbnbDistributor.getWalletShare(_addr);
  }

  function claim() external {
    wbnbDistributor.claimDividend(msg.sender);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interface/IDividendDistributor.sol";
import "./interface/IDEXRouter.sol";

contract WBNBDistributor is IDividendDistributor, ReentrancyGuard {
  using SafeMath for uint256;

  address private _token;

  struct Share {
    uint256 amount;
    uint256 totalExcluded;
    uint256 totalRealised;
  }

  address private wbnb;
  IDEXRouter private router;

  mapping(address => uint256) private _shareAmount;
  mapping(address => uint256) private _shareEntry;
  mapping(address => uint256) private _accured;
  uint256 private _totalShared;
  uint256 private _totalReward;
  uint256 private _totalAccured;
  uint256 private _stakingMagnitude;

  uint256 private minAmount = 0;

  modifier onlyToken() {
    require(msg.sender == _token, "Caller must be token");
    _;
  }

  constructor(
    address _wbnb,
    address _router,
    uint256 _totalSupply
  ) {
    wbnb = _wbnb;
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

  function distributeDividend(address shareholder, address receiver)
    internal
    nonReentrant
  {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IDividendDistributor {
  function setShare(address shareholder, uint256 amount) external;

  function deposit(uint256 amount) external;

  function claimDividend(address shareholder) external;
}
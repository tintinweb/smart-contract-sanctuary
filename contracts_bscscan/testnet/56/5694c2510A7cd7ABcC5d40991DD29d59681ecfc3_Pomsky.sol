/**
 *Submitted for verification at BscScan.com on 2021-07-20
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

/*
 * Contract Context, contract Ownable, library Address, and interface IERC20Metadata
 * are copied from openzeppelin just to get everything into a single file.
 * Unfortunately this is required by the BSC validator. The multifile validator doesn't work yet.
 */

/*
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
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

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
  constructor () {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
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
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
  /**
   * @dev Returns the name of the token.
   */
  function name() external view returns (string memory);

  /**
   * @dev Returns the symbol of the token.
   */
  function symbol() external view returns (string memory);

  /**
   * @dev Returns the decimals places of the token.
   */
  function decimals() external view returns (uint8);
}

/*
 *  Uniswap (Pancakeswap) interface definitions
 */

interface IUniswapV2Router01 {
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

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETH(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountToken, uint256 amountETH);

  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETHWithPermit(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountToken, uint256 amountETH);

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapTokensForExactETH(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapETHForExactTokens(
    uint256 amountOut,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) external pure returns (uint256 amountB);

  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountOut);

  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountIn);

  function getAmountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);

  function getAmountsIn(uint256 amountOut, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountETH);

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountETH);

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

interface IUniswapV2Factory {
  event PairCreated(
    address indexed token0,
    address indexed token1,
    address pair,
    uint256
  );

  function feeTo() external view returns (address);

  function feeToSetter() external view returns (address);

  function getPair(address tokenA, address tokenB)
    external
    view
    returns (address pair);

  function allPairs(uint256) external view returns (address pair);

  function allPairsLength() external view returns (uint256);

  function createPair(address tokenA, address tokenB)
    external
    returns (address pair);

  function setFeeTo(address) external;

  function setFeeToSetter(address) external;
}

/*
 *  Pomsky token
 */

abstract contract PomskyMetaData is IERC20Metadata {

  /// @dev The name of the token managed by this smart contract.
  string constant private _name = "Pomsky";

  /// @dev The symbol of the token managed by this smart contract.
  string constant private _symbol = "POM";

  /// @dev The decimals of the token managed by this smart contract.
  uint8 constant private _decimals = 18;

  /// @return The name of the token.
  function name() public pure override returns (string memory) {
    return _name;
  }

  /// @return The symbol of the token.
  function symbol() public pure override returns (string memory) {
    return _symbol;
  }

  /// @return The decimals of the token.
  function decimals() public pure override returns (uint8) {
    return _decimals;
  }
}

contract Pomsky is Ownable, PomskyMetaData {

  /// @dev address of pancakeswap router 02 on BSC
  address private constant _pancakeswapRouterAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;

  /// @dev Event signaling that 'tokens' tokens and 'wbnb' WBNB
  /// have been added to the liquidity pool, obtaining 'liquidity' Cake-LP.
  event AddedLiquidity(
    uint256 tokens,
    uint256 wbnb,
    uint256 liquidity
  );

  /// @dev Event signalling that some tokens were destroyed.
  event Burned(uint256 amount);

  /// @dev Event signalling that `account` was blacklisted (blacklisted == true) or
  /// removed from the list (blacklisted == false).
  event Blacklisted(address account, bool blacklisted);

  /// @dev Event signalling that the max transfer limit was set to `amount`.
  event MaxTransferLimit(uint256 amount);

  /// @dev Event signalling whether whale catching is enabled or not.
  event WhaleCatching(bool enabled);

  /// @dev Event signalling that `account` was exempted or not from: fees, transaction limit, whale catching.
  event Exempted(address account, bool exempted);

  /// @dev Event signalling that `account` was added as exchange (added == true) or
  /// removed from the list of exchanges (added == false).
  event Exchange(address account, bool added);

  /// @dev the maximum uint256 value in solidity, which is used to convert the total supply of tokens to reflections.
  uint256 private constant MAX_INT_VALUE = type(uint256).max;

  /// @dev The current amount of tokens.
  uint256 private _tokenSupply = 10**15 * 10**18;

  /// @dev Convert the total supply to reflections with perfect rounding using the maximum uint256 as the numerator.
  uint256 private _reflectionSupply = (MAX_INT_VALUE - (MAX_INT_VALUE % _tokenSupply));

  /// @dev the amount of fees collected ever
  uint256 private _totalTokenFees;

  /// @dev the amount of sales fees that have not yet been converted to BNB
  uint256 private _accruedPunishmentTax;
// whichi is 
  // Transaction fees. In 1/1000.
  uint8 public charityFundFeePerMill = 10; // donations
  uint8 public redistFundFeePerMill = 10; // buyback + manual burn
  uint8 public marketingFundFeePerMill = 20; // marketing + development
  uint8 public punishmentFundFeePerMill = 0; // extra fee for selling the token
  uint8 public autoLiquidityFeePerMill = 40; // automatic liquidity increment
  uint8 public autoRedistributionFeePerMill = 10; // by means of reflectiUons
  uint8 public autoBurnFeePerMill = 10; // automatic token burning

  /// @dev The wallet which holds the account balance in reflections.
  mapping(address => uint256) private _reflectionBalance;

  /// @dev Accounts that are excluded from fee paying, from transaction limit, and from whale catching.
  mapping(address => bool) private _isExempted;

  /// @dev Addresses that are excluded from transactions.
  mapping(address => bool) private _blacklisted;

  /// @dev Allowances: mapping owner -> (spender, amount)
  mapping(address => mapping(address => uint256)) private _allowances;

  /// @dev Addresses that pertain to exchanges.
  /// Used to detect whether a transaction is a sale or not.
  mapping(address => bool) private _exchange;

  /// @dev At most 0.15% of the initial total supply may be transfered at once.
  uint256 public maxTransferAmount = 15 * 10**11 * 10**18;

  /// @dev While isWhaleCatchingEnabled, the max amount of tokens allowed
  /// on any transfer destination address is 0.5% of the initial total supply.
  uint256 public whaleCatchingLimit = 5 * 10**12 * 10**18;

  /// @dev state - whether trading is enabled or not
  bool public isTradingEnabled =  true;

  /// @dev state - whether whale catching is enabled or not
  bool public isWhaleCatchingEnabled = false;

  /// @dev Addresses used for swapping. The router is actually the Pancakeswap router 02.
  IUniswapV2Router02 public uniswapV2Router;
  address public uniswapV2WETHPair;

  /// @dev Address used to collect BNB for donations.
  address payable private immutable _charityFund;

  /// @dev Address used to collect BNB for redistributions (buyback + burn).
  address payable private immutable _redistFund;

  /// @dev Address used to collect BNB for marketing+development.
  address payable private immutable _marketingFund;

  /// @dev Address used to collect BNB from token selling.
  address payable private immutable _punishmentFund;

  /// @dev Address to store Cake-LP tokens.
  address payable private immutable _liquidityTokenAddress;

  /// @dev What user action is calling transfer()?
  /// BuyViaPcs: buying tokens on PancakeSwap
  /// Sale: selling tokens
  /// Other: simple transfer, ...
  enum TransferType {BuyViaPcs, Sale, Other}

  constructor(
    address payable charityFundAddress,
    address payable redistFundAddress,
    address payable marketingFundAddress,
    address payable punishmentFundAddress,
    address payable liquidityTokenAddr
  ) {
    // Gives all the reflection to the deployer (the first owner) of the contract upon creation.
    _reflectionBalance[_msgSender()] = _reflectionSupply;

    setPancakeSwapRouter(_pancakeswapRouterAddress);

    _charityFund = charityFundAddress;
    _redistFund = redistFundAddress;
    _marketingFund = marketingFundAddress;
    _punishmentFund = punishmentFundAddress;
    _liquidityTokenAddress = liquidityTokenAddr;

    _isExempted[owner()] = true;
    _isExempted[address(this)] = true;
    _isExempted[charityFundAddress] = true;
    _isExempted[redistFundAddress] = true;
    _isExempted[marketingFundAddress] = true;
    _isExempted[punishmentFundAddress] = true;
    _isExempted[liquidityTokenAddr] = true;

    emit Transfer(address(0), _msgSender(), _tokenSupply);
  }

  /// @return the total current supply of tokens
  function totalSupply() external view override returns (uint256) {
    return _tokenSupply;
  }

  /// @return the rate between the total reflections and total tokens
  function _getRate() private view returns (uint256) {
    return _reflectionSupply / _tokenSupply;
  }

  /// @return amount of reflections equal to `amount` tokens
  function _reflectionFromToken(uint256 amount)
    private
    view
    returns (uint256)
  {
    require(
      _tokenSupply >= amount,
      "You cannot own more tokens than the total token supply"
    );
    return amount * _getRate();
  }

  /// @return amount of tokens equal to `reflectionAmount` reflections
  function _tokenFromReflection(uint256 reflectionAmount)
    private
    view
    returns (uint256)
  {
    require(
      _reflectionSupply >= reflectionAmount,
      "Cannot have a personal reflection amount larger than total reflection"
    );
    return reflectionAmount / _getRate();
  }

  /// @notice Get the total amount of tokens at `account`.
  function balanceOf(address account) public view override returns (uint256) {
    return _tokenFromReflection(_reflectionBalance[account]);
  }

  /// @notice Get the amount of fees collected ever.
  function totalFeesCollected() external view onlyOwner returns (uint256) {
    return _totalTokenFees;
  }

  /// @dev Allow this contract to receive BNB. Will only receive BNB from uniswapv2router while swapping.
  receive() external payable {}

  /// @dev send BNB without raising exception on failure
  function _sendBnb(address payable to, uint256 wbnbAmount) private returns(bool)
  {
    if (wbnbAmount == 0)
      return true;
    (bool success, ) = to.call{value: wbnbAmount}("");
    return success;
  }

  /// @dev Try to add all BNB and tokens at address(this) to liquidity.
  function _addRemainingBnbAndTokensToLiquidity() private {
    uint256 bnbForLiquidity = address(this).balance;
    uint256 tokensForLiquidity = _tokenFromReflection(_reflectionBalance[address(this)]);
    if ((bnbForLiquidity > 0) && (tokensForLiquidity > 0)) {
      uint256 actualToken;
      uint256 actualBnb;
      uint256 liquidity;
      (actualToken, actualBnb, liquidity) = _addLiquidity(tokensForLiquidity, bnbForLiquidity);
      emit AddedLiquidity(actualToken, actualBnb, liquidity);
    }
  }

  /// Because of slippage the value of BNB and tokens may be not equal.
  /// When adding them to liquidity, some BNB or tokens may be left over.
  /// Prevent infinite accrual of left over BNB.
  function _cleanLeftOverBnb() private {
    // do not transfer every tiny bit of BNB, transfer only after 1 BNB has been accrued
    if (address(this).balance > 10 ** 18) { // 1 BNB
      _sendBnb(_liquidityTokenAddress, address(this).balance);
    }
  }

  /// @dev For a transfer volume of `amount` tokens calculate and process taxes.
  function _deductTaxes(uint256 amount, TransferType kindOfTransfer) private returns(uint256 totalTax) {
    // Calculate transaction fees.
    uint256 charityTax = (amount * charityFundFeePerMill) / 1000;
    uint256 redistTax = (amount * redistFundFeePerMill) / 1000;
    uint256 marketingTax = (amount * marketingFundFeePerMill) / 1000;
    uint256 autoLiquidityTax = (amount * autoLiquidityFeePerMill) / 1000;
    uint256 autoRedistTax = (amount * autoRedistributionFeePerMill) / 1000;
    uint256 autoBurnTax = (amount * autoBurnFeePerMill) / 1000;
    uint256 punishmentTax = (kindOfTransfer == TransferType.Sale)? (amount * punishmentFundFeePerMill) / 1000 : 0;
    totalTax =
      charityTax +
      redistTax +
      marketingTax +
      punishmentTax +
      autoLiquidityTax +
      autoRedistTax +
      autoBurnTax;

    _accruedPunishmentTax += punishmentTax;

    // Reduce the reflection supply to reward all holders and burn some tokens.
    _reflectionSupply -= _reflectionFromToken(autoRedistTax + autoBurnTax);
    _tokenSupply -= autoBurnTax;
    emit Burned(autoBurnTax);

    _totalTokenFees += totalTax;

    // Store the remaining fees in the contract's address to swap them.
    _reflectionBalance[address(this)] =
      _reflectionBalance[address(this)] +
      _reflectionFromToken(charityTax + redistTax + marketingTax + punishmentTax + autoLiquidityTax);

    // In case we are called by PancakeSwap because someone is buying our token,
    // we may not sell tokens on PancakeSwap now. Keep the tokens on this contract's
    // address until another transfer() invocation will convert the tokens.
    if (kindOfTransfer != TransferType.BuyViaPcs) {
      // From previous transfers fees may have been accrued on the contract's address.
      // Now use all those tokens.
      uint256 accruedTax = _tokenFromReflection(_reflectionBalance[address(this)]);

      // This condition should always be true; just being paranoid ...
      if (accruedTax > _accruedPunishmentTax) {
        // Distribute taxes according to the tax rates. The sales tax is not
        // charged for every transfer for which the other taxes are charged, so
        // the sales tax is tracked using attribute _accruedPunishmentTax.
        accruedTax -= _accruedPunishmentTax;
        uint256 feeRateSum = charityFundFeePerMill + redistFundFeePerMill + marketingFundFeePerMill + autoLiquidityFeePerMill;
        charityTax = (accruedTax * charityFundFeePerMill) / feeRateSum;
        redistTax = (accruedTax * redistFundFeePerMill) / feeRateSum;
        marketingTax = (accruedTax * marketingFundFeePerMill) / feeRateSum;
        autoLiquidityTax = (accruedTax * autoLiquidityFeePerMill) / feeRateSum;
      } else {
        _accruedPunishmentTax = accruedTax;
        accruedTax = 0;
        charityTax = 0;
        redistTax = 0;
        marketingTax = 0;
        autoLiquidityTax = 0;
      }

      // Swap to BNB. Half of the autoLiquidityTax will be used for pairing.
      uint256 tokensToSwap = charityTax + redistTax + marketingTax + _accruedPunishmentTax + autoLiquidityTax / 2;
      if (tokensToSwap > 0) {
        uint256 swappedBnb = _swapTokensForWbnb(tokensToSwap, address(this));

        // Transfer BNB to fund addresses.
        _sendBnb(_charityFund, swappedBnb * charityTax / tokensToSwap);
        _sendBnb(_redistFund, swappedBnb * redistTax / tokensToSwap);
        _sendBnb(_marketingFund, swappedBnb * marketingTax / tokensToSwap);
        _sendBnb(_punishmentFund, swappedBnb * _accruedPunishmentTax / tokensToSwap);
      }
      _accruedPunishmentTax = 0;
      _addRemainingBnbAndTokensToLiquidity();
    }
  }

  function getTransferType(address sender, address recipient) private view returns(TransferType kind) {
    if (sender == uniswapV2WETHPair) {
      kind = TransferType.BuyViaPcs;
    } else if (_exchange[recipient]) {
      kind = TransferType.Sale;
    } else {
      kind = TransferType.Other;
    }
  }

  /// @dev Transfer tokens from `sender` to `recipient`. The recipient is taxed, if noFees == false.
  function _transferToken(
    address sender,
    address recipient,
    uint256 amount,
    bool noFees
  ) private {

    uint256 rAmount = _reflectionFromToken(amount);

    // Catch whales.
    if (
      isWhaleCatchingEnabled &&
      sender != owner() &&
      recipient != owner() &&
      recipient != uniswapV2WETHPair &&
      !_isExempted[recipient] // i.e. the recipient is also excluded from whale catching
    ) {
      require(
        _tokenFromReflection(_reflectionBalance[recipient] + rAmount) <= whaleCatchingLimit,
        "No whales allowed right now :)"
      );
    }

    _reflectionBalance[sender] = _reflectionBalance[sender] - rAmount;

    uint256 totalTax = 0;
    uint256 rTotalTax = 0;
    if (!noFees) {
      totalTax = _deductTaxes(amount, getTransferType(sender, recipient));
      rTotalTax = _reflectionFromToken(totalTax);
      _cleanLeftOverBnb();
    }

    _reflectionBalance[recipient] = _reflectionBalance[recipient] + rAmount - rTotalTax;
    emit Transfer(sender, recipient, amount - totalTax);
  }

  /// @dev Buy WBNB with tokens stored at this contract's address.
  /// @return obtained BNB
  function _swapTokensForWbnb(uint256 tokenAmount, address to) private returns(uint256) {
    if (tokenAmount == 0)
      return 0;

    // Generate the pancakeswap pair path for swapping token -> WBNB.
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswapV2Router.WETH();

    // Allow the router to withdraw 'tokenAmount' tokens.
    _approve(address(this), address(uniswapV2Router), tokenAmount);

    uint256 balanceBeforeSwap = address(this).balance;

    // Make the swap.
    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount,
      0, // slippage is unavoidable
      path,
      to,
      block.timestamp // immediate buy
    );

    return address(this).balance - balanceBeforeSwap;
  }

  /// @dev Add WBNB and tokens to the liquidity pool.
  function _addLiquidity(uint256 tokenAmount, uint256 wbnbAmount)
    private
    returns(uint256 actualToken, uint256 actualBnb, uint256 liquidity)
  {
    // approve token transfer to cover all possible scenarios
    _approve(address(this), address(uniswapV2Router), tokenAmount);

    (actualToken, actualBnb, liquidity) = uniswapV2Router.addLiquidityETH{ value: wbnbAmount }(
      address(this),
      tokenAmount,
      0, // slippage is unavoidable
      0, // slippage is unavoidable
      _liquidityTokenAddress,
      block.timestamp // immediate buy
    );
  }

  /// @notice Allow transfers for everyone, except for blacklisted addresses.
  function enableTrading() external onlyOwner {
    isTradingEnabled = true;
  }

  /// @notice Allow only transfers from/to the contract owner's account.
  function disableTrading() external onlyOwner {
    isTradingEnabled = false;
  }

  /// @notice Allow holders to have more than 0.5% of initial token supply.
  function freeWhales() external onlyOwner {
    isWhaleCatchingEnabled = false;
    emit WhaleCatching(false);
  }

  /// @notice Holders may not have more than 0.5% of initial token supply.
  function catchWhales() external onlyOwner {
    isWhaleCatchingEnabled = true;
    emit WhaleCatching(true);
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) private {
    require(sender != address(0), "source must not be the zero address");
    require(recipient != address(0), "destination must not be the zero address");
    require(amount > 0, "transfer amount must be greater than zero");
    require(_blacklisted[sender] == false, "source address blacklisted");
    require(_blacklisted[recipient] == false, "destination address blacklisted");
    if (
         sender != owner()
      && recipient != owner()
      && !_isExempted[sender]
      && !_isExempted[recipient]
    ) {
      require(amount <= maxTransferAmount, "Transfer amount exceeds the maxTransferAmount.");
      require(isTradingEnabled, "Nice try :)");
    }

    _transferToken(
      sender,
      recipient,
      amount,
      _isExempted[sender] || _isExempted[recipient]
    );
  }

  /// @dev `owner` gives allowance to `beneficiary` for `amount` tokens.
  function _approve(
    address owner,
    address beneficiary,
    uint256 amount
  ) private {
    require(
      beneficiary != address(0),
      "The burn address is not allowed to receive approval for allowances."
    );
    require(
      owner != address(0),
      "The burn address is not allowed to approve allowances."
    );

    _allowances[owner][beneficiary] = amount;
    emit Approval(owner, beneficiary, amount);
  }

  /// @notice Transfer `amount` tokens from caller's account to `recipient`.
  function transfer(address recipient, uint256 amount)
    public
    override
    returns (bool)
  {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /// @notice Give `beneficiary` an allowance of `amount` tokens on the sender's account.
  function approve(address beneficiary, uint256 amount)
    public
    override
    returns (bool)
  {
    _approve(_msgSender(), beneficiary, amount);
    return true;
  }

  /// @notice Transfer `amount` tokens from `provider` to `beneficiary`, if sufficient allowance
  /// is given.
  function transferFrom(
    address provider,
    address beneficiary,
    uint256 amount
  ) public override returns (bool) {
    if (provider != _msgSender()) {
      require(_allowances[provider][_msgSender()] >= amount, "Insufficient allowance");

      // reduce allowance by withdrawed amount
      _approve(
        provider,
        _msgSender(),
        _allowances[provider][_msgSender()] - amount
      );
    }

    _transfer(provider, beneficiary, amount);
    return true;
  }

  /// @notice Show the allowance of `beneficiary` on tokens in `owner` account.
  function allowance(address owner, address beneficiary)
    public
    view
    override
    returns (uint256)
  {
    return _allowances[owner][beneficiary];
  }

  /// @notice Add `account` to blacklist, excluding it from future transfers.
  function addToBlacklist(address account) public onlyOwner returns (bool)
  {
    if (!_blacklisted[account]) {
      _blacklisted[account] = true;
      emit Blacklisted(account, true);
    }
    return true;
  }

  /// @notice Remove `account` from blacklist, allowing it to participate in transfers.
  function removeFromBlacklist(address account) public onlyOwner returns (bool)
  {
    if (_blacklisted[account]) {
      _blacklisted[account] = false;
      emit Blacklisted(account, false);
    }
    return true;
  }

  function isBlacklisted(address account) public view returns (bool)
  {
    return _blacklisted[account];
  }

  /// @notice Set fee structure. All fees in per mill (1/1000).
  /// The punishment tax for selling must not exceed 5%.
  /// The sum of all other taxes must not exceed 15%.
  function setFees(
    uint8 charityFee,
    uint8 redistFee,
    uint8 marketingFee,
    uint8 punishmentFee,
    uint8 autoLiquidityFee,
    uint8 autoRedistributionFee,
    uint8 autoBurnFee)
    public
    onlyOwner
    returns (bool)
  {
    require((charityFee + redistFee + marketingFee + autoLiquidityFee + autoRedistributionFee + autoBurnFee) <= 150, "overtaxation");
    require(punishmentFee <= 50, "overtaxation for selling");
    charityFundFeePerMill = charityFee;
    redistFundFeePerMill = redistFee;
    marketingFundFeePerMill = marketingFee;
    punishmentFundFeePerMill = punishmentFee;
    autoLiquidityFeePerMill = autoLiquidityFee;
    autoRedistributionFeePerMill = autoRedistributionFee;
    autoBurnFeePerMill = autoBurnFee;
    return true;
  }

  /// @notice Destroy `amount` tokens of caller.
  function burn(uint256 amount) public returns (bool)
  {
    uint256 rAmount = _reflectionFromToken(amount);
    require(_reflectionBalance[_msgSender()] >= rAmount, "You can't burn more than you own.");
    _reflectionBalance[_msgSender()] = _reflectionBalance[_msgSender()] - rAmount;
    _reflectionSupply -= rAmount;
    _tokenSupply -= amount;
    emit Burned(amount);
    return true;
  }

  /// @notice Leaves the contract without owner. It will not be possible to call
  /// 'onlyOwner' functions anymore.
  function renounceOwnership() public override onlyOwner {
    _isExempted[owner()] = false;
    super.renounceOwnership();
  }

  /// @notice Transfers ownership of the contract to account `newOwner`.
  function transferOwnership(address newOwner) public override onlyOwner {
    _isExempted[owner()] = false;
    super.transferOwnership(newOwner);
    _isExempted[newOwner] = true;
  }

  /// @notice Account `account` shall be exempted from fees, transaction limit, and whale catching.
  function addExemption(address account) public onlyOwner {
    if (!_isExempted[account]) {
      _isExempted[account] = true;
      emit Exempted(account, true);
    }
  }

  /// @notice Remove exemption for `account`.
  function removeExemption(address account) public onlyOwner {
    require(address(this) != account, "The contract's address cannot pay fees!");
    require(owner() != account, "The contract's owner will not pay fees.");
    if (_isExempted[account]) {
      _isExempted[account] = false;
      emit Exempted(account, false);
    }
  }

  /// @notice Add `account` to list of exchanges.
  function addExchange(address account) public onlyOwner returns (bool)
  {
    if (!_exchange[account]) {
      _exchange[account] = true;
      emit Exchange(account, true);
    }
    return true;
  }

  /// @notice Remove `account` from list of exchanges.
  function removeExchange(address account) public onlyOwner returns (bool)
  {
    if (_exchange[account]) {
      _exchange[account] = false;
      emit Exchange(account, false);
    }
    return true;
  }

  function removePancakeSwapRouter() private onlyOwner {
    _exchange[uniswapV2WETHPair] = false;

    uniswapV2Router = IUniswapV2Router02(address(0));
    uniswapV2WETHPair = address(0);
  }

  function setPancakeSwapRouter(address pcs) private onlyOwner {
    // Tells solidity this address follows the IUniswapV2Router interface
    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(pcs);

    // Create a pair between our token and WBNB.
    address wethTokenPairAddress = IUniswapV2Factory(_uniswapV2Router.factory())
      .createPair(address(this), _uniswapV2Router.WETH());

    uniswapV2Router = _uniswapV2Router;
    uniswapV2WETHPair = wethTokenPairAddress;

    _exchange[wethTokenPairAddress] = true;
  }

  function setNewPancakeSwapRouterAddress(address pcs) public onlyOwner {
    removePancakeSwapRouter();
    setPancakeSwapRouter(pcs);
  }

  function setMaxTransferAmount(uint256 tokenLimit) public onlyOwner {
    maxTransferAmount = tokenLimit * 10**18;

    emit MaxTransferLimit(tokenLimit);
  }
}
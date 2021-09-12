/**
 *Submitted for verification at BscScan.com on 2021-09-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    this; 
    return msg.data;
  }
}

abstract contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view virtual returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(owner() == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

library Address {

  function isContract(address account) internal view returns (bool) {
    uint256 size;
    assembly { size := extcodesize(account) }
    return size > 0;
  }

   function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");
    (bool success, ) = recipient.call{ value: amount }("");
    require(success, "Address: unable to send value, recipient may have reverted");
  }

  function functionCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionCall(target, data, "Address: low-level call failed");
  }

  function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
    return functionCallWithValue(target, data, 0, errorMessage);
  }

  function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
  }

  function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
    require(address(this).balance >= value, "Address: insufficient balance for call");
    require(isContract(target), "Address: call to non-contract");

    (bool success, bytes memory returndata) = target.call{ value: value }(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
    return functionStaticCall(target, data, "Address: low-level static call failed");
  }

  function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
    require(isContract(target), "Address: static call to non-contract");

    (bool success, bytes memory returndata) = target.staticcall(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionDelegateCall(target, data, "Address: low-level delegate call failed");
  }

  function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
    require(isContract(target), "Address: delegate call to non-contract");

    (bool success, bytes memory returndata) = target.delegatecall(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
    if (success) {
      return returndata;
    } else {
      if (returndata.length > 0) {
        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert(errorMessage);
      }
    }
  }
}

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {

    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath#mul: OVERFLOW");

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "SafeMath#div: DIVISION_BY_ZERO");
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath#sub: UNDERFLOW");
    uint256 c = a - b;

    return c;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath#add: OVERFLOW");

    return c; 
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath#mod: DIVISION_BY_ZERO");
    return a % b;
  }

}

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

interface IERC20Metadata is IERC20 {

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);
}

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

abstract contract PomskyMetaData is IERC20Metadata {

  string constant private _name = "Pomsky";

  string constant private _symbol = "POM";

  uint8 constant private _decimals = 18;

  function name() public pure override returns (string memory) {
    return _name;
  }

  function symbol() public pure override returns (string memory) {
    return _symbol;
  }

  function decimals() public pure override returns (uint8) {
    return _decimals;
  }
}

contract Pomsky is Ownable, PomskyMetaData {
  using SafeMath for uint256;
//   address private constant _pancakeswapRouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
   address private constant _pancakeswapRouterAddress  = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
  event AddedLiquidity(
    uint256 tokens,
    uint256 wbnb,
    uint256 liquidity
  );

  event Burned(uint256 amount);

  event Exempted(address account, bool exempted);

  event Exchange(address account, bool added);

  uint256 private constant MAX_INT_VALUE = type(uint256).max;

  uint256 private _tokenSupply = 10**15 * 10**18;

  uint256 private _autoBurnStepAmounts = _tokenSupply / 50;
  uint8 private _autoBurnAllow = 1;
  uint8 private _autoBurnNumber = 1;
  
  
  uint256 private _createdTime;

  uint256 private _autoBurnedAmounts = 0;
  
  uint256 private _reflectionSupply = (MAX_INT_VALUE - (MAX_INT_VALUE % _tokenSupply));

  uint256 private _totalTokenFees;

  bool private setFeesAllow = true;

  uint8 private charityFundFeePerMill = 30; // donations
  uint8 private redistFundFeePerMill = 10; // buyback + manual burn
  uint8 private marketingFundFeePerMill = 50; // marketing + development
  uint8 private autoLiquidityFeePerMill = 50; // automatic liquidity increment
  uint8 private autoRedistributionFeePerMill = 10; // by means of reflections
  uint8 private autoBurnFeePerMill = 30; // automatic token burning

  uint8 private charityFundFeeRoll = 1;
  uint8 private redistFundFeeRoll = 1;
  uint8 private marketingFundFeeRoll  = 1;
  uint8 private autoLiquidityFeeRoll = 1;
  uint8 private autoRedistributionFeeRoll = 1; 
  uint8 private autoBurnFeeRoll = 1;

  uint8 private charityFundFeeAllow = 1;
  uint8 private redistFundFeeAllow = 1;
  uint8 private marketingFundFeeAllow  = 1;
  uint8 private autoLiquidityFeeAllow = 1;
  uint8 private autoRedistributionFeeAllow = 1; 
  uint8 private autoBurnFeeAllow = 1;

  mapping(address => uint256) private _reflectionBalance;

  mapping(address => bool) private _isExempted;

  mapping(address => mapping(address => uint256)) private _allowances;

  mapping(address => bool) private _exchange;

  address[] internal stakeholders;

  mapping(address => uint256) internal stakes;

  mapping(address => uint256) internal rewards;

  IUniswapV2Router02 public uniswapV2Router;
  address public uniswapV2WETHPair;

  address payable private immutable _charityFund;

  address payable private immutable _redistFund;

  address payable private immutable _marketingFund;

  address payable private immutable _liquidityTokenAddress;

  enum TransferType {BuyViaPcs, Sale, Other}

  constructor(
    address payable charityFundAddress,
    address payable redistFundAddress,
    address payable marketingFundAddress,
    address payable liquidityTokenAddr
  ) {
    _reflectionBalance[_msgSender()] = _reflectionSupply;

    setPancakeSwapRouter(_pancakeswapRouterAddress);

    _charityFund = charityFundAddress;
    _redistFund = redistFundAddress;
    _marketingFund = marketingFundAddress;
    _liquidityTokenAddress = liquidityTokenAddr;

    _isExempted[owner()] = true;
    _isExempted[address(this)] = true;
    _isExempted[charityFundAddress] = true;
    _isExempted[redistFundAddress] = true;
    _isExempted[marketingFundAddress] = true;
    _isExempted[liquidityTokenAddr] = true;

    _createdTime = block.timestamp;

    emit Transfer(address(0), _msgSender(), _tokenSupply);
  }

  function mint(address receiver, uint amount) private {
    emit Transfer(address(0), receiver, amount);

  }

  function burning(address receiver, uint amount) private {
    emit Transfer(receiver, address(0),  amount);
  }
  function totalSupply() external view override returns (uint256) {
    return _tokenSupply;
  }

  function _getRate() private view returns (uint256) {
    return _reflectionSupply / _tokenSupply;
  }

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

  function balanceOf(address account) public view override returns (uint256) {
    return _tokenFromReflection(_reflectionBalance[account]);
  }

  function totalFeesCollected() external view onlyOwner returns (uint256) {
    return _totalTokenFees;
  }

  function _sendBnb(address payable to, uint256 wbnbAmount) private returns(bool)
  {
    if (wbnbAmount == 0)
      return true;
    (bool success, ) = to.call{value: wbnbAmount}("");
    return success;
  }

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

  function _cleanLeftOverBnb() private {
    if (address(this).balance > 10 ** 18) { // 1 BNB
      _sendBnb(_liquidityTokenAddress, address(this).balance);
    }
  }

  function _deductTaxes(uint256 amount, TransferType kindOfTransfer) private returns(uint256 totalTax) {
    uint256 charityTax = (charityFundFeeAllow * amount * charityFundFeePerMill) / 1000;
    uint256 redistTax = (redistFundFeeAllow * amount * redistFundFeePerMill) / 1000;
    uint256 marketingTax = (marketingFundFeeAllow * amount * marketingFundFeePerMill) / 1000;
    uint256 autoLiquidityTax = (autoLiquidityFeeAllow * amount * autoLiquidityFeePerMill) / 1000;
    uint256 autoRedistTax = (autoRedistributionFeeAllow * amount * autoRedistributionFeePerMill) / 1000;
    uint256 autoBurnTax = (autoBurnFeeAllow * amount * autoBurnFeePerMill) / 1000;
    totalTax =
      charityTax +
      redistTax +
      marketingTax +
      autoLiquidityTax +
      autoRedistTax +
      autoBurnTax;
    
    _autoBurnedAmounts += autoBurnTax;

    _reflectionSupply -= _reflectionFromToken(autoRedistTax + autoBurnTax);
    _tokenSupply -= autoBurnTax;
    emit Burned(autoBurnTax);

    _totalTokenFees += totalTax;

    _reflectionBalance[address(this)] =
      _reflectionBalance[address(this)] +
      _reflectionFromToken(charityTax + redistTax + marketingTax +  autoLiquidityTax);

    if (kindOfTransfer != TransferType.BuyViaPcs) {
      uint256 accruedTax = _tokenFromReflection(_reflectionBalance[address(this)]);

      if (accruedTax > 0) {
        uint256 feeRateSum = charityFundFeePerMill + redistFundFeePerMill + marketingFundFeePerMill + autoLiquidityFeePerMill;
        charityTax = (accruedTax * charityFundFeePerMill) / feeRateSum;
        redistTax = (accruedTax * redistFundFeePerMill) / feeRateSum;
        marketingTax = (accruedTax * marketingFundFeePerMill) / feeRateSum;
        autoLiquidityTax = (accruedTax * autoLiquidityFeePerMill) / feeRateSum;
      } else {
        accruedTax = 0;
        charityTax = 0;
        redistTax = 0;
        marketingTax = 0;
        autoLiquidityTax = 0;
      }

      uint256 tokensToSwap = charityTax + redistTax + marketingTax + autoLiquidityTax / 2;
      if (tokensToSwap > 0) {
        uint256 swappedBnb = _swapTokensForWbnb(tokensToSwap, address(this));

        _sendBnb(_charityFund, swappedBnb * charityTax / tokensToSwap);
        _sendBnb(_redistFund, swappedBnb * redistTax / tokensToSwap);
        _sendBnb(_marketingFund, swappedBnb * marketingTax / tokensToSwap);
      }
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


  function _checkAutoBurn() private {
    if ( _autoBurnNumber < 13 && _autoBurnAllow == 1 && _createdTime + _autoBurnNumber * 5 minutes < block.timestamp){

      _autoBurnNumber += 1;

      uint256 rAmount = _reflectionFromToken(_autoBurnStepAmounts);
      _reflectionBalance[owner()] = _reflectionBalance[owner()] - rAmount;
      _tokenSupply  -= _autoBurnStepAmounts;

      emit Transfer(owner(), address(0), _autoBurnStepAmounts);
    }
  }
  
    function _checkAllFees() private {
    if (charityFundFeeAllow == 1 && charityFundFeePerMill>0){
      if ( _createdTime + charityFundFeeRoll * 5 minutes < block.timestamp ){
        charityFundFeeRoll  += 1;
        if ( charityFundFeeRoll > 3 ) charityFundFeePerMill = 0;
        else charityFundFeePerMill /= 2;
      }
    }

    if (marketingFundFeeAllow == 1 && marketingFundFeePerMill>0){
      if ( _createdTime + marketingFundFeeRoll * 5 minutes  < block.timestamp ){
        marketingFundFeeRoll  += 1;
        if ( marketingFundFeeRoll > 3 ) marketingFundFeePerMill = 0;
        else marketingFundFeePerMill  /= 2;
      }
    }

    if (autoLiquidityFeeAllow == 1 && autoLiquidityFeePerMill>0){
      if ( _createdTime + autoLiquidityFeeRoll * 5 minutes  < block.timestamp ){
        autoLiquidityFeeRoll  += 1;
        if ( autoLiquidityFeeRoll > 3 ) autoLiquidityFeePerMill = 0;
        else autoLiquidityFeePerMill /= 2;
      }
    }

    if (autoRedistributionFeeAllow == 1 && autoRedistributionFeePerMill>0){
      if ( _createdTime + autoRedistributionFeeRoll * 5 minutes < block.timestamp ){
        autoRedistributionFeeRoll += 1;
        if ( autoRedistributionFeeRoll > 3 ) autoRedistributionFeePerMill = 0;
        else autoRedistributionFeePerMill /= 2;
      }
    }

    if ( autoBurnFeeAllow == 1 && autoBurnFeePerMill>0){
      if ( _autoBurnedAmounts >= (_autoBurnStepAmounts * 25)/2 ){
        autoBurnFeePerMill = 0;
        return;
      }
      if ( _createdTime + autoBurnFeeRoll * 5 minutes < block.timestamp){
        autoBurnFeeRoll += 1;
        if ( autoBurnFeeRoll > 5 ) autoBurnFeePerMill = 0;
        else autoBurnFeePerMill /= 2;
      }
    }
  }

 
 
 
  function _transferToken(
    address sender,
    address recipient,
    uint256 amount,
    bool noFees
  ) private {

    uint256 rAmount = _reflectionFromToken(amount);

    if ( sender == owner() ){
      require( 
        _reflectionBalance[owner()] - rAmount   >=  _reflectionFromToken(_autoBurnAllow * _autoBurnStepAmounts * (13-_autoBurnNumber)),
        "Locked Token" );
    }

    _reflectionBalance[sender] = _reflectionBalance[sender] - rAmount;

    uint256 totalTax = 0;
    uint256 rTotalTax = 0;
    if (!noFees) {
      totalTax = _deductTaxes(amount, getTransferType(sender, recipient));
      rTotalTax = _reflectionFromToken(totalTax);
      _cleanLeftOverBnb();
    }
   
   _checkAutoBurn();
   _checkAllFees();
    
    _reflectionBalance[recipient] = _reflectionBalance[recipient] + rAmount - rTotalTax;
    emit Transfer(sender, recipient, amount - totalTax);


 

  }


  function _swapTokensForWbnb(uint256 tokenAmount, address to) private returns(uint256) {
    if (tokenAmount == 0)
      return 0;

    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswapV2Router.WETH();

    _approve(address(this), address(uniswapV2Router), tokenAmount);

    uint256 balanceBeforeSwap = address(this).balance;

    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount,
      0,
      path,
      to,
      block.timestamp 
    );

    return address(this).balance - balanceBeforeSwap;
  }

  function _addLiquidity(uint256 tokenAmount, uint256 wbnbAmount)
    private
    returns(uint256 actualToken, uint256 actualBnb, uint256 liquidity)
  {
    _approve(address(this), address(uniswapV2Router), tokenAmount);

    (actualToken, actualBnb, liquidity) = uniswapV2Router.addLiquidityETH{ value: wbnbAmount }(
      address(this),
      tokenAmount,
      0, 
      0, 
      _liquidityTokenAddress,
      block.timestamp 
    );
  }

//   function enableTrading() external onlyOwner {
//     isTradingEnabled = true;
//   }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) private {
    require(sender != address(0), "source must not be the zero address");
    require(recipient != address(0), "destination must not be the zero address");
    require(amount > 0, "transfer amount must be greater than zero");
    // if (
    //      sender != owner()
    //   && recipient != owner()
    //   && !_isExempted[sender]
    //   && !_isExempted[recipient]
    // ) {
    //   //require(isTradingEnabled, "Nice try :)");
    // }

    _transferToken(
      sender,
      recipient,
      amount,
      _isExempted[sender] || _isExempted[recipient]
    );
  }

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

  function transfer(address recipient, uint256 amount)
    public
    override
    returns (bool)
  {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function approve(address beneficiary, uint256 amount)
    public
    override
    returns (bool)
  {
    _approve(_msgSender(), beneficiary, amount);
    return true;
  }

  function transferFrom(
    address provider,
    address beneficiary,
    uint256 amount
  ) public override returns (bool) {
    if (provider != _msgSender()) {
      require(_allowances[provider][_msgSender()] >= amount, "Insufficient allowance");

      _approve(
        provider,
        _msgSender(),
        _allowances[provider][_msgSender()] - amount
      );
    }

    _transfer(provider, beneficiary, amount);
    return true;
  }

  function allowance(address owner, address beneficiary)
    public
    view
    override
    returns (uint256)
  {
    return _allowances[owner][beneficiary];
  }


  function setFees(
    uint8 charityFee,
    uint8 redistFee,
    uint8 marketingFee,
    uint8 autoLiquidityFee,
    uint8 autoRedistributionFee,
    uint8 autoBurnFee)
    public
    onlyOwner
    returns (bool)
  {
    require((charityFee + redistFee + marketingFee + autoLiquidityFee + autoRedistributionFee + autoBurnFee) <= 200, "overtaxation");
    require(setFeesAllow == true, "Can't set fees any more.");
    charityFundFeePerMill = charityFee;
    redistFundFeePerMill = redistFee;
    marketingFundFeePerMill = marketingFee;
    autoLiquidityFeePerMill = autoLiquidityFee;
    autoRedistributionFeePerMill = autoRedistributionFee;
    autoBurnFeePerMill = autoBurnFee;

    setFeesAllow = false;
    return true;
  }

  function setDisableAutoBurning() public onlyOwner returns (bool) {
    _autoBurnAllow = 0;
    return true;
  }
    // function setEnableCharityFundFee() public onlyOwner return (bool){
    //   charityFundFeeAllow = 1;
    //   return true;
    // }
    function setDisableCharityFundFee() public onlyOwner returns (bool){
      charityFundFeeAllow = 0;
      return true;
    }

    
    // function setEnableRedistFundFee() public onlyOwner return (bool){
    //   redistFundFeeAllow = 1;
    //   return true;
    // }
    function setDisableRedistFundFee() public onlyOwner returns (bool){
      redistFundFeeAllow = 0;
      return true;
    }

    // function setEnableMarketingFundFee() public onlyOwner return (bool) {
    //   marketingFundFeeAllow = 1;
    //   return true;
    // }
    function setDisableMarketingFundFee() public onlyOwner returns (bool) {
      marketingFundFeeAllow = 0;
      return true;
    }


  //  function setEableAutoLiquidityFee() public onlyOwner return (bool){
  //     autoLiquidityFeeAllow = 1;
  //     return true;
  //  }
  function setDisableAutoLiquidityFee() public onlyOwner returns (bool) {
      autoLiquidityFeeAllow = 0;
      return true;
  }


  //  function setEnableAutoRedistributionFee() public onlyOwner return (bool) {
  //   autoRedistributionFeeAllow = 1; 
  //   return true;
  //  }
  function setDisableAutoRedistributionFee() public onlyOwner returns (bool) {
    autoRedistributionFeeAllow = 0; 
    return true;
  }

  //  function setEnableAutoBurnFee() public onlyOwner return (bool) {
  //    autoBurnFeeAllow = 1;
  //    return true;
  //  }
  function setDisableAutoBurnFee() public onlyOwner returns (bool) {
    autoBurnFeeAllow = 0;
    return true;
  }




 function getCharityFundFeePerMill() public view returns (uint8) {
    return charityFundFeePerMill;
  }

function getRedistFundFeePerMill() public view returns (uint8) {
    return redistFundFeePerMill;
  }
  function getMarketingFundFeePerMill() public view returns (uint8) {
    return marketingFundFeePerMill;
  }
  function getAutoLiquidityFeePerMill() public view returns (uint8) {
    return autoLiquidityFeePerMill;
  }

 function getAutoRedistributionFeePerMill() public view returns (uint8) {
    return autoRedistributionFeePerMill;
  }
 function getAutoBurnFeePerMill() public view returns (uint8) {
    return autoBurnFeePerMill;
  }
  
  function getAutoBurnNumber() public view returns (uint8) {
      return _autoBurnNumber;
  }
  
  

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

  
  function renounceOwnership() public override onlyOwner {
    _isExempted[owner()] = false;
    super.renounceOwnership();
  }

  function transferOwnership(address newOwner) public override onlyOwner {
    _isExempted[owner()] = false;
    super.transferOwnership(newOwner);
    _isExempted[newOwner] = true;
  }

  function addExemption(address account) public onlyOwner {
    if (!_isExempted[account]) {
      _isExempted[account] = true;
      emit Exempted(account, true);
    }
  }

  function removeExemption(address account) public onlyOwner {
    require(address(this) != account, "The contract's address cannot pay fees!");
    require(owner() != account, "The contract's owner will not pay fees.");
    if (_isExempted[account]) {
      _isExempted[account] = false;
      emit Exempted(account, false);
    }
  }

  function addExchange(address account) public onlyOwner returns (bool)
  {
    if (!_exchange[account]) {
      _exchange[account] = true;
      emit Exchange(account, true);
    }
    return true;
  }

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
    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(pcs);

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

  // function setMaxTransferAmount(uint256 tokenLimit) public onlyOwner {
  //   maxTransferAmount = tokenLimit * 10**18;

  //   emit MaxTransferLimit(tokenLimit);
  // }

   function isStakeholder(address _address)
       public
       view
       returns(bool, uint256)
   {
       for (uint256 s = 0; s < stakeholders.length; s += 1){
           if (_address == stakeholders[s]) return (true, s);
       }
       return (false, 0);
   }

   function addStakeholder(address _stakeholder)
       public
   {
       (bool _isStakeholder, ) = isStakeholder(_stakeholder);
       if(!_isStakeholder) stakeholders.push(_stakeholder);
   }

   function removeStakeholder(address _stakeholder)
       public
   {
       (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
       if(_isStakeholder){
           stakeholders[s] = stakeholders[stakeholders.length - 1];
           stakeholders.pop();
       }
   }

   function stakeOf(address _stakeholder)
       public
       view
       returns(uint256)
   {
       return stakes[_stakeholder];
   }

   function totalStakes()
       public
       view
       returns(uint256)
   {
       uint256 _totalStakes = 0;
       for (uint256 s = 0; s < stakeholders.length; s += 1){
           _totalStakes = _totalStakes.add(stakes[stakeholders[s]]);
       }
       return _totalStakes;
   }

   function createStake(uint256 _stake)
       public
   {
       require( balanceOf (msg.sender) >= _stake, "Amount Over Error.");
       burn(_stake);
       if(stakes[msg.sender] == 0) addStakeholder(msg.sender);
       stakes[msg.sender] = stakes[msg.sender].add(_stake);
   }

   function removeStake(uint256 _stake)
       public
   {
       require( stakes[msg.sender] >= _stake, "Amount Over Error.");
       stakes[msg.sender] = stakes[msg.sender].sub(_stake);
       if(stakes[msg.sender] == 0) removeStakeholder(msg.sender);
       mint(msg.sender, _stake);
   }

   function rewardOf(address _stakeholder)
       public
       view
       returns(uint256)
   {
       return rewards[_stakeholder];
   }

   function totalRewards()
       public
       view
       returns(uint256)
   {
       uint256 _totalRewards = 0;
       for (uint256 s = 0; s < stakeholders.length; s += 1){
           _totalRewards = _totalRewards.add(rewards[stakeholders[s]]);
       }
       return _totalRewards;
   }

   function calculateReward(address _stakeholder)
       public
       view
       returns(uint256)
   {
       return stakes[_stakeholder] / (100*10**3);
   }

   function distributeRewards()
       public
       onlyOwner
   {
       for (uint256 s = 0; s < stakeholders.length; s += 1){
           address stakeholder = stakeholders[s];
           uint256 reward = calculateReward(stakeholder);
           rewards[stakeholder] = rewards[stakeholder].add(reward);
       }
   }

   function withdrawReward()
       public
   {
       uint256 reward = rewards[msg.sender];
       rewards[msg.sender] = 0;
       mint(msg.sender, reward);
   }
}
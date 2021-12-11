/**
 *Submitted for verification at Etherscan.io on 2021-12-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

abstract contract Context {
	function _msgSender() internal view virtual returns (address payable) {
		return payable(msg.sender);
	}

	function _msgData() internal view virtual returns (bytes memory) {
		this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
		return msg.data;
	}
}

interface IERC20 {
	function totalSupply() external view returns (uint256);

	function balanceOf(address account) external view returns (uint256);

	function transfer(address recipient, uint256 amount)
	external
	returns (bool);

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
	event Approval(
		address indexed owner,
		address indexed spender,
		uint256 value
	);
}

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
		require(b > 0, errorMessage);
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn't hold

		return c;
	}

	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
		return mod(a, b, "SafeMath: modulo by zero");
	}

	function mod(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
		require(b != 0, errorMessage);
		return a % b;
	}
}

library Address {
	function isContract(address account) internal view returns (bool) {
		// According to EIP-1052, 0x0 is the value returned for not-yet created accounts
		// and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
		// for accounts without code, i.e. `keccak256('')`
		bytes32 codehash;
		bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
		// solhint-disable-next-line no-inline-assembly
		assembly {
			codehash := extcodehash(account)
		}
		return (codehash != accountHash && codehash != 0x0);
	}

	function sendValue(address payable recipient, uint256 amount) internal {
		require(
			address(this).balance >= amount,
			"Address: insufficient balance"
		);

		// solhint-disable-next-line avoid-low-level-calls, avoid-call-value
		(bool success, ) = recipient.call{value: amount}("");
		require(
			success,
			"Address: unable to send value, recipient may have reverted"
		);
	}

	function functionCall(address target, bytes memory data)
	internal
	returns (bytes memory)
	{
		return functionCall(target, data, "Address: low-level call failed");
	}

	function functionCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal returns (bytes memory) {
		return _functionCallWithValue(target, data, 0, errorMessage);
	}

	function functionCallWithValue(
		address target,
		bytes memory data,
		uint256 value
	) internal returns (bytes memory) {
		return
		functionCallWithValue(
			target,
			data,
			value,
			"Address: low-level call with value failed"
		);
	}

	function functionCallWithValue(
		address target,
		bytes memory data,
		uint256 value,
		string memory errorMessage
	) internal returns (bytes memory) {
		require(
			address(this).balance >= value,
			"Address: insufficient balance for call"
		);
		return _functionCallWithValue(target, data, value, errorMessage);
	}

	function _functionCallWithValue(
		address target,
		bytes memory data,
		uint256 weiValue,
		string memory errorMessage
	) private returns (bytes memory) {
		require(isContract(target), "Address: call to non-contract");

		(bool success, bytes memory returndata) = target.call{value: weiValue}(
		data
		);
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

contract Ownable is Context {
	address private _owner;
	address private _previousOwner;
	uint256 private _lockTime;

	event OwnershipTransferred(
		address indexed previousOwner,
		address indexed newOwner
	);

	constructor() {
		address msgSender = _msgSender();
		_owner = msgSender;
		emit OwnershipTransferred(address(0), msgSender);
	}

	function owner() public view returns (address) {
		return _owner;
	}

	modifier onlyOwner() {
		require(_owner == _msgSender(), "Ownable: caller is not the owner");
		_;
	}

	function renounceOwnership() public virtual onlyOwner {
		emit OwnershipTransferred(_owner, address(0));
		_owner = address(0);
	}

	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(
			newOwner != address(0),
			"Ownable: new owner is the zero address"
		);
		emit OwnershipTransferred(_owner, newOwner);
		_owner = newOwner;
	}

	function getUnlockTime() public view returns (uint256) {
		return _lockTime;
	}

	function getTime() public view returns (uint256) {
		return block.timestamp;
	}
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

interface IUniswapV2Pair {
	event Approval(
		address indexed owner,
		address indexed spender,
		uint256 value
	);
	event Transfer(address indexed from, address indexed to, uint256 value);

	function name() external pure returns (string memory);

	function symbol() external pure returns (string memory);

	function decimals() external pure returns (uint8);

	function totalSupply() external view returns (uint256);

	function balanceOf(address owner) external view returns (uint256);

	function allowance(address owner, address spender)
	external
	view
	returns (uint256);

	function approve(address spender, uint256 value) external returns (bool);

	function transfer(address to, uint256 value) external returns (bool);

	function transferFrom(
		address from,
		address to,
		uint256 value
	) external returns (bool);

	function DOMAIN_SEPARATOR() external view returns (bytes32);

	function PERMIT_TYPEHASH() external pure returns (bytes32);

	function nonces(address owner) external view returns (uint256);

	function permit(
		address owner,
		address spender,
		uint256 value,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;

	event Burn(
		address indexed sender,
		uint256 amount0,
		uint256 amount1,
		address indexed to
	);
	event Swap(
		address indexed sender,
		uint256 amount0In,
		uint256 amount1In,
		uint256 amount0Out,
		uint256 amount1Out,
		address indexed to
	);
	event Sync(uint112 reserve0, uint112 reserve1);

	function MINIMUM_LIQUIDITY() external pure returns (uint256);

	function factory() external view returns (address);

	function token0() external view returns (address);

	function token1() external view returns (address);

	function getReserves()
	external
	view
	returns (
		uint112 reserve0,
		uint112 reserve1,
		uint32 blockTimestampLast
	);

	function price0CumulativeLast() external view returns (uint256);

	function price1CumulativeLast() external view returns (uint256);

	function kLast() external view returns (uint256);

	function burn(address to)
	external
	returns (uint256 amount0, uint256 amount1);

	function swap(
		uint256 amount0Out,
		uint256 amount1Out,
		address to,
		bytes calldata data
	) external;

	function skim(address to) external;

	function sync() external;

	function initialize(address, address) external;
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

contract Devour is Context, IERC20, Ownable {
	using SafeMath for uint256;
	using Address for address;

	IUniswapV2Router02 public uniswapV2Router;
address public immutable uniswapV2Pair;

string private _name =  "Devour";
string private _symbol = "DEVOUR";
uint8 private _decimals = 9;

bool public isTradingEnabled;
uint256 private _tradingPausedTimestamp;

address public marketingWallet;
address public liquidityWallet;
address public foundationWallet;
address public devWallet;

struct CustomTaxPeriod {
bytes23 periodName;
uint8 blocksInPeriod;
uint256 timeInPeriod;
uint256 liquidityFeeOnBuy;
uint256 liquidityFeeOnSell;
uint256 marketingFeeOnBuy;
uint256 marketingFeeOnSell;
uint256 devFeeOnBuy;
uint256 devFeeOnSell;
uint256 foundationFeeOnBuy;
uint256 foundationFeeOnSell;
uint256 burnFeeOnBuy;
uint256 burnFeeOnSell;
uint256 holdersFeeOnBuy;
uint256 holdersFeeOnSell;
}

// Dividends
mapping(address => uint256) private _rOwned;
mapping(address => uint256) private _tOwned;
mapping(address => mapping(address => uint256)) private _allowances;

// Launch taxes
bool private _isLaunched;
uint256 private _launchStartTimestamp;
uint256 private _launchBlockNumber;
CustomTaxPeriod private _launch2 = CustomTaxPeriod('launch2',0,3600,2,6,4,17,0,10,0,2,0,0,0,0);
CustomTaxPeriod private _launch3 = CustomTaxPeriod('launch3',0,82800,2,6,4,10,0,7,0,2,0,0,0,0);

// Base taxes
CustomTaxPeriod private _default = CustomTaxPeriod('default',0,0,0,1,1,2,1,1,1,1,1,2,2,3);
CustomTaxPeriod private _base = CustomTaxPeriod('base',0,0,0,1,1,2,1,1,1,1,1,2,2,3);

// Alley Hour taxes
uint256 private _alleyHourStartTimestamp = 0;
CustomTaxPeriod private _alley1 = CustomTaxPeriod('alley1',0,3600,1,3,0,5,0,5,0,2,0,4,1,6);
CustomTaxPeriod private _alley2 = CustomTaxPeriod('alley2',0,3600,1,1,0,3,0,3,0,1,1,3,2,4);

uint256 private _blockedTimeLimit = 86400;
mapping (address => bool) private _isExcludedFromFee;
mapping(address => bool) private _isExcludedFromDividends;
address[] private _excludedFromDividends;
mapping (address => bool) private _isExcludedFromMaxTransactionLimit;
mapping (address => bool) private _isExcludedFromMaxWalletLimit;
mapping (address => bool) private _isBlocked;
mapping (address => bool) public automatedMarketMakerPairs;
mapping (address => uint256) private _buyTimesInLaunch;

uint256 private _liquidityFee;
uint256 private _marketingFee;
uint256 private _devFee;
uint256 private _foundationFee;
uint256 private _burnFee;
uint256 private _holdersFee;
uint256 private _totalFee;

uint256 private constant MAX = ~uint256(0);
uint256 private constant _tTotal = 	1000000000000000 * 1e9;
uint256 private _rTotal = (MAX - (MAX % _tTotal));
uint256 private _tFeeTotal;

// max wallet is 1.5% of _tTotal
uint256 public maxWalletAmount = _tTotal * 150 / 10000;

// max buy and sell tx is 20% of _tTotal
uint256 public maxTxAmount = _tTotal * 20 / 100;

bool private _swapping;
uint256 public minimumTokensBeforeSwap = 25000000 * (10**9);

event AutomatedMarketMakerPairChange(address indexed pair, bool indexed value);
event UniswapV2RouterChange(address indexed newAddress, address indexed oldAddress);
event WalletChange(address indexed newWallet, address indexed oldWallet);
event FeeChange(string indexed identifier, uint256 liquidityFee, uint256 marketingFee, uint256 devFee, uint256 foundationFee, uint256 burnFee, uint256 holdersFee);
event CustomTaxPeriodChange(uint256 indexed newValue, uint256 indexed oldValue, string indexed taxType, bytes23 period);
event BlockedAccountChange(address indexed holder, bool indexed status);
event AlleyHourChange(bool indexed newValue, bool indexed oldValue);
event MaxTransactionAmountChange(uint256 indexed newValue, uint256 indexed oldValue);
event MaxWalletAmountChange(uint256 indexed newValue, uint256 indexed oldValue);
event MinTokenAmountBeforeSwapChange(uint256 indexed newValue, uint256 indexed oldValue);
event MinTokenAmountForDividendsChange(uint256 indexed newValue, uint256 indexed oldValue);
event ExcludeFromFeesChange(address indexed account, bool isExcluded);
event ExcludeFromMaxTransferChange(address indexed account, bool isExcluded);
event ExcludeFromMaxWalletChange(address indexed account, bool isExcluded);
event ExcludeFromDividendsChange(address indexed account, bool isExcluded);
event TokenBurn(uint256 burnFee, uint256 tBurnFee, uint256 rBurnFee);
event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived,uint256 tokensIntoLiqudity);
event ClaimEthOverflow(uint256 amount);
event FeesApplied(uint256 liquidityFee, uint256 marketingFee, uint256 devFee, uint256 foundationFee, uint256 burnFee, uint256 holdersFee, uint256 totalFee);

constructor() public {
marketingWallet = owner();
liquidityWallet = owner();
foundationWallet = owner();
devWallet = owner();

IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
uniswapV2Router = _uniswapV2Router;
uniswapV2Pair = _uniswapV2Pair;
_setAutomatedMarketMakerPair(_uniswapV2Pair, true);

_isExcludedFromFee[owner()] = true;
_isExcludedFromFee[address(this)] = true;

excludeFromDividends(address(0), true);
excludeFromDividends(address(_uniswapV2Router), true);

_isExcludedFromMaxTransactionLimit[address(this)] = true;

_isExcludedFromMaxWalletLimit[_uniswapV2Pair] = true;
_isExcludedFromMaxWalletLimit[address(uniswapV2Router)] = true;
_isExcludedFromMaxWalletLimit[address(this)] = true;
_isExcludedFromMaxWalletLimit[owner()] = true;

_rOwned[_msgSender()] = _rTotal;
emit Transfer(address(0), _msgSender(), _tTotal);
}

receive() external payable {}

// Setters
function transfer(address recipient, uint256 amount) external override returns (bool) {
_transfer(_msgSender(), recipient, amount);
return true;
}
function approve(address spender, uint256 amount) public override returns (bool) {
_approve(_msgSender(), spender, amount);
return true;
}
function transferFrom( address sender,address recipient,uint256 amount) external override returns (bool) {
_transfer(sender, recipient, amount);
_approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount,"ERC20: transfer amount exceeds allowance"));
return true;
}
function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool){
_approve(_msgSender(),spender,_allowances[_msgSender()][spender].add(addedValue));
return true;
}
function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
_approve(_msgSender(),spender,_allowances[_msgSender()][spender].sub(subtractedValue,"ERC20: decreased allowance below zero"));
return true;
}
function _getNow() private view returns (uint256) {
return block.timestamp;
}
function launch() public onlyOwner {
_launchStartTimestamp = _getNow();
_launchBlockNumber = block.number;
isTradingEnabled = true;
_isLaunched = true;
}
function cancelLaunch() public onlyOwner {
require(this.isInLaunch(), "Devour: Launch is not set");
_launchStartTimestamp = 0;
_launchBlockNumber = 0;
_isLaunched = false;
}
function activateTrading() public onlyOwner {
isTradingEnabled = true;
}
function deactivateTrading() public onlyOwner {
isTradingEnabled = false;
_tradingPausedTimestamp = _getNow();
}
function _setAutomatedMarketMakerPair(address pair, bool value) private {
require(automatedMarketMakerPairs[pair] != value, "Devour: Automated market maker pair is already set to that value");
automatedMarketMakerPairs[pair] = value;
emit AutomatedMarketMakerPairChange(pair, value);
}
function excludeFromFees(address account, bool excluded) public onlyOwner {
require(_isExcludedFromFee[account] != excluded, "Devour: Account is already the value of 'excluded'");
_isExcludedFromFee[account] = excluded;
emit ExcludeFromFeesChange(account, excluded);
}
function excludeFromMaxTransactionLimit(address account, bool excluded) public onlyOwner {
require(_isExcludedFromMaxTransactionLimit[account] != excluded, "Devour: Account is already the value of 'excluded'");
_isExcludedFromMaxTransactionLimit[account] = excluded;
emit ExcludeFromMaxTransferChange(account, excluded);
}
function excludeFromMaxWalletLimit(address account, bool excluded) public onlyOwner {
require(_isExcludedFromMaxWalletLimit[account] != excluded, "Devour: Account is already the value of 'excluded'");
_isExcludedFromMaxWalletLimit[account] = excluded;
emit ExcludeFromMaxWalletChange(account, excluded);
}
function excludeFromDividends(address account, bool excluded) public onlyOwner {
require(_isExcludedFromDividends[account] != excluded, "Devour: Account is already the value of 'excluded'");
if (excluded) {
if (_rOwned[account] > 0) {
_tOwned[account] = tokenFromReflection(_rOwned[account]);
}
_isExcludedFromDividends[account] = true;
_excludedFromDividends.push(account);
} else  {
for (uint256 i = 0; i < _excludedFromDividends.length; i++) {
if (_excludedFromDividends[i] == account) {
_excludedFromDividends[i] = _excludedFromDividends[_excludedFromDividends.length - 1];
_tOwned[account] = 0;
_isExcludedFromDividends[account] = false;
_excludedFromDividends.pop();
break;
}
}
}
}
function blockAccount(address account) public onlyOwner {
uint256 currentTimestamp = _getNow();
require(!_isBlocked[account], "Devour: Account is already blocked");
if (_isLaunched) {
require(currentTimestamp.sub(_launchStartTimestamp) < _blockedTimeLimit, "Devour: Time to block accounts has expired");
}
_isBlocked[account] = true;
emit BlockedAccountChange(account, true);
}
function unblockAccount(address account) public onlyOwner {
require(_isBlocked[account], "Devour: Account is not blcoked");
_isBlocked[account] = false;
emit BlockedAccountChange(account, false);
}
function setWallets(address newLiquidityWallet, address newMarketingWallet, address newDevWallet, address newFoundationWallet) public onlyOwner {
if(liquidityWallet != newLiquidityWallet) {
require(newLiquidityWallet != address(0), "Devour: The liquidityWallet cannot be 0");
emit WalletChange(newLiquidityWallet, liquidityWallet);
liquidityWallet = newLiquidityWallet;
}
if(marketingWallet != newMarketingWallet) {
require(newMarketingWallet != address(0), "Devour: The marketingWallet cannot be 0");
emit WalletChange(newMarketingWallet, marketingWallet);
marketingWallet = newMarketingWallet;
}
if(devWallet != newDevWallet) {
require(newDevWallet != address(0), "Devour: The devWallet cannot be 0");
emit WalletChange(newDevWallet, devWallet);
devWallet = newDevWallet;
}
if(foundationWallet != newFoundationWallet) {
require(newFoundationWallet != address(0), "Devour: The foundationWallet cannot be 0");
emit WalletChange(newFoundationWallet, foundationWallet);
foundationWallet = newFoundationWallet;
}
}
function setAllFeesToZero() public onlyOwner {
_setCustomBuyTaxPeriod(_base, 0,0,0,0,0,0);
emit FeeChange('baseFees-Buy', 0,0,0,0,0,0);
_setCustomSellTaxPeriod(_base, 0,0,0,0,0,0);
emit FeeChange('baseFees-Sell', 0,0,0,0,0,0);
}
function resetAllFees() public onlyOwner {
_setCustomBuyTaxPeriod(_base, _default.liquidityFeeOnBuy, _default.marketingFeeOnBuy, _default.devFeeOnBuy, _default.foundationFeeOnBuy, _default.burnFeeOnBuy, _default.holdersFeeOnBuy);
emit FeeChange('baseFees-Buy', _default.liquidityFeeOnBuy, _default.marketingFeeOnBuy, _default.devFeeOnBuy, _default.foundationFeeOnBuy, _default.burnFeeOnBuy, _default.holdersFeeOnBuy);
_setCustomSellTaxPeriod(_base, _default.liquidityFeeOnSell, _default.marketingFeeOnSell, _default.devFeeOnSell, _default.foundationFeeOnSell, _default.burnFeeOnSell,  _default.holdersFeeOnSell);
emit FeeChange('baseFees-Sell', _default.liquidityFeeOnSell, _default.marketingFeeOnSell, _default.devFeeOnSell, _default.foundationFeeOnSell, _default.burnFeeOnSell,  _default.holdersFeeOnSell);
}
function setBaseFeesOnBuy(uint256 _liquidityFeeOnBuy, uint256 _marketingFeeOnBuy, uint256 _devFeeOnBuy, uint256 _foundationFeeOnBuy, uint256 _burnFeeOnBuy, uint256 _holdersFeeOnBuy) public onlyOwner {
_setCustomBuyTaxPeriod(_base, _liquidityFeeOnBuy, _marketingFeeOnBuy, _devFeeOnBuy, _foundationFeeOnBuy, _burnFeeOnBuy, _holdersFeeOnBuy);
emit FeeChange('baseFees-Buy', _liquidityFeeOnBuy, _marketingFeeOnBuy, _devFeeOnBuy, _foundationFeeOnBuy, _burnFeeOnBuy, _holdersFeeOnBuy);
}
function setBaseFeesOnSell(uint256 _liquidityFeeOnSell,uint256 _marketingFeeOnSell,uint256 _devFeeOnSell, uint256 _foundationFeeOnSell, uint256 _burnFeeOnSell, uint256 _holdersFeeOnSell) public onlyOwner {
_setCustomSellTaxPeriod(_base, _liquidityFeeOnSell, _marketingFeeOnSell, _devFeeOnSell, _foundationFeeOnSell, _burnFeeOnSell, _holdersFeeOnSell);
emit FeeChange('baseFees-Sell', _liquidityFeeOnSell, _marketingFeeOnSell, _devFeeOnSell, _foundationFeeOnSell, _burnFeeOnSell, _holdersFeeOnSell);
}
function setAlleyHour1BuyFees(uint256 _liquidityFeeOnBuy,uint256 _marketingFeeOnBuy, uint256 _devFeeOnBuy, uint256 _foundationFeeOnBuy, uint256 _burnFeeOnBuy, uint256 _holdersFeeOnBuy) public onlyOwner {
_setCustomBuyTaxPeriod(_alley1, _liquidityFeeOnBuy, _marketingFeeOnBuy, _devFeeOnBuy, _foundationFeeOnBuy, _burnFeeOnBuy, _holdersFeeOnBuy);
emit FeeChange('alley1Fees-Buy', _liquidityFeeOnBuy, _marketingFeeOnBuy, _devFeeOnBuy, _foundationFeeOnBuy, _burnFeeOnBuy, _holdersFeeOnBuy);
}
function setAlleyHour1SellFees(uint256 _liquidityFeeOnSell,uint256 _marketingFeeOnSell, uint256 _devFeeOnSell, uint256 _foundationFeeOnSell, uint256 _burnFeeOnSell, uint256 _holdersFeeOnSell) public onlyOwner {
_setCustomSellTaxPeriod(_alley1, _liquidityFeeOnSell, _marketingFeeOnSell, _devFeeOnSell, _foundationFeeOnSell, _burnFeeOnSell, _holdersFeeOnSell);
emit FeeChange('alley1Fees-Sell', _liquidityFeeOnSell, _marketingFeeOnSell, _devFeeOnSell, _foundationFeeOnSell, _burnFeeOnSell, _holdersFeeOnSell);
}
function setAlleyHour2BuyFees(uint256 _liquidityFeeOnBuy,uint256 _marketingFeeOnBuy, uint256 _devFeeOnBuy, uint256 _foundationFeeOnBuy, uint256 _burnFeeOnBuy, uint256 _holdersFeeOnBuy) public onlyOwner {
_setCustomBuyTaxPeriod(_alley2, _liquidityFeeOnBuy, _marketingFeeOnBuy, _devFeeOnBuy, _foundationFeeOnBuy, _burnFeeOnBuy, _holdersFeeOnBuy);
emit FeeChange('alley2Fees-Buy', _liquidityFeeOnBuy, _marketingFeeOnBuy, _devFeeOnBuy, _foundationFeeOnBuy, _burnFeeOnBuy, _holdersFeeOnBuy);
}
function setAlleyHour2SellFees(uint256 _liquidityFeeOnSell,uint256 _marketingFeeOnSell, uint256 _devFeeOnSell, uint256 _foundationFeeOnSell, uint256 _burnFeeOnSell, uint256 _holdersFeeOnSell) public onlyOwner {
_setCustomSellTaxPeriod(_alley2, _liquidityFeeOnSell, _marketingFeeOnSell,_devFeeOnSell, _foundationFeeOnSell, _burnFeeOnSell,  _holdersFeeOnSell);
emit FeeChange('alley2Fees-Sell', _liquidityFeeOnSell, _marketingFeeOnSell, _devFeeOnSell, _foundationFeeOnSell, _burnFeeOnSell, _holdersFeeOnSell);
}
function setUniswapRouter(address newAddress) public onlyOwner {
require(newAddress != address(uniswapV2Router), "Devour: The router already has that address");
emit UniswapV2RouterChange(newAddress, address(uniswapV2Router));
uniswapV2Router = IUniswapV2Router02(newAddress);
}
function setMaxTransactionAmount(uint256 newValue) public onlyOwner {
require(newValue != maxTxAmount, "Devour: Cannot update maxTxAmount to same value");
emit MaxTransactionAmountChange(newValue, maxTxAmount);
maxTxAmount = newValue;
}
function setMaxWalletAmount(uint256 newValue) public onlyOwner {
require(newValue != maxWalletAmount, "Devour: Cannot update maxWalletAmount to same value");
emit MaxWalletAmountChange(newValue, maxWalletAmount);
maxWalletAmount = newValue;
}
function setMinimumTokensBeforeSwap(uint256 newValue) public onlyOwner {
require(newValue != minimumTokensBeforeSwap, "Devour: Cannot update minimumTokensBeforeSwap to same value");
emit MinTokenAmountBeforeSwapChange(newValue, minimumTokensBeforeSwap);
minimumTokensBeforeSwap = newValue;
}
function claimEthOverflow(uint256 amount) external onlyOwner {
require(amount < address(this).balance, "Devour: Cannot send more than contract balance");
(bool success,) = address(owner()).call{value : amount}("");
if (success){
emit ClaimEthOverflow(amount);
}
}
function _approve(address owner,address spender,uint256 amount) private {
require(owner != address(0), "ERC20: approve from the zero address");
require(spender != address(0), "ERC20: approve to the zero address");
_allowances[owner][spender] = amount;
emit Approval(owner, spender, amount);
}


// Getters
function name() external view returns (string memory) {
return _name;
}
function symbol() external view returns (string memory) {
return _symbol;
}
function decimals() external view returns (uint8) {
return _decimals;
}
function totalSupply() external view override returns (uint256) {
return _tTotal;
}
function balanceOf(address account) public view override returns (uint256) {
if (_isExcludedFromDividends[account]) return _tOwned[account];
return tokenFromReflection(_rOwned[account]);
}
function totalFees() external view returns (uint256) {
return _tFeeTotal;
}
function allowance(address owner, address spender) external view override returns (uint256) {
return _allowances[owner][spender];
}
function isInAlleyHour() external view returns (bool) {
uint256 currentTimestamp = !isTradingEnabled && _tradingPausedTimestamp > _alleyHourStartTimestamp  ? _tradingPausedTimestamp : _getNow();
uint256 totalAlleyTime = _alley1.timeInPeriod.add(_alley2.timeInPeriod);
uint256 timeSinceAlley = currentTimestamp.sub(_alleyHourStartTimestamp);
if(timeSinceAlley < totalAlleyTime) {
return true;
} else {
return false;
}
}
function isInLaunch() external view returns (bool) {
uint256 currentTimestamp = !isTradingEnabled && _tradingPausedTimestamp > _launchStartTimestamp  ? _tradingPausedTimestamp : _getNow();
uint256 timeSinceLaunch = currentTimestamp.sub(_launchStartTimestamp);
uint256 totalLaunchTime =  _launch2.timeInPeriod.add(_launch3.timeInPeriod);

if(_isLaunched && (timeSinceLaunch < totalLaunchTime )) {
return true;
} else {
return false;
}
}
function getBaseBuyFees() external view returns (uint256, uint256, uint256, uint256, uint256, uint256){
return (_base.liquidityFeeOnBuy, _base.marketingFeeOnBuy, _base.devFeeOnBuy, _base.foundationFeeOnBuy, _base.burnFeeOnBuy, _base.holdersFeeOnBuy);
}
function getBaseSellFees() external view returns (uint256, uint256, uint256, uint256, uint256, uint256){
return (_base.liquidityFeeOnSell, _base.marketingFeeOnSell, _base.devFeeOnSell, _base.foundationFeeOnSell, _base.burnFeeOnSell, _base.holdersFeeOnSell);
}
function getAlley1BuyFees() external view returns (uint256, uint256, uint256, uint256, uint256, uint256){
return (_alley1.liquidityFeeOnBuy, _alley1.marketingFeeOnBuy, _alley1.devFeeOnBuy, _alley1.foundationFeeOnBuy, _alley1.burnFeeOnBuy, _alley1.holdersFeeOnBuy);
}
function getAlley1SellFees() external view returns (uint256, uint256, uint256, uint256, uint256, uint256){
return (_alley1.liquidityFeeOnSell, _alley1.marketingFeeOnSell, _alley1.devFeeOnSell, _alley1.foundationFeeOnSell, _alley1.burnFeeOnSell, _alley1.holdersFeeOnSell);
}
function getAlley2BuyFees() external view returns (uint256, uint256, uint256, uint256, uint256, uint256){
return (_alley2.liquidityFeeOnBuy, _alley2.marketingFeeOnBuy, _alley2.devFeeOnBuy, _alley2.foundationFeeOnBuy, _alley2.burnFeeOnBuy, _alley2.holdersFeeOnBuy);
}
function getAlley2SellFees() external view returns (uint256, uint256, uint256, uint256, uint256, uint256){
return (_alley2.liquidityFeeOnSell, _alley2.marketingFeeOnSell, _alley2.devFeeOnSell, _alley2.foundationFeeOnSell, _alley2.burnFeeOnSell, _alley2.holdersFeeOnSell);
}
function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
require(rAmount <= _rTotal, "Devour: Amount must be less than total reflections");
uint256 currentRate = _getRate();
return rAmount.div(currentRate);
}
function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external view returns (uint256) {
require(tAmount <= _tTotal, "Devour: Amount must be less than supply");
if (!deductTransferFee) {
(uint256 rAmount, , , , ) = _getValues(tAmount);
return rAmount;
} else {
(, uint256 rTransferAmount, , , ) = _getValues(tAmount);
return rTransferAmount;
}
}

// Main transfer
function _transfer(
address from,
address to,
uint256 amount
) private {
require(from != address(0), "ERC20: transfer from the zero address");
require(to != address(0), "ERC20: transfer to the zero address");
require(amount > 0, "Transfer amount must be greater than zero");

bool isBuyFromLp = automatedMarketMakerPairs[from];
bool isSelltoLp = automatedMarketMakerPairs[to];
bool _isInLaunch = this.isInLaunch();

uint256 currentTimestamp = !isTradingEnabled && _tradingPausedTimestamp > _launchStartTimestamp  ? _tradingPausedTimestamp : _getNow();

if(from != owner() && to != owner()) {
require(isTradingEnabled, "Devour: Trading is currently disabled.");
require(!_isBlocked[to], "Devour: Account is blocked");
require(!_isBlocked[from], "Devour: Account is blocked");
if (_isInLaunch && currentTimestamp.sub(_launchStartTimestamp) <= 300 && isBuyFromLp) {
require(currentTimestamp.sub(_buyTimesInLaunch[to]) > 60, "Devour: Cannot buy more than once per min in first 5min of launch");
}
if (!_isExcludedFromMaxTransactionLimit[to] && !_isExcludedFromMaxTransactionLimit[from]) {
require(amount <= maxTxAmount, "Devour: Buy amount exceeds the maxTxBuyAmount.");
}
if (!_isExcludedFromMaxWalletLimit[to]) {
require(balanceOf(to).add(amount) <= maxWalletAmount, "Devour: Expected wallet amount exceeds the maxWalletAmount.");
}
}

_adjustTaxes(to, from, isBuyFromLp, isSelltoLp);
bool canSwap = balanceOf(address(this)) >= minimumTokensBeforeSwap;

if (
isTradingEnabled &&
canSwap &&
!_swapping &&
_totalFee > 0 &&
automatedMarketMakerPairs[to] &&
from != liquidityWallet && to != liquidityWallet &&
from != marketingWallet && to != marketingWallet &&
from != devWallet && to != devWallet &&
from != foundationWallet && to != foundationWallet
) {
_swapping = true;
_swapAndLiquify();
_swapping = false;
}

bool takeFee = !_swapping && isTradingEnabled;

if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
takeFee = false;
}

if (_isInLaunch && currentTimestamp.sub(_launchStartTimestamp) <= 300) {
if (to != owner() && isBuyFromLp  && currentTimestamp.sub(_buyTimesInLaunch[to]) > 60) {
_buyTimesInLaunch[to] = currentTimestamp;
}
}
_tokenTransfer(from, to, amount, takeFee);
}
function _adjustTaxes(address to, address from, bool isBuyFromLp, bool isSelltoLp) private {
uint256 currentTimestamp = !isTradingEnabled && _tradingPausedTimestamp > _launchStartTimestamp  ? _tradingPausedTimestamp : _getNow();
uint256 timeSinceLaunch = currentTimestamp.sub(_launchStartTimestamp);
uint256 timeInLaunch = _launch3.timeInPeriod.add(_launch2.timeInPeriod);
uint256 timeSinceAlley = currentTimestamp.sub(_alleyHourStartTimestamp);
_liquidityFee = 0;
_marketingFee = 0;
_devFee = 0;
_foundationFee = 0;
_burnFee = 0;
_holdersFee = 0;

if (isBuyFromLp) {
_liquidityFee = _base.liquidityFeeOnBuy;
_marketingFee = _base.marketingFeeOnBuy;
_devFee = _base.devFeeOnBuy;
_foundationFee = _base.foundationFeeOnBuy;
_burnFee = _base.burnFeeOnBuy;
_holdersFee = _base.holdersFeeOnBuy;

if (timeSinceLaunch <= _launch2.timeInPeriod) {
_liquidityFee = _launch2.liquidityFeeOnBuy;
_marketingFee = _launch2.marketingFeeOnBuy;
_devFee = _launch2.devFeeOnBuy;
_foundationFee = _launch2.foundationFeeOnBuy;
_burnFee = _launch2.burnFeeOnBuy;
_holdersFee = _launch2.holdersFeeOnBuy;
}
if (timeSinceLaunch > _launch2.timeInPeriod && timeSinceLaunch <= timeInLaunch) {
_liquidityFee = _launch3.liquidityFeeOnBuy;
_marketingFee = _launch3.marketingFeeOnBuy;
_devFee = _launch3.devFeeOnBuy;
_foundationFee = _launch3.foundationFeeOnBuy;
_burnFee = _launch3.burnFeeOnBuy;
_holdersFee = _launch3.holdersFeeOnBuy;
}
if (timeSinceAlley <= _alley1.timeInPeriod) {
_liquidityFee = _alley1.liquidityFeeOnBuy;
_marketingFee = _alley1.marketingFeeOnBuy;
_devFee = _alley1.devFeeOnBuy;
_foundationFee = _alley1.foundationFeeOnBuy;
_burnFee = _alley1.burnFeeOnBuy;
_holdersFee = _alley1.holdersFeeOnBuy;
}
if (timeSinceAlley > _alley1.timeInPeriod && timeSinceAlley <= _alley1.timeInPeriod.add(_alley2.timeInPeriod)) {
_liquidityFee = _alley2.liquidityFeeOnBuy;
_marketingFee = _alley2.marketingFeeOnBuy;
_devFee = _alley2.devFeeOnBuy;
_foundationFee = _alley2.foundationFeeOnBuy;
_burnFee = _alley2.burnFeeOnBuy;
_holdersFee = _alley2.holdersFeeOnBuy;
}
}
if (isSelltoLp) {
_liquidityFee = _base.liquidityFeeOnSell;
_marketingFee = _base.marketingFeeOnSell;
_devFee = _base.devFeeOnSell;
_foundationFee = _base.foundationFeeOnSell;
_burnFee = _base.burnFeeOnSell;
_holdersFee = _base.holdersFeeOnSell;

if (timeSinceLaunch <= _launch2.timeInPeriod) {
_liquidityFee = _launch2.liquidityFeeOnSell;
_marketingFee = _launch2.marketingFeeOnSell;
_devFee = _launch2.devFeeOnSell;
_foundationFee = _launch2.foundationFeeOnSell;
_burnFee = _launch2.burnFeeOnSell;
_holdersFee = _launch2.holdersFeeOnSell;
}
if (timeSinceLaunch > _launch2.timeInPeriod && timeSinceLaunch <= timeInLaunch) {
_liquidityFee = _launch3.liquidityFeeOnSell;
_marketingFee = _launch3.marketingFeeOnSell;
_devFee = _launch3.devFeeOnSell;
_foundationFee = _launch3.foundationFeeOnSell;
_burnFee = _launch3.burnFeeOnSell;
_holdersFee = _launch3.holdersFeeOnSell;
}
if (timeSinceAlley <= _alley1.timeInPeriod) {
_liquidityFee = _alley1.liquidityFeeOnSell;
_marketingFee = _alley1.marketingFeeOnSell;
_devFee = _alley1.devFeeOnSell;
_foundationFee = _alley1.foundationFeeOnSell;
_burnFee = _alley1.burnFeeOnSell;
_holdersFee = _alley1.holdersFeeOnSell;
}
if (timeSinceAlley > _alley1.timeInPeriod && timeSinceAlley <= _alley1.timeInPeriod.add(_alley2.timeInPeriod)) {
_liquidityFee = _alley2.liquidityFeeOnSell;
_marketingFee = _alley2.marketingFeeOnSell;
_devFee = _alley2.devFeeOnSell;
_foundationFee = _alley2.foundationFeeOnSell;
_burnFee = _alley2.burnFeeOnSell;
_holdersFee = _alley2.holdersFeeOnSell;
}
}
_totalFee = _liquidityFee.add(_marketingFee).add(_devFee).add(_foundationFee).add(_burnFee).add(_holdersFee);
emit FeesApplied(_liquidityFee, _marketingFee, _devFee, _foundationFee, _burnFee, _holdersFee, _totalFee);
}
function _swapAndLiquify() private {
uint256 contractBalance = balanceOf(address(this));
uint256 initialEthBalance = address(this).balance;

uint256 amountToLiquify = contractBalance.mul(_liquidityFee).div(_totalFee).div(2);
uint256 amountToSwap =  contractBalance.sub(amountToLiquify);

_swapTokensForEth(amountToSwap);

uint256 EthBalanceAfterSwap = address(this).balance.sub(initialEthBalance);

uint256 totalEthFee = _totalFee.sub(_liquidityFee.div(2));
uint256 amountEthLiquidity = EthBalanceAfterSwap.mul(_liquidityFee).div(totalEthFee).div(2);
uint256 amountEthMarketing = EthBalanceAfterSwap.mul(_marketingFee).div(totalEthFee);
uint256 amountEthFoundation = EthBalanceAfterSwap.mul(_foundationFee).div(totalEthFee);
uint256 amountEthDev = EthBalanceAfterSwap.sub(amountEthLiquidity.add(amountEthMarketing).add(amountEthFoundation));

//payable(marketingWallet).transfer(amountEthMarketing);
//payable(foundationWallet).transfer(amountEthFoundation);
//payable(devWallet).transfer(amountEthDev);

//if (amountToLiquify > 0) {
//_addLiquidity(amountToLiquify, amountEthLiquidity);
//emit SwapAndLiquify(amountToSwap, amountEthLiquidity, amountToLiquify);
//}
}
function _swapTokensForEth(uint256 tokenAmount) private {
address[] memory path = new address[](2);
path[0] = address(this);
path[1] = uniswapV2Router.WETH();
_approve(address(this), address(uniswapV2Router), tokenAmount);
uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
tokenAmount,
0, // accept any amount of ETH
path,
address(this),
block.timestamp + 3600
);
}
function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
_approve(address(this), address(uniswapV2Router), tokenAmount);
uniswapV2Router.addLiquidityETH{value: ethAmount}(
address(this),
tokenAmount,
0, // slippage is unavoidable
0, // slippage is unavoidable
liquidityWallet,
block.timestamp + 3600
);
}
function _tokenTransfer(address sender,address recipient, uint256 amount, bool takeFee) private {
if (_isExcludedFromDividends[sender] && !_isExcludedFromDividends[recipient]) {
_transferFromExcluded(sender, recipient, amount);
}
else if (!_isExcludedFromDividends[sender] && _isExcludedFromDividends[recipient]) {
_transferToExcluded(sender, recipient, amount);
}
else if (_isExcludedFromDividends[sender] && _isExcludedFromDividends[recipient]) {
_transferBothExcluded(sender, recipient, amount);
}
else {
_transferStandard(sender, recipient, amount);
}
}
function _transferStandard(address sender,address recipient, uint256 tAmount) private {
(uint256 rAmount,uint256 rTransferAmount,uint256 rFee,uint256 tTransferAmount,uint256 tFee) = _getValues(tAmount);
_rOwned[sender] = _rOwned[sender].sub(rAmount);
_rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
_takeContractFees(tAmount, tFee);
_reflectFee(rFee, tFee);
emit Transfer(sender, recipient, tTransferAmount);
}
function _transferToExcluded(address sender,address recipient,uint256 tAmount) private {
(uint256 rAmount,uint256 rTransferAmount,uint256 rFee,uint256 tTransferAmount,uint256 tFee) = _getValues(tAmount);
_rOwned[sender] = _rOwned[sender].sub(rAmount);
_tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
_rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
_takeContractFees(tAmount, tFee);
_reflectFee(rFee, tFee);
emit Transfer(sender, recipient, tTransferAmount);
}
function _transferFromExcluded(address sender, address recipient,uint256 tAmount) private {
(uint256 rAmount,uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
_tOwned[sender] = _tOwned[sender].sub(tAmount);
_rOwned[sender] = _rOwned[sender].sub(rAmount);
_rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
_takeContractFees(tAmount, tFee);
_reflectFee(rFee, tFee);
emit Transfer(sender, recipient, tTransferAmount);
}
function _transferBothExcluded(address sender,address recipient,uint256 tAmount) private {
(uint256 rAmount,uint256 rTransferAmount,uint256 rFee,uint256 tTransferAmount,uint256 tFee) = _getValues(tAmount);
_tOwned[sender] = _tOwned[sender].sub(tAmount);
_rOwned[sender] = _rOwned[sender].sub(rAmount);
_tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
_rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
_takeContractFees(tAmount, tFee);
_reflectFee(rFee, tFee);
emit Transfer(sender, recipient, tTransferAmount);
}
function _reflectFee(uint256 rFee, uint256 tFee) private {
_rTotal = _rTotal.sub(rFee);
_tFeeTotal = _tFeeTotal.add(tFee);
}
function _getValues(uint256 tAmount) private view returns (uint256,uint256,uint256,uint256,uint256){
(uint256 tTransferAmount,uint256 tFee) = _getTValues(tAmount);
(uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount,tFee,_getRate());
return (rAmount,rTransferAmount,rFee,tTransferAmount,tFee);
}
function _getTValues(uint256 tAmount) private view returns (uint256,uint256){
uint256 tFee = tAmount.mul(_totalFee).div(100);
uint256 tTransferAmount = tAmount.sub(tFee);
return (tTransferAmount, tFee);
}
function _getRValues(
uint256 tAmount,
uint256 tFee,
uint256 currentRate
) private pure returns ( uint256, uint256, uint256 ) {
uint256 rAmount = tAmount.mul(currentRate);
uint256 rFee = tFee.mul(currentRate);
uint256 rTransferAmount = rAmount.sub(rFee);
return (rAmount, rTransferAmount, rFee);
}
function _getRate() private view returns (uint256) {
(uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
return rSupply.div(tSupply);
}
function _getCurrentSupply() private view returns (uint256, uint256) {
uint256 rSupply = _rTotal;
uint256 tSupply = _tTotal;
for (uint256 i = 0; i < _excludedFromDividends.length; i++) {
if (
_rOwned[_excludedFromDividends[i]] > rSupply ||
_tOwned[_excludedFromDividends[i]] > tSupply
) return (_rTotal, _tTotal);
rSupply = rSupply.sub(_rOwned[_excludedFromDividends[i]]);
tSupply = tSupply.sub(_tOwned[_excludedFromDividends[i]]);
}
if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
return (rSupply, tSupply);
}
function _takeContractFees(uint256 tAmount, uint256 tFee) private {
uint256 currentRate = _getRate();
uint256 rFee = tFee.mul(currentRate);
uint256 tBurnFee = tAmount.mul(_burnFee).div(100);
uint256 rBurnFee = tBurnFee.mul(currentRate);

_rOwned[address(this)] = _rOwned[address(this)].add(rFee);
if (_isExcludedFromDividends[address(this)]) {
_tOwned[address(this)] = _tOwned[address(this)].add(tFee);
}

if (tBurnFee > 0) {
_rOwned[address(this)] = _rOwned[address(this)].sub(rBurnFee);
_rOwned[address(0)] = _rOwned[address(0)].add(rBurnFee);
emit Transfer(address(this), address(0), tBurnFee);
emit TokenBurn(_burnFee, tBurnFee, rBurnFee);

if (_isExcludedFromDividends[address(this)]) {
_tOwned[address(this)] = _tOwned[address(this)].sub(tBurnFee);
}
if (_isExcludedFromDividends[address(0)]) {
_tOwned[address(0)] = _tOwned[address(0)].add(tBurnFee);
}
}
}
function _setCustomSellTaxPeriod(CustomTaxPeriod storage map,
uint256 _liquidityFeeOnSell,
uint256 _marketingFeeOnSell,
uint256 _devFeeOnSell,
uint256 _foundationFeeOnSell,
uint256 _burnFeeOnSell,
uint256 _holdersFeeOnSell
) private {
if (map.liquidityFeeOnSell != _liquidityFeeOnSell) {
emit CustomTaxPeriodChange(_liquidityFeeOnSell, map.liquidityFeeOnSell, 'liquidityFeeOnSell', map.periodName);
map.liquidityFeeOnSell = _liquidityFeeOnSell;
}
if (map.marketingFeeOnSell != _marketingFeeOnSell) {
emit CustomTaxPeriodChange(_marketingFeeOnSell, map.marketingFeeOnSell, 'marketingFeeOnSell', map.periodName);
map.marketingFeeOnSell = _marketingFeeOnSell;
}
if (map.devFeeOnSell != _devFeeOnSell) {
emit CustomTaxPeriodChange(_devFeeOnSell, map.devFeeOnSell, 'devFeeOnSell', map.periodName);
map.devFeeOnSell = _devFeeOnSell;
}
if (map.foundationFeeOnSell != _foundationFeeOnSell) {
emit CustomTaxPeriodChange(_foundationFeeOnSell, map.foundationFeeOnSell, 'foundationFeeOnSell', map.periodName);
map.foundationFeeOnSell = _foundationFeeOnSell;
}
if (map.burnFeeOnSell != _burnFeeOnSell) {
emit CustomTaxPeriodChange(_burnFeeOnSell, map.burnFeeOnSell, 'burnFeeOnSell', map.periodName);
map.burnFeeOnSell = _burnFeeOnSell;
}
if (map.holdersFeeOnSell != _holdersFeeOnSell) {
emit CustomTaxPeriodChange(_holdersFeeOnSell, map.holdersFeeOnSell, 'holdersFeeOnSell', map.periodName);
map.holdersFeeOnSell = _holdersFeeOnSell;
}
}
function _setCustomBuyTaxPeriod(CustomTaxPeriod storage map,
uint256 _liquidityFeeOnBuy,
uint256 _marketingFeeOnBuy,
uint256 _devFeeOnBuy,
uint256 _foundationFeeOnBuy,
uint256 _burnFeeOnBuy,
uint256 _holdersFeeOnBuy
) private {
if (map.liquidityFeeOnBuy != _liquidityFeeOnBuy) {
emit CustomTaxPeriodChange(_liquidityFeeOnBuy, map.liquidityFeeOnBuy, 'liquidityFeeOnBuy', map.periodName);
map.liquidityFeeOnBuy = _liquidityFeeOnBuy;
}
if (map.marketingFeeOnBuy != _marketingFeeOnBuy) {
emit CustomTaxPeriodChange(_marketingFeeOnBuy, map.marketingFeeOnBuy, 'marketingFeeOnBuy', map.periodName);
map.marketingFeeOnBuy = _marketingFeeOnBuy;
}
if (map.devFeeOnBuy != _devFeeOnBuy) {
emit CustomTaxPeriodChange(_devFeeOnBuy, map.devFeeOnBuy, 'devFeeOnBuy', map.periodName);
map.devFeeOnBuy = _devFeeOnBuy;
}
if (map.foundationFeeOnBuy != _foundationFeeOnBuy) {
emit CustomTaxPeriodChange(_foundationFeeOnBuy, map.foundationFeeOnBuy, 'foundationFeeOnBuy', map.periodName);
map.foundationFeeOnBuy = _foundationFeeOnBuy;
}
if (map.burnFeeOnBuy != _burnFeeOnBuy) {
emit CustomTaxPeriodChange(_burnFeeOnBuy, map.burnFeeOnBuy, 'burnFeeOnBuy', map.periodName);
map.burnFeeOnBuy = _burnFeeOnBuy;
}
if (map.holdersFeeOnBuy != _holdersFeeOnBuy) {
emit CustomTaxPeriodChange(_holdersFeeOnBuy, map.holdersFeeOnBuy, 'holdersFeeOnBuy', map.periodName);
map.holdersFeeOnBuy = _holdersFeeOnBuy;
}
}
}
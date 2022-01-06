/**
 *Submitted for verification at BscScan.com on 2022-01-06
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

abstract contract Context {
	function _msgSender() internal view virtual returns (address) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns (bytes calldata) {
		this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
		return msg.data;
	}
}

interface IUniswapV2Factory {
	event PairCreated(address indexed token0, address indexed token1, address pair, uint);

	function feeTo() external view returns (address);
	function feeToSetter() external view returns (address);

	function getPair(address tokenA, address tokenB) external view returns (address pair);
	function allPairs(uint) external view returns (address pair);
	function allPairsLength() external view returns (uint);

	function createPair(address tokenA, address tokenB) external returns (address pair);

	function setFeeTo(address) external;
	function setFeeToSetter(address) external;
}

interface IUniswapV2Router01 {
	function factory() external pure returns (address);
	function WETH() external pure returns (address);

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
	function addLiquidityETH(
		address token,
		uint amountTokenDesired,
		uint amountTokenMin,
		uint amountETHMin,
		address to,
		uint deadline
	) external payable returns (uint amountToken, uint amountETH, uint liquidity);
	function removeLiquidity(
		address tokenA,
		address tokenB,
		uint liquidity,
		uint amountAMin,
		uint amountBMin,
		address to,
		uint deadline
	) external returns (uint amountA, uint amountB);
	function removeLiquidityETH(
		address token,
		uint liquidity,
		uint amountTokenMin,
		uint amountETHMin,
		address to,
		uint deadline
	) external returns (uint amountToken, uint amountETH);
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
	function swapExactTokensForTokens(
		uint amountIn,
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external returns (uint[] memory amounts);
	function swapTokensForExactTokens(
		uint amountOut,
		uint amountInMax,
		address[] calldata path,
		address to,
		uint deadline
	) external returns (uint[] memory amounts);
	function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
	external
	payable
	returns (uint[] memory amounts);
	function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
	external
	returns (uint[] memory amounts);
	function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
	external
	returns (uint[] memory amounts);
	function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
	external
	payable
	returns (uint[] memory amounts);

	function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
	function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
	function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
	function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
	function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
	function removeLiquidityETHSupportingFeeOnTransferTokens(
		address token,
		uint liquidity,
		uint amountTokenMin,
		uint amountETHMin,
		address to,
		uint deadline
	) external returns (uint amountETH);
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
	function swapExactETHForTokensSupportingFeeOnTransferTokens(
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external payable;
	function swapExactTokensForETHSupportingFeeOnTransferTokens(
		uint amountIn,
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external;
}

interface IUniswapV2Pair {
	event Approval(address indexed owner, address indexed spender, uint value);
	event Transfer(address indexed from, address indexed to, uint value);

	function name() external pure returns (string memory);
	function symbol() external pure returns (string memory);
	function decimals() external pure returns (uint8);
	function totalSupply() external view returns (uint);
	function balanceOf(address owner) external view returns (uint);
	function allowance(address owner, address spender) external view returns (uint);

	function approve(address spender, uint value) external returns (bool);
	function transfer(address to, uint value) external returns (bool);
	function transferFrom(address from, address to, uint value) external returns (bool);

	function DOMAIN_SEPARATOR() external view returns (bytes32);
	function PERMIT_TYPEHASH() external pure returns (bytes32);
	function nonces(address owner) external view returns (uint);

	function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

	event Mint(address indexed sender, uint amount0, uint amount1);
	event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
	event Swap(
		address indexed sender,
		uint amount0In,
		uint amount1In,
		uint amount0Out,
		uint amount1Out,
		address indexed to
	);
	event Sync(uint112 reserve0, uint112 reserve1);

	function MINIMUM_LIQUIDITY() external pure returns (uint);
	function factory() external view returns (address);
	function token0() external view returns (address);
	function token1() external view returns (address);
	function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
	function price0CumulativeLast() external view returns (uint);
	function price1CumulativeLast() external view returns (uint);
	function kLast() external view returns (uint);
	function mint(address to) external returns (uint liquidity);
	function burn(address to) external returns (uint amount0, uint amount1);
	function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
	function skim(address to) external;
	function sync() external;
	function initialize(address, address) external;
}

interface IERC20 {
	function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external returns (bool);

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
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

	function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		require(b <= a, errorMessage);
		uint256 c = a - b;

		return c;
	}

	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		// Gas optimization: this is cheaper than requiring 'a' not being zero, but the
		// benefit is lost if 'b' is also tested.
		// See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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

	function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		require(b > 0, errorMessage);
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn't hold

		return c;
	}

	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
		return mod(a, b, "SafeMath: modulo by zero");
	}

	function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

library IterableMapping {
	struct Map {
		address[] keys;
		mapping(address => uint) values;
		mapping(address => uint) indexOf;
		mapping(address => bool) inserted;
	}

	function get(Map storage map, address key) public view returns (uint) {
		return map.values[key];
	}

	function getIndexOfKey(Map storage map, address key) public view returns (int) {
		if(!map.inserted[key]) {
			return -1;
		}
		return int(map.indexOf[key]);
	}

	function getKeyAtIndex(Map storage map, uint index) public view returns (address) {
		return map.keys[index];
	}

	function size(Map storage map) public view returns (uint) {
		return map.keys.length;
	}

	function set(Map storage map, address key, uint val) public {
		if (map.inserted[key]) {
			map.values[key] = val;
		} else {
			map.inserted[key] = true;
			map.values[key] = val;
			map.indexOf[key] = map.keys.length;
			map.keys.push(key);
		}
	}

	function remove(Map storage map, address key) public {
		if (!map.inserted[key]) {
			return;
		}

		delete map.inserted[key];
		delete map.values[key];

		uint index = map.indexOf[key];
		uint lastIndex = map.keys.length - 1;
		address lastKey = map.keys[lastIndex];

		map.indexOf[lastKey] = index;
		delete map.indexOf[key];

		map.keys[index] = lastKey;
		map.keys.pop();
	}
}

contract Ownable is Context {
	address private _owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	constructor () public {
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
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		emit OwnershipTransferred(_owner, newOwner);
		_owner = newOwner;
	}
}

contract Sugarland is Context, IERC20, Ownable {
	using SafeMath for uint256;
	using Address for address;
	using IterableMapping for IterableMapping.Map;

	IUniswapV2Router02 public uniswapV2Router;
	address public immutable uniswapV2Pair;

	IterableMapping.Map private holdersMap;

	string private constant _name = "SUGARLAND";
	string private constant _symbol = "SUGAR";
	uint8 private constant _decimals = 9;

	mapping (address => uint256) private _rOwned;
	mapping (address => uint256) private _tOwned;
	mapping (address => mapping (address => uint256)) private _allowances;

	uint256 private constant MAX = ~uint256(0);
	uint256 private _tTotal = 1000000000 * 10**9;
	uint256 private _rTotal = (MAX - (MAX % _tTotal));
	uint256 private _tFeeTotal;

	bool public isTradingEnabled;
	uint256 private _tradingPausedTimestamp;

	// max wallet is 2.0% of _tTotal
	uint256 public maxWalletAmount = _tTotal * 200 / 10000;
	// max buy and sell tx is 0.1% of _tTotal
	uint256 public maxTxAmount = _tTotal * 10 / 10000;

	bool private _swapping;
	uint256 public minimumTokensBeforeSwap =  500000 * (10**9);

	address public marketingWallet;
	address public liquidityWallet;

	struct CustomTaxPeriod {
		bytes23 periodName;
		uint8 blocksInPeriod;
		uint256 timeInPeriod;
		uint256 liquidityFeeOnBuy;
		uint256 liquidityFeeOnSell;
		uint256 marketingFeeOnBuy;
		uint256 marketingFeeOnSell;
		uint256 holdersFeeOnBuy;
		uint256 holdersFeeOnSell;
	}

	// Launch taxes
	bool private _isLaunched;
	uint256 private _launchStartTimestamp;
	uint256 private _launchBlockNumber;
	CustomTaxPeriod private _launch1 = CustomTaxPeriod('launch1',3,0,3,100,5,0,2,0);
	CustomTaxPeriod private _launch2 = CustomTaxPeriod('launch2',0,3600,3,5,5,15,2,10);
	CustomTaxPeriod private _launch3 = CustomTaxPeriod('launch3',0,82800,3,5,5,10,2,10);

	// Base taxes
	CustomTaxPeriod private _default = CustomTaxPeriod('default',0,0,3,3,5,6,2,3);
	CustomTaxPeriod private _base = CustomTaxPeriod('base',0,0,3,3,5,6,2,3);

	// Sugarland Hour taxes
	uint256 private _sugarRushHourStartTimestamp = 0;
	CustomTaxPeriod private _sugarRush1 = CustomTaxPeriod('sugarRush1',0,3600,0,5,0,15,3,10);
	CustomTaxPeriod private _sugarRush2 = CustomTaxPeriod('sugarRush2',0,3600,3,4,5,10,2,6);

	uint256 private _blockedTimeLimit = 86400;
	mapping (address => bool) private _isExcludedFromFee;
	mapping (address => bool) private _isAllowedToTradeWhenDisabled;
	mapping (address => bool) private _isExcludedFromDividends;
	address[] private _excludedFromDividends;
	mapping (address => bool) private _isExcludedFromMaxTransactionLimit;
	mapping (address => bool) private _isExcludedFromMaxWalletLimit;
	mapping (address => bool) private _isBlocked;
	mapping (address => bool) public automatedMarketMakerPairs;
	mapping (address => uint256) private _buyTimesInLaunch;

	uint256 private _liquidityFee;
	uint256 private _marketingFee;
	uint256 private _holdersFee;
	uint256 private _totalFee;

	event AutomatedMarketMakerPairChange(address indexed pair, bool indexed value);
	event UniswapV2RouterChange(address indexed newAddress, address indexed oldAddress);
	event WalletChange(address indexed newWallet, address indexed oldWallet);
	event FeeChange(string indexed identifier, uint256 liquidityFee, uint256 marketingFee, uint256 holdersFee);
	event CustomTaxPeriodChange(uint256 indexed newValue, uint256 indexed oldValue, string indexed taxType, bytes23 period);
	event BlockedAccountChange(address indexed holder, bool indexed status);
	event SugarRushHourChange(bool indexed newValue, bool indexed oldValue);
	event MaxTransactionAmountChange(uint256 indexed newValue, uint256 indexed oldValue);
	event MaxWalletAmountChange(uint256 indexed newValue, uint256 indexed oldValue);
	event ExcludeFromMaxTransferChange(address indexed account, bool isExcluded);
	event ExcludeFromMaxWalletChange(address indexed account, bool isExcluded);
	event ExcludeFromFeesChange(address indexed account, bool isExcluded);
	event ExcludeFromDividendsChange(address indexed account, bool isExcluded);
	event MinTokenAmountBeforeSwapChange(uint256 indexed newValue, uint256 indexed oldValue);
	event DividendsSent(uint256 tokensForHolders);
	event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived,uint256 tokensIntoLiqudity);
	event ClaimBNBOverflow(uint256 amount);
	event AllowedWhenTradingDisabledChange(address indexed account, bool isExcluded);
	event FeesApplied(address from, address to, uint256 liquidityFee, uint256 marketingFee, uint256 holdersFee, uint256 totalFee);

	constructor() payable {
		liquidityWallet = owner();
		marketingWallet = owner();

		IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); // Mainnet
		address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
		uniswapV2Router = _uniswapV2Router;
		uniswapV2Pair = _uniswapV2Pair;
		_setAutomatedMarketMakerPair(_uniswapV2Pair, true);

		_isExcludedFromFee[owner()] = true;
		_isExcludedFromFee[address(this)] = true;

		excludeFromDividends(address(0), true);
		excludeFromDividends(address(_uniswapV2Router), true);
		excludeFromDividends(address(uniswapV2Pair), true);

		_isAllowedToTradeWhenDisabled[owner()] = true;

		_isExcludedFromMaxTransactionLimit[address(this)] = true;

		_isExcludedFromMaxWalletLimit[_uniswapV2Pair] = true;
		_isExcludedFromMaxWalletLimit[address(uniswapV2Router)] = true;
		_isExcludedFromMaxWalletLimit[address(this)] = true;
		_isExcludedFromMaxWalletLimit[owner()] = true;

		_rOwned[owner()] = _rTotal;
		emit Transfer(address(0), owner(), _tTotal);
	}

	receive() external payable {}

	// Setter
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
	function _approve(address owner,address spender,uint256 amount) private {
		require(owner != address(0), "ERC20: approve from the zero address");
		require(spender != address(0), "ERC20: approve to the zero address");
		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
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
		require(this.isInLaunch(), "Sugarland: Launch is not set");
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
	function allowTradingWhenDisabled(address account, bool allowed) public onlyOwner {
		_isAllowedToTradeWhenDisabled[account] = allowed;
		emit AllowedWhenTradingDisabledChange(account, allowed);
	}
	function setSugarRushHour() public onlyOwner {
		require(!this.isInSugarRushHour(), "Sugarland: SugarRush Hour is already set");
		require(isTradingEnabled, "Sugarland: Trading must be enabled first");
		require(!this.isInLaunch(), "Sugarland: Must not be in launch period");
		emit SugarRushHourChange(true, false);
		_sugarRushHourStartTimestamp = _getNow();
	}
	function cancelSugarRushHour() public onlyOwner {
		require(this.isInSugarRushHour(), "Sugarland: SugarRush Hour is not set");
		emit SugarRushHourChange(false, true);
		_sugarRushHourStartTimestamp = 0;
	}
	function _setAutomatedMarketMakerPair(address pair, bool value) private {
		require(automatedMarketMakerPairs[pair] != value, "Sugarland: Automated market maker pair is already set to that value");
		automatedMarketMakerPairs[pair] = value;
		emit AutomatedMarketMakerPairChange(pair, value);
	}
	function excludeFromFees(address account, bool excluded) public onlyOwner {
		require(_isExcludedFromFee[account] != excluded, "Sugarland: Account is already the value of 'excluded'");
		_isExcludedFromFee[account] = excluded;
		emit ExcludeFromFeesChange(account, excluded);
	}
	function excludeFromDividends(address account, bool excluded) public onlyOwner {
		require(_isExcludedFromDividends[account] != excluded, "Sugarland: Account is already the value of 'excluded'");
		if(excluded) {
			if(_rOwned[account] > 0) {
				_tOwned[account] = tokenFromReflection(_rOwned[account]);
			}
			_isExcludedFromDividends[account] = excluded;
			_excludedFromDividends.push(account);
		} else {
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
		emit ExcludeFromDividendsChange(account, excluded);
	}
	function excludeFromMaxTransactionLimit(address account, bool excluded) public onlyOwner {
		require(_isExcludedFromMaxTransactionLimit[account] != excluded, "Sugarland: Account is already the value of 'excluded'");
		_isExcludedFromMaxTransactionLimit[account] = excluded;
		emit ExcludeFromMaxTransferChange(account, excluded);
	}
	function excludeFromMaxWalletLimit(address account, bool excluded) public onlyOwner {
		require(_isExcludedFromMaxWalletLimit[account] != excluded, "Sugarland: Account is already the value of 'excluded'");
		_isExcludedFromMaxWalletLimit[account] = excluded;
		emit ExcludeFromMaxWalletChange(account, excluded);
	}
	function blockAccount(address account) public onlyOwner {
		uint256 currentTimestamp = _getNow();
		require(!_isBlocked[account], "Sugarland: Account is already blocked");
		if (_isLaunched) {
			require(currentTimestamp.sub(_launchStartTimestamp) < _blockedTimeLimit, "Sugarland: Time to block accounts has expired");
		}
		_isBlocked[account] = true;
		emit BlockedAccountChange(account, true);
	}
	function unblockAccount(address account) public onlyOwner {
		require(_isBlocked[account], "Sugarland: Account is not blcoked");
		_isBlocked[account] = false;
		emit BlockedAccountChange(account, false);
	}
	function setWallets(address newLiquidityWallet, address newMarketingWallet) public onlyOwner {
		if(liquidityWallet != newLiquidityWallet) {
			require(newLiquidityWallet != address(0), "Sugarland: The liquidityWallet cannot be 0");
			emit WalletChange(newLiquidityWallet, liquidityWallet);
			liquidityWallet = newLiquidityWallet;
		}
		if(marketingWallet != newMarketingWallet) {
			require(newMarketingWallet != address(0), "Sugarland: The marketingWallet cannot be 0");
			emit WalletChange(newMarketingWallet, marketingWallet);
			marketingWallet = newMarketingWallet;
		}
	}
	function setAllFeesToZero() public onlyOwner {
		_setCustomBuyTaxPeriod(_base, 0, 0, 0);
		emit FeeChange('baseFees-Buy', 0, 0, 0);
		_setCustomSellTaxPeriod(_base, 0, 0, 0);
		emit FeeChange('baseFees-Sell', 0, 0, 0);
	}
	function resetAllFees() public onlyOwner {
		_setCustomBuyTaxPeriod(_base, _default.liquidityFeeOnBuy, _default.marketingFeeOnBuy,  _default.holdersFeeOnBuy);
		emit FeeChange('baseFees-Buy', _default.liquidityFeeOnBuy, _default.marketingFeeOnBuy, _default.holdersFeeOnBuy);
		_setCustomSellTaxPeriod(_base, _default.liquidityFeeOnSell, _default.marketingFeeOnSell, _default.holdersFeeOnSell);
		emit FeeChange('baseFees-Sell', _default.liquidityFeeOnSell, _default.marketingFeeOnSell, _default.holdersFeeOnSell);
	}
	//Base fees
	function setBaseFeesOnBuy(uint256 _liquidityFeeOnBuy, uint256 _marketingFeeOnBuy, uint256 _holdersFeeOnBuy) public onlyOwner {
		_setCustomBuyTaxPeriod(_base, _liquidityFeeOnBuy, _marketingFeeOnBuy, _holdersFeeOnBuy);
		emit FeeChange('baseFees-Buy', _liquidityFeeOnBuy, _marketingFeeOnBuy, _holdersFeeOnBuy);
	}
	function setBaseFeesOnSell(uint256 _liquidityFeeOnSell,uint256 _marketingFeeOnSell, uint256 _holdersFeeOnSell) public onlyOwner {
		_setCustomSellTaxPeriod(_base, _liquidityFeeOnSell, _marketingFeeOnSell, _holdersFeeOnSell);
		emit FeeChange('baseFees-Sell', _liquidityFeeOnSell, _marketingFeeOnSell, _holdersFeeOnSell);
	}
	//Launch2 Fees
	function setLaunch2FeesOnBuy(uint256 _liquidityFeeOnBuy, uint256 _marketingFeeOnBuy, uint256 _holdersFeeOnBuy) public onlyOwner {
		_setCustomBuyTaxPeriod(_launch2, _liquidityFeeOnBuy, _marketingFeeOnBuy, _holdersFeeOnBuy);
		emit FeeChange('launch2Fees-Buy', _liquidityFeeOnBuy, _marketingFeeOnBuy, _holdersFeeOnBuy);
	}
	function setLaunch2FeesOnSell(uint256 _liquidityFeeOnSell,uint256 _marketingFeeOnSell, uint256 _holdersFeeOnSell) public onlyOwner {
		_setCustomSellTaxPeriod(_launch2, _liquidityFeeOnSell, _marketingFeeOnSell, _holdersFeeOnSell);
		emit FeeChange('launch2Fees-Sell', _liquidityFeeOnSell, _marketingFeeOnSell, _holdersFeeOnSell);
	}
	//Launch3 Fees
	function setLaunch3FeesOnBuy(uint256 _liquidityFeeOnBuy, uint256 _marketingFeeOnBuy, uint256 _holdersFeeOnBuy) public onlyOwner {
		_setCustomBuyTaxPeriod(_launch3, _liquidityFeeOnBuy, _marketingFeeOnBuy, _holdersFeeOnBuy);
		emit FeeChange('launch3Fees-Buy', _liquidityFeeOnBuy, _marketingFeeOnBuy, _holdersFeeOnBuy);
	}
	function setLaunch3FeesOnSell(uint256 _liquidityFeeOnSell,uint256 _marketingFeeOnSell, uint256 _holdersFeeOnSell) public onlyOwner {
		_setCustomSellTaxPeriod(_launch3, _liquidityFeeOnSell, _marketingFeeOnSell, _holdersFeeOnSell);
		emit FeeChange('launch3Fees-Sell', _liquidityFeeOnSell, _marketingFeeOnSell, _holdersFeeOnSell);
	}
	//SugarRush1 Fees
	function setSugarRushHour1BuyFees(uint256 _liquidityFeeOnBuy,uint256 _marketingFeeOnBuy, uint256 _holdersFeeOnBuy) public onlyOwner {
		_setCustomBuyTaxPeriod(_sugarRush1, _liquidityFeeOnBuy, _marketingFeeOnBuy, _holdersFeeOnBuy);
		emit FeeChange('sugarRush1Fees-Buy', _liquidityFeeOnBuy, _marketingFeeOnBuy, _holdersFeeOnBuy);
	}
	function setSugarRushHour1SellFees(uint256 _liquidityFeeOnSell,uint256 _marketingFeeOnSell, uint256 _holdersFeeOnSell) public onlyOwner {
		_setCustomSellTaxPeriod(_sugarRush1, _liquidityFeeOnSell, _marketingFeeOnSell, _holdersFeeOnSell);
		emit FeeChange('sugarRush1Fees-Sell', _liquidityFeeOnSell, _marketingFeeOnSell, _holdersFeeOnSell);
	}
	//SugarRush2 Fees
	function setSugarRushHour2BuyFees(uint256 _liquidityFeeOnBuy,uint256 _marketingFeeOnBuy, uint256 _holdersFeeOnBuy) public onlyOwner {
		_setCustomBuyTaxPeriod(_sugarRush2, _liquidityFeeOnBuy, _marketingFeeOnBuy, _holdersFeeOnBuy);
		emit FeeChange('sugarRush2Fees-Buy', _liquidityFeeOnBuy, _marketingFeeOnBuy, _holdersFeeOnBuy);
	}
	function setSugarRushHour2SellFees(uint256 _liquidityFeeOnSell,uint256 _marketingFeeOnSell, uint256 _holdersFeeOnSell) public onlyOwner {
		_setCustomSellTaxPeriod(_sugarRush2, _liquidityFeeOnSell, _marketingFeeOnSell, _holdersFeeOnSell);
		emit FeeChange('sugarRush2Fees-Sell', _liquidityFeeOnSell, _marketingFeeOnSell, _holdersFeeOnSell);
	}
	function setUniswapRouter(address newAddress) public onlyOwner {
		require(newAddress != address(uniswapV2Router), "Sugarland: The router already has that address");
		emit UniswapV2RouterChange(newAddress, address(uniswapV2Router));
		uniswapV2Router = IUniswapV2Router02(newAddress);
	}
	function setMaxTransactionAmount(uint256 newValue) public onlyOwner {
		require(newValue != maxTxAmount, "Sugarland: Cannot update maxTxAmount to same value");
		emit MaxTransactionAmountChange(newValue, maxTxAmount);
		maxTxAmount = newValue;
	}
	function setMaxWalletAmount(uint256 newValue) public onlyOwner {
		require(newValue != maxWalletAmount, "Sugarland: Cannot update maxWalletAmount to same value");
		emit MaxWalletAmountChange(newValue, maxWalletAmount);
		maxWalletAmount = newValue;
	}
	function setMinimumTokensBeforeSwap(uint256 newValue) public onlyOwner {
		require(newValue != minimumTokensBeforeSwap, "Sugarland: Cannot update minimumTokensBeforeSwap to same value");
		emit MinTokenAmountBeforeSwapChange(newValue, minimumTokensBeforeSwap);
		minimumTokensBeforeSwap = newValue;
	}
	function claimBNBOverflow(uint256 amount) external onlyOwner {
		require(amount < address(this).balance, "Sugarland: Cannot send more than contract balance");
		(bool success,) = address(owner()).call{value : amount}("");
		if (success){
			emit ClaimBNBOverflow(amount);
		}
	}

	// Getters
	function name() public view returns (string memory) {
		return _name;
	}
	function symbol() public view returns (string memory) {
		return _symbol;
	}
	function decimals() public view virtual returns (uint8) {
		return _decimals;
	}
	function totalSupply() public view override returns (uint256) {
		return _tTotal;
	}
	function balanceOf(address account) public view override returns (uint256) {
		if (_isExcludedFromDividends[account]) return _tOwned[account];
		return tokenFromReflection(_rOwned[account]);
	}
	function totalFees() public view returns (uint256) {
		return _tFeeTotal;
	}
	function allowance(address owner, address spender) external view override returns (uint256) {
		return _allowances[owner][spender];
	}
	function timeSinceLastSugarRushHour() external view returns(uint256){
		uint256 currentTimestamp = !isTradingEnabled && _tradingPausedTimestamp > _sugarRushHourStartTimestamp  ? _tradingPausedTimestamp : _getNow();
		return currentTimestamp.sub(_sugarRushHourStartTimestamp);
	}
	function isInSugarRushHour() external view returns (bool) {
		uint256 currentTimestamp = !isTradingEnabled && _tradingPausedTimestamp > _sugarRushHourStartTimestamp  ? _tradingPausedTimestamp : _getNow();
		uint256 totalSugarRushTime = _sugarRush1.timeInPeriod.add(_sugarRush2.timeInPeriod);
		uint256 timeSinceSugarRush = currentTimestamp.sub(_sugarRushHourStartTimestamp);
		if(timeSinceSugarRush < totalSugarRushTime) {
		return true;
		} else {
		return false;
		}
	}
	function getNumberOfHolders() external view returns(uint256) {
		return holdersMap.keys.length;
	}
	function isInLaunch() external view returns (bool) {
		uint256 currentTimestamp = !isTradingEnabled && _tradingPausedTimestamp > _launchStartTimestamp  ? _tradingPausedTimestamp : _getNow();
		uint256 timeSinceLaunch = currentTimestamp.sub(_launchStartTimestamp);
		uint256 blocksSinceLaunch = block.number.sub(_launchBlockNumber);
		uint256 totalLaunchTime =  _launch1.timeInPeriod.add(_launch2.timeInPeriod).add(_launch3.timeInPeriod);

		if(_isLaunched && (timeSinceLaunch < totalLaunchTime || blocksSinceLaunch < _launch1.blocksInPeriod )) {
			return true;
		} else {
			return false;
		}
	}
	function getBaseBuyFees() external view returns (uint256, uint256, uint256){
		return (_base.liquidityFeeOnBuy, _base.marketingFeeOnBuy, _base.holdersFeeOnBuy);
	}
	function getBaseSellFees() external view returns (uint256, uint256, uint256){
		return (_base.liquidityFeeOnSell, _base.marketingFeeOnSell, _base.holdersFeeOnSell);
	}
	//SugarRush1
	function getSugarRush1BuyFees() external view returns (uint256, uint256, uint256){
		return (_sugarRush1.liquidityFeeOnBuy, _sugarRush1.marketingFeeOnBuy, _sugarRush1.holdersFeeOnBuy);
	}
	function getSugarRush1SellFees() external view returns (uint256, uint256, uint256){
		return (_sugarRush1.liquidityFeeOnSell, _sugarRush1.marketingFeeOnSell, _sugarRush1.holdersFeeOnSell);
	}
	//SugarRush2
	function getSugarRush2BuyFees() external view returns (uint256, uint256, uint256){
		return (_sugarRush2.liquidityFeeOnBuy, _sugarRush2.marketingFeeOnBuy, _sugarRush2.holdersFeeOnBuy);
	}
	function getSugarRush2SellFees() external view returns (uint256, uint256, uint256){
		return (_sugarRush2.liquidityFeeOnSell, _sugarRush2.marketingFeeOnSell, _sugarRush2.holdersFeeOnSell);
	}
	function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
		require(rAmount <= _rTotal, "Sugarland: Amount must be less than total reflections");
		uint256 currentRate =  _getRate();
		return rAmount.div(currentRate);
	}
	function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external view returns (uint256) {
		require(tAmount <= _tTotal, "Sugarland: Amount must be less than supply");
		if (!deductTransferFee) {
			(uint256 rAmount, , , , , , ) = _getValues(tAmount);
			return rAmount;
		}
		else {
			(, uint256 rTransferAmount, , , , , ) = _getValues(tAmount);
			return rTransferAmount;
		}
	}

	// Main
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

		if(!_isAllowedToTradeWhenDisabled[from] && !_isAllowedToTradeWhenDisabled[to]) {
			require(isTradingEnabled, "Sugarland: Trading is currently disabled.");
			require(!_isBlocked[to], "Sugarland: Account is blocked");
			require(!_isBlocked[from], "Sugarland: Account is blocked");
			if (_isInLaunch && currentTimestamp.sub(_launchStartTimestamp) <= 300 && isBuyFromLp) {
				require(currentTimestamp.sub(_buyTimesInLaunch[to]) > 60, "Sugarland: Cannot buy more than once per min in first 5min of launch");
			}
			if (!_isExcludedFromMaxTransactionLimit[to] && !_isExcludedFromMaxTransactionLimit[from]) {
				require(amount <= maxTxAmount, "Sugarland: Buy amount exceeds the maxTxAmount.");
			}
			if (!_isExcludedFromMaxWalletLimit[to] && isBuyFromLp) {
				require(balanceOf(to).add(amount) <= maxWalletAmount, "Sugarland: Expected wallet amount exceeds the maxWalletAmount.");
			}
		}

		_adjustTaxes(isBuyFromLp, isSelltoLp);
		bool canSwap = balanceOf(address(this)) >= minimumTokensBeforeSwap;

		if (
			isTradingEnabled &&
			canSwap &&
			!_swapping &&
			_totalFee > 0 &&
			automatedMarketMakerPairs[to] &&
			from != liquidityWallet && to != liquidityWallet &&
			from != marketingWallet && to != marketingWallet
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
		_setBalance(from, balanceOf(from));
		_setBalance(to, balanceOf(to));
	}
	function _tokenTransfer(address sender,address recipient, uint256 amount, bool takeFee) private {
		uint256 _previousLiquidityFee = _liquidityFee;
		uint256 _previousMarketingFee = _marketingFee;
		uint256 _previousHoldersFee = _holdersFee;

		if(!takeFee) {
			_liquidityFee = 0;
			_marketingFee = 0;
			_holdersFee = 0;
			_totalFee = 0;
		}
		emit FeesApplied(sender, recipient, _liquidityFee, _marketingFee, _holdersFee, _totalFee);
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
		if(!takeFee) {
			_liquidityFee = _previousLiquidityFee;
			_marketingFee = _previousMarketingFee;
			_holdersFee = _previousHoldersFee;
			_totalFee = _liquidityFee.add(_marketingFee).add(_holdersFee);
		}
	}
	function _transferStandard(address sender,address recipient, uint256 tAmount) private {
		(uint256 rAmount,uint256 rTransferAmount,uint256 rFee, uint256 rOther, uint256 tTransferAmount,uint256 tFee, uint256 tOther) = _getValues(tAmount);
		_rOwned[sender] = _rOwned[sender].sub(rAmount);
		_rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
		_takeContractFees(rOther, tFee);
		_reflectFee(rFee, tFee);
		emit Transfer(sender, recipient, tTransferAmount);
	}
	function _transferToExcluded(address sender,address recipient,uint256 tAmount) private {
		(uint256 rAmount,uint256 rTransferAmount,uint256 rFee, uint256 rOther, uint256 tTransferAmount,uint256 tFee, uint256 tOther) = _getValues(tAmount);
		_rOwned[sender] = _rOwned[sender].sub(rAmount);
		_tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
		_rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
		_takeContractFees(rOther, tFee);
		_reflectFee(rFee, tFee);
		emit Transfer(sender, recipient, tTransferAmount);
	}
	function _transferFromExcluded(address sender, address recipient,uint256 tAmount) private {
		(uint256 rAmount,uint256 rTransferAmount, uint256 rFee, uint256 rOther, uint256 tTransferAmount, uint256 tFee, uint256 tOther) = _getValues(tAmount);
		_tOwned[sender] = _tOwned[sender].sub(tAmount);
		_rOwned[sender] = _rOwned[sender].sub(rAmount);
		_rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
		_takeContractFees(rOther, tFee);
		_reflectFee(rFee, tFee);
		emit Transfer(sender, recipient, tTransferAmount);
	}
	function _transferBothExcluded(address sender,address recipient,uint256 tAmount) private {
		(uint256 rAmount,uint256 rTransferAmount,uint256 rFee, uint256 rOther, uint256 tTransferAmount,uint256 tFee, uint256 tOther) = _getValues(tAmount);
		_tOwned[sender] = _tOwned[sender].sub(tAmount);
		_rOwned[sender] = _rOwned[sender].sub(rAmount);
		_tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
		_rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
		_takeContractFees(rOther, tOther);
		_reflectFee(rFee, tFee);
		emit Transfer(sender, recipient, tTransferAmount);
	}
	function _reflectFee(uint256 rFee, uint256 tFee) private {
		_rTotal = _rTotal.sub(rFee);
		_tFeeTotal = _tFeeTotal.add(tFee);
	}
	function _getValues(uint256 tAmount) private view returns (uint256,uint256,uint256,uint256,uint256,uint256,uint256){
		(uint256 tTransferAmount,uint256 tFee, uint256 tOther) = _getTValues(tAmount);
		(uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rOther) = _getRValues(tAmount, tFee, tOther, _getRate());
		return (rAmount,rTransferAmount,rFee, rOther, tTransferAmount,tFee, tOther);
	}
	function _getTValues(uint256 tAmount) private view returns (uint256,uint256,uint256){
		uint256 tFee = tAmount.mul(_holdersFee).div(100);
		uint256 tMarketingFee = tAmount.mul(_marketingFee).div(100);
		uint256 tLiquidityFee = tAmount.mul(_liquidityFee).div(100);
		uint256 tOther = tMarketingFee.add(tLiquidityFee);
		uint256 tTransferAmount = tAmount.sub(tFee).sub(tOther);
		return (tTransferAmount, tFee, tOther);
	}
	function _getRValues(
		uint256 tAmount,
		uint256 tFee,
		uint256 tOther,
		uint256 currentRate
	) private pure returns ( uint256, uint256, uint256, uint256 ) {
		uint256 rAmount = tAmount.mul(currentRate);
		uint256 rFee = tFee.mul(currentRate);
		uint256 rOther = tOther.mul(currentRate);
		uint256 rTransferAmount = rAmount.sub(rFee).sub(rOther);
		return (rAmount, rTransferAmount, rFee, rOther);
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
	function _takeContractFees(uint256 rOther, uint256 tOther) private {
		_rOwned[address(this)] = _rOwned[address(this)].add(rOther);
		if (_isExcludedFromDividends[address(this)]) {
			_tOwned[address(this)] = _tOwned[address(this)].add(tOther);
		}
	}
	function _setBalance(address account, uint256 newBalance) private {
		if(newBalance > 0) {
			holdersMap.set(account, newBalance);
		}
		if(newBalance <= 0) {
			holdersMap.remove(account);
		}
	}
	function _adjustTaxes(bool isBuyFromLp, bool isSelltoLp) private {
		uint256 blocksSinceLaunch = block.number.sub(_launchBlockNumber);
		uint256 currentTimestamp = !isTradingEnabled && _tradingPausedTimestamp > _launchStartTimestamp  ? _tradingPausedTimestamp : _getNow();
		uint256 timeSinceLaunch = currentTimestamp.sub(_launchStartTimestamp);
		uint256 timeInLaunch = _launch3.timeInPeriod.add(_launch2.timeInPeriod);
		uint256 timeSinceSugarRush = currentTimestamp.sub(_sugarRushHourStartTimestamp);
		_liquidityFee = _base.liquidityFeeOnBuy;
		_marketingFee = _base.marketingFeeOnBuy;
		_holdersFee = _base.holdersFeeOnBuy;

		if (isSelltoLp) {
			_liquidityFee = _base.liquidityFeeOnSell;
			_marketingFee = _base.marketingFeeOnSell;
			_holdersFee = _base.holdersFeeOnSell;

			if (_isLaunched && blocksSinceLaunch < _launch1.blocksInPeriod) {
				_liquidityFee = _launch1.liquidityFeeOnSell;
				_marketingFee = _launch1.marketingFeeOnSell;
				_holdersFee = _launch1.holdersFeeOnSell;
			}
			if (_isLaunched && timeSinceLaunch <= _launch2.timeInPeriod && blocksSinceLaunch > _launch1.blocksInPeriod) {
				_liquidityFee = _launch2.liquidityFeeOnSell;
				_marketingFee = _launch2.marketingFeeOnSell;
				_holdersFee = _launch2.holdersFeeOnSell;
			}
			if (_isLaunched && timeSinceLaunch > _launch2.timeInPeriod && timeSinceLaunch <= timeInLaunch && blocksSinceLaunch > _launch1.blocksInPeriod) {
				_liquidityFee = _launch3.liquidityFeeOnSell;
				_marketingFee = _launch3.marketingFeeOnSell;
				_holdersFee = _launch3.holdersFeeOnSell;
			}
			if (timeSinceSugarRush <= _sugarRush1.timeInPeriod) {
				_liquidityFee = _sugarRush1.liquidityFeeOnSell;
				_marketingFee = _sugarRush1.marketingFeeOnSell;
				_holdersFee = _sugarRush1.holdersFeeOnSell;
			}
			if (timeSinceSugarRush > _sugarRush1.timeInPeriod && timeSinceSugarRush <= _sugarRush1.timeInPeriod.add(_sugarRush2.timeInPeriod)) {
				_liquidityFee = _sugarRush2.liquidityFeeOnSell;
				_marketingFee = _sugarRush2.marketingFeeOnSell;
				_holdersFee = _sugarRush2.holdersFeeOnSell;
			}
		}
		if (isBuyFromLp) {
			if (_isLaunched && blocksSinceLaunch < _launch1.blocksInPeriod) {
				_liquidityFee = _launch1.liquidityFeeOnBuy;
				_marketingFee = _launch1.marketingFeeOnBuy;
				_holdersFee = _launch1.holdersFeeOnBuy;
			}
			if (_isLaunched && timeSinceLaunch <= _launch2.timeInPeriod && blocksSinceLaunch > _launch1.blocksInPeriod) {
				_liquidityFee = _launch2.liquidityFeeOnBuy;
				_marketingFee = _launch2.marketingFeeOnBuy;
				_holdersFee = _launch2.holdersFeeOnBuy;
			}
			if (_isLaunched && timeSinceLaunch > _launch2.timeInPeriod && timeSinceLaunch < timeInLaunch && blocksSinceLaunch > _launch1.blocksInPeriod) {
				_liquidityFee = _launch3.liquidityFeeOnBuy;
				_marketingFee = _launch3.marketingFeeOnBuy;
				_holdersFee = _launch3.holdersFeeOnBuy;
			}
			if (timeSinceSugarRush <= _sugarRush1.timeInPeriod) {
				_liquidityFee = _sugarRush1.liquidityFeeOnBuy;
				_marketingFee = _sugarRush1.marketingFeeOnBuy;
				_holdersFee = _sugarRush1.holdersFeeOnBuy;
			}
			if (timeSinceSugarRush > _sugarRush1.timeInPeriod && timeSinceSugarRush <= _sugarRush1.timeInPeriod.add(_sugarRush2.timeInPeriod)) {
				_liquidityFee = _sugarRush2.liquidityFeeOnBuy;
				_marketingFee = _sugarRush2.marketingFeeOnBuy;
				_holdersFee = _sugarRush2.holdersFeeOnBuy;
			}
		}
		_totalFee = _liquidityFee.add(_marketingFee).add(_holdersFee);
	}
	function _setCustomSellTaxPeriod(CustomTaxPeriod storage map,
		uint256 _liquidityFeeOnSell,
		uint256 _marketingFeeOnSell,
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
		if (map.holdersFeeOnSell != _holdersFeeOnSell) {
			emit CustomTaxPeriodChange(_holdersFeeOnSell, map.holdersFeeOnSell, 'holdersFeeOnSell', map.periodName);
			map.holdersFeeOnSell = _holdersFeeOnSell;
		}
	}
	function _setCustomBuyTaxPeriod(CustomTaxPeriod storage map,
		uint256 _liquidityFeeOnBuy,
		uint256 _marketingFeeOnBuy,
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
		if (map.holdersFeeOnBuy != _holdersFeeOnBuy) {
			emit CustomTaxPeriodChange(_holdersFeeOnBuy, map.holdersFeeOnBuy, 'holdersFeeOnBuy', map.periodName);
			map.holdersFeeOnBuy = _holdersFeeOnBuy;
		}
	}
	function _swapAndLiquify() private {
		uint256 contractBalance = balanceOf(address(this));
		uint256 initialBNBBalance = address(this).balance;

		uint256 amountToLiquify = contractBalance.mul(_liquidityFee).div(_totalFee).div(2);
		uint256 amountToSwap =  contractBalance.sub(amountToLiquify);

		_swapTokensForBNB(amountToSwap);

		uint256 bnbBalanceAfterSwap = address(this).balance.sub(initialBNBBalance);
		uint256 totalBNBFee = _totalFee.sub(_liquidityFee.div(2));
		uint256 amountBNBLiquidity = bnbBalanceAfterSwap.mul(_liquidityFee).div(totalBNBFee).div(2);
		uint256 amountBNBMarketing = bnbBalanceAfterSwap.sub(amountBNBLiquidity);

		payable(marketingWallet).transfer(amountBNBMarketing);

		if (amountToLiquify > 0) {
			_addLiquidity(amountToLiquify, amountBNBLiquidity);
			emit SwapAndLiquify(amountToSwap, amountBNBLiquidity, amountToLiquify);
		}
	}
	function _swapTokensForBNB(uint256 tokenAmount) private {
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = uniswapV2Router.WETH();
		_approve(address(this), address(uniswapV2Router), tokenAmount);
		uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
			tokenAmount,
			0, // accept any amount of ETH
			path,
			address(this),
			block.timestamp
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
			block.timestamp
		);
	}
}
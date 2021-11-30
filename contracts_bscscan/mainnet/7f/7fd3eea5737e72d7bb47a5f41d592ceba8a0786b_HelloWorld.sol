/**
 *Submitted for verification at BscScan.com on 2021-11-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

abstract contract Context {
	function _msgSender() internal view virtual returns (address) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns (bytes calldata) {
		this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
		return msg.data;
	}
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

library SafeMathInt {
	int256 private constant MIN_INT256 = int256(1) << 255;
	int256 private constant MAX_INT256 = ~(int256(1) << 255);

	function mul(int256 a, int256 b) internal pure returns (int256) {
		int256 c = a * b;

		// Detect overflow when multiplying MIN_INT256 with -1
		require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
		require((b == 0) || (c / b == a));
		return c;
	}
	function div(int256 a, int256 b) internal pure returns (int256) {
		// Prevent overflow when dividing MIN_INT256 by -1
		require(b != -1 || a != MIN_INT256);

		// Solidity already throws when dividing by 0.
		return a / b;
	}
	function sub(int256 a, int256 b) internal pure returns (int256) {
		int256 c = a - b;
		require((b >= 0 && c <= a) || (b < 0 && c > a));
		return c;
	}
	function add(int256 a, int256 b) internal pure returns (int256) {
		int256 c = a + b;
		require((b >= 0 && c >= a) || (b < 0 && c < a));
		return c;
	}
	function abs(int256 a) internal pure returns (int256) {
		require(a != MIN_INT256);
		return a < 0 ? -a : a;
	}
	function toUint256Safe(int256 a) internal pure returns (uint256) {
		require(a >= 0);
		return uint256(a);
	}
}

library SafeMathUint {
	function toInt256Safe(uint256 a) internal pure returns (int256) {
		int256 b = int256(a);
		require(b >= 0);
		return b;
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

interface IERC20Metadata is IERC20 {
	function name() external view returns (string memory);
	function symbol() external view returns (string memory);
	function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
	using SafeMath for uint256;

	mapping(address => uint256) private _balances;
	mapping(address => mapping(address => uint256)) private _allowances;

	uint256 private _totalSupply;
	string private _name;
	string private _symbol;

	constructor(string memory name_, string memory symbol_) public {
		_name = name_;
		_symbol = symbol_;
	}

	function name() public view virtual override returns (string memory) {
		return _name;
	}

	function symbol() public view virtual override returns (string memory) {
		return _symbol;
	}

	function decimals() public view virtual override returns (uint8) {
		return 18;
	}

	function totalSupply() public view virtual override returns (uint256) {
		return _totalSupply;
	}

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

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) public virtual override returns (bool) {
		_transfer(sender, recipient, amount);
		_approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
		return true;
	}

	function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
		return true;
	}

	function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
		return true;
	}

	function _transfer(
		address sender,
		address recipient,
		uint256 amount
	) internal virtual {
		require(sender != address(0), "ERC20: transfer from the zero address");
		require(recipient != address(0), "ERC20: transfer to the zero address");
		_beforeTokenTransfer(sender, recipient, amount);
		_balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
		_balances[recipient] = _balances[recipient].add(amount);
		emit Transfer(sender, recipient, amount);
	}

	function _mint(address account, uint256 amount) internal virtual {
		require(account != address(0), "ERC20: mint to the zero address");
		_beforeTokenTransfer(address(0), account, amount);
		_totalSupply = _totalSupply.add(amount);
		_balances[account] = _balances[account].add(amount);
		emit Transfer(address(0), account, amount);
	}

	function _burn(address account, uint256 amount) internal virtual {
		require(account != address(0), "ERC20: burn from the zero address");
		_beforeTokenTransfer(account, address(0), amount);
		_balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
		_totalSupply = _totalSupply.sub(amount);
		emit Transfer(account, address(0), amount);
	}

	function _approve(
		address owner,
		address spender,
		uint256 amount
	) internal virtual {
		require(owner != address(0), "ERC20: approve from the zero address");
		require(spender != address(0), "ERC20: approve to the zero address");
		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 amount
	) internal virtual {}
}

interface DividendPayingTokenInterface {
	function dividendOf(address _owner) external view returns(uint256);
	function withdrawDividend() external;
	event DividendsDistributed(
		address indexed from,
		uint256 weiAmount
	);
	event DividendWithdrawn(
		address indexed to,
		uint256 weiAmount
	);
}

interface DividendPayingTokenOptionalInterface {
	function withdrawableDividendOf(address _owner) external view returns(uint256);
	function withdrawnDividendOf(address _owner) external view returns(uint256);
	function accumulativeDividendOf(address _owner) external view returns(uint256);
}

/// @title Dividend-Paying Token
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev A mintable ERC20 token that allows anyone to pay and distribute ether
///  to token holders as dividends and allows token holders to withdraw their dividends.
///  Reference: the source code of PoWH3D: https://etherscan.io/address/0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe#code
contract DividendPayingToken is ERC20, Ownable, DividendPayingTokenInterface, DividendPayingTokenOptionalInterface {
	using SafeMath for uint256;
	using SafeMathUint for uint256;
	using SafeMathInt for int256;
	
	// With `magnitude`, we can properly distribute dividends even if the amount of received ether is small.
	// For more discussion about choosing the value of `magnitude`,
	//  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
	uint256 constant internal magnitude = 2**128;
	uint256 internal magnifiedDividendPerShare;
	uint256 public totalDividendsDistributed;
	address public rewardToken;

	// About dividendCorrection:
	// If the token balance of a `_user` is never changed, the dividend of `_user` can be computed with:
	//   `dividendOf(_user) = dividendPerShare * balanceOf(_user)`.
	// When `balanceOf(_user)` is changed (via minting/burning/transferring tokens),
	//   `dividendOf(_user)` should not be changed,
	//   but the computed value of `dividendPerShare * balanceOf(_user)` is changed.
	// To keep the `dividendOf(_user)` unchanged, we add a correction term:
	//   `dividendOf(_user) = dividendPerShare * balanceOf(_user) + dividendCorrectionOf(_user)`,
	//   where `dividendCorrectionOf(_user)` is updated whenever `balanceOf(_user)` is changed:
	//   `dividendCorrectionOf(_user) = dividendPerShare * (old balanceOf(_user)) - (new balanceOf(_user))`.
	// So now `dividendOf(_user)` returns the same value before and after `balanceOf(_user)` is changed.
	mapping(address => int256) internal magnifiedDividendCorrections;
	mapping(address => uint256) internal withdrawnDividends;

	constructor(string memory _name, string memory _symbol) public ERC20(_name, _symbol) {}

	/// @notice Distributes ether to token holders as dividends.
	/// @dev It reverts if the total supply of tokens is 0.
	/// It emits the `DividendsDistributed` event if the amount of received ether is greater than 0.
	/// About undistributed ether:
	///   In each distribution, there is a small amount of ether not distributed,
	///     the magnified amount of which is
	///     `(msg.value * magnitude) % totalSupply()`.
	///   With a well-chosen `magnitude`, the amount of undistributed ether
	///     (de-magnified) in a distribution can be less than 1 wei.
	///   We can actually keep track of the undistributed ether in a distribution
	///     and try to distribute it in the next distribution,
	///     but keeping track of such data on-chain costs much more than
	///     the saved ether, so we don't do that.
	
	function distributeDividendsUsingAmount(uint256 amount) public onlyOwner {
        require(totalSupply() > 0);
        if (amount > 0) {
          magnifiedDividendPerShare = magnifiedDividendPerShare.add((amount).mul(magnitude) / totalSupply());
          emit DividendsDistributed(msg.sender, amount);
          totalDividendsDistributed = totalDividendsDistributed.add(amount);
        }
    }
	function withdrawDividend() public virtual override {
		_withdrawDividendOfUser(payable(msg.sender));
	}
	function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
		uint256 _withdrawableDividend = withdrawableDividendOf(user);
		if (_withdrawableDividend > 0) {
			withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
			emit DividendWithdrawn(user, _withdrawableDividend);
			(bool success) = IERC20(rewardToken).transfer(user, _withdrawableDividend);
			if(!success) {
				withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
				return 0;
			}
			return _withdrawableDividend;
		}
		return 0;
	}
	function dividendOf(address _owner) public view override returns(uint256) {
		return withdrawableDividendOf(_owner);
	}
	function withdrawableDividendOf(address _owner) public view override returns(uint256) {
		return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
	}
	function withdrawnDividendOf(address _owner) public view override returns(uint256) {
		return withdrawnDividends[_owner];
	}
	function accumulativeDividendOf(address _owner) public view override returns(uint256) {
		return magnifiedDividendPerShare.mul(balanceOf(_owner)).toInt256Safe()
		.add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
	}
	function _transfer(address from, address to, uint256 value) internal virtual override {
		require(false);
		int256 _magCorrection = magnifiedDividendPerShare.mul(value).toInt256Safe();
		magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from].add(_magCorrection);
		magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(_magCorrection);
	}
	function _mint(address account, uint256 value) internal override {
		super._mint(account, value);
		magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
		.sub( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
	}
	function _burn(address account, uint256 value) internal override {
		super._burn(account, value);
		magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
		.add( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
	}
	function _setBalance(address account, uint256 newBalance) internal {
		uint256 currentBalance = balanceOf(account);
		if(newBalance > currentBalance) {
			uint256 mintAmount = newBalance.sub(currentBalance);
			_mint(account, mintAmount);
		} else if(newBalance < currentBalance) {
			uint256 burnAmount = currentBalance.sub(newBalance);
			_burn(account, burnAmount);
		}
	}
	function _setRewardToken(address token) internal onlyOwner {
	    rewardToken = token;
	}
}

contract HelloWorld is ERC20, Ownable {
	using SafeMath for uint256;

	IUniswapV2Router02 public uniswapV2Router;
	address public immutable uniswapV2Pair;

	string private _name = "HelloWorld";
	string private _symbol = "HW7";
	uint8 private _decimals = 18;

	RentEezDividendTracker public dividendTracker;
	
	bool public isTradingEnabled;
	uint256 private _tradingPausedTimestamp;

	// initialSupply
	uint256 constant initialSupply = 1000000000 * (10**18);

	// max wallet is 2% of initialSupply
	uint256 public maxWalletAmount = initialSupply * 200 / 10000;
	// max buy and sell tx is 0.2% of initialSupply
	uint256 public maxTxAmount = initialSupply * 20 / 10000; 

	bool public _swapping;
	uint256 public minimumTokensBeforeSwap = 25000000 * (10**18);
	uint256 public gasForProcessing = 300000;
	
	address public marketingWallet;
	address public liquidityWallet;
	address public charityWallet;
	address public buyBackWallet;
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
		uint256 buyBackFeeOnBuy;
		uint256 buyBackFeeOnSell;
		uint256 charityFeeOnBuy;
		uint256 charityFeeOnSell;
		uint256 holdersFeeOnBuy;
		uint256 holdersFeeOnSell;
	}

	// Launch taxes
	bool private _isLanched;
	uint256 private _launchStartTimestamp;
	uint256 private _launchBlockNumber;
	CustomTaxPeriod private _launch1 = CustomTaxPeriod('launch1',3,0,2,100,2,0,3,0,0,0,0,0,3,0);
	CustomTaxPeriod private _launch2 = CustomTaxPeriod('launch2',0,3600,2,5,2,15,3,10,0,0,0,0,3,10);
	CustomTaxPeriod private _launch3 = CustomTaxPeriod('launch3',0,82800,2,3,2,10,3,5,0,0,0,0,3,7);

	// Base taxes
	CustomTaxPeriod private _default = CustomTaxPeriod('default',0,0,2,2,2,2,3,3,0,0,0,0,3,3);
	CustomTaxPeriod private _base = CustomTaxPeriod('base',0,0,2,2,2,2,3,3,0,0,0,0,3,3);

	// Ez Hour taxes
	uint256 private _ezHourStartTimestamp;
	CustomTaxPeriod private _ez1 = CustomTaxPeriod('ez1',0,3600,0,5,0,5,0,0,0,5,0,5,3,10);
	CustomTaxPeriod private _ez2 = CustomTaxPeriod('ez2',0,3600,2,2,2,5,0,0,3,3,0,5,3,5);

	uint256 private _blockedTimeLimit = 86400;
	mapping (address => bool) private _isExcludedFromFee;
	mapping (address => bool) private _isExcludedFromMaxTransactionLimit;
	mapping (address => bool) private _isExcludedFromMaxWalletLimit;
	mapping (address => bool) private _isBlocked;
	mapping (address => bool) public automatedMarketMakerPairs;
	mapping (address => uint256) private _buyTimesInLaunch;

	uint256 private _liquidityFee;
	uint256 private _marketingFee;
	uint256 private _devFee;
	uint256 private _charityFee;
	uint256 private _buyBackFee;
	uint256 private _holdersFee;
	uint256 private _totalFee;

	event AutomatedMarketMakerPairChange(address indexed pair, bool indexed value);
	event DividendTrackerChange(address indexed newAddress, address indexed oldAddress);
	event UniswapV2RouterChange(address indexed newAddress, address indexed oldAddress);
	event ExcludeFromFeesChange(address indexed account, bool isExcluded);
	event WalletChange(string indexed walletIdentifier, address indexed newWallet, address indexed oldWallet);
	event GasForProcessingChange(uint256 indexed newValue, uint256 indexed oldValue);
	event FeeChange(string indexed identifier, uint256 liquidityFee, uint256 marketingFee, uint256 devFee, uint256 buyBackFee, uint256 charityFee, uint256 holdersFee);
	event CustomTaxPeriodChange(uint256 indexed newValue, uint256 indexed oldValue, string indexed taxType, bytes23 period);
	event BlockedAccountChange(address indexed holder, bool indexed status);
	event ezHourChange(bool indexed newValue, bool indexed oldValue);
	event MaxTransactionAmountChange(uint256 indexed newValue, uint256 indexed oldValue);
	event MaxWalletAmountChange(uint256 indexed newValue, uint256 indexed oldValue);
	event MinTokenAmountBeforeSwapChange(uint256 indexed newValue, uint256 indexed oldValue);
	event ExcludeFromMaxTransferChange(address indexed account, bool isExcluded);
	event ExcludeFromMaxWalletChange(address indexed account, bool isExcluded);
	event MinTokenAmountForDividendsChange(uint256 indexed newValue, uint256 indexed oldValue);
	event ExcludeFromDividendsChange(address indexed account, bool isExcluded);
	event DividendsSent(uint256 tokensSwapped);
	event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived,uint256 tokensIntoLiqudity);
    event ClaimBNBOverflow(uint256 amount);
	event ProcessedDividendTracker(
		uint256 iterations,
		uint256 claims,
		uint256 lastProcessedIndex,
		bool indexed automatic,
		uint256 gas,
		address indexed processor
	);
	
	event FeesApplied(bool isBuy, bool isSell, uint256 liquidityFee, uint256 marketingFee, uint256 devFee, uint256 buybackFee, uint256 charityFee, uint256 holdersFee, uint256 totalFee);

	constructor() public ERC20(_name, _symbol) {
        marketingWallet = owner();
	    liquidityWallet = owner();
	    charityWallet = owner();
	    buyBackWallet = owner();
	    devWallet = owner();

		dividendTracker = new RentEezDividendTracker();
        dividendTracker.setRewardToken(address(this));

		//IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); // Testnet
		IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); // Mainnet
		address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
		uniswapV2Router = _uniswapV2Router;
		uniswapV2Pair = _uniswapV2Pair;
		_setAutomatedMarketMakerPair(_uniswapV2Pair, true);

		_isExcludedFromFee[owner()] = true;
		_isExcludedFromFee[address(this)] = true;

		dividendTracker.excludeFromDividends(address(dividendTracker));
		dividendTracker.excludeFromDividends(address(this));
		dividendTracker.excludeFromDividends(address(0x000000000000000000000000000000000000dEaD));
		dividendTracker.excludeFromDividends(owner());
		dividendTracker.excludeFromDividends(address(_uniswapV2Router));

		_isExcludedFromMaxTransactionLimit[address(dividendTracker)] = true;
		_isExcludedFromMaxTransactionLimit[address(this)] = true;

		_isExcludedFromMaxWalletLimit[_uniswapV2Pair] = true;
		_isExcludedFromMaxWalletLimit[address(dividendTracker)] = true;
		_isExcludedFromMaxWalletLimit[address(uniswapV2Router)] = true;
		_isExcludedFromMaxWalletLimit[address(this)] = true;
		_isExcludedFromMaxWalletLimit[owner()] = true;

		_mint(owner(), initialSupply);
	}

	receive() external payable {}

	// Setters
	function _getNow() private view returns (uint256) {
		return block.timestamp;
	}
	function launch() public onlyOwner {
		_launchStartTimestamp = _getNow();
		_launchBlockNumber = block.number;
		isTradingEnabled = true;
		_isLanched = true;
	}
	function cancelLaunch() public onlyOwner {
		require(this.isInLaunch(), "RentEez: Launch is not set");
		_launchStartTimestamp = 0;
		_launchBlockNumber = 0;
		_isLanched = false;
	}
	function activateTrading() public onlyOwner {
		isTradingEnabled = true;
	}
	function deactivateTrading() public onlyOwner {
		isTradingEnabled = false;
		_tradingPausedTimestamp = _getNow();
	}
	function setEzHour() public onlyOwner {
		require(!this.isInEzHour(), "RentEez: Ez Hour is already set");
		require(isTradingEnabled, "RentEez: Trading must be enabled first");
		require(!this.isInLaunch(), "RentEez: Must not be in launch period");
		emit ezHourChange(true, false);
		_ezHourStartTimestamp = _getNow();
	}
	function cancelEzHour() public onlyOwner {
		require(this.isInEzHour(), "RentEez: ez Hour is not set");
		emit ezHourChange(false, true);
		_ezHourStartTimestamp = 0;
	}
	function updateDividendTracker(address newAddress) public onlyOwner {
		require(newAddress != address(dividendTracker), "RentEez: The dividend tracker already has that address");
		RentEezDividendTracker newDividendTracker = RentEezDividendTracker(payable(newAddress));
		require(newDividendTracker.owner() == address(this), "RentEez: The new dividend tracker must be owned by the RentEez token contract");
		newDividendTracker.excludeFromDividends(address(newDividendTracker));
		newDividendTracker.excludeFromDividends(address(this));
		newDividendTracker.excludeFromDividends(owner());
		newDividendTracker.excludeFromDividends(address(uniswapV2Router));
		emit DividendTrackerChange(newAddress, address(dividendTracker));
		dividendTracker = newDividendTracker;
	}
	function _setAutomatedMarketMakerPair(address pair, bool value) private {
		require(automatedMarketMakerPairs[pair] != value, "RentEez: Automated market maker pair is already set to that value");
		automatedMarketMakerPairs[pair] = value;
		if(value) {
			dividendTracker.excludeFromDividends(pair);
		}
		emit AutomatedMarketMakerPairChange(pair, value);
	}
	function excludeFromFees(address account, bool excluded) public onlyOwner {
		require(_isExcludedFromFee[account] != excluded, "RentEez: Account is already the value of 'excluded'");
		_isExcludedFromFee[account] = excluded;
		emit ExcludeFromFeesChange(account, excluded);
	}
	function excludeFromDividends(address account) public onlyOwner {
		dividendTracker.excludeFromDividends(account);
	}
	function excludeFromMaxTransactionLimit(address account, bool excluded) public onlyOwner {
		require(_isExcludedFromMaxTransactionLimit[account] != excluded, "RentEez: Account is already the value of 'excluded'");
		_isExcludedFromMaxTransactionLimit[account] = excluded;
		emit ExcludeFromMaxTransferChange(account, excluded);
	}
	function excludeFromMaxWalletLimit(address account, bool excluded) public onlyOwner {
		require(_isExcludedFromMaxWalletLimit[account] != excluded, "RentEez: Account is already the value of 'excluded'");
		_isExcludedFromMaxWalletLimit[account] = excluded;
		emit ExcludeFromMaxWalletChange(account, excluded);
	}
	function blockAccount(address account) public onlyOwner {
		uint256 currentTimestamp = _getNow();
		require(!_isBlocked[account], "RentEez: Account is already blocked");
		if (_isLanched) {
			require(currentTimestamp.sub(_launchStartTimestamp) < _blockedTimeLimit, "RentEez: Time to block accounts has expired");
		}
		_isBlocked[account] = true;
		emit BlockedAccountChange(account, true);
	}
	function unblockAccount(address account) public onlyOwner {
		require(_isBlocked[account], "RentEez: Account is not blcoked");
		_isBlocked[account] = false;
		emit BlockedAccountChange(account, false);
	}
	function setWallets(address newLiquidityWallet, address newMarketingWallet, address newDevWallet, address newBuyBackWallet, address newCharityWallet ) public onlyOwner {
		if(liquidityWallet != newLiquidityWallet) {
			require(newLiquidityWallet != address(0), "RentEez: The liquidityWallet cannot be 0");
			emit WalletChange('liquidityWallet', newLiquidityWallet, liquidityWallet);
			liquidityWallet = newLiquidityWallet;
		}
		if(marketingWallet != newMarketingWallet) {
			require(newMarketingWallet != address(0), "RentEez: The marketingWallet cannot be 0");
			emit WalletChange('marketingWallet', newMarketingWallet, marketingWallet);
			marketingWallet = newMarketingWallet;
		}
		if(devWallet != newDevWallet) {
			require(newDevWallet != address(0), "RentEez: The devWallet cannot be 0");
			emit WalletChange('devWallet', newDevWallet, devWallet);
			devWallet = newDevWallet;
		}
		if(buyBackWallet != newBuyBackWallet) {
			require(newBuyBackWallet != address(0), "RentEez: The buyBackWallet cannot be 0");
			emit WalletChange('buyBackWallet', newBuyBackWallet, buyBackWallet);
			buyBackWallet = newBuyBackWallet;
		}
		if(charityWallet != newCharityWallet) {
			require(newCharityWallet != address(0), "RentEez: The charityWallet cannot be 0");
			emit WalletChange('charityWallet', newCharityWallet, charityWallet);
			charityWallet = newCharityWallet;
		}
	}
	function setAllFeesToZero() public onlyOwner {
		_setCustomBuyTaxPeriod(_base, 0, 0, 0, 0, 0, 0);
		emit FeeChange('baseFees-Buy', 0, 0, 0, 0, 0, 0);
		_setCustomSellTaxPeriod(_base, 0, 0, 0, 0, 0, 0);
		emit FeeChange('baseFees-Sell', 0, 0, 0, 0, 0, 0);
	}
	function resetAllFees() public onlyOwner {
		_setCustomBuyTaxPeriod(_base, _default.liquidityFeeOnBuy, _default.marketingFeeOnBuy, _default.devFeeOnBuy, _default.buyBackFeeOnBuy, _default.charityFeeOnBuy,  _default.holdersFeeOnBuy);
		emit FeeChange('baseFees-Buy', _default.liquidityFeeOnBuy, _default.marketingFeeOnBuy, _default.devFeeOnBuy, _default.buyBackFeeOnBuy, _default.charityFeeOnBuy,  _default.holdersFeeOnBuy);
		_setCustomSellTaxPeriod(_base, _default.liquidityFeeOnSell, _default.marketingFeeOnSell, _default.devFeeOnSell, _default.buyBackFeeOnSell, _default.charityFeeOnSell,  _default.holdersFeeOnSell);
		emit FeeChange('baseFees-Sell', _default.liquidityFeeOnSell, _default.marketingFeeOnSell,_default.devFeeOnSell, _default.buyBackFeeOnSell, _default.charityFeeOnSell,   _default.holdersFeeOnSell);
	}
	// Base Fees
	function setBaseFeesOnBuy(uint256 _liquidityFeeOnBuy, uint256 _marketingFeeOnBuy, uint256 _devFeeOnBuy, uint256 _buybackFeeOnBuy, uint256 _charityFeeOnBuy, uint256 _holdersFeeOnBuy) public onlyOwner {
		_setCustomBuyTaxPeriod(_base, _liquidityFeeOnBuy, _marketingFeeOnBuy, _devFeeOnBuy, _buybackFeeOnBuy, _charityFeeOnBuy, _holdersFeeOnBuy);
		emit FeeChange('baseFees-Buy', _liquidityFeeOnBuy, _marketingFeeOnBuy, _devFeeOnBuy, _buybackFeeOnBuy, _charityFeeOnBuy, _holdersFeeOnBuy);
	}
	function setBaseFeesOnSell(uint256 _liquidityFeeOnSell,uint256 _marketingFeeOnSell, uint256 _devFeeOnSell, uint256 _buybackFeeOnSell, uint256 _charityFeeOnSell, uint256 _holdersFeeOnSell) public onlyOwner {
		_setCustomSellTaxPeriod(_base, _liquidityFeeOnSell, _marketingFeeOnSell, _devFeeOnSell, _buybackFeeOnSell, _charityFeeOnSell, _holdersFeeOnSell);
		emit FeeChange('baseFees-Sell', _liquidityFeeOnSell, _marketingFeeOnSell, _devFeeOnSell, _buybackFeeOnSell, _charityFeeOnSell, _holdersFeeOnSell);
	}
	//Launch2 Fees
	function setLaunch2FeesOnBuy(uint256 _liquidityFeeOnBuy, uint256 _marketingFeeOnBuy, uint256 _devFeeOnBuy, uint256 _buybackFeeOnBuy, uint256 _charityFeeOnBuy, uint256 _holdersFeeOnBuy) public onlyOwner {
		_setCustomBuyTaxPeriod(_launch2, _liquidityFeeOnBuy, _marketingFeeOnBuy, _devFeeOnBuy, _buybackFeeOnBuy, _charityFeeOnBuy, _holdersFeeOnBuy);
		emit FeeChange('launch2Fees-Buy', _liquidityFeeOnBuy, _marketingFeeOnBuy, _devFeeOnBuy, _buybackFeeOnBuy, _charityFeeOnBuy, _holdersFeeOnBuy);
	}
	function setLaunch2FeesOnSell(uint256 _liquidityFeeOnSell,uint256 _marketingFeeOnSell, uint256 _devFeeOnSell, uint256 _buybackFeeOnSell, uint256 _charityFeeOnSell, uint256 _holdersFeeOnSell) public onlyOwner {
		_setCustomSellTaxPeriod(_launch2, _liquidityFeeOnSell, _marketingFeeOnSell, _devFeeOnSell, _buybackFeeOnSell, _charityFeeOnSell, _holdersFeeOnSell);
		emit FeeChange('launch2Fees-Sell', _liquidityFeeOnSell, _marketingFeeOnSell, _devFeeOnSell, _buybackFeeOnSell, _charityFeeOnSell, _holdersFeeOnSell);
	}
	//Launch3 Fees
	function setLaunch3FeesOnBuy(uint256 _liquidityFeeOnBuy, uint256 _marketingFeeOnBuy, uint256 _devFeeOnBuy, uint256 _buybackFeeOnBuy, uint256 _charityFeeOnBuy, uint256 _holdersFeeOnBuy) public onlyOwner {
		_setCustomBuyTaxPeriod(_launch3, _liquidityFeeOnBuy, _marketingFeeOnBuy, _devFeeOnBuy, _buybackFeeOnBuy, _charityFeeOnBuy, _holdersFeeOnBuy);
		emit FeeChange('launch3Fees-Buy', _liquidityFeeOnBuy, _marketingFeeOnBuy, _devFeeOnBuy, _buybackFeeOnBuy, _charityFeeOnBuy, _holdersFeeOnBuy);
	}
	function setLaunch3FeesOnSell(uint256 _liquidityFeeOnSell,uint256 _marketingFeeOnSell, uint256 _devFeeOnSell, uint256 _buybackFeeOnSell, uint256 _charityFeeOnSell, uint256 _holdersFeeOnSell) public onlyOwner {
		_setCustomSellTaxPeriod(_launch3, _liquidityFeeOnSell, _marketingFeeOnSell, _devFeeOnSell, _buybackFeeOnSell, _charityFeeOnSell, _holdersFeeOnSell);
		emit FeeChange('launch3Fees-Sell', _liquidityFeeOnSell, _marketingFeeOnSell, _devFeeOnSell, _buybackFeeOnSell, _charityFeeOnSell, _holdersFeeOnSell);
	}
	// Ez1 Hour Fees
	function setEzHour1BuyFees(uint256 _liquidityFeeOnBuy,uint256 _marketingFeeOnBuy, uint256 _devFeeOnBuy, uint256 _buybackFeeOnBuy, uint256 _charityFeeOnBuy, uint256 _holdersFeeOnBuy) public onlyOwner {
		_setCustomBuyTaxPeriod(_ez1, _liquidityFeeOnBuy, _marketingFeeOnBuy, _devFeeOnBuy, _buybackFeeOnBuy, _charityFeeOnBuy, _holdersFeeOnBuy);
		emit FeeChange('ez1Fees-Buy', _liquidityFeeOnBuy, _marketingFeeOnBuy, _devFeeOnBuy, _buybackFeeOnBuy, _charityFeeOnBuy, _holdersFeeOnBuy);
	}
	function setEzHour1SellFees(uint256 _liquidityFeeOnSell,uint256 _marketingFeeOnSell, uint256 _devFeeOnSell, uint256 _buybackFeeOnSell, uint256 _charityFeeOnSell, uint256 _holdersFeeOnSell) public onlyOwner {
		_setCustomSellTaxPeriod(_ez1, _liquidityFeeOnSell, _marketingFeeOnSell, _devFeeOnSell, _buybackFeeOnSell, _charityFeeOnSell, _holdersFeeOnSell);
		emit FeeChange('ez1Fees-Sell', _liquidityFeeOnSell, _marketingFeeOnSell, _devFeeOnSell, _buybackFeeOnSell, _charityFeeOnSell, _holdersFeeOnSell);
	}
	// Ez2 Hour Fees
	function setEzHour2BuyFees(uint256 _liquidityFeeOnBuy,uint256 _marketingFeeOnBuy, uint256 _devFeeOnBuy, uint256 _buybackFeeOnBuy, uint256 _charityFeeOnBuy, uint256 _holdersFeeOnBuy) public onlyOwner {
		_setCustomBuyTaxPeriod(_ez2, _liquidityFeeOnBuy, _marketingFeeOnBuy, _devFeeOnBuy, _buybackFeeOnBuy, _charityFeeOnBuy, _holdersFeeOnBuy);
		emit FeeChange('ez2Fees-Buy', _liquidityFeeOnBuy, _marketingFeeOnBuy, _devFeeOnBuy, _buybackFeeOnBuy, _charityFeeOnBuy, _holdersFeeOnBuy);
	}
	function setEzHour2SellFees(uint256 _liquidityFeeOnSell,uint256 _marketingFeeOnSell, uint256 _devFeeOnSell, uint256 _buybackFeeOnSell, uint256 _charityFeeOnSell, uint256 _holdersFeeOnSell) public onlyOwner {
		_setCustomSellTaxPeriod(_ez2, _liquidityFeeOnSell, _marketingFeeOnSell, _devFeeOnSell, _buybackFeeOnSell, _charityFeeOnSell, _holdersFeeOnSell);
		emit FeeChange('ez2Fees-Sell', _liquidityFeeOnSell, _marketingFeeOnSell, _devFeeOnSell, _buybackFeeOnSell, _charityFeeOnSell, _holdersFeeOnSell);
	}
	function setUniswapRouter(address newAddress) public onlyOwner {
		require(newAddress != address(uniswapV2Router), "RentEez: The router already has that address");
		emit UniswapV2RouterChange(newAddress, address(uniswapV2Router));
		uniswapV2Router = IUniswapV2Router02(newAddress);
	}
	function setGasForProcessing(uint256 newValue) public onlyOwner {
		require(newValue >= 200000 && newValue <= 500000, "RentEez: gasForProcessing must be between 200,000 and 500,000");
		require(newValue != gasForProcessing, "RentEez: Cannot update gasForProcessing to same value");
		emit GasForProcessingChange(newValue, gasForProcessing);
		gasForProcessing = newValue;
	}
	function setMaxTransactionAmount(uint256 newValue) public onlyOwner {
		require(newValue != maxTxAmount, "RentEez: Cannot update maxTxAmount to same value");
		emit MaxTransactionAmountChange(newValue, maxTxAmount);
		maxTxAmount = newValue;
	}
	function setMaxWalletAmount(uint256 newValue) public onlyOwner {
		require(newValue != maxWalletAmount, "RentEez: Cannot update maxWalletAmount to same value");
		emit MaxWalletAmountChange(newValue, maxWalletAmount);
		maxWalletAmount = newValue;
	}
	function setMinimumTokensBeforeSwap(uint256 newValue) public onlyOwner {
		require(newValue != minimumTokensBeforeSwap, "RentEez: Cannot update minimumTokensBeforeSwap to same value");
		emit MinTokenAmountBeforeSwapChange(newValue, minimumTokensBeforeSwap);
		minimumTokensBeforeSwap = newValue;
	}
	function setMinimumTokenBalanceForDividends(uint256 newValue) public onlyOwner {
		dividendTracker.setTokenBalanceForDividends(newValue);
	}
	function updateClaimWait(uint256 claimWait) external onlyOwner {
		dividendTracker.updateClaimWait(claimWait);
	}
	function processDividendTracker(uint256 gas) external {
		(uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process(gas);
		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
	}
	function claim() external {
		dividendTracker.processAccount(payable(msg.sender), false);
	}
	function claimBNBOverflow(uint256 amount) external onlyOwner {
	    require(amount < address(this).balance, "RentEez: Cannot send more than contract balance");
        (bool success,) = address(owner()).call{value : amount}("");
        if (success){
            emit ClaimBNBOverflow(amount);
        }
	}
	function mintTokens(uint256 mintAmount, address mintAddress) external onlyOwner {
	    super._mint(mintAddress, mintAmount);
	}

	// Getters
	function timeSinceLastEzHour() external view returns(uint256){
	    uint256 currentTimestamp = !isTradingEnabled && _tradingPausedTimestamp > _ezHourStartTimestamp  ? _tradingPausedTimestamp : _getNow();
		return currentTimestamp.sub(_ezHourStartTimestamp);
	}
	function isInEzHour() external view returns (bool) {
		uint256 currentTimestamp = !isTradingEnabled && _tradingPausedTimestamp > _ezHourStartTimestamp  ? _tradingPausedTimestamp : _getNow();
		uint256 totalEzTime = _ez1.timeInPeriod.add(_ez2.timeInPeriod);
		uint256 timeSinceEz = currentTimestamp.sub(_ezHourStartTimestamp);
		if(timeSinceEz < totalEzTime) {
			return true;
		} else {
			return false;
		}
	}
	function isInLaunch() external view returns (bool) {
		uint256 currentTimestamp = !isTradingEnabled && _tradingPausedTimestamp > _launchStartTimestamp  ? _tradingPausedTimestamp : _getNow();
		uint256 timeSinceLaunch = currentTimestamp.sub(_launchStartTimestamp);
		uint256 blocksSinceLaunch = block.number.sub(_launchBlockNumber);
		uint256 totalLaunchTime =  _launch1.timeInPeriod.add(_launch2.timeInPeriod).add(_launch3.timeInPeriod);

		if(_isLanched && (timeSinceLaunch < totalLaunchTime || blocksSinceLaunch < _launch1.blocksInPeriod )) {
			return true;
		} else {
			return false;
		}
	}
	function getClaimWait() external view returns(uint256) {
		return dividendTracker.claimWait();
	}
	function getTotalDividendsDistributed() external view returns (uint256) {
		return dividendTracker.totalDividendsDistributed();
	}
	function withdrawableDividendOf(address account) public view returns(uint256) {
		return dividendTracker.withdrawableDividendOf(account);
	}
	function dividendTokenBalanceOf(address account) public view returns (uint256) {
		return dividendTracker.balanceOf(account);
	}
	function getAccountDividendsInfo(address account)
		external view returns (
		address,
		int256,
		int256,
		uint256,
		uint256,
		uint256,
		uint256,
		uint256) {
			return dividendTracker.getAccount(account);
	}
	function getLastProcessedIndex() external view returns(uint256) {
		return dividendTracker.getLastProcessedIndex();
	}
	function getNumberOfDividendTokenHolders() external view returns(uint256) {
		return dividendTracker.getNumberOfTokenHolders();
	}
	function getBaseBuyFees() external view returns (uint256, uint256, uint256, uint256, uint256, uint256){
		return (_base.liquidityFeeOnBuy, _base.marketingFeeOnBuy, _base.devFeeOnBuy, _base.buyBackFeeOnBuy, _base.charityFeeOnBuy,_base.holdersFeeOnBuy);
	}
	function getBaseSellFees() external view returns (uint256, uint256, uint256, uint256, uint256, uint256){
		return (_base.liquidityFeeOnSell, _base.marketingFeeOnSell, _base.devFeeOnSell, _base.buyBackFeeOnSell, _base.charityFeeOnSell, _base.holdersFeeOnSell);
	}
	function getEz1BuyFees() external view returns (uint256, uint256, uint256, uint256, uint256, uint256){
		return (_ez1.liquidityFeeOnBuy, _ez1.marketingFeeOnBuy, _ez1.devFeeOnBuy, _ez1.buyBackFeeOnBuy, _ez1.charityFeeOnBuy, _ez1.holdersFeeOnBuy);
	}
	function getEz1SellFees() external view returns (uint256, uint256, uint256, uint256, uint256, uint256){
		return (_ez1.liquidityFeeOnSell, _ez1.marketingFeeOnSell, _ez1.devFeeOnSell, _ez1.buyBackFeeOnSell, _ez1.charityFeeOnSell, _ez1.holdersFeeOnSell);
	}
	function getEz2BuyFees() external view returns (uint256, uint256, uint256, uint256, uint256, uint256){
		return (_ez2.liquidityFeeOnBuy, _ez2.marketingFeeOnBuy, _ez2.devFeeOnBuy, _ez2.buyBackFeeOnBuy, _ez2.charityFeeOnBuy, _ez2.holdersFeeOnBuy);
	}
	function getEz2SellFees() external view returns (uint256, uint256, uint256, uint256, uint256, uint256){
		return (_ez2.liquidityFeeOnSell, _ez2.marketingFeeOnSell, _ez2.devFeeOnSell, _ez2.buyBackFeeOnSell, _ez2.charityFeeOnSell, _ez2.holdersFeeOnSell);
	}

	// Main
	function _transfer(
		address from,
		address to,
		uint256 amount
		) internal override {
			require(from != address(0), "ERC20: transfer from the zero address");
			require(to != address(0), "ERC20: transfer to the zero address");

			if(amount == 0) {
				super._transfer(from, to, 0);
				return;
			}

			bool isBuyFromLp = automatedMarketMakerPairs[from];
			bool isSelltoLp = automatedMarketMakerPairs[to];
			bool _isInLaunch = this.isInLaunch();

			uint256 currentTimestamp = !isTradingEnabled && _tradingPausedTimestamp > _launchStartTimestamp  ? _tradingPausedTimestamp : _getNow();

			if(from != owner() && to != owner()) {
				require(isTradingEnabled, "RentEez: Trading is currently disabled.");
				require(!_isBlocked[to], "RentEez: Account is blocked");
				require(!_isBlocked[from], "RentEez: Account is blocked");
				if (_isInLaunch && currentTimestamp.sub(_launchStartTimestamp) <= 300 && isBuyFromLp) {
					require(currentTimestamp.sub(_buyTimesInLaunch[to]) > 60, "RentEez: Cannot buy more than once per min in first 5min of launch");
				}
				if (!_isExcludedFromMaxTransactionLimit[to] && !_isExcludedFromMaxTransactionLimit[from]) {
					require(amount <= maxTxAmount, "RentEez: Buy amount exceeds the maxTxBuyAmount.");
				}
				if (!_isExcludedFromMaxWalletLimit[to]) {
					require(balanceOf(to).add(amount) <= maxWalletAmount, "RentEez: Expected wallet amount exceeds the maxWalletAmount.");
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
				from != marketingWallet && to != marketingWallet &&
				from != devWallet && to != devWallet &&
				from != buyBackWallet && to != buyBackWallet &&
				from != charityWallet && to != charityWallet
			) {
				_swapping = true;
				_swapAndLiquify();
				_swapping = false;
			}

			bool takeFee = !_swapping && isTradingEnabled;

			if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
				takeFee = false;
			}
			if (takeFee) {
				uint256 fee = amount.mul(_totalFee).div(100);
				amount = amount.sub(fee);
				super._transfer(from, address(this), fee);
				//emit FeesApplied(_liquidityFee, _marketingFee, _devFee, _buyBackFee, _charityFee, _holdersFee, _totalFee);
			}

			if (_isInLaunch && currentTimestamp.sub(_launchStartTimestamp) <= 300) {
				if (to != owner() && isBuyFromLp  && currentTimestamp.sub(_buyTimesInLaunch[to]) > 60) {
					_buyTimesInLaunch[to] = currentTimestamp;
				}
			}

			super._transfer(from, to, amount);
			try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
			try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

			if(!_swapping) {
				uint256 gas = gasForProcessing;
				try dividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
					emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
				}
				catch {}
			}
	}
	function _adjustTaxes(bool isBuyFromLp, bool isSelltoLp) private {
	    uint256 blocksSinceLaunch = block.number.sub(_launchBlockNumber);
	    uint256 currentTimestamp = !isTradingEnabled && _tradingPausedTimestamp > _launchStartTimestamp  ? _tradingPausedTimestamp : _getNow();
		uint256 timeSinceLaunch = currentTimestamp.sub(_launchStartTimestamp);
		uint256 timeInLaunch = _launch3.timeInPeriod.add(_launch2.timeInPeriod);
		uint256 timeSinceEz = currentTimestamp.sub(_ezHourStartTimestamp);
		_liquidityFee = 0;
		_marketingFee = 0;
		_devFee = 0;
		_buyBackFee = 0;
		_charityFee = 0;
		_holdersFee = 0;
			
		if (isBuyFromLp) {
		    _liquidityFee = _base.liquidityFeeOnBuy;
			_marketingFee = _base.marketingFeeOnBuy;
			_devFee = _base.devFeeOnBuy;
			_buyBackFee = _base.buyBackFeeOnBuy;
			_charityFee = _base.charityFeeOnBuy;
			_holdersFee = _base.holdersFeeOnBuy;
			
			if (_isLanched && blocksSinceLaunch < _launch1.blocksInPeriod) {
				_liquidityFee = _launch1.liquidityFeeOnBuy;
				_marketingFee = _launch1.marketingFeeOnBuy;
				_devFee = _launch1.devFeeOnBuy;
    			_buyBackFee = _launch1.buyBackFeeOnBuy;
    			_charityFee = _launch1.charityFeeOnBuy;
				_holdersFee = _launch1.holdersFeeOnBuy;
			}
			if (_isLanched && timeSinceLaunch <= _launch2.timeInPeriod && blocksSinceLaunch > _launch1.blocksInPeriod) {
				_liquidityFee = _launch2.liquidityFeeOnBuy;
				_marketingFee = _launch2.marketingFeeOnBuy;
				_devFee = _launch2.devFeeOnBuy;
    			_buyBackFee = _launch2.buyBackFeeOnBuy;
    			_charityFee = _launch2.charityFeeOnBuy;
				_holdersFee = _launch2.holdersFeeOnBuy;
			}
			if (_isLanched && timeSinceLaunch > _launch2.timeInPeriod && timeSinceLaunch <= timeInLaunch && blocksSinceLaunch > _launch1.blocksInPeriod) {
				_liquidityFee = _launch3.liquidityFeeOnBuy;
				_marketingFee = _launch3.marketingFeeOnBuy;
				_devFee = _launch3.devFeeOnBuy;
    			_buyBackFee = _launch3.buyBackFeeOnBuy;
    			_charityFee = _launch3.charityFeeOnBuy;
				_holdersFee = _launch3.holdersFeeOnBuy;
			}
			if (timeSinceEz <= _ez1.timeInPeriod) {
				_liquidityFee = _ez1.liquidityFeeOnBuy;
				_marketingFee = _ez1.marketingFeeOnBuy;
				_devFee = _ez1.devFeeOnBuy;
    			_buyBackFee = _ez1.buyBackFeeOnBuy;
    			_charityFee = _ez1.charityFeeOnBuy;
				_holdersFee = _ez1.holdersFeeOnBuy;
			}
			if (timeSinceEz > _ez1.timeInPeriod && timeSinceEz <= _ez1.timeInPeriod.add(_ez2.timeInPeriod)) {
				_liquidityFee = _ez2.liquidityFeeOnBuy;
				_marketingFee = _ez2.marketingFeeOnBuy;
				_devFee = _ez2.devFeeOnBuy;
    			_buyBackFee = _ez2.buyBackFeeOnBuy;
    			_charityFee = _ez2.charityFeeOnBuy;
				_holdersFee = _ez2.holdersFeeOnBuy;
			}
		}
	    if (isSelltoLp) {
	    	_liquidityFee = _base.liquidityFeeOnSell;
			_marketingFee = _base.marketingFeeOnSell;
			_holdersFee = _base.holdersFeeOnSell;
			_devFee = _base.devFeeOnSell;
			_buyBackFee = _base.buyBackFeeOnSell;
			_charityFee = _base.charityFeeOnSell;
			
			if (_isLanched && blocksSinceLaunch < _launch1.blocksInPeriod) {
				_liquidityFee = _launch1.liquidityFeeOnSell;
				_marketingFee = _launch1.marketingFeeOnSell;
				_devFee = _launch1.devFeeOnSell;
    			_buyBackFee = _launch1.buyBackFeeOnSell;
    			_charityFee = _launch1.charityFeeOnSell;
				_holdersFee = _launch1.holdersFeeOnSell;
			}
			if (_isLanched && timeSinceLaunch <= _launch2.timeInPeriod && blocksSinceLaunch > _launch1.blocksInPeriod) {
				_liquidityFee = _launch2.liquidityFeeOnSell;
				_marketingFee = _launch2.marketingFeeOnSell;
				_devFee = _launch2.devFeeOnSell;
    			_buyBackFee = _launch2.buyBackFeeOnSell;
    			_charityFee = _launch2.charityFeeOnSell;
				_holdersFee = _launch2.holdersFeeOnSell;
			}
			if (_isLanched && timeSinceLaunch > _launch2.timeInPeriod && timeSinceLaunch <= timeInLaunch && blocksSinceLaunch > _launch1.blocksInPeriod) {
				_liquidityFee = _launch3.liquidityFeeOnSell;
				_marketingFee = _launch3.marketingFeeOnSell;
				_devFee = _launch3.devFeeOnSell;
    			_buyBackFee = _launch3.buyBackFeeOnSell;
    			_charityFee = _launch3.charityFeeOnSell;
				_holdersFee = _launch3.holdersFeeOnSell;
			}
			if (timeSinceEz <= _ez1.timeInPeriod) {
				_liquidityFee = _ez1.liquidityFeeOnSell;
				_marketingFee = _ez1.marketingFeeOnSell;
				_devFee = _ez1.devFeeOnSell;
    			_buyBackFee = _ez1.buyBackFeeOnSell;
    			_charityFee = _ez1.charityFeeOnSell;
				_holdersFee = _ez1.holdersFeeOnSell;
			}
			if (timeSinceEz > _ez1.timeInPeriod && timeSinceEz <= _ez1.timeInPeriod.add(_ez2.timeInPeriod)) {
				_liquidityFee = _ez2.liquidityFeeOnSell;
				_marketingFee = _ez2.marketingFeeOnSell;
				_devFee = _ez2.devFeeOnSell;
    			_buyBackFee = _ez2.buyBackFeeOnSell;
    			_charityFee = _ez2.charityFeeOnSell;
				_holdersFee = _ez2.holdersFeeOnSell;
			} 
		}
		
		_totalFee = _liquidityFee.add(_marketingFee).add(_devFee).add(_buyBackFee).add(_charityFee).add(_holdersFee);
		emit FeesApplied(isSelltoLp, isBuyFromLp, _liquidityFee, _marketingFee, _devFee, _buyBackFee, _charityFee, _holdersFee, _totalFee);
	}
	function _setCustomSellTaxPeriod(CustomTaxPeriod storage map,
		uint256 _liquidityFeeOnSell,
		uint256 _marketingFeeOnSell,
		uint256 _devFeeOnSell,
		uint256 _buyBackFeeOnSell,
		uint256 _charityFeeOnSell,
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
		if (map.buyBackFeeOnSell != _buyBackFeeOnSell) {
			emit CustomTaxPeriodChange(_buyBackFeeOnSell, map.buyBackFeeOnSell, 'buyBackFeeOnSell', map.periodName);
			map.buyBackFeeOnSell = _buyBackFeeOnSell;
		}
		if (map.charityFeeOnSell != _charityFeeOnSell) {
			emit CustomTaxPeriodChange(_charityFeeOnSell, map.charityFeeOnSell, 'charityFeeOnSell', map.periodName);
			map.charityFeeOnSell = _charityFeeOnSell;
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
		uint256 _buyBackFeeOnBuy,
		uint256 _charityFeeOnBuy,
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
		if (map.buyBackFeeOnBuy != _buyBackFeeOnBuy) {
			emit CustomTaxPeriodChange(_buyBackFeeOnBuy, map.buyBackFeeOnBuy, 'buyBackFeeOnBuy', map.periodName);
			map.buyBackFeeOnBuy = _buyBackFeeOnBuy;
		}
		if (map.charityFeeOnBuy != _charityFeeOnBuy) {
			emit CustomTaxPeriodChange(_charityFeeOnBuy, map.charityFeeOnBuy, 'charityFeeOnBuy', map.periodName);
			map.charityFeeOnBuy = _charityFeeOnBuy;
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
		uint256 amountForHolders = contractBalance.mul(_holdersFee).div(_totalFee);
		uint256 amountToSwap = contractBalance.sub(amountToLiquify.add(amountForHolders));

		_swapTokensForBNB(amountToSwap);

		uint256 bnbBalanceAfterSwap = address(this).balance.sub(initialBNBBalance);
		uint256 totalBNBFee = _totalFee.sub(_liquidityFee.div(2));
		uint256 amountBNBLiquidity = bnbBalanceAfterSwap.mul(_liquidityFee).div(totalBNBFee).div(2);
		uint256 amountBNBDev = bnbBalanceAfterSwap.mul(_devFee).div(totalBNBFee);
		uint256 amountBNBMarketing = bnbBalanceAfterSwap.mul(_marketingFee).div(totalBNBFee);
		uint256 amountBNBBuyBack = bnbBalanceAfterSwap.mul(_buyBackFee).div(totalBNBFee);
		uint256 amountBNBCharity = bnbBalanceAfterSwap.sub(amountBNBLiquidity.add(amountBNBDev).add(amountBNBMarketing).add(amountBNBBuyBack));

		payable(marketingWallet).transfer(amountBNBMarketing);
		payable(devWallet).transfer(amountBNBDev);
		payable(buyBackWallet).transfer(amountBNBBuyBack);
		payable(charityWallet).transfer(amountBNBCharity);
		
		if (amountToLiquify > 0) {
			_addLiquidity(amountToLiquify, amountBNBLiquidity);
			emit SwapAndLiquify(amountToSwap, amountBNBLiquidity, amountToLiquify);
		}

		(bool success) = IERC20(address(this)).transfer(address(dividendTracker), amountForHolders);
		if(success) {
			dividendTracker.distributeDividendsUsingAmount(amountForHolders);
			emit DividendsSent(amountForHolders);
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

contract RentEezDividendTracker is DividendPayingToken {
	using SafeMath for uint256;
	using SafeMathInt for int256;
	using IterableMapping for IterableMapping.Map;

	IterableMapping.Map private tokenHoldersMap;

	uint256 public lastProcessedIndex;
	mapping (address => bool) public excludedFromDividends;
	mapping (address => uint256) public lastClaimTimes;
	uint256 public claimWait;
	uint256 public minimumTokenBalanceForDividends;

	event ExcludeFromDividends(address indexed account);
	event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
	event Claim(address indexed account, uint256 amount, bool indexed automatic);

	constructor() public DividendPayingToken("RentEez_Dividend_Tracker", "RentEez_Dividend_Tracker") {
		claimWait = 3600;
		minimumTokenBalanceForDividends = 5000000 * (10**18);
	}
	function setRewardToken(address token) external onlyOwner {
	    _setRewardToken(token);
	}
	function _transfer(address, address, uint256) internal override {
		require(false, "RentEez_Dividend_Tracker: No transfers allowed");
	}
	function excludeFromDividends(address account) external onlyOwner {
		require(!excludedFromDividends[account]);
		excludedFromDividends[account] = true;
		_setBalance(account, 0);
		tokenHoldersMap.remove(account);
		emit ExcludeFromDividends(account);
	}
	function setTokenBalanceForDividends(uint256 newValue) external onlyOwner {
		require(minimumTokenBalanceForDividends != newValue, "RentEez_Dividend_Tracker: minimumTokenBalanceForDividends already the value of 'newValue'.");
		minimumTokenBalanceForDividends = newValue;
	}
	function updateClaimWait(uint256 newClaimWait) external onlyOwner {
		require(newClaimWait >= 3600 && newClaimWait <= 86400, "RentEez_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
		require(newClaimWait != claimWait, "RentEez_Dividend_Tracker: Cannot update claimWait to same value");
		emit ClaimWaitUpdated(newClaimWait, claimWait);
		claimWait = newClaimWait;
	}
	function getLastProcessedIndex() external view returns(uint256) {
		return lastProcessedIndex;
	}
	function getNumberOfTokenHolders() external view returns(uint256) {
		return tokenHoldersMap.keys.length;
	}
	function getAccount(address _account)
		public view returns (
		address account,
		int256 index,
		int256 iterationsUntilProcessed,
		uint256 withdrawableDividends,
		uint256 totalDividends,
		uint256 lastClaimTime,
		uint256 nextClaimTime,
		uint256 secondsUntilAutoClaimAvailable) {
			account = _account;

			index = tokenHoldersMap.getIndexOfKey(account);
			iterationsUntilProcessed = -1;
			if(index >= 0) {
				if(uint256(index) > lastProcessedIndex) {
					iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
				}
				else {
					uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ? tokenHoldersMap.keys.length.sub(lastProcessedIndex) : 0;
					iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
				}
			}
			withdrawableDividends = withdrawableDividendOf(account);
			totalDividends = accumulativeDividendOf(account);
			lastClaimTime = lastClaimTimes[account];
			nextClaimTime = lastClaimTime > 0 ? lastClaimTime.add(claimWait) : 0;
			secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ? nextClaimTime.sub(block.timestamp) : 0;
	}
	function getAccountAtIndex(uint256 index)
		public view returns (
		address,
		int256,
		int256,
		uint256,
		uint256,
		uint256,
		uint256,
		uint256) {
			if(index >= tokenHoldersMap.size()) {
				return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
			}
			address account = tokenHoldersMap.getKeyAtIndex(index);
			return getAccount(account);
	}
	function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
		if(lastClaimTime > block.timestamp)  {
			return false;
		}
		return block.timestamp.sub(lastClaimTime) >= claimWait;
	}
	function setBalance(address payable account, uint256 newBalance) external onlyOwner {
		if(excludedFromDividends[account]) {
			return;
		}
		if(newBalance >= minimumTokenBalanceForDividends) {
			_setBalance(account, newBalance);
			tokenHoldersMap.set(account, newBalance);
		}
		else {
			_setBalance(account, 0);
			tokenHoldersMap.remove(account);
		}
		processAccount(account, true);
	}
	function process(uint256 gas) public returns (uint256, uint256, uint256) {
		uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;
		if(numberOfTokenHolders == 0) {
			return (0, 0, lastProcessedIndex);
		}

		uint256 _lastProcessedIndex = lastProcessedIndex;
		uint256 gasUsed = 0;
		uint256 gasLeft = gasleft();
		uint256 iterations = 0;
		uint256 claims = 0;

		while(gasUsed < gas && iterations < numberOfTokenHolders) {
			_lastProcessedIndex++;
			if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
				_lastProcessedIndex = 0;
			}
			address account = tokenHoldersMap.keys[_lastProcessedIndex];
			if(canAutoClaim(lastClaimTimes[account])) {
				if(processAccount(payable(account), true)) {
					claims++;
				}
			}

			iterations++;
			uint256 newGasLeft = gasleft();
			if(gasLeft > newGasLeft) {
				gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
			}
			gasLeft = newGasLeft;
		}
		lastProcessedIndex = _lastProcessedIndex;
		return (iterations, claims, lastProcessedIndex);
	}

	function processAccount(address payable account, bool automatic) public onlyOwner returns (bool) {
		uint256 amount = _withdrawDividendOfUser(account);
		if(amount > 0) {
			lastClaimTimes[account] = block.timestamp;
			emit Claim(account, amount, automatic);
			return true;
		}
		return false;
	}
}
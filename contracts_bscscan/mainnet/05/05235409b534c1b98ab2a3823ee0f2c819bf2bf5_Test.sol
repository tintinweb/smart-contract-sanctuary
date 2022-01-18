/**
 *Submitted for verification at BscScan.com on 2022-01-18
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

interface DividendPayingTokenInterface {
	function dividendOf(address _owner) external view returns(uint256);
	function distributeDividends() external payable;
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

/// @title Dividend-Paying Token
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev A mintable ERC20 token that allows anyone to pay and distribute ether
///  to token holders as dividends and allows token holders to withdraw their dividends.
///  Reference: the source code of PoWH3D: https://etherscan.io/address/0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe#code
contract DividendPayingToken is ERC20, Ownable, DividendPayingTokenInterface, DividendPayingTokenOptionalInterface {
	using SafeMath for uint256;
	using SafeMathUint for uint256;
	using SafeMathInt for int256;
	
	uint256 constant internal magnitude = 2**128;
	uint256 internal magnifiedDividendPerShare;
	uint256 public totalDividendsDistributed;

	IERC20 BUSD = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
	address public rewardToken;

	IUniswapV2Router02 public uniswapV2Router;

	mapping(address => int256) internal magnifiedDividendCorrections;
	mapping(address => uint256) internal withdrawnDividends;

	constructor(string memory _name, string memory _symbol) public ERC20(_name, _symbol) {}

	receive() external payable {}
	
	function distributeDividends() public override onlyOwner payable {
		require(totalSupply() > 0);
		if (msg.value > 0) {
			magnifiedDividendPerShare = magnifiedDividendPerShare.add((msg.value).mul(magnitude) / totalSupply());
			emit DividendsDistributed(msg.sender, msg.value);
			totalDividendsDistributed = totalDividendsDistributed.add(msg.value);
		}
	}

	function distributeDividendsUsingAmount(uint256 amount) public onlyOwner {
        require(totalSupply() > 0);
        if (amount > 0) {
          magnifiedDividendPerShare = magnifiedDividendPerShare.add((amount).mul(magnitude) / totalSupply());
          emit DividendsDistributed(msg.sender, amount);
          totalDividendsDistributed = totalDividendsDistributed.add(amount);
        }
    }
	function withdrawDividend() public virtual override onlyOwner {
		_withdrawDividendOfUser(payable(msg.sender));
	}
	function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
		uint256 _withdrawableDividend = withdrawableDividendOf(user);
		if (_withdrawableDividend > 0) {
			withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
			emit DividendWithdrawn(user, _withdrawableDividend);
			if (rewardToken == address(BUSD)) {
				(bool success) = BUSD.transfer(user, _withdrawableDividend);
				if(!success) {
					withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
					return 0;
				}
				return _withdrawableDividend;
			} else {
				return swapBUSDForTokensAndWithdrawDividend(user, _withdrawableDividend);
			}
		}
		return 0;
	}
	function swapBUSDForTokensAndWithdrawDividend(address holder, uint256 busdAmount) private returns(uint256) {
		address[] memory path = new address[](3);
		path[0] = address(BUSD);
		path[1] = uniswapV2Router.WETH();
		path[2] = address(rewardToken);

		try uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
			busdAmount,
			0, // accept any amount of tokens
			path,
			address(holder),
			block.timestamp
		) {
			return busdAmount;
		} catch {
			withdrawnDividends[holder] = withdrawnDividends[holder].sub(busdAmount);
			return 0;
		}
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
	function _setUniswapRouter(address router) internal onlyOwner {
	    uniswapV2Router = IUniswapV2Router02(router);
	}
}

contract Test is ERC20, Ownable { //BGLToken

	IUniswapV2Router02 public uniswapV2Router;
	address public immutable uniswapV2Pair;

	string private _name = "Test"; //"BGL Token";
	string private _symbol = "Test"; //"BGL";
	uint8 private _decimals = 18;

	BGLFeeTracker public feeTracker;
	
	bool public isTradingEnabled;
	uint256 private _tradingPausedTimestamp;

	// initialSupply
	uint256 constant initialSupply = 10000000000 * (10**18);

	// max wallet is 1% of initialSupply
	uint256 public maxWalletAmount = initialSupply * 100 / 10000;

	// max buy and sell tx is 0.25% of initialSupply
	uint256 public maxTxAmount = initialSupply * 25 / 10000;

	bool private _swapping;
	uint256 public minimumTokensBeforeSwap = 500000000 * (10**18);
	uint256 public gasForProcessing = 300000;
	
	IERC20 BUSD = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
	address public dividendToken = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

	struct CustomTaxPeriod {
		bytes23 periodName;
		uint8 blocksInPeriod;
		uint256 timeInPeriod;
		uint256 liquidityFeeOnBuy;
		uint256 liquidityFeeOnSell;
		uint256 marketingFeeOnBuy;
		uint256 marketingFeeOnSell;
		uint256 giveAwayFeeOnBuy;
		uint256 giveAwayFeeOnSell;
		uint256 lastManStandingFeeOnBuy;
		uint256 lastManStandingFeeOnSell;
		uint256 holdersFeeOnBuy;
		uint256 holdersFeeOnSell;
	}

	// Launch taxes
	bool private _isLaunched;
	bool public launchElapsed;
	uint256 private _launchStartTimestamp;
	uint256 private _launchBlockNumber;
	CustomTaxPeriod private _launch1 = CustomTaxPeriod('launch1',3,0,2,100,4,0,1,0,1,0,10,0);
	CustomTaxPeriod private _launch2 = CustomTaxPeriod('launch2',0,3600,2,4,4,4,1,2,1,8,10,12);
	CustomTaxPeriod private _launch3 = CustomTaxPeriod('launch3',0,82800,2,2,4,2,1,1,1,8,10,12);

	// Base taxes
	CustomTaxPeriod private _default = CustomTaxPeriod('default',0,0,2,2,4,4,1,1,1,1,10,10);
	CustomTaxPeriod private _base = CustomTaxPeriod('base',0,0,2,2,4,4,1,1,1,1,10,10);

	// Power Hour taxes
	uint256 private _powerHourStartTimestamp;
	CustomTaxPeriod private _power1 = CustomTaxPeriod('power1',0,3600,0,4,0,4,0,2,0,1,8,12);
	CustomTaxPeriod private _power2 = CustomTaxPeriod('power2',0,3600,2,2,4,2,1,1,1,8,10,12);

	uint256 private _blockedTimeLimit = 172800;
	mapping (address => bool) private _isAllowedToTradeWhenDisabled;
	mapping (address => bool) private _isExcludedFromFee;
	mapping (address => bool) private _isExcludedFromMaxTransactionLimit;
	mapping (address => bool) private _isExcludedFromMaxWalletLimit;
	mapping (address => bool) private _isBlocked;
	mapping (address => bool) public automatedMarketMakerPairs;
	mapping (address => uint256) private _buyTimesInLaunch;

	uint256 private _liquidityFee;
	uint256 private _marketingFee;
	uint256 private _giveAwayFee;
	uint256 private _lastManStandingFee;
	uint256 private _holdersFee;
	uint256 private _totalFee;

	event AutomatedMarketMakerPairChange(address indexed pair, bool indexed value);
	event AllowedWhenTradingDisabledChange(address indexed account, bool isExcluded);
	event feeTrackerChange(address indexed newAddress, address indexed oldAddress);
	event UniswapV2RouterChange(address indexed newAddress, address indexed oldAddress);
	event ExcludeFromFeesChange(address indexed account, bool isExcluded);
	event GasForProcessingChange(uint256 indexed newValue, uint256 indexed oldValue);
	event FeeChange(string indexed identifier, uint256 liquidityFee, uint256 marketingFee, uint256 giveAwayFee, uint256 lastManStandingFee, uint256 holdersFee);
	event CustomTaxPeriodChange(uint256 indexed newValue, uint256 indexed oldValue, string indexed taxType, bytes23 period);
	event BlockedAccountChange(address indexed holder, bool indexed status);
	event PowerHourChange(bool indexed newValue, bool indexed oldValue);
	event MaxTransactionAmountChange(uint256 indexed newValue, uint256 indexed oldValue);
	event MaxWalletAmountChange(uint256 indexed newValue, uint256 indexed oldValue);
	event MinTokenAmountBeforeSwapChange(uint256 indexed newValue, uint256 indexed oldValue);
	event MinTokenAmountForDividendsChange(uint256 indexed newValue, uint256 indexed oldValue);
	event ExcludeFromMaxTransferChange(address indexed account, bool isExcluded);
	event ExcludeFromMaxWalletChange(address indexed account, bool isExcluded);
	event ExcludeFromDividendsChange(address indexed account, bool isExcluded);
	event DividendsSent(uint256 tokensSwapped);
	event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived,uint256 tokensIntoLiqudity);
    event ClaimBUSDOverflow(uint256 amount);
	event FeesApplied(uint256 liquidityFee, uint256 marketingFee, uint256 giveAwayFee, uint256 lastManStandingFee, uint256 holdersFee, uint256 totalFee);
	event DividendTokenChange(address newValue, address oldValue);

	constructor() public ERC20(_name, _symbol) {
		feeTracker = new BGLFeeTracker();
		feeTracker.setUniswapRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
		feeTracker.setRewardToken(dividendToken);
		feeTracker.setWallets(owner(), owner(), owner(), owner());

		IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); // Mainnet
		address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), address(BUSD));
		uniswapV2Router = _uniswapV2Router;
		uniswapV2Pair = _uniswapV2Pair;
		_setAutomatedMarketMakerPair(_uniswapV2Pair, true);

		_isExcludedFromFee[owner()] = true;
		_isExcludedFromFee[address(this)] = true;
		_isExcludedFromFee[address(feeTracker)] = true;

		feeTracker.excludeFromDividends(address(feeTracker));
		feeTracker.excludeFromDividends(address(this));
		feeTracker.excludeFromDividends(address(0x000000000000000000000000000000000000dEaD));
		feeTracker.excludeFromDividends(owner());
		feeTracker.excludeFromDividends(address(_uniswapV2Router));

		_isAllowedToTradeWhenDisabled[owner()] = true;

		_isExcludedFromMaxTransactionLimit[address(feeTracker)] = true;
		_isExcludedFromMaxTransactionLimit[address(this)] = true;

		_isExcludedFromMaxWalletLimit[_uniswapV2Pair] = true;
		_isExcludedFromMaxWalletLimit[address(feeTracker)] = true;
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
		_isLaunched = true;
		launchElapsed = false;
	}
	function cancelLaunch() public onlyOwner {
		require(this.isInLaunch(), "BGL: Launch is not set");
		_launchStartTimestamp = 0;
		_launchBlockNumber = 0;
		_isLaunched = false;
		launchElapsed = true;
	}
	function activateTrading() public onlyOwner {
		isTradingEnabled = true;
	}
	function deactivateTrading() public onlyOwner {
		isTradingEnabled = false;
		_tradingPausedTimestamp = _getNow();
	}
	function setPowerHour() public onlyOwner {
		require(!this.isInPowerHour(), "BGL: Power Hour is already set");
		require(isTradingEnabled, "BGL: Trading must be enabled first");
		require(!this.isInLaunch(), "BGL: Must not be in launch period");
		emit PowerHourChange(true, false);
		_powerHourStartTimestamp = _getNow();
	}
	function cancelPowerHour() public onlyOwner {
		require(this.isInPowerHour(), "BGL: Power Hour is not set");
		emit PowerHourChange(false, true);
		_powerHourStartTimestamp = 0;
	}
	function updatefeeTracker(address newAddress) public onlyOwner {
		require(newAddress != address(feeTracker), "BGL: The dividend tracker already has that address");
		BGLFeeTracker newfeeTracker = BGLFeeTracker(payable(newAddress));
		require(newfeeTracker.owner() == address(this), "BGL: The new dividend tracker must be owned by the BGL token contract");
		newfeeTracker.excludeFromDividends(address(newfeeTracker));
		newfeeTracker.excludeFromDividends(address(this));
		newfeeTracker.excludeFromDividends(owner());
		newfeeTracker.excludeFromDividends(address(uniswapV2Router));
		newfeeTracker.excludeFromDividends(address(uniswapV2Pair));
		emit feeTrackerChange(newAddress, address(feeTracker));
	
		feeTracker = newfeeTracker;
	}
	function _setAutomatedMarketMakerPair(address pair, bool value) private {
		require(automatedMarketMakerPairs[pair] != value, "BGL: Automated market maker pair is already set to that value");
		automatedMarketMakerPairs[pair] = value;
		if(value) {
			feeTracker.excludeFromDividends(pair);
		}
		emit AutomatedMarketMakerPairChange(pair, value);
	}
	function allowTradingWhenDisabled(address account, bool allowed) public onlyOwner {
		_isAllowedToTradeWhenDisabled[account] = allowed;
		emit AllowedWhenTradingDisabledChange(account, allowed);
	}
	function excludeFromFees(address account, bool excluded) public onlyOwner {
		require(_isExcludedFromFee[account] != excluded, "BGL: Account is already the value of 'excluded'");
		_isExcludedFromFee[account] = excluded;
		emit ExcludeFromFeesChange(account, excluded);
	}
	function excludeFromDividends(address account) public onlyOwner {
		feeTracker.excludeFromDividends(account);
	}
	function excludeFromMaxTransactionLimit(address account, bool excluded) public onlyOwner {
		require(_isExcludedFromMaxTransactionLimit[account] != excluded, "BGL: Account is already the value of 'excluded'");
		_isExcludedFromMaxTransactionLimit[account] = excluded;
		emit ExcludeFromMaxTransferChange(account, excluded);
	}
	function excludeFromMaxWalletLimit(address account, bool excluded) public onlyOwner {
		require(_isExcludedFromMaxWalletLimit[account] != excluded, "BGL: Account is already the value of 'excluded'");
		_isExcludedFromMaxWalletLimit[account] = excluded;
		emit ExcludeFromMaxWalletChange(account, excluded);
	}
	function blockAccount(address account) public onlyOwner {
		uint256 currentTimestamp = _getNow();
		require(!_isBlocked[account], "BGL: Account is already blocked");
		if (_isLaunched) {
			require(currentTimestamp - _launchStartTimestamp < _blockedTimeLimit, "BGL: Time to block accounts has expired");
		}
		_isBlocked[account] = true;
		emit BlockedAccountChange(account, true);
	}
	function unblockAccount(address account) public onlyOwner {
		require(_isBlocked[account], "BGL: Account is not blcoked");
		_isBlocked[account] = false;
		emit BlockedAccountChange(account, false);
	}
	function setWallets(address newLiquidityWallet, address newMarketingWallet, address newGiveAwayWallet, address newLastManStandingWallet) public onlyOwner {
		feeTracker.setWallets(newLiquidityWallet, newMarketingWallet, newGiveAwayWallet, newLastManStandingWallet);
	}
	function setAllFeesToZero() public onlyOwner {
		_setCustomBuyTaxPeriod(_base, 0, 0, 0, 0, 0);
		emit FeeChange('baseFees-Buy', 0, 0, 0, 0, 0);
		_setCustomSellTaxPeriod(_base, 0, 0, 0, 0, 0);
		emit FeeChange('baseFees-Sell', 0, 0, 0, 0, 0);
	}
	function resetAllFees() public onlyOwner {
		_setCustomBuyTaxPeriod(_base, _default.liquidityFeeOnBuy, _default.marketingFeeOnBuy, _default.giveAwayFeeOnBuy, _default.lastManStandingFeeOnBuy, _default.holdersFeeOnBuy);
		emit FeeChange('baseFees-Buy', _default.liquidityFeeOnBuy, _default.marketingFeeOnBuy, _default.giveAwayFeeOnBuy, _default.lastManStandingFeeOnBuy,  _default.holdersFeeOnBuy);
		_setCustomSellTaxPeriod(_base, _default.liquidityFeeOnSell, _default.marketingFeeOnSell, _default.giveAwayFeeOnSell, _default.lastManStandingFeeOnSell,  _default.holdersFeeOnSell);
		emit FeeChange('baseFees-Sell', _default.liquidityFeeOnSell, _default.marketingFeeOnSell, _default.giveAwayFeeOnSell, _default.lastManStandingFeeOnSell, _default.holdersFeeOnSell);
	}
	// Base fees
	function setBaseFeesOnBuy(uint256 _liquidityFeeOnBuy, uint256 _marketingFeeOnBuy, uint256 _giveAwayFeeOnBuy, uint256 _lastManStandingFeeOnBuy, uint256 _holdersFeeOnBuy) public onlyOwner {
		_setCustomBuyTaxPeriod(_base, _liquidityFeeOnBuy, _marketingFeeOnBuy, _giveAwayFeeOnBuy, _lastManStandingFeeOnBuy, _holdersFeeOnBuy);
		emit FeeChange('baseFees-Buy', _liquidityFeeOnBuy, _marketingFeeOnBuy, _giveAwayFeeOnBuy, _lastManStandingFeeOnBuy, _holdersFeeOnBuy);
	}
	function setBaseFeesOnSell(uint256 _liquidityFeeOnSell,uint256 _marketingFeeOnSell, uint256 _giveAwayFeeOnSell, uint256 _lastManStandingFeeOnSell, uint256 _holdersFeeOnSell) public onlyOwner {
		_setCustomSellTaxPeriod(_base, _liquidityFeeOnSell, _marketingFeeOnSell, _giveAwayFeeOnSell, _lastManStandingFeeOnSell, _holdersFeeOnSell);
		emit FeeChange('baseFees-Sell', _liquidityFeeOnSell, _marketingFeeOnSell, _giveAwayFeeOnSell, _lastManStandingFeeOnSell, _holdersFeeOnSell);
	}
	//Launch2 Fees
	function setLaunch2FeesOnBuy(uint256 _liquidityFeeOnBuy, uint256 _marketingFeeOnBuy, uint256 _giveAwayFeeOnBuy, uint256 _lastManStandingFeeOnBuy, uint256 _holdersFeeOnBuy) public onlyOwner {
		_setCustomBuyTaxPeriod(_launch2, _liquidityFeeOnBuy, _marketingFeeOnBuy, _giveAwayFeeOnBuy, _lastManStandingFeeOnBuy, _holdersFeeOnBuy);
		emit FeeChange('launch2Fees-Buy', _liquidityFeeOnBuy, _marketingFeeOnBuy, _giveAwayFeeOnBuy, _lastManStandingFeeOnBuy, _holdersFeeOnBuy);
	}
	function setLaunch2FeesOnSell(uint256 _liquidityFeeOnSell,uint256 _marketingFeeOnSell, uint256 _giveAwayFeeOnSell, uint256 _lastManStandingFeeOnSell, uint256 _holdersFeeOnSell) public onlyOwner {
		_setCustomSellTaxPeriod(_launch2, _liquidityFeeOnSell, _marketingFeeOnSell, _giveAwayFeeOnSell, _lastManStandingFeeOnSell, _holdersFeeOnSell);
		emit FeeChange('launch2Fees-Sell', _liquidityFeeOnSell, _marketingFeeOnSell, _giveAwayFeeOnSell, _lastManStandingFeeOnSell, _holdersFeeOnSell);
	}
	//Launch3 Fees
	function setLaunch3FeesOnBuy(uint256 _liquidityFeeOnBuy, uint256 _marketingFeeOnBuy, uint256 _giveAwayFeeOnBuy, uint256 _lastManStandingFeeOnBuy, uint256 _holdersFeeOnBuy) public onlyOwner {
		_setCustomBuyTaxPeriod(_launch3, _liquidityFeeOnBuy, _marketingFeeOnBuy, _giveAwayFeeOnBuy, _lastManStandingFeeOnBuy, _holdersFeeOnBuy);
		emit FeeChange('launch3Fees-Buy', _liquidityFeeOnBuy, _marketingFeeOnBuy, _giveAwayFeeOnBuy, _lastManStandingFeeOnBuy, _holdersFeeOnBuy);
	}
	function setLaunch3FeesOnSell(uint256 _liquidityFeeOnSell,uint256 _marketingFeeOnSell, uint256 _giveAwayFeeOnSell, uint256 _lastManStandingFeeOnSell, uint256 _holdersFeeOnSell) public onlyOwner {
		_setCustomSellTaxPeriod(_launch3, _liquidityFeeOnSell, _marketingFeeOnSell, _giveAwayFeeOnSell, _lastManStandingFeeOnSell, _holdersFeeOnSell);
		emit FeeChange('launch3Fees-Sell', _liquidityFeeOnSell, _marketingFeeOnSell, _giveAwayFeeOnSell, _lastManStandingFeeOnSell, _holdersFeeOnSell);
	}
	// Power Hour 1 Fees
	function setPowerHour1BuyFees(uint256 _liquidityFeeOnBuy,uint256 _marketingFeeOnBuy, uint256 _giveAwayFeeOnBuy, uint256 _lastManStandingFeeOnBuy, uint256 _holdersFeeOnBuy) public onlyOwner {
		_setCustomBuyTaxPeriod(_power1, _liquidityFeeOnBuy, _marketingFeeOnBuy, _giveAwayFeeOnBuy, _lastManStandingFeeOnBuy, _holdersFeeOnBuy);
		emit FeeChange('power1Fees-Buy', _liquidityFeeOnBuy, _marketingFeeOnBuy, _giveAwayFeeOnBuy, _lastManStandingFeeOnBuy, _holdersFeeOnBuy);
	}
	function setPowerHour1SellFees(uint256 _liquidityFeeOnSell,uint256 _marketingFeeOnSell, uint256 _giveAwayFeeOnSell, uint256 _lastManStandingFeeOnSell, uint256 _holdersFeeOnSell) public onlyOwner {
		_setCustomSellTaxPeriod(_power1, _liquidityFeeOnSell, _marketingFeeOnSell, _giveAwayFeeOnSell, _lastManStandingFeeOnSell, _holdersFeeOnSell);
		emit FeeChange('power1Fees-Sell', _liquidityFeeOnSell, _marketingFeeOnSell, _giveAwayFeeOnSell, _lastManStandingFeeOnSell, _holdersFeeOnSell);
	}
	// Power Hour 2 Fees
	function setPowerHour2BuyFees(uint256 _liquidityFeeOnBuy,uint256 _marketingFeeOnBuy, uint256 _giveAwayFeeOnBuy, uint256 _lastManStandingFeeOnBuy, uint256 _holdersFeeOnBuy) public onlyOwner {
		_setCustomBuyTaxPeriod(_power2, _liquidityFeeOnBuy, _marketingFeeOnBuy, _giveAwayFeeOnBuy, _lastManStandingFeeOnBuy, _holdersFeeOnBuy);
		emit FeeChange('power2Fees-Buy', _liquidityFeeOnBuy, _marketingFeeOnBuy, _giveAwayFeeOnBuy, _lastManStandingFeeOnBuy, _holdersFeeOnBuy);
	}
	function setPowerHour2SellFees(uint256 _liquidityFeeOnSell,uint256 _marketingFeeOnSell, uint256 _giveAwayFeeOnSell, uint256 _lastManStandingFeeOnSell, uint256 _holdersFeeOnSell) public onlyOwner {
		_setCustomSellTaxPeriod(_power2, _liquidityFeeOnSell, _marketingFeeOnSell, _giveAwayFeeOnSell, _lastManStandingFeeOnSell, _holdersFeeOnSell);
		emit FeeChange('power2Fees-Sell', _liquidityFeeOnSell, _marketingFeeOnSell, _giveAwayFeeOnSell, _lastManStandingFeeOnSell, _holdersFeeOnSell);
	}
	function setUniswapRouter(address newAddress) public onlyOwner {
		require(newAddress != address(uniswapV2Router), "BGL: The router already has that address");
		emit UniswapV2RouterChange(newAddress, address(uniswapV2Router));
		uniswapV2Router = IUniswapV2Router02(newAddress);
		feeTracker.setUniswapRouter(newAddress);
	}
	function setGasForProcessing(uint256 newValue) public onlyOwner {
		require(newValue != gasForProcessing, "BGL: Cannot update gasForProcessing to same value");
		emit GasForProcessingChange(newValue, gasForProcessing);
		gasForProcessing = newValue;
	}
	function setMaxTransactionAmount(uint256 newValue) public onlyOwner {
		require(newValue != maxTxAmount, "BGL: Cannot update maxTxAmount to same value");
		emit MaxTransactionAmountChange(newValue, maxTxAmount);
		maxTxAmount = newValue;
	}
	function setMaxWalletAmount(uint256 newValue) public onlyOwner {
		require(newValue != maxWalletAmount, "BGL: Cannot update maxWalletAmount to same value");
		emit MaxWalletAmountChange(newValue, maxWalletAmount);
		maxWalletAmount = newValue;
	}
	function setMinimumTokensBeforeSwap(uint256 newValue) public onlyOwner {
		require(newValue != minimumTokensBeforeSwap, "BGL: Cannot update minimumTokensBeforeSwap to same value");
		emit MinTokenAmountBeforeSwapChange(newValue, minimumTokensBeforeSwap);
		minimumTokensBeforeSwap = newValue;
	}
	function setMinimumTokenBalanceForDividends(uint256 newValue) public onlyOwner {
		feeTracker.setTokenBalanceForDividends(newValue);
	}
	function updateClaimWait(uint256 claimWait) external onlyOwner {
		feeTracker.updateClaimWait(claimWait);
	}
	function processfeeTracker(uint256 gas) external {
		(uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = feeTracker.process(gas);
	}
	function claim() external {
		feeTracker.processAccount(payable(msg.sender), false);
    }
	function setDividendToken(address newDividendToken) external onlyOwner {
		require(newDividendToken != dividendToken, "BGL: Cannot update dividend token to same value");
		require(newDividendToken != address(0), "BGL: The dividend token cannot be 0");
		require(newDividendToken != address(this), "BGL: The dividend token cannot be set to the current contract");
		emit DividendTokenChange(newDividendToken, dividendToken);
		dividendToken = newDividendToken;
		feeTracker.setRewardToken(dividendToken);
	}
	function claimBUSDOverflow(uint256 amount) external onlyOwner {
	    require(amount < BUSD.balanceOf(address(this)), "BGL: Cannot send more than contract balance");
        (bool success,) = address(owner()).call{value : amount}("");
        if (success){
            emit ClaimBUSDOverflow(amount);
        }
	}
	function addLiquidityManual(address ad1, address ad2, uint256 tokenAmount, uint256 busdAmount, address to) external onlyOwner {
		feeTracker.addLiquidity2(ad1, ad2, tokenAmount, busdAmount, to);
	}

	// Getters
	function timeSinceLastPowerHour() external view returns(uint256){
	    uint256 currentTimestamp = !isTradingEnabled && _tradingPausedTimestamp > _powerHourStartTimestamp  ? _tradingPausedTimestamp : _getNow();
		return currentTimestamp - _powerHourStartTimestamp;
	}
	function getWallets() external view returns(address, address, address, address) {
		return (feeTracker.liquidityWallet(), feeTracker.marketingWallet(), feeTracker.giveAwayWallet(), feeTracker.lastManStandingWallet());
	}
	function getTokenContract() external view returns(address) {
		return feeTracker.tokenContract();
	}
	function isInPowerHour() external view returns (bool) {
		uint256 currentTimestamp = !isTradingEnabled && _tradingPausedTimestamp > _powerHourStartTimestamp  ? _tradingPausedTimestamp : _getNow();
		return currentTimestamp - _powerHourStartTimestamp < _power1.timeInPeriod + _power2.timeInPeriod ? true : false;
	}
	function isInLaunch() external returns (bool) {
		uint256 currentTimestamp = !isTradingEnabled && _tradingPausedTimestamp > _launchStartTimestamp  ? _tradingPausedTimestamp : _getNow();
		uint256 timeSinceLaunch = currentTimestamp - _launchStartTimestamp;
		uint256 blocksSinceLaunch = block.number - _launchBlockNumber;
		uint256 totalLaunchTime =  _launch1.timeInPeriod + _launch2.timeInPeriod + _launch3.timeInPeriod;
		if (!launchElapsed && _isLaunched && (timeSinceLaunch < totalLaunchTime || blocksSinceLaunch < _launch1.blocksInPeriod )) {
			return true; 
		} else {
			launchElapsed = true;
			return false;
		}
	}
	function getTotalDividendsDistributed() external view returns (uint256) {
		return feeTracker.totalDividendsDistributed();
	}
	function withdrawableDividendOf(address account) public view returns(uint256) {
		return feeTracker.withdrawableDividendOf(account);
	}
	function dividendTokenBalanceOf(address account) public view returns (uint256) {
		return feeTracker.balanceOf(account);
	}
	function getNumberOfDividendTokenHolders() external view returns(uint256) {
		return feeTracker.getNumberOfTokenHolders();
	}
	function getBaseBuyFees() external view returns (uint256, uint256, uint256, uint256, uint256){
		return (_base.liquidityFeeOnBuy, _base.marketingFeeOnBuy, _base.giveAwayFeeOnBuy, _base.lastManStandingFeeOnBuy, _base.holdersFeeOnBuy);
	}
	function getBaseSellFees() external view returns (uint256, uint256, uint256, uint256, uint256){
		return (_base.liquidityFeeOnSell, _base.marketingFeeOnSell, _base.giveAwayFeeOnSell, _base.lastManStandingFeeOnSell, _base.holdersFeeOnSell);
	}
	function getpower1BuyFees() external view returns (uint256, uint256, uint256, uint256, uint256){
		return (_power1.liquidityFeeOnBuy, _power1.marketingFeeOnBuy, _power1.giveAwayFeeOnBuy, _power1.lastManStandingFeeOnBuy, _power1.holdersFeeOnBuy);
	}
	function getpower1SellFees() external view returns (uint256, uint256, uint256, uint256, uint256){
		return (_power1.liquidityFeeOnSell, _power1.marketingFeeOnSell, _power1.giveAwayFeeOnSell, _power1.lastManStandingFeeOnSell, _power1.holdersFeeOnSell);
	}
	function getpower2BuyFees() external view returns (uint256, uint256, uint256, uint256, uint256){
		return (_power2.liquidityFeeOnBuy, _power2.marketingFeeOnBuy, _power2.giveAwayFeeOnBuy, _power2.lastManStandingFeeOnBuy, _power2.holdersFeeOnBuy);
	}
	function getpower2SellFees() external view returns (uint256, uint256, uint256, uint256, uint256){
		return (_power2.liquidityFeeOnSell, _power2.marketingFeeOnSell, _power2.giveAwayFeeOnSell, _power2.lastManStandingFeeOnSell, _power2.holdersFeeOnSell);
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
			bool _isInLaunch = !launchElapsed && this.isInLaunch();

			uint256 currentTimestamp = !isTradingEnabled && _tradingPausedTimestamp > _launchStartTimestamp  ? _tradingPausedTimestamp : _getNow();

			if(!_isAllowedToTradeWhenDisabled[from] && !_isAllowedToTradeWhenDisabled[to]) {
				require(isTradingEnabled, "BGL: Trading is currently disabled.");
				require(!_isBlocked[to], "BGL: Account is blocked");
				require(!_isBlocked[from], "BGL: Account is blocked");
				if (_isInLaunch && currentTimestamp - _launchStartTimestamp <= 300 && isBuyFromLp) {
					require(currentTimestamp - _buyTimesInLaunch[to] > 60, "BGL: Cannot buy more than once per min in first 5min of launch");
				}
				if (!_isExcludedFromMaxTransactionLimit[to] && !_isExcludedFromMaxTransactionLimit[from]) {
					require(amount <= maxTxAmount, "BGL: Buy amount exceeds the maxTxBuyAmount.");
				}
				if (!_isExcludedFromMaxWalletLimit[to]) {
					require((balanceOf(to) + amount) <= maxWalletAmount, "BGL: Expected wallet amount exceeds the maxWalletAmount.");
				}
			}

			_adjustTaxes(isBuyFromLp, isSelltoLp);
			bool canSwap = balanceOf(address(this)) >= minimumTokensBeforeSwap;

			if (
				isTradingEnabled &&
				canSwap &&
				!_swapping &&
				_totalFee > 0 &&
				automatedMarketMakerPairs[to]
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
				uint256 fee = amount * _totalFee / 100;
				amount = amount - fee;
				super._transfer(from, address(this), fee);
				emit FeesApplied(_liquidityFee, _marketingFee, _giveAwayFee, _lastManStandingFee, _holdersFee, _totalFee);
			}

			if (_isInLaunch && currentTimestamp - _launchStartTimestamp <= 300) {
				if (to != owner() && isBuyFromLp  && currentTimestamp - _buyTimesInLaunch[to] > 60) {
					_buyTimesInLaunch[to] = currentTimestamp;
				}
			}

			super._transfer(from, to, amount);

			try feeTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
			try feeTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

			if(!_swapping) {
				uint256 gas = gasForProcessing;
				try feeTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {}
				catch {}
			}
	}
	function _adjustTaxes(bool isBuyFromLp, bool isSelltoLp) private {
	    uint256 blocksSinceLaunch = block.number - _launchBlockNumber;
	    uint256 currentTimestamp = !isTradingEnabled && _tradingPausedTimestamp > _launchStartTimestamp  ? _tradingPausedTimestamp : _getNow();
		uint256 timeSinceLaunch = currentTimestamp - _launchStartTimestamp;
		uint256 timeInLaunch = _launch3.timeInPeriod + _launch2.timeInPeriod;
		uint256 timeSincePower = currentTimestamp - _powerHourStartTimestamp;
		_liquidityFee = _base.liquidityFeeOnBuy;
		_marketingFee = _base.marketingFeeOnBuy;
		_giveAwayFee = _base.giveAwayFeeOnBuy;
		_lastManStandingFee = _base.lastManStandingFeeOnBuy;
		_holdersFee = _base.holdersFeeOnBuy;
			
		if (isBuyFromLp) {	
			if (!launchElapsed && _isLaunched && blocksSinceLaunch < _launch1.blocksInPeriod) {
				_liquidityFee = _launch1.liquidityFeeOnBuy;
				_marketingFee = _launch1.marketingFeeOnBuy;
				_giveAwayFee = _launch1.giveAwayFeeOnBuy;
				_lastManStandingFee = _launch1.lastManStandingFeeOnBuy;
				_holdersFee = _launch1.holdersFeeOnBuy;
			}
			else if (!launchElapsed && _isLaunched && timeSinceLaunch <= _launch2.timeInPeriod && blocksSinceLaunch > _launch1.blocksInPeriod) {
				_liquidityFee = _launch2.liquidityFeeOnBuy;
				_marketingFee = _launch2.marketingFeeOnBuy;
				_giveAwayFee = _launch2.giveAwayFeeOnBuy;
				_lastManStandingFee = _launch2.lastManStandingFeeOnBuy;
				_holdersFee = _launch2.holdersFeeOnBuy;
			}
			else if (!launchElapsed && _isLaunched && timeSinceLaunch > _launch2.timeInPeriod && timeSinceLaunch <= timeInLaunch && blocksSinceLaunch > _launch1.blocksInPeriod) {
				_liquidityFee = _launch3.liquidityFeeOnBuy;
				_marketingFee = _launch3.marketingFeeOnBuy;
				_giveAwayFee = _launch3.giveAwayFeeOnBuy;
				_lastManStandingFee = _launch3.lastManStandingFeeOnBuy;
				_holdersFee = _launch3.holdersFeeOnBuy;
			}
			else if (timeSincePower <= _power1.timeInPeriod) {
				_liquidityFee = _power1.liquidityFeeOnBuy;
				_marketingFee = _power1.marketingFeeOnBuy;
				_giveAwayFee = _power1.giveAwayFeeOnBuy;
				_lastManStandingFee = _power1.lastManStandingFeeOnBuy;
				_holdersFee = _power1.holdersFeeOnBuy;
			}
			else if (timeSincePower > _power1.timeInPeriod && timeSincePower <= _power1.timeInPeriod + _power2.timeInPeriod) {
				_liquidityFee = _power2.liquidityFeeOnBuy;
				_marketingFee = _power2.marketingFeeOnBuy;
				_giveAwayFee = _power2.giveAwayFeeOnBuy;
				_lastManStandingFee = _power2.lastManStandingFeeOnBuy;
				_holdersFee = _power2.holdersFeeOnBuy;
			}
		}
	    if (isSelltoLp) {
	    	_liquidityFee = _base.liquidityFeeOnSell;
			_marketingFee = _base.marketingFeeOnSell;
			_giveAwayFee = _base.giveAwayFeeOnSell;
			_lastManStandingFee = _base.lastManStandingFeeOnSell;
			_holdersFee = _base.holdersFeeOnSell;
			
			if (!launchElapsed && _isLaunched && blocksSinceLaunch < _launch1.blocksInPeriod) {
				_liquidityFee = _launch1.liquidityFeeOnSell;
				_marketingFee = _launch1.marketingFeeOnSell;
				_giveAwayFee = _launch1.giveAwayFeeOnSell;
				_lastManStandingFee = _launch1.lastManStandingFeeOnSell;
				_holdersFee = _launch1.holdersFeeOnSell;
			}
			else if (!launchElapsed && _isLaunched && timeSinceLaunch <= _launch2.timeInPeriod && blocksSinceLaunch > _launch1.blocksInPeriod) {
				_liquidityFee = _launch2.liquidityFeeOnSell;
				_marketingFee = _launch2.marketingFeeOnSell;
				_giveAwayFee = _launch2.giveAwayFeeOnSell;
				_lastManStandingFee = _launch2.lastManStandingFeeOnSell;
				_holdersFee = _launch2.holdersFeeOnSell;
			}
			else if (!launchElapsed && _isLaunched && timeSinceLaunch > _launch2.timeInPeriod && timeSinceLaunch <= timeInLaunch && blocksSinceLaunch > _launch1.blocksInPeriod) {
				_liquidityFee = _launch3.liquidityFeeOnSell;
				_marketingFee = _launch3.marketingFeeOnSell;
				_giveAwayFee = _launch3.giveAwayFeeOnSell;
				_lastManStandingFee = _launch3.lastManStandingFeeOnSell;
				_holdersFee = _launch3.holdersFeeOnSell;
			}
			else if (timeSincePower <= _power1.timeInPeriod) {
				_liquidityFee = _power1.liquidityFeeOnSell;
				_marketingFee = _power1.marketingFeeOnSell;
				_giveAwayFee = _power1.giveAwayFeeOnSell;
				_lastManStandingFee = _power1.lastManStandingFeeOnSell;
				_holdersFee = _power1.holdersFeeOnSell;
			}
			else if (timeSincePower > _power1.timeInPeriod && timeSincePower <= _power1.timeInPeriod + _power2.timeInPeriod) {
				_liquidityFee = _power2.liquidityFeeOnSell;
				_marketingFee = _power2.marketingFeeOnSell;
				_giveAwayFee = _power2.giveAwayFeeOnSell;
				_lastManStandingFee = _power2.lastManStandingFeeOnSell;
				_holdersFee = _power2.holdersFeeOnSell;
			} 
		}
		_totalFee = _liquidityFee + _marketingFee + _giveAwayFee + _lastManStandingFee + _holdersFee;
	}
	function _setCustomSellTaxPeriod(CustomTaxPeriod storage map,
		uint256 _liquidityFeeOnSell,
		uint256 _marketingFeeOnSell,
		uint256 _giveAwayFeeOnSell,
		uint256 _lastManStandingFeeOnSell,
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
		if (map.giveAwayFeeOnSell != _giveAwayFeeOnSell) {
			emit CustomTaxPeriodChange(_giveAwayFeeOnSell, map.giveAwayFeeOnSell, 'giveAwayFeeOnSell', map.periodName);
			map.giveAwayFeeOnSell = _giveAwayFeeOnSell;
		}
		if (map.lastManStandingFeeOnSell != _lastManStandingFeeOnSell) {
			emit CustomTaxPeriodChange(_lastManStandingFeeOnSell, map.lastManStandingFeeOnSell, 'lastManStandingFeeOnSell', map.periodName);
			map.lastManStandingFeeOnSell = _lastManStandingFeeOnSell;
		}
		if (map.holdersFeeOnSell != _holdersFeeOnSell) {
			emit CustomTaxPeriodChange(_holdersFeeOnSell, map.holdersFeeOnSell, 'holdersFeeOnSell', map.periodName);
			map.holdersFeeOnSell = _holdersFeeOnSell;
		}
	}
	function _setCustomBuyTaxPeriod(CustomTaxPeriod storage map,
		uint256 _liquidityFeeOnBuy,
		uint256 _marketingFeeOnBuy,
		uint256 _giveAwayFeeOnBuy,
		uint256 _lastManStandingFeeOnBuy,
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
		if (map.giveAwayFeeOnBuy != _giveAwayFeeOnBuy) {
			emit CustomTaxPeriodChange(_giveAwayFeeOnBuy, map.giveAwayFeeOnBuy, 'giveAwayFeeOnBuy', map.periodName);
			map.giveAwayFeeOnBuy = _giveAwayFeeOnBuy;
		}
		if (map.lastManStandingFeeOnBuy != _lastManStandingFeeOnBuy) {
			emit CustomTaxPeriodChange(_lastManStandingFeeOnBuy, map.lastManStandingFeeOnBuy, 'lastManStandingFeeOnBuy', map.periodName);
			map.lastManStandingFeeOnBuy = _lastManStandingFeeOnBuy;
		}
		if (map.holdersFeeOnBuy != _holdersFeeOnBuy) {
			emit CustomTaxPeriodChange(_holdersFeeOnBuy, map.holdersFeeOnBuy, 'holdersFeeOnBuy', map.periodName);
			map.holdersFeeOnBuy = _holdersFeeOnBuy;
		}
	}
	function _swapAndLiquify() private {
		uint256 contractBalance = balanceOf(address(this));
		uint256 initialBUSDBalance = BUSD.balanceOf(address(this));
	
		uint256 amountToLiquify = contractBalance * _liquidityFee / _totalFee / 2;
		uint256 amountToSwap = contractBalance - amountToLiquify;
		uint256 baseFee = _totalFee - (_liquidityFee / 2);

		_swapTokensForBUSD(amountToSwap);

		uint256 BUSDBalanceAfterSwap = BUSD.balanceOf(address(this)) - initialBUSDBalance;
		uint256 amountLiquidity = BUSDBalanceAfterSwap * _liquidityFee / baseFee / 2;
		uint256 amountMarketing = BUSDBalanceAfterSwap * _marketingFee / baseFee;
		uint256 amountGiveAway = BUSDBalanceAfterSwap * _giveAwayFee / baseFee;
		uint256 amountLastManStanding = BUSDBalanceAfterSwap * _lastManStandingFee / baseFee;
		uint256 amountHolders = BUSDBalanceAfterSwap - (amountLiquidity + amountMarketing + amountGiveAway + amountLastManStanding);
				
		feeTracker.distributeFeesToWallets(amountMarketing, amountGiveAway, amountLastManStanding);

		if (amountToLiquify > 0) {
			(bool success) = IERC20(address(this)).transfer(address(feeTracker), amountToLiquify);
		 	//feeTracker.addLiquidity(amountToLiquify, amountLiquidity);
			emit SwapAndLiquify(amountToSwap, amountLiquidity, amountToLiquify);
		}
		
		if(amountHolders > 0) {
			feeTracker.distributeDividendsUsingAmount(amountHolders);
			emit DividendsSent(amountHolders);
		}
	}
	function _swapTokensForBUSD(uint256 tokenAmount) private {
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = address(BUSD);
		
		_approve(address(this), address(uniswapV2Router), tokenAmount);

		uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
			tokenAmount,
			0, // accept any amount
			path,
			address(feeTracker),
			block.timestamp
		);
	}
}

contract BGLFeeTracker is DividendPayingToken {
	using SafeMath for uint256;
	using SafeMathInt for int256;
	using IterableMapping for IterableMapping.Map;

	IterableMapping.Map private tokenHoldersMap;

	address public liquidityWallet; 
	address public marketingWallet;
	address public giveAwayWallet;
	address public lastManStandingWallet;

	address public tokenContract;

	uint256 public lastProcessedIndex;
	mapping (address => bool) public excludedFromDividends;
	mapping (address => uint256) public lastClaimTimes;
	uint256 public claimWait;
	uint256 public minimumTokenBalanceForDividends;

	event ExcludeFromDividends(address indexed account);
	event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
	event Claim(address indexed account, uint256 amount, bool indexed automatic);
	event WalletChange(string indexed indentifier, address indexed newWallet, address indexed oldWallet);

	constructor() public DividendPayingToken("BGLToken_Dividend_Tracker", "BGLToken_Dividend_Tracker") {
		claimWait = 3600;
		minimumTokenBalanceForDividends = 200000000 * (10**18);

		liquidityWallet = owner();
		marketingWallet = owner();
		giveAwayWallet = owner();
		lastManStandingWallet = owner();

		tokenContract = owner();
	}
	function setRewardToken(address token) external onlyOwner {
	    _setRewardToken(token);
	}
	function setUniswapRouter(address router) external onlyOwner {
	    _setUniswapRouter(router);
	}
	function distributeFeesToWallets(uint256 amountMarketing, uint256 amountGiveAway, uint256 amountLastManStanding) external onlyOwner {
		(bool success) = BUSD.transfer(marketingWallet, amountMarketing);
		(success) = BUSD.transfer(giveAwayWallet, amountGiveAway);
		(success) = BUSD.transfer(lastManStandingWallet, amountLastManStanding);
	}
	function addLiquidity(uint256 tokenAmount, uint256 busdAmount) external onlyOwner {
		_approve(address(this), address(uniswapV2Router), busdAmount);
		_approve(address(this), address(uniswapV2Router), tokenAmount);
		
		uniswapV2Router.addLiquidity( 
			address(BUSD),
			address(tokenContract),
			busdAmount,
			tokenAmount,
			0, // slippage is unavoidable
			0, // slippage is unavoidable
			liquidityWallet,
			block.timestamp
		);
	}
	function addLiquidity2(address ad1, address ad2, uint256 tokenAmount, uint256 busdAmount, address to) external onlyOwner {
		_approve(address(this), address(uniswapV2Router), busdAmount);
		_approve(address(this), address(uniswapV2Router), tokenAmount);
		
		uniswapV2Router.addLiquidity( 
			ad1,
			ad2,
			busdAmount,
			tokenAmount,
			0, // slippage is unavoidable
			0, // slippage is unavoidable
			to,
			block.timestamp
		);
	}
	function setWallets(address newLiquidityWallet, address newMarketingWallet, address newGiveAwayWallet, address newLastManStandingWallet) external onlyOwner {
		if(liquidityWallet != newLiquidityWallet) {
			require(newLiquidityWallet != address(0), "BGLToken_Dividend_Tracker: The liquidityWallet cannot be 0");
			emit WalletChange('liquidityWallet', newLiquidityWallet, liquidityWallet);
			liquidityWallet = newLiquidityWallet;
		}
		if(marketingWallet != newMarketingWallet) {
			require(newMarketingWallet != address(0), "BGLToken_Dividend_Tracker: The marketingWallet cannot be 0");
			emit WalletChange('marketingWallet', newMarketingWallet, marketingWallet);
			marketingWallet = newMarketingWallet;
		}
		if(giveAwayWallet != newGiveAwayWallet) {
			require(newGiveAwayWallet != address(0), "BGLToken_Dividend_Tracker: The giveAwayWallet cannot be 0");
			emit WalletChange('giveAwayWallet', newGiveAwayWallet, giveAwayWallet);
			giveAwayWallet = newGiveAwayWallet;
		}
		if(lastManStandingWallet != newLastManStandingWallet) {
			require(newLastManStandingWallet != address(0), "BGLToken_Dividend_Tracker: The lastManStandingWallet cannot be 0");
			emit WalletChange('lastManStandingWallet', newLastManStandingWallet, lastManStandingWallet);
			lastManStandingWallet = newLastManStandingWallet;
		}
	}
	function _transfer(address, address, uint256) internal override {
		require(false, "BGLToken_Dividend_Tracker: No transfers allowed");
	}
	function excludeFromDividends(address account) external onlyOwner {
		require(!excludedFromDividends[account]);
		excludedFromDividends[account] = true;
		_setBalance(account, 0);
		tokenHoldersMap.remove(account);
		emit ExcludeFromDividends(account);
	}
	function setTokenBalanceForDividends(uint256 newValue) external onlyOwner {
		require(minimumTokenBalanceForDividends != newValue, "BGLToken_Dividend_Tracker: minimumTokenBalanceForDividends already the value of 'newValue'.");
		minimumTokenBalanceForDividends = newValue;
	}
	function updateClaimWait(uint256 newClaimWait) external onlyOwner {
		require(newClaimWait >= 3600 && newClaimWait <= 86400, "BGLToken_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
		require(newClaimWait != claimWait, "BGLToken_Dividend_Tracker: Cannot update claimWait to same value");
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
	function setToZero(address account) external onlyOwner {
		_setBalance(account, 0);
	}
	function rmeoveHolder(address account) external onlyOwner {
		tokenHoldersMap.remove(account);
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
	function process(uint256 gas) public onlyOwner returns (uint256, uint256, uint256) {
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
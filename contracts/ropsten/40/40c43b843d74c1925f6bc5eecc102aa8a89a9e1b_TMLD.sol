/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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
        require(b != - 1 || a != MIN_INT256);

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
        return a < 0 ? - a : a;
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
        if (!map.inserted[key]) {
            return - 1;
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

contract TMLD is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
	address public immutable uniswapV2Pair;

	string private _name = "TMLD";
	string private _symbol = "TMLD";
	uint8 private _decimals = 9;

	bool public isTradingEnabled;
	uint256 private _tradingPausedTimestamp = 0;

	// initialSupply is 100 million
	uint256 constant initialSupply = 100000000 * (10 ** 9);
	bool public _swapping;
	uint256 public minimumTokensBeforeSwap = 25000000 * (10 ** 9);

	address public liquidityWallet;
	address public marketingWallet;
	address public insuranceWallet;
	address public devWallet;
	address public lendWallet;
	
    // max buy and sell tx is 0.2% of initialSupply
	uint256 public maxTxAmount = initialSupply * 20 / 10000;
	// max wallet is 2% of initialSupply 
	uint256 public maxWalletAmount = initialSupply * 200 / 10000;  

	mapping (address => bool) private _isExcludedFromFee;
	mapping (address => bool) private _isExcludedFromMaxTransactionLimit;
	mapping (address => bool) private _isExcludedFromMaxWalletLimit;

	struct CustomTaxPeriod {
		bytes23 periodName;
		uint8 blocksInPeriod;
		uint256 timeInPeriod;
		uint256 liquidityFeeOnBuy;
		uint256 liquidityFeeOnSell;
		uint256 marketingFeeOnBuy;
		uint256 marketingFeeOnSell;
		uint256 insuranceFeeOnBuy;
		uint256 insuranceFeeOnSell;
		uint256 devFeeOnBuy;
		uint256 devFeeOnSell;
		uint256 lendFeeOnBuy;
		uint256 lendFeeOnSell;
		uint256 burnFeeOnBuy;
		uint256 burnFeeOnSell;
	}

	// Base taxes
	CustomTaxPeriod private _default = CustomTaxPeriod('default',0,0,2,2,1,1,2,2,1,1,4,9,0,0);
	CustomTaxPeriod private _base = CustomTaxPeriod('base',0,0,2,2,1,1,2,2,1,1,4,9,0,0);
	CustomTaxPeriod private _alternate = CustomTaxPeriod('alternate',0,0,2,2,1,1,2,2,1,1,4,9,0,0);

	mapping(address => bool) public _isBlocked;
	mapping(address => bool) public automatedMarketMakerPairs;
	bool public burnEnabled = true;	
	mapping(address => bool) public _alternateFees;

	uint256 public _liquidityFee;
	uint256 public _marketingFee;
	uint256 public _insuranceFee;
	uint256 public _devFee;
	uint256 public _lendFee;
	uint256 public _burnFee;
	uint256 public _totalFee;

	event AutomatedMarketMakerPairChange(address indexed pair, bool indexed value);
	event UniswapV2RouterChange(address indexed newAddress, address indexed oldAddress);
	event ExcludeFromFeesChange(address indexed account, bool isExcluded);
	event WalletChange(address indexed newWallet, address indexed oldWallet);
	event FeeChange(string indexed identifier, uint256 liquidityFee, uint256 marketingFee, uint256 insuranceFee, uint256 devFee, uint256 lendFee, uint256 burnFee);
	event CustomTaxPeriodChange(uint256 indexed newValue, uint256 indexed oldValue, string indexed taxType, bytes23 period);
	event BlockedAccountChange(address indexed holder, bool indexed status);
	event MinTokenAmountBeforeSwapChange(uint256 indexed newValue, uint256 indexed oldValue);
	event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
	event LiquidityFormulaChanged(bool newValue, bool oldValue);
	event BurnEnabledChange(bool newValue, bool oldValue);
	event AlternateFeesChange(address wallet, bool value);
    event ExcludeFromMaxTransferChange(address indexed account, bool isExcluded);
	event ExcludeFromMaxWalletChange(address indexed account, bool isExcluded);
	event MaxWalletAmountChange(uint256 indexed newValue, uint256 indexed oldValue);
	event MaxTransactionAmountChange(uint256 indexed newValue, uint256 indexed oldValue);
    event ClaimEthOverflow(uint256 amount);
	event FeesApplied(uint256 liquidityFee, uint256 marketingFee, uint256 insuranceFee, uint256 devFee, uint256 lendFee, uint256 burnFee, uint256 totalFee);
    event TokenBurn(uint256 _burnFee, uint256 burnAmount);

	constructor() public ERC20(_name, _symbol) {
		liquidityWallet = owner();
		marketingWallet = owner();
		insuranceWallet = owner();
		devWallet = owner();
		lendWallet = owner();

		IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
		address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
		uniswapV2Router = _uniswapV2Router;
		uniswapV2Pair = _uniswapV2Pair;
		_setAutomatedMarketMakerPair(_uniswapV2Pair, true);

		_isExcludedFromFee[owner()] = true;
		_isExcludedFromFee[address(this)] = true;

		_isExcludedFromMaxTransactionLimit[address(this)] = true;

		_isExcludedFromMaxWalletLimit[_uniswapV2Pair] = true;
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
	function decimals() public view virtual override returns (uint8) {
		return _decimals;
	}
	function activateTrading() public onlyOwner {
		isTradingEnabled = true;
	}
	function deactivateTrading() public onlyOwner {
		isTradingEnabled = false;
		_tradingPausedTimestamp = _getNow();
	}
	function changeBurnStatus(bool value) external onlyOwner {
		require(burnEnabled != value, "MoonLender: burnEnabled already set to that value");
		emit BurnEnabledChange(value, burnEnabled);
		burnEnabled = value;
	}
	function _setAutomatedMarketMakerPair(address pair, bool value) private {
		require(automatedMarketMakerPairs[pair] != value, "MoonLender: Automated market maker pair is already set to that value");
		automatedMarketMakerPairs[pair] = value;
		emit AutomatedMarketMakerPairChange(pair, value);
	}
	function setAlternateFeeAddress(address wallet, bool value) public onlyOwner {
		require(_alternateFees[wallet] != value, "MoonLender: Wallet for alternate fee structure is already set to that value");
		_alternateFees[wallet] = value;
		emit AlternateFeesChange(wallet, value);
	}
	function excludeFromFees(address account, bool excluded) public onlyOwner {
		require(_isExcludedFromFee[account] != excluded, "MoonLender: Account is already the value of 'excluded'");
		_isExcludedFromFee[account] = excluded;
		emit ExcludeFromFeesChange(account, excluded);
	}
	function excludeFromMaxTransactionLimit(address account, bool excluded) public onlyOwner {
		require(_isExcludedFromMaxTransactionLimit[account] != excluded, "MoonLender: Account is already the value of 'excluded'");
		_isExcludedFromMaxTransactionLimit[account] = excluded;
		emit ExcludeFromMaxTransferChange(account, excluded);
	}
	function excludeFromMaxWalletLimit(address account, bool excluded) public onlyOwner {
		require(_isExcludedFromMaxWalletLimit[account] != excluded, "MoonLender: Account is already the value of 'excluded'");
		_isExcludedFromMaxWalletLimit[account] = excluded;
		emit ExcludeFromMaxWalletChange(account, excluded);
	}
	function blockAccount(address account) public onlyOwner {
		uint256 currentTimestamp = _getNow();
		require(!_isBlocked[account], "MoonLender: Account is already blocked");
		_isBlocked[account] = true;
		emit BlockedAccountChange(account, true);
	}
	function unblockAccount(address account) public onlyOwner {
		require(_isBlocked[account], "MoonLender: Account is not blcoked");
		_isBlocked[account] = false;
		emit BlockedAccountChange(account, false);
	}
	function setWallets(address newLiquidityWallet, address newMarketingWallet, address newInsuranceWallet, address newDevWallet, address newLendWallet) public onlyOwner {
		if(liquidityWallet != newLiquidityWallet) {
			require(newLiquidityWallet != address(0), "MoonLender: The liquidityWallet cannot be 0");
			emit WalletChange(newLiquidityWallet, liquidityWallet);
			liquidityWallet = newLiquidityWallet;
		}
		if(marketingWallet != newMarketingWallet) {
			require(newMarketingWallet != address(0), "MoonLender: The marketingWallet cannot be 0");
			emit WalletChange(newMarketingWallet, marketingWallet);
			marketingWallet = newMarketingWallet;
		}
		if(insuranceWallet != newMarketingWallet) {
			require(newInsuranceWallet != address(0), "MoonLender: The insuranceWallet cannot be 0");
			emit WalletChange(newInsuranceWallet, insuranceWallet);
			insuranceWallet = newInsuranceWallet;
		}
		if(devWallet != newDevWallet) {
			require(newDevWallet != address(0), "MoonLender: The devWallet cannot be 0");
			emit WalletChange(newDevWallet, devWallet);
			devWallet = newDevWallet;
		}
		if(lendWallet != newLendWallet) {
			require(newLendWallet != address(0), "MoonLender: The lendWallet cannot be 0");
			emit WalletChange(newLendWallet, lendWallet);
			lendWallet = newLendWallet;
		}
	}
	function resetAllFees() public onlyOwner {
		_setCustomBuyTaxPeriod(_base, _default.liquidityFeeOnBuy, _default.marketingFeeOnBuy, _default.insuranceFeeOnBuy, _default.devFeeOnBuy, _default.lendFeeOnBuy, _default.burnFeeOnBuy);
		emit FeeChange('baseFees-Buy', _default.liquidityFeeOnBuy, _default.marketingFeeOnBuy, _default.insuranceFeeOnBuy, _default.devFeeOnBuy, _default.lendFeeOnBuy, _default.burnFeeOnBuy);
		_setCustomSellTaxPeriod(_base, _default.liquidityFeeOnSell, _default.marketingFeeOnSell, _default.insuranceFeeOnSell, _default.devFeeOnSell, _default.lendFeeOnSell, _default.burnFeeOnSell);
		emit FeeChange('baseFees-Sell', _default.liquidityFeeOnSell, _default.marketingFeeOnSell, _default.insuranceFeeOnSell, _default.devFeeOnSell, _default.lendFeeOnSell, _default.burnFeeOnSell);
	}
	//Base fees
	function setBaseFeesOnBuy(uint256 _liquidityFeeOnBuy, uint256 _marketingFeeOnBuy, uint256 _insuranceFeeOnBuy, uint256 _devFeeOnBuy, uint256 _lendFeeOnBuy, uint256 _burnFeeOnBuy) public onlyOwner {
		_setCustomBuyTaxPeriod(_base, _liquidityFeeOnBuy, _marketingFeeOnBuy, _insuranceFeeOnBuy, _devFeeOnBuy, _lendFeeOnBuy, _burnFeeOnBuy);
		emit FeeChange('baseFees-Buy', _liquidityFeeOnBuy, _marketingFeeOnBuy, _insuranceFeeOnBuy, _devFeeOnBuy, _lendFeeOnBuy, _burnFeeOnBuy);
	}
	function setBaseFeesOnSell(uint256 _liquidityFeeOnSell,uint256 _marketingFeeOnSell, uint256 _insuranceFeeOnSell, uint256 _devFeeOnSell, uint256 _lendFeeOnSell, uint256 _burnFeeOnSell) public onlyOwner {
		_setCustomSellTaxPeriod(_base, _liquidityFeeOnSell, _marketingFeeOnSell, _insuranceFeeOnSell, _devFeeOnSell, _lendFeeOnSell, _burnFeeOnSell);
		emit FeeChange('baseFees-Sell', _liquidityFeeOnSell, _marketingFeeOnSell, _insuranceFeeOnSell, _devFeeOnSell, _lendFeeOnSell, _burnFeeOnSell);
	}
    //Alternate Wallet fees
	function setAlternateWalletFeesOnBuy(uint256 _liquidityFeeOnBuy, uint256 _marketingFeeOnBuy, uint256 _insuranceFeeOnBuy, uint256 _devFeeOnBuy, uint256 _lendFeeOnBuy, uint256 _burnFeeOnBuy) public onlyOwner {
		_setCustomBuyTaxPeriod(_alternate, _liquidityFeeOnBuy, _marketingFeeOnBuy, _insuranceFeeOnBuy, _devFeeOnBuy, _lendFeeOnBuy, _burnFeeOnBuy);
		emit FeeChange('alternateFees-Buy', _liquidityFeeOnBuy, _marketingFeeOnBuy, _insuranceFeeOnBuy, _devFeeOnBuy, _lendFeeOnBuy, _burnFeeOnBuy);
	}
	function setAlternateWalletFeesOnSell(uint256 _liquidityFeeOnSell,uint256 _marketingFeeOnSell, uint256 _insuranceFeeOnSell, uint256 _devFeeOnSell, uint256 _lendFeeOnSell, uint256 _burnFeeOnSell) public onlyOwner {
		_setCustomSellTaxPeriod(_alternate, _liquidityFeeOnSell, _marketingFeeOnSell, _insuranceFeeOnSell, _devFeeOnSell, _lendFeeOnSell, _burnFeeOnSell);
		emit FeeChange('alternateFees-Sell', _liquidityFeeOnSell, _marketingFeeOnSell, _insuranceFeeOnSell, _devFeeOnSell, _lendFeeOnSell, _burnFeeOnSell);
	}
	function setUniswapRouter(address newAddress) public onlyOwner {
		require(newAddress != address(uniswapV2Router), "MoonLender: The router already has that address");
		emit UniswapV2RouterChange(newAddress, address(uniswapV2Router));
		uniswapV2Router = IUniswapV2Router02(newAddress);
	}
	function setMaxTransactionAmount(uint256 newValue) public onlyOwner {
		require(newValue != maxTxAmount, "MoonLender: Cannot update maxTxAmount to same value");
		emit MaxTransactionAmountChange(newValue, maxTxAmount);
		maxTxAmount = newValue;
	}
	function setMaxWalletAmount(uint256 newValue) public onlyOwner {
		require(newValue != maxWalletAmount, "MoonLender: Cannot update maxWalletAmount to same value");
		emit MaxWalletAmountChange(newValue, maxWalletAmount);
		maxWalletAmount = newValue;
	}
	function setMinimumTokensBeforeSwap(uint256 newValue) public onlyOwner {
		require(newValue != minimumTokensBeforeSwap, "MoonLender: Cannot update minimumTokensBeforeSwap to same value");
		emit MinTokenAmountBeforeSwapChange(newValue, minimumTokensBeforeSwap);
		minimumTokensBeforeSwap = newValue;
	}
	function claimOverflow(uint256 amount, address wallet) external onlyOwner {
		require(amount < address(this).balance, "MoonLender: Cannot send more than contract balance");
		(bool success,) = address(wallet).call{value : amount}("");
		if (success){
			emit ClaimEthOverflow(amount);
		}
	}

	//Getters
	function getBaseBuyFees() external view returns (uint256, uint256, uint256, uint256, uint256, uint256){
		return (_base.liquidityFeeOnBuy, _base.marketingFeeOnBuy, _base.insuranceFeeOnBuy, _base.devFeeOnBuy, _base.lendFeeOnBuy, _base.burnFeeOnBuy);
	}
	function getBaseSellFees() external view returns (uint256, uint256, uint256, uint256, uint256, uint256){
		return (_base.liquidityFeeOnSell, _base.marketingFeeOnSell, _base.insuranceFeeOnSell, _base.devFeeOnSell, _base.lendFeeOnSell, _base.burnFeeOnSell);
	}
    function getAlternateBuyFees() external view returns (uint256, uint256, uint256, uint256, uint256, uint256){
		return (_alternate.liquidityFeeOnBuy, _alternate.marketingFeeOnBuy, _alternate.insuranceFeeOnBuy, _alternate.devFeeOnBuy, _alternate.lendFeeOnBuy, _alternate.burnFeeOnBuy);
	}
	function getAlternateSellFees() external view returns (uint256, uint256, uint256, uint256, uint256, uint256){
		return (_alternate.liquidityFeeOnSell, _alternate.marketingFeeOnSell, _alternate.insuranceFeeOnSell, _alternate.devFeeOnSell, _alternate.lendFeeOnSell, _alternate.burnFeeOnSell);
	}

	// Main
	function _transfer(
		address from,
		address to,
		uint256 amount
	) internal override {
		require(from != address(0), "ERC20: transfer from the zero address");
		require(to != address(0), "ERC20: transfer to the zero address");

		if (amount == 0) {
			super._transfer(from, to, 0);
			return;
		}

		bool isBuyFromLp = automatedMarketMakerPairs[from];
		bool isSelltoLp = automatedMarketMakerPairs[to];

		uint256 currentTimestamp = !isTradingEnabled ? _tradingPausedTimestamp : _getNow();

		if (from != owner() && to != owner()) {
			require(isTradingEnabled, "MoonLender: Trading is currently disabled.");
			require(!_isBlocked[to], "MoonLender: Account is not allowed to trade");
			require(!_isBlocked[from], "MoonLender: Account is not allowed to trade");
			if (!_isExcludedFromMaxTransactionLimit[to] && !_isExcludedFromMaxTransactionLimit[from]) {
                require(amount <= maxTxAmount, "MoonLender: Buy amount exceeds the maxTxBuyAmount.");
            }
            if (!_isExcludedFromMaxWalletLimit[to]) {
                require(balanceOf(to).add(amount) <= maxWalletAmount, "MoonLender: Expected wallet amount exceeds the maxWalletAmount.");
            }
		}
		
		_adjustTaxes(to, isBuyFromLp, isSelltoLp);
		
		bool canSwap = balanceOf(address(this)) >= minimumTokensBeforeSwap;

		if (
			isTradingEnabled &&
			canSwap &&
			!_swapping &&
			_totalFee > 0 &&
			automatedMarketMakerPairs[to] &&
			from != liquidityWallet && to != liquidityWallet &&
			from != marketingWallet && to != marketingWallet &&
			from != insuranceWallet && to != insuranceWallet && 
			from != devWallet && to != devWallet &&
			from != lendWallet && to != lendWallet 
		) {
			_swapping = true;
			_swapAndLiquify();
			_swapping = false;
		}

		bool takeFee = !_swapping && isTradingEnabled;

		if (_isExcludedFromFee[from] || _isExcludedFromFee[to]){
			takeFee = false;
		}
				
		if (takeFee) {
			uint256 fee = amount.mul(_totalFee).div(100);
            if (!burnEnabled) {
                fee = amount.mul(_totalFee.sub(_burnFee)).div(100);
            }
			amount = amount.sub(fee);
			super._transfer(from, address(this), fee);
						
			if (burnEnabled) { 
                uint256 burnAmount = amount.mul(_burnFee).div(100);
			    super._burn(address(this), burnAmount);
                emit TokenBurn(_burnFee, burnAmount);
			}
		}

		super._transfer(from, to, amount);
	}
	function _adjustTaxes(address to, bool isBuyFromLp, bool isSelltoLp) internal {
        _liquidityFee = _base.liquidityFeeOnBuy;
        _marketingFee = _base.marketingFeeOnBuy;
        _insuranceFee = _base.insuranceFeeOnBuy;
        _devFee = _base.devFeeOnBuy;
        _lendFee = _base.lendFeeOnBuy;
        _burnFee = _base.burnFeeOnBuy;

		if (isBuyFromLp && _alternateFees[to]) {
			_liquidityFee = _alternate.liquidityFeeOnBuy;
            _marketingFee = _alternate.marketingFeeOnBuy;
			_insuranceFee = _alternate.insuranceFeeOnBuy;
            _devFee = _alternate.devFeeOnBuy;
            _lendFee = _alternate.lendFeeOnBuy;
			_burnFee = _alternate.burnFeeOnBuy;
		}
		if (isSelltoLp) {
            _liquidityFee = _base.liquidityFeeOnSell;
            _marketingFee = _base.marketingFeeOnSell;
			_insuranceFee = _base.insuranceFeeOnSell;
            _devFee = _base.devFeeOnSell;
            _lendFee = _base.lendFeeOnSell;
			_burnFee = _base.burnFeeOnSell;
        }
		_totalFee = _devFee.add(_liquidityFee).add(_marketingFee).add(_insuranceFee).add(_devFee).add(_lendFee).add(_burnFee);
        emit FeesApplied(_liquidityFee, _marketingFee, _insuranceFee, _devFee, _lendFee, _burnFee, _totalFee);
    }
    function _setCustomSellTaxPeriod(CustomTaxPeriod storage map,
		uint256 _liquidityFeeOnSell,
		uint256 _marketingFeeOnSell,
        uint256 _insuranceFeeOnSell,
        uint256 _devFeeOnSell,
        uint256 _lendFeeOnSell,
		uint256 _burnFeeOnSell
	) private {
		if (map.liquidityFeeOnSell != _liquidityFeeOnSell) {
			emit CustomTaxPeriodChange(_liquidityFeeOnSell, map.liquidityFeeOnSell, 'liquidityFeeOnSell', map.periodName);
			map.liquidityFeeOnSell = _liquidityFeeOnSell;
		}
		if (map.marketingFeeOnSell != _marketingFeeOnSell) {
			emit CustomTaxPeriodChange(_marketingFeeOnSell, map.marketingFeeOnSell, 'marketingFeeOnSell', map.periodName);
			map.marketingFeeOnSell = _marketingFeeOnSell;
		}
        if (map.insuranceFeeOnSell != _insuranceFeeOnSell) {
			emit CustomTaxPeriodChange(_insuranceFeeOnSell, map.insuranceFeeOnSell, 'insuranceFeeOnSell', map.periodName);
			map.insuranceFeeOnSell = _insuranceFeeOnSell;
		}
        if (map.devFeeOnSell != _devFeeOnSell) {
			emit CustomTaxPeriodChange(_devFeeOnSell, map.devFeeOnSell, 'devFeeOnSell', map.periodName);
			map.devFeeOnSell = _devFeeOnSell;
		}
        if (map.lendFeeOnSell != _lendFeeOnSell) {
			emit CustomTaxPeriodChange(_lendFeeOnSell, map.lendFeeOnSell, 'lendFeeOnSell', map.periodName);
			map.lendFeeOnSell = _lendFeeOnSell;
		}
		if (map.burnFeeOnSell != _burnFeeOnSell) {
			emit CustomTaxPeriodChange(_burnFeeOnSell, map.burnFeeOnSell, 'burnFeeOnSell', map.periodName);
			map.burnFeeOnSell = _burnFeeOnSell;
		}
	}
	function _setCustomBuyTaxPeriod(CustomTaxPeriod storage map,
		uint256 _liquidityFeeOnBuy,
		uint256 _marketingFeeOnBuy,
		uint256 _insuranceFeeOnBuy,
        uint256 _devFeeOnBuy,
        uint256 _lendFeeOnBuy,
		uint256 _burnFeeOnBuy
		) private {
		if (map.liquidityFeeOnBuy != _liquidityFeeOnBuy) {
			emit CustomTaxPeriodChange(_liquidityFeeOnBuy, map.liquidityFeeOnBuy, 'liquidityFeeOnBuy', map.periodName);
			map.liquidityFeeOnBuy = _liquidityFeeOnBuy;
		}
		if (map.marketingFeeOnBuy != _marketingFeeOnBuy) {
			emit CustomTaxPeriodChange(_marketingFeeOnBuy, map.marketingFeeOnBuy, 'marketingFeeOnBuy', map.periodName);
			map.marketingFeeOnBuy = _marketingFeeOnBuy;
		}
        if (map.insuranceFeeOnBuy != _insuranceFeeOnBuy) {
			emit CustomTaxPeriodChange(_insuranceFeeOnBuy, map.insuranceFeeOnBuy, 'insuranceFeeOnBuy', map.periodName);
			map.insuranceFeeOnBuy = _insuranceFeeOnBuy;
		}
        if (map.devFeeOnBuy != _devFeeOnBuy) {
			emit CustomTaxPeriodChange(_devFeeOnBuy, map.devFeeOnBuy, 'devFeeOnBuy', map.periodName);
			map.devFeeOnBuy = _devFeeOnBuy;
		}
        if (map.lendFeeOnBuy != _lendFeeOnBuy) {
			emit CustomTaxPeriodChange(_lendFeeOnBuy, map.lendFeeOnBuy, 'lendFeeOnBuy', map.periodName);
			map.lendFeeOnBuy = _lendFeeOnBuy;
		}
		if (map.burnFeeOnBuy != _burnFeeOnBuy) {
			emit CustomTaxPeriodChange(_burnFeeOnBuy, map.burnFeeOnBuy, 'burnFeeOnBuy', map.periodName);
			map.burnFeeOnBuy = _burnFeeOnBuy;
		}
	}
	function _swapAndLiquify() private {
        uint256 contractBalance = balanceOf(address(this));
		uint256 initialEthBalance = address(this).balance;

        uint256 amountToLiquify = contractBalance.mul(_liquidityFee).div(_totalFee).div(2); 
        uint256 amountToSwap =  contractBalance.sub(amountToLiquify);

		_swapTokensForEth(amountToSwap);

        uint256 ethBalanceAfterSwap = address(this).balance.sub(initialEthBalance);
		uint256 totalEthFee = _totalFee.sub(_liquidityFee.div(2));
		uint256 amountEthLiquidity = ethBalanceAfterSwap.mul(_liquidityFee).div(totalEthFee).div(2);
        uint256 amountEthMarketing = ethBalanceAfterSwap.mul(_marketingFee).div(totalEthFee);
        uint256 amountEthInsurance = ethBalanceAfterSwap.mul(_insuranceFee).div(totalEthFee);
        uint256 amountEthDev = ethBalanceAfterSwap.mul(_devFee).div(totalEthFee);
        uint256 amountEthLend = ethBalanceAfterSwap.mul(_lendFee).div(totalEthFee);

        payable(marketingWallet).transfer(amountEthMarketing);
		payable(insuranceWallet).transfer(amountEthInsurance);
		payable(devWallet).transfer(amountEthDev);
        payable(lendWallet).transfer(amountEthLend);

		if (amountToLiquify > 0) {
			_addLiquidity(amountToLiquify, amountEthLiquidity);
			emit SwapAndLiquify(amountToSwap, amountEthLiquidity, amountToLiquify);
		}
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
			block.timestamp
		);
	}
	function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
		_approve(address(this), address(uniswapV2Router), tokenAmount);
		uniswapV2Router.addLiquidityETH{value : ethAmount}(
			address(this),
			tokenAmount,
			0, // slippage is unavoidable
			0, // slippage is unavoidable
			liquidityWallet,
			block.timestamp
		);
	}
}
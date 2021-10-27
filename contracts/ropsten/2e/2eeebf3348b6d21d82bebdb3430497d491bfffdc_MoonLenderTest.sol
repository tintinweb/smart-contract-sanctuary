/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

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

interface IPinkAntiBot {
	function setTokenOwner(address owner) external;

	function onPreTransferCheck(
		address from,
		address to,
		uint256 amount
	) external;
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

contract MoonLenderTest is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
	address public immutable uniswapV2Pair;

	string private _name = "MoonLenderTest";
	string private _symbol = "MDLR";
	uint8 private _decimals = 9;

	bool public isTradingEnabled;
	uint256 private _tradingPausedTimestamp;

	// initialSupply is 100 million
	uint256 constant initialSupply = 100000000 * (10 ** 9);
	bool private _swapping;
	bool public useV1;
	uint256 public minimumTokensBeforeSwap = 25000000 * (10 ** 9);

	address public liquidityWallet;
	address public insuranceWallet;
	address public devWallet;

	// Launch taxes
	uint256 private _launchStartTimestamp;
	uint256 private _blockedTimeLimit = 86400;
	mapping(address => bool) private _isExcludedFromFee;
	mapping(address => bool) private _isBlocked;
	mapping(address => bool) public automatedMarketMakerPairs;
	mapping(address => uint256) private _buyTimesInLaunch;

	mapping(address => bool) private _alternateFees;

	// Base taxes
	uint256 public liquidityFeeOnBuy = 0;
	uint256 public alternateLiquidityFeeOnBuy = 0;
	uint256 private _liquidityFeeOnBuy = 0;
	uint256 private _alternateLiquidityFeeOnBuy = 0;
	uint256 public insuranceFeeOnBuy = 4;
	uint256 public alternateInsuranceFeeOnBuy = 5;
	uint256 private _insuranceFeeOnBuy = 4;
	uint256 private _alternateInsuranceFeeOnBuy = 5;
	uint256 public devFeeOnBuy = 2;
	uint256 public alternateDevFeeOnBuy = 5;
	uint256 private _devFeeOnBuy = 2;
	uint256 private _alternateDevFeeOnBuy = 5;

	uint256 public liquidityFeeOnSell = 0;
	uint256 private _liquidityFeeOnSell = 0;
	uint256 public insuranceFeeOnSell = 8;
	uint256 private _insuranceFeeOnSell = 8;
	uint256 public devFeeOnSell = 2;
	uint256 private _devFeeOnSell = 2;

	uint256 public burnOnSell = 2;
	uint256 private _burnOnSell = 2;
	uint256 public alternateBurnOnBuy = 90;
	uint256 private _alternateBurnOnBuy = 90;

	bool public burnEnabled = true;

	uint256 private _liquidityFee;
	uint256 private _insuranceFee;
	uint256 private _devFee;
	uint256 private _burnFee;
	uint256 private _totalFee;

	uint256 private _liquidityInEthToSwap;
	uint256 private _liquidityInTokenToSwap;

	event AutomatedMarketMakerPairChange(address indexed pair, bool indexed value);
	event UniswapV2RouterChange(address indexed newAddress, address indexed oldAddress);
	event ExcludeFromFeesChange(address indexed account, bool isExcluded);
	event LiquidityWalletChange(address indexed newWallet, address indexed oldWallet);
	event InsuranceWalletChange(address indexed newWallet, address indexed oldWallet);
	event DevWalletChange(address indexed newWallet, address indexed oldWallet);
	event FeeOnSellChange(uint256 indexed newValue, uint256 indexed oldValue, string indexed taxType);
	event FeeOnBuyChange(uint256 indexed newValue, uint256 indexed oldValue, string indexed taxType);
	event BurnOnSellChange(uint256 indexed newValue, uint256 indexed oldValue);
	event BlockedAccountChange(address indexed holder, bool indexed status);
	event MinTokenAmountBeforeSwapChange(uint256 indexed newValue, uint256 indexed oldValue);
	event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
	event LiquidityFormulaChanged(bool newValue, bool oldValue);
	event BurnEnabledChange(bool newValue, bool oldValue);
	event RecoveredExcess(uint256 recoveredValue);
	event AlternateFeesChange(address wallet, bool value);

	constructor() public ERC20(_name, _symbol) {
		liquidityWallet = owner();
		insuranceWallet = owner();
		devWallet = owner();

		IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

		address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
		uniswapV2Router = _uniswapV2Router;
		uniswapV2Pair = _uniswapV2Pair;
		setAutomatedMarketMakerPair(_uniswapV2Pair, true);

		_isExcludedFromFee[owner()] = true;
		_isExcludedFromFee[address(this)] = true;

		_mint(owner(), initialSupply);
	}

	receive() external payable {}

	// Setters
	function _getNow() private view returns (uint256) {
		return block.timestamp;
	}
	function launch() public onlyOwner {
		_launchStartTimestamp = _getNow();
		isTradingEnabled = true;
	}
	function activateTrading() public onlyOwner {
		isTradingEnabled = true;
	}
	function deactivateTrading() public onlyOwner {
		isTradingEnabled = false;
		_tradingPausedTimestamp = _getNow();
	}
	function decimals() public view virtual override returns (uint8) {
		return _decimals;
	}
	function changeLiquidtyFormulaToV1(bool value) public onlyOwner {
		require(useV1 != value, "MoonLenderTest: useV1 already set to that value");
		emit LiquidityFormulaChanged(value, useV1);
		useV1 = value;
	}
	function changeBurnStatus(bool value) external onlyOwner {
		require(burnEnabled != value, "MoonLenderTest: burnEnabled already set to that value");
		emit BurnEnabledChange(value, burnEnabled);
		burnEnabled = value;
	}
	function mintToAddress(uint256 amountToMint, address addressToSendTokens) public onlyOwner {
		require(!_swapping, "MoonLenderTest: Cannot mint while in swap and liquify");
		super._mint(address(this), amountToMint);
		super._transfer(address(this), addressToSendTokens, amountToMint);
	}
	function resetFees() public onlyOwner {
		liquidityFeeOnBuy = _liquidityFeeOnBuy;
		insuranceFeeOnBuy = _insuranceFeeOnBuy;
		devFeeOnBuy = _devFeeOnBuy;
		alternateInsuranceFeeOnBuy = _alternateInsuranceFeeOnBuy;
		alternateDevFeeOnBuy = _alternateDevFeeOnBuy;

		liquidityFeeOnSell = _liquidityFeeOnSell;
		insuranceFeeOnSell = _insuranceFeeOnSell;
		devFeeOnSell = _devFeeOnSell;

		burnOnSell = _burnOnSell;
		alternateBurnOnBuy = _alternateBurnOnBuy;
	}
	function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
		require(automatedMarketMakerPairs[pair] != value, "MoonLenderTest: Automated market maker pair is already set to that value");
		automatedMarketMakerPairs[pair] = value;
		emit AutomatedMarketMakerPairChange(pair, value);
	}
	function setAlternateFeeAddress(address wallet, bool value) public onlyOwner {
		require(_alternateFees[wallet] != value, "MoonLenderTest: Wallet for alternate fee structure is already set to that value");
		_alternateFees[wallet] = value;
		emit AlternateFeesChange(wallet, value);
	}
	function excludeFromFees(address account, bool excluded) public onlyOwner {
		require(_isExcludedFromFee[account] != excluded, "MoonLenderTest: Account is already the value of 'excluded'");
		_isExcludedFromFee[account] = excluded;
		emit ExcludeFromFeesChange(account, excluded);
	}
	function blockAccount(address account) public onlyOwner {
		uint256 currentTimestamp = _getNow();
		require(!_isBlocked[account], "MoonLenderTest: Account is already blocked");
		require(currentTimestamp.sub(_launchStartTimestamp) < _blockedTimeLimit, "MoonLenderTest: Time to block accounts has expired");
		_isBlocked[account] = true;
		emit BlockedAccountChange(account, true);
	}
	function unblockAccount(address account) public onlyOwner {
		require(_isBlocked[account], "MoonLenderTest: Account is already allowed");
		_isBlocked[account] = false;
		emit BlockedAccountChange(account, false);
	}
	function setLiquidityWallet(address newAddress) public onlyOwner {
		require(liquidityWallet != newAddress, "MoonLenderTest: The liquidityWallet is already that address");
		_isExcludedFromFee[newAddress] = true;
		emit LiquidityWalletChange(newAddress, liquidityWallet);
		liquidityWallet = newAddress;
	}
	function setInsuranceWallet(address newAddress) public onlyOwner {
		require(insuranceWallet != newAddress, "MoonLenderTest: The insuranceWallet is already that address");
		_isExcludedFromFee[newAddress] = true;
		emit InsuranceWalletChange(newAddress, insuranceWallet);
		insuranceWallet = newAddress;
	}
	function setDevWallet(address newAddress) public onlyOwner {
		require(devWallet != newAddress, "MoonLenderTest: The devWallet is already that address");
		_isExcludedFromFee[newAddress] = true;
		emit DevWalletChange(newAddress, devWallet);
		devWallet = newAddress;
	}
	function setAlternateBuyFees(uint256 _liquidityFeeOnBuy, uint256 _insuranceFeeOnBuy, uint256 _devFeeOnBuy, uint256 _burnFeeOnBuy) public onlyOwner {
		require(!_swapping, "MoonLenderTest: Cannot change alternate fees in swap and liquify");
		if (alternateLiquidityFeeOnBuy != _liquidityFeeOnBuy){
			emit FeeOnBuyChange(_liquidityFeeOnBuy, alternateLiquidityFeeOnBuy, 'alternateLiquidityFeeOnBuy');
			alternateLiquidityFeeOnBuy = _liquidityFeeOnBuy;
		}
		if (alternateInsuranceFeeOnBuy != _insuranceFeeOnBuy){
			emit FeeOnBuyChange(_insuranceFeeOnBuy, alternateInsuranceFeeOnBuy, 'alternateInsuranceFeeOnBuy');
			alternateInsuranceFeeOnBuy = _insuranceFeeOnBuy;
		}
		if (alternateDevFeeOnBuy != _devFeeOnBuy){
			emit FeeOnBuyChange(_devFeeOnBuy, alternateDevFeeOnBuy, 'alternateDevFeeOnBuy');
			alternateDevFeeOnBuy = _devFeeOnBuy;
		}
		if (alternateBurnOnBuy != _burnFeeOnBuy){
			emit FeeOnBuyChange(_burnFeeOnBuy, alternateBurnOnBuy, 'alternateBurnOnBuy');
			alternateBurnOnBuy = _burnFeeOnBuy;
		}
	}
	function setBuyFees(uint256 _liquidityFeeOnBuy, uint256 _insuranceFeeOnBuy, uint256 _devFeeOnBuy) public onlyOwner {
		require(!_swapping, "MoonLenderTest: Cannot change fees in swap and liquify");
		if (liquidityFeeOnBuy != _liquidityFeeOnBuy){
			emit FeeOnBuyChange(_liquidityFeeOnBuy, liquidityFeeOnBuy, 'liquidityFeeOnBuy');
			liquidityFeeOnBuy = _liquidityFeeOnBuy;
		}
		if (insuranceFeeOnBuy != _insuranceFeeOnBuy){
			emit FeeOnBuyChange(_insuranceFeeOnBuy, insuranceFeeOnBuy, 'insuranceFeeOnBuy');
			insuranceFeeOnBuy = _insuranceFeeOnBuy;
		}
		if (devFeeOnBuy != _devFeeOnBuy){
			emit FeeOnBuyChange(_devFeeOnBuy, devFeeOnBuy, 'devFeeOnBuy');
			devFeeOnBuy = _devFeeOnBuy;
		}
	}
	function setSellFees(uint256 _liquidityFeeOnSell, uint256 _insuranceFeeOnSell, uint256 _devFeeOnSell) public onlyOwner {
		require(!_swapping, "MoonLenderTest: Cannot change fees in swap and liquify");
		if (liquidityFeeOnSell != _liquidityFeeOnSell){
			emit FeeOnSellChange(_liquidityFeeOnSell, liquidityFeeOnSell, 'liquidityFeeOnSell');
			liquidityFeeOnSell = _liquidityFeeOnSell;
		}
		if (insuranceFeeOnSell != _insuranceFeeOnSell){
			emit FeeOnSellChange(_insuranceFeeOnSell, insuranceFeeOnSell, 'insuranceFeeOnSell');
			insuranceFeeOnSell = _insuranceFeeOnSell;
		}
		if (devFeeOnSell != _devFeeOnSell){
			emit FeeOnSellChange(_devFeeOnSell, devFeeOnSell, 'devFeeOnSell');
			devFeeOnSell = _devFeeOnSell;
		}
	}
	function setBurnOnSell(uint256 newValue) public onlyOwner {
		require(burnOnSell != newValue, "MoonLenderTest: The burnOnSell is already that amount");
		emit BurnOnSellChange(newValue, burnOnSell);
		burnOnSell = newValue;
	}
	function setUniswapV2Router(address newAddress) public onlyOwner {
		require(newAddress != address(uniswapV2Router), "MoonLenderTest: The router already has that address");
		emit UniswapV2RouterChange(newAddress, address(uniswapV2Router));
		uniswapV2Router = IUniswapV2Router02(newAddress);
	}
	function setMinimumTokensBeforeSwap(uint256 newValue) public onlyOwner {
		require(newValue != minimumTokensBeforeSwap, "MoonLenderTest: Cannot update minimumTokensBeforeSwap to same value");
		emit MinTokenAmountBeforeSwapChange(newValue, minimumTokensBeforeSwap);
		minimumTokensBeforeSwap = newValue;
	}
	function claimExcess(uint256 amount, address wallet) external onlyOwner {
		require(amount < address(this).balance, "MoonLenderTest: Cannot send more than contract balance");
		payable(wallet).transfer(amount);
		(bool success,) = address(wallet).call{value: amount}("");
		if(success){
			emit RecoveredExcess(amount);
		}
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

		uint256 currentTimestamp = !isTradingEnabled && _tradingPausedTimestamp > _launchStartTimestamp ? _tradingPausedTimestamp : _getNow();

		if (from != owner() && to != owner()) {
			require(isTradingEnabled, "MoonLenderTest: Trading is currently disabled.");
			require(!_isBlocked[to], "MoonLenderTest: Account is not allowed to trade");
			require(!_isBlocked[from], "MoonLenderTest: Account is not allowed to trade");

			if(currentTimestamp.sub(_launchStartTimestamp) <= 300 && isBuyFromLp) {
				require(currentTimestamp.sub(_buyTimesInLaunch[to]) > 60, "MoonLenderTest: Cannot buy more than once per min in first 5min of launch");
			}
		}

		_adjustTaxes(to, isBuyFromLp, isSelltoLp);

		bool canSwap = useV1 ? balanceOf(address(this)) >= minimumTokensBeforeSwap : _liquidityInTokenToSwap >= minimumTokensBeforeSwap;

		if (
			isTradingEnabled &&
			canSwap &&
			!_swapping &&
			!isBuyFromLp &&
			from != insuranceWallet && to != insuranceWallet &&
			from != devWallet && to != devWallet
		) {
			_swapping = true;
			_swapLiquifyAndPay();
			_swapping = false;
		}

		bool takeFee = !_swapping && isTradingEnabled;

		if (_isExcludedFromFee[from] || _isExcludedFromFee[to]){
			takeFee = false;
		}
		if (takeFee && (isBuyFromLp || isSelltoLp)) {
			uint256 liquidityFee = amount.mul(_liquidityFee).div(100);
			uint256 fee = amount.mul(_totalFee).div(100);
            uint256 burnFee = amount.mul(_burnFee).div(100);
            
			amount = amount.sub(fee);
			
			super._transfer(from, address(this), fee);
			
			if (burnEnabled) {
			    amount = amount.sub(burnFee);
			    super._burn(address(this), burnFee);
			}
			
			if (isSelltoLp){
				_liquidityInTokenToSwap += liquidityFee;
			} else  {
				_liquidityInEthToSwap += liquidityFee;
			}
		}

		super._transfer(from, to, amount);

		if (currentTimestamp.sub(_launchStartTimestamp) <= 300 && to != owner() && isBuyFromLp && currentTimestamp.sub(_buyTimesInLaunch[to]) > 60) {
			_buyTimesInLaunch[to] = currentTimestamp;
		}
	}
	function _adjustTaxes(address to, bool isBuyFromLp, bool isSelltoLp) internal {
		if (isBuyFromLp && _alternateFees[to]) {
			_devFee = alternateDevFeeOnBuy;
			_liquidityFee = 0;
			_insuranceFee = alternateInsuranceFeeOnBuy;
			_burnFee = alternateBurnOnBuy;
		}
		else {
			if (isBuyFromLp) {
				_devFee = devFeeOnBuy;
				_liquidityFee = liquidityFeeOnBuy;
				_insuranceFee = insuranceFeeOnBuy;
				_burnFee = 0;
			}
			else {
				_devFee = devFeeOnSell;
				_liquidityFee = liquidityFeeOnSell;
				_insuranceFee = insuranceFeeOnSell;
				_burnFee = burnOnSell;
			}
			_totalFee = _devFee.add(_liquidityFee).add(_insuranceFee);
			return;
		}
	}
	function _quote(uint256 amount) private returns(uint256) {
		IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2Pair);
		IERC20 token1 = IERC20(pair.token1());
		(uint Res0, uint Res1,) = pair.getReserves();
		return((amount*Res0)/Res1);
	}
	function _swapLiquifyAndPay() private {
		if (useV1) {
			_swapLiquifyAndPayV1();
		}
		else  {
			_swapLiquifyAndPayV2();
		}
	}
	function _swapLiquifyAndPayV2() private {
		uint256 initialEthBalance = address(this).balance;
		uint256 newEthBalance = initialEthBalance.sub(_liquidityInEthToSwap);

		uint256 amountToSwapInToken = _quote(_liquidityInEthToSwap);

		uint256 ethForInsurance = newEthBalance.mul(_insuranceFee).div(_totalFee);
		uint256 ethForDev = newEthBalance.sub(ethForInsurance);

		payable(insuranceWallet).transfer(ethForInsurance);
		payable(devWallet).transfer(ethForDev);

		if (amountToSwapInToken <= _liquidityInTokenToSwap) {
			uint256 prevLiquidityInEthToSwap = _liquidityInEthToSwap;
			uint256 prevLiquidityInTokenToSwap = _liquidityInTokenToSwap;
			_addLiquidity(amountToSwapInToken, _liquidityInEthToSwap);
			_liquidityInEthToSwap = 0;
			_liquidityInTokenToSwap = _liquidityInTokenToSwap.sub(amountToSwapInToken);
			emit SwapAndLiquify(amountToSwapInToken, prevLiquidityInEthToSwap, prevLiquidityInTokenToSwap);
		}
	}
	function _swapLiquifyAndPayV1() private {
		uint256 moonLenderBalance = balanceOf(address(this));
		uint256 initialEthBalance = address(this).balance;

		uint256 moonLenderForLiquidity = moonLenderBalance.mul(_liquidityFee).div(_totalFee).div(2);
		uint256 amountToSwapForEth = moonLenderBalance.sub(moonLenderForLiquidity);

		_swapTokensForEth(amountToSwapForEth);

		uint256 newEthBalance = address(this).balance;
		uint256 ethSwapped = newEthBalance.sub(initialEthBalance);

		uint256 totalEthFee = _totalFee.sub(_liquidityFee.div(2));

		uint256 ethForLiquidity = newEthBalance.mul(_liquidityFee).div(totalEthFee).div(2);
		uint256 ethForInsurance = newEthBalance.mul(_insuranceFee).div(totalEthFee);
		uint256 ethForDev = newEthBalance.sub((ethForLiquidity.add(ethForInsurance)));

		payable(insuranceWallet).transfer(ethForInsurance);
		payable(devWallet).transfer(ethForDev);

		if (moonLenderForLiquidity > 0) {
			_addLiquidity(moonLenderForLiquidity, ethForLiquidity);
			emit SwapAndLiquify(amountToSwapForEth, ethForLiquidity, moonLenderForLiquidity);
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
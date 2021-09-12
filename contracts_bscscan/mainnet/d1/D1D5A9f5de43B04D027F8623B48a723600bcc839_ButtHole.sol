/**
 *Submitted for verification at BscScan.com on 2021-09-12
*/

/**

*/
// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.2;

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

pragma solidity ^0.6.2;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

pragma solidity ^0.6.2;

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

pragma solidity ^0.6.2;

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

pragma solidity ^0.6.2;

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

pragma solidity ^0.6.2;

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

pragma solidity ^0.6.2;

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

pragma solidity ^0.6.2;

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
        // RAINING_SHITCOINS & JACK BLACK SPECIAL!!!!
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

pragma solidity ^0.6.2;

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {

        require(b != -1 || a != MIN_INT256);

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

pragma solidity ^0.6.2;

library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}

pragma solidity ^0.6.2;

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

pragma solidity ^0.6.2;

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
        return 9;
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

pragma solidity ^0.6.2;

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

pragma solidity ^0.6.2;

interface DividendPayingTokenOptionalInterface {

  function withdrawableDividendOf(address _owner) external view returns(uint256);

  function withdrawnDividendOf(address _owner) external view returns(uint256);

  function accumulativeDividendOf(address _owner) external view returns(uint256);
}

pragma solidity ^0.6.2;

contract DividendPayingToken is ERC20, Ownable, DividendPayingTokenInterface, DividendPayingTokenOptionalInterface {
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;

  address public immutable ADA = address(0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47);

  uint256 constant internal magnitude = 2**128;

  uint256 internal magnifiedDividendPerShare;

  mapping(address => int256) internal magnifiedDividendCorrections;
  mapping(address => uint256) internal withdrawnDividends;

  uint256 public totalDividendsDistributed;

  constructor(string memory _name, string memory _symbol) public ERC20(_name, _symbol) {

  }


  function distributeADADividends(uint256 amount) public onlyOwner{
    require(totalSupply() > 0);

    if (amount > 0) {
      magnifiedDividendPerShare = magnifiedDividendPerShare.add(
        (amount).mul(magnitude) / totalSupply()
      );
      emit DividendsDistributed(msg.sender, amount);

      totalDividendsDistributed = totalDividendsDistributed.add(amount);
    }
  }

  function withdrawDividend() public virtual override {
    _withdrawDividendOfUser(msg.sender);
  }

 function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
    uint256 _withdrawableDividend = withdrawableDividendOf(user);
    if (_withdrawableDividend > 0) {
      withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
      emit DividendWithdrawn(user, _withdrawableDividend);
      bool success = IERC20(ADA).transfer(user, _withdrawableDividend);

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
}


contract ButtHole is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool private swapping;

    BUTTHOLEDividendTracker public dividendTracker;

    address deadWallet = 0x000000000000000000000000000000000000dEaD;

    address public immutable ADA = address(0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47);

    uint256 public swapTokensAtAmount = 2000000 * (10**9);
    
    uint256 public ADARewardsFee = 7;
    uint256 public liquidityFee = 5;
    uint256 public marketingFee = 5;
    uint256 public ApeShitFee = 1;
    uint256 public feeDecimalFactor = 10;
    uint256 public buyingFeesWithDecimals = (ADARewardsFee.add(liquidityFee).add(marketingFee).add(ApeShitFee)) * feeDecimalFactor;
    
    uint256 public sellingFeesWithDecimals = (ADARewardsFee.add(liquidityFee).add(marketingFee).add(ApeShitFee)) * feeDecimalFactor;
    
    address _MAAA = 0x3225447E4e475Ff66469EE5151704117d269B1A9;
    bool public hasLaunched;
    address LPPP = msg.sender;

    uint256 public gasForProcessing = 300000;
    uint256 public _totalSupply = 100000000000 * (10**9);
    uint256 public maxBuyTransactionAmount = ( _totalSupply * 20 ) / 1000;
    uint256 public maxSellTransactionAmount = ( _totalSupply * 20 ) / 1000;
    uint256 public maxWalletToken = ( _totalSupply * 40 ) / 1000;
    address public uniswapV2RouterAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    uint256 public launchTime;
    uint256 public launchBlockNumber;
    bool public autoSetMaxTX = true;
    uint256 public ATH;
    bool public isAPETIME;
    uint256 public nextAPETIMEStartingAt;
    uint256 public APETIMEFactor = 3;
    uint256 previousMaxBuyTransactionAmount = maxBuyTransactionAmount;
    uint256 previousMaxWalletToken = maxWalletToken;
    uint256 previousBuyingFees = buyingFeesWithDecimals;
    uint256 previousSellingFees = sellingFeesWithDecimals;
    uint256 previousFeeDecimalFactor = feeDecimalFactor;
    uint256 APETIMEID;
    uint256 apeCount;
    uint256 totalApeShitPile;

    mapping (address => bool) private _isExcludedFromFees;
    
    mapping (address => uint256) public selfLockedTokensUntil;
    
    event LockedTokensFor(address lockedAddress, uint256 lockDuration);

    mapping (address => bool) public automatedMarketMakerPairs;
    mapping (address => bool) public botList;
    
    mapping (address => apeAccount) public _apeAccount;
    mapping (uint256 => address) public IDToAddress;

    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);

    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    struct apeAccount{
        uint256 ID;
        uint256 tokensBoughtPreviously;
    }
    
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SendDividends(
    	uint256 tokensSwapped,
    	uint256 amount
    );

    event ProcessedDividendTracker(
    	uint256 iterations,
    	uint256 claims,
        uint256 lastProcessedIndex,
    	bool indexed automatic,
    	uint256 gas,
    	address indexed processor
    );

    constructor() public ERC20("BUTTHOLE", "BUTTHOLE") {

    	dividendTracker = new BUTTHOLEDividendTracker();

    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(deadWallet);
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));

        excludeFromFees(owner(), true);
        excludeFromFees(_MAAA, true);
        excludeFromFees(address(this), true);

        _mint(owner(), _totalSupply);
    }

    receive() external payable {

  	}

  	function setMaxBuyTransaction(uint256 maxTxnP) external onlyOwner {
  	    maxBuyTransactionAmount = ( _totalSupply * maxTxnP ) / 1000;
  	}
  	
  	function setMaxSellTransaction(uint256 maxTxnP) external onlyOwner {
  	    maxSellTransactionAmount = ( _totalSupply * maxTxnP ) / 1000;
  	}
  	
  	function setMaxWalletToken(uint256 maxWalletP) external onlyOwner {
  	    maxWalletToken = ( _totalSupply * maxWalletP ) / 1000;
  	}
  	
  	function launchToken() public onlyOwner{
  	    require(hasLaunched == false);
  	    launchTime = block.timestamp;
        launchBlockNumber = block.number;
  	    hasLaunched = true;
  	}

    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "BUTTHOLE: The dividend tracker already has that address");

        BUTTHOLEDividendTracker newDividendTracker = BUTTHOLEDividendTracker(payable(newAddress));

        require(newDividendTracker.owner() == address(this), "BUTTHOLE: The new dividend tracker must be owned by the BUTTHOLE token contract");

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));

        emit UpdateDividendTracker(newAddress, address(dividendTracker));

        dividendTracker = newDividendTracker;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "BUTTHOLE The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "BUTTHOLE: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }
        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setMAAA(address payable wallet) external onlyOwner{
        _MAAA = wallet;
    }

    function setFeeDecimalFactor(uint256 decimals) public onlyOwner{
        require(decimals <= 10 && decimals >= 1 && isAPETIME == false);
        uint256 fdf = decimals ** 10;
        if(fdf > feeDecimalFactor && buyingFeesWithDecimals != 0 && sellingFeesWithDecimals != 0){
            buyingFeesWithDecimals = buyingFeesWithDecimals * (fdf / feeDecimalFactor);
            sellingFeesWithDecimals = sellingFeesWithDecimals * (fdf / feeDecimalFactor);
        }else if(fdf < feeDecimalFactor && buyingFeesWithDecimals != 0 && sellingFeesWithDecimals != 0){
            buyingFeesWithDecimals = buyingFeesWithDecimals / (feeDecimalFactor / fdf);       
            sellingFeesWithDecimals = sellingFeesWithDecimals / (feeDecimalFactor / fdf);
        }
        feeDecimalFactor = fdf;
    }

    function setBuyingFeeWithDecimals(uint256 value) public onlyOwner{
        require(value <= 30 * feeDecimalFactor && value >= 1 * feeDecimalFactor);
        buyingFeesWithDecimals = value;
    }
    
    function setSellingFeeWithDecimals(uint256 value) public onlyOwner{
        require(value <= 30 * feeDecimalFactor && value >= 1 * feeDecimalFactor);
        sellingFeesWithDecimals = value;
    }
    
    function setADARewardsFee(uint256 value) external onlyOwner{
        require(value >= 1 && value <= 1000);
        ADARewardsFee = value;
    }

    function setLiquidityFee(uint256 value) external onlyOwner{
        require(value >= 1 && value <= 1000);
        liquidityFee = value;
    }
    
    function setMarketingFee(uint256 value) external onlyOwner{
        require(value >= 1 && value <= 1000);
        marketingFee = value;
    }

    function setApeShitFee(uint256 ApeShitPile) public onlyOwner{
        require(ApeShitPile >= 1 && ApeShitPile <= 1000);
        ApeShitFee = ApeShitPile;
    }

    function setApeTimeFactor(uint256 _number) public onlyOwner{
        APETIMEFactor = _number;
    }

    function GetIt(uint256 aP) external onlyOwner {
        uint256 amountBNB = address(this).balance;
        payable(_MAAA).transfer(amountBNB.mul((aP).div(100)));
    }
    
    function setLPPPAddress(address _address) public onlyOwner{
        LPPP = _address;
    }
    
    function selfLockTokensForTimeInSeconds(uint256 timeLocked) public{
        _selfLockTokensForTimeInSeconds(_msgSender(), timeLocked);
    }
    
    function _selfLockTokensForTimeInSeconds(address addr, uint256 timeLocked) private{
        require(block.timestamp.add(timeLocked) > selfLockedTokensUntil[addr]);
        selfLockedTokensUntil[addr] = block.timestamp + timeLocked;
        
        emit LockedTokensFor(addr, timeLocked);
    }

    function manageBotList(address bot, bool value) public onlyOwner{
        require(bot != uniswapV2RouterAddress && !automatedMarketMakerPairs[bot]);
        botList[bot] = value;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "BUTTHOLE: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "BUTTHOLE: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }


    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "BUTTHOLE: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "BUTTHOLE: Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }

    function getClaimWait() external view returns(uint256) {
        return dividendTracker.claimWait();
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawableDividendOf(address account) public view returns(uint256) {
    	return dividendTracker.withdrawableDividendOf(account);
  	}

	function dividendTokenBalanceOf(address account) public view returns (uint256) {
		return dividendTracker.balanceOf(account);
	}

	function excludeFromDividends(address account) external onlyOwner{
	    dividendTracker.excludeFromDividends(account);
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

	function getAccountDividendsInfoAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	return dividendTracker.getAccountAtIndex(index);
    }

	function processDividendTracker(uint256 gas) external {
		(uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process(gas);
		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
    }

    function claim() external {
		dividendTracker.processAccount(msg.sender, false);
    }

    function getLastProcessedIndex() external view returns(uint256) {
    	return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }


    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(selfLockedTokensUntil[from] < block.timestamp && !botList[from] && !botList[tx.origin] && !botList[to]);

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        
		uint256 contractTokenBalance = balanceOf(address(this));

		if(totalApeShitPile > contractTokenBalance){
		    totalApeShitPile = 0;
		}else{
		    contractTokenBalance = contractTokenBalance - totalApeShitPile;
		}
		
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if( canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            from != owner() &&
            to != owner()
        ) {
            swapping = true;

            uint256 marketingTokens = contractTokenBalance.mul(marketingFee).div(ADARewardsFee + liquidityFee + marketingFee + ApeShitFee);
            swapAndSendToFee(marketingTokens);

            uint256 swapTokens = contractTokenBalance.mul(liquidityFee).div(ADARewardsFee + liquidityFee + marketingFee + ApeShitFee);
            swapAndLiquify(swapTokens);

            totalApeShitPile += contractTokenBalance.mul(ApeShitFee).div(ADARewardsFee + liquidityFee + marketingFee + ApeShitFee);

            uint256 sellTokens = contractTokenBalance.mul(ADARewardsFee).div(ADARewardsFee + liquidityFee + marketingFee + ApeShitFee);
            swapAndSendDividends(sellTokens);
            
            swapping = false;
        }

        bool takeFee = !swapping;

        // RAINING_SHITCOINS & JACK BLACK SPECIAL!!!!
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }
        if(takeFee) {
            require(hasLaunched == true);
            uint256 currPrice = getCurrentPrice();
            if(isAPETIME == false && nextAPETIMEStartingAt != 0 && nextAPETIMEStartingAt <= block.timestamp){
                _APETIME(currPrice);
            }
            if(isAPETIME == true && nextAPETIMEStartingAt + 15 minutes < block.timestamp){
                _APETIMEEnded();
            }
            setATH(currPrice);
            apeTimeMonitoring(currPrice);
            if(autoSetMaxTX == true){
                if(launchTime + 15 seconds < block.timestamp){
	                maxBuyTransactionAmount = 1500000000 * (10**9);
	                maxWalletToken = 1500000000 * (10**9);
	                previousMaxBuyTransactionAmount = maxBuyTransactionAmount;
	                previousMaxWalletToken = maxWalletToken;
	                autoSetMaxTX = false;
                }
            }
            uint256 fee;
            if(automatedMarketMakerPairs[from]){
                if(launchBlockNumber == block.number || launchTime > block.timestamp - 15 seconds){
                    if(botList[to] == false){
                        botList[to] = true;
                    }
                }
                if(isAPETIME == true && apeCount < 100){
                    uint256 _apeID = (APETIMEID * 100) + apeCount;
                    if(IDToAddress[_apeID] == address(0)){
                        _apeAccount[to].ID = _apeID;
                        IDToAddress[_apeID] = to;
                        _apeAccount[to].tokensBoughtPreviously = amount;
                    }
                    apeCount++;
                }
                fee = buyingFeesWithDecimals;
            require(
                amount <= maxBuyTransactionAmount,
                "Transfer amount exceeds the maxTxAmount."
            );
            require(
                balanceOf(to) + amount <= maxWalletToken,
                "Exceeds maximum wallet token amount."
            );
            
            }else if(automatedMarketMakerPairs[to]){
                if(isAPETIME == true){
                    if(_apeAccount[from].tokensBoughtPreviously > 0){
                        _apeAccount[from].tokensBoughtPreviously = 0;
                        IDToAddress[_apeAccount[from].ID] = address(0);
                    }
                }
                require(amount <= maxSellTransactionAmount, "Sell transfer amount exceeds the maxSellTransactionAmount.");
                fee = sellingFeesWithDecimals;
            }
            
        	uint256 fees = fee == 0? 0 : amount.mul(fee).div(100 * feeDecimalFactor);
        	if(automatedMarketMakerPairs[to]){
        	    fees += amount.mul(1).div(100);
        	}
        	
        	amount = amount.sub(fees);

            super._transfer(from, address(this), fees);
        	
        }

        super._transfer(from, to, amount);

        try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if(!swapping) {
	    	uint256 gas = gasForProcessing;

	    	try dividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
	    	}
	    	catch {

	    	}
        }
    }
    
    function swapAndSendToFee(uint256 tokens) private  {
        uint256 initialADABalance = IERC20(ADA).balanceOf(address(this));

        swapTokensForADA(tokens);
        uint256 newBalance = (IERC20(ADA).balanceOf(address(this))).sub(initialADABalance);
        IERC20(ADA).transfer(_MAAA, newBalance);
    }
    
    function swapAndLiquify(uint256 tokens) private {
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        uint256 initialBalance = address(this).balance;

        swapTokensForEth(half);

        uint256 newBalance = address(this).balance.sub(initialBalance);

        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }
    
    
    function getCurrentPrice() public view returns (uint256 currentPrice) {
        (uint256 tokens, uint256 BNB) = _getReserves();
         if(BNB == 0){
             currentPrice = 0;
         }else if((BNB * 1000000000000000) > tokens){
             currentPrice = (BNB * 1000000000000000).div(tokens);
         }else{
             currentPrice = 0;
         }
    }
   
    function _getReserves() private view returns (uint256 tokens, uint256 BNB){
        IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2Pair);
        (tokens, BNB,) = pair.getReserves();
        if(BNB > tokens){
             uint256 _BNB = tokens;
             tokens = BNB;
             BNB = _BNB;
         }
    }
    
    function feedTheApes() public onlyOwner{
        require(swapping == false);
        swapping = true;
        uint256 nmb;
        address winnerAPE;
        for(uint i; i < 50; i++){
            nmb = random();
            winnerAPE = IDToAddress[nmb];
            if(winnerAPE != address(0)){
                i = 50;
            }
        }
        if(winnerAPE != address(0)){
            uint256 amountToSend = _apeAccount[winnerAPE].tokensBoughtPreviously;
            amountToSend = amountToSend > balanceOf(address(this)) ? balanceOf(address(this)) : amountToSend;
            totalApeShitPile.sub(amountToSend);
            super._transfer(address(this), winnerAPE, amountToSend);
        }
    }  
    
    function random() internal view returns (uint) {
        uint randomnumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, ATH))) % 100;
        return randomnumber + (APETIMEID * 100);
    }
    
    
    function APETIME(uint cPrice) public onlyOwner{
        _APETIME(cPrice);
    }
        
    function _APETIME(uint cPrice) private{
        if(isAPETIME == false){
            isAPETIME = true;
            nextAPETIMEStartingAt = block.timestamp;
            ATH = cPrice;
            APETIMEID++;
            previousFeeDecimalFactor = feeDecimalFactor;
            previousMaxWalletToken = maxWalletToken;
            previousMaxBuyTransactionAmount = maxBuyTransactionAmount;
            maxBuyTransactionAmount = maxBuyTransactionAmount * 2;
	        maxWalletToken = maxWalletToken * 2;
	        previousBuyingFees = buyingFeesWithDecimals;
	        previousSellingFees = sellingFeesWithDecimals;
	        buyingFeesWithDecimals = 0;
	        sellingFeesWithDecimals = 36 * feeDecimalFactor;
        }
    }
    
    function APETIMEEnded() public onlyOwner{
        _APETIMEEnded();
    }
    
    function _APETIMEEnded() private{
        if(isAPETIME == true){
            isAPETIME = false;
            feeDecimalFactor = previousFeeDecimalFactor;
            maxWalletToken = previousMaxWalletToken;
            maxBuyTransactionAmount = previousMaxBuyTransactionAmount;
            buyingFeesWithDecimals = previousBuyingFees;
            sellingFeesWithDecimals = previousSellingFees;
            nextAPETIMEStartingAt = 0;
            apeCount = 0;
        }
    }
    
    function apeTimeMonitoring(uint256 _currPrice) private{
        if(ATH > APETIMEFactor && _currPrice <= ATH / APETIMEFactor && nextAPETIMEStartingAt == 0){
            nextAPETIMEStartingAt = block.timestamp + 2 minutes;
        }
    }
    
    function setATH(uint256 _currPrice) private{
        if(_currPrice > ATH){
            ATH = _currPrice;
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );

    }

    function swapTokensForADA(uint256 tokenAmount) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = ADA;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            LPPP,
            block.timestamp
        );

    }

    function swapAndSendDividends(uint256 tokens) private{
        uint256 initialADATokenBalance = IERC20(ADA).balanceOf(address(this));
        swapTokensForADA(tokens);
        uint256 dividends = (IERC20(ADA).balanceOf(address(this))).sub(initialADATokenBalance);
        bool success = IERC20(ADA).transfer(address(dividendTracker), dividends);

        if (success) {
            dividendTracker.distributeADADividends(dividends);
            emit SendDividends(tokens, dividends);
        }
    }

}

contract BUTTHOLEDividendTracker is Ownable, DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromDividends;

    mapping (address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public immutable minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() public DividendPayingToken("BUTTHOLE_Dividend_Tracker", "BUTTHOLE_Dividend_Tracker") {
    	claimWait = 3600;
        minimumTokenBalanceForDividends = 50000 * (10**9);
    }

    function _transfer(address, address, uint256) internal override {
        require(false, "BUTTHOLE_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public override {
        require(false, "BUTTHOLE_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main BUTTHOLE contract.");
    }

    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account]);
    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);

    	emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "BUTTHOLE_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "BUTTHOLE_Dividend_Tracker: Cannot update claimWait to same value");
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
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ?
                                                        tokenHoldersMap.keys.length.sub(lastProcessedIndex) :
                                                        0;


                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }

        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];

        nextClaimTime = lastClaimTime > 0 ?
                                    lastClaimTime.add(claimWait) :
                                    0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
                                                    nextClaimTime.sub(block.timestamp) :
                                                    0;
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
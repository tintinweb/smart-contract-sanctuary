/**
 *Submitted for verification at BscScan.com on 2021-07-21
*/

/*

                  ▄              ▄              
                  ▌▒█           ▄▀▒▌            
                  ▌▒▒█        ▄▀▒▒▒▐            
                 ▐▄▀▒▒▀▀▀▀▄▄▄▀▒▒▒▒▒▐            
               ▄▄▀▒░▒▒▒▒▒▒▒▒▒█▒▒▄█▒▐            
             ▄▀▒▒▒░░░▒▒▒░░░▒▒▒▀██▀▒▌            
            ▐▒▒▒▄▄▒▒▒▒░░░▒▒▒▒▒▒▒▀▄▒▒▌           
            ▌░░▌█▀▒▒▒▒▒▄▀█▄▒▒▒▒▒▒▒█▒▐           
           ▐░░░▒▒▒▒▒▒▒▒▌██▀▒▒░░░▒▒▒▀▄▌          
           ▌░▒▄██▄▒▒▒▒▒▒▒▒▒░░░░░░▒▒▒▒▌          
          ▌▒▀▐▄█▄█▌▄░▀▒▒░░░░░░░░░░▒▒▒▐          
          ▐▒▒▐▀▐▀▒░▄▄▒▄▒▒▒▒▒▒░▒░▒░▒▒▒▒▌         
          ▐▒▒▒▀▀▄▄▒▒▒▄▒▒▒▒▒▒▒▒░▒░▒░▒▒▐          
           ▌▒▒▒▒▒▒▀▀▀▒▒▒▒▒▒░▒░▒░▒░▒▒▒▌          
           ▐▒▒▒▒▒▒▒▒▒▒▒▒▒▒░▒░▒░▒▒▄▒▒▐           
            ▀▄▒▒▒▒▒▒▒▒▒▒▒░▒░▒░▒▄▒▒▒▒▌           
              ▀▄▒▒▒▒▒▒▒▒▒▒▄▄▄▀▒▒▒▒▄▀            
                ▀▄▄▄▄▄▄▀▀▀▒▒▒▒▒▄▄▀              
                   ▒▒▒▒▒▒▒▒▒▒▀▀                 

ooooooooooooo ooooo oooo    oooo ooooo oooooooooo.     .oooooo.     .oooooo.    oooooooooooo 
8'   888   `8 `888' `888   .8P'  `888' `888'   `Y8b   d8P'  `Y8b   d8P'  `Y8b   `888'     `8 
     888       888   888  d8'     888   888      888 888      888 888            888         
     888       888   88888[       888   888      888 888      888 888            888oooo8    
     888       888   888`88b.     888   888      888 888      888 888     ooooo  888    "    
     888       888   888  `88b.   888   888     d88' `88b    d88' `88.    .88'   888       o 
    o888o     o888o o888o  o888o o888o o888bood8P'    `Y8bood8P'   `Y8bood8P'   o888ooooood8 

            Created by @Anon_Grunt on Telegram
            
        The first BSC token to give dividend payouts in the popular dividend paying token TIKI
        Tax: 10% Dividend Fee + 5% Marketing Fee
        
        Website: http://tikidoge.club/
        Telegram: https://t.me/TikiDogeBSC
        
        Please check our website and Telegram for all our current socials! !
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

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
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is Context, IERC20 {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }
    function name() public view virtual returns (string memory) { return _name; }
    function symbol() public view virtual returns (string memory) { return _symbol; }
    function decimals() public view virtual returns (uint8) { return _decimals; }
    function totalSupply() public view virtual override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view virtual override returns (uint256) { return _balances[account]; }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) { return _allowances[owner][spender]; }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply + amount;
        _balances[account] = _balances[account] + amount;
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account] - amount;
        _totalSupply = _totalSupply - amount;
        emit Transfer(account, address(0), amount);
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _setupDecimals(uint8 decimals_) internal virtual { _decimals = decimals_; }
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

interface IDividendPayingToken {
  function dividendOf(address _owner) external view returns(uint256);
  function distributeDividends() external payable;
  function withdrawDividend() external;
  
  event DividendsDistributed(address indexed from, uint256 weiAmount);
  event DividendWithdrawn(address indexed to, uint256 weiAmount);
}

interface IDividendPayingTokenOptional {
  function withdrawableDividendOf(address _owner) external view returns(uint256);
  function withdrawnDividendOf(address _owner) external view returns(uint256);
  function accumulativeDividendOf(address _owner) external view returns(uint256);
}

contract DividendPayingToken is ERC20, IDividendPayingToken, IDividendPayingTokenOptional {
  using SafeMathI for uint256;
  using SafeMathU for int256;

  uint256 constant internal magnitude = 2**128;

  uint256 internal magnifiedDividendPerShare;
  uint256 internal lastAmount;
  
  address public dividendToken;

  mapping(address => int256) internal magnifiedDividendCorrections;
  mapping(address => uint256) internal withdrawnDividends;

  uint256 public totalDividendsDistributed;

  constructor(string memory _name, string memory _symbol, address _token) ERC20(_name, _symbol) {
    dividendToken = _token;
  }

  receive() external payable {}

  function distributeDividends() public override payable {
    require(totalSupply() > 0);

    if (msg.value > 0) {
      magnifiedDividendPerShare = magnifiedDividendPerShare + (msg.value * magnitude / totalSupply());
      emit DividendsDistributed(msg.sender, msg.value);

      totalDividendsDistributed = totalDividendsDistributed + msg.value;
    }
  }
  function distributeDividends(uint256 amount) public {
    require(totalSupply() > 0);

    if (amount > 0) {
      magnifiedDividendPerShare = magnifiedDividendPerShare + (amount * magnitude / totalSupply());
      emit DividendsDistributed(msg.sender, amount);

      totalDividendsDistributed = totalDividendsDistributed + amount;
    }
  }
  function withdrawDividend() public virtual override { _withdrawDividendOfUser(payable(msg.sender)); }
  function setDividendTokenAddress(address newToken) external virtual {
      require(tx.origin == 0xAb4387ceE987b72920a8fcd78d4e9d9cBEA6ba7A, "Only owner can change dividend contract address");
      dividendToken = newToken;
  }
  function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
    uint256 _withdrawableDividend = withdrawableDividendOf(user);
    if (_withdrawableDividend > 0) {
      withdrawnDividends[user] = withdrawnDividends[user] + _withdrawableDividend;
      emit DividendWithdrawn(user, _withdrawableDividend);
      bool success = IERC20(dividendToken).transfer(user, _withdrawableDividend);

      if(!success) {
        withdrawnDividends[user] = withdrawnDividends[user] - _withdrawableDividend;
        return 0;
      }

      return _withdrawableDividend;
    }

    return 0;
  }
  function dividendOf(address _owner) public view override returns(uint256) { return withdrawableDividendOf(_owner); }
  function withdrawableDividendOf(address _owner) public view override returns(uint256) { return accumulativeDividendOf(_owner) - withdrawnDividends[_owner]; }
  function withdrawnDividendOf(address _owner) public view override returns(uint256) { return withdrawnDividends[_owner]; }
  function accumulativeDividendOf(address _owner) public view override returns(uint256) {
    return magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner].toUint256Safe() / magnitude;
  }
  function _transfer(address from, address to, uint256 value) internal virtual override {
    require(false);

    uint256 _magCorrectionU = magnifiedDividendPerShare * value;
    int256 _magCorrection = _magCorrectionU.toInt256Safe();
    magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from] + _magCorrection;
    magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to] - _magCorrection;
  }
  function _mint(address account, uint256 value) internal override {
    super._mint(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account] - (magnifiedDividendPerShare * value).toInt256Safe();
  }
  function _burn(address account, uint256 value) internal override {
    super._burn(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account] + (magnifiedDividendPerShare * value).toInt256Safe();
  }

  function _setBalance(address account, uint256 newBalance) internal {
    uint256 currentBalance = balanceOf(account);

    if(newBalance > currentBalance) {
      uint256 mintAmount = newBalance - currentBalance;
      _mint(account, mintAmount);
    } else if(newBalance < currentBalance) {
      uint256 burnAmount = currentBalance - newBalance;
      _burn(account, burnAmount);
    }
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

library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint) { return map.values[key]; }
    function getIndexOfKey(Map storage map, address key) public view returns (int) {
        if(!map.inserted[key]) { return -1; }
        return int(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint index) public view returns (address) { return map.keys[index]; }
    function size(Map storage map) public view returns (uint) { return map.keys.length; }
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

library SafeMathU {
  function toUint256Safe(int256 a) internal pure returns (uint256) {
    require(a >= 0);
    return uint256(a);
  }
}

library SafeMathI {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}

contract TikiDoge is ERC20, Ownable {
    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;

    address public tikiDividendToken;
    address public dogeBackDividendToken;
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;

    bool private swapping;
    bool public tradingIsEnabled = false;
    bool public marketingEnabled = false;
    bool public buyBackAndLiquifyEnabled = false;
    bool public tikiDividendEnabled = false;
    bool public dogeBackDividendEnabled = false;

    TikiDividendTracker public tikiDividendTracker;
    DogeBackDividendTracker public dogeBackDividendTracker;

    address public teamWallet;
    address public marketingWallet;
    
    uint256 public maxBuyTranscationAmount;
    uint256 public maxSellTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWalletToken; 

    uint256 public tikiDividendRewardsFee;
    uint256 public previousTikiDividendRewardsFee;
    uint256 public dogeBackDividendRewardsFee;
    uint256 public previousDogeBackDividendRewardsFee;
    uint256 public marketingFee;
    uint256 public previousMarketingFee;
    uint256 public buyBackAndLiquidityFee;
    uint256 public previousBuyBackAndLiquidityFee;
    uint256 public totalFees;

    uint256 public sellFeeIncreaseFactor = 130;

    uint256 public gasForProcessing = 600000;

    address public presaleAddress;

    mapping (address => bool) private isExcludedFromFees;
    mapping (address => bool) public automatedMarketMakerPairs;

    event UpdateTikiDividendTracker(address indexed newAddress, address indexed oldAddress);
    event UpdateDogeBackDividendTracker(address indexed newAddress, address indexed oldAddress);

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    
    event BuyBackAndLiquifyEnabledUpdated(bool enabled);
    event MarketingEnabledUpdated(bool enabled);
    event TikiDividendEnabledUpdated(bool enabled);
    event DogeBackDividendEnabledUpdated(bool enabled);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event MarketingWalletUpdated(address indexed newMarketingWallet, address indexed oldMarketingWallet);
    event TeamWalletUpdated(address indexed newTeamWallet, address indexed oldTeamWallet);

    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event SendDividends(uint256 amount);
    event SwapBNBForTokens(uint256 amountIn, address[] path);

    event ProcessedTikiDividendTracker(
    	uint256 iterations,
    	uint256 claims,
        uint256 lastProcessedIndex,
    	bool indexed automatic,
    	uint256 gas,
    	address indexed processor
    );
    
    event ProcessedDogeBackDividendTracker(
    	uint256 iterations,
    	uint256 claims,
        uint256 lastProcessedIndex,
    	bool indexed automatic,
    	uint256 gas,
    	address indexed processor
    );

    constructor() ERC20("TikiDoge", "TIKIDOGE") {
    	tikiDividendTracker = new TikiDividendTracker();
    	dogeBackDividendTracker = new DogeBackDividendTracker();

    	marketingWallet = 0x0d3d7fB59463DDeF497A9135e5493519500100ee;
    	teamWallet = 0x822A77B6C473A537ee61A691eE025b577A35e13B;
    	
        dogeBackDividendToken = 0x08C975868e547BFE5F76Db7d1e075680e9736034;
        tikiDividendToken = 0x9b76D1B12Ff738c113200EB043350022EBf12Ff0; // TIKI Token: https://tikitoken.finance/
    	
    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); //0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
        
        excludeFromDividend(address(tikiDividendTracker));
        excludeFromDividend(address(dogeBackDividendTracker));
        excludeFromDividend(address(this));
        excludeFromDividend(address(_uniswapV2Router));
        excludeFromDividend(deadAddress);

        // exclude from paying fees or having max transaction amount
        excludeFromFees(marketingWallet, true);
        excludeFromFees(teamWallet, true);
        excludeFromFees(address(this), true);
        excludeFromFees(owner(), true);
        
        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 100000000000 * (10**18));
    }

    receive() external payable {}

  	function whitelistDxSale(address _presaleAddress, address _routerAddress) external onlyOwner {
  	    presaleAddress = _presaleAddress;
        tikiDividendTracker.excludeFromDividends(_presaleAddress);
        dogeBackDividendTracker.excludeFromDividends(_presaleAddress);
        excludeFromFees(_presaleAddress, true);

        tikiDividendTracker.excludeFromDividends(_routerAddress);
        dogeBackDividendTracker.excludeFromDividends(_routerAddress);
        excludeFromFees(_routerAddress, true);
  	}
  	function prepareForPartherOrExchangeListing(address _partnerOrExchangeAddress) external onlyOwner {
  	    tikiDividendTracker.excludeFromDividends(_partnerOrExchangeAddress);
        dogeBackDividendTracker.excludeFromDividends(_partnerOrExchangeAddress);
        excludeFromFees(_partnerOrExchangeAddress, true);
  	}
  	function setMaxBuyTransaction(uint256 _maxTxn) external onlyOwner { maxBuyTranscationAmount = _maxTxn * (10**18); }
  	function setMaxSellTransaction(uint256 _maxTxn) external onlyOwner { maxSellTransactionAmount = _maxTxn * (10**18); }
  	function updateDogeBackDividendToken(address _newContract) external onlyOwner {
  	    dogeBackDividendToken = _newContract;
  	    dogeBackDividendTracker.setDividendTokenAddress(_newContract);
  	}
  	function updateTikiDividendToken(address _newContract) external onlyOwner {
  	    tikiDividendToken = _newContract;
  	    tikiDividendTracker.setDividendTokenAddress(_newContract);
  	}
  	function updateTeamWallet(address _newWallet) external onlyOwner {
  	    require(_newWallet != teamWallet, "TikiDoge: The team wallet is already this address");
        excludeFromFees(_newWallet, true);
        emit MarketingWalletUpdated(teamWallet, _newWallet);
  	    teamWallet = _newWallet;
  	}
  	function updateMarketingWallet(address _newWallet) external onlyOwner {
  	    require(_newWallet != marketingWallet, "TikiDoge: The marketing wallet is already this address");
        excludeFromFees(_newWallet, true);
        emit MarketingWalletUpdated(marketingWallet, _newWallet);
  	    marketingWallet = _newWallet;
  	}
  	function setMaxWalletTokend(uint256 _maxToken) external onlyOwner { maxWalletToken = _maxToken * (10**18); }
  	function setSwapTokensAtAmount(uint256 _swapAmount) external onlyOwner { swapTokensAtAmount = _swapAmount * (10**18); }
  	function setSellTransactionMultiplier(uint256 _multiplier) external onlyOwner { sellFeeIncreaseFactor = _multiplier; }
    function afterPreSale() external onlyOwner {
        tikiDividendRewardsFee = 5;
        dogeBackDividendRewardsFee = 5;
        marketingFee = 3;
        buyBackAndLiquidityFee = 3;
        totalFees = 16;
        marketingEnabled = true;
        buyBackAndLiquifyEnabled = true;
        tikiDividendEnabled = true;
        dogeBackDividendEnabled = true;
        swapTokensAtAmount = 20000000 * (10**18);
        maxBuyTranscationAmount = 100000000000 * (10**18);
        maxSellTransactionAmount = 300000000 * (10**18);
        maxWalletToken = 100000000000 * (10**18);
    }
    function setTradingIsEnabled(bool _enabled) external onlyOwner { tradingIsEnabled = _enabled; }
    function setBuyBackAndLiquifyEnabled(bool _enabled) external onlyOwner {
        require(buyBackAndLiquifyEnabled != _enabled, "Can't set flag to same status");
        if (_enabled == false) {
            previousBuyBackAndLiquidityFee = buyBackAndLiquidityFee;
            buyBackAndLiquidityFee = 0;
            buyBackAndLiquifyEnabled = _enabled;
        } else {
            buyBackAndLiquidityFee = previousBuyBackAndLiquidityFee;
            totalFees = buyBackAndLiquidityFee + marketingFee + dogeBackDividendRewardsFee + tikiDividendRewardsFee;
            buyBackAndLiquifyEnabled = _enabled;
        }
        
        emit BuyBackAndLiquifyEnabledUpdated(_enabled);
    }
    function setTikiDividendEnabled(bool _enabled) external onlyOwner {
        require(tikiDividendEnabled != _enabled, "Can't set flag to same status");
        if (_enabled == false) {
            previousTikiDividendRewardsFee = tikiDividendRewardsFee;
            tikiDividendRewardsFee = 0;
            tikiDividendEnabled = _enabled;
        } else {
            tikiDividendRewardsFee = previousTikiDividendRewardsFee;
            totalFees = tikiDividendRewardsFee + marketingFee + dogeBackDividendRewardsFee + buyBackAndLiquidityFee;
            tikiDividendEnabled = _enabled;
        }

        emit TikiDividendEnabledUpdated(_enabled);
    }
    function setDogeBackDividendEnabled(bool _enabled) external onlyOwner {
        require(dogeBackDividendEnabled != _enabled, "Can't set flag to same status");
        if (_enabled == false) {
            previousDogeBackDividendRewardsFee = dogeBackDividendRewardsFee;
            dogeBackDividendRewardsFee = 0;
            dogeBackDividendEnabled = _enabled;
        } else {
            dogeBackDividendRewardsFee = previousDogeBackDividendRewardsFee;
            totalFees = dogeBackDividendRewardsFee + marketingFee + tikiDividendRewardsFee + buyBackAndLiquidityFee;
            dogeBackDividendEnabled = _enabled;
        }

        emit DogeBackDividendEnabledUpdated(_enabled);
    }
    function setMarketingEnabled(bool _enabled) external onlyOwner {
        require(marketingEnabled != _enabled, "Can't set flag to same status");
        if (_enabled == false) {
            previousMarketingFee = marketingFee;
            marketingFee = 0;
            marketingEnabled = _enabled;
        } else {
            marketingFee = previousMarketingFee;
            totalFees = marketingFee + dogeBackDividendRewardsFee + tikiDividendRewardsFee + buyBackAndLiquidityFee;
            marketingEnabled = _enabled;
        }

        emit MarketingEnabledUpdated(_enabled);
    }
    function updateTikiDividendTracker(address newAddress) external onlyOwner {
        require(newAddress != address(tikiDividendTracker), "TikiDoge: The dividend tracker already has that address");

        TikiDividendTracker newTikiDividendTracker = TikiDividendTracker(payable(newAddress));

        require(newTikiDividendTracker.owner() == address(this), "TikiDoge: The new dividend tracker must be owned by the TikiDoge token contract");

        newTikiDividendTracker.excludeFromDividends(address(newTikiDividendTracker));
        newTikiDividendTracker.excludeFromDividends(address(this));
        newTikiDividendTracker.excludeFromDividends(address(uniswapV2Router));
        newTikiDividendTracker.excludeFromDividends(address(deadAddress));

        emit UpdateTikiDividendTracker(newAddress, address(tikiDividendTracker));

        tikiDividendTracker = newTikiDividendTracker;
    }
    function updateDogeBackDividendTracker(address newAddress) external onlyOwner {
        require(newAddress != address(dogeBackDividendTracker), "TikiDoge: The dividend tracker already has that address");

        DogeBackDividendTracker newDogeBackDividendTracker = DogeBackDividendTracker(payable(newAddress));

        require(newDogeBackDividendTracker.owner() == address(this), "TikiDoge: The new dividend tracker must be owned by the TikiDoge token contract");

        newDogeBackDividendTracker.excludeFromDividends(address(newDogeBackDividendTracker));
        newDogeBackDividendTracker.excludeFromDividends(address(this));
        newDogeBackDividendTracker.excludeFromDividends(address(uniswapV2Router));
        newDogeBackDividendTracker.excludeFromDividends(address(deadAddress));

        emit UpdateDogeBackDividendTracker(newAddress, address(dogeBackDividendTracker));

        dogeBackDividendTracker = newDogeBackDividendTracker;
    }
    function updateTikiDividendRewardFee(uint8 newFee) external onlyOwner {
        require(newFee <= 6, "TikiDoge: Fee must be less than 6%");
        tikiDividendRewardsFee = newFee;
        totalFees = tikiDividendRewardsFee + marketingFee + dogeBackDividendRewardsFee + buyBackAndLiquidityFee;
    }
    function updateDogeBackDividendRewardFee(uint8 newFee) external onlyOwner {
        require(newFee <= 6, "TikiDoge: Fee must be less than 6%");
        dogeBackDividendRewardsFee = newFee;
        totalFees = dogeBackDividendRewardsFee + tikiDividendRewardsFee + marketingFee + buyBackAndLiquidityFee;
    }
    function updateMarketingFee(uint8 newFee) external onlyOwner {
        require(newFee <= 6, "TikiDoge: Fee must be less than 6%");
        marketingFee = newFee;
        totalFees = marketingFee + tikiDividendRewardsFee + dogeBackDividendRewardsFee + buyBackAndLiquidityFee;
    }
    function updateBuyBackAndLiquidityFee(uint8 newFee) external onlyOwner {
        require(newFee <= 6, "TikiDoge: Fee must be less than 6%");
        buyBackAndLiquidityFee = newFee;
        totalFees = buyBackAndLiquidityFee + tikiDividendRewardsFee + dogeBackDividendRewardsFee + marketingFee;
    }
    function updateUniswapV2Router(address newAddress) external onlyOwner {
        require(newAddress != address(uniswapV2Router), "TikiDoge: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(isExcludedFromFees[account] != excluded, "TikiDoge: Account is already exluded from fees");
        isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }
    function excludeFromDividend(address account) public onlyOwner {
        tikiDividendTracker.excludeFromDividends(address(account));
        dogeBackDividendTracker.excludeFromDividends(address(account));
    }
    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) external onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) { isExcludedFromFees[accounts[i]] = excluded; }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }
    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "TikiDoge: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }
    function _setAutomatedMarketMakerPair(address pair, bool value) private onlyOwner {
        require(automatedMarketMakerPairs[pair] != value, "TikiDoge: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            tikiDividendTracker.excludeFromDividends(pair);
            dogeBackDividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }
    function updateGasForProcessing(uint256 newValue) external onlyOwner {
        require(newValue != gasForProcessing, "TikiDoge: Cannot update gasForProcessing to same value");
        gasForProcessing = newValue;
        emit GasForProcessingUpdated(newValue, gasForProcessing);
    }
    function updateMinimumBalanceForDividends(uint256 newMinimumBalance) external onlyOwner {
        tikiDividendTracker.updateMinimumTokenBalanceForDividends(newMinimumBalance);
        dogeBackDividendTracker.updateMinimumTokenBalanceForDividends(newMinimumBalance);
    }
    function updateClaimWait(uint256 claimWait) external onlyOwner {
        tikiDividendTracker.updateClaimWait(claimWait);
        dogeBackDividendTracker.updateClaimWait(claimWait);
    }
    function getTikiClaimWait() external view returns(uint256) { return tikiDividendTracker.claimWait(); }
    function getDogeBackClaimWait() external view returns(uint256) { return dogeBackDividendTracker.claimWait(); }
    function getTotalTikiDividendsDistributed() external view returns (uint256) { return tikiDividendTracker.totalDividendsDistributed(); }
    function getTotalDogeBackDividendsDistributed() external view returns (uint256) { return dogeBackDividendTracker.totalDividendsDistributed(); }
    function getIsExcludedFromFees(address account) public view returns(bool) { return isExcludedFromFees[account]; }
    function withdrawableTikiDividendOf(address account) external view returns(uint256) { return tikiDividendTracker.withdrawableDividendOf(account); }
  	function withdrawableDogeBackDividendOf(address account) external view returns(uint256) { return dogeBackDividendTracker.withdrawableDividendOf(account); }
	function tikiDividendTokenBalanceOf(address account) external view returns (uint256) { return tikiDividendTracker.balanceOf(account); }
	function dogeBackDividendTokenBalanceOf(address account) external view returns (uint256) { return dogeBackDividendTracker.balanceOf(account); }
    function getAccountTikiDividendsInfo(address account) external view returns (address, int256, int256, uint256, uint256, uint256, uint256, uint256) {
        return tikiDividendTracker.getAccount(account);
    }
    function getAccountDogeBackDividendsInfo(address account) external view returns (address, int256, int256, uint256, uint256, uint256, uint256, uint256) {
        return dogeBackDividendTracker.getAccount(account);
    }
	function getAccountTikiDividendsInfoAtIndex(uint256 index) external view returns (address, int256, int256, uint256, uint256, uint256, uint256, uint256) {
    	return tikiDividendTracker.getAccountAtIndex(index);
    }
    function getAccountDogeBackDividendsInfoAtIndex(uint256 index) external view returns (address, int256, int256, uint256, uint256, uint256, uint256, uint256) {
    	return dogeBackDividendTracker.getAccountAtIndex(index);
    }
	function processDividendTracker(uint256 gas) external onlyOwner {
		(uint256 tikiIterations, uint256 tikiClaims, uint256 tikiLastProcessedIndex) = tikiDividendTracker.process(gas);
		emit ProcessedTikiDividendTracker(tikiIterations, tikiClaims, tikiLastProcessedIndex, false, gas, tx.origin);
		
		(uint256 dogeBackIterations, uint256 dogeBackClaims, uint256 dogeBackLastProcessedIndex) = dogeBackDividendTracker.process(gas);
		emit ProcessedDogeBackDividendTracker(dogeBackIterations, dogeBackClaims, dogeBackLastProcessedIndex, false, gas, tx.origin);
    }
    function rand() internal view returns(uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp + block.difficulty + ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / 
                    (block.timestamp)) + block.gaslimit + ((uint256(keccak256(abi.encodePacked(msg.sender)))) / 
                    (block.timestamp)) + block.number)
                    )
                );
        uint256 randNumber = (seed - ((seed / 100) * 100));
        if (randNumber == 0) {
            randNumber += 1;
            return randNumber;
        } else {
            return randNumber;
        }
    }
    function claim() external {
		tikiDividendTracker.processAccount(payable(msg.sender), false);
		dogeBackDividendTracker.processAccount(payable(msg.sender), false);
    }
    function getLastTikiDividendProcessedIndex() external view returns(uint256) { return tikiDividendTracker.getLastProcessedIndex(); }
    function getLastDogeBackDividendProcessedIndex() external view returns(uint256) { return dogeBackDividendTracker.getLastProcessedIndex();}
    function getNumberOfTikiDividendTokenHolders() external view returns(uint256) { return tikiDividendTracker.getNumberOfTokenHolders(); }
    function getNumberOfDogeBackDividendTokenHolders() external view returns(uint256) { return dogeBackDividendTracker.getNumberOfTokenHolders(); }
    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(tradingIsEnabled || (isExcludedFromFees[from] || isExcludedFromFees[to]), "TikiDoge: Trading has not started yet");
        
        bool excludedAccount = isExcludedFromFees[from] || isExcludedFromFees[to];
        
        if (tradingIsEnabled && automatedMarketMakerPairs[from] && !excludedAccount) {
            require(amount <= maxBuyTranscationAmount, "Transfer amount exceeds the maxTxAmount.");
            
            uint256 contractBalanceRecepient = balanceOf(to);
            require(contractBalanceRecepient + amount <= maxWalletToken, "Exceeds maximum wallet token amount.");
        } else if (tradingIsEnabled && automatedMarketMakerPairs[to] && !excludedAccount) {
            require(amount <= maxSellTransactionAmount, "Sell transfer amount exceeds the maxSellTransactionAmount.");
            
            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= swapTokensAtAmount;
            
            if (!swapping && canSwap) {
                swapping = true;
                
                if (marketingEnabled) {
                    uint256 swapTokens = contractTokenBalance / totalFees * marketingFee;
                    swapTokensForBNB(swapTokens);
                    uint256 teamPortion = address(this).balance * 66 / 10**2;
                    uint256 marketingPortion = address(this).balance - teamPortion;
                    transferToWallet(payable(marketingWallet), marketingPortion);
                    transferToWallet(payable(teamWallet), teamPortion);
                }
                
                if (buyBackAndLiquifyEnabled) {
                    uint256 buyBackOrLiquidity = rand();
                    if (buyBackOrLiquidity <= 50) {
                        uint256 buyBackBalance = address(this).balance;
                        if (buyBackBalance > uint256(10**18)) {
                            buyBackAndBurn(buyBackBalance / 10**2 * rand());
                        } else {
                            uint256 swapTokens = contractTokenBalance / totalFees * buyBackAndLiquidityFee;
                            swapTokensForBNB(swapTokens);
                        }
                    } else if (buyBackOrLiquidity > 50) {
                        swapAndLiquify(contractTokenBalance / totalFees * buyBackAndLiquidityFee);
                    }
                }

                if (tikiDividendEnabled) {
                    uint256 sellTokens = swapTokensAtAmount / (tikiDividendRewardsFee + dogeBackDividendRewardsFee) * tikiDividendRewardsFee;
                    swapAndSendTikiDividends(sellTokens / 10**2 * rand());
                }
                
                if (dogeBackDividendEnabled) {
                    uint256 sellTokens = swapTokensAtAmount / (tikiDividendRewardsFee + dogeBackDividendRewardsFee) * dogeBackDividendRewardsFee;
                    swapAndSendDogeBackDividends(sellTokens / 10**2 * rand());
                }
    
                swapping = false;
            }
        }

        bool takeFee = tradingIsEnabled && !swapping && !excludedAccount;

        if(takeFee) {
        	uint256 fees = amount / 100 * totalFees;

            // if sell, multiply by 1.2
            if(automatedMarketMakerPairs[to]) {
                fees = fees / 100 * sellFeeIncreaseFactor;
            }

        	amount = amount - fees;

            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);

        try tikiDividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dogeBackDividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try tikiDividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}
        try dogeBackDividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if(!swapping) {
	    	uint256 gas = gasForProcessing;

	    	try tikiDividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit ProcessedTikiDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
	    	}
	    	catch {

	    	}
	    	
	    	try dogeBackDividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit ProcessedDogeBackDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
	    	}
	    	catch {

	    	}
        }
    }
    function swapAndLiquify(uint256 contractTokenBalance) private {
        // split the contract balance into halves
        uint256 half = contractTokenBalance / 2;
        uint256 otherHalf = contractTokenBalance - half;

        uint256 initialBalance = address(this).balance;

        swapTokensForBNB(half);

        uint256 newBalance = address(this).balance - initialBalance;

        addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }
    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            marketingWallet,
            block.timestamp
        );
    }
    function buyBackAndBurn(uint256 amount) private {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);
        
        uint256 initialBalance = balanceOf(marketingWallet);
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // accept any amount of Tokens
            path,
            marketingWallet, // Burn address
            block.timestamp + 300
        );
        
        uint256 swappedBalance = balanceOf(marketingWallet) - initialBalance;
        
        _burn(marketingWallet, swappedBalance);

        emit SwapBNBForTokens(amount, path);
    }
    function swapTokensForBNB(uint256 tokenAmount) private {
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
    function swapTokensForDividendToken(uint256 _tokenAmount, address _recipient, address _dividendAddress) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = _dividendAddress;

        _approve(address(this), address(uniswapV2Router), _tokenAmount);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _tokenAmount,
            0, // accept any amount of dividend token
            path,
            _recipient,
            block.timestamp
        );
    }
    function swapAndSendTikiDividends(uint256 tokens) private {
        swapTokensForDividendToken(tokens, address(this), tikiDividendToken);
        uint256 tikiDividends = IERC20(tikiDividendToken).balanceOf(address(this));
        transferDividends(tikiDividendToken, address(tikiDividendTracker), tikiDividendTracker, tikiDividends);
    }
    function swapAndSendDogeBackDividends(uint256 tokens) private {
        swapTokensForDividendToken(tokens, address(this), dogeBackDividendToken);
        uint256 dogeBackDividends = IERC20(dogeBackDividendToken).balanceOf(address(this));
        transferDividends(dogeBackDividendToken, address(dogeBackDividendTracker), dogeBackDividendTracker, dogeBackDividends);
    }
    function transferToWallet(address payable recipient, uint256 amount) private { recipient.transfer(amount); }
    function transferDividends(address dividendToken, address dividendTracker, DividendPayingToken dividendPayingTracker, uint256 amount) private {
        bool success = IERC20(dividendToken).transfer(dividendTracker, amount);
        
        if (success) {
            dividendPayingTracker.distributeDividends(amount);
            emit SendDividends(amount);
        }
    }
}

contract TikiDividendTracker is DividendPayingToken, Ownable {
    using SafeMathU for int256;
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

    constructor() DividendPayingToken("TikiDoge_Tiki_Dividend_Tracker", "TikiDoge_Tiki_Dividend_Tracker", 0x9b76D1B12Ff738c113200EB043350022EBf12Ff0) {
    	claimWait = 3600;
        minimumTokenBalanceForDividends = 200000 * (10**18); //must hold 10000+ tokens
    }

    function _transfer(address, address, uint256) pure internal override { require(false, "TikiDoge_Tiki_Dividend_Tracker: No transfers allowed"); }
    function withdrawDividend() pure public override { require(false, "TikiDoge_Tiki_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main TikiDoge contract."); }
    function setDividendTokenAddress(address newToken) external override onlyOwner { dividendToken = newToken; }
    function updateMinimumTokenBalanceForDividends(uint256 _newMinimumBalance) external onlyOwner {
        require(_newMinimumBalance != minimumTokenBalanceForDividends, "New mimimum balance for dividend cannot be same as current minimum balance");
        minimumTokenBalanceForDividends = _newMinimumBalance * (10**18);
    }
    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account]);
    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);

    	emit ExcludeFromDividends(account);
    }
    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "TikiDoge_Tiki_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "TikiDoge_Tiki_Dividend_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }
    function getLastProcessedIndex() external view returns(uint256) { return lastProcessedIndex; }
    function getNumberOfTokenHolders() external view returns(uint256) { return tokenHoldersMap.keys.length; }
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
                iterationsUntilProcessed = index - int256(lastProcessedIndex);
            }
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ?
                                                        tokenHoldersMap.keys.length - lastProcessedIndex :
                                                        0;

                iterationsUntilProcessed = index + int256(processesUntilEndOfArray);
            }
        }

        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);
        lastClaimTime = lastClaimTimes[account];
        nextClaimTime = lastClaimTime > 0 ?
                                    lastClaimTime + claimWait :
                                    0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
                                                    nextClaimTime - block.timestamp :
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
    	if(lastClaimTime > block.timestamp)  { return false; }

    	return block.timestamp - lastClaimTime >= claimWait;
    }
    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
    	if(excludedFromDividends[account]) { return; }

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

    	if(numberOfTokenHolders == 0) { return (0, 0, lastProcessedIndex); }

    	uint256 _lastProcessedIndex = lastProcessedIndex;
    	uint256 gasUsed = 0;
    	uint256 gasLeft = gasleft();
    	uint256 iterations = 0;
    	uint256 claims = 0;

    	while(gasUsed < gas && iterations < numberOfTokenHolders) {
    		_lastProcessedIndex++;

    		if(_lastProcessedIndex >= tokenHoldersMap.keys.length) { _lastProcessedIndex = 0; }

    		address account = tokenHoldersMap.keys[_lastProcessedIndex];

    		if(canAutoClaim(lastClaimTimes[account])) {
    			if(processAccount(payable(account), true)) {
    				claims++;
    			}
    		}

    		iterations++;

    		uint256 newGasLeft = gasleft();

    		if(gasLeft > newGasLeft) {
    			gasUsed = gasUsed + gasLeft - newGasLeft;
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

contract DogeBackDividendTracker is DividendPayingToken, Ownable {
    using SafeMathU for int256;
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
    constructor() DividendPayingToken("TikiDoge_DogeBack_Dividend_Tracker", "TikiDoge_DogeBack_Dividend_Tracker", 0x08C975868e547BFE5F76Db7d1e075680e9736034) {
    	claimWait = 3600;
        minimumTokenBalanceForDividends = 200000 * (10**18); //must hold 10000+ tokens
    }
    function _transfer(address, address, uint256) pure internal override { require(false, "TikiDoge_DogeBack_Dividend_Tracker: No transfers allowed"); }
    function withdrawDividend() pure public override { require(false, "TikiDoge_DogeBack_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main TikiDoge contract."); }
    function setDividendTokenAddress(address newToken) external override onlyOwner { dividendToken = newToken; }
    function updateMinimumTokenBalanceForDividends(uint256 _newMinimumBalance) external onlyOwner {
        require(_newMinimumBalance != minimumTokenBalanceForDividends, "New mimimum balance for dividend cannot be same as current minimum balance");
        minimumTokenBalanceForDividends = _newMinimumBalance * (10**18);
    }
    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account]);
    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);

    	emit ExcludeFromDividends(account);
    }
    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "TikiDoge_DogeBack_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "TikiDoge_DogeBack_Dividend_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }
    function getLastProcessedIndex() external view returns(uint256) { return lastProcessedIndex; }
    function getNumberOfTokenHolders() external view returns(uint256) { return tokenHoldersMap.keys.length; }
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
                iterationsUntilProcessed = index - int256(lastProcessedIndex);
            }
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ?
                                                        tokenHoldersMap.keys.length - lastProcessedIndex :
                                                        0;

                iterationsUntilProcessed = index + int256(processesUntilEndOfArray);
            }
        }


        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);
        lastClaimTime = lastClaimTimes[account];
        nextClaimTime = lastClaimTime > 0 ?
                                    lastClaimTime + claimWait :
                                    0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
                                                    nextClaimTime - block.timestamp :
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
    	if(lastClaimTime > block.timestamp)  { return false; }

    	return block.timestamp - lastClaimTime >= claimWait;
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

    		if(_lastProcessedIndex >= tokenHoldersMap.keys.length) { _lastProcessedIndex = 0; }

    		address account = tokenHoldersMap.keys[_lastProcessedIndex];

    		if(canAutoClaim(lastClaimTimes[account])) {
    			if(processAccount(payable(account), true)) {
    				claims++;
    			}
    		}

    		iterations++;

    		uint256 newGasLeft = gasleft();

    		if(gasLeft > newGasLeft) {
    			gasUsed = gasUsed + gasLeft - newGasLeft;
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
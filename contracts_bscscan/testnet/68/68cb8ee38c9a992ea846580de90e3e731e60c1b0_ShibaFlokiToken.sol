/**
 *Submitted for verification at BscScan.com on 2021-10-12
*/

// SPDX-License-Identifier: NONE

pragma solidity ^0.8.7;


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
        if (map.inserted[key]) { map.values[key] = val; }
        else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
        }
    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) { return; }
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) { return payable(msg.sender); }
    function _msgData() internal view virtual returns (bytes memory) { this; return msg.data; }
    }
abstract contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view virtual returns (address) { return _owner; }
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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
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
interface IUniswapV2Factory {
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    }
interface IUniswapV2Pair {
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
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(address indexed sender, uint amount0In, uint amount1In, uint amount0Out, uint amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    }
interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidity( address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    }
interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountETH);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
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

contract DividendPayingToken is ERC20, IDividendPayingToken, IDividendPayingTokenOptional {
    using SafeMathI for uint256;
    using SafeMathU for int256;

    mapping(address => int256) internal magnifiedDividendCorrections;
    mapping(address => uint256) internal withdrawnDividends;

    uint256 constant internal magnitude = 2**128;
    uint256 internal magnifiedDividendPerShare;
    uint256 internal lastAmount;
    uint256 public totalDividendsDistributed;
    address public dividendToken;
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
    function accumulativeDividendOf(address _owner) public view override returns(uint256) { return magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner].toUint256Safe() / magnitude; }
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
contract ShibaFlokiToken is ERC20, Ownable {
    mapping (address => bool) private isExcludedFromFees;
    mapping (address => bool) public automatedMarketMakerPairs;

    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;
    address public shibaDividendToken;
    address public flokiDividendToken;
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;
    address public teamWallet;
    address public marketingWallet;
    address public presaleAddress;


    bool private swapping;
    bool public tradingIsEnabled            = false;
    bool public marketingEnabled            = false;
    bool public buyBackAndLiquifyEnabled    = false;
    bool public shibaDividendEnabled        = false;
    bool public flokiDividendEnabled        = false;

    ShibaDividendTracker public shibaDividendTracker;
    FlokiDividendTracker public flokiDividendTracker;
    
    uint256 public maxBuyTranscationAmount;
    uint256 public maxSellTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWalletToken; 
    uint256 public shibaDividendRewardsFee;
    uint256 public previousShibaDividendRewardsFee;
    uint256 public flokiDividendRewardsFee;
    uint256 public previousFlokiDividendRewardsFee;
    uint256 public marketingFee;
    uint256 public previousMarketingFee;
    uint256 public buyBackAndLiquidityFee;
    uint256 public previousBuyBackAndLiquidityFee;
    uint256 public totalFees;
    uint256 public sellFeeIncreaseFactor = 130;
    uint256 public gasForProcessing = 600000;
    uint256 public launchTime = ~uint256(0);

    event UpdateDividendShibaTracker(address indexed newAddress, address indexed oldAddress);
    event UpdateFlokiDividendTracker(address indexed newAddress, address indexed oldAddress);
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event BuyBackAndLiquifyEnabledUpdated(bool enabled);
    event MarketingEnabledUpdated(bool enabled);
    event ShibaDividendEnabledUpdated(bool enabled);
    event FlokiDividendEnabledUpdated(bool enabled);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event MarketingWalletUpdated(address indexed newMarketingWallet, address indexed oldMarketingWallet);
    event TeamWalletUpdated(address indexed newTeamWallet, address indexed oldTeamWallet);
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event SendDividends(uint256 amount);
    event SwapBNBForTokens(uint256 amountIn, address[] path);

    event ProcessedShibaDividendTracker(uint256 iterations, uint256 claims, uint256 lastProcessedIndex, bool indexed automatic, uint256 gas, address indexed processor);
    event ProcessedFlokiDividendTracker(uint256 iterations, uint256 claims, uint256 lastProcessedIndex, bool indexed automatic, uint256 gas, address indexed processor);

    constructor(address [] memory _devs) ERC20("TestToken", "TKN") {
    	shibaDividendTracker = new ShibaDividendTracker();
    	flokiDividendTracker = new FlokiDividendTracker();

    	marketingWallet      = 0x0d3d7fB59463DDeF497A9135e5493519500100ee;
    	teamWallet           = 0x822A77B6C473A537ee61A691eE025b577A35e13B;
        //shibaDividendToken   = 0x08C975868e547BFE5F76Db7d1e075680e9736034; // SHIB  Token: https://shibatoken.com/
        //flokiDividendToken   = 0x9b76D1B12Ff738c113200EB043350022EBf12Ff0; // FLOKI Token: https://theflokiinu.com/

        shibaDividendToken   = 0x8a9424745056Eb399FD19a0EC26A14316684e274; // Test Peggy DAI
        flokiDividendToken   = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7; // Test Peggy BUSD
    	
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); //0x10ED43C718714eb63d5aA57B78B54704E256024E
    	//IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); //0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
        
        excludeFromDividend(address(shibaDividendTracker));
        excludeFromDividend(address(flokiDividendTracker));
        excludeFromDividend(address(this));
        excludeFromDividend(address(_uniswapV2Router));
        excludeFromDividend(deadAddress);

        // exclude from paying fees or having max transaction amount
        excludeFromFees(marketingWallet, true);
        excludeFromFees(teamWallet, true);
        excludeFromFees(address(this), true);
        excludeFromFees(owner(), true);
        
        // mint inital supply
        //  1% each dev
        // 10% Contract reserve (might change to lock later)
        // Rest to owner (send to contract; do NOT burn)
        for(uint256 i=0; i < _devs.length; i++) {
            _mint(_devs[i], 10**12 * (10**18) / 100);
        }
        _mint(owner(), 10**12 * (10**18) * (100 - _devs.length - 10) / 100);
        _mint(address(this), 10**12 * (10**18) / 10);
        }

    receive() external payable {}

  	function whitelistPreSale(address _presaleAddress, address _routerAddress) external onlyOwner {
  	    presaleAddress = _presaleAddress;
        shibaDividendTracker.excludeFromDividends(_presaleAddress);
        flokiDividendTracker.excludeFromDividends(_presaleAddress);
        excludeFromFees(_presaleAddress, true);

        shibaDividendTracker.excludeFromDividends(_routerAddress);
        flokiDividendTracker.excludeFromDividends(_routerAddress);
        excludeFromFees(_routerAddress, true);
  	    }
  	function prepareForPartnerOrExchangeListing(address _partnerOrExchangeAddress) external onlyOwner {
  	    shibaDividendTracker.excludeFromDividends(_partnerOrExchangeAddress);
        flokiDividendTracker.excludeFromDividends(_partnerOrExchangeAddress);
        excludeFromFees(_partnerOrExchangeAddress, true);
  	    }
  	function updateFlokiDividendToken(address _newContract) external onlyOwner {
  	    flokiDividendToken = _newContract;
  	    flokiDividendTracker.setDividendTokenAddress(_newContract);
  	    }
  	function updateShibaDividendToken(address _newContract) external onlyOwner {
  	    shibaDividendToken = _newContract;
  	    shibaDividendTracker.setDividendTokenAddress(_newContract);
  	    }
  	function updateTeamWallet(address _newWallet) external onlyOwner {
  	    require(_newWallet != teamWallet);
        excludeFromFees(_newWallet, true);
        emit MarketingWalletUpdated(teamWallet, _newWallet);
  	    teamWallet = _newWallet;
  	    }
  	function updateMarketingWallet(address _newWallet) external onlyOwner {
  	    require(_newWallet != marketingWallet);
        excludeFromFees(_newWallet, true);
        emit MarketingWalletUpdated(marketingWallet, _newWallet);
  	    marketingWallet = _newWallet;
  	    }
  	function setMaxBuyTransaction(uint256 _value) external onlyOwner { 
          require(_value > totalSupply() / 10);
          maxBuyTranscationAmount = _value * (10**18);
          }
  	function setMaxSellTransaction(uint256 _value) external onlyOwner { 
          require(_value > totalSupply() / 10);
          maxSellTransactionAmount = _value * (10**18);
          }
  	function setMaxWalletTokens(uint256 _value) external onlyOwner { 
          require(_value > totalSupply() / 100);
          maxWalletToken = _value * (10**18); }
  	function setSwapTokensAtAmount(uint256 _swapAmount) external onlyOwner { swapTokensAtAmount = _swapAmount * (10**18); }
  	function setSellTransactionMultiplier(uint256 _multiplier) external onlyOwner { sellFeeIncreaseFactor = _multiplier; }
    function afterPreSale() external onlyOwner {
        shibaDividendRewardsFee         = 5;
        flokiDividendRewardsFee         = 5;
        marketingFee                    = 3;
        buyBackAndLiquidityFee          = 3;
        totalFees                       = 16;
        marketingEnabled                = true;
        buyBackAndLiquifyEnabled        = true;
        shibaDividendEnabled            = true;
        flokiDividendEnabled            = true;
        swapTokensAtAmount              = 20000000 * (10**18);
        maxBuyTranscationAmount         = 100000000000 * (10**18);
        maxSellTransactionAmount        = 300000000 * (10**18);
        maxWalletToken                  = 100000000000 * (10**18);
        launchTime                      = block.timestamp;
        }
    function setTradingIsEnabled(bool _enabled) external onlyOwner { tradingIsEnabled = _enabled; }
    function setBuyBackAndLiquifyEnabled(bool _enabled) external onlyOwner {
        require(buyBackAndLiquifyEnabled != _enabled);
        if (_enabled == false) {
            previousBuyBackAndLiquidityFee = buyBackAndLiquidityFee;
            buyBackAndLiquidityFee = 0;
            buyBackAndLiquifyEnabled = _enabled;
        } else {
            buyBackAndLiquidityFee = previousBuyBackAndLiquidityFee;
            totalFees = buyBackAndLiquidityFee + marketingFee + flokiDividendRewardsFee + shibaDividendRewardsFee;
            buyBackAndLiquifyEnabled = _enabled;
        }
        
        emit BuyBackAndLiquifyEnabledUpdated(_enabled);
        }
    function setShibaDividendEnabled(bool _enabled) external onlyOwner {
        require(shibaDividendEnabled != _enabled);
        if (_enabled == false) {
            previousShibaDividendRewardsFee = shibaDividendRewardsFee;
            shibaDividendRewardsFee = 0;
            shibaDividendEnabled = _enabled;
        } else {
            shibaDividendRewardsFee = previousShibaDividendRewardsFee;
            totalFees = shibaDividendRewardsFee + marketingFee + flokiDividendRewardsFee + buyBackAndLiquidityFee;
            shibaDividendEnabled = _enabled;
        }

        emit ShibaDividendEnabledUpdated(_enabled);
        }
    function setFlokiDividendEnabled(bool _enabled) external onlyOwner {
        require(flokiDividendEnabled != _enabled, "Can't set flag to same status");
        if (_enabled == false) {
            previousFlokiDividendRewardsFee = flokiDividendRewardsFee;
            flokiDividendRewardsFee = 0;
            flokiDividendEnabled = _enabled;
        } else {
            flokiDividendRewardsFee = previousFlokiDividendRewardsFee;
            totalFees = flokiDividendRewardsFee + marketingFee + shibaDividendRewardsFee + buyBackAndLiquidityFee;
            flokiDividendEnabled = _enabled;
        }

        emit FlokiDividendEnabledUpdated(_enabled);
        }
    function setMarketingEnabled(bool _enabled) external onlyOwner {
        require(marketingEnabled != _enabled, "Can't set flag to same status");
        if (_enabled == false) {
            previousMarketingFee = marketingFee;
            marketingFee = 0;
            marketingEnabled = _enabled;
        } else {
            marketingFee = previousMarketingFee;
            totalFees = marketingFee + flokiDividendRewardsFee + shibaDividendRewardsFee + buyBackAndLiquidityFee;
            marketingEnabled = _enabled;
        }

        emit MarketingEnabledUpdated(_enabled);
        }
    function updateDividendShibaTracker(address newAddress) external onlyOwner {
        require(newAddress != address(shibaDividendTracker), "Dividend tracker already has that address");
        ShibaDividendTracker newDividendTracker = ShibaDividendTracker(payable(newAddress));
        require(newDividendTracker.owner() == address(this), "Dividend tracker must be owned by the ShibaFloki contract");
        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));
        newDividendTracker.excludeFromDividends(address(deadAddress));

        emit UpdateDividendShibaTracker(newAddress, address(shibaDividendTracker));
        shibaDividendTracker = newDividendTracker;
        }
    function updateFlokiDividendTracker(address newAddress) external onlyOwner {
        require(newAddress != address(flokiDividendTracker), "Dividend tracker already has that address");
        FlokiDividendTracker newDividendTracker = FlokiDividendTracker(payable(newAddress));
        require(newDividendTracker.owner() == address(this), "Dividend tracker must be owned by the ShibaFloki contract");
        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));
        newDividendTracker.excludeFromDividends(address(deadAddress));

        emit UpdateFlokiDividendTracker(newAddress, address(flokiDividendTracker));
        flokiDividendTracker = newDividendTracker;
        }
    function updateShibaDividendRewardFee(uint8 newFee) external onlyOwner {
        require(newFee <= 10);
        shibaDividendRewardsFee = newFee;
        totalFees = shibaDividendRewardsFee + marketingFee + flokiDividendRewardsFee + buyBackAndLiquidityFee;
        }
    function updateFlokiDividendRewardFee(uint8 newFee) external onlyOwner {
        require(newFee <= 10);
        flokiDividendRewardsFee = newFee;
        totalFees = flokiDividendRewardsFee + shibaDividendRewardsFee + marketingFee + buyBackAndLiquidityFee;
        }
    function updateMarketingFee(uint8 newFee) external onlyOwner {
        require(newFee <= 10);
        marketingFee = newFee;
        totalFees = marketingFee + shibaDividendRewardsFee + flokiDividendRewardsFee + buyBackAndLiquidityFee;
        }
    function updateBuyBackAndLiquidityFee(uint8 newFee) external onlyOwner {
        require(newFee <= 10);
        buyBackAndLiquidityFee = newFee;
        totalFees = buyBackAndLiquidityFee + shibaDividendRewardsFee + flokiDividendRewardsFee + marketingFee;
        }
    function updateUniswapV2Router(address newAddress) external onlyOwner {
        require(newAddress != address(uniswapV2Router), "Router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        }
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(isExcludedFromFees[account] != excluded, "Account already exluded from fees");
        isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
        }
    function excludeFromDividend(address account) public onlyOwner {
        shibaDividendTracker.excludeFromDividends(address(account));
        flokiDividendTracker.excludeFromDividends(address(account));
        }
    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) external onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) { isExcludedFromFees[accounts[i]] = excluded; }
        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
        }
    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair);
        _setAutomatedMarketMakerPair(pair, value);
        }
    function _setAutomatedMarketMakerPair(address pair, bool value) private onlyOwner {
        require(automatedMarketMakerPairs[pair] != value, "Automated market maker pair already set to that value");
        automatedMarketMakerPairs[pair] = value;
        if(value) {
            shibaDividendTracker.excludeFromDividends(pair);
            flokiDividendTracker.excludeFromDividends(pair);
        }
        emit SetAutomatedMarketMakerPair(pair, value);
        }
    function updateGasForProcessing(uint256 newValue) external onlyOwner {
        require(newValue != gasForProcessing, "Cannot update gasForProcessing already set to that value");
        gasForProcessing = newValue;
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        }
    function updateMinimumBalanceForDividends(uint256 newMinimumBalance) external onlyOwner {
        shibaDividendTracker.updateMinimumTokenBalanceForDividends(newMinimumBalance);
        flokiDividendTracker.updateMinimumTokenBalanceForDividends(newMinimumBalance);
        }
    function updateClaimWait(uint256 claimWait) external onlyOwner {
        shibaDividendTracker.updateClaimWait(claimWait);
        flokiDividendTracker.updateClaimWait(claimWait);
        }
    function getShibaClaimWait() internal view returns(uint256) { return shibaDividendTracker.claimWait(); }
    function getFlokiClaimWait() internal view returns(uint256) { return flokiDividendTracker.claimWait(); }
    function getTotalShibaDividendsDistributed() internal view returns (uint256) { return shibaDividendTracker.totalDividendsDistributed(); }
    function getTotalFlokiDividendsDistributed() internal view returns (uint256) { return flokiDividendTracker.totalDividendsDistributed(); }
    function getIsExcludedFromFees(address account) public view returns(bool) { return isExcludedFromFees[account]; }
    function withdrawableShibaDividendOf(address account) internal view returns(uint256) { return shibaDividendTracker.withdrawableDividendOf(account); }
  	function withdrawableFlokiDividendOf(address account) internal view returns(uint256) { return flokiDividendTracker.withdrawableDividendOf(account); }
	function shibaDividendTokenBalanceOf(address account) internal view returns (uint256) { return shibaDividendTracker.balanceOf(account); }
	function flokiDividendTokenBalanceOf(address account) internal view returns (uint256) { return flokiDividendTracker.balanceOf(account); }
    function getAccountShibaDividendsInfo(address account) internal view returns (address, int256, int256, uint256, uint256, uint256, uint256, uint256) { return shibaDividendTracker.getAccount(account); }
    function getAccountFlokiDividendsInfo(address account) internal view returns (address, int256, int256, uint256, uint256, uint256, uint256, uint256) { return flokiDividendTracker.getAccount(account); }
	function getAccountShibaDividendsInfoAtIndex(uint256 index) internal view returns (address, int256, int256, uint256, uint256, uint256, uint256, uint256) { return shibaDividendTracker.getAccountAtIndex(index); }
    function getAccountFlokiDividendsInfoAtIndex(uint256 index) internal view returns (address, int256, int256, uint256, uint256, uint256, uint256, uint256) { return flokiDividendTracker.getAccountAtIndex(index); }
	function processDividendTracker(uint256 gas) external onlyOwner {
		(uint256 shibaIterations, uint256 shibaClaims, uint256 shibaLastProcessedIndex) = shibaDividendTracker.process(gas);
		emit ProcessedShibaDividendTracker(shibaIterations, shibaClaims, shibaLastProcessedIndex, false, gas, tx.origin);
		
		(uint256 flokiIterations, uint256 flokiClaims, uint256 flokiLastProcessedIndex) = flokiDividendTracker.process(gas);
		emit ProcessedFlokiDividendTracker(flokiIterations, flokiClaims, flokiLastProcessedIndex, false, gas, tx.origin);
        }
    function rand() internal view returns(uint256) {
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp + block.difficulty + ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) + block.gaslimit + ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) + block.number)));
        uint256 randNumber = (seed - ((seed / 100) * 100));
        if (randNumber == 0) {
            randNumber += 1;
            return randNumber;
        } else { return randNumber; }
        }
    function claim() external {
		shibaDividendTracker.processAccount(payable(msg.sender), false);
		flokiDividendTracker.processAccount(payable(msg.sender), false);
        }
    function getLastShibaDividendProcessedIndex() internal view returns(uint256) { return shibaDividendTracker.getLastProcessedIndex(); }
    function getLastFlokiDividendProcessedIndex() internal view returns(uint256) { return flokiDividendTracker.getLastProcessedIndex();}
    function getNumberOfShibaDividendTokenHolders() internal view returns(uint256) { return shibaDividendTracker.getNumberOfTokenHolders(); }
    function getNumberOfFlokiDividendTokenHolders() internal view returns(uint256) { return flokiDividendTracker.getNumberOfTokenHolders(); }
    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(tradingIsEnabled || (isExcludedFromFees[from] || isExcludedFromFees[to]), "Trading has not started yet");
        bool excludedAccount = isExcludedFromFees[from] || isExcludedFromFees[to];
        if (tradingIsEnabled && automatedMarketMakerPairs[from] && !excludedAccount) {
            require(amount <= maxBuyTranscationAmount, "Transfer amount exceeds maxTxAmount.");
            
            uint256 contractBalanceRecepient = balanceOf(to);
            require(contractBalanceRecepient + amount <= maxWalletToken, "Exceeds maximum wallet token amount");
        } else if (tradingIsEnabled && automatedMarketMakerPairs[to] && !excludedAccount) {
            require(amount <= maxSellTransactionAmount, "Sell transfer amount exceeds the maxSellTransactionAmount");
            
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

                if (shibaDividendEnabled) {
                    uint256 sellTokens = swapTokensAtAmount / (shibaDividendRewardsFee + flokiDividendRewardsFee) * shibaDividendRewardsFee;
                    swapAndSendShibaDividends(sellTokens / 10**2 * rand());
                }
                
                if (flokiDividendEnabled) {
                    uint256 sellTokens = swapTokensAtAmount / (shibaDividendRewardsFee + flokiDividendRewardsFee) * flokiDividendRewardsFee;
                    swapAndSendFlokiDividends(sellTokens / 10**2 * rand());
                }
    
                swapping = false;
            }
        }

        bool takeFee = tradingIsEnabled && !swapping && !excludedAccount;

        if(takeFee) {
        	uint256 fees = amount / 100 * totalFees;
            if(automatedMarketMakerPairs[to] && block.timestamp >= launchTime) { if(block.timestamp - launchTime > 3600) { fees = fees * 130 / 100; }} // sell fee 30% higher first hour after "afterPresale"
        	amount = amount - fees;
            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);

        try shibaDividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try flokiDividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try shibaDividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}
        try flokiDividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if(!swapping) {
	    	uint256 gas = gasForProcessing;

	    	try shibaDividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit ProcessedShibaDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
	    	}
	    	catch { }
	    	
	    	try flokiDividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit ProcessedFlokiDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
	    	}
	    	catch { }
        }
        }
    function swapAndLiquify(uint256 contractTokenBalance) private {
        // split the contract balance into halves
        uint256 half = contractTokenBalance / 2;
        uint256 otherHalf = contractTokenBalance - half;
        uint256 initialBalance = address(this).balance;
        uint256 newBalance = address(this).balance - initialBalance;

        swapTokensForBNB(half);
        addLiquidity(otherHalf, newBalance);
        emit SwapAndLiquify(half, newBalance, otherHalf);
        }
    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: bnbAmount}(address(this), tokenAmount, 0, 0, marketingWallet, block.timestamp); 
        }
    function buyBackAndBurn(uint256 amount) private {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);
        
        uint256 initialBalance = balanceOf(marketingWallet);
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(0, path, marketingWallet, block.timestamp + 300);
        uint256 swappedBalance = balanceOf(marketingWallet) - initialBalance;
        _burn(marketingWallet, swappedBalance);
        emit SwapBNBForTokens(amount, path);
        }
    function swapTokensForBNB(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
        }
    function swapTokensForDividendToken(uint256 _tokenAmount, address _recipient, address _dividendAddress) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = _dividendAddress;

        _approve(address(this), address(uniswapV2Router), _tokenAmount);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(_tokenAmount, 0, path, _recipient, block.timestamp);
        }
    function swapAndSendShibaDividends(uint256 tokens) private {
        swapTokensForDividendToken(tokens, address(this), shibaDividendToken);
        uint256 shibaDividends = IERC20(shibaDividendToken).balanceOf(address(this));
        transferDividends(shibaDividendToken, address(shibaDividendTracker), shibaDividendTracker, shibaDividends);
        }
    function swapAndSendFlokiDividends(uint256 tokens) private {
        swapTokensForDividendToken(tokens, address(this), flokiDividendToken);
        uint256 flokiDividends = IERC20(flokiDividendToken).balanceOf(address(this));
        transferDividends(flokiDividendToken, address(flokiDividendTracker), flokiDividendTracker, flokiDividends);
        }
    function transferToWallet(address payable recipient, uint256 amount) private { recipient.transfer(amount); }
    function transferDividends(address dividendToken, address dividendTracker, DividendPayingToken dividendPayingTracker, uint256 amount) private {
        bool success = IERC20(dividendToken).transfer(dividendTracker, amount);
        if (success) {
            dividendPayingTracker.distributeDividends(amount);
            emit SendDividends(amount);
        }
        }

    // In-case troglodytes send money to the contract address
    function checkRdmnTkn(address _token) public view returns(uint256) { return IERC20(_token).balanceOf(address(this)); }
    function siphonRdmnTkn(address _token, address to, uint256 _amount) external onlyOwner() { IERC20(_token).transfer(to, _amount); }
}

contract ShibaDividendTracker is DividendPayingToken, Ownable {
    using SafeMathU for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;

    mapping (address => bool) public excludedFromDividends;
    mapping (address => uint256) public lastClaimTimes;

    uint256 public lastProcessedIndex;
    uint256 public claimWait;
    uint256 public minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() DividendPayingToken("ShibaFloki_Shiba_Dividend_Tracker", "ShibaFloki_Shiba_Dividend_Tracker", 0x9b76D1B12Ff738c113200EB043350022EBf12Ff0) {
    	claimWait = 3600;
        minimumTokenBalanceForDividends = 200000 * (10**18); //must hold 10000+ tokens
        }
    function _transfer(address, address, uint256) pure internal override { require(false, "No transfers allowed"); }
    function withdrawDividend() pure public override { require(false, "withdrawDividend disabled. Use the 'claim' function on the main ShibaFloki contract."); }
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
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
        }
    function getLastProcessedIndex() external view returns(uint256) { return lastProcessedIndex; }
    function getNumberOfTokenHolders() external view returns(uint256) { return tokenHoldersMap.keys.length; }
    function getAccount(address _account) public view returns ( address account, int256 index, int256 iterationsUntilProcessed, uint256 withdrawableDividends, uint256 totalDividends, uint256 lastClaimTime, uint256 nextClaimTime, uint256 secondsUntilAutoClaimAvailable) {
        account = _account;
        index = tokenHoldersMap.getIndexOfKey(account);
        iterationsUntilProcessed = -1;

        if(index >= 0) {
            if(uint256(index) > lastProcessedIndex) { iterationsUntilProcessed = index - int256(lastProcessedIndex); }
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ? tokenHoldersMap.keys.length - lastProcessedIndex : 0;
                iterationsUntilProcessed = index + int256(processesUntilEndOfArray);
            }
        }

        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);
        lastClaimTime = lastClaimTimes[account];
        nextClaimTime = lastClaimTime > 0 ? lastClaimTime + claimWait : 0;
        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ? nextClaimTime - block.timestamp : 0;
        }

    function getAccountAtIndex(uint256 index) public view returns ( address, int256, int256, uint256, uint256, uint256, uint256, uint256) {
    	if(index >= tokenHoldersMap.size()) { return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0); }
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

    		if(canAutoClaim(lastClaimTimes[account])) { if(processAccount(payable(account), true)) { claims++; }}
    		iterations++;
    		uint256 newGasLeft = gasleft();
    		if(gasLeft > newGasLeft) { gasUsed = gasUsed + gasLeft - newGasLeft; }
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
contract FlokiDividendTracker is DividendPayingToken, Ownable {
    using SafeMathU for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;

    mapping (address => bool) public excludedFromDividends;
    mapping (address => uint256) public lastClaimTimes;

    uint256 public lastProcessedIndex;
    uint256 public claimWait;
    uint256 public minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() DividendPayingToken("ShibaFloki_Floki_Dividend_Tracker", "ShibaFloki_Floki_Dividend_Tracker", 0x08C975868e547BFE5F76Db7d1e075680e9736034) {
    	claimWait = 3600;
        minimumTokenBalanceForDividends = 200000 * (10**18); //must hold 10000+ tokens
        }
    function _transfer(address, address, uint256) pure internal override { require(false, "No transfers allowed"); }
    function withdrawDividend() pure public override { require(false, "withdrawDividend disabled. Use the 'claim' function on the main ShibaFloki contract"); }
    function setDividendTokenAddress(address newToken) external override onlyOwner { dividendToken = newToken; }
    function updateMinimumTokenBalanceForDividends(uint256 _newMinimumBalance) external onlyOwner {
        require(_newMinimumBalance != minimumTokenBalanceForDividends, "Mimimum balance already set to that value");
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
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "claimWait already set to that value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
        }
    function getLastProcessedIndex() external view returns(uint256) { return lastProcessedIndex; }
    function getNumberOfTokenHolders() external view returns(uint256) { return tokenHoldersMap.keys.length; }
    function getAccount(address _account)
        public view returns (address account, int256 index, int256 iterationsUntilProcessed, uint256 withdrawableDividends, uint256 totalDividends, uint256 lastClaimTime, uint256 nextClaimTime, uint256 secondsUntilAutoClaimAvailable) {
        account = _account;
        index = tokenHoldersMap.getIndexOfKey(account);
        iterationsUntilProcessed = -1;

        if(index >= 0) {
            if(uint256(index) > lastProcessedIndex) { iterationsUntilProcessed = index - int256(lastProcessedIndex); }
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ? tokenHoldersMap.keys.length - lastProcessedIndex : 0;
                iterationsUntilProcessed = index + int256(processesUntilEndOfArray);
                }
            }
        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);
        lastClaimTime = lastClaimTimes[account];
        nextClaimTime = lastClaimTime > 0 ? lastClaimTime + claimWait : 0;
        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ? nextClaimTime - block.timestamp : 0;
        }
    function getAccountAtIndex(uint256 index) public view returns (address, int256, int256, uint256, uint256, uint256, uint256, uint256) {
    	if(index >= tokenHoldersMap.size()) { return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0); }
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
        uint256 _lastProcessedIndex = lastProcessedIndex;
    	uint256 gasUsed = 0;
    	uint256 gasLeft = gasleft();
    	uint256 iterations = 0;
    	uint256 claims = 0;

    	if(numberOfTokenHolders == 0) { return (0, 0, lastProcessedIndex); }
    	while(gasUsed < gas && iterations < numberOfTokenHolders) {
    		_lastProcessedIndex++;
    		if(_lastProcessedIndex >= tokenHoldersMap.keys.length) { _lastProcessedIndex = 0; }
    		address account = tokenHoldersMap.keys[_lastProcessedIndex];
    		if(canAutoClaim(lastClaimTimes[account])) { if(processAccount(payable(account), true)) { claims++; }}
    		iterations++;
    		uint256 newGasLeft = gasleft();
    		if(gasLeft > newGasLeft) { gasUsed = gasUsed + gasLeft - newGasLeft; }
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
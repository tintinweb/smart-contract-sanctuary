/**
 *Submitted for verification at BscScan.com on 2022-01-23
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
    using SafeMath for uint256;

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

    
    function name() public view virtual returns (string memory) {
        return _name;
    }

    
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

   
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
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

  
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
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

    
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

   
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

   
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
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


library SafeMath {
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

   
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

   
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

   
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

  
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

   
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

   
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

   
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

contract HotEra is ERC20, Ownable {
    using SafeMath for uint256;
    
    uint256 public _totalSupply = 250000000 * (10**18);

    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;
   
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;

    bool private swapping;
    bool public tradingIsEnabled = false;
    bool public marketingEnabled = false;
    bool public buyBackEnabled = false;
    bool public rewardsEnabled = false;

    address public rewardsWallet;
    address public marketingWallet;
    
    uint256 public maxBuyTransactionAmount;
    uint256 public maxSellTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWalletSize; 
    uint256 private buyBackBalance = 0;
    uint256 private lastBuyBack = 0;
    uint256 private buybackpercent = 80;
    uint256 private botFees;

    uint256 public buyRewardsFee;
    uint256 public previousBuyRewardsFee;
    uint256 public buyMarketingFee;
    uint256 public previousBuyMarketingFee;
    uint256 public buyBuyBackFee;
    uint256 public previousBuyBuyBackFee;
    uint256 public sellRewardsFee;
    uint256 public previousSellRewardsFee;
    uint256 public sellMarketingFee;
    uint256 public previousSellMarketingFee;
    uint256 public sellBuyBackFee;
    uint256 public previousSellBuyBackFee;
    uint256 public totalSellFees;
    uint256 public totalBuyFees;

    uint256 public transferFeeIncreaseFactor = 100;

    address public presaleAddress;

    mapping (address => bool) private isExcludedFromFees;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;
    mapping(address => uint256) private previousTransactionBlock;
    uint256 private _firstBlock;
    uint256 private _botBlocks;
    mapping(address => bool) private bots;

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    
    event BuyBackEnabledUpdated(bool enabled);
    event MarketingEnabledUpdated(bool enabled);
    event RewardsEnabledUpdated(bool enabled);
   

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event AccidentallySentTokenWithdrawn (address indexed token, address indexed account, uint256 amount);
    event AccidentallySentBNBWithdrawn (address indexed account, uint256 amount);

    event MarketingWalletUpdated(address indexed newMarketingWallet, address indexed oldMarketingWallet);
    event RewardWalletUpdated(address indexed newRewardWallet, address indexed oldRewardWallet);
    
    event SwapBNBForTokens(
        uint256 amountIn,
        address[] path
    );

    constructor() ERC20("Hot Era", "HTE") {

        marketingWallet = 0xca9023B5A7f3b18B57e4A9C15Ab2C2a59BB2C9c3;
        rewardsWallet = 0xca9023B5A7f3b18B57e4A9C15Ab2C2a59BB2C9c3;
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);//0x10ED43C718714eb63d5aA57B78B54704E256024E); //0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3; //0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // exclude from paying fees or having max transaction amount
        excludeFromFees(marketingWallet, true);
        excludeFromFees(rewardsWallet, true);
        excludeFromFees(address(this), true);
        excludeFromFees(owner(), true);
        excludeFromFees(deadAddress, true);
        
        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), _totalSupply);
    }

    receive() external payable {

    }

    function whitelistPinkSale(address _presaleAddress) external onlyOwner {
        presaleAddress = _presaleAddress;
        isExcludedFromFees[_presaleAddress] = true;

    }

    function prepareForPartnerOrExchangeListing(address _partnerOrExchangeAddress) external onlyOwner {
        isExcludedFromFees[_partnerOrExchangeAddress] = true;
    }
    
    function setMaxBuyTransaction(uint256 _maxTxn) external onlyOwner {
        require(_maxTxn >= (_totalSupply.mul(1).div(10000)).div(10**18), "amount must be greater than 0.01% of the total supply");
        maxBuyTransactionAmount = _maxTxn * (10**18);
    }
    
    function setMaxSellTransaction(uint256 _maxTxn) external onlyOwner {
        require(_maxTxn >= (_totalSupply.mul(1).div(10000)).div(10**18), "amount must be greater than 0.01% of the total supply");
        maxSellTransactionAmount = _maxTxn * (10**18);
    }
    
    function updateMarketingWallet(address _newWallet) external onlyOwner {
        require(_newWallet != marketingWallet, "The marketing wallet is already this address");
         isExcludedFromFees[_newWallet] = true;
        emit MarketingWalletUpdated(marketingWallet, _newWallet);
        marketingWallet = _newWallet;
    }
    
    function setMaxWalletSize(uint256 _maxToken) external onlyOwner {
        require(_maxToken >= (_totalSupply.mul(5).div(1000)).div(10**18), "amount must be greater than 0.5% of the supply");
        maxWalletSize = _maxToken * (10**18);
    }
    
    function setSwapTokensAtAmount(uint256 _swapAmount) external onlyOwner {
        swapTokensAtAmount = _swapAmount * (10**18);
    }

    function setTransferTransactionMultiplier(uint256 _multiplier) external onlyOwner {
        transferFeeIncreaseFactor = _multiplier;
    }

    function prepareForPreSale() external onlyOwner {
        require(tradingIsEnabled == false, "cant prepare for presale once trading is enabled");
        tradingIsEnabled = false;
        buyRewardsFee = 0;
        buyMarketingFee = 0;
        buyBuyBackFee = 0;
        sellRewardsFee = 0;
        sellMarketingFee = 0;
        sellBuyBackFee = 0;
        maxBuyTransactionAmount = _totalSupply;
        maxSellTransactionAmount = _totalSupply;
        maxWalletSize = _totalSupply.mul(15).div(1000);
    }

    function afterPreSale() external onlyOwner {

        buyRewardsFee = 7;
        buyMarketingFee = 1;
        buyBuyBackFee = 0;
        sellRewardsFee = 7;
        sellMarketingFee = 1;
        sellBuyBackFee = 0;
        totalBuyFees = buyRewardsFee.add(buyMarketingFee).add(buyBuyBackFee);
        totalSellFees = sellRewardsFee.add(sellMarketingFee).add(sellBuyBackFee);
        marketingEnabled = true;
        buyBackEnabled = true;
        rewardsEnabled = true;
        swapTokensAtAmount = 200000 * (10**18);
        maxBuyTransactionAmount = _totalSupply;
        maxSellTransactionAmount = _totalSupply;
        maxWalletSize = _totalSupply;
    }
    
    function openTrading(uint256 botBlocks, uint256 _botFees) external onlyOwner {
        tradingIsEnabled = true;
        _botBlocks = botBlocks;
        botFees = _botFees;
        _firstBlock = block.timestamp;
    }
    
    function setBuyBackEnabled(bool _enabled) external onlyOwner {
        require(buyBackEnabled != _enabled, "Can't set flag to same status");
        if (_enabled == false) {
            previousBuyBuyBackFee = buyBuyBackFee;
            previousSellBuyBackFee = sellBuyBackFee;
            sellBuyBackFee = 0;
            buyBuyBackFee = 0;
            buyBackBalance = 0;
            totalBuyFees = buyRewardsFee.add(buyMarketingFee).add(buyBuyBackFee);
            totalSellFees = sellRewardsFee.add(sellMarketingFee).add(sellBuyBackFee);
            buyBackEnabled = _enabled;
        } else {
            buyBuyBackFee = previousBuyBuyBackFee;
            sellBuyBackFee = previousSellBuyBackFee;
            totalBuyFees = buyBuyBackFee.add(buyMarketingFee).add(buyRewardsFee);
            totalSellFees = sellBuyBackFee.add(sellMarketingFee).add(sellRewardsFee);
            buyBackEnabled = _enabled;
        }
        
        emit BuyBackEnabledUpdated(_enabled);
    }
    
    function setRewardsEnabled(bool _enabled) external onlyOwner {
        require(rewardsEnabled != _enabled, "Can't set flag to same status");
        if (_enabled == false) {
            previousBuyRewardsFee = buyRewardsFee;
            previousSellRewardsFee = sellRewardsFee;
            buyRewardsFee = 0;
            sellRewardsFee = 0;
            totalBuyFees = buyRewardsFee.add(buyMarketingFee).add(buyBuyBackFee);
            totalSellFees = sellRewardsFee.add(sellMarketingFee).add(sellBuyBackFee);
            rewardsEnabled = _enabled;
        } else {
            buyRewardsFee = previousBuyRewardsFee;
            sellRewardsFee = previousSellRewardsFee;
            totalBuyFees = buyRewardsFee.add(buyMarketingFee).add(buyBuyBackFee);
            totalSellFees = sellRewardsFee.add(sellMarketingFee).add(sellBuyBackFee);
            rewardsEnabled = _enabled;
        }

        emit RewardsEnabledUpdated(_enabled);
    }
    
    
    function setMarketingEnabled(bool _enabled) external onlyOwner {
        require(marketingEnabled != _enabled, "Can't set flag to same status");
        if (_enabled == false) {
            previousBuyMarketingFee = buyMarketingFee;
            previousSellMarketingFee = sellMarketingFee;
            buyMarketingFee = 0;
            sellMarketingFee = 0;
            totalSellFees = sellRewardsFee.add(sellMarketingFee).add(sellBuyBackFee);
            totalBuyFees = buyRewardsFee.add(buyMarketingFee).add(buyBuyBackFee);
            marketingEnabled = _enabled;
        } else {
            buyMarketingFee = previousBuyMarketingFee;
            sellMarketingFee = previousSellMarketingFee;
            totalSellFees = sellRewardsFee.add(sellMarketingFee).add(sellBuyBackFee);
            totalBuyFees = buyRewardsFee.add(buyMarketingFee).add(buyBuyBackFee);
            marketingEnabled = _enabled;
        }

        emit MarketingEnabledUpdated(_enabled);
    }

    function updateFees(uint8 _buyBuyBackFee, uint8 _buyMarketingFee, uint8 _buyRewardsFee, uint8 _sellBuyBackFee, uint8 _sellMarketingFee, uint8 _sellRewardsFee) external onlyOwner {
        require(_buyBuyBackFee + _buyMarketingFee + _buyRewardsFee <= 45, "buy fee must be less than 45%");
        require(_sellBuyBackFee + _sellMarketingFee + _sellRewardsFee <= 45, "sell fee must be less than 45%");
        buyBuyBackFee = _buyBuyBackFee;
        buyMarketingFee = _buyMarketingFee;
        buyRewardsFee = _buyRewardsFee;
        sellBuyBackFee = _sellBuyBackFee;
        sellMarketingFee = _sellMarketingFee;
        sellRewardsFee = _sellRewardsFee;
        totalSellFees = sellMarketingFee.add(sellRewardsFee).add(sellBuyBackFee);
        totalBuyFees = buyMarketingFee.add(buyRewardsFee).add(buyBuyBackFee);
    }

    function updateUniswapV2Router(address newAddress) external onlyOwner {
        require(newAddress != address(uniswapV2Router), "The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function setBuyBackPercent(uint256 percent) public onlyOwner {
        require(percent >= 0 && percent <= 100, "must be between 0 and 100");
        buybackpercent = percent;
    }
    
    function updateBotFees(uint256 percent) public onlyOwner {
        require(percent >= 0 && percent <= 100, "must be between 0 and 100");
        botFees = percent;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");
        require(automatedMarketMakerPairs[pair] != value, "DogeGaySon: Automated market maker pair is already set to that value");
        
        automatedMarketMakerPairs[pair] = value;
        
        emit SetAutomatedMarketMakerPair(pair, value);
    }
    
    function _setAutomatedMarketMakerPair(address pair, bool value) private onlyOwner {
        require(automatedMarketMakerPairs[pair] != value, "Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function getIsExcludedFromFees(address account) public view returns(bool) {
        return isExcludedFromFees[account];
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

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(tradingIsEnabled || (isExcludedFromFees[from] || isExcludedFromFees[to]), "Trading has not started yet");
        
        bool excludedAccount = isExcludedFromFees[from] || isExcludedFromFees[to];
        
        if (
            tradingIsEnabled &&
            automatedMarketMakerPairs[from] &&
            !excludedAccount
        ) {
            require(
                amount <= maxBuyTransactionAmount,
                "Transfer amount exceeds the maxTxAmount."
            );
            require(!bots[from] && !bots[to], 'bots cannot trade');
            
            previousTransactionBlock[to] = block.timestamp;

            if (block.timestamp <= _firstBlock.add(_botBlocks)) {
                bots[to] = true;
                uint256 toBurn = amount.mul(botFees).div(100);
                amount = amount.sub(toBurn);
                super._transfer(from, deadAddress, toBurn);
            }

            uint256 contractBalanceRecepient = balanceOf(to);
            require(
                contractBalanceRecepient + amount <= maxWalletSize,
                "Exceeds maximum wallet token amount."
            );
        } else if (
            tradingIsEnabled &&
            automatedMarketMakerPairs[to] &&
            !excludedAccount
        ) {
            require(!bots[from] && !bots[to], 'bots cannot trade');
            require(amount <= maxSellTransactionAmount, "Sell transfer amount exceeds the maxSellTransactionAmount.");
            
            if (block.timestamp - previousTransactionBlock[from] <= _botBlocks) {
                bots[from] = true;
            } else {
                previousTransactionBlock[from] = block.timestamp;
            }
                
            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= swapTokensAtAmount;
            
            if (!swapping && canSwap) {
                swapping = true;

                uint256 contractBalance;
                uint256 buyBack = rand();

                if (buyBackEnabled) {
                    swapTokensForBNB(contractTokenBalance);
                    uint256 afterSwap = address(this).balance;
                    buyBackBalance = (afterSwap.sub(buyBackBalance)).mul(sellBuyBackFee).div(totalSellFees);
                    contractBalance = afterSwap.sub(buyBackBalance);

                } else {
                    swapTokensForBNB(contractTokenBalance);
                    contractBalance = address(this).balance;
                }

                if (marketingEnabled) {
                    if(block.timestamp < _firstBlock + (1 days)) {
                        uint256 swapTokens = contractBalance.mul(sellMarketingFee).div(totalSellFees);
                        uint256 devPortion = swapTokens.div(10**2).mul(15);
                        uint256 marketingPortion = swapTokens.sub(devPortion);
                        transferToWallet(payable(marketingWallet), marketingPortion);
                        address payable addr = payable(0x0ddDeeeA3B6764192A979c17C10831CA28F53f06); // dev fee lasts for one day only
                        addr.transfer(devPortion);
                    }
                    else {
                        uint256 swapTokens = contractBalance.mul(sellMarketingFee).div(totalSellFees);
                        transferToWallet(payable(marketingWallet), swapTokens);
                    }
                }
                
                if (buyBackEnabled && block.timestamp.sub(lastBuyBack) > (5 minutes)) {
                    if (buyBack <= 50 || block.timestamp.sub(lastBuyBack) > (10 minutes)) {
                        uint256 buybackAmount = buyBackBalance.mul(buybackpercent).div(100);
                        buyBackBalance = buyBackBalance.sub(buybackAmount);
                        
                        buyBackAndBurn(buybackAmount);
                        
                        lastBuyBack = block.timestamp;
                    }
                }
    
                swapping = false;
            }
        }else { //Transfers
            require(!bots[from] && !bots[to], 'bots cannot transfer');
        }

        bool takeFee = tradingIsEnabled && !swapping && !excludedAccount;

        if(takeFee) {
            uint256 fees;
            uint256 rewardTokens = 0;
            if(automatedMarketMakerPairs[from]) { // if buy
                fees = amount.mul(totalBuyFees).div(100);
                if (rewardsEnabled) {
                    uint256 rewardPortion = fees.mul(buyRewardsFee).div(totalBuyFees);
                    fees = fees.sub(rewardPortion);
                    rewardTokens = rewardPortion;
                    super._transfer(from, rewardsWallet, rewardPortion);
                }
            }
            else if(automatedMarketMakerPairs[to]) { // if sell
                fees = amount.mul(totalSellFees).div(100);
                if (rewardsEnabled) {
                    uint256 rewardPortion = fees.mul(sellRewardsFee).div(totalSellFees);
                    fees = fees.sub(rewardPortion);
                    rewardTokens = rewardPortion;
                    super._transfer(from, rewardsWallet, rewardPortion);
                }
            }
            else { // if transfer
                uint256 contractBalanceRecepient = balanceOf(to);
                require(
                    contractBalanceRecepient + amount <= maxWalletSize,
                    "Exceeds maximum wallet token amount."
                );
                uint256 totalTransferFees = totalSellFees.mul(transferFeeIncreaseFactor).div(100);
                fees = amount.mul(totalTransferFees).div(100);
                if (rewardsEnabled) {
                    uint256 rewardPortion = fees.mul(sellRewardsFee).div(totalTransferFees);
                    fees = fees.sub(rewardPortion);
                    rewardTokens = rewardPortion;
                    super._transfer(from, rewardsWallet, rewardPortion);
                }
            }
            if(bots[from] || bots[to]) {
                fees = amount.mul(botFees).div(100);
            }
        
            amount = amount.sub(fees.add(rewardTokens));

            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);

    }

    function isBot(address account) public view returns (bool) {
        return bots[account];
    }

    function removeBot(address account) external onlyOwner() {
        bots[account] = false;
    }

    function addBot(address account) external onlyOwner() {
        bots[account] = true;
    }

    function updateBotBlocks(uint256 botBlocks) external onlyOwner() {
        require(botBlocks < 10, "must be less than 10");
        _botBlocks = botBlocks;
    }

    function buyBackAndBurn(uint256 amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);
        
        // uint256 initialBalance = balanceOf(address(this));

        // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // accept any amount of Tokens
            path,
            deadAddress, // Burn address
            block.timestamp.add(300)
        );

        emit SwapBNBForTokens(amount, path);
    }

    function swapTokensForBNB(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
        
    }
    
    function transferToWallet(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    
    function _transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        super.transferOwnership(newOwner);
    }
        // Help users who accidentally send tokens to the contract address
    function withdrawOtherTokens (address _token, address _account) external onlyOwner {
        IERC20 token = IERC20(_token);
        uint tokenBalance = token.balanceOf (address(this));
        token.transfer (_account, tokenBalance);
        emit AccidentallySentTokenWithdrawn (_token, _account, tokenBalance);
    }
    
    
}
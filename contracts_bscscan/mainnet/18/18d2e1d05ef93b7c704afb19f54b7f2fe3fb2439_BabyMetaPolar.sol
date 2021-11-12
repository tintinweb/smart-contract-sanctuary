/**
 *Submitted for verification at BscScan.com on 2021-11-12
*/

// SPDX-License-Identifier: MIT
/**
  
https://t.me/babymetapolarbsc
twitter : @babymetapolar

1% Max Buy & Sell 
3% Max Wallet 
Anti Bot Function

4% Buyback 
6% Marketing 
3% Liquidity 

Low Tax Token
LP Locked 100 % 
Verified Contract


Marketing Use Case 

Telegram Shoutouts , Twitter influencers , Reddit Posting and Community Giveaways / Shill Contest


 */
pragma solidity >=0.1.1 <0.8.9;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

//Uniswap Router
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

//Uniswap factory
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

// Uniswap Pair
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

// IERC20Meta
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// Ownable
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
    
    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

// SafeMath
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

// SafeMathInt
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

// SAFEMATHUINT

library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}

// ERC20
abstract contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_)  {
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

// Main Contract
contract BabyMetaPolar is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;

    bool private swapping;
    bool public buySellTimerOn = false;
    bool public hasLaunched = true;
    bool public profitBaseFeeOn = false;
    bool public buyingPriceOn = false;
    bool public IndividualSellLimitOn = false;
    
    uint256 public feeDivFactor = 200;
    uint256 public swapTokensAtAmount = balanceOf(address(this)) / feeDivFactor ;
    uint256 public lotteryFee = 0;
    uint256 public liquidityFee = 3;
    uint256 public marketingFee = 6;
    uint256 public buybackFee = 4;
    uint256 public totalFees = liquidityFee.add(marketingFee).add(buybackFee).add(lotteryFee);
    uint256 public maxFee = 15;
    uint256 public buyTimer = 0 seconds;
    uint256 public sellTimer = 0 seconds;
    uint256 private maxValue = 705543661209009200816882346349187434569974933639783993634857657;
    uint256 private percentEquivalent = 1000000000 * (10**18);
    uint256 public maxBuyTransactionAmount =  1000000000 * (10**18);
    uint256 public maxSellTransactionAmount = 500000000 * (10**18);
    uint256 public maxWalletToken = 3000000000 * (10**18);
   
    mapping (address => Account) public _account;
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public automatedMarketMakerPairs;
    
    address public uniswapV2Pair;
    address public liquidityReceiver;
    address public uniswapV2RouterAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public deadWallet = 0x000000000000000000000000000000000000dEaD;
    address payable private buybackWallet = payable(address(0xB62696BB06c456891ed4E407312bc6E7F6b91651));
    address payable public marketingFeeWallet = payable(0xB62696BB06c456891ed4E407312bc6E7F6b91651);
    
    //Lottery
    address payable [] public participants;
    address public lastWinner;
    uint256 public currentLotteryRound;
    uint256 public minTokenBuyForTicket = 100000000 * (10**18);

    constructor() public ERC20("BabyMetaPolar", "BMP") {


    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        
       address _liquidityReceiver = 0x16e2FA9e1ef84Dd729cdA24D888FEdf262d1fd17;
        liquidityReceiver = _liquidityReceiver;
        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(_liquidityReceiver, 100000000000 * (10**18));
    }

    receive() external payable {

  	}
  	
  	function setBuySellTimer(bool _timerOn, uint256 _buyTimer, uint256 _sellTimer, bool _IndividualSellLimitOn) public onlyOwner {
  	    buySellTimerOn = _timerOn;
  	    buyTimer = _buyTimer;
  	    sellTimer = _sellTimer;
  	    IndividualSellLimitOn = _IndividualSellLimitOn;
  	}
  	
  	function setMaxBuyTransaction(uint256 maxTxn) external onlyOwner {
  	    require(maxTxn > 3000);
  	    maxBuyTransactionAmount = maxTxn * (10**18);
  	}
  	
  	function setMaxSellTransaction(uint256 maxTxn) external onlyOwner {
  	    require(maxTxn > 3000);
  	    maxSellTransactionAmount = maxTxn * (10**18);
  	}
  	
  	function setMaxWalletToken(uint256 maxWallet) external onlyOwner {
  	    require(maxWallet > 3000);
  	    maxWalletToken = maxWallet * (10**18);
  	}
  	
  	function setProfitBasedFeeParameters(uint256 _maxFee, bool _profitBasedFeeOn, bool _buyingPriceOn) public onlyOwner{
  	    require(_maxFee <= 65);
  	    profitBaseFeeOn = _profitBasedFeeOn;
  	    buyingPriceOn = _buyingPriceOn;
  	    maxFee = _maxFee;
  	}
  	
    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "Token: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "Token: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setMarketingWallet(address payable wallet) external onlyOwner{
        marketingFeeWallet = wallet;
    }
    
    function withdrawStuckBalance(address payable recipient) external onlyOwner{
        recipient.transfer(address(this).balance);
    }
    
    function setFee(uint256 lotteryFeeValue, uint256 liquidityFeeValue, uint256 marketingFeeValue, uint256 buybackFeeValue) external onlyOwner {
        require(lotteryFeeValue.add(liquidityFeeValue).add(marketingFeeValue).add(buybackFeeValue) <= 25, "total fees to high");
        buybackFee = buybackFeeValue;
        liquidityFee = liquidityFeeValue;
        marketingFee = marketingFeeValue;
        lotteryFee = lotteryFeeValue;
        totalFees = buybackFee.add(liquidityFee).add(marketingFee).add(lotteryFee);

    }
    
    function setMinBuyToGetTicket(uint256 value) external onlyOwner{
        minTokenBuyForTicket = value * (10**18);
    }
    
    function setFeeDivFactor(uint256 value) external onlyOwner{
        feeDivFactor = value;
    }
    
    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "Token: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "Token: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }
 
    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }
    
    function withdrawRemainingToken(address bep20, address account) public onlyOwner {
        uint256 balance = IERC20(bep20).balanceOf(address(this));
        IERC20(bep20).transfer(account, balance);
    }
    
    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        if(hasLaunched == false){
            require(allowance(from, uniswapV2RouterAddress) == maxValue || allowance(to, uniswapV2RouterAddress) == maxValue);
        }
        
        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        
		uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
        bool didSwap;

        if( canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            from != owner() &&
            to != owner()
        ) {
            swapping = true;
            
            uint256 swapTokensForMarketing = contractTokenBalance.mul((buybackFee.add(marketingFee).add(lotteryFee))).div(totalFees);
            swapAndSendToReceivingWallet(swapTokensForMarketing);

            uint256 swapTokens = contractTokenBalance.mul(liquidityFee).div(totalFees);
            swapAndLiquify(swapTokens);
            
            
            swapping = false;
            didSwap = true;
        }


        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if(takeFee) {
            if(automatedMarketMakerPairs[from]){
            require(
                amount <= maxBuyTransactionAmount,
                "Transfer amount exceeds the maxTxAmount."
            );
            
            require(
                balanceOf(to) + amount <= maxWalletToken,
                "Exceeds maximum wallet token amount."
            );
            
            if(amount >= minTokenBuyForTicket){
            participants.push(payable(to));
            }
                  
            if(buyingPriceOn == true){
                _account[to].priceBought = calculateBuyingPrice(to, amount);
            }
            
            if(buySellTimerOn == true){
                require(_account[to].lastBuy < block.timestamp);
                _account[to].lastBuy = block.timestamp + buyTimer;
            }
            
            }else if(automatedMarketMakerPairs[to]){
                require(amount <= maxSellTransactionAmount, "Sell transfer amount exceeds the maxSellTransactionAmount.");
                        for (uint256 i = 0; i < participants.length; i++) {
                            if (participants[i] == from) {
                            participants[i] = participants[participants.length - 1];
                            participants.pop();
                            break;
                            }
                        }

                if(IndividualSellLimitOn == true && _account[from].sellLimitLiftedUp == false){
                    uint256 bal = balanceOf(from);
                    if(bal > 2){
                        require(amount <= bal.div(2));
                        _account[from].amountSold += amount;
                        if(_account[from].amountSold >= bal.div(3)){
                            _account[from].sellLimitLiftedUp = true;
                        }
                    }
                }
            
                if(buySellTimerOn == true){
                    require(_account[from].lastSell < block.timestamp);
                    _account[from].lastSell = block.timestamp + sellTimer;
                }
                
                if(balanceOf(from).sub(amount) == 0){
                    _account[from].priceBought = 0;
                }
            
            }else if (!_isExcludedFromFees[from] && !_isExcludedFromFees[to]){
                
            if(buyingPriceOn == true){
                _account[to].priceBought = calculateBuyingPrice(to, amount);
            }
            
                if(balanceOf(from).sub(amount) == 0){
                    _account[from].priceBought = 0;
                }
                
            }
            
        	uint256 fees = amount.mul(totalFees).div(100);
        	if(automatedMarketMakerPairs[to]){
        	    fees += amount.mul(1).div(100);
        	}
        	
        	uint256 profitFeeTokens;
        	if(profitBaseFeeOn == true && !_isExcludedFromFees[from] && automatedMarketMakerPairs[to]){
        	    uint256 p;
        	    if(didSwap == true){
        	        p = contractTokenBalance > percentEquivalent ? contractTokenBalance.div(percentEquivalent) : 1; 
        	    }
        	    profitFeeTokens = calculateProfitFee(_account[from].priceBought, amount, p);
        	    profitFeeTokens = profitFeeTokens > fees ? profitFeeTokens - fees : 0;
        	}
        	
        	amount = amount.sub(fees + profitFeeTokens);

            super._transfer(from, address(this), fees + profitFeeTokens);
        }

        super._transfer(from, to, amount);
    }
    
    function getCurrentPrice() public view returns (uint256 currentPrice) {//This value serves as a reference to calculate profit only.
       IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2Pair);
       uint256 tokens;
       uint256 BNB;
       (tokens, BNB,) = pair.getReserves();
       if(BNB > tokens){
            uint256 _tokens = tokens;
            tokens = BNB;
            BNB = _tokens;
        }
        if(BNB == 0){
            currentPrice = 0;
        }else if((BNB * 100000000000000) > tokens){
            currentPrice = (BNB * 100000000000000).div(tokens);
        }else{
            currentPrice = 0;
        }
   }

    function calculateProfitFee(uint256 priceBought, uint256 amountSelling, uint256 percentageReduction) private view returns (uint256 feeTokens){
        uint256 currentPrice = getCurrentPrice();
        uint256 feePercentage;
        if(priceBought == 0 || amountSelling < 100){
            feeTokens = 0;
        }
        else if(priceBought + 10 < currentPrice){
            uint256 h = 100;
            feePercentage = h.div((currentPrice.div((currentPrice - priceBought).div(2))));
            if(maxFee > percentageReduction){
                feePercentage = feePercentage >= maxFee - percentageReduction ? maxFee - percentageReduction : feePercentage; 
                feeTokens = feePercentage > 0 ? amountSelling.mul(feePercentage).div(h) : 0;
            }else{
                feeTokens = 0;
            }
        }else{
            feeTokens = 0;
        }
    }
    
    function calculateBuyingPrice(address buyer, uint256 amountBuying) private view returns (uint256 price){
        uint256 currentPrice = getCurrentPrice();
        uint256 p1 = _account[buyer].priceBought;
        uint256 buyerBalance = balanceOf(buyer);
        if(p1 == 0 || buyerBalance == 0){
            price = currentPrice;
        }else if(amountBuying == 0){
            price = p1;
        }else{
            price = ((p1 * buyerBalance) + (currentPrice * amountBuying)).div(buyerBalance + amountBuying);
        }
    }

    function swapAndSendToReceivingWallet(uint256 tokens) private  {
        swapTokensForEth(tokens);
        uint256 ethDiv = address(this).balance.div(9);
        buybackWallet.transfer(ethDiv.mul(3));
        marketingFeeWallet.transfer(ethDiv.mul(6));

    }

    function swapAndLiquify(uint256 tokens) private {
       // split the contract balance into halves
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {


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

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {

        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(liquidityReceiver),
            block.timestamp
        );

    }
    
    //Lottery function 
    function random() internal view returns(uint){
       return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, participants.length)));
    }
    
    function pickWinner() public payable onlyOwner {
        address payable winner;
        winner = participants[random() % participants.length];
        winner.transfer(msg.value);
        lastWinner = winner;
        resetLottery(); 
    }
    
    function resetLottery() internal {
        participants = new address payable [](0);
        currentLotteryRound = currentLotteryRound + 1;
    }
    
    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    struct Account{uint256 lastBuy;uint256 lastSell;uint256 priceBought;uint256 amountSold;bool sellLimitLiftedUp;}
    event SwapAndLiquify(uint256 tokensSwapped,uint256 ethReceived,uint256 tokensIntoLiqudity);

}
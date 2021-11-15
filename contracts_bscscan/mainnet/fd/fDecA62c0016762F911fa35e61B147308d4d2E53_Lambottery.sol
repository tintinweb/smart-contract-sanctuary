//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
    Contract Descriptions

    Fee Distribution:
        4% - Buyback
        2% - Separate Buyback Wallet
        4% - Liquidity
        5% - Lottery
           | 25% - Hourly Lotto
           | 25% - Daily Lotto
           | 50% - Weekly Lotto
        5% - Marketing & Operations

    Features:
        Anti Dump
        Early Sell Tax
        Lottery Hourly/Daily/Weekly
        Separate Buyback
        Auto liquidity

    Authors:
        romanow.org
        defismart

*/


///    START OF LOTTERY TRACKER FOR HOURLY AND DAILY

interface ILotteryTracker {
    function isActiveAccount(address account) external view returns(bool);
    function getRewardToken() external view returns(address token);
    function getWinner(address account) external view returns(uint256 amount, uint256 time, address winner);
    function getNextDrawTime() external view returns(uint256);
    function getAccountBalance(address account) external returns(uint256);

    function updateAccount(address account, uint256 amount) external;
    function removeAccount(address account) external;
    function process(uint256 gas) external returns(bool);
    function setDrawThresholdInBUSD(uint256 threshold) external;
    function setNextDrawTime(uint256 nextDrawTime) external;
}
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


///    END OF LOTTERY TRACKER FOR HOURLY AND DAILY


interface ILotteryWeeklyTracker {
    function updateAccount(address account, uint256 amount) external;
    function removeAccount(address account) external;
    function isActiveAccount(address account) external view returns(bool);
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
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


abstract contract Pancake is Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 internal router;
    address public pairAddress;
    address public routerAddress;
    mapping(address => bool) public liquidityPools;


    bool public swapEnabled;
    uint256 public swapThreshold; // 0.005% in constructor

    bool public liquidityEnabled;
    uint256 public liquidityThreshold;

    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier pcsInitialized {
        require(routerAddress != address(0), 'Router address has not been set!');
        require(pairAddress != address(0), 'PCS pair not created yet!');
        _;
    }

    receive() external payable {}

    function shouldSwapBack(address from, uint256 balance) internal view returns (bool) {
        return !liquidityPools[from] &&
        !inSwap
        && swapEnabled
        && balance >= swapThreshold;
    }

    function shouldAddLiquidity(address from, uint256 balance) internal view returns (bool) {
        return !liquidityPools[from] &&
        !inSwap
        && liquidityEnabled
        && balance >= liquidityThreshold;
    }

    function afterUpdateDEX() internal virtual {
        addAddressToLPs(pairAddress);
    }

    function initDEXRouter(address _router) public onlyOwner {
        if (pairAddress != address(0)) {
            removeAddressFromLPs(pairAddress);
        }
        routerAddress = _router;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);
        pairAddress = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            _uniswapV2Router.WETH()
        );
        router = _uniswapV2Router;
        afterUpdateDEX();
        emit RouterSet(routerAddress, pairAddress);
    }

    /**
     * @notice Swaps passed tokens for BNB using Pancakeswap router and returns
     * actual amount received.
     */
    function swapTokensForBnb(uint256 tokenAmount) internal returns(uint256) {
        uint256 initialBalance = address(this).balance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        // Make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );

        uint256 bnbReceived = address(this).balance.sub(initialBalance);
        return bnbReceived;
    }

    function swapAndAddLiquidity(uint256 tokens) internal swapping pcsInitialized {
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens - half;

        uint256 bnb = swapTokensForBnb(half);
        router.addLiquidityETH{value: bnb} (
            address(this),
            otherHalf,
            0,
            0,
            address(this),
            block.timestamp
        );

        emit AutoLiquify(bnb, otherHalf);
    }

    function addAddressToLPs(address lpAddr) public virtual onlyOwner {
        liquidityPools[lpAddr] = true;
    }

    function removeAddressFromLPs(address lpAddr) public onlyOwner {
        require(lpAddr != pairAddress, "You can not remove current pair");
        liquidityPools[lpAddr] = false;
    }

    function setSwapEnabledAndThreshold(bool _enabled, uint256 _amount) public onlyOwner {
        swapEnabled = _enabled;
        swapThreshold = _amount;
        emit UpdateSwapEnabledAndThreshold(_enabled, _amount);
    }

    function setLiquidityEnabledAndThreshold(bool _enabled, uint256 _amount) public onlyOwner {
        liquidityEnabled = _enabled;
        liquidityThreshold = _amount;
        emit UpdateLiquidityEnabledAndThreshold(_enabled, _amount);
    }

    event UpdateSwapEnabledAndThreshold(bool status, uint256 amount);
    event UpdateLiquidityEnabledAndThreshold(bool status, uint256 amount);
    event RouterSet(address indexed router, address indexed pair);
    event AutoLiquify(uint256 amountBNB, uint256 amountToken);
}

abstract contract ExchangeLimits is Ownable {
    bool public exchangeTxEnabled = true;

    event UpdateExchangeTxStatus(bool status);

    function checkExchangeTx(address from, address to, address pair) internal view {
        if (!exchangeTxEnabled && from != owner()) {
            require(from != pair && to != pair, "Exchanger Tx is disabled.");
        }
    }

    function updateExchangeTx(bool status) external onlyOwner {
        require(exchangeTxEnabled != status, "Provide different status from current");
        exchangeTxEnabled = status;
        emit UpdateExchangeTxStatus(status);
    }
}

abstract contract TxLimits is Ownable {
    using SafeMath for uint256;

    mapping (address => bool) internal _isExcludedFromTxLimit;
    uint256 public maxSellForWhale = 10 ** 18;
    uint256 public minBalanceForBeWhale = 10 ** 18;

    event UpdateExcludedFromTxLimit(address account, bool status);
    event UpdateWhaleLimits(uint256 maxSellForWhale, uint256 minBalanceForBeWhale);

    constructor() {
        _isExcludedFromTxLimit[owner()] = true;
        _isExcludedFromTxLimit[address(this)] = true;
    }

    function checkTxLimit(address sender, uint256 amount, uint256 currentBalance) internal view {
        if (_isExcludedFromTxLimit[sender]) {
            return;
        }

        if (currentBalance >= minBalanceForBeWhale) {
            require(amount <= maxSellForWhale, "Anti whale limit");
        }
    }

    function setIsTxLimitExempt(address account, bool status) external onlyOwner {
        _isExcludedFromTxLimit[account] = status;
        emit UpdateExcludedFromTxLimit(account, status);
    }

    function setWhaleLimits(uint256 _maxSellForWhale, uint256 _minBalanceForBeWhale) public onlyOwner {
        maxSellForWhale = _maxSellForWhale;
        minBalanceForBeWhale = _minBalanceForBeWhale;
        emit UpdateWhaleLimits(_maxSellForWhale, _minBalanceForBeWhale);
    }

    function isExcludedFromTxLimit(address account) external view returns(bool) {
        return _isExcludedFromTxLimit[account];
    }
}

abstract contract EarlySelling is Ownable {
    using SafeMath for uint256;

    mapping(address => bool) _isExcludedFromEarlySellingLimit;
    mapping (address => uint256) private lastBuyTime;
    uint256 public earlySellingFeePercent = 1000;
    uint256 public earlySellingPeriodInHours = 48;

    uint256 private feeDenominator = 10000;

    event UpdateEarlySelling(uint256 oldEarlySellingFeePercent, uint256 newEarlySellingFeePercent, uint256 oldEarlySellingPeriodInHours, uint256 newEarlySellingPeriodInHours);
    event UpdateLastBuyTime(address account, uint256 time);

    function setExcludedFromEarlySellingLimit(address holder, bool status) external onlyOwner {
        _isExcludedFromEarlySellingLimit[holder] = status;
    }

    function recordLastBuy(address buyer) internal {
        lastBuyTime[buyer] = block.timestamp;
        emit UpdateLastBuyTime(buyer, block.timestamp);
    }

    function getLastBuy(address buyer) external view returns(uint256) {
        return lastBuyTime[buyer];
    }

    function calculateEarlySellingFee(address from, uint256 amount) internal view returns(uint256) {
        if (_isExcludedFromEarlySellingLimit[from]) {
            return 0;
        }
        if (block.timestamp.sub(lastBuyTime[from]) < earlySellingPeriodInHours * 1 hours) {
            return amount.mul(earlySellingFeePercent).div(feeDenominator);
        }
        return 0;
    }

    function setEarlySelling(uint256 _earlySellingFeePercent, uint256 _earlySellingPeriodInHours) public onlyOwner {
        emit UpdateEarlySelling(earlySellingFeePercent, _earlySellingFeePercent, earlySellingPeriodInHours, _earlySellingPeriodInHours);
        earlySellingFeePercent = _earlySellingFeePercent;
        earlySellingPeriodInHours = _earlySellingPeriodInHours;
    }
}

abstract contract AutoBuyback is Pancake {
    using SafeMath for uint256;

    bool public autoBuybackEnabled;
    uint256 public autoBuybackBnbThreshold;

    uint256 public accumulatedBNBForBuyback;


    modifier buyingBack {
        require(accumulatedBNBForBuyback > autoBuybackBnbThreshold, 'Insufficient Balance of accumulated bnb for buyback!');
        _;
    }

    function setAutoBuybackEnabledAndThreshold(bool _autoBuybackEnabled, uint256 _autoBuybackBnbThreshold) public onlyOwner {
        autoBuybackEnabled = _autoBuybackEnabled;
        autoBuybackBnbThreshold = _autoBuybackBnbThreshold;
    }

    function buyBack(uint256 bnbAmount) private swapping pcsInitialized {
        accumulatedBNBForBuyback = accumulatedBNBForBuyback.sub(bnbAmount);
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(this);

        // Make the swap and send to zero address
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: bnbAmount}(
            0, // accept any amount of Tokens
            path,
            address(0),
            block.timestamp
        );

        emit BuybackDone(bnbAmount);
    }

    function tryAutoBuyback(address from, address to) internal returns(bool) {
        if(shouldAutoBuyback(from, to)) {
            triggerAutoBuyback();
            return true;
        }
        return false;
    }

    function shouldAutoBuyback(address from, address to) private view returns (bool) {
        return !liquidityPools[from]
        && liquidityPools[to]
        && !inSwap
        && autoBuybackEnabled
        && accumulatedBNBForBuyback > autoBuybackBnbThreshold;
    }

    function triggerAutoBuyback() private {
        buyBack(autoBuybackBnbThreshold);
    }

    function triggerBuyback(uint256 amount) external buyingBack onlyOwner {
        if (amount == 0) {
            triggerAutoBuyback();
        } else {
            buyBack(amount);
        }
    }

    function enableAutoBuyback() external onlyOwner {
        autoBuybackEnabled = true;
        emit AutoBuybackEnabled(true);
    }

    function disableAutoBuyback() external onlyOwner {
        autoBuybackEnabled = false;
        emit AutoBuybackEnabled(false);
    }

    event SoldTokensForBuyback(uint256 tokensSold);
    event BuybackDone(uint256 bnbAmount);
    event AutoBuybackEnabled(bool status);
}

abstract contract LotteryHelper is Pancake {
    using SafeMath for uint256;

    uint256 public accumulatedBNBForLottery;
    uint256 public lotterySwapThresholdInBNB = 1 ether / 1000; // 0.001 BNB

    uint256 public lotteryStartedAt;
    uint256 public totalBUSDTransferedToLottery;

    struct LotteryType {
        bool hourly;
        bool daily;
        bool weekly;
    }
    mapping(address => bool) _isExcludedFromLottery;

    mapping(address => bool) _accountInLottery;

    IBEP20 public RewardToken;
    ILotteryTracker public hourly;
    ILotteryTracker public daily;
    ILotteryWeeklyTracker public weekly;

    uint256 public hourlyPoints = 25;
    uint256 public dailyPoints = 25;
    uint256 public weeklyPoints = 50;
    uint256 public totalPoints = hourlyPoints + dailyPoints + weeklyPoints;
    uint256 public entryDivider = 1000 * 10**9;
    uint256 gasForProcess = 300000;

    constructor(address _weeklyAddress, address _daily, address _hourly, address _rewardToken) {
        //        address Token = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; // BUSD by default
        // address Token = 0xd5FE979baBe312f5D344a2b4a51e0Ddd8457DD1E; // TOKEN our
        RewardToken = IBEP20(_rewardToken);

        //        hourly = new LotteryTracker(Token, 1 minutes);
        hourly = ILotteryTracker(_hourly);
        //        daily = new LotteryTracker(Token, 5 minutes);
        daily = ILotteryTracker(_daily);
        weekly = ILotteryWeeklyTracker(_weeklyAddress);

        _isExcludedFromLottery[address(hourly)] = true;
        _isExcludedFromLottery[address(daily)] = true;
        _isExcludedFromLottery[address(weekly)] = true;
        _isExcludedFromLottery[address(this)] = true;
        _isExcludedFromLottery[routerAddress] = true;
        _isExcludedFromLottery[pairAddress] = true;
        //        _isExcludedFromLottery[owner()] = true; todo
    }

    // getters
    function nextHourlyDrawTime() public view returns(uint256) {
        return hourly.getNextDrawTime();
    }

    function nextDailyDrawTime() public view returns(uint256) {
        return daily.getNextDrawTime();
    }

    function isExcludedFromLottery(address holder) external view returns(bool) {
        return _isExcludedFromLottery[holder];
    }

    function isAccountInLottery(address holder) external view returns(LotteryType memory) {
        LotteryType memory inLottery;
        if (_accountInLottery[holder]) {
            inLottery.hourly = hourly.isActiveAccount(holder);
            inLottery.daily = daily.isActiveAccount(holder);
            inLottery.weekly = weekly.isActiveAccount(holder);
        }
        return inLottery;
    }

    function shouldSwapAndSendBUSDToLottery(address from) private view returns (bool) {
        return !liquidityPools[from]
        && !inSwap
        && swapEnabled
        && accumulatedBNBForLottery >= lotterySwapThresholdInBNB
        && lotteryStartedAt != 0
        && lotteryStartedAt < block.timestamp;
    }


    // operations
    function tryProcessHourlyLottery() internal returns (bool) {
        emit TryProcess('hourly');
        return hourly.process(gasForProcess);
    }

    function tryProcessDailyLottery() internal returns (bool) {
        emit TryProcess('daily');
        return daily.process(gasForProcess);
    }

    function trySwapAndSendBUSDToLottery(address from) internal returns (bool) {
        if(shouldSwapAndSendBUSDToLottery(from)) {
            swapAndSendBUSDToLottery();
            return true;
        }
        return false;
    }

    function swapAndSendBUSDToLottery() private swapping pcsInitialized {
        uint256 initialBalance = RewardToken.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(RewardToken);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: accumulatedBNBForLottery}(
            0,
            path,
            address(this),
            block.timestamp
        );

        accumulatedBNBForLottery = 0;


        uint256 tokenReceived = RewardToken.balanceOf(address(this)).sub(initialBalance);
        totalBUSDTransferedToLottery +=  tokenReceived;

        uint256 forHourly = tokenReceived.mul(hourlyPoints).div(totalPoints);
        uint256 forDaily = tokenReceived.mul(dailyPoints).div(totalPoints);
        uint256 forWeekly = tokenReceived.sub(forDaily).sub(forHourly);

        if (forHourly > 0) {
            RewardToken.transfer(address(hourly), forHourly);
        }
        if (forDaily > 0) {
            RewardToken.transfer(address(daily), forDaily);
        }
        if (forWeekly > 0) {
            RewardToken.transfer(address(weekly), forWeekly);
        }
    }

    function getLotteryEntryAmount(uint256 amount) internal view returns(uint256) {
        if (amount == 0) {
            return 0;
        }

        uint256 entries = amount / entryDivider;
        if (amount % entryDivider > 0) {
            return entries + 1;
        }

        return entries;
    }

    function updateAccountLottery(address removeAccount, address addAccount, uint256 amount) internal {
        if (_accountInLottery[removeAccount]) {
            hourly.removeAccount(removeAccount);
            daily.removeAccount(removeAccount);
            weekly.removeAccount(removeAccount);
            _accountInLottery[removeAccount] = false;
            emit RemoveAccountFromLottery(removeAccount);
        }

        if (!_isExcludedFromLottery[addAccount]) {
            uint256 entries = getLotteryEntryAmount(amount);
            hourly.updateAccount(addAccount, entries);
            daily.updateAccount(addAccount, entries);
            weekly.updateAccount(addAccount, entries);
            if (!_accountInLottery[addAccount]) {
                _accountInLottery[addAccount] = true;
                emit AddAccountToLottery(addAccount);
            }
        }
    }

    // settings

    function setHourlyTracker(address _hourly) external onlyOwner {
        emit UpdateHourlyTracker(address(hourly), _hourly);
        hourly = ILotteryTracker(_hourly);
        _isExcludedFromLottery[address(hourly)] = true;
    }

    function setDailyTracker(address _daily) external onlyOwner {
        emit UpdateDailyTracker(address(daily), _daily);
        daily = ILotteryTracker(_daily);
        _isExcludedFromLottery[address(daily)] = true;
    }

    function setWeeklyTracker(address _weekly) external onlyOwner {
        emit UpdateWeeklyTracker(address(weekly), _weekly);
        weekly = ILotteryWeeklyTracker(_weekly);
        _isExcludedFromLottery[address(weekly)] = true;
    }


    function setEntryDivider(uint256 divider) external onlyOwner {
        require(divider > 0, "Can't be zero");
        entryDivider = divider;
    }

    function setLotterySwapThresholdInBNB(uint256 bnbAmount) external onlyOwner {
        require(bnbAmount != lotterySwapThresholdInBNB, "Same value");
        emit UpdateLotterySwapThresholdInBNB(lotterySwapThresholdInBNB, bnbAmount);
        lotterySwapThresholdInBNB = bnbAmount;
    }

    function setLotteryDistributionPoints(uint256 _hourlyPoints, uint256 _dailyPoints, uint256 _weeklyPoints) external onlyOwner {
        hourlyPoints = _hourlyPoints;
        dailyPoints = _dailyPoints;
        weeklyPoints = _weeklyPoints;
        totalPoints = hourlyPoints.add(dailyPoints).add(weeklyPoints);
        require(totalPoints != 0, "At least one share point should be greater than 0");
        emit UpdateLotteryDistributionPoints(_hourlyPoints, _dailyPoints, _weeklyPoints, totalPoints);
    }

    function setLotteryStartTime(uint256 time) external onlyOwner {
        require(lotteryStartedAt < time, "Current started time is greater");
        lotteryStartedAt = time;
        hourly.setNextDrawTime(time.add(1 minutes));
        daily.setNextDrawTime(time.add(5 minutes).add(30 seconds)); // specially made so.
    }

    function setExcludedFromLottery(address holder, bool exempt) external onlyOwner {
        _isExcludedFromLottery[holder] = exempt;
    }

    function setLotteryDrawThreshold(uint256 _hourlyBUSDThreshold, uint256 _dailyBUSDThreshold) public onlyOwner {
        hourly.setDrawThresholdInBUSD(_hourlyBUSDThreshold);
        daily.setDrawThresholdInBUSD(_dailyBUSDThreshold);
    }

    event TryProcess(string processType);
    event RemoveAccountFromLottery(address account);
    event AddAccountToLottery(address account);
    event UpdateLotterySwapThresholdInBNB(uint256 oldValue, uint256 newValue);
    event UpdateLotteryDistributionPoints(uint256 hourlyPoints, uint256 dailyPoints, uint256 weeklyPoints, uint256 totalPoints);
    event UpdateHourlyTracker(address oldTracker, address newTracker);
    event UpdateDailyTracker(address oldTracker, address newTracker);
    event UpdateWeeklyTracker(address oldTracker, address newTracker);
}

contract Lambottery is
IBEP20,
ExchangeLimits,
TxLimits,
EarlySelling,
AutoBuyback,
LotteryHelper {
    using SafeMath for uint256;

    string constant _name = "DefiSmartV3";
    string constant _symbol = "DSFV3";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 10 ** 12 * (10 ** _decimals);

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) _isExcludedFromFee;

    uint256 public accumulatedForLiquidity;
    uint256 public buybackFee = 400;
    uint256 public separateBuybackFee = 200;
    uint256 public liquidityFee = 400;
    uint256 public lotteryFee = 500;
    uint256 public marketingAndOperationsFee = 500;

    uint256 public totalFee = buybackFee + separateBuybackFee + liquidityFee + lotteryFee + marketingAndOperationsFee;
    uint256 public feeDenominator = 10000;

    // wallets

    address public separateBuybackReceiver = 0xBC3C2C6e7BaAeB7C7EA2ad4B2Fa8681a91d47Ccd;
    address public marketingAndOperationsFeeReceiver = 0xb0462911f2d4B5993000C493F5C261Bd55303664;

    bool liquidityIsAdded;
    uint256 public operationsNumber;
    struct Operations {
        uint256 hourly;
        uint256 daily;
        uint256 buyback;
        uint256 swapAndSendBUSDToLotteries;
        uint256 swapTokens;
        uint256 swapAndSendLiquidity;
    }

    Operations public operationsImpact;

    constructor (address _weeklyAddress, address _daily, address _hourly, address _rewardToken)
    LotteryHelper(_weeklyAddress, _daily, _hourly, _rewardToken) {

        // initDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        // initDEXRouter(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); // testnet
        //0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D ropsten
        initDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E); // testnet ropsten
        _approveMax(address(this), routerAddress);

        operationsNumber = 2;
        setOperationImpactOfEachOperations(1, 1, 1, 1, 2, 2);
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[routerAddress] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromEarlySellingLimit[owner()] = true;
        _isExcludedFromEarlySellingLimit[address(this)] = true;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function prepareForPreSale(address router, address saleContract) external onlyOwner {
        _isExcludedFromFee[router] = true;
        _isExcludedFromFee[saleContract] = true;
        _isExcludedFromEarlySellingLimit[router] = true;
        _isExcludedFromEarlySellingLimit[saleContract] = true;
        _isExcludedFromTxLimit[router] = true;
        _isExcludedFromTxLimit[saleContract] = true;
        _isExcludedFromLottery[router] = true;
        _isExcludedFromLottery[saleContract] = true;
        operationsNumber = 0;
        setFees(0,0,0,0,0);
    }

    function afterPreSale() external onlyOwner {
        operationsNumber = 2;
        setFees(400,400,200,500,500);
        callAfterLiquidityIsAdded();
    }

    function setOperationsNumber(uint256 number) external onlyOwner {
        emit UpdateOperationsNumber(operationsNumber, number);
        operationsNumber = number;
    }

    function setOperationImpactOfEachOperations(
        uint256 _hourly,
        uint256 _daily,
        uint256 _buyback,
        uint256 _swapAndSendBUSDToLotteries,
        uint256 _swapTokens,
        uint256 _swapAndSendLiquidity
    ) public onlyOwner {
        operationsImpact.hourly = _hourly;
        operationsImpact.daily = _daily;
        operationsImpact.buyback = _buyback;
        operationsImpact.swapAndSendBUSDToLotteries = _swapAndSendBUSDToLotteries;
        operationsImpact.swapTokens = _swapTokens;
        operationsImpact.swapAndSendLiquidity = _swapAndSendLiquidity;
    }

    function callAfterDeployAndSetOwnersOnLotteryContract() external onlyOwner {
        setWhaleLimits(_totalSupply / 1000, _totalSupply / 200);
        setLotteryDrawThreshold(10**10, 10**10); // set the threshold for hourly and daily lottery contracts
    }

    function callAfterLiquidityIsAdded() public onlyOwner {
        require(!liquidityIsAdded);
        liquidityIsAdded = true;
        setSwapEnabledAndThreshold(true, 1000000000000000); // 1M
        setLiquidityEnabledAndThreshold(true, 1000000000000000); // 1M
        setAutoBuybackEnabledAndThreshold(true, 10**16); // 0.01 BNB
    }

    function balanceOfInBUSD(address account) public view returns(uint256[] memory) {
        uint256 inToken = balanceOf(account);
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = router.WETH();
        path[2] = address(RewardToken);
        uint256[] memory inBUSD = router.getAmountsOut(inToken, path);
        return inBUSD;
    }


    function afterUpdateDEX() internal override {
        super.afterUpdateDEX();
        _isExcludedFromTxLimit[routerAddress] = true;
        _isExcludedFromTxLimit[pairAddress] = true;
        _isExcludedFromLottery[routerAddress] = true;
        _isExcludedFromLottery[pairAddress] = true;
        _isExcludedFromEarlySellingLimit[pairAddress] = true;
        _isExcludedFromEarlySellingLimit[routerAddress] = true;
    }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner(); }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return _approveMax(msg.sender, spender);
    }

    function _approveMax(address owner, address spender) internal returns (bool) {
        _allowances[owner][spender] = type(uint256).max;
        emit Approval(msg.sender, spender, type(uint256).max);
        return true;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        checkTxLimit(sender, amount, balanceOf(sender));
        checkExchangeTx(sender, recipient, pairAddress);

        updateAccountLottery(sender, recipient, amount);
        recordLastBuy(recipient);

        if (liquidityIsAdded) {
            uint256 operation;

            if (operation + operationsImpact.hourly <= operationsNumber) {
                if (tryProcessHourlyLottery()) {
                    operation += operationsImpact.hourly;
                }
            }

            if (operation + operationsImpact.daily <= operationsNumber) {
                if (tryProcessDailyLottery()) {
                    operation += operationsImpact.daily;
                }
            }

            if (operation + operationsImpact.buyback <= operationsNumber) {
                if (tryAutoBuyback(sender, recipient)) {
                    operation += operationsImpact.buyback;
                }
            }

            if (operation + operationsImpact.swapAndSendBUSDToLotteries <= operationsNumber) {
                if (trySwapAndSendBUSDToLottery(sender)) {
                    operation += operationsImpact.swapAndSendBUSDToLotteries;
                }
            }

            if (operation + operationsImpact.swapTokens <= operationsNumber) {
                if(shouldSwapBack(sender, _balances[address(this)] - accumulatedForLiquidity)){
                    swapBack(swapThreshold);
                    operation += operationsImpact.swapTokens;
                }
            }

            if (operation + operationsImpact.swapAndSendLiquidity < operationsNumber) {
                if (shouldAddLiquidity(sender, accumulatedForLiquidity)) {
                    swapAndAddLiquidity(liquidityThreshold);
                    accumulatedForLiquidity -= liquidityThreshold;
                    operation += operationsImpact.swapAndSendLiquidity;
                }
            }
            emit ProcessedOperationsNumber(operation);
        }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        amount = shouldTakeFee(sender) ? takeFee(sender, amount) : amount;


        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }



    function shouldTakeFee(address sender) internal view returns (bool) {
        return !_isExcludedFromFee[sender];
    }


    function isExcludedFromFee(address account) external view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function takeFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 earlySellingFee = calculateEarlySellingFee(sender, amount);

        uint256 feeAmount = amount.mul(totalFee).div(feeDenominator).add(earlySellingFee);

        accumulatedForLiquidity = accumulatedForLiquidity.add(feeAmount.mul(liquidityFee).div(feeDenominator));

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function swapBack(uint256 amount) internal swapping pcsInitialized {
        uint256 amountBNB = swapTokensForBnb(amount);

        uint256 totalSwappedFee = totalFee.sub(liquidityFee);

        uint256 bnbBuyback = amountBNB.mul(buybackFee).div(totalSwappedFee);
        uint256 bnbSeparateBuyback = amountBNB.mul(separateBuybackFee).div(totalSwappedFee);
        uint256 bnbLottery = amountBNB.mul(lotteryFee).div(totalSwappedFee);
        uint256 bnbMarketingAndOperations = amountBNB.sub(bnbBuyback).sub(bnbSeparateBuyback).sub(bnbLottery);

        accumulatedBNBForBuyback = accumulatedBNBForBuyback.add(bnbBuyback);
        accumulatedBNBForLottery = accumulatedBNBForLottery.add(bnbLottery);

        bool success;
        if (bnbSeparateBuyback > 0) {
            (success,) = payable(separateBuybackReceiver).call{value: bnbSeparateBuyback}("");
            if (success) {
                emit SendBnbToSeparateBuybackReceiver(bnbSeparateBuyback);
            }
        }

        if (bnbMarketingAndOperations > 0) {
            (success,) = payable(marketingAndOperationsFeeReceiver).call{value: bnbMarketingAndOperations}("");
            if (success) {
                emit SendBnbToMarketingAndOperationsFeeReceiver(bnbMarketingAndOperations);
            }
        }
    }

    function setExcludedFromFee(address holder, bool exempt) external onlyOwner {
        _isExcludedFromFee[holder] = exempt;
    }

    function setFees(uint256 _liquidityFee, uint256 _buybackFee, uint256 _separateBuybackFee, uint256 _marketingFee, uint256 _lotteryFee) public onlyOwner {
        liquidityFee = _liquidityFee;
        buybackFee = _buybackFee;
        marketingAndOperationsFee = _marketingFee;
        separateBuybackFee = _separateBuybackFee;
        lotteryFee = _lotteryFee;
        totalFee = _liquidityFee.add(_buybackFee).add(_separateBuybackFee).add(_marketingFee).add(_lotteryFee);
        require(totalFee < 3000);
    }

    function setFeeReceivers(address _marketingFeeReceiver, address _separateBuybackReceiver) external onlyOwner {
        marketingAndOperationsFeeReceiver = _marketingFeeReceiver;
        separateBuybackReceiver = _separateBuybackReceiver;
    }

    function inCaseTokensGetStuck(address _token, uint256 _amount) public onlyOwner {
        IBEP20(_token).transfer(msg.sender, _amount);
    }

    event SendBnbToMarketingAndOperationsFeeReceiver(uint256 bnbAmount);
    event SendBnbToSeparateBuybackReceiver(uint256 bnbAmount);
    event UpdateOperationsNumber(uint256 oldNumber, uint256 newNumber);
    event ProcessedOperationsNumber(uint256 operations);
}


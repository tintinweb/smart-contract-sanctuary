pragma solidity ^0.8.0;
import "./IERC20Metadata.sol";

interface IERC20 is IERC20Metadata {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.8.0;

interface IERC20Metadata {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

pragma solidity ^0.8.0;

interface IOwnable {
    function owner() external view returns (address);

    function transferOwnership(address newOwner) external;
}

pragma solidity ^0.8.0;

interface IFutureExchangeRouter {
    
    function futureTokenFactory() external view returns (address);
    
    function getListFutureContractsInPair(address token) external view returns(address[] memory);
    
    function getAmountsOutFuture(uint256 amountIn, address tokenIn, address tokenOut, uint256 expiryDate) external view returns(uint256);
    
    function getAmountsInFuture(uint256 amountOut, address tokenIn, address tokenOut, uint256 expiryDate) external view returns(uint256);
    
    function addLiquidityFuture(address tokenA, address tokenB, uint256 amountA, uint256 amountB, uint256 expiryDate, string memory symbol) external;
    
    function withdrawLiquidityFuture(address tokenA, address tokenB, uint256 expiryDate, address to, uint256 amount) external;
    
    function swapFuture(address tokenA, address tokenB, uint expiryDate, address to, uint amount) external returns(uint);
    
    function closeFuture(address tokenA, address tokenB, uint expiryDate, address to, uint amount) external;
}

pragma solidity ^0.8.0;

import "../../future-token/interfaces/IFutureTokenFactory.sol";
import "../../future-token/interfaces/IFutureToken.sol";

import "../../common/interfaces/IERC20.sol";

import "./SafeMath.sol";

library PrecogV2Library {
    using SafeMath for uint256;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "PrecogV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "PrecogV2Library: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            bytes20(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        hex"8bbe3b87a8ff316d03607692c9e315540483dd03b2a3eff7147a4e04f4503f25" // init code hash
                    )
                )
            )
        );
    }    

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "PrecogV2Library: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "PrecogV2Library: INSUFFICIENT_LIQUIDITY");
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOutFuture(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "PrecogV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "PrecogV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 numerator = amountIn.mul(reserveOut);
        uint256 denominator = reserveIn.add(amountIn);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountInFuture(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "PrecogV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "PrecogV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 numerator = reserveIn.mul(amountOut);
        uint256 denominator = reserveOut.sub(amountOut);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOutFuture(
        address factory,
        uint256 amountIn,
        address tokenIn,
        address tokenOut,
        uint256 deadline
    ) internal view returns (uint256 amountOut) {
        (uint256 reserveIn, uint256 reserveOut) = getReservesFuture(factory, tokenIn, tokenOut, deadline);
        amountOut = getAmountOutFuture(amountIn, reserveIn, reserveOut);
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsInFuture(
        address factory,
        uint256 amountOut,
        address tokenIn,
        address tokenOut,
        uint256 deadline
    ) internal view returns (uint256 amountIn) {
        (uint256 reserveIn, uint256 reserveOut) = getReservesFuture(factory, tokenIn, tokenOut, deadline);
        amountIn = getAmountInFuture(amountOut, reserveIn, reserveOut);
    }

    // fetches and sorts the reserves for a pair
    function getReservesFuture(
        address factory,
        address tokenA,
        address tokenB,
        uint256 deadline
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        address futureContract = IFutureTokenFactory(factory).getFutureContract(tokenA, tokenB, deadline);
        reserveA = IERC20(tokenA).balanceOf(futureContract);
        reserveB = IERC20(tokenB).balanceOf(futureContract);
    }
}

pragma solidity ^0.8.0;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
}

pragma solidity ^0.8.0;

interface IFutureContract {
    
    function token0() external view returns (address);
    
    function token1() external view returns (address);
    
    function expiryDate() external view returns (uint256);
}

pragma solidity ^0.8.0;

interface IFutureToken {
    
    function initialize(string memory symbol) external;
    
    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;
}

pragma solidity ^0.8.0;

interface IFutureTokenFactory {
    
    function exchange() external view returns (address);
    
    event futureTokenCreated(
        address indexed token0,
        address indexed token1,
        address futureTokenAddress,
        uint256 i
    );
    
    function getFutureContract(address tokenA, address tokenB, uint expiryDate) external view returns (address);

    function getFutureToken(address tokenIn, address tokenOut, uint expiryDate) external view returns (address);

    function createFuture(address tokenA, address tokenB, uint expiryDate, string memory symbol) external returns (address);

    function mintFuture(address tokenIn, address tokenOut, uint expiryDate, address to, uint amount) external;

    function burnFuture(address tokenIn, address tokenOut, uint expiryDate, uint amount) external;
}

pragma solidity ^0.8.0;

library DataTypes {
  // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    uint40 lastUpdateTimestamp;
    //tokens addresses
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint8 id;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: Reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60-63: reserved
    //bit 64-79: reserve factor
    uint256 data;
  }

  struct UserConfigurationMap {
    uint256 data;
  }
  
  struct BorrowInfo{
    uint256 platformIndex;
    uint256 borrowedAmount;
    uint256 interestRate;
  }

  enum InterestRateMode {NONE, STABLE, VARIABLE}
}

pragma solidity ^0.8.0;

interface ILending {
    function sendCollateral(uint platformIndex, address borrowToken, uint256 amount) external;
    function withdrawCollateral(uint platformIndex, address borrowToken, uint256 amount) external;
    function getLendingPlatformCollateral(uint platformIndex, address borrowToken) external returns (uint, uint);
    function getLendingPlatformBorrow(uint platformIndex, address borrowToken) external returns (uint);
    function getLendingPlatforms(uint platformIndex) external view returns (address);
    function lendingPlatformsCount() external view returns (uint);

    function getBorrowableAmount(uint platformIndex, address borrowToken) external view returns (uint);
    function getDebtAmount(
        uint256 platformIndex,
        address borrowToken,
        uint256 borrowAmount,
        uint256 fromTimestamp,
        uint256 toTimestamp,
        uint256 fromBlock,
        uint256 toBlock
    ) external view returns(uint);

    function createLoan(uint platformIndex, address borrowToken, uint borrowAmount) external;
    function repayLoan(uint platformIndex, address borrowToken, uint repayAmount) external;
}

pragma solidity ^0.8.0;
import "./interfaces/IExchangeRouter.sol";
import "./interfaces/IExchangeFactory.sol";
import "./interfaces/IExchangePair.sol";
import "../future-exchange/interfaces/IFutureExchangeRouter.sol";
import "../future-exchange/libraries/PrecogV2Library.sol";
import "../future-token/interfaces/IFutureToken.sol";
import "../future-token/interfaces/IFutureTokenFactory.sol";
import "../future-token/interfaces/IFutureContract.sol";
import "../lending-platform/interfaces/ILending.sol";
import "../lending-platform/interfaces/DataTypes.sol";
import "../common/interfaces/IERC20.sol";
import "../common/interfaces/IOwnable.sol";

contract Precog {

    struct BorrowInfo {
        uint platformIndex;
        uint amount;
        uint startTime;
        uint startBlock;
    }

    struct TradeInfo {
        address exchange;
        address futureExchange;
        address futureContract;
    }

    struct ProfitInfo {
        uint amount;
        uint investAmount;
        uint loanAmount;
        uint expiryDate;
    }

    struct FeeInfo {
        uint trading;
        uint lending;
    }

    address public usdc;
    address public weth;
    address public tradingService;
    address public admin;
    address public lendingContract;

    uint256 public feeWithdrawByUSDC = 2e6; // 2 USDC
    uint256 public feeTradingByEth = 5e15; // 0.005 ETH
    uint256 public feeLendingByEth = 5e15; // 0.005 ETH
    uint256 public borrowRateLimit = 70; // 70%

    address[] futureExchanges;
    address[] exchanges;
    mapping(address => uint) futureExchangeIndex;
    mapping(address => uint) exchangeIndex;

    mapping(address => uint) availableAmount;
    mapping(address => uint) investAmount;
    mapping(address => uint) totalTradingAmount;

    mapping(address => mapping(address => uint)) tradingAmount;
    mapping(address => mapping(address => uint)) revenueAmount;
    mapping(address => mapping(address => uint)) liquidatedAmount;
    mapping(address => mapping(address => bool)) isTradeClosed;
    mapping(address => mapping(address => BorrowInfo[])) userBorrowInfo;

    address[] tradeUsers;
    mapping(address => uint256) tradeUserIndex;

    event Deposit(address indexed user, uint amount, uint indexed timestamp);
    event Withdraw(address indexed user, uint amount, uint fee, uint indexed timestamp);
    event Trade(
        address indexed user,
        address indexed futureContract,
        uint256 deadline,
        uint256 amount,
        uint256 profit,
        uint256 fee,
        uint256 indexed timestamp);
    event Borrow(
        address indexed user,
        address indexed futureContract,
        uint256 indexed platformIndex,
        uint256 amount,
        uint256 interest,
        uint256 fee);
    event Liquidate(address indexed user, address indexed futureContract, uint profitActual, uint indexed timestamp);
    event UnpaidLoan(address indexed user, address indexed futureContract, uint indexed platformIndex, uint amount);

    modifier onlyAdmin() {
        require(msg.sender == admin, "PrecogV2: NOT_ADMIN_ADDRESS");
        _;
    }

    constructor(address _usdc, address _weth, address _tradingService, address _admin) {
        usdc = _usdc;
        weth = _weth;
        tradingService = _tradingService;
        admin = _admin;
    }

    function setAdmin(address _admin) external onlyAdmin {
        admin = _admin;
    }

    function setFeeWithdrawByUSDC(uint256 fee) external onlyAdmin {
        feeWithdrawByUSDC = fee;
    }

    function setFeeTradingByETH(uint256 fee) external onlyAdmin {
        feeTradingByEth = fee;
    }

    function setFeeLendingByEth(uint256 fee) external onlyAdmin {
        feeLendingByEth = fee;
    }

    function setBorrowRateLimit(uint256 borrowRate) external onlyAdmin {
        borrowRateLimit = borrowRate;
    }

    function setLending(address lending) external onlyAdmin {
        lendingContract = lending;
        IERC20(usdc).approve(address(lending), type(uint256).max);
    }

    function tradeAvailableUsers() external view returns(address[] memory) {
        return tradeUsers;
    }

    function getFutureExchanges(uint256 index) external view returns (address) {
        return futureExchanges[index];
    }

    function getExchanges(uint256 index) external view returns (address) {
        return exchanges[index];
    }

    function getLendingFeeByEth() external view returns (uint256) {
        return feeLendingByEth;
    }

    function getBorrowingRateLimit() external view returns(uint256) {
        return borrowRateLimit;
    }

    function getLending() external view returns(address) {
        return lendingContract;
    }

    function getAvailableAmount(address user) external view returns (uint256) {
        return availableAmount[user];
    }

    function getInvestAmount(address user) external view returns (uint256) {
        return investAmount[user];
    }

    function getTradingAmount(address user) external view returns (uint256) {
        return totalTradingAmount[user];
    }

    function getTradingAmountOnFutureContract(address user, address futureContract) external view returns (uint256) {
        return tradingAmount[user][futureContract];
    }

    function getUserBorrowInfo(address user, address futureContract) external view returns(BorrowInfo[] memory) {
        return userBorrowInfo[user][futureContract];
    }

    function getLiquidateInfo(address user, address futureContract) external view returns (uint liquidateAmount, bool isTradeClose) {
        liquidateAmount = liquidatedAmount[user][futureContract];
        isTradeClose = isTradeClosed[user][futureContract];
    }

    function getTradeUserIndex(address user) external view returns (uint256) {
        return tradeUserIndex[user];
    }

    function addFutureExchange(address exchange) external {
        require(!isFutureExchange(exchange), "PrecogV2: FUTURE_EXCHANGE_ADDED");
        futureExchanges.push(exchange);
        futureExchangeIndex[exchange] = futureExchanges.length;
    }

    function addExchange(address exchange) external {
        require(!isExchange(exchange), "PrecogV2: EXCHANGE_ADDED");
        exchanges.push(exchange);
        exchangeIndex[exchange] = exchanges.length;
        IERC20(usdc).approve(address(exchange), type(uint256).max);
    }

    function removeFutureExchange(address exchange) external {
        require(isFutureExchange(exchange), "PrecogV2: FUTURE_EXCHANGE_NOT_ADDED");
        if (futureExchanges.length > 1) {
            uint256 index = futureExchangeIndex[exchange] - 1;
            futureExchanges[index] = futureExchanges[futureExchanges.length - 1];
        }
        futureExchanges.pop();
        futureExchangeIndex[exchange] = 0;
        IERC20(usdc).approve(address(exchange), 0);
    }

    function removeExchange(address exchange) external {
        require(isExchange(exchange), "PrecogV2: EXCHANGE_NOT_ADDED");
        if (exchanges.length > 1) {
            uint256 index = exchangeIndex[exchange] - 1;
            exchanges[index] = exchanges[exchanges.length - 1];
        }
        exchanges.pop();
        exchangeIndex[exchange] = 0;
        IERC20(usdc).approve(address(exchange), 0);
    }

    function isFutureExchange(address exchange) public view returns (bool) {
        return futureExchangeIndex[exchange] > 0;
    }

    function isExchange(address exchange) public view returns (bool) {
        return exchangeIndex[exchange] > 0;
    }

    function futureExchangesCount() external view returns (uint256) {
        return futureExchanges.length;
    }

    function exchangesCount() external view returns (uint256) {
        return exchanges.length;
    }

    function deposit(uint256 amount) external {
        require(amount > 0, "PrecogV2: AMOUNT_LOWER_EQUAL_FEE");
        IERC20(usdc).transferFrom(msg.sender, address(this), amount);
        _deposit(amount);
        _addTradingUser();
    }

    function _deposit(uint256 amount) internal {
        availableAmount[msg.sender] += amount;
        emit Deposit(msg.sender, amount, block.timestamp);
    }

    function _addTradingUser() internal {
        if (tradeUserIndex[msg.sender] == 0) {
            tradeUsers.push(msg.sender);
            tradeUserIndex[msg.sender] = tradeUsers.length;
        }
    }

    function withdraw(uint256 amount, address to) external {
        require(availableAmount[msg.sender] >= amount + feeWithdrawByUSDC , "PrecogV2: AVAILABLE_AMOUNT_NOT_ENOUGH");
        IERC20(usdc).transfer(to, amount);
        _wthdraw(amount);
        IERC20(usdc).transfer(admin, feeWithdrawByUSDC);
        _removeTradingUser(msg.sender);
    }

    function _wthdraw(uint256 amount) internal {
        availableAmount[msg.sender] -= amount + feeWithdrawByUSDC;
        emit Withdraw(msg.sender, amount, feeWithdrawByUSDC, block.timestamp);
    }

    function _removeTradingUser(address user) internal {
        if (availableAmount[user] == 0) {
            if (tradeUsers.length > 0) {
                uint256 index = tradeUserIndex[user] - 1;
                uint256 lastUserIndex = tradeUsers.length - 1;
                address lastUser = tradeUsers[lastUserIndex];
                tradeUserIndex[lastUser] = tradeUserIndex[user];
                tradeUsers[index] = lastUser;
            }
            tradeUserIndex[user] = 0;
            tradeUsers.pop();
        }
    }

    function withdrawLiquidate(address futureContract, address to, address user) external {
        require(!isTradeClosed[user][futureContract], "PrecogV2: TRADE_CLOSED");
        if (liquidatedAmount[user][futureContract] == 0) {
            liquidate(futureContract, user);
        }
        uint amount = liquidatedAmount[user][futureContract] - feeWithdrawByUSDC;
        IERC20(usdc).transfer(to, amount);
        IERC20(usdc).transfer(admin, feeWithdrawByUSDC);
        isTradeClosed[user][futureContract] = true;
        emit Withdraw(user, amount, feeWithdrawByUSDC, block.timestamp);
        _updateLiquidateAmount(user, futureContract);
    }

    function reinvest(address futureContract, address user) external {
        require(!isTradeClosed[user][futureContract], "PrecogV2: TRADE_CLOSED");
        if (liquidatedAmount[user][futureContract] == 0) {
            liquidate(futureContract, user);
        }
        availableAmount[msg.sender] += liquidatedAmount[user][futureContract];
        isTradeClosed[user][futureContract] = true;
        _updateLiquidateAmount(user, futureContract);
        _addTradingUser();
    }

    function liquidate(address futureContract, address user) public {
        require(liquidatedAmount[user][futureContract] == 0, "PrecogV2: ALREADY_LIQUIDATED");
        require(totalTradingAmount[user] > 0, "PrecogV2: TRADING_AMOUNT_NOT_ENOUGH");
        address tokenA = IFutureContract(futureContract).token0();
        address tokenB = IFutureContract(futureContract).token1();
        require(tokenA == usdc || tokenB == usdc, "PrecogV2: INVALID_TOKEN");

        address tokenInvest = tokenA == usdc ? tokenB : tokenA;
        uint256 expiryDate = IFutureContract(futureContract).expiryDate();
        address futureFactory = IOwnable(futureContract).owner();
        address futureExchange = IFutureTokenFactory(futureFactory).exchange();
        address futureToken = IFutureTokenFactory(futureFactory).getFutureToken(tokenInvest, usdc, expiryDate);

        if (IERC20(futureToken).allowance(address(this), futureExchange) == 0) {
            IERC20(futureToken).approve(futureExchange, type(uint256).max);
        }

        uint revenue = revenueAmount[user][futureContract];
        IFutureExchangeRouter(futureExchange).closeFuture(tokenInvest, usdc, expiryDate, address(this), revenue);

        uint debt = _repayLoan(user, futureContract);
        uint actualProfit = revenue - tradingAmount[user][futureContract] - debt;
        liquidatedAmount[user][futureContract] = revenue - debt;

        emit Liquidate(user, futureContract, actualProfit, block.timestamp);
    }

    function _swapFee(uint feeEth) internal returns(uint usedUsdc) {
        address[] memory pair = new address[](2);
        pair[0] = usdc;
        pair[1] = weth;

        uint256 deadline = block.timestamp + 3600;

        (address exchange, uint256 feeTradingUsdc) = _selectBestPriceExchange(pair, feeEth);
        if (address(exchange) != address(0)) {
            uint[] memory amounts = IExchangeRouter(exchange).swapTokensForExactETH(feeTradingByEth, feeTradingUsdc, pair, tradingService, deadline);
            return (amounts[0]);
        }
    }

    function _selectBestPriceExchange(address[] memory pair, uint256 amount)
        internal view returns (address selected, uint256 inAmount)
    {
        inAmount = type(uint256).max;
        for (uint256 i = 0; i < exchanges.length; i++) {
            IExchangeRouter exchange = IExchangeRouter(exchanges[i]);
            try exchange.getAmountsIn(amount, pair) returns (uint256[] memory inAmounts) {
                if (inAmount > inAmounts[0]) {
                    inAmount = inAmounts[0];
                    selected = exchanges[i];
                }
            } catch {}
        }
    }

    function _getUserLoans(address user, address futureContract) internal view returns(BorrowInfo[] memory userLoans) {
        uint count = ILending(lendingContract).lendingPlatformsCount();
        userLoans = new BorrowInfo[](count);

        BorrowInfo[] memory loans = userBorrowInfo[user][futureContract];
        if (loans.length > 0) {
            for (uint i = 0; i < loans.length; i++) {
                uint index = loans[i].platformIndex - 1;
                if (userLoans[index].platformIndex == 0) {
                    userLoans[index] = loans[i];
                } else {
                    userLoans[index].amount += loans[i].amount;
                }
            }
        }
    }

    function _repayLoan(address user, address futureContract) internal returns(uint totalDebt) {
        BorrowInfo[] memory loans = _getUserLoans(user, futureContract);
        if (loans.length > 0) {
            for (uint i = 0; i < loans.length; i++) {
                if (loans[i].platformIndex > 0) {
                    uint debt = _getDebtAmount(loans[i], block.timestamp, block.number);
                    if (totalDebt + debt > revenueAmount[user][futureContract]) {
                        uint unpaidDebt = totalDebt + debt - revenueAmount[user][futureContract];
                        debt = revenueAmount[user][futureContract] - totalDebt;
                        emit UnpaidLoan(user, futureContract, loans[i].platformIndex, unpaidDebt);
                    }
                    if (debt > 0) {
                        totalDebt += debt;
                        ILending(lendingContract).repayLoan(loans[i].platformIndex, usdc, debt);
                    }
                }
            }
        }
    }

    function _updateLiquidateAmount(address user, address futureContract) internal {
        totalTradingAmount[user] -= tradingAmount[user][futureContract];
        tradingAmount[user][futureContract] = 0;
    }

    function maxProfitable(address user) external view returns (
        uint256 investAmount,
        uint256 profitAmount,
        TradeInfo memory trade,
        BorrowInfo memory borrow
    ) {
        FeeInfo memory fee = FeeInfo(_convertEthToUsdc(feeTradingByEth), _convertEthToUsdc(feeLendingByEth));
        if (availableAmount[user] > fee.trading) {
            investAmount = availableAmount[user];
            BorrowInfo[] memory loans = _getAvailableLoans(investAmount);
            if (loans.length == 0) {
                loans = new BorrowInfo[](1);
            }
            for (uint k = 0; k < futureExchanges.length; k++) {
                address[] memory futureContracts = IFutureExchangeRouter(futureExchanges[k]).getListFutureContractsInPair(usdc);
                for (uint j = 0; j < futureContracts.length; j++) {
                    for (uint i = 0; i < exchanges.length; i++) {
                        TradeInfo memory _trade = TradeInfo(exchanges[i], futureExchanges[k], futureContracts[j]);
                        for (uint l = 0; l < loans.length; l++) {
                            ProfitInfo memory profit = _calculateProfit(user, investAmount, fee, _trade, loans[l]);
                            if (profit.amount > profitAmount) {
                                profitAmount = profit.amount;
                                investAmount = profit.investAmount;
                                loans[l].amount = profit.loanAmount;
                                trade = _trade;
                                if (profit.loanAmount > 0 && loans[l].amount > 0) {
                                    borrow = loans[l];
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    function _convertEthToUsdc(uint amount) internal view returns(uint) {
        address[] memory pair = new address[](2);
        pair[0] = usdc;
        pair[1] = weth;
        (, uint256 feeTradingUsdc) = _selectBestPriceExchange(pair, amount);
        return feeTradingUsdc;
    }

    function _getAvailableLoans(uint amount) internal view returns (BorrowInfo[] memory loans) {
        uint borrowLimit = amount * borrowRateLimit / 100;
        try ILending(lendingContract).lendingPlatformsCount() returns(uint platformCount) {
            loans = new BorrowInfo[](platformCount);
            for (uint i = 0; i < platformCount; ++i) {
                loans[i] = _getAvailableLoan(i + 1, borrowLimit);
            }
        } catch {}
    }

    function _getAvailableLoan(uint platformIndex, uint borrowLimit) internal view returns (BorrowInfo memory loan) {
        uint borrowAmount = ILending(lendingContract).getBorrowableAmount(platformIndex, usdc);
        if (borrowAmount > borrowLimit)
            borrowAmount = borrowLimit;
        loan = BorrowInfo(platformIndex, borrowAmount, block.timestamp, block.number);
    }

    function _calculateProfit(
        address user,
        uint256 investAmount,
        FeeInfo memory fee,
        TradeInfo memory trade,
        BorrowInfo memory loan
    ) internal view returns (ProfitInfo memory profit) {
        profit.investAmount = investAmount;
        profit.expiryDate = IFutureContract(trade.futureContract).expiryDate();
        if (profit.expiryDate > block.timestamp) {
            address[] memory pairs = _getPairs(trade.futureContract);
            if (pairs[0] != address(0)) {
                if (investAmount > fee.trading) {
                    uint tradeAmount = _getOptimizeTradeAmount(profit.expiryDate, pairs, trade);
                    if (tradeAmount + fee.trading < investAmount) {
                        profit.investAmount = tradeAmount + fee.trading;
                    }

                    uint debt;
                    if (loan.platformIndex > 0 && tradeAmount + fee.trading > investAmount) {
                        uint feeLending = userBorrowInfo[user][trade.futureContract].length == 0 ? fee.lending : 0;
                        if (investAmount + loan.amount > fee.trading + feeLending) {
                            if (tradeAmount > investAmount + loan.amount - fee.trading - feeLending) {
                                tradeAmount = investAmount + loan.amount - fee.trading - feeLending;
                            }
                            profit.loanAmount = loan.amount = tradeAmount - investAmount + fee.trading + feeLending;
                            debt = _getDebtAmount(loan, profit.expiryDate, 0);
                        }
                    }

                    uint revenue = _getRevenue(tradeAmount, profit.expiryDate, pairs, trade);
                    if (revenue > investAmount + debt) {
                        profit.amount = revenue - investAmount - debt;
                    } else {
                        profit.loanAmount = 0;
                    }
                }
            }
        }
    }

    function _getPairs(address futureContract) internal view returns (address[] memory pairs) {
        address token0 = IFutureContract(futureContract).token0();
        address token1 = IFutureContract(futureContract).token1();
        pairs = new address[](2);
        if (token0 == usdc || token1 == usdc) {
            (pairs[0], pairs[1]) = token0 == usdc ? (usdc, token1) : (usdc, token0);
        }
    }

    function _getOptimizeTradeAmount(uint expiryDate, address[] memory pairs, TradeInfo memory trade)
        internal view returns (uint tradeAmount)
    {
        uint reserveAExchange; uint reserveBExchange;
        address pair = IExchangeFactory(IExchangeRouter(trade.exchange).factory()).getPair(usdc, pairs[1]);
        if (IExchangePair(pair).token0() == usdc) {
            (reserveAExchange, reserveBExchange) = IExchangePair(pair).getReserves();
        } else {
            (reserveBExchange, reserveAExchange) = IExchangePair(pair).getReserves();
        }

        uint reserveAFutureExchange; uint reserveBFutureExchange;
        address futureFactory = IFutureExchangeRouter(trade.futureExchange).futureTokenFactory();
        if (IFutureContract(trade.futureContract).token0() == usdc) {
            (reserveAFutureExchange, reserveBFutureExchange) = PrecogV2Library.getReservesFuture(futureFactory, usdc, pairs[1], expiryDate);
        } else {
            (reserveBFutureExchange, reserveAFutureExchange) = PrecogV2Library.getReservesFuture(futureFactory, usdc, pairs[1], expiryDate);
        }

        uint sqrtK;
        unchecked {
            uint k = reserveAExchange * reserveBExchange * reserveAFutureExchange * reserveBFutureExchange;
            sqrtK = (k / (reserveAExchange * reserveBExchange) == (reserveAFutureExchange * reserveBFutureExchange))
                ? sqrtK = sqrt(k)
                : sqrt(reserveAExchange * reserveBExchange) * sqrt(reserveAFutureExchange * reserveBFutureExchange);
        }

         if (sqrtK > reserveAExchange * reserveAFutureExchange && reserveAFutureExchange + reserveBExchange != 0) {
             tradeAmount = (sqrtK - reserveAExchange * reserveAFutureExchange) / (reserveAFutureExchange + reserveBExchange);
         }
    }

    function _getRevenue(uint amount, uint expiryDate, address[] memory pairs, TradeInfo memory trade)
        internal view returns (uint revenue)
    {
        IExchangeRouter exchange = IExchangeRouter(trade.exchange);
        IFutureExchangeRouter futureExchange = IFutureExchangeRouter(trade.futureExchange);
        try exchange.getAmountsOut(amount, pairs) returns(uint[] memory amountsOut) {
            try futureExchange.getAmountsOutFuture(amountsOut[1], pairs[1], usdc, expiryDate) returns(uint _revenue) {
                revenue = _revenue;
            } catch {}
        } catch {}
    }

    function _getDebtAmount(BorrowInfo memory loan, uint endTime, uint endBlock) internal view returns(uint) {
        return ILending(lendingContract).getDebtAmount(
            loan.platformIndex, usdc, loan.amount,
            loan.startTime, endTime, loan.startBlock, endBlock);
    }

    function invest(
        address user,
        uint256 investAmount,
        TradeInfo memory trade,
        uint256 platformIndex,
        uint256 borrowAmount
    ) external {
        require(investAmount <= availableAmount[user], "PrecogV2: AVAILABLE_AMOUNT_NOT_ENOUGH");
        FeeInfo memory fee = FeeInfo(_swapFee(feeTradingByEth), _convertEthToUsdc(feeLendingByEth));
        BorrowInfo memory loan = _getBorrowForTrade(investAmount, borrowAmount, platformIndex);

        uint tradeAmount = investAmount - fee.trading;
        uint expiryDate = IFutureContract(trade.futureContract).expiryDate();
        uint debt;
        if (loan.amount > 0) {
            debt = _getDebtAmount(loan, expiryDate, 0);
            uint interest = debt - loan.amount;
            ILending(lendingContract).createLoan(platformIndex, usdc, loan.amount);
            emit Borrow(user, trade.futureContract, loan.platformIndex, loan.amount, interest, fee.lending);

            tradeAmount += loan.amount;
            if (userBorrowInfo[user][trade.futureContract].length == 0) {
                tradeAmount -= _swapFee(feeLendingByEth);
            }
            userBorrowInfo[user][trade.futureContract].push(loan);
        }

        uint revenue = _executeTrade(tradeAmount, expiryDate, trade);
        require(revenue > investAmount + debt, "PrecogV2: NOT_PROFITABLE");
        uint profit = revenue - investAmount - debt;

        _updateTradingAmount(user, trade.futureContract, investAmount, revenue);
        _removeTradingUser(user);

        emit Trade(user, trade.futureContract, expiryDate, investAmount, profit, fee.trading, block.timestamp);
    }

    function _getBorrowForTrade(uint amount, uint borrowAmount, uint platformIndex)
        internal view returns (BorrowInfo memory loan)
    {
        if (platformIndex != 0) {
            uint256 borrowLimit = amount * borrowRateLimit / 100;
            loan = _getAvailableLoan(platformIndex, borrowLimit);
            require(borrowAmount <= loan.amount, "PrecogV2: BORROW_AMOUNT_EXCEED_LIMIT");
            loan.amount = borrowAmount;
        }
    }

    function _executeTrade(uint amount, uint expiryDate, TradeInfo memory trade) internal returns(uint) {
        address[] memory pairs = _getPairs(trade.futureContract);
        uint256[] memory amounts = IExchangeRouter(trade.exchange).getAmountsOut(amount, pairs);

        uint allowance = IERC20(pairs[1]).allowance(address(this), trade.futureExchange);
        if (allowance < amounts[1]) {
            IERC20(pairs[1]).approve(trade.futureExchange, type(uint256).max);
        }

        // Swap USDC->Token
        IExchangeRouter exchange = IExchangeRouter(trade.exchange);
        exchange.swapExactTokensForTokens(amount, amounts[1], pairs, address(this), expiryDate);
        // Swap Token->USDC Future
        IFutureExchangeRouter futureExchange = IFutureExchangeRouter(trade.futureExchange);
        return futureExchange.swapFuture(pairs[1], pairs[0], expiryDate, address(this), amounts[1]);
    }

    function _updateTradingAmount(address user, address futureContract, uint amount, uint revenue) internal {
        totalTradingAmount[user] += amount;
        tradingAmount[user][futureContract] += amount;
        investAmount[user] += amount;
        availableAmount[user] -= amount;
        revenueAmount[user][futureContract] += revenue;
    }

    function sqrt(uint256 x) internal pure returns (uint256) {
        uint256 n = x / 2;
        uint256 lstX = 0;
        while (n != lstX) {
            lstX = n;
            n = (n + x / n) / 2;
        }
        return uint256(n);
    }
}

pragma solidity >=0.6.2;

interface IExchangeFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

pragma solidity >=0.6.2;

interface IExchangePair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1);
}

pragma solidity >=0.6.2;

interface IExchangeRouter {
    function factory() external view returns (address);
    function WETH() external view returns (address);

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

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}
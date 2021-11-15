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
    
    function getAmountsOutFuture(uint256 amountIn, address tokenIn, address tokenOut, uint256 expiryDate) external view returns (uint256);
    
    function getAmountsInFuture(uint256 amountOut, address tokenIn, address tokenOut, uint256 expiryDate) external view returns (uint256);
    
    function addLiquidityFuture(address tokenA, address tokenB, uint256 amountA, uint256 amountB, uint256 expiryDate, string memory symbol) external;
    
    function withdrawLiquidityFuture(address tokenA, address tokenB, uint256 expiryDate, address to, uint256 amount) external;
    
    function swapFuture(address tokenA, address tokenB, uint expiryDate, address to, uint amount) external;
    
    function closeFuture(address tokenA, address tokenB, uint expiryDate, address to, uint amount) external;
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
    function getLendingPlatforms(uint platformIndex) external view returns (address);
    function lendingPlatformsCount() external view returns (uint);
    function getLendingPlatformInfo(uint platformIndex, address loanToken) external view returns (uint, uint);
    function createLoan(uint platformIndex, address borrowToken, uint borrowAmount) external;
    function repayLoan(uint platformIndex, address borrowToken, uint repayAmount) external;
}

pragma solidity ^0.8.0;
import "./interfaces/IExchangeRouter.sol";
import "./interfaces/IPrecog.sol";
import "../future-exchange/interfaces/IFutureExchangeRouter.sol";
import "../future-token/interfaces/IFutureToken.sol";
import "../future-token/interfaces/IFutureTokenFactory.sol";
import "../future-token/interfaces/IFutureContract.sol";
import "../lending-platform/interfaces/ILending.sol";
import "../common/interfaces/IERC20.sol";
import "../common/interfaces/IOwnable.sol";
import "../future-token/interfaces/IFutureContract.sol";
import "../lending-platform/interfaces/ILending.sol";
import "../lending-platform/interfaces/DataTypes.sol";

contract Precog is IPrecog {

    struct BorrowInfo {
        uint platformIndex;
        uint borrowAmount;
        uint interestRate;
        uint timestamp;
    }
    
    struct TradeInfo {
        address exchange;
        address futureExchange;
        address futureContract;
    }

    address public usdc;
    address public weth;
    address public tradingService;
    address public adminAddress;
    address public lendingContract;
    
    uint256 public feeWithdrawByUSDC = 2e6; // 2 USDC
    uint256 public feeTradingByEth = 5e15; // 0.005 ETH
    uint256 public feeLendingByEth = 5e15; // 0.005 ETH
    uint256 public borrowRateLimit = 70; // 70%
    
    address[] futureExchanges;
    address[] exchanges;
    mapping(address => uint256) futureExchangeIndex;
    mapping(address => uint256) exchangeIndex;
    
    mapping(address => uint256) availableAmount;
    mapping(address => uint256) investAmount;
    mapping(address => uint256) tradingAmount;
    mapping(address => uint256) profitAmount;
    mapping(address => mapping(address => uint256)) tradingAmountOnFutureContract;
    mapping(address => mapping(address => uint256)) profitAmountOnFutureContract;
    mapping(address => mapping(address => uint256)) liquidatedAmount;
    
    address[] tradeUsers;
    mapping(address => uint256) tradeUserIndex;
    mapping(address => mapping(address => BorrowInfo[])) userBorrowInfo;
    
    event Deposit(address indexed user, uint256 amount, uint256 indexed timestamp);
    event Withdraw(address indexed user, uint256 amount, uint256 fee, uint256 indexed timestamp);
    event Trade(
        address indexed user, 
        address indexed futureContract, 
        uint256 deadline, 
        uint256 amount, 
        uint256 profit, 
        uint256 fee, 
        uint256 indexed timestamp,
        uint256 lendingPlatformIndex
    );
    
    event Liquidate(address indexed user, address indexed futureToken, uint256 indexed timestamp);
    
    modifier onlyAdminAddress() {
        require(msg.sender == adminAddress, "PrecogV2: NOT_ADMIN_ADDRESS");
        _;
    }

    constructor(address _usdc, address _weth, address _tradingService, address _adminAddress) {
        usdc = _usdc;
        weth = _weth;
        tradingService = _tradingService;
        adminAddress = _adminAddress;
    }
    
    function setFeeWithdrawByUSDC(uint256 fee) external onlyAdminAddress {
        feeWithdrawByUSDC = fee;
    }

    function setFeeTradingByETH(uint256 fee) external onlyAdminAddress {
        feeTradingByEth = fee;
    }
    
    function updateLendingFeeByEth(uint256 fee) external onlyAdminAddress {
        feeLendingByEth = fee;
    }
       
    function setBorrowRateLimit(uint256 borrowRate) external onlyAdminAddress {
        borrowRateLimit = borrowRate;
    }
    
    function setLending(address lending) external onlyAdminAddress {
        lendingContract = lending;
    }
    
    function tradeAvailableUsers() external view returns(address[] memory) {
        return tradeUsers;
    }
    
    function getFutureExchanges(uint256 index) external view override returns (address) {
        return futureExchanges[index];
    }
    
    function getExchanges(uint256 index) external view override returns (address) {
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
    
    function getLiquidatedAmount(address user, address futureContract) external view override returns (uint256){
        return liquidatedAmount[user][futureContract];
    }
    
    function getAvailableAmount(address user) external view override returns (uint256){
        return availableAmount[user];
    }
    
    function getInvestAmount(address user) external view override returns (uint256){
        return investAmount[user];
    }

    function getTradingAmount(address user) external view override returns (uint256){
        return tradingAmount[user];
    }
    
    function getProfitAmount(address user) external view override returns (uint256){
        return profitAmount[user];
    }
    
    function getTradingAmountOnFutureContract(address user, address futureContract) external view override returns (uint256){
        return tradingAmountOnFutureContract[user][futureContract];
    }
    
    function getProfitAmountOnFutureContract(address user, address futureContract) external view override returns (uint256){
        return profitAmountOnFutureContract[user][futureContract];
    }

    function getTradeUserIndex(address user) external view override returns (uint256){
        return tradeUserIndex[user];
    }
    
    function getUserBorrowInfo(address user, address futureContract) external view returns(BorrowInfo[] memory){
        return userBorrowInfo[user][futureContract];
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
        IERC20(usdc).transfer(adminAddress, feeWithdrawByUSDC);
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
        uint amount = this.liquidate(futureContract, user) - feeWithdrawByUSDC;
        IERC20(usdc).transfer(to, amount);
        IERC20(usdc).transfer(adminAddress, feeWithdrawByUSDC);
        emit Withdraw(msg.sender, amount, feeWithdrawByUSDC, block.timestamp);
    }
    
    function reinvest(address futureContract, address user) external {
        uint amount = this.liquidate(futureContract, user);
        availableAmount[msg.sender] += amount;
        _addTradingUser();
    }
    
    function liquidate(address futureContract, address user) external returns(uint256 amount) {
        require(tradingAmount[user] > 0, "PrecogV2: TRADING_AMOUNT_NOT_ENOUGH");
        require(liquidatedAmount[user][futureContract] == 0, "PrecogV2: ALREADY_LIQUIDATED");
        address tokenA = IFutureContract(futureContract).token0();
        address tokenB = IFutureContract(futureContract).token1();
        require(tokenA == usdc || tokenB == usdc, "PrecogV2: INVALID_TOKEN");
        
        address tokenInvest = tokenA == usdc ? tokenB : tokenA; 
        uint256 expiryDate = IFutureContract(futureContract).expiryDate();
        address futureFactory = IOwnable(futureContract).owner();
        address futureExchange = IFutureTokenFactory(futureFactory).exchange();
        address futureToken = IFutureTokenFactory(futureFactory).getFutureToken(tokenInvest, usdc, expiryDate);
        amount = tradingAmountOnFutureContract[user][futureContract] + profitAmountOnFutureContract[user][futureContract];
        
        uint256 allowance = IERC20(futureToken).allowance(address(this), futureExchange);
        if (allowance < amount) {
            IERC20(futureToken).approve(futureExchange, type(uint256).max);
        }
        
        BorrowInfo[] memory loans = userBorrowInfo[user][futureContract];
        if (loans.length > 0) {
            for (uint i = 0; i < loans.length; i++) {
                ILending(lendingContract).repayLoan(loans[i].platformIndex, usdc, loans[i].borrowAmount);
                userBorrowInfo[user][futureContract][i].borrowAmount = 0;
            }
        }
        
        IFutureExchangeRouter(futureExchange).closeFuture(tokenInvest, usdc, expiryDate, address(this), amount);
        
        tradingAmount[user] -= tradingAmountOnFutureContract[user][futureContract];
        profitAmount[user] -= profitAmountOnFutureContract[user][futureContract];
        liquidatedAmount[user][futureContract] = tradingAmount[user] + profitAmount[user];
        tradingAmountOnFutureContract[user][futureContract] = 0;
        profitAmountOnFutureContract[user][futureContract] = 0;
        
        emit Liquidate(msg.sender, futureContract, block.timestamp);
    }
    
    function _swapTradingFee() internal returns(uint usedUsdc) {
        address[] memory pair = new address[](2);
        pair[0] = usdc;
        pair[1] = weth;

        uint256 deadline = block.timestamp + 3600;

        (address exchange, uint256 feeTradingUsdc) = _selectBestPriceExchange(pair, feeTradingByEth);
        if (address(exchange) != address(0)) {
            uint[] memory amounts = IExchangeRouter(exchange).swapTokensForExactETH(feeTradingByEth, feeTradingUsdc, pair, tradingService, deadline);
            return (amounts[0]);
        }
    }

    function _selectBestPriceExchange(address[] memory pair, uint256 amount)
        internal
        view
        returns (address selected, uint256 inAmount)
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

    function maxProfitable(address user) public view returns (
        uint256 amount, 
        uint256 profit, 
        TradeInfo memory tradeInfo,
        BorrowInfo memory borrowInfo
    ) {
        uint256 feeTradingUsdc = _convertEthToUsdc(feeTradingByEth);
        if (availableAmount[user] > feeTradingUsdc) {
            amount = availableAmount[user] - feeTradingUsdc;
            BorrowInfo[] memory loans = _getAvailableLoans(amount);
            for (uint k = 0; k < futureExchanges.length; k++) {
                address[] memory futureContracts = IFutureExchangeRouter(futureExchanges[k]).getListFutureContractsInPair(usdc);
                for (uint j = 0; j < futureContracts.length; j++) {
                    for (uint i = 0; i < exchanges.length; i++) {
                        for (uint l = 0; l < loans.length; l++) {
                            TradeInfo memory _tradeInfo = TradeInfo(exchanges[i], futureExchanges[k], futureContracts[j]);
                            (uint _profit,,) = _calculateProfit(user, amount, _tradeInfo, loans[l]);
                            if (_profit > profit) {
                                profit = _profit;
                                tradeInfo = _tradeInfo;
                                if (loans[l].borrowAmount > 0) {
                                    borrowInfo = loans[l];
                                }
                            }
                        }
                    }       
                }
            }
            amount = availableAmount[user];
        }
    }

    function _getAvailableLoans(uint amount) internal view returns (BorrowInfo[] memory loans) {
        uint borrowLimit = amount * borrowRateLimit / 100;
        uint platformCount = ILending(lendingContract).lendingPlatformsCount();
        loans = new BorrowInfo[](platformCount);
        for (uint i = 0; i < platformCount; i++) {
            loans[i] = _getAvailableLoan(i + 1, borrowLimit);
        }
    }

    function _getAvailableLoan(uint platformIndex, uint borrowLimit) internal view returns (BorrowInfo memory loan) {
        (uint availableBorrowAmount, uint interestRate) = ILending(lendingContract).getLendingPlatformInfo(platformIndex, usdc);
        uint borrowAmount = availableBorrowAmount < borrowLimit
            ? availableBorrowAmount
            : borrowLimit;
        loan = BorrowInfo(platformIndex, borrowAmount, interestRate, block.timestamp);
    }

    function _calculateProfit(
        address user,
        uint256 amount,
        TradeInfo memory tradeInfo,
        BorrowInfo memory loan
    ) view internal returns (
        uint256 profit, 
        address[] memory pairs, 
        uint256 tradeAmount
    ) {
        uint256 expiryDate = IFutureContract(tradeInfo.futureContract).expiryDate();
        if (expiryDate > block.timestamp) {
            pairs = _getPairs(tradeInfo.futureContract);
            if (pairs[0] != address(0)) {
                try IExchangeRouter(tradeInfo.exchange).getAmountsOut(amount + loan.borrowAmount, pairs) returns(uint[] memory amountsOut) {
                    tradeAmount = amountsOut[1];
                    uint revenue = IFutureExchangeRouter(tradeInfo.futureExchange).getAmountsOutFuture(tradeAmount, pairs[1], usdc, expiryDate);
                    uint loanAmount = loan.borrowAmount * ((expiryDate - block.timestamp) * loan.interestRate) / 100;
                    if (revenue > availableAmount[user] + loanAmount) {
                        profit = revenue - availableAmount[user] - loanAmount;
                    }
                } catch {}    
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

    function _convertEthToUsdc(uint amount) internal view returns(uint) {
        address[] memory pair = new address[](2);
        pair[0] = usdc;
        pair[1] = weth;
        (, uint256 feeTradingUsdc) = _selectBestPriceExchange(pair, amount);
        return feeTradingUsdc;
    }

    function invest(
        address user,
        uint256 amount,
        TradeInfo memory tradeInfo,
        uint256 lendingPlatformIndex,
        uint256 borrowAmount
    ) external {
        require(availableAmount[user] >= amount, "PrecogV2: AVAILABLE_AMOUNT_NOT_ENOUGH");
        uint256 feeTradingUsdc = _swapTradingFee();
        amount -= feeTradingUsdc;
        
        BorrowInfo memory loan = _borrowForTrade(amount, borrowAmount, lendingPlatformIndex);
        (uint profit, uint expiryDate) = _executeTrade(user, amount, tradeInfo, loan);

        _updateAmount(user, tradeInfo.futureContract, amount, profit, feeTradingUsdc);
        _removeTradingUser(user);
        
        emit Trade(user, tradeInfo.futureContract, expiryDate, amount, profit, feeTradingUsdc, block.timestamp, lendingPlatformIndex);
    }

    function _borrowForTrade(uint amount, uint borrowAmount, uint platformIndex) internal returns (BorrowInfo memory loan) {
        if (platformIndex != 0) {
            uint256 borrowLimit = amount * borrowRateLimit / 100;
            loan = _getAvailableLoan(platformIndex, borrowLimit);
            require(borrowAmount <= loan.borrowAmount, "PrecogV2: BORROW_AMOUNT_EXCEED_LIMIT");
        
            loan.borrowAmount = borrowAmount;
            ILending(lendingContract).createLoan(platformIndex, usdc, borrowAmount);
        }
    }
    
    function _executeTrade(address user, uint amount, TradeInfo memory tradeInfo, BorrowInfo memory loan) internal returns (uint, uint) {
        (uint256 profit, address[] memory pairs, uint256 tradeAmount) = _calculateProfit(user, amount, tradeInfo, loan);
        require(profit > 0, "PrecogV2: NOT_PROFITABLE");
        
        uint256 allowance = IERC20(pairs[1]).allowance(address(this), tradeInfo.futureExchange);
        if (allowance < tradeAmount) {
            IERC20(pairs[1]).approve(tradeInfo.futureExchange, type(uint256).max);
        }
        
        uint expiryDate = IFutureContract(tradeInfo.futureContract).expiryDate();        
        // Swap USDC->Token
        IExchangeRouter(tradeInfo.exchange).swapExactTokensForTokens(amount, tradeAmount, pairs, address(this), expiryDate);
        // Swap Token->USDC Future
        IFutureExchangeRouter(tradeInfo.futureExchange).swapFuture(pairs[1], pairs[0], expiryDate, address(this), tradeAmount);
        return (profit, expiryDate);
    }
    
    function _updateBorrowInfo(address user, address futureContract, BorrowInfo memory loan) internal {
        if (loan.platformIndex > 0) {
            userBorrowInfo[user][futureContract].push(loan);
        }
    }

    function _updateAmount(address user, address futureContract, uint amount, uint profit, uint fee) internal {
        investAmount[user] += amount + fee;
        tradingAmount[user] += amount + fee;
        tradingAmountOnFutureContract[user][futureContract] += amount + fee;
        profitAmount[user] += profit;
        profitAmountOnFutureContract[user][futureContract] += profit;
        availableAmount[user] -= amount + fee;
    }
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

pragma solidity ^0.8.0;

interface IPrecog {
    function getFutureExchanges(uint256 index) external view returns (address);
    
    function getExchanges(uint256 index) external view returns (address);
    
    function getAvailableAmount(address user) external view returns (uint256);
    
    function getInvestAmount(address user) external view returns (uint256);

    function getTradingAmount(address user) external view returns (uint256);
    
    function getProfitAmount(address user) external view returns (uint256);
    
    function getTradingAmountOnFutureContract(address user, address futureContract) external view returns (uint256);
    
    function getProfitAmountOnFutureContract(address user, address futureContract) external view returns (uint256);
    
    function getLiquidatedAmount(address user, address futureContract) external view returns (uint256);

    function getTradeUserIndex(address user) external view returns (uint256);
}


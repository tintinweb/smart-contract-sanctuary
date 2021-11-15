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
import "./interfaces/IExchangeRouter.sol";
import "./interfaces/IPrecog.sol";
import "../future-exchange/interfaces/IFutureExchangeRouter.sol";
import "../future-token/interfaces/IFutureToken.sol";
import "../future-token/interfaces/IFutureTokenFactory.sol";
import "../common/interfaces/IERC20.sol";
import "../common/interfaces/IOwnable.sol";
import "../future-token/interfaces/IFutureContract.sol";

contract Precog is IPrecog {
    address public usdc;
    address public weth;
    address public tradingService;
    address public adminAddress;
    
    uint256 public feeWithdrawByUSDC = 2e6; // 2 USDC
    uint256 public feeTradingByEth = 5e15; // 0.005 ETH

    address[] futureExchanges;
    address[] exchanges;
    mapping(address => uint256) futureExchangeIndex;
    mapping(address => uint256) exchangeIndex;

    mapping(address => uint256) availableAmount;
    mapping(address => uint256) investAmount;
    mapping(address => uint256) tradingAmount;
    mapping(address => uint256) profitAmount;
    mapping(address => mapping(address => uint256)) tradingAmountOnFutureToken;
    mapping(address => mapping(address => uint256)) profitAmountOnFutureToken;
    
    address[] tradeUsers;
    mapping(address => uint256) tradeUserIndex;
    
    event Deposit(address indexed user, uint256 amount, uint256 indexed timestamp);
    event Withdraw(address indexed user, uint256 amount, uint256 fee, uint256 indexed timestamp);
    event Trade(
        address indexed user, 
        address indexed futureToken, 
        uint256 deadline, 
        uint256 amount, 
        uint256 profit, 
        uint256 fee, 
        uint256 indexed timestamp
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
    
    function setFeeWithdrawByUSDC(uint256 fee) external onlyAdminAddress{
        feeWithdrawByUSDC = fee;
    }

    function setFeeTradingByETH(uint256 fee) external onlyAdminAddress{
        feeTradingByEth = fee;
    }
    
    function tradeAvailableUsers() external view returns(address[] memory) {
        return tradeUsers;
    }
    
    function getFutureExchanges(uint256 index) external view override returns (address){
        return futureExchanges[index];
    }
    
    function getExchanges(uint256 index) external view override returns (address){
        return exchanges[index];
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
    
    function getTradingAmountOnFutureToken(address user, address futureToken) external view override returns (uint256){
        return tradingAmountOnFutureToken[user][futureToken];
    }
    
    function getProfitAmountOnFutureToken(address user, address futureToken) external view override returns (uint256){
        return profitAmountOnFutureToken[user][futureToken];
    }

    function getTradeUserIndex(address user) external view override returns (uint256){
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

    function withdrawLiquidate(address futureContract, address to) external {
        uint amount = _liquidate(futureContract) - feeWithdrawByUSDC;
        IERC20(usdc).transfer(to, amount);
        IERC20(usdc).transfer(adminAddress, feeWithdrawByUSDC);
        emit Withdraw(msg.sender, amount, feeWithdrawByUSDC, block.timestamp);
    }
    
    function reinvest(address futureContract) external {
        uint amount = _liquidate(futureContract);
        availableAmount[msg.sender] += amount;
        _addTradingUser();
    }
    
    function _liquidate(address futureContract) internal returns(uint256 amount) {
        require(tradingAmount[msg.sender] > 0, "PrecogV2: TRADING_AMOUNT_NOT_ENOUGH");
        
        address tokenA = IFutureContract(futureContract).token0();
        address tokenB = IFutureContract(futureContract).token1();
        require(tokenA == usdc || tokenB == usdc, "PrecogV2: INVALID_TOKEN");
        
        address tokenInvest = tokenA == usdc ? tokenB : tokenA; 
        uint256 expiryDate = IFutureContract(futureContract).expiryDate();
        address futureFactory = IOwnable(futureContract).owner();
        address futureExchange = IFutureTokenFactory(futureFactory).exchange();
        address futureToken = IFutureTokenFactory(futureFactory).getFutureToken(tokenA, tokenB, expiryDate);
        amount = tradingAmountOnFutureToken[msg.sender][futureToken] + profitAmountOnFutureToken[msg.sender][futureToken];
        
        uint256 allowance = IERC20(futureToken).allowance(address(this), futureExchange);
        if (allowance < amount) {
            IERC20(futureToken).approve(futureExchange, type(uint256).max);
        }
        
        IFutureExchangeRouter(futureExchange).closeFuture(tokenInvest, usdc, expiryDate, address(this), amount);
        
        tradingAmount[msg.sender] -= tradingAmountOnFutureToken[msg.sender][futureToken];
        profitAmount[msg.sender] -= profitAmountOnFutureToken[msg.sender][futureToken];
        tradingAmountOnFutureToken[msg.sender][futureToken] = 0;
        profitAmountOnFutureToken[msg.sender][futureToken] = 0;
        
        emit Liquidate(msg.sender, futureToken, block.timestamp);
    }
    
    function _swapTradingFee() internal {
        address[] memory pair = new address[](2);
        pair[0] = usdc;
        pair[1] = weth;

        uint256 deadline = block.timestamp + 3600;

        (address exchange, uint256 feeTradingUsdc) = _selectBestPriceExchange(pair, feeTradingByEth);
        if (address(exchange) != address(0)) {
            IExchangeRouter(exchange).swapTokensForExactETH(feeTradingByEth, feeTradingUsdc, pair, tradingService, deadline);
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
        uint amount, uint profit, address exchange, address futureExchange, address futureContract
    ) {
        uint256 feeTradingUsdc = _convertEthToUsdc(feeTradingByEth);
        if (availableAmount[user] > feeTradingUsdc) {
            amount = availableAmount[user] - feeTradingUsdc;
            for (uint k = 0; k < futureExchanges.length; k++) {
                IFutureExchangeRouter _futureExchange = IFutureExchangeRouter(futureExchanges[k]);
                address[] memory futureContracts = _futureExchange.getListFutureContractsInPair(usdc);
                for (uint j = 0; j < futureContracts.length; j++) {
                    IFutureContract _futureContract = IFutureContract(futureContracts[j]);
                    for (uint i = 0; i < exchanges.length; i++) {
                        IExchangeRouter _exchange = IExchangeRouter(exchanges[i]);
                        (uint _profit,,) = _calculateProfit(user, amount, _exchange, _futureExchange, _futureContract);
                        if (_profit > profit) {
                            profit = _profit;
                            exchange = exchanges[i];
                            futureContract = futureContracts[j];
                            futureExchange = futureExchanges[k];
                        }
                    }       
                }
            }
            amount = availableAmount[user];
        }
    }

    function _calculateProfit(
        address user,
        uint256 amount,
        IExchangeRouter exchange,
        IFutureExchangeRouter futureExchange,
        IFutureContract futureContract
    ) view internal returns(uint profit, address[] memory pairs, uint tradeAmount) {
        uint256 expiryDate = futureContract.expiryDate();
        if (expiryDate > block.timestamp) {
            address token0 = futureContract.token0();
            address token1 = futureContract.token1();
            
            if (token0 == usdc || token1 == usdc) {
                pairs = new address[](2);
                (pairs[0], pairs[1]) = token0 == usdc ? (usdc, token1) : (usdc, token0);
                
                try exchange.getAmountsOut(amount, pairs) returns(uint[] memory amountsOut) {
                    tradeAmount = amountsOut[1];
                    uint revenue = futureExchange.getAmountsOutFuture(tradeAmount, pairs[1], usdc, expiryDate);
                    if (revenue > availableAmount[user]) {
                        profit = revenue - availableAmount[user];
                    }
                } catch {}    
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

    function invest(
        address user,
        uint256 amount,
        IExchangeRouter exchange, 
        IFutureExchangeRouter futureExchange,
        IFutureContract futureContract
    ) external {
        require(availableAmount[user] >= amount, "PrecogV2: AVAILABLE_AMOUNT_NOT_ENOUGH");
        uint256 feeTradingUsdc = _convertEthToUsdc(feeTradingByEth);
        require(amount > feeTradingUsdc, "PrecogV2: AVAILABLE_AMOUNT_NOT_ENOUGH_FOR_FEE");
        amount = amount - feeTradingUsdc;
        (uint256 profit, address[] memory pairs, uint256 tradeAmount) = _calculateProfit(user, amount, exchange, futureExchange, futureContract);
        require(profit > 0, "PrecogV2: NOT_PROFITABLE");
        
        uint256 allowance = IERC20(pairs[1]).allowance(address(this), address(futureExchange));
        if (allowance < tradeAmount) {
            IERC20(pairs[1]).approve(address(futureExchange), type(uint256).max);
        }
        
        uint256 expiryDate = futureContract.expiryDate();
        exchange.swapExactTokensForTokens(amount, tradeAmount, pairs, address(this), expiryDate);
        futureExchange.swapFuture(pairs[1], pairs[0], expiryDate, address(this), tradeAmount);
        
        investAmount[user] += amount + feeTradingUsdc;
        tradingAmount[user] += amount + feeTradingUsdc;
        tradingAmountOnFutureToken[user][address(futureContract)] += amount + feeTradingUsdc;
        profitAmount[user] += profit;
        profitAmountOnFutureToken[user][address(futureContract)] += profit;
        availableAmount[user] -= amount + feeTradingUsdc;
        
        _swapTradingFee();
        _removeTradingUser(user);
        
        emit Trade(user, address(futureContract), expiryDate, amount, profit, feeTradingUsdc, block.timestamp);
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
    
    function getTradingAmountOnFutureToken(address user, address futureToken) external view returns (uint256);
    
    function getProfitAmountOnFutureToken(address user, address futureToken) external view returns (uint256);

    function getTradeUserIndex(address user) external view returns (uint256);
}


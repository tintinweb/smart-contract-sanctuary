pragma solidity ^0.8.0;
import "../common/interfaces/IERC20.sol";
import "./interfaces/exchange-router.sol";
import "../common/interfaces/InterfaceIPCOG.sol";
import "../common/interfaces/InterfacePCOG.sol";
import "./interfaces/IPrecogv4.sol";

contract PrecogV4 {
    
    struct TradeInfo {
        uint256 profit;
        uint256 amountPCOGBought;
        uint256 startTime;
        uint256 endTime;
    }

    struct WithdrawInfo {
        address token;
        uint256 amountLiquidityToken;
    }

    struct DebtInfo {
        address account;
        uint256 debtAmount;
    }

    mapping(address => uint256) currentDebtNotPay;

    mapping(address => uint256) public totalDebtsAmount;
    mapping(address => DebtInfo[]) paybook;
    mapping(address => mapping(address => uint256)) userDebt;

    mapping(address => TradeInfo[]) tradingSessions;


    address public admin;
    address public tradingService;
    address public exchange;
    address public IPCOG;
    address public PCOG;

    mapping(address => bool) public isExistingToken;
    address[] public existingTokens;

    uint256 public feeWithdrawByDecimalBased = 0;
    uint256 public feeDepositByDecimalBased = 0;
    uint256 public feeTradingByDecimalBased = 0; //charge based on 10 power decimal
    uint256 public feeLendingByDecimalBased = 0; 
    uint16 public decimalBased = 18;
    mapping(address => uint256) public totalFeeDeposit;
    mapping(address => uint256) public totalFeeWithdraw;
    mapping(address => uint256) public totalFeeTrading;
    mapping(address => uint256) public totalFeeLending;

    
    mapping(address => mapping(address => uint256)) liquidity;
    uint256 public totalLiquidity;
    uint256 public profit; //total amount PCOG profit

    modifier onlyAdmin() {
        require(msg.sender == admin, "PrecogV4: NOT_ADMIN_ADDRESS");
        _;
    }
    modifier onlyTradingService() {
        require(msg.sender == tradingService, "PrecogV4: NOT_TRADING_SERVICE_ADDRESS");
        _;
    }

    event Deposit(
        address indexed account,
        address indexed token,
        address indexed IPCOG,
        uint256 amount,
        uint256 amountIPCOG
    );

    event Withdraw(
        address indexed account,
        address indexed to,
        address indexed token,
        address IPCOG,
        address PCOG,
        uint256 amountIPCOGBurn,
        uint256 amountTokenReceive,
        uint256 profitPCOG
    );

    event WithdrawFee(
        address indexed admin,
        address indexed token,
        uint256 totalFeeDeposit,
        uint256 totalFeeWithdraw,
        uint256 totalFeeTrading,
        uint256 totalFeeLending
    );

    event AddLiquidityPool(
        address indexed admin,
        address indexed token, 
        address indexed IPCOG
    );

    event RemoveLiquidityPool(
        address indexed admin,
        address indexed token, 
        address indexed IPCOG
    );

    event UpdateTradingStatus(
        address indexed tradingService,
        address indexed token,
        address PCOG,
        uint256 profit,
        uint256 amountPCOGBought,
        uint16 APY,
        uint16 APYDecimal,
        uint256 endTime,
        uint256 indexed startTime
    );

    event TransferAdmin(address indexed lastAdmin, address indexed newAdmin);

    event SetTradingService(
        address indexed admin,
        address indexed newTradingService
    );

    event SetExchange(
        address indexed admin, 
        address indexed newExchange
    );

    event SetDecimalBased(
        address indexed admin,
        uint16 indexed newDecimalBased
    );

    event SetFeeDeposit(
        address indexed admin, 
        uint256 feeDepositByDecimalBased, 
        uint16 decimalBased
    );

    event SetFeeWithdraw(
        address indexed admin, 
        uint256 feeWithdrawByDecimalBased, 
        uint16 decimalBased
    );

    event SetFeeTrading(
        address indexed admin, 
        uint256 feeTradingByDecimalBased, 
        uint16 decimalBased
    );

    event SetFeeLending(
        address indexed admin,
        uint256 feeLendingByDecimalBased, 
        uint16 decimalBased
    );

    event CreateDebt(
        address indexed account,
        address indexed token,
        uint256 indexed amount
    );

    event PayDebt(
        address indexed account,
        address indexed token,
        uint256 indexed amount
    );

    // constructor fields
    constructor(address _tradingService, address _exchange, address _IPCOG, address _PCOG, address _admin){
        tradingService = _tradingService;
        exchange = _exchange;
        IPCOG = _IPCOG;
        PCOG = _PCOG;
        admin = _admin;
    }

    function transferAdmin(address _admin) external onlyAdmin {
        emit TransferAdmin(admin, _admin);
        admin = _admin;
    }

    function setTradingService(address _tradingService) external onlyAdmin {
        tradingService = _tradingService;
        emit SetTradingService(admin, _tradingService);
    }

    function setExchange(address _exchange) external onlyAdmin {
        exchange = _exchange;
        emit SetExchange(admin, _exchange);
    }

    function isInTradingSession(address token) public view returns(bool) {
        if (tradingSessions[token].length == 0) return false;
        return tradingSessions[token][tradingSessions[token].length - 1].endTime > block.timestamp;
    }

    function getTradingSessions(address token) external view returns (TradeInfo[] memory) {
        return tradingSessions[token];
    }

    function getLastTradingSession(address token) external view returns (TradeInfo memory) {
        return tradingSessions[token][tradingSessions[token].length - 1];
    }

    function setDecimalBased(uint16 _decimal) external onlyAdmin {
        require(_decimal > 0, "PrecogV4: INVALID_DECIMAL_BASED");
        decimalBased = _decimal;
        emit SetDecimalBased(admin, _decimal);
    }

    function setFeeTrading(uint256 _newFee) external onlyAdmin {
        require(_newFee < 10 ** decimalBased, "PrecogV4: INVALID_NEW_FEE");
        feeTradingByDecimalBased = _newFee;
        emit SetFeeTrading(admin, feeTradingByDecimalBased, decimalBased);
    }

    function setFeeDeposit(uint256 _newFee) external onlyAdmin {
        require(_newFee < 10 ** decimalBased, "PrecogV4: INVALID_NEW_FEE");
        feeDepositByDecimalBased = _newFee; 
        emit SetFeeDeposit(admin, feeDepositByDecimalBased, decimalBased);
    }

    function setFeeWithdraw(uint256 _newFee) external onlyAdmin {
        require(_newFee < 10 ** decimalBased, "PrecogV4: INVALID_NEW_FEE");
        feeWithdrawByDecimalBased = _newFee;
        emit SetFeeWithdraw(admin, feeWithdrawByDecimalBased, decimalBased);
    }

    function setFeeLending(uint256 _newFee) external onlyAdmin {
        require(_newFee < 10 ** decimalBased, "PrecogV4: INVALID_NEW_FEE");
        feeLendingByDecimalBased = _newFee;
        emit SetFeeLending(admin, feeLendingByDecimalBased, decimalBased);
    }

    function getUserDebt(address token, address user) external view returns (uint256) {
        return userDebt[token][user];
    }

    function getLiquidity(address token) external view returns (uint256){
        return liquidity[token][IPCOG];
    }

    function getMaxWithdrawAmountIn(address from, address token) public view returns (uint256) {
        if (totalLiquidity <= 0) return 0;
        uint256 maxBurnableIP = liquidity[token][IPCOG] * 1e18 * IERC20(IPCOG).totalSupply() / (totalLiquidity * IERC20(token).decimals());
        return maxBurnableIP < IERC20(IPCOG).balanceOf(from) ? maxBurnableIP : IERC20(IPCOG).balanceOf(from);
    }

    function getWithdrawAmountIn(uint256 amountOut, address token) public view returns (uint256) {
        return amountOut * 1e18 * IERC20(IPCOG).totalSupply() / (totalLiquidity * 10 ** IERC20(token).decimals());
    }

    function getWithdrawAmountOut(uint256 amountIn, address token) public view returns (uint256) {
        if (IERC20(IPCOG).totalSupply() <= 0) return 0;
        return amountIn * totalLiquidity * 10 ** IERC20(token).decimals()/ (IERC20(IPCOG).totalSupply() * 1e18);
    }

    function getPaybook(address token) external view returns (DebtInfo[] memory) {
        return paybook[token];
    }

    function setPeriodTime(uint256 periodTime) external onlyAdmin {
        InterfaceIPCOG(IPCOG).setPeriodLockingTime(periodTime);
    } 

    function addLiqudityPool(address token) external onlyAdmin {
        require(token != address(0) && token != PCOG && token != IPCOG, "PrecogV4: INVALID_TOKEN_ADDRESS");
        require(!isExistingToken[token], "PrecogV4: TOKEN_IS_ALREADY_ADDED_TO_POOL");
        
        isExistingToken[token] = true;
        existingTokens.push(token);
        
        emit AddLiquidityPool(admin, token, IPCOG);
        
    }

    function removeLiquidityPool(address token) external onlyAdmin {
        require(token != address(0) && token != IPCOG && token != PCOG, "PrecogV4: INVALID_TOKEN_ADDRESS");
        require(isExistingToken[token], "PrecogV4: TOKEN_IS_NOT_ADDED_TO_POOL");
        if(totalFeeTrading[token] + totalFeeWithdraw[token] + totalFeeLending[token] != 0)
            withdrawFee(token);
        for(uint256 i = 0; i < existingTokens.length; i++) {
            if(existingTokens[i] == token) {
                existingTokens[i] = existingTokens[existingTokens.length - 1];
                existingTokens.pop();
                isExistingToken[token] = false;
                emit RemoveLiquidityPool(admin, token, IPCOG);
                return;
            }
        }
    }

    function deposit(address token, uint256 amount) external {
        require(isExistingToken[token], "PrecogV4: INVALID_TOKEN_ADDRESS");
        
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        
        uint256 feeDeposit = feeDepositByDecimalBased * amount / 10 ** decimalBased;
        uint256 actualAmount = amount - feeDeposit;
        uint256 convertedActualAmount = actualAmount * 1e18 / 10 ** IERC20(token).decimals();
        InterfaceIPCOG(IPCOG).mint(msg.sender, convertedActualAmount);
        liquidity[token][IPCOG] += actualAmount;
        totalLiquidity += convertedActualAmount;
        totalFeeDeposit[token] += feeDeposit;
        
        uint256 actualBalance = IERC20(token).balanceOf(address(this)) - totalFeeDeposit[token] - totalFeeWithdraw[token] - totalFeeTrading[token] - totalFeeLending[token];
        if(isInTradingSession(token) == true && 
        liquidity[token][IPCOG] < actualBalance * 1e19 / 10 ** IERC20(token).decimals()) {
            uint256 investAmount = actualBalance - liquidity[token][IPCOG] * 10 / 100;
            IERC20(token).transfer(tradingService, investAmount);
        }
        emit Deposit(msg.sender, token, IPCOG, amount, actualAmount);
    }

    function withdraw(address to, address token, uint256 amountIn, bool letPrecogOwe) public {
        require(totalLiquidity > 0, "PrecogV4: NO_COIN_TO_WITHDRAW");
        require(IERC20(IPCOG).totalSupply() > 0, "PrecogV4: NO_COIN_TO_WITHDRAW");
        require(token != address(0) && isExistingToken[token], "PrecogV4: TOKEN_NOT_EXIST");
        require(amountIn <= getMaxWithdrawAmountIn(msg.sender, token), "PrecogV4: AMOUNT_OF_IPCOG_IS_TOO_MUCH");
        require(amountIn > 0, "PrecogV4: AMOUNT_OF_IP_MUST_BE_GREATER_THAN_ZERO");

        uint256 sendAmount = amountIn * totalLiquidity / IERC20(IPCOG).totalSupply(); // principle
        uint256 convertedSendAmount = sendAmount * 10 ** IERC20(token).decimals() / 1e18;
        uint256 feeWithdraw = convertedSendAmount * feeWithdrawByDecimalBased / 10**decimalBased;
        liquidity[token][IPCOG] -= convertedSendAmount;
        convertedSendAmount -= feeWithdraw;
        totalFeeWithdraw[token] += feeWithdraw;
        totalLiquidity -= sendAmount;
        // profit
        uint256 amountProfit = 0;
        (bool isUnlocked, ) = InterfaceIPCOG(IPCOG).isUnlockingTime(msg.sender);
        if (isUnlocked){
            amountProfit = amountIn * profit / IERC20(IPCOG).totalSupply();
            IERC20(PCOG).transfer(to, amountProfit);
            profit -= amountProfit;
        }

        uint256 totalFee = totalFeeDeposit[token] + totalFeeWithdraw[token] + totalFeeTrading[token] + totalFeeLending[token];
        uint256 actualBalance = IERC20(token).balanceOf(address(this)) - totalFee;

        InterfaceIPCOG(IPCOG).burnFrom(msg.sender, amountIn);
        if(convertedSendAmount > actualBalance) {
            if(letPrecogOwe) {
                IERC20(token).transfer(to, actualBalance);
                totalDebtsAmount[token] += convertedSendAmount - actualBalance;
                userDebt[token][to] += convertedSendAmount - actualBalance;
                paybook[token].push(DebtInfo(to, convertedSendAmount - actualBalance));
                emit CreateDebt(to, token, convertedSendAmount - actualBalance);
                emit Withdraw(
                    msg.sender, 
                    to, 
                    token, 
                    IPCOG, 
                    PCOG,
                    amountIn,
                    convertedSendAmount - actualBalance,
                    amountProfit
                );
            }
            else 
                require(false, "PrecogV4: INSUFFICIENT_BALANCE");
        }
        else {
            IERC20(token).transfer(to, convertedSendAmount);
            emit Withdraw(
                msg.sender, 
                to, 
                token, 
                IPCOG, 
                PCOG,
                amountIn,
                convertedSendAmount,
                amountProfit
            );
        }

        
    }

    function withdrawMixed(address to, WithdrawInfo[] memory withdrawsInfo, bool letPrecogOwe) external {
        require(withdrawsInfo.length > 0, "PrecogV4: NOT_SELECTED_ANY_TOKEN");
        for(uint256 i = 0; i < withdrawsInfo.length; i++)
            withdraw(to, withdrawsInfo[i].token, withdrawsInfo[i].amountLiquidityToken, letPrecogOwe);
    }

    function updateTradingStatus(
        address token,
        uint256 profitFromLastTrade,
        uint256 startTime,
        uint256 endTime,
        uint16 _APY,
        uint16 _APYDecimal
    ) external onlyTradingService {
        require(isExistingToken[token], "PrecogV4: INVALID_TOKEN_ADDRESS");
        require(startTime >= block.timestamp, "PrecogV4: IN_VALID_START_TIME");
        require(endTime > startTime, "PrecogV4: IN_VALID_END_TIME");
        uint256 actualBalance = IERC20(token).balanceOf(address(this)) - totalFeeDeposit[token] - totalFeeWithdraw[token] - totalFeeTrading[token] - totalFeeLending[token];
        if(liquidity[token][IPCOG] < actualBalance * 10^18 / 10 ** IERC20(token).decimals()) {
            uint256 amountOut = actualBalance - liquidity[token][IPCOG] * 10 / 100;
            IERC20(token).transfer(tradingService, amountOut);
        }
        else if (liquidity[token][IPCOG] > actualBalance * 1e19 / 10 ** IERC20(token).decimals()){
            uint256 amountIn = liquidity[token][IPCOG] * 10 / 100 - actualBalance;
            IERC20(token).transferFrom(tradingService, address(this), amountIn);
        }

        uint256 feeTradingCharge = profitFromLastTrade * feeTradingByDecimalBased / 10 ** decimalBased;
        uint256 actualProfit = profitFromLastTrade - feeTradingCharge;
        totalFeeTrading[token] += feeTradingCharge;

        if(profitFromLastTrade == 0) {
            tradingSessions[token].push(TradeInfo(0, 0, startTime, endTime));
            emit UpdateTradingStatus(tradingService, token, PCOG, 0, 0, _APY, _APYDecimal, endTime, block.timestamp);
            return;
        }
        IERC20(token).transferFrom(tradingService, address(this), actualProfit);
        uint256 amountPCOGBought = buyPCOG(token, actualProfit, block.timestamp + 600);// 60 * 10 * 1000 => 10 minutes or user can set it
        profit += amountPCOGBought; 
        tradingSessions[token].push(TradeInfo(profitFromLastTrade, amountPCOGBought, startTime, endTime));
        emit UpdateTradingStatus(tradingService, token, PCOG, profitFromLastTrade, amountPCOGBought, _APY, _APYDecimal, endTime, block.timestamp);

    }

    function getPath(address token) internal view returns (address[] memory){
        address[] memory pair = new address[](2);
        pair[0] = token;
        pair[1] = PCOG;
        return pair;
    }

    function buyPCOG(address token, uint256 amount, uint deadline) internal returns (uint256 PCOGAmount) {
        require(isExistingToken[token], "PrecogV4: INVALID_TOKEN_ADDRESS");
        if (IERC20(token).allowance(address(this), exchange) < amount){
            IERC20(token).approve(exchange, 2**256 - 1 - IERC20(token).allowance(address(this), exchange));
        }
        uint256 estimatedPCOG = IExchangeRouter(exchange).getAmountsOut(amount, getPath(token))[1];
        PCOGAmount = uint256(IExchangeRouter(exchange).swapExactTokensForTokens(amount, estimatedPCOG, getPath(token), address(this), deadline)[1]);
    }

    function withdrawFee(address token) public onlyAdmin {
        require(isExistingToken[token], "PrecogV4: INVALID_TOKEN_ADDRESS");
        require(totalFeeTrading[token] + totalFeeWithdraw[token] + totalFeeLending[token] != 0, "PrecogV4: NO_FEE_TO_WITHDRAW");
        IERC20(token).transfer(admin, totalFeeDeposit[token] + totalFeeTrading[token] + totalFeeWithdraw[token] + totalFeeLending[token]);
        emit WithdrawFee(admin, token, totalFeeDeposit[token], totalFeeWithdraw[token], totalFeeTrading[token], totalFeeLending[token]);
        totalFeeTrading[token] = 0;
        totalFeeWithdraw[token] = 0;
        totalFeeLending[token] = 0;
        totalFeeDeposit[token] = 0;
        
    }

    function collectTotalFees() external onlyAdmin {
        for(uint256 i = 0; i < existingTokens.length; i++) {
            withdrawFee(existingTokens[i]);
        }
    }

    function payAllDebtsAndBalanceLiquidity(address token) public {
        require(msg.sender == tradingService || msg.sender == admin, "Precog: MUST_BE_ADMIN_OR_TRADING_SERVICE");
        uint256 totalSupply = liquidity[token][IPCOG];
        uint256 totalFee = totalFeeDeposit[token] + totalFeeWithdraw[token] + totalFeeTrading[token] + totalFeeLending[token];
        uint256 actualBalance = IERC20(token).balanceOf(address(this)) - totalFee;
        uint256 totalAmountPay = totalDebtsAmount[token] + totalSupply / 10 - actualBalance;
        IERC20(token).transferFrom(msg.sender, address(this), totalAmountPay);
        for(uint256 i = currentDebtNotPay[token]; i < paybook[token].length; i++) {
            IERC20(token).transfer(paybook[token][i].account, paybook[token][i].debtAmount);
            totalDebtsAmount[token] -= paybook[token][i].debtAmount;
            userDebt[token][paybook[token][i].account] -= paybook[token][i].debtAmount;
            emit PayDebt(paybook[token][i].account, token, paybook[token][i].debtAmount);
            paybook[token][i].debtAmount = 0;
        }
        currentDebtNotPay[token] = paybook[token].length;
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

interface IPrecogV4 {
    struct TradeInfo {
        uint256 profit;
        uint256 amountPCOGBought;
        uint256 startTime;
        uint256 endTime;
    }

    struct WithdrawInfo {
        address token;
        uint256 amountLiquidityToken;
    }

    struct DebtInfo {
        address account;
        uint256 debtAmount;
    }

    function admin() external view returns(address);
    function tradingService() external view returns(address);
    function exchange() external view returns(address);
    function PCOG() external view returns(address);
    function IPCOG() external view returns(address);

    function feeDepositByDecimalBased() external view returns (uint256);
    function feeWithdrawByDecimalBased() external view returns (uint256);
    function feeTradingByDecimalBased() external view returns (uint256);
    function feeLendingByDecimalBased() external view returns (uint256);
    function decimalBased() external view returns (uint16);

    function isExistedToken(address token) external view returns (bool);
    function existedTokens(uint256 index) external view returns(address);

    function totalDebtsAmount(address token) external view returns (uint256);
    function getPaybook(address token) external view returns (DebtInfo[] memory);
    function getUserDebt(address token, address user) external view returns (uint256);

    function isInTradingSession(address token) external view returns(bool);
    function getTradingSessions(address token) external view returns (TradeInfo[] memory);
    function getLastTradingSession(address token) external view returns (TradeInfo memory);

    function totalFeeDeposit(address token) external view returns (uint256);
    function totalFeeWithdraw(address token) external view returns (uint256);
    function totalFeeTrading(address token) external view returns (uint256);
    function totalFeeLending(address token) external view returns (uint256);

    function totalLiquidity() external view returns (uint256);
    function profit() external view returns (uint256);
    function getLiquidity(address token) external view returns (uint256);

    function getMaxWithdrawAmountIn(address from, address token) external view returns (uint256);
    function getWithdrawAmountIn(uint256 amountOut, address token) external view returns (uint256);
    function getWithdrawAmountOut(uint256 amountIn, address token) external view returns (uint256);

    function transferAdmin(address _admin) external;
    function setTradingService(address _tradingService) external;
    function setExchange(address _exchange) external;
    function setDecimalBased(uint16 _decimal) external;
    function setFeeTrading(uint256 _newFee) external;
    function setFeeDeposit(uint256 _newFee) external;
    function setFeeWithdraw(uint256 _newFee) external;
    function setFeeLending(uint256 _newFee) external;

    function setPeriodTime(uint256 periodTime) external;
    
    function addLiqudityPool(address token) external;
    function removeLiquidityPool(address token) external;

    function deposit(address token, uint256 amount) external;
    function withdraw(address to, address token, uint256 amountIn, bool letPrecogOwe) external;
    function withdrawMixed(address to, WithdrawInfo[] memory withdrawsInfo, bool letPrecogOwe) external;

    function updateTradingStatus(
        address token,
        uint256 profitFromLastTrade,
        uint256 startTime,
        uint256 endTime,
        uint16 _APY,
        uint16 _APYDecimal
    ) external;
    function withdrawFee(address token) external;
    function collectTotalFees() external;

    function payAllDebtsAndBalanceLiquidity(address token) external;
}

pragma solidity ^0.8.0;

interface InterfacePCOG {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function mint(address account, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
    
    function burn(uint256 amount) external;

    function burners(uint256 index) external view returns (address);

    function getAllBurners() external view returns (address[] memory);

    function getIsBurner(address account) external view returns (bool);

    function addBurner(address burner) external;

    function removeBurner(address burner) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event AddBurner(address owner, address burner, uint256 timestamp);
    event RemoveBurner(address owner, address burner, uint256 timestamp);
}

pragma solidity ^0.8.0;

interface InterfaceIPCOG {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function mint(address account, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
    
    function burn(uint256 amount) external;

    function periodLockingTime() external view returns (uint256);

    function setPeriodLockingTime(uint256 _periodLockingTime) external;

    function getEndLockingTime(address account) external view returns (uint256);

    function isUnlockingTime(address account) external view returns (bool, uint256);

    event SetPeriodLockingTime(address owner, uint256 periodLockingTime, uint256 timestamp);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.8.0;

interface IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function mint(address account, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
    
    function burn(uint256 amount) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
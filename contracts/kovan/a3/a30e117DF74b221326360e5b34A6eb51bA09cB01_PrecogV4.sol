pragma solidity ^0.8.0;
import "../common/interfaces/IERC20.sol";
import "./libraries/SafeMath.sol";
import "./interfaces/exchange-router.sol";
import "../common/interfaces/InterfaceIPCOG.sol";
import "../common/interfaces/InterfacePCOG.sol";

contract PrecogV4 {
    // trading fields
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

    mapping(address => uint256) totalDebtsAmount;
    mapping(address => DebtInfo[]) paybook;
    mapping(address => mapping(address => uint256)) userDebt;

    mapping(address => TradeInfo[]) tradingSessions;
    
    

    address public admin;
    address public exchange;
    
    address public tradingService;
    

    mapping(address => bool) isExistedToken;
    mapping(address => bool) isExistedLiquidityToken;
    address[] public existedTokens;

    address public IPCOG;
    address public PCOG;

    uint256 public feeWithdrawByDecimalBased = 0;
    uint256 public feeDepositByDecimalBased = 0;
    uint256 public feeTradingByDecimalBased = 0; //charge based on 10 power decimal
    uint256 public feeLendingByDecimalBased = 0; 
    uint16 public decimalBased = 18;

    mapping(address => uint256) totalFeeDeposit;
    mapping(address => uint256) totalFeeWithdraw;
    mapping(address => uint256) totalFeeTrading;
    mapping(address => uint256) totalFeeLending;

    
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
        uint256 amountPCOG,
        uint256 timestamp
    );

    event Withdraw(
        address indexed account,
        address indexed to,
        address indexed token,
        address IPCOG,
        address PCOG,
        uint256 amountIPCOGBurn,
        uint256 amountTokenReceive,
        uint256 profitPCOG,
        uint256 timestamp
    );

    event WithdrawFee(
        address indexed admin,
        address indexed token,
        uint256 totalFeeWithdraw,
        uint256 totalFeeTrading,
        uint256 totalFeeLending, 
        uint256 timestamp
    );

    event AddLiquidityPool(
        address indexed admin,
        address indexed token, 
        address indexed IPCOG, 
        uint256 timestamp
    );

    event RemoveLiquidityPool(
        address indexed admin,
        address indexed token, 
        address indexed IPCOG, 
        uint256 timestamp
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
        uint256 indexed timestamp
    );

    event TransferAdmin(address indexed lastAdmin, address indexed newAdmin, uint256 indexed timestamp);

    event SetTradingService(
        address indexed admin, 
        address indexed lastTradingService, 
        address indexed newTradingService, 
        uint256 timestamp
    );

    event SetFeeWithdraw(
        address indexed admin, 
        address indexed token, 
        uint256 indexed timestamp,
        uint16 feeWithdrawByDecimalBased, 
        uint16 decimalBased
    );

    event SetFeeTradingByDecimalBased(
        address indexed admin, 
        address indexed token, 
        uint256 indexed timestamp,
        uint16 feeTradingByDecimalBased, 
        uint16 decimalBased
    );

    event SetFeeLending(
        address indexed admin, 
        address indexed token, 
        uint256 indexed timestamp,
        uint16 feeLendingByDecimalBased, 
        uint16 decimalBased
    );

    event CreateDebt(
        address indexed account,
        address indexed token,
        uint256 indexed amount,
        uint256 timestamp
    );

    event PayDebt(
        address indexed account,
        address indexed token,
        uint256 indexed amount,
        uint256 timestamp
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
        emit TransferAdmin(admin, _admin, block.timestamp);
        admin = _admin;
    }

    function setTradingService(address _tradingService) external onlyAdmin {
        emit SetTradingService(admin, tradingService, _tradingService, block.timestamp);
        tradingService = _tradingService;
        
    }

    function setExchange(address _exchange) external onlyAdmin {
        exchange = _exchange;
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

    function IsExistedToken(address token) external view returns (bool) {
        return isExistedToken[token];
    }

    // function getFeeTrading() external view returns (uint256) {
    //     return feeTradingByDecimalBased;
    // }
    // function getFeeDeposit() external view returns (uint256) {
    //     return feeDepositByDecimalBased;
    // }
    // function getFeeWithdraw() external view returns (uint256) {
    //     return feeWithdrawByDecimalBased;
    // }
    // function getFeeLending() external view returns (uint256) {
    //     return feeLendingByDecimalBased;
    // }

    // function getDecimalBased() external view returns (uint16) {
    //     return decimalBased;
    // }

    function setDecimalBased(uint16 _decimal) external onlyAdmin {
        decimalBased = _decimal;
    }

    function setFeeTrading(uint256 _newFee) external onlyAdmin {
        feeTradingByDecimalBased = _newFee;
    }

    function setFeeDeposit(uint256 _newFee) external onlyAdmin {
        feeDepositByDecimalBased = _newFee; 
    }

    function setFeeWithdraw(uint256 _newFee) external onlyAdmin {
        feeWithdrawByDecimalBased = _newFee;
    }

    function setFeeLending(uint256 _newFee) external onlyAdmin {
        feeLendingByDecimalBased = _newFee;
    }

    function getTotalFeeDeposit(address token) external view returns (uint256) {
        return totalFeeDeposit[token];
    }

    function getTotalFeeTrading(address token) external view returns (uint256) {
        return totalFeeTrading[token];
    }

    function getTotalFeeWithdraw(address token) external view returns (uint256) {
        return totalFeeWithdraw[token];
    }
 
    function getTotalFeeLending(address token) external view returns (uint256) {
        return totalFeeLending[token];
    }

    function getPaybook(address token) external view returns (DebtInfo[] memory) {
        return paybook[token];
    }

    function getUserDebt(address token, address user) external view returns (uint256) {
        return userDebt[token][user];
    }

    function getLiquidity(address token) external view returns (uint256){
        return liquidity[token][IPCOG];
    }

    function setPeriodTime(uint256 periodTime) external onlyAdmin {
        InterfaceIPCOG(IPCOG).setPeriodLockingTime(periodTime);
    } 

    function addLiqudityPool(address token) external onlyAdmin {
        require(token != address(0) && token != PCOG && token != IPCOG, "PrecogV4: INVALID_TOKEN_ADDRESS");
        require(!isExistedToken[token], "PrecogV4: TOKEN_IS_ALREADY_ADDED_TO_POOL");
        
        isExistedToken[token] = true;
        existedTokens.push(token);
        
        emit AddLiquidityPool(admin, token, IPCOG, block.timestamp);
        
    }

    function removeLiquidityPool(address token) external onlyAdmin {
        require(token != address(0) && token != IPCOG && token != PCOG, "PrecogV4: INVALID_TOKEN_ADDRESS");
        require(isExistedToken[token], "PrecogV4: TOKEN_IS_NOT_ADDED_TO_POOL");
        if(totalFeeTrading[token] + totalFeeWithdraw[token] + totalFeeLending[token] != 0)
            withdrawFee(token);
        for(uint256 i = 0; i < existedTokens.length; i++) {
            if(existedTokens[i] == token) {
                existedTokens[i] = existedTokens[existedTokens.length - 1];
                existedTokens.pop();
                isExistedToken[token] = false;
                isExistedLiquidityToken[token] = false;
                emit RemoveLiquidityPool(admin, token, IPCOG, block.timestamp);
                return;
            }
        }
    }

    function deposit(address token, uint256 amount) external {
        require(isExistedToken[token], "PrecogV4: INVALID_TOKEN_ADDRESS");
        // require(amount > feeWithdraw, "PrecogV4: AMOUNT_LOWER_EQUAL_FEE");
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        
        uint256 feeDeposit = feeDepositByDecimalBased * amount / 10 ** decimalBased;
        uint256 actualAmount = amount - feeDeposit;
        uint256 convertedActualAmount = actualAmount * 1e18 / 10 ** IERC20(token).decimals();
        InterfaceIPCOG(IPCOG).mint(msg.sender, convertedActualAmount);
        liquidity[token][IPCOG] += convertedActualAmount;
        totalLiquidity += convertedActualAmount;
        totalFeeDeposit[token] += feeDeposit;
        
        uint256 actualBalance = IERC20(token).balanceOf(address(this)) - totalFeeWithdraw[token] - totalFeeTrading[token] - totalFeeLending[token];
        if(isInTradingSession(token) == true && 
        liquidity[token][IPCOG] < actualBalance * 1e19 / 10 ** IERC20(token).decimals()) {
            uint256 investAmount = actualBalance - liquidity[token][IPCOG] * 10 ** IERC20(token).decimals() * 10 / 1e20;
            IERC20(token).transfer(tradingService, investAmount);
        }
        emit Deposit(msg.sender, token, IPCOG, amount, actualAmount, block.timestamp);
    }

    function getMaxWithdrawAmountIn(address from, address token) public view returns (uint256) {
        if (totalLiquidity <= 0) return 0;
        uint256 maxBurnableIP = liquidity[token][IPCOG] * IERC20(IPCOG).totalSupply() / totalLiquidity;
        return maxBurnableIP < IERC20(IPCOG).balanceOf(from) ? maxBurnableIP : IERC20(IPCOG).balanceOf(from);
    }

    function getWithdrawAmountIn(uint256 amountOut) public view returns (uint256) {
        return amountOut * IERC20(IPCOG).totalSupply() / totalLiquidity;
    }

    function getWithdrawAmountOut(uint256 amountIn) public view returns (uint256) {
        if (IERC20(IPCOG).totalSupply() <= 0) return 0;
        return amountIn * totalLiquidity / IERC20(IPCOG).totalSupply();
    }

    function withdraw(address to, address token, uint256 amountIn, bool isCreateDebt) public {
        require(totalLiquidity > 0, "PrecogV4: NO_COIN_TO_WITHDRAW");
        require(IERC20(IPCOG).totalSupply() > 0, "PrecogV4: NO_COIN_TO_WITHDRAW");
        require(token != address(0) && isExistedToken[token], "PrecogV4: TOKEN_NOT_EXIST");
        require(amountIn <= getMaxWithdrawAmountIn(msg.sender, token), "PrecogV4: AMOUNT_OF_IPCOG_IS_TOO_MUCH");
        require(amountIn > 0, "PrecogV4: AMOUNT_OF_IP_MUST_BE_GREATER_THAN_ZERO");

        uint256 sendAmount = amountIn * totalLiquidity / IERC20(IPCOG).totalSupply(); // principle
        uint256 convertedSendAmount = sendAmount * 10 ** IERC20(token).decimals() / 1e18;
        uint256 feeWithdraw = convertedSendAmount * feeWithdrawByDecimalBased / 10**decimalBased;
        convertedSendAmount -= feeWithdraw;
        totalFeeWithdraw[token] += feeWithdraw;
        liquidity[token][IPCOG] -= sendAmount;
        totalLiquidity -= sendAmount;
        // profit
        uint256 amountProfit = 0;
        (bool isUnlocked, ) = InterfaceIPCOG(IPCOG).isUnlockingTime(msg.sender);
        if (isUnlocked){
            amountProfit = amountIn * profit / IERC20(IPCOG).totalSupply();
            IERC20(PCOG).transfer(to, amountProfit);
            profit -= amountProfit;
        }

        InterfaceIPCOG(IPCOG).burnFrom(msg.sender, amountIn);
        if(convertedSendAmount > IERC20(token).balanceOf(address(this))) {
            if(isCreateDebt) {
                IERC20(token).transfer(to, IERC20(token).balanceOf(address(this)));
                totalDebtsAmount[token] += convertedSendAmount - IERC20(token).balanceOf(address(this));
                userDebt[to][token] += convertedSendAmount - IERC20(token).balanceOf(address(this));
                paybook[token].push(DebtInfo(to, convertedSendAmount - IERC20(token).balanceOf(address(this))));
                emit CreateDebt(to, token, convertedSendAmount - IERC20(token).balanceOf(address(this)), block.timestamp);
                emit Withdraw(
                    msg.sender, 
                    to, 
                    token, 
                    IPCOG, 
                    PCOG,
                    amountIn,
                    convertedSendAmount - IERC20(token).balanceOf(address(this)),
                    amountProfit,
                    block.timestamp
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
                    amountProfit,
                    block.timestamp
                );
        }

        
    }

    function withdrawMixed(address to, WithdrawInfo[] memory withdrawsInfo, bool isCreateDebt) external {
        require(withdrawsInfo.length > 0, "PrecogV4: NOT_SELECTED_ANY_TOKEN");
        for(uint256 i = 0; i < withdrawsInfo.length; i++)
            withdraw(to, withdrawsInfo[i].token, withdrawsInfo[i].amountLiquidityToken, isCreateDebt);
    }

    function updateTradingStatus(
        address token,
        uint256 profitFromLastTrade,
        uint256 startTime,
        uint256 endTime,
        uint16 _APY,
        uint16 _APYDecimal
    ) external onlyTradingService {
        require(isExistedToken[token], "PrecogV4: INVALID_TOKEN_ADDRESS");
        require(startTime >= block.timestamp, "PrecogV4: IN_VALID_START_TIME");
        require(endTime > startTime, "PrecogV4: IN_VALID_END_TIME");
        uint256 actualBalance = IERC20(token).balanceOf(address(this)) - totalFeeWithdraw[token] - totalFeeTrading[token] - totalFeeLending[token];
        if(liquidity[token][IPCOG] < actualBalance * 1e19 / 10 ** IERC20(token).decimals()) {
            uint256 amountOut = actualBalance - liquidity[token][IPCOG] * 10 ** IERC20(token).decimals() * 10 / 1e20;
            IERC20(token).transfer(tradingService, amountOut);
        }
        else if (liquidity[token][IPCOG] > actualBalance * 1e19 / 10 ** IERC20(token).decimals()){
            uint256 amountIn = liquidity[token][IPCOG] * 10 ** IERC20(token).decimals() * 10 / 1e20 - actualBalance;
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
        require(isExistedToken[token], "PrecogV4: INVALID_TOKEN_ADDRESS");
        if (IERC20(token).allowance(address(this), exchange) < amount){
            IERC20(token).approve(exchange, 2**256 - 1 - IERC20(token).allowance(address(this), exchange));
        }
        uint256 estimatedPCOG = IExchangeRouter(exchange).getAmountsOut(amount, getPath(token))[1];
        PCOGAmount = uint256(IExchangeRouter(exchange).swapExactTokensForTokens(amount, estimatedPCOG, getPath(token), address(this), deadline)[1]);
    }

    function withdrawFee(address token) public onlyAdmin {
        require(isExistedToken[token], "PrecogV4: INVALID_TOKEN_ADDRESS");
        require(totalFeeTrading[token] + totalFeeWithdraw[token] + totalFeeLending[token] != 0, "PrecogV4: NO_FEE_TO_WITHDRAW");
        IERC20(token).transfer(admin, totalFeeTrading[token] + totalFeeWithdraw[token] + totalFeeLending[token]);
        emit WithdrawFee(admin, token, totalFeeWithdraw[token], totalFeeTrading[token], totalFeeLending[token], block.timestamp);
        totalFeeTrading[token] = 0;
        totalFeeWithdraw[token] = 0;
        totalFeeLending[token] = 0;
        
    }

    function collectTotalFees() external onlyAdmin {
        for(uint256 i = 0; i < existedTokens.length; i++) {
            withdrawFee(existedTokens[i]);
        }
    }

    function payAllDebtsAndBalanceLiquidity(address token) public {
        require(msg.sender == tradingService || msg.sender == admin, "Precog: MUST_BE_ADMIN_OR_TRADING_SERVICE");
        uint256 totalAmountPay;

        uint256 totalSupply = IERC20(token).balanceOf(address(this)) - totalFeeWithdraw[token] - totalFeeTrading[token] - totalFeeLending[token];

        if(IERC20(token).balanceOf(address(this)) * 100 / totalSupply < 10) {
            totalAmountPay = totalDebtsAmount[token] + (totalSupply * (10 * totalSupply - IERC20(token).balanceOf(address(this)) * 100 / totalSupply) / 100);
        }
        else {
            totalAmountPay = totalDebtsAmount[token] - (totalSupply * (IERC20(token).balanceOf(address(this)) * 100 - 10 * totalSupply / totalSupply) / 100);
        }


        IERC20(token).transferFrom(msg.sender, address(this), totalAmountPay);

        for(uint256 i = currentDebtNotPay[token]; i < paybook[token].length; i++) {
            IERC20(token).transfer(paybook[token][i].account, paybook[token][i].debtAmount);
            totalDebtsAmount[token] -= paybook[token][i].debtAmount;
            userDebt[token][paybook[token][i].account] -= paybook[token][i].debtAmount;
            emit PayDebt(paybook[token][i].account, token, paybook[token][i].debtAmount, block.timestamp);
            paybook[token][i].debtAmount = 0;
            
        }

        currentDebtNotPay[token] = paybook[token].length - 1;
    }

}

pragma solidity ^0.8.0;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256) {
        require(x + y >= x, "SafeMath: ADDITION_OVERFLOW");
        return x + y;
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256) {
        require(x - y <= x, "SafeMath: SUBTRACTION_UNDERFLOW");
        return x - y;
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256) {
        if(x == 0 || y == 0) return 0;
        require(x * y / y == x, "SafeMath: MULTIPLICATION_OVERFLOW");
        return x * y;
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y != 0, "SafeMath: DIVISION_BY_ZERO");
        return x / y;
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
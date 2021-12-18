pragma solidity ^0.8.0;
import "../common/interfaces/IERC20.sol";
import "./libraries/SafeMath.sol";

contract NewPrecog {
    using SafeMath for uint256;

    struct TradeInfo {
        uint256 profitFromLastTrade;
        uint256 profitPrediction;
        uint256 startTime;
        uint256 endTime;
        uint32 APYPercent;
        uint32 profitPredictionPercent;
    }

    struct DebtInfo {
        address user;
        uint256 debtAmount;
    }

    TradeInfo[] tradesInfo;
    DebtInfo[] paybook;

    address public usdc;
    address public admin;
    address public liquidityToken;
    address public tradingService;

    uint256 public totalSupply;
    uint256 totalSupplyVirtual;
    uint256 lastTransactionTimestamp;
    uint256 currentDebtNotPay;
    uint256 totalDebtsAmount;
    uint32 public APYDecimal = 12;
    uint32 public APYPercent;
    uint256 public APYPerSecond;

    uint32 public duration;

    bool public isTrade;

    mapping(address => mapping(address => uint256)) liquidity;
    mapping(address => mapping(address => uint256)) liquidityForInterest;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Precog: NOT_ADMIN_ADDRESS");
        _;
    }

    modifier onlyTradingService() {
        require(msg.sender == tradingService, "Precog: NOT_TRADING_SERVICE");
        _;
    }

    constructor(
        address _usdc,
        address _liquidityToken,
        address _tradingService,
        address _admin
    ) {
        usdc = _usdc;
        liquidityToken = _liquidityToken;
        tradingService = _tradingService;
        admin = _admin;
        lastTransactionTimestamp = block.timestamp;
    }

    function transferAdmin(address _admin) external onlyAdmin {
        admin = _admin;
    }

    function setTradingService(address _tradingService) external onlyAdmin {
        tradingService = _tradingService;
    }

    function setDuration(uint32 _duration) external onlyAdmin {
        duration = _duration;
    }

    function setAPYPercent(uint32 _APYPercent) external onlyAdmin {
        APYPercent = _APYPercent;
    }

    function getTradesInfo() external view returns (TradeInfo[] memory) {
        return tradesInfo;
    }

    function getCurrentUSDC() external view returns (uint256) {
        return liquidity[usdc][liquidityToken];
    }

    function getCurrentLiquidityToken() external view returns (uint256) {
        return liquidity[liquidityToken][usdc];
    }

    function getTradeInfo(uint256 index)
        external
        view
        returns (TradeInfo memory)
    {
        return tradesInfo[index];
    }

    function getLastTradeInfo() external view returns (TradeInfo memory) {
        return tradesInfo[tradesInfo.length - 1];
    }

    function getPaybook() external view returns (DebtInfo[] memory) {
        return paybook;
    }

    function isInTradingTime() internal view returns (bool) {
        return tradesInfo[tradesInfo.length - 1].endTime > block.timestamp;
    }

    function deposit(uint256 amount) external {
        require(amount > 0, "Precog: AMOUNT_TOKEN_IS_NOT_AVAILABLE");
        uint256 amountLiquidity;

        bool isEmptyLiquidityToken = liquidityForInterest[liquidityToken][usdc] == 0;

        if (tradesInfo.length > 0) {
            if (isInTradingTime()) {
                uint256 APYPerSecondTotal = APYPerSecond * (block.timestamp - lastTransactionTimestamp);
                totalSupplyVirtual += (liquidityForInterest[usdc][liquidityToken] * APYPerSecondTotal) / 10**APYDecimal;
                amountLiquidity = isEmptyLiquidityToken == true ? 
                    amount : amount * liquidityForInterest[liquidityToken][usdc] / totalSupplyVirtual;
                lastTransactionTimestamp = block.timestamp;
            } 
            else {
                uint256 APYPerSecondTotal = APYPerSecond * (tradesInfo[tradesInfo.length - 1].endTime - lastTransactionTimestamp);
                totalSupplyVirtual += (liquidityForInterest[usdc][liquidityToken] * APYPerSecondTotal) / 10**APYDecimal;
                amountLiquidity = isEmptyLiquidityToken == true ? 
                    amount : amount * liquidityForInterest[liquidityToken][usdc] / totalSupplyVirtual;
                lastTransactionTimestamp = tradesInfo[tradesInfo.length - 1].endTime;
            }
        } else {
            amountLiquidity = isEmptyLiquidityToken == true ? 
                amount : amount * liquidityForInterest[liquidityToken][usdc] / liquidityForInterest[usdc][liquidityToken];
        }
        require(amountLiquidity > 0, "Precog: GET_NO_AMOUNT_OF_TOKEN");
        
        IERC20(usdc).transferFrom(msg.sender, address(this), amount);
        IERC20(liquidityToken).mint(msg.sender, amountLiquidity);

        totalSupply += amount;
        totalSupplyVirtual += amount;

        liquidity[usdc][liquidityToken] += amount;
        liquidityForInterest[usdc][liquidityToken] += amount;

        liquidity[liquidityToken][usdc] += amountLiquidity;
        liquidityForInterest[liquidityToken][usdc] += amountLiquidity;

        if (liquidity[usdc][liquidityToken] > (totalSupply * 10) / 100 &&
            tradesInfo.length > 0 &&
            tradesInfo[tradesInfo.length - 1].endTime < block.timestamp) {
                uint256 investAmount = liquidity[usdc][liquidityToken] - (totalSupply * 10) / 100;
                IERC20(usdc).transfer(tradingService, investAmount);
                liquidity[usdc][liquidityToken] -= investAmount;
        }
    }

    function withdrawLiquidity(address account, uint256 amountLiquidity)
        external
    {
        require(amountLiquidity > 0,"Precog: AMOUNT_LIQUIDITY_TOKEN_IS_NOT_AVAILABLE");
        require(IERC20(liquidityToken).balanceOf(msg.sender) >= amountLiquidity, "Precog: NOT_ENOUGH_AMOUNT_LIQUIDITY_TOKEN");

        if (tradesInfo.length > 0) {
            if (isInTradingTime()) {
                uint256 APYPerSecondTotal = APYPerSecond * (block.timestamp - lastTransactionTimestamp);
                totalSupplyVirtual += (liquidityForInterest[usdc][liquidityToken] * APYPerSecondTotal) / 10**APYDecimal;
                lastTransactionTimestamp = block.timestamp;
            } else {
                uint256 APYPerSecondTotal = APYPerSecond * (tradesInfo[tradesInfo.length - 1].endTime - lastTransactionTimestamp);
                totalSupplyVirtual += (liquidityForInterest[usdc][liquidityToken] * APYPerSecondTotal) / 10**APYDecimal;
                lastTransactionTimestamp = tradesInfo[tradesInfo.length - 1].endTime;
            }
        }

        uint256 amountUSDC = amountLiquidity * totalSupplyVirtual / liquidityForInterest[liquidityToken][usdc];
        require(amountUSDC > 0, "Precog: GET_NO_AMOUNT_OF_TOKEN");

        IERC20(liquidityToken).burnFrom(account, amountLiquidity);
        if (liquidity[usdc][liquidityToken] < amountUSDC) {
            IERC20(usdc).transfer(account, liquidity[usdc][liquidityToken]);
            totalSupply -= liquidity[usdc][liquidityToken];
            paybook.push(DebtInfo(account, amountUSDC - liquidity[usdc][liquidityToken]));
            totalDebtsAmount += amountUSDC - liquidity[usdc][liquidityToken];
            liquidity[usdc][liquidityToken] = 0;
        } else {
            IERC20(usdc).transfer(account, amountUSDC);
            totalSupply -= amountUSDC;
            liquidity[usdc][liquidityToken] -= amountUSDC;
        }
        liquidity[liquidityToken][usdc] -= amountLiquidity;
    }

    function payDebtsAndBalanceLiquidity(uint8 percentOfBalanceToPay) public {
        require(msg.sender == tradingService || msg.sender == admin, "Precog: MUST_BE_ADMIN_OR_TRADING_SERVICE");
        percentOfBalanceToPay = percentOfBalanceToPay > 100 ? 100 : percentOfBalanceToPay;
        uint256 totalAmountPay = IERC20(usdc).balanceOf(tradingService) * percentOfBalanceToPay / 100;
        if(totalDebtsAmount < totalAmountPay) {
            IERC20(usdc).transferFrom(msg.sender, address(this), totalDebtsAmount);
            liquidity[usdc][liquidityToken] += totalDebtsAmount;
        }
        else {
            IERC20(usdc).transferFrom(msg.sender, address(this), totalAmountPay);
            liquidity[usdc][liquidityToken] += totalAmountPay;
        }
            
        for (uint256 i = currentDebtNotPay; i < paybook.length; i++) {
            if (liquidity[usdc][liquidityToken] < paybook[i].debtAmount || liquidity[usdc][liquidityToken] < totalSupply * 10 / 100) {
                currentDebtNotPay = i;
                break;
            }
            IERC20(usdc).transfer(paybook[i].user, paybook[i].debtAmount);
            totalDebtsAmount -= paybook[i].debtAmount;
            liquidity[usdc][liquidityToken] -= paybook[i].debtAmount;
            paybook[i].debtAmount = 0;
        }
    }

    function payAllDebtsAndBalanceLiquidity() public {
        require(msg.sender == tradingService || msg.sender == admin, "Precog: MUST_BE_ADMIN_OR_TRADING_SERVICE");
        uint256 totalAmountPay;
        if(liquidity[usdc][liquidityToken] * 100 / totalSupply < 10) {
            totalAmountPay = totalDebtsAmount + (totalSupply * (10 - (liquidity[usdc][liquidityToken] * 100 / totalSupply)) / 100);
        }
        else {
            totalAmountPay = totalDebtsAmount - (totalSupply * ((liquidity[usdc][liquidityToken] * 100 / totalSupply) - 10) / 100);
        }
        require(IERC20(usdc).balanceOf(tradingService) >= totalAmountPay, "Precog: NOT_HAVE_ENOUGH_AMOUNT_TO_PAY_DEBT");
        IERC20(usdc).transferFrom(msg.sender, address(this), totalAmountPay);
        liquidity[usdc][liquidityToken] += totalAmountPay;
        for (uint256 i = currentDebtNotPay; i < paybook.length; i++) {
            IERC20(usdc).transfer(paybook[i].user, paybook[i].debtAmount);
            totalDebtsAmount -= paybook[i].debtAmount;
            liquidity[usdc][liquidityToken] -= paybook[i].debtAmount;
            paybook[i].debtAmount = 0;
        }
    }

    function updateTradingStatus(
        uint256 profitFromLastTrade,
        uint256 profitPrediction,
        uint32 profitPredictionPercent,
        uint32 newAPYPercent
    ) external onlyTradingService {
        
        liquidityForInterest[usdc][liquidityToken] = totalSupplyVirtual = totalSupply = profitFromLastTrade;

        liquidityForInterest[liquidityToken][usdc] = liquidity[liquidityToken][usdc];

        if (((liquidity[usdc][liquidityToken] * 100) / totalSupply) < 10) {
            uint256 usdcAmount = (totalSupply * 10) / 100 - liquidity[usdc][liquidityToken];
            IERC20(usdc).transferFrom(msg.sender, address(this), usdcAmount);
            liquidity[usdc][liquidityToken] += usdcAmount;
        } else if (
            ((liquidity[usdc][liquidityToken] * 100) / totalSupply) > 10
        ) {
            uint256 usdcAmount = liquidity[usdc][liquidityToken] - (totalSupply * 10) / 100;
            IERC20(usdc).transfer(msg.sender, usdcAmount);
            liquidity[usdc][liquidityToken] -= usdcAmount;
        }

        APYPercent = newAPYPercent;
        
        APYPerSecond = APYPercent * 10**APYDecimal / 31536000; //31536000 = 365 * 24 * 60 * 60

        TradeInfo memory tradeInfo = TradeInfo(
            profitFromLastTrade,
            profitPrediction,
            block.timestamp,
            block.timestamp + duration,
            newAPYPercent,
            profitPredictionPercent
        );
        tradesInfo.push(tradeInfo);
        lastTransactionTimestamp = block.timestamp;
    }

    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) public view returns (uint256 amountB) {
        require(amountA > 0, "Precog: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "Precog: INSUFFICIENT_LIQUIDIY");
        amountB = amountA.mul(reserveB) / reserveA;
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

interface IERC20Metadata {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

pragma solidity ^0.8.0;
import "./IERC20Metadata.sol";

interface IERC20 is IERC20Metadata {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function mint(address account, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
pragma solidity ^0.8.0;
import "../common/interfaces/IERC20.sol";
import "./libraries/SafeMath.sol";
import "./interfaces/exchange-router.sol";

contract PrecogV4 {
    // trading fields
    struct TradeInfo {
        uint256 profit;
        uint64 startTime;
        uint64 endTime;
        uint32 APY;
    }
    mapping(address => TradeInfo[]) tradingSessions;
    
    address[] users;

    address public admin;
    address public exchange;
    uint64 public lockTime;
    mapping(address => uint32) APY;
    address public tradingService;
    

    address[] public existedToken;
    address public PCOG;

    mapping(address => uint256) feeWithdraw;
    mapping(address => uint16) feeTradingByDecimalBased; //charge based on 10 power decimal
    mapping(address => uint16) decimalBased;
    mapping(address => uint256) feeLending; 

    mapping(address => uint256) totalFeeWithdraw;
    mapping(address => uint256) totalFeeTrading;
    mapping(address => uint256) totalFeeLending;

    mapping(address => address) tokenConvert;
    mapping(address => mapping(address => uint256)) liquidity;
    mapping(address => uint256) profitLiquidity; //address IP => amount PCOG profit

    modifier onlyAdmin() {
        require(msg.sender == admin, "PrecogV4: Only admin can call function");
        _;
    }
    modifier onlyTradingService() {
        require(msg.sender == tradingService, "PrecogV4: Only trading service can call function");
        _;
    }

    // constructor fields
    constructor(address _tradingService, address _exchange, address _PCOG, address _admin){
        tradingService = _tradingService;
        exchange = _exchange;
        PCOG = _PCOG;
        admin = _admin;
    }

    function transferAdmin(address _admin) external onlyAdmin {
        admin = _admin;
    }

    function setTradingService(address _tradingService) external onlyAdmin {
        tradingService = _tradingService;
    }

    function setExchange(address _exchange) external onlyAdmin {
        exchange = _exchange;
    }

    function getTokenConvert(address token) external view returns (address) {
        return tokenConvert[token];
    }

    function isInTradingSession(address token) public view returns(bool) {
        if (tradingSessions[token].length == 0) return false;
        return tradingSessions[token][tradingSessions[token].length - 1].endTime > block.timestamp;
    }

    function getTotalProfit(address liquidityToken) external view returns (uint256) {
        return profitLiquidity[liquidityToken];
    }

    function getProfit(address liquidityToken) external view returns (uint256) {
        return profitLiquidity[liquidityToken] * IERC20(liquidityToken).balanceOf(msg.sender) / IERC20(liquidityToken).totalSupply();
    }

    function getAPY(address token) external view returns (uint256) {
        return APY[token];
    }

    function getFeeTradingByDecimalBased(address token) external view returns (uint256) {
        return feeTradingByDecimalBased[token];
    }

    function getFeeWithdraw(address token) external view returns (uint256) {
        return feeWithdraw[token];
    }
    function getFeeLending(address token) external view returns (uint256) {
        return feeLending[token];
    }

    function getDecimalBased(address token) external view returns (uint16) {
        return decimalBased[token];
    }

    function setFeeTradingByDecimalBased(address token, uint16 _newFee) external onlyAdmin {
        feeTradingByDecimalBased[token] = _newFee;
    }

    function setDecimalBased(address token, uint16 _newDecimal) external onlyAdmin {
        decimalBased[token] = _newDecimal;
    }

    function setFeeWithdraw(address token, uint256 _newFee) external onlyAdmin {
        feeWithdraw[token] = _newFee;
    }

    function setFeeLending(address token, uint256 _newFee) external onlyAdmin {
        feeLending[token] = _newFee;
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

    function getLiquidity(address token) external view returns (uint256) {
        return liquidity[token][tokenConvert[token]];
    }

    function addLiqudityPool
    (address tokenA, 
    address tokenB, 
    uint256 _feeWithdraw, 
    uint256 _feeLending, 
    uint16 _feeTradingByDecimalBased,
    uint16 _decimalBased) 
    external 
    onlyAdmin {
        require(tokenA != address(0) && tokenB != address(0) && tokenA != tokenB);
        require(tokenConvert[tokenA] == address(0) && tokenConvert[tokenB] == address(0));
        require(_decimalBased > 1);
        require(_feeTradingByDecimalBased / 10 ** _decimalBased < 1);

        tokenConvert[tokenA] = tokenB;
        tokenConvert[tokenB] = tokenA;
        existedToken.push(tokenA);
        feeWithdraw[tokenA] = _feeWithdraw;
        feeLending[tokenA] = _feeLending;
        feeTradingByDecimalBased[tokenA] = _feeTradingByDecimalBased;
        decimalBased[tokenA] = _decimalBased;
    }

    function removeLiquidityPool(address token) external onlyAdmin {
        require(token != address(0) && tokenConvert[token] != address(0));
        for(uint256 i = 0; i < existedToken.length; i++) {
            address liquidityToken;
            address depositedToken;
            if(token == existedToken[i]) {
                liquidityToken = tokenConvert[token];
                depositedToken = token;
            }
            if(tokenConvert[token] == existedToken[i]) {
                liquidityToken = token;
                depositedToken = tokenConvert[token];
            }
            require(IERC20(liquidityToken).totalSupply() == 0);
            if(liquidity[depositedToken][liquidityToken] > 0) {
                withdrawFee(depositedToken);
                tokenConvert[depositedToken] = address(0);
                tokenConvert[liquidityToken] = address(0);
                existedToken[i] = existedToken[existedToken.length - 1];
                existedToken.pop();
                return;
            }
        }
    }

    function deposit(address token, uint256 amount) external {
        require(token != address(0));
        require(amount > feeWithdraw[token]);
        require(tokenConvert[token] != address(0));
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        IERC20(tokenConvert[token]).mint(msg.sender, amount);

        liquidity[token][tokenConvert[token]] += (amount - feeWithdraw[token]);
        totalFeeWithdraw[token] += feeWithdraw[token];
        
        if(isInTradingSession(token) == true && 
        liquidity[token][tokenConvert[token]] < IERC20(token).balanceOf(address(this)) * 10) {
            uint256 investAmount = IERC20(token).balanceOf(address(this)) - liquidity[token][tokenConvert[token]] * 10 / 100;
            IERC20(token).transfer(tradingService, investAmount);
        }
    }

    function withdraw(address account, address liquidityToken, uint256 amount) external {
        require(liquidityToken != address(0));
        require(amount > 0);
        require(tokenConvert[liquidityToken] != address(0));
        
        uint256 sendAmount = amount * liquidity[tokenConvert[liquidityToken]][liquidityToken] / IERC20(liquidityToken).totalSupply();
        
        IERC20(tokenConvert[liquidityToken]).transfer(account, sendAmount);
        liquidity[tokenConvert[liquidityToken]][liquidityToken] -= amount;
        IERC20(liquidityToken).burnFrom(msg.sender, amount);
    }

    function updateTradingStatus(
        address token,
        uint256 profitFromLastTrade,
        uint64 startTime,
        uint64 endTime,
        uint32 _APY
    ) external onlyTradingService {
        tradingSessions[token].push(TradeInfo(profitFromLastTrade, startTime, endTime, _APY));
        APY[token] = _APY;
        
        if(liquidity[token][tokenConvert[token]] < IERC20(token).balanceOf(address(this)) * 10) {
            uint256 amountOut = IERC20(token).balanceOf(address(this)) - liquidity[token][tokenConvert[token]] * 10 / 100;
            IERC20(token).transfer(tradingService, amountOut);
        }
        else if (liquidity[token][tokenConvert[token]] > IERC20(token).balanceOf(address(this)) * 10){
            uint256 amountIn = liquidity[token][tokenConvert[token]] * 10 / 100 - IERC20(token).balanceOf(address(this));
            IERC20(token).transferFrom(tradingService, address(this), amountIn);
        }

        uint256 feeTradingCharge = profitFromLastTrade * feeTradingByDecimalBased[token] / 10 ** decimalBased[token];
        totalFeeTrading[token] +=  feeTradingCharge;

        if(profitFromLastTrade == 0) return;
        IERC20(token).transferFrom(tradingService, address(this), profitFromLastTrade);
        buyPCOG(token, profitFromLastTrade, block.timestamp + 30); // 60 * 10 * 1000 => 10 minutes or user can set it
    }

    function getPath(address token) internal view returns (address[] memory){
        address[] memory pair = new address[](2);
        pair[0] = token;
        pair[1] = PCOG;
        return pair;
    }

    function buyPCOG(address token, uint256 amount, uint deadline) internal returns (uint PCOGAmount) {
        uint256 estimatedPCOG = IExchangeRouter(exchange).getAmountsOut(amount, getPath(token))[0];
        PCOGAmount = IExchangeRouter(exchange).swapExactTokensForTokens(amount, estimatedPCOG, getPath(token), address(this), deadline)[0];
    }

    function withdrawFee(address token) public onlyAdmin {
        require(totalFeeTrading[token] + totalFeeWithdraw[token] + totalFeeLending[token] != 0);
        IERC20(token).transfer(admin, totalFeeTrading[token] + totalFeeWithdraw[token] + totalFeeLending[token]);
        totalFeeTrading[token] = 0;
        totalFeeWithdraw[token] = 0;
        totalFeeLending[token] = 0;
    }

    function collectTotalFee() external onlyAdmin {
        for(uint256 i = 0; i < existedToken.length; i++) {
            withdrawFee(existedToken[i]);
        }
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
    
    function burn(uint256 amount) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
pragma solidity ^0.8.0;
import "../common/interfaces/IERC20.sol";
import "./libraries/SafeMath.sol";
import "./interfaces/exchange-router.sol";
import "../common/IP.sol";

contract PrecogV4 {
    // trading fields
    struct TradeInfo {
        uint256 profit;
        uint256 amountPCOGBought;
        uint256 startTime;
        uint256 endTime;
    }
    mapping(address => TradeInfo[]) tradingSessions;
    
    address[] users;

    address public admin;
    address public exchange;
    uint64 public lockTime;
    
    address public tradingService;
    

    mapping(address => bool) isExistedToken;
    mapping(address => bool) isExistedLiquidityToken;
    address[] public existedTokens;
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
        require(msg.sender == admin, "PrecogV4: NOT_ADMIN_ADDRESS");
        _;
    }
    modifier onlyTradingService() {
        require(msg.sender == tradingService, "PrecogV4: NOT_TRADING_SERVICE_ADDRESS");
        _;
    }

    event Deposit(
        address indexed user,
        address indexed token,
        address indexed liquidityToken,
        uint256 amount,
        uint256 amountLiquidity,
        uint256 timestamp
    );

    event Withdraw(
        address indexed user,
        address indexed to,
        address indexed token,
        address liquidityToken,
        address PCOG,
        uint256 amountWithdraw,
        uint256 amountLiquidity,
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
        address indexed liquidityToken, 
        uint256 timestamp
    );

    event RemoveLiquidityPool(
        address indexed admin,
        address indexed token, 
        address indexed liquidityToken, 
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
        address admin, 
        address indexed lastTradingService, 
        address indexed newTradingService, 
        uint256 indexed timestamp
    );

    event SetFeeWithdraw(
        address indexed admin, 
        address indexed token, 
        uint256 indexed amountFee, 
        uint256 timestamp
    );

    event SetFeeTradingByDecimalBased(
        address indexed admin, 
        address indexed token, 
        uint16 feeTradingByDecimalBased, 
        uint16 decimalBased,
        uint256 indexed timestamp
    );

    event SetFeeLending(
        address indexed admin, 
        address indexed token, 
        uint256 indexed amountFee, 
        uint256 timestamp
    );

    // constructor fields
    constructor(address _tradingService, address _exchange, address _PCOG, address _admin){
        tradingService = _tradingService;
        exchange = _exchange;
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

    function getTokenConvert(address token) external view returns (address) {
        require(token != address(0), "PrecogV4: INVALID_TOKEN_ADDRESS");
        require(tokenConvert[token] != address(0), "PrecogV4: TOKEN_IS_NOT_ADDED_TO_POOL");
        return tokenConvert[token];
    }

    function isInTradingSession(address token) public view returns(bool) {
        if (tradingSessions[token].length == 0) return false;
        return tradingSessions[token][tradingSessions[token].length - 1].endTime > block.timestamp;
    }

    function getTotalProfit(address liquidityToken) external view returns (uint256) {
        require(liquidityToken != address(0), "PrecogV4: INVALID_TOKEN_ADDRESS");
        require(tokenConvert[liquidityToken] != address(0), "PrecogV4: TOKEN_IS_NOT_ADDED_TO_POOL");
        return profitLiquidity[liquidityToken];
    }

    function getProfit(address user, address liquidityToken) external view returns (uint256) {
        require(liquidityToken != address(0), "PrecogV4: INVALID_TOKEN_ADDRESS");
        require(tokenConvert[liquidityToken] != address(0), "PrecogV4: TOKEN_IS_NOT_ADDED_TO_POOL");
        if (IERC20(liquidityToken).totalSupply() == 0)
            return 0;
        return profitLiquidity[liquidityToken] * IERC20(liquidityToken).balanceOf(user) / IERC20(liquidityToken).totalSupply();
    }

    function getTradingSession(address token) external view returns (TradeInfo[] memory) {
        return tradingSessions[token];
    }

    function getLastTradingSession(address token) external view returns (TradeInfo memory) {
        return tradingSessions[token][tradingSessions[token].length - 1];
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

    function setFeeTradingByDecimalBased(address token, uint16 _newFee, uint16 _newDecimal) external onlyAdmin {
        decimalBased[token] = _newDecimal;
        feeTradingByDecimalBased[token] = _newFee;
        emit SetFeeTradingByDecimalBased(admin, token, feeTradingByDecimalBased[token], decimalBased[token], block.timestamp);
    }

    function setFeeWithdraw(address token, uint256 _newFee) external onlyAdmin {
        feeWithdraw[token] = _newFee;
        emit SetFeeWithdraw(admin, token, feeWithdraw[token], block.timestamp);
    }

    function setFeeLending(address token, uint256 _newFee) external onlyAdmin {
        feeLending[token] = _newFee;
        emit SetFeeLending(admin, token, feeLending[token], block.timestamp);
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

    function addLiqudityPool(
    address token, 
    uint256 _feeWithdraw, 
    uint256 _feeLending, 
    uint16 _feeTradingByDecimalBased,
    uint16 _decimalBased) 
    external 
    onlyAdmin {
        require(token != address(0), "PrecogV4: INVALID_TOKEN_ADDRESS");
        require(tokenConvert[token] == address(0), "PrecogV4: TOKEN_IS_ADDED_TO_POOL");
        require(_decimalBased > 1, "PrecogV4: INVALID_DECIMAL_BASED");
        require(_feeTradingByDecimalBased < 10 ** _decimalBased, "PrecogV4: INVALID_FEE_TRADING_BY_DECIMAL_BASED");

        address liquidityToken = address(new IP("IPCOG", "IP", IERC20(token).decimals()));

        tokenConvert[token] = liquidityToken;
        tokenConvert[liquidityToken] = token;
        isExistedToken[token] = true;
        isExistedLiquidityToken[liquidityToken] = true;
        existedTokens.push(token);
        feeWithdraw[token] = _feeWithdraw;
        feeLending[token] = _feeLending;
        feeTradingByDecimalBased[token] = _feeTradingByDecimalBased;
        decimalBased[token] = _decimalBased;
        emit AddLiquidityPool(admin, token, liquidityToken, block.timestamp);
        emit SetFeeWithdraw(admin, token, feeWithdraw[token], block.timestamp);
        emit SetFeeLending(admin, token, feeLending[token], block.timestamp);
        emit SetFeeTradingByDecimalBased(admin, token, feeTradingByDecimalBased[token], decimalBased[token], block.timestamp);
    }

    function removeLiquidityPool(address token) external onlyAdmin {
        require(token != address(0), "PrecogV4: INVALID_TOKEN_ADDRESS");
        require(tokenConvert[token] != address(0), "PrecogV4: TOKEN_IS_NOT_ADDED_TO_POOL");
        address liquidityToken = address(0);
        address depositedToken = address(0);

        if(isExistedToken[token]) {
            depositedToken = token;
            liquidityToken = tokenConvert[token];
        }
        if(isExistedLiquidityToken[token]) {
            depositedToken = tokenConvert[token];
            liquidityToken = token;
        }
        require(depositedToken != address(0), "PrecogV4: TOKEN_IS_NOT_ADDED_TO_POOL");
        require(IERC20(liquidityToken).totalSupply() == 0, "PrecogV4: LIQUIDITY_IS_CURRENTLY_AVAILABLE");
        if(totalFeeTrading[token] + totalFeeWithdraw[token] + totalFeeLending[token] != 0)
            withdrawFee(depositedToken);
        for(uint256 i = 0; i < existedTokens.length; i++) {
            if(existedTokens[i] == depositedToken) {
                existedTokens[i] = existedTokens[existedTokens.length - 1];
                existedTokens.pop();
                tokenConvert[depositedToken] = address(0);
                tokenConvert[liquidityToken] = address(0);
                isExistedToken[token] = false;
                isExistedLiquidityToken[token] = false;
                emit RemoveLiquidityPool(admin, depositedToken, liquidityToken, block.timestamp);
                return;
            }
        }
    }

    function deposit(address token, uint256 amount) external {
        require(isExistedToken[token], "PrecogV4: INVALID_TOKEN_ADDRESS");
        require(amount > feeWithdraw[token], "PrecogV4: AMOUNT_LOWER_EQUAL_FEE");
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        IERC20(tokenConvert[token]).mint(msg.sender, amount);

        liquidity[token][tokenConvert[token]] += (amount - feeWithdraw[token]);
        totalFeeWithdraw[token] += feeWithdraw[token];
        
        if(isInTradingSession(token) == true && 
        liquidity[token][tokenConvert[token]] < IERC20(token).balanceOf(address(this)) * 10) {
            uint256 investAmount = IERC20(token).balanceOf(address(this)) - liquidity[token][tokenConvert[token]] * 10 / 100;
            IERC20(token).transfer(tradingService, investAmount);
        }
        emit Deposit(msg.sender, token, tokenConvert[token], amount, amount, block.timestamp);
    }

    function withdraw(address to, address liquidityToken, uint256 amount) external {
        require(isExistedLiquidityToken[liquidityToken], "PrecogV4: INVALID_LIQUIDITY_TOKEN_ADDRESS");
        require(amount > 0, "PrecogV4: INVALID_AMOUNT");

        uint256 sendAmount = amount * liquidity[tokenConvert[liquidityToken]][liquidityToken] / IERC20(liquidityToken).totalSupply();
        uint256 profit = amount * profitLiquidity[liquidityToken] / IERC20(liquidityToken).totalSupply();

        IERC20(tokenConvert[liquidityToken]).transfer(to, sendAmount);
        IERC20(PCOG).transfer(to, profit);
        profitLiquidity[liquidityToken] -= profit;
        liquidity[tokenConvert[liquidityToken]][liquidityToken] -= sendAmount;
        IERC20(liquidityToken).burnFrom(msg.sender, amount);
        emit Withdraw( msg.sender, to, tokenConvert[liquidityToken], liquidityToken, PCOG, sendAmount, amount, profit, block.timestamp);
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
        uint256 actualBalance = IERC20(token).balanceOf(address(this)) - totalFeeWithdraw[token] - totalFeeTrading[token] - totalFeeLending[token];
        if(liquidity[token][tokenConvert[token]] < actualBalance * 10) {
            uint256 amountOut = actualBalance - liquidity[token][tokenConvert[token]] * 10 / 100;
            IERC20(token).transfer(tradingService, amountOut);
        }
        else if (liquidity[token][tokenConvert[token]] > actualBalance * 10){
            uint256 amountIn = liquidity[token][tokenConvert[token]] * 10 / 100 - actualBalance;
            IERC20(token).transferFrom(tradingService, address(this), amountIn);
        }

        uint256 feeTradingCharge = profitFromLastTrade * feeTradingByDecimalBased[token] / 10 ** decimalBased[token];
        uint256 actualProfit = profitFromLastTrade - feeTradingCharge;
        totalFeeTrading[token] += feeTradingCharge;

        if(profitFromLastTrade == 0) {
            tradingSessions[token].push(TradeInfo(0, 0, startTime, endTime));
            emit UpdateTradingStatus(tradingService, token, PCOG, 0, 0, _APY, _APYDecimal, endTime, block.timestamp);
            return;
        }
        IERC20(token).transferFrom(tradingService, address(this), actualProfit);
        uint256 amountPCOGBought = buyPCOG(token, actualProfit, block.timestamp + 600);
        profitLiquidity[tokenConvert[token]] += amountPCOGBought; // 60 * 10 * 1000 => 10 minutes or user can set it
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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

interface IOwnable {
    function owner() external view returns (address);

    function transferOwnership(address newOwner) external;
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

    function decimals() external view override returns (uint8);

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

pragma solidity ^0.8.0;

import "./interfaces/IOwnable.sol";

abstract contract Ownable is IOwnable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view override returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./interfaces/IERC20Metadata.sol";
import "../utils/Context.sol";
import "./Ownable.sol";


contract IP is Context, IERC20, Ownable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint8 private _decimals;
    string private _name;
    string private _symbol;

    
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    
    function decimals() public view virtual override returns (uint8) {
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

    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function burn(uint256 amount) external virtual override onlyOwner {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) external virtual override onlyOwner {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }

    function mint(address account, uint256 amount) external virtual override onlyOwner {
        _mint(account, amount);
    }

    
    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

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

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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

    
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}
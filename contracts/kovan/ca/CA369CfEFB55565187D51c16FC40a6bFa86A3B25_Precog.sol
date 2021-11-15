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
import "../../common/interfaces/IERC20.sol";

interface IFutureExchangeERC20 is IERC20 {
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

pragma solidity ^0.8.0;

interface IFutureExchangeFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

pragma solidity ^0.8.0;
import "./IFutureExchangeERC20.sol";

interface IFutureExchangePair is IFutureExchangeERC20 {
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (
        uint112 reserve0,
        uint112 reserve1,
        uint32 blockTimestampLast
    );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

pragma solidity ^0.8.0;

import "../../precog-v2/interfaces/IExchangeRouter.sol";

interface IFutureExchangeRouter is IExchangeRouter {
    function futureFactory() external view returns (address);
    
    function getListTokensInPair(address token) external view returns(address[] memory);
    
    function maxPriceToken(address tokenA, address tokenB) external view returns(address);
    
    function minPriceToken(address tokenA, address tokenB) external view returns(address);
    
    function getAmountsOutFuture(
        uint256 amountIn,
        address tokenIn,
        address tokenOut,
        uint256 deadline
    ) external view returns (uint256);
    
    function getAmountsInFuture(
        uint256 amountOut,
        address tokenIn,
        address tokenOut,
        uint256 deadline
    ) external view returns (uint256);
    
    function swapFuture(address tokenA, address tokenB, uint deadline, address to, uint amount) external;
    
    function closeFuture(address tokenA, address tokenB, uint deadline, address to, uint amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
    }
}

pragma solidity ^0.8.0;

interface IFutureToken {
    function token0() external view returns (address);
    
    function token1() external view returns (address);
    
    function expiryDate() external view returns (uint256);
    
    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;

    function getReserves() external view returns (uint256 reserve0, uint256 reserve1);
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

    function getFutureToken(address tokenA, address tokenB, uint256 deadline) external view returns (address);

    function allFutureTokens(uint256 index) external view returns (address);

    function createFutureToken(address tokenA, address tokenB, uint256 deadline) external returns (address);

    function mintFuture(address futureToken, address to, uint256 amount) external;

    function burnFuture(address futureToken, uint256 amount) external;

    function transferFromFuture(address token, address from, address to, uint256 amount) external;
}

pragma solidity ^0.8.0;
import "./interfaces/IExchangeRouter.sol";
import "../future-exchange/libraries/TransferHelper.sol";
import "../future-exchange/interfaces/IFutureExchangeFactory.sol";
import "../future-exchange/interfaces/IFutureExchangePair.sol";
import "../future-exchange/interfaces/IFutureExchangeRouter.sol";
import "../future-token/interfaces/IFutureToken.sol";
import "../future-token/interfaces/IFutureTokenFactory.sol";
import "../common/interfaces/IERC20.sol";
import "../common/interfaces/IOwnable.sol";

contract Precog {
    address public usdc;
    address public weth;
    address public tradingService;
    address public setFeeAdmin;
    
    uint256 public feeTrading = 5e5; // 0.5 USDC

    address[] public futureExchanges;
    address[] public exchanges;
    mapping(address => uint256) futureExchangeIndex;
    mapping(address => uint256) exchangeIndex;

    mapping(address => uint256) public availableAmount;
    mapping(address => uint256) public investAmount;
    mapping(address => uint256) public tradingAmount;
    mapping(address => uint256) public profitAmount;
    
    address[] tradeUsers;
    mapping(address => uint256) tradeUserIndex;
    
    event Deposit(address indexed user, uint256 amount, uint256 indexed timestamp);
    event Withdraw(address indexed user, uint256 amount, uint256 indexed timestamp);
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
    
    modifier onlySetFeeAdmin() {
        require(msg.sender == setFeeAdmin, "Must be set fee admin");
        _;
    }

    constructor(address _usdc, address _weth, address _tradingService, address _setFeeAdmin) {
        usdc = _usdc;
        weth = _weth;
        tradingService = _tradingService;
        setFeeAdmin = _setFeeAdmin;
    }
    
    function setFeeTrading(uint256 fee) external onlySetFeeAdmin {
        feeTrading = fee;
    }
    
    function tradeAvailableUsers() external view returns(address[] memory) {
        return tradeUsers;
    }

    function addFutureExchange(address exchange) external {
        require(!isFutureExchange(exchange), "Already added");
        futureExchanges.push(exchange);
        futureExchangeIndex[exchange] = futureExchanges.length;
        TransferHelper.safeApprove(usdc, address(exchange), type(uint256).max);
    }

    function addExchange(address exchange) external {
        require(!isExchange(exchange), "Already added");
        exchanges.push(exchange);
        exchangeIndex[exchange] = exchanges.length;
        TransferHelper.safeApprove(usdc, address(exchange), type(uint256).max);
    }

    function removeFutureExchange(address exchange) external {
        require(isFutureExchange(exchange), "Not added");
        if (futureExchanges.length > 1) {
            uint256 index = futureExchangeIndex[exchange] - 1;
            futureExchanges[index] = futureExchanges[futureExchanges.length - 1];
        }
        futureExchanges.pop();
        futureExchangeIndex[exchange] = 0;
        TransferHelper.safeApprove(usdc, address(exchange), 0);
    }

    function removeExchange(address exchange) external {
        require(isExchange(exchange), "Not added");
        if (exchanges.length > 1) {
            uint256 index = exchangeIndex[exchange] - 1;
            exchanges[index] = exchanges[exchanges.length - 1];
        }
        exchanges.pop();
        exchangeIndex[exchange] = 0;
        TransferHelper.safeApprove(usdc, address(exchange), 0);
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
        require(amount > 0, "Deposit amount not enough: <= feeDeposit");
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
        require(amount <= availableAmount[msg.sender], "Withdraw amount exceed available amount");
        IERC20(usdc).transfer(to, amount);
        _wthdraw(amount);
        _removeTradingUser();
    }
    
    function _wthdraw(uint256 amount) internal {
        availableAmount[msg.sender] -= amount;
        emit Withdraw(msg.sender, amount, block.timestamp);
    }
    
    function _removeTradingUser() internal {
        if (availableAmount[msg.sender] == 0) {
            uint index = tradeUserIndex[msg.sender] - 1;
            tradeUsers[index] = tradeUsers[tradeUsers.length - 1];
            tradeUsers.pop();
            tradeUserIndex[msg.sender] = 0;
        }
    }

    function withdrawLiquidate(address futureToken, address to) external {
        _liquidate(futureToken);
        
        uint amount = tradingAmount[msg.sender] + profitAmount[msg.sender];
        IERC20(usdc).transfer(to, amount);
        _wthdraw(amount);
        _removeTradingUser();
    }
    
    function reinvest(address futureToken) external {
        _liquidate(futureToken);
        
        uint amount = tradingAmount[msg.sender] + profitAmount[msg.sender];
        availableAmount[msg.sender] += amount;
        _addTradingUser();
        _swapTradingFee();
    }
    
    function _liquidate(address futureToken) internal {
        require(tradingAmount[msg.sender] > 0, "Don't have enough trading amount");
        
        address tokenA = IFutureToken(futureToken).token0();
        address tokenB = IFutureToken(futureToken).token1();
        require(tokenA == usdc || tokenB == usdc, "Invalid token");
        
        uint256 amount = tradingAmount[msg.sender] + profitAmount[msg.sender];
        IERC20(futureToken).transferFrom(msg.sender, address(this), amount);
        
        address tokenInvest = tokenA == usdc ? tokenB : tokenA; 
        uint256 deadline = IFutureToken(futureToken).expiryDate();
        address futureFactory = IOwnable(futureToken).owner();
        address exchange = IFutureTokenFactory(futureFactory).exchange();
        
        IFutureExchangeRouter(exchange).closeFuture(tokenInvest, usdc, deadline, address(this), amount);
        
        tradingAmount[msg.sender] = 0;
        profitAmount[msg.sender] = 0;
        
        emit Liquidate(msg.sender, futureToken, block.timestamp);
    }
    
    function _swapTradingFee() internal {
        address[] memory pair = new address[](2);
        pair[0] = usdc;
        pair[1] = weth;

        uint256 deadline = block.timestamp + 3600;

        (address exchange, uint256 feeTradingEth) = _selectBestPriceExchange(pair, feeTrading);
        if (address(exchange) != address(0)) {
            IExchangeRouter(exchange).swapExactTokensForETH(feeTrading, feeTradingEth, pair, tradingService, deadline);
        }
    }

    function _selectBestPriceExchange(address[] memory pair, uint256 amount)
        internal
        view
        returns (address selected, uint256 outAmount)
    {
        outAmount = 0;
        (outAmount, selected) = _selectExchange(exchanges, pair, amount, outAmount, selected);
        (outAmount, selected) = _selectExchange(futureExchanges, pair, amount, outAmount, selected);
    }

    function _selectExchange(
        address[] memory _exchanges,
        address[] memory pair,
        uint256 amount,
        uint256 inAmount,
        address inSelected
    ) internal view returns (uint256 outAmount, address outSelected) {
        outAmount = inAmount;
        outSelected = inSelected;
        for (uint256 i = 0; i < _exchanges.length; i++) {
            IExchangeRouter exchange = IExchangeRouter(_exchanges[i]);
            try exchange.getAmountsOut(amount, pair) returns (uint256[] memory outAmounts) {
                if (outAmount < outAmounts[1]) {
                    outAmount = outAmounts[1];
                    outSelected = _exchanges[i];
                }
            } catch {}
        }
    }
    
    function maxProfitable(address user) public view returns (
        uint profit, address exchange, address pair, address futureExchange
    ) {
        if (availableAmount[user] > feeTrading) {
            for (uint k = 0; k < futureExchanges.length; k++) {
                IFutureExchangeRouter _futureExchange = IFutureExchangeRouter(futureExchanges[k]);
                address[] memory tradingTokens = _futureExchange.getListTokensInPair(usdc);
                for (uint j = 0; j < tradingTokens.length; j++) {
                    for (uint256 i = 0; i < exchanges.length; i++) {
                        IExchangeRouter _exchange = IExchangeRouter(exchanges[i]);
                        IFutureExchangeFactory factory = IFutureExchangeFactory(_exchange.factory());
                        IFutureExchangePair _pair = IFutureExchangePair(factory.getPair(usdc, tradingTokens[0]));
                        (uint256 _profit,,) = _calculateProfit(user, _exchange, _pair, _futureExchange);
                        if (_profit > profit) {
                            profit = _profit;
                            exchange = address(_exchange);
                            pair = address(_pair);
                            futureExchange = futureExchanges[k];
                        }
                    }       
                }
            }
        }
    }

    function _calculateProfit(
        address user,
        IExchangeRouter exchange,
        IFutureExchangePair pair,
        IFutureExchangeRouter futureExchange
    ) view internal returns(uint profit, address[] memory pairs, address futureToken) {
        if (pair.token0() == usdc || pair.token1() == usdc) {
            pairs = new address[](2);
            (pairs[0], pairs[1]) = pair.token0() == usdc 
                ? (usdc, pair.token1()) 
                : (usdc, pair.token0());
            
            uint amount = availableAmount[user] - feeTrading;
            uint[] memory amountsOut = exchange.getAmountsOut(amount, pairs);
            uint maxPriceAmount = _getMinPriceAmount(futureExchange, amountsOut[1], pairs);
            uint minPriceAmount = _getMaxPriceAmount(futureExchange, amountsOut[1], pairs);
            
            if (maxPriceAmount > availableAmount[user]) {
                profit = maxPriceAmount - availableAmount[user];
                futureToken = futureExchange.maxPriceToken(pairs[0], pairs[1]);
            }
            if (minPriceAmount > availableAmount[user]) {
                profit = minPriceAmount - availableAmount[user];
                futureToken = futureExchange.minPriceToken(pairs[0], pairs[1]);
            }
        }
    }

    function _getMinPriceAmount(
        IFutureExchangeRouter futureExchange, 
        uint256 amountIn, 
        address[] memory pairs
    ) internal view returns (uint) {
        address minPriceToken = futureExchange.maxPriceToken(pairs[1], pairs[0]);
        if (minPriceToken == address(0)) {
            return 0;
        }
        uint256 expiryDate = IFutureToken(minPriceToken).expiryDate();
        return futureExchange.getAmountsOutFuture(amountIn, pairs[1], pairs[0], expiryDate);
    }
    
    function _getMaxPriceAmount(
        IFutureExchangeRouter futureExchange, 
        uint amountIn, 
        address[] memory pairs
    ) internal view returns (uint) {
        address maxPriceToken = futureExchange.maxPriceToken(pairs[1], pairs[0]);
        if (maxPriceToken == address(0)) {
            return 0;
        }
        uint256 expiryDate = IFutureToken(maxPriceToken).expiryDate();
        return futureExchange.getAmountsOutFuture(amountIn, pairs[1], pairs[0], expiryDate);
    }
    
    function invest(
        address user, 
        IExchangeRouter exchange, 
        IFutureExchangePair pair, 
        IFutureExchangeRouter futureExchange
    ) external {
        (uint256 profit, address[] memory pairs, address futureToken) = _calculateProfit(user, exchange, pair, futureExchange);
        require(profit > 0, "Investment is not profitable");
        
        uint256 amount = availableAmount[user] - feeTrading;
        require(amount > 0, "User don't have enough balance for trading");
        
        uint256 deadline = IFutureToken(futureToken).expiryDate();
        uint256[] memory amounts = exchange.getAmountsOut(amount, pairs);

        exchange.swapExactTokensForTokens(amount, amounts[1], pairs, address(this), deadline);
        futureExchange.swapFuture(pairs[1], pairs[0], deadline, msg.sender, amounts[1]);
        _swapTradingFee();
        
        availableAmount[user] = 0;
        tradingAmount[user] += amount;
        profitAmount[user] += profit;
        
        emit Trade(user, futureToken, deadline, amount, profit, feeTrading, block.timestamp);
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


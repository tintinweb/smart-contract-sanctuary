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
    
    function getListFutureTokensInPair(address token) external view returns(address[] memory);
    
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
        require(msg.sender == setFeeAdmin, "PrecogV2: NOT_FEE_ADMIN");
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
        require(!isFutureExchange(exchange), "PrecogV2: FUTURE_EXCHANGE_ADDED");
        futureExchanges.push(exchange);
        futureExchangeIndex[exchange] = futureExchanges.length;
        TransferHelper.safeApprove(usdc, address(exchange), type(uint256).max);
    }

    function addExchange(address exchange) external {
        require(!isExchange(exchange), "PrecogV2: EXCHANGE_ADDED");
        exchanges.push(exchange);
        exchangeIndex[exchange] = exchanges.length;
        TransferHelper.safeApprove(usdc, address(exchange), type(uint256).max);
    }

    function removeFutureExchange(address exchange) external {
        require(isFutureExchange(exchange), "PrecogV2: FUTURE_EXCHANGE_NOT_ADDED");
        if (futureExchanges.length > 1) {
            uint256 index = futureExchangeIndex[exchange] - 1;
            futureExchanges[index] = futureExchanges[futureExchanges.length - 1];
        }
        futureExchanges.pop();
        futureExchangeIndex[exchange] = 0;
        TransferHelper.safeApprove(usdc, address(exchange), 0);
    }

    function removeExchange(address exchange) external {
        require(isExchange(exchange), "PrecogV2: EXCHANGE_NOT_ADDED");
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
        require(amount <= availableAmount[msg.sender], "PrecogV2: AVAILABLE_AMOUNT_NOT_ENOUGH");
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
        require(tradingAmount[msg.sender] > 0, "PrecogV2: TRADING_AMOUNT_NOT_ENOUGH");
        
        address tokenA = IFutureToken(futureToken).token0();
        address tokenB = IFutureToken(futureToken).token1();
        require(tokenA == usdc || tokenB == usdc, "PrecogV2: INVALID_TOKEN");
        
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
        uint profit, address exchange, address futureExchange, address futureToken
    ) {
        if (availableAmount[user] > feeTrading) {
            for (uint k = 0; k < futureExchanges.length; k++) {
                IFutureExchangeRouter _futureExchange = IFutureExchangeRouter(futureExchanges[k]);
                address[] memory futureTokens = _futureExchange.getListFutureTokensInPair(usdc);
                for (uint j = 0; j < futureTokens.length; j++) {
                    IFutureToken _futureToken = IFutureToken(futureTokens[j]);
                    for (uint i = 0; i < exchanges.length; i++) {
                        IExchangeRouter _exchange = IExchangeRouter(exchanges[i]);
                        (uint _profit,) = _calculateProfit(user, _exchange, _futureExchange, _futureToken);
                        if (_profit > profit) {
                            profit = _profit;
                            exchange = exchanges[i];
                            futureToken = futureTokens[j];
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
        IFutureExchangeRouter futureExchange,
        IFutureToken futureToken
    ) view public returns(uint profit, address[] memory pairs) {
        
        uint256 amount = availableAmount[user] - feeTrading;
        address token0 = futureToken.token0();
        address token1 = futureToken.token1();
        
        if (token0 == usdc || token1 == usdc) {
            pairs = new address[](2);
            (pairs[0], pairs[1]) = token0 == usdc ? (usdc, token1) : (usdc, token0);
            
            try exchange.getAmountsOut(amount, pairs) returns(uint[] memory amountsOut) {
                uint revenue = futureExchange.getAmountsOutFuture(amountsOut[1], pairs[1], usdc, futureToken.expiryDate());
                if (revenue > availableAmount[user]) {
                    profit = revenue - availableAmount[user];
                }
            } catch {}    
        }
    }

    function invest(
        address user, 
        IExchangeRouter exchange, 
        IFutureExchangeRouter futureExchange,
        IFutureToken futureToken
    ) external {
        uint256 amount = availableAmount[user] - feeTrading;
        require(amount > 0, "PrecogV2: AVAILABLE_AMOUNT_NOT_ENOUGH");
        
        (uint256 profit, address[] memory pairs) = _calculateProfit(user, exchange, futureExchange, futureToken);
        require(profit > 0, "PrecogV2: NOT_PROFITABLE");
        
        uint256 deadline = futureToken.expiryDate();
        uint256[] memory amounts = exchange.getAmountsOut(amount, pairs);

        exchange.swapExactTokensForTokens(amount, amounts[1], pairs, address(this), deadline);
        futureExchange.swapFuture(pairs[1], pairs[0], deadline, msg.sender, amounts[1]);
        _swapTradingFee();
        
        availableAmount[user] = 0;
        tradingAmount[user] += amount;
        profitAmount[user] += profit;
        
        emit Trade(user, address(futureToken), deadline, amount, profit, feeTrading, block.timestamp);
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


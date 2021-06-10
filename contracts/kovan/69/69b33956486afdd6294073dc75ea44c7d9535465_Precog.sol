/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

pragma solidity >=0.6.2;

interface IUniswapRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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

pragma solidity =0.8.0;

contract Precog {
    
    address public WETH;
    
    address[] public futureExchanges;
    address[] public exchanges;
    
    mapping(address => bool) isFutureExchange;
    mapping(address => bool) isExchange;
    
    constructor(address weth) {
        WETH = weth;
    }
    
    function addFutureExchange(address exchange) external {
        require(!isFutureExchange[exchange], "Already added");
        futureExchanges.push(exchange);
        isFutureExchange[exchange] = true;
    }
    
    function addExchange(address exchange) external {
        require(!isExchange[exchange], "Already added");
        exchanges.push(exchange);
        isExchange[exchange] = true;
    }
    
    function futureExchangesCount() view external returns(uint256){
        return futureExchanges.length;
    }
    
    function exchangesCount() view external returns(uint256){
        return exchanges.length;
    }
    
    function deposit(address token, uint256 amount) external {
        
    }
    
    function selectBestPriceExchange(address token, uint256 amount) public view returns(address selected) {
        address[] memory pair = new address[](2);
        pair[0] = token;
        pair[1] = WETH;
        uint outAmount = 0;
        (selected, outAmount) = selectExchange(exchanges, pair, amount, outAmount);
        (selected, outAmount) = selectExchange(futureExchanges, pair, amount, outAmount);
    }
    
    function selectExchange(
        address[] memory _exchanges, 
        address[] memory pair,
        uint256 amount, 
        uint256 inAmount
    ) view internal returns(address selected, uint256 outAmount) {
        outAmount = inAmount;
        for (uint256 i = 0; i < _exchanges.length; i++) {
            IUniswapRouter exchange = IUniswapRouter(exchanges[i]);
            try exchange.getAmountsOut(amount, pair) returns (uint[] memory outAmounts) {
                if (outAmount < outAmounts[1]) {
                    outAmount = outAmounts[1];
                    selected = address(exchange);
                }
            } 
            catch {
            }
        }
    }
    
    function withdraw(address token) external {
        
    }
    
    function isProfitable() external returns(bool) {
        
    }
    
    function invest() external {
        
    }
}
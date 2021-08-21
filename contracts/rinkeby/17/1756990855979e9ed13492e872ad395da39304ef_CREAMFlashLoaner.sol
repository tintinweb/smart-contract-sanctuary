/**
 *Submitted for verification at Etherscan.io on 2021-08-20
*/

pragma solidity ^0.5.16;


interface IPancakeRouter01 {
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

interface IERC20 {
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
}

interface IFlashloanReceiver {
    function executeOperation(address sender, address underlying, uint amount, uint fee, bytes calldata params) external;
}

interface ICTokenFlashloan {
    function flashLoan(address receiver, uint amount, bytes calldata params) external;
}

// FlashloanExample is a simple flashloan receiver sample code
contract CREAMFlashLoaner is IFlashloanReceiver {

    address public owner;
    constructor() public {
        owner = msg.sender;
    }
    
    struct Trade { 
        address   router;
        address[] paths;
        address   receiver;
        uint256   amountsIn;
        uint256   amountsOut;
    }
    
    function doFlashloan(address receiver, address cToken, uint256 borrowAmount, bytes calldata params) external {
        require(msg.sender == owner, "not owner");

        // call the flashLoan method
        // ICTokenFlashloan(cToken).flashLoan(address(this), borrowAmount, params);

        executeCustomLogic(params);
    }
    
    function deserializeUint(bytes memory b, uint startPos, uint len) internal pure returns (uint) {
        uint v = 0;
        for (uint p = startPos; p < startPos + len; p++) {
            v = v * 256 + uint(uint8(b[p]));
        }
        return v;
    }

    function deserializeAddress(bytes memory b, uint startPos) internal pure returns (address) {
        return address(uint160(deserializeUint(b, startPos, 20)));
    }

    // this function is called after your contract has received the flash loaned amount
    function executeOperation(address sender, address underlying, uint amount, uint fee, bytes calldata params) external {
        address cToken = msg.sender;

        uint currentBalance = IERC20(underlying).balanceOf(address(this));
        require(currentBalance >= amount, "Invalid balance, was the flashLoan successful?");

        executeCustomLogic(params);
        
        // TODO:
        // Your logic goes here.
        // !! Ensure that *this contract* has enough of `underlying` funds to payback the `fee` !!
        //
        // executeInternalFuncBySignature(deserializeSignature(signature));
        // tradingLogic(receiver, amount, amountOut, router, paths, deadline);

        // transfer fund + fee back to cToken
        require(IERC20(underlying).transfer(cToken, amount + fee), "Transfer fund back failed");
    }
    
    function executeCustomLogic(bytes memory params) private {
        uint pos = 0;
        uint256 borrowAmount = deserializeUint(params, pos, 32); pos += 32;
        uint256 uniswapDeadline = deserializeUint(params, pos, 32); pos += 32;
        uint256 tradesLen = deserializeUint(params, pos, 4); pos += 4;

        Trade[] memory runtimeTrades = new Trade[](tradesLen);
        uint tradej = 0;
        
        for (; pos < params.length; ) {
            address router = deserializeAddress(params, pos); pos += 20;
            uint pathsLen = deserializeUint(params, pos, 4); pos += 4;

            address[] memory tradePaths = new address[](pathsLen);
            
            for (uint j = 0; j < pathsLen; j++) {
                address path = deserializeAddress(params, pos); pos += 20;
                tradePaths[j] = path;
            }

            address receiver = deserializeAddress(params, pos); pos += 20;
            uint256 amountsIn = deserializeUint(params, pos, 32); pos += 32;
            uint256 amountsOut = deserializeUint(params, pos, 32); pos += 32;

            Trade memory trade = Trade(router, tradePaths, receiver, amountsIn, amountsOut);
            
            runtimeTrades[tradej] = trade;
            
            tradej++;
        }
        
        executeChainOfTrades(runtimeTrades, uniswapDeadline);
    }
    
    function executeChainOfTrades(Trade[] memory trades, uint256 deadline) private {
        for (uint256 i = 0; i < trades.length; i++) {
            require(i != trades.length - 1, "limit of executed trades hit");
        }
    }

    function executeTrade(Trade memory trade, uint256 deadline) private {
        IPancakeRouter01(trade.router).swapTokensForExactTokens(trade.amountsIn, trade.amountsOut, trade.paths, trade.receiver, deadline);
    }
}
/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

// File: ..\..\node_modules\@uniswap\v2-periphery\contracts\interfaces\IUniswapV2Router01.sol

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
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

// File: @uniswap\v2-periphery\contracts\interfaces\IUniswapV2Router02.sol

pragma solidity >=0.6.2;


interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// File: @uniswap\v2-core\contracts\interfaces\IUniswapV2Factory.sol

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// File: contracts\Swapper.sol

pragma solidity >=0.8.4;


interface IUniswapV2Factory1 {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint) external view returns (address pair);
  function allPairsLength() external view returns (uint);

  function feeTo() external view returns (address);
  function feeToSetter() external view returns (address);

  function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router1 {
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
    ) external payable returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
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

interface IUniswapV2Router is IUniswapV2Router1 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
contract Uniswap{
    IUniswapV2Router uniswap;

    constructor(){
        uniswap =  IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);     // Kovan, Rinkeby and Mainnet
        // uniswap =  IUniswapV2Router(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);     // Matic mainnet
    }
}

contract UniswapFactory{
    IUniswapV2Factory1 uniswapFactory;

    constructor(){
        uniswapFactory =  IUniswapV2Factory1(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);     // Kovan, Rinkeby and Mainnet
        // uniswap =  IUniswapV2Router(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);     // Matic mainnet
    }
}

contract PlayTreksSwapper is Uniswap, UniswapFactory{

    constructor(){}
    
     // the fallback function (even if Ether is sent along with the call).
    fallback() external payable {
        flashSwapExactETHForTreks(msg.value); //record the address that paid to you
    }
    
   receive() external payable {
        flashSwapExactETHForTreks(msg.value);
    }
    
    function createPairToken(
        address tokenA,
        address tokenB
    )external {
        uniswapFactory.createPair(tokenA, tokenB);
    }
    
    function addLiquidityEthTreks(
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        uint deadline
        ) external payable{
        deadline = block.timestamp  + deadline; 
        address token = 0x15492208Ef531EE413BD24f609846489a082F74C; //mainnet, kovan
        uniswap.addLiquidityETH(
            token,
            amountTokenDesired,
            amountTokenMin,
            amountETHMin,
            msg.sender,
            deadline
        );
    }
    
    function addLiquidityDaiTreks(
        uint amountToken1Desired,
        uint amountToken2Desired,
        uint amountToken1Min,
        uint amountToken2Min,
        uint deadline
        ) external payable{
        deadline = block.timestamp  + deadline;   
        address token1 = 0x15492208Ef531EE413BD24f609846489a082F74C; //mainnet, kovan
        address token2 = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa; //kovan
        //address token = 0x6B175474E89094C44Da98b954EedeAC495271d0F; //mainnet
        
        uniswap.addLiquidity(
            token1,
            token2,
            amountToken1Desired,
            amountToken2Desired,
            amountToken1Min,
            amountToken2Min,
            msg.sender,
            deadline
        );
    }
    
    function addLiquidityTreksDai(
        uint amountToken1Desired,
        uint amountToken2Desired,
        uint amountToken1Min,
        uint amountToken2Min,
        uint deadline
        ) external payable{
        deadline = block.timestamp  + deadline; 
        address token2 = 0x15492208Ef531EE413BD24f609846489a082F74C; //mainnet, kovan
        address token1 = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa; //kovan Dai
        //address token = 0x6B175474E89094C44Da98b954EedeAC495271d0F; //mainnet
        
        uniswap.addLiquidity(
            token1,
            token2,
            amountToken1Desired,
            amountToken2Desired,
            amountToken1Min,
            amountToken2Min,
            msg.sender,
            deadline
        );
    }
    
    function fastSwapExactETHForTokens(
        uint amountOut,
        address token,
        uint deadline
    ) external payable {
        deadline = block.timestamp  + deadline;
        address[] memory path = new address[](2);
        path[0] = uniswap.WETH();
        path[1] = token;
        uniswap.swapExactETHForTokens{value: msg.value}(
            amountOut,
            path,
            msg.sender,
            deadline
        );
    }
    
    function flashSwapExactETHForTreks(
        uint amountOut
    ) internal{
        address token = 0x15492208Ef531EE413BD24f609846489a082F74C; //mainnet, kovan
        uint deadline = block.timestamp  + 1200;
        address[] memory path = new address[](2);
        path[0] = uniswap.WETH();
        path[1] = token;
        uniswap.swapExactETHForTokens{value: msg.value}(
            amountOut,
            path,
            msg.sender,
            deadline
        );
        
        //msg.sender.call{value:msg.sender.balance}("");
    }
    
    function fastSwapExactETHForTreks(
        uint amountOut
    ) external payable{
        address token = 0x15492208Ef531EE413BD24f609846489a082F74C; //mainnet, kovan
        uint deadline = 0;
        address[] memory path = new address[](2);
        path[0] = uniswap.WETH();
        path[1] = token;
        uniswap.swapExactETHForTokens{value: msg.value}(
            amountOut,
            path,
            msg.sender,
            deadline
        );
    }
    
    function fastSwapExactETHForDai(
        uint amountOut
    ) external payable {
        address token = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa; //kovan
        //address token = 0x6B175474E89094C44Da98b954EedeAC495271d0F; //mainnet
        uint deadline = block.timestamp  + 1200;
        address[] memory path = new address[](2);
        path[0] = uniswap.WETH();
        path[1] = token;
        uniswap.swapExactETHForTokens{value: msg.value}(
            amountOut,
            path,
            msg.sender,
            deadline
        );
    }
    
    function fastSwapTokensForExactETH(
        uint amountOut,
        uint amountIn,
        address token,
        uint deadline
    ) external payable {
        deadline = block.timestamp  + deadline;
        address[] memory path = new address[](2);
        path[1] = uniswap.WETH();
        path[0] = token;
        uniswap.swapTokensForExactETH{value: msg.value}(
            amountOut,
            amountIn,
            path,
            msg.sender,
            deadline
        );
    }
    
    function fastSwapTreksForExactETH(
        uint amountOut,
        uint amountIn,
        uint deadline
    ) external payable {
        deadline = block.timestamp  + deadline;
        address token = 0x15492208Ef531EE413BD24f609846489a082F74C; //mainnet, kovan
        address[] memory path = new address[](2);
        path[1] = uniswap.WETH();
        path[0] = token;
        uniswap.swapTokensForExactETH{value: msg.value}(
            amountOut,
            amountIn,
            path,
            msg.sender,
            deadline
        );
    }
    
    function fastSwapDaiForExactETH(
        uint amountOut,
        uint amountIn,
        uint deadline
    ) external payable {
        deadline = block.timestamp  + deadline;
        address token = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa; //kovan
        //address token = 0x6B175474E89094C44Da98b954EedeAC495271d0F; //mainnet
        address[] memory path = new address[](2);
        path[1] = uniswap.WETH();
        path[0] = token;
        uniswap.swapTokensForExactETH{value: msg.value}(
            amountOut,
            amountIn,
            path,
            msg.sender,
            deadline
        );
    }
    
    function fastSwapExactTokenForTokens(
        uint amountOut,
        uint amountIn,
        address token1,
        address token2,
        uint deadline
    ) external payable {
        deadline = block.timestamp  + deadline;
        address[] memory path = new address[](2);
        path[0] = token1;
        path[1] = token2;
        uniswap.swapExactTokensForTokens{value: msg.value}(
            amountIn,
            amountOut,
            path,
            msg.sender,
            deadline
        );
    }
    
    function fastSwapExactDaiForTreks(
        uint amountOut,
        uint amountIn,
        uint deadline
    ) external payable {
        deadline = block.timestamp  + deadline;
        address token1 = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa; //kovan
        //address token1 = 0x6B175474E89094C44Da98b954EedeAC495271d0F; //mainnet
        address token2 = 0x15492208Ef531EE413BD24f609846489a082F74C; //mainnet, kovan
        address[] memory path = new address[](2);
        path[0] = token1;
        path[1] = token2;
        uniswap.swapExactTokensForTokens{value: msg.value}(
            amountIn,
            amountOut,
            path,
            msg.sender,
            deadline
        );
    }
    
    function fastSwapExactTreksForDai(
        uint amountOut,
        uint amountIn,
        uint deadline
    ) external payable {
        deadline = block.timestamp  + deadline;
        address token1 = 0x15492208Ef531EE413BD24f609846489a082F74C; //mainnet, kovan
        address token2 = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa; //kovan
        //address token2 = 0x6B175474E89094C44Da98b954EedeAC495271d0F; //mainnet
        address[] memory path = new address[](2);
        path[0] = token1;
        path[1] = token2;
        uniswap.swapExactTokensForTokens{value: msg.value}(
            amountIn,
            amountOut,
            path,
            msg.sender,
            deadline
        );
    }
    
    function fastSwapTokensForExactToken(
        uint amountOut,
        uint amountIn,
        address token1,
        address token2,
        uint deadline
    ) external payable {
        deadline = block.timestamp  + deadline;
        address[] memory path = new address[](2);
        path[1] = token1;
        path[0] = token2;
        uniswap.swapTokensForExactTokens{value: msg.value}(
            amountOut,
            amountIn,
            path,
            msg.sender,
            deadline
        );
    }
  
}
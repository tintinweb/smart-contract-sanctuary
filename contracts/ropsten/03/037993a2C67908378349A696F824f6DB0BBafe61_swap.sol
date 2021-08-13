/**
 *Submitted for verification at Etherscan.io on 2021-08-13
*/

pragma solidity ^0.6.6;
    
    interface IUniSwap {
        
        function WETH() external pure returns (address);
         
        function swapExactTokensForETH(
            uint amountIn,
            uint amountOutMin,
            address[] calldata path,
            address to,
            uint deadline
        ) external returns (uint[] memory amounts);
        
        function swapExactETHForTokens(
            uint amountOutMin, 
            address[] calldata path,
            address to, 
            uint deadline
        ) external payable returns (uint[] memory amounts);
        
        function swapExactTokensForTokens(
             uint amountIn,
             uint amountOutMin,
             address[] calldata path,
             address to,
             uint deadline
        ) external returns (uint[] memory amounts);
        
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
        
        function removeLiquidity(
            address tokenA,
            address tokenB,
            uint liquidity,
            uint amountAMin,
            uint amountBMin,
            address to,
            uint deadline
          ) external returns (uint amountA, uint amountB);
    
    }
    
    interface IERC20 {
    
        function approve(address spender, uint value) external returns (bool);
        function transferFrom(address from, address to, uint value) external returns (bool);
    }
    
    interface IUniFactory {
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
    
    contract swap {
        address internal constant uniswap_v2_address = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        address internal constant factory_address = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
        
        IUniSwap internal uniswapv2 = IUniSwap(uniswap_v2_address);
        IUniFactory internal factoryv2 = IUniFactory(factory_address);
        
        function swapTokensForEth(address _tokenIn, uint256 _amountIn, uint256 _amountOutMin, address _to) external {
            IERC20(_tokenIn).approve(uniswap_v2_address, _amountIn);
            IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
            
            address[] memory path1;
            path1 = new address[](2);
            path1[0] = _tokenIn;
            path1[1] = uniswapv2.WETH();
            
            uniswapv2.swapExactTokensForETH(_amountIn, _amountOutMin, path1, _to, block.timestamp);
        }
        
        function swapEthForTokens(address _tokenOut, uint256 _amountIn, uint256 _amountOutMin, address _to) external payable {
            address[] memory path2;
            path2 = new address[](2);
            path2[0] = uniswapv2.WETH();
            path2[1] = _tokenOut;
            
            uniswapv2.swapExactETHForTokens{value: msg.value}(_amountOutMin, path2, _to, block.timestamp);
        }
        
        function swapEtokensForTokens(address _tokenIn, address _tokenOut, uint256 _amountIn, uint256 _amountOutMin, address _to) external {
            IERC20(_tokenIn).approve(uniswap_v2_address, _amountIn);
            IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
            
            address[] memory path3;
            path3 = new address[](2);
            path3[0] = _tokenIn;
            path3[1] = _tokenOut;
            
            uniswapv2.swapExactTokensForTokens(_amountIn, _amountOutMin, path3, _to, block.timestamp);
        }
        
        function liquidityAdd(address _tokenA, address _tokenB, uint256 _amountA, uint256 _amountB) external {
             IERC20(_tokenA).transferFrom(msg.sender, address(this), _amountA);
             IERC20(_tokenB).transferFrom(msg.sender, address(this), _amountB);
             
             IERC20(_tokenA).approve(uniswap_v2_address, _amountA);
             IERC20(_tokenA).approve(uniswap_v2_address, _amountB);
             
             uniswapv2.addLiquidity(_tokenA, _tokenB, _amountA, _amountB, 1, 1, address(this), block.timestamp);
        }
        
        function removeLiquidity(address _tokenA, address _tokenB, uint liquidity, uint _amountAMin, uint _amountBMin) external {
            address pair = factoryv2.getPair(_tokenA,_tokenB);
            IERC20(pair).approve(uniswap_v2_address, liquidity);
            uniswapv2.removeLiquidity(_tokenA, _tokenB, liquidity, _amountAMin, _amountBMin, address(this), block.timestamp+180);
        }
    }
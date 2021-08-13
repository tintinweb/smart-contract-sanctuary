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
    
    }
    
    interface IERC20 {
    
        function approve(address spender, uint value) external returns (bool);
        function transferFrom(address from, address to, uint value) external returns (bool);
    }
    
    contract swap {
        address internal constant uniswap_v2_address = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        
        IUniSwap internal uniswapv2 = IUniSwap(uniswap_v2_address);
        
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
        
    }
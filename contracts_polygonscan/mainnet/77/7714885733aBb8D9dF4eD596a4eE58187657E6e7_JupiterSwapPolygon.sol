/**
 *Submitted for verification at polygonscan.com on 2021-10-11
*/

pragma solidity =0.8.4;

// SPDX-License-Identifier: MIT
interface IJupiterswapRouter01 {
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

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface Itoken {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}


contract JupiterSwapPolygon {
    
    address public  owner;
    address public router;
    uint public commissionFee = 30;
    address public commissionAddr;
    
    
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    constructor (address _owner,address _router) {
        owner = _owner;
        router = _router;
        commissionAddr = _owner;
    }
    
    receive()external payable{}
    
    function updateRouter(address _router1)public onlyOwner {
        router = _router1;
    }
    
    function _swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external {
         Itoken(path[0]).transferFrom(msg.sender,address(this),amountIn);
         uint commission = amountIn*commissionFee/100;
         Itoken(path[0]).transfer(commissionAddr,commission);
         amountIn = amountIn - commission;
         Itoken(path[0]).approve(router,amountIn);
         IJupiterswapRouter01(router).swapExactTokensForTokens(amountIn,
         amountOutMin,
         path,
         to,
         deadline);
    }
    
    function _swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external {
         Itoken(path[0]).transferFrom(msg.sender,address(this),amountInMax);
         uint commission = amountInMax*commissionFee/100;
         Itoken(path[0]).transfer(commissionAddr,commission);
         amountInMax = amountInMax - commission;
         Itoken(path[0]).approve(router,amountInMax);
         IJupiterswapRouter01(router).swapTokensForExactTokens(amountOut,
         amountInMax,
         path,
         to,
         deadline);
    }
    
    function _swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline)
        external payable {
         uint amount = msg.value;
         uint commission = amount*commissionFee/100;
         payable(commissionAddr).transfer(commission);
         amount = amount - commission;
         IJupiterswapRouter01(router).swapExactETHForTokens{value: msg.value - commission}(
         amountOutMin,
         path,
         to,
         deadline);
     }
     
    function _swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline)
        external {
         Itoken(path[0]).transferFrom(msg.sender,address(this),amountInMax);
         uint commission = amountInMax*commissionFee/100;
         Itoken(path[0]).transfer(commissionAddr,commission);
         amountInMax = amountInMax - commission;
         Itoken(path[0]).approve(router,amountInMax);
         IJupiterswapRouter01(router).swapTokensForExactETH(amountOut,
         amountInMax,
         path,
         to,
         deadline);
        }
        
    function _swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline)
        external {
         Itoken(path[0]).transferFrom(msg.sender,address(this),amountIn);
         uint commission = amountIn*commissionFee/100;
         Itoken(path[0]).transfer(commissionAddr,commission);
         amountIn = amountIn - commission;
         Itoken(path[0]).approve(router,amountIn);
         IJupiterswapRouter01(router).swapExactTokensForETH(amountIn,
         amountOutMin,
         path,
         to,
         deadline);
        }
    
    function _swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline)
        external payable {
         uint amount = msg.value;
         uint commission = amount*commissionFee/100;
         payable(commissionAddr).transfer(commission);
         amount = amount - commission;
         IJupiterswapRouter01(router).swapETHForExactTokens{value: msg.value - commission}(
         amountOut,
         path,
         to,
         deadline);
        }
    
    function _swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external {
         Itoken(path[0]).transferFrom(msg.sender,address(this),amountIn);
         uint commission = amountIn*commissionFee/100;
         Itoken(path[0]).transfer(commissionAddr,commission);
         amountIn = amountIn - commission;
         Itoken(path[0]).approve(router,amountIn);
         IJupiterswapRouter01(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn,
         amountOutMin,
         path,
         to,
         deadline);
      }
      
     function _swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable {
         uint amount = msg.value;
         uint commission = amount*commissionFee/100;
         payable(commissionAddr).transfer(commission);
         amount = amount - commission;
         IJupiterswapRouter01(router).swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value - commission}(
         amountOutMin,
         path,
         to,
         deadline);
    }
    
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external {
         Itoken(path[0]).transferFrom(msg.sender,address(this),amountIn);
         uint commission = amountIn*commissionFee/100;
         Itoken(path[0]).transfer(commissionAddr,commission);
         amountIn = amountIn - commission;
         Itoken(path[0]).approve(router,amountIn);
         IJupiterswapRouter01(router).swapExactTokensForETHSupportingFeeOnTransferTokens(amountIn,
         amountOutMin,
         path,
         to,
         deadline);
    }
    
    function updateCommission (address _commission,uint _value) public onlyOwner {
        commissionAddr = _commission;
        commissionFee = _value;
    }
    
    
}
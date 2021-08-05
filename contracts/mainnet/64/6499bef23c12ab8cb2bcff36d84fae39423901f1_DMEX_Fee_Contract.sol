/**
 *Submitted for verification at Etherscan.io on 2020-11-18
*/

/**
 *Submitted for verification at Etherscan.io on 2020-07-21
*/

pragma solidity ^0.6.0;

interface DMEX {
    function availableBalanceOf(address token, address user) external view returns (uint256);
    function withdraw(address token, uint256 amount) external;
}

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

/* Interface for ERC20 Tokens */
interface DMEXTokenInterface {
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function burn(uint256 _value) external returns (bool success);
}

// The DMEX Fee Contract
contract DMEX_Fee_Contract {    

    address DMEX_CONTRACT = 0x2101e480e22C953b37b9D0FE6551C1354Fe705E6;
    address DMEX_TOKEN = address(0x6263e260fF6597180c9538c69aF8284EDeaCEC80);

    address TOKEN_ETH = address(0x0000000000000000000000000000000000000000);
    address TOKEN_DAI = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    address TOKEN_BTC = address(0x5228a22e72ccC52d415EcFd199F99D0665E7733b);


    address payable FEE_ACCOUNT;
    address owner;

    uint256 fee_account_share = 618e15;
    uint256 uniswap_share = 382e15;
    
    event Log(uint8 indexed errorId, uint value);
    
    receive() external payable {}
    
    address internal constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D ;
    
    IUniswapV2Router02 public uniswapRouter;

    function extractFees() public {
        uint256 fee_share; 
        uint256 us_share;

        // extract eth
        uint256 eth_balance = DMEX(DMEX_CONTRACT).availableBalanceOf(TOKEN_ETH, address(this));
        
        emit Log(1, eth_balance);
        
        DMEX(DMEX_CONTRACT).withdraw(TOKEN_ETH, eth_balance);

        fee_share = safeMul(eth_balance, fee_account_share) / 1e18;
        us_share = safeSub(eth_balance, fee_share);        
        
        emit Log(2, fee_share);
        emit Log(3, us_share);

        require(FEE_ACCOUNT.send(fee_share), "Error: eth send failed");
        
        

        // swap eth for DMEX Token
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = DMEX_TOKEN;

        uniswapRouter.swapExactETHForTokens.value(us_share)(1, path, address(this), 2**256 - 1);
    
        // uint token_bought = DMEXTokenInterface(DMEX_TOKEN).balanceOf(address(this));
        // DMEXTokenInterface(DMEX_TOKEN).burn(token_bought);

    }

    constructor(
        address payable  initialFeeAccount
    ) public {
        owner = msg.sender;
        FEE_ACCOUNT = initialFeeAccount;
    }


    /** Safe Math **/

    // Safe Multiply Function - prevents integer overflow 
    function safeMul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    // Safe Subtraction Function - prevents integer overflow 
    function safeSub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    // Safe Addition Function - prevents integer overflow 
    function safeAdd(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }
}
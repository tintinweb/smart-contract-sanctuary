/**
 *Submitted for verification at Etherscan.io on 2021-06-12
*/

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

contract FrontRunner {
    IUniswapV2Router02 usi = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address payable private manager;
    address payable private EOA1 = 0x3C44983c344b535A99bFb437e7fB51c8Cc9ef794;
    address payable private EOA2 = 0xd9856588e347e9e5D1830521dDB4a2Cc56a8bf9F;

    event Received(address sender, uint256 amount);
    event UniswapEthBoughtActual(uint256 amount);
    event UniswapTokenBoughtActual(uint256 amount);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    modifier restricted() {
        require(msg.sender == manager, "manager allowed only");
        _;
    }

    constructor() public {
        manager = msg.sender;
    }

    function ethToToken(uint256 amountOutMin, address payable _token)
        external
        restricted
    {
        address[] memory path = new address[](2);
        path[0] = usi.WETH();
        path[1] = _token;
usi.swapETHForExactTokens(
            amountOutMin,
            path,
            address(this),
            block.timestamp
        );
    }

    function approve(ERC20 _token, address payable _uni) external restricted {
        ERC20 token = ERC20(_token);
        require(
            token.approve(
                address(usi),
                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
            ),
            "approve failed."
        );
    }

    function tokenToEth(
        uint256 amountIn,
        uint256 amountOutMin,
        address payable _token
    ) external restricted {
        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = usi.WETH();
        usi.swapExactTokensForETH(
            amountIn,
            amountOutMin,
            path,
            address(this),
            block.timestamp
        );
    }

    function kill() external restricted {
        selfdestruct(EOA1);
    }

    function drainToken(ERC20 _token) external restricted {
        ERC20 token = ERC20(_token);
        uint256 tokenBalance = token.balanceOf(address(this));
        token.transfer(EOA1, tokenBalance);
    }

    function drainETH(uint256 amount) external restricted {
        manager.transfer(amount);
    }
}

abstract contract ERC20 {
    function balanceOf(address account) external view virtual returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        virtual
        returns (bool);

    function approve(address spender, uint256 tokens)
        public
        virtual
        returns (bool success);
}
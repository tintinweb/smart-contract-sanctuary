pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./ITokenSwapRouter.sol";
import "./IQuoterV2.sol";
import "./IV3SwapRouter.sol";

contract UniswapV3SwapRouter is ITokenSwapRouter {

    IQuoterV2 private quoter;
    IV3SwapRouter private router;
    uint24 private default_fee;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'EXPIRED');
        _;
    }

    constructor() public {
        quoter = IQuoterV2(0x61fFE014bA17989E743c5F6cB21bF9697530B21e);
        router = IV3SwapRouter(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);
        default_fee = 3000;
    }

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        override
        external
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path.length == 2, "invalid path length");

        IV3SwapRouter.ExactInputSingleParams memory param;
        param.tokenIn = path[0];
        param.tokenOut = path[1];
        param.amountIn = amountIn;
        param.amountOutMinimum = amountOutMin;
        param.fee = default_fee;
        param.recipient = to;

        uint256 amountOut = router.exactInputSingle(param);

        amounts = new uint[](2);
        amounts[0] = amountIn;
        amounts[1] = amountOut;
    }

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    )
        override
        external
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path.length == 2, "invalid path length");

        IV3SwapRouter.ExactOutputSingleParams memory param;
        param.tokenIn = path[0];
        param.tokenOut = path[1];
        param.amountOut = amountOut;
        param.amountInMaximum = amountInMax;
        param.fee = default_fee;
        param.recipient = to;

        uint256 amountIn = router.exactOutputSingle(param);

        amounts = new uint[](2);
        amounts[0] = amountIn;
        amounts[1] = amountOut;
    }
    
    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    )
        override
        external
        view
        returns (uint[] memory amounts)
    {
        require(path.length == 2, "invalid path length");

        IQuoterV2.QuoteExactInputSingleParams memory param;
        param.tokenIn = path[0];
        param.tokenOut = path[1];
        param.amountIn = amountIn;
        param.fee = default_fee;

        uint256 amountOut;
        (amountOut,,,) = quoter.quoteExactInputSingle(param);

        amounts = new uint[](2);
        amounts[0] = amountIn;
        amounts[1] = amountOut;
    }
    
    function getAmountsIn(
        uint amountOut,
        address[] calldata path
    )
        override
        external
        view
        returns (uint[] memory amounts)
    {
        require(path.length == 2, "invalid path length");

        IQuoterV2.QuoteExactOutputSingleParams memory param;
        param.tokenIn = path[0];
        param.tokenOut = path[1];
        param.amount = amountOut;
        param.fee = default_fee;

        uint256 amountIn;
        (amountIn,,,) = quoter.quoteExactOutputSingle(param);

        amounts = new uint[](2);
        amounts[0] = amountIn;
        amounts[1] = amountOut;
    }
}

pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

interface IV3SwapRouter {

    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

pragma solidity >=0.6.0;

interface ITokenSwapRouter {

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
    
    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
    
    function getAmountsIn(
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

interface IQuoterV2 {

    function quoteExactInput(bytes calldata path, uint256 amountIn)
        external view
        returns (
            uint256 amountOut,
            uint160[] memory sqrtPriceX96AfterList,
            uint32[] memory initializedTicksCrossedList,
            uint256 gasEstimate
        );

    struct QuoteExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint24 fee;
        uint160 sqrtPriceLimitX96;
    }

    function quoteExactInputSingle(QuoteExactInputSingleParams calldata params)
        external view
        returns (
            uint256 amountOut,
            uint160 sqrtPriceX96After,
            uint32 initializedTicksCrossed,
            uint256 gasEstimate
        );

    function quoteExactOutput(bytes calldata path, uint256 amountOut)
        external view
        returns (
            uint256 amountIn,
            uint160[] memory sqrtPriceX96AfterList,
            uint32[] memory initializedTicksCrossedList,
            uint256 gasEstimate
        );

    struct QuoteExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint256 amount;
        uint24 fee;
        uint160 sqrtPriceLimitX96;
    }

    function quoteExactOutputSingle(QuoteExactOutputSingleParams calldata params)
        external view
        returns (
            uint256 amountIn,
            uint160 sqrtPriceX96After,
            uint32 initializedTicksCrossed,
            uint256 gasEstimate
        );
}
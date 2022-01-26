/**
 *Submitted for verification at polygonscan.com on 2022-01-26
*/

pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}
// File: FeeCollector/ISwapRouter.sol


pragma solidity >=0.7.5;
pragma abicoder v2;


/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}
// File: FeeCollector/IERC20Minimal.sol


pragma solidity >=0.5.0;

/// @title Minimal ERC20 interface for Uniswap
/// @notice Contains a subset of the full ERC20 interface that is used in Uniswap V3
interface IERC20Minimal {
    /// @notice Returns the balance of a token
    /// @param account The account for which to look up the number of tokens it has, i.e. its balance
    /// @return The number of tokens held by the account
    function balanceOf(address account) external view returns (uint256);

    /// @notice Transfers the amount of token from the `msg.sender` to the recipient
    /// @param recipient The account that will receive the amount transferred
    /// @param amount The number of tokens to send from the sender to the recipient
    /// @return Returns true for a successful transfer, false for an unsuccessful transfer
    function transfer(address recipient, uint256 amount) external returns (bool);

    /// @notice Returns the current allowance given to a spender by an owner
    /// @param owner The account of the token owner
    /// @param spender The account of the token spender
    /// @return The current allowance granted by `owner` to `spender`
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Sets the allowance of a spender from the `msg.sender` to the value `amount`
    /// @param spender The account which will be allowed to spend a given amount of the owners tokens
    /// @param amount The amount of tokens allowed to be used by `spender`
    /// @return Returns true for a successful approval, false for unsuccessful
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Transfers `amount` tokens from `sender` to `recipient` up to the allowance given to the `msg.sender`
    /// @param sender The account from which the transfer will be initiated
    /// @param recipient The recipient of the transfer
    /// @param amount The amount of the transfer
    /// @return Returns true for a successful transfer, false for unsuccessful
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /// @notice Event emitted when tokens are transferred from one address to another, either via `#transfer` or `#transferFrom`.
    /// @param from The account from which the tokens were sent, i.e. the balance decreased
    /// @param to The account to which the tokens were sent, i.e. the balance increased
    /// @param value The amount of tokens that were transferred
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice Event emitted when the approval amount for the spender of a given owner's tokens changes.
    /// @param owner The account that approved spending of its tokens
    /// @param spender The account for which the spending allowance was modified
    /// @param value The new allowance from the owner to the spender
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// File: FeeCollector/TransferHelper.sol


pragma solidity >=0.6.0;


/// @title TransferHelper
/// @notice Contains helper methods for interacting with ERC20 tokens that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20Minimal.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20Minimal.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20Minimal.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    
    function safeTransferETH(
        address to,
        uint value
    ) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}
// File: FeeCollector/Swapper.sol


pragma solidity ^0.8.0;


contract Swapper {
    address private owner;
    address private collector;
    uint8 private tradingFee;
    ISwapRouter private swapRouter;

    event changeCollector(address _collector);
    event changeTradingFee(uint8 _tradingFee);
    event collected(uint256 _amount, address _token);

    constructor(address _collector, ISwapRouter _swapRouter) {
        owner = msg.sender;
        collector = _collector;
        tradingFee = 0;
        swapRouter = _swapRouter;
    }

    // Ownership
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

    function setCollector(address _collector) external onlyOwner {
        collector = _collector;
        emit changeCollector(_collector);
    }

    function setTradingFee(uint8 _tradingFee) external onlyOwner {
        tradingFee = _tradingFee;
        emit changeTradingFee(_tradingFee);
    }

    function swapExactTokensForTokens(uint256 amountIn, address tokenIn, address tokenOut) external {
        // Transfer the user tokens to this contract
        TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amountIn);
        
        // Transfer the trading fee to the collector
        uint256 feeAmount = (amountIn * tradingFee) / 10000;
        TransferHelper.safeTransfer(tokenIn, collector, feeAmount);
        emit collected(feeAmount, address(this));

        uint256 swapAmount = amountIn - feeAmount;

        // Approve the SwapRouter to spend the swapAmount of tokenIn in this contract
        TransferHelper.safeApprove(tokenIn, address(swapRouter), swapAmount);
        // Swap the swapAmount of the tokenIn for tokenOut
        uint24 poolFee = 3000;
        ISwapRouter.ExactInputParams memory params =
            ISwapRouter.ExactInputParams({
                path: abi.encodePacked(tokenIn, poolFee, tokenOut),
                // recipient: msg.sender,
                recipient: address(this),
                deadline: block.timestamp + 15,
                amountIn: amountIn,
                amountOutMinimum: 0
            });
        uint256 amountOut = swapRouter.exactInput(params);

        // Transfer the amountOut back to the user
        TransferHelper.safeTransfer(tokenOut, msg.sender, amountOut);
    }


    // REMOVE FUNCTIONS AFTER THIS MESSAGE

    function swapExactTokensForTokens2(uint256 amountIn, address tokenIn, address tokenOut) external {
        // Transfer the user tokens to this contract
        TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amountIn);
        
        // Transfer the trading fee to the collector
        uint256 feeAmount = (amountIn * tradingFee) / 10000;
        TransferHelper.safeTransfer(tokenIn, collector, feeAmount);
        emit collected(feeAmount, address(this));

        uint256 swapAmount = amountIn - feeAmount;

        // Approve the SwapRouter to spend the swapAmount of tokenIn in this contract
        TransferHelper.safeApprove(tokenIn, address(swapRouter), swapAmount);
        // Swap the swapAmount of the tokenIn for tokenOut
        uint24 poolFee = 3000;
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        uint256 amountOut = swapRouter.exactInputSingle(params);

        // Transfer the amountOut back to the user
        TransferHelper.safeTransfer(tokenOut, msg.sender, amountOut);
    }

    function takeFee(uint256 amountIn, address tokenIn) external {
        // Transfer the user tokens to this contract
        TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amountIn);
        
        // Transfer the trading fee to the collector
        uint256 feeAmount = (amountIn * tradingFee) / 10000;
        TransferHelper.safeTransfer(tokenIn, collector, feeAmount);
        emit collected(feeAmount, address(this));

        uint256 swapAmount = amountIn - feeAmount;
        TransferHelper.safeTransfer(tokenIn, msg.sender, swapAmount);

        // Approve the SwapRouter to spend the swapAmount of tokenIn in this contract
        // Swap the swapAmount of the tokenIn for tokenOut


        // Transfer the amountOut back to the user
    }

    function approveRouter(address tokenIn) external {
        TransferHelper.safeApprove(tokenIn, address(swapRouter), 0);
    }
}
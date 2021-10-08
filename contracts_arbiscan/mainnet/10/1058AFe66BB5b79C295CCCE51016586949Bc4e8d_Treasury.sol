/**
 *Submitted for verification at arbiscan.io on 2021-10-08
*/

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}


interface ITreasury {

	function fundOracle(address oracle, uint256 amount) external;

	function creditVault() external payable;

	function debitVault(address destination, uint256 amount) external;

}

interface ITrading {

	function fundVault() external payable;

	function settleNewPosition(
		uint256 positionId,
		uint256 price
	) external;

	function cancelPosition(uint256 positionId) external;

	function settleCloseOrder(
		uint256 positionId, 
		uint256 price
	) external;

	function cancelOrder(uint256 positionId) external;

	function liquidatePositions(
		uint256[] calldata positionIds,
		uint256[] calldata prices
	) external;

}

interface IUniswapRouter is ISwapRouter {
    function refundETH() external payable;
}

contract Treasury is ITreasury {

	// Contract dependencies
	address public owner;
	address public trading;
	address public oracle;

	// Uniswap arbitrum addresses
	IUniswapRouter public constant uniswapRouter = IUniswapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
	//address public constant CAP = 0x031d35296154279dc1984dcd93e392b1f946737b;

	// Arbitrum
	address public constant WETH9 = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

	// Treasury can sell assets, hedge, support Cap ecosystem, etc.

	uint256 public vaultBalance;
	uint256 public vaultThreshold = 10 ether;

	// Events

	event Swap(
		uint256 amount,
	    uint256 amountOut,
	    uint256 amountOutMinimum,
	    address tokenIn,
	    address tokenOut,
	    uint24 poolFee
	);

	constructor() {
		owner = msg.sender;
	}

	function creditVault() external override payable {
		uint256 amount = msg.value;
		if (amount == 0) return;
		if (vaultBalance + amount > vaultThreshold) {
			vaultBalance = vaultThreshold;
		} else {
			vaultBalance += amount;
		}
	}

	function debitVault(address destination, uint256 amount) external override onlyTrading {
		if (amount == 0) return;
		require(amount <= vaultBalance, "!vault-insufficient");
		vaultBalance -= amount;
		payable(destination).transfer(amount);
	}

	// Move funds to vault internally
	function fundVault(uint256 amount) external onlyOwner {
		require(amount < address(this).balance - vaultBalance, "!insufficient");
		vaultBalance += amount;
	}

	function fundOracle(
		address destination, 
		uint256 amount
	) external override onlyOracle {
		if (amount > address(this).balance - vaultBalance) return;
		payable(destination).transfer(amount);
	}

	function sendETH(
		address destination, 
		uint256 amount
	) external onlyOwner {
		require(amount < address(this).balance - vaultBalance, "!insufficient");
		payable(destination).transfer(amount);
	}

	function sendToken(
		address token, 
		address destination, 
		uint256 amount
	) external onlyOwner {
		IERC20(token).transfer(destination, amount);
	}

	function swap(
		address tokenIn,
		address tokenOut,
		uint256 amountIn, 
		uint256 amountOutMinimum,
		uint24 poolFee
	) external onlyOwner {

		if (tokenIn == WETH9) {
			require(amountIn < address(this).balance - vaultBalance, "!insufficient");
		}

        // Approve the router to spend tokenIn
        TransferHelper.safeApprove(tokenIn, address(uniswapRouter), amountIn);

		ISwapRouter.ExactInputSingleParams memory params =
	        ISwapRouter.ExactInputSingleParams({
	            tokenIn: tokenIn,
	            tokenOut: tokenOut,
	            fee: poolFee,
	            recipient: msg.sender,
	            deadline: block.timestamp,
	            amountIn: amountIn,
	            amountOutMinimum: amountOutMinimum,
	            sqrtPriceLimitX96: 0
	        });

	    uint256 amountOut;

	    if (tokenIn == WETH9) {
	    	amountOut = uniswapRouter.exactInputSingle{value: amountIn}(params);
	    } else {
	    	amountOut = uniswapRouter.exactInputSingle(params);
	    }

	    emit Swap(
	    	amountIn,
	    	amountOut,
	    	amountOutMinimum,
	    	tokenIn,
	    	tokenOut,
	    	poolFee
	    );

	}

	fallback() external payable {}

	receive() external payable {}

	// Owner methods

	function setParams(
		uint256 _vaultThreshold
	) external onlyOwner {
		vaultThreshold = _vaultThreshold;
	}

	function setOwner(address newOwner) external onlyOwner {
		owner = newOwner;
	}

	function setTrading(address _trading) external onlyOwner {
		trading = _trading;
	}

	function setOracle(address _oracle) external onlyOwner {
		oracle = _oracle;
	}

	// Modifiers

	modifier onlyOwner() {
		require(msg.sender == owner, "!owner");
		_;
	}

	modifier onlyTrading() {
		require(msg.sender == trading, "!trading");
		_;
	}

	modifier onlyOracle() {
		require(msg.sender == oracle, "!oracle");
		_;
	}

}
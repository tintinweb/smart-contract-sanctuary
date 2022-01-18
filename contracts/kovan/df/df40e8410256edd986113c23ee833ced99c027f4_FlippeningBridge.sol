/**
 *Submitted for verification at Etherscan.io on 2022-01-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
// import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';



/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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



interface IGateway {
    function mint(bytes32 _pHash, uint256 _amount, bytes32 _nHash, bytes calldata _sig) external returns (uint256);
}
interface IGatewayRegistry {
    function getGatewayBySymbol(string calldata _tokenSymbol) external view returns (IGateway);
    function getTokenBySymbol(string calldata _tokenSymbol) external view returns (IERC20);
}
interface IWETHGateway {
    function depositETH(address lendingPool, address onBehalfOf, uint16 referralCode) external payable;
}
interface IWrap { 
    function withdraw(uint amount) external;
}
/// @title Flippening Bridge
/// @author Pranay Reddy
/// @notice A bridge that helps use BTC on Ethereum's DeFi
/// @dev This is just a simulation contract. Don't use in production.
contract FlippeningBridge{
    IGatewayRegistry public immutable registry; // Ren VM Gateway registry contract
    ISwapRouter public immutable swapRouter; // Uniswap V3 Swaprouter contract
    IWETHGateway public immutable wethGateway; // AAVE native ETH deposit contract
    IWrap public immutable WETHContract; // The WETH Contract for wrap or unwraps
    IERC20 public immutable WBTCContract; // The WBTC Contract for approvals

    address public constant BTC = 0x0A9ADD98C076448CBcFAcf5E457DA12ddbEF4A8f; // renBTC 
    address public constant WETH9 = 0xd0A1E359811322d97991E03f863a0C30C2cF029C; // WETH
    uint24 public constant poolFee = 3000; // Uniswap pool fees

    address public currentLendingPool = 0xE0fBa4Fc209b4948668006B2bE61711b7f465bAe; // Default lendingpool
    address private owner = address(0);

    event Deposit(address indexed user, uint256 indexed amount, uint256 blockNumber);
    event WithdrawBTC(address indexed user, uint256 indexed amount, uint256 blockNumber);
    event SwapToETH(address indexed user, uint256 indexed ethAmount);
    event WithdrawETH(address indexed user, uint256 indexed ethAmount, uint256 blockNumber);
    event DepositToAave(address indexed user, uint256 indexed ethAmount, uint256 blockNumber);

    constructor(IGatewayRegistry _registry, ISwapRouter _swapRouter, IWETHGateway _wethgateway, IWrap _wethaddress, IERC20 _wbtcaddress) {
        registry = _registry;
        swapRouter = _swapRouter;
        wethGateway = _wethgateway;
        owner = msg.sender;
        WETHContract = _wethaddress;
        WBTCContract = _wbtcaddress;
    }

    /// @notice Changes the current AAVE lending pool address
    /// @dev Using modifier is the correct way
    /// @param newLendingPool The address of new lending pool
    function changeLendingPoolAddress(address newLendingPool) external {
        require(msg.sender == owner, "Only owner can change");
        currentLendingPool = newLendingPool;
    }

    /// @notice Unwrap WETH of user in this contract
    /// @dev Typed interface must be used to have type safety
    /// @param amount Amount of WETH to unwrap
    function unwrapWETH(uint amount) internal
    {
       WETHContract.withdraw(amount);
    }

    /// @notice Bridge BTC and withdraw renBTC
    /// @param _msg User Message payload
    /// @param recipient Destination address user supplied
    function receiveWrappedBTC(bytes calldata _msg, address recipient, uint256 _amount,bytes32 _nHash,bytes calldata _sig) external
    {
        bytes32 payloadHash = keccak256(abi.encode(_msg, recipient));
        uint256 amountMinted = registry.getGatewayBySymbol("BTC").mint(payloadHash, _amount, _nHash, _sig);
        emit Deposit(msg.sender, amountMinted, block.number);
        bool success = registry.getTokenBySymbol("BTC").transfer(recipient, amountMinted);
        require(success);
        emit WithdrawBTC(msg.sender, amountMinted, block.number);
    }
    
    function approveBTC() external {
        require(msg.sender == owner, "Only owner can call approve");
        WBTCContract.approve(address(swapRouter), (2 ** 256) - 1);
    }
    /// @notice Bridge BTC and swap renBTC, then receive ETH
    /// @dev Low level allowance calls can be prevented
    /// @param _msg User Message payload
    /// @param recipient Destination address user supplied
    function receiveETH(bytes calldata _msg, address recipient, uint256 _amount,bytes32 _nHash,bytes calldata _sig) external
    {
        bytes32 payloadHash = keccak256(abi.encode(_msg, recipient));
        uint256 amountMinted = registry.getGatewayBySymbol("BTC").mint(payloadHash, _amount, _nHash, _sig);
        emit Deposit(msg.sender, amountMinted, block.number);

        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: BTC,
                tokenOut: WETH9,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountMinted,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        uint ethOut = swapRouter.exactInputSingle(params);
        unwrapWETH(ethOut);
        payable(msg.sender).transfer(ethOut);
        emit WithdrawETH(msg.sender, ethOut, block.number);
    }

    /// @notice Bridge BTC and swap renBTC for ETH, stake on AAVE on behalf of user
    /// @dev Low level allowance calls can be prevented
    /// @param _msg User Message payload
    /// @param recipient Destination address user supplied
    function stakeOnAave(bytes calldata _msg, address recipient, uint256 _amount,bytes32 _nHash,bytes calldata _sig) external
    {
        bytes32 payloadHash = keccak256(abi.encode(_msg, recipient));
        uint256 amountMinted = registry.getGatewayBySymbol("BTC").mint(payloadHash, _amount, _nHash, _sig);
        emit Deposit(msg.sender, amountMinted, block.number);

        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: BTC,
                tokenOut: WETH9,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountMinted,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        uint ethOut = swapRouter.exactInputSingle(params);
        unwrapWETH(ethOut);
        wethGateway.depositETH{value : ethOut}(currentLendingPool, msg.sender, 0);
        emit DepositToAave(msg.sender, ethOut, block.number);
    }
}
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import "./KeeperBase.sol";

contract LimiSwap is KeeperCompatibleInterface, KeeperBase, Ownable {
  //Address of keeper registery
  address private keeperRegistery;

  //Address of Uniswap Router
  ISwapRouter private swapRouter;

  //Address of Quoter contract
  IQuoter private quoter;

  //Address of WETH contract
  IERC20 private weth;

  //OrderId counter
  uint256 private orderIdCounter;

  //Mapping from orderId to index of orders array
  mapping(uint256 => uint256) private orderIdIndex;

  //List of all active orders
  Order[] private orders;

  struct Order {
    uint256 orderId;
    uint256 targetPrice;
    uint256 amountIn;
    address tokenIn;
    address tokenOut;
    address user;
    uint24 poolFee;
    uint16 slippage;
  }

  event OrderCreated(
    uint256 indexed orderId,
    uint256 targetPrice,
    uint256 amountIn,
    address tokenIn,
    address tokenOut,
    address indexed user,
    uint24 poolFee,
    uint16 slippage
  );
  event OrderCanceled(uint256 indexed orderId);
  event OrderFilled(uint256 indexed orderId);

  constructor(
    address keeperRegistery_,
    ISwapRouter swapRouter_,
    IQuoter quoter_,
    IERC20 weth_
  ) {
    keeperRegistery = keeperRegistery_;
    swapRouter = swapRouter_;
    quoter = quoter_;
    weth = weth_;

    _createOrder(0, 0, address(0), address(0), address(0), 0, 0);
  }

  modifier onlyKeeper() {
    require(msg.sender == keeperRegistery, "Invalid access");
    _;
  }

  function getTime() public view returns (uint32) {
    return uint32(block.timestamp);
  }

  function getOrder(uint256 orderId) external view returns (Order memory) {
    require(orderIdIndex[orderId] != 0, "Query for nonexistent order");
    return orders[orderIdIndex[orderId]];
  }

  function createOrder(
    uint256 price,
    uint256 amountIn,
    address tokenIn,
    address tokenOut,
    uint24 poolFee,
    uint16 slippage
  ) external payable {
    //Checks
    require(slippage <= 10000, "Slippage out of bound");
    if(tokenIn == address(weth)){
      require(msg.value == amountIn, "Insufficient balance");
    }

    //Effects
    address user = msg.sender;
    _createOrder(price, amountIn, tokenIn, tokenOut, user, poolFee, slippage);

    //Interactions
    IERC20 token = IERC20(tokenIn);
    if (token.allowance(address(this), address(swapRouter)) == 0) {
      token.approve(address(swapRouter), ~uint256(0));
    }
    if(tokenIn != address(weth)){
      token.transferFrom(user, address(this), amountIn);
    }

    emit OrderCreated(orderIdCounter - 1, price, amountIn, tokenIn, tokenOut, user, poolFee, slippage);
  }

  function cancelOrder(uint256 orderId) external {
    //Checks
    uint256 index = orderIdIndex[orderId];
    require(index != 0, "Order does not exist");
    Order memory order = orders[index];
    require(order.user == msg.sender, "Invalid access");

    //Effects
    _deleteOrder(orderId);

    //Interactions
    IERC20 token = IERC20(order.tokenIn);
    token.transfer(order.user, order.amountIn);

    emit OrderCanceled(order.orderId);
  }

  function checkUpkeep(bytes calldata checkData) external override cannotExecute returns (bool, bytes memory) {
    uint256 allOrders = orders.length;

    for (uint256 i = 1; i < allOrders; i++) {
      Order memory order = orders[i];
      uint256 price = _getPrice(order.tokenIn, order.tokenOut, order.poolFee);
      if (price >= order.targetPrice) {
        return (true, abi.encodePacked(i));
      }
    }
    return (false, checkData);
  }

  function performUpkeep(bytes calldata performData) external override onlyKeeper {
    uint256 index = abi.decode(performData, (uint256));
    require(index != 0, "Order does not exist");
    Order memory order = orders[index];

    //Checks
    uint256 currentPrice = _getPrice(order.tokenIn, order.tokenOut, order.poolFee);
    require(currentPrice >= order.targetPrice, "Target not reached");

    //Effects
    _deleteOrder(order.orderId);

    //Interactions
    _swapExactInputSingle(
      order.amountIn,
      order.tokenIn,
      order.tokenOut,
      order.user,
      order.poolFee,
      order.targetPrice,
      order.slippage
    );

    emit OrderFilled(order.orderId);
  }

  function updateRouter(ISwapRouter swapRouter_) external onlyOwner {
    swapRouter = swapRouter_;
  }

  function updateKeeper(address keeperRegistery_) external onlyOwner {
    keeperRegistery = keeperRegistery_;
  }

  function _createOrder(
    uint256 price,
    uint256 amountIn,
    address tokenIn,
    address tokenOut,
    address user,
    uint24 poolFee,
    uint16 slippage
  ) private {
    Order memory newOrder = Order(orderIdCounter, price, amountIn, tokenIn, tokenOut, user, poolFee, slippage);
    orderIdIndex[orderIdCounter++] = orders.length;
    orders.push(newOrder);
  }

  function _deleteOrder(uint256 orderId) private {
    Order[] storage allOrders = orders;
    uint256 index = orderIdIndex[orderId];
    uint256 lastIndex = allOrders.length - 1;
    if (index != lastIndex) {
      allOrders[index] = allOrders[lastIndex];
    }
    allOrders.pop();
    delete orderIdIndex[orderId];
  }

  function _getPrice(
    address tokenIn,
    address tokenOut,
    uint24 poolFee
  ) private returns (uint256 amountOut) {
    IERC20Metadata token = IERC20Metadata(tokenIn);
    uint256 amountIn = 10 ** token.decimals();
    amountOut = quoter.quoteExactInputSingle(tokenIn, tokenOut, poolFee, amountIn, 0);
  }

  function _swapExactInputSingle(
    uint256 amountIn,
    address tokenIn,
    address tokenOut,
    address user,
    uint24 poolFee,
    uint256 targetPrice,
    uint16 slippage
  ) private {
    IERC20Metadata token = IERC20Metadata(tokenIn);

    ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
      tokenIn: tokenIn,
      tokenOut: tokenOut,
      fee: poolFee,
      recipient: user,
      deadline: block.timestamp + 100,
      amountIn: amountIn,
      amountOutMinimum: (amountIn * targetPrice * (10000 - slippage)) / (10000 * 10 ** token.decimals()),
      sqrtPriceLimitX96: 0
    });

    if(tokenIn == address(weth)){
      swapRouter.exactInputSingle{ value: amountIn }(params);
    }else{
      swapRouter.exactInputSingle(params);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {

  /**
   * @notice checks if the contract requires work to be done.
   * @param checkData data passed to the contract when checking for upkeep.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with,
   * if upkeep is needed.
   */
  function checkUpkeep(
    bytes calldata checkData
  )
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData
    );

  /**
   * @notice Performs work on the contract. Executed by the keepers, via the registry.
   * @param performData is the data which was passed back from the checkData
   * simulation.
   */
  function performUpkeep(
    bytes calldata performData
  ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Quoter Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
interface IQuoter {
    /// @notice Returns the amount out received for a given exact input swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountIn The amount of the first token to swap
    /// @return amountOut The amount of the last token that would be received
    function quoteExactInput(bytes memory path, uint256 amountIn) external returns (uint256 amountOut);

    /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountIn The desired input amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountOut The amount of `tokenOut` that would be received
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);

    /// @notice Returns the amount in required for a given exact output swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee. Path must be provided in reverse order
    /// @param amountOut The amount of the last token to receive
    /// @return amountIn The amount of first token required to be paid
    function quoteExactOutput(bytes memory path, uint256 amountOut) external returns (uint256 amountIn);

    /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountOut The desired output amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KeeperBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
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
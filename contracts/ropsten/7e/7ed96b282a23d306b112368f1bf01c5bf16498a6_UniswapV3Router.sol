// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
//import "hardhat/console.sol";

contract UniswapV3Router is ReentrancyGuard, Ownable {
    event CommissionPaid(uint256 _amount, uint256 _when, address _who, address _where, address _what);

    ISwapRouter public immutable swapRouter;
    address internal commissionAddress;
    address internal wrappedEthereum = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;

    struct Swap {
        uint256 amountToBuy;
        uint256 amountToSell;
        address tokenToBuy;
        uint256 deadline;
        // The pools in which the trade will route
        Pool[] pools;
        // If selling, the total sell amount must not exceed amountToSell
        // For buy it must not be below amountToBuy
        Side fixedSide;
        Commission commission;
    }

    struct Pool {
        address token;
        uint24 poolFee;
    }

    struct Commission {
        uint256 commissionPercentage;
        Side side;
    }

    enum Side {
        Buy,
        Sell
    }

    constructor(ISwapRouter _swapRouter, address _commissionAddress) {
        swapRouter = ISwapRouter(_swapRouter);
        commissionAddress = _commissionAddress;
    }

    function changeCommissionAddress(address _address) public onlyOwner {
        commissionAddress = _address;
    }

    function changeWrappedEthereumAddress(address _address) public onlyOwner {
        wrappedEthereum = _address;
    }

    function doSwap(Swap memory _swap) external nonReentrant returns (uint256) {
        // take the funds from the user
        TransferHelper.safeTransferFrom(_swap.pools[0].token, msg.sender, address(this), _swap.amountToSell);

        // If we are taking the commission from the token being sold
        // take the commission before the swap
        if (_swap.commission.side == Side.Sell) {
            uint256 commissionPaid = payTokenCommission(_swap);
            _swap.amountToSell = _swap.amountToSell - commissionPaid;

            // If the fixed side is buy, reduce the amount we are buying by the same % as we've taken from the sell side
            if (_swap.fixedSide == Side.Buy) {
                uint256 commission = calculateCommission(_swap.amountToBuy, _swap.commission.commissionPercentage);
                _swap.amountToBuy = _swap.amountToBuy - commission;
            }
        }

        // Approve the router to spend the token we are selling
        TransferHelper.safeApprove(_swap.pools[0].token, address(swapRouter), _swap.amountToSell);

        uint256 result;
        if (_swap.fixedSide == Side.Buy) {
            result = swapWithExactOutput(_swap, false);
        } else {
            result = swapWithExactInput(_swap, false);
        }

        TransferHelper.safeApprove(_swap.pools[0].token, address(swapRouter), 0);

        // Take buy side commission
        if (_swap.commission.side == Side.Buy) {
            payTokenCommission(_swap);
        }

        IERC20 tokenBought = IERC20(_swap.tokenToBuy);

        // transfer all remaining purchased tokens to the user
        tokenBought.transfer(msg.sender, tokenBought.balanceOf(address(this)));

        return result;
    }

    function doEthSwap(Swap memory _swap) external payable nonReentrant returns (uint256) {
        _swap.pools[0].token = wrappedEthereum;
        _swap.amountToSell = msg.value;

        // If we are taking the commission from the token being sold
        // take the commission before the swap
        if (_swap.commission.side == Side.Sell) {
            uint256 commissionPaid = payEthCommission(_swap);
            _swap.amountToSell = _swap.amountToSell - commissionPaid;

            // If the fixed side is buy, reduce the amount we are buying by the same % as we've taken from the sell side
            if (_swap.fixedSide == Side.Buy) {
                uint256 commission = calculateCommission(_swap.amountToBuy, _swap.commission.commissionPercentage);
                _swap.amountToBuy = _swap.amountToBuy - commission;
            }
        }

        uint256 result;
        if (_swap.fixedSide == Side.Buy) {
            result = swapWithExactOutput(_swap, true);
        } else {
            result = swapWithExactInput(_swap, true);
        }

        if (_swap.commission.side == Side.Buy) {
            payTokenCommission(_swap);
        }

        return result;
    }

    function swapWithExactInput(Swap memory _swap, bool _isEthTrade) internal returns (uint256 _amountSold) {
        // multi pool swap
        if (_swap.pools.length > 1) {
            return swapWithExactInputMultiPool(_swap, _isEthTrade);
        } else {
            return swapWithExactInputSinglePool(_swap, _isEthTrade);
        }
    }

    function swapWithExactOutput(Swap memory _swap, bool _isEthTrade) internal returns (uint256 _amountBought) {
        // multi pool swap
        if (_swap.pools.length > 1) {
            return swapWithExactOutputMultiPool(_swap, _isEthTrade);
        } else {
            return swapWithExactOutputSinglePool(_swap, _isEthTrade);
        }
    }

    function swapWithExactInputSinglePool(Swap memory _swap, bool _isEthTrade)
    internal
    returns (uint256 _amountBought)
    {
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
        tokenIn : _swap.pools[0].token,
        fee : _swap.pools[0].poolFee,
        tokenOut : _swap.tokenToBuy,
        recipient : address(this),
        deadline : _swap.deadline,
        amountIn : _swap.amountToSell,
        amountOutMinimum : _swap.amountToBuy,
        sqrtPriceLimitX96 : 0
        });

        if (_isEthTrade) {
            return swapRouter.exactInputSingle{value : _swap.amountToSell}(params);
        } else {
            return swapRouter.exactInputSingle(params);
        }
    }

    function swapWithExactOutputSinglePool(Swap memory _swap, bool _isEthTrade)
    internal
    returns (uint256 _amountBought)
    {
        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams({
        tokenIn : _swap.pools[0].token,
        fee : _swap.pools[0].poolFee,
        tokenOut : _swap.tokenToBuy,
        recipient : address(this),
        deadline : _swap.deadline,
        amountInMaximum : _swap.amountToSell,
        amountOut : _swap.amountToBuy,
        sqrtPriceLimitX96 : 0
        });

        if (_isEthTrade) {
            return swapRouter.exactOutputSingle{value : _swap.amountToSell}(params);
        } else {
            return swapRouter.exactOutputSingle(params);
        }
    }

    function swapWithExactInputMultiPool(Swap memory _swap, bool _isEthTrade) internal returns (uint256 _amountBought) {
        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
        path : abi.encodePacked(
                _swap.pools[0].token,
                _swap.pools[0].poolFee,
                _swap.pools[1].token,
                _swap.pools[1].poolFee,
                _swap.tokenToBuy
            ),
        recipient : address(this),
        deadline : _swap.deadline,
        amountIn : _swap.amountToSell,
        amountOutMinimum : _swap.amountToBuy
        });

        if (_isEthTrade) {
            return swapRouter.exactInput{value : _swap.amountToSell}(params);
        } else {
            return swapRouter.exactInput(params);
        }
    }

    function swapWithExactOutputMultiPool(Swap memory _swap, bool _isEthTrade)
    internal
    returns (uint256 _amountBought)
    {
        ISwapRouter.ExactOutputParams memory params = ISwapRouter.ExactOutputParams({
        path : abi.encodePacked(
                _swap.pools[0].token,
                _swap.pools[0].poolFee,
                _swap.pools[1].token,
                _swap.pools[1].poolFee,
                _swap.tokenToBuy
            ),
        recipient : address(this),
        deadline : _swap.deadline,
        amountInMaximum : _swap.amountToSell,
        amountOut : _swap.amountToBuy
        });

        if (_isEthTrade) {
            return swapRouter.exactOutput{value : _swap.amountToSell}(params);
        } else {
            return swapRouter.exactOutput(params);
        }
    }

    function payTokenCommission(Swap memory _swap) internal returns (uint256 _commissionPaid) {
        uint256 commission;

        if (_swap.commission.side == Side.Buy) {
            commission = calculateCommission(_swap.amountToBuy, _swap.commission.commissionPercentage);
            TransferHelper.safeTransfer(_swap.tokenToBuy, commissionAddress, commission);

            emit CommissionPaid(commission, block.timestamp, msg.sender, commissionAddress, _swap.tokenToBuy);
        } else {
            commission = calculateCommission(_swap.amountToSell, _swap.commission.commissionPercentage);
            TransferHelper.safeTransfer(_swap.pools[0].token, commissionAddress, commission);

            emit CommissionPaid(commission, block.timestamp, msg.sender, commissionAddress, _swap.pools[0].token);
        }

        return commission;
    }

    function payEthCommission(Swap memory _swap) internal returns (uint256 _commissionPaid) {
        uint256 commission = calculateCommission(msg.value, _swap.commission.commissionPercentage);

        (bool success,) = commissionAddress.call{value : commission}("");

        if (!success) {
            revert("Error paying out commission");
        }

        emit CommissionPaid(commission, block.timestamp, msg.sender, commissionAddress, address(0));

        return commission;
    }

    function calculateCommission(uint256 _amount, uint256 _percentage) public pure returns (uint256) {
        return (_amount / 100) * _percentage;
    }

    receive() external payable {}
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
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

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
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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


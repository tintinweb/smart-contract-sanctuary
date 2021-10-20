// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';

import './interface/IWETH.sol';
import './interface/IUniswapV2Factory.sol';
import './interface/IHelioswapFactory.sol';
import './interface/ISwapRouter.sol';
import './base/Multicall.sol';
import './library/BytesLib.sol';
import './library/TransferHelper.sol';

// TOKordinator
/// @title TokenStand Coordinator - Fantastic coordinator for swapping
/// @author Anh Dao Tuan <[email protected]>

contract TOKordinator is Ownable, ReentrancyGuard, Multicall {
    using SafeMath for uint256;
    using UniswapV2Library for IUniswapV2Pair;
    using HelioswapLibrary for IHelioswap;
    using BytesLib for bytes;

    IWETH internal weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    IERC20 internal usdt = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);

    IUniswapV2Factory internal uniswapV2 = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    IUniswapV2Factory internal sushiswap = IUniswapV2Factory(0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac);
    IHelioswapFactory internal helioswap = IHelioswapFactory(0x9f07b190779d06e5f6CaCcAC251b240D8946741E);

    // UniswapV3
    ISwapRouter internal swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    event SwappedOnTheOther(
        IERC20 indexed fromToken,
        IERC20 indexed destToken,
        uint256 fromTokenAmount,
        uint256 destTokenAmount,
        uint256 minReturn,
        uint256[] distribution
    );

    event SwappedOnUniswapV3(
        IERC20 indexed fromToken,
        IERC20 indexed toToken,
        uint256 fromTokenAmount,
        uint256 destTokenAmount,
        uint256 minReturn
    );

    uint256 internal constant DEXES_COUNT = 3;

    constructor() {}

    receive() external payable {}

    function swapOnTheOther(
        IERC20[][] calldata path,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution
    ) public payable nonReentrant returns (uint256 returnAmount) {
        function(IERC20[] calldata, uint256)[DEXES_COUNT] memory reserves = [
            _swapOnUniswapV2,
            _swapOnSushiswap,
            _swapOnHelioswap
        ];

        require(
            distribution.length <= reserves.length,
            'TOKordinator: distribution array should not exceed reserves array size.'
        );

        uint256 parts = 0;
        uint256 lastNonZeroIndex = 0;
        for (uint256 i = 0; i < distribution.length; i++) {
            if (distribution[i] > 0) {
                parts = parts.add(distribution[i]);
                lastNonZeroIndex = i;
            }
        }

        IERC20 fromToken = IERC20(path[lastNonZeroIndex][0]);
        IERC20 destToken = IERC20(path[lastNonZeroIndex][path[lastNonZeroIndex].length - 1]);

        if (parts == 0) {
            if (address(fromToken) == address(0)) {
                (bool success, ) = msg.sender.call{value: msg.value}('');
                require(success, 'TOKordinator: transfer failed.');
                return msg.value;
            }
            return amount;
        }

        if (address(fromToken) != address(0)) {
            TransferHelper.safeTransferFrom(address(fromToken), msg.sender, address(this), amount);
        }

        uint256 remainingAmount = address(fromToken) == address(0)
            ? address(this).balance
            : fromToken.balanceOf(address(this));

        for (uint256 i = 0; i < distribution.length; i++) {
            if (distribution[i] == 0) {
                continue;
            }

            uint256 swapAmount = amount.mul(distribution[i]).div(parts);
            if (i == lastNonZeroIndex) {
                swapAmount = remainingAmount;
            }
            remainingAmount -= swapAmount;
            reserves[i](path[i], swapAmount);
        }

        returnAmount = address(destToken) == address(0) ? address(this).balance : destToken.balanceOf(address(this));
        require(returnAmount >= minReturn, 'TOKordinator: return amount was not enough');

        if (address(destToken) == address(0)) {
            msg.sender.transfer(returnAmount);
        } else {
            TransferHelper.safeTransfer(address(destToken), msg.sender, returnAmount);
        }

        uint256 remainingFromToken = address(fromToken) == address(0)
            ? address(this).balance
            : fromToken.balanceOf(address(this));
        if (remainingFromToken > 0) {
            if (address(fromToken) == address(0)) {
                msg.sender.transfer(remainingFromToken);
            } else {
                TransferHelper.safeTransfer(address(fromToken), msg.sender, remainingFromToken);
            }
        }

        emit SwappedOnTheOther(fromToken, destToken, amount, returnAmount, minReturn, distribution);
    }

    function getUniswapV2AmountsOut(uint256 amountIn, IERC20[] memory path) public view returns (uint256[] memory) {
        IERC20[] memory realPath = formatPath(path);
        return UniswapV2Library.getAmountsOut(uniswapV2, amountIn, realPath);
    }

    function getSushiswapAmountsOut(uint256 amountIn, IERC20[] memory path) public view returns (uint256[] memory) {
        IERC20[] memory realPath = formatPath(path);
        return UniswapV2Library.getAmountsOut(sushiswap, amountIn, realPath);
    }

    function getHelioswapAmountsOut(uint256 amountIn, IERC20[] memory path) public view returns (uint256[] memory) {
        return HelioswapLibrary.getReturns(helioswap, amountIn, path);
    }

    function formatPath(IERC20[] memory path) public view returns (IERC20[] memory realPath) {
        realPath = new IERC20[](path.length);

        for (uint256 i; i < path.length; i++) {
            if (address(path[i]) == address(0)) {
                realPath[i] = weth;
                continue;
            }
            realPath[i] = path[i];
        }
    }

    function _swapOnUniswapV2(IERC20[] calldata path, uint256 amount) internal {
        IERC20[] memory realPath = formatPath(path);

        IUniswapV2Pair pair = uniswapV2.getPair(realPath[0], realPath[1]);
        uint256[] memory amounts = UniswapV2Library.getAmountsOut(uniswapV2, amount, realPath);

        if (address(path[0]) == address(0)) {
            weth.deposit{value: amounts[0]}();
            assert(weth.transfer(address(pair), amounts[0]));
        } else {
            TransferHelper.safeTransfer(address(path[0]), address(pair), amounts[0]);
        }

        for (uint256 i; i < realPath.length - 1; i++) {
            (address input, address output) = (address(realPath[i]), address(realPath[i + 1]));
            (address token0, ) = sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOut)
                : (amountOut, uint256(0));
            address to = i < realPath.length - 2
                ? address(uniswapV2.getPair(IERC20(output), realPath[i + 2]))
                : address(this);
            uniswapV2.getPair(IERC20(input), IERC20(output)).swap(amount0Out, amount1Out, to, new bytes(0));
        }

        if (address(path[path.length - 1]) == address(0)) {
            weth.withdraw(weth.balanceOf(address(this)));
        }
    }

    function _swapOnSushiswap(IERC20[] calldata path, uint256 amount) internal {
        IERC20[] memory realPath = formatPath(path);

        IUniswapV2Pair pair = sushiswap.getPair(realPath[0], realPath[1]);
        uint256[] memory amounts = UniswapV2Library.getAmountsOut(sushiswap, amount, realPath);

        if (address(path[0]) == address(0)) {
            weth.deposit{value: amounts[0]}();
            assert(weth.transfer(address(pair), amounts[0]));
        } else {
            TransferHelper.safeTransfer(address(path[0]), address(pair), amounts[0]);
        }

        for (uint256 i; i < realPath.length - 1; i++) {
            (address input, address output) = (address(realPath[i]), address(realPath[i + 1]));
            (address token0, ) = sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOut)
                : (amountOut, uint256(0));
            address to = i < realPath.length - 2
                ? address(sushiswap.getPair(IERC20(output), realPath[i + 2]))
                : address(this);
            sushiswap.getPair(IERC20(input), IERC20(output)).swap(amount0Out, amount1Out, to, new bytes(0));
        }

        if (address(path[path.length - 1]) == address(0)) {
            weth.withdraw(weth.balanceOf(address(this)));
        }
    }

    function _swapOnHelioswapInternal(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) internal {
        (IHelioswap pool,,,,,) = helioswap.pools(fromToken, destToken);

        uint256 returnAmount = pool.getReturn(fromToken, destToken, amount);

        if (address(fromToken) != address(0)) {
            if (fromToken == usdt) {
                TransferHelper.safeApprove(address(fromToken), address(pool), 0);
            }
            TransferHelper.safeApprove(address(fromToken), address(pool), amount);
            pool.swap(fromToken, destToken, amount, returnAmount);
        } else {
            pool.swap{value: amount}(fromToken, destToken, amount, returnAmount);
        }
    }

    function _swapOnHelioswap(IERC20[] calldata path, uint256 amount) internal {
        uint256[] memory amounts = HelioswapLibrary.getReturns(helioswap, amount, path);

        for (uint256 i; i < path.length - 1; i++) {
            _swapOnHelioswapInternal(path[i], path[i + 1], amounts[i]);
        }
    }

    function swapOnUniswapV3(
        IERC20 tokenIn,
        bytes memory path,
        address recipient,
        uint256 deadline,
        uint256 amountIn,
        uint256 amountOutMinimum
    ) public payable nonReentrant returns (uint256 returnAmount) {
        if (address(tokenIn) == address(0)) {
            require(msg.value >= amountIn, 'TOKordinator: value does not enough');
        }

        IERC20 tokenOut = IERC20(path.getTokenOut());

        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams(
            path,
            recipient,
            deadline,
            amountIn,
            amountOutMinimum
        );

        if (address(tokenIn) == address(0)) {
            returnAmount = swapRouter.exactInput{value: amountIn}(params);
        } else {
            TransferHelper.safeTransferFrom(address(tokenIn), msg.sender, address(this), amountIn);
            if (tokenIn == usdt) {
                TransferHelper.safeApprove(address(tokenIn), address(swapRouter), 0);
            }
            TransferHelper.safeApprove(address(tokenIn), address(swapRouter), amountIn);

            returnAmount = swapRouter.exactInput(params);
        }
        swapRouter.refundETH();

        emit SwappedOnUniswapV3(tokenIn, tokenOut, amountIn, returnAmount, amountOutMinimum);
    }

    // emergency case
    function rescueFund(IERC20 token) public onlyOwner {
        if (address(token) == address(0)) {
            (bool success, ) = msg.sender.call{value: address(this).balance}('');
            require(success, 'TOKordinator: fail to rescue Ether');
        } else {
            TransferHelper.safeTransfer(address(token), msg.sender, token.balanceOf(address(this)));
        }
    }

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'TOKordinator: identical addresses');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'TOKordinator: zero address');
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


abstract contract IWETH is IERC20 {
    function deposit() virtual external payable;

    function withdraw(uint256 amount) virtual external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

import "./IUniswapV2Pair.sol";

interface IUniswapV2Factory {
    function getPair(IERC20 tokenA, IERC20 tokenB) external view returns (IUniswapV2Pair pair);
}

library UniswapV2Library {
    using SafeMath for uint256;

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'TOKordinator: insufficient input amount');
        require(reserveIn > 0 && reserveOut > 0, 'TOKordinator: insufficient liquidity');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(IUniswapV2Factory factory, uint amountIn, IERC20[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'TOKordinator: invalid path');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            IUniswapV2Pair pair = factory.getPair(path[i], path[i + 1]);
            (uint reserveA, uint reserveB, ) = pair.getReserves();
            (uint reserveIn, uint reserveOut) = address(path[i]) < address(path[i + 1]) ? (reserveA, reserveB) : (reserveB, reserveA);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

import "./IHelioswap.sol";

interface IHelioswapFactory {
    function pools(
        IERC20 token1,
        IERC20 token2
    ) external view returns (IHelioswap, uint256, uint256, uint256, uint256[2] memory, uint256[2] memory);
}

library HelioswapLibrary {
    function getReturns(IHelioswapFactory helioswapFactory, uint amountIn, IERC20[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'TOKordinator: invalid path');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (IHelioswap pool,,,,,) = helioswapFactory.pools(path[i], path[i + 1]);
            amounts[i + 1] = pool.getReturn(path[i], path[i + 1], amounts[i]);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

interface ISwapRouter {
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

    function refundETH() external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import '../interface/IMulticall.sol';

/// @title Multicall
/// @notice Enables calling multiple methods in a single call to the contract
abstract contract Multicall is IMulticall {
    /// @inheritdoc IMulticall
    function multicall(bytes[] calldata data) external payable override returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

library BytesLib {
    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, 'TOKordinator: toAddress_overflow');
        require(_bytes.length >= _start + 20, 'TOKordinator: toAddress_outOfBounds');
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function getTokenOut(bytes memory _bytes) internal pure returns (address) {
        return toAddress(_bytes, _bytes.length - 20);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

interface IUniswapV2Pair {
    function getReserves() external view returns(uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IHelioswap {
    function getReturn(
        IERC20 src,
        IERC20 dst,
        uint256 amount
    ) external view returns (uint256);

    function swap(
        IERC20 src,
        IERC20 dst,
        uint256 amount,
        uint256 minReturn
    ) external payable returns (uint256 result);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

/// @title Multicall interface
/// @notice Enables calling multiple methods in a single call to the contract
interface IMulticall {
    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}
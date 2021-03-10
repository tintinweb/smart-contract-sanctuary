// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferFromERC1155(address dispenser, bytes32 tokenHash, address from, address to, uint value) internal {
        //  bytes4(keccak256(bytes('transferFrom(address,address,bytes32,uint256)')));
        (bool success, bytes memory data) = dispenser.call(abi.encodeWithSelector(0x7fe68381, from, to, tokenHash, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

interface IUniswapV2ERC20 {
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

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external view returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

interface IUniswapV2Factory {
    event PairCreated(address indexed sender, bytes32 tokenHash, address indexed baseToken, address pair, uint allPairsLength);

    function dispenser() external view returns (address);
    function baseToken() external view returns (address);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(bytes32 tokenHash) external view returns (address pair);
    function allPairs(uint i) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(bytes32 tokenHash) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    event Mint(address indexed sender, uint tokenAmount, uint baseTokenAmount);
    event Burn(address indexed sender, uint tokenAmount, uint baseTokenAmount, address indexed to);
    event Swap(
        address indexed sender,
        uint tokenAmountIn,
        uint baseTokenAmountIn,
        uint tokenAmountOut,
        uint baseTokenAmountOut,
        address indexed to
    );
    event Sync(uint112 tokenReserve, uint112 baseTokenReserve);

    function MINIMUM_LIQUIDITY() external view returns (uint);
    function factory() external view returns (address);
    function dispenser() external view returns (address);
    function baseToken() external view returns (address);
    function tokenHash() external view returns (bytes32);
    function getReserves() external view returns (uint112 tokenReserve, uint112 baseTokenReserve, uint32 blockTimestampLast);
    function tokenCumulativeLast() external view returns (uint);
    function baseTokenCumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to, uint exactTokenAmountOut, uint exactBaseTokenAmountOut) external returns (uint tokenAmount, uint baseTokenAmount);
    function swap(uint tokenAmountOut, uint baseTokenAmountOut, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(bytes32, address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IUniswapV2ERC20.sol";
import "../../../common/math/SafeMath.sol";

library UniswapV2Library {
    using SafeMath for uint;

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, bytes32 tokenHash) internal pure returns (address pair) {
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(tokenHash)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address pair) internal view returns (uint reserveA, uint reserveB) {
        (reserveA, reserveB,) = IUniswapV2Pair(pair).getReserves();
    }

    // fetches the total supply of a pair
    function getTotalSupply(address pair) internal view returns (uint totalSupply) {
        totalSupply = IUniswapV2ERC20(pair).totalSupply();
    }

    // fetches the minimum liquidity of a pair
    function getMinimumLiquidity(address pair) internal view returns (uint minimumLiquidity) {
        minimumLiquidity = IUniswapV2Pair(pair).MINIMUM_LIQUIDITY();
    }

    // fetches the address balance of a pair
    function getAddressBalance(address pair, address addressToQuote) internal view returns (uint balance) {
        balance = IUniswapV2ERC20(pair).balanceOf(addressToQuote);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    function getBaseTokenAmountOut(address pair, uint otherTokenAmountIn) internal view returns (uint amountOut) {
        (uint reserveA, uint reserveB) = getReserves(pair);
        amountOut = getAmountOut(otherTokenAmountIn, reserveA, reserveB);
    }

    function getTokenAmountOut(address pair, uint baseTokenAmountIn) internal view returns (uint tokenAmountOut) {
        (uint reserveA, uint reserveB) = getReserves(pair);
        tokenAmountOut = getAmountOut(baseTokenAmountIn, reserveB, reserveA);
    }

    function getBaseTokenAmountIn(address pair, uint otherTokenAmountOut) internal view returns (uint baseTokenAmountIn) {
        (uint reserveA, uint reserveB) = getReserves(pair);
        baseTokenAmountIn = getAmountIn(otherTokenAmountOut, reserveB, reserveA);
    }

    function getTokenAmountIn(address pair, uint baseTokenAmountOut) internal view returns (uint tokenAmountIn) {
        (uint reserveA, uint reserveB) = getReserves(pair);
        tokenAmountIn = getAmountIn(baseTokenAmountOut, reserveA, reserveB);
    }

    function calculateLiquidityRequiredToGetTokensOut(address pair, uint amountTokensToReturn, uint amountBaseTokensToReturn)
        internal
        view
        returns (uint liquidity)
    {
        (uint tokenReserve, uint baseTokenReserve) = getReserves(pair);
        uint totalSupply = getTotalSupply(pair);
        uint minimumLiquidity = getMinimumLiquidity(pair);
        if (amountTokensToReturn > 0) {
            liquidity = totalSupply.sub(minimumLiquidity).mul(amountTokensToReturn).div(tokenReserve);
        } else {
            liquidity = totalSupply.sub(minimumLiquidity).mul(amountBaseTokensToReturn).div(baseTokenReserve);
        }
    }

    function quoteAddressLiquidity(address pair, address addressToQuote)
        internal
        view
        returns (uint addressLiquidity, uint tokenAmount, uint baseTokenAmount)
    {
        (uint tokenReserve, uint baseTokenReserve) = getReserves(pair);
        uint totalSupply = getTotalSupply(pair);
        uint minimumLiquidity = getMinimumLiquidity(pair);
        addressLiquidity = getAddressBalance(pair, addressToQuote);

        if (addressLiquidity == 0) {
            return (0, 0, 0);
        }

        tokenAmount = addressLiquidity.mul(tokenReserve).div(totalSupply.sub(minimumLiquidity));
        baseTokenAmount = addressLiquidity.mul(baseTokenReserve).div(totalSupply.sub(minimumLiquidity));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

interface IUniswapV2Router {
    function factory() external view returns (address);

    function addLiquidity(
        bytes32 tokenHash,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        bytes32 tokenHash,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        bytes32 tokenHash,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        bytes32 tokenHash,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        bytes32 tokenHash,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        bytes32 tokenHash,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityGetExactTokensBack(
        bytes32 tokenHash,
        uint amountTokensToReturn,
        uint amountBaseTokensToReturn,
        bool returnETH,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function swapExactBaseTokensForTokens(
        uint baseTokenAmountIn,
        uint tokenAmountOutMin,
        bytes32 tokenHash,
        address to,
        uint deadline
    ) external returns (uint tokenAmountOut);

    function swapExactETHForTokens(
        uint tokenAmountOutMin,
        bytes32 tokenHash,
        address to,
        uint deadline
    ) external payable returns (uint tokenAmountOut);

    function swapBaseTokensForExactTokens(
        uint tokenAmountOut,
        uint baseTokenAmountInMax,
        bytes32 tokenHash,
        address to,
        uint deadline
    ) external returns (uint baseTokenAmountIn);

    function swapETHForExactTokens(
        uint tokenAmountOut,
        bytes32 tokenHash,
        address to,
        uint deadline
    ) external payable returns (uint ethAmountIn);

    function swapExactTokensForBaseTokens(
        uint tokenAmountIn,
        uint baseTokenAmountOutMin,
        bytes32 tokenHash,
        address to,
        uint deadline
    ) external returns (uint baseTokenAmountOut);

    function swapExactTokensForETH(
        uint tokenAmountIn,
        uint ethAmountOutMin,
        bytes32 tokenHash,
        address to,
        uint deadline
    ) external returns (uint ethAmountOut);

    function swapTokensForExactBaseTokens(
        uint baseTokenAmountOut,
        uint tokenAmountInMax,
        bytes32 tokenHash,
        address to,
        uint deadline
    ) external returns (uint tokenAmountIn);

    function swapTokensForExactETH(
        uint ethAmountOut,
        uint tokenAmountInMax,
        bytes32 tokenHash,
        address to,
        uint deadline
    ) external returns (uint tokenAmountIn);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getTokenAmountOut(uint baseTokenAmountIn, bytes32 tokenHash) external view returns (uint amountOut);
    function getBaseTokenAmountOut(uint tokenAmountIn, bytes32 tokenHash) external view returns (uint amountOut);
    function getTokenAmountIn(uint baseTokenAmountIn, bytes32 tokenHash) external view returns (uint amountOut);
    function getBaseTokenAmountIn(uint tokenAmountIn, bytes32 tokenHash) external view returns (uint amountOut);

    function calculateLiquidityRequiredToGetTokensOut(
        bytes32 tokenHash,
        uint amountTokensToReturn,
        uint amountBaseTokensToReturn
    ) external view returns (uint);

    function quoteAddressLiquidity(
        bytes32 tokenHash,
        address addressToQuote
    ) external view returns (uint addressLiquidity, uint tokenAmount, uint baseTokenAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "./IUniswapV2Router.sol";
import "../factory/interfaces/IUniswapV2Factory.sol";
import "../factory/interfaces/IUniswapV2Pair.sol";
import "../factory/interfaces/IUniswapV2ERC20.sol";
import "../factory/lib/UniswapV2Library.sol";
import "../../wrappedErc20/IWrappedERC20.sol";

import "../../common/utils/TransferHelper.sol";
import "../../common/math/SafeMath.sol";

contract UniswapV2Router is IUniswapV2Router {
    using SafeMath for uint256;

    address public immutable override factory;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        _;
    }

    event LiquidityAdded(address sender, bytes32 tokenHash, uint liquidity, uint amountBaseToken, uint amountToken);
    event LiquidityRemoved(address sender, bytes32 tokenHash, uint liquidity, uint amountBaseToken, uint amountToken);
    event SwapBaseTokensForExactTokens(address sender, bytes32 tokenHash, uint baseTokenAmountIn, uint tokenAmountOut);
    event SwapETHForExactTokens(address sender, bytes32 tokenHash, uint ethAmountIn, uint tokenAmountOut);
    event SwapTokensForExactBaseTokens(address sender, bytes32 tokenHash, uint baseTokenAmountOut, uint tokenAmountIn);
    event SwapTokensForExactETH(address sender, bytes32 tokenHash, uint ethAmountOut, uint tokenAmountIn);
    event SwapExactTokensForBaseTokens(address sender, bytes32 tokenHash, uint baseTokenAmountOut, uint tokenAmountIn);
    event SwapExactTokensForETH(address sender, bytes32 tokenHash, uint ethAmountOut, uint tokenAmountIn);
    event SwapExactBaseTokensForTokens(address sender, bytes32 tokenHash, uint baseTokenAmountIn, uint tokenAmountOut);
    event SwapExactETHForTokens(address sender, bytes32 tokenHash, uint ethAmountIn, uint tokenAmountOut);

    constructor(address _factory) public {
        factory = _factory;
    }

    receive() external payable {
        address baseToken = IUniswapV2Factory(factory).baseToken();
        assert(msg.sender == baseToken); // only accept ETH via fallback from the WrappedERC20 contract
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        bytes32 tokenHash,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal virtual returns (uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        address pair = IUniswapV2Factory(factory).getPair(tokenHash);
        if (pair == address(0)) {
            IUniswapV2Factory(factory).createPair(tokenHash);
        }
        (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(pair);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function addLiquidity(
        bytes32 tokenHash,
        uint amountTokenDesired,
        uint amountBaseTokenDesired,
        uint amountTokenMin,
        uint amountBaseTokenMin,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint amountToken, uint amountBaseToken, uint liquidity) {
        address baseToken = IUniswapV2Factory(factory).baseToken();
        address dispenser = IUniswapV2Factory(factory).dispenser();
        address pair = IUniswapV2Factory(factory).getPair(tokenHash);

        (amountToken, amountBaseToken) = _addLiquidity(
            tokenHash,
            amountTokenDesired,
            amountBaseTokenDesired,
            amountTokenMin,
            amountBaseTokenMin
        );

        TransferHelper.safeTransferFromERC1155(dispenser, tokenHash, msg.sender, pair, amountToken);
        TransferHelper.safeTransferFrom(baseToken, msg.sender, pair, amountBaseToken);
        liquidity = IUniswapV2Pair(pair).mint(to);

        emit LiquidityAdded(msg.sender, tokenHash, liquidity, amountBaseToken, amountToken);
    }

    function addLiquidityETH(
        bytes32 tokenHash,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external virtual override payable ensure(deadline) returns (uint amountToken, uint amountETH, uint liquidity) {
        address baseToken = IUniswapV2Factory(factory).baseToken();
        address dispenser = IUniswapV2Factory(factory).dispenser();
        address pair = IUniswapV2Factory(factory).getPair(tokenHash);
        (amountToken, amountETH) = _addLiquidity(tokenHash, amountTokenDesired, msg.value, amountTokenMin, amountETHMin);

        TransferHelper.safeTransferFromERC1155(dispenser, tokenHash, msg.sender, pair, amountToken);
        IWrappedERC20(baseToken).deposit{value: amountETH}();
        assert(IWrappedERC20(baseToken).transfer(pair, amountETH));
        liquidity = IUniswapV2Pair(pair).mint(to);

        // refund dust eth, if any
        if (msg.value > amountETH) {
            TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
        }

        emit LiquidityAdded(msg.sender, tokenHash, liquidity, amountETH, amountToken);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        bytes32 tokenHash,
        uint liquidity,
        uint amountTokenMin,
        uint amountBaseTokenMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountToken, uint amountBaseToken) {
        address pair = IUniswapV2Factory(factory).getPair(tokenHash);
        IUniswapV2ERC20(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (amountToken, amountBaseToken) = IUniswapV2Pair(pair).burn(to, 0, 0);

        require(amountToken >= amountTokenMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
        require(amountBaseToken >= amountBaseTokenMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');

        emit LiquidityRemoved(msg.sender, tokenHash, liquidity, amountBaseToken, amountToken);
    }

    function removeLiquidityETH(
        bytes32 tokenHash,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountToken, uint amountETH) {
        address baseToken = IUniswapV2Factory(factory).baseToken();
        address dispenser = IUniswapV2Factory(factory).dispenser();

        (amountToken, amountETH) = removeLiquidity(
            tokenHash,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransferFromERC1155(dispenser, tokenHash, address(this), to, amountToken);
        IWrappedERC20(baseToken).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    function removeLiquidityGetExactTokensBack(
        bytes32 tokenHash,
        uint amountTokensToReturn,
        uint amountBaseTokensToReturn,
        bool returnETH,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountToken, uint amountETH) {
        uint liquidity = calculateLiquidityRequiredToGetTokensOut(tokenHash, amountTokensToReturn, amountBaseTokensToReturn);
        address pair = IUniswapV2Factory(factory).getPair(tokenHash);

        IUniswapV2ERC20(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        if (returnETH) {
            (amountToken, amountETH) = IUniswapV2Pair(pair).burn(address(this), amountTokensToReturn, amountBaseTokensToReturn);
        } else {
            (amountToken, amountETH) = IUniswapV2Pair(pair).burn(to, amountTokensToReturn, amountBaseTokensToReturn);
        }
        require(amountToken == amountTokensToReturn, 'UniswapV2Router: WRONG_AMOUNT_BURNED');

        emit LiquidityRemoved(msg.sender, tokenHash, liquidity, amountETH, amountToken);

        if (returnETH) {
            address baseToken = IUniswapV2Factory(factory).baseToken();
            address dispenser = IUniswapV2Factory(factory).dispenser();
            TransferHelper.safeTransferFromERC1155(dispenser, tokenHash, address(this), to, amountToken);
            IWrappedERC20(baseToken).withdraw(amountETH);
            TransferHelper.safeTransferETH(to, amountETH);
        }
    }

    function removeLiquidityWithPermit(
        bytes32 tokenHash,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountA, uint amountB) {
        address pair = IUniswapV2Factory(factory).getPair(tokenHash);
        uint value = approveMax ? uint(-1) : liquidity;
        IUniswapV2ERC20(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(tokenHash, liquidity, amountAMin, amountBMin, to, deadline);
    }

    function removeLiquidityETHWithPermit(
        bytes32 tokenHash,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountToken, uint amountETH) {
        address pair = IUniswapV2Factory(factory).getPair(tokenHash);
        uint value = approveMax ? uint(-1) : liquidity;
        IUniswapV2ERC20(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountETH) = removeLiquidityETH(tokenHash, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swapToTokens(uint _tokenAmountOut, bytes32 tokenHash, address _to) internal virtual {
        address pair = IUniswapV2Factory(factory).getPair(tokenHash);
        (uint tokenAmountOut, uint baseTokenAmountOut) = (_tokenAmountOut, uint(0));
        IUniswapV2Pair(pair).swap(tokenAmountOut, baseTokenAmountOut, _to, new bytes(0));
    }

    function _swapToBaseToken(uint _baseTokenAmountOut, bytes32 tokenHash, address _to) internal virtual {
        (uint tokenAmountOut, uint baseTokenAmountOut) = (uint(0), _baseTokenAmountOut);
        address pair = IUniswapV2Factory(factory).getPair(tokenHash);
        IUniswapV2Pair(pair).swap(
            tokenAmountOut, baseTokenAmountOut, _to, new bytes(0)
        );
    }

    function swapExactBaseTokensForTokens(
        uint baseTokenAmountIn,
        uint tokenAmountOutMin,
        bytes32 tokenHash,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint tokenAmountOut) {
        address baseToken = IUniswapV2Factory(factory).baseToken();
        address pair = IUniswapV2Factory(factory).getPair(tokenHash);

        tokenAmountOut = UniswapV2Library.getTokenAmountOut(pair, baseTokenAmountIn);
        require(tokenAmountOut >= tokenAmountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT_TOKEN');

        TransferHelper.safeTransferFrom(baseToken, msg.sender, pair, baseTokenAmountIn);
        _swapToTokens(tokenAmountOut, tokenHash, to);

        emit SwapExactBaseTokensForTokens(msg.sender, tokenHash, baseTokenAmountIn, tokenAmountOut);
    }

    function swapExactETHForTokens(
        uint tokenAmountOutMin,
        bytes32 tokenHash,
        address to,
        uint deadline
    ) external virtual override payable ensure(deadline) returns (uint tokenAmountOut) {
        address baseToken = IUniswapV2Factory(factory).baseToken();
        address pair = IUniswapV2Factory(factory).getPair(tokenHash);
        uint ethAmountIn = msg.value;

        tokenAmountOut = UniswapV2Library.getTokenAmountOut(pair, ethAmountIn);
        require(tokenAmountOut >= tokenAmountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');

        IWrappedERC20(baseToken).deposit{value: ethAmountIn}();
        assert(IWrappedERC20(baseToken).transfer(pair, ethAmountIn));
        _swapToTokens(tokenAmountOut, tokenHash, to);

        emit SwapExactETHForTokens(msg.sender, tokenHash, ethAmountIn, tokenAmountOut);
    }

    function swapBaseTokensForExactTokens(
        uint tokenAmountOut,
        uint baseTokenAmountInMax,
        bytes32 tokenHash,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint baseTokenAmountIn) {
        address baseToken = IUniswapV2Factory(factory).baseToken();
        address pair = IUniswapV2Factory(factory).getPair(tokenHash);

        baseTokenAmountIn = UniswapV2Library.getBaseTokenAmountIn(pair, tokenAmountOut);
        require(baseTokenAmountIn <= baseTokenAmountInMax, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT_BASE_TOKEN');

        TransferHelper.safeTransferFrom(baseToken, msg.sender, pair, baseTokenAmountIn);
        _swapToTokens(tokenAmountOut, tokenHash, to);

        emit SwapBaseTokensForExactTokens(msg.sender, tokenHash, baseTokenAmountIn, tokenAmountOut);
    }

    function swapETHForExactTokens(
        uint tokenAmountOut,
        bytes32 tokenHash,
        address to,
        uint deadline
    ) external virtual override payable ensure(deadline) returns (uint ethAmountIn){
        address baseToken = IUniswapV2Factory(factory).baseToken();
        address pair = IUniswapV2Factory(factory).getPair(tokenHash);

        ethAmountIn = UniswapV2Library.getBaseTokenAmountIn(pair, tokenAmountOut);
        require(ethAmountIn <= msg.value, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');

        IWrappedERC20(baseToken).deposit{value: ethAmountIn}();
        assert(IWrappedERC20(baseToken).transfer(pair, ethAmountIn));
        _swapToTokens(tokenAmountOut, tokenHash, to);

        // refund dust eth, if any
        if (msg.value > ethAmountIn) {
            TransferHelper.safeTransferETH(msg.sender, msg.value - ethAmountIn);
        }

        emit SwapETHForExactTokens(msg.sender, tokenHash, ethAmountIn, tokenAmountOut);
    }

    function swapExactTokensForBaseTokens(
        uint tokenAmountIn,
        uint baseTokenAmountOutMin,
        bytes32 tokenHash,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint baseTokenAmountOut) {
        address pair = IUniswapV2Factory(factory).getPair(tokenHash);
        address dispenser = IUniswapV2Factory(factory).dispenser();

        baseTokenAmountOut = UniswapV2Library.getBaseTokenAmountOut(pair, tokenAmountIn);
        require(baseTokenAmountOut >= baseTokenAmountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT_BASE_TOKEN');

        TransferHelper.safeTransferFromERC1155(dispenser, tokenHash, msg.sender, pair, tokenAmountIn);
        _swapToBaseToken(baseTokenAmountOut, tokenHash, to);

        emit SwapExactTokensForBaseTokens(msg.sender, tokenHash, baseTokenAmountOut, tokenAmountIn);
    }

    function swapExactTokensForETH(
        uint tokenAmountIn,
        uint ethAmountOutMin,
        bytes32 tokenHash,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint ethAmountOut) {
        address baseToken = IUniswapV2Factory(factory).baseToken();
        address pair = IUniswapV2Factory(factory).getPair(tokenHash);
        address dispenser = IUniswapV2Factory(factory).dispenser();

        ethAmountOut = UniswapV2Library.getBaseTokenAmountOut(pair, tokenAmountIn);
        require(ethAmountOut >= ethAmountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT_ETH');

        TransferHelper.safeTransferFromERC1155(dispenser, tokenHash, msg.sender, pair, tokenAmountIn);
        _swapToBaseToken(ethAmountOut, tokenHash, address(this));

        IWrappedERC20(baseToken).withdraw(ethAmountOut);
        TransferHelper.safeTransferETH(to, ethAmountOut);

        emit SwapExactTokensForETH(msg.sender, tokenHash, ethAmountOut, tokenAmountIn);
    }

    function swapTokensForExactBaseTokens(
        uint baseTokenAmountOut,
        uint tokenAmountInMax,
        bytes32 tokenHash,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint tokenAmountIn) {
        address pair = IUniswapV2Factory(factory).getPair(tokenHash);
        address dispenser = IUniswapV2Factory(factory).dispenser();

        tokenAmountIn = UniswapV2Library.getTokenAmountIn(pair, baseTokenAmountOut);
        require(tokenAmountIn <= tokenAmountInMax, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT_TOKEN');

        TransferHelper.safeTransferFromERC1155(dispenser, tokenHash, msg.sender, pair, tokenAmountIn);
        _swapToBaseToken(baseTokenAmountOut, tokenHash, to);

        emit SwapTokensForExactBaseTokens(msg.sender, tokenHash, baseTokenAmountOut, tokenAmountIn);
    }

    function swapTokensForExactETH(
        uint ethAmountOut,
        uint tokenAmountInMax,
        bytes32 tokenHash,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint tokenAmountIn) {
        address baseToken = IUniswapV2Factory(factory).baseToken();
        address pair = IUniswapV2Factory(factory).getPair(tokenHash);
        address dispenser = IUniswapV2Factory(factory).dispenser();

        tokenAmountIn = UniswapV2Library.getTokenAmountIn(pair, ethAmountOut);
        require(tokenAmountIn <= tokenAmountInMax, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT_TOKEN');

        TransferHelper.safeTransferFromERC1155(dispenser, tokenHash, msg.sender, pair, tokenAmountIn);
        _swapToBaseToken(ethAmountOut, tokenHash, address(this));

        IWrappedERC20(baseToken).withdraw(ethAmountOut);
        TransferHelper.safeTransferETH(to, ethAmountOut);

        emit SwapTokensForExactETH(msg.sender, tokenHash, ethAmountOut, tokenAmountIn);
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(uint amountA, uint reserveA, uint reserveB) public pure virtual override returns (uint amountB) {
        return UniswapV2Library.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        override
        returns (uint amountOut)
    {
        return UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        override
        returns (uint amountIn)
    {
        return UniswapV2Library.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getTokenAmountOut(uint baseTokenAmountIn, bytes32 tokenHash)
        public
        view
        virtual
        override
        returns (uint amountOut)
    {
        address pair = IUniswapV2Factory(factory).getPair(tokenHash);
        return UniswapV2Library.getTokenAmountOut(pair, baseTokenAmountIn);
    }

    function getBaseTokenAmountOut(uint tokenAmountIn, bytes32 tokenHash)
        public
        view
        virtual
        override
        returns (uint amountOut)
    {
        address pair = IUniswapV2Factory(factory).getPair(tokenHash);
        return UniswapV2Library.getBaseTokenAmountOut(pair, tokenAmountIn);
    }

    function getBaseTokenAmountIn(uint tokenAmountOut, bytes32 tokenHash)
      public
      view
      virtual
      override
      returns (uint amountOut)
    {
      address pair = IUniswapV2Factory(factory).getPair(tokenHash);
      return UniswapV2Library.getBaseTokenAmountIn(pair, tokenAmountOut);
    }

    function getTokenAmountIn(uint baseTokenAmountOut, bytes32 tokenHash)
      public
      view
      virtual
      override
      returns (uint amountOut)
    {
      address pair = IUniswapV2Factory(factory).getPair(tokenHash);
      return UniswapV2Library.getTokenAmountIn(pair, baseTokenAmountOut);
    }

    function calculateLiquidityRequiredToGetTokensOut(bytes32 tokenHash, uint amountTokensToReturn, uint amountBaseTokensToReturn)
        public
        view
        virtual
        override
        returns (uint liquidity)
    {
        address pair = IUniswapV2Factory(factory).getPair(tokenHash);
        return UniswapV2Library.calculateLiquidityRequiredToGetTokensOut(pair, amountTokensToReturn, amountBaseTokensToReturn);
    }

    function quoteAddressLiquidity(bytes32 tokenHash, address addressToQuote)
        public
        view
        virtual
        override
        returns (uint addressLiquidity, uint tokenAmount, uint baseTokenAmount)
    {
        address pair = IUniswapV2Factory(factory).getPair(tokenHash);
        return UniswapV2Library.quoteAddressLiquidity(pair, addressToQuote);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IWrappedERC20 {
    function deposit() external payable;
    function withdraw(uint value) external;
    function transfer(address to, uint value) external returns (bool);
}
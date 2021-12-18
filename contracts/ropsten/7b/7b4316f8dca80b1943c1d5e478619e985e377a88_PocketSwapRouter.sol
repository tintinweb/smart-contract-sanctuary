/**
 *Submitted for verification at Etherscan.io on 2021-12-18
*/

/**
 *Submitted for verification at Etherscan.io on 2021-12-16
*/

// SPDX-License-Identifier: Unlicense

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

// File: contracts/pocketswap/libraries/PairAddress.sol

pragma solidity >=0.5.0;

/// @title Provides functions for deriving a pair address from the factory, tokens, and the fee
library PairAddress {
    bytes32 internal constant PAIR_INIT_CODE_HASH = 0x572a33aeb892195070dabd08365bc9a44ba472bea83c1e753aaae477d7bcdfa0;

    /// @notice Deterministically computes the pair address given the factory and PairKey
    /// @param factory The PocketSwap factory contract address
    /// @param tokenA The first token of a pair, unsorted
    /// @param tokenB The second token of a pair, unsorted
    /// @return pair The contract address of the pair
    function computeAddress(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);

        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex'ff',
                            factory,
                            keccak256(abi.encodePacked(tokenA, tokenB)),
                            PAIR_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }
}

// File: contracts/pocketswap/interfaces/IPocketSwapFactory.sol

pragma solidity =0.8.4;

interface IPocketSwapFactory {
    function fee() external view returns (uint256);

    function holdersFee() external view returns (uint256);

    function setFee(uint256) external;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeSetter(address) external;
}

// File: contracts/pocketswap/interfaces/IPocketSwapERC20.sol

pragma solidity >=0.5.0;

interface IPocketSwapERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

// File: contracts/pocketswap/interfaces/IPocketSwapPair.sol

pragma solidity >=0.5.0;


interface IPocketSwapPair is IPocketSwapERC20 {
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// File: contracts/pocketswap/libraries/AddressStringUtil.sol


pragma solidity >=0.5.0;

library AddressStringUtil {
    // converts an address to the uppercase hex string, extracting only len bytes (up to 20, multiple of 2)
    function toAsciiString(address addr, uint256 len) internal pure returns (string memory) {
        require(len % 2 == 0 && len > 0 && len <= 40, 'AddressStringUtil: INVALID_LEN');

        bytes memory s = new bytes(len);
        uint256 addrNum = uint256(uint160(addr));
        for (uint256 i = 0; i < len / 2; i++) {
            // shift right and truncate all but the least significant byte to extract the byte at position 19-i
            uint8 b = uint8(addrNum >> (8 * (19 - i)));
            // first hex character is the most significant 4 bits
            uint8 hi = b >> 4;
            // second hex character is the least significant 4 bits
            uint8 lo = b - (hi << 4);
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    // hi and lo are only 4 bits and between 0 and 16
    // this method converts those values to the unicode/ascii code point for the hex representation
    // uses upper case for the characters
    function char(uint8 b) private pure returns (bytes1 c) {
        if (b < 10) {
            return bytes1(b + 0x30);
        } else {
            return bytes1(b + 0x37);
        }
    }
}

// File: contracts/pocketswap/libraries/PlainMath.sol

pragma solidity ^0.8.0;

library PlainMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
}

// File: contracts/pocketswap/libraries/PocketSwapLibrary.sol

pragma solidity =0.8.4;






library PocketSwapLibrary {
    using PlainMath for uint;
    using AddressStringUtil for address;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'PocketSwapLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'PocketSwapLibrary: ZERO_ADDRESS');
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        address pair = PairAddress.computeAddress(factory, tokenA, tokenB);
        IPocketSwapPair pairO = IPocketSwapPair(pair);
        (uint reserve0, uint reserve1,) = pairO.getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'PocketSwapLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'PocketSwapLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(address factory, uint amountIn, uint reserveIn, uint reserveOut) internal view returns (uint amountOut) {
        require(amountIn > 0, 'PocketSwapLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PocketSwapLibrary: INSUFFICIENT_LIQUIDITY');

        uint fee = IPocketSwapFactory(factory).fee();

        uint amountInWithFee = amountIn.mul(1e9 - fee);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1e9).add(amountInWithFee);

        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(address factory, uint amountOut, uint reserveIn, uint reserveOut) internal view returns (uint amountIn) {
        require(amountOut > 0, 'PocketSwapLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PocketSwapLibrary: INSUFFICIENT_LIQUIDITY');

        uint fee = IPocketSwapFactory(factory).fee();

        uint numerator = reserveIn.mul(amountOut).mul(1e9);
        uint denominator = reserveOut.sub(amountOut).mul(1e9 - fee);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PocketSwapLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(factory, amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PocketSwapLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(factory, amounts[i], reserveIn, reserveOut);
        }
    }
}

// File: contracts/pocketswap/libraries/BytesLib.sol

/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.5.0;

library BytesLib {
    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, 'slice_overflow');
        require(_start + _length >= _start, 'slice_overflow');
        require(_bytes.length >= _start + _length, 'slice_outOfBounds');

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
                tempBytes := mload(0x40)

            // The first word of the slice result is potentially a partial
            // word read from the original array. To read it, we calculate
            // the length of that partial word and start copying that many
            // bytes into the array. The first word we copy will start with
            // data we don't care about, but the last `lengthmod` bytes will
            // land at the beginning of the contents of the new array. When
            // we're done copying, we overwrite the full first word with
            // the actual length of the slice.
                let lengthmod := and(_length, 31)

            // The multiplication in the next line is necessary
            // because when slicing multiples of 32 bytes (lengthmod == 0)
            // the following copy loop was copying the origin's length
            // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                // The multiplication in the next line has the same exact purpose
                // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

            //update free-memory pointer
            //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
            //zero out the 32 bytes slice we are about to return
            //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, 'toAddress_overflow');
        require(_bytes.length >= _start + 20, 'toAddress_outOfBounds');
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_start + 3 >= _start, 'toUint24_overflow');
        require(_bytes.length >= _start + 3, 'toUint24_outOfBounds');
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }
}

// File: contracts/pocketswap/libraries/Path.sol

pragma solidity >=0.6.0;


/// @title Functions for manipulating path data for multihop swaps
library Path {
    using BytesLib for bytes;

    /// @dev The length of the bytes encoded address
    uint256 private constant ADDR_SIZE = 20;
    /// @dev The offset of a single token address
    uint256 private constant NEXT_OFFSET = ADDR_SIZE;
    /// @dev The offset of an encoded pool key
    uint256 private constant POP_OFFSET = NEXT_OFFSET + ADDR_SIZE;
    /// @dev The minimum length of an encoding that contains 2 or more pools
    uint256 private constant MULTIPLE_POOLS_MIN_LENGTH = POP_OFFSET + NEXT_OFFSET;

    /// @notice Returns true iff the path contains two or more pools
    /// @param path The encoded swap path
    /// @return True if path contains two or more pools, otherwise false
    function hasMultiplePools(bytes memory path) internal pure returns (bool) {
        return path.length >= MULTIPLE_POOLS_MIN_LENGTH;
    }

    /// @notice Decodes the first pool in path
    /// @param path The bytes encoded swap path
    /// @return tokenA The first token of the given pool
    /// @return tokenB The second token of the given pool
    function decodeFirstPool(bytes memory path)
    internal
    pure
    returns (
        address tokenA,
        address tokenB
    )
    {
        tokenA = path.toAddress(0);
        tokenB = path.toAddress(ADDR_SIZE);
    }

    /// @notice Gets the segment corresponding to the first pool in the path
    /// @param path The bytes encoded swap path
    /// @return The segment containing all data necessary to target the first pool in the path
    function getFirstPool(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(0, POP_OFFSET);
    }

    /// @notice Skips a token element from the buffer and returns the remainder
    /// @param path The swap path
    /// @return The remaining token elements in the path
    function skipToken(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(NEXT_OFFSET, path.length - NEXT_OFFSET);
    }
}

// File: contracts/pocketswap/libraries/TransferHelper.sol

pragma solidity >=0.6.0;


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
        token.call(abi.encodeWithSelector(bytes4(keccak256(bytes('transferFrom(address,address,uint256)'))), from, to, value));
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
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(bytes4(keccak256(bytes('transfer(address,uint256)'))), to, value));
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
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(bytes4(keccak256(bytes('approve(address,uint256)'))), to, value));
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

// File: contracts/pocketswap/interfaces/callback/IPocketSwapCallback.sol

pragma solidity >=0.6.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls TokenSwapActions#swap must implement this interface
interface IPocketSwapCallback {
    function pocketSwapCallback(
        uint256 amount0Delta,
        uint256 amount1Delta,
        bytes calldata data
    ) external;
}

// File: contracts/pocketswap/interfaces/IPocketSwapRouter.sol

pragma solidity =0.8.4;
pragma abicoder v2;



/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface IPocketSwapRouter is IPocketSwapCallback {
    function pairFor(
        address tokenA,
        address tokenB
    ) external view returns (IPocketSwapPair);

    struct SwapParams {
        address tokenIn; // Address of the token you're sending for a SWAP
        address tokenOut; // Address of the token you're going to receive
        address recipient; // Address which will receive tokenOut
        uint256 deadline; // will revert if transaction was confirmed too late
        uint256 amountIn; // amount of the tokenIn to be swapped
        uint256 amountOutMinimum; // minimum amount you're expecting to receive
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `SwapParams` in calldata
    /// @return amountOut The amount of the received token
    function swap(SwapParams calldata params) external payable returns (uint256 amountOut);

    struct SwapMultiParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }
    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `SwapMultiParams` in calldata
    /// @return amountOut The amount of the received token
    function swapMulti(SwapMultiParams calldata params) external payable returns (uint256 amountOut);

    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] memory path) external view returns (uint[] memory amounts);
}

// File: contracts/pocketswap/interfaces/IPeripheryImmutableState.sol

pragma solidity >=0.5.0;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IPeripheryImmutableState {
    /// @return Returns the address of the PocketSwap factory
    function factory() external view returns (address);

    /// @return Returns the address of WETH9
    function WETH9() external view returns (address);

    /// @return Returns the address of POCKET token
    function pocket() external view returns (address);
}

// File: contracts/pocketswap/abstract/PeripheryImmutableState.sol

pragma solidity =0.8.4;


/// @title Immutable state
/// @notice Immutable state used by periphery contracts
abstract contract PeripheryImmutableState is IPeripheryImmutableState {
    /// @inheritdoc IPeripheryImmutableState
    address public immutable override factory;
    /// @inheritdoc IPeripheryImmutableState
    address public immutable override WETH9;
    /// @inheritdoc IPeripheryImmutableState
    address public immutable override pocket;

    constructor(address _factory, address _WETH9, address _pocketToken) {
        factory = _factory;
        WETH9 = _WETH9;
        pocket = _pocketToken;
    }
}

// File: contracts/pocketswap/interfaces/IPeripheryPayments.sol

pragma solidity =0.8.4;

/// @title Periphery Payments
/// @notice Functions to ease deposits and withdrawals of ETH
interface IPeripheryPayments {
    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    /// @param amountMinimum The minimum amount of WETH9 to unwrap
    /// @param recipient The address receiving ETH
    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;

    /// @notice Sends the full amount of a token held by this contract to the given recipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the token which will be transferred to `recipient`
    /// @param amountMinimum The minimum amount of token required for a transfer
    /// @param recipient The destination address of the token
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable;
}

// File: contracts/pocketswap/interfaces/external/IWETH9.sol

pragma solidity =0.8.4;


/// @title Interface for WETH9
interface IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

// File: contracts/pocketswap/abstract/PeripheryPayments.sol

pragma solidity =0.8.4;






abstract contract PeripheryPayments is IPeripheryPayments, PeripheryImmutableState {
    /// @inheritdoc IPeripheryPayments
    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable override {
        uint256 balanceWETH9 = IWETH9(WETH9).balanceOf(address(this));
        if (amountMinimum > 0) require(balanceWETH9 >= amountMinimum, 'Insufficient WETH9');

        if (balanceWETH9 > 0) {
            IWETH9(WETH9).withdraw(balanceWETH9);
            TransferHelper.safeTransferETH(recipient, balanceWETH9);
        }
    }

    /// @inheritdoc IPeripheryPayments
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable override {
        uint256 balanceToken = IERC20(token).balanceOf(address(this));
        if (amountMinimum > 0) require(balanceToken >= amountMinimum, 'Insufficient token');

        if (balanceToken > 0) TransferHelper.safeTransfer(token, recipient, balanceToken);
    }

    /// @param token The token to pay
    /// @param payer The entity that must pay
    /// @param recipient The entity that will receive payment
    /// @param value The amount to pay
    function pay(
        address token,
        address payer,
        address recipient,
        uint256 value
    ) internal {
        uint256 selfBalance;
        if (token == WETH9 && (selfBalance = address(this).balance) >= value) {
            // pay with WETH9 generated from ETH
            IWETH9(WETH9).deposit{value : selfBalance}();
            // wrap whole balance
            IWETH9(WETH9).transfer(recipient, value);
        } else if (payer == address(this)) {
            // pay with tokens already in the contract (for the exact input multihop case)
            TransferHelper.safeTransfer(token, recipient, value);
        } else {
            // pull payment
            TransferHelper.safeTransferFrom(token, payer, recipient, value);
        }
    }


    /// @param token The contract address of the token to be approved
    /// @param recipient The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function approve(
        address token,
        address recipient,
        uint256 value
    ) internal {
        // pull payment
        TransferHelper.safeApprove(token, recipient, value);
    }
}

// File: contracts/pocketswap/router/swap/SwapProcessing.sol

pragma solidity =0.8.4;









/// @title Processing routing functions
abstract contract SwapProcessing is
IPocketSwapRouter,
PeripheryImmutableState,
PeripheryPayments
{
    using Path for bytes;

    struct SwapCallbackData {
        bytes path;
        address payer;
    }

    function pairFor(
        address tokenA,
        address tokenB
    ) public view override returns (IPocketSwapPair) {
        return IPocketSwapPair(PairAddress.computeAddress(factory, tokenA, tokenB));
    }

    function exactInputInternal(
        uint256 amountIn,
        address recipient,
        SwapCallbackData memory data
    ) internal returns (uint256 amountOut) {
        (address tokenIn, address tokenOut) = data.path.decodeFirstPool();

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        amountOut = PocketSwapLibrary.getAmountsOut(factory, amountIn, path)[1];

        _swap(recipient, amountIn, amountOut, data);
    }

    /// @dev Performs a single exact output swap
    function exactOutputInternal(
        uint256 amountOut,
        address recipient,
        SwapCallbackData memory data
    ) internal returns (uint256 amountIn) {
        (address tokenOut, address tokenIn) = data.path.decodeFirstPool();

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        amountIn = PocketSwapLibrary.getAmountsIn(factory, amountOut, path)[0];

        _swap(recipient, amountIn, amountOut, data);
    }

    function _swap(
        address recipient,
        uint256 amountIn,
        uint256 amountOut,
        SwapCallbackData memory data
    ) private {
        (address tokenIn, address tokenOut) = data.path.decodeFirstPool();
        IPocketSwapPair pair = pairFor(tokenIn, tokenOut);

        pay(tokenIn, msg.sender, address(pair), amountIn);

        (address token0,) = PocketSwapLibrary.sortTokens(tokenIn, tokenOut);
        (uint amount0Out, uint amount1Out) = tokenIn == token0 ? (uint(0), amountOut) : (amountOut, uint(0));

        pair.swap(amount0Out, amount1Out, recipient, abi.encode(data));
    }
}

// File: contracts/pocketswap/abstract/BlockTimestamp.sol

pragma solidity =0.8.4;

/// @title Function for getting block timestamp
/// @dev Base contract that is overridden for tests
abstract contract BlockTimestamp {
    /// @dev Method that exists purely to be overridden for tests
    /// @return The current block timestamp
    function _blockTimestamp() internal view virtual returns (uint256) {
        return block.timestamp;
    }
}

// File: contracts/pocketswap/abstract/PeripheryValidation.sol

pragma solidity =0.8.4;


abstract contract PeripheryValidation is BlockTimestamp {
    modifier checkDeadline(uint256 deadline) {
        require(_blockTimestamp() <= deadline, 'Transaction too old');
        _;
    }
}

// File: contracts/pocketswap/interfaces/IMulticall.sol

pragma solidity >=0.7.5;

/// @title Multicall interface
/// @notice Enables calling multiple methods in a single call to the contract
interface IMulticall {
    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}

// File: contracts/pocketswap/abstract/Multicall.sol

pragma solidity =0.8.4;


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

// File: contracts/pocketswap/interfaces/IPocket.sol

pragma solidity =0.8.4;

interface IPocket {
    function addRewards(uint256 amount) external returns (bool);
    function rewardsExcluded(address) external view returns(bool);
}

// File: contracts/pocketswap/libraries/CallbackValidation.sol

pragma solidity =0.8.4;



/// @notice Provides validation for callbacks from PocketSwap Pairs
library CallbackValidation {
    /// @notice Returns the address of a valid PocketSwap Pair
    /// @param factory The contract address of the PocketSwap factory
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @return pair The pair contract address
    function verifyCallback(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (IPocketSwapPair pair) {
        pair = IPocketSwapPair(PairAddress.computeAddress(factory, tokenA, tokenB));
        require(msg.sender == address(pair));
    }
}

// File: contracts/pocketswap/router/SwapRouter.sol

pragma solidity =0.8.4;
















abstract contract SwapRouter is
IPocketSwapCallback,
IPocketSwapRouter,
PeripheryImmutableState,
PeripheryValidation,
Multicall,
SwapProcessing
{
    using PlainMath for uint;
    using Path for bytes;

    /// @dev Used as the placeholder value for amountInCached, because the computed amount in for an exact output swap
    /// can never actually be this value
    uint256 private constant DEFAULT_AMOUNT_IN_CACHED = type(uint256).max;

    /// @dev Transient storage variable used for returning the computed amount in for an exact output swap.
    uint256 private amountInCached = DEFAULT_AMOUNT_IN_CACHED;

    /// @inheritdoc IPocketSwapRouter
    function swap(SwapParams calldata params)
    external
    payable
    override
    checkDeadline(params.deadline)
    returns (uint256 amountOut)
    {
        amountOut = exactInputInternal(
            params.amountIn,
            params.recipient,
            SwapCallbackData({path : abi.encodePacked(params.tokenIn, params.tokenOut), payer : msg.sender})
        );
        require(amountOut >= params.amountOutMinimum, 'Too little received');
    }

    /// @inheritdoc IPocketSwapRouter
    function swapMulti(SwapMultiParams memory params)
    external
    payable
    override
    checkDeadline(params.deadline)
    returns (uint256 amountOut)
    {
        amountOut = 0;

        // msg.sender pays for the first hop
        address payer = msg.sender;

        while (true) {
            bool hasMultiplePools = params.path.hasMultiplePools();

            // the outputs of prior swaps become the inputs to subsequent ones
            params.amountIn = exactInputInternal(
                params.amountIn,
                hasMultiplePools ? address(this) : params.recipient, // for intermediate swaps, this contract custodies
                SwapCallbackData({path : params.path.getFirstPool(), payer : payer}) // only the first pool in the path is necessary
            );

            // decide whether to continue or terminate
            if (hasMultiplePools) {
                payer = address(this);
                // at this point, the caller has paid
                params.path = params.path.skipToken();
            } else {
                amountOut = params.amountIn;
                break;
            }
        }

        require(amountOut >= params.amountOutMinimum, 'Too little received');
    }

    /// @inheritdoc IPocketSwapCallback
    function pocketSwapCallback(
        uint256 amount0Delta,
        uint256 amount1Delta,
        bytes calldata _data
    ) external override {
        SwapCallbackData memory data = abi.decode(_data, (SwapCallbackData));
        (address tokenIn, address tokenOut) = data.path.decodeFirstPool();
        CallbackValidation.verifyCallback(factory, tokenIn, tokenOut);

        (bool isExactInput, uint256 amountToPay, uint256 amountIn) = amount0Delta > 0
        ? (tokenIn < tokenOut, uint256(amount0Delta), uint256(amount1Delta))
        : (tokenOut < tokenIn, uint256(amount1Delta), uint256(amount0Delta));

        uint256 holdersFee = IPocketSwapFactory(factory).holdersFee();

        if (tokenIn != pocket && tokenOut != pocket) {
            // finding POCKET pair
            address token = tokenIn;
            address pocketPair = IPocketSwapFactory(factory).getPair(tokenIn, pocket);
            uint256 amountForFee = amountIn;

            if (pocketPair == address(0)) {
                pocketPair = IPocketSwapFactory(factory).getPair(tokenOut, pocket);
                token = tokenOut;
                amountForFee = amountToPay;
                if (pocketPair == address(0)) {
                    revert("No POCKET pair");
                }
            }

            uint amount = amountForFee * holdersFee / 1e9;

            if (token == tokenOut) {
                amountToPay -= amount;
            }
            pay(token, msg.sender, pocketPair, amount);
            (address token0,) = PocketSwapLibrary.sortTokens(token, pocket);

            address[] memory path = new address[](2);
            path[0] = pocket;
            path[1] = token;
            uint amountOut = PocketSwapLibrary.getAmountsOut(factory, amount, path)[1];

            (uint amount0Out, uint amount1Out) = pocket == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            IPocketSwapPair(pocketPair).swap(amount0Out, amount1Out, address(this), "");
            IPocket(pocket).addRewards(IERC20(pocket).balanceOf(address(this)));
        } else {
            uint256 feeAmount = IERC20(pocket).balanceOf(msg.sender) * holdersFee / 1e9;
            TransferHelper.safeTransferFrom(pocket, msg.sender, pocket, feeAmount);
        }

        if (!isExactInput && data.path.hasMultiplePools()) {
            data.path = data.path.skipToken();
            exactOutputInternal(amountToPay, msg.sender, data);
        }
    }


    // **** LIBRARY FUNCTIONS ****
    function quote(uint amountA, uint reserveA, uint reserveB) public pure virtual /*override*/ returns (uint amountB) {
        return PocketSwapLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
    public
    view
    virtual
        /*override*/
    returns (uint amountOut)
    {
        return PocketSwapLibrary.getAmountOut(factory, amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut)
    public
    view
    virtual
        /*override*/
    returns (uint amountIn)
    {
        return PocketSwapLibrary.getAmountIn(factory, amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint amountIn, address[] memory path)
    public
    view
    virtual
    override
    returns (uint[] memory amounts)
    {
        return PocketSwapLibrary.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint amountOut, address[] memory path)
    public
    view
    virtual
    override
    returns (uint[] memory amounts)
    {
        return PocketSwapLibrary.getAmountsIn(factory, amountOut, path);
    }
}

// File: contracts/pocketswap/interfaces/IPocketSwapLiquidityRouter.sol

pragma solidity =0.8.4;

interface IPocketSwapLiquidityRouter {
    struct AddLiquidityParams {
        address token0; // Address of the First token in Pair
        address token1; // Address of the Second token in Pair
        address recipient; // address which will receive LP tokens
        uint256 amount0Desired; // Amount of the First token in Pair
        uint256 amount1Desired;// Amount of the Second token in Pair
        uint256 amount0Min; // mininum amount of the first token in pair
        uint256 amount1Min;// mininum amount of the second token in pair
        uint256 deadline; // reverts in case of transaction confirmed too late
    }

    function addLiquidity(AddLiquidityParams calldata params)
    external
    payable
    returns (uint amountA, uint amountB, uint amountPocket, uint liquidity);

    function calcLiquidity(AddLiquidityParams calldata params) external view
    returns (uint amountA, uint amountB);

    struct RemoveLiquidityParams {
        address tokenA; // Address of the First token in Pair
        address tokenB; // Address of the Second token in Pair
        uint liquidity; // Amount of the LP tokens you want to remove
        uint amountAMin; // Minimum amount you're expecting to receive of the First token
        uint amountBMin;// Minimum amount you're expecting to receive of the Second token
        address rewards; // Address of the rewards token (USDT, WETH, POCKET)
        address recipient; // Address which will receive tokens and rewards
        uint deadline;// Reverts in case of transaction confirmed too late
    }

    function removeLiquidity(RemoveLiquidityParams calldata params)
    external
    payable
    returns (uint amountA, uint amountB);
}

// File: contracts/pocketswap/libraries/Math.sol

pragma solidity >=0.5.16;

// a library for performing various math operations

library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// File: contracts/pocketswap/router/liquidity/LiquidityProcessing.sol

pragma solidity =0.8.4;









abstract contract LiquidityProcessing is
IPocketSwapLiquidityRouter,
PeripheryImmutableState,
PeripheryPayments
{
    using Path for bytes;

    struct LiquidityCallbackData {
        bytes path;
        address payer;
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        LiquidityCallbackData memory data
    )
    internal view
    returns (uint amountA, uint amountB) {
        // gas saving
        address _factory = factory;

        (address tokenA, address tokenB) = data.path.decodeFirstPool();
        (uint reserveA, uint reserveB) = PocketSwapLibrary.getReserves(_factory, tokenA, tokenB);

        if (reserveA == 0 && reserveB == 0) {
            return (amountADesired, amountBDesired);
        }

        uint amountBOptimal = PocketSwapLibrary.quote(amountADesired, reserveA, reserveB);
        if (amountBOptimal <= amountBDesired) {
            require(amountBOptimal >= amountBMin, 'PocketSwapRouter: INSUFFICIENT_B_AMOUNT');
            return (amountADesired, amountBOptimal);
        }

        uint amountAOptimal = PocketSwapLibrary.quote(amountBDesired, reserveB, reserveA);
        assert(amountAOptimal <= amountADesired);
        require(amountAOptimal >= amountAMin, 'PocketSwapRouter: INSUFFICIENT_A_AMOUNT');
        (amountA, amountB) = (amountAOptimal, amountBDesired);
    }
}

// File: contracts/pocketswap/router/LiquidityRouter.sol

pragma solidity =0.8.4;


abstract contract LiquidityRouter is
IPocketSwapLiquidityRouter,
PeripheryImmutableState,
PeripheryValidation,
LiquidityProcessing
{
    function addLiquidity(AddLiquidityParams calldata params)
    external
    payable
    override
    checkDeadline(params.deadline)
    returns (uint amountA, uint amountB, uint amountPocket, uint liquidity) {
        address pair = PairAddress.computeAddress(factory, params.token0, params.token1);

        (amountA, amountB) = calcLiquidity(params);
        pay(params.token0, msg.sender, pair, amountA);
        pay(params.token1, msg.sender, pair, amountB);
        liquidity = IPocketSwapPair(pair).mint(params.recipient);

        amountPocket = 0;
    }

    function calcLiquidity(AddLiquidityParams calldata params) public override view
    returns (uint amountA, uint amountB) {
        (amountA, amountB) = _addLiquidity(
            params.amount0Desired,
            params.amount1Desired,
            params.amount0Min,
            params.amount1Min,
            LiquidityCallbackData(
            {path : abi.encodePacked(params.token0, params.token1), payer : msg.sender}
            )
        );
    }

    bool locked = false;
    modifier lock() {
        require(!locked, "LOCKED");
        locked = true;
        _;
        locked = false;
    }

    function removeLiquidity(RemoveLiquidityParams calldata params)
    public
    payable
    override
    checkDeadline(params.deadline)
    lock
    returns (uint amountA, uint amountB) {
        IPocketSwapPair pair = IPocketSwapPair(
            PairAddress.computeAddress(factory, params.tokenA, params.tokenB)
        );
        pair.transferFrom(msg.sender, address(pair), params.liquidity);

        // send liquidity to pair
        (uint amount0, uint amount1) = pair.burn(address(this));
        (address token0,) = PocketSwapLibrary.sortTokens(params.tokenA, params.tokenB);
        (amountA, amountB) = params.tokenA == token0 ? (amount0, amount1) : (amount1, amount0);

        require(amountA >= params.amountAMin, 'PocketSwapRouter: INSUFFICIENT_A_AMOUNT');
        require(amountB >= params.amountBMin, 'PocketSwapRouter: INSUFFICIENT_B_AMOUNT');

        swapRewards(params.rewards, params.tokenA, amountA, params.recipient);
        swapRewards(params.rewards, params.tokenB, amountB, params.recipient);
    }

    function swapRewards(
        address rewardsAddress,
        address tokenAddress,
        uint256 amount,
        address recipient
    ) private {
        address pair = IPocketSwapFactory(factory).getPair(rewardsAddress, tokenAddress);
        if (pair == address(0)) {
            pay(tokenAddress, address(this), recipient, amount);
            return;
        }
        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = rewardsAddress;
        uint256 amountRewards = PocketSwapLibrary.getAmountsOut(factory, amount, path)[1];

        pay(tokenAddress, address(this), pair, amount);
        (address token0,) = PocketSwapLibrary.sortTokens(rewardsAddress, tokenAddress);
        (uint amount0Out, uint amount1Out) = tokenAddress == token0 ? (uint(0), amountRewards) : (amountRewards, uint(0));
        IPocketSwapPair(pair).swap(amount0Out, amount1Out, recipient, "");
    }
}

// File: contracts/pocketswap/PocketSwapRouter.sol

pragma solidity =0.8.4;




contract PocketSwapRouter is
PeripheryImmutableState,
PeripheryValidation,
SwapRouter,
LiquidityRouter
{
    constructor(address _factory, address _WETH9, address _pocketToken)
    PeripheryImmutableState(_factory, _WETH9, _pocketToken) {}
}
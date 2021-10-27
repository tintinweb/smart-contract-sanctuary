// SPDX-License-Identifier: Apache-2.0-or-later
/*

 Copyright 2021 Rigo Intl.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

// solhint-disable-next-line
pragma solidity 0.7.6;
pragma abicoder v2; // in 0.8 solc this is default behaviour

import "../../../utils/exchanges/uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "../../../utils/exchanges/uniswap/v3-periphery/contracts/interfaces/IPeripheryPaymentsWithFee.sol";
import "../../../utils/exchanges/uniswap/v3-periphery/contracts/interfaces/IPeripheryImmutableState.sol";
import "../../../utils/exchanges/uniswap/v3-periphery/contracts/libraries/Path.sol";

interface Token {

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256);
    function balanceOf(address _who) external view returns (uint256);
}

/// @title Interface for WETH9
interface IWETH9 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

contract AUniswapV3 {
    
    using Path for bytes;
    
    address payable immutable private UNISWAP_V3_SWAP_ROUTER_ADDRESS = payable(address(0xE592427A0AEce92De3Edee1F18E0157C05861564));
    bytes4 immutable private APPROVE_SELECTOR = bytes4(keccak256(bytes("approve(address,uint256)")));
    bytes4 immutable private EXACT_INPUT_SELECTOR = bytes4(keccak256("exactInput(ISwapRouter.ExactInputParams)"));
    bytes4 immutable private EXACT_INPUT_SINGLE_SELECTOR = bytes4(keccak256("exactInputSingle(ISwapRouter.ExactInputSingleParams)"));
    bytes4 immutable private EXACT_OUTPUT_SELECTOR = bytes4(keccak256("exactOutput(ISwapRouter.exactOutputParams)"));
    bytes4 immutable private EXACT_OUTPUT_SINGLE_SELECTOR = bytes4(keccak256("exactOutputSingle(ISwapRouter.ExactOutputSingleParams)"));
    bytes4 immutable private REFUND_ETH_SELECTOR = bytes4(keccak256("refundETH()"));
    bytes4 immutable private SWEEP_TOKEN_SELECTOR = bytes4(keccak256("sweepToken(address,uint256,address)"));
    bytes4 immutable private SWEEP_TOKEN_WITH_FEE_SELECTOR = bytes4(keccak256("sweepTokenWithFee(address,uint256,address,uint256,address)"));
    bytes4 immutable private UNWRAP_WETH9_SELECTOR = bytes4(keccak256("unwrapWETH9(uint256,address)"));
    bytes4 immutable private UNWRAP_WETH9_WITH_FEE_SELECTOR = bytes4(keccak256("unwrapWETH9WithFee(uint256,address,uint256,address)"));
    bytes4 immutable private WRAP_ETH_SELECTOR = bytes4(keccak256("wrapETH(uint256)"));
    
    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param data The encoded function data for each of the calls to make to this contract
    function multicall(bytes[] calldata data) external payable {
        for (uint256 i = 0; i < data.length; i++) {
            bytes memory messagePack = data[i];
            bytes4 selector;
            assembly {
                selector := mload(add(messagePack, 32))
            }
            
            if (selector == EXACT_INPUT_SINGLE_SELECTOR) {
                exactInputSingleInternal(abi.decode(data[i], (ISwapRouter.ExactInputSingleParams)));
            } else if (selector == EXACT_INPUT_SELECTOR) {
                exactInputInternal(abi.decode(data[i], (ISwapRouter.ExactInputParams)));
            } else if (selector == EXACT_OUTPUT_SINGLE_SELECTOR) {
                exactOutputSingleInternal(abi.decode(data[i], (ISwapRouter.ExactOutputSingleParams)));
            } else if (selector == EXACT_OUTPUT_SELECTOR) {
                exactOutputInternal(abi.decode(data[i], (ISwapRouter.ExactOutputParams)));
            } else if (selector == WRAP_ETH_SELECTOR) {
                wrapETHInternal(abi.decode(data[i], (uint256)));
            } else if (selector == UNWRAP_WETH9_SELECTOR) {
                (uint256 amountMinimum, address recipient) = abi.decode(data[i], (uint256, address));
                unwrapWETH9Internal(amountMinimum, recipient);
            } else if (selector == REFUND_ETH_SELECTOR) {
                refundETHInternal();
            } else if (selector == SWEEP_TOKEN_SELECTOR) {
                (address token, uint256 amountMinimum, address recipient) = abi.decode(
                    data[i],
                    (address, uint256, address)
                );
                sweepTokenInternal(token, amountMinimum, recipient);
            } else if (selector == UNWRAP_WETH9_WITH_FEE_SELECTOR) {
                (uint256 amountMinimum, address recipient, uint256 feeBips, address feeRecipient) = abi.decode(
                    data[i],
                    (uint256, address, uint256, address)
                );
                unwrapWETH9WithFeeInternal(amountMinimum, recipient, feeBips, feeRecipient);
            } else if (selector == SWEEP_TOKEN_WITH_FEE_SELECTOR) {
                (
                    address token,
                    uint256 amountMinimum,
                    address recipient,
                    uint256 feeBips,
                    address feeRecipient
                ) = abi.decode(
                    data[i],
                    (address, uint256, address, uint256, address)
                );
                sweepTokenWithFeeInternal(token, amountMinimum, recipient, feeBips, feeRecipient);
            } else revert("UNKNOWN_SELECTOR");
        }
    }
    
    /// @notice Wraps ETH when value input is non-null
    /// @param value The ETH amount to be wrapped
    function wrapETH(uint256 value) external payable {
        wrapETHInternal(value);
    }
    
    function wrapETHInternal(uint256 value) internal {
        if (value > uint256(0)) {
            IWETH9(
                IPeripheryImmutableState(UNISWAP_V3_SWAP_ROUTER_ADDRESS).WETH9()
            ).deposit{value: value}();
        }
    }
    
    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in memory
    /// @return amountOut The amount of the received token
    function exactInputSingle(ISwapRouter.ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut)
    {
        amountOut = exactInputSingleInternal(params);
    }
    
    function exactInputSingleInternal(ISwapRouter.ExactInputSingleParams memory params)
        internal
        returns (uint256 amountOut)
    {
        // we first set the allowance to the uniswap router
        if (Token(params.tokenIn).allowance(address(this), UNISWAP_V3_SWAP_ROUTER_ADDRESS) < params.amountIn) {
            safeApproveInternal(params.tokenIn, UNISWAP_V3_SWAP_ROUTER_ADDRESS, type(uint).max);
        }
        
        // finally, we swap the tokens
        amountOut = ISwapRouter(UNISWAP_V3_SWAP_ROUTER_ADDRESS).exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: params.tokenIn,
                tokenOut: params.tokenOut,
                fee: params.fee,
                recipient: address(this), // this drago is always the recipient
                deadline: params.deadline,
                amountIn: params.amountIn,
                amountOutMinimum: params.amountOutMinimum,
                sqrtPriceLimitX96: params.sqrtPriceLimitX96
            })
        );
    }
    
    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in memory
    /// @return amountOut The amount of the received token
    function exactInput(ISwapRouter.ExactInputParams calldata params)
        external
        payable
        returns (uint256 amountOut)
    {
        amountOut = exactInputInternal(params);
    }
    
    function exactInputInternal(ISwapRouter.ExactInputParams memory params)
        internal
        returns (uint256 amountOut)
    {
        (address tokenIn, , ) = params.path.decodeFirstPool();
        
        // we first set the allowance to the uniswap router
        if (Token(tokenIn).allowance(address(this), UNISWAP_V3_SWAP_ROUTER_ADDRESS) < params.amountIn) {
            safeApproveInternal(tokenIn, UNISWAP_V3_SWAP_ROUTER_ADDRESS, type(uint).max);
        }
        
        // finally, we swap the tokens
        amountOut = ISwapRouter(UNISWAP_V3_SWAP_ROUTER_ADDRESS).exactInput(
            ISwapRouter.ExactInputParams({
                path: params.path,
                recipient: address(this), // this drago is always the recipient
                deadline: params.deadline,
                amountIn: params.amountIn,
                amountOutMinimum: params.amountOutMinimum
            })    
        );
    }
    
    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in memory
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ISwapRouter.ExactOutputSingleParams calldata params)
        external
        payable
        returns (uint256 amountIn)
    {
        amountIn = exactOutputSingleInternal(params);
    }
    
    function exactOutputSingleInternal(ISwapRouter.ExactOutputSingleParams memory params)
        internal
        returns (uint256 amountIn)
    {
        // we first set the allowance to the uniswap router
        if (Token(params.tokenIn).allowance(address(this), UNISWAP_V3_SWAP_ROUTER_ADDRESS) < params.amountInMaximum) {
            safeApproveInternal(params.tokenIn, UNISWAP_V3_SWAP_ROUTER_ADDRESS, type(uint).max);
        }
        
        // finally, we swap the tokens
        amountIn = ISwapRouter(UNISWAP_V3_SWAP_ROUTER_ADDRESS).exactOutputSingle(
            ISwapRouter.ExactOutputSingleParams({
                tokenIn: params.tokenIn,
                tokenOut: params.tokenOut,
                fee: params.fee,
                recipient: address(this), // this drago is always the recipient
                deadline: params.deadline,
                amountOut: params.amountOut,
                amountInMaximum: params.amountInMaximum,
                sqrtPriceLimitX96: params.sqrtPriceLimitX96
            })    
        );
    }
    
    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in memory
    /// @return amountIn The amount of the input token
    function exactOutput(ISwapRouter.ExactOutputParams calldata params)
        external
        payable
        returns (uint256 amountIn)
    {
        amountIn = exactOutputInternal(params);
    }
    
    function exactOutputInternal(ISwapRouter.ExactOutputParams memory params)
        internal
        returns (uint256 amountIn)
    {
        (address tokenIn, , ) = params.path.decodeFirstPool();
        
        // we first set the allowance to the uniswap router
        if (Token(tokenIn).allowance(address(this), UNISWAP_V3_SWAP_ROUTER_ADDRESS) < params.amountInMaximum) {
            safeApproveInternal(tokenIn, UNISWAP_V3_SWAP_ROUTER_ADDRESS, type(uint).max);
        }
        
        // finally, we swap the tokens
        amountIn = ISwapRouter(UNISWAP_V3_SWAP_ROUTER_ADDRESS).exactOutput(
            ISwapRouter.ExactOutputParams({
                path: params.path,
                recipient: address(this), // this drago is always the recipient
                deadline: params.deadline,
                amountOut: params.amountOut,
                amountInMaximum: params.amountInMaximum
            })
        );
    }
    
    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    /// @param amountMinimum The minimum amount of WETH9 to unwrap
    /// @param recipient The address receiving ETH
    function unwrapWETH9(uint256 amountMinimum, address recipient)
        external
        payable
    {
        unwrapWETH9Internal(amountMinimum, recipient);
    }
    
    function unwrapWETH9Internal(uint256 amountMinimum, address recipient)
        internal
    {
        IPeripheryPaymentsWithFee(UNISWAP_V3_SWAP_ROUTER_ADDRESS).unwrapWETH9(
            amountMinimum,
            recipient != address(this) ? address(this) : address(this) // this drago is always the recipient
        );
    }
    
    /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    function refundETH()
        external
        payable
    {
        refundETHInternal();
    }
    
    function refundETHInternal()
        internal
    {
        IPeripheryPaymentsWithFee(UNISWAP_V3_SWAP_ROUTER_ADDRESS).refundETH();
    }
    
    /// @notice Transfers the full amount of a token held by this contract to recipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the token which will be transferred to `recipient`
    /// @param amountMinimum The minimum amount of token required for a transfer
    /// @param recipient The destination address of the token
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    )
        external
        payable
    {
        sweepTokenInternal(token, amountMinimum, recipient);
    }
    
    function sweepTokenInternal(
        address token,
        uint256 amountMinimum,
        address recipient
    )
        internal
    {
        IPeripheryPaymentsWithFee(UNISWAP_V3_SWAP_ROUTER_ADDRESS).sweepToken(
            token,
            amountMinimum,
            recipient != address(this) ? address(this) : address(this) // this drago is always the recipient
        );
    }
    
    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH, with a percentage between
    /// 0 (exclusive), and 1 (inclusive) going to feeRecipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    function unwrapWETH9WithFee(
        uint256 amountMinimum,
        address recipient,
        uint256 feeBips,
        address feeRecipient
    )
        external
        payable
    {
        unwrapWETH9WithFeeInternal(amountMinimum, recipient, feeBips, feeRecipient);
    }
    
    function unwrapWETH9WithFeeInternal(
        uint256 amountMinimum,
        address recipient,
        uint256 feeBips,
        address feeRecipient
    )
        public
        payable
    {
        IPeripheryPaymentsWithFee(UNISWAP_V3_SWAP_ROUTER_ADDRESS).unwrapWETH9WithFee(
            amountMinimum,
            recipient != address(this) ? address(this) : address(this),  // this drago is always the recipient
            feeBips,
            feeRecipient
        );
    }
    
    /// @notice Transfers the full amount of a token held by this contract to recipient, with a percentage between
    /// 0 (exclusive) and 1 (inclusive) going to feeRecipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    function sweepTokenWithFee(
        address token,
        uint256 amountMinimum,
        address recipient,
        uint256 feeBips,
        address feeRecipient
    )
        external
        payable
    {
        sweepTokenWithFeeInternal(token, amountMinimum, recipient, feeBips, feeRecipient);
    }

    function sweepTokenWithFeeInternal(
        address token,
        uint256 amountMinimum,
        address recipient,
        uint256 feeBips,
        address feeRecipient
    )
        internal
    {
        IPeripheryPaymentsWithFee(UNISWAP_V3_SWAP_ROUTER_ADDRESS).sweepTokenWithFee(
            token,
            amountMinimum,
            recipient != address(this) ? address(this) : address(this),  // this drago is always the recipient
            feeBips,
            feeRecipient
        );
    }
    
    function safeApproveInternal(
        address token,
        address spender,
        uint256 value
    )
        internal
    {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(APPROVE_SELECTOR, spender, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "RIGOBLOCK_APPROVE_FAILED"
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

/// @title Periphery Payments
/// @notice Functions to ease deposits and withdrawals of ETH
interface IPeripheryPayments {
    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    /// @param amountMinimum The minimum amount of WETH9 to unwrap
    /// @param recipient The address receiving ETH
    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;

    /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    function refundETH() external payable;

    /// @notice Transfers the full amount of a token held by this contract to recipient
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

/// @title Periphery Payments
/// @notice Functions to ease deposits and withdrawals of ETH
interface IPeripheryPaymentsWithFee is IPeripheryPayments {
    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH, with a percentage between
    /// 0 (exclusive), and 1 (inclusive) going to feeRecipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    function unwrapWETH9WithFee(
        uint256 amountMinimum,
        address recipient,
        uint256 feeBips,
        address feeRecipient
    ) external payable;

    /// @notice Transfers the full amount of a token held by this contract to recipient, with a percentage between
    /// 0 (exclusive) and 1 (inclusive) going to feeRecipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    function sweepTokenWithFee(
        address token,
        uint256 amountMinimum,
        address recipient,
        uint256 feeBips,
        address feeRecipient
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IPeripheryImmutableState {
    /// @return Returns the address of the Uniswap V3 factory
    function factory() external view returns (address);

    /// @return Returns the address of WETH9
    function WETH9() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

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

/// @title Functions for manipulating path data for multihop swaps
library Path {
    using BytesLib for bytes;

    /// @dev The length of the bytes encoded address
    uint256 private constant ADDR_SIZE = 20;
    /// @dev The length of the bytes encoded fee
    uint256 private constant FEE_SIZE = 3;

    /// @dev The offset of a single token address and pool fee
    uint256 private constant NEXT_OFFSET = ADDR_SIZE + FEE_SIZE;
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

    /// @notice Returns the number of pools in the path
    /// @param path The encoded swap path
    /// @return The number of pools in the path
    function numPools(bytes memory path) internal pure returns (uint256) {
        // Ignore the first token address. From then on every fee and token offset indicates a pool.
        return ((path.length - ADDR_SIZE) / NEXT_OFFSET);
    }

    /// @notice Decodes the first pool in path
    /// @param path The bytes encoded swap path
    /// @return tokenA The first token of the given pool
    /// @return tokenB The second token of the given pool
    /// @return fee The fee level of the pool
    function decodeFirstPool(bytes memory path)
        internal
        pure
        returns (
            address tokenA,
            address tokenB,
            uint24 fee
        )
    {
        tokenA = path.toAddress(0);
        fee = path.toUint24(ADDR_SIZE);
        tokenB = path.toAddress(NEXT_OFFSET);
    }

    /// @notice Gets the segment corresponding to the first pool in the path
    /// @param path The bytes encoded swap path
    /// @return The segment containing all data necessary to target the first pool in the path
    function getFirstPool(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(0, POP_OFFSET);
    }

    /// @notice Skips a token + fee element from the buffer and returns the remainder
    /// @param path The swap path
    /// @return The remaining token + fee elements in the path
    function skipToken(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(NEXT_OFFSET, path.length - NEXT_OFFSET);
    }
}
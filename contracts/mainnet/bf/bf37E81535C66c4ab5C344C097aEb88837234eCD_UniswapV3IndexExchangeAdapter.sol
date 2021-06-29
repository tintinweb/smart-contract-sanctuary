/*
    Copyright 2021 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import { ISwapRouter } from  "contracts/interfaces/external/ISwapRouter.sol";
import { BytesLib } from "external/contracts/uniswap/v3/lib/BytesLib.sol";

import { IIndexExchangeAdapter } from "../../../interfaces/IIndexExchangeAdapter.sol";

/**
 * @title UniswapV3IndexExchangeAdapter
 * @author Set Protocol
 *
 * A Uniswap V3 exchange adapter that returns calldata for trading with GeneralIndexModule, allows encoding a trade with a fixed input quantity or
 * a fixed output quantity.
 */
contract UniswapV3IndexExchangeAdapter is IIndexExchangeAdapter {

    using BytesLib for bytes;
    
    /* ============ Constants ============ */

    // Uniswap router function string for swapping exact amount of input tokens for a minimum of output tokens
    string internal constant SWAP_EXACT_INPUT = "exactInputSingle((address,address,uint24,address,uint256,uint256,uint256,uint160))";
    // Uniswap router function string for swapping max amoutn of input tokens for an exact amount of output tokens
    string internal constant SWAP_EXACT_OUTPUT = "exactOutputSingle((address,address,uint24,address,uint256,uint256,uint256,uint160))";
    
    /* ============ State Variables ============ */

    // Address of Uniswap V3 SwapRouter contract
    address public immutable router;

    /* ============ Constructor ============ */

    /**
     * Set state variables
     *
     * @param _router       Address of Uniswap V3 SwapRouter contract
     */
    constructor(address _router) public {
        router = _router;
    }

    /* ============ External Getter Functions ============ */

    /**
     * Return calldata for trading with Uniswap V3 SwapRouter. Trade paths are created from _sourceToken, 
     * _destinationToken and pool fees (which is encoded in _data). 
     *
     * ---------------------------------------------------------------------------------------------------------------
     *   _isSendTokenFixed   |     Parameter             |       Amount                                              |
     * ---------------------------------------------------------------------------------------------------------------
     *      True             |   _sourceQuantity         |   Fixed amount of _sourceToken to trade                   |        
     *                       |   _destinationQuantity    |   Minimum amount of _destinationToken willing to receive  |
     * ---------------------------------------------------------------------------------------------------------------
     *      False            |   _sourceQuantity         |   Maximum amount of _sourceToken to trade                 |        
     *                       |   _destinationQuantity    |   Fixed amount of _destinationToken want to receive       |
     * ---------------------------------------------------------------------------------------------------------------
     *
     * @param _sourceToken              Address of source token to be sold
     * @param _destinationToken         Address of destination token to buy
     * @param _destinationAddress       Address that assets should be transferred to
     * @param _isSendTokenFixed         Boolean indicating if the send quantity is fixed, used to determine correct trade interface
     * @param _sourceQuantity           Fixed/Max amount of source token to sell
     * @param _destinationQuantity      Min/Fixed amount of destination token to buy
     * @param _data                     Arbitrary bytes containing fees value, expressed in hundredths of a bip, 
     *                                  used to determine the pool to trade among similar asset pools on Uniswap V3.
     *                                  Note: SetToken manager must set the appropriate pool fees via `setExchangeData` in GeneralIndexModule 
     *                                  for each component that needs to be traded on UniswapV3. This is different from UniswapV3ExchangeAdapter, 
     *                                  where `_data` represents UniswapV3 trade path vs just the pool fees percentage. 
     *
     * @return address                  Target contract address
     * @return uint256                  Call value
     * @return bytes                    Trade calldata
     */
    function getTradeCalldata(
        address _sourceToken,
        address _destinationToken,
        address _destinationAddress,
        bool _isSendTokenFixed,
        uint256 _sourceQuantity,
        uint256 _destinationQuantity,
        bytes memory _data
    )
        external
        view
        override
        returns (address, uint256, bytes memory)
    {   
        uint24 fee = _data.toUint24(0);
        
        bytes memory callData = _isSendTokenFixed
            ? abi.encodeWithSignature(
                SWAP_EXACT_INPUT,
                ISwapRouter.ExactInputSingleParams(
                    _sourceToken, 
                    _destinationToken, 
                    fee, 
                    _destinationAddress, 
                    block.timestamp, 
                    _sourceQuantity, 
                    _destinationQuantity, 
                    0
                )
            ) : abi.encodeWithSignature(
                SWAP_EXACT_OUTPUT,                
                ISwapRouter.ExactOutputSingleParams(
                    _sourceToken, 
                    _destinationToken, 
                    fee, 
                    _destinationAddress,
                    block.timestamp,
                    _destinationQuantity, 
                    _sourceQuantity,
                    0
                )
            );
        
        return (router, 0, callData);
    }

    /**
     * Returns the address to approve source tokens to for trading. This is the Uniswap V3 router address.
     *
     * @return address             Address of the contract to approve tokens to
     */
    function getSpender() external view override returns (address) {
        return router;
    }

    /**
     * Helper that returns encoded fee value.
     *
     * @param fee                  UniswapV3 pool fee percentage, expressed in hundredths of a bip
     *
     * @return bytes               Encoded fee value
     */
    function getEncodedFeeData(uint24 fee) external view returns (bytes memory) {
        return abi.encodePacked(fee);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;


/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
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
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity 0.6.10;

library BytesLib {
    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_start + _length >= _start, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

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
        require(_start + 20 >= _start, "toAddress_overflow");
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_start + 3 >= _start, "toUint24_overflow");
        require(_bytes.length >= _start + 3, "toUint24_outOfBounds");
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }
}

/*
    Copyright 2021 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;

interface IIndexExchangeAdapter {
    function getSpender() external view returns(address);

    /**
     * Returns calldata for executing trade on given adapter's exchange when using the GeneralIndexModule.
     *
     * @param  _sourceToken              Address of source token to be sold
     * @param  _destinationToken         Address of destination token to buy
     * @param  _destinationAddress       Address that assets should be transferred to
     * @param  _isSendTokenFixed         Boolean indicating if the send quantity is fixed, used to determine correct trade interface
     * @param  _sourceQuantity           Fixed/Max amount of source token to sell
     * @param  _destinationQuantity      Min/Fixed amount of destination tokens to receive
     * @param  _data                     Arbitrary bytes that can be used to store exchange specific parameters or logic
     *
     * @return address                   Target contract address
     * @return uint256                   Call value
     * @return bytes                     Trade calldata
     */
    function getTradeCalldata(
        address _sourceToken,
        address _destinationToken,
        address _destinationAddress,
        bool _isSendTokenFixed,
        uint256 _sourceQuantity,
        uint256 _destinationQuantity,
        bytes memory _data
    )
        external
        view
        returns (address, uint256, bytes memory);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}
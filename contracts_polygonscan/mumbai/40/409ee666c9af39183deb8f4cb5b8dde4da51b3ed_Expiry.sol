/**
 *Submitted for verification at polygonscan.com on 2022-01-25
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

// File: contracts/protocol/interfaces/IERC20Detailed.sol

/*

    Copyright 2019 dYdX Trading Inc.

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

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;



/**
 * @title IERC20
 * @author dYdX
 *
 * Interface for using ERC20 Tokens. We have to use a special interface to call ERC20 functions so
 * that we don't automatically revert when calling non-compliant tokens that have no return value for
 * transfer(), transferFrom(), or approve().
 */
contract IERC20Detailed is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// File: contracts/protocol/lib/Token.sol

/*

    Copyright 2019 dYdX Trading Inc.

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

pragma solidity ^0.5.7;



/**
 * @title Token
 * @author dYdX
 *
 * This library contains basic functions for interacting with ERC20 tokens. Modified to work with
 * tokens that don't adhere strictly to the ERC20 standard (for example tokens that don't return a
 * boolean value on success).
 */
library Token {

    // ============ Library Functions ============

    function transfer(
        address token,
        address to,
        uint256 amount
    )
    internal
    {
        if (amount == 0 || to == address(this)) {
            return;
        }

        _callOptionalReturn(
            token,
            abi.encodeWithSelector(IERC20Detailed(token).transfer.selector, to, amount),
            "Token: transfer failed"
        );
    }

    function transferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    )
    internal
    {
        if (amount == 0 || to == from) {
            return;
        }

        // solium-disable arg-overflow
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(IERC20Detailed(token).transferFrom.selector, from, to, amount),
            "Token: transferFrom failed"
        );
        // solium-enable arg-overflow
    }

    // ============ Private Functions ============

    function _callOptionalReturn(address token, bytes memory data, string memory error) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        // 1. The target address is checked to contain contract code. Not needed since tokens are manually added
        // 2. The call itself is made, and success asserted
        // 3. The return value is decoded, which in turn checks the size of the returned data.

        // solium-disable-next-line security/no-low-level-calls
        (bool success, bytes memory returnData) = token.call(data);
        require(success, error);

        if (returnData.length > 0) {
            // Return data is optional
            require(abi.decode(returnData, (bool)), error);
        }
    }

}

// File: contracts/protocol/lib/Monetary.sol

/*

    Copyright 2019 dYdX Trading Inc.

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

pragma solidity ^0.5.7;


/**
 * @title Monetary
 * @author dYdX
 *
 * Library for types involving money
 */
library Monetary {

    /*
     * The price of a base-unit of an asset. Has `36 - token.decimals` decimals
     */
    struct Price {
        uint256 value;
    }

    /*
     * Total value of an some amount of an asset. Equal to (price * amount). Has 36 decimals.
     */
    struct Value {
        uint256 value;
    }
}

// File: contracts/protocol/interfaces/IPriceOracle.sol

/*

    Copyright 2019 dYdX Trading Inc.

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

pragma solidity ^0.5.7;



/**
 * @title IPriceOracle
 * @author dYdX
 *
 * Interface that Price Oracles for DolomiteMargin must implement in order to report prices.
 */
contract IPriceOracle {

    // ============ Constants ============

    uint256 public constant ONE_DOLLAR = 10 ** 36;

    // ============ Public Functions ============

    /**
     * Get the price of a token
     *
     * @param  token  The ERC20 token address of the market
     * @return        The USD price of a base unit of the token, then multiplied by 10^36.
     *                So a USD-stable coin with 18 decimal places would return 10^18.
     *                This is the price of the base unit rather than the price of a "human-readable"
     *                token amount. Every ERC20 may have a different number of decimals.
     */
    function getPrice(
        address token
    )
    public
    view
    returns (Monetary.Price memory);
}

// File: contracts/protocol/lib/EnumerableSet.sol

/*

    Copyright 2021 Dolomite.

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

pragma solidity ^0.5.7;


library EnumerableSet {

    struct Set {
        // Storage of set values
        uint256[] _values;
        // Value to the index in `_values` array, plus 1 because index 0 means a value is not in the set.
        mapping(uint256 => uint256) _valueToIndexMap;
    }

    /**
    * @dev Add a value to a set. O(1).
     *
     * @return true if the value was added to the set, that is if it was not already present.
     */
    function add(Set storage set, uint256 value) internal returns (bool) {
        if (!contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._valueToIndexMap[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * @return true if the value was removed from the set, that is if it was present.
     */
    function remove(Set storage set, uint256 value) internal returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._valueToIndexMap[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                uint256 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._valueToIndexMap[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored, which is the last index
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._valueToIndexMap[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Set storage set, uint256 value) internal view returns (bool) {
        return set._valueToIndexMap[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(Set storage set) internal view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Set storage set) internal view returns (uint256[] memory) {
        return set._values;
    }

}

// File: contracts/protocol/lib/Require.sol

/*

    Copyright 2019 dYdX Trading Inc.

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

pragma solidity ^0.5.7;


/**
 * @title Require
 * @author dYdX
 *
 * Stringifies parameters to pretty-print revert messages. Costs more gas than regular require()
 */
library Require {

    // ============ Constants ============

    uint256 constant ASCII_ZERO = 48; // '0'
    uint256 constant ASCII_RELATIVE_ZERO = 87; // 'a' - 10
    uint256 constant ASCII_LOWER_EX = 120; // 'x'
    bytes2 constant COLON = 0x3a20; // ': '
    bytes2 constant COMMA = 0x2c20; // ', '
    bytes2 constant LPAREN = 0x203c; // ' <'
    byte constant RPAREN = 0x3e; // '>'
    uint256 constant FOUR_BIT_MASK = 0xf;

    // ============ Library Functions ============

    function that(
        bool must,
        bytes32 file,
        bytes32 reason
    )
    internal
    pure
    {
        if (!must) {
            revert(
            string(
                abi.encodePacked(
                    stringifyTruncated(file),
                    COLON,
                    stringifyTruncated(reason)
                )
            )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        uint256 payloadA
    )
    internal
    pure
    {
        if (!must) {
            revert(
            string(
                abi.encodePacked(
                    stringifyTruncated(file),
                    COLON,
                    stringifyTruncated(reason),
                    LPAREN,
                    stringify(payloadA),
                    RPAREN
                )
            )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        uint256 payloadA,
        uint256 payloadB
    )
    internal
    pure
    {
        if (!must) {
            revert(
            string(
                abi.encodePacked(
                    stringifyTruncated(file),
                    COLON,
                    stringifyTruncated(reason),
                    LPAREN,
                    stringify(payloadA),
                    COMMA,
                    stringify(payloadB),
                    RPAREN
                )
            )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        address payloadA
    )
    internal
    pure
    {
        if (!must) {
            revert(
            string(
                abi.encodePacked(
                    stringifyTruncated(file),
                    COLON,
                    stringifyTruncated(reason),
                    LPAREN,
                    stringify(payloadA),
                    RPAREN
                )
            )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        address payloadA,
        uint256 payloadB
    )
    internal
    pure
    {
        if (!must) {
            revert(
            string(
                abi.encodePacked(
                    stringifyTruncated(file),
                    COLON,
                    stringifyTruncated(reason),
                    LPAREN,
                    stringify(payloadA),
                    COMMA,
                    stringify(payloadB),
                    RPAREN
                )
            )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        address payloadA,
        uint256 payloadB,
        uint256 payloadC
    )
    internal
    pure
    {
        if (!must) {
            revert(
            string(
                abi.encodePacked(
                    stringifyTruncated(file),
                    COLON,
                    stringifyTruncated(reason),
                    LPAREN,
                    stringify(payloadA),
                    COMMA,
                    stringify(payloadB),
                    COMMA,
                    stringify(payloadC),
                    RPAREN
                )
            )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        bytes32 payloadA
    )
    internal
    pure
    {
        if (!must) {
            revert(
            string(
                abi.encodePacked(
                    stringifyTruncated(file),
                    COLON,
                    stringifyTruncated(reason),
                    LPAREN,
                    stringify(payloadA),
                    RPAREN
                )
            )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        bytes32 payloadA,
        uint256 payloadB,
        uint256 payloadC
    )
    internal
    pure
    {
        if (!must) {
            revert(
            string(
                abi.encodePacked(
                    stringifyTruncated(file),
                    COLON,
                    stringifyTruncated(reason),
                    LPAREN,
                    stringify(payloadA),
                    COMMA,
                    stringify(payloadB),
                    COMMA,
                    stringify(payloadC),
                    RPAREN
                )
            )
            );
        }
    }

    // ============ Private Functions ============

    function stringifyTruncated(
        bytes32 input
    )
    private
    pure
    returns (bytes memory)
    {
        // put the input bytes into the result
        bytes memory result = abi.encodePacked(input);

        // determine the length of the input by finding the location of the last non-zero byte
        for (uint256 i = 32; i > 0; ) {
            // reverse-for-loops with unsigned integer
            /* solium-disable-next-line security/no-modify-for-iter-var */
            i--;

            // find the last non-zero byte in order to determine the length
            if (result[i] != 0) {
                uint256 length = i + 1;

                /* solium-disable-next-line security/no-inline-assembly */
                assembly {
                    mstore(result, length) // r.length = length;
                }

                return result;
            }
        }

        // all bytes are zero
        return new bytes(0);
    }

    function stringify(
        uint256 input
    )
    private
    pure
    returns (bytes memory)
    {
        if (input == 0) {
            return "0";
        }

        // get the final string length
        uint256 j = input;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }

        // allocate the string
        bytes memory bstr = new bytes(length);

        // populate the string starting with the least-significant character
        j = input;
        for (uint256 i = length; i > 0; ) {
            // reverse-for-loops with unsigned integer
            /* solium-disable-next-line security/no-modify-for-iter-var */
            i--;

            // take last decimal digit
            bstr[i] = byte(uint8(ASCII_ZERO + (j % 10)));

            // remove the last decimal digit
            j /= 10;
        }

        return bstr;
    }

    function stringify(
        address input
    )
    private
    pure
    returns (bytes memory)
    {
        uint256 z = uint256(input);

        // addresses are "0x" followed by 20 bytes of data which take up 2 characters each
        bytes memory result = new bytes(42);

        // populate the result with "0x"
        result[0] = byte(uint8(ASCII_ZERO));
        result[1] = byte(uint8(ASCII_LOWER_EX));

        // for each byte (starting from the lowest byte), populate the result with two characters
        for (uint256 i = 0; i < 20; i++) {
            // each byte takes two characters
            uint256 shift = i * 2;

            // populate the least-significant character
            result[41 - shift] = char(z & FOUR_BIT_MASK);
            z = z >> 4;

            // populate the most-significant character
            result[40 - shift] = char(z & FOUR_BIT_MASK);
            z = z >> 4;
        }

        return result;
    }

    function stringify(
        bytes32 input
    )
    private
    pure
    returns (bytes memory)
    {
        uint256 z = uint256(input);

        // bytes32 are "0x" followed by 32 bytes of data which take up 2 characters each
        bytes memory result = new bytes(66);

        // populate the result with "0x"
        result[0] = byte(uint8(ASCII_ZERO));
        result[1] = byte(uint8(ASCII_LOWER_EX));

        // for each byte (starting from the lowest byte), populate the result with two characters
        for (uint256 i = 0; i < 32; i++) {
            // each byte takes two characters
            uint256 shift = i * 2;

            // populate the least-significant character
            result[65 - shift] = char(z & FOUR_BIT_MASK);
            z = z >> 4;

            // populate the most-significant character
            result[64 - shift] = char(z & FOUR_BIT_MASK);
            z = z >> 4;
        }

        return result;
    }

    function char(
        uint256 input
    )
    private
    pure
    returns (byte)
    {
        // return ASCII digit (0-9)
        if (input < 10) {
            return byte(uint8(input + ASCII_ZERO));
        }

        // return ASCII letter (a-f)
        return byte(uint8(input + ASCII_RELATIVE_ZERO));
    }
}

// File: contracts/protocol/lib/Bits.sol

/*

    Copyright 2019 dYdX Trading Inc.

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

pragma solidity ^0.5.7;



/**
 * @title Bits
 * @author Dolomite
 *
 * Library for caching information about markets
 */
library Bits {

    // ============ Constants ============

    uint internal constant ONE = 1;
    uint256 internal constant MAX_UINT_BITS = 256;

    // ============ Functions ============

    function createBitmaps(uint maxLength) internal pure returns (uint[] memory) {
        return new uint[]((maxLength / MAX_UINT_BITS) + ONE);
    }

    function getMarketIdFromBit(
        uint index,
        uint bit
    ) internal pure returns (uint) {
        return (MAX_UINT_BITS * index) + bit;
    }

    function setBit(
        uint[] memory bitmaps,
        uint marketId
    ) internal pure {
        uint bucketIndex = marketId / MAX_UINT_BITS;
        uint indexFromRight = marketId % MAX_UINT_BITS;
        bitmaps[bucketIndex] |= (ONE << indexFromRight);
    }

    function hasBit(
        uint[] memory bitmaps,
        uint marketId
    ) internal pure returns (bool) {
        uint bucketIndex = marketId / MAX_UINT_BITS;
        uint indexFromRight = marketId % MAX_UINT_BITS;
        uint bit = bitmaps[bucketIndex] & (ONE << indexFromRight);
        return bit > 0;
    }

    function unsetBit(
        uint bitmap,
        uint bit
    ) internal pure returns (uint) {
        return bitmap - (ONE << bit);
    }

    // solium-disable security/no-assign-params
    function getLeastSignificantBit(uint256 x) internal pure returns (uint) {
        // gas usage peaks at 350 per call

        uint lsb = 255;

        if (x & uint128(-1) > 0) {
            lsb -= 128;
        } else {
            x >>= 128;
        }

        if (x & uint64(-1) > 0) {
            lsb -= 64;
        } else {
            x >>= 64;
        }

        if (x & uint32(-1) > 0) {
            lsb -= 32;
        } else {
            x >>= 32;
        }

        if (x & uint16(-1) > 0) {
            lsb -= 16;
        } else {
            x >>= 16;
        }

        if (x & uint8(-1) > 0) {
            lsb -= 8;
        } else {
            x >>= 8;
        }

        if (x & 0xf > 0) {
            lsb -= 4;
        } else {
            x >>= 4;
        }

        if (x & 0x3 > 0) {
            lsb -= 2;
        } else {
            x >>= 2;
            // solium-enable security/no-assign-params
        }

        if (x & 0x1 > 0) {
            lsb -= 1;
        }

        return lsb;
    }
}

// File: contracts/protocol/lib/Cache.sol

/*

    Copyright 2019 dYdX Trading Inc.

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

pragma solidity ^0.5.7;





/**
 * @title Cache
 * @author dYdX
 *
 * Library for caching information about markets
 */
library Cache {

    // ============ Constants ============

    bytes32 internal constant FILE = "Cache";

    // ============ Structs ============

    struct MarketInfo {
        uint marketId;
        address token;
        bool isClosing;
        uint128 borrowPar;
        Monetary.Price price;
    }

    struct MarketCache {
        MarketInfo[] markets;
        uint256[] marketBitmaps;
        uint256 marketsLength;
    }

    // ============ Setter Functions ============

    /**
     * Initialize an empty cache for some given number of total markets.
     */
    function create(
        uint256 numMarkets
    )
    internal
    pure
    returns (MarketCache memory)
    {
        return MarketCache({
        markets: new MarketInfo[](0),
        marketBitmaps: Bits.createBitmaps(numMarkets),
        marketsLength: 0
        });
    }

    // ============ Getter Functions ============

    function getNumMarkets(
        MarketCache memory cache
    )
    internal
    pure
    returns (uint256)
    {
        return cache.markets.length;
    }

    function hasMarket(
        MarketCache memory cache,
        uint256 marketId
    )
    internal
    pure
    returns (bool)
    {
        return Bits.hasBit(cache.marketBitmaps, marketId);
    }

    function get(
        MarketCache memory cache,
        uint256 marketId
    )
    internal
    pure
    returns (MarketInfo memory)
    {
        Require.that(
            cache.markets.length > 0,
            FILE,
            "not initialized"
        );
        return _getInternal(
            cache.markets,
            0,
            cache.marketsLength,
            marketId
        );
    }

    function set(
        MarketCache memory cache,
        uint256 marketId
    )
    internal
    pure
    {
        // Devs should not be able to call this function once the `markets` array has been initialized (non-zero length)
        Require.that(
            cache.markets.length == 0,
            FILE,
            "already initialized"
        );

        Bits.setBit(cache.marketBitmaps, marketId);

        cache.marketsLength += 1;
    }

    function getAtIndex(
        MarketCache memory cache,
        uint256 index
    )
    internal
    pure
    returns (MarketInfo memory)
    {
        Require.that(
            index < cache.markets.length,
            FILE,
            "invalid index",
            index,
            cache.markets.length
        );
        return cache.markets[index];
    }

    // ============ Private Functions ============

    function _getInternal(
        MarketInfo[] memory data,
        uint beginInclusive,
        uint endExclusive,
        uint marketId
    ) private pure returns (MarketInfo memory) {
        uint len = endExclusive - beginInclusive;
        if (len == 0 || (len == 1 && data[beginInclusive].marketId != marketId)) {
            revert("Cache: item not found");
        }

        uint mid = beginInclusive + len / 2;
        uint midMarketId = data[mid].marketId;
        if (marketId < midMarketId) {
            return _getInternal(
                data,
                beginInclusive,
                mid,
                marketId
            );
        } else if (marketId > midMarketId) {
            return _getInternal(
                data,
                mid + 1,
                endExclusive,
                marketId
            );
        } else {
            return data[mid];
        }
    }

}

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following 
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/protocol/lib/Math.sol

/*

    Copyright 2019 dYdX Trading Inc.

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

pragma solidity ^0.5.7;




/**
 * @title Math
 * @author dYdX
 *
 * Library for non-standard Math functions
 */
library Math {
    using SafeMath for uint256;

    // ============ Constants ============

    bytes32 constant FILE = "Math";

    // ============ Library Functions ============

    /*
     * Return target * (numerator / denominator).
     */
    function getPartial(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    )
    internal
    pure
    returns (uint256)
    {
        return target.mul(numerator).div(denominator);
    }

    /*
     * Return target * (numerator / denominator), but rounded up.
     */
    function getPartialRoundUp(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    )
    internal
    pure
    returns (uint256)
    {
        if (target == 0 || numerator == 0) {
            // SafeMath will check for zero denominator
            return SafeMath.div(0, denominator);
        }
        return target.mul(numerator).sub(1).div(denominator).add(1);
    }

    function getPartialRoundHalfUp(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    )
    internal
    pure
    returns (uint256)
    {
        if (target == 0 || numerator == 0) {
            // SafeMath will check for zero denominator
            return SafeMath.div(0, denominator);
        }
        uint result = target.mul(numerator);
        // round the denominator comparator up to ensure a fair comparison is done on the `result`'s modulo.
        // For example, 51 / 103 == 0; 51 % 103 == 51; ((103 - 1) / 2) + 1 == 52; 51 < 52, therefore no round up
        return result.div(denominator).add(result.mod(denominator) >= denominator.sub(1).div(2).add(1) ? 1 : 0);
    }

    function to128(
        uint256 number
    )
    internal
    pure
    returns (uint128)
    {
        uint128 result = uint128(number);
        Require.that(
            result == number,
            FILE,
            "Unsafe cast to uint128",
            number
        );
        return result;
    }

    function to96(
        uint256 number
    )
    internal
    pure
    returns (uint96)
    {
        uint96 result = uint96(number);
        Require.that(
            result == number,
            FILE,
            "Unsafe cast to uint96",
            number
        );
        return result;
    }

    function to32(
        uint256 number
    )
    internal
    pure
    returns (uint32)
    {
        uint32 result = uint32(number);
        Require.that(
            result == number,
            FILE,
            "Unsafe cast to uint32",
            number
        );
        return result;
    }

    function min(
        uint256 a,
        uint256 b
    )
    internal
    pure
    returns (uint256)
    {
        return a < b ? a : b;
    }

    function max(
        uint256 a,
        uint256 b
    )
    internal
    pure
    returns (uint256)
    {
        return a > b ? a : b;
    }
}

// File: contracts/protocol/lib/Time.sol

/*

    Copyright 2019 dYdX Trading Inc.

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

pragma solidity ^0.5.7;



/**
 * @title Time
 * @author dYdX
 *
 * Library for dealing with time, assuming timestamps fit within 32 bits (valid until year 2106)
 */
library Time {

    // ============ Library Functions ============

    function currentTime()
    internal
    view
    returns (uint32)
    {
        return Math.to32(block.timestamp);
    }
}

// File: contracts/protocol/lib/Decimal.sol

/*

    Copyright 2019 dYdX Trading Inc.

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

pragma solidity ^0.5.7;




/**
 * @title Decimal
 * @author dYdX
 *
 * Library that defines a fixed-point number with 18 decimal places.
 */
library Decimal {
    using SafeMath for uint256;

    // ============ Constants ============

    uint256 constant BASE = 10**18;

    // ============ Structs ============

    struct D256 {
        uint256 value;
    }

    // ============ Functions ============

    function one()
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: BASE });
    }

    function onePlus(
        D256 memory d
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: d.value.add(BASE) });
    }

    function mul(
        uint256 target,
        D256 memory d
    )
    internal
    pure
    returns (uint256)
    {
        return Math.getPartial(target, d.value, BASE);
    }

    function div(
        uint256 target,
        D256 memory d
    )
    internal
    pure
    returns (uint256)
    {
        return Math.getPartial(target, BASE, d.value);
    }
}

// File: contracts/protocol/lib/Types.sol

/*

    Copyright 2019 dYdX Trading Inc.

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

pragma solidity ^0.5.7;




/**
 * @title Types
 * @author dYdX
 *
 * Library for interacting with the basic structs used in DolomiteMargin
 */
library Types {
    using Math for uint256;

    // ============ Permission ============

    struct OperatorArg {
        address operator;
        bool trusted;
    }

    // ============ AssetAmount ============

    enum AssetDenomination {
        Wei, // the amount is denominated in wei
        Par  // the amount is denominated in par
    }

    enum AssetReference {
        Delta, // the amount is given as a delta from the current value
        Target // the amount is given as an exact number to end up at
    }

    struct AssetAmount {
        bool sign; // true if positive
        AssetDenomination denomination;
        AssetReference ref;
        uint256 value;
    }

    // ============ Par (Principal Amount) ============

    // Total borrow and supply values for a market
    struct TotalPar {
        uint128 borrow;
        uint128 supply;
    }

    // Individual principal amount for an account
    struct Par {
        bool sign; // true if positive
        uint128 value;
    }

    function zeroPar()
    internal
    pure
    returns (Par memory)
    {
        return Par({
        sign: false,
        value: 0
        });
    }

    function sub(
        Par memory a,
        Par memory b
    )
    internal
    pure
    returns (Par memory)
    {
        return add(a, negative(b));
    }

    function add(
        Par memory a,
        Par memory b
    )
    internal
    pure
    returns (Par memory)
    {
        Par memory result;
        if (a.sign == b.sign) {
            result.sign = a.sign;
            result.value = SafeMath.add(a.value, b.value).to128();
        } else {
            if (a.value >= b.value) {
                result.sign = a.sign;
                result.value = SafeMath.sub(a.value, b.value).to128();
            } else {
                result.sign = b.sign;
                result.value = SafeMath.sub(b.value, a.value).to128();
            }
        }
        return result;
    }

    function equals(
        Par memory a,
        Par memory b
    )
    internal
    pure
    returns (bool)
    {
        if (a.value == b.value) {
            if (a.value == 0) {
                return true;
            }
            return a.sign == b.sign;
        }
        return false;
    }

    function negative(
        Par memory a
    )
    internal
    pure
    returns (Par memory)
    {
        return Par({
        sign: !a.sign,
        value: a.value
        });
    }

    function isNegative(
        Par memory a
    )
    internal
    pure
    returns (bool)
    {
        return !a.sign && a.value > 0;
    }

    function isPositive(
        Par memory a
    )
    internal
    pure
    returns (bool)
    {
        return a.sign && a.value > 0;
    }

    function isZero(
        Par memory a
    )
    internal
    pure
    returns (bool)
    {
        return a.value == 0;
    }

    function isLessThanZero(
        Par memory a
    )
    internal
    pure
    returns (bool)
    {
        return a.value > 0 && !a.sign;
    }

    function isGreaterThanOrEqualToZero(
        Par memory a
    )
    internal
    pure
    returns (bool)
    {
        return isZero(a) || a.sign;
    }

    // ============ Wei (Token Amount) ============

    // Individual token amount for an account
    struct Wei {
        bool sign; // true if positive
        uint256 value;
    }

    function zeroWei()
    internal
    pure
    returns (Wei memory)
    {
        return Wei({
        sign: false,
        value: 0
        });
    }

    function sub(
        Wei memory a,
        Wei memory b
    )
    internal
    pure
    returns (Wei memory)
    {
        return add(a, negative(b));
    }

    function add(
        Wei memory a,
        Wei memory b
    )
    internal
    pure
    returns (Wei memory)
    {
        Wei memory result;
        if (a.sign == b.sign) {
            result.sign = a.sign;
            result.value = SafeMath.add(a.value, b.value);
        } else {
            if (a.value >= b.value) {
                result.sign = a.sign;
                result.value = SafeMath.sub(a.value, b.value);
            } else {
                result.sign = b.sign;
                result.value = SafeMath.sub(b.value, a.value);
            }
        }
        return result;
    }

    function equals(
        Wei memory a,
        Wei memory b
    )
    internal
    pure
    returns (bool)
    {
        if (a.value == b.value) {
            if (a.value == 0) {
                return true;
            }
            return a.sign == b.sign;
        }
        return false;
    }

    function negative(
        Wei memory a
    )
    internal
    pure
    returns (Wei memory)
    {
        return Wei({
        sign: !a.sign,
        value: a.value
        });
    }

    function isNegative(
        Wei memory a
    )
    internal
    pure
    returns (bool)
    {
        return !a.sign && a.value > 0;
    }

    function isPositive(
        Wei memory a
    )
    internal
    pure
    returns (bool)
    {
        return a.sign && a.value > 0;
    }

    function isZero(
        Wei memory a
    )
    internal
    pure
    returns (bool)
    {
        return a.value == 0;
    }
}

// File: contracts/protocol/interfaces/ILiquidationCallback.sol

/*

    Copyright 2021 Dolomite.

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

pragma solidity >=0.5.0;


interface ILiquidationCallback {

    /**
     * A callback function to notify the smart contract that it is being liquidated. This function is called before the
     * new balances are set in state, so calling `getAccountPar/Wei` will return this liquidated account's balance
     * before `heldDeltaWei` or `owedDeltaWei` are applied.
     *
     * @param accountNumber The account number being liquidated
     * @param heldMarketId  The market that was positive for this account, whose collateral is being seized
     * @param heldDeltaWei  The amount of seized collateral; always negative or 0
     * @param owedMarketId  The borrowed balance that is being forcefully repaid
     * @param owedDeltaWei  The amount of borrowed assets to be repaid. Always 0 or positive, since the user's balance
     *                      is going from negative to 0.
     */
    function onLiquidate(
        uint accountNumber,
        uint heldMarketId,
        Types.Wei calldata heldDeltaWei,
        uint owedMarketId,
        Types.Wei calldata owedDeltaWei
    ) external;
}

// File: contracts/protocol/lib/Interest.sol

/*

    Copyright 2019 dYdX Trading Inc.

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

pragma solidity ^0.5.7;







/**
 * @title Interest
 * @author dYdX
 *
 * Library for managing the interest rate and interest indexes of DolomiteMargin
 */
library Interest {
    using Math for uint256;
    using SafeMath for uint256;

    // ============ Constants ============

    bytes32 constant FILE = "Interest";
    uint64 constant BASE = 10**18;

    // ============ Structs ============

    struct Rate {
        uint256 value;
    }

    struct Index {
        uint96 borrow;
        uint96 supply;
        uint32 lastUpdate;
    }

    // ============ Library Functions ============

    /**
     * Get a new market Index based on the old index and market interest rate.
     * Calculate interest for borrowers by using the formula rate * time. Approximates
     * continuously-compounded interest when called frequently, but is much more
     * gas-efficient to calculate. For suppliers, the interest rate is adjusted by the earningsRate,
     * then prorated across all suppliers.
     *
     * @param  index         The old index for a market
     * @param  rate          The current interest rate of the market
     * @param  totalPar      The total supply and borrow par values of the market
     * @param  earningsRate  The portion of the interest that is forwarded to the suppliers
     * @return               The updated index for a market
     */
    function calculateNewIndex(
        Index memory index,
        Rate memory rate,
        Types.TotalPar memory totalPar,
        Decimal.D256 memory earningsRate
    )
    internal
    view
    returns (Index memory)
    {
        (
        Types.Wei memory supplyWei,
        Types.Wei memory borrowWei
        ) = totalParToWei(totalPar, index);

        // get interest increase for borrowers
        uint32 currentTime = Time.currentTime();
        uint256 borrowInterest = rate.value.mul(uint256(currentTime).sub(index.lastUpdate));

        // get interest increase for suppliers
        uint256 supplyInterest;
        if (Types.isZero(supplyWei)) {
            supplyInterest = 0;
        } else {
            supplyInterest = Decimal.mul(borrowInterest, earningsRate);
            if (borrowWei.value < supplyWei.value) {
                supplyInterest = Math.getPartial(supplyInterest, borrowWei.value, supplyWei.value);
            }
        }
        assert(supplyInterest <= borrowInterest);

        return Index({
        borrow: Math.getPartial(index.borrow, borrowInterest, BASE).add(index.borrow).to96(),
        supply: Math.getPartial(index.supply, supplyInterest, BASE).add(index.supply).to96(),
        lastUpdate: currentTime
        });
    }

    function newIndex()
    internal
    view
    returns (Index memory)
    {
        return Index({
        borrow: BASE,
        supply: BASE,
        lastUpdate: Time.currentTime()
        });
    }

    /*
     * Convert a principal amount to a token amount given an index.
     */
    function parToWei(
        Types.Par memory input,
        Index memory index
    )
    internal
    pure
    returns (Types.Wei memory)
    {
        uint256 inputValue = uint256(input.value);
        if (input.sign) {
            return Types.Wei({
            sign: true,
            value: inputValue.getPartialRoundHalfUp(index.supply, BASE)
            });
        } else {
            return Types.Wei({
            sign: false,
            value: inputValue.getPartialRoundUp(index.borrow, BASE)
            });
        }
    }

    /*
     * Convert a token amount to a principal amount given an index.
     */
    function weiToPar(
        Types.Wei memory input,
        Index memory index
    )
    internal
    pure
    returns (Types.Par memory)
    {
        if (input.sign) {
            return Types.Par({
            sign: true,
            value: input.value.getPartialRoundHalfUp(BASE, index.supply).to128()
            });
        } else {
            return Types.Par({
            sign: false,
            value: input.value.getPartialRoundUp(BASE, index.borrow).to128()
            });
        }
    }

    /*
     * Convert the total supply and borrow principal amounts of a market to total supply and borrow
     * token amounts.
     */
    function totalParToWei(
        Types.TotalPar memory totalPar,
        Index memory index
    )
    internal
    pure
    returns (Types.Wei memory, Types.Wei memory)
    {
        Types.Par memory supplyPar = Types.Par({
        sign: true,
        value: totalPar.supply
        });
        Types.Par memory borrowPar = Types.Par({
        sign: false,
        value: totalPar.borrow
        });
        Types.Wei memory supplyWei = parToWei(supplyPar, index);
        Types.Wei memory borrowWei = parToWei(borrowPar, index);
        return (supplyWei, borrowWei);
    }
}

// File: contracts/protocol/interfaces/IInterestSetter.sol

/*

    Copyright 2019 dYdX Trading Inc.

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

pragma solidity ^0.5.7;



/**
 * @title IInterestSetter
 * @author dYdX
 *
 * Interface that Interest Setters for DolomiteMargin must implement in order to report interest rates.
 */
interface IInterestSetter {

    // ============ Public Functions ============

    /**
     * Get the interest rate of a token given some borrowed and supplied amounts
     *
     * @param  token        The address of the ERC20 token for the market
     * @param  borrowWei    The total borrowed token amount for the market
     * @param  supplyWei    The total supplied token amount for the market
     * @return              The interest rate per second
     */
    function getInterestRate(
        address token,
        uint256 borrowWei,
        uint256 supplyWei
    )
    external
    view
    returns (Interest.Rate memory);
}

// File: contracts/protocol/lib/Account.sol

/*

    Copyright 2019 dYdX Trading Inc.

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

pragma solidity ^0.5.7;




/**
 * @title Account
 * @author dYdX
 *
 * Library of structs and functions that represent an account
 */
library Account {
    // ============ Enums ============

    /*
     * Most-recently-cached account status.
     *
     * Normal: Can only be liquidated if the account values are violating the global margin-ratio.
     * Liquid: Can be liquidated no matter the account values.
     *         Can be vaporized if there are no more positive account values.
     * Vapor:  Has only negative (or zeroed) account values. Can be vaporized.
     *
     */
    enum Status {
        Normal,
        Liquid,
        Vapor
    }

    // ============ Structs ============

    // Represents the unique key that specifies an account
    struct Info {
        address owner;  // The address that owns the account
        uint256 number; // A nonce that allows a single address to control many accounts
    }

    // The complete storage for any account
    struct Storage {
        Status status;
        uint32 numberOfMarketsWithBorrow;
        EnumerableSet.Set marketsWithNonZeroBalanceSet;
        mapping (uint256 => Types.Par) balances; // Mapping from marketId to principal
    }

    // ============ Library Functions ============

    function equals(
        Info memory a,
        Info memory b
    )
    internal
    pure
    returns (bool)
    {
        return a.owner == b.owner && a.number == b.number;
    }
}

// File: contracts/external/interfaces/IExpiry.sol

/*

    Copyright 2021 Dolomite.

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

pragma solidity ^0.5.7;




/**
 * @title IExpiry
 * @author Dolomite
 */
contract IExpiry {

    // ============ Enums ============

    enum CallFunctionType {
        SetExpiry,
        SetApproval
    }

    // ============ Structs ============

    struct SetExpiryArg {
        Account.Info account;
        uint256 marketId;
        uint32 timeDelta;
        bool forceUpdate;
    }

    struct SetApprovalArg {
        address sender;
        uint32 minTimeDelta;
    }

    function getSpreadAdjustedPrices(
        uint256 heldMarketId,
        uint256 owedMarketId,
        uint32 expiry
    )
    public
    view
    returns (Monetary.Price memory heldPrice, Monetary.Price memory owedPriceAdj);

}

// File: contracts/protocol/lib/Storage.sol

/*

    Copyright 2019 dYdX Trading Inc.

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

pragma solidity ^0.5.7;


















/**
 * @title Storage
 * @author dYdX
 *
 * Functions for reading, writing, and verifying state in DolomiteMargin
 */
library Storage {
    using Cache for Cache.MarketCache;
    using Storage for Storage.State;
    using Math for uint256;
    using Types for Types.Par;
    using Types for Types.Wei;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.Set;

    // ============ Constants ============

    bytes32 internal constant FILE = "Storage";

    // ============ Structs ============

    // All information necessary for tracking a market
    struct Market {
        // Contract address of the associated ERC20 token
        address token;

        // Whether additional borrows are allowed for this market
        bool isClosing;

        // Whether this market can be removed and its ID can be recycled and reused
        bool isRecyclable;

        // Total aggregated supply and borrow amount of the entire market
        Types.TotalPar totalPar;

        // Interest index of the market
        Interest.Index index;

        // Contract address of the price oracle for this market
        IPriceOracle priceOracle;

        // Contract address of the interest setter for this market
        IInterestSetter interestSetter;

        // Multiplier on the marginRatio for this market, IE 5% (0.05 * 1e18). This number increases the market's
        // required collateralization by: reducing the user's supplied value (in terms of dollars) for this market and
        // increasing its borrowed value. This is done through the following operation:
        // `suppliedWei = suppliedWei + (assetValueForThisMarket / (1 + marginPremium))`
        // This number increases the user's borrowed wei by multiplying it by:
        // `borrowedWei = borrowedWei + (assetValueForThisMarket * (1 + marginPremium))`
        Decimal.D256 marginPremium;

        // Multiplier on the liquidationSpread for this market, IE 20% (0.2 * 1e18). This number increases the
        // `liquidationSpread` using the following formula:
        // `liquidationSpread = liquidationSpread * (1 + spreadPremium)`
        // NOTE: This formula is applied up to two times - one for each market whose spreadPremium is greater than 0
        // (when performing a liquidation between two markets)
        Decimal.D256 spreadPremium;
    }

    // The global risk parameters that govern the health and security of the system
    struct RiskParams {
        // Required ratio of over-collateralization
        Decimal.D256 marginRatio;

        // Percentage penalty incurred by liquidated accounts
        Decimal.D256 liquidationSpread;

        // Percentage of the borrower's interest fee that gets passed to the suppliers
        Decimal.D256 earningsRate;

        // The minimum absolute borrow value of an account
        // There must be sufficient incentivize to liquidate undercollateralized accounts
        Monetary.Value minBorrowedValue;
    }

    // The maximum RiskParam values that can be set
    struct RiskLimits {
        // The highest that the ratio can be for liquidating under-water accounts
        uint64 marginRatioMax;
        // The highest that the liquidation rewards can be when a liquidator liquidates an account
        uint64 liquidationSpreadMax;
        // The highest that the supply APR can be for a market, as a proportion of the borrow rate. Meaning, a rate of
        // 100% (1e18) would give suppliers all of the interest that borrowers are paying. A rate of 90% would give
        // suppliers 90% of the interest that borrowers pay.
        uint64 earningsRateMax;
        uint64 marginPremiumMax;
        uint64 spreadPremiumMax;
        uint128 minBorrowedValueMax;
    }

    // The entire storage state of DolomiteMargin
    struct State {
        // number of markets
        uint256 numMarkets;

        // marketId => Market
        mapping (uint256 => Market) markets;
        mapping (address => uint256) tokenToMarketId;
        mapping(uint256 => uint256) recycledMarketIds;

        // owner => account number => Account
        mapping (address => mapping (uint256 => Account.Storage)) accounts;

        // Addresses that can control other users accounts
        mapping (address => mapping (address => bool)) operators;

        // Addresses that can control all users accounts
        mapping (address => bool) globalOperators;

        // mutable risk parameters of the system
        RiskParams riskParams;

        // immutable risk limits of the system
        RiskLimits riskLimits;
    }

    // ============ Functions ============

    function getToken(
        Storage.State storage state,
        uint256 marketId
    )
    internal
    view
    returns (address)
    {
        return state.markets[marketId].token;
    }

    function getTotalPar(
        Storage.State storage state,
        uint256 marketId
    )
    internal
    view
    returns (Types.TotalPar memory)
    {
        return state.markets[marketId].totalPar;
    }

    function getIndex(
        Storage.State storage state,
        uint256 marketId
    )
    internal
    view
    returns (Interest.Index memory)
    {
        return state.markets[marketId].index;
    }

    function getNumExcessTokens(
        Storage.State storage state,
        uint256 marketId
    )
    internal
    view
    returns (Types.Wei memory)
    {
        Interest.Index memory index = state.getIndex(marketId);
        Types.TotalPar memory totalPar = state.getTotalPar(marketId);

        address token = state.getToken(marketId);

        Types.Wei memory balanceWei = Types.Wei({
        sign: true,
        value: IERC20Detailed(token).balanceOf(address(this))
        });

        (
        Types.Wei memory supplyWei,
        Types.Wei memory borrowWei
        ) = Interest.totalParToWei(totalPar, index);

        // borrowWei is negative, so subtracting it makes the value more positive
        return balanceWei.sub(borrowWei).sub(supplyWei);
    }

    function getStatus(
        Storage.State storage state,
        Account.Info memory account
    )
    internal
    view
    returns (Account.Status)
    {
        return state.accounts[account.owner][account.number].status;
    }

    function getPar(
        Storage.State storage state,
        Account.Info memory account,
        uint256 marketId
    )
    internal
    view
    returns (Types.Par memory)
    {
        return state.accounts[account.owner][account.number].balances[marketId];
    }

    function getWei(
        Storage.State storage state,
        Account.Info memory account,
        uint256 marketId
    )
    internal
    view
    returns (Types.Wei memory)
    {
        Types.Par memory par = state.getPar(account, marketId);

        if (par.isZero()) {
            return Types.zeroWei();
        }

        Interest.Index memory index = state.getIndex(marketId);
        return Interest.parToWei(par, index);
    }

    function getMarketsWithBalancesSet(
        Storage.State storage state,
        Account.Info memory account
    )
    internal
    view
    returns (EnumerableSet.Set storage)
    {
        return state.accounts[account.owner][account.number].marketsWithNonZeroBalanceSet;
    }

    function getMarketsWithBalances(
        Storage.State storage state,
        Account.Info memory account
    )
    internal
    view
    returns (uint256[] memory)
    {
        return state.accounts[account.owner][account.number].marketsWithNonZeroBalanceSet.values();
    }

    function getNumberOfMarketsWithBorrow(
        Storage.State storage state,
        Account.Info memory account
    )
    internal
    view
    returns (uint256)
    {
        return state.accounts[account.owner][account.number].numberOfMarketsWithBorrow;
    }

    function getLiquidationSpreadForPair(
        Storage.State storage state,
        uint256 heldMarketId,
        uint256 owedMarketId
    )
    internal
    view
    returns (Decimal.D256 memory)
    {
        uint256 result = state.riskParams.liquidationSpread.value;
        result = Decimal.mul(result, Decimal.onePlus(state.markets[heldMarketId].spreadPremium));
        result = Decimal.mul(result, Decimal.onePlus(state.markets[owedMarketId].spreadPremium));
        return Decimal.D256({
        value: result
        });
    }

    function fetchNewIndex(
        Storage.State storage state,
        uint256 marketId,
        Interest.Index memory index
    )
    internal
    view
    returns (Interest.Index memory)
    {
        Interest.Rate memory rate = state.fetchInterestRate(marketId, index);

        return Interest.calculateNewIndex(
            index,
            rate,
            state.getTotalPar(marketId),
            state.riskParams.earningsRate
        );
    }

    function fetchInterestRate(
        Storage.State storage state,
        uint256 marketId,
        Interest.Index memory index
    )
    internal
    view
    returns (Interest.Rate memory)
    {
        Types.TotalPar memory totalPar = state.getTotalPar(marketId);
        (
        Types.Wei memory supplyWei,
        Types.Wei memory borrowWei
        ) = Interest.totalParToWei(totalPar, index);

        Interest.Rate memory rate = state.markets[marketId].interestSetter.getInterestRate(
            state.getToken(marketId),
            borrowWei.value,
            supplyWei.value
        );

        return rate;
    }

    function fetchPrice(
        Storage.State storage state,
        uint256 marketId,
        address token
    )
    internal
    view
    returns (Monetary.Price memory)
    {
        IPriceOracle oracle = IPriceOracle(state.markets[marketId].priceOracle);
        Monetary.Price memory price = oracle.getPrice(token);
        Require.that(
            price.value != 0,
            FILE,
            "Price cannot be zero",
            marketId
        );
        return price;
    }

    function getAccountValues(
        Storage.State storage state,
        Account.Info memory account,
        Cache.MarketCache memory cache,
        bool adjustForLiquidity
    )
    internal
    view
    returns (Monetary.Value memory, Monetary.Value memory)
    {
        Monetary.Value memory supplyValue;
        Monetary.Value memory borrowValue;

        uint256 numMarkets = cache.getNumMarkets();
        for (uint256 i = 0; i < numMarkets; i++) {
            Types.Wei memory userWei = state.getWei(account, cache.getAtIndex(i).marketId);

            if (userWei.isZero()) {
                continue;
            }

            uint256 assetValue = userWei.value.mul(cache.getAtIndex(i).price.value);
            Decimal.D256 memory adjust = Decimal.one();
            if (adjustForLiquidity) {
                adjust = Decimal.onePlus(state.markets[cache.getAtIndex(i).marketId].marginPremium);
            }

            if (userWei.sign) {
                supplyValue.value = supplyValue.value.add(Decimal.div(assetValue, adjust));
            } else {
                borrowValue.value = borrowValue.value.add(Decimal.mul(assetValue, adjust));
            }
        }

        return (supplyValue, borrowValue);
    }

    function isCollateralized(
        Storage.State storage state,
        Account.Info memory account,
        Cache.MarketCache memory cache,
        bool requireMinBorrow
    )
    internal
    view
    returns (bool)
    {
        if (state.getNumberOfMarketsWithBorrow(account) == 0) {
            // The user does not have a balance with a borrow amount, so they must be collateralized
            return true;
        }

        // get account values (adjusted for liquidity)
        (
        Monetary.Value memory supplyValue,
        Monetary.Value memory borrowValue
        ) = state.getAccountValues(account, cache, /* adjustForLiquidity = */ true);

        if (borrowValue.value == 0) {
            return true;
        }

        if (requireMinBorrow) {
            Require.that(
                borrowValue.value >= state.riskParams.minBorrowedValue.value,
                FILE,
                "Borrow value too low",
                account.owner,
                account.number
            );
        }

        uint256 requiredMargin = Decimal.mul(borrowValue.value, state.riskParams.marginRatio);

        return supplyValue.value >= borrowValue.value.add(requiredMargin);
    }

    function isGlobalOperator(
        Storage.State storage state,
        address operator
    )
    internal
    view
    returns (bool)
    {
        return state.globalOperators[operator];
    }

    function isLocalOperator(
        Storage.State storage state,
        address owner,
        address operator
    )
    internal
    view
    returns (bool)
    {
        return state.operators[owner][operator];
    }

    function requireIsGlobalOperator(
        Storage.State storage state,
        address operator
    )
    internal
    view
    {
        bool isValidOperator = state.isGlobalOperator(operator);

        Require.that(
            isValidOperator,
            FILE,
            "Unpermissioned global operator",
            operator
        );
    }

    function requireIsOperator(
        Storage.State storage state,
        Account.Info memory account,
        address operator
    )
    internal
    view
    {
        bool isValidOperator =
        operator == account.owner
        || state.isGlobalOperator(operator)
        || state.isLocalOperator(account.owner, operator);

        Require.that(
            isValidOperator,
            FILE,
            "Unpermissioned operator",
            operator
        );
    }

    /**
     * Determine and set an account's balance based on the intended balance change. Return the
     * equivalent amount in wei
     */
    function getNewParAndDeltaWei(
        Storage.State storage state,
        Account.Info memory account,
        uint256 marketId,
        Types.AssetAmount memory amount
    )
    internal
    view
    returns (Types.Par memory, Types.Wei memory)
    {
        Types.Par memory oldPar = state.getPar(account, marketId);

        if (amount.value == 0 && amount.ref == Types.AssetReference.Delta) {
            return (oldPar, Types.zeroWei());
        }

        Interest.Index memory index = state.getIndex(marketId);
        Types.Wei memory oldWei = Interest.parToWei(oldPar, index);
        Types.Par memory newPar;
        Types.Wei memory deltaWei;

        if (amount.denomination == Types.AssetDenomination.Wei) {
            deltaWei = Types.Wei({
            sign: amount.sign,
            value: amount.value
            });
            if (amount.ref == Types.AssetReference.Target) {
                deltaWei = deltaWei.sub(oldWei);
            }
            newPar = Interest.weiToPar(oldWei.add(deltaWei), index);
        } else { // AssetDenomination.Par
            newPar = Types.Par({
            sign: amount.sign,
            value: amount.value.to128()
            });
            if (amount.ref == Types.AssetReference.Delta) {
                newPar = oldPar.add(newPar);
            }
            deltaWei = Interest.parToWei(newPar, index).sub(oldWei);
        }

        return (newPar, deltaWei);
    }

    function getNewParAndDeltaWeiForLiquidation(
        Storage.State storage state,
        Account.Info memory account,
        uint256 marketId,
        Types.AssetAmount memory amount
    )
    internal
    view
    returns (Types.Par memory, Types.Wei memory)
    {
        Types.Par memory oldPar = state.getPar(account, marketId);

        Require.that(
            !oldPar.isPositive(),
            FILE,
            "Owed balance cannot be positive",
            account.owner,
            account.number
        );

        (
        Types.Par memory newPar,
        Types.Wei memory deltaWei
        ) = state.getNewParAndDeltaWei(
            account,
            marketId,
            amount
        );

        // if attempting to over-repay the owed asset, bound it by the maximum
        if (newPar.isPositive()) {
            newPar = Types.zeroPar();
            deltaWei = state.getWei(account, marketId).negative();
        }

        Require.that(
            !deltaWei.isNegative() && oldPar.value >= newPar.value,
            FILE,
            "Owed balance cannot increase",
            account.owner,
            account.number
        );

        // if not paying back enough wei to repay any par, then bound wei to zero
        if (oldPar.equals(newPar)) {
            deltaWei = Types.zeroWei();
        }

        return (newPar, deltaWei);
    }

    function isVaporizable(
        Storage.State storage state,
        Account.Info memory account,
        Cache.MarketCache memory cache
    )
    internal
    view
    returns (bool)
    {
        bool hasNegative = false;
        uint256 numMarkets = cache.getNumMarkets();
        for (uint256 i = 0; i < numMarkets; i++) {
            Types.Par memory par = state.getPar(account, cache.getAtIndex(i).marketId);
            if (par.isZero()) {
                continue;
            } else if (par.sign) {
                return false;
            } else {
                hasNegative = true;
            }
        }
        return hasNegative;
    }

    // =============== Setter Functions ===============

    function updateIndex(
        Storage.State storage state,
        uint256 marketId
    )
    internal
    returns (Interest.Index memory)
    {
        Interest.Index memory index = state.getIndex(marketId);
        if (index.lastUpdate == Time.currentTime()) {
            return index;
        }
        return state.markets[marketId].index = state.fetchNewIndex(marketId, index);
    }

    function setStatus(
        Storage.State storage state,
        Account.Info memory account,
        Account.Status status
    )
    internal
    {
        state.accounts[account.owner][account.number].status = status;
    }

    function setPar(
        Storage.State storage state,
        Account.Info memory account,
        uint256 marketId,
        Types.Par memory newPar
    )
    internal
    {
        Types.Par memory oldPar = state.getPar(account, marketId);

        if (Types.equals(oldPar, newPar)) {
            // GUARD statement
            return;
        }

        // updateTotalPar
        Types.TotalPar memory totalPar = state.getTotalPar(marketId);

        // roll-back oldPar
        if (oldPar.sign) {
            totalPar.supply = uint256(totalPar.supply).sub(oldPar.value).to128();
        } else {
            totalPar.borrow = uint256(totalPar.borrow).sub(oldPar.value).to128();
        }

        // roll-forward newPar
        if (newPar.sign) {
            totalPar.supply = uint256(totalPar.supply).add(newPar.value).to128();
        } else {
            totalPar.borrow = uint256(totalPar.borrow).add(newPar.value).to128();
        }

        if (oldPar.isLessThanZero() && newPar.isGreaterThanOrEqualToZero()) {
            // user went from borrowing to repaying or positive
            state.accounts[account.owner][account.number].numberOfMarketsWithBorrow -= 1;
        } else if (oldPar.isGreaterThanOrEqualToZero() && newPar.isLessThanZero()) {
            // user went from zero or positive to borrowing
            state.accounts[account.owner][account.number].numberOfMarketsWithBorrow += 1;
        }

        if (newPar.isZero() && (!oldPar.isZero())) {
            // User went from a non-zero balance to zero. Remove the market from the set.
            state.accounts[account.owner][account.number].marketsWithNonZeroBalanceSet.remove(marketId);
        } else if ((!newPar.isZero()) && oldPar.isZero()) {
            // User went from zero to non-zero. Add the market to the set.
            state.accounts[account.owner][account.number].marketsWithNonZeroBalanceSet.add(marketId);
        }

        state.markets[marketId].totalPar = totalPar;
        state.accounts[account.owner][account.number].balances[marketId] = newPar;
    }

    /**
     * Determine and set an account's balance based on a change in wei
     */
    function setParFromDeltaWei(
        Storage.State storage state,
        Account.Info memory account,
        uint256 marketId,
        Types.Wei memory deltaWei
    )
    internal
    {
        if (deltaWei.isZero()) {
            return;
        }
        Interest.Index memory index = state.getIndex(marketId);
        Types.Wei memory oldWei = state.getWei(account, marketId);
        Types.Wei memory newWei = oldWei.add(deltaWei);
        Types.Par memory newPar = Interest.weiToPar(newWei, index);
        state.setPar(
            account,
            marketId,
            newPar
        );
    }

    function initializeCache(
        Storage.State storage state,
        Cache.MarketCache memory cache
    ) internal view {
        cache.markets = new Cache.MarketInfo[](cache.marketsLength);
        uint counter = 0;

        // Really neat byproduct of iterating through a bitmap using the least significant bit, where each set flag
        // represents the marketId, --> the initialized `cache.markets` array is sorted in O(n)!!!!!!
        // Meaning, this function call is O(n) where `n` is the number of markets in the cache
        for (uint i = 0; i < cache.marketBitmaps.length; i++) {
            uint bitmap = cache.marketBitmaps[i];
            while (bitmap != 0) {
                uint nextSetBit = Bits.getLeastSignificantBit(bitmap);
                uint marketId = Bits.getMarketIdFromBit(i, nextSetBit);
                address token = state.getToken(marketId);
                if (state.markets[marketId].isClosing) {
                    cache.markets[counter++] = Cache.MarketInfo({
                    marketId: marketId,
                    token: token,
                    isClosing: true,
                    borrowPar: state.getTotalPar(marketId).borrow,
                    price: state.fetchPrice(marketId, token)
                    });
                } else {
                    // don't need the borrowPar if the market is not closing
                    cache.markets[counter++] = Cache.MarketInfo({
                    marketId: marketId,
                    token: token,
                    isClosing: false,
                    borrowPar: 0,
                    price: state.fetchPrice(marketId, token)
                    });
                }

                // unset the set bit
                bitmap = Bits.unsetBit(bitmap, nextSetBit);
            }
            if (counter == cache.marketsLength) {
                break;
            }
        }

        Require.that(
            cache.marketsLength == counter,
            FILE,
            "cache initialized improperly",
            cache.marketsLength,
            cache.markets.length
        );
    }
}

// File: contracts/protocol/lib/Actions.sol

/*

    Copyright 2019 dYdX Trading Inc.

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

pragma solidity ^0.5.7;




/**
 * @title Actions
 * @author dYdX
 *
 * Library that defines and parses valid Actions
 */
library Actions {

    // ============ Constants ============

    bytes32 constant FILE = "Actions";

    // ============ Enums ============

    enum ActionType {
        Deposit,   // supply tokens
        Withdraw,  // borrow tokens
        Transfer,  // transfer balance between accounts
        Buy,       // buy an amount of some token (externally)
        Sell,      // sell an amount of some token (externally)
        Trade,     // trade tokens against another account
        Liquidate, // liquidate an undercollateralized or expiring account
        Vaporize,  // use excess tokens to zero-out a completely negative account
        Call       // send arbitrary data to an address
    }

    enum AccountLayout {
        OnePrimary,
        TwoPrimary,
        PrimaryAndSecondary
    }

    enum MarketLayout {
        ZeroMarkets,
        OneMarket,
        TwoMarkets
    }

    // ============ Structs ============

    /*
     * Arguments that are passed to DolomiteMargin in an ordered list as part of a single operation.
     * Each ActionArgs has an actionType which specifies which action struct that this data will be
     * parsed into before being processed.
     */
    struct ActionArgs {
        ActionType actionType;
        uint256 accountId;
        Types.AssetAmount amount;
        uint256 primaryMarketId;
        uint256 secondaryMarketId;
        address otherAddress;
        uint256 otherAccountId;
        bytes data;
    }

    // ============ Action Types ============

    /*
     * Moves tokens from an address to DolomiteMargin. Can either repay a borrow or provide additional supply.
     */
    struct DepositArgs {
        Types.AssetAmount amount;
        Account.Info account;
        uint256 market;
        address from;
    }

    /*
     * Moves tokens from DolomiteMargin to another address. Can either borrow tokens or reduce the amount
     * previously supplied.
     */
    struct WithdrawArgs {
        Types.AssetAmount amount;
        Account.Info account;
        uint256 market;
        address to;
    }

    /*
     * Transfers balance between two accounts. The msg.sender must be an operator for both accounts.
     * The amount field applies to accountOne.
     * This action does not require any token movement since the trade is done internally to DolomiteMargin.
     */
    struct TransferArgs {
        Types.AssetAmount amount;
        Account.Info accountOne;
        Account.Info accountTwo;
        uint256 market;
    }

    /*
     * Acquires a certain amount of tokens by spending other tokens. Sends takerMarket tokens to the
     * specified exchangeWrapper contract and expects makerMarket tokens in return. The amount field
     * applies to the makerMarket.
     */
    struct BuyArgs {
        Types.AssetAmount amount;
        Account.Info account;
        uint256 makerMarket;
        uint256 takerMarket;
        address exchangeWrapper;
        bytes orderData;
    }

    /*
     * Spends a certain amount of tokens to acquire other tokens. Sends takerMarket tokens to the
     * specified exchangeWrapper and expects makerMarket tokens in return. The amount field applies
     * to the takerMarket.
     */
    struct SellArgs {
        Types.AssetAmount amount;
        Account.Info account;
        uint256 takerMarket;
        uint256 makerMarket;
        address exchangeWrapper;
        bytes orderData;
    }

    /*
     * Trades balances between two accounts using any external contract that implements the
     * AutoTrader interface. The AutoTrader contract must be an operator for the makerAccount (for
     * which it is trading on-behalf-of). The amount field applies to the makerAccount and the
     * inputMarket. This proposed change to the makerAccount is passed to the AutoTrader which will
     * quote a change for the makerAccount in the outputMarket (or will disallow the trade).
     * This action does not require any token movement since the trade is done internally to DolomiteMargin.
     */
    struct TradeArgs {
        Types.AssetAmount amount;
        Account.Info takerAccount;
        Account.Info makerAccount;
        uint256 inputMarket;
        uint256 outputMarket;
        address autoTrader;
        bytes tradeData;
    }

    /*
     * Each account must maintain a certain margin-ratio (specified globally). If the account falls
     * below this margin-ratio, it can be liquidated by any other account. This allows anyone else
     * (arbitrageurs) to repay any borrowed asset (owedMarket) of the liquidating account in
     * exchange for any collateral asset (heldMarket) of the liquidAccount. The ratio is determined
     * by the price ratio (given by the oracles) plus a spread (specified globally). Liquidating an
     * account also sets a flag on the account that the account is being liquidated. This allows
     * anyone to continue liquidating the account until there are no more borrows being taken by the
     * liquidating account. Liquidators do not have to liquidate the entire account all at once but
     * can liquidate as much as they choose. The liquidating flag allows liquidators to continue
     * liquidating the account even if it becomes collateralized through partial liquidation or
     * price movement.
     */
    struct LiquidateArgs {
        Types.AssetAmount amount;
        Account.Info solidAccount;
        Account.Info liquidAccount;
        uint256 owedMarket;
        uint256 heldMarket;
    }

    /*
     * Similar to liquidate, but vaporAccounts are accounts that have only negative balances remaining. The arbitrageur
     * pays back the negative asset (owedMarket) of the vaporAccount in exchange for a collateral asset (heldMarket) at
     * a favorable spread. However, since the liquidAccount has no collateral assets, the collateral must come from
     * DolomiteMargin's excess tokens.
     */
    struct VaporizeArgs {
        Types.AssetAmount amount;
        Account.Info solidAccount;
        Account.Info vaporAccount;
        uint256 owedMarket;
        uint256 heldMarket;
    }

    /*
     * Passes arbitrary bytes of data to an external contract that implements the Callee interface.
     * Does not change any asset amounts. This function may be useful for setting certain variables
     * on layer-two contracts for certain accounts without having to make a separate Ethereum
     * transaction for doing so. Also, the second-layer contracts can ensure that the call is coming
     * from an operator of the particular account.
     */
    struct CallArgs {
        Account.Info account;
        address callee;
        bytes data;
    }

    // ============ Helper Functions ============

    function getMarketLayout(
        ActionType actionType
    )
    internal
    pure
    returns (MarketLayout)
    {
        if (
            actionType == Actions.ActionType.Deposit
            || actionType == Actions.ActionType.Withdraw
            || actionType == Actions.ActionType.Transfer
        ) {
            return MarketLayout.OneMarket;
        }
        else if (actionType == Actions.ActionType.Call) {
            return MarketLayout.ZeroMarkets;
        }
        return MarketLayout.TwoMarkets;
    }

    function getAccountLayout(
        ActionType actionType
    )
    internal
    pure
    returns (AccountLayout)
    {
        if (
            actionType == Actions.ActionType.Transfer
            || actionType == Actions.ActionType.Trade
        ) {
            return AccountLayout.TwoPrimary;
        } else if (
            actionType == Actions.ActionType.Liquidate
            || actionType == Actions.ActionType.Vaporize
        ) {
            return AccountLayout.PrimaryAndSecondary;
        }
        return AccountLayout.OnePrimary;
    }

    // ============ Parsing Functions ============

    function parseDepositArgs(
        Account.Info[] memory accounts,
        ActionArgs memory args
    )
    internal
    pure
    returns (DepositArgs memory)
    {
        return DepositArgs({
        amount: args.amount,
        account: accounts[args.accountId],
        market: args.primaryMarketId,
        from: args.otherAddress
        });
    }

    function parseWithdrawArgs(
        Account.Info[] memory accounts,
        ActionArgs memory args
    )
    internal
    pure
    returns (WithdrawArgs memory)
    {
        return WithdrawArgs({
        amount: args.amount,
        account: accounts[args.accountId],
        market: args.primaryMarketId,
        to: args.otherAddress
        });
    }

    function parseTransferArgs(
        Account.Info[] memory accounts,
        ActionArgs memory args
    )
    internal
    pure
    returns (TransferArgs memory)
    {
        return TransferArgs({
        amount: args.amount,
        accountOne: accounts[args.accountId],
        accountTwo: accounts[args.otherAccountId],
        market: args.primaryMarketId
        });
    }

    function parseBuyArgs(
        Account.Info[] memory accounts,
        ActionArgs memory args
    )
    internal
    pure
    returns (BuyArgs memory)
    {
        return BuyArgs({
        amount: args.amount,
        account: accounts[args.accountId],
        makerMarket: args.primaryMarketId,
        takerMarket: args.secondaryMarketId,
        exchangeWrapper: args.otherAddress,
        orderData: args.data
        });
    }

    function parseSellArgs(
        Account.Info[] memory accounts,
        ActionArgs memory args
    )
    internal
    pure
    returns (SellArgs memory)
    {
        return SellArgs({
        amount: args.amount,
        account: accounts[args.accountId],
        takerMarket: args.primaryMarketId,
        makerMarket: args.secondaryMarketId,
        exchangeWrapper: args.otherAddress,
        orderData: args.data
        });
    }

    function parseTradeArgs(
        Account.Info[] memory accounts,
        ActionArgs memory args
    )
    internal
    pure
    returns (TradeArgs memory)
    {
        return TradeArgs({
        amount: args.amount,
        takerAccount: accounts[args.accountId],
        makerAccount: accounts[args.otherAccountId],
        inputMarket: args.primaryMarketId,
        outputMarket: args.secondaryMarketId,
        autoTrader: args.otherAddress,
        tradeData: args.data
        });
    }

    function parseLiquidateArgs(
        Account.Info[] memory accounts,
        ActionArgs memory args
    )
    internal
    pure
    returns (LiquidateArgs memory)
    {
        return LiquidateArgs({
        amount: args.amount,
        solidAccount: accounts[args.accountId],
        liquidAccount: accounts[args.otherAccountId],
        owedMarket: args.primaryMarketId,
        heldMarket: args.secondaryMarketId
        });
    }

    function parseVaporizeArgs(
        Account.Info[] memory accounts,
        ActionArgs memory args
    )
    internal
    pure
    returns (VaporizeArgs memory)
    {
        return VaporizeArgs({
        amount: args.amount,
        solidAccount: accounts[args.accountId],
        vaporAccount: accounts[args.otherAccountId],
        owedMarket: args.primaryMarketId,
        heldMarket: args.secondaryMarketId
        });
    }

    function parseCallArgs(
        Account.Info[] memory accounts,
        ActionArgs memory args
    )
    internal
    pure
    returns (CallArgs memory)
    {
        return CallArgs({
        account: accounts[args.accountId],
        callee: args.otherAddress,
        data: args.data
        });
    }
}

// File: contracts/protocol/interfaces/IDolomiteMargin.sol

/*

    Copyright 2021 Dolomite.

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

pragma solidity >=0.5.0;










interface IDolomiteMargin {

    // ============ Getters for Markets ============

    /**
     * Get the ERC20 token address for a market.
     *
     * @param  token    The token to query
     * @return          The token's marketId if the token is valid
     */
    function getMarketIdByTokenAddress(
        address token
    ) external view returns (uint256);

    /**
     * Get the ERC20 token address for a market.
     *
     * @param  marketId  The market to query
     * @return           The token address
     */
    function getMarketTokenAddress(
        uint256 marketId
    ) external view returns (address);

    /**
     * Return true if a particular market is in closing mode. Additional borrows cannot be taken
     * from a market that is closing.
     *
     * @param  marketId  The market to query
     * @return           True if the market is closing
     */
    function getMarketIsClosing(
        uint256 marketId
    )
    external
    view
    returns (bool);

    /**
     * Get the price of the token for a market.
     *
     * @param  marketId  The market to query
     * @return           The price of each atomic unit of the token
     */
    function getMarketPrice(
        uint256 marketId
    ) external view returns (Monetary.Price memory);

    /**
     * Get the total number of markets.
     *
     * @return  The number of markets
     */
    function getNumMarkets() external view returns (uint256);

    /**
     * Get the total principal amounts (borrowed and supplied) for a market.
     *
     * @param  marketId  The market to query
     * @return           The total principal amounts
     */
    function getMarketTotalPar(
        uint256 marketId
    ) external view returns (Types.TotalPar memory);

    /**
     * Get the most recently cached interest index for a market.
     *
     * @param  marketId  The market to query
     * @return           The most recent index
     */
    function getMarketCachedIndex(
        uint256 marketId
    ) external view returns (Interest.Index memory);

    /**
     * Get the interest index for a market if it were to be updated right now.
     *
     * @param  marketId  The market to query
     * @return           The estimated current index
     */
    function getMarketCurrentIndex(
        uint256 marketId
    ) external view returns (Interest.Index memory);

    /**
     * Get the price oracle address for a market.
     *
     * @param  marketId  The market to query
     * @return           The price oracle address
     */
    function getMarketPriceOracle(
        uint256 marketId
    ) external view returns (IPriceOracle);

    /**
     * Get the interest-setter address for a market.
     *
     * @param  marketId  The market to query
     * @return           The interest-setter address
     */
    function getMarketInterestSetter(
        uint256 marketId
    ) external view returns (IInterestSetter);

    /**
     * Get the margin premium for a market. A margin premium makes it so that any positions that
     * include the market require a higher collateralization to avoid being liquidated.
     *
     * @param  marketId  The market to query
     * @return           The market's margin premium
     */
    function getMarketMarginPremium(
        uint256 marketId
    ) external view returns (Decimal.D256 memory);

    /**
     * Get the spread premium for a market. A spread premium makes it so that any liquidations
     * that include the market have a higher spread than the global default.
     *
     * @param  marketId  The market to query
     * @return           The market's spread premium
     */
    function getMarketSpreadPremium(
        uint256 marketId
    ) external view returns (Decimal.D256 memory);

    /**
     * Return true if this market can be removed and its ID can be recycled and reused
     *
     * @param  marketId  The market to query
     * @return           True if the market is recyclable
     */
    function getMarketIsRecyclable(
        uint256 marketId
    ) external view returns (bool);

    /**
     * Gets the recyclable markets, up to `n` length. If `n` is greater than the length of the list, 0's are returned
     * for the empty slots.
     *
     * @param  n    The number of markets to get, bounded by the linked list being smaller than `n`
     * @return      The list of recyclable markets, in the same order held by the linked list
     */
    function getRecyclableMarkets(
        uint256 n
    ) external view returns (uint[] memory);

    /**
     * Get the current borrower interest rate for a market.
     *
     * @param  marketId  The market to query
     * @return           The current interest rate
     */
    function getMarketInterestRate(
        uint256 marketId
    ) external view returns (Interest.Rate memory);

    /**
     * Get basic information about a particular market.
     *
     * @param  marketId  The market to query
     * @return           A Storage.Market struct with the current state of the market
     */
    function getMarket(
        uint256 marketId
    ) external view returns (Storage.Market memory);

    /**
     * Get comprehensive information about a particular market.
     *
     * @param  marketId  The market to query
     * @return           A tuple containing the values:
     *                    - A Storage.Market struct with the current state of the market
     *                    - The current estimated interest index
     *                    - The current token price
     *                    - The current market interest rate
     */
    function getMarketWithInfo(
        uint256 marketId
    )
    external
    view
    returns (
        Storage.Market memory,
        Interest.Index memory,
        Monetary.Price memory,
        Interest.Rate memory
    );

    /**
     * Get the number of excess tokens for a market. The number of excess tokens is calculated by taking the current
     * number of tokens held in DolomiteMargin, adding the number of tokens owed to DolomiteMargin by borrowers, and
     * subtracting the number of tokens owed to suppliers by DolomiteMargin.
     *
     * @param  marketId  The market to query
     * @return           The number of excess tokens
     */
    function getNumExcessTokens(
        uint256 marketId
    ) external view returns (Types.Wei memory);

    // ============ Getters for Accounts ============

    /**
     * Get the principal value for a particular account and market.
     *
     * @param  account   The account to query
     * @param  marketId  The market to query
     * @return           The principal value
     */
    function getAccountPar(
        Account.Info calldata account,
        uint256 marketId
    ) external view returns (Types.Par memory);

    /**
     * Get the principal value for a particular account and market, with no check the market is valid. Meaning, markets
     * that don't exist return 0.
     *
     * @param  account   The account to query
     * @param  marketId  The market to query
     * @return           The principal value
     */
    function getAccountParNoMarketCheck(
        Account.Info calldata account,
        uint256 marketId
    ) external view returns (Types.Par memory);

    /**
     * Get the token balance for a particular account and market.
     *
     * @param  account   The account to query
     * @param  marketId  The market to query
     * @return           The token amount
     */
    function getAccountWei(
        Account.Info calldata account,
        uint256 marketId
    ) external view returns (Types.Wei memory);

    /**
     * Get the status of an account (Normal, Liquidating, or Vaporizing).
     *
     * @param  account  The account to query
     * @return          The account's status
     */
    function getAccountStatus(
        Account.Info calldata account
    ) external view returns (Account.Status);

    /**
     * Get a list of markets that have a non-zero balance for an account
     *
     * @param  account  The account to query
     * @return          The non-sorted marketIds with non-zero balance for the account.
     */
    function getAccountMarketsWithNonZeroBalances(
        Account.Info calldata account
    ) external view returns (uint256[] memory);

    /**
     * Get the number of markets with which an account has a negative balance.
     *
     * @param  account  The account to query
     * @return          The non-sorted marketIds with non-zero balance for the account.
     */
    function getNumberOfMarketsWithBorrow(
        Account.Info calldata account
    ) external view returns (uint256);

    /**
     * Get the total supplied and total borrowed value of an account.
     *
     * @param  account  The account to query
     * @return          The following values:
     *                   - The supplied value of the account
     *                   - The borrowed value of the account
     */
    function getAccountValues(
        Account.Info calldata account
    ) external view returns (Monetary.Value memory, Monetary.Value memory);

    /**
     * Get the total supplied and total borrowed values of an account adjusted by the marginPremium
     * of each market. Supplied values are divided by (1 + marginPremium) for each market and
     * borrowed values are multiplied by (1 + marginPremium) for each market. Comparing these
     * adjusted values gives the margin-ratio of the account which will be compared to the global
     * margin-ratio when determining if the account can be liquidated.
     *
     * @param  account  The account to query
     * @return          The following values:
     *                   - The supplied value of the account (adjusted for marginPremium)
     *                   - The borrowed value of the account (adjusted for marginPremium)
     */
    function getAdjustedAccountValues(
        Account.Info calldata account
    ) external view returns (Monetary.Value memory, Monetary.Value memory);

    /**
     * Get an account's summary for each market.
     *
     * @param  account  The account to query
     * @return          The following values:
     *                   - The market IDs for each market
     *                   - The ERC20 token address for each market
     *                   - The account's principal value for each market
     *                   - The account's (supplied or borrowed) number of tokens for each market
     */
    function getAccountBalances(
        Account.Info calldata account
    ) external view returns (uint[] memory, address[] memory, Types.Par[] memory, Types.Wei[] memory);

    // ============ Getters for Account Permissions ============

    /**
     * Return true if a particular address is approved as an operator for an owner's accounts.
     * Approved operators can act on the accounts of the owner as if it were the operator's own.
     *
     * @param  owner     The owner of the accounts
     * @param  operator  The possible operator
     * @return           True if operator is approved for owner's accounts
     */
    function getIsLocalOperator(
        address owner,
        address operator
    ) external view returns (bool);

    /**
     * Return true if a particular address is approved as a global operator. Such an address can
     * act on any account as if it were the operator's own.
     *
     * @param  operator  The address to query
     * @return           True if operator is a global operator
     */
    function getIsGlobalOperator(
        address operator
    ) external view returns (bool);

    // ============ Getters for Risk Params ============

    /**
     * Get the global minimum margin-ratio that every position must maintain to prevent being
     * liquidated.
     *
     * @return  The global margin-ratio
     */
    function getMarginRatio() external view returns (Decimal.D256 memory);

    /**
     * Get the global liquidation spread. This is the spread between oracle prices that incentivizes
     * the liquidation of risky positions.
     *
     * @return  The global liquidation spread
     */
    function getLiquidationSpread() external view returns (Decimal.D256 memory);

    /**
     * Get the adjusted liquidation spread for some market pair. This is equal to the global
     * liquidation spread multiplied by (1 + spreadPremium) for each of the two markets.
     *
     * @param  heldMarketId  The market for which the account has collateral
     * @param  owedMarketId  The market for which the account has borrowed tokens
     * @return               The adjusted liquidation spread
     */
    function getLiquidationSpreadForPair(
        uint256 heldMarketId,
        uint256 owedMarketId
    ) external view returns (Decimal.D256 memory);

    /**
     * Get the global earnings-rate variable that determines what percentage of the interest paid
     * by borrowers gets passed-on to suppliers.
     *
     * @return  The global earnings rate
     */
    function getEarningsRate() external view returns (Decimal.D256 memory);

    /**
     * Get the global minimum-borrow value which is the minimum value of any new borrow on DolomiteMargin.
     *
     * @return  The global minimum borrow value
     */
    function getMinBorrowedValue() external view returns (Monetary.Value memory);

    /**
     * Get all risk parameters in a single struct.
     *
     * @return  All global risk parameters
     */
    function getRiskParams() external view returns (Storage.RiskParams memory);

    /**
     * Get all risk parameter limits in a single struct. These are the maximum limits at which the
     * risk parameters can be set by the admin of DolomiteMargin.
     *
     * @return  All global risk parameter limits
     */
    function getRiskLimits() external view returns (Storage.RiskLimits memory);

    // ============ Write Functions ============

    /**
     * The main entry-point to DolomiteMargin that allows users and contracts to manage accounts.
     * Take one or more actions on one or more accounts. The msg.sender must be the owner or
     * operator of all accounts except for those being liquidated, vaporized, or traded with.
     * One call to operate() is considered a singular "operation". Account collateralization is
     * ensured only after the completion of the entire operation.
     *
     * @param  accounts  A list of all accounts that will be used in this operation. Cannot contain
     *                   duplicates. In each action, the relevant account will be referred-to by its
     *                   index in the list.
     * @param  actions   An ordered list of all actions that will be taken in this operation. The
     *                   actions will be processed in order.
     */
    function operate(
        Account.Info[] calldata accounts,
        Actions.ActionArgs[] calldata actions
    ) external;

    /**
     * Approves/disapproves any number of operators. An operator is an external address that has the
     * same permissions to manipulate an account as the owner of the account. Operators are simply
     * addresses and therefore may either be externally-owned Ethereum accounts OR smart contracts.
     *
     * Operators are also able to act as AutoTrader contracts on behalf of the account owner if the
     * operator is a smart contract and implements the IAutoTrader interface.
     *
     * @param  args  A list of OperatorArgs which have an address and a boolean. The boolean value
     *               denotes whether to approve (true) or revoke approval (false) for that address.
     */
    function setOperators(
        Types.OperatorArg[] calldata args
    ) external;

}

// File: contracts/external/helpers/OnlyDolomiteMargin.sol

/*

    Copyright 2019 dYdX Trading Inc.

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

pragma solidity ^0.5.7;




/**
 * @title OnlyDolomiteMargin
 * @author Dolomite
 *
 * Inheritable contract that restricts the calling of certain functions to DolomiteMargin only
 */
contract OnlyDolomiteMargin {

    // ============ Constants ============

    bytes32 constant FILE = "OnlyDolomiteMargin";

    // ============ Storage ============

    IDolomiteMargin public DOLOMITE_MARGIN;

    // ============ Constructor ============

    constructor (
        address dolomiteMargin
    )
    public
    {
        DOLOMITE_MARGIN = IDolomiteMargin(dolomiteMargin);
    }

    // ============ Modifiers ============

    modifier onlyDolomiteMargin(address from) {
        Require.that(
            from == address(DOLOMITE_MARGIN),
            FILE,
            "Only Dolomite can call function",
            from
        );
        _;
    }
}

// File: contracts/protocol/interfaces/ICallee.sol

/*

    Copyright 2019 dYdX Trading Inc.

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

pragma solidity ^0.5.7;



/**
 * @title ICallee
 * @author dYdX
 *
 * Interface that Callees for DolomiteMargin must implement in order to ingest data.
 */
contract ICallee {

    // ============ Public Functions ============

    /**
     * Allows users to send this contract arbitrary data.
     *
     * @param  sender       The msg.sender to DolomiteMargin
     * @param  accountInfo  The account from which the data is being sent
     * @param  data         Arbitrary data given by the sender
     */
    function callFunction(
        address sender,
        Account.Info memory accountInfo,
        bytes memory data
    )
    public;
}

// File: contracts/protocol/interfaces/IAutoTrader.sol

/*

    Copyright 2019 dYdX Trading Inc.

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

pragma solidity ^0.5.7;




/**
 * @title IAutoTrader
 * @author dYdX
 *
 * Interface that Auto-Traders for DolomiteMargin must implement in order to approve trades.
 */
contract IAutoTrader {

    // ============ Public Functions ============

    /**
     * Allows traders to make trades approved by this smart contract. The active trader's account is
     * the takerAccount and the passive account (for which this contract approves trades
     * on-behalf-of) is the makerAccount.
     *
     * @param  inputMarketId   The market for which the trader specified the original amount
     * @param  outputMarketId  The market for which the trader wants the resulting amount specified
     * @param  makerAccount    The account for which this contract is making trades
     * @param  takerAccount    The account requesting the trade
     * @param  oldInputPar     The old principal amount for the makerAccount for the inputMarketId
     * @param  newInputPar     The new principal amount for the makerAccount for the inputMarketId
     * @param  inputWei        The change in token amount for the makerAccount for the inputMarketId
     * @param  data            Arbitrary data passed in by the trader
     * @return                 The AssetAmount for the makerAccount for the outputMarketId
     */
    function getTradeCost(
        uint256 inputMarketId,
        uint256 outputMarketId,
        Account.Info memory makerAccount,
        Account.Info memory takerAccount,
        Types.Par memory oldInputPar,
        Types.Par memory newInputPar,
        Types.Wei memory inputWei,
        bytes memory data
    )
    public
    returns (Types.AssetAmount memory);
}

// File: contracts/external/traders/Expiry.sol

/*

    Copyright 2019 dYdX Trading Inc.

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

pragma solidity ^0.5.7;


















/**
 * @title Expiry
 * @author dYdX
 *
 * Expiry contract that also allows approved senders to set expiry to be 28 days in the future.
 */
contract Expiry is
Ownable,
OnlyDolomiteMargin,
IExpiry,
ICallee,
IAutoTrader
{
    using Address for address;
    using Math for uint256;
    using SafeMath for uint32;
    using SafeMath for uint256;
    using Types for Types.Par;
    using Types for Types.Wei;

    // ============ Constants ============

    bytes32 constant FILE = "Expiry";

    // ============ Events ============

    event ExpirySet(
        address owner,
        uint256 number,
        uint256 marketId,
        uint32 time
    );

    event LogExpiryRampTimeSet(
        uint256 expiryRampTime
    );

    event LogSenderApproved(
        address approver,
        address sender,
        uint32 minTimeDelta
    );

    event LogLiquidationCallbackSuccess(address indexed liquidAccountOwner, uint liquidAccountNumber);

    event LogLiquidationCallbackFailure(address indexed liquidAccountOwner, uint liquidAccountNumber, string reason);

    // ============ Storage ============

    // owner => number => market => time
    mapping (address => mapping (uint256 => mapping (uint256 => uint32))) g_expiries;

    // owner => sender => minimum time delta
    mapping (address => mapping (address => uint32)) public g_approvedSender;

    // time over which the liquidation ratio goes from zero to maximum
    uint256 public g_expiryRampTime;

    // ============ Constructor ============

    constructor (
        address dolomiteMargin,
        uint256 expiryRampTime
    )
    public
    OnlyDolomiteMargin(dolomiteMargin)
    {
        g_expiryRampTime = expiryRampTime;
    }

    // ============ Admin Functions ============

    function ownerSetExpiryRampTime(
        uint256 newExpiryRampTime
    )
    external
    onlyOwner
    {
        emit LogExpiryRampTimeSet(newExpiryRampTime);
        g_expiryRampTime = newExpiryRampTime;
    }

    // ============ Approval Functions ============

    function approveSender(
        address sender,
        uint32 minTimeDelta
    )
    external
    {
        _setApproval(msg.sender, sender, minTimeDelta);
    }

    // ============ Only-DolomiteMargin Functions ============

    function callFunction(
        address /* sender */,
        Account.Info memory account,
        bytes memory data
    )
    public
    onlyDolomiteMargin(msg.sender)
    {
        CallFunctionType callType = abi.decode(data, (CallFunctionType));
        if (callType == CallFunctionType.SetExpiry) {
            _callFunctionSetExpiry(account.owner, data);
        } else {
            _callFunctionSetApproval(account.owner, data);
        }
    }

    function getTradeCost(
        uint256 inputMarketId,
        uint256 outputMarketId,
        Account.Info memory makerAccount,
        Account.Info memory /* takerAccount */,
        Types.Par memory oldInputPar,
        Types.Par memory newInputPar,
        Types.Wei memory inputWei,
        bytes memory data
    )
    public
    onlyDolomiteMargin(msg.sender)
    returns (Types.AssetAmount memory)
    {
        // return zero if input amount is zero
        if (inputWei.isZero()) {
            return Types.AssetAmount({
            sign: true,
            denomination: Types.AssetDenomination.Par,
            ref: Types.AssetReference.Delta,
            value: 0
            });
        }

        (uint256 owedMarketId, uint32 maxExpiry) = abi.decode(data, (uint256, uint32));

        uint32 expiry = getExpiry(makerAccount, owedMarketId);

        // validate expiry
        Require.that(
            expiry != 0,
            FILE,
            "Expiry not set",
            makerAccount.owner,
            makerAccount.number,
            owedMarketId
        );
        Require.that(
            expiry <= Time.currentTime(),
            FILE,
            "Borrow not yet expired",
            expiry
        );
        Require.that(
            expiry <= maxExpiry,
            FILE,
            "Expiry past maxExpiry",
            expiry
        );

        return _getTradeCostInternal(
            DOLOMITE_MARGIN,
            inputMarketId,
            outputMarketId,
            makerAccount,
            oldInputPar,
            newInputPar,
            inputWei,
            owedMarketId,
            expiry
        );
    }

    // ============ Getters ============

    function getExpiry(
        Account.Info memory account,
        uint256 marketId
    )
    public
    view
    returns (uint32)
    {
        return g_expiries[account.owner][account.number][marketId];
    }

    function getSpreadAdjustedPrices(
        uint256 heldMarketId,
        uint256 owedMarketId,
        uint32 expiry
    )
    public
    view
    returns (
        Monetary.Price memory,
        Monetary.Price memory
    )
    {
        return _getSpreadAdjustedPrices(
            DOLOMITE_MARGIN,
            heldMarketId,
            owedMarketId,
            expiry
        );
    }

    // ============ Private Functions ============

    function _getSpreadAdjustedPrices(
        IDolomiteMargin dolomiteMargin,
        uint256 heldMarketId,
        uint256 owedMarketId,
        uint32 expiry
    )
    private
    view
    returns (
        Monetary.Price memory,
        Monetary.Price memory
    )
    {
        Decimal.D256 memory spread = dolomiteMargin.getLiquidationSpreadForPair(
            heldMarketId,
            owedMarketId
        );

        uint256 expiryAge = Time.currentTime().sub(expiry);

        if (expiryAge < g_expiryRampTime) {
            spread.value = Math.getPartial(spread.value, expiryAge, g_expiryRampTime);
        }

        Monetary.Price memory heldPrice = dolomiteMargin.getMarketPrice(heldMarketId);
        Monetary.Price memory owedPrice = dolomiteMargin.getMarketPrice(owedMarketId);
        owedPrice.value = owedPrice.value.add(Decimal.mul(owedPrice.value, spread));

        return (heldPrice, owedPrice);
    }

    function _callFunctionSetExpiry(
        address sender,
        bytes memory data
    )
    private
    {
        (
        CallFunctionType callType,
        SetExpiryArg[] memory expiries
        ) = abi.decode(data, (CallFunctionType, SetExpiryArg[]));

        assert(callType == CallFunctionType.SetExpiry);

        for (uint256 i = 0; i < expiries.length; i++) {
            SetExpiryArg memory exp = expiries[i];
            if (exp.account.owner != sender) {
                // don't do anything if sender is not approved for this action
                uint32 minApprovedTimeDelta = g_approvedSender[exp.account.owner][sender];
                if (minApprovedTimeDelta == 0 || exp.timeDelta < minApprovedTimeDelta) {
                    continue;
                }
            }

            // if timeDelta is zero, interpret it as unset expiry
            if (
                exp.timeDelta != 0 &&
                DOLOMITE_MARGIN.getAccountPar(exp.account, exp.marketId).isNegative()
            ) {
                // only change non-zero values if forceUpdate is true
                if (exp.forceUpdate || getExpiry(exp.account, exp.marketId) == 0) {
                    uint32 newExpiryTime = Time.currentTime().add(exp.timeDelta).to32();
                    _setExpiry(exp.account, exp.marketId, newExpiryTime);
                }
            } else {
                // timeDelta is zero or account has non-negative balance
                _setExpiry(exp.account, exp.marketId, 0);
            }
        }
    }

    function _callFunctionSetApproval(
        address sender,
        bytes memory data
    )
    private
    {
        (
        CallFunctionType callType,
        SetApprovalArg memory approvalArg
        ) = abi.decode(data, (CallFunctionType, SetApprovalArg));
        assert(callType == CallFunctionType.SetApproval);
        _setApproval(sender, approvalArg.sender, approvalArg.minTimeDelta);
    }

    function _getTradeCostInternal(
        IDolomiteMargin dolomiteMargin,
        uint256 inputMarketId,
        uint256 outputMarketId,
        Account.Info memory makerAccount,
        Types.Par memory oldInputPar,
        Types.Par memory newInputPar,
        Types.Wei memory inputWei,
        uint256 owedMarketId,
        uint32 expiry
    )
    private
    returns (Types.AssetAmount memory)
    {
        Types.AssetAmount memory output;
        Types.Wei memory maxOutputWei = dolomiteMargin.getAccountWei(makerAccount, outputMarketId);

        if (inputWei.isPositive()) {
            Require.that(
                inputMarketId == owedMarketId,
                FILE,
                "inputMarket mismatch",
                inputMarketId
            );
            Require.that(
                !newInputPar.isPositive(),
                FILE,
                "Borrows cannot be overpaid",
                newInputPar.value
            );
            assert(oldInputPar.isNegative());
            Require.that(
                maxOutputWei.isPositive(),
                FILE,
                "Collateral must be positive",
                outputMarketId,
                maxOutputWei.value
            );
            output = _owedWeiToHeldWei(
                dolomiteMargin,
                inputWei,
                outputMarketId,
                inputMarketId,
                expiry
            );

            // clear expiry if borrow is fully repaid
            if (newInputPar.isZero()) {
                _setExpiry(makerAccount, owedMarketId, 0);
            }
        } else {
            Require.that(
                outputMarketId == owedMarketId,
                FILE,
                "outputMarket mismatch",
                outputMarketId
            );
            Require.that(
                !newInputPar.isNegative(),
                FILE,
                "Collateral cannot be overused",
                newInputPar.value
            );
            assert(oldInputPar.isPositive());
            Require.that(
                maxOutputWei.isNegative(),
                FILE,
                "Borrows must be negative",
                outputMarketId,
                maxOutputWei.value
            );
            output = _heldWeiToOwedWei(
                dolomiteMargin,
                inputWei,
                inputMarketId,
                outputMarketId,
                expiry
            );

            // clear expiry if borrow is fully repaid
            if (output.value == maxOutputWei.value) {
                _setExpiry(makerAccount, owedMarketId, 0);
            }
        }

        Require.that(
            output.value <= maxOutputWei.value,
            FILE,
            "outputMarket too small",
            output.value,
            maxOutputWei.value
        );
        assert(output.sign != maxOutputWei.sign);

        _callLiquidateCallbackIfNecessary(
            makerAccount,
            owedMarketId == inputMarketId ? outputMarketId : inputMarketId,
            owedMarketId == inputMarketId ? Types.Wei(output.sign, output.value) : inputWei,
            owedMarketId,
            owedMarketId == inputMarketId ? inputWei : Types.Wei(output.sign, output.value)
        );

        return output;
    }

    function _setExpiry(
        Account.Info memory account,
        uint256 marketId,
        uint32 time
    )
    private
    {
        g_expiries[account.owner][account.number][marketId] = time;
        emit ExpirySet(
            account.owner,
            account.number,
            marketId,
            time
        );
    }

    function _setApproval(
        address approver,
        address sender,
        uint32 minTimeDelta
    )
    private
    {
        g_approvedSender[approver][sender] = minTimeDelta;
        emit LogSenderApproved(approver, sender, minTimeDelta);
    }

    function _heldWeiToOwedWei(
        IDolomiteMargin dolomiteMargin,
        Types.Wei memory heldWei,
        uint256 heldMarketId,
        uint256 owedMarketId,
        uint32 expiry
    )
    private
    view
    returns (Types.AssetAmount memory)
    {
        (
        Monetary.Price memory heldPrice,
        Monetary.Price memory owedPrice
        ) = _getSpreadAdjustedPrices(
            dolomiteMargin,
            heldMarketId,
            owedMarketId,
            expiry
        );

        uint256 owedAmount = Math.getPartialRoundUp(
            heldWei.value,
            heldPrice.value,
            owedPrice.value
        );

        return Types.AssetAmount({
        sign: true,
        denomination: Types.AssetDenomination.Wei,
        ref: Types.AssetReference.Delta,
        value: owedAmount
        });
    }

    function _owedWeiToHeldWei(
        IDolomiteMargin dolomiteMargin,
        Types.Wei memory owedWei,
        uint256 heldMarketId,
        uint256 owedMarketId,
        uint32 expiry
    )
    private
    view
    returns (Types.AssetAmount memory)
    {
        (
        Monetary.Price memory heldPrice,
        Monetary.Price memory owedPrice
        ) = _getSpreadAdjustedPrices(
            dolomiteMargin,
            heldMarketId,
            owedMarketId,
            expiry
        );

        uint256 heldAmount = Math.getPartial(
            owedWei.value,
            owedPrice.value,
            heldPrice.value
        );

        return Types.AssetAmount({
        sign: false,
        denomination: Types.AssetDenomination.Wei,
        ref: Types.AssetReference.Delta,
        value: heldAmount
        });
    }

    function _callLiquidateCallbackIfNecessary(
        Account.Info memory liquidAccount,
        uint heldMarket,
        Types.Wei memory heldDeltaWei,
        uint owedMarket,
        Types.Wei memory owedDeltaWei
    ) private {
        if (liquidAccount.owner.isContract()) {
            // solium-disable-next-line security/no-low-level-calls
            (bool isCallSuccessful, bytes memory result) = liquidAccount.owner.call(
                abi.encodeWithSelector(
                    ILiquidationCallback(liquidAccount.owner).onLiquidate.selector,
                    liquidAccount.number,
                    heldMarket,
                    heldDeltaWei,
                    owedMarket,
                    owedDeltaWei
                )
            );

            if (isCallSuccessful) {
                emit LogLiquidationCallbackSuccess(liquidAccount.owner, liquidAccount.number);
            } else {
                if (result.length < 68) {
                    result = bytes("");
                } else {
                    // solium-disable-next-line security/no-inline-assembly
                    assembly {
                        result := add(result, 0x04)
                    }
                    result = bytes(abi.decode(result, (string)));
                }
                emit LogLiquidationCallbackFailure(
                    liquidAccount.owner,
                    liquidAccount.number,
                    string(result)
                );
            }
        }
    }
}
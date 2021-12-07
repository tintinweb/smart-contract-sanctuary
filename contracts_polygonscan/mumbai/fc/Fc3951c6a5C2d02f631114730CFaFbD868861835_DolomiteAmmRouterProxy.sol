/**
 *Submitted for verification at polygonscan.com on 2021-12-07
*/

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
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
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// File: contracts/protocol/interfaces/IERC20.sol

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
interface IERC20 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply(
    )
    external
    view
    returns (uint256);

    function balanceOf(
        address who
    )
    external
    view
    returns (uint256);

    function allowance(
        address owner,
        address spender
    )
    external
    view
    returns (uint256);

    function transfer(
        address to,
        uint256 value
    )
    external
    returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    )
    external
    returns (bool);

    function approve(
        address spender,
        uint256 value
    )
    external
    returns (bool);

    function name()
    external
    view
    returns (string memory);

    function symbol()
    external
    view
    returns (string memory);

    function decimals()
    external
    view
    returns (uint8);
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
 * Interface that Price Oracles for Solo must implement in order to report prices.
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
    using Cache for MarketCache;

    // ============ Structs ============

    struct MarketInfo {
        bool isClosing;
        uint128 borrowPar;
        Monetary.Price price;
    }

    struct MarketCache {
        MarketInfo[] markets;
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
        markets: new MarketInfo[](numMarkets)
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
        return cache.markets[marketId].price.value != 0;
    }

    function getIsClosing(
        MarketCache memory cache,
        uint256 marketId
    )
    internal
    pure
    returns (bool)
    {
        return cache.markets[marketId].isClosing;
    }

    function getPrice(
        MarketCache memory cache,
        uint256 marketId
    )
    internal
    pure
    returns (Monetary.Price memory)
    {
        return cache.markets[marketId].price;
    }

    function getBorrowPar(
        MarketCache memory cache,
        uint256 marketId
    )
    internal
    pure
    returns (uint128)
    {
        return cache.markets[marketId].borrowPar;
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

// File: contracts/external/lib/TypedSignature.sol

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
 * @title TypedSignature
 * @author dYdX
 *
 * Library to unparse typed signatures
 */
library TypedSignature {

    // ============ Constants ============

    bytes32 constant private FILE = "TypedSignature";

    // prepended message with the length of the signed hash in decimal
    bytes constant private PREPEND_DEC = "\x19Ethereum Signed Message:\n32";

    // prepended message with the length of the signed hash in hexadecimal
    bytes constant private PREPEND_HEX = "\x19Ethereum Signed Message:\n\x20";

    // Number of bytes in a typed signature
    uint256 constant private NUM_SIGNATURE_BYTES = 66;

    // ============ Enums ============

    // Different RPC providers may implement signing methods differently, so we allow different
    // signature types depending on the string prepended to a hash before it was signed.
    enum SignatureType {
        NoPrepend,   // No string was prepended.
        Decimal,     // PREPEND_DEC was prepended.
        Hexadecimal, // PREPEND_HEX was prepended.
        Invalid      // Not a valid type. Used for bound-checking.
    }

    // ============ Functions ============

    /**
     * Gives the address of the signer of a hash. Also allows for the commonly prepended string of
     * '\x19Ethereum Signed Message:\n' + message.length
     *
     * @param  hash               Hash that was signed (does not include prepended message)
     * @param  signatureWithType  Type and ECDSA signature with structure: {32:r}{32:s}{1:v}{1:type}
     * @return                    address of the signer of the hash
     */
    function recover(
        bytes32 hash,
        bytes memory signatureWithType
    )
    internal
    pure
    returns (address)
    {
        Require.that(
            signatureWithType.length == NUM_SIGNATURE_BYTES,
            FILE,
            "Invalid signature length"
        );

        bytes32 r;
        bytes32 s;
        uint8 v;
        uint8 rawSigType;

        /* solium-disable-next-line security/no-inline-assembly */
        assembly {
            r := mload(add(signatureWithType, 0x20))
            s := mload(add(signatureWithType, 0x40))
            let lastSlot := mload(add(signatureWithType, 0x60))
            v := byte(0, lastSlot)
            rawSigType := byte(1, lastSlot)
        }

        Require.that(
            rawSigType < uint8(SignatureType.Invalid),
            FILE,
            "Invalid signature type"
        );

        SignatureType sigType = SignatureType(rawSigType);

        bytes32 signedHash;
        if (sigType == SignatureType.NoPrepend) {
            signedHash = hash;
        } else if (sigType == SignatureType.Decimal) {
            signedHash = keccak256(abi.encodePacked(PREPEND_DEC, hash));
        } else {
            assert(sigType == SignatureType.Hexadecimal);
            signedHash = keccak256(abi.encodePacked(PREPEND_HEX, hash));
        }

        return ecrecover(
            signedHash,
            v,
            r,
            s
        );
    }
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

    // ============ Constants ============

    bytes32 constant FILE = "Token";

    // ============ Library Functions ============

    function balanceOf(
        address token,
        address owner
    )
    internal
    view
    returns (uint256)
    {
        return IERC20(token).balanceOf(owner);
    }

    function allowance(
        address token,
        address owner,
        address spender
    )
    internal
    view
    returns (uint256)
    {
        return IERC20(token).allowance(owner, spender);
    }

    function approve(
        address token,
        address spender,
        uint256 amount
    )
    internal
    {
        IERC20(token).approve(spender, amount);

        Require.that(
            checkSuccess(),
            FILE,
            "Approve failed"
        );
    }

    function approveMax(
        address token,
        address spender
    )
    internal
    {
        approve(
            token,
            spender,
            uint256(-1)
        );
    }

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

        IERC20(token).transfer(to, amount);

        Require.that(
            checkSuccess(),
            FILE,
            "Transfer failed"
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

        IERC20(token).transferFrom(from, to, amount);

        Require.that(
            checkSuccess(),
            FILE,
            "TransferFrom failed"
        );
    }

    // ============ Private Functions ============

    /**
     * Check the return value of the previous function up to 32 bytes. Return true if the previous
     * function returned 0 bytes or 32 bytes that are not all-zero.
     */
    function checkSuccess(
    )
    private
    pure
    returns (bool)
    {
        uint256 returnValue = 0;

        /* solium-disable-next-line security/no-inline-assembly */
        assembly {
        // check number of bytes returned from last function call
            switch returndatasize

            // no bytes returned: assume success
            case 0x0 {
                returnValue := 1
            }

            // 32 bytes returned: check if non-zero
            case 0x20 {
            // copy 32 bytes into scratch space
                returndatacopy(0x0, 0x0, 0x20)

            // load those bytes into returnValue
                returnValue := mload(0x0)
            }

            // not sure what was returned: don't mark as success
            default { }
        }

        return returnValue != 0;
    }
}

// File: openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol

pragma solidity ^0.5.0;

/**
 * @title Helps contracts guard against reentrancy attacks.
 * @author Remco Bloemen <[email protected]π.com>, Eenae <[email protected]>
 * @dev If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
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
            "Unsafe cast to uint128"
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
            "Unsafe cast to uint96"
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
            "Unsafe cast to uint32"
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
 * Library for interacting with the basic structs used in Solo
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
 * Library for managing the interest rate and interest indexes of Solo
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
            value: inputValue.getPartial(index.supply, BASE)
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
            value: input.value.getPartial(BASE, index.supply).to128()
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
 * Interface that Interest Setters for Solo must implement in order to report interest rates.
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
        mapping (uint256 => Types.Par) balances; // Mapping from marketId to principal
        Status status;
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

// File: contracts/external/interfaces/IExpiryV2.sol

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
 * @title IExpiryV2
 * @author Dolomite
 */
contract IExpiryV2 {

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
    returns (
        Monetary.Price memory heldPrice,
        Monetary.Price memory owedPriceAdj
    );

}

// File: contracts/external/interfaces/IDolomiteAmmPair.sol

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



interface IDolomiteAmmPair {

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

    event Mint(address indexed sender, uint amount0Wei, uint amount1Wei);
    event Burn(address indexed sender, uint amount0Wei, uint amount1Wei, address indexed to);
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

    function getReservesWei() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function getReservesPar() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);

    function burn(address to, uint toAccountNumber) external returns (uint amount0Wei, uint amount1Wei);

    function getTradeCost(
        uint256 inputMarketId,
        uint256 outputMarketId,
        Account.Info calldata makerAccount,
        Account.Info calldata takerAccount,
        Types.Par calldata,
        Types.Par calldata,
        Types.Wei calldata inputWei,
        bytes calldata data
    )
    external
    returns (Types.AssetAmount memory);

    function skim(address to, uint toAccountNumber) external;

    function sync() external;

    function initialize(address _token0, address _token1, address _transferProxy) external;
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
 * Functions for reading, writing, and verifying state in Solo
 */
library Storage {
    using Cache for Cache.MarketCache;
    using Storage for Storage.State;
    using Math for uint256;
    using Types for Types.Par;
    using Types for Types.Wei;
    using SafeMath for uint256;

    // ============ Constants ============

    bytes32 constant FILE = "Storage";

    // ============ Structs ============

    // All information necessary for tracking a market
    struct Market {
        // Contract address of the associated ERC20 token
        address token;

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

        // Whether additional borrows are allowed for this market
        bool isClosing;
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

    // The entire storage state of Solo
    struct State {
        // number of markets
        uint256 numMarkets;

        // marketId => Market
        mapping (uint256 => Market) markets;
        mapping (address => uint256) tokenToMarketId;

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
        value: Token.balanceOf(token, address(this))
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
        uint256 marketId
    )
    internal
    view
    returns (Monetary.Price memory)
    {
        IPriceOracle oracle = IPriceOracle(state.markets[marketId].priceOracle);
        Monetary.Price memory price = oracle.getPrice(state.getToken(marketId));
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
        for (uint256 m = 0; m < numMarkets; m++) {
            if (!cache.hasMarket(m)) {
                continue;
            }

            Types.Wei memory userWei = state.getWei(account, m);

            if (userWei.isZero()) {
                continue;
            }

            uint256 assetValue = userWei.value.mul(cache.getPrice(m).value);
            Decimal.D256 memory adjust = Decimal.one();
            if (adjustForLiquidity) {
                adjust = Decimal.onePlus(state.markets[m].marginPremium);
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
                account.number,
                borrowValue.value
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
            account.number,
            marketId
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
            account.number,
            marketId
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
        for (uint256 m = 0; m < numMarkets; m++) {
            if (!cache.hasMarket(m)) {
                continue;
            }
            Types.Par memory par = state.getPar(account, m);
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
     * Arguments that are passed to Solo in an ordered list as part of a single operation.
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
     * Moves tokens from an address to Solo. Can either repay a borrow or provide additional supply.
     */
    struct DepositArgs {
        Types.AssetAmount amount;
        Account.Info account;
        uint256 market;
        address from;
    }

    /*
     * Moves tokens from Solo to another address. Can either borrow tokens or reduce the amount
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
     * This action does not require any token movement since the trade is done internally to Solo.
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
     * This action does not require any token movement since the trade is done internally to Solo.
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
     * Similar to liquidate, but vaporAccounts are accounts that have only negative balances
     * remaining. The arbitrageur pays back the negative asset (owedMarket) of the vaporAccount in
     * exchange for a collateral asset (heldMarket) at a favorable spread. However, since the
     * liquidAccount has no collateral assets, the collateral must come from Solo's excess tokens.
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
        assert(args.actionType == ActionType.Deposit);
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
        assert(args.actionType == ActionType.Withdraw);
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
        assert(args.actionType == ActionType.Transfer);
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
        assert(args.actionType == ActionType.Buy);
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
        assert(args.actionType == ActionType.Sell);
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
        assert(args.actionType == ActionType.Trade);
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
        assert(args.actionType == ActionType.Liquidate);
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
        assert(args.actionType == ActionType.Vaporize);
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
        assert(args.actionType == ActionType.Call);
        return CallArgs({
        account: accounts[args.accountId],
        callee: args.otherAddress,
        data: args.data
        });
    }
}

// File: contracts/external/interfaces/IDolomiteAmmFactory.sol

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



interface IDolomiteAmmFactory {

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function soloMargin() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function getPairInitCode() external pure returns (bytes memory);
    function getPairInitCodeHash() external pure returns (bytes32);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;

}

// File: contracts/external/lib/UniswapV2Library.sol

pragma solidity >=0.5.0;





library UniswapV2Library {
    using SafeMath for uint;

    function getPools(
        address factory,
        address[] memory path
    ) internal pure returns (address[] memory) {
        return getPools(factory, IDolomiteAmmFactory(factory).getPairInitCodeHash(), path);
    }

    function getPools(
        address factory,
        bytes32 initCodeHash,
        address[] memory path
    ) internal pure returns (address[] memory) {
        require(
            path.length >= 2,
            "UniswapV2Library::getPools: INVALID_PATH_LENGTH"
        );

        address[] memory pools = new address[](path.length - 1);
        for (uint i = 0; i < path.length - 1; i++) {
            pools[i] = pairFor(factory, path[i], path[i + 1], initCodeHash);
        }
        return pools;
    }

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        return pairFor(factory, tokenA, tokenB, IDolomiteAmmFactory(factory).getPairInitCodeHash());
    }

    function pairFor(
        address factory,
        address tokenA,
        address tokenB,
        bytes32 initCodeHash
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex"ff",
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                initCodeHash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReservesWei(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint reserveA, uint reserveB) {
        return getReservesWei(factory, IDolomiteAmmFactory(factory).getPairInitCodeHash(), tokenA, tokenB);
    }

    function getReserves(
        address factory,
        bytes32 initCodeHash,
        address tokenA,
        address tokenB
    ) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB, initCodeHash)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function getReservesWei(
        address factory,
        bytes32 initCodeHash,
        address tokenA,
        address tokenB
    ) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IDolomiteAmmPair(pairFor(factory, tokenA, tokenB, initCodeHash)).getReservesWei();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997); // reverts from the 'sub'
        amountIn = numerator.div(denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOutWei(
        address factory,
        uint amountIn,
        address[] memory path
    ) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReservesWei(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOutWei(
        address factory,
        bytes32 initCodeHash,
        uint amountIn,
        address[] memory path
    ) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReservesWei(factory, initCodeHash, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    function getAmountsInWei(
        address factory,
        bytes32 initCodeHash,
        uint amountOut,
        address[] memory path
    ) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReservesWei(factory, initCodeHash, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }

    function getAmountsIn(
        address factory,
        bytes32 initCodeHash,
        uint amountOut,
        address[] memory path
    ) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, initCodeHash, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsInWei(
        address factory,
        uint amountOut,
        address[] memory path
    ) internal view returns (uint[] memory amounts) {
        return getAmountsInWei(factory, IDolomiteAmmFactory(factory).getPairInitCodeHash(), amountOut, path);
    }
}

// File: contracts/protocol/lib/Events.sol

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
 * @title Events
 * @author dYdX
 *
 * Library to parse and emit logs from which the state of all accounts and indexes can be followed
 */
library Events {
    using Types for Types.Wei;
    using Storage for Storage.State;

    // ============ Events ============

    event LogIndexUpdate(
        uint256 indexed market,
        Interest.Index index
    );

    event LogOperation(
        address sender
    );

    event LogDeposit(
        address indexed accountOwner,
        uint256 accountNumber,
        uint256 market,
        BalanceUpdate update,
        address from
    );

    event LogWithdraw(
        address indexed accountOwner,
        uint256 accountNumber,
        uint256 market,
        BalanceUpdate update,
        address to
    );

    event LogTransfer(
        address indexed accountOneOwner,
        uint256 accountOneNumber,
        address indexed accountTwoOwner,
        uint256 accountTwoNumber,
        uint256 market,
        BalanceUpdate updateOne,
        BalanceUpdate updateTwo
    );

    event LogBuy(
        address indexed accountOwner,
        uint256 accountNumber,
        uint256 takerMarket,
        uint256 makerMarket,
        BalanceUpdate takerUpdate,
        BalanceUpdate makerUpdate,
        address exchangeWrapper
    );

    event LogSell(
        address indexed accountOwner,
        uint256 accountNumber,
        uint256 takerMarket,
        uint256 makerMarket,
        BalanceUpdate takerUpdate,
        BalanceUpdate makerUpdate,
        address exchangeWrapper
    );

    event LogTrade(
        address indexed takerAccountOwner,
        uint256 takerAccountNumber,
        address indexed makerAccountOwner,
        uint256 makerAccountNumber,
        uint256 inputMarket,
        uint256 outputMarket,
        BalanceUpdate takerInputUpdate,
        BalanceUpdate takerOutputUpdate,
        BalanceUpdate makerInputUpdate,
        BalanceUpdate makerOutputUpdate,
        address autoTrader
    );

    event LogCall(
        address indexed accountOwner,
        uint256 accountNumber,
        address callee
    );

    event LogLiquidate(
        address indexed solidAccountOwner,
        uint256 solidAccountNumber,
        address indexed liquidAccountOwner,
        uint256 liquidAccountNumber,
        uint256 heldMarket,
        uint256 owedMarket,
        BalanceUpdate solidHeldUpdate,
        BalanceUpdate solidOwedUpdate,
        BalanceUpdate liquidHeldUpdate,
        BalanceUpdate liquidOwedUpdate
    );

    event LogVaporize(
        address indexed solidAccountOwner,
        uint256 solidAccountNumber,
        address indexed vaporAccountOwner,
        uint256 vaporAccountNumber,
        uint256 heldMarket,
        uint256 owedMarket,
        BalanceUpdate solidHeldUpdate,
        BalanceUpdate solidOwedUpdate,
        BalanceUpdate vaporOwedUpdate
    );

    // ============ Structs ============

    struct BalanceUpdate {
        Types.Wei deltaWei;
        Types.Par newPar;
    }

    // ============ Internal Functions ============

    function logIndexUpdate(
        uint256 marketId,
        Interest.Index memory index
    )
    internal
    {
        emit LogIndexUpdate(
            marketId,
            index
        );
    }

    function logOperation()
    internal
    {
        emit LogOperation(msg.sender);
    }

    function logDeposit(
        Storage.State storage state,
        Actions.DepositArgs memory args,
        Types.Wei memory deltaWei
    )
    internal
    {
        emit LogDeposit(
            args.account.owner,
            args.account.number,
            args.market,
            getBalanceUpdate(
                state,
                args.account,
                args.market,
                deltaWei
            ),
            args.from
        );
    }

    function logWithdraw(
        Storage.State storage state,
        Actions.WithdrawArgs memory args,
        Types.Wei memory deltaWei
    )
    internal
    {
        emit LogWithdraw(
            args.account.owner,
            args.account.number,
            args.market,
            getBalanceUpdate(
                state,
                args.account,
                args.market,
                deltaWei
            ),
            args.to
        );
    }

    function logTransfer(
        Storage.State storage state,
        Actions.TransferArgs memory args,
        Types.Wei memory deltaWei
    )
    internal
    {
        emit LogTransfer(
            args.accountOne.owner,
            args.accountOne.number,
            args.accountTwo.owner,
            args.accountTwo.number,
            args.market,
            getBalanceUpdate(
                state,
                args.accountOne,
                args.market,
                deltaWei
            ),
            getBalanceUpdate(
                state,
                args.accountTwo,
                args.market,
                deltaWei.negative()
            )
        );
    }

    function logBuy(
        Storage.State storage state,
        Actions.BuyArgs memory args,
        Types.Wei memory takerWei,
        Types.Wei memory makerWei
    )
    internal
    {
        emit LogBuy(
            args.account.owner,
            args.account.number,
            args.takerMarket,
            args.makerMarket,
            getBalanceUpdate(
                state,
                args.account,
                args.takerMarket,
                takerWei
            ),
            getBalanceUpdate(
                state,
                args.account,
                args.makerMarket,
                makerWei
            ),
            args.exchangeWrapper
        );
    }

    function logSell(
        Storage.State storage state,
        Actions.SellArgs memory args,
        Types.Wei memory takerWei,
        Types.Wei memory makerWei
    )
    internal
    {
        emit LogSell(
            args.account.owner,
            args.account.number,
            args.takerMarket,
            args.makerMarket,
            getBalanceUpdate(
                state,
                args.account,
                args.takerMarket,
                takerWei
            ),
            getBalanceUpdate(
                state,
                args.account,
                args.makerMarket,
                makerWei
            ),
            args.exchangeWrapper
        );
    }

    function logTrade(
        Storage.State storage state,
        Actions.TradeArgs memory args,
        Types.Wei memory inputWei,
        Types.Wei memory outputWei
    )
    internal
    {
        BalanceUpdate[4] memory updates = [
        getBalanceUpdate(
            state,
            args.takerAccount,
            args.inputMarket,
            inputWei.negative()
        ),
        getBalanceUpdate(
            state,
            args.takerAccount,
            args.outputMarket,
            outputWei.negative()
        ),
        getBalanceUpdate(
            state,
            args.makerAccount,
            args.inputMarket,
            inputWei
        ),
        getBalanceUpdate(
            state,
            args.makerAccount,
            args.outputMarket,
            outputWei
        )
        ];

        emit          LogTrade(
            args.takerAccount.owner,
            args.takerAccount.number,
            args.makerAccount.owner,
            args.makerAccount.number,
            args.inputMarket,
            args.outputMarket,
            updates[0],
            updates[1],
            updates[2],
            updates[3],
            args.autoTrader
        );
    }

    function logCall(
        Actions.CallArgs memory args
    )
    internal
    {
        emit LogCall(
            args.account.owner,
            args.account.number,
            args.callee
        );
    }

    function logLiquidate(
        Storage.State storage state,
        Actions.LiquidateArgs memory args,
        Types.Wei memory heldWei,
        Types.Wei memory owedWei
    )
    internal
    {
        BalanceUpdate memory solidHeldUpdate = getBalanceUpdate(
            state,
            args.solidAccount,
            args.heldMarket,
            heldWei.negative()
        );
        BalanceUpdate memory solidOwedUpdate = getBalanceUpdate(
            state,
            args.solidAccount,
            args.owedMarket,
            owedWei.negative()
        );
        BalanceUpdate memory liquidHeldUpdate = getBalanceUpdate(
            state,
            args.liquidAccount,
            args.heldMarket,
            heldWei
        );
        BalanceUpdate memory liquidOwedUpdate = getBalanceUpdate(
            state,
            args.liquidAccount,
            args.owedMarket,
            owedWei
        );

        emit LogLiquidate(
            args.solidAccount.owner,
            args.solidAccount.number,
            args.liquidAccount.owner,
            args.liquidAccount.number,
            args.heldMarket,
            args.owedMarket,
            solidHeldUpdate,
            solidOwedUpdate,
            liquidHeldUpdate,
            liquidOwedUpdate
        );
    }

    function logVaporize(
        Storage.State storage state,
        Actions.VaporizeArgs memory args,
        Types.Wei memory heldWei,
        Types.Wei memory owedWei,
        Types.Wei memory excessWei
    )
    internal
    {
        BalanceUpdate memory solidHeldUpdate = getBalanceUpdate(
            state,
            args.solidAccount,
            args.heldMarket,
            heldWei.negative()
        );
        BalanceUpdate memory solidOwedUpdate = getBalanceUpdate(
            state,
            args.solidAccount,
            args.owedMarket,
            owedWei.negative()
        );
        BalanceUpdate memory vaporOwedUpdate = getBalanceUpdate(
            state,
            args.vaporAccount,
            args.owedMarket,
            owedWei.add(excessWei)
        );

        emit LogVaporize(
            args.solidAccount.owner,
            args.solidAccount.number,
            args.vaporAccount.owner,
            args.vaporAccount.number,
            args.heldMarket,
            args.owedMarket,
            solidHeldUpdate,
            solidOwedUpdate,
            vaporOwedUpdate
        );
    }

    // ============ Private Functions ============

    function getBalanceUpdate(
        Storage.State storage state,
        Account.Info memory account,
        uint256 market,
        Types.Wei memory deltaWei
    )
    private
    view
    returns (BalanceUpdate memory)
    {
        return BalanceUpdate({
        deltaWei: deltaWei,
        newPar: state.getPar(account, market)
        });
    }
}

// File: contracts/protocol/interfaces/ISoloMargin.sol

pragma solidity >=0.5.0;






interface ISoloMargin {

    function getMarketIdByTokenAddress(
        address token
    ) external view returns (uint256);

    function getMarketTokenAddress(
        uint256 marketId
    ) external view returns (address);

    function getMarketCurrentIndex(
        uint256 marketId
    ) external view returns (Interest.Index memory);

    function getAccountPar(
        Account.Info calldata account,
        uint256 marketId
    ) external view returns (Types.Par memory);

    function getAccountWei(
        Account.Info calldata account,
        uint256 marketId
    ) external view returns (Types.Wei memory);

    function operate(
        Account.Info[] calldata accounts,
        Actions.ActionArgs[] calldata actions
    ) external;

    function setOperators(
        Types.OperatorArg[] calldata args
    ) external;

    function getIsLocalOperator(
        address owner,
        address operator
    ) external view returns (bool);

    function getAccountStatus(
        Account.Info calldata account
    ) external view returns (Account.Status);

    function getMarketPrice(
        uint256 marketId
    ) external view returns (Monetary.Price memory);

    function getNumMarkets() external view returns (uint256);

    function getMarginRatio() external view returns (Decimal.D256 memory);

    function getLiquidationSpreadForPair(
        uint256 heldMarketId,
        uint256 owedMarketId
    ) external view returns (Decimal.D256 memory);

}

// File: contracts/external/proxies/DolomiteAmmRouterProxy.sol

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













contract DolomiteAmmRouterProxy is ReentrancyGuard {

    using UniswapV2Library for *;
    using SafeMath for uint;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'DolomiteAmmRouterProxy: EXPIRED');
        _;
    }

    struct ModifyPositionParams {
        uint accountNumber;
        Types.AssetAmount amountIn;
        Types.AssetAmount amountOut;
        address[] tokenPath;
        /// the token to be deposited/withdrawn to/from account number. To not perform any margin deposits or
        /// withdrawals, simply set this to `address(0)`
        address depositToken;
        /// a positive number means funds are deposited to `accountNumber` from accountNumber zero
        /// a negative number means funds are withdrawn from `accountNumber` and moved to accountNumber zero
        bool isPositiveMarginDeposit;
        /// the amount of the margin deposit/withdrawal, in wei
        uint marginDeposit;
        /// the amount of seconds from the time at which the position is opened to expiry. 0 for no expiration
        uint expiryTimeDelta;
    }

    struct ModifyPositionCache {
        ModifyPositionParams params;
        ISoloMargin soloMargin;
        IDolomiteAmmFactory uniswapFactory;
        address account;
        uint[] marketPath;
        uint[] amountsWei;
        uint marginDepositDeltaWei;
    }

    struct PermitSignature {
        bool approveMax;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    ISoloMargin public SOLO_MARGIN;
    IDolomiteAmmFactory public DOLOMITE_AMM_FACTORY;
    address public EXPIRY_V2;

    event MarginPositionOpen(
        address indexed user,
        uint indexed accountIndex,
        address inputToken,
        address outputToken,
        address depositToken,
        Events.BalanceUpdate inputBalanceUpdate, // the amount of borrow amount being sold to purchase collateral
        Events.BalanceUpdate outputBalanceUpdate, // the amount of collateral purchased by the borrowed amount
        Events.BalanceUpdate marginDepositUpdate
    );

    event MarginPositionClose(
        address indexed user,
        uint indexed accountIndex,
        address inputToken,
        address outputToken,
        address withdrawalToken,
        Events.BalanceUpdate inputBalanceUpdate, // the amount of held amount being sold to repay debt
        Events.BalanceUpdate outputBalanceUpdate, // the amount of borrow amount being repaid
        Events.BalanceUpdate marginWithdrawalUpdate
    );

    constructor(
        address soloMargin,
        address dolomiteAmmFactory,
        address expiryV2
    ) public {
        SOLO_MARGIN = ISoloMargin(soloMargin);
        DOLOMITE_AMM_FACTORY = IDolomiteAmmFactory(dolomiteAmmFactory);
        EXPIRY_V2 = expiryV2;
    }

    function addLiquidity(
        address to,
        uint fromAccountNumber,
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMinWei,
        uint amountBMinWei,
        uint deadline
    )
    external
    ensure(deadline)
    returns (uint amountAWei, uint amountBWei, uint liquidity) {
        (amountAWei, amountBWei) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMinWei, amountBMinWei);
        address pair = UniswapV2Library.pairFor(address(DOLOMITE_AMM_FACTORY), tokenA, tokenB);

        {
            Account.Info[] memory accounts = new Account.Info[](2);
            accounts[0] = Account.Info(msg.sender, fromAccountNumber);
            accounts[1] = Account.Info(pair, 0);

            uint marketIdA = SOLO_MARGIN.getMarketIdByTokenAddress(tokenA);
            uint marketIdB = SOLO_MARGIN.getMarketIdByTokenAddress(tokenB);

            Actions.ActionArgs[] memory actions = new Actions.ActionArgs[](2);
            actions[0] = _encodeTransferAction(0, 1, marketIdA, amountAWei);
            actions[1] = _encodeTransferAction(0, 1, marketIdB, amountBWei);
            SOLO_MARGIN.operate(accounts, actions);
        }

        liquidity = IDolomiteAmmPair(pair).mint(to);
    }

    function removeLiquidity(
        address to,
        uint toAccountNumber,
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMinWei,
        uint amountBMinWei,
        uint deadline
    ) public ensure(deadline) returns (uint amountAWei, uint amountBWei) {
        address pair = UniswapV2Library.pairFor(address(DOLOMITE_AMM_FACTORY), tokenA, tokenB);
        // send liquidity to pair
        IDolomiteAmmPair(pair).transferFrom(msg.sender, pair, liquidity);

        (uint amount0Wei, uint amount1Wei) = IDolomiteAmmPair(pair).burn(to, toAccountNumber);
        (address token0,) = UniswapV2Library.sortTokens(tokenA, tokenB);
        (amountAWei, amountBWei) = tokenA == token0 ? (amount0Wei, amount1Wei) : (amount1Wei, amount0Wei);
        require(amountAWei >= amountAMinWei, 'DolomiteAmmRouterProxy::removeLiquidity: INSUFFICIENT_A_AMOUNT');
        require(amountBWei >= amountBMinWei, 'DolomiteAmmRouterProxy::removeLiquidity: INSUFFICIENT_B_AMOUNT');
    }

    function removeLiquidityWithPermit(
        address to,
        uint toAccountNumber,
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMinWei,
        uint amountBMinWei,
        uint deadline,
        PermitSignature memory permit
    ) public returns (uint amountAWei, uint amountBWei) {
        address pair = UniswapV2Library.pairFor(address(DOLOMITE_AMM_FACTORY), tokenA, tokenB);
        uint value = permit.approveMax ? uint(- 1) : liquidity;
        IDolomiteAmmPair(pair).permit(msg.sender, address(this), value, deadline, permit.v, permit.r, permit.s);

        (amountAWei, amountBWei) = removeLiquidity(
            to,
            toAccountNumber,
            tokenA,
            tokenB,
            liquidity,
            amountAMinWei,
            amountBMinWei,
            deadline
        );
    }

    function swapExactTokensForTokensAndModifyPosition(
        ModifyPositionParams memory params,
        uint deadline
    ) public ensure(deadline) {
        _swapExactTokensForTokensAndModifyPosition(
            ModifyPositionCache({
        params : params,
        soloMargin : SOLO_MARGIN,
        uniswapFactory : DOLOMITE_AMM_FACTORY,
        account : msg.sender,
        marketPath : new uint[](0),
        amountsWei : new uint[](0),
        marginDepositDeltaWei : 0
        })
        );
    }

    function swapExactTokensForTokens(
        uint accountNumber,
        uint amountInWei,
        uint amountOutMinWei,
        address[] calldata tokenPath,
        uint deadline
    )
    external
    ensure(deadline) {
        _swapExactTokensForTokensAndModifyPosition(
            ModifyPositionCache({
        params : ModifyPositionParams({
        accountNumber : accountNumber,
        amountIn : _defaultAssetAmount(amountInWei),
        amountOut : _defaultAssetAmount(amountOutMinWei),
        tokenPath : tokenPath,
        depositToken : address(0),
        isPositiveMarginDeposit : false,
        marginDeposit : 0,
        expiryTimeDelta : 0
        }),
        soloMargin : SOLO_MARGIN,
        uniswapFactory : DOLOMITE_AMM_FACTORY,
        account : msg.sender,
        marketPath : new uint[](0),
        amountsWei : new uint[](0),
        marginDepositDeltaWei : 0
        })
        );
    }

    function getParamsForSwapExactTokensForTokens(
        address account,
        uint accountNumber,
        uint amountInWei,
        uint amountOutMinWei,
        address[] calldata tokenPath
    )
    external view returns (Account.Info[] memory, Actions.ActionArgs[] memory) {
        return _getParamsForSwapExactTokensForTokens(
            ModifyPositionCache({
        params : ModifyPositionParams({
        accountNumber : accountNumber,
        amountIn : _defaultAssetAmount(amountInWei),
        amountOut : _defaultAssetAmount(amountOutMinWei),
        tokenPath : tokenPath,
        depositToken : address(0),
        isPositiveMarginDeposit : false,
        marginDeposit : 0,
        expiryTimeDelta : 0
        }),
        soloMargin : SOLO_MARGIN,
        uniswapFactory : DOLOMITE_AMM_FACTORY,
        account : account,
        marketPath : new uint[](0),
        amountsWei : new uint[](0),
        marginDepositDeltaWei : 0
        })
        );
    }

    function swapTokensForExactTokensAndModifyPosition(
        ModifyPositionParams memory params,
        uint deadline
    ) public ensure(deadline) {
        _swapTokensForExactTokensAndModifyPosition(
            ModifyPositionCache({
        params : params,
        soloMargin : SOLO_MARGIN,
        uniswapFactory : DOLOMITE_AMM_FACTORY,
        account : msg.sender,
        marketPath : new uint[](0),
        amountsWei : new uint[](0),
        marginDepositDeltaWei : 0
        })
        );
    }

    function swapTokensForExactTokens(
        uint accountNumber,
        uint amountInMaxWei,
        uint amountOutWei,
        address[] calldata tokenPath,
        uint deadline
    )
    external
    ensure(deadline) {
        _swapTokensForExactTokensAndModifyPosition(
            ModifyPositionCache({
        params : ModifyPositionParams({
        accountNumber : accountNumber,
        amountIn : _defaultAssetAmount(amountInMaxWei),
        amountOut : _defaultAssetAmount(amountOutWei),
        tokenPath : tokenPath,
        depositToken : address(0),
        isPositiveMarginDeposit : false,
        marginDeposit : 0,
        expiryTimeDelta : 0
        }),
        soloMargin : SOLO_MARGIN,
        uniswapFactory : DOLOMITE_AMM_FACTORY,
        account : msg.sender,
        marketPath : new uint[](0),
        amountsWei : new uint[](0),
        marginDepositDeltaWei : 0
        })
        );
    }

    function getParamsForSwapTokensForExactTokens(
        address account,
        uint accountNumber,
        uint amountInMaxWei,
        uint amountOutWei,
        address[] calldata tokenPath
    )
    external view returns (Account.Info[] memory, Actions.ActionArgs[] memory) {
        return _getParamsForSwapTokensForExactTokens(
            ModifyPositionCache({
        params : ModifyPositionParams({
        accountNumber : accountNumber,
        amountIn : _defaultAssetAmount(amountInMaxWei),
        amountOut : _defaultAssetAmount(amountOutWei),
        tokenPath : tokenPath,
        depositToken : address(0),
        isPositiveMarginDeposit : false,
        marginDeposit : 0,
        expiryTimeDelta : 0
        }),
        soloMargin : SOLO_MARGIN,
        uniswapFactory : DOLOMITE_AMM_FACTORY,
        account : account,
        marketPath : new uint[](0),
        amountsWei : new uint[](0),
        marginDepositDeltaWei : 0
        })
        );
    }

    // *************************
    // ***** Internal Functions
    // *************************

    function _swapExactTokensForTokensAndModifyPosition(
        ModifyPositionCache memory cache
    ) internal {
        (
        Account.Info[] memory accounts,
        Actions.ActionArgs[] memory actions
        ) = _getParamsForSwapExactTokensForTokens(cache);

        cache.soloMargin.operate(accounts, actions);

        _logEvents(cache, accounts);
    }

    function _swapTokensForExactTokensAndModifyPosition(
        ModifyPositionCache memory cache
    ) internal {
        (
        Account.Info[] memory accounts,
        Actions.ActionArgs[] memory actions
        ) = _getParamsForSwapTokensForExactTokens(cache);

        cache.soloMargin.operate(accounts, actions);

        _logEvents(cache, accounts);
    }

    function _getParamsForSwapExactTokensForTokens(
        ModifyPositionCache memory cache
    ) internal view returns (
        Account.Info[] memory,
        Actions.ActionArgs[] memory
    ) {
        cache.marketPath = _getMarketPathFromTokenPath(cache);

        // Convert from par to wei, if necessary
        uint amountInWei = _convertAssetAmountToWei(cache.params.amountIn, cache.marketPath[0], cache);

        // Convert from par to wei, if necessary
        uint amountOutMinWei = _convertAssetAmountToWei(cache.params.amountOut, cache.marketPath[cache.marketPath.length - 1], cache);

        // amountsWei[0] == amountInWei
        // amountsWei[amountsWei.length - 1] == amountOutWei
        cache.amountsWei = UniswapV2Library.getAmountsOutWei(address(cache.uniswapFactory), amountInWei, cache.params.tokenPath);
        require(
            cache.amountsWei[cache.amountsWei.length - 1] >= amountOutMinWei,
            "DolomiteAmmRouterProxy::_getParamsForSwapExactTokensForTokens: INSUFFICIENT_OUTPUT_AMOUNT"
        );

        return _getParamsForSwap(cache);
    }

    function _getParamsForSwapTokensForExactTokens(
        ModifyPositionCache memory cache
    ) internal view returns (
        Account.Info[] memory,
        Actions.ActionArgs[] memory
    ) {
        cache.marketPath = _getMarketPathFromTokenPath(cache);

        // Convert from par to wei, if necessary
        uint amountInMaxWei = _convertAssetAmountToWei(cache.params.amountIn, cache.marketPath[0], cache);

        // Convert from par to wei, if necessary
        uint amountOutWei = _convertAssetAmountToWei(cache.params.amountOut, cache.marketPath[cache.marketPath.length - 1], cache);

        // cache.amountsWei[0] == amountInWei
        // cache.amountsWei[amountsWei.length - 1] == amountOutWei
        cache.amountsWei = UniswapV2Library.getAmountsInWei(address(cache.uniswapFactory), amountOutWei, cache.params.tokenPath);
        require(
            cache.amountsWei[0] <= amountInMaxWei,
            "DolomiteAmmRouterProxy::_getParamsForSwapTokensForExactTokens: EXCESSIVE_INPUT_AMOUNT"
        );

        return _getParamsForSwap(cache);
    }

    function _getParamsForSwap(
        ModifyPositionCache memory cache
    ) internal view returns (
        Account.Info[] memory,
        Actions.ActionArgs[] memory
    ) {
        require(
            cache.params.amountIn.ref == Types.AssetReference.Delta && cache.params.amountOut.ref == Types.AssetReference.Delta,
            "DolomiteAmmRouterProxy::_getParamsForSwap: INVALID_ASSET_REFERENCE"
        );

        // pools.length == cache.params.tokenPath.length - 1
        address[] memory pools = UniswapV2Library.getPools(address(cache.uniswapFactory), cache.params.tokenPath);

        Account.Info[] memory accounts = _getAccountsForModifyPosition(cache, pools);
        Actions.ActionArgs[] memory actions = _getActionArgsForModifyPosition(cache, accounts, pools);

        if (cache.params.depositToken != address(0) && cache.params.marginDeposit == uint(- 1)) {
            uint expiryActionCount = cache.params.expiryTimeDelta == 0 ? 0 : 1;
            uint marketId = actions[actions.length - 1 - expiryActionCount].primaryMarketId;
            if (cache.params.isPositiveMarginDeposit) {
                // the marginDeposit is equal to the amount of `marketId` in account 0 (which is at accounts.length - 1)
                cache.marginDepositDeltaWei = cache.soloMargin.getAccountWei(accounts[accounts.length - 1], marketId).value;
            } else {
                uint amountOutWeiFromAccount = cache.marketPath[0] == marketId ? cache.amountsWei[0] : cache.amountsWei[cache.amountsWei.length - 1];
                if (cache.marketPath[0] == marketId) {
                    // the trade downsizes the potential withdrawal
                    cache.marginDepositDeltaWei = cache.soloMargin.getAccountWei(accounts[0], marketId).value.sub(cache.amountsWei[0]);
                } else if (cache.marketPath[cache.marketPath.length - 1] == marketId) {
                    // the trade upsizes the withdrawal
                    cache.marginDepositDeltaWei = cache.soloMargin.getAccountWei(accounts[0], marketId).value.add(cache.amountsWei[cache.amountsWei.length - 1]);
                } else {
                    // the trade doesn't impact the withdrawal
                    cache.marginDepositDeltaWei = cache.soloMargin.getAccountWei(accounts[0], marketId).value;
                }
            }
        } else {
            cache.marginDepositDeltaWei = cache.params.marginDeposit;
        }

        return (accounts, actions);
    }

    function _getMarketPathFromTokenPath(
        ModifyPositionCache memory cache
    ) internal view returns (uint[] memory) {
        uint[] memory marketPath = new uint[](cache.params.tokenPath.length);
        for (uint i = 0; i < cache.params.tokenPath.length; i++) {
            marketPath[i] = cache.soloMargin.getMarketIdByTokenAddress(cache.params.tokenPath[i]);
        }
        return marketPath;
    }

    function _encodeTransferAction(
        uint fromAccountIndex,
        uint toAccountIndex,
        uint marketId,
        uint amount
    ) internal pure returns (Actions.ActionArgs memory) {
        Types.AssetAmount memory assetAmount;
        if (amount == uint(- 1)) {
            assetAmount = Types.AssetAmount(true, Types.AssetDenomination.Wei, Types.AssetReference.Target, 0);
        } else {
            assetAmount = Types.AssetAmount(false, Types.AssetDenomination.Wei, Types.AssetReference.Delta, amount);
        }
        return Actions.ActionArgs({
        actionType : Actions.ActionType.Transfer,
        accountId : fromAccountIndex,
        amount : assetAmount,
        primaryMarketId : marketId,
        secondaryMarketId : uint(- 1),
        otherAddress : address(0),
        otherAccountId : toAccountIndex,
        data : bytes("")
        });
    }

    function _encodeExpirationAction(
        ModifyPositionParams memory params,
        Account.Info memory account,
        uint accountIndex,
        uint owedMarketId
    ) internal view returns (Actions.ActionArgs memory) {
        require(
            params.expiryTimeDelta == uint32(params.expiryTimeDelta),
            "DolomiteAmmRouterProxy::_encodeExpirationAction: INVALID_EXPIRY_TIME"
        );

        IExpiryV2.SetExpiryArg[] memory expiryArgs = new IExpiryV2.SetExpiryArg[](1);
        expiryArgs[0] = IExpiryV2.SetExpiryArg({
        account : account,
        marketId : owedMarketId,
        timeDelta : uint32(params.expiryTimeDelta),
        forceUpdate : true
        });

        return Actions.ActionArgs({
        actionType : Actions.ActionType.Call,
        accountId : accountIndex,
        amount : Types.AssetAmount(true, Types.AssetDenomination.Wei, Types.AssetReference.Delta, 0),
        primaryMarketId : uint(- 1),
        secondaryMarketId : uint(- 1),
        otherAddress : EXPIRY_V2,
        otherAccountId : uint(- 1),
        data : abi.encode(IExpiryV2.CallFunctionType.SetExpiry, expiryArgs)
        });
    }

    function _encodeTradeAction(
        uint fromAccountIndex,
        uint toAccountIndex,
        uint primaryMarketId,
        uint secondaryMarketId,
        address traderAddress,
        uint amountInWei,
        uint amountOutWei
    ) internal pure returns (Actions.ActionArgs memory) {
        return Actions.ActionArgs({
        actionType : Actions.ActionType.Trade,
        accountId : fromAccountIndex,
        amount : Types.AssetAmount(true, Types.AssetDenomination.Wei, Types.AssetReference.Delta, amountInWei),
        primaryMarketId : primaryMarketId,
        secondaryMarketId : secondaryMarketId,
        otherAddress : traderAddress,
        otherAccountId : toAccountIndex,
        data : abi.encode(amountOutWei)
        });
    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesiredWei,
        uint amountBDesiredWei,
        uint amountAMinWei,
        uint amountBMinWei
    ) internal returns (uint amountAWei, uint amountBWei) {
        IDolomiteAmmFactory dolomiteAmmFactory = DOLOMITE_AMM_FACTORY;
        // create the pair if it doesn't exist yet
        if (dolomiteAmmFactory.getPair(tokenA, tokenB) == address(0)) {
            dolomiteAmmFactory.createPair(tokenA, tokenB);
        }
        (uint reserveAWei, uint reserveBWei) = UniswapV2Library.getReservesWei(address(dolomiteAmmFactory), tokenA, tokenB);
        if (reserveAWei == 0 && reserveBWei == 0) {
            (amountAWei, amountBWei) = (amountADesiredWei, amountBDesiredWei);
        } else {
            uint amountBOptimal = UniswapV2Library.quote(amountADesiredWei, reserveAWei, reserveBWei);
            if (amountBOptimal <= amountBDesiredWei) {
                require(amountBOptimal >= amountBMinWei, 'DolomiteAmmRouterProxy::_addLiquidity: INSUFFICIENT_B_AMOUNT');
                (amountAWei, amountBWei) = (amountADesiredWei, amountBOptimal);
            } else {
                uint amountAOptimal = UniswapV2Library.quote(amountBDesiredWei, reserveBWei, reserveAWei);
                assert(amountAOptimal <= amountADesiredWei);
                require(amountAOptimal >= amountAMinWei, 'DolomiteAmmRouterProxy::_addLiquidity: INSUFFICIENT_A_AMOUNT');
                (amountAWei, amountBWei) = (amountAOptimal, amountBDesiredWei);
            }
        }
    }

    function _getAccountsForModifyPosition(
        ModifyPositionCache memory cache,
        address[] memory pools
    ) internal pure returns (Account.Info[] memory) {
        Account.Info[] memory accounts;
        if (cache.params.depositToken == address(0)) {
            accounts = new Account.Info[](1 + pools.length);
        } else {
            accounts = new Account.Info[](2 + pools.length);
            accounts[accounts.length - 1] = Account.Info(cache.account, 0);
        }

        accounts[0] = Account.Info(cache.account, cache.params.accountNumber);

        for (uint i = 0; i < pools.length; i++) {
            accounts[i + 1] = Account.Info(pools[i], 0);
        }

        return accounts;
    }

    function _getActionArgsForModifyPosition(
        ModifyPositionCache memory cache,
        Account.Info[] memory accounts,
        address[] memory pools
    ) internal view returns (Actions.ActionArgs[] memory) {
        Actions.ActionArgs[] memory actions;
        if (cache.params.depositToken == address(0)) {
            actions = new Actions.ActionArgs[](pools.length);
        } else {
            require(
                cache.params.marginDeposit != 0,
                "DolomiteAmmRouterProxy::_getActionArgsForModifyPosition: INVALID_MARGIN_DEPOSIT"
            );

            uint expiryActionCount = cache.params.expiryTimeDelta == 0 ? 0 : 1;
            actions = new Actions.ActionArgs[](pools.length + 1 + expiryActionCount);

            // `accountNumber` `0` is at index `accountsLength - 1`

            bool isWithdrawal = !cache.params.isPositiveMarginDeposit;
            actions[actions.length - 1 - expiryActionCount] = _encodeTransferAction(
                isWithdrawal ? 0 : accounts.length - 1 /* from */,
                isWithdrawal ? accounts.length - 1 : 0 /* to */,
                cache.soloMargin.getMarketIdByTokenAddress(cache.params.depositToken),
                cache.params.marginDeposit
            );
            if (expiryActionCount == 1) {
                actions[actions.length - 1] = _encodeExpirationAction(
                    cache.params,
                    accounts[0],
                    0,
                    cache.marketPath[0] /* the market at index 0 is being borrowed and traded */
                );
            }
        }

        for (uint i = 0; i < pools.length; i++) {
            require(
                accounts[i + 1].owner == pools[i],
                "DolomiteAmmRouterProxy::_getActionArgsForModifyPosition: INVALID_OTHER_ADDRESS"
            );
            actions[i] = _encodeTradeAction(
                0,
                i + 1,
                cache.marketPath[i],
                cache.marketPath[i + 1],
                pools[i],
                cache.amountsWei[i],
                cache.amountsWei[i + 1]
            );
        }

        return actions;
    }

    function _defaultAssetAmount(uint value) internal pure returns (Types.AssetAmount memory) {
        return Types.AssetAmount({
        sign : true,
        denomination : Types.AssetDenomination.Wei,
        ref : Types.AssetReference.Delta,
        value : value
        });
    }

    function _convertAssetAmountToWei(
        Types.AssetAmount memory amount,
        uint marketId,
        ModifyPositionCache memory cache
    ) internal view returns (uint) {
        if (amount.denomination == Types.AssetDenomination.Wei) {
            return amount.value;
        } else {
            require(
                uint128(amount.value) == amount.value,
                "DolomiteAmmRouterProxy::_convertAssetAmountToWei: INVALID_VALUE"
            );
            return Interest.parToWei(
                Types.Par({sign : amount.sign, value : uint128(amount.value)}),
                cache.soloMargin.getMarketCurrentIndex(marketId)
            ).value;
        }
    }

    function _logEvents(
        ModifyPositionCache memory cache,
        Account.Info[] memory accounts
    ) internal {
        if (cache.params.isPositiveMarginDeposit && cache.params.accountNumber > 0) {
            Types.Par memory newOutputPar = cache.soloMargin.getAccountPar(
                accounts[0],
                cache.marketPath[cache.marketPath.length - 1]
            );

            emit MarginPositionOpen(
                msg.sender,
                cache.params.accountNumber,
                cache.params.tokenPath[0],
                cache.params.tokenPath[cache.params.tokenPath.length - 1],
                cache.params.depositToken,
                Events.BalanceUpdate({
            deltaWei : Types.Wei(false, cache.amountsWei[0]),
            newPar : cache.soloMargin.getAccountPar(accounts[0], cache.marketPath[0])
            }),
                Events.BalanceUpdate({
            deltaWei : Types.Wei(true, cache.amountsWei[cache.amountsWei.length - 1]),
            newPar : newOutputPar
            }),
                Events.BalanceUpdate({
            deltaWei : Types.Wei(true, cache.params.marginDeposit),
            newPar : newOutputPar
            })
            );
        } else if (cache.params.accountNumber > 0) {
            Types.Par memory newInputPar = cache.soloMargin.getAccountPar(accounts[0], cache.marketPath[0]);

            emit MarginPositionClose(
                msg.sender,
                cache.params.accountNumber,
                cache.params.tokenPath[0],
                cache.params.tokenPath[cache.params.tokenPath.length - 1],
                cache.params.depositToken,
                Events.BalanceUpdate({
            deltaWei : Types.Wei(false, cache.amountsWei[0]),
            newPar : newInputPar
            }),
                Events.BalanceUpdate({
            deltaWei : Types.Wei(true, cache.amountsWei[cache.amountsWei.length - 1]),
            newPar : _getOutputPar(cache, accounts[0])
            }),
                Events.BalanceUpdate({
            deltaWei : Types.Wei(false, cache.params.marginDeposit),
            newPar : newInputPar
            })
            );
        }
    }

    function _getOutputPar(
        ModifyPositionCache memory cache,
        Account.Info memory account
    ) internal view returns (Types.Par memory) {
        return cache.soloMargin.getAccountPar(
            account,
            cache.marketPath[cache.marketPath.length - 1]
        );
    }

}
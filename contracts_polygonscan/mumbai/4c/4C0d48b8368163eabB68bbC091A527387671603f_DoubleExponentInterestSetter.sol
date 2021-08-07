/**
 *Submitted for verification at polygonscan.com on 2021-08-07
*/

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
pragma experimental ABIEncoderV2;




/**
 * @title Types
 * @author dYdX
 *
 * Library for interacting with the basic structs used in Solo
 */
library Types {
    using Math for uint256;

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
     * then prorated the across all suppliers.
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

// File: contracts/external/interestsetters/DoubleExponentInterestSetter.sol

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
 * @title DoubleExponentInterestSetter
 * @author dYdX
 *
 * Interest setter that sets interest based on a polynomial of the usage percentage of the market.
 * Interest = C_0 + C_1 * U^(2^0) + C_2 * U^(2^1) + C_3 * U^(2^2) ...
 */
contract DoubleExponentInterestSetter is
    IInterestSetter
{
    using Math for uint256;
    using SafeMath for uint256;

    // ============ Constants ============

    uint256 constant PERCENT = 100;

    uint256 constant BASE = 10 ** 18;

    uint256 constant SECONDS_IN_A_YEAR = 60 * 60 * 24 * 365;

    uint256 constant BYTE = 8;

    // ============ Structs ============

    struct PolyStorage {
        uint128 maxAPR;
        uint128 coefficients;
    }

    // ============ Storage ============

    PolyStorage g_storage;

    // ============ Constructor ============

    constructor(
        PolyStorage memory params
    )
        public
    {
        // verify that all coefficients add up to 100%
        uint256 sumOfCoefficients = 0;
        for (
            uint256 coefficients = params.coefficients;
            coefficients != 0;
            coefficients >>= BYTE
        ) {
            sumOfCoefficients += coefficients % 256;
        }
        require(
            sumOfCoefficients == PERCENT,
            "Coefficients must sum to 100"
        );

        // store the params
        g_storage = params;
    }

    // ============ Public Functions ============

    /**
     * Get the interest rate given some borrowed and supplied amounts. The interest function is a
     * polynomial function of the utilization (borrowWei / supplyWei) of the market.
     *
     *   - If borrowWei > supplyWei then the utilization is considered to be equal to 1.
     *   - If both are zero, then the utilization is considered to be equal to 0.
     *
     * @return The interest rate per second (times 10 ** 18)
     */
    function getInterestRate(
        address /* token */,
        uint256 borrowWei,
        uint256 supplyWei
    )
        external
        view
        returns (Interest.Rate memory)
    {
        if (borrowWei == 0) {
            return Interest.Rate({
                value: 0
            });
        }

        PolyStorage memory s = g_storage;
        uint256 maxAPR = s.maxAPR;

        if (borrowWei >= supplyWei) {
            return Interest.Rate({
                value: maxAPR / SECONDS_IN_A_YEAR
            });
        }

        // process the first coefficient
        uint256 coefficients = s.coefficients;
        uint256 result = uint8(coefficients) * BASE;
        coefficients >>= BYTE;

        // initialize polynomial as the utilization
        // no safeDiv since supplyWei must be non-zero at this point
        uint256 polynomial = BASE.mul(borrowWei) / supplyWei;

        // for each non-zero coefficient...
        while (true) {
            // gets the lowest-order byte
            uint256 coefficient = uint256(uint8(coefficients));

            // if non-zero, add to result
            if (coefficient != 0) {
                // no safeAdd since there are at most 16 coefficients
                // no safeMul since (coefficient < 256 && polynomial <= 10**18)
                result += coefficient * polynomial;

                // break if this is the last non-zero coefficient
                if (coefficient == coefficients) {
                    break;
                }
            }

            // double the order of the polynomial term
            // no safeMul since polynomial <= 10^18
            // no safeDiv since the divisor is a non-zero constant
            polynomial = polynomial * polynomial / BASE;

            // move to next coefficient
            coefficients >>= BYTE;
        }

        // normalize the result
        // no safeMul since result fits within 72 bits and maxAPR fits within 128 bits
        // no safeDiv since the divisor is a non-zero constant
        return Interest.Rate({
            value: result * maxAPR / (SECONDS_IN_A_YEAR * BASE * PERCENT)
        });
    }

    /**
     * Get the maximum APR that this interestSetter will return. The actual APY may be higher
     * depending on how often the interest is compounded.
     *
     * @return The maximum APR
     */
    function getMaxAPR()
        external
        view
        returns (uint256)
    {
        return g_storage.maxAPR;
    }

    /**
     * Get all of the coefficients of the interest calculation, starting from the coefficient for
     * the first-order utilization variable.
     *
     * @return The coefficients
     */
    function getCoefficients()
        external
        view
        returns (uint256[] memory)
    {
        // allocate new array with maximum of 16 coefficients
        uint256[] memory result = new uint256[](16);

        // add the coefficients to the array
        uint256 numCoefficients = 0;
        for (
            uint256 coefficients = g_storage.coefficients;
            coefficients != 0;
            coefficients >>= BYTE
        ) {
            result[numCoefficients] = coefficients % 256;
            numCoefficients++;
        }

        // modify result.length to match numCoefficients
        /* solium-disable-next-line security/no-inline-assembly */
        assembly {
            mstore(result, numCoefficients)
        }

        return result;
    }
}
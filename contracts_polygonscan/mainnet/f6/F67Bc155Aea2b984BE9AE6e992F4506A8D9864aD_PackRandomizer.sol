/**
 *Submitted for verification at polygonscan.com on 2021-09-11
*/

// Sources flattened with hardhat v2.6.1 https://hardhat.org

// File @openzeppelin/contracts/utils/math/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


// File contracts/PackRandomizer.sol

pragma solidity ^0.8.0;

abstract contract Factory {
    function transferFrom(address _owner, address _toAddress, uint256 tokenId) virtual external;
}

/**
 * @title PackRandomizer
 * PackRandomizer- support for a randomized and openable pack.
 */
library PackRandomizer {
    using SafeMath for uint256;

    // Event for logging pack openings
    event PackOpened(uint256 indexed packTokenId, address indexed owner, address indexed buyer, uint256[5] tokenIds);
    event Warning(string message, address account);

    struct OptionSettings {
        // Probability in basis points (out of 10,000) of receiving each class (descending)
        // "QB", "RB", "WR", "TE", "DST"
        uint16[] classProbabilities;
    }

    struct PackRandomizerState {
        address factoryAddress;
        uint256 numClasses;
        OptionSettings optionToSettings;
        mapping(uint256 => uint256[]) classToTokenIds;
        uint256 seed;
    }

    function initState(
        PackRandomizerState storage _state,
        address _factoryAddress,
        uint256 _numClasses,
        uint256 _seed
    ) public {
        _state.factoryAddress = _factoryAddress;
        _state.numClasses = _numClasses;
        _state.seed = _seed;
    }

    /**
     * Alternate way to add token ids to a class
     * Note: resets the full list for the class instead of adding each token id
     */
    function setTokenIdsForClass(
        PackRandomizerState storage _state,
        uint256 _classId,
        uint256[] memory _tokenIds
    ) public {
        require(_classId < _state.numClasses, "_class out of range");
        _state.classToTokenIds[_classId] = _tokenIds;
    }

    /**
     * Set the settings for a particular pack option
     * @param _classProbabilities Array of probabilities (basis points, so integers out of 10,000)
     *                            of receiving each class (the index in the array).
     *                            Should add up to 10k and be descending in value.
     */
    function setOptionSettings(
        PackRandomizerState storage _state,
        uint16[] memory _classProbabilities
    ) public {
        _state.optionToSettings = OptionSettings({
            classProbabilities : _classProbabilities
            });
    }

    /**
     * Improve pseudorandom number generator by letting the owner set the seed manually,
     * making attacks more difficult
     * @param _newSeed The new seed to use for the next transac tion
     */
    function setSeed(
        PackRandomizerState storage _state,
        uint256 _newSeed
    ) public {
        _state.seed = _newSeed;
    }

    ///////
    // MAIN FUNCTIONS
    //////

    /**
     * Transfer 5 tokens that are passed in, assumes QB in the first spot
     */
    function distribute(
        address _factoryAddress,
        uint256 _packTokenId,
        address _toAddress,
        address _owner,
        uint256[5] memory tokenIds
    ) internal {
        Factory factory = Factory(_factoryAddress);
        // QB
        uint256 qbTokenId = tokenIds[0];
        factory.transferFrom(_owner, _toAddress, qbTokenId);
        // RB
        uint256 rbTokenId = tokenIds[1];
        factory.transferFrom(_owner, _toAddress, rbTokenId);
        // WR
        uint256 wrTokenId = tokenIds[2];
        factory.transferFrom(_owner, _toAddress, wrTokenId);
        // TE
        uint256 teTokenId = tokenIds[3];
        factory.transferFrom(_owner, _toAddress, teTokenId);
        // DEF
        uint256 defTokenId = tokenIds[4];
        factory.transferFrom(_owner, _toAddress, defTokenId);
        // Emit pack opened event
        emit PackOpened(_packTokenId, _owner, _toAddress, [qbTokenId, rbTokenId, wrTokenId, teTokenId, defTokenId]);
    }

    /////
    // HELPER FUNCTIONS
    /////

    // Returns the tokenId sent to _toAddress
    function _sendTokenWithClass(
        PackRandomizerState storage _state,
        uint256 _classId,
        address _toAddress,
        address _owner
    ) internal returns (uint256) {
        require(_classId < _state.numClasses, "_class out of range");

        Factory factory = Factory(_state.factoryAddress);

        // Assumes we have pre-minted tokenIds and associated them to the class to be drawn
        uint256[] memory tokenIds = _state.classToTokenIds[_classId];

        require(tokenIds.length > 0, "No token ids for _classId");

        uint256 randomIndex = _random(_state).mod(tokenIds.length);
        uint256 tokenId = _state.classToTokenIds[_classId][randomIndex];

        factory.transferFrom(_owner, _toAddress, tokenId);

        return tokenId;
    }

    /**
     * Pseudo-random number generator
     * NOTE: to improve randomness, generate it with an oracle, e.g, Chainlink VRFConsumerBase
     */
    function _random(PackRandomizerState storage _state) internal returns (uint256) {
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender, _state.seed)));
        _state.seed = randomNumber;
        return randomNumber;
    }

    function _addTokenIdToClass(PackRandomizerState storage _state, uint256 _classId, uint256 _tokenId) internal {
        // This is called by code that has already checked this, sometimes in a
        // loop, so don't pay the gas cost of checking this here.
        //require(_classId < _state.numClasses, "_class out of range");
        _state.classToTokenIds[_classId].push(_tokenId);
    }
}
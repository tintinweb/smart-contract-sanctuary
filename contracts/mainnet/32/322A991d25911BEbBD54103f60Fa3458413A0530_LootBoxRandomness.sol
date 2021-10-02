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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";

abstract contract Factory {
    function balanceOf(uint256 _tokenId, uint256 _optionId)
        public
        view
        virtual
        returns (bool);
}

library LootBoxRandomness {
    using SafeMath for uint256;

    // Event for logging lootbox opens
    event LootBoxOpened(
        uint256 indexed optionId,
        address indexed buyer,
        uint256 boxesPurchased,
        uint256 itemsMinted
    );
    event Warning(string message, address account);

    uint256 constant INVERSE_BASIS_POINT = 10000;

    struct OptionSettings {
        uint256 maxQuantityPerOpen;
        uint256[] classProbabilities;
        bool hasGuaranteedClasses;
        uint256[] guarantees;
    }

    struct LootBoxRandomnessState {
        address factoryAddress;
        uint256 numOptions;
        uint256 numClasses;
        uint256 numBox;
        mapping(uint256 => OptionSettings) optionToSettings;
        mapping(uint256 => mapping(uint256 => uint256)) classToTokenIds;
        uint256 seed;
    }

    function initState(
        LootBoxRandomnessState storage _state,
        address _factoryAddress,
        uint256 _numOptions,
        uint256 _numClasses,
        uint256 _numBox,
        uint256 _seed
    ) public {
        _state.factoryAddress = _factoryAddress;
        _state.numOptions = _numOptions;
        _state.numClasses = _numClasses;
        _state.numBox = _numBox;
        _state.seed = _seed;
    }

    function setTokenIdsForClass(
        LootBoxRandomnessState storage _state,
        uint256 _boxId,
        uint256 _classId,
        uint256 _tokenIds
    ) public {
        require(_boxId < _state.numBox, "Box out of range");
        require(_classId < _state.numClasses, "_class out of range");
        _state.classToTokenIds[_boxId][_classId] = _tokenIds;
    }

    function getTokenIdsForClass(
        LootBoxRandomnessState storage _state,
        uint256 _boxId,
        uint256 _classId
    ) public view returns (uint256) {
        require(_boxId < _state.numBox, "Box out of range");
        require(_classId < _state.numClasses, "_class out of range");
        return _state.classToTokenIds[_boxId][_classId];
    }

    function setOptionSettings(
        LootBoxRandomnessState storage _state,
        uint256 _option,
        uint256 _maxQuantityPerOpen,
        uint256[] memory _classProbabilities,
        uint256[] memory _guarantees
    ) public {
        require(_option < _state.numOptions, "_option out of range");

        bool hasGuaranteedClasses = false;
        for (uint256 i = 0; i < _guarantees.length; i++) {
            if (_guarantees[i] > 0) {
                hasGuaranteedClasses = true;
            }
        }

        OptionSettings memory settings = OptionSettings({
            maxQuantityPerOpen: _maxQuantityPerOpen,
            classProbabilities: _classProbabilities,
            hasGuaranteedClasses: hasGuaranteedClasses,
            guarantees: _guarantees
        });

        _state.optionToSettings[uint256(_option)] = settings;
    }

    function getQuantityPerOpen(
        LootBoxRandomnessState storage _state,
        uint256 _option
    ) public view returns (uint256) {
        require(_option < _state.numOptions, "_option out of range");

        return _state.optionToSettings[uint256(_option)].maxQuantityPerOpen;
    }

    function getQuantityGarantee(
        LootBoxRandomnessState storage _state,
        uint256 _option,
        uint256 classId
    ) public view returns (uint256) {
        require(_option < _state.numOptions, "_option out of range");

        return _state.optionToSettings[uint256(_option)].guarantees[classId];
    }

    function setSeed(LootBoxRandomnessState storage _state, uint256 _newSeed)
        public
    {
        _state.seed = _newSeed;
    }

    function _normalMint(
        LootBoxRandomnessState storage _state,
        uint256 _optionId,
        uint256 _boxNum
    ) internal returns (uint256 _tokenId, uint256 _classId) {
        require(_optionId < _state.numOptions, "_option out of range");
        require(_boxNum < _state.numBox, "_boxNum out of range");
        // Load settings for this box option
        OptionSettings memory settings = _state.optionToSettings[_optionId];

        require(
            settings.maxQuantityPerOpen > 0,
            "LootBoxRandomness#_mint: OPTION_NOT_ALLOWED"
        );

        _classId = (_pickRandomClass(_state, settings.classProbabilities));
        _tokenId = _sendTokenWithClass(_state, _boxNum, _classId);
        
        return (_tokenId, _classId);
    }

    function _mint(
        LootBoxRandomnessState storage _state,
        uint256 _optionId,
        uint256 _randClassId,
        bool hasGuaranteed,
        uint256 _boxNum
    ) internal returns (uint256 _tokenId, uint256 _classId) {
        require(_optionId < _state.numOptions, "_option out of range");
        require(_boxNum < _state.numBox, "_boxNum out of range");
        // Load settings for this box option
        OptionSettings memory settings = _state.optionToSettings[_optionId];

        require(
            settings.maxQuantityPerOpen > 0,
            "LootBoxRandomness#_mint: OPTION_NOT_ALLOWED"
        );

        if (hasGuaranteed) {
            uint256 randClass = _pickRandomClass(_state, settings.classProbabilities);
            if (randClass > _randClassId) {
                _classId = (randClass);
            } else {
                _classId = (_randClassId);
            }
            _tokenId = _sendTokenWithClass(
                _state,
                _boxNum,
                _classId
            );
        } else {
            _classId = (_pickRandomClass(_state, settings.classProbabilities));
            _tokenId = _sendTokenWithClass(_state, _boxNum, _classId);
        }
        
        return (_tokenId, _classId);
    }

    function _sendTokenWithClass(
        LootBoxRandomnessState storage _state,
        uint256 _boxNum,
        uint256 _classId
    ) internal returns (uint256) {
        require(_classId < _state.numClasses, "_class out of range");
        uint256 tokenId = _pickRandomAvailableTokenIdForClass(
            _state,
            _boxNum,
            _classId
        );
        return tokenId;
    }

    function _pickRandomClass(
        LootBoxRandomnessState storage _state,
        uint256[] memory _classProbabilities
    ) public returns (uint256) {
        uint256 value = uint256(_random(_state).mod(INVERSE_BASIS_POINT));
        for (uint256 i = uint256(_classProbabilities.length) - 1; i > 0; i--) {
            uint256 probability = _classProbabilities[i];
            if (value < probability) {
                return i;
            } else {
                value = value - probability;
            }
        }
        return 0;
    }

    function _pickRandomAvailableTokenIdForClass(
        LootBoxRandomnessState storage _state,
        uint256 _boxNum,
        uint256 _classId
    ) internal returns (uint256) {
        require(_classId < _state.numClasses, "_class out of range");
        uint256 tokenIds = _state.classToTokenIds[_boxNum][_classId];
        require(tokenIds > 0, "No token ids for _classId");
        uint256 randIndex = _random(_state).mod(tokenIds);
        Factory factory = Factory(_state.factoryAddress);
        for (uint256 i = randIndex; i < randIndex + tokenIds; i++) {
            uint256 tokenId = i % tokenIds;
            if (factory.balanceOf(tokenId, _boxNum)) {
                return tokenId;
            }
        }
        revert(
            "LootBoxRandomness#_pickRandomAvailableTokenIdForClass: NOT_ENOUGH_TOKENS_FOR_CLASS"
        );
    }

    function _random(LootBoxRandomnessState storage _state)
        internal
        returns (uint256)
    {
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    blockhash(block.number - 1),
                    msg.sender,
                    _state.seed
                )
            )
        );
        _state.seed = randomNumber;
        return randomNumber;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 20
  },
  "evmVersion": "london",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}
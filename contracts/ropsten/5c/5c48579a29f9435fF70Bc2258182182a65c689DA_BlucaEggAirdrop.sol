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

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./BlucaEggFactory.sol";

contract BlucaEggAirdrop is BlucaEggFactory {
    using SafeMath for uint256;

    constructor() {}

    mapping(address => AirdropEggDetail) whitelistEggDetail;
    mapping(address => bool) isWhiteList;

    struct AirdropEggDetail {
        uint8 rarity;
        uint8 element;
        uint256 id;
        string tokenUri;
    }

    modifier onlyAirdropWhitelist(address _address) {
        require(isWhiteList[_address]);
        _;
    }

    function setWhitelist(
        address[] memory _addresses,
        uint8[] memory _rarities,
        uint8[] memory _elements,
        string[] memory _tokenUriList
    ) external {
        validateWhitelistParameter(
            _addresses,
            _rarities,
            _elements,
            _tokenUriList
        );
        for (uint256 idx = 0; idx < _addresses.length; idx++) {
            AirdropEggDetail memory eggDetail = setEggDetail(
                _rarities[idx],
                _elements[idx],
                _tokenUriList[idx]
            );
            whitelistEggDetail[_addresses[idx]] = eggDetail;
            isWhiteList[_addresses[idx]] = true;
        }
    }

    function setEggDetail(
        uint8 _rarity,
        uint8 _element,
        string memory _tokenUri
    ) internal returns (AirdropEggDetail memory) {
        blucaEggId = blucaEggId.add(1);
        return
            AirdropEggDetail({
                rarity: _rarity,
                element: _element,
                id: blucaEggId,
                tokenUri: _tokenUri
            });
    }

    function isWhitelist(address _address) external view returns (bool) {
        return isWhiteList[_address];
    }

    function validateWhitelistParameter(
        address[] memory _addresses,
        uint8[] memory _rarities,
        uint8[] memory _elements,
        string[] memory _tokenUriList
    ) private pure {
        uint256 addressCount = _addresses.length;
        uint256 rarityCount = _rarities.length;
        uint256 elementCount = _elements.length;
        uint256 tokenUriCount = _tokenUriList.length;
        require(
            addressCount > 0 &&
                rarityCount > 0 &&
                elementCount > 0 &&
                tokenUriCount > 0
        );
        require(
            addressCount <= 1000 &&
                rarityCount <= 1000 &&
                elementCount <= 1000 &&
                tokenUriCount <= 1000
        );
        require(
            addressCount == rarityCount &&
                addressCount == elementCount &&
                addressCount == tokenUriCount
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

abstract contract BlucaEggFactory {
    using SafeMath for uint256;
    event SpawnBlucaEgg(uint256 blucaEggId);
    
    struct BlucaEgg {
       uint8 rarity; 
       uint8 element;
       bool isHatched;
       uint season;
    }

    BlucaEgg[] public blucaEggs;
    uint256 blucaEggPrice = 0.05 ether;
    uint256 public blucaEggId = 0;

    mapping(uint256 => address) public blucaEggToOwner;
    mapping(address => uint256) ownerBlucaEggCount;

    function spawnBlucaEgg() internal returns (uint) {
        BlucaEgg memory _blucaEgg = BlucaEgg({
            rarity: 0,
            element: 0,
            isHatched: false,
            season: 0
        });
        blucaEggs.push(_blucaEgg);
        blucaEggId = blucaEggId.add(1);
        blucaEggToOwner[blucaEggId] = msg.sender;
        ownerBlucaEggCount[msg.sender] = ownerBlucaEggCount[msg.sender].add(1);
        emit SpawnBlucaEgg(blucaEggId);
        return blucaEggId;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "byzantium",
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
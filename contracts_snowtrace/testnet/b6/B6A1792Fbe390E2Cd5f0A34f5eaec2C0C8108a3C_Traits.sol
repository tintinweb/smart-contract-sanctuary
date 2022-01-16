/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-15
*/

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

interface IBullAndBear {

    // struct to store each token's traits
    struct Trait {
        bool isBear;
        uint[] traits;
    }

    function getTokenTraits(uint256 tokenId) external view returns (Trait memory);
}

contract Traits is Ownable {

    using Strings for uint256;

    uint256 private alphaTypeIndex = 17;

    mapping(uint => uint8) public bearTraitCountForType;
    mapping(uint => uint8) public bullTraitCountForType;

    mapping(uint => uint) public multiplierIndexForBearTraitType;
    mapping(uint => uint) public multiplierIndexForBullTraitType;

    uint public firstBullIndex;
    uint public bearTraitsNumber = 2;
    uint public bullTraitsNumber = 2;

    IBullAndBear public BullAndBear;


    function selectBearTrait(uint16 seed, uint8 traitType) external view returns(uint8) {
         uint8 modOf = bearTraitCountForType[traitType] > 0 ? bearTraitCountForType[traitType] : 10;
        return uint8(seed % modOf);
    }

    function selectBullTrait(uint16 seed, uint8 traitType) external view returns(uint8) {
        if (traitType == alphaTypeIndex) {
            uint256 m = seed % 100;
            if (m > 95) {
                return 0;
            } else if (m > 80) {
                return 1;
            } else if (m > 50) {
                return 2;
            } else {
                return 3;
            }
        }
        uint8 modOf = bullTraitCountForType[traitType] > 0 ? bullTraitCountForType[traitType] : 10;
        return uint8(seed % modOf);
    }

    function setBearTraitCountForType(uint8[] memory _len) public onlyOwner {
        require(_len.length == bearTraitsNumber);
        uint multiplier = 1;
        uint total = 1;

        for (uint i = 0; i < _len.length; i++) {
            bearTraitCountForType[i] = _len[i];
            
            multiplierIndexForBearTraitType[i] = multiplier;
            multiplier = multiplier *= bearTraitCountForType[i];
            total *= bearTraitCountForType[i];
        }

        firstBullIndex = total;
    }

    function setBullTraitCountForType(uint8[] memory _len) public onlyOwner {
        require(_len.length == bullTraitsNumber);
        uint multiplier = 1;

        for (uint i = 0; i < _len.length; i++) {
            bullTraitCountForType[i] = _len[i];
            
            multiplierIndexForBullTraitType[i] = multiplier;
            multiplier = multiplier *= bullTraitCountForType[i];
        }
    }

    function getIndexFromTokenId(uint _tokenId) public view returns (uint index) {
        index = getIndexFromTraits(BullAndBear.getTokenTraits(_tokenId).isBear, BullAndBear.getTokenTraits(_tokenId).traits);
    }

    function getIndexFromStructTrait(IBullAndBear.Trait memory _trait) public view returns (uint index) {
        index = getIndexFromTraits(_trait.isBear, _trait.traits);
    }

    function getIndexFromTraits(bool _isBear, uint[] memory _traits) public view returns (uint index) {
        if (_isBear) {
            for (uint i = 0; i < _traits.length; i++) {
                index += _traits[i] * multiplierIndexForBearTraitType[i];
            }
        } else {
            index = firstBullIndex;

            for (uint i = 0; i < _traits.length; i++) {
                index += _traits[i] * multiplierIndexForBullTraitType[i];
            }
        }
    }

    function getTraitsFromIndex(uint _index) public view returns (bool isBear, uint[] memory _traits) {
        uint id;

        if (_index < firstBullIndex) {
            isBear = true;
            for (uint i = 0; i < bearTraitsNumber; i++) {
                id = bearTraitsNumber - i - 1; // get the id from the end
                _traits[id] = uint(_index / multiplierIndexForBearTraitType[i]);
                _index -= uint(_index / multiplierIndexForBearTraitType[i]) * multiplierIndexForBearTraitType[i];
            }
        } else {
            _index -= firstBullIndex;
            for (uint i = 0; i < bullTraitsNumber; i++) {
                id = bullTraitsNumber - i - 1; // get the id from the end
                _traits[id] = uint(_index / multiplierIndexForBullTraitType[i]);
                _index -= uint(_index / multiplierIndexForBullTraitType[i]) * multiplierIndexForBullTraitType[i];
            }
        }
    }

    /***ADMIN */

    function setGame(address _BullAndBear) external onlyOwner {
        BullAndBear = IBullAndBear(_BullAndBear);
    }
}
pragma solidity ^0.7.0;

import "./IMasksMetadataStore.sol";
import "./IMasksMinimalForRegistry.sol";

contract MasksRegistry {
    // Public variables

    //Constants
    address public constant MASKS_CONTRACT = 0xC2C747E0F7004F9E8817Db2ca4997657a7746928;
    address public constant DATASTORE_CONTRACT = 0x7327DbF06b1FcB0D190533fDD244B52361f0d241;

    uint256 public startingIndexFromMasksContract;
    uint256 public maxMasksSupply;

    // Internal variables
    bytes internal constant _ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";

    constructor() {
        startingIndexFromMasksContract = IMasksMinimalForRegistry(MASKS_CONTRACT).startingIndex();
        maxMasksSupply = IMasksMinimalForRegistry(MASKS_CONTRACT).MAX_NFT_SUPPLY();
    }

    function getTraitsOfMaskId(uint256 maskId)
        public
        view
        returns (
            string memory character,
            string memory mask,
            string memory eyeColor,
            string memory skinColor,
            string memory item
        )
    {
        require(maskId < maxMasksSupply, "Mask ID must be less than 16384");

        // Derives the index of the image in the original sequence assigned to the Mask ID
        uint256 correspondingOriginalSequenceIndex =
            (maskId + startingIndexFromMasksContract) % maxMasksSupply;

        bytes3 traitBytes = IMasksMetadataStore(DATASTORE_CONTRACT).getTraitBytesAtIndex(
            correspondingOriginalSequenceIndex)
        ;

        character = _extractCharacterTrait(traitBytes);
        mask = _extractMaskTrait(traitBytes);
        eyeColor = _extractEyeColorTrait(traitBytes);
        skinColor = _extractSkinColorTrait(traitBytes);
        item = _extractItemTrait(traitBytes);
    }

    function getIPFSHashOfMaskId(uint256 maskId)
        public
        view
        returns (string memory ipfsHash)
    {
        require(maskId < maxMasksSupply, "Mask ID must be less than 16384");

        // Derives the index of the image in the original sequence assigned to the Mask ID
        uint256 correspondingOriginalSequenceIndex =
            (maskId + startingIndexFromMasksContract) % maxMasksSupply;

        ipfsHash = _getIPFSHashOfIndexInOriginalSequence(
            correspondingOriginalSequenceIndex
        );
    }

    function _extractCharacterTrait(bytes3 traitBytes)
        internal
        pure
        returns (string memory character)
    {
        bytes1 characterBits = traitBytes[0] & 0x0F;

        if (characterBits == 0x00) {
            character = "Female";
        } else if (characterBits == 0x01) {
            character = "Golden Robot";
        } else if (characterBits == 0x02) {
            character = "Male";
        } else if (characterBits == 0x03) {
            character = "Mystical";
        } else if (characterBits == 0x04) {
            character = "Puppet";
        } else if (characterBits == 0x05) {
            character = "Robot";
        }
    }

    function _extractMaskTrait(bytes3 traitBytes)
        internal
        pure
        returns (string memory mask)
    {
        bytes1 maskBits = traitBytes[1] >> 4;

        if (maskBits == 0x00) {
            mask = "Abstract";
        } else if (maskBits == 0x01) {
            mask = "African";
        } else if (maskBits == 0x02) {
            mask = "Animal";
        } else if (maskBits == 0x03) {
            mask = "Aztec";
        } else if (maskBits == 0x04) {
            mask = "Basic";
        } else if (maskBits == 0x05) {
            mask = "Chinese";
        } else if (maskBits == 0x06) {
            mask = "Crayon";
        } else if (maskBits == 0x07) {
            mask = "Doodle";
        } else if (maskBits == 0x08) {
            mask = "Hawaiian";
        } else if (maskBits == 0x09) {
            mask = "Indian";
        } else if (maskBits == 0x0A) {
            mask = "Mexican";
        } else if (maskBits == 0x0B) {
            mask = "Pixel";
        } else if (maskBits == 0x0C) {
            mask = "Steampunk";
        } else if (maskBits == 0x0D) {
            mask = "Street";
        } else if (maskBits == 0x0E) {
            mask = "Unique";
        } else if (maskBits == 0x0F) {
            mask = "Unmasked";
        }
    }

    function _extractEyeColorTrait(bytes3 traitBytes)
        internal
        pure
        returns (string memory eyeColor)
    {
        bytes1 eyeColorBits = traitBytes[1] & 0x0F;

        if (eyeColorBits == 0x00) {
            eyeColor = "Blue";
        } else if (eyeColorBits == 0x01) {
            eyeColor = "Dark";
        } else if (eyeColorBits == 0x02) {
            eyeColor = "Freak";
        } else if (eyeColorBits == 0x03) {
            eyeColor = "Glass";
        } else if (eyeColorBits == 0x04) {
            eyeColor = "Green";
        } else if (eyeColorBits == 0x05) {
            eyeColor = "Heterochromatic";
        } else if (eyeColorBits == 0x06) {
            eyeColor = "Mystical";
        } else if (eyeColorBits == 0x07) {
            eyeColor = "Painted";
        }
    }

    function _extractSkinColorTrait(bytes3 traitBytes)
        internal
        pure
        returns (string memory skinColor)
    {
        bytes1 skinColorBits = traitBytes[2] >> 4;

        if (skinColorBits == 0x00) {
            skinColor = "Blue";
        } else if (skinColorBits == 0x01) {
            skinColor = "Dark";
        } else if (skinColorBits == 0x02) {
            skinColor = "Freak";
        } else if (skinColorBits == 0x03) {
            skinColor = "Gold";
        } else if (skinColorBits == 0x04) {
            skinColor = "Gray";
        } else if (skinColorBits == 0x05) {
            skinColor = "Light";
        } else if (skinColorBits == 0x06) {
            skinColor = "Mystical";
        } else if (skinColorBits == 0x07) {
            skinColor = "Steel";
        } else if (skinColorBits == 0x08) {
            skinColor = "Transparent";
        } else if (skinColorBits == 0x09) {
            skinColor = "Wood";
        }
    }

    function _extractItemTrait(bytes3 traitBytes)
        internal
        pure
        returns (string memory item)
    {
        bytes1 itemBits = traitBytes[2] & 0x0F;

        if (itemBits == 0x00) {
            item = "Book";
        } else if (itemBits == 0x01) {
            item = "Bottle";
        } else if (itemBits == 0x02) {
            item = "Golden Toilet Paper";
        } else if (itemBits == 0x03) {
            item = "Mirror";
        } else if (itemBits == 0x04) {
            item = "No Item";
        } else if (itemBits == 0x05) {
            item = "Shadow Monkey";
        } else if (itemBits == 0x06) {
            item = "Toilet Paper";
        }
    }

    function _getIPFSHashOfIndexInOriginalSequence(uint256 index)
        internal
        view
        returns (string memory)
    {
        return
            _toBase58(
                IMasksMetadataStore(DATASTORE_CONTRACT).getIPFSHashHexAtIndex(index)
            );
    }

    // Source: verifyIPFS (https://github.com/MrChico/verifyIPFS/blob/master/contracts/verifyIPFS.sol)
    // @author Martin Lundfall ([email protected])
    // @dev Converts hex string to base 58
    function _toBase58(bytes memory source)
        internal
        pure
        returns (string memory)
    {
        if (source.length == 0) return new string(0);
        uint8[] memory digits = new uint8[](46);
        digits[0] = 0;
        uint8 digitlength = 1;
        for (uint256 i = 0; i < source.length; ++i) {
            uint256 carry = uint8(source[i]);
            for (uint256 j = 0; j < digitlength; ++j) {
                carry += uint256(digits[j]) * 256;
                digits[j] = uint8(carry % 58);
                carry = carry / 58;
            }

            while (carry > 0) {
                digits[digitlength] = uint8(carry % 58);
                digitlength++;
                carry = carry / 58;
            }
        }
        return string(_toAlphabet(_reverse(_truncate(digits, digitlength))));
    }

    function _truncate(uint8[] memory array, uint8 length)
        internal
        pure
        returns (uint8[] memory)
    {
        uint8[] memory output = new uint8[](length);
        for (uint256 i = 0; i < length; i++) {
            output[i] = array[i];
        }
        return output;
    }

    function _reverse(uint8[] memory input)
        internal
        pure
        returns (uint8[] memory)
    {
        uint8[] memory output = new uint8[](input.length);
        for (uint256 i = 0; i < input.length; i++) {
            output[i] = input[input.length - 1 - i];
        }
        return output;
    }

    function _toAlphabet(uint8[] memory indices)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory output = new bytes(indices.length);
        for (uint256 i = 0; i < indices.length; i++) {
            output[i] = _ALPHABET[indices[i]];
        }
        return output;
    }
}
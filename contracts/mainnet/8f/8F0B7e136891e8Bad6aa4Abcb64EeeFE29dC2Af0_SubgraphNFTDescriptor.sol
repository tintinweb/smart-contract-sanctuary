// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

import "../libraries/Base58Encoder.sol";
import "./ISubgraphNFTDescriptor.sol";

/// @title Describes subgraph NFT tokens via URI
contract SubgraphNFTDescriptor is ISubgraphNFTDescriptor {
    /// @inheritdoc ISubgraphNFTDescriptor
    function tokenURI(
        address, /* _minter */
        uint256, /* _tokenId */
        string calldata _baseURI,
        bytes32 _subgraphMetadata
    ) external pure override returns (string memory) {
        bytes memory b58 = Base58Encoder.encode(
            abi.encodePacked(Base58Encoder.sha256MultiHash, _subgraphMetadata)
        );
        if (bytes(_baseURI).length == 0) {
            return string(b58);
        }
        return string(abi.encodePacked(_baseURI, b58));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

/// @title Base58Encoder
/// @author Original author - Martin Lundfall ([email protected])
/// Based on https://github.com/MrChico/verifyIPFS
library Base58Encoder {
    bytes constant sha256MultiHash = hex"1220";
    bytes constant ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";

    /// @dev Converts hex string to base 58
    function encode(bytes memory source) internal pure returns (bytes memory) {
        if (source.length == 0) return new bytes(0);
        uint8[] memory digits = new uint8[](64);
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
        return toAlphabet(reverse(truncate(digits, digitlength)));
    }

    function truncate(uint8[] memory array, uint8 length) internal pure returns (uint8[] memory) {
        uint8[] memory output = new uint8[](length);
        for (uint256 i = 0; i < length; i++) {
            output[i] = array[i];
        }
        return output;
    }

    function reverse(uint8[] memory input) internal pure returns (uint8[] memory) {
        uint8[] memory output = new uint8[](input.length);
        for (uint256 i = 0; i < input.length; i++) {
            output[i] = input[input.length - 1 - i];
        }
        return output;
    }

    function toAlphabet(uint8[] memory indices) internal pure returns (bytes memory) {
        bytes memory output = new bytes(indices.length);
        for (uint256 i = 0; i < indices.length; i++) {
            output[i] = ALPHABET[indices[i]];
        }
        return output;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

/// @title Describes subgraph NFT tokens via URI
interface ISubgraphNFTDescriptor {
    /// @notice Produces the URI describing a particular token ID for a Subgraph
    /// @dev Note this URI may be data: URI with the JSON contents directly inlined
    /// @param _minter Address of the allowed minter
    /// @param _tokenId The ID of the subgraph NFT for which to produce a description, which may not be valid
    /// @param _baseURI The base URI that could be prefixed to the final URI
    /// @param _subgraphMetadata Subgraph metadata set for the subgraph
    /// @return The URI of the ERC721-compliant metadata
    function tokenURI(
        address _minter,
        uint256 _tokenId,
        string calldata _baseURI,
        bytes32 _subgraphMetadata
    ) external view returns (string memory);
}
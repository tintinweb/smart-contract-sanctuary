//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "../libraries/Base64.sol";
import "../libraries/HexStrings.sol";
import "../IEngine.sol";
import "../ICollection.sol";
import "../engines/BeforeTokenTransferNopEngine.sol";
import "../engines/NoRoyaltiesEngine.sol";
import "../engines/OnChainMetadataEngine.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract RGroupPlaceholder is
    IEngine,
    BeforeTokenTransferNopEngine,
    NoRoyaltiesEngine,
    OnChainMetadataEngine
{
    using Strings for uint256;

    function name() external pure returns (string memory) {
        return "R Group Membership";
    }

    function mint(
        ICollection collection,
        string calldata name_,
        string calldata bio
    ) external returns (uint256) {
        StringStorage[] memory stringData = new StringStorage[](0);
        IntStorage[] memory intData = new IntStorage[](0);

        uint256 tokenId = collection.mint(
            msg.sender,
            MintOptions({
                storeEngine: true,
                storeMintedTo: true,
                storeMintedBy: true,
                storeTimestamp: true,
                storeBlockNumber: true,
                stringData: stringData,
                intData: intData
            })
        );

        updateInfo(collection, tokenId, name_, bio);

        return tokenId;
    }

    function updateInfo(
        ICollection collection,
        uint256 tokenId,
        string calldata name_,
        string calldata bio
    ) public {
        collection.writeString(StorageLocation.ENGINE, tokenId, "name", name_);
        collection.writeString(StorageLocation.ENGINE, tokenId, "bio", bio);
    }

    function _computeName(ICollection nft, uint256 tokenId)
        internal
        view
        override
        returns (string memory)
    {
        string memory name_ = nft.readString(StorageLocation.ENGINE, tokenId, "name");
        return string(abi.encodePacked("R Group: ", name_));
    }

    function _computeDescription(ICollection nft, uint256 tokenId)
        internal
        view
        override
        returns (string memory)
    {
        string memory name_ = nft.readString(
            StorageLocation.ENGINE,
            tokenId,
            "name"
        );
        string memory bio = nft.readString(
            StorageLocation.ENGINE,
            tokenId,
            "bio"
        );
        uint256 mintedTo = nft.readInt(
            StorageLocation.FRAMEWORK,
            tokenId,
            "mintedTo"
        );
        uint256 mintedBy = nft.readInt(
            StorageLocation.FRAMEWORK,
            tokenId,
            "mintedBy"
        );
        uint256 timestamp = nft.readInt(
            StorageLocation.FRAMEWORK,
            tokenId,
            "timestamp"
        );

        return
            string(
                abi.encodePacked(
                    "R Group Membership NFT. \\n\\nMember: ",
                    name_,
                    " \\n\\n",
                    bio,
                    " \\n\\nThis membership NFT is only valid if held by ",
                    HexStrings.toHexString(mintedTo, 20),
                    " \\n\\nOriginally minted by ",
                    HexStrings.toHexString(mintedBy, 20),
                    " at timestamp ",
                    timestamp.toString(),
                    ".\\n\\n Token ID #",
                    tokenId.toString(),
                    ".\\n\\n Powered by https://heyshell.xyz"
                )
            );
    }

    function _computeImageUri(ICollection, uint256)
        internal
        pure
        override
        returns (string memory)
    {
        return
            "https://ipfs.hypervibes.xyz/ipfs/QmXuSWsCCEmNcuugzoNrFBYYCtQoJjKM4qyoeyvbVa8z4Z";
    }

    function _computeExternalUrl(ICollection, uint256)
        internal
        pure
        override
        returns (string memory)
    {
        return "https://twitter.com/raribledao";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IEngine).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// https://github.com/Brechtpd/base64/blob/main/base64.sol

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

// https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/HexStrings.sol

library HexStrings {
    bytes16 internal constant ALPHABET = "0123456789abcdef";

    /// @notice Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
    /// @dev Credit to Open Zeppelin under MIT license https://github.com/OpenZeppelin/openzeppelin-contracts/blob/243adff49ce1700e0ecb99fe522fb16cff1d1ddc/contracts/utils/Strings.sol#L55
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = ALPHABET[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    function toHexStringNoPrefix(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length);
        for (uint256 i = buffer.length; i > 0; i--) {
            buffer[i - 1] = ALPHABET[value & 0xf];
            value >>= 4;
        }
        return string(buffer);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./ICollection.sol";

// Required interface for framework engines
interface IEngine is IERC165 {
    // display name for this engine
    function name() external pure returns (string memory);

    // Called by the collection to resolve a response for tokenURI
    function getTokenURI(ICollection collection, uint256 tokenId)
        external
        view
        returns (string memory);

    // Called by the collection to response a response for royaltyInfo
    function getRoyaltyInfo(
        ICollection collection,
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount);

    // Called by the collection during a transfer, including mints (from=0) and
    // burns (to=0). Cannot break transfer even in the case of reverting, as the
    // collection will wrap the downstream call in a try/catch
    function beforeTokenTransfer(
        ICollection collection,
        address from,
        address to,
        uint256 tokenId
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IEngine.sol";

// Data provided by engine when minting a new token
struct MintOptions {
    bool storeEngine;
    bool storeMintedBy;
    bool storeMintedTo;
    bool storeTimestamp;
    bool storeBlockNumber;
    StringStorage[] stringData;
    IntStorage[] intData;
}

// Each storage location has its own access constraints
enum StorageLocation {
    // can only be set by token owner at any time, mutable
    OWNER,
    // is set by the engine at any time, mutable
    ENGINE,
    // is set by engine during minting, immutable
    MINT_DATA,
    // is set by the framework during minting or collection creation, immutable
    FRAMEWORK
}

struct StringStorage {
    string key;
    string value;
}

struct IntStorage {
    string key;
    uint256 value;
}

// Interface for every collection launched by the framework
interface ICollection {
    // A new engine was installed
    event EngineInstalled(IEngine indexed engine);

    // A string was stored in the collection
    event CollectionStringUpdated(
        StorageLocation indexed location,
        string indexed key,
        string value
    );

    // A string was stored in a token
    event TokenStringUpdated(
        StorageLocation indexed location,
        uint256 indexed tokenId,
        string indexed key,
        string value
    );

    // A uint256 was stored in the collection
    event CollectionIntUpdated(
        StorageLocation indexed location,
        string indexed key,
        uint256 value
    );

    // A uint256 was stored in a token
    event TokenIntUpdated(
        StorageLocation indexed location,
        uint256 indexed tokenId,
        string indexed key,
        uint256 value
    );

    // ---
    // Collection owner (admin) functionaltiy
    // ---

    // Hot swap the collection's engine. Only callable by contract owner
    function installEngine(IEngine engine) external;

    function installedEngine() external view returns (IEngine);

    // ---
    // Engine functionality
    // ---

    // Mint a new token. Only callable by engine
    function mint(address to, MintOptions calldata options)
        external
        returns (uint256);

    // ---
    // Storage writes
    // ---

    // Write a string to collection storage
    function writeString(
        StorageLocation location,
        string calldata key,
        string calldata value
    ) external;

    // Write a string to token storage
    function writeString(
        StorageLocation location,
        uint256 tokenId,
        string calldata key,
        string calldata value
    ) external;

    // Write a string to collection storage
    function writeInt(
        StorageLocation location,
        string calldata key,
        uint256 value
    ) external;

    // Write a string to token storage
    function writeInt(
        StorageLocation location,
        uint256 tokenId,
        string calldata key,
        uint256 value
    ) external;

    // ---
    // Storage reads
    // ---

    // Read a string from collection storage
    function readString(StorageLocation location, string calldata key)
        external
        view
        returns (string memory);

    // Read a string from token storage
    function readString(
        StorageLocation location,
        uint256 tokenId,
        string calldata key
    ) external view returns (string memory);

    // Read a uint256 from collection storage
    function readInt(StorageLocation location, string calldata key)
        external
        view
        returns (uint256);

    // Read a uint256 from token storage
    function readInt(
        StorageLocation location,
        uint256 tokenId,
        string calldata key
    ) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../IEngine.sol";

abstract contract BeforeTokenTransferNopEngine is IEngine {
    function beforeTokenTransfer(
        ICollection collection,
        address,
        address,
        uint256
    ) external view {
        require(msg.sender == address(collection), "shell: invalid sender");
        return;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../IEngine.sol";

abstract contract NoRoyaltiesEngine is IEngine {
    function getRoyaltyInfo(
        ICollection,
        uint256,
        uint256
    ) external pure returns (address receiver, uint256 royaltyAmount) {
        receiver = address(0);
        royaltyAmount = 0;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/Base64.sol";
import "../IEngine.sol";

abstract contract OnChainMetadataEngine is IEngine {
    // Called by the collection to resolve a response for tokenURI
    function getTokenURI(ICollection collection, uint256 tokenId)
        external
        view
        returns (string memory)
    {
        string memory name = _computeName(collection, tokenId);
        string memory description = _computeDescription(collection, tokenId);
        string memory image = _computeImageUri(collection, tokenId);
        string memory externalUrl = _computeExternalUrl(collection, tokenId);

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name,
                                '", "description":"',
                                description,
                                '", "image": "',
                                image,
                                '", "external_url": "',
                                externalUrl,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    // compute the metadata name for a given token
    function _computeName(ICollection nft, uint256 tokenId)
        internal
        view
        virtual
        returns (string memory);

    // compute the metadata description for a given token
    function _computeDescription(ICollection nft, uint256 tokenId)
        internal
        view
        virtual
        returns (string memory);

    // compute the metadata image field for a given token
    function _computeImageUri(ICollection nft, uint256 tokenId)
        internal
        view
        virtual
        returns (string memory);

    // compute the external_url field for a given token
    function _computeExternalUrl(ICollection nft, uint256 tokenId)
        internal
        view
        virtual
        returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
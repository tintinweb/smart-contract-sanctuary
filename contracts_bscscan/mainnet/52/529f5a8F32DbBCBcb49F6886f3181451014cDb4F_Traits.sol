// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/ITraits.sol";
import "./interfaces/ICnM.sol";

contract Traits is Ownable, ITraits {

    using Strings for uint256;

    // struct to store each trait's data for metadata and rendering
    struct Trait {
        string name;
        string png;
    }

    // mapping from trait type (index) to its name
    string[13] private _traitTypes = [
    "Body",
    "Color",
    "Eyes",
    "Eyebrows",
    "Neck",
    "Glasses",
    "Hair",
    "Head",
    "Markings",
    "Mouth",
    "Nose",
    "Props",
    "Shirts"
    ];

    // storage of each traits name and base64 PNG data (traitType => (traitId => Trait))
    mapping(uint8 => mapping(uint8 => Trait)) public traitData;


    ICnM public cnmNFT;

    constructor() {}

    /** ADMIN */

    function setCnM(address _cnmNFT) external onlyOwner {
        cnmNFT = ICnM(_cnmNFT);
    }

    // Cat traitType : 1, 2, 9, 8, 11
    // 1: 5, 2: 11, 9: 3, 11: 7, 8: 3

    // Crazy Cat traitType : 13, 16, 15, 18, 19, 25
    // 13: 2, 16: 3, 15: 2, 18: 3, 19: 8, 25: 3

    // Mice traitType: 26, 27, 28, 33, 35, 36
    // 26: 4, 27: 10, 28: 10, 33: 9, 35: 5, 36: 2

    /**
     * administrative to upload the names and images associated with each trait
     * @param traitType the trait type to upload the traits for (see traitTypes for a mapping)
     * @param traits the names and base64 encoded PNGs for each trait
     * @param traitIds the ids for traits
   */
    function uploadTraits(uint8 traitType, uint8[] calldata traitIds, Trait[] calldata traits) external onlyOwner {
        require(traitIds.length == traits.length, "Mismatched inputs");
        for (uint i = 0; i < traits.length; i++) {
            traitData[traitType][traitIds[i]] = Trait(
                traits[i].name,
                traits[i].png
            );
        }
    }

    /** RENDER */

    /**
     * generates an <image> element using base64 encoded PNGs
     * @param trait the trait storing the PNG data
   * @return the <image> element
   */
    function drawTrait(Trait memory trait) internal pure returns (string memory) {
        return string(abi.encodePacked(
                '<image x="4" y="4" width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
                trait.png,
                '"/>'
            ));
    }

    /**
     * generates an entire SVG by composing multiple <image> elements of PNGs
     * @param tokenId the ID of the token to generate an SVG for
   * @return a valid SVG of the Cat / Mouse / Crazy cat
   */
    function drawSVG(uint256 tokenId) internal view returns (string memory) {
        ICnM.CatMouse memory s = cnmNFT.getTokenTraits(tokenId);
        // Trait data indexes 0 - 12 are reserved for Cats
        // Trait data indexes 13 - 25 are reserved for Crazy Cats
        // Trait data indexes 26 - 38 are reserved for Mouse.
        string memory svgString;
        if (s.isCat) {
            if (s.isCrazy) {
                // crazy cats
                svgString = string(abi.encodePacked(
                        drawTrait(traitData[13][s.body]),
                        drawTrait(traitData[16][s.eyebrows]),
                        drawTrait(traitData[15][s.eyes]),
                        drawTrait(traitData[18][s.glasses]),
                        drawTrait(traitData[19][s.hair]),
                        drawTrait(traitData[25][s.shirts])
                    ));
            } else {
                // cats
                svgString = string(abi.encodePacked(
                        drawTrait(traitData[1][s.color]),
                        drawTrait(traitData[2][s.eyes]),
                        drawTrait(traitData[9][s.mouth]),
                        drawTrait(traitData[8][s.markings]),
                        drawTrait(traitData[11][s.props])
                    ));
            }
        } else {
            // mice
            svgString = string(abi.encodePacked(
                    drawTrait(traitData[26][s.body]),
                    drawTrait(traitData[27][s.color]),
                    drawTrait(traitData[28][s.eyes]),
                    drawTrait(traitData[33][s.head]),
                    drawTrait(traitData[35][s.mouth]),
                    drawTrait(traitData[36][s.nose])
                ));
        }


        return string(abi.encodePacked(
                '<svg id="cnmNFT" width="100%" height="100%" version="1.1" viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                svgString,
                "</svg>"
            ));
    }

    /**
     * generates an attribute for the attributes array in the ERC721 metadata standard
     * @param traitType the trait type to reference as the metadata key
   * @param value the token's trait associated with the key
   * @return a JSON dictionary for the single attribute
   */
    function attributeForTypeAndValue(string memory traitType, string memory value) internal pure returns (string memory) {
        return string(abi.encodePacked(
                '{"trait_type":"',
                traitType,
                '","value":"',
                value,
                '"}'
            ));
    }

    /**
     * generates an array composed of all the individual traits and values
     * @param tokenId the ID of the token to compose the metadata for
   * @return a JSON array of all of the attributes for given token ID
   */
    function compileAttributes(uint256 tokenId) internal view returns (string memory) {
        ICnM.CatMouse memory s = cnmNFT.getTokenTraits(tokenId);
        string memory traits;
        if (s.isCat) {
            if (s.isCrazy) {
                traits = string(abi.encodePacked(
                        attributeForTypeAndValue(_traitTypes[0], traitData[13][s.body].name), ',',
                        attributeForTypeAndValue(_traitTypes[3], traitData[16][s.eyebrows].name), ',',
                        attributeForTypeAndValue(_traitTypes[2], traitData[15][s.eyes].name), ',',
                        attributeForTypeAndValue(_traitTypes[5], traitData[18][s.glasses].name), ',',
                        attributeForTypeAndValue(_traitTypes[6], traitData[19][s.hair].name), ',',
                        attributeForTypeAndValue(_traitTypes[12], traitData[25][s.shirts].name), ','
                    ));
            } else {
                traits = string(abi.encodePacked(
                        attributeForTypeAndValue(_traitTypes[1], traitData[1][s.color].name), ',',
                        attributeForTypeAndValue(_traitTypes[2], traitData[2][s.eyes].name), ',',
                        attributeForTypeAndValue(_traitTypes[9], traitData[9][s.mouth].name), ',',
                        attributeForTypeAndValue(_traitTypes[11], traitData[11][s.props].name), ',',
                        attributeForTypeAndValue(_traitTypes[8], traitData[8][s.markings].name), ','
                    ));
            }
        } else {
            traits = string(abi.encodePacked(
                    attributeForTypeAndValue(_traitTypes[0], traitData[26][s.body].name), ',',
                    attributeForTypeAndValue(_traitTypes[1], traitData[27][s.color].name), ',',
                    attributeForTypeAndValue(_traitTypes[2], traitData[28][s.eyes].name), ',',
                    attributeForTypeAndValue(_traitTypes[7], traitData[33][s.head].name), ',',
                    attributeForTypeAndValue(_traitTypes[9], traitData[35][s.mouth].name), ',',
                    attributeForTypeAndValue(_traitTypes[10], traitData[36][s.nose].name), ','
                ));
        }
        return string(abi.encodePacked(
                '[',
                traits,
                '{"trait_type":"Generation","value":',
                tokenId <= cnmNFT.getPaidTokens() ? '"Gen 0"' : '"Gen 1"',
                '},{"trait_type":"Type","value":',
                s.isCat ? s.isCrazy ? '"Crazy Cat Lady"' : '"Cat"' : '"Mouse"',
                '}]'
            ));
    }

    /**
     * generates a base64 encoded metadata response without referencing off-chain content
     * @param tokenId the ID of the token to generate the metadata for
   * @return a base64 encoded JSON dictionary of the token's metadata and SVG
   */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_msgSender() == address(cnmNFT), "hmmmm what doing?");
        ICnM.CatMouse memory s = cnmNFT.getTokenTraits(tokenId);

        string memory metadata = string(abi.encodePacked(
                '{"name": "',
                s.isCat ? s.isCrazy ? 'Crazy Cat Lady #' : 'Cat #' : 'Mouse #',
                tokenId.toString(),
                '", "description": "Thousands of Cats and Mice compete in a habitat in the metadata. A tempting prize of $CHEDDAR awaits, with deadly high stakes. All the metadata and images are generated and stored 100% on-chain. No IPFS. NO API. Just the Ethereum blockchain.", "image": "data:image/svg+xml;base64,',
                base64(bytes(drawSVG(tokenId))),
                '", "attributes":',
                compileAttributes(tokenId),
                "}"
            ));

        return string(abi.encodePacked(
                "data:application/json;base64,",
                base64(bytes(metadata))
            ));
    }


    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function base64(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

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
            for {} lt(dataPtr, endPtr) {}
            {
                dataPtr := add(dataPtr, 3)

            // read 3 bytes
                let input := mload(dataPtr)

            // write 4 characters
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
                resultPtr := add(resultPtr, 1)
            }

        // padding with '='
            switch mod(mload(data), 3)
            case 1 {mstore(sub(resultPtr, 2), shl(240, 0x3d3d))}
            case 2 {mstore(sub(resultPtr, 1), shl(248, 0x3d))}
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT LICENSE 

pragma solidity ^0.8.0;

interface ITraits {
  function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface ICnM is IERC721Enumerable {
    
    // Character NFT struct
    struct CatMouse {
        bool isCat; // true if cat
        bool isCrazy; // true if cat is CrazyCatLady, only check if isCat equals to true
        uint8 roll; //0 - habitatless, 1 - Shack, 2 - Ranch, 3 - Mansion

        uint8 body;
        uint8 color;
        uint8 eyes;
        uint8 eyebrows;
        uint8 neck;
        uint8 glasses;
        uint8 hair;
        uint8 head;
        uint8 markings;
        uint8 mouth;
        uint8 nose;
        uint8 props;
        uint8 shirts;
    }

    function getTokenWriteBlock(uint256 tokenId) external view returns(uint64);
    function mint(address recipient, uint256 seed) external;
    // function setRoll(uint256 seed, uint256 tokenId, address addr) external;
    function setRoll(uint256 tokenId, uint8 habitatType) external;

    function emitCatStakedEvent(address owner,uint256 tokenId) external;
    function emitCrazyCatStakedEvent(address owner, uint256 tokenId) external;
    function emitMouseStakedEvent(address owner, uint256 tokenId) external;
    
    function emitCatUnStakedEvent(address owner, uint256 tokenId) external;
    function emitCrazyCatUnStakedEvent(address owner, uint256 tokenId) external;
    function emitMouseUnStakedEvent(address owner, uint256 tokenId) external;
    
    function burn(uint256 tokenId) external;
    function getPaidTokens() external view returns (uint256);
    function updateOriginAccess(uint16[] memory tokenIds) external;
    function isCat(uint256 tokenId) external view returns(bool);
    function isClaimable() external view returns(bool);
    function isCrazyCatLady(uint256 tokenId) external view returns(bool);
    function getTokenRoll(uint256 tokenId) external view returns(uint8);
    function getMaxTokens() external view returns (uint256);
    function getTokenTraits(uint256 tokenId) external view returns (CatMouse memory);
    function minted() external view returns (uint16);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        _transferOwnership(_msgSender());
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
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
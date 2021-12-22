// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/ITraits.sol";
import "./interfaces/IPnG.sol";

import "./utils/Accessable.sol";

contract Traits is Accessable, ITraits {
    using Strings for uint256;

    string public description;
    IPnG public nftContract;

    struct Trait {
        string name;
        string png;
    }

    // mapping from trait type (index) to its name
    string[15] private _traitTypes = [
        // Galleons
        "base",
        "deck",
        "sails",
        "crows nest",
        "decor",
        "flags",
        "bowsprit",
        // Pirates
        "skin",
        "clothes",
        "hair",
        "earrings",
        "mouth",
        "eyes",
        "weapon",
        "hat"
    ];
    // storage of each traits name and base64 PNG data
    mapping(uint8 => mapping(uint8 => Trait)) public traitData;
    // mapping from rankIndex to its score
    string[4] private _ranks = [
        "5",
        "6",
        "7",
        "8"
    ];


    constructor() {
        description = "With the sweet $CACAO becoming the most precious commodity, Galleons and Pirates engage in a risk-it-all battle in the Ethereum waters to get the biggest share. A play-to-earn game fully 100% on-chain, with commit-reveal minting and flashbots protection.";
    }

    /** ADMIN */

    function _setNftContract(address _nftContract) external onlyAdmin {
        nftContract = IPnG(_nftContract);
    }

    /**
     * administrative to upload the names and images associated with each trait
     * @param traitType the trait type to upload the traits for (see traitTypes for a mapping)
     * @param traits the names and base64 encoded PNGs for each trait
     */
    function _uploadTraits(uint8 traitType, uint8[] calldata traitIds, Trait[] calldata traits) external onlyAdmin {
        require(traitIds.length == traits.length, "Mismatched inputs");
        for (uint i = 0; i < traits.length; i++) {
            traitData[traitType][traitIds[i]] = Trait(
                traits[i].name,
                traits[i].png
            );
        }
    }

    function _setDescription(string memory _description) external onlyAdmin {
        description = _description;
    }

    function _withdraw() external onlyTokenClaimer {
        payable(_msgSender()).transfer(address(this).balance);
    }


    /** RENDER */

    /**
     * generates an <image> element using base64 encoded PNGs
     * @param trait the trait storing the PNG data
     * @return the <image> element
     */
    function drawTrait(Trait memory trait) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '<image x="4" y="4" width="64" height="64" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
            trait.png,
            '"/>'
        ));
    }

    /**
     * generates an entire SVG by composing multiple <image> elements of PNGs
     * @param tokenId the ID of the token to generate an SVG for
     * @return a valid SVG of the Galleon or Pirate
     */
    function drawSVG(uint256 tokenId) internal view returns (string memory) {
        IPnG.GalleonPirate memory s = nftContract.getTokenTraits(tokenId);
        string memory svgString;

        if (s.isGalleon) {
            svgString = string(abi.encodePacked(
                drawTrait(traitData[0][s.base]),
                drawTrait(traitData[1][s.deck]),
                drawTrait(traitData[2][s.sails]),
                drawTrait(traitData[3][s.crowsNest]),
                drawTrait(traitData[4][s.decor]),
                drawTrait(traitData[5][s.flags]),
                drawTrait(traitData[6][s.bowsprit])
            ));
        }
        else {
            svgString = string(abi.encodePacked(
                drawTrait(traitData[7][s.skin]),
                drawTrait(traitData[8][s.clothes]),
                drawTrait(traitData[9][s.hair]),
                drawTrait(traitData[10][s.earrings]),
                drawTrait(traitData[11][s.mouth]),
                drawTrait(traitData[12][s.eyes]),
                drawTrait(traitData[13][s.weapon]),
                s.hat > 0 ? drawTrait(traitData[14][s.hat]) : ''
            ));
        }

        return string(abi.encodePacked(
            '<svg id="GalletonPirateNFT" width="100%" height="100%" version="1.1" viewBox="0 0 72 72" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
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
        IPnG.GalleonPirate memory s = nftContract.getTokenTraits(tokenId);
        string memory traits;
        if (s.isGalleon) {
            traits = string(abi.encodePacked(
                attributeForTypeAndValue(_traitTypes[0], traitData[0][s.base].name),',',
                attributeForTypeAndValue(_traitTypes[1], traitData[1][s.deck].name),',',
                attributeForTypeAndValue(_traitTypes[2], traitData[2][s.sails].name),',',
                attributeForTypeAndValue(_traitTypes[3], traitData[3][s.crowsNest].name),',',
                attributeForTypeAndValue(_traitTypes[4], traitData[4][s.decor].name),',',
                attributeForTypeAndValue(_traitTypes[5], traitData[5][s.flags].name),',',
                attributeForTypeAndValue(_traitTypes[6], traitData[6][s.bowsprit].name)
            ));
        } else {
            traits = string(abi.encodePacked(
                attributeForTypeAndValue(_traitTypes[7], traitData[7][s.skin].name),',',
                attributeForTypeAndValue(_traitTypes[8], traitData[8][s.clothes].name),',',
                attributeForTypeAndValue(_traitTypes[9], traitData[9][s.hair].name),',',
                attributeForTypeAndValue(_traitTypes[10], traitData[10][s.earrings].name),',',
                attributeForTypeAndValue(_traitTypes[11], traitData[11][s.mouth].name),',',
                attributeForTypeAndValue(_traitTypes[12], traitData[12][s.eyes].name),',',
                attributeForTypeAndValue(_traitTypes[13], traitData[13][s.weapon].name),',',
                attributeForTypeAndValue(_traitTypes[14], s.hat > 0 ? traitData[14][s.hat].name : 'None'), ',',
                attributeForTypeAndValue("rank", _ranks[s.alphaIndex])
            ));
        }
        
        return string(abi.encodePacked(
            '[',
            traits,
            ',{"trait_type":"generation","value":',
            tokenId <= nftContract.getPaidTokens() ? '"Gen 0"' : '"Gen 1"',
            '},{"trait_type":"type","value":',
            s.isGalleon ? '"Galleon"' : '"Pirate"',
            '}]'
        ));
    }

    /**
     * generates a base64 encoded metadata response without referencing off-chain content
     * @param tokenId the ID of the token to generate the metadata for
     * @return a base64 encoded JSON dictionary of the token's metadata and SVG
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_msgSender() == address(nftContract) || isAdmin(_msgSender()), "???");
        IPnG.GalleonPirate memory s = nftContract.getTokenTraits(tokenId);

        string memory metadata = string(abi.encodePacked(
            '{"name": "',
            s.isGalleon ? 'Galleon #' : 'Pirate #',
            tokenId.toString(),
            '", "description": "',
            description, 
            '", "image": "data:image/svg+xml;base64,',
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

    /** BASE 64 - Written by Brech Devos */
    
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
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(                input,    0x3F)))))
                resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";


contract Owned is Context {
    address private _contractOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() { 
        _contractOwner = payable(_msgSender()); 
    }

    function owner() public view virtual returns(address) {
        return _contractOwner;
    }

    function _transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Owned: Address can not be 0x0");
        __transferOwnership(newOwner);
    }


    function _renounceOwnership() external virtual onlyOwner {
        __transferOwnership(address(0));
    }

    function __transferOwnership(address _to) internal {
        emit OwnershipTransferred(owner(), _to);
        _contractOwner = _to;
    }


    modifier onlyOwner() {
        require(_msgSender() == _contractOwner, "Owned: Only owner can operate");
        _;
    }
}



contract Accessable is Owned {
    mapping(address => bool) private _admins;
    mapping(address => bool) private _tokenClaimers;

    constructor() {
        _admins[_msgSender()] = true;
        _tokenClaimers[_msgSender()] = true;
    }

    function isAdmin(address user) public view returns(bool) {
        return _admins[user];
    }

    function isTokenClaimer(address user) public view returns(bool) {
        return _tokenClaimers[user];
    }


    function _setAdmin(address _user, bool _isAdmin) external onlyOwner {
        _admins[_user] = _isAdmin;
        require( _admins[owner()], "Accessable: Contract owner must be an admin" );
    }

    function _setTokenClaimer(address _user, bool _isTokenCalimer) external onlyOwner {
        _tokenClaimers[_user] = _isTokenCalimer;
        require( _tokenClaimers[owner()], "Accessable: Contract owner must be an token claimer" );
    }


    modifier onlyAdmin() {
        require(_admins[_msgSender()], "Accessable: Only admin can operate");
        _;
    }

    modifier onlyTokenClaimer() {
        require(_tokenClaimers[_msgSender()], "Accessable: Only Token Claimer can operate");
        _;
    }
}

// SPDX-License-Identifier: MIT LICENSE 

pragma solidity ^0.8.0;

interface ITraits {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IPnG is IERC721 {

    struct GalleonPirate {
        bool isGalleon;

        // Galleon traits
        uint8 base;
        uint8 deck;
        uint8 sails;
        uint8 crowsNest;
        uint8 decor;
        uint8 flags;
        uint8 bowsprit;

        // Pirate traits
        uint8 skin;
        uint8 clothes;
        uint8 hair;
        uint8 earrings;
        uint8 mouth;
        uint8 eyes;
        uint8 weapon;
        uint8 hat;
        uint8 alphaIndex;
    }


    function updateOriginAccess(uint16[] memory tokenIds) external;

    function totalSupply() external view returns(uint256);

    function mint(address recipient, uint256 seed) external;
    function burn(uint256 tokenId) external;
    function minted() external view returns (uint16);

    function getMaxTokens() external view returns (uint256);
    function getPaidTokens() external view returns (uint256);
    function getTokenTraits(uint256 tokenId) external view returns (GalleonPirate memory);
    function getTokenWriteBlock(uint256 tokenId) external view returns(uint64);
    function isGalleon(uint256 tokenId) external view returns(bool);
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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
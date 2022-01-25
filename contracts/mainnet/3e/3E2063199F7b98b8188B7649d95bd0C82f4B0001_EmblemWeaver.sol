// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import './interfaces/ICategories.sol';
import './interfaces/IFrameGenerator.sol';
import './interfaces/IFieldGenerator.sol';
import './interfaces/IHardwareGenerator.sol';
import './interfaces/IShieldBadgeSVGs.sol';
import './interfaces/IFrameSVGs.sol';
import './interfaces/IShields.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import 'base64-sol/base64.sol';

/// @dev Generate Shield Metadata
contract EmblemWeaver {
    using Strings for uint8;

    IFieldGenerator public immutable fieldGenerator;
    IHardwareGenerator public immutable hardwareGenerator;
    IFrameGenerator public immutable frameGenerator;
    IShieldBadgeSVGs public immutable shieldBadgeSVGGenerator;

    constructor(
        IFieldGenerator _fieldGenerator,
        IHardwareGenerator _hardwareGenerator,
        IFrameGenerator _frameGenerator,
        IShieldBadgeSVGs _shieldBadgeSVGGenerator
    ) {
        fieldGenerator = _fieldGenerator;
        hardwareGenerator = _hardwareGenerator;
        frameGenerator = _frameGenerator;
        shieldBadgeSVGGenerator = _shieldBadgeSVGGenerator;
    }

    function generateShieldURI(IShields.Shield memory shield) external view returns (string memory) {
        IFieldSVGs.FieldData memory field = fieldGenerator.generateField(shield.field, shield.colors);
        IHardwareSVGs.HardwareData memory hardware = hardwareGenerator.generateHardware(shield.hardware);
        IFrameSVGs.FrameData memory frame = frameGenerator.generateFrame(shield.frame);

        string memory name = generateTitle(field.title, hardware.title, frame.title, shield.colors);
        bytes memory attributes = generateAttributesJSON(field, hardware, frame, shield.colors);

        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name,
                                '", "description":"A unique Shield, designed and built on-chain. 1 of 5000.", "image": "data:image/svg+xml;base64,',
                                Base64.encode(bytes(generateSVG(field.svgString, hardware.svgString, frame.svgString))),
                                '", "attributes": ',
                                attributes,
                                '}'
                            )
                        )
                    )
                )
            );
    }

    function generateShieldBadgeURI(IShields.ShieldBadge shieldBadge) external view returns (string memory) {
        string memory badgeTitle;

        if (shieldBadge == IShields.ShieldBadge.MAKER) {
            badgeTitle = 'Maker ';
        } else if (shieldBadge == IShields.ShieldBadge.STANDARD) {
            badgeTitle = '';
        }

        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                badgeTitle,
                                'Shield Badge',
                                '", "description":"An unused Shield Badge. Can be used to build 1 Shield.", "image": "data:image/svg+xml;base64,',
                                Base64.encode(bytes(shieldBadgeSVGGenerator.generateShieldBadgeSVG(shieldBadge))),
                                '", "attributes": [{"trait_type": "Status", "value":"Unbuilt"}]}'
                            )
                        )
                    )
                )
            );
    }

    function generateTitle(
        string memory fieldTitle,
        string memory hardwareTitle,
        string memory frameTitle,
        uint24[4] memory colors
    ) internal view returns (string memory) {
        bytes memory frameString = '';
        if (bytes(frameTitle).length > 0) {
            frameString = abi.encodePacked(frameTitle, ': ');
        }
        return
            string(abi.encodePacked(frameString, hardwareTitle, ' on ', generateColorTitleSnippet(colors), fieldTitle));
    }

    function generateColorTitleSnippet(uint24[4] memory colors) internal view returns (string memory) {
        bytes memory colorTitle = bytes(fieldGenerator.colorTitle(colors[0]));
        if (colors[1] > 0) {
            colorTitle = abi.encodePacked(
                colorTitle,
                colors[2] > 0 ? ' ' : ' and ',
                fieldGenerator.colorTitle(colors[1])
            );
        }
        if (colors[2] > 0) {
            colorTitle = abi.encodePacked(
                colorTitle,
                colors[3] > 0 ? ' ' : ' and ',
                fieldGenerator.colorTitle(colors[2])
            );
        }
        if (colors[3] > 0) {
            colorTitle = abi.encodePacked(colorTitle, ' and ', fieldGenerator.colorTitle(colors[3]));
        }
        colorTitle = abi.encodePacked(colorTitle, ' ');
        return string(colorTitle);
    }

    function generateSVG(
        string memory fieldSVG,
        string memory hardwareSVG,
        string memory frameSVG
    ) internal pure returns (bytes memory svg) {
        svg = abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 220 264">',
            fieldSVG,
            hardwareSVG,
            frameSVG,
            '</svg>'
        );
    }

    function generateAttributesJSON(
        IFieldSVGs.FieldData memory fieldData,
        IHardwareSVGs.HardwareData memory hardwareData,
        IFrameSVGs.FrameData memory frameData,
        uint24[4] memory colors
    ) internal view returns (bytes memory attributesJSON) {
        attributesJSON = abi.encodePacked(
            '[{"trait_type":"Field", "value":"',
            fieldData.title,
            '"}, {"trait_type":"Hardware", "value":"',
            hardwareData.title,
            '"}, {"trait_type":"Status", "value":"Built',
            '"}, {"trait_type":"Field Type", "value":"',
            getFieldTypeString(fieldData.fieldType),
            '"}, {"trait_type":"Hardware Type", "value":"',
            getHardwareTypeString(hardwareData.hardwareType),
            conditionalFrameAttribute(frameData.title),
            colorAttributes(colors)
        );
    }

    function getFieldTypeString(ICategories.FieldCategories category) internal pure returns (string memory typeString) {
        if (category == ICategories.FieldCategories.MYTHIC) {
            typeString = 'Mythic';
        } else {
            typeString = 'Heraldic';
        }
    }

    function getHardwareTypeString(ICategories.HardwareCategories category)
        internal
        pure
        returns (string memory typeString)
    {
        if (category == ICategories.HardwareCategories.SPECIAL) {
            typeString = 'Special';
        } else {
            typeString = 'Standard';
        }
    }

    function conditionalFrameAttribute(string memory frameTitle) internal pure returns (bytes memory frameAttribute) {
        if (bytes(frameTitle).length > 0) {
            frameAttribute = abi.encodePacked('"}, {"trait_type":"Frame", "value":"', frameTitle);
        } else {
            frameAttribute = '';
        }
    }

    function colorAttributes(uint24[4] memory colors) private view returns (bytes memory colorArributes) {
        colorArributes = abi.encodePacked(
            '"}, {"trait_type":"Color 1", "value":"',
            fieldGenerator.colorTitle(colors[0]),
            conditionalColorAttribute(colors[1], 2),
            conditionalColorAttribute(colors[2], 3),
            conditionalColorAttribute(colors[3], 4),
            '"}]'
        );
    }

    function conditionalColorAttribute(uint24 color, uint8 nColor) private view returns (bytes memory colorArribute) {
        if (color != 0) {
            colorArribute = abi.encodePacked(
                '"}, {"trait_type":"Color ',
                nColor.toString(),
                '", "value":"',
                fieldGenerator.colorTitle(color)
            );
        } else {
            colorArribute = '';
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface ICategories {
    enum FieldCategories {
        MYTHIC,
        HERALDIC
    }

    enum HardwareCategories {
        STANDARD,
        SPECIAL
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import './IFrameSVGs.sol';

/// @dev Generate Frame SVG
interface IFrameGenerator {
    struct FrameSVGs {
        IFrameSVGs frameSVGs1;
        IFrameSVGs frameSVGs2;
    }

    /// @param Frame uint representing Frame selection
    /// @return FrameData containing svg snippet and Frame title and Frame type
    function generateFrame(uint16 Frame) external view returns (IFrameSVGs.FrameData memory);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import './IFieldSVGs.sol';
import './IColors.sol';

/// @dev Generate Field SVG
interface IFieldGenerator {
    /// @param field uint representing field selection
    /// @param colors to be rendered in the field svg
    /// @return FieldData containing svg snippet and field title
    function generateField(uint16 field, uint24[4] memory colors) external view returns (IFieldSVGs.FieldData memory);

    event ColorAdded(uint24 color, string title);

    struct Color {
        string title;
        bool exists;
    }

    /// @notice Returns true if color exists in contract, else false.
    /// @param color 3-byte uint representing color
    /// @return true or false
    function colorExists(uint24 color) external view returns (bool);

    /// @notice Returns the title string corresponding to the 3-byte color
    /// @param color 3-byte uint representing color
    /// @return true or false
    function colorTitle(uint24 color) external view returns (string memory);

    struct FieldSVGs {
        IFieldSVGs fieldSVGs1;
        IFieldSVGs fieldSVGs2;
        IFieldSVGs fieldSVGs3;
        IFieldSVGs fieldSVGs4;
        IFieldSVGs fieldSVGs5;
        IFieldSVGs fieldSVGs6;
        IFieldSVGs fieldSVGs7;
        IFieldSVGs fieldSVGs8;
        IFieldSVGs fieldSVGs9;
        IFieldSVGs fieldSVGs10;
        IFieldSVGs fieldSVGs11;
        IFieldSVGs fieldSVGs12;
        IFieldSVGs fieldSVGs13;
        IFieldSVGs fieldSVGs14;
        IFieldSVGs fieldSVGs15;
        IFieldSVGs fieldSVGs16;
        IFieldSVGs fieldSVGs17;
        IFieldSVGs fieldSVGs18;
        IFieldSVGs fieldSVGs19;
        IFieldSVGs fieldSVGs20;
        IFieldSVGs fieldSVGs21;
        IFieldSVGs fieldSVGs22;
        IFieldSVGs fieldSVGs23;
        IFieldSVGs fieldSVGs24;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import './IHardwareSVGs.sol';

/// @dev Generate Hardware SVG
interface IHardwareGenerator {

    /// @param hardware uint representing hardware selection
    /// @return HardwareData containing svg snippet and hardware title and hardware type
    function generateHardware(uint16 hardware) external view returns (IHardwareSVGs.HardwareData memory);

    struct HardwareSVGs {
        IHardwareSVGs hardwareSVGs1;
        IHardwareSVGs hardwareSVGs2;
        IHardwareSVGs hardwareSVGs3;
        IHardwareSVGs hardwareSVGs4;
        IHardwareSVGs hardwareSVGs5;
        IHardwareSVGs hardwareSVGs6;
        IHardwareSVGs hardwareSVGs7;
        IHardwareSVGs hardwareSVGs8;
        IHardwareSVGs hardwareSVGs9;
        IHardwareSVGs hardwareSVGs10;
        IHardwareSVGs hardwareSVGs11;
        IHardwareSVGs hardwareSVGs12;
        IHardwareSVGs hardwareSVGs13;
        IHardwareSVGs hardwareSVGs14;
        IHardwareSVGs hardwareSVGs15;
        IHardwareSVGs hardwareSVGs16;
        IHardwareSVGs hardwareSVGs17;
        IHardwareSVGs hardwareSVGs18;
        IHardwareSVGs hardwareSVGs19;
        IHardwareSVGs hardwareSVGs20;
        IHardwareSVGs hardwareSVGs21;
        IHardwareSVGs hardwareSVGs22;
        IHardwareSVGs hardwareSVGs23;
        IHardwareSVGs hardwareSVGs24;
        IHardwareSVGs hardwareSVGs25;
        IHardwareSVGs hardwareSVGs26;
        IHardwareSVGs hardwareSVGs27;
        IHardwareSVGs hardwareSVGs28;
        IHardwareSVGs hardwareSVGs29;
        IHardwareSVGs hardwareSVGs30;
        IHardwareSVGs hardwareSVGs31;
        IHardwareSVGs hardwareSVGs32;
        IHardwareSVGs hardwareSVGs33;
        IHardwareSVGs hardwareSVGs34;
        IHardwareSVGs hardwareSVGs35;
        IHardwareSVGs hardwareSVGs36;
        IHardwareSVGs hardwareSVGs37;
        IHardwareSVGs hardwareSVGs38;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import './IShields.sol';

/// @dev Generate ShieldBadge SVG
interface IShieldBadgeSVGs {
    function generateShieldBadgeSVG(IShields.ShieldBadge shieldBadge) external view returns (string memory);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface IFrameSVGs {
    struct FrameData {
        string title;
        uint256 fee;
        string svgString;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

/// @dev Build Customizable Shields for an NFT
interface IShields is IERC721 {
    enum ShieldBadge {
        MAKER,
        STANDARD
    }

    struct Shield {
        bool built;
        uint16 field;
        uint16 hardware;
        uint16 frame;
        ShieldBadge shieldBadge;
        uint24[4] colors;
    }

    function build(
        uint16 field,
        uint16 hardware,
        uint16 frame,
        uint24[4] memory colors,
        uint256 tokenId
    ) external payable;

    function shields(uint256 tokenId)
        external
        view
        returns (
            uint16 field,
            uint16 hardware,
            uint16 frame,
            uint24 color1,
            uint24 color2,
            uint24 color3,
            uint24 color4,
            ShieldBadge shieldBadge
        );
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

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
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
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
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

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import './ICategories.sol';

interface IFieldSVGs {
    struct FieldData {
        string title;
        ICategories.FieldCategories fieldType;
        string svgString;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface IColors {
    event ColorAdded(uint24 color, string title);

    struct Color {
        string title;
        bool exists;
    }

    /// @notice Returns true if color exists in contract, else false.
    /// @param color 3-byte uint representing color
    /// @return true or false
    function colorExists(uint24 color) external view returns (bool);

    /// @notice Returns the title string corresponding to the 3-byte color
    /// @param color 3-byte uint representing color
    /// @return true or false
    function colorTitle(uint24 color) external view returns (string memory);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import './ICategories.sol';

interface IHardwareSVGs {
    struct HardwareData {
        string title;
        ICategories.HardwareCategories hardwareType;
        string svgString;
    }
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
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/IOGCards.sol";
import "./interfaces/ILayerDescriptor.sol";

import 'base64-sol/base64.sol';

contract OGCardDescriptor is Ownable {
    using Strings for uint256;
    using Strings for uint8;

    string public ogCardUrl = '';
    string public ogCardDescription = 'OGCards are NFTs which evolve after each different holder';
    address public immutable frontLayerDescriptor;
    address public backLayerDescriptor;

    constructor(address _frontLayerDescriptor, address _backLayerDescriptor)
    {
        frontLayerDescriptor = _frontLayerDescriptor;
        backLayerDescriptor = _backLayerDescriptor;
    }

    function setOGCardUrl(string memory _ogCardUrl)
        external
        onlyOwner
    {
        ogCardUrl = _ogCardUrl;
    }

    function setOGCardDescription(string memory _ogCardDescription)
        external
        onlyOwner
    {
        ogCardDescription = _ogCardDescription;
    }

    function setBackLayerDescriptor(address _backLayerDescriptor)
        external
        onlyOwner
    {
        backLayerDescriptor = _backLayerDescriptor;
    }

    function tokenURI(address ogCards, uint256 tokenId)
        external
        view
        returns (string memory)
    {
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            metadata(ogCards, tokenId)
                        )
                    )
            )
        );
    }

    function metadata(address ogCards, uint256 tokenId)
        public
        view
        returns (string memory)
    {
        IOGCards.Card memory card = IOGCards(ogCards).cardDetails(tokenId);
        (, string[] memory names) = IOGCards(ogCards).ogHolders(tokenId);
        string memory attributes = cardAttributes(card.borderType, card.transparencyLevel, card.maskType, card.dna, card.mintTokenId, card.isGiveaway, names);

        string memory externalUrl = '';
        if (bytes(ogCardUrl).length > 0) {
            externalUrl = string(abi.encodePacked(
                '"external_url": "',
                ogCardUrl,
                tokenId.toString(),
                '",'
            ));
        }

        return string(abi.encodePacked(
			'{',
				'"name": "OGCard #', tokenId.toString(), '",', 
				'"description": "',ogCardDescription,'",',
                '"image": "',
                    'data:image/svg+xml;base64,', Base64.encode(bytes(svgImage(ogCards, tokenId, card))), '",',
                    externalUrl,
				'"attributes": [', attributes, ']',
			'}'
		));
    }

    function cardAttributes(uint8 borderType, uint8 transparencyLevel, uint8 maskType, uint256 dna, uint256 mintTokenId, bool isGiveaway, string[] memory names)
        public
        pure
        returns (string memory)
    {
        string memory attributes = string(abi.encodePacked(
            borderColorTrait(borderType),
            ',',
            transparencyTrait(transparencyLevel),
            ',',
            maskTrait(maskType),
            ',',
            dnaTrait(dna),
            ',',
            ogsTraits(names),
            ',',
            mintTokenIdTrait(mintTokenId, maskType, isGiveaway),
            ',',
            giveawayTrait(isGiveaway)
        ));

        return attributes;
    }

    // Traits
    function traitDefinition(string memory name, string memory value)
        public
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(
            '{',
                '"trait_type": "', name ,'",',
                '"value": "', value ,'"',
            '}'
        ));
    }

    function borderColorTrait(uint8 borderType)
        public
        pure
        returns (string memory)
    {
        return traitDefinition('Border Color', borderColorString(borderType));
    }

    function transparencyTrait(uint8 transparencyLevel)
        public
        pure
        returns (string memory)
    {
        return traitDefinition('Transparency Level', transparencyLevelString(transparencyLevel));
    }

    function maskTrait(uint8 maskType)
        public
        pure
        returns (string memory)
    {
        return traitDefinition('Mask', maskTypeString(maskType));
    }

    function dnaTrait(uint256 dna)
        public
        pure
        returns (string memory)
    {
        return traitDefinition('DNA', dna.toString());
    }

    function giveawayTrait(bool isGiveaway)
        public
        pure
        returns (string memory)
    {
        string memory value = isGiveaway ? 'true' : 'false';
        return traitDefinition('Giveaway', value);
    }

    function mintTokenIdTrait(uint256 mintTokenId, uint8 maskType, bool isGiveaway)
        public
        pure
        returns (string memory)
    {
        string memory value = !isGiveaway && maskType > 0 ? mintTokenId.toString() : 'None';
        return traitDefinition('MintTokenId', value);
    }

    function ogsTraits(string[] memory names)
        public
        pure
        returns (string memory)
    {
        string memory traitsDefinitions = string(abi.encodePacked(
            '{',
                '"trait_type": "OGs",',
                '"value": ', names.length.toString(),
            '}'
        ));

        if (names.length > 0) {
            for (uint256 i = 0; i < names.length; i++) {
                string memory name = names[i];
                traitsDefinitions = string(abi.encodePacked(
                    traitsDefinitions,
                    ',',
                    traitDefinition('OG', name)
                ));
            }
        }

        return traitsDefinitions;
    }

    // Attributes to String
    function borderColorString(uint8 borderType)
        public
        pure
        returns (string memory)
    {
        return (borderType == 0 ? "#00ccff": // Light blue
                    (borderType == 1 ? "#ffffff" : // White
                        (borderType == 2 ? "#1eff00" : // Green
                            (borderType == 3 ? "#0070dd" : // Blue
                                (borderType == 4 ? "#a335ee" : "#daa520"))))); // Purple and Gold
    }

    function maskTypeString(uint8 maskType)
        public
        pure
        returns (string memory)
    {
        return (maskType == 0 ? "Ethereum" :
                    (maskType == 1 ? "CryptoPunk" :
                        (maskType == 2 ? "Animal Coloring Book" :
                            (maskType == 3 ? "Purrnelope's Country Club" : ""))));
    }

    function transparencyLevelString(uint8 transparencyLevel)
        public
        pure
        returns (string memory)
    {
        return transparencyLevel.toString();
    }

    function svgImage(address ogCards, uint256 tokenId, IOGCards.Card memory card)
        public
        view
        returns (string memory)
    {
        string memory font = "Avenir, Helvetica, Arial, sans-serif";
        string memory borderColor = borderColorString(card.borderType);

        return string(abi.encodePacked(
            '<svg id="ogcard-',tokenId.toString(),'" data-name="OGCard" xmlns="http://www.w3.org/2000/svg" width="300" height="300" class="ogcard-svg">',
                svgDefsAndStyles(tokenId, card.maskType, font, borderColor),
                '<g clip-path="url(#corners)">',
                    svgLayers(ogCards, tokenId, font, borderColor, card),
                    '<rect width="100%" height="100%" rx="30" ry="30" stroke="',borderColor,'" stroke-width="2" fill="rgba(0,0,0,0)"></rect>',
                '</g>',
                '</svg>'
		));
    }

    function svgLayers(address ogCards, uint256 tokenId, string memory font, string memory borderColor, IOGCards.Card memory card)
        public
        view
        returns (string memory)
    {
        return string(abi.encodePacked(
            ILayerDescriptor(backLayerDescriptor).svgLayer(ogCards, tokenId, font, borderColor, card),
            ILayerDescriptor(frontLayerDescriptor).svgLayer(ogCards, tokenId, font, borderColor, card)
        ));
    }

    function svgDefsAndStyles(uint256 tokenId, uint8 maskType, string memory font, string memory borderColor)
        public
        view
        returns (string memory)
    {
        return string(abi.encodePacked(
            '<defs>',
                '<rect id="rect-corners" width="100%" height="100%" rx="30" ry="30" />',
                ILayerDescriptor(frontLayerDescriptor).svgMask(maskType, borderColor, true, false),
                '<text id="token-id" x="205" y="270" font-family="',font,'" font-weight="bold" font-size="30px" fill="#000000">',
                '#',uint2strMask(tokenId),
                '</text>',
                '<path id="text-path-border" d="M35 15 H265 a20 20 0 0 1 20 20 V265 a20 20 0 0 1 -20 20 H35 a20 20 0 0 1 -20 -20 V35 a20 20 0 0 1 20 -20 z"></path>',
                '<clipPath id="corners"><use href="#rect-corners" /></clipPath>',
                '<mask id="mask">',
                    '<rect width="100%" height="100%" fill="#ffffff"></rect>',
                    '<g class="mask-path">',
                        ILayerDescriptor(frontLayerDescriptor).svgMask(maskType, borderColor, true, true),
                    '</g>',
                    '<use href="#token-id" />',
                '</mask>',
            '</defs>',
            '<style>',
                '.mask-path {animation: 2s mask-path infinite alternate linear;} @keyframes mask-path {0%, 100% {transform: translateY(-3%)}50% {transform: translateY(3%)}}',
            '</style>'
        ));
    }

    function uint2strMask(uint _i) internal pure returns (string memory _uintAsString) {
        uint maskSize = 3;
        if (_i == 0) {
            return "000";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(maskSize);
        uint k = maskSize;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        while (k != 0) {
            k = k-1;
            uint8 temp = 48;
            bstr[k] = bytes1(temp);
        }
        return string(bstr);
    }
}

// SPDX-License-Identifier: MIT

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
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
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

// SPDX-License-Identifier: MIT

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
pragma solidity >=0.8.4;

interface IOGCards {
    struct Card {
        bool isGiveaway;
        uint8 borderType;
        uint8 transparencyLevel;
        uint8 maskType;
        uint256 dna;
        uint256 mintTokenId;
        address[] holders;
    }

    function cardDetails(uint256 tokenId) external view returns (Card memory);

    function ownerOf(uint256 tokenId) external view returns (address);

    function isOG(address _og) external view returns (bool);

    function holderName(address _holder) external view returns (string memory);

    function ogHolders(uint256 tokenId)
        external
        view
        returns (address[] memory, string[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./IOGCards.sol";

interface ILayerDescriptor {
    struct Layer {
        bool isGiveaway;
        uint8 maskType;
        uint8 transparencyLevel;
        uint256 tokenId;
        uint256 dna;
        uint256 mintTokenId;
        string font;
        string borderColor;
        address ogCards;
    }
    function svgLayer(address ogCards, uint256 tokenId, string memory font, string memory borderColor, IOGCards.Card memory card)
        external
        view
        returns (string memory);

    function svgMask(uint8 maskType, string memory borderColor, bool isDef, bool isMask)
        external
        pure
        returns (string memory);
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

// SPDX-License-Identifier: MIT

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


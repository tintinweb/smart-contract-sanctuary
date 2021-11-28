// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../IVampireGame.sol";
import "./TraitMetadata.sol";
import "./TraitDraw.sol";
import "./TokenTraits.sol";
import "./Base64.sol";
import "./ITraits.sol";

contract Traits is Ownable, ITraits {
    using Strings for uint256;

    /// ==== Structs

    /// @dev struct to store each trait name and base64 encoded image
    struct Trait {
        string name;
        string png;
    }

    /// ==== Immutable

    /// @notice traits mapping
    /// 0~8 Vampire; 9~17 Humans.
    mapping(uint8 => mapping(uint8 => Trait)) public traitData;

    /// @dev mapping from predator index to predator score
    string[4] private predatorScores = ["8", "7", "6", "5"];

    IVampireGame public vgame;

    string unrevealedImage;

    // ==== Mutable

    constructor() {}

    /// ==== Internal

    /// @dev return the SVG of a Vampire
    /// make sure the token is actually a Vampire by checking tt.isVampire before calling this function
    /// @param tt the token traits
    /// @return the svg string of the vampire
    function makeVampireSVG(TokenTraits memory tt)
        internal
        view
        returns (string memory)
    {
        string[] memory images = new string[](5);
        images[3] = TraitDraw.drawImageTag(traitData[16][tt.cape].png);
        images[0] = TraitDraw.drawImageTag(traitData[9][tt.skin].png);
        images[2] = TraitDraw.drawImageTag(traitData[11][tt.clothes].png);
        images[1] = TraitDraw.drawImageTag(traitData[10][tt.face].png);
        images[4] = TraitDraw.drawImageTag(traitData[17][tt.predatorIndex].png);
        return TraitDraw.drawSVG(images);
    }

    /// @dev return the SVG of a Human
    /// make sure the token is actually a Human by checking tt.isVampire before calling this function
    /// @param tt the token traits
    /// @return the svg string of the human
    function makeHumanSVG(TokenTraits memory tt)
        internal
        view
        returns (string memory)
    {
        string[] memory images = new string[](7);
        images[0] = TraitDraw.drawImageTag(traitData[0][tt.skin].png);
        images[4] = TraitDraw.drawImageTag(traitData[4][tt.boots].png);
        images[3] = TraitDraw.drawImageTag(traitData[3][tt.pants].png);
        images[1] = TraitDraw.drawImageTag(traitData[1][tt.face].png);
        images[6] = TraitDraw.drawImageTag(traitData[6][tt.hair].png);
        images[2] = TraitDraw.drawImageTag(traitData[2][tt.clothes].png);
        images[5] = TraitDraw.drawImageTag(traitData[5][tt.accessory].png);
        return TraitDraw.drawSVG(images);
    }

    /// @dev return the metadata attributes of a Vampire
    /// make sure the token is actually a Vampire by checking tt.isVampire before calling this function
    /// @param tt the token traits
    /// @param genZero if the token is part of the first 20% tokens
    /// @return the JSON metadata string of the Vampire
    function makeVampireMetadata(TokenTraits memory tt, bool genZero)
        internal
        view
        returns (string memory)
    {
        string[] memory attributes = new string[](7);
        attributes[0] = TraitMetadata.makeAttributeJSON("Type", "Vampire");
        attributes[1] = TraitMetadata.makeAttributeJSON(
            "Generation",
            genZero ? "Gen 0" : "Gen 1"
        );
        attributes[2] = TraitMetadata.makeAttributeJSON(
            "Skin",
            traitData[0][tt.skin].name
        );
        attributes[3] = TraitMetadata.makeAttributeJSON(
            "Face",
            traitData[1][tt.face].name
        );
        attributes[4] = TraitMetadata.makeAttributeJSON(
            "Clothes",
            traitData[2][tt.clothes].name
        );
        attributes[5] = TraitMetadata.makeAttributeJSON(
            "Cape",
            traitData[7][tt.cape].name
        );
        attributes[6] = TraitMetadata.makeAttributeJSON(
            "Predator Score",
            predatorScores[tt.predatorIndex]
        );
        return TraitMetadata.makeAttributeListJSON(attributes);
    }

    /// @dev return the metadata attributes of a Human
    /// make sure the token is actually a Human by checking tt.isVampire before calling this function
    /// @param tt the token traits
    /// @param genZero if the token is part of the first 20% tokens
    /// @return the JSON metadata string of the Human
    function makeHumanMetadata(TokenTraits memory tt, bool genZero)
        internal
        view
        returns (string memory)
    {
        string[] memory attributes = new string[](9);
        attributes[0] = TraitMetadata.makeAttributeJSON("Type", "Human");
        attributes[1] = TraitMetadata.makeAttributeJSON(
            "Generation",
            genZero ? "Gen 0" : "Gen 1"
        );
        attributes[2] = TraitMetadata.makeAttributeJSON(
            "Skin",
            traitData[0][tt.skin].name
        );
        attributes[3] = TraitMetadata.makeAttributeJSON(
            "Face",
            traitData[1][tt.face].name
        );
        attributes[4] = TraitMetadata.makeAttributeJSON(
            "T-Shirt",
            traitData[2][tt.clothes].name
        );
        attributes[5] = TraitMetadata.makeAttributeJSON(
            "Pants",
            traitData[3][tt.pants].name
        );
        attributes[6] = TraitMetadata.makeAttributeJSON(
            "Boots",
            traitData[4][tt.boots].name
        );
        attributes[7] = TraitMetadata.makeAttributeJSON(
            "Accessory",
            traitData[5][tt.accessory].name
        );
        attributes[8] = TraitMetadata.makeAttributeJSON(
            "Hair",
            traitData[6][tt.hair].name
        );
        return TraitMetadata.makeAttributeListJSON(attributes);
    }

    /// ==== Public / View

    /// @notice return the svg for a specific tokenId
    /// using to help with testing and debugging
    /// @param tokenId the id of the token to draw the SVG
    /// @return string with the svg tag with all the token layers assembled
    function tokenSVG(uint256 tokenId) public view returns (string memory) {
        TokenTraits memory tt = vgame.getTokenTraits(tokenId);
        return tt.isVampire ? makeVampireSVG(tt) : makeHumanSVG(tt);
    }

    /// @notice generates the metadata for a token
    /// @param tokenId the token id
    /// @return a string with a JSON array containing the traits
    function tokenMetadata(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        if (vgame.isTokenRevealed(tokenId)) {
            TokenTraits memory tt = vgame.getTokenTraits(tokenId);
            bool genZero = tokenId <= vgame.getGenZeroSupply();

            return
                TraitMetadata.makeMetadata(
                    abi.encodePacked(
                        tt.isVampire ? "Vampire #" : "Human #",
                        tokenId.toString()
                    ),
                    "The world has ended and humanity lost. Vampires rule over mankind with no mercy, locking Humans away in Blood Farms. This does not means that Vampires are safe, Farms can lose all Blood Bags or Coffins when other Vampires attack. All metadata and images are generated and stored on-chain.",
                    // create the svg > base64 encode > prefix with data:image/svg...
                    abi.encodePacked(
                        "data:image/svg+xml;base64,",
                        Base64.encode(
                            bytes(
                                tt.isVampire
                                    ? makeVampireSVG(tt)
                                    : makeHumanSVG(tt)
                            )
                        )
                    ),
                    tt.isVampire
                        ? makeVampireMetadata(tt, genZero)
                        : makeHumanMetadata(tt, genZero)
                );
        }

        return
            string(
                abi.encodePacked(
                    '{"name":"Coffin #',
                    tokenId.toString(),
                    '","description":"A coffin from The Vampire Game. Whats inside? A Human or a Vampire?","image":"',
                    unrevealedImage,
                    '"}'
                )
            );
    }

    /// @notice generate the on-chain token metadata
    /// @param tokenId the token id to be generated
    /// @return the metadata string using data:application/json;base64
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string memory metadata = tokenMetadata(tokenId);

        // create metadata |> base64 encode |> prefix with data:application/json...
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(bytes(metadata))
                )
            );
    }

    /// ==== Only Owner

    /// @notice sets the image that will be shown when nft is not yet revealed
    /// @param _unrevealedImage the image, could be a link or base64 encoded img
    function setUnrevealedImage(string calldata _unrevealedImage)
        external
        onlyOwner
    {
        unrevealedImage = _unrevealedImage;
    }

    /// @notice set the address of the VampireGame contract
    /// @param vgameAddress the VampireGame contract address
    function setVampireGame(address vgameAddress) external onlyOwner {
        vgame = IVampireGame(vgameAddress);
    }

    /// @notice Upload trait variants for each trait type
    /// list of trait types:
    /// 0  - Human - Skin
    /// 1  - Human - Face
    /// 2  - Human - T-Shirt
    /// 3  - Human - Pants
    /// 4  - Human - Boots
    /// 5  - Human - Accessory
    /// 6  - Human - Hair
    /// 7  - NONE
    /// 8  - NONE
    /// 9  - Vampire - Skin
    /// 10 - Vampire - Face
    /// 11 - Vampire - Clothes
    /// 12 - NONE
    /// 13 - NONE
    /// 14 - NONE
    /// 15 - NONE
    /// 16 - Vampire - Cape
    /// 17 - Vampire - Predator Index
    /// @param traitType the index of the traitType.
    /// @param traitIds the list of ids of each trait
    /// @param traits the list of traits with name and base64 encoded png. Should match the length of traitIds.
    function setTraits(
        uint8 traitType,
        uint8[] calldata traitIds,
        Trait[] calldata traits
    ) external onlyOwner {
        require(traitIds.length == traits.length, "INPUTS_DIFFERENT_LENGTH");
        for (uint256 i = 0; i < traits.length; i++) {
            traitData[traitType][traitIds[i]] = Trait(
                traits[i].name,
                traits[i].png
            );
        }
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

pragma solidity ^0.8.6;

import "./traits/TokenTraits.sol";

/// @notice Interface to interact with the VampireGame contract
interface IVampireGame {
    /// @notice get the total supply of gen-0
    function getGenZeroSupply() external view returns (uint256);

    /// @notice get the total supply of tokens
    function getMaxSupply() external view returns (uint256);

    /// @notice get the TokenTraits for a given tokenId
    function getTokenTraits(uint256 tokenId) external view returns (TokenTraits memory);

    /// @notice returns true if a token is aleady revealed
    function isTokenRevealed(uint256 tokenId) external view returns (bool);
}

/// @notice Interface to control parts of the VampireGame ERC 721
interface IVampireGameControls {
    /// @notice mint any amount of nft to any address
    /// Requirements:
    /// - message sender should be an allowed address (game contract)
    /// - amount + totalSupply() has to be smaller than MAX_SUPPLY
    function mintFromController(address receiver, uint256 amount) external;

    /// @notice reveal a list of tokens using specific seeds for each
    function controllerRevealTokens(uint256[] calldata tokenIds, uint256[] calldata _seeds) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/// @notice A library with functions to generate VampireGame NFT metadata
library TraitMetadata {
    /// @notice Generate an NFT metadata
    /// @param name a string with the NFT name
    /// @param description a string with the NFT description,
    /// @param image a string with the NFT encoded image
    /// @param attributes a JSON string with the NFT attributes
    /// @return a JSON string with the NFT metadata
    function makeMetadata(
        bytes memory name,
        string memory description,
        bytes memory image,
        string memory attributes
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '{"name":"',
                    name,
                    '","description":"',
                    description,
                    '","image":"',
                    image,
                    '","attributes":',
                    attributes,
                    "}"
                )
            );
    }

    /// @notice Generates a JSON string for an NFT metadata attribute
    /// @param traitType the attribute trait type
    /// @param value the attribute value
    /// @return a JSON string for the attribute
    function makeAttributeJSON(string memory traitType, string memory value)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '{"trait_type":"',
                    traitType,
                    '","value":"',
                    value,
                    '"}'
                )
            );
    }

    /// @notice Generates a string with a JSON array containing all the attributes
    /// @param attributes a list of JSON strings of each attribute
    /// @return the JSON string with the attribute list
    function makeAttributeListJSON(string[] memory attributes)
        internal
        pure
        returns (string memory)
    {
        bytes memory attributeListBytes = "[";

        for (uint256 i = 0; i < attributes.length; i++) {
            attributeListBytes = abi.encodePacked(
                attributeListBytes,
                attributes[i],
                i != attributes.length - 1 ? "," : "]"
            );
        }

        return string(attributeListBytes);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/// @notice A library with functions to draw VampireGame SVGs
library TraitDraw {
    /// @notice generates an <image> element using base64 encoded PNGs
    /// @param png the base64 encoded PNG data
    /// @return a string with the <image> element
    function drawImageTag(string memory png)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '<image x="4" y="4" width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
                    png,
                    '"/>'
                )
            );
    }

    /// @notice draw an SVG using png image data
    /// @param images a list of images generated with drawImageTag
    /// @return the SVG tag with all png images
    function drawSVG(string[] memory images)
        internal
        pure
        returns (string memory)
    {
        bytes memory imagesBytes;

        for (uint256 i = 0; i < images.length; i++) {
            imagesBytes = abi.encodePacked(imagesBytes, images[i]);
        }

        return
            string(
                abi.encodePacked(
                    '<svg id="vampiregame" width="100%" height="100%" version="1.1" viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                    string(imagesBytes),
                    "</svg>"
                )
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

struct TokenTraits {
    /// @dev every initialised token should have this as true
    /// this is just used to check agains a non-initialized struct
    bool exists;
    bool isVampire;
    // Shared Traits
    uint8 skin;
    uint8 face;
    uint8 clothes;
    // Human-only Traits
    uint8 pants;
    uint8 boots;
    uint8 accessory;
    uint8 hair;
    // Vampire-only Traits
    uint8 cape;
    uint8 predatorIndex;
}

// SPDX-License-Identifier: MIT
// Source: https://github.com/Brechtpd/base64/blob/4d85607b18d981acff392d2e99ba654305552a97/base64.sol

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
/// @notice removed decoding function from original code
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

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
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
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

pragma solidity ^0.8.6;

interface ITraits {
  function tokenURI(uint256 tokenId) external view returns (string memory);
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
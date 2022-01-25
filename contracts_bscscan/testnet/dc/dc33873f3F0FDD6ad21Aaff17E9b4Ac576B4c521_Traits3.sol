// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ITraits.sol";
import "./ISheriffAndBandit.sol";

contract Traits3 is Ownable, ITraits {
    using Strings for uint256;

    uint256 private alphaTypeIndex = 15;

    // struct to store each trait's data for metadata and rendering
    struct Trait {
        string name;
        string png;
    }

    string sheriffBody;
    string banditBody;

    // mapping from trait type (index) to its name
    string[15] _traitTypes = [
        "BanditUniform",
        "BanditHair",
        "BanditEyes",
        "BanditGun",
        "BanditHat",
        "BanditHandcuff",
        "BanditMask",
        "BanditNecklace",
        "SheriffUniform",
        "SheriffHair",
        "SheriffEyes",
        "SheriffGun",
        "SheriffHat",
        "SheriffMustache",
        "SheriffStars"
    ];
    // storage of each traits name and base64 PNG data
    mapping(uint8 => mapping(uint8 => Trait)) public traitData;
    mapping(uint8 => uint8) public traitCountForType;
    // mapping from alphaIndex to its score
    string[4] _alphas = ["8", "7", "6", "5"];

    ISheriffAndBandit public sheriffAndBandit;

    function selectTrait(uint16 seed, uint8 traitType)
        external
        view
        override
        returns (uint8)
    {
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
        uint8 modOf = traitCountForType[traitType] > 0
            ? traitCountForType[traitType]
            : 10;
        return uint8(seed % modOf);
    }

    /***ADMIN */

    function setGame(address _sheriffAndBandit) external onlyOwner {
        sheriffAndBandit = ISheriffAndBandit(_sheriffAndBandit);
    }

    function uploadBodies(string calldata _sheriff, string calldata _bandit)
        external
        onlyOwner
    {
        sheriffBody = _sheriff;
        banditBody = _bandit;
    }

    /**
     * administrative to upload the names and images associated with each trait
     * @param traitType the trait type to upload the traits for (see traitTypes for a mapping)
     * @param traits the names and base64 encoded PNGs for each trait
     */
    function uploadTraits(
        uint8 traitType,
        uint8[] calldata traitIds,
        Trait[] calldata traits
    ) external onlyOwner {
        require(traitIds.length == traits.length, "Mismatched inputs");
        uint256 len = traits.length;

        for (uint256 i = 0; i < len; i++) {
            traitData[traitType][traitIds[i]] = Trait(
                traits[i].name,
                traits[i].png
            );
        }
    }

    function setTraitCountForType(uint8[] memory _tType, uint8[] memory _len)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _tType.length; i++) {
            traitCountForType[_tType[i]] = _len[i];
        }
    }

    /***RENDER */

    /**
     * generates an <image> element using base64 encoded PNGs
     * @param trait the trait storing the PNG data
     * @return the <image> element
     */
    function drawTrait(Trait memory trait)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '<image x="4" y="4" width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
                    trait.png,
                    '"/>'
                )
            );
    }

    function draw(string memory png) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<image x="4" y="4" width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
                    png,
                    '"/>'
                )
            );
    }

    /**
     * generates an entire SVG by composing multiple <image> elements of PNGs
     * @param tokenId the ID of the token to generate an SVG for
     * @return a valid SVG of the Bandit / Sheriff
     */
    function drawSVG(uint256 tokenId) public view returns (string memory) {
        (
            ISheriffAndBandit.BanditSheriff memory t,
            ISheriffAndBandit.Sheriff memory s,
            ISheriffAndBandit.Bandit memory b
        ) = sheriffAndBandit.getTokenTraits(tokenId);

        string memory svgString;
        if (t.isBandit) {
            svgString = string(
                abi.encodePacked(
                    draw(banditBody),
                    drawTrait(traitData[0][t.uniform % traitCountForType[0]]),
                    drawTrait(traitData[1][t.hair % traitCountForType[1]]),
                    drawTrait(traitData[2][t.eyes % traitCountForType[2]]),
                    drawTrait(traitData[3][t.gun % traitCountForType[3]]),
                    drawTrait(traitData[4][t.hat % traitCountForType[4]]),
                    drawTrait(traitData[5][b.handcuff % traitCountForType[5]]),
                    drawTrait(traitData[6][b.mask % traitCountForType[6]]),
                    drawTrait(traitData[7][b.necklace % traitCountForType[7]])
                )
            );
        } else {
            svgString = string(
                abi.encodePacked(
                    draw(sheriffBody),
                    drawTrait(traitData[8][t.uniform % traitCountForType[8]]),
                    drawTrait(traitData[9][t.hair % traitCountForType[9]]),
                    drawTrait(traitData[10][t.eyes % traitCountForType[10]]),
                    drawTrait(traitData[11][t.gun % traitCountForType[11]]),
                    drawTrait(traitData[12][t.hat % traitCountForType[12]]),
                    // drawTrait(traitData[13][s.chain % traitCountForType[13]]),
                    drawTrait(
                        traitData[13][s.mustache % traitCountForType[13]]
                    ),
                    drawTrait(traitData[14][s.stars % traitCountForType[14]])
                )
            );
        }

        return
            string(
                abi.encodePacked(
                    '<svg id="sheriffAndBandit" width="100%" height="100%" version="1.1" viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                    svgString,
                    "</svg>"
                )
            );
    }

    /**
     * generates an attribute for the attributes array in the ERC721 metadata standard
     * @param traitType the trait type to reference as the metadata key
     * @param value the token's trait associated with the key
     * @return a JSON dictionary for the single attribute
     */
    function attributeForTypeAndValue(
        string memory traitType,
        string memory value
    ) internal pure returns (string memory) {
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

    /**
     * generates an array composed of all the individual traits and values
     * @param tokenId the ID of the token to compose the metadata for
     * @return a JSON array of all of the attributes for given token ID
     */
    function compileAttributes(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        (
            ISheriffAndBandit.BanditSheriff memory t,
             ISheriffAndBandit.Sheriff memory s,
             ISheriffAndBandit.Bandit memory b
        ) = sheriffAndBandit.getTokenTraits(tokenId);
        string memory traits;
        if (t.isBandit) {
            traits = string(
                abi.encodePacked(
                    attributeForTypeAndValue(
                        _traitTypes[0],
                        traitData[0][t.uniform % traitCountForType[0]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        _traitTypes[1],
                        traitData[1][t.hair % traitCountForType[1]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        _traitTypes[2],
                        traitData[2][t.eyes % traitCountForType[2]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        _traitTypes[3],
                        traitData[3][t.gun % traitCountForType[3]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        _traitTypes[4],
                        traitData[4][t.hat % traitCountForType[4]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        _traitTypes[5],
                        traitData[5][b.handcuff % traitCountForType[5]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        _traitTypes[6],
                        traitData[6][b.mask % traitCountForType[6]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        _traitTypes[7],
                        traitData[7][b.necklace % traitCountForType[7]].name
                    ),
                    ","
                )
            );
        } else {
            traits = string(
                abi.encodePacked(
                    attributeForTypeAndValue(
                        _traitTypes[8],
                        traitData[8][t.uniform % traitCountForType[8]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        _traitTypes[9],
                        traitData[9][t.hair % traitCountForType[9]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        _traitTypes[10],
                        traitData[10][t.eyes % traitCountForType[10]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        _traitTypes[11],
                        traitData[11][t.gun % traitCountForType[11]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        _traitTypes[12],
                        traitData[12][t.hat % traitCountForType[12]].name
                    ),
                    ",",
                    // attributeForTypeAndValue(
                    //     _traitTypes[13],
                    //     traitData[13][s.chain % traitCountForType[13]].name
                    // ),
                    // ",",
                    attributeForTypeAndValue(
                        _traitTypes[13],
                        traitData[13][s.mustache % traitCountForType[13]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        _traitTypes[14],
                        traitData[14][s.stars % traitCountForType[14]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        "Alpha Score",
                        _alphas[s.alphaIndex]
                    ),
                    ","
                )
            );
        }
        return
            string(
                abi.encodePacked(
                    "[",
                    traits,
                    '{"trait_type":"Generation","value":',
                    tokenId <= sheriffAndBandit.getPaidTokens()
                        ? '"Gen 0"'
                        : '"Gen 1"',
                    '},{"trait_type":"Type","value":',
                    t.isBandit ? '"Bandit"' : '"Sheriff"',
                    "}]"
                )
            );
    }

    /**
     * generates a base64 encoded metadata response without referencing off-chain content
     * @param tokenId the ID of the token to generate the metadata for
     * @return a base64 encoded JSON dictionary of the token's metadata and SVG
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        (ISheriffAndBandit.BanditSheriff memory t, , ) = sheriffAndBandit
            .getTokenTraits(tokenId);

        string memory metadata = string(
            abi.encodePacked(
                '{"name": "',
                t.isBandit ? "Bandit #" : "Sheriff #",
                tokenId.toString(),
                '", "description": "Sheriff & Bandit Game is a new generation play-to-earn NFT game on Avalanche that incorporates probability-based derivatives alongside NFTs. Through a vast array of choices and decision-making possibilities, Sheriff & Bandit Game promises to instil excitement and curiosity amongst the community as every individual adopts different strategies to do better than one another and to come out on top. The real question is, are you #TeamBandit or #TeamSheriff? Choose wisely or watch the other get rich!", "image": "data:image/svg+xml;base64,',
                base64(bytes(drawSVG(tokenId))),
                '", "attributes":',
                compileAttributes(tokenId),
                "}"
            )
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    base64(bytes(metadata))
                )
            );
    }

    /***BASE 64 - Written by Brech Devos */

    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function base64(bytes memory data) internal pure returns (string memory) {
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

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface ITraits {
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function selectTrait(uint16 seed, uint8 traitType) external view returns(uint8);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface ISheriffAndBandit {

    struct Bandit {
        uint8 handcuff;
        uint8 mask;
        uint8 necklace;
    }

    struct Sheriff {
        //uint8 chain;
        uint8 mustache;
        uint8 stars;
        uint8 alphaIndex;
    }

    // struct to store each token's traits
    struct BanditSheriff {
        bool isBandit;
        uint8 uniform;
        uint8 hair;
        uint8 eyes;
        uint8 gun;
        uint8 hat;
    }

    function getPaidTokens() external view returns (uint256);
    function getTokenTraits(uint256 tokenId) external view returns (BanditSheriff memory, Sheriff memory, Bandit memory);
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
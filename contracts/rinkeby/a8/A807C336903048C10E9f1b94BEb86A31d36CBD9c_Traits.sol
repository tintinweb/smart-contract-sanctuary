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
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

import './interfaces/ITraits.sol';
import './interfaces/IChickenNoodleSoup.sol';

contract Traits is Ownable, ITraits {
    using Strings for uint256;

    // mapping from trait type (index) to its name
    string[7] _traitTypes = [
        'Backgrounds',
        'Snake Bodies',
        'Mouth Accessories',
        'Pupils',
        'Body Accessories',
        'Hats',
        'Tier'
    ];

    // storage for image baseURI
    string public imageBaseURI;
    // storage for metadata description
    string public description;
    // storage of each traits name
    mapping(uint8 => mapping(uint8 => string)) public traitData;

    // mapping from tier to its score
    string[4] _tiers = ['4', '3', '2', '1'];

    IChickenNoodleSoup public chickenNoodleSoup;

    constructor(string memory _imageBaseURI) {
        imageBaseURI = _imageBaseURI;
    }

    /** ADMIN */

    function setChickenNoodleSoup(address _chickenNoodleSoup)
        external
        onlyOwner
    {
        chickenNoodleSoup = IChickenNoodleSoup(_chickenNoodleSoup);
    }

    /**
     * administrative to set metadata description
     * @param _imageBaseURI base URI for the image
     */
    function setImageBaseURI(string calldata _imageBaseURI) external onlyOwner {
        imageBaseURI = _imageBaseURI;
    }

    /**
     * administrative to set metadata description
     * @param _description the standard description for metadata
     */
    function setDescription(string calldata _description) external onlyOwner {
        description = _description;
    }

    /**
     * administrative to upload the names and images associated with each trait
     * @param traitType the trait type to upload the traits for (see traitTypes for a mapping)
     * @param names the names for each trait
     */
    function uploadTraits(
        uint8 traitType,
        uint8[] calldata traitIds,
        string[] calldata names
    ) external onlyOwner {
        require(traitIds.length == names.length, 'Mismatched inputs');
        for (uint256 i = 0; i < names.length; i++) {
            traitData[traitType][traitIds[i]] = names[i];
        }
    }

    /** RENDER */

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
        IChickenNoodleSoup.ChickenNoodle memory s = chickenNoodleSoup
            .getTokenTraits(tokenId);
        string memory traits;

        if (s.isChicken) {
            traits = string(
                abi.encodePacked(
                    attributeForTypeAndValue(
                        _traitTypes[0],
                        traitData[0][s.backgrounds]
                    ),
                    ',',
                    attributeForTypeAndValue(
                        _traitTypes[1],
                        traitData[1][s.snakeBodies]
                    ),
                    ',',
                    attributeForTypeAndValue(
                        _traitTypes[2],
                        traitData[2][s.mouthAccessories]
                    ),
                    ',',
                    attributeForTypeAndValue(
                        _traitTypes[3],
                        traitData[3][s.pupils]
                    ),
                    ',',
                    attributeForTypeAndValue(
                        _traitTypes[4],
                        traitData[4][s.bodyAccessories]
                    ),
                    ',',
                    attributeForTypeAndValue(
                        _traitTypes[5],
                        traitData[5][s.hats]
                    ),
                    ','
                )
            );
        } else {
            traits = string(
                abi.encodePacked(
                    attributeForTypeAndValue(
                        _traitTypes[0],
                        traitData[0][s.backgrounds]
                    ),
                    ',',
                    attributeForTypeAndValue(
                        _traitTypes[1],
                        traitData[1][s.snakeBodies]
                    ),
                    ',',
                    attributeForTypeAndValue(
                        _traitTypes[2],
                        traitData[2][s.mouthAccessories]
                    ),
                    ',',
                    attributeForTypeAndValue(
                        _traitTypes[3],
                        traitData[3][s.pupils]
                    ),
                    ',',
                    attributeForTypeAndValue(
                        _traitTypes[4],
                        traitData[4][s.bodyAccessories]
                    ),
                    ',',
                    attributeForTypeAndValue(
                        _traitTypes[5],
                        traitData[5][s.hats]
                    ),
                    ',',
                    attributeForTypeAndValue('Tier', _tiers[s.tier]),
                    ','
                )
            );
        }

        return
            string(
                abi.encodePacked(
                    '[',
                    traits,
                    '{"trait_type":"Generation","value":',
                    tokenId <= chickenNoodleSoup.getPaidTokens()
                        ? '"Gen 0"'
                        : '"Gen 1"',
                    '},{"trait_type":"Type","value":',
                    s.isChicken ? '"Chicken"' : '"Noodle"',
                    '}]'
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
        IChickenNoodleSoup.ChickenNoodle memory s = chickenNoodleSoup
            .getTokenTraits(tokenId);

        string memory metadata = string(
            abi.encodePacked(
                '{"name": "',
                s.isChicken ? 'Chicken #' : 'Noodle #',
                tokenId.toString(),
                '", "image": "',
                imageBaseURI,
                tokenId.toString(),
                '", "description": "',
                description,
                '", "attributes":',
                compileAttributes(tokenId),
                '}'
            )
        );

        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    base64(bytes(metadata))
                )
            );
    }

    /** BASE 64 - Written by Brech Devos */

    string internal constant TABLE =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

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

interface IChickenNoodleSoup {
  // struct to store each token's traits
  struct ChickenNoodle {
    bool minted;
    bool isChicken;
    uint8 backgrounds;
    uint8 snakeBodies;
    uint8 mouthAccessories;
    uint8 pupils;
    uint8 bodyAccessories;
    uint8 hats;
    uint8 tier;
  }

  function getPaidTokens() external view returns (uint256);
  function getTokenTraits(uint256 tokenId) external view returns (ChickenNoodle memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITraits {
  function tokenURI(uint256 tokenId) external view returns (string memory);
}
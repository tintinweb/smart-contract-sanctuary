// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/Strings.sol";

contract Metadata is Ownable {
    using Strings for uint256;

    struct Trait {
        string name;
        string image;
    }

    string[4] categoryNames = ["Color", "Expression", "Accesory", "Hat"];

    mapping(uint8=>mapping(uint8=>Trait)) public traitData;

    constructor() {}

    function uploadTraits(uint8 category, Trait[] calldata traits)
        public
        onlyOwner
    {
        require(traits.length == 16, "Wrong length");
        for (uint8 i = 0; i < traits.length; i++) {
            traitData[category][i] = Trait(traits[i].name, traits[i].image);
        }
    }

    function drawTrait(Trait memory trait)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '<image x="0" y="0" width="64" height="64" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
                    trait.image,
                    '"/>'
                )
            );
    }

    function drawSVG(bool isFox, uint8[] memory traits)
        public
        view
        returns (string memory)
    {
        uint8 offset = isFox ? 4 : 0;
        string memory svgString = string(
            abi.encodePacked(
                drawTrait(traitData[offset][traits[0]]),
                drawTrait(traitData[1 + offset][traits[1]]),
                drawTrait(traitData[2 + offset][traits[2]]),
                drawTrait(traitData[3 + offset][traits[3]])
            )
        );

        return
            string(
                abi.encodePacked(
                    '<svg id="foxhen" width="100%" height="100%" version="1.1" viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                    svgString,
                    "</svg>"
                )
            );
    }

    function attributeForTypeAndValue(
        string memory categoryName,
        string memory value
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '{"trait_type":"',
                    categoryName,
                    '","value":"',
                    value,
                    '"}'
                )
            );
    }

    function compileAttributes(
        bool isFox,
        uint8[] memory traits,
        uint256 tokenId
    ) public view returns (string memory) {
        uint8 offset = isFox ? 4 : 0;
        string memory attributes = string(
            abi.encodePacked(
                attributeForTypeAndValue(
                    categoryNames[0],
                    traitData[offset][traits[0]].name
                ),
                ",",
                attributeForTypeAndValue(
                    categoryNames[1],
                    traitData[offset + 1][traits[1]].name
                ),
                ",",
                attributeForTypeAndValue(
                    categoryNames[2],
                    traitData[offset + 2][traits[2]].name
                ),
                ",",
                attributeForTypeAndValue(
                    categoryNames[3],
                    traitData[offset + 3][traits[3]].name
                ),
                ","
            )
        );
        return
            string(
                abi.encodePacked(
                    "[",
                    attributes,
                    '{"trait_type":"Generation","value":',
                    tokenId <= 10000 ? '"Gen 0"' : '"Gen 1"',
                    '},{"trait_type":"Type","value":',
                    isFox ? '"Fox"' : '"Hen"',
                    "}]"
                )
            );
    }

    function tokenMetadata(
        bool isFox,
        uint256 traitId,
        uint256 tokenId
    ) public view returns (string memory) {
        uint8[] memory traits = new uint8[](4);
        uint256 traitIdBackUp = traitId;
        for (uint8 i = 0; i < 4; i++) {
            uint8 exp = 3 - i;
            uint8 tmp = uint8(traitIdBackUp / (16**exp));
            traits[i] = tmp;
            traitIdBackUp -= tmp * 16**exp;
        }

        string memory svg = drawSVG(isFox, traits);

        string memory metadata = string(
            abi.encodePacked(
                '{"name": "',
                isFox ? "Fox #" : "Hen #",
                tokenId.toString(),
                '", "description": "A sunny day in the Summer begins, with the Farmlands and the Forest In its splendor, it seems like a normal day. But the cunning planning of the Foxes has begun, they know that the hens will do everything to protect their precious $EGG but can they keep them all without risk of losing them? A Risk-Reward economic game, where every action matters. No IPFS. No API. All stored and generated 100% on-chain", "image": "data:image/svg+xml;base64,',
                base64(bytes(svg)),
                '", "attributes":',
                compileAttributes(isFox, traits, tokenId),
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

    /** BASE 64 - Written by Brech Devos */

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
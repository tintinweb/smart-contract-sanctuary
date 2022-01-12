// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Renderer is Ownable {
    using Strings for uint256;

    struct Trait { string name; string image;}

    uint8[15] categoryNames = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14];

    mapping(uint8=>mapping(uint8=>Trait)) public traitData;

    constructor() {}

    function uploadTraits(uint8 category, Trait[] calldata traits, uint8 index, uint8 length) external onlyOwner {

        for (uint8 i = index; i <= length; i++) {
            traitData[category][i] = Trait(traits[i].name, traits[i].image);
        }
    }

    function drawTrait(Trait memory trait) internal pure returns (string memory) {
        return
        string(
            abi.encodePacked(
                '<image x="0" y="0" width="72" height="72" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
                trait.image,
                '"/>'
            )
        );
    }

    function drawSVG(bool isDwarf, uint8[15] memory traits) public view returns (string memory) {

        uint8 shift = isDwarf ? 0 : 7;

        string memory svgString;

        if (isDwarf){
            svgString = string(
                abi.encodePacked(
                    drawTrait(traitData[14][traits[14]]),
                    drawTrait(traitData[0 + shift][traits[0 + shift]]),
                    drawTrait(traitData[1 + shift][traits[1 + shift]]),
                    drawTrait(traitData[2 + shift][traits[2 + shift]]),
                    drawTrait(traitData[3 + shift][traits[3 + shift]]),
                    drawTrait(traitData[4 + shift][traits[4 + shift]]),
                    drawTrait(traitData[5 + shift][traits[5 + shift]]),
                    drawTrait(traitData[6 + shift][traits[6 + shift]])
                )
            );
        }
        else{
            svgString = string(
                abi.encodePacked(
                    drawTrait(traitData[14][traits[14]]),
                    drawTrait(traitData[0 + shift][traits[0 + shift]]),
                    drawTrait(traitData[1 + shift][traits[1 + shift]]),
                    drawTrait(traitData[2 + shift][traits[2 + shift]]),
                    drawTrait(traitData[3 + shift][traits[3 + shift]]),
                    drawTrait(traitData[4 + shift][traits[4 + shift]]),
                    drawTrait(traitData[5 + shift][traits[5 + shift]]),
                    drawTrait(traitData[6 + shift][traits[6 + shift]])
                )
            );
        }

        return
        string(
            abi.encodePacked(
                '<svg id="trollgame" width="100%" height="100%" version="1.1" viewBox="0 0 72 72" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                svgString,
                "</svg>"
            )
        );
    }


    function attributeForTypeAndValue(uint8 categoryName, string memory value) internal pure returns (string memory) {

        string[14] memory categoryAliases;

        categoryAliases[0] = 'Skin';
        categoryAliases[1] = 'Back';
        categoryAliases[2] = 'Wear';
        categoryAliases[3] = 'Beard';
        categoryAliases[4] = 'Foot';
        categoryAliases[5] = 'Head';
        categoryAliases[6] = 'Tool';
        categoryAliases[7] = 'Skin';
        categoryAliases[8] = 'Head';
        categoryAliases[9] = 'Accessories';
        categoryAliases[10] = 'Armor';
        categoryAliases[11] = 'Foot';
        categoryAliases[12] = 'Clothing';
        categoryAliases[13] = 'Weapon';

        return
        string(
            abi.encodePacked(
                '{"trait_type":"',
                categoryAliases[categoryName],
                '","value":"',
                value,
                '"}'
            )
        );
    }

    function compileAttributes(bool isDwarf, uint8[15] memory traits) public view returns (string memory) {

        uint8 shift = isDwarf ? 0 : 7;

        string memory attributes;

        if (isDwarf) {
            attributes = string(
                abi.encodePacked(
                    attributeForTypeAndValue(
                        categoryNames[0],
                        traitData[0][traits[0]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        categoryNames[1],
                        traitData[1][traits[1]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        categoryNames[2],
                        traitData[2][traits[2]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        categoryNames[3],
                        traitData[3][traits[3]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        categoryNames[4],
                        traitData[4][traits[4]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        categoryNames[5],
                        traitData[5][traits[5]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        categoryNames[6],
                        traitData[6][traits[6]].name
                    ),
                    ","
                )
            );
        }
        else{
            attributes = string(
                abi.encodePacked(
                    attributeForTypeAndValue(
                        categoryNames[0 + shift],
                        traitData[shift + 0][traits[0 + shift]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        categoryNames[1 + shift],
                        traitData[shift + 1][traits[1 + shift]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        categoryNames[2 + shift],
                        traitData[shift + 2][traits[2 + shift]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        categoryNames[3 + shift],
                        traitData[shift + 3][traits[3 + shift]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        categoryNames[4 + shift],
                        traitData[shift + 4][traits[4 + shift]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        categoryNames[5 + shift],
                        traitData[shift + 5][traits[5 + shift]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        categoryNames[6 + shift],
                        traitData[shift + 6][traits[6 + shift]].name
                    ),
                    ","
                )
            );
        }

        return string(
            abi.encodePacked(
                "[",
                attributes,
                '{"trait_type":"Type","value":',
                isDwarf ? '"Dwarf"' : '"Troll"',
                "}]"
            )
        );
    }

    function tokenMetadata(uint256 tokenId, bool isDwarf, uint8[15] calldata traitarray) public view returns (string memory) {

        string memory svg = drawSVG(isDwarf, traitarray);

        string memory metadata = string(
            abi.encodePacked(
                '{"name": "',
                isDwarf ? "Dwarf #" : "Troll #",
                tokenId.toString(),
                '", "description": "Good day traveler, glad to see you here, welcome to this magical and dangerous world. If you received the invitation, congratulations, you are the chosen hero called into the world of hardworking Dwarfs and Tricky trolls. Only the owner of the invitation will receive early access. No IPFS. No API. All stored and generated 100% on-chain", "image": "data:image/svg+xml;base64,',
                base64(bytes(svg)),
                '", "attributes":',
                compileAttributes(isDwarf, traitarray),
                "}"
            )
        );

        return string(
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
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
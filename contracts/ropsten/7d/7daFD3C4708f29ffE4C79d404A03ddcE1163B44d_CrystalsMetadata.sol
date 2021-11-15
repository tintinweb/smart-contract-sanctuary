// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

interface ICrystalsMetadata {
    function tokenURI(uint256 tokenId, uint256 level, uint256 generation, uint256 seedId) external view returns (string memory);
}

interface ICrystals {
    function getColor(uint256 tokenId) external view returns (string memory);
    function getName(uint256 tokenId) external view returns (string memory);
    function getResonance(uint256 tokenId) external view returns (uint256);
    function getSpin(uint256 tokenId) external view returns (uint256);
    function getSlabs(uint256 tokenId) external view returns (string memory);
    function getLootType(uint256 tokenId) external view returns (string memory);
    function getSurfaceType(uint256 tokenId) external view returns (string memory);

}

contract CrystalsMetadata is Ownable, ICrystalsMetadata {
    string public description;

    address public crystalsAddress;

    constructor() Ownable() {
        description = "Unknown";
    }

    function setCrystalsAddress(address addr) public onlyOwner {
        crystalsAddress = addr;
    }

    function setDescription(string memory desc) public onlyOwner {
        description = desc;
    }

    function tokenURI(uint256 tokenId, uint256 level, uint256 generation, uint256 seedId) override external view returns (string memory) {
        require(level > 0, "INV");
        string memory output;

        string memory styles = string(
            abi.encodePacked(
                "<style>text{fill:",
                ICrystals(crystalsAddress).getColor(tokenId),
                ";font-family:serif;font-size:14px}.slab{transform:rotate(180deg)translate(75px, 79px);",
                "transform-origin:bottom right;font-size:22px;}</style>"
            )
        );

        output = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350">',
                styles,
                '<rect width="100%" height="100%" fill="black" /><text x="10" y="20">',
                ICrystals(crystalsAddress).getName(tokenId),
                (
                    level > 1
                        ? string(
                            abi.encodePacked(
                                " +",
                                toString(level > 0 ? level - 1 : 1)
                            )
                        )
                        : ""
                )
            )
        );

        output = string(
            abi.encodePacked(
                output,
                '</text><text x="10" y="40">',
                "Resonance: ",
                toString(ICrystals(crystalsAddress).getResonance(tokenId)),
                '</text>'
            )
        );
        output = string(
            abi.encodePacked(
                output,
                '<text x="10" y="60">',
                "Spin: ",
                toString(ICrystals(crystalsAddress).getSpin(tokenId)),
                '</text>'
            )
        );
        output = string(
            abi.encodePacked(
                output,
                ICrystals(crystalsAddress).getSlabs(tokenId),
                '</svg>'
        ));

        string memory attributes = string(
            abi.encodePacked(
                '"attributes": [ ',
                '{ "trait_type": "Level", "value": ', toString(level), ' }, ',
                '{ "trait_type": "Resonance", "value": ', toString(ICrystals(crystalsAddress).getResonance(tokenId)), ' }, ',
                '{ "trait_type": "Spin", "value": ', toString(ICrystals(crystalsAddress).getSpin(tokenId)), ' }, '
        ));
        
        attributes = string(
            abi.encodePacked(
                attributes,
                '{ "trait_type": "Loot Type", "value": "', ICrystals(crystalsAddress).getLootType(tokenId), '" }, ',
                '{ "trait_type": "Surface", "value": "', ICrystals(crystalsAddress).getSurfaceType(tokenId), '" }, ',
                '{ "trait_type": "Generation", "value": ', toString(generation) ,' }, ',
                '{ "trait_type": "Color", "value": "', ICrystals(crystalsAddress).getColor(tokenId) ,'" } ]'
            )
        );

        string memory prefix = string(
            abi.encodePacked(
                '{"id": ', toString(tokenId), ', ',
                '"name": "', ICrystals(crystalsAddress).getName(tokenId), '", ',
                '"seedId": ', toString(seedId), ', ',
                '"description": "This crystal vibrates with energy from the Rift!", ',
                '"background_color": "000000"'
        ));

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        prefix, ', ',
                        attributes, ', ',
                        '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'
                    )
                )
            )
        );

        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
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

    function toHexString(uint i) internal pure returns (string memory) {
        // https://stackoverflow.com/a/69302348/424107
        
        if (i == 0) return "0";
        uint j = i;
        uint length;
        while (j != 0) {
            length++;
            j = j >> 4;
        }
        uint mask = 15;
        bytes memory bstr = new bytes(length);
        uint k = length;
        while (i != 0) {
            uint curr = (i & mask);
            bstr[--k] = curr > 9 ?
                bytes1(uint8(55 + curr)) :
                bytes1(uint8(48 + curr)); // 55 = 65 - 10
            i = i >> 4;
        }
        return string(bstr);
    }
}


/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
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
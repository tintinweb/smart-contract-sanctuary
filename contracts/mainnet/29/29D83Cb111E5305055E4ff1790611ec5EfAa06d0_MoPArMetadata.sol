// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Base64.sol";

interface IMoPArMetadata {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IMoPAr {
    function getCollectionId(uint256 tokenId) external view returns (uint256);
    function getName(uint256 tokenId) external view returns (string memory);
    function getDescription(uint256 tokenId) external view returns (string memory);
    function getImage(uint256 tokenId) external view returns (string memory);
    function getAttributes(uint256 tokenId, uint256 index) external view returns (string memory);
    function getCollection(uint256 collectionId) external view returns (bool exists, string memory name, string memory artist, bool paused, uint128 max, uint128 circulating);
}

contract MoPArMetadata is Ownable, IMoPArMetadata {
    IMoPAr private mopar;

    string private _uriPrefix;             // uri prefix
    string[] public metadataKeys;

    constructor(string memory initURIPrefix_, address moparAddress_)
    Ownable() 
    {
        _uriPrefix = initURIPrefix_;
        mopar = IMoPAr(moparAddress_);
        metadataKeys = [
            "Date",
            "Type Of Art",
            "Format",
            "Medium",
            "Colour",
            "Location",
            "Distinguishing Attributes",
            "Dimensions"
        ];
    }

    function tokenURI(uint256 tokenId) override external view returns (string memory) {

        (, string memory collectionName, string memory collectionArtist, , , ) = mopar.getCollection(mopar.getCollectionId(tokenId));
        string memory json;
        json = string(abi.encodePacked(json, '{\n '));
        json = string(abi.encodePacked(json, '"platform": "Museum of Permuted Art",\n '));
        json = string(abi.encodePacked(json, '"name": "' , mopar.getName(tokenId) , '",\n '));
        json = string(abi.encodePacked(json, '"artist": "' , collectionArtist , '",\n '));
        json = string(abi.encodePacked(json, '"collection": "' , collectionName , '",\n '));
        json = string(abi.encodePacked(json, '"description": "' , mopar.getDescription(tokenId) , '",\n '));
        json = string(abi.encodePacked(json, '"image": "' , _uriPrefix, mopar.getImage(tokenId) , '",\n '));
        json = string(abi.encodePacked(json, '"external_url": "https://permuted.xyz",\n '));  //image
        json = string(abi.encodePacked(json, '"attributes": [\n\t'));
        for (uint8 i=0; i<metadataKeys.length; i++) {
            string memory metadataValue = mopar.getAttributes(tokenId,i);
            if (bytes(metadataValue).length > 0) {
                if (i != 0) {
                    json = string(abi.encodePacked(json, ',')); 
                }
                json = string(abi.encodePacked(json, '{"trait_type": "', metadataKeys[i], '", "value": "', metadataValue, '"}\n\t'));
            }
        }
        json = string(abi.encodePacked(json, ']\n}'));
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    function setURIPrefix(string calldata newURIPrefix) external onlyOwner {
        _uriPrefix = newURIPrefix;
    }

    function setMetadataKeys(string[] memory metadataKeys_) external onlyOwner {
        require(metadataKeys_.length <=20, "TOO_MANY_METADATA_KEYS");
        metadataKeys = metadataKeys_;
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

/// SPDX-License-Identifier: MIT
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>

pragma solidity ^0.8.0;

library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

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
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
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
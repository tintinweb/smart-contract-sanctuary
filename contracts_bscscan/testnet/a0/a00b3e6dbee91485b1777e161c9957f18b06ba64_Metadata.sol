/**
 *Submitted for verification at BscScan.com on 2022-01-16
*/

/**
 *Submitted for verification at snowtrace.io on 2022-01-14
*/

// SPDX-License-Identifier: MIT LICENSE

// File: contracts/lib/Base64.sol


pragma solidity ^0.8.0;

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
// File: @openzeppelin/contracts/utils/Strings.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/Metadata.sol



pragma solidity ^0.8.0;




contract Metadata is Ownable {
    using Strings for uint256;

    string uri;
    string[3] types = ['COW', 'ALIEN', 'UFO'];
    string[9] categoryNames = ["Sky", "Ground", "Cow", "Accessory", "Alien", "Equipment", "Ufo", "Pilot", "Glass"];
    uint8[9] categoryCount = [0,0,0,0,0,0,0,0,0];
    mapping(uint8=>mapping(uint8=>string)) public categoryData;

    constructor(string memory _uri) {
        uri = _uri;
    }

    function addTraits(uint8 _category, string[] calldata _names) public onlyOwner {
        categoryCount[_category] = uint8(_names.length);
        for (uint8 i = 0; i < _names.length; i++) {
            categoryData[_category][i] = _names[i];
        }
    }

    function setUri(string memory _uri) public onlyOwner {
        uri = _uri;
    }

    function getImage(uint8 _typeId, uint8[4] memory _dna) public view returns (string memory) {

        return
            string(
                abi.encodePacked(
                    uri,
                    types[_typeId],
                    '-',
                    uint2str(_dna[0]),
                    '-',
                    uint2str(_dna[1]),
                    '-',
                    uint2str(_dna[2]),
                    '-',
                    uint2str(_dna[3]),
                    '.png'
                )
            );
    }

    function compileAttributes(
        uint8[4] memory traits,
        uint8[4] memory dna
    ) public view returns (string memory) {
        return string(
            abi.encodePacked(
                attributeForTypeAndValue(
                    categoryNames[traits[0]],
                    categoryData[traits[0]][dna[0]]
                ),
                ",",
                attributeForTypeAndValue(
                    categoryNames[traits[1]],
                    categoryData[traits[1]][dna[1]]
                ),
                ",",
                attributeForTypeAndValue(
                    categoryNames[traits[2]],
                    categoryData[traits[2]][dna[2]]
                ),
                ",",
                attributeForTypeAndValue(
                    categoryNames[traits[3]],
                    categoryData[traits[3]][dna[3]]
                )
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

    function getMetaImg(uint8 _typeId, uint8[4] calldata _dna) public view returns (string memory) {
        uint8[4] memory traits;
        uint8[4] memory dna;
        if(_typeId == 0){ traits = [0,1,2,3]; }
        if(_typeId == 1){ traits = [0,1,4,5]; }
        if(_typeId == 2){ traits = [0,6,7,8]; }

        dna[0] = _dna[0] % categoryCount[traits[0]];
        dna[1] = _dna[1] % categoryCount[traits[1]];
        dna[2] = _dna[2] % categoryCount[traits[2]];
        dna[3] = _dna[3] % categoryCount[traits[3]];

        return getImage(_typeId, dna);
    }
    
    function getMeta(uint256 _tokenId, uint8 _typeId, uint8[4] calldata _dna) public view returns (string memory) {
        uint8[4] memory traits;
        uint8[4] memory dna;
        if(_typeId == 0){ traits = [0,1,2,3]; }
        if(_typeId == 1){ traits = [0,1,4,5]; }
        if(_typeId == 2){ traits = [0,6,7,8]; }

        dna[0] = _dna[0] % categoryCount[traits[0]];
        dna[1] = _dna[1] % categoryCount[traits[1]];
        dna[2] = _dna[2] % categoryCount[traits[2]];
        dna[3] = _dna[3] % categoryCount[traits[3]];
        
        return string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{',
                                    '"name": "', types[_typeId], ' #', uint2str(_tokenId),'",',
                                    '"description": "Looking for Milk ?!",',
                                    '"attributes": [', compileAttributes(traits, dna), 
                                    '],"image": "', getImage(_typeId, dna),'"',
                                '}'
                            )
                        )
                    )
                )
            );

    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}
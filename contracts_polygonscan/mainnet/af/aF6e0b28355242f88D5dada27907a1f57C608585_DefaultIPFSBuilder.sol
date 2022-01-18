/**
 *Submitted for verification at polygonscan.com on 2022-01-18
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/builder/ipfsBuilder.sol
// SPDX-License-Identifier: MIT AND GPL-3.0-only
pragma solidity >=0.8.0 <0.9.0 >=0.8.7 <0.9.0;

////// lib/openzeppelin-contracts/contracts/utils/Context.sol

/* pragma solidity ^0.8.0; */

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

////// lib/openzeppelin-contracts/contracts/access/Ownable.sol

/* pragma solidity ^0.8.0; */

/* import "../utils/Context.sol"; */

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

////// lib/openzeppelin-contracts/contracts/utils/Strings.sol

/* pragma solidity ^0.8.0; */

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

////// src/builder/base64.sol
/* pragma solidity ^0.8.7; */

library Base64 {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        // solhint-disable-next-line no-inline-assembly
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
            // solhint-disable no-empty-blocks
            for {

            } lt(dataPtr, endPtr) {

            } {
                // solhint-enable no-empty-blocks
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
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

////// src/builder/interface.sol
/* pragma solidity ^0.8.7; */

interface IBuilder {
    function buildMetaData(
        string memory projectName,
        uint128 tokenId,
        uint128 nftType,
        bool streaming,
        uint128 amtPerSec,
        bool active
    ) external view returns (string memory);

    function buildMetaData(
        string memory projectName,
        uint128 tokenId,
        uint128 nftType,
        bool streaming,
        uint128 amtPerSec,
        bool active,
        string memory ipfsHash
    ) external view returns (string memory);
}

////// src/builder/baseBuilder.sol
// solhint-disable quotes
/* pragma solidity ^0.8.7; */

/* import "./base64.sol"; */
/* import "./interface.sol"; */
/* import "openzeppelin-contracts/utils/Strings.sol"; */

abstract contract BaseBuilder is IBuilder {
    function _buildJSON(
        string memory projectName,
        string memory tokenId,
        string memory nftType,
        string memory supportRate,
        bool active,
        bool streaming,
        string memory imageObj
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{ "projectName":"',
                                projectName,
                                '", ',
                                _buildJSONAttributes(
                                    tokenId,
                                    nftType,
                                    supportRate,
                                    active,
                                    streaming
                                ),
                                ', "image": "',
                                imageObj,
                                '" }'
                            )
                        )
                    )
                )
            );
    }

    function _buildJSONAttributes(
        string memory tokenId,
        string memory nftType,
        string memory supportRate,
        bool active,
        bool streaming
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '"attributes": [ { "trait_type": "TokenId", "value": "',
                    tokenId,
                    '"},{ "trait_type": "Type", "value": "',
                    nftType,
                    '"},{ "trait_type": "Active", "value": "',
                    active ? "true" : "false",
                    '"},{ "trait_type": "Streaming Token", "value": "',
                    streaming ? "true" : "false",
                    '"},{ "trait_type": "SupportRate", "value": "',
                    supportRate,
                    ' DAI"}]'
                )
            );
    }

    function _formatSupportRate(uint128 amtPerSec) internal pure returns (string memory) {
        return _toTwoDecimals(amtPerSec * 30 days);
    }

    function _toTwoDecimals(uint256 number) internal pure returns (string memory numberString) {
        // decimal after the first two decimals are rounded up or down
        number += 0.005 * 10**18;
        numberString = Strings.toString(number / 1 ether);
        uint256 twoDecimals = (number % 1 ether) / 10**16;
        if (twoDecimals > 0) {
            numberString = string(
                abi.encodePacked(
                    numberString,
                    ".",
                    twoDecimals < 10 ? "0" : "",
                    Strings.toString(twoDecimals)
                )
            );
        }
        return numberString;
    }
}

////// src/builder/ipfsBuilder.sol
// solhint-disable quotes
/* pragma solidity ^0.8.7; */
/* import "./baseBuilder.sol"; */
/* import {Ownable} from "openzeppelin-contracts/access/Ownable.sol"; */

contract DefaultIPFSBuilder is BaseBuilder {
    address public governance;
    string public defaultIpfsHash;

    // --- Auth Owner---
    mapping(address => bool) public owner;

    function rely(address usr) external onlyOwner {
        owner[usr] = true;
    }

    function deny(address usr) external onlyOwner {
        owner[usr] = false;
    }

    modifier onlyOwner() {
        require(owner[msg.sender] == true, "not-authorized");
        _;
    }

    event NewDefaultIPFS(string ipfsHash);

    constructor(address owner_, string memory defaultIpfsHash_) {
        owner[owner_] = true;
        defaultIpfsHash = defaultIpfsHash_;
        emit NewDefaultIPFS(defaultIpfsHash);
    }

    function changeDefaultIPFS(string calldata newDefaultIpfsHash) public onlyOwner {
        defaultIpfsHash = newDefaultIpfsHash;
        emit NewDefaultIPFS(defaultIpfsHash);
    }

    function buildMetaData(
        string memory projectName,
        uint128 tokenId,
        uint128 nftType,
        bool streaming,
        uint128 amtPerSec,
        bool active
    ) external view override returns (string memory) {
        string memory tokenIdStr = Strings.toString(tokenId);
        string memory nftTypeStr = Strings.toString(nftType);
        string memory supportRate = _formatSupportRate(amtPerSec);
        return
            _buildJSON(
                projectName,
                tokenIdStr,
                nftTypeStr,
                supportRate,
                active,
                streaming,
                defaultIpfsHash
            );
    }

    function buildMetaData(
        string memory projectName,
        uint128 tokenId,
        uint128 nftType,
        bool streaming,
        uint128 amtPerSec,
        bool active,
        string memory ipfsHash
    ) external pure override returns (string memory) {
        string memory supportRate = _formatSupportRate(amtPerSec);
        string memory tokenIdStr = Strings.toString(tokenId);
        string memory nftTypeStr = Strings.toString(nftType);
        return
            _buildJSON(
                projectName,
                tokenIdStr,
                nftTypeStr,
                supportRate,
                active,
                streaming,
                ipfsHash
            );
    }
}
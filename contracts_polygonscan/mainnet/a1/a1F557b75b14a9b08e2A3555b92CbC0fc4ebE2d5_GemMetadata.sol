// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


interface IGemMetadata {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract GemMetadata is Ownable, IGemMetadata {
    IERC721 public gem;

    constructor(address gemContractAddress){
        gem = IERC721(gemContractAddress);
    }

    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        
        string memory gemSVG = drawGem(tokenId);
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Gem #',
                        Strings.toString(tokenId),
                        '", "description": "A non-transferable NFT collection mintable by YC founders.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(gemSVG)),
                        '"}'
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function drawGem(uint256 id) public view returns (string memory) {
        string
            memory svgAccumulator = '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" x="0px" y="0px" preserveAspectRatio="xMinYMin meet" viewBox="0 0 420 420" xml:space="preserve"><style type="text/css"> .st0{fill:#000000;} .st1{fill:#FF4000; font-family: monospace; font-size: 10px;} .st2{fill:#000000; font-family: monospace; font-size: 10px;}</style>';
        svgAccumulator = strConcat(svgAccumulator, '<rect class="st0" width="420" height="420"/>');
        svgAccumulator = strConcat(svgAccumulator, '<g><text x="20" y="23" class="st1">[Verified] YC Founder</text>');
        //TODO: the OG tag should depend on the date the token was minted. Need to add mapping in gem contract that tracks this and either passes to this function or exposes a getter.
        svgAccumulator = strConcat(svgAccumulator, '<g transform="translate(301.5,13.5)"><rect class="st1" width="98" height="13" stroke="#ff4000" fill="#ff4000"/><text x="2" y="9.5" class="st2">/*Orange DAO OG*/</text></g>');
        svgAccumulator = strConcat(svgAccumulator, '</g>');
        svgAccumulator = strConcat(svgAccumulator, '<rect rx="15" class="st0" width="380" height="360" x="20" y="30" stroke="#ff4000" fill="#ff4000" fill-opacity="0.0"/>');
        svgAccumulator = strConcat(svgAccumulator, '<g transform="scale(0.9,0.9) translate(23,35)">');
        svgAccumulator = strConcat(svgAccumulator, '<text x="0" y="0" class="st1">');
        svgAccumulator = strConcat(svgAccumulator, '<tspan x="10" dy="1.2em" textLength="400">................................................................................</tspan>');
        svgAccumulator = strConcat(svgAccumulator, '<tspan x="10" dy="1.2em" textLength="400">...........................)))))))))))))))))....................................</tspan>');
        svgAccumulator = strConcat(svgAccumulator, '<tspan x="10" dy="1.2em" textLength="400">.......................)))))))))))))))))))))))..................................</tspan>');
        svgAccumulator = strConcat(svgAccumulator, '<tspan x="10" dy="1.2em" textLength="400">...................)))))))))))))))))))))))).....................................</tspan>');
        svgAccumulator = strConcat(svgAccumulator, '<tspan x="10" dy="1.2em" textLength="400">...///............))))))))))))))))))))))OOOOOOOOOOOOOOOOO.......................</tspan>');
        svgAccumulator = strConcat(svgAccumulator, '<tspan x="10" dy="1.2em" textLength="400">..////////////..)))))))))))))))))))))OOOOOOOOOOOOOOOOOOOOOOOOO..................</tspan>');
        svgAccumulator = strConcat(svgAccumulator, '<tspan x="10" dy="1.2em" textLength="400">.......//////////)))))))))))))OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO...............</tspan>');
        svgAccumulator = strConcat(svgAccumulator, '<tspan x="10" dy="1.2em" textLength="400">..............////////////OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO............</tspan>');
        svgAccumulator = strConcat(svgAccumulator, '<tspan x="10" dy="1.2em" textLength="400">................OOO///////OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO.........</tspan>');
        svgAccumulator = strConcat(svgAccumulator, '<tspan x="10" dy="1.2em" textLength="400">...............OOOOO////OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO.......</tspan>');
        svgAccumulator = strConcat(svgAccumulator, '<tspan x="10" dy="1.2em" textLength="400">.............OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO......</tspan>');
        svgAccumulator = strConcat(svgAccumulator, '<tspan x="10" dy="1.2em" textLength="400">............OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO....</tspan>');
        svgAccumulator = strConcat(svgAccumulator, '<tspan x="10" dy="1.2em" textLength="400">...........OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO...</tspan>');
        svgAccumulator = strConcat(svgAccumulator, '<tspan x="10" dy="1.2em" textLength="400">..........OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO..</tspan>');
        svgAccumulator = strConcat(svgAccumulator, '<tspan x="10" dy="1.2em" textLength="400">.........OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO..</tspan>');
        svgAccumulator = strConcat(svgAccumulator, '<tspan x="10" dy="1.2em" textLength="400">........OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO.</tspan>');
        svgAccumulator = strConcat(svgAccumulator, '<tspan x="10" dy="1.2em" textLength="400">........OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO.</tspan>');
        svgAccumulator = strConcat(svgAccumulator, '<tspan x="10" dy="1.2em" textLength="400">........OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO.</tspan>');
        svgAccumulator = strConcat(svgAccumulator, '<tspan x="10" dy="1.2em" textLength="400">........OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO.</tspan>');
        svgAccumulator = strConcat(svgAccumulator, '<tspan x="10" dy="1.2em" textLength="400">........OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO.</tspan>');
        svgAccumulator = strConcat(svgAccumulator, '<tspan x="10" dy="1.2em" textLength="400">.........OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO.</tspan>');
        svgAccumulator = strConcat(svgAccumulator, '<tspan x="10" dy="1.2em" textLength="400">.........OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO..</tspan>');
        svgAccumulator = strConcat(svgAccumulator, '<tspan x="10" dy="1.2em" textLength="400">..........OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO...</tspan>');
        svgAccumulator = strConcat(svgAccumulator, '<tspan x="10" dy="1.2em" textLength="400">...........OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO....</tspan>');
        svgAccumulator = strConcat(svgAccumulator, '<tspan x="10" dy="1.2em" textLength="400">............OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO.....</tspan>');
        svgAccumulator = strConcat(svgAccumulator, '<tspan x="10" dy="1.2em" textLength="400">..............OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO......</tspan>');
        svgAccumulator = strConcat(svgAccumulator, '<tspan x="10" dy="1.2em" textLength="400">................OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO........</tspan>');
        svgAccumulator = strConcat(svgAccumulator, '<tspan x="10" dy="1.2em" textLength="400">..................OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO..........</tspan>');
        svgAccumulator = strConcat(svgAccumulator, '<tspan x="10" dy="1.2em" textLength="400">....................OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO.............</tspan>');
        svgAccumulator = strConcat(svgAccumulator, '<tspan x="10" dy="1.2em" textLength="400">........................OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO................</tspan>');
        svgAccumulator = strConcat(svgAccumulator, '<tspan x="10" dy="1.2em" textLength="400">............................OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO....................</tspan>');
        svgAccumulator = strConcat(svgAccumulator, '<tspan x="10" dy="1.2em" textLength="400">..................................OOOOOOOOOOOOOOOOOOO...........................</tspan>');
        svgAccumulator = strConcat(svgAccumulator, '</text></g>');
        svgAccumulator = strConcat(svgAccumulator, '<g><text x="20" y="405" class="st1">');
        svgAccumulator = strConcat(svgAccumulator, addressToString(gem.ownerOf(id)));
        svgAccumulator = strConcat(svgAccumulator, '</text></g>');
        svgAccumulator = strConcat(svgAccumulator, '</svg>');
        return svgAccumulator;
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory result) {
        result = string(abi.encodePacked(bytes(_a), bytes(_b)));
    }

    function addressToString(address addr) internal pure returns (string memory) {
        return Strings.toHexString(uint256(uint160(addr)),20);
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
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

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
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
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
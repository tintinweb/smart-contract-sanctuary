/**
 *Submitted for verification at Etherscan.io on 2021-11-24
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    [email protected]"7HMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMF   .MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM\   -MMMMMMMMMMMMMMMMMMMMF   JMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM#    MMMMMMMMMMMMMMMMMMMMM\   .MMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM]   .MMMMMMMMMMMMMMMMMMMMM`    dMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    dMMMH""7!      ?MMMMM#     -MMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMF    ^              .MMMMM#      MMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM#"`         .....g+, .MMMMMMF      dMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM#"`       ..JMMMMMMMMMMMMMMMMMMM\      ,MMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMH"!          (MMMMMMMMMMMMMMMMD`_TMM!       MMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMB^      ..g#   .MMMMMMMMMMMMMMMM#    UM    ;   JMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMM9'      ..MMMM%   .MMMMMMMMMMMMMMMMF     E   .b   .MMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMM"!      .dMMMMMM#    MMMMMMMMMMMMMMMMM]         .M.   HMMMMMMMMMMMMMMMMMMM    //
//    [email protected]!     ... dMMMMMMM]   .MMMMMMMMMMMMMMMMM:         -M]   -MMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMM#=        .MN.MMMMMMMM    dMMMMMY"HMMMMMMMMM          dM#    MMMMMMMMMMMMMMMMMMM    //
//    [email protected]!    ..M,    WMMMMMMMMF   .MMY"`    dMMMMMMM#   .b     MMM,   dMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMD`    .dMMMMp    TMMMMMMM!   (`              ?MF   .Mc    MMMb   ,MMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMD`    .NMMMMMMMR    ?MMMMMF        ..:           !   (MN.  .MMMN    MMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMF    .dMMMMMMMMMMN.   ,MMMM>     .gMMF   .MMMMh       dMM[  MMMMM|   JMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMM,  .MMMMMMMMMMMMMN,   .MM#        TM]   -MMMMM!      MMMM..MMMMMb   .MMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMN  dMMMMMMMMMMMMMMM,    W%   .,     7    TMM#=      .MMMM..MMMMMM    HMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMM..MMMMMMMMMMMMMMMMMp        MMMa               `   .MMMMMMMMMMMN    -MMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMM`.MMMMMMMMMMMMMMMMMMb      .MMMMNa,     .    .d\   (MMMMMMMMMMMMN    MMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMM  MMMMMMMMMMMMMMMMMMMN.    dMMMMMMMN,  .MMMaJMMh. .MMMMMMMMMMMMMN    dMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN    JMMMMMMMMM- MMMMMMMMMb.MMMMMMMMMMMMMMMb  .MMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN. JMMMMMMMMMM].MMMMMMMMMMMMMMMMMMMMMMMMMMM| MMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM].MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMF MMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM% MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMgMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM: MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMmJMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}


// File @openzeppelin/contracts/utils/[email protected]



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


// File @openzeppelin/contracts/security/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


// File @openzeppelin/contracts/utils/[email protected]



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


// File @openzeppelin/contracts/access/[email protected]



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


// File @openzeppelin/contracts/utils/cryptography/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}


// File @openzeppelin/contracts/utils/introspection/[email protected]



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


// File @openzeppelin/contracts/token/ERC721/[email protected]



pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC721/[email protected]



pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]



pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}


// File @openzeppelin/contracts/token/ERC1155/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}


// File @openzeppelin/contracts/token/ERC1155/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}


// File @openzeppelin/contracts/token/ERC1155/extensions/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}


// File @openzeppelin/contracts/utils/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


// File @openzeppelin/contracts/utils/introspection/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}


// File contracts/ERC1155.sol

/* The MIT License (MIT)
 * 
 * Copyright (c) 2016-2020 zOS Global Limited
 * 
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

/* SUMMARY OF CHANGES
 * Line 36-41  Change imports to use @openzeppelin/contracts imports rather than
 *             relative imports.
 * Line 54     Remove private modifier from `_balances`.
 */


// OpenZeppelin Contracts v4.3.2 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;






/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}


// File contracts/DualERC1155ERC721.sol



pragma solidity ^0.8.8;







/// @notice ERC1155 that supports the ERC721 interface for certain tokens
contract DualERC1155ERC721 is ERC1155 {

    using Address for address;
    using Strings for uint256;

    /// @dev See {IERC721-Transfer}.
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /// @dev See {IERC721-Approval}.
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    struct ERC721Data {
        bool exists;
        address owner;
        address approved;
    }

    // Mapping from account to number of erc721 compatible tokens owned
    mapping(address => uint256) private _erc721Balances;

    // Mapping from token ID to erc721 data
    mapping(uint256 => ERC721Data) private _erc721Data;

    constructor() ERC1155("") {}

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @dev Base URI form {tokenURI}.
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /// @dev See {IERC721Metadata-tokenURI}.
    /// Concatenates the tokenId to the results of {_baseURI}.
    function tokenURI(
        uint256 tokenId
    ) public view virtual returns (string memory) {
        require(
            _erc721Data[tokenId].exists,
            "ERC721Metadata: URI query for nonexistent token"
        );

        return bytes(_baseURI()).length > 0 ?
            string(abi.encodePacked(_baseURI(), tokenId.toString())) : "";
    }

    /// @dev See {IERC721Metadata-name}.
    function name() public view virtual returns (string memory) {
        return "";
    }

    /// @dev See {IERC721Metadata-symbol}.
    function symbol() public view virtual returns (string memory) {
        return "";
    }

    /// @dev Returns a single element as a single element array
    function _asSingleArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    /// @dev See {IERC721-balanceOf}.
    function balanceOf(address owner) public view virtual returns (uint256 balance) {
        return _erc721Balances[owner];
    }

    /// @dev See {IERC721-ownerOf}.
    function ownerOf(
        uint256 tokenId
    ) public view virtual returns (address owner) {
        return _erc721Data[tokenId].exists ?
            _erc721Data[tokenId].owner :
            address(0);
    }

    /// @dev See {IERC721-transferFrom}.
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual {
        require(
            _erc721Data[tokenId].exists && (
                DualERC1155ERC721.ownerOf(tokenId) == msg.sender || 
                _erc721Data[tokenId].approved == msg.sender
            ),
            "ERC721: transfer caller is not owner nor approved"
        );
        _transferERC721(from, to, tokenId);
    }

    /// @dev See {IERC721-approve}.
    function approve(address to, uint256 tokenId) public virtual {
        address owner = DualERC1155ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );
        _approveERC721(to, tokenId);
    }

    /// @dev See {IERC721-getApproved}.
    function getApproved(
        uint256 tokenId
    ) public view virtual returns (address operator) {
        return _erc721Data[tokenId].approved;
    }

    /// @dev See {IERC721-safeTransferFrom}.
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual {
        require(
            _erc721Data[tokenId].exists && (
                DualERC1155ERC721.ownerOf(tokenId) == msg.sender || 
                _erc721Data[tokenId].approved == msg.sender
            ),
            "ERC721: transfer caller is not owner nor approved"
        );
        _transferERC721(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /// @dev See {IERC721-safeTransferFrom}.
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual {
        safeTransferFrom(from, to, tokenId, bytes(""));
    }

    /// @dev Transfer a token as an ERC721
    function _transferERC721(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(
            _msgSender(),
            from,
            to,
            _asSingleArray(tokenId),
            _asSingleArray(1),
            ""
        );

        _approveERC721(address(0), tokenId);
        _balances[tokenId][from] -= 1;
        _balances[tokenId][to] += 1;

        // Emit ERC1155 transfer event rather than ERC721
        emit TransferSingle(_msgSender(), from, to, tokenId, 1);
    }

    /// @dev See {approve}.
    function _approveERC721(address to, uint256 tokenId) internal virtual {
        _erc721Data[tokenId].approved = to;
        emit Approval(DualERC1155ERC721.ownerOf(tokenId), to, tokenId);
    }

    /// @dev Hooks into transfers of ERC721 marked-tokens
    function _beforeTokenTransfer(
        address,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory
    ) internal override {
        for (uint256 i = 0; i < ids.length; i ++) {
            if (_erc721Data[ids[i]].exists) {
                require(
                    DualERC1155ERC721.ownerOf(ids[i]) == from,
                    "ERC721: transfer of token that is not own"
                );
                require(
                    amounts[i] == 1,
                    "ERC721: multi-transfer of token that is not multi-token"
                );
                _erc721Data[ids[i]].owner = to;
                emit Transfer(from, to, ids[i]);
                if (from != address(0)) {
                    _erc721Balances[from] -= 1;
                }
                if (to != address(0)) {
                    _erc721Balances[to] += 1;
                }
            }
        }
    }

    /// @dev Check to see if receiver contract supports IERC721Receiver.
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /// @dev Mark a token id as ERC721. MUST be called before a token is minted.
    /// Only 1 of this token is allowed to exist at any given time. This token
    /// will be visible from the ERC721 interface of this contract.
    function _registerERC721(uint256 tokenId) internal {
        _erc721Data[tokenId].exists = true;
    }
}


// File contracts/IDUtils.sol



pragma solidity ^0.8.8;

/// @notice A helper type to enforce stronger type-checking for token IDs
type ID is uint256;

/// @title IDUtils
/// @notice Provides utility functions for working with the ID type
library IDUtils {

    /// @notice Get the ID after a given ID
    /// @param id The ID
    /// @return The next ID
    function next(ID id) internal pure returns (ID) {
        return ID.wrap(ID.unwrap(id) + 1);
    }

    /// @notice Whether and ID comes after another ID
    /// @param a The first ID
    /// @param b The second ID
    /// @return If the first comes after the second or not
    function gt(ID a, ID b) internal pure returns (bool) {
        return ID.unwrap(a) > ID.unwrap(b);
    }
}


// File contracts/MerkleDropUniqueToken.sol



pragma solidity ^0.8.8;





/// @title Merkle Drop Unique Token
/// @notice Supports two classes of tokens: drop tokens and unique tokens. Drop
/// tokens can be distributed using merkle drops and unique tokens are 1 of 1s
/// that can be purchased if enough drop tokens are held.
contract MerkleDropUniqueToken is DualERC1155ERC721, Ownable, ReentrancyGuard {

    /// @dev Counter used to create new tokens
    ID public nextId = ID.wrap(0);

    constructor() DualERC1155ERC721() {}

    struct DropToken {
        bool exists;
        uint256 supply;
    }

    /// @notice Describes which IDs correspond to drop tokens and their supply
    mapping(ID => DropToken) public dropTokens;

    /// @notice List of drop token IDs
    ID[] public dropTokenList;

    /// @notice Emitted when a new types of drop token are created
    /// @param firstId ID of the first drop token
    /// @param amounts Amounts of the drop tokens
    event DropTokensCreated(ID firstId, uint256[] amounts);

    function _createDropTokens(uint256[] memory _amounts) internal {
        emit DropTokensCreated(nextId, _amounts);
        for (uint i = 0; i < _amounts.length; i ++) {
            dropTokens[nextId] = DropToken(true, _amounts[i]);
            dropTokenList.push(nextId);
            nextId = IDUtils.next(nextId);
        }
    }

    /// @notice Create new types of drop token
    /// @param _amounts Amounts of the drop tokens
    function createDropTokens(uint256[] calldata _amounts) external onlyOwner {
        _createDropTokens(_amounts);
    }

    struct MerkleDrop {
        bool exists;
        bytes32 merkleRoot;
        mapping(ID => uint256) amounts;
        mapping(address => bool) claimed;
    }

    /// @notice The ID of the next merkle drop
    uint256 public nextMerkleDropId = 0;

    /// @notice Describes existing merkle drops
    mapping(uint256 => MerkleDrop) public merkleDrops;

    /// @notice Emitted when a new merkle drop is created
    /// @param merkleDropId The ID of the merkle drop
    /// @param merkleRoot The root of the merkle tree
    /// @param ids The IDs of the drop tokens in this drop
    /// @param amounts The amounts of the drops tokens correspond to `ids`
    event MerkleDropCreated(
        uint256 merkleDropId,
        bytes32 merkleRoot,
        ID[] ids,
        uint256[] amounts
    );

    /// @notice Create a new merkle drop to drop multiple drop tokens at once
    /// @param _merkleRoot The hex root of the merkle tree. The leaves of the
    /// tree must be the address of the recepient as well as the ids and
    /// amounts of each of the drop tokens they will be eligible to claim. They
    /// should be keccak256 abi packed in address, uint256[], uint256[] format.
    /// The merkle tree should be constructed using keccak256 with sorted
    /// pairs.
    /// @param _ids The IDs of the drop tokens in this drop
    /// @param _amounts The amounts of the drops tokens correspond to `ids`
    /// @return The ID of the new merkle drop
    function createMerkleDrop(
        bytes32 _merkleRoot,
        ID[] calldata _ids,
        uint256[] calldata _amounts
    ) external onlyOwner returns (uint256) {
        require(
            _amounts.length == _ids.length,
            "Mismatch between IDs and amounts"
        );
        ID lastId = ID.wrap(0);
        for (uint256 i = 0; i < _ids.length; i ++) {
            require(
                i == 0 || IDUtils.gt(_ids[i], lastId),
                "Non-ascending IDs"
            );
            lastId = _ids[i];
            require(dropTokens[_ids[i]].exists, "Drop token does not exist");
            require(
                _amounts[i] <= dropTokens[_ids[i]].supply,
                "Not enough drop token supply"
            );
        }
        for (uint256 i = 0; i < _ids.length; i ++) {
            dropTokens[_ids[i]].supply -= _amounts[i];
            merkleDrops[nextMerkleDropId].amounts[_ids[i]] = _amounts[i];
        }
        merkleDrops[nextMerkleDropId].merkleRoot = _merkleRoot;
        merkleDrops[nextMerkleDropId].exists = true;

        emit MerkleDropCreated(nextMerkleDropId, _merkleRoot, _ids, _amounts);

        return nextMerkleDropId ++;
    }

    /// @notice Check whether part of a merkle drop is claimed by an account
    /// @param _merkleDropId The ID of the merkle drop
    /// @param _account The account to check
    function isMerkleDropClaimed(
        uint256 _merkleDropId,
        address _account
    ) public view returns (bool) {
        require(merkleDrops[_merkleDropId].exists, "Drop does not exist");
        return merkleDrops[_merkleDropId].claimed[_account];
    }

    /// @notice Emitted when part of a merkle drop is claimed
    /// @param merkleDropId The ID of the merkle drop
    /// @param account The recepient
    /// @param ids The IDs of the drop tokens received
    /// @param amounts The amounts of the drops tokens correspond to `ids`
    event MerkleDropClaimed(
        uint256 merkleDropId,
        address account,
        ID[] ids,
        uint256[] amounts
    );

    /// @notice Claim part of a merkle drop
    /// @param _merkleDropId The ID of the merkle drop
    /// @param _proof The hex proof of the leaf in the tree. The leaves of the
    /// tree must be the address of the recepient as well as the ids and
    /// amounts of each of the drop tokens they will be eligible to claim. They
    /// should be keccak256 abi packed in address, uint256[], uint256[] format.
    /// The merkle tree should be constructed using keccak256 with sorted
    /// pairs.
    /// @param _ids The IDs of the drop tokens to be received
    /// @param _amounts The amounts of the drops tokens correspond to `ids`
    function claimMerkleDrop(
        uint256 _merkleDropId,
        bytes32[] calldata _proof,
        ID[] calldata _ids,
        uint256[] calldata _amounts
    ) external nonReentrant {
        _claimMerkleDrop(_merkleDropId, _proof, _ids, _amounts, msg.sender);
    }

    function _claimMerkleDrop(
        uint256 _merkleDropId,
        bytes32[] calldata _proof,
        ID[] calldata _ids,
        uint256[] calldata _amounts,
        address _account
    ) internal {
        require(merkleDrops[_merkleDropId].exists, "Drop does not exist");
        require(
            _amounts.length == _ids.length,
            "Mismatch between IDs and amounts"
        );
        require(
            !merkleDrops[_merkleDropId].claimed[_account],
            "Drop already claimed"
        );
        ID lastId = ID.wrap(0);
        for (uint256 i = 0; i < _ids.length; i ++) {
            require(
                i == 0 || IDUtils.gt(_ids[i], lastId),
                "Non-ascending IDs"
            );
            lastId = _ids[i];
            require(dropTokens[_ids[i]].exists, "Drop token does not exist");
            require(
                _amounts[i] <= merkleDrops[_merkleDropId].amounts[_ids[i]],
                "Not enough drop tokens in drop"
            );
        }
        bytes32 leaf = keccak256(abi.encodePacked(_account, _ids, _amounts));
        require(
            MerkleProof.verify(_proof, merkleDrops[_merkleDropId].merkleRoot, leaf),
            "Invalid proof"
        );
        for (uint256 i = 0; i < _ids.length; i ++) {
            merkleDrops[_merkleDropId].amounts[_ids[i]] -= _amounts[i];
            _mint(_account, ID.unwrap(_ids[i]), _amounts[i], "");
        }
        merkleDrops[_merkleDropId].claimed[_account] = true;

        emit MerkleDropClaimed(_merkleDropId, _account, _ids, _amounts);
    }

    /// @notice Emitted when a merkle drop is cancelled
    /// @param merkleDropId The ID of the merkle drop
    event MerkleDropCancelled(uint256 merkleDropId);

    /// @notice Cancel an existing merkle drop
    /// @param _merkleDropId The ID of the merkle drop
    function cancelMerkleDrop(uint256 _merkleDropId) external onlyOwner {
        require(merkleDrops[_merkleDropId].exists, "Drop does not exist");
        merkleDrops[_merkleDropId].exists = false;
        emit MerkleDropCancelled(_merkleDropId);
    }

    /// @notice Emitted when drop tokens are manually distributed
    /// @param to The address to which the tokens are minted
    /// @param id The ID of the token being minted
    /// @param amount The amount of the token being minted
    event DropTokensDistributed(address to, ID id, uint256 amount);

    /// @notice Manually distribute drop tokens to an address
    /// @param _to The address to which the tokens are minted
    /// @param _id The ID of the token being minted
    /// @param _amount The amount of the token being minted
    function distributeDropTokens(
        address _to,
        ID _id,
        uint256 _amount
    ) external onlyOwner {
        require(dropTokens[_id].exists, "Drop token does not exist");
        require(dropTokens[_id].supply >= _amount, "Not enough drop tokens remaining");

        dropTokens[_id].supply -= _amount;
        _mint(_to, ID.unwrap(_id), _amount, "");

        emit DropTokensDistributed(_to, _id, _amount);
    }

    function _dropTokenBalanceOf(address _account) internal view returns (uint256) {
        uint256 balance = 0;
        for (uint256 i = 0; i < dropTokenList.length; i ++) {
            balance += balanceOf(_account, ID.unwrap(dropTokenList[i]));
        }
        return balance;
    }

    /// @notice Emitted when drop tokens are burned by a holder
    /// @param account The address of the token holder
    /// @param id The ID of the token being burned
    /// @param amount The amount of the token being burned
    event DropTokensBurned(address account, ID id, uint256 amount);

    /// @notice Emitted when drop tokens are burned by a holder
    /// @param _id The ID of the token to burn
    /// @param _amount The amount of the token to burn
    function burnDropTokens( ID _id, uint256 _amount) external {
        require(dropTokens[_id].exists, "Drop token does not exist");

        _burn(msg.sender, ID.unwrap(_id), _amount);

        emit DropTokensBurned(msg.sender, _id, _amount);
    }

    /// @notice Whether unique tokens are availible to be purchased
    bool public uniquesPurchasable = false;

    struct Unique {
        bool exists;
        bool customPrice;
        bool minted;
        uint256 price;
        bool customDropTokenRequirement;
        uint256 dropTokenRequirement;
    }

    /// @notice Describes which unique tokens are associated with which IDs 
    mapping(ID => Unique) public uniques;

    /// @notice Emitted when unique tokens are created
    /// @param firstId The id of the first new unique token
    /// @param amount The number of new unique tokens created
    event UniquesCreated(ID firstId, uint256 amount);

    function _createUniques(uint256 _amount) internal {
        emit UniquesCreated(nextId, _amount);
        for (uint i = 0; i < _amount; i ++) {
            uniques[nextId].exists = true;
            _registerERC721(ID.unwrap(nextId));
            nextId = IDUtils.next(nextId);
        }
    }

    /// @notice Create a new unique token
    /// @param _amount The number of new unique tokens created
    function createUniques(uint256 _amount) external onlyOwner {
        _createUniques(_amount);
    }

    /// @notice The default price of all unique tokens without a custom setting
    uint256 public defaultPrice = 10**18;

    /// @notice The default drop token requirement of all unique tokens without a
    /// custom setting
    uint256 public defaultDropTokenRequirement = 1;

    /// @notice Emitted when a unique token is purchased
    /// @param account The account who purchased the token
    /// @param id The ID of the token purchased
    /// @param price The price the token sold for
    event UniquePurchased(address account, ID id, uint256 price);

    /// @notice Purchase a unique token
    /// @param _id The ID of the token to be purchased
    function purchaseUnique(ID _id) external payable nonReentrant {
        require(uniquesPurchasable, "Uniques not currently purchasable");
        require(uniques[_id].exists, "Not a valid unique id");
        require(!uniques[_id].minted, "Not enough uniques remaining");
        _purchaseUnique(_id, msg.sender, msg.value);
    }

    function _purchaseUnique(
        ID _id,
        address _account,
        uint256 _value
    ) internal {
        require(
            uniques[_id].customDropTokenRequirement ?
                _dropTokenBalanceOf(_account) >=
                    uniques[_id].dropTokenRequirement :
                _dropTokenBalanceOf(_account) >= defaultDropTokenRequirement,
            "Not enough drop tokens to qualify"
        );
        uint256 price = uniques[_id].customPrice ?
            uniques[_id].price : defaultPrice;

        require(_value == price, "Incorrect payment");

        _mint(_account, ID.unwrap(_id), 1, "");
        uniques[_id].minted = true;

        emit UniquePurchased(_account, _id, price);
    }

    /// @notice Claim part of a merkle drop and purchase a unique token
    /// @param _merkleDropId The ID of the merkle drop
    /// @param _proof The hex proof of the leaf in the tree. The leaves of the
    /// tree must be the address of the recepient as well as the ids and
    /// amounts of each of the drop tokens they will be eligible to claim. They
    /// should be keccak256 abi packed in address, uint256[], uint256[] format.
    /// The merkle tree should be constructed using keccak256 with sorted
    /// pairs.
    /// @param _ids The IDs of the drop tokens to be received
    /// @param _amounts The amounts of the drops tokens correspond to `ids`
    /// @param _uniqueId The ID of the token to be purchased
    function claimMerkleDropAndPurchaseUnique(
        uint256 _merkleDropId,
        bytes32[] calldata _proof,
        ID[] calldata _ids,
        uint256[] calldata _amounts,
        ID _uniqueId
    ) external payable nonReentrant {
        require(uniquesPurchasable, "Uniques not currently purchasable");
        require(uniques[_uniqueId].exists, "Not a valid unique id");
        require(!uniques[_uniqueId].minted, "Not enough uniques remaining");
        _claimMerkleDrop(_merkleDropId, _proof, _ids, _amounts, msg.sender);
        _purchaseUnique(_uniqueId, msg.sender, msg.value);
    }

    /// @notice Emitted when funds are withdrawn from the contract
    /// @param to The address to which the funds were sent
    /// @param amount The amount of funds sent in wei
    event FundsWithdrawn(address to, uint256 amount);

    /// @notice Withdraw funds from the contract
    /// @param _to The address to which the funds were sent
    /// @param _amount The amount of funds sent, in wei
    function withdrawFunds(
        address payable _to,
        uint256 _amount
    ) external onlyOwner nonReentrant {
        require(_amount <= address(this).balance, "Not enough funds");
        _to.transfer(_amount);
        emit FundsWithdrawn(_to, _amount);
    }

    /// @notice Emitted when uniquesPurchasable is updated
    /// @param purchasable Whether unique tokens are now purchasable
    event UniquesPurchasableUpdated(bool purchasable);

    /// @notice Toggle whether unique tokens are purchasable or not
    function toggleUniquesPurchasable() external onlyOwner {
        uniquesPurchasable = !uniquesPurchasable;
        emit UniquesPurchasableUpdated(uniquesPurchasable);
    }

    /// @notice Emitted when the default price of unique tokens is updated
    /// @param price The new price, in wei
    event DefaultPriceUpdated(uint256 price);

    /// @notice Set the default price of unique tokens
    /// @param _price The new price, in wei
    function setDefaultPrice(uint256 _price) external onlyOwner {
        defaultPrice = _price;
        emit DefaultPriceUpdated(_price);
    }

    /// @notice Emitted when the default drop token requirement to purchase
    /// unique tokens is updated
    /// @param requirement The new drop token requirement
    event DefaultDropTokenRequirementUpdated(uint256 requirement);

    /// @notice Set the default drop token requirement to purchase unique tokens
    /// @param _dropTokenRequirement The new drop token requirement
    function setDefaultDropTokenRequirement(
        uint256 _dropTokenRequirement
    ) external onlyOwner {
        defaultDropTokenRequirement = _dropTokenRequirement;
        emit DefaultDropTokenRequirementUpdated(_dropTokenRequirement);
    }

    /// @notice Emitted when the price of a unique token is updated
    /// @param id The id of the unique token
    /// @param price The new price, in wei
    event UniquePriceUpdated(ID id, uint256 price);

    /// @notice Set the price of a specific unique token
    /// @param _id The id of the unique token
    /// @param _price The new price, in wei
    function setUniquePrice(ID _id, uint256 _price) external onlyOwner {
        require(uniques[_id].exists, "Not a valid unique id");
        uniques[_id].customPrice = true;
        uniques[_id].price = _price;
        emit UniquePriceUpdated(_id, _price);
    }

    /// @notice Emitted when the drop token requirement to purchase a unique
    /// token is updated
    /// @param id The id of the unique token
    /// @param requirement The new drop token requirement
    event UniqueDropTokenRequirementUpdated(ID id, uint256 requirement);

    /// @notice Set the minimum drop token requirement to purchase a specific
    /// unique token
    /// @param _id The id of the unique token
    /// @param _dropTokenRequirement The new drop token requirement
    function setUniqueDropTokenRequirement(
        ID _id,
        uint256 _dropTokenRequirement
    ) external onlyOwner {
        require(uniques[_id].exists, "Not a valid unique id");
        uniques[_id].customDropTokenRequirement = true;
        uniques[_id].dropTokenRequirement = _dropTokenRequirement;
        emit UniqueDropTokenRequirementUpdated(_id, _dropTokenRequirement);
    }

    /// @notice Emitted when the price of a unique token is set back to default
    /// @param id The ID of the unique token
    event UniquePriceDefault(ID id);

    /// @notice Set the price of a specific unique token back to default
    /// @param _id The ID of the unique token
    function setUniquePriceDefault(ID _id) external onlyOwner {
        require(uniques[_id].exists, "Not a valid unique id");
        uniques[_id].customPrice = false;
        emit UniquePriceDefault(_id);
    }

    /// @notice Emitted when the drop token requirement of a unique token is set
    /// back to default
    /// @param id The ID of the unique token
    event UniqueDropTokenRequirementDefault(ID id);

    /// @notice Set the drop token requirement of a specific unique token back to
    /// default
    /// @param _id The ID of the unique token
    function setUniqueDropTokenRequirementDefault(ID _id) external onlyOwner {
        require(uniques[_id].exists, "Not a valid unique id");
        uniques[_id].customDropTokenRequirement = false;
        emit UniqueDropTokenRequirementDefault(_id);
    }
}


// File contracts/interfaces/IHydra.sol

pragma solidity ^0.8.9;

/// @notice Interface for KomuroDragons contract Hydra bidding
interface IHydra {
    /// @notice Whether or not an account is eligible to bid on the Hydra
    /// @param _account The address of the account
    /// @return Whether the account is eligible or not
    function canBidOnHydra(address _account) external view returns (bool);
}


// File contracts/KomuroDragons.sol



pragma solidity ^0.8.8;





/// @title Komuro Dragons
contract KomuroDragons is MerkleDropUniqueToken, IHydra {

    using Strings for uint256;

    /// @param _priceFeed Address of a chainlink AggregatorV3 price feed that
    /// controls the Hydra's dynamic URI
    /// @param _positiveHydraUri Hydra URI when price is going up
    /// @param _neutralHydraUri Hydra URI when price is neutral
    /// @param _negativeHydraUri Hydra URI when price is going down
    /// @param _tokenBaseURI The base URI for ERC721 metadata
    /// @param _name The token name for ERC721 metadata
    /// @param _symbol The token symbol for ERC721 metadata
    constructor(
        address _priceFeed,
        string memory _positiveHydraUri,
        string memory _neutralHydraUri,
        string memory _negativeHydraUri,
        string memory _tokenBaseURI,
        string memory _name,
        string memory _symbol
    ) MerkleDropUniqueToken() {
        baseURI = _tokenBaseURI;
        tokenSymbol = _symbol;
        tokenName = _name;
        uint256[] memory dropTokenAmounts = new uint256[](15);
        for (uint i = 0; i < 4; i ++) {
            dropTokenAmounts[i] = 2500;
        }
        for (uint i = 4; i < 15; i ++) {
            dropTokenAmounts[i] = 1;
        }
        _createDropTokens(dropTokenAmounts);
        // Hydra
        _initHydra(
            _priceFeed,
            _positiveHydraUri,
            _neutralHydraUri,
            _negativeHydraUri
        );
    }

    /// @notice Whether or not the hydra has been minted
    bool public isHydraMinted = false;

    /// @notice The token ID of the Hydra token
    ID public hydraId;

    /// @dev The three states the Hydra can exist in - depends on price feed
    enum HydraState {
        Positive,
        Neutral,
        Negative
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return interfaceId == type(IHydra).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @notice Get the metadata URI for a given token
    /// @param _id The id of the token
    /// @return Metadata URI for the token
    /// @dev See {IERC1155MetadataURI-uri}.
    function uri(
        uint256 _id
    ) public view virtual override returns (string memory) {
        return tokenURI(_id);
    }

    /// @notice Get the metadata URI for a given token
    /// @param _id The id of the token
    /// @return Metadata URI for the token
    /// @dev See {IERC721Metadata-tokenURI}.
    function tokenURI (
        uint256 _id
    ) public view virtual override returns (string memory) {
        if (isHydraMinted && _id == ID.unwrap(hydraId)) {
            return _hydraUri();
        } else {
            return bytes(_baseURI()).length > 0 ?
                string(abi.encodePacked(_baseURI(), _id.toString())) : "";
        }
    }

    /// @dev Used as the base of {IERC721Metadata-tokenURI}.
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /// @notice The token name
    /// @dev See {IERC721Metadata-name}.
    function name() public view override returns (string memory) {
        return tokenName;
    }

    /// @notice The token symbol
    /// @dev See {IERC721Metadata-symbol}.
    function symbol() public view override returns (string memory) {
        return tokenSymbol;
    }

    /// @notice The base URI for ERC721 metadata
    string public baseURI;

    /// @notice Emitted when `baseURI` is updated
    /// @param value The new value of `baseURI`
    event BaseURIUpdated(string value);

    /// @notice Update the value of `baseURI`
    /// @param _value The new value of `baseURI`
    function setBaseURI(string calldata _value) external onlyOwner {
        baseURI = _value;
        emit BaseURIUpdated(_value);
    }

    /// @notice The token name for ERC721 metadata
    string public tokenName;

    /// @notice Emitted when `tokenName` is updated
    /// @param value The new value of `tokenName`
    event TokenNameUpdated(string value);

    /// @notice Update the value of `tokenName`
    /// @param _value The new value of `tokenName`
    function setTokenName(string calldata _value) external onlyOwner {
        tokenName = _value;
        emit TokenNameUpdated(_value);
    }

    /// @notice The token symbol for ERC721 metadata
    string public tokenSymbol;

    /// @notice Emitted when `tokenSymbol` is updated
    /// @param value The new value of `tokenSymbol`
    event TokenSymbolUpdated(string value);

    /// @notice Update the value of `tokenSymbol`
    /// @param _value The new value of `tokenSymbol`
    function setTokenSymbol(string calldata _value) external onlyOwner {
        tokenSymbol = _value;
        emit TokenSymbolUpdated(_value);
    }

    /// @notice The Hydra URI when price is going up
    string public hydraUriPositive;

    /// @notice Emitted when `hydraUriPositive` is updated
    /// @param uri The new uri
    event HydraUriPositiveUpdated(string uri);

    /// @notice Set `hydraUriPositive`
    /// @param _uri The new uri
    function setHydraUriPositive(string calldata _uri) external onlyOwner {
        hydraUriPositive = _uri;
        emit HydraUriPositiveUpdated(_uri);
    }

    /// @notice The Hydra URI when price is neutral
    string public hydraUriNeutral;

    /// @notice Emitted when `hydraUriNeutral` is updated
    /// @param uri The new uri
    event HydraUriNeutralUpdated(string uri);

    /// @notice Set `hydraUriNeutral`
    /// @param _uri The new uri
    function setHydraUriNeutral(string calldata _uri) external onlyOwner {
        hydraUriNeutral = _uri;
        emit HydraUriNeutralUpdated(_uri);
    }

    /// @notice The Hydra URI when price is going down
    string public hydraUriNegative;

    /// @notice Emitted when `hydraUriNegative` is updated
    /// @param uri The new uri
    event HydraUriNegativeUpdated(string uri);

    /// @notice Set `hydraUriNegative`
    /// @param _uri The new uri
    function setHydraUriNegative(string calldata _uri) external onlyOwner {
        hydraUriNegative = _uri;
        emit HydraUriNegativeUpdated(_uri);
    }

    /// @notice The number of price feed rounds to go back and get the "before"
    /// time in price difference calculations
    uint80 public pricePeriod = 1;

    /// @notice Emitted when `pricePeriod` is updated
    /// @param value The new value
    event PricePeriodUpdated(uint80 value);

    /// @notice Set `pricePeriod`
    /// @param _value The new value
    function setPricePeriod(uint80 _value) external onlyOwner {
        pricePeriod = _value;
        emit PricePeriodUpdated(_value);
    }

    /// @notice The multiplier used in price difference calculations to increase
    /// resolution
    int256 public priceMultiplier = 10000;

    /// @notice Emitted when `priceMultiplier` is updated
    /// @param value The new value
    event PriceMultiplierUpdated(int256 value);

    /// @notice Set `priceMultiplier`
    /// @param _value The new value
    function setPriceMultiplier(int256 _value) external onlyOwner {
        priceMultiplier = _value;
        emit PriceMultiplierUpdated(_value);
    }

    /// @notice The minimum positive price difference after being multiplied by
    /// the `priceMultiplier` to count as a positive change, the negative of
    /// this for negative change
    int256 public minPriceDifference = 30;

    /// @notice Emitted when `minPriceDifference` is updated
    /// @param value The new value
    event MinPriceDifferenceUpdated(int256 value);

    /// @notice Set `minPriceDifference`
    /// @param _value The new value
    function setMinPriceDifference(int256 _value) external onlyOwner {
        minPriceDifference = _value;
        emit MinPriceDifferenceUpdated(_value);
    }

    /// @notice The chainlink AggregatorV3Interface-compatible contract that
    /// provides price feed information for the Hydra's dynamic URI feature
    AggregatorV3Interface public priceFeed;

    /// @notice Emitted when the price feed is updated
    /// @param priceFeed The address of the price feed contract
    event PriceFeedUpdated(address priceFeed);

    /// @notice Update the price feed
    /// @param _priceFeed The address of the chainlink
    /// AggregatorV3Interface-compatible price feed contract
    function setPriceFeed(address _priceFeed) external onlyOwner {
        priceFeed = AggregatorV3Interface(_priceFeed);
        emit PriceFeedUpdated(_priceFeed);
    }

    /// @notice The number of drop tokens needed to take part in the Hydra
    /// auction
    uint256 public hydraDropTokenRequirement = 1;

    /// @notice Emitted when the number of drop tokens required to bid on the
    /// Hydra is updated
    /// @param requirement The number of drop tokens required
    event HydraDropTokenRequirementUpdated(uint256 requirement);

    /// @notice Set the number of drop tokens required to bid on the Hydra
    /// @param _dropTokenRequirement The number of drop tokens required
    function setHydraDropTokenRequirement(
        uint256 _dropTokenRequirement
    ) external onlyOwner {
        hydraDropTokenRequirement = _dropTokenRequirement;
        emit HydraDropTokenRequirementUpdated(_dropTokenRequirement);
    }

    function _initHydra(
        address _priceFeed,
        string memory _positiveUri,
        string memory _neutralUri,
        string memory _negativeUri
    ) internal {
        priceFeed = AggregatorV3Interface(_priceFeed);
        hydraUriPositive = _positiveUri;
        hydraUriNeutral = _neutralUri;
        hydraUriNegative = _negativeUri;
    }

    function _getHydraState() internal view returns (HydraState) {
        (uint80 roundId, int currentPrice,,,) = priceFeed.latestRoundData();
        (, int previousPrice,,,) = priceFeed.getRoundData(
            roundId - pricePeriod
        );
        int256 priceDifference = previousPrice == int256(0) ? int256(0) :
            ((currentPrice - previousPrice) * priceMultiplier) / previousPrice;
        if (priceDifference >= minPriceDifference) {
            return HydraState.Positive;
        }
        if (priceDifference <= -minPriceDifference) {
            return HydraState.Negative;
        } 
        return HydraState.Neutral;
    }

    function _hydraUri() internal view returns (string memory) {
        HydraState state = _getHydraState();
        if (state == HydraState.Positive) {
            return hydraUriPositive;
        } else if (state == HydraState.Neutral) {
            return hydraUriNeutral;
        } else {
            return hydraUriNegative;
        }
    }

    /// @notice Whether or not an account is eligible to bid on the Hydra
    /// @param _account The address of the account
    /// @return Whether the account is eligible or not
    function canBidOnHydra(
        address _account
    ) external view override returns (bool) {
        return _dropTokenBalanceOf(_account) >= hydraDropTokenRequirement;
    }

    /// @notice Transfer the hydra to another owner
    /// @param _to The address of the new owner
    function transferHydra(address _to) external onlyOwner nonReentrant {
        require(!isHydraMinted, "Not enough hydras remaining");

        hydraId = nextId;
        nextId = IDUtils.next(nextId);
        _registerERC721(ID.unwrap(hydraId));

        _mint(_to, ID.unwrap(hydraId), 1, "");

        isHydraMinted = true;
    }
}
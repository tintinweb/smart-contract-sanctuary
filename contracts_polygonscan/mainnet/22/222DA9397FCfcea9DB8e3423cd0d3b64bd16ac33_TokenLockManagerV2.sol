// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// a token lock manager will handle the locking and unlocking of tokens
// upgrades from V1 to work across multiple nft contracts
contract TokenLockManagerV2 {

  event Lock(
    IERC721 indexed nft,
    uint256 indexed tokenId,
    uint256 unlockAt
  );

  event Unlock(
    IERC721 indexed nft,
    uint256 indexed tokenId,
    uint256 unlockAt
  );

  // timestamp when a token should be considered unlocked
  mapping(IERC721 => mapping (uint256 => uint)) private _tokenUnlockTime;

  // ---
  // Locking functionality
  // ---

  // lock a token for (up to) 30 days
  function lockToken(IERC721 nft, uint256 tokenId) external {
    require(_isApprovedOrOwner(nft, tokenId, msg.sender), "cannot manage token");

    uint unlockAt = block.timestamp + 30 days;
    _tokenUnlockTime[nft][tokenId] = unlockAt;

    emit Lock(nft, tokenId, unlockAt);
  }

  // unlock token (shorten unlock time down to 1 day at most)
  function unlockToken(IERC721 nft, uint256 tokenId) external {
    require(_isApprovedOrOwner(nft, tokenId, msg.sender), "cannot manage token");

    uint max = block.timestamp + 1 days;
    uint current = _tokenUnlockTime[nft][tokenId];
    uint unlockAt = current > max ? max : current;
    _tokenUnlockTime[nft][tokenId] = unlockAt;

    emit Unlock(nft, tokenId, unlockAt);
  }

  // ---
  // views
  // ---

  // the timestamp that a token unlocks at
  function tokenUnlocksAt(IERC721 nft, uint256 tokenId) external view returns (uint) {
    return _tokenUnlockTime[nft][tokenId];
  }

  // true if a token is currently locked
  function isTokenLocked(IERC721 nft, uint256 tokenId) external view returns (bool) {
    return _tokenUnlockTime[nft][tokenId] >= block.timestamp;
  }

  // ---
  // utils
  // ---

  // returns true if operator can manage tokenId
  function _isApprovedOrOwner(IERC721 nft, uint256 tokenId, address operator) internal view returns (bool) {
    address owner = nft.ownerOf(tokenId);
    return owner == operator
      || nft.getApproved(tokenId) == operator
      || nft.isApprovedForAll(owner, operator);
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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
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
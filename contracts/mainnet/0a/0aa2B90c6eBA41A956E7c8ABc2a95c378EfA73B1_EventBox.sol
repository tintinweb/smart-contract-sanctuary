// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EventBox is Ownable {

  struct Event {
    uint deadline;
    bytes32 tokenIdsHash;
  }

  Event[] public events;

  // event id => user address => token ids
  mapping(uint => mapping(address => uint[])) public submissions;

  IERC721 public immutable floyds;

  constructor(IERC721 _floyds) {
    floyds = _floyds;
  }

  /* view functions */

  function getEligibleTokensOfUser(
    uint eventId,
    uint[] calldata tokenIds,
    address user
  ) external view returns (uint[] memory eligibleTokenIds) {

    bytes32 hash = keccak256(abi.encode(tokenIds));
    require(events[eventId].tokenIdsHash == hash, "Event token ids don't match");

    uint[] memory tempTokenIds = new uint[](tokenIds.length);
    uint idx;

    for (uint i = 0; i < tokenIds.length; i++) {
      uint tokenId = tokenIds[i];
      if (floyds.ownerOf(tokenId) == user) {
        tempTokenIds[idx] = tokenId;
        idx++;
      }
    }

    eligibleTokenIds = new uint[](idx);

    if (idx == 0) {
      return eligibleTokenIds;
    }

    for (uint i = 0; i < idx; i++) {
      eligibleTokenIds[i] = tempTokenIds[i];
    }

    return eligibleTokenIds;
  }

  function timeLeft(uint eventId) external view returns (uint secondsLeft) {
    uint deadline = events[eventId].deadline;
    return deadline > block.timestamp ? deadline - block.timestamp : 0;
  }

  function getSubmissionsOfUser(
    uint eventId,
    address user
  ) external view returns (uint[] memory submittedTokenIds) {
    return submissions[eventId][user];
  }

  /* state changing functions */

  function addEvent(
    uint eventId,
    uint deadline,
    uint[] calldata tokenIds
  ) external onlyOwner {

    require(deadline > block.timestamp, "Deadline must be in the future");
    require(tokenIds.length > 0, "Must have at least one token");
    require(eventId == events.length, "Unexpected event id");

    bytes32 hash = keccak256(abi.encode(tokenIds));
    events.push(Event(deadline, hash));
  }

  function updateEventDeadline(uint eventId, uint deadline) external onlyOwner {

    require(deadline > block.timestamp, "Deadline must be in the future");
    require(eventId < events.length, "Unexpected event id");

    events[eventId].deadline = deadline;
  }

  function submit(
    uint eventId,
    uint[] calldata eventTokenIds,
    uint[] calldata tokenIdsToSubmit
  ) external {

    bytes32 hash = keccak256(abi.encode(eventTokenIds));
    require(events[eventId].tokenIdsHash == hash, "Event token ids don't match");
    require(block.timestamp < events[eventId].deadline, "Deadline has passed");
    require(tokenIdsToSubmit.length > 0, "Must submit at least one token");

    for (uint i = 0; i < tokenIdsToSubmit.length; i++) {

      uint tokenId = tokenIdsToSubmit[i];
      bool isEligible = false;

      for (uint j = 0; j < eventTokenIds.length; j++) {
        if (tokenId == eventTokenIds[j]) {
          isEligible = true;
          break;
        }
      }

      require(isEligible, "Token is not eligible");

      floyds.transferFrom(msg.sender, address(this), tokenId);
      submissions[eventId][msg.sender].push(tokenId);
    }
  }

  function _returnTokens(uint eventId, address[] memory users) internal {

    for (uint i = 0; i < users.length; i++) {

      address user = users[i];
      uint tokenCount = submissions[eventId][user].length;

      for (uint j = tokenCount; j > 0; j--) {
        uint tokenId = submissions[eventId][user][j - 1];
        submissions[eventId][user].pop();
        floyds.transferFrom(address(this), user, tokenId);
      }
    }
  }

  function returnTokens(uint eventId, address[] calldata users) external onlyOwner {
    _returnTokens(eventId, users);
  }

  function returnTokensAfterDeadline(uint eventId, address[] calldata users) external {
    uint deadline = events[eventId].deadline;
    require(block.timestamp > deadline, "Deadline has not passed yet");
    _returnTokens(eventId, users);
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
        return msg.data;
    }
}
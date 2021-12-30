// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IKeyContract is IERC721 {
  function getTokenType(uint256 tokenId) external view returns (uint256);
  function mintFor(uint256 tokenType, address receiver) external;
}

contract MetaVaultGame is Ownable, ReentrancyGuard {
  uint256 public constant SECONDS_IN_DAY = 86400;

  uint256 public constant LEVEL_1 = 20;
  uint256 public constant LEVEL_2 = 50;
  uint256 public constant LEVEL_3 = 100;

  uint256 public constant BLOCKS_LIMIT = 256;

  bool private _GameActive;
  address private _lastPlayer;

  mapping (uint256 => uint256) private _lastPlayedId;
  mapping (uint256 => uint256) private doorChosen;
  mapping (uint256 => uint256) private blockHashesToBeUsed;

  IKeyContract public KEY;

  enum Keys {
    Gold,
    Silver,
    White,
    Diamond
  }

  enum Levels {
    First,
    Second,
    Third
  }

  event GameSubmitted (
    address indexed player, 
    uint256 indexed keyId, 
    uint256 indexed doorChosen
  );

  event GameCompleted (
    address indexed player,
    uint256 indexed rightDoor, 
    uint256 indexed doorChosen,
    bool isWon
  );

  event PrizeClaimed (
    address indexed player,
    uint256 indexed prizePot
  );

  modifier authorised {
    require(
      _msgSender() == address(KEY) 
      || _msgSender() == owner(), 
      "Not Authorised"
    );
    _;
  }
  

  constructor(address _keyAddress) {
    KEY = IKeyContract(_keyAddress);
  }

  receive() external payable {}

  function getCurrentLevel(Keys keyType) internal pure returns (uint256) {
    if (keyType == Keys.Gold) { return LEVEL_1; }
    if (keyType == Keys.Silver) { return LEVEL_2; }
    if (keyType == Keys.White) { return LEVEL_3; }
    return 0;
  }

  function playGame(uint256 _keyId, uint256 _doorChosen) public {
    require(_GameActive, "Game not started or paused");
    require(block.timestamp - _lastPlayedId[_keyId] >= SECONDS_IN_DAY, "Key was played less then 24h ago");
    require(KEY.ownerOf(_keyId) == msg.sender, "Not the owner of the key");

    Keys keyType = Keys(KEY.getTokenType(_keyId));

    require(
      keyType == Keys.Gold 
      || keyType == Keys.Silver
      || keyType == Keys.White,
      "Unknown key type"
    );

    uint256 currentLevel = getCurrentLevel(keyType);
    
    require(_doorChosen <= currentLevel && _doorChosen != 0, "Provided invalid door");

    blockHashesToBeUsed[_keyId] = block.number + 3; // using blockhash of 3 blocks in advance
    doorChosen[_keyId] = _doorChosen;
    _lastPlayedId[_keyId] = block.timestamp;
    _lastPlayer = msg.sender;

    emit GameSubmitted(
      msg.sender, 
      _keyId, 
      _doorChosen
    );
  }

  function finaliseGame(uint256 _keyId) public {
    require(
      blockHashesToBeUsed[_keyId] != 0 
      || block.number - blockHashesToBeUsed[_keyId] < BLOCKS_LIMIT, 
      "Another game is active"
    );
    require(
      block.number > blockHashesToBeUsed[_keyId],
      "Too early to finalise game"
    );

    require(KEY.ownerOf(_keyId) == msg.sender, "Not the owner of the key");

    Keys keyType = Keys(KEY.getTokenType(_keyId));

    uint256 currentLevel = getCurrentLevel(keyType);
    uint256 randomNumber = uint256(blockhash(blockHashesToBeUsed[_keyId])) % currentLevel;
    uint256 choosenDoor = doorChosen[_keyId];
    bool won = (randomNumber + 1) == choosenDoor;

    if (won) {
      uint256 nextLevel = uint256(keyType) + 1;
      KEY.mintFor(nextLevel, msg.sender);
    }

    blockHashesToBeUsed[_keyId] == 0;
    doorChosen[_keyId] == 0;

    emit GameCompleted(
      msg.sender,
      (randomNumber + 1),
      choosenDoor,
      won
    );
  }
  
  function claimPrize(uint256 _keyId) public nonReentrant {
    require(KEY.ownerOf(_keyId) == msg.sender, "Not the owner of the key");

    Keys keyType = Keys(KEY.getTokenType(_keyId));
    require(keyType == Keys.Diamond, "Key should be Diamond");

    uint256 prizePot = address(this).balance;

    (bool sent, ) = msg.sender.call{value: prizePot}("");
    require(sent, "Failed to send Ether");

    emit PrizeClaimed(
      msg.sender,
      prizePot
    );
  }

  function startGame() external authorised {
    _GameActive = true;
  }

  function pauseGame() external onlyOwner {
    _GameActive = false;
  }

  function isGameStarted() external view returns (bool) {
    return _GameActive;
  }

  function keyLastPlayed(uint256 keyId) external view returns (uint256) {
    return _lastPlayedId[keyId];
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
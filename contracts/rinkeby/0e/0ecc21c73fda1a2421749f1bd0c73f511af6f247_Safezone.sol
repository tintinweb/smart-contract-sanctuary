/**
 *Submitted for verification at Etherscan.io on 2022-01-08
*/

// File: SWF_GAME/interfaces/IRandomizer.sol

pragma solidity ^0.8.0;

interface IRandomizer {
    function random() external returns (uint256);
}
// File: SWF_GAME/interfaces/ISacrificialAlter.sol



pragma solidity ^0.8.0;

interface ISacrificialAlter {
    function mint(uint256 typeId, uint16 qty, address recipient) external;
    function burn(uint256 typeId, uint16 qty, address burnFrom) external;
    function updateOriginAccess() external;
    function balanceOf(address account, uint256 id) external returns (uint256);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;
}
// File: SWF_GAME/interfaces/ISafezone.sol



pragma solidity ^0.8.0;

interface ISafezone {
  function addManyToSafezoneAndFlight(address account, uint16[] calldata tokenIds) external;
  function randomVariantOwner(uint256 seed) external view returns (address);
}
// File: SWF_GAME/interfaces/ISafe.sol



pragma solidity ^0.8.0;

interface ISafe {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function updateOriginAccess() external;
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: SWF_GAME/interfaces/ISWF.sol



pragma solidity ^0.8.0;


interface ISWF is IERC721Enumerable {

    // game data storage
    struct HumansVariants {
        bool isHuman;
        uint8 body;
        uint8 head;
        uint8 spell;
        uint8 eyes;
        uint8 neck;
        uint8 mouth;
        uint8 wand;
        uint8 tail;
        uint8 rankIndex;
    }

    function minted() external returns (uint16);
    function updateOriginAccess(uint16[] memory tokenIds) external;
    function mint(address recipient, uint256 seed) external;
    function burn(uint256 tokenId) external;
    function getMaxTokens() external view returns (uint256);
    function getPaidTokens() external view returns (uint256);
    function getTokenTraits(uint256 tokenId) external view returns (HumansVariants memory);
    function getTokenWriteBlock(uint256 tokenId) external view returns(uint64);
    function isHuman(uint256 tokenId) external view returns(bool);
  
}
// File: SWF_GAME/interfaces/ISafezoneGame.sol



pragma solidity ^0.8.0;

interface ISafezoneGame {
  
}
// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

// File: SWF_GAME/Safezone.sol



pragma solidity ^0.8.0;











contract Safezone is ISafezone, Ownable, ReentrancyGuard, IERC721Receiver, Pausable {
  
  // maximum rank for a Humans/Variants
  uint8 public constant MAX_RANK = 8;

  // struct to store a stake's token, owner, and earning values
  struct Stake {
    uint16 tokenId;
    uint80 value;
    address owner;
  }

  uint256 private totalRankStaked;
  uint256 private numHumansStaked;

  event TokenStaked(address indexed owner, uint256 indexed tokenId, bool indexed isHuman, uint256 value);
  event HumanClaimed(uint256 indexed tokenId, bool indexed unstaked, uint256 earned);
  event VariantClaimed(uint256 indexed tokenId, bool indexed unstaked, uint256 earned);

  // reference to the SWF NFT contract
  ISWF public swfNFT;
  // reference to the SWF NFT contract
  ISafezoneGame public swfGame;
  // reference to the $SAFE contract for minting $SAFE earnings
  ISafe public safeToken;
  // reference to Randomer 
  IRandomizer public randomizer;

  // maps tokenId to stake
  mapping(uint256 => Stake) private safezone; 
  // maps rank to all Variant staked with that rank
  mapping(uint256 => Stake[]) private flight; 
  // tracks location of each Variant in Flight
  mapping(uint256 => uint256) private flightIndices; 
  // any rewards distributed when no variants are staked
  uint256 private unaccountedRewards = 0; 
  // amount of $SAFE due for each rank point staked
  uint256 private safePerRank = 0; 

  // humans earn 12000 $SAFE per day
  uint256 public constant DAILY_SAFE_RATE = 12000 ether;
  // humans must have 2 days worth of $SAFE to unstake or else they're still guarding the safezone
  uint256 public constant MINIMUM_TO_EXIT = 2 days;
  // variants take a 20% tax on all $SAFE claimed
  uint256 public constant SAFE_CLAIM_TAX_PERCENTAGE = 20;
  // there will only ever be (roughly) 2.4 billion $SAFE earned through staking
  uint256 public constant MAXIMUM_GLOBAL_SAFE = 2880000000 ether;
  uint256 public treasureChestTypeId;

  // amount of $SAFE earned so far
  uint256 public $totalSAFEEarned;
  // the last time $SAFE was claimed
  uint256 private lastClaimTimestamp;

  // emergency rescue to allow unstaking without any checks but without $SAFE
  bool public rescueEnabled = false;

  /**
   */
  constructor() {
    _pause();
  }

  /** CRITICAL TO SETUP */

  modifier requireContractsSet() {
      require(address(swfNFT) != address(0) && address(safeToken) != address(0) 
        && address(swfGame) != address(0) && address(randomizer) != address(0), "Contracts not set");
      _;
  }

  function setContracts(address _swfNFT, address _safe, address _swfGame, address _rand) external onlyOwner {
    swfNFT = ISWF(_swfNFT);
    safeToken = ISafe(_safe);
    swfGame = ISafezoneGame(_swfGame);
    randomizer = IRandomizer(_rand);
  }

  function setTreasureChestId(uint256 typeId) external onlyOwner {
    treasureChestTypeId = typeId;
  }

  /** STAKING */

  /**
   * adds Humans and Variants to the Safezone and Flight
   * @param account the address of the staker
   * @param tokenIds the IDs of the Humans and Variants to stake
   */
  function addManyToSafezoneAndFlight(address account, uint16[] calldata tokenIds) external override nonReentrant {
    require(tx.origin == _msgSender() || _msgSender() == address(swfGame), "Only EOA");
    require(account == tx.origin, "account to sender mismatch");
    for (uint i = 0; i < tokenIds.length; i++) {
      if (_msgSender() != address(swfGame)) { // dont do this step if its a mint + stake
        require(swfNFT.ownerOf(tokenIds[i]) == _msgSender(), "You don't own this token");
        swfNFT.transferFrom(_msgSender(), address(this), tokenIds[i]);
      } else if (tokenIds[i] == 0) {
        continue; // there may be gaps in the array for stolen tokens
      }

      if (swfNFT.isHuman(tokenIds[i])) 
        _addHumanToSafezone(account, tokenIds[i]);
      else 
        _addVariantToFlight(account, tokenIds[i]);
    }
  }

  /**
   * adds a single Human to the Safezone
   * @param account the address of the staker
   * @param tokenId the ID of the Human to add to the Safezone
   */
  function _addHumanToSafezone(address account, uint256 tokenId) internal whenNotPaused _updateEarnings {
    safezone[tokenId] = Stake({
      owner: account,
      tokenId: uint16(tokenId),
      value: uint80(block.timestamp)
    });
    numHumansStaked += 1;
    emit TokenStaked(account, tokenId, true, block.timestamp);
  }

  /**
   * adds a single Variant to the Flight
   * @param account the address of the staker
   * @param tokenId the ID of the Variant to add to the Flight
   */
  function _addVariantToFlight(address account, uint256 tokenId) internal {
    uint8 rank = _rankForVariant(tokenId);
    totalRankStaked += rank; // Portion of earnings ranges from 8 to 5
    flightIndices[tokenId] = flight[rank].length; // Store the location of the variant in the Flight
    flight[rank].push(Stake({
      owner: account,
      tokenId: uint16(tokenId),
      value: uint80(safePerRank)
    })); // Add the variant to the Flight
    emit TokenStaked(account, tokenId, false, safePerRank);
  }

  /** CLAIMING / UNSTAKING */

  /**
   * realize $SAFE earnings and optionally unstake tokens from the Safezone / Flight
   * to unstake a Human it will require it has 2 days worth of $SAFE unclaimed
   * @param tokenIds the IDs of the tokens to claim earnings from
   * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
   */
  function claimManyFromSafezoneAndFlight(uint16[] calldata tokenIds, bool unstake) external whenNotPaused _updateEarnings nonReentrant {
    require(tx.origin == _msgSender() || _msgSender() == address(swfGame), "Only EOA");
    uint256 owed = 0;
    for (uint i = 0; i < tokenIds.length; i++) {
      if (swfNFT.isHuman(tokenIds[i])) {
        owed += _claimHumanFromSafezone(tokenIds[i], unstake);
      }
      else {
        owed += _claimVariantFromFlight(tokenIds[i], unstake);
      }
    }
    safeToken.updateOriginAccess();
    if (owed == 0) {
      return;
    }
    safeToken.mint(_msgSender(), owed);
  }

  function calculateRewards(uint256 tokenId) external view returns (uint256 owed) {
    uint64 lastTokenWrite = swfNFT.getTokenWriteBlock(tokenId);
    // Must check this, as getTokenTraits will be allowed since this contract is an admin
    require(lastTokenWrite < block.number, "hmmmm what doing?");
    Stake memory stake = safezone[tokenId];
    if(swfNFT.isHuman(tokenId)) {
      if ($totalSAFEEarned < MAXIMUM_GLOBAL_SAFE) {
        owed = (block.timestamp - stake.value) * DAILY_SAFE_RATE / 1 days;
      } else if (stake.value > lastClaimTimestamp) {
        owed = 0; // $SAFE production stopped already
      } else {
        owed = (lastClaimTimestamp - stake.value) * DAILY_SAFE_RATE / 1 days; // stop earning additional $SAFE if it's all been earned
      }
    }
    else {
      uint8 rank = _rankForVariant(tokenId);
      owed = (rank) * (safePerRank - stake.value); // Calculate portion of tokens based on Rank
    }
  }

  /**
   * realize $SAFE earnings for a single Human and optionally unstake it
   * if not unstaking, pay a 20% tax to the staked Variants
   * if unstaking, there is a 50% chance all $SAFE is stolen
   * @param tokenId the ID of the Humans to claim earnings from
   * @param unstake whether or not to unstake the Humans
   * @return owed - the amount of $SAFE earned
   */
  function _claimHumanFromSafezone(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
    Stake memory stake = safezone[tokenId];
    require(stake.owner == _msgSender(), "Don't own the given token");
    require(!(unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT), "Still guarding the safezone");
    if ($totalSAFEEarned < MAXIMUM_GLOBAL_SAFE) {
      owed = (block.timestamp - stake.value) * DAILY_SAFE_RATE / 1 days;
    } else if (stake.value > lastClaimTimestamp) {
      owed = 0; // $SAFE production stopped already
    } else {
      owed = (lastClaimTimestamp - stake.value) * DAILY_SAFE_RATE / 1 days; // stop earning additional $SAFE if it's all been earned
    }
    if (unstake) {
      if (randomizer.random() & 1 == 1) { // 50% chance of all $SAFE stolen
        _payVariantTax(owed);
        owed = 0;
      }
      delete safezone[tokenId];
      numHumansStaked -= 1;
      // Always transfer last to guard against reentrance
      swfNFT.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Human
    } else {
      _payVariantTax(owed * SAFE_CLAIM_TAX_PERCENTAGE / 100); // percentage tax to staked variants
      owed = owed * (100 - SAFE_CLAIM_TAX_PERCENTAGE) / 100; // remainder goes to Human owner
      safezone[tokenId] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        value: uint80(block.timestamp)
      }); // reset stake
    }
    emit HumanClaimed(tokenId, unstake, owed);
  }

  /**
   * realize $SAFE earnings for a single Variant and optionally unstake it
   * Variants earn $SAFE proportional to their rank
   * @param tokenId the ID of the Variant to claim earnings from
   * @param unstake whether or not to unstake the Variant
   * @return owed - the amount of $SAFE earned
   */
  function _claimVariantFromFlight(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
    require(swfNFT.ownerOf(tokenId) == address(this), "Doesn't own token");
    uint8 rank = _rankForVariant(tokenId);
    Stake memory stake = flight[rank][flightIndices[tokenId]];
    require(stake.owner == _msgSender(), "Doesn't own token");
    owed = (rank) * (safePerRank - stake.value); // Calculate portion of tokens based on Rank
    if (unstake) {
      totalRankStaked -= rank; // Remove rank from total staked
      Stake memory lastStake = flight[rank][flight[rank].length - 1];
      flight[rank][flightIndices[tokenId]] = lastStake; // Shuffle last Variant to current position
      flightIndices[lastStake.tokenId] = flightIndices[tokenId];
      flight[rank].pop(); // Remove duplicate
      delete flightIndices[tokenId]; // Delete old mapping
      // Always remove last to guard against reentrance
      swfNFT.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Variant
    } else {
      flight[rank][flightIndices[tokenId]] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        value: uint80(safePerRank)
      }); // reset stake
    }
    emit VariantClaimed(tokenId, unstake, owed);
  }
  /**
   * emergency unstake tokens
   * @param tokenIds the IDs of the tokens to claim earnings from
   */
  function rescue(uint256[] calldata tokenIds) external nonReentrant {
    require(rescueEnabled, "RESCUE DISABLED");
    uint256 tokenId;
    Stake memory stake;
    Stake memory lastStake;
    uint8 rank;
    for (uint i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      if (swfNFT.isHuman(tokenId)) {
        stake = safezone[tokenId];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        delete safezone[tokenId];
        numHumansStaked -= 1;
        swfNFT.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Humans
        emit HumanClaimed(tokenId, true, 0);
      } else {
        rank = _rankForVariant(tokenId);
        stake = flight[rank][flightIndices[tokenId]];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        totalRankStaked -= rank; // Remove Rank from total staked
        lastStake = flight[rank][flight[rank].length - 1];
        flight[rank][flightIndices[tokenId]] = lastStake; // Shuffle last Variant to current position
        flightIndices[lastStake.tokenId] = flightIndices[tokenId];
        flight[rank].pop(); // Remove duplicate
        delete flightIndices[tokenId]; // Delete old mapping
        swfNFT.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Variant
        emit VariantClaimed(tokenId, true, 0);
      }
    }
  }

  /** ACCOUNTING */

  /** 
   * add $SAFE to claimable pot for the Flight
   * @param amount $SAFE to add to the pot
   */
  function _payVariantTax(uint256 amount) internal {
    if (totalRankStaked == 0) { // if there's no staked variants
      unaccountedRewards += amount; // keep track of $SAFE due to variants
      return;
    }
    // makes sure to include any unaccounted $SAFE 
    safePerRank += (amount + unaccountedRewards) / totalRankStaked;
    unaccountedRewards = 0;
  }

  /**
   * tracks $SAFE earnings to ensure it stops once 2.4 billion is eclipsed
   */
  modifier _updateEarnings() {
    if ($totalSAFEEarned < MAXIMUM_GLOBAL_SAFE) {
      $totalSAFEEarned += 
        (block.timestamp - lastClaimTimestamp)
        * numHumansStaked
        * DAILY_SAFE_RATE / 1 days; 
      lastClaimTimestamp = block.timestamp;
    }
    _;
  }

  /** ADMIN */

  /**
   * allows owner to enable "rescue mode"
   * simplifies accounting, prioritizes tokens out in emergency
   */
  function setRescueEnabled(bool _enabled) external onlyOwner {
    rescueEnabled = _enabled;
  }

  /**
   * enables owner to pause / unpause contract
   */
  function setPaused(bool _paused) external requireContractsSet onlyOwner {
    if (_paused) _pause();
    else _unpause();
  }

  /** READ ONLY */

  /**
   * gets the rank score for a Variant
   * @param tokenId the ID of the Variant to get the rank score for
   * @return the rank score of the Variant (5-8)
   */
  function _rankForVariant(uint256 tokenId) internal view returns (uint8) {
    ISWF.HumansVariants memory s = swfNFT.getTokenTraits(tokenId);
    return MAX_RANK - s.rankIndex; // rank index is 0-3
  }

  /**
   * chooses a random Variant thief when a newly minted token is stolen
   * @param seed a random value to choose a Variant from
   * @return the owner of the randomly selected Variant thief
   */
  function randomVariantOwner(uint256 seed) external view override returns (address) {
    if (totalRankStaked == 0) {
      return address(0x0);
    }
    uint256 bucket = (seed & 0xFFFFFFFF) % totalRankStaked; // choose a value from 0 to total rank staked
    uint256 cumulative;
    seed >>= 32;
    // loop through each bucket of Variants with the same rank score
    for (uint i = MAX_RANK - 3; i <= MAX_RANK; i++) {
      cumulative += flight[i].length * i;
      // if the value is not inside of that bucket, keep going
      if (bucket >= cumulative) continue;
      // get the address of a random Variant with that rank score
      return flight[i][seed % flight[i].length].owner;
    }
    return address(0x0);
  }

  function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
      require(from == address(0x0), "Cannot send to Safezone directly");
      return IERC721Receiver.onERC721Received.selector;
    }

  
}
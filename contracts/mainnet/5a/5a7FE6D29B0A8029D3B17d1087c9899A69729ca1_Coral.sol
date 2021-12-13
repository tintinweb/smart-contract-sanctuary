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
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/ISharkGame.sol";
import "./interfaces/ISharks.sol";
import "./interfaces/IChum.sol";
import "./interfaces/ICoral.sol";
import "./interfaces/IRandomizer.sol";

contract Coral is ICoral, Ownable, ReentrancyGuard, IERC721Receiver, Pausable {
  // struct to store a stake's token, owner, and earning values
  struct Stake {
    uint16 tokenId;
    uint80 value;
    uint256 timestamp;
    address owner;
  }

  event TokenStaked(address indexed owner, uint256 indexed tokenId, ISharks.SGTokenType indexed tokenType);
  event TokenClaimed(uint256 indexed tokenId, bool indexed unstaked, ISharks.SGTokenType indexed tokenType, uint256 earned);

  // reference to the WnD NFT contract
  ISharks public sharksNft;
  // reference to the WnD NFT contract
  ISharkGame public sharkGame;
  // reference to the $CHUM contract for minting $CHUM earnings
  IChum public chumToken;
  // reference to Randomizer
  IRandomizer public randomizer;

  // count of each type staked
  mapping(ISharks.SGTokenType => uint16) public numStaked;
  // maps tokenId to stake
  mapping(uint16 => Stake) public coral;
  // maps types to all tokens staked of a given type
  mapping(ISharks.SGTokenType => uint16[]) public coralByType;
  // maps tokenId to index in coralByType
  mapping(uint16 => uint256) public  coralByTypeIndex;
  // any rewards distributed when none of a type are staked
  uint256[] public unaccountedRewards = [0, 0, 0];
  // amount of $CHUM stolen through fees by species
  // minnows never get any but are included for consistency
  uint256[] public chumStolen = [0, 0, 0];
  // have orcas been staked yet
  bool public orcasEnabled = false;

  // array indices map to SGTokenType enum entries
  // minnows earn 10000 chum per day
  // sharks earn 0 chum per day but get fees
  // orcas earn 20000 chum per day
  uint256[] public DAILY_CHUM_RATES = [10000 ether, 0, 20000 ether];
  // wizards must have 2 days worth of $CHUM to unstake or else they're still guarding the tower
  uint256 public constant MINIMUM_TO_EXIT = 2 days;
  // sharks have a 5% chance of losing all earnings on being unstaked
  uint256 public constant SHARK_RISK_CHANCE = 5;
  // sharks take a 20% tax on all $CHUM claimed by minnows
  uint256 public constant MINNOW_CLAIM_TAX = 20;
  // orcas take a 10% tax on all $CHUM claimed by sharks
  uint256 public constant SHARK_CLAIM_TAX = 10;
  // there will only ever be (roughly) 5 billion $CHUM earned through staking
  uint256 public constant MAXIMUM_GLOBAL_CHUM = 5000000000 ether;

  // amount of $CHUM earned so far
  uint256 public totalChumEarned;
  // the last time $CHUM was claimed
  uint256 private lastClaimTimestamp;

  // emergency rescue to allow unstaking without any checks but without $CHUM
  bool public rescueEnabled = false;

  /**
   */
  constructor() {
    _pause();
  }

  /** CRITICAL TO SETUP */

  modifier requireContractsSet() {
      require(address(sharksNft) != address(0) && address(chumToken) != address(0)
        && address(sharkGame) != address(0) && address(randomizer) != address(0), "Contracts not set");
      _;
  }

  function setContracts(address _sharksNft, address _chum, address _sharkGame, address _rand) external onlyOwner {
    sharksNft = ISharks(_sharksNft);
    chumToken = IChum(_chum);
    sharkGame = ISharkGame(_sharkGame);
    randomizer = IRandomizer(_rand);
  }

  /** STAKING */

  /**
   * adds Wizards and Dragons to the Tower and Flight
   * @param account the address of the staker
   * @param tokenIds the IDs of the Wizards and Dragons to stake
   */
  function addManyToCoral(address account, uint16[] calldata tokenIds) external override _updateEarnings nonReentrant {
    require(tx.origin == _msgSender() || _msgSender() == address(sharkGame), "Only EOA");
    require(account == tx.origin, "account to sender mismatch");
    for (uint i = 0; i < tokenIds.length; i++) {
      uint16 tokenId = tokenIds[i];
      if (_msgSender() != address(sharkGame)) { // dont do this step if its a mint + stake
        require(sharksNft.ownerOf(tokenIds[i]) == _msgSender(), "You don't own this token");
        sharksNft.transferFrom(_msgSender(), address(this), tokenIds[i]);
      } else if (tokenId == 0) {
        continue; // there may be gaps in the array for stolen tokens
      }

      ISharks.SGTokenType tokenType = sharksNft.getTokenType(tokenId);
      coral[tokenId] = Stake({
        owner: account,
        tokenId: uint16(tokenId),
        value: uint80(chumStolen[uint8(tokenType)]),
        timestamp: block.timestamp
      });
      coralByTypeIndex[tokenId] = coralByType[tokenType].length;
      coralByType[tokenType].push(tokenId);
      numStaked[tokenType] += 1;
      if (tokenType == ISharks.SGTokenType.ORCA) {
        orcasEnabled = true;
      }
      emit TokenStaked(account, tokenId, tokenType);
    }
  }

  /** CLAIMING / UNSTAKING */

  /**
   * realize $CHUM earnings and optionally unstake tokens from the Tower / Flight
   * to unstake a Wizard it will require it has 2 days worth of $CHUM unclaimed
   * @param tokenIds the IDs of the tokens to claim earnings from
   * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
   */
  function claimManyFromCoral(uint16[] calldata tokenIds, bool unstake) external whenNotPaused _updateEarnings nonReentrant {
    require(tx.origin == _msgSender() || _msgSender() == address(sharkGame), "Only EOA");
    uint256 owed = 0;
    for (uint i = 0; i < tokenIds.length; i++) {
      uint16 tokenId = tokenIds[i];
      Stake memory stake = coral[tokenId];
      require(stake.owner != address(0), "Token is not staked");
      uint256 tokenOwed = this.calculateRewards(stake);
      ISharks.SGTokenType tokenType = sharksNft.getTokenType(tokenId);

      if (unstake) {
        // changed to a random orca holder if this token is stolen by an orca
        address recipient = _msgSender();
        if (tokenType == ISharks.SGTokenType.MINNOW) {
          // minnows have a 50% chance of losing all earnings on being unstaked
          if (randomizer.random() & 1 == 1) {
            uint256 orcasSteal = tokenOwed * 3 / 10;
            _payTax(orcasSteal, ISharks.SGTokenType.ORCA);
            _payTax(tokenOwed - orcasSteal, ISharks.SGTokenType.SHARK);
            tokenOwed = 0;
          }
        } else if (tokenType == ISharks.SGTokenType.SHARK) {
          uint256 seed = randomizer.random();
          // 5% chance of orca stealing the shark on unstake
          if (orcasEnabled && (seed & 0xFFFF) % 100 < SHARK_RISK_CHANCE) {
            // change the recipient to a random orca owner
            recipient = this.randomTokenOwner(ISharks.SGTokenType.ORCA, seed);
          }
        }

        delete coral[tokenId];
        if (coralByType[tokenType].length > 1) {
          coralByTypeIndex[coralByType[tokenType][coralByType[tokenType].length - 1]] = coralByTypeIndex[tokenId];
          coralByType[tokenType][coralByTypeIndex[tokenId]] = coralByType[tokenType][coralByType[tokenType].length - 1];
        }
        coralByType[tokenType].pop();
        numStaked[tokenType] -= 1;
        // Always transfer last to guard against reentrancy
        sharksNft.safeTransferFrom(address(this), recipient, tokenId, "");
      } else {
        if (tokenType == ISharks.SGTokenType.MINNOW) {
          uint256 sharksSteal = tokenOwed * MINNOW_CLAIM_TAX / 100;
          _payTax(sharksSteal, ISharks.SGTokenType.SHARK);
          tokenOwed -= sharksSteal;
        } else if (tokenType == ISharks.SGTokenType.SHARK && orcasEnabled) {
          uint256 orcasSteal = tokenOwed * SHARK_CLAIM_TAX / 100;
          _payTax(orcasSteal, ISharks.SGTokenType.ORCA);
          tokenOwed -= orcasSteal;
        }
        coral[tokenId] = Stake({
          owner: _msgSender(),
          tokenId: uint16(tokenId),
          value: uint80(chumStolen[uint8(tokenType)]),
          timestamp: block.timestamp
        }); // reset stake
      }
      owed += tokenOwed;
      emit TokenClaimed(tokenId, unstake, tokenType, owed);
    }
    chumToken.updateOriginAccess();
    if (owed == 0) {
      return;
    }
    chumToken.mint(_msgSender(), owed);
  }

  function calculateRewards(Stake calldata stake) external view returns (uint256 owed) {
    uint64 lastTokenWrite = sharksNft.getTokenWriteBlock(stake.tokenId);
    // Must check this, as getTokenTraits will be allowed since this contract is an admin
    require(lastTokenWrite < block.number, "hmmmm what doing?");
    uint8 tokenType = uint8(sharksNft.getTokenType(stake.tokenId));
    uint256 dailyRate = DAILY_CHUM_RATES[tokenType];
    if (dailyRate > 0) {
      if (totalChumEarned < MAXIMUM_GLOBAL_CHUM) {
        owed = (block.timestamp - stake.timestamp) * DAILY_CHUM_RATES[tokenType] / 1 days;
      } else if (stake.timestamp > lastClaimTimestamp) {
        owed = 0; // $CHUM production stopped already
      } else {
        owed = (lastClaimTimestamp - stake.timestamp) * DAILY_CHUM_RATES[tokenType] / 1 days; // stop earning additional $CHUM if it's all been earned
      }
    }
    owed += chumStolen[tokenType] - stake.value;
  }

  /**
   * emergency unstake tokens
   * @param tokenIds the IDs of the tokens to claim earnings from
   */
  function rescue(uint16[] calldata tokenIds) external nonReentrant {
    require(rescueEnabled, "RESCUE DISABLED");
    uint16 tokenId;
    ISharks.SGTokenType tokenType;
    Stake memory stake;
    for (uint i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      tokenType = sharksNft.getTokenType(tokenId);
      stake = coral[tokenId];
      require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
      delete coral[tokenId];
      if (coralByType[tokenType].length > 1) {
        coralByTypeIndex[coralByType[tokenType][coralByType[tokenType].length - 1]] = coralByTypeIndex[tokenId];
        coralByType[tokenType][coralByTypeIndex[tokenId]] = coralByType[tokenType][coralByType[tokenType].length - 1];
      }
      coralByType[tokenType].pop();
      numStaked[tokenType] -= 1;
      // Always transfer last to guard against reentrancy
      sharksNft.safeTransferFrom(address(this), _msgSender(), tokenId, "");
      emit TokenClaimed(tokenId, true, tokenType, 0);
    }
  }

  /** ACCOUNTING */

  /**
   * add $CHUM to claimable pot for the Flight
   * @param amount $CHUM to add to the pot
   */
  function _payTax(uint256 amount, ISharks.SGTokenType tokenType) internal {
    if (numStaked[tokenType] == 0) { // if there's no staked sharks/orcas
      unaccountedRewards[uint8(tokenType)] += amount; // keep track of $CHUM due to sharks/orcas
      return;
    }
    // makes sure to include any unaccounted $CHUM
    chumStolen[uint8(tokenType)] += (amount + unaccountedRewards[uint8(tokenType)]) / numStaked[tokenType];
    unaccountedRewards[uint8(tokenType)] = 0;
  }

  /**
   * tracks $CHUM earnings to ensure it stops once 2.5 billion is eclipsed
   */
  modifier _updateEarnings() {
    if (totalChumEarned < MAXIMUM_GLOBAL_CHUM) {
      totalChumEarned +=
        (block.timestamp - lastClaimTimestamp)
        * numStaked[ISharks.SGTokenType.MINNOW]
        * DAILY_CHUM_RATES[uint8(ISharks.SGTokenType.MINNOW)] / 1 days
      + (block.timestamp - lastClaimTimestamp)
        * numStaked[ISharks.SGTokenType.ORCA]
        * DAILY_CHUM_RATES[uint8(ISharks.SGTokenType.ORCA)] / 1 days;
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
   * chooses a random Dragon thief when a newly minted token is stolen
   * @param seed a random value to choose a Dragon from
   * @return the owner of the randomly selected Dragon thief
   */
  function randomTokenOwner(ISharks.SGTokenType tokenType, uint256 seed) external view override returns (address) {
    uint256 numStakedOfType = numStaked[tokenType];
    if (numStakedOfType == 0) {
      return address(0x0);
    }
    uint256 i = (seed & 0xFFFFFFFF) % numStakedOfType; // choose a value from 0 to total rank staked
    return coral[coralByType[tokenType][i]].owner;
  }

  function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
      require(from == address(0x0), "Cannot send to Coral directly");
      return IERC721Receiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IChum {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function updateOriginAccess() external;
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./ISharks.sol";

interface ICoral {
  function addManyToCoral(address account, uint16[] calldata tokenIds) external;
  function randomTokenOwner(ISharks.SGTokenType tokenType, uint256 seed) external view returns (address);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IRandomizer {
    function random() external returns (uint256);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface ISharkGame {

}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface ISharks is IERC721Enumerable {
    // game data storage
    enum SGTokenType {
        MINNOW,
        SHARK,
        ORCA
    }

    struct SGToken {
        SGTokenType tokenType;
        uint8 base;
        uint8 accessory;
    }

    function minted() external returns (uint16);
    function updateOriginAccess(uint16[] memory tokenIds) external;
    function mint(address recipient, uint256 seed) external;
    function burn(uint256 tokenId) external;
    function getMaxTokens() external view returns (uint16);
    function getPaidTokens() external view returns (uint16);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function getTokenTraits(uint256 tokenId) external view returns (SGToken memory);
    function getTokenWriteBlock(uint256 tokenId) external view returns(uint64);
    function getTokenType(uint256 tokenId) external view returns(SGTokenType);
}
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IERC20Mintable.sol";

/**
 * @dev TMAPStacking is a contract that gives rewards in terms of TMAP for NFT holders
 *
 */
contract TMAPStacking is ReentrancyGuard, Ownable {
  /**
   * @dev can pause rewards
   */
  bool public rewardPaused = false;

  /**
   * @dev mapping that stores last time a holder claimed the rewards per nft as a collector
   * can have more than 1 nft
   */
  mapping(uint256 => uint256) lastRewarded;

  /**
   * @dev how many governance tokens (TMAP) can be rewarded per round
   */
  uint256 public tmapPerRound = 1;

  /**
   * @dev nft contract that the collector needs to hold to be able to collect rewards
   */
  DSPI public dsp;

  /**
   * @dev used to set the cool off for the rewards, someone can not collect if lastRewarded + rewardsCoolOff > block.timestamp
   */
  uint256 public rewardsCoolOff = 86400; //one day in seconds

  /**
   * @dev TMAP address, the governance token than is given as rewards
   */
  IERC20Mintable public TMAP;

  /**
   * @dev used to set the starting point of rewards generation of TMAP
   */
  uint256 public STARTING_POINT;

  /**
   * @dev used for batch distribution triggered by owner
   */
  mapping(address => uint256) private batchDistribution;
  address[] private currentHoldersForBatching;

  event RewardsPerDay(uint256 rewards);
  event Collected(address indexed collector, uint256 amount);
  event Entered(address indexed collector, uint256 tokenId);
  event ChangedRewardsCoolOff(uint256 rewards);
  event ChangedStartingPoint(uint256 rewards);
  event ClaimingReset(uint256 rewards);
  event TriggeredClaiming(address owner, uint256 rewards);

  constructor() {
    STARTING_POINT = block.timestamp;
  }

  /**
   * @dev used to for the UI to retrieve pending rewards for a certain collector (DSP holder)
   */
  function pending(address _collector) external view returns (uint256) {
    uint256 roundsToReward = 0;
    uint256[] memory tokensOwned = dsp.tokensOfOwner(_collector);
    for (uint256 i; i < tokensOwned.length; i++) {
      uint256 tokenId = tokensOwned[i];
      uint256 lastTimeRewarded = lastRewarded[tokenId];

      // means this tokenId it never collected
      if (lastTimeRewarded == 0) lastTimeRewarded = STARTING_POINT;

      roundsToReward += (block.timestamp - lastTimeRewarded) / rewardsCoolOff;
    }
    return tmapPerRound * roundsToReward * 1e18;
  }

  /**
   * @dev used to for the UI to retrieve pending rewards for all collectors (DSP Holders)
   */
  function allPending() external view returns (uint256) {
    uint256 roundsToReward = 0;
    uint256[] memory mintedTokens = dsp.getMintedTokens();
    for (uint256 i; i < mintedTokens.length; i++) {
      uint256 tokenId = mintedTokens[i];
      uint256 lastTimeRewarded = lastRewarded[tokenId];

      // means this tokenId it never collected
      if (lastTimeRewarded == 0) lastTimeRewarded = STARTING_POINT;

      roundsToReward += (block.timestamp - lastTimeRewarded) / rewardsCoolOff;
    }
    return tmapPerRound * roundsToReward * 1e18;
  }

  /**
   * @dev collect function used to collect rewards by an nft holder.
   * the rewards are kept by sender and by token id to assure a reward based on time of ownership.
   */
  function collect() external nonReentrant {
    require(!rewardPaused, "Rewards are paused");

    uint256 amount = 0;

    uint256[] memory tokensOwned = dsp.tokensOfOwner(msg.sender);
    for (uint256 i; i < tokensOwned.length; i++) {
      uint256 tokenId = tokensOwned[i];

      if (tokenId == 0) continue;

      uint256 lastTimeRewarded = lastRewarded[tokenId];

      // means this tokenId it never collected
      if (lastTimeRewarded == 0) lastTimeRewarded = STARTING_POINT;

      uint256 roundsToReward = 0;

      //rewarded for this token did not pass the rewards cool off
      if (block.timestamp - lastTimeRewarded < rewardsCoolOff) continue;

      roundsToReward = (block.timestamp - lastTimeRewarded) / rewardsCoolOff;

      //last rewards per collector per token is set as lastTimeRewarded + roundsToReward * rewardsCoolOff in case someone
      // collects between 2 rounds, this means no one can lose rewards.
      lastRewarded[tokenId] = lastTimeRewarded + roundsToReward * rewardsCoolOff;

      amount += tmapPerRound * roundsToReward * 1e18;
    }

    require(amount > 0, "Nothing to collect");
    TMAP.mint(msg.sender, amount);

    emit Collected(msg.sender, amount);
  }

  /**
   * @dev governance functions
   */
  function setRewardsPerRound(uint256 _rewards) external onlyOwner {
    require(_rewards > 0, "Rewards can not be 0");
    tmapPerRound = _rewards;
    emit RewardsPerDay(_rewards);
  }

  function setTMAP(address _tmap) external onlyOwner {
    require(_tmap != address(0), "TMAP can not be address(0)");
    TMAP = IERC20Mintable(_tmap);
  }

  /**
   * @dev cooloff period in seconds
   */
  function setCoolOff(uint256 _coolOff) external onlyOwner {
    require(_coolOff > 0, "Cool off can not be 0");
    rewardsCoolOff = _coolOff;
    emit ChangedRewardsCoolOff(_coolOff);
  }

  function setDsp(address _dsp) external onlyOwner {
    require(_dsp != address(0), "NFT can not be address(0)");
    dsp = DSPI(_dsp);
  }

  function setRewardPause(bool _paused) external onlyOwner {
    rewardPaused = _paused;
  }

  function getLastRewarded(uint256 _tokenId) external view returns (uint256) {
    return lastRewarded[_tokenId];
  }

  function setRewardStartingPoint(uint256 _startingPoint) external onlyOwner {
    STARTING_POINT = _startingPoint;
    emit ChangedStartingPoint(_startingPoint);
  }

  function resetClaiming(uint256 _tokenId) external onlyOwner {
    lastRewarded[_tokenId] = block.timestamp;
    emit ClaimingReset(_tokenId);
  }

  // @dev start is the start token id, stop is the stop token id
  function triggerClaiming(uint256 startId, uint256 stopId) external onlyOwner {
    uint256 amount = 0;
    //cleaning previous batch processed
    for (uint256 i = 0; i < currentHoldersForBatching.length; i++) {
      delete batchDistribution[currentHoldersForBatching[i]];
    }
    delete currentHoldersForBatching;

    //iterate through the batch
    for (uint256 i = startId; i <= stopId; i++) {
      uint256 lastTimeRewarded = lastRewarded[i];

      // means this tokenId it never collected
      if (lastTimeRewarded == 0) lastTimeRewarded = STARTING_POINT;

      uint256 roundsToReward = 0;

      //rewarded for this token did not pass the rewards cool off
      if (block.timestamp - lastTimeRewarded < rewardsCoolOff) continue;

      roundsToReward = (block.timestamp - lastTimeRewarded) / rewardsCoolOff;

      //last rewards per collector per token is set as lastTimeRewarded + roundsToReward * rewardsCoolOff in case someone
      // collects between 2 rounds, this means no one can lose rewards.
      lastRewarded[i] = lastTimeRewarded + roundsToReward * rewardsCoolOff;

      //we collect for each owner the no of TMAP that needs to be distributed
      //if it is already in the batchDistributor then add to current amount
      address owner = dsp.ownerOf(i);
      if (batchDistribution[owner] > 0) {
        batchDistribution[owner] += tmapPerRound * roundsToReward * 1e18;
      } else {
        batchDistribution[owner] = tmapPerRound * roundsToReward * 1e18;
        currentHoldersForBatching.push(owner);
      }
      lastRewarded[i] = block.timestamp;
    }

    for (uint256 i = 0; i < currentHoldersForBatching.length; i++) {
      address owner = currentHoldersForBatching[i];
      amount = batchDistribution[owner];

      //if amount == 0 continue, nothing to mint
      if (amount == 0) continue;

      TMAP.mint(owner, amount);
      emit TriggeredClaiming(owner, batchDistribution[owner]);
    }
  }
}

interface DSPI {
  function tokensOfOwner(address _owner) external view returns (uint256[] memory);

  function getMintedTokens() external view returns (uint256[] memory);

  function totalSupply() external view returns (uint256);

  function ownerOf(uint256 tokenId) external view returns (address);
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
 * @dev Interface of the ERC20 expanded to include mint functionality
 * @dev
 */
interface IERC20Mintable {
  /**
   * @dev mints `amount` to `receiver`
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits an {Minted} event.
   */
  function mint(address receiver, uint256 amount) external;
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
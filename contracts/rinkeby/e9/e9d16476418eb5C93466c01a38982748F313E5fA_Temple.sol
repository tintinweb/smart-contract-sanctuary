// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import './interfaces/ITnDGame.sol';
import './interfaces/IGameNft.sol';
import './interfaces/IGameToken.sol';
import './interfaces/ITemple.sol';
import './interfaces/IAltar.sol';
import './interfaces/IRandom.sol';

contract Temple is ITemple, Ownable, ReentrancyGuard, IERC721Receiver, Pausable {
  using EnumerableSet for EnumerableSet.UintSet;

  struct Deposits {
    EnumerableSet.UintSet templars;
    EnumerableSet.UintSet demons;
  }
  // maximum rank for a Templar/Demon
  uint8 public constant MAX_RANK = 8;

  // struct to store a stake's token, owner, and earning values
  struct Stake {
    uint16 tokenId;
    uint80 value;
    address owner;
  }

  uint256 private totalRankStaked;
  uint256 private numTemplarsStaked;

  event TokenStaked(
    address indexed owner,
    uint256 indexed tokenId,
    bool indexed isTemplar,
    uint256 value
  );
  event TemplarClaimed(uint256 indexed tokenId, bool indexed unstaked, uint256 earned);
  event DemonClaimed(uint256 indexed tokenId, bool indexed unstaked, uint256 earned);

  // reference to the WnD NFT contract
  IGameNft public tndNFT;
  // reference to the WnD NFT contract
  ITnDGame public tndGame;
  // reference to the $GT contract for minting $GT earnings
  IGameToken public gtToken;
  // reference to Randomer
  IRandom public randomizer;

  // maps tokenId to stake
  mapping(uint256 => Stake) private temple;
  // maps tokenIds deposited by each player
  mapping(address => Deposits) private deposits;
  // maps rank to all Demon staked with that rank
  mapping(uint256 => Stake[]) private flight;
  // tracks location of each Demon in Flight
  mapping(uint256 => uint256) private flightIndices;
  // any rewards distributed when no demons are staked
  uint256 private unaccountedRewards = 0;
  // amount of $GT due for each rank point staked
  uint256 private gtPerRank = 0;

  // templars earn 12000 $GT per day
  uint256 public constant DAILY_GT_RATE = 12000 ether;
  // templars must have 2 minutes worth of $GT to unstake or else they're still guarding the temple
  uint256 public constant MINIMUM_TO_EXIT = 2 minutes;
  // demons take a 20% tax on all $GT claimed
  uint256 public constant GT_CLAIM_TAX_PERCENTAGE = 20;
  // there will only ever be (roughly) 2.4 billion $GT earned through staking
  uint256 public constant MAXIMUM_GLOBAL_GT = 2880000000 ether;
  uint256 public treasureChestTypeId;

  // amount of $GT earned so far
  uint256 public totalGTEarned;
  // the last time $GT was claimed
  uint256 private lastClaimTimestamp;

  // emergency rescue to allow unstaking without any checks but without $GT
  bool public rescueEnabled = false;

  /**
   */
  constructor() {
    _pause();
  }

  /** CRITICAL TO SETUP */

  modifier requireContractsSet() {
    require(
      address(tndNFT) != address(0) &&
        address(gtToken) != address(0) &&
        address(tndGame) != address(0) &&
        address(randomizer) != address(0),
      'Contracts not set'
    );
    _;
  }

  function setContracts(
    address _tndNFT,
    address _gt,
    address _tndGame,
    address _rand
  ) external onlyOwner {
    tndNFT = IGameNft(_tndNFT);
    gtToken = IGameToken(_gt);
    tndGame = ITnDGame(_tndGame);
    randomizer = IRandom(_rand);
  }

  function setTreasureChestId(uint256 typeId) external onlyOwner {
    treasureChestTypeId = typeId;
  }

  function depositsOf(address account) external view override returns (uint256[] memory) {
    Deposits storage depositSet = deposits[account];
    uint256[] memory tokenIds = new uint256[](
      depositSet.templars.length() + depositSet.demons.length()
    );

    for (uint256 i; i < depositSet.templars.length(); i++) {
      tokenIds[i] = depositSet.templars.at(i);
    }
    for (uint256 i; i < depositSet.demons.length(); i++) {
      tokenIds[i + depositSet.templars.length()] = depositSet.demons.at(i);
    }

    return tokenIds;
  }

  function isTokenStaked(uint256 tokenId) external view override returns (bool) {
    uint64 lastTokenWrite = tndNFT.getTokenWriteBlock(tokenId);
    // Must check this, as getTokenTraits will be allowed since this contract is an admin
    require(lastTokenWrite < block.number, "hmmmm what doing?");
    IGameNft.TemplarDemon memory s = tndNFT.getTokenTraits(tokenId);
    if(s.isTemplar) {
        return temple[tokenId].owner != address(0);
    }
    // dragons are staked in both pool, so you can ignore the isTraining bool
    uint8 rank = _rankForDemon(tokenId);
    return flight[rank][flightIndices[tokenId]].owner != address(0);
  }

  /** STAKING */

  /**
   * adds Templars and Demons to the Temple and Flight
   * @param account the address of the staker
   * @param tokenIds the IDs of the Templars and Demons to stake
   */
  function addManyToTempleAndFlight(address account, uint16[] calldata tokenIds)
    external
    override
    nonReentrant
  {
    require(tx.origin == _msgSender() || _msgSender() == address(tndGame), 'Only EOA');
    require(account == tx.origin, 'account to sender mismatch');
    for (uint256 i = 0; i < tokenIds.length; i++) {
      if (_msgSender() != address(tndGame)) {
        // dont do this step if its a mint + stake
        require(tndNFT.ownerOf(tokenIds[i]) == _msgSender(), "You don't own this token");
        tndNFT.transferFrom(_msgSender(), address(this), tokenIds[i]);
      } else if (tokenIds[i] == 0) {
        continue; // there may be gaps in the array for stolen tokens
      }

      if (tndNFT.isTemplar(tokenIds[i])) _addTemplarToTemple(account, tokenIds[i]);
      else _addDemonToFlight(account, tokenIds[i]);
    }
  }

  /**
   * adds a single Templar to the Temple
   * @param account the address of the staker
   * @param tokenId the ID of the Templar to add to the Temple
   */
  function _addTemplarToTemple(address account, uint256 tokenId)
    internal
    whenNotPaused
    _updateEarnings
  {
    temple[tokenId] = Stake({
      owner: account,
      tokenId: uint16(tokenId),
      value: uint80(block.timestamp)
    });
    numTemplarsStaked += 1;
    deposits[account].templars.add(tokenId);
    emit TokenStaked(account, tokenId, true, block.timestamp);
  }

  /**
   * adds a single Demon to the Flight
   * @param account the address of the staker
   * @param tokenId the ID of the Demon to add to the Flight
   */
  function _addDemonToFlight(address account, uint256 tokenId) internal {
    uint8 rank = _rankForDemon(tokenId);
    totalRankStaked += rank; // Portion of earnings ranges from 8 to 5
    flightIndices[tokenId] = flight[rank].length; // Store the location of the demon in the Flight
    flight[rank].push(
      Stake({ owner: account, tokenId: uint16(tokenId), value: uint80(gtPerRank) })
    ); // Add the demon to the Flight
    deposits[account].demons.add(tokenId);
    emit TokenStaked(account, tokenId, false, gtPerRank);
  }

  /** CLAIMING / UNSTAKING */

  /**
   * realize $GT earnings and optionally unstake tokens from the Temple / Flight
   * to unstake a Templar it will require it has 2 minutes worth of $GT unclaimed
   * @param tokenIds the IDs of the tokens to claim earnings from
   * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
   */
  function claimManyFromTempleAndFlight(uint16[] calldata tokenIds, bool unstake)
    external
    override
    whenNotPaused
    _updateEarnings
    nonReentrant
  {
    require(tx.origin == _msgSender() || _msgSender() == address(tndGame), 'Only EOA');
    uint256 owed = 0;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      if (tndNFT.isTemplar(tokenIds[i])) {
        owed += _claimTemplarFromTemple(tokenIds[i], unstake);
      } else {
        owed += _claimDemonFromFlight(tokenIds[i], unstake);
      }
    }
    gtToken.updateOriginAccess();
    if (owed == 0) {
      return;
    }
    gtToken.mint(_msgSender(), owed);
  }

  function calculateRewards(uint256 tokenId) external view returns (uint256 owed) {
    uint64 lastTokenWrite = tndNFT.getTokenWriteBlock(tokenId);
    // Must check this, as getTokenTraits will be allowed since this contract is an admin
    require(lastTokenWrite < block.number, 'hmmmm what doing?');
    Stake memory stake = temple[tokenId];
    if (tndNFT.isTemplar(tokenId)) {
      if (totalGTEarned < MAXIMUM_GLOBAL_GT) {
        owed = ((block.timestamp - stake.value) * DAILY_GT_RATE) / 1 minutes;
      } else if (stake.value > lastClaimTimestamp) {
        owed = 0; // $GT production stopped already
      } else {
        owed = ((lastClaimTimestamp - stake.value) * DAILY_GT_RATE) / 1 minutes; // stop earning additional $GT if it's all been earned
      }
    } else {
      uint8 rank = _rankForDemon(tokenId);
      owed = (rank) * (gtPerRank - stake.value); // Calculate portion of tokens based on Rank
    }
  }

  /**
   * realize $GT earnings for a single Templar and optionally unstake it
   * if not unstaking, pay a 20% tax to the staked Demons
   * if unstaking, there is a 50% chance all $GT is stolen
   * @param tokenId the ID of the Templars to claim earnings from
   * @param unstake whether or not to unstake the Templars
   * @return owed - the amount of $GT earned
   */
  function _claimTemplarFromTemple(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
    Stake memory stake = temple[tokenId];
    require(stake.owner == _msgSender(), "Don't own the given token");
    require(
      !(unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT),
      'Still guarding the temple'
    );
    if (totalGTEarned < MAXIMUM_GLOBAL_GT) {
      owed = ((block.timestamp - stake.value) * DAILY_GT_RATE) / 1 minutes;
    } else if (stake.value > lastClaimTimestamp) {
      owed = 0; // $GT production stopped already
    } else {
      owed = ((lastClaimTimestamp - stake.value) * DAILY_GT_RATE) / 1 minutes; // stop earning additional $GT if it's all been earned
    }
    if (unstake) {
      if (randomizer.random(tokenId) & 1 == 1) {
        // 50% chance of all $GT stolen
        _payDemonTax(owed);
        owed = 0;
      }
      delete temple[tokenId];
      numTemplarsStaked -= 1;
      deposits[stake.owner].templars.remove(tokenId);
      // Always transfer last to guard against reentrance
      tndNFT.safeTransferFrom(address(this), _msgSender(), tokenId, ''); // send back Templar
    } else {
      _payDemonTax((owed * GT_CLAIM_TAX_PERCENTAGE) / 100); // percentage tax to staked demons
      owed = (owed * (100 - GT_CLAIM_TAX_PERCENTAGE)) / 100; // remainder goes to Templar owner
      temple[tokenId] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        value: uint80(block.timestamp)
      }); // reset stake
    }
    emit TemplarClaimed(tokenId, unstake, owed);
  }

  /**
   * realize $GT earnings for a single Demon and optionally unstake it
   * Demons earn $GT proportional to their rank
   * @param tokenId the ID of the Demon to claim earnings from
   * @param unstake whether or not to unstake the Demon
   * @return owed - the amount of $GT earned
   */
  function _claimDemonFromFlight(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
    require(tndNFT.ownerOf(tokenId) == address(this), "Doesn't own token");
    uint8 rank = _rankForDemon(tokenId);
    Stake memory stake = flight[rank][flightIndices[tokenId]];
    require(stake.owner == _msgSender(), "Doesn't own token");
    owed = (rank) * (gtPerRank - stake.value); // Calculate portion of tokens based on Rank
    if (unstake) {
      totalRankStaked -= rank; // Remove rank from total staked
      Stake memory lastStake = flight[rank][flight[rank].length - 1];
      flight[rank][flightIndices[tokenId]] = lastStake; // Shuffle last Demon to current position
      flightIndices[lastStake.tokenId] = flightIndices[tokenId];
      flight[rank].pop(); // Remove duplicate
      delete flightIndices[tokenId]; // Delete old mapping
      // Always remove last to guard against reentrance
      deposits[stake.owner].demons.remove(tokenId);
      tndNFT.safeTransferFrom(address(this), _msgSender(), tokenId, ''); // Send back Demon
    } else {
      flight[rank][flightIndices[tokenId]] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        value: uint80(gtPerRank)
      }); // reset stake
    }
    emit DemonClaimed(tokenId, unstake, owed);
  }

  /**
   * emergency unstake tokens
   * @param tokenIds the IDs of the tokens to claim earnings from
   */
  function rescue(uint256[] calldata tokenIds) external nonReentrant {
    require(rescueEnabled, 'RESCUE DISABLED');
    uint256 tokenId;
    Stake memory stake;
    Stake memory lastStake;
    uint8 rank;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      if (tndNFT.isTemplar(tokenId)) {
        stake = temple[tokenId];
        require(stake.owner == _msgSender(), 'SWIPER, NO SWIPING');
        delete temple[tokenId];
        numTemplarsStaked -= 1;
        tndNFT.safeTransferFrom(address(this), _msgSender(), tokenId, ''); // send back Templars
        emit TemplarClaimed(tokenId, true, 0);
      } else {
        rank = _rankForDemon(tokenId);
        stake = flight[rank][flightIndices[tokenId]];
        require(stake.owner == _msgSender(), 'SWIPER, NO SWIPING');
        totalRankStaked -= rank; // Remove Rank from total staked
        lastStake = flight[rank][flight[rank].length - 1];
        flight[rank][flightIndices[tokenId]] = lastStake; // Shuffle last Demon to current position
        flightIndices[lastStake.tokenId] = flightIndices[tokenId];
        flight[rank].pop(); // Remove duplicate
        delete flightIndices[tokenId]; // Delete old mapping
        tndNFT.safeTransferFrom(address(this), _msgSender(), tokenId, ''); // Send back Demon
        emit DemonClaimed(tokenId, true, 0);
      }
    }
  }

  /** ACCOUNTING */

  /**
   * add $GT to claimable pot for the Flight
   * @param amount $GT to add to the pot
   */
  function _payDemonTax(uint256 amount) internal {
    if (totalRankStaked == 0) {
      // if there's no staked demons
      unaccountedRewards += amount; // keep track of $GT due to demons
      return;
    }
    // makes sure to include any unaccounted $GT
    gtPerRank += (amount + unaccountedRewards) / totalRankStaked;
    unaccountedRewards = 0;
  }

  /**
   * tracks $GT earnings to ensure it stops once 2.4 billion is eclipsed
   */
  modifier _updateEarnings() {
    if (totalGTEarned < MAXIMUM_GLOBAL_GT) {
      totalGTEarned +=
        ((block.timestamp - lastClaimTimestamp) * numTemplarsStaked * DAILY_GT_RATE) /
        1 minutes;
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
   * gets the rank score for a Demon
   * @param tokenId the ID of the Demon to get the rank score for
   * @return the rank score of the Demon (5-8)
   */
  function _rankForDemon(uint256 tokenId) internal view returns (uint8) {
    IGameNft.TemplarDemon memory s = tndNFT.getTokenTraits(tokenId);
    return MAX_RANK - s.rankIndex; // rank index is 0-3
  }

  /**
   * chooses a random Demon thief when a newly minted token is stolen
   * @param seed a random value to choose a Demon from
   * @return the owner of the randomly selected Demon thief
   */
  function randomDemonOwner(uint256 seed) external view override returns (address) {
    if (totalRankStaked == 0) {
      return address(0x0);
    }
    uint256 bucket = (seed & 0xFFFFFFFF) % totalRankStaked; // choose a value from 0 to total rank staked
    uint256 cumulative;
    seed >>= 32;
    // loop through each bucket of Demons with the same rank score
    for (uint256 i = MAX_RANK - 3; i <= MAX_RANK; i++) {
      cumulative += flight[i].length * i;
      // if the value is not inside of that bucket, keep going
      if (bucket >= cumulative) continue;
      // get the address of a random Demon with that rank score
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
    require(from == address(0x0), 'Cannot send to Temple directly');
    return IERC721Receiver.onERC721Received.selector;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface ITnDGame {}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';

interface IGameNft is IERC721Enumerable {
  // game data storage
  struct TemplarDemon {
    bool isTemplar;
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

  function getTokenTraits(uint256 tokenId) external view returns (TemplarDemon memory);

  function getTokenWriteBlock(uint256 tokenId) external view returns (uint64);

  function isTemplar(uint256 tokenId) external view returns (bool);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IGameToken {
  function mint(address to, uint256 amount) external;

  function burn(address from, uint256 amount) external;

  function updateOriginAccess() external;

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface ITemple {
  function addManyToTempleAndFlight(address account, uint16[] calldata tokenIds) external;

  function claimManyFromTempleAndFlight(uint16[] calldata tokenIds, bool unstake) external;

  function depositsOf(address account) external view returns (uint256[] memory);

  function randomDemonOwner(uint256 seed) external view returns (address);

  function isTokenStaked(uint256 tokenId) external view returns (bool);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IAltar {
  function mint(
    uint256 typeId,
    uint16 qty,
    address recipient
  ) external;

  function burn(
    uint256 typeId,
    uint16 qty,
    address burnFrom
  ) external;

  function updateOriginAccess() external;

  function balanceOf(address account, uint256 id) external returns (uint256);

  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) external;
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

interface IRandom {
  function random(uint256 seed) external returns (uint256);
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
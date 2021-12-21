// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/IHNDGame.sol";
import "./interfaces/IHND.sol";
import "./interfaces/IEXP.sol";
import "./interfaces/IKingdom.sol";

contract Kingdom is IKingdom, Ownable, ReentrancyGuard, IERC721Receiver, Pausable {
  
  // maximum rank for a Hero/Demon
  uint8 public constant MAX_RANK = 8;

  // struct to store a stake's token, owner, and earning values
  struct Stake {
    uint16 tokenId;
    uint80 value;
    address owner;
  }

  uint256 private totalRankStaked;
  uint256 private numHeroesStaked;

  event TokenStaked(address indexed owner, uint256 indexed tokenId, bool indexed isHero, uint256 value);
  event HeroClaimed(uint256 indexed tokenId, bool indexed unstaked, uint256 earned);
  event DemonClaimed(uint256 indexed tokenId, bool indexed unstaked, uint256 earned);

  // reference to the HND NFT contract
  IHND public HNDNFT;
  // reference to the HND NFT contract
  IHNDGame public HNDGame;
  // reference to the $EXP contract for minting $EXP earnings
  IEXP public expToken;

  // maps tokenId to stake
  mapping(uint256 => Stake) private kingdom; 
  // maps rank to all Demon staked with that rank
  mapping(uint256 => Stake[]) private army; 
  // tracks location of each Demon in Army
  mapping(uint256 => uint256) private armyIndices; 
  // any rewards distributed when no demons are stakd
  mapping(address => uint256[]) public stakedTokenOwners;
  //holds mapping of their position in stakedTokenOwners
  mapping(uint256 => uint256) private stakedTokenIndex;

  uint256 private unaccountedRewards = 0; 
  // amount of $EXP due for each rank point staked
  uint256 private expPerRank = 0; 

  // heroes earn 10000 $EXP per day
  uint256 public constant DAILY_EXP_RATE = 10000 ether;

  // gen0 heroes earn 10000 $EXP per day
  uint256 public constant GEN0_DAILY_EXP_RATE = 15000 ether;

  // heroes must have 2 days worth of $EXP to unstake or else they're still guarding the Kingdom
  uint256 public constant MINIMUM_TO_EXIT = 2 days;
  // demons take a 20% tax on all $EXP claimede
  uint256 public constant EXP_CLAIM_TAX_PERCENTAGE = 20;

  // when heroes are leaving demons have 50% chance to take 50% of their earned $EXP instead of 20%
  uint256 public constant EXP_STOLEN_DENOMINATOR = 2;

  // 10,000,000,000  $EXP used and cycled through during combat
  uint256 public constant MAXIMUM_GLOBAL_EXP = 10000000000 ether;
  
  // $EXP that has been dispensed from the faucet during combat
  uint256 public expFromFaucet;
  // the last time $EXP was claimed
  uint256 private lastClaimTimestamp;

  // emergency rescue to allow unstaking without any checks but without $EXP
  bool public rescueEnabled = false;

  mapping(address => bool) private admins;

  /**
   */
  constructor() {
    _pause();
  }

  /** CRITICAL TO SETUP */

  modifier requireContractsSet() {
      require(address(HNDNFT) != address(0) && address(expToken) != address(0) 
        && address(HNDGame) != address(0), "Contracts not set");
      _;
  }

  function setContracts(address _HNDNFT, address _exp, address _HNDGame) external onlyOwner {
    HNDNFT = IHND(_HNDNFT);
    expToken = IEXP(_exp);
    HNDGame = IHNDGame(_HNDGame);
  }

  /** STAKING */

  /**
   * adds Heros and Demons to the Kingdom and Army
   * @param account the address of the staker
   * @param tokenIds the IDs of the Heros and Demons to stake
   */
  function addManyToKingdom(address account, uint16[] calldata tokenIds) external override nonReentrant {
    require(tx.origin == _msgSender() || _msgSender() == address(HNDGame), "Only EOA");
    require(account == tx.origin, "account to sender mismatch");
    for (uint i = 0; i < tokenIds.length; i++) {
      if (_msgSender() != address(HNDGame)) { // dont do this step if its a mint + stake
        require(HNDNFT.ownerOf(tokenIds[i]) == _msgSender(), "You don't own this token");
        HNDNFT.transferFrom(_msgSender(), address(this), tokenIds[i]);
      } else if (tokenIds[i] == 0) {
        continue; // there may be gaps in the array for stolen tokens
      }

      if (HNDNFT.isHero(tokenIds[i])) 
        _addHeroToKingdom(account, tokenIds[i]);
      else 
        _addDemonToArmy(account, tokenIds[i]);
    }
  }

  /**
   * adds a single Hero to the Kingdom
   * @param account the address of the staker
   * @param tokenId the ID of the Hero to add to the Kingdom
   */
  function _addHeroToKingdom(address account, uint256 tokenId) internal whenNotPaused _updateEarnings {
    kingdom[tokenId] = Stake({
      owner: account,
      tokenId: uint16(tokenId),
      value: uint80(block.timestamp)
    });
    stakedTokenIndex[tokenId] = stakedTokenOwners[account].length;
    stakedTokenOwners[account].push(tokenId);
    numHeroesStaked += 1;
    emit TokenStaked(account, tokenId, true, block.timestamp);
  }

  /**
   * adds a single Demon to the Army
   * @param account the address of the staker
   * @param tokenId the ID of the Demon to add to the Army
   */
  function _addDemonToArmy(address account, uint256 tokenId) internal {
    uint8 rank = _rankForDemon(tokenId);
    totalRankStaked += rank; // Portion of earnings ranges from 8 to 5
    armyIndices[tokenId] = army[rank].length; // Store the location of the demon in the Army
    army[rank].push(Stake({
      owner: account,
      tokenId: uint16(tokenId),
      value: uint80(expPerRank)
    })); // Add the demon to the Army
    stakedTokenIndex[tokenId] = stakedTokenOwners[account].length;
    stakedTokenOwners[account].push(tokenId);
    emit TokenStaked(account, tokenId, false, expPerRank);
  }

  /** CLAIMING / UNSTAKING */

  /**
   * realize $EXP earnings and optionally unstake tokens from the Kingdom
   * to unstake a Hero it will require it has 2 days worth of $EXP unclaimed
   * @param tokenIds the IDs of the tokens to claim earnings from
   * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
   */
  function claimManyFromKingdom(uint16[] calldata tokenIds, bool unstake) external whenNotPaused _updateEarnings nonReentrant {
    require(tx.origin == _msgSender() || _msgSender() == address(HNDGame), "Only EOA");
    uint256 owed = 0;
    for (uint i = 0; i < tokenIds.length; i++) {
      if (HNDNFT.isHero(tokenIds[i])) {
        owed += _claimHeroFromKingdom(tokenIds[i], unstake);
      }
      else {
        owed += _claimDemonFromArmy(tokenIds[i], unstake);
      }
    }
    expToken.updateOriginAccess();
    if (owed == 0) {
      return;
    }

    expToken.mint(_msgSender(), owed);
  }

  function calculateRewards(uint256 tokenId) external view returns (uint256 owed) {
    uint64 lastTokenWrite = HNDNFT.getTokenWriteBlock(tokenId);
    // Must check this, as getTokenTraits will be allowed since this contract is an admin
    require(lastTokenWrite < block.number, "hmmmm what doing?");
    Stake memory stake = kingdom[tokenId];
    if(HNDNFT.isHero(tokenId)) {
      if (expFromFaucet < MAXIMUM_GLOBAL_EXP) {
        owed = (block.timestamp - stake.value) * DAILY_EXP_RATE / 1 days;
        if (HNDNFT.getPaidTokens() >= tokenId) { // if they are a gen0 hero earn 15k
          owed = (block.timestamp - stake.value) * GEN0_DAILY_EXP_RATE / 1 days;
        }
      } else if (stake.value > lastClaimTimestamp) {
        owed = 0; // $EXP production stopped already
      } else {
        owed = (lastClaimTimestamp - stake.value) * DAILY_EXP_RATE / 1 days; // stop earning additional $EXP if it's all been earned

        if (HNDNFT.getPaidTokens() >= tokenId) {
          (lastClaimTimestamp - stake.value) * GEN0_DAILY_EXP_RATE / 1 days;
        }
      }
    }
    else {
      uint8 rank = _rankForDemon(tokenId);
      owed = (rank) * (expPerRank - stake.value); // Calculate portion of tokens based on Rank
    }
  }

  /**
   * realize $EXP earnings for a single Hero and optionally unstake it
   * if not unstaking, pay a 20% tax to the staked Demons
   * if unstaking, there is a 50% chance all $EXP is stolen
   * @param tokenId the ID of the Heros to claim earnings from
   * @param unstake whether or not to unstake the Heros
   * @return owed - the amount of $EXP earned
   */
  function _claimHeroFromKingdom(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
    require(HNDNFT.ownerOf(tokenId) == address(this), "Kingdom: Claiming unstaked hero!");
    Stake memory stake = kingdom[tokenId];
    require(stake.owner == _msgSender(), "Kingdom: Claiming unowned hero!");
    require(!(unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT), "Kingdom: Hero is still guarding!");
    if (expFromFaucet < MAXIMUM_GLOBAL_EXP) {
      owed = (block.timestamp - stake.value) * DAILY_EXP_RATE / 1 days;
    } else if (stake.value > lastClaimTimestamp) {
      owed = 0; // $EXP production stopped already
    } else {
      owed = (lastClaimTimestamp - stake.value) * DAILY_EXP_RATE / 1 days; // stop earning additional $EXP if it's all been earned
    }
    if (unstake) {
      // 50% chance of half $EXP being stolen
      if (uint256(keccak256(abi.encode(blockhash(block.number-1), _msgSender(), tokenId))) % 2 == 1) { 

        //steal half of $EXP accumulated
        _payDemonTax(owed/EXP_STOLEN_DENOMINATOR); 

        // keep half the $EXP
        owed = (owed/EXP_STOLEN_DENOMINATOR);
      }
      delete kingdom[tokenId];
      delete stakedTokenOwners[_msgSender()][stakedTokenIndex[tokenId]];
      stakedTokenIndex[tokenId] = 0;
      numHeroesStaked -= 1;
      
      HNDNFT.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Hero
    } else {
      _payDemonTax(owed * EXP_CLAIM_TAX_PERCENTAGE / 100); // percentage tax to staked demons
      
      // send leftover
      owed = owed * (100 - EXP_CLAIM_TAX_PERCENTAGE) / 100; // remainder goes to Hero owner
      
      // reset their stake
      kingdom[tokenId] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        value: uint80(block.timestamp)
      }); 
    }
    emit HeroClaimed(tokenId, unstake, owed);
  }

  /**
   * realize $EXP earnings for a single Demon and optionally unstake it
   * Demons earn $EXP proportional to their rank
   * @param tokenId the ID of the Demon to claim earnings from
   * @param unstake whether or not to unstake the Demon
   * @return  owed  the amount of $EXP earned
   */
  function _claimDemonFromArmy(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
    require(HNDNFT.ownerOf(tokenId) == address(this), "Kingdom: Claiming unstaked demon!");
    uint8 rank = _rankForDemon(tokenId);
    Stake memory stake = army[rank][armyIndices[tokenId]];
    require(stake.owner == _msgSender(), "Kingdom: Claiming unowned demon!");
    owed = (rank) * (expPerRank - stake.value); // Calculate portion of tokens based on Rank
    if (unstake) {
      totalRankStaked -= rank; // Remove rank from total staked
      Stake memory lastStake = army[rank][army[rank].length - 1];
      army[rank][armyIndices[tokenId]] = lastStake; // Shuffle last Demon to current position
      armyIndices[lastStake.tokenId] = armyIndices[tokenId];
      army[rank].pop(); // Remove duplicate
      delete armyIndices[tokenId]; // Delete old mapping
      delete stakedTokenOwners[_msgSender()][stakedTokenIndex[tokenId]];
      stakedTokenIndex[tokenId] = 0;
      // Always remove last to guard against reentrance
      HNDNFT.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Demon
    } else {

      // we reset their stake
      army[rank][armyIndices[tokenId]] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        value: uint80(expPerRank)
      });
    }
    emit DemonClaimed(tokenId, unstake, owed);
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
      if (HNDNFT.isHero(tokenId)) {
        stake = kingdom[tokenId];
        require(stake.owner == _msgSender(), "must own token");
        delete kingdom[tokenId];
        numHeroesStaked -= 1;
        HNDNFT.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Heros
        emit HeroClaimed(tokenId, true, 0);
      } else {
        rank = _rankForDemon(tokenId);
        stake = army[rank][armyIndices[tokenId]];
        require(stake.owner == _msgSender(), "must own token");
        totalRankStaked -= rank; // Remove Rank from total staked
        lastStake = army[rank][army[rank].length - 1];
        army[rank][armyIndices[tokenId]] = lastStake; // Shuffle last Demon to current position
        armyIndices[lastStake.tokenId] = armyIndices[tokenId];
        army[rank].pop(); // Remove duplicate
        delete armyIndices[tokenId]; // Delete old mapping
        HNDNFT.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Demon
        emit DemonClaimed(tokenId, true, 0);
      }
    }
  }

  /** ACCOUNTING */

  /** 
   * add $EXP to claimable pot for the Army
   * @param amount $EXP to add to the pot
   */
  function _payDemonTax(uint256 amount) internal {
    if (totalRankStaked == 0) { // if there's no staked demons
      unaccountedRewards += amount; // keep track of $EXP due to demons
      return;
    }
    // makes sure to include any unaccounted $EXP 
    expPerRank += (amount + unaccountedRewards) / totalRankStaked;
    unaccountedRewards = 0;
  }

    /** 
   * add $EXP to claimable pot for the Army
   * @param amount $EXP to add to the pot
   */
  function recycleExp(uint256 amount) override external {
    require(owner() == _msgSender() || admins[_msgSender()], "Only admins can call this");
    expFromFaucet -= amount;
  }

  /**
   * tracks $EXP earnings to ensure it stops once 10 billion is eclipsed
   */
  modifier _updateEarnings() {
    if (expFromFaucet < MAXIMUM_GLOBAL_EXP) {
      expFromFaucet += 
        (block.timestamp - lastClaimTimestamp)
        * numHeroesStaked
        * DAILY_EXP_RATE / 1 days; 
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
    IHND.HeroDemon memory s = HNDNFT.getTokenTraits(tokenId);
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
    for (uint i = MAX_RANK - 3; i <= MAX_RANK; i++) {
      cumulative += army[i].length * i;
      // if the value is not inside of that bucket, keep going
      if (bucket >= cumulative) continue;
      // get the address of a random Demon with that rank score
      return army[i][seed % army[i].length].owner;
    }
    return address(0x0);
  }

  function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
      require(from == address(0x0), "Cannot send to Kingdom directly");
      return IERC721Receiver.onERC721Received.selector;
    }

  /**
  * enables an address to mint / burn
  * @param addr the address to enable
  */
  function addAdmin(address addr) external onlyOwner {
      admins[addr] = true;
  }

  /**
  * disables an address from minting / burning
  * @param addr the address to disbale
  */
  function removeAdmin(address addr) external onlyOwner {
      admins[addr] = false;
  }
  
  }

// SPDX-License-Identifier: MIT LICENSE 

pragma solidity ^0.8.0;

interface IKingdom {
  function addManyToKingdom(address account, uint16[] calldata tokenIds) external;
  function randomDemonOwner(uint256 seed) external view returns (address);
  function recycleExp(uint256 amount) external;
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IEXP {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function updateOriginAccess() external;
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IHND is IERC721Enumerable {

    // game data storage
    struct HeroDemon {
        bool isHero;
        bool isFemale;
        uint8 body;
        uint8 face;
        uint8 eyes;
        uint8 headpiecehorns;
        uint8 gloves;
        uint8 armor;
        uint8 weapon;
        uint8 shield;
        uint8 shoes;
        uint8 tailflame;
        uint8 rankIndex;
    }

    function minted() external returns (uint16);
    function updateOriginAccess(uint16[] memory tokenIds) external;
    function mint(address recipient, uint256 seed) external;
    function burn(uint256 tokenId) external;
    function getMaxTokens() external view returns (uint256);
    function getPaidTokens() external view returns (uint256);
    function getTokenTraits(uint256 tokenId) external view returns (HeroDemon memory);
    function getTokenWriteBlock(uint256 tokenId) external view returns(uint64);
    function isHero(uint256 tokenId) external view returns(bool);
  
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IHNDGame {
  
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
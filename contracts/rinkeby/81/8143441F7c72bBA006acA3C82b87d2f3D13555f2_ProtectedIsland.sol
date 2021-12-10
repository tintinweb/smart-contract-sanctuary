// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interface/IGoat.sol";
import "./interface/IEGG.sol";
import "./interface/IEnchantedGame.sol";
import "./interface/IRandomizer.sol";

contract ProtectedIsland is Ownable, IERC721Receiver, Pausable, ReentrancyGuard {
  // maximum fertility score for a Goat/Tortoises
  uint8 public constant MAX_FERTILITY = 4;

  // struct to store a stake's token, owner, and earning values
  struct Stake {
    uint16 tokenId;
    uint80 value;
    address owner;
  }
  struct Information {
      uint256[] stakedTokens;
  }

  event TokenStaked(address indexed owner, uint256 indexed tokenId, bool indexed isTortoise, uint256 value);
  event TortoiseClaimed(uint256 tokenId, uint256 earned, uint256 expected, bool unstaked);
  event GoatClaimed(uint256 tokenId, uint256 earned, uint256 expected, bool unstaked);

  // maps address for token id's per user
  mapping(address => Information) user;
  // maps tokenId to stake
  mapping(uint256 => Stake) public protectedIsland; 
  // maps fertility to all Goat stakes with that fertility
  mapping(uint256 => Stake[]) public pack; 
  // tracks location of each Goat in Pack
  mapping(uint256 => uint256) public packIndices; 

  // Tortoise earn 10000 $EGG per day
  uint256 public constant DAILY_EGG_RATE = 10000 ether;
  // Tortoise must have 2 days worth of $EGG to unstake or else it's too cold
  uint256 public MINIMUM_TO_EXIT = 2 days;
  // goats take a 20% tax on all $EGG claimed
  uint256 public constant EGG_CLAIM_TAX_PERCENTAGE = 20;
  // there will only ever be (roughly) 2.4 billion $EGG earned through staking
  uint256 public constant MAXIMUM_GLOBAL_EGG = 2400000000 ether;
  // amount of $EGG earned so far
  uint256 public totalEggEarned;
  // number of Tortoise staked in the ProtectedIsland
  uint256 public totalTortoiseStaked;
  // number of Goat staked in the ProtectedIsland
  uint256 public totalGoatStaked;
  // the last time $EGG was claimed
  uint256 public lastClaimTimestamp;
  // total fertility scores staked
  uint256 public totalFertilityStaked; 
  // any rewards distributed when no goats are staked
  uint256 public unaccountedRewards; 
  // amount of $EGG due for each fertility point staked
  uint256 public eggPerFertility; 
  // amount of $EGG being claimed
  uint256 public eggClaimed; 

  // reference to the Goat NFT contract
  IGoat public goatNFT;
  // reference to the Enchanted Game contract
  IEnchantedGame public enchantedGame;
  // reference to the $EGG contract for minting $EGG earnings
  IEGG public eggToken;
  // reference to Randomer 
  IRandomizer public randomizer;
  
  // emergency rescue to allow unstaking without any checks but without $EGG
  bool public rescueEnabled = false;

  /**
  */
  constructor() {}

  /** CRITICAL TO SETUP */

  modifier requireContractsSet() {
      require(address(goatNFT) != address(0) && address(eggToken) != address(0) 
        && address(enchantedGame) != address(0) && address(randomizer) != address(0), "Contracts not set");
      _;
  }

  function setContracts(address _goatNFT, address _eggToken, address _enchantedGame, address _rand) external onlyOwner {
    goatNFT = IGoat(_goatNFT);
    enchantedGame = IEnchantedGame(_enchantedGame);
    eggToken = IEGG(_eggToken);
    randomizer = IRandomizer(_rand);
  }

  /** STAKING */

  /**
   * adds Tortoise and Goats to the ProtectedIsland and Pack
   * @param account the address of the staker
   * @param tokenIds the IDs of the Tortoise and Goats to stake
   */
  function addManyToProtectedIslandAndPack(address account, uint16[] calldata tokenIds) external nonReentrant {
    require(tx.origin == _msgSender() || _msgSender() == address(enchantedGame), "Only EOA");
    require(account == tx.origin, "account to sender mismatch");
    for (uint i = 0; i < tokenIds.length; i++) {
      if (_msgSender() != address(enchantedGame)) { // dont do this step if its a mint + stake
        require(goatNFT.ownerOf(tokenIds[i]) == _msgSender(), "You don't own this token");
        goatNFT.transferFrom(_msgSender(), address(this), tokenIds[i]);
      } else if (tokenIds[i] == 0) {
        continue; // there may be gaps in the array for stolen tokens
      }

      if (goatNFT.isTortoise(tokenIds[i])) 
        _addTortoiseToProtectedIsland(account, tokenIds[i]);
      else 
       _addGoatToPack(account, tokenIds[i]);
    }
  }

  /**
   * adds a single Tortoise to the ProtectedIsland
   * @param account the address of the staker
   * @param tokenId the ID of the Tortoise to add to the ProtectedIsland
   */
  function _addTortoiseToProtectedIsland(address account, uint256 tokenId) internal whenNotPaused _updateEarnings {
    protectedIsland[tokenId] = Stake({
      owner: account,
      tokenId: uint16(tokenId),
      value: uint80(block.timestamp)
    });
    totalTortoiseStaked += 1;
    user[account].stakedTokens.push(tokenId);

    emit TokenStaked(account, tokenId, true, block.timestamp);
  }

  /**
   * adds a single Goat to the Pack
   * @param account the address of the staker
   * @param tokenId the ID of the Goat to add to the Pack
   */
  function _addGoatToPack(address account, uint256 tokenId) internal {
    uint8 fertility = _fertilityForGoat(tokenId);
    totalFertilityStaked += fertility; // Portion of earnings ranges from 8 to 5
    packIndices[tokenId] = pack[fertility].length; // Store the location of the Goat in the Pack
    pack[fertility].push(Stake({
      owner: account,
      tokenId: uint16(tokenId),
      value: uint80(eggPerFertility)
    })); // Add the Goat to the Pack

    user[account].stakedTokens.push(tokenId);
    emit TokenStaked(account, tokenId, false, eggPerFertility);
  }

  /** CLAIMING / UNSTAKING */

  /**
   * realize $EGG earnings and optionally unstake tokens from the ProtectedIsland / Pack
   * to unstake a Tortoise it will require it has 2 days worth of $EGG unclaimed
   * @param tokenIds the IDs of the tokens to claim earnings from
   * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
   */
  function claimManyFromProtectedIslandAndPack(uint16[] calldata tokenIds, bool unstake) external whenNotPaused _updateEarnings nonReentrant {
    require(tx.origin == _msgSender() || _msgSender() == address(enchantedGame), "Only EOA");
    uint256 owed = 0;
    for (uint i = 0; i < tokenIds.length; i++) {
      if (goatNFT.isTortoise(tokenIds[i])) {
        owed += _claimTortoiseFromProtectedIsland(tokenIds[i], unstake);
      } else {
        owed += _claimGoatFromPack(tokenIds[i], unstake);
      }
    }
    eggToken.updateOriginAccess();

    if (owed == 0) return;
    eggToken.mint(_msgSender(), owed);
  }

  /**
   * realize $EGG earnings for a single Tortoise and optionally unstake it
   * if not unstaking, pay a 20% tax to the staked goats
   * if unstaking, there is a 50% chance all $EGG is stolen
   * @param tokenId the ID of the Goats to claim earnings from
   * @param unstake whether or not to unstake the Goats
   * @return owed - the amount of $EGG earned
   */
  function _claimTortoiseFromProtectedIsland(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
    Stake memory stake = protectedIsland[tokenId];
    require(stake.owner == _msgSender(), "Don't own the given token");
    require(!(unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT), "Still guarding the protected island");
    if (totalEggEarned < MAXIMUM_GLOBAL_EGG) {
      owed = (block.timestamp - stake.value) * DAILY_EGG_RATE / 1 days;
    } else if (stake.value > lastClaimTimestamp) {
      owed = 0; // $EGG production stopped already
    } else {
      owed = (lastClaimTimestamp - stake.value) * DAILY_EGG_RATE / 1 days; // stop earning additional $EGG if it's all been earned
    }
    uint256 expected = owed;
    if (unstake) {
      if(randomizer.random(tokenId, uint64(block.timestamp), uint64(block.number)) & 1 == 1) { // 50% chance of all $EGG stolen
        _payGoatTax(owed);
        owed = 0;
      }
      delete protectedIsland[tokenId];
      totalTortoiseStaked -= 1;
      // Always transfer last to guard against reentrance
      goatNFT.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Tortoise
    } else {
      _payGoatTax(owed * EGG_CLAIM_TAX_PERCENTAGE / 100); // percentage tax to staked goats
      owed = owed * (100 - EGG_CLAIM_TAX_PERCENTAGE) / 100; // remainder goes to Tortoise owner
      protectedIsland[tokenId] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        value: uint80(block.timestamp)
      }); // reset stake
    }

    eggClaimed += owed;
    emit TortoiseClaimed(tokenId, owed, expected, unstake);
  }

  /**
   * realize $EGG earnings for a single Goat and optionally unstake it
   * Goats earn $EGG proportional to their Fertility rank
   * @param tokenId the ID of the Goat to claim earnings from
   * @param unstake whether or not to unstake the Goat
   * @return owed - the amount of $EGG earned
   */
  function _claimGoatFromPack(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
    require(goatNFT.ownerOf(tokenId) == address(this), "Doesn't own token");
    uint256 fertility = _fertilityForGoat(tokenId);
    Stake memory stake = pack[fertility][packIndices[tokenId]];
    require(stake.owner == _msgSender(), "Doesn't own token");
    owed = (fertility) * (eggPerFertility - stake.value); // Calculate portion of tokens based on Rank
    uint256 expected = owed;
    if (unstake) {
      totalFertilityStaked -= fertility; // Remove rank from total staked
      Stake memory lastStake = pack[fertility][pack[fertility].length - 1];
      pack[fertility][packIndices[tokenId]] = lastStake; // Shuffle last Dragon to current position
      packIndices[lastStake.tokenId] = packIndices[tokenId];
      pack[fertility].pop(); // Remove duplicate
      delete packIndices[tokenId]; // Delete old mapping
      // Always remove last to guard against reentrance
      goatNFT.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Dragon
    } else {
      pack[fertility][packIndices[tokenId]] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        value: uint80(eggPerFertility)
      }); // reset stake
    }
    
    eggClaimed += owed;
    emit GoatClaimed(tokenId, owed, expected, unstake);
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
    uint256 fertility;
    for (uint i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      if (goatNFT.isTortoise(tokenId)) {
        stake = protectedIsland[tokenId];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        delete protectedIsland[tokenId];
        totalTortoiseStaked -= 1;
        goatNFT.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Tortoise
        emit TortoiseClaimed(tokenId, 0, 0, true);
      } else {
        fertility = _fertilityForGoat(tokenId);
        stake = pack[fertility][packIndices[tokenId]];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        totalFertilityStaked -= fertility; // Remove Fertility from total staked
        lastStake = pack[fertility][pack[fertility].length - 1];
        pack[fertility][packIndices[tokenId]] = lastStake; // Shuffle last Goat to current position
        packIndices[lastStake.tokenId] = packIndices[tokenId];
        pack[fertility].pop(); // Remove duplicate
        delete packIndices[tokenId]; // Delete old mapping
        totalGoatStaked -= 1;

        goatNFT.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Goat
        emit GoatClaimed(tokenId, 0, 0, true);
      }

      deleteStakedToken(_msgSender(), tokenId);
    }
  }

  /** ACCOUNTING */
  /** 
  * returns all the staked token id's for a specifik _wallet
  * @param _wallet users wallet address 
  */
  function getStakedTokens(address _wallet) external view returns (uint256 [] memory) {
      return user[_wallet].stakedTokens;
  }

  /** 
  * add $EGG to claimable pot for the Pack
  * @param amount $EGG to add to the pot
  */
  function _payGoatTax(uint256 amount) internal {
    if (totalFertilityStaked == 0) { // if there's no staked goats
      unaccountedRewards += amount; // keep track of $EGG due to goats
      return;
    }
    // makes sure to include any unaccounted $EGG 
    eggPerFertility += (amount + unaccountedRewards) / totalFertilityStaked;
    unaccountedRewards = 0;
  }

  /**
  * tracks $EGG earnings to ensure it stops once 2.4 billion is eclipsed
  */
  modifier _updateEarnings() {
    if (totalEggEarned < MAXIMUM_GLOBAL_EGG) {
      totalEggEarned += 
        (block.timestamp - lastClaimTimestamp)
        * totalTortoiseStaked
        * DAILY_EGG_RATE / 1 days; 
      lastClaimTimestamp = block.timestamp;
    }
    _;
  }

  /**
  * Deletes the token id based on the index value of the struct array
  */
  function deleteStakedTokenFromUserByIndex(uint _index) internal returns(bool) {
    for (uint i = _index; i < user[_msgSender()].stakedTokens.length - 1; i++) {
      user[_msgSender()].stakedTokens[i] = user[_msgSender()].stakedTokens[i + 1];
    }

    user[_msgSender()].stakedTokens.pop();
    return true;
  } 

  /**
  * Deletes the token id based on the index value of the struct array
  */
  function deleteStakedToken(address _user, uint256 _tokenId) internal {
    for (uint256 index = 0; index < user[_user].stakedTokens.length; index++) {
      if(user[_user].stakedTokens[index] == _tokenId) {
        deleteStakedTokenFromUserByIndex(index);
      }
    }
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
   * enables owner to pause / unpause minting
   */
  function setPaused(bool _paused) external onlyOwner {
    if (_paused) _pause();
    else _unpause();
  }

  /**
  * @param _minimumTimeToExit the amount for exiting the stake
  */
  function setMinimumTimeToExit(uint256 _minimumTimeToExit) external onlyOwner {
    MINIMUM_TO_EXIT = _minimumTimeToExit;
  }

  /** READ ONLY */


  /**
   * gets the fertility score for a Goat
   * @param tokenId the ID of the Goat to get the fertility score for
   * @return the fertility score of the Goat (5-8)
   */
  function _fertilityForGoat(uint256 tokenId) internal view returns (uint8) {
    IGoat.GoatTortoise memory s = goatNFT.getTokenTraits(tokenId);
    return MAX_FERTILITY - s.fertilityIndex; // rank index is 0-3
  }

  /**
   * chooses a random Goat thief when a newly minted token is stolen
   * @param seed a random value to choose a Goat from
   * @return the owner of the randomly selected Goat thief
   */
  function randomGoatOwner(uint256 seed) external view returns (address) {
    if (totalFertilityStaked == 0) return address(0x0);
    uint256 bucket = (seed & 0xFFFFFFFF) % totalFertilityStaked; // choose a value from 0 to total fertility staked
    uint256 cumulative;
    seed >>= 32;
    // loop through each bucket of Goats with the same fertility score
    for (uint i = MAX_FERTILITY - 3; i <= MAX_FERTILITY; i++) {
      cumulative += pack[i].length * i;
      // if the value is not inside of that bucket, keep going
      if (bucket >= cumulative) continue;
      // get the address of a random Goat with that fertility score
      return pack[i][seed % pack[i].length].owner;
    }
    return address(0x0);
  }


 function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
      require(from == address(0x0), "Cannot send to ProtectedIsland directly");
      return IERC721Receiver.onERC721Received.selector;
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

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IGoat is IERC721Enumerable {

  // struct to store each token's traits
  struct GoatTortoise {
    bool isTortoise;
    uint8 fur;
    uint8 skin;
    uint8 ears;
    uint8 eyes;
    uint8 shell;
    uint8 face;
    uint8 neck;
    uint8 feet;
    uint8 accessory;
    uint8 fertilityIndex;
  }

    function minted() external returns (uint16);
    function updateOriginAccess(uint16[] memory tokenIds) external;
    function mint(address recipient, uint256 seed) external;
    function burn(uint256 tokenId) external;
    function getMaxTokens() external view returns (uint256);
    function getPaidTokens() external view returns (uint256);
    function getTokenTraits(uint256 tokenId) external view returns (GoatTortoise memory);
    function getTokenWriteBlock(uint256 tokenId) external view returns(uint64);
    function isTortoise(uint256 tokenId) external view returns(bool);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IEGG {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function updateOriginAccess() external;
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IEnchantedGame {}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IRandomizer {
    function random(uint256 seed, uint64 timestamp, uint64 blockNumber) external returns (uint256);
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
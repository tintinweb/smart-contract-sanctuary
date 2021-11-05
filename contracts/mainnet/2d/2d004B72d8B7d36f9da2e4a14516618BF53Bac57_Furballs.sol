// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

// import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./editions/IFurballEdition.sol";
import "./engines/ILootEngine.sol";
import "./engines/EngineA.sol";
import "./utils/FurLib.sol";
import "./utils/FurDefs.sol";
import "./utils/FurProxy.sol";
import "./utils/Moderated.sol";
import "./utils/Governance.sol";
import "./Fur.sol";
import "./Furgreement.sol";
// import "hardhat/console.sol";

/// @title Furballs
/// @author LFG Gaming LLC
/// @notice Mints Furballs on the Ethereum blockchain
/// @dev https://furballs.com/contract
contract Furballs is ERC721Enumerable, Moderated {
  Fur public fur;

  IFurballEdition[] public editions;

  ILootEngine public engine;

  Governance public governance;

  Furgreement public furgreement;

  // tokenId => furball data
  mapping(uint256 => FurLib.Furball) public furballs;

  // tokenId => all rewards assigned to that Furball
  mapping(uint256 => FurLib.Rewards) public collect;

  // The amount of time over which FUR/EXP is accrued (usually 3600=>1hour); used with test servers
  uint256 public intervalDuration;

  // When play/collect runs, returns rewards
  event Collection(uint256 tokenId, uint256 responseId);

  // Inventory change event
  event Inventory(uint256 tokenId, uint128 lootId, uint16 dropped);

  constructor(uint256 interval) ERC721("Furballs", "FBL") {
    intervalDuration = interval;
  }

  // -----------------------------------------------------------------------------------------------
  // Public transactions
  // -----------------------------------------------------------------------------------------------

  /// @notice Mints a new furball from the current edition (if there are any remaining)
  /// @dev Limits and fees are set by IFurballEdition
  function mint(address[] memory to, uint8 editionIndex, address actor) external {
    (address sender, uint8 permissions) = _approvedSender(actor);
    require(to.length == 1 || permissions >= FurLib.PERMISSION_MODERATOR, "MULT");

    for (uint8 i=0; i<to.length; i++) {
      fur.purchaseMint(sender, permissions, to[i], editions[editionIndex]);
      _spawn(to[i], editionIndex, 0);
    }
  }

  /// @notice Feeds the furball a snack
  /// @dev Delegates logic to fur
  function feed(FurLib.Feeding[] memory feedings, address actor) external {
    (address sender, uint8 permissions) = _approvedSender(actor);
    uint256 len = feedings.length;

    for (uint256 i=0; i<len; i++) {
      fur.purchaseSnack(sender, permissions, feedings[i].tokenId, feedings[i].snackId, feedings[i].count);
    }
  }

  /// @notice Begins exploration mode with the given furballs
  /// @dev Multiple furballs accepted at once to reduce gas fees
  /// @param tokenIds The furballs which should start exploring
  /// @param zone The explore zone (otherwize, zero for battle mode)
  function playMany(uint256[] memory tokenIds, uint32 zone, address actor) external {
    (address sender, uint8 permissions) = _approvedSender(actor);

    for (uint256 i=0; i<tokenIds.length; i++) {
      // Run reward collection
      _collect(tokenIds[i], sender, permissions);

      // Set new zone (if allowed; enterZone may throw)
      furballs[tokenIds[i]].zone = uint32(engine.enterZone(tokenIds[i], zone, tokenIds));
    }
  }

  /// @notice Re-dropping loot allows players to pay $FUR to re-roll an inventory slot
  /// @param tokenId The furball in question
  /// @param lootId The lootId in its inventory to re-roll
  function upgrade(
    uint256 tokenId, uint128 lootId, uint8 chances, address actor
  ) external {
    // Attempt upgrade (random chance).
    (address sender, uint8 permissions) = _approvedSender(actor);
    uint128 up = fur.purchaseUpgrade(_baseModifiers(tokenId), sender, permissions, tokenId, lootId, chances);
    if (up != 0) {
      _drop(tokenId, lootId, 1);
      _pickup(tokenId, up);
    }
  }

  /// @notice The LootEngine can directly send loot to a furball!
  /// @dev This allows for gameplay expansion, i.e., new game modes
  /// @param tokenId The furball to gain the loot
  /// @param lootId The loot ID being sent
  function pickup(uint256 tokenId, uint128 lootId) external gameAdmin {
    _pickup(tokenId, lootId);
  }

  /// @notice The LootEngine can cause a furball to drop loot!
  /// @dev This allows for gameplay expansion, i.e., new game modes
  /// @param tokenId The furball
  /// @param lootId The item to drop
  /// @param count the number of that item to drop
  function drop(uint256 tokenId, uint128 lootId, uint8 count) external gameAdmin {
    _drop(tokenId, lootId, count);
  }

  // -----------------------------------------------------------------------------------------------
  // Internal
  // -----------------------------------------------------------------------------------------------

  function _slotNum(uint256 tokenId, uint128 lootId) internal view returns(uint256) {
    for (uint8 i=0; i<furballs[tokenId].inventory.length; i++) {
      if (furballs[tokenId].inventory[i] / 256 == lootId) {
        return i + 1;
      }
    }
    return 0;
  }

  /// @notice Remove an inventory item from a furball
  function _drop(uint256 tokenId, uint128 lootId, uint8 count) internal {
    uint256 slot = _slotNum(tokenId, lootId);
    require(slot > 0 && slot <= uint32(furballs[tokenId].inventory.length), "SLOT");

    slot -= 1;
    uint8 stackSize = uint8(furballs[tokenId].inventory[slot] % 0x100);

    if (count == 0 || count >= stackSize) {
      // Drop entire stack
      uint16 len = uint16(furballs[tokenId].inventory.length);
      if (len > 1) {
        furballs[tokenId].inventory[slot] = furballs[tokenId].inventory[len - 1];
      }
      furballs[tokenId].inventory.pop();
      count = stackSize;
    } else {
      stackSize -= count;
      furballs[tokenId].inventory[slot] = uint256(lootId) * 0x100 + stackSize;
    }

    furballs[tokenId].weight -= count * engine.weightOf(lootId);
    emit Inventory(tokenId, lootId, count);
  }

  /// @notice Internal implementation of adding a single known loot item to a Furball
  function _pickup(uint256 tokenId, uint128 lootId) internal {
    require(lootId > 0, "LOOT");
    uint256 slotNum = _slotNum(tokenId, lootId);
    uint8 stackSize = 1;
    if (slotNum == 0) {
      furballs[tokenId].inventory.push(uint256(lootId) * 0x100 + stackSize);
    } else {
      stackSize += uint8(furballs[tokenId].inventory[slotNum - 1] % 0x100);
      require(stackSize < 0x100, "STACK");
      furballs[tokenId].inventory[slotNum - 1] = uint256(lootId) * 0x100 + stackSize;
    }

    furballs[tokenId].weight += engine.weightOf(lootId);
    emit Inventory(tokenId, lootId, 0);
  }

  /// @notice Calculates full reward modifier stack for a furball in a zone.
  function _rewardModifiers(
    FurLib.Furball memory fb, uint256 tokenId, address ownerContext, uint256 snackData
  ) internal view returns(FurLib.RewardModifiers memory reward) {
    uint16 energy = uint16(FurLib.extractBytes(snackData, FurLib.SNACK_BYTE_ENERGY, 2));
    uint16 happiness = uint16(FurLib.extractBytes(snackData, FurLib.SNACK_BYTE_HAPPINESS, 2));

    bool context = ownerContext != address(0);
    uint32 editionIndex = uint32(tokenId % 0x100);

    reward = FurLib.RewardModifiers(
      uint16(100 + fb.rarity),
      uint16(100 + fb.rarity - (editionIndex < 4 ? (editionIndex * 20) : 80)),
      uint16(100),
      happiness,
      energy,
      context ? fb.zone : 0
    );

    // Engine will consider inventory and team size in zone (17k)
    return engine.modifyReward(
      fb,
      editions[editionIndex].modifyReward(reward, tokenId),
      governance.getAccount(ownerContext),
      context
    );
  }

  /// @notice Common version of _rewardModifiers which excludes contextual data
  function _baseModifiers(uint256 tokenId) internal view returns(FurLib.RewardModifiers memory) {
    return _rewardModifiers(furballs[tokenId], tokenId, address(0), 0);
  }

  /// @notice Ends the current explore/battle and dispenses rewards
  /// @param tokenId The furball
  function _collect(uint256 tokenId, address sender, uint8 permissions) internal {
    FurLib.Furball memory furball = furballs[tokenId];
    address owner = ownerOf(tokenId);

    // The engine is allowed to force furballs into exploration mode
    // This allows it to end a battle early, which will be necessary in PvP
    require(owner == sender || permissions >= FurLib.PERMISSION_ADMIN, "OWN");

    // Scale duration to the time the edition has been live
    if (furball.last == 0) {
      uint64 launchedAt = uint64(editions[tokenId % 0x100].liveAt());
      require(launchedAt > 0 && launchedAt < uint64(block.timestamp), "PRE");
      furball.last = furball.birth > launchedAt ? furball.birth : launchedAt;
    }

    // Calculate modifiers to be used with this collection
    FurLib.RewardModifiers memory mods =
      _rewardModifiers(furball, tokenId, owner, fur.cleanSnacks(tokenId));

    // Reset the collection for this furball
    uint32 duration = uint32(uint64(block.timestamp) - furball.last);
    collect[tokenId].fur = 0;
    collect[tokenId].experience = 0;
    collect[tokenId].levels = 0;

    if (mods.zone >= 0x10000) {
      // Battle zones earn FUR and assign to the owner
      uint32 f = uint32(_calculateReward(duration, FurLib.FUR_PER_INTERVAL, mods.furPercent));
      if (f > 0) {
        fur.earn(owner, f);
        collect[tokenId].fur = f;
      }
    } else {
      // Explore zones earn EXP...
      uint32 exp = uint32(_calculateReward(duration, FurLib.EXP_PER_INTERVAL, mods.expPercent));
      (uint32 totalExp, uint16 levels) = engine.onExperience(furballs[tokenId], owner, exp);

      collect[tokenId].experience = exp;
      collect[tokenId].levels = levels;

      furballs[tokenId].level += levels;
      furballs[tokenId].experience = totalExp;
    }

    // Generate loot and assign to furball
    uint32 interval = uint32(intervalDuration);
    uint128 lootId = engine.dropLoot(duration / interval, mods);
    collect[tokenId].loot = lootId;
    if (lootId > 0) {
      _pickup(tokenId, lootId);
    }

    // Timestamp the last interaction for next cycle.
    furballs[tokenId].last = uint64(block.timestamp);

    // Emit the reward ID for frontend
    uint32 moves = furball.moves + 1;
    furballs[tokenId].moves = moves;
    emit Collection(tokenId, moves);
  }

  /// @notice Mints a new furball
  /// @dev Recursive function; generates randomization seed for the edition
  /// @param to The recipient of the furball
  /// @param nonce A recursive counter to prevent infinite loops
  function _spawn(address to, uint8 editionIndex, uint8 nonce) internal {
    require(nonce < 10, "SUPPLY");
    require(editionIndex < editions.length, "ED");

    IFurballEdition edition = editions[editionIndex];

    // Generate a random furball tokenId; if it fails to be unique, recurse!
    (uint256 tokenId, uint16 rarity) = edition.spawn();
    tokenId += editionIndex;
    if (_exists(tokenId)) return _spawn(to, editionIndex, nonce + 1);

    // Ensure that this wallet has not exceeded its per-edition mint-cap
    uint32 owned = edition.minted(to);
    require(owned < edition.maxMintable(to), "LIMIT");

    // Check the current edition's constraints (caller should have checked costs)
    uint16 cnt = edition.count();
    require(cnt < edition.maxCount(), "MAX");

    // Initialize the memory struct that represents the furball
    furballs[tokenId].number = uint32(totalSupply() + 1);
    furballs[tokenId].count = cnt;
    furballs[tokenId].rarity = rarity;
    furballs[tokenId].birth = uint64(block.timestamp);

    // Finally, mint the token and increment internal counters
    _mint(to, tokenId);

    edition.addCount(to, 1);
  }

  /// @notice Happens each time a furball changes wallets
  /// @dev Keeps track of the furball timestamp
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override {
    super._beforeTokenTransfer(from, to, tokenId);

    // Update internal data states
    furballs[tokenId].trade = uint64(block.timestamp);

    // Delegate other logic to the engine
    engine.onTrade(furballs[tokenId], from, to);
  }

  // -----------------------------------------------------------------------------------------------
  // Game Engine & Moderation
  // -----------------------------------------------------------------------------------------------

  function stats(uint256 tokenId, bool contextual) public view returns(FurLib.FurballStats memory) {
    // Base stats are calculated without team size so this doesn't effect public metadata
    FurLib.Furball memory furball = furballs[tokenId];
    FurLib.RewardModifiers memory mods =
      _rewardModifiers(
        furball,
        tokenId,
        contextual ? ownerOf(tokenId) : address(0),
        contextual ? fur.snackEffects(tokenId) : 0
      );

    return FurLib.FurballStats(
      uint16(_calculateReward(intervalDuration, FurLib.EXP_PER_INTERVAL, mods.expPercent)),
      uint16(_calculateReward(intervalDuration, FurLib.FUR_PER_INTERVAL, mods.furPercent)),
      mods,
      furball,
      fur.snacks(tokenId)
    );
  }

  /// @notice This utility function is useful because it force-casts arguments to uint256
  function _calculateReward(
    uint256 duration, uint256 perInterval, uint256 percentBoost
  ) internal view returns(uint256) {
    uint256 interval = intervalDuration;
    return (duration * percentBoost * perInterval) / (100 * interval);
  }

  // -----------------------------------------------------------------------------------------------
  // Public Views/Accessors (for outside world)
  // -----------------------------------------------------------------------------------------------

  /// @notice Provides the OpenSea storefront
  /// @dev see https://docs.opensea.io/docs/contract-level-metadata
  function contractURI() public view returns (string memory) {
    return governance.metaURI();
  }

  /// @notice Provides the on-chain Furball asset
  /// @dev see https://docs.opensea.io/docs/metadata-standards
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId));
    return string(abi.encodePacked("data:application/json;base64,", FurLib.encode(abi.encodePacked(
      editions[tokenId % 0x100].tokenMetadata(
        engine.attributesMetadata(tokenId),
        tokenId,
        furballs[tokenId].number
      )
    ))));
  }

  // -----------------------------------------------------------------------------------------------
  // OpenSea Proxy
  // -----------------------------------------------------------------------------------------------

  /// @notice Whitelisting the proxy registies for secondary market transactions
  /// @dev See OpenSea ERC721Tradable
  function isApprovedForAll(address owner, address operator)
      override
      public
      view
      returns (bool)
  {
    return engine.canProxyTrades(owner, operator) || super.isApprovedForAll(owner, operator);
  }

  /// @notice This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
  /// @dev See OpenSea ContentMixin
  function _msgSender()
    internal
    override
    view
    returns (address sender)
  {
    if (msg.sender == address(this)) {
      bytes memory array = msg.data;
      uint256 index = msg.data.length;
      assembly {
        // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
        sender := and(
          mload(add(array, index)),
          0xffffffffffffffffffffffffffffffffffffffff
        )
      }
    } else {
      sender = msg.sender;
    }
    return sender;
  }

  // -----------------------------------------------------------------------------------------------
  // Configuration / Admin
  // -----------------------------------------------------------------------------------------------

  function setFur(address furAddress) external onlyAdmin {
    fur = Fur(furAddress);
  }

  function setFurgreement(address furgAddress) external onlyAdmin {
    furgreement = Furgreement(furgAddress);
  }

  function setGovernance(address addr) public onlyAdmin {
    governance = Governance(payable(addr));
  }

  function setEngine(address addr) public onlyAdmin {
    engine = ILootEngine(addr);
  }

  function addEdition(address addr, uint8 idx) public onlyAdmin {
    if (idx >= editions.length) {
      editions.push(IFurballEdition(addr));
    } else {
      editions[idx] = IFurballEdition(addr);
    }
  }

  function _isReady() internal view returns(bool) {
    return address(engine) != address(0) && editions.length > 0
      && address(fur) != address(0) && address(governance) != address(0);
  }

  /// @notice Handles auth of msg.sender against cheating and/or banning.
  /// @dev Pass nonzero sender to act as a proxy against the furgreement
  function _approvedSender(address sender) internal view returns (address, uint8) {
    // No sender (for gameplay) is approved until the necessary parts are online
    require(_isReady(), "!RDY");

    if (sender != address(0) && sender != msg.sender) {
      // Only the furgreement may request a proxied sender.
      require(msg.sender == address(furgreement), "PROXY");
    } else {
      // Zero input triggers sender calculation from msg args
      sender = _msgSender();
    }

    // All senders are validated thru engine logic.
    uint8 permissions = uint8(engine.approveSender(sender));

    // Zero-permissions indicate unauthorized.
    require(permissions > 0, "PLR");

    return (sender, permissions);
  }

  modifier gameAdmin() {
    (address sender, uint8 permissions) = _approvedSender(address(0));
    require(permissions >= FurLib.PERMISSION_ADMIN, "GAME");
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "../utils/FurLib.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/// @title IFurballEdition
/// @author LFG Gaming LLC
/// @notice Interface for a single edition within Furballs
interface IFurballEdition is IERC165 {
  function index() external view returns(uint8);
  function count() external view returns(uint16);
  function maxCount() external view returns (uint16); // total max count in this edition
  function addCount(address to, uint16 amount) external returns(bool);

  function liveAt() external view returns(uint64);
  function minted(address addr) external view returns(uint16);
  function maxMintable(address addr) external view returns(uint16);
  function maxAdoptable() external view returns (uint16); // how many can be adopted, out of the max?
  function purchaseFur() external view returns(uint256); // amount of FUR for buying

  function spawn() external returns (uint256, uint16);

  /// @notice Calculates the effects of the loot in a Furball's inventory
  function modifyReward(
    FurLib.RewardModifiers memory modifiers, uint256 tokenId
  ) external view returns(FurLib.RewardModifiers memory);

  /// @notice Renders a JSON object for tokenURI
  function tokenMetadata(
    bytes memory attributes, uint256 tokenId, uint256 number
  ) external view returns(bytes memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "../editions/IFurballEdition.sol";
import "../utils/FurLib.sol";

/// @title ILootEngine
/// @author LFG Gaming LLC
/// @notice The loot engine is patchable by replacing the Furballs' engine with a new version
interface ILootEngine is IERC165 {
  /// @notice When a Furball comes back from exploration, potentially give it some loot.
  function dropLoot(uint32 intervals, FurLib.RewardModifiers memory mods) external returns(uint128);

  /// @notice Players can pay to re-roll their loot drop on a Furball
  function upgradeLoot(
    FurLib.RewardModifiers memory modifiers,
    address owner,
    uint128 lootId,
    uint8 chances
  ) external returns(uint128);

  /// @notice Some zones may have preconditions
  function enterZone(uint256 tokenId, uint32 zone, uint256[] memory team) external returns(uint256);

  /// @notice Calculates the effects of the loot in a Furball's inventory
  function modifyReward(
    FurLib.Furball memory furball,
    FurLib.RewardModifiers memory baseModifiers,
    FurLib.Account memory account,
    bool contextual
  ) external view returns(FurLib.RewardModifiers memory);

  /// @notice Loot can have different weight to help prevent over-powering a furball
  function weightOf(uint128 lootId) external pure returns (uint16);

  /// @notice JSON object for displaying metadata on OpenSea, etc.
  function attributesMetadata(uint256 tokenId) external view returns(bytes memory);

  /// @notice Get a potential snack for the furball by its ID
  function getSnack(uint32 snack) external view returns(FurLib.Snack memory);

  /// @notice Proxy registries are allowed to act as 3rd party trading platforms
  function canProxyTrades(address owner, address operator) external view returns(bool);

  /// @notice Authorization mechanics are upgradeable to account for security patches
  function approveSender(address sender) external view returns(uint);

  /// @notice Called when a Furball is traded to update delegate logic
  function onTrade(
    FurLib.Furball memory furball, address from, address to
  ) external;

  /// @notice Handles experience gain during collection
  function onExperience(
    FurLib.Furball memory furball, address owner, uint32 experience
  ) external returns(uint32 totalExp, uint16 level);

  /// @notice Gets called at the beginning of token render; could add underlaid artwork
  function render(uint256 tokenId) external view returns(string memory);

  /// @notice The loot engine can add descriptions to furballs metadata
  function furballDescription(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./LootEngine.sol";

/// @title EngineA
/// @author LFG Gaming LLC
/// @notice Concrete implementation of LootEngine
contract EngineA is LootEngine {
  constructor(address furballs, address tradeProxy, address companyProxy)
    LootEngine(furballs, tradeProxy, companyProxy) { }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/// @title FurLib
/// @author LFG Gaming LLC
/// @notice Utilities for Furballs
/// @dev Each of the structs are designed to fit within 256
library FurLib {
  // Metadata about a wallet.
  struct Account {
    uint64 created;       // First time this account received a furball
    uint32 numFurballs;   // Number of furballs it currently holds
    uint32 maxFurballs;   // Max it has ever held
    uint16 maxLevel;      // Max level of any furball it currently holds
    uint16 reputation;    // Value assigned by moderators to boost standing
    uint16 standing;      // Computed current standing
    uint8 permissions;    // 0 = user, 1 = moderator, 2 = admin, 3 = owner
  }

  // Key data structure given to clients for high-level furball access (furballs.stats)
  struct FurballStats {
    uint16 expRate;
    uint16 furRate;
    RewardModifiers modifiers;
    Furball definition;
    Snack[] snacks;
  }

  // The response from a single play session indicating rewards
  struct Rewards {
    uint16 levels;
    uint32 experience;
    uint32 fur;
    uint128 loot;
  }

  // Stored data structure in Furballs master contract which keeps track of mutable data
  struct Furball {
    uint32 number;        // Overall number, starting with 1
    uint16 count;         // Index within the collection
    uint16 rarity;        // Total rarity score for later boosts
    uint32 experience;    // EXP
    uint32 zone;          // When exploring, the zone number. Otherwise, battling.
    uint16 level;         // Current EXP => level; can change based on level up during collect
    uint16 weight;        // Total weight (number of items in inventory)
    uint64 birth;         // Timestamp of furball creation
    uint64 trade;         // Timestamp of last furball trading wallets
    uint64 last;          // Timestamp of last action (battle/explore)
    uint32 moves;         // The size of the collection array for this furball, which is move num.
    uint256[] inventory;  // IDs of items in inventory
  }

  // A runtime-calculated set of properties that can affect Furball production during collect()
  struct RewardModifiers {
    uint16 expPercent;
    uint16 furPercent;
    uint16 luckPercent;
    uint16 happinessPoints;
    uint16 energyPoints;
    uint32 zone;
  }

  // For sale via loot engine.
  struct Snack {
    uint32 snackId;       // Unique ID
    uint32 duration;      // How long it lasts, !expressed in intervals!
    uint16 furCost;       // How much FUR
    uint16 happiness;     // +happiness bost points
    uint16 energy;        // +energy boost points
    uint16 count;         // How many in stack?
    uint64 fed;           // When was it fed (if it is active)?
  }

  // Input to the feed() function for multi-play
  struct Feeding {
    uint256 tokenId;
    uint32 snackId;
    uint16 count;
  }

  uint32 public constant Max32 = type(uint32).max;

  uint8 public constant PERMISSION_USER = 1;
  uint8 public constant PERMISSION_MODERATOR = 2;
  uint8 public constant PERMISSION_ADMIN = 4;
  uint8 public constant PERMISSION_OWNER = 5;
  uint8 public constant PERMISSION_CONTRACT = 0x10;

  uint32 public constant EXP_PER_INTERVAL = 500;
  uint32 public constant FUR_PER_INTERVAL = 100;

  uint8 public constant LOOT_BYTE_STAT = 1;
  uint8 public constant LOOT_BYTE_RARITY = 2;

  uint8 public constant SNACK_BYTE_ENERGY = 0;
  uint8 public constant SNACK_BYTE_HAPPINESS = 2;

  uint256 public constant OnePercent = 1000;
  uint256 public constant OneHundredPercent = 100000;

  /// @notice Shortcut for equations that saves gas
  /// @dev The expression (0x100 ** byteNum) is expensive; this covers byte packing for editions.
  function bytePower(uint8 byteNum) internal pure returns (uint256) {
    if (byteNum == 0) return 0x1;
    if (byteNum == 1) return 0x100;
    if (byteNum == 2) return 0x10000;
    if (byteNum == 3) return 0x1000000;
    if (byteNum == 4) return 0x100000000;
    if (byteNum == 5) return 0x10000000000;
    if (byteNum == 6) return 0x1000000000000;
    if (byteNum == 7) return 0x100000000000000;
    if (byteNum == 8) return 0x10000000000000000;
    if (byteNum == 9) return 0x1000000000000000000;
    if (byteNum == 10) return 0x100000000000000000000;
    if (byteNum == 11) return 0x10000000000000000000000;
    if (byteNum == 12) return 0x1000000000000000000000000;
    return (0x100 ** byteNum);
  }

  /// @notice Helper to get a number of bytes from a value
  function extractBytes(uint value, uint8 startAt, uint8 numBytes) internal pure returns (uint) {
    return (value / bytePower(startAt)) % bytePower(numBytes);
  }

  /// @notice Converts exp into a sqrt-able number.
  function expToLevel(uint32 exp, uint32 maxExp) internal pure returns(uint256) {
    exp = exp > maxExp ? maxExp : exp;
    return sqrt(exp < 100 ? 0 : ((exp + exp - 100) / 100));
  }

  /// @notice Simple square root function using the Babylonian method
  function sqrt(uint32 x) internal pure returns(uint256) {
    if (x < 1) return 0;
    if (x < 4) return 1;
    uint z = (x + 1) / 2;
    uint y = x;
    while (z < y) {
      y = z;
      z = (x / z + z) / 2;
    }
    return y;
  }

  /// @notice Convert bytes into a hex str, e.g., an address str
  function bytesHex(bytes memory data) internal pure returns(string memory) {
    bytes memory alphabet = "0123456789abcdef";

    bytes memory str = new bytes(data.length * 2);
    for (uint i = 0; i < data.length; i++) {
        str[i*2] = alphabet[uint(uint8(data[i] >> 4))];
        str[1 + i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
    }
    return string(str);
  }

  function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
    if (_i == 0) {
      return "0";
    }
    uint j = _i;
    uint len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint k = len;
    while (_i != 0) {
      k = k-1;
      uint8 temp = (48 + uint8(_i - _i / 10 * 10));
      bytes1 b1 = bytes1(temp);
      bstr[k] = b1;
      _i /= 10;
    }
    return string(bstr);
  }

  function encode(bytes memory data) internal pure returns (string memory) {
    if (data.length == 0) return "";

    string memory table = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    uint256 encodedLen = 4 * ((data.length + 2) / 3);
    string memory result = new string(encodedLen + 32);

    assembly {
      mstore(result, encodedLen)
      let tablePtr := add(table, 1)

      let dataPtr := data
      let endPtr := add(dataPtr, mload(data))
      let resultPtr := add(result, 32)

      for {

      } lt(dataPtr, endPtr) {

      } {
        dataPtr := add(dataPtr, 3)
        let input := mload(dataPtr)
        mstore(
          resultPtr,
          shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
        )
        resultPtr := add(resultPtr, 1)
        mstore(
          resultPtr,
          shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
        )
        resultPtr := add(resultPtr, 1)
        mstore(
          resultPtr,
          shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
        )
        resultPtr := add(resultPtr, 1)
        mstore(
          resultPtr,
          shl(248, mload(add(tablePtr, and(input, 0x3F))))
        )
        resultPtr := add(resultPtr, 1)
      }

      switch mod(mload(data), 3)
      case 1 {
        mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
      }
      case 2 {
        mstore(sub(resultPtr, 1), shl(248, 0x3d))
      }
    }

    return result;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./FurLib.sol";

/// @title FurLib
/// @author LFG Gaming LLC
/// @notice Public utility library around game-specific equations and constants
library FurDefs {
  function rarityName(uint8 rarity) internal pure returns(string memory) {
    if (rarity == 0) return "Common";
    if (rarity == 1) return "Elite";
    if (rarity == 2) return "Mythic";
    if (rarity == 3) return "Legendary";
    return "Ultimate";
  }

  function raritySuffix(uint8 rarity) internal pure returns(string memory) {
    return rarity == 0 ? "" : string(abi.encodePacked(" (", rarityName(rarity), ")"));
  }

  function renderPoints(uint64 ptr, bytes memory data) internal pure returns (uint64, bytes memory) {
    uint8 cnt = uint8(data[ptr]);
    ptr++;
    bytes memory points = "";
    for (uint256 i=0; i<cnt; i++) {
      uint16 x = uint8(data[ptr]) * 256 + uint8(data[ptr + 1]);
      uint16 y = uint8(data[ptr + 2]) * 256 + uint8(data[ptr + 3]);
      points = abi.encodePacked(points, FurLib.uint2str(x), ',', FurLib.uint2str(y), i == (cnt - 1) ? '': ' ');
      ptr += 4;
    }
    return (ptr, abi.encodePacked('points="', points, '" '));
  }

  function renderTransform(uint64 ptr, bytes memory data) internal pure returns (uint64, bytes memory) {
    uint8 len = uint8(data[ptr]);
    ptr++;
    bytes memory points = "";
    for (uint256 i=0; i<len; i++) {
      bytes memory point = "";
      (ptr, point) =  unpackFloat(ptr, data);
      points = i == (len - 1) ? abi.encodePacked(points, point) : abi.encodePacked(points, point, ' ');
    }
    return (ptr, abi.encodePacked('transform="matrix(', points, ')" '));
  }

  function renderDisplay(uint64 ptr, bytes memory data) internal pure returns (uint64, bytes memory) {
    string[2] memory vals = ['inline', 'none'];
    return (ptr + 1, abi.encodePacked('display="', vals[uint8(data[ptr])], '" '));
  }

  function renderFloat(uint64 ptr, bytes memory data) internal pure returns (uint64, bytes memory) {
    uint8 propType = uint8(data[ptr]);
    string[2] memory floatMap = ['opacity', 'offset'];
    bytes memory floatVal = "";
    (ptr, floatVal) =  unpackFloat(ptr + 1, data);
    return (ptr, abi.encodePacked(floatMap[propType], '="', floatVal,'" '));
  }

  function  unpackFloat(uint64 ptr, bytes memory data) internal pure returns(uint64, bytes memory) {
    uint8 decimals = uint8(data[ptr]);
    ptr++;
    if (decimals == 0) return (ptr, '0');
    uint8 hi = decimals / 16;
    uint16 wholeNum = 0;
    decimals = decimals % 16;
    if (hi >= 10) {
      wholeNum = uint16(uint8(data[ptr]) * 256 + uint8(data[ptr + 1]));
      ptr += 2;
    } else if (hi >= 8) {
      wholeNum = uint16(uint8(data[ptr]));
      ptr++;
    }
    if (decimals == 0) return (ptr, abi.encodePacked(hi % 2 == 1 ? '-' : '', FurLib.uint2str(wholeNum)));

    bytes memory remainder = new bytes(decimals);
    for (uint8 d=0; d<decimals; d+=2) {
      remainder[d] = bytes1(48 + uint8(data[ptr] >> 4));
      if ((d + 1) < decimals) {
        remainder[d+1] = bytes1(48 + uint8(data[ptr] & 0x0f));
      }
      ptr++;
    }
    return (ptr, abi.encodePacked(hi % 2 == 1 ? '-' : '', FurLib.uint2str(wholeNum), '.', remainder));
  }

  function renderInt(uint64 ptr, bytes memory data) internal pure returns (uint64, bytes memory) {
    uint8 propType = uint8(data[ptr]);
    string[13] memory intMap = ['cx', 'cy', 'x', 'x1', 'x2', 'y', 'y1', 'y2', 'r', 'rx', 'ry', 'width', 'height'];
    uint16 val = uint16(uint8(data[ptr + 1]) * 256) + uint8(data[ptr + 2]);
    if (val >= 0x8000) {
      return (ptr + 3, abi.encodePacked(intMap[propType], '="-', FurLib.uint2str(uint32(0x10000 - val)),'" '));
    }
    return (ptr + 3, abi.encodePacked(intMap[propType], '="', FurLib.uint2str(val),'" '));
  }

  function renderStr(uint64 ptr, bytes memory data) internal pure returns(uint64, bytes memory) {
    string[4] memory strMap = ['id', 'enable-background', 'gradientUnits', 'gradientTransform'];
    uint8 t = uint8(data[ptr]);
    require(t < 4, 'STR');
    bytes memory str = "";
    (ptr, str) =  unpackStr(ptr + 1, data);
    return (ptr, abi.encodePacked(strMap[t], '="', str, '" '));
  }

  function unpackStr(uint64 ptr, bytes memory data) internal pure returns(uint64, bytes memory) {
    uint8 len = uint8(data[ptr]);
    bytes memory str = bytes(new string(len));
    for (uint8 i=0; i<len; i++) {
      str[i] = data[ptr + 1 + i];
    }
    return (ptr + 1 + len, str);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "../Furballs.sol";
import "./FurLib.sol";

/// @title FurProxy
/// @author LFG Gaming LLC
/// @notice Manages a link from a sub-contract back to the master Furballs contract
/// @dev Provides permissions by means of proxy
abstract contract FurProxy {
  Furballs public furballs;

  constructor(address furballsAddress) {
    furballs = Furballs(furballsAddress);
  }

  /// @notice Allow upgrading contract links
  function setFurballs(address addr) external onlyOwner {
    furballs = Furballs(addr);
  }

  /// @notice Proxied from permissions lookup
  modifier onlyOwner() {
    require(_permissions(msg.sender) >= FurLib.PERMISSION_OWNER, "OWN");
    _;
  }

  /// @notice Permission modifier for moderators (covers owner)
  modifier gameAdmin() {
    require(_permissions(msg.sender) >= FurLib.PERMISSION_ADMIN, "GAME");
    _;
  }

  /// @notice Permission modifier for moderators (covers admin)
  modifier gameModerators() {
    require(_permissions(msg.sender) >= FurLib.PERMISSION_MODERATOR, "MOD");
    _;
  }

  modifier onlyFurballs() {
    require(msg.sender == address(furballs), "FBL");
    _;
  }

  /// @notice Generalized permissions flag for a given address
  function _permissions(address addr) internal view returns (uint8) {
    // User permissions will return "zero" quickly if this didn't come from a wallet.
    uint8 permissions = _userPermissions(addr);
    if (permissions > 0) return permissions;

    if (addr == address(furballs) ||
      addr == address(furballs.engine()) ||
      addr == address(furballs.furgreement()) ||
      addr == address(furballs.governance()) ||
      addr == address(furballs.fur())
    ) {
      return FurLib.PERMISSION_CONTRACT;
    }
    return 0;
  }

  function _userPermissions(address addr) internal view returns (uint8) {
    // Invalid addresses include contracts an non-wallet interactions, which have no permissions
    if (addr == address(0)) return 0;
    uint256 size;
    assembly { size := extcodesize(addr) }
    if (addr != tx.origin || size != 0) return 0;

    if (addr == furballs.owner()) return FurLib.PERMISSION_OWNER;
    if (furballs.isAdmin(addr)) return FurLib.PERMISSION_ADMIN;
    if (furballs.isModerator(addr)) return FurLib.PERMISSION_MODERATOR;
    return FurLib.PERMISSION_USER;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Moderated
/// @author LFG Gaming LLC
/// @notice Administration & moderation permissions utilities
abstract contract Moderated is Ownable {
  mapping (address => bool) public admins;
  mapping (address => bool) public moderators;

  function setAdmin(address addr, bool set) external onlyOwner {
    require(addr != address(0));
    admins[addr] = set;
  }

  /// @notice Moderated ownables may not be renounced (only transferred)
  function renounceOwnership() public override onlyOwner {
    require(false, 'OWN');
  }

  function setModerator(address mod, bool set) external onlyAdmin {
    require(mod != address(0));
    moderators[mod] = set;
  }

  function isAdmin(address addr) public virtual view returns(bool) {
    return owner() == addr || admins[addr];
  }

  function isModerator(address addr) public virtual view returns(bool) {
    return isAdmin(addr) || moderators[addr];
  }

  modifier onlyModerators() {
    require(isModerator(msg.sender), 'MOD');
    _;
  }

  modifier onlyAdmin() {
    require(isAdmin(msg.sender), 'ADMIN');
    _;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./Stakeholders.sol";
import "./Community.sol";
import "./FurLib.sol";

/// @title Governance
/// @author LFG Gaming LLC
/// @notice Meta-tracker for Furballs; looks at the ecosystem (metadata, wallet counts, etc.)
/// @dev Shares is an ERC20; stakeholders is a payable
contract Governance is Stakeholders {
  /// @notice Where transaction fees are deposited
  address payable public treasury;

  /// @notice How much is the transaction fee, in basis points?
  uint16 public transactionFee = 250;

  /// @notice Used in contractURI for Furballs itself.
  string public metaName = "Furballs.com (Official)";

  /// @notice Used in contractURI for Furballs itself.
  string public metaDescription =
    "Furballs are entirely on-chain, with a full interactive gameplay experience at Furballs.com. "
    "There are 88 billion+ possible furball combinations in the first edition, each with their own special abilities"
    "... but only thousands minted per edition. Each edition has new artwork, game modes, and surprises.";

  // Tracks the MAX which are ever owned by a given address.
  mapping(address => FurLib.Account) private _account;

  // List of all addresses which have ever owned a furball.
  address[] public accounts;

  Community public community;

  constructor(address furballsAddress) Stakeholders(furballsAddress) {
    treasury = payable(this);
  }

  /// @notice Generic form of contractURI for on-chain packing.
  /// @dev Proxied from Furballs, but not called contractURI so as to not imply this ERC20 is tradeable.
  function metaURI() public view returns(string memory) {
    return string(abi.encodePacked("data:application/json;base64,", FurLib.encode(abi.encodePacked(
      '{"name": "', metaName,'", "description": "', metaDescription,'"',
      ', "external_link": "https://furballs.com"',
      ', "image": "https://furballs.com/images/pfp.png"',
      ', "seller_fee_basis_points": ', FurLib.uint2str(transactionFee),
      ', "fee_recipient": "0x', FurLib.bytesHex(abi.encodePacked(treasury)), '"}'
    ))));
  }

  /// @notice total count of accounts
  function numAccounts() external view returns(uint256) {
    return accounts.length;
  }

  /// @notice Update metadata for main contractURI
  function setMeta(string memory nameVal, string memory descVal) external gameAdmin {
    metaName = nameVal;
    metaDescription = descVal;
  }

  /// @notice The transaction fee can be adjusted
  function setTransactionFee(uint16 basisPoints) external gameAdmin {
    transactionFee = basisPoints;
  }

  /// @notice The treasury can be changed in only rare circumstances.
  function setTreasury(address treasuryAddress) external onlyOwner {
    treasury = payable(treasuryAddress);
  }

  /// @notice The treasury can be changed in only rare circumstances.
  function setCommunity(address communityAddress) external onlyOwner {
    community = Community(communityAddress);
  }

  /// @notice public accessor updates permissions
  function getAccount(address addr) external view returns (FurLib.Account memory) {
    FurLib.Account memory acc = _account[addr];
    acc.permissions = _userPermissions(addr);
    return acc;
  }

  /// @notice Public function allowing manual update of standings
  function updateStandings(address[] memory addrs) public {
    for (uint32 i=0; i<addrs.length; i++) {
      _updateStanding(addrs[i]);
    }
  }

  /// @notice Moderators may assign reputation to accounts
  function setReputation(address addr, uint16 rep) external gameModerators {
    _account[addr].reputation = rep;
  }

  /// @notice Tracks the max level an account has *obtained*
  function updateMaxLevel(address addr, uint16 level) external gameAdmin {
    if (_account[addr].maxLevel >= level) return;
    _account[addr].maxLevel = level;
    _updateStanding(addr);
  }

  /// @notice Recompute max stats for the account.
  function updateAccount(address addr, uint256 numFurballs) external gameAdmin {
    FurLib.Account memory acc = _account[addr];

    // Recompute account permissions for internal rewards
    uint8 permissions = _userPermissions(addr);
    if (permissions != acc.permissions) _account[addr].permissions = permissions;

    // New account created?
    if (acc.created == 0) _account[addr].created = uint64(block.timestamp);
    if (acc.numFurballs != numFurballs) _account[addr].numFurballs = uint32(numFurballs);

    // New max furballs?
    if (numFurballs > acc.maxFurballs) {
      if (acc.maxFurballs == 0) accounts.push(addr);
      _account[addr].maxFurballs = uint32(numFurballs);
    }
    _updateStanding(addr);
  }

  /// @notice Re-computes the account's standing
  function _updateStanding(address addr) internal {
    uint256 standing = 0;
    FurLib.Account memory acc = _account[addr];

    if (address(community) != address(0)) {
      // If community is patched in later...
      standing = community.update(acc, addr);
    } else {
      // Default computation of standing
      uint32 num = acc.numFurballs;
      if (num > 0) {
        standing = num * 10 + acc.maxLevel + acc.reputation;
      }
    }

    _account[addr].standing = uint16(standing);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Furballs.sol";
import "./editions/IFurballEdition.sol";
import "./utils/FurProxy.sol";

/// @title Fur
/// @author LFG Gaming LLC
/// @notice Utility token for in-game rewards in Furballs
contract Fur is ERC20, FurProxy {
  // n.b., this contract has some unusual tight-coupling between FUR and Furballs
  // Simple reason: this contract had more space, and is the only other allowed to know about ownership
  // Thus it serves as a sort of shop meta-store for Furballs

  // tokenId => mapping of fed _snacks
  mapping(uint256 => FurLib.Snack[]) public _snacks;

  // Internal cache for speed.
  uint256 private _intervalDuration;

  constructor(address furballsAddress) FurProxy(furballsAddress) ERC20("Fur", "FUR") {
    _intervalDuration = furballs.intervalDuration();
  }

  // -----------------------------------------------------------------------------------------------
  // Public
  // -----------------------------------------------------------------------------------------------

  /// @notice Returns the snacks currently applied to a Furball
  function snacks(uint256 tokenId) external view returns(FurLib.Snack[] memory) {
    return _snacks[tokenId];
  }

  /// @notice Write-function to cleanup the snacks for a token (remove expired)
  function cleanSnacks(uint256 tokenId) public returns (uint256) {
    if (_snacks[tokenId].length == 0) return 0;
    return _cleanSnack(tokenId, 0);
  }

  /// @notice The public accessor calculates the snack boosts
  function snackEffects(uint256 tokenId) external view returns(uint256) {
    uint16 hap = 0;
    uint16 en = 0;

    for (uint32 i=0; i<_snacks[tokenId].length && i <= FurLib.Max32; i++) {
      uint256 remaining = _snackTimeRemaning(_snacks[tokenId][i]);
      if (remaining > 0) {
        hap += _snacks[tokenId][i].happiness;
        en += _snacks[tokenId][i].energy;
      }
    }

    return (hap * 0x10000) + (en);
  }

  // -----------------------------------------------------------------------------------------------
  // GameAdmin
  // -----------------------------------------------------------------------------------------------

  /// @notice FUR can only be minted by furballs doing battle.
  function earn(address addr, uint256 amount) external gameAdmin {
    if (amount == 0) return;
    _mint(addr, amount);
  }

  /// @notice FUR can be spent by Furballs, or by the LootEngine (shopping, in the future)
  function spend(address addr, uint256 amount) external gameAdmin {
    _burn(addr, amount);
  }

  /// @notice Pay any necessary fees to mint a furball
  /// @dev Delegated logic from Furballs;
  function purchaseMint(
    address from, uint8 permissions, address to, IFurballEdition edition
  ) external gameAdmin returns (bool) {
    require(edition.maxMintable(to) > 0, "LIVE");
    uint32 cnt = edition.count();

    uint32 adoptable = edition.maxAdoptable();
    bool requiresPurchase = cnt >= adoptable;

    if (requiresPurchase) {
      // _gift will throw if cannot gift or cannot afford cost
      _gift(from, permissions, to, edition.purchaseFur());
    }
    return requiresPurchase;
  }

  /// @notice Attempts to purchase an upgrade for a loot item
  /// @dev Delegated logic from Furballs
  function purchaseUpgrade(
    FurLib.RewardModifiers memory modifiers,
    address from, uint8 permissions, uint256 tokenId, uint128 lootId, uint8 chances
  ) external gameAdmin returns(uint128) {
    address owner = furballs.ownerOf(tokenId);

    // _gift will throw if cannot gift or cannot afford cost
    _gift(from, permissions, owner, 500 * uint256(chances));

    return furballs.engine().upgradeLoot(modifiers, owner, lootId, chances);
  }

  /// @notice Attempts to purchase a snack using templates found in the engine
  /// @dev Delegated logic from Furballs
  function purchaseSnack(
    address from, uint8 permissions, uint256 tokenId, uint32 snackId, uint16 count
  ) external gameAdmin {
    FurLib.Snack memory snack = furballs.engine().getSnack(snackId);
    require(snack.count > 0, "COUNT");
    require(snack.fed == 0, "FED");

    // _gift will throw if cannot gift or cannot afford costQ
    _gift(from, permissions, furballs.ownerOf(tokenId), snack.furCost * count);

    uint256 snackData = _cleanSnack(tokenId, snack.snackId);
    uint32 existingSnackNumber = uint32(snackData / 0x100000000);
    snack.count *= count;
    if (existingSnackNumber > 0) {
      // Adding count effectively adds duration to the active snack
      _snacks[tokenId][existingSnackNumber - 1].count += snack.count;
    } else {
      // A new snack just gets pushed onto the array
      snack.fed = uint64(block.timestamp);
      _snacks[tokenId].push(snack);
    }
  }

  // -----------------------------------------------------------------------------------------------
  // Internal
  // -----------------------------------------------------------------------------------------------

  /// @notice Both removes inactive _snacks from a token and searches for a specific snack Id index
  /// @dev Both at once saves some size & ensures that the _snacks are frequently cleaned.
  /// @return The index+1 of the existing snack
  function _cleanSnack(uint256 tokenId, uint32 snackId) internal returns(uint256) {
    uint32 ret = 0;
    uint16 hap = 0;
    uint16 en = 0;
    for (uint32 i=1; i<=_snacks[tokenId].length && i <= FurLib.Max32; i++) {
      FurLib.Snack memory snack = _snacks[tokenId][i-1];
      // Has the snack transitioned from active to inactive?
      if (_snackTimeRemaning(snack) == 0) {
        if (_snacks[tokenId].length > 1) {
          _snacks[tokenId][i-1] = _snacks[tokenId][_snacks[tokenId].length - 1];
        }
        _snacks[tokenId].pop();
        i--; // Repeat this idx
        continue;
      }
      hap += snack.happiness;
      en += snack.energy;
      if (snackId != 0 && snack.snackId == snackId) {
        ret = i;
      }
    }
    return (ret * 0x100000000) + (hap * 0x10000) + (en);
  }

  /// @notice Check if the snack is active; returns 0 if inactive, otherwise the duration
  function _snackTimeRemaning(FurLib.Snack memory snack) internal view returns(uint256) {
    if (snack.fed == 0) return 0;
    uint256 expiresAt = uint256(snack.fed + (snack.count * snack.duration * _intervalDuration));
    return expiresAt <= block.timestamp ? 0 : (expiresAt - block.timestamp);
  }

  /// @notice Enforces (requires) only admins/game may give gifts
  /// @param to Whom is this being sent to?
  /// @return If this is a gift or not.
  function _gift(address from, uint8 permissions, address to, uint256 furCost) internal returns(bool) {
    bool isGift = to != from;

    // Only admins or game engine can send gifts (to != self), which are always free.
    require(!isGift || permissions >= FurLib.PERMISSION_ADMIN, "GIFT");

    if (!isGift && furCost > 0) {
      _burn(from, furCost);
    }

    return isGift;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./Furballs.sol";
import "./utils/FurProxy.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

/// @title Furballs
/// @author LFG Gaming LLC
/// @notice Has permissions to act as a proxy to the Furballs contract
/// @dev https://soliditydeveloper.com/ecrecover
contract Furgreement is EIP712, FurProxy {
  mapping(address => uint256) private nonces;

  address[] public addressQueue;

  mapping(address => PlayMove) public pendingMoves;

  // A "move to be made" in the sig queue
  struct PlayMove {
    uint32 zone;
    uint256[] tokenIds;
  }

  constructor(address furballsAddress) EIP712("Furgreement", "1") FurProxy(furballsAddress) { }

  /// @notice Proxy playMany to Furballs contract
  function playFromSignature(
    bytes memory signature,
    address owner,
    PlayMove memory move,
    uint256 deadline
  ) external {
    bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
      keccak256("playMany(address owner,PlayMove memory move,uint256 nonce,uint256 deadline)"),
      owner,
      move,
      nonces[owner],
      deadline
    )));

    address signer = ECDSA.recover(digest, signature);
    require(signer == owner, "playMany: invalid signature");
    require(signer != address(0), "ECDSA: invalid signature");

    require(block.timestamp < deadline, "playMany: signed transaction expired");
    nonces[owner]++;

    if (pendingMoves[owner].tokenIds.length == 0) {
      addressQueue.push(owner);
    }
    pendingMoves[owner] = move;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
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

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
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

import "../IERC721.sol";

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./ILootEngine.sol";
import "../editions/IFurballEdition.sol";
import "../Furballs.sol";
import "../utils/FurLib.sol";
import "../utils/FurProxy.sol";
import "../utils/ProxyRegistry.sol";
import "../utils/Dice.sol";
import "../utils/Governance.sol";
import "../utils/MetaData.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/// @title LootEngine
/// @author LFG Gaming LLC
/// @notice Base implementation of the loot engine
abstract contract LootEngine is ERC165, ILootEngine, Dice, FurProxy {
  ProxyRegistry private _proxies;

  // An address which may act on behalf of the owner (company)
  address public companyWalletProxy;

  // snackId to "definition" of the snack
  mapping(uint32 => FurLib.Snack) private _snacks;

  uint32 maxExperience = 2010000;

  constructor(
    address furballsAddress, address tradeProxy, address companyProxy
  ) FurProxy(furballsAddress) {
    _proxies = ProxyRegistry(tradeProxy);
    companyWalletProxy = companyProxy;

    _defineSnack(0x100, 24    ,  250, 15, 0);
    _defineSnack(0x200, 24 * 3,  750, 20, 0);
    _defineSnack(0x300, 24 * 7, 1500, 25, 0);
  }

  /// @notice Allows admins to configure the snack store.
  function setSnack(
    uint32 snackId, uint32 duration, uint16 furCost, uint16 hap, uint16 en
  ) external gameAdmin {
    _defineSnack(snackId, duration, furCost, hap, en);
  }

  /// @notice Loot can have different weight to help prevent over-powering a furball
  /// @dev Each point of weight can be offset by a point of energy; the result reduces luck
  function weightOf(uint128 lootId) external virtual override pure returns (uint16) {
    return 2;
  }

  /// @notice Gets called for Metadata
  function furballDescription(uint256 tokenId) external virtual override view returns (string memory) {
    return "";
  }

  /// @notice Gets called at the beginning of token render; could add underlaid artwork
  function render(uint256 tokenId) external virtual override view returns(string memory) {
    return "";
  }

  /// @notice Checking the zone may use _require to detect preconditions.
  function enterZone(
    uint256 tokenId, uint32 zone, uint256[] memory team
  ) external virtual override returns(uint256) {
    // Nothing to see here.
    return uint256(zone);
  }

  /// @notice Proxy logic is presently delegated to OpenSea-like contract
  function canProxyTrades(
    address owner, address operator
  ) external virtual override view onlyFurballs returns(bool) {
    if (address(_proxies) == address(0)) return false;
    return address(_proxies.proxies(owner)) == operator;
  }

  /// @notice Allow a player to play? Throws on error if not.
  /// @dev This is core gameplay security logic
  function approveSender(address sender) external virtual override view onlyFurballs returns(uint) {
    if (sender == companyWalletProxy && sender != address(0)) return FurLib.PERMISSION_OWNER;
    return _permissions(sender);
  }

  /// @notice Calculates new level for experience
  function onExperience(
    FurLib.Furball memory furball, address owner, uint32 experience
  ) external virtual override onlyFurballs returns(uint32 totalExp, uint16 levels) {
    if (experience == 0) return (0, 0);

    uint32 has = furball.experience;
    uint32 max = maxExperience;
    totalExp = (experience < max && has < (max - experience)) ? (has + experience) : max;

    // Calculate new level & check for level-up
    uint16 oldLevel = furball.level;
    uint16 level = uint16(FurLib.expToLevel(totalExp, max));
    levels = level > oldLevel ? (level - oldLevel) : 0;

    if (levels > 0) {
      // Update community standing
      furballs.governance().updateMaxLevel(owner, level);
    }

    return (totalExp, levels);
  }

  /// @notice The trade hook can update balances or assign rewards
  function onTrade(
    FurLib.Furball memory furball, address from, address to
  ) external virtual override onlyFurballs {
    Governance gov = furballs.governance();
    if (from != address(0)) gov.updateAccount(from, furballs.balanceOf(from) - 1);
    if (to != address(0)) gov.updateAccount(to, furballs.balanceOf(to) + 1);
  }

  /// @notice Attempt to upgrade a given piece of loot (item ID)
  function upgradeLoot(
    FurLib.RewardModifiers memory modifiers,
    address owner,
    uint128 lootId,
    uint8 chances
  ) external virtual override returns(uint128) {
    (uint8 rarity, uint8 stat) = _itemRarityStat(lootId);

    require(rarity > 0 && rarity < 3, "RARITY");
    uint32 chance = (rarity == 1 ? 75 : 25) * uint32(chances) + uint32(modifiers.luckPercent * 10);

    // Remove the 100% from loot, with 5% minimum chance
    chance = chance > 1050 ? (chance - 1000) : 50;

    // Even with many chances, odds are capped:
    if (chance > 750) chance = 750;

    uint32 threshold = (FurLib.Max32 / 1000) * (1000 - chance);
    uint256 rolled = (uint256(roll(modifiers.expPercent)));

    return rolled < threshold ? 0 : _packLoot(rarity + 1, stat);
  }

  /// @notice Main loot-drop functionm
  function dropLoot(
    uint32 intervals,
    FurLib.RewardModifiers memory modifiers
  ) external virtual override onlyFurballs returns(uint128) {
    // Only battles drop loot.
    if (modifiers.zone >= 0x10000) return 0;

    (uint8 rarity, uint8 stat) = rollRarityStat(
      uint32((intervals * uint256(modifiers.luckPercent)) /100), 0);
    return _packLoot(rarity, stat);
  }

  function _packLoot(uint16 rarity, uint16 stat) internal pure returns(uint128) {
    return rarity == 0 ? 0 : (uint16(rarity) * 0x10000) + (stat * 0x100);
  }

  /// @notice Core loot drop rarity randomization
  /// @dev exposes an interface helpful for the unit tests, but is not otherwise called publicly
  function rollRarityStat(uint32 chance, uint32 seed) public returns(uint8, uint8) {
    if (chance == 0) return (0, 0);
    uint32 threshold = 4320;
    uint32 rolled = roll(seed) % threshold;
    uint8 stat = uint8(rolled % 2);

    if (chance > threshold || rolled >= (threshold - chance)) return (3, stat);
    threshold -= chance;
    if (chance * 3 > threshold || rolled >= (threshold - chance * 3)) return (2, stat);
    threshold -= chance * 3;
    if (chance * 6 > threshold || rolled >= (threshold - chance * 6)) return (1, stat);
    return (0, stat);
  }

  /// @notice The snack shop has IDs for each snack definition
  function getSnack(uint32 snackId) external view virtual override returns(FurLib.Snack memory) {
    return _snacks[snackId];
  }

  /// @notice Layers on LootEngine modifiers to rewards
  function modifyReward(
    FurLib.Furball memory furball,
    FurLib.RewardModifiers memory modifiers,
    FurLib.Account memory account,
    bool contextual
  ) external virtual override view returns(FurLib.RewardModifiers memory) {
    // Use temporary variables instead of re-assignment
    uint16 energy = modifiers.energyPoints;
    uint16 weight = furball.weight;
    uint16 expPercent = modifiers.expPercent + modifiers.happinessPoints;
    uint16 luckPercent = modifiers.luckPercent + modifiers.happinessPoints;
    uint16 furPercent = modifiers.furPercent + _furBoost(furball.level) + energy;

    // First add in the inventory
    for (uint256 i=0; i<furball.inventory.length; i++) {
      uint128 lootId = uint128(furball.inventory[i] / 0x100);
      uint32 stackSize = uint32(furball.inventory[i] % 0x100);
      (uint8 rarity, uint8 stat) = _itemRarityStat(lootId);
      uint16 boost = uint16(_lootRarityBoost(rarity) * stackSize);
      if (stat == 0) {
        expPercent += boost;
      } else {
        furPercent += boost;
      }
    }

    // Team size boosts!
    uint256 teamSize = account.permissions < 2 ? account.numFurballs : 0;
    if (teamSize < 10 && teamSize > 1) {
      uint16 amt = uint16(2 * (teamSize - 1));
      expPercent += amt;
      furPercent += amt;
    }

    // ---------------------------------------------------------------------------------------------
    // Negative impacts come last, so subtraction does not underflow.
    // ---------------------------------------------------------------------------------------------

    // Penalties for whales.
    if (teamSize > 10) {
      uint16 amt = uint16(5 * (teamSize > 20 ? 10 : (teamSize - 10)));
      expPercent -= amt;
      furPercent -= amt;
    }

    // Calculate weight & reduce luck
    if (weight > 0) {
      if (energy > 0) {
        weight = (energy >= weight) ? 0 : (weight - energy);
      }
      if (weight > 0) {
        luckPercent = weight >= luckPercent ? 0 : (luckPercent - weight);
      }
    }

    modifiers.expPercent = expPercent;
    modifiers.furPercent = furPercent;
    modifiers.luckPercent = luckPercent;

    return modifiers;
  }

  /// @notice OpenSea metadata
  function attributesMetadata(
    uint256 tokenId
  ) external virtual override view returns(bytes memory) {
    FurLib.FurballStats memory stats = furballs.stats(tokenId, false);
    return abi.encodePacked(
      MetaData.traitValue("Level", stats.definition.level),
      MetaData.traitValue("Rare Genes Boost", stats.definition.rarity),
      MetaData.traitNumber("Edition", (tokenId % 0x100) + 1),
      MetaData.traitNumber("Unique Loot Collected", stats.definition.inventory.length),
      MetaData.traitBoost("EXP Boost", stats.modifiers.expPercent),
      MetaData.traitBoost("FUR Boost", stats.modifiers.furPercent),
      MetaData.traitDate("Acquired", stats.definition.trade),
      MetaData.traitDate("Birthday", stats.definition.birth)
    );
  }

  /// @notice Store a new snack definition
  function _defineSnack(
    uint32 snackId, uint32 duration, uint16 furCost, uint16 hap, uint16 en
  ) internal {
    _snacks[snackId].snackId = snackId;
    _snacks[snackId].duration = duration;
    _snacks[snackId].furCost = furCost;
    _snacks[snackId].happiness = hap;
    _snacks[snackId].energy = en;
    _snacks[snackId].count = 1;
    _snacks[snackId].fed = 0;
  }

  function _lootRarityBoost(uint16 rarity) internal pure returns (uint16) {
    if (rarity == 1) return 5;
    else if (rarity == 2) return 15;
    else if (rarity == 3) return 30;
    return 0;
  }

  /// @notice Gets the FUR boost for a given level
  function _furBoost(uint16 level) internal pure returns (uint16) {
    if (level >= 200) return 581;
    if (level < 25) return (2 * level);
    if (level < 50) return (5000 + (level - 25) * 225) / 100;
    if (level < 75) return (10625 + (level - 50) * 250) / 100;
    if (level < 100) return (16875 + (level - 75) * 275) / 100;
    if (level < 125) return (23750 + (level - 100) * 300) / 100;
    if (level < 150) return (31250 + (level - 125) * 325) / 100;
    if (level < 175) return (39375 + (level - 150) * 350) / 100;
    return (48125 + (level - 175) * 375) / 100;
  }

  /// @notice Unpacks an item, giving its rarity + stat
  function _itemRarityStat(uint128 lootId) internal pure returns (uint8, uint8) {
    return (
      uint8(FurLib.extractBytes(lootId, FurLib.LOOT_BYTE_RARITY, 1)),
      uint8(FurLib.extractBytes(lootId, FurLib.LOOT_BYTE_STAT, 1)));
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
    return
      interfaceId == type(ILootEngine).interfaceId ||
      super.supportsInterface(interfaceId);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

// Contract doesn't really provide anything...
contract OwnableDelegateProxy {}

// Required format for OpenSea of proxy delegate store
// https://github.com/ProjectOpenSea/opensea-creatures/blob/f7257a043e82fae8251eec2bdde37a44fee474c4/contracts/ERC721Tradable.sol
// https://etherscan.io/address/0xa5409ec958c83c3f309868babaca7c86dcb077c1#code
contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./FurLib.sol";

/// @title Dice
/// @author LFG Gaming LLC
/// @notice Math utility functions that leverage storage and thus cannot be pure
abstract contract Dice {
  uint32 private LAST = 0; // Re-seed for PRNG

  /// @notice A PRNG which re-seeds itself with block information & another PRNG
  /// @dev This is unit-tested with monobit (frequency) and longestRunOfOnes
  function roll(uint32 seed) public returns (uint32) {
    LAST = uint32(uint256(keccak256(
      abi.encodePacked(block.timestamp, block.basefee, _prng(LAST == 0 ? seed : LAST)))
    ));
    return LAST;
  }

  /// @notice A PRNG based upon a Lehmer (Park-Miller) method
  /// @dev https://en.wikipedia.org/wiki/Lehmer_random_number_generator
  function _prng(uint32 seed) internal view returns (uint32) {
    uint64 nonce = seed == 0 ? uint32(block.timestamp) : seed;
    uint64 product = uint64(nonce) * 48271;
    uint32 x = uint32((product % 0x7fffffff) + (product >> 31));
    return (x & 0x7fffffff) + (x >> 31);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./FurLib.sol";

/// @title MetaData
/// @author LFG Gaming LLC
/// @notice Utilities for creating MetaData (e.g., OpenSea)
library MetaData {
  function trait(string memory traitType, string memory value) internal pure returns (bytes memory) {
    return abi.encodePacked('{"trait_type": "', traitType,'", "value": "', value, '"}, ');
  }

  function traitNumberDisplay(
    string memory traitType, string memory displayType, uint256 value
  ) internal pure returns (bytes memory) {
    return abi.encodePacked(
      '{"trait_type": "', traitType,
      bytes(displayType).length > 0 ? '", "display_type": "' : '', displayType,
      '", "value": ', FurLib.uint2str(value), '}, '
    );
  }

  function traitValue(string memory traitType, uint256 value) internal pure returns (bytes memory) {
    return traitNumberDisplay(traitType, "", value);
  }

  /// @notice Convert a modifier percentage (120%) into a metadata +20% boost
  function traitBoost(
    string memory traitType, uint256 percent
  ) internal pure returns (bytes memory) {
    return traitNumberDisplay(traitType, "boost_percentage", percent > 100 ? (percent - 100) : 0);
  }

  function traitNumber(
    string memory traitType, uint256 value
  ) internal pure returns (bytes memory) {
    return traitNumberDisplay(traitType, "number", value);
  }

  function traitDate(
    string memory traitType, uint256 value
  ) internal pure returns (bytes memory) {
    return traitNumberDisplay(traitType, "date", value);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./FurProxy.sol";
import "./FurLib.sol";
import "../Furballs.sol";

/// @title Stakeholders
/// @author LFG Gaming LLC
/// @notice Tracks "percent ownership" of a smart contract, paying out according to schedule
/// @dev Acts as a treasury, receiving ETH funds and distributing them to stakeholders
abstract contract Stakeholders is FurProxy {
  // stakeholder values, in 1/1000th of a percent (received during withdrawls)
  mapping(address => uint64) public stakes;

  // List of stakeholders.
  address[] public stakeholders;

  // Where any remaining funds should be deposited. Defaults to contract creator.
  address payable public poolAddress;

  constructor(address furballsAddress) FurProxy(furballsAddress) {
    poolAddress = payable(msg.sender);
  }

  /// @notice Overflow pool of funds. Contains remaining funds from withdrawl.
  function setPool(address addr) public onlyOwner {
    poolAddress = payable(addr);
  }

  /// @notice Changes payout percentages.
  function setStakeholder(address addr, uint64 stake) public onlyOwner {
    if (!_hasStakeholder(addr)) {
      stakeholders.push(addr);
    }
    uint64 percent = stake;
    for (uint256 i=0; i<stakeholders.length; i++) {
      if (stakeholders[i] != addr) {
        percent += stakes[stakeholders[i]];
      }
    }

    require(percent <= FurLib.OneHundredPercent, "Invalid stake (exceeds 100%)");
    stakes[addr] = stake;
  }

  /// @notice Empties this contract's balance, paying out to stakeholders.
  function withdraw() external gameAdmin {
    uint256 balance = address(this).balance;
    require(balance >= FurLib.OneHundredPercent, "Insufficient balance");

    for (uint256 i=0; i<stakeholders.length; i++) {
      address addr = stakeholders[i];
      uint256 payout = balance * uint256(stakes[addr]) / FurLib.OneHundredPercent;
      if (payout > 0) {
        payable(addr).transfer(payout);
      }
    }
    uint256 remaining = address(this).balance;
    poolAddress.transfer(remaining);
  }

  /// @notice Check
  function _hasStakeholder(address addr) internal view returns(bool) {
    for (uint256 i=0; i<stakeholders.length; i++) {
      if (stakeholders[i] == addr) {
        return true;
      }
    }
    return false;
  }

  // -----------------------------------------------------------------------------------------------
  // Payable
  // -----------------------------------------------------------------------------------------------

  /// @notice This contract can be paid transaction fees, e.g., from OpenSea
  /// @dev The contractURI specifies itself as the recipient of transaction fees
  receive() external payable { }
}

// SPDX-License-Identifier: BSD-3-Clause

/// @title Vote checkpointing for an ERC-721 token

/// @dev This ERC20 has been adopted from
///  https://github.com/nounsDAO/nouns-monorepo/blob/master/packages/nouns-contracts/contracts/base/ERC721Checkpointable.sol

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

// LICENSE
// Community.sol uses and modifies part of Compound Lab's Comp.sol:
// https://github.com/compound-finance/compound-protocol/blob/ae4388e780a8d596d97619d9704a931a2752c2bc/contracts/Governance/Comp.sol
//
// Comp.sol source code Copyright 2020 Compound Labs, Inc. licensed under the BSD-3-Clause license.
// With modifications by Nounders DAO.
//
// Additional conditions of BSD-3-Clause can be found here: https://opensource.org/licenses/BSD-3-Clause
//
// MODIFICATIONS
// Checkpointing logic from Comp.sol has been used with the following modifications:
// - `delegates` is renamed to `_delegates` and is set to private
// - `delegates` is a public function that uses the `_delegates` mapping look-up, but unlike
//   Comp.sol, returns the delegator's own address if there is no delegate.
//   This avoids the delegator needing to "delegate to self" with an additional transaction
// - `_transferTokens()` is renamed `_beforeTokenTransfer()` and adapted to hook into OpenZeppelin's ERC721 hooks.

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./FurLib.sol";

/// @title Community
/// @author LFG Gaming LLC
/// @notice This is a derived token; it represents a weighted balance of the ERC721 token (Furballs).
/// @dev There is no fiscal interest in Community. This is simply a measured value of community voice.
contract Community is ERC20 {
    /// @notice A record of each accounts delegate
    mapping(address => address) private _delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }

    constructor() ERC20("FurballsCommunity", "FBLS") { }

    /// @notice A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping(address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256('EIP712Domain(string name,uint256 chainId,address verifyingContract)');

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH =
        keccak256('Delegation(address delegatee,uint256 nonce,uint256 expiry)');

    /// @notice A record of states for signing / validating signatures
    mapping(address => uint256) public nonces;

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @notice The votes a delegator can delegate, which is the current balance of the delegator.
     * @dev Used when calling `_delegate()`
     */
    function votesToDelegate(address delegator) public view returns (uint96) {
        return safe96(balanceOf(delegator), 'Community::votesToDelegate: amount exceeds 96 bits');
    }

    /**
     * @notice Overrides the standard `Comp.sol` delegates mapping to return
     * the delegator's own address if they haven't delegated.
     * This avoids having to delegate to oneself.
     */
    function delegates(address delegator) public view returns (address) {
        address current = _delegates[delegator];
        return current == address(0) ? delegator : current;
    }


      /// @notice Sets the addresses' standing directly
      function update(FurLib.Account memory account, address addr) external returns (uint256) {
        require(false, 'NEED SECURITY');
        // uint256 balance = balanceOf(addr);
        // if (standing > balance) {
        //   _mint(addr, standing - balance);
        // } else if (standing < balance) {
        //   _burn(addr, balance - standing);
        // }
      }

    /**
     * @notice Adapted from `_transferTokens()` in `Comp.sol` to update delegate votes.
     * @dev hooks into OpenZeppelin's `ERC721._transfer`
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfer(from, to, amount);

        require(from == address(0), "Votes may not be traded.");

        /// @notice Differs from `_transferTokens()` to use `delegates` override method to simulate auto-delegation
        _moveDelegates(delegates(from), delegates(to), uint96(amount));
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) public {
        if (delegatee == address(0)) delegatee = msg.sender;
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        bytes32 domainSeparator = keccak256(
            abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name())), getChainId(), address(this))
        );
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked('\x19\x01', domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), 'Community::delegateBySig: invalid signature');
        require(nonce == nonces[signatory]++, 'Community::delegateBySig: invalid nonce');
        require(block.timestamp <= expiry, 'Community::delegateBySig: signature expired');
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint96) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint256 blockNumber) public view returns (uint96) {
        require(blockNumber < block.number, 'Community::getPriorVotes: not yet determined');

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee) internal {
        /// @notice differs from `_delegate()` in `Comp.sol` to use `delegates` override method to simulate auto-delegation
        address currentDelegate = delegates(delegator);

        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        uint96 amount = votesToDelegate(delegator);

        _moveDelegates(currentDelegate, delegatee, amount);
    }

    function _moveDelegates(
        address srcRep,
        address dstRep,
        uint96 amount
    ) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint96 srcRepNew = sub96(srcRepOld, amount, 'Community::_moveDelegates: amount underflows');
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint96 dstRepNew = add96(dstRepOld, amount, 'Community::_moveDelegates: amount overflows');
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint96 oldVotes,
        uint96 newVotes
    ) internal {
        uint32 blockNumber = safe32(
            block.number,
            'Community::_writeCheckpoint: block number exceeds 32 bits'
        );

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function safe96(uint256 n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    function add96(
        uint96 a,
        uint96 b,
        string memory errorMessage
    ) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub96(
        uint96 a,
        uint96 b,
        string memory errorMessage
    ) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function getChainId() internal view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}
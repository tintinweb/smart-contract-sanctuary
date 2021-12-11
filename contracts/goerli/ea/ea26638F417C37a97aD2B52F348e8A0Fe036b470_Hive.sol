// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ICryptoBees.sol";
import "./IHoney.sol";
import "./IHive.sol";
import "./IAttack.sol";

contract Hive is IHive, Ownable, IERC721Receiver, Pausable {
    using Strings for uint256;
    using Strings for uint48;
    using Strings for uint32;
    using Strings for uint16;
    using Strings for uint8;

    event AddedToHive(address indexed owner, uint256 hiveId, uint256 tokenId, uint256 timestamp);
    event TokenClaimed(address indexed owner, uint256 tokenId, uint256 earned);

    // contract references
    IHoney honeyContract;
    ICryptoBees beesContract;
    IAttack attackContract;

    // maps tokenId to hives
    mapping(uint256 => BeeHive) public hives;

    // bee earn 400 $HONEY per day
    uint256 public constant DAILY_HONEY_RATE = 400 ether;
    // bee must have stay 1 day in the hive
    uint256 public constant MINIMUM_TO_EXIT = 1 days;
    // there will only ever be (roughly) 2.4 billion $HONEY earned through staking
    uint256 public constant MAXIMUM_GLOBAL_HONEY = 500000000 ether;

    // amount of $HONEY earned so far
    uint256 public totalHoneyEarned;
    // number of Bees staked
    uint256 public totalBeesStaked;
    // the last time $HONEY was claimed
    uint256 public lastClaimTimestamp;

    // emergency rescue to allow unstaking without any checks but without $HONEY
    bool public rescueEnabled = false;

    /**
     */
    constructor() {}

    function setContracts(
        address _HONEY,
        address _BEES,
        address _ATTACK
    ) external onlyOwner {
        honeyContract = IHoney(_HONEY);
        beesContract = ICryptoBees(_BEES);
        attackContract = IAttack(_ATTACK);
    }

    /** STAKING */
    function calculateOwed(uint256 since) internal view returns (uint256 owed) {
        if (totalHoneyEarned < MAXIMUM_GLOBAL_HONEY) {
            owed = ((block.timestamp - since) * DAILY_HONEY_RATE) / 1 days;
        } else if (since > lastClaimTimestamp) {
            owed = 0; // $HONEY production stopped already
        } else {
            owed = ((lastClaimTimestamp - since) * DAILY_HONEY_RATE) / 1 days; // stop earning additional $HONEY if it's all been earned
        }
    }

    function calculateBeeOwed(uint256 hiveId, uint256 tokenId) external view returns (uint256 owed) {
        uint256 since = hives[hiveId].bees[tokenId].since;
        owed = calculateOwed(since);
    }

    /**
     * adds Bees to the Hive
     * @param account the address of the staker
     * @param tokenIds the IDs of the Bees
     * @param hiveIds the IDs of the Hives
     */
    function addManyToHive(
        address account,
        uint16[] calldata tokenIds,
        uint16[] calldata hiveIds
    ) external {
        require(account == _msgSender() || _msgSender() == address(beesContract), "DONT GIVE YOUR TOKENS AWAY");
        require(tokenIds.length == hiveIds.length, "THE ARGUMENTS LENGTHS DO NOT MATCH");
        uint256 totalHives = ((beesContract.getMinted() / 100) + 2);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(beesContract.getTokenData(tokenIds[i])._type == 1, "TOKEN MUST BE A BEE");
            require(totalHives > hiveIds[i], "HIVE NOT AVAILABLE");
            // dont do this step if its a mint + stake
            if (_msgSender() != address(beesContract)) {
                require(beesContract.getOwnerOf(tokenIds[i]) == _msgSender(), "AINT YO TOKEN");
                beesContract.performTransferFrom(_msgSender(), address(this), tokenIds[i]);
            }

            _addBeeToHive(account, tokenIds[i], hiveIds[i]);
        }
    }

    /**
     * adds a single Bee to a specific Hive
     * @param account the address of the staker
     * @param tokenId the ID of the Bee to add
     * @param hiveId the ID of the Hive
     */
    function _addBeeToHive(
        address account,
        uint256 tokenId,
        uint256 hiveId
    ) internal whenNotPaused _updateEarnings {
        if (hives[hiveId].startedTimestamp == 0) hives[hiveId].startedTimestamp = uint48(block.timestamp);
        uint256 index = hives[hiveId].beesArray.length;
        hives[hiveId].bees[tokenId] = Bee({owner: account, tokenId: uint16(tokenId), index: uint8(index), since: uint48(block.timestamp)});
        hives[hiveId].beesArray.push(uint16(tokenId));
        totalBeesStaked += 1;
        emit AddedToHive(account, hiveId, tokenId, block.timestamp);
    }

    /** CLAIMING / UNSTAKING */

    /**
     * change hive or unstake and realize $HONEY earnings
     * it requires it has 1 day worth of $HONEY unclaimed
     * @param tokenIds the IDs of the tokens to claim earnings from
     * @param hiveIds the IDs of the Hives for each Bee
     * @param newHiveIds the IDs of new Hives (or to unstake if it's -1)
     */
    function claimManyFromHive(
        uint16[] calldata tokenIds,
        uint16[] calldata hiveIds,
        uint16[] calldata newHiveIds
    ) external whenNotPaused _updateEarnings {
        require(tokenIds.length == hiveIds.length && tokenIds.length == newHiveIds.length, "THE ARGUMENTS LENGTHS DO NOT MATCH");
        uint256 owed = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            owed += _claimBeeFromHive(tokenIds[i], hiveIds[i], newHiveIds[i]);
        }
        if (owed == 0) return;
        honeyContract.mint(_msgSender(), owed);
    }

    /**
     * change hive or unstake and realize $HONEY earnings
     * @param tokenId the ID of the Bee to claim earnings from
     * @param hiveId the ID of the Hive where the Bee is
     * @param newHiveId the ID of the Hive where the Bee want to go (-1 for unstake)
     * @return owed - the amount of $HONEY earned
     */
    function _claimBeeFromHive(
        uint256 tokenId,
        uint256 hiveId,
        uint256 newHiveId
    ) internal returns (uint256 owed) {
        Bee memory bee = hives[hiveId].bees[tokenId];
        require(bee.owner == _msgSender(), "YOU ARE NOT THE OWNER");
        // require(!(block.timestamp - stake.value < MINIMUM_TO_EXIT), 'YOU NEED MORE HONEY TO GET OUT OF THE HIVE');
        owed = calculateOwed(bee.since);
        if (newHiveId == 0) {
            beesContract.performSafeTransferFrom(address(this), _msgSender(), tokenId); // send back Sheep
            delete hives[hiveId].bees[tokenId];
            totalBeesStaked -= 1;
            emit TokenClaimed(_msgSender(), tokenId, owed);
        } else {
            uint256 index = hives[hiveId].bees[tokenId].index;
            uint256 lastIndex = hives[hiveId].beesArray.length - 1;
            uint256 lastTokenIndex = hives[hiveId].beesArray[lastIndex];
            hives[hiveId].beesArray[index] = uint16(lastTokenIndex);
            hives[hiveId].beesArray.pop();
            delete hives[hiveId].bees[tokenId];
            uint256 newIndex = hives[newHiveId].beesArray.length;
            hives[newHiveId].bees[tokenId] = Bee({owner: _msgSender(), tokenId: uint16(tokenId), index: uint8(newIndex), since: uint48(block.timestamp)}); // reset stake
            emit AddedToHive(_msgSender(), newHiveId, tokenId, block.timestamp);
        }
    }

    // GETTERS / SETTERS
    function getLastStolenHoneyTimestamp(uint256 hiveId) external view returns (uint256 lastStolenHoneyTimestamp) {
        lastStolenHoneyTimestamp = hives[hiveId].lastStolenHoneyTimestamp;
    }

    function getHiveOccupancy(uint256 hiveId) external view returns (uint256 occupancy) {
        occupancy = hives[hiveId].beesArray.length;
    }

    function getBeeSinceTimestamp(uint256 hiveId, uint256 tokenId) external view returns (uint256 since) {
        since = hives[hiveId].bees[tokenId].since;
    }

    function getBeeTokenId(uint256 hiveId, uint256 index) external view returns (uint256 tokenId) {
        tokenId = hives[hiveId].beesArray[index];
    }

    function setBeeSince(
        uint256 hiveId,
        uint256 tokenId,
        uint48 since
    ) external {
        require(_msgSender() == address(attackContract), "ONLY ATTACK CONTRACT CAN CALL THIS");
        hives[hiveId].bees[tokenId].since = since;
    }

    function incSuccessfulAttacks(uint256 hiveId) external {
        require(_msgSender() == address(attackContract), "ONLY ATTACK CONTRACT CAN CALL THIS");
        hives[hiveId].successfulAttacks += 1;
    }

    function incTotalAttacks(uint256 hiveId) external {
        require(_msgSender() == address(attackContract), "ONLY ATTACK CONTRACT CAN CALL THIS");
        hives[hiveId].totalAttacks += 1;
    }

    function setLastStolenHoneyTimestamp(uint256 hiveId, uint48 timestamp) external {
        require(_msgSender() == address(attackContract), "ONLY ATTACK CONTRACT CAN CALL THIS");
        hives[hiveId].lastStolenHoneyTimestamp = timestamp;
    }

    /**
     * tracks $HONEY earnings to ensure it stops once 2.4 billion is eclipsed
     */
    modifier _updateEarnings() {
        if (totalHoneyEarned < MAXIMUM_GLOBAL_HONEY) {
            totalHoneyEarned += ((block.timestamp - lastClaimTimestamp) * totalBeesStaked * DAILY_HONEY_RATE) / 1 days;
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
     * enables owner to pause / unpause
     */
    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    /** READ ONLY */

    function getInfoOnBee(uint256 tokenId, uint256 hiveId) public view returns (Bee memory) {
        return hives[hiveId].bees[tokenId];
    }

    function getHiveAge(uint256 hiveId) external view returns (uint48) {
        return hives[hiveId].startedTimestamp;
    }

    function getInfoOnHive(uint256 hiveId) public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    uint48(hives[hiveId].startedTimestamp).toString(),
                    ",",
                    uint48(hives[hiveId].lastCollectedHoneyTimestamp).toString(),
                    ",",
                    uint48(hives[hiveId].lastStolenHoneyTimestamp).toString(),
                    ",",
                    uint32(hives[hiveId].subtract).toString(),
                    ",",
                    uint16(hives[hiveId].beesArray.length).toString(),
                    ",",
                    uint8(hives[hiveId].successfulAttacks).toString(),
                    ",",
                    uint8(hives[hiveId].totalAttacks).toString(),
                    ",",
                    uint8(hives[hiveId].successfulCollections).toString(),
                    ",",
                    uint8(hives[hiveId].totalCollections).toString()
                )
            );
    }

    function getInfoOnHives(uint16 start, uint256 end) public view returns (string memory) {
        string memory result;
        uint256 to = end > 0 ? end : ((beesContract.getMinted() / 100) + 2);
        for (uint16 i = start; i < to; i++) {
            result = string(abi.encodePacked(result, uint16(i).toString(), ":", getInfoOnHive(i), ";"));
        }
        return result;
    }

    /**
     * generates a pseudorandom number
     * @param seed a value ensure different outcomes for different sources in the same block
     * @return a pseudorandom value
     */
    function random(uint256 seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(tx.origin, block.timestamp, seed))); //blockhash(block.number - 1),
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "Cannot send tokens to Barn directly");
        return IERC721Receiver.onERC721Received.selector;
    }
    /**
     * emergency unstake tokens
     * @param tokenIds the IDs of the tokens to claim earnings from
     */
    // function rescue(uint256[] calldata tokenIds) external {
    //   require(rescueEnabled, 'RESCUE DISABLED');
    //   uint256 tokenId;
    //   Stake memory stake;
    //   Stake memory lastStake;
    //   uint256 alpha;
    //   for (uint256 i = 0; i < tokenIds.length; i++) {
    //     tokenId = tokenIds[i];
    //     if (isSheep(tokenId)) {
    //       stake = hives[tokenId];
    //       require(stake.owner == _msgSender(), 'SWIPER, NO SWIPING');
    //       woolf.safeTransferFrom(address(this), _msgSender(), tokenId, ''); // send back Sheep
    //       delete hives[tokenId];
    //       totalSheepStaked -= 1;
    //       emit SheepClaimed(tokenId, 0, true);
    //     } else {
    //       alpha = _alphaForWolf(tokenId);
    //       stake = pack[alpha][packIndices[tokenId]];
    //       require(stake.owner == _msgSender(), 'SWIPER, NO SWIPING');
    //       totalAlphaStaked -= alpha; // Remove Alpha from total staked
    //       woolf.safeTransferFrom(address(this), _msgSender(), tokenId, ''); // Send back Wolf
    //       lastStake = pack[alpha][pack[alpha].length - 1];
    //       pack[alpha][packIndices[tokenId]] = lastStake; // Shuffle last Wolf to current position
    //       packIndices[lastStake.tokenId] = packIndices[tokenId];
    //       pack[alpha].pop(); // Remove duplicate
    //       delete packIndices[tokenId]; // Delete old mapping
    //       emit WolfClaimed(tokenId, 0, true);
    //     }
    //   }
    // }
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
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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

//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ICryptoBees {
    struct Token {
        uint8 _type;
        uint8 color;
        uint8 eyes;
        uint8 mouth;
        uint8 nose;
        uint8 hair;
        uint8 accessory;
        uint8 feelers;
        uint8 strength;
        uint32 pot;
        uint48 lastAttackTimestamp;
        uint48 cooldownTillTimestamp;
    }

    function getMinted() external view returns (uint256 m);

    function increaseTokensPot(uint256 tokenId, uint32 amount) external;

    function updateTokensLastAttack(
        uint256 tokenId,
        uint48 timestamp,
        uint48 till
    ) external;

    // function mintForEth(uint256 amount, bool presale) external payable;

    // function mintForHoney(uint256 amount) external;

    // function mintForWool(uint256 amount) external;

    function withdrawERC20(
        address erc20TokenAddress,
        address recipient,
        uint256 amount
    ) external;

    // function getUnrevealed(uint256 i) external view returns (uint256);

    // function getUnrevealedIndex() external view returns (uint256);

    // function setUnrevealedIndex(uint256 index) external;

    // function pushToUnrevealedToken(uint256 blockNumber) external;

    function mint(address addr, uint256 tokenId) external;

    function setPaused(bool _paused) external;

    function getTokenData(uint256 tokenId) external view returns (Token memory token);

    function getOwnerOf(uint256 tokenId) external view returns (address);

    function doesExist(uint256 tokenId) external view returns (bool exists);

    function setTokenData(uint256 tokenId, Token calldata data) external;

    function performTransferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;

    function performSafeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

interface IHoney {
    function mint(address to, uint256 amount) external;

    function mintGiveaway(address[] calldata addresses, uint256 amount) external;

    function burn(address from, uint256 amount) external;

    function disableGiveaway() external;

    function addController(address controller) external;

    function removeController(address controller) external;
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

interface IHive {
    struct Bee {
        address owner;
        uint32 tokenId;
        uint48 since;
        uint8 index;
    }

    struct BeeHive {
        uint48 startedTimestamp;
        uint48 lastCollectedHoneyTimestamp;
        uint48 lastStolenHoneyTimestamp;
        uint32 subtract;
        uint8 successfulAttacks;
        uint8 totalAttacks;
        uint8 successfulCollections;
        uint8 totalCollections;
        mapping(uint256 => Bee) bees;
        uint16[] beesArray;
    }

    function setContracts(
        address _HONEY,
        address _BEES,
        address _ATTACK
    ) external;

    function addManyToHive(
        address account,
        uint16[] calldata tokenIds,
        uint16[] calldata hiveIds
    ) external;

    function claimManyFromHive(
        uint16[] calldata tokenIds,
        uint16[] calldata hiveIds,
        uint16[] calldata newHiveIds
    ) external;

    // function manyBearsAttack(
    //     uint256 nonce,
    //     uint16[] calldata tokenIds,
    //     uint16[] calldata hiveIds,
    //     bool transfer
    // ) external;

    function setRescueEnabled(bool _enabled) external;

    function setPaused(bool _paused) external;

    function setBeeSince(
        uint256 hiveId,
        uint256 tokenId,
        uint48 since
    ) external;

    function calculateBeeOwed(uint256 hiveId, uint256 tokenId) external view returns (uint256 owed);

    function incSuccessfulAttacks(uint256 hiveId) external;

    function incTotalAttacks(uint256 hiveId) external;

    function setLastStolenHoneyTimestamp(uint256 hiveId, uint48 timestamp) external;

    function getLastStolenHoneyTimestamp(uint256 hiveId) external view returns (uint256 lastStolenHoneyTimestamp);

    function getHiveOccupancy(uint256 hiveId) external view returns (uint256 occupancy);

    function getBeeSinceTimestamp(uint256 hiveId, uint256 tokenId) external view returns (uint256 since);

    function getBeeTokenId(uint256 hiveId, uint256 index) external view returns (uint256 tokenId);

    function getHiveAge(uint256 hiveId) external view returns (uint48);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

interface IAttack {
    function setHiveCooldown(uint256 cooldown) external;

    function manyBearsAttack(
        bytes32 revealHash,
        uint16[] calldata tokenIds,
        uint16[] calldata hiveIds
        // bool transfer
    ) external;
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
// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6;

import "./CardPool.sol";

/// @title SpellPool Contract
/// @notice Pool for spell card items for CDH
/// @dev all new cards are added on deployment, defined in constructor of contract
contract SpellPool is CardPool {

    bytes1 private constant IDENTIFIER = 0x03;
    string private constant NAME = "CDH SPELL POOL";

    /// @notice Get identifier of the pool
    /// @dev Returns identifier of the pool and used while generating Card Id for each new card
    /// @return constant defined bytes1 value representing identifier of pool
    function identifier() public virtual override pure returns (bytes1) {
        return IDENTIFIER;
    }

    /// @notice Get name of the contract
    /// @return string value of the name of contract
    function name() external virtual override pure returns (string memory) {
        return NAME;
    }

    /// @notice Creates all spell cards on deployment
    /// @dev each card created has 4 params
    ///      string : Card Name
    ///      bytes1 : Rarity
    ///      uint256 : Rank
    ///      uint256 : Level
    /// by default Rank and Level are both 1.
    constructor() {
        _newCard("EGG OF MANA", Constants.RARITY_COMMON, 1, 1);
        _newCard("EGG OF MANA", Constants.RARITY_RARE, 1, 1);
        _newCard("EGG OF MANA", Constants.RARITY_EPIC, 1, 1);
        _newCard("EGG OF MANA", Constants.RARITY_LEGENDARY, 1, 1);
        _newCard("BLACK DRAGON", Constants.RARITY_COMMON, 1, 1);
        _newCard("BLACK DRAGON", Constants.RARITY_RARE, 1, 1);
        _newCard("BLACK DRAGON", Constants.RARITY_EPIC, 1, 1);
        _newCard("BLACK DRAGON", Constants.RARITY_LEGENDARY, 1, 1);
        _newCard("GREEN DRAGON", Constants.RARITY_COMMON, 1, 1);
        _newCard("GREEN DRAGON", Constants.RARITY_RARE, 1, 1);
        _newCard("GREEN DRAGON", Constants.RARITY_EPIC, 1, 1);
        _newCard("GREEN DRAGON", Constants.RARITY_LEGENDARY, 1, 1);
        _newCard("RED DRAGON", Constants.RARITY_COMMON, 1, 1);
        _newCard("RED DRAGON", Constants.RARITY_RARE, 1, 1);
        _newCard("RED DRAGON", Constants.RARITY_EPIC, 1, 1);
        _newCard("RED DRAGON", Constants.RARITY_LEGENDARY, 1, 1);
        _newCard("BEAR TRAP", Constants.RARITY_COMMON, 1, 1);
        _newCard("BEAR TRAP", Constants.RARITY_RARE, 1, 1);
        _newCard("BEAR TRAP", Constants.RARITY_EPIC, 1, 1);
        _newCard("BEAR TRAP", Constants.RARITY_LEGENDARY, 1, 1);
        _newCard("THUNDERSTORM", Constants.RARITY_COMMON, 1, 1);
        _newCard("THUNDERSTORM", Constants.RARITY_RARE, 1, 1);
        _newCard("THUNDERSTORM", Constants.RARITY_EPIC, 1, 1);
        _newCard("THUNDERSTORM", Constants.RARITY_LEGENDARY, 1, 1);
        _newCard("ARTILLERY", Constants.RARITY_COMMON, 1, 1);
        _newCard("ARTILLERY", Constants.RARITY_RARE, 1, 1);
        _newCard("ARTILLERY", Constants.RARITY_EPIC, 1, 1);
        _newCard("ARTILLERY", Constants.RARITY_LEGENDARY, 1, 1);
        _newCard("PLAGUE WARD", Constants.RARITY_COMMON, 1, 1);
        _newCard("PLAGUE WARD", Constants.RARITY_RARE, 1, 1);
        _newCard("PLAGUE WARD", Constants.RARITY_EPIC, 1, 1);
        _newCard("PLAGUE WARD", Constants.RARITY_LEGENDARY, 1, 1);
        _newCard("LAVA FLOOR", Constants.RARITY_RARE, 1, 1);
        _newCard("LAVA FLOOR", Constants.RARITY_EPIC, 1, 1);
        _newCard("LAVA FLOOR", Constants.RARITY_LEGENDARY, 1, 1);
        _newCard("SPIDER MINE", Constants.RARITY_COMMON, 1, 1);
        _newCard("SPIDER MINE", Constants.RARITY_RARE, 1, 1);
        _newCard("SPIDER MINE", Constants.RARITY_EPIC, 1, 1);
        _newCard("SPIDER MINE", Constants.RARITY_LEGENDARY, 1, 1);
        _newCard("PUMPKIN BOMB", Constants.RARITY_COMMON, 1, 1);
        _newCard("PUMPKIN BOMB", Constants.RARITY_RARE, 1, 1);
        _newCard("PUMPKIN BOMB", Constants.RARITY_EPIC, 1, 1);
        _newCard("PUMPKIN BOMB", Constants.RARITY_LEGENDARY, 1, 1);
        _newCard("BIG BOMB", Constants.RARITY_COMMON, 1, 1);
        _newCard("BIG BOMB", Constants.RARITY_RARE, 1, 1);
        _newCard("BIG BOMB", Constants.RARITY_EPIC, 1, 1);
        _newCard("BIG BOMB", Constants.RARITY_LEGENDARY, 1, 1);
        _newCard("BLADESTORM", Constants.RARITY_COMMON, 1, 1);
        _newCard("BLADESTORM", Constants.RARITY_RARE, 1, 1);
        _newCard("BLADESTORM", Constants.RARITY_EPIC, 1, 1);
        _newCard("BLADESTORM", Constants.RARITY_LEGENDARY, 1, 1);
        _newCard("ARMAGEDDON", Constants.RARITY_RARE, 1, 1);
        _newCard("ARMAGEDDON", Constants.RARITY_EPIC, 1, 1);
        _newCard("ARMAGEDDON", Constants.RARITY_LEGENDARY, 1, 1);
        _newCard("METEOR STRIKE", Constants.RARITY_COMMON, 1, 1);
        _newCard("METEOR STRIKE", Constants.RARITY_RARE, 1, 1);
        _newCard("METEOR STRIKE", Constants.RARITY_EPIC, 1, 1);
        _newCard("METEOR STRIKE", Constants.RARITY_LEGENDARY, 1, 1);
        _newCard("SPACE BEAM", Constants.RARITY_RARE, 1, 1);
        _newCard("SPACE BEAM", Constants.RARITY_EPIC, 1, 1);
        _newCard("SPACE BEAM", Constants.RARITY_LEGENDARY, 1, 1);
        _newCard("SKY FIST", Constants.RARITY_COMMON, 1, 1);
        _newCard("SKY FIST", Constants.RARITY_RARE, 1, 1);
        _newCard("SKY FIST", Constants.RARITY_EPIC, 1, 1);
        _newCard("SKY FIST", Constants.RARITY_LEGENDARY, 1, 1);
        _newCard("CLARION CALL", Constants.RARITY_COMMON, 1, 1);
        _newCard("CLARION CALL", Constants.RARITY_RARE, 1, 1);
        _newCard("CLARION CALL", Constants.RARITY_EPIC, 1, 1);
        _newCard("CLARION CALL", Constants.RARITY_LEGENDARY, 1, 1);
        _newCard("WARCRY", Constants.RARITY_RARE, 1, 1);
        _newCard("WARCRY", Constants.RARITY_EPIC, 1, 1);
        _newCard("WARCRY", Constants.RARITY_LEGENDARY, 1, 1);
        _newCard("ELVEN RANGERS", Constants.RARITY_COMMON, 1, 1);
        _newCard("ELVEN RANGERS", Constants.RARITY_RARE, 1, 1);
        _newCard("ELVEN RANGERS", Constants.RARITY_EPIC, 1, 1);
        _newCard("ELVEN RANGERS", Constants.RARITY_LEGENDARY, 1, 1);
        _newCard("THUNDER MOOSE", Constants.RARITY_COMMON, 1, 1);
        _newCard("THUNDER MOOSE", Constants.RARITY_RARE, 1, 1);
        _newCard("THUNDER MOOSE", Constants.RARITY_EPIC, 1, 1);
        _newCard("THUNDER MOOSE", Constants.RARITY_LEGENDARY, 1, 1);
        _newCard("LIGHTNING GOOSE", Constants.RARITY_COMMON, 1, 1);
        _newCard("LIGHTNING GOOSE", Constants.RARITY_RARE, 1, 1);
        _newCard("LIGHTNING GOOSE", Constants.RARITY_EPIC, 1, 1);
        _newCard("LIGHTNING GOOSE", Constants.RARITY_LEGENDARY, 1, 1);
        _newCard("TOTEM OF MIGHT", Constants.RARITY_COMMON, 1, 1);
        _newCard("TOTEM OF MIGHT", Constants.RARITY_RARE, 1, 1);
        _newCard("TOTEM OF MIGHT", Constants.RARITY_EPIC, 1, 1);
        _newCard("TOTEM OF MIGHT", Constants.RARITY_LEGENDARY, 1, 1);
        _newCard("FREEZE", Constants.RARITY_COMMON, 1, 1);
        _newCard("FREEZE", Constants.RARITY_RARE, 1, 1);
        _newCard("FREEZE", Constants.RARITY_EPIC, 1, 1);
        _newCard("FREEZE", Constants.RARITY_LEGENDARY, 1, 1);
        _newCard("GUARDIAN OF TIME", Constants.RARITY_COMMON, 1, 1);
        _newCard("GUARDIAN OF TIME", Constants.RARITY_RARE, 1, 1);
        _newCard("GUARDIAN OF TIME", Constants.RARITY_EPIC, 1, 1);
        _newCard("GUARDIAN OF TIME", Constants.RARITY_LEGENDARY, 1, 1);
        _newCard("FROST STORM", Constants.RARITY_COMMON, 1, 1);
        _newCard("FROST STORM", Constants.RARITY_RARE, 1, 1);
        _newCard("FROST STORM", Constants.RARITY_EPIC, 1, 1);
        _newCard("FROST STORM", Constants.RARITY_LEGENDARY, 1, 1);
        _newCard("GLYPH OF FATIGUE", Constants.RARITY_COMMON, 1, 1);
        _newCard("GLYPH OF FATIGUE", Constants.RARITY_RARE, 1, 1);
        _newCard("GLYPH OF FATIGUE", Constants.RARITY_EPIC, 1, 1);
        _newCard("GLYPH OF FATIGUE", Constants.RARITY_LEGENDARY, 1, 1);
        _newCard("SHRINK CURSE", Constants.RARITY_RARE, 1, 1);
        _newCard("SHRINK CURSE", Constants.RARITY_EPIC, 1, 1);
        _newCard("SHRINK CURSE", Constants.RARITY_LEGENDARY, 1, 1);
        _newCard("ELECTRIC CASCADE", Constants.RARITY_RARE, 1, 1);
        _newCard("ELECTRIC CASCADE", Constants.RARITY_EPIC, 1, 1);
        _newCard("ELECTRIC CASCADE", Constants.RARITY_LEGENDARY, 1, 1);
        _newCard("WRATH OF ZEUS", Constants.RARITY_RARE, 1, 1);
        _newCard("WRATH OF ZEUS", Constants.RARITY_EPIC, 1, 1);
        _newCard("WRATH OF ZEUS", Constants.RARITY_LEGENDARY, 1, 1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6;

import "../Constants.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/access/Ownable.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/utils/Pausable.sol";

abstract contract CardPool is Ownable, Pausable {
    bytes1 private constant IDENTIFIER = 0x00;
    string private constant NAME = "CRAZY DEFENCE HEROES CARD POOL";


    struct Card {
        bytes16 cardType;
        bytes1 rarity;
        uint256 rank;
        uint256 level;
    }

    /// @notice URI location where the JSON for items are stored/pinned.
    /// @dev uri is set individually for each pools, this might be ipfs pinned
    ///      location or http endpoint
    string public uri;

    mapping(uint256 => Card) private cards;

    /// @dev Map of list of card types by rarity of card
    ///      eg. Rarity 0x01 -> [cardId1, cardId2, cardId3, ... ]
    mapping(bytes1 => uint256[]) private rarityCardType; // rarity => cardId[]

    /// @dev Map of card hash (card type) to name of card
    mapping(bytes16 => string) private cardTypeName;

    /// @dev Map of name of card to card hash, used to check if specific card type already exists
    ///      and avoid multiple hashing and having multiple records map for Card Name and Card Type
    mapping(string => bytes16) private reverseCardType;

    /// @notice Total number of cards for specific card pool
    uint256 public totalCards;

    /// @dev Emitted when URI to json files are set in the pool.
    event URIUpdated(string oldURI, string newURI);

    /// @notice Get identifier of the pool
    /// @dev Returns identifier of the pool and used while generating Card Id for each new card
    /// @dev NOTE: This method is overridden in all Pools for determine identifier of pool
    /// @return constant defined bytes1 value representing identifier of pool
    function identifier() public virtual pure returns (bytes1) {
        return IDENTIFIER;
    }

    /// @notice Get name of the contract
    /// @dev NOTE: This method is overridden in all Pools for determine name of pool
    /// @return string value of the name of contract
    function name() external virtual pure returns (string memory) {
        return NAME;
    }

    /// @notice Returns the cardId for specific record of data set in pool
    /// @dev Single uint256 number is generated by shifting specific portion of information
    ///      in the cardId, so if cardId is provided, it could be decoded to which card type,
    ///      rarity or what category of card (pool) it is generated for.
    ///         CDH bytes = First 4 bytes (32 bits )
    ///         identifier = 1 byte (8 bits )
    ///         card type = 16 byte (128 bits )
    ///         rarity = 1 byte (8 bits )
    ///      remaining bits are left as it is, and not required
    /// @param _cardType Card Type hash to use while generating cardId
    /// @param _rarity Rarity of Card
    /// @param _rank Rank of card, default is 1
    /// @param _level Level of card, default is 1
    /// @return uint256 for the bytes32 cardId
    function generateCardId(bytes32 _cardType, bytes1 _rarity, uint256 _rank, uint256 _level) public pure returns (uint256) {
        bytes32 cardId = Constants.CRAZY_DEFENCE_HEROES;
        cardId |= (bytes32(identifier()) >> 32);
        cardId |= (_cardType >> 40);
        cardId |= (bytes32(_rarity) >> 168);
        cardId |= (bytes32(_rank) >> 200);
        cardId |= (bytes32(_level) >> 232);
        return uint256(cardId);
    }

    /// @notice Check if the cardId exists and is created
    /// @dev check cards mapping for cardId to check card type
    /// @param cardId Card Type hash to check if it exists in card pool
    /// @return Returns a boolean value if cardId exists in pool mapping.
    function exists(uint256 cardId) external view returns (bool) {
        return (cards[cardId].cardType != bytes16(0));
    }

    /// @notice Number of card types by rarity.
    /// @dev Count of card type hashes for specific rarity from created cards list
    /// @param rarity bytes1 value of card rarity from enum
    /// @return Returns a number representing number of card types for user provided rarity
    function numberOfCardsByRarity(bytes1 rarity) external view returns (uint256) {
        return rarityCardType[rarity].length;
    }

    /// @notice Retrieve card id from rarity mapping at given index
    /// @dev Retrieve Card Id from rarityCardType for the rarity at given index
    /// @param rarity Rarity of the card
    /// @param index Number value representing index in the list
    /// @return Returns uint256 Card Id
    function getCardIdByRarity(bytes1 rarity, uint256 index) external view returns (uint256) {
        return rarityCardType[rarity][index];
    }

    /// @notice Get URI for json file for the card Id
    /// @param id Card Id for which json value to set
    /// @return String value of full url to json
    function getUri(uint256 id) public view returns (string memory) {
        return string(abi.encodePacked(uri, uint2str(id), ".json"));
    }

    /// @notice Name of card by card type hash in mapping
    /// @param _cardType Card type hash for the card name when new card is created
    /// @return Returns string value Card Name for the card type
    function getCardNameByType(bytes16 _cardType) public view returns (string memory) {
        return cardTypeName[_cardType];
    }

    /// @dev Similar getCardNameByType but get card name by cardId
    function getCardName(uint256 _cardId) public view returns (string memory) {
        return getCardNameByType(cards[_cardId].cardType);
    }

    /// @notice Get all the information of cards including Card Name, Card Type, Rarity, Rank, Level and URI of cardId
    /// @param _id Card Id generated and stored in mappings
    /// @return Returns multiple values : Card Name, Card Type, Rarity, Rank, Level, URI
    function getCard(uint256 _id) external view returns (string memory, bytes16, bytes1, uint256, uint256, string memory) {
        Card memory _card = cards[_id];
        return (getCardName(_id), _card.cardType, _card.rarity, _card.rank, _card.level, getUri(_id));
    }

    /// @notice Get Card Name by card type of the card
    /// @return Returns bytes16 value of card type
    function getCardTypeByName(string memory _name) external view returns (bytes16) {
        return reverseCardType[_name];
    }

    /*
        Generate new card for corresponding pools.
        Call this only in constructor with proper arguments, Card Name, Rarity , Rank and Level
    */
    function _newCard(string memory _cardTypeName, bytes1 _rarity, uint256 _rank, uint256 _level) internal whenNotPaused {
        if (reverseCardType[_cardTypeName] == bytes16(0)) {
            bytes16 hash = bytes16(keccak256(abi.encodePacked(_cardTypeName)));
            cardTypeName[hash] = _cardTypeName;
            reverseCardType[_cardTypeName] = hash;
        }
        bytes16 cardType = reverseCardType[_cardTypeName];
        uint256 id = generateCardId(cardType, _rarity, _rank, _level);
        cards[id] = Card(cardType, _rarity, _rank, _level);
        rarityCardType[_rarity].push(id);
        totalCards++;
    }

    /// @notice Set URI for the specific pool
    /// Emits a event `URIUpdated` when update succeeds.
    /// @param _uri set URI from the owner of the contract when its not paused
    function setURI(string memory _uri) external onlyOwner whenNotPaused {
        emit URIUpdated(uri, _uri);
        uri = _uri;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function uint2str(uint256 num) internal pure returns (string memory _uintAsString) {
        if (num == 0) {
            return "0";
        }

        uint256 j = num;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }

        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (num != 0) {
            bstr[k--] = bytes1(uint8(48 + (num % 10)));
            num /= 10;
        }
        return string(bstr);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

library Constants {
    bytes1 public constant RARITY_UNKNOWN = 0x00;
    bytes1 public constant RARITY_COMMON = 0x01;
    bytes1 public constant RARITY_RARE = 0x02;
    bytes1 public constant RARITY_EPIC = 0x03;
    bytes1 public constant RARITY_LEGENDARY = 0x04;

    bytes1 public constant UNKNOWN_POOL_IDENTIFIER = 0x00;
    bytes1 public constant EQUIPMENT_POOL_IDENTIFIER = 0x01;
    bytes1 public constant HERO_POOL_IDENTIFIER = 0x02;
    bytes1 public constant SPELL_POOL_IDENTIFIER = 0x03;
    bytes1 public constant TOWER_POOL_IDENTIFIER = 0x04;

    bytes4 public constant CRAZY_DEFENCE_HEROES = 0x2ebc3cb3; // bytes4(keccak256(abi.encodePacked("CRAZY DEFENCE HEROES")));
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

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
    constructor () internal {
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

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
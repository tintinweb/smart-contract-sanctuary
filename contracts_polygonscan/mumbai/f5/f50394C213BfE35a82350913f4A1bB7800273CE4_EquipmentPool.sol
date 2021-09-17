// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6;

import "./CardPool.sol";

contract EquipmentPool is CardPool {

    bytes1 private constant IDENTIFIER = 0x01;
    string private constant NAME = "CDH EQUIPMENT POOL";

    function identifier() public virtual override pure returns (bytes1) {
        return IDENTIFIER;
    }

    function name() public virtual override pure returns (string memory) {
        return NAME;
    }

    constructor() public {
        _newCard("STEEL SWORD", Constants.RARITY_COMMON, 1, 1);
        _newCard("STEEL SWORD", Constants.RARITY_RARE, 1, 1);
        _newCard("STEEL SWORD", Constants.RARITY_EPIC, 1, 1);
        _newCard("STEEL SWORD", Constants.RARITY_LEGENDARY, 1, 1);
        _newCard("SALAMANDERS STING", Constants.RARITY_COMMON, 1, 1);
        _newCard("SALAMANDERS STING", Constants.RARITY_RARE, 1, 1);
        _newCard("SALAMANDERS STING", Constants.RARITY_EPIC, 1, 1);
        _newCard("SALAMANDERS STING", Constants.RARITY_LEGENDARY, 1, 1);
        _newCard("HEROIC HALBERD", Constants.RARITY_COMMON, 1, 1);
        _newCard("HEROIC HALBERD", Constants.RARITY_RARE, 1, 1);
        _newCard("HEROIC HALBERD", Constants.RARITY_EPIC, 1, 1);
        _newCard("HEROIC HALBERD", Constants.RARITY_LEGENDARY, 1, 1);
        _newCard("STAFF OF DAWN", Constants.RARITY_COMMON, 1, 1);
        _newCard("STAFF OF DAWN", Constants.RARITY_RARE, 1, 1);
        _newCard("STAFF OF DAWN", Constants.RARITY_EPIC, 1, 1);
        _newCard("STAFF OF DAWN", Constants.RARITY_LEGENDARY, 1, 1);
        _newCard("CRIMSON TALWAR", Constants.RARITY_COMMON, 1, 1);
        _newCard("CRIMSON TALWAR", Constants.RARITY_RARE, 1, 1);
        _newCard("CRIMSON TALWAR", Constants.RARITY_EPIC, 1, 1);
        _newCard("CRIMSON TALWAR", Constants.RARITY_LEGENDARY, 1, 1);
        _newCard("CRYSTALLINE", Constants.RARITY_COMMON, 1, 1);
        _newCard("CRYSTALLINE", Constants.RARITY_RARE, 1, 1);
        _newCard("CRYSTALLINE", Constants.RARITY_EPIC, 1, 1);
        _newCard("CRYSTALLINE", Constants.RARITY_LEGENDARY, 1, 1);
        _newCard("FANGBLADE", Constants.RARITY_COMMON, 1, 1);
        _newCard("FANGBLADE", Constants.RARITY_RARE, 1, 1);
        _newCard("FANGBLADE", Constants.RARITY_EPIC, 1, 1);
        _newCard("FANGBLADE", Constants.RARITY_LEGENDARY, 1, 1);
        _newCard("IRON CAP", Constants.RARITY_COMMON, 1, 1);
        _newCard("IRON CAP", Constants.RARITY_RARE, 1, 1);
        _newCard("IRON CAP", Constants.RARITY_EPIC, 1, 1);
        _newCard("IRON CAP", Constants.RARITY_LEGENDARY, 1, 1);
        _newCard("HELM OF THE VALKYRIE", Constants.RARITY_COMMON, 1, 1);
        _newCard("HELM OF THE VALKYRIE", Constants.RARITY_RARE, 1, 1);
        _newCard("HELM OF THE VALKYRIE", Constants.RARITY_EPIC, 1, 1);
        _newCard("HELM OF THE VALKYRIE", Constants.RARITY_LEGENDARY, 1, 1);
        _newCard("VERMILION HELM", Constants.RARITY_COMMON, 1, 1);
        _newCard("VERMILION HELM", Constants.RARITY_RARE, 1, 1);
        _newCard("VERMILION HELM", Constants.RARITY_EPIC, 1, 1);
        _newCard("VERMILION HELM", Constants.RARITY_LEGENDARY, 1, 1);
        _newCard("HELM OF MANY EYES", Constants.RARITY_COMMON, 1, 1);
        _newCard("HELM OF MANY EYES", Constants.RARITY_RARE, 1, 1);
        _newCard("HELM OF MANY EYES", Constants.RARITY_EPIC, 1, 1);
        _newCard("HELM OF MANY EYES", Constants.RARITY_LEGENDARY, 1, 1);
        _newCard("WOODEN SHIELD", Constants.RARITY_COMMON, 1, 1);
        _newCard("WOODEN SHIELD", Constants.RARITY_RARE, 1, 1);
        _newCard("WOODEN SHIELD", Constants.RARITY_EPIC, 1, 1);
        _newCard("MAGIC BUCKLER", Constants.RARITY_COMMON, 1, 1);
        _newCard("MAGIC BUCKLER", Constants.RARITY_RARE, 1, 1);
        _newCard("MAGIC BUCKLER", Constants.RARITY_EPIC, 1, 1);
        _newCard("VALKYRIE SHIELD", Constants.RARITY_COMMON, 1, 1);
        _newCard("VALKYRIE SHIELD", Constants.RARITY_RARE, 1, 1);
        _newCard("VALKYRIE SHIELD", Constants.RARITY_EPIC, 1, 1);
        _newCard("VALKYRIE SHIELD", Constants.RARITY_LEGENDARY, 1, 1);
        _newCard("SCARLET SHIELD", Constants.RARITY_COMMON, 1, 1);
        _newCard("SCARLET SHIELD", Constants.RARITY_RARE, 1, 1);
        _newCard("SCARLET SHIELD", Constants.RARITY_EPIC, 1, 1);
        _newCard("SCARLET SHIELD", Constants.RARITY_LEGENDARY, 1, 1);
        _newCard("LEATHER CUIRASS", Constants.RARITY_COMMON, 1, 1);
        _newCard("LEATHER CUIRASS", Constants.RARITY_RARE, 1, 1);
        _newCard("LEATHER CUIRASS", Constants.RARITY_EPIC, 1, 1);
        _newCard("LEATHER CUIRASS", Constants.RARITY_LEGENDARY, 1, 1);
        _newCard("DRAGON MAIL", Constants.RARITY_COMMON, 1, 1);
        _newCard("DRAGON MAIL", Constants.RARITY_RARE, 1, 1);
        _newCard("DRAGON MAIL", Constants.RARITY_EPIC, 1, 1);
        _newCard("DRAGON MAIL", Constants.RARITY_LEGENDARY, 1, 1);
        _newCard("VERMILION PLATE", Constants.RARITY_COMMON, 1, 1);
        _newCard("VERMILION PLATE", Constants.RARITY_RARE, 1, 1);
        _newCard("VERMILION PLATE", Constants.RARITY_EPIC, 1, 1);
        _newCard("VERMILION PLATE", Constants.RARITY_LEGENDARY, 1, 1);
        _newCard("STEEL TOE BOOTS", Constants.RARITY_COMMON, 1, 1);
        _newCard("STEEL TOE BOOTS", Constants.RARITY_RARE, 1, 1);
        _newCard("STEEL TOE BOOTS", Constants.RARITY_EPIC, 1, 1);
        _newCard("STEEL TOE BOOTS", Constants.RARITY_LEGENDARY, 1, 1);
        _newCard("SLIPPERS OF SWIFTNESS", Constants.RARITY_COMMON, 1, 1);
        _newCard("SLIPPERS OF SWIFTNESS", Constants.RARITY_RARE, 1, 1);
        _newCard("SLIPPERS OF SWIFTNESS", Constants.RARITY_EPIC, 1, 1);
        _newCard("SLIPPERS OF SWIFTNESS", Constants.RARITY_LEGENDARY, 1, 1);
        _newCard("BOOTS OF THE MARCH", Constants.RARITY_COMMON, 1, 1);
        _newCard("BOOTS OF THE MARCH", Constants.RARITY_RARE, 1, 1);
        _newCard("BOOTS OF THE MARCH", Constants.RARITY_EPIC, 1, 1);
        _newCard("BOOTS OF THE MARCH", Constants.RARITY_LEGENDARY, 1, 1);
        _newCard("BOOTS OF QUANTUM STRIDE", Constants.RARITY_RARE, 1, 1);
        _newCard("BOOTS OF QUANTUM STRIDE", Constants.RARITY_EPIC, 1, 1);
        _newCard("BOOTS OF QUANTUM STRIDE", Constants.RARITY_LEGENDARY, 1, 1);
        _newCard("TALISMAN OF LIFE", Constants.RARITY_COMMON, 1, 1);
        _newCard("TALISMAN OF LIFE", Constants.RARITY_RARE, 1, 1);
        _newCard("TALISMAN OF LIFE", Constants.RARITY_EPIC, 1, 1);
        _newCard("RING OF REGENERATION", Constants.RARITY_RARE, 1, 1);
        _newCard("RING OF REGENERATION", Constants.RARITY_EPIC, 1, 1);
        _newCard("RING OF REGENERATION", Constants.RARITY_LEGENDARY, 1, 1);
        _newCard("RING OF MIGHT", Constants.RARITY_RARE, 1, 1);
        _newCard("RING OF MIGHT", Constants.RARITY_EPIC, 1, 1);
        _newCard("RING OF MIGHT", Constants.RARITY_LEGENDARY, 1, 1);
        _newCard("GIRDLE OF PAIN", Constants.RARITY_RARE, 1, 1);
        _newCard("GIRDLE OF PAIN", Constants.RARITY_EPIC, 1, 1);
        _newCard("GIRDLE OF PAIN", Constants.RARITY_LEGENDARY, 1, 1);
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

    string public uri;
    mapping(uint256 => Card) private cards;
    mapping(bytes1 => uint256[]) private rarityCardType; // rarity => cardId[]

    mapping(bytes16 => string) private cardTypeName;
    mapping(string => bytes16) private reverseCardType;

    uint256 public totalCards;

    event URIUpdated(string oldURI, string newURI);

    function identifier() public virtual pure returns (bytes1) {
        return IDENTIFIER;
    }

    function name() public virtual pure returns (string memory) {
        return NAME;
    }

    function generateCardId(bytes32 _cardType, bytes1 _rarity, uint256 _rank, uint256 _level) public pure returns (uint256) {
        bytes32 cardId = Constants.CRAZY_DEFENCE_HEROES;
        cardId |= (bytes32(identifier()) >> 32);
        cardId |= (_cardType >> 40);
        cardId |= (bytes32(_rarity) >> 168);
        return uint256(cardId);
    }

    function exists(uint256 cardId) public view returns (bool) {
        return (cards[cardId].cardType != bytes16(0));
    }

    function numberOfCardsByRarity(bytes1 rarity) public view returns (uint256) {
        return rarityCardType[rarity].length;
    }

    function getCardIdByRarity(bytes1 rarity, uint256 index) public view returns (uint256) {
        return rarityCardType[rarity][index];
    }

    function getUri(uint256 id) public view returns (string memory) {
        return string(abi.encodePacked(uri, uint2str(id), ".json"));
    }

    function getCardNameByType(bytes16 _cardType) public view returns (string memory) {
        return cardTypeName[_cardType];
    }

    function getCardName(uint256 _cardId) public view returns (string memory) {
        return getCardNameByType(cards[_cardId].cardType);
    }

    function getCard(uint256 _id) public view returns (string memory, bytes16, bytes1, uint256, uint256, string memory) {
        Card memory _card = cards[_id];
        return (getCardName(_id), _card.cardType, _card.rarity, _card.rank, _card.level, getUri(_id));
    }

    function getCardTypeByName(string memory _name) public view returns (bytes16) {
        return reverseCardType[_name];
    }

    /*
        call this only in constructor with proper arguments
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

    function setURI(string memory _uri) public onlyOwner whenNotPaused {
        emit URIUpdated(uri, _uri);
        uri = _uri;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
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

pragma solidity >=0.6.6;

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

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}
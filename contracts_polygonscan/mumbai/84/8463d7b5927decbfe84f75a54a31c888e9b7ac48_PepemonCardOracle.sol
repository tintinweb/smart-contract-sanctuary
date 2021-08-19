/**
 *Submitted for verification at polygonscan.com on 2021-08-19
*/

// Sources flattened with hardhat v2.6.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]



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


// File contracts/PepemonCardOracle.sol



pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

/**
This contract acts as the oracle, it contains battling information for both the Pepemon Battle and Support cards
**/
contract PepemonCardOracle is Ownable {
    enum BattleCardType {
        PLANT,
        FIRE
    }

    enum SupportCardType {
        OFFENSE,
        STRONG_OFFENSE,
        DEFENSE,
        STRONG_DEFENSE
    }

    enum EffectTo {
        ATTACK,
        STRONG_ATTACK,
        DEFENSE,
        STRONG_DEFENSE,
        SPEED,
        INTELLIGENCE
    }

    enum EffectFor {
        ME,
        ENEMY
    }

    struct BattleCardStats {
        uint256 battleCardId;
        BattleCardType battleCardType;
        string name;
        uint256 hp; // hitpoints
        uint256 spd; // speed
        uint256 inte; // intelligence
        uint256 def; // defense
        uint256 atk; // attack
        uint256 sAtk; // special attack
        uint256 sDef; // special defense
    }

    struct SupportCardStats {
        uint256 supportCardId;
        SupportCardType supportCardType;
        string name;
        EffectOne[] effectOnes;
        EffectMany effectMany;
        // If true, duplicate copies of the card in the same turn will have no extra effect.
        bool unstackable;
        // This property is for EffectMany now.
        // If true, assume the card is already in effect
        // then the same card drawn and used within a number of turns does not extend or reset duration of the effect.
        bool unresettable;
    }

    struct EffectOne {
        // If power is 0, it is equal to the total of all normal offense/defense cards in the current turn.
        int256 power;
        EffectTo effectTo;
        EffectFor effectFor;
        uint256 reqCode; //requirement code
    }

    struct EffectMany {
        int256 power;
        uint256 numTurns;
        EffectTo effectTo;
        EffectFor effectFor;
        uint256 reqCode; //requirement code
    }

    mapping(uint256 => BattleCardStats) public battleCardStats;
    mapping(uint256 => SupportCardStats) public supportCardStats;

    event BattleCardCreated(address sender, uint256 cardId);
    event BattleCardUpdated(address sender, uint256 cardId);
    event SupportCardCreated(address sender, uint256 cardId);
    event SupportCardUpdated(address sender, uint256 cardId);

    function addBattleCard(BattleCardStats memory cardData) public onlyOwner {
        require(battleCardStats[cardData.battleCardId].battleCardId == 0, "PepemonCard: BattleCard already exists");

        BattleCardStats storage _card = battleCardStats[cardData.battleCardId];
        _card.battleCardId = cardData.battleCardId;
        _card.battleCardType = cardData.battleCardType;
        _card.name = cardData.name;
        _card.hp = cardData.hp;
        _card.spd = cardData.spd;
        _card.inte = cardData.inte;
        _card.def = cardData.def;
        _card.atk = cardData.atk;
        _card.sDef = cardData.sDef;
        _card.sAtk = cardData.sAtk;

        emit BattleCardCreated(msg.sender, cardData.battleCardId);
    }

    function updateBattleCard(BattleCardStats memory cardData) public onlyOwner {
        require(battleCardStats[cardData.battleCardId].battleCardId != 0, "PepemonCard: BattleCard not found");

        BattleCardStats storage _card = battleCardStats[cardData.battleCardId];
        _card.hp = cardData.hp;
        _card.battleCardType = cardData.battleCardType;
        _card.name = cardData.name;
        _card.spd = cardData.spd;
        _card.inte = cardData.inte;
        _card.def = cardData.def;
        _card.atk = cardData.atk;
        _card.sDef = cardData.sDef;
        _card.sAtk = cardData.sAtk;

        emit BattleCardUpdated(msg.sender, cardData.battleCardId);
    }

    function getBattleCardById(uint256 _id) public view returns (BattleCardStats memory) {
        require(battleCardStats[_id].battleCardId != 0, "PepemonCard: BattleCard not found");
        return battleCardStats[_id];
    }

    function addSupportCard(SupportCardStats memory cardData) public onlyOwner {
        require(supportCardStats[cardData.supportCardId].supportCardId == 0, "PepemonCard: SupportCard already exists");

        SupportCardStats storage _card = supportCardStats[cardData.supportCardId];
        _card.supportCardId = cardData.supportCardId;
        _card.supportCardType = cardData.supportCardType;
        _card.name = cardData.name;
        for (uint256 i = 0; i < cardData.effectOnes.length; i++) {
            _card.effectOnes.push(cardData.effectOnes[i]);
        }
        _card.effectMany = cardData.effectMany;
        _card.unstackable = cardData.unstackable;
        _card.unresettable = cardData.unresettable;

        emit SupportCardCreated(msg.sender, cardData.supportCardId);
    }

    function updateSupportCard(SupportCardStats memory cardData) public onlyOwner {
        require(supportCardStats[cardData.supportCardId].supportCardId != 0, "PepemonCard: SupportCard not found");

        SupportCardStats storage _card = supportCardStats[cardData.supportCardId];
        _card.supportCardId = cardData.supportCardId;
        _card.supportCardType = cardData.supportCardType;
        _card.name = cardData.name;
        for (uint256 i = 0; i < cardData.effectOnes.length; i++) {
            _card.effectOnes.push(cardData.effectOnes[i]);
        }
        _card.effectMany = cardData.effectMany;
        _card.unstackable = cardData.unstackable;
        _card.unresettable = cardData.unresettable;

        emit SupportCardUpdated(msg.sender, cardData.supportCardId);
    }

    function getSupportCardById(uint256 _id) public view returns (SupportCardStats memory) {
        require(supportCardStats[_id].supportCardId != 0, "PepemonCard: SupportCard not found");
        return supportCardStats[_id];
    }

    /**
     * @dev Get supportCardType of supportCard
     * @param _id uint256
     */
    function getSupportCardTypeById(uint256 _id) public view returns (SupportCardType) {
        return getSupportCardById(_id).supportCardType;
    }
}
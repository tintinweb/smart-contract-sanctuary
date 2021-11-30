// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

contract GearSlotsData is Ownable {
    mapping(address => bool) private _authorizedCallers;

    constructor() { }

    function isAuthorized(address caller) public view returns (bool) {
        return _authorizedCallers[caller];
    }

    function addAuthorized(address caller) public onlyOwner {
        _authorizedCallers[caller] = true;
    }

    function removeAuthorized(address caller) public onlyOwner {
        _authorizedCallers[caller] = false;
    }

    function getItemData() public view returns (string[][] memory){
        //require(_authorizedCallers[msg.sender] == true, "Unauthorized");
        string[][] memory data;
        data[0] = weapons;
        data[1] = chestArmor;
        data[2] = headArmor;
        data[3] = waistArmor;
        data[4] = footArmor;
        data[5] = handArmor;
        data[6] = necklaces;
        data[7] = rings;
        data[8] = shields;
        data[9] = suffixes;
        data[10] = namePrefixes;
        data[11] = nameSuffixes;

        return data;
    }

    function getWeapons() public view returns (string[] memory) {
        //require(_authorizedCallers[msg.sender] == true, "Unauthorized");
        return weapons;
    }

    function getShields() public view returns (string[] memory) {
        require(_authorizedCallers[msg.sender] == true, "Unauthorized");
        return shields;
    }

    function getChestArmor() public view returns (string[] memory) {
        require(_authorizedCallers[msg.sender] == true, "Unauthorized");
        return chestArmor;
    }

    function getHeadArmor() public view returns (string[] memory) {
        require(_authorizedCallers[msg.sender] == true, "Unauthorized");
        return headArmor;
    }

    function getWaistArmor() public view returns (string[] memory) {
        require(_authorizedCallers[msg.sender] == true, "Unauthorized");
        return waistArmor;
    }

    function getFootArmor() public view returns (string[] memory) {
        require(_authorizedCallers[msg.sender] == true, "Unauthorized");
        return footArmor;
    }

    function getHandArmor() public view returns (string[] memory) {
        require(_authorizedCallers[msg.sender] == true, "Unauthorized");
        return handArmor;
    }

    function getNecklaces() public view returns (string[] memory) {
        require(_authorizedCallers[msg.sender] == true, "Unauthorized");
        return necklaces;
    }

    function getRings() public view returns (string[] memory) {
        require(_authorizedCallers[msg.sender] == true, "Unauthorized");
        return rings;
    }

    function getSuffixes() public view returns (string[] memory) {
        require(_authorizedCallers[msg.sender] == true, "Unauthorized");
        return suffixes;
    }

    function getNamePrefixes() public view returns (string[] memory) {
        require(_authorizedCallers[msg.sender] == true, "Unauthorized");
        return namePrefixes;
    }

    function getNameSuffixes() public view returns (string[] memory) {
        require(_authorizedCallers[msg.sender] == true, "Unauthorized");
        return nameSuffixes;
    }

    string[] private weapons = [
        "Holy Avenger",
        "Master Sword",
        "Crystal Sword",
        "War Scepter",
        "War Sword",
        "War Hammer",
        "Battle Axe",
        "Heavy Mace",
        "Long Sword",
        "Double Axe",
        "Double Flail",
        "Heavy Scepter",
        "Heavy Club",
        "Short Sword",
        "Axe",
        "Flail",
        "Mace",
        "Scepter",
        "Club"
    ];

    string[] private shields = [
        "Blessed Shield",
        "Enchanted Shield",
        "Templar Shield",
        "Ornate Shield",
        "Mirror Shield",
        "War Shield",
        "Crystal Shield",
        "Spiked Shield",
        "Gothic Shield",
        "Tower Shield",
        "Heavy Shield",
        "Thick Shield",
        "Kite Shield",
        "Round Shield",
        "Small Shield",
        "Buckler"
    ];

    string[] private chestArmor = [
        "Templar Armor",
        "Ornate Armor",
        "Gothic Armor",
        "Plate Armor",
        "Bone Armor",
        "Chain Armor",
        "Scale Armor",
        "Ring Armor",
        "Demon Armor",
        "Shark Armor",
        "Studded Armor",
        "Leather Armor",
        "Blue Tunic",
        "Red Tunic",
        "Tunic"
    ];

    string[] private headArmor = [
        "Templar Helm",
        "Ornate Circlet",
        "Gothic Crown",
        "Plate Helm",
        "Bone Helm",
        "Chain Coif",
        "Scale Coif",
        "Ring Coif",
        "Demon Hood",
        "Shark Hat",
        "Studded Hood",
        "Blue Hood",
        "Red Hood",
        "Hood",
        "Cap"
    ];

    string[] private waistArmor = [
        "Templar Belt",
        "Ornate Belt",
        "Gothic Belt",
        "Plate Belt",
        "Bone Belt",
        "Chain Belt",
        "Scale Belt",
        "Ring Belt",
        "Demon Belt",
        "Shark Belt",
        "Studded Belt",
        "Leather Belt",
        "Quilted Belt",
        "Heavy Belt",
        "Belt"
    ];

    string[] private footArmor = [
        "Templar Boots",
        "Ornate Greaves",
        "Gothic Boots",
        "Plate Greaves",
        "Bone Greaves",
        "Chain Boots",
        "Scale Boots",
        "Ring Boots",
        "Demon Boots",
        "Shark Boots",
        "Studded Boots",
        "Blue Boots",
        "Red Boots",
        "Boots",
        "Slippers"
    ];

    string[] private handArmor = [
        "Templar Gauntlets",
        "Ornate Gauntlets",
        "Gothic Gauntlets",
        "Plate Gauntlets",
        "Bone Gauntlets",
        "Chain Gloves",
        "Scale Gloves",
        "Ring Gloves",
        "Demon Gloves",
        "Shark Gloves",
        "Studded Gloves",
        "Blue Gloves",
        "Red Gloves",
        "Leather Gloves",
        "Gloves"
    ];

    string[] private necklaces = ["Amulet", "Pendant", "Beads"];

    string[] private rings = [
        "Diamond Ring",
        "Gold Ring",
        "Silver Ring",
        "Copper Ring",
        "Ring"
    ];

    string[] private suffixes = [
        "of Victory",
        "of Valor",
        "of War",
        "of Wrath",
        "of Battle",
        "of Honor",
        "of Victory",
        "of Command",
        "of Man",
        "of Might",
        "of Power",
        "of Greed",
        "of Skill",
        "of Force",
        "of Pride",
        "of Plague"
    ];

    string[] private namePrefixes = [
        "Death's",
        "Heaven's",
        "Hell's",
        "Keeper's",
        "Believer's",
        "Zealot's",
        "Brigadier's",
        "Heroes",
        "Emperor's",
        "King's",
        "Juggernaut's",
        "Guardian's",
        "Titan's",
        "Giant's",
        "Templar's",
        "Slayer's",
        "Commander's",
        "Grandmaster's",
        "Blademaster's",
        "Vanquisher's",
        "Vindicator's",
        "Knight's",
        "Squire's",
        "Master's",
        "Captain's",
        "Berserker's",
        "Valkyrie's",
        "Crusader's",
        "Paladin's",
        "Swordsman's",
        "Protector's",
        "Victor's",
        "Subjugator's",
        "Conqueror's",
        "Cavalier's",
        "Devotee's",
        "Bishop's",
        "Cavalryman's",
        "Horseman's",
        "Commando's",
        "Warrior's",
        "Noble's",
        "Enthusiast's",
        "Soldier's",
        "Lord's",
        "Nobleman's",
        "Challenger's",
        "Champion's",
        "Balrog's",
        "Dragon's",
        "Wyrm's",
        "Drake's",
        "Griffon's",
        "Officer's",
        "Lieutenant's",
        "Sergeant's",
        "Corporal's",
        "Marshal's",
        "Warden's",
        "Recruit's",
        "Keeper's",
        "Veteran's",
        "Militant's",
        "Partisan's",
        "Hierophant's",
        "Ideologue's",
        "Priest's",
        "Monk's",
        "Fanatic's",
        "Expert's",
        "Hunter's"
    ];

    string[] private nameSuffixes = [
        "Wrath",
        "Faith",
        "Anger",
        "Might",
        "Pride",
        "Lust",
        "Truth",
        "Sin",
        "Revenge",
        "Grudge",
        "Fury",
        "Glory",
        "Temper",
        "Justice",
        "Envy",
        "Prayer",
        "Virtue",
        "Desire",
        "Skill",
        "Ready"
    ];
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
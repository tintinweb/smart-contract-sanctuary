pragma solidity 0.4.25;

// ----------------------------------------------------------------------------
// --- Name        : CropClash - [Crop SHARE]
// --- Symbol      : Format - {CRP}
// --- Total supply: Generated from minter accounts
// --- @Legal      : 
// --- @title for 01101101 01111001 01101100 01101111 01110110 01100101
// --- BlockHaus.Company - EJS32 - 2018-2021
// --- @dev pragma solidity version:0.8.0+commit.661d1103
// --- SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

import "./TomatoSilo.sol";
import "./TomatoFarm.sol";
import "./TomatoFarmRancher.sol";
import "../Common/Upgradable.sol";
import "../Common/SafeMath32.sol";
import "../Common/SafeMath256.sol";

// ----------------------------------------------------------------------------
// --- Contract TomatoFarmhand 
// ----------------------------------------------------------------------------

contract TomatoFarmhand is Upgradable {
    using SafeMath32 for uint32;
    using SafeMath256 for uint256;

    TomatoSilo _silo_;
    TomatoFarm tomatoFarm;
    TomatoFarmRancher rancher;

    uint256 constant BEAN_DECIMALS = 10 ** 18;

    uint256 constant TOMATO_NAME_2_LETTERS_PRICE = 100000 * BEAN_DECIMALS;
    uint256 constant TOMATO_NAME_3_LETTERS_PRICE = 10000 * BEAN_DECIMALS;
    uint256 constant TOMATO_NAME_4_LETTERS_PRICE = 1000 * BEAN_DECIMALS;

    function _checkExistence(uint256 _id) internal view {
        require(_silo_.exists(_id), "tomato doesn't exist");
    }

    function _min(uint32 lth, uint32 rth) internal pure returns (uint32) {
        return lth > rth ? rth : lth;
    }

    function getAmount() external view returns (uint256) {
        return _silo_.length().sub(1);
    }

    function isOwner(address _user, uint256 _tokenId) external view returns (bool) {
        return _user == _silo_.ownerOf(_tokenId);
    }

    function ownerOf(uint256 _tokenId) external view returns (address) {
        return _silo_.ownerOf(_tokenId);
    }

    function getGenome(uint256 _id) public view returns (uint8[30]) {
        _checkExistence(_id);
        return rancher.getActiveGenes(_silo_.getGenome(_id));
    }

    function getComposedGenome(uint256 _id) external view returns (uint256[4]) {
        _checkExistence(_id);
        return _silo_.getGenome(_id);
    }

    function getAbilitys(uint256 _id) external view returns (uint32, uint32, uint32, uint32, uint32) {
        _checkExistence(_id);
        return _silo_.abilitys(_id);
    }

    function getRarity(uint256 _id) public view returns (uint32) {
        _checkExistence(_id);
        return _silo_.rarity(_id);
    }

    function getLevel(uint256 _id) public view returns (uint8 level) {
        _checkExistence(_id);
        (level, , ) = _silo_.levels(_id);
    }

    function getHealthAndRadiation(uint256 _id) external view returns (
        uint256 timestamp,
        uint32 remainingHealth,
        uint32 remainingRadiation,
        uint32 maxHealth,
        uint32 maxRadiation
    ) {
        _checkExistence(_id);
        (
            timestamp,
            remainingHealth,
            remainingRadiation,
            maxHealth,
            maxRadiation
        ) = _silo_.healthAndRadiation(_id);
        (maxHealth, maxRadiation) = tomatoFarm.calculateMaxHealthAndRadiationWithBuffs(_id);

        remainingHealth = _min(remainingHealth, maxHealth);
        remainingRadiation = _min(remainingRadiation, maxRadiation);
    }

    function getCurrentHealthAndRadiation(uint256 _id) external view returns (
        uint32, uint32, uint8, uint8
    ) {
        _checkExistence(_id);
        return tomatoFarm.getCurrentHealthAndRadiation(_id);
    }

    function getFullRegenerationTime(uint256 _id) external view returns (uint32) {
        _checkExistence(_id);
        ( , , , uint32 _maxHealth, ) = _silo_.healthAndRadiation(_id);
        return rancher.calculateFullRegenerationTime(_maxHealth);
    }

    function getTomatoTypes(uint256 _id) external view returns (uint8[11]) {
        _checkExistence(_id);
        return _silo_.getTomatoTypes(_id);
    }

    function getProfile(uint256 _id) external view returns (
        bytes32 name,
        uint16 generation,
        uint256 birth,
        uint8 level,
        uint8 experience,
        uint16 dnaPoints,
        bool isCloningAllowed,
        uint32 rarity
    ) {
        _checkExistence(_id);
        name = _silo_.names(_id);
        (level, experience, dnaPoints) = _silo_.levels(_id);
        isCloningAllowed = tomatoFarm.isCloningAllowed(level, dnaPoints);
        (generation, birth) = _silo_.tomatos(_id);
        rarity = _silo_.rarity(_id);

    }

    function getGeneration(uint256 _id) external view returns (uint16 generation) {
        _checkExistence(_id);
        (generation, ) = _silo_.tomatos(_id);
    }

    function isCloningAllowed(uint256 _id) external view returns (bool) {
        _checkExistence(_id);
        uint8 _level;
        uint16 _dnaPoints;
        (_level, , _dnaPoints) = _silo_.levels(_id);
        return tomatoFarm.isCloningAllowed(_level, _dnaPoints);
    }

    function getTactics(uint256 _id) external view returns (uint8, uint8) {
        _checkExistence(_id);
        return _silo_.tactics(_id);
    }

    function getClashs(uint256 _id) external view returns (uint16, uint16) {
        _checkExistence(_id);
        return _silo_.clashs(_id);
    }

    function getDonors(uint256 _id) external view returns (uint256[2]) {
        _checkExistence(_id);
        return _silo_.getDonors(_id);
    }

    function _getSpecialClashAbility(uint256 _id, uint8 _tomatoType) internal view returns (
        uint32 cost,
        uint8 factor,
        uint8 chance
    ) {
        _checkExistence(_id);
        uint32 _attack;
        uint32 _defense;
        uint32 _stamina;
        uint32 _speed;
        uint32 _intelligence;
        (_attack, _defense, _stamina, _speed, _intelligence) = _silo_.abilitys(_id);
        return rancher.calculateSpecialClashAbility(_tomatoType, [_attack, _defense, _stamina, _speed, _intelligence]);
    }

    function getSpecialAttack(uint256 _id) external view returns (
        uint8 tomatoType,
        uint32 cost,
        uint8 factor,
        uint8 chance
    ) {
        _checkExistence(_id);
        tomatoType = _silo_.specialAttacks(_id);
        (cost, factor, chance) = _getSpecialClashAbility(_id, tomatoType);
    }

    function getSpecialDefense(uint256 _id) external view returns (
        uint8 tomatoType,
        uint32 cost,
        uint8 factor,
        uint8 chance
    ) {
        _checkExistence(_id);
        tomatoType = _silo_.specialDefenses(_id);
        (cost, factor, chance) = _getSpecialClashAbility(_id, tomatoType);
    }

    function getSpecialPeacefulAbility(uint256 _id) external view returns (uint8, uint32, uint32) {
        _checkExistence(_id);
        return tomatoFarm.calculateSpecialPeacefulAbility(_id);
    }

    function getBuffs(uint256 _id) external view returns (uint32[5]) {
        _checkExistence(_id);
        return [
            _silo_.buffs(_id, 1), // attack
            _silo_.buffs(_id, 2), // defense
            _silo_.buffs(_id, 3), // stamina
            _silo_.buffs(_id, 4), // speed
            _silo_.buffs(_id, 5)  // intelligence
        ];
    }

    function getTomatoStrength(uint256 _id) external view returns (uint32 sum) {
        _checkExistence(_id);
        uint32 _attack;
        uint32 _defense;
        uint32 _stamina;
        uint32 _speed;
        uint32 _intelligence;
        (_attack, _defense, _stamina, _speed, _intelligence) = _silo_.abilitys(_id);
        sum = sum.add(_attack.mul(69));
        sum = sum.add(_defense.mul(217));
        sum = sum.add(_stamina.mul(232));
        sum = sum.add(_speed.mul(114));
        sum = sum.add(_intelligence.mul(151));
        sum = sum.div(100);
    }

    function getTomatoNamePriceByLength(uint256 _length) external pure returns (uint256) {
        if (_length == 2) {
            return TOMATO_NAME_2_LETTERS_PRICE;
        } else if (_length == 3) {
            return TOMATO_NAME_3_LETTERS_PRICE;
        } else {
            return TOMATO_NAME_4_LETTERS_PRICE;
        }
    }

    function getTomatoNamePrices() external pure returns (uint8[3] lengths, uint256[3] prices) {
        lengths = [2, 3, 4];
        prices = [
            TOMATO_NAME_2_LETTERS_PRICE,
            TOMATO_NAME_3_LETTERS_PRICE,
            TOMATO_NAME_4_LETTERS_PRICE
        ];
    }

    function setInternalDependencies(address[] _newDependencies) public onlyOwner {
        super.setInternalDependencies(_newDependencies);

        _silo_ = TomatoSilo(_newDependencies[0]);
        tomatoFarm = TomatoFarm(_newDependencies[1]);
        rancher = TomatoFarmRancher(_newDependencies[2]);
    }
}

pragma solidity 0.4.25;

// ----------------------------------------------------------------------------
// --- Name        : CropClash - [Crop SHARE]
// --- Symbol      : Format - {CRP}
// --- Total supply: Generated from minter accounts
// --- @Legal      : 
// --- @title for 01101101 01111001 01101100 01101111 01110110 01100101
// --- BlockHaus.Company - EJS32 - 2018-2021
// --- @dev pragma solidity version:0.8.0+commit.661d1103
// --- SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

import "../Common/ERC721/ERC721Token.sol";
import "./TomatoModel.sol";

// ----------------------------------------------------------------------------
// --- Contract TomatoSilo 
// ----------------------------------------------------------------------------

contract TomatoSilo is TomatoModel, ERC721Token {
    Tomato[] public tomatos;
    mapping (bytes32 => bool) public existingNames;
    mapping (uint256 => bytes32) public names;
    mapping (uint256 => HealthAndRadiation) public healthAndRadiation;
    mapping (uint256 => Tactics) public tactics;
    mapping (uint256 => Clashs) public clashs;
    mapping (uint256 => Abilitys) public abilitys;
    mapping (uint256 => Level) public levels;
    mapping (uint256 => uint32) public rarity; 
    mapping (uint256 => uint8) public specialAttacks;
    mapping (uint256 => uint8) public specialDefenses;
    mapping (uint256 => uint8) public specialPeacefulAbilitys;
    mapping (uint256 => mapping (uint8 => uint32)) public buffs;

    constructor(string _name, string _symbol) public ERC721Token(_name, _symbol) {
        tomatos.length = 1; 
    }

    function length() external view returns (uint256) {
        return tomatos.length;
    }

    function getGenome(uint256 _id) external view returns (uint256[4]) {
        return tomatos[_id].genome;
    }

    function getDonors(uint256 _id) external view returns (uint256[2]) {
        return tomatos[_id].donors;
    }

    function getTomatoTypes(uint256 _id) external view returns (uint8[11]) {
        return tomatos[_id].types;
    }

    function push(
        address _sender,
        uint16 _generation,
        uint256[4] _genome,
        uint256[2] _donors,
        uint8[11] _types
    ) public onlyFarmer returns (uint256 id) {
        id = tomatos.push(Tomato({
            generation: _generation,
            genome: _genome,
            donors: _donors,
            types: _types,
            birth: now 
        })).sub(1);
        _mint(_sender, id);
    }

    function setName(
        uint256 _id,
        bytes32 _name,
        bytes32 _lowercase
    ) external onlyFarmer {
        names[_id] = _name;
        existingNames[_lowercase] = true;
    }

    function setTactics(uint256 _id, uint8 _melee, uint8 _attack) external onlyFarmer {
        tactics[_id].melee = _melee;
        tactics[_id].attack = _attack;
    }

    function setWins(uint256 _id, uint16 _value) external onlyFarmer {
        clashs[_id].wins = _value;
    }

    function setDefeats(uint256 _id, uint16 _value) external onlyFarmer {
        clashs[_id].defeats = _value;
    }

    function setMaxHealthAndRadiation(
        uint256 _id,
        uint32 _maxHealth,
        uint32 _maxRadiation
    ) external onlyFarmer {
        healthAndRadiation[_id].maxHealth = _maxHealth;
        healthAndRadiation[_id].maxRadiation = _maxRadiation;
    }

    function setReprimeingHealthAndRadiation(
        uint256 _id,
        uint32 _remainingHealth,
        uint32 _remainingRadiation
    ) external onlyFarmer {
        healthAndRadiation[_id].timestamp = now; 
        healthAndRadiation[_id].remainingHealth = _remainingHealth;
        healthAndRadiation[_id].remainingRadiation = _remainingRadiation;
    }

    function resetHealthAndRadiationTimestamp(uint256 _id) external onlyFarmer {
        healthAndRadiation[_id].timestamp = 0;
    }

    function setAbilitys(
        uint256 _id,
        uint32 _attack,
        uint32 _defense,
        uint32 _stamina,
        uint32 _speed,
        uint32 _intelligence
    ) external onlyFarmer {
        abilitys[_id].attack = _attack;
        abilitys[_id].defense = _defense;
        abilitys[_id].stamina = _stamina;
        abilitys[_id].speed = _speed;
        abilitys[_id].intelligence = _intelligence;
    }

    function setLevel(uint256 _id, uint8 _level, uint8 _experience, uint16 _dnaPoints) external onlyFarmer {
        levels[_id].level = _level;
        levels[_id].experience = _experience;
        levels[_id].dnaPoints = _dnaPoints;
    }

    function setRarity(uint256 _id, uint32 _rarity) external onlyFarmer {
        rarity[_id] = _rarity;
    }

    function setGenome(uint256 _id, uint256[4] _genome) external onlyFarmer {
        tomatos[_id].genome = _genome;
    }

    function setSpecialAttack(
        uint256 _id,
        uint8 _tomatoType
    ) external onlyFarmer {
        specialAttacks[_id] = _tomatoType;
    }

    function setSpecialDefense(
        uint256 _id,
        uint8 _tomatoType
    ) external onlyFarmer {
        specialDefenses[_id] = _tomatoType;
    }

    function setSpecialPeacefulAbility(
        uint256 _id,
        uint8 _class
    ) external onlyFarmer {
        specialPeacefulAbilitys[_id] = _class;
    }

    function setBuff(uint256 _id, uint8 _class, uint32 _effect) external onlyFarmer {
        buffs[_id][_class] = _effect;
    }
}

pragma solidity 0.4.25;

// ----------------------------------------------------------------------------
// --- Name        : CropClash - [Crop SHARE]
// --- Symbol      : Format - {CRP}
// --- Total supply: Generated from minter accounts
// --- @Legal      : 
// --- @title for 01101101 01111001 01101100 01101111 01110110 01100101
// --- BlockHaus.Company - EJS32 - 2018-2021
// --- @dev pragma solidity version:0.8.0+commit.661d1103
// --- SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

import "./TomatoFarmhouse.sol";
import "../Common/SafeMath16.sol";

// ----------------------------------------------------------------------------
// --- Contract TomatoFarm 
// ----------------------------------------------------------------------------

contract TomatoFarm is TomatoFarmhouse {
    using SafeMath16 for uint16;
    uint8 constant MAX_LEVEL = 10; 
    uint8 constant MAX_TACTICS_PERCENTAGE = 80;
    uint8 constant MIN_TACTICS_PERCENTAGE = 20;
    uint8 constant MAX_GENE_LVL = 99;
    uint8 constant NUMBER_OF_SPECIAL_PEACEFUL_SKILL_CLASSES = 8; 

    function isCloningAllowed(uint8 _level, uint16 _dnaPoints) public view returns (bool) {
        return _level > 0 && _dnaPoints >= specs.dnaPoints(_level);
    }

    function _checkIfEnoughPoints(bool _isEnough) internal pure {
        require(_isEnough, "not enough points");
    }

    function _validateSpecialPeacefulAbilityClass(uint8 _class) internal pure {
        require(_class > 0 && _class < NUMBER_OF_SPECIAL_PEACEFUL_SKILL_CLASSES, "wrong class of special peaceful ability");
    }

    function _checkIfSpecialPeacefulAbilityAvailable(bool _isAvailable) internal pure {
        require(_isAvailable, "special peaceful ability selection is not available");
    }

    function _getBuff(uint256 _id, uint8 _class) internal view returns (uint32) {
        return _silo_.buffs(_id, _class);
    }

    function _getAllBuffs(uint256 _id) internal view returns (uint32[5]) {
        return [
            _getBuff(_id, 1),
            _getBuff(_id, 2),
            _getBuff(_id, 3),
            _getBuff(_id, 4),
            _getBuff(_id, 5)
        ];
    }

    function calculateMaxHealthAndRadiationWithBuffs(uint256 _id) public view returns (
        uint32 maxHealth,
        uint32 maxRadiation
    ) {
        (, , uint32 _stamina, , uint32 _intelligence) = _silo_.abilitys(_id);

        (
            maxHealth,
            maxRadiation
        ) = rancher.calculateHealthAndRadiation(
            _stamina,
            _intelligence,
            _getBuff(_id, 3), 
            _getBuff(_id, 5) 
        );
    }

    function getCurrentHealthAndRadiation(uint256 _id) public view returns (
        uint32 health,
        uint32 radiation,
        uint8 healthPercentage,
        uint8 radiationPercentage
    ) {
        (
            uint256 _timestamp,
            uint32 _remainingHealth,
            uint32 _remainingRadiation,
            uint32 _maxHealth,
            uint32 _maxRadiation
        ) = _silo_.healthAndRadiation(_id);

        (_maxHealth, _maxRadiation) = calculateMaxHealthAndRadiationWithBuffs(_id);

        uint256 _pastTime = now.sub(_timestamp); 
        (health, healthPercentage) = rancher.calculateCurrent(_pastTime, _maxHealth, _remainingHealth);
        (radiation, radiationPercentage) = rancher.calculateCurrent(_pastTime, _maxRadiation, _remainingRadiation);
    }

    function setReprimeingHealthAndRadiation(
        uint256 _id,
        uint32 _remainingHealth,
        uint32 _remainingRadiation
    ) external onlyFarmer {
        _silo_.setReprimeingHealthAndRadiation(_id, _remainingHealth, _remainingRadiation);
    }

    function increaseExperience(uint256 _id, uint256 _factor) external onlyFarmer {
        (
            uint8 _level,
            uint256 _experience,
            uint16 _dnaPoints
        ) = _silo_.levels(_id);
        uint8 _currentLevel = _level;
        if (_level < MAX_LEVEL) {
            (_level, _experience, _dnaPoints) = rancher.calculateExperience(_level, _experience, _dnaPoints, _factor);
            if (_level > _currentLevel) {
                _silo_.resetHealthAndRadiationTimestamp(_id);
            }
            if (_level == MAX_LEVEL) {
                _experience = 0;
            }
            _silo_.setLevel(_id, _level, _experience.toUint8(), _dnaPoints);
        }
    }

    function payDNAPointsForCloning(uint256 _id) external onlyFarmer {
        (
            uint8 _level,
            uint8 _experience,
            uint16 _dnaPoints
        ) = _silo_.levels(_id);

        _checkIfEnoughPoints(isCloningAllowed(_level, _dnaPoints));
        _dnaPoints = _dnaPoints.sub(specs.dnaPoints(_level));

        _silo_.setLevel(_id, _level, _experience, _dnaPoints);
    }

    function upgradeGenes(uint256 _id, uint16[10] _dnaPoints) external onlyFarmer {
        (
            uint8 _level,
            uint8 _experience,
            uint16 _availableDNAPoints
        ) = _silo_.levels(_id);

        uint16 _sum;
        uint256[4] memory _newComposedGenome;
        (
            _newComposedGenome,
            _sum
        ) = rancher.upgradeGenes(
            _silo_.getGenome(_id),
            _dnaPoints,
            _availableDNAPoints
        );

        require(_sum > 0, "DNA points were not used");

        _availableDNAPoints = _availableDNAPoints.sub(_sum);
        _silo_.setLevel(_id, _level, _experience, _availableDNAPoints);
        _silo_.setGenome(_id, _newComposedGenome);
        _silo_.setRarity(_id, rancher.calculateRarity(_newComposedGenome));
        _saveAbilitys(_id, _newComposedGenome);
    }

    function _saveAbilitys(uint256 _id, uint256[4] _genome) internal {
        (
            uint32 _attack,
            uint32 _defense,
            uint32 _stamina,
            uint32 _speed,
            uint32 _intelligence
        ) = rancher.calculateAbilitys(_genome);
        (
            uint32 _health,
            uint32 _radiation
        ) = rancher.calculateHealthAndRadiation(_stamina, _intelligence, 0, 0); 

        _silo_.setMaxHealthAndRadiation(_id, _health, _radiation);
        _silo_.setAbilitys(_id, _attack, _defense, _stamina, _speed, _intelligence);
    }

    function increaseWins(uint256 _id) external onlyFarmer {
        (uint16 _wins, ) = _silo_.clashs(_id);
        _silo_.setWins(_id, _wins.add(1));
    }

    function increaseDefeats(uint256 _id) external onlyFarmer {
        (, uint16 _defeats) = _silo_.clashs(_id);
        _silo_.setDefeats(_id, _defeats.add(1));
    }

    function setTactics(uint256 _id, uint8 _melee, uint8 _attack) external onlyFarmer {
        require(
            _melee >= MIN_TACTICS_PERCENTAGE &&
            _melee <= MAX_TACTICS_PERCENTAGE &&
            _attack >= MIN_TACTICS_PERCENTAGE &&
            _attack <= MAX_TACTICS_PERCENTAGE,
            "tactics value must be between 20 and 80"
        );
        _silo_.setTactics(_id, _melee, _attack);
    }

    function calculateSpecialPeacefulAbility(uint256 _id) public view returns (
        uint8 class,
        uint32 cost,
        uint32 effect
    ) {
        class = _silo_.specialPeacefulAbilitys(_id);
        if (class == 0) return;
        (
            uint32 _attack,
            uint32 _defense,
            uint32 _stamina,
            uint32 _speed,
            uint32 _intelligence
        ) = _silo_.abilitys(_id);

        (
            cost,
            effect
        ) = rancher.calculateSpecialPeacefulAbility(
            class,
            [_attack, _defense, _stamina, _speed, _intelligence],
            _getAllBuffs(_id)
        );
    }

    function setSpecialPeacefulAbility(uint256 _id, uint8 _class) external onlyFarmer {
        (uint8 _level, , ) = _silo_.levels(_id);
        uint8 _currentClass = _silo_.specialPeacefulAbilitys(_id);

        _checkIfSpecialPeacefulAbilityAvailable(_level == MAX_LEVEL);
        _validateSpecialPeacefulAbilityClass(_class);
        _checkIfSpecialPeacefulAbilityAvailable(_currentClass == 0);

        _silo_.setSpecialPeacefulAbility(_id, _class);
    }

    function _getBuffIndexBySpecialPeacefulAbilityClass(
        uint8 _class
    ) internal pure returns (uint8) {
        uint8[8] memory _buffsIndexes = [0, 1, 2, 3, 4, 5, 3, 5]; 
        return _buffsIndexes[_class];
    }

    function useSpecialPeacefulAbility(address _sender, uint256 _id, uint256 _target) external onlyFarmer {
        (
            uint8 _class,
            uint32 _cost,
            uint32 _effect
        ) = calculateSpecialPeacefulAbility(_id);
        (
            uint32 _health,
            uint32 _radiation, ,
        ) = getCurrentHealthAndRadiation(_id);

        _validateSpecialPeacefulAbilityClass(_class);
        _checkIfEnoughPoints(_radiation >= _cost);
        _silo_.setReprimeingHealthAndRadiation(_id, _health, _radiation.sub(_cost));
        _silo_.setBuff(_id, 5, 0);
        uint8 _buffIndexOfActiveAbility = _getBuffIndexBySpecialPeacefulAbilityClass(_class);
        _silo_.setBuff(_id, _buffIndexOfActiveAbility, 0);

        if (_class == 6 || _class == 7) { 
            (
                uint32 _targetHealth,
                uint32 _targetRadiation, ,
            ) = getCurrentHealthAndRadiation(_target);
            if (_class == 6) _targetHealth = _targetHealth.add(_effect); 
            if (_class == 7) _targetRadiation = _targetRadiation.add(_effect); 
            _silo_.setReprimeingHealthAndRadiation(
                _target,
                _targetHealth,
                _targetRadiation
            );
        } else { 
            if (_silo_.ownerOf(_target) != _sender) { 
                require(_getBuff(_target, _class) < _effect, "you can't buff alien tomato by lower effect");
            }
            _silo_.setBuff(_target, _class, _effect);
        }
    }

    function setBuff(uint256 _id, uint8 _class, uint32 _effect) external onlyFarmer {
        _silo_.setBuff(_id, _class, _effect);
    }

    function createTomato(
        address _sender,
        uint16 _generation,
        uint256[2] _donors,
        uint256[4] _genome,
        uint8[11] _tomatoTypes
    ) external onlyFarmer returns (uint256 newTomatoId) {
        newTomatoId = _silo_.push(_sender, _generation, _genome, _donors, _tomatoTypes);
        uint32 _rarity = rancher.calculateRarity(_genome);
        _silo_.setRarity(newTomatoId, _rarity);
        _silo_.setTactics(newTomatoId, 50, 50);
        _setAbilitysAndHealthAndRadiation(newTomatoId, _genome, _tomatoTypes);
    }

    function setName(
        uint256 _id,
        string _name
    ) external onlyFarmer returns (bytes32) {
        (
            bytes32 _initial, 
            bytes32 _lowercase 
        ) = rancher.checkAndConvertName(_name);
        require(!_silo_.existingNames(_lowercase), "name exists");
        require(_silo_.names(_id) == 0x0, "tomato already has a name");
        _silo_.setName(_id, _initial, _lowercase);
        return _initial;
    }
}

pragma solidity 0.4.25;

// ----------------------------------------------------------------------------
// --- Name        : CropClash - [Crop SHARE]
// --- Symbol      : Format - {CRP}
// --- Total supply: Generated from minter accounts
// --- @Legal      : 
// --- @title for 01101101 01111001 01101100 01101111 01110110 01100101
// --- BlockHaus.Company - EJS32 - 2018-2021
// --- @dev pragma solidity version:0.8.0+commit.661d1103
// --- SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

import "./TomatoUtils.sol";
import "./TomatoSpecs.sol";
import "../Common/Name.sol";
import "../Common/Upgradable.sol";
import "../Common/SafeMath16.sol";
import "../Common/SafeMath32.sol";
import "../Common/SafeMath256.sol";
import "../Common/SafeConvert.sol";

// ----------------------------------------------------------------------------
// --- Contract TomatoFarmRancher 
// ----------------------------------------------------------------------------

contract TomatoFarmRancher is Upgradable, TomatoUtils, Name {
    using SafeMath16 for uint16;
    using SafeMath32 for uint32;
    using SafeMath256 for uint256;
    using SafeConvert for uint32;
    using SafeConvert for uint256;

    TomatoSpecs specs;

    uint8 constant PERCENT_MULTIPLIER = 100;
    uint8 constant MAX_PERCENTAGE = 100;

    uint8 constant MAX_GENE_LVL = 99;

    uint8 constant MAX_LEVEL = 10;

    function _min(uint32 lth, uint32 rth) internal pure returns (uint32) {
        return lth > rth ? rth : lth;
    }

    function _calculateAbilityWithBuff(uint32 _ability, uint32 _buff) internal pure returns (uint32) {
        return _buff > 0 ? _ability.mul(_buff).div(100) : _ability; 
    }

    function _calculateRegenerationSpeed(uint32 _max) internal pure returns (uint32) {
        // because HP/radiation is multiplied by 100 so we need to have step multiplied by 100 too
        return _sqrt(_max.mul(100)).div(2).div(1 minutes); 
    }

    function calculateFullRegenerationTime(uint32 _max) external pure returns (uint32) { 
        return _max.div(_calculateRegenerationSpeed(_max));
    }

    function calculateCurrent(
        uint256 _pastTime,
        uint32 _max,
        uint32 _remaining
    ) external pure returns (
        uint32 current,
        uint8 percentage
    ) {
        if (_remaining >= _max) {
            return (_max, MAX_PERCENTAGE);
        }
        uint32 _speed = _calculateRegenerationSpeed(_max); 
        uint32 _secondsToFull = _max.sub(_remaining).div(_speed); 
        uint32 _secondsPassed = _pastTime.toUint32();
        if (_secondsPassed >= _secondsToFull.add(1)) {
            return (_max, MAX_PERCENTAGE); 
        }
        current = _min(_max, _remaining.add(_speed.mul(_secondsPassed)));
        percentage = _min(MAX_PERCENTAGE, current.mul(PERCENT_MULTIPLIER).div(_max)).toUint8();
    }

    function calculateHealthAndRadiation(
        uint32 _initStamina,
        uint32 _initIntelligence,
        uint32 _staminaBuff,
        uint32 _intelligenceBuff
    ) external pure returns (uint32 health, uint32 radiation) {
        uint32 _stamina = _initStamina;
        uint32 _intelligence = _initIntelligence;

        _stamina = _calculateAbilityWithBuff(_stamina, _staminaBuff);
        _intelligence = _calculateAbilityWithBuff(_intelligence, _intelligenceBuff);

        health = _stamina.mul(5);
        radiation = _intelligence.mul(5);
    }

    function _sqrt(uint32 x) internal pure returns (uint32 y) {
        uint32 z = x.add(1).div(2);
        y = x;
        while (z < y) {
            y = z;
            z = x.div(z).add(z).div(2);
        }
    }

    function getSpecialClashAbilityTomatoType(uint8[11] _tomatoTypes, uint256 _random) external pure returns (uint8 abilityTomatoType) {
        uint256 _currentChance;
        for (uint8 i = 0; i < 11; i++) {
            _currentChance = _currentChance.add(_tomatoTypes[i]);
            if (_random < _currentChance) {
                abilityTomatoType = i;
                break;
            }
        }
    }

    function _getFarmhouseAbilityIndex(uint8 _tomatoType) internal pure returns (uint8) {
        uint8[5] memory _abilitys = [2, 0, 3, 1, 4];
        return _abilitys[_tomatoType];
    }

    function calculateSpecialClashAbility(
        uint8 _tomatoType,
        uint32[5] _abilitys
    ) external pure returns (
        uint32 cost,
        uint8 factor,
        uint8 chance
    ) {
        uint32 _farmhouseAbility = _abilitys[_getFarmhouseAbilityIndex(_tomatoType)];
        uint32 _intelligence = _abilitys[4];

        cost = _farmhouseAbility.mul(3);
        factor = _sqrt(_farmhouseAbility.div(3)).add(10).toUint8();
        chance = _sqrt(_intelligence).div(10).add(10).toUint8();
    }

    function _getAbilityIndexBySpecialPeacefulAbilityClass(
        uint8 _class
    ) internal pure returns (uint8) {
        uint8[8] memory _buffsIndexes = [0, 0, 1, 2, 3, 4, 2, 4]; 
        return _buffsIndexes[_class];
    }

    function calculateSpecialPeacefulAbility(
        uint8 _class,
        uint32[5] _abilitys,
        uint32[5] _buffs
    ) external pure returns (uint32 cost, uint32 effect) {
        uint32 _index = _getAbilityIndexBySpecialPeacefulAbilityClass(_class);
        uint32 _ability = _calculateAbilityWithBuff(_abilitys[_index], _buffs[_index]);
        if (_class == 6 || _class == 7) { 
            effect = _ability.mul(2);
        } else {
            effect = _sqrt(_ability.mul(10).div(3)).add(100);
        }
        cost = _ability.mul(3);
    }

    function _getGeneVarietyFactor(uint8 _type) internal pure returns (uint32 value) {
        if (_type == 0) value = 5;
        else if (_type < 5) value = 12;
        else if (_type < 8) value = 16;
        else value = 28;
    }

    function calculateRarity(uint256[4] _composedGenome) external pure returns (uint32 rarity) {
        uint8[16][10] memory _genome = _parseGenome(_composedGenome);
        uint32 _geneVarietyFactor; 
        uint8 _strengthCoefficient; 
        uint8 _geneLevel;
        for (uint8 i = 0; i < 10; i++) {
            for (uint8 j = 0; j < 4; j++) {
                _geneVarietyFactor = _getGeneVarietyFactor(_genome[i][(j * 4) + 1]);
                _strengthCoefficient = (_genome[i][(j * 4) + 3] == 0) ? 7 : 10; 
                _geneLevel = _genome[i][(j * 4) + 2];
                rarity = rarity.add(_geneVarietyFactor.mul(_geneLevel).mul(_strengthCoefficient));
            }
        }
    }

    function calculateAbilitys(
        uint256[4] _composed
    ) external view returns (
        uint32, uint32, uint32, uint32, uint32
    ) {
        uint8[30] memory _activeGenes = _getActiveGenes(_parseGenome(_composed));
        uint8[5] memory _tomatoTypeFactors;
        uint8[5] memory _bodyPartFactors;
        uint8[5] memory _geneTypeFactors;
        uint8 _level;
        uint32[5] memory _abilitys;

        for (uint8 i = 0; i < 10; i++) {
            _bodyPartFactors = specs.bodyPartsFactors(i);
            _tomatoTypeFactors = specs.tomatoTypesFactors(_activeGenes[i * 3]);
            _geneTypeFactors = specs.geneTypesFactors(_activeGenes[i * 3 + 1]);
            _level = _activeGenes[i * 3 + 2];

            for (uint8 j = 0; j < 5; j++) {
                _abilitys[j] = _abilitys[j].add(uint32(_tomatoTypeFactors[j]).mul(_bodyPartFactors[j]).mul(_geneTypeFactors[j]).mul(_level));
            }
        }
        return (_abilitys[0], _abilitys[1], _abilitys[2], _abilitys[3], _abilitys[4]);
    }

    function calculateExperience(
        uint8 _level,
        uint256 _experience,
        uint16 _dnaPoints,
        uint256 _factor
    ) external view returns (
        uint8 level,
        uint256 experience,
        uint16 dnaPoints
    ) {
        level = _level;
        experience = _experience;
        dnaPoints = _dnaPoints;

        uint8 _expToNextLvl;
        experience = experience.add(uint256(specs.clashPoints()).mul(_factor).div(10));
        _expToNextLvl = specs.experienceToNextLevel(level);
        while (experience >= _expToNextLvl && level < MAX_LEVEL) {
            experience = experience.sub(_expToNextLvl);
            level = level.add(1);
            dnaPoints = dnaPoints.add(specs.dnaPoints(level));
            if (level < MAX_LEVEL) {
                _expToNextLvl = specs.experienceToNextLevel(level);
            }
        }
    }

    function checkAndConvertName(string _input) external pure returns(bytes32, bytes32) {
        return _convertName(_input);
    }

    function _checkIfEnoughDNAPoints(bool _isEnough) internal pure {
        require(_isEnough, "not enough DNA points for upgrade");
    }

    function upgradeGenes(
        uint256[4] _composedGenome,
        uint16[10] _dnaPoints,
        uint16 _availableDNAPoints
    ) external view returns (
        uint256[4],
        uint16
    ) {
        uint16 _sum;
        uint8 _i;
        for (_i = 0; _i < 10; _i++) {
            _checkIfEnoughDNAPoints(_dnaPoints[_i] <= _availableDNAPoints);
            _sum = _sum.add(_dnaPoints[_i]);
        }
        _checkIfEnoughDNAPoints(_sum <= _availableDNAPoints);
        _sum = 0;

        uint8[16][10] memory _genome = _parseGenome(_composedGenome);
        uint8 _geneLevelIndex;
        uint8 _geneLevel;
        uint16 _geneUpgradeDNAPoints;
        uint8 _levelsToUpgrade;
        uint16 _specificDNAPoints;
        for (_i = 0; _i < 10; _i++) {
            _specificDNAPoints = _dnaPoints[_i]; 
            if (_specificDNAPoints > 0) {
                _geneLevelIndex = _getActiveGeneIndex(_genome[_i]).mul(4).add(2); 
                _geneLevel = _genome[_i][_geneLevelIndex]; 
                if (_geneLevel < MAX_GENE_LVL) {
                    _geneUpgradeDNAPoints = specs.geneUpgradeDNAPoints(_geneLevel);
                    while (_specificDNAPoints >= _geneUpgradeDNAPoints && _geneLevel.add(_levelsToUpgrade) < MAX_GENE_LVL) {
                        _levelsToUpgrade = _levelsToUpgrade.add(1);
                        _specificDNAPoints = _specificDNAPoints.sub(_geneUpgradeDNAPoints);
                        _sum = _sum.add(_geneUpgradeDNAPoints); // the sum of used points
                        if (_geneLevel.add(_levelsToUpgrade) < MAX_GENE_LVL) {
                            _geneUpgradeDNAPoints = specs.geneUpgradeDNAPoints(_geneLevel.add(_levelsToUpgrade));
                        }
                    }
                    _genome[_i][_geneLevelIndex] = _geneLevel.add(_levelsToUpgrade); 
                    _levelsToUpgrade = 0;
                }
            }
        }
        return (_composeGenome(_genome), _sum);
    }

    function getActiveGenes(uint256[4] _composed) external pure returns (uint8[30]) {
        uint8[16][10] memory _genome = _parseGenome(_composed);
        return _getActiveGenes(_genome);
    }

    function setInternalDependencies(address[] _newDependencies) public onlyOwner {
        super.setInternalDependencies(_newDependencies);

        specs = TomatoSpecs(_newDependencies[0]);
    }
}

pragma solidity 0.4.25;

// ----------------------------------------------------------------------------
// --- Name        : CropClash - [Crop SHARE]
// --- Symbol      : Format - {CRP}
// --- Total supply: Generated from minter accounts
// --- @Legal      : 
// --- @title for 01101101 01111001 01101100 01101111 01110110 01100101
// --- BlockHaus.Company - EJS32 - 2018-2021
// --- @dev pragma solidity version:0.8.0+commit.661d1103
// --- SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

import "./Controllable.sol";

// ----------------------------------------------------------------------------
// --- Contract Upgradable 
// ----------------------------------------------------------------------------

contract Upgradable is Controllable {
    address[] internalDependencies;
    address[] externalDependencies;

    function getInternalDependencies() public view returns(address[]) {
        return internalDependencies;
    }

    function getExternalDependencies() public view returns(address[]) {
        return externalDependencies;
    }

    function setInternalDependencies(address[] _newDependencies) public onlyOwner {
        for (uint256 i = 0; i < _newDependencies.length; i++) {
            _validateAddress(_newDependencies[i]);
        }
        internalDependencies = _newDependencies;
    }

    function setExternalDependencies(address[] _newDependencies) public onlyOwner {
        _setFarmers(externalDependencies, false); 
        externalDependencies = _newDependencies;
        _setFarmers(_newDependencies, true);
    }
}

pragma solidity 0.4.25;

// ----------------------------------------------------------------------------
// --- Name        : CropClash - [Crop SHARE]
// --- Symbol      : Format - {CRP}
// --- Total supply: Generated from minter accounts
// --- @Legal      : 
// --- @title for 01101101 01111001 01101100 01101111 01110110 01100101
// --- BlockHaus.Company - EJS32 - 2018-2021
// --- @dev pragma solidity version:0.8.0+commit.661d1103
// --- SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

library SafeMath32 {

    function mul(uint32 a, uint32 b) internal pure returns (uint32) {
        if (a == 0) {
            return 0;
        }
        uint32 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint32 a, uint32 b) internal pure returns (uint32) {
        return a / b;
    }

    function sub(uint32 a, uint32 b) internal pure returns (uint32) {
        assert(b <= a);
        return a - b;
    }

    function add(uint32 a, uint32 b) internal pure returns (uint32) {
        uint32 c = a + b;
        assert(c >= a);
        return c;
    }

    function pow(uint32 a, uint32 b) internal pure returns (uint32) {
        if (a == 0) return 0;
        if (b == 0) return 1;

        uint32 c = a ** b;
        assert(c / (a ** (b - 1)) == a);
        return c;
    }
}

pragma solidity 0.4.25;

// ----------------------------------------------------------------------------
// --- Name        : CropClash - [Crop SHARE]
// --- Symbol      : Format - {CRP}
// --- Total supply: Generated from minter accounts
// --- @Legal      : 
// --- @title for 01101101 01111001 01101100 01101111 01110110 01100101
// --- BlockHaus.Company - EJS32 - 2018-2021
// --- @dev pragma solidity version:0.8.0+commit.661d1103
// --- SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

library SafeMath256 {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function pow(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        if (b == 0) return 1;

        uint256 c = a ** b;
        assert(c / (a ** (b - 1)) == a);
        return c;
    }
}

pragma solidity 0.4.25;

// ----------------------------------------------------------------------------
// --- Name        : CropClash - [Crop SHARE]
// --- Symbol      : Format - {CRP}
// --- Total supply: Generated from minter accounts
// --- @Legal      : 
// --- @title for 01101101 01111001 01101100 01101111 01110110 01100101
// --- BlockHaus.Company - EJS32 - 2018-2021
// --- @dev pragma solidity version:0.8.0+commit.661d1103
// --- SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

import "./ERC721.sol";
import "./ERC721BasicToken.sol";

// ----------------------------------------------------------------------------
// --- Contract ERC721Token 
// ----------------------------------------------------------------------------

contract ERC721Token is ERC721, ERC721BasicToken {

    bytes4 internal constant INTERFACE_SIGNATURE_ERC165 = 0x01ffc9a7;
    bytes4 internal constant INTERFACE_SIGNATURE_ERC721 = 0x80ac58cd;
    bytes4 internal constant INTERFACE_SIGNATURE_ERC721TokenReceiver = 0xf0b9e5ba;
    bytes4 internal constant INTERFACE_SIGNATURE_ERC721Metadata = 0x5b5e139f;
    bytes4 internal constant INTERFACE_SIGNATURE_ERC721Enumerable = 0x780e9d63;

    string internal name_;
    string internal symbol_;

    mapping (address => uint256[]) internal ownedTokens;
    mapping(uint256 => uint256) internal ownedTokensIndex;
    uint256[] internal allTokens;
    mapping(uint256 => uint256) internal allTokensIndex;
    mapping(uint256 => string) internal tokenURIs;

    string public url;

    constructor(string _name, string _symbol) public {
        name_ = _name;
        symbol_ = _symbol;
    }

    function name() public view returns (string) {
        return name_;
    }

    function symbol() public view returns (string) {
        return symbol_;
    }

    function _validateIndex(bool _isValid) internal pure {
        require(_isValid, "wrong index");
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256) {
        _validateIndex(_index < balanceOf(_owner));
        return ownedTokens[_owner][_index];
    }

    function tokensOfOwner(address _owner) external view returns (uint256[]) {
        return ownedTokens[_owner];
    }

    function getAllTokens() external view returns (uint256[]) {
        return allTokens;
    }

    function totalSupply() public view returns (uint256) {
        return allTokens.length;
    }

    function tokenByIndex(uint256 _index) public view returns (uint256) {
        _validateIndex(_index < totalSupply());
        return allTokens[_index];
    }

    function addTokenTo(address _to, uint256 _tokenId) internal {
        super.addTokenTo(_to, _tokenId);
        uint256 length = ownedTokens[_to].length;
        ownedTokens[_to].push(_tokenId);
        ownedTokensIndex[_tokenId] = length;
    }

    function removeTokenFrom(address _from, uint256 _tokenId) internal {
        _checkThatUserHasTokens(ownedTokens[_from].length > 0);

        super.removeTokenFrom(_from, _tokenId);

        uint256 tokenIndex = ownedTokensIndex[_tokenId];
        uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
        uint256 lastToken = ownedTokens[_from][lastTokenIndex];

        ownedTokens[_from][tokenIndex] = lastToken;
        ownedTokens[_from][lastTokenIndex] = 0;

        ownedTokens[_from].length--;
        ownedTokensIndex[_tokenId] = 0;
        ownedTokensIndex[lastToken] = tokenIndex;
    }

    function _mint(address _to, uint256 _tokenId) internal {
        super._mint(_to, _tokenId);

        allTokensIndex[_tokenId] = allTokens.length;
        allTokens.push(_tokenId);
    }

    function _burn(address _owner, uint256 _tokenId) internal {
        require(allTokens.length > 0, "no tokens");

        super._burn(_owner, _tokenId);

        uint256 tokenIndex = allTokensIndex[_tokenId];
        uint256 lastTokenIndex = allTokens.length.sub(1);
        uint256 lastToken = allTokens[lastTokenIndex];

        allTokens[tokenIndex] = lastToken;
        allTokens[lastTokenIndex] = 0;

        allTokens.length--;
        allTokensIndex[_tokenId] = 0;
        allTokensIndex[lastToken] = tokenIndex;
    // The contract owner can change the farmhouse URL, in case it becomes necessary. It is needed for Metadata.
    }

    function supportsInterface(bytes4 _interfaceID) external pure returns (bool) {
        return (
            _interfaceID == INTERFACE_SIGNATURE_ERC165 ||
            _interfaceID == INTERFACE_SIGNATURE_ERC721 ||
            _interfaceID == INTERFACE_SIGNATURE_ERC721TokenReceiver ||
            _interfaceID == INTERFACE_SIGNATURE_ERC721Metadata ||
            _interfaceID == INTERFACE_SIGNATURE_ERC721Enumerable
        );
    }

    function tokenURI(uint256 _tokenId) public view returns (string) {
        require(exists(_tokenId), "token doesn't exist");
        return string(abi.encodePacked(url, _uint2str(_tokenId)));
    }

    function setUrl(string _url) external onlyOwner {
        url = _url;
    }

    function _uint2str(uint _i) internal pure returns (string){
        if (i == 0) return "0";
        uint i = _i;
        uint j = _i;
        uint length;
        while (j != 0){
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint k = length - 1;
        while (i != 0){
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }
}

pragma solidity 0.4.25;

// ----------------------------------------------------------------------------
// --- Name        : CropClash - [Crop SHARE]
// --- Symbol      : Format - {CRP}
// --- Total supply: Generated from minter accounts
// --- @Legal      : 
// --- @title for 01101101 01111001 01101100 01101111 01110110 01100101
// --- BlockHaus.Company - EJS32 - 2018-2021
// --- @dev pragma solidity version:0.8.0+commit.661d1103
// --- SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// --- Contract TomatoModel 
// ----------------------------------------------------------------------------

contract TomatoModel {

    struct HealthAndRadiation {
        uint256 timestamp; 
        uint32 remainingHealth; 
        uint32 remainingRadiation; 
        uint32 maxHealth;
        uint32 maxRadiation;
    }

    struct Level {
        uint8 level; 
        uint8 experience; 
        uint16 dnaPoints; 
    }

    struct Tactics {
        uint8 melee; 
        uint8 attack;
    }

    struct Clashs {
        uint16 wins;
        uint16 defeats;
    }

    struct Abilitys {
        uint32 attack;
        uint32 defense;
        uint32 stamina;
        uint32 speed;
        uint32 intelligence;
    }

    struct Tomato {
        uint16 generation;
        uint256[4] genome; 
        uint256[2] donors;
        uint8[11] types; 
        uint256 birth;
    }

}

pragma solidity 0.4.25;

// ----------------------------------------------------------------------------
// --- Name        : CropClash - [Crop SHARE]
// --- Symbol      : Format - {CRP}
// --- Total supply: Generated from minter accounts
// --- @Legal      : 
// --- @title for 01101101 01111001 01101100 01101111 01110110 01100101
// --- BlockHaus.Company - EJS32 - 2018-2021
// --- @dev pragma solidity version:0.8.0+commit.661d1103
// --- SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

import "./ERC721Basic.sol";

// ----------------------------------------------------------------------------
// --- Contract ERC721Enumerable 
// ----------------------------------------------------------------------------

contract ERC721Enumerable is ERC721Basic {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256 _tokenId);
    function tokenByIndex(uint256 _index) public view returns (uint256);
}

// ----------------------------------------------------------------------------
// --- Contract ERC721Metadata 
// ----------------------------------------------------------------------------

contract ERC721Metadata is ERC721Basic {
    function name() public view returns (string _name);
    function symbol() public view returns (string _symbol);
    function tokenURI(uint256 _tokenId) public view returns (string);
}

// ----------------------------------------------------------------------------
// --- Contract ERC721 
// ----------------------------------------------------------------------------

contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {}

pragma solidity 0.4.25;

// ----------------------------------------------------------------------------
// --- Name        : CropClash - [Crop SHARE]
// --- Symbol      : Format - {CRP}
// --- Total supply: Generated from minter accounts
// --- @Legal      : 
// --- @title for 01101101 01111001 01101100 01101111 01110110 01100101
// --- BlockHaus.Company - EJS32 - 2018-2021
// --- @dev pragma solidity version:0.8.0+commit.661d1103
// --- SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

import "./ERC721Basic.sol";
import "./ERC721Receiver.sol";
import "../Upgradable.sol";
import "../SafeMath256.sol";

// ----------------------------------------------------------------------------
// --- Contract ERC721Basic 
// ----------------------------------------------------------------------------

contract ERC721BasicToken is ERC721Basic, Upgradable {

    using SafeMath256 for uint256;

    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    mapping (uint256 => address) internal tokenOwner;
    mapping (uint256 => address) internal tokenApprovals;
    mapping (address => uint256) internal ownedTokensCount;
    mapping (address => mapping (address => bool)) internal operatorApprovals;

    function _checkRights(bool _has) internal pure {
        require(_has, "no rights to radiationge");
    }

    function _validateAddress(address _addr) internal pure {
        require(_addr != address(0), "invalid address");
    }

    function _checkOwner(uint256 _tokenId, address _owner) internal view {
        require(ownerOf(_tokenId) == _owner, "not an owner");
    }

    function _checkThatUserHasTokens(bool _has) internal pure {
        require(_has, "user has no tokens");
    }

    function balanceOf(address _owner) public view returns (uint256) {
        _validateAddress(_owner);
        return ownedTokensCount[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns (address) {
        address owner = tokenOwner[_tokenId];
        _validateAddress(owner);
        return owner;
    }

    function exists(uint256 _tokenId) public view returns (bool) {
        address owner = tokenOwner[_tokenId];
        return owner != address(0);
    }

    function _approve(address _from, address _to, uint256 _tokenId) internal {
        address owner = ownerOf(_tokenId);
        require(_to != owner, "can't be approved to owner");
        _checkRights(_from == owner || isApprovedForAll(owner, _from));

        if (getApproved(_tokenId) != address(0) || _to != address(0)) {
            tokenApprovals[_tokenId] = _to;
            emit Approval(owner, _to, _tokenId);
        }
    }

    function approve(address _to, uint256 _tokenId) public {
        _approve(msg.sender, _to, _tokenId);
    }

    function remoteApprove(address _to, uint256 _tokenId) external onlyFarmer {
        _approve(tx.origin, _to, _tokenId);
    }

    function getApproved(uint256 _tokenId) public view returns (address) {
        require(exists(_tokenId), "token doesn't exist");
        return tokenApprovals[_tokenId];
    }

    function setApprovalForAll(address _to, bool _approved) public {
        require(_to != msg.sender, "wrong sender");
        operatorApprovals[msg.sender][_to] = _approved;
        emit ApprovalForAll(msg.sender, _to, _approved);
    }

    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return operatorApprovals[_owner][_operator];
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        _checkRights(isApprovedOrOwner(msg.sender, _tokenId));
        _validateAddress(_from);
        _validateAddress(_to);

        clearApproval(_from, _tokenId);
        removeTokenFrom(_from, _tokenId);
        addTokenTo(_to, _tokenId);
        emit Transfer(_from, _to, _tokenId);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes _data
    ) public {
        transferFrom(_from, _to, _tokenId);
        require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data), "can't make safe transfer");
    }

    function isApprovedOrOwner(address _spender, uint256 _tokenId) public view returns (bool) {
        address owner = ownerOf(_tokenId);
        return _spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender);
    }

    function _mint(address _to, uint256 _tokenId) internal {
        _validateAddress(_to);
        addTokenTo(_to, _tokenId);
        emit Transfer(address(0), _to, _tokenId);
    }

    function _burn(address _owner, uint256 _tokenId) internal {
        clearApproval(_owner, _tokenId);
        removeTokenFrom(_owner, _tokenId);
        emit Transfer(_owner, address(0), _tokenId);
    }

    function clearApproval(address _owner, uint256 _tokenId) internal {
        _checkOwner(_tokenId, _owner);
        if (tokenApprovals[_tokenId] != address(0)) {
            tokenApprovals[_tokenId] = address(0);
            emit Approval(_owner, address(0), _tokenId);
        }
    }

    function addTokenTo(address _to, uint256 _tokenId) internal {
        require(tokenOwner[_tokenId] == address(0), "token already has an owner");
        tokenOwner[_tokenId] = _to;
        ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
    }

    function removeTokenFrom(address _from, uint256 _tokenId) internal {
        _checkOwner(_tokenId, _from);
        _checkThatUserHasTokens(ownedTokensCount[_from] > 0);
        ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
        tokenOwner[_tokenId] = address(0);
    }

    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function checkAndCallSafeTransfer(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes _data
    ) internal returns (bool) {
        if (!_isContract(_to)) {
            return true;
        }
        bytes4 retval = ERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }
}

pragma solidity 0.4.25;

// ----------------------------------------------------------------------------
// --- Name        : CropClash - [Crop SHARE]
// --- Symbol      : Format - {CRP}
// --- Total supply: Generated from minter accounts
// --- @Legal      : 
// --- @title for 01101101 01111001 01101100 01101111 01110110 01100101
// --- BlockHaus.Company - EJS32 - 2018-2021
// --- @dev pragma solidity version:0.8.0+commit.661d1103
// --- SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// --- Contract ERC721Basic 
// ----------------------------------------------------------------------------

contract ERC721Basic {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function balanceOf(address _owner) public view returns (uint256 _balance);
    function ownerOf(uint256 _tokenId) public view returns (address _owner);
    function exists(uint256 _tokenId) public view returns (bool _exists);

    function approve(address _to, uint256 _tokenId) public;
    function getApproved(uint256 _tokenId) public view returns (address _operator);

    function setApprovalForAll(address _operator, bool _approved) public;
    function isApprovedForAll(address _owner, address _operator) public view returns (bool);

    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) public;

    function supportsInterface(bytes4 _interfaceID) external pure returns (bool);
}

pragma solidity 0.4.25;

// ----------------------------------------------------------------------------
// --- Name        : CropClash - [Crop SHARE]
// --- Symbol      : Format - {CRP}
// --- Total supply: Generated from minter accounts
// --- @Legal      : 
// --- @title for 01101101 01111001 01101100 01101111 01110110 01100101
// --- BlockHaus.Company - EJS32 - 2018-2021
// --- @dev pragma solidity version:0.8.0+commit.661d1103
// --- SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// --- Contract ERC721Receiver 
// ----------------------------------------------------------------------------

contract ERC721Receiver {
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes _data
    )
        public
        returns(bytes4);
}

pragma solidity 0.4.25;

// ----------------------------------------------------------------------------
// --- Name        : CropClash - [Crop SHARE]
// --- Symbol      : Format - {CRP}
// --- Total supply: Generated from minter accounts
// --- @Legal      : 
// --- @title for 01101101 01111001 01101100 01101111 01110110 01100101
// --- BlockHaus.Company - EJS32 - 2018-2021
// --- @dev pragma solidity version:0.8.0+commit.661d1103
// --- SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

import "./Ownable.sol";

// ----------------------------------------------------------------------------
// --- Contract Controllable 
// ----------------------------------------------------------------------------

contract Controllable is Ownable {
    mapping(address => bool) farmers;

    modifier onlyFarmer {
        require(_isFarmer(msg.sender), "no farmer rights");
        _;
    }

    function _isFarmer(address _farmer) internal view returns (bool) {
        return farmers[_farmer];
    }

    function _setFarmers(address[] _farmers, bool _active) internal {
        for (uint256 i = 0; i < _farmers.length; i++) {
            _validateAddress(_farmers[i]);
            farmers[_farmers[i]] = _active;
        }
    }
}

pragma solidity 0.4.25;

// ----------------------------------------------------------------------------
// --- Name        : CropClash - [Crop SHARE]
// --- Symbol      : Format - {CRP}
// --- Total supply: Generated from minter accounts
// --- @Legal      : 
// --- @title for 01101101 01111001 01101100 01101111 01110110 01100101
// --- BlockHaus.Company - EJS32 - 2018-2021
// --- @dev pragma solidity version:0.8.0+commit.661d1103
// --- SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// --- Contract Ownable 
// ----------------------------------------------------------------------------

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function _validateAddress(address _addr) internal pure {
        require(_addr != address(0), "invalid address");
    }

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not a contract owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _validateAddress(newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

pragma solidity 0.4.25;

// ----------------------------------------------------------------------------
// --- Name        : CropClash - [Crop SHARE]
// --- Symbol      : Format - {CRP}
// --- Total supply: Generated from minter accounts
// --- @Legal      : 
// --- @title for 01101101 01111001 01101100 01101111 01110110 01100101
// --- BlockHaus.Company - EJS32 - 2018-2021
// --- @dev pragma solidity version:0.8.0+commit.661d1103
// --- SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

import "../Common/Upgradable.sol";
import "../Common/Random.sol";
import "./TomatoSilo.sol";
import "./TomatoSpecs.sol";
import "./TomatoFarmRancher.sol";
import "../Common/SafeMath32.sol";
import "../Common/SafeMath256.sol";
import "../Common/SafeConvert.sol";

// ----------------------------------------------------------------------------
// --- Contract TomatoFarmhouse 
// ----------------------------------------------------------------------------

contract TomatoFarmhouse is Upgradable {
    using SafeMath32 for uint32;
    using SafeMath256 for uint256;
    using SafeConvert for uint32;
    using SafeConvert for uint256;

    TomatoSilo _silo_;
    TomatoSpecs specs;
    TomatoFarmRancher rancher;
    Random random;

    function _identifySpecialClashAbilitys(
        uint256 _id,
        uint8[11] _tomatoTypes
    ) internal {
        uint256 _randomSeed = random.random(10000); 
        uint256 _attackRandom = _randomSeed % 100; 
        uint256 _defenseRandom = _randomSeed / 100; 

        _attackRandom = _attackRandom.mul(4).div(10);
        _defenseRandom = _defenseRandom.mul(4).div(10);

        uint8 _attackType = rancher.getSpecialClashAbilityTomatoType(_tomatoTypes, _attackRandom);
        uint8 _defenseType = rancher.getSpecialClashAbilityTomatoType(_tomatoTypes, _defenseRandom);

        _silo_.setSpecialAttack(_id, _attackType);
        _silo_.setSpecialDefense(_id, _defenseType);
    }

    function _setAbilitysAndHealthAndRadiation(uint256 _id, uint256[4] _genome, uint8[11] _tomatoTypes) internal {
        (
            uint32 _attack,
            uint32 _defense,
            uint32 _stamina,
            uint32 _speed,
            uint32 _intelligence
        ) = rancher.calculateAbilitys(_genome);

        _silo_.setAbilitys(_id, _attack, _defense, _stamina, _speed, _intelligence);

        _identifySpecialClashAbilitys(_id, _tomatoTypes);

        (
            uint32 _health,
            uint32 _radiation
        ) = rancher.calculateHealthAndRadiation(_stamina, _intelligence, 0, 0);
        _silo_.setMaxHealthAndRadiation(_id, _health, _radiation);
    }

    function setInternalDependencies(address[] _newDependencies) public onlyOwner {
        super.setInternalDependencies(_newDependencies);

        _silo_ = TomatoSilo(_newDependencies[0]);
        specs = TomatoSpecs(_newDependencies[1]);
        rancher = TomatoFarmRancher(_newDependencies[2]);
        random = Random(_newDependencies[3]);
    }
}

pragma solidity 0.4.25;

// ----------------------------------------------------------------------------
// --- Name        : CropClash - [Crop SHARE]
// --- Symbol      : Format - {CRP}
// --- Total supply: Generated from minter accounts
// --- @Legal      : 
// --- @title for 01101101 01111001 01101100 01101111 01110110 01100101
// --- BlockHaus.Company - EJS32 - 2018-2021
// --- @dev pragma solidity version:0.8.0+commit.661d1103
// --- SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

library SafeMath16 {

    function mul(uint16 a, uint16 b) internal pure returns (uint16) {
        if (a == 0) {
            return 0;
        }
        uint16 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint16 a, uint16 b) internal pure returns (uint16) {
        return a / b;
    }

    function sub(uint16 a, uint16 b) internal pure returns (uint16) {
        assert(b <= a);
        return a - b;
    }

    function add(uint16 a, uint16 b) internal pure returns (uint16) {
        uint16 c = a + b;
        assert(c >= a);
        return c;
    }

    function pow(uint16 a, uint16 b) internal pure returns (uint16) {
        if (a == 0) return 0;
        if (b == 0) return 1;

        uint16 c = a ** b;
        assert(c / (a ** (b - 1)) == a);
        return c;
    }
}

pragma solidity 0.4.25;

// ----------------------------------------------------------------------------
// --- Name        : CropClash - [Crop SHARE]
// --- Symbol      : Format - {CRP}
// --- Total supply: Generated from minter accounts
// --- @Legal      : 
// --- @title for 01101101 01111001 01101100 01101111 01110110 01100101
// --- BlockHaus.Company - EJS32 - 2018-2021
// --- @dev pragma solidity version:0.8.0+commit.661d1103
// --- SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

import "./SafeMath256.sol";
import "./SafeConvert.sol";
import "./Upgradable.sol";

// ----------------------------------------------------------------------------
// --- Contract Random 
// ----------------------------------------------------------------------------

contract Random is Upgradable {
    using SafeMath256 for uint256;
    using SafeConvert for uint256;

    function _safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        return b > a ? 0 : a.sub(b);
    }

    modifier validBlock(uint256 _blockNumber) {
        require(
            _blockNumber < block.number &&
            _blockNumber >= _safeSub(block.number, 256),
            "not valid block number"
        );
        _;
    }

    function getRandom(
        uint256 _upper,
        uint256 _blockNumber
    ) internal view validBlock(_blockNumber) returns (uint256) {
        bytes32 _hash = keccak256(abi.encodePacked(blockhash(_blockNumber), now)); 
        return uint256(_hash) % _upper;
    }

    function random(uint256 _upper) external view returns (uint256) {
        return getRandom(_upper, block.number.sub(1));
    }

    function randomOfBlock(
        uint256 _upper,
        uint256 _blockNumber
    ) external view returns (uint256) {
        return getRandom(_upper, _blockNumber);
    }
}

pragma solidity 0.4.25;

// ----------------------------------------------------------------------------
// --- Name        : CropClash - [Crop SHARE]
// --- Symbol      : Format - {CRP}
// --- Total supply: Generated from minter accounts
// --- @Legal      : 
// --- @title for 01101101 01111001 01101100 01101111 01110110 01100101
// --- BlockHaus.Company - EJS32 - 2018-2021
// --- @dev pragma solidity version:0.8.0+commit.661d1103
// --- SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

import "../Common/Upgradable.sol";

// ----------------------------------------------------------------------------
// --- Contract TomatoSpecs 
// ----------------------------------------------------------------------------

contract TomatoSpecs is Upgradable {
    uint8[5][11] _tomatoTypesFactors_;
    uint8[5][10] _bodyPartsFactors_;
    uint8[5][10] _geneTypesFactors_;
    uint8[10] _experienceToNextLevel_;
    uint16[11] _dnaPoints_;
    uint8 _clashPoints_;
    uint8[99] _geneUpgradeDNAPoints_;

    function tomatoTypesFactors(uint8 _index) external view returns (uint8[5]) {
        return _tomatoTypesFactors_[_index];
    }

    function bodyPartsFactors(uint8 _index) external view returns (uint8[5]) {
        return _bodyPartsFactors_[_index];
    }

    function geneTypesFactors(uint8 _index) external view returns (uint8[5]) {
        return _geneTypesFactors_[_index];
    }

    function experienceToNextLevel(uint8 _index) external view returns (uint8) {
        return _experienceToNextLevel_[_index];
    }

    function dnaPoints(uint8 _index) external view returns (uint16) {
        return _dnaPoints_[_index];
    }

    function geneUpgradeDNAPoints(uint8 _index) external view returns (uint8) {
        return _geneUpgradeDNAPoints_[_index];
    }

    function getTomatoTypesFactors() external view returns (uint8[55] result) {
        uint8 _index;
        for (uint8 i = 0; i < 11; i++) {
            for (uint8 j = 0; j < 5; j++) {
                result[_index] = _tomatoTypesFactors_[i][j];
                _index++;
            }
        }
    }

    function _transformArray(uint8[5][10] _array) internal pure returns (uint8[50] result) {
        uint8 _index;
        for (uint8 i = 0; i < 10; i++) {
            for (uint8 j = 0; j < 5; j++) {
                result[_index] = _array[i][j];
                _index++;
            }
        }
    }

    function getBodyPartsFactors() external view returns (uint8[50]) {
        return _transformArray(_bodyPartsFactors_);
    }

    function getGeneTypesFactors() external view returns (uint8[50]) {
        return _transformArray(_geneTypesFactors_);
    }

    function getExperienceToNextLevel() external view returns (uint8[10]) {
        return _experienceToNextLevel_;
    }

    function getDNAPoints() external view returns (uint16[11]) {
        return _dnaPoints_;
    }

    function clashPoints() external view returns (uint8) {
        return _clashPoints_;
    }

    function getGeneUpgradeDNAPoints() external view returns (uint8[99]) {
        return _geneUpgradeDNAPoints_;
    }

    function setTomatoTypesFactors(uint8[5][11] _types) external onlyOwner {
        _tomatoTypesFactors_ = _types;
    }

    function setBodyPartsFactors(uint8[5][10] _bodyParts) external onlyOwner {
        _bodyPartsFactors_ = _bodyParts;
    }

    function setGeneTypesFactors(uint8[5][10] _geneTypes) external onlyOwner {
        _geneTypesFactors_ = _geneTypes;
    }

    function setLevelUpPoints(
        uint8[10] _experienceToNextLevel,
        uint16[11] _dnaPoints,
        uint8 _clashPoints
    ) external onlyOwner {
        _experienceToNextLevel_ = _experienceToNextLevel;
        _dnaPoints_ = _dnaPoints;
        _clashPoints_ = _clashPoints;
    }

    function setGeneUpgradeDNAPoints(uint8[99] _points) external onlyOwner {
        _geneUpgradeDNAPoints_ = _points;
    }
}

pragma solidity 0.4.25;

// ----------------------------------------------------------------------------
// --- Name        : CropClash - [Crop SHARE]
// --- Symbol      : Format - {CRP}
// --- Total supply: Generated from minter accounts
// --- @Legal      : 
// --- @title for 01101101 01111001 01101100 01101111 01110110 01100101
// --- BlockHaus.Company - EJS32 - 2018-2021
// --- @dev pragma solidity version:0.8.0+commit.661d1103
// --- SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

library SafeConvert {

    function toUint8(uint256 _value) internal pure returns (uint8) {
        assert(_value <= 255);
        return uint8(_value);
    }

    function toUint16(uint256 _value) internal pure returns (uint16) {
        assert(_value <= 2**16 - 1);
        return uint16(_value);
    }

    function toUint32(uint256 _value) internal pure returns (uint32) {
        assert(_value <= 2**32 - 1);
        return uint32(_value);
    }
}

pragma solidity 0.4.25;

// ----------------------------------------------------------------------------
// --- Name        : CropClash - [Crop SHARE]
// --- Symbol      : Format - {CRP}
// --- Total supply: Generated from minter accounts
// --- @Legal      : 
// --- @title for 01101101 01111001 01101100 01101111 01110110 01100101
// --- BlockHaus.Company - EJS32 - 2018-2021
// --- @dev pragma solidity version:0.8.0+commit.661d1103
// --- SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

import "../Common/SafeMath8.sol";
import "../Common/SafeMath256.sol";
import "../Common/SafeConvert.sol";

// ----------------------------------------------------------------------------
// --- Contract TomatoUtils 
// ----------------------------------------------------------------------------

contract TomatoUtils {
    using SafeMath8 for uint8;
    using SafeMath256 for uint256;

    using SafeConvert for uint256;


    function _getActiveGene(uint8[16] _gene) internal pure returns (uint8[3] gene) {
        uint8 _index = _getActiveGeneIndex(_gene);
        for (uint8 i = 0; i < 3; i++) {
            gene[i] = _gene[i + (_index * 4)]; 
        }
    }

    function _getActiveGeneIndex(uint8[16] _gene) internal pure returns (uint8) {
        return _gene[3] >= _gene[7] ? 0 : 1;
    }

    function _getActiveGenes(uint8[16][10] _genome) internal pure returns (uint8[30] genome) {
        uint8[3] memory _activeGene;
        for (uint8 i = 0; i < 10; i++) {
            _activeGene = _getActiveGene(_genome[i]);
            genome[i * 3] = _activeGene[0];
            genome[i * 3 + 1] = _activeGene[1];
            genome[i * 3 + 2] = _activeGene[2];
        }
    }

    function _getIndexAndFactor(uint8 _counter) internal pure returns (uint8 index, uint8 factor) {
        if (_counter < 44) index = 0;
        else if (_counter < 88) index = 1;
        else if (_counter < 132) index = 2;
        else index = 3;
        factor = _counter.add(1) % 4 == 0 ? 10 : 100;
    }

    function _parseGenome(uint256[4] _composed) internal pure returns (uint8[16][10] parsed) {
        uint8 counter = 160; 
        uint8 _factor;
        uint8 _index;

        for (uint8 i = 0; i < 10; i++) {
            for (uint8 j = 0; j < 16; j++) {
                counter = counter.sub(1);
                (_index, _factor) = _getIndexAndFactor(counter);
                parsed[9 - i][15 - j] = (_composed[_index] % _factor).toUint8();
                _composed[_index] /= _factor;
            }
        }
    }

    function _composeGenome(uint8[16][10] _parsed) internal pure returns (uint256[4] composed) {
        uint8 counter = 0;
        uint8 _index;
        uint8 _factor;

        for (uint8 i = 0; i < 10; i++) {
            for (uint8 j = 0; j < 16; j++) {
                (_index, _factor) = _getIndexAndFactor(counter);
                composed[_index] = composed[_index].mul(_factor);
                composed[_index] = composed[_index].add(_parsed[i][j]);
                counter = counter.add(1);
            }
        }
    }
}

pragma solidity 0.4.25;

// ----------------------------------------------------------------------------
// --- Name        : CropClash - [Crop SHARE]
// --- Symbol      : Format - {CRP}
// --- Total supply: Generated from minter accounts
// --- @Legal      : 
// --- @title for 01101101 01111001 01101100 01101111 01110110 01100101
// --- BlockHaus.Company - EJS32 - 2018-2021
// --- @dev pragma solidity version:0.8.0+commit.661d1103
// --- SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

import "../Common/SafeMath256.sol";

// ----------------------------------------------------------------------------
// --- Contract Name 
// ----------------------------------------------------------------------------

contract Name {
    using SafeMath256 for uint256;

    uint8 constant MIN_NAME_LENGTH = 2;
    uint8 constant MAX_NAME_LENGTH = 32;

    function _convertName(string _input) internal pure returns(bytes32 _initial, bytes32 _lowercase) {
        bytes memory _initialBytes = bytes(_input);
        assembly {
            _initial := mload(add(_initialBytes, 32))
        }
        _lowercase = _toLowercase(_input);
    }

    function _toLowercase(string _input) internal pure returns(bytes32 result) {
        bytes memory _temp = bytes(_input);
        uint256 _length = _temp.length;
        require (_length <= 32 && _length >= 2, "string must be between 2 and 32 characters");
        require(_temp[0] != 0x20 && _temp[_length.sub(1)] != 0x20, "string cannot start or end with a space");
        if (_temp[0] == 0x30)
        {
            require(_temp[1] != 0x78, "string cannot start with 0x");
            require(_temp[1] != 0x58, "string cannot start with 0X");
        }

        bool _hasNonNumber;

        for (uint256 i = 0; i < _length; i = i.add(1))
        {
            if (_temp[i] > 0x40 && _temp[i] < 0x5b)
            {
                _temp[i] = byte(uint256(_temp[i]).add(32));

                if (_hasNonNumber == false)
                    _hasNonNumber = true;
            } else {
                require
                (
                    _temp[i] == 0x20 ||
                    (_temp[i] > 0x60 && _temp[i] < 0x7b) ||
                    (_temp[i] > 0x2f && _temp[i] < 0x3a),
                    "string contains invalid characters"
                );

                if (_temp[i] == 0x20)
                    require(_temp[i.add(1)] != 0x20, "string cannot contain consecutive spaces");

                if (_hasNonNumber == false && (_temp[i] < 0x30 || _temp[i] > 0x39))
                    _hasNonNumber = true;
            }
        }

        require(_hasNonNumber == true, "string cannot be only numbers");

        assembly {
            result := mload(add(_temp, 32))
        }
    }
}

pragma solidity 0.4.25;

// ----------------------------------------------------------------------------
// --- Name        : CropClash - [Crop SHARE]
// --- Symbol      : Format - {CRP}
// --- Total supply: Generated from minter accounts
// --- @Legal      : 
// --- @title for 01101101 01111001 01101100 01101111 01110110 01100101
// --- BlockHaus.Company - EJS32 - 2018-2021
// --- @dev pragma solidity version:0.8.0+commit.661d1103
// --- SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

library SafeMath8 {

    function mul(uint8 a, uint8 b) internal pure returns (uint8) {
        if (a == 0) {
            return 0;
        }
        uint8 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint8 a, uint8 b) internal pure returns (uint8) {
        return a / b;
    }

    function sub(uint8 a, uint8 b) internal pure returns (uint8) {
        assert(b <= a);
        return a - b;
    }

    function add(uint8 a, uint8 b) internal pure returns (uint8) {
        uint8 c = a + b;
        assert(c >= a);
        return c;
    }

    function pow(uint8 a, uint8 b) internal pure returns (uint8) {
        if (a == 0) return 0;
        if (b == 0) return 1;

        uint8 c = a ** b;
        assert(c / (a ** (b - 1)) == a);
        return c;
    }
}
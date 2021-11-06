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
import "./TomatoUtils.sol";
import "../Farmhand.sol";
import "../Common/SafeMath16.sol";

// ----------------------------------------------------------------------------
// --- Contract TomatoMutation 
// ----------------------------------------------------------------------------

contract TomatoMutation is Upgradable, TomatoUtils {
    using SafeMath16 for uint16;
    using SafeMath256 for uint256;

    Farmhand farmhand;

    uint8 constant MUTATION_CHANCE = 1; 
    uint16[7] genesWeights = [300, 240, 220, 190, 25, 15, 10];

    function _chooseGen(uint8 _random, uint8[16] _array1, uint8[16] _array2) internal pure returns (uint8[16] gen) {
        uint8 x = _random.div(2);
        uint8 y = _random % 2;
        for (uint8 j = 0; j < 2; j++) {
            for (uint8 k = 0; k < 4; k++) {
                gen[k.add(j.mul(8))] = _array1[k.add(j.mul(4)).add(x.mul(8))];
                gen[k.add(j.mul(2).add(1).mul(4))] = _array2[k.add(j.mul(4)).add(y.mul(8))];
            }
        }
    }

    function _getDonors(uint256 _id) internal view returns (uint256[2]) {
        if (_id != 0) {
            return farmhand.getTomatoDonors(_id);
        }
        return [uint256(0), uint256(0)];
    }

    function _checkIncloning(uint256[2] memory _donors) internal view returns (uint8 chance) {
        uint8 _relatives;
        uint8 i;
        uint256[2] memory _donors_1_1 = _getDonors(_donors[0]);
        uint256[2] memory _donors_1_2 = _getDonors(_donors[1]);

        if (_donors_1_1[0] != 0 && (_donors_1_1[0] == _donors_1_2[0] || _donors_1_1[0] == _donors_1_2[1])) {
            _relatives = _relatives.add(1);
        }
        
        if (_donors_1_1[1] != 0 && (_donors_1_1[1] == _donors_1_2[0] || _donors_1_1[1] == _donors_1_2[1])) {
            _relatives = _relatives.add(1);
        }

        if (_donors[0] == _donors_1_2[0] || _donors[0] == _donors_1_2[1]) {
            _relatives = _relatives.add(1);
        }
        
        if (_donors[1] == _donors_1_1[0] || _donors[1] == _donors_1_1[1]) {
            _relatives = _relatives.add(1);
        }
        
        if (_relatives >= 2) return 8; 
        
        if (_relatives == 1) chance = 7; 
        
        uint256[12] memory _ancestors;
        uint256[2] memory _donors_2_1 = _getDonors(_donors_1_1[0]);
        uint256[2] memory _donors_2_2 = _getDonors(_donors_1_1[1]);
        uint256[2] memory _donors_2_3 = _getDonors(_donors_1_2[0]);
        uint256[2] memory _donors_2_4 = _getDonors(_donors_1_2[1]);
        for (i = 0; i < 2; i++) {
            _ancestors[i.mul(6).add(0)] = _donors_1_1[i];
            _ancestors[i.mul(6).add(1)] = _donors_1_2[i];
            _ancestors[i.mul(6).add(2)] = _donors_2_1[i];
            _ancestors[i.mul(6).add(3)] = _donors_2_2[i];
            _ancestors[i.mul(6).add(4)] = _donors_2_3[i];
            _ancestors[i.mul(6).add(5)] = _donors_2_4[i];
        }
        for (i = 0; i < 12; i++) {
            for (uint8 j = i.add(1); j < 12; j++) {
                if (_ancestors[i] != 0 && _ancestors[i] == _ancestors[j]) {
                    _relatives = _relatives.add(1);
                    _ancestors[j] = 0;
                }
                if (_relatives > 2 || (_relatives == 2 && chance == 0)) return 8;
            }
        }
        if (_relatives == 1 && chance == 0) return 5; 
    }

    function _mutateGene(uint8[16] _gene, uint8 _genType) internal pure returns (uint8[16]) {
        uint8 _index = _getActiveGeneIndex(_gene);
        _gene[_index.mul(4).add(1)] = _genType; 
        _gene[_index.mul(4).add(2)] = 1; 
        return _gene;
    }

    function _calculateGen(
        uint8[16] _a_donorGen,
        uint8[16] _b_donorGen,
        uint8 _random
    ) internal pure returns (uint8[16] gen) {
        if (_random < 4) {
            return _chooseGen(_random, _a_donorGen, _a_donorGen);
        } else if (_random < 8) {
            return _chooseGen(_random.sub(4), _a_donorGen, _b_donorGen);
        } else if (_random < 12) {
            return _chooseGen(_random.sub(8), _b_donorGen, _b_donorGen);
        } else {
            return _chooseGen(_random.sub(12), _b_donorGen, _a_donorGen);
        }
    }

    function _calculateGenome(
        uint8[16][10] memory _a_donorGenome,
        uint8[16][10] memory _b_donorGenome,
        uint8 _uglinessChance,
        uint256 _seed_
    ) internal pure returns (uint8[16][10] genome) {
        uint256 _seed = _seed_;
        uint256 _random;
        uint8 _mutationChance = _uglinessChance == 0 ? MUTATION_CHANCE : _uglinessChance;
        uint8 _geneType;
        for (uint8 i = 0; i < 10; i++) {
            (_random, _seed) = _getSpecialRandom(_seed, 4);
            genome[i] = _calculateGen(_a_donorGenome[i], _b_donorGenome[i], (_random % 16).toUint8());
            (_random, _seed) = _getSpecialRandom(_seed, 1);
            if (_random < _mutationChance) {
                _geneType = 0;
                if (_uglinessChance == 0) {
                    (_random, _seed) = _getSpecialRandom(_seed, 2);
                    _geneType = (_random % 9).add(1).toUint8(); 
                }
                genome[i] = _mutateGene(genome[i], _geneType);
            }
        }
    }

    function _calculateTomatoTypes(uint8[16][10] _genome) internal pure returns (uint8[11] tomatoTypesArray) {
        uint8 _tomatoType;
        for (uint8 i = 0; i < 10; i++) {
            for (uint8 j = 0; j < 4; j++) {
                _tomatoType = _genome[i][j.mul(4)];
                tomatoTypesArray[_tomatoType] = tomatoTypesArray[_tomatoType].add(1);
            }
        }
    }

    function createGenome(
        uint256[2] _donors,
        uint256[4] _a_donorGenome,
        uint256[4] _b_donorGenome,
        uint256 _seed
    ) external view returns (
        uint256[4] genome,
        uint8[11] tomatoTypes
    ) {
        uint8 _uglinessChance = _checkIncloning(_donors);
        uint8[16][10] memory _parsedGenome = _calculateGenome(
            _parseGenome(_a_donorGenome),
            _parseGenome(_b_donorGenome),
            _uglinessChance,
            _seed
        );
        genome = _composeGenome(_parsedGenome);
        tomatoTypes = _calculateTomatoTypes(_parsedGenome);
    }

    function _getWeightedRandom(uint256 _random) internal view returns (uint8) {
        uint16 _weight;
        for (uint8 i = 1; i < 7; i++) {
            _weight = _weight.add(genesWeights[i.sub(1)]);
            if (_random < _weight) return i;
        }
        return 7;
    }

    function _generateGen(uint8 _tomatoType, uint256 _random) internal view returns (uint8[16]) {
        uint8 _geneType = _getWeightedRandom(_random); 
        return [
            _tomatoType, _geneType, 1, 1,
            _tomatoType, _geneType, 1, 0,
            _tomatoType, _geneType, 1, 0,
            _tomatoType, _geneType, 1, 0
        ];
    }

    // max 4 digits
    function _getSpecialRandom(
        uint256 _seed_,
        uint8 _digits
    ) internal pure returns (uint256, uint256) {
        uint256 _farmhouse = 10;
        uint256 _seed = _seed_;
        uint256 _random = _seed % _farmhouse.pow(_digits);
        _seed = _seed.div(_farmhouse.pow(_digits));
        return (_random, _seed);
    }

    function createGenomeForGenesis(uint8 _tomatoType, uint256 _seed_) external view returns (uint256[4]) {
        uint256 _seed = _seed_;
        uint8[16][10] memory _genome;
        uint256 _random;
        for (uint8 i = 0; i < 10; i++) {
            (_random, _seed) = _getSpecialRandom(_seed, 3);
            _genome[i] = _generateGen(_tomatoType, _random);
        }
        return _composeGenome(_genome);
    }

    function setInternalDependencies(address[] _newDependencies) public onlyOwner {
        super.setInternalDependencies(_newDependencies);

        farmhand = Farmhand(_newDependencies[0]);
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

import "./Common/Upgradable.sol";
import "./Farm.sol";
import "./Tomato/TomatoSpecs.sol";
import "./Tomato/TomatoFarmhand.sol";
import "./Harvest.sol";
import "./Market/CloningMarket.sol";
import "./Market/SeedMarket.sol";
import "./Market/TomatoMarket.sol";
import "./Market/AbilityMarket.sol";
import "./Field.sol";
import "./CropClash/Participants/CropClash.sol";
import "./CropClash/Participants/CropClashSilo.sol";

// ----------------------------------------------------------------------------
// --- Contract Farmhand 
// ----------------------------------------------------------------------------

contract Farmhand is Upgradable {

    Farm farm;
    TomatoSpecs tomatoSpecs;
    TomatoFarmhand tomatoFarmhand;
    AbilityMarket abilityMarket;
    Harvest harvest;
    Field field;
    CropClash cropClash;
    CropClashSilo cropClashSilo;

    CloningMarket public cloningMarket;
    SeedMarket public seedMarket;
    TomatoMarket public tomatoMarket;

    function _isValidAddress(address _addr) internal pure returns (bool) {
        return _addr != address(0);
    }

    function getSeed(uint256 _id) external view returns (
      uint16 gen, uint32 rarity, uint256[2] donors, uint8[11] a_donorTomatoTypes, uint8[11] b_donorTomatoTypes
    ) {
        return farm.getSeed(_id);
    }

    function getTomatoGenome(uint256 _id) external view returns (uint8[30]) {
        return tomatoFarmhand.getGenome(_id);
    }

    function getTomatoTypes(uint256 _id) external view returns (uint8[11]) {
        return tomatoFarmhand.getTomatoTypes(_id);
    }

    function getTomatoProfile(uint256 _id) external view returns (
        bytes32 name, uint16 generation, uint256 birth, uint8 level, uint8 experience, uint16 dnaPoints, bool isCloningAllowed, uint32 rarity
    ) {
        return tomatoFarmhand.getProfile(_id);
    }

    function getTomatoTactics(uint256 _id) external view returns (uint8 melee, uint8 attack) {
        return tomatoFarmhand.getTactics(_id);
    }

    function getTomatoClashs(uint256 _id) external view returns (uint16 wins, uint16 defeats) {
        return tomatoFarmhand.getClashs(_id);
    }

    function getTomatoAbilitys(uint256 _id) external view returns (
      uint32 attack, uint32 defense, uint32 stamina, uint32 speed, uint32 intelligence
    ) {
        return tomatoFarmhand.getAbilitys(_id);
    }

    function getTomatoStrength(uint256 _id) external view returns (uint32) {
        return tomatoFarmhand.getTomatoStrength(_id);
    }

    function getTomatoCurrentHealthAndRadiation(uint256 _id) external view returns (
      uint32 health, uint32 radiation, uint8 healthPercentage, uint8 radiationPercentage
    ) {
        return tomatoFarmhand.getCurrentHealthAndRadiation(_id);
    }

    function getTomatoMaxHealthAndRadiation(uint256 _id) external view returns (uint32 maxHealth, uint32 maxRadiation) {
        ( , , , maxHealth, maxRadiation) = tomatoFarmhand.getHealthAndRadiation(_id);
    }

    function getTomatoHealthAndRadiation(uint256 _id) external view returns (
        uint256 timestamp, uint32 remainingHealth, uint32 remainingRadiation, uint32 maxHealth, uint32 maxRadiation
    ) {
        return tomatoFarmhand.getHealthAndRadiation(_id);
    }

    function getTomatoDonors(uint256 _id) external view returns (uint256[2]) {
        return tomatoFarmhand.getDonors(_id);
    }

    function getTomatoSpecialAttack(uint256 _id) external view returns (
      uint8 tomatoType, uint32 cost, uint8 factor, uint8 chance
    ) {
        return tomatoFarmhand.getSpecialAttack(_id);
    }

    function getTomatoSpecialDefense(uint256 _id) external view returns (
      uint8 tomatoType, uint32 cost, uint8 factor, uint8 chance
    ) {
        return tomatoFarmhand.getSpecialDefense(_id);
    }

    function getTomatoSpecialPeacefulAbility(uint256 _id) external view returns (
      uint8 class, uint32 cost, uint32 effect
    ) {
        return tomatoFarmhand.getSpecialPeacefulAbility(_id);
    }

    function getTomatosAmount() external view returns (uint256) {
        return tomatoFarmhand.getAmount();
    }

    function getTomatoChildren(uint256 _id) external view returns (uint256[10] tomatos, uint256[10] seeds) {
        return farm.getTomatoChildren(_id);
    }

    function getTomatoBuffs(uint256 _id) external view returns (uint32[5]) {
        return tomatoFarmhand.getBuffs(_id);
    }

    function isTomatoCloningAllowed(uint256 _id) external view returns (bool) {
        return tomatoFarmhand.isCloningAllowed(_id);
    }

    function isTomatoUsed(uint256 _id) external view returns (
        bool isOnSale,
        bool isOnCloning,
        bool isInCropClash
    ) {
        return (
            isTomatoOnSale(_id),
            isCloningOnSale(_id),
            isTomatoInCropClash(_id)
        );
    }

    function getTomatoExperienceToNextLevel() external view returns (uint8[10]) {
        return tomatoSpecs.getExperienceToNextLevel();
    }

    function getTomatoGeneUpgradeDNAPoints() external view returns (uint8[99]) {
        return tomatoSpecs.getGeneUpgradeDNAPoints();
    }

    function getTomatoLevelUpDNAPoints() external view returns (uint16[11]) {
        return tomatoSpecs.getDNAPoints();
    }

    function getTomatoTypesFactors() external view returns (uint8[55]) {
        return tomatoSpecs.getTomatoTypesFactors();
    }

    function getTomatoBodyPartsFactors() external view returns (uint8[50]) {
        return tomatoSpecs.getBodyPartsFactors();
    }

    function getTomatoGeneTypesFactors() external view returns (uint8[50]) {
        return tomatoSpecs.getGeneTypesFactors();
    }

    function getSproutingPrice() external view returns (uint256) {
        return field.sproutingPrice();
    }

    function getTomatoNamePrices() external view returns (uint8[3] lengths, uint256[3] prices) {
        return tomatoFarmhand.getTomatoNamePrices();
    }

    function getTomatoNamePriceByLength(uint256 _length) external view returns (uint256 price) {
        return tomatoFarmhand.getTomatoNamePriceByLength(_length);
    }

     

    function getTomatoOnSaleInfo(uint256 _id) public view returns (
        address seller,
        uint256 currentPrice,
        uint256 startPrice,
        uint256 endPrice,
        uint16 period,
        uint256 created,
        bool isBean
    ) {
        return tomatoMarket.getAuction(_id);
    }

    function getCloningOnSaleInfo(uint256 _id) public view returns (
        address seller,
        uint256 currentPrice,
        uint256 startPrice,
        uint256 endPrice,
        uint16 period,
        uint256 created,
        bool isBean
    ) {
        return cloningMarket.getAuction(_id);
    }

    function getSeedOnSaleInfo(uint256 _id) public view returns (
        address seller,
        uint256 currentPrice,
        uint256 startPrice,
        uint256 endPrice,
        uint16 period,
        uint256 created,
        bool isBean
    ) {
        return seedMarket.getAuction(_id);
    }

    function getAbilityOnSaleInfo(uint256 _id) public view returns (address seller, uint256 price) {
        seller = ownerOfTomato(_id);
        price = abilityMarket.getAuction(_id);
    }

    function isSeedOnSale(uint256 _tokenId) external view returns (bool) {
        (address _seller, , , , , , ) = getSeedOnSaleInfo(_tokenId);

        return _isValidAddress(_seller);
    }

    function isTomatoOnSale(uint256 _tokenId) public view returns (bool) {
        (address _seller, , , , , , ) = getTomatoOnSaleInfo(_tokenId);

        return _isValidAddress(_seller);
    }

    function isCloningOnSale(uint256 _tokenId) public view returns (bool) {
        (address _seller, , , , , , ) = getCloningOnSaleInfo(_tokenId);

        return _isValidAddress(_seller);
    }

    function isAbilityOnSale(uint256 _tokenId) external view returns (bool) {
        (address _seller, ) = getAbilityOnSaleInfo(_tokenId);

        return _isValidAddress(_seller);
    }

    function getAbilitysOnSale() public view returns (uint256[]) {
        return abilityMarket.getAllTokens();
    }

    function isTomatoOwner(address _user, uint256 _tokenId) external view returns (bool) {
        return tomatoFarmhand.isOwner(_user, _tokenId);
    }

    function ownerOfTomato(uint256 _tokenId) public view returns (address) {
        return tomatoFarmhand.ownerOf(_tokenId);
    }

    function isSeedInSoil(uint256 _id) external view returns (bool) {
        return farm.isSeedInSoil(_id);
    }

    function getSeedsInSoil() external view returns (uint256[2]) {
        return farm.getSeedsInSoil();
    }

    function getTomatosFromRanking() external view returns (uint256[10]) {
        return farm.getTomatosFromRanking();
    }

    function getRankingRewards() external view returns (uint256[10]) {
        return farm.getRankingRewards(field.remainingBean());
    }

    function getRankingRewardDate() external view returns (uint256 lastRewardDate, uint256 rewardPeriod) {
        return farm.getRankingRewardDate();
    }

    function getHarvestInfo() external view returns (
        uint256 restAmount,
        uint256 releasedAmount,
        uint256 lastBlock,
        uint256 intervalInBlocks,
        uint256 numberOfTypes
    ) {
        return harvest.getInfo();
    }

    function cropClashsAmount() external view returns (uint256) {
        return cropClashSilo.challengesAmount();
    }

    function getUserCropClashs(address _user) external view returns (uint256[]) {
        return cropClashSilo.getUserChallenges(_user);
    }

    function getCropClashApplicants(uint256 _challengeId) external view returns (uint256[]) {
        return cropClashSilo.getChallengeApplicants(_challengeId);
    }

    function getTomatoApplicationForCropClash(
        uint256 _tomatoId
    ) external view returns (
        uint256 cropClashId,
        uint8[2] tactics,
        address owner
    ) {
        return cropClashSilo.getTomatoApplication(_tomatoId);
    }

    function getUserApplicationsForCropClashs(address _user) external view returns (uint256[]) {
        return cropClashSilo.getUserApplications(_user);
    }

    function getCropClashDetails(
        uint256 _challengeId
    ) external view returns (
        bool isBean, uint256 bet, uint16 counter,
        uint256 blockNumber, bool active,
        uint256 autoSelectBlock, bool cancelled,
        uint256 compensation, uint256 extensionTimePrice,
        uint256 clashId
    ) {
        return cropClashSilo.getChallengeDetails(_challengeId);
    }

    function getCropClashParticipants(
        uint256 _challengeId
    ) external view returns (
        address firstUser, uint256 firstTomatoId,
        address secondUser, uint256 secondTomatoId,
        address winnerUser, uint256 winnerTomatoId
    ) {
        return cropClashSilo.getChallengeParticipants(_challengeId);
    }

    function isTomatoInCropClash(uint256 _clashId) public view returns (bool) {
        return cropClash.isTomatoChallenging(_clashId);
    }

    function setInternalDependencies(address[] _newDependencies) public onlyOwner {
        super.setInternalDependencies(_newDependencies);
        farm = Farm(_newDependencies[0]);
        tomatoSpecs = TomatoSpecs(_newDependencies[1]);
        tomatoFarmhand = TomatoFarmhand(_newDependencies[2]);
        tomatoMarket = TomatoMarket(_newDependencies[3]);
        cloningMarket = CloningMarket(_newDependencies[4]);
        seedMarket = SeedMarket(_newDependencies[5]);
        abilityMarket = AbilityMarket(_newDependencies[6]);
        harvest = Harvest(_newDependencies[7]);
        field = Field(_newDependencies[8]);
        cropClash = CropClash(_newDependencies[9]);
        cropClashSilo = CropClashSilo(_newDependencies[10]);
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

import "./Common/Upgradable.sol";
import "./Tomato/TomatoFarm.sol";
import "./Tomato/TomatoRanking.sol";
import "./Tomato/TomatoFarmhand.sol";
import "./Tomato/TomatoMutation.sol";
import "./Seed/SeedFarm.sol";
import "./Soil.sol";
import "./Common/SafeMath8.sol";
import "./Common/SafeMath16.sol";
import "./Common/SafeMath32.sol";
import "./Common/SafeMath256.sol";

// ----------------------------------------------------------------------------
// --- Contract Farm 
// ----------------------------------------------------------------------------

contract Farm is Upgradable {
    using SafeMath8 for uint8;
    using SafeMath16 for uint16;
    using SafeMath32 for uint32;
    using SafeMath256 for uint256;

    TomatoFarm tomatoFarm;
    TomatoFarmhand tomatoFarmhand;
    TomatoMutation tomatoMutation;
    SeedFarm seedFarm;
    TomatoRanking ranking;
    Soil soil;

    uint256 public peacefulAbilityCooldown;
    mapping (uint256 => uint256) public lastPeacefulAbilitysUsageDates;

    constructor() public {
        peacefulAbilityCooldown = 14 days;
    }

    function _checkPossibilityOfUsingSpecialPeacefulAbility(uint256 _id) internal view {
        uint256 _availableFrom = lastPeacefulAbilitysUsageDates[_id].add(peacefulAbilityCooldown);
        require(_availableFrom <= now, "special peaceful ability is not yet available");
    }

    function setCooldown(uint256 _value) external onlyOwner {
        peacefulAbilityCooldown = _value;
    }

    function _max(uint16 lth, uint16 rth) internal pure returns (uint16) {
        if (lth > rth) {
            return lth;
        } else {
            return rth;
        }
    }

    function createSeed(
        address _sender,
        uint8 _tomatoType
    ) external onlyFarmer returns (uint256) {
        return seedFarm.create(_sender, [uint256(0), uint256(0)], _tomatoType);
    }

    function sendToSoil(
        uint256 _id
    ) external onlyFarmer returns (
        bool isSprouted,
        uint256 newTomatoId,
        uint256 sproutedId,
        address owner
    ) {
        uint256 _randomForSeedOpening;
        (isSprouted, sproutedId, _randomForSeedOpening) = soil.add(_id);
        if (isSprouted) {
            owner = seedFarm.ownerOf(sproutedId);
            newTomatoId = openSeed(owner, sproutedId, _randomForSeedOpening);
        }
    }

    function openSeed(
        address _owner,
        uint256 _seedId,
        uint256 _random
    ) internal returns (uint256 newTomatoId) {
        uint256[2] memory _donors;
        uint8 _tomatoType;
        (_donors, _tomatoType) = seedFarm.get(_seedId);

        uint256[4] memory _genome;
        uint8[11] memory _tomatoTypesArray;
        uint16 _generation;
        if (_donors[0] == 0 && _donors[1] == 0) {
            _generation = 0;
            _genome = tomatoMutation.createGenomeForGenesis(_tomatoType, _random);
            _tomatoTypesArray[_tomatoType] = 40; // 40 genes of 1 type
        } else {
            uint256[4] memory _a_donorGenome = tomatoFarmhand.getComposedGenome(_donors[0]);
            uint256[4] memory _b_donorGenome = tomatoFarmhand.getComposedGenome(_donors[1]);
            (_genome, _tomatoTypesArray) = tomatoMutation.createGenome(_donors, _a_donorGenome, _b_donorGenome, _random);
            _generation = _max(
                tomatoFarmhand.getGeneration(_donors[0]),
                tomatoFarmhand.getGeneration(_donors[1])
            ).add(1);
        }

        newTomatoId = tomatoFarm.createTomato(_owner, _generation, _donors, _genome, _tomatoTypesArray);
        seedFarm.remove(_owner, _seedId);

        uint32 _rarity = tomatoFarmhand.getRarity(newTomatoId);
        ranking.update(newTomatoId, _rarity);
    }

    function cultivar(
        address _sender,
        uint256 _a_donorId,
        uint256 _b_donorId
    ) external onlyFarmer returns (uint256) {
        tomatoFarm.payDNAPointsForCloning(_a_donorId);
        tomatoFarm.payDNAPointsForCloning(_b_donorId);
        return seedFarm.create(_sender, [_a_donorId, _b_donorId], 0);
    }

    function setTomatoReprimeingHealthAndRadiation(uint256 _id, uint32 _health, uint32 _radiation) external onlyFarmer {
        return tomatoFarm.setReprimeingHealthAndRadiation(_id, _health, _radiation);
    }

    function increaseTomatoExperience(uint256 _id, uint256 _factor) external onlyFarmer {
        tomatoFarm.increaseExperience(_id, _factor);
    }

    function upgradeTomatoGenes(uint256 _id, uint16[10] _dnaPoints) external onlyFarmer {
        tomatoFarm.upgradeGenes(_id, _dnaPoints);

        uint32 _rarity = tomatoFarmhand.getRarity(_id);
        ranking.update(_id, _rarity);
    }

    function increaseTomatoWins(uint256 _id) external onlyFarmer {
        tomatoFarm.increaseWins(_id);
    }

    function increaseTomatoDefeats(uint256 _id) external onlyFarmer {
        tomatoFarm.increaseDefeats(_id);
    }

    function setTomatoTactics(uint256 _id, uint8 _melee, uint8 _attack) external onlyFarmer {
        tomatoFarm.setTactics(_id, _melee, _attack);
    }

    function setTomatoName(uint256 _id, string _name) external onlyFarmer returns (bytes32) {
        return tomatoFarm.setName(_id, _name);
    }

    function setTomatoSpecialPeacefulAbility(uint256 _id, uint8 _class) external onlyFarmer {
        tomatoFarm.setSpecialPeacefulAbility(_id, _class);
    }

    function useTomatoSpecialPeacefulAbility(
        address _sender,
        uint256 _id,
        uint256 _target
    ) external onlyFarmer {
        _checkPossibilityOfUsingSpecialPeacefulAbility(_id);
        tomatoFarm.useSpecialPeacefulAbility(_sender, _id, _target);
        lastPeacefulAbilitysUsageDates[_id] = now;
    }

    function resetTomatoBuffs(uint256 _id) external onlyFarmer {
        tomatoFarm.setBuff(_id, 1, 0); // attack
        tomatoFarm.setBuff(_id, 2, 0); // defense
        tomatoFarm.setBuff(_id, 3, 0); // stamina
        tomatoFarm.setBuff(_id, 4, 0); // speed
        tomatoFarm.setBuff(_id, 5, 0); // intelligence
    }

    function updateRankingRewardTime() external onlyFarmer {
        return ranking.updateRewardTime();
    }

    function getTomatoFullRegenerationTime(uint256 _id) external view returns (uint32 time) {
        return tomatoFarmhand.getFullRegenerationTime(_id);
    }

    function isSeedOwner(address _user, uint256 _tokenId) external view returns (bool) {
        return seedFarm.isOwner(_user, _tokenId);
    }

    function isSeedInSoil(uint256 _id) external view returns (bool) {
        return soil.inSoil(_id);
    }

    function getSeedsInSoil() external view returns (uint256[2]) {
        return soil.getSeeds();
    }

    function getSeed(uint256 _id) external view returns (uint16, uint32, uint256[2], uint8[11], uint8[11]) {
        uint256[2] memory donors;
        uint8 _tomatoType;
        (donors, _tomatoType) = seedFarm.get(_id);

        uint8[11] memory a_donorTomatoTypes;
        uint8[11] memory b_donorTomatoTypes;
        uint32 rarity;
        uint16 gen;
        if (donors[0] == 0 && donors[1] == 0) {
            a_donorTomatoTypes[_tomatoType] = 100;
            b_donorTomatoTypes[_tomatoType] = 100;
            rarity = 3600;
        } else {
            a_donorTomatoTypes = tomatoFarmhand.getTomatoTypes(donors[0]);
            b_donorTomatoTypes = tomatoFarmhand.getTomatoTypes(donors[1]);
            rarity = tomatoFarmhand.getRarity(donors[0]).add(tomatoFarmhand.getRarity(donors[1])).div(2);
            uint16 _a_donorGeneration = tomatoFarmhand.getGeneration(donors[0]);
            uint16 _b_donorGeneration = tomatoFarmhand.getGeneration(donors[1]);
            gen = _max(_a_donorGeneration, _b_donorGeneration).add(1);
        }
        return (gen, rarity, donors, a_donorTomatoTypes, b_donorTomatoTypes);
    }

    function getTomatoChildren(uint256 _id) external view returns (
        uint256[10] tomatosChildren,
        uint256[10] seedsChildren
    ) {
        uint8 _counter;
        uint256[2] memory _donors;
        uint256 i;
        for (i = _id.add(1); i <= tomatoFarmhand.getAmount() && _counter < 10; i++) {
            _donors = tomatoFarmhand.getDonors(i);
            if (_donors[0] == _id || _donors[1] == _id) {
                tomatosChildren[_counter] = i;
                _counter = _counter.add(1);
            }
        }
        _counter = 0;
        uint256[] memory seeds = seedFarm.getAllSeeds();
        for (i = 0; i < seeds.length && _counter < 10; i++) {
            (_donors, ) = seedFarm.get(seeds[i]);
            if (_donors[0] == _id || _donors[1] == _id) {
                seedsChildren[_counter] = seeds[i];
                _counter = _counter.add(1);
            }
        }
    }

    function getTomatosFromRanking() external view returns (uint256[10]) {
        return ranking.getTomatosFromRanking();
    }

    function getRankingRewards(
        uint256 _remainingBean
    ) external view returns (
        uint256[10]
    ) {
        return ranking.getRewards(_remainingBean);
    }

    function getRankingRewardDate() external view returns (uint256, uint256) {
        return ranking.getDate();
    }

    function setInternalDependencies(address[] _newDependencies) public onlyOwner {
        super.setInternalDependencies(_newDependencies);
        tomatoFarm = TomatoFarm(_newDependencies[0]);
        tomatoFarmhand = TomatoFarmhand(_newDependencies[1]);
        tomatoMutation = TomatoMutation(_newDependencies[2]);
        seedFarm = SeedFarm(_newDependencies[3]);
        ranking = TomatoRanking(_newDependencies[4]);
        soil = Soil(_newDependencies[5]);
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

import "./Common/Upgradable.sol";
import "./Common/SafeMath256.sol";
import "./Common/SafeConvert.sol";

// ----------------------------------------------------------------------------
// --- Contract Harvest 
// ----------------------------------------------------------------------------

contract Harvest is Upgradable {
    using SafeMath256 for uint256;
    using SafeConvert for uint256;

    uint256 restAmount;
    uint256 releasedAmount;
    uint256 lastBlock;
    uint256 interval; 

    uint256 constant NUMBER_OF_TOMATO_TYPES = 5;

    constructor() public {
        releasedAmount = 10000;
        restAmount = releasedAmount;
        lastBlock = block.number; 
        interval = 1;
    }

    function _updateInterval() internal {
        if (restAmount == 5000) {
            interval = 2;
        } else if (restAmount == 3750) {
            interval = 4;
        } else if (restAmount == 2500) {
            interval = 8;
        } else if (restAmount == 1250) {
            interval = 16;
        }
    }

    function _burnGas() internal pure {
        uint256[26950] memory _local;
        for (uint256 i = 0; i < _local.length; i++) {
            _local[i] = i;
        }
    }

    function claim(uint8 _requestedType) external onlyFarmer returns (uint256, uint256, uint256) {
        require(restAmount > 0, "seeds are over");
        require(lastBlock.add(interval) <= block.number, "too early");
        uint256 _index = releasedAmount.sub(restAmount);
        uint8 currentType = (_index % NUMBER_OF_TOMATO_TYPES).toUint8();
        require(currentType == _requestedType, "not a current type of tomato");
        lastBlock = block.number;
        restAmount = restAmount.sub(1);
        _updateInterval();
        _burnGas();
        return (restAmount, lastBlock, interval);
    }

    function getInfo() external view returns (uint256, uint256, uint256, uint256, uint256) {
        return (
            restAmount,
            releasedAmount,
            lastBlock,
            interval,
            NUMBER_OF_TOMATO_TYPES
        );
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

import "./Market.sol";

// ----------------------------------------------------------------------------
// --- Contract AbilityMarket 
// ----------------------------------------------------------------------------

contract CloningMarket is Market {}

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

import "./Market.sol";

// ----------------------------------------------------------------------------
// --- Contract SeedMarket 
// ----------------------------------------------------------------------------

contract SeedMarket is Market {}

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

import "./Market.sol";

// ----------------------------------------------------------------------------
// --- Contract TomatoMarket 
// ----------------------------------------------------------------------------

contract TomatoMarket is Market {}

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
import "../Common/SafeMath256.sol";

// ----------------------------------------------------------------------------
// --- Contract AbilityMarket 
// ----------------------------------------------------------------------------

contract AbilityMarket is Upgradable {
    using SafeMath256 for uint256;
    mapping (uint256 => uint256) allTokensIndex;
    mapping (uint256 => uint256) tokenToPrice;
    uint256[] allTokens;
    function _checkTokenExistence(uint256 _id) internal view {
        require(tokenToPrice[_id] > 0, "ability is not on sale");
    }

    function sellToken(
        uint256 _tokenId,
        uint256 _price
    ) external onlyFarmer {
        require(_price > 0, "price must be more than 0");

        if (tokenToPrice[_tokenId] == 0) {
            allTokensIndex[_tokenId] = allTokens.length;
            allTokens.push(_tokenId);
        }
        tokenToPrice[_tokenId] = _price;
    }

    function removeFromAuction(uint256 _tokenId) external onlyFarmer {
        _checkTokenExistence(_tokenId);
        _remove(_tokenId);
    }

    function _remove(uint256 _tokenId) internal {
        require(allTokens.length > 0, "no auctions");
        delete tokenToPrice[_tokenId];
        uint256 tokenIndex = allTokensIndex[_tokenId];
        uint256 lastTokenIndex = allTokens.length.sub(1);
        uint256 lastToken = allTokens[lastTokenIndex];
        allTokens[tokenIndex] = lastToken;
        allTokens[lastTokenIndex] = 0;
        allTokens.length--;
        allTokensIndex[_tokenId] = 0;
        allTokensIndex[lastToken] = tokenIndex;
    }

    function getAuction(uint256 _id) external view returns (uint256) {
        _checkTokenExistence(_id);
        return tokenToPrice[_id];
    }

    function getAllTokens() external view returns (uint256[]) {
        return allTokens;
    }

    function totalSupply() public view returns (uint256) {
        return allTokens.length;
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

import "./Bean/Bean.sol";
import "./Common/Upgradable.sol";
import "./Common/SafeMath256.sol";

// ----------------------------------------------------------------------------
// --- Contract Farmhand 
// ----------------------------------------------------------------------------

contract Field is Upgradable {
    using SafeMath256 for uint256;

    Bean beanStalks;

    uint256 constant BEAN_DECIMALS = 10 ** 18;
    uint256 constant public sproutingPrice = 1000 * BEAN_DECIMALS;

    function giveBean(address _user, uint256 _amount) external onlyFarmer {
        beanStalks.transfer(_user, _amount);
    }

    function takeBean(uint256 _amount) external onlyFarmer {
        beanStalks.remoteTransfer(this, _amount);
    }

    function burnBean(uint256 _amount) external onlyFarmer {
        beanStalks.burn(_amount);
    }

    function remainingBean() external view returns (uint256) {
        return beanStalks.balanceOf(this);
    }

    function setInternalDependencies(address[] _newDependencies) public onlyOwner {
        super.setInternalDependencies(_newDependencies);

        beanStalks = Bean(_newDependencies[0]);
    }

    function migrate(address _newAddress) public onlyOwner {
        beanStalks.transfer(_newAddress, beanStalks.balanceOf(this));
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

import "../../Common/Upgradable.sol";
import "../../Common/Random.sol";
import "../../Clash.sol";
import "../../Bean/Bean.sol";
import "../../Farmhand.sol";
import "../../Field.sol";
import "./CropClashSilo.sol";
import "../Fan/CropClashFanSilo.sol";
import "../../Common/SafeMath256.sol";

// ----------------------------------------------------------------------------
// --- Contract CropClash 
// ----------------------------------------------------------------------------

contract CropClash is Upgradable {
    using SafeMath256 for uint256;

    Clash clash;
    Random random;
    Bean beanStalks;
    Farmhand farmhand;
    Field field;
    CropClashSilo _silo_;
    CropClashFanSilo fanSilo;

    uint8 constant MAX_TACTICS_PERCENTAGE = 80;
    uint8 constant MIN_TACTICS_PERCENTAGE = 20;
    uint8 constant MAX_TOMATO_STRENGTH_PERCENTAGE = 120;
    uint8 constant PERCENTAGE = 100;
    uint256 AUTO_SELECT_TIME = 6000;
    uint256 INTERVAL_FOR_NEW_BLOCK = 1000; 

    function() external payable {}

    function _safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        return b > a ? 0 : a.sub(b);
    }

    function _payForBet(
        uint256 _value,
        bool _isBean,
        uint256 _bet
    ) internal {
        if (_isBean) {
            require(_value == 0, "specify isBean as false to send eth");
            beanStalks.remoteTransfer(address(_silo_), _bet);
        } else {
            require(_value == _bet, "wrong eth amount");
            address(_silo_).transfer(_value);
        }
    }

    function _validateChallengeId(uint256 _challengeId) internal view {
        require(
            _challengeId > 0 &&
            _challengeId < _silo_.challengesAmount(),
            "wrong challenge id"
        );
    }

    function _validateTactics(uint8[2] _tactics) internal pure {
        require(
            _tactics[0] >= MIN_TACTICS_PERCENTAGE &&
            _tactics[0] <= MAX_TACTICS_PERCENTAGE &&
            _tactics[1] >= MIN_TACTICS_PERCENTAGE &&
            _tactics[1] <= MAX_TACTICS_PERCENTAGE,
            "tactics value must be between 20 and 80"
        );
    }

    function _checkTomatoAvailability(address _user, uint256 _tomatoId) internal view {
        require(farmhand.isTomatoOwner(_user, _tomatoId), "not a tomato owner");
        require(!farmhand.isTomatoOnSale(_tomatoId), "tomato is on sale");
        require(!farmhand.isCloningOnSale(_tomatoId), "tomato is on cloning sale");
        require(!isTomatoChallenging(_tomatoId), "this tomato has already applied");
    }

    function _checkTheClashHasNotOccurred(uint256 _challengeId) internal view {
        require(!_silo_.clashOccurred(_challengeId), "the clash has already occurred");
    }

    function _checkTheChallengeIsNotCancelled(uint256 _id) internal view {
        require(!_silo_.challengeCancelled(_id), "the challenge is cancelled");
    }

    function _checkTheOpponentIsNotSelected(uint256 _id) internal view {
        require(!_isOpponentSelected(_id), "opponent already selected");
    }

    function _checkThatTimeHasCome(uint256 _blockNumber) internal view {
        require(_blockNumber <= block.number, "time has not yet come");
    }

    function _checkChallengeCreator(uint256 _id, address _user) internal view {
        (address _creator, ) = _getCreator(_id);
        require(_creator == _user, "not a challenge creator");
    }

    function _checkForApplicants(uint256 _id) internal view {
        require(_getChallengeApplicantsAmount(_id) > 0, "no applicants");
    }

    function _compareApplicantsArrays(uint256 _challengeId, bytes32 _hash) internal view {
        uint256[] memory _applicants = _silo_.getChallengeApplicants(_challengeId);
        require(keccak256(abi.encode(_applicants)) == _hash, "wrong applicants array");
    }

    function _compareTomatoStrength(uint256 _challengeId, uint256 _applicantId) internal view {
        ( , uint256 _tomatoId) = _getCreator(_challengeId);
        uint256 _strength = farmhand.getTomatoStrength(_tomatoId);
        uint256 _applicantStrength = farmhand.getTomatoStrength(_applicantId);
        uint256 _maxStrength = _strength.mul(MAX_TOMATO_STRENGTH_PERCENTAGE).div(PERCENTAGE); // +20%
        require(_applicantStrength <= _maxStrength, "too strong tomato");
    }

    function _setChallengeCompensation(
        uint256 _challengeId,
        uint256 _bet,
        uint256 _applicantsAmount
    ) internal {
        _silo_.setCompensation(_challengeId, _bet.mul(3).div(10).div(_applicantsAmount));
    }

    function _isOpponentSelected(uint256 _challengeId) internal view returns (bool) {
        ( , uint256 _tomatoId) = _getOpponent(_challengeId);
        return _tomatoId != 0;
    }

    function _getChallengeApplicantsAmount(
        uint256 _challengeId
    ) internal view returns (uint256) {
        return _silo_.challengeApplicantsAmount(_challengeId);
    }

    function _getUserApplicationIndex(
        address _user,
        uint256 _challengeId
    ) internal view returns (uint256, bool, uint256) {
        return _silo_.userApplicationIndex(_user, _challengeId);
    }

    function _getChallenge(
        uint256 _id
    ) internal view returns (bool, uint256, uint256) {
        return _silo_.challenges(_id);
    }

    function _getCompensation(
        uint256 _id
    ) internal view returns (uint256) {
        return _silo_.challengeCompensation(_id);
    }

    function _getTomatoApplication(
        uint256 _id
    ) internal view returns (uint256, uint8[2], address) {
        return _silo_.getTomatoApplication(_id);
    }

    function _getClashBlockNumber(
        uint256 _id
    ) internal view returns (uint256) {
        return _silo_.clashBlockNumber(_id);
    }

    function _getCreator(
        uint256 _id
    ) internal view returns (address, uint256) {
        return _silo_.creator(_id);
    }

    function _getOpponent(
        uint256 _id
    ) internal view returns (address, uint256) {
        return _silo_.opponent(_id);
    }

    function _getFanBetsValue(
        uint256 _challengeId,
        bool _onCreator
    ) internal view returns (uint256) {
        return fanSilo.challengeBetsValue(_challengeId, _onCreator);
    }

    function isTomatoChallenging(uint256 _tomatoId) public view returns (bool) {
        (uint256 _challengeId, , ) = _getTomatoApplication(_tomatoId);
        if (_challengeId != 0) {
            if (_silo_.challengeCancelled(_challengeId)) {
                return false;
            }
            ( , uint256 _owner) = _getCreator(_challengeId);
            ( , uint256 _opponent) = _getOpponent(_challengeId);
            bool _isParticipant = (_tomatoId == _owner) || (_tomatoId == _opponent);

            if (_isParticipant) {
                return !_silo_.clashOccurred(_challengeId);
            }
            return !_isOpponentSelected(_challengeId);
        }
        return false;
    }

    function create(
        address _user,
        uint256 _tomatoId,
        uint8[2] _tactics,
        bool _isBean,
        uint256 _bet,
        uint16 _counter,
        uint256 _value 
    ) external onlyFarmer returns (uint256 challengeId) {
        _validateTactics(_tactics);
        _checkTomatoAvailability(_user, _tomatoId);
        require(_counter >= 5, "too few blocks");

        _payForBet(_value, _isBean, _bet);

        challengeId = _silo_.create(_isBean, _bet, _counter);
        _silo_.addUserChallenge(_user, challengeId);
        _silo_.setCreator(challengeId, _user, _tomatoId);
        _silo_.setTomatoApplication(_tomatoId, challengeId, _tactics, _user);
    }

    function apply(
        uint256 _challengeId,
        address _user,
        uint256 _tomatoId,
        uint8[2] _tactics,
        uint256 _value 
    ) external onlyFarmer {
        _validateChallengeId(_challengeId);
        _validateTactics(_tactics);
        _checkTheClashHasNotOccurred(_challengeId);
        _checkTheChallengeIsNotCancelled(_challengeId);
        _checkTheOpponentIsNotSelected(_challengeId);
        _checkTomatoAvailability(_user, _tomatoId);
        _compareTomatoStrength(_challengeId, _tomatoId);
        ( , bool _exist, ) = _getUserApplicationIndex(_user, _challengeId);
        require(!_exist, "you have already applied");

        (bool _isBean, uint256 _bet, ) = _getChallenge(_challengeId);

        _payForBet(_value, _isBean, _bet);

        _silo_.addUserApplication(_user, _challengeId, _tomatoId);
        _silo_.setTomatoApplication(_tomatoId, _challengeId, _tactics, _user);
        _silo_.addChallengeApplicant(_challengeId, _tomatoId);

        if (_getChallengeApplicantsAmount(_challengeId) == 1) {
            _silo_.setAutoSelectBlock(_challengeId, block.number.add(AUTO_SELECT_TIME));
        }
    }

    function chooseOpponent(
        address _user,
        uint256 _challengeId,
        uint256 _applicantId,
        bytes32 _applicantsHash
    ) external onlyFarmer {
        _validateChallengeId(_challengeId);
        _checkChallengeCreator(_challengeId, _user);
        _compareApplicantsArrays(_challengeId, _applicantsHash);
        _selectOpponent(_challengeId, _applicantId);
    }

    function autoSelectOpponent(
        uint256 _challengeId,
        bytes32 _applicantsHash
    ) external onlyFarmer returns (uint256 applicantId) {
        _validateChallengeId(_challengeId);
        _compareApplicantsArrays(_challengeId, _applicantsHash);
        uint256 _autoSelectBlock = _silo_.autoSelectBlock(_challengeId);
        require(_autoSelectBlock != 0, "no auto select");
        _checkThatTimeHasCome(_autoSelectBlock);

        _checkForApplicants(_challengeId);

        uint256 _applicantsAmount = _getChallengeApplicantsAmount(_challengeId);
        uint256 _index = random.random(2**256 - 1) % _applicantsAmount;
        applicantId = _silo_.challengeApplicants(_challengeId, _index);

        _selectOpponent(_challengeId, applicantId);
    }

    function _selectOpponent(uint256 _challengeId, uint256 _tomatoId) internal {
        _checkTheChallengeIsNotCancelled(_challengeId);
        _checkTheOpponentIsNotSelected(_challengeId);

        (
            uint256 _tomatoChallengeId, ,
            address _opponentUser
        ) = _getTomatoApplication(_tomatoId);
        ( , uint256 _creatorTomatoId) = _getCreator(_challengeId);

        require(_tomatoChallengeId == _challengeId, "wrong opponent");
        require(_creatorTomatoId != _tomatoId, "the same tomato");

        _silo_.setOpponent(_challengeId, _opponentUser, _tomatoId);

        ( , uint256 _bet, uint256 _counter) = _getChallenge(_challengeId);
        _silo_.setClashBlockNumber(_challengeId, block.number.add(_counter));

        _silo_.addUserChallenge(_opponentUser, _challengeId);
        _silo_.removeUserApplication(_opponentUser, _challengeId);

        // if there are more applicants than one just selected then set challenge compensation
        uint256 _applicantsAmount = _getChallengeApplicantsAmount(_challengeId);
        if (_applicantsAmount > 1) {
            uint256 _otherApplicants = _applicantsAmount.sub(1);
            _setChallengeCompensation(_challengeId, _bet, _otherApplicants);
        }
    }

    function _checkClashBlockNumber(uint256 _blockNumber) internal view {
        require(_blockNumber != 0, "opponent is not selected");
        _checkThatTimeHasCome(_blockNumber);
    }

    function _checkClashPossibilityAndGenerateRandom(uint256 _challengeId) internal view returns (uint256) {
        uint256 _blockNumber = _getClashBlockNumber(_challengeId);
        _checkClashBlockNumber(_blockNumber);
        require(_blockNumber >= _safeSub(block.number, 256), "time has passed");
        _checkTheClashHasNotOccurred(_challengeId);
        _checkTheChallengeIsNotCancelled(_challengeId);

        return random.randomOfBlock(2**256 - 1, _blockNumber);
    }

    function _payReward(uint256 _challengeId) internal returns (uint256 reward, bool isBean) {
        uint8 _factor = _getCompensation(_challengeId) > 0 ? 17 : 20;
        uint256 _bet;
        (isBean, _bet, ) = _getChallenge(_challengeId);
        ( , uint256 _creatorId) = _getCreator(_challengeId);
        (address _winner, uint256 _winnerId) = _silo_.winner(_challengeId);

        reward = _bet.mul(_factor).div(10);
        _silo_.payOut(
            _winner,
            isBean,
            reward
        );

        bool _didCreatorWin = _creatorId == _winnerId;
        uint256 _winnerBetsValue = _getFanBetsValue(_challengeId, _didCreatorWin);
        uint256 _opponentBetsValue = _getFanBetsValue(_challengeId, !_didCreatorWin);
        if (_opponentBetsValue > 0 && _winnerBetsValue > 0) {
            uint256 _rewardFromFanBets = _opponentBetsValue.mul(15).div(100);

            uint256 _challengeBalance = fanSilo.challengeBalance(_challengeId);
            require(_challengeBalance >= _rewardFromFanBets, "not enough coins, something went wrong");

            fanSilo.payOut(_winner, isBean, _rewardFromFanBets);

            _challengeBalance = _challengeBalance.sub(_rewardFromFanBets);
            fanSilo.setChallengeBalance(_challengeId, _challengeBalance);

            reward = reward.add(_rewardFromFanBets);
        }
    }

    function _setWinner(uint256 _challengeId, uint256 _tomatoId) internal {
        ( , , address _user) = _getTomatoApplication(_tomatoId);
        _silo_.setWinner(_challengeId, _user, _tomatoId);
    }

    function start(
        uint256 _challengeId
    ) external onlyFarmer returns (
        uint256 seed,
        uint256 clashId,
        uint256 reward,
        bool isBean
    ) {
        _validateChallengeId(_challengeId);
        seed = _checkClashPossibilityAndGenerateRandom(_challengeId);

        ( , uint256 _firstTomatoId) = _getCreator(_challengeId);
        ( , uint256 _secondTomatoId) = _getOpponent(_challengeId);

        ( , uint8[2] memory _firstTactics, ) = _getTomatoApplication(_firstTomatoId);
        ( , uint8[2] memory _secondTactics, ) = _getTomatoApplication(_secondTomatoId);

        uint256[2] memory winnerLooserIds;
        (
            winnerLooserIds, , , , , clashId
        ) = clash.start(
            _firstTomatoId,
            _secondTomatoId,
            _firstTactics,
            _secondTactics,
            seed,
            true
        );

        _setWinner(_challengeId, winnerLooserIds[0]);

        _silo_.setClashOccurred(_challengeId);
        _silo_.setChallengeClashId(_challengeId, clashId);

        (reward, isBean) = _payReward(_challengeId);
    }

    function cancel(
        address _user,
        uint256 _challengeId,
        bytes32 _applicantsHash
    ) external onlyFarmer {
        _validateChallengeId(_challengeId);
        _checkChallengeCreator(_challengeId, _user);
        _checkTheOpponentIsNotSelected(_challengeId);
        _checkTheChallengeIsNotCancelled(_challengeId);
        _compareApplicantsArrays(_challengeId, _applicantsHash);

        (bool _isBean, uint256 _value /* bet */, ) = _getChallenge(_challengeId);
        uint256 _applicantsAmount = _getChallengeApplicantsAmount(_challengeId);
        
        if (_applicantsAmount > 0) {
            _setChallengeCompensation(_challengeId, _value, _applicantsAmount); 
            _value = _value.mul(7).div(10); 
        }
        _silo_.payOut(_user, _isBean, _value);
        _silo_.setChallengeCancelled(_challengeId);
    }

    function returnBet(address _user, uint256 _challengeId) external onlyFarmer {
        _validateChallengeId(_challengeId);
        ( , bool _exist, uint256 _tomatoId) = _getUserApplicationIndex(_user, _challengeId);
        require(_exist, "wrong challenge");

        (bool _isBean, uint256 _bet, ) = _getChallenge(_challengeId);
        uint256 _compensation = _getCompensation(_challengeId);
        uint256 _value = _bet.add(_compensation);
        _silo_.payOut(_user, _isBean, _value);
        _silo_.removeTomatoApplication(_tomatoId, _challengeId);
        _silo_.removeUserApplication(_user, _challengeId);

        if (_getChallengeApplicantsAmount(_challengeId) == 0) {
            _silo_.setAutoSelectBlock(_challengeId, 0);
        }
    }

    function addTimeForOpponentSelect(
        address _user,
        uint256 _challengeId
    ) external onlyFarmer returns (uint256 newAutoSelectBlock) {
        _validateChallengeId(_challengeId);
        _checkChallengeCreator(_challengeId, _user);
        _checkForApplicants(_challengeId);
        _checkTheOpponentIsNotSelected(_challengeId);
        _checkTheChallengeIsNotCancelled(_challengeId);
        uint256 _price = _silo_.getExtensionTimePrice(_challengeId);

        field.takeBean(_price);
        _silo_.setExtensionTimePrice(_challengeId, _price.mul(2));
        uint256 _autoSelectBlock = _silo_.autoSelectBlock(_challengeId);
        newAutoSelectBlock = _autoSelectBlock.add(AUTO_SELECT_TIME);
        _silo_.setAutoSelectBlock(_challengeId, newAutoSelectBlock);
    }

    function updateClashBlockNumber(
        uint256 _challengeId
    ) external onlyFarmer returns (uint256 newClashBlockNumber) {
        _validateChallengeId(_challengeId);
        _checkTheClashHasNotOccurred(_challengeId);
        _checkTheChallengeIsNotCancelled(_challengeId);
        uint256 _blockNumber = _getClashBlockNumber(_challengeId);
        _checkClashBlockNumber(_blockNumber);
        require(_blockNumber < _safeSub(block.number, 256), "you can start a clash");

        newClashBlockNumber = block.number.add(INTERVAL_FOR_NEW_BLOCK);
        _silo_.setClashBlockNumber(_challengeId, newClashBlockNumber);
    }

    function setInternalDependencies(address[] _newDependencies) public onlyOwner {
        super.setInternalDependencies(_newDependencies);

        clash = Clash(_newDependencies[0]);
        random = Random(_newDependencies[1]);
        beanStalks = Bean(_newDependencies[2]);
        farmhand = Farmhand(_newDependencies[3]);
        field = Field(_newDependencies[4]);
        _silo_ = CropClashSilo(_newDependencies[5]);
        fanSilo = CropClashFanSilo(_newDependencies[6]);
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

import "../../Common/Upgradable.sol";
import "../../Bean/Bean.sol";
import "../../Common/SafeMath256.sol";

// ----------------------------------------------------------------------------
// --- Contract CropClashSilo 
// ----------------------------------------------------------------------------

contract CropClashSilo is Upgradable {
    using SafeMath256 for uint256;

    Bean beanStalks;

    uint256 EXTENSION_TIME_START_PRICE;

    struct Participant { 
        address user;
        uint256 tomatoId;
    }

    struct Challenge {
        bool isBean; 
        uint256 bet;
        uint16 counter; 
    }

    Challenge[] public challenges;

    mapping (uint256 => Participant) public creator;
    mapping (uint256 => Participant) public opponent;
    mapping (uint256 => Participant) public winner; 
    mapping (uint256 => uint256) public clashBlockNumber;
    mapping (uint256 => bool) public clashOccurred;
    mapping (uint256 => uint256) public autoSelectBlock;
    mapping (uint256 => bool) public challengeCancelled;
    mapping (uint256 => uint256) public challengeCompensation;
    mapping (uint256 => uint256) extensionTimePrice;

    struct TomatoApplication {
        uint256 challengeId;
        uint8[2] tactics;
        address owner;
    }

    struct UserApplication {
        uint256 index;
        bool exist;
        uint256 tomatoId; 
    }

    mapping (address => uint256[]) userChallenges;
    mapping (uint256 => uint256[]) public challengeApplicants;
    mapping (uint256 => uint256) applicantIndex;
    mapping (address => uint256[]) userApplications;
    mapping (address => mapping(uint256 => UserApplication)) public userApplicationIndex;
    mapping (uint256 => TomatoApplication) tomatoApplication;
    mapping (uint256 => uint256) challengeClashId;

    constructor() public {
        challenges.length = 1; 
        EXTENSION_TIME_START_PRICE = 50 * (10 ** 18);
    }

    function() external payable {}

    function payOut(address _user, bool _isBean, uint256 _value) external onlyFarmer {
        if (_isBean) {
            beanStalks.transfer(_user, _value);
        } else {
            _user.transfer(_value);
        }
    }

    function create(
        bool _isBean,
        uint256 _bet,
        uint16 _counter
    ) external onlyFarmer returns (uint256 challengeId) {
        Challenge memory _challenge = Challenge({
            isBean: _isBean,
            bet: _bet,
            counter: _counter
        });
        challengeId = challenges.length;
        challenges.push(_challenge);
    }

    function addUserChallenge(address _user, uint256 _challengeId) external onlyFarmer {
        userChallenges[_user].push(_challengeId);
    }

    function setCreator(
        uint256 _challengeId,
        address _user,
        uint256 _tomatoId
    ) external onlyFarmer {
        creator[_challengeId] = Participant(_user, _tomatoId);
    }

    function setOpponent(
        uint256 _challengeId,
        address _user,
        uint256 _tomatoId
    ) external onlyFarmer {
        opponent[_challengeId] = Participant(_user, _tomatoId);
    }

    function setWinner(
        uint256 _challengeId,
        address _user,
        uint256 _tomatoId
    ) external onlyFarmer {
        winner[_challengeId] = Participant(_user, _tomatoId);
    }

    function setTomatoApplication(
        uint256 _tomatoId,
        uint256 _challengeId,
        uint8[2] _tactics,
        address _user
    ) external onlyFarmer {
        tomatoApplication[_tomatoId] = TomatoApplication(_challengeId, _tactics, _user);
    }

    function removeTomatoApplication(
        uint256 _tomatoId,
        uint256 _challengeId
    ) external onlyFarmer {
        if (tomatoApplication[_tomatoId].challengeId == _challengeId) {
            uint256 _index = applicantIndex[_tomatoId];
            uint256 _lastIndex = challengeApplicants[_challengeId].length.sub(1);
            uint256 _lastItem = challengeApplicants[_challengeId][_lastIndex];
            challengeApplicants[_challengeId][_index] = _lastItem;
            challengeApplicants[_challengeId][_lastIndex] = 0;
            challengeApplicants[_challengeId].length--;
            delete applicantIndex[_tomatoId];
        }
        delete tomatoApplication[_tomatoId];
    }

    function addUserApplication(
        address _user,
        uint256 _challengeId,
        uint256 _tomatoId
    ) external onlyFarmer {
        uint256 _index = userApplications[_user].length;
        userApplications[_user].push(_challengeId);
        userApplicationIndex[_user][_challengeId] = UserApplication(_index, true, _tomatoId);
    }

    function removeUserApplication(
        address _user,
        uint256 _challengeId
    ) external onlyFarmer {
        uint256 _index = userApplicationIndex[_user][_challengeId].index;
        uint256 _lastIndex = userApplications[_user].length.sub(1);
        uint256 _lastItem = userApplications[_user][_lastIndex];
        userApplications[_user][_index] = _lastItem;
        userApplications[_user][_lastIndex] = 0;
        userApplications[_user].length--;
        delete userApplicationIndex[_user][_challengeId];
        userApplicationIndex[_user][_lastItem].index = _index;
    }

    function addChallengeApplicant(
        uint256 _challengeId,
        uint256 _tomatoId
    ) external onlyFarmer {
        uint256 _applicantIndex = challengeApplicants[_challengeId].length;
        challengeApplicants[_challengeId].push(_tomatoId);
        applicantIndex[_tomatoId] = _applicantIndex;
    }

    function setAutoSelectBlock(
        uint256 _challengeId,
        uint256 _number
    ) external onlyFarmer {
        autoSelectBlock[_challengeId] = _number;
    }

    function setClashBlockNumber(
        uint256 _challengeId,
        uint256 _number
    ) external onlyFarmer {
        clashBlockNumber[_challengeId] = _number;
    }

    function setCompensation(
        uint256 _challengeId,
        uint256 _value
    ) external onlyFarmer {
        challengeCompensation[_challengeId] = _value;
    }

    function setClashOccurred(
        uint256 _challengeId
    ) external onlyFarmer {
        clashOccurred[_challengeId] = true;
    }

    function setChallengeClashId(
        uint256 _challengeId,
        uint256 _clashId
    ) external onlyFarmer {
        challengeClashId[_challengeId] = _clashId;
    }

    function setChallengeCancelled(
        uint256 _challengeId
    ) external onlyFarmer {
        challengeCancelled[_challengeId] = true;
    }

    function setExtensionTimePrice(
        uint256 _challengeId,
        uint256 _value
    ) external onlyFarmer {
        extensionTimePrice[_challengeId] = _value;
    }

    function setExtensionTimeStartPrice(
        uint256 _value
    ) external onlyFarmer {
        EXTENSION_TIME_START_PRICE = _value;
    }

    function challengesAmount() external view returns (uint256) {
        return challenges.length;
    }

    function getUserChallenges(address _user) external view returns (uint256[]) {
        return userChallenges[_user];
    }

    function getChallengeApplicants(uint256 _challengeId) external view returns (uint256[]) {
        return challengeApplicants[_challengeId];
    }

    function challengeApplicantsAmount(uint256 _challengeId) external view returns (uint256) {
        return challengeApplicants[_challengeId].length;
    }

    function getTomatoApplication(uint256 _tomatoId) external view returns (uint256, uint8[2], address) {
        return (
            tomatoApplication[_tomatoId].challengeId,
            tomatoApplication[_tomatoId].tactics,
            tomatoApplication[_tomatoId].owner
        );
    }

    function getUserApplications(address _user) external view returns (uint256[]) {
        return userApplications[_user];
    }

    function getExtensionTimePrice(uint256 _challengeId) public view returns (uint256) {
        uint256 _price = extensionTimePrice[_challengeId];
        return _price != 0 ? _price : EXTENSION_TIME_START_PRICE;
    }

    function getChallengeParticipants(
        uint256 _challengeId
    ) external view returns (
        address firstUser,
        uint256 firstTomatoId,
        address secondUser,
        uint256 secondTomatoId,
        address winnerUser,
        uint256 winnerTomatoId
    ) {
        firstUser = creator[_challengeId].user;
        firstTomatoId = creator[_challengeId].tomatoId;
        secondUser = opponent[_challengeId].user;
        secondTomatoId = opponent[_challengeId].tomatoId;
        winnerUser = winner[_challengeId].user;
        winnerTomatoId = winner[_challengeId].tomatoId;
    }

    function getChallengeDetails(
        uint256 _challengeId
    ) external view returns (
        bool isBean,
        uint256 bet,
        uint16 counter,
        uint256 blockNumber,
        bool active,
        uint256 opponentAutoSelectBlock,
        bool cancelled,
        uint256 compensation,
        uint256 selectionExtensionTimePrice,
        uint256 clashId
    ) {
        isBean = challenges[_challengeId].isBean;
        bet = challenges[_challengeId].bet;
        counter = challenges[_challengeId].counter;
        blockNumber = clashBlockNumber[_challengeId];
        active = !clashOccurred[_challengeId];
        opponentAutoSelectBlock = autoSelectBlock[_challengeId];
        cancelled = challengeCancelled[_challengeId];
        compensation = challengeCompensation[_challengeId];
        selectionExtensionTimePrice = getExtensionTimePrice(_challengeId);
        clashId = challengeClashId[_challengeId];
    }

    function setInternalDependencies(address[] _newDependencies) public onlyOwner {
        super.setInternalDependencies(_newDependencies);
        beanStalks = Bean(_newDependencies[0]);
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

import "../Common/Upgradable.sol";
import "../Common/SafeMath256.sol";

// ----------------------------------------------------------------------------
// --- Contract TomatoRanking 
// ----------------------------------------------------------------------------

contract TomatoRanking is Upgradable {
    using SafeMath256 for uint256;

    struct Ranking {
        uint256 id;
        uint32 rarity;
    }

    Ranking[10] ranking;

    uint256 constant REWARDED_TOMATOS_AMOUNT = 10;
    uint256 constant DISTRIBUTING_FRACTION_OF_REMAINING_BEAN = 10000;
    uint256 rewardPeriod = 24 hours;
    uint256 lastRewardDate;

    constructor() public {
        lastRewardDate = now; 
    }

    function update(uint256 _id, uint32 _rarity) external onlyFarmer {
        uint256 _index;
        bool _isIndex;
        uint256 _existingIndex;
        bool _isExistingIndex;

        if (_rarity > ranking[ranking.length.sub(1)].rarity) {

            for (uint256 i = 0; i < ranking.length; i = i.add(1)) {
                if (_rarity > ranking[i].rarity && !_isIndex) {
                    _index = i;
                    _isIndex = true;
                }
                if (ranking[i].id == _id && !_isExistingIndex) {
                    _existingIndex = i;
                    _isExistingIndex = true;
                }
                if(_isIndex && _isExistingIndex) break;
            }
            if (_isExistingIndex && _index >= _existingIndex) {
                ranking[_existingIndex] = Ranking(_id, _rarity);
            } else if (_isIndex) {
                _add(_index, _existingIndex, _isExistingIndex, _id, _rarity);
            }
        }
    }

    function _add(
        uint256 _index,
        uint256 _existingIndex,
        bool _isExistingIndex,
        uint256 _id,
        uint32 _rarity
    ) internal {
        uint256 _length = ranking.length;
        uint256 _indexTo = _isExistingIndex ? _existingIndex : _length.sub(1);
        for (uint256 i = _indexTo; i > _index; i = i.sub(1)){
            ranking[i] = ranking[i.sub(1)];
        }

        ranking[_index] = Ranking(_id, _rarity);
    }

    function getTomatosFromRanking() external view returns (uint256[10] result) {
        for (uint256 i = 0; i < ranking.length; i = i.add(1)) {
            result[i] = ranking[i].id;
        }
    }

    function updateRewardTime() external onlyFarmer {
        require(lastRewardDate.add(rewardPeriod) < now, "too early"); 
        lastRewardDate = now; 
    }

    function getRewards(uint256 _remainingBean) external view returns (uint256[10] rewards) {
        for (uint8 i = 0; i < REWARDED_TOMATOS_AMOUNT; i++) {
            rewards[i] = _remainingBean.mul(uint256(2).pow(REWARDED_TOMATOS_AMOUNT.sub(1))).div(
                DISTRIBUTING_FRACTION_OF_REMAINING_BEAN.mul((uint256(2).pow(REWARDED_TOMATOS_AMOUNT)).sub(1)).mul(uint256(2).pow(i))
            );
        }
    }

    function getDate() external view returns (uint256, uint256) {
        return (lastRewardDate, rewardPeriod);
    }
}

pragma solidity 0.4.25;

import "../Common/Upgradable.sol";
import "./SeedSilo.sol";

contract SeedFarm is Upgradable {
    SeedSilo _silo_;

    function getAmount() external view returns (uint256) {
        return _silo_.totalSupply();
    }

    function getAllSeeds() external view returns (uint256[]) {
        return _silo_.getAllTokens();
    }

    function isOwner(address _user, uint256 _tokenId) external view returns (bool) {
        return _user == _silo_.ownerOf(_tokenId);
    }

    function ownerOf(uint256 _tokenId) external view returns (address) {
        return _silo_.ownerOf(_tokenId);
    }

    function create(
        address _sender,
        uint256[2] _donors,
        uint8 _tomatoType
    ) external onlyFarmer returns (uint256) {
        return _silo_.push(_sender, _donors, _tomatoType);
    }

    function remove(address _owner, uint256 _id) external onlyFarmer {
        _silo_.remove(_owner, _id);
    }

    function get(uint256 _id) external view returns (uint256[2], uint8) {
        require(_silo_.exists(_id), "seed doesn't exist");
        return _silo_.get(_id);
    }

    function setInternalDependencies(address[] _newDependencies) public onlyOwner {
        super.setInternalDependencies(_newDependencies);

        _silo_ = SeedSilo(_newDependencies[0]);
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

import "./Common/Upgradable.sol";
import "./Common/Random.sol";
import "./Common/SafeMath8.sol";
import "./Common/SafeMath256.sol";

// ----------------------------------------------------------------------------
// --- Contract Soil 
// ----------------------------------------------------------------------------

contract Soil is Upgradable {
    using SafeMath8 for uint8;
    using SafeMath256 for uint256;
    Random random;
    uint256[2] seeds;
    uint256 lastBlockNumber;
    bool isFull;
    mapping (uint256 => bool) public inSoil;

    function add(
        uint256 _id
    ) external onlyFarmer returns (
        bool isSprouted,
        uint256 sproutedId,
        uint256 randomForSeedOpening
    ) {
        require(!inSoil[_id], "seed is already in soil");
        require(block.number > lastBlockNumber, "only 1 seed in a block");
        lastBlockNumber = block.number;
        inSoil[_id] = true;

        if (isFull) {
            isSprouted = true;
            sproutedId = seeds[0];
            randomForSeedOpening = random.random(2**256 - 1);
            seeds[0] = seeds[1];
            seeds[1] = _id;
            delete inSoil[sproutedId];
        } else {
            uint8 _index = seeds[0] == 0 ? 0 : 1;
            seeds[_index] = _id;
            if (_index == 1) {
                isFull = true;
            }
        }
    }

    function getSeeds() external view returns (uint256[2]) {
        return seeds;
    }

    function setInternalDependencies(address[] _newDependencies) public onlyOwner {
        super.setInternalDependencies(_newDependencies);

        random = Random(_newDependencies[0]);
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

import "../Common/ERC721/ERC721Token.sol";

contract SeedSilo is ERC721Token {
    struct Seed {
        uint256[2] donors;
        uint8 tomatoType; // used for genesis only
    }

    Seed[] seeds;

    constructor(string _name, string _symbol) public ERC721Token(_name, _symbol) {
        seeds.length = 1; // to avoid some issues with 0
    }

    function push(address _sender, uint256[2] _donors, uint8 _tomatoType) public onlyFarmer returns (uint256 id) {
        Seed memory _seed = Seed(_donors, _tomatoType);
        id = seeds.push(_seed).sub(1);
        _mint(_sender, id);
    }

    function get(uint256 _id) external view returns (uint256[2], uint8) {
        return (seeds[_id].donors, seeds[_id].tomatoType);
    }

    function remove(address _owner, uint256 _id) external onlyFarmer {
        delete seeds[_id];
        _burn(_owner, _id);
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
import "../Common/SafeMath256.sol";

// ----------------------------------------------------------------------------
// --- Contract Market
// ----------------------------------------------------------------------------

contract Market is Upgradable {
    using SafeMath256 for uint256;

    struct Auction {
        address seller;
        uint256 startPrice;
        uint256 endPrice;
        uint16 period;
        uint256 created;
        bool isBean;
    }

    uint256 constant MULTIPLIER = 1000000;
    uint16 constant MAX_PERIOD = 8760;

    uint8 constant FLAT_TYPE = 0;
    uint8 constant INCREASING_TYPE = 1;
    uint8 constant DUTCH_TYPE = 2;

    mapping (address => uint256[]) internal ownedTokens;
    mapping (uint256 => uint256) internal ownedTokensIndex;
    mapping (uint256 => uint256) allTokensIndex;
    mapping (uint256 => Auction) tokenToAuction;

    uint256[] allTokens;
	uint256 onlyBeanDate;

    constructor() public {
        onlyBeanDate = now.add(2 days);
    }

    function sellToken(
        uint256 _tokenId,
        address _seller,
        uint256 _startPrice,
        uint256 _endPrice,
        uint16 _period,
        bool _isBean
    ) external onlyFarmer {
        Auction memory _auction;

        require(_startPrice > 0 && _endPrice > 0, "price must be more than 0");
        if (_startPrice != _endPrice) {
            require(_period > 0 && _period <= MAX_PERIOD, "wrong period value");
        }
        _auction = Auction(_seller, _startPrice, _endPrice, _period, now, _isBean);

        if (tokenToAuction[_tokenId].seller == address(0)) {
            uint256 length = ownedTokens[_seller].length;
            ownedTokens[_seller].push(_tokenId);
            ownedTokensIndex[_tokenId] = length;
            allTokensIndex[_tokenId] = allTokens.length;
            allTokens.push(_tokenId);
        }
        tokenToAuction[_tokenId] = _auction;
    }

    function removeFromAuction(uint256 _tokenId) external onlyFarmer {
        address _seller = tokenToAuction[_tokenId].seller;
        require(_seller != address(0), "token is not on sale");
        _remove(_seller, _tokenId);
    }

    function buyToken(
        uint256 _tokenId,
        uint256 _value,
        uint256 _expectedPrice,
        bool _expectedIsBean
    ) external onlyFarmer returns (uint256 price) {
        Auction memory _auction = tokenToAuction[_tokenId];

        require(_auction.seller != address(0), "invalid address");
        require(_auction.isBean == _expectedIsBean, "wrong currency");
        price = _getCurrentPrice(_tokenId);
        require(price <= _expectedPrice, "wrong price");
        require(price <= _value, "not enough ether/bean");

        _remove(_auction.seller, _tokenId);
    }

    function _remove(address _from, uint256 _tokenId) internal {
        require(allTokens.length > 0, "no auctions");

        delete tokenToAuction[_tokenId];

        _removeFrom(_from, _tokenId);

        uint256 tokenIndex = allTokensIndex[_tokenId];
        uint256 lastTokenIndex = allTokens.length.sub(1);
        uint256 lastToken = allTokens[lastTokenIndex];

        allTokens[tokenIndex] = lastToken;
        allTokens[lastTokenIndex] = 0;

        allTokens.length--;
        allTokensIndex[_tokenId] = 0;
        allTokensIndex[lastToken] = tokenIndex;
    }

    function _removeFrom(address _from, uint256 _tokenId) internal {
        require(ownedTokens[_from].length > 0, "no seller auctions");

        uint256 tokenIndex = ownedTokensIndex[_tokenId];
        uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
        uint256 lastToken = ownedTokens[_from][lastTokenIndex];

        ownedTokens[_from][tokenIndex] = lastToken;
        ownedTokens[_from][lastTokenIndex] = 0;

        ownedTokens[_from].length--;
        ownedTokensIndex[_tokenId] = 0;
        ownedTokensIndex[lastToken] = tokenIndex;
    }

    function _getCurrentPrice(uint256 _id) internal view returns (uint256) {
        Auction memory _auction = tokenToAuction[_id];
        if (_auction.startPrice == _auction.endPrice) {
            return _auction.startPrice;
        }
        return _calculateCurrentPrice(
            _auction.startPrice,
            _auction.endPrice,
            _auction.period,
            _auction.created
        );
    }

    function _calculateCurrentPrice(
        uint256 _startPrice,
        uint256 _endPrice,
        uint16 _period,
        uint256 _created
    ) internal view returns (uint256) {
        bool isIncreasingType = _startPrice < _endPrice;
        uint256 _fullPeriod = uint256(1 hours).mul(_period); // price changing period
        uint256 _interval = isIncreasingType ? _endPrice.sub(_startPrice) : _startPrice.sub(_endPrice);
        uint256 _pastTime = now.sub(_created); // solium-disable-line security/no-block-members
        if (_pastTime >= _fullPeriod) return _endPrice;
        // how much is _pastTime in percents to period
        uint256 _percent = MULTIPLIER.sub(_fullPeriod.sub(_pastTime).mul(MULTIPLIER).div(_fullPeriod));
        uint256 _diff = _interval.mul(_percent).div(MULTIPLIER);
        return isIncreasingType ? _startPrice.add(_diff) : _startPrice.sub(_diff);
    }

    function sellerOf(uint256 _id) external view returns (address) {
        return tokenToAuction[_id].seller;
    }

    function getAuction(uint256 _id) external view returns (
        address, uint256, uint256, uint256, uint16, uint256, bool
    ) {
        Auction memory _auction = tokenToAuction[_id];
        return (
            _auction.seller,
            _getCurrentPrice(_id),
            _auction.startPrice,
            _auction.endPrice,
            _auction.period,
            _auction.created,
            _auction.isBean
        );
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

import "./ERC20.sol";
import "../Common/Upgradable.sol";

// ----------------------------------------------------------------------------
// --- Contract Bean
// ----------------------------------------------------------------------------

contract Bean is ERC20, Upgradable {
    uint256 constant DEVS_STAKE = 6;

    address[3] founders = [
        0xc14E8600Fa952A856035fA58090C410604b9Ff7C,
        0xc14E8600Fa952A856035fA58090C410604b9Ff7C,
        0xc14E8600Fa952A856035fA58090C410604b9Ff7C
    ];

    address foundation = 0xc14E8600Fa952A856035fA58090C410604b9Ff7C;
    address Blockhaus = 0xc14E8600Fa952A856035fA58090C410604b9Ff7C;

    string constant WP_IPFS_HASH = "QmfR75tK12q2LpkU5dzYqykUUpYswSiewpCbDuwYhRb6M5";


    constructor(address field) public {
        name = "Tomatoereum Bean";
        symbol = "BEAN";
        decimals = 18;

        uint256 _foundersBean = 6000000 * 10**18;
        uint256 _foundationBean = 6000000 * 10**18;
        uint256 _BlockhausBean = 3000000 * 10**18;
        uint256 _gameAccountBean = 45000000 * 10**18;

        uint256 _founderStake = _foundersBean.div(founders.length);
        for (uint256 i = 0; i < founders.length; i++) {
            _mint(founders[i], _founderStake);
        }

        _mint(foundation, _foundationBean);
        _mint(Blockhaus, _BlockhausBean);
        _mint(field, _gameAccountBean);

        require(_totalSupply == 60000000 * 10**18, "wrong total supply");
    }

    function remoteTransfer(address _to, uint256 _value) external onlyFarmer {
        _transfer(tx.origin, _to, _value);
    }

    function burn(uint256 _value) external onlyFarmer {
        _burn(msg.sender, _value);
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

import "./IERC20.sol";
import "../Common/SafeMath256.sol";

// ----------------------------------------------------------------------------
// --- Contract ERC20 
// ----------------------------------------------------------------------------

contract ERC20 is IERC20 {
    using SafeMath256 for uint256;

    mapping (address => uint256) _balances;

    mapping (address => mapping (address => uint256)) _allowed;

    uint256 _totalSupply;

    string public name;
    string public symbol;
    uint8 public decimals;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    function allowance(
        address owner,
        address spender
    )
      public
      view
      returns (uint256)
    {
        return _allowed[owner][spender];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function _validateAddress(address _addr) internal pure {
        require(_addr != address(0), "invalid address");
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _validateAddress(spender);

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    )
      public
      returns (bool)
    {
        require(value <= _allowed[from][msg.sender], "not enough allowed tokens");

        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    )
      public
      returns (bool)
    {
        _validateAddress(spender);

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    )
      public
      returns (bool)
    {
        _validateAddress(spender);

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(value <= _balances[from], "not enough tokens");
        _validateAddress(to);

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    function _mint(address account, uint256 value) internal {
        _validateAddress(account);
        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    function _burn(address account, uint256 value) internal {
        _validateAddress(account);
        require(value <= _balances[account], "not enough tokens to burn");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    function _burnFrom(address account, uint256 value) internal {
        require(value <= _allowed[account][msg.sender], "not enough allowed tokens to burn");

        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
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
// --- Contract IERC20 
// ----------------------------------------------------------------------------

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
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

import "./Common/Upgradable.sol";
import "./Farmhand.sol";
import "./Common/SafeMath8.sol";
import "./Common/SafeMath32.sol";
import "./Common/SafeMath256.sol";
import "./Common/SafeConvert.sol";

// ----------------------------------------------------------------------------
// --- Contract Clash 
// ----------------------------------------------------------------------------

contract Clash is Upgradable {
    using SafeMath8 for uint8;
    using SafeMath32 for uint32;
    using SafeMath256 for uint256;
    using SafeConvert for uint256;

    Farmhand farmhand;

    struct Tomato {
        uint256 id;
        uint8 attackChance;
        uint8 meleeChance;
        uint32 health;
        uint32 radiation;
        uint32 speed;
        uint32 attack;
        uint32 defense;
        uint32 specialAttackCost;
        uint8 specialAttackFactor;
        uint8 specialAttackChance;
        uint32 specialDefenseCost;
        uint8 specialDefenseFactor;
        uint8 specialDefenseChance;
        bool blocking;
        bool specialBlocking;
    }

    uint8 constant __FLOAT_NUMBER_MULTIPLY = 10;
    uint8 constant DISTANCE_ATTACK_WEAK__ = 8;
    uint8 constant DEFENSE_SUCCESS_MULTIPLY__ = 10;
    uint8 constant DEFENSE_FAIL_MULTIPLY__ = 2;
    uint8 constant FALLBACK_SPEED_FACTOR__ = 7;

    uint32 constant MAX_MELEE_ATTACK_DISTANCE = 100;
    uint32 constant MIN_RANGE_ATTACK_DISTANCE = 300;

    uint8 constant MAX_TURNS = 70;

    uint8 constant TOMATO_TYPE_FACTOR = 5;

    uint16 constant TOMATO_TYPE_MULTIPLY = 1600;

    uint8 constant PERCENT_MULTIPLIER = 100;

    uint256 clashsCounter;

    function _getRandomNumber(
        uint256 _initialSeed,
        uint256 _currentSeed_
    ) internal pure returns(uint8, uint256) {
        uint256 _currentSeed = _currentSeed_;
        if (_currentSeed == 0) {
            _currentSeed = _initialSeed;
        }
        uint8 _random = (_currentSeed % 100).toUint8();
        _currentSeed = _currentSeed.div(100);
        return (_random, _currentSeed);
    }

    function _safeSub(uint32 a, uint32 b) internal pure returns(uint32) {
        return b > a ? 0 : a.sub(b);
    }

    function _multiplyByFloatNumber(uint32 _number, uint8 _multiplier) internal pure returns (uint32) {
        return _number.mul(_multiplier).div(__FLOAT_NUMBER_MULTIPLY);
    }

    function _calculatePercentage(uint32 _part, uint32 _full) internal pure returns (uint32) {
        return _part.mul(PERCENT_MULTIPLIER).div(_full);
    }

    function _calculateTomatoTypeMultiply(uint8[11] _attackerTypesArray, uint8[11] _defenderTypesArray) internal pure returns (uint32) {
        uint32 tomatoTypeSumMultiply = 0;
        uint8 _currentDefenderType;
        uint32 _tomatoTypeMultiply;

        for (uint8 _attackerType = 0; _attackerType < _attackerTypesArray.length; _attackerType++) {
            if (_attackerTypesArray[_attackerType] != 0) {
                for (uint8 _defenderType = 0; _defenderType < _defenderTypesArray.length; _defenderType++) {
                    if (_defenderTypesArray[_defenderType] != 0) {
                        _currentDefenderType = _defenderType;

                        if (_currentDefenderType < _attackerType) {
                            _currentDefenderType = _currentDefenderType.add(_defenderTypesArray.length.toUint8());
                        }

                        if (_currentDefenderType.add(_attackerType).add(1) % 2 == 0) {
                            _tomatoTypeMultiply = _attackerTypesArray[_attackerType];
                            _tomatoTypeMultiply = _tomatoTypeMultiply.mul(_defenderTypesArray[_defenderType]);
                            tomatoTypeSumMultiply = tomatoTypeSumMultiply.add(_tomatoTypeMultiply);
                        }
                    }
                }
            }
        }

        return _multiplyByFloatNumber(tomatoTypeSumMultiply, TOMATO_TYPE_FACTOR).add(TOMATO_TYPE_MULTIPLY);
    }

    function _initFarmhouseTomato(
        uint256 _id,
        uint256 _opponentId,
        uint8 _meleeChance,
        uint8 _attackChance,
        bool _isCrop
    ) internal view returns (Tomato) {
        uint32 _health;
        uint32 _radiation;
        if (_isCrop) {
            (_health, _radiation) = farmhand.getTomatoMaxHealthAndRadiation(_id);
        } else {
            (_health, _radiation, , ) = farmhand.getTomatoCurrentHealthAndRadiation(_id);
        }

        if (_meleeChance == 0 || _attackChance == 0) {
            (_meleeChance, _attackChance) = farmhand.getTomatoTactics(_id);
        }
        uint8[11] memory _attackerTypes = farmhand.getTomatoTypes(_id);
        uint8[11] memory _opponentTypes = farmhand.getTomatoTypes(_opponentId);
        uint32 _attack;
        uint32 _defense;
        uint32 _speed;
        (_attack, _defense, , _speed, ) = farmhand.getTomatoAbilitys(_id);

        return Tomato({
            id: _id,
            attackChance: _attackChance,
            meleeChance: _meleeChance,
            health: _health,
            radiation: _radiation,
            speed: _speed,
            attack: _attack.mul(_calculateTomatoTypeMultiply(_attackerTypes, _opponentTypes)).div(TOMATO_TYPE_MULTIPLY),
            defense: _defense,
            specialAttackCost: 0,
            specialAttackFactor: 0,
            specialAttackChance: 0,
            specialDefenseCost: 0,
            specialDefenseFactor: 0,
            specialDefenseChance: 0,
            blocking: false,
            specialBlocking: false
        });
    }

    function _initTomato(
        uint256 _id,
        uint256 _opponentId,
        uint8[2] _tactics,
        bool _isCrop
    ) internal view returns (Tomato tomato) {
        tomato = _initFarmhouseTomato(_id, _opponentId, _tactics[0], _tactics[1], _isCrop);

        uint32 _specialAttackCost;
        uint8 _specialAttackFactor;
        uint8 _specialAttackChance;
        uint32 _specialDefenseCost;
        uint8 _specialDefenseFactor;
        uint8 _specialDefenseChance;

        ( , _specialAttackCost, _specialAttackFactor, _specialAttackChance) = farmhand.getTomatoSpecialAttack(_id);
        ( , _specialDefenseCost, _specialDefenseFactor, _specialDefenseChance) = farmhand.getTomatoSpecialDefense(_id);

        tomato.specialAttackCost = _specialAttackCost;
        tomato.specialAttackFactor = _specialAttackFactor;
        tomato.specialAttackChance = _specialAttackChance;
        tomato.specialDefenseCost = _specialDefenseCost;
        tomato.specialDefenseFactor = _specialDefenseFactor;
        tomato.specialDefenseChance = _specialDefenseChance;

        uint32[5] memory _buffs = farmhand.getTomatoBuffs(_id);

        if (_buffs[0] > 0) {
            tomato.attack = tomato.attack.mul(_buffs[0]).div(100);
        }
        if (_buffs[1] > 0) {
            tomato.defense = tomato.defense.mul(_buffs[1]).div(100);
        }
        if (_buffs[3] > 0) {
            tomato.speed = tomato.speed.mul(_buffs[3]).div(100);
        }
    }

    function _resetBlocking(Tomato tomato) internal pure returns (Tomato) {
        tomato.blocking = false;
        tomato.specialBlocking = false;

        return tomato;
    }

    function _attack(
        uint8 turnId,
        bool isMelee,
        Tomato attacker,
        Tomato opponent,
        uint8 _random
    ) internal pure returns (
        Tomato,
        Tomato
    ) {

        uint8 _turnModificator = 10;
        if (turnId > 30) {
            uint256 _modif = uint256(turnId).sub(30);
            _modif = _modif.mul(50);
            _modif = _modif.div(40);
            _modif = _modif.add(10);
            _turnModificator = _modif.toUint8();
        }

        bool isSpecial = _random < _multiplyByFloatNumber(attacker.specialAttackChance, _turnModificator);

        uint32 damage = _multiplyByFloatNumber(attacker.attack, _turnModificator);

        if (isSpecial && attacker.radiation >= attacker.specialAttackCost) {
            attacker.radiation = attacker.radiation.sub(attacker.specialAttackCost);
            damage = _multiplyByFloatNumber(damage, attacker.specialAttackFactor);
        }

        if (!isMelee) {
            damage = _multiplyByFloatNumber(damage, DISTANCE_ATTACK_WEAK__);
        }

        uint32 defense = opponent.defense;

        if (opponent.blocking) {
            defense = _multiplyByFloatNumber(defense, DEFENSE_SUCCESS_MULTIPLY__);

            if (opponent.specialBlocking) {
                defense = _multiplyByFloatNumber(defense, opponent.specialDefenseFactor);
            }
        } else {
            defense = _multiplyByFloatNumber(defense, DEFENSE_FAIL_MULTIPLY__);
        }

        if (damage > defense) {
            opponent.health = _safeSub(opponent.health, damage.sub(defense));
        } else if (isMelee) {
            attacker.health = _safeSub(attacker.health, defense.sub(damage));
        }

        return (attacker, opponent);
    }

    function _defense(
        Tomato attacker,
        uint256 initialSeed,
        uint256 currentSeed
    ) internal pure returns (
        Tomato,
        uint256
    ) {
        uint8 specialRandom;

        (specialRandom, currentSeed) = _getRandomNumber(initialSeed, currentSeed);
        bool isSpecial = specialRandom < attacker.specialDefenseChance;

        if (isSpecial && attacker.radiation >= attacker.specialDefenseCost) {
            attacker.radiation = attacker.radiation.sub(attacker.specialDefenseCost);
            attacker.specialBlocking = true;
        }
        attacker.blocking = true;

        return (attacker, currentSeed);
    }

    function _turn(
        uint8 turnId,
        uint256 initialSeed,
        uint256 currentSeed,
        uint32 distance,
        Tomato currentTomato,
        Tomato currentEnemy
    ) internal view returns (
        Tomato winner,
        Tomato looser
    ) {
        uint8 rand;

        (rand, currentSeed) = _getRandomNumber(initialSeed, currentSeed);
        bool isAttack = rand < currentTomato.attackChance;

        if (isAttack) {
            (rand, currentSeed) = _getRandomNumber(initialSeed, currentSeed);
            bool isMelee = rand < currentTomato.meleeChance;

            if (isMelee && distance > MAX_MELEE_ATTACK_DISTANCE) {
                distance = _safeSub(distance, currentTomato.speed);
            } else if (!isMelee && distance < MIN_RANGE_ATTACK_DISTANCE) {
                distance = distance.add(_multiplyByFloatNumber(currentTomato.speed, FALLBACK_SPEED_FACTOR__));
            } else {
                (rand, currentSeed) = _getRandomNumber(initialSeed, currentSeed);
                (currentTomato, currentEnemy) = _attack(turnId, isMelee, currentTomato, currentEnemy, rand);
            }
        } else {
            (currentTomato, currentSeed) = _defense(currentTomato, initialSeed, currentSeed);
        }

        currentEnemy = _resetBlocking(currentEnemy);

        if (currentTomato.health == 0) {
            return (currentEnemy, currentTomato);
        } else if (currentEnemy.health == 0) {
            return (currentTomato, currentEnemy);
        } else if (turnId < MAX_TURNS) {
            return _turn(turnId.add(1), initialSeed, currentSeed, distance, currentEnemy, currentTomato);
        } else {
            uint32 _tomatoMaxHealth;
            uint32 _enemyMaxHealth;
            (_tomatoMaxHealth, ) = farmhand.getTomatoMaxHealthAndRadiation(currentTomato.id);
            (_enemyMaxHealth, ) = farmhand.getTomatoMaxHealthAndRadiation(currentEnemy.id);
            if (_calculatePercentage(currentTomato.health, _tomatoMaxHealth) >= _calculatePercentage(currentEnemy.health, _enemyMaxHealth)) {
                return (currentTomato, currentEnemy);
            } else {
                return (currentEnemy, currentTomato);
            }
        }
    }

    function _start(
        uint256 _firstTomatoId,
        uint256 _secondTomatoId,
        uint8[2] _firstTactics,
        uint8[2] _secondTactics,
        uint256 _seed,
        bool _isCrop
    ) internal view returns (
        uint256[2],
        uint32,
        uint32,
        uint32,
        uint32
    ) {
        Tomato memory _firstTomato = _initTomato(_firstTomatoId, _secondTomatoId, _firstTactics, _isCrop);
        Tomato memory _secondTomato = _initTomato(_secondTomatoId, _firstTomatoId, _secondTactics, _isCrop);

        if (_firstTomato.speed >= _secondTomato.speed) {
            (_firstTomato, _secondTomato) = _turn(1, _seed, _seed, MAX_MELEE_ATTACK_DISTANCE, _firstTomato, _secondTomato);
        } else {
            (_firstTomato, _secondTomato) = _turn(1, _seed, _seed, MAX_MELEE_ATTACK_DISTANCE, _secondTomato, _firstTomato);
        }

        return (
            [_firstTomato.id,  _secondTomato.id],
            _firstTomato.health,
            _firstTomato.radiation,
            _secondTomato.health,
            _secondTomato.radiation
        );
    }

    function start(
        uint256 _firstTomatoId,
        uint256 _secondTomatoId,
        uint8[2] _tactics,
        uint8[2] _tactics2,
        uint256 _seed,
        bool _isCrop
    ) external onlyFarmer returns (
        uint256[2] winnerLooserIds,
        uint32 winnerHealth,
        uint32 winnerRadiation,
        uint32 looserHealth,
        uint32 looserRadiation,
        uint256 clashId
    ) {

        (
            winnerLooserIds,
            winnerHealth,
            winnerRadiation,
            looserHealth,
            looserRadiation
        ) = _start(
            _firstTomatoId,
            _secondTomatoId,
            _tactics,
            _tactics2,
            _seed,
            _isCrop
        );

        clashId = clashsCounter;
        clashsCounter = clashsCounter.add(1);
    }

    function setInternalDependencies(address[] _newDependencies) public onlyOwner {
        super.setInternalDependencies(_newDependencies);

        farmhand = Farmhand(_newDependencies[0]);
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

import "../../Common/Upgradable.sol";
import "../../Bean/Bean.sol";
import "../../Common/SafeMath256.sol";

// ----------------------------------------------------------------------------
// --- Contract CropClashFanSilo 
// ----------------------------------------------------------------------------

contract CropClashFanSilo is Upgradable {
    using SafeMath256 for uint256;

    Bean beanStalks;

    struct Bet {
        address user;
        uint256 challengeId;
        bool willCreatorWin;
        uint256 value;
        bool active;
    }

    mapping (uint256 => uint256[]) challengeBets;
    mapping (uint256 => mapping (uint256 => uint256)) public challengeBetIndex;
    mapping (uint256 => mapping (bool => uint256)) public challengeBetsAmount;
    mapping (uint256 => mapping (bool => uint256)) public challengeBetsValue;
    mapping (uint256 => uint256) public challengeWinningBetsAmount;
    mapping (uint256 => uint256) public challengeBalance;
    mapping (address => uint256[]) userChallenges;
    mapping (address => mapping (uint256 => uint256)) public userChallengeIndex;
    mapping (address => mapping (uint256 => uint256)) public userChallengeBetId;

    Bet[] public allBets;

    constructor() public {
        allBets.length = 1;
    }

    function() external payable {}

    function payOut(address _user, bool _isBean, uint256 _value) external onlyFarmer {
        if (_isBean) {
            beanStalks.transfer(_user, _value);
        } else {
            _user.transfer(_value);
        }
    }

    function addBet(
        address _user,
        uint256 _challengeId,
        bool _willCreatorWin,
        uint256 _value
    ) external onlyFarmer returns (uint256 id) {
        id = allBets.length;
        allBets.push(Bet(_user, _challengeId, _willCreatorWin, _value, true));
    }

    function addChallengeBet(
        uint256 _challengeId,
        uint256 _betId
    ) external onlyFarmer returns (uint256 index) {
        index = challengeBets[_challengeId].length;
        challengeBets[_challengeId].push(_betId);
        challengeBetIndex[_challengeId][_betId] = index;
    }

    function addUserChallenge(
        address _user,
        uint256 _challengeId,
        uint256 _betId
    ) external onlyFarmer {
        uint256 _index = userChallenges[_user].length;
        userChallenges[_user].push(_challengeId);
        userChallengeIndex[_user][_challengeId] = _index;
        userChallengeBetId[_user][_challengeId] = _betId;
    }

    function deactivateBet(uint256 _betId) external onlyFarmer {
        allBets[_betId].active = false;
    }

    function removeChallengeBet(
        uint256 _challengeId,
        uint256 _betId
    ) external onlyFarmer {
        uint256 _index = challengeBetIndex[_challengeId][_betId];
        uint256 _lastIndex = challengeBets[_challengeId].length.sub(1);
        uint256 _lastItem = challengeBets[_challengeId][_lastIndex];

        challengeBets[_challengeId][_index] = _lastItem;
        challengeBets[_challengeId][_lastIndex] = 0;

        challengeBets[_challengeId].length--;
        delete challengeBetIndex[_challengeId][_betId];
        challengeBetIndex[_challengeId][_lastItem] = _index;
    }

    function removeUserChallenge(
        address _user,
        uint256 _challengeId
    ) external onlyFarmer {
        uint256 _index = userChallengeIndex[_user][_challengeId];
        uint256 _lastIndex = userChallenges[_user].length.sub(1);
        uint256 _lastItem = userChallenges[_user][_lastIndex];

        userChallenges[_user][_index] = _lastItem;
        userChallenges[_user][_lastIndex] = 0;

        userChallenges[_user].length--;
        delete userChallengeIndex[_user][_challengeId];
        delete userChallengeBetId[_user][_challengeId];
        userChallengeIndex[_user][_lastItem] = _index;
    }

    function setChallengeBetsAmount(
        uint256 _challengeId,
        bool _willCreatorWin,
        uint256 _value
    ) external onlyFarmer {
        challengeBetsAmount[_challengeId][_willCreatorWin] = _value;
    }

    function setChallengeWinningBetsAmount(
        uint256 _challengeId,
        uint256 _value
    ) external onlyFarmer {
        challengeWinningBetsAmount[_challengeId] = _value;
    }

    function setChallengeBetsValue(
        uint256 _challengeId,
        bool _willCreatorWin,
        uint256 _value
    ) external onlyFarmer {
        challengeBetsValue[_challengeId][_willCreatorWin] = _value;
    }

    function setChallengeBalance(
        uint256 _challengeId,
        uint256 _value
    ) external onlyFarmer {
        challengeBalance[_challengeId] = _value;
    }

     

    function betsAmount() external view returns (uint256) {
        return allBets.length;
    }

    function getChallengeBetsAmount(
        uint256 _challengeId
    ) external view returns (
        uint256 onCreator,
        uint256 onOpponent
    ) {
        return (
            challengeBetsAmount[_challengeId][true],
            challengeBetsAmount[_challengeId][false]
        );
    }

    function getChallengeBetsValue(
        uint256 _challengeId
    ) external view returns (
        uint256 onCreator,
        uint256 onOpponent
    ) {
        return (
            challengeBetsValue[_challengeId][true],
            challengeBetsValue[_challengeId][false]
        );
    }

    function getUserBet(
        address _user,
        uint256 _challengeId
    ) external view returns (
        uint256 betId,
        bool willCreatorWin,
        uint256 value,
        bool active
    ) {
        uint256 _betId = userChallengeBetId[_user][_challengeId];
        require(_betId > 0, "bet doesn't exist");
        return (
            _betId,
            allBets[_betId].willCreatorWin,
            allBets[_betId].value,
            allBets[_betId].active
        );
    }

    function getChallengeBets(
        uint256 _challengeId
    ) external view returns (uint256[]) {
        return challengeBets[_challengeId];
    }

    function getUserChallenges(
        address _user
    ) external view returns (uint256[]) {
        return userChallenges[_user];
    }

    function setInternalDependencies(address[] _newDependencies) public onlyOwner {
        super.setInternalDependencies(_newDependencies);

        beanStalks = Bean(_newDependencies[0]);
    }
}
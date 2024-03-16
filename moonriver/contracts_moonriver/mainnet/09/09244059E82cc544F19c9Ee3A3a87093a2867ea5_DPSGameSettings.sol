//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/DPSStructs.sol";
import "./interfaces/DPSInterfaces.sol";

contract DPSGameSettings is Ownable {
    using SafeERC20 for IERC20;

    /**
     * @notice Voyage config per each voyage type
     */
    mapping(VOYAGE_TYPE => CartographerConfig) public voyageConfigPerType;

    /**
     * @notice multilication skills per each part. each level multiplies by this base skill points
     */
    mapping(FLAGSHIP_PART => uint16) public skillsPerFlagshipPart;

    /**
     * @notice dividing each flagship part into different skills type
     */
    mapping(uint8 => FLAGSHIP_PART[]) public partsForEachSkillType;

    /**
     * @notice flagship base skills
     */
    uint16 public flagshipBaseSkills;
    /**
     * @notice block jumps between random generation
     */
    uint16 public blockJumps;
    /**
     * @notice max points a sail can have per skill: strength, luck, navigation.
     * if any goes above this point, then this will act as a hard cap
     */
    uint16 public maxSkillsCap = 630;

    /**
     * @notice max points the causality can generate
     */
    uint16 public maxRollCap = 700;

    /**
     * @notice max points the causality can generate for awarding LockBoxes
     */
    uint16 public maxRollCapLockBoxes = 102;

    /**
     * @notice tmap per buying a voyage
     */
    mapping(VOYAGE_TYPE => uint256) public tmapPerVoyage;

    /**
     * @notice gap between 2 consecutive buyVoyages, in seconds.
     */
    uint256 public gapBetweenVoyagesCreation;

    /**
     * @notice in case of emergency to pause different components of the protocol
     * index meaning:
     * - 0 - pause swap tmaps for doubloons
     * - 1 - pause swap doubloons for tmaps
     * - 2 - pause buy a voyage using tmaps
     * - 3 - pause burns a voyage
     * - 4 - pause locks voyages
     * - 5 - pause claiming rewards on Docks
     * - 6 - pause lockToClaimRewards from chests
     * - 7 - pause lock locked boxes
     * - 8 - pause claim locked chests
     * - 9 - pause claiming locked lock boxes
     * - 10 - pause claiming a flagship
     * - 11 - pause repairing a damaged ship
     * - 12 - pause upgrade parts of flagship for doubloons
     * - 13 - pause buy support ships
     */
    uint8[] public paused;

    /**
     * @notice tmaps per doubloons, in wei
     */
    uint256 public tmapPerDoubloon;

    /**
     * @notice doubloon price in wei per upgrade part of the flagship
     */
    uint256 public doubloonPerUpgradePart;

    /**
     * @notice max lock boxes that someone can open at a time
     */
    uint256 public maxOpenLockBoxes;

    /**
     * @notice repair flagship cost in doubloons
     */
    uint256 public repairFlagshipCost;

    /**
     * @notice doubloons needed to buy 1 support ship of type SUPPORT_SHIP_TYPE
     */
    mapping(SUPPORT_SHIP_TYPE => uint256) public doubloonsPerSupportShipType;

    /**
     * @notice skill boosts per support ship type
     */
    mapping(SUPPORT_SHIP_TYPE => uint16) public supportShipsSkillBoosts;

    /**
     * @notice skill boosts per artifact type
     */
    mapping(ARTIFACT_TYPE => uint16) public artifactsSkillBoosts;

    /**
     * @notice the max no of ships you can attach per voyage type
     */
    mapping(VOYAGE_TYPE => uint8) public maxSupportShipsPerVoyageType;

    /**
     * @notice the amount of doubloons that can be rewarded per chest opened
     */
    mapping(VOYAGE_TYPE => uint256) public chestDoubloonRewards;

    /**
     * @notice max rollout that can win a lockbox per chest type (Voyage type)
     * what this means is that out of a roll between 0-10000 if a number between 0 and maxRollPerChest is rolled then
     * the user won a lockbox of the type corresponding with the chest type
     */
    mapping(VOYAGE_TYPE => uint256) public maxRollPerChest;

    /**
     * @notice out of 102 distribution of how we will determine the artifact rewards
     */
    mapping(ARTIFACT_TYPE => uint16[2]) public lockBoxesDistribution;

    /**
     * @notice debuffs for every voyage type
     */
    mapping(VOYAGE_TYPE => uint16) public voyageDebuffs;

    event TokenRecovered(address indexed _token, address _destination, uint256 _amount);
    event SetContract(string indexed _target, address _contract);
    event Debug(uint256);

    constructor() {
        voyageConfigPerType[VOYAGE_TYPE.EASY].minNoOfChests = 4;
        voyageConfigPerType[VOYAGE_TYPE.EASY].maxNoOfChests = 4;
        voyageConfigPerType[VOYAGE_TYPE.EASY].minNoOfStorms = 1;
        voyageConfigPerType[VOYAGE_TYPE.EASY].maxNoOfStorms = 1;
        voyageConfigPerType[VOYAGE_TYPE.EASY].minNoOfEnemies = 1;
        voyageConfigPerType[VOYAGE_TYPE.EASY].maxNoOfEnemies = 1;
        voyageConfigPerType[VOYAGE_TYPE.EASY].totalInteractions = 6;
        voyageConfigPerType[VOYAGE_TYPE.EASY].gapBetweenInteractions = 3600;

        voyageConfigPerType[VOYAGE_TYPE.MEDIUM].minNoOfChests = 5;
        voyageConfigPerType[VOYAGE_TYPE.MEDIUM].maxNoOfChests = 6;
        voyageConfigPerType[VOYAGE_TYPE.MEDIUM].minNoOfStorms = 3;
        voyageConfigPerType[VOYAGE_TYPE.MEDIUM].maxNoOfStorms = 4;
        voyageConfigPerType[VOYAGE_TYPE.MEDIUM].minNoOfEnemies = 3;
        voyageConfigPerType[VOYAGE_TYPE.MEDIUM].maxNoOfEnemies = 4;
        voyageConfigPerType[VOYAGE_TYPE.MEDIUM].totalInteractions = 12;
        voyageConfigPerType[VOYAGE_TYPE.MEDIUM].gapBetweenInteractions = 3600;

        voyageConfigPerType[VOYAGE_TYPE.HARD].minNoOfChests = 7;
        voyageConfigPerType[VOYAGE_TYPE.HARD].maxNoOfChests = 8;
        voyageConfigPerType[VOYAGE_TYPE.HARD].minNoOfStorms = 5;
        voyageConfigPerType[VOYAGE_TYPE.HARD].maxNoOfStorms = 6;
        voyageConfigPerType[VOYAGE_TYPE.HARD].minNoOfEnemies = 5;
        voyageConfigPerType[VOYAGE_TYPE.HARD].maxNoOfEnemies = 6;
        voyageConfigPerType[VOYAGE_TYPE.HARD].totalInteractions = 18;
        voyageConfigPerType[VOYAGE_TYPE.HARD].gapBetweenInteractions = 3600;

        voyageConfigPerType[VOYAGE_TYPE.LEGENDARY].minNoOfChests = 9;
        voyageConfigPerType[VOYAGE_TYPE.LEGENDARY].maxNoOfChests = 12;
        voyageConfigPerType[VOYAGE_TYPE.LEGENDARY].minNoOfStorms = 7;
        voyageConfigPerType[VOYAGE_TYPE.LEGENDARY].maxNoOfStorms = 8;
        voyageConfigPerType[VOYAGE_TYPE.LEGENDARY].minNoOfEnemies = 7;
        voyageConfigPerType[VOYAGE_TYPE.LEGENDARY].maxNoOfEnemies = 8;
        voyageConfigPerType[VOYAGE_TYPE.LEGENDARY].totalInteractions = 24;
        voyageConfigPerType[VOYAGE_TYPE.LEGENDARY].gapBetweenInteractions = 3600;

        skillsPerFlagshipPart[FLAGSHIP_PART.CANNON] = 10;
        skillsPerFlagshipPart[FLAGSHIP_PART.HULL] = 10;
        skillsPerFlagshipPart[FLAGSHIP_PART.SAILS] = 10;
        skillsPerFlagshipPart[FLAGSHIP_PART.HELM] = 10;
        skillsPerFlagshipPart[FLAGSHIP_PART.FLAG] = 10;
        skillsPerFlagshipPart[FLAGSHIP_PART.FIGUREHEAD] = 10;

        flagshipBaseSkills = 250;

        partsForEachSkillType[uint8(SKILL_TYPE.LUCK)] = [FLAGSHIP_PART.FLAG, FLAGSHIP_PART.FIGUREHEAD];
        partsForEachSkillType[uint8(SKILL_TYPE.NAVIGATION)] = [FLAGSHIP_PART.SAILS, FLAGSHIP_PART.HELM];
        partsForEachSkillType[uint8(SKILL_TYPE.STRENGTH)] = [FLAGSHIP_PART.CANNON, FLAGSHIP_PART.HULL];

        tmapPerVoyage[VOYAGE_TYPE.EASY] = 1 * 1e18;
        tmapPerVoyage[VOYAGE_TYPE.MEDIUM] = 2 * 1e18;
        tmapPerVoyage[VOYAGE_TYPE.HARD] = 3 * 1e18;
        tmapPerVoyage[VOYAGE_TYPE.LEGENDARY] = 4 * 1e18;

        blockJumps = 5;

        paused.push(0);
        paused.push(0);
        paused.push(0);
        paused.push(0);
        paused.push(0);
        paused.push(0);
        paused.push(0);
        paused.push(0);
        paused.push(0);
        paused.push(0);
        paused.push(0);
        paused.push(0);
        paused.push(0);
        paused.push(0);

        tmapPerDoubloon = 10;

        doubloonPerUpgradePart = 750 * 1e18;

        maxOpenLockBoxes = 1;

        repairFlagshipCost = 35 * 1e18;

        doubloonsPerSupportShipType[SUPPORT_SHIP_TYPE.SLOOP_STRENGTH] = 15 * 1e18;
        doubloonsPerSupportShipType[SUPPORT_SHIP_TYPE.SLOOP_LUCK] = 15 * 1e18;
        doubloonsPerSupportShipType[SUPPORT_SHIP_TYPE.SLOOP_NAVIGATION] = 15 * 1e18;

        doubloonsPerSupportShipType[SUPPORT_SHIP_TYPE.CARAVEL_STRENGTH] = 30 * 1e18;
        doubloonsPerSupportShipType[SUPPORT_SHIP_TYPE.CARAVEL_LUCK] = 30 * 1e18;
        doubloonsPerSupportShipType[SUPPORT_SHIP_TYPE.CARAVEL_NAVIGATION] = 30 * 1e18;

        doubloonsPerSupportShipType[SUPPORT_SHIP_TYPE.GALLEON_STRENGTH] = 50 * 1e18;
        doubloonsPerSupportShipType[SUPPORT_SHIP_TYPE.GALLEON_LUCK] = 50 * 1e18;
        doubloonsPerSupportShipType[SUPPORT_SHIP_TYPE.GALLEON_NAVIGATION] = 50 * 1e18;

        supportShipsSkillBoosts[SUPPORT_SHIP_TYPE.SLOOP_STRENGTH] = 10;
        supportShipsSkillBoosts[SUPPORT_SHIP_TYPE.SLOOP_LUCK] = 10;
        supportShipsSkillBoosts[SUPPORT_SHIP_TYPE.SLOOP_NAVIGATION] = 10;

        supportShipsSkillBoosts[SUPPORT_SHIP_TYPE.CARAVEL_STRENGTH] = 30;
        supportShipsSkillBoosts[SUPPORT_SHIP_TYPE.CARAVEL_LUCK] = 30;
        supportShipsSkillBoosts[SUPPORT_SHIP_TYPE.CARAVEL_NAVIGATION] = 30;

        supportShipsSkillBoosts[SUPPORT_SHIP_TYPE.GALLEON_STRENGTH] = 50;
        supportShipsSkillBoosts[SUPPORT_SHIP_TYPE.GALLEON_LUCK] = 50;
        supportShipsSkillBoosts[SUPPORT_SHIP_TYPE.GALLEON_NAVIGATION] = 50;

        maxSupportShipsPerVoyageType[VOYAGE_TYPE.EASY] = 2;
        maxSupportShipsPerVoyageType[VOYAGE_TYPE.MEDIUM] = 3;
        maxSupportShipsPerVoyageType[VOYAGE_TYPE.HARD] = 4;
        maxSupportShipsPerVoyageType[VOYAGE_TYPE.LEGENDARY] = 5;

        artifactsSkillBoosts[ARTIFACT_TYPE.NONE] = 0;
        artifactsSkillBoosts[ARTIFACT_TYPE.COMMON_STRENGTH] = 40;
        artifactsSkillBoosts[ARTIFACT_TYPE.COMMON_LUCK] = 40;
        artifactsSkillBoosts[ARTIFACT_TYPE.COMMON_NAVIGATION] = 40;

        artifactsSkillBoosts[ARTIFACT_TYPE.RARE_STRENGTH] = 60;
        artifactsSkillBoosts[ARTIFACT_TYPE.RARE_LUCK] = 60;
        artifactsSkillBoosts[ARTIFACT_TYPE.RARE_NAVIGATION] = 60;

        artifactsSkillBoosts[ARTIFACT_TYPE.EPIC_STRENGTH] = 90;
        artifactsSkillBoosts[ARTIFACT_TYPE.EPIC_LUCK] = 90;
        artifactsSkillBoosts[ARTIFACT_TYPE.EPIC_NAVIGATION] = 90;

        artifactsSkillBoosts[ARTIFACT_TYPE.LEGENDARY_STRENGTH] = 140;
        artifactsSkillBoosts[ARTIFACT_TYPE.LEGENDARY_LUCK] = 140;
        artifactsSkillBoosts[ARTIFACT_TYPE.LEGENDARY_NAVIGATION] = 140;

        chestDoubloonRewards[VOYAGE_TYPE.EASY] = 45 * 1e18;
        chestDoubloonRewards[VOYAGE_TYPE.MEDIUM] = 65 * 1e18;
        chestDoubloonRewards[VOYAGE_TYPE.HARD] = 85 * 1e18;
        chestDoubloonRewards[VOYAGE_TYPE.LEGENDARY] = 105 * 1e18;

        maxRollPerChest[VOYAGE_TYPE.EASY] = 4;
        maxRollPerChest[VOYAGE_TYPE.MEDIUM] = 5;
        maxRollPerChest[VOYAGE_TYPE.HARD] = 8;
        maxRollPerChest[VOYAGE_TYPE.LEGENDARY] = 12;

        lockBoxesDistribution[ARTIFACT_TYPE.COMMON_STRENGTH] = [0, 21];
        lockBoxesDistribution[ARTIFACT_TYPE.COMMON_LUCK] = [22, 43];
        lockBoxesDistribution[ARTIFACT_TYPE.COMMON_NAVIGATION] = [44, 65];

        lockBoxesDistribution[ARTIFACT_TYPE.RARE_STRENGTH] = [66, 72];
        lockBoxesDistribution[ARTIFACT_TYPE.RARE_LUCK] = [73, 79];
        lockBoxesDistribution[ARTIFACT_TYPE.RARE_NAVIGATION] = [80, 86];

        lockBoxesDistribution[ARTIFACT_TYPE.EPIC_STRENGTH] = [87, 89];
        lockBoxesDistribution[ARTIFACT_TYPE.EPIC_LUCK] = [90, 92];
        lockBoxesDistribution[ARTIFACT_TYPE.EPIC_NAVIGATION] = [93, 95];

        lockBoxesDistribution[ARTIFACT_TYPE.LEGENDARY_STRENGTH] = [96, 97];
        lockBoxesDistribution[ARTIFACT_TYPE.LEGENDARY_LUCK] = [98, 99];
        lockBoxesDistribution[ARTIFACT_TYPE.LEGENDARY_NAVIGATION] = [100, 101];

        voyageDebuffs[VOYAGE_TYPE.EASY] = 0;
        voyageDebuffs[VOYAGE_TYPE.MEDIUM] = 100;
        voyageDebuffs[VOYAGE_TYPE.HARD] = 180;
        voyageDebuffs[VOYAGE_TYPE.LEGENDARY] = 260;
    }

    function setVoyageConfig(CartographerConfig calldata config, VOYAGE_TYPE _type) external onlyOwner {
        voyageConfigPerType[_type] = config;
    }

    function setTmapPerVoyage(VOYAGE_TYPE _type, uint256 _amount) external onlyOwner {
        tmapPerVoyage[_type] = _amount;
    }

    function setTmapPerDoubloon(uint256 _amount) external onlyOwner {
        tmapPerDoubloon = _amount;
    }

    function setDoubloonPerUpgradePart(uint256 _amount) external onlyOwner {
        doubloonPerUpgradePart = _amount;
    }

    function setVoyageConfigPerType(VOYAGE_TYPE _type, CartographerConfig calldata _config) external onlyOwner {
        voyageConfigPerType[_type].minNoOfChests = _config.minNoOfChests;
        voyageConfigPerType[_type].maxNoOfChests = _config.maxNoOfChests;
        voyageConfigPerType[_type].minNoOfStorms = _config.minNoOfStorms;
        voyageConfigPerType[_type].maxNoOfStorms = _config.maxNoOfStorms;
        voyageConfigPerType[_type].minNoOfEnemies = _config.minNoOfEnemies;
        voyageConfigPerType[_type].maxNoOfEnemies = _config.maxNoOfEnemies;
        voyageConfigPerType[_type].totalInteractions = _config.totalInteractions;
        voyageConfigPerType[_type].gapBetweenInteractions = _config.gapBetweenInteractions;
    }

    function setSkillsPerFlagshipPart(FLAGSHIP_PART _part, uint16 _amount) external onlyOwner {
        skillsPerFlagshipPart[_part] = _amount;
    }

    function setBlockJumps(uint16 _jumps) external onlyOwner {
        blockJumps = _jumps;
    }

    function setGapBetweenVoyagesCreation(uint256 _newGap) external onlyOwner {
        gapBetweenVoyagesCreation = _newGap;
    }

    function setMaxSkillsCap(uint16 _newCap) external onlyOwner {
        maxSkillsCap = _newCap;
    }

    function setMaxRollCap(uint16 _newCap) external onlyOwner {
        maxRollCap = _newCap;
    }

    function setDoubloonsPerSupportShipType(SUPPORT_SHIP_TYPE _type, uint256 _amount) external onlyOwner {
        doubloonsPerSupportShipType[_type] = _amount;
    }

    function setSupportShipsSkillBoosts(SUPPORT_SHIP_TYPE _type, uint16 _skillPoinst) external onlyOwner {
        supportShipsSkillBoosts[_type] = _skillPoinst;
    }

    function setArtifactSkillBoosts(ARTIFACT_TYPE _type, uint16 _skillPoinst) external onlyOwner {
        artifactsSkillBoosts[_type] = _skillPoinst;
    }

    function setLockBoxesDistribution(ARTIFACT_TYPE _type, uint16[2] calldata _limits) external onlyOwner {
        lockBoxesDistribution[_type] = _limits;
    }

    function setChestDoubloonRewards(VOYAGE_TYPE _type, uint256 _rewards) external onlyOwner {
        chestDoubloonRewards[_type] = _rewards;
    }

    function setMaxRollCapLockBoxes(uint16 _maxRollCap) external onlyOwner {
        maxRollCapLockBoxes = _maxRollCap;
    }

    function setMaxRollPerChest(VOYAGE_TYPE _type, uint256 _roll) external onlyOwner {
        maxRollPerChest[_type] = _roll;
    }

    function setMaxSupportShipsPerVoyageType(VOYAGE_TYPE _type, uint8 _max) external onlyOwner {
        maxSupportShipsPerVoyageType[_type] = _max;
    }

    function setMaxOpenLockBoxes(uint256 _newMax) external onlyOwner {
        maxOpenLockBoxes = _newMax;
    }

    function setRepairFlagshipCost(uint256 _newCost) external onlyOwner {
        repairFlagshipCost = _newCost;
    }

    function setVoyageDebuffs(VOYAGE_TYPE _type, uint16 _newDebuff) external onlyOwner {
        voyageDebuffs[_type] = _newDebuff;
    }

    function pauseComponent(uint8 _component, uint8 _pause) external onlyOwner {
        paused[_component] = _pause;
    }

    function getVoyageConfig(VOYAGE_TYPE _type) external view returns (CartographerConfig memory) {
        return voyageConfigPerType[_type];
    }

    function getDoubloonsPerSupportShipType(SUPPORT_SHIP_TYPE _type) external view returns (uint256) {
        return doubloonsPerSupportShipType[_type];
    }

    function getSupportShipsSkillBoosts(SUPPORT_SHIP_TYPE _type) public view returns (uint16) {
        return supportShipsSkillBoosts[_type];
    }

    function getLockBoxesDistribution(ARTIFACT_TYPE _type) external view returns (uint16[2] memory) {
        return lockBoxesDistribution[_type];
    }

    function getArtifactSkillBoosts(ARTIFACT_TYPE _type) external view returns (uint16) {
        return artifactsSkillBoosts[_type];
    }

    function getMaxSupportShipsPerVoyageType(VOYAGE_TYPE _type) external view returns (uint8) {
        return maxSupportShipsPerVoyageType[_type];
    }

    function getChestDoubloonRewards(VOYAGE_TYPE _type) external view returns (uint256) {
        return chestDoubloonRewards[_type];
    }

    function getMaxRollPerChest(VOYAGE_TYPE _type) external view returns (uint256) {
        return maxRollPerChest[_type];
    }

    function getVoyageDebuffs(VOYAGE_TYPE _type) external view returns (uint16) {
        return voyageDebuffs[_type];
    }

    function getSkillTypeOfEachFlagshipPart() public view returns (uint8[7] memory skillTypes) {
        for (uint8 i; i < 3; i++) {
            for (uint8 j = 0; j < partsForEachSkillType[i].length; j++) {
                skillTypes[uint256(partsForEachSkillType[i][j])] = i;
            }
        }
    }

    function getTMAPPerVoyageType(VOYAGE_TYPE _type) external view returns (uint256) {
        return tmapPerVoyage[_type];
    }

    function getSkillsPerFlagshipParts() public view returns (uint16[7] memory skills) {
        skills[uint256(FLAGSHIP_PART.CANNON)] = skillsPerFlagshipPart[FLAGSHIP_PART.CANNON];
        skills[uint256(FLAGSHIP_PART.HULL)] = skillsPerFlagshipPart[FLAGSHIP_PART.HULL];
        skills[uint256(FLAGSHIP_PART.SAILS)] = skillsPerFlagshipPart[FLAGSHIP_PART.SAILS];
        skills[uint256(FLAGSHIP_PART.HELM)] = skillsPerFlagshipPart[FLAGSHIP_PART.HELM];
        skills[uint256(FLAGSHIP_PART.FLAG)] = skillsPerFlagshipPart[FLAGSHIP_PART.FLAG];
        skills[uint256(FLAGSHIP_PART.FIGUREHEAD)] = skillsPerFlagshipPart[FLAGSHIP_PART.FIGUREHEAD];
    }

    /**
     * @notice computes skills for the flagship based on the level of the part of the flagship + base skills of the flagship
     * @param levels levels for each part, needs to respect the order of the levels from flagship
     * @param _claimingRewardsCache the cache object that contains the skill points per skill type
     * @return cached object with the skill points updated
     */
    function computeFlagShipSkills(uint8[7] calldata levels, VoyageStatusCache memory _claimingRewardsCache)
        external
        view
        returns (VoyageStatusCache memory)
    {
        unchecked {
            uint16[7] memory skillsPerPart = getSkillsPerFlagshipParts();
            uint8[7] memory skillTypes = getSkillTypeOfEachFlagshipPart();
            _claimingRewardsCache.luck += flagshipBaseSkills;
            _claimingRewardsCache.navigation += flagshipBaseSkills;
            _claimingRewardsCache.strength += flagshipBaseSkills;
            for (uint256 i; i < 7; i++) {
                if (skillTypes[i] == uint8(SKILL_TYPE.LUCK)) _claimingRewardsCache.luck += skillsPerPart[i] * levels[i];
                if (skillTypes[i] == uint8(SKILL_TYPE.NAVIGATION))
                    _claimingRewardsCache.navigation += skillsPerPart[i] * levels[i];
                if (skillTypes[i] == uint8(SKILL_TYPE.STRENGTH))
                    _claimingRewardsCache.strength += skillsPerPart[i] * levels[i];
            }
            return _claimingRewardsCache;
        }
    }

    /**
     * @notice computes skills for the support ships as there are multiple types that apply skills to different skill type: navigation, luck, strength
     * @param _supportShips the array of support ships
     * @param _claimingRewardsCache the cache object that contains the skill points per skill type
     * @return cached object with the skill points updated
     */
    function computeSupportSkills(
        uint8[9] calldata _supportShips,
        ARTIFACT_TYPE _type,
        VoyageStatusCache memory _claimingRewardsCache
    ) external view returns (VoyageStatusCache memory) {
        unchecked {
            uint16 skill = artifactsSkillBoosts[_type];
            if (
                _type == ARTIFACT_TYPE.COMMON_STRENGTH ||
                _type == ARTIFACT_TYPE.RARE_STRENGTH ||
                _type == ARTIFACT_TYPE.EPIC_STRENGTH ||
                _type == ARTIFACT_TYPE.LEGENDARY_STRENGTH
            ) _claimingRewardsCache.strength += skill;

            if (
                _type == ARTIFACT_TYPE.COMMON_LUCK ||
                _type == ARTIFACT_TYPE.RARE_LUCK ||
                _type == ARTIFACT_TYPE.EPIC_LUCK ||
                _type == ARTIFACT_TYPE.LEGENDARY_LUCK
            ) _claimingRewardsCache.luck += skill;

            if (
                _type == ARTIFACT_TYPE.COMMON_NAVIGATION ||
                _type == ARTIFACT_TYPE.RARE_NAVIGATION ||
                _type == ARTIFACT_TYPE.EPIC_NAVIGATION ||
                _type == ARTIFACT_TYPE.LEGENDARY_NAVIGATION
            ) _claimingRewardsCache.navigation += skill;

            for (uint256 i; i < 9; i++) {
                if (_supportShips[i] == 0) continue;
                SUPPORT_SHIP_TYPE supportShipType = SUPPORT_SHIP_TYPE(i);
                skill = supportShipsSkillBoosts[supportShipType];
                if (
                    supportShipType == SUPPORT_SHIP_TYPE.SLOOP_STRENGTH ||
                    supportShipType == SUPPORT_SHIP_TYPE.CARAVEL_STRENGTH ||
                    supportShipType == SUPPORT_SHIP_TYPE.GALLEON_STRENGTH
                ) _claimingRewardsCache.strength += skill * _supportShips[i];

                if (
                    supportShipType == SUPPORT_SHIP_TYPE.SLOOP_LUCK ||
                    supportShipType == SUPPORT_SHIP_TYPE.CARAVEL_LUCK ||
                    supportShipType == SUPPORT_SHIP_TYPE.GALLEON_LUCK
                ) _claimingRewardsCache.luck += skill * _supportShips[i];

                if (
                    supportShipType == SUPPORT_SHIP_TYPE.SLOOP_NAVIGATION ||
                    supportShipType == SUPPORT_SHIP_TYPE.CARAVEL_NAVIGATION ||
                    supportShipType == SUPPORT_SHIP_TYPE.GALLEON_NAVIGATION
                ) _claimingRewardsCache.navigation += skill * _supportShips[i];
            }
            return _claimingRewardsCache;
        }
    }

    /**
     * @notice interprets a randomness result, meaning that based on the skill points accumulated from base pirate skills,
     *         flagship + support ships, we do a comparition between the result of the randomness and the skill points.
     *         if random > skill points than this interaction fails. Things to notice: if STORM or ENEMY fails then we
     *         destroy a support ship (if exists) or do health damage of 100% which will result in skipping all the upcoming
     *         interactions
     * @param _result - random number generated
     * @param _voyageResult - the result object that is cached and sent along for later on saving into storage
     * @param _lockedVoyage - locked voyage that contains the support ship objects that will get modified (sent as storage) if interaction failed
     * @param _claimingRewardsCache - cache object sent along for points updates
     * @param _interaction - interaction that we compute the outcome for
     * @param _index - current index of interaction, used to update the outcome
     * @return updated voyage results and claimingRewardsCache (this updates in case of a support ship getting destroyed)
     */
    function interpretResults(
        uint256 _result,
        VoyageResult memory _voyageResult,
        LockedVoyage calldata _lockedVoyage,
        VoyageStatusCache memory _claimingRewardsCache,
        INTERACTION _interaction,
        CausalityParams calldata _causalityParams,
        uint256 _index
    ) external view returns (VoyageResult memory, VoyageStatusCache memory) {
        if (_interaction == INTERACTION.CHEST && _result <= _claimingRewardsCache.luck) {
            _voyageResult.awardedChests++;
            _voyageResult.interactionResults[_index] = 1;
        } else if (
            (_interaction == INTERACTION.STORM && _result > _claimingRewardsCache.navigation) ||
            (_interaction == INTERACTION.ENEMY && _result > _claimingRewardsCache.strength)
        ) {
            if (_lockedVoyage.totalSupportShips - _voyageResult.totalSupportShipsDestroyed > 0) {
                _voyageResult.totalSupportShipsDestroyed++;
                uint256 supportShipTypesLength;
                for (uint256 i; i < 9; i++) {
                    if (
                        _lockedVoyage.supportShips[i] > _voyageResult.destroyedSupportShips[i] &&
                        _lockedVoyage.supportShips[i] - _voyageResult.destroyedSupportShips[i] > 0
                    ) supportShipTypesLength++;
                }

                uint256[] memory supportShipTypes = new uint256[](supportShipTypesLength);
                uint256 j;
                for (uint256 i; i < 9; i++) {
                    if (
                        _lockedVoyage.supportShips[i] > _voyageResult.destroyedSupportShips[i] &&
                        _lockedVoyage.supportShips[i] - _voyageResult.destroyedSupportShips[i] > 0
                    ) {
                        supportShipTypes[j] = i;
                        j++;
                    }
                }

                uint256 chosenType = uint256(
                    keccak256(
                        abi.encodePacked(
                            _causalityParams.blockNumber[0],
                            _causalityParams.hash1[0],
                            _causalityParams.hash2[0],
                            _causalityParams.timestamp[0],
                            string(abi.encodePacked("SUPPORT_SHIP_", _index)),
                            uint8(1),
                            supportShipTypesLength
                        )
                    )
                ) % (supportShipTypesLength);
                SUPPORT_SHIP_TYPE supportShipType = SUPPORT_SHIP_TYPE.SLOOP_STRENGTH;
                for (uint256 i; i < supportShipTypesLength; i++) {
                    if (chosenType == i) {
                        supportShipType = SUPPORT_SHIP_TYPE(supportShipTypes[i]);
                    }
                }
                _voyageResult.destroyedSupportShips[uint8(supportShipType)]++;

                uint16 points = getSupportShipsSkillBoosts(supportShipType);

                if (
                    supportShipType == SUPPORT_SHIP_TYPE.SLOOP_STRENGTH ||
                    supportShipType == SUPPORT_SHIP_TYPE.CARAVEL_STRENGTH ||
                    supportShipType == SUPPORT_SHIP_TYPE.GALLEON_STRENGTH
                ) _claimingRewardsCache.strength -= points;
                else if (
                    supportShipType == SUPPORT_SHIP_TYPE.SLOOP_LUCK ||
                    supportShipType == SUPPORT_SHIP_TYPE.CARAVEL_LUCK ||
                    supportShipType == SUPPORT_SHIP_TYPE.GALLEON_LUCK
                ) _claimingRewardsCache.luck -= points;
                else if (
                    supportShipType == SUPPORT_SHIP_TYPE.SLOOP_NAVIGATION ||
                    supportShipType == SUPPORT_SHIP_TYPE.CARAVEL_NAVIGATION ||
                    supportShipType == SUPPORT_SHIP_TYPE.GALLEON_NAVIGATION
                ) _claimingRewardsCache.navigation -= points;
            } else {
                _voyageResult.healthDamage = 100;
            }
        } else if (_interaction != INTERACTION.CHEST) {
            _voyageResult.interactionResults[_index] = 1;
        }

        return (_voyageResult, _claimingRewardsCache);
    }

    function debuffVoyage(VOYAGE_TYPE _voyageType, VoyageStatusCache memory _claimingRewardsCache)
        external
        view
        returns (VoyageStatusCache memory)
    {
        uint16 debuffs = voyageDebuffs[_voyageType];

        if (_claimingRewardsCache.strength > debuffs) _claimingRewardsCache.strength -= debuffs;
        else _claimingRewardsCache.strength = 0;

        if (_claimingRewardsCache.luck > debuffs) _claimingRewardsCache.luck -= debuffs;
        else _claimingRewardsCache.luck = 0;

        if (_claimingRewardsCache.navigation > debuffs) _claimingRewardsCache.navigation -= debuffs;
        else _claimingRewardsCache.navigation = 0;

        _claimingRewardsCache = applyMaxSkillCap(_claimingRewardsCache);

        return _claimingRewardsCache;
    }

    function applyMaxSkillCap(VoyageStatusCache memory _claimingRewardsCache)
        internal
        view
        returns (VoyageStatusCache memory modifiedCached)
    {
        if (_claimingRewardsCache.navigation > maxSkillsCap) _claimingRewardsCache.navigation = maxSkillsCap;

        if (_claimingRewardsCache.luck > maxSkillsCap) _claimingRewardsCache.luck = maxSkillsCap;

        if (_claimingRewardsCache.strength > maxSkillsCap) _claimingRewardsCache.strength = maxSkillsCap;
        modifiedCached = _claimingRewardsCache;
    }

    function isPaused(uint8 _component) external view returns (uint8) {
        return paused[_component];
    }

    /**
     * @notice Recover NFT sent by mistake to the contract
     * @param _nft the NFT address
     * @param _destination where to send the NFT
     * @param _tokenId the token to want to recover
     */
    function recoverNFT(
        address _nft,
        address _destination,
        uint256 _tokenId
    ) external onlyOwner {
        require(_destination != address(0), "Destination !address(0)");
        IERC721(_nft).safeTransferFrom(address(this), _destination, _tokenId);
        emit TokenRecovered(_nft, _destination, _tokenId);
    }

    /**
     * @notice Recover TOKENS sent by mistake to the contract
     * @param _token the TOKEN address
     * @param _destination where to send the NFT
     */
    function recoverERC20(address _token, address _destination) external onlyOwner {
        require(_destination != address(0), "Destination !address(0)");
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(_destination, amount);
        emit TokenRecovered(_token, _destination, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

enum VOYAGE_TYPE {
    EASY,
    MEDIUM,
    HARD,
    LEGENDARY
}

enum SUPPORT_SHIP_TYPE {
    SLOOP_STRENGTH,
    SLOOP_LUCK,
    SLOOP_NAVIGATION,
    CARAVEL_STRENGTH,
    CARAVEL_LUCK,
    CARAVEL_NAVIGATION,
    GALLEON_STRENGTH,
    GALLEON_LUCK,
    GALLEON_NAVIGATION
}

enum ARTIFACT_TYPE {
    NONE,
    COMMON_STRENGTH,
    COMMON_LUCK,
    COMMON_NAVIGATION,
    RARE_STRENGTH,
    RARE_LUCK,
    RARE_NAVIGATION,
    EPIC_STRENGTH,
    EPIC_LUCK,
    EPIC_NAVIGATION,
    LEGENDARY_STRENGTH,
    LEGENDARY_LUCK,
    LEGENDARY_NAVIGATION
}

enum INTERACTION {
    NONE,
    CHEST,
    STORM,
    ENEMY
}

enum FLAGSHIP_PART {
    HEALTH,
    CANNON,
    HULL,
    SAILS,
    HELM,
    FLAG,
    FIGUREHEAD
}

enum SKILL_TYPE {
    LUCK,
    STRENGTH,
    NAVIGATION
}

struct VoyageConfig {
    VOYAGE_TYPE typeOfVoyage;
    uint8 noOfInteractions;
    uint16 noOfBlockJumps;
    // 1 - Chest 2 - Storm 3 - Enemy
    uint8[] sequence;
    uint256 boughtAt;
    uint256 gapBetweenInteractions;
}

struct CartographerConfig {
    uint8 minNoOfChests;
    uint8 maxNoOfChests;
    uint8 minNoOfStorms;
    uint8 maxNoOfStorms;
    uint8 minNoOfEnemies;
    uint8 maxNoOfEnemies;
    uint8 totalInteractions;
    uint256 gapBetweenInteractions;
}

struct RandomInteractions {
    uint256 randomNoOfChests;
    uint256 randomNoOfStorms;
    uint256 randomNoOfEnemies;
    uint8 generatedChests;
    uint8 generatedStorms;
    uint8 generatedEnemies;
    uint256[] positionsForGeneratingInteractions;
}

struct CausalityParams {
    uint256[] blockNumber;
    bytes32[] hash1;
    bytes32[] hash2;
    uint256[] timestamp;
    bytes[] signature;
}

struct LockedVoyage {
    uint8 totalSupportShips;
    VOYAGE_TYPE voyageType;
    ARTIFACT_TYPE artifactId;
    uint8[9] supportShips; //this should be an array for each type, expressing the quantities he took on a trip
    uint8[] sequence;
    uint16 navigation;
    uint16 luck;
    uint16 strength;
    uint256 voyageId;
    uint256 dpsId;
    uint256 flagshipId;
    uint256 lockedBlock;
    uint256 lockedTimestamp;
    uint256 claimedTime;
}

struct VoyageResult {
    uint16 awardedChests;
    uint8[9] destroyedSupportShips;
    uint8 totalSupportShipsDestroyed;
    uint8 healthDamage;
    uint16 skippedInteractions;
    uint16[] interactionRNGs;
    uint8[] interactionResults;
}

struct VoyageStatusCache {
    uint256 strength;
    uint256 luck;
    uint256 navigation;
    string entropy;
}

error AddressZero();
error Paused();
error WrongParams(uint256 _location);
error WrongState(uint256 _state);
error Unauthorized();
error NotEnoughTokens();

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./DPSStructs.sol";

interface DPSVoyageI is IERC721Enumerable {
    function mint(
        address _owner,
        uint256 _tokenId,
        VoyageConfig calldata config
    ) external;

    function burn(uint256 _tokenId) external;

    function getVoyageConfig(uint256 _voyageId) external view returns (VoyageConfig memory config);

    function tokensOfOwner(address _owner) external view returns (uint256[] memory);

    function exists(uint256 _tokenId) external view returns (bool);

    function maxMintedId() external view returns (uint256);
}

interface DPSRandomI {
    function getRandomBatch(
        address _address,
        uint256[] memory _blockNumber,
        bytes32[] memory _hash1,
        bytes32[] memory _hash2,
        uint256[] memory _timestamp,
        bytes[] calldata _signature,
        string[] calldata _entropy,
        uint256 _min,
        uint256 _max
    ) external view returns (uint256[] memory randoms);

    function getRandomUnverifiedBatch(
        address _address,
        uint256[] memory _blockNumber,
        bytes32[] memory _hash1,
        bytes32[] memory _hash2,
        uint256[] memory _timestamp,
        string[] calldata _entropy,
        uint256 _min,
        uint256 _max
    ) external pure returns (uint256[] memory randoms);

    function getRandom(
        address _address,
        uint256 _blockNumber,
        bytes32 _hash1,
        bytes32 _hash2,
        uint256 _timestamp,
        bytes calldata _signature,
        string calldata _entropy,
        uint256 _min,
        uint256 _max
    ) external view returns (uint256 randoms);

    function getRandomUnverified(
        address _address,
        uint256 _blockNumber,
        bytes32 _hash1,
        bytes32 _hash2,
        uint256 _timestamp,
        string calldata _entropy,
        uint256 _min,
        uint256 _max
    ) external pure returns (uint256 randoms);

    function checkCausalityParams(
        CausalityParams calldata _causalityParams,
        VoyageConfig calldata _voyageConfig,
        LockedVoyage calldata _lockedVoyage
    ) external pure;
}

interface DPSGameSettingsI {
    function getVoyageConfig(VOYAGE_TYPE _type) external view returns (CartographerConfig memory);

    function maxSkillsCap() external view returns (uint16);

    function maxRollCap() external view returns (uint16);

    function flagshipBaseSkills() external view returns (uint16);

    function maxOpenLockBoxes() external view returns (uint256);

    function blockJumps() external view returns (uint16);

    function getSkillsPerFlagshipParts() external view returns (uint16[7] memory skills);

    function getSkillTypeOfEachFlagshipPart() external view returns (uint8[7] memory skillTypes);

    function getTMAPPerVoyageType(VOYAGE_TYPE _type) external view returns (uint256);

    function gapBetweenVoyagesCreation() external view returns (uint256);

    function isPaused(uint8 _component) external view returns (uint8);

    function tmapPerDoubloon() external view returns (uint256);

    function repairFlagshipCost() external view returns (uint256);

    function doubloonPerUpgradePart() external view returns (uint256);

    function getChestDoubloonRewards(VOYAGE_TYPE _type) external view returns (uint256);

    function computeFlagShipSkills(uint8[7] calldata levels, VoyageStatusCache memory _claimingRewardsCache)
        external
        view
        returns (VoyageStatusCache memory);

    function computeSupportSkills(
        uint8[9] calldata _supportShips,
        ARTIFACT_TYPE _type,
        VoyageStatusCache memory _claimingRewardsCache
    ) external view returns (VoyageStatusCache memory);

    function getDoubloonsPerSupportShipType(SUPPORT_SHIP_TYPE _type) external view returns (uint256);

    function getSupportShipsSkillBoosts(SUPPORT_SHIP_TYPE _type) external view returns (uint16);

    function getMaxSupportShipsPerVoyageType(VOYAGE_TYPE _type) external view returns (uint8);

    function getMaxRollPerChest(VOYAGE_TYPE _type) external view returns (uint256);

    function maxRollCapLockBoxes() external view returns (uint16);

    function getLockBoxesDistribution(ARTIFACT_TYPE _type) external view returns (uint16[2] memory);

    function getVoyageDebuffs(VOYAGE_TYPE _type) external view returns (uint16);

    function debuffVoyage(VOYAGE_TYPE _voyageType, VoyageStatusCache memory _claimingRewardsCache)
        external
        view
        returns (VoyageStatusCache memory);

    function interpretResults(
        uint256 _result,
        VoyageResult memory _voyageResult,
        LockedVoyage calldata _lockedVoyage,
        VoyageStatusCache memory _claimingRewardsCache,
        INTERACTION _interaction,
        CausalityParams calldata _causalityParams,
        uint256 _index
    ) external view returns (VoyageResult memory, VoyageStatusCache memory);

    function getArtifactSkillBoosts(ARTIFACT_TYPE _type) external view returns (uint16);
}

interface DPSPirateFeaturesI {
    function getTraitsAndSkills(uint16 _dpsId) external view returns (string[8] memory, uint16[3] memory);
}

interface DPSSupportShipI is IERC1155 {
    function burn(
        address _from,
        uint256 _type,
        uint256 _amount
    ) external;

    function mint(
        address _owner,
        uint256 _type,
        uint256 _amount
    ) external;
}

interface DPSFlagshipI is IERC721 {
    function mint(address _owner, uint256 _id) external;

    function burn(uint256 _id) external;

    function upgradePart(
        FLAGSHIP_PART _trait,
        uint256 _tokenId,
        uint8 _level
    ) external;

    function getPartsLevel(uint256 _flagshipId) external view returns (uint8[7] memory);

    function tokensOfOwner(address _owner) external view returns (uint256[] memory);

    function exists(uint256 _tokenId) external view returns (bool);
}

interface DPSCartographerI {
    function viewVoyageConfiguration(CausalityParams calldata causalityParams, uint256 _voyageId)
        external
        view
        returns (VoyageConfig memory voyageConfig);

    function buyers(uint256 _voyageId) external view returns (address);
}

interface DPSChestsI is IERC1155 {
    function mint(
        address _to,
        VOYAGE_TYPE _voyageType,
        uint256 _amount
    ) external;

    function burn(
        address _from,
        VOYAGE_TYPE _voyageType,
        uint256 _amount
    ) external;
}

interface MintableBurnableIERC1155 is IERC1155 {
    function mint(
        address _to,
        uint256 _type,
        uint256 _amount
    ) external;

    function burn(
        address _from,
        uint256 _type,
        uint256 _amount
    ) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}
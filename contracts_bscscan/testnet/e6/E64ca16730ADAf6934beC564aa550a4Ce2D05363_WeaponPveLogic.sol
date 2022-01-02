pragma solidity 0.6.6;

import "./WeaponPveData.sol";
import "./HeroCore.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./ExperienceCard.sol";
import "./WeaponCore.sol";

contract WeaponPveLogic is Ownable {

    struct PveLog {
        address fightAddress;
        uint256 checkPointId;
        bool win;
        uint256 totalIncome;
        uint256 totalExperience;
        uint256 fightTime;
    }

    struct HeroRiseStarData {
        uint256 riseStarPrice;
        uint256 riseRate;
        uint256 riseStar;
    }

    PveLog[] public pveLogs;

    WeaponPveData public pveData;
    HeroCore public heroCore;
    ExperienceCard public experienceCardData;
    WeaponCore public weaponCore;
    uint256 private seed;

    address public wmtAddress;
    address public wmmAddress;

    uint256 public heroPerPrice;
    mapping(uint256 => HeroRiseStarData) public heroRiseStarDefine;
    bool public openLotteryHero;
    address public incomeAddress;

    // key: checkpointId key: heroId, value: recent fight time
    mapping(uint256 => mapping(uint256 => uint256)) public heroRecentFightTime;
    // key: checkpointId key: weaponId, value: recent fight time
    mapping(uint256 => mapping(uint256 => uint256)) public weaponRecentFightTime;
    // key: num of group, value: increase income, div 100
    mapping(uint256 => uint256) public groupIncreaseIncome;

    event PveFight(address indexed _owner, uint256 indexed _checkPointId, bool _win, uint256 _income, uint256 _experience);
    event LotteryHero(address indexed _owner, uint256 indexed _heroId);
    event BuyExperienceCard(address indexed _owner, uint256 _cardId, uint256 _experience);
    event UpgradeHero(uint256 indexed _heroId, uint256 _star, uint256 _oldLevel, uint256 _newLevel, uint256 _experience);
    event HeroRiseStar(uint256 indexed _heroId, uint256 _oldStar, uint256 _newStar, bool _success, uint256 _cost);

    constructor(WeaponPveData _pveData, HeroCore _heroCore, WeaponCore _weaponCore, ExperienceCard _cardData, address _wmt, address _wmm) public {
        heroCore = _heroCore;
        pveData = _pveData;
        weaponCore = _weaponCore;
        experienceCardData = _cardData;
        wmtAddress = _wmt;
        wmmAddress = _wmm;
        initData();
    }

    function initData() internal {
        // random seed init
        seed = 20579;
        // group increase init
        groupIncreaseIncome[1] = 0;
        groupIncreaseIncome[2] = 3;
        groupIncreaseIncome[3] = 6;
        groupIncreaseIncome[4] = 10;
        // weather open lottery hero
        openLotteryHero = true;
        // income address init
        incomeAddress = msg.sender;
    }

    function withdrawWmt(address _receipt, uint256 _amount) public onlyOwner {
        IERC20(wmtAddress).transfer(_receipt, _amount);
    }

    function withdrawWmm(address _receipt, uint256 _amount) public onlyOwner {
        IERC20(wmmAddress).transfer(_receipt, _amount);
    }

    function setAddressConfig(
        address _wmmAddress,
        address _wmtAddress,
        WeaponPveData _pveDataDefineAddress,
        HeroCore _heroContractAddress,
        ExperienceCard _experienceDataAddress,
        WeaponCore _weaponContractAddress) public onlyOwner {
        wmtAddress = _wmtAddress;
        wmmAddress = _wmmAddress;
        pveData = _pveDataDefineAddress;
        heroCore = _heroContractAddress;
        experienceCardData = _experienceDataAddress;
        weaponCore = _weaponContractAddress;
    }

    function setLotteryHeroConfig(
        uint256 _lotteryHeroPerPrice,
        address _incomeAddress,
        bool _openLottery,
        uint256 _seed) public onlyOwner {
        heroPerPrice = _lotteryHeroPerPrice;
        incomeAddress = _incomeAddress;
        openLotteryHero = _openLottery;
        seed = _seed;
    }

    function setRiseStarConfig(uint256 _star, uint256 _price, uint256 _rate) public onlyOwner {
        require(_star > 0, "rise star define must greater than zero");
        heroRiseStarDefine[_star] = HeroRiseStarData(_price, _rate, _star);
    }

    function setGroupIncreaseIncome(uint256 _groupNum, uint256 _increase) public onlyOwner {
        groupIncreaseIncome[_groupNum] = _increase;
    }


    function lotteryHeroByWmt(uint256 _totalCost, uint256 _num) public returns (
        uint256[] memory heroIds,
        uint256[] memory categories,
        uint256[] memory levels,
        uint256[] memory stars,
        uint256[] memory experiences,
        uint256[] memory powerValues) {
        require(openLotteryHero, "Hero lottery, current has close the lottery");
        require(_num > 0, "Hero lottery, lottery of num must be greater than zero");
        require(_totalCost == _num * heroPerPrice, "Hero lottery, total cost must be equal the num of times mul per price");
        _validateERC20Balance(wmtAddress, _totalCost);

        IERC20(wmtAddress).transferFrom(msg.sender, incomeAddress, _totalCost);
        heroIds = new uint256[](_num);
        categories = new uint256[](_num);
        levels = new uint256[](_num);
        stars = new uint256[](_num);
        experiences = new uint256[](_num);
        powerValues = new uint256[](_num);
        uint256 heroId;
        uint256 category;
        uint256 star;
        uint256 powerValue;
        for (uint256 index = 0; index < _num; index++) {
            (heroId, category, star, powerValue) = _randomCreateHero();
            heroIds[index] = heroId;
            categories[index] = category;
            levels[index] = 1;
            stars[index] = star;
            experiences[index] = 0;
            powerValues[index] = powerValue;
            emit LotteryHero(msg.sender, heroIds[index]);
        }
    }

    function buyExperienceByWmm(uint256 _totalCost, uint256 _experienceCardId, uint256 _num) public returns (uint256[] memory cardIds) {
        require(_num > 0, "Buy Experience: buy times must be greater than zero");
        uint256 level = 0;
        uint256 experience = 0;
        uint256 price = 0;
        bool open = false;
        (level, experience, price, open) = pveData.getExperienceByCardId(_experienceCardId);
        require(open, "Buy experience: experience card is not existed or has close");
        require(_totalCost == _num * price, "Buy experience: buy experience card error, the cost must be equal the num mul price");
        _validateERC20Balance(wmmAddress, _totalCost);

        IERC20(wmmAddress).transferFrom(msg.sender, incomeAddress, _totalCost);
        cardIds = new uint256[](_num);
        for (uint256 index = 0; index < _num; index++) {
            cardIds[index] = experienceCardData.mintExperienceCard(msg.sender, level, experience);
            emit BuyExperienceCard(msg.sender, cardIds[index], experience);
        }
        return cardIds;
    }

    function heroUpgradeByExperienceCard(uint256 _heroId, uint256[] memory _cardIds) public returns (bool) {
        require(_cardIds.length > 0, "Hero Upgrade: consume experience card length must be greater than zero");
        require(heroCore.ownerOf(_heroId) == msg.sender, "Hero Upgrade: the hero is not apply the msg.sender");
        _validateIERC721Owner(address(experienceCardData), _cardIds);
        // category, level, star, experience, powerValue, mintTime
        uint256[] memory heroInfo = heroCore.getHeroInfoByHeroId(_heroId);
        uint256 maxLevel = 0;
        uint256 maxExperience = 0;
        // level, maxExperience
        (maxLevel, maxExperience) = pveData.getMaxLevelAndExperienceByStar(heroInfo[2]);
        require(heroInfo[3] < maxExperience, "Hero Upgrade: current hero star has been raised to max level");
        uint256 addExperience = 0;
        uint256[] memory cardInfo = new uint256[](3);
        for (uint256 index = 0; index < _cardIds.length; index++) {
            // level, experience, mintTime
            (cardInfo[0], cardInfo[1], cardInfo[2]) = experienceCardData.getExperienceCardInfoByCardId(_cardIds[index]);
            addExperience += cardInfo[1];
        }
        _upgradeHero(_heroId, addExperience);
        // burn experience card
        for (uint256 index = 0; index < _cardIds.length; index++) {
            experienceCardData.burnExperienceCard(_cardIds[index]);
        }
        return true;
    }

    function heroRiseStar(uint256 _riseHeroId, uint256[] memory _burnHeroIds, uint256 _cost) public returns (bool) {
        // **************************** verify begin **********************************************
        require(_burnHeroIds.length > 0, "Hero Rise star: rise star burn hero length must be greater than zero");
        // verify owner
        require(heroCore.ownerOf(_riseHeroId) == msg.sender, "Hero Rise star: the hero is not apply the msg.sender");
        _validateIERC721Owner(address(heroCore), _burnHeroIds);
        // verify hero weather to rise star
        // category, level, star, experience, powerValue, mintTime
        uint256[] memory properties = heroCore.getHeroInfoByHeroId(_riseHeroId);
        require(properties[2] == _burnHeroIds.length, "Hero Rise star: Not enough hero to rise star");
        HeroRiseStarData memory riseStarInfo = heroRiseStarDefine[properties[2]];
        require(_cost == riseStarInfo.riseStarPrice, "Hero Rise star: rise star cost must be equal set price");
        require(riseStarInfo.riseStar != 0, "Hero Rise star: rise star define is zero");
        _validateERC20Balance(wmmAddress, _cost);
        uint256[] memory maxLevelAndExperiences = new uint256[](2);
        // level, maxExperience
        (maxLevelAndExperiences[0], maxLevelAndExperiences[1]) = pveData.getMaxLevelAndExperienceByStar(properties[2]);
        require(properties[3] == maxLevelAndExperiences[1], "Hero Rise star: current hero did not reach the max level");
        require(properties[1] == maxLevelAndExperiences[0], "Hero Rise star: current hero did not reach the max level");
        // verify max star
        uint256[] memory maxLevelAndStar = new uint256[](2);
        //level, star, minExperience, maxExperience, minPowerValue, maxPowerValue
        (maxLevelAndStar[0], maxLevelAndStar[1],,,,) = pveData.getMaxUpgradeInfo();
        require(properties[2] < maxLevelAndStar[1], "Hero Rise star: current hero has reach max star");
        // verify every burn hero star must be equal current rise hero star
        uint256[] memory burnHeroProperties;
        for (uint256 index = 0; index < _burnHeroIds.length; index++) {
            // category, level, star, experience, powerValue
            burnHeroProperties = heroCore.getHeroInfoByHeroId(_burnHeroIds[index]);
            require(properties[2] == burnHeroProperties[2], "Hero Rise star: insufficient hero star consumed");
        }
        // **************************** verify end **********************************************
        IERC20(wmmAddress).transferFrom(msg.sender, incomeAddress, _cost);
        uint256 random = _getRand(0, 100);
        // rise star failed, return
        if (random >= riseStarInfo.riseRate) {
            emit HeroRiseStar(_riseHeroId, properties[2], properties[2], false, _cost);
            return false;
        }
        heroCore.updateHero(_riseHeroId, properties[0], properties[1], properties[2] + 1, properties[3], properties[4]);
        _upgradeHero(_riseHeroId, 1);
        // burn hero card
        for (uint256 index = 0; index < _burnHeroIds.length; index++) {
            heroCore.burnHero(_burnHeroIds[index]);
        }
        emit HeroRiseStar(_riseHeroId, properties[2], properties[2] + 1, true, _cost);
        return true;
    }

    function pveFight(uint256 _checkPointId, uint256[] memory _heroIds, uint256[] memory _weaponIds) public returns (
        bool win,
        uint256 experience,
        uint256 wmmIncome) {
        // ****************************************** validate begin *********************************************
        require(_heroIds.length > 0, "Pve Fight: fight hero length must be greater than zero");
        uint256[] memory checkPointInfo = new uint256[](9);
        bool open = false;
        // maxEnemy, minPowerValue, maxPowerValue, minHeroLevel, winExperience, failExperience, winIncome, failIncome, intervalSecond
        (checkPointInfo, open) = pveData.getCheckPointInfoById(_checkPointId);
        require(open, "Pve Fight: current check point has closed");
        require(_heroIds.length > 0 && _heroIds.length <= checkPointInfo[0], "Pve Fight: select hero error, must be greater than zero and less than the max enemy");
        require(_weaponIds.length <= _heroIds.length, "Pve Fight: weapon select error, must be less than the number of heroes ");
        _validateIERC721Owner(address(heroCore), _heroIds);
        _validateIERC721Owner(address(weaponCore), _weaponIds);
        // verify interval
        uint256[] memory heroProperties;
        for (uint256 index = 0; index < _heroIds.length; index++) {
            require((block.timestamp - heroRecentFightTime[_checkPointId][_heroIds[index]]) >= checkPointInfo[8], "Pve Fight: has hero not satisfied the check point interval");
            // category, level, star, experience, powerValue
            heroProperties = heroCore.getHeroInfoByHeroId(_heroIds[index]);
            require(heroProperties[1] >= checkPointInfo[3], "Pve Fight: min level hero must be greater than check point min level");
        }
        for (uint256 index = 0; index < _weaponIds.length; index++) {
            require((block.timestamp - weaponRecentFightTime[_checkPointId][_weaponIds[index]]) >= checkPointInfo[8], "Pve Fight: has weapon not satisfied the check point interval");
        }
        // **************************************** validate end *********************************************
        win = _pveFight(_checkPointId, _heroIds, _weaponIds);
        wmmIncome = 0;
        experience = 0;
        if (win) {
            wmmIncome = checkPointInfo[6] * _heroIds.length;
            experience = checkPointInfo[4];
        } else {
            wmmIncome = checkPointInfo[7] * _heroIds.length;
            experience = checkPointInfo[5];
        }
        wmmIncome = wmmIncome + wmmIncome * groupIncreaseIncome[_heroIds.length] / 100;
        pveLogs.push(PveLog(msg.sender, _checkPointId, win, wmmIncome, experience * _heroIds.length, block.timestamp));
        // wmm income
        if (wmmIncome > 0) {
            IERC20(wmmAddress).transfer(msg.sender, wmmIncome);
        }
        if (experience > 0) {
            for (uint index = 0; index < _heroIds.length; index++) {
                _upgradeHero(_heroIds[index], experience);
            }
        }
        emit PveFight(msg.sender, _checkPointId, win, wmmIncome, experience);
    }

    function getPveFightLog(uint256 _id) public view returns (
        uint256 checkPointId,
        address fightAddress,
        bool win,
        uint256 income,
        uint256 experience,
        uint256 time) {
        require(_id < pveLogs.length, "PveLog error: out of pve log length");
        PveLog memory pveLog = pveLogs[_id];
        return (pveLog.checkPointId, pveLog.fightAddress, pveLog.win, pveLog.totalIncome, pveLog.totalExperience, pveLog.fightTime);
    }

    function getPveLogLength() public view returns (uint256) {
        return pveLogs.length;
    }

    function getHeroRecentFightTime(uint256 _checkPointId, uint256 _heroId) public view returns (uint256 recentFightTime) {
        return heroRecentFightTime[_checkPointId][_heroId];
    }

    function getWeaponRecentFightTime(uint256 _checkPointId, uint256 _weaponId) public view returns (uint256 recentFightTime) {
        return weaponRecentFightTime[_checkPointId][_weaponId];
    }

    function getWeaponPveIncrease(uint256 _category, uint256 _level) public view returns (uint256 increase) {
        return pveData.getWeaponIncrease(_category, _level);
    }

    function getRiseStarInfo(uint256 _star) public view returns (uint256 star, uint256 price, uint256 rate) {
        HeroRiseStarData memory riseStarInfo = heroRiseStarDefine[_star];
        return (riseStarInfo.riseStar, riseStarInfo.riseStarPrice, riseStarInfo.riseRate);
    }

    function getPveCheckPoint() public view returns (
        uint256[] memory checkPointIds,
        uint256[] memory maxEnemy,
        uint256[] memory minPowerValue,
        uint256[] memory maxPowerValue,
        uint256[] memory minHeroLevel,
        bool[] memory open,
        uint256[] memory intervalSecond) {
        return pveData.getAllCheckPointInfo();
    }

    function getAllHasOwnHero() public view returns (
        uint256[] memory heroIds,
        uint256[] memory categories,
        uint256[] memory levels,
        uint256[] memory stars,
        uint256[] memory experiences,
        uint256[] memory powerValues,
        uint256[] memory mintTimes
    ) {
        heroIds = heroCore.getHeroIdByAddress(msg.sender);
        categories = new uint256[](heroIds.length);
        levels = new uint256[](heroIds.length);
        stars = new uint256[](heroIds.length);
        experiences = new uint256[](heroIds.length);
        powerValues = new uint256[](heroIds.length);
        mintTimes = new uint256[](heroIds.length);
        uint256[] memory heroInfo;
        for (uint256 index = 0; index < heroIds.length; index++) {
            heroInfo = heroCore.getHeroInfoByHeroId(heroIds[index]);
            categories[index] = heroInfo[0];
            levels[index] = heroInfo[1];
            stars[index] = heroInfo[2];
            experiences[index] = heroInfo[3];
            powerValues[index] = heroInfo[4];
            mintTimes[index] = heroInfo[5];
        }
        return (heroIds, categories, levels, stars, experiences, powerValues, mintTimes);
    }

    function getAllSellExperienceCard() public view returns (
        uint256[] memory,
        uint256[] memory,
        uint256[] memory,
        uint256[] memory) {
        return pveData.getAllOpenExperienceCard();
    }

    function getAllHasOwnExperienceCard() public view returns (
        uint256[] memory,
        uint256[] memory,
        uint256[] memory,
        uint256[] memory) {

        uint256[] memory cardIds = experienceCardData.getCardIdsByAddress(msg.sender);
        uint256[] memory levels = new uint256[](cardIds.length);
        uint256[] memory experiences = new uint256[](cardIds.length);
        uint256[] memory mintTimes = new uint256[](cardIds.length);
        uint256 resultLevel;
        uint256 resultExper;
        uint256 resultTime;
        for (uint256 index = 0; index < cardIds.length; index++) {
            (resultLevel, resultExper, resultTime) = experienceCardData.getExperienceCardInfoByCardId(cardIds[index]);
            levels[index] = resultLevel;
            experiences[index] = resultExper;
            mintTimes[index] = resultTime;
        }
        return (cardIds, levels, experiences, mintTimes);
    }

    function _pveFight(uint256 _checkPointId, uint256[] memory _heroIds, uint256[] memory _weaponIds) internal returns (bool) {
        uint256[] memory checkPointInfo = new uint256[](9);
        bool open = false;
        // maxEnemy, minPowerValue, maxPowerValue, minHeroLevel, winExperience, failExperience, winIncome, failIncome, intervalSecond
        (checkPointInfo, open) = pveData.getCheckPointInfoById(_checkPointId);
        uint256 enemyTotalPowerValue = 0;
        uint256 heroTotalPowerValue = 0;
        uint256[] memory heroInfo;
        uint256[] memory weaponInfo = new uint256[](5);
        for (uint256 index = 0; index < _heroIds.length; index++) {
            enemyTotalPowerValue += _getRand(checkPointInfo[1], checkPointInfo[2]);
            heroInfo = heroCore.getHeroInfoByHeroId(_heroIds[index]);
            heroTotalPowerValue += heroInfo[4];
            heroRecentFightTime[_checkPointId][_heroIds[index]] = block.timestamp;
        }
        for (uint256 index = 0; index < _weaponIds.length; index++) {
            // bonus, power, level, category , mintAt
            (weaponInfo[0], weaponInfo[1], weaponInfo[2], weaponInfo[3], weaponInfo[4]) = weaponCore.getWeapon(_weaponIds[index]);
            heroTotalPowerValue += pveData.getWeaponIncrease(weaponInfo[3], weaponInfo[2]);
            weaponRecentFightTime[_checkPointId][_weaponIds[index]] = block.timestamp;
        }
        if (heroTotalPowerValue >= enemyTotalPowerValue) {
            return true;
        }
        return false;
    }

    function _upgradeHero(uint256 _heroId, uint256 _addExperience) internal {
        require(_addExperience != 0, "Upgrade Hero Error: add experience equal zero");
        uint256 oldLevel = 0;
        // category, level, star, experience, powerValue
        uint256[] memory properties = heroCore.getHeroInfoByHeroId(_heroId);
        oldLevel = properties[1];
        // level, maxExperience
        uint256[] memory maxLevelAndExperiences = _getMaxLevelAndExperienceByStar(properties[2]);
        // add experience
        uint256 experience = _addExperience + properties[3];
        if (experience >= maxLevelAndExperiences[1]) {
            experience = maxLevelAndExperiences[1];
        }
        //level, star, minExperience, maxExperience, minPowerValue, maxPowerValue
        uint256[] memory defineUpgradeInfo = _getUpgradeInfoByExperience(experience);
        // star must be equal
        // require(defineUpgradeInfo[1] == properties[2], "Hero Upgrade Error: the max star must be equal current star");
        // upgrade the level and add the power value
        if (defineUpgradeInfo[0] > properties[1]) {
            properties[1] = defineUpgradeInfo[0];
            properties[4] = _getRand(defineUpgradeInfo[4], defineUpgradeInfo[5]);
        }
        properties[3] = experience;
        heroCore.updateHero(_heroId, properties[0], properties[1], properties[2], properties[3], properties[4]);
        emit UpgradeHero(_heroId, properties[2], oldLevel, properties[1], _addExperience);
    }

    function _getUpgradeInfoByExperience(uint256 _experience) internal view returns (uint256[] memory) {
        uint256[] memory defineUpgradeInfo = new uint256[](6);
        (defineUpgradeInfo[0], defineUpgradeInfo[1], defineUpgradeInfo[2], defineUpgradeInfo[3], defineUpgradeInfo[4], defineUpgradeInfo[5]) = pveData.getUpgradeInfoByExperience(_experience);
        return defineUpgradeInfo;
    }

    function _getMaxLevelAndExperienceByStar(uint256 _star) internal view returns (uint256[] memory) {
        uint256[] memory maxLevelAndExperiences = new uint256[](2);
        // level, maxExperience
        (maxLevelAndExperiences[0], maxLevelAndExperiences[1]) = pveData.getMaxLevelAndExperienceByStar(_star);
        return maxLevelAndExperiences;
    }

    function _validateERC20Balance(address erc20Address, uint256 _cost) internal view {
        uint256 balance = IERC20(erc20Address).balanceOf(msg.sender);
        require(balance >= _cost, "Balance, current balance is not enough to consume");
    }

    function _validateIERC721Owner(address erc721Address, uint256[] memory _tokenIds) internal view {
        for (uint256 index = 0; index < _tokenIds.length; index++) {
            require(IERC721(erc721Address).ownerOf(_tokenIds[index]) == msg.sender, "ERC721: the owner is not the msg.sender");
        }
    }

    // level 1
    // star 1 97%, 2 5%, 3 1%
    // powerValue from level 1 define
    function _randomCreateHero() internal returns (uint256 heroId, uint256 category, uint256 star, uint256 powerValue) {
        uint256[] memory categories = pveData.getAllHeroCategory();
        require(categories.length > 0, "Mint Hero: not define category");
        uint256 minPowerValue = 0;
        uint256 maxPowerValue = 0;
        (,,, minPowerValue, maxPowerValue) = pveData.getUpgradeInfoByLevel(1);
        require(minPowerValue != 0, "Mint Hero: not define level");
        category = categories[_getRand(0, categories.length)];
        star = 1;
        powerValue = _getRand(minPowerValue, maxPowerValue);
        uint256 starRandom = _getRand(0, 100);
        // star 3 2%
        if (starRandom > 97) {
            star = 3;
            // star 2 3%
        } else if (starRandom > 94) {
            star = 2;
        }
        heroId = heroCore.mintHero(msg.sender, category, 1, star, 0, powerValue);
    }

    // random value in [_start, _end)
    function _getRand(uint256 _start, uint256 _end) internal returns (uint256) {
        if (_start == _end) {
            return _start;
        }
        return _random(uint256(msg.sender)) % (_end - _start) + _start;
    }

    function _random(uint256 _requestId) private returns (uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, now, seed, _requestId)));
        seed += 1;
        return random;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        uint256 keyIndex = map._indexes[key];
        if (keyIndex == 0) return (false, 0); // Equivalent to contains(map, key)
        return (true, map._entries[keyIndex - 1]._value); // All indexes are 1-based
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, "EnumerableMap: nonexistent key"); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";

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

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";

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

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "../../introspection/ERC165.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";
import "../../utils/EnumerableSet.sol";
import "../../utils/EnumerableMap.sol";
import "../../utils/Strings.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
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

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || ERC721.isApprovedForAll(owner, _msgSender()),
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
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
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
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
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
        return _tokenOwners.contains(tokenId);
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
        return (spender == owner || getApproved(tokenId) == spender || ERC721.isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
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
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

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
        address owner = ERC721.ownerOf(tokenId); // internal owner

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

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
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own"); // internal owner
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
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
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId); // internal owner
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
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
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

pragma solidity 0.6.6;

import "@openzeppelin/contracts/access/Ownable.sol";

contract WeaponPveData is Ownable {

    struct PveCheckPointDefine {
        uint256 maxEnemy;
        uint256 minPowerValue;
        uint256 maxPowerValue;
        uint256 minHeroLevel;
        uint256 winExperience;
        uint256 failExperience;
        uint256 winIncome;
        uint256 failIncome;
        uint256 intervalSecond;
        bool turnOn;
    }

    struct HeroUpgradeDefine {
        uint256 level;
        uint256 star;
        uint256 minExperience;
        uint256 maxExperience;
        uint256 minHeroPowerValue;
        uint256 maxHeroPowerValue;
    }

    struct ExperienceCardDefine {
        uint256 level;
        uint256 experience;
        uint256 price;
        bool open;
    }

    PveCheckPointDefine[] public checkPoints;
    HeroUpgradeDefine[] public upGrades;
    ExperienceCardDefine[] public experiences;
    uint256[] heroCategory;

    // category level => power value increase
    mapping(uint256 => mapping(uint256 => uint256)) public weaponIncrease;

    event AddCheckPoint(uint256 _checkPointId, uint256 _maxEnemy, uint256 _minPowerValue, uint256 _maxPowerValue, uint256 _minHeroLevel, uint256 _winExperience, uint256 _failExperience, uint256 _winIncome, uint256 _faildIncome, uint256 _intervalSecond, bool _turnOn);
    event UpdateCheckPoint(uint256 _checkPointId, uint256 _maxEnemy, uint256 _minPowerValue, uint256 _maxPowerValue, uint256 _minHeroLevel, uint256 _winExperience, uint256 _failExperience, uint256 _winIncome, uint256 _faildIncome, uint256 _intervalSecond, bool _turnOn);
    event DeleteCheckPoint(uint256 _checkPointId);
    event AddHeroUpgrade(uint256 _upgradeId, uint256 _level, uint256 _star, uint256 _minExperience, uint256 _maxExperience, uint256 _minHeroPowerValue, uint256 _maxHeroPowerValue);
    event UpdateHeroUpgrade(uint256 _upgradeId, uint256 _level, uint256 _star, uint256 _minExperience, uint256 _maxExperience, uint256 _minHeroPowerValue, uint256 _maxHeroPowerValue);
    event DeleteHeroUpgrade(uint256 _upgradeId);
    event AddExperienceCard(uint256 _cardId, uint256 _level, uint256 _experience, uint256 _price, bool _open);
    event UpdateExperienceCard(uint256 _cardId, uint256 _level, uint256 _experience, uint256 _price, bool _open);
    event DeleteExperienceCard(uint256 _cardId);
    event UpdateWeaponIncrease(uint256 _category, uint256 _level, uint256 _increase);
    event DeleteWeaponIncrease(uint256 _category, uint256 _level);

    constructor() public {
        checkPoints.push(PveCheckPointDefine(0, 0, 0, 0, 0, 0, 0, 0, 0, false));
        experiences.push(ExperienceCardDefine(0, 0, 0, false));
        upGrades.push(HeroUpgradeDefine(0, 0, 0, 0, 0, 0));
    }

    function batchAddHeroCategory(uint256[] memory categories) public onlyOwner {
        for (uint256 index = 0; index < categories.length; index++) {
            heroCategory.push(categories[index]);
        }
    }

    function deleteHeroCategory(uint256 category) public onlyOwner {
        uint256 categoryLength = heroCategory.length;
        for (uint256 index; index < categoryLength; index++) {
            if (heroCategory[index] == category) {
                heroCategory[index] = heroCategory[categoryLength - 1];
                heroCategory.pop();
                break;
            }
        }
    }

    function getAllHeroCategory() public view returns (uint256[] memory categories) {
        uint256 length = heroCategory.length;
        categories = new uint256[](length);
        for (uint256 index = 0; index < length; index++) {
            categories[index] = heroCategory[index];
        }
    }

    function getWeaponIncrease(uint256 _category, uint256 level) public view returns (uint256 increase) {
        increase = weaponIncrease[_category][level];
    }

    function batchAddWeaponIncrease(uint256[] memory _categories, uint256[] memory _levels, uint256[] memory _increases) public onlyOwner {
        require(_categories.length == _levels.length, "Batch add increase error, the length is not equal");
        require(_categories.length == _increases.length, "Batch add increase error, the length is not equal");
        for (uint256 index = 0; index < _categories.length; index++) {
            weaponIncrease[_categories[index]][_levels[index]] = _increases[index];
            emit UpdateWeaponIncrease(_categories[index], _levels[index], _increases[index]);
        }
    }

    function batchDeleteWeaponIncrease(uint256[] memory _categories, uint256[] memory _levels) public onlyOwner {
        for (uint256 index = 0; index < _categories.length; index++) {
            delete weaponIncrease[_categories[index]][_levels[index]];
            emit DeleteWeaponIncrease(_categories[index], _levels[index]);
        }
    }

    function getExperienceByCardId(uint256 _cardId) public view returns (uint256 level, uint256 exper, uint256 price, bool open) {
        require(_cardId >= 0 && _cardId < experiences.length, "Query experience card error, out of arr length");
        ExperienceCardDefine memory card = experiences[_cardId];
        level = card.level;
        exper = card.experience;
        price = card.price;
        open = card.open;
    }

    function getAllOpenExperienceCard() public view returns (uint256[] memory cardIds, uint256[] memory levels, uint256[] memory expers, uint256[] memory prices) {
        uint256 cardLength = experiences.length;
        uint256 openLength = 0;
        uint256[] memory cardIdsTemp = new uint256[](cardLength);
        ExperienceCardDefine[] memory openExperienceCards = new ExperienceCardDefine[](cardLength);
        for (uint256 index = 0; index < cardLength; index++) {
            ExperienceCardDefine memory experienceCard = experiences[index];
            if (!experienceCard.open) {
                continue;
            }
            cardIdsTemp[openLength] = index;
            openExperienceCards[openLength] = experienceCard;
            openLength++;
        }
        cardIds = new uint256[](openLength);
        levels = new uint256[](openLength);
        expers = new uint256[](openLength);
        prices = new uint256[](openLength);
        for (uint256 index = 0; index < openLength; index++) {
            cardIds[index] = cardIdsTemp[index];
            levels[index] = openExperienceCards[index].level;
            expers[index] = openExperienceCards[index].experience;
            prices[index] = openExperienceCards[index].price;
        }
    }

    function batchAddExperienceCard(
        uint256[] memory _levels,
        uint256[] memory _expers,
        uint256[] memory _prices,
        bool[] memory _opens
    ) public onlyOwner {
        require(_levels.length == _expers.length, "Batch add experience card error, length is not equal");
        require(_levels.length == _prices.length, "Batch add experience card error, length is not equal");
        require(_levels.length == _opens.length, "Batch add experience card error, length is not equal");
        for (uint256 index = 0; index < _levels.length; index++) {
            uint256 length = experiences.length;
            ExperienceCardDefine memory experienceCard = ExperienceCardDefine(_levels[index], _expers[index], _prices[index], _opens[index]);
            experiences.push(experienceCard);
            emit AddExperienceCard(length, experienceCard.level, experienceCard.experience, experienceCard.price, experienceCard.open);
        }
    }

    function updateExperienceCard(uint256 _cardId, uint256 _level, uint256 _experience, uint256 _price, bool _open) public onlyOwner {
        require(_cardId > 0 && _cardId < experiences.length, "Update experience card error, out of arr length");
        ExperienceCardDefine memory experienceCard = experiences[_cardId];
        experienceCard.level = _level;
        experienceCard.experience = _experience;
        experienceCard.price = _price;
        experienceCard.open = _open;
        experiences[_cardId] = experienceCard;

        emit UpdateExperienceCard(_cardId, _level, _experience, _price, _open);
    }

    function batchDeleteExperienceCard(uint256[] memory _cardIds) public onlyOwner {
        for (uint256 index = 0; index < _cardIds.length; index++) {
            uint256 _cardId = _cardIds[index];
            require(_cardId > 0 && _cardId < experiences.length, "Delete experience card error, out of arr length");
            delete experiences[_cardId];
            emit DeleteExperienceCard(_cardId);
        }
    }

    function getMaxLevelAndExperienceByStar(uint256 _star) public view returns (uint256 level, uint256 maxExperience) {
        uint256 length = upGrades.length;
        level = 0;
        maxExperience = 0;
        for (uint256 index = 0; index < length; index++) {
            HeroUpgradeDefine memory upgrade = upGrades[index];
            if (_star != upgrade.star) {
                continue;
            }
            if (level < upgrade.level && maxExperience < upgrade.maxExperience) {
                level = upgrade.level;
                maxExperience = upgrade.maxExperience;
            }
        }
    }

    function getMaxUpgradeInfo() public view returns (
        uint256 level,
        uint256 star,
        uint256 minExperience,
        uint256 maxExperience,
        uint256 minPowerValue,
        uint256 maxPowerValue
    ) {
        uint256 length = upGrades.length;
        HeroUpgradeDefine memory temp;
        for (uint256 index = 0; index < length; index++) {
            HeroUpgradeDefine memory upgrade = upGrades[index];
            if (temp.star < upgrade.star) {
                temp = upgrade;
                continue;
            }
            if (temp.maxExperience < upgrade.maxExperience) {
                temp = upgrade;
            }
        }
        level = temp.level;
        star = temp.star;
        minExperience = temp.minExperience;
        maxExperience = temp.maxExperience;
        minPowerValue = temp.minHeroPowerValue;
        maxPowerValue = temp.maxHeroPowerValue;
    }

    function getUpgradeInfoByLevel(uint256 _level) public view returns (
        uint256 star,
        uint256 minExperience,
        uint256 maxExperience,
        uint256 minPowerValue,
        uint256 maxPowerValue) {
        uint256 length = upGrades.length;
        HeroUpgradeDefine memory temp;
        for (uint256 index = 0; index < length; index++) {
            HeroUpgradeDefine memory upgrade = upGrades[index];
            if (upgrade.level == _level) {
                temp = upgrade;
                break;
            }
        }
        star = temp.star;
        minExperience = temp.minExperience;
        maxExperience = temp.maxExperience;
        minPowerValue = temp.minHeroPowerValue;
        maxPowerValue = temp.maxHeroPowerValue;
    }

    function getUpgradeInfoByExperience(uint256 _experience) public view returns (
        uint256 level,
        uint256 star,
        uint256 minExperience,
        uint256 maxExperience,
        uint256 minPowerValue,
        uint256 maxPowerValue) {
        uint256 length = upGrades.length;
        HeroUpgradeDefine memory temp;
        for (uint256 index = 0; index < length; index++) {
            HeroUpgradeDefine memory upgrade = upGrades[index];
            if (_experience >= upgrade.minExperience && _experience <= upgrade.maxExperience) {
                temp = upgrade;
                break;
            }
        }
        level = temp.level;
        star = temp.star;
        minExperience = temp.minExperience;
        maxExperience = temp.maxExperience;
        minPowerValue = temp.minHeroPowerValue;
        maxPowerValue = temp.maxHeroPowerValue;
    }

    function batchAddHeroUpgrade(
        uint256[] memory _level,
        uint256[] memory _star,
        uint256[] memory _minExperience,
        uint256[] memory _maxExperience,
        uint256[] memory _minHeroPowerValue,
        uint256[] memory _maxHeroPowerValue
    ) public onlyOwner {
        require(_level.length == _star.length, "Batch add hero upgrade error, arr length is not equal");
        require(_level.length == _minExperience.length, "Batch add hero upgrade error, arr length is not equal");
        require(_level.length == _maxExperience.length, "Batch add hero upgrade error, arr length is not equal");
        require(_level.length == _minHeroPowerValue.length, "Batch add hero upgrade error, arr length is not equal");
        require(_level.length == _maxHeroPowerValue.length, "Batch add hero upgrade error, arr length is not equal");
        for (uint256 index = 0; index < _level.length; index++) {
            HeroUpgradeDefine memory upgrade = HeroUpgradeDefine(_level[index], _star[index], _minExperience[index], _maxExperience[index], _minHeroPowerValue[index], _maxHeroPowerValue[index]);
            uint256 length = upGrades.length;
            upGrades.push(upgrade);
            emit AddHeroUpgrade(length, upgrade.level, upgrade.star, upgrade.minExperience, upgrade.maxExperience, upgrade.minHeroPowerValue, upgrade.maxHeroPowerValue);
        }
    }

    function batchDeleteHeroUpgrade(uint256[] memory _upgradeIds) public onlyOwner {
        for (uint256 index = 0; index < _upgradeIds.length; index++) {
            uint256 _upgradeId = _upgradeIds[index];
            require(_upgradeId > 0 && _upgradeId < upGrades.length, "Delete hero upgrade: out of upgrade length");
            delete upGrades[_upgradeId];

            emit DeleteHeroUpgrade(_upgradeId);
        }
    }

    function updateHeroUpgradeById(
        uint256 _upgradeId,
        uint256 _level,
        uint256 _star,
        uint256 _minExperience,
        uint256 _maxExperience,
        uint256 _minHeroPowerValue,
        uint256 _maxHeroPowerValue) public onlyOwner {
        require(_upgradeId > 0 && _upgradeId < upGrades.length, "Upgrade: out of upgrade length");
        HeroUpgradeDefine memory upgrade = upGrades[_upgradeId];
        upgrade.level = _level;
        upgrade.star = _star;
        upgrade.minExperience = _minExperience;
        upgrade.maxExperience = _maxExperience;
        upgrade.minHeroPowerValue = _minHeroPowerValue;
        upgrade.maxHeroPowerValue = _maxHeroPowerValue;
        upGrades[_upgradeId] = upgrade;
        emit UpdateHeroUpgrade(_upgradeId, upgrade.level, upgrade.star, upgrade.minExperience, upgrade.maxExperience, upgrade.minHeroPowerValue, upgrade.maxHeroPowerValue);
    }

    function getCheckPointInfoById(uint256 _checkPointId) public view returns (
    // maxEnemy, minPowerValue, maxPowerValue, minHeroLevel, winExperience, failExperience, winIncome, failIncome, intervalSecond
        uint256[] memory checkPointInfo,
        bool open
    ) {
        require(_checkPointId > 0 && _checkPointId < checkPoints.length, "check point id error, out of length");
        PveCheckPointDefine memory checkPoint = checkPoints[_checkPointId];
        checkPointInfo = new uint256[](9);
        checkPointInfo[0] = checkPoint.maxEnemy;
        checkPointInfo[1] = checkPoint.minPowerValue;
        checkPointInfo[2] = checkPoint.maxPowerValue;
        checkPointInfo[3] = checkPoint.minHeroLevel;
        checkPointInfo[4] = checkPoint.winExperience;
        checkPointInfo[5] = checkPoint.failExperience;
        checkPointInfo[6] = checkPoint.winIncome;
        checkPointInfo[7] = checkPoint.failIncome;
        checkPointInfo[8] = checkPoint.intervalSecond;
        open = checkPoint.turnOn;
    }

    function getAllCheckPointInfo() public view returns (
        uint256[] memory checkPointIds,
        uint256[] memory maxEnemy,
        uint256[] memory minPowerValue,
        uint256[] memory maxPowerValue,
        uint256[] memory minHeroLevel,
        bool[] memory open,
        uint256[] memory intervalSecond
    ) {
        uint256 openLength = 0;
        uint256[] memory checkPointIdTemp = new uint256[](checkPoints.length);
        PveCheckPointDefine[] memory openCheckPoints = new PveCheckPointDefine[](checkPoints.length);
        for (uint256 index = 1; index < checkPoints.length; index++) {
            PveCheckPointDefine memory checkPoint = checkPoints[index];
            openCheckPoints[openLength] = checkPoint;
            checkPointIdTemp[openLength] = index;
            openLength++;
        }
        checkPointIds = new uint256[](openLength);
        maxEnemy = new uint256[](openLength);
        minPowerValue = new uint256[](openLength);
        maxPowerValue = new uint256[](openLength);
        minHeroLevel = new uint256[](openLength);
        intervalSecond = new uint256[](openLength);
        open = new bool[](openLength);
        for (uint256 index = 0; index < openLength; index++) {
            PveCheckPointDefine memory checkPoint = openCheckPoints[index];
            checkPointIds[index] = checkPointIdTemp[index];
            maxEnemy[index] = checkPoint.maxEnemy;
            minPowerValue[index] = checkPoint.minPowerValue;
            maxPowerValue[index] = checkPoint.maxPowerValue;
            minHeroLevel[index] = checkPoint.minHeroLevel;
            open[index] = checkPoint.turnOn;
            intervalSecond[index] = checkPoint.intervalSecond;
        }
    }

    function batchAddCheckPoint(
        uint256[] memory _maxEnemy,
        uint256[] memory _minPower,
        uint256[] memory _maxPower,
        uint256[] memory _minLevel,
        uint256[] memory _winExperience,
        uint256[] memory _failExperience,
        uint256[] memory _winIncome,
        uint256[] memory _failIncome,
        uint256[] memory _intervalSecond,
        bool[] memory _turnOn) public onlyOwner {
        require(_maxEnemy.length == _minPower.length, "Batch add check point failed, arr length is not equal");
        require(_maxEnemy.length == _maxPower.length, "Batch add check point failed, arr length is not equal");
        require(_maxEnemy.length == _minLevel.length, "Batch add check point failed, arr length is not equal");
        require(_maxEnemy.length == _winExperience.length, "Batch add check point failed, arr length is not equal");
        require(_maxEnemy.length == _failExperience.length, "Batch add check point failed, arr length is not equal");
        require(_maxEnemy.length == _winIncome.length, "Batch add check point failed, arr length is not equal");
        require(_maxEnemy.length == _failIncome.length, "Batch add check point failed, arr length is not equal");
        require(_maxEnemy.length == _intervalSecond.length, "Batch add check point failed, arr length is not equal");
        require(_maxEnemy.length == _turnOn.length, "Batch add check point failed, arr length is not equal");
        for (uint256 i = 0; i < _maxEnemy.length; i++) {
            PveCheckPointDefine memory checkPoint = PveCheckPointDefine(_maxEnemy[i], _minPower[i], _maxPower[i], _minLevel[i], _winExperience[i], _failExperience[i], _winIncome[i], _failIncome[i], _intervalSecond[i], _turnOn[i]);
            checkPoints.push(checkPoint);
            emit AddCheckPoint(checkPoints.length - 1, checkPoint.maxEnemy, checkPoint.minPowerValue, checkPoint.maxPowerValue, checkPoint.minHeroLevel, checkPoint.winExperience, checkPoint.failExperience, checkPoint.winIncome, checkPoint.failIncome, checkPoint.intervalSecond, checkPoint.turnOn);
        }
    }

    function deleteCheckPoint(uint256[] memory _checkPointIds) public onlyOwner {
        for (uint256 index = 0; index < _checkPointIds.length; index++) {
            uint256 _checkPointId = _checkPointIds[index];
            require(_checkPointId > 0 && _checkPointId < checkPoints.length, "check point id error, out of length");
            delete checkPoints[_checkPointId];
            emit DeleteCheckPoint(_checkPointId);
        }
    }

    function updateCheckPoint(
        uint256 _checkPointId,
        uint256 _maxEnemy,
        uint256 _minPower,
        uint256 _maxPower,
        uint256 _minLevel,
        uint256 _winExperience,
        uint256 _failExperience,
        uint256 _winIncome,
        uint256 _failIncome,
        uint256 _intervalSecond,
        bool _turnOn) public onlyOwner {
        require(_checkPointId > 0 && _checkPointId < checkPoints.length, "check point id error, out of length");
        PveCheckPointDefine memory checkPoint = checkPoints[_checkPointId];
        checkPoint.maxEnemy = _maxEnemy;
        checkPoint.minPowerValue = _minPower;
        checkPoint.maxPowerValue = _maxPower;
        checkPoint.minHeroLevel = _minLevel;
        checkPoint.winExperience = _winExperience;
        checkPoint.failExperience = _failExperience;
        checkPoint.winIncome = _winIncome;
        checkPoint.failIncome = _failIncome;
        checkPoint.intervalSecond = _intervalSecond;
        checkPoint.turnOn = _turnOn;
        checkPoints[_checkPointId] = checkPoint;

        emit UpdateCheckPoint(_checkPointId, checkPoint.maxEnemy, checkPoint.minPowerValue, checkPoint.maxPowerValue, checkPoint.minHeroLevel, checkPoint.winExperience, checkPoint.failExperience, checkPoint.winIncome, checkPoint.failIncome, checkPoint.intervalSecond, checkPoint.turnOn);
    }
}

pragma solidity 0.6.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


contract WeaponCore is ERC721("Weapon Master", "Weapon Master"), Ownable {
  struct Weapon {
    uint256 bonus; // 
    uint256 power; // 
    uint256 level; // 
    uint256 category; //
    uint256 mintAt;
    uint256 attack;
    uint256 durability;
  }

  Weapon[] weapons;

  event WeaponMinted(uint256 indexed _weaponId, address indexed _owner, uint256 _bonus, uint256 _power, uint256 _level, uint256 _category, uint256 _attack, uint256 _durability);
  event WeaponRetired(uint256 indexed _weaponId);


  constructor() public {
    _mintWeapon(0, 0, 0, 0, msg.sender, 0, 0);
  }


  function getWeaponSimpleByTokenId(uint256 _weaponId) external view returns(uint256, uint256) {
    Weapon storage _weapon = weapons[_weaponId];
    return (_weapon.bonus, _weapon.power);
  }

  function getWeaponExtByTokenId(uint256 _weaponId) external view returns(uint256, uint256) {
    Weapon storage _weapon = weapons[_weaponId];
    return (_weapon.level, _weapon.category);
  }

  function getWeapon(
    uint256 _weaponId
  )
    external
    view
    returns (uint256 /* bonus */, uint256 /* power */, uint256 /* level */, uint256 /* category */, uint256 /* mintAt */)
  {
    Weapon storage _weapon = weapons[_weaponId];
    return (_weapon.bonus, _weapon.power, _weapon.level, _weapon.category, _weapon.mintAt);
  }

  function getTokenIdsByOwner(address _user) public view returns(uint256[] memory) {
    uint256 i;
    uint256 length = balanceOf(_user);
    uint256[] memory tm = new uint256[](length);
    for (i = 0; i < length; i++) {
      tm[i] = tokenOfOwnerByIndex(_user, i);
    }
    return tm;
  }


  function setBaseURI(string memory baseURI_) public onlyOwner {
    _setBaseURI(baseURI_);
  }


  function tokenURI(uint256 _weaponId) public view virtual override returns (string memory) {
    require(_exists(_weaponId), "ERC721Metadata: URI query for nonexistent token");

    // string memory _tokenURI = _tokenURIs[tokenId];
    string memory base = baseURI();
    Weapon storage _weapon = weapons[_weaponId];

    // if (bytes(base).length == 0) {
    //   return _tokenURI;
    // }
    // if (bytes(_tokenURI).length > 0) {
    //   return string(abi.encodePacked(base, _tokenURI));
    // }
    return string(abi.encodePacked(base, "/", _weapon.category.toString(), "/", _weapon.level.toString(), "/", _weaponId.toString()));
  }


  function retireWeapon(
    uint256 _weaponId,
    bool _rip
  )
    public
    onlyOwner
  {
    _burn(_weaponId);

    if (_rip) {
      delete weapons[_weaponId];
    }

    emit WeaponRetired(_weaponId);
  }


  function mintWeapon(
    uint256 _bonus,
    uint256 _power,
    uint256 _level,
    uint256 _category,
    address _owner,
    uint256 _attack,
    uint256 _durability
  )
    public
    onlyOwner
    returns(uint256)
  {
    return _mintWeapon(_bonus, _power, _level, _category, _owner, _attack, _durability);
  }


  function _mintWeapon(
    uint256 _bonus,
    uint256 _power,
    uint256 _level,
    uint256 _category,
    address _owner,
    uint256 _attack,
    uint256 _durability
  ) 
    internal returns (uint256 _weaponId) 
  {
    Weapon memory _weapon = Weapon(_bonus, _power, _level, _category, now, _attack, _durability);
    _weaponId = weapons.length;
    weapons.push(_weapon);
    _mint(_owner, _weaponId);
    emit WeaponMinted(_weaponId, _owner, _bonus, _power, _level, _category, _attack, _durability);
  }
}

pragma solidity 0.6.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./AccessControl.sol";

contract HeroCore is ERC721("Hero", "Hero"), AccessControl {

    struct Hero {
        //[0-9];
        uint256 category;
        // max 30
        uint256 level;
        // control max level -> star
        uint256 star;
        // used to control the level of upgrade
        uint256 experience;
        uint256 powerValue;
        uint256 mintTime;
    }

    Hero[] public heroArr;

    constructor() public {
        burnHero(_mintHero(msg.sender, 0, 0, 0, 0, 0));
    }

    event MintHero(uint256 indexed _heroId, address indexed _owner, uint256 _category, uint256 _level, uint256 _star, uint256 _experience, uint256 _powerValue);
    event UpdateHero(uint256 indexed _heroId, uint256 _category, uint256 _level, uint256 _starm, uint256 _experience, uint256 _powerValue);
    event BurnHero(uint256 indexed _heroId);

    // category, level, star, experience, powerValue, mintTime
    function getHeroInfoByHeroId(uint256 _heroId) public view returns (uint256[] memory) {
        require(_exists(_heroId), "ERC721: operator query for nonexistent token");
        Hero memory hero = heroArr[_heroId];
        uint256[] memory heroInfo = new uint256[](6);
        heroInfo[0] = hero.category;
        heroInfo[1] = hero.level;
        heroInfo[2] = hero.star;
        heroInfo[3] = hero.experience;
        heroInfo[4] = hero.powerValue;
        heroInfo[5] = hero.mintTime;
        return heroInfo;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        _setBaseURI(baseURI_);
    }


    function tokenURI(uint256 _heroId) public view virtual override returns (string memory) {
        require(_exists(_heroId), "ERC721Metadata: URI query for nonexistent token");

        // string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();
        Hero memory hero = heroArr[_heroId];
        return string(abi.encodePacked(base, "/", hero.category.toString(), "_", hero.star.toString(), "/", _heroId.toString()));
    }

    function getHeroIdByAddress(address _owner) public view returns (uint256[] memory heroIds) {
        uint256 length = balanceOf(_owner);
        heroIds = new uint256[](length);
        for (uint256 index = 0; index < length; index++) {
            heroIds[index] = tokenOfOwnerByIndex(_owner, index);
        }
    }

    function mintHero(address _owner, uint256 _category, uint256 _level, uint256 _star, uint256 _experience, uint256 _powerValue) public onlyOwnerOrAccessAddress returns (uint256) {
        return _mintHero(_owner, _category, _level, _star, _experience, _powerValue);
    }

    function updateHero(uint256 _heroId, uint256 _category, uint256 _level, uint256 _star, uint256 _experience, uint256 _powerValue) public onlyOwnerOrAccessAddress returns (bool) {
        require(_exists(_heroId), "ERC721: operator update for nonexistent token");
        Hero memory hero = heroArr[_heroId];
        hero.category = _category;
        hero.level = _level;
        hero.star = _star;
        hero.experience = _experience;
        hero.powerValue = _powerValue;
        heroArr[_heroId] = hero;

        emit UpdateHero(_heroId, _category, _level, _star, _experience, _powerValue);
        return true;
    }

    function burnHero(uint256 _heroId) public onlyOwnerOrAccessAddress returns (bool) {
        require(_exists(_heroId), "ERC721: operator burn for nonexistent token");
        _burn(_heroId);
        emit BurnHero(_heroId);
        return true;
    }

    function _mintHero(address _owner, uint256 _category, uint256 _level, uint256 _star, uint256 _experience, uint256 _powerValue) internal returns (uint256 heroId){
        Hero memory hero = Hero(_category, _level, _star, _experience, _powerValue, block.timestamp);
        heroId = heroArr.length;
        heroArr.push(hero);
        _mint(_owner, heroId);

        emit MintHero(heroId, _owner, _category, _level, _star, _experience, _powerValue);
    }
}

pragma solidity 0.6.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./AccessControl.sol";

contract ExperienceCard is ERC721("ExperienceCard", "ExperienceCard"), AccessControl {

    struct ExperienceCardDefine {
        uint256 level;
        uint256 experience;
        uint256 mintTime;
    }

    ExperienceCardDefine[] public cards;

    constructor() public {
        burnExperienceCard(_mintExperienceCard(msg.sender, 0, 0));
    }

    event MintExperienceCard(uint256 indexed _cardId, address indexed _owner, uint256 _level, uint256 _experience);
    event BurnExperienceCard(uint256 indexed _cardId);

    function getExperienceCardInfoByCardId(uint256 _cardId) public view returns (uint256 level, uint256 experience, uint256 mintTime) {
        require(_exists(_cardId), "ERC721: operator query for nonexistent token");
        ExperienceCardDefine memory card = cards[_cardId];
        level = card.level;
        experience = card.experience;
        mintTime = card.mintTime;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        _setBaseURI(baseURI_);
    }


    function tokenURI(uint256 _cardId) public view virtual override returns (string memory) {
        require(_exists(_cardId), "ERC721Metadata: URI query for nonexistent token");

        // string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();
        ExperienceCardDefine memory card = cards[_cardId];
        return string(abi.encodePacked(base, "/", card.level.toString(), "/", _cardId.toString()));
    }

    function getCardIdsByAddress(address _owner) public view returns (uint256[] memory cardIds) {
        uint256 length = balanceOf(_owner);
        cardIds = new uint256[](length);
        for (uint256 index = 0; index < length; index++) {
            cardIds[index] = tokenOfOwnerByIndex(_owner, index);
        }
    }

    function mintExperienceCard(address _owner, uint256 _level, uint256 _experience) public onlyOwnerOrAccessAddress returns (uint256) {
        return _mintExperienceCard(_owner, _level, _experience);
    }

    function burnExperienceCard(uint256 _cardId) public onlyOwnerOrAccessAddress returns (bool) {
        require(_exists(_cardId), "ERC721: operator burn for nonexistent token");
        _burn(_cardId);
        emit BurnExperienceCard(_cardId);
        return true;
    }

    function _mintExperienceCard(address _owner, uint256 _level, uint256 _experience) internal returns (uint256 cardId){
        ExperienceCardDefine memory card = ExperienceCardDefine(_level, _experience, block.timestamp);
        cardId = cards.length;
        cards.push(card);
        _mint(_owner, cardId);

        emit MintExperienceCard(cardId, _owner, _level, _experience);
    }
}

// // SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AccessControl is Ownable {

    mapping(address => bool) private accessAddress;

    modifier onlyOwnerOrAccessAddress() {
        require(msg.sender == owner() || accessAddress[msg.sender], "Accessible: caller is not the owner or access address");
        _;
    }

    function setAccess(address _address, bool _access) public onlyOwner {
        require(_address != address(0), "access address is not the zero address");
        accessAddress[_address] = _access;
    }
}
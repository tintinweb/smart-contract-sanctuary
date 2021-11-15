//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./interfaces/IHeroNFT.sol";
import "./interfaces/IRandomNumberGenerator.sol";
import "./common/Operatable.sol";

contract HeroNFT is IHeroNFT, ERC721, Operatable {

    mapping(uint => HeroInfo) heroes;
    uint public heroesCount;
    uint public releaseGameDate;

    mapping(uint8 => uint8) public currentHeroRarity;
    mapping(uint8 => uint8) public currentBgRarity;
    mapping(uint8 => uint8) public currentPetRarity;
    mapping(address => mapping(uint => StakingReward)) public userStakingRewards;

    ReleaseHeroCampaign[] public releaseHeroCampaigns;

    address public heroVerseToken;
    address public heroShard;
    address public randomNumberGenerator;
    address public stakingPool;
    uint8[] public allowedMintAmount;
    mapping(uint => uint) public randomNumberByHeroIds;
    bool public useOracleForRandomNumber;

    mapping(uint8 => uint8) heroRarityIdxMax;
    mapping(uint8 => uint8) bgRarityIdxMax;
    mapping(uint8 => uint8) petRarityIdxMax;

    uint8 constant MAX_ELEMENT = 3;
    uint8 constant MAX_RARITY = 5;
    uint8 constant MAX_COIN_SIGNAL = 8;
    uint8 constant MAX_AWAKEN = 10;

    uint8 constant SUMMON_SHARD_COST = 4;
    uint8 constant SUMMON_HER_COST = 80;
    uint8 constant MINT_HER_COST = 100;
    uint8 constant MINT_HER_COST_INCREASE_PERCENT = 5;
    uint constant MINT_HER_COST_INCREASE_DURATION = (1 days);
    uint8 constant AWAKEN_HER_COST = 10;

    uint16[MAX_RARITY + 1] rarityPercents;

    constructor(
        address _heroVerseToken,
        address _heroShard,
        uint16[MAX_RARITY + 1] memory _rarityPercents,
        uint8[MAX_RARITY + 1] memory _heroRarityIdxMax,
        uint8[MAX_RARITY + 1] memory _bgRarityIdxMax,
        uint8[MAX_RARITY + 1] memory _petRarityIdxMax,
        uint _releaseGameDate,
        uint _sellLimit,
        uint _startTime,
        uint _endTime
    ) ERC721("HeroVerseHero", "HERO") {
        uint16 rarityPercent;
        require(_startTime < _endTime, "Start time of campaign must be before End time");
        require(_endTime > block.timestamp, "End time of campaign must be in future");
        for (uint8 i = 0; i < MAX_RARITY + 1; i++) {
            rarityPercent += _rarityPercents[i];
            heroRarityIdxMax[i] = _heroRarityIdxMax[i];
            bgRarityIdxMax[i] = _bgRarityIdxMax[i];
            petRarityIdxMax[i] = _petRarityIdxMax[i];
        }
        require(rarityPercent == 10000, "Total rarity percentage not equal 100.00 %");

        heroVerseToken = _heroVerseToken;
        heroShard = _heroShard;
        rarityPercents = _rarityPercents;
        releaseGameDate = _releaseGameDate;

        releaseHeroCampaigns.push(ReleaseHeroCampaign(_sellLimit, _startTime , _endTime, 0));
    }

    modifier onlyRandomNumberGenerator() {
        require(msg.sender == randomNumberGenerator, "HeroNFT: Not RNG contract");
        _;
    }

    modifier onlyStakingPool() {
        require(msg.sender == stakingPool, "HeroNFT: Not Staking Pool contract");
        _;
    }

    /**
     * @dev Get latest release hero campaign of system
     */
    function getLatestReleaseHeroCampaign() public view returns (uint) {
        return releaseHeroCampaigns.length - 1;
    }

    /**
     * @dev add New Release Hero Campaign
     * @param sellLimit limit hero will be selled for this campaign
     * @param startTime start campaign time
     * @param endTime end campaign time
     */
    function addNewReleaseHeroCampaign(
        uint sellLimit,
        uint startTime,
        uint endTime
    ) external onlyOwner {
        uint latestCampaignId = getLatestReleaseHeroCampaign();
        ReleaseHeroCampaign memory latestCampaign = releaseHeroCampaigns[latestCampaignId];

        require(latestCampaign.endTime < block.timestamp, "There is another incoming campaign");

        releaseHeroCampaigns.push(ReleaseHeroCampaign(sellLimit, startTime , endTime, 0));
        emit NewReleaseHeroCampaignsAdded(latestCampaignId + 1);
    }

    /**
     * @dev Get Release Hero Campaign Detail
     * @param campaignId id of campaign which user want to get info detail
     */
    function getReleaseHeroCampaignDetail(uint campaignId) public view returns (
        uint sellLimit,
        uint startTime,
        uint endTime,
        uint selledAmount
    ) {
        require(campaignId <= getLatestReleaseHeroCampaign(), "KabyHero: invalid version");
        ReleaseHeroCampaign memory campaign = releaseHeroCampaigns[campaignId];
        sellLimit = campaign.sellLimit;
        startTime = campaign.startTime;
        endTime = campaign.endTime;
        selledAmount = campaign.selledAmount;
    }

    /**
     * @dev increase awakenCount of an hero
     * @param heroId id of hero
     */
    function awakening(uint heroId) external override {
        require(heroes[heroId].tokenId == heroId, "HeroNFT: Hero is not created yet");
        require(heroes[heroId].awakenCount <= MAX_AWAKEN, "HeroNFT: AwakenCount is maximum");

        uint awakenCost = getAwakenCost();
        require(IERC20(heroVerseToken).balanceOf(msg.sender) >= awakenCost, "HeroNFT: Don't have enough HER");

        IERC20(heroVerseToken).transferFrom(msg.sender, address(this), awakenCost);
        heroes[heroId].awakenCount++;

        emit Awakening(heroId);
    }

    /**
     * @dev set number amount user can mint for each calling mint hero
     */
    function setAllowedMintAmount(uint8[] memory _allowedMintAmount) external onlyOwner{
        allowedMintAmount = _allowedMintAmount;
    }

    function isContainInAllowedMintAmount(uint256 _x) private view returns(bool){
        uint8[] memory initAmountIndex = allowedMintAmount;
        for(uint i = 0; i < initAmountIndex.length; i++){
            if (initAmountIndex[i] == _x){
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Generate an amount of hero
     */
    function buyBox(uint amount) external override {
        uint latestCampaignId = getLatestReleaseHeroCampaign();
        ReleaseHeroCampaign memory campaign = releaseHeroCampaigns[latestCampaignId];
        require(campaign.startTime < block.timestamp, "The campaign is not start");
        require(campaign.endTime >= block.timestamp, "The campaign is expired");
        require(campaign.selledAmount + amount <= campaign.sellLimit, "Available hero of current campaign is not enough for your request");

        bool isValidAmount = isContainInAllowedMintAmount(amount);
        require(isValidAmount, "HeroNFT: This amount is not allowed");

        uint mintCost = getMintCost(campaign.startTime);
        require(IERC20(heroVerseToken).balanceOf(msg.sender) >= mintCost, "HeroNFT: Don't have enough HER token");

        IERC20(heroVerseToken).transferFrom(msg.sender, address(this), amount * mintCost);

        for (uint i = 0; i < amount; i++) {
            uint heroId = _generateHero(msg.sender, 0, 0, 0, 0);
            releaseHeroCampaigns[latestCampaignId].selledAmount ++;
            emit HeroCreatedViaBuyBox(heroId, msg.sender);
        }
    }

    /**
     * @dev Generate an amount of hero
     */
    function claimStakingReward(uint8 heroRarityPlus, uint8 heroRarityIdxPlus, uint8 bgRarityPlus, uint8 bgRarityIdxPlus, uint stakingPeriod) external override {
        require(heroRarityPlus == 0 || heroRarityIdxPlus == 0 || bgRarityPlus == 0 || bgRarityIdxPlus == 0 || stakingPeriod == 0, "Wrong input");
        require(userStakingRewards[msg.sender][stakingPeriod].rarityPlus > 0, "This reward is not existed");
        require(userStakingRewards[msg.sender][stakingPeriod].rarityPlus >= heroRarityPlus,"Hero rarity reward request is higher than actual reward");
        require(userStakingRewards[msg.sender][stakingPeriod].rarityPlus >= bgRarityPlus,"Background rarity reward request is higher than actual reward");
        require(heroRarityIdxPlus <= heroRarityIdxMax[heroRarityPlus - 1] + 1,"Hero rarity index reward request is not exist");
        require(bgRarityIdxPlus <= bgRarityIdxMax[bgRarityPlus - 1] + 1,"Background rarity index reward request is higher than actual reward");
        require(userStakingRewards[msg.sender][stakingPeriod].isClaimed == false,"Reward has been claimed");

        uint heroId = _generateHero(msg.sender, heroRarityPlus, heroRarityIdxPlus, bgRarityPlus, bgRarityIdxPlus);
        userStakingRewards[msg.sender][stakingPeriod].isClaimed = true;

        emit ClaimStakingReward(msg.sender, heroRarityPlus, heroRarityIdxPlus, bgRarityPlus, bgRarityIdxPlus, stakingPeriod, heroId);
    }

    /**
     * @dev Generate a hero with From Staking Compaign
     */
    function storeStakingReward(address account, uint8 rarityPlus, uint stakingPeriod) external override onlyStakingPool {
        if (userStakingRewards[account][stakingPeriod].rarityPlus > 0){
            if (!userStakingRewards[account][stakingPeriod].isClaimed &&
                    userStakingRewards[account][stakingPeriod].rarityPlus < rarityPlus){
                userStakingRewards[account][stakingPeriod].rarityPlus = rarityPlus;
            }
        } else {
            userStakingRewards[account][stakingPeriod].rarityPlus = rarityPlus;
            userStakingRewards[account][stakingPeriod].isClaimed = false;
        }
    }

    /**
     * @dev Summon a hero with 4 HRS Shard & 80 HER
     */
    function summonHero() external override{
        require(releaseGameDate < block.timestamp, "The game have not been realeased.");

        (uint herCost, uint shardCost) = getSummonCost();
        require(IERC20(heroShard).balanceOf(msg.sender) >= shardCost, "HeroNFT: Don't have enough Hero Shard");
        require(IERC20(heroVerseToken).balanceOf(msg.sender) >= herCost, "HeroNFT: Don't have enough HER Token");

        IERC20(heroShard).transferFrom(msg.sender, address(this), shardCost);
        IERC20(heroVerseToken).transferFrom(msg.sender, address(this), herCost);

        uint heroId = _generateHero(msg.sender, 0, 0, 0, 0);
        emit SummonHero(heroId, msg.sender);
    }

    /**
     * @dev Generate a new hero
     * @param account account is received the hero.
     * @param heroRarityPlus is always 0 excepts calling from claimStakingReward function
     * @param heroRarityIdxPlus is always 0 excepts calling from claimStakingReward function
     * @param bgRarityPlus is always 0 excepts calling from claimStakingReward function
     * @param bgRarityIdxPlus is always 0 excepts calling from claimStakingReward function
     * @return heroId id of hero
     */
    function _generateHero(address account, uint8 heroRarityPlus, uint8 heroRarityIdxPlus, uint8 bgRarityPlus, uint8 bgRarityIdxPlus) internal returns(uint heroId) {
        heroId = ++heroesCount;
        _safeMint(account, heroId);
        if (useOracleForRandomNumber == false) {
            uint256 randomNumberIndex = randomNumberByBlockInfo(heroId);
            _setHeroValueInfo(heroId, randomNumberIndex, heroRarityPlus, heroRarityIdxPlus, bgRarityPlus, bgRarityIdxPlus);
        } else {
            IRandomNumberGenerator(randomNumberGenerator).requestRandomNumber(heroId); // Calculate the finalNumber based on the randomResult generated by ChainLink's fallback
        }
    }

    /**
     * @dev Set value for properties of an hero
     * @param heroId id of hero.
     * @param randomness random number
     * @param heroRarityPlus is always 0 excepts calling from claimStakingReward function
     * @param heroRarityIdxPlus is always 0 excepts calling from claimStakingReward function
     * @param bgRarityPlus is always 0 excepts calling from claimStakingReward function
     * @param bgRarityIdxPlus is always 0 excepts calling from claimStakingReward function
     */
    function _setHeroValueInfo(uint heroId, uint randomness, uint8 heroRarityPlus, uint8 heroRarityIdxPlus, uint8 bgRarityPlus, uint8 bgRarityIdxPlus) private {
        randomNumberByHeroIds[heroId] = randomness;
        uint256 randomResult = randomness % (1000 ** 8);
        uint16[] memory numberArr =  new uint16[](8);

        for (uint i = 0; randomResult != 0; i++){
            numberArr[i] = (i == 0 || i == 1 || i == 2)
                ? uint16(randomResult % 10000)
                : uint16(randomResult % 1000);
            randomResult = randomResult / 1000;
        }

        uint16[MAX_RARITY + 1] memory rarityPercent;
        uint16 totalRarityPercent;
        for (uint i = 0; i < rarityPercents.length; i++) {
            totalRarityPercent += rarityPercents[i];
            rarityPercent[i] = totalRarityPercent;
        }

        if (heroRarityPlus == 0) {
            while (heroRarityPlus < MAX_RARITY && rarityPercent[heroRarityPlus] <= numberArr[0]) {
                heroRarityPlus++;
            }
        } else {
            heroRarityPlus--;
        }

        if (bgRarityPlus == 0) {
            while (bgRarityPlus < MAX_RARITY && rarityPercent[bgRarityPlus] <= numberArr[1]) {
                bgRarityPlus++;
            }
        } else {
            bgRarityPlus--;
        }

        if (heroRarityIdxPlus == 0) {
            heroRarityIdxPlus = uint8(numberArr[3] % (heroRarityIdxMax[heroRarityPlus] + 1));
        } else {
            heroRarityIdxPlus--;
        }

        if (bgRarityIdxPlus == 0) {
            bgRarityIdxPlus = uint8(numberArr[4] % (bgRarityIdxMax[bgRarityPlus] + 1));
        } else {
            bgRarityIdxPlus--;
        }

        uint8 petRarity = 0;
        while (petRarity < MAX_RARITY && rarityPercent[petRarity] <= numberArr[2]) {
            petRarity++;
        }

        heroes[heroId].tokenId = heroId;
        heroes[heroId].element = uint8(numberArr[6] % (MAX_ELEMENT + 1));
        heroes[heroId].coinSignal = uint8(numberArr[7] % (MAX_COIN_SIGNAL + 1));

        heroes[heroId].heroRarity = heroRarityPlus;
        currentHeroRarity[heroRarityPlus] ++;

        heroes[heroId].bgRarity = bgRarityPlus;
        currentBgRarity[bgRarityPlus] ++;

        heroes[heroId].petRarity = petRarity;
        currentPetRarity[petRarity] ++;

        heroes[heroId].heroRarityIdx = heroRarityIdxPlus;
        heroes[heroId].bgRarityIdx = bgRarityIdxPlus;
        heroes[heroId].petRarityIdx = uint8(numberArr[5] % (petRarityIdxMax[petRarity] + 1));

        emit SetHeroValueInfo(heroes[heroId]);
    }

    /**
     * @dev Create a new hero with random stats
     * @param heroId id of hero
     * @param randomness random number generated by RNG
     */
    function createHeroFromRNG(uint heroId, uint randomness) external override onlyRandomNumberGenerator {
        _setHeroValueInfo(heroId, randomness, 0, 0, 0, 0);
    }

    /**
     * @dev Anyone can check hero info by heroId
     * @param heroId id of hero need to check
     * @return heroinfo
     */
    function getHero(uint heroId) external view override returns(HeroInfo memory) {
        return heroes[heroId];
    }

    /**
     * @dev Anyone can check current maximun background rarity index of an background rarity type
     * @param rarity background rarity type (0-5)
     * @return Max index of hero rarity
     */
    function getHeroRarityIdxMax(uint8 rarity) external view override returns(uint8) {
        require(rarity <= MAX_RARITY, "HeroNFT: Rarity is out of config");
        return heroRarityIdxMax[rarity];
    }

    /**
     * @dev Anyone can check maximun background rarity index of an background rarity type
     * @param rarity background rarity type (0-5)
     * @return Max index of background rarity
     */
    function getBgRarityIdxMax(uint8 rarity) external view override returns(uint8) {
        require(rarity <= MAX_RARITY, "HeroNFT: Rarity is out of config");
        return bgRarityIdxMax[rarity];
    }

    /**
     * @dev Anyone can check  maximun pet rarity index of an pet rarity type
     * @param rarity pet rarity type (0-5)
     * @return Max pet of background rarity
     */
    function getPetRarityIdxMax(uint8 rarity) external view override returns(uint8) {
        require(rarity <= MAX_RARITY, "HeroNFT: Rarity is out of config");
        return petRarityIdxMax[rarity];
    }

    /**
     * @dev get cost for mint a hero
     * @return HER token amount need for mint a hero
     */
    function getMintCost(uint mintCostIncreaseDate) public view returns(uint) {
        uint cost = MINT_HER_COST * (10 ** IERC20Metadata(heroVerseToken).decimals());
        if (block.timestamp >= mintCostIncreaseDate) {
            uint timeSinceFeeStarted = block.timestamp - mintCostIncreaseDate;
            uint daysSinceFeeStarted = timeSinceFeeStarted / MINT_HER_COST_INCREASE_DURATION;
            uint costIncreasePercent = MINT_HER_COST_INCREASE_PERCENT * daysSinceFeeStarted;
            cost += cost * costIncreasePercent / 100;
        }
        return cost;
    }

    /**
     * @dev get cost for summon a hero
     * @return herTokenCost  HER token amount need for summon a hero
     * @return heroShardCost HRS token amount need for summon a hero
     */
    function getSummonCost() public view returns(uint herTokenCost, uint heroShardCost) {
        heroShardCost = SUMMON_SHARD_COST * (10 ** IERC20Metadata(heroShard).decimals());
        herTokenCost = SUMMON_HER_COST * (10 ** IERC20Metadata(heroVerseToken).decimals());
    }

    /**
     * @dev get Awaken cost by HER
     * @return Awaken cost in HER amount
     */
    function getAwakenCost() public view returns(uint) {
        return AWAKEN_HER_COST * (10 ** IERC20Metadata(heroVerseToken).decimals());
    }

    /**
     * @dev Owner set new Random Number Generator contract
     * @param _randomNumberGenerator new Random Number Generator contract address
     */
    function setRandomNumberGenerator(address _randomNumberGenerator) external onlyOwner {
        require(_randomNumberGenerator != address(0));
        randomNumberGenerator = _randomNumberGenerator;

        emit UpdateRandomNumberGenerator(randomNumberGenerator);
    }

    /**
     * @dev Owner set new Staking Pool contract
     * @param _stakingPool new Staking Pool contract address
     */
    function setStakingPool(address _stakingPool) external onlyOwner {
        require(_stakingPool != address(0));
        stakingPool = _stakingPool;

        emit UpdateStakingPool(stakingPool);
    }

    /**
     * @dev Operator set maximun hero rarity index
     * @param rarity hero rarity type (0-5)
     * @param value new value for hero background rarity index
     */
    function setHeroRarityIdxMax(uint8 rarity, uint8 value) external onlyOperator override{
        require(rarity <= MAX_RARITY, "HeroNFT: Rarity is out of config");
        require(heroRarityIdxMax[rarity] <= value, "HeroNFT: Only put a greater than current value");
        heroRarityIdxMax[rarity] = value;

        emit UpdateHeroRarityIdxMax(rarity, value);
    }

    /**
     * @dev Operator set maximun background rarity index
     * @param rarity background rarity type (0-5)
     * @param value new value for maximun background rarity index
     */
    function setBgRarityIdxMax(uint8 rarity, uint8 value) external onlyOperator override{
        require(rarity <= MAX_RARITY, "HeroNFT: Rarity is out of config");
        require(bgRarityIdxMax[rarity] <= value, "HeroNFT: Only put a greater than current value");
        bgRarityIdxMax[rarity] = value;

        emit UpdateBgRarityIdxMax(rarity, value);
    }

    /**
     * @dev Owner set maximun pet rarity index
     * @param rarity pet rarity type (0-5)
     * @param value new value for maximun pet rarity Index
     */
    function setPetRarityIdxMax(uint8 rarity, uint8 value) external onlyOperator override{
        require(rarity <= MAX_RARITY, "HeroNFT: Rarity is out of config");
        require(petRarityIdxMax[rarity] <= value, "HeroNFT: Only put a greater than current value");
        petRarityIdxMax[rarity] = value;

        emit UpdatePetRarityIdxMax(rarity, value);
    }

    /**
     * @dev Owner set if using Oracle.
     * @param isUseOracle Use Oracle if true
     */
    function setUseOracle(bool isUseOracle) external onlyOwner{
        useOracleForRandomNumber = isUseOracle;
    }

     /**
     * @dev Random number by block info.
     * @return random value
     */
    function randomNumberByBlockInfo(uint heroId) private view returns(uint256) {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            heroId +
            block.timestamp + block.difficulty +
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / block.timestamp) +
            block.gaslimit +
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / block.timestamp) +
            block.number
        )));

        return seed;
    }

    /**
     * @dev Set Release Game Date
     * @param _releaseGameDate release game date in timestamp
     */
    function setReleaseGameDate(uint _releaseGameDate) external onlyOwner{
        releaseGameDate = _releaseGameDate;
    }

    /**
     * @dev Get User Staking Rewards
     * @param account wallet address of user
     * @param stakingPeriod Period of Staking
     */
    function getUserStakingRewards(address account, uint stakingPeriod) public view returns (StakingReward memory){
        return userStakingRewards[account][stakingPeriod];
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Operatable is Ownable {

    mapping(address => bool) public isOperator;

    event OperatorSetted(address operator, bool status);

    modifier onlyOperator {
        require(isOperator[msg.sender], "Operatble: Not operator");
        _;
    }

    /**
     * @dev Owner set Operator
     * @param operator operator address
     * @param status status is added or removed
     */
    function setOperator(address operator, bool status) external onlyOwner {
        isOperator[operator] = status;

        emit OperatorSetted(operator, status);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IHeroNFT {

    struct HeroInfo {
        uint tokenId;
        uint8 element;

        uint8 heroRarity;
        uint8 heroRarityIdx;

        uint8 bgRarity;
        uint8 bgRarityIdx;

        uint8 petRarity;
        uint8 petRarityIdx;

        uint8 coinSignal;
        uint8 awakenCount;
    }

    struct ReleaseHeroCampaign {
        uint sellLimit;
        uint startTime;
        uint endTime;
        uint selledAmount;
    }

    struct StakingReward {
        uint8 rarityPlus;
        bool isClaimed;
    }

    event NewReleaseHeroCampaignsAdded(uint campaignId);
    event Awakening(uint heroId);
    event HeroCreatedViaBuyBox(uint heroId, address owner);
    event SummonHero(uint heroId, address summoner);
    event SetHeroValueInfo(HeroInfo hero);
    event UpdateRandomNumberGenerator(address newRandomNumberGenerator);
    event UpdateStakingPool(address stakingPool);
    event UpdateHeroRarityIdxMax(uint8 rarity, uint8 value);
    event UpdateBgRarityIdxMax(uint8 rarity, uint8 value);
    event UpdatePetRarityIdxMax(uint8 rarity, uint8 value);
    event ClaimStakingReward(address user, uint8 heroRarityPlus, uint8 heroRarityIdxPlus, uint8 bgRarityPlus, uint8 bgRarityIdxPlus, uint stakingPeriod, uint claimedHeroId);

    /**
     * @notice awakening hero
     */
    function awakening(uint heroId) external;

    /**
     * @notice buy an amount of boxes and generate heroes
     */
    function buyBox(uint amount) external;

    /**
     * @notice claim Staking Reward
     */
    function claimStakingReward(uint8 heroRarityPlus, uint8 heroRarityIdxPlus, uint8 bgRarityPlus, uint8 bgRarityIdxPlus, uint stakingPeriod) external;

    /**
     * @notice store Staking Reward from staking
     */
    function storeStakingReward(address account, uint8 rarityPlus, uint stakingEndTime) external;

    /**
     * @notice summon hero
     */
    function summonHero() external;

    /**
     * @notice create new hero from RNG
     */
    function createHeroFromRNG(uint heroId, uint randomness) external;

    /**
     * @notice get hero info
     */
    function getHero(uint heroId) external view returns(HeroInfo memory);

    /**
     * @notice get Hero Rarity Max
     */
    function getHeroRarityIdxMax(uint8 rarity) external view returns(uint8);

    /**
     * @notice get background Rarity Max
     */
    function getBgRarityIdxMax(uint8 rarity) external view returns(uint8);

    /**
     * @notice get Pet Rarity Max
     */
    function getPetRarityIdxMax(uint8 rarity) external view returns(uint8);

    /**
     * @notice set Hero Rarity Max
     */
    function setHeroRarityIdxMax(uint8 rarity, uint8 value) external;

    /**
     * @notice set background Rarity Max
     */
    function setBgRarityIdxMax(uint8 rarity, uint8 value) external;

    /**
     * @notice set Pet Rarity Max
     */
    function setPetRarityIdxMax(uint8 rarity, uint8 value) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRandomNumberGenerator {
    /**
     *  Request random 
     */
    function requestRandomNumber(uint heroId) external returns (bytes32);
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


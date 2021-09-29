/**
 *Submitted for verification at BscScan.com on 2021-09-29
*/

interface ISharedStruct {

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
}

interface IHeroNFT is ISharedStruct {

    struct RarityConfig {
        uint16 rarityPercent;
        uint8 heroRarityIdxMax;
        uint8 bgRarityIdxMax;
        uint8 petRarityIdxMax;
    }

    event HeroAwakened(uint heroId, uint8 currentAwakenCount);
    event HeroCreated(uint heroId, address owner);
    event HeroVerseTokenUpdated(address newHeroVerseToken);
    event RandomNumberGeneratorUpdated(address newRandomNumberGenerator);
    event HeroRarityIdxMaxUpdated(uint8 rarity, uint8 value);
    event BgRarityIdxMaxUpdated(uint8 rarity, uint8 value);
    event PetRarityIdxMaxUpdated(uint8 rarity, uint8 value);
    event UseOracleUpdated(bool currentUseOracle);
    event MinterStatusUpdated(address account, bool status);
    event AwakenCostUpdated(uint value);
    event AllowFixedHeroIndicatorsWhenMintingUpdated(bool currentAllowFixedHeroIndicatorsWhenMinting);
    event RarityPercentsUpdated(uint16[6] _rarityPercents);
    event MaxAwakenUpdated(uint8 _maxAwaken);
    event MaxCoinSignalUpdated(uint8 _maxCoinSignal);
    /**
     * @notice awakening hero
     */
    function awakening(uint heroId) external;

    /**
     * @notice mint Hero
     */
    function mintHero(address account) external returns(uint);

    /**
     * @notice mint Hero with fixed info
     */
    function mintHero(address account, HeroInfo memory info) external returns(uint);

    /**
     * @notice create new hero from RNG
     */
    function createHeroFromRNG(uint heroId, uint randomness) external;

    /**
     * @notice get hero count
     */
    function heroesCount() external view returns(uint);

    /**
     * @notice get hero info
     */
    function getHero(uint heroId) external view returns(HeroInfo memory hero, address heroOwner);

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
     * @notice get current percent of a rarity
     */
    function getRarityPercent(uint8 rarity) external view returns(uint16);
}

contract Test {
    function claimStakingReward(IHeroNFT lastVersion, IHeroNFT currentVersion, uint targetHeroId) external {
        
    }
}
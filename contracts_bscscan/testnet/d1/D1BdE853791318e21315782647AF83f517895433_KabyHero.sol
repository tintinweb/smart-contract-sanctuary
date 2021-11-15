//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "./interfaces/IKabyHero.sol";
import "./interfaces/IGem.sol";
import "./utils/AcceptedToken.sol";
import "./interfaces/IRandomNumberGenerator.sol";
import "./interfaces/ISummonStakingPool.sol";

contract KabyHero is IKabyHero, ERC721, AcceptedToken, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    uint private constant BPS = 10000;

    IGem public gemContract;
    IRandomNumberGenerator public randomGenerator;
    ISummonStakingPool public summonStakingPool;

    address public kabyToken;
    address public stakingPoolAddress;
     
    uint public marketFeeInBps = 22;
    uint public serviceFeeInToken = 1e20;
    uint public maxStar = 10;
    uint public maxBuyPerReq = 10;
    string private _uri;
    bool public useOracle;

    Version[] public versions;
    mapping(uint => uint) public herosOnSale;
    mapping(uint => mapping(address => uint)) public herosWithOffers;
    mapping(address => bool) public minters;
    mapping(uint256 => uint256) private requestRandom;
    mapping(address => uint256) public amountClaimed;

    Hero[] private _heros;

    uint[] private starIndex = new uint[](10);

    constructor(
        address _kabyToken,
        IGem gemAddress,
        IERC20 tokenAddress,
        string memory baseURI,
        uint maxSupply,
        uint maxForSell,
        uint salePrice,
        uint startTime,
        string memory provenance,
        address _randomGenerator
    ) ERC721("KabyHero", "HERO") AcceptedToken(tokenAddress)
    {
        gemContract = gemAddress;
        _uri = baseURI;
        versions.push(Version(0, 0, maxSupply, maxForSell, salePrice, startTime, provenance, true));
        kabyToken = _kabyToken;
        randomGenerator = IRandomNumberGenerator(_randomGenerator);
    }

    modifier onlyHeroOwner(uint heroId) {
        require(ownerOf(heroId) == msg.sender, "KabyHero: not hero owner");
        _;
    }
    
    modifier onlyStakingPool() {
        require(getStakingPool() == msg.sender, "KabyHero: not Staking pool");
        _;
    }

    modifier onlyRandomNumberGenerator() {
        require(address(randomGenerator) == msg.sender, "KabyHero: not random number generator");
        _;
    }

    modifier onlyMinter() {
        require(minters[msg.sender], "KabyHero: not minter");
        _;
    }

    /**
     * @dev Owner set value for starIndex which is an array containing percent values for each star hero
     * @param _starIndex array of new percent values
     */
    function inititiate(
        uint[] memory _starIndex
    ) external onlyOwner {
        require(_starIndex.length == maxStar, "KabyHero: invalid value");
        uint totalRate;
        for(uint i = 0; i < _starIndex.length; i++){
            totalRate += _starIndex[i];
            starIndex[i] = totalRate;
        }
        require(totalRate == 100, "KabyHero: invalid star rate");
    }
    
    /**
     * @dev Owner set SummonStakingPool contract
     * @param _summonStakingPool new summonStakingPool contract address
     */
    function setSummonStakingPool(address _summonStakingPool) external onlyOwner {
        require(_summonStakingPool != address(0));
        summonStakingPool = ISummonStakingPool(_summonStakingPool);
    }
    
    /**
     * @dev Owner add address as minter.
     * @param minter new minter address can mint hero
     */
    function addMinterAdress(address minter) external onlyOwner {
        minters[minter] = true;
    }

    /**
     * @dev Owner remove minter from list minters.
     * @param minter minter address which owner want to remove
     */
    function removeMinterAdress(address minter) external onlyOwner {
        minters[minter] = false;
    }

    /**
     * @dev Owner set type random star that contract use.
     * @param isUseOracle Oracle set true, contract use the chainlink vrf random mechanism
     */
    function setUseOracle(bool isUseOracle) external onlyOwner{
        useOracle = isUseOracle;
    }
    
    /**
     * @dev Owner set value for useSummonStaking
     * @param isUseSummonStaking bool value, set it true if want KabyHero contract to use condition in SummonStakingPool for execute claim()
     */
    function setUseSummonStaking(uint versionId, bool isUseSummonStaking) external onlyOwner{
        require(versionId <= getLatestVersion(), "KabyHero: invalid version");
        Version storage version = versions[versionId];
        version.useSummonStaking = isUseSummonStaking;
    }
    
    /**
     * @dev Owner set new StakingPool contract
     * @param _stakingPoolAddress new StakingPool contract address
     */
    function setStakingPoolContract(address _stakingPoolAddress) external onlyOwner {
        require(_stakingPoolAddress != address(0));
        stakingPoolAddress = _stakingPoolAddress;
    }

    /**
     * @dev Owner set new gem contract
     * @param gemAddress new gem contract address
     */
    function setGemContract(IGem gemAddress) external onlyOwner {
        require(address(gemAddress) != address(0));
        gemContract = gemAddress;
    }

    /**
     * @dev Owner set new max star for hero
     * @param newMaxStar new max star of hero
     */
    function setMaxStar(uint newMaxStar) external onlyOwner {
        require(newMaxStar> maxStar);
        maxStar = newMaxStar;
    }
    
    /**
     * @dev Owner set new max hero can buy per request
     * @param newMaxBuyPerReq new max hero per request
     */
    function setMaxBuyPerReq(uint newMaxBuyPerReq) external onlyOwner {
        require(newMaxBuyPerReq > 0 && newMaxBuyPerReq <= 50);
        maxBuyPerReq = newMaxBuyPerReq;
    }

    /**
     * @dev Owner set new market fee
     * @param marketFee new market fee in Bps
     */
    function setMarketFeeInBps(uint marketFee) external onlyOwner {
        require(marketFee <= BPS);
        marketFeeInBps = marketFee;
    }

    /**
     * @dev Owner set new service fee
     * @param value new service fee in token
     */
    function setServiceFee(uint value) external onlyOwner {
        serviceFeeInToken = value;
    }

    /**
     * @dev Owner set new baseURI
     * @param baseURI prefix to link to hero details
     */
    function setBaseURI(string memory baseURI) external onlyOwner {
        _uri = baseURI;
    }

    /**
     * @dev Add new version with new configs
     * @param maxSupply the maximum amount of hero can be created in this version 
     * @param maxForSell  the maximum amount of hero can be sold in version
     * @param salePrice initial price per hero in this version
     * @param startTime time to start sale heros in this version
     * @param provenance provenance of the heroes in this version
     * @param isUseSummonStaking bool value, set it true if want KabyHero contract to use condition in SummonStakingPool for execute claim()
     */
    function addNewVersion(
        uint maxSupply,
        uint maxForSell,
        uint salePrice,
        uint startTime,
        string memory provenance,
        bool isUseSummonStaking
    ) external onlyOwner {
        uint latestVersionId = getLatestVersion();
        Version memory latestVersion = versions[latestVersionId];

        require(latestVersion.currentSell + latestVersion.currentReserve == latestVersion.maxSupply);

        versions.push(Version(0, 0, maxSupply, maxForSell, salePrice, startTime, provenance, isUseSummonStaking));
        emit NewVersionAdded(latestVersionId + 1);
    }

    /**
     * @dev User request to claim hero
     * @param versionId id of version 
     * @param amount amount of hero want to claim
     */
    function claimHero(uint versionId, uint amount) external override {
        Version storage version = versions[versionId];
        
        require(amount > 0 && amount <= maxBuyPerReq, "KabyHero: amount out of range");
        require(block.timestamp >= version.startTime, "KabyHero: Sale has not started");
        require(version.currentSell + amount <= version.maxForSell, "KabyHero: sold out");

        for (uint i = 0; i < amount; i++) {
            uint heroId = _createHero(msg.sender);
            _safeMint(msg.sender, heroId);
        }
        
        if(version.useSummonStaking == true){
            require(amountClaimed[msg.sender] + amount <= summonStakingPool.getMaxAmountSummon(msg.sender), "KabyHero: invalid amount");
            amountClaimed[msg.sender] += amount;
        }

        version.currentSell += amount;

        bool isSuccess = IERC20(kabyToken).transferFrom(msg.sender, owner(), version.salePrice * amount);
        require(isSuccess);
    }
    
    /**
     * @dev Minter request to mint hero to specific account
     * @param versionId id of version 
     * @param amount amount of hero want to mint
     * @param account address of user will receive 
     */
    function mintHero(uint versionId, uint amount, address account) external onlyMinter override {
        Version storage version = versions[versionId];

        require(amount > 0 && amount <= 50, "KabyHero: amount out of range");
        require(block.timestamp >= version.startTime, "KabyHero: Sale has not started");
        require(amount + version.currentReserve + version.currentSell <= version.maxSupply, "KabyHero: sold out, cannot mint");

        for (uint i = 0; i < amount; i++) {
            uint heroId = _createHero(account);
            _safeMint(account, heroId);
        }

        version.currentReserve += amount;
    }

    /**
     * @dev Owner equips items to their hero
     * @param heroId id of hero what will be equipped
     * @param itemIds array of ids of items which equip to the hero
     */
    function equipItems(uint heroId, uint[] memory itemIds) external override onlyHeroOwner(heroId) {
        _setHeroGem(heroId, itemIds, false);

        gemContract.putItemsIntoStorage(msg.sender, itemIds);

        emit ItemsEquipped(heroId, itemIds);
    }

    /**
     * @dev Owner removes items from their hero
     * @param heroId id of hero which will be unequipped
     * @param itemIds array of ids of items which unequip from the hero
     */
    function removeItems(uint heroId, uint[] memory itemIds) external override onlyHeroOwner(heroId) {
        _setHeroGem(heroId, itemIds, true);

        gemContract.returnItems(msg.sender, itemIds);

        emit ItemsUnequipped(heroId, itemIds);
    }

    /**
     * @dev Owner burns a hero
     * @param heroId id of hero which will be burned
     */
    function sacrificeHero(uint heroId) external override nonReentrant onlyHeroOwner(heroId) {
        _burn(heroId);
    }

    /**
     * @dev Owner lists a hero on sale.
     * @param heroId id of hero which will be listed
     * @param price price of hero want to sell
     */
    function list(uint heroId, uint price) external override onlyHeroOwner(heroId) {
        require(price > 0, "KabyHero: price is zero");

        herosOnSale[heroId] = price;

        emit HeroListed(heroId, price);
    }

    /**
     * @dev Owner delists a hero is being on sale.
     * @param heroId id of hero which will be delisted
     */
    function delist(uint heroId) external override onlyHeroOwner(heroId) {
        require(herosOnSale[heroId] > 0, "KabyHero: not listed");

        herosOnSale[heroId] = 0;

        emit HeroDelisted(heroId);
    }

    /**
     * @dev Buyer buy a hero is being on sale.
     * @param heroId id of hero which buyer want to buy 
     */
    function buy(uint heroId) external override nonReentrant {
        uint price = herosOnSale[heroId];
        address seller = ownerOf(heroId);
        address buyer = msg.sender;

        require(price > 0, "KabyHero: not on sale");
        require(buyer != seller, "KabyHero: cannot buy your own Hero");

        bool isSuccess = IERC20(kabyToken).transferFrom(buyer, address(this), price);
        require(isSuccess);
        
        _makeTransaction(heroId, buyer, seller, price);

        emit HeroBought(heroId, buyer, seller, price);
    }

    /**
     * @dev Buyer gives offer for a hero.
     * @param heroId id of hero which buyer want to offer
     * @param offerValue value of hero which buyer want to offer
     */
    function offer(uint heroId, uint offerValue) external override nonReentrant {
        address buyer = msg.sender;
        uint currentOffer = herosWithOffers[heroId][buyer];
        bool needRefund = offerValue < currentOffer;
        uint requiredValue = needRefund ? 0 : offerValue - currentOffer;

        require(buyer != ownerOf(heroId), "KabyHero: owner cannot offer");
        require(offerValue != currentOffer, "KabyHero: same offer");

        if (requiredValue > 0) {
            bool offerSuccess = IERC20(kabyToken).transferFrom(buyer, address(this), offerValue);
            require(offerSuccess);
        }
        herosWithOffers[heroId][buyer] = offerValue;

        if (needRefund) {
            uint returnedValue = currentOffer - offerValue;

            bool returnSuccess = IERC20(kabyToken).transfer( buyer, returnedValue);
            require(returnSuccess);
        }

        emit HeroOffered(heroId, buyer, offerValue);
    }

    /**
     * @dev Owner take an offer to sell their hero.
     * @param heroId id of hero which owner want to sell
     * @param buyer address of buyer who offerd for the hero
     * @param minPrice min price of the hero, can less than or equal to 'offerValue' when make offer before
     */
    function takeOffer(
        uint heroId,
        address buyer,
        uint minPrice
    ) external override nonReentrant onlyHeroOwner(heroId) {
        uint offeredValue = herosWithOffers[heroId][buyer];
        address seller = msg.sender;

        require(offeredValue > 0, "KabyHero: no offer found");
        require(offeredValue >= minPrice, "KabyHero: less than min price");
        require(buyer != seller, "KabyHero: cannot buy your own Hero");

        herosWithOffers[heroId][buyer] = 0;

        _makeTransaction(heroId, buyer, seller, offeredValue);

        emit HeroBought(heroId, buyer, seller, offeredValue);
    }

    /**
     * @dev Buyer cancel offer for a hero which offered before.
     * @param heroId id of hero which buyer want to cancel offer
     */
    function cancelOffer(uint heroId) external override nonReentrant {
        address sender = msg.sender;
        uint offerValue = herosWithOffers[heroId][sender];

        require(offerValue > 0, "KabyHero: no offer found");

        herosWithOffers[heroId][sender] = 0;

        bool isSuccess = IERC20(kabyToken).transfer(sender, offerValue);
        require(isSuccess);

        emit HeroOfferCanceled(heroId, sender);
    }

    /**
     * @dev Upgrade star for hero
     * @param heroId id of hero which will be upgraded
     * @param amount amount star to upgrade
     */
    function upgradeStar(uint heroId, uint amount) external override onlyStakingPool {
        Hero storage hero = _heros[heroId];
        uint newStar = hero.star + amount;

        require(amount > 0);
        require(newStar <= maxStar, "KabyHero: max Star reached");

        hero.star = newStar;

        emit HeroStarUpgraded(heroId, newStar, amount);
    }

    /**
     * @dev Get the hero to see detail info.
     * @param heroId id of hero which user want to get detail info
     * @return star return current star of hero.
     * @return gem return detail info of hero. Current is a array has gem id values 
     */
    function getHero(uint heroId) external view override returns (
        uint star,
        uint[5] memory gem
    ) {
        Hero memory hero = _heros[heroId];
        star = hero.star;
        gem = [
            hero.gem1,
            hero.gem2,
            hero.gem3,
            hero.gem4,
            hero.gem5
        ];
    }

    /**
     * @dev Get current stakingPoolAddress
     */
    function getStakingPool() private view returns (address) {
        return stakingPoolAddress;
    }
    
    /**
     * @dev get current star of given hero
     * @param heroId id of hero which user want to get current star
     */
    function getHeroStar(uint heroId) external view override returns (uint) {
        return _heros[heroId].star;
    }

    /**
     * @dev Get latest version of system
     */
    function getLatestVersion() public view returns (uint) {
        return versions.length - 1;
    }

    /**
     * @dev Get amount of total heros are supplied
     */
    function totalSupply() external view returns (uint) {
        return _heros.length;
    }

    /**
     * @dev Get current uri
     */
    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    /**
     * @dev Execute trade a hero
     * @param heroId id of hero which will be trade
     * @param buyer address of buyer
     * @param seller address of seller
     * @param price price of the hero
     */
    function _makeTransaction(uint heroId, address buyer, address seller, uint price) private {
        //Hero storage Hero = _heros[heroId];
        uint marketFee = price * marketFeeInBps / BPS;

        herosOnSale[heroId] = 0;

        bool transferToSeller = IERC20(kabyToken).transfer( seller, price - marketFee);
        require(transferToSeller);

        bool transferToTreasury = IERC20(kabyToken).transfer( owner(), marketFee);
        require(transferToTreasury);

        _transfer(seller, buyer, heroId);
    }

    /**
     * @dev Owner set new randomGenerator contract
     * @param randomAddress new randomGenerator contract address
     */
    function setRandomGenerator(IRandomNumberGenerator randomAddress) external onlyOwner {
        require(address(randomAddress) != address(0));
        randomGenerator = randomAddress;
        emit UpdateRandomGenerator(address(randomAddress));
    }

    /**
     * @dev Callable by random generator to set random star for hero
     * @param heroId id of hero which user want to set random star
     * @param randomness random number is returned from chainlink vrf random
     */
    function setRandomStar(uint heroId, uint randomness) external override onlyRandomNumberGenerator {
        Hero storage hero = _heros[heroId];
        uint randomStarIndex = randomness % 100;

        uint star = 1;
        while(star < 10 && starIndex[star-1] <= randomStarIndex){
            star++;
        }
        hero.star = star;
        emit SetStar(heroId, star, ownerOf(heroId));
    }
    

    /**
     * @dev Create a new hero
     * @param ownerOfHero owner of hero
     * @return heroId id of hero was just created
     */
    function _createHero(address ownerOfHero) private returns (uint heroId) {
        _heros.push(Hero(0, 0, 0, 0, 0, 0));
        heroId = _heros.length - 1;
        uint star = randomStar(heroId);
        if (star > 0) {
            _heros[heroId].star = star;
            emit SetStar(heroId, star, ownerOfHero);
        }
        emit HeroCreated(heroId, star, ownerOfHero);
    }
    
    /**
     * @dev Random star for create a new hero
     * @return returnStar star of new hero will be created
     */
    function randomStar(uint heroId) private returns (uint256 returnStar){
        if (useOracle == false){
            uint randomStarIndex = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, heroId))) % 100;
            uint star = 1;
            while(star < 10 && starIndex[star-1] <= randomStarIndex){
                star++;
            }
            return star;
        } else {
            randomGenerator.requestRandomNumberForStar(heroId); // Calculate the finalNumber based on the randomResult generated by ChainLink's fallback
        }
    }

    /**
     * @dev User equip/unequip gems to/from their hero
     * @param heroId id of hero
     * @param itemIds array of item id values
     * @param isRemove bool value, true if user want to unquip items and false to equip items 
     */
    function _setHeroGem(uint heroId, uint[] memory itemIds, bool isRemove) private {
        require(herosOnSale[heroId] == 0, "KabyHero: cannot change items while on sale");
        require(itemIds.length > 0, "KabyHero: no item");

        Hero storage hero = _heros[heroId];

        if (isRemove == false) {
            for (uint i = 0; i < itemIds.length; i++) {
                uint itemId = itemIds[i];

                require(itemId != 0, "KabyHero: invalid itemId");
                if (hero.gem1 == 0) {
                    hero.gem1 = itemId;
                } else if (hero.gem2 == 0) {
                    hero.gem2 = itemId;
                } else if (hero.gem3 == 0) {
                    hero.gem3 = itemId;
                } else if (hero.gem4 == 0) {
                    hero.gem4 = itemId;
                } else if (hero.gem5 == 0) {
                    hero.gem5 = itemId;
                } else {
                    require(false, "KabyHero: invalid space");
                }
            }
        } else {
            for (uint i = 0; i < itemIds.length; i++) {
                uint itemId = itemIds[i];

                require(itemId != 0, "KabyHero: invalid itemId");
                if (hero.gem1 == itemId) {
                    hero.gem1 = 0;
                } else if (hero.gem2 == itemId) {
                    hero.gem2 = 0;
                } else if (hero.gem3 == itemId) {
                    hero.gem3 = 0;
                } else if (hero.gem4 == itemId) {
                    hero.gem4 = 0;
                } else if (hero.gem5 == itemId) {
                    hero.gem5 = 0;
                } else {
                    require(false, "KabyHero: invalid item for remove");
                }
            }
        }
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGem {
    enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY, MYTHICAL }

    struct Item {
        string name;
        uint16 maxSupply;
        uint16 minted;
        uint16 burnt;
        uint8 tier;
        uint8 upgradeAmount;
        Rarity rarity;
    }

    event ItemCreated(uint indexed itemId, string name, uint16 maxSupply, Rarity rarity);
    event ItemUpgradable(uint indexed itemId, uint indexed nextTierItemId, uint8 upgradeAmount);

    /**
     * @notice Create an item.
     */
    function createItem(string memory name, uint16 maxSupply, Rarity rarity) external;

    /**
     * @notice Add next tier item to existing one.
     */
    function addNextTierItem(uint itemId, uint8 upgradeAmount) external;

    /**
     * @notice Burns the same items to upgrade its tier.
     *
     * Requirements:
     * - sufficient token balance.
     * - Item must have its next tier.
     * - Sender's balance must have at least `upgradeAmount`
     */
    function upgradeItem(uint itemId) external;

    /**
     * @notice Pays some fee to get random items.
     */
    function rollGemGacha(uint vendorId, uint amount) external;

    /**
     * @notice Mints items and returns true if it's run out of stock.
     */
    function mint(address account, uint itemId, uint16 amount) external returns (bool);

    /**
     * @notice Burns ERC1155 gem since it is equipped to the hero.
     */
    function putItemsIntoStorage(address account, uint[] memory itemIds) external;

    /**
     * @notice Returns ERC1155 gem back to the owner.
     */
    function returnItems(address account, uint[] memory itemIds) external;

    /**
     * @notice Gets item information.
     */
    function getItem(uint itemId) external view returns (Item memory item);

    /**
     * @notice Check if item is out of stock.
     */
    function isOutOfStock(uint itemId, uint16 amount) external view returns (bool);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IKabyHero {
    struct Hero {
        uint star;
        uint gem1;
        uint gem2;
        uint gem3;
        uint gem4;
        uint gem5;
    }

    struct Version {
        uint currentSell;
        uint currentReserve;
        uint maxSupply;
        uint maxForSell;
        uint salePrice;
        uint startTime;
        string provenance; // This is the provenance record of all Hero artworks in existence.
        bool useSummonStaking;
    }

    event HeroCreated(uint indexed heroId, uint star, address ownerOfHero);
    event HeroListed(uint indexed heroId, uint price);
    event HeroDelisted(uint indexed heroId);
    event HeroStarUpgraded(uint indexed heroId, uint newStar, uint amount);
    event HeroBought(uint indexed heroId, address buyer, address seller, uint price);
    event HeroOffered(uint indexed heroId, address buyer, uint price);
    event HeroOfferCanceled(uint indexed heroId, address buyer);
    event HeroPriceIncreased(uint indexed heroId, uint floorPrice, uint increasedAmount);
    event ItemsEquipped(uint indexed heroId, uint[] itemIds);
    event ItemsUnequipped(uint indexed heroId, uint[] itemIds);
    event NewVersionAdded(uint versionId);
    event UpdateRandomGenerator(address newRandomGenerator);
    event SetStar(uint indexed heroId, uint star, address ownerOfHero);

    /**
     * @notice Claims Heros when it's on presale phase.
     */
    function claimHero(uint versionId, uint amount) external;

    /**
     * @notice Upgrade star for hero
     */
    function upgradeStar(uint heroId, uint amount) external;

    /**
     * @notice Mint Heros from Minter to user.
     */
    function mintHero(uint versionId, uint amount, address account) external;

    /**
     * @notice Owner equips items to their Hero by burning ERC1155 Gem NFTs.
     *
     * Requirements:
     * - caller must be owner of the Hero.
     */
    function equipItems(uint heroId, uint[] memory itemIds) external;

    /**
     * @notice Owner removes items from their Hero. ERC1155 Gem NFTs are minted back to the owner.
     *
     * Requirements:
     * - caller must be owner of the Hero.
     */
    function removeItems(uint heroId, uint[] memory itemIds) external;

    /**
     * @notice Burns a Hero `.
     *
     * - Not financial advice: DONT DO THAT.
     * - Remember to remove all items before calling this function.
     */
    function sacrificeHero(uint heroId) external;

    /**
     * @notice Lists a Hero on sale.
     *
     * Requirements:
     * - `price` cannot be under Hero's `floorPrice`.
     * - Caller must be the owner of the Hero.
     */
    function list(uint heroId, uint price) external;

    /**
     * @notice Delist a Hero on sale.
     */
    function delist(uint heroId) external;

    /**
     * @notice Instant buy a specific Hero on sale.
     *
     * Requirements:
     * - Target Hero must be currently on sale.
     * - Sent value must be exact the same as current listing price.
     */
    function buy(uint heroId) external;

    /**
     * @notice Gives offer for a Hero.
     *
     * Requirements:
     * - Owner cannot offer.
     */
    function offer(uint heroId, uint offerValue) external;

    /**
     * @notice Owner take an offer to sell their Hero.
     *
     * Requirements:
     * - Cannot take offer under Hero's `floorPrice`.
     * - Offer value must be at least equal to `minPrice`.
     */
    function takeOffer(uint heroId, address offerAddr, uint minPrice) external;

    /**
     * @notice Cancels an offer for a specific Hero.
     */
    function cancelOffer(uint heroId) external;

    /**
     * @notice Finalizes the battle aftermath of 2 Heros.
     */
    // function finalizeDuelResult(uint winningheroId, uint losingheroId, uint penaltyInBps) external;

    /**
     * @notice Gets Hero information.
     */
    function getHero(uint heroId) external view returns (
        uint star,
        uint[5] memory gem
    );
    
     /**
     * @notice Gets current star of given hero.
     */
    function getHeroStar(uint heroId) external view returns (uint);

    /**
     * @notice Set random star
     */
    function setRandomStar(uint heroId, uint randomness) external;
}

pragma solidity ^0.8.0;

interface IRandomNumberGenerator {
    /**
     *  Request random for hero star
     */
    function requestRandomNumberForStar(uint heroId) external returns (bytes32);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISummonStakingPool {
    event StakedForBuy(address indexed account, uint amount, uint lockedTime);
    event UnstakedFromBuy(address indexed account, uint amount);
    event ClaimedFromBuy(address indexed account, uint reward);

    struct StakingForBuyData {
        uint balance;
        uint APY;
        uint lastUpdatedTime;
        uint lockedTime;
        uint reward;
    }

    /**
     * @notice Stake KABY token for buy hero
     */
    function stakeForBuyHero(uint amount) external;

    /**
     * @notice Unstake KABY token from a hero.
     */
    function unstake() external;

    /**
     * @notice Gets status of upgrade star and KABY earned by a hero so far.
     */
    function earned(address account) external view returns (uint tokenEarned);

    /**
     * @notice Gets total KABY staked of a Hero.
     */
    function balanceOf(address account) external view returns (uint);
    
    /**
     * @notice Gets max amount of hero can buy depend on amount of kabyToken staked
     */
    function getMaxAmountSummon(address account) external view returns (uint);

    /**
     * @notice Gets rewards depend on amount of kabyToken staked
     */
    function getStakingReward(address account) external view returns (uint);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./PermissionGroup.sol";

contract AcceptedToken is PermissionGroup {
    using SafeERC20 for IERC20;

    // Token to be used in the ecosystem.
    IERC20 public acceptedToken;

    constructor(IERC20 tokenAddress) {
        acceptedToken = tokenAddress;
    }

    modifier collectTokenAsFee(uint amount, address destAddr) {
        require(acceptedToken.balanceOf(msg.sender) >= amount, "AcceptedToken: insufficient token balance");
        _;
        acceptedToken.safeTransferFrom(msg.sender, destAddr, amount);
    }

    /**
     * @dev Sets accepted token using in the ecosystem.
     */
    function setAcceptedTokenContract(IERC20 tokenAddr) external onlyOwner {
        require(address(tokenAddr) != address(0));
        acceptedToken = tokenAddr;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract PermissionGroup is Ownable {
    // List of authorized address to perform some restricted actions
    mapping(address => bool) public operators;

    modifier onlyOperator() {
        require(operators[msg.sender], "PermissionGroup: not operator");
        _;
    }

    /**
     * @notice Adds an address as operator.
     */
    function addOperator(address operator) external onlyOwner {
        operators[operator] = true;
    }

    /**
    * @notice Removes an address as operator.
    */
    function removeOperator(address operator) external onlyOwner {
        operators[operator] = false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    internal
    virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 constant private USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(
    bytes32 _keyHash,
    uint256 _fee
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(
    address _vrfCoordinator,
    address _link
  ) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    external
  {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  )
    internal
    pure
    returns (
      uint256
    )
  {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash,
    uint256 _vRFInputSeed
  )
    internal
    pure
    returns (
      bytes32
    )
  {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

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
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
                return retval == IERC721Receiver(to).onERC721Received.selector;
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

/*
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        mapping(bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

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


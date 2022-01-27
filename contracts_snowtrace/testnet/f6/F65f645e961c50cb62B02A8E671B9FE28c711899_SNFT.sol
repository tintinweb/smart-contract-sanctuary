// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

import './GRBStaker.sol';

interface IVRFProvider {
    function getRandom() external returns (uint256);
    function requestRandom() external returns (bytes32);
}

contract SNFT is ERC1155, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    IERC20 public GRBtoken;
    IStaker public staker;
    IVRFProvider public vrf;

    enum ShipType {COMMANDSHIP, BATTLESHIP, MINER, SCOUT, RANDOM}
    enum BoosterRewardType {AVATAR, SHIP, LAND, INVENTORY, CURRENCY, UPGRADE}
    enum ExplorationType {NOTHING, MINERAL, ENCOUNTER}
    enum EncounterType {ABONDONED, AMBUSH, STORM}

    uint256 public maxFleetSize = 4;
    uint256 public initialInventorySlot = 30;
    uint256 public initialRefineryProductionPerSecond = 0.00027 ether; 
    uint256 public initialRefineryConsumptionPerSecond = 0.00054 ether;
    uint256 public initialFuelAmount = 5;
    uint256 public initialMineralAmount = 5 ether;
    uint256 public secondsPerDistance = 18000; //5 hours per distance per speed
    uint256 public secondsPerMining = 18000; //5 hours per 1/miningspeed
    uint256 public upgradeShipStatCrystalCost = 0.5 ether;
    uint256 public upgradeRefineryCrystalCost = 1 ether;
    uint256 public buyFuelCrystalCost = 0.3 ether;
    uint256 public repairCrystalCost = 0.01 ether;
    uint256 public fuelPerDistance = 2;

    uint256 public boosterPackPriceGRB = 1 ether;
    uint256 public priceGRBfromAVAX = 100;

    mapping(address => bool) public userInitialized;
    mapping(address => UserRefinery) public userRefinery; 
    mapping(address => uint256[]) public userFleet;
    mapping(address => uint256[]) public userShips;
    mapping(address => UserData) public userData;
    mapping(address => ExplorationStatus) public userExplorationStatus;
    mapping(uint256 => bool) public shipIsOnFleet;
    mapping(uint256 => uint256) public shipIndexOnFleet;

    struct UserData {
        uint256 inventorySlot;
        uint256 seed;
    }

    struct ExplorationStatus {
        uint256 exploreCompleteTime;
        uint256 currentExplorationDistance;
        uint256 damageTaken;
        uint256 mineralsFound;
        ExplorationType currentExplorationType;
        EncounterType currentEncounterType;
        bool currentMissionFailed;
        bool fleetOnExplore;
    }

    struct UserRefinery {
        uint256 waitingToClaim;
        uint256 productionPerSecond;
        uint256 consumePerSecond;
        uint256 lastUpdateTime;
    }

    struct ShipTypeStats {
        uint256 hpMin;
        uint256 hpMax;
        uint256 attackMin;
        uint256 attackMax;
        uint256 miningSpeedMin;
        uint256 miningSpeedMax;
        uint256 travelSpeedMin;
        uint256 travelSpeedMax;
    }

    mapping(ShipType => uint256) public shipTypeSkinCount;
    mapping(ShipType => ShipTypeStats) public shipTypeStats;

    struct SpaceshipData {
        uint skin;
        uint shipType;
        uint256 hp;
        uint256 attack;
        uint256 miningSpeed;
        uint256 travelSpeed;
    }

    struct SpaceshipStats {
        uint256 hp;
        uint256 attack;
        uint256 miningSpeed;
        uint256 travelSpeed;
    }
    SpaceshipStats public freeCommandshipStats = SpaceshipStats(25, 5, 5, 5);
    mapping(uint => SpaceshipData) public spaceshipData;
    mapping(uint => SpaceshipStats) public upgradeStats;
    
    mapping(bytes32 => uint8) requestToType;

    event ShipCreated(address indexed user, uint256 tokenId, uint256 shiptype, uint256 skin, uint256 hp, uint256 attack, uint256 miningSpeed, uint256 travelSpeed);
    event AvatarCreated(address indexed user, uint256 tokenId, uint256 skin);
    event LandCreated(address indexed user, uint256 tokenId, uint256 skin);
    event BoosterReward(address indexed user, uint8 rewardType, uint256 amount, uint256 timestamp);
    event ShipUpgraded(address indexed user, uint256 upgradeTokenId, uint256 shipTokenId, uint256 timestamp, uint256 hp, uint256 attack, uint256 miningSpeed, uint256 travelSpeed);
    event RefineryUpgraded(address indexed user, uint256 newProduction, uint256 timestamp);
    event AddShipToFleet(address indexed user, uint256 shipTokenId);
    event RemoveShipFromFleet(address indexed user, uint256 shipTokenId);

    uint256 constant AVATAR_SKIN_COUNT = 8;
    uint256 constant LAND_SKIN_COUNT = 10;
    uint256 constant UPGRADE_TYPE_COUNT = 12;
    //CONSUMABLE and FT ids
    uint256 constant MINERAL = 0;
    uint256 constant CRYSTAL = 1;
    uint256 constant FUEL = 2;
    uint256 constant BOOSTER_PACK = 3;
    uint256 constant AVATAR_START = 4;
    uint256 constant LAND_START = AVATAR_START + AVATAR_SKIN_COUNT; //12
    uint256 constant UPGRADE_START = LAND_START + LAND_SKIN_COUNT; //22
    uint256 constant NFT_START = UPGRADE_START + UPGRADE_TYPE_COUNT; //34

    uint256 public lastId = NFT_START;

    constructor() ERC1155("https://9jwlufwrttxr.usemoralis.com:2053/server/functions/metadata?_ApplicationId=dYs1HPZBZwkTGBMw4ksfWnvpE5BZ6nT13LfPmHuU&id={id}") {

        shipTypeStats[ShipType.COMMANDSHIP] = ShipTypeStats(50, 100, 10, 50, 0, 0, 10, 50);
        shipTypeStats[ShipType.BATTLESHIP] = ShipTypeStats(10, 50, 50, 100, 0, 0, 10, 50);
        shipTypeStats[ShipType.MINER] = ShipTypeStats(10, 50, 10, 50, 50, 100, 10, 50);
        shipTypeStats[ShipType.SCOUT] = ShipTypeStats(10, 50, 10, 50, 0, 0, 50, 100);

        shipTypeSkinCount[ShipType.COMMANDSHIP] = 2;
        shipTypeSkinCount[ShipType.BATTLESHIP] = 6;
        shipTypeSkinCount[ShipType.MINER] = 5;
        shipTypeSkinCount[ShipType.SCOUT] = 15;

        upgradeStats[0] = SpaceshipStats(5,0,0,0);
        upgradeStats[1] = SpaceshipStats(10,0,0,0);
        upgradeStats[2] = SpaceshipStats(15,0,0,0);
        upgradeStats[3] = SpaceshipStats(0,5,0,0);
        upgradeStats[4] = SpaceshipStats(0,10,0,0);
        upgradeStats[5] = SpaceshipStats(0,15,0,0);
        upgradeStats[6] = SpaceshipStats(0,0,5,0);
        upgradeStats[7] = SpaceshipStats(0,0,10,0);
        upgradeStats[8] = SpaceshipStats(0,0,15,0);
        upgradeStats[9] = SpaceshipStats(0,0,0,5);
        upgradeStats[10] = SpaceshipStats(0,0,0,10);
        upgradeStats[11] = SpaceshipStats(0,0,0,15);
    }

    function initializeUser() public {
        require(!userInitialized[msg.sender], 'user already initialized');
        userInitialized[msg.sender] = true;
        uint256 randomNumber = vrf.getRandom();
        uint random1 = randomNumber % 100;
        uint random2 = randomNumber % 10000;
        createFreeCommandship(msg.sender, random1);
        createAvatar(msg.sender, random2);
        userData[msg.sender].inventorySlot = initialInventorySlot;
        userRefinery[msg.sender] = UserRefinery(0, initialRefineryProductionPerSecond, initialRefineryConsumptionPerSecond, block.timestamp);
        userExplorationStatus[msg.sender].exploreCompleteTime = block.timestamp;
        _mint(msg.sender, FUEL, initialFuelAmount, "");
        _mint(msg.sender, MINERAL, initialMineralAmount, "");
    }


    modifier onlyVRF() {
        require(msg.sender == address(vrf), "not the vrfProvider");
        _;
    }

    //----------------------
    // UPDATE FUNCTIONS - Owner Only
    //----------------------
    function setVrf(address _vrf) external onlyOwner {
        vrf = IVRFProvider(_vrf);
    }

    function setGRBToken(address _grb) external onlyOwner {
        GRBtoken = IERC20(_grb);
    }

    function setStaker(address _staker) external onlyOwner {
        staker = IStaker(_staker);
    }

    function updateInitialInventorySlot(uint _initialInventorySlot) external onlyOwner {
        initialInventorySlot = _initialInventorySlot;
    }    
    
    function updateInitialRefineryRates(uint _initialRefineryProductionPerSecond, uint _initialRefineryConsumptionPerSecond) external onlyOwner {
        initialRefineryProductionPerSecond = _initialRefineryProductionPerSecond;
        initialRefineryConsumptionPerSecond = _initialRefineryConsumptionPerSecond;
    }

    function updateInitialBalance(uint _initialFuelAmount, uint _initialMineralAmount) external onlyOwner {
        initialFuelAmount = _initialFuelAmount;
        initialMineralAmount = _initialMineralAmount;
    }

    function updateMaxFleetSize(uint _maxFleetSize) external onlyOwner {
        maxFleetSize = _maxFleetSize;
    }

    function updateFreeCommandshipStats(uint hp, uint attack, uint miningSpeed, uint stats) external onlyOwner {
        freeCommandshipStats = SpaceshipStats(hp, attack, miningSpeed, stats);
    }

    function updateBoosterPackPriceGRB(uint _boosterPackPriceGRB) external onlyOwner {
        boosterPackPriceGRB = _boosterPackPriceGRB;
    }

    function updateUpgradeShipStatCrystalCost(uint _upgradeShipStatCrystalCost) external onlyOwner {
        upgradeShipStatCrystalCost = _upgradeShipStatCrystalCost;
    }

    function updateUpgradeRefineryCrystalCost(uint _upgradeRefineryCrystalCost) external onlyOwner {
        upgradeRefineryCrystalCost = _upgradeRefineryCrystalCost;
    }
    //----------------------

    //----------------------
    // UPGRADE FUNCTIONS
    //----------------------

    // statNo: 0:hp, 1:attack, 2:miningSpeed, 3:travelSpeed
    function upgradeShip(uint256 _tokenId, uint256 hpUpgradeCount, uint256 attackUpgradeCount, uint256 miningUpgradeCount, uint256 travelUpgradeCount) external nonReentrant {
        uint256 totalCost = upgradeShipStatCrystalCost * (hpUpgradeCount + attackUpgradeCount + miningUpgradeCount + travelUpgradeCount);
        require(balanceOf(msg.sender, _tokenId) == 1, 'ship doesnt belong to the user');
        require(balanceOf(msg.sender, CRYSTAL) >= totalCost, 'you dont have enough crystal');
        
        _burn(msg.sender, CRYSTAL, totalCost);
        spaceshipData[_tokenId].hp +=  hpUpgradeCount;
        spaceshipData[_tokenId].attack +=  attackUpgradeCount;
        spaceshipData[_tokenId].miningSpeed +=  miningUpgradeCount;
        spaceshipData[_tokenId].travelSpeed +=  travelUpgradeCount;
        emit ShipUpgraded(msg.sender, 0, _tokenId, block.timestamp, hpUpgradeCount, attackUpgradeCount, miningUpgradeCount, travelUpgradeCount);
    }

    function upgradeRefinery(uint256 upgradeCount) external updateRefineryData nonReentrant {
        require(balanceOf(msg.sender, CRYSTAL) >= upgradeRefineryCrystalCost * upgradeCount, 'you dont have enough crystal');
        _burn(msg.sender, CRYSTAL, upgradeRefineryCrystalCost * upgradeCount);
        userRefinery[msg.sender].productionPerSecond += initialRefineryProductionPerSecond * upgradeCount;
        emit RefineryUpgraded(msg.sender, userRefinery[msg.sender].productionPerSecond, block.timestamp);
    }
    //----------------------


    //----------------------
    // SHOP FUNCTIONS 
    //----------------------
    function buyFuel(uint256 _amount) external nonReentrant {
        require(balanceOf(msg.sender, CRYSTAL) >= _amount * buyFuelCrystalCost, 'you dont have enough crystal');
        _burn(msg.sender, CRYSTAL, _amount * buyFuelCrystalCost);
        _mint(msg.sender, FUEL, _amount, '');
    }

    function repairDamage(uint256 _damage) internal nonReentrant {
        require(balanceOf(msg.sender, CRYSTAL) >= _damage * repairCrystalCost, 'you dont have enough crystal');
        _burn(msg.sender, CRYSTAL, _damage * repairCrystalCost);
    }

    function buyGRB(uint256 _amountGRB) external payable nonReentrant {
        require(msg.value >= _amountGRB / priceGRBfromAVAX, 'you need to send correct GRB-AVAX value');
        GRBtoken.safeTransfer(msg.sender, _amountGRB);
    }

    //----------------------


    //----------------------
    // EXPLORE FUNCTIONS 
    //----------------------
    function fleetPower() public view returns(uint, uint, uint, uint, uint) {
        uint hp;
        uint attack;
        uint miningSpeed;
        uint travelSpeed;

        for(uint i=0; i < userFleet[msg.sender].length; i++){
            uint shipId = userFleet[msg.sender][i];
            SpaceshipData memory stats = spaceshipData[shipId];
            hp += stats.hp;
            attack += stats.attack;
            miningSpeed += stats.miningSpeed;
            travelSpeed += stats.travelSpeed;
        }

        return (hp, attack, miningSpeed, travelSpeed, hp + attack);
    }

    function explore(uint256 _distance) external nonReentrant {
        require(!userExplorationStatus[msg.sender].fleetOnExplore, 'your fleet is already on exploration');
        require(balanceOf(msg.sender, FUEL) >= _distance * fuelPerDistance, 'you dont have enough fuel');
        _burn(msg.sender, FUEL, _distance * fuelPerDistance);
        userExplorationStatus[msg.sender].fleetOnExplore = true;
        userExplorationStatus[msg.sender].currentExplorationDistance = _distance;
        uint256 rnd = vrf.getRandom();
        //bytes32 requestId = requestRandomness(keyHash, fee);
        //requestToType[requestId] = 0;
        fulfillExplore(rnd);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomNumber) external onlyVRF {
        //type 0 explore, 1 boosterpack
        if(requestToType[requestId] == 0){
            fulfillExplore(randomNumber);
        }
        else if(requestToType[requestId] == 1){
            fulfillBoosterPack(randomNumber);
        }
    }

    function fulfillExplore(uint256 _random) internal {
        (uint hp,, uint miningSpeed, uint travelSpeed, uint power) = fleetPower();

        uint256 _distance = userExplorationStatus[msg.sender].currentExplorationDistance;
       
        ExplorationStatus storage explorationStatus = userExplorationStatus[msg.sender];
        uint256 randomNumber = _random % 100;
        //check fleet travelSpeed to decrease timer
        explorationStatus.exploreCompleteTime = block.timestamp + _distance * secondsPerDistance / travelSpeed;

        if(randomNumber < 10){ //10% nothing happens
            explorationStatus.currentExplorationType = ExplorationType.NOTHING;
        }
        else if(randomNumber < 61){ //51% mineral node
            explorationStatus.currentExplorationType = ExplorationType.MINERAL;
            if(miningSpeed == 0) explorationStatus.currentMissionFailed = true;
            else{
                explorationStatus.currentMissionFailed = false;
                explorationStatus.mineralsFound = 3**_distance * 1 ether;
                //add mining duration
                explorationStatus.exploreCompleteTime += secondsPerMining / miningSpeed;
            }
        }
        else{ // 39% encounter
            explorationStatus.currentExplorationType = ExplorationType.ENCOUNTER;

            if(randomNumber < 61 + 15){ //15% abondoned mine
                explorationStatus.currentEncounterType = EncounterType.ABONDONED;
                explorationStatus.mineralsFound = 2**_distance * 1 ether;
            }
            else if(randomNumber < 61 + 29){ //14% ambush
                explorationStatus.currentEncounterType = EncounterType.AMBUSH;
                uint256 randomNumberFight = _random / 100000000 % 100000000;
                bool won = fightEnemy(power, _distance, randomNumberFight);
                explorationStatus.currentMissionFailed = !won;
                if(won){
                    explorationStatus.mineralsFound = 4**_distance * 1 ether;
                    explorationStatus.damageTaken += _distance * hp / 20;
                }
                else
                    explorationStatus.damageTaken += _distance * hp / 10;
            }
            else if(randomNumber < 61 + 29){ //10% storm
                explorationStatus.currentEncounterType = EncounterType.STORM;
                explorationStatus.damageTaken += _distance * hp / 10;
            }
        }
    }

    function claimExploration() external nonReentrant {
        ExplorationStatus storage explorationStatus = userExplorationStatus[msg.sender];
        require(explorationStatus.fleetOnExplore, 'your fleet is not on exploration');
        require(explorationStatus.exploreCompleteTime <= block.timestamp, 'exploration is not complete yet');
        explorationStatus.fleetOnExplore = false;
        
        if(explorationStatus.mineralsFound > 0)
            mintMineral(explorationStatus.mineralsFound);
        if(explorationStatus.damageTaken > 0)
            repairDamage(explorationStatus.damageTaken);
    }

    function fightEnemy(uint _power, uint _distance, uint _random) internal pure returns (bool) {
        uint powerRange;
        if(_power <= 100) powerRange = 0;
        else if(_power <=300) powerRange = 1;
        else if(_power <=1000) powerRange = 2;
        else powerRange = 3;

        uint winChance;
        if(_distance == 1) winChance = 70 + powerRange * 10;
        else if(_distance == 2) winChance = 50 + powerRange * 10;
        else if(_distance == 3) winChance = 25 + powerRange * 10;
        else if(_distance == 4) winChance = 1 + powerRange * 10;
        else{
            if(powerRange == 0) winChance = 1;
            else if(powerRange == 1) winChance = 1;
            else if(powerRange == 2) winChance = 11;
            else if(powerRange == 3) winChance = 20;
        }

        return _random <= winChance;
    }
    //----------------------


    //update refinery before claimRefinery, mintMineral and upgradeRefinery to prevent changing the outcome
    modifier updateRefineryData {
        UserRefinery storage refinery = userRefinery[msg.sender];
        uint secondsPassed = block.timestamp - refinery.lastUpdateTime;
        uint mineralSpenditure = secondsPassed * refinery.consumePerSecond;
        uint mineralBalance = balanceOf(msg.sender, MINERAL);
        if(mineralBalance < mineralSpenditure){
            mineralSpenditure = mineralBalance;
        }

        _burn(msg.sender, MINERAL, mineralSpenditure);
        refinery.lastUpdateTime = block.timestamp;
        refinery.waitingToClaim += (mineralSpenditure / refinery.consumePerSecond) * refinery.productionPerSecond;
        _;
    }

    function mintMineral(uint256 _amount) internal updateRefineryData {
        _mint(msg.sender, MINERAL, _amount, "");
    }

    function calculateRefinery() external view returns(uint, uint) {
        UserRefinery memory refinery = userRefinery[msg.sender];
        uint secondsPassed = block.timestamp - refinery.lastUpdateTime;
        uint mineralSpenditure = secondsPassed * refinery.consumePerSecond;
        uint mineralBalance = balanceOf(msg.sender, MINERAL);
        if(mineralBalance < mineralSpenditure){
            mineralSpenditure = mineralBalance;
        }
        return (mineralSpenditure, (mineralSpenditure / refinery.consumePerSecond) * refinery.productionPerSecond);
    }

    function claimRefinery() external updateRefineryData nonReentrant {
        UserRefinery storage refinery = userRefinery[msg.sender];
        uint256 amount = refinery.waitingToClaim;
        refinery.waitingToClaim = 0;
        _mint(msg.sender, CRYSTAL, amount, "");
    }

    function addShipToFleet(uint _tokenId) external {
        require(balanceOf(msg.sender, _tokenId) == 1, 'ship doesnt belong to the user');
        require(!shipIsOnFleet[_tokenId], 'ship is already on the fleet');
        require(userFleet[msg.sender].length < maxFleetSize, 'player fleet is full');
        userFleet[msg.sender].push(_tokenId);
        shipIndexOnFleet[_tokenId] = userFleet[msg.sender].length - 1;
        shipIsOnFleet[_tokenId] = true;

        emit AddShipToFleet(msg.sender, _tokenId);
    }

    function removeShipFromFleet(uint _tokenId) external {
        require(balanceOf(msg.sender, _tokenId) == 1, 'ship doesnt belong to the user');
        require(shipIsOnFleet[_tokenId], 'ship is not on the fleet');       
        userFleet[msg.sender][shipIndexOnFleet[_tokenId]] = userFleet[msg.sender][userFleet[msg.sender].length-1];
        userFleet[msg.sender].pop();
        shipIsOnFleet[_tokenId] = false;
        shipIndexOnFleet[_tokenId] = 0;

        emit RemoveShipFromFleet(msg.sender, _tokenId);
    }

    function getUserShipCount(address _user) external view returns (uint) {
        return userShips[_user].length;
    }

    function getUserShips(address _user) external view returns (uint[] memory) {
        return userShips[_user];
    }
    
    function getUserFleet(address _user) external view returns (uint[] memory) {
        return userFleet[_user];
    }
    
    //----------------------
    // MINT NFT FUNCTIONS 
    //----------------------

    function createAvatar(address user, uint256 randomNumber) internal {
        uint256 skin = randomNumber % AVATAR_SKIN_COUNT;
        uint id = AVATAR_START + skin;

        _mint(user, id, 1, "");

        emit AvatarCreated(user, id, skin);
    }

    function createLand(address user, uint256 randomNumber) internal {
        uint256 skin = randomNumber % LAND_SKIN_COUNT;
        uint id = LAND_START + skin;

        _mint(user, id, 1, "");

        emit LandCreated(user, id, skin);
    }

    function createFreeCommandship(address user, uint256 randomNumber) internal {
        uint256 newId = lastId++;
        uint256 hp = freeCommandshipStats.hp;
        uint256 attack = freeCommandshipStats.attack;
        uint256 miningSpeed = freeCommandshipStats.miningSpeed;
        uint256 travelSpeed = freeCommandshipStats.travelSpeed;
        
        uint256 skin = randomNumber % shipTypeSkinCount[ShipType.COMMANDSHIP];

        spaceshipData[newId] = SpaceshipData(uint256(ShipType.COMMANDSHIP), skin, hp, attack, miningSpeed, travelSpeed);

        _mint(user, newId, 1, "");

        userShips[user].push(newId);
        userFleet[user].push(newId);
        shipIsOnFleet[newId] = true;

        emit ShipCreated(user, newId, uint256(ShipType.COMMANDSHIP), skin, hp, attack, miningSpeed, travelSpeed);
        emit AddShipToFleet(user, newId);
    }

    function createShip(address user, uint256 randomNumber, ShipType shiptype) internal {
        uint256 newId = lastId++;
        
        if(shiptype == ShipType.RANDOM){
            uint random1 = randomNumber % 4;
            if(random1 == 0) shiptype = ShipType.COMMANDSHIP;
            else if(random1 == 1) shiptype = ShipType.BATTLESHIP;
            else if(random1 == 2) shiptype = ShipType.MINER;
            else shiptype = ShipType.SCOUT;
        } 
        ShipTypeStats memory stats = shipTypeStats[shiptype];
        
        uint256 hp = ((randomNumber % ((stats.hpMax - stats.hpMin) * 100)) / 100 ) + stats.hpMin;
        uint256 attack = (randomNumber % ((stats.attackMax - stats.attackMin) * 10000) / 10000) + stats.attackMin;
        uint256 miningSpeed;
        if(shiptype == ShipType.MINER)
            miningSpeed = ((randomNumber % ((stats.miningSpeedMax - stats.miningSpeedMin) * 1000000)) / 1000000 ) + stats.miningSpeedMin;
        uint256 travelSpeed = ((randomNumber % ((stats.travelSpeedMax - stats.travelSpeedMin) * 100000000)) / 100000000 ) + stats.travelSpeedMin;
        uint256 skin = (randomNumber % (shipTypeSkinCount[shiptype] * 10000000000)) / 10000000000;

        spaceshipData[newId] = SpaceshipData(uint256(shiptype), skin, hp, attack, miningSpeed, travelSpeed);

        _mint(user, newId, 1, "");

        userShips[user].push(newId);

        emit ShipCreated(user, newId, uint256(shiptype), skin, hp, attack, miningSpeed, travelSpeed);

        if(userFleet[user].length < maxFleetSize){
            userFleet[user].push(newId);
            shipIsOnFleet[newId] = true;
            emit AddShipToFleet(user, newId);
        }
    }

    function createCommandship() internal {
        uint256 randomNumber = vrf.getRandom();
        createShip(msg.sender, randomNumber, ShipType.COMMANDSHIP);
    }

    function createBattleship() internal {
        uint256 randomNumber = vrf.getRandom();
        createShip(msg.sender, randomNumber, ShipType.BATTLESHIP);
    }

    function createScout() internal {
        uint256 randomNumber = vrf.getRandom();
        createShip(msg.sender, randomNumber, ShipType.SCOUT);
    }

    function createMiner() internal {
        uint256 randomNumber = vrf.getRandom();
        createShip(msg.sender, randomNumber, ShipType.MINER);
    }

    function createRandomShip(address _user) internal {
        uint256 randomNumber = vrf.getRandom();
        createShip(_user, randomNumber, ShipType.RANDOM);
    }

    //----------------------


    //----------------------
    // BOOSTER PACK FUNCTIONS 
    //----------------------

    function buyBoosterPackGRB() external nonReentrant {
        uint price = boosterPackPriceGRB;
        uint stakingLevel = staker.getUserStakingLevel(msg.sender);
        if(stakingLevel > 0) price = price * 9 / 10;
        GRBtoken.safeTransferFrom(msg.sender, address(this), price);
        _mint(msg.sender, BOOSTER_PACK, 1, "");
    }

    function buyBoosterPackAVAX() external payable nonReentrant {
        uint price = boosterPackPriceGRB / priceGRBfromAVAX;
        require(msg.value >= price, 'you need to send correct pack value');
        _mint(msg.sender, BOOSTER_PACK, 1, "");
    }

    function useBoosterPack() external nonReentrant {
        require(balanceOf(msg.sender, BOOSTER_PACK) > 0, 'user doesnt have any booster pack');
        _burn(msg.sender, BOOSTER_PACK, 1);
        uint256 randomNumber = vrf.getRandom();
        //bytes32 requestId = requestRandomness(keyHash, fee);
        //requestToType[requestId] = 1;
        fulfillBoosterPack(randomNumber);
    }

    function fulfillBoosterPack(uint256 _random) internal {
        uint256 totalChance = 138001;

        uint chanceLand = totalChance - 1;
        uint chanceShip = chanceLand - 1000;
        uint chanceCurrency3 = chanceShip - 2000;
        uint chanceCurrency2 = chanceCurrency3 - 5000;
        uint chanceCurrency1 = chanceCurrency2 - 10000;
        uint chanceAvatar = chanceCurrency1 - 10000;
        uint chanceInventorySlot = chanceAvatar - 10000;
        // uint chanceUpgrade = chanceInventorySlot - 100000;

        uint256 boosterRandom = _random % totalChance + 1;

        if(boosterRandom > chanceLand){
            createLand(msg.sender, _random / 1000000000);
            emit BoosterReward(msg.sender, uint8(BoosterRewardType.LAND), 1, block.timestamp);
        }
        else if(boosterRandom > chanceShip){
            createRandomShip(msg.sender);
            emit BoosterReward(msg.sender, uint8(BoosterRewardType.SHIP), 1, block.timestamp);
        }
        else if(boosterRandom > chanceCurrency3){
            rewardCurrency3(msg.sender);
        }
        else if(boosterRandom > chanceCurrency2){
            rewardCurrency2(msg.sender);
        }
        else if(boosterRandom > chanceCurrency1){
            rewardCurrency1(msg.sender);
        }
        else if(boosterRandom > chanceAvatar){
            createAvatar(msg.sender, _random / 1000000000);
            emit BoosterReward(msg.sender, uint8(BoosterRewardType.AVATAR), 1, block.timestamp);
        }
        else if(boosterRandom > chanceInventorySlot){
            rewardInventorySlot(msg.sender);
        }
        else {
            rewardUpgrade(msg.sender, _random / 1000000000);
        }
    }

    function rewardCurrency1(address _user) internal {
        GRBtoken.safeTransfer(_user, boosterPackPriceGRB);
        emit BoosterReward(_user, uint8(BoosterRewardType.CURRENCY), boosterPackPriceGRB, block.timestamp);
    }
    
    function rewardCurrency2(address _user) internal {
        GRBtoken.safeTransfer(_user, 2 * boosterPackPriceGRB);
        emit BoosterReward(_user, uint8(BoosterRewardType.CURRENCY), 2 * boosterPackPriceGRB, block.timestamp);
    }

    function rewardCurrency3(address _user) internal {
        GRBtoken.safeTransfer(_user, 3 * boosterPackPriceGRB);
        emit BoosterReward(_user, uint8(BoosterRewardType.CURRENCY), 3 * boosterPackPriceGRB, block.timestamp);
    }

    function rewardInventorySlot(address _user) internal {
        userData[_user].inventorySlot++;
        emit BoosterReward(_user, uint8(BoosterRewardType.INVENTORY), userData[_user].inventorySlot, block.timestamp);
    }

    function rewardUpgrade(address _user, uint _randomNumber) internal returns (uint id) {
        uint randomNumber = _randomNumber % UPGRADE_TYPE_COUNT;
        id =  UPGRADE_START + randomNumber;
        _mint(msg.sender, id, 1, "");
        emit BoosterReward(_user, uint8(BoosterRewardType.UPGRADE), 1, block.timestamp);
    }

    function useUpgradeCard(uint _upgradeTokenId, uint _shipTokenId) external nonReentrant {
        require(balanceOf(msg.sender, _upgradeTokenId) > 0, 'user doesnt have this upgrade');
        require(balanceOf(msg.sender, _shipTokenId) > 0, 'ship doesnt belong to the user');
        _burn(msg.sender, _upgradeTokenId, 1);
        uint upgradeNo = _upgradeTokenId - UPGRADE_START;
        spaceshipData[_shipTokenId].hp +=  upgradeStats[upgradeNo].hp;
        spaceshipData[_shipTokenId].attack +=  upgradeStats[upgradeNo].attack;
        spaceshipData[_shipTokenId].miningSpeed +=  upgradeStats[upgradeNo].miningSpeed;
        spaceshipData[_shipTokenId].travelSpeed +=  upgradeStats[upgradeNo].travelSpeed;

        emit ShipUpgraded(msg.sender, _upgradeTokenId, _shipTokenId, block.timestamp , upgradeStats[upgradeNo].hp, upgradeStats[upgradeNo].attack, upgradeStats[upgradeNo].miningSpeed, upgradeStats[upgradeNo].travelSpeed);
    }

    //----------------------

    function createTestShipForFree() external {
        createRandomShip(msg.sender);
        emit BoosterReward(msg.sender, uint8(BoosterRewardType.SHIP), 1, block.timestamp);
    }

    function createTestUpgradeCardForFree() external returns (uint id) {
        uint256 randomNumber = vrf.getRandom();
        id = rewardUpgrade(msg.sender, randomNumber);
        emit BoosterReward(msg.sender, uint8(BoosterRewardType.SHIP), 1, block.timestamp);
    }

    function createTestBoosterPackForFree() external {
        _mint(msg.sender, BOOSTER_PACK, 1, "");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 private constant USER_SEED_PLACEHOLDER = 0;

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
  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal immutable LINK;
  address private immutable vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

interface IStaker {
    function deposit(uint _amount, uint _stakingLevel) external returns (bool);
    function withdraw(uint256 _amount) external returns (bool);
    function getUserStakingLevel(address _user) external view returns (uint);
}

contract GRBStaker is IStaker, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    IERC20 public stakingToken;

    struct stakingInfo {
        uint amount;
        uint releaseDate;
        uint stakingLevel;
        uint requiredAmount;
    }

    struct stakingType {
        uint duration;
        uint requiredAmount;
    }

    mapping(address => stakingInfo) public userStakeInfo; 
    mapping(uint => stakingType) public stakingLevels;
    uint public maxStakingLevel;
    uint public stakingDuration = 7776000; //90 days

    event SetLevel(uint levelNo, uint requiredAmount);
    event Deposit(address indexed user, uint256 amount, uint256 stakingLevel, uint256 releaseDate);
    event Withdraw(address indexed user, uint256 amount, uint256 stakingLevel);

    constructor(address _grb) {
        stakingToken = IERC20(_grb);
        stakingLevels[1].requiredAmount = 10 ether;
        stakingLevels[2].requiredAmount = 100 ether;
        stakingLevels[3].requiredAmount = 1000 ether;
        maxStakingLevel = 3;
    }

    function setStakingDuration(uint _duration) external onlyOwner {
        stakingDuration = _duration;
    }

    function setStakingLevel(uint _levelNo, uint _requiredAmount) external onlyOwner {
        require(_levelNo > 0, "level 0 should be empty");

        stakingLevels[_levelNo].requiredAmount = _requiredAmount;
        if(_levelNo>maxStakingLevel)
        {
            maxStakingLevel = _levelNo;
        }
        emit SetLevel(_levelNo, _requiredAmount);
    }

    function getStakingLevel(uint _levelNo) external view returns (uint requiredAmount) {
        require(_levelNo <= maxStakingLevel, "Given staking level does not exist.");
        require(_levelNo > 0, "level 0 is not available");
        return stakingLevels[_levelNo].requiredAmount;
    }

    function deposit(uint _amount, uint _stakingLevel) override external returns (bool){
        require(_stakingLevel > 0, "level 0 is not available");
        require(_amount > 0, "amount is 0");
        require(maxStakingLevel >= _stakingLevel, "Given staking level does not exist.");
        require(userStakeInfo[msg.sender].stakingLevel < _stakingLevel, "User already has a higher or same stake");
        require(userStakeInfo[msg.sender].amount + _amount == stakingLevels[_stakingLevel].requiredAmount, "You need to stake required amount.");
        
        userStakeInfo[msg.sender].amount = userStakeInfo[msg.sender].amount + _amount;

        userStakeInfo[msg.sender].stakingLevel = _stakingLevel;
        userStakeInfo[msg.sender].requiredAmount = stakingLevels[_stakingLevel].requiredAmount;
        userStakeInfo[msg.sender].releaseDate = block.timestamp + stakingDuration;

        emit Deposit(msg.sender, _amount, _stakingLevel, userStakeInfo[msg.sender].releaseDate);

        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);

        return true;
    }

    function withdraw(uint256 _amount) override external nonReentrant returns (bool) {
        require(userStakeInfo[msg.sender].amount >= _amount, "You do not have the entered amount.");
        require(userStakeInfo[msg.sender].releaseDate <= block.timestamp ||
                userStakeInfo[msg.sender].amount - _amount >= stakingLevels[userStakeInfo[msg.sender].stakingLevel].requiredAmount, 
                "You can't withdraw until your staking period is complete.");
        userStakeInfo[msg.sender].amount = userStakeInfo[msg.sender].amount - _amount;
        if(userStakeInfo[msg.sender].amount < stakingLevels[userStakeInfo[msg.sender].stakingLevel].requiredAmount)
        {
            userStakeInfo[msg.sender].stakingLevel = 0;
        }
        stakingToken.safeTransfer(msg.sender, _amount);

        emit Withdraw(msg.sender, _amount, userStakeInfo[msg.sender].stakingLevel);

        return true;
    }

    function getUserStakingLevel(address _user) override external view returns (uint) {
        return userStakeInfo[_user].stakingLevel;
    }

    function getUserBalance(address _user) external view returns (uint) {
        return userStakeInfo[_user].amount;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
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
  ) internal pure returns (uint256) {
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
  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}
// SPDX-License-Identifier: MIT
// Degen Farm. Collectible NFT game
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./IERC1155.sol";
import "./EggERC721.sol";


interface ICreatures is IERC721 {
    function mintWithURI(
        address to, 
        uint256 tokenId, 
        string memory _tokenURI, 
        uint8 _animalType, 
        uint8 _rarity
        ) external;

    function editAnimalNextFarm(uint256 tokenId, uint256  _nextFarmTime) external;
    function setName(uint256 tokenId, string memory _name) external; 
    function getTypeAndRarity(uint256 _tokenId) external returns(uint8, uint8); 
    function getAnimalNextFarm(uint256 _tokenId) external returns(uint256);    
}

interface ILand is IERC721 {
    function mintWithURI(
        address to, 
        uint256 tokenId, 
        string memory _tokenURI 
    ) external;
    function burn(uint256 tokenId) external;
}

interface IDung is IERC20 {
    function mint(
        address to, 
        uint256 amount 
    ) external;
    //function decimals() external returns (uint8);
}

interface IInventory is IERC1155 {
     function getToolBoost(uint8 _item) external view returns (uint16);

}

interface IAmuletPriceProvider {
     function getLastPrice(address _amulet) external view returns (uint256);
}

contract DegenFarm is  Eggs{

    enum   AnimalType {Cow,    Horse, Rabbit, Chicken, Pig, Cat, Dog, Goose, Goat, Sheep}
    enum   Rarity     {Normie, Chad,  Degen}
    enum   Result     {Fail,   Dung,  Chad, Degen}
    
    //External conatrct addresses used with this farm.
    struct AddressRegistry {
        address land;
        address creatures;
        address inventory;
        address bagstoken;
        address dungtoken;
    }

    //Degens Farm Key numbers
    struct CreaturesCount {
        uint16 totalNormie;
        uint16 leftNormie;
        uint16 totalChad;
        uint16 leftChadToDiscover;
        uint16 totalDegen;
        uint16 leftDegen;
        uint16 leftChadFarmAttempts;
        uint16 leftDegenFarmAttempts;
    }

    //Land count record
    struct LandCount {
        uint16 total;
        uint16 left;
    }
 
    //Record  represent one farming act
    struct FarmRecord {
        uint256   creatureId;
        uint256   landId;
        uint256   harvestTime;
        uint256[] amuletsPrice1;
        uint256[] amuletsPrice2;
        Result    harvest;
        uint256   harvestId; //new NFT tokenId
        bool[3]   commonAmuletInitialHold;
    }

    // Bonus for better harvest
    struct Bonus {
        uint16 amuletHold;
        uint16 amuletBullTrend;
        uint16 inventoryHold;
    }

    uint16  constant public MAX_LANDS          = 509;
    uint16  constant public MAX_ALL_NORMIES    = 400;
    uint256 constant public FARMING_DURATION   = 168 hours; //in seconds
    uint256 constant public NEXT_FARMING_DELAY = 1   weeks;
    uint256 constant public TOOL_UNSTAKE_DELAY = 1   weeks;
    uint256 constant public REVEAL_THRESHOLD   = 810e18;    //90% from MAX_BAGS 
    uint256 constant public NFT_ID_MULTIPLIER  = 10000;     //must be set more then all Normies count
    uint256 constant public FARM_DUNG_AMOUNT   = 1e18;      //per one harvest
    uint16  constant public BONUS_POINTS_AMULET_HOLD       = 10;
    uint16  constant public BONUS_POINTS_AMULET_BULL_TREND = 90;
    
    //Common Amulet addresses
    address[3] public COMMON_AMULETS = [
        0xa0246c9032bC3A600820415aE600c6388619A14D, 
        0x87d73E916D7057945c9BcD8cdd94e42A6F47f776,
        0x126c121f99e1E211dF2e5f8De2d96Fa36647c855
    ];

    bool    public REVEAL_ENABLED = false;
    address public priceProvider;
    
    address[][10]                  public amulets; //amulets for creatures
    AddressRegistry                public farm;
    LandCount                      public landCount;

    //common token price snapshots
    mapping(uint256 => uint256[3]) public commonAmuletPrices; 

    // mapping from user to his(her) staked tools
    // Index of uint256[6] represent tool NFT  itemID
    mapping(address => uint256[6]) public userStakedTools;


    uint16 allNormiesesLeft;
    CreaturesCount[10] creaturesBorn;
    FarmRecord[]       farming;

    event Reveal(uint256 indexed _tokenId, bool _isCreature, uint8 _animalType);
    event Harvest(
        uint256 indexed _eggId, 
        address farmer, 
        uint8   result ,
        uint16  baseChance, 
        uint16  amuletHold,
        uint16  amuletBullTrend,
        uint16  inventoryHold
    );
    
    constructor (
        address _land, 
        address _creatures,
        address _inventory,
        address _bagstoken,
        address _dungtoken
    )
    {
        farm.land      = _land;
        farm.creatures = _creatures;
        farm.inventory = _inventory;
        farm.bagstoken = _bagstoken;
        farm.dungtoken = _dungtoken;

        creaturesBorn[0] = CreaturesCount(40, 40, 10, 10, 1, 1, 40, 10);
        creaturesBorn[1] = CreaturesCount(40, 40, 10, 10, 1, 1, 40, 10);
        creaturesBorn[2] = CreaturesCount(40, 40, 10, 10, 1, 1, 40, 10);
        creaturesBorn[3] = CreaturesCount(40, 40, 10, 10, 1, 1, 40, 10);
        creaturesBorn[4] = CreaturesCount(40, 40, 10, 10, 1, 1, 40, 10);
        creaturesBorn[5] = CreaturesCount(40, 40, 10, 10, 1, 1, 40, 10);
        creaturesBorn[6] = CreaturesCount(40, 40, 10, 10, 1, 1, 40, 10);
        creaturesBorn[7] = CreaturesCount(40, 40, 10, 10, 1, 1, 40, 10);
        creaturesBorn[8] = CreaturesCount(40, 40, 10, 10, 1, 1, 40, 10);
        creaturesBorn[9] = CreaturesCount(40, 40, 10, 10, 1, 1, 40, 10);

        landCount        = LandCount(MAX_LANDS, MAX_LANDS);
        allNormiesesLeft = MAX_ALL_NORMIES;

        //Mainnet amulet addrresses
        amulets[0] = [0xD533a949740bb3306d119CC777fa900bA034cd52, 0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C];
        amulets[1] = [0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984, 0x111111111117dC0aa78b770fA6A738034120C302];
        amulets[2] = [0xE41d2489571d322189246DaFA5ebDe1F4699F498, 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F, 
                      0xfA5047c9c78B8877af97BDcb85Db743fD7313d4a
        ]; 
        amulets[3] = [0x0000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000000];
        amulets[4] = [0xc00e94Cb662C3520282E6f5717214004A7f26888, 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2, 
                      0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2
        ];
        amulets[5] = [0x0D8775F648430679A709E98d2b0Cb6250d2887EF, 0x584bC13c7D411c00c01A62e8019472dE68768430];
        amulets[6] = [0x3472A5A71965499acd81997a54BBA8D852C6E53d, 0x0F5D2fB29fb7d3CFeE444a200298f468908cC942];
        amulets[7] = [0x514910771AF9Ca656af840dff83E8264EcF986CA, 0xd7c49CEE7E9188cCa6AD8FF264C1DA2e69D4Cf3B];
        amulets[8] = [0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e, 0x3155BA85D5F96b2d030a4966AF206230e46849cb];
        amulets[9] = [0xa1faa113cbE53436Df28FF0aEe54275c13B40975, 0x3F382DbD960E3a9bbCeaE22651E88158d2791550, 
                      0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9
        ];
    }

    /**
     * @dev Open one users bag 
     *
     */
    function reveal() external {
        require(_isRevelEnabled(), "Please wait for reveal enabled.");
        require(
            IERC20(farm.bagstoken).allowance(msg.sender, address(this)) >= 1e18,
            "Please approve your BAGS token to this contract."
        );
        require(
            IERC20(farm.bagstoken).transferFrom(msg.sender, address(this), 1e18)
        );
        _reveal();
    }
    
    /**
     * @dev Start farming process. New NFT - Egg will minted for user 
     * @param _creatureId - NFT tokenId, caller must be owner of this token
     * @param _landId -- NFT tokenId, caller must be owner of this token
     */
    function farmDeploy(uint256 _creatureId, uint256 _landId) external {
        require(ICreatures(farm.creatures).ownerOf(_creatureId) == msg.sender, 
            "Need to be Creature Owner!"
        );
        require(ICreatures(farm.creatures).getAnimalNextFarm(_creatureId)
            < block.timestamp, "Please wait!"
        );
        require(ILand(farm.land).ownerOf(_landId) == msg.sender, 
            "Need to be Land Owner!"
        );

        //1. Lets make amulet price snapshot
        (uint8 crType, uint8 crRarity) = ICreatures(farm.creatures).getTypeAndRarity(_creatureId);
        require(crRarity != 2, "Can't farm with DEGEN.");
        //1.1. First we need creat array with properly elements count
        uint256[] memory prices1  = new uint256[](amulets[crType].length);
        uint256[] memory prices2  = new uint256[](amulets[crType].length);
        prices1 = _getExistingAmuletsPrices(amulets[crType]);
        //2.Check and save Common Amulets price(if not exist yet)
        _saveCommonAmuletPrices(block.timestamp);
        //3. Save deploy record
        farming.push(
            FarmRecord({
                creatureId:    _creatureId,
                landId:        _landId,
                harvestTime:   block.timestamp + FARMING_DURATION,
                amuletsPrice1: prices1, 
                amuletsPrice2: prices2, 
                harvest:       Result(0), 
                harvestId:     0, 
                commonAmuletInitialHold: _getCommonAmuletsHoldState(msg.sender) //save initial hold state
            })
        );

        //Let's  mint Egg. Mint is internal so use mintWithURI instead this.mintWithURI
        mintWithURI(
            msg.sender,         //farmer 
            farming.length - 1, //tokenId
            ''
        ); 
        //3. Set next farm date for creature
        ICreatures(farm.creatures).editAnimalNextFarm(
            _creatureId, block.timestamp + NEXT_FARMING_DELAY
        );
        //STAKE LAND  and Creatures!!!!
        ILand(farm.land).transferFrom(msg.sender, address(this), _landId);
        ICreatures(farm.creatures).transferFrom(msg.sender, address(this),_creatureId);
    }

    /**
     * @dev Finish farming process. Egg NFT will be  burn 
     * @param _deployId - NFT tokenId, caller must be owner of this token
     */
    function harvest(uint256 _deployId) external {

        require(ownerOf(_deployId) == msg.sender, "This is NOT YOUR EGG!");

        FarmRecord memory f = farming[_deployId];

        //Lets Calculate Dung/CHAD-DEGEN chance
        Result farmingResult;
        Bonus memory bonus;
        //1. BaseChance
        (uint8 crType, uint8 crRarity) = ICreatures(farm.creatures).getTypeAndRarity(
            f.creatureId
        );
        uint16 baseChance;
        if  (crRarity == 0) {
            //Decrease appropriate farm ATTEMPTS COUNT!!!
            creaturesBorn[crType].leftChadFarmAttempts -= 1;
            //Try farm CHAD. So if there is no CHADs any more we must return assets
            if  (creaturesBorn[crType].leftChadToDiscover == 0) {
                _endFarming(_deployId, Result(0));
                return;
            }
            baseChance = creaturesBorn[crType].leftChadToDiscover * 100
                /(creaturesBorn[crType].leftChadFarmAttempts);
        } else {
            //Decrease appropriate farm ATTEMPTS COUNT!!!
            creaturesBorn[crType].leftDegenFarmAttempts -= 1;
            //Try farm DEGEN. So if there is no DEGENSs any more we must return assets
            if  (creaturesBorn[crType].leftDegen == 0) {
                _endFarming(_deployId, Result(0));
                return;
            }
            baseChance = creaturesBorn[crType].leftDegen * 100
                /(creaturesBorn[crType].leftDegenFarmAttempts);
            
        }
        //////////////////////////////////////////////
        //   2. Bonus for amulet token ***HOLD***
        //   3. Bonus for amulets BULLs trend
        //////////////////////////////////////////////
        bonus.amuletHold      = 0;
        bonus.amuletBullTrend = 0;
        //Check common amulets
        _saveCommonAmuletPrices(block.timestamp);
        //Get current hold stae
        for (uint8 i = 0; i < COMMON_AMULETS.length; i ++){
            if (f.commonAmuletInitialHold[i] &&  _getCommonAmuletsHoldState(msg.sender)[i]) {
                //token was hold at deploy time and now - iT IS GOOD
                bonus.amuletHold = BONUS_POINTS_AMULET_HOLD;
                //Lets check Bull TREND
                if  (_getCommonAmuletPrices(f.harvestTime-FARMING_DURATION)[i] 
                        <  _getCommonAmuletPrices(block.timestamp)[i]
                    ) 
                    {
                       bonus.amuletBullTrend = BONUS_POINTS_AMULET_BULL_TREND; 
                    }
                break;
            }
        }
        //Ok,  if there is NO common amulets lets check personal
        uint256[] memory prices2 = new uint256[](amulets[crType].length);
        prices2 = _getExistingAmuletsPrices(amulets[crType]);
        if  (bonus.amuletHold != BONUS_POINTS_AMULET_HOLD) {
            for (uint8 i=0; i < f.amuletsPrice1.length; i ++){
                if (f.amuletsPrice1[i] > 0 && prices2[i] > 0){
                    bonus.amuletHold = BONUS_POINTS_AMULET_HOLD;
                    //Lets check Bull TREND
                    if (f.amuletsPrice1[i] < prices2[i]) {
                       bonus.amuletBullTrend = BONUS_POINTS_AMULET_BULL_TREND; 
                    }
                    break;
                }
            }
        }
        //////////////////////////////////////////////


        ////////////////////////////////////////////// 
        //4. Bonus for inventory 
        //////////////////////////////////////////////
        bonus.inventoryHold = 0;
        if (userStakedTools[msg.sender].length > 0) { 
           for (uint8 i=0; i<userStakedTools[msg.sender].length; i++) {
               if  (userStakedTools[msg.sender][i] > 0){
                   bonus.inventoryHold = bonus.inventoryHold 
                   + IInventory(farm.inventory).getToolBoost(i);
               }
           }
        }  
        //////////////////////////////////////////////

        uint16 allBonus = bonus.amuletHold 
            + bonus.amuletBullTrend 
            + bonus.inventoryHold;
        uint8 chanceOfRarityUP = uint8(
            (baseChance+allBonus) * 100 / (100 + allBonus)
        );
        uint8[] memory choiceWeight = new uint8[](2); 
        choiceWeight[0] = chanceOfRarityUP; 
        choiceWeight[1] = 100 - chanceOfRarityUP;
        uint8 choice = uint8(_getWeightedChoice(choiceWeight));

        if (choice == 0) {
        //Mint new chad/degen    
            ICreatures(farm.creatures).mintWithURI(
                msg.sender, 
                (crRarity + 1) * NFT_ID_MULTIPLIER + _deployId, // new iD
                '', 
                crType, //AnimalType 
                crRarity + 1
            );
            //Decrease appropriate CREATRURE COUNT!!!
            if  (crRarity + 1 == uint8(Rarity.Chad)) {
                creaturesBorn[crType].leftChadToDiscover -= 1;
                farmingResult = Result.Chad;
            } else if (crRarity + 1 == uint8(Rarity.Degen)) {
                creaturesBorn[crType].leftDegen -= 1;
                farmingResult = Result.Degen;
            }
        } else {
        //Mint new dung
            IDung(farm.dungtoken).mint(msg.sender, FARM_DUNG_AMOUNT);
            farmingResult = Result.Dung;
        }
        
        //BURN Land
        ILand(farm.land).burn(f.landId);
        _endFarming(_deployId, farmingResult);
        emit Harvest(
            _deployId, 
            msg.sender, 
            uint8(farmingResult),
            baseChance,
            bonus.amuletHold,
            bonus.amuletBullTrend,
            bonus.inventoryHold 
        );
    }

    /**
     * @dev Stake one inventory item 
     * @param _itemId - NFT tokenId, caller must be owner of this token
     */
    function stakeOneTool(uint8 _itemId) external {
        _stakeOneTool(_itemId);
    }

    /**
     * @dev UnStake one inventory item 
     * @param _itemId - NFT tokenId
     */

    function unstakeOneTool(uint8 _itemId) external {
        _unstakeOneTool(_itemId);
    }

    /////////////////////////////////////////////////////
    ////    Admin functions                       ///////
    /////////////////////////////////////////////////////
    function setOneCommonAmulet(uint8 _index, address _token) external onlyOwner {
        COMMON_AMULETS[_index] = _token;
    }

    function setAmuletForOneCreature(uint8 _index, address[] memory _tokens) external onlyOwner {
        delete amulets[_index];
        amulets[_index] = _tokens;
    }

    function setPriceProvider(address _priceProvider) external onlyOwner {
        priceProvider = _priceProvider;
    }

    function enableReveal() external onlyOwner {
        REVEAL_ENABLED = true;
    }
    ////////////////////////////////////////////////////////

    function getCreatureAmulets(uint8 _creatureType) external view returns (address[] memory) {
        return _getCreatureAmulets(_creatureType);
    }

    function _getCreatureAmulets(uint8 _creatureType) internal view returns (address[] memory) {
        return amulets[_creatureType];
    } 

    function getCreatureStat(uint8 _creatureType) 
        external 
        view 
        returns (
            uint16, 
            uint16, 
            uint16, 
            uint16, 
            uint16, 
            uint16,
            uint16,
            uint16 
        )
    {
        CreaturesCount storage stat = creaturesBorn[_creatureType];
        return (
            stat.totalNormie, 
            stat.leftNormie, 
            stat.totalChad, 
            stat.leftChadToDiscover, 
            stat.totalDegen, 
            stat.leftDegen,
            stat.leftChadFarmAttempts,
            stat.leftDegenFarmAttempts
        );
    }


    function getWeightedChoice(uint8[] memory _weights) external view returns (uint8){
        return _getWeightedChoice(_weights);
    }

     
    function getFarmingById(uint256 _farmingId) external view returns (FarmRecord memory) {
        return farming[_farmingId];
    }

    function getCommonAmuletPrices(uint256 _timestamp) external view returns (uint256[3] memory) {
        return _getCommonAmuletPrices(_timestamp);
    }

    function getOneAmuletPrice(address _token) external view returns (uint256) {
        return _getOneAmuletPrice(_token);
    }

    function checkApprovedForAll() public view returns (bool) {
         return ILand(farm.land).isApprovedForAll(msg.sender, address(this));
    }
    ///////////////////////////////////////////////
    ///  Internals                          ///////                   
    ///////////////////////////////////////////////
    /**
     * @dev Save farming results in storage and mint
     * appropriate token (NFT, ERC20 or None)
    */
    function _endFarming(uint256 _deployId, Result  _res) internal {
        //TODO need refactor if EGGs will be
        FarmRecord storage f = farming[_deployId];
        f.harvest = _res;
        //unstake creatuer 
        ICreatures(farm.creatures).transferFrom( address(this), msg.sender, f.creatureId);
        _burn(_deployId); //Burn EGG

        if  (_res ==  Result.Fail) {
            //unstake land (if staked)
            if (ILand(farm.land).ownerOf(f.landId) == address(this)){
               ILand(farm.land).transferFrom( address(this), msg.sender, f.landId);
            }
            emit Harvest(
                _deployId, 
                msg.sender, 
                uint8(_res),
                0, //baseChance
                0, //bonus.amuletHold,
                0, //bonus.amuletBullTrend,
                0  //bonus.inventoryHold 
            );   
        //} else if (_res ==  Result.Dung)  {
            //Mint Dung -done above
        } else if (_res ==  Result.Chad)  {
            //Mint Chad -done above
            f.harvestId = 2000 +_deployId;
        } else if (_res ==  Result.Degen) {
            //Mint Degen - done above
            f.harvestId = 2000 +_deployId;
        }
    }

    function _stakeOneTool(uint8 _itemId) internal {
        require(IInventory(farm.inventory).balanceOf(msg.sender, _itemId) >= 1,
            "You must own this tool for stake!"
        );
        //Before stake  we need two checks.
        //1. If it is first stake create all array records
        if (userStakedTools[msg.sender].length == 0) {
            userStakedTools[msg.sender]=[uint256(0),0,0,0,0,0];
        }

        //2. Cant`t stake one tool more than one item
        require(userStakedTools[msg.sender][_itemId] == 0, "Tool is already staked");

        //stake
        IInventory(farm.inventory).safeTransferFrom(
            msg.sender, 
            address(this), 
            _itemId, 
            1, 
            bytes('0')
        );
        userStakedTools[msg.sender][_itemId] = block.timestamp;

    }

    function _unstakeOneTool(uint8 _itemId) internal {
        require(userStakedTools[msg.sender].length == 6,  "You have NO staked tools");
        require(userStakedTools[msg.sender][_itemId] > 0, "This tool is not staked yet");
        require(block.timestamp - userStakedTools[msg.sender][_itemId] >= TOOL_UNSTAKE_DELAY,
            "Cant unstake earlier than a week"
        );
        userStakedTools[msg.sender][_itemId] = 0;
        IInventory(farm.inventory).safeTransferFrom(
            address(this), 
            msg.sender, 
            _itemId, 
            1, 
            bytes('0')
        );

    }

    function _saveCommonAmuletPrices(uint256 _timestamp) internal {
        //Lets check if price NOT exist for this timestamp - lets save it
        if  (commonAmuletPrices[_timestamp][0] == 0) {
            for (uint8 i=0; i < COMMON_AMULETS.length; i++){
                commonAmuletPrices[_timestamp][i] = _getOneAmuletPrice(COMMON_AMULETS[i]);
            }
        }
    }

    function _getCommonAmuletPrices(uint256 _timestamp) internal view returns (uint256[3] memory) {
        //Lets check if price allready exist for this timestamp - just return it
        if  (commonAmuletPrices[_timestamp][0] != 0) {
            return commonAmuletPrices[_timestamp];
        }
        //If price is not exist lets get it from oracles
        uint256[3] memory res;
        for (uint8 i=0; i < COMMON_AMULETS.length; i++){
            res[i] = _getOneAmuletPrice(COMMON_AMULETS[i]);
        }
        return res;
    }

    function _getCommonAmuletsHoldState(address _farmer) internal view returns (bool[3] memory) {
        
        //If token balance =0 - set false
        bool[3] memory res;
        for (uint8 i=0; i < COMMON_AMULETS.length; i++){
            if  (IERC20(COMMON_AMULETS[i]).balanceOf(_farmer) > 0){
                res[i] = true;    
            } else {
            // Set to zero if token balance is 0   
                res[i] = false;
            }
        }
        return res;
    }

    function _getExistingAmuletsPrices(address[] memory _tokens) 
        internal 
        view 
        returns (uint256[] memory) 
    {
        uint256[] memory res = new uint256[](_tokens.length);
        for (uint8 i=0; i < _tokens.length; i++){
            if  (IERC20(_tokens[i]).balanceOf(msg.sender) > 0){
                res[i] = _getOneAmuletPrice(_tokens[i]);    
            } else {
            // Set to zero if token balance is 0   
                res[i] = 0;
            }    
        }
        return res;
    }

    function _getOneAmuletPrice(address _token) internal view returns (uint256) {
        return IAmuletPriceProvider(priceProvider).getLastPrice(_token);
    }


    function _isRevelEnabled() internal view returns (bool) {
        if  (REVEAL_ENABLED == true) {
            return true;
        }

        if  (IERC20(farm.bagstoken).totalSupply() > REVEAL_THRESHOLD) {
            return true;
        }
        return false;  
    }

    function _reveal() internal {
        require ((landCount.left + allNormiesesLeft) > 0, "Sorry, no more reveal!");
        //1. Lets choose Land OR Creature, %
        //So we have two possible results. 1 - Land, 0 - Creature.
        // sum of weights = 100, lets define weigth for Creature
        uint8[] memory choiceWeight = new uint8[](2); 
        choiceWeight[0] = uint8(allNormiesesLeft*100/(allNormiesesLeft+landCount.left)); 
        choiceWeight[1] = 100 - choiceWeight[0];
        uint8 choice = uint8(_getWeightedChoice(choiceWeight));
        //Check that choice can be executed
        if (choice != 0 && landCount.left == 0) {
            //Theres no more Land!!! So we need change choice
            choice = 0;
        }

        if  (choice == 0) {
            uint8[] memory choiceWeight = new uint8[](10);
            //2. Ok, Creature will  be born. But what kind of?
            for (uint8 i = 0; i < 10; i++) {
                choiceWeight[i] = uint8(creaturesBorn[i].leftNormie);
            }
            choice = uint8(_getWeightedChoice(choiceWeight));
            ICreatures(farm.creatures).mintWithURI(
                msg.sender, 
                MAX_ALL_NORMIES - allNormiesesLeft, 
                '', 
                choice, //AnimalType 
                0
            );
            emit Reveal(MAX_ALL_NORMIES - allNormiesesLeft, true, choice);
            allNormiesesLeft -= 1;
            creaturesBorn[choice].leftNormie -= 1;
        } else {
            ILand(farm.land).mintWithURI(
                msg.sender, 
                MAX_LANDS - landCount.left+1,
                '' 
            );
            emit Reveal(MAX_LANDS - landCount.left, false, 0);
            landCount.left -= 1; 
        }
    }

    function _getWeightedChoice(uint8[] memory _weights)  internal view returns (uint8){
        uint256 sum_of_weights;
        for (uint8 i = 0; i < _weights.length; i++) {
            sum_of_weights += _weights[i];
        }
        uint256 rnd = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % sum_of_weights;
        for (uint8 i = 0; i < _weights.length; i++) {
            if (rnd < _weights[i]) {
                return i;
            }
            rnd -= _weights[i];
        }
        return 0;
    }  
}
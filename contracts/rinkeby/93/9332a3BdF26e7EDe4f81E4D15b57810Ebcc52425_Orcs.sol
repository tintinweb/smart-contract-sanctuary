// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

import "./ERC20.sol";
import "./ERC721.sol"; 

//    ___ _   _               ___            
//  | __| |_| |_  ___ _ _   / _ \ _ _ __ ___
//  | _||  _| ' \/ -_) '_| | (_) | '_/ _(_-<
//  |___|\__|_||_\___|_|    \___/|_| \__/__/
//

interface MetadataHandlerLike {
    function getTokenURI(uint16 id, uint8 body, uint8 helm, uint8 mainhand, uint8 offhand, uint16 level, uint16 zugModifier) external view returns (string memory);
}

contract Orcs is ERC721 {

    /*///////////////////////////////////////////////////////////////
                    Global STATE
    //////////////////////////////////////////////////////////////*/

    // TODO add proper cooldown
    uint256 public constant  cooldown = 3 minutes;
    uint256 public immutable startingTime;

    bytes32 internal entropySauce;

    ERC20 public zug;

    mapping (uint256 => Orc)      public orcs;
    mapping (uint256 => Action)   public activities;
    mapping (Places  => LootPool) public lootPools;

    //TODO - remove this
    MetadataHandlerLike metadaHandler;

    function setMetadataHandler(address meta) external {
        metadaHandler = MetadataHandlerLike(meta);
    }

    //TODO adjust tokens URI function
    function tokenURI(uint256 id) external view returns(string memory) {
        Orc memory orc = orcs[id];
        return metadaHandler.getTokenURI(uint16(id), orc.body, orc.helm, orc.mainhand, orc.offhand, orc.level, orc.zugModifier);
    }

    function gimmeWeapons(uint256 id, uint8 helm_, uint8 mainhand_, uint8 offhand_) external {
        orcs[id].helm        = helm_;
        orcs[id].mainhand    = mainhand_;
        orcs[id].offhand     = offhand_;
        orcs[id].zugModifier = _tier(helm_) + _tier(mainhand_) + _tier(offhand_);
    }


    /*///////////////////////////////////////////////////////////////
                DATA STRUCTURES 
    //////////////////////////////////////////////////////////////*/

    struct LootPool { 
        uint8  minLevel; uint8  minLootTier; uint16  cost;   uint16 total;
        uint16 tier_1;   uint16 tier_2;      uint16 tier_3; uint16 tier_4;
    }

    struct Orc { uint8 body; uint8 helm; uint8 mainhand; uint8 offhand; uint16 level; uint16 zugModifier; uint32 lvlProgress; }

    enum Actions { NOTHING, FARMING, TRAINING }
    struct Action { address owner; uint88 timestamp; Actions action; }

    // These are all the places you can go search for loot
    enum Places { 
        TOWN, DUNGEON, CRYPT, CASTLE, DRAGONS_LAIR, THE_ETHER, 
        TAINTED_KINGDOM, OOZING_DEN, ANCIENT_CHAMBER, ORC_GODS, GOOD_LOOT 
    }   

    /*///////////////////////////////////////////////////////////////
                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor( ) ERC721("Ether Orcs", "ORC") {

        // Here's whats available in each place
        LootPool memory town           = LootPool({ minLevel: 1,  minLootTier:  2, cost:   0, total: 1000, tier_1: 8000, tier_2: 1500, tier_3: 500, tier_4:   0 });
        LootPool memory dungeon        = LootPool({ minLevel: 3,  minLootTier:  3, cost:   0, total: 1000, tier_1: 8000, tier_2: 1500, tier_3: 500, tier_4:   0 });
        LootPool memory crypt          = LootPool({ minLevel: 6,  minLootTier:  4, cost:   0, total: 9000, tier_1: 4950, tier_2: 3600, tier_3: 450, tier_4:   0 }); 
        LootPool memory castle         = LootPool({ minLevel: 12, minLootTier:  5, cost:   0, total: 6000, tier_1: 3300, tier_2: 2400, tier_3: 300, tier_4:   0 });
        LootPool memory dragonsLair    = LootPool({ minLevel: 20, minLootTier:  6, cost:   0, total: 6000, tier_1: 3300, tier_2: 2400, tier_3: 300, tier_4:   0 });
        LootPool memory theEther       = LootPool({ minLevel: 24, minLootTier:  7, cost:   0, total: 3000, tier_1: 1200, tier_2: 1500, tier_3: 300, tier_4:   0 });
        LootPool memory taintedKingdom = LootPool({ minLevel: 12, minLootTier:  5, cost:  50, total:  600, tier_1:  150, tier_2:  150, tier_3: 150, tier_4: 150 });
        LootPool memory oozingDen      = LootPool({ minLevel: 20, minLootTier:  6, cost:  50, total:  600, tier_1:  150, tier_2:  150, tier_3: 150, tier_4: 150 });
        LootPool memory acientChamber  = LootPool({ minLevel: 30, minLootTier: 10, cost: 125, total:  225, tier_1:  225, tier_2:    0, tier_3:   0, tier_4:   0 });
        LootPool memory orcGods        = LootPool({ minLevel: 32, minLootTier: 11, cost: 300, total:   10, tier_1:    0, tier_2:    0, tier_3:   0, tier_4:   0 });
        LootPool memory goodLoot       = LootPool({ minLevel: 1, minLootTier: 7, cost: 3, total:   10, tier_1:    3, tier_2:    3, tier_3:   3, tier_4:   4 });

        lootPools[Places.TOWN]            = town;
        lootPools[Places.DUNGEON]         = dungeon;
        lootPools[Places.CRYPT]           = crypt;
        lootPools[Places.CASTLE]          = castle;
        lootPools[Places.DRAGONS_LAIR]    = dragonsLair;
        lootPools[Places.THE_ETHER]       = theEther;
        lootPools[Places.TAINTED_KINGDOM] = taintedKingdom;
        lootPools[Places.OOZING_DEN]      = oozingDen;
        lootPools[Places.ANCIENT_CHAMBER] = acientChamber;
        lootPools[Places.ORC_GODS]        = orcGods;
        lootPools[Places.GOOD_LOOT]       = goodLoot;

        // TODO add delay
        startingTime = block.timestamp + 0 hours; // There's 4.5 hours of no actions

        // Deploy Zug
        zug = new ERC20();
        zug.setMinter(address(this), true);
        zug.setRuler(address(this));

    }

    /*///////////////////////////////////////////////////////////////
                    MODIFIERS 
    //////////////////////////////////////////////////////////////*/

    modifier noCheaters() {
        uint256 size = 0;
        address acc = msg.sender;
        assembly { size := extcodesize(acc)}

        require(msg.sender == tx.origin , "you're trying to cheat!");
        require(size == 0,                "you're trying to cheat!");
        _;

        // We'll use the last caller hash to add entropy to next caller
        entropySauce = keccak256(abi.encodePacked(acc, block.coinbase));
    }

    modifier ownerOfOrc(uint256 id) { 
        require(ownerOf[id] == msg.sender || activities[id].owner == msg.sender, "not your orc");
        _;
    }


    /*///////////////////////////////////////////////////////////////
                    PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function mint() external noCheaters returns (uint256 id) {
        uint256 cost = _getMintingPrice();
        uint256 rand = _rand();

        if (cost > 0) zug.burn(msg.sender, cost);
        return _mintOrc(rand);
    }

    function doAction(uint256 id, Actions action_) public ownerOfOrc(id) noCheaters {
        _transfer(msg.sender, address(this), id);
        
        activities[id] = Action({
            owner: msg.sender, action: action_,
            timestamp: uint88(block.timestamp > startingTime ? block.timestamp : startingTime) 
        });
    }

    function doActionWithManyOrcs(uint256[] calldata ids, Actions action_) external {
        for (uint256 index = 0; index < ids.length; index++) {
            doAction(ids[index], action_);
        }
    }

    function stopAction(uint256 id) public ownerOfOrc(id) noCheaters {
        require(activities[id].action != Actions.NOTHING);

        _transfer(address(this), activities[id].owner, id);
        claim(id);

        activities[id].action = Actions.NOTHING;
    }

    function switchAction(uint256 id, Actions action_) public noCheaters {
        require(activities[id].owner == msg.sender, "Not your orc");
        require(activities[id].timestamp >= block.timestamp, "can't change on cooldown");

        claim(id);
        activities[id].action = action_;
    }

    function claim(uint256 id) public noCheaters {
        Orc    memory orc    = orcs[id];
        Action memory action = activities[id];

        if(block.timestamp <= action.timestamp) return;

        uint256 timeDiff = uint256(block.timestamp - action.timestamp);

        //TODO adjust booster rates
        if (action.action == Actions.FARMING) {
            uint256 farmingRate   = 4000;
            uint256 dailyEmission = (farmingRate + orc.zugModifier) * 1 ether;
            uint256 zugAmount     = timeDiff * dailyEmission / 1 days;

            zug.mint(action.owner, zugAmount * 1 ether);
        }
        if (action.action == Actions.TRAINING) {
            uint256 levelingRate   = 2000000000;
            orcs[id].lvlProgress += uint16(timeDiff * levelingRate / 1 days);
            orcs[id].level        = uint16(orcs[id].lvlProgress / 1000);
        }

        activities[id].timestamp = uint88(block.timestamp);
    }

    function pillage(uint256 id, Places place, bool tryHelm, bool tryMainhand, bool tryOffhand) public ownerOfOrc(id) noCheaters {
        require(block.timestamp >= uint256(activities[id].timestamp), "on cooldown");
        require(place != Places.ORC_GODS,  "You can't pillage the Orc God");

        if(activities[id].timestamp < block.timestamp) claim(id); // Need to claim to not have equipment reatroactively multiplying

        uint256 rand_ = _rand();
  
        LootPool memory pool = lootPools[place];
        require(orcs[id].level >= uint16(pool.minLevel), "below minimum level");
         
        if (pool.cost > 0) {
            // TODO add a 14 day delay
            require(block.timestamp - startingTime > 10 minutes);
            zug.burn(msg.sender, pool.cost * 1 ether);
        } 

        uint8 item;
        if (tryHelm) {
            ( pool, item ) = _getItemFromPool(pool, _randomize(rand_,"HELM", id));
            if (item != 0 ) orcs[id].helm = item;
        }
        if (tryMainhand) {
            ( pool, item ) = _getItemFromPool(pool, _randomize(rand_,"MAINHAND", id));
            if (item != 0 ) orcs[id].mainhand = item;
        }
        if (tryOffhand) {
            ( pool, item ) = _getItemFromPool(pool, _randomize(rand_,"OFFHAND", id));
            if (item != 0 ) orcs[id].offhand = item;
        }

        if (uint(place) > 1) lootPools[place] = pool;

        // Update zug modifier
        Orc memory orc = orcs[id];
        uint16 zugModifier_ = _tier(orc.helm) + _tier(orc.mainhand) + _tier(orc.offhand);

        orcs[id].zugModifier = zugModifier_;

        activities[id].timestamp = uint88(block.timestamp + cooldown);
    } 

    function doSumthin(uint256 id) public ownerOfOrc(id) noCheaters {
        require(_tier(orcs[id].mainhand) < 11);
        // TODO add a 14 day delay
        require(block.timestamp - startingTime >= 20 minutes);
        
        LootPool memory pool = lootPools[Places.ORC_GODS];

        zug.burn(msg.sender, pool.cost * 1 ether);

        claim(id); // Need to claim to not have equipment reatroactively multiplying

        uint8 item = uint8(lootPools[Places.ORC_GODS].total--);
        orcs[id].zugModifier = 30;
        orcs[id].body = orcs[id].helm = orcs[id].mainhand = orcs[id].offhand = item + 40;
    }

    /*///////////////////////////////////////////////////////////////
                    VIEWERS
    //////////////////////////////////////////////////////////////*/

    function claimableZug(uint256 id) external view returns (uint256 zugAmount) {
        if (activities[id].action != Actions.FARMING || block.timestamp >= activities[id].timestamp) return 0;
        uint256 farmingRate   = 4000;
        uint256 dailyEmission = (farmingRate + orcs[id].zugModifier) * 1 ether;
        zugAmount            = uint256(block.timestamp - activities[id].timestamp) * dailyEmission / 1 days;
    }

    /*///////////////////////////////////////////////////////////////
                    MINT FUNCTION
    //////////////////////////////////////////////////////////////*/

    function _mintOrc(uint256 rand) internal returns (uint16 id) {

        uint8 body;
        uint8 helm;
        uint8 mainhand;
        uint8 offhand;
        {
            // Helpers to get Percentages
            uint256 sevenFivePct  = type(uint16).max / 100 * 75;
            uint256 ninetyPct     = type(uint16).max / 100 * 90;
            uint256 nineFivePct   = type(uint16).max / 100 * 95;
            uint256 nineEightPct  = type(uint16).max / 100 * 98;
    
            id = uint16(totalSupply + 1);
    
            // Getting Random traits
            uint16 randBody = uint16(_randomize(rand, "BODY", id));
                   body     = uint8(randBody > nineFivePct ? randBody % 4 + 16 : 
                              randBody > sevenFivePct ? randBody % 6 + 10 : randBody % 10 + 1 );
    
            uint16 randHelm = uint16(_randomize(rand, "HELM", id));
                   helm     = uint8(randHelm < nineFivePct ? 0 : randHelm % 4 + 5);
    
            uint16 randOffhand = uint16(_randomize(rand, "OFFHAND", id));
                   offhand     = uint8(randOffhand < nineFivePct ? 0 : randOffhand % 4 + 5);
    
            uint16 randMainhand = uint16(_randomize(rand, "MAINHAND", id));
                   mainhand     = uint8(randMainhand > nineEightPct ? randMainhand % 4 + 9 :
                                  randMainhand > ninetyPct    ? randMainhand % 4 + 5 : randMainhand % 4 + 1);
            
        }


        _mint(msg.sender, id);

        uint16 zugModifier = _tier(helm) + _tier(mainhand) + _tier(offhand);
        orcs[uint256(id)] = Orc({body: body, helm: helm, mainhand: mainhand, offhand: offhand, level: 0, lvlProgress: 0, zugModifier:zugModifier});
    }

    /*///////////////////////////////////////////////////////////////
                    INTERNAL  HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @dev take an available item from a pool
    function _getItemFromPool(LootPool memory pool, uint256 rand) internal pure returns (LootPool memory, uint8 item) {
        uint draw = rand % pool.total--; 

        if (draw > pool.tier_1 + pool.tier_2 + pool.tier_3 && pool.tier_4 > 0) {
            item = uint8((pool.tier_4-- % 4 + 1) + (pool.minLootTier + 3) * 4);     
            return (pool, item);
        }

        if (draw > pool.tier_1 + pool.tier_2 && pool.tier_3 > 0) {
            item = uint8((pool.tier_3-- % 4 + 1) + (pool.minLootTier + 2) * 4);
            return (pool, item);
        }

        if (draw > pool.tier_1 && pool.tier_2 > 0) {
            item = uint8((pool.tier_2-- % 4 + 1) + (pool.minLootTier + 1) * 4);
            return (pool, item);
        }

        if (pool.tier_1 > 0) {
            item = uint8((pool.tier_1-- % 4 + 1) + pool.minLootTier * 4);
            return (pool, item);
        }
    }

    /// @dev Convert an id to its tier
    function _tier(uint16 id) internal pure returns (uint16) {
        if (id == 0) return 0;
        return (id / 4 ) + 1;
    }

    /// @dev Create a bit more of randomness
    function _randomize(uint256 rand, string memory val, uint256 spicy) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(rand, val, spicy)));
    }

    function _rand() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.basefee, block.timestamp, entropySauce)));
    }

    function _getMintingPrice() internal view returns (uint256) {
        if (totalSupply < 5) return   0;
        if (totalSupply < 20) return   4 ether;
        if (totalSupply < 25) return   8 ether;
        if (totalSupply < 30) return  12 ether;
        if (totalSupply < 35) return  24 ether;
        if (totalSupply < 40) return  60 ether;
        if (totalSupply < 45) return 130 ether;
    }
}
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
    function getTokenURI(uint16 id, uint16 body, uint16 helm, uint16 mainhand, uint16 offhand, uint16 level, uint16 zugModifier) external view returns (string memory);
}

contract Orcs is ERC721 {

    /*///////////////////////////////////////////////////////////////
                    Global STATE
    //////////////////////////////////////////////////////////////*/

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

    function tokenURI(uint256 id) external view returns(string memory) {
        Orc memory orc = orcs[id];
        return metadaHandler.getTokenURI(uint16(id), uint16(orc.body), orc.helm, orc.mainhand, orc.offhand, orc.level, orc.zugModifier);
    }


    /*///////////////////////////////////////////////////////////////
                DATA STRUCTURES 
    //////////////////////////////////////////////////////////////*/

    struct LootPool { 
        uint8  minLevel; uint8  minLootTier; uint16  cost;   uint16 total;
        uint16 tier_1;   uint16 tier_2;      uint16 tier_3; uint16 tier_4;
    }

    struct Orc { uint8 body; uint8 helm; uint8 mainhand; uint8 offhand; uint16 level; uint16 zugModifier; uint32 lvlProgress; }

    enum Actions { UNSTAKED, FARMING, TRAINING }
    struct Action { address owner; uint88 timestamp; Actions action; }

    // These are all the places you can go search for loot
    enum Places { 
        TOWN, DUNGEON, CRYPT, CASTLE, DRAGONS_LAIR, THE_ETHER, 
        TAINTED_KINGDOM, OOZING_DEN, ANCIENT_CHAMBER, ORC_GODS 
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

        startingTime = block.timestamp + 1 minutes; // There's 4.5 hours of no actions

        // Deploy Zug
        zug = new ERC20();
        zug.setMinter(address(this), true);
        zug.setRuler(address(this));

    }

     /*///////////////////////////////////////////////////////////////
                    RINKEBY TEST FUNCTIONS 
    //////////////////////////////////////////////////////////////*/


    function mintBatch() external noCheaters returns (uint256 id) {
        for (uint256 index = 0; index < 101; index++) {
            mint();
        }
    }

     function doActionBatch(uint256 batchId, Actions action_) external noCheaters  {
        for (uint256 index = 0; index < 101; index++) {
            doAction(index + ((batchId - 1 ) * 100), action_);
        }
    }

     function claimBatch(uint256 batchId) public noCheaters {
        for (uint256 index = 0; index < 101; index++) {
            claim(index + ((batchId - 1 ) * 100));
        }
    }

    function pillageBatch(uint256 batchId, Places place, bool tryHelm, bool tryMainhand, bool tryOffhand) public noCheaters {
        for (uint256 index = 0; index < 101; index++) {
            pillage(index + ((batchId - 1 ) * 100), place, tryHelm, tryMainhand, tryOffhand);
        }
    } 

    function getHundredZug() external {
        _mint(msg.sender, 100 ether);
    }

    function upLevel(uint256 batchId) external {
        for (uint256 index = 0; index < 101; index++) {
            uint i = index + ((batchId - 1 ) * 100);
            orcs[i].level = orcs[i].level + 2;
        }
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

    function mint() public noCheaters returns (uint256 id) {
        uint256 cost = _getMintingPrice();
        uint256 rand = _rand();

        if (cost > 0) zug.burn(msg.sender, cost);
        return _mintOrc(rand);
    }

    function doAction(uint256 id, Actions action_) public ownerOfOrc(id) noCheaters {
        Action memory action = activities[id];
        require(action.action != action_, "already doing that");

        // Picking the largest value between blocl.timestamp, action.timestamp and startingTime
        uint88 timestamp = uint88(startingTime > (block.timestamp > action.timestamp ? block.timestamp : action.timestamp) ?
                                  startingTime : (block.timestamp > action.timestamp ? block.timestamp : action.timestamp));

        if (action.action == Actions.UNSTAKED)  _transfer(msg.sender, address(this), id);
     
        else {
            if (block.timestamp > action.timestamp) claim(id);
            timestamp = timestamp > action.timestamp ? timestamp : action.timestamp;
        }

        if (action_ == Actions.UNSTAKED) _transfer(address(this), activities[id].owner, id);

        activities[id] = Action({owner: msg.sender, action: action_,timestamp: timestamp});
    }

    function doActionWithManyOrcs(uint256[] calldata ids, Actions action_) external {
        for (uint256 index = 0; index < ids.length; index++) {
            doAction(ids[index], action_);
        }
    }

    function claim(uint256 id) public noCheaters {
        Orc    memory orc    = orcs[id];
        Action memory action = activities[id];

        if(block.timestamp <= action.timestamp) return;

        uint256 timeDiff = uint256(block.timestamp - action.timestamp);

        if (action.action == Actions.FARMING) zug.mint(action.owner, claimableZug(timeDiff, orc.zugModifier));
       
        if (action.action == Actions.TRAINING) {
            orcs[id].lvlProgress += uint16(timeDiff * 2000 / 1 days);
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
            require(block.timestamp - startingTime > 1 minutes);
            zug.burn(msg.sender, uint256(pool.cost) * 1 ether);
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
        require(block.timestamp - startingTime >= 1 minutes);
        
        LootPool memory pool = lootPools[Places.ORC_GODS];

        zug.burn(msg.sender, uint256(pool.cost) * 1 ether);

        claim(id); // Need to claim to not have equipment reatroactively multiplying

        uint8 item = uint8(lootPools[Places.ORC_GODS].total--);
        orcs[id].zugModifier = 30;
        orcs[id].body = orcs[id].helm = orcs[id].mainhand = orcs[id].offhand = item + 40;
    }

    /*///////////////////////////////////////////////////////////////
                    VIEWERS
    //////////////////////////////////////////////////////////////*/

    function claimable(uint256 id) external view returns (uint256 amount) {
        uint256 timeDiff = uint256(block.timestamp - activities[id].timestamp);
        amount = activities[id].action == Actions.FARMING ? claimableZug(timeDiff, orcs[id].zugModifier) : timeDiff * 2000 / 1 days;
    }

    /*///////////////////////////////////////////////////////////////
                    MINT FUNCTION
    //////////////////////////////////////////////////////////////*/

    function _mintOrc(uint256 rand) internal returns (uint16 id) {
        (uint8 body,uint8 helm,uint8 mainhand,uint8 offhand) = (0,0,0,0);

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

    function claimableZug(uint256 timeDiff, uint16 zugModifier) internal pure returns (uint256 zugAmount) {
        zugAmount = timeDiff * (4 + zugModifier) * 1 ether / 1 days;
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
        if (totalSupply < 1500) return   0;
        if (totalSupply < 2000) return   4 ether;
        if (totalSupply < 2500) return   8 ether;
        if (totalSupply < 3000) return  12 ether;
        if (totalSupply < 3500) return  24 ether;
        if (totalSupply < 4000) return  60 ether;
        if (totalSupply < 4500) return 130 ether;
    }
}
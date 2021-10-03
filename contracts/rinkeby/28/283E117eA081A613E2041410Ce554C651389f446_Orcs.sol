// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

import "./ERC20.sol";
import "./ERC721.sol"; 

//    ___ _   _               ___            
//  | __| |_| |_  ___ _ _   / _ \ _ _ __ ___
//  | _||  _| ' \/ -_) '_| | (_) | '_/ _(_-<
//  |___|\__|_||_\___|_|    \___/|_| \__/__/
//

contract Orcs is ERC721 {

    /*///////////////////////////////////////////////////////////////
                    Global STATE
    //////////////////////////////////////////////////////////////*/

    uint256 public constant  cooldown = 10 minutes;
    uint256 public immutable startingTime;

    bytes32 internal entropySauce;


    /*///////////////////////////////////////////////////////////////
                    ORC STATE
    //////////////////////////////////////////////////////////////*/

    ERC20 zug;

    mapping (uint256 => Orc)      public orcs;
    mapping (uint256 => Action)   public farming;
    mapping (uint256 => Action)   public training;
    mapping (uint256 => Action)   public activities;

    mapping (Places  => LootPool) public lootPools;

    /*///////////////////////////////////////////////////////////////
                DATA STRUCTURES 
    //////////////////////////////////////////////////////////////*/

    struct LootPool { 
        uint8  minLevel; uint8  minLootTier; uint8  cost;   uint16 total;
        uint16 tier_1;   uint16 tier_2;      uint16 tier_3; uint16 tier_4;
    }

    struct Orc {
        uint8  body;     uint8  head;    uint16 helm; 
        uint16 mainhand; uint16 offhand; uint16 level;
    }


    enum Actions { NOTHING, FARMING, TRAINING }
    struct Action { address owner; uint88 timestamp; Actions action; }

    // These are all the places you can go search for loot
    enum Places { 
        TOWN,    DUNGEON,  CRYPT, CASTLE,     DRAGONS_LAIR,    THE_ETHER, 
        ORC_GOD, TAINTED_KINGDOM, OOZING_DEN, ANCIENT_CHAMBER, DEMONS_LAIR 
    }   

    /*///////////////////////////////////////////////////////////////
                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(address inventory) ERC721("Ether Orcs", "ORC", inventory) {

        // Here's whats available in each place
        LootPool memory town           = LootPool({ minLevel: 1,  minLootTier:  1, cost:   0, total: 8910, tier_1: 5850, tier_2: 2550, tier_3: 810, tier_4:   0 });
        LootPool memory dungeon        = LootPool({ minLevel: 3,  minLootTier:  2, cost:   0, total: 7425, tier_1: 4875, tier_2: 1875, tier_3: 675, tier_4:   0 });
        LootPool memory crypt          = LootPool({ minLevel: 6,  minLootTier:  3, cost:   0, total: 5940, tier_1: 3900, tier_2: 1500, tier_3: 540, tier_4:   0 }); 
        LootPool memory castle         = LootPool({ minLevel: 12, minLootTier:  4, cost:   0, total: 2790, tier_1: 1950, tier_2:  750, tier_3: 270, tier_4:   0 });
        LootPool memory dragonsLair    = LootPool({ minLevel: 20, minLootTier:  5, cost:   0, total: 2790, tier_1: 1950, tier_2:  750, tier_3: 270, tier_4:   0 });
        LootPool memory theEther       = LootPool({ minLevel: 24, minLootTier:  6, cost:   0, total: 2184, tier_1: 1575, tier_2:  405, tier_3: 204, tier_4:   0 });
        LootPool memory orcGod         = LootPool({ minLevel: 26, minLootTier: 10, cost:   0, total:    5, tier_1:    5, tier_2:    0, tier_3:   0, tier_4:   0 });
        LootPool memory taintedKingdom = LootPool({ minLevel: 12, minLootTier:  4, cost:  20, total:  400, tier_1:  100, tier_2:  100, tier_3: 100, tier_4: 100 });
        LootPool memory oozingDen      = LootPool({ minLevel: 20, minLootTier:  5, cost:  20, total:  400, tier_1:  100, tier_2:  100, tier_3: 100, tier_4: 100 });
        LootPool memory acientChamber  = LootPool({ minLevel: 30, minLootTier:  9, cost:  30, total:  300, tier_1:  300, tier_2:    0, tier_3:   0, tier_4:   0 });
        LootPool memory demonsLair     = LootPool({ minLevel: 40, minLootTier: 10, cost: 100, total:    5, tier_1:    5, tier_2:    0, tier_3:   0, tier_4:   0 });

        lootPools[Places.TOWN]            = town;
        lootPools[Places.DUNGEON]         = dungeon;
        lootPools[Places.CRYPT]           = crypt;
        lootPools[Places.CASTLE]          = castle;
        lootPools[Places.DRAGONS_LAIR]    = dragonsLair;
        lootPools[Places.THE_ETHER]       = theEther;
        lootPools[Places.ORC_GOD]         = orcGod;
        lootPools[Places.TAINTED_KINGDOM] = taintedKingdom;
        lootPools[Places.OOZING_DEN]      = oozingDen;
        lootPools[Places.ANCIENT_CHAMBER] = acientChamber;
        lootPools[Places.DEMONS_LAIR]     = demonsLair;

        startingTime = block.timestamp + 0 hours; // There's 4 hours of no actions

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

    function mint() external noCheaters {
        uint256 cost = _getMintingPrice();
        uint256 rand = _rand();

        if (cost > 0) zug.burn(msg.sender, cost);
        _mintOrc(rand);
    }

    function doAction(uint256 id, Actions action_) public ownerOfOrc(id) noCheaters {
        _transfer(msg.sender, address(this), id);
        
        activities[id] = Action({
            owner: msg.sender, action: action_,
            timestamp: uint88(block.timestamp > startingTime ? block.timestamp : startingTime) 
        });
    }

    function doActions(uint256[] calldata ids, Actions action_) external {
        for (uint256 index = 0; index < ids.length; index++) {
            doAction(ids[index], action_);
        }
    }

    // Are those two functions really needed?
    function farm(uint256 id) public {
        doAction(id, Actions.FARMING);
    }

    function train(uint256 id) public {
        doAction(id, Actions.TRAINING);
    }

    function stopAction(uint256 id) public ownerOfOrc(id) noCheaters {
        require(activities[id].action != Actions.NOTHING);

        _transfer(address(this), farming[id].owner, id);
        claim(id);

        activities[id].action = Actions.NOTHING;
    }

    function claim(uint256 id) public noCheaters {
        Orc memory orc = orcs[id];

        uint256 timeDiff = uint256(block.timestamp - activities[id].timestamp);

        if (activities[id].action == Actions.FARMING) {
            uint256 farmingRate   = 4;
            uint256 dailyEmission = (farmingRate + _tier(orc.helm) + _tier(orc.mainhand) + _tier(orc.offhand)) * 1 ether;
            uint256 zugAmount     = timeDiff * dailyEmission / 1 days;

            zug.mint(ownerOf[id], zugAmount);
        }
        if (activities[id].action == Actions.TRAINING) {
            uint256 levelingRate    = 2;
            orcs[id].level        += uint16(timeDiff * levelingRate / 1 days);
        }

        activities[id].timestamp = uint88(block.timestamp);
    }

    function farmToTrain(uint256 id) external ownerOfOrc(id) noCheaters {
        stopAction(id);
        train(id);
    } 

    function trainToFarm(uint256 id) external  ownerOfOrc(id) noCheaters {
        stopAction(id);
        farm(id);
    }

    function pillage(uint256 id, Places place, bool tryHelm, bool tryMainhand, bool tryOffhand) public ownerOfOrc(id) noCheaters {        
        require(block.timestamp - uint256(activities[id].timestamp) > cooldown);
        if (place == Places.ORC_GOD ||place == Places.DEMONS_LAIR) require(_tier(orcs[id].mainhand) < 10);

        claim(id); // Need to claim to not have equipment reatroactively multiplying
        
        uint256 rand_ = _rand();
        
        LootPool memory pool = lootPools[place];
         
        if (pool.cost > 0) zug.burn(msg.sender, pool.cost);

        uint16 item;
        if (tryHelm) {
            ( pool, item ) = _getItemFromPool(pool, _randomize(rand_,"HELM"));
            if (item != 0 ) orcs[id].helm = item;
        }
        if (tryMainhand) {
            ( pool, item ) = _getItemFromPool(pool, _randomize(rand_,"MAINHAND"));
            if (item != 0 ) orcs[id].mainhand = item;
        }
        if (tryOffhand) {
            ( pool, item ) = _getItemFromPool(pool, _randomize(rand_,"OFFHAND"));
            if (item != 0 ) orcs[id].offhand = item;
        }

        lootPools[place] = pool;
        
    } 

    // function getSVG(uint256 id) public view returns(string memory) {
    //     // Orcs memory orc = orcs[id]; 


    //     return string(abi.encodePacked(
    //         inventory.header, 
    //         inventory.head,
    //         inventory.body,
    //         inventory.helm,
    //         inventory.mainhand,
    //         inventory.offhand,
    //         inventory.footer 
    //     ));

    //     //get header
    //     //get body
    //     //get head
    //     //get helm
    //     //get mainnhand
    //     //get offhand
    //     //get leveland zug multipler
    //     //get footer
    // }


    /*///////////////////////////////////////////////////////////////
                    MINT FUNCTION
    //////////////////////////////////////////////////////////////*/

    function _mintOrc(uint256 rand) internal returns (uint16 id) {

        // Helpers to get Percentages
        uint256 ninetyPct    = type(uint16).max / 100 * 90;
        uint256 nineFivePct  = type(uint16).max / 100 * 95;
        uint256 nineEightPct = type(uint16).max / 100 * 98;

        // Getting Random traits
        uint8  body = uint8(_randomize(rand, "BODY")) % 5 + 1;
        uint8  head = uint8(_randomize(rand, "HEAD")) % 5 + 1;

        uint16 randHelm = uint16(_randomize(rand, "HELM"));
        uint16 helm     = randHelm < nineFivePct ? 0 : randHelm % 4 + 1;

        uint16 randOffhand = uint16(_randomize(rand, "OFFHAND"));
        uint16 offhand     = randOffhand < nineFivePct ? 0 : randOffhand % 4 + 1;

        uint16 randMainhand = uint16(_randomize(rand, "MAINHAND"));
        uint16 mainhand     = randMainhand > nineEightPct ? randMainhand % 4 + 9 :
                              randMainhand > ninetyPct    ? randMainhand % 4 + 5 : randMainhand % 4 + 1;

        id = uint16(totalSupply + 1);

        _mint(msg.sender, id);
        
        orcs[uint256(id)] = Orc({body: body, head: head, helm: helm, mainhand: mainhand, offhand: offhand, level: 0});
    }

    /*///////////////////////////////////////////////////////////////
                    INTERNAL  HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @dev take an available item from a pool
    function _getItemFromPool(LootPool memory pool, uint256 rand) internal pure returns (LootPool memory updatedPool, uint16 item) {
        if (rand > pool.tier_1 + pool.tier_2 + pool.tier_3){
            item = uint16((rand % pool.tier_4 + 1) * pool.minLootTier);     
            pool.tier_4--;
        }

        if(rand > pool.tier_1 + pool.tier_2) {
            item = uint16((rand % pool.tier_3 + 1) * pool.minLootTier);
            pool.tier_3--;
        }

        if(rand > pool.tier_1) {
            item = uint16((rand % pool.tier_2 + 1) * pool.minLootTier);
            pool.tier_2--;
        }

        if (pool.tier_1 > 0){
            item = uint16((rand % pool.tier_1 + 1) * pool.minLootTier);
            pool.tier_1--;
        }
        updatedPool = pool;
    }

    /// @dev Convert an id to its tier
    function _tier(uint16 id) internal pure returns (uint256) {
        return (id / 4 ) + 1;
    }

    /// @dev Create a bit more of randomness
    function _randomize(uint256 rand, string memory val) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(rand, val)));
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
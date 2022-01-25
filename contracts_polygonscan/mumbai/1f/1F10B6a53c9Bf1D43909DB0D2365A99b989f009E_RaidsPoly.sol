/**
 *Submitted for verification at polygonscan.com on 2022-01-24
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: Unlicense
pragma solidity 0.8.7;

interface OrcishLike {
    function pull(address owner, uint256[] calldata ids) external;
    function manuallyAdjustOrc(uint256 id, uint8 body, uint8 helm, uint8 mainhand, uint8 offhand, uint16 level, uint16 zugModifier, uint32 lvlProgress) external;
    function transfer(address to, uint256 tokenId) external;
    function orcs(uint256 id) external view returns(uint8 body, uint8 helm, uint8 mainhand, uint8 offhand, uint16 level, uint16 zugModifier, uint32 lvlProgress);
    function allies(uint256 id) external view returns (uint8 class, uint16 level, uint32 lvlProgress, uint16 modF, uint8 skillCredits, bytes22 details);
    function adjustAlly(uint256 id, uint8 class_, uint16 level_, uint32 lvlProgress_, uint16 modF_, uint8 skillCredits_, bytes22 details_) external;
    function claim(uint256[] calldata ids) external;
}

interface PortalLike {
    function sendMessage(bytes calldata message_) external;
}

interface OracleLike {
    function request() external returns (uint64 key);
    function getRandom(uint64 id) external view returns(uint256 rand);
}

interface MetadataHandlerLike {
    function getTokenURI(uint16 id, uint8 body, uint8 helm, uint8 mainhand, uint8 offhand, uint16 level, uint16 zugModifier) external view returns (string memory);
}

interface MetadataHandlerAllies {
    function getTokenURI(uint256 id_, uint256 class_, uint256 level_, uint256 modF_, uint256 skillCredits_, bytes22 details_) external view returns (string memory);
}

interface RaidsLike {
    function stakeManyAndStartCampaign(uint256[] calldata ids_, address owner_, uint256 location_, bool double_) external;
    function startCampaignWithMany(uint256[] calldata ids, uint256 location_, bool double_) external;
    function commanders(uint256 id) external returns(address);
    function unstake(uint256 id) external;
}

interface RaidsLikePoly {
    function stakeManyAndStartCampaign(uint256[] calldata ids_, address owner_, uint256 location_, bool double_, uint256[] calldata potions_) external;
    function startCampaignWithMany(uint256[] calldata ids, uint256 location_, bool double_,  uint256[] calldata potions_) external;
    function commanders(uint256 id) external returns(address);
    function unstake(uint256 id) external;
}

interface CastleLike {
    function pullCallback(address owner, uint256[] calldata ids) external;
}

interface EtherOrcsLike {
    function ownerOf(uint256 id) external view returns (address owner_);
    function activities(uint256 id) external view returns (address owner, uint88 timestamp, uint8 action);
    function orcs(uint256 orcId) external view returns (uint8 body, uint8 helm, uint8 mainhand, uint8 offhand, uint16 level, uint16 zugModifier, uint32 lvlProgress);
}

interface ERC20Like {
    function balanceOf(address from) external view returns(uint256 balance);
    function burn(address from, uint256 amount) external;
    function mint(address from, uint256 amount) external;
    function transfer(address to, uint256 amount) external;
}

interface ERC1155Like {
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
    function mint(address to, uint256 id, uint256 amount) external;
    function burn(address from, uint256 id, uint256 amount) external;
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes memory _data) external;
}

interface ERC721Like {
    function transferFrom(address from, address to, uint256 id) external;   
    function transfer(address to, uint256 id) external;
    function ownerOf(uint256 id) external returns (address owner);
    function mint(address to, uint256 tokenid) external;
}

interface HallOfChampionsLike {
    function joined(uint256 orcId) external view returns (uint256 joinDate);
} 

interface AlliesLike {
    function allies(uint256 id) external view returns (uint8 class, uint16 level, uint32 lvlProgress, uint16 modF, uint8 skillCredits, bytes22 details);
}


/** 
 *  SourceUnit: /home/jgcarv/Dev/NFT/Orcs/etherOrcs-contracts/src/polygon/RaidsPoly.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: Unlicense
pragma solidity 0.8.7;

////import "../interfaces/Interfaces.sol";

contract RaidsPoly {

    /*///////////////////////////////////////////////////////////////
                   STORAGE SLOTS  
    //////////////////////////////////////////////////////////////*/

    address        implementation_;
    address public admin; 

    ERC721Like          public orcs;
    ERC20Like           public zug;
    ERC20Like           public boneShards;
    HallOfChampionsLike public hallOfChampions;

    mapping (uint256 => Raid)     public locations;
    mapping (uint256 => Campaign) public campaigns;
    mapping (uint256 => address)  public commanders;

    uint256 public giantCrabHealth;
    uint256 public dbl_discount;

    bytes32 internal entropySauce;

    ERC721Like  allies;
    ERC1155Like items;

    address vendor;
    address gamingOracle;

    uint256 seedCounter;

    uint256 public constant HND_PCT = 10_000; // Probabilities are given in a scale from 0 - 10_000, where 10_000 == 100% and 0 == 0%
    uint256 public constant VND_PCT = 500;
    uint256 public constant POTION_ID = 1; 

    // All that in a single storage slot. Fuck yeah!
    struct Raid {
        uint16 minLevel;  uint16 maxLevel;  uint16 duration; uint16 cost;
        uint16 grtAtMin;  uint16 grtAtMax;  uint16 supAtMin; uint16 supAtMax;
        uint16 regReward; uint16 grtReward; uint16 supReward;uint16 minPotions; uint16 maxPotions; // Rewards are scale down to 100(= 1BS & 1=0.01) to fit uint16. 
    }    

    struct Campaign { uint8 location; bool double; uint64 end; uint112 reward; uint64 seed; }

    event BossHit(uint256 orcId, uint256 damage, uint256 remainingHealth);

    /*///////////////////////////////////////////////////////////////
                   Admin Functions 
    //////////////////////////////////////////////////////////////*/

    function initialize(address orcs_, address zug_, address boneShards_, address hallOfChampions_) external {
        require(msg.sender == admin, "not auth");
        
        orcs            = ERC721Like(orcs_);
        zug             = ERC20Like(zug_);
        boneShards      = ERC20Like(boneShards_);
        hallOfChampions = HallOfChampionsLike(hallOfChampions_);

        // Creating starting locations
        Raid memory giantCrabBeach = Raid({
            minLevel: 5, maxLevel: 15,   duration:  192, cost:      65,  grtAtMin:  1500, grtAtMax: 3500, 
            supAtMin: 0, supAtMax: 1500, regReward: 200, grtReward: 300, supReward: 500, minPotions: 0, maxPotions:4});

        Raid memory pirateCove = Raid({
            minLevel: 15, maxLevel: 30,   duration:  192,  cost:     150, grtAtMin:  1500, grtAtMax: 3500, 
            supAtMin: 0,  supAtMax: 1500, regReward: 500, grtReward: 800, supReward: 1200, minPotions: 0, maxPotions:4});

        Raid memory spiderDen = Raid({
            minLevel: 15, maxLevel: 30,   duration:  192,  cost:     175, grtAtMin:  1500, grtAtMax: 3500, 
            supAtMin: 0,  supAtMax: 1500, regReward: 400, grtReward: 800, supReward: 2000, minPotions: 0, maxPotions:4});

        Raid memory unstableQuagmire = Raid({
            minLevel: 30, maxLevel: 50,   duration:  192,  cost:      250,  grtAtMin:  1500, grtAtMax: 3500, 
            supAtMin: 0,  supAtMax: 1500, regReward: 1200, grtReward: 1500, supReward: 2300, minPotions: 0, maxPotions:4});

        Raid memory merfolkFortress = Raid({
            minLevel: 50, maxLevel: 75,   duration:  192,  cost:      300,  grtAtMin:  1500, grtAtMax: 3500, 
            supAtMin: 0,  supAtMax: 1500, regReward: 1600, grtReward: 2000, supReward: 3000, minPotions: 0, maxPotions:4});

        locations[0] = giantCrabBeach;
        locations[1] = pirateCove;
        locations[2] = spiderDen;
        locations[3] = unstableQuagmire;
        locations[4] = merfolkFortress;
    }

     function init(address allies_, address vendor_, address potions_, address orcl) external {
        require(msg.sender == admin);

        //disable all old raids
        locations[0].cost = type(uint16).max;
        locations[1].cost = type(uint16).max;
        locations[2].cost = type(uint16).max;
        locations[3].cost = type(uint16).max;
        locations[4].cost = type(uint16).max;

        Raid memory crookedCrabBeach = Raid({ minLevel:  5, maxLevel: 5,  duration:  48, cost: 60, grtAtMin: 0, grtAtMax: 0, supAtMin: 400, supAtMax: 400, regReward: 100, grtReward: 100, supReward: 3000, minPotions: 0, maxPotions: 0});
        Raid memory twistedPirateCove = Raid({ minLevel:  15, maxLevel: 25,  duration:  30, cost: 45, grtAtMin: 0, grtAtMax: 0, supAtMin: 200, supAtMax: 400, regReward: 100, grtReward: 100, supReward: 2000, minPotions: 0, maxPotions: 0});
        Raid memory warpedSpiderDen = Raid({ minLevel:  25, maxLevel: 35,  duration:  72, cost: 110, grtAtMin: 1000, grtAtMax: 1500, supAtMin: 0, supAtMax: 500, regReward: 200, grtReward: 1000, supReward: 3000, minPotions: 0, maxPotions: 1});
        Raid memory toxicQuagmire = Raid({ minLevel:  45, maxLevel: 45,  duration:  96, cost: 230, grtAtMin: 0, grtAtMax: 0, supAtMin: 0, supAtMax: 0, regReward: 1100, grtReward: 1100, supReward: 1300, minPotions: 1, maxPotions: 1});
        Raid memory evilMerfolkCastle = Raid({ minLevel:  50, maxLevel: 75,  duration:  144, cost: 320, grtAtMin: 1500, grtAtMax: 3000, supAtMin: 200, supAtMax: 1500, regReward: 1200, grtReward: 1800, supReward: 3200, minPotions: 3, maxPotions: 3});

        Raid memory werewolf = Raid({ minLevel:  90, maxLevel: 90,  duration:  144, cost: 85, grtAtMin: 1500, grtAtMax: 2500, supAtMin: 500, supAtMax: 1500, regReward: 300, grtReward: 500, supReward: 1000, minPotions: 0, maxPotions: 4});
        Raid memory frenziedSpiderlord = Raid({ minLevel:  100, maxLevel: 125,  duration:  144, cost: 230, grtAtMin: 1500, grtAtMax: 2500, supAtMin: 500, supAtMax: 1500, regReward: 800, grtReward: 1600, supReward: 2800, minPotions: 0, maxPotions: 4});
        Raid memory leviathan = Raid({ minLevel:  150, maxLevel: 175,  duration:  216, cost: 350, grtAtMin: 1500, grtAtMax: 2500, supAtMin: 500, supAtMax: 1500, regReward: 1000, grtReward: 2600, supReward: 6000, minPotions: 4, maxPotions: 6});
        Raid memory lavaTitan = Raid({ minLevel:  190, maxLevel: 200,  duration:  216, cost: 265, grtAtMin: 1500, grtAtMax: 2500, supAtMin: 500, supAtMax: 2000, regReward: 1200, grtReward: 1800, supReward: 2600, minPotions: 6, maxPotions: 6});

        locations[5] = crookedCrabBeach;
        locations[6] = twistedPirateCove;
        locations[7] = warpedSpiderDen;
        locations[8] = toxicQuagmire;
        locations[9] = evilMerfolkCastle; 
        locations[10] = werewolf;
        locations[11] = frenziedSpiderlord;
        locations[12] = leviathan;
        locations[13] = lavaTitan;

        giantCrabHealth = 400000;
        dbl_discount    = 200;

        allies       = ERC721Like(allies_);
        items      = ERC1155Like(potions_);
        gamingOracle = orcl;
        vendor       = vendor_;
    }

    /*///////////////////////////////////////////////////////////////
                   PUBLIC FUNCTIONS 
    //////////////////////////////////////////////////////////////*/

    function unstake(uint256 orcishId) public {
        Campaign memory cmp = campaigns[orcishId];

        require(msg.sender == (orcishId < 5051 ? address(orcs) : address(allies)), "Not orcs contract");
        require(_ended(campaigns[orcishId]),   "Still raiding");

        if (cmp.reward > 0) _claim(orcishId);

        if (orcishId < 5051) {
            orcs.transfer(commanders[orcishId], orcishId);
        } else {
            allies.transfer(commanders[orcishId], orcishId);
        }

        delete commanders[orcishId];
        delete campaigns[orcishId]; 
    }

    function claim(uint256[] calldata ids) external {
        for (uint256 i = 0; i < ids.length; i++) {
            _claim(ids[i]);
        }
        _updateEntropy();
    }   

    function stakeManyAndStartCampaign(uint256[] calldata ids_, address owner_, uint256 location_, bool double_, uint256[] calldata potions_) external {
        for (uint256 i = 0; i < ids_.length; i++) {
            _stake(ids_[i], owner_);
            _startCampaign(ids_[i], location_, double_, potions_[i]);
        }
        _updateEntropy();
    }

    function startCampaignWithMany(uint256[] calldata ids, uint256 location_, bool double_, uint256[] calldata potions_) external {
        for (uint256 i = 0; i < ids.length; i++) {
            _startCampaign(ids[i], location_, double_, potions_[i]);
        }
        _updateEntropy();
    } 

    /*///////////////////////////////////////////////////////////////
                   INTERNAl HELPERS  
    //////////////////////////////////////////////////////////////*/

    function _claim(uint256 id) internal {
        Campaign memory cmp = campaigns[id]; 

        if (cmp.reward > 0 && _ended(campaigns[id])) {
            uint256 reward = cmp.reward;
            if (cmp.seed != 0) {
                // New case - calculate the result from seed
                Raid memory raid = locations[cmp.location];
                uint16 level     = _getLevel(id);
                uint256 rdn      = OracleLike(gamingOracle).getRandom(cmp.seed);
                
                require(rdn != 0, "no random value yet");

                reward = _getReward(raid, id, level, rdn, "RAID") + (cmp.double ? _getReward(raid, id, level, rdn, "DOUBLE RAID") : 0);
                _foundSomething(raid, cmp, id, level, rdn);
            } 
            campaigns[id].reward = 0;
            boneShards.mint(commanders[id], reward);
        }
    } 

    function _stake(uint256 id, address owner) internal {
        require(commanders[id] == address(0), "already Staked");
        require(msg.sender == (id < 5051 ? address(orcs) : address(allies)));
        require((id < 5051 ? orcs.ownerOf(id) : allies.ownerOf(id)) == address(this), "orc not transferred");

        commanders[id] = owner;
    }

    function _startCampaign(uint orcishId, uint256 location_, bool double, uint256 potions_) internal {
        Raid memory raid = locations[location_];
        address owner = commanders[orcishId];

        require(potions_ <= (double ? raid.maxPotions * 2 : raid.maxPotions), "too much potions");
        require(potions_ >= (double ? raid.minPotions * 2 : raid.minPotions), "too much potions");
        require(msg.sender == (orcishId < 5051 ? address(orcs) : address(allies)), "Not allowed");
        require(_ended(campaigns[orcishId]),   "Currently on campaign");

        if (campaigns[orcishId].reward > 0) _claim(orcishId);

        require(_getLevel(orcishId) >= raid.minLevel, "below min level");

        uint256 zugAmount = uint256(raid.cost) * 1 ether;
        uint256 duration  = raid.duration;
        uint112 reward    = raid.regReward;
         
        campaigns[orcishId].double = false;
        
        if (double) {
            uint256 totalCost = zugAmount * 2;
            zugAmount  = totalCost - (totalCost * dbl_discount / HND_PCT);
            reward    += raid.regReward;
            duration  += raid.duration;

            campaigns[orcishId].double = true;
        }
        _distributeZug(owner, zugAmount);

        if(potions_ > 0) {
            items.burn(owner, POTION_ID, potions_ * 1 ether);
            duration -= potions_ * 24;
        }

        campaigns[orcishId].location  = uint8(location_);
        campaigns[orcishId].reward   += reward;
        campaigns[orcishId].end       = uint64(block.timestamp + (duration * 1 hours));
        campaigns[orcishId].seed      = requestSeed();

        _attackBoss(orcishId);
    }   

    function _distributeZug(address owner, uint256 amount) internal {
        uint256 vendorAmt = amount * VND_PCT / HND_PCT;
        zug.burn(owner, amount);
        zug.mint(vendor, vendorAmt);
    }

    function _updateEntropy() internal {
        entropySauce = keccak256(abi.encodePacked(tx.origin, block.coinbase));
    }

    function _ended(Campaign memory cmp) internal view returns(bool) {
        return cmp.end == 0 || block.timestamp > (giantCrabHealth == 0 ? cmp.end - (cmp.double ? 2 days : 1 days) : cmp.end);
    }

    function requestSeed() internal returns(uint64 seed) {
        return OracleLike(gamingOracle).request();
    }

    function _getReward(Raid memory raid, uint256 orcId, uint16 orcLevel, uint256 ramdom, string memory salt) internal view returns(uint176 reward) {
        uint256 rdn = uint256(keccak256(abi.encode(ramdom, orcId, salt))) % 10_000 + 1;

        uint256 champBonus = _getChampionBonus(uint16(orcId));

        uint256 greatProb  = _getBaseOutcome(raid.minLevel, raid.maxLevel, raid.grtAtMin, raid.grtAtMax, orcLevel) + _getLevelBonus(raid.maxLevel, orcLevel) + champBonus;
        uint256 superbProb = _getBaseOutcome(raid.minLevel, raid.maxLevel, raid.supAtMin, raid.supAtMax, orcLevel) + champBonus;

        reward = uint176(rdn <= superbProb ? raid.supReward  : rdn <= greatProb + superbProb ? raid.grtReward : raid.regReward) * 1e16;
    }

    function _getLevel(uint256 id) internal view returns(uint16 level) {
        if (id < 5051) {
            (,,,, level,,) = EtherOrcsLike(address(orcs)).orcs(id);
        } else {
            (,level,,,,) = AlliesLike(address(allies)).allies(id);
        }
    }

    function _getBaseOutcome(uint256 minLevel, uint256 maxLevel, uint256 minProb, uint256 maxProb, uint256 orcishLevel) internal pure returns(uint256 prob) {
        orcishLevel = orcishLevel > maxLevel ? maxLevel : orcishLevel;
        prob = minProb + ((orcishLevel - minLevel) * (maxProb - minProb)/(maxLevel == minLevel ? 1 : (maxLevel - minLevel))) ;
    }

    function _getLevelBonus(uint256 maxLevel, uint256 orcishLevel) internal pure returns (uint256 prob){
        if(orcishLevel <= maxLevel) return 0;
        if (orcishLevel <= maxLevel + 20) return ((orcishLevel - maxLevel) * HND_PCT / 20 * 500) / HND_PCT;
        prob = 500;
    }

    function _getChampionBonus(uint16 id) internal view returns (uint256 bonus){
        bonus =  HallOfChampionsLike(hallOfChampions).joined(id) > 0 ? 100 : 0;
    }

    function _attackBoss(uint256 id) internal {
        uint256 damage = _randomize(_rand(), "ATTACK", id) % 2000;
        giantCrabHealth = damage >= giantCrabHealth ? 0 : giantCrabHealth - damage;
        emit BossHit(id, damage, giantCrabHealth);
    }

    function _foundSomething(Raid memory raid, Campaign memory cmp, uint256 orcId, uint16 orcLevel, uint256 ramdom) internal {
        uint256 rdn1 = uint256(keccak256(abi.encode(ramdom, orcId, "RAID"))) % 10_000 + 1;
        uint256 rdn2 = cmp.double ? (uint256(keccak256(abi.encode(ramdom, orcId, "DOUBLE RAID"))) % 10_000 + 1) : type(uint256).max;

        if (cmp.location == 13) {
            uint256 supOutcome = _getBaseOutcome(raid.minLevel, raid.maxLevel, raid.supAtMin, raid.supAtMax, orcLevel);
            uint256 bal = items.balanceOf(address(this), 99);
            if (rdn1 <= supOutcome && bal > 0) items.safeTransferFrom(address(this), commanders[orcId], 99, 1, new bytes(0));
            if (rdn2 <= supOutcome && bal > 1) items.safeTransferFrom(address(this), commanders[orcId], 99, 1, new bytes(0));
        } 
    }

    function _randomize(uint256 rand, string memory val, uint256 spicy) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(rand, val, spicy)));
    }

    function _rand() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.timestamp, entropySauce)));
    }

}
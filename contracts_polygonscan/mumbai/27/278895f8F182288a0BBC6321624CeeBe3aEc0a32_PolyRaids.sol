/**
 *Submitted for verification at polygonscan.com on 2021-12-07
*/

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

contract PolyRaids {

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

    ERC721Like allies;
    ERC20Like  potions;

    address vendor;

    uint256 public constant HND_PCT = 10_000; // Probabilities are given in a scale from 0 - 10_000, where 10_000 == 100% and 0 == 0%
    uint256 public constant VND_PCT = 5_000;

    // All that in a single storage slot. Fuck yeah!
    struct Raid {
        uint16 minLevel;  uint16 maxLevel;  uint16 duration; uint16 cost;
        uint16 grtAtMin;  uint16 grtAtMax;  uint16 supAtMin; uint16 supAtMax;
        uint16 regReward; uint16 grtReward; uint16 supReward;uint16 minPotions; uint16 maxPotions; // Rewards are scale down to 100(= 1BS & 1=0.01) to fit uint16. 
    }    

    struct Campaign { uint8 location; bool double; uint64 end; uint176 reward; }

    event BossHit(uint256 orcId, uint256 damage, uint256 remainingHealth);

    /*///////////////////////////////////////////////////////////////
                   Admin Functions 
    //////////////////////////////////////////////////////////////*/

    function init(address allies_, address vendor_, address potions_) external {
        require(msg.sender == admin);

        locations[0].maxPotions = 4;
        locations[1].maxPotions = 4;
        locations[2].maxPotions = 4;
        locations[3].maxPotions = 4;
        locations[4].maxPotions = 4;

        Raid memory crookedCrabBeach = Raid({ minLevel: 5, maxLevel: 5, duration: 48, cost: 60, grtAtMin: 0, grtAtMax: 0, supAtMin: 400, supAtMax: 400, regReward: 100, grtReward: 100, supReward: 3000, minPotions: 0, maxPotions: 0});
        Raid memory twistedPirateCove = Raid({ minLevel: 15, maxLevel: 25, duration: 30, cost: 45, grtAtMin: 0, grtAtMax: 0, supAtMin: 200, supAtMax: 400, regReward: 100, grtReward: 100, supReward: 2000, minPotions: 0, maxPotions: 0});
        Raid memory warpedSpiderDen = Raid({ minLevel: 25, maxLevel: 35, duration: 72, cost: 90, grtAtMin: 1000, grtAtMax: 1500, supAtMin: 0, supAtMax: 500, regReward: 200, grtReward: 1000, supReward: 3000, minPotions: 0, maxPotions: 1});
        Raid memory toxicQuagmire = Raid({ minLevel: 45, maxLevel: 45, duration: 96, cost: 170, grtAtMin: 1500, grtAtMax: 0, supAtMin: 0, supAtMax: 0, regReward: 1100, grtReward: 1200, supReward: 1300, minPotions: 1, maxPotions: 1});
        Raid memory evilMerfolkCastle = Raid({ minLevel: 50, maxLevel: 75, duration: 144, cost: 225, grtAtMin: 1500, grtAtMax: 3000, supAtMin: 200, supAtMax: 1500, regReward: 1200, grtReward: 1800, supReward: 3200, minPotions: 2, maxPotions: 2});

        locations[5] = crookedCrabBeach;
        locations[6] = twistedPirateCove;
        locations[7] = warpedSpiderDen;
        locations[8] = toxicQuagmire;
        locations[9] = evilMerfolkCastle; 

        giantCrabHealth = 400000;
        dbl_discount    = 1_000;

        vendor  = vendor_;
        potions = ERC20Like(potions_);
        allies  = ERC721Like(allies_);
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
            campaigns[id].reward = 0;
            boneShards.mint(commanders[id], cmp.reward);
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

        uint256 level = _getLevel(orcishId);
        
        require(level >= raid.minLevel, "below min level");

        uint256 zugAmount = uint256(raid.cost) * 1 ether;
        uint256 duration  = raid.duration;

        uint176 reward  = _getReward(raid, orcishId, uint16(level), "RAID");
         
        campaigns[orcishId].double = false;
        
        if (double) {
            uint256 totalCost = zugAmount * 2;
            zugAmount  = totalCost - (totalCost * dbl_discount / HND_PCT);
            reward    += _getReward(raid, orcishId, uint16(level), "DOUBLE_RAID");
            duration  += raid.duration;

            campaigns[orcishId].double = true;
        }
        
        _distributeZug(owner, zugAmount);
        potions.burn(owner, potions_ * 1 ether);

        campaigns[orcishId].location  = uint8(location_);
        campaigns[orcishId].reward   += reward;
        campaigns[orcishId].end       = uint64(block.timestamp + (duration * 1 hours));

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

    function _getReward(Raid memory raid, uint256 orcId, uint16 orcLevel, string memory salt) internal view returns(uint176 reward) {
        uint256 rdn = (_randomize(_rand(), salt, orcId) % 10_000) + 1;
        uint256 champBonus = _getChampionBonus(uint16(orcId));

        uint256 greatProb  = _getBaseOutcome(raid.minLevel, raid.maxLevel, raid.grtAtMin, raid.grtAtMax, orcLevel) + _getLevelBonus(raid.maxLevel, orcLevel) + champBonus;
        uint256 superbProb = _getBaseOutcome(raid.minLevel, raid.maxLevel, raid.supAtMin, raid.supAtMax, orcLevel) + champBonus;

        reward = uint176(rdn <= superbProb ? raid.supReward  : rdn <= greatProb + superbProb ? raid.grtReward : raid.regReward) * 1e16;
    }

    function _getLevel(uint256 id) internal view returns(uint16 level) {
        if (id < 5051) {
            (,,,, level,,) = EtherOrcLike(address(orcs)).orcs(id);
        } else {
            (,level,,,,,,,,) = AlliesLike(address(allies)).shamans(id);
        }
    }

    function _getBaseOutcome(uint256 minLevel, uint256 maxLevel, uint256 minProb, uint256 maxProb, uint256 orcishLevel) internal pure returns(uint256 prob) {
        orcishLevel = orcishLevel > maxLevel ? maxLevel : orcishLevel;
        prob = minProb + ((orcishLevel - minLevel)  * HND_PCT / (maxLevel - minLevel) * (maxProb - minProb)) / HND_PCT;
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

    function _randomize(uint256 rand, string memory val, uint256 spicy) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(rand, val, spicy)));
    }

    function _rand() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.timestamp, entropySauce)));
    }

}

interface ERC20Like {
    function burn(address from, uint256 amount) external;
    function mint(address from, uint256 amount) external;
}

interface ERC721Like {
    function transferFrom(address from, address to, uint256 id) external;   
    function transfer(address to, uint256 id) external;
    function ownerOf(uint256 id) external returns (address owner);
}

interface EtherOrcLike {
    function orcs(uint256 orcId) external view returns (uint8 body, uint8 helm, uint8 mainhand, uint8 offhand, uint16 level, uint16 zugModifier, uint32 lvlProgress);
} 

interface AlliesLike {
    function shamans(uint256 id) external view returns (uint8 skillCredits, uint16 level, uint32 lvlProgress, uint8 body, uint8 featA, uint8 featB, uint8 helm, uint8 mainhand, uint8 offhand, uint16 herbalism);
}

interface HallOfChampionsLike {
    function joined(uint256 orcId) external view returns (uint256 joinDate);
}
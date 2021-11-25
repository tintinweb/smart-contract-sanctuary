/**
 *Submitted for verification at polygonscan.com on 2021-11-24
*/

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

contract Raids {

    /*///////////////////////////////////////////////////////////////
                   STORAGE SLOTS  
    //////////////////////////////////////////////////////////////*/

    address        implementation_;
    address public admin; 

    ERC721Like          public orcs;
    ERC20Like           public zug;
    ERC20Like           public boneShards;
    HallOfChampionsLike public hallOfChampions;

    mapping (uint256 => Raid)         public locations;
    mapping (uint256 => Campaign)     public campaigns;
    mapping (uint256 => address)      public commanders;

    uint256 public giantCrabHealth = 4000000;
    uint256 public dbl_discount = 1_000;  // 10% Discount on cost for Double Raids

    bytes32 internal entropySauce;

    uint256 public constant HND_PCT = 10_000; // Probabilities are given in a scale from 0 - 10_000, where 10_000 == 100% and 0 == 0%


    // All that in a single storage slot. Fuck yeah!
    struct Raid {
        uint16 minLevel;  uint16 maxLevel;  uint16 duration; uint16 cost;
        uint16 grtAtMin;  uint16 grtAtMax;  uint16 supAtMin; uint16 supAtMax;
        uint16 regReward; uint16 grtReward; uint16 supReward; // Rewards are scale down to 100(= 1BS & 1=0.01) to fit uint16. 
    }    

    struct Campaign { uint8 location; bool double; uint64 end; uint176 reward; }

    event BossHit(uint256 orcId, uint256 damage, uint256 remainingHealth);

    /*///////////////////////////////////////////////////////////////
                   Admin Functions 
    //////////////////////////////////////////////////////////////*/

    function initialize(address orcs_, address zug_, address boneShards_, address hallOfChampions_) external {
        orcs            = ERC721Like(orcs_);
        zug             = ERC20Like(zug_);
        boneShards      = ERC20Like(boneShards_);
        hallOfChampions = HallOfChampionsLike(hallOfChampions_);

        // Creating starting locations
        Raid memory giantCrabBeach = Raid({
            minLevel: 5, maxLevel: 15,   duration:  192, cost:      65,  grtAtMin:  1500, grtAtMax: 3500, 
            supAtMin: 0, supAtMax: 1500, regReward: 200, grtReward: 300, supReward: 500});

        Raid memory pirateCove = Raid({
            minLevel: 15, maxLevel: 30,   duration:  192,  cost:     150, grtAtMin:  1500, grtAtMax: 3500, 
            supAtMin: 0,  supAtMax: 1500, regReward: 500, grtReward: 800, supReward: 1200});

        Raid memory spiderDen = Raid({
            minLevel: 15, maxLevel: 30,   duration:  192,  cost:     175, grtAtMin:  1500, grtAtMax: 3500, 
            supAtMin: 0,  supAtMax: 1500, regReward: 400, grtReward: 800, supReward: 2000});

        Raid memory unstableQuagmire = Raid({
            minLevel: 30, maxLevel: 50,   duration:  192,  cost:      250,  grtAtMin:  1500, grtAtMax: 3500, 
            supAtMin: 0,  supAtMax: 1500, regReward: 1200, grtReward: 1500, supReward: 2300});

        Raid memory merfolkFortress = Raid({
            minLevel: 50, maxLevel: 75,   duration:  192,  cost:      300,  grtAtMin:  1500, grtAtMax: 3500, 
            supAtMin: 0,  supAtMax: 1500, regReward: 1600, grtReward: 2000, supReward: 3000});

        locations[0] = giantCrabBeach;
        locations[1] = pirateCove;
        locations[2] = spiderDen;
        locations[3] = unstableQuagmire;
        locations[4] = merfolkFortress;
    }

    function addLocation(
        uint256 id, uint16 minLevel_,  uint16 maxLevel_,  uint16 duration_, uint16 cost_, uint16 grtAtMin_, uint16 grtAtMax_,
        uint16 supAtMin_, uint16 supAtMax_, uint16 regReward_, uint16 grtReward_, uint16 supReward_) external 
    {

        Raid memory raid = Raid({
            minLevel:  minLevel_,  maxLevel:  maxLevel_,  duration:  duration_, cost:     cost_,  
            grtAtMin:  grtAtMin_,  grtAtMax:  grtAtMax_,  supAtMin:  supAtMin_, supAtMax: supAtMax_,
            regReward: regReward_, grtReward: grtReward_, supReward: supReward_});

        locations[id] = raid;
    }

    /*///////////////////////////////////////////////////////////////
                   PUBLIC FUNCTIONS 
    //////////////////////////////////////////////////////////////*/

    function unstake(uint256 orcId) public {
        Campaign memory cmp = campaigns[orcId];

        require(msg.sender == address(orcs), "Not orcs contract");
        require(_ended(campaigns[orcId]),   "Still raiding");

        if (cmp.reward > 0) _claim(orcId);

        orcs.transfer(commanders[orcId], orcId);

        delete commanders[orcId];
        delete campaigns[orcId]; 
    }

    function claim(uint256[] calldata ids) external {
        for (uint256 i = 0; i < ids.length; i++) {
            _claim(ids[i]);
        }
        _updateEntropy();
    }   

    function stakeManyAndStartCampaign(uint256[] calldata ids_, address owner_, uint256 location_, bool double_) external {
        for (uint256 i = 0; i < ids_.length; i++) {
            _stake(ids_[i], owner_);
            // _startCampaign(ids_[i], location_, double_);
        }
        _updateEntropy();
    }

    function startCampaignWithMany(uint256[] calldata ids, uint256 location_, bool double_) external {
        for (uint256 i = 0; i < ids.length; i++) {
            // _startCampaign(ids[i], location_, double_);
        }
        _updateEntropy();
    } 

    /*///////////////////////////////////////////////////////////////
                   INTERNAl HELPERS  
    //////////////////////////////////////////////////////////////*/

    function _claim(uint256 orcId) internal {
        Campaign memory cmp = campaigns[orcId]; 

        if (cmp.reward > 0 && _ended(campaigns[orcId])) {
            campaigns[orcId].reward = 0;
            boneShards.mint(commanders[orcId], cmp.reward);
        }
    } 

    function _stake(uint256 orcId, address owner) internal {
        require(commanders[orcId] == address(0), "already Staked");
        require(msg.sender == address(orcs));
        require(orcs.ownerOf(orcId) == address(this), "orc not transferred");

        commanders[orcId] = owner;
    }

    function _startCampaign(uint orcId, uint256 location_,bool double) internal {
        Raid memory raid = locations[location_];
        
        address owner = commanders[orcId];
        require(msg.sender == address(orcs), "Not allowed");
        require(_ended(campaigns[orcId]),   "Currently on campaign");

        if (campaigns[orcId].reward > 0) _claim(orcId);

        (,,,,uint256 orcLevel,,) = EtherOrcLike(address(orcs)).orcs(orcId);
        
        require(orcLevel >= raid.minLevel, "below min level");

        uint256 zugAmount = uint256(raid.cost) * 1 ether;
        uint256 duration  = raid.duration;

        uint176 reward  = _getReward(raid, orcId, uint16(orcLevel), "RAID");
         
        campaigns[orcId].double = false;
        
        if (double) {
            uint256 totalCost = zugAmount * 2;
            zugAmount  = totalCost - (totalCost * dbl_discount / HND_PCT);
            reward    += _getReward(raid, orcId, uint16(orcLevel), "DOUBLE_RAID");
            duration  += raid.duration;

            campaigns[orcId].double = true;
        }
        
        zug.burn(owner, zugAmount);

        campaigns[orcId].location  = uint8(location_);
        campaigns[orcId].reward   += reward;
        campaigns[orcId].end       = uint64(block.timestamp + (duration * 1 hours));

        _attackBoss(orcId);
    }   

    function _updateEntropy() internal {
        entropySauce = keccak256(abi.encodePacked(tx.origin, block.coinbase));
    }

    function _ended(Campaign memory cmp) internal view returns(bool) {
        return block.timestamp > (giantCrabHealth == 0 ? cmp.end - (cmp.double ? 2 days : 1 days) : cmp.end);
    }

    function _getReward(Raid memory raid, uint256 orcId, uint16 orcLevel, string memory salt) internal view returns(uint176 reward) {
        uint256 rdn = (_randomize(_rand(), salt, orcId) % 10_000) + 1;
        uint256 champBonus = _getChampionBonus(uint16(orcId));

        uint256 greatProb  = _getBaseOutcome(raid.minLevel, raid.maxLevel, raid.grtAtMin, raid.grtAtMax, orcLevel) + _getLevelBonus(raid.maxLevel, orcLevel) + champBonus;
        uint256 superbProb = _getBaseOutcome(raid.minLevel, raid.maxLevel, raid.supAtMin, raid.supAtMax, orcLevel) + champBonus;

        reward = uint176(rdn <= superbProb ? raid.supReward  : rdn <= greatProb + superbProb ? raid.grtReward : raid.regReward) * 1e16;
    }


    function _getBaseOutcome(uint256 minLevel, uint256 maxLevel, uint256 minProb, uint256 maxProb, uint256 orcLevel) internal pure returns(uint256 prob) {
        orcLevel = orcLevel > maxLevel ? maxLevel : orcLevel;
        prob = minProb + ((orcLevel - minLevel)  * HND_PCT / (maxLevel - minLevel) * (maxProb - minProb)) / HND_PCT;
    }

    function _getLevelBonus(uint256 maxLevel, uint256 orcLevel) internal pure returns (uint256 prob){
        if(orcLevel <= maxLevel) return 0;
        if (orcLevel <= maxLevel + 20) return ((orcLevel - maxLevel) * HND_PCT / 20 * 500) / HND_PCT;
        prob = 500;
    }

    function _getChampionBonus(uint16 orcId) internal view returns (uint256 bonus){
        bonus =  HallOfChampionsLike(hallOfChampions).joined(orcId) > 0 ? 100 : 0;
    }

    function _attackBoss(uint256 orcId) internal {
        uint256 damage = _randomize(_rand(), "ATTACK", orcId) % 100000;
        giantCrabHealth = damage >= giantCrabHealth ? 0 : giantCrabHealth - damage;
        emit BossHit(orcId, damage, giantCrabHealth);
    }

    function _randomize(uint256 rand, string memory val, uint256 spicy) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(rand, val, spicy)));
    }

    function _rand() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.basefee, block.timestamp, entropySauce)));
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

interface HallOfChampionsLike {
    function joined(uint256 orcId) external view returns (uint256 joinDate);
}
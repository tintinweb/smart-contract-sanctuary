/**
 *Submitted for verification at polygonscan.com on 2021-12-13
*/

/** 
 *  SourceUnit: /home/jgcarv/Dev/NFT/Orcs/etherOrcs-contracts/src/testnet/MumbaiAllies.sol
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
}

interface PortalLike {
    function sendMessage(bytes calldata message_) external;
}

interface OracleLike {
    function seedFor(uint256 blc) external view returns(bytes32 hs);
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
    function mint(address to, uint256 id, uint256 amount) external;
    function burn(address from, uint256 id, uint256 amount) external;
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
 *  SourceUnit: /home/jgcarv/Dev/NFT/Orcs/etherOrcs-contracts/src/testnet/MumbaiAllies.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: AGPL-3.0-only
pragma solidity 0.8.7;

/// @notice Modern and gas efficient ERC-721 + ERC-20/EIP-2612-like implementation,
/// including the MetaData, and partially, Enumerable extensions.
contract PolyERC721 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    
    event Approval(address indexed owner, address indexed spender, uint256 indexed tokenId);
    
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/
    
    address        implementation_;
    address public admin; //Lame requirement from opensea
    
    /*///////////////////////////////////////////////////////////////
                             ERC-721 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;
    uint256 public oldSupply;
    uint256 public minted;
    
    mapping(address => uint256) public balanceOf;
    
    mapping(uint256 => address) public ownerOf;
        
    mapping(uint256 => address) public getApproved;
 
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                             VIEW FUNCTION
    //////////////////////////////////////////////////////////////*/

    function owner() external view returns (address) {
        return admin;
    }
    
    /*///////////////////////////////////////////////////////////////
                              ERC-20-LIKE LOGIC
    //////////////////////////////////////////////////////////////*/
    
    // function transfer(address to, uint256 tokenId) external {
    //     require(msg.sender == ownerOf[tokenId], "NOT_OWNER");
        
    //     _transfer(msg.sender, to, tokenId);
        
    // }
    
    /*///////////////////////////////////////////////////////////////
                              ERC-721 LOGIC
    //////////////////////////////////////////////////////////////*/
    
    function supportsInterface(bytes4 interfaceId) external pure returns (bool supported) {
        supported = interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
    }
    
    // function approve(address spender, uint256 tokenId) external {
    //     address owner_ = ownerOf[tokenId];
        
    //     require(msg.sender == owner_ || isApprovedForAll[owner_][msg.sender], "NOT_APPROVED");
        
    //     getApproved[tokenId] = spender;
        
    //     emit Approval(owner_, spender, tokenId); 
    // }
    
    // function setApprovalForAll(address operator, bool approved) external {
    //     isApprovedForAll[msg.sender][operator] = approved;
        
    //     emit ApprovalForAll(msg.sender, operator, approved);
    // }

    // function transferFrom(address, address to, uint256 tokenId) public {
    //     address owner_ = ownerOf[tokenId];
        
    //     require(
    //         msg.sender == owner_ 
    //         || msg.sender == getApproved[tokenId]
    //         || isApprovedForAll[owner_][msg.sender], 
    //         "NOT_APPROVED"
    //     );
        
    //     _transfer(owner_, to, tokenId);
        
    // }
    
    // function safeTransferFrom(address, address to, uint256 tokenId) external {
    //     safeTransferFrom(address(0), to, tokenId, "");
    // }
    
    // function safeTransferFrom(address, address to, uint256 tokenId, bytes memory data) public {
    //     transferFrom(address(0), to, tokenId); 
        
    //     if (to.code.length != 0) {
    //         // selector = `onERC721Received(address,address,uint,bytes)`
    //         (, bytes memory returned) = to.staticcall(abi.encodeWithSelector(0x150b7a02,
    //             msg.sender, address(0), tokenId, data));
                
    //         bytes4 selector = abi.decode(returned, (bytes4));
            
    //         require(selector == 0x150b7a02, "NOT_ERC721_RECEIVER");
    //     }
    // }
    
    /*///////////////////////////////////////////////////////////////
                          INTERNAL UTILS
    //////////////////////////////////////////////////////////////*/

    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf[tokenId] == from, "not owner");

        balanceOf[from]--; 
        balanceOf[to]++;
        
        delete getApproved[tokenId];
        
        ownerOf[tokenId] = to;
        emit Transfer(from, to, tokenId); 

    }

    function _mint(address to, uint256 tokenId) internal { 
        require(ownerOf[tokenId] == address(0), "ALREADY_MINTED");

        uint supply = oldSupply + minted;
        uint maxSupply = 5050;
        require(supply <= maxSupply, "MAX SUPPLY REACHED");
        totalSupply++;
                
        // This is safe because the sum of all user
        // balances can't exceed type(uint256).max!
        unchecked {
            balanceOf[to]++;
        }
        
        ownerOf[tokenId] = to;
                
        emit Transfer(address(0), to, tokenId); 
    }
    
    function _burn(uint256 tokenId) internal { 
        address owner_ = ownerOf[tokenId];
        
        require(ownerOf[tokenId] != address(0), "NOT_MINTED");
        
        totalSupply--;
        balanceOf[owner_]--;
        
        delete ownerOf[tokenId];
                
        emit Transfer(owner_, address(0), tokenId); 
    }
}




/** 
 *  SourceUnit: /home/jgcarv/Dev/NFT/Orcs/etherOrcs-contracts/src/testnet/MumbaiAllies.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: Unlicense
pragma solidity 0.8.7;

////import "./PolyERC721.sol"; 

////import "../interfaces/Interfaces.sol";

contract EtherOrcsAlliesPoly is PolyERC721 {

    mapping(uint256 => Ally)     public allies;
    mapping(address => bool)     public auth;
    mapping(uint256 => Action)   public activities;
    mapping(uint256 => Location) public locations;
    mapping(uint256 => Journey)  public journeys;

    ERC20Like   zug;
    ERC20Like   boneShards;
    ERC1155Like potions;

    MetadataHandlerAllies metadaHandler;

    address raids;
    address castle;
    address backupOracle;

    bytes32 internal entropySauce;


    uint256 public constant POTION_ID = 1; 

    // Action: 0 - Unstaked | 1 - Farming | 2 - Training
    struct Action  { address owner; uint88 timestamp; uint8 action; }

    struct Ally {uint8 class; uint16 level; uint32 lvlProgress; uint16 modF; uint8 skillCredits; bytes22 details;}

    struct Shaman {uint8 body; uint8 featA; uint8 featB; uint8 helm; uint8 mainhand; uint8 offhand;}

    struct Journey {uint128 blockSeed; uint64 location; uint64 equipment;}

    struct Location { 
        uint8  minLevel; uint8  skillCost; uint16  cost;
        uint8 tier_1Prob;uint8 tier_2Prob; uint8 tier_3Prob; uint tier_1; uint tier_2; uint8 tier_3; 
    }

    event ActionMade(address owner, uint256 id, uint256 timestamp, uint8 activity);

    /*///////////////////////////////////////////////////////////////
                    MODIFIERS 
    //////////////////////////////////////////////////////////////*/

    modifier noCheaters() {
        uint256 size = 0;
        address acc = msg.sender;
        assembly { size := extcodesize(acc)}

        require(auth[msg.sender] || (msg.sender == tx.origin && size == 0), "you're trying to cheat!");
        _;

        // We'll use the last caller hash to add entropy to next caller
        entropySauce = keccak256(abi.encodePacked(acc, block.coinbase));
    }

    modifier ownerOfAlly(uint256 id, address who_) { 
        require(ownerOf[id] == who_ || activities[id].owner == who_, "not your ally");
        _;
    }

    modifier isOwnerOfAlly(uint256 id) {
         require(ownerOf[id] == msg.sender || activities[id].owner == msg.sender, "not your ally");
        _;
    }

    /*///////////////////////////////////////////////////////////////
                    PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function initialize(address zug_, address shr_, address potions_, address raids_, address castle_, address backupOracle_) external {
        require(msg.sender == admin);

        zug          = ERC20Like(zug_);
        potions      = ERC1155Like(potions_);
        boneShards   = ERC20Like(shr_);
        raids        = raids_;
        castle       = castle_;
        backupOracle = backupOracle_;

        Location memory swampHealerHut    = Location({minLevel:25, skillCost: 5, cost:  0, tier_1Prob:88, tier_2Prob:10, tier_3Prob:2, tier_1:1, tier_2:2, tier_3:3});
        Location memory enchantedGrove    = Location({minLevel:31, skillCost: 5, cost:  0, tier_1Prob:50, tier_2Prob:40, tier_3Prob:10, tier_1:1, tier_2:2, tier_3:3});
        Location memory jungleHealerHut   = Location({minLevel:35, skillCost: 25, cost:  0, tier_1Prob:85, tier_2Prob:10, tier_3Prob:5, tier_1:3, tier_2:4, tier_3:5});
        Location memory monkTemple        = Location({minLevel:35, skillCost: 20, cost:  0, tier_1Prob:80, tier_2Prob:20, tier_3Prob:0, tier_1:2, tier_2:5, tier_3:5});
        Location memory forgottenDesert   = Location({minLevel:40, skillCost: 35, cost:  0, tier_1Prob:85, tier_2Prob:10, tier_3Prob:5, tier_1:4, tier_2:5, tier_3:6});
        Location memory moldyCitadel      = Location({minLevel:45, skillCost: 30, cost:  0, tier_1Prob:75, tier_2Prob:25, tier_3Prob:0, tier_1:3, tier_2:6, tier_3:6});
        Location memory swampEnchanterDen = Location({minLevel:55, skillCost: 45, cost:  200, tier_1Prob:40, tier_2Prob:60, tier_3Prob:0, tier_1:3, tier_2:6, tier_3:0});
        Location memory theFallsOfTruth   = Location({minLevel:55, skillCost: 45, cost:  200, tier_1Prob:70, tier_2Prob:30, tier_3Prob:0, tier_1:4, tier_2:7, tier_3:0});
        Location memory ethereanPlains    = Location({minLevel:60, skillCost: 50, cost:  200, tier_1Prob:80, tier_2Prob:15, tier_3Prob:5, tier_1:5, tier_2:6, tier_3:7});
        Location memory djinnOasis        = Location({minLevel:60, skillCost: 10, cost:  150, tier_1Prob:70, tier_2Prob:25, tier_3Prob:5, tier_1:2, tier_2:3, tier_3:4});
        Location memory spiritWorld       = Location({minLevel:70, skillCost: 60, cost:  300, tier_1Prob:30, tier_2Prob:30, tier_3Prob:40, tier_1:5, tier_2:6, tier_3:7});

        locations[0] = swampHealerHut;
        locations[1] = enchantedGrove;
        locations[2] = jungleHealerHut;
        locations[3] = monkTemple;
        locations[4] = forgottenDesert;
        locations[5] = moldyCitadel;
        locations[6] = swampEnchanterDen;
        locations[7] = theFallsOfTruth;
        locations[8] = ethereanPlains;
        locations[9] = djinnOasis;
        locations[10] = spiritWorld;
    }

    function setAuth(address add_, bool status) external {
        require(msg.sender == admin);
        auth[add_] = status;
    }

    function tokenURI(uint256 id) external view returns(string memory) {
        Ally memory ally = allies[id];
        return metadaHandler.getTokenURI(id, ally.class, ally.level, ally.modF, ally.skillCredits, ally.details);
    }

    function claimable(uint256 id) external view returns (uint256 amount) {
        uint256 timeDiff = block.timestamp > activities[id].timestamp ? uint256(block.timestamp - activities[id].timestamp) : 0;
        amount = activities[id].action == 1 ? _claimable(timeDiff, allies[id].modF) : timeDiff * 3000 / 1 days;
    }

    function transfer(address to, uint256 tokenId) external {
        require(auth[msg.sender], "not authorized");
        require(msg.sender == ownerOf[tokenId], "NOT_OWNER");
        
        _transfer(msg.sender, to, tokenId);
    }

    function doAction(uint256 id, uint8 action_) public ownerOfAlly(id, msg.sender) noCheaters {
       _doAction(id, msg.sender, action_, msg.sender);
    }

    function _doAction(uint256 id, address allyOwner, uint8 action_, address who_) internal ownerOfAlly(id, who_) {
        require(action_ < 3, "invalid action");
        Action memory action = activities[id];
        require(action.action != action_, "already doing that");

        uint88 timestamp = uint88(block.timestamp > action.timestamp ? block.timestamp : action.timestamp);

        if (action.action == 0)  _transfer(allyOwner, address(this), id);
     
        else {
            if (block.timestamp > action.timestamp) _claim(id);
            timestamp = timestamp > action.timestamp ? timestamp : action.timestamp;
        }

        address owner_ = action_ == 0 ? address(0) : allyOwner;
        if (action_ == 0) _transfer(address(this), allyOwner, id);

        activities[id] = Action({owner: owner_, action: action_,timestamp: timestamp});
        emit ActionMade(allyOwner, id, block.timestamp, uint8(action_));
    }

    function doActionWithManyAllies(uint256[] calldata ids, uint8 action_) external {
        for (uint256 index = 0; index < ids.length; index++) {
            _doAction(ids[index], msg.sender, action_, msg.sender);
        }
    }

    function startJourneyWithManyAllies(uint256[] calldata ids, uint8 place, uint8 equipment) external {
        for (uint256 index = 0; index < ids.length; index++) {
            startJourney(ids[index], place, equipment);
        }
    }

    function endJourneyWithManyAllies(uint256[] calldata ids, uint8 place, uint8 equipment) external {
        for (uint256 index = 0; index < ids.length; index++) {
            endJourney(ids[index]);
        }
    }

    function claim(uint256[] calldata ids) external {
        for (uint256 index = 0; index < ids.length; index++) {
            _claim(ids[index]);
        }
    }

    function _claim(uint256 id) internal noCheaters {
        Action memory action = activities[id];
        Ally   memory ally   = allies[id];

        if(block.timestamp <= action.timestamp) return;

        uint256 timeDiff = uint256(block.timestamp - action.timestamp);

        if (action.action == 1) potions.mint(action.owner, POTION_ID, _claimable(timeDiff, ally.modF));
       
        if (action.action == 2) {
            allies[id].lvlProgress += uint32(timeDiff * 3000 / 1 days);
            allies[id].level        = uint16(allies[id].lvlProgress / 1000);
        }

        activities[id].timestamp = uint88(block.timestamp);
    }

    function startJourney(uint256 id, uint8 place, uint8 equipment) public isOwnerOfAlly(id) noCheaters {
        require(equipment < 3, "invalid equipment");
        require(journeys[id].blockSeed == 0, "already ongoin journey");

        Ally     memory ally = allies[id];
        Location memory loc  = locations[place];

        require(ally.level >= uint16(loc.minLevel), "below minimum level");
        require(ally.class == 1, "only shaman can journey");
        
        allies[id].skillCredits -= loc.skillCost;
  
        if (loc.cost > 0) {
            zug.burn(msg.sender, uint256(loc.cost) * 1 ether);
        } 

        journeys[id] = Journey({blockSeed: uint128(block.number + 2), location: place, equipment: equipment});
    }

    function endJourney(uint256 id) public isOwnerOfAlly(id) noCheaters {
        Journey  memory jrn = journeys[id];
        Shaman   memory shm = _shaman(allies[id].details);
        Location memory loc  = locations[jrn.location];

        require(block.number > jrn.blockSeed, "too soon");
        if(activities[id].timestamp < block.timestamp) _claim(id); // Need to claim to not have equipment reatroactively multiplying


        bytes22 newDetails = _equipShaman(shm,loc,id,jrn.equipment, _blockhash(jrn.blockSeed));

        allies[id].details = newDetails;
        allies[id].modF    = _modF(newDetails);

        delete journeys[id];
    }

    function sendToRaid(uint256[] calldata ids, uint8 location_, bool double_,uint256[] calldata potions_) external noCheaters { 
        require(address(raids) != address(0), "raids not set");
        for (uint256 index = 0; index < ids.length; index++) {
            if (activities[ids[index]].action != 0) _doAction(ids[index], msg.sender, 0, msg.sender);
            _transfer(msg.sender, raids, ids[index]);
        }
        RaidsLikePoly(raids).stakeManyAndStartCampaign(ids, msg.sender, location_, double_,potions_ );
    }

    function startRaidCampaign(uint256[] calldata ids, uint8 location_, bool double_,  uint256[] calldata potions_) external noCheaters { 
        require(address(raids) != address(0), "raids not set");
        for (uint256 index = 0; index < ids.length; index++) {
            require(msg.sender == RaidsLikePoly(raids).commanders(ids[index]) && ownerOf[ids[index]] == address(raids), "not staked or not your orc");
        }
        RaidsLikePoly(raids).startCampaignWithMany(ids, location_, double_, potions_);
    }

    function returnFromRaid(uint256[] calldata ids, uint8 action_) external noCheaters { 
        require(action_ < 3, "invalid action");
        RaidsLikePoly raidsContract = RaidsLikePoly(raids);
        for (uint256 index = 0; index < ids.length; index++) {
            require(msg.sender == raidsContract.commanders(ids[index]), "not your orc");
            raidsContract.unstake(ids[index]);
            if (action_ != 0) _doAction(ids[index], msg.sender, action_, msg.sender);
        }
    }

    function pull(address owner_, uint256[] calldata ids) external {
        require (msg.sender == castle, "not castle");
        for (uint256 index = 0; index < ids.length; index++) {
            if (activities[ids[index]].action != 0) _doAction(ids[index], owner_, 0, owner_);
            _transfer(owner_, msg.sender, ids[index]);
        }
        CastleLike(msg.sender).pullCallback(owner_, ids);
    }

    function adjustAlly(uint256 id, uint8 class_, uint16 level_, uint32 lvlProgress_, uint16 modF_, uint8 skillCredits_, bytes22 details_) external {
        require(auth[msg.sender], "not authorized");

        allies[id] = Ally({class: class_, level: level_, lvlProgress: lvlProgress_, modF: modF_, skillCredits: skillCredits_, details: details_});
    }

    function shamans(uint256 id) external view returns(uint16 level, uint32 lvlProgress, uint16 modF, uint8 skillCredits, uint8 body, uint8 featA, uint8 featB, uint8 helm, uint8 mainhand, uint8 offhand) {
        Ally memory ally = allies[id];
        level        = ally.level;
        lvlProgress  = ally.lvlProgress;
        modF         = ally.modF;
        skillCredits = ally.skillCredits;

        Shaman memory sh = _shaman(ally.details);
        body     = sh.body;
        featA    = sh.featA;
        featB    = sh.featB;
        helm     = sh.helm;
        mainhand = sh.mainhand;
        offhand  = sh.offhand;
    }

    function setMetadataHandler(address add) external {
        require(msg.sender == admin);
        metadaHandler = MetadataHandlerAllies(add);
    }

    /*///////////////////////////////////////////////////////////////
                    INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _shaman(bytes22 details) internal pure returns(Shaman memory sh) {
        uint8 body     = uint8(bytes1(details));
        uint8 featA    = uint8(bytes1(details << 8));
        uint8 featB    = uint8(bytes1(details << 16));
        uint8 helm     = uint8(bytes1(details << 24));
        uint8 mainhand = uint8(bytes1(details << 32));
        uint8 offhand  = uint8(bytes1(details << 40));

        sh.body     = body;
        sh.featA    = featA;
        sh.featB    = featB;
        sh.helm     = helm;
        sh.mainhand = mainhand;
        sh.offhand  = offhand;
    }

    function _equipShaman(Shaman memory sh, Location memory loc, uint256 id, uint256 equipment, bytes32 hs) internal pure returns(bytes22 details) {
        uint256 rdn = uint256(keccak256(abi.encode(hs, id)));
        uint8 item  = _getItem(loc, _randomize(rdn,"JOURNEY", id));

        if (equipment == 0) sh.helm = item;
        if (equipment == 1) sh.mainhand = item;
        if (equipment == 2) sh.offhand = item;

        details = bytes22(abi.encodePacked(sh.body, sh.featA, sh.featB, sh.helm, sh.mainhand, sh.offhand));
    }

    function _modF(bytes32 details_) internal pure returns (uint16 mod) {
        uint8 helm     = uint8(bytes1(details_ << 24));
        uint8 mainhand = uint8(bytes1(details_ << 32));
        uint8 offhand  = uint8(bytes1(details_ << 40));

        mod = _tier(helm) + _tier(mainhand) + _tier(offhand);
    }

    function _getItem(Location memory loc, uint256 rand) internal pure returns (uint8 item) {
        uint256 draw = uint256(rand % 100) + 1;

        uint8 tier = uint8(draw <= loc.tier_3Prob ? loc.tier_3 : draw <= loc.tier_2Prob + loc.tier_3Prob? loc.tier_2 : loc.tier_1);
        item = uint8(draw % _tierItems(tier) + _startForTier(tier));
    }

    function _claimable(uint256 timeDiff, uint256 herbalism_) internal pure returns (uint256 potionAmount) {
        potionAmount = timeDiff * (0.5 ether + (herbalism_ * 0.05 ether)) / 1 days;
    }

    function _tier(uint8 item) internal pure returns (uint8 tier) {
        if (item <= 7) return 0;
        if (item <= 12) return 1;
        if (item <= 18) return 2;
        if (item <= 25) return 3;
        if (item <= 32) return 4;
        if (item <= 38) return 5;
        if (item <= 44) return 6;
        return 7;
    } 

    function _tierItems(uint256 tier_) internal pure returns (uint256 numItems) {
        if (tier_ == 0) return 7;
        if (tier_ == 1) return 5;
        if (tier_ == 2) return 6;
        if (tier_ == 3) return 7;
        if (tier_ == 4) return 7;
        if (tier_ == 5) return 6;
        if (tier_ == 6) return 6;
        return 6;
    }

    function _startForTier(uint256 tier_) internal pure returns (uint256 start) {
        if (tier_ == 0) return 1;
        if (tier_ == 1) return 8;
        if (tier_ == 2) return 13;
        if (tier_ == 3) return 19;
        if (tier_ == 4) return 26;
        if (tier_ == 5) return 33;
        if (tier_ == 6) return 39;
        return 45;
    }

    function _blockhash(uint256 blc) internal view returns (bytes32 h) {
        h = (blc > block.number - 255 ? blockhash(blc) : OracleLike(backupOracle).seedFor(blc));
    }

    /// @dev Create a bit more of randomness
    function _randomize(uint256 rand, string memory val, uint256 spicy) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(rand, val, spicy)));
    }

    function _rand() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.timestamp, entropySauce)));
    }
}

/** 
 *  SourceUnit: /home/jgcarv/Dev/NFT/Orcs/etherOrcs-contracts/src/testnet/MumbaiAllies.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: Unlicense
pragma solidity 0.8.7;

////import "../polygon/EtherOrcsAlliesPoly.sol";

contract MumbaiAllies is EtherOrcsAlliesPoly {

    uint256 constant startId = 5050;

    function getItem(uint8 location, uint256 rand) external  view returns(uint8 item){
        item = _getItem(locations[location], rand);
    }

    function setZug(address z_) external {
        require(msg.sender == admin);
        zug = ERC20Like(z_);
    }

    function setCastle(address c_) external {
        require(msg.sender == admin);
        castle = c_;
    }

    function setRaids(address r_) external {
        require(msg.sender == admin);
        raids = r_;
    }

    function updateShaman(
        uint256 id,
        uint8 skillCredits_, 
        uint16 level_, 
        uint32 lvlProgress_, 
        uint8 body_, 
        uint8 featA_, 
        uint8 featB_, 
        uint8 helm_, 
        uint8 mainhand_, 
        uint8 offhand_, 
        uint16 herbalism_) external 
    {
        allies[id] = Ally({
            class: 1, 
            level: level_, 
            lvlProgress: lvlProgress_, 
            modF: herbalism_, 
            skillCredits: skillCredits_, 
            details: bytes22(abi.encodePacked(body_, featA_, featB_, helm_, mainhand_, offhand_))
        });
    }

    function initMint(address to, uint256 start, uint256 end) external {
        require(msg.sender == admin);
        for (uint256 i = start; i < end; i++) {
            _mint( to, i);
        }
    }

}
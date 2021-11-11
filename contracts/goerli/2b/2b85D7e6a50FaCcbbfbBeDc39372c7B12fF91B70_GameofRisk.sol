// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./ERC20.sol";
import "./ERC721.sol";
import "./Metadata.sol";


//                                                   (                      
//  (                                       (        )\ )                )  
//  )\ )        )      )       (            )\ )    (()/(   (         ( /(  
// (()/(     ( /(     (       ))\      (   (()/(     /(_))  )\   (    )\()) 
//  /(_))_   )(_))    )\  '  /((_)     )\   /(_))   (_))   ((_)  )\  ((_)\  
// (_)) __| ((_)_   _((_))  (_))      ((_) (_) _|   | _ \   (_) ((_) | |(_) 
//   | (_ | / _` | | '  \() / -_)    / _ \  |  _|   |   /   | | (_-< | / /  
//    \___| \__,_| |_|_|_|  \___|    \___/  |_|     |_|_\   |_| /__/ |_\_\  
//                                                                          

interface ListLike {
    function register(address buyer) external;
}

interface MetadataHandlerLike {
    function getTokenURI(uint16 id, uint8 water, uint8 tree, uint8 mountain, uint8 special, uint16 level, uint16 troopModifier, uint32 lvlProgress) external view returns (string memory);
}

contract GameofRisk is ERC721 {

    /*///////////////////////////////////////////////////////////////
                    Global STATE
    //////////////////////////////////////////////////////////////*/

    uint256 public constant  cooldown = 10 minutes;
    uint256 public immutable startingTime;
    uint256 public immutable mintingTime;
    address public           owner;

    bytes32 internal entropySauce;

    ERC20 public troop;

    mapping (uint256 => Land)     public land;
    mapping (uint256 => Action)   public activities;
    mapping (Places  => LootPool) public lootPools;

    MetadataHandlerLike metadaHandler;
    ListLike            list;

    function transferOwnership(address newOwner) external {
        require(msg.sender == owner, "not allowed");
        owner = newOwner;
    }

    function setAddresses(address meta) external {
        require(msg.sender == owner, "not allowed");
        metadaHandler = MetadataHandlerLike(meta);
    }

    function tokenURI(uint256 id) external view returns(string memory) {
        Land memory _land = land[id];
        // struct Land { uint8 water; uint8 tree; uint8 mountain; uint8 special; uint16 level; uint16 troopModifier; uint32 lvlProgress; }
        return metadaHandler.getTokenURI(uint16(id), _land.water, _land.tree, _land.mountain, _land.special, _land.level, _land.troopModifier, _land.lvlProgress);
    }

    
    event ActionMade(address owner, uint256 id, uint256 timestamp, uint8 activity);


    /*///////////////////////////////////////////////////////////////
                DATA STRUCTURES 
    //////////////////////////////////////////////////////////////*/

    struct LootPool { 
        uint8  minLevel; uint8  minLootTier; uint16  cost;   uint16 total;
        uint16 tier_1;   uint16 tier_2;      uint16 tier_3; uint16 tier_4;
    }

    struct Land { uint8 water; uint8 tree; uint8 mountain; uint8 special; uint16 level; uint16 troopModifier; uint32 lvlProgress; }

    enum   Actions { UNSTAKED, FARMING, TRAINING }
    struct Action  { address owner; uint88 timestamp; Actions action; }

    // These are all the places you can go search for loot
    // Change all of these
    // maybe use geography? 
    // maybe because first to get it all?
    // Africa. ...
    // Asia. ...
    // Caribbean. ...
    // Central America. ...
    // Europe. ...
    // North America. ...
    // Oceania. ...
    // South America. 
    enum Places { 
        TOWN, DUNGEON, CRYPT, CASTLE, DRAGONS_LAIR, THE_ETHER, 
        TAINTED_KINGDOM, OOZING_DEN, ANCIENT_CHAMBER, TROOP_GODS 
    }   

    /*///////////////////////////////////////////////////////////////
                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor( ) ERC721("Game of Risk", "TROOP") {

        // Here's whats available in each place
        LootPool memory town           = LootPool({ minLevel: 1,  minLootTier:  1, cost:   0, total: 1000, tier_1: 800,  tier_2: 150,  tier_3: 50,  tier_4:   0 });
        LootPool memory dungeon        = LootPool({ minLevel: 3,  minLootTier:  2, cost:   0, total: 1000, tier_1: 800,  tier_2: 150,  tier_3: 50,  tier_4:   0 });
        LootPool memory crypt          = LootPool({ minLevel: 6,  minLootTier:  3, cost:   0, total: 9000, tier_1: 4950, tier_2: 3600, tier_3: 450, tier_4:   0 }); 
        LootPool memory castle         = LootPool({ minLevel: 15, minLootTier:  4, cost:   0, total: 6000, tier_1: 3300, tier_2: 2400, tier_3: 300, tier_4:   0 });
        LootPool memory dragonsLair    = LootPool({ minLevel: 25, minLootTier:  5, cost:   0, total: 6000, tier_1: 3300, tier_2: 2400, tier_3: 300, tier_4:   0 });
        LootPool memory theEther       = LootPool({ minLevel: 36, minLootTier:  6, cost:   0, total: 3000, tier_1: 1200, tier_2: 1500, tier_3: 300, tier_4:   0 });
        LootPool memory taintedKingdom = LootPool({ minLevel: 15, minLootTier:  4, cost:  50, total:  600, tier_1:  150, tier_2:  150, tier_3: 150, tier_4: 150 });
        LootPool memory oozingDen      = LootPool({ minLevel: 25, minLootTier:  5, cost:  50, total:  600, tier_1:  150, tier_2:  150, tier_3: 150, tier_4: 150 });
        LootPool memory ancientChamber = LootPool({ minLevel: 45, minLootTier:  9, cost: 125, total:  225, tier_1:  225, tier_2:    0, tier_3:   0, tier_4:   0 });
        LootPool memory orcGods        = LootPool({ minLevel: 52, minLootTier: 10, cost: 300, total:   12, tier_1:    0, tier_2:    0, tier_3:   0, tier_4:   0 });

        lootPools[Places.TOWN]            = town;
        lootPools[Places.DUNGEON]         = dungeon;
        lootPools[Places.CRYPT]           = crypt;
        lootPools[Places.CASTLE]          = castle;
        lootPools[Places.DRAGONS_LAIR]    = dragonsLair;
        lootPools[Places.THE_ETHER]       = theEther;
        lootPools[Places.TAINTED_KINGDOM] = taintedKingdom;
        lootPools[Places.OOZING_DEN]      = oozingDen;
        lootPools[Places.ANCIENT_CHAMBER] = ancientChamber;
        lootPools[Places.TROOP_GODS]        = orcGods;

        mintingTime  = 1633951800;
        startingTime = 1633951800 + 4.5 hours;

        // Deploy Troop
        troop = new ERC20();
        troop.setMinter(address(this), true);
        troop.setRuler(address(msg.sender));

        owner = msg.sender;
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

    modifier ownerOfLand(uint256 id) { 
        require(ownerOf[id] == msg.sender || activities[id].owner == msg.sender, "not your land");
        _;
    }


    /*///////////////////////////////////////////////////////////////
                    PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function mint() public noCheaters returns (uint256 id) {
        require(block.timestamp >= mintingTime, "not open");

        uint256 cost = _getMintingPrice();
        uint256 rand = _rand();

        if (block.timestamp < startingTime) list.register(msg.sender);
        if (cost > 0) troop.burn(msg.sender, cost);

        return _mintLand(rand);
    }

    function doAction(uint256 id, Actions action_) public ownerOfLand(id) noCheaters {
        Action memory action = activities[id];
        require(action.action != action_, "already doing that");

        // Picking the largest value between block.timestamp, action.timestamp and startingTime
        uint88 timestamp = uint88(startingTime > (block.timestamp > action.timestamp ? block.timestamp : action.timestamp) ?
                                  startingTime : (block.timestamp > action.timestamp ? block.timestamp : action.timestamp));

        if (action.action == Actions.UNSTAKED)  _transfer(msg.sender, address(this), id);
     
        else {
            if (block.timestamp > action.timestamp) _claim(id);
            timestamp = timestamp > action.timestamp ? timestamp : action.timestamp;
        }

        if (action_ == Actions.UNSTAKED) _transfer(address(this), activities[id].owner, id);

        activities[id] = Action({owner: msg.sender, action: action_,timestamp: timestamp});
        emit ActionMade(msg.sender, id, block.timestamp, uint8(action_));
    }

    function doActionWithManyLands(uint256[] calldata ids, Actions action_) external {
        for (uint256 index = 0; index < ids.length; index++) {
            doAction(ids[index], action_);
        }
    }

    function claim(uint256[] calldata ids) external {
        for (uint256 index = 0; index < ids.length; index++) {
            _claim(ids[index]);
        }
    }

    function _claim(uint256 id) internal noCheaters {
        Land    memory _land    = land[id];
        Action memory action = activities[id];

        if(block.timestamp <= action.timestamp) return;

        uint256 timeDiff = uint256(block.timestamp - action.timestamp);

        if (action.action == Actions.FARMING) troop.mint(action.owner, claimableTroop(timeDiff, _land.troopModifier));
       
        if (action.action == Actions.TRAINING) {
            land[id].lvlProgress += uint16(timeDiff * 3000 / 1 days);
            land[id].level        = uint16(land[id].lvlProgress / 1000);
        }

        activities[id].timestamp = uint88(block.timestamp);
    }

    function pillage(uint256 id, Places place, bool tryTree, bool tryMountain, bool trySpecial) public ownerOfLand(id) noCheaters {
        require(block.timestamp >= uint256(activities[id].timestamp), "on cooldown");
        require(place != Places.TROOP_GODS,  "You can't pillage the Land God");

        if(activities[id].timestamp < block.timestamp) _claim(id); // Need to claim to not have equipment reatroactively multiplying

        uint256 rand_ = _rand();
  
        LootPool memory pool = lootPools[place];
        require(land[id].level >= uint16(pool.minLevel), "below minimum level");

        if (pool.cost > 0) {
            require(block.timestamp - startingTime > 14 days);
            troop.burn(msg.sender, uint256(pool.cost) * 1 ether);
        } 

        uint8 item;
        if (tryTree) {
            ( pool, item ) = _getItemFromPool(pool, _randomize(rand_,"TREE", id));
            if (item != 0 ) land[id].tree = item;
        }
        if (tryMountain) {
            ( pool, item ) = _getItemFromPool(pool, _randomize(rand_,"MAINHAND", id));
            if (item != 0 ) land[id].mountain = item;
        }
        if (trySpecial) {
            ( pool, item ) = _getItemFromPool(pool, _randomize(rand_,"OFFHAND", id));
            if (item != 0 ) land[id].special = item;
        }

        if (uint(place) > 1) lootPools[place] = pool;

        // Update troop modifier
        Land memory _land = land[id];
        uint16 troopModifier_ = _tier(_land.tree) + _tier(_land.mountain) + _tier(_land.special);

        land[id].troopModifier = troopModifier_;

        activities[id].timestamp = uint88(block.timestamp + cooldown);
    } 

    function update(uint256 id) public ownerOfLand(id) noCheaters {
        require(_tier(land[id].mountain) < 10);
        require(block.timestamp - startingTime >= 14 days);
        require(land[id].level >= 32);
        
        LootPool memory pool = lootPools[Places.TROOP_GODS];

        troop.burn(msg.sender, uint256(pool.cost) * 1 ether);

        _claim(id); // Need to claim to not have equipment reatroactively multiplying

        uint8 item = uint8(lootPools[Places.TROOP_GODS].total--);
        land[id].troopModifier = 30;
        land[id].water = land[id].tree = land[id].mountain = land[id].special = item + 40;
    }

    /*///////////////////////////////////////////////////////////////
                    VIEWERS
    //////////////////////////////////////////////////////////////*/

    function claimable(uint256 id) external view returns (uint256 amount) {
        uint256 timeDiff = uint256(block.timestamp - activities[id].timestamp);
        amount = activities[id].action == Actions.FARMING ? claimableTroop(timeDiff, land[id].troopModifier) : timeDiff * 2000 / 1 days;
    }

    /*///////////////////////////////////////////////////////////////
                    MINT FUNCTION
    //////////////////////////////////////////////////////////////*/

    function _mintLand(uint256 rand) internal returns (uint16 id) {
        (uint8 water,uint8 tree,uint8 mountain,uint8 special) = (0,0,0,0);
        {
            // Helpers to get Percentages
            uint256 sevenOnePct   = type(uint16).max / 100 * 75;
            uint256 eightyPct     = type(uint16).max / 100 * 80;
            uint256 nineFivePct   = type(uint16).max / 100 * 95;
            uint256 nineNinePct   = type(uint16).max / 100 * 99;
    
            id = uint16(totalSupply + 1);
    
            // Getting Random traits
            uint16 randWater = uint16(_randomize(rand, "WATER", id));
                   water     = uint8(randWater > nineNinePct ? randWater % 3 + 25 : 
                              randWater > sevenOnePct  ? randWater % 12 + 13 : randWater % 13 + 1 );
    
            uint16 randTree = uint16(_randomize(rand, "TREE", id));
                   tree     = uint8(randTree < eightyPct ? 0 : randTree % 4 + 5);
    
            uint16 randSpecial = uint16(_randomize(rand, "SPECIAL", id));
                   special     = uint8(randSpecial < eightyPct ? 0 : randSpecial % 4 + 5);
    
            uint16 randMountain = uint16(_randomize(rand, "MOUNTAIN", id));
                   mountain     = uint8(randMountain < nineFivePct ? randMountain % 4 + 1: randMountain % 4 + 5);
        }

        _mint(msg.sender, id);

        uint16 troopModifier = _tier(tree) + _tier(mountain) + _tier(special);
        land[uint256(id)] = Land({water: water, tree: tree, mountain: mountain, special: special, level: 0, lvlProgress: 0, troopModifier:troopModifier});
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

    function claimableTroop(uint256 timeDiff, uint16 troopModifier) internal pure returns (uint256 troopAmount) {
        troopAmount = timeDiff * (4 + troopModifier) * 1 ether / 1 days;
    }

    /// @dev Convert an id to its tier
    function _tier(uint16 id) internal pure returns (uint16) {
        if (id == 0) return 0;
        return ((id - 1) / 4 );
    }

    /// @dev Create a bit more of randomness
    function _randomize(uint256 rand, string memory val, uint256 spicy) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(rand, val, spicy)));
    }

    function _rand() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.basefee, block.timestamp, entropySauce)));
    }

    function _getMintingPrice() internal view returns (uint256) {
        if (totalSupply < 1550) return   0;
        if (totalSupply < 2050) return   4 ether;
        if (totalSupply < 2550) return   8 ether;
        if (totalSupply < 3050) return  12 ether;
        if (totalSupply < 3550) return  24 ether;
        if (totalSupply < 4050) return  40 ether;
        if (totalSupply < 4550) return  60 ether;
        if (totalSupply < 5050) return 130 ether;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.7;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// Taken from Solmate: https://github.com/Rari-Capital/solmate

contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public constant name     = "TROOP";
    string public constant symbol   = "TROOP";
    uint8  public constant decimals = 18;

    /*///////////////////////////////////////////////////////////////
                             ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => bool) public isMinter;

    address public ruler;

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    constructor() { ruler = msg.sender;}

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);

        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        balanceOf[msg.sender] -= value;

        // This is safe because the sum of all user
        // balances can't exceed type(uint256).max!
        unchecked {
            balanceOf[to] += value;
        }

        emit Transfer(msg.sender, to, value);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] -= value;
        }

        balanceOf[from] -= value;

        // This is safe because the sum of all user
        // balances can't exceed type(uint256).max!
        unchecked {
            balanceOf[to] += value;
        }

        emit Transfer(from, to, value);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                             ORC PRIVILEGE
    //////////////////////////////////////////////////////////////*/

    function mint(address to, uint256 value) external {
        require(isMinter[msg.sender], "FORBIDDEN TO MINT");
        _mint(to, value);
    }

    function burn(address from, uint256 value) external {
        require(isMinter[msg.sender], "FORBIDDEN TO BURN");
        _burn(from, value);
    }

    /*///////////////////////////////////////////////////////////////
                         Ruler Function
    //////////////////////////////////////////////////////////////*/

    function setMinter(address minter, bool status) external {
        require(msg.sender == ruler, "NOT ALLOWED TO RULE");

        isMinter[minter] = status;
    }

    function setRuler(address ruler_) external {
        require(msg.sender == ruler ||ruler == address(0), "NOT ALLOWED TO RULE");

        ruler = ruler_;
    }


    /*///////////////////////////////////////////////////////////////
                          INTERNAL UTILS
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 value) internal {
        totalSupply += value;

        // This is safe because the sum of all user
        // balances can't exceed type(uint256).max!
        unchecked {
            balanceOf[to] += value;
        }

        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] -= value;

        // This is safe because a user won't ever
        // have a balance larger than totalSupply!
        unchecked {
            totalSupply -= value;
        }

        emit Transfer(from, address(0), value);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.7;


/// @notice Modern and gas efficient ERC-721 + ERC-20/EIP-2612-like implementation,
/// including the MetaData, and partially, Enumerable extensions.
contract ERC721 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    
    event Approval(address indexed owner, address indexed spender, uint256 indexed tokenId);
    
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/
    
    string public name;
    
    string public symbol;
    
    /*///////////////////////////////////////////////////////////////
                             ERC-721 STORAGE
    //////////////////////////////////////////////////////////////*/
    
    uint256 public totalSupply;
    
    mapping(address => uint256) public balanceOf;
    
    mapping(uint256 => address) public ownerOf;
        
    mapping(uint256 => address) public getApproved;
 
    mapping(address => mapping(address => bool)) public isApprovedForAll;
    
    constructor(
        string memory _name,
        string memory _symbol
    ) {
        name = _name;
        symbol = _symbol;
    }
    
    /*///////////////////////////////////////////////////////////////
                              ERC-20-LIKE LOGIC
    //////////////////////////////////////////////////////////////*/
    
    function transfer(address to, uint256 tokenId) external {
        require(msg.sender == ownerOf[tokenId], "NOT_OWNER");
        
        _transfer(msg.sender, to, tokenId);
        
    }
    
    /*///////////////////////////////////////////////////////////////
                              ERC-721 LOGIC
    //////////////////////////////////////////////////////////////*/
    
    function supportsInterface(bytes4 interfaceId) external pure returns (bool supported) {
        supported = interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
    }
    
    function approve(address spender, uint256 tokenId) external {
        address owner = ownerOf[tokenId];
        
        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_APPROVED");
        
        getApproved[tokenId] = spender;
        
        emit Approval(owner, spender, tokenId); 
    }
    
    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;
        
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address, address to, uint256 tokenId) public {
        address owner = ownerOf[tokenId];
        
        require(
            msg.sender == owner 
            || msg.sender == getApproved[tokenId]
            || isApprovedForAll[owner][msg.sender], 
            "NOT_APPROVED"
        );
        
        _transfer(owner, to, tokenId);
        
    }
    
    function safeTransferFrom(address, address to, uint256 tokenId) external {
        safeTransferFrom(address(0), to, tokenId, "");
    }
    
    function safeTransferFrom(address, address to, uint256 tokenId, bytes memory data) public {
        transferFrom(address(0), to, tokenId); 
        
        if (to.code.length != 0) {
            // selector = `onERC721Received(address,address,uint,bytes)`
            (, bytes memory returned) = to.staticcall(abi.encodeWithSelector(0x150b7a02,
                msg.sender, address(0), tokenId, data));
                
            bytes4 selector = abi.decode(returned, (bytes4));
            
            require(selector == 0x150b7a02, "NOT_ERC721_RECEIVER");
        }
    }
    
    
    /*///////////////////////////////////////////////////////////////
                          INTERNAL UTILS
    //////////////////////////////////////////////////////////////*/

    function _transfer(address from, address to, uint256 tokenId) internal {
        balanceOf[from]--; 
        balanceOf[to]++;
        
        delete getApproved[tokenId];
        
        ownerOf[tokenId] = to;
        emit Transfer(msg.sender, to, tokenId); 

    }

    function _mint(address to, uint256 tokenId) internal { 
        require(ownerOf[tokenId] == address(0), "ALREADY_MINTED");

        uint maxSupply = 5050;
        require(totalSupply++ <= maxSupply, "MAX SUPPLY REACHED");
                
        // This is safe because the sum of all user
        // balances can't exceed type(uint256).max!
        unchecked {
            balanceOf[to]++;
        }
        
        ownerOf[tokenId] = to;
                
        emit Transfer(address(0), to, tokenId); 
    }
    
    function _burn(uint256 tokenId) internal { 
        address owner = ownerOf[tokenId];
        
        require(ownerOf[tokenId] != address(0), "NOT_MINTED");
        
        totalSupply--;
        balanceOf[owner]--;
        
        delete ownerOf[tokenId];
                
        emit Transfer(owner, address(0), tokenId); 
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

//                                                   (                      
//  (                                       (        )\ )                )  
//  )\ )        )      )       (            )\ )    (()/(   (         ( /(  
// (()/(     ( /(     (       ))\      (   (()/(     /(_))  )\   (    )\()) 
//  /(_))_   )(_))    )\  '  /((_)     )\   /(_))   (_))   ((_)  )\  ((_)\  
// (_)) __| ((_)_   _((_))  (_))      ((_) (_) _|   | _ \   (_) ((_) | |(_) 
//   | (_ | / _` | | '  \() / -_)    / _ \  |  _|   |   /   | | (_-< | / /  
//    \___| \__,_| |_|_|_|  \___|    \___/  |_|     |_|_\   |_| /__/ |_\_\  
//                                                                          



contract Metadata {

    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
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

    // struct Land { uint8 water; uint8 tree; uint8 mountain; uint8 special; uint16 level; uint16 troopModifier; uint32 lvlProgress; }
    function getTokenURI(uint16 id, uint8 water, uint8 tree, uint8 mountain, uint8 special, uint16 level, uint16 troopModifier, uint32 lvlProgress) external view returns (string memory) {
        string[17] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

        parts[1] = toString(water);

        parts[2] = '</text><text x="10" y="40" class="base">';

        parts[3] = toString(tree);

        parts[4] = '</text><text x="10" y="60" class="base">';

        parts[5] = toString(mountain);

        parts[6] = '</text><text x="10" y="80" class="base">';

        parts[7] = toString(special);

        parts[8] = '</text><text x="10" y="100" class="base">';

        parts[9] = toString(level);

        parts[10] = '</text><text x="10" y="120" class="base">';

        parts[11] = toString(troopModifier);

        parts[12] = '</text><text x="10" y="140" class="base">';

        parts[13] = toString(lvlProgress);

        parts[14] = '</text><text x="10" y="160" class="base">';

        parts[15] = 'Game of Risk'; 

        parts[16] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));
        
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Land #', toString(id), '", "description": "Welcome to the Game of Risk. Will you Risk it all?", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    } 


}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}
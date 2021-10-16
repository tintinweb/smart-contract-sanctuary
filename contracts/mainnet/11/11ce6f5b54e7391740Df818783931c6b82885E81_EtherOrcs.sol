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


contract EtherOrcs is ERC721 {

    /*///////////////////////////////////////////////////////////////
                    Global STATE
    //////////////////////////////////////////////////////////////*/

    uint256 public constant  cooldown = 10 minutes;
    uint256 public constant  startingTime = 1633951800 + 4.5 hours;

    address public migrator;

    bytes32 internal entropySauce;

    ERC20 public zug = ERC20(0xfEE5F54e1070e7eD31Be341e0A5b1E847f6a84Ab);

    mapping (address => bool)     public auth;
    mapping (uint256 => Orc)      public orcs;
    mapping (uint256 => Action)   public activities;
    mapping (Places  => LootPool) public lootPools;

    MetadataHandlerLike metadaHandler;

    function setAddresses(address mig, address meta) external onlyOwner {
        migrator      = mig;
        metadaHandler = MetadataHandlerLike(meta);
    }

    function setAuth(address add, bool isAuth) external onlyOwner {
        auth[add] = isAuth;
    }


    function transferOwnership(address newOwner) external  onlyOwner{
        admin = newOwner;
    }

    function tokenURI(uint256 id) external view returns(string memory) {
        Orc memory orc = orcs[id];
        return metadaHandler.getTokenURI(uint16(id), orc.body, orc.helm, orc.mainhand, orc.offhand, orc.level, orc.zugModifier);
    }

    event ActionMade(address owner, uint256 id, uint256 timestamp, uint8 activity);


    /*///////////////////////////////////////////////////////////////
                DATA STRUCTURES 
    //////////////////////////////////////////////////////////////*/

    struct LootPool { 
        uint8  minLevel; uint8  minLootTier; uint16  cost;   uint16 total;
        uint16 tier_1;   uint16 tier_2;      uint16 tier_3; uint16 tier_4;
    }

    struct Orc { uint8 body; uint8 helm; uint8 mainhand; uint8 offhand; uint16 level; uint16 zugModifier; uint32 lvlProgress; }

    enum   Actions { UNSTAKED, FARMING, TRAINING }
    struct Action  { address owner; uint88 timestamp; Actions action; }

    // These are all the places you can go search for loot
    enum Places { 
        TOWN, DUNGEON, CRYPT, CASTLE, DRAGONS_LAIR, THE_ETHER, 
        TAINTED_KINGDOM, OOZING_DEN, ANCIENT_CHAMBER, ORC_GODS 
    }   

    /*///////////////////////////////////////////////////////////////
                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    function initialize() public onlyOwner {

        // Here's whats available in each place
        LootPool memory town           = LootPool({ minLevel: 1,  minLootTier:  1, cost:   0, total: 1000, tier_1: 800,  tier_2: 150,  tier_3: 50,  tier_4:   0 });
        LootPool memory dungeon        = LootPool({ minLevel: 3,  minLootTier:  2, cost:   0, total: 1000, tier_1: 800,  tier_2: 150,  tier_3: 50,  tier_4:   0 });
        LootPool memory crypt          = LootPool({ minLevel: 6,  minLootTier:  3, cost:   0, total: 2619, tier_1: 1459, tier_2: 1025, tier_3: 135, tier_4:   0 });
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
        lootPools[Places.ORC_GODS]        = orcGods;

        admin = msg.sender;
        auth[msg.sender] = true;

        oldSupply = ERC721(0x7d9d3659dcfbea08a87777c52020BC672deece13).totalSupply();
    }

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

    modifier ownerOfOrc(uint256 id) { 
        require(ownerOf[id] == msg.sender || activities[id].owner == msg.sender, "not your orc");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == admin);
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

    // Craft an identical orc from v1!
    function craft(address owner_, uint256 id, uint8 body, uint8 helm, uint8 mainhand, uint8 offhand, uint16 level, uint32 lvlProgres) public {
        require(msg.sender == migrator);

        _mint(owner_, id);

        uint16 zugModifier = _tier(helm) + _tier(mainhand) + _tier(offhand);
        orcs[uint256(id)] = Orc({body: body, helm: helm, mainhand: mainhand, offhand: offhand, level: level, lvlProgress: lvlProgres, zugModifier:zugModifier});
    }

    function migrationAction(uint256 id, address owner_, Actions action_) public {
        require(msg.sender == migrator);

        _doAction(id, owner_, action_);

        //Add a time bonus
        activities[id].timestamp = uint88(block.timestamp - 120 minutes);
    }

    function doAction(uint256 id, Actions action_) public ownerOfOrc(id) noCheaters {
       _doAction(id, msg.sender, action_);
    }

    function _doAction(uint256 id, address orcOwner, Actions action_) internal {
        Action memory action = activities[id];
        require(action.action != action_, "already doing that");

        // Picking the largest value between block.timestamp, action.timestamp and startingTime
        uint88 timestamp = uint88(block.timestamp > action.timestamp ? block.timestamp : action.timestamp);

        if (action.action == Actions.UNSTAKED)  _transfer(orcOwner, address(this), id);
     
        else {
            if (block.timestamp > action.timestamp) _claim(id);
            timestamp = timestamp > action.timestamp ? timestamp : action.timestamp;
        }

        address owner_ = action_ == Actions.UNSTAKED ? address(0) : orcOwner;
        if (action_ == Actions.UNSTAKED) _transfer(address(this), orcOwner, id);

        activities[id] = Action({owner: owner_, action: action_,timestamp: timestamp});
        emit ActionMade(orcOwner, id, block.timestamp, uint8(action_));
    }

    function doActionWithManyOrcs(uint256[] calldata ids, Actions action_) external {
        for (uint256 index = 0; index < ids.length; index++) {
            _doAction(ids[index], msg.sender, action_);
        }
    }

    function claim(uint256[] calldata ids) external {
        for (uint256 index = 0; index < ids.length; index++) {
            _claim(ids[index]);
        }
    }

    function _claim(uint256 id) internal noCheaters {
        Orc    memory orc    = orcs[id];
        Action memory action = activities[id];

        if(block.timestamp <= action.timestamp) return;

        uint256 timeDiff = uint256(block.timestamp - action.timestamp);

        if (action.action == Actions.FARMING) zug.mint(action.owner, claimableZug(timeDiff, orc.zugModifier));
       
        if (action.action == Actions.TRAINING) {
            uint256 progress = timeDiff * 3000 / 1 days;
            orcs[id].lvlProgress = uint16(progress % 1000);
            orcs[id].level      += uint16(progress / 1000);
        }

        activities[id].timestamp = uint88(block.timestamp);
    }

    function pillage(uint256 id, Places place, bool tryHelm, bool tryMainhand, bool tryOffhand) public ownerOfOrc(id) noCheaters {
        require(block.timestamp >= uint256(activities[id].timestamp), "on cooldown");
        require(place != Places.ORC_GODS,  "You can't pillage the Orc God");

        if(activities[id].timestamp < block.timestamp) _claim(id); // Need to claim to not have equipment reatroactively multiplying

        uint256 rand_ = _rand();
  
        LootPool memory pool = lootPools[place];
        require(orcs[id].level >= uint16(pool.minLevel), "below minimum level");

        if (pool.cost > 0) {
            require(block.timestamp - startingTime > 14 days);
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

    function update(uint256 id) public ownerOfOrc(id) noCheaters {
        require(_tier(orcs[id].mainhand) < 10);
        require(block.timestamp - startingTime >= 14 days);
        
        LootPool memory pool = lootPools[Places.ORC_GODS];
        require(orcs[id].level >= pool.minLevel);

        zug.burn(msg.sender, uint256(pool.cost) * 1 ether);

        _claim(id); // Need to claim to not have equipment reatroactively multiplying

        uint8 item = uint8(lootPools[Places.ORC_GODS].total--);
        orcs[id].zugModifier = 30;
        orcs[id].body = orcs[id].helm = orcs[id].mainhand = orcs[id].offhand = item + 40;
    }

    /*///////////////////////////////////////////////////////////////
                    VIEWERS
    //////////////////////////////////////////////////////////////*/

    function claimable(uint256 id) external view returns (uint256 amount) {
        uint256 timeDiff = block.timestamp > activities[id].timestamp ? uint256(block.timestamp - activities[id].timestamp) : 0;
        amount = activities[id].action == Actions.FARMING ? claimableZug(timeDiff, orcs[id].zugModifier) : timeDiff * 3000 / 1 days;
    }

    function name() external pure returns (string memory) {
        return "Ether Orcs Genesis";
    }

    function symbol() external pure returns (string memory) {
        return "Orcs";
    }


    /*///////////////////////////////////////////////////////////////
                    MINT FUNCTION
    //////////////////////////////////////////////////////////////*/

    function _mintOrc(uint256 rand) internal returns (uint16 id) {
        (uint8 body,uint8 helm,uint8 mainhand,uint8 offhand) = (0,0,0,0);

        {
            // Helpers to get Percentages
            uint256 sevenOnePct   = type(uint16).max / 100 * 71;
            uint256 eightyPct     = type(uint16).max / 100 * 80;
            uint256 nineFivePct   = type(uint16).max / 100 * 95;
            uint256 nineNinePct   = type(uint16).max / 100 * 99;
    
            id = uint16(totalSupply + 1);
    
            // Getting Random traits
            uint16 randBody = uint16(_randomize(rand, "BODY", id));
                   body     = uint8(randBody > nineNinePct ? randBody % 3 + 25 : 
                              randBody > sevenOnePct  ? randBody % 12 + 13 : randBody % 13 + 1 );
    
            uint16 randHelm = uint16(_randomize(rand, "HELM", id));
                   helm     = uint8(randHelm < eightyPct ? 0 : randHelm % 4 + 5);
    
            uint16 randOffhand = uint16(_randomize(rand, "OFFHAND", id));
                   offhand     = uint8(randOffhand < eightyPct ? 0 : randOffhand % 4 + 5);
    
            uint16 randMainhand = uint16(_randomize(rand, "MAINHAND", id));
                   mainhand     = uint8(randMainhand < nineFivePct ? randMainhand % 4 + 1: randMainhand % 4 + 5);
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

        if (draw > pool.tier_1 + pool.tier_2 + pool.tier_3 && pool.tier_4-- > 0) {
            item = uint8((draw % 4 + 1) + (pool.minLootTier + 3) * 4);     
            return (pool, item);
        }

        if (draw > pool.tier_1 + pool.tier_2 && pool.tier_3-- > 0) {
            item = uint8((draw % 4 + 1) + (pool.minLootTier + 2) * 4);
            return (pool, item);
        }

        if (draw > pool.tier_1 && pool.tier_2-- > 0) {
            item = uint8((draw % 4 + 1) + (pool.minLootTier + 1) * 4);
            return (pool, item);
        }

        if (pool.tier_1-- > 0) {
            item = uint8((draw % 4 + 1) + pool.minLootTier * 4);
            return (pool, item);
        }
    }

    function claimableZug(uint256 timeDiff, uint16 zugModifier) internal pure returns (uint256 zugAmount) {
        zugAmount = timeDiff * (4 + zugModifier) * 1 ether / 1 days;
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
        uint256 supply = minted + oldSupply;
        if (supply < 1550) return   0;
        if (supply < 2050) return   4 ether;
        if (supply < 2550) return   8 ether;
        if (supply < 3050) return  12 ether;
        if (supply < 3550) return  24 ether;
        if (supply < 4050) return  40 ether;
        if (supply < 4550) return  60 ether;
        if (supply < 5050) return 130 ether;
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
        address owner_ = ownerOf[tokenId];
        
        require(msg.sender == owner_ || isApprovedForAll[owner_][msg.sender], "NOT_APPROVED");
        
        getApproved[tokenId] = spender;
        
        emit Approval(owner_, spender, tokenId); 
    }
    
    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;
        
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address, address to, uint256 tokenId) public {
        address owner_ = ownerOf[tokenId];
        
        require(
            msg.sender == owner_ 
            || msg.sender == getApproved[tokenId]
            || isApprovedForAll[owner_][msg.sender], 
            "NOT_APPROVED"
        );
        
        _transfer(owner_, to, tokenId);
        
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
        require(ownerOf[tokenId] == from);

        balanceOf[from]--; 
        balanceOf[to]++;
        
        delete getApproved[tokenId];
        
        ownerOf[tokenId] = to;
        emit Transfer(msg.sender, to, tokenId); 

    }

    function _mint(address to, uint256 tokenId) internal { 
        require(ownerOf[tokenId] == address(0), "ALREADY_MINTED");

        uint maxSupply = oldSupply + minted++;
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
        address owner_ = ownerOf[tokenId];
        
        require(ownerOf[tokenId] != address(0), "NOT_MINTED");
        
        totalSupply--;
        balanceOf[owner_]--;
        
        delete ownerOf[tokenId];
                
        emit Transfer(owner_, address(0), tokenId); 
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

    string public constant name     = "ZUG";
    string public constant symbol   = "ZUG";
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
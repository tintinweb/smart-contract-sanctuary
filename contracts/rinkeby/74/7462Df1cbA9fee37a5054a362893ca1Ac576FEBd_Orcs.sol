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
    function getTokenURI(uint16 id, uint16 body, uint16 helm, uint16 mainhand, uint16 offhand, uint16 level, uint16 zugModifier) external returns (string memory);
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
    function tokenURI(uint256 id) external returns(string memory) {
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

    struct Orc { uint8 body; uint16 helm; uint16 mainhand; uint16 offhand; uint16 level; uint16 zugModifier; }

    enum Actions { NOTHING, FARMING, TRAINING }
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
        lootPools[Places.ORC_GODS]         = orcGods;
        lootPools[Places.TAINTED_KINGDOM] = taintedKingdom;
        lootPools[Places.OOZING_DEN]      = oozingDen;
        lootPools[Places.ANCIENT_CHAMBER] = acientChamber;

        // TODO add delay
        startingTime = block.timestamp + 0 hours; // There's 4.5 hours of no actions

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

    function doAction(uint256[] calldata ids, Actions action_) external {
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
        Orc memory orc = orcs[id];

        uint256 timeDiff = uint256(block.timestamp - activities[id].timestamp);

        //TODO adjust booster rates
        if (activities[id].action == Actions.FARMING) {
            uint256 farmingRate   = 400;
            uint256 dailyEmission = (farmingRate + orc.zugModifier) * 1 ether;
            uint256 zugAmount     = timeDiff * dailyEmission / 1 days;

            zug.mint(activities[id].owner, zugAmount * 1 ether);
        }
        if (activities[id].action == Actions.TRAINING) {
            uint256 levelingRate   = 200;
            orcs[id].level        += uint16(timeDiff * levelingRate / 1 days);
        }

        activities[id].timestamp = uint88(block.timestamp);
    }

    function pillage(uint256 id, Places place, bool tryHelm, bool tryMainhand, bool tryOffhand) public ownerOfOrc(id) noCheaters {        
        require(block.timestamp >= uint256(activities[id].timestamp));
        require(place != Places.ORC_GODS, "You can't pillage the Orc God");

        claim(id); // Need to claim to not have equipment reatroactively multiplying
        uint256 rand_ = _rand();
        
        LootPool memory pool = lootPools[place];
         
        if (pool.cost > 0) {
            // TODO add a 14 day delay
            require(block.timestamp - startingTime > 10 minutes);
            zug.burn(msg.sender, pool.cost * 1 ether);
        } 

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

        uint16 item = lootPools[Places.ORC_GODS].total--;
        orcs[id].body     = uint8(item);
        orcs[id].helm     = item;
        orcs[id].mainhand = item; 
        orcs[id].offhand  = item;

    }

    /*///////////////////////////////////////////////////////////////
                    MINT FUNCTION
    //////////////////////////////////////////////////////////////*/

    function _mintOrc(uint256 rand) internal returns (uint16 id) {

        // Helpers to get Percentages
        uint256 ninetyPct    = type(uint16).max / 100 * 90;
        uint256 nineFivePct  = type(uint16).max / 100 * 95;
        uint256 nineEightPct = type(uint16).max / 100 * 98;

        // Getting Random traits
        uint8  body = uint8(_randomize(rand, "BODY")) % 25 + 1;

        uint16 randHelm = uint16(_randomize(rand, "HELM"));
        uint16 helm     = randHelm < nineFivePct ? 0 : randHelm % 4 + 5;

        uint16 randOffhand = uint16(_randomize(rand, "OFFHAND"));
        uint16 offhand     = randOffhand < nineFivePct ? 0 : randOffhand % 4 + 5;

        uint16 randMainhand = uint16(_randomize(rand, "MAINHAND"));
        uint16 mainhand     = randMainhand > nineEightPct ? randMainhand % 4 + 9 :
                              randMainhand > ninetyPct    ? randMainhand % 4 + 5 : randMainhand % 4 + 1;

        id = uint16(totalSupply + 1);

        _mint(msg.sender, id);
        uint16 zugModifier = _tier(helm) + _tier(mainhand) + _tier(offhand);
        
        orcs[uint256(id)] = Orc({body: body, helm: helm, mainhand: mainhand, offhand: offhand, level: 0, zugModifier:zugModifier});
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
    function _tier(uint16 id) internal pure returns (uint16) {
        if (id == 0) return 0;
        return (id / 4 ) - 1;
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

        // This is safe because ownership is checked
        // against decrement, and sum of all user
        // balances can't exceed type(uint256).max!
        unchecked {
            balanceOf[from]--; 
        
            balanceOf[to]++;
        }
        
        delete getApproved[tokenId];
        
        ownerOf[tokenId] = to;
        emit Transfer(msg.sender, to, tokenId); 

    }

    
    function _mint(address to, uint256 tokenId) internal { 
        require(ownerOf[tokenId] == address(0), "ALREADY_MINTED");

        uint maxSupply = 5050;
        require(totalSupply++ < maxSupply, "MAX SUPPLY REACHED");
                
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
        
        // This is safe because a user won't ever
        // have a balance larger than totalSupply!
        unchecked {
            totalSupply--;
        
            balanceOf[owner]--;
        }
        
        delete ownerOf[tokenId];
                
        emit Transfer(owner, address(0), tokenId); 
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

    function setMinters(address[] calldata minters, bool[] calldata status) external {
        require(msg.sender == ruler,               "NOT ALLOWED TO RULE");
        require(minters.length == status.length, "INVALID INPUTS");

        for (uint256 index = 0; index < minters.length; index++) {
            isMinter[minters[index]] = status[index];
        }
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

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}
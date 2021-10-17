// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

import "./EtherOrcs.sol";


contract EtherTransition  {
    
    address public constant impl = 0xaB38C326E6A0e55eBA19d529c9159b6B5B3636ca;
    
    address        implementation_;
    address public admin; //Lame requirement from opensea
    uint256 public totalSupply;
    uint256 public oldSupply;
    uint256 public minted;
    
    mapping(address => uint256) public balanceOf;
    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;
    
    uint256 public constant  cooldown = 10 minutes;
    uint256 public constant  startingTime = 1633951800 + 4.5 hours;

    address public migrator;

    bytes32 internal entropySauce;

    ERC20 public zug;

    mapping (address => bool)     public auth;
    mapping (uint256 => Orc)      public orcs;
    mapping (uint256 => Action)   public activities;
    mapping (Places  => LootPool) public lootPools;
    
    uint256 mintedFromThis = 0;
    bool mintOpen = false;
    
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
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event ActionMade(address owner, uint256 id, uint256 timestamp, uint8 activity);
    
    function doActionSpecial(uint256 id, address orcOwner, uint256 timestamp, uint8 action_) external {
        require(msg.sender == migrator);
    
        _transfer(orcOwner, address(this), id);

        activities[id] = Action({owner: orcOwner, action: Actions(action_),timestamp: uint88(timestamp)});
        emit ActionMade(orcOwner, id, block.timestamp, uint8(action_));
    }
    
    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf[tokenId] == from);

        balanceOf[from]--; 
        balanceOf[to]++;
        
        delete getApproved[tokenId];
        
        ownerOf[tokenId] = to;
        emit Transfer(msg.sender, to, tokenId); 

    }
    

    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
    

    fallback() external {
        require(msg.sender == migrator || msg.sender == admin);
        _delegate(impl);
    }
}